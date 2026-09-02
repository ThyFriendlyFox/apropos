import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content
        }
        .task {
            if case .restoring = session.phase { await session.restore() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch session.phase {
        case .restoring:
            ProgressView().controlSize(.large)
        case .signedOut:
            SignInView()
        case .awaitingApproval(let code):
            DeviceApprovalView(code: code)
        case .signedIn(let user):
            RepoListView(user: user)
        }
    }
}
