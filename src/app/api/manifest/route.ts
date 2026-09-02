import { NextRequest, NextResponse } from "next/server";

/**
 * Serves the install manifest iOS fetches for an `itms-services://` install.
 *
 * Apropos attaches a manifest.plist to the release itself when the signed-in
 * account can write to the repository. This endpoint covers the case where it
 * cannot: deploy this app, then paste the endpoint URL into Apropos's
 * Settings under "Manifest host".
 *
 * Only GitHub release assets are served, so the endpoint cannot be pointed at an
 * arbitrary host and used as an open redirect for an install.
 */

const ALLOWED_IPA_HOSTS = ["github.com", "objects.githubusercontent.com"];

function escapeXml(value: string): string {
  return value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const ipa = searchParams.get("ipa");
  const bundleId = searchParams.get("id");
  const version = searchParams.get("version") || "1.0";
  const title = searchParams.get("title") || bundleId || "App";

  if (!ipa || !bundleId) {
    return NextResponse.json({ error: "ipa and id are both required" }, { status: 400 });
  }

  let assetUrl: URL;
  try {
    assetUrl = new URL(ipa);
  } catch {
    return NextResponse.json({ error: "ipa is not a URL" }, { status: 400 });
  }
  if (assetUrl.protocol !== "https:" || !ALLOWED_IPA_HOSTS.includes(assetUrl.hostname)) {
    return NextResponse.json(
      { error: "ipa must be an https GitHub release asset" },
      { status: 400 }
    );
  }

  const plist = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>items</key>
  <array>
    <dict>
      <key>assets</key>
      <array>
        <dict>
          <key>kind</key>
          <string>software-package</string>
          <key>url</key>
          <string>${escapeXml(assetUrl.toString())}</string>
        </dict>
      </array>
      <key>metadata</key>
      <dict>
        <key>bundle-identifier</key>
        <string>${escapeXml(bundleId)}</string>
        <key>bundle-version</key>
        <string>${escapeXml(version)}</string>
        <key>kind</key>
        <string>software</string>
        <key>title</key>
        <string>${escapeXml(title)}</string>
      </dict>
    </dict>
  </array>
</dict>
</plist>
`;

  return new NextResponse(plist, {
    headers: {
      "Content-Type": "application/xml",
      "Cache-Control": "no-store",
    },
  });
}
