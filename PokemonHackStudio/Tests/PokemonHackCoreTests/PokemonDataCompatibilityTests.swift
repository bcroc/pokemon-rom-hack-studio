import XCTest
@testable import PokemonHackCore

final class PokemonDataCompatibilityTests: XCTestCase {
    func testClassicEmeraldReportMarksPokemonMovesLearnsetsAndItemsEditable() throws {
        let root = try temporaryRoot()
        try makeClassicProject(at: root, profile: .pokeemerald)

        let report = try PokemonDataCompatibilityReportBuilder.build(path: root.path)

        XCTAssertEqual(entry(.species, in: report).status, .editable)
        XCTAssertEqual(entry(.moves, in: report).status, .editable)
        XCTAssertEqual(entry(.levelUpLearnsets, in: report).status, .editable)
        XCTAssertEqual(entry(.tmhmLearnsets, in: report).status, .editable)
        XCTAssertEqual(entry(.eggMoves, in: report).status, .editable)
        let items = entry(.items, in: report)
        XCTAssertEqual(items.status, .editable)
        XCTAssertEqual(items.sourcePath, "src/data/items.h")
        XCTAssertEqual(items.tableSymbol, "gItems")
        XCTAssertEqual(items.editableCount, 1)
        XCTAssertTrue(items.unsupportedFields.contains("description text rewrites"))
    }

    func testClassicFireRedReportMarksPokemonAndMovesEditableButItemsReadOnly() throws {
        let root = try temporaryRoot()
        try makeClassicProject(at: root, profile: .pokefirered)

        let report = try PokemonDataCompatibilityReportBuilder.build(path: root.path)

        XCTAssertEqual(entry(.species, in: report).status, .editable)
        XCTAssertEqual(entry(.moves, in: report).status, .editable)
        XCTAssertEqual(entry(.levelUpLearnsets, in: report).status, .editable)
        XCTAssertEqual(entry(.tmhmLearnsets, in: report).status, .editable)
        let items = entry(.items, in: report)
        XCTAssertEqual(items.status, .readOnly)
        XCTAssertEqual(items.sourcePath, "src/data/items.json")
        XCTAssertEqual(items.tableSymbol, "items")
        XCTAssertEqual(items.indexedCount, 1)
        XCTAssertEqual(items.editableCount, 0)
        XCTAssertTrue(items.blockedReason?.contains("FireRed item data") == true)
        XCTAssertTrue(items.unsupportedFields.contains("FireRed JSON item rewrites"))
        XCTAssertEqual(items.recommendedFutureRow, "PHS-T50")
    }

    func testRubyAndExpansionItemsReportReadOnlyBlockedShapes() throws {
        let ruby = try PokemonDataCompatibilityReportBuilder.build(
            index: projectIndex(profile: .pokeruby),
            sourceIndex: sourceIndex(profile: .pokeruby, itemPath: "src/data/items_en.h")
        )
        let expansion = try PokemonDataCompatibilityReportBuilder.build(
            index: projectIndex(profile: .pokeemeraldExpansion),
            sourceIndex: sourceIndex(profile: .pokeemeraldExpansion, itemPath: "src/data/items.h")
        )

        let rubyItems = entry(.items, in: ruby)
        XCTAssertEqual(rubyItems.status, .readOnly)
        XCTAssertEqual(rubyItems.sourcePath, "src/data/items_en.h")
        XCTAssertEqual(rubyItems.tableSymbol, "gItems")
        XCTAssertTrue(rubyItems.blockedReason?.contains("Ruby/Sapphire positional") == true)
        XCTAssertTrue(rubyItems.unsupportedFields.contains("Ruby/Sapphire positional gItems rewrites"))

        let expansionItems = entry(.items, in: expansion)
        XCTAssertEqual(expansionItems.status, .readOnly)
        XCTAssertEqual(expansionItems.sourcePath, "src/data/items.h")
        XCTAssertEqual(expansionItems.tableSymbol, "gItemsInfo")
        XCTAssertTrue(expansionItems.blockedReason?.contains("Expansion ItemInfo") == true)
        XCTAssertTrue(expansionItems.unsupportedFields.contains("Expansion ItemInfo rewrites"))
    }

    private func entry(
        _ surface: PokemonDataCompatibilitySurface,
        in report: PokemonDataCompatibilityReport,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> PokemonDataCompatibilityEntry {
        guard let entry = report.entries.first(where: { $0.surface == surface }) else {
            XCTFail("Missing compatibility entry for \(surface.rawValue)", file: file, line: line)
            return PokemonDataCompatibilityEntry(surface: surface, status: .blocked, adapterID: "", adapterName: "", profile: .unknown)
        }
        return entry
    }

    private func makeClassicProject(at root: URL, profile: GameProfile) throws {
        switch profile {
        case .pokeemerald:
            try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
        case .pokefirered:
            try write("poke$(BUILD_NAME).gba\n", to: root.appendingPathComponent("Makefile"))
            try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/quest_log"), withIntermediateDirectories: true)
        default:
            XCTFail("Unsupported classic fixture profile")
        }

        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try write(Data([0x89, 0x50, 0x4E, 0x47]), to: root.appendingPathComponent("graphics/pokemon/treecko/front.png"))
        try writeClassicPokemonSources(at: root, profile: profile)
        try writeBattleMoves(at: root)
        try writeItems(at: root, profile: profile)
    }

    private func writeClassicPokemonSources(at root: URL, profile: GameProfile) throws {
        try write(
            """
            const struct SpeciesInfo gSpeciesInfo[] =
            {
                [SPECIES_TREECKO] =
                {
                    .baseHP = 40,
                    .baseAttack = 45,
                    .baseDefense = 35,
                    .baseSpeed = 70,
                    .baseSpAttack = 65,
                    .baseSpDefense = 55,
                    .types = { TYPE_GRASS, TYPE_GRASS },
                    .abilities = { ABILITY_OVERGROW, ABILITY_NONE },
                    .growthRate = GROWTH_MEDIUM_SLOW,
                    .eggGroups = { EGG_GROUP_MONSTER, EGG_GROUP_DRAGON },
                },
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/species_info.h")
        )
        try write(
            """
            static const u16 sTreeckoLevelUpLearnset[] = {
                LEVEL_UP_MOVE(1, MOVE_POUND),
                LEVEL_UP_END
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/level_up_learnsets.h")
        )
        try write(
            """
            const u16 *const gLevelUpLearnsets[] =
            {
                [SPECIES_TREECKO] = sTreeckoLevelUpLearnset,
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/level_up_learnset_pointers.h")
        )
        let tmhmBody = profile == .pokefirered
            ? "[SPECIES_TREECKO] = TMHM_LEARNSET(TMHM(TM09_BULLET_SEED)),"
            : "[SPECIES_TREECKO] = { .learnset = { .BULLET_SEED = TRUE } },"
        let tmhmSymbol = profile == .pokefirered ? "sTMHMLearnsets" : "gTMHMLearnsets"
        try write(
            """
            static const u32 \(tmhmSymbol)[] =
            {
                \(tmhmBody)
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/tmhm_learnsets.h")
        )
        try write(
            """
            const u16 gEggMoves[] = {
                egg_moves(TREECKO, MOVE_CRUNCH),
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/egg_moves.h")
        )
        try write(
            """
            const struct Evolution gEvolutionTable[NUM_SPECIES][EVOS_PER_MON] =
            {
                [SPECIES_TREECKO] = {{EVO_LEVEL, 16, SPECIES_GROVYLE}},
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/evolution.h")
        )
        try write(
            """
            const struct PokedexEntry gPokedexEntries[] =
            {
                [NATIONAL_DEX_TREECKO] = { .categoryName = _(\"WOOD GECKO\"), .height = 5, .weight = 50 },
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/pokedex_entries.h")
        )
        try write(
            """
            #define MOVE_POUND 1
            #define MOVE_CRUNCH 2
            #define MOVE_BULLET_SEED 3
            """,
            to: root.appendingPathComponent("include/constants/moves.h")
        )
        try write("#define ITEM_TM09_BULLET_SEED ITEM_TM09\n", to: root.appendingPathComponent("include/constants/items.h"))
    }

    private func writeBattleMoves(at root: URL) throws {
        try write(
            """
            static const struct BattleMove gBattleMoves[] =
            {
                [MOVE_POUND] =
                {
                    .effect = EFFECT_HIT,
                    .power = 40,
                    .type = TYPE_NORMAL,
                    .accuracy = 100,
                    .pp = 35,
                    .secondaryEffectChance = 0,
                    .target = MOVE_TARGET_SELECTED,
                    .priority = 0,
                    .flags = FLAG_MAKES_CONTACT,
                },
            };
            """,
            to: root.appendingPathComponent("src/data/battle_moves.h")
        )
    }

    private func writeItems(at root: URL, profile: GameProfile) throws {
        if profile == .pokefirered {
            try write(
                """
                {"items":[{"itemId":"ITEM_POTION","english":"POTION","price":300,"pocket":"POCKET_ITEMS","type":"ITEM_USE_PARTY_MENU"}]}
                """,
                to: root.appendingPathComponent("src/data/items.json")
            )
            return
        }
        try write(
            """
            const struct Item gItems[] =
            {
                [ITEM_POTION] =
                {
                    .name = _(\"POTION\"),
                    .itemId = ITEM_POTION,
                    .price = 300,
                    .holdEffect = HOLD_EFFECT_NONE,
                    .holdEffectParam = 0,
                    .description = sPotionDesc,
                    .pocket = POCKET_ITEMS,
                    .type = ITEM_USE_PARTY_MENU,
                    .fieldUseFunc = ItemUseOutOfBattle_Medicine,
                    .battleUsage = ITEM_B_USE_MEDICINE,
                    .battleUseFunc = ItemUseInBattle_Medicine,
                    .secondaryId = 0,
                },
            };
            """,
            to: root.appendingPathComponent("src/data/items.h")
        )
    }

    private func projectIndex(profile: GameProfile) throws -> ProjectIndex {
        let root = try temporaryRoot()
        return ProjectIndex(
            root: SourceLocation(path: root.path, exists: true),
            profile: profile,
            adapterID: "test.\(profile.rawValue)",
            adapterName: "\(profile.rawValue) Fixture",
            editorModules: [.pokemon, .moves, .items],
            capabilities: [.diagnostics],
            writePolicy: .mutationPlanOnly,
            documents: []
        )
    }

    private func sourceIndex(profile: GameProfile, itemPath: String) throws -> ProjectSourceIndex {
        let root = try temporaryRoot()
        return ProjectSourceIndex(
            root: SourceLocation(path: root.path, exists: true),
            profile: profile,
            adapterID: "test.\(profile.rawValue)",
            adapterName: "\(profile.rawValue) Fixture",
            records: [
                SourceIndexRecord(
                    id: "items:\(profile.rawValue):ITEM_POTION",
                    module: .items,
                    title: "ITEM_POTION",
                    subtitle: itemPath,
                    sourceSpan: SourceSpan(relativePath: itemPath, startLine: 1),
                    facts: [
                        SourceIndexFact(label: "name", value: "_(\"POTION\")"),
                        SourceIndexFact(label: "price", value: "300"),
                        SourceIndexFact(label: "pocket", value: "POCKET_ITEMS"),
                        SourceIndexFact(label: "type", value: "ITEM_USE_PARTY_MENU")
                    ],
                    preview: "ITEM_POTION"
                )
            ]
        )
    }

    private func temporaryRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonDataCompatibilityTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: root)
        }
        return root
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
