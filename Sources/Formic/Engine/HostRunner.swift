actor HostRunner {
    weak var engine: Engine?
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
    var runner: Task<Void, any Error>?
    let host: Host
    let runnerDelay: Duration

    // IMPLEMENTATION NOTES:
    //
    // I likely made this more complicated than it needs to be. The gist is that I wanted
    // to never have parallel tasks operating on a single host. I'm creating a host-specific runner
    // that independently operates, requesting any available tasks, running the first one it receives,
    // and then pushing the result back to the engine.
    //
    // I've carefully kept the declarations of playbooks, commands, and the results all sendable to
    // make this transfer easily over the isolation boundaries.
    //
    // The actual "run" is on the engine Actor, and runs as an nonisolated async task (aka in
    // the concurrent queue), and I leave the sequencing within the actor in a loop, awaiting
    // and continuing.

    func start(stepping: Bool = false) {
        if stepping {
            operatingMode = .stepping
            readyForNext = false
        } else {
            operatingMode = .ongoing
        }
        runner = Task {
            while operatingMode != .stopped {
                guard let engine = engine else {
                    // terminate running if not engine is available to interact with (deinit)
                    return
                }
                let availableCommands = await engine.availableCommandsForHost(host: host)
                if let nextCommand = availableCommands.first {
                    if (operatingMode == .stepping && readyForNext) || operatingMode == .ongoing {
                        //get and run
                        let commandResult = try await engine.run(command: nextCommand, host: host)
                        await engine.acceptResult(host: host, result: commandResult)
                    }
                }
                try await Task.sleep(for: runnerDelay)
            }
            operatingMode = .stopped
        }
    }

    // I originally fleshed out the idea of an operating mode to allow for stepping through a
    // playbook a piece at a time, but the commands to allow that through an engine don't yet exist.
    func step() {
        if operatingMode == .stepping {
            readyForNext = true
        }
    }

    func stop() {
        readyForNext = false
        operatingMode = .stopped
        runner?.cancel()
    }

    init(host: Host, operatingMode: EngineOperationMode, engine: Engine, start: Bool = true) {
        self.operatingMode = operatingMode
        self.readyForNext = false
        self.host = host
        self.engine = engine
        self.runnerDelay = .seconds(1)
        self.runner = nil

        if start {
            Task {
                await self.start()
            }
        }
    }

    deinit {
        self.runner?.cancel()
    }
}
