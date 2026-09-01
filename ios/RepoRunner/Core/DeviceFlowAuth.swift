import Foundation

struct DeviceCode: Equatable, Sendable {
    let deviceCode: String
    let userCode: String
    let verificationURL: URL
    let interval: TimeInterval
    let expiresAt: Date
}

enum DeviceFlowError: LocalizedError, Equatable {
    case denied
    case expired
    case github(String)

    var errorDescription: String? {
        switch self {
        case .denied: return "The sign-in request was denied on GitHub."
        case .expired: return "The code expired. Start again."
        case .github(let slug): return "GitHub refused the sign-in: \(slug)."
        }
    }
}

/// GitHub's OAuth device flow. It needs a client ID and no client secret,
/// which is the only OAuth shape safe to ship inside an app binary.
struct DeviceFlowAuth: Sendable {
    private let transport: Transport
    private let clientID: String

    init(clientID: String, transport: Transport = URLSession.shared) {
        self.clientID = clientID
        self.transport = transport
    }

    func requestCode() async throws -> DeviceCode {
        let body = try await form(
            url: URL(string: "https://github.com/login/device/code")!,
            fields: ["client_id": clientID, "scope": AppConfig.scope]
        )
        guard let deviceCode = body["device_code"],
              let userCode = body["user_code"],
              let uri = body["verification_uri"], let url = URL(string: uri) else {
            throw DeviceFlowError.github(body["error"] ?? "malformed device code response")
        }
        let interval = TimeInterval(body["interval"] ?? "5") ?? 5
        let expiresIn = TimeInterval(body["expires_in"] ?? "900") ?? 900
        return DeviceCode(
            deviceCode: deviceCode,
            userCode: userCode,
            verificationURL: url,
            interval: max(interval, 1),
            expiresAt: Date().addingTimeInterval(expiresIn)
        )
    }

    /// One poll. GitHub answers HTTP 200 with an `error` field while the
    /// user has not approved yet, so the status code alone proves nothing.
    /// Returns nil to mean "ask again after `nextInterval`".
    func poll(_ code: DeviceCode) async throws -> String? {
        let body = try await form(
            url: URL(string: "https://github.com/login/oauth/access_token")!,
            fields: [
                "client_id": clientID,
                "device_code": code.deviceCode,
                "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
            ]
        )
        if let token = body["access_token"] { return token }
        switch body["error"] {
        case "authorization_pending", "slow_down": return nil
        case "access_denied": throw DeviceFlowError.denied
        case "expired_token": throw DeviceFlowError.expired
        case let other?: throw DeviceFlowError.github(other)
        case nil: throw DeviceFlowError.github("empty response")
        }
    }

    /// Polls until GitHub returns a token, the code expires, or the task is
    /// cancelled. Backs off by 5 seconds whenever GitHub says `slow_down`.
    func awaitToken(for code: DeviceCode) async throws -> String {
        var interval = code.interval
        while Date() < code.expiresAt {
            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            try Task.checkCancellation()
            if let token = try await poll(code) { return token }
            interval += 0.5
        }
        throw DeviceFlowError.expired
    }

    private func form(url: URL, fields: [String: String]) async throws -> [String: String] {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = Data(
            fields.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? $0.value)" }
                .sorted()
                .joined(separator: "&")
                .utf8
        )
        let (data, response) = try await transport.send(request)
        guard (200..<300).contains(response.statusCode) else {
            throw DeviceFlowError.github("HTTP \(response.statusCode)")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return json.reduce(into: [String: String]()) { result, pair in
            result[pair.key] = String(describing: pair.value)
        }
    }
}
