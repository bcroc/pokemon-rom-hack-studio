import XCTest
@testable import PokemonHackCore

final class ScriptParserTests: XCTestCase {
    func testParseLabel() {
        let line = "PetalburgCity_EventScript_Boy::"
        let parsed = ScriptParser.parseLine(line, lineNumber: 1)
        if case .label(let name, _) = parsed {
            XCTAssertEqual(name, "PetalburgCity_EventScript_Boy")
        } else {
            XCTFail("Expected label, got \(parsed)")
        }
    }

    func testParseCommandWithArgs() {
        let line = "\tmsgbox Route102_Text_WatchMeCatchPokemon, MSGBOX_DEFAULT"
        let parsed = ScriptParser.parseLine(line, lineNumber: 1)
        if case .command(let cmd, _) = parsed {
            XCTAssertEqual(cmd.name, "msgbox")
            XCTAssertEqual(cmd.arguments, ["Route102_Text_WatchMeCatchPokemon", "MSGBOX_DEFAULT"])
        } else {
            XCTFail("Expected command, got \(parsed)")
        }
    }

    func testParseCommandWithComment() {
        let line = "\tend @ End the script"
        let parsed = ScriptParser.parseLine(line, lineNumber: 1)
        if case .command(let cmd, _) = parsed {
            XCTAssertEqual(cmd.name, "end")
            XCTAssertEqual(cmd.comment, "End the script")
        } else {
            XCTFail("Expected command, got \(parsed)")
        }
    }

    func testParseDirective() {
        let line = "\t.string \"Hello world!$\""
        let parsed = ScriptParser.parseLine(line, lineNumber: 1)
        if case .directive(let name, let value, _) = parsed {
            XCTAssertEqual(name, ".string")
            XCTAssertEqual(value, "\"Hello world!$\"")
        } else {
            XCTFail("Expected directive, got \(parsed)")
        }
    }

    func testParseArgumentsWithCommasInQuotes() {
        let line = "\tmsgbox \"Hello, world!\", MSGBOX_DEFAULT"
        let parsed = ScriptParser.parseLine(line, lineNumber: 1)
        if case .command(let cmd, _) = parsed {
            XCTAssertEqual(cmd.arguments, ["\"Hello, world!\"", "MSGBOX_DEFAULT"])
        } else {
            XCTFail("Expected command, got \(parsed)")
        }
    }

    func testParseComplexArguments() {
        let line = "\tcall_if_eq VAR_PETALBURG_CITY_STATE, 0, PetalburgCity_EventScript_MoveGymBoyToWestEntrance @ Comment"
        let parsed = ScriptParser.parseLine(line, lineNumber: 1)
        if case .command(let cmd, _) = parsed {
            XCTAssertEqual(cmd.name, "call_if_eq")
            XCTAssertEqual(cmd.arguments, ["VAR_PETALBURG_CITY_STATE", "0", "PetalburgCity_EventScript_MoveGymBoyToWestEntrance"])
            XCTAssertEqual(cmd.comment, "Comment")
        } else {
            XCTFail("Expected command, got \(parsed)")
        }
    }
}
