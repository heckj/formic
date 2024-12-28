/// The result of executing a command.
public struct CommandExecutionResult: Sendable {
    /// The command.
    public let command: any Command
    /// The host for the command.
    public let host: Host
    /// The output from the command.
    public let output: CommandOutput
    /// The duration of execution of the command.
    public let duration: Duration
    /// The number of retries needed for the command.
    public let retries: Int
    /// The description of the exception thrown while invoking the command, if any.
    public let exception: String?

    /// Creates an annotated command execution result.
    /// - Parameters:
    ///   - command: The command.
    ///   - host: The host for the command.
    ///   - playbookId: The ID of the playbook the command is part of, it any.
    ///   - output: The output from the command
    ///   - duration: The duration of execution of the command.
    ///   - retries: The number of retries needed for the command.
    ///   - exception: The description of the exception thrown while invoking the command, if any.
    public init(
        command: any Command, host: Host, output: CommandOutput, duration: Duration,
        retries: Int, exception: String?
    ) {
        self.command = command
        self.host = host
        self.output = output
        self.duration = duration
        self.retries = retries
        self.exception = exception
    }

    /// Returns a Boolean value that indicates if the execution result represents a failure.
    public func representsFailure() -> Bool {
        output.returnCode != 0 && !command.ignoreFailure
    }
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
            } else if representsFailure() {
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
    /// Returns `true` if the two execution results are equal.
    /// - Parameters:
    ///   - lhs: The first execution result
    ///   - rhs: The second execution result
    public static func == (lhs: CommandExecutionResult, rhs: CommandExecutionResult) -> Bool {
        lhs.command.id == rhs.command.id && lhs.host == rhs.host
            && lhs.output == rhs.output && lhs.duration == rhs.duration && lhs.retries == rhs.retries
            && lhs.exception == rhs.exception
    }
}

extension CommandExecutionResult: Hashable {
    /// Hashes the essential components of the execution result.
    /// - Parameter hasher: The hasher to use when combining the components
    public func hash(into hasher: inout Hasher) {
        let hashOfCommand = command.hashValue
        hasher.combine(hashOfCommand)
        hasher.combine(host)
        hasher.combine(output)
        hasher.combine(duration)
        hasher.combine(retries)
        hasher.combine(exception)
    }
}
