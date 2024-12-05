import Formic
import Testing

@Test("initializing asserted network credentials")
func validSSHCredentials() async throws {
    let assertedCredentials = SSHAccessCredentials(username: "docker-user", identityFile: "~/.ssh/id_rsa")

    #expect(assertedCredentials.username == "docker-user")
    #expect(assertedCredentials.identityFile == "~/.ssh/id_rsa")
}
