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
    let owner: RepoOwner
    /// Absent when the listing was fetched without it; treated as no write
    /// access rather than assumed.
    let permissions: RepoPermissions?

    var canWrite: Bool { permissions?.push == true }

    enum CodingKeys: String, CodingKey {
        case id, name, description, language, owner, permissions
        case fullName = "full_name"
        case isPrivate = "private"
        case htmlURL = "html_url"
        case pushedAt = "pushed_at"
        case stargazersCount = "stargazers_count"
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
