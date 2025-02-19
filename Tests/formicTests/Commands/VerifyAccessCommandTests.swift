import Dependencies
import Foundation
import Testing

@testable import Formic

@Test("test invoking a verify access command with failure response")
func testInvokingVerifyAccessFail() async throws {

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
        try await VerifyAccess().run(host: host, logger: nil)
    }
    #expect(cmdOut.stderrString == "Unable to verify access.")
    #expect(cmdOut.returnCode == -1)
}

@Test("test invoking a verify access command success")
func testInvokingVerifyAccessSuccess() async throws {

    let testInvoker = TestCommandInvoker()

    let host = try await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess(
            dnsName: "somewhere.com", ipAddressesToUse: ["8.8.8.8"])
    } operation: {
        try await RemoteHost.resolve("somewhere.com")
    }

    let cmdOut = try await withDependencies {
        $0.commandInvoker = testInvoker.addSuccess(command: "echo 'hello'", presentOutput: "hello\n")
    } operation: {
        try await VerifyAccess().run(host: host, logger: nil)
    }
    #expect(cmdOut.stdoutString == "hello")
    #expect(cmdOut.returnCode == 0)
}
