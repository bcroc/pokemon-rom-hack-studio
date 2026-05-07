import XCTest
@testable import PokemonHackCore

final class ScriptReadinessTests: XCTestCase {
    private var temporaryDirectories: [ScriptReadinessTemporaryDirectory] = []

    override func tearDown() {
        temporaryDirectories.removeAll()
        super.tearDown()
    }

    func testMapReadinessResolvesEventScriptsBuildOutputAndPlaytestHandoff() throws {
        let root = try makeReadinessProject(includeROMOutput: true)
        let report = ScriptReadinessReportBuilder.build(
            index: makeIndex(root: root),
            target: ScriptReadinessTarget(kind: .map, identifier: "MAP_ROUTE1"),
            toolResolver: availableTools(["make": "/usr/bin/make", "mgba": "/Applications/mGBA.app"])
        )

        XCTAssertTrue(report.isReady)
        XCTAssertEqual(report.status, .passed)
        XCTAssertEqual(report.mapContext?.mapName, "Route1")
        XCTAssertEqual(report.mapContext?.eventScriptLabels, ["Route1_EventScript_NPC"])
        XCTAssertTrue(report.checks.contains { $0.id == "source:event-script:Route1_EventScript_NPC:object:0" && $0.status == .passed })
        XCTAssertTrue(report.checks.contains { $0.id == "build:output:emerald-build" && $0.status == .passed })
        XCTAssertTrue(report.checks.contains { $0.id == "playtest:runnable" && $0.status == .passed })
    }

    func testScriptReadinessBlocksMissingLabelAndMissingROMCandidate() throws {
        let root = try makeReadinessProject(includeROMOutput: false)
        let report = ScriptReadinessReportBuilder.build(
            index: makeIndex(root: root),
            target: ScriptReadinessTarget(kind: .script, identifier: "Missing_EventScript"),
            toolResolver: availableTools(["make": "/usr/bin/make"])
        )

        XCTAssertFalse(report.isReady)
        XCTAssertEqual(report.status, .blocked)
        XCTAssertTrue(report.checks.contains { $0.id == "source:script-target" && $0.status == .blocked })
        XCTAssertTrue(report.checks.contains { $0.id == "build:output:emerald-build" && $0.status == .blocked })
        XCTAssertTrue(report.checks.contains { $0.id == "playtest:rom-candidate" && $0.status == .blocked })
        XCTAssertTrue(report.diagnostics.contains { $0.code == "SCRIPT_READINESS_BLOCKED" })
    }

    private func makeReadinessProject(includeROMOutput: Bool) throws -> URL {
        let temp = try ScriptReadinessTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url

        try write(
            """
            {
              "group_order": ["gMapGroup_Routes"],
              "gMapGroup_Routes": ["Route1"]
            }
            """,
            to: root.appendingPathComponent("data/maps/map_groups.json")
        )
        try write(
            """
            {
              "layouts_table_label": "gMapLayouts",
              "layouts": [
                {
                  "id": "LAYOUT_ROUTE1",
                  "name": "Route1_Layout",
                  "width": 1,
                  "height": 1,
                  "border_width": 0,
                  "border_height": 0,
                  "primary_tileset": "gTileset_General",
                  "secondary_tileset": "gTileset_Route",
                  "border_filepath": "data/layouts/Route1/border.bin",
                  "blockdata_filepath": "data/layouts/Route1/map.bin"
                }
              ]
            }
            """,
            to: root.appendingPathComponent("data/layouts/layouts.json")
        )
        try write(
            """
            {
              "id": "MAP_ROUTE1",
              "name": "Route1",
              "layout": "LAYOUT_ROUTE1",
              "connections": [],
              "object_events": [
                {
                  "local_id": "LOCALID_ROUTE1_NPC",
                  "type": "object",
                  "x": 1,
                  "y": 1,
                  "elevation": 3,
                  "script": "Route1_EventScript_NPC"
                }
              ],
              "warp_events": [],
              "coord_events": [],
              "bg_events": []
            }
            """,
            to: root.appendingPathComponent("data/maps/Route1/map.json")
        )
        try write(
            """
            Route1_EventScript_NPC::
                lock
                msgbox Route1_Text
                release
                end

            Route1_Text::
                .string "Ready.$"
            """,
            to: root.appendingPathComponent("data/maps/Route1/scripts.inc")
        )
        try writeWords([0], to: root.appendingPathComponent("data/layouts/Route1/map.bin"))
        try writeWords([0], to: root.appendingPathComponent("data/layouts/Route1/border.bin"))
        if includeROMOutput {
            try write(Data("abc".utf8), to: root.appendingPathComponent("pokeemerald.gba"))
        }
        return root
    }

    private func makeIndex(root: URL) -> ProjectIndex {
        ProjectIndex(
            root: SourceLocation(path: root.path, exists: true),
            profile: .pokeemerald,
            adapterID: "test.adapter",
            adapterName: "Test Adapter",
            editorModules: [.maps, .scripts, .build],
            capabilities: [.mapIndex, .layoutIndex, .scriptOutline, .buildRunner, .playtestBridge, .diagnostics],
            writePolicy: .mutationPlanOnly,
            documents: [
                SourceDocument(relativePath: "data/maps/map_groups.json", kind: .json, exists: true),
                SourceDocument(relativePath: "data/layouts/layouts.json", kind: .layoutJson, exists: true),
                SourceDocument(relativePath: "data/maps/Route1/map.json", kind: .mapJson, exists: true),
                SourceDocument(relativePath: "data/maps/Route1/scripts.inc", kind: .script, exists: true)
            ],
            buildTargets: [
                BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
            ]
        )
    }

    private func availableTools(_ pathsByTool: [String: String]) -> ToolAvailabilityResolver {
        { tool in
            if let path = pathsByTool[tool] {
                return ToolAvailability(name: tool, isAvailable: true, resolvedPath: path)
            }
            return ToolAvailability(name: tool, isAvailable: false)
        }
    }

    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func write(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }

    private func writeWords(_ words: [UInt16], to url: URL) throws {
        var data = Data()
        for word in words {
            data.append(UInt8(word & 0x00ff))
            data.append(UInt8((word >> 8) & 0x00ff))
        }
        try write(data, to: url)
    }
}

private final class ScriptReadinessTemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackScriptReadinessTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
