import Formic
import Foundation
import Testing

@Test("initializing a generic AnyCommand")
func anyCommandInit() async throws {
    let command = AnyCommand(name: "myName", ignoreFailure: false, retry: .never, executionTimeout: .seconds(60)) { _ in
        return CommandOutput.generalSuccess(msg: "done")
    }

    #expect(command.ignoreFailure == false)
    #expect(command.retry == .never)
    #expect(command.description == "myName")

    let output = try await command.run(host: .localhost)
    #expect(output.returnCode == 0)
    #expect(output.stdoutString == "done")
}
