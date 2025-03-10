import Dependencies
import Foundation
import Logging

/// A command to transfer a file from a remote URL into the host.
///
/// This command requests the contents of the URL, storing it temporarily on the local file system, before sending it to the host.
/// Once the file is received locally, it is sent to the remote host using scp through a local shell.
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
    ///   - into: The destination path on the remote host.
    ///   - from: The URL from which to copy the file.
    ///   - env: An optional dictionary of environment variables the system sets when the engine runs the the command.
    ///   - ignoreFailure: A Boolean value that indicates whether a failing command should fail a playbook.
    ///   - retry: The retry settings for the command.
    ///   - executionTimeout: The maximum duration to allow for the command.
    public init(
        into: String, from: URL, env: [String: String]? = nil, ignoreFailure: Bool = false,
        retry: Backoff = .never, executionTimeout: Duration = .seconds(30)
    ) {
        self.from = from
        self.env = env
        self.destinationPath = into
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
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(from.lastPathComponent)
        do {
            let data = try await invoker.getDataAtURL(url: from, logger: logger)
            try data.write(to: tempFile)
        } catch {
            return CommandOutput(
                returnCode: -1, stdOut: nil, stdErr: "Unable to retrieve file: \(error)".data(using: .utf8))
        }
        let sshCreds = host.sshAccessCredentials
        let targetHostName = host.networkAddress.dnsName ?? host.networkAddress.address.description
        return try await invoker.remoteCopy(
            host: targetHostName,
            user: sshCreds.username,
            identityFile: sshCreds.identityFile,
            port: host.sshPort,
            strictHostKeyChecking: false,
            localPath: tempFile.path,
            remotePath: destinationPath,
            logger: logger)
    }
}

extension CopyFrom: CustomStringConvertible {
    /// A textual representation of the command.
    public var description: String {
        return "scp \(from.absoluteURL) to remote host:\(destinationPath)"
    }
}
