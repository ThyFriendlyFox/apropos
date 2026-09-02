import Foundation
import Compression

struct ZipEntry: Equatable, Sendable {
    let name: String
    let method: UInt16
    let compressedSize: Int
    let uncompressedSize: Int
    let localHeaderOffset: Int
}

enum ZipError: LocalizedError, Equatable {
    case noEndOfCentralDirectory
    case unsupportedZip64
    case entryNotFound(String)
    case corruptEntry(String)
    case unsupportedCompression(UInt16)
    case unsafeEntry(String)

    var errorDescription: String? {
        switch self {
        case .noEndOfCentralDirectory: return "The file does not look like an .ipa."
        case .unsupportedZip64: return "The .ipa uses a ZIP64 layout this app cannot read."
        case .entryNotFound(let name): return "The .ipa has no \(name)."
        case .corruptEntry(let name): return "The entry \(name) in the .ipa is malformed."
        case .unsupportedCompression(let method): return "The archive uses compression method \(method)."
        case .unsafeEntry(let name): return "The archive contains an entry that writes outside its folder: \(name)."
        }
    }
}

/// Just enough ZIP to find one file and pull it out. Written against the
/// central directory rather than a streaming read so an `.ipa` can be
/// inspected with a few range requests.
enum ZipDirectory {
    /// The largest end-of-central-directory record, including a maximal comment.
    static let maxEndRecordSize = 65_557

    struct End: Equatable {
        let centralDirectoryOffset: Int
        let centralDirectorySize: Int
        let entryCount: Int
    }

    static func findEnd(inTail tail: Data, tailStartsAt tailOffset: Int) throws -> End {
        let signature: [UInt8] = [0x50, 0x4b, 0x05, 0x06]
        let bytes = [UInt8](tail)
        guard bytes.count >= 22 else { throw ZipError.noEndOfCentralDirectory }
        var index = bytes.count - 22
        while index >= 0 {
            if Array(bytes[index..<index + 4]) == signature {
                let count = Int(u16(bytes, index + 10))
                let size = Int(u32(bytes, index + 12))
                let offset = Int(u32(bytes, index + 16))
                if offset == 0xFFFF_FFFF || size == 0xFFFF_FFFF { throw ZipError.unsupportedZip64 }
                _ = tailOffset
                return End(centralDirectoryOffset: offset, centralDirectorySize: size, entryCount: count)
            }
            index -= 1
        }
        throw ZipError.noEndOfCentralDirectory
    }

    static func parseCentralDirectory(_ data: Data) throws -> [ZipEntry] {
        let bytes = [UInt8](data)
        var entries: [ZipEntry] = []
        var index = 0
        while index + 46 <= bytes.count {
            guard Array(bytes[index..<index + 4]) == [0x50, 0x4b, 0x01, 0x02] else { break }
            let method = u16(bytes, index + 10)
            let compressed = Int(u32(bytes, index + 20))
            let uncompressed = Int(u32(bytes, index + 24))
            let nameLength = Int(u16(bytes, index + 28))
            let extraLength = Int(u16(bytes, index + 30))
            let commentLength = Int(u16(bytes, index + 32))
            let localOffset = Int(u32(bytes, index + 42))
            let nameStart = index + 46
            guard nameStart + nameLength <= bytes.count else { break }
            let name = String(decoding: bytes[nameStart..<nameStart + nameLength], as: UTF8.self)
            entries.append(ZipEntry(
                name: name,
                method: method,
                compressedSize: compressed,
                uncompressedSize: uncompressed,
                localHeaderOffset: localOffset
            ))
            index = nameStart + nameLength + extraLength + commentLength
        }
        return entries
    }

    /// The local header repeats the name and extra-field lengths, and its
    /// extra field routinely differs from the central directory's. The data
    /// offset can only be computed from the local header itself.
    static func dataOffset(localHeader: Data, entry: ZipEntry) throws -> Int {
        let bytes = [UInt8](localHeader)
        guard bytes.count >= 30, Array(bytes[0..<4]) == [0x50, 0x4b, 0x03, 0x04] else {
            throw ZipError.corruptEntry(entry.name)
        }
        let nameLength = Int(u16(bytes, 26))
        let extraLength = Int(u16(bytes, 28))
        return entry.localHeaderOffset + 30 + nameLength + extraLength
    }

    static func decompress(_ data: Data, entry: ZipEntry) throws -> Data {
        switch entry.method {
        case 0:
            return data
        case 8:
            return try inflate(data, expectedSize: entry.uncompressedSize, name: entry.name)
        default:
            throw ZipError.unsupportedCompression(entry.method)
        }
    }

    /// ZIP stores raw DEFLATE. `COMPRESSION_ZLIB` is Apple's name for exactly
    /// that: no zlib header, no trailer.
    private static func inflate(_ data: Data, expectedSize: Int, name: String) throws -> Data {
        guard expectedSize > 0 else { return Data() }
        var output = Data(count: expectedSize)
        let written: Int = output.withUnsafeMutableBytes { destination in
            data.withUnsafeBytes { source in
                guard let destinationBase = destination.baseAddress?.assumingMemoryBound(to: UInt8.self),
                      let sourceBase = source.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return 0 }
                return compression_decode_buffer(
                    destinationBase, expectedSize,
                    sourceBase, data.count,
                    nil, COMPRESSION_ZLIB
                )
            }
        }
        guard written == expectedSize else { throw ZipError.corruptEntry(name) }
        return output
    }

    private static func u16(_ bytes: [UInt8], _ index: Int) -> UInt16 {
        UInt16(bytes[index]) | UInt16(bytes[index + 1]) << 8
    }

    private static func u32(_ bytes: [UInt8], _ index: Int) -> UInt32 {
        UInt32(bytes[index]) | UInt32(bytes[index + 1]) << 8
            | UInt32(bytes[index + 2]) << 16 | UInt32(bytes[index + 3]) << 24
    }
}

extension ZipDirectory {
    /// Unpacks every file entry into `directory`. Used for web bundles,
    /// which are small enough to hold in memory; the `.ipa` path reads
    /// ranges instead.
    ///
    /// Entry names come from the archive, so they are untrusted. Any name
    /// that escapes `directory` is refused rather than written.
    @discardableResult
    static func extractAll(_ data: Data, to directory: URL) throws -> [URL] {
        let end = try findEnd(inTail: data.suffix(min(maxEndRecordSize, data.count)),
                              tailStartsAt: max(0, data.count - maxEndRecordSize))
        let start = end.centralDirectoryOffset
        let directoryData = data.subdata(in: start..<(start + end.centralDirectorySize))
        let entries = try parseCentralDirectory(directoryData)

        let root = directory.standardizedFileURL
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        var written: [URL] = []
        for entry in entries {
            guard !entry.name.hasSuffix("/") else { continue }
            guard let destination = safeDestination(for: entry.name, under: root) else {
                throw ZipError.unsafeEntry(entry.name)
            }
            let headerEnd = min(entry.localHeaderOffset + 30, data.count)
            guard entry.localHeaderOffset >= 0, headerEnd > entry.localHeaderOffset else {
                throw ZipError.corruptEntry(entry.name)
            }
            let header = data.subdata(in: entry.localHeaderOffset..<headerEnd)
            let dataStart = try dataOffset(localHeader: header, entry: entry)
            let dataEnd = dataStart + entry.compressedSize
            guard dataEnd <= data.count else { throw ZipError.corruptEntry(entry.name) }
            let payload = try decompress(data.subdata(in: dataStart..<dataEnd), entry: entry)

            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try payload.write(to: destination)
            written.append(destination)
        }
        return written
    }

    /// Refuses absolute paths and any `..` that would climb out of `root`.
    static func safeDestination(for name: String, under root: URL) -> URL? {
        guard !name.hasPrefix("/"), !name.contains("\0") else { return nil }
        var components: [String] = []
        for part in name.split(separator: "/") {
            switch part {
            case ".": continue
            case "..":
                if components.isEmpty { return nil }
                components.removeLast()
            default: components.append(String(part))
            }
        }
        guard !components.isEmpty else { return nil }
        return components.reduce(root) { $0.appendingPathComponent($1) }
    }

    /// The single entry a web bundle is served from. Prefers the shallowest
    /// `index.html`, because build tools often nest the whole site one
    /// folder deep inside the archive.
    static func findIndex(under root: URL) -> URL? {
        let manager = FileManager.default
        guard let walker = manager.enumerator(at: root, includingPropertiesForKeys: nil) else { return nil }
        var best: (depth: Int, url: URL)?
        for case let url as URL in walker where url.lastPathComponent.lowercased() == "index.html" {
            let depth = url.pathComponents.count
            if best == nil || depth < best!.depth { best = (depth, url) }
        }
        return best?.url
    }
}
