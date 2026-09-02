import Foundation
import Security

/// Where the GitHub token is persisted. Never UserDefaults, never a log
/// line, never a URL.
protocol TokenStoring: Sendable {
    func read() -> String?
    /// False when the token could not be persisted. The caller must not
    /// treat that as a sign-in failure; the token is still valid for this
    /// run.
    @discardableResult
    func write(_ token: String) -> Bool
    func clear()
}

struct KeychainTokenStore: TokenStoring {
    private let service = "com.thyfriendlyfox.apropos"
    private let account = "github-access-token"

    static let shared = KeychainTokenStore()

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    func read() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    func write(_ token: String) -> Bool {
        writeStatus(token) == errSecSuccess
    }

    /// The raw status, so a failing gate names the reason instead of just
    /// saying false. `-34018` is errSecMissingEntitlement.
    func writeStatus(_ token: String) -> OSStatus {
        SecItemDelete(baseQuery as CFDictionary)
        var insert = baseQuery
        insert[kSecValueData as String] = Data(token.utf8)
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(insert as CFDictionary, nil)
    }

    func clear() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}
