import SwiftUI

struct RepoListView: View {
    @Environment(SessionStore.self) private var session
    let user: GitHubUser

    @State private var model: RepoListModel?
    @State private var index: ReleaseIndex?
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if let model, let index {
                    listBody(model, index: index)
                } else {
                    ProgressView()
                }
            }
            .background(Theme.background)
            .navigationTitle("Repositories")
            .navigationDestination(for: Repo.self) { RepoDetailView(repo: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                    .accessibilityIdentifier("account-menu")
                }
            }
        }
        .sheet(isPresented: $showingSettings) { SettingsView(user: user) }
        .task {
            if model == nil { model = RepoListModel(api: session.api) }
            if index == nil { index = ReleaseIndex(api: session.api) }
            await model?.loadFirstPageIfNeeded()
        }
    }

    @ViewBuilder
    private func emptyState(_ model: RepoListModel) -> some View {
        if model.repos.isEmpty {
            ContentUnavailableView {
                Label("No repositories", systemImage: "tray")
            } description: {
                Text("This account has no repositories Apropos can see. Sign in as a different account, or check the app's authorisation on GitHub.")
            }
        } else {
            ContentUnavailableView.search(text: model.query)
        }
    }

    @ViewBuilder
    private func listBody(_ model: RepoListModel, index: ReleaseIndex) -> some View {
        @Bindable var model = model
        if model.repos.isEmpty, case .failed(let message) = model.state {
            ContentUnavailableView {
                Label("Could not load repositories", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try again") { Task { await model.reload() } }
                    .buttonStyle(.borderedProminent)
            }
        } else if model.repos.isEmpty, model.state != .loaded {
            ProgressView("Loading repositories").controlSize(.large)
        } else {
            List {
                if let warning = session.persistenceWarning {
                    Label(warning, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardSurface(padding: 12)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        .accessibilityIdentifier("persistence-warning")
                }
                ForEach(model.visibleRepos) { repo in
                    NavigationLink(value: repo) {
                        RepoRow(repo: repo, entry: index.entry(for: repo))
                    }
                    .accessibilityIdentifier("repo-\(repo.name)")
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    .task {
                        await index.scanIfNeeded(repo)
                        if model.shouldLoadMore(after: repo) { await model.loadNextPage() }
                    }
                }
                if model.visibleRepos.isEmpty {
                    emptyState(model)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .searchable(text: $model.query, prompt: "Search repositories")
            .refreshable {
                index.forgetAll()
                await model.reload()
            }
        }
    }
}

struct RepoRow: View {
    let repo: Repo
    let entry: ReleaseIndex.Entry?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(repo.name)
                    .font(.headline)
                    .lineLimit(1)
                if repo.isPrivate {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer(minLength: 8)
                badge
            }

            if let description = repo.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(2)
            }

            HStack(spacing: 14) {
                if let language = repo.language {
                    Label(language, systemImage: "circle.fill")
                        .labelStyle(DotLabelStyle())
                }
                if repo.stargazersCount > 0 {
                    Label("\(repo.stargazersCount)", systemImage: "star")
                }
                if let pushedAt = repo.pushedAt {
                    Text(pushedAt, format: .relative(presentation: .numeric))
                }
            }
            .font(.caption)
            .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        // Keeps the badge queryable instead of being folded into the row's
        // combined accessibility label.
        .accessibilityElement(children: .contain)
    }

    /// Says how the latest release can be run. Running inside Apropos is
    /// the answer that needs no desktop, so it wins when both are true.
    @ViewBuilder
    private var badge: some View {
        if case .found(let scanned) = entry {
            if scanned.isRunnableInApropos {
                pill("Runs here", icon: "play.fill", tint: Theme.accent)
                    .accessibilityIdentifier("runs-here-badge")
            } else if scanned.isInstallable {
                pill("iOS build", icon: "iphone", tint: .white.opacity(0.55))
                    .accessibilityIdentifier("ios-build-badge")
            }
        }
    }

    private func pill(_ text: String, icon: String, tint: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.16), in: Capsule())
            .foregroundStyle(tint)
    }
}

private struct DotLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 5) {
            configuration.icon.font(.system(size: 7))
            configuration.title
        }
    }
}
