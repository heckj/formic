import Foundation
import Parsing

/// The kind of operating system.
public struct OperatingSystem: Resource {

    /// The kind of operating system.
    public let name: KindOfOperatingSystem

    /// The types of operating system this resource can represent.
    public enum KindOfOperatingSystem: String, StringInfoKey {
        case macOS
        case linux
        case unknown
    }
    // ^^ provides a useful type that we can "parse" into and initialize the wrapping resource-type

    struct UnameParser: Parser {
        var body: some Parser<Substring, KindOfOperatingSystem> {
            OneOf {
                "Darwin".map { KindOfOperatingSystem.macOS }
                "Linux".map { KindOfOperatingSystem.linux }
                "linux".map { KindOfOperatingSystem.linux }
                "macOS".map { KindOfOperatingSystem.macOS }
            }
            // NOTE: This parser *always* consumes the "\n" if it's there,
            // so it's not suitable to using in a Many() construct.
            Skip {
                Optionally {
                    "\n"
                }
            }
        }
    }

    /// Creates a new resource instance for the kind of operating system you provide.
    /// - Parameter kind: The kind of operating system.
    public init(_ kind: KindOfOperatingSystem) {
        self.name = kind
    }

    /// Creates a new instance of the resource based on the string you provide.
    /// - Parameter name: The string that represents the kind of operating system.
    public init(_ name: String) {
        do {
            self.name = try UnameParser().parse(name)
        } catch {
            self.name = .unknown
        }
    }
}

//extension OperatingSystem: Resource {
//    public typealias ResourceInformationKey = OSInformationKey
//    public enum OSInformationKey: String, StringInfoKey {
//        case name
//    }
//    public func info(for key: ResourceInformationKey) -> String? {
//        switch key {
//        case .name:
//            return name.rawValue
//        }
//    }
//}

extension OperatingSystem: SingularResource {
    /// The shell command to use to get the state for this resource.
    public static let singularInquiry: (any Command) = LocalProcess.shell("uname")

    /// The shell command to use to update the state for this resource.
    public var inquiry: (any Command) {
        return Self.singularInquiry
    }

    /// Returns the state of the resource from the output of the shell command.
    /// - Parameter output: The string output of the shell command.
    public static func parse(_ output: String) -> OperatingSystem {
        do {
            return Self(try UnameParser().parse(output))
        } catch {
            return Self(.unknown)
        }
    }
}
