import Foundation

/// An error that occurs when running a command.
public enum CommandError: LocalizedError {
    case missingSSHAccessCredentials(msg: String)
    case failedToResolveHost(name: String)
    case noOutputToParse(msg: String)
    case commandFailed(rc: Int32, errmsg: String)

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
        }
    }
}
