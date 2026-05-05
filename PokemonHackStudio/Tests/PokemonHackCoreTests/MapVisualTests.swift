import XCTest
@testable import PokemonHackCore

final class MapVisualTests: XCTestCase {
    private var temporaryDirectories: [MapVisualTemporaryDirectory] = []

    override func tearDown() {
        temporaryDirectories.removeAll()
        super.tearDown()
    }

    func testVisualLoaderResolvesTilesetsAndFullBlockdata() throws {
        let root = try makeVisualProject()
        try addObjectEventSpriteFixtures(to: root)
        let index = projectIndex(root: root)

        let document = try ProjectMapVisualLoader.load(from: index, mapID: "MAP_ROUTE1")

        XCTAssertEqual(document.mapName, "Route1")
        XCTAssertEqual(document.blockdata.rawValues, [0x0001, 0x0402, 0x0803, 0xf204])
        XCTAssertEqual(document.blockdata.metatileIDs, [1, 2, 3, 0x204])
        XCTAssertEqual(document.border?.rawValues, [7, 8, 9, 10])
        XCTAssertEqual(document.primaryTileset?.tileImagePath, "data/tilesets/primary/general/tiles.png")
        XCTAssertEqual(document.secondaryTileset?.palettePaths.first, "data/tilesets/secondary/route/palettes/00.gbapal")
        XCTAssertTrue(document.metatiles.contains { $0.id == 0x200 && $0.tilesetSymbol == "gTileset_Route" })

        let flippedEntry = try XCTUnwrap(document.metatiles.first(where: { $0.id == 0 })?.tileEntries[1])
        XCTAssertEqual(flippedEntry.tileIndex, 2)
        XCTAssertTrue(flippedEntry.hFlip)
        XCTAssertFalse(flippedEntry.vFlip)

        let paletteEntry = try XCTUnwrap(document.metatiles.first(where: { $0.id == 0x200 })?.tileEntries[3])
        XCTAssertEqual(paletteEntry.palette, 15)
        XCTAssertTrue(paletteEntry.vFlip)
        XCTAssertEqual(document.metatiles.first(where: { $0.id == 0x200 })?.attribute?.rawValue, 0x12345678)

        let sprite = try XCTUnwrap(document.events.first { $0.kind == .object }?.sprite)
        XCTAssertEqual(sprite.graphicsID, "OBJ_EVENT_GFX_BOY_1")
        XCTAssertEqual(sprite.graphicsConstantValue, 7)
        XCTAssertEqual(sprite.graphicsInfoSymbol, "gObjectEventGraphicsInfo_Boy1")
        XCTAssertEqual(sprite.imageAssetPath, "graphics/object_events/pics/people/boy_1.png")
        XCTAssertEqual(sprite.frameWidth, 16)
        XCTAssertEqual(sprite.frameHeight, 32)
        XCTAssertEqual(sprite.paletteTag, "OBJ_EVENT_PAL_TAG_NPC_1")
    }

    func testVisualLoaderUsesFieldmapMetatileLimitsForSecondaryBase() throws {
        let root = try makeVisualProject()
        try writeFieldmap(primaryMetatiles: 640, totalMetatiles: 1024, to: root)
        try writeWords([0x0000, 0x0280, 0x0281, 0x0282], to: root.appendingPathComponent("data/layouts/Route1/map.bin"))
        try writeWords([0x0000, 0x0000, 0x0000, 0x0000], to: root.appendingPathComponent("data/layouts/Route1/border.bin"))
        try writeWords(
            [
                0x0001, 0x0002, 0x0003, 0xf804, 0x0005, 0x0006, 0x0007, 0x0008,
                0x0009, 0x000a, 0x000b, 0x000c, 0x000d, 0x000e, 0x000f, 0x0010,
                0x0011, 0x0012, 0x0013, 0x0014, 0x0015, 0x0016, 0x0017, 0x0018
            ],
            to: root.appendingPathComponent("data/tilesets/secondary/route/metatiles.bin")
        )
        try writeDWords(
            [0x12345678, 0x12345679, 0x1234567a],
            to: root.appendingPathComponent("data/tilesets/secondary/route/metatile_attributes.bin")
        )

        let document = try ProjectMapVisualLoader.load(from: projectIndex(root: root), mapID: "MAP_ROUTE1")

        XCTAssertEqual(document.metatileLimits.primary, 640)
        XCTAssertEqual(document.metatileLimits.total, 1024)
        XCTAssertEqual(document.blockdata.metatileIDs, [0, 0x280, 0x281, 0x282])
        XCTAssertTrue(document.metatiles.contains { $0.id == 0x280 && $0.localID == 0 && $0.tilesetSymbol == "gTileset_Route" })
        XCTAssertTrue(document.metatiles.contains { $0.id == 0x282 && $0.localID == 2 && $0.tilesetSymbol == "gTileset_Route" })
        XCTAssertEqual(document.metatiles.filter { $0.id == 0x280 }.count, 1)
        XCTAssertFalse(document.diagnostics.contains { $0.code == "MAP_VISUAL_METATILE_DEFINITION_MISSING" })
    }

    func testVisualLoaderReportsUsedMetatilesMissingDefinitions() throws {
        let root = try makeVisualProject()

        let document = try ProjectMapVisualLoader.load(from: projectIndex(root: root), mapID: "MAP_ROUTE1")

        let diagnostic = try XCTUnwrap(document.diagnostics.first {
            $0.code == "MAP_VISUAL_METATILE_DEFINITION_MISSING" && $0.message.contains("data/layouts/Route1/map.bin")
        })
        XCTAssertEqual(diagnostic.severity, .warning)
        XCTAssertTrue(diagnostic.message.contains("data/layouts/Route1/map.bin"))
        XCTAssertTrue(diagnostic.message.contains("0x204"))
    }

    func testVisualSceneBuildsBorderViewportAndDirectionalConnections() throws {
        let root = try makeVisualProject()
        try addSceneConnectionFixtures(to: root)

        let document = try ProjectMapVisualLoader.load(from: projectIndex(root: root), mapID: "MAP_ROUTE1")

        XCTAssertEqual(document.scene.viewport.minX, -MapVisualScene.gameViewportTileWidth)
        XCTAssertEqual(document.scene.viewport.minY, -MapVisualScene.gameViewportTileHeight)
        XCTAssertEqual(document.scene.viewport.width, document.blockdata.width + MapVisualScene.gameViewportTileWidth * 2)
        XCTAssertEqual(document.scene.viewport.height, document.blockdata.height + MapVisualScene.gameViewportTileHeight * 2)
        XCTAssertEqual(document.scene.layoutPlacement?.originX, 0)
        XCTAssertEqual(document.scene.layoutPlacement?.originY, 0)

        let resolvedConnections = document.scene.connections.filter(\.isResolved)
        XCTAssertEqual(resolvedConnections.count, 4)
        XCTAssertEqual(document.scene.connections.count, 5)
        XCTAssertTrue(document.scene.diagnostics.contains { $0.code == "MAP_SCENE_CONNECTION_MAP_MISSING" })

        let north = try XCTUnwrap(document.scene.placements.first { $0.mapID == "MAP_ROUTE_NORTH" })
        XCTAssertEqual(north.originX, -1)
        XCTAssertEqual(north.originY, -1)
        XCTAssertEqual(north.rawValues, [0x0011, 0x0012])

        let south = try XCTUnwrap(document.scene.placements.first { $0.mapID == "MAP_ROUTE_SOUTH" })
        XCTAssertEqual(south.originX, 1)
        XCTAssertEqual(south.originY, 2)

        let west = try XCTUnwrap(document.scene.placements.first { $0.mapID == "MAP_ROUTE_WEST" })
        XCTAssertEqual(west.originX, -1)
        XCTAssertEqual(west.originY, 0)

        let east = try XCTUnwrap(document.scene.placements.first { $0.mapID == "MAP_ROUTE_EAST" })
        XCTAssertEqual(east.originX, 2)
        XCTAssertEqual(east.originY, -2)
        XCTAssertEqual(document.blockdata.rawValues, [0x0001, 0x0402, 0x0803, 0xf204])
    }

    func testMetatileLayerTypeDecoding() throws {
        XCTAssertEqual(MetatileAttribute(rawValue: 0x0000, wordSize: 2).layerType, .normal)
        XCTAssertEqual(MetatileAttribute(rawValue: 0x1000, wordSize: 2).layerType, .covered)
        XCTAssertEqual(MetatileAttribute(rawValue: 0x2000, wordSize: 2).layerType, .split)
        XCTAssertEqual(MetatileAttribute(rawValue: 0xf000, wordSize: 2).rawLayerType, 15)
        XCTAssertEqual(MetatileAttribute(rawValue: 0xf000, wordSize: 2).layerType, .normal)

        XCTAssertEqual(MetatileAttribute(rawValue: 0x00000000, wordSize: 4).layerType, .normal)
        XCTAssertEqual(MetatileAttribute(rawValue: 0x20000000, wordSize: 4).layerType, .covered)
        XCTAssertEqual(MetatileAttribute(rawValue: 0x40000000, wordSize: 4).layerType, .split)
        XCTAssertEqual(MetatileAttribute(rawValue: 0x60000000, wordSize: 4).rawLayerType, 3)
        XCTAssertEqual(MetatileAttribute(rawValue: 0x60000000, wordSize: 4).layerType, .normal)
    }

    func testMetatileLayerExpansionMatchesGameBackgroundPlanes() throws {
        let normal = makeMetatile(layerType: .normal)
        XCTAssertTrue(normal.layerCell(for: .bottom).isEmpty)
        XCTAssertEqual(tileIndices(in: normal.layerCell(for: .middle)), [0, 1, 2, 3])
        XCTAssertEqual(tileIndices(in: normal.layerCell(for: .top)), [4, 5, 6, 7])

        let covered = makeMetatile(layerType: .covered)
        XCTAssertEqual(tileIndices(in: covered.layerCell(for: .bottom)), [0, 1, 2, 3])
        XCTAssertEqual(tileIndices(in: covered.layerCell(for: .middle)), [4, 5, 6, 7])
        XCTAssertTrue(covered.layerCell(for: .top).isEmpty)

        let split = makeMetatile(layerType: .split)
        XCTAssertEqual(tileIndices(in: split.layerCell(for: .bottom)), [0, 1, 2, 3])
        XCTAssertTrue(split.layerCell(for: .middle).isEmpty)
        XCTAssertEqual(tileIndices(in: split.layerCell(for: .top)), [4, 5, 6, 7])

        let unknown = makeMetatile(attribute: MetatileAttribute(rawValue: 0xf000, wordSize: 2))
        XCTAssertEqual(unknown.attribute?.layerType, .normal)
        XCTAssertEqual(tileIndices(in: unknown.layerCell(for: .middle)), [0, 1, 2, 3])
        XCTAssertEqual(tileIndices(in: unknown.layerCell(for: .top)), [4, 5, 6, 7])
    }

    func testMapBlockAttributeDecoding() throws {
        let attributes = MapBlockAttributes(rawValue: 0xd7ff)
        XCTAssertEqual(attributes.metatileID, 0x3ff)
        XCTAssertEqual(attributes.collision, 1)
        XCTAssertEqual(attributes.elevation, 13)
    }

    func testPaletteParsingForJASCAndGBAPalettes() throws {
        let jasc = Data(
            """
            JASC-PAL
            0100
            3
            0 0 0
            255 128 64
            12 34 56
            """.utf8
        )
        XCTAssertEqual(
            TilePaletteParser.parse(data: jasc),
            [
                PaletteColor(red: 0, green: 0, blue: 0),
                PaletteColor(red: 255, green: 128, blue: 64),
                PaletteColor(red: 12, green: 34, blue: 56)
            ]
        )

        let gba = Data([0x1f, 0x00, 0xe0, 0x03, 0x00, 0x7c])
        XCTAssertEqual(
            TilePaletteParser.parse(data: gba),
            [
                PaletteColor(red: 255, green: 0, blue: 0),
                PaletteColor(red: 0, green: 255, blue: 0),
                PaletteColor(red: 0, green: 0, blue: 255)
            ]
        )
    }

    func testVisualLoaderReportsUnknownLayerTypesWithoutBlocking() throws {
        let root = try makeVisualProject(primaryAttribute: 0xf011, secondaryAttribute: 0x60000000)
        let document = try ProjectMapVisualLoader.load(from: projectIndex(root: root), mapID: "MAP_ROUTE1")

        XCTAssertEqual(document.metatiles.first(where: { $0.id == 0 })?.attribute?.rawLayerType, 15)
        XCTAssertEqual(document.metatiles.first(where: { $0.id == 0 })?.attribute?.layerType, .normal)
        XCTAssertEqual(document.metatiles.first(where: { $0.id == 0x200 })?.attribute?.rawLayerType, 3)
        XCTAssertEqual(document.metatiles.first(where: { $0.id == 0x200 })?.attribute?.layerType, .normal)
        XCTAssertEqual(document.diagnostics.filter { $0.code == "METATILE_LAYER_TYPE_UNKNOWN" }.count, 2)
    }

    func testMutationPlannerStagesBlockdataAndOrderedMapJSONChanges() throws {
        let root = try makeVisualProject()
        let document = try ProjectMapVisualLoader.load(from: projectIndex(root: root), mapID: "MAP_ROUTE1")

        let plan = MapMutationPlanner.plan(
            document: document,
            operations: [
                MapEditOperation(action: .paintMetatile, target: .layout, x: 1, y: 0, rawValue: 0x0234),
                MapEditOperation(action: .moveEvent, x: 4, y: 5, eventKind: .object, eventIndex: 0),
                MapEditOperation(action: .updateEventField, eventKind: .object, eventIndex: 0, fieldKey: "script", fieldValue: "Route1_EventScript_New")
            ]
        )

        XCTAssertEqual(plan.changes.map { $0.path }.sorted(), ["data/layouts/Route1/map.bin", "data/maps/Route1/map.json"])
        XCTAssertFalse(plan.changes.contains { $0.path.hasSuffix(".inc") })
        let blockChange = try XCTUnwrap(plan.changes.first { $0.path == "data/layouts/Route1/map.bin" })
        XCTAssertEqual([UInt8](blockChange.newData), [0x01, 0x00, 0x34, 0x02, 0x03, 0x08, 0x04, 0xf2])

        let json = try XCTUnwrap(plan.changes.first { $0.path == "data/maps/Route1/map.json" }?.textPreview)
        XCTAssertTrue(json.contains(#""custom_field": "preserved""#))
        XCTAssertTrue(json.contains(#""type": "object""#))
        XCTAssertTrue(json.contains(#""x": 4"#))
        XCTAssertTrue(json.contains(#""y": 5"#))
        XCTAssertTrue(json.contains(#""script": "Route1_EventScript_New""#))
    }

    func testScriptIndexResolvesMapLocalSharedMissingAndDuplicateLabels() throws {
        let root = try makeVisualProject()
        try write(
            """
            Route1_EventScript_NPC::
            \tmsgbox Route1_Text
            \tend

            DuplicateScript::
            \tend
            """,
            to: root.appendingPathComponent("data/maps/Route1/scripts.inc")
        )
        try write(
            """
            Shared_EventScript::
            \treturn

            DuplicateScript::
            \treturn
            """,
            to: root.appendingPathComponent("data/maps/SharedTown/scripts.inc")
        )

        let index = MapScriptIndexLoader.load(root: root, mapName: "Route1", sharedMapName: "SharedTown")
        let local = index.resolution(for: "Route1_EventScript_NPC")
        let shared = index.resolution(for: "Shared_EventScript")
        let missing = index.resolution(for: "Route1_EventScript_Missing")
        let duplicate = index.resolution(for: "DuplicateScript")

        XCTAssertEqual(local.state, .resolved)
        XCTAssertEqual(local.span?.sourceRole, .mapLocal)
        XCTAssertEqual(local.span?.body.trimmingCharacters(in: .whitespacesAndNewlines), "msgbox Route1_Text\n\tend")
        XCTAssertEqual(shared.state, .resolved)
        XCTAssertEqual(shared.span?.sourceRole, .shared)
        XCTAssertEqual(missing.state, .missingLabel)
        XCTAssertEqual(duplicate.state, .duplicateLabel)
        XCTAssertTrue(index.diagnostics.contains { $0.code == "MAP_SCRIPT_LABEL_DUPLICATE" })
    }

    func testMutationPlannerReplacesOnlyScriptBodyAndKeepsNeighborLabels() throws {
        let root = try makeVisualProject()
        try write(
            """
            Route1_EventScript_NPC::
            \tmsgbox Route1_Text
            \tend

            Route1_EventScript_Other::
            \treturn
            """,
            to: root.appendingPathComponent("data/maps/Route1/scripts.inc")
        )
        let document = try ProjectMapVisualLoader.load(from: projectIndex(root: root), mapID: "MAP_ROUTE1")

        let plan = MapMutationPlanner.plan(
            document: document,
            operations: [
                MapEditOperation(
                    action: .updateScriptBody,
                    scriptLabel: "Route1_EventScript_NPC",
                    scriptBody: "\tmsgbox Route1_Text_Updated\n\tend",
                    scriptSourcePath: "data/maps/Route1/scripts.inc"
                )
            ]
        )

        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty, "\(plan.diagnostics.map(\.code))")
        XCTAssertEqual(plan.changes.map(\.path), ["data/maps/Route1/scripts.inc"])
        let script = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(script.contains("Route1_EventScript_NPC::\n\tmsgbox Route1_Text_Updated\n\tend"))
        XCTAssertTrue(script.contains("Route1_EventScript_Other::\n\treturn"))
        XCTAssertFalse(script.contains("msgbox Route1_Text\n\tend"))
    }

    func testMutationPlannerStagesCombinedMapJSONAndScriptBodyChanges() throws {
        let root = try makeVisualProject()
        try write(
            """
            Route1_EventScript_NPC::
            \tmsgbox Route1_Text
            \tend
            """,
            to: root.appendingPathComponent("data/maps/Route1/scripts.inc")
        )
        let document = try ProjectMapVisualLoader.load(from: projectIndex(root: root), mapID: "MAP_ROUTE1")

        let plan = MapMutationPlanner.plan(
            document: document,
            operations: [
                MapEditOperation(action: .moveEvent, x: 4, y: 5, eventKind: .object, eventIndex: 0),
                MapEditOperation(
                    action: .updateScriptBody,
                    scriptLabel: "Route1_EventScript_NPC",
                    scriptBody: "\tmsgbox Route1_Text_Updated\n\tend",
                    scriptSourcePath: "data/maps/Route1/scripts.inc"
                )
            ]
        )

        XCTAssertEqual(plan.changes.map(\.path).sorted(), ["data/maps/Route1/map.json", "data/maps/Route1/scripts.inc"])
        XCTAssertTrue(plan.changes.first { $0.path == "data/maps/Route1/map.json" }?.textPreview?.contains(#""x": 4"#) ?? false)
        XCTAssertTrue(plan.changes.first { $0.path == "data/maps/Route1/scripts.inc" }?.textPreview?.contains("Route1_Text_Updated") ?? false)
        XCTAssertTrue(plan.isApplyable, "\(plan.diagnostics.map(\.code))")
    }

    func testMutationPlannerCreatesScriptLabelThenUpdatesEventScriptField() throws {
        let root = try makeVisualProject()
        try write("", to: root.appendingPathComponent("data/maps/Route1/scripts.inc"))
        let document = try ProjectMapVisualLoader.load(from: projectIndex(root: root), mapID: "MAP_ROUTE1")

        let plan = MapMutationPlanner.plan(
            document: document,
            operations: [
                MapEditOperation(
                    action: .createMapScriptLabel,
                    scriptLabel: "Route1_EventScript_New",
                    scriptBody: "\tend",
                    scriptSourcePath: "data/maps/Route1/scripts.inc"
                ),
                MapEditOperation(
                    action: .updateEventField,
                    eventKind: .object,
                    eventIndex: 0,
                    fieldKey: "script",
                    fieldValue: "Route1_EventScript_New"
                )
            ]
        )

        XCTAssertEqual(plan.changes.map(\.path).sorted(), ["data/maps/Route1/map.json", "data/maps/Route1/scripts.inc"])
        XCTAssertTrue(plan.changes.first { $0.path == "data/maps/Route1/scripts.inc" }?.textPreview?.contains("Route1_EventScript_New::\n\tend") ?? false)
        XCTAssertTrue(plan.changes.first { $0.path == "data/maps/Route1/map.json" }?.textPreview?.contains(#""script": "Route1_EventScript_New""#) ?? false)
        XCTAssertTrue(plan.isApplyable, "\(plan.diagnostics.map(\.code))")
    }

    func testMutationPlannerCanUpdateBodyForNewlyCreatedScriptLabel() throws {
        let root = try makeVisualProject()
        try write("", to: root.appendingPathComponent("data/maps/Route1/scripts.inc"))
        let document = try ProjectMapVisualLoader.load(from: projectIndex(root: root), mapID: "MAP_ROUTE1")

        let plan = MapMutationPlanner.plan(
            document: document,
            operations: [
                MapEditOperation(
                    action: .createMapScriptLabel,
                    scriptLabel: "Route1_EventScript_New",
                    scriptBody: "\tend",
                    scriptSourcePath: "data/maps/Route1/scripts.inc"
                ),
                MapEditOperation(
                    action: .updateScriptBody,
                    scriptLabel: "Route1_EventScript_New",
                    scriptBody: "\tmsgbox Route1_Text\n\tend",
                    scriptSourcePath: "data/maps/Route1/scripts.inc"
                )
            ]
        )

        let script = try XCTUnwrap(plan.changes.first { $0.path == "data/maps/Route1/scripts.inc" }?.textPreview)
        XCTAssertTrue(script.contains("Route1_EventScript_New::\n\tmsgbox Route1_Text\n\tend"))
        XCTAssertEqual(script.components(separatedBy: "Route1_EventScript_New::").count, 2)
        XCTAssertTrue(plan.isApplyable, "\(plan.diagnostics.map(\.code))")
    }

    func testMutationPlannerReportsBoundsDiagnostics() throws {
        let root = try makeVisualProject()
        let document = try ProjectMapVisualLoader.load(from: projectIndex(root: root), mapID: "MAP_ROUTE1")

        let plan = MapMutationPlanner.plan(
            document: document,
            operations: [
                MapEditOperation(action: .paintMetatile, target: .layout, x: 4, y: 0, rawValue: 1)
            ]
        )

        XCTAssertTrue(plan.diagnostics.contains { $0.code == "MAP_EDIT_OUT_OF_BOUNDS" }, "\(plan.diagnostics.map { $0.code })")
        XCTAssertTrue(plan.changes.isEmpty)
    }

    func testEditReducerMatchesPlannerForBlockdataAndJSON() throws {
        let root = try makeVisualProject()
        let document = try ProjectMapVisualLoader.load(from: projectIndex(root: root), mapID: "MAP_ROUTE1")
        let operations = [
            MapEditOperation(action: .paintMetatile, target: .layout, x: 1, y: 0, rawValue: 0x0234),
            MapEditOperation(action: .fillMetatile, target: .layout, x: 0, y: 1, width: 2, height: 1, rawValue: 0x0055),
            MapEditOperation(action: .moveEvent, x: 4, y: 5, eventKind: .object, eventIndex: 0)
        ]

        let draft = MapEditReducer.reduce(document: document, operations: operations)
        let plan = MapMutationPlanner.plan(document: document, operations: operations)

        XCTAssertEqual(draft.blockdata.rawValues, [0x0001, 0x0234, 0x0055, 0x0055])
        XCTAssertEqual(plan.diagnostics.map(\.code), draft.diagnostics.map(\.code))
        XCTAssertEqual(plan.changes.first { $0.path == document.blockdata.filepath }?.newData, encodedWords(draft.blockdata.rawValues))
        XCTAssertEqual(plan.changes.first { $0.path == document.mapSourcePath }?.textPreview, draft.mapJSONText)
        XCTAssertEqual(draft.events.first { $0.kind == .object && $0.index == 0 }?.x, 4)
        XCTAssertEqual(draft.events.first { $0.kind == .object && $0.index == 0 }?.y, 5)
    }

    func testDuplicateEventCarriesOperationAndTemplateJSONParity() throws {
        let root = try makeVisualProject()
        let document = try ProjectMapVisualLoader.load(from: projectIndex(root: root), mapID: "MAP_ROUTE1")
        let operation = MapEditOperation(
            action: .duplicateEvent,
            x: 7,
            y: 8,
            eventKind: .object,
            eventIndex: 0,
            fieldKey: "script",
            fieldValue: "Route1_EventScript_Copy",
            templateProperties: [
                MapEventProperty(key: "local_id", value: "LOCALID_ROUTE1_COPY"),
                MapEventProperty(key: "trainer_type", value: "TRAINER_TYPE_NONE")
            ]
        )

        let draft = MapEditReducer.reduce(document: document, operations: [operation])
        let plan = MapMutationPlanner.plan(document: document, operations: [operation])
        let duplicated = try XCTUnwrap(draft.events.first { $0.kind == .object && $0.index == 1 })
        let properties = Dictionary(uniqueKeysWithValues: duplicated.properties.map { ($0.key, $0.value) })
        let json = try XCTUnwrap(plan.changes.first { $0.path == document.mapSourcePath }?.textPreview)

        XCTAssertEqual(draft.events.filter { $0.kind == .object }.count, 2)
        XCTAssertEqual(duplicated.x, 7)
        XCTAssertEqual(duplicated.y, 8)
        XCTAssertEqual(properties["local_id"], "LOCALID_ROUTE1_COPY")
        XCTAssertEqual(properties["script"], "Route1_EventScript_Copy")
        XCTAssertEqual(properties["trainer_type"], "TRAINER_TYPE_NONE")
        XCTAssertEqual(properties["graphics_id"], "OBJ_EVENT_GFX_BOY_1")
        XCTAssertEqual(json, draft.mapJSONText)
        XCTAssertTrue(json.contains(#""local_id": "LOCALID_ROUTE1_COPY""#))
        XCTAssertTrue(json.contains(#""x": 7"#))
        XCTAssertTrue(json.contains(#""y": 8"#))
        XCTAssertTrue(json.contains(#""script": "Route1_EventScript_Copy""#))
    }

    func testApplyBlocksPlansWithDiagnosticsAndDoesNotWrite() throws {
        let root = try makeVisualProject()
        let mapPath = root.appendingPathComponent("data/layouts/Route1/map.bin")
        let original = try Data(contentsOf: mapPath)
        let document = try ProjectMapVisualLoader.load(from: projectIndex(root: root), mapID: "MAP_ROUTE1")
        let plan = MapMutationPlanner.plan(
            document: document,
            operations: [
                MapEditOperation(action: .paintMetatile, target: .layout, x: 0, y: 0, rawValue: 0x0009),
                MapEditOperation(action: .paintMetatile, target: .layout, x: 4, y: 0, rawValue: 0x000a)
            ]
        )

        let result = try MapMutationApplier.apply(plan: plan)

        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.changes.contains { $0.path == "data/layouts/Route1/map.bin" })
        XCTAssertTrue(result.appliedChanges.isEmpty)
        XCTAssertTrue(result.diagnostics.contains { $0.code == "MAP_EDIT_OUT_OF_BOUNDS" }, "\(result.diagnostics.map { $0.code })")
        XCTAssertEqual(try Data(contentsOf: mapPath), original)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(plan.backupRelativeRoot).path))
    }

    func testApplyabilityRejectsGeneratedArtifactEscapeAndOutsideRootPaths() throws {
        let root = try makeVisualProject()
        let outsideRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackMapVisualOutside")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: outsideRoot, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: outsideRoot)
        }
        let outsideFile = outsideRoot.appendingPathComponent("out.bin")
        try write("outside", to: outsideFile)
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("linked"), withDestinationURL: outsideRoot)
        let scriptPlan = manualPlan(
            root: root,
            changes: [fileChange(path: "data/maps/Route1/scripts.inc")]
        )
        let plan = manualPlan(
            root: root,
            changes: [
                fileChange(path: outsideRoot.appendingPathComponent("absolute.bin").path),
                fileChange(path: "../escape.bin"),
                fileChange(path: "data/maps/Route1/events.inc"),
                fileChange(path: "build/out.bin"),
                fileChange(path: "pokeemerald.gba"),
                fileChange(path: "linked/out.bin", originalByteCount: Data("outside".utf8).count)
            ]
        )

        XCTAssertTrue(scriptPlan.validateApplyability().isApplyable)
        let applyability = plan.validateApplyability()
        let result = try MapMutationApplier.apply(plan: plan)
        let codes = Set(applyability.diagnostics.map(\.code))

        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(codes.contains("MAP_APPLY_PATH_ABSOLUTE"), "\(codes)")
        XCTAssertTrue(codes.contains("MAP_APPLY_PATH_ESCAPE"), "\(codes)")
        XCTAssertTrue(codes.contains("MAP_APPLY_PATH_GENERATED"), "\(codes)")
        XCTAssertTrue(codes.contains("MAP_APPLY_PATH_ARTIFACT"), "\(codes)")
        XCTAssertTrue(codes.contains("MAP_APPLY_PATH_ROM_OR_ARTIFACT"), "\(codes)")
        XCTAssertTrue(codes.contains("MAP_APPLY_PATH_OUTSIDE_ROOT"), "\(codes)")
        XCTAssertTrue(result.appliedChanges.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(plan.backupRelativeRoot).path))
        XCTAssertEqual(try String(contentsOf: outsideFile, encoding: .utf8), "outside")
    }

    func testMutationApplierWritesOnlySourceFilesAndCreatesBackups() throws {
        let root = try makeVisualProject()
        let generatedPath = root.appendingPathComponent("data/maps/Route1/events.inc")
        try write("generated", to: generatedPath)
        let mapPath = root.appendingPathComponent("data/layouts/Route1/map.bin")
        let originalMapData = try Data(contentsOf: mapPath)
        let document = try ProjectMapVisualLoader.load(from: projectIndex(root: root), mapID: "MAP_ROUTE1")
        let plan = MapMutationPlanner.plan(
            document: document,
            operations: [
                MapEditOperation(action: .paintMetatile, target: .layout, x: 0, y: 0, rawValue: 0x0009),
                MapEditOperation(action: .deleteEvent, eventKind: .bg, eventIndex: 0)
            ]
        )

        let result = try MapMutationApplier.apply(plan: plan)

        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent("data/layouts/Route1/map.bin")).first, 0x09)
        XCTAssertEqual(try String(contentsOf: generatedPath, encoding: .utf8), "generated")
        XCTAssertTrue(result.appliedChanges.contains { $0.path == "data/layouts/Route1/map.bin" })
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.backupRootPath))
        let backupMapPath = URL(fileURLWithPath: result.backupRootPath).appendingPathComponent("data/layouts/Route1/map.bin")
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupMapPath.path))
        XCTAssertEqual(try Data(contentsOf: backupMapPath), originalMapData)
        XCTAssertNotEqual(try Data(contentsOf: mapPath), originalMapData)
    }

    private func makeMetatile(layerType: MetatileLayerType? = nil, attribute: MetatileAttribute? = nil) -> MetatileDefinition {
        let resolvedAttribute = attribute ?? layerType.map { MetatileAttribute(rawValue: UInt32($0.rawValue) << 12, wordSize: 2) }
        return MetatileDefinition(
            id: 0,
            localID: 0,
            tilesetSymbol: "gTileset_Test",
            tileEntries: (0..<8).map { MetatileTileEntry(index: $0, rawValue: UInt16($0)) },
            attribute: resolvedAttribute
        )
    }

    private func tileIndices(in cell: MetatileLayerCell) -> [Int] {
        cell.tileEntries.compactMap { $0?.tileIndex }
    }

    private func makeVisualProject(
        primaryAttribute: UInt16 = 0x0011,
        secondaryAttribute: UInt32 = 0x12345678
    ) throws -> URL {
        let temp = try MapVisualTemporaryDirectory()
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
                  "width": 2,
                  "height": 2,
                  "border_width": 2,
                  "border_height": 2,
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
              "custom_field": "preserved",
              "music": "MUS_ROUTE1",
              "region_map_section": "MAPSEC_ROUTE1",
              "weather": "WEATHER_SUNNY",
              "map_type": "MAP_TYPE_ROUTE",
              "connections": [],
              "object_events": [
                {
                  "local_id": "LOCALID_ROUTE1_NPC",
                  "type": "object",
                  "graphics_id": "OBJ_EVENT_GFX_BOY_1",
                  "x": 1,
                  "y": 1,
                  "elevation": 3,
                  "script": "Route1_EventScript_NPC"
                }
              ],
              "warp_events": [],
              "coord_events": [],
              "bg_events": [
                {
                  "type": "sign",
                  "x": 0,
                  "y": 0,
                  "elevation": 0,
                  "script": "Route1_EventScript_Sign"
                }
              ]
            }
            """,
            to: root.appendingPathComponent("data/maps/Route1/map.json")
        )

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
            const u32 gMetatileAttributes_Route[] = INCBIN_U32("data/tilesets/secondary/route/metatile_attributes.bin");
            """,
            to: root.appendingPathComponent("src/data/tilesets/metatiles.h")
        )

        try writeWords([0x0001, 0x0402, 0x0803, 0xf204], to: root.appendingPathComponent("data/layouts/Route1/map.bin"))
        try writeWords([7, 8, 9, 10], to: root.appendingPathComponent("data/layouts/Route1/border.bin"))
        try writeWords([0x0001, 0x0402, 0x0803, 0x1004, 0x0005, 0x0006, 0x0007, 0x0008], to: root.appendingPathComponent("data/tilesets/primary/general/metatiles.bin"))
        try writeWords([primaryAttribute], to: root.appendingPathComponent("data/tilesets/primary/general/metatile_attributes.bin"))
        try writeWords([0x0001, 0x0002, 0x0003, 0xf804, 0x0005, 0x0006, 0x0007, 0x0008], to: root.appendingPathComponent("data/tilesets/secondary/route/metatiles.bin"))
        try writeDWords([secondaryAttribute], to: root.appendingPathComponent("data/tilesets/secondary/route/metatile_attributes.bin"))
        try write(Data(), to: root.appendingPathComponent("data/tilesets/primary/general/tiles.png"))
        try write(Data(), to: root.appendingPathComponent("data/tilesets/secondary/route/tiles.png"))
        try write(Data(), to: root.appendingPathComponent("data/tilesets/primary/general/palettes/00.pal"))
        try write(Data(), to: root.appendingPathComponent("data/tilesets/secondary/route/palettes/00.gbapal"))

        return root
    }

    private func addSceneConnectionFixtures(to root: URL) throws {
        try write(
            """
            {
              "group_order": ["gMapGroup_Routes"],
              "gMapGroup_Routes": ["Route1", "RouteNorth", "RouteSouth", "RouteWest", "RouteEast"]
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
                  "id": "LAYOUT_ROUTE_NORTH",
                  "name": "RouteNorth_Layout",
                  "width": 2,
                  "height": 1,
                  "primary_tileset": "gTileset_General",
                  "secondary_tileset": "gTileset_Route",
                  "border_filepath": "data/layouts/RouteNorth/border.bin",
                  "blockdata_filepath": "data/layouts/RouteNorth/map.bin"
                },
                {
                  "id": "LAYOUT_ROUTE_SOUTH",
                  "name": "RouteSouth_Layout",
                  "width": 2,
                  "height": 1,
                  "primary_tileset": "gTileset_General",
                  "secondary_tileset": "gTileset_Route",
                  "border_filepath": "data/layouts/RouteSouth/border.bin",
                  "blockdata_filepath": "data/layouts/RouteSouth/map.bin"
                },
                {
                  "id": "LAYOUT_ROUTE_WEST",
                  "name": "RouteWest_Layout",
                  "width": 1,
                  "height": 2,
                  "primary_tileset": "gTileset_General",
                  "secondary_tileset": "gTileset_Route",
                  "border_filepath": "data/layouts/RouteWest/border.bin",
                  "blockdata_filepath": "data/layouts/RouteWest/map.bin"
                },
                {
                  "id": "LAYOUT_ROUTE_EAST",
                  "name": "RouteEast_Layout",
                  "width": 1,
                  "height": 2,
                  "primary_tileset": "gTileset_General",
                  "secondary_tileset": "gTileset_Route",
                  "border_filepath": "data/layouts/RouteEast/border.bin",
                  "blockdata_filepath": "data/layouts/RouteEast/map.bin"
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
              "music": "MUS_ROUTE1",
              "region_map_section": "MAPSEC_ROUTE1",
              "weather": "WEATHER_SUNNY",
              "map_type": "MAP_TYPE_ROUTE",
              "connections": [
                { "map": "MAP_ROUTE_NORTH", "offset": -1, "direction": "up" },
                { "map": "MAP_ROUTE_SOUTH", "offset": 1, "direction": "down" },
                { "map": "MAP_ROUTE_WEST", "offset": 0, "direction": "left" },
                { "map": "MAP_ROUTE_EAST", "offset": -2, "direction": "right" },
                { "map": "MAP_ROUTE_MISSING", "offset": 0, "direction": "right" }
              ],
              "object_events": [],
              "warp_events": [],
              "coord_events": [],
              "bg_events": []
            }
            """,
            to: root.appendingPathComponent("data/maps/Route1/map.json")
        )
        try writeConnectedMap("RouteNorth", mapID: "MAP_ROUTE_NORTH", layoutID: "LAYOUT_ROUTE_NORTH", root: root)
        try writeConnectedMap("RouteSouth", mapID: "MAP_ROUTE_SOUTH", layoutID: "LAYOUT_ROUTE_SOUTH", root: root)
        try writeConnectedMap("RouteWest", mapID: "MAP_ROUTE_WEST", layoutID: "LAYOUT_ROUTE_WEST", root: root)
        try writeConnectedMap("RouteEast", mapID: "MAP_ROUTE_EAST", layoutID: "LAYOUT_ROUTE_EAST", root: root)

        try writeWords([0x0011, 0x0012], to: root.appendingPathComponent("data/layouts/RouteNorth/map.bin"))
        try writeWords([0x0021, 0x0022], to: root.appendingPathComponent("data/layouts/RouteSouth/map.bin"))
        try writeWords([0x0031, 0x0032], to: root.appendingPathComponent("data/layouts/RouteWest/map.bin"))
        try writeWords([0x0041, 0x0042], to: root.appendingPathComponent("data/layouts/RouteEast/map.bin"))
    }

    private func writeConnectedMap(_ name: String, mapID: String, layoutID: String, root: URL) throws {
        try write(
            """
            {
              "id": "\(mapID)",
              "name": "\(name)",
              "layout": "\(layoutID)",
              "map_type": "MAP_TYPE_ROUTE",
              "connections": [],
              "object_events": [],
              "warp_events": [],
              "coord_events": [],
              "bg_events": []
            }
            """,
            to: root.appendingPathComponent("data/maps/\(name)/map.json")
        )
    }

    private func addObjectEventSpriteFixtures(to root: URL) throws {
        try write(
            """
            #define OBJ_EVENT_GFX_BOY_1 7
            """,
            to: root.appendingPathComponent("include/constants/event_objects.h")
        )
        try write(
            """
            const struct ObjectEventGraphicsInfo gObjectEventGraphicsInfo_Boy1;

            const struct ObjectEventGraphicsInfo *const gObjectEventGraphicsInfoPointers[NUM_OBJ_EVENT_GFX] = {
                [OBJ_EVENT_GFX_BOY_1] = &gObjectEventGraphicsInfo_Boy1,
            };
            """,
            to: root.appendingPathComponent("src/data/object_events/object_event_graphics_info_pointers.h")
        )
        try write(
            """
            const struct ObjectEventGraphicsInfo gObjectEventGraphicsInfo_Boy1 = {
                .tileTag = TAG_NONE,
                .paletteTag = OBJ_EVENT_PAL_TAG_NPC_1,
                .reflectionPaletteTag = OBJ_EVENT_PAL_TAG_NONE,
                .size = 512,
                .width = 16,
                .height = 32,
                .paletteSlot = PALSLOT_NPC_1,
                .shadowSize = SHADOW_SIZE_M,
                .inanimate = FALSE,
                .disableReflectionPaletteLoad = FALSE,
                .tracks = TRACKS_FOOT,
                .oam = &gObjectEventBaseOam_16x32,
                .subspriteTables = sOamTables_16x32,
                .anims = sAnimTable_Standard,
                .images = sPicTable_Boy1,
                .affineAnims = gDummySpriteAffineAnimTable,
            };
            """,
            to: root.appendingPathComponent("src/data/object_events/object_event_graphics_info.h")
        )
        try write(
            """
            static const struct SpriteFrameImage sPicTable_Boy1[] = {
                overworld_frame(gObjectEventPic_Boy1, 2, 4, 0),
            };
            """,
            to: root.appendingPathComponent("src/data/object_events/object_event_pic_tables.h")
        )
        try write(
            """
            const u16 gObjectEventPic_Boy1[] = INCGFX_U16("graphics/object_events/pics/people/boy_1.png", ".4bpp");
            """,
            to: root.appendingPathComponent("src/data/object_events/object_event_graphics.h")
        )
    }

    private func writeFieldmap(primaryMetatiles: Int, totalMetatiles: Int, to root: URL) throws {
        try write(
            """
            #define NUM_METATILES_IN_PRIMARY \(primaryMetatiles)
            #define NUM_METATILES_TOTAL \(totalMetatiles)
            """,
            to: root.appendingPathComponent("include/fieldmap.h")
        )
    }

    private func projectIndex(root: URL) -> ProjectIndex {
        ProjectIndex(
            root: SourceLocation(path: root.path, exists: true),
            profile: .pokefirered,
            adapterID: "test.fixture",
            adapterName: "Fixture",
            editorModules: [.maps],
            capabilities: [.mapIndex, .layoutIndex],
            writePolicy: .explicitApply,
            documents: []
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

    private func writeDWords(_ words: [UInt32], to url: URL) throws {
        var data = Data()
        for word in words {
            data.append(UInt8(word & 0x000000ff))
            data.append(UInt8((word >> 8) & 0x000000ff))
            data.append(UInt8((word >> 16) & 0x000000ff))
            data.append(UInt8((word >> 24) & 0x000000ff))
        }
        try write(data, to: url)
    }

    private func encodedWords(_ words: [UInt16]) -> Data {
        var data = Data()
        for word in words {
            data.append(UInt8(word & 0x00ff))
            data.append(UInt8((word >> 8) & 0x00ff))
        }
        return data
    }

    private func manualPlan(root: URL, changes: [MapEditFileChange], diagnostics: [Diagnostic] = []) -> MapEditPlan {
        MapEditPlan(
            rootPath: root.path,
            documentID: "fixture",
            operations: [],
            changes: changes,
            diagnostics: diagnostics,
            mutationPlan: MutationPlan(
                title: "Fixture plan",
                summary: "Fixture plan",
                changes: changes.map { PlannedChange(path: $0.path, summary: $0.summary) },
                diagnostics: diagnostics,
                requiresExplicitApply: true
            ),
            backupRelativeRoot: ".pokemonhackstudio/backups/fixture"
        )
    }

    private func fileChange(path: String, originalByteCount: Int = 0, newData: Data = Data([0x01])) -> MapEditFileChange {
        MapEditFileChange(
            path: path,
            summary: "Fixture change",
            originalByteCount: originalByteCount,
            newByteCount: newData.count,
            newData: newData
        )
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

private final class MapVisualTemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackMapVisualTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
