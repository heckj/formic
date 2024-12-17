import Foundation

/// An error that occurs when querying a resource.
public enum QueryError: LocalizedError {
    /// Failure due to the output from inquiry not being decodable as a UTF-8 string.
    case notAString

    /// The localized description.
    public var errorDescription: String? {
        switch self {
        case .notAString:
            "Inquiry ouput not a UTF-8 string."
        }
    }
}
