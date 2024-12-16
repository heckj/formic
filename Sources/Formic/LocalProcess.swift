import Dependencies
import Foundation

/// A command to run on a local or remote host.
///
/// Use ``run(host:)`` to invoke the command. The system forks a process and collects the output, both `STDOUT` and `STDERR`, when it finishes.
///
/// The combination is returned as ``CommandOutput``, wrapped into ``CommandExecutionResult`` after retry
/// and timeout logic is processed to provide a result for a ``Playbook``.
public struct LocalProcess: Sendable, Identifiable {
    /// The command and arguments to run.
    public let args: [String]
    /// Environment variables the system sets when it runs the command.
    public let env: [String: String]?
    public let ignoreFailure: Bool
    public let retry: RetrySetting
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
        retry: RetrySetting, executionTimeout: Duration
    ) {
        self.args = args
        self.env = env
        self.commandType = commandType
        self.retry = retry
        self.ignoreFailure = ignoreFailure
        self.executionTimeout = executionTimeout
        id = UUID()
    }

    /// Creates a new command declaration that runs a shell command.
    /// - Parameters:
    ///   - args: the command and arguments to run.
    ///   - env: An optional dictionary of environment variables the system sets when it runs the command.
    ///   - ignoreFailure: A Boolean value that indicates whether a failing command should fail a playbook.
    ///   - retry: The retry settings for the command.
    ///   - timeout: The maximum duration to allow for the command.
    /// - Returns: The command declaration.
    public static func shell(
        _ args: String..., env: [String: String]? = nil, ignoreFailure: Bool = false, retry: RetrySetting = .none,
        timeout: Duration = .seconds(30)
    ) -> LocalProcess {
        LocalProcess(
            args: args, env: env, commandType: .shell, ignoreFailure: ignoreFailure, retry: retry,
            executionTimeout: timeout)
    }

    /// Creates a new command declaration that copies a file to a remote host.
    /// - Parameters:
    ///   - from: The path of the file to copy.
    ///   - to: The path to copy the file to.
    ///   - ignoreFailure: A Boolean value that indicates whether a failing command should fail a playbook.
    ///   - retry: The retry settings for the command.
    ///   - timeout: The maximum duration to allow for the command.
    public static func remoteCopy(
        from: String, to: String, ignoreFailure: Bool = false, retry: RetrySetting = .none,
        timeout: Duration = .seconds(30)
    ) -> LocalProcess {
        LocalProcess(
            args: [from, to], env: nil, commandType: .scp, ignoreFailure: ignoreFailure, retry: retry,
            executionTimeout: timeout)
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

extension LocalProcess: Hashable {}
extension LocalProcess: Codable {}
extension LocalProcess: CustomStringConvertible {
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

extension LocalProcess: CommandProtocol {}
