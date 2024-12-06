import Formic
import Foundation
import Testing

@Test(
    "uname functional test",
    .enabled(if: ProcessInfo.processInfo.environment.keys.contains("CI")),
    .timeLimit(.minutes(1)),
    .tags(.functionalTest))
func unameFunctionalTest() async throws {
    let shellResult = try Command.run(host: .localhost, args: ["uname"])

    // results expected on a Linux host only
    #expect(shellResult.returnCode == 0)
    #expect(shellResult.stdoutString == "Linux\n")
    #expect(shellResult.stderrString == nil)
}
