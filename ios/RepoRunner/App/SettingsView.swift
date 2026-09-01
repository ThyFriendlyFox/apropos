import SwiftUI

struct SettingsView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let user: GitHubUser

    @State private var clientID: String = AppConfig.clientID ?? ""
    @State private var manifestHost: String = AppConfig.manifestHost?.absoluteString ?? ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    LabeledContent("Signed in as", value: user.login)
                    Button("Sign out", role: .destructive) {
                        session.signOut()
                        dismiss()
                    }
                }

                Section {
                    TextField("https://your-app.vercel.app/api/manifest", text: $manifestHost)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .font(.system(.footnote, design: .monospaced))
                } header: {
                    Text("Manifest host")
                } footer: {
                    Text("iOS installs from a plist at an https URL. Repo Runner attaches one to the release when you can write to the repository. For repositories you cannot write to, deploy src/app/api/manifest from this project and paste its URL here.")
                }

                Section {
                    TextField("Iv1.0123456789abcdef", text: $clientID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.footnote, design: .monospaced))
                    Button("Create an OAuth app on GitHub") {
                        openURL(AppConfig.oauthAppSetupURL)
                    }
                } header: {
                    Text("OAuth client ID")
                } footer: {
                    Text("Used for the device-flow sign-in. A value set in ios/Secrets.xcconfig at build time appears here already.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        AppConfig.setManifestHost(manifestHost)
                        session.setClientID(clientID)
                        dismiss()
                    }
                }
            }
        }
    }
}
