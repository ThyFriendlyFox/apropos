import XCTest
@testable import RepoRunner

/// Runs inside the host app, so it uses the app's entitlements.
///
/// A simulator build is signed ad hoc and carries no keychain entitlement,
/// so every write answers errSecMissingEntitlement (-34018). That is a
/// property of the signature, not of this code, so these tests skip with
/// the status rather than fail. A build signed with a real team — which is
/// every build that reaches a phone — runs them for real.
final class KeychainTokenStoreTests: XCTestCase {
    private let store = KeychainTokenStore.shared

    override func setUpWithError() throws {
        let status = store.writeStatus("probe")
        store.clear()
        try XCTSkipIf(
            status == errSecMissingEntitlement,
            "this build has no keychain entitlement (OSStatus \(status)); sign with a team to run these"
        )
        XCTAssertEqual(status, errSecSuccess, "unexpected Keychain status \(status)")
    }

    override func tearDown() {
        store.clear()
        super.tearDown()
    }

    func testWriteThenReadReturnsTheToken() throws {
        store.clear()
        XCTAssertTrue(store.write("gho_roundtrip"))
        XCTAssertEqual(store.read(), "gho_roundtrip")
    }

    func testWriteReplacesAnEarlierToken() throws {
        XCTAssertTrue(store.write("first"))
        XCTAssertTrue(store.write("second"))
        XCTAssertEqual(store.read(), "second")
    }

    func testClearRemovesTheToken() throws {
        XCTAssertTrue(store.write("gone"))
        store.clear()
        XCTAssertNil(store.read())
    }
}

/// A store that always fails to persist, standing in for a build with no
/// keychain entitlement.
final class FailingTokenStore: TokenStoring {
    func read() -> String? { nil }
    func write(_ token: String) -> Bool { false }
    func clear() {}
}

@MainActor
final class SessionStoreTests: XCTestCase {
    /// The bug this covers: sign-in used to read the token back out of the
    /// store, so a store that could not write turned a good token into a
    /// 401 and told the user GitHub had rejected it.
    func testSignInSucceedsWhenTheTokenCannotBePersisted() async throws {
        let transport = StubTransport([
            .init(json: """
            {"device_code":"dc","user_code":"WDJB-MJHT",
             "verification_uri":"https://github.com/login/device",
             "expires_in":900,"interval":1}
            """),
            .init(json: #"{"access_token":"gho_good"}"#),
            .init(json: #"{"login":"octocat","name":"The Octocat","avatar_url":null}"#),
        ])
        let session = SessionStore(transport: transport, tokens: FailingTokenStore())

        session.signIn()
        try await waitUntilSignedIn(session)

        guard case .signedIn(let user) = session.phase else {
            return XCTFail("expected a signed-in phase, got \(session.phase)")
        }
        XCTAssertEqual(user.login, "octocat")
        XCTAssertNil(session.errorMessage, "a storage failure is not a sign-in failure")
        XCTAssertNotNil(session.persistenceWarning, "the user must be told the token was not saved")

        // The token it just received is the one it uses, not one read back.
        let authorization = transport.sentRequests.last?.value(forHTTPHeaderField: "Authorization")
        XCTAssertEqual(authorization, "Bearer gho_good")
    }

    private func waitUntilSignedIn(_ session: SessionStore, timeout: TimeInterval = 10) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if case .signedIn = session.phase { return }
            if session.errorMessage != nil { return }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTFail("sign-in did not settle within \(timeout)s; phase is \(session.phase)")
    }
}
