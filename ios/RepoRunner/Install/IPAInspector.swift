import Foundation

enum SigningKind: Equatable, Sendable {
    case development
    case adHoc(deviceCount: Int)
    case enterprise
    case appStore
    case unknown

    /// Whether an over-the-air install can ever place this build on a phone.
    /// An App Store signature cannot: only the App Store and TestFlight can
    /// install one.
    var canInstallOverTheAir: Bool {
        switch self {
        case .development, .adHoc, .enterprise: return true
        case .appStore: return false
        case .unknown: return true
        }
    }

    var summary: String {
        switch self {
        case .development: return "Development signature"
        case .adHoc(let count): return "Ad-hoc signature, \(count) registered device\(count == 1 ? "" : "s")"
        case .enterprise: return "Enterprise signature"
        case .appStore: return "App Store signature"
        case .unknown: return "Unrecognised signature"
        }
    }
}

struct IPAMetadata: Equatable, Sendable {
    let bundleID: String
    let displayName: String
    let shortVersion: String
    let buildVersion: String
    let signing: SigningKind
}

/// Reads an `.ipa` well enough to build an install manifest, using range
/// requests instead of a full download. A manifest needs the exact bundle
/// identifier; a wrong one turns into "Unable to Install" on the phone.
struct IPAInspector: Sendable {
    let transport: Transport

    init(transport: Transport = URLSession.shared) {
        self.transport = transport
    }

    func inspect(_ url: URL) async throws -> IPAMetadata {
        let file = RemoteFile(url: url, transport: transport)
        let total = try await file.length()

        let tailSize = min(ZipDirectory.maxEndRecordSize, total)
        let tail = try await file.read(offset: total - tailSize, count: tailSize)
        let end = try ZipDirectory.findEnd(inTail: tail, tailStartsAt: total - tailSize)

        let directory = try await file.read(
            offset: end.centralDirectoryOffset,
            count: end.centralDirectorySize
        )
        let entries = try ZipDirectory.parseCentralDirectory(directory)

        guard let infoEntry = entries.first(where: { Self.isAppRootFile($0.name, named: "Info.plist") }) else {
            throw ZipError.entryNotFound("Payload/*.app/Info.plist")
        }
        let info = try await plist(entry: infoEntry, in: file)

        var signing = SigningKind.unknown
        if let profileEntry = entries.first(where: { Self.isAppRootFile($0.name, named: "embedded.mobileprovision") }),
           let profile = try? await raw(entry: profileEntry, in: file) {
            signing = Self.signingKind(fromProfile: profile)
        }

        guard let bundleID = info["CFBundleIdentifier"] as? String else {
            throw ZipError.corruptEntry(infoEntry.name)
        }
        let name = (info["CFBundleDisplayName"] as? String)
            ?? (info["CFBundleName"] as? String)
            ?? bundleID
        return IPAMetadata(
            bundleID: bundleID,
            displayName: name,
            shortVersion: info["CFBundleShortVersionString"] as? String ?? "",
            buildVersion: info["CFBundleVersion"] as? String ?? "",
            signing: signing
        )
    }

    /// Matches `Payload/Something.app/<file>` and nothing deeper, so a
    /// framework's or an extension's Info.plist is never mistaken for the
    /// app's own.
    static func isAppRootFile(_ path: String, named file: String) -> Bool {
        let parts = path.split(separator: "/", omittingEmptySubsequences: false)
        return parts.count == 3
            && parts[0] == "Payload"
            && parts[1].hasSuffix(".app")
            && parts[2] == file
    }

    /// A `.mobileprovision` is a CMS envelope wrapping an XML plist. The
    /// plist is extracted by its own delimiters rather than by decoding the
    /// signature, which the app has no reason to verify.
    static func signingKind(fromProfile data: Data) -> SigningKind {
        guard let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8), options: .backwards) else {
            return .unknown
        }
        let xml = data[start.lowerBound..<end.upperBound]
        guard let profile = try? PropertyListSerialization.propertyList(
            from: xml, options: [], format: nil
        ) as? [String: Any] else {
            return .unknown
        }
        if profile["ProvisionsAllDevices"] as? Bool == true { return .enterprise }
        if let devices = profile["ProvisionedDevices"] as? [String], !devices.isEmpty {
            let entitlements = profile["Entitlements"] as? [String: Any]
            let debuggable = entitlements?["get-task-allow"] as? Bool == true
            return debuggable ? .development : .adHoc(deviceCount: devices.count)
        }
        return .appStore
    }

    private func raw(entry: ZipEntry, in file: RemoteFile) async throws -> Data {
        // The local header's extra field is its own; read it before the data.
        let header = try await file.read(offset: entry.localHeaderOffset, count: 30)
        let start = try ZipDirectory.dataOffset(localHeader: header, entry: entry)
        let payload = try await file.read(offset: start, count: max(entry.compressedSize, 1))
        return try ZipDirectory.decompress(payload, entry: entry)
    }

    private func plist(entry: ZipEntry, in file: RemoteFile) async throws -> [String: Any] {
        let data = try await raw(entry: entry, in: file)
        guard let dictionary = try PropertyListSerialization.propertyList(
            from: data, options: [], format: nil
        ) as? [String: Any] else {
            throw ZipError.corruptEntry(entry.name)
        }
        return dictionary
    }
}
