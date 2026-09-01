import Foundation

/// The plist iOS fetches when an app opens an `itms-services://` URL.
/// Apple's schema is fixed; the phone rejects anything else.
enum InstallManifest {
    static func plist(ipaURL: URL, metadata: IPAMetadata, title: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
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
                  <string>\(escape(ipaURL.absoluteString))</string>
                </dict>
              </array>
              <key>metadata</key>
              <dict>
                <key>bundle-identifier</key>
                <string>\(escape(metadata.bundleID))</string>
                <key>bundle-version</key>
                <string>\(escape(metadata.shortVersion.isEmpty ? "1.0" : metadata.shortVersion))</string>
                <key>kind</key>
                <string>software</string>
                <key>title</key>
                <string>\(escape(title))</string>
              </dict>
            </dict>
          </array>
        </dict>
        </plist>
        """
    }

    /// iOS accepts the manifest URL only over https, and only as the query
    /// value of this exact scheme.
    static func installURL(manifestURL: URL) -> URL? {
        guard manifestURL.scheme?.lowercased() == "https" else { return nil }
        var components = URLComponents()
        components.scheme = "itms-services"
        components.host = ""
        components.queryItems = [
            URLQueryItem(name: "action", value: "download-manifest"),
            URLQueryItem(name: "url", value: manifestURL.absoluteString),
        ]
        return components.url
    }

    private static func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
