/// The level and contents of output exposed for a command execution result.
public enum CommandOutputDetail: Sendable, Hashable {
    /// Reports only failures
    case silent(emoji: Bool = false)
    /// Reports host and command with an indication of command success or failure.
    case normal(emoji: Bool = true)
    /// Reports host, command, duration, the result code, and stdout on success, or stderr on failure.
    case verbose(emoji: Bool = true)
    /// Reports host, command, duration, the result code, stdout, and stderr returned from the command.
    case debug(emoji: Bool = true)
}
