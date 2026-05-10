import XCTest
@testable import PokemonHackCore

final class MapWorkflowPlanTests: XCTestCase {
    func testDuplicationPlanCapturesSourceSnapshotsAndBlocksApply() throws {
        let root = try makeTemporaryProjectRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        try write("{}", to: root.appendingPathComponent("data/maps/OldaleTown/map.json"))
        try write("[\"OldaleTown\"]", to: root.appendingPathComponent("data/maps/map_groups.json"))
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

        XCTAssertFalse(plan.executionState.canApply)
        XCTAssertTrue(plan.mutationPlan.requiresExplicitApply)
        XCTAssertTrue(plan.plannedFiles.contains { $0.destinationPath == "data/maps/CodexTest/map.json" })
        XCTAssertTrue(plan.plannedFiles.contains { $0.destinationPath == "data/layouts/OldaleTown_Copy/map.bin" })
        XCTAssertTrue(plan.sourceSnapshots.contains { $0.relativePath == "data/maps/OldaleTown/map.json" && $0.exists })
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

    func testVisualExportPlansIgnoredArtifactWithoutWriting() throws {
        let root = try makeTemporaryProjectRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let document = makeMapVisualDocument(root: root)
        let plan = MapWorkflowPlanner.planVisualExport(document: document, format: .png, fileStem: "test-room")

        XCTAssertFalse(plan.executionState.canExport)
        XCTAssertEqual(plan.artifacts.first?.relativePath, ".pokemonhackstudio/exports/maps/test-room.png")
        XCTAssertEqual(plan.artifacts.first?.role, .artifact)
        XCTAssertTrue(plan.artifacts.first?.isIgnoredWorkspaceArtifact == true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: plan.artifacts[0].absolutePath))
    }

    private func makeMapVisualDocument(root: URL) -> MapVisualDocument {
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
            mapJSONText: "{}"
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
