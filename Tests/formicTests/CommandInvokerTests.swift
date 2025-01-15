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
    "invoking a command over SSH",
    .enabled(if: ProcessInfo.processInfo.environment.keys.contains("CI")),
    .timeLimit(.minutes(1)),
    .tags(.functionalTest))
func invokeBasicCommandOverSSH() async throws {

    TestLogMessages.bootstrap()
    let logger = Logger(label: "MyTestLabel")
    let container = TestLogMessages.container(forLabel: "MyTestLabel")
    container.reset()  // Wipes out any existing messages

    //let x = TestLogMessages.container(forLabel: "MyTestLabel")
    // To check this test locally, run a local SSH server in docker:
    // docker run --name openSSH-server -d -p 2222:2222 -e USER_NAME=fred -e PUBLIC_KEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINvu92Ykn9Yr7jxemV9MVXPK8nchioFkPUs7rC+5Yus9 heckj@Sparrow.local' lscr.io/linuxserver/openssh-server:latest
    //
    // Then set up the relevant environment variables the CI test attempts to load:
    // export SSH_HOST=127.0.0.1
    // export SSH_PORT=2222
    // export SSH_USERNAME=fred
    // export CI=true
    //
    // Verifying SSH access on CLI:
    //   `ssh fred@localhost -p 2222 -i Tests/formicTests/Fixtures/id_ed25519`
    //
    // swift test --filter FormicTests.invokeBasicCommandOverSSH
    //
    // When done, tear down the container:
    //   `docker rm -f openSSH-server`
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

    let host: Formic.Host? = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = LiveLocalSystemAccess()
    } operation: {
        try await Formic.Host.resolve(
            hostname, sshPort: port, sshUser: username, sshIdentityFile: "Tests/formicTests/Fixtures/id_ed25519",
            strictHostKeyChecking: false)
    }
    let explicitHost: Formic.Host = try #require(host)

    let output: CommandOutput = try await withDependencies { dependencyValues in
        dependencyValues.commandInvoker = ProcessCommandInvoker()
    } operation: {
        try await ShellCommand("uname").run(host: explicitHost, logger: logger)
    }

    print("===TEST DEBUGGING===")
    print("rc: \(output.returnCode)")
    print("out: \(output.stdoutString ?? "nil")")
    print("err: \(output.stderrString ?? "nil")")
    container.print()
    print("===TEST DEBUGGING===")

    // results expected on a Linux host only
    #expect(output.returnCode == 0)
    let stdout = try #require(output.stdoutString)
    #expect(stdout.contains("Linux"))
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
