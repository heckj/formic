import Dependencies
import Foundation

/// A command to transfer a file from a remote URL into the host.
///
/// This command requests the contents of the URL from where the playbook is executing.
/// Once received, it transfers the file to the remote host using scp through a local shell.
public struct CopyFrom: Command {
    /// The URL from which to copy the file.
    public let from: URL
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
    ///   - location: The destination path on the remote host.
    ///   - from: The URL from which to copy the file.
    ///   - env: An optional dictionary of environment variables the system sets when the engine runs the the command.
    ///   - ignoreFailure: A Boolean value that indicates whether a failing command should fail a playbook.
    ///   - retry: The retry settings for the command.
    ///   - executionTimeout: The maximum duration to allow for the command.
    public init(
        location: String, from: URL, env: [String: String]? = nil, ignoreFailure: Bool = false,
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
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(from.lastPathComponent)
        do {
            let data = try await invoker.getDataAtURL(url: from)
            try data.write(to: tempFile)
        } catch {
            return CommandOutput(
                returnCode: -1, stdOut: nil, stdErr: "Unable to retrieve file: \(error)".data(using: .utf8))
        }
        if host.remote {
            let sshCreds = host.sshAccessCredentials
            let targetHostName = host.networkAddress.dnsName ?? host.networkAddress.address.description
            return try await invoker.remoteCopy(
                host: targetHostName,
                user: sshCreds.username,
                identityFile: sshCreds.identityFile,
                port: host.sshPort,
                strictHostKeyChecking: false,
                localPath: tempFile.path,
                remotePath: destinationPath)
        } else {
            return try await invoker.localShell(cmd: ["cp", tempFile.path, destinationPath], stdIn: nil, env: nil)
        }
    }
}

extension CopyFrom: CustomStringConvertible {
    /// A textual representation of the command.
    public var description: String {
        return "scp \(from.absoluteURL) to remote host:\(destinationPath)"
    }
}
