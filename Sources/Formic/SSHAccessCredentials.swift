import Dependencies
import Foundation

/// SSH Credentials for accessing a remote host.
public struct SSHAccessCredentials: Sendable {
    public let username: String
    public let identityFile: String

    public init(username: String, identityFile: String) {
        self.username = username
        self.identityFile = identityFile
    }

    private static func defaultUsername() -> String? {
        @Dependency(\.localSystemAccess) var localHostAccess: any LocalSystemAccess
        return localHostAccess.username
    }

    private static func defaultIdentityFilePath() -> String? {
        @Dependency(\.localSystemAccess) var localHostAccess: any LocalSystemAccess

        let homeDirectory = localHostAccess.homeDirectory
        let rsaPath = homeDirectory.appendingPathComponent(".ssh/id_rsa").path
        if localHostAccess.fileExists(atPath: rsaPath) {
            return rsaPath
        }
        let dsaPath = homeDirectory.appendingPathComponent(".ssh/id_dsa").path
        if localHostAccess.fileExists(atPath: dsaPath) {
            return dsaPath
        }
        let ed25519Path = homeDirectory.appendingPathComponent(".ssh/id_ed25519").path
        if localHostAccess.fileExists(atPath: ed25519Path) {
            return ed25519Path
        }
        return nil
    }

    public init(username: String? = nil, identityFile: String? = nil) throws {
        let username = username ?? Self.defaultUsername()
        let identityFile = identityFile ?? Self.defaultIdentityFilePath()

        if let username = username, let identityFile = identityFile {
            self.init(username: username, identityFile: identityFile)
        } else {
            var msg: String = ""
            if username == nil {
                msg.append("The local username could not be determined as a default to access a remote host. ")
            }
            if identityFile == nil {
                msg.append("A local SSH identity file could not be determined as a default to access a remote host. ")
            }
            throw CommandError.missingSSHAccessCredentials(msg: msg)
        }
    }
}

// MARK: dependency injection protocol and redirection

// docs: https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies

protocol LocalSystemAccess: Sendable {
    var username: String? { get }
    var homeDirectory: URL { get }
    func fileExists(atPath: String) -> Bool
}

struct LiveLocalSystemAccess: LocalSystemAccess {
    let username = ProcessInfo.processInfo.environment["USER"]
    let homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    func fileExists(atPath: String) -> Bool {
        FileManager.default.fileExists(atPath: atPath)
    }
}

// register the dependency
private enum LocalSystemAccessKey: DependencyKey {
    static let liveValue: any LocalSystemAccess = LiveLocalSystemAccess()
}

extension DependencyValues {
    var localSystemAccess: LocalSystemAccess {
        get { self[LocalSystemAccessKey.self] }
        set { self[LocalSystemAccessKey.self] = newValue }
    }
}