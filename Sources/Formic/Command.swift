import Foundation
import Logging

/// A type that represents a command, run locally or remotely.
public protocol Command: Sendable, Identifiable, Hashable {
    /// The identifier of a command.
    var id: UUID { get }
    /// A Boolean value that indicates whether a failing command within a sequence should fail the overall sequence of commands.
    var ignoreFailure: Bool { get }
    /// The retry settings to apply when a command fails.
    var retry: Backoff { get }

    /// The maximum time allowed for the command to execute.
    var executionTimeout: Duration { get }

    /// The function that is invoked by an engine to run the command.
    /// - Parameters:
    ///   - host: The host on which the command is run.
    ///   - logger: An optional logger to record the command output or errors.
    /// - Returns: The combined output from the command execution.
    func run(host: RemoteHost, logger: Logger?) async throws -> CommandOutput
}
