import Foundation
@testable import RepoRunner

/// Answers requests from a queue of canned responses so no gate needs a
/// live GitHub.
final class StubTransport: Transport, @unchecked Sendable {
    struct Reply {
        let status: Int
        let body: Data
        let headers: [String: String]

        init(status: Int = 200, json: String, headers: [String: String] = [:]) {
            self.status = status
            self.body = Data(json.utf8)
            self.headers = headers
        }
    }

    private let lock = NSLock()
    private var queue: [Reply]
    private(set) var sentRequests: [URLRequest] = []

    init(_ replies: [Reply]) { queue = replies }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        lock.lock()
        defer { lock.unlock() }
        sentRequests.append(request)
        guard !queue.isEmpty else {
            throw URLError(.resourceUnavailable)
        }
        let reply = queue.removeFirst()
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: reply.status,
            httpVersion: "HTTP/1.1",
            headerFields: reply.headers
        )!
        return (reply.body, response)
    }
}
