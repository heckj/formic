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
