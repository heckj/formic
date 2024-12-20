import Foundation

/// An engine that runs playbooks and exposes the results.
public actor Engine {
    let clock: ContinuousClock
    var playbooks: [Playbook.ID: Playbook]
    var states: [Playbook.ID: PlaybookState]
    var commandResults: [Host: [UUID: CommandExecutionResult]]
    var runners: [Host: Task<Void, any Error>]

    /// An asynchronous stream of state updates for playbooks.
    ///
    /// You can request the state of a playbook by calling the ``status(_:)`` method
    /// or watch a stream of the command results as they process by reading the ``commandUpdates``
    /// stream.
    public nonisolated let playbookUpdates: AsyncStream<(Playbook.ID, PlaybookState)>
    let stateContinuation: AsyncStream<(Playbook.ID, PlaybookState)>.Continuation

    /// An asynchronous stream of command execution results.
    public nonisolated let commandUpdates: AsyncStream<(CommandExecutionResult)>
    let commandContinuation: AsyncStream<(CommandExecutionResult)>.Continuation

    /// Creates a new engine.
    public init() {
        clock = ContinuousClock()
        states = [:]
        commandResults = [:]
        runners = [:]
        playbooks = [:]

        // assemble the streams and continuations
        (playbookUpdates, stateContinuation) = AsyncStream.makeStream(of: (Playbook.ID, PlaybookState).self)
        (commandUpdates, commandContinuation) = AsyncStream.makeStream(of: CommandExecutionResult.self)
    }

    // MARK: Operating mode and scheduling

    /// Run a playbook.
    /// - Parameter playbook: The playbook to run.
    /// - Parameter delay: The delay between steps.
    /// - Parameter startRunner: A Boolean value that indicates whether to start the runner.
    ///
    /// If you schedule a playbook with `startRunner` set to `false`, the engine does not automatically
    /// create a runner to process the commands.
    /// Call ``step(for:)`` to process the commands individually.
    public func schedule(_ playbook: Playbook, delay: Duration = .seconds(1), startRunner: Bool = true) {
        for host in playbook.hosts {
            if commandResults[host] == nil {
                commandResults[host] = [:]
            }
        }
        // store a copy of the playbook
        playbooks[playbook.id] = playbook
        // set the initial state of the playbook
        states[playbook.id] = .scheduled
        stateContinuation.yield((playbook.id, .scheduled))

        for host in playbook.hosts {
            // initialize empty result set for each host listed in the playbook, if needed
            if commandResults[host] == nil {
                commandResults[host] = [:]
            }
            // start a runner for each host listed in the playbook
            if startRunner {
                createHostRunnerIfNeeded(host: host, delay: delay)
            }
        }
    }

    internal func createHostRunnerIfNeeded(host: Host, delay: Duration) {
        if runners[host] == nil {
            //let runner = HostRunner(host: host, operatingMode: .ongoing, engine: self)
            runners[host] = Task {
                while !Task.isCancelled {
                    await step(for: host)
                    try await Task.sleep(for: delay)
                }
                self.runners[host] = nil
            }
        }
    }

    /// Cancels ongoing processing for the host you provide.
    ///- Parameter playbookId: the Id of the playbook to cancel.
    public func cancel(_ playbookId: Playbook.ID) {
        if let state = states[playbookId] {
            switch state {
            case .scheduled, .running:
                states[playbookId] = .cancelled
                stateContinuation.yield((playbookId, .cancelled))
            case .complete, .failed, .cancelled:
                break
            }
        }
    }

    /// Cancels ongoing processing for the host you provide.
    /// - Parameter host: The host to cancel processing for.
    public func cancelRunner(for host: Host) {
        if let runner = runners[host] {
            runner.cancel()
        }
        runners[host] = nil
    }

    /// Returns a Boolean value that indicates whether there is active processing for the host you provide.
    /// - Parameter host: The host to check.
    public func runnerOperating(for host: Host) -> Bool {
        return runners[host] != nil
    }

    /// Returns the current state of the playbook you provide.
    /// - Parameter playbookId: The ID of the playbook to check.
    /// - Returns: The current state of the execution of the playbook.
    public func status(_ playbookId: Playbook.ID) -> PlaybookStatus? {
        guard let playbook = playbooks[playbookId],
            let state = states[playbookId]
        else {
            return nil
        }
        var hostResults: [Host: [UUID: CommandExecutionResult]] = [:]
        // get a list of all the command IDs for this host in this playbook
        // public let results: [Host:[Command.ID:CommandExecutionResult]]

        for host in playbook.hosts {
            var resultsForHost: [UUID: CommandExecutionResult] = [:]
            // ALL results from the engine for this host
            if let allEngineResults: [UUID: CommandExecutionResult] = commandResults[host] {
                // only include the results for commands from this playbook
                for commandId in playbook.commands.map(\.id) {
                    if let executionResult = allEngineResults[commandId] {
                        resultsForHost[commandId] = executionResult
                    }
                }
            }
            hostResults[host] = resultsForHost
        }
        return PlaybookStatus(state: state, playbook: playbook, results: hostResults)
    }

    // MARK: Coordination API

    func availableCommandsForHost(host: Host) -> [(any Command, Playbook.ID)] {
        var availableCommands: [(any Command, Playbook.ID)] = []
        // list of playbooks that are either scheduled or running
        // but not terminated, failed, or cancelled.
        let availablePlaybookIds: [Playbook.ID] = playbooks.keys.filter { id in
            // return true for isIncluded
            guard let playbookStatus = states[id] else {
                return false
            }
            if playbookStatus == .scheduled || playbookStatus == .running {
                return true
            }
            return false
        }
        for playbookId in availablePlaybookIds {
            guard let playbook = playbooks[playbookId] else {
                continue
            }
            let completedCommandIDs: [UUID] = commandResults[host]?.keys.map { $0 } ?? []
            let remainingCommands: [(any Command)] = playbook.commands.filter { command in
                return !completedCommandIDs.contains(command.id)
            }
            for command in remainingCommands {
                availableCommands.append((command, playbookId))
            }
        }
        return availableCommands
    }

    func acceptResult(host: Host, result: CommandExecutionResult) {
        // store the result
        if var hostResultDict: [UUID: CommandExecutionResult] = commandResults[host] {
            assert(hostResultDict[result.command.id] == nil, "Duplicate command result")
            hostResultDict[result.command.id] = result
            commandResults[host] = hostResultDict
        } else {
            // dictionary doesn't exist, create it and add result
            commandResults[host] = [result.command.id: result]
        }
        // If the result has a playbook associated with it, update the playbook state
        if let playbookId = result.playbookId {
            // advance the state to running if it wasn't before
            if states[playbookId] == .scheduled {
                states[playbookId] = .running
                stateContinuation.yield((playbookId, .running))
            }
            // if the result is failure, terminate the playbook unless its marked to be ignored
            if result.output.returnCode != 0 && !result.command.ignoreFailure {
                states[playbookId] = .failed
                stateContinuation.yield((playbookId, .failed))
            } else {
                if result.command.id == playbooks[playbookId]?.commands.last?.id {
                    // check for completion
                    if playbookComplete(playbookId: playbookId) {
                        states[playbookId] = .complete
                        stateContinuation.yield((playbookId, .complete))
                    }
                }
            }
        }
        // stream the result as well
        commandContinuation.yield(result)
    }

    func playbookComplete(playbookId: Playbook.ID) -> Bool {
        guard let originalPlaybook = playbooks[playbookId] else {
            return false
        }
        for host in originalPlaybook.hosts {
            guard let commandResultsForHost = commandResults[host],
                commandResultsForHost.count == originalPlaybook.commands.count
            else {
                return false
            }
            // host has all commands reported from original playbook
            let anyFailure = commandResultsForHost.contains { (id: UUID, result: CommandExecutionResult) in
                result.output.returnCode != 0 && !result.command.ignoreFailure
            }
            if anyFailure {
                return false
            }
        }
        return true
    }

    func handleCommandException(
        playbookId: Playbook.ID, host: Host, command: (any Command), exception: any Error
    ) {
        // store the result
        let exceptionReport = CommandExecutionResult(
            command: command, host: host, playbookId: playbookId, output: .empty, duration: .nanoseconds(0), retries: 0,
            exception: exception.localizedDescription)
        if var hostResultDict: [UUID: CommandExecutionResult] = commandResults[host] {
            assert(hostResultDict[command.id] == nil, "Duplicate command result")
            hostResultDict[command.id] = exceptionReport
            commandResults[host] = hostResultDict
        } else {
            // dictionary doesn't exist, create it and add result
            commandResults[host] = [command.id: exceptionReport]
        }
        states[playbookId] = .failed
        stateContinuation.yield((playbookId, .failed))
        // stream the result as well
        commandContinuation.yield(exceptionReport)
    }

    // MARK: Running API

    /// Runs the next command in the background that is available for the host you provide.
    /// - Parameter host: The host to interact with.
    public nonisolated func step(for host: Host) async {
        // `nonisolated` + `async` means run on a cooperative thread pool and return the result
        // remove the `nonisolated` keyword to run in the actor's context.
        let availableCommands = await availableCommandsForHost(host: host)
        if let (nextCommand, playbookId) = availableCommands.first {
            //get and run
            do {
                let commandResult = try await run(command: nextCommand, host: host, playbookId: playbookId)
                await acceptResult(host: host, result: commandResult)
            } catch {
                await handleCommandException(playbookId: playbookId, host: host, command: nextCommand, exception: error)
            }
        }
    }

    /// Directly runs a series of commands against a single host.
    /// - Parameters:
    ///   - host: The host on which to run the command.
    ///   - commands: The commands to run.
    ///   - displayProgress: A Boolean value that indicates whether to display progress while the commands are executed.
    ///   - verbosity: The level of verbosity for reporting progress.
    /// - Returns: A list of the results of the command executions.
    @discardableResult
    public func run(
        host: Host, commands: [(any Command)], displayProgress: Bool,
        verbosity: Verbosity = .silent(emoji: true)
    ) async throws -> [CommandExecutionResult] {
        var results: [CommandExecutionResult] = []
        for command in commands {
            let result = try await run(command: command, host: host)
            results.append(result)
            if displayProgress {
                print(result.consoleOutput(verbosity: verbosity))
            }
        }
        return results
    }

    /// Directly runs a playbook in the foreground, one host at time.
    /// - Parameters:
    ///   - playbook:  The playbook to run.
    ///   - displayProgress: A Boolean value that indicates whether to display progress while the playbook is executed.
    ///   - verbosity: The verbosity level to use if you display progress.
    /// - Returns: The combined playbook state when the run is complete.
    /// - Throws: Any exceptions that occur while running the playbook.
    ///
    /// Exceptions are not captured and embedded in results when running in the foreground.
    @discardableResult
    public func run(playbook: Playbook, displayProgress: Bool, verbosity: Verbosity = .silent(emoji: true)) async throws
        -> PlaybookStatus
    {

        var failed: Bool = false
        //public let results: [Host: [Command.ID: CommandExecutionResult]]
        var hostResults: [Host: [UUID: CommandExecutionResult]] = [:]
        for host in playbook.hosts {
            var results: [UUID: CommandExecutionResult] = [:]
            for command in playbook.commands {
                let result = try await run(command: command, host: host, playbookId: playbook.id)
                results[result.command.id] = result
                if displayProgress {
                    print(result.consoleOutput(verbosity: verbosity))
                }

                if result.output.returnCode != 0 && !result.command.ignoreFailure {
                    failed = true
                    break
                }
            }
            hostResults[host] = results
        }

        if failed {
            return PlaybookStatus(state: .failed, playbook: playbook, results: hostResults)
        } else {
            return PlaybookStatus(state: .complete, playbook: playbook, results: hostResults)
        }
    }

    /// Directly runs a single command against a single host.
    /// - Parameters:
    ///   - command: The command to run.
    ///   - host: The host on which to run the command.
    ///   - playbookId: The ID of the playbook the command is part of.
    /// - Returns: The result of the command execution.
    public nonisolated func run(command: (any Command), host: Host, playbookId: Playbook.ID? = nil) async throws
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
                    command: command, host: host, playbookId: playbookId, output: outputOfLastAttempt,
                    duration: durationOfLastAttempt, retries: numberOfRetries,
                    exception: nil)
            } else {
                let delay = command.retry.strategy.delay(for: numberOfRetries, withJitter: true)
                try await Task.sleep(for: delay)
            }
        } while command.retry.retryOnFailure && numberOfRetries < command.retry.maxRetries

        return CommandExecutionResult(
            command: command, host: host, playbookId: playbookId, output: outputOfLastAttempt,
            duration: durationOfLastAttempt, retries: numberOfRetries,
            exception: nil)
    }
}
