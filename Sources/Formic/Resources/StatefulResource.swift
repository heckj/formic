import Foundation

/// A type of resource that can be retrieved and resolved to a desired state using a declaration.
public protocol StatefulResource<DeclarativeStateType>: Resource {
    associatedtype DeclarativeStateType: Sendable, Hashable
    // a declaration alone should be enough to get the resource and resolve it to
    // whatever state is desired and supported.

    // IMPLEMENTATION NOTES:
    // Requirement 2 - a declarative structure to represent what we want it to be
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
    // The idea being that a declaration is tiny subset of all the detail possible from a resource, but
    // sufficient to identify - and to hold what states is can "resolve" and set declaratively.
    // This allows us to represent the resource types with strong types
    // in swift, while exposing the details with a public type for the resource.
    //
    // Requirement 3 - a way to compute the changes needed to get into that desired state
    //    - knowledge of (1), and `resolve()`
    // (a full representation of all the states and how to transition between them)
    //
    // Requirement 4 - the actions to take to make those changes
    //    - `resolve()`

    /// Queries and returns the state of the resource identified by a declaration you provide.
    /// - Parameters:
    ///   - state: The declaration that identifies the resource.
    ///   - host: The host on which to find the resource.
    static func query(state: DeclarativeStateType, from host: Host) async throws -> (Self, Date)
    /// Queries and attempts to resolve the update to the desired state you provide.
    /// - Parameters:
    ///   - state: The declaration that identifies the resource and its desired state.
    ///   - host: The host on which to resolve the resource.
    static func resolve(state: DeclarativeStateType, on host: Host) async throws -> Bool
}
