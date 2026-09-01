# STATUS.md — where the project actually stands

The single source of truth for project state. Claims require evidence: a
passing gate, a linked run, a tag. Updated in the same commit as the
behavior change. The weekly cycle (WEEKLY.md step 5) refreshes it.

| Area | State | Evidence |
|---|---|---|
| Native iOS shell (`ios/`) | ❌ | not started |
| GitHub device-flow sign-in | ❌ | not started |
| Repo list | ❌ | not started |
| Release scanning | ❌ | not started |
| Install via `itms-services` | ❌ | not started |
| Health gate `verify/verify.sh` | ❌ | not started |
| Next.js web demo (`src/`) | 🧊 | kept as-is; not the product |

States: ✅ done (gated) · 🚧 in progress · ❌ not started · 🧊 frozen/won't do.

## Current week

- **Shipping:** Feature Queue item 1 — native iOS shell with GitHub sign-in.
- **Last release:** none.
- **Known red:** `verify/verify.sh` does not exist yet.
