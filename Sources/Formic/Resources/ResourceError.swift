import Foundation

/// An error that occurs when running a command.
public enum ResourceError: LocalizedError {
    //    /// Failure due to state mismatch after a resolve operation.
    //    case failedToResolve(msg: String)
    /// Failure due to the output from inquiry not being decodable as a UTF-8 string.
    case notAString

    /// The localized description.
    public var errorDescription: String? {
        switch self {
        case .notAString:
            "Inquiry output is not a UTF-8 string."
        //        case .failedToResolve(let msg):
        //            "Failed to resolve resource: \(msg)"
        }
    }
}