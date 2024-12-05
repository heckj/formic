import Foundation

/// SSH Credentials for accessing a remote host.
public struct SSHAccessCredentials {
    public let username: String
    public let identityFile: String

    public init(username: String, identityFile: String) {
        self.username = username
        self.identityFile = identityFile
    }

    private static func defaultUsername() -> String? {
        return ProcessInfo.processInfo.environment["USER"]
    }

    private static func defaultIdentityFilePath() -> String? {
        let homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
        let rsaPath = homeDirectory.appendingPathComponent(".ssh/id_rsa").path
        if FileManager.default.fileExists(atPath: rsaPath) {
            return rsaPath
        }
        let dsaPath = homeDirectory.appendingPathComponent(".ssh/id_dsa").path
        if FileManager.default.fileExists(atPath: dsaPath) {
            return dsaPath
        }
        let ed25519Path = homeDirectory.appendingPathComponent(".ssh/id_ed25519").path
        if FileManager.default.fileExists(atPath: ed25519Path) {
            return ed25519Path
        }
        return nil
    }

    public init?(username: String) {
        if let identityFile = Self.defaultIdentityFilePath() {
            self.username = username
            self.identityFile = identityFile
        }
        return nil
    }

    public init?(identityFile: String) {
        if let username = Self.defaultUsername() {
            self.username = username
            self.identityFile = identityFile
            return
        }
        return nil
    }

    public init?() {
        if let identityFile = Self.defaultIdentityFilePath(),
            let username = Self.defaultUsername()
        {
            self.username = username
            self.identityFile = identityFile
            return
        }
        return nil
    }
}
