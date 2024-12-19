import Formic
import Foundation
import Testing

@Test("initializing a copy command")
func copyFromCommandDeclarationTest() async throws {

    let url: URL = try #require(URL(string: "http://somehost.com/datafile"))
    let command = CopyFrom(location: "/dest/path", from: url)
    #expect(command.retry == .none)
    #expect(command.from == url)
    #expect(command.destinationPath == "/dest/path")
    #expect(command.env == nil)

    #expect(command.description == "scp http://somehost.com/datafile to remote host:/dest/path")
}

@Test("initializing a copy command with all options")
func copyFromCommandFullDeclarationTest() async throws {
    let url: URL = try #require(URL(string: "http://somehost.com/datafile"))
    let command = CopyFrom(
        location: "/dest/path", from: url,
        retry: .retryOnFailure(Backoff(maxRetries: 100, strategy: .fibonacci(maxDelay: .seconds(60)))))
    #expect(command.from == url)
    #expect(command.destinationPath == "/dest/path")
    #expect(command.env == nil)
    #expect(command.retry != .none)
    guard case .retryOnFailure(let backoff) = command.retry else {
        Issue.record("Unexpected type found in retry: \(command.retry)")
        return
    }
    #expect(backoff == Backoff(maxRetries: 100, strategy: .fibonacci(maxDelay: .seconds(60))))

    #expect(command.description == "scp http://somehost.com/datafile to remote host:/dest/path")
}
