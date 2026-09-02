import Foundation

enum GitHubError: LocalizedError, Equatable {
    case unauthorized
    case rateLimited(resetsAt: Date?)
    case http(status: Int, message: String)
    case decoding(String)
    case transport(URLError)
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "GitHub rejected the saved token. Sign in again."
        case .rateLimited(let resetsAt):
            guard let resetsAt else { return "GitHub rate limit reached." }
            let formatter = RelativeDateTimeFormatter()
            return "GitHub rate limit reached. It resets \(formatter.localizedString(for: resetsAt, relativeTo: Date()))."
        case .http(let status, let message):
            return message.isEmpty ? "GitHub returned HTTP \(status)." : message
        case .decoding(let detail):
            return "GitHub sent a response this app could not read: \(detail)"
        case .transport(let error):
            return error.localizedDescription
        case .notConfigured:
            return "No GitHub client ID is set. Add one in Settings to sign in."
        }
    }

    static func == (lhs: GitHubError, rhs: GitHubError) -> Bool {
        lhs.localizedDescription == rhs.localizedDescription
    }
}
