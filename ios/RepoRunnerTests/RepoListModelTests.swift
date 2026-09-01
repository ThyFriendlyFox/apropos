import XCTest
@testable import RepoRunner

@MainActor
final class RepoListModelTests: XCTestCase {
    private func repoJSON(id: Int, name: String, description: String = "") -> String {
        """
        {"id":\(id),"name":"\(name)","full_name":"me/\(name)","description":"\(description)",
         "private":false,"html_url":"https://github.com/me/\(name)",
         "pushed_at":"2026-08-30T10:00:00Z","stargazers_count":0,"language":null,
         "owner":{"login":"me","avatar_url":null}}
        """
    }

    func testReloadLoadsTheFirstPage() async {
        let transport = StubTransport([.init(json: "[\(repoJSON(id: 1, name: "zen"))]")])
        let model = RepoListModel(api: GitHubAPI(transport: transport, token: { "t" }))

        await model.reload()

        XCTAssertEqual(model.state, .loaded)
        XCTAssertEqual(model.repos.map(\.name), ["zen"])
    }

    func testAnEmptyPageEndsPagination() async {
        let transport = StubTransport([
            .init(json: "[\(repoJSON(id: 1, name: "a"))]"),
            .init(json: "[]"),
        ])
        let model = RepoListModel(api: GitHubAPI(transport: transport, token: { "t" }))

        await model.reload()
        await model.loadNextPage()

        XCTAssertFalse(model.hasMore)
        XCTAssertEqual(model.repos.count, 1)
    }

    func testSearchFiltersOnNameAndDescription() async {
        let transport = StubTransport([.init(json: """
        [\(repoJSON(id: 1, name: "zen-focus")),
         \(repoJSON(id: 2, name: "notes", description: "a Zen editor")),
         \(repoJSON(id: 3, name: "unrelated"))]
        """)])
        let model = RepoListModel(api: GitHubAPI(transport: transport, token: { "t" }))
        await model.reload()

        model.query = "zen"
        XCTAssertEqual(Set(model.visibleRepos.map(\.name)), ["zen-focus", "notes"])
    }

    func testFailureIsReportedAndStopsPagination() async {
        let transport = StubTransport([.init(status: 500, json: #"{"message":"boom"}"#)])
        let model = RepoListModel(api: GitHubAPI(transport: transport, token: { "t" }))

        await model.reload()

        guard case .failed(let message) = model.state else {
            return XCTFail("expected .failed, got \(model.state)")
        }
        XCTAssertEqual(message, "boom")
        XCTAssertFalse(model.hasMore)
    }
}
