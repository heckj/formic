/// An engine that runs playbooks and exposes the results.
public actor Engine {
    let clock: ContinuousClock
    var states: [Playbook: PlaybookRunState]
    // async stream of playbook results as it executes?

    // start/stop controls for the engine?
    // list of playbooks that are running?
    // ability to cancel a playbook in progress?

    func run(_ playbook: Playbook) throws -> PlaybookResult {
        fatalError()
    }

    nonisolated func run(command: Command, host: Host) async throws -> CommandExecutionResult {
        // `nonisolated` + `async` means run on a cooperative thread pool and return the result
        // remove the `nonisolated` keyword to run in the actor's context.
        let start = clock.now
        let commandOutput = try command.run(host: host)
        let duration = clock.now - start
        return CommandExecutionResult(command: command, host: host, output: commandOutput, duration: duration)
    }

    init(states: [Playbook: PlaybookRunState]) {
        self.clock = ContinuousClock()
        self.states = states
    }
}
