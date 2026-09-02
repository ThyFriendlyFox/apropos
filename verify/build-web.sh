#!/bin/bash
# Builds the web surface as a static bundle for a release asset.
#
# The manifest host at src/app/api is a server route, which a static export
# cannot contain. It is left out of the export tree; the deployed app still
# serves it.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

OUT="${1:-$REPO_ROOT/ios/DerivedData/web}"
STAGE="$REPO_ROOT/ios/DerivedData/web-src"

step "Stage the web surface without its server routes"
rm -rf "$STAGE" "$OUT"
mkdir -p "$STAGE"
cp -R "$REPO_ROOT/src" "$REPO_ROOT/public" "$REPO_ROOT/package.json" \
      "$REPO_ROOT/tsconfig.json" "$REPO_ROOT/postcss.config.mjs" "$STAGE/"
rm -rf "$STAGE/src/app/api"
ln -s "$REPO_ROOT/node_modules" "$STAGE/node_modules"
cat > "$STAGE/next.config.ts" <<'CONFIG'
import type { NextConfig } from "next";
const nextConfig: NextConfig = { output: "export", images: { unoptimized: true } };
export default nextConfig;
CONFIG

step "Build the static export"
( cd "$STAGE" && npx --no-install next build >/dev/null )
[ -d "$STAGE/out" ] || die "next build produced no out/ directory"
mkdir -p "$(dirname "$OUT")"
cp -R "$STAGE/out" "$OUT"
[ -f "$OUT/index.html" ] || die "the export has no index.html"
ok "$(du -sh "$OUT" | cut -f1) in $OUT"
