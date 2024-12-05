//#if canImport(FoundationEssentials)
//import FoundationEssentials
//#else
import Foundation

//#endif

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Represents the output of a shell command.
public struct CommandOutput: Sendable {
    public let returnCode: Int32
    public let stdOut: Data?
    public let stdErr: Data?

    public var stdoutString: String? {
        guard let stdOut else {
            return nil
        }
        return String(data: stdOut, encoding: String.Encoding.utf8)
    }

    public var stderrString: String? {
        guard let stdErr else {
            return nil
        }
        return String(data: stdErr, encoding: String.Encoding.utf8)
    }

    init(returnCode: Int32, stdOut: Data?, stdErr: Data?) {
        self.returnCode = returnCode
        self.stdOut = stdOut
        self.stdErr = stdErr
    }
}

// For concurrency support, there are two projects that already have a nice run at this same space:
// - https://github.com/GeorgeLyon/Shwift
// Shwift has clearly been around the block, but it has heavier dependencies (all of SwiftNIO) that
// make it a heavier take.

// - https://github.com/Zollerboy1/SwiftCommand
// I like the structure of SwiftCommand, but it has a few swift6 concurrency warnings about fiddling
// with mutable buffers that are _just_ slightly concerning to me. There also doesn't appear to be a convenient
// way to capture STDERR separately (it's mixed together).

/// A type that represents a command to invoke on a local or remote host.
public struct Command {
    /// Invoke a local command.
    ///
    /// - Parameters:
    ///   - args: A list of strings that make up the command and any arguments.
    ///   - returnStdOut: A Boolean value that indicates whether to return data from `STDOUT`.
    ///   - stdIn: An option pipe to provide `STDIN`.
    ///   - env: A dictionary of shell environment variables to apply.
    /// - Returns: The command output.
    /// - Throws: any errors from invoking the shell process.
    @discardableResult
    public static func localShell(
        _ args: [String], returnStdOut: Bool = false, returnStdErr: Bool = false, stdIn: Pipe? = nil,
        env: [String: String]? = nil
    ) throws -> CommandOutput {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")

        if var env = env {
            // if the environment is passed in, and an explicit bit is set, then don't override it
            if env["TERM"] == nil {
                // otherwise set `TERM=dumb` to hint to CLI tooling that console characters aren't useful
                // in this context.
                env["TERM"] = "dumb"
            }
            task.environment = env
        } else {
            task.environment = ["TERM": "dumb"]
        }

        task.arguments = args

        let stdOutPipe = Pipe()
        let stdErrPipe = Pipe()

        if returnStdOut {
            task.standardOutput = stdOutPipe
        } else {
            task.standardOutput = FileHandle.nullDevice
        }

        if returnStdErr {
            task.standardError = stdErrPipe
        } else {
            task.standardError = FileHandle.nullDevice
        }

        if let stdIn = stdIn {
            task.standardInput = stdIn
        }

        try task.run()

        // Attach this process to our process group so that Ctrl-C and other signals work
        let pgid = tcgetpgrp(STDOUT_FILENO)
        if pgid != -1 {
            tcsetpgrp(STDOUT_FILENO, task.processIdentifier)
        }

        task.waitUntilExit()

        let stdOutData = try stdOutPipe.fileHandleForReading.readToEnd()
        let stdErrData = try stdErrPipe.fileHandleForReading.readToEnd()

        return CommandOutput(returnCode: task.terminationStatus, stdOut: stdOutData, stdErr: stdErrData)
    }

    @discardableResult
    public static func localShell(
        _ args: String, returnStdOut: Bool = false, returnStdErr: Bool = false, stdIn: Pipe? = nil,
        env: [String: String]? = nil
    ) throws -> CommandOutput {
        try self.localShell([args], returnStdOut: returnStdOut, returnStdErr: returnStdErr, stdIn: stdIn, env: env)
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
    /// - Returns: the command output.
    /// - Throws: any errors from invoking the shell process.
    public static func remoteShell(
        host: String,
        user: String,
        identityFile: String? = nil,
        port: Int? = nil,
        strictHostKeyChecking: Bool = false,
        cmd: [String]
    ) throws -> CommandOutput {
        var args: [String] = ["ssh"]
        if strictHostKeyChecking {
            args.append("-o")
            args.append("StrictHostKeyChecking=no")
        }
        if let identityFile {
            args.append("-i")
            args.append(identityFile)
        }
        if let port {
            args.append("-p")
            args.append("\(port)")
        }
        args.append("-t")  // request a TTY at the remote host
        args.append("\(user)@\(host)")

        args.append(contentsOf: cmd)

        // NOTE(heckj): Ansible's SSH capability
        // (https://github.com/ansible/ansible/blob/devel/lib/ansible/plugins/connection/ssh.py)
        // does this with significantly more finness, checking the output as it's returned and providing a pass
        // to use sshpass to authenticate, or to escalate commands with sudo and a password, before the core
        // command is invoked.
        let rcAndPipe = try localShell(args, returnStdOut: true, returnStdErr: true)
        return rcAndPipe
    }

    public static func remoteShell(host: Host, cmd: [String]) throws -> CommandOutput {
        let sshCreds = host.sshAccessCredentials
        let targetHostName = host.networkAddress.dnsName ?? host.networkAddress.address.description
        return try self.remoteShell(
            host: targetHostName, user: sshCreds.username, identityFile: sshCreds.identityFile, port: host.sshPort,
            cmd: cmd)
    }
}
