import Dependencies
import Foundation
import Logging

/// A command to verify access to a host.
///
/// This command attempts to SSH to the remote host and invoke a simple command to verify access.
/// By default, this command will repeated with a backoff strategy if it fails, to provide time
/// for a remote host to reboot or otherwise become accessible.
///
/// To verify a remote host is immediately access, set the `retry` parameter to `.never` when defining the command.
public struct VerifyAccess: Command {
    /// A Boolean value that indicates whether a failing command should fail a playbook.
    public let ignoreFailure: Bool
    /// The retry settings for the command.
    public let retry: Backoff
    /// The maximum duration to allow for the command.
    public let executionTimeout: Duration
    /// The ID of the command.
    public let id: UUID

    /// Invokes a command on the host to verify access.
    /// - Parameters:
    ///   - ignoreFailure: A Boolean value that indicates whether a failing command should fail a playbook.
    ///   - retry: The retry settings for the command.
    ///   - executionTimeout: The maximum duration to allow for the command.
    public init(
        ignoreFailure: Bool = false,
        retry: Backoff = Backoff(
            maxRetries: 10,
            strategy: .fibonacci(maxDelay: .seconds(600))),
        executionTimeout: Duration = .seconds(30)
    ) {
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
    public func run(host: RemoteHost, logger: Logger?) async throws -> CommandOutput {
        @Dependency(\.commandInvoker) var invoker: any CommandInvoker
        let command = "echo 'hello'"

        let sshCreds = host.sshAccessCredentials
        let targetHostName = host.networkAddress.dnsName ?? host.networkAddress.address.description
        let answer = try await invoker.remoteShell(
            host: targetHostName,
            user: sshCreds.username,
            identityFile: sshCreds.identityFile,
            port: host.sshPort,
            strictHostKeyChecking: false,
            cmd: command,
            env: nil,
            logger: logger)

        if let answerString = answer.stdoutString, answerString.contains("hello") {
            return CommandOutput(returnCode: 0, stdOut: "hello".data(using: .utf8), stdErr: nil)
        } else {
            return CommandOutput(returnCode: -1, stdOut: nil, stdErr: "Unable to verify access.".data(using: .utf8))
        }
    }
}

extension VerifyAccess: CustomStringConvertible {
    /// A textual representation of the command.
    public var description: String {
        return "echo 'hello'"
    }
}
