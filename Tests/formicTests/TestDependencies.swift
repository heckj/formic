import AsyncDNSResolver
import Dependencies
import Foundation

@testable import Formic

struct TestCommandInvoker: CommandInvoker {
    // proxyResults is keyed by arguments, returns a tuple of seconds delay to apply, then the result
    var proxyResults: [[String]: (Duration, CommandOutput)]
    var proxyErrors: [[String]: (any Error)]

    func remoteCopy(
        host: String, user: String, identityFile: String?, port: Int?, strictHostKeyChecking: Bool, localPath: String,
        remotePath: String
    ) async throws -> Formic.CommandOutput {
        if let errorToThrow = proxyErrors[[localPath, remotePath]] {
            throw errorToThrow
        }
        if let (delay, storedResponse) = proxyResults[[localPath, remotePath]] {
            try await Task.sleep(for: delay)
            return storedResponse
        }
        return CommandOutput(returnCode: 0, stdOut: "".data(using: .utf8), stdErr: nil)
    }

    func remoteShell(
        host: String, user: String, identityFile: String?, port: Int?, strictHostKeyChecking: Bool, cmd: [String],
        env: [String: String]?
    ) async throws -> Formic.CommandOutput {
        if let errorToThrow = proxyErrors[cmd] {
            throw errorToThrow
        }
        if let (delay, storedResponse) = proxyResults[cmd] {
            try await Task.sleep(for: delay)
            return storedResponse
        }
        // default to a null, success response
        return CommandOutput(returnCode: 0, stdOut: "".data(using: .utf8), stdErr: nil)
    }

    func localShell(cmd: [String], stdIn: Pipe?, env: [String: String]?) async throws -> Formic.CommandOutput {
        if let (delay, storedResponse) = proxyResults[cmd] {
            try await Task.sleep(for: delay)
            return storedResponse
        }
        // default to a null, success response
        return CommandOutput(returnCode: 0, stdOut: "".data(using: .utf8), stdErr: nil)
    }

    init(_ outputs: [[String]: (Duration, CommandOutput)]? = nil, _ errors: [[String]: (any Error)]? = nil) {
        if let outputs {
            self.proxyResults = outputs
        } else {
            proxyResults = [:]
        }
        if let errors {
            self.proxyErrors = errors
        } else {
            proxyErrors = [:]
        }
    }

    init() {
        proxyResults = [:]
        proxyErrors = [:]
    }

    func addSuccess(command: [String], presentOutput: String, delay: Duration = .zero) -> Self {
        var existingResult = proxyResults
        existingResult[command] = (
            delay,
            CommandOutput(
                returnCode: 0,
                stdOut: presentOutput.data(using: .utf8),
                stdErr: nil)
        )
        return TestCommandInvoker(existingResult, proxyErrors)
    }

    func addFailure(command: [String], presentOutput: String, delay: Duration = .zero, returnCode: Int32 = -1) -> Self {
        var existingResult = proxyResults
        existingResult[command] = (
            delay,
            CommandOutput(
                returnCode: returnCode,
                stdOut: nil,
                stdErr:
                    presentOutput.data(using: .utf8))
        )
        return TestCommandInvoker(existingResult, proxyErrors)
    }

    func throwError(command: [String], errorToThrow: (any Error)) -> Self {
        var existingErrors = proxyErrors
        existingErrors[command] = errorToThrow
        return TestCommandInvoker(proxyResults, existingErrors)
    }
}

struct TestFileSystemAccess: LocalSystemAccess {

    enum SSHId {
        case rsa
        case dsa
        case ed25519
    }
    let sshIDToMatch: SSHId
    let mockDNSresolution: [String: [String]]

    func fileExists(atPath: String) -> Bool {
        switch sshIDToMatch {
        case .rsa:
            atPath.contains("id_rsa")
        case .dsa:
            atPath.contains("id_dsa")
        case .ed25519:
            atPath.contains("id_ed25519")
        }
    }
    let homeDirectory: URL = URL(filePath: "/home/docker-user")
    let username: String? = "docker-user"
    func queryA(name: String) async throws -> [ARecord] {
        if let returnValues = mockDNSresolution[name] {
            return returnValues.map { ARecord(address: .init(address: $0), ttl: 999) }
        } else {
            return []
        }
    }

    init(sshIdMatch: SSHId = .dsa) {
        sshIDToMatch = sshIdMatch
        mockDNSresolution = [:]
    }

    init(dnsName: String, ipAddressesToUse: [String], sshIdMatch: SSHId = .dsa) {
        mockDNSresolution = [dnsName: ipAddressesToUse]
        sshIDToMatch = sshIdMatch
    }
}

/// An error for testing error handling.
public enum TestError: LocalizedError {
    case unknown(msg: String)

    /// The localized description.
    public var errorDescription: String? {
        switch self {
        case .unknown(let msg):
            "Unknown error: \(msg)"
        }
    }
}
