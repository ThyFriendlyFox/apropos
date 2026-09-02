import Foundation
import Network

/// Serves an extracted web bundle over loopback so a WKWebView loads it
/// from a real `http://127.0.0.1` origin.
///
/// A `file://` origin would be simpler, but it breaks `fetch`, absolute
/// paths, and service workers, which most build tools emit. A real origin
/// lets an ordinary static build run unchanged.
final class LocalWebServer: @unchecked Sendable {
    enum ServerError: LocalizedError {
        case noPort

        var errorDescription: String? {
            switch self {
            case .noPort: return "Apropos could not open a local port to run the app."
            }
        }
    }

    private let root: URL
    private let queue = DispatchQueue(label: "apropos.localwebserver")
    private var listener: NWListener?
    private(set) var port: UInt16?

    init(root: URL) {
        self.root = root.standardizedFileURL
    }

    /// Starts on an ephemeral loopback port and returns the base URL.
    func start() async throws -> URL {
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: .any)
        parameters.allowLocalEndpointReuse = true

        let listener = try NWListener(using: parameters)
        self.listener = listener

        // NWListener reports readiness and failure on its own queue and can
        // report more than once. The box makes resuming exactly-once safe
        // from any thread.
        let box = ContinuationBox()
        return try await withCheckedThrowingContinuation { continuation in
            box.attach(continuation)
            listener.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    guard let rawPort = listener.port?.rawValue else {
                        box.fail(ServerError.noPort)
                        return
                    }
                    self?.port = rawPort
                    box.succeed(URL(string: "http://127.0.0.1:\(rawPort)/")!)
                case .failed(let error):
                    box.fail(error)
                case .cancelled:
                    box.fail(ServerError.noPort)
                default:
                    break
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                self?.accept(connection)
            }
            listener.start(queue: queue)
        }
    }

    private final class ContinuationBox: @unchecked Sendable {
        private let lock = NSLock()
        private var continuation: CheckedContinuation<URL, Error>?

        func attach(_ continuation: CheckedContinuation<URL, Error>) {
            lock.lock()
            defer { lock.unlock() }
            self.continuation = continuation
        }

        func succeed(_ url: URL) { take()?.resume(returning: url) }
        func fail(_ error: Error) { take()?.resume(throwing: error) }

        private func take() -> CheckedContinuation<URL, Error>? {
            lock.lock()
            defer { lock.unlock() }
            let held = continuation
            continuation = nil
            return held
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        port = nil
    }

    deinit { listener?.cancel() }

    private func accept(_ connection: NWConnection) {
        connection.start(queue: queue)
        receive(on: connection, buffered: Data())
    }

    /// A request line can arrive split across reads, so bytes accumulate
    /// until the end of the headers is seen.
    private func receive(on connection: NWConnection, buffered: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16 * 1024) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            var buffer = buffered
            if let data { buffer.append(data) }

            if let range = buffer.range(of: Data("\r\n\r\n".utf8)) {
                let head = String(decoding: buffer[..<range.lowerBound], as: UTF8.self)
                self.respond(to: head, on: connection)
                return
            }
            if error != nil || isComplete || buffer.count > 64 * 1024 {
                connection.cancel()
                return
            }
            self.receive(on: connection, buffered: buffer)
        }
    }

    private func respond(to head: String, on connection: NWConnection) {
        guard let requestLine = head.split(separator: "\r\n").first else {
            return send(status: "400 Bad Request", body: Data(), type: "text/plain", on: connection)
        }
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2, parts[0] == "GET" || parts[0] == "HEAD" else {
            return send(status: "405 Method Not Allowed", body: Data(), type: "text/plain", on: connection)
        }

        let target = String(parts[1])
        guard let resolved = Self.resolve(target: target, root: root) else {
            return send(status: "404 Not Found", body: Data("Not found".utf8), type: "text/plain", on: connection)
        }
        guard let body = try? Data(contentsOf: resolved) else {
            return send(status: "404 Not Found", body: Data("Not found".utf8), type: "text/plain", on: connection)
        }
        send(
            status: "200 OK",
            body: parts[0] == "HEAD" ? Data() : body,
            type: Self.contentType(for: resolved),
            length: body.count,
            on: connection
        )
    }

    /// Maps a request path onto a file under `root`. Falls back to
    /// `index.html` so a single-page app's own routes resolve, and refuses
    /// anything that climbs out of `root`.
    static func resolve(target: String, root: URL) -> URL? {
        var path = target
        if let cut = path.firstIndex(where: { $0 == "?" || $0 == "#" }) { path = String(path[..<cut]) }
        path = path.removingPercentEncoding ?? path

        let index = root.appendingPathComponent("index.html")
        if path.isEmpty || path == "/" {
            return FileManager.default.fileExists(atPath: index.path) ? index : nil
        }
        guard let candidate = ZipDirectory.safeDestination(for: String(path.dropFirst()), under: root) else {
            return nil
        }
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: candidate.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                let nested = candidate.appendingPathComponent("index.html")
                return FileManager.default.fileExists(atPath: nested.path) ? nested : nil
            }
            return candidate
        }
        // An unknown path with no extension is a client-side route.
        if candidate.pathExtension.isEmpty, FileManager.default.fileExists(atPath: index.path) {
            return index
        }
        return nil
    }

    static func contentType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "html", "htm": return "text/html; charset=utf-8"
        case "js", "mjs": return "text/javascript; charset=utf-8"
        case "css": return "text/css; charset=utf-8"
        case "json", "map": return "application/json; charset=utf-8"
        case "svg": return "image/svg+xml"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        case "avif": return "image/avif"
        case "ico": return "image/x-icon"
        case "woff2": return "font/woff2"
        case "woff": return "font/woff"
        case "ttf": return "font/ttf"
        case "wasm": return "application/wasm"
        case "txt": return "text/plain; charset=utf-8"
        case "webmanifest": return "application/manifest+json"
        default: return "application/octet-stream"
        }
    }

    private func send(
        status: String,
        body: Data,
        type: String,
        length: Int? = nil,
        on connection: NWConnection
    ) {
        let headers = """
        HTTP/1.1 \(status)\r
        Content-Type: \(type)\r
        Content-Length: \(length ?? body.count)\r
        Cache-Control: no-store\r
        Connection: close\r
        \r

        """
        connection.send(content: Data(headers.utf8) + body, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
