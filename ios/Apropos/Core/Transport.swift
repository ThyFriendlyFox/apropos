import Foundation

/// The seam between the API layer and the network. Tests substitute a stub
/// so no gate ever needs a live GitHub.
protocol Transport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

extension URLSession: Transport {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GitHubError.transport(URLError(.badServerResponse))
        }
        return (data, http)
    }
}
