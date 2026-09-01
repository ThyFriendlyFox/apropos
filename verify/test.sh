#!/bin/bash
# Gate 3: unit tests pass on a simulator destination.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

UDID="${SIM_UDID:-$(pick_simulator)}"
step "Run RepoRunnerTests on simulator $UDID"
set +e
xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$UDID" \
  -derivedDataPath "$DERIVED" \
  -only-testing:RepoRunnerTests \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | tee "$DERIVED/test.log" | grep -E "(Test Case '.*(passed|failed)|Executed .* tests|error:|TEST)" 
rc=${PIPESTATUS[0]}
set -e
[ "$rc" -eq 0 ] || die "tests failed; see $DERIVED/test.log"
ok "$(grep -oE 'Executed [0-9]+ tests?' "$DERIVED/test.log" | tail -1) passed"
