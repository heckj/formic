import Foundation
import Testing

@testable import Formic

@Test(
    "invoking a command",
    .enabled(if: ProcessInfo.processInfo.environment.keys.contains("CI")),
    .timeLimit(.minutes(1)),
    .tags(.functionalTest))
func invokeBasicCommandLocally() async throws {
    let shellResult = try await ProcessCommandInvoker().localShell(cmd: "uname", stdIn: nil, env: nil)

    // print("rc: \(shellResult.returnCode)")
    // print("out: \(shellResult.stdoutString ?? "nil")")
    // print("err: \(shellResult.stderrString ?? "nil")")

    // results expected on a Linux host only
    #expect(shellResult.returnCode == 0)
    #expect(shellResult.stdoutString == "Linux\n")
    #expect(shellResult.stderrString == nil)
}

@Test(
    "invoking a local command w/ chdir",
    .enabled(if: ProcessInfo.processInfo.environment.keys.contains("INTEGRATION_ENABLED")),
    .timeLimit(.minutes(1)),
    .tags(.integrationTest))
func invokeBasicCommandLocallyWithChdir() async throws {
    let shellResult = try await ProcessCommandInvoker().localShell(cmd: "pwd", stdIn: nil, env: nil, chdir: "..")

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
        cmd: "ls -al", env: nil)
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
        cmd: "echo ${FIDDLY}", env: ["FIDDLY": "FADDLY"])
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
        cmd: "ls -al", env: nil)
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
    let shellResult = try await ProcessCommandInvoker().remoteShell(
        host: "127.0.0.1", user: "heckj", identityFile: "~/.orbstack/ssh/id_ed25519", port: 32222, chdir: "..",
        cmd: "mkdir ~/.ssh", env: nil)
    print("rc: \(shellResult.returnCode)")
    print("out: \(shellResult.stdoutString ?? "nil")")
    print("err: \(shellResult.stderrString ?? "nil")")
}
