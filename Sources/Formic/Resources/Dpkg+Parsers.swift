import Foundation
import Parsing

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
