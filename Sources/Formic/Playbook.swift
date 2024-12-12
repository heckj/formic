import Foundation

/// A type that holds a sequence of imperative commands to run against one or more hosts.
public struct Playbook: Identifiable, Sendable {
    public let id: UUID
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
    public init(name: String, hosts: [Host], commands: [Command]) {
        self.name = name
        self.hosts = hosts
        self.commands = commands
        id = UUID()
    }

    /// Creates a new playlist.
    /// - Parameters:
    ///   - name: The name of the playlist.
    ///   - hosts: The host names to resolve into hosts.
    ///   - commands: The commands to invoke on the hosts.
    public init(name: String, hosts: [String], commands: [Command]) async {
        id = UUID()
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

extension Playbook: Hashable {}
extension Playbook: Codable {}
