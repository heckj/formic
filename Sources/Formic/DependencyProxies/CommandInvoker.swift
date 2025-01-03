import Dependencies
import Foundation

#if canImport(FoundationNetworking)  // Required for Linux
    import FoundationNetworking
#endif

// IMPLEMENTATION NOTES:
// With this structure, everything is synchronous - which makes some of the higher level
// structuring easier. But it also means that you don't see any output _while_ it's happening.
// It's possible we might be able to stream if we switch to one the Async oriented shell
// libraries, that stream/flow data from the Pipes as it appears, but in terms of the
// functional logic of this - it's more relevant to see what the output is when it's complete
// than the see the internals as it flows. It *looks* a lot nicer - gives a feeling of
// progress that's really great - but isn't strictly needed for the core functionality.
//
// Two options for async shell command execution:
//
// - https://github.com/GeorgeLyon/Shwift
// Shwift has clearly been around the block, but has heavier dependencies (all of SwiftNIO) that
// make it a heavier take.
//
// - https://github.com/Zollerboy1/SwiftCommand
// I like the structure of SwiftCommand, but it has a few swift6 concurrency warnings about fiddling
// with mutable buffers that are slightly concerning to me. There also doesn't appear to
// be a convenient way to capture STDERR separately (it's mixed together).

// Dependency injection docs:
// https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies

protocol CommandInvoker: Sendable {
    func remoteShell(
        host: String,
        user: String,
        identityFile: String?,
        port: Int?,
        strictHostKeyChecking: Bool,
        chdir: String?,
        cmd: String,
        env: [String: String]?,
        debugPrint: Bool
    ) async throws -> CommandOutput

    func remoteCopy(
        host: String,
        user: String,
        identityFile: String?,
        port: Int?,
        strictHostKeyChecking: Bool,
        localPath: String,
        remotePath: String
    ) async throws -> CommandOutput

    func getDataAtURL(url: URL) async throws -> Data

    func localShell(
        cmd: [String],
        stdIn: Pipe?,
        env: [String: String]?,
        chdir: String?,
        debugPrint: Bool
    ) async throws -> CommandOutput
}

// registers the dependency

private enum CommandInvokerKey: DependencyKey {
    static let liveValue: any CommandInvoker = ProcessCommandInvoker()
}

// adds a dependencyValue for convenient access

extension DependencyValues {
    var commandInvoker: CommandInvoker {
        get { self[CommandInvokerKey.self] }
        set { self[CommandInvokerKey.self] = newValue }
    }
}

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
        cmd: [String], stdIn: Pipe? = nil, env: [String: String]? = nil, chdir: String? = nil, debugPrint: Bool = false
    ) async throws -> CommandOutput {
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

        if let chdir = chdir {
            task.currentDirectoryURL = URL(fileURLWithPath: chdir)
        }
        task.arguments = cmd

        if debugPrint {
            print(task.arguments?.joined(separator: " ") ?? "nil")
        }

        let stdOutPipe = Pipe()
        let stdErrPipe = Pipe()
        task.standardOutput = stdOutPipe
        task.standardError = stdErrPipe

        if let stdIn = stdIn {
            task.standardInput = stdIn
        }

        try task.run()

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

    func getDataAtURL(url: URL) async throws -> Data {
        let ephemeral = URLSession(configuration: .ephemeral)
        let request = URLRequest(url: url)
        let (data, response) = try await ephemeral.data(for: request)
        guard let httpResponse: HTTPURLResponse = response as? HTTPURLResponse else {
            throw CommandError.noOutputToParse(
                msg: "Unable to parse response from \(url): \(response.debugDescription)")
        }
        if data.isEmpty {
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
        remotePath: String
    ) async throws -> CommandOutput {
        var args: [String] = ["scp"]

        if strictHostKeyChecking {
            args.append("-o")
            args.append("StrictHostKeyChecking=no")
        }
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
        let rcAndPipe = try await localShell(cmd: args)
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
        debugPrint: Bool = false
    ) async throws -> CommandOutput {
        var args: [String] = ["ssh"]
        if strictHostKeyChecking {
            args.append("-o")
            args.append("StrictHostKeyChecking=no")
        }
        if let identityFile {
            args.append("-i")
            args.append("\(identityFile)")
        }
        if let port {
            args.append("-p")
            args.append("\(port)")
        }
        args.append("-t")
        // request a TTY from the remote host - // notably reports connections closed on STDERR
        args.append("\(user)@\(host)")

        var cmdString = ""
        // first change directory, if applied
        if let chdir = chdir {
            cmdString.append("cd \(chdir);")
        }
        // set up any set ENV variables PRIOR to command
        if let env = env {
            for (key, value) in env {
                cmdString.append("\(key)=\(value) ")
            }
        }
        // and the command
        cmdString.append("\(cmd)")
        // Apply this as a single string argument to pass down
        args.append(cmdString)

        // NOTE(heckj): Ansible's SSH capability
        // (https://github.com/ansible/ansible/blob/devel/lib/ansible/plugins/connection/ssh.py)
        // does this with significantly more finesse. It checks the output as it's returned and
        // provides a password through that uses sshpass to authenticate, or escalates commands
        // with sudo and a password, before the core command is invoked.
        let rcAndPipe = try await localShell(cmd: args, env: nil, debugPrint: debugPrint)
        return rcAndPipe
    }
}
