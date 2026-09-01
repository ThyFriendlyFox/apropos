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

### 1. Native iOS shell that signs in with GitHub and lists repos
- **Promise:** On a booted iPhone simulator, a clean `verify/verify.sh`
  run installs and launches `com.thyfriendlyfox.reporunner`, the first
  screen is the Sign in with GitHub button, and after a device-flow
  sign-in the repo list renders the account's repositories.
- **Evidence:** `verify/verify.sh` green (unit tests + build +
  `verify/simulator-smoke.sh`), plus a simulator screenshot of the
  onboarding screen and of the repo list.
- **Use case:** UC-1, UC-2 in `docs/USE-CASES.md`.
- **Scope guard:** No install action yet. No release scanning yet.
- **Status:** ready

### 2. Release scanning and iOS artifact detection
- **Promise:** A repo row shows an "iOS build" badge when the repo's
  latest release carries an installable iOS artifact, and the repo
  detail screen lists every release with its artifacts classified as
  device (`.ipa`), simulator (`.app.zip`/`.app.tar.gz`), or manifest
  (`.plist`).
- **Evidence:** `ReleaseScannerTests` covers every classification case;
  detail screen screenshot against a real public repo.
- **Use case:** UC-3.
- **Scope guard:** No downloading. Classification and display only.
- **Status:** ready

### 3. One-tap install of a release build
- **Promise:** Tapping Install on a release with a public `.ipa` opens
  an `itms-services://` install for a manifest whose URL is https, and
  the app reports a specific reason instead of installing when the
  release is private, unsigned-for-this-device, or simulator-only.
- **Evidence:** `InstallServiceTests` proves manifest generation and
  every refusal branch; the simulator run shows the refusal copy.
- **Use case:** UC-4, UC-5.
- **Scope guard:** No re-signing. No MDM. No private-repo proxying.
- **Status:** ready

### 4. Ship-to-phone polish
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
