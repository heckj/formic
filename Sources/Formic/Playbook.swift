import Foundation

/// A type that holds a sequence of imperative commands to run against one or more hosts.
public struct Playbook: Identifiable, Sendable {
    public let id: UUID
    /// The name of the playlist.
    public let name: String
    /// The hosts to run the commands on.
    public let hosts: [Host]
    /// The commands to invoke on the hosts.
    public let commands: [(any CommandProtocol)]

    /// Creates a new playlist.
    /// - Parameters:
    ///   - name: The name of the playlist.
    ///   - hosts: The hosts to run the commands on.
    ///   - commands: The commands to invoke on the hosts.
    public init(name: String, hosts: [Host], commands: [(any CommandProtocol)]) {
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
    public init(name: String, hosts: [String], commands: [(any CommandProtocol)]) async {
        id = UUID()
        self.name = name
        self.commands = commands
        var resolved: [Host] = []
        for host in hosts {
            do {
                let resolvedHost = try await Host.resolve(host)
                resolved.append(resolvedHost)
            } catch {
                print("Ignoring \(host): \(error)")
            }
        }
        self.hosts = resolved
    }
}

extension Playbook: Equatable {
    public static func == (lhs: Playbook, rhs: Playbook) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.hosts == rhs.hosts
    }
}

extension Playbook: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(hosts)
        for command in commands {
            let tempHash = command.hashValue
            hasher.combine(tempHash)
        }
    }
}
