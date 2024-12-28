import Foundation
import Parsing

/// The kind of operating system.
public struct OperatingSystem: SingularResource {
    /// The kind of operating system.
    public let name: KindOfOperatingSystem

    /// The types of operating system this resource can represent.
    public enum KindOfOperatingSystem: String, Sendable {
        case macOS
        case linux
        case unknown
    }
    // ^^ provides a useful type that we can "parse" into and initialize the wrapping resource-type
    public static var inquiry: (any Command) {
        return ShellCommand("uname")
    }

    public var inquiry: (any Command) {
        return Self.inquiry
    }

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

    /// Returns the state of the resource from the output of the shell command.
    /// - Parameter output: The string output of the shell command.
    public static func parse(_ output: Data) -> OperatingSystem {
        do {
            guard let stringFromData: String = String(data: output, encoding: .utf8) else {
                return Self(.unknown)
            }
            return Self(try UnameParser().parse(stringFromData))
        } catch {
            return Self(.unknown)
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
