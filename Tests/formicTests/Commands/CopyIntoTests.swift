import Dependencies
import Foundation
import Testing

@testable import Formic

@Test("initializing a copy command")
func copyCommandDeclarationTest() async throws {
    let command = CopyInto(location: "two", from: "one")
    #expect(command.retry == .never)
    #expect(command.from == "one")
    #expect(command.destinationPath == "two")
    #expect(command.env == nil)

    #expect(command.description == "scp one to remote host:two")
}

@Test("initializing a copy command with all options")
func copyCommandFullDeclarationTest() async throws {
    let command = CopyInto(
        location: "two", from: "one",
        retry: Backoff(maxRetries: 100, strategy: .fibonacci(maxDelay: .seconds(60))))
    #expect(command.from == "one")
    #expect(command.destinationPath == "two")
    #expect(command.env == nil)
    #expect(command.retry == Backoff(maxRetries: 100, strategy: .fibonacci(maxDelay: .seconds(60))))

    #expect(command.description == "scp one to remote host:two")
}

@Test("test invoking a copyInt command")
func testInvokingCopyIntoCommand() async throws {

    let testInvoker = TestCommandInvoker()

    let host = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess(
            dnsName: "somewhere.com", ipAddressesToUse: ["8.8.8.8"])
    } operation: {
        try await RemoteHost.resolve("somewhere.com")
    }

    let cmdOut = try await withDependencies {
        $0.commandInvoker = testInvoker
    } operation: {
        try await CopyInto(location: "/etc/configFile", from: "~/datafile").run(host: host, logger: nil)
    }

    #expect(cmdOut.returnCode == 0)
}
