/// The state of execution for a playbook.
public enum PlaybookRunState: Sendable, Hashable, Codable {
    /// The playbook is scheduled to run, but hasn't yet started.
    case scheduled
    /// The playbook is in progress.
    case running
    /// The playbook is finished.
    case complete
    /// The playbook was terminated before completion due to a failed command.
    case failed
    /// The playbook was terminated before completion due to cancellation.
    case cancelled
}
