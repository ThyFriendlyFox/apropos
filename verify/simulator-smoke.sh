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

step "Confirm the app is still alive after launch"
/bin/sleep 3
assert_running "$UDID" "$BUNDLE_ID" || die "$BUNDLE_ID is not running after launch; it crashed on start"
ok "still running"

step "Capture the onboarding screen"
mkdir -p "$REPO_ROOT/docs/screenshots"
xcrun simctl io "$UDID" screenshot --type=png "$REPO_ROOT/docs/screenshots/onboarding.png" >/dev/null 2>&1
ok "docs/screenshots/onboarding.png"

# The signed-in screens need a real token. The gate injects one through the
# launch environment; the app reads it only in a Debug build. With no token
# available this half is skipped out loud, never passed silently.
step "Render the signed-in screens with a real token"
TOKEN="${REPORUNNER_TOKEN:-$(gh auth token 2>/dev/null || true)}"
if [ -z "$TOKEN" ]; then
  echo "    SKIP: no token. Set REPORUNNER_TOKEN or run gh auth login to include this gate."
  exit 0
fi
SIMCTL_CHILD_REPORUNNER_TOKEN="$TOKEN" \
  xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID" >/dev/null
/bin/sleep 6
assert_running "$UDID" "$BUNDLE_ID" || die "$BUNDLE_ID crashed while loading the repo list"
xcrun simctl io "$UDID" screenshot --type=png "$REPO_ROOT/docs/screenshots/repo-list.png" >/dev/null 2>&1
ok "docs/screenshots/repo-list.png"
