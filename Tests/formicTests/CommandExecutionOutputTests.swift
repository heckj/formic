import Dependencies
import Testing

@testable import Formic

@Test("CommandExecutionOutput emoji")
func testEmojiForExecutionOuput() async throws {
    let cmd = ShellCommand("uname")
    let cmdIgnoreFailure = ShellCommand("uname", ignoreFailure: true)

    let successOutput = CommandOutput(returnCode: 0, stdOut: "Darwin\n".data(using: .utf8), stdErr: nil)
    let failureOutput = CommandOutput(returnCode: -1, stdOut: nil, stdErr: "I'm not telling you!\n".data(using: .utf8))

    let localhost: RemoteHost = try withDependencies {
        $0.localSystemAccess = TestFileSystemAccess()
    } operation: {
        try RemoteHost(RemoteHost.NetworkAddress.localhost)
    }

    #expect(
        CommandExecutionResult(
            command: cmd, host: localhost, output: successOutput, duration: .milliseconds(1),
            retries: 0, exception: nil
        ).emojiString() == "✅")
    #expect(
        CommandExecutionResult(
            command: cmdIgnoreFailure, host: localhost, output: failureOutput,
            duration: .milliseconds(1), retries: 0, exception: nil
        ).emojiString() == "⚠️")
    #expect(
        CommandExecutionResult(
            command: cmd, host: localhost, output: failureOutput, duration: .milliseconds(1),
            retries: 0, exception: nil
        ).emojiString() == "❌")
    #expect(
        CommandExecutionResult(
            command: cmd, host: localhost, output: failureOutput, duration: .milliseconds(1),
            retries: 0, exception: TestError.unknown(msg: "Error desc")

        ).emojiString() == "🚫")

}

@Test("CommandExecutionOutput consoleOutput")
func testConsoleOutputForExecutionOuput() async throws {
    let cmd = ShellCommand("uname")
    let cmdIgnoreFailure = ShellCommand("uname", ignoreFailure: true)

    let localhost: RemoteHost = try withDependencies {
        $0.localSystemAccess = TestFileSystemAccess()
    } operation: {
        try RemoteHost(RemoteHost.NetworkAddress.localhost)
    }

    let successOutput = CommandOutput(returnCode: 0, stdOut: "Darwin\n".data(using: .utf8), stdErr: nil)
    let failureOutput = CommandOutput(returnCode: -1, stdOut: nil, stdErr: "I'm not telling you!\n".data(using: .utf8))

    let successResult = CommandExecutionResult(
        command: cmd, host: localhost, output: successOutput, duration: .milliseconds(1), retries: 0,
        exception: nil)

    let failureResult = CommandExecutionResult(
        command: cmd, host: localhost, output: failureOutput, duration: .milliseconds(1), retries: 0,
        exception: nil)

    let ignoreFailureResult = CommandExecutionResult(
        command: cmdIgnoreFailure, host: localhost, output: failureOutput, duration: .milliseconds(1),
        retries: 0, exception: nil)

    let exceptionResult = CommandExecutionResult(
        command: cmd, host: localhost, output: failureOutput, duration: .milliseconds(1), retries: 0,
        exception: TestError.unknown(msg: "exception reported"))

    //TODO: This is probably more sanely refactored into parameterized tests

    // .silent
    #expect(successResult.consoleOutput(detailLevel: .silent(emoji: true)) == "✅")
    #expect(successResult.consoleOutput(detailLevel: .silent(emoji: false)) == "")

    #expect(failureResult.consoleOutput(detailLevel: .silent(emoji: true)).contains("❌"))
    #expect(failureResult.consoleOutput(detailLevel: .silent(emoji: true)).contains("-1"))
    #expect(failureResult.consoleOutput(detailLevel: .silent(emoji: true)).contains("I'm not telling you!"))

    #expect(!failureResult.consoleOutput(detailLevel: .silent(emoji: false)).contains("❌"))
    #expect(failureResult.consoleOutput(detailLevel: .silent(emoji: false)).contains("-1"))
    #expect(failureResult.consoleOutput(detailLevel: .silent(emoji: false)).contains("I'm not telling you!"))

    #expect(ignoreFailureResult.consoleOutput(detailLevel: .silent(emoji: true)) == "⚠️")
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .silent(emoji: false)) == "")

    #expect(exceptionResult.consoleOutput(detailLevel: .silent(emoji: true)).contains("🚫"))
    #expect(!exceptionResult.consoleOutput(detailLevel: .silent(emoji: false)).contains("🚫"))
    #expect(exceptionResult.consoleOutput(detailLevel: .silent(emoji: false)).contains("exception reported"))

    // .normal
    #expect(successResult.consoleOutput(detailLevel: .normal(emoji: true)).contains("✅"))
    #expect(successResult.consoleOutput(detailLevel: .normal(emoji: true)).contains("uname"))
    #expect(successResult.consoleOutput(detailLevel: .normal(emoji: true)).contains("rc=0"))
    #expect(successResult.consoleOutput(detailLevel: .normal(emoji: true)).contains("retries=0"))

    #expect(!successResult.consoleOutput(detailLevel: .normal(emoji: false)).contains("✅"))
    #expect(successResult.consoleOutput(detailLevel: .normal(emoji: false)).contains("uname"))
    #expect(successResult.consoleOutput(detailLevel: .normal(emoji: false)).contains("rc=0"))
    #expect(successResult.consoleOutput(detailLevel: .normal(emoji: false)).contains("retries=0"))
    #expect(successResult.consoleOutput(detailLevel: .normal(emoji: false)).contains("[00:00"))
    // duration marker

    #expect(failureResult.consoleOutput(detailLevel: .normal(emoji: true)).contains("❌"))
    #expect(failureResult.consoleOutput(detailLevel: .normal(emoji: true)).contains("uname"))
    #expect(failureResult.consoleOutput(detailLevel: .normal(emoji: true)).contains("rc=-1"))
    #expect(failureResult.consoleOutput(detailLevel: .normal(emoji: true)).contains("retries=0"))
    #expect(failureResult.consoleOutput(detailLevel: .normal(emoji: true)).contains("I'm not telling you!"))
    #expect(successResult.consoleOutput(detailLevel: .normal(emoji: true)).contains("[00:00"))
    // duration marker

    #expect(!failureResult.consoleOutput(detailLevel: .normal(emoji: false)).contains("❌"))
    #expect(failureResult.consoleOutput(detailLevel: .normal(emoji: false)).contains("uname"))
    #expect(failureResult.consoleOutput(detailLevel: .normal(emoji: false)).contains("rc=-1"))
    #expect(failureResult.consoleOutput(detailLevel: .normal(emoji: false)).contains("retries=0"))
    #expect(failureResult.consoleOutput(detailLevel: .normal(emoji: false)).contains("I'm not telling you!"))
    #expect(failureResult.consoleOutput(detailLevel: .normal(emoji: false)).contains("[00:00"))
    // duration marker

    #expect(ignoreFailureResult.consoleOutput(detailLevel: .normal(emoji: true)).contains("⚠️"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .normal(emoji: true)).contains("uname"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .normal(emoji: true)).contains("rc=-1"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .normal(emoji: true)).contains("retries=0"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .normal(emoji: true)).contains("I'm not telling you!"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .normal(emoji: true)).contains("[00:00"))
    // duration marker

    #expect(!ignoreFailureResult.consoleOutput(detailLevel: .normal(emoji: false)).contains("⚠️"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .normal(emoji: false)).contains("uname"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .normal(emoji: false)).contains("rc=-1"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .normal(emoji: false)).contains("retries=0"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .normal(emoji: false)).contains("I'm not telling you!"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .normal(emoji: false)).contains("[00:00"))
    // duration marker

    #expect(exceptionResult.consoleOutput(detailLevel: .normal(emoji: true)).contains("🚫"))
    #expect(exceptionResult.consoleOutput(detailLevel: .normal(emoji: true)).contains("exception reported"))
    #expect(exceptionResult.consoleOutput(detailLevel: .normal(emoji: true)).contains("[00:00"))
    // duration marker

    #expect(!exceptionResult.consoleOutput(detailLevel: .normal(emoji: false)).contains("🚫"))
    #expect(exceptionResult.consoleOutput(detailLevel: .normal(emoji: false)).contains("exception reported"))
    #expect(exceptionResult.consoleOutput(detailLevel: .normal(emoji: false)).contains("[00:00"))
    // duration marker

    // .verbose
    #expect(successResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("✅"))
    #expect(successResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("uname"))
    #expect(successResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("rc=0"))
    #expect(successResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("retries=0"))
    #expect(successResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("Darwin"))
    #expect(successResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("[00:00"))
    // duration marker

    #expect(!successResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("✅"))
    #expect(successResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("uname"))
    #expect(successResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("rc=0"))
    #expect(successResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("retries=0"))
    #expect(successResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("Darwin"))
    #expect(successResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("[00:00"))
    // duration marker

    #expect(failureResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("❌"))
    #expect(failureResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("uname"))
    #expect(failureResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("rc=-1"))
    #expect(failureResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("retries=0"))
    #expect(failureResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("I'm not telling you!"))
    #expect(failureResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("[00:00"))
    // duration marker

    #expect(!failureResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("❌"))
    #expect(failureResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("uname"))
    #expect(failureResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("rc=-1"))
    #expect(failureResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("retries=0"))
    #expect(failureResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("I'm not telling you!"))
    #expect(failureResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("[00:00"))
    // duration marker

    #expect(ignoreFailureResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("⚠️"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("uname"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("rc=-1"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("retries=0"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("I'm not telling you!"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("[00:00"))
    // duration marker

    #expect(!ignoreFailureResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("⚠️"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("uname"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("rc=-1"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("retries=0"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("I'm not telling you!"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("[00:00"))
    // duration marker

    #expect(exceptionResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("🚫"))
    #expect(exceptionResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("exception reported"))
    #expect(exceptionResult.consoleOutput(detailLevel: .verbose(emoji: true)).contains("[00:00"))
    // duration marker

    #expect(!exceptionResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("🚫"))
    #expect(exceptionResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("exception reported"))
    #expect(exceptionResult.consoleOutput(detailLevel: .verbose(emoji: false)).contains("[00:00"))
    // duration marker

    // .debug
    #expect(successResult.consoleOutput(detailLevel: .debug(emoji: true)).contains("✅"))
    #expect(successResult.consoleOutput(detailLevel: .debug(emoji: true)).contains("uname"))
    #expect(successResult.consoleOutput(detailLevel: .debug(emoji: true)).contains("rc=0"))
    #expect(successResult.consoleOutput(detailLevel: .debug(emoji: true)).contains("retries=0"))
    #expect(successResult.consoleOutput(detailLevel: .debug(emoji: true)).contains("Darwin"))
    #expect(successResult.consoleOutput(detailLevel: .debug(emoji: true)).contains("[00:00"))
    // duration marker

    #expect(!successResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("✅"))
    #expect(successResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("uname"))
    #expect(successResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("rc=0"))
    #expect(successResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("retries=0"))
    #expect(successResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("Darwin"))
    #expect(successResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("[00:00"))
    // duration marker

    #expect(failureResult.consoleOutput(detailLevel: .debug(emoji: true)).contains("❌"))
    #expect(failureResult.consoleOutput(detailLevel: .debug(emoji: true)).contains("uname"))
    #expect(failureResult.consoleOutput(detailLevel: .debug(emoji: true)).contains("rc=-1"))
    #expect(failureResult.consoleOutput(detailLevel: .debug(emoji: true)).contains("retries=0"))
    #expect(failureResult.consoleOutput(detailLevel: .debug(emoji: true)).contains("I'm not telling you!"))
    #expect(failureResult.consoleOutput(detailLevel: .debug(emoji: true)).contains("[00:00"))
    // duration marker

    #expect(!failureResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("❌"))
    #expect(failureResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("uname"))
    #expect(failureResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("rc=-1"))
    #expect(failureResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("retries=0"))
    #expect(failureResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("I'm not telling you!"))
    #expect(failureResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("[00:00"))
    // duration marker

    #expect(ignoreFailureResult.consoleOutput(detailLevel: .debug(emoji: true)).contains("⚠️"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .debug(emoji: true)).contains("uname"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .debug(emoji: true)).contains("rc=-1"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .debug(emoji: true)).contains("retries=0"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .debug(emoji: true)).contains("I'm not telling you!"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("[00:00"))
    // duration marker

    #expect(!ignoreFailureResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("⚠️"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("uname"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("rc=-1"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("retries=0"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("I'm not telling you!"))
    #expect(ignoreFailureResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("[00:00"))
    // duration marker

    #expect(exceptionResult.consoleOutput(detailLevel: .debug(emoji: true)).contains("🚫"))
    #expect(exceptionResult.consoleOutput(detailLevel: .debug(emoji: true)).contains("exception reported"))
    #expect(exceptionResult.consoleOutput(detailLevel: .debug(emoji: true)).contains("[00:00"))
    // duration marker

    #expect(!exceptionResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("🚫"))
    #expect(exceptionResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("exception reported"))
    #expect(exceptionResult.consoleOutput(detailLevel: .debug(emoji: false)).contains("[00:00"))
    // duration marker
}
