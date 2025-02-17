import ArgumentParser
import AsyncDNSResolver
import Dependencies

// Host - yeah, in hindsight a terrible name choice for it's conflict with Foundation.Host -
// represents are remote system - an IP address or DNS name. The initializer has taking a string
// uses AsyncDNSResolver to resolve the name to an IP address.

// There's also the concept of "remote" vs. "local", which I'm not sure is really needed for what
// I'm after, but initially I thought it was useful to have so I could invoke "local" commands
// or "remote" ones. I suspect a "remote only" API interface would be more than sufficient for most
// of what I'm after, which could simplify this quite a bit.

// Also in practice, I'm using this for configuring infrastructure, so the whole process of using a name
// doesn't make as much sense as I originally thought it might. Names are pointing for services,
// often representing either a CDN or a load balancer somewhere, while the thing I want to reach into
// and configure is available as an IP address, sometimes only available through another bastion host.

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
