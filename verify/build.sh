#!/bin/bash
# Gate 2: the app compiles for the iOS simulator.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

UDID="${SIM_UDID:-$(pick_simulator)}"
mkdir -p "$DERIVED"
step "Build $SCHEME for simulator $UDID"
xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$UDID" \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO \
  | tee "$DERIVED/build.log" \
  | grep -E '(error:|warning:|BUILD)' || true

grep -q '^\*\* BUILD SUCCEEDED' "$DERIVED/build.log" || die "build failed; see $DERIVED/build.log"
# Only source-located warnings count. Toolchain chatter such as the
# AppIntents metadata note is not a defect in this app.
if grep -qE '^[^ ]+:[0-9]+:[0-9]+: warning:' "$DERIVED/build.log"; then
  grep -E '^[^ ]+:[0-9]+:[0-9]+: warning:' "$DERIVED/build.log" | sort -u
  die "build produced warnings; the gate treats them as errors"
fi
[ -d "$APP_PATH" ] || die "no app bundle at $APP_PATH"
ok "built $APP_PATH with no warnings"
