import SwiftUI

struct DeviceApprovalView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.openURL) private var openURL
    let code: DeviceCode

    @State private var copied = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Enter this code on GitHub")
                .font(.title2.bold())

            Text(code.userCode)
                .font(.system(size: 42, weight: .bold, design: .monospaced))
                .kerning(4)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity)
                .cardSurface(padding: 8)
                .accessibilityIdentifier("device-user-code")

            Button {
                UIPasteboard.general.string = code.userCode
                copied = true
            } label: {
                Label(copied ? "Copied" : "Copy code", systemImage: copied ? "checkmark" : "doc.on.doc")
            }
            .font(.subheadline)

            Button {
                openURL(code.verificationURL)
            } label: {
                Text("Open \(code.verificationURL.host() ?? "github.com")")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent)

            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Waiting for approval")
                    .foregroundStyle(Theme.secondaryText)
            }
            .font(.footnote)

            Spacer()

            Button("Cancel", role: .cancel) { session.cancelSignIn() }
                .padding(.bottom, 32)
        }
        .padding(.horizontal, 28)
    }
}
