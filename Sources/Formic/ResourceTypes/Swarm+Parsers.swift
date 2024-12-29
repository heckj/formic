import Foundation
import Parsing

// https://swiftpackageindex.com/pointfreeco/swift-parsing#user-content-getting-started
// https://pointfreeco.github.io/swift-parsing/0.10.0/documentation/parsing/

/// A parser that converts the STDOUT from a swarm init command into a ShellCommand.
public struct SwarmJoinCommand: Parser {

    func convertToShellCommand(_ argTuple: (String, String, String, String, String, String)) -> ShellCommand {
        ShellCommand(arguments: [argTuple.0, argTuple.1, argTuple.2, argTuple.3, argTuple.4, argTuple.5])
    }

    public var body: some Parser<Substring, ShellCommand> {
        Parse(convertToShellCommand) {
            Skip {
                PrefixThrough("run the following command:\n\n")
            }
            Skip {
                Whitespace()
            }
            // docker
            Prefix { !$0.isWhitespace }.map(String.init)
            Skip {
                Whitespace()
            }
            // swarm
            Prefix { !$0.isWhitespace }.map(String.init)
            Skip {
                Whitespace()
            }
            // join
            Prefix { !$0.isWhitespace }.map(String.init)
            Skip {
                Whitespace()
            }
            //--token
            Prefix { !$0.isWhitespace }.map(String.init)
            Skip {
                Whitespace()
            }
            // token-value
            Prefix { !$0.isWhitespace }.map(String.init)
            Skip {
                Whitespace()
            }
            Prefix { !$0.isWhitespace }.map(String.init)
            // host-and-port
            Skip {
                Optionally {
                    Rest()
                }
            }
        }
    }
}
