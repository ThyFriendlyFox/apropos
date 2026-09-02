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

### 1. Run a release's web app inside Apropos
- **Promise:** Tapping Run on a release that carries a web bundle opens
  that app full screen inside Apropos on a phone or simulator, playable,
  with no desktop step and nothing installed.
- **Evidence:** A UI test drives Run on a real GitHub release and asserts
  the app's own content is on screen inside Apropos; a screenshot shows it.
- **Use case:** UC-7.
- **Scope guard:** No native `.ipa` execution — iOS cannot run one inside
  another app. No code execution outside the web view.
- **Status:** ready

### 2. Detect what a release can run
- **Promise:** A repo row says how its latest release can be run — inside
  Apropos, installed to the Home Screen, or not at all — and the detail
  screen names the asset behind that answer.
- **Evidence:** `ReleaseScannerTests` covers every payload shape; a
  screenshot of the list with mixed verdicts.
- **Use case:** UC-3, UC-7.
- **Scope guard:** Classification only.
- **Status:** ready

### 3. Apropos ships its own web build
- **Promise:** The `apropos` repo's latest release carries a web bundle,
  and Apropos runs itself from its own repo list.
- **Evidence:** A screenshot of Apropos running Apropos.
- **Use case:** UC-7.
- **Scope guard:** The web build is the existing `src/` surface. No second
  implementation of the phone app.
- **Status:** ready

### 4. Keep a run where you left it
- **Promise:** Reopening a repo that was run before resumes it without
  downloading the bundle again, and a pull to refresh replaces it when the
  release changed.
- **Evidence:** A unit test over the cache keyed by release id; a UI test
  that a second run makes no network call for the bundle.
- **Use case:** UC-7.
- **Scope guard:** No offline mode for apps that need the network.
- **Status:** ready

## Later — candidates, not yet specced

- Watch a repo and notify on a new release — the natural next step once
  installs work.
- Starred repos of other accounts, not just the owner's.
- Per-repo install history so the phone shows what version is on it.

## Shipped

| Week | Feature | Release | Evidence |
|---|---|---|---|
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
