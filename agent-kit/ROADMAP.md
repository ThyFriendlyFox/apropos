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

### 1. Ship-to-phone polish
- **Promise:** The app has an icon, a launch screen, pull-to-refresh,
  search, empty and error states with retry, and sign-out, and
  `docs/DEPLOY-TO-PHONE.md` names the exact Xcode steps to run it on a
  physical iPhone.
- **Evidence:** Screenshots of every state; the deploy doc.
- **Use case:** UC-6.
- **Scope guard:** No App Store submission work.
- **Status:** ready

## Later — candidates, not yet specced

- Watch a repo and notify on a new release — the natural next step once
  installs work.
- Starred repos of other accounts, not just the owner's.
- Per-repo install history so the phone shows what version is on it.

## Shipped

| Week | Feature | Release | Evidence |
|---|---|---|---|
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
