import XCTest
@testable import PokemonHackCore

final class GenIIIAssetCatalogTests: XCTestCase {
    private var temporaryDirectories: [AssetCatalogTemporaryDirectory] = []

    override func tearDown() {
        temporaryDirectories.removeAll()
        super.tearDown()
    }

    func testAssetCatalogComposesSourceGraphsMapsGraphicsGeneratedAndInventory() throws {
        let root = try makeEmeraldAssetProject()
        let catalog = GenIIIAssetCatalogBuilder.build(path: root.path)

        XCTAssertEqual(catalog.profile, .pokeemerald)
        XCTAssertTrue(catalog.assets.contains { $0.category == .maps && $0.title == "Route1" })
        XCTAssertTrue(catalog.assets.contains { $0.category == .layouts && $0.title == "Route1_Layout" })
        XCTAssertTrue(catalog.assets.contains { $0.category == .scripts && $0.title == "Test_EventScript" })
        XCTAssertTrue(catalog.assets.contains { $0.category == .text && $0.title == "gText_Test" })
        XCTAssertTrue(catalog.assets.contains { $0.category == .species && $0.title == "SPECIES_TREECKO" })
        XCTAssertTrue(catalog.assets.contains { $0.category == .moves && $0.title == "MOVE_POUND" })
        XCTAssertTrue(catalog.assets.contains { $0.category == .learnsets && $0.title == "SPECIES_TREECKO" })
        XCTAssertTrue(catalog.assets.contains { $0.category == .evolutions && $0.title == "SPECIES_TREECKO" })
        XCTAssertTrue(catalog.assets.contains { $0.category == .pokedex && $0.relativePath == "src/data/pokemon/pokedex_entries.h" })
        XCTAssertTrue(catalog.assets.contains { $0.category == .graphics && $0.relativePath == "graphics/pokemon/treecko.png" })
        XCTAssertTrue(catalog.assets.contains { $0.category == .audio && $0.relativePath == "sound/songs/mus_test.s" })
        XCTAssertTrue(catalog.assets.contains { $0.category == .generated && $0.relativePath == "pokeemerald.gba" })

        let mapAsset = try XCTUnwrap(catalog.assets.first { $0.category == .maps && $0.title == "Route1" })
        XCTAssertEqual(mapAsset.navigationTarget?.module, .maps)
        XCTAssertEqual(mapAsset.navigationTarget?.identifier, "MAP_ROUTE1")

        let layoutAsset = try XCTUnwrap(catalog.assets.first { $0.category == .layouts && $0.title == "Route1_Layout" })
        XCTAssertEqual(layoutAsset.navigationTarget?.module, .maps)
        XCTAssertEqual(layoutAsset.navigationTarget?.identifier, "LAYOUT_ROUTE1")

        let scriptAsset = try XCTUnwrap(catalog.assets.first { $0.category == .scripts && $0.title == "Test_EventScript" })
        XCTAssertEqual(scriptAsset.navigationTarget?.module, .scripts)
        XCTAssertEqual(scriptAsset.navigationTarget?.identifier, "Test_EventScript")

        let speciesAsset = try XCTUnwrap(catalog.assets.first { $0.category == .species && $0.title == "SPECIES_TREECKO" })
        XCTAssertEqual(speciesAsset.navigationTarget?.module, .pokemon)
        XCTAssertEqual(speciesAsset.navigationTarget?.identifier, "SPECIES_TREECKO")

        let moveAsset = try XCTUnwrap(catalog.assets.first { $0.category == .moves && $0.title == "MOVE_POUND" })
        XCTAssertEqual(moveAsset.navigationTarget?.module, .pokemon)
        XCTAssertEqual(moveAsset.navigationTarget?.identifier, "MOVE_POUND")

        let graphicsAsset = try XCTUnwrap(catalog.assets.first { $0.category == .graphics && $0.relativePath == "graphics/pokemon/treecko.png" })
        XCTAssertEqual(graphicsAsset.navigationTarget?.module, .graphics)
        XCTAssertEqual(graphicsAsset.navigationTarget?.identifier, "graphics/pokemon/treecko.png")

        let generatedAsset = try XCTUnwrap(catalog.assets.first { $0.category == .generated && $0.relativePath == "pokeemerald.gba" })
        XCTAssertEqual(generatedAsset.navigationTarget?.module, .build)
        XCTAssertEqual(generatedAsset.navigationTarget?.identifier, "pokeemerald.gba")
    }

    func testSourceProjectAssetCatalogCacheIsCreatedReusedAndInvalidated() throws {
        let root = try makeEmeraldAssetProject()
        let cacheURL = root.appendingPathComponent(".pokemonhackstudio/indexes/asset-catalog-v1.json")

        let first = GenIIIAssetCatalogBuilder.build(path: root.path)
        let firstCacheData = try Data(contentsOf: cacheURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: cacheURL.path))

        let cached = GenIIIAssetCatalogBuilder.build(path: root.path)
        let cachedData = try Data(contentsOf: cacheURL)

        XCTAssertEqual(assetIDs(first), assetIDs(cached))
        XCTAssertEqual(first.assetCount, cached.assetCount)
        XCTAssertEqual(firstCacheData, cachedData)

        try write(
            minimalMapJSON(id: "MAP_ROUTE1", name: "Longer Route One", layout: "LAYOUT_ROUTE1"),
            to: root.appendingPathComponent("data/maps/Route1/map.json")
        )

        let invalidated = GenIIIAssetCatalogBuilder.build(path: root.path)
        let invalidatedData = try Data(contentsOf: cacheURL)

        XCTAssertTrue(invalidated.assets.contains { $0.category == .maps && $0.title == "Longer Route One" })
        XCTAssertNotEqual(firstCacheData, invalidatedData)
        XCTAssertEqual(first.assetCount, invalidated.assetCount)
    }

    func testAssetCatalogJSONDoesNotExposePersistentCachePayloadFields() throws {
        let root = try makeEmeraldAssetProject()
        let catalog = GenIIIAssetCatalogBuilder.build(path: root.path)
        let data = try JSONEncoder().encode(catalog)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertNil(object["schemaVersion"])
        XCTAssertNil(object["sourceFingerprint"])
        XCTAssertNil(object["project"])
        XCTAssertNil(object["catalog"])
    }

    func testSafeInventoryExcludesGeneratedNestedROMsAndBuildProducts() throws {
        let root = try makeEmeraldAssetProject()
        try write(Data([1, 2, 3]), to: root.appendingPathComponent("graphics/build/skipped.png"))
        try write(Data([1, 2, 3]), to: root.appendingPathComponent("data/generated.gba"))
        try write(Data([1, 2, 3]), to: root.appendingPathComponent("sound/songs/kept.mid"))

        let catalog = GenIIIAssetCatalogBuilder.build(path: root.path)

        XCTAssertFalse(catalog.assets.contains { $0.relativePath == "graphics/build/skipped.png" })
        XCTAssertFalse(catalog.assets.contains { $0.relativePath == "data/generated.gba" })
        XCTAssertTrue(catalog.assets.contains { $0.relativePath == "sound/songs/kept.mid" && $0.category == .audio })
    }

    func testBinaryROMBuildsReadOnlyROMAssetCatalog() throws {
        let temp = try AssetCatalogTemporaryDirectory()
        temporaryDirectories.append(temp)
        let rom = temp.url.appendingPathComponent("Pokemon Emerald.gba")
        try writeGBA(title: "POKEMON EMER", gameCode: "BPEE", to: rom)
        var data = try Data(contentsOf: rom)
        data.append(contentsOf: repeatElement(UInt8(0), count: 0x104 - data.count))
        data.replaceSubrange(0x100..<0x104, with: [0x80, 0x00, 0x00, 0x08])
        try data.write(to: rom)

        let catalog = GenIIIAssetCatalogBuilder.build(path: rom.path)

        XCTAssertEqual(catalog.profile, .binaryROM)
        let romAsset = try XCTUnwrap(catalog.assets.first { $0.category == .rom })
        XCTAssertEqual(romAsset.status, .valid)
        XCTAssertEqual(romAsset.availability, .availableLocalInput)
        XCTAssertTrue(catalog.assets.contains { $0.category == .rom && $0.tags.contains("ROM Header") })
        XCTAssertTrue(catalog.assets.contains { $0.category == .rom && $0.tags.contains("GBA Pointer") })
        XCTAssertTrue(catalog.assets.contains { $0.category == .rom && $0.tags.contains("Free Space") })
    }

    func testUnsupportedInputReturnsDiagnosticInsteadOfThrowing() throws {
        let temp = try AssetCatalogTemporaryDirectory()
        temporaryDirectories.append(temp)
        let file = temp.url.appendingPathComponent("notes.txt")
        try write("not a project or ROM\n", to: file)

        let catalog = GenIIIAssetCatalogBuilder.build(path: file.path)

        XCTAssertEqual(catalog.profile, .unknown)
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "ASSET_CATALOG_UNSUPPORTED_INPUT" })
    }

    func testAvailabilityClassificationSeparatesSourceHealthFromOptionalGeneratedOutputs() throws {
        let optionalGenerated = GenIIIAsset(
            id: "generated:pokeemerald.gba",
            title: "pokeemerald.gba",
            subtitle: "Build output",
            relativePath: "pokeemerald.gba",
            category: .generated,
            kind: "buildOutput",
            role: .generated,
            status: .missing
        )
        let staleGenerated = GenIIIAsset(
            id: "generated:tiles",
            title: "tiles.4bpp.lz",
            subtitle: "Converted tiles",
            relativePath: "data/tilesets/primary/test/tiles.4bpp.lz",
            category: .generated,
            kind: "generated",
            role: .artifact,
            status: .warning,
            diagnostics: [
                Diagnostic(
                    severity: .warning,
                    code: "GRAPHICS_GENERATED_ARTIFACT_STALE",
                    message: "Generated tiles are older than source.",
                    span: SourceSpan(relativePath: "data/tilesets/primary/test/tiles.4bpp.lz", startLine: 1)
                )
            ]
        )
        let missingRequiredSource = GenIIIAsset(
            id: "source:items",
            title: "items.h",
            subtitle: "Required source",
            relativePath: "src/data/items.h",
            category: .source,
            kind: "source",
            role: .source,
            status: .missing
        )
        let nonBlockingTextWarning = GenIIIAsset(
            id: "text:gText_Test",
            title: "gText_Test",
            subtitle: "Text",
            relativePath: "data/text/test.inc",
            category: .text,
            kind: "text",
            role: .source,
            status: .warning,
            diagnostics: [
                Diagnostic(
                    severity: .warning,
                    code: "TEXT_LINE_LONG",
                    message: "Text line is long.",
                    span: SourceSpan(relativePath: "data/text/test.inc", startLine: 3)
                )
            ]
        )
        let parserWarning = GenIIIAsset(
            id: "source:moves",
            title: "moves.h",
            subtitle: "Parser warning",
            relativePath: "src/data/battle_moves.h",
            category: .moves,
            kind: "sourceIndexRecord",
            role: .source,
            status: .warning,
            diagnostics: [
                Diagnostic(
                    severity: .warning,
                    code: "TABLE_NOT_FOUND",
                    message: "Move table was not found.",
                    span: SourceSpan(relativePath: "src/data/battle_moves.h", startLine: 1)
                )
            ]
        )

        XCTAssertEqual(optionalGenerated.availability, .optionalGeneratedMissing)
        XCTAssertEqual(staleGenerated.availability, .generatedStale)
        XCTAssertEqual(missingRequiredSource.availability, .missingRequiredSource)
        XCTAssertEqual(nonBlockingTextWarning.availability, .availableSource)
        XCTAssertEqual(parserWarning.availability, .parserWarning)
        XCTAssertFalse(optionalGenerated.availability.affectsResourceAvailability)
        XCTAssertFalse(staleGenerated.availability.affectsResourceAvailability)
        XCTAssertFalse(nonBlockingTextWarning.availability.affectsResourceAvailability)
        XCTAssertTrue(missingRequiredSource.availability.affectsResourceAvailability)
        XCTAssertTrue(parserWarning.availability.affectsResourceAvailability)

        let catalog = GenIIIAssetCatalog(
            root: SourceLocation(path: "/tmp/pokemonhack-availability", exists: true),
            profile: .pokeemerald,
            adapterID: "test.availability",
            adapterName: "Availability Test",
            assets: [optionalGenerated, staleGenerated, missingRequiredSource, nonBlockingTextWarning, parserWarning]
        )
        let counts = Dictionary(uniqueKeysWithValues: catalog.availabilityCounts.map { ($0.availability, $0.count) })
        XCTAssertEqual(counts[.optionalGeneratedMissing], 1)
        XCTAssertEqual(counts[.generatedStale], 1)
        XCTAssertEqual(counts[.missingRequiredSource], 1)
        XCTAssertEqual(counts[.availableSource], 1)
        XCTAssertEqual(counts[.parserWarning], 1)
    }

    private func makeEmeraldAssetProject() throws -> URL {
        let temp = try AssetCatalogTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url

        try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
        try write("f3ae088181bf583e55daf962a92bb46f4f1d07b7  pokeemerald.gba\n", to: root.appendingPathComponent("rom.sha1"))
        try write("#define NUM_METATILES_IN_PRIMARY 0x200\n#define NUM_METATILES_TOTAL 0x400\n", to: root.appendingPathComponent("include/fieldmap.h"))

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
        try write(minimalMapJSON(id: "MAP_ROUTE1", name: "Route1", layout: "LAYOUT_ROUTE1"), to: root.appendingPathComponent("data/maps/Route1/map.json"))
        try writeBlockdata([1], to: root.appendingPathComponent("data/layouts/Route1/map.bin"))

        try write("const struct SpeciesInfo gSpeciesInfo[] = { [SPECIES_TREECKO] = { .baseHP = 40, .growthRate = GROWTH_MEDIUM_SLOW }, };\n", to: root.appendingPathComponent("src/data/pokemon/species_info.h"))
        try write("const struct Trainer gTrainers[] = { [TRAINER_TEST] = { .trainerName = _(\"TEST\") }, };\n", to: root.appendingPathComponent("src/data/trainers.h"))
        try write("const struct Item gItems[] = { [ITEM_POTION] = { .name = _(\"POTION\"), .itemId = ITEM_POTION }, };\n", to: root.appendingPathComponent("src/data/items.h"))
        try write("const struct BattleMove gBattleMoves[] = { [MOVE_POUND] = { .power = 40, .type = TYPE_NORMAL, .pp = 35 }, };\n", to: root.appendingPathComponent("src/data/battle_moves.h"))
        try write("const u16 *const gLevelUpLearnsets[NUM_SPECIES] = { [SPECIES_TREECKO] = sTreeckoLevelUpLearnset, };\n", to: root.appendingPathComponent("src/data/pokemon/level_up_learnset_pointers.h"))
        try write("const union { u32 as_u32s[2]; } gTMHMLearnsets[NUM_SPECIES] = { [SPECIES_TREECKO] = { .as_u32s = {1, 0} }, };\n", to: root.appendingPathComponent("src/data/pokemon/tmhm_learnsets.h"))
        try write("const struct Evolution gEvolutionTable[NUM_SPECIES][EVOS_PER_MON] = { [SPECIES_TREECKO] = {{EVO_LEVEL, 16, SPECIES_GROVYLE}}, };\n", to: root.appendingPathComponent("src/data/pokemon/evolution.h"))
        try write("const struct PokedexEntry gPokedexEntries[] = { { .categoryName = _(\"WOOD GECKO\"), .height = 5, .weight = 50 }, };\n", to: root.appendingPathComponent("src/data/pokemon/pokedex_entries.h"))

        try write(
            """
            Test_EventScript::
                lock
                msgbox gText_Test
                release
                end
            """,
            to: root.appendingPathComponent("data/scripts/test.inc")
        )
        try write(
            """
            gText_Test::
                .string "Hello$"
            """,
            to: root.appendingPathComponent("data/text/test.inc")
        )

        try write(Data([0x89, 0x50, 0x4E, 0x47]), to: root.appendingPathComponent("graphics/pokemon/treecko.png"))
        try write("song\n", to: root.appendingPathComponent("sound/songs/mus_test.s"))
        return root
    }

    private func minimalMapJSON(id: String, name: String, layout: String) -> String {
        """
        {
          "id": "\(id)",
          "name": "\(name)",
          "layout": "\(layout)",
          "music": "MUS_NONE",
          "region_map_section": "MAPSEC_NONE",
          "weather": "WEATHER_NONE",
          "map_type": "MAP_TYPE_NONE",
          "connections": [],
          "object_events": [],
          "warp_events": [],
          "coord_events": [],
          "bg_events": []
        }
        """
    }

    private func assetIDs(_ catalog: GenIIIAssetCatalog) -> [String] {
        catalog.assets.map(\.id).sorted()
    }

    private func writeBlockdata(_ words: [UInt16], to url: URL) throws {
        var data = Data()
        for word in words {
            data.append(UInt8(word & 0x00ff))
            data.append(UInt8((word & 0xff00) >> 8))
        }
        try write(data, to: url)
    }

    private func writeGBA(title: String, gameCode: String, to url: URL) throws {
        var bytes = [UInt8](repeating: 0, count: 0xC0)
        replaceASCII(title, at: 0xA0, in: &bytes, maxLength: 12)
        replaceASCII(gameCode, at: 0xAC, in: &bytes, maxLength: 4)
        replaceASCII("01", at: 0xB0, in: &bytes, maxLength: 2)
        try Data(bytes).write(to: url)
    }

    private func replaceASCII(_ string: String, at offset: Int, in bytes: inout [UInt8], maxLength: Int? = nil) {
        let replacement = Array(string.utf8).prefix(maxLength ?? string.utf8.count)
        bytes.replaceSubrange(offset..<(offset + replacement.count), with: replacement)
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

private final class AssetCatalogTemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackAssetCatalogTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
}
