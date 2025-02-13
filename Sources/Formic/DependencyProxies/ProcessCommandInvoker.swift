import Dependencies
import Foundation
import Logging

#if canImport(FoundationNetworking)  // Required for Linux
    import FoundationNetworking
#endif

struct ProcessCommandInvoker: CommandInvoker {
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
        task.executableURL = URL(fileURLWithPath: "/bin/sh")

        if let env = env {
            task.environment = env
        }

        if let chdir = chdir {
            task.currentDirectoryURL = URL(fileURLWithPath: chdir)
        }

        let cmdString = "\"\(cmd.joined(separator: " "))\""
        task.arguments = ["-c", cmdString]

        logger?.trace("RAW LOCAL COMMAND:")
        logger?.trace("/bin/sh -c \(cmdString)")

        let stdOutPipe = Pipe()
        let stdErrPipe = Pipe()
        task.standardOutput = stdOutPipe
        task.standardError = stdErrPipe

        if let stdIn = stdIn {
            task.standardInput = stdIn
        }

        try task.run()

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
        var args: [String] = ["/usr/bin/scp"]

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

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")

        if let env = env {
            task.environment = env
        }

        if let chdir = chdir {
            task.currentDirectoryURL = URL(fileURLWithPath: chdir)
        }

        var args: [String] = []

        args.append("-c")

        var sshCmdAssembly: String = "ssh"

        //        sshCmdAssembly.append(" -o")
        //        sshCmdAssembly.append(" BatchMode=yes")
        sshCmdAssembly.append(" -o")
        sshCmdAssembly.append(" StrictHostKeyChecking=\(strictHostKeyChecking ? "yes" : "no")")
        sshCmdAssembly.append(" -o")
        sshCmdAssembly.append(" UpdateHostKeys=\(strictHostKeyChecking ? "yes" : "no")")

        if let identityFile {
            sshCmdAssembly.append(" -i")
            sshCmdAssembly.append(" \(identityFile)")
        }
        if let port {
            sshCmdAssembly.append(" -p")
            sshCmdAssembly.append(" \(port)")
        }

        // assert/request no TTY needed: -T
        // request a pseudo tty: -t
        // sshCmdAssembly.append(" -t")

        // refs:
        // https://stackoverflow.com/questions/7085429/terminating-ssh-session-executed-by-bash-script
        // https://stackoverflow.com/questions/7114990/pseudo-terminal-will-not-be-allocated-because-stdin-is-not-a-terminal
        // https://www.baeldung.com/linux/ssh-pseudo-terminal-allocation

        sshCmdAssembly.append(" \(user)@\(host)")

        var remoteCmdString = ""
        // first change directory, if applied
        if let chdir = chdir {
            remoteCmdString.append("cd \(chdir);")
        }
        // set up any set ENV variables PRIOR to command
        if let env = env {
            for (key, value) in env {
                remoteCmdString.append("\(key)=\(value) ")
            }
        }
        // and the command
        remoteCmdString.append("\(cmd)")
        // Apply this as a single string argument to pass down
        sshCmdAssembly.append(" '\(remoteCmdString)'")

        args.append(sshCmdAssembly)
        task.arguments = args

        logger?.trace("RAW LOCAL COMMAND:")
        logger?.trace("\(String(describing: args))")
        let combined = args.joined(separator: " ")
        logger?.trace("\(combined)")

        let stdOutPipe = Pipe()
        let stdErrPipe = Pipe()
        task.standardOutput = stdOutPipe
        task.standardError = stdErrPipe

        try task.run()

        // appears to be hang location for https://github.com/heckj/formic/issues/76
        task.waitUntilExit()

        let stdOutData = try stdOutPipe.fileHandleForReading.readToEnd()
        let stdErrData = try stdErrPipe.fileHandleForReading.readToEnd()

        return CommandOutput(returnCode: task.terminationStatus, stdOut: stdOutData, stdErr: stdErrData)

        // NOTE(heckj): Ansible's SSH capability
        // (https://github.com/ansible/ansible/blob/devel/lib/ansible/plugins/connection/ssh.py)
        // does this with significantly more finesse. It checks the output as it's returned and
        // provides a password through that uses sshpass to authenticate, or escalates commands
        // with sudo and a password, before the core command is invoked.
    }
}
