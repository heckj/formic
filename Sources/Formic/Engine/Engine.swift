/// An engine that runs playbooks and exposes the results.
public actor Engine {
    let clock: ContinuousClock
    var playbooks: [Playbook.ID: Playbook]
    var states: [Playbook.ID: PlaybookRunState]
    var commandResults: [Host: [Command.ID: CommandExecutionResult]]
    var runners: [Host: Task<Void, any Error>]

    // TODO: potentially "stream" the results to observers using an asyncStream
    // either generally, or a stream per playbook stored?
    // - define the stream (or collection of streams) here and add in appropriate
    // yielding in the acceptResult method

    // MARK: Operating mode and scheduling

    /// Run a playbook.
    /// - Parameter playbook: The playbook to run.
    /// - Parameter delay: The delay between steps.
    /// - Parameter startRunner: A Boolean value that indicates whether to start the runner.
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
                    try await step(for: host)
                    try await Task.sleep(for: delay)
                }
                self.runners[host] = nil
            }
        }
    }

    /// Cancels ongoing processing for the host you provide.
    /// - Parameter host: The host to cancel processing for.
    public func cancel(_ playbookId: Playbook.ID) {
        if let state = states[playbookId] {
            switch state {
            case .scheduled, .running:
                states[playbookId] = .cancelled
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
        // runners[host] = nil
    }

    /// Returns a Boolean value that indicates whether there is active processing for the host you provide.
    /// - Parameter host: The host to check.
    public func status(_ host: Host) -> Bool {
        return runners[host] != nil
    }

    /// Returns the current state of the playbook you provide.
    /// - Parameter playbookId: The ID of the playbook to check.
    /// - Returns: The current state of the execution of the playbook.
    public func status(_ playbookId: Playbook.ID) -> PlaybookResult? {
        guard let playbook = playbooks[playbookId],
            let state = states[playbookId]
        else {
            return nil
        }
        var hostResults: [Host: [Command.ID: CommandExecutionResult]] = [:]
        // get a list of all the command IDs for this host in this playbook
        // public let results: [Host:[Command.ID:CommandExecutionResult]]

        for host in playbook.hosts {
            var resultsForHost: [Command.ID: CommandExecutionResult] = [:]
            // ALL results from the engine for this host
            if let allEngineResults: [Command.ID: CommandExecutionResult] = commandResults[host] {
                // only include the results for commands from this playbook
                for commandId in playbook.commands.map(\.id) {
                    if let executionResult = allEngineResults[commandId] {
                        resultsForHost[commandId] = executionResult
                    }
                }
            }
            hostResults[host] = resultsForHost
        }
        return PlaybookResult(state: state, playbook: playbook, results: hostResults)
    }

    // MARK: Coordination API

    func availableCommandsForHost(host: Host) -> [(Command, Playbook.ID)] {
        var availableCommands: [(Command, Playbook.ID)] = []
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
            let completedCommandIDs: [Command.ID] = commandResults[host]?.keys.map { $0 } ?? []
            let remainingCommands: [Command] = playbook.commands.filter { command in
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
        if var hostResultDict: [Command.ID: CommandExecutionResult] = commandResults[host] {
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
            }
            // if the result is failure, terminate the playbook unless its marked to be ignored
            if result.output.returnCode != 0 && !result.command.ignoreFailure {
                states[playbookId] = .failed
            } else {
                if result.command == playbooks[playbookId]?.commands.last {
                    states[playbookId] = .complete
                }
            }
            // TODO: potentially "stream" the results to observers using an asyncStream
            // either generally, or a stream per playbook stored?
        }
    }

    // MARK: Running API

    /// Runs the next command available for the host you provide.
    /// - Parameter host: The host to interact with.
    public nonisolated func step(for host: Host) async throws {
        // `nonisolated` + `async` means run on a cooperative thread pool and return the result
        // remove the `nonisolated` keyword to run in the actor's context.
        let availableCommands = await availableCommandsForHost(host: host)
        if let (nextCommand, playbookId) = availableCommands.first {
            //get and run
            let commandResult = try await run(command: nextCommand, host: host, playbookId: playbookId)
            await acceptResult(host: host, result: commandResult)
        }
    }

    /// Runs a single command against a single host.
    /// - Parameters:
    ///   - command: The command to run.
    ///   - host: The host on which to run the command.
    ///   - playbookId: The ID of the playbook the command is part of.
    /// - Returns: The result of the command execution.
    public nonisolated func run(command: Command, host: Host, playbookId: Playbook.ID? = nil) async throws
        -> CommandExecutionResult
    {
        // `nonisolated` + `async` means run on a cooperative thread pool and return the result
        // remove the `nonisolated` keyword to run in the actor's context.
        let start = clock.now
        // TODO: handle failure and retry logic
        let commandOutput = try command.run(host: host)
        let duration = clock.now - start
        return CommandExecutionResult(
            command: command, host: host, playbookId: playbookId, output: commandOutput, duration: duration, retries: 0)
    }

    /// Creates a new engine.
    public init() {
        clock = ContinuousClock()
        states = [:]
        commandResults = [:]
        runners = [:]
        playbooks = [:]
    }
}
