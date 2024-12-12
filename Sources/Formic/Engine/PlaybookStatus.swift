/// A representation of the state of playbook execution.
public struct PlaybookStatus: Sendable, Hashable, Codable {
    public let state: PlaybookRunState
    public let playbook: Playbook  // would like the name, but the rest is kind of redundant...
    public let results: [Host: [Command.ID: CommandExecutionResult]]
}
