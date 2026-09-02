import Foundation

/// Where the OAuth client ID comes from. The build sets it through
/// `ios/Secrets.xcconfig`; a user can paste one at runtime instead.
enum AppConfig {
    private static let overrideKey = "github.client.id.override"

    static var clientID: String? {
        if let stored = UserDefaults.standard.string(forKey: overrideKey), !stored.isEmpty {
            return stored
        }
        let built = Bundle.main.object(forInfoDictionaryKey: "GitHubClientID") as? String
        guard let built, !built.isEmpty else { return nil }
        return built
    }

    static func setClientIDOverride(_ value: String?) {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            UserDefaults.standard.set(trimmed, forKey: overrideKey)
        } else {
            UserDefaults.standard.removeObject(forKey: overrideKey)
        }
    }

    /// `repo` is the narrowest OAuth scope that still lists private
    /// repositories and their releases. OAuth apps have no finer grain.
    static let scope = "repo read:user"

    static let oauthAppSetupURL = URL(string: "https://github.com/settings/applications/new")!

    private static let manifestHostKey = "manifest.host"

    /// An https endpoint that turns query values into an install manifest.
    /// `src/app/api/manifest/route.ts` in this repository is one; deploy it
    /// and paste its URL. Only needed when a release carries no manifest and
    /// the account cannot write to the repository.
    static var manifestHost: URL? {
        guard let raw = UserDefaults.standard.string(forKey: manifestHostKey),
              let url = URL(string: raw), url.scheme?.lowercased() == "https" else { return nil }
        return url
    }

    static func setManifestHost(_ value: String?) {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            UserDefaults.standard.set(trimmed, forKey: manifestHostKey)
        } else {
            UserDefaults.standard.removeObject(forKey: manifestHostKey)
        }
    }
}
