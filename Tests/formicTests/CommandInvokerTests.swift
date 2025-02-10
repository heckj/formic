import Dependencies
import Foundation
import Logging
import SwiftLogTesting
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
    let stdout = try #require(shellResult.stdoutString)
    #expect(stdout.contains("Linux"))
    #expect(shellResult.stderrString == nil)
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
