import Foundation

/// An error that occurs when running a command.
public enum ResourceError: LocalizedError {
    /// Failure due to missing SSH access credentials.
    case failedToResolve(msg: String)
    /// The localized description.
    public var errorDescription: String? {
        switch self {
        case .failedToResolve(let msg):
            "Failed to resolve resource: \(msg)"
        }
    }
}
