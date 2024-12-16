import Foundation

/// A type that represents a command, run locally or remotely.
public protocol CommandProtocol: Sendable, Identifiable, Hashable, Codable {
    var id: UUID { get }
    var ignoreFailure: Bool { get }
    var retry: RetrySetting { get }
    var executionTimeout: Duration { get }

    func run(host: Host) async throws -> CommandOutput
}
