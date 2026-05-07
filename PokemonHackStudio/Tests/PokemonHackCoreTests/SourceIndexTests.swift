import XCTest
@testable import PokemonHackCore

final class SourceIndexTests: XCTestCase {
    func testTableParserHandlesBracketedNestedAndMacroEntries() throws {
        let descriptor = CInitializerTableDescriptor(
            module: .pokemon,
            relativePath: "src/data/pokemon/species_info.h",
            tableSymbol: "gSpeciesInfo",
            entryStyle: .bracketed
        )
        let text = """
        const struct SpeciesInfo gSpeciesInfo[] =
        {
            [SPECIES_TREECKO] =
            {
                .baseHP = 40,
                .types = { TYPE_GRASS, TYPE_GRASS },
                .abilities = { ABILITY_OVERGROW, ABILITY_NONE },
            },
            [SPECIES_OLD_UNOWN] = OLD_UNOWN_SPECIES_INFO,
        };
        """

        let result = CInitializerParser.tableEntries(in: text, descriptor: descriptor)

        XCTAssertEqual(result.entries.map(\.symbol), ["SPECIES_TREECKO", "SPECIES_OLD_UNOWN"])
        XCTAssertEqual(result.entries.first?.fields["baseHP"], "40")
        XCTAssertEqual(result.entries.first?.fields["types"], "{ TYPE_GRASS, TYPE_GRASS }")
        XCTAssertTrue(result.entries[1].body.contains("OLD_UNOWN_SPECIES_INFO"))
        XCTAssertTrue(result.diagnostics.isEmpty)
    }

    func testTableParserHandlesPositionalEntriesAndMissingIDFieldDiagnostics() throws {
        let descriptor = CInitializerTableDescriptor(
            module: .items,
            relativePath: "src/data/items.h",
            tableSymbol: "gItems",
            entryStyle: .positional,
            idField: "itemId"
        )
        let text = """
        const struct Item gItems[] = {
            {
                .name = _("POTION"),
                .itemId = ITEM_POTION,
                .price = 300,
            }, {
                .name = _("BROKEN"),
                .price = 10,
            },
        };
        """

        let result = CInitializerParser.tableEntries(in: text, descriptor: descriptor)
        let records = result.entries.map { entry in
            SourceIndexRecord(
                id: entry.symbol,
                module: .items,
                title: entry.fields["itemId"] ?? entry.symbol,
                subtitle: descriptor.relativePath,
                sourceSpan: entry.span,
                diagnostics: entry.fields["itemId"] == nil ? [
                    Diagnostic(
                        severity: .warning,
                        code: "TABLE_ENTRY_ID_MISSING",
                        message: "Missing itemId",
                        span: entry.span
                    )
                ] : []
            )
        }

        XCTAssertEqual(result.entries.map(\.symbol), ["ITEM_POTION", "gItems[1]"])
        XCTAssertEqual(result.entries.first?.ordinal, 0)
        XCTAssertEqual(result.entries.first?.fields["price"], "300")
        XCTAssertEqual(records.last?.diagnostics.first?.code, "TABLE_ENTRY_ID_MISSING")
    }

    func testScriptAndTextIndexesExposeLabelsSpansAndDiagnostics() throws {
        let temp = try SourceIndexTemporaryDirectory()
        let root = temp.url
        try write("POKEMON EMER\n", to: root.appendingPathComponent("Makefile"))
        try makeDirectory(root.appendingPathComponent("include"))
        try makeDirectory(root.appendingPathComponent("graphics"))
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try write(
            """
            const struct SpeciesInfo gSpeciesInfo[] =
            {
                [SPECIES_TREECKO] = { .baseHP = 40 },
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/species_info.h")
        )
        try write(
            """
            const struct Trainer gTrainers[] = {
                [TRAINER_TEST] = { .trainerName = _("TEST"), .party = NO_ITEM_DEFAULT_MOVES(sParty_Test) },
            };
            """,
            to: root.appendingPathComponent("src/data/trainers.h")
        )
        try write(
            """
            const struct Item gItems[] =
            {
                [ITEM_POTION] = { .name = _("POTION"), .itemId = ITEM_POTION, .price = 300 },
            };
            """,
            to: root.appendingPathComponent("src/data/items.h")
        )
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
                .string "This line is intentionally far too long for the Gen III textbox diagnostic threshold$"
            """,
            to: root.appendingPathComponent("data/text/test.inc")
        )

        let projectIndex = try GameAdapterRegistry.index(path: root.path)
        let sourceIndex = try ProjectSourceIndexLoader.load(from: projectIndex)

        XCTAssertTrue(sourceIndex.records.contains { $0.module == .scripts && $0.title == "Test_EventScript" })
        XCTAssertTrue(sourceIndex.records.contains { $0.module == .text && $0.title == "gText_Test" })
        XCTAssertTrue(sourceIndex.records.contains { $0.module == .pokemon && $0.title == "SPECIES_TREECKO" })
        XCTAssertTrue(sourceIndex.diagnostics.contains { $0.code == "TEXT_LINE_LONG" })
    }

    func testProjectScriptOutlineReusesMapScriptLabelsForCommandsTextAndSpans() throws {
        let temp = try SourceIndexTemporaryDirectory()
        let root = temp.url
        try write("POKEMON EMER\n", to: root.appendingPathComponent("Makefile"))
        try makeDirectory(root.appendingPathComponent("include"))
        try makeDirectory(root.appendingPathComponent("graphics"))
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try write("const struct SpeciesInfo gSpeciesInfo[] = { [SPECIES_TREECKO] = { .baseHP = 40 }, };\n", to: root.appendingPathComponent("src/data/pokemon/species_info.h"))
        try write("const struct Trainer gTrainers[] = { [TRAINER_TEST] = { .trainerName = _(\"TEST\") }, };\n", to: root.appendingPathComponent("src/data/trainers.h"))
        try write("const struct Item gItems[] = { [ITEM_POTION] = { .name = _(\"POTION\"), .itemId = ITEM_POTION }, };\n", to: root.appendingPathComponent("src/data/items.h"))
        try write(
            """
            Test_EventScript::
                lock
                msgbox gText_Test
                release
                end

            SingleColonLabel:
                setflag FLAG_TEST
                return
            """,
            to: root.appendingPathComponent("data/scripts/test.inc")
        )
        try write(
            """
            MapLocalScript::
                message gText_Test
                end
            """,
            to: root.appendingPathComponent("data/maps/PetalburgCity/scripts.inc")
        )
        try write(
            """
            gText_Test::
                .string "This text intentionally lacks a terminator"
            """,
            to: root.appendingPathComponent("data/text/test.inc")
        )
        try write(
            """
            GeneratedEventScript::
                end
            """,
            to: root.appendingPathComponent("data/maps/PetalburgCity/events.inc")
        )

        let projectIndex = try GameAdapterRegistry.index(path: root.path)
        let outline = try ProjectScriptOutlineLoader.load(from: projectIndex)

        let script = try XCTUnwrap(outline.labels.first { $0.label == "Test_EventScript" })
        XCTAssertEqual(script.commands.map(\.name), ["lock", "msgbox", "release", "end"])
        XCTAssertEqual(script.commands.first { $0.name == "msgbox" }?.arguments, "gText_Test")
        XCTAssertEqual(script.textReferences, ["gText_Test"])
        XCTAssertEqual(script.sourceSpan.relativePath, "data/scripts/test.inc")
        XCTAssertEqual(script.sourceSpan.startLine, 1)

        XCTAssertTrue(outline.labels.contains { $0.label == "SingleColonLabel" })
        XCTAssertTrue(outline.labels.contains { $0.label == "MapLocalScript" && $0.sourceRole == .mapLocal })
        XCTAssertFalse(outline.labels.contains { $0.label == "GeneratedEventScript" })
        XCTAssertTrue(outline.textBlocks.contains { $0.label == "gText_Test" })
        XCTAssertTrue(outline.diagnostics.contains { $0.code == "TEXT_TERMINATOR_MISSING" })
    }

    func testFireRedItemJSONFallbackIndexesItemsWithoutDescriptorWarning() throws {
        let temp = try SourceIndexTemporaryDirectory()
        let root = temp.url
        try write("poke$(BUILD_NAME).gba\n", to: root.appendingPathComponent("Makefile"))
        try makeDirectory(root.appendingPathComponent("include"))
        try makeDirectory(root.appendingPathComponent("graphics/quest_log"))
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try write("const struct SpeciesInfo gSpeciesInfo[] = { [SPECIES_BULBASAUR] = { .baseHP = 45 }, };\n", to: root.appendingPathComponent("src/data/pokemon/species_info.h"))
        try write("const struct Trainer gTrainers[] = { [TRAINER_TEST] = { .trainerName = _(\"TEST\") }, };\n", to: root.appendingPathComponent("src/data/trainers.h"))
        try write("const struct BattleMove gBattleMoves[] = { [MOVE_POUND] = { .power = 40 }, };\n", to: root.appendingPathComponent("src/data/battle_moves.h"))
        try write("const u16 *const gLevelUpLearnsets[NUM_SPECIES] = { [SPECIES_BULBASAUR] = sBulbasaurLevelUpLearnset, };\n", to: root.appendingPathComponent("src/data/pokemon/level_up_learnset_pointers.h"))
        try write("const union { u32 as_u32s[2]; } sTMHMLearnsets[NUM_SPECIES] = { [SPECIES_BULBASAUR] = { .as_u32s = {1, 0} }, };\n", to: root.appendingPathComponent("src/data/pokemon/tmhm_learnsets.h"))
        try write("const struct Evolution gEvolutionTable[NUM_SPECIES][EVOS_PER_MON] = { [SPECIES_BULBASAUR] = {{EVO_LEVEL, 16, SPECIES_IVYSAUR}}, };\n", to: root.appendingPathComponent("src/data/pokemon/evolution.h"))
        try write("const struct PokedexEntry gPokedexEntries[] = { { .categoryName = _(\"SEED\"), .height = 7, .weight = 69 }, };\n", to: root.appendingPathComponent("src/data/pokemon/pokedex_entries.h"))
        try write(
            """
            {
              "items": [
                {
                  "itemId": "ITEM_POTION",
                  "english": "POTION",
                  "price": 300,
                  "pocket": "POCKET_ITEMS",
                  "type": "ITEM_USE_PARTY_MENU"
                }
              ]
            }
            """,
            to: root.appendingPathComponent("src/data/items.json")
        )

        let projectIndex = try GameAdapterRegistry.index(path: root.path)
        let sourceIndex = try ProjectSourceIndexLoader.load(from: projectIndex)

        XCTAssertEqual(projectIndex.profile, .pokefirered)
        let item = try XCTUnwrap(sourceIndex.records.first { $0.module == .items && $0.title == "ITEM_POTION" })
        XCTAssertEqual(item.sourceSpan.relativePath, "src/data/items.json")
        XCTAssertTrue(item.tags.contains("json"))
        XCTAssertTrue(item.facts.contains { $0.label == "price" && $0.value == "300" })
        XCTAssertFalse(sourceIndex.diagnostics.contains { $0.code == "SOURCE_INDEX_DESCRIPTOR_MISSING" && $0.span?.relativePath == "src/data/items.h" })
    }

    func testExpansionMovedDataShapesIndexWithoutRequiredDescriptorWarnings() throws {
        let partyText = """
        === TRAINER_TREECKO ===
        Name: TREECKO
        Class: Rival

        Treecko
        Level: 5
        """

        let temp = try SourceIndexTemporaryDirectory()
        let root = temp.url
        try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
        try makeDirectory(root.appendingPathComponent("graphics"))
        try write("#define EXPANSION_VERSION 1\n", to: root.appendingPathComponent("include/constants/expansion.h"))
        try write("// RHH\n", to: root.appendingPathComponent("src/rom_header_rhh.c"))
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try write("const struct SpeciesInfo gSpeciesInfo[] = { [SPECIES_TREECKO] = { .baseHP = 40 }, };\n", to: root.appendingPathComponent("src/data/pokemon/species_info.h"))
        try write("const struct ItemInfo gItemsInfo[] = { [ITEM_POTION] = { .name = _(\"POTION\"), .price = 300 }, };\n", to: root.appendingPathComponent("src/data/items.h"))
        try write("const struct MoveInfo gMovesInfo[] = { [MOVE_POUND] = { .power = 40, .type = TYPE_NORMAL, .pp = 35 }, };\n", to: root.appendingPathComponent("src/data/moves_info.h"))
        try write(
            """
            static const struct LevelUpMove sTreeckoLevelUpLearnset[] = {
                LEVEL_UP_MOVE(1, MOVE_POUND),
                LEVEL_UP_MOVE(6, MOVE_ABSORB),
                LEVEL_UP_MOVE_END
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/level_up_learnsets/gen_3.h")
        )
        try write(
            """
            {
              "TREECKO": ["MOVE_POUND", "MOVE_ABSORB"]
            }
            """,
            to: root.appendingPathComponent("src/data/pokemon/all_learnables.json")
        )
        try write(
            """
            [SPECIES_TREECKO] =
            {
                .categoryName = _("WOOD GECKO"),
                .height = 5,
                .weight = 50,
                .description = COMPOUND_STRING("It quickly scales even vertical walls."),
                .evolutions = EVOLUTION({EVO_LEVEL, 16, SPECIES_GROVYLE}),
            },
            """,
            to: root.appendingPathComponent("src/data/pokemon/species_info/gen_3_families.h")
        )
        try write(partyText, to: root.appendingPathComponent("src/data/trainers.party"))

        let projectIndex = try GameAdapterRegistry.index(path: root.path)
        let sourceIndex = try ProjectSourceIndexLoader.load(from: projectIndex)

        XCTAssertEqual(projectIndex.profile, .pokeemeraldExpansion)
        XCTAssertTrue(sourceIndex.records.contains { $0.module == .pokemon && $0.title == "SPECIES_TREECKO" && $0.sourceSpan.relativePath == "src/data/pokemon/species_info.h" })
        XCTAssertTrue(sourceIndex.records.contains { $0.module == .items && $0.title == "ITEM_POTION" && $0.sourceSpan.relativePath == "src/data/items.h" })
        XCTAssertTrue(sourceIndex.records.contains { $0.module == .moves && $0.title == "MOVE_POUND" && $0.sourceSpan.relativePath == "src/data/moves_info.h" })
        XCTAssertTrue(sourceIndex.records.contains { $0.module == .learnsets && $0.title == "SPECIES_TREECKO" && $0.sourceSpan.relativePath == "src/data/pokemon/level_up_learnsets/gen_3.h" })
        XCTAssertTrue(sourceIndex.records.contains { $0.module == .learnsets && $0.title == "SPECIES_TREECKO" && $0.sourceSpan.relativePath == "src/data/pokemon/all_learnables.json" })
        XCTAssertTrue(sourceIndex.records.contains { $0.module == .evolutions && $0.title == "SPECIES_TREECKO" && $0.sourceSpan.relativePath == "src/data/pokemon/species_info/gen_3_families.h" })
        XCTAssertTrue(sourceIndex.records.contains { $0.module == .pokedex && $0.title == "SPECIES_TREECKO" && $0.sourceSpan.relativePath == "src/data/pokemon/species_info/gen_3_families.h" })
        XCTAssertTrue(sourceIndex.records.contains { $0.module == .trainers && $0.title == "TRAINER_TREECKO" && $0.sourceSpan.relativePath == "src/data/trainers.party" })
        XCTAssertFalse(sourceIndex.diagnostics.contains { $0.code == "SOURCE_INDEX_DESCRIPTOR_MISSING" })
    }

    func testExpansionTrainerPartyBlocksBecomeTrainerRecords() throws {
        let partyText = """
        === TRAINER_TEST ===
        Name: TEST
        Class: Hiker

        Geodude
        Level: 12

        === TRAINER_EMPTY ===
        Name: EMPTY
        Class: Pkmn Trainer
        """

        let temp = try SourceIndexTemporaryDirectory()
        let root = temp.url
        try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
        try makeDirectory(root.appendingPathComponent("graphics"))
        try write("#define EXPANSION_VERSION 1\n", to: root.appendingPathComponent("include/constants/expansion.h"))
        try write("// RHH\n", to: root.appendingPathComponent("src/rom_header_rhh.c"))
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try write("const struct SpeciesInfo gSpeciesInfo[] = { [SPECIES_NONE] = {0}, };\n", to: root.appendingPathComponent("src/data/pokemon/species_info.h"))
        try write("const struct Trainer gTrainers[] = { [TRAINER_NONE] = {0}, };\n", to: root.appendingPathComponent("src/data/trainers.h"))
        try write("const struct Item gItems[] = { [ITEM_NONE] = {0}, };\n", to: root.appendingPathComponent("src/data/items.h"))
        try write(partyText, to: root.appendingPathComponent("src/data/trainers.party"))

        let projectIndex = try GameAdapterRegistry.index(path: root.path)
        let sourceIndex = try ProjectSourceIndexLoader.load(from: projectIndex)

        let partyRecords = sourceIndex.records.filter { $0.module == .trainers && $0.sourceSpan.relativePath == "src/data/trainers.party" }
        XCTAssertEqual(partyRecords.map(\.title), ["TRAINER_TEST", "TRAINER_EMPTY"])
        XCTAssertEqual(partyRecords.first?.facts.first { $0.label == "Party Mons" }?.value, "1")
    }

    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func makeDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
}

private final class SourceIndexTemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackSourceIndexTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
