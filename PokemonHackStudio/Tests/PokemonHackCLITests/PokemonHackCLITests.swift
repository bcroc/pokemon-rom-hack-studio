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

    private func makeEmeraldProject() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackCLITests-\(UUID().uuidString)")
        temporaryDirectories.append(root)
        try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("src"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/pokenav"), withIntermediateDirectories: true)
        return root
    }

    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func decodeJSON(_ json: String) throws -> [String: Any] {
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
