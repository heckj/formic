import Foundation

/// Errors from Integration and Functional Tests in Continuous Integration.
public enum CITestError: LocalizedError {
    /// A general error from a test setup or execution.
    case general(msg: String)

    /// The description of the error.
    public var errorDescription: String? {
        switch self {
        case .general(let msg):
            "general error: \(msg)"
        }
    }
}
