import Foundation
import Parsing

// An example resource
// - a collection of debian packages
// - declared state of installed vs. not

// Resource pieces and operating on them:

// 0 - persist-able and comparable
//    - `Codable`, `Hashable`
//
// 1 - a declarative structure to represent what we want it to be
//    - name
//      - state (present|absent)
//    ? additional state/information (not declarable, but shown?)
//      - version
//      - architecture
//      - description
// 2 - a way query the current state - "QueryableState"
//    - `shellcommand`, `parse(_ output: String) -> Self`, used by
//      `queryState(from host: Host) throws -> (Self, Date)`
//    - should I differentiate between "checking this specific one" and "checking all"?
//
// 3 - a way to compute the changes needed to get into that desired state
//    - knowledge of (1), and `resolve()`
//
// 4 - the actions to take to make those changes
//
// 5 - a way to test the state of the resource (various diagnostic levels?)

// ex:
// > `docker-user@ubuntu:~$ dpkg -l docker-ce`
//
//Desired=Unknown/Install/Remove/Purge/Hold
//| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
//|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
//||/ Name           Version                       Architecture Description
//+++-==============-=============================-============-====================================================
//ii  docker-ce      5:27.3.1-1~ubuntu.24.04~noble arm64        Docker: the open-source application container engine

/// The kind of operating system.
public struct DebianPackage: QueryableResource {

    public enum DeclarativeState: String, Sendable, Codable {
        case present
        case absent
    }

    public enum InformationKey: String, Sendable, Codable {
        case version
        case architecture
        case description
    }

    public var name: String
    public var state: DeclarativeState
    public var infodetails: [InformationKey: String]

    public static let shellcommand: Command = .shell("dpkg", "-l")

    // borrow from https://github.com/kellyjonbrazil/jc
    // MIT License: https://github.com/kellyjonbrazil/jc/blob/master/LICENSE.md
    // - https://github.com/kellyjonbrazil/jc/blob/master/jc/parsers/dpkg_l.py
    // - https://github.com/kellyjonbrazil/jc/blob/master/docs/parsers/dpkg_l.md

    public static func parse(_ output: String) throws -> DebianPackage {
        fatalError("not implemented")
    }

}

// there's stuff I want to just "ask about" and report on, and stuff I want to "change"
// QueryableResource vs. DeclaredResource
// for both state and information bits that I query - I want to track "when I last asked" - when it was last updated.
