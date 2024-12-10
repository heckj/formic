import Dependencies
import Foundation
import Testing

@testable import Formic

@Test("parsing uname output for determining type of operating system")
func testOSKindParsing() async throws {
    let parser = OperatingSystem.UnameParser()
    #expect(try parser.parse("Linux\n") == .linux)
    #expect(try parser.parse("Darwin\n") == .macOS)
    #expect(try parser.parse("Linux") == .linux)
    #expect(try parser.parse("Darwin") == .macOS)
}

@Test("verify string based initializer for OperatingSystem")
func testOSStringInitializer() async throws {
    #expect(OperatingSystem("Darwin").name == .macOS)
    #expect(OperatingSystem("macOS").name == .macOS)
    #expect(OperatingSystem("linux").name == .linux)
    #expect(OperatingSystem("Linux").name == .linux)
    #expect(OperatingSystem("FreeBSD").name == .unknown)
}

@Test("test resource building blocks")
func testResourceBuildingBlocks() async throws {

    let shellResult = try withDependencies {
        $0.commandInvoker = TestCommandInvoker(command: ["uname"], presentOutput: "Linux\n")
    } operation: {
        try OperatingSystem.singularInquiry.run(host: .localhost)
    }

    // results proxied for a linux host
    #expect(shellResult.returnCode == 0)
    #expect(shellResult.stdoutString == "Linux\n")
    #expect(shellResult.stderrString == nil)

    let stdout = try #require(shellResult.stdoutString)
    let parsedOS = OperatingSystem.parse(stdout)
    #expect(parsedOS.name == .linux)
}

@Test("test singular resource query for operating system")
func testOperatingSystemQuery() async throws {

    let (parsedOS, _) = try withDependencies {
        $0.commandInvoker = TestCommandInvoker(command: ["uname"], presentOutput: "Linux\n")
        $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
    } operation: {
        try OperatingSystem.findResource(from: .localhost)
    }

    #expect(parsedOS.name == .linux)
}

@Test("test instance resource query for operating system")
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
