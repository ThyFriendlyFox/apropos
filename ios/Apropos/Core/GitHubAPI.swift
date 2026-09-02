import Foundation

/// Every network call to GitHub goes through this type. Views never build
/// a URLRequest of their own.
struct GitHubAPI: Sendable {
    private let transport: Transport
    private let token: @Sendable () -> String?
    private let baseURL = URL(string: "https://api.github.com")!

    init(transport: Transport = URLSession.shared, token: @escaping @Sendable () -> String?) {
        self.transport = transport
        self.token = token
    }

    func currentUser() async throws -> GitHubUser {
        try await get(path: "/user")
    }

    /// One page of the signed-in account's repositories, most recently
    /// pushed first. `page` is 1-based, as GitHub numbers them.
    func repositories(page: Int, perPage: Int = 50) async throws -> [Repo] {
        try await get(path: "/user/repos", query: [
            "sort": "pushed",
            "direction": "desc",
            "affiliation": "owner,collaborator,organization_member",
            "per_page": String(perPage),
            "page": String(page),
        ])
    }

    func releases(owner: String, repo: String, perPage: Int = 20) async throws -> [Release] {
        try await get(path: "/repos/\(owner)/\(repo)/releases", query: ["per_page": String(perPage)])
    }

    func latestRelease(owner: String, repo: String) async throws -> Release? {
        do {
            return try await get(path: "/repos/\(owner)/\(repo)/releases/latest") as Release
        } catch GitHubError.http(status: 404, _) {
            return nil
        }
    }

    /// Attaches a generated manifest to a release. Uploads go to a different
    /// host than the rest of the API.
    func uploadReleaseAsset(
        owner: String,
        repo: String,
        releaseID: Int,
        name: String,
        contentType: String,
        body: Data
    ) async throws -> ReleaseAsset {
        var components = URLComponents(
            string: "https://uploads.github.com/repos/\(owner)/\(repo)/releases/\(releaseID)/assets"
        )!
        components.queryItems = [URLQueryItem(name: "name", value: name)]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        if let token = token() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body

        let (data, response): (Data, HTTPURLResponse)
        do {
            (data, response) = try await transport.send(request)
        } catch let error as URLError {
            throw GitHubError.transport(error)
        }
        try Self.throwIfFailure(data: data, response: response)
        do {
            return try Self.decoder.decode(ReleaseAsset.self, from: data)
        } catch {
            throw GitHubError.decoding(String(describing: error))
        }
    }

    // MARK: - Request plumbing

    private func get<T: Decodable>(path: String, query: [String: String] = [:]) async throws -> T {
        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
                .sorted { $0.name < $1.name }
        }
        var request = URLRequest(url: components.url!)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        if let token = token() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response): (Data, HTTPURLResponse)
        do {
            (data, response) = try await transport.send(request)
        } catch let error as URLError {
            throw GitHubError.transport(error)
        }

        try Self.throwIfFailure(data: data, response: response)

        do {
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            throw GitHubError.decoding(String(describing: error))
        }
    }

    static func throwIfFailure(data: Data, response: HTTPURLResponse) throws {
        guard !(200..<300).contains(response.statusCode) else { return }
        if response.statusCode == 401 { throw GitHubError.unauthorized }
        // GitHub signals a rate limit with 403 or 429; only the remaining
        // header tells the two apart from an ordinary permission failure.
        let exhausted = response.value(forHTTPHeaderField: "x-ratelimit-remaining") == "0"
        if exhausted, response.statusCode == 403 || response.statusCode == 429 {
            let reset = response.value(forHTTPHeaderField: "x-ratelimit-reset").flatMap(Double.init)
            throw GitHubError.rateLimited(resetsAt: reset.map { Date(timeIntervalSince1970: $0) })
        }
        let message = (try? JSONDecoder().decode(APIMessage.self, from: data))?.message ?? ""
        throw GitHubError.http(status: response.statusCode, message: message)
    }

    private struct APIMessage: Decodable { let message: String }

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
