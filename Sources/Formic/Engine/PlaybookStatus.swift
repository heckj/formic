import Foundation

/// A representation of the state of playbook execution.
public struct PlaybookStatus: Sendable, Hashable {
    /// The state of the playbook.
    public let state: PlaybookState
    /// The playbook declaration.
    public let playbook: Playbook
    /// A nested dictionary of all results for this playbook, keyed by host, then by command ID.
    public let results: [Host: [UUID: CommandExecutionResult]]
}
