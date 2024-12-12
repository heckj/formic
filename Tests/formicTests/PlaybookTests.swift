import Dependencies
import Testing

@testable import Formic

@Test("playbook declaration")
func testPlaybookSimpleDeclaration() async throws {
    let playbook = Playbook(
        name: "simplest", hosts: [.localhost],
        commands: [
            Command.shell("uname"),
            Command.shell("pwd"),
            Command.shell("ls", "-l"),
        ])
    #expect(playbook.name == "simplest")
    #expect(playbook.hosts.count == 1)
    #expect(playbook.hosts[0] == .localhost)
    #expect(playbook.commands.count == 3)
    #expect(playbook.commands[0].args == ["uname"])
    #expect(playbook.commands[1].args == ["pwd"])
    #expect(playbook.commands[2].args == ["ls", "-l"])
}

@Test("test playbook creating with hostname resolution")
func asyncPlaybookInit() async throws {
    typealias IPv4Address = Formic.Host.IPv4Address
    
    let playbook = await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess(
            dnsName: "somewhere.com", ipAddressesToUse: ["8.8.8.8"])
    } operation: {
        await Playbook(name: "basic", hosts: ["somewhere.com"], commands: [])
    }
    
    #expect(playbook.name == "basic")
    #expect(playbook.hosts.count == 1)
    #expect(playbook.hosts[0].networkAddress.address == IPv4Address("8.8.8.8"))
}
