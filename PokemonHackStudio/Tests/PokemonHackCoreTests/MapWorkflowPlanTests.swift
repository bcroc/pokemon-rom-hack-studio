import XCTest
@testable import PokemonHackCore

final class MapWorkflowPlanTests: XCTestCase {
    func testDuplicationPlanCapturesSourceSnapshotsAndEnablesApply() throws {
        let root = try makeTemporaryProjectRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        try write(#"{"id":"MAP_OLDALE_TOWN","name":"OldaleTown","layout":"LAYOUT_OLDALE_TOWN"}"#, to: root.appendingPathComponent("data/maps/OldaleTown/map.json"))
        try write("[\"OldaleTown\"]", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write(#"{"layouts":[{"id":"LAYOUT_OLDALE_TOWN","name":"OldaleTown","blockdata_filepath":"data/layouts/OldaleTown/map.bin","border_filepath":"data/layouts/OldaleTown/border.bin"}]}"#, to: root.appendingPathComponent("data/layouts/layouts.json"))
        try write(Data(repeating: 0, count: 8), to: root.appendingPathComponent("data/layouts/OldaleTown/map.bin"))
        try write(Data(repeating: 0, count: 8), to: root.appendingPathComponent("data/layouts/OldaleTown/border.bin"))

        let catalog = ProjectMapCatalog(
            id: "emerald",
            rootPath: root.path,
            profile: .pokeemerald,
            mapGroups: [],
            maps: [
                MapDescriptor(
                    id: "MAP_OLDALE_TOWN",
                    name: "OldaleTown",
                    sourcePath: "data/maps/OldaleTown/map.json",
                    groupID: nil,
                    groupIndex: nil,
                    mapIndexInGroup: nil,
                    layout: "LAYOUT_OLDALE_TOWN",
                    layoutSlotIndex: 0,
                    music: nil,
                    mapType: nil,
                    weather: nil,
                    regionMapSection: "MAPSEC_OLDALE_TOWN",
                    floorNumber: nil,
                    sharedEventsMap: nil,
                    sharedScriptsMap: nil
                )
            ],
            layoutSlots: [
                LayoutSlot(
                    slotIndex: 0,
                    layoutID: "LAYOUT_OLDALE_TOWN",
                    name: "OldaleTown",
                    width: 2,
                    height: 2,
                    borderWidth: 2,
                    borderHeight: 2,
                    primaryTileset: nil,
                    secondaryTileset: nil,
                    borderFilepath: "data/layouts/OldaleTown/border.bin",
                    blockdataFilepath: "data/layouts/OldaleTown/map.bin",
                    sourcePath: "data/layouts/layouts.json"
                )
            ]
        )

        let plan = MapWorkflowPlanner.planDuplication(
            catalog: catalog,
            sourceMapID: "MAP_OLDALE_TOWN",
            proposedMapID: "MAP_CODEX_TEST",
            proposedMapName: "CodexTest"
        )

        XCTAssertTrue(plan.executionState.canApply, "\(plan.executionState.reasons)")
        XCTAssertTrue(plan.mutationPlan.requiresExplicitApply)
        XCTAssertTrue(plan.plannedFiles.contains { $0.destinationPath == "data/maps/CodexTest/map.json" })
        XCTAssertTrue(plan.plannedFiles.contains { $0.destinationPath == "data/layouts/OldaleTown_Copy/map.bin" })
        XCTAssertTrue(plan.sourceSnapshots.contains { $0.relativePath == "data/maps/OldaleTown/map.json" && $0.exists })

        let result = try MapWorkflowApplier.applyDuplication(plan: plan)
        XCTAssertEqual(result.selectedMapID, "MAP_CODEX_TEST")
        XCTAssertTrue(result.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(result.appliedFiles.contains { $0.path == "data/maps/CodexTest/map.json" })
        XCTAssertTrue(result.appliedFiles.contains { $0.path == "data/maps/map_groups.json" && $0.backupPath != nil })
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedFiles.first { $0.path == "data/maps/map_groups.json" }?.backupPath ?? ""))
        let duplicatedMap = try String(contentsOf: root.appendingPathComponent("data/maps/CodexTest/map.json"), encoding: .utf8)
        XCTAssertTrue(duplicatedMap.contains("MAP_CODEX_TEST"))
        XCTAssertTrue(duplicatedMap.contains("CodexTest"))
        XCTAssertTrue(duplicatedMap.contains("LAYOUT_OLDALE_TOWN_COPY"))
        let mapGroups = try String(contentsOf: root.appendingPathComponent("data/maps/map_groups.json"), encoding: .utf8)
        XCTAssertTrue(mapGroups.contains("\"OldaleTown\", \"CodexTest\""))
    }

    func testExternalChangeDiagnosticsReportHashMismatch() throws {
        let root = try makeTemporaryProjectRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let path = "data/maps/OldaleTown/map.json"
        let url = root.appendingPathComponent(path)
        try write("{\"id\":\"MAP_OLDALE_TOWN\"}", to: url)
        let snapshots = MapWorkflowPlanner.captureSourceSnapshots(rootPath: root.path, paths: [path])
        try write("{\"id\":\"MAP_CHANGED\"}  ", to: url)

        let diagnostics = MapWorkflowPlanner.externalChangeDiagnostics(rootPath: root.path, snapshots: snapshots)
        XCTAssertTrue(diagnostics.contains { $0.code == "MAP_WORKFLOW_SOURCE_HASH_MISMATCH" })
    }

    func testRegionPreviewFallsBackWithoutRegionSection() {
        let descriptor = MapDescriptor(
            id: "MAP_TEST_ROOM",
            name: "TestRoom",
            sourcePath: "data/maps/TestRoom/map.json",
            groupID: nil,
            groupIndex: nil,
            mapIndexInGroup: nil,
            layout: nil,
            layoutSlotIndex: nil,
            music: nil,
            mapType: nil,
            weather: nil,
            regionMapSection: "MAPSEC_NONE",
            floorNumber: 2,
            sharedEventsMap: nil,
            sharedScriptsMap: nil
        )

        let metadata = MapWorkflowPlanner.regionPreviewMetadata(for: descriptor)
        XCTAssertTrue(metadata.usesFallback)
        XCTAssertEqual(metadata.displayName, "TestRoom")
        XCTAssertEqual(metadata.floorNumber, 2)
        XCTAssertEqual(metadata.diagnostics.first?.code, "MAP_REGION_PREVIEW_FALLBACK")
    }

    func testPrefabPastePlansThroughMapMutationGate() throws {
        let root = try makeTemporaryProjectRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        try write(Data([0, 0, 1, 0, 2, 0, 3, 0]), to: root.appendingPathComponent("data/layouts/Test/map.bin"))
        let document = makeMapVisualDocument(root: root)
        let prefab = MapBlockPrefab(name: "Corner", width: 2, height: 1, rawValues: [0x10, 0x11])

        let plan = MapWorkflowPlanner.planPrefabPaste(document: document, prefab: prefab, x: 0, y: 1)
        XCTAssertTrue(plan.executionState.canApply)
        XCTAssertEqual(plan.operation?.action, .pasteBlockPattern)
        XCTAssertEqual(plan.mapEditPlan?.changes.first?.path, "data/layouts/Test/map.bin")

        let blocked = MapWorkflowPlanner.planPrefabPaste(document: document, prefab: prefab, x: 1, y: 1)
        XCTAssertFalse(blocked.executionState.canApply)
        XCTAssertTrue(blocked.diagnostics.contains { $0.code == "MAP_PREFAB_PASTE_OUT_OF_BOUNDS" })
    }

    func testEventCapacityWarningsDoNotBlockMapMutationPlanApplyability() throws {
        let root = try makeTemporaryProjectRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        try write(Data([0, 0, 1, 0, 2, 0, 3, 0]), to: root.appendingPathComponent("data/layouts/Test/map.bin"))
        try write("{}", to: root.appendingPathComponent("data/maps/TestRoom/map.json"))
        let capacity = MapEventCapacitySummary(
            counts: MapEventCounts(),
            limits: MapEventCapacityLimits(
                objectEvents: 1,
                sources: [
                    MapEventCapacityLimits.Source(
                        kind: .object,
                        path: "include/constants/global.h",
                        symbol: "OBJECT_EVENT_TEMPLATES_COUNT",
                        detail: "Object map template capacity."
                    )
                ]
            ),
            mapSourcePath: "data/maps/TestRoom/map.json"
        )
        let document = makeMapVisualDocument(root: root, eventCapacity: capacity, mapJSONText: "{}")
        let operations = [
            MapEditOperation(
                action: .addEvent,
                x: 0,
                y: 0,
                eventKind: .object,
                templateProperties: MapEventTemplateKind.object.templateProperties(x: 0, y: 0)
            ),
            MapEditOperation(
                action: .addEvent,
                x: 1,
                y: 1,
                eventKind: .object,
                templateProperties: MapEventTemplateKind.object.templateProperties(x: 1, y: 1)
            )
        ]

        let plan = MapMutationPlanner.plan(document: document, operations: operations)
        let diagnostic = try XCTUnwrap(plan.diagnostics.first { $0.code == "MAP_EVENT_CAPACITY_OVER_LIMIT" })

        XCTAssertEqual(diagnostic.severity, .warning)
        XCTAssertEqual(diagnostic.span?.relativePath, "data/maps/TestRoom/map.json")
        XCTAssertTrue(plan.changes.contains { $0.path == "data/maps/TestRoom/map.json" })
        XCTAssertTrue(plan.isApplyable, "\(plan.applyability.diagnostics.map(\.code))")
    }

    func testDuplicationApplyBlocksStaleSnapshots() throws {
        let root = try makeTemporaryProjectRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        try write(#"{"id":"MAP_OLDALE_TOWN","name":"OldaleTown","layout":"LAYOUT_OLDALE_TOWN"}"#, to: root.appendingPathComponent("data/maps/OldaleTown/map.json"))
        try write("[\"OldaleTown\"]", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write(#"{"layouts":[{"id":"LAYOUT_OLDALE_TOWN","name":"OldaleTown"}]}"#, to: root.appendingPathComponent("data/layouts/layouts.json"))

        let catalog = ProjectMapCatalog(
            id: "emerald",
            rootPath: root.path,
            profile: .pokeemerald,
            mapGroups: [],
            maps: [
                MapDescriptor(
                    id: "MAP_OLDALE_TOWN",
                    name: "OldaleTown",
                    sourcePath: "data/maps/OldaleTown/map.json",
                    groupID: nil,
                    groupIndex: nil,
                    mapIndexInGroup: nil,
                    layout: "LAYOUT_OLDALE_TOWN",
                    layoutSlotIndex: 0,
                    music: nil,
                    mapType: nil,
                    weather: nil,
                    regionMapSection: nil,
                    floorNumber: nil,
                    sharedEventsMap: nil,
                    sharedScriptsMap: nil
                )
            ],
            layoutSlots: [
                LayoutSlot(
                    slotIndex: 0,
                    layoutID: "LAYOUT_OLDALE_TOWN",
                    name: "OldaleTown",
                    width: 2,
                    height: 2,
                    borderWidth: nil,
                    borderHeight: nil,
                    primaryTileset: nil,
                    secondaryTileset: nil,
                    borderFilepath: nil,
                    blockdataFilepath: nil,
                    sourcePath: "data/layouts/layouts.json"
                )
            ]
        )
        let plan = MapWorkflowPlanner.planDuplication(
            catalog: catalog,
            sourceMapID: "MAP_OLDALE_TOWN",
            proposedMapID: "MAP_CODEX_TEST",
            proposedMapName: "CodexTest"
        )
        try write("[\"OldaleTown\", \"Changed\"]", to: root.appendingPathComponent("data/maps/map_groups.json"))

        let result = try MapWorkflowApplier.applyDuplication(plan: plan)

        XCTAssertTrue(result.appliedFiles.isEmpty)
        XCTAssertTrue(result.diagnostics.contains { $0.code == "MAP_WORKFLOW_SOURCE_HASH_MISMATCH" || $0.code == "MAP_WORKFLOW_SOURCE_SIZE_MISMATCH" })
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("data/maps/CodexTest/map.json").path))
    }

    func testVisualExportPlansAndWritesIgnoredArtifact() throws {
        let root = try makeTemporaryProjectRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let document = makeMapVisualDocument(root: root)
        let plan = MapWorkflowPlanner.planVisualExport(document: document, format: .json, fileStem: "test-room")

        XCTAssertTrue(plan.executionState.canExport)
        XCTAssertEqual(plan.artifacts.first?.relativePath, ".pokemonhackstudio/exports/maps/test-room.json")
        XCTAssertEqual(plan.artifacts.first?.role, .artifact)
        XCTAssertTrue(plan.artifacts.first?.isIgnoredWorkspaceArtifact == true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: plan.artifacts[0].absolutePath))

        let result = try MapVisualExportWriter.export(plan: plan)
        XCTAssertEqual(result.relativePath, ".pokemonhackstudio/exports/maps/test-room.json")
        XCTAssertGreaterThan(result.byteCount, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: plan.artifacts[0].absolutePath))
    }

    private func makeMapVisualDocument(
        root: URL,
        eventCapacity: MapEventCapacitySummary? = nil,
        mapJSONText: String = "{}"
    ) -> MapVisualDocument {
        let layout = LayoutSlot(
            slotIndex: 0,
            layoutID: "LAYOUT_TEST",
            name: "Test",
            width: 2,
            height: 2,
            borderWidth: nil,
            borderHeight: nil,
            primaryTileset: nil,
            secondaryTileset: nil,
            borderFilepath: nil,
            blockdataFilepath: "data/layouts/Test/map.bin",
            sourcePath: "data/layouts/layouts.json"
        )
        return MapVisualDocument(
            id: "MAP_TEST_ROOM",
            rootPath: root.path,
            profile: .pokeemerald,
            mapID: "MAP_TEST_ROOM",
            mapName: "TestRoom",
            mapSourcePath: "data/maps/TestRoom/map.json",
            layout: layout,
            blockdata: EditableLayoutBlockdata(
                filepath: "data/layouts/Test/map.bin",
                width: 2,
                height: 2,
                rawValues: [0, 1, 2, 3]
            ),
            border: nil,
            primaryTileset: nil,
            secondaryTileset: nil,
            metatiles: [],
            events: [],
            eventCapacity: eventCapacity,
            mapJSONText: mapJSONText
        )
    }

    private func makeTemporaryProjectRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("pokemonhack-map-workflow-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func write(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }

    private func write(_ text: String, to url: URL) throws {
        try write(Data(text.utf8), to: url)
    }
}
