import Foundation

/// Owns one run: fetch the bundle, serve it, hand back a URL to load.
@MainActor
@Observable
final class WebAppRunner {
    enum Step: Equatable {
        case preparing
        case running(URL)
        case failed(String)
    }

    private(set) var step: Step = .preparing

    private let store: WebAppStore
    private let artifact: Artifact
    private let releaseID: Int
    private var server: LocalWebServer?

    init(artifact: Artifact, releaseID: Int, store: WebAppStore = WebAppStore()) {
        self.artifact = artifact
        self.releaseID = releaseID
        self.store = store
    }

    func start() async {
        guard case .preparing = step else { return }
        do {
            let prepared = try await store.prepare(artifact: artifact, releaseID: releaseID)
            let server = LocalWebServer(root: prepared.root)
            let base = try await server.start()
            self.server = server
            step = .running(base)
        } catch {
            step = .failed(error.localizedDescription)
        }
    }

    /// Drops the cached copy so the next run downloads the release again.
    func reinstall() async {
        server?.stop()
        server = nil
        store.forget(releaseID: releaseID)
        step = .preparing
        await start()
    }

    func stop() {
        server?.stop()
        server = nil
    }
}
