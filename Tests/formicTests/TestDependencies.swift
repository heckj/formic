import Dependencies
import Foundation

@testable import Formic

struct TestCommandInvoker: CommandInvoker {
    func remoteCopy(
        host: String, user: String, identityFile: String?, port: Int?, strictHostKeyChecking: Bool, localPath: String,
        remotePath: String
    ) throws -> Formic.CommandOutput {
        return CommandOutput(returnCode: 0, stdOut: "".data(using: .utf8), stdErr: nil)
    }

    var proxyResults: [[String]: CommandOutput]
    func remoteShell(
        host: String, user: String, identityFile: String?, port: Int?, strictHostKeyChecking: Bool, cmd: [String],
        env: [String: String]?
    ) throws -> Formic.CommandOutput {
        if let storedResponse = proxyResults[cmd] {
            return storedResponse
        }
        // default to a null, success response
        return CommandOutput(returnCode: 0, stdOut: "".data(using: .utf8), stdErr: nil)
    }

    func localShell(cmd: [String], stdIn: Pipe?, env: [String: String]?) throws -> Formic.CommandOutput {
        if let storedResponse = proxyResults[cmd] {
            return storedResponse
        }
        // default to a null, success response
        return CommandOutput(returnCode: 0, stdOut: "".data(using: .utf8), stdErr: nil)
    }

    init(_ outputs: [[String]: CommandOutput]? = nil) {
        if let outputs {
            self.proxyResults = outputs
        } else {
            proxyResults = [:]
        }
    }

    init(command: [String], presentOutput: String) {
        self.proxyResults = [
            command: CommandOutput(returnCode: 0, stdOut: presentOutput.data(using: .utf8), stdErr: nil)
        ]
    }

    func addSuccess(command: [String], presentOutput: String) -> Self {
        var existingResult = proxyResults
        existingResult[command] = CommandOutput(
            returnCode: 0,
            stdOut: presentOutput.data(using: .utf8),
            stdErr: nil)
        return TestCommandInvoker(existingResult)
    }

    func addFailure(command: [String], presentOutput: String, returnCode: Int32 = -1) -> Self {
        var existingResult = proxyResults
        existingResult[command] = CommandOutput(
            returnCode: returnCode,
            stdOut: nil,
            stdErr:
                presentOutput.data(using: .utf8))
        return TestCommandInvoker(existingResult)
    }
}
