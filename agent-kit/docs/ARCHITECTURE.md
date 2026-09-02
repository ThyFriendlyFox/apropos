# Architecture

The map a new contributor (or agent) reads before the first change. Tables
over prose. Keep it current: WEEKLY.md step 5 includes this file when a
feature moves a boundary.

Apropos is a SwiftUI iPhone app, iOS 17 and newer, with no server of
its own. The code has six parts.

| Part | Folder | Task |
|---|---|---|
| App shell | `ios/Apropos/App` | Scene, root routing by auth phase, Settings. |
| Core | `ios/Apropos/Core` | Models, the GitHub client, the device flow, the Keychain, session state. |
| Onboarding | `ios/Apropos/Onboarding` | Sign-in button, device-code screen, client-ID entry. |
| Repos | `ios/Apropos/Repos` | Repository list, release index, repository detail. |
| Install | `ios/Apropos/Install` | Range reads, ZIP and `.ipa` parsing, install planning, the install sheet. |
| Web surface | `src/` | A Next.js app. Its `/api/manifest` route is the optional manifest host. |

## Data flow — installing this morning's build

1. `SignInView` calls `SessionStore.signIn()`.
2. `DeviceFlowAuth` gets a user code from GitHub, and the view shows it.
   `awaitToken` polls until GitHub answers with an access token.
3. `TokenStore` writes the token to the Keychain. `SessionStore.phase`
   becomes `.signedIn`.
4. `RepoListModel` pages `/user/repos` through `GitHubAPI`.
5. As a row appears, `ReleaseIndex` fetches that repository's latest
   release once and `ReleaseScanner` classifies its assets. An `.ipa`
   puts the "iOS build" badge on the row.
6. Tapping the row opens `RepoDetailView`, which lists every release with
   its classified artifacts.
7. Tapping Install opens `InstallSheet`, which drives `InstallCoordinator`.
8. `IPAInspector` reads the `.ipa`'s end-of-central-directory, then its
   `Info.plist` and `embedded.mobileprovision`, over HTTP range requests.
   A few kilobytes answer what the whole archive would.
9. `InstallPlanner` turns the repository, the release, and that metadata
   into one plan: ready with a manifest source, or refused with a reason.
10. On a ready plan, the manifest is taken from the release, from the
    manifest host, or attached to the release by `GitHubAPI`.
11. `InstallManifest.installURL` builds the `itms-services://` URL and the
    coordinator hands it to iOS, which does the install.

## Boundaries

| Boundary | Rule |
|---|---|
| Views ↔ network | Views never build a `URLRequest`. Everything goes through `GitHubAPI` or `IPAInspector`. |
| `Transport` | The one seam. `URLSession` in the app, a stub in tests. See `docs/ADAPTERS.md`. |
| Token | Read only through `TokenStore`. Never in `UserDefaults`, a log, or a URL. |
| Pure vs effectful | `InstallPlanner`, `ReleaseScanner`, `ZipDirectory`, and `InstallManifest` are pure, so every branch has a test. `InstallCoordinator` holds the effects. |
| `ios/` ↔ `src/` | The app never depends on the web surface at runtime. The manifest host is an optional URL the user pastes in. |
