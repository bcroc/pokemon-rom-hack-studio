import XCTest
@testable import PokemonHackCore

final class PokemonDataCompatibilityTests: XCTestCase {
    func testClassicEmeraldReportMarksPokemonMovesLearnsetsAndItemsEditable() throws {
        let root = try temporaryRoot()
        try makeClassicProject(at: root, profile: .pokeemerald)

        let report = try PokemonDataCompatibilityReportBuilder.build(path: root.path)

        assertNoCompletedRowRecommendations(in: report)
        XCTAssertEqual(entry(.species, in: report).status, .editable)
        XCTAssertEqual(entry(.moves, in: report).status, .editable)
        XCTAssertFalse(entry(.species, in: report).unsupportedFields.contains("pokedex text rewrites"))
        XCTAssertFalse(entry(.moves, in: report).unsupportedFields.contains("TM/HM/tutor compatibility edits"))
        let levelUp = entry(.levelUpLearnsets, in: report)
        let tmhm = entry(.tmhmLearnsets, in: report)
        let eggMoves = entry(.eggMoves, in: report)
        let tutor = entry(.tutorLearnsets, in: report)
        let evolutions = entry(.evolutions, in: report)
        let pokedex = entry(.pokedex, in: report)
        XCTAssertEqual(levelUp.status, .editable)
        XCTAssertNil(levelUp.recommendedFutureRow)
        XCTAssertEqual(tmhm.status, .editable)
        XCTAssertFalse(tmhm.unsupportedFields.contains("compatibility matrix bulk edits"))
        XCTAssertNil(tmhm.recommendedFutureRow)
        XCTAssertEqual(eggMoves.status, .editable)
        XCTAssertNil(eggMoves.recommendedFutureRow)
        XCTAssertEqual(tutor.status, .editable)
        XCTAssertNil(tutor.recommendedFutureRow)
        XCTAssertEqual(evolutions.status, .editable)
        XCTAssertEqual(evolutions.editableCount, 1)
        XCTAssertNil(evolutions.recommendedFutureRow)
        XCTAssertEqual(pokedex.status, .editable)
        XCTAssertEqual(pokedex.editableCount, 1)
        XCTAssertNil(pokedex.recommendedFutureRow)
        let items = entry(.items, in: report)
        XCTAssertEqual(items.status, .editable)
        XCTAssertEqual(items.sourcePath, "src/data/items.h")
        XCTAssertEqual(items.tableSymbol, "gItems")
        XCTAssertEqual(items.editableCount, 1)
        XCTAssertFalse(items.unsupportedFields.contains("description text rewrites"))
    }

    func testClassicFireRedReportMarksPokemonMovesAndItemRowsEditable() throws {
        let root = try temporaryRoot()
        try makeClassicProject(at: root, profile: .pokefirered)

        let report = try PokemonDataCompatibilityReportBuilder.build(path: root.path)

        assertNoCompletedRowRecommendations(in: report)
        XCTAssertEqual(entry(.species, in: report).status, .editable)
        XCTAssertEqual(entry(.moves, in: report).status, .editable)
        XCTAssertFalse(entry(.species, in: report).unsupportedFields.contains("pokedex text rewrites"))
        XCTAssertFalse(entry(.moves, in: report).unsupportedFields.contains("TM/HM/tutor compatibility edits"))
        let levelUp = entry(.levelUpLearnsets, in: report)
        let tmhm = entry(.tmhmLearnsets, in: report)
        let tutor = entry(.tutorLearnsets, in: report)
        let evolutions = entry(.evolutions, in: report)
        let pokedex = entry(.pokedex, in: report)
        XCTAssertEqual(levelUp.status, .editable)
        XCTAssertNil(levelUp.recommendedFutureRow)
        XCTAssertEqual(tmhm.status, .editable)
        XCTAssertFalse(tmhm.unsupportedFields.contains("compatibility matrix bulk edits"))
        XCTAssertNil(tmhm.recommendedFutureRow)
        XCTAssertEqual(tutor.status, .editable)
        XCTAssertNil(tutor.recommendedFutureRow)
        XCTAssertEqual(evolutions.status, .editable)
        XCTAssertNil(evolutions.recommendedFutureRow)
        XCTAssertEqual(pokedex.status, .editable)
        XCTAssertNil(pokedex.recommendedFutureRow)
        let items = entry(.items, in: report)
        XCTAssertEqual(items.status, .editable)
        XCTAssertEqual(items.sourcePath, "src/data/items.h")
        XCTAssertEqual(items.tableSymbol, "gItems")
        XCTAssertEqual(items.indexedCount, 1)
        XCTAssertEqual(items.editableCount, 1)
        XCTAssertNil(items.blockedReason)
        XCTAssertFalse(items.unsupportedFields.contains("FireRed row-field rewrites"))
        XCTAssertTrue(items.unsupportedFields.contains("TM/HM item compatibility edits"))
        XCTAssertFalse(items.unsupportedFields.contains("description text rewrites"))
        XCTAssertNil(items.recommendedFutureRow)
    }

    func testRubyAndExpansionItemsReportEditableSourceBackedRows() throws {
        let rubyRoot = try temporaryRoot()
        try writeRubySpecies(at: rubyRoot)
        try writeRubyItems(at: rubyRoot)
        let ruby = try PokemonDataCompatibilityReportBuilder.build(
            index: projectIndex(root: rubyRoot, profile: .pokeruby),
            sourceIndex: sourceIndex(profile: .pokeruby, itemPath: "src/data/items_en.h")
        )
        let expansionRoot = try temporaryRoot()
        try writeExpansionItems(at: expansionRoot)
        let expansion = try PokemonDataCompatibilityReportBuilder.build(
            index: projectIndex(root: expansionRoot, profile: .pokeemeraldExpansion),
            sourceIndex: sourceIndex(profile: .pokeemeraldExpansion, itemPath: "src/data/items.h")
        )

        assertNoCompletedRowRecommendations(in: ruby)
        assertNoCompletedRowRecommendations(in: expansion)
        let rubySpecies = entry(.species, in: ruby)
        XCTAssertEqual(rubySpecies.status, .editable)
        XCTAssertEqual(rubySpecies.sourcePath, "src/data/pokemon/base_stats.h")
        XCTAssertEqual(rubySpecies.tableSymbol, "gBaseStats")
        XCTAssertEqual(rubySpecies.indexedCount, 1)
        XCTAssertEqual(rubySpecies.editableCount, 1)
        XCTAssertNil(rubySpecies.blockedReason)
        XCTAssertFalse(rubySpecies.unsupportedFields.contains("Ruby/Sapphire base_stats positional apply"))
        XCTAssertTrue(rubySpecies.unsupportedFields.contains("Pokedex rewrites"))
        XCTAssertNil(rubySpecies.recommendedFutureRow)
        let rubyPokedex = entry(.pokedex, in: ruby)
        XCTAssertEqual(rubyPokedex.status, .readOnly)
        XCTAssertEqual(rubyPokedex.sourcePath, "src/data/pokedex_entries_en.h")
        XCTAssertEqual(rubyPokedex.tableSymbol, "gPokedexEntries")
        XCTAssertEqual(rubyPokedex.editableCount, 0)
        XCTAssertTrue(rubyPokedex.unsupportedFields.contains("description text rewrites"))
        let rubyAssets = entry(.assets, in: ruby)
        XCTAssertEqual(rubyAssets.status, .readOnly)
        XCTAssertEqual(rubyAssets.editableCount, 0)

        let rubyItems = entry(.items, in: ruby)
        XCTAssertEqual(rubyItems.status, .editable)
        XCTAssertEqual(rubyItems.sourcePath, "src/data/items_en.h")
        XCTAssertEqual(rubyItems.tableSymbol, "gItems")
        XCTAssertEqual(rubyItems.editableCount, 1)
        XCTAssertNil(rubyItems.blockedReason)
        XCTAssertFalse(rubyItems.unsupportedFields.contains("Ruby/Sapphire positional gItems rewrites"))
        XCTAssertTrue(rubyItems.unsupportedFields.contains("description text rewrites"))
        XCTAssertTrue(rubyItems.unsupportedFields.contains("TM/HM item compatibility edits"))
        XCTAssertNil(rubyItems.recommendedFutureRow)

        let expansionItems = entry(.items, in: expansion)
        XCTAssertEqual(expansionItems.status, .editable)
        XCTAssertEqual(expansionItems.sourcePath, "src/data/items.h")
        XCTAssertEqual(expansionItems.tableSymbol, "gItemsInfo")
        XCTAssertEqual(expansionItems.indexedCount, 1)
        XCTAssertEqual(expansionItems.editableCount, 1)
        XCTAssertNil(expansionItems.blockedReason)
        XCTAssertFalse(expansionItems.unsupportedFields.contains("description text rewrites"))
        XCTAssertTrue(expansionItems.unsupportedFields.contains("non-simple/non-COMPOUND_STRING description rewrites"))
        XCTAssertTrue(expansionItems.unsupportedFields.contains("include/config/item.h rewrites"))
        XCTAssertTrue(expansionItems.unsupportedFields.contains("generated item output writes"))
        XCTAssertTrue(expansionItems.unsupportedFields.contains("reference-only item source writes"))
        XCTAssertTrue(expansionItems.unsupportedFields.contains("Modern Emerald item writers"))
        XCTAssertTrue(expansionItems.unsupportedFields.contains("binary ROM item writes"))
        XCTAssertTrue(expansionItems.unsupportedFields.contains("broad Expansion item schema rewrites"))
        XCTAssertNil(expansionItems.recommendedFutureRow)
        let expansionItemSources = try XCTUnwrap(expansionItems.sourceTables)
        XCTAssertTrue(expansionItemSources.contains { $0.path == "src/data/items.h" && $0.tableSymbol == "gItemsInfo" && $0.status == .editable && $0.indexedCount == 1 })
        XCTAssertTrue(expansionItemSources.contains { $0.path == "src/data/items.h" && ($0.note?.contains("simple inline COMPOUND_STRING descriptions") == true) })
        XCTAssertTrue(expansionItemSources.contains { $0.path == "include/config/item.h" && $0.status == .blocked })
        XCTAssertTrue(expansionItemSources.contains { $0.path == "generated" && $0.status == .blocked })
        XCTAssertTrue(expansionItemSources.contains { $0.path == "references/pokeemerald-expansion/src/data/items.h" && $0.status == .blocked })
    }

    func testExpansionMovesInfoRowsReportEditableWithBlockedAdjacentSourcesAndJSON() throws {
        let root = try temporaryRoot()
        try writeExpansionMovesInfo(at: root)
        let index = projectIndex(root: root, profile: .pokeemeraldExpansion)
        let sourceIndex = try ProjectSourceIndexLoader.load(from: index)
        let expansion = try PokemonDataCompatibilityReportBuilder.build(
            index: index,
            sourceIndex: sourceIndex
        )

        assertNoCompletedRowRecommendations(in: expansion)
        let moves = entry(.moves, in: expansion)
        XCTAssertEqual(moves.status, .editable)
        XCTAssertEqual(moves.sourcePath, "src/data/moves_info.h")
        XCTAssertEqual(moves.tableSymbol, "gMovesInfo")
        XCTAssertEqual(moves.indexedCount, 1)
        XCTAssertEqual(moves.editableCount, 1)
        XCTAssertNil(moves.blockedReason)
        XCTAssertTrue(moves.unsupportedFields.contains("new/reordered move constants"))
        XCTAssertTrue(moves.unsupportedFields.contains("contest data"))
        XCTAssertTrue(moves.unsupportedFields.contains("description text rewrites"))
        XCTAssertTrue(moves.unsupportedFields.contains("TM/HM/tutor compatibility edits"))
        XCTAssertTrue(moves.unsupportedFields.contains("gMovesInfo non-simple flags expressions"))
        XCTAssertTrue(moves.unsupportedFields.contains("generated move output writes"))
        XCTAssertTrue(moves.unsupportedFields.contains("reference-only move source writes"))
        XCTAssertTrue(moves.unsupportedFields.contains("binary ROM move writes"))
        XCTAssertTrue(moves.unsupportedFields.contains("broad Expansion move schema rewrites"))
        XCTAssertNil(moves.recommendedFutureRow)
        let sourceTables = try XCTUnwrap(moves.sourceTables)
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/moves_info.h" && $0.tableSymbol == "gMovesInfo" && $0.status == .editable && $0.indexedCount == 1 })
        XCTAssertTrue(sourceTables.contains { $0.path == "include/constants/moves.h" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/text/move_descriptions.h" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/contest_moves.h" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/pokemon/tmhm_learnsets.h" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/pokemon/tutor_learnsets.h" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "generated" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "references/pokeemerald-expansion/src/data/moves_info.h" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "ROM output" && $0.status == .blocked })

        let json = String(data: try JSONEncoder().encode(expansion), encoding: .utf8) ?? ""
        XCTAssertTrue(json.contains(#""sourceTables""#))
        XCTAssertTrue(json.contains(#""gMovesInfo""#))
        XCTAssertTrue(json.contains(#""generated""#))
        XCTAssertTrue(json.contains(#""references\/pokeemerald-expansion\/src\/data\/moves_info.h""#))
    }

    func testExpansionSpeciesRowsReportEditableWithBlockedAdjacentSourcesAndJSON() throws {
        let root = try temporaryRoot()
        try writeExpansionSpecies(at: root)
        let index = projectIndex(root: root, profile: .pokeemeraldExpansion)
        let sourceIndex = try ProjectSourceIndexLoader.load(from: index)
        let expansion = try PokemonDataCompatibilityReportBuilder.build(
            index: index,
            sourceIndex: sourceIndex
        )

        assertNoCompletedRowRecommendations(in: expansion)
        let species = entry(.species, in: expansion)
        XCTAssertEqual(species.status, .editable)
        XCTAssertEqual(species.sourcePath, "src/data/pokemon/species_info.h")
        XCTAssertEqual(species.tableSymbol, "gSpeciesInfo")
        XCTAssertEqual(species.indexedCount, 1)
        XCTAssertEqual(species.editableCount, 1)
        XCTAssertNil(species.blockedReason)
        XCTAssertNil(species.recommendedFutureRow)
        XCTAssertTrue(species.unsupportedFields.contains("type/ability/egg group brace-list rewrites"))
        XCTAssertTrue(species.unsupportedFields.contains("learnset rewrites"))
        XCTAssertTrue(species.unsupportedFields.contains("TM/HM/tutor/egg move rewrites"))
        XCTAssertTrue(species.unsupportedFields.contains("evolution rewrites"))
        XCTAssertTrue(species.unsupportedFields.contains("Pokedex rewrites"))
        XCTAssertTrue(species.unsupportedFields.contains("Pokedex text rewrites"))
        XCTAssertTrue(species.unsupportedFields.contains("species asset/cries/form rewrites"))
        XCTAssertTrue(species.unsupportedFields.contains("generated species family supplement apply"))
        XCTAssertTrue(species.unsupportedFields.contains("reference-only species source writes"))
        XCTAssertTrue(species.unsupportedFields.contains("Modern Emerald species writers"))
        XCTAssertTrue(species.unsupportedFields.contains("binary ROM species writes"))
        let sourceTables = try XCTUnwrap(species.sourceTables)
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/pokemon/species_info.h" && $0.tableSymbol == "gSpeciesInfo" && $0.status == .editable && $0.indexedCount == 1 })
        XCTAssertTrue(sourceTables.contains { $0.path == "include/config/species_enabled.h" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "include/config/pokemon.h" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/pokemon/species_info/" && $0.status == .blocked && $0.indexedCount == 1 })
        XCTAssertTrue(sourceTables.contains { $0.path == "generated" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "references/pokeemerald-expansion/src/data/pokemon/species_info.h" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "Modern Emerald species surfaces" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "ROM output" && $0.status == .blocked })

        let forms = entry(.forms, in: expansion)
        XCTAssertEqual(forms.status, .readOnly)
        XCTAssertEqual(forms.recommendedFutureRow, "PHS-T57E")
        let formSources = try XCTUnwrap(forms.sourceTables)
        XCTAssertTrue(formSources.contains { $0.path == "src/data/pokemon/species_info/" && $0.indexedCount == 1 && $0.status == .readOnly })

        let json = String(data: try JSONEncoder().encode(expansion), encoding: .utf8) ?? ""
        XCTAssertTrue(json.contains(#""sourceTables""#))
        XCTAssertTrue(json.contains(#""gSpeciesInfo""#))
        XCTAssertTrue(json.contains(#""include\/config\/species_enabled.h""#))
        XCTAssertTrue(json.contains(#""references\/pokeemerald-expansion\/src\/data\/pokemon\/species_info.h""#))
        XCTAssertTrue(json.contains(#""Modern Emerald species surfaces""#))
    }

    func testAssetAndCryReadOnlyEntriesPointToLiveCompatibilityRow() throws {
        let report = try PokemonDataCompatibilityReportBuilder.build(
            index: projectIndex(profile: .pokeemerald),
            sourceIndex: sourceIndex(profile: .pokeemerald, itemPath: "src/data/items.h")
        )

        let assets = entry(.assets, in: report)
        XCTAssertEqual(assets.recommendedFutureRow, "PHS-T57")

        let cries = entry(.cries, in: report)
        XCTAssertNil(cries.recommendedFutureRow)
        XCTAssertEqual(cries.status, .blocked)
        XCTAssertEqual(cries.cryAudioPlan?.status, .blocked)
        XCTAssertTrue(cries.cryAudioPlan?.blockedActions.contains("Generated audio output writes") == true)
    }

    func testCryAudioCompatibilityReportsSourceBackedPreviewOnlyPlan() throws {
        let root = try temporaryRoot()
        try write(Data([0x01, 0x02, 0x03, 0x04]), to: root.appendingPathComponent("sound/direct_sound_samples/cries/treecko.aif"))
        try write("cry song\n", to: root.appendingPathComponent("sound/songs/mus_cry_treecko.s"))

        let report = try PokemonDataCompatibilityReportBuilder.build(
            index: projectIndex(root: root, profile: .pokeemerald),
            sourceIndex: sourceIndex(profile: .pokeemerald, itemPath: "src/data/items.h")
        )

        let cries = entry(.cries, in: report)
        XCTAssertEqual(cries.status, .readOnly)
        XCTAssertEqual(cries.indexedCount, 2)
        XCTAssertEqual(cries.editableCount, 0)
        XCTAssertNil(cries.recommendedFutureRow)
        XCTAssertNil(cries.blockedReason)
        let plan = try XCTUnwrap(cries.cryAudioPlan)
        XCTAssertEqual(plan.status, .previewOnly)
        XCTAssertEqual(plan.sourceFiles.map(\.path), [
            "sound/direct_sound_samples/cries/treecko.aif",
            "sound/songs/mus_cry_treecko.s"
        ])
        XCTAssertTrue(plan.sourceFiles.allSatisfy { !$0.sha1.isEmpty && $0.sizeBytes > 0 })
        XCTAssertTrue(plan.plannedChanges.contains("Keep generated audio artifacts and ROM output unchanged."))
        XCTAssertTrue(plan.blockedActions.contains("Audio conversion"))
        XCTAssertTrue(plan.blockedActions.contains("Mutation apply"))
        XCTAssertTrue(cries.diagnostics.contains { $0.code == "GBA_CRY_AUDIO_PLAN_PREVIEW_ONLY" })
    }

    func testFormsCompatibilityReportsSourceGraphWhileBlockingMutationWorkflows() throws {
        let report = try PokemonDataCompatibilityReportBuilder.build(
            index: projectIndex(profile: .pokeemeraldExpansion),
            sourceIndex: formSourceIndex(profile: .pokeemeraldExpansion)
        )

        let forms = entry(.forms, in: report)
        XCTAssertEqual(forms.status, .readOnly)
        XCTAssertEqual(forms.sourcePath, "src/data/pokemon/form_species_tables.h")
        XCTAssertEqual(forms.tableSymbol, "FormSpeciesIdTable/FormChangeTable")
        XCTAssertEqual(forms.indexedCount, 3)
        XCTAssertEqual(forms.editableCount, 0)
        XCTAssertEqual(forms.readOnlyCount, 3)
        XCTAssertEqual(forms.recommendedFutureRow, "PHS-T57E")
        XCTAssertTrue(forms.blockedReason?.contains("diagnostics only") == true)
        XCTAssertTrue(forms.unsupportedFields.contains("form editing"))
        XCTAssertTrue(forms.unsupportedFields.contains("form table mutation/apply"))
        XCTAssertTrue(forms.unsupportedFields.contains("form graphics sync"))
        XCTAssertTrue(forms.unsupportedFields.contains("generated family supplement apply"))
        XCTAssertTrue(forms.unsupportedFields.contains("binary-only form table writes"))
        XCTAssertTrue(forms.diagnostics.contains { $0.code == "GBA_FORMS_SOURCE_GRAPH_DETECTED" })
        XCTAssertTrue(forms.diagnostics.contains { $0.code == "GBA_FORMS_MUTATION_WORKFLOW_BLOCKED" })
        let sourceTables = try XCTUnwrap(forms.sourceTables)
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/pokemon/form_species_tables.h" && $0.indexedCount == 1 && $0.status == .readOnly })
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/pokemon/form_change_tables.h" && $0.indexedCount == 1 && $0.status == .readOnly })
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/pokemon/species_info/" && $0.indexedCount == 1 && $0.status == .readOnly })
    }

    private func assertNoCompletedRowRecommendations(
        in report: PokemonDataCompatibilityReport,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let staleRows = report.entries.compactMap(\.recommendedFutureRow).filter { ["PHS-T50", "PHS-T51", "PHS-T64", "PHS-T65", "PHS-T66"].contains($0) }
        XCTAssertTrue(staleRows.isEmpty, "Completed rows should not appear as future guidance: \(staleRows)", file: file, line: line)
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
                    .type1 = TYPE_GRASS,
                    .type2 = TYPE_GRASS,
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
                [NATIONAL_DEX_TREECKO] = { .categoryName = _(\"WOOD GECKO\"), .height = 5, .weight = 50, .description = gTreeckoPokedexText },
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/pokedex_entries.h")
        )
        try write(
            """
            #define TUTOR_FURY_CUTTER 0
            const u16 gTutorLearnsets[] =
            {
                [SPECIES_TREECKO] = TUTOR(FURY_CUTTER),
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/tutor_learnsets.h")
        )
        try write("const u8 gTreeckoPokedexText[] = _(\"Wood gecko.\");\n", to: root.appendingPathComponent("src/data/pokemon/pokedex_text.h"))
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
                const u8 gItemDescription_ITEM_POTION[] = _(\"Restores HP.\");
                const struct Item gItems[] = {
                    {
                        .name = _(\"POTION\"),
                        .itemId = ITEM_POTION,
                        .price = 300,
                        .holdEffect = HOLD_EFFECT_NONE,
                        .holdEffectParam = 20,
                        .description = gItemDescription_ITEM_POTION,
                        .importance = 0,
                        .registrability = 0,
                        .pocket = POCKET_ITEMS,
                        .type = ITEM_TYPE_PARTY_MENU,
                        .fieldUseFunc = FieldUseFunc_Medicine,
                        .battleUsage = 0,
                        .battleUseFunc = NULL,
                        .secondaryId = 0,
                    },
                };
                """,
                to: root.appendingPathComponent("src/data/items.h")
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

    private func writeRubyItems(at root: URL) throws {
        try write(
            """
            const struct Item gItems[] =
            {
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
            to: root.appendingPathComponent("src/data/items_en.h")
        )
    }

    private func writeRubySpecies(at root: URL) throws {
        try write(
            """
            const struct BaseStats gBaseStats[] =
            {
                [SPECIES_TREECKO] =
                {
                    .baseHP = 40,
                    .baseAttack = 45,
                    .baseDefense = 35,
                    .baseSpeed = 70,
                    .baseSpAttack = 65,
                    .baseSpDefense = 55,
                    .type1 = TYPE_GRASS,
                    .type2 = TYPE_GRASS,
                    .catchRate = 45,
                    .expYield = 65,
                    .evYield_HP = 0,
                    .evYield_Attack = 0,
                    .evYield_Defense = 0,
                    .evYield_Speed = 1,
                    .evYield_SpAttack = 0,
                    .evYield_SpDefense = 0,
                    .item1 = ITEM_NONE,
                    .item2 = ITEM_NONE,
                    .genderRatio = PERCENT_FEMALE(12.5),
                    .eggCycles = 20,
                    .friendship = 70,
                    .growthRate = GROWTH_MEDIUM_SLOW,
                    .eggGroup1 = EGG_GROUP_MONSTER,
                    .eggGroup2 = EGG_GROUP_DRAGON,
                    .ability1 = ABILITY_OVERGROW,
                    .ability2 = ABILITY_NONE,
                    .safariZoneFleeRate = 0,
                    .bodyColor = BODY_COLOR_GREEN,
                    .noFlip = FALSE,
                },
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/base_stats.h")
        )
        try write(
            """
            const struct PokedexEntry gPokedexEntries[] =
            {
                [NATIONAL_DEX_TREECKO] = { .categoryName = _(\"WOOD GECKO\"), .height = 5, .weight = 50, .description = gTreeckoPokedexText },
            };
            """,
            to: root.appendingPathComponent("src/data/pokedex_entries_en.h")
        )
        try write("const u8 gTreeckoPokedexText[] = _(\"Wood gecko.\");\n", to: root.appendingPathComponent("src/data/pokedex_text_en.h"))
        try write(Data([0x89, 0x50, 0x4E, 0x47]), to: root.appendingPathComponent("graphics/pokemon/treecko/front.png"))
        try write(
            """
            #define TYPE_GRASS 12
            #define EGG_GROUP_MONSTER 1
            #define EGG_GROUP_DRAGON 14
            #define GROWTH_MEDIUM_SLOW 3
            #define BODY_COLOR_GREEN 5
            """,
            to: root.appendingPathComponent("include/constants/pokemon.h")
        )
        try write("#define ABILITY_NONE 0\n#define ABILITY_OVERGROW 65\n", to: root.appendingPathComponent("include/constants/abilities.h"))
        try write("#define ITEM_NONE 0\n", to: root.appendingPathComponent("include/constants/items.h"))
    }

    private func writeExpansionItems(at root: URL) throws {
        try write(
            """
            const struct ItemInfo gItemsInfo[] =
            {
                [ITEM_POTION] =
                {
                    .name = ITEM_NAME("Potion"),
                    .price = 300,
                    .holdEffectParam = 20,
                    .description = COMPOUND_STRING("Restores HP."),
                    .pocket = POCKET_ITEMS,
                    .sortType = ITEM_TYPE_HEALTH_RECOVERY,
                    .type = ITEM_USE_PARTY_MENU,
                    .fieldUseFunc = ItemUseOutOfBattle_Medicine,
                    .battleUsage = EFFECT_ITEM_RESTORE_HP,
                    .battleUseFunc = NULL,
                    .secondaryId = 0,
                    .iconPic = gItemIcon_Potion,
                    .iconPalette = gItemIconPalette_Potion,
                },
            };
            """,
            to: root.appendingPathComponent("src/data/items.h")
        )
    }

    private func writeExpansionMovesInfo(at root: URL) throws {
        try write(
            """
            const struct MoveInfo gMovesInfo[] =
            {
                [MOVE_NONE] =
                {
                    .effect = EFFECT_NONE,
                    .power = 0,
                    .type = TYPE_NORMAL,
                    .accuracy = 0,
                    .pp = 0,
                    .secondaryEffectChance = 0,
                    .target = MOVE_TARGET_SELECTED,
                    .priority = 0,
                    .flags = 0,
                },
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
                    .description = sPoundDescription,
                    .contestCategory = CONTEST_CATEGORY_TOUGH,
                },
            };
            """,
            to: root.appendingPathComponent("src/data/moves_info.h")
        )
    }

    private func writeExpansionSpecies(at root: URL) throws {
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
                    .catchRate = 45,
                    .baseExp = 65,
                    .evYield_HP = 0,
                    .evYield_Attack = 0,
                    .evYield_Defense = 0,
                    .evYield_Speed = 1,
                    .evYield_SpAttack = 0,
                    .evYield_SpDefense = 0,
                    .item1 = ITEM_NONE,
                    .item2 = ITEM_NONE,
                    .genderRatio = PERCENT_FEMALE(12.5),
                    .eggCycles = 20,
                    .friendship = 70,
                    .growthRate = GROWTH_MEDIUM_SLOW,
                    .eggGroup1 = EGG_GROUP_MONSTER,
                    .eggGroup2 = EGG_GROUP_DRAGON,
                    .ability1 = ABILITY_OVERGROW,
                    .ability2 = ABILITY_NONE,
                    .hiddenAbility = ABILITY_CHLOROPHYLL,
                    .safariZoneFleeRate = 0,
                    .bodyColor = BODY_COLOR_GREEN,
                    .noFlip = FALSE,
                },
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/species_info.h")
        )
        try write(
            """
            [SPECIES_TREECKO] =
            {
                .categoryName = _(\"WOOD GECKO\"),
                .height = 5,
                .weight = 50,
                .description = COMPOUND_STRING(\"It quickly scales even vertical walls.\"),
                .formSpeciesIdTable = sTreeckoFormSpeciesIdTable,
                .formChangeTable = sTreeckoFormChangeTable,
            },
            """,
            to: root.appendingPathComponent("src/data/pokemon/species_info/gen_3_families.h")
        )
        try write(
            """
            static const u16 sTreeckoFormSpeciesIdTable[] = {
                SPECIES_TREECKO,
                SPECIES_TREECKO_MEGA,
                FORM_SPECIES_END,
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/form_species_tables.h")
        )
        try write(
            """
            static const struct FormChange sTreeckoFormChangeTable[] = {
                { FORM_CHANGE_BATTLE_MEGA_EVOLUTION, SPECIES_TREECKO_MEGA },
                { FORM_CHANGE_TERMINATOR },
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/form_change_tables.h")
        )
    }

    private func projectIndex(profile: GameProfile) throws -> ProjectIndex {
        let root = try temporaryRoot()
        return projectIndex(root: root, profile: profile)
    }

    private func projectIndex(root: URL, profile: GameProfile) -> ProjectIndex {
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

    private func formSourceIndex(profile: GameProfile) throws -> ProjectSourceIndex {
        let root = try temporaryRoot()
        return ProjectSourceIndex(
            root: SourceLocation(path: root.path, exists: true),
            profile: profile,
            adapterID: "test.\(profile.rawValue)",
            adapterName: "\(profile.rawValue) Fixture",
            records: [
                SourceIndexRecord(
                    id: "forms:src/data/pokemon/form_species_tables.h:sTreeckoFormSpeciesIdTable",
                    module: .pokemon,
                    title: "sTreeckoFormSpeciesIdTable",
                    subtitle: "src/data/pokemon/form_species_tables.h",
                    sourceSpan: SourceSpan(relativePath: "src/data/pokemon/form_species_tables.h", startLine: 1),
                    tags: ["form", "form-species-table", "read-only"],
                    facts: [SourceIndexFact(label: "Kind", value: "Form Species Table")]
                ),
                SourceIndexRecord(
                    id: "forms:src/data/pokemon/form_change_tables.h:sTreeckoFormChangeTable",
                    module: .pokemon,
                    title: "sTreeckoFormChangeTable",
                    subtitle: "src/data/pokemon/form_change_tables.h",
                    sourceSpan: SourceSpan(relativePath: "src/data/pokemon/form_change_tables.h", startLine: 1),
                    tags: ["form", "form-change-table", "read-only"],
                    facts: [SourceIndexFact(label: "Kind", value: "Form Change Table")]
                ),
                SourceIndexRecord(
                    id: "forms:src/data/pokemon/species_info/gen_3_families.h:SPECIES_TREECKO",
                    module: .pokemon,
                    title: "SPECIES_TREECKO",
                    subtitle: "src/data/pokemon/species_info/gen_3_families.h",
                    sourceSpan: SourceSpan(relativePath: "src/data/pokemon/species_info/gen_3_families.h", startLine: 1),
                    tags: ["form", "form-supplement", "species-info", "read-only"],
                    facts: [SourceIndexFact(label: "Form Species Table", value: "sTreeckoFormSpeciesIdTable")]
                ),
                SourceIndexRecord(
                    id: "legacy:src/data/pokemon/forms.h:sLegacyForms",
                    module: .pokemon,
                    title: "sLegacyForms",
                    subtitle: "src/data/pokemon/forms.h",
                    sourceSpan: SourceSpan(relativePath: "src/data/pokemon/forms.h", startLine: 1),
                    tags: ["forms", "read-only"],
                    facts: []
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
