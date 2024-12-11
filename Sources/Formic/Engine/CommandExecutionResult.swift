/// The result of executing a command.
public struct CommandExecutionResult: Sendable, Hashable, Codable {
    /// The command.
    public let command: Command
    /// The host for the command.
    public let host: Host
    /// The ID of the playbook that the command is part of, if any.
    public let playbookId: Playbook.ID?
    /// The output from the command.
    public let output: CommandOutput
    /// The duration of the command.
    public let duration: Duration
    /// The number of retries needed for this command.
    public let retries: Int
}

extension CommandExecutionResult {
    /// Returns a possibly multi-line string representation of the command execution result.
    /// - Parameter verbosity: The verbosity level of the output.
    public func consoleOutput(verbosity: Verbosity) -> String {
        let style = Duration.TimeFormatStyle(pattern: .hourMinuteSecond(padHourToLength: 2))
        let formattedDuration = duration.formatted(style)  // "00:00:02".

        var stringOutput = ""
        switch verbosity {
        case .silent(emoji: let includeEmoji):
            // Reports only failure.
            if output.returnCode != 0 {
                if includeEmoji {
                    stringOutput.append("❌ ")
                }
                stringOutput.append("return code: \(output.returnCode)")
                if let errorOutput = output.stderrString {
                    stringOutput.append("\nSTDERR: \(errorOutput)")
                } else {
                    stringOutput.append(" No STDERR output.")
                }
            } else {
                if includeEmoji {
                    stringOutput.append("✅")
                }
            }
        case .normal(emoji: let includeEmoji):
            // Reports host and command with an indication of command success or failure.
            if output.returnCode != 0 {
                if includeEmoji {
                    stringOutput.append("❌ ")
                }
                stringOutput.append("command: \(command), rc=\(output.returnCode)")
                if let errorOutput = output.stderrString {
                    stringOutput.append("\nSTDERR: \(errorOutput)")
                } else {
                    stringOutput.append(" No STDERR output.")
                }
            } else {
                if includeEmoji {
                    stringOutput.append("✅ ")
                }
                stringOutput.append("command: \(output.returnCode), rc=\(output.returnCode)")
            }
        case .verbose(emoji: let includeEmoji):
            // Reports host, command, duration, the result code, and stdout on success, or stderr on failure.
            if output.returnCode != 0 {
                if includeEmoji {
                    stringOutput.append("❌ ")
                }
                stringOutput.append("[\(formattedDuration)] ")
                stringOutput.append("command: \(command), rc=\(output.returnCode)")
                if let errorOutput = output.stderrString {
                    stringOutput.append("\nSTDERR: \(errorOutput)")
                } else {
                    stringOutput.append(" No STDERR output.")
                }
            } else {
                if includeEmoji {
                    stringOutput.append("✅ ")
                }
                stringOutput.append("[\(formattedDuration)] ")
                stringOutput.append("command: \(command), rc=\(output.returnCode)")
                if let stdoutOutput = output.stdoutString {
                    stringOutput.append("\nSTDOUT: \(stdoutOutput)")
                } else {
                    stringOutput.append(" No STDOUT output.")
                }
            }
        case .debug(emoji: let includeEmoji):
            // Reports host, command, duration, the result code, stdout, and stderr returned from the command.
            if includeEmoji {
                if output.returnCode != 0 {
                    stringOutput.append("❌ ")
                } else {
                    stringOutput.append("✅ ")
                }
            }
            stringOutput.append("[\(formattedDuration)] ")
            stringOutput.append("command: \(command), rc=\(output.returnCode)")
            if let errorOutput = output.stderrString {
                stringOutput.append("\nSTDERR: \(errorOutput)")
            } else {
                stringOutput.append(" No STDERR output.")
            }
            if let stdoutOutput = output.stdoutString {
                stringOutput.append("\nSTDOUT: \(stdoutOutput)")
            } else {
                stringOutput.append(" No STDOUT output.")
            }
        }
        return stringOutput
    }
}
