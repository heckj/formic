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

struct DpkgState: Sendable, Hashable {
    enum DesiredState: String, Sendable, Hashable {
        case unknown = "u"
        case install = "i"
        case remove = "r"
        case purge = "p"
        case hold = "h"
    }

    enum StatusCode: String, Sendable, Hashable {
        case notInstalled = "n"
        case installed = "i"
        case configFiles = "c"
        case unpacked = "u"
        case failedConfig = "f"
        case halfInstalled = "h"
        case triggerAwait = "w"
        case triggerPending = "t"
    }

    enum ErrCode: String, Sendable, Hashable {
        case reinstall = "r"
        case none = " "
    }

    let desiredState: DesiredState
    let statusCode: StatusCode
    let errCode: ErrCode

    let name: String
    let version: String
    let architecture: String
    let description: String
}

// https://swiftpackageindex.com/pointfreeco/swift-parsing#user-content-getting-started
// https://pointfreeco.github.io/swift-parsing/0.10.0/documentation/parsing/

extension DpkgState {
    // parsing individual lines
    struct PackageCodes: Parser {
        var body: some Parser<Substring, (DesiredState, StatusCode, ErrCode)> {
            OneOf {
                DesiredState.unknown.rawValue.map { DesiredState.unknown }
                DesiredState.install.rawValue.map { DesiredState.install }
                DesiredState.remove.rawValue.map { DesiredState.remove }
                DesiredState.purge.rawValue.map { DesiredState.purge }
                DesiredState.hold.rawValue.map { DesiredState.hold }
            }
            OneOf {
                StatusCode.notInstalled.rawValue.map { StatusCode.notInstalled }
                StatusCode.installed.rawValue.map { StatusCode.installed }
                StatusCode.configFiles.rawValue.map { StatusCode.configFiles }
                StatusCode.unpacked.rawValue.map { StatusCode.unpacked }
                StatusCode.halfInstalled.rawValue.map { StatusCode.halfInstalled }
                StatusCode.triggerAwait.rawValue.map { StatusCode.triggerAwait }
                StatusCode.triggerPending.rawValue.map { StatusCode.triggerPending }
            }
            OneOf {
                ErrCode.reinstall.rawValue.map { ErrCode.reinstall }
                ErrCode.none.rawValue.map { ErrCode.none }
            }
        }
    }

    struct PackageStatus: Parser {
        var body: some Parser<Substring, DpkgState> {
            Parse(DpkgState.init) {
                PackageCodes()
                Skip {
                    // whitespace
                    Whitespace()
                    //Prefix { $0.isWhitespace }
                }
                // package name
                Prefix { !$0.isWhitespace }.map(String.init)
                Skip {
                    Whitespace()
                    // whitespace
                    //Prefix { $0.isWhitespace }
                }
                // version
                Prefix { !$0.isWhitespace }.map(String.init)
                Skip {
                    Whitespace()
                    // whitespace
                    //Prefix { $0.isWhitespace }
                }
                // architecture
                Prefix { !$0.isWhitespace }.map(String.init)
                Skip {
                    // whitespace
                    Whitespace()
                    //Prefix { $0.isWhitespace }
                }
                // description
                Prefix {
                    $0 != "\n"
                }.map(String.init)
            }
        }
    }
}

extension DpkgState {
    // parsing `dpkg -l` output
    struct DpkgHeader: Parser {
        var body: some Parser<Substring, Void> {
            Skip {
                PrefixThrough("========")
            }
            Skip {
                PrefixThrough("\n")
            }
        }
    }

    struct PackageList: Parser {
        var body: some Parser<Substring, [DpkgState]> {
            DpkgState.DpkgHeader()
            Many(1...) {
                PackageStatus()
            } separator: {
                "\n"
            }
        }
    }
}
