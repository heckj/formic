import Foundation

/// A type that runs imperative commands against a collection of hosts.
public struct Playlist {
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
    }

    /// Creates a new playlist.
    /// - Parameters:
    ///   - name: The name of the playlist.
    ///   - hosts: The host names to resolve into hosts.
    ///   - commands: The commands to invoke on the hosts.
    public init(name: String, hosts: [String], commands: [Command]) async {
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

    /// Runs the playlist synchronously for each host in order, printing out the results.
    public func runSync() throws {
        for host in hosts {
            for command in commands {
                let result = try command.run(host: host)
                if result.returnCode != 0 {
                    // failure
                    print("❌ \(command.args) (rc=\(result.returnCode))")
                    if let stdout = result.stdoutString {
                        print("  out: \(stdout)")
                    }
                    if let stderr = result.stderrString {
                        print("  out: \(stderr)")
                    }
                } else {
                    // success
                    print("✅ \(command.args)")
                    if let stdout = result.stdoutString {
                        print("  out: \(stdout)")
                    }
                    if let stderr = result.stderrString {
                        print("  out: \(stderr)")
                    }
                }
            }
        }
    }
}

extension Playlist: Hashable {}
extension Playlist: Codable {}
