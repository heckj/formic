import Foundation
import Testing

@testable import Formic

@Test(
    "invoking a command",
    .enabled(if: ProcessInfo.processInfo.environment.keys.contains("CI")),
    .timeLimit(.minutes(1)),
    .tags(.functionalTest))
func invokeBasicCommandLocally() async throws {
    let shellResult = try await ProcessCommandInvoker().localShell(cmd: ["uname"], stdIn: nil, env: nil)

    // print("rc: \(shellResult.returnCode)")
    // print("out: \(shellResult.stdoutString ?? "nil")")
    // print("err: \(shellResult.stderrString ?? "nil")")

    // results expected on a Linux host only
    #expect(shellResult.returnCode == 0)
    #expect(shellResult.stdoutString == "Linux\n")
    #expect(shellResult.stderrString == nil)
}

@Test(
    "invoking a command over SSH",
    .enabled(if: ProcessInfo.processInfo.environment.keys.contains("CI")),
    .timeLimit(.minutes(1)),
    .tags(.functionalTest))
func invokeBasicCommandOverSSH() async throws {

    guard
        let hostname = ProcessInfo.processInfo.environment["SSH_HOST"]
    else {
        throw CITestError.general(msg: "MISSING ENVIRONMENT VARIABLE - SSH_HOST")
    }
    guard
        let _port = ProcessInfo.processInfo.environment["SSH_PORT"],
        let port = Int(_port)
    else {
        throw CITestError.general(msg: "MISSING ENVIRONMENT VARIABLE - SSH_PORT")
    }
    guard
        let username = ProcessInfo.processInfo.environment["SSH_USERNAME"]
    else {
        throw CITestError.general(msg: "MISSING ENVIRONMENT VARIABLE - SSH_USERNAME")
    }

    guard
        let host = try Formic.Host(
            hostname, sshPort: port, sshUser: username, sshIdentityFile: nil, strictHostKeyChecking: false)
    else {
        throw CITestError.general(msg: "Failed to resolve host")
    }

    let output: CommandOutput = try await ShellCommand("uname").run(host: host, logger: nil)

    // print("rc: \(output.returnCode)")
    // print("out: \(output.stdoutString ?? "nil")")
    // print("err: \(output.stderrString ?? "nil")")

    // results expected on a Linux host only
    #expect(output.returnCode == 0)
    #expect(output.stdoutString == "Linux\n")
    #expect(output.stderrString == nil)
}

@Test(
    "invoking a local command w/ chdir",
    .enabled(if: ProcessInfo.processInfo.environment.keys.contains("INTEGRATION_ENABLED")),
    .timeLimit(.minutes(1)),
    .tags(.integrationTest))
func invokeBasicCommandLocallyWithChdir() async throws {
    let shellResult = try await ProcessCommandInvoker().localShell(cmd: ["pwd"], stdIn: nil, env: nil, chdir: "..")

    print("rc: \(shellResult.returnCode)")
    print("out: \(shellResult.stdoutString ?? "nil")")
    print("err: \(shellResult.stderrString ?? "nil")")
}

@Test(
    "invoking a remote command",
    .enabled(if: ProcessInfo.processInfo.environment.keys.contains("INTEGRATION_ENABLED")),
    .timeLimit(.minutes(1)),
    .tags(.integrationTest))
func invokeRemoteCommand() async throws {
    let shellResult = try await ProcessCommandInvoker().remoteShell(
        host: "127.0.0.1", user: "heckj", identityFile: "~/.orbstack/ssh/id_ed25519", port: 32222, chdir: nil,
        cmd: "ls -al", env: nil, logger: nil)
    print("rc: \(shellResult.returnCode)")
    print("out: \(shellResult.stdoutString ?? "nil")")
    print("err: \(shellResult.stderrString ?? "nil")")
}

@Test(
    "invoking a remote command with Env",
    .enabled(if: ProcessInfo.processInfo.environment.keys.contains("INTEGRATION_ENABLED")),
    .timeLimit(.minutes(1)),
    .tags(.integrationTest))
func invokeRemoteCommandWithEnv() async throws {
    let shellResult = try await ProcessCommandInvoker().remoteShell(
        host: "127.0.0.1", user: "heckj", identityFile: "~/.orbstack/ssh/id_ed25519", port: 32222, chdir: nil,
        cmd: "echo ${FIDDLY}", env: ["FIDDLY": "FADDLY"], logger: nil)
    print("rc: \(shellResult.returnCode)")
    print("out: \(shellResult.stdoutString ?? "nil")")
    print("err: \(shellResult.stderrString ?? "nil")")
}

@Test(
    "invoking a remote command w/ chdir",
    .enabled(if: ProcessInfo.processInfo.environment.keys.contains("INTEGRATION_ENABLED")),
    .timeLimit(.minutes(1)),
    .tags(.integrationTest))
func invokeRemoteCommandWithChdir() async throws {
    let shellResult = try await ProcessCommandInvoker().remoteShell(
        host: "127.0.0.1", user: "heckj", identityFile: "~/.orbstack/ssh/id_ed25519", port: 32222, chdir: "..",
        cmd: "ls -al", env: nil, logger: nil)
    print("rc: \(shellResult.returnCode)")
    print("out: \(shellResult.stdoutString ?? "nil")")
    print("err: \(shellResult.stderrString ?? "nil")")
}

@Test(
    "invoking a remote command w/ tilde",
    .enabled(if: ProcessInfo.processInfo.environment.keys.contains("INTEGRATION_ENABLED")),
    .timeLimit(.minutes(1)),
    .tags(.integrationTest))
func invokeRemoteCommandWithTilde() async throws {
    //    let shellResult = try await ProcessCommandInvoker().remoteShell(
    //        host: "127.0.0.1", user: "heckj", identityFile: "~/.orbstack/ssh/id_ed25519", port: 32222, chdir: "..",
    //        cmd: "mkdir ~/.ssh", env: nil)
    let shellResult = try await ProcessCommandInvoker().remoteShell(
        host: "172.190.172.6", user: "docker-user", identityFile: "~/.ssh/bastion_id_ed25519", chdir: nil,
        cmd: "mkdir -p ~/.ssh", env: nil, logger: nil)
    print("rc: \(shellResult.returnCode)")
    print("out: \(shellResult.stdoutString ?? "nil")")
    print("err: \(shellResult.stderrString ?? "nil")")
}

@Test(
    "invoking a remote command w/ tilde",
    .enabled(if: ProcessInfo.processInfo.environment.keys.contains("INTEGRATION_ENABLED")),
    .timeLimit(.minutes(1)),
    .tags(.integrationTest))
func invokeVerifyAccess() async throws {
    let engine = Engine()
    let orbStackAddress = try #require(Formic.Host.NetworkAddress("127.0.0.1"))
    let orbStackHost = Formic.Host(
        remote: true,
        address: orbStackAddress,
        sshPort: 32222,
        sshAccessCredentials: .init(
            username: "heckj",
            identityFile: "/Users/heckj/.orbstack/ssh/id_ed25519"),
        strictHostKeyChecking: false)

    let result = try await engine.run(host: orbStackHost, command: VerifyAccess())
    print(result.consoleOutput(verbosity: .verbose(emoji: true)))
}
