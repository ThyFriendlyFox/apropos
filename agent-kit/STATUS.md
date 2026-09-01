# STATUS.md — where the project actually stands

The single source of truth for project state. Claims require evidence: a
passing gate, a linked run, a tag. Updated in the same commit as the
behavior change. The weekly cycle (WEEKLY.md step 5) refreshes it.

| Area | State | Evidence |
|---|---|---|
| Native iOS shell (`ios/`) | ✅ | `verify/verify.sh` green at `a40efa0` |
| GitHub device-flow sign-in | 🚧 | `DeviceFlowAuthTests`, 6 cases; end-to-end run needs an OAuth client ID |
| Repo list | ✅ | `docs/screenshots/repo-list.png`, live GitHub |
| Release scanning | ✅ | `ReleaseScannerTests` 8 cases; UI test against `reagent-systems/mouse` v1.4 |
| Install via `itms-services` | ✅ | 26 install-layer tests; `docs/screenshots/install-sheet.png` reads the live `mouse` .ipa and refuses it by reason |
| Health gate `verify/verify.sh` | ✅ | 16 tests, 0 failures; build with warnings as errors |
| Next.js web demo (`src/`) | 🧊 | kept as-is; not the product |

States: ✅ done (gated) · 🚧 in progress · ❌ not started · 🧊 frozen/won't do.

## Current week

- **Shipping:** Feature Queue item 1 — ship-to-phone polish.
- **Last release:** none.
- **Known red:** none. The signed-in half of the smoke gate skips out loud when no GitHub token is present.
