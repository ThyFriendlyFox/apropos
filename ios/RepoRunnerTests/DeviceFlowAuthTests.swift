import XCTest
@testable import RepoRunner

final class DeviceFlowAuthTests: XCTestCase {
    func testRequestCodeParsesTheChallenge() async throws {
        let transport = StubTransport([.init(json: """
        {"device_code":"dc","user_code":"WDJB-MJHT",
         "verification_uri":"https://github.com/login/device",
         "expires_in":900,"interval":5}
        """)])
        let code = try await DeviceFlowAuth(clientID: "Iv1.x", transport: transport).requestCode()

        XCTAssertEqual(code.userCode, "WDJB-MJHT")
        XCTAssertEqual(code.deviceCode, "dc")
        XCTAssertEqual(code.interval, 5)
        XCTAssertGreaterThan(code.expiresAt, Date())

        let body = try XCTUnwrap(transport.sentRequests.first?.httpBody.map { String(decoding: $0, as: UTF8.self) })
        XCTAssertTrue(body.contains("client_id=Iv1"), body)
        XCTAssertFalse(body.contains("client_secret"), "the device flow must never send a secret")
    }

    /// GitHub answers 200 with an error body while approval is pending.
    func testPendingPollReturnsNilNotAnError() async throws {
        let transport = StubTransport([.init(json: #"{"error":"authorization_pending"}"#)])
        let token = try await DeviceFlowAuth(clientID: "c", transport: transport).poll(Self.code)
        XCTAssertNil(token)
    }

    func testSlowDownPollReturnsNil() async throws {
        let transport = StubTransport([.init(json: #"{"error":"slow_down","interval":10}"#)])
        let token = try await DeviceFlowAuth(clientID: "c", transport: transport).poll(Self.code)
        XCTAssertNil(token)
    }

    func testApprovedPollReturnsTheToken() async throws {
        let transport = StubTransport([.init(json: #"{"access_token":"gho_abc","token_type":"bearer"}"#)])
        let token = try await DeviceFlowAuth(clientID: "c", transport: transport).poll(Self.code)
        XCTAssertEqual(token, "gho_abc")
    }

    func testDeniedPollThrows() async {
        let transport = StubTransport([.init(json: #"{"error":"access_denied"}"#)])
        do {
            _ = try await DeviceFlowAuth(clientID: "c", transport: transport).poll(Self.code)
            XCTFail("expected denial")
        } catch {
            XCTAssertEqual(error as? DeviceFlowError, .denied)
        }
    }

    func testExpiredPollThrows() async {
        let transport = StubTransport([.init(json: #"{"error":"expired_token"}"#)])
        do {
            _ = try await DeviceFlowAuth(clientID: "c", transport: transport).poll(Self.code)
            XCTFail("expected expiry")
        } catch {
            XCTAssertEqual(error as? DeviceFlowError, .expired)
        }
    }

    private static let code = DeviceCode(
        deviceCode: "dc",
        userCode: "WDJB-MJHT",
        verificationURL: URL(string: "https://github.com/login/device")!,
        interval: 5,
        expiresAt: Date().addingTimeInterval(900)
    )
}
