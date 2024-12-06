import Foundation

/// A type that runs imperative commands against a collection of hosts.
public actor Playlist {
    /// The name of the playlist.
    public let name: String
    /// The hosts to run the commands on.
    public var hosts: [Host]
    /// The commands to invoke on the hosts.
    public var commands: [Command]

    /// Creates a new playlist.
    /// - Parameters:
    ///   - name: The name of the playlist.
    ///   - hosts: The hosts to run the commands on.
    ///   - commands: The commands to invoke on the hosts.
    init(name: String, hosts: [Host], commands: [Command]) {
        self.name = name
        self.hosts = hosts
        self.commands = commands
    }

    /// Creates a new playlist.
    /// - Parameters:
    ///   - name: The name of the playlist.
    ///   - hosts: The host names to resolve into hosts.
    ///   - commands: The commands to invoke on the hosts.
    init(name: String, hosts: [String], commands: [Command]) async {
        self.name = name
        self.commands = commands
        self.hosts = []
        for host in hosts {
            do {
                let resolvedHost = try await Host.resolve(host)
                self.hosts.append(resolvedHost)
            } catch {
                print("Ignoring \(host): \(error)")
            }
        }
    }

}
