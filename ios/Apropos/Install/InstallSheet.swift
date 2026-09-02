import SwiftUI

struct InstallSheet: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let repo: Repo
    let scanned: ScannedRelease

    @State private var coordinator: InstallCoordinator?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        if let coordinator {
                            if let metadata = coordinator.metadata {
                                BuildSummary(metadata: metadata, asset: scanned.deviceBuild?.asset)
                            }
                            body(for: coordinator)
                        } else {
                            ProgressView()
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(scanned.release.tagName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            if coordinator == nil {
                coordinator = InstallCoordinator(
                    repo: repo,
                    scanned: scanned,
                    api: session.api,
                    inspector: IPAInspector()
                )
            }
            await coordinator?.prepare()
        }
    }

    @ViewBuilder
    private func body(for coordinator: InstallCoordinator) -> some View {
        switch coordinator.step {
        case .idle, .inspecting:
            VStack(spacing: 12) {
                ProgressView().controlSize(.large)
                Text("Reading the build")
                    .foregroundStyle(Theme.secondaryText)
                Text("Apropos reads a few kilobytes of the .ipa to find its bundle identifier and signature.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 40)

        case .preparingManifest:
            VStack(spacing: 12) {
                ProgressView().controlSize(.large)
                Text("Attaching manifest.plist to the release")
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(.vertical, 40)

        case .plan(.ready(let source, let metadata)):
            ManifestNote(source: source)
            if coordinator.isSimulator {
                Notice(
                    title: InstallRefusal.runningInSimulator.title,
                    detail: InstallRefusal.runningInSimulator.detail,
                    tone: .neutral
                )
            } else {
                Button {
                    Task { await coordinator.install { openURL($0) } }
                } label: {
                    Label("Install \(metadata.displayName)", systemImage: "arrow.down.to.line")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("install-button")
            }

        case .plan(.refused(let refusal)):
            Notice(title: refusal.title, detail: refusal.detail, tone: .warning)
                .accessibilityIdentifier("install-refusal")
            // A phone install being refused does not make the release
            // useless: a simulator archive on the same release still runs
            // on a Mac.
            if let simulator = scanned.simulatorBuild {
                CommandBlock(command: InstallPlanner.simulatorCommand(for: simulator.asset))
            }

        case .plan(.needsInspection):
            ProgressView()

        case .handedToSystem:
            Notice(
                title: "iOS is installing it",
                detail: "Leave Apropos and watch the Home Screen. If a dialog asks to install, confirm it there.",
                tone: .good
            )

        case .failed(let message):
            Notice(title: "Install could not start", detail: message, tone: .warning)
        }
    }
}

private struct BuildSummary: View {
    let metadata: IPAMetadata
    let asset: ReleaseAsset?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(metadata.displayName)
                .font(.title3.bold())
            row("Bundle ID", metadata.bundleID)
            if !metadata.shortVersion.isEmpty {
                row("Version", "\(metadata.shortVersion) (\(metadata.buildVersion))")
            }
            row("Signing", metadata.signing.summary)
            if let asset {
                row("Size", ByteCountFormatter.string(fromByteCount: Int64(asset.size), countStyle: .file))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .accessibilityIdentifier("build-summary")
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
                .frame(width: 78, alignment: .leading)
            Text(value)
                .font(.footnote.monospaced())
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
    }
}

private struct ManifestNote: View {
    let source: ManifestSource

    var body: some View {
        Notice(title: title, detail: detail, tone: .neutral)
    }

    private var title: String {
        switch source {
        case .existingAsset: return "Installs from the release manifest"
        case .hosted: return "Installs through your manifest host"
        case .uploadToRelease: return "A manifest will be attached to the release"
        }
    }

    private var detail: String {
        switch source {
        case .existingAsset:
            return "This release already carries a manifest.plist, so nothing is written."
        case .hosted:
            return "The manifest host in Settings builds the plist iOS reads."
        case .uploadToRelease:
            return "Apropos attaches manifest.plist to this release once. It stays there, so later installs skip this step. Delete it from the release to undo."
        }
    }
}

private struct Notice: View {
    enum Tone { case good, neutral, warning }

    let title: String
    let detail: String
    let tone: Tone

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
            Text(detail)
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var icon: String {
        switch tone {
        case .good: return "checkmark.circle"
        case .neutral: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        }
    }

    private var color: Color {
        switch tone {
        case .good: return Theme.accent
        case .neutral: return .white
        case .warning: return .orange
        }
    }
}

private struct CommandBlock: View {
    let command: String
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Run this on your Mac to put it on a booted simulator:")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
            Text(command)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                UIPasteboard.general.string = command
                copied = true
            } label: {
                Label(copied ? "Copied" : "Copy command", systemImage: copied ? "checkmark" : "doc.on.doc")
                    .font(.footnote)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}
