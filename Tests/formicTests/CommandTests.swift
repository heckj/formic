import Formic
import Foundation
import Testing

@Test("initializing a shell command")
func shellCommandDeclarationTest() async throws {
    let command = Command.shell("uname")
    #expect(command.retry == .none)
    #expect(command.args == ["uname"])
    #expect(command.env == nil)
    #expect(command.id != nil)

    #expect(command.description == "uname")
}

@Test("unique command ids by instance (Identifiable)")
func verifyIdentifiableCommands() async throws {
    let command1 = Command.shell("uname")
    let command2 = Command.shell("uname")
    try #require(command1.id != command2.id)
}

@Test("initializing a shell command with all options")
func shellCommandFullDeclarationTest() async throws {
    let command = Command.shell(
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

@Test("initializing a copy command")
func copyCommandDeclarationTest() async throws {
    let command = Command.remoteCopy(from: "one", to: "two")
    #expect(command.retry == .none)
    #expect(command.args == ["one", "two"])
    #expect(command.env == nil)

    #expect(command.description == "scp one to remote host:two")
}

@Test("initializing a copy command with all options")
func copyCommandFullDeclarationTest() async throws {
    let command = Command.remoteCopy(
        from: "one", to: "two",
        retry: .retryOnFailure(Backoff(maxRetries: 100, strategy: .fibonacci(maxDelay: .seconds(60)))))
    #expect(command.args == ["one", "two"])
    #expect(command.env == nil)
    #expect(command.retry != .none)
    guard case .retryOnFailure(let backoff) = command.retry else {
        Issue.record("Unexpected type found in retry: \(command.retry)")
        return
    }
    #expect(backoff == Backoff(maxRetries: 100, strategy: .fibonacci(maxDelay: .seconds(60))))

    #expect(command.description == "scp one to remote host:two")
}
