import AsyncDNSResolver
import Dependencies
import Foundation
import Testing

@testable import Formic

struct TestFileSystemAccess: LocalSystemAccess {
    let mockDNSresolution: [String: [String]]
        
    func fileExists(atPath: String) -> Bool {
        atPath.contains("id_dsa")
    }
    let homeDirectory: URL = URL(filePath: "/home/docker-user")
    let username: String? = "docker-user"
    func queryA(name: String) async throws -> [ARecord] {
        if let returnValues = mockDNSresolution[name] {
            return returnValues.map { ARecord(address: .init(address: $0), ttl: 999) }
        } else {
            return []
        }
    }
    
    init() {
        mockDNSresolution = [:]
    }
    
    init(dnsName: String, ipAddressesToUse: [String]) {
        mockDNSresolution = [dnsName: ipAddressesToUse]
    }
}

@Test("Host initializer")
func initHost() async throws {

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

@Test("Host initializer using localhost name should be marked local")
func initHostWithLocalHostName() async throws {
    let host = try withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
    } operation: {
        try Host("localhost")
    }
    #expect(host != nil)
    #expect(host?.remote == false)
}

@Test("Host initializer using localhost address should be marked remote")
func initHostWithLocalHostAddress() async throws {
    let host = try withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
    } operation: {
        try Host("127.0.0.1")
    }
    #expect(host != nil)
    #expect(host?.remote == true)
}
