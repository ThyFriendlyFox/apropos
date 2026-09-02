import Foundation

/// What a release asset is good for. The distinction matters: an `.ipa`
/// installs on a phone and never on a simulator, and a simulator `.app`
/// bundle is the reverse. Confusing the two produces an install that
/// silently never appears.
enum ArtifactKind: String, Equatable, Sendable {
    case deviceApp
    case simulatorApp
    case manifest
    case webApp

    var label: String {
        switch self {
        case .deviceApp: return "iPhone build"
        case .simulatorApp: return "Simulator build"
        case .manifest: return "Install manifest"
        case .webApp: return "Runs in Apropos"
        }
    }

    var systemImage: String {
        switch self {
        case .deviceApp: return "iphone"
        case .simulatorApp: return "macwindow"
        case .manifest: return "doc.text"
        case .webApp: return "play.circle"
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
    var webBundle: Artifact? { artifacts.first { $0.kind == .webApp } }
    /// The only way to run this release without a desktop.
    var isRunnableInApropos: Bool { webBundle != nil }
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
        if name.hasSuffix(".html") || name.hasSuffix(".htm") { return .webApp }
        if name.hasSuffix(".app.zip") || name.hasSuffix(".app.tar.gz") { return .simulatorApp }

        let isArchive = name.hasSuffix(".zip") || name.hasSuffix(".tar.gz") || name.hasSuffix(".tgz")
        guard isArchive else { return nil }
        if name.contains("simulator") || name.contains("-sim") { return .simulatorApp }
        // Debug symbols and source snapshots are archives too, and neither
        // is something to run.
        for noise in ["dsym", "symbol", "source", "-src", "androidtest", ".apk"] where name.contains(noise) {
            return nil
        }
        // Only zip is unpacked; a tarball would need a second reader.
        guard name.hasSuffix(".zip") else { return nil }
        return .webApp
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
