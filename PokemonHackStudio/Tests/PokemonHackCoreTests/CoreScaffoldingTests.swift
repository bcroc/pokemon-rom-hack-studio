import XCTest
@testable import PokemonHackCore

final class CoreScaffoldingTests: XCTestCase {
    private var temporaryDirectories: [CoreTemporaryDirectory] = []

    override func tearDown() {
        temporaryDirectories.removeAll()
        super.tearDown()
    }

    func testDetectsRubySapphireAdapterBeforeFireRedFallback() throws {
        let root = try makeDecompFixture(name: "pokeruby") { root in
            try write(
                """
                GAME_VERSION  ?= RUBY
                BUILD_NAME := ruby
                """,
                to: root.appendingPathComponent("config.mk")
            )
            try write("ROM := poke$(BUILD_NAME).gba\n", to: root.appendingPathComponent("Makefile"))
            try write("placeholder\n", to: root.appendingPathComponent("ruby.sha1"))
        }

        let profile = try ProjectInspector.detectProfile(at: root)
        let index = try GameAdapterRegistry.index(path: root.path)

        XCTAssertEqual(profile, .pokeruby)
        XCTAssertEqual(index.adapterID, "pret.pokeruby")
        XCTAssertTrue(index.buildTargets.contains { $0.id == "ruby-build" })
        XCTAssertTrue(index.documents.contains { $0.relativePath == "config.mk" })
        XCTAssertTrue(index.capabilities.contains(.patchPlanning))
        XCTAssertTrue(index.capabilities.contains(.playtestBridge))
    }

    func testExpansionAdapterWinsOverEmeraldDetection() throws {
        let root = try makeDecompFixture(name: "pokeemerald-expansion") { root in
            try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
            try makeDirectory(root.appendingPathComponent("graphics/pokenav"))
            try write("#define EXPANSION_VERSION 1\n", to: root.appendingPathComponent("include/constants/expansion.h"))
            try write("// RHH header\n", to: root.appendingPathComponent("src/rom_header_rhh.c"))
        }

        let index = try GameAdapterRegistry.index(path: root.path)

        XCTAssertEqual(index.profile, .pokeemeraldExpansion)
        XCTAssertEqual(index.adapterID, "rhh.pokeemerald-expansion")
        XCTAssertTrue(index.documents.contains { $0.relativePath == "include/constants/expansion.h" })
        XCTAssertTrue(index.buildTargets.contains { $0.id == "expansion-check" })
    }

    func testExpansionAdapterUsesExpansionTrainerSourcesWithoutEmeraldTrainerWarning() throws {
        let root = try makeDecompFixture(name: "pokeemerald-expansion") { root in
            try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
            try makeDirectory(root.appendingPathComponent("graphics/pokenav"))
            try writeCommonDecompSources(root: root, trainerPath: "src/data/trainers.party", itemPath: "src/data/items.h")
            try write("// trainer parties\n", to: root.appendingPathComponent("src/data/trainer_parties.h"))
            try write("#define EXPANSION_VERSION 1\n", to: root.appendingPathComponent("include/constants/expansion.h"))
            try write("// RHH header\n", to: root.appendingPathComponent("src/rom_header_rhh.c"))
            try write("// gimmicks\n", to: root.appendingPathComponent("src/data/gimmicks.h"))
            try write("// forms\n", to: root.appendingPathComponent("src/data/pokemon/form_change_tables.h"))
            try write("#define BATTLE_TEST 1\n", to: root.appendingPathComponent("include/config/battle.h"))
            try write("#define POKEMON_TEST 1\n", to: root.appendingPathComponent("include/config/pokemon.h"))
            try write("#define SPECIES_TEST 1\n", to: root.appendingPathComponent("include/config/species_enabled.h"))
            try write("migration notes\n", to: root.appendingPathComponent("migration_scripts/README.md"))
            try write("// runner\n", to: root.appendingPathComponent("test/test_runner.c"))
        }

        let index = try GameAdapterRegistry.index(path: root.path)

        XCTAssertEqual(index.profile, .pokeemeraldExpansion)
        XCTAssertFalse(index.documents.contains { $0.relativePath == "src/data/trainers.h" })
        XCTAssertTrue(index.documents.contains { $0.relativePath == "src/data/trainers.party" && $0.exists })
        XCTAssertTrue(index.documents.contains { $0.relativePath == "src/data/trainer_parties.h" && $0.exists })
        XCTAssertFalse(index.diagnostics.contains { $0.span?.relativePath == "src/data/trainers.h" })
        XCTAssertFalse(index.diagnostics.contains { $0.code == "SOURCE_MISSING" })
    }

    func testFireRedAdapterUsesItemsJSONWhenItemsHeaderIsAbsent() throws {
        let root = try makeDecompFixture(name: "pokefirered") { root in
            try write("ROM := poke$(BUILD_NAME).gba\n", to: root.appendingPathComponent("Makefile"))
            try makeDirectory(root.appendingPathComponent("graphics/quest_log"))
            try writeCommonDecompSources(root: root, trainerPath: "src/data/trainers.h", itemPath: "src/data/items.json")
        }

        let index = try GameAdapterRegistry.index(path: root.path)

        XCTAssertEqual(index.profile, .pokefirered)
        XCTAssertFalse(index.documents.contains { $0.relativePath == "src/data/items.h" })
        XCTAssertTrue(index.documents.contains { $0.relativePath == "src/data/items.json" && $0.exists })
        XCTAssertFalse(index.diagnostics.contains { $0.span?.relativePath == "src/data/items.h" })
        XCTAssertFalse(index.diagnostics.contains { $0.code == "SOURCE_MISSING" })
    }

    func testMissingPreferredFallbackSourcesStillWarn() throws {
        let root = try makeDecompFixture(name: "pokefirered") { root in
            try write("ROM := poke$(BUILD_NAME).gba\n", to: root.appendingPathComponent("Makefile"))
            try makeDirectory(root.appendingPathComponent("graphics/quest_log"))
            try writeCommonDecompSources(root: root, trainerPath: "src/data/trainers.h", itemPath: nil)
        }

        let index = try GameAdapterRegistry.index(path: root.path)

        XCTAssertTrue(index.documents.contains { $0.relativePath == "src/data/items.json" && !$0.exists })
        XCTAssertTrue(index.diagnostics.contains { diagnostic in
            diagnostic.code == "SOURCE_MISSING" && diagnostic.span?.relativePath == "src/data/items.json"
        })
    }

    func testBinaryROMAdapterIndexesLocalROMWithoutMutation() throws {
        let temp = try CoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let rom = temp.url.appendingPathComponent("test.gba")
        var bytes = [UInt8](repeating: 0, count: 0xC0)
        bytes.replaceSubrange(0xA0..<0xAC, with: Array("POKEMON TEST".utf8))
        bytes.replaceSubrange(0xAC..<0xB0, with: Array("BPEE".utf8))
        bytes.replaceSubrange(0xB0..<0xB2, with: Array("01".utf8))
        try Data(bytes).write(to: rom)

        let adapter = try XCTUnwrap(try GameAdapterRegistry.adapter(for: rom.path))
        let index = try adapter.index(root: rom, fileManager: .default)
        let image = ROMImage(path: rom.path, data: try Data(contentsOf: rom))

        XCTAssertEqual(index.profile, .binaryROM)
        XCTAssertEqual(index.writePolicy, .mutationPlanOnly)
        XCTAssertTrue(index.capabilities.contains(.binaryROMGraph))
        XCTAssertTrue(index.capabilities.contains(.patchPlanning))
        XCTAssertTrue(index.capabilities.contains(.playtestBridge))
        XCTAssertEqual(image.title, "POKEMON TEST")
        XCTAssertEqual(image.gameCode, "BPEE")
        XCTAssertEqual(image.makerCode, "01")
    }

    func testBinaryROMGraphReportsHeaderPointersAndFreeSpace() throws {
        let temp = try CoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let rom = temp.url.appendingPathComponent("graph.gba")
        var bytes = [UInt8](repeating: 0xff, count: 0x200)
        bytes.replaceSubrange(0x04..<0xA0, with: Array(repeating: 1, count: 0x9C))
        bytes.replaceSubrange(0xA0..<0xAC, with: Array("POKEMON TEST".utf8))
        bytes.replaceSubrange(0xAC..<0xB0, with: Array("BPEE".utf8))
        bytes.replaceSubrange(0xB0..<0xB2, with: Array("01".utf8))
        bytes[0xBC] = 0
        let expected = UInt8((0x19 - bytes[0xA0...0xBC].reduce(0) { ($0 + Int($1)) & 0xff }) & 0xff)
        bytes[0xBD] = expected
        bytes[0x100] = 0x80
        bytes[0x101] = 0x00
        bytes[0x102] = 0x00
        bytes[0x103] = 0x08
        try Data(bytes).write(to: rom)

        let graph = BinaryROMGraphBuilder.build(path: rom.path, data: try Data(contentsOf: rom))
        let entry = GenIIIResourceRegistry.resourceIndex(path: rom.path)

        XCTAssertEqual(graph.image.gameCode, "BPEE")
        XCTAssertEqual(graph.image.isComplementChecksumValid, true)
        XCTAssertTrue(graph.pointerCandidates.contains { $0.sourceOffset == 0x100 && $0.targetOffset == 0x80 })
        XCTAssertTrue(graph.freeSpaceRanges.contains { $0.offset >= 0x104 && $0.fillByte == 0xff })
        XCTAssertTrue(entry.items.contains { $0.category == "ROM Header" && $0.kind == "Game Code" })
        XCTAssertTrue(entry.items.contains { $0.category == "GBA Pointer" })
        XCTAssertTrue(entry.items.contains { $0.category == "Free Space" })
    }

    func testMapGroupIndexRoundTripsWithoutLosingGroups() throws {
        let json = Data(
            """
            {
              "group_order": ["gMapGroup_TownsAndRoutes", "gMapGroup_Indoor"],
              "gMapGroup_TownsAndRoutes": ["LittlerootTown", "Route101"],
              "gMapGroup_Indoor": ["LittlerootTown_ProfessorBirchsLab"]
            }
            """.utf8
        )

        let decoded = try SourceParsers.decodeMapGroups(json)
        let encoded = try JSONEncoder().encode(decoded)
        let decodedAgain = try SourceParsers.decodeMapGroups(encoded)

        XCTAssertEqual(decoded.groupOrder, ["gMapGroup_TownsAndRoutes", "gMapGroup_Indoor"])
        XCTAssertEqual(decoded.groups["gMapGroup_TownsAndRoutes"], ["LittlerootTown", "Route101"])
        XCTAssertEqual(decodedAgain, decoded)
    }

    func testLayoutIndexDecodesPretShape() throws {
        let json = Data(
            """
            {
              "layouts_table_label": "gMapLayouts",
              "layouts": [
                {
                  "id": "LAYOUT_LITTLEROOT_TOWN",
                  "name": "LittlerootTown_Layout",
                  "width": 20,
                  "height": 20,
                  "primary_tileset": "gTileset_General",
                  "secondary_tileset": "gTileset_Petalburg",
                  "border_filepath": "data/layouts/LittlerootTown/border.bin",
                  "blockdata_filepath": "data/layouts/LittlerootTown/map.bin"
                }
              ]
            }
            """.utf8
        )

        let decoded = try SourceParsers.decodeLayouts(json)

        XCTAssertEqual(decoded.layoutsTableLabel, "gMapLayouts")
        XCTAssertEqual(decoded.layouts.first?.id, "LAYOUT_LITTLEROOT_TOWN")
        XCTAssertEqual(decoded.layouts.first?.width, 20)
        XCTAssertEqual(decoded.layouts.first?.blockdataFilepath, "data/layouts/LittlerootTown/map.bin")
    }

    func testCInitializerParserFindsEntriesWithSpans() {
        let text = """
        const struct SpeciesInfo gSpeciesInfo[] =
        {
            [SPECIES_TREECKO] =
            {
                .baseHP = 40,
                .baseAttack = 45,
            },
            [SPECIES_TORCHIC] = { .baseHP = 45 },
        };
        """

        let entries = CInitializerParser.entries(in: text, relativePath: "src/data/pokemon/species_info.h")

        XCTAssertEqual(entries.map(\.symbol), ["SPECIES_TREECKO", "SPECIES_TORCHIC"])
        XCTAssertEqual(entries[0].span.startLine, 3)
        XCTAssertTrue(entries[0].body.contains(".baseAttack"))
    }

    func testScriptTextDiagnosticsWarnsForLongAndUnterminatedStrings() {
        let diagnostics = ScriptTextDiagnostics.diagnose(
            text: """
                .string "This string is intentionally far too long for the configured Gen III text preview line length"
                .string "Missing terminator"
                .string "Done$"
            """,
            relativePath: "data/text/example.inc",
            maxLineLength: 40
        )

        XCTAssertTrue(diagnostics.contains { $0.code == "TEXT_LINE_LONG" })
        XCTAssertTrue(diagnostics.contains { $0.code == "TEXT_TERMINATOR_MISSING" })
    }

    func testByteCursorAndGBAPointerPrimitives() throws {
        var cursor = ByteCursor(data: Data([0x34, 0x12, 0x78, 0x56, 0x00, 0x08]))

        XCTAssertEqual(try cursor.readUInt16LE(), 0x1234)
        XCTAssertEqual(try cursor.readUInt32LE(), 0x08005678)
        XCTAssertEqual(GBAPointer(offset: 0x1234).rawValue, 0x08001234)
        XCTAssertEqual(GBAPointer(rawValue: 0x08001234).romOffset, 0x1234)
    }

    func testPatchParserSummarizesSyntheticPatchHeaders() throws {
        let ips = Data("PATCH".utf8)
            + Data([0x00, 0x00, 0x01, 0x00, 0x02, 0xAA, 0xBB])
            + Data("EOF".utf8)
        let bps = Data("BPS1".utf8) + Data([0x85, 0x86, 0x80])
        let ups = Data("UPS1".utf8) + Data([0x85, 0x86])

        let ipsSummary = try PatchParser.parseSummary(data: ips)
        let bpsSummary = try PatchParser.parseSummary(data: bps)
        let upsSummary = try PatchParser.parseSummary(data: ups)

        XCTAssertEqual(ipsSummary.format, .ips)
        XCTAssertEqual(ipsSummary.recordCount, 1)
        XCTAssertFalse(ipsSummary.hasEmbeddedChecksums)
        XCTAssertEqual(bpsSummary.format, .bps)
        XCTAssertEqual(bpsSummary.sourceSize, 5)
        XCTAssertEqual(bpsSummary.targetSize, 6)
        XCTAssertTrue(bpsSummary.hasEmbeddedChecksums)
        XCTAssertEqual(upsSummary.format, .ups)
        XCTAssertEqual(upsSummary.sourceSize, 5)
        XCTAssertEqual(upsSummary.targetSize, 6)
    }

    private func makeDecompFixture(
        name: String,
        configure: (URL) throws -> Void
    ) throws -> URL {
        let temp = try CoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent(name)
        try makeDirectory(root)
        try makeDirectory(root.appendingPathComponent("src"))
        try makeDirectory(root.appendingPathComponent("include"))
        try makeDirectory(root.appendingPathComponent("graphics/pokemon"))
        try makeDirectory(root.appendingPathComponent("graphics/trainers"))
        try makeDirectory(root.appendingPathComponent("graphics/items"))
        try makeDirectory(root.appendingPathComponent("data/scripts"))
        try makeDirectory(root.appendingPathComponent("data/text"))
        try makeDirectory(root.appendingPathComponent("data/maps"))
        try makeDirectory(root.appendingPathComponent("data/layouts"))
        try write("[]\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try configure(root)
        return root
    }

    private func writeCommonDecompSources(root: URL, trainerPath: String, itemPath: String?) throws {
        try write("const struct SpeciesInfo gSpeciesInfo[] = {};\n", to: root.appendingPathComponent("src/data/pokemon/species_info.h"))
        try write("trainer data\n", to: root.appendingPathComponent(trainerPath))
        if let itemPath {
            try write("item data\n", to: root.appendingPathComponent(itemPath))
        }
        try write("[]\n", to: root.appendingPathComponent("src/data/wild_encounters.json"))
    }

    private func makeDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private func write(_ text: String, to url: URL) throws {
        try makeDirectory(url.deletingLastPathComponent())
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
}

private final class CoreTemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackCoreScaffoldingTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
