import Foundation

/// The level of console output.
public enum Verbosity: Int {
    /// Reports only failures
    case silent
    /// Reports host and command with an indication of command success or failure.
    case normal
    /// Reports host, command, and stdout on success, or stderr on failure.
    case verbose
    /// Reports host, command, the result code, stdout, and stderr returned from the command.
    case debug
}

/// The result of executing a command.
public struct CommandExecutionResult: Sendable, Hashable, Codable {
    /// The command.
    public let command: Command
    /// The host for the command.
    public let host: Host
    /// The output from the command.
    public let output: CommandOutput
    /// The duration of the command.
    public let duration: Duration
}

/// The state of execution for a playbook.
public enum PlaybookRunState: Sendable, Hashable, Codable {
    /// The playbook is scheduled to run, but hasn't yet started.
    case pending
    /// The playbook is in progress.
    case running
    /// The playbook is finished.
    case complete
    /// The playbook was terminated before completion.
    case terminated
}

/// A representation of the state of playbook execution.
public struct PlaybookResult: Sendable, Hashable, Codable {
    public let state: PlaybookRunState
    public let playbook: Playbook  // would like the name, but the rest is kind of redundant...
    public let results: [CommandExecutionResult]
    public var success: Bool {
        // if all commands are successful (except when ignored),
        // and all commands have been run for each host in the playbook
        // and state is complete.
        return false
    }
}

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

    func run(command: Command, host: Host, verbosity: Verbosity = .normal) throws -> CommandExecutionResult {
        let fakeOutput = CommandOutput(returnCode: 0, stdOut: nil, stdErr: nil)
        let result = CommandExecutionResult(command: command, host: host, output: fakeOutput, duration: .seconds(1))
        return result
    }

    init(states: [Playbook: PlaybookRunState]) {
        self.clock = ContinuousClock()
        self.states = states
    }
}
