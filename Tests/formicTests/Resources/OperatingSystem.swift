import Dependencies
import Foundation
import Testing

@testable import Formic

@Test("parse a string to determine type of operating system")
func testOperatingSystemKindParser() async throws {
    let parser = OperatingSystem.UnameParser()
    #expect(try parser.parse("Linux\n") == .linux)
    #expect(try parser.parse("Darwin\n") == .macOS)
    #expect(try parser.parse("Linux") == .linux)
    #expect(try parser.parse("Darwin") == .macOS)
    #expect(try parser.parse("macOS") == .macOS)
    #expect(try parser.parse("linux") == .linux)

    #expect(
        throws: (any Error).self,
        performing: {
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
    let shellResult: CommandOutput = try await withDependencies {
        $0.commandInvoker = TestCommandInvoker()
            .addSuccess(command: ["uname"], presentOutput: "Linux\n")
    } operation: {
        try await OperatingSystem.inquiry.run(host: .localhost)
    }

    // results proxied for a linux host
    #expect(shellResult.returnCode == 0)
    #expect(shellResult.stdoutString == "Linux\n")
    #expect(shellResult.stderrString == nil)
}

@Test("verify the OperatingSystem.parse(_:String) function")
func testOperatingSystemParse() async throws {
    let dataToParse: Data = try #require("Linux\n".data(using: .utf8))
    #expect(OperatingSystem.parse(dataToParse).name == .linux)
}

@Test("test singular findResource for operating system")
func testOperatingSystemQuery() async throws {

    let (parsedOS, _) = try await withDependencies {
        $0.commandInvoker = TestCommandInvoker()
            .addSuccess(command: ["uname"], presentOutput: "Linux\n")

        $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
    } operation: {
        try await OperatingSystem.query(from: .localhost)
    }

    #expect(parsedOS.name == .linux)
}

@Test("test instance queryResource for operating system")
func testOperatingSystemInstanceQuery() async throws {

    let instance = OperatingSystem(.macOS)

    let (parsedOS, _) = try await withDependencies {
        $0.commandInvoker = TestCommandInvoker()
            .addSuccess(command: ["uname"], presentOutput: "Linux\n")
        $0.date.now = Date(timeIntervalSince1970: 1_234_567_890)
    } operation: {
        try await instance.query(from: .localhost)
    }

    #expect(parsedOS.name == .linux)
}
