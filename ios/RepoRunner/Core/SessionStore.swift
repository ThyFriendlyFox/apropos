import Foundation

/// Owns who is signed in. Every view reads auth state from here.
@MainActor
@Observable
final class SessionStore {
    enum Phase: Equatable {
        case restoring
        case signedOut
        case awaitingApproval(DeviceCode)
        case signedIn(GitHubUser)
    }

    private(set) var phase: Phase = .restoring
    private(set) var errorMessage: String?
    /// Set when the token is good but could not be persisted. Sign-in still
    /// succeeded, so this is a notice, not an error.
    private(set) var persistenceWarning: String?
    private(set) var clientID: String? = AppConfig.clientID

    private let transport: Transport
    private let tokens: TokenStoring
    /// Authoritative for this run. The store is persistence, not the source
    /// of truth: a store that cannot write must not break sign-in.
    private var sessionToken: String?
    private var pollTask: Task<Void, Never>?

    init(transport: Transport = URLSession.shared, tokens: TokenStoring = KeychainTokenStore.shared) {
        self.transport = transport
        self.tokens = tokens
    }

    private var currentToken: String? {
        #if DEBUG
        if let injected = InjectedToken.value { return injected }
        #endif
        return sessionToken ?? tokens.read()
    }

    var api: GitHubAPI {
        let token = currentToken
        return GitHubAPI(transport: transport, token: { token })
    }

    func restore() async {
        guard currentToken != nil else {
            phase = .signedOut
            return
        }
        do {
            phase = .signedIn(try await api.currentUser())
        } catch GitHubError.unauthorized {
            tokens.clear()
            sessionToken = nil
            phase = .signedOut
            errorMessage = GitHubError.unauthorized.localizedDescription
        } catch {
            // Offline at launch is not a reason to throw the session away.
            phase = .signedOut
            errorMessage = error.localizedDescription
        }
    }

    func setClientID(_ value: String?) {
        AppConfig.setClientIDOverride(value)
        clientID = AppConfig.clientID
    }

    func signIn() {
        guard let clientID else {
            errorMessage = GitHubError.notConfigured.localizedDescription
            return
        }
        errorMessage = nil
        persistenceWarning = nil
        pollTask?.cancel()
        let auth = DeviceFlowAuth(clientID: clientID, transport: transport)
        pollTask = Task { [weak self] in
            do {
                let code = try await auth.requestCode()
                guard let self, !Task.isCancelled else { return }
                self.phase = .awaitingApproval(code)

                let token = try await auth.awaitToken(for: code)
                guard !Task.isCancelled else { return }

                // Hold the token before persisting it. Reading it back from
                // the store would turn a storage failure into a 401.
                self.sessionToken = token
                if !self.tokens.write(token) {
                    self.persistenceWarning = "This build cannot write to the Keychain, so the token is kept for this run only. You will sign in again after the app restarts."
                }
                self.phase = .signedIn(try await self.api.currentUser())
            } catch is CancellationError {
                return
            } catch {
                guard let self, !Task.isCancelled else { return }
                self.sessionToken = nil
                self.errorMessage = error.localizedDescription
                self.phase = .signedOut
            }
        }
    }

    func cancelSignIn() {
        pollTask?.cancel()
        pollTask = nil
        phase = .signedOut
    }

    func signOut() {
        pollTask?.cancel()
        pollTask = nil
        sessionToken = nil
        tokens.clear()
        errorMessage = nil
        persistenceWarning = nil
        phase = .signedOut
    }

    func dismissError() { errorMessage = nil }
}
