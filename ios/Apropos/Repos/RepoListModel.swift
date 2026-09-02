import Foundation

@MainActor
@Observable
final class RepoListModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var repos: [Repo] = []
    private(set) var state: LoadState = .idle
    private(set) var hasMore = true
    var query: String = ""

    private let api: GitHubAPI
    private var nextPage = 1
    private var loadingPage = false

    init(api: GitHubAPI) {
        self.api = api
    }

    var visibleRepos: [Repo] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return repos }
        return repos.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
                || ($0.description ?? "").localizedCaseInsensitiveContains(trimmed)
        }
    }

    func loadFirstPageIfNeeded() async {
        guard case .idle = state else { return }
        await reload()
    }

    func reload() async {
        nextPage = 1
        hasMore = true
        state = .loading
        repos = []
        await loadNextPage()
    }

    func loadNextPage() async {
        guard hasMore, !loadingPage else { return }
        loadingPage = true
        defer { loadingPage = false }
        do {
            let page = try await api.repositories(page: nextPage)
            repos.append(contentsOf: page)
            hasMore = !page.isEmpty
            nextPage += 1
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
            hasMore = false
        }
    }

    /// True when the row is close enough to the end to justify a fetch.
    func shouldLoadMore(after repo: Repo) -> Bool {
        guard hasMore, query.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard let index = repos.firstIndex(of: repo) else { return false }
        return index >= repos.count - 5
    }
}
