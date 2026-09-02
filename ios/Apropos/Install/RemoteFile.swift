import Foundation

/// Reads byte ranges out of a remote file. An `.ipa` is a ZIP, and its
/// directory sits at the end, so a few kilobytes of range reads answer what
/// the whole multi-megabyte download would.
struct RemoteFile: Sendable {
    let url: URL
    let transport: Transport

    enum ReadError: LocalizedError, Equatable {
        case rangeNotSupported
        case http(Int)
        case malformedContentRange

        var errorDescription: String? {
            switch self {
            case .rangeNotSupported: return "The server will not serve part of this file."
            case .http(let status): return "The download server answered HTTP \(status)."
            case .malformedContentRange: return "The download server sent a range this app could not read."
            }
        }
    }

    /// Total size in bytes, taken from the `Content-Range` of a one-byte read.
    /// A `HEAD` is avoided: GitHub redirects asset URLs and not every host on
    /// the far side answers `HEAD`.
    func length() async throws -> Int {
        var request = URLRequest(url: url)
        request.setValue("bytes=0-0", forHTTPHeaderField: "Range")
        let (_, response) = try await transport.send(request)
        guard response.statusCode == 206 else {
            throw response.statusCode == 200 ? ReadError.rangeNotSupported : ReadError.http(response.statusCode)
        }
        guard let header = response.value(forHTTPHeaderField: "Content-Range"),
              let total = header.split(separator: "/").last.flatMap({ Int($0) }) else {
            throw ReadError.malformedContentRange
        }
        return total
    }

    /// Bytes `offset..<offset+count`. Suffix ranges are never used: some
    /// hosts drop them across a redirect and answer with a short body.
    func read(offset: Int, count: Int) async throws -> Data {
        precondition(count > 0)
        var request = URLRequest(url: url)
        request.setValue("bytes=\(offset)-\(offset + count - 1)", forHTTPHeaderField: "Range")
        let (data, response) = try await transport.send(request)
        guard response.statusCode == 206 else {
            throw response.statusCode == 200 ? ReadError.rangeNotSupported : ReadError.http(response.statusCode)
        }
        return data
    }
}
