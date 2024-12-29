import Dependencies
import Foundation
import Testing

@testable import Formic

@Test("Engine initializer")
func initEngine() async throws {
    let _ = Engine()
}

@Test("Direct engine execution - single function")
func testEngineRun() async throws {
    let engine = Engine()
    let cmd = ShellCommand("uname")
    let cmdExecOut = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
        dependencyValues.commandInvoker = TestCommandInvoker()
            .addSuccess(command: ["uname"], presentOutput: "Darwin\n")
    } operation: {
        try await engine.run(host: .localhost, command: cmd)
    }

    #expect(cmdExecOut.command.id == cmd.id)
    #expect(cmdExecOut.output.returnCode == 0)
    #expect(cmdExecOut.output.stdoutString == "Darwin\n")

    #expect(cmdExecOut.host == .localhost)
    #expect(cmdExecOut.retries == 0)
    #expect(cmdExecOut.duration > .zero)
    #expect(cmdExecOut.exception == nil)
}

@Test("Direct engine execution - list of functions")
func testEngineRunList() async throws {
    let engine = Engine()
    let cmd1 = ShellCommand("uname")
    let cmd2 = ShellCommand("whoami")

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

    #expect(cmdExecOut[0].retries == 0)
    #expect(cmdExecOut[0].duration > .zero)
    #expect(cmdExecOut[0].exception == nil)

    #expect(cmdExecOut[1].command.id == cmd2.id)
    #expect(cmdExecOut[1].output.returnCode == 0)
    #expect(cmdExecOut[1].output.stdoutString == "docker-user")

    #expect(cmdExecOut[1].host == .localhost)
    #expect(cmdExecOut[1].retries == 0)
    #expect(cmdExecOut[1].duration > .zero)
    #expect(cmdExecOut[1].exception == nil)
}

@Test("Direct engine execution - playbook")
func testEngineRunPlaybook() async throws {
    let engine = Engine()
    let cmd1 = ShellCommand("uname")
    let cmd2 = ShellCommand("whoami")

    let collectedResults = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
        dependencyValues.commandInvoker = TestCommandInvoker()
            .addSuccess(command: ["uname"], presentOutput: "Darwin\n")
            .addSuccess(command: ["whoami"], presentOutput: "docker-user")
    } operation: {
        try await engine.run(hosts: .localhost, commands: [cmd1, cmd2], displayProgress: false)
    }

    #expect(collectedResults.count == 1)

    let resultsForLocalhost: [CommandExecutionResult] = try #require(collectedResults[.localhost])
    #expect(resultsForLocalhost.count == 2)

    #expect(resultsForLocalhost[0].output.stdoutString == "Darwin\n")
    #expect(resultsForLocalhost[0].host == .localhost)
    #expect(resultsForLocalhost[0].retries == 0)
    #expect(resultsForLocalhost[0].exception == nil)

    #expect(resultsForLocalhost[1].output.stdoutString == "docker-user")
    #expect(resultsForLocalhost[1].host == .localhost)
    #expect(resultsForLocalhost[1].retries == 0)
    #expect(resultsForLocalhost[1].exception == nil)
}

@Test("Direct engine execution - playbook w/ failure")
func testEngineRunPlaybookWithFailure() async throws {
    let engine = Engine()
    let cmd1 = ShellCommand("uname")
    let cmd2 = ShellCommand("whoami")

    let collectedResults = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
        dependencyValues.commandInvoker = TestCommandInvoker()
            .addSuccess(command: ["uname"], presentOutput: "Darwin\n")
            .addFailure(command: ["whoami"], presentOutput: "not tellin!")
    } operation: {
        try await engine.run(hosts: .localhost, commands: [cmd1, cmd2], displayProgress: false)
    }

    #expect(collectedResults.count == 1)

    let resultsForLocalhost: [CommandExecutionResult] = try #require(collectedResults[.localhost])
    #expect(resultsForLocalhost.count == 2)

    #expect(resultsForLocalhost[0].output.stdoutString == "Darwin\n")
    #expect(resultsForLocalhost[0].host == .localhost)
    #expect(resultsForLocalhost[0].retries == 0)
    #expect(resultsForLocalhost[0].exception == nil)

    #expect(resultsForLocalhost[1].output.stderrString == "not tellin!")
    #expect(resultsForLocalhost[1].host == .localhost)
    #expect(resultsForLocalhost[1].retries == 0)
    #expect(resultsForLocalhost[1].exception == nil)
}

@Test("Direct engine execution - playbook w/ exception")
func testEngineRunPlaybookWithException() async throws {
    let engine = Engine()
    let cmd1 = ShellCommand("uname")
    let cmd2 = ShellCommand("whoami")

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
                try await engine.run(hosts: .localhost, commands: [cmd1, cmd2], displayProgress: false)
            }
        })
}

@Test("verify timeout is triggered on long command")
func testCommandTimeout() async throws {
    typealias Host = Formic.Host
    let engine = Engine()
    let cmd1 = ShellCommand("uname", executionTimeout: .seconds(1))

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
                return try await engine.run(host: fakeHost, command: cmd1)
            }
        })
}

@Test("verify retry works as expected")
func testCommandRetry() async throws {
    typealias Host = Formic.Host
    let engine = Engine()
    let cmd1 = ShellCommand("uname", retry: .default)

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
        return try await engine.run(host: fakeHost, command: cmd1)
    }

    #expect(result.command.id == cmd1.id)
    #expect(result.output.returnCode == -1)
    #expect(result.output.stderrString == "not tellin!")
    #expect(result.retries == 3)
}
