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

    func testSpeciesMutationPlannerStagesFireRedAssetChanges() throws {
        let temp = try SpeciesCatalogTemporaryDirectory()
        let root = temp.url
        try makeFireRedProject(at: root)
        let catalog = try ProjectSpeciesCatalogBuilder.build(path: root.path)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        var draft = try XCTUnwrap(SpeciesEditDraft(detail: treecko))

        let pngData = testPNGData(width: 32, height: 64, paletteColorCount: 16)
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
            const u16 gTutorLearnsets[] =
            {
                [SPECIES_TREECKO] = (TUTOR(MEGA_PUNCH) | TUTOR(SWORD_DANCE)),
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/tutor_learnsets.h")
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
            """,
            to: root.appendingPathComponent("include/constants/pokemon.h")
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
