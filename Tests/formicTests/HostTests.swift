import Dependencies
import Foundation
import Testing

@testable import Formic

@Test("Host initializer")
func initHost() async throws {

    let host = try withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
    } operation: {
        try RemoteHost("localhost")
    }

    #expect(host != nil)
    #expect(host?.networkAddress.address.description == "127.0.0.1")
    #expect(host?.networkAddress.dnsName == "localhost")
    #expect(host?.sshPort == 22)
    #expect(host?.sshAccessCredentials != nil)
    #expect(host?.sshAccessCredentials.username == "docker-user")
    #expect(host?.sshAccessCredentials.identityFile == "/home/docker-user/.ssh/id_dsa")
}

@Test("Host initializer using localhost name should be marked local")
func initHostWithLocalHostName() async throws {
    let host = try withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
    } operation: {
        try RemoteHost("localhost")
    }
    #expect(host != nil)
}

@Test("Host initializer using localhost address should be marked remote")
func initHostWithLocalHostAddress() async throws {
    let host = try withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
    } operation: {
        try RemoteHost("127.0.0.1")
    }
    #expect(host != nil)
}
