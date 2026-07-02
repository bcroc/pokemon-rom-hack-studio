import XCTest
@testable import PokemonHackCore

final class MapRenderAuditTests: XCTestCase {
    private var temporaryDirectories: [URL] = []

    override func tearDownWithError() throws {
        for url in temporaryDirectories {
            try? FileManager.default.removeItem(at: url)
        }
        temporaryDirectories.removeAll()
        try super.tearDownWithError()
    }

    func testAuditTraversesAllMapsAndTextures() throws {
        let root = try makeAuditProject(mapNames: ["Route1", "Route2"])

        let report = MapRenderAuditBuilder.build(path: root.path)

        XCTAssertEqual(report.status, .passed)
        XCTAssertEqual(report.summary.targetCount, 1)
        XCTAssertEqual(report.summary.mapCount, 2)
        XCTAssertEqual(report.summary.auditedMapCount, 2)
        XCTAssertEqual(report.targets.first?.maps.map(\.mapID), ["MAP_ROUTE1", "MAP_ROUTE2"])
        XCTAssertEqual(report.targets.first?.maps.first?.textureChecks.filter { $0.kind == .tileImage }.count, 2)
        XCTAssertEqual(report.targets.first?.maps.first?.textureChecks.filter { $0.kind == .palette }.count, 2)
    }

    func testTextureSuccessReportsDimensionsAndPaletteCounts() throws {
        let root = try makeAuditProject()

        let report = MapRenderAuditBuilder.build(path: root.path)
        let map = try XCTUnwrap(report.targets.first?.maps.first)
        let tile = try XCTUnwrap(map.textureChecks.first { $0.kind == .tileImage && $0.role == "primary" })
        let palette = try XCTUnwrap(map.textureChecks.first { $0.kind == .palette && $0.role == "primary" })

        XCTAssertEqual(report.status, .passed)
        XCTAssertEqual(tile.width, 8)
        XCTAssertEqual(tile.height, 8)
        XCTAssertEqual(tile.tileCount, 1)
        XCTAssertEqual(palette.colorCount, 16)
    }

    func testMissingTileImageIsBlocker() throws {
        let root = try makeAuditProject()
        try FileManager.default.removeItem(at: root.appendingPathComponent("data/tilesets/primary/general/tiles.png"))

        let report = MapRenderAuditBuilder.build(path: root.path)

        XCTAssertEqual(report.status, .failed)
        XCTAssertTrue(report.failures.contains { $0.code == "MAP_RENDER_AUDIT_TILE_IMAGE_MISSING" })
    }

    func testMalformedIndexedPNGIsBlocker() throws {
        let root = try makeAuditProject()
        try write(Data("not an indexed png".utf8), to: root.appendingPathComponent("data/tilesets/primary/general/tiles.png"))

        let report = MapRenderAuditBuilder.build(path: root.path)

        XCTAssertEqual(report.status, .failed)
        XCTAssertTrue(report.failures.contains { $0.code == "MAP_RENDER_AUDIT_TILE_IMAGE_UNPARSEABLE" })
    }

    func testMissingPaletteIsBlocker() throws {
        let root = try makeAuditProject()
        try FileManager.default.removeItem(at: root.appendingPathComponent("data/tilesets/primary/general/palettes/00.gbapal"))

        let report = MapRenderAuditBuilder.build(path: root.path)

        XCTAssertEqual(report.status, .failed)
        XCTAssertTrue(report.failures.contains { $0.code == "MAP_RENDER_AUDIT_PALETTE_MISSING" })
    }

    func testUnparseablePaletteIsBlocker() throws {
        let root = try makeAuditProject()
        try write("JASC-PAL\n", to: root.appendingPathComponent("data/tilesets/primary/general/palettes/00.gbapal"))

        let report = MapRenderAuditBuilder.build(path: root.path)

        XCTAssertEqual(report.status, .failed)
        XCTAssertTrue(report.failures.contains { $0.code == "MAP_RENDER_AUDIT_PALETTE_UNPARSEABLE" })
    }

    func testMissingMetatileDefinitionIsBlocker() throws {
        let root = try makeAuditProject(mapMetatileID: 2)

        let report = MapRenderAuditBuilder.build(path: root.path)

        XCTAssertEqual(report.status, .failed)
        XCTAssertTrue(report.failures.contains { $0.code == "MAP_RENDER_AUDIT_METATILE_DEFINITION_MISSING" })
    }

    func testOutOfRangeTileAndPaletteReferencesAreBlockers() throws {
        let root = try makeAuditProject(metatileWords: [0xf001, 0x03ff] + Array(repeating: 0, count: 6))
        try write(
            """
            #define NUM_METATILES_IN_PRIMARY 1
            #define NUM_METATILES_TOTAL 2
            #define NUM_TILES_IN_PRIMARY 4
            #define NUM_TILES_TOTAL 5
            """,
            to: root.appendingPathComponent("include/fieldmap.h")
        )

        let report = MapRenderAuditBuilder.build(path: root.path)

        XCTAssertEqual(report.status, .failed)
        XCTAssertTrue(report.failures.contains { $0.code == "MAP_RENDER_AUDIT_TILE_INDEX_OUT_OF_RANGE" })
        XCTAssertTrue(report.failures.contains { $0.code == "MAP_RENDER_AUDIT_PALETTE_INDEX_OUT_OF_RANGE" })
    }

    func testAllBlankRenderIsBlocker() throws {
        let root = try makeAuditProject(tilePaletteIndex: 0)

        let report = MapRenderAuditBuilder.build(path: root.path)

        XCTAssertEqual(report.status, .failed)
        XCTAssertTrue(report.failures.contains { $0.code == "MAP_RENDER_AUDIT_ALL_BLANK_RENDER" })
    }

    func testWarningOnlyDiagnosticsStayNonFatal() throws {
        let root = try makeAuditProject(includeUnresolvedObjectEvent: true)

        let report = MapRenderAuditBuilder.build(path: root.path)

        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.warningBuckets.contains { $0.code == "MAP_EVENT_SPRITE_UNRESOLVED" })
        XCTAssertTrue(report.failures.isEmpty)
    }

    func testAllWorkspaceAuditReportsUnsupportedTargetsAsSkipped() throws {
        let workspace = try makeTemporaryDirectory()
        let sourceRoot = workspace.appendingPathComponent("pokeemerald")
        try makeAuditProject(at: sourceRoot)
        try write(Data([0xde, 0xad, 0xbe, 0xef]), to: workspace.appendingPathComponent("local.nds"))

        let report = MapRenderAuditBuilder.buildAll(workspaceRoot: workspace.path)

        XCTAssertEqual(report.status, .passed)
        XCTAssertEqual(report.summary.auditedTargetCount, 1)
        XCTAssertEqual(report.summary.mapCount, 1)
        XCTAssertTrue(report.skippedTargets.contains { $0.path.hasSuffix("local.nds") })
    }

    private func makeAuditProject(
        mapNames: [String] = ["Route1"],
        mapMetatileID: UInt16 = 0,
        tilePaletteIndex: UInt8 = 1,
        metatileWords: [UInt16] = Array(repeating: 0, count: 8),
        includeUnresolvedObjectEvent: Bool = false
    ) throws -> URL {
        let root = try makeTemporaryDirectory()
        try makeAuditProject(
            at: root,
            mapNames: mapNames,
            mapMetatileID: mapMetatileID,
            tilePaletteIndex: tilePaletteIndex,
            metatileWords: metatileWords,
            includeUnresolvedObjectEvent: includeUnresolvedObjectEvent
        )
        return root
    }

    private func makeAuditProject(
        at root: URL,
        mapNames: [String] = ["Route1"],
        mapMetatileID: UInt16 = 0,
        tilePaletteIndex: UInt8 = 1,
        metatileWords: [UInt16] = Array(repeating: 0, count: 8),
        includeUnresolvedObjectEvent: Bool = false
    ) throws {
        try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("src"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/pokenav"), withIntermediateDirectories: true)
        try write(
            """
            #define NUM_METATILES_IN_PRIMARY 1
            #define NUM_METATILES_TOTAL 2
            #define NUM_TILES_IN_PRIMARY 1
            #define NUM_TILES_TOTAL 2
            """,
            to: root.appendingPathComponent("include/fieldmap.h")
        )
        try writeMapGroupJSON(mapNames: mapNames, to: root)
        try writeLayoutsJSON(to: root)
        for name in mapNames {
            try writeMapJSON(name: name, includeUnresolvedObjectEvent: includeUnresolvedObjectEvent, to: root)
        }
        try writeTilesetHeaders(to: root)
        try writeTilesetGraphics(to: root)
        try writeTilesetMetatiles(to: root)
        try writeWords([mapMetatileID, mapMetatileID, mapMetatileID, mapMetatileID], to: root.appendingPathComponent("data/layouts/Route1/map.bin"))
        try writeWords([mapMetatileID, mapMetatileID, mapMetatileID, mapMetatileID], to: root.appendingPathComponent("data/layouts/Route1/border.bin"))
        try writeWords(metatileWords, to: root.appendingPathComponent("data/tilesets/primary/general/metatiles.bin"))
        try writeWords(Array(repeating: 0x0011, count: max(metatileWords.count / 8, 1)), to: root.appendingPathComponent("data/tilesets/primary/general/metatile_attributes.bin"))
        try writeWords(Array(repeating: 0, count: 8), to: root.appendingPathComponent("data/tilesets/secondary/route/metatiles.bin"))
        try writeWords([0x0011], to: root.appendingPathComponent("data/tilesets/secondary/route/metatile_attributes.bin"))
        try write(indexedPNG(width: 8, height: 8, paletteIndex: tilePaletteIndex), to: root.appendingPathComponent("data/tilesets/primary/general/tiles.png"))
        try write(indexedPNG(width: 8, height: 8, paletteIndex: 1), to: root.appendingPathComponent("data/tilesets/secondary/route/tiles.png"))
        try write(gbaPalette(colorCount: 16), to: root.appendingPathComponent("data/tilesets/primary/general/palettes/00.gbapal"))
        try write(gbaPalette(colorCount: 16), to: root.appendingPathComponent("data/tilesets/secondary/route/palettes/00.gbapal"))
    }

    private func makeTemporaryDirectory() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("MapRenderAuditTests-\(UUID().uuidString)")
        temporaryDirectories.append(root)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func writeMapGroupJSON(mapNames: [String], to root: URL) throws {
        let names = mapNames.map { "\"\($0)\"" }.joined(separator: ", ")
        try write(
            """
            {
              "group_order": ["gMapGroup_Routes"],
              "gMapGroup_Routes": [\(names)]
            }
            """,
            to: root.appendingPathComponent("data/maps/map_groups.json")
        )
    }

    private func writeLayoutsJSON(to root: URL) throws {
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
    }

    private func writeMapJSON(name: String, includeUnresolvedObjectEvent: Bool, to root: URL) throws {
        let objectEvents = includeUnresolvedObjectEvent
            ? """
              [
                {
                  "local_id": 1,
                  "type": "object",
                  "graphics_id": "OBJ_EVENT_GFX_UNKNOWN_TEST",
                  "x": 1,
                  "y": 1,
                  "elevation": 3,
                  "script": "0x0"
                }
              ]
            """
            : "[]"
        try write(
            """
            {
              "id": "\(mapID(for: name))",
              "name": "\(name)",
              "layout": "LAYOUT_ROUTE1",
              "music": "MUS_ROUTE1",
              "region_map_section": "MAPSEC_ROUTE1",
              "weather": "WEATHER_SUNNY",
              "map_type": "MAP_TYPE_ROUTE",
              "connections": [],
              "object_events": \(objectEvents),
              "warp_events": [],
              "coord_events": [],
              "bg_events": []
            }
            """,
            to: root.appendingPathComponent("data/maps/\(name)/map.json")
        )
    }

    private func writeTilesetHeaders(to root: URL) throws {
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
    }

    private func writeTilesetGraphics(to root: URL) throws {
        try write(
            """
            const u32 gTilesetTiles_General[] = INCBIN_U32("data/tilesets/primary/general/tiles.4bpp.lz");
            const u32 gTilesetTiles_Route[] = INCBIN_U32("data/tilesets/secondary/route/tiles.4bpp.lz");
            const u16 gTilesetPalettes_General[][16] = {
                INCBIN_U16("data/tilesets/primary/general/palettes/00.gbapal"),
            };
            const u16 gTilesetPalettes_Route[][16] = {
                INCBIN_U16("data/tilesets/secondary/route/palettes/00.gbapal"),
            };
            """,
            to: root.appendingPathComponent("src/data/tilesets/graphics.h")
        )
    }

    private func writeTilesetMetatiles(to root: URL) throws {
        try write(
            """
            const u16 gMetatiles_General[] = INCBIN_U16("data/tilesets/primary/general/metatiles.bin");
            const u16 gMetatiles_Route[] = INCBIN_U16("data/tilesets/secondary/route/metatiles.bin");
            const u16 gMetatileAttributes_General[] = INCBIN_U16("data/tilesets/primary/general/metatile_attributes.bin");
            const u16 gMetatileAttributes_Route[] = INCBIN_U16("data/tilesets/secondary/route/metatile_attributes.bin");
            """,
            to: root.appendingPathComponent("src/data/tilesets/metatiles.h")
        )
    }

    private func mapID(for name: String) -> String {
        "MAP_" + name.map { character in
            character.isUppercase ? "_\(character)" : String(character).uppercased()
        }
        .joined()
        .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }

    private func indexedPNG(width: Int, height: Int, paletteIndex: UInt8) -> Data {
        var data = Data([137, 80, 78, 71, 13, 10, 26, 10])
        var ihdr = Data()
        appendUInt32BE(UInt32(width), to: &ihdr)
        appendUInt32BE(UInt32(height), to: &ihdr)
        ihdr.append(contentsOf: [8, 3, 0, 0, 0])
        appendChunk("IHDR", payload: ihdr, to: &data)
        appendChunk("PLTE", payload: Data([0, 0, 0, 255, 255, 255]), to: &data)
        var rows = Data()
        for _ in 0..<height {
            rows.append(0)
            rows.append(contentsOf: Array(repeating: paletteIndex, count: width))
        }
        appendChunk("IDAT", payload: rows, to: &data)
        appendChunk("IEND", payload: Data(), to: &data)
        return data
    }

    private func gbaPalette(colorCount: Int) -> Data {
        var data = Data()
        for index in 0..<colorCount {
            let raw: UInt16 = index == 1 ? 0x7fff : 0
            data.append(UInt8(raw & 0x00ff))
            data.append(UInt8((raw >> 8) & 0x00ff))
        }
        return data
    }

    private func writeWords(_ words: [UInt16], to url: URL) throws {
        var data = Data()
        for word in words {
            data.append(UInt8(word & 0x00ff))
            data.append(UInt8((word >> 8) & 0x00ff))
        }
        try write(data, to: url)
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

    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func write(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }
}
