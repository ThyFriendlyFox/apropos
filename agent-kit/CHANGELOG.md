# Changelog

All notable changes to Apropos are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/) · Versioning: [SemVer](https://semver.org/).

## [Unreleased]

## [0.2.0] — 2026-09-02

### Added
- **Run a repo's release inside Apropos.** A release carrying a web bundle
  opens full screen in the app. The bundle is downloaded, unpacked into the
  app's container, and served from a loopback HTTP server, so an ordinary
  static build runs unchanged. Nothing is installed and no desktop is
  involved.
- Row badges say how a repo can be run: "Runs here" or "iOS build".
- Bundles are cached by release id, so a second run makes no network call.
- `verify/build-web.sh` exports the web surface as a release bundle.

### Changed
- Install is no longer the primary action on a release that can run.
- Archive entries are checked before writing; a name that escapes the
  destination folder is refused.


## [0.1.0] — 2026-09-01

### Added
- A native SwiftUI iPhone app in `ios/`, generated from `ios/project.yml`.
- Sign in with GitHub through the OAuth device flow. No client secret and
  no backend. The token is stored in the Keychain.
- Repository list with search, pull to refresh, and paging.
- Release scanning. A row shows an "iOS build" badge when the latest
  release carries an `.ipa`; the detail screen classifies every asset as an
  iPhone build, a simulator build, or an install manifest.
- Install through `itms-services://`. The `.ipa`'s bundle identifier,
  version, and signature are read over HTTP range requests, so the archive
  is never downloaded to identify it.
- Named refusals: no `.ipa`, simulator-only, private release asset, App
  Store signature, no manifest host, and running in the simulator.
- `src/app/api/manifest`, an optional manifest host for repositories the
  account cannot write to.
- `verify/verify.sh`: regenerate, build with source warnings as errors,
  unit tests, simulator install and launch, and UI tests against live
  GitHub that refresh `docs/screenshots/`.
- `docs/DEPLOY-TO-PHONE.md`.

### Changed
- The Next.js app in `src/` is a browser demo, not the product.
- Renamed the app to Apropos. Bundle id `com.thyfriendlyfox.apropos`.

### Fixed
- Sign-in reported "GitHub rejected the saved token" when the Keychain
  could not persist it. A simulator's ad-hoc signature carries no keychain
  entitlement, so the write failed with `errSecMissingEntitlement`, the
  read-back returned nothing, and `/user` answered 401. The token received
  is now the one used; the store is persistence only.
- A refused phone install hid the simulator archive on the same release.
- The simulator smoke gate reported a false crash. Piping the process
  listing into `grep -q` made the producer take SIGPIPE, which `pipefail`
  reported as a failure.
