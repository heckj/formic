import Testing
import Formic

@Test("initializing network address")
func initNetworkAddress1() async throws {
    let goodSample = "192.168.0.1"
    
    // parsing path, checks IP v4 pattern first
    let first = await NetworkAddress(goodSample)
    #expect(first?.address.description == goodSample)
}

@Test("initializing network address - optionally valid IPv4 address")
func initNetworkAddress2() async throws {
    
    let goodSample = "192.168.0.1"
    
    // optional IPv4Address
    let third = NetworkAddress(IPv4Address(goodSample))
    #expect(third?.address.description == goodSample)
}

@Test("initializing network address - fully valid IPv4 address")
func initNetworkAddress3() async throws {
    
    let goodSample = "192.168.0.1"
    
    // fully valid IPv4Address
    guard let validIPAddress = IPv4Address(goodSample) else {
        Issue.record("\(goodSample) is not a valid IP address")
        return
    }
    let fourth = NetworkAddress(validIPAddress)
    #expect(fourth.address.description == goodSample)
}

@Test("initializing network address - dns resolution")
func initNetworkAddress4() async throws {
    
    let validDNSName = "google.com"

    let goodName = await NetworkAddress(validDNSName)
    #expect(goodName?.dnsName == validDNSName)
}

@Test("failing initializing network address - invalid IPv4 address format")
func initFailingNetworkAddress1() async throws {
    let badSample1 = "256.0.0.1"

    // parsing path, checks IP v4 pattern first, but bad IP address is an invalid address
    let second = await NetworkAddress(badSample1)
    #expect(second == nil)
}

@Test("failing initializing network address - invalid optional IPv4 address")
func initFailingNetworkAddress3() async throws {
    let invalid: IPv4Address? = nil

    let result = NetworkAddress(invalid)
    #expect(result == nil)
}

@Test("failing initializing network address - invalid DNS name")
func initFailingNetworkAddress2() async throws {
    
    let invalidDNSName = "indescribable.wurplefred"

    let badName = await NetworkAddress(invalidDNSName)
    #expect(badName == nil)
}

@Test("localhost network address")
func localhostNetworkAddress() async throws {
    #expect(NetworkAddress.localhost.address.description == "127.0.0.1")
    #expect(NetworkAddress.localhost.dnsName == "localhost")
}
