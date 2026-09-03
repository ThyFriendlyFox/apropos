import Foundation

struct GitHubUser: Codable, Equatable, Sendable {
    let login: String
    let name: String?
    let avatarURL: URL?

    enum CodingKeys: String, CodingKey {
        case login, name
        case avatarURL = "avatar_url"
    }
}

struct RepoOwner: Codable, Hashable, Sendable {
    let login: String
    let avatarURL: URL?

    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
    }
}

struct RepoPermissions: Codable, Hashable, Sendable {
    let push: Bool
}

struct Repo: Codable, Hashable, Sendable, Identifiable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let isPrivate: Bool
    let htmlURL: URL
    let pushedAt: Date?
    let stargazersCount: Int
    let language: String?
    /// A deployed URL the owner set on the repository. Most repos that are
    /// already live have one, which makes them runnable with no setup.
    let homepage: String?
    let hasPages: Bool?
    let owner: RepoOwner
    /// Absent when the listing was fetched without it; treated as no write
    /// access rather than assumed.
    let permissions: RepoPermissions?

    var canWrite: Bool { permissions?.push == true }

    /// The site to open when the release carries no bundle. GitHub Pages
    /// lives at a predictable address, so it needs no extra request.
    var hostedSite: URL? {
        if let homepage, let url = URL(string: homepage.trimmingCharacters(in: .whitespaces)),
           url.scheme?.lowercased() == "https", url.host() != nil {
            return url
        }
        if hasPages == true {
            return URL(string: "https://\(owner.login.lowercased()).github.io/\(name)/")
        }
        return nil
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, language, owner, permissions, homepage
        case fullName = "full_name"
        case isPrivate = "private"
        case htmlURL = "html_url"
        case pushedAt = "pushed_at"
        case stargazersCount = "stargazers_count"
        case hasPages = "has_pages"
    }
}

struct ReleaseAsset: Codable, Equatable, Sendable, Identifiable {
    let id: Int
    let name: String
    let size: Int
    let contentType: String?
    let browserDownloadURL: URL

    enum CodingKeys: String, CodingKey {
        case id, name, size
        case contentType = "content_type"
        case browserDownloadURL = "browser_download_url"
    }
}

struct Release: Codable, Equatable, Sendable, Identifiable {
    let id: Int
    let tagName: String
    let name: String?
    let body: String?
    let draft: Bool
    let prerelease: Bool
    let publishedAt: Date?
    let htmlURL: URL
    let assets: [ReleaseAsset]

    enum CodingKeys: String, CodingKey {
        case id, name, body, draft, prerelease, assets
        case tagName = "tag_name"
        case publishedAt = "published_at"
        case htmlURL = "html_url"
    }
}
