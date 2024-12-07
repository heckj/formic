import Dependencies
import Foundation

/// A type that can be queried using a shell command.
public protocol QueryableResource: Sendable {
    /// The shell command to use to get the state for this resource.
    static var shellcommand: Command { get }
    /// Returns the state of the resource from the output of the shell command.
    /// - Parameter output: The string output of the shell command.
    /// - Throws: Any errors parsing the output.
    static func parse(_ output: String) throws -> Self
    /// Queries the state of the resource from the given host.
    /// - Parameter from: The host to inspect.
    /// - Returns: The state of the resource.
    static func queryState(from: Host) throws -> (Self, Date)
}

extension QueryableResource {
    /// Queries the state of the resource from the given host.
    /// - Parameter host: The host to inspect.
    /// - Returns: The state of the resource and the time that it was last updated.
    public static func queryState(from host: Host) throws -> (Self, Date) {
        // default implementation:

        @Dependency(\.date.now) var date
        // run the command on the relevant host, capturing the output
        let output: CommandOutput = try shellcommand.run(host: host)
        // verify the return code is 0
        if output.returnCode != 0 {
            throw CommandError.commandFailed(rc: output.returnCode, errmsg: output.stderrString ?? "")
        } else {
            // then parse the output
            guard let stdout = output.stdoutString else {
                throw CommandError.noOutputToParse(
                    msg:
                        "The command \(Self.shellcommand) to \(host) did not return any output. stdError: \(output.stderrString ?? "-none-")"
                )
            }
            let parsedState = try Self.parse(stdout)
            return (parsedState, date)
        }
    }
}
