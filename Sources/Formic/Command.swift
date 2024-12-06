import Dependencies
import Foundation

/// A command to run on a local or remote host.
///
/// When you invoke a command, use ``run(host:)`` or ``run(host:args:)``, a process is forked locally
/// and the output, both `STDOUT` and `STDERR` collected when the process is finished. The combination
/// is returned as ``CommandOutput``.
public struct Command {
    /// The command and arguments to run.
    public let args: [String]
    /// Environment variables the system sets when it runs the command.
    public let env: [String: String]?

    /// Creates a new command declaration.
    /// - Parameter args: the command and arguments to run.
    /// - Parameter env: An optional dictionary of environment variables the system sets when it runs the command.
    public init(_ args: String..., env: [String: String]? = nil) {
        self.args = args
        self.env = env
    }

    /// Runs the command on the host you provide.
    /// - Parameter host: The host on which to run the command.
    /// - Returns: The command output.
    @discardableResult
    public func run(host: Host) throws -> CommandOutput {
        try Command.run(host: host, args: args)
    }

    /// Runs the command on the host you provide.
    /// - Parameters:
    ///   - host: The host on which to run the command.
    ///   - args: The command and arguments.
    /// - Returns: The command output.
    @discardableResult
    public static func run(host: Host, args: [String], env: [String: String]? = nil) throws -> CommandOutput {
        @Dependency(\.commandInvoker) var invoker: any CommandInvoker

        if host.remote {
            let sshCreds = host.sshAccessCredentials
            let targetHostName = host.networkAddress.dnsName ?? host.networkAddress.address.description
            return try invoker.remoteShell(
                host: targetHostName,
                user: sshCreds.username,
                identityFile: sshCreds.identityFile,
                port: host.sshPort,
                strictHostKeyChecking: false,
                cmd: args,
                env: env)
        } else {
            return try invoker.localShell(cmd: args, stdIn: nil, env: env)
        }
    }
}

extension Command: Hashable {}
extension Command: Codable {}
