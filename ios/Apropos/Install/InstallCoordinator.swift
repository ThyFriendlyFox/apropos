import Foundation
import UIKit

/// Runs the install: inspect the `.ipa`, settle on a manifest, then hand
/// iOS an `itms-services://` URL. iOS gives an app no other way to install
/// another app.
@MainActor
@Observable
final class InstallCoordinator {
    enum Step: Equatable {
        case idle
        case inspecting
        case preparingManifest
        case plan(InstallPlan)
        case handedToSystem
        case failed(String)
    }

    private(set) var step: Step = .idle

    private let api: GitHubAPI
    private let inspector: IPAInspector
    private let repo: Repo
    private let scanned: ScannedRelease
    private(set) var metadata: IPAMetadata?

    init(repo: Repo, scanned: ScannedRelease, api: GitHubAPI, inspector: IPAInspector) {
        self.repo = repo
        self.scanned = scanned
        self.api = api
        self.inspector = inspector
    }

    var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    private var context: InstallContext {
        InstallContext(
            repo: repo,
            scanned: scanned,
            metadata: metadata,
            manifestHost: AppConfig.manifestHost,
            canWriteToRepo: repo.canWrite
        )
    }

    func prepare() async {
        guard step == .idle else { return }
        switch InstallPlanner.plan(context) {
        case .needsInspection(let ipa):
            step = .inspecting
            do {
                metadata = try await inspector.inspect(ipa.browserDownloadURL)
            } catch {
                step = .failed(error.localizedDescription)
                return
            }
            step = .plan(InstallPlanner.plan(context))
        case let settled:
            step = .plan(settled)
        }
    }

    /// Publishes the manifest if it does not exist yet, then opens the
    /// install. On a simulator it stops with the reason instead.
    func install(openURL: @MainActor (URL) -> Void) async {
        guard case .plan(.ready(let source, let metadata)) = step else { return }
        if isSimulator {
            step = .plan(.refused(.runningInSimulator))
            return
        }
        guard let ipa = scanned.deviceBuild?.asset else { return }

        let manifestURL: URL
        switch source {
        case .existingAsset(let url), .hosted(let url):
            manifestURL = url
        case .uploadToRelease:
            step = .preparingManifest
            let body = InstallManifest.plist(
                ipaURL: ipa.browserDownloadURL,
                metadata: metadata,
                title: repo.name
            )
            do {
                let asset = try await api.uploadReleaseAsset(
                    owner: repo.owner.login,
                    repo: repo.name,
                    releaseID: scanned.release.id,
                    name: Self.manifestAssetName,
                    contentType: "text/xml",
                    body: Data(body.utf8)
                )
                manifestURL = asset.browserDownloadURL
            } catch {
                step = .failed(error.localizedDescription)
                return
            }
        }

        guard let install = InstallManifest.installURL(manifestURL: manifestURL) else {
            step = .failed("The manifest URL is not https, so iOS will not read it.")
            return
        }
        openURL(install)
        step = .handedToSystem
    }

    static let manifestAssetName = "manifest.plist"
}
