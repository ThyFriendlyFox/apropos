import Foundation

/// What a release asset is good for. The distinction matters: an `.ipa`
/// installs on a phone and never on a simulator, and a simulator `.app`
/// bundle is the reverse. Confusing the two produces an install that
/// silently never appears.
enum ArtifactKind: String, Equatable, Sendable {
    case deviceApp
    case simulatorApp
    case manifest

    var label: String {
        switch self {
        case .deviceApp: return "iPhone build"
        case .simulatorApp: return "Simulator build"
        case .manifest: return "Install manifest"
        }
    }

    var systemImage: String {
        switch self {
        case .deviceApp: return "iphone"
        case .simulatorApp: return "macwindow"
        case .manifest: return "doc.text"
        }
    }
}

struct Artifact: Equatable, Sendable, Identifiable {
    let asset: ReleaseAsset
    let kind: ArtifactKind

    var id: Int { asset.id }
}

struct ScannedRelease: Equatable, Sendable, Identifiable {
    let release: Release
    let artifacts: [Artifact]

    var id: Int { release.id }

    var deviceBuild: Artifact? { artifacts.first { $0.kind == .deviceApp } }
    var manifest: Artifact? { artifacts.first { $0.kind == .manifest } }
    var simulatorBuild: Artifact? { artifacts.first { $0.kind == .simulatorApp } }
    var isInstallable: Bool { deviceBuild != nil }
}

enum ReleaseScanner {
    /// Classifies by file name. GitHub's `content_type` is whatever the
    /// uploader sent, so it is not trustworthy on its own.
    static func classify(_ asset: ReleaseAsset) -> ArtifactKind? {
        let name = asset.name.lowercased()
        if name.hasSuffix(".ipa") { return .deviceApp }
        if name.hasSuffix(".plist") { return .manifest }
        if name.hasSuffix(".app.zip") || name.hasSuffix(".app.tar.gz") { return .simulatorApp }
        let isArchive = name.hasSuffix(".zip") || name.hasSuffix(".tar.gz") || name.hasSuffix(".tgz")
        if isArchive, name.contains("simulator") || name.contains("-sim") { return .simulatorApp }
        return nil
    }

    static func scan(_ release: Release) -> ScannedRelease {
        let artifacts = release.assets.compactMap { asset in
            classify(asset).map { Artifact(asset: asset, kind: $0) }
        }
        return ScannedRelease(release: release, artifacts: artifacts)
    }

    /// Drafts never carry a downloadable asset URL a phone can reach, so
    /// they are dropped before anything else looks at the list.
    static func scan(_ releases: [Release]) -> [ScannedRelease] {
        releases.filter { !$0.draft }.map(scan)
    }
}
