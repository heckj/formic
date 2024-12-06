import Dependencies
import Testing

@testable import Formic

@Test("example run of a simple playlist")
func basicPlaylist() async throws {

    let playlist = withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
    } operation: {
        Formic.Playlist(
            name: "example", hosts: [.localhost],
            commands: [
                Command.shell("uname"),
                Command.shell("pwd"),
                Command.shell("ls", "-l"),
            ])
    }

    #expect(playlist.name == "example")
    #expect(playlist.hosts.count == 1)
    #expect(playlist.hosts[0].remote == false)
    #expect(playlist.commands.count == 3)

    try withDependencies {
        $0.commandInvoker = TestCommandInvoker()
    } operation: {
        try playlist.runSync()
    }
}
