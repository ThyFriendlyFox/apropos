import Foundation

/// Downloads a release's web bundle and unpacks it into the app's own
/// container, keyed by release id so a second run reuses it.
struct WebAppStore: Sendable {
    enum StoreError: LocalizedError {
        case noIndex

        var errorDescription: String? {
            switch self {
            case .noIndex:
                return "That archive has no index.html, so there is nothing to open. Attach a built web app to the release."
            }
        }
    }

    private let transport: Transport
    private let root: URL

    init(transport: Transport = URLSession.shared, root: URL? = nil) {
        self.transport = transport
        self.root = root ?? URL.applicationSupportDirectory.appendingPathComponent("RunnableApps", isDirectory: true)
    }

    func directory(forRelease releaseID: Int) -> URL {
        root.appendingPathComponent(String(releaseID), isDirectory: true)
    }

    func cachedIndex(forRelease releaseID: Int) -> URL? {
        ZipDirectory.findIndex(under: directory(forRelease: releaseID))
    }

    /// Returns the folder to serve and the index inside it. Downloads only
    /// when nothing is cached for that release.
    func prepare(artifact: Artifact, releaseID: Int) async throws -> (root: URL, index: URL) {
        let destination = directory(forRelease: releaseID)
        if let cached = cachedIndex(forRelease: releaseID) {
            return (cached.deletingLastPathComponent(), cached)
        }

        let data = try await download(artifact.asset.browserDownloadURL)
        try? FileManager.default.removeItem(at: destination)

        if artifact.asset.name.lowercased().hasSuffix(".html")
            || artifact.asset.name.lowercased().hasSuffix(".htm") {
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
            let index = destination.appendingPathComponent("index.html")
            try data.write(to: index)
            return (destination, index)
        }

        try ZipDirectory.extractAll(data, to: destination)
        guard let index = ZipDirectory.findIndex(under: destination) else {
            try? FileManager.default.removeItem(at: destination)
            throw StoreError.noIndex
        }
        // Serve from the folder holding index.html: build tools often nest
        // the whole site one level down inside the archive.
        return (index.deletingLastPathComponent(), index)
    }

    func forget(releaseID: Int) {
        try? FileManager.default.removeItem(at: directory(forRelease: releaseID))
    }

    private func download(_ url: URL) async throws -> Data {
        let (data, response) = try await transport.send(URLRequest(url: url))
        guard (200..<300).contains(response.statusCode) else {
            throw GitHubError.http(status: response.statusCode, message: "Could not download the bundle.")
        }
        return data
    }
}
