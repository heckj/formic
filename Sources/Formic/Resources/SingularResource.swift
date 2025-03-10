import Dependencies
import Foundation
import Logging

/// A type of resource that exists in singular form on a Host.
public protocol SingularResource: ParsedResource {

    // a singular resource should have a way to query for the kind of resource given
    // JUST the host, so any default query & parse setup should be accessible as
    // static variables or functions.

    /// The shell command to use to get the state for this resource.
    static var inquiry: (any Command) { get }
    /// Queries the state of the resource from the given host.
    /// - Parameter from: The host to inspect.
    /// - Parameter logger: An optional logger to record the command output or errors.
    /// - Returns: The state of the resource.
    static func query(from: RemoteHost, logger: Logger?) async throws -> (Self?, Date)
}

extension SingularResource {
    /// Queries the state of the resource from the given host.
    /// - Parameter host: The host to inspect.
    /// - Parameter logger: An optional logger to record the command output or errors.
    /// - Returns: The state of the resource and the time that it was last updated.
    public static func query(from host: RemoteHost, logger: Logger?) async throws -> (Self?, Date) {
        // default implementation:

        @Dependency(\.date.now) var date
        // run the command on the relevant host, capturing the output
        let output: CommandOutput = try await Self.inquiry.run(host: host, logger: logger)
        // verify the return code is 0
        if output.returnCode != 0 {
            throw CommandError.commandFailed(rc: output.returnCode, errmsg: output.stderrString ?? "")
        } else {
            // then parse the output
            guard let stdout = output.stdOut else {
                throw CommandError.noOutputToParse(
                    msg:
                        "The command \(Self.inquiry) to \(host) did not return any output. stdError: \(output.stderrString ?? "-none-")"
                )
            }
            let parsedState = try Self.parse(stdout)
            return (parsedState, date)
        }
    }
}
