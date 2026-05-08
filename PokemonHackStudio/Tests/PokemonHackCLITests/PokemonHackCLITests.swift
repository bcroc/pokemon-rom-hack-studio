import XCTest
@testable import pokemonhack_cli

final class PokemonHackCLITests: XCTestCase {
    private var temporaryDirectories: [URL] = []

    override func tearDownWithError() throws {
        for url in temporaryDirectories {
            try? FileManager.default.removeItem(at: url)
        }
        temporaryDirectories.removeAll()
        try super.tearDownWithError()
    }

    func testPlaytestHeadlessAndLaunchEmitJSONWithoutApplyingSideEffects() throws {
        let root = try makeEmeraldProject()

        let headless = try decodeJSON(
            PokemonHackCLI.run(arguments: ["playtest", root.path, "--headless", "--json"])
        )
        XCTAssertEqual(headless["mode"] as? String, "headless")
        XCTAssertEqual(headless["isRunnable"] as? Bool, false)
        XCTAssertNotNil(headless["session"])

        let launch = try decodeJSON(
            PokemonHackCLI.run(arguments: ["playtest", root.path, "--launch", "--json"])
        )
        XCTAssertEqual(launch["mode"] as? String, "interactive")
        XCTAssertEqual(launch["status"] as? String, "blocked")
        XCTAssertNil(launch["processID"] as? Int)
        XCTAssertNotNil(launch["artifacts"])
    }

    func testPlaytestUnknownModeThrowsUsage() throws {
        let root = try makeEmeraldProject()

        XCTAssertThrowsError(
            try PokemonHackCLI.run(arguments: ["playtest", root.path, "--bogus", "--json"])
        ) { error in
            XCTAssertEqual(error as? CLIError, .usage)
        }
    }

    func testGraphicsImportPlanCommandEmitsPreviewJSON() throws {
        let root = try makeEmeraldProject()
        let package = try makeTemporaryDirectory().appendingPathComponent("local-pack")
        try write("Credit: local fixture\n", to: package.appendingPathComponent("credits.txt"))
        try writePNG(width: 16, height: 16, paletteColors: 8, to: package.appendingPathComponent("top.png"))
        try write("id,behavior,layer\n", to: package.appendingPathComponent("attributes.csv"))

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["graphics-import-plan", root.path, package.path, "--json"])
        )

        XCTAssertEqual(result["readiness"] as? String, "ready")
        XCTAssertEqual(result["isPreviewOnly"] as? Bool, true)
        XCTAssertNotNil(result["copyPlan"])
        XCTAssertNotNil(result["layeredTilesetDryRun"])
    }

    func testRomGraphCommandEmitsSemanticRuns() throws {
        let rom = try makeTestROM()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["rom-graph", rom.path, "--json"])
        )

        XCTAssertNotNil(result["headerFacts"])
        XCTAssertNotNil(result["semanticRuns"])
        XCTAssertNotNil(result["anchors"])
        XCTAssertNotNil(result["pointerCandidates"])
    }

    private func makeEmeraldProject() throws -> URL {
        let root = try makeTemporaryDirectory()
        try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("src"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/pokenav"), withIntermediateDirectories: true)
        return root
    }

    private func makeTemporaryDirectory() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackCLITests-\(UUID().uuidString)")
        temporaryDirectories.append(root)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func makeTestROM() throws -> URL {
        let root = try makeTemporaryDirectory()
        let rom = root.appendingPathComponent("test.gba")
        var bytes = [UInt8](repeating: 0xff, count: 0x200)
        bytes.replaceSubrange(0x04..<0xA0, with: Array(repeating: 1, count: 0x9C))
        bytes.replaceSubrange(0xA0..<0xAC, with: Array("POKEMON TEST".utf8))
        bytes.replaceSubrange(0xAC..<0xB0, with: Array("BPEE".utf8))
        bytes.replaceSubrange(0xB0..<0xB2, with: Array("01".utf8))
        bytes[0x100] = 0x80
        bytes[0x101] = 0x00
        bytes[0x102] = 0x00
        bytes[0x103] = 0x08
        try Data(bytes).write(to: rom)
        return rom
    }

    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func writePNG(width: UInt32, height: UInt32, paletteColors: Int, to url: URL) throws {
        var data = Data([137, 80, 78, 71, 13, 10, 26, 10])
        appendChunk("IHDR", payload: pngIHDR(width: width, height: height), to: &data)
        appendChunk("PLTE", payload: Data(repeating: 0, count: paletteColors * 3), to: &data)
        appendChunk("IEND", payload: Data(), to: &data)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }

    private func pngIHDR(width: UInt32, height: UInt32) -> Data {
        var data = Data()
        appendUInt32BE(width, to: &data)
        appendUInt32BE(height, to: &data)
        data.append(contentsOf: [8, 3, 0, 0, 0])
        return data
    }

    private func appendChunk(_ type: String, payload: Data, to data: inout Data) {
        appendUInt32BE(UInt32(payload.count), to: &data)
        data.append(Data(type.utf8))
        data.append(payload)
        appendUInt32BE(0, to: &data)
    }

    private func appendUInt32BE(_ value: UInt32, to data: inout Data) {
        data.append(UInt8((value >> 24) & 0xff))
        data.append(UInt8((value >> 16) & 0xff))
        data.append(UInt8((value >> 8) & 0xff))
        data.append(UInt8(value & 0xff))
    }

    private func decodeJSON(_ json: String) throws -> [String: Any] {
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
