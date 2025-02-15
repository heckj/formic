import Foundation

/// An error that occurs when running a command.
public enum CommandError: LocalizedError {
    /// Failure due to missing SSH access credentials.
    case missingSSHAccessCredentials(msg: String)
    /// Failure due to inability to resolve a host.
    case failedToResolveHost(name: String)
    /// Failure due to no output to parse.
    case noOutputToParse(msg: String)
    /// Failure due to a command failing.
    case commandFailed(rc: Int32, errmsg: String)
    /// Failure due to an invalid command.
    case invalidCommand(msg: String)
    /// Failure due to a command timeout exceeding.
    case timeoutExceeded(cmd: (any Command))
    /// Failure due to no output from a command
    case noOutputFromCommand(cmd: (any Command))

    /// Failure due to using a remote command with a local host.
    case localUnsupported(msg: String)

    /// The localized description.
    public var errorDescription: String? {
        switch self {
        case .missingSSHAccessCredentials(let msg):
            "Missing SSH access credentials: \(msg)"
        case .failedToResolveHost(let name):
            "Failed to resolve \(name) as a valid internet host."
        case .noOutputToParse(let msg):
            "No output to parse: \(msg)"
        case .commandFailed(let rc, let errmsg):
            "Command failed with return code \(rc): \(errmsg)"
        case .invalidCommand(let msg):
            "Invalid command: \(msg)"
        case .timeoutExceeded(let command):
            "Timeout exceeded for command: \(command)"
        case .noOutputFromCommand(let cmd):
            "No output received from command: \(cmd)"
        case .localUnsupported(let msg):
            "Local host does not support remote commands: \(msg)"
        }
    }
}
