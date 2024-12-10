import Dependencies
import Foundation
import Testing
import AsyncDNSResolver

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
    let testCredentials: Formic.Host.SSHAccessCredentials = try withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess(sshIdMatch: .rsa)
    } operation: {
        try Host.SSHAccessCredentials()
    }

    try #require(testCredentials != nil)
    #expect(testCredentials.username == "docker-user")
    #expect(testCredentials.identityFile == "/home/docker-user/.ssh/id_rsa")
}

@Test("default home directory w/ dsa id")
func homeDirDependencyOverrideDSA() async throws {

    let testCredentials: Formic.Host.SSHAccessCredentials? = try withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess(sshIdMatch: .dsa)
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
    let testCredentials: Formic.Host.SSHAccessCredentials = try withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess(sshIdMatch: .ed25519)
    } operation: {
        try Host.SSHAccessCredentials()
    }

    try #require(testCredentials != nil)
    #expect(testCredentials.username == "docker-user")
    #expect(testCredentials.identityFile == "/home/docker-user/.ssh/id_ed25519")
}
