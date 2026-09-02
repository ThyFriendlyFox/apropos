import Foundation

enum InstallRefusal: Equatable, Sendable {
    case noIOSBuild
    case simulatorBuildOnly(command: String)
    case privateRelease
    case appStoreSigned
    case noManifestHost
    case runningInSimulator

    var title: String {
        switch self {
        case .noIOSBuild: return "No iOS build on this release"
        case .simulatorBuildOnly: return "Simulator build only"
        case .privateRelease: return "Private release asset"
        case .appStoreSigned: return "Signed for the App Store"
        case .noManifestHost: return "Nowhere to publish the manifest"
        case .runningInSimulator: return "Installing needs a physical iPhone"
        }
    }

    var detail: String {
        switch self {
        case .noIOSBuild:
            return "This release has no .ipa. Attach one and it becomes installable."
        case .simulatorBuildOnly:
            return "This release ships a simulator bundle. A simulator build cannot run on a phone; iOS needs an .ipa."
        case .privateRelease:
            return "iOS fetches the build itself and cannot send your token. A private repository's release asset always fails. Make the release public, or attach the .ipa to a public repository."
        case .appStoreSigned:
            return "An App Store signature installs only through the App Store or TestFlight. Re-sign the build ad-hoc, for development, or with an enterprise certificate."
        case .noManifestHost:
            return "iOS installs from a manifest at an https URL. This release has no manifest, you cannot write to this repository, and no manifest host is set in Settings."
        case .runningInSimulator:
            return "The simulator has no App Store and no install pipeline. Build to your iPhone from Xcode, then install from there."
        }
    }
}

enum ManifestSource: Equatable, Sendable {
    /// The release already carries a `.plist`; nothing needs creating.
    case existingAsset(URL)
    /// A manifest host set in Settings builds the plist from query values.
    case hosted(URL)
    /// The manifest is generated here and attached to the release.
    case uploadToRelease
}

enum InstallPlan: Equatable, Sendable {
    case needsInspection(ipa: ReleaseAsset)
    case ready(manifest: ManifestSource, metadata: IPAMetadata)
    case refused(InstallRefusal)
}

struct InstallContext: Equatable, Sendable {
    let repo: Repo
    let scanned: ScannedRelease
    let metadata: IPAMetadata?
    let manifestHost: URL?
    let canWriteToRepo: Bool
}

/// Decides what tapping Install does. Pure, so every refusal has a test.
enum InstallPlanner {
    static func plan(_ context: InstallContext) -> InstallPlan {
        guard let ipa = context.scanned.deviceBuild?.asset else {
            if let simulator = context.scanned.simulatorBuild {
                return .refused(.simulatorBuildOnly(command: simulatorCommand(for: simulator.asset)))
            }
            return .refused(.noIOSBuild)
        }
        if context.repo.isPrivate { return .refused(.privateRelease) }

        guard let metadata = context.metadata else { return .needsInspection(ipa: ipa) }
        guard metadata.signing.canInstallOverTheAir else { return .refused(.appStoreSigned) }

        if let manifest = context.scanned.manifest?.asset.browserDownloadURL {
            return .ready(manifest: .existingAsset(manifest), metadata: metadata)
        }
        if let host = context.manifestHost,
           let hosted = hostedManifestURL(host: host, ipa: ipa, metadata: metadata, title: context.repo.name) {
            return .ready(manifest: .hosted(hosted), metadata: metadata)
        }
        if context.canWriteToRepo {
            return .ready(manifest: .uploadToRelease, metadata: metadata)
        }
        return .refused(.noManifestHost)
    }

    static func hostedManifestURL(host: URL, ipa: ReleaseAsset, metadata: IPAMetadata, title: String) -> URL? {
        guard host.scheme?.lowercased() == "https" else { return nil }
        var components = URLComponents(url: host, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "ipa", value: ipa.browserDownloadURL.absoluteString),
            URLQueryItem(name: "id", value: metadata.bundleID),
            URLQueryItem(name: "version", value: metadata.shortVersion),
            URLQueryItem(name: "title", value: title),
        ]
        return components?.url
    }

    /// What to run on a Mac to put a simulator build on a booted simulator.
    /// The app cannot do this itself; a sandboxed app cannot write into
    /// another app's container.
    static func simulatorCommand(for asset: ReleaseAsset) -> String {
        """
        curl -L -o /tmp/\(asset.name) "\(asset.browserDownloadURL.absoluteString)" \\
          && unzip -oq /tmp/\(asset.name) -d /tmp/sim-build \\
          && xcrun simctl install booted /tmp/sim-build/*.app
        """
    }
}
