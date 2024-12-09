import AsyncDNSResolver
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
