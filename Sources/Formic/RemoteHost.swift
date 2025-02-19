import ArgumentParser
import Foundation

/// A local or remote host.
public struct RemoteHost: Sendable {
    /// The network address.
    public let networkAddress: NetworkAddress
    /// The port to use for SSH access.
    public let sshPort: Int
    /// The credentials to use for SSH access.
    public let sshAccessCredentials: SSHAccessCredentials
    /// A Boolean value that indicates whether to enable strict host checking during SSH connections.
    public let strictHostKeyChecking: Bool

    init(
        address: NetworkAddress, sshPort: Int, sshAccessCredentials: SSHAccessCredentials,
        strictHostKeyChecking: Bool
    ) {
        self.networkAddress = address
        self.sshPort = sshPort
        self.sshAccessCredentials = sshAccessCredentials
        self.strictHostKeyChecking = strictHostKeyChecking
    }

    /// Creates a new host without attempting DNS resolution.
    ///
    /// The initializer may return nil if the name isn't a valid network address.
    /// Use the name `localhost` to ensure all commands are run locally.
    /// Use the name `127.0.0.1` to access a remote host through a port forwarding setup.
    ///
    /// - Parameters:
    ///   - name: The network address of the host.
    ///   - sshPort: the ssh port, defaults to `22`.
    ///   - sshUser: the ssh user, defaults to the username of the current user.
    ///   - sshIdentityFile: The ssh identity file, defaults to standard key locations for ssh.
    ///   - strictHostKeyChecking: A Boolean value that indicates whether to enable strict host checking during SSH connections.
    public init?(
        _ name: String, sshPort: Int = 22, sshUser: String? = nil, sshIdentityFile: String? = nil,
        strictHostKeyChecking: Bool = false
    ) throws {
        let creds = try SSHAccessCredentials(username: sshUser, identityFile: sshIdentityFile)
        if let address = NetworkAddress(name) {
            if name == "localhost" {
                self.init(
                    address: address, sshPort: sshPort, sshAccessCredentials: creds,
                    strictHostKeyChecking: strictHostKeyChecking)
            } else {
                self.init(
                    address: address, sshPort: sshPort, sshAccessCredentials: creds,
                    strictHostKeyChecking: strictHostKeyChecking)
            }
        } else {
            return nil
        }
    }

    /// Creates a new host using the NetworkAddress you provide.
    ///
    /// Use the name `localhost` to ensure all commands are run locally.
    /// Use the name `127.0.0.1` to access a remote host through port forwarding.
    ///
    /// - Parameters:
    ///   - networkAddress: The network address of the host.
    ///   - sshPort: the ssh port, defaults to `22`.
    ///   - sshUser: the ssh user, defaults to the username of the current user.
    ///   - sshIdentityFile: The ssh identity file, defaults to standard key locations for ssh.
    ///   - strictHostKeyChecking: A Boolean value that indicates whether to enable strict host checking during SSH connections.
    public init(
        _ networkAddress: NetworkAddress,
        sshPort: Int = 22,
        sshUser: String? = nil,
        sshIdentityFile: String? = nil,
        strictHostKeyChecking: Bool = false
    ) throws {
        let creds = try SSHAccessCredentials(username: sshUser, identityFile: sshIdentityFile)
        if networkAddress.dnsName == "localhost" {
            self.init(
                address: networkAddress, sshPort: sshPort, sshAccessCredentials: creds,
                strictHostKeyChecking: strictHostKeyChecking)
        } else {
            self.init(
                address: networkAddress, sshPort: sshPort, sshAccessCredentials: creds,
                strictHostKeyChecking: strictHostKeyChecking)
        }
    }

    /// Creates a new host using DNS name resolution.
    ///
    /// - Parameters:
    ///   - name: The DNS name or network address of the host.
    ///   - sshPort: the ssh port, defaults to `22`.
    ///   - sshUser: the ssh user, defaults to the username of the current user.
    ///   - sshIdentityFile: The ssh identity file, defaults to standard key locations for ssh.
    ///   - strictHostKeyChecking: A Boolean value that indicates whether to enable strict host checking during SSH connections.
    public static func resolve(
        _ name: String,
        sshPort: Int = 22,
        sshUser: String? = nil,
        sshIdentityFile: String? = nil,
        strictHostKeyChecking: Bool = false
    ) async throws -> RemoteHost {
        let creds = try SSHAccessCredentials(username: sshUser, identityFile: sshIdentityFile)
        if let address = await NetworkAddress.resolve(name) {
            return RemoteHost(
                address: address, sshPort: sshPort, sshAccessCredentials: creds,
                strictHostKeyChecking: strictHostKeyChecking)
        } else {
            throw CommandError.failedToResolveHost(name: name)
        }
    }
}

extension RemoteHost: CustomDebugStringConvertible {
    /// The debug description of the host.
    public var debugDescription: String {
        "host \(networkAddress)@\(sshPort), user: \(sshAccessCredentials), \(strictHostKeyChecking ? "strict key checking": "disabled key checking")"
    }
}

extension RemoteHost: CustomStringConvertible {
    /// The description of the host.
    public var description: String {
        return "\(self.sshAccessCredentials.username)@\(networkAddress)"
    }
}

extension RemoteHost: ExpressibleByArgument {
    /// Creates a new host from a string.
    /// - Parameter argument: The argument to parse as a host.
    public init?(argument: String) {
        try? self.init(argument)
    }
}

extension RemoteHost: Hashable {}
extension RemoteHost: Codable {}
