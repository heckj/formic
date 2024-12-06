import ArgumentParser
import RegexBuilder

/// An IPv4 address.
public struct IPv4Address: LosslessStringConvertible, Sendable {
    // It would be great if this were in a standard library built into the swift toolchain (aka Foundation)
    // but alas, it's not. There are multiple versions of this kind of type from different libraries:
    // WebURL has one at https://karwa.github.io/swift-url/main/documentation/weburl/ipv4address/
    // NIOCore has one at https://github.com/apple/swift-nio/blob/main/Sources/NIOCore/SocketAddresses.swift
    // and Apple's Network library as one.

    public var description: String {
        "\(octets.0).\(octets.1).\(octets.2).\(octets.3)"
    }

    enum CodingKeys: String, CodingKey {
        case a = "a"
        case b = "b"
        case c = "c"
        case d = "d"
    }

    let octets: (UInt8, UInt8, UInt8, UInt8)

    public init?(_ stringRep: String) {
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

    public static let localhost = IPv4Address((127, 0, 0, 1))
}

extension IPv4Address: ExpressibleByArgument {}

extension IPv4Address: Hashable {
    /// Returns a Boolean value that indicates whether two IPv4 addresses are equal.
    /// - Parameters:
    ///   - lhs: the first address to compare.
    ///   - rhs: the second address to compare.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.octets == rhs.octets
    }

    /// Calculates the hash value for the IPv4 address.
    /// - Parameter hasher: The hasher to combine the values with.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(octets.0)
        hasher.combine(octets.1)
        hasher.combine(octets.2)
        hasher.combine(octets.3)
    }

}

extension IPv4Address: Codable {
    /// Creates an IPv4 address from a decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let a = try values.decode(UInt8.self, forKey: .a)
        let b = try values.decode(UInt8.self, forKey: .b)
        let c = try values.decode(UInt8.self, forKey: .c)
        let d = try values.decode(UInt8.self, forKey: .d)
        octets = (a, b, c, d)
    }

    /// Encodes an IPv4 address to a decoder.
    /// - Parameter encoder: the encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let (a, b, c, d) = self.octets
        try container.encode(a, forKey: .a)
        try container.encode(b, forKey: .b)
        try container.encode(c, forKey: .c)
        try container.encode(d, forKey: .d)
    }
}
