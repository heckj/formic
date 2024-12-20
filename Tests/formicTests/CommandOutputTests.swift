import Testing

@testable import Formic

@Test("CommandOutput initializer")
func initCommandOutput() async throws {
    let output = CommandOutput(
        returnCode: 0,
        stdOut: "Darwin\n".data(using: .utf8),
        stdErr: nil
    )
    #expect(output.returnCode == 0)
    #expect(output.stdoutString == "Darwin\n")
    #expect(output.stderrString == nil)
}

@Test("CommandOutput builtins")
func testCommandOutputBuiltins() async throws {
    #expect(CommandOutput.empty.returnCode == 0)
    #expect(CommandOutput.empty.stdoutString == nil)
    #expect(CommandOutput.empty.stderrString == nil)

    #expect(CommandOutput.generalFailure(msg: "A").returnCode == -1)
    #expect(CommandOutput.generalFailure(msg: "A").stdoutString == nil)
    #expect(CommandOutput.generalFailure(msg: "A").stderrString == "A")

    #expect(CommandOutput.generalSuccess(msg: "A").returnCode == 0)
    #expect(CommandOutput.generalSuccess(msg: "A").stdoutString == "A")
    #expect(CommandOutput.generalSuccess(msg: "A").stderrString == nil)

}
