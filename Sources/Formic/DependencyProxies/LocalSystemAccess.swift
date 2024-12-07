import Dependencies
import Foundation

// Dependency injection docs:
// https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies

/// Protocol for shimming in dependencies for accessing the local system.
protocol LocalSystemAccess: Sendable {
    var username: String? { get }
    var homeDirectory: URL { get }
    func fileExists(atPath: String) -> Bool
}

/// The default "live" local system access.
struct LiveLocalSystemAccess: LocalSystemAccess {
    let username = ProcessInfo.processInfo.environment["USER"]
    let homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    func fileExists(atPath: String) -> Bool {
        FileManager.default.fileExists(atPath: atPath)
    }
}

// registers the dependency

private enum LocalSystemAccessKey: DependencyKey {
    static let liveValue: any LocalSystemAccess = LiveLocalSystemAccess()
}

// adds a dependencyValue for convenient access

extension DependencyValues {
    var localSystemAccess: LocalSystemAccess {
        get { self[LocalSystemAccessKey.self] }
        set { self[LocalSystemAccessKey.self] = newValue }
    }
}
