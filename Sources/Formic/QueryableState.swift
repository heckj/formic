/// A type that can be queried using a shell command.
public protocol QueryableState: Sendable {
    /// The shell command to use to get the state for this resource.
    static var shellcommand: [String] { get }
    /// Returns the state of the resource from the output of the shell command.
    /// - Parameter output: The string output of the shell command.
    /// - Throws: Any errors parsing the output.
    static func parse(_ output: String) throws -> Self
    /// Queries the state of the resource from the given host.
    /// - Parameter from: The host to inspect.
    /// - Returns: The state of the resource.
    static func queryState(from: Host) throws -> Self
}

extension QueryableState {
    /// Queries the state of the resource from the given host.
    /// - Parameter from: The host to inspect.
    /// - Returns: The state of the resource.
    public static func queryState(from host: Host) throws -> Self {
        let output: CommandOutput = try Command.run(host: host, args: Self.shellcommand)
        if output.returnCode != 0 {
            throw CommandError.commandFailed(rc: output.returnCode, errmsg: output.stderrString ?? "")
        } else {
            guard let stdout = output.stdoutString else {
                throw CommandError.noOutputToParse(
                    msg:
                        "The command \(Self.shellcommand) to \(host) did not return any output. stdError: \(output.stderrString ?? "-none-")"
                )
            }
            return try Self.parse(stdout)
        }
    }
}
