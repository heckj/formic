import Foundation

/// SSH Credentials for accessing a remote host
struct SSHAccessCredentials {
    let username: String
    let identityFile: String
    
    init(username: String, identityFile: String) {
        self.username = username
        self.identityFile = identityFile
    }
    
    // TODO:
    // default identity file using FileManager - choose from what's available
    // default username from $USER in processInfo
}

struct Host {
    let os: OperatingSystem
    let remote: Bool
    // needed for remote access via SSH
    let address: NetworkAddress
    let port: Int
    let sshAccessCredentials: SSHAccessCredentials
}

struct OperatingSystem {
    static let ubuntu = "ubuntu"
}
