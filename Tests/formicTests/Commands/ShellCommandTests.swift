import Dependencies
import Foundation
import Testing

@testable import Formic

@Test("initializing a shell command")
func shellCommandDeclarationTest() async throws {
    let command = ShellCommand("uname")
    #expect(command.retry == .never)
    #expect(command.commandString == "uname")
    #expect(command.env == nil)
    #expect(command.id != nil)

    #expect(command.description == "uname")
}

@Test("unique command ids by instance (Identifiable)")
func verifyIdentifiableCommands() async throws {
    let command1 = ShellCommand("uname")
    let command2 = ShellCommand("uname")
    try #require(command1.id != command2.id)
}

@Test("initializing a shell command with all options")
func shellCommandFullDeclarationTest() async throws {
    let command = ShellCommand(
        "ls", env: ["PATH": "/usr/bin"],
        retry: Backoff(maxRetries: 200, strategy: .exponential(maxDelay: .seconds(60))))
    #expect(command.commandString == "ls")
    #expect(command.env == ["PATH": "/usr/bin"])
    #expect(command.retry == Backoff(maxRetries: 200, strategy: .exponential(maxDelay: .seconds(60))))
    #expect(command.description == "ls")
}

@Test("test invoking a shell command")
func testInvokingShellCommand() async throws {

    let testInvoker = TestCommandInvoker()

    let host = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess(
            dnsName: "somewhere.com", ipAddressesToUse: ["8.8.8.8"])
    } operation: {
        try await Host.resolve("somewhere.com")
    }

    let cmdOut = try await withDependencies {
        $0.commandInvoker = testInvoker
    } operation: {
        try await ShellCommand("ls -altr").run(host: host, logger: nil)
    }

    #expect(cmdOut.returnCode == 0)
}
