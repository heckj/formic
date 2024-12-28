import Dependencies
import Foundation

// Resource pieces and operating on them:

/// A type of resource that can be updated from a remote and supports collections and persistence.
public protocol Resource: Hashable, Sendable {
    // IMPLEMENTATION NOTE:
    // Requirement 0 - persist-able and comparable
    //    - `Codable`, `Hashable`
    // (I want to be able to persist a "last known state" - or the information needed to determine
    // its state - and be able to read it back in again in another "run".)

    // 2 - a way query the current state - "QueryableState"
    //    - `shellcommand`, `parse(_ output: String) -> Self`, used by
    //      `queryState(from host: Host) throws -> (Self, Date)`
    // Working from some initial implementations, I've broken this up into multiple protocols.
    // The baseline is a resource that, given an instance, you can query for the latest state
    // and associated details that might go along with the current state.
    //
    // There's a difference between resources that you only need to provide a "host" to get details
    // about, and resources that you need to provide a name or other identifier.
    // The first I've called "SingularResource" - the example is OperatingSystem providing a baseline.
    // The second I've called "NamedResource" - the example is a DebianPackage.
    // To accommodate lists of resources within a single host, I went with "CollectionQueryableResource".
    //
    // (I think a single command will do what we need for resources within an OS, but for resources
    // that span multiple hosts, we might need something more complex)

    /// The shell command to use to get the state for this resource.
    var inquiry: (any Command) { get }
    /// Returns the state of the resource from the output of the shell command.
    /// - Parameter output: The string output of the shell command.
    /// - Throws: Any errors parsing the output.
    static func parse(_ output: Data) throws -> Self
    /// Queries the state of the resource from the given host.
    /// - Parameter from: The host to inspect.
    /// - Returns: The state of the resource.
    func query(from: Host) async throws -> (Self, Date)
}

// IMPLEMENTATION NOTE:
// Requirement 1 - a declarative structure to represent what we want it to be
//    - name
//      - state (present|absent)
//    ? additional state/information (not declarable, but shown?)
//      - version
//      - architecture
//      - description
// (we need enough of a name and context to be able to programmatically request information about
// the resource. For software on a single OS, a type, name, and host address should be enough. But
// for resources that span hosts, we might need something very different.)
//
// The use cases I've stumbled across so far _may_ result in this needing to be more "stringly"
// typed - especially if it revolves out to externally declared resources, but I think this can
// mostly work _within_ Swift itself by using the underlying types of the resources themselves.
//
// While I started down this way to expose a struct as a bunch of generic strings, I'm not
// really sure it's needed, let along as a core "Resource" capability. So I've left the structure
// here, but I'm not sure it's needed.
//
// This whole basic structure is very indirect if you could "represent" the resource as a
// single string or something. It is a means of making a type that you can
// generically inquire for details, with an assumption that _most_ resource types will have
// multiple kinds of detail. This allows us to represent the resource types with strong types
// in swift, while exposing a String interface to inquire about the details.
// The idea was to try and get a little bit away from Stringly-typed resources if at all
// possible.
//

extension Resource {
    /// Queries the state of the resource from the given host.
    /// - Parameter host: The host to inspect.
    /// - Returns: The state of the resource and the time that it was last updated.
    public func query(from host: Host) async throws -> (Self, Date) {
        // default implementation:

        @Dependency(\.date.now) var date
        // run the command on the relevant host, capturing the output
        let output: CommandOutput = try await inquiry.run(host: host)
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

/// A type of resource that exists in singular form on a Host.
public protocol SingularResource: Resource {
    /// The shell command to use to get the state for this resource.
    static var inquiry: (any Command) { get }
    /// Queries the state of the resource from the given host.
    /// - Parameter from: The host to inspect.
    /// - Returns: The state of the resource.
    static func query(from: Host) async throws -> (Self, Date)
}

extension SingularResource {
    /// Queries the state of the resource from the given host.
    /// - Parameter host: The host to inspect.
    /// - Returns: The state of the resource and the time that it was last updated.
    public static func query(from host: Host) async throws -> (Self, Date) {
        // default implementation:

        @Dependency(\.date.now) var date
        // run the command on the relevant host, capturing the output
        let output: CommandOutput = try await Self.inquiry.run(host: host)
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

/// A type of resource that exposes a declarative state.
public protocol StatefulResource<DeclarativeStateType>: Resource {
    associatedtype DeclarativeStateType: CustomStringConvertible, Sendable, Hashable
    /// The state of this resource.
    var state: DeclarativeStateType { get }
}

/// A resource that can be identifier from a host with a name you provide.
public protocol NamedResource: Resource {
    /// Returns a resource for the host you provide.
    /// - Parameter name: The name of the resource to find.
    /// - Parameter host: The host to inspect for the resource.
    static func query(_ name: String, from host: Host) async throws -> (Self, Date)
    // var name: String { get }
}

/// A collection of resources that can be found and queried from a host.
public protocol CollectionQueryableResource: Resource {
    /// The shell command to use to get the state for this resource.
    static var collectionInquiry: (any Command) { get }
    /// Returns a list of resources from the string output from a command.
    /// - Parameter output: The output from the command.
    static func collectionParse(_ output: Data) throws -> [Self]
    /// Returns a list of resources for the host you provide.
    /// - Parameter from: The host to inspect.
    static func queryCollection(from: Host) async throws -> ([Self], Date)
}

extension CollectionQueryableResource {
    /// Queries the state of the resource from the given host.
    /// - Parameter host: The host to inspect.
    /// - Returns: The state of the resource and the time that it was last updated.
    public static func queryCollection(from host: Host) async throws -> ([Self], Date) {
        // default implementation:

        @Dependency(\.date.now) var date
        // run the command on the relevant host, capturing the output
        let output: CommandOutput = try await collectionInquiry.run(host: host)
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
}

// TODO(heckj): These additional requirements are going to be needed for resolvable state and actions
// in a more "Operator" kind of pattern. These aren't yet fleshed out.
//
// Requirement 3 - a way to compute the changes needed to get into that desired state
//    - knowledge of (1), and `resolve()`
// (a full representation of all the states and how to transition between them)
//
// Requirement 4 - the actions to take to make those changes
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
