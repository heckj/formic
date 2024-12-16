/// The result of executing a command.
public struct CommandExecutionResult: Sendable {
    /// The command.
    public let command: any CommandProtocol  // switch to command id?
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
    /// The description of the exception thrown while invoking the command, if any.
    public let exception: String?
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
            if includeEmoji {
                stringOutput.append(emojiString())
            }
            // Reports only failure.
            if let exception = exception {
                if includeEmoji {
                    stringOutput.append(" ")
                }
                stringOutput.append("exception: \(exception)")
            } else if output.returnCode != 0 && !command.ignoreFailure {
                if includeEmoji {
                    stringOutput.append(" ")
                }
                stringOutput.append("return code: \(output.returnCode)")
                if let errorOutput = output.stderrString {
                    stringOutput.append("\nSTDERR: \(errorOutput)")
                } else {
                    stringOutput.append("\nNo STDERR output.")
                }
            }
        case .normal(emoji: let includeEmoji):
            // Reports host and command with an indication of command success or failure.
            if includeEmoji {
                stringOutput.append("\(emojiString()) ")
            }
            if let exception = exception {
                if includeEmoji {
                    stringOutput.append(" ")
                }
                stringOutput.append("exception: \(exception)")
            } else if output.returnCode != 0 {
                stringOutput.append("command: \(command), rc=\(output.returnCode), retries=\(retries)")
                if let errorOutput = output.stderrString {
                    stringOutput.append("\nSTDERR: \(errorOutput)")
                } else {
                    stringOutput.append(" No STDERR output.")
                }
            } else {
                stringOutput.append("command: \(command), rc=\(output.returnCode), retries=\(retries)")
            }
        case .verbose(emoji: let includeEmoji):
            // Reports host, command, duration, the result code, and stdout on success, or stderr on failure.
            if includeEmoji {
                stringOutput.append("\(emojiString()) ")
            }
            if let exception = exception {
                if includeEmoji {
                    stringOutput.append(" ")
                }
                stringOutput.append("exception: \(exception)")
            } else if output.returnCode != 0 {
                stringOutput.append("[\(formattedDuration)] ")
                stringOutput.append("command: \(command), rc=\(output.returnCode), retries=\(retries)")
                if let errorOutput = output.stderrString {
                    stringOutput.append("\nSTDERR: \(errorOutput)")
                } else {
                    stringOutput.append(" No STDERR output.")
                }
            } else {
                stringOutput.append("[\(formattedDuration)] ")
                stringOutput.append("command: \(command), rc=\(output.returnCode), retries=\(retries)")
                if let stdoutOutput = output.stdoutString {
                    stringOutput.append("\nSTDOUT: \(stdoutOutput)")
                } else {
                    stringOutput.append(" No STDOUT output.")
                }
            }
        case .debug(emoji: let includeEmoji):
            // Reports host, command, duration, the result code, stdout, and stderr returned from the command.
            if includeEmoji {
                stringOutput.append("\(emojiString()) ")
            }
            if let exception = exception {
                if includeEmoji {
                    stringOutput.append(" ")
                }
                stringOutput.append("exception: \(exception)")
            } else {
                stringOutput.append("[\(formattedDuration)] ")
                stringOutput.append("command: \(command), rc=\(output.returnCode), retries=\(retries)")
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
        }
        return stringOutput
    }

    func emojiString() -> String {
        if exception != nil {
            return "🚫"
        } else if output.returnCode != 0 {
            return command.ignoreFailure ? "⚠️" : "❌"
        } else {
            return "✅"
        }
    }
}

extension CommandExecutionResult: Equatable {
    public static func == (lhs: CommandExecutionResult, rhs: CommandExecutionResult) -> Bool {
        lhs.command.id == rhs.command.id && lhs.host == rhs.host && lhs.playbookId == rhs.playbookId
            && lhs.output == rhs.output && lhs.duration == rhs.duration && lhs.retries == rhs.retries
            && lhs.exception == rhs.exception
    }
}

extension CommandExecutionResult: Hashable {
    public func hash(into hasher: inout Hasher) {
        let hashOfCommand = command.hashValue
        hasher.combine(hashOfCommand)
        hasher.combine(host)
        hasher.combine(playbookId)
        hasher.combine(output)
        hasher.combine(duration)
        hasher.combine(retries)
        hasher.combine(exception)
    }
}
