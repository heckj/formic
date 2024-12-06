import Dependencies
import Foundation
import Testing

@testable import Formic

@Test("Host initializer")
func initHost() async throws {
    struct TestFileSystemAccess: LocalSystemAccess {
        func fileExists(atPath: String) -> Bool {
            atPath.contains("id_dsa")
        }
        let homeDirectory: URL = URL(filePath: "/home/docker-user")
        let username: String? = "docker-user"
    }

    let host = try withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
    } operation: {
        try Host("localhost")
    }

    #expect(host != nil)
    #expect(host?.networkAddress.address.description == "127.0.0.1")
    #expect(host?.networkAddress.dnsName == "localhost")
    #expect(host?.sshPort == 22)
    #expect(host?.sshAccessCredentials != nil)
    #expect(host?.sshAccessCredentials.username == "docker-user")
    #expect(host?.sshAccessCredentials.identityFile == "/home/docker-user/.ssh/id_dsa")
}
