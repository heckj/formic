import Dependencies
import Foundation
import Logging

/// A command to run on a local or remote host.
///
/// This command uses SSH through a local process to invoke commands on a remote host.
/// Do not use shell control or redirect operators in the command string.
public struct ShellCommand: Command {
    /// The command and arguments to run.
    public let commandString: String
    /// An optional dictionary of environment variables the system sets when it runs the command.
    public let env: [String: String]?
    /// A Boolean value that indicates whether a failing command should fail a playbook.
    public let ignoreFailure: Bool
    /// The retry settings for the command.
    public let retry: Backoff
    /// The maximum duration to allow for the command.
    public let executionTimeout: Duration
    /// The ID of the command.
    public let id: UUID

    /// Creates a new command declaration that the engine runs as a shell command.
    /// - Parameters:
    ///   - argString: the command and arguments to run as a single string separated by spaces.
    ///   - env: An optional dictionary of environment variables the system sets when it runs the command.
    ///   - chdir: An optional directory to change to before running the command.
    ///   - ignoreFailure: A Boolean value that indicates whether a failing command should fail a playbook.
    ///   - retry: The retry settings for the command.
    ///   - executionTimeout: The maximum duration to allow for the command.
    public init(
        _ argString: String, env: [String: String]? = nil, chdir: String? = nil,
        ignoreFailure: Bool = false,
        retry: Backoff = .never, executionTimeout: Duration = .seconds(120)
    ) {
        self.commandString = argString
        self.env = env
        self.retry = retry
        self.ignoreFailure = ignoreFailure
        self.executionTimeout = executionTimeout
        id = UUID()
    }

    /// The function that is invoked by an engine to run the command.
    /// - Parameters:
    ///   - host: The host on which the command is run.
    ///   - logger: An optional logger to record the command output or errors.
    /// - Returns: The combined output from the command execution.
    @discardableResult
    public func run(host: Host, logger: Logger?) async throws -> CommandOutput {
        @Dependency(\.commandInvoker) var invoker: any CommandInvoker
        if host.remote {
            let sshCreds = host.sshAccessCredentials
            let targetHostName = host.networkAddress.dnsName ?? host.networkAddress.address.description
            return try await invoker.remoteShell(
                host: targetHostName,
                user: sshCreds.username,
                identityFile: sshCreds.identityFile,
                port: host.sshPort,
                strictHostKeyChecking: host.strictHostKeyChecking,
                cmd: commandString,
                env: env,
                logger: logger
            )
        } else {
            let parsedArgsBySpace: [String] = commandString.split(separator: .whitespace).map(String.init)
            return try await invoker.localShell(
                cmd: parsedArgsBySpace, stdIn: nil, env: env, logger: logger)
        }
    }
}

extension ShellCommand: CustomStringConvertible {
    /// A textual representation of the command.
    public var description: String {
        return commandString
    }
}
