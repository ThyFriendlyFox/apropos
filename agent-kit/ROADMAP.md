# ROADMAP.md — the source of all work

**This file is not optional.** Every feature the agent builds flows down
from here. If it isn't on this roadmap, it doesn't get built; if it needs
building, it gets added here first. One item ships per weekly cycle
(see `WEEKLY.md`).

## North star

Repo Runner is a native iPhone app that turns a GitHub account into a
personal app store. The owner ships a build to a repo's Releases page,
opens Repo Runner on the phone, taps the repo, and runs that build. No
TestFlight, no cable, no Xcode on the phone side.

## Feature Queue — ordered; top unblocked item ships next

### 1. Clear the frozen web demo's lint debt
- **Promise:** `npx eslint src` reports 0 errors and 0 warnings, and
  `verify/lint.sh` gates all of `src/` instead of only `src/app/api`.
- **Evidence:** `verify/lint.sh` green with the wider scope.
- **Use case:** UC-6 — a clean gate is what makes the deploy steps
  trustworthy.
- **Scope guard:** No redesign of the demo. Lint only.
- **Status:** ready

### 2. Notify when a watched repo publishes a build
- **Promise:** Marking a repository as watched makes Repo Runner show a
  badge on next launch when that repository has published a release with
  an `.ipa` since the last time it was opened.
- **Evidence:** A unit test over the stored watermark, plus a UI test that
  the badge appears and clears.
- **Use case:** UC-4 — the developer wants the new build, not to go
  looking for it.
- **Scope guard:** No push notifications. In-app only; a push server would
  break the no-backend invariant.
- **Status:** ready

### 3. Show what is already on this phone
- **Promise:** A repository whose installed bundle identifier is present on
  the device shows the installed version next to the release list.
- **Evidence:** Unit tests over the version comparison; a screenshot of a
  repository with an older version installed.
- **Use case:** UC-4, UC-5.
- **Scope guard:** iOS gives no list of installed apps. This uses only what
  `canOpenURL` answers for a declared scheme, and says so when it cannot
  tell.
- **Status:** blocked on deciding whether requiring a URL scheme per app is
  acceptable

### 4. Sign in without creating an OAuth app
- **Promise:** A first-run user reaches the repo list without visiting
  github.com/settings/applications/new.
- **Evidence:** A fresh install signs in with no client ID configured.
- **Use case:** UC-1.
- **Scope guard:** No client secret in the binary, ever. A fine-grained
  personal access token pasted into the app is an acceptable answer.
- **Status:** ready

## Later — candidates, not yet specced

- Watch a repo and notify on a new release — the natural next step once
  installs work.
- Starred repos of other accounts, not just the owner's.
- Per-repo install history so the phone shows what version is on it.

## Shipped

| Week | Feature | Release | Evidence |
|---|---|---|---|
| 2026-09-01 | Ship-to-phone polish | unreleased | `docs/DEPLOY-TO-PHONE.md`; app icon, launch screen, search, pull to refresh, empty and error states with retry, sign out; `verify/verify.sh` green |
| 2026-09-01 | One-tap install of a release build | unreleased | `InstallPlannerTests` 10 cases, `InstallManifestTests` 5, `IPAInspectorTests` 11; `InstallSheetUITests` against the live `mouse` .ipa; `docs/screenshots/install-sheet.png` |
| 2026-09-01 | Release scanning and iOS artifact detection | unreleased | `ReleaseScannerTests`, 8 cases; `RepoBrowsingUITests` against `reagent-systems/mouse`; `docs/screenshots/repo-detail.png` |
| 2026-09-01 | Native iOS shell with GitHub device-flow sign-in | unreleased | `verify/verify.sh` green at `a40efa0`; `docs/screenshots/onboarding.png` and `docs/screenshots/repo-list.png` |

## Explicitly not doing

- Re-signing IPAs on device — impossible without the signing identity,
  and shipping one in an app is a leak.
- Installing simulator `.app` bundles from inside the app — iOS gives a
  sandboxed app no way to write into another app's container.
- Private-repo asset proxying — it needs a server holding the user's
  token. The app stays backendless.

## Queue changes

- 2026-09-01 — Seeded the queue for the native iOS rewrite. The prior
  Next.js surface stays as a web demo, not as the product.
- 2026-09-01 — Shipped item 1. The repo-list half of its promise is
  proven against live GitHub by `verify/simulator-smoke.sh`. The
  device-flow half is proven by `DeviceFlowAuthTests` only: an
  end-to-end run needs an OAuth client ID, which only the account owner
  can create.
- 2026-09-01 — Refilled the queue after shipping all four seeded items.
  The web demo's lint debt goes to the top because it is the one thing
  keeping `verify/lint.sh` from gating the whole repository.
- 2026-09-01 — Item 3 is marked blocked, not ready. iOS gives an app no
  list of installed apps, so the design question comes before the code.
