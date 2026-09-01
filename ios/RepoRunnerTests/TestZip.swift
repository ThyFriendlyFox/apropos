import Foundation
import Compression
@testable import RepoRunner

/// Builds a ZIP in memory so the inspector can be tested without a network
/// or a checked-in binary fixture.
enum TestZip {
    struct File {
        let name: String
        let contents: Data
        let deflate: Bool
    }

    static func build(_ files: [File]) -> Data {
        var payload = Data()
        var directory = Data()

        for file in files {
            let stored = file.deflate ? deflate(file.contents) : file.contents
            let method: UInt16 = file.deflate ? 8 : 0
            let offset = payload.count
            let name = Data(file.name.utf8)

            payload += u32(0x0403_4b50)
            payload += u16(20) + u16(0) + u16(method) + u16(0) + u16(0)
            payload += u32(0)
            payload += u32(UInt32(stored.count)) + u32(UInt32(file.contents.count))
            payload += u16(UInt16(name.count)) + u16(0)
            payload += name
            payload += stored

            directory += u32(0x0201_4b50)
            directory += u16(20) + u16(20) + u16(0) + u16(method) + u16(0) + u16(0)
            directory += u32(0)
            directory += u32(UInt32(stored.count)) + u32(UInt32(file.contents.count))
            directory += u16(UInt16(name.count)) + u16(0) + u16(0)
            directory += u16(0) + u16(0) + u32(0)
            directory += u32(UInt32(offset))
            directory += name
        }

        let directoryOffset = payload.count
        var end = Data()
        end += u32(0x0605_4b50)
        end += u16(0) + u16(0) + u16(UInt16(files.count)) + u16(UInt16(files.count))
        end += u32(UInt32(directory.count)) + u32(UInt32(directoryOffset))
        end += u16(0)

        return payload + directory + end
    }

    private static func deflate(_ data: Data) -> Data {
        var output = Data(count: max(data.count * 2, 128))
        let written: Int = output.withUnsafeMutableBytes { destination in
            data.withUnsafeBytes { source in
                compression_encode_buffer(
                    destination.baseAddress!.assumingMemoryBound(to: UInt8.self), destination.count,
                    source.baseAddress!.assumingMemoryBound(to: UInt8.self), data.count,
                    nil, COMPRESSION_ZLIB
                )
            }
        }
        return output.prefix(written)
    }

    private static func u16(_ value: UInt16) -> Data {
        Data([UInt8(value & 0xff), UInt8(value >> 8 & 0xff)])
    }

    private static func u32(_ value: UInt32) -> Data {
        Data([
            UInt8(value & 0xff),
            UInt8(value >> 8 & 0xff),
            UInt8(value >> 16 & 0xff),
            UInt8(value >> 24 & 0xff),
        ])
    }
}

/// Serves one blob and honours `Range`, the way a release-asset host does.
final class RangeTransport: Transport, @unchecked Sendable {
    private let blob: Data
    private let supportsRanges: Bool
    private(set) var requestedRanges: [String] = []

    init(_ blob: Data, supportsRanges: Bool = true) {
        self.blob = blob
        self.supportsRanges = supportsRanges
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        guard supportsRanges, let header = request.value(forHTTPHeaderField: "Range") else {
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (blob, response)
        }
        requestedRanges.append(header)
        let numbers = header.replacingOccurrences(of: "bytes=", with: "").split(separator: "-")
        let start = Int(numbers[0])!
        let end = min(Int(numbers[1])!, blob.count - 1)
        let slice = blob.subdata(in: start..<(end + 1))
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 206,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Range": "bytes \(start)-\(end)/\(blob.count)"]
        )!
        return (slice, response)
    }
}
