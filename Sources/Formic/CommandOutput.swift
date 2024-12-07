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

    init(returnCode: Int32, stdOut: Data?, stdErr: Data?) {
        self.returnCode = returnCode
        self.stdOut = stdOut
        self.stdErr = stdErr
    }
}

extension CommandOutput: Hashable {}

// IMPL NOTES: I'm not sure I require the Codable representation, but it doesn't hurt to have it.
extension CommandOutput: Codable {}
