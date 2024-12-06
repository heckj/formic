import Dependencies
import Foundation
import Testing

@testable import Formic

@Test("command run uname")
func unameFunctionalTest() async throws {

    let shellResult = try withDependencies {
        $0.commandInvoker = TestCommandInvoker(command: ["uname"], presentOutput: "Linux\n")
    } operation: {
        try Command.run(host: .localhost, args: ["uname"])
    }

    // results expected on a Linux host only
    #expect(shellResult.returnCode == 0)
    #expect(shellResult.stdoutString == "Linux\n")
    #expect(shellResult.stderrString == nil)
}
