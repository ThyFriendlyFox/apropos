#!/bin/bash
# Gate 1: the project regenerates cleanly and the web surface still lints.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

step "Regenerate the Xcode project from ios/project.yml"
regenerate_project
[ -d "$PROJECT" ] || die "xcodegen produced no $PROJECT"
ok "$(basename "$PROJECT") is current"

step "Lint the Next.js web surface"
if [ -d "$REPO_ROOT/node_modules" ]; then
  ( cd "$REPO_ROOT" && npx --no-install next lint --max-warnings=0 ) \
    || ( cd "$REPO_ROOT" && npm run --silent lint )
  ok "web surface lints"
else
  echo "    skip: node_modules is absent; run npm install to include this gate"
fi
