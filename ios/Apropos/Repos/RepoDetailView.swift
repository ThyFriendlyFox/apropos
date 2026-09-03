import SwiftUI

struct RepoDetailView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.openURL) private var openURL
    let repo: Repo

    @State private var releases: [ScannedRelease] = []
    @State private var state: LoadState = .loading
    @State private var runTarget: RunTarget?

    enum LoadState: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content
        }
        .navigationTitle(repo.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    openURL(repo.htmlURL)
                } label: {
                    Image(systemName: "safari")
                }
                .accessibilityLabel("Open on GitHub")
            }
        }
        .fullScreenCover(item: $runTarget) { target in
            WebAppView(repo: repo, target: target)
        }
        .task { await load() }
        .refreshable { await load() }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ProgressView("Reading releases").controlSize(.large)
        case .failed(let message):
            ContentUnavailableView {
                Label("Could not read releases", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try again") { Task { await load() } }
                    .buttonStyle(.borderedProminent)
            }
        case .loaded:
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Runnability does not depend on releases existing: a
                    // deployed site makes a repo runnable on its own.
                    runHeader
                    if releases.isEmpty {
                        Notice(
                            title: "No releases",
                            detail: "\(repo.name) has no published release. Attach a built web app as a .zip to run that exact build here, or an .ipa to install it on the Home Screen.",
                            tone: .neutral
                        )
                    } else {
                        ForEach(releases) { scanned in
                            ReleaseCard(repo: repo, scanned: scanned)
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    /// The one action that matters, at the top, whatever the releases hold.
    @ViewBuilder
    private var runHeader: some View {
        if let target = RunResolver.target(repo: repo, latest: releases.first) {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    runTarget = target
                } label: {
                    Label("Run \(repo.name)", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("run-repo")

                Text(target.isLive
                     ? "Opens the live site at \(target.source) inside Apropos."
                     : "Runs the build from \(target.source) inside Apropos.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface()
        } else {
            Notice(
                title: "Nothing to run yet",
                detail: RunResolver.adviceWhenNotRunnable(repo: repo)
            )
            .accessibilityIdentifier("not-runnable")
        }
    }

    private func load() async {
        do {
            let fetched = try await session.api.releases(owner: repo.owner.login, repo: repo.name)
            releases = ReleaseScanner.scan(fetched)
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

struct ReleaseCard: View {
    @Environment(\.openURL) private var openURL
    let repo: Repo
    let scanned: ScannedRelease

    @State private var showingInstall = false
    @State private var runningTarget: RunTarget?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(scanned.release.name?.isEmpty == false ? scanned.release.name! : scanned.release.tagName)
                    .font(.headline)
                Spacer()
                if scanned.release.prerelease {
                    Text("pre-release")
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.18), in: Capsule())
                        .foregroundStyle(.orange)
                }
            }

            HStack(spacing: 10) {
                Text(scanned.release.tagName)
                    .font(.caption.monospaced())
                if let published = scanned.release.publishedAt {
                    Text(published, format: .relative(presentation: .numeric))
                        .font(.caption)
                }
            }
            .foregroundStyle(Theme.secondaryText)

            if scanned.artifacts.isEmpty {
                Text("Nothing on this release can run. Attach a built web app as a .zip and Apropos runs it here; attach an .ipa to install it on the Home Screen.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            } else {
                VStack(spacing: 8) {
                    ForEach(scanned.artifacts) { artifact in
                        ArtifactRow(artifact: artifact)
                    }
                }
            }

            HStack(spacing: 16) {
                if let web = scanned.webBundle {
                    Button {
                        runningTarget = .bundle(
                            artifact: web,
                            releaseID: scanned.release.id,
                            tag: scanned.release.tagName
                        )
                    } label: {
                        Label("Run", systemImage: "play.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .accessibilityIdentifier("run-\(scanned.release.tagName)")
                }
                if scanned.deviceBuild != nil || scanned.simulatorBuild != nil {
                    Button {
                        showingInstall = true
                    } label: {
                        Label("Install", systemImage: "arrow.down.to.line")
                            .font(.subheadline.weight(.semibold))
                    }
                    // Run is the primary action whenever the release can
                    // run, so Install steps back to a plain button.
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(scanned.webBundle == nil ? Theme.accent : Color.white.opacity(0.5))
                    .accessibilityIdentifier("install-\(scanned.release.tagName)")
                }
                Spacer()
                Button {
                    openURL(scanned.release.htmlURL)
                } label: {
                    Label("Release notes", systemImage: "arrow.up.right")
                        .font(.footnote)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .sheet(isPresented: $showingInstall) {
            InstallSheet(repo: repo, scanned: scanned)
        }
        .fullScreenCover(item: $runningTarget) { target in
            WebAppView(repo: repo, target: target)
        }
    }
}

struct ArtifactRow: View {
    let artifact: Artifact

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: artifact.kind.systemImage)
                .frame(width: 22)
                .foregroundStyle(artifact.kind == .deviceApp ? Theme.accent : Theme.secondaryText)
            VStack(alignment: .leading, spacing: 2) {
                Text(artifact.asset.name)
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text("\(artifact.kind.label) · \(Self.size.string(fromByteCount: Int64(artifact.asset.size)))")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("artifact-\(artifact.asset.name)")
    }

    private static let size: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()
}
