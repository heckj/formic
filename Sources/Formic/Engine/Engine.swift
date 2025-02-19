import Foundation
import Logging

/// An engine that runs playbooks and exposes the results.
public actor Engine {
    let clock: ContinuousClock
    let logger: Logger?

    /// An asynchronous stream of command execution results.
    public nonisolated let commandUpdates: AsyncStream<(CommandExecutionResult)>
    let commandContinuation: AsyncStream<(CommandExecutionResult)>.Continuation

    /// Creates a new engine.
    public init(logger: Logger? = nil) {
        clock = ContinuousClock()
        self.logger = logger

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
        host: RemoteHost,
        displayProgress: Bool,
        detailLevel: CommandOutputDetail = .silent(emoji: true),
        commands: [(any Command)]
    ) async throws -> [CommandExecutionResult] {
        var results: [CommandExecutionResult] = []
        for command in commands {
            logger?.debug("running command: \(command)")

            let result = try await run(host: host, command: command)
            results.append(result)
            if displayProgress {
                logger?.info("\(result.consoleOutput(detailLevel: detailLevel))")
            }
            if result.representsFailure() {
                logger?.debug("result: \(result) represents failure - breaking")
                break
            }
        }
        logger?.debug("returning \(results.count) CEResults")
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
        hosts: [RemoteHost],
        displayProgress: Bool,
        detailLevel: CommandOutputDetail = .silent(emoji: true),
        commands: [(any Command)]
    ) async throws
        -> [RemoteHost: [CommandExecutionResult]]
    {
        var hostResults: [RemoteHost: [CommandExecutionResult]] = [:]

        for host in hosts {
            async let resultsOfSingleHost = self.run(
                host: host, displayProgress: displayProgress, detailLevel: detailLevel, commands: commands)
            hostResults[host] = try await resultsOfSingleHost
        }

        return hostResults
    }

    /// Directly runs a single command against a single host, applying the retry and timeout policies of the command.
    /// - Parameters:
    ///   - host: The host on which to run the command.
    ///   - command: The command to run.
    /// - Returns: The result of the command execution.
    /// - Throws: exceptions from Task.sleep delay while retrying.
    public nonisolated func run(host: RemoteHost, command: (any Command)) async throws
        -> CommandExecutionResult
    {
        // `nonisolated` + `async` means run on a cooperative thread pool and return the result
        // remove the `nonisolated` keyword to run in the actor's context.
        var numberOfRetries: Int = -1
        var durationOfLastAttempt: Duration = .zero
        var outputOfLastAttempt: CommandOutput = .empty
        var capturedException: (any Error)? = nil

        repeat {
            capturedException = nil
            numberOfRetries += 1
            let start = clock.now
            do {
                logger?.debug("running command \(command) against \(host)")
                outputOfLastAttempt = try await command.run(host: host, logger: logger)
                // - DISABLED execution timeout checking because it's hanging when
                // the process that invokes the commands is Foundation.process, which is all
                // synchronous/blocking code, and fairly incompatible with async/await.
                //
                //    outputOfLastAttempt = try await withThrowingTaskGroup(
                //        of: CommandOutput.self, returning: CommandOutput.self
                //    ) {
                //        group in
                //        group.addTask {
                //            return try await command.run(host: host)
                //        }
                //        group.addTask {
                //            try await Task.sleep(for: command.executionTimeout)
                //            try Task.checkCancellation()
                //            throw CommandError.timeoutExceeded(cmd: command)
                //        }
                //        guard let output = try await group.next() else {
                //            throw CommandError.noOutputFromCommand(cmd: command)
                //        }
                //        group.cancelAll()
                //        return output
                //    }
            } catch {
                // catch inner exception conditions and treat as a failure to allow for
                // retries and timeouts to be handled.
                capturedException = error
                // mark as a failure due to the exception capture - if not marked
                // as a failure explicitly, .empty is assumed to be a success.
                outputOfLastAttempt = .exceptionFailure()
            }
            durationOfLastAttempt = clock.now - start

            // if successful, return the output immediately
            if outputOfLastAttempt.returnCode == 0 {
                return CommandExecutionResult(
                    command: command, host: host, output: outputOfLastAttempt,
                    duration: durationOfLastAttempt, retries: numberOfRetries,
                    exception: nil)
            }

            // otherwise, prep for possible retry
            if command.retry.retryOnFailure && numberOfRetries < command.retry.maxRetries {
                let delay = command.retry.strategy.delay(for: numberOfRetries, withJitter: true)
                logger?.trace("delaying for \(delay) due to failure before retrying command: \(command)")
                try await Task.sleep(for: delay)
            }
        } while command.retry.retryOnFailure && numberOfRetries < command.retry.maxRetries

        return CommandExecutionResult(
            command: command, host: host, output: outputOfLastAttempt,
            duration: durationOfLastAttempt, retries: numberOfRetries,
            exception: capturedException)
    }
}
