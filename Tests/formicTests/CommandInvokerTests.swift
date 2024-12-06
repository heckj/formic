import Foundation
import Testing

@testable import Formic

@Test(
    "invoking a command",
    .enabled(if: ProcessInfo.processInfo.environment.keys.contains("CI")),
    .timeLimit(.minutes(1)),
    .tags(.functionalTest))
func invokeBasicCommandLocally() async throws {
    let shellResult = try ProcessCommandInvoker().localShell(cmd: ["uname"], stdIn: nil, env: nil)

    // results expected on a Linux host only
    #expect(shellResult.returnCode == 0)
    #expect(shellResult.stdoutString == "Linux\n")
    #expect(shellResult.stderrString == nil)
}
