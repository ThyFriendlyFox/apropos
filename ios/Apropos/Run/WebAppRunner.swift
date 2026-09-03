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
    private let target: RunTarget
    private var server: LocalWebServer?

    init(target: RunTarget, store: WebAppStore = WebAppStore()) {
        self.target = target
        self.store = store
    }

    func start() async {
        guard case .preparing = step else { return }
        switch target {
        case .hosted(let url):
            // A deployed site needs no download and no local server.
            step = .running(url)
        case .bundle(let artifact, let releaseID, _):
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
    }

    /// Drops any cached copy so the next run fetches the release again.
    func reinstall() async {
        server?.stop()
        server = nil
        if case .bundle(_, let releaseID, _) = target {
            store.forget(releaseID: releaseID)
        }
        step = .preparing
        await start()
    }

    func stop() {
        server?.stop()
        server = nil
    }
}
