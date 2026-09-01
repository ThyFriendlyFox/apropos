#!/bin/bash
# Gate 1: the project regenerates cleanly and the web surface still lints.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

step "Regenerate the Xcode project from ios/project.yml"
regenerate_project
[ -d "$PROJECT" ] || die "xcodegen produced no $PROJECT"
ok "$(basename "$PROJECT") is current"

step "Lint the manifest host"
# Only src/app/api is load-bearing for the phone. The rest of src/ is the
# frozen browser demo; its lint debt is queued in agent-kit/ROADMAP.md and
# is reported here rather than gating on it.
if [ -d "$REPO_ROOT/node_modules" ]; then
  ( cd "$REPO_ROOT" && npx --no-install eslint src/app/api --max-warnings=0 )
  ok "src/app/api is clean"
  frozen="$( cd "$REPO_ROOT" && npx --no-install eslint src/components src/lib 2>/dev/null | grep -E 'problems? \(' | tail -1 || true )"
  echo "    note: frozen web demo still reports ${frozen:-no problems}"
else
  echo "    SKIP: node_modules is absent; run npm install to include this gate"
fi
