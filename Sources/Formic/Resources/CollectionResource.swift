import Dependencies
import Foundation
import Logging

/// A collection of resources that can be found and queried from a host.
public protocol CollectionResource: ParsedResource {
    /// The shell command to use to get the state for this resource.
    static var collectionInquiry: (any Command) { get }
    /// Returns a list of resources from the string output from a command.
    /// - Parameter output: The output from the command.
    static func collectionParse(_ output: Data) throws -> [Self]
    /// Returns a list of resources for the host you provide.
    /// - Parameter from: The host to inspect.
    /// - Parameter logger: An optional logger to record the command output or errors.
    static func queryCollection(from: RemoteHost, logger: Logger?) async throws -> ([Self], Date)
    /// Returns an inquiry command that retrieves the output to parse into a resource.
    /// - Parameter name: The name of the resource to find.
    static func namedInquiry(_ name: String) -> (any Command)
}

extension CollectionResource {
    /// Queries the state of the resource from the given host.
    /// - Parameter host: The host to inspect.
    /// - Parameter logger: An optional logger to record the command output or errors.
    /// - Returns: A list of the resources found, and the timestamp when it was checked.
    public static func queryCollection(from host: RemoteHost, logger: Logger?) async throws -> ([Self], Date) {
        // default implementation:

        @Dependency(\.date.now) var date
        // run the command on the relevant host, capturing the output
        let output: CommandOutput = try await collectionInquiry.run(host: host, logger: logger)
        // verify the return code is 0
        if output.returnCode != 0 {
            throw CommandError.commandFailed(rc: output.returnCode, errmsg: output.stderrString ?? "")
        } else {
            // then parse the output
            guard let stdout = output.stdOut else {
                throw CommandError.noOutputToParse(
                    msg:
                        "The command \(Self.collectionInquiry) to \(host) did not return any output. stdError: \(output.stderrString ?? "-none-")"
                )
            }
            let parsedState = try Self.collectionParse(stdout)
            return (parsedState, date)
        }
    }

    /// Returns the individual resource, if it exists, and the timestamp of the check from a resource collection and host that you provide.
    /// - Parameter name: The name of the resource to find.
    /// - Parameter host: The host to inspect for the resource.
    /// - Parameter logger: An optional logger to record the command output or errors.
    static func query(_ name: String, from host: RemoteHost, logger: Logger?) async throws -> (Self?, Date) {
        // default implementation:

        @Dependency(\.date.now) var date
        // run the command on the relevant host, capturing the output
        let output: CommandOutput = try await Self.namedInquiry(name).run(host: host, logger: logger)
        // verify the return code is 0
        if output.returnCode != 0 {
            throw CommandError.commandFailed(rc: output.returnCode, errmsg: output.stderrString ?? "")
        } else {
            // then parse the output
            guard let stdout = output.stdOut else {
                throw CommandError.noOutputToParse(
                    msg:
                        "The command \(Self.collectionInquiry) to \(host) did not return any output. stdError: \(output.stderrString ?? "-none-")"
                )
            }
            let parsedState = try Self.parse(stdout)
            return (parsedState, date)
        }
    }
}
