import AsyncDNSResolver

public struct NetworkAddress: Sendable {
    public let address: IPv4Address
    public let dnsName: String?
    
    public init?(_ name: String) async {
        if let nameIsIPAddress = IPv4Address(name) {
            self.address = nameIsIPAddress
            self.dnsName = nil
            return
        }
        
        guard let resolver = try? AsyncDNSResolver() else {
            print("Unable to initialize a DNS resolver")
            return nil
        }
        do {
            let result: [ARecord] = try await resolver.queryA(name: name)
            if let firstARecordAddress = result.first?.address,
               let ourIPv4Address = IPv4Address(firstARecordAddress.address) {
                address = ourIPv4Address
                dnsName = name
                return
            }
        } catch {
            print("Unable to resolve \(name) as an IPv4 address: \(error)")
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

    init(_ address: IPv4Address, resolvedName: String) {
        self.address = address
        self.dnsName = resolvedName
    }

    public static let localhost = NetworkAddress(.localhost, resolvedName: "localhost")
}

