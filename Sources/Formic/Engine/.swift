///// The state of execution for a playbook.
//public enum PlaybookState: Sendable, Hashable, Codable {
//    /// The playbook is scheduled to run, but hasn't yet started.
//    ///
//    /// This is the initial state.
//    ///
//    /// A playbook will generally transition to ``running`` once any command from it has been accepted back by the engine.
//    /// A playbook may transition directly to ``failed`` if an exception is thrown while
//    /// running a command.
//    /// It may also transition to ``cancelled`` if it is cancelled using ``Engine/cancel(_:)`` before any commands were run.
//    case scheduled
//    /// The playbook is in progress.
//    ///
//    /// The playbook stays in this state until all commands have been run.
//    /// When a command is run that returns a failed, and the command wasn't set to ignore the failure or when an exception, the playbook transitions to ``failed``.
//    /// If all commands are run without any failures to report, the playbook transitions to ``complete``.
//    case running
//    /// The playbook is finished without any failed commands.
//    ///
//    /// This is a terminal state.
//    case complete
//    /// The playbook was terminated due to a failed command
//    /// or an exception being thrown while attempting to run a command.
//    ///
//    /// This is a terminal state.
//    case failed
//    /// The playbook was terminated before completion due to cancellation.
//    ///
//    /// This is a terminal state.
//    case cancelled
//}
