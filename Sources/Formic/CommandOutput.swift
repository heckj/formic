import Foundation

/// Represents the output of a shell command.
public struct CommandOutput: Sendable {
    public let returnCode: Int32
    public let stdOut: Data?
    public let stdErr: Data?

    public var stdoutString: String? {
        guard let stdOut else {
            return nil
        }
        return String(data: stdOut, encoding: String.Encoding.utf8)
    }

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
extension CommandOutput: Codable {}
