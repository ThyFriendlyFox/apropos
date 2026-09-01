import XCTest

/// Drives the real app against live GitHub. `xcodebuild` forwards any
/// `TEST_RUNNER_`-prefixed variable to the runner with the prefix removed,
/// which is how the token reaches this process. With no token the tests
/// skip out loud rather than passing on nothing.
final class RepoBrowsingUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        let token = ProcessInfo.processInfo.environment["REPORUNNER_TOKEN"] ?? ""
        try XCTSkipIf(token.isEmpty, "no REPORUNNER_TOKEN; the signed-in UI gate needs one")
        app = XCUIApplication()
        app.launchEnvironment["REPORUNNER_TOKEN"] = token
        app.launch()
    }

    func testRepoListShowsAnIOSBuildBadgeForARepoWithAnIPA() {
        XCTAssertTrue(app.navigationBars["Repositories"].waitForExistence(timeout: 20))

        search(for: "mouse")

        let row = app.descendants(matching: .any)["repo-mouse"]
        XCTAssertTrue(row.waitForExistence(timeout: 20), "the mouse repository never appeared")
        XCTAssertTrue(
            app.staticTexts["iOS build"].waitForExistence(timeout: 20),
            "reagent-systems/mouse ships an .ipa on its latest release, so the badge must show"
        )
        attach(named: "repo-list-badge")
    }

    func testRepoDetailClassifiesEveryArtifact() {
        XCTAssertTrue(app.navigationBars["Repositories"].waitForExistence(timeout: 20))
        search(for: "mouse")

        let row = app.descendants(matching: .any)["repo-mouse"]
        XCTAssertTrue(row.waitForExistence(timeout: 20))
        row.tap()

        XCTAssertTrue(app.navigationBars["mouse"].waitForExistence(timeout: 20))
        XCTAssertTrue(
            app.descendants(matching: .any)["artifact-mouse-ios-v1.4.ipa"].waitForExistence(timeout: 20),
            "the .ipa asset must be listed"
        )
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "iPhone build")).firstMatch.exists)
        XCTAssertTrue(
            app.descendants(matching: .any)["artifact-mouse-ios-sim-v1.4.zip"].exists,
            "the simulator archive must be listed and classified separately"
        )
        XCTAssertFalse(
            app.descendants(matching: .any)["artifact-mouse-android-v1.4.apk"].exists,
            "an Android build is not an iOS artifact"
        )
        attach(named: "repo-detail")
    }

    private func search(for text: String) {
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 20))
        field.tap()
        field.typeText(text)
    }

    private func attach(named name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
