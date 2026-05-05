import PokemonHackCore
import XCTest
@testable import PokemonHackStudio

final class MapEditorStoreTests: XCTestCase {
    private var temporaryDirectories: [MapEditorStoreTemporaryDirectory] = []

    override func tearDown() {
        temporaryDirectories.removeAll()
        super.tearDown()
    }

    @MainActor
    func testBrushSelectionUndoAndRedoStacks() throws {
        let store = try makeLoadedStore()

        store.selectMapCell(x: 0, y: 0)
        store.selectBrush(rawValue: 0x0022)
        store.paintMapCell(x: 1, y: 0)

        XCTAssertEqual(store.selectedMapTool, .pencil)
        XCTAssertEqual(store.stagedMapBlockdataValues[1], 0x0022)
        XCTAssertEqual(store.mapEditorSession.stagedMapBlockdataValues[1], 0x0022)
        XCTAssertEqual(store.mapEditOperations, store.mapEditorSession.mapEditOperations)
        XCTAssertEqual(store.mapEditOperations.count, 1)
        XCTAssertTrue(store.undoneMapEditOperations.isEmpty)

        store.undoLastMapEdit()
        XCTAssertEqual(store.stagedMapBlockdataValues[1], 0x0002)
        XCTAssertEqual(store.stagedMapBlockdataValues, store.mapEditorSession.stagedMapBlockdataValues)
        XCTAssertTrue(store.mapEditOperations.isEmpty)
        XCTAssertEqual(store.undoneMapEditOperations.count, 1)

        store.redoMapEdit()
        XCTAssertEqual(store.stagedMapBlockdataValues[1], 0x0022)
        XCTAssertEqual(store.mapEditOperations, store.mapEditorSession.mapEditOperations)
        XCTAssertEqual(store.mapEditOperations.count, 1)
        XCTAssertTrue(store.undoneMapEditOperations.isEmpty)
    }

    @MainActor
    func testSelectionPersistenceAndMapSwitchClearsDirtyState() throws {
        let store = try makeLoadedStore()

        store.selectMapCell(x: 1, y: 1)
        XCTAssertEqual(store.selectedMapCell?.metatileID, 4)

        store.selectBrush(rawValue: 0x0033)
        store.paintMapCell(x: 1, y: 1)
        XCTAssertEqual(store.mapEditOperations.count, 1)

        store.selectedMapID = "MAP_ROUTE2"
        store.loadSelectedMapVisualDocument()

        XCTAssertEqual(store.selectedMapVisualDocument?.mapID, "MAP_ROUTE2")
        XCTAssertEqual(store.mapEditOperations.count, 0)
        XCTAssertNil(store.selectedMapCell)
        XCTAssertNil(store.latestMapEditPlan)
        XCTAssertEqual(store.stagedMapBlockdataValues, [5, 6, 7, 8])
    }

    @MainActor
    func testMutationPreviewAndApplyGatingState() throws {
        let store = try makeLoadedStore()

        XCTAssertNil(store.latestMapEditPlan)
        store.previewSelectedMapMutationPlan()
        XCTAssertNil(store.latestMapEditPlan)

        store.selectBrush(rawValue: 0x0044)
        store.paintMapCell(x: 0, y: 0)
        XCTAssertNil(store.latestMapEditPlan)

        store.previewSelectedMapMutationPlan()

        let plan = try XCTUnwrap(store.latestMapEditPlan)
        XCTAssertEqual(plan.changes.map(\.path), ["data/layouts/Route1/map.bin"])
        XCTAssertTrue(plan.mutationPlan.requiresExplicitApply)
        XCTAssertTrue(plan.changes.allSatisfy { !$0.path.hasSuffix(".inc") })
    }

    @MainActor
    func testEventPropertyEditsStageJSONMutation() throws {
        let store = try makeLoadedStore()

        store.selectMapEvent(id: "object-0")
        store.updateSelectedMapEventProperty(key: "script", value: "Route1_EventScript_New")
        store.previewSelectedMapMutationPlan()

        XCTAssertEqual(store.stagedMapEvents.first?.properties.first { $0.key == "script" }?.value, "Route1_EventScript_New")
        XCTAssertEqual(store.stagedMapEvents, store.mapEditorSession.stagedMapEvents)
        let jsonPreview = try XCTUnwrap(store.latestMapEditPlan?.changes.first { $0.path == "data/maps/Route1/map.json" }?.textPreview)
        XCTAssertTrue(jsonPreview.contains(#""script": "Route1_EventScript_New""#))
    }

    @MainActor
    func testStoreMapEditingFacadeUsesSessionAsSingleOwner() throws {
        let store = try makeLoadedStore()

        store.selectBrush(rawValue: 0x0088)
        store.paintMapCell(x: 0, y: 0)
        store.selectMapEvent(id: "object-0")
        store.updateSelectedMapEventProperty(key: "elevation", value: "4")

        XCTAssertTrue(store.mapEditorSession.isDirty)
        XCTAssertEqual(store.selectedBrushRawValue, store.mapEditorSession.selectedBrushRawValue)
        XCTAssertEqual(store.selectedMapCell, store.mapEditorSession.selectedMapCell)
        XCTAssertEqual(store.selectedMapEventID, store.mapEditorSession.selectedMapEventID)
        XCTAssertEqual(store.stagedMapBlockdataValues, store.mapEditorSession.stagedMapBlockdataValues)
        XCTAssertEqual(store.stagedMapEvents, store.mapEditorSession.stagedMapEvents)
        XCTAssertEqual(store.mapEditOperations, store.mapEditorSession.mapEditOperations)

        store.discardMapEdits()

        XCTAssertFalse(store.mapEditorSession.isDirty)
        XCTAssertEqual(store.stagedMapBlockdataValues, [1, 2, 3, 4])
        XCTAssertEqual(store.stagedMapEvents, store.mapEditorSession.stagedMapEvents)
        XCTAssertTrue(store.mapEditOperations.isEmpty)
    }

    @MainActor
    private func makeLoadedStore() throws -> WorkbenchStore {
        let root = try makeVisualProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)
        store.openProject(path: root.path)
        store.selectedMapID = "MAP_ROUTE1"
        store.loadSelectedMapVisualDocument()
        XCTAssertEqual(store.selectedMapVisualDocument?.mapID, "MAP_ROUTE1")
        return store
    }

    private func makeVisualProject() throws -> URL {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url

        try write("POKEMON EMER\n", to: root.appendingPathComponent("Makefile"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/pokenav"), withIntermediateDirectories: true)

        try write(
            """
            {
              "group_order": ["gMapGroup_Routes"],
              "gMapGroup_Routes": ["Route1", "Route2"]
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
                  "width": 2,
                  "height": 2,
                  "border_width": 2,
                  "border_height": 2,
                  "primary_tileset": "gTileset_General",
                  "secondary_tileset": "gTileset_Route",
                  "border_filepath": "data/layouts/Route1/border.bin",
                  "blockdata_filepath": "data/layouts/Route1/map.bin"
                },
                {
                  "id": "LAYOUT_ROUTE2",
                  "name": "Route2_Layout",
                  "width": 2,
                  "height": 2,
                  "border_width": 2,
                  "border_height": 2,
                  "primary_tileset": "gTileset_General",
                  "secondary_tileset": "gTileset_Route",
                  "border_filepath": "data/layouts/Route2/border.bin",
                  "blockdata_filepath": "data/layouts/Route2/map.bin"
                }
              ]
            }
            """,
            to: root.appendingPathComponent("data/layouts/layouts.json")
        )
        try writeMapJSON(name: "Route1", mapID: "MAP_ROUTE1", layoutID: "LAYOUT_ROUTE1", to: root.appendingPathComponent("data/maps/Route1/map.json"))
        try writeMapJSON(name: "Route2", mapID: "MAP_ROUTE2", layoutID: "LAYOUT_ROUTE2", to: root.appendingPathComponent("data/maps/Route2/map.json"))

        try write(
            """
            const struct Tileset gTileset_General =
            {
                .isCompressed = TRUE,
                .isSecondary = FALSE,
                .tiles = gTilesetTiles_General,
                .palettes = gTilesetPalettes_General,
                .metatiles = gMetatiles_General,
                .metatileAttributes = gMetatileAttributes_General,
                .callback = NULL,
            };

            const struct Tileset gTileset_Route =
            {
                .isCompressed = TRUE,
                .isSecondary = TRUE,
                .tiles = gTilesetTiles_Route,
                .palettes = gTilesetPalettes_Route,
                .metatiles = gMetatiles_Route,
                .metatileAttributes = gMetatileAttributes_Route,
                .callback = NULL,
            };
            """,
            to: root.appendingPathComponent("src/data/tilesets/headers.h")
        )
        try write(
            """
            const u32 gTilesetTiles_General[] = INCGFX_U32("data/tilesets/primary/general/tiles.png", ".4bpp.lz", "-num_tiles 1");
            const u16 gTilesetPalettes_General[][16] =
            {
                INCGFX_U16("data/tilesets/primary/general/palettes/00.pal", ".gbapal"),
            };
            const u32 gTilesetTiles_Route[] = INCBIN_U32("data/tilesets/secondary/route/tiles.4bpp.lz");
            const u16 gTilesetPalettes_Route[][16] =
            {
                INCBIN_U16("data/tilesets/secondary/route/palettes/00.gbapal"),
            };
            """,
            to: root.appendingPathComponent("src/data/tilesets/graphics.h")
        )
        try write(
            """
            const u16 gMetatiles_General[] = INCBIN_U16("data/tilesets/primary/general/metatiles.bin");
            const u16 gMetatileAttributes_General[] = INCBIN_U16("data/tilesets/primary/general/metatile_attributes.bin");
            const u16 gMetatiles_Route[] = INCBIN_U16("data/tilesets/secondary/route/metatiles.bin");
            const u16 gMetatileAttributes_Route[] = INCBIN_U16("data/tilesets/secondary/route/metatile_attributes.bin");
            """,
            to: root.appendingPathComponent("src/data/tilesets/metatiles.h")
        )

        try writeWords([1, 2, 3, 4], to: root.appendingPathComponent("data/layouts/Route1/map.bin"))
        try writeWords([5, 6, 7, 8], to: root.appendingPathComponent("data/layouts/Route2/map.bin"))
        try writeWords([9, 10, 11, 12], to: root.appendingPathComponent("data/layouts/Route1/border.bin"))
        try writeWords([13, 14, 15, 16], to: root.appendingPathComponent("data/layouts/Route2/border.bin"))
        try writeWords([1, 2, 3, 4, 5, 6, 7, 8], to: root.appendingPathComponent("data/tilesets/primary/general/metatiles.bin"))
        try writeWords([1], to: root.appendingPathComponent("data/tilesets/primary/general/metatile_attributes.bin"))
        try writeWords([1, 2, 3, 4, 5, 6, 7, 8], to: root.appendingPathComponent("data/tilesets/secondary/route/metatiles.bin"))
        try writeWords([1], to: root.appendingPathComponent("data/tilesets/secondary/route/metatile_attributes.bin"))
        try write(Data(), to: root.appendingPathComponent("data/tilesets/primary/general/tiles.png"))
        try write(Data(), to: root.appendingPathComponent("data/tilesets/secondary/route/tiles.png"))
        try write(Data(), to: root.appendingPathComponent("data/tilesets/primary/general/palettes/00.pal"))
        try write(Data(), to: root.appendingPathComponent("data/tilesets/secondary/route/palettes/00.gbapal"))

        return root
    }

    private func writeMapJSON(name: String, mapID: String, layoutID: String, to url: URL) throws {
        try write(
            """
            {
              "id": "\(mapID)",
              "name": "\(name)",
              "layout": "\(layoutID)",
              "music": "MUS_ROUTE",
              "region_map_section": "MAPSEC_ROUTE",
              "weather": "WEATHER_SUNNY",
              "map_type": "MAP_TYPE_ROUTE",
              "connections": [],
              "object_events": [
                {
                  "local_id": "LOCALID_ROUTE_NPC",
                  "type": "object",
                  "graphics_id": "OBJ_EVENT_GFX_BOY_1",
                  "x": 1,
                  "y": 1,
                  "elevation": 3,
                  "script": "\(name)_EventScript_NPC"
                }
              ],
              "warp_events": [],
              "coord_events": [],
              "bg_events": []
            }
            """,
            to: url
        )
    }

    private func writeWords(_ words: [UInt16], to url: URL) throws {
        var data = Data()
        for word in words {
            data.append(UInt8(word & 0x00ff))
            data.append(UInt8((word >> 8) & 0x00ff))
        }
        try write(data, to: url)
    }

    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func write(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }
}

private final class MapEditorStoreTemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackMapEditorStoreTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
