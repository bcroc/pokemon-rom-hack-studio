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
        XCTAssertFalse(rubySpecies.unsupportedFields.contains("TM/HM learnset rewrites"))
        XCTAssertFalse(rubySpecies.unsupportedFields.contains("egg move rewrites"))
        XCTAssertFalse(rubySpecies.unsupportedFields.contains("Pokedex rewrites"))
        XCTAssertFalse(rubySpecies.unsupportedFields.contains("evolution rewrites"))
        XCTAssertNil(rubySpecies.recommendedFutureRow)
        let rubyEvolutions = entry(.evolutions, in: ruby)
        XCTAssertEqual(rubyEvolutions.status, .editable)
        XCTAssertEqual(rubyEvolutions.sourcePath, "src/data/pokemon/evolution.h")
        XCTAssertEqual(rubyEvolutions.tableSymbol, "gEvolutionTable")
        XCTAssertEqual(rubyEvolutions.indexedCount, 1)
        XCTAssertEqual(rubyEvolutions.editableCount, 1)
        XCTAssertEqual(rubyEvolutions.readOnlyCount, 0)
        XCTAssertNil(rubyEvolutions.blockedReason)
        XCTAssertNil(rubyEvolutions.recommendedFutureRow)
        XCTAssertEqual(rubyEvolutions.unsupportedFields, ["missing evolution row insertion"])
        let rubyPokedex = entry(.pokedex, in: ruby)
        XCTAssertEqual(rubyPokedex.status, .editable)
        XCTAssertEqual(rubyPokedex.sourcePath, "src/data/pokedex_entries_en.h")
        XCTAssertEqual(rubyPokedex.tableSymbol, "gPokedexEntries")
        XCTAssertEqual(rubyPokedex.indexedCount, 1)
        XCTAssertEqual(rubyPokedex.editableCount, 1)
        XCTAssertEqual(rubyPokedex.readOnlyCount, 0)
        XCTAssertNil(rubyPokedex.blockedReason)
        XCTAssertNil(rubyPokedex.recommendedFutureRow)
        XCTAssertFalse(rubyPokedex.unsupportedFields.contains("description text rewrites"))
        XCTAssertTrue(rubyPokedex.unsupportedFields.contains("national dex identity changes"))
        let rubyLevelUp = entry(.levelUpLearnsets, in: ruby)
        XCTAssertEqual(rubyLevelUp.status, .editable)
        XCTAssertEqual(rubyLevelUp.sourcePath, "src/data/pokemon/level_up_learnsets.h")
        XCTAssertEqual(rubyLevelUp.tableSymbol, "gLevelUpLearnsets")
        XCTAssertEqual(rubyLevelUp.indexedCount, 1)
        XCTAssertEqual(rubyLevelUp.editableCount, 1)
        XCTAssertEqual(rubyLevelUp.readOnlyCount, 0)
        XCTAssertNil(rubyLevelUp.blockedReason)
        XCTAssertNil(rubyLevelUp.recommendedFutureRow)
        XCTAssertTrue(rubyLevelUp.unsupportedFields.contains("learnset symbol renames"))
        XCTAssertTrue(rubyLevelUp.unsupportedFields.contains("shared learnset extraction"))
        XCTAssertTrue(rubyLevelUp.unsupportedFields.contains("missing learnset block insertion"))
        XCTAssertTrue(rubyLevelUp.unsupportedFields.contains("generated learnset output writes"))
        XCTAssertTrue(rubyLevelUp.unsupportedFields.contains("reference-only learnset source writes"))
        XCTAssertTrue(rubyLevelUp.unsupportedFields.contains("binary ROM learnset writes"))
        let rubyLevelUpSources = try XCTUnwrap(rubyLevelUp.sourceTables)
        XCTAssertTrue(rubyLevelUpSources.contains { $0.path == "src/data/pokemon/level_up_learnsets.h" && $0.tableSymbol == "gLevelUpLearnsets" && $0.status == .editable && $0.indexedCount == 1 })
        XCTAssertTrue(rubyLevelUpSources.contains { $0.path == "src/data/pokemon/tmhm_learnsets.h" && $0.tableSymbol == "gTMHMLearnsets" && $0.status == .editable && $0.indexedCount == 1 })
        XCTAssertTrue(rubyLevelUpSources.contains { $0.path == "src/data/pokemon/egg_moves.h" && $0.tableSymbol == "gEggMoves" && $0.status == .editable && $0.indexedCount == 1 })
        XCTAssertTrue(rubyLevelUpSources.contains { $0.path == "src/data/pokemon/tutor_learnsets.h" && $0.status == .blocked })
        XCTAssertTrue(rubyLevelUpSources.contains { $0.path == "references/pokeruby/src/data/pokemon/level_up_learnsets.h" && $0.status == .blocked })
        let rubyTMHM = entry(.tmhmLearnsets, in: ruby)
        XCTAssertEqual(rubyTMHM.status, .editable)
        XCTAssertEqual(rubyTMHM.sourcePath, "src/data/pokemon/tmhm_learnsets.h")
        XCTAssertEqual(rubyTMHM.tableSymbol, "gTMHMLearnsets")
        XCTAssertEqual(rubyTMHM.indexedCount, 1)
        XCTAssertEqual(rubyTMHM.editableCount, 1)
        XCTAssertEqual(rubyTMHM.readOnlyCount, 0)
        XCTAssertNil(rubyTMHM.blockedReason)
        XCTAssertNil(rubyTMHM.recommendedFutureRow)
        XCTAssertFalse(rubyTMHM.unsupportedFields.contains("compatibility matrix bulk edits"))
        XCTAssertTrue(rubyTMHM.unsupportedFields.contains("TM/HM item mapping edits"))
        XCTAssertTrue(rubyTMHM.unsupportedFields.contains("machine constant creation"))
        XCTAssertTrue(rubyTMHM.unsupportedFields.contains("missing TM/HM row insertion"))
        XCTAssertTrue(rubyTMHM.unsupportedFields.contains("generated learnset output writes"))
        XCTAssertTrue(rubyTMHM.unsupportedFields.contains("reference-only learnset source writes"))
        XCTAssertTrue(rubyTMHM.unsupportedFields.contains("binary ROM learnset writes"))
        let rubyEgg = entry(.eggMoves, in: ruby)
        XCTAssertEqual(rubyEgg.status, .editable)
        XCTAssertEqual(rubyEgg.sourcePath, "src/data/pokemon/egg_moves.h")
        XCTAssertEqual(rubyEgg.tableSymbol, "gEggMoves")
        XCTAssertEqual(rubyEgg.indexedCount, 1)
        XCTAssertEqual(rubyEgg.editableCount, 1)
        XCTAssertEqual(rubyEgg.readOnlyCount, 0)
        XCTAssertNil(rubyEgg.blockedReason)
        XCTAssertNil(rubyEgg.recommendedFutureRow)
        XCTAssertTrue(rubyEgg.unsupportedFields.contains("egg move family reshaping"))
        XCTAssertTrue(rubyEgg.unsupportedFields.contains("missing egg-move species row insertion"))
        XCTAssertTrue(rubyEgg.unsupportedFields.contains("generated learnset output writes"))
        XCTAssertTrue(rubyEgg.unsupportedFields.contains("reference-only learnset source writes"))
        XCTAssertTrue(rubyEgg.unsupportedFields.contains("binary ROM learnset writes"))
        XCTAssertTrue(rubyEgg.unsupportedFields.contains("broad Ruby/Sapphire egg-move schema rewrites"))
        let rubyTutor = entry(.tutorLearnsets, in: ruby)
        XCTAssertEqual(rubyTutor.status, .blocked)
        XCTAssertEqual(rubyTutor.sourcePath, "src/data/pokemon/tutor_learnsets.h")
        XCTAssertEqual(rubyTutor.tableSymbol, "sTutorLearnsets/gTutorLearnsets")
        XCTAssertEqual(rubyTutor.indexedCount, 0)
        XCTAssertEqual(rubyTutor.editableCount, 0)
        XCTAssertNil(rubyTutor.recommendedFutureRow)
        XCTAssertTrue(rubyTutor.unsupportedFields.contains("missing tutor row insertion"))
        XCTAssertTrue(rubyTutor.unsupportedFields.contains("generated learnset output writes"))
        XCTAssertTrue(rubyTutor.unsupportedFields.contains("reference-only learnset source writes"))
        XCTAssertTrue(rubyTutor.unsupportedFields.contains("binary ROM learnset writes"))
        let rubyTutorSources = try XCTUnwrap(rubyTutor.sourceTables)
        XCTAssertTrue(rubyTutorSources.contains { $0.path == "src/data/pokemon/tutor_learnsets.h" && $0.tableSymbol == "sTutorLearnsets/gTutorLearnsets" && $0.status == .blocked && $0.indexedCount == 0 })
        XCTAssertTrue(rubyTutorSources.contains { $0.path == "references/pokeruby/src/data/pokemon/tutor_learnsets.h" && $0.status == .blocked })
        XCTAssertTrue(rubyTutorSources.contains { $0.path == "ROM output" && $0.status == .blocked })
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
        XCTAssertFalse(rubyItems.unsupportedFields.contains("description text rewrites"))
        XCTAssertTrue(rubyItems.unsupportedFields.contains("TM/HM item compatibility edits"))
        XCTAssertNil(rubyItems.recommendedFutureRow)

        try writeRubyMoves(at: rubyRoot)
        try writeRubyTutorLearnsets(at: rubyRoot)
        let rubyMovesIndex = projectIndex(root: rubyRoot, profile: .pokeruby)
        let rubyMovesReport = try PokemonDataCompatibilityReportBuilder.build(
            index: rubyMovesIndex,
            sourceIndex: try ProjectSourceIndexLoader.load(from: rubyMovesIndex)
        )
        assertNoCompletedRowRecommendations(in: rubyMovesReport)
        let rubyMoves = entry(.moves, in: rubyMovesReport)
        XCTAssertEqual(rubyMoves.status, .editable)
        XCTAssertEqual(rubyMoves.sourcePath, "src/data/battle_moves.c")
        XCTAssertEqual(rubyMoves.tableSymbol, "gBattleMoves")
        XCTAssertEqual(rubyMoves.indexedCount, 1)
        XCTAssertEqual(rubyMoves.editableCount, 1)
        XCTAssertNil(rubyMoves.blockedReason)
        XCTAssertFalse(rubyMoves.unsupportedFields.contains("Ruby/Sapphire move row rewrites"))
        XCTAssertFalse(rubyMoves.unsupportedFields.contains("description text rewrites"))
        XCTAssertFalse(rubyMoves.unsupportedFields.contains("contest data"))
        XCTAssertFalse(rubyMoves.unsupportedFields.contains("contest data beyond existing .contestEffect"))
        XCTAssertTrue(rubyMoves.unsupportedFields.contains("missing or non-simple contest combo arrays and non-simple contest scalar expressions"))
        XCTAssertFalse(rubyMoves.unsupportedFields.contains("TM/HM/tutor compatibility edits"))
        XCTAssertFalse(rubyMoves.unsupportedFields.contains("tutor compatibility edits"))
        XCTAssertTrue(rubyMoves.unsupportedFields.contains("TM/HM item mapping edits"))
        XCTAssertTrue(rubyMoves.unsupportedFields.contains("machine constant creation"))
        XCTAssertTrue(rubyMoves.unsupportedFields.contains("missing TM/HM row insertion"))
        XCTAssertTrue(rubyMoves.unsupportedFields.contains("tutor constant creation"))
        XCTAssertTrue(rubyMoves.unsupportedFields.contains("missing tutor row insertion"))
        XCTAssertTrue(rubyMoves.unsupportedFields.contains("generated move output writes"))
        XCTAssertTrue(rubyMoves.unsupportedFields.contains("reference-only move source writes"))
        XCTAssertTrue(rubyMoves.unsupportedFields.contains("binary ROM move writes"))
        XCTAssertTrue(rubyMoves.unsupportedFields.contains("broad Ruby/Sapphire move schema rewrites"))
        XCTAssertNil(rubyMoves.recommendedFutureRow)
        let rubyMoveSources = try XCTUnwrap(rubyMoves.sourceTables)
        XCTAssertTrue(rubyMoveSources.contains { $0.path == "src/data/battle_moves.c" && $0.tableSymbol == "gBattleMoves" && $0.status == .editable && $0.indexedCount == 1 })
        XCTAssertTrue(rubyMoveSources.contains { $0.path == "src/data/battle_moves.c" && $0.tableSymbol == "gMoveDescription_*" && $0.status == .editable && $0.indexedCount == 1 })
        let rubyMoveConstants = try XCTUnwrap(rubyMoveSources.first { $0.path == "include/constants/moves.h" && $0.tableSymbol == "MOVE_*" })
        XCTAssertEqual(rubyMoveConstants.status, .readOnly)
        XCTAssertEqual(rubyMoveConstants.indexedCount, 4)
        XCTAssertEqual(rubyMoveConstants.sourceRole, "readOnlyMoveConstants")
        XCTAssertEqual(rubyMoveConstants.readiness, "read-only 4 MOVE_* constants indexed")
        XCTAssertEqual(rubyMoveConstants.blockedActions, [
            "constant creation",
            "constant rename",
            "row insertion/removal/reorder",
            "generated writes",
            "reference writes",
            "ROM writes",
            "binary writes"
        ])
        XCTAssertTrue(rubyMoveSources.contains { $0.path == "src/data/battle_moves.c" && $0.tableSymbol == ".contestEffect" && $0.status == .editable && $0.indexedCount == 1 })
        let rubyMoveTMHM = try XCTUnwrap(rubyMoveSources.first { $0.path == "src/data/pokemon/tmhm_learnsets.h" && $0.tableSymbol == "gTMHMLearnsets" })
        XCTAssertEqual(rubyMoveTMHM.status, .editable)
        XCTAssertEqual(rubyMoveTMHM.indexedCount, 1)
        XCTAssertEqual(rubyMoveTMHM.sourceRole, "editableTMHMLearnsets")
        XCTAssertEqual(rubyMoveTMHM.readiness, "editable existing gTMHMLearnsets rows")
        XCTAssertEqual(rubyMoveTMHM.blockedActions, [
            "TM/HM item mapping edits",
            "machine constant creation",
            "missing TM/HM row insertion",
            "row insertion/removal/reorder",
            "generated writes",
            "reference writes",
            "ROM writes",
            "binary writes"
        ])
        let rubyContestMoves = try XCTUnwrap(rubyMoveSources.first { $0.path == "src/data/contest_moves.h" && $0.tableSymbol == "gContestMoves" })
        XCTAssertEqual(rubyContestMoves.status, .editable)
        XCTAssertEqual(rubyContestMoves.indexedCount, 1)
        XCTAssertEqual(rubyContestMoves.sourceRole, "editableContestScalarsAndComboMoves")
        XCTAssertEqual(rubyContestMoves.readiness, "editable existing simple scalar fields and combo arrays")
        XCTAssertEqual(rubyContestMoves.blockedActions, [
            "constants",
            "missing-field insertion",
            "row insertion/removal/reorder",
            "generated writes",
            "reference writes",
            "ROM writes",
            "binary writes"
        ])
        let rubyMoveTutor = try XCTUnwrap(rubyMoveSources.first { $0.path == "src/data/pokemon/tutor_learnsets.h" && $0.tableSymbol == "sTutorLearnsets/gTutorLearnsets" })
        XCTAssertEqual(rubyMoveTutor.status, .editable)
        XCTAssertEqual(rubyMoveTutor.indexedCount, 1)
        XCTAssertEqual(rubyMoveTutor.sourceRole, "editableTutorLearnsets")
        XCTAssertEqual(rubyMoveTutor.readiness, "editable existing sTutorLearnsets/gTutorLearnsets rows")
        XCTAssertEqual(rubyMoveTutor.blockedActions, [
            "move constant creation",
            "tutor constant creation",
            "missing tutor row insertion",
            "row insertion/removal/reorder",
            "generated writes",
            "reference writes",
            "ROM writes",
            "binary writes"
        ])
        let rubyMoveEgg = try XCTUnwrap(rubyMoveSources.first { $0.path == "src/data/pokemon/egg_moves.h" && $0.tableSymbol == "gEggMoves" })
        XCTAssertEqual(rubyMoveEgg.status, .editable)
        XCTAssertEqual(rubyMoveEgg.indexedCount, 1)
        XCTAssertEqual(rubyMoveEgg.sourceRole, "editableEggMoves")
        XCTAssertEqual(rubyMoveEgg.readiness, "editable existing gEggMoves rows")
        XCTAssertEqual(rubyMoveEgg.blockedActions, [
            "move constant creation",
            "move identity changes",
            "missing egg-move species row insertion",
            "family reshaping",
            "row insertion/removal/reorder",
            "generated writes",
            "reference writes",
            "ROM writes",
            "binary writes"
        ])
        XCTAssertTrue(rubyMoveSources.contains { $0.path == "generated" && $0.status == .blocked })
        XCTAssertTrue(rubyMoveSources.contains { $0.path == "references/pokeruby/src/data/battle_moves.c" && $0.status == .blocked })
        XCTAssertTrue(rubyMoveSources.contains { $0.path == "ROM output" && $0.status == .blocked })
        let rubyJSON = String(data: try JSONEncoder().encode(rubyMovesReport), encoding: .utf8) ?? ""
        XCTAssertTrue(rubyJSON.contains(#""gLevelUpLearnsets""#))
        XCTAssertTrue(rubyJSON.contains(#""gContestMoves""#))
        XCTAssertTrue(rubyJSON.contains(#""editableContestScalarsAndComboMoves""#))
        XCTAssertTrue(rubyJSON.contains(#""readOnlyMoveConstants""#))
        XCTAssertTrue(rubyJSON.contains(#""editableTutorLearnsets""#))
        XCTAssertTrue(rubyJSON.contains(#""editableEggMoves""#))
        XCTAssertTrue(rubyJSON.contains(#""sTutorLearnsets\/gTutorLearnsets""#))
        XCTAssertTrue(rubyJSON.contains(#""references\/pokeruby\/src\/data\/pokemon\/level_up_learnsets.h""#))

        try FileManager.default.removeItem(at: rubyRoot.appendingPathComponent("include/constants/moves.h"))
        let missingConstantsIndex = projectIndex(root: rubyRoot, profile: .pokeruby)
        let missingConstantsReport = try PokemonDataCompatibilityReportBuilder.build(
            index: missingConstantsIndex,
            sourceIndex: try ProjectSourceIndexLoader.load(from: missingConstantsIndex)
        )
        let missingConstantsMoves = entry(.moves, in: missingConstantsReport)
        let missingConstantsSources = try XCTUnwrap(missingConstantsMoves.sourceTables)
        let missingConstants = try XCTUnwrap(missingConstantsSources.first { $0.path == "include/constants/moves.h" && $0.tableSymbol == "MOVE_*" })
        XCTAssertEqual(missingConstants.status, .blocked)
        XCTAssertEqual(missingConstants.indexedCount, 0)
        XCTAssertEqual(missingConstants.readiness, "missing local move constants header")

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
        let metadataSource = try XCTUnwrap(expansionItemSources.first { $0.path == "src/data/items.h" && $0.tableSymbol == "gItemsInfo .effect/.iconPic/.iconPalette" })
        XCTAssertEqual(metadataSource.status, .editable)
        XCTAssertEqual(metadataSource.indexedCount, 1)
        XCTAssertEqual(metadataSource.sourceRole, "editableSourceFields")
        XCTAssertEqual(metadataSource.readiness, "editable existing source fields")
        XCTAssertEqual(metadataSource.blockedActions, [
            "icon asset rewrites",
            "generated output writes",
            "Modern Emerald writes",
            "ROM/build/export paths",
            "identity edits"
        ])
        XCTAssertTrue(metadataSource.note?.contains("existing simple C-symbol fields") == true)
        let metadataJSON = String(data: try JSONEncoder().encode(metadataSource), encoding: .utf8) ?? ""
        XCTAssertTrue(metadataJSON.contains(#""sourceRole":"editableSourceFields""#))
        XCTAssertTrue(metadataJSON.contains(#""readiness":"editable existing source fields""#))
        XCTAssertTrue(metadataJSON.contains(#""blockedActions""#))
        XCTAssertTrue(metadataJSON.contains("effect"))
        XCTAssertTrue(metadataJSON.contains("Modern Emerald writes"))
        let usageSource = try XCTUnwrap(expansionItemSources.first {
            $0.path == "src/data/items.h"
                && $0.tableSymbol == "gItemsInfo .holdEffect/.holdEffectParam/.pocket/.type"
        })
        XCTAssertEqual(usageSource.status, .editable)
        XCTAssertEqual(usageSource.indexedCount, 1)
        XCTAssertEqual(usageSource.sourceRole, "editableUsageScalars")
        XCTAssertEqual(usageSource.readiness, "editable existing usage/classification scalar fields; complete missing group insertion is anchor-gated")
        XCTAssertEqual(usageSource.blockedActions, [
            "constants-file edits/creation",
            "partial missing-field insertion/removal",
            "row insertion/removal/reorder",
            "generated outputs",
            "reference writes",
            "ROM/build/export paths",
            "binary writes",
            "broad schema rewrites"
        ])
        XCTAssertTrue(usageSource.note?.contains("one complete anchored usage/classification group") == true)
        let behaviorSource = try XCTUnwrap(expansionItemSources.first {
            $0.path == "src/data/items.h"
                && $0.tableSymbol == "gItemsInfo .fieldUseFunc/.battleUsage/.battleUseFunc/.secondaryId"
        })
        XCTAssertEqual(behaviorSource.status, .editable)
        XCTAssertEqual(behaviorSource.indexedCount, 1)
        XCTAssertEqual(behaviorSource.sourceRole, "editableBehaviorScalars")
        XCTAssertEqual(behaviorSource.readiness, "editable existing behavior/function scalar fields; complete missing group insertion is anchor-gated")
        XCTAssertEqual(behaviorSource.blockedActions, [
            "constants-file edits/creation",
            "partial missing-field insertion/removal",
            "row insertion/removal/reorder",
            "generated outputs",
            "reference writes",
            "ROM/build/export paths",
            "binary writes",
            "broad schema rewrites"
        ])
        XCTAssertTrue(behaviorSource.note?.contains("inserted as one complete anchored behavior/function group") == true)
        let bagClassificationSource = try XCTUnwrap(expansionItemSources.first {
            $0.path == "src/data/items.h"
                && $0.tableSymbol == "gItemsInfo .importance/.registrability/.sortType/.exitsBagOnUse"
        })
        XCTAssertEqual(bagClassificationSource.status, .editable)
        XCTAssertEqual(bagClassificationSource.indexedCount, 1)
        XCTAssertEqual(bagClassificationSource.sourceRole, "editableBagClassificationScalars")
        XCTAssertEqual(bagClassificationSource.readiness, "editable existing bag/classification scalar fields")
        XCTAssertEqual(bagClassificationSource.blockedActions, [
            "constants-file edits/creation",
            "missing-field insertion",
            "row insertion/removal/reorder",
            "generated outputs",
            "reference writes",
            "ROM/build/export paths",
            "binary writes",
            "broad schema rewrites"
        ])
        XCTAssertTrue(bagClassificationSource.note?.contains("existing simple local source fields") == true)
        XCTAssertTrue(expansionItemSources.contains { $0.path == "include/config/item.h" && $0.status == .blocked })
        XCTAssertTrue(expansionItemSources.contains { $0.path == "generated" && $0.status == .blocked })
        XCTAssertTrue(expansionItemSources.contains { $0.path == "references/pokeemerald-expansion/src/data/items.h" && $0.status == .blocked })
        assertModernEmeraldSource(
            in: expansionItemSources,
            path: "references/modern-emerald/src/data/items.h",
            tableSymbol: "gItems"
        )
        assertModernEmeraldSource(
            in: expansionItemSources,
            path: "references/modern-emerald/include/constants/items.h"
        )
        assertModernEmeraldSource(
            in: expansionItemSources,
            path: "references/modern-emerald/include/config.h"
        )
        assertModernEmeraldSource(
            in: expansionItemSources,
            path: "references/modern-emerald/src/data/graphics/items.h",
            tableSymbol: "item graphics metadata"
        )
        assertModernEmeraldSource(
            in: expansionItemSources,
            path: "references/modern-emerald/graphics/items/icons",
            tableSymbol: "item icon PNG paths"
        )
        assertModernEmeraldSource(
            in: expansionItemSources,
            path: "references/modern-emerald/graphics/items/icon_palettes",
            tableSymbol: "item icon palette paths"
        )
        XCTAssertTrue(expansionItems.diagnostics.contains { $0.code == "GBA_MODERN_EMERALD_ITEMS_UNSUPPORTED" })
    }

    func testRubyTutorLearnsetsReportEditableForExistingLocalRows() throws {
        let root = try temporaryRoot()
        try writeRubySpecies(at: root)
        try writeRubyTutorLearnsets(at: root)
        let index = projectIndex(root: root, profile: .pokeruby)
        let report = try PokemonDataCompatibilityReportBuilder.build(
            index: index,
            sourceIndex: try ProjectSourceIndexLoader.load(from: index)
        )

        assertNoCompletedRowRecommendations(in: report)
        let tutor = entry(.tutorLearnsets, in: report)
        XCTAssertEqual(tutor.status, .editable)
        XCTAssertEqual(tutor.sourcePath, "src/data/pokemon/tutor_learnsets.h")
        XCTAssertEqual(tutor.tableSymbol, "sTutorLearnsets/gTutorLearnsets")
        XCTAssertEqual(tutor.indexedCount, 1)
        XCTAssertEqual(tutor.editableCount, 1)
        XCTAssertEqual(tutor.readOnlyCount, 0)
        XCTAssertNil(tutor.blockedReason)
        XCTAssertNil(tutor.recommendedFutureRow)
        XCTAssertTrue(tutor.unsupportedFields.contains("learnset symbol renames"))
        XCTAssertTrue(tutor.unsupportedFields.contains("tutor constant creation"))
        XCTAssertTrue(tutor.unsupportedFields.contains("missing tutor row insertion"))
        XCTAssertTrue(tutor.unsupportedFields.contains("generated learnset output writes"))
        XCTAssertTrue(tutor.unsupportedFields.contains("reference-only learnset source writes"))
        XCTAssertTrue(tutor.unsupportedFields.contains("binary ROM learnset writes"))
        XCTAssertTrue(tutor.unsupportedFields.contains("broad Ruby/Sapphire tutor schema rewrites"))
        let sourceTables = try XCTUnwrap(tutor.sourceTables)
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/pokemon/tutor_learnsets.h" && $0.tableSymbol == "sTutorLearnsets/gTutorLearnsets" && $0.status == .editable && $0.indexedCount == 1 })
        XCTAssertTrue(sourceTables.contains { $0.path == "include/constants/moves.h" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "generated" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "references/pokeruby/src/data/pokemon/tutor_learnsets.h" && $0.tableSymbol == "sTutorLearnsets/gTutorLearnsets" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "ROM output" && $0.status == .blocked })

        let json = String(data: try JSONEncoder().encode(report), encoding: .utf8) ?? ""
        XCTAssertTrue(json.contains(#""sTutorLearnsets\/gTutorLearnsets""#))
        XCTAssertTrue(json.contains(#""references\/pokeruby\/src\/data\/pokemon\/tutor_learnsets.h""#))
    }

    func testExpansionMovesInfoRowsReportEditableWithBlockedAdjacentSourcesAndJSON() throws {
        let root = try temporaryRoot()
        try writeExpansionMovesInfo(at: root)
        try writeExpansionSpecies(at: root)
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
        XCTAssertFalse(moves.unsupportedFields.contains("contest data"))
        XCTAssertTrue(moves.unsupportedFields.contains("gMovesInfo non-simple contest scalar expressions"))
        XCTAssertTrue(moves.unsupportedFields.contains("gMovesInfo non-simple contest combo move arrays"))
        XCTAssertFalse(moves.unsupportedFields.contains("description text rewrites"))
        XCTAssertTrue(moves.unsupportedFields.contains("non-source-backed move description rewrites"))
        XCTAssertFalse(moves.unsupportedFields.contains("TM/HM/tutor compatibility edits"))
        XCTAssertTrue(moves.unsupportedFields.contains("gMovesInfo non-simple flags expressions"))
        XCTAssertTrue(moves.unsupportedFields.contains("TM/HM compatibility edits from move row plans"))
        XCTAssertTrue(moves.unsupportedFields.contains("egg compatibility edits from move row plans"))
        XCTAssertTrue(moves.unsupportedFields.contains("tutor constant creation"))
        XCTAssertTrue(moves.unsupportedFields.contains("missing tutor row insertion"))
        XCTAssertTrue(moves.unsupportedFields.contains("generated all_learnables.json writes"))
        XCTAssertTrue(moves.unsupportedFields.contains("generated move output writes"))
        XCTAssertTrue(moves.unsupportedFields.contains("reference-only move source writes"))
        XCTAssertTrue(moves.unsupportedFields.contains("Modern Emerald move writers"))
        XCTAssertTrue(moves.unsupportedFields.contains("binary ROM move writes"))
        XCTAssertTrue(moves.unsupportedFields.contains("broad Expansion move schema rewrites"))
        XCTAssertNil(moves.recommendedFutureRow)
        let sourceTables = try XCTUnwrap(moves.sourceTables)
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/moves_info.h" && $0.tableSymbol == "gMovesInfo" && $0.status == .editable && $0.indexedCount == 1 })
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/moves_info.h" && ($0.note?.contains("move description declarations") == true) })
        XCTAssertTrue(sourceTables.contains { $0.path == "include/constants/moves.h" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/text/move_descriptions.h" && $0.status == .editable })
        let flags = try XCTUnwrap(sourceTables.first { $0.path == "src/data/moves_info.h" && $0.tableSymbol == "gMovesInfo flags" })
        XCTAssertEqual(flags.status, .editable)
        XCTAssertEqual(flags.indexedCount, 1)
        XCTAssertEqual(flags.sourceRole, "editableFlags")
        XCTAssertEqual(flags.readiness, "editable existing or missing simple FLAG_* field values")
        XCTAssertTrue(flags.blockedActions?.contains("constant creation") == true)
        XCTAssertTrue(flags.blockedActions?.contains("non-simple flags expressions") == true)
        XCTAssertTrue(flags.blockedActions?.contains("row insertion/removal/reorder") == true)
        XCTAssertTrue(flags.blockedActions?.contains("generated outputs") == true)
        XCTAssertTrue(flags.blockedActions?.contains("reference writes") == true)
        XCTAssertTrue(flags.blockedActions?.contains("ROM/build/export paths") == true)
        XCTAssertTrue(flags.blockedActions?.contains("binary writes") == true)
        let contestMetadata = try XCTUnwrap(sourceTables.first { $0.path == "src/data/moves_info.h" && $0.tableSymbol == "gMovesInfo contest scalars" })
        XCTAssertEqual(contestMetadata.status, .editable)
        XCTAssertEqual(contestMetadata.sourceRole, "editableContestScalars")
        XCTAssertEqual(contestMetadata.readiness, "editable existing simple scalar fields")
        XCTAssertTrue(contestMetadata.blockedActions?.contains("constants") == true)
        XCTAssertTrue(contestMetadata.blockedActions?.contains("missing-field insertion") == true)
        XCTAssertTrue(contestMetadata.blockedActions?.contains("row insertion/removal/reorder") == true)
        XCTAssertTrue(contestMetadata.blockedActions?.contains("generated outputs") == true)
        XCTAssertTrue(contestMetadata.blockedActions?.contains("reference writes") == true)
        XCTAssertTrue(contestMetadata.blockedActions?.contains("ROM/binary writes") == true)
        let contestCombos = try XCTUnwrap(sourceTables.first { $0.path == "src/data/moves_info.h" && $0.tableSymbol == "gMovesInfo contest combo moves" })
        XCTAssertEqual(contestCombos.status, .editable)
        XCTAssertEqual(contestCombos.indexedCount, 1)
        XCTAssertEqual(contestCombos.sourceRole, "editableContestComboMoves")
        XCTAssertEqual(contestCombos.readiness, "editable existing simple MOVE_* arrays")
        XCTAssertTrue(contestCombos.blockedActions?.contains("constants") == true)
        XCTAssertTrue(contestCombos.blockedActions?.contains("missing-field insertion") == true)
        XCTAssertTrue(contestCombos.blockedActions?.contains("row insertion/removal/reorder") == true)
        XCTAssertTrue(contestCombos.blockedActions?.contains("generated outputs") == true)
        XCTAssertTrue(contestCombos.blockedActions?.contains("reference writes") == true)
        XCTAssertTrue(contestCombos.blockedActions?.contains("ROM/build/export paths") == true)
        XCTAssertTrue(contestCombos.blockedActions?.contains("binary writes") == true)
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/contest_moves.h" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/pokemon/tmhm_learnsets.h" && $0.status == .blocked })
        let tutorCompatibility = try XCTUnwrap(sourceTables.first { $0.path == "src/data/pokemon/tutor_learnsets.h" && $0.tableSymbol == "gTutorLearnsets" })
        XCTAssertEqual(tutorCompatibility.status, .editable)
        XCTAssertEqual(tutorCompatibility.indexedCount, 1)
        XCTAssertEqual(tutorCompatibility.sourceRole, "editableTutorLearnsets")
        XCTAssertEqual(tutorCompatibility.readiness, "editable existing gTutorLearnsets rows")
        XCTAssertEqual(tutorCompatibility.blockedActions, [
            "tutor constant creation",
            "missing tutor row insertion",
            "row insertion/removal/reorder",
            "generated all_learnables.json writes",
            "generated outputs",
            "reference writes",
            "ROM/build/export paths",
            "binary writes"
        ])
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/pokemon/egg_moves.h" && $0.tableSymbol == "gEggMoves" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "generated" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "references/pokeemerald-expansion/src/data/moves_info.h" && $0.status == .blocked })
        assertModernEmeraldSource(
            in: sourceTables,
            path: "references/modern-emerald/src/data/battle_moves.h",
            tableSymbol: "gBattleMoves"
        )
        assertModernEmeraldSource(
            in: sourceTables,
            path: "references/modern-emerald/include/constants/moves.h"
        )
        assertModernEmeraldSource(
            in: sourceTables,
            path: "references/modern-emerald/include/config.h"
        )
        assertModernEmeraldSource(
            in: sourceTables,
            path: "references/modern-emerald/src/data/pokemon/tmhm_learnsets.h",
            tableSymbol: "gTMHMLearnsets"
        )
        assertModernEmeraldSource(
            in: sourceTables,
            path: "references/modern-emerald/src/data/pokemon/tutor_learnsets.h",
            tableSymbol: "gTutorLearnsets"
        )
        XCTAssertTrue(sourceTables.contains { $0.path == "ROM output" && $0.status == .blocked })
        XCTAssertTrue(moves.diagnostics.contains { $0.code == "GBA_MODERN_EMERALD_MOVES_UNSUPPORTED" })

        let json = String(data: try JSONEncoder().encode(expansion), encoding: .utf8) ?? ""
        XCTAssertTrue(json.contains(#""sourceTables""#))
        XCTAssertTrue(json.contains(#""gMovesInfo""#))
        XCTAssertTrue(json.contains(#""editableTutorLearnsets""#))
        XCTAssertTrue(json.contains(#""generated all_learnables.json writes""#))
        XCTAssertTrue(json.contains(#""generated""#))
        XCTAssertTrue(json.contains(#""references\/pokeemerald-expansion\/src\/data\/moves_info.h""#))
        XCTAssertTrue(json.contains(#""references\/modern-emerald\/src\/data\/battle_moves.h""#))
        XCTAssertTrue(json.contains(#""sourceRole":"referenceOnly""#))
        XCTAssertTrue(json.contains(#""sourceRole":"editableFlags""#))
        XCTAssertTrue(json.contains(#""readiness":"editable existing or missing simple FLAG_* field values""#))
        XCTAssertTrue(json.contains(#""sourceRole":"editableContestScalars""#))
        XCTAssertTrue(json.contains(#""readiness":"editable existing simple scalar fields""#))
        XCTAssertTrue(json.contains(#""recommendedFutureRow":"PHS-T78""#))
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
        XCTAssertEqual(species.indexedCount, 4)
        XCTAssertEqual(species.editableCount, 4)
        XCTAssertNil(species.blockedReason)
        XCTAssertNil(species.recommendedFutureRow)
        XCTAssertTrue(species.unsupportedFields.contains("type/ability/egg group brace-list rewrites"))
        XCTAssertFalse(species.unsupportedFields.contains("learnset rewrites"))
        XCTAssertFalse(species.unsupportedFields.contains("TM/HM/tutor/egg move rewrites"))
        XCTAssertTrue(species.unsupportedFields.contains("TM/HM/egg move rewrites"))
        XCTAssertFalse(species.unsupportedFields.contains("evolution rewrites"))
        XCTAssertTrue(species.unsupportedFields.contains("evolution row insertion/removal/reorder"))
        XCTAssertFalse(species.unsupportedFields.contains("Pokedex rewrites"))
        XCTAssertFalse(species.unsupportedFields.contains("Pokedex text rewrites"))
        XCTAssertTrue(species.unsupportedFields.contains("species asset/cries/form rewrites"))
        XCTAssertTrue(species.unsupportedFields.contains("generated species family supplement apply"))
        XCTAssertTrue(species.unsupportedFields.contains("reference-only species source writes"))
        XCTAssertTrue(species.unsupportedFields.contains("Modern Emerald species writers"))
        XCTAssertTrue(species.unsupportedFields.contains("binary ROM species writes"))
        let sourceTables = try XCTUnwrap(species.sourceTables)
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/pokemon/species_info.h" && $0.tableSymbol == "gSpeciesInfo" && $0.status == .editable && $0.indexedCount == 4 })
        XCTAssertTrue(sourceTables.contains { $0.path == "include/config/species_enabled.h" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "include/config/pokemon.h" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/pokemon/species_info/" && $0.status == .blocked && $0.indexedCount == 1 })
        XCTAssertTrue(sourceTables.contains { $0.path == "generated" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "references/pokeemerald-expansion/src/data/pokemon/species_info.h" && $0.status == .blocked })
        assertModernEmeraldSource(
            in: sourceTables,
            path: "references/modern-emerald/src/data/pokemon/species_info.h",
            tableSymbol: "gSpeciesInfo"
        )
        assertModernEmeraldSource(
            in: sourceTables,
            path: "references/modern-emerald/include/constants/species.h"
        )
        assertModernEmeraldSource(
            in: sourceTables,
            path: "references/modern-emerald/include/constants/pokemon.h"
        )
        assertModernEmeraldSource(
            in: sourceTables,
            path: "references/modern-emerald/include/config.h"
        )
        assertModernEmeraldSource(
            in: sourceTables,
            path: "references/modern-emerald/graphics/pokemon",
            tableSymbol: "species graphics/icon paths"
        )
        XCTAssertTrue(sourceTables.contains { $0.path == "ROM output" && $0.status == .blocked })
        XCTAssertTrue(species.diagnostics.contains { $0.code == "GBA_MODERN_EMERALD_SPECIES_UNSUPPORTED" })

        let levelUp = entry(.levelUpLearnsets, in: expansion)
        XCTAssertEqual(levelUp.status, .editable)
        XCTAssertEqual(levelUp.sourcePath, "src/data/pokemon/level_up_learnsets")
        XCTAssertEqual(levelUp.tableSymbol, "s*LevelUpLearnset")
        XCTAssertEqual(levelUp.indexedCount, 1)
        XCTAssertEqual(levelUp.editableCount, 1)
        XCTAssertNil(levelUp.blockedReason)
        XCTAssertNil(levelUp.recommendedFutureRow)
        XCTAssertTrue(levelUp.unsupportedFields.contains("learnset symbol renames"))
        XCTAssertTrue(levelUp.unsupportedFields.contains("shared learnset extraction"))
        XCTAssertTrue(levelUp.unsupportedFields.contains("missing learnset block insertion"))
        XCTAssertTrue(levelUp.unsupportedFields.contains("all_learnables.json apply"))
        XCTAssertTrue(levelUp.unsupportedFields.contains("generated learnset output writes"))
        XCTAssertTrue(levelUp.unsupportedFields.contains("reference-only learnset source writes"))
        XCTAssertTrue(levelUp.unsupportedFields.contains("binary ROM learnset writes"))
        XCTAssertFalse(levelUp.unsupportedFields.contains("generated learnset directory apply"))
        let levelUpSources = try XCTUnwrap(levelUp.sourceTables)
        XCTAssertTrue(levelUpSources.contains { $0.path == "src/data/pokemon/level_up_learnsets" && $0.tableSymbol == "s*LevelUpLearnset" && $0.status == .editable && $0.indexedCount == 1 })
        XCTAssertTrue(levelUpSources.contains { $0.path == "src/data/pokemon/all_learnables.json" && $0.status == .blocked && $0.indexedCount == 1 })
        assertBlockedGeneratedLearnsetRows(in: levelUp)
        XCTAssertTrue(levelUpSources.contains { $0.path == "generated" && $0.status == .blocked })
        XCTAssertTrue(levelUpSources.contains { $0.path == "references/pokeemerald-expansion/src/data/pokemon/level_up_learnsets" && $0.status == .blocked })
        assertModernEmeraldSource(
            in: levelUpSources,
            path: "references/modern-emerald/src/data/pokemon/level_up_learnsets.h",
            tableSymbol: "s*LevelUpLearnset"
        )
        XCTAssertTrue(levelUpSources.contains { $0.path == "ROM output" && $0.status == .blocked })

        let tmhm = entry(.tmhmLearnsets, in: expansion)
        XCTAssertEqual(tmhm.status, .editable)
        XCTAssertEqual(tmhm.sourcePath, "src/data/pokemon/tmhm_learnsets.h")
        XCTAssertEqual(tmhm.tableSymbol, "sTMHMLearnsets/gTMHMLearnsets")
        XCTAssertEqual(tmhm.indexedCount, 1)
        XCTAssertEqual(tmhm.editableCount, 1)
        XCTAssertEqual(tmhm.readOnlyCount, 0)
        XCTAssertNil(tmhm.blockedReason)
        XCTAssertNil(tmhm.recommendedFutureRow)
        XCTAssertTrue(tmhm.unsupportedFields.contains("TM/HM item mapping edits"))
        XCTAssertTrue(tmhm.unsupportedFields.contains("machine constant creation"))
        XCTAssertTrue(tmhm.unsupportedFields.contains("missing TM/HM row insertion"))
        XCTAssertTrue(tmhm.unsupportedFields.contains("all_learnables.json apply"))
        XCTAssertTrue(tmhm.unsupportedFields.contains("generated learnset output writes"))
        XCTAssertTrue(tmhm.unsupportedFields.contains("reference-only learnset source writes"))
        XCTAssertTrue(tmhm.unsupportedFields.contains("binary ROM learnset writes"))
        XCTAssertFalse(tmhm.unsupportedFields.contains("compatibility matrix bulk edits"))
        let tmhmSources = try XCTUnwrap(tmhm.sourceTables)
        XCTAssertTrue(tmhmSources.contains { $0.path == "src/data/pokemon/tmhm_learnsets.h" && $0.tableSymbol == "sTMHMLearnsets/gTMHMLearnsets" && $0.status == .editable && $0.indexedCount == 1 })
        XCTAssertTrue(tmhmSources.contains { $0.path == "src/data/pokemon/all_learnables.json" && $0.status == .blocked && $0.indexedCount == 1 })
        assertBlockedGeneratedLearnsetRows(in: tmhm)
        XCTAssertTrue(tmhmSources.contains { $0.path == "generated" && $0.status == .blocked })
        XCTAssertTrue(tmhmSources.contains { $0.path == "references/pokeemerald-expansion/src/data/pokemon/tmhm_learnsets.h" && $0.tableSymbol == "sTMHMLearnsets/gTMHMLearnsets" && $0.status == .blocked })
        assertModernEmeraldSource(
            in: tmhmSources,
            path: "references/modern-emerald/src/data/pokemon/tmhm_learnsets.h",
            tableSymbol: "gTMHMLearnsets"
        )
        XCTAssertTrue(tmhmSources.contains { $0.path == "ROM output" && $0.status == .blocked })

        let egg = entry(.eggMoves, in: expansion)
        XCTAssertEqual(egg.status, .editable)
        XCTAssertEqual(egg.sourcePath, "src/data/pokemon/egg_moves.h")
        XCTAssertEqual(egg.tableSymbol, "gEggMoves")
        XCTAssertEqual(egg.indexedCount, 1)
        XCTAssertEqual(egg.editableCount, 1)
        XCTAssertEqual(egg.readOnlyCount, 0)
        XCTAssertNil(egg.blockedReason)
        XCTAssertNil(egg.recommendedFutureRow)
        XCTAssertTrue(egg.unsupportedFields.contains("egg move family reshaping"))
        XCTAssertTrue(egg.unsupportedFields.contains("missing egg-move species row insertion"))
        XCTAssertTrue(egg.unsupportedFields.contains("all_learnables.json apply"))
        XCTAssertTrue(egg.unsupportedFields.contains("generated learnset output writes"))
        XCTAssertTrue(egg.unsupportedFields.contains("reference-only learnset source writes"))
        XCTAssertTrue(egg.unsupportedFields.contains("binary ROM learnset writes"))
        XCTAssertTrue(egg.unsupportedFields.contains("broad Expansion egg-move schema rewrites"))
        let eggSources = try XCTUnwrap(egg.sourceTables)
        XCTAssertTrue(eggSources.contains { $0.path == "src/data/pokemon/egg_moves.h" && $0.tableSymbol == "gEggMoves" && $0.status == .editable && $0.indexedCount == 1 })
        XCTAssertTrue(eggSources.contains { $0.path == "src/data/pokemon/all_learnables.json" && $0.status == .blocked && $0.indexedCount == 1 })
        assertBlockedGeneratedLearnsetRows(in: egg)
        XCTAssertTrue(eggSources.contains { $0.path == "generated" && $0.status == .blocked })
        XCTAssertTrue(eggSources.contains { $0.path == "references/pokeemerald-expansion/src/data/pokemon/egg_moves.h" && $0.tableSymbol == "gEggMoves" && $0.status == .blocked })
        assertModernEmeraldSource(
            in: eggSources,
            path: "references/modern-emerald/src/data/pokemon/egg_moves.h",
            tableSymbol: "gEggMoves"
        )
        XCTAssertTrue(eggSources.contains { $0.path == "ROM output" && $0.status == .blocked })

        let tutor = entry(.tutorLearnsets, in: expansion)
        XCTAssertEqual(tutor.status, .editable)
        XCTAssertEqual(tutor.sourcePath, "src/data/pokemon/tutor_learnsets.h")
        XCTAssertEqual(tutor.tableSymbol, "gTutorLearnsets")
        XCTAssertEqual(tutor.indexedCount, 1)
        XCTAssertEqual(tutor.editableCount, 1)
        XCTAssertEqual(tutor.readOnlyCount, 0)
        XCTAssertNil(tutor.blockedReason)
        XCTAssertNil(tutor.recommendedFutureRow)
        XCTAssertTrue(tutor.unsupportedFields.contains("learnset symbol renames"))
        XCTAssertTrue(tutor.unsupportedFields.contains("tutor constant creation"))
        XCTAssertTrue(tutor.unsupportedFields.contains("missing tutor row insertion"))
        XCTAssertTrue(tutor.unsupportedFields.contains("all_learnables.json apply"))
        XCTAssertTrue(tutor.unsupportedFields.contains("generated learnset output writes"))
        XCTAssertTrue(tutor.unsupportedFields.contains("reference-only learnset source writes"))
        XCTAssertTrue(tutor.unsupportedFields.contains("binary ROM learnset writes"))
        XCTAssertFalse(tutor.unsupportedFields.contains("compatibility matrix bulk edits"))
        let tutorSources = try XCTUnwrap(tutor.sourceTables)
        XCTAssertTrue(tutorSources.contains { $0.path == "src/data/pokemon/tutor_learnsets.h" && $0.tableSymbol == "gTutorLearnsets" && $0.status == .editable && $0.indexedCount == 1 })
        XCTAssertTrue(tutorSources.contains { $0.path == "include/constants/moves.h" && $0.status == .blocked })
        XCTAssertTrue(tutorSources.contains { $0.path == "src/data/pokemon/all_learnables.json" && $0.status == .blocked && $0.indexedCount == 1 })
        assertBlockedGeneratedLearnsetRows(in: tutor)
        XCTAssertTrue(tutorSources.contains { $0.path == "generated" && $0.status == .blocked })
        XCTAssertTrue(tutorSources.contains { $0.path == "references/pokeemerald-expansion/src/data/pokemon/tutor_learnsets.h" && $0.tableSymbol == "gTutorLearnsets" && $0.status == .blocked })
        assertModernEmeraldSource(
            in: tutorSources,
            path: "references/modern-emerald/src/data/pokemon/tutor_learnsets.h",
            tableSymbol: "gTutorMoves/s*TutorLearnset"
        )
        XCTAssertTrue(tutorSources.contains { $0.path == "ROM output" && $0.status == .blocked })

        let evolutions = entry(.evolutions, in: expansion)
        XCTAssertEqual(evolutions.status, .editable)
        XCTAssertEqual(evolutions.sourcePath, "src/data/pokemon/evolution.h")
        XCTAssertEqual(evolutions.tableSymbol, "gEvolutionTable")
        XCTAssertEqual(evolutions.indexedCount, 1)
        XCTAssertEqual(evolutions.editableCount, 1)
        XCTAssertEqual(evolutions.readOnlyCount, 0)
        XCTAssertNil(evolutions.blockedReason)
        XCTAssertNil(evolutions.recommendedFutureRow)
        XCTAssertTrue(evolutions.unsupportedFields.contains("evolution row insertion/removal/reorder"))
        XCTAssertTrue(evolutions.unsupportedFields.contains("evolution method constant creation"))
        XCTAssertTrue(evolutions.unsupportedFields.contains("species constant/identity changes"))
        XCTAssertTrue(evolutions.unsupportedFields.contains("generated evolution output writes"))
        XCTAssertTrue(evolutions.unsupportedFields.contains("reference-only evolution source writes"))
        XCTAssertTrue(evolutions.unsupportedFields.contains("ROM/export/build outputs"))
        XCTAssertTrue(evolutions.unsupportedFields.contains("binary ROM evolution writes"))
        let evolutionSources = try XCTUnwrap(evolutions.sourceTables)
        XCTAssertTrue(evolutionSources.contains { $0.path == "src/data/pokemon/evolution.h" && $0.tableSymbol == "gEvolutionTable" && $0.status == .editable && $0.indexedCount == 1 })
        XCTAssertTrue(evolutionSources.contains { $0.path == "include/constants/pokemon.h" && $0.status == .blocked })
        XCTAssertTrue(evolutionSources.contains { $0.path == "generated" && $0.status == .blocked })
        XCTAssertTrue(evolutionSources.contains { $0.path == "references/pokeemerald-expansion/src/data/pokemon/evolution.h" && $0.tableSymbol == "gEvolutionTable" && $0.status == .blocked })
        XCTAssertTrue(evolutionSources.contains { $0.path == "ROM output" && $0.status == .blocked })

        let forms = entry(.forms, in: expansion)
        XCTAssertEqual(forms.status, .editable)
        XCTAssertEqual(forms.sourcePath, "src/data/pokemon/form_species_tables.h")
        XCTAssertEqual(forms.tableSymbol, "FormSpeciesIdTable/FormChangeTable")
        XCTAssertEqual(forms.indexedCount, 3)
        XCTAssertEqual(forms.editableCount, 2)
        XCTAssertEqual(forms.readOnlyCount, 1)
        XCTAssertNil(forms.blockedReason)
        XCTAssertNil(forms.recommendedFutureRow)
        XCTAssertTrue(forms.unsupportedFields.contains("form row insertion/removal/reorder"))
        XCTAssertTrue(forms.unsupportedFields.contains("unsupported form change tuple shapes"))
        XCTAssertTrue(forms.unsupportedFields.contains("form graphics sync"))
        XCTAssertTrue(forms.unsupportedFields.contains("generated family supplement apply"))
        XCTAssertTrue(forms.unsupportedFields.contains("reference-only form source writes"))
        XCTAssertTrue(forms.unsupportedFields.contains("ROM/export/build outputs"))
        XCTAssertTrue(forms.unsupportedFields.contains("binary-only form table writes"))
        let formSources = try XCTUnwrap(forms.sourceTables)
        XCTAssertTrue(formSources.contains { $0.path == "src/data/pokemon/form_species_tables.h" && $0.indexedCount == 1 && $0.status == .editable })
        XCTAssertTrue(formSources.contains { $0.path == "src/data/pokemon/form_change_tables.h" && $0.indexedCount == 1 && $0.status == .editable })
        XCTAssertTrue(formSources.contains { $0.path == "src/data/pokemon/species_info/" && $0.indexedCount == 1 && $0.status == .readOnly })
        XCTAssertTrue(formSources.contains { $0.path == "generated" && $0.status == .blocked })
        XCTAssertTrue(formSources.contains { $0.path == "references/pokeemerald-expansion/src/data/pokemon/form_species_tables.h" && $0.status == .blocked })
        XCTAssertTrue(formSources.contains { $0.path == "references/pokeemerald-expansion/src/data/pokemon/form_change_tables.h" && $0.status == .blocked })
        XCTAssertTrue(formSources.contains { $0.path == "graphics/pokemon" && $0.status == .blocked })
        XCTAssertTrue(formSources.contains { $0.path == "ROM output" && $0.status == .blocked })

        let pokedex = entry(.pokedex, in: expansion)
        XCTAssertEqual(pokedex.status, .editable)
        XCTAssertEqual(pokedex.sourcePath, "src/data/pokemon/pokedex_entries.h")
        XCTAssertEqual(pokedex.tableSymbol, "gPokedexEntries")
        XCTAssertEqual(pokedex.indexedCount, 1)
        XCTAssertEqual(pokedex.editableCount, 1)
        XCTAssertEqual(pokedex.readOnlyCount, 0)
        XCTAssertNil(pokedex.blockedReason)
        XCTAssertNil(pokedex.recommendedFutureRow)
        XCTAssertTrue(pokedex.unsupportedFields.contains("national dex identity changes"))
        XCTAssertTrue(pokedex.unsupportedFields.contains("missing Pokedex row insertion"))
        XCTAssertTrue(pokedex.unsupportedFields.contains("generated Pokedex output writes"))
        XCTAssertTrue(pokedex.unsupportedFields.contains("reference-only Pokedex source writes"))
        XCTAssertTrue(pokedex.unsupportedFields.contains("ROM/export/build outputs"))
        XCTAssertTrue(pokedex.unsupportedFields.contains("binary-only Pokedex writes"))
        XCTAssertTrue(pokedex.unsupportedFields.contains("broad Expansion Pokedex schema rewrites"))
        let pokedexSources = try XCTUnwrap(pokedex.sourceTables)
        XCTAssertTrue(pokedexSources.contains { $0.path == "src/data/pokemon/pokedex_entries.h" && $0.tableSymbol == "gPokedexEntries" && $0.status == .editable && $0.indexedCount == 1 })
        XCTAssertTrue(pokedexSources.contains { $0.path == "src/data/pokemon/pokedex_text.h" && $0.tableSymbol == "g*PokedexText" && $0.status == .editable && $0.indexedCount == 1 })
        XCTAssertTrue(pokedexSources.contains { $0.path == "generated" && $0.status == .blocked })
        XCTAssertTrue(pokedexSources.contains { $0.path == "references/pokeemerald-expansion/src/data/pokemon/pokedex_entries.h" && $0.status == .blocked })
        XCTAssertTrue(pokedexSources.contains { $0.path == "references/pokeemerald-expansion/src/data/pokemon/pokedex_text.h" && $0.status == .blocked })
        XCTAssertTrue(pokedexSources.contains { $0.path == "ROM output" && $0.status == .blocked })

        let json = String(data: try JSONEncoder().encode(expansion), encoding: .utf8) ?? ""
        XCTAssertTrue(json.contains(#""sourceTables""#))
        XCTAssertTrue(json.contains(#""gSpeciesInfo""#))
        XCTAssertTrue(json.contains(#""s*LevelUpLearnset""#))
        XCTAssertTrue(json.contains(#""sTMHMLearnsets\/gTMHMLearnsets""#))
        XCTAssertTrue(json.contains(#""gEggMoves""#))
        XCTAssertTrue(json.contains(#""gTutorLearnsets""#))
        XCTAssertTrue(json.contains(#""gEvolutionTable""#))
        XCTAssertTrue(json.contains(#""FormSpeciesIdTable\/FormChangeTable""#))
        XCTAssertTrue(json.contains(#""src\/data\/pokemon\/all_learnables.json""#))
        XCTAssertTrue(json.contains(#""sourceRole":"generatedAllLearnablesIndex""#))
        XCTAssertTrue(json.contains(#""readiness":"read-only generated context""#))
        XCTAssertTrue(json.contains(#""blockedActions""#))
        XCTAssertTrue(json.contains(#""generated output writes""#))
        XCTAssertTrue(json.contains(#""ROM"#) && json.contains(#"binary writes"#))
        XCTAssertTrue(json.contains(#""include\/config\/species_enabled.h""#))
        XCTAssertTrue(json.contains(#""references\/pokeemerald-expansion\/src\/data\/pokemon\/species_info.h""#))
        XCTAssertTrue(json.contains(#""references\/pokeemerald-expansion\/src\/data\/pokemon\/level_up_learnsets""#))
        XCTAssertTrue(json.contains(#""references\/pokeemerald-expansion\/src\/data\/pokemon\/tmhm_learnsets.h""#))
        XCTAssertTrue(json.contains(#""references\/pokeemerald-expansion\/src\/data\/pokemon\/egg_moves.h""#))
        XCTAssertTrue(json.contains(#""references\/pokeemerald-expansion\/src\/data\/pokemon\/evolution.h""#))
        XCTAssertTrue(json.contains(#""src\/data\/pokemon\/pokedex_entries.h""#))
        XCTAssertTrue(json.contains(#""references\/pokeemerald-expansion\/src\/data\/pokemon\/pokedex_text.h""#))
        XCTAssertTrue(json.contains(#""references\/pokeemerald-expansion\/src\/data\/pokemon\/tutor_learnsets.h""#))
        XCTAssertTrue(json.contains(#""references\/modern-emerald\/src\/data\/pokemon\/species_info.h""#))
        XCTAssertTrue(json.contains(#""references\/modern-emerald\/include\/config.h""#))
        XCTAssertTrue(json.contains(#""references\/modern-emerald\/graphics\/pokemon""#))
        XCTAssertTrue(json.contains(#""references\/modern-emerald\/src\/data\/items.h""#))
        XCTAssertTrue(json.contains(#""references\/modern-emerald\/graphics\/items\/icons""#))
        XCTAssertTrue(json.contains(#""sourceRole":"referenceOnly""#))
        XCTAssertTrue(json.contains(#""recommendedFutureRow":"PHS-T78""#))
    }

    func testExpansionLearnsetCompatibilityWarnsWhenAllLearnablesIsStale() throws {
        let root = try temporaryRoot()
        try writeExpansionSpecies(at: root)
        let generatedDate = Date(timeIntervalSince1970: 1_000)
        let sourceDate = Date(timeIntervalSince1970: 2_000)
        try setModificationDate(generatedDate, for: "src/data/pokemon/all_learnables.json", under: root)
        try setModificationDate(sourceDate, for: "src/data/pokemon/level_up_learnsets/treecko.h", under: root)
        try setModificationDate(sourceDate, for: "src/data/pokemon/tmhm_learnsets.h", under: root)
        try setModificationDate(sourceDate, for: "src/data/pokemon/egg_moves.h", under: root)
        try setModificationDate(sourceDate, for: "src/data/pokemon/tutor_learnsets.h", under: root)
        let index = projectIndex(root: root, profile: .pokeemeraldExpansion)
        let sourceIndex = try ProjectSourceIndexLoader.load(from: index)

        let report = try PokemonDataCompatibilityReportBuilder.build(index: index, sourceIndex: sourceIndex)

        assertNoCompletedRowRecommendations(in: report)
        let levelUp = entry(.levelUpLearnsets, in: report)
        let tmhm = entry(.tmhmLearnsets, in: report)
        let egg = entry(.eggMoves, in: report)
        let tutor = entry(.tutorLearnsets, in: report)
        XCTAssertEqual(levelUp.status, .editable)
        XCTAssertEqual(tmhm.status, .editable)
        XCTAssertEqual(egg.status, .editable)
        XCTAssertEqual(tutor.status, .editable)
        XCTAssertEqual(levelUp.editableCount, 1)
        XCTAssertEqual(tmhm.editableCount, 1)
        XCTAssertEqual(egg.editableCount, 1)
        XCTAssertEqual(tutor.editableCount, 1)
        assertStaleLearnablesDiagnostic(
            in: levelUp,
            sourcePath: "src/data/pokemon/level_up_learnsets/treecko.h",
            surfaceName: "level-up"
        )
        assertStaleLearnablesDiagnostic(
            in: tmhm,
            sourcePath: "src/data/pokemon/tmhm_learnsets.h",
            surfaceName: "TM/HM"
        )
        assertStaleLearnablesDiagnostic(
            in: egg,
            sourcePath: "src/data/pokemon/egg_moves.h",
            surfaceName: "egg-move"
        )
        assertStaleLearnablesDiagnostic(
            in: tutor,
            sourcePath: "src/data/pokemon/tutor_learnsets.h",
            surfaceName: "tutor"
        )
        XCTAssertEqual(report.diagnostics.filter { $0.code == "GBA_EXPANSION_LEARNSET_GENERATED_STALE" }.count, 4)
        let expectedStaleSourcePaths = [
            "src/data/pokemon/egg_moves.h",
            "src/data/pokemon/level_up_learnsets/treecko.h",
            "src/data/pokemon/tmhm_learnsets.h",
            "src/data/pokemon/tutor_learnsets.h"
        ]
        assertBlockedGeneratedLearnsetRows(
            in: levelUp,
            expectedStaleSourceFileCount: 4,
            expectedNewestStaleSourcePath: "src/data/pokemon/egg_moves.h",
            expectedStaleSourcePaths: expectedStaleSourcePaths
        )
        assertBlockedGeneratedLearnsetRows(
            in: tmhm,
            expectedStaleSourceFileCount: 4,
            expectedNewestStaleSourcePath: "src/data/pokemon/egg_moves.h",
            expectedStaleSourcePaths: expectedStaleSourcePaths
        )
        assertBlockedGeneratedLearnsetRows(
            in: egg,
            expectedStaleSourceFileCount: 4,
            expectedNewestStaleSourcePath: "src/data/pokemon/egg_moves.h",
            expectedStaleSourcePaths: expectedStaleSourcePaths
        )
        assertBlockedGeneratedLearnsetRows(
            in: tutor,
            expectedStaleSourceFileCount: 4,
            expectedNewestStaleSourcePath: "src/data/pokemon/egg_moves.h",
            expectedStaleSourcePaths: expectedStaleSourcePaths
        )
    }

    func testExpansionLearnsetCompatibilityDoesNotWarnWhenAllLearnablesIsFresh() throws {
        let root = try temporaryRoot()
        try writeExpansionSpecies(at: root)
        let sourceDate = Date(timeIntervalSince1970: 1_000)
        let generatedDate = Date(timeIntervalSince1970: 2_000)
        try setModificationDate(sourceDate, for: "src/data/pokemon/level_up_learnsets/treecko.h", under: root)
        try setModificationDate(sourceDate, for: "src/data/pokemon/tmhm_learnsets.h", under: root)
        try setModificationDate(sourceDate, for: "src/data/pokemon/egg_moves.h", under: root)
        try setModificationDate(sourceDate, for: "src/data/pokemon/tutor_learnsets.h", under: root)
        try setModificationDate(generatedDate, for: "src/data/pokemon/all_learnables.json", under: root)
        let index = projectIndex(root: root, profile: .pokeemeraldExpansion)
        let sourceIndex = try ProjectSourceIndexLoader.load(from: index)

        let report = try PokemonDataCompatibilityReportBuilder.build(index: index, sourceIndex: sourceIndex)

        let levelUp = entry(.levelUpLearnsets, in: report)
        let tmhm = entry(.tmhmLearnsets, in: report)
        let egg = entry(.eggMoves, in: report)
        let tutor = entry(.tutorLearnsets, in: report)
        XCTAssertEqual(levelUp.status, .editable)
        XCTAssertEqual(tmhm.status, .editable)
        XCTAssertEqual(egg.status, .editable)
        XCTAssertEqual(tutor.status, .editable)
        XCTAssertEqual(levelUp.editableCount, 1)
        XCTAssertEqual(tmhm.editableCount, 1)
        XCTAssertEqual(egg.editableCount, 1)
        XCTAssertEqual(tutor.editableCount, 1)
        XCTAssertFalse(levelUp.diagnostics.contains { $0.code == "GBA_EXPANSION_LEARNSET_GENERATED_STALE" })
        XCTAssertFalse(tmhm.diagnostics.contains { $0.code == "GBA_EXPANSION_LEARNSET_GENERATED_STALE" })
        XCTAssertFalse(egg.diagnostics.contains { $0.code == "GBA_EXPANSION_LEARNSET_GENERATED_STALE" })
        XCTAssertFalse(tutor.diagnostics.contains { $0.code == "GBA_EXPANSION_LEARNSET_GENERATED_STALE" })
        XCTAssertFalse(report.diagnostics.contains { $0.code == "GBA_EXPANSION_LEARNSET_GENERATED_STALE" })
    }

    func testExpansionAllLearnablesCoverageCountsGeneratedSourceAndMoveMismatches() throws {
        let root = try temporaryRoot()
        try writeExpansionSpecies(at: root)
        let levelUpPath = "src/data/pokemon/level_up_learnsets/treecko.h"
        let levelUpURL = root.appendingPathComponent(levelUpPath)
        var levelUpText = try String(contentsOf: levelUpURL, encoding: .utf8)
        levelUpText +=
            """

            static const u16 sGrovyleLevelUpLearnset[] = {
                LEVEL_UP_MOVE( 1, MOVE_POUND),
                LEVEL_UP_END
            };
            """
        try write(levelUpText, to: levelUpURL)
        try write(
            """
            {
              "SPECIES_TREECKO": [
                "MOVE_POUND",
                "MOVE_ABSORB",
                "MOVE_BULLET_SEED",
                "MOVE_CRUNCH",
                "MOVE_LEECH_SEED",
                "MOVE_MEGA_PUNCH",
                "MOVE_QUICK_ATTACK"
              ],
              "TREECKO_GENERATED": [
                "MOVE_SPLASH"
              ]
            }
            """,
            to: root.appendingPathComponent("src/data/pokemon/all_learnables.json")
        )
        let oldDate = Date(timeIntervalSince1970: 1_000)
        let generatedDate = Date(timeIntervalSince1970: 2_000)
        let staleDate = Date(timeIntervalSince1970: 3_000)
        try setModificationDate(generatedDate, for: "src/data/pokemon/all_learnables.json", under: root)
        try setModificationDate(staleDate, for: levelUpPath, under: root)
        try setModificationDate(oldDate, for: "src/data/pokemon/tmhm_learnsets.h", under: root)
        try setModificationDate(oldDate, for: "src/data/pokemon/egg_moves.h", under: root)
        try setModificationDate(oldDate, for: "src/data/pokemon/tutor_learnsets.h", under: root)
        let index = projectIndex(root: root, profile: .pokeemeraldExpansion)
        let sourceIndex = try ProjectSourceIndexLoader.load(from: index)
        let report = try PokemonDataCompatibilityReportBuilder.build(index: index, sourceIndex: sourceIndex)

        let levelUp = entry(.levelUpLearnsets, in: report)
        assertBlockedGeneratedLearnsetRows(
            in: levelUp,
            expectedIndexedCount: 2,
            expectedGeneratedSpeciesCount: 2,
            expectedParsedSourceSpeciesCount: 2,
            expectedMatchingSpeciesCount: 0,
            expectedMismatchSpeciesCount: 3,
            expectedGeneratedOnlySpeciesCount: 1,
            expectedSourceOnlySpeciesCount: 1,
            expectedMoveMismatchSpeciesCount: 1,
            expectedStaleSourceFileCount: 1,
            expectedNewestStaleSourcePath: levelUpPath,
            expectedStaleSourcePaths: [levelUpPath],
            expectedDisagreementCount: 3
        )
        let allLearnablesCoverage = try XCTUnwrap(
            levelUp.sourceTables?.first { $0.path == "src/data/pokemon/all_learnables.json" }?.learnablesCoverage
        )
        XCTAssertEqual(allLearnablesCoverage.staleSourcePaths, [levelUpPath])
        let regenerationPlan = try XCTUnwrap(allLearnablesCoverage.regenerationPlan)
        XCTAssertEqual(regenerationPlan.posture, "copyReportOnly")
        XCTAssertEqual(regenerationPlan.generatedPath, "src/data/pokemon/all_learnables.json")
        XCTAssertEqual(regenerationPlan.sourceBuckets, ["levelUp", "tmhm", "tutor", "egg"])
        XCTAssertEqual(regenerationPlan.bucketPaths.map(\.bucket), ["levelUp", "tmhm", "tutor", "egg"])
        XCTAssertEqual(regenerationPlan.bucketPaths.flatMap(\.paths), [
            "src/data/pokemon/level_up_learnsets.h",
            "src/data/pokemon/level_up_learnsets",
            "src/data/pokemon/tmhm_learnsets.h",
            "src/data/pokemon/tutor_learnsets.h",
            "src/data/pokemon/egg_moves.h"
        ])
        XCTAssertEqual(regenerationPlan.generatedOnlyMoveIDs, ["MOVE_QUICK_ATTACK", "MOVE_SPLASH"])
        XCTAssertEqual(regenerationPlan.sourceOnlyMoveIDs, ["MOVE_POUND", "MOVE_SWORD_DANCE"])
        XCTAssertEqual(regenerationPlan.reviewItems.map(\.speciesID), [
            "SPECIES_GROVYLE",
            "SPECIES_TREECKO",
            "SPECIES_TREECKO_GENERATED"
        ])
        let treeckoReviewItem = try XCTUnwrap(regenerationPlan.reviewItems.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(treeckoReviewItem.status, .moveMismatch)
        XCTAssertEqual(treeckoReviewItem.generatedOnlyMoves, ["MOVE_QUICK_ATTACK"])
        XCTAssertEqual(treeckoReviewItem.sourceOnlyMoves.map(\.move), ["MOVE_SWORD_DANCE"])
        XCTAssertEqual(treeckoReviewItem.sourceOnlyMoves.first?.bucket, "tutor")
        XCTAssertEqual(treeckoReviewItem.sourceOnlyMoves.first?.sourceSpan.relativePath, "src/data/pokemon/tutor_learnsets.h")
        XCTAssertEqual(treeckoReviewItem.sourceOnlyMoves.first?.sourceSpan.startLine, 3)
        XCTAssertEqual(regenerationPlan.reportCommands, [
            "swift run --package-path PokemonHackStudio pokemonhack-cli pokemon-compatibility <project-root> --json",
            "swift run --package-path PokemonHackStudio pokemonhack-cli asset-index <project-root> --json"
        ])
        XCTAssertTrue(regenerationPlan.reviewGuidance.contains("outside PokemonHackStudio"))
        XCTAssertTrue(regenerationPlan.reviewGuidance.contains("will not run regeneration"))
        XCTAssertEqual(allLearnablesCoverage.disagreements.map(\.speciesID), [
            "SPECIES_GROVYLE",
            "SPECIES_TREECKO",
            "SPECIES_TREECKO_GENERATED"
        ])
        let sourceOnly = try XCTUnwrap(allLearnablesCoverage.disagreements.first { $0.speciesID == "SPECIES_GROVYLE" })
        XCTAssertEqual(sourceOnly.status, .sourceOnly)
        XCTAssertEqual(sourceOnly.generatedOnlyMoves, [])
        XCTAssertEqual(sourceOnly.sourceOnlyMoves.map(\.move), ["MOVE_POUND"])
        XCTAssertEqual(sourceOnly.sourceOnlyMoves.first?.bucket, "levelUp")
        XCTAssertEqual(sourceOnly.sourceOnlyMoves.first?.sourceSpan.relativePath, levelUpPath)
        XCTAssertEqual(sourceOnly.sourceOnlyMoves.first?.sourceSpan.startLine, 7)
        XCTAssertEqual(sourceOnly.contributingSourcePaths, [levelUpPath])

        let moveMismatch = try XCTUnwrap(allLearnablesCoverage.disagreements.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(moveMismatch.status, .moveMismatch)
        XCTAssertEqual(moveMismatch.generatedOnlyMoves, ["MOVE_QUICK_ATTACK"])
        XCTAssertEqual(moveMismatch.sourceOnlyMoves.map(\.move), ["MOVE_SWORD_DANCE"])
        XCTAssertEqual(moveMismatch.sourceOnlyMoves.first?.bucket, "tutor")
        XCTAssertEqual(moveMismatch.sourceOnlyMoves.first?.sourceSpan.relativePath, "src/data/pokemon/tutor_learnsets.h")
        XCTAssertEqual(moveMismatch.sourceOnlyMoves.first?.sourceSpan.startLine, 3)
        XCTAssertEqual(moveMismatch.contributingSourcePaths, ["src/data/pokemon/tutor_learnsets.h"])

        let generatedOnly = try XCTUnwrap(allLearnablesCoverage.disagreements.first { $0.speciesID == "SPECIES_TREECKO_GENERATED" })
        XCTAssertEqual(generatedOnly.status, .generatedOnly)
        XCTAssertEqual(generatedOnly.generatedOnlyMoves, ["MOVE_SPLASH"])
        XCTAssertEqual(generatedOnly.sourceOnlyMoves, [])
        XCTAssertEqual(generatedOnly.contributingSourcePaths, [])

        let allLearnablesRecord = try XCTUnwrap(sourceIndex.records.first {
            $0.module == .learnsets
                && $0.title == "SPECIES_TREECKO"
                && $0.sourceSpan.relativePath == "src/data/pokemon/all_learnables.json"
        })
        XCTAssertEqual(allLearnablesRecord.facts.first { $0.label == "Coverage Status" }?.value, "moveMismatch")
        XCTAssertEqual(allLearnablesRecord.facts.first { $0.label == "Parsed Source Moves" }?.value, "7")
        XCTAssertEqual(allLearnablesRecord.facts.first { $0.label == "Missing Generated Moves" }?.value, "1")
        XCTAssertEqual(allLearnablesRecord.facts.first { $0.label == "Extra Generated Moves" }?.value, "1")
        XCTAssertEqual(allLearnablesRecord.facts.first { $0.label == "Missing Generated Move IDs" }?.value, "MOVE_SWORD_DANCE")
        XCTAssertEqual(allLearnablesRecord.facts.first { $0.label == "Extra Generated Move IDs" }?.value, "MOVE_QUICK_ATTACK")
        XCTAssertEqual(allLearnablesRecord.facts.first { $0.label == "Generated Species" }?.value, "2")
        XCTAssertEqual(allLearnablesRecord.facts.first { $0.label == "Parsed Source Species" }?.value, "2")
        XCTAssertEqual(allLearnablesRecord.facts.first { $0.label == "Coverage Matches" }?.value, "0")
        XCTAssertEqual(allLearnablesRecord.facts.first { $0.label == "Coverage Mismatches" }?.value, "3")
        XCTAssertEqual(allLearnablesRecord.facts.first { $0.label == "Generated-only Species" }?.value, "1")
        XCTAssertEqual(allLearnablesRecord.facts.first { $0.label == "Source-only Species" }?.value, "1")
        XCTAssertEqual(allLearnablesRecord.facts.first { $0.label == "Move-set Mismatches" }?.value, "1")
        XCTAssertEqual(allLearnablesRecord.facts.first { $0.label == "Stale Source Files" }?.value, "1")
        XCTAssertEqual(allLearnablesRecord.facts.first { $0.label == "Newest Stale Source" }?.value, levelUpPath)
        XCTAssertEqual(allLearnablesRecord.facts.first { $0.label == "Regeneration Posture" }?.value, "copy/report-only; no generated JSON writes or command execution")
        XCTAssertEqual(allLearnablesRecord.facts.first { $0.label == "Regeneration Source Buckets" }?.value, "levelUp, tmhm, tutor, egg")
        XCTAssertEqual(allLearnablesRecord.facts.first { $0.label == "Regeneration Source Paths" }?.value, "src/data/pokemon/level_up_learnsets.h; src/data/pokemon/level_up_learnsets; src/data/pokemon/tmhm_learnsets.h; src/data/pokemon/tutor_learnsets.h; src/data/pokemon/egg_moves.h")
        XCTAssertEqual(allLearnablesRecord.facts.first { $0.label == "Regeneration Source-only Move IDs" }?.value, "MOVE_POUND, MOVE_SWORD_DANCE")
        XCTAssertEqual(allLearnablesRecord.facts.first { $0.label == "Regeneration Generated-only Move IDs" }?.value, "MOVE_QUICK_ATTACK, MOVE_SPLASH")
        XCTAssertTrue(allLearnablesRecord.facts.first { $0.label == "Regeneration Report Commands" }?.value.contains("pokemon-compatibility <project-root> --json") == true)
        XCTAssertTrue(allLearnablesRecord.facts.first { $0.label == "Regeneration Guidance" }?.value.contains("will not run regeneration") == true)
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
        XCTAssertEqual(cries.blockedReason, "No existing local files matched sound/direct_sound_samples/cries/*. No existing local files matched sound/songs/mus_cry*.s or sound/songs/mus_cry*.inc.")
        let plan = try XCTUnwrap(cries.cryAudioPlan)
        XCTAssertEqual(plan.status, .blocked)
        XCTAssertEqual(plan.candidateSourcePaths, [
            "sound/direct_sound_samples/cries/*",
            "sound/songs/mus_cry*.s",
            "sound/songs/mus_cry*.inc"
        ])
        XCTAssertEqual(plan.replacementGate?.status, .blocked)
        XCTAssertEqual(plan.blockedReasons, [
            "No existing local files matched sound/direct_sound_samples/cries/*.",
            "No existing local files matched sound/songs/mus_cry*.s or sound/songs/mus_cry*.inc."
        ])
        XCTAssertTrue(plan.replacementConstraints.contains("Replacement must be one-for-one with the same project-relative path and source kind."))
        XCTAssertTrue(plan.replacementConstraints.contains("Missing cry source insertion and directory creation are disabled."))
        XCTAssertTrue(plan.blockedActions.contains("Audio conversion"))
        XCTAssertTrue(plan.blockedActions.contains("Generated audio output writes"))
        XCTAssertTrue(plan.blockedActions.contains("Playback"))
        XCTAssertTrue(plan.blockedActions.contains("ROM export"))
        XCTAssertTrue(plan.blockedActions.contains("Binary mutation"))
        XCTAssertTrue(plan.blockedActions.contains("Source mutation apply"))
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
        XCTAssertEqual(plan.sourceFiles.map(\.kind), [
            "directSoundCrySample",
            "crySongAssembly"
        ])
        XCTAssertEqual(plan.sourceFiles.map(\.sizeBytes), [4, 9])
        XCTAssertEqual(plan.sourceFiles[0].sha1, pokemonHackSHA1Hex(Data([0x01, 0x02, 0x03, 0x04])))
        XCTAssertEqual(plan.sourceFiles[1].sha1, pokemonHackSHA1Hex(Data("cry song\n".utf8)))
        XCTAssertEqual(plan.candidateSourcePaths, [
            "sound/direct_sound_samples/cries/*",
            "sound/songs/mus_cry*.s",
            "sound/songs/mus_cry*.inc"
        ])
        XCTAssertTrue(plan.replacementConstraints.contains("Replacement is future-only and must target an existing local source file reported in sourceFiles."))
        XCTAssertTrue(plan.replacementConstraints.contains("Replacement must be one-for-one with the same project-relative path and source kind."))
        XCTAssertTrue(plan.replacementConstraints.contains("Generated audio outputs, build artifacts, ROM targets, binary mutation, playback, and source mutation apply are disabled."))
        XCTAssertEqual(plan.replacementGate?.status, .readOnly)
        XCTAssertEqual(plan.replacementGate?.targetPaths, [
            "sound/direct_sound_samples/cries/treecko.aif",
            "sound/songs/mus_cry_treecko.s"
        ])
        XCTAssertEqual(plan.blockedReasons, [])
        XCTAssertTrue(plan.plannedChanges.contains("Keep generated audio artifacts and ROM output unchanged."))
        XCTAssertTrue(plan.blockedActions.contains("Audio conversion"))
        XCTAssertTrue(plan.blockedActions.contains("Generated audio output writes"))
        XCTAssertTrue(plan.blockedActions.contains("Playback"))
        XCTAssertTrue(plan.blockedActions.contains("ROM export"))
        XCTAssertTrue(plan.blockedActions.contains("Binary mutation"))
        XCTAssertTrue(plan.blockedActions.contains("Source mutation apply"))
        XCTAssertTrue(cries.diagnostics.contains { $0.code == "GBA_CRY_AUDIO_PLAN_PREVIEW_ONLY" })
    }

    func testRubySapphireCryAudioCompatibilityReportsEditableReplacementGate() throws {
        let root = try temporaryRoot()
        try write(Data([0x01, 0x02, 0x03, 0x04]), to: root.appendingPathComponent("sound/direct_sound_samples/cries/treecko.aif"))
        try write("cry song\n", to: root.appendingPathComponent("sound/songs/mus_cry_treecko.s"))

        let report = try PokemonDataCompatibilityReportBuilder.build(
            index: projectIndex(root: root, profile: .pokeruby),
            sourceIndex: sourceIndex(profile: .pokeruby, itemPath: "src/data/items_en.h")
        )

        let cries = entry(.cries, in: report)
        XCTAssertEqual(cries.status, .editable)
        XCTAssertEqual(cries.indexedCount, 2)
        XCTAssertEqual(cries.editableCount, 2)
        XCTAssertEqual(cries.readOnlyCount, 0)
        XCTAssertNil(cries.recommendedFutureRow)
        XCTAssertNil(cries.blockedReason)
        XCTAssertFalse(cries.unsupportedFields.contains("source mutation apply"))
        XCTAssertTrue(cries.unsupportedFields.contains("audio conversion"))
        XCTAssertTrue(cries.unsupportedFields.contains("generated audio output writes"))
        XCTAssertTrue(cries.unsupportedFields.contains("reference writes"))

        let plan = try XCTUnwrap(cries.cryAudioPlan)
        XCTAssertEqual(plan.status, .previewOnly)
        XCTAssertEqual(plan.replacementGate?.status, .editable)
        XCTAssertEqual(plan.replacementGate?.targetPaths, [
            "sound/direct_sound_samples/cries/treecko.aif",
            "sound/songs/mus_cry_treecko.s"
        ])
        XCTAssertTrue(plan.replacementConstraints.contains("Replacement must target an existing local Ruby/Sapphire source file reported in sourceFiles."))
        XCTAssertTrue(plan.replacementConstraints.contains("Generated audio outputs, build artifacts, ROM targets, binary mutation, playback, source generation, reference writes, and broad audio schema rewrites are disabled."))
        XCTAssertTrue(plan.blockedActions.contains("Audio conversion"))
        XCTAssertTrue(plan.blockedActions.contains("Generated audio output writes"))
        XCTAssertTrue(plan.blockedActions.contains("Source generation"))
        XCTAssertTrue(plan.blockedActions.contains("Reference writes"))
        XCTAssertFalse(plan.blockedActions.contains("Source mutation apply"))
        XCTAssertTrue(cries.diagnostics.contains { $0.code == "GBA_CRY_AUDIO_REPLACEMENT_GATE_EDITABLE" })
    }

    func testFormsCompatibilityReportsEditableLocalRowsWhileBlockingAdjacentWorkflows() throws {
        let report = try PokemonDataCompatibilityReportBuilder.build(
            index: projectIndex(profile: .pokeemeraldExpansion),
            sourceIndex: formSourceIndex(profile: .pokeemeraldExpansion)
        )

        let forms = entry(.forms, in: report)
        XCTAssertEqual(forms.status, .editable)
        XCTAssertEqual(forms.sourcePath, "src/data/pokemon/form_species_tables.h")
        XCTAssertEqual(forms.tableSymbol, "FormSpeciesIdTable/FormChangeTable")
        XCTAssertEqual(forms.indexedCount, 3)
        XCTAssertEqual(forms.editableCount, 2)
        XCTAssertEqual(forms.readOnlyCount, 1)
        XCTAssertNil(forms.recommendedFutureRow)
        XCTAssertNil(forms.blockedReason)
        XCTAssertTrue(forms.unsupportedFields.contains("form row insertion/removal/reorder"))
        XCTAssertTrue(forms.unsupportedFields.contains("unsupported form change tuple shapes"))
        XCTAssertTrue(forms.unsupportedFields.contains("form graphics sync"))
        XCTAssertTrue(forms.unsupportedFields.contains("generated family supplement apply"))
        XCTAssertTrue(forms.unsupportedFields.contains("reference-only form source writes"))
        XCTAssertTrue(forms.unsupportedFields.contains("ROM/export/build outputs"))
        XCTAssertTrue(forms.unsupportedFields.contains("binary-only form table writes"))
        XCTAssertTrue(forms.diagnostics.contains { $0.code == "GBA_FORMS_SOURCE_GRAPH_DETECTED" })
        XCTAssertTrue(forms.diagnostics.contains { $0.code == "GBA_FORMS_ADJACENT_WORKFLOWS_BLOCKED" })
        let sourceTables = try XCTUnwrap(forms.sourceTables)
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/pokemon/form_species_tables.h" && $0.indexedCount == 1 && $0.status == .editable })
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/pokemon/form_change_tables.h" && $0.indexedCount == 1 && $0.status == .editable })
        XCTAssertTrue(sourceTables.contains { $0.path == "src/data/pokemon/species_info/" && $0.indexedCount == 1 && $0.status == .readOnly })
        XCTAssertTrue(sourceTables.contains { $0.path == "generated" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "references/pokeemerald-expansion/src/data/pokemon/form_species_tables.h" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "references/pokeemerald-expansion/src/data/pokemon/form_change_tables.h" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "graphics/pokemon" && $0.status == .blocked })
        XCTAssertTrue(sourceTables.contains { $0.path == "ROM output" && $0.status == .blocked })
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

    private func assertStaleLearnablesDiagnostic(
        in entry: PokemonDataCompatibilityEntry,
        sourcePath: String,
        surfaceName: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let diagnostic = entry.diagnostics.first { $0.code == "GBA_EXPANSION_LEARNSET_GENERATED_STALE" }
        XCTAssertEqual(diagnostic?.severity, .warning, file: file, line: line)
        XCTAssertEqual(diagnostic?.span?.relativePath, sourcePath, file: file, line: line)
        XCTAssertTrue(diagnostic?.message.contains(surfaceName) == true, file: file, line: line)
        XCTAssertTrue(diagnostic?.message.contains(sourcePath) == true, file: file, line: line)
        XCTAssertTrue(diagnostic?.message.contains("src/data/pokemon/all_learnables.json") == true, file: file, line: line)
    }

    private func assertBlockedGeneratedLearnsetRows(
        in entry: PokemonDataCompatibilityEntry,
        expectedIndexedCount: Int = 1,
        expectedGeneratedSpeciesCount: Int = 1,
        expectedParsedSourceSpeciesCount: Int = 1,
        expectedMatchingSpeciesCount: Int = 1,
        expectedMismatchSpeciesCount: Int = 0,
        expectedGeneratedOnlySpeciesCount: Int = 0,
        expectedSourceOnlySpeciesCount: Int = 0,
        expectedMoveMismatchSpeciesCount: Int = 0,
        expectedStaleSourceFileCount: Int = 0,
        expectedNewestStaleSourcePath: String? = nil,
        expectedStaleSourcePaths: [String] = [],
        expectedDisagreementCount: Int = 0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sourceTables = entry.sourceTables ?? []
        let allLearnables = sourceTables.first { $0.path == "src/data/pokemon/all_learnables.json" }
        XCTAssertEqual(allLearnables?.status, .blocked, file: file, line: line)
        XCTAssertEqual(allLearnables?.indexedCount, expectedIndexedCount, file: file, line: line)
        XCTAssertEqual(allLearnables?.sourceRole, "generatedAllLearnablesIndex", file: file, line: line)
        XCTAssertEqual(allLearnables?.readiness, "read-only generated context", file: file, line: line)
        XCTAssertEqual(allLearnables?.relatedSourcePaths, [
            "src/data/pokemon/level_up_learnsets.h",
            "src/data/pokemon/level_up_learnsets",
            "src/data/pokemon/tmhm_learnsets.h",
            "src/data/pokemon/tutor_learnsets.h",
            "src/data/pokemon/egg_moves.h"
        ], file: file, line: line)
        XCTAssertEqual(allLearnables?.blockedActions, [
            "apply",
            "generated output writes",
            "reference writes",
            "ROM/binary writes"
        ], file: file, line: line)
        XCTAssertEqual(allLearnables?.learnablesCoverage?.generatedSpeciesCount, expectedGeneratedSpeciesCount)
        XCTAssertEqual(allLearnables?.learnablesCoverage?.parsedSourceSpeciesCount, expectedParsedSourceSpeciesCount)
        XCTAssertEqual(allLearnables?.learnablesCoverage?.matchingSpeciesCount, expectedMatchingSpeciesCount)
        XCTAssertEqual(allLearnables?.learnablesCoverage?.mismatchSpeciesCount, expectedMismatchSpeciesCount)
        XCTAssertEqual(allLearnables?.learnablesCoverage?.generatedOnlySpeciesCount, expectedGeneratedOnlySpeciesCount)
        XCTAssertEqual(allLearnables?.learnablesCoverage?.sourceOnlySpeciesCount, expectedSourceOnlySpeciesCount)
        XCTAssertEqual(allLearnables?.learnablesCoverage?.moveMismatchSpeciesCount, expectedMoveMismatchSpeciesCount)
        XCTAssertEqual(allLearnables?.learnablesCoverage?.staleSourceFileCount, expectedStaleSourceFileCount)
        XCTAssertEqual(allLearnables?.learnablesCoverage?.newestStaleSourcePath, expectedNewestStaleSourcePath)
        XCTAssertEqual(allLearnables?.learnablesCoverage?.staleSourcePaths, expectedStaleSourcePaths)
        XCTAssertEqual(allLearnables?.learnablesCoverage?.disagreements.count, expectedDisagreementCount)
        XCTAssertTrue(allLearnables?.note?.contains("context and freshness reporting only") == true, file: file, line: line)
        XCTAssertTrue(allLearnables?.note?.contains("refresh must happen outside PokemonHackStudio") == true, file: file, line: line)
        XCTAssertTrue(sourceTables.contains { $0.path == "generated" && $0.status == .blocked }, file: file, line: line)
        XCTAssertTrue(sourceTables.contains { $0.path.hasPrefix("references/pokeemerald-expansion/") && $0.status == .blocked }, file: file, line: line)
        XCTAssertTrue(sourceTables.contains { $0.path == "ROM output" && $0.status == .blocked }, file: file, line: line)
    }

    private func assertModernEmeraldSource(
        in sourceTables: [PokemonDataCompatibilitySourceTable],
        path: String,
        tableSymbol: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            sourceTables.contains { table in
                table.path == path
                    && table.tableSymbol == tableSymbol
                    && table.status == .blocked
                    && table.sourceRole == "referenceOnly"
                    && table.recommendedFutureRow == "PHS-T78"
            },
            "Expected blocked Modern Emerald reference-only source table at \(path).",
            file: file,
            line: line
        )
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
        try write(
            """
            static const u8 sPotionDesc[] = _(
                "Restores HP.");
            """,
            to: root.appendingPathComponent("src/data/item_descriptions_en.h")
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
            const struct Evolution gEvolutionTable[NUM_SPECIES][EVOS_PER_MON] =
            {
                [SPECIES_TREECKO] = {{EVO_LEVEL, 16, SPECIES_TREECKO}},
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/evolution.h")
        )
        try write(
            """
            const u16 *gLevelUpLearnsets[] =
            {
                gTreeckoLevelUpLearnset,
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/level_up_learnset_pointers.h")
        )
        try write(
            """
            const u16 gTreeckoLevelUpLearnset[] = {
                LEVEL_UP_MOVE( 1, MOVE_POUND),
                LEVEL_UP_END
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/level_up_learnsets.h")
        )
        try write(
            """
            union TMHMLearnset gTMHMLearnsets[NUM_SPECIES] =
            {
                [SPECIES_TREECKO] = { .learnset = { .BULLET_SEED = TRUE } },
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/tmhm_learnsets.h")
        )
        try write(
            """
            const u16 gEggMoves[] = {
                egg_moves(TREECKO,
                          MOVE_CRUNCH),
                EGG_MOVES_TERMINATOR
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/egg_moves.h")
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
        try write("#define ITEM_NONE 0\n#define ITEM_TM09_BULLET_SEED ITEM_TM09\n", to: root.appendingPathComponent("include/constants/items.h"))
        try write("#define MOVE_POUND 1\n#define MOVE_BULLET_SEED 4\n#define MOVE_CRUNCH 8\n#define MOVE_LEECH_SEED 9\n", to: root.appendingPathComponent("include/constants/moves.h"))
    }

    private func writeRubyTutorLearnsets(at root: URL) throws {
        try write(
            """
            const u16 gTutorLearnsets[] =
            {
                [SPECIES_TREECKO] = (TUTOR(MEGA_PUNCH) | TUTOR(SWORD_DANCE)),
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/tutor_learnsets.h")
        )
    }

    private func writeRubyMoves(at root: URL) throws {
        try write(
            """
            static const u8 gMoveDescription_Tackle[] = _("A physical attack.");

            const struct BattleMove gBattleMoves[] =
            {
                [MOVE_TACKLE] =
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
                    .description = gMoveDescription_Tackle,
                    .contestEffect = CONTEST_EFFECT_NONE,
                },
            };
            """,
            to: root.appendingPathComponent("src/data/battle_moves.c")
        )
        try write(
            """
            const struct ContestMove gContestMoves[MOVES_COUNT] =
            {
                [MOVE_TACKLE] =
                {
                    .effect = CONTEST_EFFECT_HIGHLY_APPEALING,
                    .contestCategory = CONTEST_CATEGORY_TOUGH,
                    .comboStarterId = COMBO_STARTER_TACKLE,
                    .comboMoves = { COMBO_STARTER_GROWL, COMBO_STARTER_POUND },
                },
            };
            """,
            to: root.appendingPathComponent("src/data/contest_moves.h")
        )
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
                    .holdEffect = HOLD_EFFECT_NONE,
                    .holdEffectParam = 20,
                    .description = COMPOUND_STRING("Restores HP."),
                    .pocket = POCKET_ITEMS,
                    .importance = 0,
                    .registrability = 0,
                    .sortType = ITEM_TYPE_HEALTH_RECOVERY,
                    .type = ITEM_USE_PARTY_MENU,
                    .exitsBagOnUse = FALSE,
                    .effect = ITEM_EFFECT_HEAL,
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
                    .contestAppeal = 2,
                    .contestJam = 1,
                    .contestComboStarterId = COMBO_STARTER_POUND,
                    .contestComboMoves = { MOVE_DOUBLE_SLAP, MOVE_MEGA_PUNCH },
                },
            };
            """,
            to: root.appendingPathComponent("src/data/moves_info.h")
        )
        try write(
            """
            static const u8 sPoundDescription[] = _("Pounds with forelegs.");

            """,
            to: root.appendingPathComponent("src/data/text/move_descriptions.h")
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
                [SPECIES_GROVYLE] = { .baseHP = 50 },
                [SPECIES_TREECKO_MEGA] = { .baseHP = 70 },
                [SPECIES_TREECKO_PRIMAL] = { .baseHP = 80 },
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
        try write(
            """
            static const u16 sTreeckoLevelUpLearnset[] = {
                LEVEL_UP_MOVE( 1, MOVE_POUND),
                LEVEL_UP_MOVE( 6, MOVE_ABSORB),
                LEVEL_UP_END
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/level_up_learnsets/treecko.h")
        )
        try write(
            """
            const struct TMHMLearnset sTMHMLearnsets[] =
            {
                [SPECIES_TREECKO] = { .learnset = { .BULLET_SEED = TRUE } },
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/tmhm_learnsets.h")
        )
        try write(
            """
            const u16 gTutorLearnsets[] =
            {
                [SPECIES_TREECKO] = (TUTOR(MEGA_PUNCH) | TUTOR(SWORD_DANCE)),
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/tutor_learnsets.h")
        )
        try write(
            """
            const u16 gEggMoves[] = {
                egg_moves(TREECKO,
                          MOVE_CRUNCH,
                          MOVE_LEECH_SEED),
                EGG_MOVES_TERMINATOR
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/egg_moves.h")
        )
        try write(
            """
            const struct PokedexEntry gPokedexEntries[] =
            {
                [NATIONAL_DEX_TREECKO] =
                {
                    .categoryName = _("WOOD GECKO"),
                    .height = 5,
                    .weight = 50,
                    .description = gTreeckoPokedexText,
                    .pokemonScale = 256,
                    .pokemonOffset = 0,
                    .trainerScale = 256,
                    .trainerOffset = 0,
                },
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/pokedex_entries.h")
        )
        try write("const u8 gTreeckoPokedexText[] = _(\"Wood gecko.\");\n", to: root.appendingPathComponent("src/data/pokemon/pokedex_text.h"))
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
            {
              "SPECIES_TREECKO": [
                "MOVE_POUND",
                "MOVE_ABSORB",
                "MOVE_BULLET_SEED",
                "MOVE_CRUNCH",
                "MOVE_LEECH_SEED",
                "MOVE_MEGA_PUNCH",
                "MOVE_SWORD_DANCE"
              ]
            }
            """,
            to: root.appendingPathComponent("src/data/pokemon/all_learnables.json")
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

    private func setModificationDate(_ date: Date, for relativePath: String, under root: URL) throws {
        try FileManager.default.setAttributes(
            [.modificationDate: date],
            ofItemAtPath: root.appendingPathComponent(relativePath).path
        )
    }
}
