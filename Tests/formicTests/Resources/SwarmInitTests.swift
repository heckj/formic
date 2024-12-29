import Foundation
import Parsing  // temp while I work out how to use the parser
import Testing

@testable import Formic

@Test("swarm init output parsing")
func verifyParsingSwarmInitIntoWorkerCommand() async throws {
    let sample = """
        Swarm initialized: current node (dl490ag3crgutgvzq91id7wo1) is now a manager.

        To add a worker to this swarm, run the following command:

            docker swarm join --token SWMTKN-1-4co3ccnbcdrww0iq7f9te0478286pd168bhzfx9oyc1wyws0vi-1p35bj1i57s9h9dpf57mmeqq0 198.19.249.61:2377

        To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
        """
    let cmd = try SwarmJoinCommand().parse(sample)

    #expect(cmd.args.count == 6)
    #expect(cmd.args[4] == "SWMTKN-1-4co3ccnbcdrww0iq7f9te0478286pd168bhzfx9oyc1wyws0vi-1p35bj1i57s9h9dpf57mmeqq0")
    #expect(cmd.args[5] == "198.19.249.61:2377")
}

@Test("docker swarm join-token worker parsing")
func verifyParsingSwarmJoinTokenWorkerCommand() async throws {
    let sample = """
        To add a worker to this swarm, run the following command:

            docker swarm join --token SWMTKN-1-4co3ccnbcdrww0iq7f9te0478286pd168bhzfx9oyc1wyws0vi-1p35bj1i57s9h9dpf57mmeqq0 198.19.249.61:2377
        """
    let cmd = try SwarmJoinCommand().parse(sample)

    #expect(cmd.args.count == 6)
    #expect(cmd.args[4] == "SWMTKN-1-4co3ccnbcdrww0iq7f9te0478286pd168bhzfx9oyc1wyws0vi-1p35bj1i57s9h9dpf57mmeqq0")
    #expect(cmd.args[5] == "198.19.249.61:2377")
}
