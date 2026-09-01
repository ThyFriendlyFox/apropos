#!/bin/bash
# Gate 4: the app installs, launches, and survives on a booted simulator.
# simctl reports success for a launch that crashes immediately, so this
# re-checks the process after a delay.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

UDID="${SIM_UDID:-$(pick_simulator)}"
[ -d "$APP_PATH" ] || die "no app bundle; run verify/build.sh first"

step "Boot simulator $UDID"
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
ok "booted"

step "Install and launch $BUNDLE_ID"
xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$UDID" "$APP_PATH"
PID="$(xcrun simctl launch "$UDID" "$BUNDLE_ID" | awk -F': ' '{print $2}')"
[ -n "$PID" ] || die "launch returned no pid"
ok "launched as pid $PID"

step "Confirm the app is still alive after 3 seconds"
/bin/sleep 3
xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -q "$BUNDLE_ID" \
  || die "$BUNDLE_ID is not running 3 seconds after launch; it crashed on start"
ok "still running"

step "Capture a screenshot"
mkdir -p "$REPO_ROOT/docs/screenshots"
xcrun simctl io "$UDID" screenshot --type=png "$REPO_ROOT/docs/screenshots/smoke.png" >/dev/null 2>&1
ok "docs/screenshots/smoke.png"
