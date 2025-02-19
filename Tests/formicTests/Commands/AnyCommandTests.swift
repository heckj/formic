import Dependencies
import Foundation
import Testing

@testable import Formic

@Test("initializing a generic AnyCommand")
func anyCommandInit() async throws {
    let command = AnyCommand(name: "myName", ignoreFailure: false, retry: .never, executionTimeout: .seconds(60)) {
        _, _ in
        return CommandOutput.generalSuccess(msg: "done")
    }

    #expect(command.ignoreFailure == false)
    #expect(command.retry == .never)
    #expect(command.description == "myName")

    let localhost: RemoteHost = try withDependencies {
        $0.localSystemAccess = TestFileSystemAccess()
    } operation: {
        try RemoteHost(RemoteHost.NetworkAddress.localhost)
    }

    let output = try await command.run(host: localhost, logger: nil)
    #expect(output.returnCode == 0)
    #expect(output.stdoutString == "done")
}

@Test("hashable AnyCommand")
func anyCommandHashEquatable() async throws {
    let command1 = AnyCommand(name: "myName", ignoreFailure: false, retry: .never, executionTimeout: .seconds(60)) {
        _, _ in
        return CommandOutput.generalSuccess(msg: "done")
    }

    let command2 = AnyCommand(name: "myName", ignoreFailure: true, retry: .default, executionTimeout: .seconds(60)) {
        _, _ in
        return CommandOutput.generalSuccess(msg: "done")
    }

    let command3 = AnyCommand(name: "myName", ignoreFailure: true, retry: .default, executionTimeout: .seconds(60)) {
        _, _ in
        return CommandOutput.generalSuccess(msg: "yep")
    }

    #expect(command1 != command2)
    #expect(command1.hashValue != command2.hashValue)

    // only because "ID" inside is different
    #expect(command2.hashValue != command3.hashValue)
}
