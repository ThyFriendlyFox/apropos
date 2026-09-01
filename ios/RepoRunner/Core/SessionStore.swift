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
    private(set) var clientID: String? = AppConfig.clientID

    private let transport: Transport
    private let tokens: TokenStore
    private var pollTask: Task<Void, Never>?

    init(transport: Transport = URLSession.shared, tokens: TokenStore = .shared) {
        self.transport = transport
        self.tokens = tokens
    }

    var api: GitHubAPI {
        let tokens = self.tokens
        return GitHubAPI(transport: transport, token: { tokens.read() })
    }

    func restore() async {
        guard tokens.read() != nil else {
            phase = .signedOut
            return
        }
        do {
            phase = .signedIn(try await api.currentUser())
        } catch GitHubError.unauthorized {
            tokens.clear()
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
        pollTask?.cancel()
        let auth = DeviceFlowAuth(clientID: clientID, transport: transport)
        pollTask = Task { [weak self] in
            do {
                let code = try await auth.requestCode()
                guard let self, !Task.isCancelled else { return }
                self.phase = .awaitingApproval(code)
                let token = try await auth.awaitToken(for: code)
                guard !Task.isCancelled else { return }
                self.tokens.write(token)
                self.phase = .signedIn(try await self.api.currentUser())
            } catch is CancellationError {
                return
            } catch {
                guard let self, !Task.isCancelled else { return }
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
        tokens.clear()
        errorMessage = nil
        phase = .signedOut
    }

    func dismissError() { errorMessage = nil }
}
