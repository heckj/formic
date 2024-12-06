import Foundation

/// The kind of operating system.
public struct OperatingSystem: QueryableState {
    public let name: String  // state

    public static let shellcommand: Command = Command.shell("uname")
    public static func parse(_ output: String) throws -> OperatingSystem {
        switch output {
        case "Darwin\n":
            return .macOS
        case "Linux\n":
            return .linux
        default:
            return .unnkown
        }
    }

    // This could be an enum, but we don't really need to iterate on the cases, so I'm
    // opting to leave it as a struct.

    public static let linux = Self(name: "linux")  // data sources: uname, lsb_release
    public static let macOS = Self(name: "macOS")  // data sources: uname, lsb_release
    public static let unnkown = Self(name: "unknown")

    /// Creates a new instance of OperatingSystem with name you provide.
    /// - Parameter name: The name of the operating system
    init(name: String) {
        self.name = name
    }
}

// TODO: consider shifting these to a protocol that overlays QueryableState - Resource or such
// to extend those required conformances.
extension OperatingSystem: Hashable {}
extension OperatingSystem: Codable {}
