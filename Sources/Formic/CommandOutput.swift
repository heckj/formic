import Foundation

/// The raw output of a shell command.
public struct CommandOutput: Sendable {
    /// The return code.
    public let returnCode: Int32
    /// The raw data from STDOUT, if any.
    public let stdOut: Data?
    /// The raw data from STDERR, if any.
    public let stdErr: Data?

    /// The data from STDOUT reported as a UTF-8 string.
    public var stdoutString: String? {
        guard let stdOut else {
            return nil
        }
        return String(data: stdOut, encoding: String.Encoding.utf8)
    }

    /// The data from STDERR reported as a UTF-8 string.
    public var stderrString: String? {
        guard let stdErr else {
            return nil
        }
        return String(data: stdErr, encoding: String.Encoding.utf8)
    }

    /// Create a new command output.
    /// - Parameters:
    ///   - returnCode: The return code
    ///   - stdOut: The raw data for STDOUT, if any.
    ///   - stdErr: The raw data for STDERR, if any.
    init(returnCode: Int32, stdOut: Data?, stdErr: Data?) {
        self.returnCode = returnCode
        self.stdOut = stdOut
        self.stdErr = stdErr
    }

    /// A null output with no useful information.
    public static var empty: CommandOutput {
        CommandOutput(returnCode: 0, stdOut: nil, stdErr: nil)
    }

    /// Creates a command out that represents a success.
    /// - Parameter msg: A message to include as the standard output.
    public static func generalSuccess(msg: String) -> CommandOutput {
        CommandOutput(returnCode: 0, stdOut: msg.data(using: .utf8), stdErr: nil)
    }

    /// Creates a command out that represents a failure.
    /// - Parameter msg: A message to include as the standard error.
    public static func generalFailure(msg: String) -> CommandOutput {
        CommandOutput(returnCode: -1, stdOut: nil, stdErr: msg.data(using: .utf8))
    }

    /// Creates a command out that represents an exception thrown failure, and has no output.
    public static func exceptionFailure() -> CommandOutput {
        CommandOutput(returnCode: -1, stdOut: nil, stdErr: nil)
    }

}

extension CommandOutput: Hashable {}

// IMPL NOTES: I'm not sure I require the Codable representation, but it doesn't hurt to have it.
extension CommandOutput: Codable {}
