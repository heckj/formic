import Foundation

/// An engine that runs playbooks and exposes the results.
public actor Engine {
    let clock: ContinuousClock

    /// An asynchronous stream of command execution results.
    public nonisolated let commandUpdates: AsyncStream<(CommandExecutionResult)>
    let commandContinuation: AsyncStream<(CommandExecutionResult)>.Continuation

    /// Creates a new engine.
    public init() {
        clock = ContinuousClock()

        // assemble the streams and continuations
        (commandUpdates, commandContinuation) = AsyncStream.makeStream(of: CommandExecutionResult.self)
    }

    /// Directly runs a series of commands against a single host.
    /// - Parameters:
    ///   - host: The host on which to run the command.
    ///   - displayProgress: A Boolean value that indicates whether to display progress while the commands are executed.
    ///   - verbosity: The level of verbosity for reporting progress.
    ///   - commands: The commands to run.
    /// - Returns: A list of the results of the command executions.
    @discardableResult
    public func run(
        host: Host,
        displayProgress: Bool,
        verbosity: Verbosity = .silent(emoji: true),
        commands: [(any Command)]
    ) async throws -> [CommandExecutionResult] {
        var results: [CommandExecutionResult] = []
        for command in commands {
            let result = try await run(host: host, command: command)
            results.append(result)
            if displayProgress {
                print(result.consoleOutput(verbosity: verbosity))
            }
            if result.representsFailure() {
                break
            }
        }
        return results
    }

    /// Runs a series of commands on all of the hosts you provide.
    /// - Parameters:
    ///   - hosts: The hosts on which to run the commands.
    ///   - displayProgress: A Boolean value that indicates whether to display progress while the playbook is executed.
    ///   - verbosity: The verbosity level to use if you display progress.
    ///   - commands: The commands to run.
    /// - Returns: A dictionary of the command results by host.
    /// - Throws: Any exceptions that occur while running the commands.
    @discardableResult
    public func run(
        hosts: [Host],
        displayProgress: Bool,
        verbosity: Verbosity = .silent(emoji: true),
        commands: [(any Command)]
    ) async throws
        -> [Host: [CommandExecutionResult]]
    {
        var hostResults: [Host: [CommandExecutionResult]] = [:]

        for host in hosts {
            async let resultsOfSingleHost = self.run(
                host: host, displayProgress: displayProgress, verbosity: verbosity, commands: commands)
            hostResults[host] = try await resultsOfSingleHost
        }

        return hostResults
    }

    /// Directly runs a single command against a single host, applying the retry and timeout policies of the command.
    /// - Parameters:
    ///   - host: The host on which to run the command.
    ///   - command: The command to run.
    /// - Returns: The result of the command execution.
    public nonisolated func run(host: Host, command: (any Command)) async throws
        -> CommandExecutionResult
    {
        // `nonisolated` + `async` means run on a cooperative thread pool and return the result
        // remove the `nonisolated` keyword to run in the actor's context.
        var numberOfRetries: Int = -1
        var durationOfLastAttempt: Duration = .zero
        var outputOfLastAttempt: CommandOutput = .empty

        repeat {
            numberOfRetries += 1
            let start = clock.now
            outputOfLastAttempt = try await withThrowingTaskGroup(of: CommandOutput.self, returning: CommandOutput.self)
            {
                group in
                group.addTask {
                    return try await command.run(host: host)
                }
                group.addTask {
                    try await Task.sleep(for: command.executionTimeout)
                    try Task.checkCancellation()
                    throw CommandError.timeoutExceeded(cmd: command)
                }
                guard let output = try await group.next() else {
                    throw CommandError.noOutputFromCommand(cmd: command)
                }
                group.cancelAll()
                return output
            }
            durationOfLastAttempt = clock.now - start

            if outputOfLastAttempt.returnCode == 0 {
                return CommandExecutionResult(
                    command: command, host: host, output: outputOfLastAttempt,
                    duration: durationOfLastAttempt, retries: numberOfRetries,
                    exception: nil)
            } else {
                let delay = command.retry.strategy.delay(for: numberOfRetries, withJitter: true)
                try await Task.sleep(for: delay)
            }
        } while command.retry.retryOnFailure && numberOfRetries < command.retry.maxRetries

        return CommandExecutionResult(
            command: command, host: host, output: outputOfLastAttempt,
            duration: durationOfLastAttempt, retries: numberOfRetries,
            exception: nil)
    }
}
