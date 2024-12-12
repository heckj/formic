import Dependencies
import Foundation
import Testing

@testable import Formic

@Test("Engine initializer")
func initEngine() async throws {
    let engine = Engine()

    #expect(await engine.runners.count == 0)
    #expect(await engine.commandResults.isEmpty)
    #expect(await engine.playbooks.isEmpty)
    #expect(await engine.states.isEmpty)

    // external/public API
    #expect(await engine.status(.localhost) == false)
    #expect(await engine.status(UUID()) == nil)

    // internal pieces
    #expect(await engine.availableCommandsForHost(host: .localhost).isEmpty)

    // step with no playbooks is a no-op
    try await engine.step(for: .localhost)

    #expect(await engine.runners.count == 0)
    #expect(await engine.commandResults.isEmpty)
    #expect(await engine.playbooks.isEmpty)
    #expect(await engine.states.isEmpty)
}

@Test("Engine execution function")
func testEngineRun() async throws {
    let engine = Engine()
    let cmd = Command.shell("uname")
    let cmdExecOut = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
        dependencyValues.commandInvoker = TestCommandInvoker(command: ["uname"], presentOutput: "Darwin\n")
    } operation: {
        try await engine.run(command: cmd, host: .localhost)
    }

    #expect(cmdExecOut.command == cmd)
    #expect(cmdExecOut.output.returnCode == 0)
    #expect(cmdExecOut.output.stdoutString == "Darwin\n")

    #expect(cmdExecOut.host == .localhost)
    #expect(cmdExecOut.playbookId == nil)
    #expect(cmdExecOut.retries == 0)
    #expect(cmdExecOut.duration > .zero)
}

@Test("engine schedule w/ step function")
func testEngineScheduleStep() async throws {
    typealias Host = Formic.Host
    let engine = Engine()
    let cmd1 = Command.shell("uname")
    let cmd2 = Command.shell("whoami")

    let fakeHost = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess(
            dnsName: "somewhere.com", ipAddressesToUse: ["8.8.8.8"])
    } operation: {
        try await Host.resolve("somewhere.com")
    }

    let playbook = Playbook(name: "example", hosts: [fakeHost], commands: [cmd1, cmd2])
    let mockCmdInvoker = TestCommandInvoker()
        .addSuccess(command: ["uname"], presentOutput: "Linux\n")
        .addSuccess(command: ["whoami"], presentOutput: "docker-user")

    await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
        dependencyValues.commandInvoker = mockCmdInvoker
    } operation: {
        await engine.schedule(playbook, delay: .microseconds(1), startRunner: false)

        #expect(await engine.runners.count == 0)
        #expect(await engine.commandResults.count == 1)
        #expect(await engine.commandResults[fakeHost] == [:])
        #expect(await engine.playbooks.count == 1)
        #expect(await engine.playbooks[playbook.id] == playbook)
        #expect(await engine.states.count == 1)
        #expect(await engine.states[playbook.id] == .scheduled)
    }

    try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
        dependencyValues.commandInvoker = mockCmdInvoker
    } operation: {
        // and take a _single_ step
        try await engine.step(for: fakeHost)
    }

    #expect(await engine.runners.count == 0)
    #expect(await engine.commandResults.count == 1)
    #expect(await engine.playbooks.count == 1)
    #expect(await engine.playbooks[playbook.id] == playbook)
    #expect(await engine.states.count == 1)
    let playbookRunState = try #require(await engine.states[playbook.id])
    print(playbookRunState)
    #expect(playbookRunState == .running)

    // and verify the results of the first command are recorded
    let currentResults: [Command.ID: CommandExecutionResult] = try await #require(engine.commandResults[fakeHost])
    #expect(currentResults.count == 1)
    let singleResult: CommandExecutionResult = try #require(currentResults[cmd1.id])
    #expect(singleResult.command == cmd1)
    #expect(singleResult.playbookId == playbook.id)
    #expect(singleResult.host == fakeHost)
    #expect(singleResult.retries == 0)
}
