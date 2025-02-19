import Dependencies
import Foundation
import Logging

/// A type that can be queried from a host to provide information about itself.
public protocol Resource: Hashable, Sendable {

    // IMPLEMENTATION NOTE:
    // A resource is fundamentally something you can query about a system to get details about it.
    // Any **instance** of a resource should be able to get updated details about itself.

    /// Queries the state of the resource from the given host.
    /// - Parameter from: The host to inspect.
    /// - Parameter logger: An optional logger to record the command output or errors.
    /// - Returns: The resource, if it exists, and a timestamp at which is was checked.
    func query(from: RemoteHost, logger: Logger?) async throws -> (Self?, Date)

}

/// A resource that provides an inquiry command and parser to return the state of the resource.
public protocol ParsedResource: Resource {
    /// The command to use to get the state for this resource.
    var inquiry: (any Command) { get }
    /// Returns the resource, if it exists, from the output of the shell command, otherwise nil.
    /// - Parameter output: The string output of the shell command.
    /// - Throws: Any errors parsing the output.
    static func parse(_ output: Data) throws -> Self?
}

// IMPLEMENTATION NOTE:
// Requirement 0 - persist-able and comparable
//    - `Hashable` - maybe `Codable` down the road.
// (I want to be able to persist a "last known state" - or the information needed to determine
// its state - and be able to read it back in again in another "run".) Right now, I'm only requiring
// Hashable and Sendable while I work out how to use them in a larger scope, and where I might want
// to apply persistence (Codable) down the road (expected in the "Operator" use case).

// Requirement 1 - a way query the current state, the fundamental aspect of a resource.
//    - It's starting off with an expected pattern of a command (run on a host).
//      The command returns an output that can be parsed into the resource type.
//      Implementations should be able to provide a command to run, and a parser to do the
//      conversion, and a default implementation of query does the work.

// Working from some initial implementations, I've broken this up into multiple protocols.
// The baseline is a resource that, given an instance, you can query for the latest state
// and associated details that might go along with the current state.
//
// There's a difference between resources that you only need to provide a "host" to get details
// about, and resources that you need to provide a name or other identifier.
// The first I've called "SingularResource" - the example is OperatingSystem providing a baseline.
// The second I've called "CollectionResource" - the example is a DebianPackage.
// To accommodate lists of resources within a single host, I went with "CollectionResource".
//
// (I think a single command will do what we need for resources within an OS, but for resources
// that span multiple hosts, we will need something different)

extension ParsedResource {
    /// Queries the state of the resource from the given host.
    /// - Parameter host: The host to inspect.
    /// - Parameter logger: An optional logger to record the command output or errors.
    /// - Returns: The the resource, if it exists, and the timestamp that it was last checked.
    public func query(from host: RemoteHost, logger: Logger?) async throws -> (Self?, Date) {
        // default implementation to get updated details from an _instance_ of a resource

        @Dependency(\.date.now) var date
        // run the command on the relevant host, capturing the output
        let output: CommandOutput = try await inquiry.run(host: host, logger: logger)
        // verify the return code is 0
        if output.returnCode != 0 {
            throw CommandError.commandFailed(rc: output.returnCode, errmsg: output.stderrString ?? "")
        } else {
            // then parse the output
            guard let stdout = output.stdOut else {
                throw CommandError.noOutputToParse(
                    msg:
                        "The command \(inquiry) to \(host) did not return any output. stdError: \(output.stderrString ?? "-none-")"
                )
            }
            let parsedState = try Self.parse(stdout)
            return (parsedState, date)
        }
    }
}

// TODO(heckj): These additional requirements are going to be needed for resolvable state and actions
// in a more "Operator" kind of pattern. These aren't yet fleshed out.
//
// Requirement 5 - a way to test the state of the resource (various diagnostic levels)
//
// Some resources - such as a file or the group settings of an OS - won't have deeper levels
// of diagnostics available. You pretty much just get to look to see if the file is there and as
// you expect, or not. Other services - running processes - _can_ have deeper diagnostics to
// interrogate and "work" them to determine if they're fully operational.
// This is potentially very interesting for dependencies between services, especially for
// when dependencies span across multiple hosts. It could provide the way to "easily understand"
// why a service is failing.
