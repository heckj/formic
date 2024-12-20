import Dependencies
import Foundation

/// A command to transfer a file into the host.
///
/// This command uses scp through a shell on the local host to transfer the file.
public struct CopyInto: Command {
    /// The local path of the file to copy.
    public let from: String
    /// The destination path on the remote host.
    public let destinationPath: String
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

    /// Transfers a file from the host where this is run to the destination host.
    /// - Parameters:
    ///   - location: The location where the file is copied into.
    ///   - from: The location of the file to copy.
    ///   - env: An optional dictionary of environment variables the system sets when the engine runs the the command.
    ///   - ignoreFailure: A Boolean value that indicates whether a failing command should fail a playbook.
    ///   - retry: The retry settings for the command.
    ///   - executionTimeout: The maximum duration to allow for the command.
    public init(
        location: String, from: String, env: [String: String]? = nil, ignoreFailure: Bool = false,
        retry: Backoff = .none, executionTimeout: Duration = .seconds(30)
    ) {
        self.from = from
        self.env = env
        self.destinationPath = location
        self.retry = retry
        self.ignoreFailure = ignoreFailure
        self.executionTimeout = executionTimeout
        id = UUID()
    }

    /// Runs the command on the host you provide.
    /// - Parameter host: The host on which to run the command.
    /// - Returns: The command output.
    @discardableResult
    public func run(host: Host) async throws -> CommandOutput {
        @Dependency(\.commandInvoker) var invoker: any CommandInvoker
        if host.remote {
            let sshCreds = host.sshAccessCredentials
            let targetHostName = host.networkAddress.dnsName ?? host.networkAddress.address.description
            return try await invoker.remoteCopy(
                host: targetHostName,
                user: sshCreds.username,
                identityFile: sshCreds.identityFile,
                port: host.sshPort,
                strictHostKeyChecking: false,
                localPath: from,
                remotePath: destinationPath)
        } else {
            throw CommandError.invalidCommand(msg: "CopyInto is only supported for remote hosts")
        }
    }
}

extension CopyInto: CustomStringConvertible {
    /// A textual representation of the command.
    public var description: String {
        return "scp \(from) to remote host:\(destinationPath)"
    }
}
