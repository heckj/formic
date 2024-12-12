import ArgumentParser
import AsyncDNSResolver
import Dependencies

extension Host {
    /// A network address, either an IP address or a DNS name.
    public struct NetworkAddress: Sendable {
        public let address: IPv4Address
        public let dnsName: String?

        public init?(_ name: String) {
            if name == "localhost" {
                self.address = .localhost
                self.dnsName = "localhost"
                return
            } else if let nameIsIPAddress = IPv4Address(name) {
                self.address = nameIsIPAddress
                self.dnsName = nil
                return
            }
            return nil
        }

        public init(_ address: IPv4Address) {
            self.address = address
            self.dnsName = nil
        }

        public init?(_ address: IPv4Address?) {
            guard let address = address else {
                return nil
            }
            self.init(address)
        }

        internal init(_ address: IPv4Address, resolvedName: String) {
            self.address = address
            self.dnsName = resolvedName
        }

        public static let localhost = NetworkAddress(.localhost, resolvedName: "localhost")

        // MARK: Resolver

        public static func resolve(_ name: String?) async -> NetworkAddress? {

            @Dependency(\.localSystemAccess) var localSystem: any LocalSystemAccess

            guard let name = name else {
                return nil
            }

            if let nameIsIPAddress = IPv4Address(name) {
                return NetworkAddress(nameIsIPAddress)
            }

            do {
                let result: [ARecord] = try await localSystem.queryA(name: name)
                if let firstARecordAddress = result.first?.address,
                    let ourIPv4Address = IPv4Address(firstARecordAddress.address)
                {
                    return NetworkAddress(ourIPv4Address, resolvedName: name)
                }
            } catch {
                print("Unable to resolve \(name) as an IPv4 address: \(error)")
            }
            return nil
        }
    }
}

extension Host.NetworkAddress: ExpressibleByArgument {
    /// Creates a new network address from a string.
    /// - Parameter argument: The argument to parse as a network address.
    public init?(argument: String) {
        self.init(argument)
    }
}

extension Host.NetworkAddress: Codable {}
extension Host.NetworkAddress: Hashable {}
