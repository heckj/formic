import Formic
import Testing

@Test(
    "example run of a simple playlist",
    .timeLimit(.minutes(1)),
    .tags(.functionalTest))
func basicPlaylist() async throws {
    let playlist = Formic.Playlist(
        name: "example", hosts: [.localhost],
        commands: [
            Command("uname"),
            Command("pwd"),
            Command("ls", "-l"),
        ])

    #expect(playlist.name == "example")
    #expect(playlist.hosts.count == 1)
    #expect(playlist.commands.count == 3)

    try playlist.runSync()
}
