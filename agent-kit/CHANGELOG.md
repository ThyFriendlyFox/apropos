# Changelog

All notable changes to Apropos are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/) · Versioning: [SemVer](https://semver.org/).

## [Unreleased]

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

### Fixed
- The simulator smoke gate reported a false crash. Piping the process
  listing into `grep -q` made the producer take SIGPIPE, which `pipefail`
  reported as a failure.
