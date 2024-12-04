import Formic
import Testing

@Test("parsing ipv4 address - good address")
func validAddressInit() async throws {

    let goodSample = "192.168.0.1"

    let first = IPv4Address(goodSample)
    #expect(first?.description == goodSample)

}

@Test("parsing ipv4 address - invalid address")
func failingAddressInit() async throws {
    let badSample1 = "256.0.0.1"
    let second = IPv4Address(badSample1)
    #expect(second == nil)
}

@Test("parsing ipv4 address - localhost")
func localHostValidation() async throws {
    #expect(IPv4Address.localhost.description == "127.0.0.1")
}
