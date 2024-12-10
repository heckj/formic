/// An engine that runs playbooks and exposes the results.
public actor Engine {
    let clock: ContinuousClock
    var states: [Playbook.ID: PlaybookRunState]
    var currentState: [Playbook.ID: PlaybookResult]
    var operatingMode: EngineOperationMode
    enum EngineOperationMode {
        case ongoing
        case stepping
        // when in stepping mode, only process is "readyForNext" is true.
        // expected behavior is that the user calls step() to advance to the next
        // available step.
        case stopped
    }
    var readyForNext: Bool

    // async stream of playbook results as it executes?

    // ability to cancel a playbook in progress?

    // MARK: Operating mode and scheduling

    func start(stepping: Bool = false) {
        if stepping {
            operatingMode = .stepping
        } else {
            operatingMode = .ongoing
        }
        readyForNext = false
    }

    func step() {
        if operatingMode == .stepping {
            readyForNext = true
        }
    }

    func stop() {
        operatingMode = .stopped
    }

    func schedule(_ playbook: Playbook) -> PlaybookResult {
        states[playbook.id] = .scheduled
        let scheduled = PlaybookResult(state: .scheduled, playbook: playbook, results: [])
        currentState[playbook.id] = scheduled
        return scheduled
    }

    func status(_ playbook: Playbook) -> PlaybookResult? {
        guard let state = states[playbook.id], let output = currentState[playbook.id] else {
            return nil
        }
        return PlaybookResult(state: state, playbook: playbook, results: output.results)
    }

    // MARK: Run Ongoing

    // MARK: Run Once - no scheduling

    /// Runs a single command against a single host.
    /// - Parameters:
    ///   - command: The command to run.
    ///   - host: The host on which to run the command.
    /// - Returns: The result of the command execution.
    public nonisolated func run(command: Command, host: Host) async throws -> CommandExecutionResult {
        // `nonisolated` + `async` means run on a cooperative thread pool and return the result
        // remove the `nonisolated` keyword to run in the actor's context.
        let start = clock.now
        let commandOutput = try command.run(host: host)
        let duration = clock.now - start
        return CommandExecutionResult(command: command, host: host, output: commandOutput, duration: duration)
    }

    /// Creates a new engine.
    public init() {
        clock = ContinuousClock()
        states = [:]
        currentState = [:]
        operatingMode = .stopped
        readyForNext = false
    }
}
