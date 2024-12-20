import Foundation

/// A type that holds a sequence of imperative commands to run against one or more hosts.
public struct Playbook: Identifiable, Sendable {
    public let id: UUID
    /// The name of the playlist.
    public let name: String
    /// The hosts to run the commands on.
    public let hosts: [Host]
    /// The commands to invoke on the hosts.
    public let commands: [(any Command)]

    /// Creates a new playlist.
    /// - Parameters:
    ///   - name: The name of the playlist.
    ///   - hosts: The hosts to run the commands on.
    ///   - commands: The commands to invoke on the hosts.
    public init(name: String, hosts: [Host], commands: [(any Command)]) {
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
    public init(name: String, hosts: [String], commands: [(any Command)]) async {
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
    /// Returns `true` if the two playbooks are equal.
    /// - Parameters:
    ///   - lhs: The first playbook
    ///   - rhs: The second playbook
    public static func == (lhs: Playbook, rhs: Playbook) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.hosts == rhs.hosts
    }
}

extension Playbook: Hashable {
    /// Hashes the essential components of the playbook.
    /// - Parameter hasher: The hasher to use when combining the components
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
