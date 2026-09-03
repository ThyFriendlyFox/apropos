# ROADMAP.md — the source of all work

**This file is not optional.** Every feature the agent builds flows down
from here. If it isn't on this roadmap, it doesn't get built; if it needs
building, it gets added here first. One item ships per weekly cycle
(see `WEEKLY.md`).

## North star

Apropos is a phone-only app runner. Any repo whose release carries a
mobile app opens *inside* Apropos and is playable there. The owner never
touches a desktop to run one, never signs anything, and never installs
anything. Apropos ships its own web build, so it appears in its own list.

Installing a native `.ipa` to the Home Screen stays as a secondary path
for builds that are signed for it. It is not the main way to run a repo,
because iOS gates it behind a Mac.

## Feature Queue — ordered; top unblocked item ships next

### 1. Clear the frozen web demo's lint debt
- **Promise:** `npx eslint src` reports 0 errors and 0 warnings, and
  `verify/lint.sh` gates all of `src/`.
- **Evidence:** `verify/lint.sh` green with the wider scope.
- **Use case:** UC-6.
- **Scope guard:** Lint only.
- **Status:** ready

### 2. Remember what was run
- **Promise:** The repo list has a section at the top holding the repos
  run most recently, so getting back to one is a single tap.
- **Evidence:** A UI test that a run appears there afterwards.
- **Use case:** UC-7.
- **Scope guard:** No sync between devices.
- **Status:** ready

### 3. Set a repo's site from inside Apropos
- **Promise:** A repo with nothing runnable offers to set its website
  field, so it becomes runnable without leaving the app.
- **Evidence:** A UI test against a repo the account can write to.
- **Use case:** UC-5, UC-7.
- **Scope guard:** Only the homepage field. No other repository settings.
- **Status:** ready

## Later — candidates, not yet specced

- Watch a repo and notify on a new release — the natural next step once
  installs work.
- Starred repos of other accounts, not just the owner's.
- Per-repo install history so the phone shows what version is on it.

## Shipped

| Week | Feature | Release | Evidence |
|---|---|---|---|
| 2026-09-02 | Say what to do when a repo cannot run | v0.3.0 | The detail screen names the one action that fixes it |
| 2026-09-02 | One obvious button on a repo | v0.3.0 | A single Run button at the top; Install shows only where an install is possible |
| 2026-09-02 | Run any repo that already has a live site | v0.3.0 | `RunResolverTests`, 7 cases; `RunHostedSiteUITests` runs `openlawn`, which has no release at all; `docs/screenshots/running-hosted.png` |
| 2026-09-02 | Publish a runnable bundle from a tag | v0.2.1 | `.github/workflows/build-web-bundle.yml`; v0.2.1's `apropos-web.zip` was built and attached by CI with no local build |
| 2026-09-02 | Keep a run where you left it | v0.2.0 | `WebAppStoreTests.testASecondRunUsesTheCachedCopy`: the bundle is downloaded once per release id |
| 2026-09-02 | Apropos ships its own web build | v0.2.0 | `verify/build-web.sh`; the v0.2.0 release carries `apropos-web-v0.2.0.zip`; `docs/screenshots/running-inside.png` is Apropos running Apropos |
| 2026-09-02 | Detect what a release can run | v0.2.0 | `ReleaseScannerTests`, 13 cases; the row badge reads "Runs here" or "iOS build" |
| 2026-09-02 | Run a release's web app inside Apropos | v0.2.0 | `RunInsideUITests` drives Run on the real release and asserts the app's own content renders inside Apropos |
| 2026-09-01 | Ship-to-phone polish | v0.1.0 | `docs/DEPLOY-TO-PHONE.md`; app icon, launch screen, search, pull to refresh, empty and error states with retry, sign out; `verify/verify.sh` green |
| 2026-09-01 | One-tap install of a release build | v0.1.0 | `InstallPlannerTests` 10 cases, `InstallManifestTests` 5, `IPAInspectorTests` 11; `InstallSheetUITests` against the live `mouse` .ipa; `docs/screenshots/install-sheet.png` |
| 2026-09-01 | Release scanning and iOS artifact detection | v0.1.0 | `ReleaseScannerTests`, 8 cases; `RepoBrowsingUITests` against `reagent-systems/mouse`; `docs/screenshots/repo-detail.png` |
| 2026-09-01 | Native iOS shell with GitHub device-flow sign-in | v0.1.0 | `verify/verify.sh` green at `a40efa0`; `docs/screenshots/onboarding.png`, `docs/screenshots/repo-list.png`, and `docs/screenshots/device-flow-signed-in.png` from a real device-flow sign-in on the simulator. |

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
- 2026-09-01 — Closed item 1's evidence gap. A real device-flow sign-in
  ran on the simulator with the owner's OAuth client ID.
- 2026-09-02 — Refilled after the run-inside cycle. Publishing a bundle
  still needs a terminal, so that is now the top item: it is the last
  desktop step between a new repo and playing with it on the phone.
