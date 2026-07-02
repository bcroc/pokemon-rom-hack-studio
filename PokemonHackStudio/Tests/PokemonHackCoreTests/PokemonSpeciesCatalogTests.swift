import XCTest
@testable import PokemonHackCore

final class PokemonSpeciesCatalogTests: XCTestCase {
    func testSpeciesCatalogBuildsStatsLearnsetsPokedexAndAssets() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)

        let index = try GameAdapterRegistry.index(path: root.path)
        let catalog = try ProjectSpeciesCatalogBuilder.build(index: index)

        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(treecko.displayName, "Treecko")
        XCTAssertEqual(treecko.baseStats.hp, 40)
        XCTAssertEqual(treecko.baseStats.attack, 45)
        XCTAssertEqual(treecko.baseStats.total, 310)
        XCTAssertEqual(treecko.types, ["TYPE_GRASS", "TYPE_GRASS"])
        XCTAssertEqual(treecko.abilities, ["ABILITY_OVERGROW", "ABILITY_NONE"])
        XCTAssertEqual(treecko.evYield.speed, 1)
        XCTAssertEqual(treecko.evYield.total, 1)
        XCTAssertEqual(treecko.training.catchRate, "45")
        XCTAssertEqual(treecko.training.expYield, "65")
        XCTAssertEqual(treecko.training.growthRate, "GROWTH_MEDIUM_SLOW")
        XCTAssertEqual(treecko.breeding.eggGroups, ["EGG_GROUP_MONSTER", "EGG_GROUP_DRAGON"])
        XCTAssertEqual(treecko.learnsets.levelUp.map(\.move), ["MOVE_POUND", "MOVE_LEER", "MOVE_ABSORB"])
        XCTAssertEqual(treecko.learnsets.levelUp.map(\.level), [1, 1, 6])
        XCTAssertEqual(treecko.learnsets.tmhm.map(\.move), ["MOVE_BULLET_SEED", "MOVE_CUT"])
        XCTAssertEqual(treecko.learnsets.egg.map(\.move), ["MOVE_CRUNCH", "MOVE_LEECH_SEED"])
        XCTAssertEqual(treecko.learnsets.tutor.map(\.move).sorted(), ["MOVE_MEGA_PUNCH", "MOVE_SWORD_DANCE"])
        XCTAssertEqual(treecko.evolutions.first?.method, "EVO_LEVEL")
        XCTAssertEqual(treecko.evolutions.first?.parameter, "16")
        XCTAssertEqual(treecko.evolutions.first?.targetSpecies, "SPECIES_GROVYLE")
        XCTAssertEqual(treecko.pokedex?.categoryName, "WOOD GECKO")
        XCTAssertEqual(treecko.pokedex?.height, "5")
        XCTAssertEqual(treecko.pokedex?.weight, "50")
        XCTAssertEqual(treecko.pokedex?.pokemonScale, "256")
        XCTAssertEqual(treecko.pokedex?.pokemonOffset, "0")
        XCTAssertTrue(treecko.pokedex?.description?.contains("protector of the forest") == true)
        XCTAssertTrue(treecko.assets.contains { $0.kind == .front && $0.exists })
        XCTAssertTrue(treecko.assets.contains { $0.kind == .icon && $0.exists })
        XCTAssertTrue(treecko.assets.contains { $0.kind == .shinyPalette && !$0.exists })
        XCTAssertTrue(treecko.diagnostics.contains { $0.code == "SPECIES_ASSET_MISSING" })
        XCTAssertFalse(catalog.diagnostics.contains { $0.code == "SPECIES_ASSET_MISSING" })
        XCTAssertTrue(treecko.isEditable)
        XCTAssertEqual(treecko.learnsets.levelUpSymbol, "sTreeckoLevelUpLearnset")
        XCTAssertNotNil(treecko.learnsets.tmhmSourceSpan)
        XCTAssertTrue(catalog.constants[.types]?.contains { $0.symbol == "TYPE_GRASS" } == true)
        XCTAssertTrue(catalog.constants[.abilities]?.contains { $0.symbol == "ABILITY_OVERGROW" } == true)
        XCTAssertTrue(catalog.constants[.tmhmMoves]?.contains { $0.symbol == "MOVE_CUT" && $0.value == "HM01_CUT" } == true)
    }

    func testSpeciesMutationPlannerRewritesCoreAndMoveSourcesThenAppliesWithBackup() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.baseStats.hp = 41
        draft.types[1] = "TYPE_FIRE"
        draft.abilities[1] = "ABILITY_CHLOROPHYLL"
        draft.evYield.hp = 1
        draft.evYield.speed = 0
        draft.growthRate = "GROWTH_FAST"
        draft.itemCommon = "ITEM_POTION"
        draft.levelUpMoves[0].move = "MOVE_TACKLE"
        draft.levelUpMoves.append(SpeciesLevelUpMoveDraft(level: 9, move: "MOVE_FLASH"))
        draft.tmhmMoves.append("MOVE_FLASH")
        draft.eggMoves = ["MOVE_LEECH_SEED", "MOVE_FLASH"]
        draft.tutorMoves.append("MOVE_FURY_CUTTER")
        draft.pokedex?.pokemonScale = "257"

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(
            plan.changes.map(\.path).sorted(),
            [
                "src/data/pokemon/egg_moves.h",
                "src/data/pokemon/level_up_learnsets.h",
                "src/data/pokemon/pokedex_entries.h",
                "src/data/pokemon/species_info.h",
                "src/data/pokemon/tmhm_learnsets.h",
                "src/data/pokemon/tutor_learnsets.h"
            ]
        )
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(plan.isApplyable)
        XCTAssertTrue(plan.changes.first { $0.path == "src/data/pokemon/species_info.h" }?.textPreview?.contains(".baseHP = 41") == true)
        XCTAssertTrue(plan.changes.first { $0.path == "src/data/pokemon/tmhm_learnsets.h" }?.textPreview?.contains(".FLASH = TRUE") == true)
        XCTAssertTrue(plan.changes.first { $0.path == "src/data/pokemon/tutor_learnsets.h" }?.textPreview?.contains("TUTOR(FURY_CUTTER)") == true)
        XCTAssertTrue(plan.changes.first { $0.path == "src/data/pokemon/pokedex_entries.h" }?.textPreview?.contains(".pokemonScale = 257") == true)

        let result = try SpeciesMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.count, 6)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))

        let reloaded = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let speciesInfoText = try String(contentsOf: root.appendingPathComponent("src/data/pokemon/species_info.h"), encoding: .utf8)
        XCTAssertEqual(reloaded.species.map(\.speciesID), ["SPECIES_TREECKO", "SPECIES_GROVYLE"], "\(reloaded.diagnostics)\n\(speciesInfoText)")
        let edited = try XCTUnwrap(
            reloaded.species.first { $0.speciesID == "SPECIES_TREECKO" },
            speciesInfoText
        )
        XCTAssertEqual(edited.baseStats.hp, 41)
        XCTAssertEqual(edited.types, ["TYPE_GRASS", "TYPE_FIRE"])
        XCTAssertEqual(edited.abilities, ["ABILITY_OVERGROW", "ABILITY_CHLOROPHYLL"])
        XCTAssertEqual(edited.evYield.hp, 1)
        XCTAssertEqual(edited.evYield.speed, 0)
        XCTAssertEqual(edited.training.growthRate, "GROWTH_FAST")
        XCTAssertEqual(edited.heldItems.common, "ITEM_POTION")
        XCTAssertEqual(edited.learnsets.levelUp.map(\.move), ["MOVE_TACKLE", "MOVE_LEER", "MOVE_ABSORB", "MOVE_FLASH"])
        XCTAssertTrue(edited.learnsets.tmhm.map(\.move).contains("MOVE_FLASH"))
        XCTAssertEqual(edited.learnsets.tutor.map(\.move).sorted(), ["MOVE_FURY_CUTTER", "MOVE_MEGA_PUNCH", "MOVE_SWORD_DANCE"])
        XCTAssertEqual(edited.learnsets.egg.map(\.move), ["MOVE_LEECH_SEED", "MOVE_FLASH"])
        XCTAssertEqual(edited.pokedex?.pokemonScale, "257")
    }

    func testRubySapphireSpeciesBaseStatsPlanApplyBackUpAndReload() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeRubyProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })

        XCTAssertTrue(treecko.isEditable)
        XCTAssertEqual(treecko.sourceSpan.relativePath, "src/data/pokemon/base_stats.h")
        XCTAssertEqual(treecko.types, ["TYPE_GRASS", "TYPE_GRASS"])
        XCTAssertEqual(treecko.heldItems.common, "ITEM_NONE")
        XCTAssertEqual(treecko.breeding.eggGroups, ["EGG_GROUP_MONSTER", "EGG_GROUP_DRAGON"])

        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.baseStats.hp = 41
        draft.types[1] = "TYPE_FIRE"
        draft.abilities[1] = "ABILITY_CHLOROPHYLL"
        draft.evYield.hp = 1
        draft.evYield.speed = 0
        draft.growthRate = "GROWTH_FAST"
        draft.itemCommon = "ITEM_POTION"
        draft.noFlip = true

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/base_stats.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(plan.isApplyable)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains(".baseHP = 41"))
        XCTAssertTrue(preview.contains(".type2 = TYPE_FIRE"))
        XCTAssertTrue(preview.contains(".item1 = ITEM_POTION"))
        XCTAssertTrue(preview.contains(".ability2 = ABILITY_CHLOROPHYLL"))
        XCTAssertTrue(preview.contains(".noFlip = TRUE"))

        let result = try SpeciesMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/base_stats.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))

        let reloaded = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let edited = try XCTUnwrap(reloaded.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(edited.baseStats.hp, 41)
        XCTAssertEqual(edited.types, ["TYPE_GRASS", "TYPE_FIRE"])
        XCTAssertEqual(edited.abilities, ["ABILITY_OVERGROW", "ABILITY_CHLOROPHYLL"])
        XCTAssertEqual(edited.evYield.hp, 1)
        XCTAssertEqual(edited.evYield.speed, 0)
        XCTAssertEqual(edited.training.growthRate, "GROWTH_FAST")
        XCTAssertEqual(edited.heldItems.common, "ITEM_POTION")
        XCTAssertEqual(edited.noFlip, "TRUE")
    }

    func testRubySapphireSpeciesPlannerBlocksAdjacentDraftScopes() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeRubyProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        draft.eggMoves.append("MOVE_LEECH_SEED")
        draft.tutorMoves.append("MOVE_SWORD_DANCE")
        draft.assetData[.front] = testPNGData(width: 64, height: 64, paletteColorCount: 16)

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.count, 0)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_LEVEL_UP_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_TMHM_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_EGG_MOVES_SPAN_MISSING" })
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_EGG_MOVES_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_TUTOR_SPAN_MISSING" })
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_TUTOR_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_EVOLUTION_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_POKEDEX_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_POKEDEX_TEXT_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_ASSET_EDIT_UNSUPPORTED_PROFILE" })
    }

    func testRubySapphireTMHMLearnsetPlanApplyBackUpAndReload() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeRubyProject(at: root)
        let tmhmPath = root.appendingPathComponent("src/data/pokemon/tmhm_learnsets.h")
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })

        XCTAssertEqual(treecko.learnsets.tmhm.map(\.move), ["MOVE_BULLET_SEED"])
        XCTAssertEqual(treecko.learnsets.tmhmSourceSpan?.relativePath, "src/data/pokemon/tmhm_learnsets.h")

        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.tmhmMoves.append("MOVE_FLASH")

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/tmhm_learnsets.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(plan.isApplyable)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains("[SPECIES_TREECKO] = { .learnset = {"))
        XCTAssertTrue(preview.contains(".BULLET_SEED = TRUE"))
        XCTAssertTrue(preview.contains(".FLASH = TRUE"))

        let result = try SpeciesMutationApplier.apply(plan: plan)

        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/tmhm_learnsets.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))
        let source = try String(contentsOf: tmhmPath, encoding: .utf8)
        XCTAssertTrue(source.contains(".BULLET_SEED = TRUE"))
        XCTAssertTrue(source.contains(".FLASH = TRUE"))

        let reloaded = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let edited = try XCTUnwrap(reloaded.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(edited.learnsets.tmhm.map(\.move), ["MOVE_BULLET_SEED", "MOVE_FLASH"])
        XCTAssertEqual(edited.baseStats.hp, 40)
        XCTAssertEqual(edited.pokedex?.categoryName, "WOOD GECKO")
    }

    func testRubySapphireTMHMLearnsetEditsRequireParsedSourceRow() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeRubyProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let grovyle = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_GROVYLE" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: grovyle))
        draft.tmhmMoves.append("MOVE_CUT")

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.count, 0)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_TMHM_SPAN_MISSING" })
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_TMHM_EDIT_UNSUPPORTED_PROFILE" })
    }

    func testRubySapphireTutorLearnsetPlanPreviewApplyBackupReload() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeRubyProject(at: root)
        try writeRubyTutorLearnsets(at: root)
        let tutorPath = root.appendingPathComponent("src/data/pokemon/tutor_learnsets.h")
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })

        XCTAssertEqual(treecko.learnsets.tutor.map(\.move).sorted(), ["MOVE_MEGA_PUNCH", "MOVE_SWORD_DANCE"])
        XCTAssertEqual(treecko.learnsets.tutorSourceSpan?.relativePath, "src/data/pokemon/tutor_learnsets.h")

        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.tutorMoves.removeAll { $0 == "MOVE_MEGA_PUNCH" }
        draft.tutorMoves.append("MOVE_FURY_CUTTER")

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/tutor_learnsets.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(plan.isApplyable)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains("TUTOR(FURY_CUTTER)"))
        XCTAssertTrue(preview.contains("TUTOR(SWORD_DANCE)"))
        XCTAssertFalse(preview.contains("TUTOR(MEGA_PUNCH)"))

        let result = try SpeciesMutationApplier.apply(plan: plan)

        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/tutor_learnsets.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))
        let source = try String(contentsOf: tutorPath, encoding: .utf8)
        XCTAssertTrue(source.contains("TUTOR(FURY_CUTTER)"))
        XCTAssertFalse(source.contains("TUTOR(MEGA_PUNCH)"))

        let reloaded = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let edited = try XCTUnwrap(reloaded.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(edited.learnsets.tutor.map(\.move).sorted(), ["MOVE_FURY_CUTTER", "MOVE_SWORD_DANCE"])
        XCTAssertEqual(edited.baseStats.hp, 40)
    }

    func testRubySapphireTutorLearnsetPlanBlocksSourceDrift() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeRubyProject(at: root)
        try writeRubyTutorLearnsets(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.tutorMoves.append("MOVE_FURY_CUTTER")
        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertTrue(plan.isApplyable)

        let tutorPath = root.appendingPathComponent("src/data/pokemon/tutor_learnsets.h")
        let source = try String(contentsOf: tutorPath, encoding: .utf8)
            .replacingOccurrences(of: "TUTOR(SWORD_DANCE)", with: "TUTOR(FURY_CUTTER)")
        try write(source, to: tutorPath)

        let applyability = plan.validateApplyability()
        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(applyability.diagnostics.contains { $0.code == "SPECIES_APPLY_ORIGINAL_SIZE_MISMATCH" || $0.code == "SPECIES_APPLY_ORIGINAL_HASH_MISMATCH" })
    }

    func testRubySapphireTutorLearnsetPlanRejectsUnknownMoveConstants() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeRubyProject(at: root)
        try writeRubyTutorLearnsets(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.tutorMoves.append("MOVE_NOT_REAL")

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.count, 0)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_DRAFT_CONSTANT_UNRESOLVED" && $0.message.contains("MOVE_NOT_REAL") })
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_TUTOR_SPAN_MISSING" })
    }

    func testRubySapphireTutorLearnsetEditsRequireParsedSourceRow() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeRubyProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.tutorMoves.append("MOVE_SWORD_DANCE")

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.count, 0)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_TUTOR_SPAN_MISSING" })
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_TUTOR_EDIT_UNSUPPORTED_PROFILE" })
    }

    func testRubySapphireEggMovePlanApplyBackUpReloadAndPreserveRowOrder() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeRubyProject(at: root)
        try writeRubyEggMoves(at: root)
        let eggPath = root.appendingPathComponent("src/data/pokemon/egg_moves.h")
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })

        XCTAssertEqual(treecko.learnsets.egg.map(\.move), ["MOVE_CRUNCH", "MOVE_LEECH_SEED"])
        XCTAssertEqual(treecko.learnsets.eggSourceSpan?.relativePath, "src/data/pokemon/egg_moves.h")

        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.eggMoves = ["MOVE_LEECH_SEED", "MOVE_FLASH", "MOVE_CRUNCH"]

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/egg_moves.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(plan.isApplyable)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains("egg_moves(TREECKO,"))
        XCTAssertLessThan(
            try XCTUnwrap(preview.range(of: "MOVE_LEECH_SEED")?.lowerBound),
            try XCTUnwrap(preview.range(of: "MOVE_FLASH")?.lowerBound)
        )
        XCTAssertLessThan(
            try XCTUnwrap(preview.range(of: "MOVE_FLASH")?.lowerBound),
            try XCTUnwrap(preview.range(of: "MOVE_CRUNCH")?.lowerBound)
        )

        let result = try SpeciesMutationApplier.apply(plan: plan)

        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/egg_moves.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))
        let source = try String(contentsOf: eggPath, encoding: .utf8)
        XCTAssertLessThan(
            try XCTUnwrap(source.range(of: "egg_moves(TREECKO")?.lowerBound),
            try XCTUnwrap(source.range(of: "egg_moves(GROVYLE")?.lowerBound)
        )
        XCTAssertTrue(source.contains("egg_moves(GROVYLE,\n              MOVE_CRUNCH),"))

        let reloaded = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let edited = try XCTUnwrap(reloaded.species.first { $0.speciesID == "SPECIES_TREECKO" })
        let grovyle = try XCTUnwrap(reloaded.species.first { $0.speciesID == "SPECIES_GROVYLE" })
        XCTAssertEqual(edited.learnsets.egg.map(\.move), ["MOVE_LEECH_SEED", "MOVE_FLASH", "MOVE_CRUNCH"])
        XCTAssertEqual(grovyle.learnsets.egg.map(\.move), ["MOVE_CRUNCH"])
        XCTAssertEqual(edited.baseStats.hp, 40)
    }

    func testRubySapphireEggMovePlanBlocksSourceDrift() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeRubyProject(at: root)
        try writeRubyEggMoves(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.eggMoves.append("MOVE_FLASH")
        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertTrue(plan.isApplyable)

        let eggPath = root.appendingPathComponent("src/data/pokemon/egg_moves.h")
        let source = try String(contentsOf: eggPath, encoding: .utf8)
            .replacingOccurrences(of: "MOVE_CRUNCH", with: "MOVE_TACKLE")
        try write(source, to: eggPath)

        let applyability = plan.validateApplyability()
        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(applyability.diagnostics.contains { $0.code == "SPECIES_APPLY_ORIGINAL_SIZE_MISMATCH" || $0.code == "SPECIES_APPLY_ORIGINAL_HASH_MISMATCH" })
    }

    func testRubySapphireEggMoveEditsRequireParsedSourceRow() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeRubyProject(at: root)
        try writeRubyEggMoves(at: root, includeGrovyle: false)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let grovyle = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_GROVYLE" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: grovyle))
        draft.eggMoves.append("MOVE_LEECH_SEED")

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.count, 0)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_EGG_MOVES_SPAN_MISSING" })
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_EGG_MOVES_EDIT_UNSUPPORTED_PROFILE" })
    }

    func testRubySapphireLevelUpLearnsetPlanApplyBackUpAndReload() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeRubyProject(at: root)
        let levelUpPath = root.appendingPathComponent("src/data/pokemon/level_up_learnsets.h")
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })

        XCTAssertEqual(treecko.learnsets.levelUp.map(\.move), ["MOVE_POUND", "MOVE_LEER", "MOVE_ABSORB"])
        XCTAssertEqual(treecko.learnsets.levelUp.map(\.level), [1, 1, 6])
        XCTAssertEqual(treecko.learnsets.levelUpSymbol, "gTreeckoLevelUpLearnset")
        XCTAssertEqual(treecko.learnsets.levelUpSourceSpan?.relativePath, "src/data/pokemon/level_up_learnsets.h")

        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.levelUpMoves[0].move = "MOVE_TACKLE"
        draft.levelUpMoves.append(SpeciesLevelUpMoveDraft(level: 9, move: "MOVE_FLASH"))

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/level_up_learnsets.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(plan.isApplyable)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains("const u16 gTreeckoLevelUpLearnset[] = {"))
        XCTAssertFalse(preview.contains("static const u16 gTreeckoLevelUpLearnset[] = {"))
        XCTAssertTrue(preview.contains("LEVEL_UP_MOVE( 1, MOVE_TACKLE),"))
        XCTAssertTrue(preview.contains("LEVEL_UP_MOVE( 9, MOVE_FLASH),"))

        let result = try SpeciesMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/level_up_learnsets.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))

        let source = try String(contentsOf: levelUpPath, encoding: .utf8)
        XCTAssertTrue(source.contains("const u16 gTreeckoLevelUpLearnset[] = {"))
        XCTAssertFalse(source.contains("static const u16 gTreeckoLevelUpLearnset[] = {"))
        XCTAssertTrue(source.contains("LEVEL_UP_MOVE( 1, MOVE_TACKLE),"))
        XCTAssertTrue(source.contains("LEVEL_UP_MOVE( 9, MOVE_FLASH),"))

        let reloaded = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let edited = try XCTUnwrap(reloaded.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(edited.learnsets.levelUp.map(\.move), ["MOVE_TACKLE", "MOVE_LEER", "MOVE_ABSORB", "MOVE_FLASH"])
        XCTAssertEqual(edited.learnsets.levelUp.map(\.level), [1, 1, 6, 9])
        XCTAssertEqual(edited.baseStats.hp, 40)
    }

    func testRubySapphireLevelUpLearnsetPlanBlocksSourceDrift() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeRubyProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.levelUpMoves.append(SpeciesLevelUpMoveDraft(level: 9, move: "MOVE_FLASH"))
        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertTrue(plan.isApplyable)

        let levelUpPath = root.appendingPathComponent("src/data/pokemon/level_up_learnsets.h")
        let source = try String(contentsOf: levelUpPath, encoding: .utf8)
            .replacingOccurrences(of: "LEVEL_UP_MOVE( 6, MOVE_ABSORB),", with: "LEVEL_UP_MOVE( 7, MOVE_ABSORB),")
        try write(source, to: levelUpPath)

        let applyability = plan.validateApplyability()
        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(applyability.diagnostics.contains { $0.code == "SPECIES_APPLY_ORIGINAL_SIZE_MISMATCH" || $0.code == "SPECIES_APPLY_ORIGINAL_HASH_MISMATCH" })
    }

    func testRubySapphireLevelUpLearnsetPlanRejectsUnknownMoveConstants() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeRubyProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.levelUpMoves.append(SpeciesLevelUpMoveDraft(level: 9, move: "MOVE_NOT_REAL"))

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.count, 0)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_DRAFT_CONSTANT_UNRESOLVED" && $0.message.contains("MOVE_NOT_REAL") })
    }

    func testRubySapphireLevelUpLearnsetEditsRequireParsedSourceBlock() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeRubyProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let grovyle = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_GROVYLE" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: grovyle))
        draft.levelUpMoves.append(SpeciesLevelUpMoveDraft(level: 1, move: "MOVE_POUND"))

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.count, 0)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_LEVEL_UP_SPAN_MISSING" })
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_LEVEL_UP_EDIT_UNSUPPORTED_PROFILE" })
    }

    func testRubySapphirePokedexPlanApplyBackUpAndReload() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeRubyProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        draft.pokedex?.height = "6"
        draft.pokedex?.categoryName = "FOREST \"LIZARD\""
        draft.pokedex?.description = "Ruby \"description\"\\path\nwith two lines."

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.map(\.path).sorted(), [
            "src/data/pokedex_entries_en.h",
            "src/data/pokedex_text_en.h"
        ])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(plan.isApplyable)
        let entryPreview = try XCTUnwrap(plan.changes.first { $0.path == "src/data/pokedex_entries_en.h" }?.textPreview)
        XCTAssertTrue(entryPreview.contains(".height = 6"))
        XCTAssertTrue(entryPreview.contains(#".categoryName = _("FOREST \"LIZARD\"")"#))
        let textPreview = try XCTUnwrap(plan.changes.first { $0.path == "src/data/pokedex_text_en.h" }?.textPreview)
        XCTAssertEqual(textPreview, #"const u8 gTreeckoPokedexText[] = _("Ruby \"description\"\\path\nwith two lines.");"#)

        let result = try SpeciesMutationApplier.apply(plan: plan)

        XCTAssertEqual(result.appliedChanges.map(\.path).sorted(), [
            "src/data/pokedex_entries_en.h",
            "src/data/pokedex_text_en.h"
        ])
        XCTAssertTrue(result.appliedChanges.allSatisfy { FileManager.default.fileExists(atPath: $0.backupPath) })

        let reloaded = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let edited = try XCTUnwrap(reloaded.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(edited.pokedex?.height, "6")
        XCTAssertEqual(edited.pokedex?.categoryName, #"FOREST "LIZARD""#)
        XCTAssertEqual(edited.pokedex?.description, #"Ruby "description"\\path"# + "\nwith two lines.")
        XCTAssertEqual(edited.baseStats.hp, 40)
        XCTAssertEqual(edited.learnsets.levelUp.map(\.move), ["MOVE_POUND", "MOVE_LEER", "MOVE_ABSORB"])
    }

    func testRubySapphireEvolutionPlanApplyBackUpAndReload() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeRubyProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        XCTAssertEqual(draft.evolutions.first?.targetSpecies, "SPECIES_GROVYLE")
        draft.evolutions[0].method = "EVO_ITEM"
        draft.evolutions[0].parameter = "ITEM_POTION"
        draft.evolutions[0].targetSpecies = "SPECIES_TREECKO"

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/evolution.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(plan.isApplyable)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains("[SPECIES_TREECKO] = {{ EVO_ITEM, ITEM_POTION, SPECIES_TREECKO }}"))

        let result = try SpeciesMutationApplier.apply(plan: plan)

        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/evolution.h"])
        XCTAssertTrue(result.appliedChanges.allSatisfy { FileManager.default.fileExists(atPath: $0.backupPath) })

        let reloaded = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let edited = try XCTUnwrap(reloaded.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(edited.evolutions.count, 1)
        XCTAssertEqual(edited.evolutions.first?.method, "EVO_ITEM")
        XCTAssertEqual(edited.evolutions.first?.parameter, "ITEM_POTION")
        XCTAssertEqual(edited.evolutions.first?.targetSpecies, "SPECIES_TREECKO")
        XCTAssertEqual(edited.baseStats.hp, 40)
        XCTAssertEqual(edited.pokedex?.categoryName, "WOOD GECKO")
    }

    func testRubySapphireEvolutionStillBlocksMissingRowInsertion() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeRubyProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let grovyle = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_GROVYLE" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: grovyle))

        draft.evolutions.append(SpeciesEvolutionDraft(method: "EVO_LEVEL", parameter: "36", targetSpecies: "SPECIES_TREECKO"))

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.count, 0)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_EVOLUTION_SPAN_MISSING" })
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_EVOLUTION_EDIT_UNSUPPORTED_PROFILE" })
    }

    func testExpansionSpeciesInfoScalarPlanApplyBackupReloadPreservesRawFields() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root)
        let familyPath = root.appendingPathComponent("src/data/pokemon/species_info/gen_3_families.h")
        let originalFamilyText = try String(contentsOf: familyPath, encoding: .utf8)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })

        XCTAssertTrue(treecko.isEditable)
        XCTAssertEqual(treecko.sourceSpan.relativePath, "src/data/pokemon/species_info.h")
        XCTAssertEqual(treecko.baseStats.hp, 40)
        XCTAssertEqual(treecko.types, ["TYPE_GRASS", "TYPE_GRASS"])
        XCTAssertEqual(treecko.abilities, ["ABILITY_OVERGROW", "ABILITY_NONE", "ABILITY_CHLOROPHYLL"])
        XCTAssertEqual(treecko.breeding.eggGroups, ["EGG_GROUP_MONSTER", "EGG_GROUP_DRAGON"])
        XCTAssertEqual(treecko.heldItems.common, "ITEM_NONE")
        XCTAssertTrue(treecko.diagnostics.contains { $0.code == "SPECIES_ENTRY_EXPANSION_FIELD_READ_ONLY" })

        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.baseStats.hp = 41
        draft.baseStats.attack = 46
        draft.types[1] = "TYPE_FIRE"
        draft.abilities[1] = "ABILITY_CHLOROPHYLL"
        draft.evYield.hp = 1
        draft.evYield.speed = 0
        draft.catchRate = "46"
        draft.expYield = "66"
        draft.itemCommon = "ITEM_POTION"
        draft.friendship = "71"
        draft.growthRate = "GROWTH_FAST"
        draft.eggGroups[1] = "EGG_GROUP_MONSTER"
        draft.bodyColor = "BODY_COLOR_RED"
        draft.noFlip = true

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/species_info.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(plan.isApplyable)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains(".baseHP = 41, // preserve comment"))
        XCTAssertTrue(preview.contains(".baseAttack    = 46"))
        XCTAssertTrue(preview.contains(".type2 = TYPE_FIRE"))
        XCTAssertTrue(preview.contains(".baseExp = 66"))
        XCTAssertTrue(preview.contains(".evYield_HP        = 1"))
        XCTAssertTrue(preview.contains(".item1 = ITEM_POTION"))
        XCTAssertTrue(preview.contains(".eggGroup2 = EGG_GROUP_MONSTER"))
        XCTAssertTrue(preview.contains(".ability2 = ABILITY_CHLOROPHYLL"))
        XCTAssertTrue(preview.contains(".hiddenAbility = ABILITY_CHLOROPHYLL"))
        XCTAssertTrue(preview.contains(".formSpeciesIdTable = sTreeckoFormSpeciesIdTable"))
        XCTAssertTrue(preview.contains(".mysteryExpansionField = KEEP_ME"))
        XCTAssertTrue(preview.contains(".noFlip = TRUE"))

        let result = try SpeciesMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/species_info.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))
        XCTAssertEqual(try String(contentsOf: familyPath, encoding: .utf8), originalFamilyText)

        let source = try String(contentsOf: root.appendingPathComponent("src/data/pokemon/species_info.h"), encoding: .utf8)
        XCTAssertTrue(source.contains(".baseHP = 41, // preserve comment"))
        XCTAssertTrue(source.contains(".type2 = TYPE_FIRE"))
        XCTAssertTrue(source.contains(".hiddenAbility = ABILITY_CHLOROPHYLL"))
        XCTAssertTrue(source.contains(".formSpeciesIdTable = sTreeckoFormSpeciesIdTable"))
        XCTAssertTrue(source.contains(".mysteryExpansionField = KEEP_ME"))

        let reloaded = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let edited = try XCTUnwrap(reloaded.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(edited.baseStats.hp, 41)
        XCTAssertEqual(edited.baseStats.attack, 46)
        XCTAssertEqual(edited.types, ["TYPE_GRASS", "TYPE_FIRE"])
        XCTAssertEqual(edited.abilities, ["ABILITY_OVERGROW", "ABILITY_CHLOROPHYLL", "ABILITY_CHLOROPHYLL"])
        XCTAssertEqual(edited.evYield.hp, 1)
        XCTAssertEqual(edited.evYield.speed, 0)
        XCTAssertEqual(edited.training.catchRate, "46")
        XCTAssertEqual(edited.training.expYield, "66")
        XCTAssertEqual(edited.heldItems.common, "ITEM_POTION")
        XCTAssertEqual(edited.training.friendship, "71")
        XCTAssertEqual(edited.training.growthRate, "GROWTH_FAST")
        XCTAssertEqual(edited.breeding.eggGroups, ["EGG_GROUP_MONSTER", "EGG_GROUP_MONSTER"])
        XCTAssertEqual(edited.bodyColor, "BODY_COLOR_RED")
        XCTAssertEqual(edited.noFlip, "TRUE")
    }

    func testExpansionLevelUpLearnsetPlanPreviewApplyBackupReload() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root, includeLevelUpLearnsets: true)
        let levelUpPath = root.appendingPathComponent("src/data/pokemon/level_up_learnsets/treecko.h")
        let familyPath = root.appendingPathComponent("src/data/pokemon/species_info/gen_3_families.h")
        let allLearnablesPath = root.appendingPathComponent("src/data/pokemon/all_learnables.json")
        let originalFamilyText = try String(contentsOf: familyPath, encoding: .utf8)
        let originalAllLearnablesText = try String(contentsOf: allLearnablesPath, encoding: .utf8)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })

        XCTAssertEqual(treecko.learnsets.levelUp.map(\.move), ["MOVE_POUND", "MOVE_LEER", "MOVE_ABSORB"])
        XCTAssertEqual(treecko.learnsets.levelUpSourceSpan?.relativePath, "src/data/pokemon/level_up_learnsets/treecko.h")
        XCTAssertEqual(treecko.learnsets.levelUpSymbol, "sTreeckoLevelUpLearnset")

        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.levelUpMoves[0].move = "MOVE_TACKLE"
        draft.levelUpMoves.append(SpeciesLevelUpMoveDraft(level: 9, move: "MOVE_FLASH"))

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/level_up_learnsets/treecko.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(plan.isApplyable)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains("static const u16 sTreeckoLevelUpLearnset[] = {"))
        XCTAssertTrue(preview.contains("LEVEL_UP_MOVE( 1, MOVE_TACKLE),"))
        XCTAssertTrue(preview.contains("LEVEL_UP_MOVE( 9, MOVE_FLASH),"))

        let result = try SpeciesMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/level_up_learnsets/treecko.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))
        XCTAssertEqual(try String(contentsOf: familyPath, encoding: .utf8), originalFamilyText)
        XCTAssertEqual(try String(contentsOf: allLearnablesPath, encoding: .utf8), originalAllLearnablesText)

        let source = try String(contentsOf: levelUpPath, encoding: .utf8)
        XCTAssertTrue(source.contains("LEVEL_UP_MOVE( 1, MOVE_TACKLE),"))
        XCTAssertTrue(source.contains("LEVEL_UP_MOVE( 9, MOVE_FLASH),"))

        let reloaded = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let edited = try XCTUnwrap(reloaded.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(edited.learnsets.levelUp.map(\.move), ["MOVE_TACKLE", "MOVE_LEER", "MOVE_ABSORB", "MOVE_FLASH"])
        XCTAssertEqual(edited.learnsets.levelUp.map(\.level), [1, 1, 6, 9])
    }

    func testExpansionFormTablesPlanPreviewApplyBackupReloadPreservesAdjacentOutputs() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root)
        let formSpeciesPath = root.appendingPathComponent("src/data/pokemon/form_species_tables.h")
        let formChangePath = root.appendingPathComponent("src/data/pokemon/form_change_tables.h")
        let familyPath = root.appendingPathComponent("src/data/pokemon/species_info/gen_3_families.h")
        let generatedPath = root.appendingPathComponent("generated/form_tables.json")
        let referencePath = root.appendingPathComponent("references/pokeemerald-expansion/src/data/pokemon/form_species_tables.h")
        let romPath = root.appendingPathComponent("pokeemerald.gba")
        try write("{\"forms\":[]}\n", to: generatedPath)
        try write("reference stays read-only\n", to: referencePath)
        try write(Data([0x01, 0x02, 0x03]), to: romPath)
        let originalFamilyText = try String(contentsOf: familyPath, encoding: .utf8)
        let originalGeneratedText = try String(contentsOf: generatedPath, encoding: .utf8)
        let originalReferenceText = try String(contentsOf: referencePath, encoding: .utf8)
        let originalROMData = try Data(contentsOf: romPath)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })

        XCTAssertEqual(treecko.forms.formSpeciesTableSymbol, "sTreeckoFormSpeciesIdTable")
        XCTAssertEqual(treecko.forms.formSpeciesSourceSpan?.relativePath, "src/data/pokemon/form_species_tables.h")
        XCTAssertEqual(treecko.forms.species.map(\.speciesID), ["SPECIES_TREECKO", "SPECIES_TREECKO_MEGA"])
        XCTAssertEqual(treecko.forms.formChangeTableSymbol, "sTreeckoFormChangeTable")
        XCTAssertEqual(treecko.forms.formChangeSourceSpan?.relativePath, "src/data/pokemon/form_change_tables.h")
        XCTAssertEqual(treecko.forms.changes.map(\.method), ["FORM_CHANGE_BATTLE_MEGA_EVOLUTION"])
        XCTAssertEqual(treecko.forms.changes.map(\.targetSpecies), ["SPECIES_TREECKO_MEGA"])

        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.formSpecies[1].speciesID = "SPECIES_TREECKO_PRIMAL"
        draft.formChanges[0].method = "FORM_CHANGE_ITEM_HOLD"
        draft.formChanges[0].targetSpecies = "SPECIES_TREECKO_PRIMAL"

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.map(\.path).sorted(), [
            "src/data/pokemon/form_change_tables.h",
            "src/data/pokemon/form_species_tables.h"
        ])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty, "\(plan.diagnostics)")
        XCTAssertTrue(plan.isApplyable)
        XCTAssertTrue(plan.changes.first { $0.path == "src/data/pokemon/form_species_tables.h" }?.textPreview?.contains("SPECIES_TREECKO_PRIMAL") == true)
        XCTAssertTrue(plan.changes.first { $0.path == "src/data/pokemon/form_change_tables.h" }?.textPreview?.contains("{ FORM_CHANGE_ITEM_HOLD, SPECIES_TREECKO_PRIMAL },") == true)

        let result = try SpeciesMutationApplier.apply(plan: plan)

        XCTAssertEqual(result.appliedChanges.map(\.path).sorted(), [
            "src/data/pokemon/form_change_tables.h",
            "src/data/pokemon/form_species_tables.h"
        ])
        XCTAssertTrue(result.appliedChanges.allSatisfy { FileManager.default.fileExists(atPath: $0.backupPath) })
        XCTAssertEqual(try String(contentsOf: familyPath, encoding: .utf8), originalFamilyText)
        XCTAssertEqual(try String(contentsOf: generatedPath, encoding: .utf8), originalGeneratedText)
        XCTAssertEqual(try String(contentsOf: referencePath, encoding: .utf8), originalReferenceText)
        XCTAssertEqual(try Data(contentsOf: romPath), originalROMData)

        let formSpeciesSource = try String(contentsOf: formSpeciesPath, encoding: .utf8)
        let formChangeSource = try String(contentsOf: formChangePath, encoding: .utf8)
        XCTAssertTrue(formSpeciesSource.contains("SPECIES_TREECKO_PRIMAL"))
        XCTAssertTrue(formChangeSource.contains("{ FORM_CHANGE_ITEM_HOLD, SPECIES_TREECKO_PRIMAL },"))

        let reloaded = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let edited = try XCTUnwrap(reloaded.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(edited.forms.species.map(\.speciesID), ["SPECIES_TREECKO", "SPECIES_TREECKO_PRIMAL"])
        XCTAssertEqual(edited.forms.changes.map(\.method), ["FORM_CHANGE_ITEM_HOLD"])
        XCTAssertEqual(edited.forms.changes.map(\.targetSpecies), ["SPECIES_TREECKO_PRIMAL"])
    }

    func testExpansionFormTablePlanBlocksSourceDrift() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.formSpecies[1].speciesID = "SPECIES_TREECKO_PRIMAL"
        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        let formSpeciesPath = root.appendingPathComponent("src/data/pokemon/form_species_tables.h")
        let source = try String(contentsOf: formSpeciesPath, encoding: .utf8)
            .replacingOccurrences(of: "SPECIES_TREECKO_MEGA", with: "SPECIES_TREECKO_FAKE")
        try write(source, to: formSpeciesPath)

        let applyability = plan.validateApplyability()
        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(applyability.diagnostics.contains { $0.code == "SPECIES_APPLY_ORIGINAL_SIZE_MISMATCH" || $0.code == "SPECIES_APPLY_ORIGINAL_HASH_MISMATCH" })
    }

    func testExpansionFormTablePlanRejectsUnknownConstantsAndRowInsertion() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var unknownDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        unknownDraft.formSpecies[1].speciesID = "SPECIES_NOT_REAL"
        unknownDraft.formChanges[0].method = "FORM_CHANGE_NOT_REAL"

        let unknownPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: unknownDraft)

        XCTAssertEqual(unknownPlan.changes.count, 0)
        XCTAssertFalse(unknownPlan.isApplyable)
        XCTAssertTrue(unknownPlan.diagnostics.contains { $0.code == "SPECIES_DRAFT_CONSTANT_UNRESOLVED" && $0.message.contains("SPECIES_NOT_REAL") })
        XCTAssertTrue(unknownPlan.diagnostics.contains { $0.code == "SPECIES_DRAFT_CONSTANT_UNRESOLVED" && $0.message.contains("FORM_CHANGE_NOT_REAL") })

        var insertedDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        insertedDraft.formSpecies.append(SpeciesFormSpeciesDraft(slot: 99, speciesID: "SPECIES_TREECKO_PRIMAL"))
        insertedDraft.formChanges.append(SpeciesFormChangeDraft(index: 99, method: "FORM_CHANGE_ITEM_HOLD", targetSpecies: "SPECIES_TREECKO_PRIMAL"))

        let insertedPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: insertedDraft)

        XCTAssertEqual(insertedPlan.changes.count, 0)
        XCTAssertFalse(insertedPlan.isApplyable)
        XCTAssertTrue(insertedPlan.diagnostics.contains { $0.code == "SPECIES_FORM_SPECIES_ROW_STRUCTURE_UNSUPPORTED" })
        XCTAssertTrue(insertedPlan.diagnostics.contains { $0.code == "SPECIES_FORM_CHANGE_ROW_STRUCTURE_UNSUPPORTED" })
    }

    func testExpansionFormChangeUnsupportedTupleShapeBlocksFormEdits() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root)
        try write(
            """
            static const struct FormChange sTreeckoFormChangeTable[] = {
                { FORM_CHANGE_ITEM_HOLD, ITEM_POTION, SPECIES_TREECKO_MEGA },
                { FORM_CHANGE_TERMINATOR },
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/form_change_tables.h")
        )
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.formSpecies[1].speciesID = "SPECIES_TREECKO_PRIMAL"

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.count, 0)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_FORM_CHANGE_ROW_UNSUPPORTED_SHAPE" })
    }

    func testExpansionEvolutionTuplesPlanPreviewApplyBackupReloadPreservesAdjacentOutputs() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root, includeEvolutionRows: true)
        let evolutionPath = root.appendingPathComponent("src/data/pokemon/evolution.h")
        let familyPath = root.appendingPathComponent("src/data/pokemon/species_info/gen_3_families.h")
        let generatedPath = root.appendingPathComponent("generated/evolutions.json")
        let referencePath = root.appendingPathComponent("references/pokeemerald-expansion/src/data/pokemon/evolution.h")
        let romPath = root.appendingPathComponent("pokeemerald.gba")
        try write("{\"evolutions\":[]}\n", to: generatedPath)
        try write("reference evolution stays read-only\n", to: referencePath)
        try write(Data([0x01, 0x02, 0x03]), to: romPath)
        let originalFamilyText = try String(contentsOf: familyPath, encoding: .utf8)
        let originalGeneratedText = try String(contentsOf: generatedPath, encoding: .utf8)
        let originalReferenceText = try String(contentsOf: referencePath, encoding: .utf8)
        let originalROMData = try Data(contentsOf: romPath)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })

        XCTAssertEqual(treecko.evolutions.map(\.method), ["EVO_LEVEL", "EVO_ITEM"])
        XCTAssertEqual(treecko.evolutions.map(\.parameter), ["16", "ITEM_POTION"])
        XCTAssertEqual(treecko.evolutions.map(\.targetSpecies), ["SPECIES_GROVYLE", "SPECIES_TREECKO_MEGA"])
        XCTAssertEqual(treecko.evolutions.map(\.rowIndex), [0, 1])
        XCTAssertEqual(treecko.evolutions.first?.sourceSpan.relativePath, "src/data/pokemon/evolution.h")

        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.evolutions[0].method = "EVO_ITEM"
        draft.evolutions[0].parameter = "ITEM_POTION"
        draft.evolutions[0].targetSpecies = "SPECIES_TREECKO_PRIMAL"
        draft.evolutions[1].method = "EVO_LEVEL"
        draft.evolutions[1].parameter = "20"
        draft.evolutions[1].targetSpecies = "SPECIES_GROVYLE"

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/evolution.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty, "\(plan.diagnostics)")
        XCTAssertTrue(plan.isApplyable)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains("[SPECIES_TREECKO] = {"))
        XCTAssertTrue(preview.contains("{ EVO_ITEM, ITEM_POTION, SPECIES_TREECKO_PRIMAL },"))
        XCTAssertTrue(preview.contains("{ EVO_LEVEL, 20, SPECIES_GROVYLE }"))

        let result = try SpeciesMutationApplier.apply(plan: plan)

        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/evolution.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))
        XCTAssertEqual(try String(contentsOf: familyPath, encoding: .utf8), originalFamilyText)
        XCTAssertEqual(try String(contentsOf: generatedPath, encoding: .utf8), originalGeneratedText)
        XCTAssertEqual(try String(contentsOf: referencePath, encoding: .utf8), originalReferenceText)
        XCTAssertEqual(try Data(contentsOf: romPath), originalROMData)

        let source = try String(contentsOf: evolutionPath, encoding: .utf8)
        XCTAssertTrue(source.contains("{ EVO_ITEM, ITEM_POTION, SPECIES_TREECKO_PRIMAL },"))
        XCTAssertTrue(source.contains("{ EVO_LEVEL, 20, SPECIES_GROVYLE }"))

        let reloaded = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let edited = try XCTUnwrap(reloaded.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(edited.evolutions.map(\.method), ["EVO_ITEM", "EVO_LEVEL"])
        XCTAssertEqual(edited.evolutions.map(\.parameter), ["ITEM_POTION", "20"])
        XCTAssertEqual(edited.evolutions.map(\.targetSpecies), ["SPECIES_TREECKO_PRIMAL", "SPECIES_GROVYLE"])
    }

    func testExpansionEvolutionTuplePlanBlocksSourceDrift() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root, includeEvolutionRows: true)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.evolutions[0].parameter = "18"
        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        let evolutionPath = root.appendingPathComponent("src/data/pokemon/evolution.h")
        let source = try String(contentsOf: evolutionPath, encoding: .utf8)
            .replacingOccurrences(of: "EVO_LEVEL, 16", with: "EVO_LEVEL, 17")
        try write(source, to: evolutionPath)

        let applyability = plan.validateApplyability()
        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(applyability.diagnostics.contains { $0.code == "SPECIES_APPLY_ORIGINAL_SIZE_MISMATCH" || $0.code == "SPECIES_APPLY_ORIGINAL_HASH_MISMATCH" })
    }

    func testExpansionEvolutionTuplePlanRejectsUnknownConstantsAndRowStructureChanges() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root, includeEvolutionRows: true)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })

        var unknownDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        unknownDraft.evolutions[0].method = "EVO_NOT_REAL"
        unknownDraft.evolutions[0].targetSpecies = "SPECIES_NOT_REAL"
        unknownDraft.evolutions[1].parameter = "ITEM_NOT_REAL"

        let unknownPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: unknownDraft)

        XCTAssertEqual(unknownPlan.changes.count, 0)
        XCTAssertFalse(unknownPlan.isApplyable)
        XCTAssertTrue(unknownPlan.diagnostics.contains { $0.code == "SPECIES_DRAFT_CONSTANT_UNRESOLVED" && $0.message.contains("EVO_NOT_REAL") })
        XCTAssertTrue(unknownPlan.diagnostics.contains { $0.code == "SPECIES_DRAFT_CONSTANT_UNRESOLVED" && $0.message.contains("SPECIES_NOT_REAL") })
        XCTAssertTrue(unknownPlan.diagnostics.contains { $0.code == "SPECIES_DRAFT_CONSTANT_UNRESOLVED" && $0.message.contains("ITEM_NOT_REAL") })

        var invalidParameterDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        invalidParameterDraft.evolutions[0].method = "EVO_FRIENDSHIP"
        invalidParameterDraft.evolutions[0].parameter = "16"

        let invalidParameterPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: invalidParameterDraft)

        XCTAssertFalse(invalidParameterPlan.isApplyable)
        XCTAssertTrue(invalidParameterPlan.diagnostics.contains { $0.code == "SPECIES_EVOLUTION_PARAMETER_INVALID" })

        var insertedDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        insertedDraft.evolutions.append(SpeciesEvolutionDraft(method: "EVO_LEVEL", parameter: "30", targetSpecies: "SPECIES_GROVYLE"))
        let insertedPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: insertedDraft)
        XCTAssertEqual(insertedPlan.changes.count, 0)
        XCTAssertFalse(insertedPlan.isApplyable)
        XCTAssertTrue(insertedPlan.diagnostics.contains { $0.code == "SPECIES_EXPANSION_EVOLUTION_ROW_STRUCTURE_UNSUPPORTED" })

        var removedDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        removedDraft.evolutions.removeLast()
        let removedPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: removedDraft)
        XCTAssertEqual(removedPlan.changes.count, 0)
        XCTAssertFalse(removedPlan.isApplyable)
        XCTAssertTrue(removedPlan.diagnostics.contains { $0.code == "SPECIES_EXPANSION_EVOLUTION_ROW_STRUCTURE_UNSUPPORTED" })

        var reorderedDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        reorderedDraft.evolutions.swapAt(0, 1)
        let reorderedPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: reorderedDraft)
        XCTAssertEqual(reorderedPlan.changes.count, 0)
        XCTAssertFalse(reorderedPlan.isApplyable)
        XCTAssertTrue(reorderedPlan.diagnostics.contains { $0.code == "SPECIES_EXPANSION_EVOLUTION_ROW_STRUCTURE_UNSUPPORTED" })
    }

    func testExpansionLevelUpLearnsetPlanBlocksSourceDrift() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root, includeLevelUpLearnsets: true)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.levelUpMoves.append(SpeciesLevelUpMoveDraft(level: 9, move: "MOVE_FLASH"))
        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        let levelUpPath = root.appendingPathComponent("src/data/pokemon/level_up_learnsets/treecko.h")
        let source = try String(contentsOf: levelUpPath, encoding: .utf8)
            .replacingOccurrences(of: "LEVEL_UP_MOVE( 6, MOVE_ABSORB),", with: "LEVEL_UP_MOVE( 7, MOVE_ABSORB),")
        try write(source, to: levelUpPath)

        let applyability = plan.validateApplyability()
        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(applyability.diagnostics.contains { $0.code == "SPECIES_APPLY_ORIGINAL_HASH_MISMATCH" })
    }

    func testExpansionLevelUpLearnsetPlanRejectsUnknownMoveConstants() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root, includeLevelUpLearnsets: true)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.levelUpMoves.append(SpeciesLevelUpMoveDraft(level: 9, move: "MOVE_NOT_REAL"))

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.count, 0)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_DRAFT_CONSTANT_UNRESOLVED" && $0.message.contains("MOVE_NOT_REAL") })
    }

    func testExpansionLevelUpLearnsetEditsRequireParsedSourceBlock() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.levelUpMoves.append(SpeciesLevelUpMoveDraft(level: 7, move: "MOVE_ABSORB"))

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.count, 0)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_LEVEL_UP_SPAN_MISSING" })
    }

    func testExpansionTMHMLearnsetPlanPreviewApplyBackupReloadPreservesGeneratedLearnables() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root, includeTMHMLearnsets: true)
        let tmhmPath = root.appendingPathComponent("src/data/pokemon/tmhm_learnsets.h")
        let familyPath = root.appendingPathComponent("src/data/pokemon/species_info/gen_3_families.h")
        let allLearnablesPath = root.appendingPathComponent("src/data/pokemon/all_learnables.json")
        let originalFamilyText = try String(contentsOf: familyPath, encoding: .utf8)
        let originalAllLearnablesText = try String(contentsOf: allLearnablesPath, encoding: .utf8)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })

        XCTAssertEqual(treecko.learnsets.tmhm.map(\.move), ["MOVE_BULLET_SEED", "MOVE_CUT"])
        XCTAssertEqual(treecko.learnsets.tmhmSourceSpan?.relativePath, "src/data/pokemon/tmhm_learnsets.h")

        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.tmhmMoves.removeAll { $0 == "MOVE_CUT" }
        draft.tmhmMoves.append("MOVE_FLASH")

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/tmhm_learnsets.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty, "\(plan.diagnostics)")
        XCTAssertTrue(plan.isApplyable)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains(".BULLET_SEED = TRUE"))
        XCTAssertTrue(preview.contains(".FLASH = TRUE"))
        XCTAssertFalse(preview.contains(".CUT = TRUE"))

        let result = try SpeciesMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/tmhm_learnsets.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))
        XCTAssertEqual(try String(contentsOf: familyPath, encoding: .utf8), originalFamilyText)
        XCTAssertEqual(try String(contentsOf: allLearnablesPath, encoding: .utf8), originalAllLearnablesText)

        let source = try String(contentsOf: tmhmPath, encoding: .utf8)
        XCTAssertTrue(source.contains(".BULLET_SEED = TRUE"))
        XCTAssertTrue(source.contains(".FLASH = TRUE"))
        XCTAssertFalse(source.contains(".CUT = TRUE"))

        let reloaded = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let edited = try XCTUnwrap(reloaded.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(edited.learnsets.tmhm.map(\.move), ["MOVE_BULLET_SEED", "MOVE_FLASH"])
    }

    func testExpansionTMHMLearnsetPlanBlocksSourceDrift() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root, includeTMHMLearnsets: true)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.tmhmMoves.append("MOVE_FLASH")
        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        let tmhmPath = root.appendingPathComponent("src/data/pokemon/tmhm_learnsets.h")
        let source = try String(contentsOf: tmhmPath, encoding: .utf8)
            .replacingOccurrences(of: ".BULLET_SEED = TRUE,", with: ".BULLET_SEED = TRUF,")
        try write(source, to: tmhmPath)

        let applyability = plan.validateApplyability()
        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(applyability.diagnostics.contains { $0.code == "SPECIES_APPLY_ORIGINAL_HASH_MISMATCH" })
    }

    func testExpansionTMHMLearnsetPlanRejectsUnknownMachineMoveConstants() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root, includeTMHMLearnsets: true)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.tmhmMoves.append("MOVE_NOT_REAL")

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.count, 0)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_DRAFT_CONSTANT_UNRESOLVED" && $0.message.contains("MOVE_NOT_REAL") })
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_TMHM_SPAN_MISSING" })
    }

    func testExpansionTMHMLearnsetEditsRequireParsedSourceRow() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.tmhmMoves.append("MOVE_CUT")

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.count, 0)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_TMHM_SPAN_MISSING" })
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_TMHM_EDIT_UNSUPPORTED_PROFILE" })
    }

    func testExpansionTutorLearnsetPlanPreviewApplyBackupReload() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root, includeTutorLearnsets: true)
        let tutorPath = root.appendingPathComponent("src/data/pokemon/tutor_learnsets.h")
        let familyPath = root.appendingPathComponent("src/data/pokemon/species_info/gen_3_families.h")
        let allLearnablesPath = root.appendingPathComponent("src/data/pokemon/all_learnables.json")
        let originalFamilyText = try String(contentsOf: familyPath, encoding: .utf8)
        let originalAllLearnablesText = try String(contentsOf: allLearnablesPath, encoding: .utf8)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })

        XCTAssertEqual(treecko.learnsets.tutor.map(\.move).sorted(), ["MOVE_MEGA_PUNCH", "MOVE_SWORD_DANCE"])
        XCTAssertEqual(treecko.learnsets.tutorSourceSpan?.relativePath, "src/data/pokemon/tutor_learnsets.h")

        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.tutorMoves.removeAll { $0 == "MOVE_MEGA_PUNCH" }
        draft.tutorMoves.append("MOVE_FURY_CUTTER")

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/tutor_learnsets.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(plan.isApplyable)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains("TUTOR(FURY_CUTTER)"))
        XCTAssertTrue(preview.contains("TUTOR(SWORD_DANCE)"))
        XCTAssertFalse(preview.contains("TUTOR(MEGA_PUNCH)"))

        let result = try SpeciesMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/tutor_learnsets.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))
        XCTAssertEqual(try String(contentsOf: familyPath, encoding: .utf8), originalFamilyText)
        XCTAssertEqual(try String(contentsOf: allLearnablesPath, encoding: .utf8), originalAllLearnablesText)

        let source = try String(contentsOf: tutorPath, encoding: .utf8)
        XCTAssertTrue(source.contains("TUTOR(FURY_CUTTER)"))
        XCTAssertFalse(source.contains("TUTOR(MEGA_PUNCH)"))

        let reloaded = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let edited = try XCTUnwrap(reloaded.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(edited.learnsets.tutor.map(\.move).sorted(), ["MOVE_FURY_CUTTER", "MOVE_SWORD_DANCE"])
    }

    func testExpansionTutorLearnsetPlanBlocksSourceDrift() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root, includeTutorLearnsets: true)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.tutorMoves.append("MOVE_FURY_CUTTER")
        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        let tutorPath = root.appendingPathComponent("src/data/pokemon/tutor_learnsets.h")
        let source = try String(contentsOf: tutorPath, encoding: .utf8)
            .replacingOccurrences(of: "TUTOR(SWORD_DANCE)", with: "TUTOR(FURY_CUTTER)")
        try write(source, to: tutorPath)

        let applyability = plan.validateApplyability()
        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(applyability.diagnostics.contains { $0.code == "SPECIES_APPLY_ORIGINAL_HASH_MISMATCH" })
    }

    func testExpansionTutorLearnsetPlanRejectsUnknownMoveConstants() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root, includeTutorLearnsets: true)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.tutorMoves.append("MOVE_NOT_REAL")

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.count, 0)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_DRAFT_CONSTANT_UNRESOLVED" && $0.message.contains("MOVE_NOT_REAL") })
    }

    func testExpansionTutorLearnsetEditsRequireParsedSourceRow() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.tutorMoves.append("MOVE_SWORD_DANCE")

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.count, 0)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_TUTOR_SPAN_MISSING" })
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_TUTOR_EDIT_UNSUPPORTED_PROFILE" })
    }

    func testExpansionEggMovePlanPreviewApplyBackupReload() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root, includeEggMoves: true)
        let eggPath = root.appendingPathComponent("src/data/pokemon/egg_moves.h")
        let familyPath = root.appendingPathComponent("src/data/pokemon/species_info/gen_3_families.h")
        let allLearnablesPath = root.appendingPathComponent("src/data/pokemon/all_learnables.json")
        let originalFamilyText = try String(contentsOf: familyPath, encoding: .utf8)
        let originalAllLearnablesText = try String(contentsOf: allLearnablesPath, encoding: .utf8)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })

        XCTAssertEqual(treecko.learnsets.egg.map(\.move), ["MOVE_CRUNCH", "MOVE_LEECH_SEED"])
        XCTAssertEqual(treecko.learnsets.eggSourceSpan?.relativePath, "src/data/pokemon/egg_moves.h")

        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.eggMoves = ["MOVE_LEECH_SEED", "MOVE_FLASH", "MOVE_CRUNCH"]

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/egg_moves.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(plan.isApplyable)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains("egg_moves(TREECKO,"))
        XCTAssertTrue(preview.contains("MOVE_FLASH"))
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_EGG_MOVES_EDIT_UNSUPPORTED_PROFILE" })

        let result = try SpeciesMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/egg_moves.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))
        XCTAssertEqual(try String(contentsOf: familyPath, encoding: .utf8), originalFamilyText)
        XCTAssertEqual(try String(contentsOf: allLearnablesPath, encoding: .utf8), originalAllLearnablesText)

        let source = try String(contentsOf: eggPath, encoding: .utf8)
        XCTAssertTrue(source.contains("egg_moves(TREECKO,"))
        XCTAssertTrue(source.contains("MOVE_FLASH"))
        XCTAssertTrue(source.contains("egg_moves(GROVYLE,"))

        let reloaded = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let edited = try XCTUnwrap(reloaded.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(edited.learnsets.egg.map(\.move), ["MOVE_LEECH_SEED", "MOVE_FLASH", "MOVE_CRUNCH"])
    }

    func testExpansionEggMovePlanBlocksSourceDrift() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root, includeEggMoves: true)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.eggMoves.append("MOVE_FLASH")
        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        let eggPath = root.appendingPathComponent("src/data/pokemon/egg_moves.h")
        let source = try String(contentsOf: eggPath, encoding: .utf8)
            .replacingOccurrences(of: "MOVE_CRUNCH", with: "MOVE_ABSORB")
        try write(source, to: eggPath)

        let applyability = plan.validateApplyability()
        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(applyability.diagnostics.contains { $0.code == "SPECIES_APPLY_ORIGINAL_HASH_MISMATCH" })
    }

    func testExpansionEggMovePlanRejectsUnknownMoveConstants() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root, includeEggMoves: true)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.eggMoves.append("MOVE_NOT_REAL")

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.count, 0)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_DRAFT_CONSTANT_UNRESOLVED" && $0.message.contains("MOVE_NOT_REAL") })
    }

    func testExpansionEggMoveEditsRequireParsedSourceRow() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.eggMoves.append("MOVE_LEECH_SEED")

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.count, 0)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_EGG_MOVES_SPAN_MISSING" })
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_EGG_MOVES_EDIT_UNSUPPORTED_PROFILE" })
    }

    func testExpansionSpeciesInfoPlannerBlocksCompositeAndAdjacentScopes() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root, scalarAliases: false)
        let speciesPath = root.appendingPathComponent("src/data/pokemon/species_info.h")
        let originalText = try String(contentsOf: speciesPath, encoding: .utf8)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var compositeDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        compositeDraft.types[1] = "TYPE_FIRE"
        compositeDraft.abilities[1] = "ABILITY_CHLOROPHYLL"
        compositeDraft.eggGroups[1] = "EGG_GROUP_MONSTER"

        let compositePlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: compositeDraft)

        XCTAssertEqual(compositePlan.changes.count, 0)
        XCTAssertFalse(compositePlan.isApplyable)
        XCTAssertTrue(compositePlan.diagnostics.contains { $0.code == "SPECIES_EXPANSION_NON_SCALAR_FIELD_BLOCKED" && $0.message.contains("types") })
        XCTAssertTrue(compositePlan.diagnostics.contains { $0.code == "SPECIES_EXPANSION_NON_SCALAR_FIELD_BLOCKED" && $0.message.contains("abilities") })
        XCTAssertTrue(compositePlan.diagnostics.contains { $0.code == "SPECIES_EXPANSION_NON_SCALAR_FIELD_BLOCKED" && $0.message.contains("eggGroups") })
        XCTAssertEqual(try String(contentsOf: speciesPath, encoding: .utf8), originalText)

        var adjacentDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        adjacentDraft.tmhmMoves.append("MOVE_CUT")
        adjacentDraft.eggMoves.append("MOVE_LEECH_SEED")
        adjacentDraft.tutorMoves.append("MOVE_SWORD_DANCE")
        adjacentDraft.evolutions.append(SpeciesEvolutionDraft(method: "EVO_LEVEL", parameter: "16", targetSpecies: "SPECIES_TREECKO"))
        adjacentDraft.pokedex?.height = "6"
        adjacentDraft.pokedex?.description = "Expansion Pokedex text remains read-only."
        adjacentDraft.assetData[.front] = testPNGData(width: 64, height: 64, paletteColorCount: 16)
        adjacentDraft.bodyColor = "BODY_COLOR_BLUE"

        let adjacentPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: adjacentDraft)

        XCTAssertEqual(adjacentPlan.changes.count, 0)
        XCTAssertFalse(adjacentPlan.isApplyable)
        XCTAssertFalse(adjacentPlan.diagnostics.contains { $0.code == "SPECIES_TMHM_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertTrue(adjacentPlan.diagnostics.contains { $0.code == "SPECIES_EGG_MOVES_SPAN_MISSING" })
        XCTAssertFalse(adjacentPlan.diagnostics.contains { $0.code == "SPECIES_EGG_MOVES_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertFalse(adjacentPlan.diagnostics.contains { $0.code == "SPECIES_TUTOR_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertFalse(adjacentPlan.diagnostics.contains { $0.code == "SPECIES_EVOLUTION_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertFalse(adjacentPlan.diagnostics.contains { $0.code == "SPECIES_POKEDEX_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertFalse(adjacentPlan.diagnostics.contains { $0.code == "SPECIES_POKEDEX_TEXT_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertTrue(adjacentPlan.diagnostics.contains { $0.code == "SPECIES_ASSET_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertTrue(adjacentPlan.diagnostics.contains { $0.code == "SPECIES_DRAFT_CONSTANT_UNRESOLVED" })
        XCTAssertEqual(try String(contentsOf: speciesPath, encoding: .utf8), originalText)
    }

    func testExpansionSpeciesInfoScalarPlanBlocksSourceDrift() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.baseStats.attack = 46
        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        let speciesPath = root.appendingPathComponent("src/data/pokemon/species_info.h")
        let source = try String(contentsOf: speciesPath, encoding: .utf8)
            .replacingOccurrences(of: ".baseHP = 40, // preserve comment", with: ".baseHP = 41, // preserve comment")
        try write(source, to: speciesPath)

        let applyability = plan.validateApplyability()
        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(applyability.diagnostics.contains { $0.code == "SPECIES_APPLY_ORIGINAL_HASH_MISMATCH" })
    }

    func testExpansionPokedexPlanPreviewApplyBackupReloadPreservesAdjacentOutputs() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root)
        let entryPath = root.appendingPathComponent("src/data/pokemon/pokedex_entries.h")
        let textPath = root.appendingPathComponent("src/data/pokemon/pokedex_text.h")
        let familyPath = root.appendingPathComponent("src/data/pokemon/species_info/gen_3_families.h")
        let generatedPath = root.appendingPathComponent("generated/pokedex/entries.json")
        let referencePath = root.appendingPathComponent("references/pokeemerald-expansion/src/data/pokemon/pokedex_entries.h")
        let romPath = root.appendingPathComponent("build/pokeemerald.gba")
        try write("{\"pokedex\":[]}\n", to: generatedPath)
        try write("// reference Pokedex entry\n", to: referencePath)
        try write(Data([0x47, 0x42, 0x41]), to: romPath)
        let originalFamilyText = try String(contentsOf: familyPath, encoding: .utf8)
        let originalGeneratedText = try String(contentsOf: generatedPath, encoding: .utf8)
        let originalReferenceText = try String(contentsOf: referencePath, encoding: .utf8)
        let originalROMData = try Data(contentsOf: romPath)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        draft.pokedex?.height = "6"
        draft.pokedex?.weight = "52"
        draft.pokedex?.categoryName = "EXPANSION \"GECKO\""
        draft.pokedex?.description = "Expansion \"description\"\\path\nwith two lines."

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.map(\.path).sorted(), [
            "src/data/pokemon/pokedex_entries.h",
            "src/data/pokemon/pokedex_text.h"
        ])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(plan.isApplyable)
        let entryPreview = try XCTUnwrap(plan.changes.first { $0.path == "src/data/pokemon/pokedex_entries.h" }?.textPreview)
        XCTAssertTrue(entryPreview.contains(".height = 6"))
        XCTAssertTrue(entryPreview.contains(".weight = 52"))
        XCTAssertTrue(entryPreview.contains(#".categoryName = _("EXPANSION \"GECKO\"")"#))
        let textPreview = try XCTUnwrap(plan.changes.first { $0.path == "src/data/pokemon/pokedex_text.h" }?.textPreview)
        XCTAssertEqual(textPreview, #"const u8 gTreeckoPokedexText[] = _("Expansion \"description\"\\path\nwith two lines.");"#)

        let result = try SpeciesMutationApplier.apply(plan: plan)

        XCTAssertEqual(result.appliedChanges.map(\.path).sorted(), [
            "src/data/pokemon/pokedex_entries.h",
            "src/data/pokemon/pokedex_text.h"
        ])
        XCTAssertTrue(result.appliedChanges.allSatisfy { FileManager.default.fileExists(atPath: $0.backupPath) })
        XCTAssertEqual(try String(contentsOf: familyPath, encoding: .utf8), originalFamilyText)
        XCTAssertEqual(try String(contentsOf: generatedPath, encoding: .utf8), originalGeneratedText)
        XCTAssertEqual(try String(contentsOf: referencePath, encoding: .utf8), originalReferenceText)
        XCTAssertEqual(try Data(contentsOf: romPath), originalROMData)
        XCTAssertTrue(try String(contentsOf: entryPath, encoding: .utf8).contains(".height = 6"))
        XCTAssertTrue(try String(contentsOf: textPath, encoding: .utf8).contains(#"Expansion \"description\"\\path\nwith two lines."#))

        let reloaded = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let edited = try XCTUnwrap(reloaded.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(edited.pokedex?.height, "6")
        XCTAssertEqual(edited.pokedex?.weight, "52")
        XCTAssertEqual(edited.pokedex?.categoryName, #"EXPANSION "GECKO""#)
        XCTAssertEqual(edited.pokedex?.description, #"Expansion "description"\\path"# + "\nwith two lines.")
    }

    func testExpansionPokedexPlanBlocksSourceDrift() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.pokedex?.height = "6"
        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        let entryPath = root.appendingPathComponent("src/data/pokemon/pokedex_entries.h")
        let source = try String(contentsOf: entryPath, encoding: .utf8)
            .replacingOccurrences(of: ".height = 5,", with: ".height = 7,")
        try write(source, to: entryPath)

        let applyability = plan.validateApplyability()
        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(applyability.diagnostics.contains { $0.code == "SPECIES_APPLY_ORIGINAL_HASH_MISMATCH" })
    }

    func testExpansionPokedexTextRequiresParsedSimpleDeclaration() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root)
        try write(
            """
            const u8 gTreeckoPokedexText[] = {
                _("Wood gecko.")
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/pokedex_text.h")
        )
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        draft.pokedex?.description = "Replacement text must not insert a declaration."

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.count, 0)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_POKEDEX_TEXT_SPAN_MISSING" })
    }

    func testExpansionPokedexPlannerKeepsAdjacentScopesBlocked() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeExpansionSpeciesProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var adjacentDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        adjacentDraft.evolutions.append(SpeciesEvolutionDraft(method: "EVO_LEVEL", parameter: "16", targetSpecies: "SPECIES_GROVYLE"))
        adjacentDraft.eggMoves.append("MOVE_LEECH_SEED")
        adjacentDraft.assetData[.front] = testPNGData(width: 64, height: 64, paletteColorCount: 16)

        let adjacentPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: adjacentDraft)

        XCTAssertEqual(adjacentPlan.changes.count, 0)
        XCTAssertFalse(adjacentPlan.isApplyable)
        XCTAssertFalse(adjacentPlan.diagnostics.contains { $0.code == "SPECIES_EVOLUTION_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertTrue(adjacentPlan.diagnostics.contains { $0.code == "SPECIES_EGG_MOVES_SPAN_MISSING" })
        XCTAssertFalse(adjacentPlan.diagnostics.contains { $0.code == "SPECIES_EGG_MOVES_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertTrue(adjacentPlan.diagnostics.contains { $0.code == "SPECIES_ASSET_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertFalse(adjacentPlan.diagnostics.contains { $0.code == "SPECIES_POKEDEX_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertFalse(adjacentPlan.diagnostics.contains { $0.code == "SPECIES_POKEDEX_TEXT_EDIT_UNSUPPORTED_PROFILE" })

        var identityDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        identityDraft.speciesID = "SPECIES_NOT_REAL"

        let identityPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: identityDraft)

        XCTAssertEqual(identityPlan.changes.count, 0)
        XCTAssertFalse(identityPlan.isApplyable)
        XCTAssertTrue(identityPlan.diagnostics.contains { $0.code == "SPECIES_PLAN_TARGET_MISSING" })
    }

    func testSpeciesMutationPlannerRewritesPokedexEntriesAndText() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        XCTAssertNotNil(draft.pokedex)
        draft.pokedex?.height = "6"
        draft.pokedex?.categoryName = "NEW \"BUG\\TYPE\""
        draft.pokedex?.description = "New \"description\"\\path\nwith two lines."

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertTrue(plan.changes.contains { $0.path == "src/data/pokemon/pokedex_entries.h" })
        XCTAssertTrue(plan.changes.contains { $0.path == "src/data/pokemon/pokedex_text.h" })

        let entryPreview = try XCTUnwrap(plan.changes.first { $0.path == "src/data/pokemon/pokedex_entries.h" }?.textPreview)
        XCTAssertTrue(entryPreview.contains(".height = 6"))
        XCTAssertTrue(entryPreview.contains(#".categoryName = _("NEW \"BUG\\TYPE\"")"#))

        let textPreview = try XCTUnwrap(plan.changes.first { $0.path == "src/data/pokemon/pokedex_text.h" }?.textPreview)
        XCTAssertEqual(textPreview, #"const u8 gTreeckoPokedexText[] = _("New \"description\"\\path\nwith two lines.");"#)

        _ = try SpeciesMutationApplier.apply(plan: plan)

        let reloaded = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let edited = try XCTUnwrap(reloaded.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(edited.pokedex?.height, "6")
        XCTAssertEqual(edited.pokedex?.categoryName, #"NEW "BUG\\TYPE""#)
        XCTAssertEqual(edited.pokedex?.description, #"New "description"\\path"# + "\nwith two lines.")
    }

    func testSpeciesMutationPlannerBlocksInvalidPokedexNumericFields() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        draft.pokedex?.height = "tall"
        draft.pokedex?.pokemonScale = "big"
        draft.pokedex?.pokemonOffset = "near"
        draft.pokedex?.trainerScale = "wide"
        draft.pokedex?.trainerOffset = "far"

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_POKEDEX_HEIGHT_INVALID" })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_POKEDEX_POKEMON_SCALE_INVALID" })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_POKEDEX_POKEMON_OFFSET_INVALID" })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_POKEDEX_TRAINER_SCALE_INVALID" })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_POKEDEX_TRAINER_OFFSET_INVALID" })
        XCTAssertFalse(plan.isApplyable)
    }

    func testSpeciesMutationPlannerStagesAssetChanges() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        let pngData = testPNGData(width: 64, height: 64, paletteColorCount: 16)
        draft.assetData[.front] = pngData

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertTrue(plan.changes.contains { $0.path == "graphics/pokemon/treecko/front.png" })
        let change = try XCTUnwrap(plan.changes.first { $0.path == "graphics/pokemon/treecko/front.png" })
        XCTAssertEqual(change.newData, pngData)
        XCTAssertEqual(change.summary, "Replace front asset")
        XCTAssertEqual(change.originalByteCount, 4)
        XCTAssertNotNil(change.originalSHA1)
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(plan.isApplyable)

        _ = try SpeciesMutationApplier.apply(plan: plan)

        let appliedData = try Data(contentsOf: root.appendingPathComponent("graphics/pokemon/treecko/front.png"))
        XCTAssertEqual(appliedData, pngData)
    }

    func testSpeciesAssetImportProvenanceIsPreservedInMutationPlan() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        let importPath = root.appendingPathComponent("incoming/front.png").path
        let pngData = testPNGData(width: 64, height: 64, paletteColorCount: 16)
        let provenance = SpeciesAssetImportValidator.provenance(
            sourcePath: importPath,
            expectedKind: .front,
            data: pngData
        )
        draft.assetData[.front] = pngData
        draft.assetImports[.front] = provenance

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertTrue(plan.isApplyable)
        XCTAssertEqual(plan.draft.assetImports[.front]?.sourcePath, importPath)
        XCTAssertEqual(plan.draft.assetImports[.front]?.detectedKind, .png)
        XCTAssertEqual(plan.draft.assetImports[.front]?.status, .ready)
        XCTAssertEqual(plan.draft.assetImports[.front]?.byteCount, pngData.count)
        XCTAssertEqual(plan.changes.first { $0.path == "graphics/pokemon/treecko/front.png" }?.newData, pngData)
    }

    func testSpeciesFootprintImportStagesSourcePNGWithFormatProvenance() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        let importPath = root.appendingPathComponent("incoming/footprint.png").path
        let pngData = testPNGData(width: 16, height: 16, paletteColorCount: 2)
        let provenance = SpeciesAssetImportValidator.provenance(
            sourcePath: importPath,
            expectedKind: .footprint,
            data: pngData
        )
        draft.assetData[.footprint] = pngData
        draft.assetImports[.footprint] = provenance

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertTrue(plan.isApplyable)
        XCTAssertEqual(provenance.status, .ready)
        XCTAssertEqual(provenance.detectedKind, .png)
        XCTAssertEqual(provenance.pngMetadata?.width, 16)
        XCTAssertEqual(provenance.pngMetadata?.height, 16)
        XCTAssertEqual(provenance.pngMetadata?.paletteColorCount, 2)
        XCTAssertEqual(plan.draft.assetImports[.footprint]?.sha1, provenance.sha1)
        let change = try XCTUnwrap(plan.changes.first { $0.path == "graphics/pokemon/treecko/footprint.png" })
        XCTAssertEqual(change.summary, "Replace footprint asset")
        XCTAssertEqual(change.newData, pngData)

        _ = try SpeciesMutationApplier.apply(plan: plan)
        let appliedData = try Data(contentsOf: root.appendingPathComponent("graphics/pokemon/treecko/footprint.png"))
        XCTAssertEqual(appliedData, pngData)
    }

    func testSpeciesFootprintImportBlocksUnsupportedFormatAndPalette() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })

        var wrongSizeDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        let wrongSize = testPNGData(width: 32, height: 32, paletteColorCount: 2)
        let wrongSizeProvenance = SpeciesAssetImportValidator.provenance(
            sourcePath: root.appendingPathComponent("incoming/footprint-large.png").path,
            expectedKind: .footprint,
            data: wrongSize
        )
        wrongSizeDraft.assetData[.footprint] = wrongSize
        wrongSizeDraft.assetImports[.footprint] = wrongSizeProvenance

        let wrongSizePlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: wrongSizeDraft)
        XCTAssertEqual(wrongSizeProvenance.status, .blocked)
        XCTAssertTrue(wrongSizeProvenance.diagnostics.contains { $0.code == "SPECIES_ASSET_IMPORT_PNG_DIMENSIONS_UNSUPPORTED" })
        XCTAssertFalse(wrongSizePlan.changes.contains { $0.path == "graphics/pokemon/treecko/footprint.png" })
        XCTAssertTrue(wrongSizePlan.diagnostics.contains { $0.code == "SPECIES_ASSET_PNG_DIMENSIONS_UNSUPPORTED" })
        XCTAssertFalse(wrongSizePlan.isApplyable)

        var paletteDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        let tooManyColors = testPNGData(width: 16, height: 16, paletteColorCount: 3)
        let paletteProvenance = SpeciesAssetImportValidator.provenance(
            sourcePath: root.appendingPathComponent("incoming/footprint-colors.png").path,
            expectedKind: .footprint,
            data: tooManyColors
        )
        paletteDraft.assetData[.footprint] = tooManyColors
        paletteDraft.assetImports[.footprint] = paletteProvenance

        let palettePlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: paletteDraft)
        XCTAssertEqual(paletteProvenance.status, .blocked)
        XCTAssertTrue(paletteProvenance.diagnostics.contains { $0.code == "SPECIES_ASSET_IMPORT_PNG_PALETTE_OVER_LIMIT" })
        XCTAssertFalse(palettePlan.changes.contains { $0.path == "graphics/pokemon/treecko/footprint.png" })
        XCTAssertTrue(palettePlan.diagnostics.contains { $0.code == "SPECIES_ASSET_PNG_PALETTE_OVER_LIMIT" })
        XCTAssertFalse(palettePlan.isApplyable)
    }

    func testSpeciesIconImportStagesSourcePNGWithFormatProvenanceAndBackup() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        let importPath = root.appendingPathComponent("incoming/icon.png").path
        let pngData = testPNGData(width: 32, height: 64, paletteColorCount: 16)
        let provenance = SpeciesAssetImportValidator.provenance(
            sourcePath: importPath,
            expectedKind: .icon,
            data: pngData
        )
        draft.assetData[.icon] = pngData
        draft.assetImports[.icon] = provenance

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertTrue(plan.isApplyable)
        XCTAssertEqual(provenance.status, .ready)
        XCTAssertEqual(provenance.detectedKind, .png)
        XCTAssertEqual(provenance.pngMetadata?.width, 32)
        XCTAssertEqual(provenance.pngMetadata?.height, 64)
        XCTAssertEqual(provenance.pngMetadata?.paletteColorCount, 16)
        XCTAssertEqual(plan.draft.assetImports[.icon]?.sha1, provenance.sha1)
        XCTAssertEqual(plan.changes.map(\.path), ["graphics/pokemon/treecko/icon.png"])
        let change = try XCTUnwrap(plan.changes.first)
        XCTAssertEqual(change.summary, "Replace icon asset")
        XCTAssertEqual(change.newData, pngData)

        let result = try SpeciesMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["graphics/pokemon/treecko/icon.png"])
        XCTAssertTrue(result.backupRootPath.contains(".pokemonhackstudio/backups/"))
        let appliedChange = try XCTUnwrap(result.appliedChanges.first)
        XCTAssertEqual(appliedChange.byteCount, pngData.count)
        XCTAssertTrue(FileManager.default.fileExists(atPath: appliedChange.backupPath))
        let backupData = try Data(contentsOf: URL(fileURLWithPath: appliedChange.backupPath))
        XCTAssertEqual(backupData, Data([0x89, 0x50, 0x4E, 0x47]))
        let appliedData = try Data(contentsOf: root.appendingPathComponent("graphics/pokemon/treecko/icon.png"))
        XCTAssertEqual(appliedData, pngData)
    }

    func testSpeciesIconImportAllowsMissingPaletteChunkAsWarning() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        let pngData = testPNGData(width: 32, height: 64)
        let provenance = SpeciesAssetImportValidator.provenance(
            sourcePath: root.appendingPathComponent("incoming/icon-rgb.png").path,
            expectedKind: .icon,
            data: pngData
        )
        draft.assetData[.icon] = pngData
        draft.assetImports[.icon] = provenance

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(provenance.status, .warning)
        XCTAssertTrue(provenance.diagnostics.contains { $0.code == "SPECIES_ASSET_IMPORT_PNG_PALETTE_UNVERIFIED" })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_ASSET_PNG_PALETTE_UNVERIFIED" })
        XCTAssertTrue(plan.isApplyable)
    }

    func testSpeciesIconImportBlocksUnsupportedDimensionsPaletteAndMissingSource() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })

        var wrongSizeDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        let wrongSize = testPNGData(width: 32, height: 32, paletteColorCount: 16)
        let wrongSizeProvenance = SpeciesAssetImportValidator.provenance(
            sourcePath: root.appendingPathComponent("incoming/icon-small.png").path,
            expectedKind: .icon,
            data: wrongSize
        )
        wrongSizeDraft.assetData[.icon] = wrongSize
        wrongSizeDraft.assetImports[.icon] = wrongSizeProvenance

        let wrongSizePlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: wrongSizeDraft)
        XCTAssertEqual(wrongSizeProvenance.status, .blocked)
        XCTAssertTrue(wrongSizeProvenance.diagnostics.contains { $0.code == "SPECIES_ASSET_IMPORT_PNG_DIMENSIONS_UNSUPPORTED" })
        XCTAssertFalse(wrongSizePlan.changes.contains { $0.path == "graphics/pokemon/treecko/icon.png" })
        XCTAssertTrue(wrongSizePlan.diagnostics.contains { $0.code == "SPECIES_ASSET_PNG_DIMENSIONS_UNSUPPORTED" })
        XCTAssertFalse(wrongSizePlan.isApplyable)

        var paletteDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        let tooManyColors = testPNGData(width: 32, height: 64, paletteColorCount: 17)
        let paletteProvenance = SpeciesAssetImportValidator.provenance(
            sourcePath: root.appendingPathComponent("incoming/icon-colors.png").path,
            expectedKind: .icon,
            data: tooManyColors
        )
        paletteDraft.assetData[.icon] = tooManyColors
        paletteDraft.assetImports[.icon] = paletteProvenance

        let palettePlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: paletteDraft)
        XCTAssertEqual(paletteProvenance.status, .blocked)
        XCTAssertTrue(paletteProvenance.diagnostics.contains { $0.code == "SPECIES_ASSET_IMPORT_PNG_PALETTE_OVER_LIMIT" })
        XCTAssertFalse(palettePlan.changes.contains { $0.path == "graphics/pokemon/treecko/icon.png" })
        XCTAssertTrue(palettePlan.diagnostics.contains { $0.code == "SPECIES_ASSET_PNG_PALETTE_OVER_LIMIT" })
        XCTAssertFalse(palettePlan.isApplyable)

        try FileManager.default.removeItem(at: root.appendingPathComponent("graphics/pokemon/treecko/icon.png"))
        var missingSourceDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        missingSourceDraft.assetData[.icon] = testPNGData(width: 32, height: 64, paletteColorCount: 16)

        let missingSourcePlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: missingSourceDraft)
        XCTAssertTrue(missingSourcePlan.diagnostics.contains { $0.code == "SPECIES_ASSET_SOURCE_MISSING" })
        XCTAssertFalse(missingSourcePlan.changes.contains { $0.path == "graphics/pokemon/treecko/icon.png" })
        XCTAssertFalse(missingSourcePlan.isApplyable)
    }

    func testSpeciesProfileSpriteImportStagesFrontBackSourcePNGsWithProvenanceAndBackups() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        let frontData = testPNGData(width: 64, height: 64, paletteColorCount: 16)
        let backData = testPNGData(width: 64, height: 64, paletteColorCount: 15)
        let frontProvenance = SpeciesAssetImportValidator.provenance(
            sourcePath: root.appendingPathComponent("incoming/front.png").path,
            expectedKind: .front,
            data: frontData
        )
        let backProvenance = SpeciesAssetImportValidator.provenance(
            sourcePath: root.appendingPathComponent("incoming/back.png").path,
            expectedKind: .back,
            data: backData
        )
        draft.assetData[.front] = frontData
        draft.assetData[.back] = backData
        draft.assetImports[.front] = frontProvenance
        draft.assetImports[.back] = backProvenance

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertTrue(plan.isApplyable)
        XCTAssertEqual(frontProvenance.status, .ready)
        XCTAssertEqual(backProvenance.status, .ready)
        XCTAssertEqual(frontProvenance.pngMetadata?.width, 64)
        XCTAssertEqual(frontProvenance.pngMetadata?.height, 64)
        XCTAssertEqual(backProvenance.pngMetadata?.width, 64)
        XCTAssertEqual(backProvenance.pngMetadata?.height, 64)
        XCTAssertEqual(plan.draft.assetImports[.front]?.sha1, frontProvenance.sha1)
        XCTAssertEqual(plan.draft.assetImports[.back]?.sha1, backProvenance.sha1)
        XCTAssertEqual(
            plan.changes.map(\.path),
            [
                "graphics/pokemon/treecko/front.png",
                "graphics/pokemon/treecko/back.png"
            ]
        )
        XCTAssertFalse(plan.changes.contains { change in
            change.path.contains(".4bpp")
                || change.path.hasSuffix(".gbapal")
                || change.path.hasSuffix(".gba")
                || change.path.contains("/build/")
        })

        let result = try SpeciesMutationApplier.apply(plan: plan)

        XCTAssertEqual(
            result.appliedChanges.map(\.path),
            [
                "graphics/pokemon/treecko/front.png",
                "graphics/pokemon/treecko/back.png"
            ]
        )
        for appliedChange in result.appliedChanges {
            XCTAssertTrue(FileManager.default.fileExists(atPath: appliedChange.backupPath))
            let backupData = try Data(contentsOf: URL(fileURLWithPath: appliedChange.backupPath))
            XCTAssertEqual(backupData, Data([0x89, 0x50, 0x4E, 0x47]))
        }
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent("graphics/pokemon/treecko/front.png")), frontData)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent("graphics/pokemon/treecko/back.png")), backData)
    }

    func testSpeciesProfileSpriteImportBlocksUnsupportedDimensionsPaletteAndMissingSource() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })

        var wrongSizeDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        let wrongSize = testPNGData(width: 32, height: 64, paletteColorCount: 16)
        let wrongSizeProvenance = SpeciesAssetImportValidator.provenance(
            sourcePath: root.appendingPathComponent("incoming/front-small.png").path,
            expectedKind: .front,
            data: wrongSize
        )
        wrongSizeDraft.assetData[.front] = wrongSize
        wrongSizeDraft.assetImports[.front] = wrongSizeProvenance

        let wrongSizePlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: wrongSizeDraft)
        XCTAssertEqual(wrongSizeProvenance.status, .blocked)
        XCTAssertTrue(wrongSizeProvenance.diagnostics.contains { $0.code == "SPECIES_ASSET_IMPORT_PNG_DIMENSIONS_UNSUPPORTED" })
        XCTAssertFalse(wrongSizePlan.changes.contains { $0.path == "graphics/pokemon/treecko/front.png" })
        XCTAssertTrue(wrongSizePlan.diagnostics.contains { $0.code == "SPECIES_ASSET_PNG_DIMENSIONS_UNSUPPORTED" })
        XCTAssertFalse(wrongSizePlan.isApplyable)

        var paletteDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        let tooManyColors = testPNGData(width: 64, height: 64, paletteColorCount: 17)
        let paletteProvenance = SpeciesAssetImportValidator.provenance(
            sourcePath: root.appendingPathComponent("incoming/back-colors.png").path,
            expectedKind: .back,
            data: tooManyColors
        )
        paletteDraft.assetData[.back] = tooManyColors
        paletteDraft.assetImports[.back] = paletteProvenance

        let palettePlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: paletteDraft)
        XCTAssertEqual(paletteProvenance.status, .blocked)
        XCTAssertTrue(paletteProvenance.diagnostics.contains { $0.code == "SPECIES_ASSET_IMPORT_PNG_PALETTE_OVER_LIMIT" })
        XCTAssertFalse(palettePlan.changes.contains { $0.path == "graphics/pokemon/treecko/back.png" })
        XCTAssertTrue(palettePlan.diagnostics.contains { $0.code == "SPECIES_ASSET_PNG_PALETTE_OVER_LIMIT" })
        XCTAssertFalse(palettePlan.isApplyable)

        try FileManager.default.removeItem(at: root.appendingPathComponent("graphics/pokemon/treecko/back.png"))
        var missingSourceDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        missingSourceDraft.assetData[.back] = testPNGData(width: 64, height: 64, paletteColorCount: 16)

        let missingSourcePlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: missingSourceDraft)
        XCTAssertTrue(missingSourcePlan.diagnostics.contains { $0.code == "SPECIES_ASSET_SOURCE_MISSING" })
        XCTAssertFalse(missingSourcePlan.changes.contains { $0.path == "graphics/pokemon/treecko/back.png" })
        XCTAssertFalse(missingSourcePlan.isApplyable)
    }

    func testRubySapphireCryAudioReplacementStagesCompatibilityReportedSourceWithBackup() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeRubyProject(at: root)
        let targetPath = "sound/direct_sound_samples/cries/treecko.aif"
        let originalData = Data([0x01, 0x02, 0x03, 0x04])
        let replacementData = Data([0x10, 0x20, 0x30])
        try write(originalData, to: root.appendingPathComponent(targetPath))
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        let source = try XCTUnwrap(GBACryAudioSourceFileScanner.sourceFiles(rootPath: root.path).first { $0.path == targetPath })
        let replacement = GBACryAudioReplacementValidator.replacementDraft(
            target: source,
            replacementSourcePath: root.appendingPathComponent("incoming/treecko.aif").path,
            data: replacementData
        )
        draft.cryAudioReplacements = [source.path: replacement]

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertTrue(plan.isApplyable)
        XCTAssertEqual(replacement.status, .ready)
        XCTAssertEqual(plan.changes.map(\.path), [targetPath])
        let change = try XCTUnwrap(plan.changes.first)
        XCTAssertEqual(change.summary, "Replace cry/audio source")
        XCTAssertEqual(change.originalByteCount, originalData.count)
        XCTAssertEqual(change.originalSHA1, pokemonHackSHA1Hex(originalData))
        XCTAssertEqual(change.newByteCount, replacementData.count)
        XCTAssertEqual(change.newData, replacementData)

        let result = try SpeciesMutationApplier.apply(plan: plan)

        XCTAssertEqual(result.appliedChanges.map(\.path), [targetPath])
        let applied = try XCTUnwrap(result.appliedChanges.first)
        XCTAssertTrue(FileManager.default.fileExists(atPath: applied.backupPath))
        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: applied.backupPath)), originalData)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(targetPath)), replacementData)
    }

    func testRubySapphireCryAudioReplacementBlocksMissingWrongKindEmptyAndDriftedSources() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeRubyProject(at: root)
        let targetPath = "sound/direct_sound_samples/cries/treecko.aif"
        try write(Data([0x01, 0x02, 0x03]), to: root.appendingPathComponent(targetPath))
        var catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        var treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var source = try XCTUnwrap(GBACryAudioSourceFileScanner.sourceFiles(rootPath: root.path).first { $0.path == targetPath })

        var wrongKindDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        let wrongKindReplacement = GBACryAudioReplacementValidator.replacementDraft(
            target: source,
            replacementSourcePath: root.appendingPathComponent("incoming/treecko.wav").path,
            data: Data([0x04])
        )
        wrongKindDraft.cryAudioReplacements = [source.path: wrongKindReplacement]
        let wrongKindPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: wrongKindDraft)
        XCTAssertEqual(wrongKindReplacement.status, .blocked)
        XCTAssertTrue(wrongKindPlan.diagnostics.contains { $0.code == "GBA_CRY_AUDIO_REPLACEMENT_KIND_MISMATCH" })
        XCTAssertTrue(wrongKindPlan.diagnostics.contains { $0.code == "SPECIES_CRY_AUDIO_REPLACEMENT_BLOCKED" })
        XCTAssertFalse(wrongKindPlan.isApplyable)

        var emptyDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        let emptyReplacement = GBACryAudioReplacementValidator.replacementDraft(
            target: source,
            replacementSourcePath: root.appendingPathComponent("incoming/treecko.aif").path,
            data: Data()
        )
        emptyDraft.cryAudioReplacements = [source.path: emptyReplacement]
        let emptyPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: emptyDraft)
        XCTAssertEqual(emptyReplacement.status, .blocked)
        XCTAssertTrue(emptyPlan.diagnostics.contains { $0.code == "GBA_CRY_AUDIO_REPLACEMENT_EMPTY" })
        XCTAssertTrue(emptyPlan.diagnostics.contains { $0.code == "SPECIES_CRY_AUDIO_REPLACEMENT_DATA_EMPTY" })
        XCTAssertFalse(emptyPlan.isApplyable)

        var missingTargetDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        let missingTargetReplacement = GBACryAudioReplacementValidator.replacementDraft(
            target: source,
            replacementSourcePath: root.appendingPathComponent("incoming/treecko.aif").path,
            data: Data([0x05])
        )
        missingTargetDraft.cryAudioReplacements = [source.path: missingTargetReplacement]
        try FileManager.default.removeItem(at: root.appendingPathComponent(targetPath))
        let missingTargetPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: missingTargetDraft)
        XCTAssertTrue(missingTargetPlan.diagnostics.contains { $0.code == "SPECIES_CRY_AUDIO_TARGET_NOT_REPORTED" })
        XCTAssertFalse(missingTargetPlan.isApplyable)

        try write(Data([0x01, 0x02, 0x03]), to: root.appendingPathComponent(targetPath))
        catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        source = try XCTUnwrap(GBACryAudioSourceFileScanner.sourceFiles(rootPath: root.path).first { $0.path == targetPath })
        var driftDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        let driftReplacement = GBACryAudioReplacementValidator.replacementDraft(
            target: source,
            replacementSourcePath: root.appendingPathComponent("incoming/treecko.aif").path,
            data: Data([0x06])
        )
        driftDraft.cryAudioReplacements = [source.path: driftReplacement]
        try write(Data([0x09, 0x09, 0x09]), to: root.appendingPathComponent(targetPath))
        let driftPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: driftDraft)
        XCTAssertTrue(driftPlan.diagnostics.contains { $0.code == "SPECIES_CRY_AUDIO_SOURCE_CHANGED" })
        XCTAssertFalse(driftPlan.isApplyable)
    }

    func testCryAudioReplacementBlocksNonRubyAndReferenceRoots() throws {
        let emeraldTemp = try SpeciesCatalogTemporaryDirectory()
        let emeraldRoot = emeraldTemp.url
        try makeEmeraldProject(at: emeraldRoot)
        let targetPath = "sound/direct_sound_samples/cries/treecko.aif"
        try write(Data([0x01, 0x02, 0x03]), to: emeraldRoot.appendingPathComponent(targetPath))
        let emeraldCatalog = try ProjectSpeciesCatalogBuilder.build(path: emeraldRoot.path)
        let emeraldTreecko = try XCTUnwrap(emeraldCatalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var emeraldDraft = try XCTUnwrap(SpeciesEditDraft(detail: emeraldTreecko))
        let emeraldSource = try XCTUnwrap(GBACryAudioSourceFileScanner.sourceFiles(rootPath: emeraldRoot.path).first { $0.path == targetPath })
        emeraldDraft.cryAudioReplacements = [
            emeraldSource.path: GBACryAudioReplacementValidator.replacementDraft(
                target: emeraldSource,
                replacementSourcePath: emeraldRoot.appendingPathComponent("incoming/treecko.aif").path,
                data: Data([0x04])
            )
        ]

        let emeraldPlan = SpeciesMutationPlanner.plan(catalog: emeraldCatalog, draft: emeraldDraft)

        XCTAssertTrue(emeraldPlan.diagnostics.contains { $0.code == "SPECIES_CRY_AUDIO_UNSUPPORTED_PROFILE" })
        XCTAssertFalse(emeraldPlan.isApplyable)

        let referenceTemp = try SpeciesCatalogTemporaryDirectory()
        let referenceRoot = referenceTemp.url.appendingPathComponent("references/pokeruby")
        try makeRubyProject(at: referenceRoot)
        try write(Data([0x01, 0x02, 0x03]), to: referenceRoot.appendingPathComponent(targetPath))
        let referenceCatalog = try ProjectSpeciesCatalogBuilder.build(path: referenceRoot.path)
        let referenceTreecko = try XCTUnwrap(referenceCatalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var referenceDraft = try XCTUnwrap(SpeciesEditDraft(detail: referenceTreecko))
        let referenceSource = try XCTUnwrap(GBACryAudioSourceFileScanner.sourceFiles(rootPath: referenceRoot.path).first { $0.path == targetPath })
        referenceDraft.cryAudioReplacements = [
            referenceSource.path: GBACryAudioReplacementValidator.replacementDraft(
                target: referenceSource,
                replacementSourcePath: referenceRoot.appendingPathComponent("incoming/treecko.aif").path,
                data: Data([0x04])
            )
        ]

        let referencePlan = SpeciesMutationPlanner.plan(catalog: referenceCatalog, draft: referenceDraft)

        XCTAssertTrue(referencePlan.diagnostics.contains { $0.code == "SPECIES_CRY_AUDIO_REFERENCE_ROOT_BLOCKED" })
        XCTAssertFalse(referencePlan.isApplyable)
    }

    func testSpeciesMutationPlannerStagesFireRedAssetChanges() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeFireRedProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        let pngData = testPNGData(width: 64, height: 64, paletteColorCount: 16)
        draft.assetData[.back] = pngData

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        let change = try XCTUnwrap(plan.changes.first { $0.path == "graphics/pokemon/treecko/back.png" })
        XCTAssertEqual(change.newData, pngData)
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(plan.isApplyable)
    }

    func testSpeciesMutationPlannerRejectsMalformedAssetPNG() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        draft.assetData[.front] = Data("DUMMY PNG".utf8)

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertFalse(plan.changes.contains { $0.path == "graphics/pokemon/treecko/front.png" })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_ASSET_PNG_INVALID" })
        XCTAssertFalse(plan.isApplyable)
    }

    func testSpeciesMutationPlannerRejectsWrongKindAssetData() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })

        var spriteDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        spriteDraft.assetData[.front] = testJASCPalette(colorCount: 16)
        let spritePlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: spriteDraft)
        XCTAssertFalse(spritePlan.changes.contains { $0.path == "graphics/pokemon/treecko/front.png" })
        XCTAssertTrue(spritePlan.diagnostics.contains { $0.code == "SPECIES_ASSET_PNG_INVALID" })
        XCTAssertFalse(spritePlan.isApplyable)

        var paletteDraft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        paletteDraft.assetData[.normalPalette] = testPNGData(width: 64, height: 64, paletteColorCount: 16)
        let palettePlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: paletteDraft)
        XCTAssertFalse(palettePlan.changes.contains { $0.path == "graphics/pokemon/treecko/normal.pal" })
        XCTAssertTrue(palettePlan.diagnostics.contains { $0.code == "SPECIES_ASSET_PALETTE_INVALID" })
        XCTAssertFalse(palettePlan.isApplyable)
    }

    func testSpeciesMutationPlannerValidatesPaletteAssetPolicy() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        draft.assetData[.normalPalette] = testJASCPalette(colorCount: 16)
        let validPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertTrue(validPlan.changes.contains { $0.path == "graphics/pokemon/treecko/normal.pal" })
        XCTAssertTrue(validPlan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(validPlan.isApplyable)

        draft.assetData[.normalPalette] = testJASCPalette(colorCount: 17)
        let overLimitPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertFalse(overLimitPlan.changes.contains { $0.path == "graphics/pokemon/treecko/normal.pal" })
        XCTAssertTrue(overLimitPlan.diagnostics.contains { $0.code == "SPECIES_ASSET_PALETTE_OVER_LIMIT" })
        XCTAssertFalse(overLimitPlan.isApplyable)

        draft.assetData[.normalPalette] = testJASCPalette(colorCount: 0)
        let missingSlotPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertFalse(missingSlotPlan.changes.contains { $0.path == "graphics/pokemon/treecko/normal.pal" })
        XCTAssertTrue(missingSlotPlan.diagnostics.contains { $0.code == "SPECIES_ASSET_PALETTE_SLOT_ZERO_MISSING" })
        XCTAssertFalse(missingSlotPlan.isApplyable)

        draft.assetData[.normalPalette] = Data("not a palette".utf8)
        let malformedPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertFalse(malformedPlan.changes.contains { $0.path == "graphics/pokemon/treecko/normal.pal" })
        XCTAssertTrue(malformedPlan.diagnostics.contains { $0.code == "SPECIES_ASSET_PALETTE_INVALID" })
        XCTAssertFalse(malformedPlan.isApplyable)
    }

    func testSpeciesPaletteImportBlocksBinaryGBAPaletteBytesForSourceTargets() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        let binaryPalette = Data(repeating: 0, count: 32)

        let provenance = SpeciesAssetImportValidator.provenance(
            sourcePath: root.appendingPathComponent("incoming/normal.gbapal").path,
            expectedKind: .normalPalette,
            data: binaryPalette
        )
        draft.assetData[.normalPalette] = binaryPalette
        draft.assetImports[.normalPalette] = provenance

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(provenance.status, .blocked)
        XCTAssertTrue(provenance.diagnostics.contains { $0.code == "SPECIES_ASSET_IMPORT_BINARY_PALETTE_BLOCKED" })
        XCTAssertFalse(plan.changes.contains { $0.path == "graphics/pokemon/treecko/normal.pal" })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SPECIES_ASSET_BINARY_PALETTE_BLOCKED" })
        XCTAssertFalse(plan.isApplyable)
    }

    func testSpeciesMutationPlannerBlocksAssetApplyAfterSourceHashChanges() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.assetData[.front] = testPNGData(width: 64, height: 64, paletteColorCount: 16)
        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        try write(testPNGData(width: 32, height: 32, paletteColorCount: 16), to: root.appendingPathComponent("graphics/pokemon/treecko/front.png"))

        let applyability = plan.validateApplyability()
        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(applyability.diagnostics.contains { $0.code == "SPECIES_APPLY_ORIGINAL_SIZE_MISMATCH" || $0.code == "SPECIES_APPLY_ORIGINAL_HASH_MISMATCH" })
    }

    func testSpeciesMutationPlannerKeepsAssetTargetsOnSourcePaths() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.assetData[.front] = testPNGData(width: 64, height: 64, paletteColorCount: 16)
        draft.assetData[.normalPalette] = testJASCPalette(colorCount: 16)

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(
            plan.changes.map(\.path).filter { $0.hasPrefix("graphics/pokemon/treecko/") }.sorted(),
            [
                "graphics/pokemon/treecko/front.png",
                "graphics/pokemon/treecko/normal.pal"
            ]
        )
        XCTAssertFalse(plan.changes.contains { $0.path.contains(".4bpp") || $0.path.hasSuffix(".gbapal") || $0.path.contains("/build/") })
    }

    func testSpeciesMutationPlannerRendersFireRedTMHMMacros() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeFireRedProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.tmhmMoves.append("MOVE_FLASH")

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        let tmhmPreview = try XCTUnwrap(plan.changes.first { $0.path == "src/data/pokemon/tmhm_learnsets.h" }?.textPreview)
        XCTAssertTrue(tmhmPreview.contains("TMHM_LEARNSET"))
        XCTAssertTrue(tmhmPreview.contains("TMHM(HM05_FLASH)"))
    }

    func testSpeciesMutationPlannerBlocksChangedSourceHash() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))
        draft.baseStats.hp = 99
        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        try "changed\n".write(to: root.appendingPathComponent("src/data/pokemon/species_info.h"), atomically: true, encoding: .utf8)

        let applyability = plan.validateApplyability()
        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(applyability.diagnostics.contains { $0.code == "SPECIES_APPLY_ORIGINAL_SIZE_MISMATCH" || $0.code == "SPECIES_APPLY_ORIGINAL_HASH_MISMATCH" })
    }

    private func makeEmeraldProject(at root: URL) throws {
        try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try writeClassicConstants(at: root)
        try write(Data([0x89, 0x50, 0x4E, 0x47]), to: root.appendingPathComponent("graphics/pokemon/treecko/front.png"))
        try write(Data([0x89, 0x50, 0x4E, 0x47]), to: root.appendingPathComponent("graphics/pokemon/treecko/back.png"))
        try write(Data([0x89, 0x50, 0x4E, 0x47]), to: root.appendingPathComponent("graphics/pokemon/treecko/icon.png"))
        try write(Data([0x89, 0x50, 0x4E, 0x47]), to: root.appendingPathComponent("graphics/pokemon/treecko/footprint.png"))
        try write("JASC-PAL\n", to: root.appendingPathComponent("graphics/pokemon/treecko/normal.pal"))

        try write(
            """
            const struct SpeciesInfo gSpeciesInfo[] =
            {
                [SPECIES_TREECKO] =
                {
                    .baseHP        = 40,
                    .baseAttack    = 45,
                    .baseDefense   = 35,
                    .baseSpeed     = 70,
                    .baseSpAttack  = 65,
                    .baseSpDefense = 55,
                    .types = { TYPE_GRASS, TYPE_GRASS },
                    .catchRate = 45,
                    .expYield = 65,
                    .evYield_HP        = 0,
                    .evYield_Attack    = 0,
                    .evYield_Defense   = 0,
                    .evYield_Speed     = 1,
                    .evYield_SpAttack  = 0,
                    .evYield_SpDefense = 0,
                    .itemCommon = ITEM_NONE,
                    .itemRare   = ITEM_NONE,
                    .genderRatio = PERCENT_FEMALE(12.5),
                    .eggCycles = 20,
                    .friendship = STANDARD_FRIENDSHIP,
                    .growthRate = GROWTH_MEDIUM_SLOW,
                    .eggGroups = { EGG_GROUP_MONSTER, EGG_GROUP_DRAGON },
                    .abilities = {ABILITY_OVERGROW, ABILITY_NONE},
                    .safariZoneFleeRate = 0,
                    .bodyColor = BODY_COLOR_GREEN,
                    .noFlip = FALSE,
                },
                [SPECIES_GROVYLE] = { .baseHP = 50 },
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/species_info.h")
        )
        try write(
            """
            const u16 *const gLevelUpLearnsets[NUM_SPECIES] =
            {
                [SPECIES_TREECKO] = sTreeckoLevelUpLearnset,
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/level_up_learnset_pointers.h")
        )
        try write(
            """
            static const u16 sTreeckoLevelUpLearnset[] = {
                LEVEL_UP_MOVE( 1, MOVE_POUND),
                LEVEL_UP_MOVE( 1, MOVE_LEER),
                LEVEL_UP_MOVE( 6, MOVE_ABSORB),
                LEVEL_UP_END
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/level_up_learnsets.h")
        )
        try write(
            """
            union TMHMLearnset gTMHMLearnsets[NUM_SPECIES] =
            {
                [SPECIES_TREECKO] = { .learnset = {
                    .CUT = TRUE,
                    .BULLET_SEED = TRUE,
                } },
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/tmhm_learnsets.h")
        )
        try write(
            """
            const u16 gEggMoves[] = {
                egg_moves(TREECKO,
                          MOVE_CRUNCH,
                          MOVE_LEECH_SEED),
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/egg_moves.h")
        )
        try writeRubyTutorLearnsets(at: root)
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
        try write(
            """
            const u8 gTreeckoPokedexText[] = _(
                \"It makes its nest in a giant tree in the\\n\"
                \"forest. It is said to be the protector of the forest.\");
            """,
            to: root.appendingPathComponent("src/data/pokemon/pokedex_text.h")
        )
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

    private func makeFireRedProject(at root: URL) throws {
        try makeEmeraldProject(at: root)
        try write("poke$(BUILD_NAME).gba\n", to: root.appendingPathComponent("Makefile"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/quest_log"), withIntermediateDirectories: true)
        try write(
            """
            static const u32 sTMHMLearnsets[][2] =
            {
                [SPECIES_TREECKO]     = TMHM_LEARNSET(TMHM(TM09_BULLET_SEED)
                                                    | TMHM(HM01_CUT)),
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/tmhm_learnsets.h")
        )
    }

    private func makeExpansionSpeciesProject(
        at root: URL,
        scalarAliases: Bool = true,
        includeLevelUpLearnsets: Bool = false,
        includeTMHMLearnsets: Bool = false,
        includeTutorLearnsets: Bool = false,
        includeEvolutionRows: Bool = false,
        includeEggMoves: Bool = false
    ) throws {
        try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics"), withIntermediateDirectories: true)
        try write("// Expansion marker\n", to: root.appendingPathComponent("include/constants/expansion.h"))
        try writeClassicConstants(at: root)
        let typeFields = scalarAliases
            ? """
                    .type1 = TYPE_GRASS,
                    .type2 = TYPE_GRASS,
            """
            : """
                    .types = { TYPE_GRASS, TYPE_GRASS },
            """
        let eggGroupFields = scalarAliases
            ? """
                    .eggGroup1 = EGG_GROUP_MONSTER,
                    .eggGroup2 = EGG_GROUP_DRAGON,
            """
            : """
                    .eggGroups = { EGG_GROUP_MONSTER, EGG_GROUP_DRAGON },
            """
        let abilityFields = scalarAliases
            ? """
                    .ability1 = ABILITY_OVERGROW,
                    .ability2 = ABILITY_NONE,
                    .hiddenAbility = ABILITY_CHLOROPHYLL,
            """
            : """
                    .abilities = {ABILITY_OVERGROW, ABILITY_NONE},
                    .hiddenAbility = ABILITY_CHLOROPHYLL,
            """

        try write(
            """
            const struct SpeciesInfo gSpeciesInfo[] =
            {
                [SPECIES_TREECKO] =
                {
                    .baseHP = 40, // preserve comment
                    .baseAttack    = 45,
                    .baseDefense   = 35,
                    .baseSpeed     = 70,
                    .baseSpAttack  = 65,
                    .baseSpDefense = 55,
            \(typeFields)
                    .catchRate = 45,
                    .baseExp = 65,
                    .evYield_HP        = 0,
                    .evYield_Attack    = 0,
                    .evYield_Defense   = 0,
                    .evYield_Speed     = 1,
                    .evYield_SpAttack  = 0,
                    .evYield_SpDefense = 0,
                    .item1 = ITEM_NONE,
                    .item2 = ITEM_NONE,
                    .genderRatio = PERCENT_FEMALE(12.5),
                    .eggCycles = 20,
                    .friendship = 70,
                    .growthRate = GROWTH_MEDIUM_SLOW,
            \(eggGroupFields)
            \(abilityFields)
                    .safariZoneFleeRate = 0,
                    .bodyColor = BODY_COLOR_GREEN,
                    .formSpeciesIdTable = sTreeckoFormSpeciesIdTable,
                    .formChangeTable = sTreeckoFormChangeTable,
                    .mysteryExpansionField = KEEP_ME,
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
            // Generated family supplement stays read-only for PHS-T57D.
            static const u16 sTreeckoFormSpeciesIdTable[] = {
                SPECIES_TREECKO,
                SPECIES_NONE,
            };
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
        if includeLevelUpLearnsets {
            try write(
                """
                static const u16 sTreeckoLevelUpLearnset[] = {
                    LEVEL_UP_MOVE( 1, MOVE_POUND),
                    LEVEL_UP_MOVE( 1, MOVE_LEER),
                    LEVEL_UP_MOVE( 6, MOVE_ABSORB),
                    LEVEL_UP_END
                };
                """,
                to: root.appendingPathComponent("src/data/pokemon/level_up_learnsets/treecko.h")
            )
        }
        if includeTMHMLearnsets {
            try write(
                """
                const struct TMHMLearnset sTMHMLearnsets[] =
                {
                    [SPECIES_TREECKO] = { .learnset = {
                        .BULLET_SEED = TRUE,
                        .CUT = TRUE,
                    } },
                };
                """,
                to: root.appendingPathComponent("src/data/pokemon/tmhm_learnsets.h")
            )
        }
        if includeTutorLearnsets {
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
        if includeEvolutionRows {
            try write(
                """
                const struct Evolution gEvolutionTable[NUM_SPECIES][EVOS_PER_MON] =
                {
                    [SPECIES_TREECKO] = {
                                            { EVO_LEVEL, 16, SPECIES_GROVYLE },
                                            { EVO_ITEM, ITEM_POTION, SPECIES_TREECKO_MEGA }
                                        },
                };
                """,
                to: root.appendingPathComponent("src/data/pokemon/evolution.h")
            )
        }
        if includeEggMoves {
            try write(
                """
                const u16 gEggMoves[] = {
                    egg_moves(TREECKO,
                              MOVE_CRUNCH,
                              MOVE_LEECH_SEED),
                    egg_moves(GROVYLE,
                              MOVE_CRUNCH),
                    EGG_MOVES_TERMINATOR
                };
                """,
                to: root.appendingPathComponent("src/data/pokemon/egg_moves.h")
            )
        }
        if includeLevelUpLearnsets || includeTMHMLearnsets || includeTutorLearnsets || includeEggMoves {
            try write(
                """
                {
                  "SPECIES_TREECKO": [
                    "MOVE_POUND",
                    "MOVE_LEER",
                    "MOVE_ABSORB",
                    "MOVE_BULLET_SEED",
                    "MOVE_CUT",
                    "MOVE_FLASH",
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
    }

    private func makeRubyProject(at root: URL) throws {
        try write(
            """
            GAME_VERSION ?= RUBY
            BUILD_NAME := ruby
            """,
            to: root.appendingPathComponent("config.mk")
        )
        try write("ROM := poke$(BUILD_NAME).gba\n", to: root.appendingPathComponent("Makefile"))
        try write("placeholder\n", to: root.appendingPathComponent("ruby.sha1"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics"), withIntermediateDirectories: true)
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try writeClassicConstants(at: root)

        try write(
            """
            const struct BaseStats gBaseStats[] =
            {
                [SPECIES_NONE] = {0},

                [SPECIES_TREECKO] =
                {
                    .baseHP        = 40,
                    .baseAttack    = 45,
                    .baseDefense   = 35,
                    .baseSpeed     = 70,
                    .baseSpAttack  = 65,
                    .baseSpDefense = 55,
                    .type1 = TYPE_GRASS,
                    .type2 = TYPE_GRASS,
                    .catchRate = 45,
                    .expYield = 65,
                    .evYield_HP        = 0,
                    .evYield_Attack    = 0,
                    .evYield_Defense   = 0,
                    .evYield_Speed     = 1,
                    .evYield_SpAttack  = 0,
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

                [SPECIES_GROVYLE] =
                {
                    .baseHP        = 50,
                    .baseAttack    = 65,
                    .baseDefense   = 45,
                    .baseSpeed     = 95,
                    .baseSpAttack  = 85,
                    .baseSpDefense = 65,
                    .type1 = TYPE_GRASS,
                    .type2 = TYPE_GRASS,
                    .catchRate = 45,
                    .expYield = 141,
                    .evYield_HP        = 0,
                    .evYield_Attack    = 0,
                    .evYield_Defense   = 0,
                    .evYield_Speed     = 2,
                    .evYield_SpAttack  = 0,
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
                [SPECIES_TREECKO] = {{EVO_LEVEL, 16, SPECIES_GROVYLE}},
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
                LEVEL_UP_MOVE( 1, MOVE_LEER),
                LEVEL_UP_MOVE( 6, MOVE_ABSORB),
                LEVEL_UP_END
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/level_up_learnsets.h")
        )
        try write(
            """
            union TMHMLearnset gTMHMLearnsets[NUM_SPECIES] =
            {
                [SPECIES_TREECKO] = { .learnset = {
                    .BULLET_SEED = TRUE,
                } },
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/tmhm_learnsets.h")
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
            to: root.appendingPathComponent("src/data/pokedex_entries_en.h")
        )
        try write(
            """
            const u8 gTreeckoPokedexText[] = _("It makes its nest in a giant tree.");
            """,
            to: root.appendingPathComponent("src/data/pokedex_text_en.h")
        )
    }

    private func writeRubyEggMoves(at root: URL, includeGrovyle: Bool = true) throws {
        let grovyleRow = includeGrovyle
            ? """
                egg_moves(GROVYLE,
                          MOVE_CRUNCH),
            """
            : ""
        try write(
            """
            const u16 gEggMoves[] = {
                egg_moves(TREECKO,
                          MOVE_CRUNCH,
                          MOVE_LEECH_SEED),
            \(grovyleRow)    EGG_MOVES_TERMINATOR
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/egg_moves.h")
        )
    }

    private func testPNGData(width: UInt32, height: UInt32, paletteColorCount: Int? = nil) -> Data {
        var data = Data([137, 80, 78, 71, 13, 10, 26, 10])
        var ihdr = Data()
        ihdr.appendUInt32BE(width)
        ihdr.appendUInt32BE(height)
        ihdr.append(contentsOf: [8, 3, 0, 0, 0])
        data.appendPNGChunk(type: "IHDR", payload: ihdr)
        if let paletteColorCount {
            data.appendPNGChunk(type: "PLTE", payload: Data(repeating: 0, count: paletteColorCount * 3))
        }
        data.appendPNGChunk(type: "IEND", payload: Data())
        return data
    }

    private func testJASCPalette(colorCount: Int) -> Data {
        let colors = (0..<colorCount).map { index -> String in
            let channel = (index * 8) % 256
            return "\(channel) \(channel) \(channel)"
        }
        return Data(("JASC-PAL\n0100\n\(colorCount)\n" + colors.joined(separator: "\n") + "\n").utf8)
    }

    private func writeClassicConstants(at root: URL) throws {
        try write(
            """
            #define TYPE_NORMAL 0
            #define TYPE_FIRE 10
            #define TYPE_GRASS 12
            #define EGG_GROUP_NONE 0
            #define EGG_GROUP_MONSTER 1
            #define EGG_GROUP_DRAGON 14
            #define GROWTH_MEDIUM_FAST 0
            #define GROWTH_MEDIUM_SLOW 3
            #define GROWTH_FAST 4
            #define BODY_COLOR_RED 0
            #define BODY_COLOR_GREEN 5
            #define EVO_LEVEL 4
            #define EVO_ITEM 7
            #define EVO_TRADE_ITEM 8
            #define EVO_FRIENDSHIP 9
            #define FORM_CHANGE_BATTLE_MEGA_EVOLUTION 1
            #define FORM_CHANGE_ITEM_HOLD 2
            """,
            to: root.appendingPathComponent("include/constants/pokemon.h")
        )
        try write(
            """
            #define SPECIES_TREECKO 1
            #define SPECIES_GROVYLE 2
            #define SPECIES_TREECKO_MEGA 3
            #define SPECIES_TREECKO_PRIMAL 4
            """,
            to: root.appendingPathComponent("include/constants/species.h")
        )
        try write(
            """
            #define ABILITY_NONE 0
            #define ABILITY_OVERGROW 65
            #define ABILITY_CHLOROPHYLL 34
            """,
            to: root.appendingPathComponent("include/constants/abilities.h")
        )
        try write(
            """
            #define ITEM_NONE 0
            #define ITEM_POTION 1
            #define ITEM_TM09_BULLET_SEED ITEM_TM09
            #define ITEM_HM01_CUT ITEM_HM01
            #define ITEM_HM05_FLASH ITEM_HM05
            """,
            to: root.appendingPathComponent("include/constants/items.h")
        )
        try write(
            """
            #define MOVE_NONE 0
            #define MOVE_POUND 1
            #define MOVE_LEER 2
            #define MOVE_ABSORB 3
            #define MOVE_BULLET_SEED 4
            #define MOVE_CUT 5
            #define MOVE_TACKLE 6
            #define MOVE_FLASH 7
            #define MOVE_CRUNCH 8
            #define MOVE_LEECH_SEED 9
            #define MOVE_FURY_CUTTER 10
            #define MOVE_MEGA_PUNCH 11
            #define MOVE_SWORD_DANCE 12
            """,
            to: root.appendingPathComponent("include/constants/moves.h")
        )
    }

    private func write(_ text: String, to url: URL) throws {
        try write(Data(text.utf8), to: url)
    }

    private func write(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }
    func testSpeciesMutationPlannerRewritesEvolutions() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        draft.evolutions[0].parameter = "18"

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        let evolutionChange = try XCTUnwrap(plan.changes.first { $0.path == "src/data/pokemon/evolution.h" })
        let evolutionPreview = try XCTUnwrap(evolutionChange.textPreview)

        XCTAssertTrue(evolutionPreview.contains("[SPECIES_TREECKO] = {{ EVO_LEVEL, 18, SPECIES_GROVYLE }}"))

        _ = try SpeciesMutationApplier.apply(plan: plan)
        let reloaded = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let edited = try XCTUnwrap(reloaded.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(edited.evolutions.first?.parameter, "18")
    }

    func testSpeciesMutationPlannerRewritesMultipleEvolutions() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        draft.evolutions.append(SpeciesEvolutionDraft(method: "EVO_ITEM", parameter: "ITEM_POTION", targetSpecies: "SPECIES_GROVYLE"))

        let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)

        let evolutionChange = try XCTUnwrap(plan.changes.first { $0.path == "src/data/pokemon/evolution.h" })
        let evolutionPreview = try XCTUnwrap(evolutionChange.textPreview)

        XCTAssertTrue(evolutionPreview.contains("[SPECIES_TREECKO] = {"))
        XCTAssertTrue(evolutionPreview.contains("{ EVO_LEVEL, 16, SPECIES_GROVYLE },"))
        XCTAssertTrue(evolutionPreview.contains("{ EVO_ITEM, ITEM_POTION, SPECIES_GROVYLE }"))

        _ = try SpeciesMutationApplier.apply(plan: plan)
        let reloaded = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let edited = try XCTUnwrap(reloaded.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(edited.evolutions.count, 2)
        XCTAssertEqual(edited.evolutions.last?.method, "EVO_ITEM")
        XCTAssertEqual(edited.evolutions.last?.parameter, "ITEM_POTION")
    }

    func testSpeciesMutationPlannerHandlesEvolutionRemovalAndComplexMethodValidation() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeEmeraldProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        draft.evolutions.removeAll()
        let removalPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)
        let removalPreview = try XCTUnwrap(removalPlan.changes.first { $0.path == "src/data/pokemon/evolution.h" }?.textPreview)
        XCTAssertEqual(removalPreview, "    [SPECIES_TREECKO] = {},")

        draft.evolutions = [
            SpeciesEvolutionDraft(method: "EVO_TRADE_ITEM", parameter: "ITEM_POTION", targetSpecies: "SPECIES_GROVYLE")
        ]
        let tradeItemPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertTrue(tradeItemPlan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(tradeItemPlan.changes.first { $0.path == "src/data/pokemon/evolution.h" }?.textPreview?.contains("EVO_TRADE_ITEM, ITEM_POTION") == true)

        draft.evolutions = [
            SpeciesEvolutionDraft(method: "EVO_FRIENDSHIP", parameter: "16", targetSpecies: "SPECIES_GROVYLE")
        ]
        let invalidParameterPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertTrue(invalidParameterPlan.diagnostics.contains { $0.code == "SPECIES_EVOLUTION_PARAMETER_INVALID" })
        XCTAssertFalse(invalidParameterPlan.isApplyable)

        let grovyle = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_GROVYLE" })
        var grovyleDraft = try XCTUnwrap(SpeciesEditDraft(detail: grovyle))
        grovyleDraft.evolutions.append(SpeciesEvolutionDraft(method: "EVO_LEVEL", parameter: "36", targetSpecies: "SPECIES_TREECKO"))
        let missingRowPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: grovyleDraft)
        XCTAssertTrue(missingRowPlan.diagnostics.contains { $0.code == "SPECIES_EVOLUTION_SPAN_MISSING" })
        XCTAssertFalse(missingRowPlan.isApplyable)
    }
}

private extension Data {
    mutating func appendUInt32BE(_ value: UInt32) {
        append(UInt8((value >> 24) & 0xff))
        append(UInt8((value >> 16) & 0xff))
        append(UInt8((value >> 8) & 0xff))
        append(UInt8(value & 0xff))
    }

    mutating func appendPNGChunk(type: String, payload: Data) {
        appendUInt32BE(UInt32(payload.count))
        append(contentsOf: type.utf8)
        append(payload)
        appendUInt32BE(0)
    }
}

private final class SpeciesCatalogTemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackSpeciesCatalogTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
