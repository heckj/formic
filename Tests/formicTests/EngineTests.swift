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
    #expect(await engine.runnerOperating(for: .localhost) == false)
    #expect(await engine.status(UUID()) == nil)

    // internal pieces
    #expect(await engine.availableCommandsForHost(host: .localhost).isEmpty)

    // step with no playbooks is a no-op
    await engine.step(for: .localhost)

    #expect(await engine.runners.count == 0)
    #expect(await engine.commandResults.isEmpty)
    #expect(await engine.playbooks.isEmpty)
    #expect(await engine.states.isEmpty)
}

@Test("Direct engine execution - single function")
func testEngineRun() async throws {
    let engine = Engine()
    let cmd = LocalProcess.shell("uname")
    let cmdExecOut = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
        dependencyValues.commandInvoker = TestCommandInvoker()
            .addSuccess(command: ["uname"], presentOutput: "Darwin\n")
    } operation: {
        try await engine.run(command: cmd, host: .localhost)
    }

    #expect(cmdExecOut.command.id == cmd.id)
    #expect(cmdExecOut.output.returnCode == 0)
    #expect(cmdExecOut.output.stdoutString == "Darwin\n")

    #expect(cmdExecOut.host == .localhost)
    #expect(cmdExecOut.playbookId == nil)
    #expect(cmdExecOut.retries == 0)
    #expect(cmdExecOut.duration > .zero)
    #expect(cmdExecOut.exception == nil)
}

@Test("Direct engine execution - list of functions")
func testEngineRunList() async throws {
    let engine = Engine()
    let cmd1 = LocalProcess.shell("uname")
    let cmd2 = LocalProcess.shell("whoami")

    let cmdExecOut = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
        dependencyValues.commandInvoker = TestCommandInvoker()
            .addSuccess(command: ["uname"], presentOutput: "Darwin\n")
            .addSuccess(command: ["whoami"], presentOutput: "docker-user")
    } operation: {
        try await engine.run(host: .localhost, commands: [cmd1, cmd2], displayProgress: false)
    }

    #expect(cmdExecOut.count == 2)
    #expect(cmdExecOut[0].command.id == cmd1.id)
    #expect(cmdExecOut[0].output.returnCode == 0)
    #expect(cmdExecOut[0].output.stdoutString == "Darwin\n")

    #expect(cmdExecOut[0].host == .localhost)
    #expect(cmdExecOut[0].playbookId == nil)
    #expect(cmdExecOut[0].retries == 0)
    #expect(cmdExecOut[0].duration > .zero)
    #expect(cmdExecOut[0].exception == nil)

    #expect(cmdExecOut[1].command.id == cmd2.id)
    #expect(cmdExecOut[1].output.returnCode == 0)
    #expect(cmdExecOut[1].output.stdoutString == "docker-user")

    #expect(cmdExecOut[1].host == .localhost)
    #expect(cmdExecOut[1].playbookId == nil)
    #expect(cmdExecOut[1].retries == 0)
    #expect(cmdExecOut[1].duration > .zero)
    #expect(cmdExecOut[1].exception == nil)
}

@Test("Direct engine execution - playbook")
func testEngineRunPlaybook() async throws {
    let engine = Engine()
    let cmd1 = LocalProcess.shell("uname")
    let cmd2 = LocalProcess.shell("whoami")
    let playbook = Playbook(
        name: "testPlaybook", hosts: [.localhost],
        commands: [cmd1, cmd2])

    let status = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
        dependencyValues.commandInvoker = TestCommandInvoker()
            .addSuccess(command: ["uname"], presentOutput: "Darwin\n")
            .addSuccess(command: ["whoami"], presentOutput: "docker-user")
    } operation: {
        try await engine.run(playbook: playbook, displayProgress: false)
    }

    #expect(status.playbook.id == playbook.id)
    #expect(status.playbook == playbook)
    #expect(status.state == .complete)
    #expect(status.results.count == 1)

    let resultsForLocalhost: [UUID: CommandExecutionResult] = try #require(status.results[.localhost])
    #expect(resultsForLocalhost.count == 2)

    #expect(resultsForLocalhost[cmd1.id]?.output.stdoutString == "Darwin\n")
    #expect(resultsForLocalhost[cmd1.id]?.playbookId == playbook.id)
    #expect(resultsForLocalhost[cmd1.id]?.host == .localhost)
    #expect(resultsForLocalhost[cmd1.id]?.retries == 0)
    #expect(resultsForLocalhost[cmd1.id]?.exception == nil)

    #expect(resultsForLocalhost[cmd2.id]?.output.stdoutString == "docker-user")
    #expect(resultsForLocalhost[cmd2.id]?.playbookId == playbook.id)
    #expect(resultsForLocalhost[cmd2.id]?.host == .localhost)
    #expect(resultsForLocalhost[cmd2.id]?.retries == 0)
    #expect(resultsForLocalhost[cmd2.id]?.exception == nil)
}

@Test("Direct engine execution - playbook w/ failure")
func testEngineRunPlaybookWithFailure() async throws {
    let engine = Engine()
    let cmd1 = LocalProcess.shell("uname")
    let cmd2 = LocalProcess.shell("whoami")
    let playbook = Playbook(
        name: "testPlaybook", hosts: [.localhost],
        commands: [cmd1, cmd2])

    let status = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
        dependencyValues.commandInvoker = TestCommandInvoker()
            .addSuccess(command: ["uname"], presentOutput: "Darwin\n")
            .addFailure(command: ["whoami"], presentOutput: "not tellin!")
    } operation: {
        try await engine.run(playbook: playbook, displayProgress: false)
    }

    #expect(status.playbook.id == playbook.id)
    #expect(status.playbook == playbook)
    #expect(status.state == .failed)
    #expect(status.results.count == 1)

    let resultsForLocalhost: [UUID: CommandExecutionResult] = try #require(status.results[.localhost])
    #expect(resultsForLocalhost.count == 2)

    #expect(resultsForLocalhost[cmd1.id]?.output.stdoutString == "Darwin\n")
    #expect(resultsForLocalhost[cmd1.id]?.playbookId == playbook.id)
    #expect(resultsForLocalhost[cmd1.id]?.host == .localhost)
    #expect(resultsForLocalhost[cmd1.id]?.retries == 0)
    #expect(resultsForLocalhost[cmd1.id]?.exception == nil)

    #expect(resultsForLocalhost[cmd2.id]?.output.stderrString == "not tellin!")
    #expect(resultsForLocalhost[cmd2.id]?.playbookId == playbook.id)
    #expect(resultsForLocalhost[cmd2.id]?.host == .localhost)
    #expect(resultsForLocalhost[cmd2.id]?.retries == 0)
    #expect(resultsForLocalhost[cmd2.id]?.exception == nil)
}

@Test("Direct engine execution - playbook w/ exception")
func testEngineRunPlaybookWithException() async throws {
    let engine = Engine()
    let cmd1 = LocalProcess.shell("uname")
    let cmd2 = LocalProcess.shell("whoami")
    let playbook = Playbook(
        name: "testPlaybook", hosts: [.localhost],
        commands: [cmd1, cmd2])

    await #expect(
        throws: TestError.self,
        performing: {
            let _ = try await withDependencies { dependencyValues in
                dependencyValues.localSystemAccess = TestFileSystemAccess()
                dependencyValues.commandInvoker = TestCommandInvoker()
                    .addSuccess(command: ["uname"], presentOutput: "Darwin\n")
                    .addException(
                        command: ["whoami"], errorToThrow: TestError.unknown(msg: "Process failed in something"))
            } operation: {
                try await engine.run(playbook: playbook, displayProgress: false)
            }
        })
}

@Test("engine schedule w/ step function")
func testEngineScheduleStep() async throws {
    typealias Host = Formic.Host
    let engine = Engine()
    let cmd1 = LocalProcess.shell("uname")
    let cmd2 = LocalProcess.shell("whoami")

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

    await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
        dependencyValues.commandInvoker = mockCmdInvoker
    } operation: {
        // and take a _single_ step
        await engine.step(for: fakeHost)
    }

    #expect(await engine.runners.count == 0)
    #expect(await engine.commandResults.count == 1)
    #expect(await engine.playbooks.count == 1)
    #expect(await engine.playbooks[playbook.id] == playbook)
    #expect(await engine.states.count == 1)
    let playbookRunState = try #require(await engine.states[playbook.id])
    #expect(playbookRunState == .running)

    // and verify the results of the first command are recorded
    let currentResults: [LocalProcess.ID: CommandExecutionResult] = try await #require(engine.commandResults[fakeHost])
    #expect(currentResults.count == 1)
    let singleResult: CommandExecutionResult = try #require(currentResults[cmd1.id])
    #expect(singleResult.command.id == cmd1.id)
    #expect(singleResult.playbookId == playbook.id)
    #expect(singleResult.host == fakeHost)
    #expect(singleResult.retries == 0)
}

@Test("engine schedule w/ step function")
func testEngineScheduleStepWithFailure() async throws {
    typealias Host = Formic.Host
    let engine = Engine()
    let cmd1 = LocalProcess.shell("uname")
    let cmd2 = LocalProcess.shell("whoami")

    let fakeHost = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess(
            dnsName: "somewhere.com", ipAddressesToUse: ["8.8.8.8"])
    } operation: {
        try await Host.resolve("somewhere.com")
    }

    let playbook = Playbook(name: "example", hosts: [fakeHost], commands: [cmd1, cmd2])
    let mockCmdInvoker = TestCommandInvoker()
        .addSuccess(command: ["uname"], presentOutput: "Linux\n")
        .addFailure(command: ["whoami"], presentOutput: "zsh: command not found: whoami")

    await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
        dependencyValues.commandInvoker = mockCmdInvoker
    } operation: {
        await engine.schedule(playbook, delay: .microseconds(1), startRunner: false)
        await engine.step(for: fakeHost)
        await engine.step(for: fakeHost)
    }

    #expect(await engine.runners.count == 0)
    #expect(await engine.playbooks.count == 1)
    #expect(await engine.playbooks[playbook.id] == playbook)
    #expect(await engine.states.count == 1)

    let playbookRunState = try #require(await engine.states[playbook.id])
    #expect(playbookRunState == .failed)

    #expect(await engine.commandResults.count == 1)

    // and verify the results of the first command are recorded
    let currentResults: [LocalProcess.ID: CommandExecutionResult] = try await #require(engine.commandResults[fakeHost])
    #expect(currentResults.count == 2)
    let finalResult: CommandExecutionResult = try #require(currentResults[cmd2.id])
    #expect(finalResult.command.id == cmd2.id)
    #expect(finalResult.playbookId == playbook.id)
    #expect(finalResult.host == fakeHost)
    #expect(finalResult.retries == 0)

    #expect(finalResult.output.returnCode == -1)
    #expect(finalResult.output.stderrString == "zsh: command not found: whoami")
}

@Test("playbook complete w/ step function")
func testPlaybookComplete() async throws {
    typealias Host = Formic.Host
    let engine = Engine()
    let cmd1 = LocalProcess.shell("uname")
    let cmd2 = LocalProcess.shell("whoami")

    let fakeHost = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess(
            dnsName: "somewhere.com", ipAddressesToUse: ["8.8.8.8"])
    } operation: {
        try await Host.resolve("somewhere.com")
    }

    let playbook = Playbook(name: "example", hosts: [fakeHost, .localhost], commands: [cmd1, cmd2])
    let mockCmdInvoker = TestCommandInvoker()
        .addSuccess(command: ["uname"], presentOutput: "Linux\n")
        .addSuccess(command: ["whoami"], presentOutput: "zsh: command not found: whoami")

    await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
        dependencyValues.commandInvoker = mockCmdInvoker
    } operation: {
        #expect(await engine.playbookComplete(playbookId: playbook.id) == false)
        await engine.schedule(playbook, delay: .microseconds(1), startRunner: false)
        #expect(await engine.playbookComplete(playbookId: playbook.id) == false)
        await engine.step(for: fakeHost)
        #expect(await engine.playbookComplete(playbookId: playbook.id) == false)
        await engine.step(for: fakeHost)
        #expect(await engine.playbookComplete(playbookId: playbook.id) == false)
        await engine.step(for: .localhost)
        #expect(await engine.playbookComplete(playbookId: playbook.id) == false)
        await engine.step(for: .localhost)
        #expect(await engine.playbookComplete(playbookId: playbook.id) == true)
    }
}

@Test("playbook result for non-existant playbook")
func testUnknownPlaybookComplete() async throws {
    let engine = Engine()
    let unregisteredPlaybook = await Playbook(name: "unknown", hosts: [], commands: [])
    #expect(await engine.playbookComplete(playbookId: unregisteredPlaybook.id) == false)
}

@Test("engine schedule w/ immediate error using step function")
func testEngineScheduleStepWithImmediateError() async throws {
    typealias Host = Formic.Host
    let engine = Engine()
    let cmd1 = LocalProcess.shell("uname")
    let cmd2 = LocalProcess.shell("whoami")

    let fakeHost = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess(
            dnsName: "somewhere.com", ipAddressesToUse: ["8.8.8.8"])
    } operation: {
        try await Host.resolve("somewhere.com")
    }

    let playbook = Playbook(name: "example", hosts: [fakeHost], commands: [cmd1, cmd2])
    let mockCmdInvoker = TestCommandInvoker()
        .addException(command: ["uname"], errorToThrow: TestError.unknown(msg: "Process failed in something"))

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

    await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
        dependencyValues.commandInvoker = mockCmdInvoker
    } operation: {
        // and take a _single_ step
        await engine.step(for: fakeHost)
    }

    #expect(await engine.runners.count == 0)
    #expect(await engine.commandResults.count == 1)
    #expect(await engine.playbooks.count == 1)
    #expect(await engine.playbooks[playbook.id] == playbook)
    #expect(await engine.states.count == 1)

    let playbookRunState = try #require(await engine.states[playbook.id])
    #expect(playbookRunState == .failed)

    // and verify the results of the first command are recorded
    let currentResults: [LocalProcess.ID: CommandExecutionResult] = try await #require(engine.commandResults[fakeHost])
    #expect(currentResults.count == 1)
}

@Test("engine schedule, later exception, w/ step function")
func testEngineScheduleStepWithLaterException() async throws {
    typealias Host = Formic.Host
    let engine = Engine()
    let cmd1 = LocalProcess.shell("uname")
    let cmd2 = LocalProcess.shell("whoami")

    let fakeHost = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess(
            dnsName: "somewhere.com", ipAddressesToUse: ["8.8.8.8"])
    } operation: {
        try await Host.resolve("somewhere.com")
    }

    let playbook = Playbook(name: "example", hosts: [fakeHost], commands: [cmd1, cmd2])
    let mockCmdInvoker = TestCommandInvoker()
        .addSuccess(command: ["uname"], presentOutput: "Linux\n")
        .addException(command: ["whoami"], errorToThrow: TestError.unknown(msg: "Process failed in something"))

    await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
        dependencyValues.commandInvoker = mockCmdInvoker
    } operation: {
        await engine.schedule(playbook, delay: .microseconds(1), startRunner: false)
        await engine.step(for: fakeHost)
        await engine.step(for: fakeHost)
    }

    #expect(await engine.runners.count == 0)
    #expect(await engine.playbooks.count == 1)
    #expect(await engine.playbooks[playbook.id] == playbook)
    #expect(await engine.states.count == 1)

    let playbookRunState = try #require(await engine.states[playbook.id])
    #expect(playbookRunState == .failed)

    #expect(await engine.commandResults.count == 1)

    // and verify the results of the first command are recorded
    let currentResults: [LocalProcess.ID: CommandExecutionResult] = try await #require(engine.commandResults[fakeHost])
    #expect(currentResults.count == 2)

    let finalResult: CommandExecutionResult = try #require(currentResults[cmd2.id])
    #expect(finalResult.command.id == cmd2.id)
    #expect(finalResult.playbookId == playbook.id)
    #expect(finalResult.host == fakeHost)
    #expect(finalResult.exception == "Unknown error: Process failed in something")
}

@Test("requesting state after single step")
func testPlaybookStatusAfterStep() async throws {
    typealias Host = Formic.Host
    let engine = Engine()
    let cmd1 = LocalProcess.shell("uname")
    let cmd2 = LocalProcess.shell("whoami")

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
        await engine.step(for: fakeHost)
    }

    let pbStatus: PlaybookStatus = try #require(await engine.status(playbook.id))
    #expect(pbStatus.playbook == playbook)
    #expect(pbStatus.state == .running)
    #expect(!pbStatus.results.isEmpty)
    let resultsFromPbStatus = pbStatus.results
    #expect(resultsFromPbStatus.count == 1)
    let dictOfResultsforHost: [LocalProcess.ID: CommandExecutionResult] = try #require(resultsFromPbStatus[fakeHost])
    #expect(dictOfResultsforHost.count == 1)
    #expect(dictOfResultsforHost[cmd1.id]?.command.id == cmd1.id)

    await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
        dependencyValues.commandInvoker = mockCmdInvoker
    } operation: {
        await engine.step(for: fakeHost)
    }

    let finalPbStatus: PlaybookStatus = try #require(await engine.status(playbook.id))
    #expect(finalPbStatus.state == .complete)
}

@Test("using Schedule, default mode, creates a runner for the hosts of the playbook scheduled")
func testPlaybookRunnerIsCreatedOnSchedule() async throws {
    typealias Host = Formic.Host
    let engine = Engine()

    let fakeHost = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess(
            dnsName: "somewhere.com", ipAddressesToUse: ["8.8.8.8"])
    } operation: {
        try await Host.resolve("somewhere.com")
    }

    let playbook = Playbook(name: "example", hosts: [fakeHost], commands: [])

    await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
    } operation: {
        await engine.schedule(playbook, delay: .microseconds(1), startRunner: true)
    }

    #expect(await engine.runners.count == 1)
    await engine.cancelRunner(for: fakeHost)
    #expect(await engine.runners.count == 0)
}

@Test("verify playbook state stream")
func testPlaybookStateStream() async throws {
    typealias Host = Formic.Host
    let engine = Engine()
    let cmd1 = LocalProcess.shell("uname")
    let cmd2 = LocalProcess.shell("whoami")

    let fakeHost = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess(
            dnsName: "somewhere.com", ipAddressesToUse: ["8.8.8.8"])
    } operation: {
        try await Host.resolve("somewhere.com")
    }

    let playbook = Playbook(name: "example", hosts: [fakeHost], commands: [cmd1, cmd2])
    let mockCmdInvoker = TestCommandInvoker()
        .addSuccess(command: ["uname"], presentOutput: "Linux\n")
        .addException(command: ["whoami"], errorToThrow: TestError.unknown(msg: "Process failed in something"))

    let stateStream: AsyncStream<(Playbook.ID, PlaybookState)> = engine.playbookUpdates
    var streamIterator = stateStream.makeAsyncIterator()

    try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
        dependencyValues.commandInvoker = mockCmdInvoker
    } operation: {
        await engine.schedule(playbook, delay: .microseconds(1), startRunner: false)

        var (id, state) = try #require(await streamIterator.next())
        #expect(id == playbook.id)
        #expect(state == .scheduled)

        await engine.step(for: fakeHost)

        (id, state) = try #require(await streamIterator.next())
        #expect(id == playbook.id)
        #expect(state == .running)

        await engine.step(for: fakeHost)
        (id, state) = try #require(await streamIterator.next())
        #expect(id == playbook.id)
        #expect(state == .failed)
    }
}

@Test("verify playbook command result stream")
func testPlaybookCommandResultStream() async throws {
    typealias Host = Formic.Host
    let engine = Engine()
    let cmd1 = LocalProcess.shell("uname")
    let cmd2 = LocalProcess.shell("whoami")

    let fakeHost = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess(
            dnsName: "somewhere.com", ipAddressesToUse: ["8.8.8.8"])
    } operation: {
        try await Host.resolve("somewhere.com")
    }

    let playbook = Playbook(name: "example", hosts: [fakeHost], commands: [cmd1, cmd2])
    let mockCmdInvoker = TestCommandInvoker()
        .addSuccess(command: ["uname"], presentOutput: "Linux\n")
        .addException(command: ["whoami"], errorToThrow: TestError.unknown(msg: "Process failed in something"))

    let stateStream: AsyncStream<CommandExecutionResult> = engine.commandUpdates
    var streamIterator = stateStream.makeAsyncIterator()

    try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
        dependencyValues.commandInvoker = mockCmdInvoker
    } operation: {
        await engine.schedule(playbook, delay: .microseconds(1), startRunner: false)

        await engine.step(for: fakeHost)

        var result: CommandExecutionResult = try #require(await streamIterator.next())
        #expect(result.playbookId == playbook.id)
        #expect(result.exception == nil)
        #expect(result.command.id == cmd1.id)

        await engine.step(for: fakeHost)
        result = try #require(await streamIterator.next())
        #expect(result.playbookId == playbook.id)
        #expect(result.exception != nil)
        #expect(result.command.id == cmd2.id)
    }
}

@Test("verify timeout is triggered on long command")
func testCommandTimeout() async throws {
    typealias Host = Formic.Host
    let engine = Engine()
    let cmd1 = LocalProcess.shell("uname", timeout: .seconds(1))

    let fakeHost = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess(
            dnsName: "somewhere.com", ipAddressesToUse: ["8.8.8.8"])
    } operation: {
        try await Host.resolve("somewhere.com")
    }

    let mockCmdInvoker = TestCommandInvoker()
        .addSuccess(command: ["uname"], presentOutput: "Linux\n", delay: .seconds(2))

    await #expect(
        throws: CommandError.self, "Slow command should invoke timeout",
        performing: {
            let _ = try await withDependencies { dependencyValues in
                dependencyValues.localSystemAccess = TestFileSystemAccess()
                dependencyValues.commandInvoker = mockCmdInvoker
            } operation: {
                return try await engine.run(command: cmd1, host: fakeHost)
            }
        })
}

@Test("verify retry works as expected")
func testCommandRetry() async throws {
    typealias Host = Formic.Host
    let engine = Engine()
    let cmd1 = LocalProcess.shell("uname", retry: .retryOnFailure(.default))

    let fakeHost = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess(
            dnsName: "somewhere.com", ipAddressesToUse: ["8.8.8.8"])
    } operation: {
        try await Host.resolve("somewhere.com")
    }

    let mockCmdInvoker = TestCommandInvoker()
        .addFailure(command: ["uname"], presentOutput: "not tellin!")

    let result = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
        dependencyValues.commandInvoker = mockCmdInvoker
    } operation: {
        return try await engine.run(command: cmd1, host: fakeHost)
    }

    #expect(result.command.id == cmd1.id)
    #expect(result.output.returnCode == -1)
    #expect(result.output.stderrString == "not tellin!")
    #expect(result.retries == 3)
}
