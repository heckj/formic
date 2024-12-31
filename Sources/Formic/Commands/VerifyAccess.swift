import Dependencies
import Foundation

/// A command to verify access to a host.
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

    /// Runs the command to verify access to the host you provide.
    /// - Parameter host: The host on which to run the command.
    /// - Returns: The command output.
    @discardableResult
    public func run(host: Host) async throws -> CommandOutput {
        @Dependency(\.commandInvoker) var invoker: any CommandInvoker
        let command = "echo 'hello'"

        let answer: CommandOutput
        if host.remote {
            let sshCreds = host.sshAccessCredentials
            let targetHostName = host.networkAddress.dnsName ?? host.networkAddress.address.description
            answer = try await invoker.remoteShell(
                host: targetHostName,
                user: sshCreds.username,
                identityFile: sshCreds.identityFile,
                port: host.sshPort,
                strictHostKeyChecking: false,
                chdir: nil,
                cmd: command,
                env: nil,
                debugPrint: false)
        } else {
            answer = try await invoker.localShell(cmd: command, stdIn: nil, env: nil, chdir: nil, debugPrint: false)
        }
        if answer.stdoutString != "hello" {
            return CommandOutput(returnCode: -1, stdOut: nil, stdErr: "Unable to verify access.".data(using: .utf8))
        } else {
            return CommandOutput(returnCode: 0, stdOut: "hello".data(using: .utf8), stdErr: nil)
        }
    }
}

extension VerifyAccess: CustomStringConvertible {
    /// A textual representation of the command.
    public var description: String {
        return "echo 'hello'"
    }
}
