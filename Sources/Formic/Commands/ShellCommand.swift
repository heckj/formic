import Dependencies
import Foundation

/// A command to run on a local or remote host.
///
/// This command uses SSH through a local process to invoke commands on a remote host.
/// Do not use shell control or redirect operators in the command string.
public struct ShellCommand: Command {
    /// The command and arguments to run.
    public let args: [String]
    /// An optional dictionary of environment variables the system sets when it runs the command.
    public let env: [String: String]?
    /// An optional directory to change to before running the command.
    public let chdir: String?
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
    ///   - arguments: the command and arguments to run, each argument as a separate string.
    ///   - env: An optional dictionary of environment variables the system sets when it runs the command.
    ///   - chdir: An optional directory to change to before running the command.
    ///   - ignoreFailure: A Boolean value that indicates whether a failing command should fail a playbook.
    ///   - retry: The retry settings for the command.
    ///   - executionTimeout: The maximum duration to allow for the command.
    public init(
        arguments: [String], env: [String: String]? = nil, chdir: String? = nil,
        ignoreFailure: Bool = false, retry: Backoff = .never,
        executionTimeout: Duration = .seconds(30)
    ) {
        self.args = arguments
        self.env = env
        self.retry = retry
        self.ignoreFailure = ignoreFailure
        self.executionTimeout = executionTimeout
        self.chdir = chdir
        id = UUID()
    }

    /// Creates a new command declaration that the engine runs as a shell command.
    /// - Parameters:
    ///   - argString: the command and arguments to run as a single string separated by spaces.
    ///   - env: An optional dictionary of environment variables the system sets when it runs the command.
    ///   - chdir: An optional directory to change to before running the command.
    ///   - ignoreFailure: A Boolean value that indicates whether a failing command should fail a playbook.
    ///   - retry: The retry settings for the command.
    ///   - executionTimeout: The maximum duration to allow for the command.
    ///
    /// This initializer is useful when you have a space-separated string of arguments, and splits all arguments by whitespace.
    /// If a command, or argument, requires a whitespace within it, use ``init(arguments:env:chdir:ignoreFailure:retry:executionTimeout:)`` instead.
    public init(
        _ argString: String, env: [String: String]? = nil, chdir: String? = nil,
        ignoreFailure: Bool = false,
        retry: Backoff = .never, executionTimeout: Duration = .seconds(30)
    ) {
        let splitArgs: [String] = argString.split(separator: .whitespace).map(String.init)
        self.init(
            arguments: splitArgs, env: env, chdir: chdir, ignoreFailure: ignoreFailure, retry: retry,
            executionTimeout: executionTimeout)
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
            return try await invoker.remoteShell(
                host: targetHostName,
                user: sshCreds.username,
                identityFile: sshCreds.identityFile,
                port: host.sshPort,
                strictHostKeyChecking: false,
                chdir: chdir,
                cmd: args,
                env: env,
                debugPrint: false
            )
        } else {
            return try await invoker.localShell(cmd: args, stdIn: nil, env: env, chdir: chdir, debugPrint: false)
        }
    }
}

extension ShellCommand: CustomStringConvertible {
    /// A textual representation of the command.
    public var description: String {
        return args.joined(separator: " ")
    }
}
