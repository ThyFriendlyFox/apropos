import XCTest
@testable import Apropos

final class RunResolverTests: XCTestCase {
    private func repo(homepage: String? = nil, hasPages: Bool = false, name: String = "zen") -> Repo {
        Repo(
            id: 1, name: name, fullName: "me/\(name)", description: nil, isPrivate: false,
            htmlURL: URL(string: "https://github.com/me/\(name)")!, pushedAt: nil,
            stargazersCount: 0, language: nil, homepage: homepage, hasPages: hasPages,
            owner: RepoOwner(login: "Me", avatarURL: nil), permissions: nil
        )
    }

    private func release(_ assetName: String, id: Int = 5, tag: String = "v1.0.0") -> ScannedRelease {
        ReleaseScanner.scan(Release(
            id: id, tagName: tag, name: nil, body: nil, draft: false, prerelease: false,
            publishedAt: nil, htmlURL: URL(string: "https://github.com/me/zen/releases/tag/\(tag)")!,
            assets: [ReleaseAsset(
                id: 1, name: assetName, size: 10, contentType: nil,
                browserDownloadURL: URL(string: "https://github.com/me/zen/releases/download/\(tag)/\(assetName)")!
            )]
        ))
    }

    func testADeployedHomepageMakesARepoRunnableWithNoRelease() throws {
        let target = try XCTUnwrap(
            RunResolver.target(repo: repo(homepage: "https://zen.vercel.app"), latest: nil)
        )
        XCTAssertEqual(target, .hosted(URL(string: "https://zen.vercel.app")!))
        XCTAssertTrue(target.isLive)
    }

    /// GitHub Pages lives at a predictable address, so no extra request is
    /// needed to know a repo can run.
    func testGitHubPagesIsUsedWhenThereIsNoHomepage() throws {
        let target = try XCTUnwrap(RunResolver.target(repo: repo(hasPages: true), latest: nil))
        XCTAssertEqual(target, .hosted(URL(string: "https://me.github.io/zen/")!))
    }

    func testAReleaseBundleBeatsADeployedSite() throws {
        let target = try XCTUnwrap(RunResolver.target(
            repo: repo(homepage: "https://zen.vercel.app"),
            latest: release("web.zip")
        ))
        guard case .bundle(let artifact, let releaseID, let tag) = target else {
            return XCTFail("the shipped build must win over a deployed site, got \(target)")
        }
        XCTAssertEqual(artifact.asset.name, "web.zip")
        XCTAssertEqual(releaseID, 5)
        XCTAssertEqual(tag, "v1.0.0")
        XCTAssertFalse(target.isLive)
    }

    /// An .ipa cannot run inside another app, so it does not make a repo
    /// runnable; the deployed site still does.
    func testAnIPAAloneDoesNotMakeARepoRunnable() {
        XCTAssertNil(RunResolver.target(repo: repo(), latest: release("App.ipa")))
        XCTAssertNotNil(RunResolver.target(
            repo: repo(homepage: "https://zen.vercel.app"), latest: release("App.ipa")
        ))
    }

    func testAnInsecureHomepageIsRefused() {
        XCTAssertNil(RunResolver.target(repo: repo(homepage: "http://zen.example"), latest: nil))
    }

    func testAnEmptyHomepageIsIgnored() {
        XCTAssertNil(RunResolver.target(repo: repo(homepage: "  "), latest: nil))
        XCTAssertNil(RunResolver.target(repo: repo(homepage: ""), latest: nil))
    }

    func testNothingRunnableGivesAdviceNamingTheRepo() {
        let advice = RunResolver.adviceWhenNotRunnable(repo: repo(name: "halite"))
        XCTAssertTrue(advice.contains("halite"), advice)
        XCTAssertTrue(advice.contains("index.html"), advice)
    }
}
