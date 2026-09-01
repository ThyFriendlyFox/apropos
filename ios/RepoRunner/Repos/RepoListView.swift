import SwiftUI

struct RepoListView: View {
    @Environment(SessionStore.self) private var session
    let user: GitHubUser

    @State private var model: RepoListModel?

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    listBody(model)
                } else {
                    ProgressView()
                }
            }
            .background(Theme.background)
            .navigationTitle("Repositories")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Text("Signed in as \(user.login)")
                        Button("Sign out", role: .destructive) { session.signOut() }
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                    .accessibilityIdentifier("account-menu")
                }
            }
        }
        .task {
            if model == nil { model = RepoListModel(api: session.api) }
            await model?.loadFirstPageIfNeeded()
        }
    }

    @ViewBuilder
    private func listBody(_ model: RepoListModel) -> some View {
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
                ForEach(model.visibleRepos) { repo in
                    RepoRow(repo: repo)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                        .task {
                            if model.shouldLoadMore(after: repo) { await model.loadNextPage() }
                        }
                }
                if model.visibleRepos.isEmpty {
                    ContentUnavailableView.search(text: model.query)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .searchable(text: $model.query, prompt: "Search repositories")
            .refreshable { await model.reload() }
        }
    }
}

struct RepoRow: View {
    let repo: Repo

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
                Spacer()
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
