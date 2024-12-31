import AsyncDNSResolver
import Dependencies
import Foundation

@testable import Formic

struct TestCommandInvoker: CommandInvoker {

    func getDataAtURL(url: URL) async throws -> Data {
        if let data = proxyData[url] {
            return data
        } else {
            guard let sampleData = "SAMPLE".data(using: .utf8) else {
                fatalError("Some whack error converting a string into data.")
            }
            return sampleData
        }
    }

    // proxyResults is keyed by arguments, returns a tuple of seconds delay to apply, then the result
    var proxyResults: [[String]: (Duration, CommandOutput)]
    var proxyErrors: [[String]: (any Error)]
    var proxyData: [URL: Data]

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
        host: String, user: String, identityFile: String?, port: Int?, strictHostKeyChecking: Bool, chdir: String?,
        cmd: [String], env: [String: String]?, debugPrint: Bool
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

    func localShell(cmd: [String], stdIn: Pipe?, env: [String: String]?, chdir: String?, debugPrint: Bool) async throws
        -> Formic.CommandOutput
    {
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

    init(
        _ outputs: [[String]: (Duration, CommandOutput)],
        _ errors: [[String]: (any Error)],
        _ data: [URL: Data]
    ) {
        proxyResults = outputs
        proxyErrors = errors
        proxyData = data
    }

    init() {
        proxyResults = [:]
        proxyErrors = [:]
        proxyData = [:]
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
        return TestCommandInvoker(existingResult, proxyErrors, proxyData)
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
        return TestCommandInvoker(existingResult, proxyErrors, proxyData)
    }

    func addException(command: [String], errorToThrow: (any Error)) -> Self {
        var existingErrors = proxyErrors
        existingErrors[command] = errorToThrow
        return TestCommandInvoker(proxyResults, existingErrors, proxyData)
    }

    func addData(url: URL, data: Data?) -> Self {
        guard let data = data else {
            return self
        }
        var existingData = proxyData
        existingData[url] = data
        return TestCommandInvoker(proxyResults, proxyErrors, existingData)
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
