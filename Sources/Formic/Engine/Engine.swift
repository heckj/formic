/// An engine that runs playbooks and exposes the results.
public actor Engine {
    let clock: ContinuousClock
    var playbooks: [Playbook.ID: Playbook]
    var states: [Playbook.ID: PlaybookRunState]
    var commandResults: [Host: [Command.ID: CommandExecutionResult]]
    var runners: [Host: HostRunner]

    // async stream of playbook results as it executes?

    // MARK: Operating mode and scheduling

    func schedule(_ playbook: Playbook) -> PlaybookResult {
        for host in playbook.hosts {
            if commandResults[host] == nil {
                commandResults[host] = [:]
            }
        }
        playbooks[playbook.id] = playbook
        states[playbook.id] = .scheduled

        var hostResults: [Host: [Command.ID: CommandExecutionResult]] = [:]
        for host in playbook.hosts {
            hostResults[host] = [:]
            createHostRunnerIfNeeded(host: host)
        }
        let scheduled = PlaybookResult(state: .scheduled, playbook: playbook, results: hostResults)
        return scheduled
    }

    func createHostRunnerIfNeeded(host: Host) {
        if runners[host] == nil {
            let runner = HostRunner(host: host, operatingMode: .ongoing, engine: self)
            runners[host] = runner
        }
    }

    func status(_ playbook: Playbook) -> PlaybookResult? {
        guard let state = states[playbook.id] else {
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

    // MARK: HostRunners API

    func availableCommandsForHost(host: Host) -> [Command] {
        var availableCommands: [Command] = []
        // list of playbooks that are either scheduled or running
        // but not terminated, failed, or cancelled.
        let availablePlaybookIDs: [Playbook.ID] = playbooks.keys.filter { id in
            // return true for isIncluded
            guard let playbookStatus = states[id] else {
                return false
            }
            if playbookStatus == .scheduled || playbookStatus == .running {
                return true
            }
            return false
        }
        for playbookID in availablePlaybookIDs {
            guard let playbook = playbooks[playbookID] else {
                continue
            }
            let completedCommandIDs: [Command.ID] = commandResults[host]?.keys.map { $0 } ?? []
            let remainingCommands: [Command] = playbook.commands.filter { command in
                return !completedCommandIDs.contains(command.id)
            }
            availableCommands.append(contentsOf: remainingCommands)
        }
        return availableCommands
    }

    func acceptResult(host: Host, result: CommandExecutionResult) {
        if var hostResultDict: [Command.ID: CommandExecutionResult] = commandResults[host] {
            assert(hostResultDict[result.command.id] == nil, "Duplicate command result")
            hostResultDict[result.command.id] = result
            commandResults[host] = hostResultDict
        } else {
            // dictionary doesn't exist, create it and add result
            commandResults[host] = [result.command.id: result]
        }
    }

    // MARK: Run Once - no inherent scheduling coordination

    /// Runs a single command against a single host.
    /// - Parameters:
    ///   - command: The command to run.
    ///   - host: The host on which to run the command.
    /// - Returns: The result of the command execution.
    public nonisolated func run(command: Command, host: Host) async throws -> CommandExecutionResult {
        // `nonisolated` + `async` means run on a cooperative thread pool and return the result
        // remove the `nonisolated` keyword to run in the actor's context.
        let start = clock.now
        // TODO: handle failure and retry logic
        let commandOutput = try command.run(host: host)
        let duration = clock.now - start
        return CommandExecutionResult(
            command: command, host: host, output: commandOutput, duration: duration, retries: 0)
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
