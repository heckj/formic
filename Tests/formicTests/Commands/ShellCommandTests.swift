import Formic
import Foundation
import Testing

@Test("initializing a shell command")
func shellCommandDeclarationTest() async throws {
    let command = ShellCommand("uname")
    #expect(command.retry == .none)
    #expect(command.args == ["uname"])
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
        retry: .retryOnFailure(
            Backoff(maxRetries: 200, strategy: .exponential(maxDelay: .seconds(60)))))
    #expect(command.args == ["ls"])
    #expect(command.env == ["PATH": "/usr/bin"])
    #expect(command.retry != .none)
    guard case .retryOnFailure(let backoff) = command.retry else {
        Issue.record("Unexpected type found in retry: \(command.retry)")
        return
    }
    #expect(backoff == Backoff(maxRetries: 200, strategy: .exponential(maxDelay: .seconds(60))))
    #expect(command.description == "ls")
}
