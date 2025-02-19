import Foundation
import Logging

/// A type of resource that can be retrieved and resolved to a desired state using a declaration.
public protocol StatefulResource<DeclarativeStateType>: Resource {
    associatedtype DeclarativeStateType: Sendable, Hashable
    // a declaration alone should be enough to get the resource and resolve it to
    // whatever state is desired and supported.

    // IMPLEMENTATION NOTES:
    // Requirement 2 - a declarative structure to represent what we want it to be
    //    - name
    //      - state (present|absent)
    //
    // The idea being that a declaration is tiny subset of all the detail possible from a
    // resource, but sufficient to identify - and to hold what states is can "resolve"
    // and set declaratively. This allows us to represent the resource types with strong
    // types in Swift, while exposing the details as properties.
    //
    //    - additional state/information (not declarable, but available to be inspected)
    //      - version
    //      - architecture
    //      - description
    //
    // We need enough of a name and context to be able to request information about
    // the resource. For software on a single OS, a type, name, and host address should be enough.
    // But for resources that span hosts, we might need something very different.
    //
    // Requirement 3 - a way to compute the changes needed to get into that desired state
    //    - knowledge of (1), and `resolve()`
    // (a full representation of all the states and how to transition between them)
    //
    // Requirement 4 - the actions to take to make those changes
    //    - `resolve()`
    //
    // Knowing the full state is likely an internal type on the resource, and mapping
    // the possible states to what can be declared is the core of the `resolve()` function.

    /// Queries and returns the resource, if it exists, identified by a declaration you provide.
    /// - Parameters:
    ///   - state: The declaration that identifies the resource.
    ///   - host: The host on which to find the resource.
    ///   - logger: An optional logger to record the command output or errors.
    /// - Returns: A tuple of the resource, if it exists, and a timestamp of the check.
    static func query(state: DeclarativeStateType, from host: RemoteHost, logger: Logger?) async throws -> (Self?, Date)

    /// Queries and attempts to resolve the update to the desired state you provide.
    /// - Parameters:
    ///   - state: The declaration that identifies the resource and its desired state.
    ///   - host: The host on which to resolve the resource.
    ///   - logger: An optional logger to record the command output or errors.
    /// - Returns: A tuple of the resource state and a timestamp for the state.
    static func resolve(state: DeclarativeStateType, on host: RemoteHost, logger: Logger?) async throws -> Bool
}
