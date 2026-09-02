# STATUS.md — where the project actually stands

The single source of truth for project state. Claims require evidence: a
passing gate, a linked run, a tag. Updated in the same commit as the
behavior change. The weekly cycle (WEEKLY.md step 5) refreshes it.

| Area | State | Evidence |
|---|---|---|
| Native iOS shell (`ios/`) | ✅ | `verify/verify.sh` green at `a40efa0` |
| GitHub device-flow sign-in | ✅ | `DeviceFlowAuthTests` 6 cases plus a real end-to-end sign-in: `docs/screenshots/device-flow-signed-in.png` |
| Repo list | ✅ | `docs/screenshots/repo-list.png`, live GitHub |
| Release scanning | ✅ | `ReleaseScannerTests` 8 cases; UI test against `reagent-systems/mouse` v1.4 |
| Run a release inside Apropos | ✅ | `RunInsideUITests`; `docs/screenshots/running-inside.png` |
| Web bundle detection | ✅ | `ReleaseScannerTests`, 13 cases |
| Loopback server for bundles | ✅ | `LocalWebServerTests` serve real HTTP to URLSession |
| Install via `itms-services` | ✅ | 26 install-layer tests; `docs/screenshots/install-sheet.png` reads the live `mouse` .ipa and refuses it by reason |
| Health gate `verify/verify.sh` | ✅ | 16 tests, 0 failures; build with warnings as errors |
| Ship-to-phone docs | ✅ | `docs/DEPLOY-TO-PHONE.md` |
| Token persistence | ✅ | In-memory for the run, Keychain for persistence. `SessionStoreTests` covers the store-fails path; `KeychainTokenStoreTests` skip on an ad-hoc simulator signature and name the OSStatus. |
| Next.js web demo (`src/`) | 🧊 | frozen. 54 lint problems, queued as Feature Queue item 1. `src/app/api` is gated and clean. |

States: ✅ done (gated) · 🚧 in progress · ❌ not started · 🧊 frozen/won't do.

## Current week

- **Shipping:** between cycles. The run-inside cycle shipped all four items.
- **Last release:** v0.2.0 — 2026-09-02.
- **Known red:** none. Two gate steps skip out loud without a GitHub
  token. `verify/lint.sh` covers `src/app/api` and reports, without
  gating on, the frozen demo's 54 lint problems.
