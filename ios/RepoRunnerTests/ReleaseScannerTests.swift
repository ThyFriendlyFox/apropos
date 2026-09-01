import XCTest
@testable import RepoRunner

final class ReleaseScannerTests: XCTestCase {
    private func asset(_ name: String, size: Int = 1024) -> ReleaseAsset {
        ReleaseAsset(
            id: abs(name.hashValue),
            name: name,
            size: size,
            contentType: "application/octet-stream",
            browserDownloadURL: URL(string: "https://github.com/me/app/releases/download/v1/\(name)")!
        )
    }

    func testIPAIsADeviceBuild() {
        XCTAssertEqual(ReleaseScanner.classify(asset("ZenFocus.ipa")), .deviceApp)
        XCTAssertEqual(ReleaseScanner.classify(asset("Zen-Focus-1.2.3.IPA")), .deviceApp)
    }

    func testPlistIsAManifest() {
        XCTAssertEqual(ReleaseScanner.classify(asset("manifest.plist")), .manifest)
    }

    func testSimulatorArchivesAreSimulatorBuilds() {
        XCTAssertEqual(ReleaseScanner.classify(asset("ZenFocus.app.zip")), .simulatorApp)
        XCTAssertEqual(ReleaseScanner.classify(asset("ZenFocus.app.tar.gz")), .simulatorApp)
        XCTAssertEqual(ReleaseScanner.classify(asset("ZenFocus-Simulator.zip")), .simulatorApp)
        XCTAssertEqual(ReleaseScanner.classify(asset("build-sim.tgz")), .simulatorApp)
    }

    func testUnrelatedAssetsAreNotArtifacts() {
        XCTAssertNil(ReleaseScanner.classify(asset("source.zip")))
        XCTAssertNil(ReleaseScanner.classify(asset("README.md")))
        XCTAssertNil(ReleaseScanner.classify(asset("app.apk")))
        XCTAssertNil(ReleaseScanner.classify(asset("app.dSYM.zip")))
    }

    func testContentTypeIsIgnoredInFavourOfTheName() {
        let mislabelled = ReleaseAsset(
            id: 1,
            name: "ZenFocus.ipa",
            size: 10,
            contentType: "text/plain",
            browserDownloadURL: URL(string: "https://example.com/ZenFocus.ipa")!
        )
        XCTAssertEqual(ReleaseScanner.classify(mislabelled), .deviceApp)
    }

    func testScanPicksTheDeviceBuildAndManifest() {
        let scanned = ReleaseScanner.scan(Self.release(assets: [
            asset("notes.txt"),
            asset("ZenFocus.ipa", size: 8_000_000),
            asset("manifest.plist"),
            asset("ZenFocus.app.zip"),
        ]))

        XCTAssertEqual(scanned.artifacts.count, 3)
        XCTAssertEqual(scanned.deviceBuild?.asset.name, "ZenFocus.ipa")
        XCTAssertEqual(scanned.manifest?.asset.name, "manifest.plist")
        XCTAssertEqual(scanned.simulatorBuild?.asset.name, "ZenFocus.app.zip")
        XCTAssertTrue(scanned.isInstallable)
    }

    func testASimulatorOnlyReleaseIsNotInstallable() {
        let scanned = ReleaseScanner.scan(Self.release(assets: [asset("ZenFocus.app.zip")]))
        XCTAssertFalse(scanned.isInstallable)
        XCTAssertNotNil(scanned.simulatorBuild)
    }

    func testDraftsAreDropped() {
        let all = [Self.release(assets: [asset("a.ipa")], draft: true),
                   Self.release(assets: [asset("b.ipa")])]
        let scanned = ReleaseScanner.scan(all)
        XCTAssertEqual(scanned.count, 1)
        XCTAssertEqual(scanned[0].deviceBuild?.asset.name, "b.ipa")
    }

    private static func release(assets: [ReleaseAsset], draft: Bool = false) -> Release {
        Release(
            id: draft ? 2 : 1,
            tagName: "v1.0.0",
            name: "First",
            body: nil,
            draft: draft,
            prerelease: false,
            publishedAt: Date(timeIntervalSince1970: 1_780_000_000),
            htmlURL: URL(string: "https://github.com/me/app/releases/tag/v1.0.0")!,
            assets: assets
        )
    }
}
