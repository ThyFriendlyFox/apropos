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
  ( cd "$IOS_DIR" && xcodegen generate --quiet )
}
