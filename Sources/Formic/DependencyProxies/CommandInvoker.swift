import Dependencies
import Foundation
import Logging

#if canImport(FoundationNetworking)  // Required for Linux
    import FoundationNetworking
#endif

// IMPLEMENTATION NOTES:
// With this structure, everything is synchronous - which makes some of the higher level
// structuring easier. But it also means that you don't see any output _while_ it's happening.
// It's possible we might be able to stream if we switch to one the Async oriented shell
// libraries, that stream/flow data from the Pipes as it appears, but in terms of the
// functional logic of this - it's more relevant to see what the output is when it's complete
// than the see the internals as it flows. It *looks* a lot nicer - gives a feeling of
// progress that's really great - but isn't strictly needed for the core functionality.
//
// Two options for async shell command execution:
//
// - https://github.com/GeorgeLyon/Shwift
// Shwift has clearly been around the block, but has heavier dependencies (all of SwiftNIO) that
// make it a heavier take.
//
// - https://github.com/Zollerboy1/SwiftCommand
// I like the structure of SwiftCommand, but it has a few swift6 concurrency warnings about fiddling
// with mutable buffers that are slightly concerning to me. There also doesn't appear to
// be a convenient way to capture STDERR separately (it's mixed together).

// Dependency injection docs:
// https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies

protocol CommandInvoker: Sendable {
    func remoteShell(
        host: String,
        user: String,
        identityFile: String?,
        port: Int?,
        strictHostKeyChecking: Bool,
        cmd: String,
        env: [String: String]?,
        logger: Logger?
    ) async throws -> CommandOutput

    func remoteCopy(
        host: String,
        user: String,
        identityFile: String?,
        port: Int?,
        strictHostKeyChecking: Bool,
        localPath: String,
        remotePath: String,
        logger: Logger?
    ) async throws -> CommandOutput

    func getDataAtURL(url: URL, logger: Logger?) async throws -> Data

    func localShell(
        cmd: [String],
        stdIn: Pipe?,
        env: [String: String]?,
        logger: Logger?
    ) async throws -> CommandOutput
}

// registers the dependency

private enum CommandInvokerKey: DependencyKey {
    static let liveValue: any CommandInvoker = ProcessCommandInvoker()
}

// adds a dependencyValue for convenient access

extension DependencyValues {
    var commandInvoker: CommandInvoker {
        get { self[CommandInvokerKey.self] }
        set { self[CommandInvokerKey.self] = newValue }
    }
}
