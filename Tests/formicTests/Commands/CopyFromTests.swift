import Dependencies
import Foundation
import Testing

@testable import Formic

@Test("initializing a copy command")
func copyFromCommandDeclarationTest() async throws {

    let url: URL = try #require(URL(string: "http://somehost.com/datafile"))
    let command = CopyFrom(location: "/dest/path", from: url)
    #expect(command.retry == .never)
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
        retry: Backoff(maxRetries: 100, strategy: .fibonacci(maxDelay: .seconds(60))))
    #expect(command.from == url)
    #expect(command.destinationPath == "/dest/path")
    #expect(command.env == nil)
    #expect(command.retry == Backoff(maxRetries: 100, strategy: .fibonacci(maxDelay: .seconds(60))))

    #expect(command.description == "scp http://somehost.com/datafile to remote host:/dest/path")
}

@Test("test invoking a copyFrom command")
func testInvokingCopyFromCommand() async throws {

    let url: URL = try #require(URL(string: "http://somewhere.com/datafile"))
    let testInvoker = TestCommandInvoker()
        .addData(url: url, data: "file contents".data(using: .utf8))

    let host = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess(
            dnsName: "somewhere.com", ipAddressesToUse: ["8.8.8.8"])
    } operation: {
        try await Host.resolve("somewhere.com")
    }

    let cmdOut = try await withDependencies {
        $0.commandInvoker = testInvoker
    } operation: {
        try await CopyFrom(location: "/dest/path", from: url).run(host: host)
    }

    #expect(cmdOut.returnCode == 0)
}
