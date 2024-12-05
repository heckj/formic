import Dependencies
import Foundation
import Testing

@testable import Formic

@Test("initializing asserted network credentials")
func validSSHCredentials() async throws {
    let assertedCredentials = SSHAccessCredentials(username: "docker-user", identityFile: "~/.ssh/id_rsa")

    #expect(assertedCredentials.username == "docker-user")
    #expect(assertedCredentials.identityFile == "~/.ssh/id_rsa")
}

@Test("default home directory check")
func homeDirDependencyOverride() async throws {

    struct TestFileSystemAccess: LocalSystemAccess {
        func fileExists(atPath: String) -> Bool {
            return true
        }
        let homeDirectory: URL = URL(filePath: "/home/docker-user")
        let username: String? = "docker-user"
    }

    let testCredentials: SSHAccessCredentials? = withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
    } operation: {
        SSHAccessCredentials()
    }

    try #require(testCredentials != nil)
    #expect(testCredentials?.username == "docker-user")
    #expect(testCredentials?.identityFile == "/home/docker-user/.ssh/id_rsa")
}
