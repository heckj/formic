import Foundation

/// A general command that is run against a host.
public struct AnyCommand: Command {
    /// A Boolean value that indicates whether a failing command should fail a playbook.
    public let ignoreFailure: Bool
    /// The retry settings for the command.
    public let retry: Backoff
    /// The maximum duration to allow for the command.
    public let executionTimeout: Duration
    /// The ID of the command.
    public let id: UUID
    let name: String
    let commandClosure: @Sendable (Host) async throws -> CommandOutput

    /// Invokes a command on the host to verify access.
    /// - Parameters:
    ///   - name: A name for this command.
    ///   - ignoreFailure: A Boolean value that indicates whether a failing command should fail a playbook.
    ///   - retry: The retry settings for the command.
    ///   - executionTimeout: The maximum duration to allow for the command.
    ///   - commandClosure: An asynchronous closure that the engine invokes when it runs the command.
    public init(
        name: String,
        ignoreFailure: Bool,
        retry: Backoff,
        executionTimeout: Duration,
        commandClosure: @escaping @Sendable (Host) async throws -> CommandOutput
    ) {
        self.retry = retry
        self.ignoreFailure = ignoreFailure
        self.executionTimeout = executionTimeout
        self.commandClosure = commandClosure
        self.name = name
        id = UUID()
    }

    /// Runs the command to verify access to the host you provide.
    /// - Parameter host: The host on which to run the command.
    /// - Returns: The command output.
    @discardableResult
    public func run(host: Host) async throws -> CommandOutput {
        try await commandClosure(host)
    }
}

extension AnyCommand: Equatable {
    /// Returns a Boolean value that indicates whether the two commands are equal.
    /// - Parameters:
    ///   - lhs: The first command.
    ///   - rhs: The second command.
    /// - Returns: `true` if the settings, name, and ID of the commands are equal; `false` otherwise.
    public static func == (lhs: AnyCommand, rhs: AnyCommand) -> Bool {
        lhs.id == rhs.id && lhs.ignoreFailure == rhs.ignoreFailure && lhs.retry == rhs.retry
            && lhs.executionTimeout == rhs.executionTimeout && lhs.name == rhs.name
    }
}

extension AnyCommand: Hashable {
    /// Combines elements of the command to generate a hash value.
    /// - Parameter hasher: The hasher to use when combining the components of the command.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(ignoreFailure)
        hasher.combine(retry)
        hasher.combine(executionTimeout)
        hasher.combine(name)
    }
}

extension AnyCommand: CustomStringConvertible {
    /// A textual representation of the command.
    public var description: String {
        return name
    }
}
