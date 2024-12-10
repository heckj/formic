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
