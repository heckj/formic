/// The state of execution for a playbook.
public enum PlaybookRunState: Sendable, Hashable, Codable {
    /// The playbook is scheduled to run, but hasn't yet started.
    case scheduled  // initial state
    /// The playbook is in progress.
    case running
    /// The playbook is finished.
    case complete  // terminal state
    /// The playbook was terminated before completion due to a failed command.
    case failed  // terminal state
    /// The playbook was terminated before completion due to cancellation.
    case cancelled  // terminal state
}
