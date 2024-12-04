import Testing
import Formic

@Test("parsing ipv4 address - good address")
func initIPv4Address1() async throws {
    
    let goodSample = "192.168.0.1"
    
    let first = IPv4Address(goodSample)
    #expect(first?.description == goodSample)

}

@Test("parsing ipv4 address - invalid address")
func initIPv4Address2() async throws {
    let badSample1 = "256.0.0.1"
    let second = IPv4Address(badSample1)
    #expect(second == nil)
}

@Test("parsing ipv4 address - localhost")
func IPv4Address_localhost() async throws {
    #expect(IPv4Address.localhost.description == "127.0.0.1")
}
