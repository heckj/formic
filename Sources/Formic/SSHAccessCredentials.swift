import Dependencies
import Foundation

extension Host {

    // This loosely represents a username and credentials, built for pass through to a command
    // line version of `ssh` to invoke remote commands. Citadel SSH provides an API that requires
    // a bit more detail about credentials, as it wants (needs) to know the specific kind of key
    // (rsa vs dsa vs ed25519, etc) and loads the key into memory in order to pass it to the remote
    // SSH server for authentication.

    // If we want to leverage (or base more of the interactions) using Citadel SSH, this API
    // probably needs to get updated to encapsulate the kind of key that was loaded by
    // default. Currently, it tries to match how `ssh` on the CLI automatically looks for keys
    // in the .ssh directory).

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
                    msg.append(
                        "A local SSH identity file could not be determined as a default to access a remote host. ")
                }
                throw CommandError.missingSSHAccessCredentials(msg: msg)
            }
        }
    }
}

extension Host.SSHAccessCredentials: Hashable {}
extension Host.SSHAccessCredentials: Codable {}
