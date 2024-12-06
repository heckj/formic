import Dependencies
import Foundation
import Testing

@testable import Formic

@Test("test resource building blocks")
func testResourceBuildingBlocks() async throws {

    let shellResult = try withDependencies {
        $0.commandInvoker = TestCommandInvoker(command: ["uname"], presentOutput: "Linux\n")
    } operation: {
        try Command.run(host: .localhost, args: OperatingSystem.shellcommand)
    }

    // results proxied for a linux host
    #expect(shellResult.returnCode == 0)
    #expect(shellResult.stdoutString == "Linux\n")
    #expect(shellResult.stderrString == nil)

    let stdout = try #require(shellResult.stdoutString)
    let parsedOS = try OperatingSystem.parse(stdout)
    #expect(parsedOS == .linux)
}

@Test("test queried operating system")
func testOperatingSystemQuery() async throws {

    let (parsedOS, _) = try withDependencies {
        $0.commandInvoker = TestCommandInvoker(command: ["uname"], presentOutput: "Linux\n")
        $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
    } operation: {
        try OperatingSystem.queryState(from: .localhost)
    }

    #expect(parsedOS == .linux)
}
