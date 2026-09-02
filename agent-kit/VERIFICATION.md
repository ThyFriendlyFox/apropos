# VERIFICATION.md — one command answers "is this repo healthy"

`verify/verify.sh` runs, in order:

1. Lint / format check — `verify/lint.sh`
2. Build — `verify/build.sh`
3. Tests — `verify/test.sh`
4. Simulator smoke — `verify/simulator-smoke.sh`
5. UI tests against live GitHub — `verify/ui-test.sh`

## What each gate proves

| Gate | Proves |
|---|---|
| `verify/lint.sh` | `ios/project.yml` regenerates cleanly and the web surface still lints. |
| `verify/build.sh` | The app compiles for the iOS simulator with no warnings-as-errors. |
| `verify/test.sh` | Unit tests pass on a simulator destination. |
| `verify/simulator-smoke.sh` | The app installs on a booted simulator, launches, is still alive 3 seconds later, and renders the repo list with a real token. |
| `verify/ui-test.sh` | The badge and the artifact classification hold against a live repository, and the screenshots in `docs/screenshots/` are regenerated. |

## Rules

- CI runs **the same command** as local. No CI-only logic.
- A gate that can't run in some environment **skips loudly**, never
  passes silently. `verify/simulator-smoke.sh` needs a simulator
  runtime; with none installed it exits non-zero and says so. The
  signed-in half of that gate and all of `verify/ui-test.sh` need a
  GitHub token from `APROPOS_TOKEN` or `gh auth token`; without one
  they print `SKIP` and the reason.
- New behavior lands with its gate in the same PR whenever feasible.
- A feature's completion promise (ROADMAP.md) should be backed by a gate
  here whenever it can be — evidence that keeps proving itself beats
  evidence produced once.
- Fixing a flaky or broken gate is always in scope, for any task.

## Known environment

Verified on Xcode 26.2 (build 17C52) with the iOS 18.6 and iOS 26.x
simulator runtimes installed. `verify/lib.sh` picks the newest available
iPhone simulator; it does not pin a device name.
