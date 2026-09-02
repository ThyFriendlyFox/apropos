import SwiftUI
import WebKit

struct WebAppView: View {
    @Environment(\.dismiss) private var dismiss

    let repo: Repo
    let scanned: ScannedRelease
    let artifact: Artifact

    @State private var runner: WebAppRunner?
    @State private var reloadToken = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content
            }
            .navigationTitle(repo.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        runner?.stop()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Reload") { reloadToken += 1 }
                        Button("Download again") {
                            Task { await runner?.reinstall() }
                        }
                        Text(scanned.release.tagName)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onDisappear { runner?.stop() }
        .task {
            if runner == nil {
                runner = WebAppRunner(artifact: artifact, releaseID: scanned.release.id)
            }
            await runner?.start()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch runner?.step {
        case .running(let base):
            WebView(url: base, reloadToken: reloadToken)
                .ignoresSafeArea(edges: .bottom)
                .accessibilityIdentifier("web-app")
        case .failed(let message):
            ContentUnavailableView {
                Label("Could not run this build", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try again") { Task { await runner?.reinstall() } }
                    .buttonStyle(.borderedProminent)
            }
        default:
            VStack(spacing: 12) {
                ProgressView().controlSize(.large)
                Text("Fetching \(scanned.release.tagName)")
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }
}

/// A web view pointed at the loopback server. The app runs inside Apropos;
/// nothing is installed and nothing leaves the container.
private struct WebView: UIViewRepresentable {
    let url: URL
    let reloadToken: Int

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let view = WKWebView(frame: .zero, configuration: configuration)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.load(URLRequest(url: url))
        context.coordinator.loadedToken = reloadToken
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        if context.coordinator.loadedToken != reloadToken {
            context.coordinator.loadedToken = reloadToken
            view.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var loadedToken = -1
    }
}
