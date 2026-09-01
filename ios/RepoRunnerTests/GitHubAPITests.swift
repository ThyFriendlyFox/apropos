import XCTest
@testable import RepoRunner

final class GitHubAPITests: XCTestCase {
    private func api(_ replies: [StubTransport.Reply], token: String? = "t") -> (GitHubAPI, StubTransport) {
        let transport = StubTransport(replies)
        return (GitHubAPI(transport: transport, token: { token }), transport)
    }

    func testRepositoriesDecodesAPage() async throws {
        let json = """
        [{"id":1,"name":"zen","full_name":"me/zen","description":"a timer",
          "private":false,"html_url":"https://github.com/me/zen",
          "pushed_at":"2026-08-30T10:00:00Z","stargazers_count":4,"language":"Swift",
          "owner":{"login":"me","avatar_url":"https://example.com/a.png"}}]
        """
        let (client, transport) = api([.init(json: json)])
        let repos = try await client.repositories(page: 1)

        XCTAssertEqual(repos.count, 1)
        XCTAssertEqual(repos[0].fullName, "me/zen")
        XCTAssertEqual(repos[0].language, "Swift")
        XCTAssertNotNil(repos[0].pushedAt)

        let url = try XCTUnwrap(transport.sentRequests.first?.url?.absoluteString)
        XCTAssertTrue(url.contains("sort=pushed"), url)
        XCTAssertTrue(url.contains("page=1"), url)
        XCTAssertEqual(
            transport.sentRequests.first?.value(forHTTPHeaderField: "Authorization"),
            "Bearer t"
        )
    }

    func testTokenIsNeverPutInTheQueryString() async throws {
        let secret = "gho_s3cr3tt0k3nvalue"
        let (client, transport) = api([.init(json: "[]")], token: secret)
        _ = try await client.repositories(page: 1)
        let url = try XCTUnwrap(transport.sentRequests.first?.url?.absoluteString)
        XCTAssertFalse(url.contains(secret), "no token may appear in a URL: \(url)")
    }

    func test401MapsToUnauthorized() async {
        let (client, _) = api([.init(status: 401, json: #"{"message":"Bad credentials"}"#)])
        do {
            _ = try await client.currentUser()
            XCTFail("expected unauthorized")
        } catch {
            XCTAssertEqual(error as? GitHubError, .unauthorized)
        }
    }

    func testExhaustedRateLimitMapsToRateLimited() async {
        let (client, _) = api([.init(
            status: 403,
            json: #"{"message":"API rate limit exceeded"}"#,
            headers: ["x-ratelimit-remaining": "0", "x-ratelimit-reset": "1800000000"]
        )])
        do {
            _ = try await client.currentUser()
            XCTFail("expected rate limit")
        } catch let error as GitHubError {
            guard case .rateLimited = error else {
                return XCTFail("expected .rateLimited, got \(error)")
            }
        } catch {
            XCTFail("unexpected \(error)")
        }
    }

    func testForbiddenWithQuotaLeftIsNotARateLimit() async {
        let (client, _) = api([.init(
            status: 403,
            json: #"{"message":"Resource not accessible"}"#,
            headers: ["x-ratelimit-remaining": "4321"]
        )])
        do {
            _ = try await client.currentUser()
            XCTFail("expected http error")
        } catch let error as GitHubError {
            guard case .http(let status, let message) = error else {
                return XCTFail("expected .http, got \(error)")
            }
            XCTAssertEqual(status, 403)
            XCTAssertEqual(message, "Resource not accessible")
        } catch {
            XCTFail("unexpected \(error)")
        }
    }

    func testLatestReleaseReturnsNilOn404() async throws {
        let (client, _) = api([.init(status: 404, json: #"{"message":"Not Found"}"#)])
        let release = try await client.latestRelease(owner: "me", repo: "zen")
        XCTAssertNil(release)
    }
}
