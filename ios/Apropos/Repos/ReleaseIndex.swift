import Foundation

/// Caches the latest-release lookup per repository. Rows ask for a badge
/// as they scroll on; each repository is fetched once per session.
@MainActor
@Observable
final class ReleaseIndex {
    enum Entry: Equatable {
        case scanning
        case noRelease
        case found(ScannedRelease)
        case failed
    }

    private(set) var entries: [String: Entry] = [:]
    private let api: GitHubAPI

    init(api: GitHubAPI) {
        self.api = api
    }

    func entry(for repo: Repo) -> Entry? { entries[repo.fullName] }

    func scanIfNeeded(_ repo: Repo) async {
        guard entries[repo.fullName] == nil else { return }
        entries[repo.fullName] = .scanning
        do {
            guard let release = try await api.latestRelease(owner: repo.owner.login, repo: repo.name) else {
                entries[repo.fullName] = .noRelease
                return
            }
            entries[repo.fullName] = .found(ReleaseScanner.scan(release))
        } catch {
            entries[repo.fullName] = .failed
        }
    }

    func forget(_ repo: Repo) { entries[repo.fullName] = nil }
    func forgetAll() { entries.removeAll() }
}
