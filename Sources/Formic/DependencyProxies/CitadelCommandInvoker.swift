import Citadel
import CryptoKit  // for loading a private key to use with Citadel for authentication
import Dependencies
import Foundation
import Logging
import NIOCore  // to interact with ByteBuffer - otherwise it's opaquely buried in Citadel's API response

#if canImport(FoundationNetworking)  // Required for Linux
    import FoundationNetworking
#endif

struct CitadelCommandInvoker: CommandInvoker {
    /// Invoke a local command.
    ///
    /// - Parameters:
    ///   - args: A list of strings that make up the command and any arguments.
    ///   - stdIn: An optional Pipe to provide `STDIN`.
    ///   - env: A dictionary of shell environment variables to apply.
    ///   - cmd: The command to invoke, as a list of strings
    ///   - debugPrint: A Boolean value that indicates if the invoker prints the raw command before running it.
    ///   - chdir: An optional directory to change to before running the command.
    /// - Returns: The command output.
    /// - Throws: any errors from invoking the shell process.
    ///
    /// Errors exposed source from [Process.run()](https://developer.apple.com/documentation/foundation/process/2890105-run),
    /// followed by attempting to read the Pipe() outputs (fileHandleForReading.readToEnd()).
    /// The types of errors thrown from those locations aren't undocumented.
    func localShell(
        cmd: [String], stdIn: Pipe? = nil, env: [String: String]? = nil, chdir: String? = nil, logger: Logger? = nil
    ) async throws -> CommandOutput {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")

        if let env = env {
            task.environment = env
        }

        if let chdir = chdir {
            task.currentDirectoryURL = URL(fileURLWithPath: chdir)
        }
        task.arguments = cmd

        let stdOutPipe = Pipe()
        let stdErrPipe = Pipe()
        task.standardOutput = stdOutPipe
        task.standardError = stdErrPipe

        if let stdIn = stdIn {
            task.standardInput = stdIn
        }

        try task.run()

        // *NOTE*: this doesn't seem to be propagating the termination signals when shelling down
        // and invoking `ssh` locally...
        // Attach this process to our process group so that Ctrl-C and other signals work
        let pgid = tcgetpgrp(STDOUT_FILENO)
        if pgid != -1 {
            tcsetpgrp(STDOUT_FILENO, task.processIdentifier)
        }

        // appears to be hang location for https://github.com/heckj/formic/issues/76
        task.waitUntilExit()

        let stdOutData = try stdOutPipe.fileHandleForReading.readToEnd()
        let stdErrData = try stdErrPipe.fileHandleForReading.readToEnd()

        return CommandOutput(returnCode: task.terminationStatus, stdOut: stdOutData, stdErr: stdErrData)
    }

    func getDataAtURL(url: URL, logger: Logger?) async throws -> Data {
        let ephemeral = URLSession(configuration: .ephemeral)
        let request = URLRequest(url: url)
        let (data, response) = try await ephemeral.data(for: request)
        guard let httpResponse: HTTPURLResponse = response as? HTTPURLResponse else {
            logger?.warning("Unable to parse response from \(url): \(response.debugDescription)")
            throw CommandError.noOutputToParse(
                msg: "Unable to parse response from \(url): \(response.debugDescription)")
        }
        if data.isEmpty {
            logger?.warning("No data returned from \(url): \(httpResponse.debugDescription)")
            throw CommandError.noOutputToParse(msg: "No data returned from \(url): \(httpResponse.debugDescription)")
        } else {
            return data
        }
    }

    func remoteCopy(
        host: String,
        user: String,
        identityFile: String? = nil,
        port: Int? = nil,
        strictHostKeyChecking: Bool = false,
        localPath: String,
        remotePath: String,
        logger: Logger?
    ) async throws -> CommandOutput {

        // CODE FROM PROCESS - NOT YET CONVERTED TO USE CITADEL BITS...

        var args: [String] = ["scp"]

        args.append("-o")
        args.append("BatchMode=yes")
        args.append("-o")
        args.append("StrictHostKeyChecking=\(strictHostKeyChecking ? "yes" : "no")")
        args.append("-o")
        args.append("UpdateHostKeys=\(strictHostKeyChecking ? "yes" : "no")")

        if let identityFile {
            args.append("-i")
            args.append(identityFile)
        }
        if let port {
            args.append("-P")  // yes, it's supposed to be capital `P` for scp
            args.append("\(port)")
        }

        args.append(localPath)
        args.append("\(user)@\(host):\(remotePath)")

        // loose form:
        // scp -o StrictHostKeyChecking=no get-docker.sh "docker-user@${IP_ADDRESS}:get-docker.sh"
        let rcAndPipe = try await localShell(cmd: args, logger: logger)
        return rcAndPipe
    }

    /// Invoke a command over SSH on a remote host.
    ///
    /// - Parameters:
    ///   - host: The remote host to connect to and call the shell command.
    ///   - user: The user on the remote host to connect as
    ///   - identityFile: The string path to an SSH identity file.
    ///   - port: The port to use for SSH to the remote host.
    ///   - strictHostKeyChecking: A Boolean value that indicates whether to enable strict host checking, defaults to `false`.
    ///   - cmd: A list of strings that make up the command and any arguments.
    ///   - chdir: An optional directory to change to before running the command.
    ///   - env: A dictionary of shell environment variables to apply.
    ///   - debugPrint: A Boolean value that indicates if the invoker prints the raw command before running it.
    /// - Returns: the command output.
    /// - Throws: any errors from invoking the shell process.
    func remoteShell(
        host: String,
        user: String,
        identityFile: String? = nil,
        port: Int? = nil,
        strictHostKeyChecking: Bool = false,
        chdir: String?,
        cmd: String,
        env: [String: String]? = nil,
        logger: Logger?
    ) async throws -> CommandOutput {

        guard let identityFile = identityFile else {
            throw CommandError.noOutputToParse(msg: "No identity file provided for SSH connection")
        }

        let urlForData = URL(fileURLWithPath: identityFile)
        let dataFromURL = try Data(contentsOf: urlForData)  // 411 bytes
        let key: Curve25519.Signing.PrivateKey = try Curve25519.Signing.PrivateKey(sshEd25519: dataFromURL)

        let client = try await SSHClient.connect(
            host: host,
            authenticationMethod: .ed25519(username: "docker-user", privateKey: key),
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
            // Citadel API appears to provide a return code on failure, but not on success -
            // and through the process of throwing an exception while reading the above streams.

            let results: CommandOutput = CommandOutput(returnCode: 0, stdOut: stdoutData, stdErr: stderrData)
            return results
        } catch let error as SSHClient.CommandFailed {
            let results: CommandOutput = CommandOutput(
                returnCode: Int32(error.exitCode), stdOut: stdoutData, stdErr: stderrData)
            return results
        } catch {
            throw error
        }

    }
}
