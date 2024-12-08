import Foundation
import Parsing  // temp while I work out how to use the parser
import Testing

@testable import Formic

let bigSample = """
    Desired=Unknown/Install/Remove/Purge/Hold
    | Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
    |/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
    ||/ Name                          Version                           Architecture Description
    +++-=============================-=================================-============-=====================================================================
    ii  adduser                       3.137ubuntu1                      all          add and remove users and groups
    ii  apparmor                      4.0.1really4.0.1-0ubuntu0.24.04.3 arm64        user-space parser utility for AppArmor
    ii  apt                           2.7.14build2                      arm64        commandline package manager
    ii  apt-utils                     2.7.14build2                      arm64        package management related utility programs
    ii  base-files                    13ubuntu10.1                      arm64        Debian base system miscellaneous files
    ii  base-passwd                   3.6.3build1                       arm64        Debian base system master password and group files
    ii  bash                          5.2.21-2ubuntu4                   arm64        GNU Bourne Again SHell
    ii  bsdutils                      1:2.39.3-9ubuntu6.1               arm64        basic utilities from 4.4BSD-Lite
    ii  ca-certificates               20240203                          all          Common CA certificates
    ii  console-setup                 1.226ubuntu1                      all          console font and keymap setup program
    ii  console-setup-linux           1.226ubuntu1                      all          Linux specific part of console-setup
    ii  containerd.io                 1.7.24-1                          arm64        An open and reliable container runtime
    ii  coreutils                     9.4-3ubuntu6                      arm64        GNU core utilities
    ii  cron                          3.0pl1-184ubuntu2                 arm64        process scheduling daemon
    ii  cron-daemon-common            3.0pl1-184ubuntu2                 all          process scheduling daemon's configuration files
    ii  curl                          8.5.0-2ubuntu10.5                 arm64        command line tool for transferring data with URL syntax
    ii  dash                          0.5.12-6ubuntu5                   arm64        POSIX-compliant shell
    ii  dbus                          1.14.10-4ubuntu4.1                arm64        simple interprocess messaging system (system message bus)
    ii  dbus-bin                      1.14.10-4ubuntu4.1                arm64        simple interprocess messaging system (command line utilities)
    """

@Test("package parsing - one line")
func verifyParsingOneLine() async throws {
    let sample =
        "ii  apt                           2.7.14build2                      arm64        commandline package manager\n"
    let result = try PackageStatus().parse(sample)
    print(result)
}

@Test("matching the header")
func veriyHeaderParse() async throws {
    let headerSample = """
        Desired=Unknown/Install/Remove/Purge/Hold
        | Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
        |/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
        ||/ Name                          Version                           Architecture Description
        +++-=============================-=================================-============-=====================================================================
        what?
        """
    var x: Substring = headerSample[...]
    try DpkgHeader().parse(&x)
    #expect(x == "what?")
}

@Test("package parsing - dpkg output")
func verifyParsingMultilineOutputString() async throws {
    let result = try PackageList().parse(bigSample)
    print(result)
}

// https://swiftpackageindex.com/pointfreeco/swift-parsing#user-content-getting-started
// https://pointfreeco.github.io/swift-parsing/0.10.0/documentation/parsing/

struct DpkgHeader: Parser {
    var body: some Parser<Substring, Void> {
        Skip {
            PrefixThrough("========")
        }
        Skip {
            PrefixUpTo("\n")
        }
        Skip {
            Prefix { $0.isNewline }
        }
    }
}

struct PackageList: Parser {
    var body:
        some Parser<
            Substring,
            [(
                PackageCodes.DesiredState, PackageCodes.StatusCode, PackageCodes.ErrCode, Substring, Substring,
                Substring, Substring
            )]
        >
    {
        DpkgHeader()
        Many(1...) {
            PackageStatus()
        } separator: {
            "\n"
        }
    }
}

// individual lines

struct PackageCodes: Parser {
    enum DesiredState: String {
        case unknown = "u"
        case install = "i"
        case remove = "r"
        case purge = "p"
        case hold = "h"
    }
    enum StatusCode: String {
        case notInstalled = "n"
        case installed = "i"
        case configFiles = "c"
        case unpacked = "u"
        case failedConfig = "f"
        case halfInstalled = "h"
        case triggerAwait = "w"
        case triggerPending = "t"
    }
    enum ErrCode: String {
        case reinstall = "r"
        case none = " "
    }
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
    var body:
        some Parser<
            Substring,
            (
                PackageCodes.DesiredState, PackageCodes.StatusCode, PackageCodes.ErrCode, Substring, Substring,
                Substring, Substring
            )
        >
    {
        PackageCodes()
        Skip {
            // whitespace
            Prefix { $0.isWhitespace }
        }
        Prefix { !$0.isWhitespace }  // package name
        Skip {
            // whitespace
            Prefix { $0.isWhitespace }
        }
        Prefix { !$0.isWhitespace }  // version
        Skip {
            // whitespace
            Prefix { $0.isWhitespace }
        }
        Prefix { !$0.isWhitespace }  //architecture
        Skip {
            // whitespace
            Prefix { $0.isWhitespace }
        }
        Rest().map(Substring.init)  // description
    }
}
