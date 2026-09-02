import XCTest
@testable import Apropos

final class IPAInspectorTests: XCTestCase {
    private static func infoPlist(bundleID: String = "com.example.zen") -> Data {
        try! PropertyListSerialization.data(
            fromPropertyList: [
                "CFBundleIdentifier": bundleID,
                "CFBundleDisplayName": "Zen Focus",
                "CFBundleShortVersionString": "1.2.3",
                "CFBundleVersion": "42",
            ],
            format: .xml,
            options: 0
        )
    }

    /// A `.mobileprovision` is a CMS envelope; the inspector only looks for
    /// the XML plist inside it.
    private static func profile(_ dictionary: [String: Any]) -> Data {
        let xml = try! PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0)
        return Data([0x30, 0x82, 0x0a, 0x0b]) + xml + Data([0x00, 0x01, 0x02])
    }

    private func inspect(_ files: [TestZip.File]) async throws -> IPAMetadata {
        let transport = RangeTransport(TestZip.build(files))
        return try await IPAInspector(transport: transport)
            .inspect(URL(string: "https://example.com/app.ipa")!)
    }

    func testReadsBundleIdentifierAndVersionFromADeflatedInfoPlist() async throws {
        let metadata = try await inspect([
            .init(name: "Payload/Zen.app/Info.plist", contents: Self.infoPlist(), deflate: true),
        ])
        XCTAssertEqual(metadata.bundleID, "com.example.zen")
        XCTAssertEqual(metadata.displayName, "Zen Focus")
        XCTAssertEqual(metadata.shortVersion, "1.2.3")
        XCTAssertEqual(metadata.buildVersion, "42")
    }

    func testReadsAStoredInfoPlist() async throws {
        let metadata = try await inspect([
            .init(name: "Payload/Zen.app/Info.plist", contents: Self.infoPlist(), deflate: false),
        ])
        XCTAssertEqual(metadata.bundleID, "com.example.zen")
    }

    func testOnlyAFewKilobytesAreRead() async throws {
        let padding = Data(repeating: 0x41, count: 4_000_000)
        let blob = TestZip.build([
            .init(name: "Payload/Zen.app/pad.bin", contents: padding, deflate: false),
            .init(name: "Payload/Zen.app/Info.plist", contents: Self.infoPlist(), deflate: true),
        ])
        let transport = RangeTransport(blob)
        _ = try await IPAInspector(transport: transport).inspect(URL(string: "https://example.com/app.ipa")!)

        let bytesRead = transport.requestedRanges.reduce(0) { total, header in
            let parts = header.replacingOccurrences(of: "bytes=", with: "").split(separator: "-")
            return total + (Int(parts[1])! - Int(parts[0])! + 1)
        }
        XCTAssertLessThan(bytesRead, 200_000, "the inspector must not pull the whole .ipa")
    }

    func testAFrameworkInfoPlistIsNotMistakenForTheApp() async throws {
        let metadata = try await inspect([
            .init(name: "Payload/Zen.app/Frameworks/Kit.framework/Info.plist",
                  contents: Self.infoPlist(bundleID: "com.example.kit"), deflate: true),
            .init(name: "Payload/Zen.app/Info.plist", contents: Self.infoPlist(), deflate: true),
        ])
        XCTAssertEqual(metadata.bundleID, "com.example.zen")
    }

    func testAppRootMatching() {
        XCTAssertTrue(IPAInspector.isAppRootFile("Payload/Zen.app/Info.plist", named: "Info.plist"))
        XCTAssertFalse(IPAInspector.isAppRootFile("Payload/Zen.app/PlugIns/W.appex/Info.plist", named: "Info.plist"))
        XCTAssertFalse(IPAInspector.isAppRootFile("Info.plist", named: "Info.plist"))
        XCTAssertFalse(IPAInspector.isAppRootFile("Payload/Zen/Info.plist", named: "Info.plist"))
    }

    func testAdHocProfileIsRecognised() async throws {
        let metadata = try await inspect([
            .init(name: "Payload/Zen.app/Info.plist", contents: Self.infoPlist(), deflate: true),
            .init(name: "Payload/Zen.app/embedded.mobileprovision",
                  contents: Self.profile(["ProvisionedDevices": ["a", "b", "c"]]), deflate: false),
        ])
        XCTAssertEqual(metadata.signing, .adHoc(deviceCount: 3))
        XCTAssertTrue(metadata.signing.canInstallOverTheAir)
    }

    func testDevelopmentProfileIsRecognised() async throws {
        let metadata = try await inspect([
            .init(name: "Payload/Zen.app/Info.plist", contents: Self.infoPlist(), deflate: true),
            .init(name: "Payload/Zen.app/embedded.mobileprovision",
                  contents: Self.profile([
                    "ProvisionedDevices": ["a"],
                    "Entitlements": ["get-task-allow": true],
                  ]), deflate: false),
        ])
        XCTAssertEqual(metadata.signing, .development)
    }

    func testEnterpriseProfileIsRecognised() async throws {
        let metadata = try await inspect([
            .init(name: "Payload/Zen.app/Info.plist", contents: Self.infoPlist(), deflate: true),
            .init(name: "Payload/Zen.app/embedded.mobileprovision",
                  contents: Self.profile(["ProvisionsAllDevices": true]), deflate: false),
        ])
        XCTAssertEqual(metadata.signing, .enterprise)
    }

    /// An App Store signature can never install over the air, so the app must
    /// say so instead of handing iOS a URL that fails.
    func testAppStoreProfileCannotInstallOverTheAir() async throws {
        let metadata = try await inspect([
            .init(name: "Payload/Zen.app/Info.plist", contents: Self.infoPlist(), deflate: true),
            .init(name: "Payload/Zen.app/embedded.mobileprovision",
                  contents: Self.profile(["ApplicationIdentifierPrefix": ["ABCDE"]]), deflate: false),
        ])
        XCTAssertEqual(metadata.signing, .appStore)
        XCTAssertFalse(metadata.signing.canInstallOverTheAir)
    }

    func testAFileWithoutAZipDirectoryIsRejected() async {
        let transport = RangeTransport(Data(repeating: 0x00, count: 5_000))
        do {
            _ = try await IPAInspector(transport: transport).inspect(URL(string: "https://example.com/a.ipa")!)
            XCTFail("expected a ZIP error")
        } catch {
            XCTAssertEqual(error as? ZipError, .noEndOfCentralDirectory)
        }
    }

    func testAHostThatIgnoresRangesIsReported() async {
        let transport = RangeTransport(TestZip.build([
            .init(name: "Payload/Zen.app/Info.plist", contents: Self.infoPlist(), deflate: true),
        ]), supportsRanges: false)
        do {
            _ = try await IPAInspector(transport: transport).inspect(URL(string: "https://example.com/a.ipa")!)
            XCTFail("expected a range error")
        } catch {
            XCTAssertEqual(error as? RemoteFile.ReadError, .rangeNotSupported)
        }
    }
}
