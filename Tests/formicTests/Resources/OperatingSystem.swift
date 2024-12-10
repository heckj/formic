import Dependencies
import Foundation
import Testing

@testable import Formic

// Things to test for a type that's a Resource:
//
// - If the type includes a parser as a sep. type, work that directly with various inputs
// static Self.parse(_:String) throws -> Self
// functional-mock - instance.queryResource(from: Host) throws -> (Self, Date)
//
// --------------------------------------
// tests for SingularResource:
//
// functional-mock - Self.findResource(from: Host) throws -> (Self, Date) (also uses static parse)
//
// --------------------------------------
// tests for NamedResource:
//
// functional-mock - Self.findResource(_:String, from: Host) throws -> Self
// (typically uses the static parse, with name used in the command to to request the resource)
//
// --------------------------------------
// tests for CollectionQueryableResource:
//
// static collectionParse(_:String) throws -> [Self]
// functional-mock - Self.queryResourceCollection(from: Host) throws -> ([Self],Date) (uses collectionParse)
//

@Test("parse a string to determine type of operating system")
func testOperatingSystemKindParser() async throws {
    let parser = OperatingSystem.UnameParser()
    #expect(try parser.parse("Linux\n") == .linux)
    #expect(try parser.parse("Darwin\n") == .macOS)
    #expect(try parser.parse("Linux") == .linux)
    #expect(try parser.parse("Darwin") == .macOS)
    #expect(try parser.parse("macOS") == .macOS)
    #expect(try parser.parse("linux") == .linux)
    
    #expect(throws: (any Error).self, performing: {
        try parser.parse("FreeBSD")
    })
}

@Test("verify string based initializer for OperatingSystem")
func testOSStringInitializer() async throws {
    #expect(OperatingSystem("linux").name == .linux)
    #expect(OperatingSystem("").name == .unknown)
}

@Test("verify the OperatingSystem.singularInquiry(_:String) function")
func testOperatingSystemSingularInquiry() async throws {
    let shellResult: CommandOutput = try withDependencies {
        $0.commandInvoker = TestCommandInvoker(command: ["uname"], presentOutput: "Linux\n")
    } operation: {
        try OperatingSystem.singularInquiry.run(host: .localhost)
    }

    // results proxied for a linux host
    #expect(shellResult.returnCode == 0)
    #expect(shellResult.stdoutString == "Linux\n")
    #expect(shellResult.stderrString == nil)
}

@Test("verify the OperatingSystem.parse(_:String) function")
func testOperatingSystemParse() async throws {
    #expect(OperatingSystem.parse("Linux\n").name == .linux)
}

@Test("test singular findResource for operating system")
func testOperatingSystemQuery() async throws {

    let (parsedOS, _) = try withDependencies {
        $0.commandInvoker = TestCommandInvoker(command: ["uname"], presentOutput: "Linux\n")
        $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
    } operation: {
        try OperatingSystem.findResource(from: .localhost)
    }

    #expect(parsedOS.name == .linux)
}

@Test("test instance queryResource for operating system")
func testOperatingSystemInstanceQuery() async throws {

    let instance = OperatingSystem(.macOS)

    let (parsedOS, _) = try withDependencies {
        $0.commandInvoker = TestCommandInvoker(command: ["uname"], presentOutput: "Linux\n")
        $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
    } operation: {
        try instance.queryResource(from: .localhost)
    }

    #expect(parsedOS.name == .linux)
}
