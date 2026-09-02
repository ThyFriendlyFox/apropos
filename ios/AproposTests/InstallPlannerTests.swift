import XCTest
@testable import Apropos

final class InstallPlannerTests: XCTestCase {
    private func repo(private isPrivate: Bool = false, canWrite: Bool = false) -> Repo {
        Repo(
            id: 1,
            name: "zen",
            fullName: "me/zen",
            description: nil,
            isPrivate: isPrivate,
            htmlURL: URL(string: "https://github.com/me/zen")!,
            pushedAt: nil,
            stargazersCount: 0,
            language: nil,
            owner: RepoOwner(login: "me", avatarURL: nil),
            permissions: canWrite ? RepoPermissions(push: true) : RepoPermissions(push: false)
        )
    }

    private func asset(_ name: String) -> ReleaseAsset {
        ReleaseAsset(
            id: abs(name.hashValue),
            name: name,
            size: 1024,
            contentType: nil,
            browserDownloadURL: URL(string: "https://github.com/me/zen/releases/download/v1/\(name)")!
        )
    }

    private func scanned(_ names: [String]) -> ScannedRelease {
        ReleaseScanner.scan(Release(
            id: 7,
            tagName: "v1.0.0",
            name: "First",
            body: nil,
            draft: false,
            prerelease: false,
            publishedAt: nil,
            htmlURL: URL(string: "https://github.com/me/zen/releases/tag/v1.0.0")!,
            assets: names.map(asset)
        ))
    }

    private let metadata = IPAMetadata(
        bundleID: "com.example.zen",
        displayName: "Zen",
        shortVersion: "1.2.3",
        buildVersion: "42",
        signing: .adHoc(deviceCount: 2)
    )

    private func plan(
        assets: [String],
        metadata: IPAMetadata? = nil,
        isPrivate: Bool = false,
        canWrite: Bool = false,
        manifestHost: URL? = nil
    ) -> InstallPlan {
        InstallPlanner.plan(InstallContext(
            repo: repo(private: isPrivate, canWrite: canWrite),
            scanned: scanned(assets),
            metadata: metadata,
            manifestHost: manifestHost,
            canWriteToRepo: canWrite
        ))
    }

    func testAReleaseWithNoArtifactIsRefused() {
        XCTAssertEqual(plan(assets: ["notes.txt"]), .refused(.noIOSBuild))
    }

    func testASimulatorOnlyReleaseIsRefusedWithACommand() {
        guard case .refused(.simulatorBuildOnly(let command)) = plan(assets: ["Zen.app.zip"]) else {
            return XCTFail("expected a simulator-only refusal")
        }
        XCTAssertTrue(command.contains("simctl install booted"), command)
        XCTAssertTrue(command.contains("Zen.app.zip"), command)
    }

    func testAPrivateRepositoryIsRefusedBeforeAnythingIsDownloaded() {
        XCTAssertEqual(plan(assets: ["Zen.ipa"], isPrivate: true), .refused(.privateRelease))
    }

    func testAnUninspectedIPAAsksForInspectionFirst() {
        guard case .needsInspection(let ipa) = plan(assets: ["Zen.ipa"]) else {
            return XCTFail("expected inspection")
        }
        XCTAssertEqual(ipa.name, "Zen.ipa")
    }

    func testAnAppStoreBuildIsRefused() {
        let appStore = IPAMetadata(
            bundleID: "com.example.zen", displayName: "Zen",
            shortVersion: "1", buildVersion: "1", signing: .appStore
        )
        XCTAssertEqual(plan(assets: ["Zen.ipa"], metadata: appStore), .refused(.appStoreSigned))
    }

    func testAnExistingManifestIsUsedAsIs() {
        guard case .ready(.existingAsset(let url), _) = plan(
            assets: ["Zen.ipa", "manifest.plist"], metadata: metadata
        ) else {
            return XCTFail("expected the release manifest to be used")
        }
        XCTAssertEqual(url.lastPathComponent, "manifest.plist")
    }

    func testAManifestHostWinsOverUploading() {
        let host = URL(string: "https://runner.example.com/api/manifest")!
        guard case .ready(.hosted(let url), _) = plan(
            assets: ["Zen.ipa"], metadata: metadata, canWrite: true, manifestHost: host
        ) else {
            return XCTFail("expected the hosted manifest")
        }
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        XCTAssertEqual(query.first { $0.name == "id" }?.value, "com.example.zen")
        XCTAssertEqual(query.first { $0.name == "version" }?.value, "1.2.3")
        XCTAssertTrue(query.first { $0.name == "ipa" }?.value?.hasSuffix("Zen.ipa") == true)
    }

    func testAnInsecureManifestHostIsIgnored() {
        let host = URL(string: "http://runner.example.com/api/manifest")!
        guard case .ready(.uploadToRelease, _) = plan(
            assets: ["Zen.ipa"], metadata: metadata, canWrite: true, manifestHost: host
        ) else {
            return XCTFail("an http host must not be used; iOS refuses it")
        }
    }

    func testWriteAccessMeansTheManifestIsAttachedToTheRelease() {
        guard case .ready(.uploadToRelease, let found) = plan(
            assets: ["Zen.ipa"], metadata: metadata, canWrite: true
        ) else {
            return XCTFail("expected an upload plan")
        }
        XCTAssertEqual(found.bundleID, "com.example.zen")
    }

    /// A release can carry both. Refusing the phone install must not hide
    /// the simulator archive that is sitting right next to it.
    func testASimulatorArchiveIsStillOfferedWhenTheIPAIsRefused() {
        let appStore = IPAMetadata(
            bundleID: "com.example.zen", displayName: "Zen",
            shortVersion: "1", buildVersion: "1", signing: .appStore
        )
        let context = InstallContext(
            repo: repo(),
            scanned: scanned(["Zen.ipa", "Zen-Simulator.zip"]),
            metadata: appStore,
            manifestHost: nil,
            canWriteToRepo: false
        )
        XCTAssertEqual(InstallPlanner.plan(context), .refused(.appStoreSigned))
        XCTAssertEqual(context.scanned.simulatorBuild?.asset.name, "Zen-Simulator.zip")
    }

    func testNoManifestAndNoWriteAccessIsRefused() {
        XCTAssertEqual(
            plan(assets: ["Zen.ipa"], metadata: metadata, canWrite: false),
            .refused(.noManifestHost)
        )
    }
}
