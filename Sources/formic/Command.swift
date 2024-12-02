//#if canImport(FoundationEssentials)
//import FoundationEssentials
//#else
import Foundation

//#endif

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// A type that represents a command to invoke on a local or remote host.
public struct Command {
    /// Invoke a local command.
    ///
    /// - Parameters:
    ///   - args: A list of strings that make up the command and any arguments.
    ///   - returnStdOut: A Boolean value that indicates whether to return data from `STDOUT`.
    ///   - stdIn: An option pipe to provide `STDIN`.
    ///   - env: A dictionary of shell environment variables to apply.
    /// - Returns: A tuple of (returnCode, Pipe)
    /// - Throws: any errors from invoking the shell process.
    ///
    /// The returned Pipe is a file handle the pipe used when you opt to capture `STDOUT`.
    /// Use Pipe.string() to read the pipe and provide the output as an optional String parsed as `UTF-8`.
    @discardableResult
    public static func shell(
        _ args: [String], returnStdOut: Bool = false, stdIn: Pipe? = nil, env: [String: String]? = nil
    ) throws -> (Int32, Pipe) {
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

        let pipe = Pipe()

        if returnStdOut {
            task.standardOutput = pipe
        } else {
            task.standardOutput = FileHandle.nullDevice
        }

        if let stdIn = stdIn {
            task.standardInput = stdIn
        } else {
            task.standardOutput = FileHandle.nullDevice
        }

        try task.run()

        // Attach this process to our process group so that Ctrl-C and other signals work
        let pgid = tcgetpgrp(STDOUT_FILENO)
        if pgid != -1 {
            tcsetpgrp(STDOUT_FILENO, task.processIdentifier)
        }

        task.waitUntilExit()
        return (task.terminationStatus, pipe)
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
    /// - Returns: A tuple of (returnCode, Pipe)
    /// - Throws: any errors from invoking the shell process.
    ///
    /// The returned Pipe is a file handle the pipe used when you opt to capture `STDOUT`.
    /// Use Pipe.string() to read the pipe and provide the output as an optional String parsed as `UTF-8`.

    public static func remoteShell(
        host: String,
        user: String,
        identityFile: String? = nil,
        port: Int? = nil,
        strictHostKeyChecking: Bool = false,
        cmd: [String]
    ) async throws -> (Int32, String?) {
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
        let x = try shell(args, returnStdOut: true)
        return (x.0, x.1.string())
    }
}
