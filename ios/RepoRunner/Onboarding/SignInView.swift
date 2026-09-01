import SwiftUI

struct SignInView: View {
    @Environment(SessionStore.self) private var session
    @State private var showingClientIDSheet = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            AppMark()
                .frame(width: 108, height: 108)

            Text("Repo Runner")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .padding(.top, 24)

            Text("Install the latest build from any of your GitHub repos, straight onto this phone.")
                .font(.callout)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 10)

            Spacer()

            VStack(spacing: 14) {
                Button {
                    if session.clientID == nil {
                        showingClientIDSheet = true
                    } else {
                        session.signIn()
                    }
                } label: {
                    Label("Sign in with GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("sign-in-with-github")

                Text("Repo Runner asks for the `repo` scope so it can list your private repositories and their releases. The token stays in this phone's Keychain.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)

                Button("Set OAuth client ID") { showingClientIDSheet = true }
                    .font(.footnote)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .alert(
            "Sign-in failed",
            isPresented: .init(get: { session.errorMessage != nil }, set: { if !$0 { session.dismissError() } })
        ) {
            Button("OK", role: .cancel) { session.dismissError() }
        } message: {
            Text(session.errorMessage ?? "")
        }
        .sheet(isPresented: $showingClientIDSheet) { ClientIDView() }
    }
}

/// The launch glyph, drawn rather than shipped as a second asset so it
/// always matches the app icon's proportions.
struct AppMark: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            RoundedRectangle(cornerRadius: w * 0.18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.9), lineWidth: w * 0.055)
                .overlay {
                    Image(systemName: "arrow.down.to.line")
                        .font(.system(size: w * 0.42, weight: .bold))
                        .foregroundStyle(Theme.accent)
                }
                .frame(width: w * 0.66, height: w)
                .frame(maxWidth: .infinity)
        }
    }
}

struct ClientIDView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var value: String = AppConfig.clientID ?? ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Iv1.0123456789abcdef", text: $value)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("OAuth client ID")
                } footer: {
                    Text("Repo Runner signs in with GitHub's device flow, which needs a client ID and no secret. Create an OAuth app on GitHub, enable device flow on it, and paste its client ID here. A value set in ios/Secrets.xcconfig at build time appears here already.")
                }

                Section {
                    Button("Create an OAuth app on GitHub") {
                        openURL(AppConfig.oauthAppSetupURL)
                    }
                }
            }
            .navigationTitle("Sign-in setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        session.setClientID(value)
                        dismiss()
                    }
                    .disabled(value.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
