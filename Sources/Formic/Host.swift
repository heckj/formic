import Foundation

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
