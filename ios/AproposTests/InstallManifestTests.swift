import XCTest
@testable import Apropos

final class InstallManifestTests: XCTestCase {
    private let metadata = IPAMetadata(
        bundleID: "com.example.zen",
        displayName: "Zen",
        shortVersion: "1.2.3",
        buildVersion: "42",
        signing: .adHoc(deviceCount: 1)
    )

    func testManifestCarriesTheFieldsIOSRequires() throws {
        let xml = InstallManifest.plist(
            ipaURL: URL(string: "https://github.com/me/zen/releases/download/v1/Zen.ipa")!,
            metadata: metadata,
            title: "zen"
        )
        let parsed = try PropertyListSerialization.propertyList(
            from: Data(xml.utf8), options: [], format: nil
        ) as? [String: Any]
        let item = try XCTUnwrap((parsed?["items"] as? [[String: Any]])?.first)
        let asset = try XCTUnwrap((item["assets"] as? [[String: Any]])?.first)
        let meta = try XCTUnwrap(item["metadata"] as? [String: Any])

        XCTAssertEqual(asset["kind"] as? String, "software-package")
        XCTAssertEqual(asset["url"] as? String, "https://github.com/me/zen/releases/download/v1/Zen.ipa")
        XCTAssertEqual(meta["bundle-identifier"] as? String, "com.example.zen")
        XCTAssertEqual(meta["bundle-version"] as? String, "1.2.3")
        XCTAssertEqual(meta["kind"] as? String, "software")
        XCTAssertEqual(meta["title"] as? String, "zen")
    }

    func testAmpersandsInTheAssetURLStayValidXML() throws {
        let xml = InstallManifest.plist(
            ipaURL: URL(string: "https://host.example/get?a=1&b=2")!,
            metadata: metadata,
            title: "zen & co"
        )
        XCTAssertNoThrow(try PropertyListSerialization.propertyList(
            from: Data(xml.utf8), options: [], format: nil
        ))
    }

    func testAMissingVersionFallsBackRatherThanEmittingAnEmptyKey() throws {
        let bare = IPAMetadata(
            bundleID: "com.example.zen", displayName: "Zen",
            shortVersion: "", buildVersion: "", signing: .unknown
        )
        let xml = InstallManifest.plist(
            ipaURL: URL(string: "https://host.example/Zen.ipa")!, metadata: bare, title: "zen"
        )
        let parsed = try PropertyListSerialization.propertyList(
            from: Data(xml.utf8), options: [], format: nil
        ) as? [String: Any]
        let item = try XCTUnwrap((parsed?["items"] as? [[String: Any]])?.first)
        let meta = try XCTUnwrap(item["metadata"] as? [String: Any])
        XCTAssertEqual(meta["bundle-version"] as? String, "1.0")
    }

    func testInstallURLUsesTheSchemeIOSExpects() throws {
        let url = try XCTUnwrap(InstallManifest.installURL(
            manifestURL: URL(string: "https://host.example/manifest.plist")!
        ))
        XCTAssertEqual(url.scheme, "itms-services")
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        XCTAssertEqual(query.first { $0.name == "action" }?.value, "download-manifest")
        XCTAssertEqual(query.first { $0.name == "url" }?.value, "https://host.example/manifest.plist")
    }

    /// iOS silently does nothing for a manifest served over http.
    func testAnInsecureManifestURLProducesNoInstallURL() {
        XCTAssertNil(InstallManifest.installURL(
            manifestURL: URL(string: "http://host.example/manifest.plist")!
        ))
    }
}
