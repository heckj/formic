import Formic
import Foundation
import Testing

@Test("initializing a copy command")
func copyCommandDeclarationTest() async throws {
    let command = CopyInto(location: "two", from: "one")
    #expect(command.retry == .none)
    #expect(command.from == "one")
    #expect(command.destinationPath == "two")
    #expect(command.env == nil)

    #expect(command.description == "scp one to remote host:two")
}

@Test("initializing a copy command with all options")
func copyCommandFullDeclarationTest() async throws {
    let command = CopyInto(
        location: "two", from: "one",
        retry: .retryOnFailure(Backoff(maxRetries: 100, strategy: .fibonacci(maxDelay: .seconds(60)))))
    #expect(command.from == "one")
    #expect(command.destinationPath == "two")
    #expect(command.env == nil)
    #expect(command.retry != .none)
    guard case .retryOnFailure(let backoff) = command.retry else {
        Issue.record("Unexpected type found in retry: \(command.retry)")
        return
    }
    #expect(backoff == Backoff(maxRetries: 100, strategy: .fibonacci(maxDelay: .seconds(60))))

    #expect(command.description == "scp one to remote host:two")
}
