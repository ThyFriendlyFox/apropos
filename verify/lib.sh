#!/bin/bash
# Shared helpers for the verify gates. Source this; do not run it.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IOS_DIR="$REPO_ROOT/ios"
DERIVED="$IOS_DIR/DerivedData"
PROJECT="$IOS_DIR/RepoRunner.xcodeproj"
SCHEME="RepoRunner"
BUNDLE_ID="com.thyfriendlyfox.reporunner"
APP_PATH="$DERIVED/Build/Products/Debug-iphonesimulator/RepoRunner.app"

step()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()    { printf '\033[1;32m    ok: %s\033[0m\n' "$*"; }
die()   { printf '\033[1;31m    FAIL: %s\033[0m\n' "$*" >&2; exit 1; }

# Newest available iPhone simulator, as a UDID. Fails loudly with none.
pick_simulator() {
  local udid
  udid="$(xcrun simctl list devices available --json \
    | /usr/bin/python3 -c '
import json,sys,re
d=json.load(sys.stdin)["devices"]
best=None
for runtime,devs in d.items():
    m=re.search(r"iOS-(\d+)-(\d+)$",runtime)
    if not m: continue
    ver=(int(m.group(1)),int(m.group(2)))
    for dev in devs:
        if not dev.get("isAvailable"): continue
        if not dev["name"].startswith("iPhone"): continue
        key=(ver,dev["name"])
        if best is None or key>best[0]: best=(key,dev["udid"])
print(best[1] if best else "")')"
  [ -n "$udid" ] || die "no available iPhone simulator runtime; install one in Xcode > Settings > Components"
  echo "$udid"
}

regenerate_project() {
  command -v xcodegen >/dev/null || die "xcodegen is not installed (brew install xcodegen)"
  # Secrets.xcconfig is gitignored, and xcodegen fails on a missing config
  # file. A fresh clone gets the empty template so every gate still runs.
  [ -f "$IOS_DIR/Secrets.xcconfig" ] || cp "$IOS_DIR/Secrets.example.xcconfig" "$IOS_DIR/Secrets.xcconfig"
  ( cd "$IOS_DIR" && xcodegen generate --quiet )
}

# `simctl launch` reports success for a process that dies a moment later, so
# liveness is checked separately. The listing is captured first: piping into
# `grep -q` makes the producer take SIGPIPE, which `pipefail` then reports as
# a failure even on a match.
assert_running() {
  local udid="$1" bundle="$2" tries="${3:-6}"
  local listing
  for _ in $(seq 1 "$tries"); do
    listing="$(xcrun simctl spawn "$udid" launchctl list 2>/dev/null || true)"
    case "$listing" in *"$bundle"*) return 0 ;; esac
    /bin/sleep 1
  done
  return 1
}
