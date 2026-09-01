# DEVLOG.md — append-only history

## 2026-09-01 — Native iOS shell lands

I installed the agent kit and pointed the project at a native iPhone app.
The Next.js surface in `src/` stays as a web demo. It is not the product.

What shipped:

- `ios/` holds a SwiftUI app, generated from `ios/project.yml` by
  xcodegen. Bundle id `com.thyfriendlyfox.reporunner`, iOS 17 minimum.
- GitHub OAuth device flow. It needs a client ID and no client secret,
  which is the only OAuth shape safe inside an app binary.
- The token goes to the Keychain. A test asserts it never reaches a URL.
- Repo list with search, pull to refresh, and paging.
- `verify/verify.sh`: regenerate, build with warnings as errors, 16 unit
  tests, then install and launch on a booted simulator.

Evidence: `verify/verify.sh` green. 16 tests, 0 failures. Screenshot at
`docs/screenshots/smoke.png` shows the Sign in with GitHub screen.

Next: release scanning, then install through `itms-services`.
