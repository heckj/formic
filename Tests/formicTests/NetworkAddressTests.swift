import Dependencies
import Testing

@testable import Formic

@Test("initializing network address")
func validIPv4AddressAsStringInit() async throws {
    let goodSample = "192.168.0.1"

    // parsing path, checks IP v4 pattern first
    let first = RemoteHost.NetworkAddress(goodSample)
    #expect(first?.address.description == goodSample)
}

@Test("initializing network address - optionally valid IPv4 address")
func validOptionalIPv4AddressInit() async throws {

    let goodSample = "192.168.0.1"

    // optional IPv4Address
    let third = RemoteHost.NetworkAddress(RemoteHost.IPv4Address(goodSample))
    #expect(third?.address.description == goodSample)
}

@Test("initializing network address - fully valid IPv4 address")
func validIPv4AddressInit() async throws {

    let goodSample = "192.168.0.1"

    // fully valid IPv4Address
    guard let validIPAddress = RemoteHost.IPv4Address(goodSample) else {
        Issue.record("\(goodSample) is not a valid IP address")
        return
    }
    let fourth = RemoteHost.NetworkAddress(validIPAddress)
    #expect(fourth.address.description == goodSample)
}

@Test(
    "failing initializing network address - invalid optional IPv4 address",
    .timeLimit(.minutes(1)),
    .tags(.functionalTest))
func nilOptionalIPv4Address() async throws {
    let invalid: RemoteHost.IPv4Address? = nil

    let result = RemoteHost.NetworkAddress(invalid)
    #expect(result == nil)
}

@Test("initializing network address - dns resolution")
func initNetworkAddress4() async throws {

    let validDNSName = "google.com"

    let goodName = await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess(dnsName: validDNSName, ipAddressesToUse: ["8.8.8.8"])
    } operation: {
        await RemoteHost.NetworkAddress.resolve(validDNSName)
    }

    #expect(goodName?.dnsName == validDNSName)
}

@Test("failing initializing network address - invalid DNS name")
func invalidDNSNameResolution() async throws {

    let invalidDNSName = "indescribable.wurplefred"

    let badName = await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
    } operation: {
        await RemoteHost.NetworkAddress.resolve(invalidDNSName)
    }

    #expect(badName == nil)
}

@Test("failing resolve network address - nil")
func nilNameResolve() async throws {
    let badName = await RemoteHost.NetworkAddress.resolve(nil)
    #expect(badName == nil)
}

@Test("failing initializing network address - invalid IPv4 address format")
func invalidIPAddressResolver() async throws {
    let badSample1 = "256.0.0.1"

    // parsing path, checks IP v4 pattern first, but bad IP address is an invalid address
    let second = await withDependencies { dependencyValues in
        dependencyValues.localSystemAccess = TestFileSystemAccess()
    } operation: {
        await RemoteHost.NetworkAddress.resolve(badSample1)
    }

    #expect(second == nil)
}

@Test("localhost network address")
func localhostNetworkAddressByStaticVar() async throws {
    #expect(RemoteHost.NetworkAddress.localhost.address.description == "127.0.0.1")
    #expect(RemoteHost.NetworkAddress.localhost.dnsName == "localhost")
}

@Test("localhost network address name")
func localhostNetworkAddressByName() async throws {
    let example = RemoteHost.NetworkAddress("localhost")
    #expect(example?.address.description == "127.0.0.1")
    #expect(example?.dnsName == "localhost")
}

@Test("localhost network address name by address")
func localhostNetworkAddressByAddress() async throws {
    let example = RemoteHost.NetworkAddress("127.0.0.1")
    #expect(example?.address.description == "127.0.0.1")
    #expect(example?.dnsName == nil)
}
