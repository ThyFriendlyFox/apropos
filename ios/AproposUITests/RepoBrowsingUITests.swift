import XCTest

/// Drives the real app against live GitHub. `xcodebuild` forwards any
/// `TEST_RUNNER_`-prefixed variable to the runner with the prefix removed,
/// which is how the token reaches this process. With no token the tests
/// skip out loud rather than passing on nothing.
final class RepoBrowsingUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        let token = ProcessInfo.processInfo.environment["APROPOS_TOKEN"] ?? ""
        try XCTSkipIf(token.isEmpty, "no APROPOS_TOKEN; the signed-in UI gate needs one")
        app = XCUIApplication()
        app.launchEnvironment["APROPOS_TOKEN"] = token
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

/// Opens the install sheet against a live public `.ipa`. This proves the
/// range-read inspection end to end: the bundle identifier and the signature
/// come out of the real archive on GitHub, not out of a fixture.
final class InstallSheetUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        let token = ProcessInfo.processInfo.environment["APROPOS_TOKEN"] ?? ""
        try XCTSkipIf(token.isEmpty, "no APROPOS_TOKEN; the signed-in UI gate needs one")
        app = XCUIApplication()
        app.launchEnvironment["APROPOS_TOKEN"] = token
        app.launch()
    }

    func testInstallSheetReadsTheRealIPAAndRefusesAnAppStoreBuild() {
        XCTAssertTrue(app.navigationBars["Repositories"].waitForExistence(timeout: 20))

        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 20))
        field.tap()
        field.typeText("mouse")

        let row = app.descendants(matching: .any)["repo-mouse"]
        XCTAssertTrue(row.waitForExistence(timeout: 20))
        row.tap()

        let install = app.buttons["install-v1.4"]
        XCTAssertTrue(install.waitForExistence(timeout: 20))
        install.tap()

        // Read out of the .ipa itself, over range requests.
        XCTAssertTrue(
            app.staticTexts["com.reagentsystems.mouse.swift"].waitForExistence(timeout: 40),
            "the bundle identifier must come from the archive on GitHub"
        )
        XCTAssertTrue(app.staticTexts["Mouse"].exists)
        XCTAssertTrue(app.staticTexts["1.4 (1)"].exists)
        XCTAssertTrue(app.staticTexts["App Store signature"].exists)

        // An App Store signature can never install over the air, so the app
        // must name that reason rather than hand iOS a URL that fails.
        XCTAssertTrue(
            app.descendants(matching: .any)["install-refusal"].waitForExistence(timeout: 10),
            "an App Store build must be refused with its reason"
        )
        XCTAssertFalse(app.buttons["install-button"].exists)

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "install-sheet"
        shot.lifetime = .keepAlways
        add(shot)
    }
}

/// The core promise: a repo's release runs inside Apropos, on the phone,
/// with nothing installed and no desktop involved. Driven against the real
/// `apropos` release, which carries the web bundle.
final class RunInsideUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        let token = ProcessInfo.processInfo.environment["APROPOS_TOKEN"] ?? ""
        try XCTSkipIf(token.isEmpty, "no APROPOS_TOKEN; the signed-in UI gate needs one")
        app = XCUIApplication()
        app.launchEnvironment["APROPOS_TOKEN"] = token
        app.launch()
    }

    func testARepoReleaseRunsInsideApropos() {
        XCTAssertTrue(app.navigationBars["Repositories"].waitForExistence(timeout: 20))

        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 20))
        field.tap()
        field.typeText("apropos")

        let row = app.descendants(matching: .any)["repo-apropos"]
        XCTAssertTrue(row.waitForExistence(timeout: 20), "the apropos repository never appeared")
        row.tap()

        // Matched by prefix so a new tag does not break the gate.
        let run = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'run-'")).firstMatch
        XCTAssertTrue(run.waitForExistence(timeout: 20), "no release offered a Run button")
        run.tap()

        // Content from the downloaded bundle, rendered by the web view
        // inside Apropos.
        let heading = app.staticTexts["iOS Repo Runner"]
        XCTAssertTrue(
            heading.waitForExistence(timeout: 60),
            "the release's web app did not render inside Apropos"
        )
        XCTAssertTrue(app.descendants(matching: .any)["web-app"].exists)

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "running-inside"
        shot.lifetime = .keepAlways
        add(shot)

        // Still Apropos: the runner is a sheet with its own chrome.
        XCTAssertTrue(app.buttons["Done"].exists, "the run must stay inside Apropos, not leave it")
    }
}

/// A repo with no release at all still runs, because it has a deployed
/// site. This is the case that covers most repos with no setup.
final class RunHostedSiteUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        let token = ProcessInfo.processInfo.environment["APROPOS_TOKEN"] ?? ""
        try XCTSkipIf(token.isEmpty, "no APROPOS_TOKEN; the signed-in UI gate needs one")
        app = XCUIApplication()
        app.launchEnvironment["APROPOS_TOKEN"] = token
        app.launch()
    }

    func testARepoWithOnlyADeployedSiteRuns() {
        XCTAssertTrue(app.navigationBars["Repositories"].waitForExistence(timeout: 20))

        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 20))
        field.tap()
        field.typeText("openlawn")

        let row = app.descendants(matching: .any)["repo-openlawn"]
        XCTAssertTrue(row.waitForExistence(timeout: 20), "openlawn never appeared")
        row.tap()

        // openlawn has no release; the Run button comes from its homepage.
        let run = app.buttons["run-repo"]
        XCTAssertTrue(run.waitForExistence(timeout: 20), "a deployed site must make a repo runnable")
        XCTAssertFalse(
            app.descendants(matching: .any)["not-runnable"].exists,
            "a repo with a deployed site must not be called unrunnable"
        )
        run.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["web-app"].waitForExistence(timeout: 60),
            "the site did not open inside Apropos"
        )
        XCTAssertTrue(app.buttons["Done"].exists, "the run must stay inside Apropos")

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "running-hosted"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
