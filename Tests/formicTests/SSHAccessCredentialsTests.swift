import Dependencies
import Foundation
import Testing

@testable import Formic

@Test("initializing asserted network credentials")
func validSSHCredentials() async throws {
    let assertedCredentials = Host.SSHAccessCredentials(username: "docker-user", identityFile: "~/.ssh/id_rsa")

    #expect(assertedCredentials.username == "docker-user")
    #expect(assertedCredentials.identityFile == "~/.ssh/id_rsa")
}

@Test("default home directory check")
func homeDirDependencyOverride() async throws {
    // Dependency injection docs:
    // https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies
    struct TestFileSystemAccess: LocalSystemAccess {
        func fileExists(atPath: String) -> Bool {
            return true
        }
        let homeDirectory: URL = URL(filePath: "/home/docker-user")
        let username: String? = "docker-user"
    }

    let testCredentials: Formic.Host.SSHAccessCredentials = try withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
    } operation: {
        try Host.SSHAccessCredentials()
    }

    try #require(testCredentials != nil)
    #expect(testCredentials.username == "docker-user")
    #expect(testCredentials.identityFile == "/home/docker-user/.ssh/id_rsa")
}

@Test("default home directory w/ dsa id")
func homeDirDependencyOverrideDSA() async throws {
    // Dependency injection docs:
    // https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies
    struct TestFileSystemAccess: LocalSystemAccess {
        func fileExists(atPath: String) -> Bool {
            atPath.contains("id_dsa")
        }
        let homeDirectory: URL = URL(filePath: "/home/docker-user")
        let username: String? = "docker-user"
    }

    let testCredentials: Formic.Host.SSHAccessCredentials? = try withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
    } operation: {
        try Host.SSHAccessCredentials()
    }

    try #require(testCredentials != nil)
    #expect(testCredentials?.username == "docker-user")
    #expect(testCredentials?.identityFile == "/home/docker-user/.ssh/id_dsa")
}

@Test("default home directory w/ ed25519 id")
func homeDirDependencyOverrideED25519() async throws {
    // Dependency injection docs:
    // https://swiftpackageindex.com/pointfreeco/swift-dependencies/main/documentation/dependencies
    struct TestFileSystemAccess: LocalSystemAccess {
        func fileExists(atPath: String) -> Bool {
            atPath.contains("id_ed25519")
        }
        let homeDirectory: URL = URL(filePath: "/home/docker-user")
        let username: String? = "docker-user"
    }

    let testCredentials: Formic.Host.SSHAccessCredentials = try withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
    } operation: {
        try Host.SSHAccessCredentials()
    }

    try #require(testCredentials != nil)
    #expect(testCredentials.username == "docker-user")
    #expect(testCredentials.identityFile == "/home/docker-user/.ssh/id_ed25519")
}
