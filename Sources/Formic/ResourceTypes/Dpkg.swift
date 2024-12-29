import Foundation
import Parsing

// An example resource
// - a collection of debian packages
// - declared state of installed vs. not

// ex:
// > `docker-user@ubuntu:~$ dpkg -l docker-ce`
//
//Desired=Unknown/Install/Remove/Purge/Hold
//| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
//|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
//||/ Name           Version                       Architecture Description
//+++-==============-=============================-============-====================================================
//ii  docker-ce      5:27.3.1-1~ubuntu.24.04~noble arm64        Docker: the open-source application container engine

/// A debian package resource.
public struct Dpkg: Sendable, Hashable, Resource {
    /// Returns an inquiry command that retrieves the output to parse into a resource.
    /// - Parameter name: The name of the resource to find.
    public static func namedInquiry(_ name: String) -> (any Command) {
        ShellCommand("dpkg -l \(name)")
    }

    /// The command to use to get the state for this resource.
    public var inquiry: (any Command) {
        Self.namedInquiry(name)
    }

    /// Returns the state of the resource from the output of the shell command.
    /// - Parameter output: The string output of the shell command.
    /// - Throws: Any errors parsing the output.
    public static func parse(_ output: Data) throws -> Dpkg {
        guard let stringFromData: String = String(data: output, encoding: .utf8) else {
            throw ResourceError.notAString
        }
        let _ = try Dpkg.PackageList().parse(Substring(stringFromData))
        fatalError("not implemented")
    }

    /// The desired state code from the Dpkg system.
    public enum DesiredState: String, Sendable, Hashable {
        case unknown = "u"
        case install = "i"
        case remove = "r"
        case purge = "p"
        case hold = "h"
    }

    /// The status code from the Dpkg system.
    public enum StatusCode: String, Sendable, Hashable {
        case notInstalled = "n"
        case installed = "i"
        case configFiles = "c"
        case unpacked = "u"
        case failedConfig = "f"
        case halfInstalled = "h"
        case triggerAwait = "w"
        case triggerPending = "t"
    }

    /// The error code from the Dpkg system.
    public enum ErrCode: String, Sendable, Hashable {
        case reinstall = "r"
        case none = " "
    }

    /// The desired state code of this resource from the Dpkg system.
    public let desiredState: DesiredState
    /// The status code of this resource from the Dpkg system.
    public let statusCode: StatusCode
    /// The error code of this resource from the Dpkg system.
    public let errCode: ErrCode

    /// The name of the package.
    public let name: String
    /// The version of the package.
    public let version: String
    /// The architecture the package supports.
    public let architecture: String
    /// The description of the package.
    public let description: String

    /// The declaration for a Debian package resource.
    public struct DebianPackageDeclaration: Hashable, Sendable, Command {
        public var id: UUID
        public var ignoreFailure: Bool
        public var retry: Backoff
        public var executionTimeout: Duration
        public func run(host: Host) async throws -> CommandOutput {
            if try await Dpkg.resolve(state: self, on: host) {
                return .generalSuccess(msg: "Resolved")
            } else {
                return .generalFailure(msg: "Failed")
            }
        }

        /// The configurable state of a debian package.
        public enum DesiredPackageState: String, Hashable, Sendable {
            /// The package exists and is installed.
            case present
            /// The package is not installed or removed.
            case absent
        }

        /// The name of the package.
        public var name: String
        /// The desired state of the package.
        public var declaredState: DesiredPackageState

        /// Creates a new declaration for a Debian package resource
        /// - Parameters:
        ///   - name: The name of the package.
        ///   - state: The desired state of the package.
        ///   - retry: The retry settings for resolving the resource.
        ///   - resolveTimeout: The execution timeout to allow the resource to resolve.
        public init(
            name: String, state: DesiredPackageState, retry: Backoff = .never, resolveTimeout: Duration = .seconds(60)
        ) {
            self.name = name
            self.declaredState = state
            // Command details
            self.id = UUID()
            self.ignoreFailure = false
            self.retry = retry
            self.executionTimeout = resolveTimeout
        }
    }
}

extension Dpkg: CollectionResource {
    /// The shell command to use to get the state for this resource.
    public static var collectionInquiry: (any Command) {
        ShellCommand("dpkg -l")
    }

    /// Returns a list of resources from the string output from a command.
    /// - Parameter output: The output from the command.
    public static func collectionParse(_ output: Data) throws -> [Dpkg] {
        guard let stringFromData: String = String(data: output, encoding: .utf8) else {
            throw ResourceError.notAString
        }
        let collection = try Dpkg.PackageList().parse(Substring(stringFromData))
        return collection
    }
}

extension Dpkg: StatefulResource {
    /// Queries and returns the state of the resource identified by a declaration you provide.
    /// - Parameters:
    ///   - state: The declaration that identifies the resource.
    ///   - host: The host on which to find the resource.
    public static func query(state: DebianPackageDeclaration, from host: Host) async throws -> (Dpkg, Date) {
        return try await Dpkg.query(state.name, from: host)
    }

    /// Queries and attempts to resolve the update to the desired state you provide.
    /// - Parameters:
    ///   - state: The declaration that identifies the resource and its desired state.
    ///   - host: The host on which to resolve the resource.
    public static func resolve(state: DebianPackageDeclaration, on host: Host) async throws -> Bool {
        let (currentState, _) = try await Dpkg.query(state.name, from: host)
        switch state.declaredState {
        case .present:
            if currentState.desiredState == .install && currentState.statusCode == .installed {
                return true
            } else {
                try await ShellCommand("apt-get install \(state.name)").run(host: host)
                let (updatedState, _) = try await Dpkg.query(state.name, from: host)
                if updatedState.desiredState == .install && updatedState.statusCode == .installed {
                    return true
                } else {
                    return false
                }
            }

        case .absent:
            if (currentState.desiredState == .unknown || currentState.desiredState == .remove)
                && currentState.statusCode == .notInstalled
            {
                return true
            } else {
                // do the removal
                try await ShellCommand("apt-get remove \(state.name)").run(host: host)
                let (updatedState, _) = try await Dpkg.query(state.name, from: host)
                if (updatedState.desiredState == .unknown || updatedState.desiredState == .remove)
                    && updatedState.statusCode == .notInstalled
                {
                    return true
                } else {
                    return false
                }
            }
        }
    }
}
