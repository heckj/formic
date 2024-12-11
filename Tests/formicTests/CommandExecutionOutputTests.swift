import Testing

@testable import Formic

@Test("CommandExecutionOutput emoji")
func testEmojiForExecutionOuput() async throws {
    let cmd = Command.shell("uname")
    let cmdIgnoreFailure = Command.shell("uname", ignoreFailure: true)

    let successOutput = CommandOutput(returnCode: 0, stdOut: "Darwin\n".data(using: .utf8), stdErr: nil)
    let failureOutput = CommandOutput(returnCode: -1, stdOut: nil, stdErr: "I'm not telling you!\n".data(using: .utf8))

    #expect(
        CommandExecutionResult(
            command: cmd, host: .localhost, playbookId: nil, output: successOutput, duration: .milliseconds(1),
            retries: 0
        ).emojiString() == "✅")
    #expect(
        CommandExecutionResult(
            command: cmdIgnoreFailure, host: .localhost, playbookId: nil, output: failureOutput,
            duration: .milliseconds(1), retries: 0
        ).emojiString() == "⚠️")
    #expect(
        CommandExecutionResult(
            command: cmd, host: .localhost, playbookId: nil, output: failureOutput, duration: .milliseconds(1),
            retries: 0
        ).emojiString() == "❌")
}

@Test("CommandExecutionOutput consoleOutput")
func testConsoleOutputForExecutionOuput() async throws {
    let cmd = Command.shell("uname")
    let cmdIgnoreFailure = Command.shell("uname", ignoreFailure: true)

    let successOutput = CommandOutput(returnCode: 0, stdOut: "Darwin\n".data(using: .utf8), stdErr: nil)
    let failureOutput = CommandOutput(returnCode: -1, stdOut: nil, stdErr: "I'm not telling you!\n".data(using: .utf8))

    let successResult = CommandExecutionResult(
        command: cmd, host: .localhost, playbookId: nil, output: successOutput, duration: .milliseconds(1), retries: 0)

    let failureResult = CommandExecutionResult(
        command: cmd, host: .localhost, playbookId: nil, output: failureOutput, duration: .milliseconds(1), retries: 0)

    let ignoreFailureResult = CommandExecutionResult(
        command: cmdIgnoreFailure, host: .localhost, playbookId: nil, output: failureOutput, duration: .milliseconds(1),
        retries: 0)

    //TODO: This is probably more sanely refactored into parameterized tests

    // .silent
    #expect(successResult.consoleOutput(verbosity: .silent(emoji: true)) == "✅")
    #expect(successResult.consoleOutput(verbosity: .silent(emoji: false)) == "")

    #expect(failureResult.consoleOutput(verbosity: .silent(emoji: true)).contains("❌"))
    #expect(failureResult.consoleOutput(verbosity: .silent(emoji: true)).contains("-1"))
    #expect(failureResult.consoleOutput(verbosity: .silent(emoji: true)).contains("I'm not telling you!"))

    #expect(!failureResult.consoleOutput(verbosity: .silent(emoji: false)).contains("❌"))
    #expect(failureResult.consoleOutput(verbosity: .silent(emoji: false)).contains("-1"))
    #expect(failureResult.consoleOutput(verbosity: .silent(emoji: false)).contains("I'm not telling you!"))

    #expect(ignoreFailureResult.consoleOutput(verbosity: .silent(emoji: true)) == "⚠️")
    #expect(ignoreFailureResult.consoleOutput(verbosity: .silent(emoji: false)) == "")

    // .normal
    #expect(successResult.consoleOutput(verbosity: .normal(emoji: true)).contains("✅"))
    #expect(successResult.consoleOutput(verbosity: .normal(emoji: true)).contains("uname"))
    #expect(successResult.consoleOutput(verbosity: .normal(emoji: true)).contains("rc=0"))
    #expect(successResult.consoleOutput(verbosity: .normal(emoji: true)).contains("retries=0"))

    #expect(!successResult.consoleOutput(verbosity: .normal(emoji: false)).contains("✅"))
    #expect(successResult.consoleOutput(verbosity: .normal(emoji: false)).contains("uname"))
    #expect(successResult.consoleOutput(verbosity: .normal(emoji: false)).contains("rc=0"))
    #expect(successResult.consoleOutput(verbosity: .normal(emoji: false)).contains("retries=0"))

    #expect(failureResult.consoleOutput(verbosity: .normal(emoji: true)).contains("❌"))
    #expect(failureResult.consoleOutput(verbosity: .normal(emoji: true)).contains("uname"))
    #expect(failureResult.consoleOutput(verbosity: .normal(emoji: true)).contains("rc=-1"))
    #expect(failureResult.consoleOutput(verbosity: .normal(emoji: true)).contains("retries=0"))
    #expect(failureResult.consoleOutput(verbosity: .normal(emoji: true)).contains("I'm not telling you!"))

    #expect(!failureResult.consoleOutput(verbosity: .normal(emoji: false)).contains("❌"))
    #expect(failureResult.consoleOutput(verbosity: .normal(emoji: false)).contains("uname"))
    #expect(failureResult.consoleOutput(verbosity: .normal(emoji: false)).contains("rc=-1"))
    #expect(failureResult.consoleOutput(verbosity: .normal(emoji: false)).contains("retries=0"))
    #expect(failureResult.consoleOutput(verbosity: .normal(emoji: false)).contains("I'm not telling you!"))

    #expect(ignoreFailureResult.consoleOutput(verbosity: .normal(emoji: true)).contains("⚠️"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .normal(emoji: true)).contains("uname"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .normal(emoji: true)).contains("rc=-1"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .normal(emoji: true)).contains("retries=0"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .normal(emoji: true)).contains("I'm not telling you!"))

    #expect(!ignoreFailureResult.consoleOutput(verbosity: .normal(emoji: false)).contains("⚠️"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .normal(emoji: false)).contains("uname"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .normal(emoji: false)).contains("rc=-1"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .normal(emoji: false)).contains("retries=0"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .normal(emoji: false)).contains("I'm not telling you!"))

    // .verbose
    #expect(successResult.consoleOutput(verbosity: .verbose(emoji: true)).contains("✅"))
    #expect(successResult.consoleOutput(verbosity: .verbose(emoji: true)).contains("uname"))
    #expect(successResult.consoleOutput(verbosity: .verbose(emoji: true)).contains("rc=0"))
    #expect(successResult.consoleOutput(verbosity: .verbose(emoji: true)).contains("retries=0"))
    #expect(successResult.consoleOutput(verbosity: .verbose(emoji: true)).contains("Darwin"))

    #expect(!successResult.consoleOutput(verbosity: .verbose(emoji: false)).contains("✅"))
    #expect(successResult.consoleOutput(verbosity: .verbose(emoji: false)).contains("uname"))
    #expect(successResult.consoleOutput(verbosity: .verbose(emoji: false)).contains("rc=0"))
    #expect(successResult.consoleOutput(verbosity: .verbose(emoji: false)).contains("retries=0"))
    #expect(successResult.consoleOutput(verbosity: .verbose(emoji: true)).contains("Darwin"))

    #expect(failureResult.consoleOutput(verbosity: .verbose(emoji: true)).contains("❌"))
    #expect(failureResult.consoleOutput(verbosity: .verbose(emoji: true)).contains("uname"))
    #expect(failureResult.consoleOutput(verbosity: .verbose(emoji: true)).contains("rc=-1"))
    #expect(failureResult.consoleOutput(verbosity: .verbose(emoji: true)).contains("retries=0"))
    #expect(failureResult.consoleOutput(verbosity: .verbose(emoji: true)).contains("I'm not telling you!"))

    #expect(!failureResult.consoleOutput(verbosity: .verbose(emoji: false)).contains("❌"))
    #expect(failureResult.consoleOutput(verbosity: .verbose(emoji: false)).contains("uname"))
    #expect(failureResult.consoleOutput(verbosity: .verbose(emoji: false)).contains("rc=-1"))
    #expect(failureResult.consoleOutput(verbosity: .verbose(emoji: false)).contains("retries=0"))
    #expect(failureResult.consoleOutput(verbosity: .verbose(emoji: false)).contains("I'm not telling you!"))

    #expect(ignoreFailureResult.consoleOutput(verbosity: .verbose(emoji: true)).contains("⚠️"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .verbose(emoji: true)).contains("uname"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .verbose(emoji: true)).contains("rc=-1"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .verbose(emoji: true)).contains("retries=0"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .verbose(emoji: true)).contains("I'm not telling you!"))

    #expect(!ignoreFailureResult.consoleOutput(verbosity: .verbose(emoji: false)).contains("⚠️"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .verbose(emoji: false)).contains("uname"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .verbose(emoji: false)).contains("rc=-1"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .verbose(emoji: false)).contains("retries=0"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .verbose(emoji: false)).contains("I'm not telling you!"))

    // .debug
    #expect(successResult.consoleOutput(verbosity: .debug(emoji: true)).contains("✅"))
    #expect(successResult.consoleOutput(verbosity: .debug(emoji: true)).contains("uname"))
    #expect(successResult.consoleOutput(verbosity: .debug(emoji: true)).contains("rc=0"))
    #expect(successResult.consoleOutput(verbosity: .debug(emoji: true)).contains("retries=0"))
    #expect(successResult.consoleOutput(verbosity: .debug(emoji: true)).contains("Darwin"))

    #expect(!successResult.consoleOutput(verbosity: .debug(emoji: false)).contains("✅"))
    #expect(successResult.consoleOutput(verbosity: .debug(emoji: false)).contains("uname"))
    #expect(successResult.consoleOutput(verbosity: .debug(emoji: false)).contains("rc=0"))
    #expect(successResult.consoleOutput(verbosity: .debug(emoji: false)).contains("retries=0"))
    #expect(successResult.consoleOutput(verbosity: .debug(emoji: true)).contains("Darwin"))

    #expect(failureResult.consoleOutput(verbosity: .debug(emoji: true)).contains("❌"))
    #expect(failureResult.consoleOutput(verbosity: .debug(emoji: true)).contains("uname"))
    #expect(failureResult.consoleOutput(verbosity: .debug(emoji: true)).contains("rc=-1"))
    #expect(failureResult.consoleOutput(verbosity: .debug(emoji: true)).contains("retries=0"))
    #expect(failureResult.consoleOutput(verbosity: .debug(emoji: true)).contains("I'm not telling you!"))

    #expect(!failureResult.consoleOutput(verbosity: .debug(emoji: false)).contains("❌"))
    #expect(failureResult.consoleOutput(verbosity: .debug(emoji: false)).contains("uname"))
    #expect(failureResult.consoleOutput(verbosity: .debug(emoji: false)).contains("rc=-1"))
    #expect(failureResult.consoleOutput(verbosity: .debug(emoji: false)).contains("retries=0"))
    #expect(failureResult.consoleOutput(verbosity: .debug(emoji: false)).contains("I'm not telling you!"))

    #expect(ignoreFailureResult.consoleOutput(verbosity: .debug(emoji: true)).contains("⚠️"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .debug(emoji: true)).contains("uname"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .debug(emoji: true)).contains("rc=-1"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .debug(emoji: true)).contains("retries=0"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .debug(emoji: true)).contains("I'm not telling you!"))

    #expect(!ignoreFailureResult.consoleOutput(verbosity: .debug(emoji: false)).contains("⚠️"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .debug(emoji: false)).contains("uname"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .debug(emoji: false)).contains("rc=-1"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .debug(emoji: false)).contains("retries=0"))
    #expect(ignoreFailureResult.consoleOutput(verbosity: .debug(emoji: false)).contains("I'm not telling you!"))
}
