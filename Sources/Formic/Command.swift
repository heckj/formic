import Dependencies
import Foundation

/// A command to run on a local or remote host.
///
/// Use ``run(host:)`` to invoke the command. The system forks a process and collects the output, both `STDOUT` and `STDERR`, when it finishes.
/// The combination is returned as ``CommandOutput``.
public struct Command: Sendable {
    /// The command and arguments to run.
    public let args: [String]
    /// Environment variables the system sets when it runs the command.
    public let env: [String: String]?

    //TODO: add a declaration to "ignore" the RC of the command - ignoreFailure

    // I'm special-casing Command using this sort of wonky hack to keep the
    // ergonomics of types that USE Commands easier to work with. If I switch
    // this out to a protocol and use `any Command`, I loose Equatable and Codable
    // conformances, which makes maintaining a declaration from a playlist far more
    // difficult (or anything else that may need the opaque type setup)

    enum CommandType: Codable, Hashable {
        case shell
        case scp
    }
    let commandType: CommandType

    private init(args: [String], env: [String: String]?, commandType: CommandType) {
        self.args = args
        self.env = env
        self.commandType = commandType
    }

    /// Creates a new command declaration that runs a shell command.
    /// - Parameter args: the command and arguments to run.
    /// - Parameter env: An optional dictionary of environment variables the system sets when it runs the command.
    public static func shell(_ args: String..., env: [String: String]? = nil) -> Command {
        Command(args: args, env: env, commandType: .shell)
    }

    /// Creates a new command declaration that copies a file to a remote host.
    /// - Parameters:
    ///   - from: The path of the file to copy.
    ///   - to: The path to copy the file to.
    public static func remoteCopy(from: String, to: String) -> Command {
        Command(args: [from, to], env: nil, commandType: .scp)
    }

    /// Runs the command on the host you provide.
    /// - Parameter host: The host on which to run the command.
    /// - Returns: The command output.
    @discardableResult
    public func run(host: Host) throws -> CommandOutput {
        @Dependency(\.commandInvoker) var invoker: any CommandInvoker
        switch commandType {
        case .scp:
            if host.remote {
                let sshCreds = host.sshAccessCredentials
                let targetHostName = host.networkAddress.dnsName ?? host.networkAddress.address.description
                if args.count != 2 {
                    throw CommandError.invalidCommand(msg: "SCP requires a single 'from' and 'to' path as arguments.")
                }
                return try invoker.remoteCopy(
                    host: targetHostName,
                    user: sshCreds.username,
                    identityFile: sshCreds.identityFile,
                    port: host.sshPort,
                    strictHostKeyChecking: false,
                    localPath: args[0],
                    remotePath: args[1])
            } else {
                throw CommandError.invalidCommand(msg: "SCP is only supported for remote hosts")
            }
        case .shell:
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
}

extension Command: Hashable {}
extension Command: Codable {}
extension Command: CustomStringConvertible {
    /// A textual representation of the command.
    public var description: String {
        switch commandType {
        case .shell:
            return args.joined(separator: " ")
        case .scp:
            return "scp \(args[0]) to remote host:\(args[1])"
        }
    }
}
