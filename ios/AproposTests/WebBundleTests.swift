import XCTest
@testable import Apropos

final class ZipExtractionTests: XCTestCase {
    private var scratch: URL!

    override func setUpWithError() throws {
        scratch = URL.temporaryDirectory.appendingPathComponent("zip-\(UUID().uuidString)")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: scratch)
        super.tearDown()
    }

    func testExtractsEveryEntry() throws {
        let zip = TestZip.build([
            .init(name: "index.html", contents: Data("<h1>hi</h1>".utf8), deflate: true),
            .init(name: "assets/app.js", contents: Data("console.log(1)".utf8), deflate: true),
            .init(name: "assets/logo.png", contents: Data([0x89, 0x50, 0x4e, 0x47]), deflate: false),
        ])
        try ZipDirectory.extractAll(zip, to: scratch)

        XCTAssertEqual(
            try String(contentsOf: scratch.appendingPathComponent("index.html"), encoding: .utf8),
            "<h1>hi</h1>"
        )
        XCTAssertEqual(
            try String(contentsOf: scratch.appendingPathComponent("assets/app.js"), encoding: .utf8),
            "console.log(1)"
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: scratch.appendingPathComponent("assets/logo.png").path))
    }

    /// Build tools often nest the whole site one folder deep.
    func testFindsTheShallowestIndex() throws {
        let zip = TestZip.build([
            .init(name: "dist/index.html", contents: Data("<b>site</b>".utf8), deflate: true),
            .init(name: "dist/docs/index.html", contents: Data("<b>docs</b>".utf8), deflate: true),
        ])
        try ZipDirectory.extractAll(zip, to: scratch)

        let index = try XCTUnwrap(ZipDirectory.findIndex(under: scratch))
        XCTAssertEqual(try String(contentsOf: index, encoding: .utf8), "<b>site</b>")
        XCTAssertEqual(index.deletingLastPathComponent().lastPathComponent, "dist")
    }

    /// An archive is untrusted input. A name that climbs out of the folder
    /// must be refused, not written.
    func testRefusesAnEntryThatEscapesTheFolder() {
        let zip = TestZip.build([
            .init(name: "../../escaped.txt", contents: Data("no".utf8), deflate: false),
        ])
        XCTAssertThrowsError(try ZipDirectory.extractAll(zip, to: scratch)) { error in
            XCTAssertEqual(error as? ZipError, .unsafeEntry("../../escaped.txt"))
        }
    }

    func testSafeDestinationRules() {
        let root = URL(fileURLWithPath: "/tmp/root")
        XCTAssertNil(ZipDirectory.safeDestination(for: "/etc/passwd", under: root))
        XCTAssertNil(ZipDirectory.safeDestination(for: "../out", under: root))
        XCTAssertNil(ZipDirectory.safeDestination(for: "a/../../out", under: root))
        XCTAssertEqual(
            ZipDirectory.safeDestination(for: "a/./b.txt", under: root)?.path,
            "/tmp/root/a/b.txt"
        )
    }
}

final class LocalWebServerTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = URL.temporaryDirectory.appendingPathComponent("site-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: root.appendingPathComponent("assets"),
            withIntermediateDirectories: true
        )
        try Data("<h1>Runs inside Apropos</h1>".utf8).write(to: root.appendingPathComponent("index.html"))
        try Data("export const x = 1".utf8).write(to: root.appendingPathComponent("assets/app.js"))
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: root)
        super.tearDown()
    }

    func testServesFilesOverLoopback() async throws {
        let server = LocalWebServer(root: root)
        let base = try await server.start()
        defer { server.stop() }

        XCTAssertEqual(base.host(), "127.0.0.1")

        let (html, response) = try await URLSession.shared.data(from: base)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertEqual(String(decoding: html, as: UTF8.self), "<h1>Runs inside Apropos</h1>")

        let (js, jsResponse) = try await URLSession.shared.data(from: base.appending(path: "assets/app.js"))
        XCTAssertEqual(String(decoding: js, as: UTF8.self), "export const x = 1")
        XCTAssertEqual(
            (jsResponse as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Type"),
            "text/javascript; charset=utf-8"
        )
    }

    /// A real origin is the point: `file://` breaks fetch and absolute paths.
    func testTheOriginIsHTTPSoFetchWorks() async throws {
        let server = LocalWebServer(root: root)
        let base = try await server.start()
        defer { server.stop() }
        XCTAssertEqual(base.scheme, "http")
        XCTAssertNotNil(server.port)
    }

    func testUnknownRouteFallsBackToIndexForSinglePageApps() {
        let resolved = LocalWebServer.resolve(target: "/settings/profile", root: root)
        XCTAssertEqual(resolved?.lastPathComponent, "index.html")
    }

    func testAMissingAssetIsNotFoundRatherThanIndex() {
        XCTAssertNil(LocalWebServer.resolve(target: "/assets/missing.js", root: root))
    }

    func testQueryAndFragmentAreIgnored() {
        XCTAssertEqual(
            LocalWebServer.resolve(target: "/assets/app.js?v=2#top", root: root)?.lastPathComponent,
            "app.js"
        )
    }

    func testTraversalIsRefused() {
        XCTAssertNil(LocalWebServer.resolve(target: "/../../../etc/passwd", root: root))
    }

    func testContentTypes() {
        XCTAssertEqual(LocalWebServer.contentType(for: URL(fileURLWithPath: "a.html")), "text/html; charset=utf-8")
        XCTAssertEqual(LocalWebServer.contentType(for: URL(fileURLWithPath: "a.wasm")), "application/wasm")
        XCTAssertEqual(LocalWebServer.contentType(for: URL(fileURLWithPath: "a.bin")), "application/octet-stream")
    }
}

final class WebAppStoreTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = URL.temporaryDirectory.appendingPathComponent("store-\(UUID().uuidString)")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: root)
        super.tearDown()
    }

    private func artifact(_ name: String) -> Artifact {
        Artifact(
            asset: ReleaseAsset(
                id: 1, name: name, size: 10, contentType: nil,
                browserDownloadURL: URL(string: "https://example.com/\(name)")!
            ),
            kind: .webApp
        )
    }

    func testDownloadsUnpacksAndFindsTheIndex() async throws {
        let zip = TestZip.build([
            .init(name: "index.html", contents: Data("<p>ok</p>".utf8), deflate: true),
        ])
        let transport = StubTransport([.init(json: "")])
        let store = WebAppStore(transport: RawTransport(zip), root: root)

        let prepared = try await store.prepare(artifact: artifact("web.zip"), releaseID: 42)

        XCTAssertEqual(try String(contentsOf: prepared.index, encoding: .utf8), "<p>ok</p>")
        _ = transport
    }

    func testASecondRunUsesTheCachedCopy() async throws {
        let zip = TestZip.build([
            .init(name: "index.html", contents: Data("<p>cached</p>".utf8), deflate: true),
        ])
        let transport = RawTransport(zip)
        let store = WebAppStore(transport: transport, root: root)

        _ = try await store.prepare(artifact: artifact("web.zip"), releaseID: 7)
        _ = try await store.prepare(artifact: artifact("web.zip"), releaseID: 7)

        XCTAssertEqual(transport.requestCount, 1, "the bundle must not be downloaded twice")
    }

    func testAnArchiveWithNoIndexIsReportedNotSilentlyEmpty() async {
        let zip = TestZip.build([
            .init(name: "readme.txt", contents: Data("nothing here".utf8), deflate: false),
        ])
        let store = WebAppStore(transport: RawTransport(zip), root: root)
        do {
            _ = try await store.prepare(artifact: artifact("web.zip"), releaseID: 9)
            XCTFail("expected a missing-index error")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("index.html"), error.localizedDescription)
        }
    }

    func testASingleHTMLAssetBecomesTheIndex() async throws {
        let store = WebAppStore(transport: RawTransport(Data("<h1>one file</h1>".utf8)), root: root)
        let prepared = try await store.prepare(artifact: artifact("game.html"), releaseID: 11)
        XCTAssertEqual(prepared.index.lastPathComponent, "index.html")
        XCTAssertEqual(try String(contentsOf: prepared.index, encoding: .utf8), "<h1>one file</h1>")
    }
}

/// Answers every request with the same bytes, the way a release-asset
/// download does.
final class RawTransport: Transport, @unchecked Sendable {
    private let payload: Data
    private let lock = NSLock()
    private var count = 0

    var requestCount: Int {
        lock.lock(); defer { lock.unlock() }
        return count
    }

    init(_ payload: Data) { self.payload = payload }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        lock.lock(); count += 1; lock.unlock()
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (payload, response)
    }
}
