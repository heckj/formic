import Formic
import Testing

@Test("parsing ipv4 address - good address")
func validAddressInit() async throws {
    let goodSample = "192.168.0.1"
    let first = RemoteHost.IPv4Address(goodSample)
    #expect(first?.description == goodSample)

}

@Test("parsing ipv4 address - invalid address")
func failingAddressInit() async throws {
    let badSample1 = "256.0.0.1"
    let second = RemoteHost.IPv4Address(badSample1)
    #expect(second == nil)
}

@Test("parsing ipv4 address - localhost")
func localHostValidation() async throws {
    #expect(RemoteHost.IPv4Address.localhost.description == "127.0.0.1")
}

@Test("equatable ipv4 address")
func checkIPv4AddressEquatable() async throws {
    let first = RemoteHost.IPv4Address("127.0.0.1")
    let second = RemoteHost.IPv4Address("192.168.0.1")
    #expect(first != second)
}

@Test("hashable ipv4 address")
func checkIPv4AddressHashable() async throws {
    let first = RemoteHost.IPv4Address("127.0.0.1")
    let second = RemoteHost.IPv4Address("192.168.0.1")
    #expect(first?.hashValue != second.hashValue)
}
