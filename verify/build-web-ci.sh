#!/bin/bash
# The bundle build as CI runs it: no simulator, no Xcode, output in web-out.
set -euo pipefail
cd "$(dirname "$0")/.."
STAGE=".web-src"
rm -rf "$STAGE" web-out
mkdir -p "$STAGE"
cp -R src public package.json tsconfig.json postcss.config.mjs "$STAGE/"
# The manifest host is a server route; a static export cannot contain one.
rm -rf "$STAGE/src/app/api"
ln -s "$PWD/node_modules" "$STAGE/node_modules"
cat > "$STAGE/next.config.ts" <<'CONFIG'
import type { NextConfig } from "next";
const nextConfig: NextConfig = { output: "export", images: { unoptimized: true } };
export default nextConfig;
CONFIG
( cd "$STAGE" && npx --no-install next build >/dev/null )
cp -R "$STAGE/out" web-out
rm -rf "$STAGE"
[ -f web-out/index.html ] || { echo "no index.html in web-out" >&2; exit 1; }
echo "web-out ready: $(du -sh web-out | cut -f1)"
