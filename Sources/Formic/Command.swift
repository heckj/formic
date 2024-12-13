import Dependencies
import Foundation

/// A command to run on a local or remote host.
///
/// Use ``run(host:)`` to invoke the command. The system forks a process and collects the output, both `STDOUT` and `STDERR`, when it finishes.
/// The combination is returned as ``CommandOutput``.
public struct Command: Sendable, Identifiable {
    /// The command and arguments to run.
    public let args: [String]
    /// Environment variables the system sets when it runs the command.
    public let env: [String: String]?
    public let ignoreFailure: Bool
    public let retryOnFailure: Bool
    public let backoff: Backoff
    public let executionTimeout: Duration
    public let id: UUID

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

    private init(
        args: [String], env: [String: String]?, commandType: CommandType, ignoreFailure: Bool,
        retryOnFailure: Bool, backoff: Backoff, executionTimeout: Duration
    ) {
        self.args = args
        self.env = env
        self.commandType = commandType
        self.retryOnFailure = retryOnFailure
        self.ignoreFailure = ignoreFailure
        self.backoff = backoff
        self.executionTimeout = executionTimeout
        id = UUID()
    }

    /// Creates a new command declaration that runs a shell command.
    /// - Parameters:
    ///   - args: the command and arguments to run.
    ///   - env: An optional dictionary of environment variables the system sets when it runs the command.
    ///   - ignoreFailure: A Boolean value that indicates whether a failing command should fail a playbook.
    ///   - retryOnFailure: A Boolean value that indicates whether the system should retry a failed command.
    ///   - backoff: The strategy used to delay when retrying a failed command.
    /// - Returns: The command declaration.
    public static func shell(
        _ args: String..., env: [String: String]? = nil, ignoreFailure: Bool = false, retryOnFailure: Bool = false,
        backoff: Backoff = .default, timeout: Duration = .seconds(30)
    ) -> Command {
        Command(
            args: args, env: env, commandType: .shell, ignoreFailure: ignoreFailure, retryOnFailure: retryOnFailure,
            backoff: backoff, executionTimeout: timeout)
    }

    /// Creates a new command declaration that copies a file to a remote host.
    /// - Parameters:
    ///   - from: The path of the file to copy.
    ///   - to: The path to copy the file to.
    ///   - ignoreFailure: A Boolean value that indicates whether a failing command should fail a playbook.
    ///   - retryOnFailure: A Boolean value that indicates whether the system should retry a failed command.
    ///   - backoff: The strategy used to delay when retrying a failed command.
    public static func remoteCopy(
        from: String, to: String, ignoreFailure: Bool = false, retryOnFailure: Bool = false,
        backoff: Backoff = .default, timeout: Duration = .seconds(30)
    ) -> Command {
        Command(
            args: [from, to], env: nil, commandType: .scp, ignoreFailure: ignoreFailure, retryOnFailure: retryOnFailure,
            backoff: backoff, executionTimeout: timeout)
    }

    /// Runs the command on the host you provide.
    /// - Parameter host: The host on which to run the command.
    /// - Returns: The command output.
    @discardableResult
    public func run(host: Host) async throws -> CommandOutput {
        @Dependency(\.commandInvoker) var invoker: any CommandInvoker
        switch commandType {
        case .scp:
            if host.remote {
                let sshCreds = host.sshAccessCredentials
                let targetHostName = host.networkAddress.dnsName ?? host.networkAddress.address.description
                if args.count != 2 {
                    throw CommandError.invalidCommand(msg: "SCP requires a single 'from' and 'to' path as arguments.")
                }
                return try await invoker.remoteCopy(
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
                return try await invoker.remoteShell(
                    host: targetHostName,
                    user: sshCreds.username,
                    identityFile: sshCreds.identityFile,
                    port: host.sshPort,
                    strictHostKeyChecking: false,
                    cmd: args,
                    env: env)
            } else {
                return try await invoker.localShell(cmd: args, stdIn: nil, env: env)
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
