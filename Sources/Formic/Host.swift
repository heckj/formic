import ArgumentParser
import Foundation

/// A local or remote host.
public struct Host: Sendable {
    let remote: Bool
    // needed for remote access via SSH
    public let networkAddress: NetworkAddress
    public let sshPort: Int
    public let sshAccessCredentials: SSHAccessCredentials

    /// A host reference to localhost.
    public static let localhost = Host(
        remote: false, address: .localhost, sshPort: 22,
        sshAccessCredentials: SSHAccessCredentials(username: "", identityFile: ""))

    init(remote: Bool, address: NetworkAddress, sshPort: Int, sshAccessCredentials: SSHAccessCredentials) {
        self.remote = remote
        self.networkAddress = address
        self.sshPort = sshPort
        self.sshAccessCredentials = sshAccessCredentials
    }

    /// Creates a new host without attempting DNS resolution.
    /// - Parameters:
    ///   - name: The network address of the host.
    ///   - sshPort: the ssh port, defaults to `22`.
    ///   - sshUser: the ssh user, defaults to the username of the current user.
    ///   - sshIdentityFile: The ssh identity file, defaults to standard key locations for ssh.
    public init?(_ name: String, sshPort: Int = 22, sshUser: String? = nil, sshIdentityFile: String? = nil) throws {
        let creds = try SSHAccessCredentials(username: sshUser, identityFile: sshIdentityFile)
        if let address = NetworkAddress(name) {
            self.init(remote: false, address: address, sshPort: sshPort, sshAccessCredentials: creds)
        }
        return nil
    }

    /// Creates a new host using DNS name resolution.
    /// - Parameters:
    ///   - name: The DNS name or network address of the host.
    ///   - sshPort: the ssh port, defaults to `22`.
    ///   - sshUser: the ssh user, defaults to the username of the current user.
    ///   - sshIdentityFile: The ssh identity file, defaults to standard key locations for ssh.
    public static func resolve(
        _ name: String, sshPort: Int = 22, sshUser: String? = nil, sshIdentityFile: String? = nil
    ) async throws -> Host {
        let creds = try SSHAccessCredentials(username: sshUser, identityFile: sshIdentityFile)
        if let address = await NetworkAddress.resolve(name) {
            return Host(remote: false, address: address, sshPort: sshPort, sshAccessCredentials: creds)
        } else {
            throw CommandError.failedToResolveHost(name: name)
        }
    }
}

extension Host: CustomStringConvertible {
    /// The description of the host.
    public var description: String {
        if remote {
            return "\(self.sshAccessCredentials.username)@\(networkAddress)"
        } else {
            return "localhost"
        }
    }
}

extension Host: ExpressibleByArgument {
    /// Creates a new host from a string.
    /// - Parameter argument: The argument to parse as a host.
    public init?(argument: String) {
        try? self.init(argument)
    }
}
