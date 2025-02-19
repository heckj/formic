import Citadel
import Crypto  // for loading a private key to use with Citadel for authentication
import Dependencies
import Foundation
import Logging
import NIOCore  // to interact with ByteBuffer - otherwise it's opaquely buried in Citadel's API response

#if canImport(FoundationNetworking)  // Required for Linux
    import FoundationNetworking
#endif

/// A command to run on a remote host.
///
/// This (experimental) command uses the Citadel SSH library to connect to a remote host and invoke a command on it.
/// Do not use shell control or redirect operators in the command string.
public struct SSHCommand: Command {
    /// The command and arguments to run.
    public let commandString: String
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

    /// Creates a new command declaration that the engine runs as a shell command.
    /// - Parameters:
    ///   - argString: the command and arguments to run as a single string separated by spaces.
    ///   - env: An optional dictionary of environment variables the system sets when it runs the command.
    ///   - chdir: An optional directory to change to before running the command.
    ///   - ignoreFailure: A Boolean value that indicates whether a failing command should fail a playbook.
    ///   - retry: The retry settings for the command.
    ///   - executionTimeout: The maximum duration to allow for the command.
    public init(
        _ argString: String, env: [String: String]? = nil, chdir: String? = nil,
        ignoreFailure: Bool = false,
        retry: Backoff = .never, executionTimeout: Duration = .seconds(120)
    ) {
        self.commandString = argString
        self.env = env
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

        let sshCreds = host.sshAccessCredentials
        let targetHostName = host.networkAddress.dnsName ?? host.networkAddress.address.description
        return try await self.remoteCommand(
            host: targetHostName,
            user: sshCreds.username,
            identityFile: sshCreds.identityFile,
            port: host.sshPort,
            strictHostKeyChecking: host.strictHostKeyChecking,
            cmd: commandString,
            env: env,
            logger: logger
        )
    }

    // IMPLEMENTATION NOTE(heckj):
    // This is a more direct usage of Citadel SSHClient, not abstracted through a protocol (such as
    // CommandInvoker) in order to just "try it out". This means it's not really amenable to use
    // and test in api's which use this functionality to make requests and get data.

    // Citadel *also* supports setting up a connecting _once_, and then executing multiple commands,
    // which wasn't something you could do with forking commands through Process. I'm not trying to
    // take advantage of that capability here.

    // Finally, Citadel is particular about the KIND of key you're using - and this iteration is only
    // written to handle Ed25519 keys. To make this "real", we'd want to work in how to support RSA
    // and DSA keys for SSH authentication as well. Maybe even password authentication.

    /// Invoke a command using SSH on a remote host.
    ///
    /// - Parameters:
    ///   - host: The remote host to connect to and call the shell command.
    ///   - user: The user on the remote host to connect as
    ///   - identityFile: The string path to an SSH identity file.
    ///   - port: The port to use for SSH to the remote host.
    ///   - strictHostKeyChecking: A Boolean value that indicates whether to enable strict host checking, defaults to `false`.
    ///   - cmd: A list of strings that make up the command and any arguments.
    ///   - env: A dictionary of shell environment variables to apply.
    ///   - debugPrint: A Boolean value that indicates if the invoker prints the raw command before running it.
    /// - Returns: the command output.
    /// - Throws: any errors from invoking the shell process, or errors attempting to connect.
    func remoteCommand(
        host: String,
        user: String,
        identityFile: String? = nil,
        port: Int? = nil,
        strictHostKeyChecking: Bool = false,
        cmd: String,
        env: [String: String]? = nil,
        logger: Logger?
    ) async throws -> CommandOutput {

        guard let identityFile = identityFile else {
            throw CommandError.noOutputToParse(msg: "No identity file provided for SSH connection")
        }

        let urlForData = URL(fileURLWithPath: identityFile)
        let dataFromURL = try Data(contentsOf: urlForData)  // 411 bytes

        let client = try await SSHClient.connect(
            host: host,
            authenticationMethod: .ed25519(username: "docker-user", privateKey: .init(sshEd25519: dataFromURL)),
            hostKeyValidator: .acceptAnything(),
            // ^ Please use another validator if at all possible, this is insecure
            reconnect: .never
        )

        var stdoutData: Data = Data()
        var stderrData: Data = Data()

        do {
            let streams = try await client.executeCommandStream(cmd, inShell: true)

            for try await event in streams {
                switch event {
                case .stdout(let stdout):
                    stdoutData.append(Data(buffer: stdout))
                case .stderr(let stderr):
                    stderrData.append(Data(buffer: stderr))
                }
            }

            // Citadel API appears to provide a return code on failure, but not on success.

            let results: CommandOutput = CommandOutput(returnCode: 0, stdOut: stdoutData, stdErr: stderrData)
            return results
        } catch let error as SSHClient.CommandFailed {
            // Have to catch the exceptions thrown by executeCommandStream to get the return code,
            // in the event of a command failure.
            let results: CommandOutput = CommandOutput(
                returnCode: Int32(error.exitCode), stdOut: stdoutData, stdErr: stderrData)
            return results
        } catch {
            throw error
        }

    }
}

extension SSHCommand: CustomStringConvertible {
    /// A textual representation of the command.
    public var description: String {
        return commandString
    }
}
