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

@Test("example run of a simple playlist")
func basicPlaybook() async throws {

    let playbook = withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
    } operation: {
        Playbook(
            name: "example", hosts: [.localhost],
            commands: [
                Command.shell("uname"),
                Command.shell("pwd"),
                Command.shell("ls", "-l"),
            ])
    }

    #expect(playbook.name == "example")
    #expect(playbook.hosts.count == 1)
    #expect(playbook.hosts[0].remote == false)
    #expect(playbook.commands.count == 3)

    try withDependencies {
        $0.commandInvoker = TestCommandInvoker()
    } operation: {
        try playbook.runSync()
    }
}
