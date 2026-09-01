#!/bin/bash
# Gate 5: drive the real app against live GitHub and keep the screenshots.
# The token reaches the test runner through xcodebuild's TEST_RUNNER_ prefix.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

UDID="${SIM_UDID:-$(pick_simulator)}"
TOKEN="${REPORUNNER_TOKEN:-$(gh auth token 2>/dev/null || true)}"
if [ -z "$TOKEN" ]; then
  echo "    SKIP: no token. Set REPORUNNER_TOKEN or run gh auth login to include this gate."
  exit 0
fi

RESULTS="$DERIVED/ui-tests.xcresult"
rm -rf "$RESULTS"

step "Run RepoRunnerUITests on simulator $UDID"
set +e
TEST_RUNNER_REPORUNNER_TOKEN="$TOKEN" xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$UDID" \
  -derivedDataPath "$DERIVED" \
  -resultBundlePath "$RESULTS" \
  -only-testing:RepoRunnerUITests \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | tee "$DERIVED/ui-test.log" | grep -E "(Test Case '.*(passed|failed|skipped)|Executed .* tests|error:|TEST)"
rc=${PIPESTATUS[0]}
set -e
[ "$rc" -eq 0 ] || die "UI tests failed; see $DERIVED/ui-test.log"

step "Export the screenshots the UI tests captured"
OUT="$REPO_ROOT/docs/screenshots"
mkdir -p "$OUT"
TMP="$DERIVED/ui-attachments"
rm -rf "$TMP" && mkdir -p "$TMP"
xcrun xcresulttool export attachments --path "$RESULTS" --output-path "$TMP" >/dev/null
# Exported files are named by UUID; the manifest carries the name the test
# asked for, with an index and a UUID appended.
found=0
while IFS=$'\t' read -r exported suggested; do
  name="${suggested%%_*}"
  case "$name" in
    repo-list-badge|repo-detail)
      cp "$TMP/$exported" "$OUT/$name.png"
      found=$((found+1))
      ;;
  esac
done < <(jq -r '.[].attachments[] | [.exportedFileName, .suggestedHumanReadableName] | @tsv' "$TMP/manifest.json")
[ "$found" -eq 2 ] || die "expected 2 exported screenshots, got $found"
ok "exported $found screenshots to docs/screenshots"
