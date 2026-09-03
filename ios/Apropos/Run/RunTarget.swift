import Foundation

/// What Run opens. A release bundle is the exact build the owner shipped,
/// so it wins over a deployed site when both exist.
enum RunTarget: Equatable, Identifiable, Sendable {
    case bundle(artifact: Artifact, releaseID: Int, tag: String)
    case hosted(URL)

    var id: String {
        switch self {
        case .bundle(_, let releaseID, _): return "bundle-\(releaseID)"
        case .hosted(let url): return "hosted-\(url.absoluteString)"
        }
    }

    /// One line naming where the running app came from.
    var source: String {
        switch self {
        case .bundle(let artifact, _, let tag): return "\(tag) · \(artifact.asset.name)"
        case .hosted(let url): return url.host() ?? url.absoluteString
        }
    }

    var isLive: Bool {
        if case .hosted = self { return true }
        return false
    }
}

enum RunResolver {
    /// The best thing to run for a repository, or nil when nothing can.
    static func target(repo: Repo, latest: ScannedRelease?) -> RunTarget? {
        if let latest, let bundle = latest.webBundle {
            return .bundle(artifact: bundle, releaseID: latest.release.id, tag: latest.release.tagName)
        }
        if let site = repo.hostedSite {
            return .hosted(site)
        }
        return nil
    }

    /// What the owner would have to do to make this repo runnable.
    static func adviceWhenNotRunnable(repo: Repo) -> String {
        """
        Nothing here can run yet. Attach a built web app to a release as a \
        .zip containing an index.html, or set the repository's website field \
        to a deployed URL. Either one makes \(repo.name) run inside Apropos.
        """
    }
}
