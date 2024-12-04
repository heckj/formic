import RegexBuilder

public struct IPv4Address: LosslessStringConvertible, Sendable {
    // It would be great if this were in a standard library built into the swift toolchain (aka Foundation)
    // but alas, it's not. There are multiple versions of this kind of type from different libraries:
    // WebURL has one at https://karwa.github.io/swift-url/main/documentation/weburl/ipv4address/
    // NIOCore has one at https://github.com/apple/swift-nio/blob/main/Sources/NIOCore/SocketAddresses.swift
    // and Apple's Network library as one.
    
    public var description: String {
        "\(octets.0).\(octets.1).\(octets.2).\(octets.3)"
    }
    
    let octets: (UInt8, UInt8, UInt8, UInt8)

    public init?(_ stringRep:String) {
        let octetRef = Reference(UInt8.self)
        let myBuilderRegex = Regex {
            TryCapture(as: octetRef) {
                OneOrMore(.digit)
            } transform: { str -> UInt8? in
                guard let intValue = UInt8(str) else {
                    return nil
                }
                return intValue
            }
            "."
            TryCapture(as: octetRef) {
                OneOrMore(.digit)
            } transform: { str -> UInt8? in
                guard let intValue = UInt8(str) else {
                    return nil
                }
                return intValue
            }
            "."
            TryCapture(as: octetRef) {
                OneOrMore(.digit)
            } transform: { str -> UInt8? in
                guard let intValue = UInt8(str) else {
                    return nil
                }
                return intValue
            }
            "."
            TryCapture(as: octetRef) {
                OneOrMore(.digit)
            } transform: { str -> UInt8? in
                guard let intValue = UInt8(str) else {
                    return nil
                }
                return intValue
            }
        }
        guard let matches = try? myBuilderRegex.wholeMatch(in: stringRep) else {
            return nil
        }
        octets = (matches.1, matches.2, matches.3, matches.4)
    }

    public init(_ octets: (UInt8, UInt8, UInt8, UInt8)) {
        self.octets = octets
    }
    
    public static let localhost = IPv4Address((127,0,0,1))
}
