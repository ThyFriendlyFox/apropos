#!/bin/bash
# The health gate. Green here is the precondition for any push.
set -euo pipefail
cd "$(dirname "$0")/.."
export SIM_UDID="${SIM_UDID:-$(source verify/lib.sh; pick_simulator)}"
verify/lint.sh
verify/build.sh
verify/test.sh
verify/simulator-smoke.sh
verify/ui-test.sh
printf '\n\033[1;32m==> verify: all gates green (simulator %s)\033[0m\n' "$SIM_UDID"
