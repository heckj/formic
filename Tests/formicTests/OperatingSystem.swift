import Formic
import Testing

@Test("uname functional test")
func unameFunctionalTest() async throws {
    let shellResult = try Command.localShell("uname", returnStdOut: true, returnStdErr: true)
    #expect(shellResult.returnCode == 0)
    #expect(shellResult.stdoutString == "Darwin\n")
    #expect(shellResult.stderrString == nil)
    //    for aLine in shellResult.stdoutString!.split(separator: .newlineSequence) {
    //        print("==>\(aLine)<==")
    //    }
}
