import XCTest
@testable import PokemonHackCore

final class TrainerCatalogTests: XCTestCase {
    func testEmeraldTrainerCatalogJoinsTrainerTableToAllClassicPartyShapes() throws {
        let temp = try TrainerCatalogTemporaryDirectory()
        try writeEmeraldFixture(at: temp.url)

        let catalog = try ProjectTrainerCatalogBuilder.build(path: temp.url.path)

        XCTAssertEqual(catalog.profile, .pokeemerald)
        XCTAssertEqual(catalog.trainers.count, 5)
        XCTAssertFalse(catalog.trainers.filter { $0.trainerID != "TRAINER_DUMMY" }.flatMap(\.diagnostics).contains { $0.severity == .error })

        let defaultTrainer = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_DEFAULT" })
        XCTAssertEqual(defaultTrainer.partyShape, .noItemDefaultMoves)
        XCTAssertEqual(defaultTrainer.party.first?.species, "SPECIES_TREECKO")
        XCTAssertNil(defaultTrainer.party.first?.heldItem)
        XCTAssertEqual(defaultTrainer.party.first?.moves, [])
        XCTAssertEqual(defaultTrainer.party.first?.defaultMoves, ["MOVE_POUND", "MOVE_ABSORB", "MOVE_NONE", "MOVE_NONE"])
        XCTAssertEqual(defaultTrainer.party.first?.ivs, .uniform(0))

        let itemDefaultTrainer = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_ITEM_DEFAULT" })
        XCTAssertEqual(itemDefaultTrainer.partyShape, .itemDefaultMoves)
        XCTAssertEqual(itemDefaultTrainer.party.first?.heldItem, "ITEM_POTION")

        let customTrainer = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_CUSTOM" })
        XCTAssertEqual(customTrainer.partyShape, .noItemCustomMoves)
        XCTAssertEqual(customTrainer.party.first?.moves, ["MOVE_POUND", "MOVE_ABSORB", "MOVE_NONE", "MOVE_NONE"])

        let itemCustomTrainer = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_ITEM_CUSTOM" })
        XCTAssertEqual(itemCustomTrainer.partyShape, .itemCustomMoves)
        XCTAssertEqual(itemCustomTrainer.trainerItems.first, "ITEM_SUPER_POTION")
        XCTAssertEqual(itemCustomTrainer.aiFlags, ["AI_SCRIPT_CHECK_BAD_MOVE", "AI_SCRIPT_TRY_TO_FAINT"])
        XCTAssertTrue(itemCustomTrainer.isEditable)
    }

    func testFireRedTrainerCatalogUsesClassicSources() throws {
        let temp = try TrainerCatalogTemporaryDirectory()
        try writeFireRedFixture(at: temp.url)

        let catalog = try ProjectTrainerCatalogBuilder.build(path: temp.url.path)

        XCTAssertEqual(catalog.profile, .pokefirered)
        let trainer = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_FIRE" })
        XCTAssertEqual(trainer.displayName, "FIRE (TRAINER_FIRE)")
        XCTAssertEqual(trainer.partyShape, .itemCustomMoves)
        XCTAssertEqual(trainer.party.first?.species, "SPECIES_CHARMANDER")
        XCTAssertEqual(trainer.party.first?.heldItem, "ITEM_ORAN_BERRY")
        XCTAssertEqual(trainer.party.first?.moves.first, "MOVE_EMBER")
        XCTAssertTrue(trainer.isEditable)
    }

    func testRubyTrainerCatalogLoadsUnionPartiesAndNumericAI() throws {
        let temp = try TrainerCatalogTemporaryDirectory()
        try writeRubyFixture(at: temp.url)

        let catalog = try ProjectTrainerCatalogBuilder.build(path: temp.url.path)

        XCTAssertEqual(catalog.profile, .pokeruby)
        XCTAssertEqual(catalog.trainers.count, 4)

        let archie = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_ARCHIE_1" })
        XCTAssertTrue(archie.isEditable)
        XCTAssertEqual(archie.aiFlags, [])
        XCTAssertEqual(archie.aiFlagsExpression, "0x7")
        XCTAssertEqual(archie.partyFlagsExpression, "0")
        XCTAssertEqual(archie.partySize, 1)
        XCTAssertEqual(archie.partyShape, .noItemDefaultMoves)
        XCTAssertEqual(archie.partySymbol, "gTrainerParty_Archie1")
        XCTAssertEqual(archie.party.first?.level, 17)
        XCTAssertEqual(archie.party.first?.species, "SPECIES_HUNTAIL")

        let cindy = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_CINDY_1" })
        XCTAssertTrue(cindy.isEditable)
        XCTAssertEqual(cindy.partyShape, .itemCustomMoves)
        XCTAssertEqual(cindy.party.first?.heldItem, "ITEM_NUGGET")
        XCTAssertEqual(cindy.party.first?.moves, ["MOVE_FURY_SWIPES", "MOVE_MUD_SPORT", "MOVE_ODOR_SLEUTH", "MOVE_SAND_ATTACK"])
        XCTAssertFalse(catalog.diagnostics.contains { $0.code == "TRAINER_CONSTANT_UNRESOLVED" && $0.severity == .error })
    }

    func testRubyTrainerMutationPlannerAppliesWithBackupReloadAndPartySizeUpdate() throws {
        let temp = try TrainerCatalogTemporaryDirectory()
        try writeRubyFixture(at: temp.url)
        let catalog = try ProjectTrainerCatalogBuilder.build(path: temp.url.path)
        let trainer = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_CINDY_1" })
        var draft = try XCTUnwrap(TrainerEditDraft(detail: trainer))
        draft.trainerName = "CINDY"
        draft.trainerItems = ["ITEM_HYPER_POTION", "ITEM_NONE", "ITEM_NONE", "ITEM_NONE"]
        draft.doubleBattle = true
        draft.party[0].species = "SPECIES_ZIGZAGOON"
        draft.party[0].level = 37
        draft.party[0].heldItem = "ITEM_ORAN_BERRY"
        draft.party[0].moves = ["MOVE_TACKLE", "MOVE_TAIL_WHIP", "MOVE_NONE", "MOVE_NONE"]
        draft.party.append(TrainerPartyPokemonDraft(
            slot: 1,
            species: "SPECIES_POOCHYENA",
            level: 12,
            iv: 10,
            ivs: .uniform(1),
            heldItem: "ITEM_NUGGET",
            moves: ["MOVE_BITE", "MOVE_NONE", "MOVE_NONE", "MOVE_NONE"]
        ))

        let plan = TrainerMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.map(\.path).sorted(), ["src/data/trainer_parties.h", "src/data/trainers_en.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(plan.isApplyable)
        let trainerPreview = plan.changes.first { $0.path == "src/data/trainers_en.h" }?.textPreview ?? ""
        XCTAssertTrue(trainerPreview.contains(".partySize = 2"))
        XCTAssertTrue(trainerPreview.contains(".party = {.ItemCustomMoves = gTrainerParty_Cindy1 }"))
        XCTAssertTrue(trainerPreview.contains(".aiFlags = 0x7"))
        let partyPreview = plan.changes.first { $0.path == "src/data/trainer_parties.h" }?.textPreview ?? ""
        XCTAssertTrue(partyPreview.contains("const struct TrainerMonItemCustomMoves gTrainerParty_Cindy1[]"))
        XCTAssertTrue(partyPreview.contains(".level = 37"))
        XCTAssertTrue(partyPreview.contains(".moves = MOVE_TACKLE, MOVE_TAIL_WHIP, MOVE_NONE, MOVE_NONE"))

        let result = try TrainerMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.count, 2)
        XCTAssertTrue(result.appliedChanges.allSatisfy { FileManager.default.fileExists(atPath: $0.backupPath) })

        let trainerText = try String(contentsOf: temp.url.appendingPathComponent("src/data/trainers_en.h"), encoding: .utf8)
        XCTAssertTrue(trainerText.contains(".partySize = 2"))
        XCTAssertTrue(trainerText.contains(".aiFlags = 0x7"))
        let reloaded = try ProjectTrainerCatalogBuilder.build(path: temp.url.path)
        let edited = try XCTUnwrap(reloaded.trainers.first { $0.trainerID == "TRAINER_CINDY_1" })
        XCTAssertEqual(edited.trainerName, "CINDY")
        XCTAssertEqual(edited.partySize, 2)
        XCTAssertEqual(edited.party.map(\.species), ["SPECIES_ZIGZAGOON", "SPECIES_POOCHYENA"])
        XCTAssertEqual(edited.party.first?.heldItem, "ITEM_ORAN_BERRY")
        XCTAssertEqual(edited.party.first.map { Array($0.moves.prefix(2)) }, ["MOVE_TACKLE", "MOVE_TAIL_WHIP"])
    }

    func testTrainerMutationPlannerUnsupportedProfileMessageIncludesRubySapphireSupport() throws {
        let catalog = ProjectTrainerCatalog(
            root: SourceLocation(path: "/tmp/unsupported", exists: false),
            profile: .unknown,
            adapterID: "test.unknown",
            adapterName: "Unknown",
            trainers: []
        )
        let draft = TrainerEditDraft(
            trainerID: "TRAINER_TEST",
            trainerName: "TEST",
            trainerClass: "TRAINER_CLASS_PKMN_TRAINER_1",
            encounterMusicGender: "TRAINER_ENCOUNTER_MUSIC_MALE",
            trainerPic: "TRAINER_PIC_HIKER",
            trainerItems: ["ITEM_NONE", "ITEM_NONE", "ITEM_NONE", "ITEM_NONE"],
            doubleBattle: false,
            aiFlags: [],
            partyShape: .noItemDefaultMoves,
            partySymbol: "sParty_Test",
            party: [
                TrainerPartyPokemonDraft(
                    slot: 0,
                    species: "SPECIES_TREECKO",
                    level: 5,
                    iv: 0
                )
            ]
        )

        let plan = TrainerMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertFalse(plan.isApplyable)
        let diagnostic = try XCTUnwrap(plan.diagnostics.first { $0.code == "TRAINER_PLAN_UNSUPPORTED_PROFILE" })
        XCTAssertTrue(diagnostic.message.contains("Ruby/Sapphire"))
        XCTAssertFalse(diagnostic.message.contains("only available for classic Emerald and FireRed"))
    }

    func testRubyTrainerPlannerPreservesNumericAIFlags() throws {
        let temp = try TrainerCatalogTemporaryDirectory()
        try writeRubyFixture(at: temp.url)
        let catalog = try ProjectTrainerCatalogBuilder.build(path: temp.url.path)
        let trainer = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_ARCHIE_1" })
        var draft = try XCTUnwrap(TrainerEditDraft(detail: trainer))
        draft.trainerName = "ARCHIE_EDIT"

        let plan = TrainerMutationPlanner.plan(catalog: catalog, draft: draft)
        let preview = plan.changes.first { $0.path == "src/data/trainers_en.h" }?.textPreview ?? ""

        XCTAssertTrue(plan.isApplyable)
        XCTAssertTrue(preview.contains(".aiFlags = 0x7"))
        XCTAssertFalse(preview.contains(".aiFlags = 0,"))
    }

    func testRubyTrainerApplyBlocksAfterSourceHashChanges() throws {
        let temp = try TrainerCatalogTemporaryDirectory()
        try writeRubyFixture(at: temp.url)
        let catalog = try ProjectTrainerCatalogBuilder.build(path: temp.url.path)
        let trainer = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_ARCHIE_1" })
        var draft = try XCTUnwrap(TrainerEditDraft(detail: trainer))
        draft.trainerName = "ARCHIE_EDIT"
        let plan = TrainerMutationPlanner.plan(catalog: catalog, draft: draft)

        try write(rubyTrainers.replacingOccurrences(of: #"ARCHIE"#, with: #"AQUA"#), to: temp.url.appendingPathComponent("src/data/trainers_en.h"))

        let applyability = plan.validateApplyability()

        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(applyability.diagnostics.contains { $0.code == "TRAINER_APPLY_ORIGINAL_SIZE_MISMATCH" || $0.code == "TRAINER_APPLY_ORIGINAL_HASH_MISMATCH" })
    }

    func testRubyTrainerPlannerBlocksUnsupportedAndMissingParties() throws {
        let temp = try TrainerCatalogTemporaryDirectory()
        try writeRubyFixture(at: temp.url)
        let catalog = try ProjectTrainerCatalogBuilder.build(path: temp.url.path)

        let unsupported = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_UNSUPPORTED" })
        XCTAssertFalse(unsupported.isEditable)
        XCTAssertTrue(unsupported.diagnostics.contains { $0.code == "TRAINER_PARTY_UNSUPPORTED" })
        XCTAssertNil(TrainerEditDraft(detail: unsupported))

        let missing = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_MISSING" })
        let draft = try XCTUnwrap(TrainerEditDraft(detail: missing))
        let plan = TrainerMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertFalse(missing.isEditable)
        XCTAssertTrue(missing.diagnostics.contains { $0.code == "TRAINER_PARTY_UNRESOLVED" })
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "TRAINER_NOT_EDITABLE" })
    }

    func testTrainerMutationPlannerRewritesOnlyTrainerAndPartyBlocksThenAppliesWithBackup() throws {
        let temp = try TrainerCatalogTemporaryDirectory()
        try writeEmeraldFixture(at: temp.url)
        let catalog = try ProjectTrainerCatalogBuilder.build(path: temp.url.path)
        let trainer = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_ITEM_CUSTOM" })
        var draft = try XCTUnwrap(TrainerEditDraft(detail: trainer))
        draft.trainerName = "EDITED"
        draft.trainerItems = ["ITEM_HYPER_POTION", "ITEM_NONE", "ITEM_NONE", "ITEM_NONE"]
        draft.doubleBattle = true
        draft.aiFlags = ["AI_SCRIPT_CHECK_BAD_MOVE", "AI_SCRIPT_CHECK_VIABILITY"]
        draft.party[0].species = "SPECIES_TORCHIC"
        draft.party[0].level = 33
        draft.party[0].ivs = .uniform(14)
        draft.party[0].heldItem = "ITEM_ORAN_BERRY"
        draft.party[0].moves = ["MOVE_EMBER", "MOVE_POUND", "MOVE_NONE", "MOVE_NONE"]

        let plan = TrainerMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.map(\.path).sorted(), ["src/data/trainer_parties.h", "src/data/trainers.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(plan.isApplyable)
        XCTAssertTrue(plan.changes.first { $0.path == "src/data/trainers.h" }?.textPreview?.contains(".trainerName = _(\"EDITED\")") == true)
        XCTAssertTrue(plan.changes.first { $0.path == "src/data/trainer_parties.h" }?.textPreview?.contains(".species = SPECIES_TORCHIC") == true)

        let result = try TrainerMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.count, 2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))

        let reloaded = try ProjectTrainerCatalogBuilder.build(path: temp.url.path)
        let edited = try XCTUnwrap(reloaded.trainers.first { $0.trainerID == "TRAINER_ITEM_CUSTOM" })
        XCTAssertEqual(edited.trainerName, "EDITED")
        XCTAssertEqual(edited.party.first?.species, "SPECIES_TORCHIC")
        XCTAssertEqual(edited.party.first?.level, 33)
        XCTAssertEqual(edited.party.first?.ivs, .uniform(14))
    }

    func testTrainerAssetReplacementRequiresExistingSourceFilesAndWarnsForSharedPics() throws {
        let temp = try TrainerCatalogTemporaryDirectory()
        try writeEmeraldFixture(at: temp.url)
        try writeTrainerGraphicsReferences(
            at: temp.url,
            frontReference: #"graphics/trainers/front_pics/hiker_front_pic.4bpp.lz"#,
            paletteReference: #"graphics/trainers/palettes/hiker.gbapal.lz"#
        )
        try write(Data("old-front".utf8), to: temp.url.appendingPathComponent("graphics/trainers/front_pics/hiker_front_pic.png"))
        try write(Data("old-palette".utf8), to: temp.url.appendingPathComponent("graphics/trainers/palettes/hiker.pal"))

        let catalog = try ProjectTrainerCatalogBuilder.build(path: temp.url.path)
        let trainer = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_DEFAULT" })
        let sources = TrainerAssetResolver.sources(catalog: catalog, trainer: trainer)

        XCTAssertEqual(sources.first { $0.kind == .frontSprite }?.relativePath, "graphics/trainers/front_pics/hiker_front_pic.png")
        XCTAssertEqual(sources.first { $0.kind == .palette }?.relativePath, "graphics/trainers/palettes/hiker.pal")
        XCTAssertEqual(sources.first { $0.kind == .frontSprite }?.sharedTrainerCount, 2)

        var draft = try XCTUnwrap(TrainerEditDraft(detail: trainer))
        let replacementPNG = testPNGData(width: 64, height: 64, paletteColorCount: 16)
        let replacementPalette = testJASCPalette(colorCount: 16)
        draft.assetData[.frontSprite] = replacementPNG
        draft.assetData[.palette] = replacementPalette
        draft.assetImports[.frontSprite] = SourceAssetImportValidator.provenance(
            sourcePath: temp.url.appendingPathComponent("incoming/hiker.png").path,
            expectedContent: .png,
            targetPath: "graphics/trainers/front_pics/hiker_front_pic.png",
            data: replacementPNG
        )
        draft.assetImports[.palette] = SourceAssetImportValidator.provenance(
            sourcePath: temp.url.appendingPathComponent("incoming/hiker.pal").path,
            expectedContent: .sourcePalette,
            targetPath: "graphics/trainers/palettes/hiker.pal",
            data: replacementPalette
        )

        let plan = TrainerMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertTrue(plan.diagnostics.contains { $0.code == "TRAINER_ASSET_SHARED_PIC" && $0.severity == .warning })
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(plan.isApplyable)
        XCTAssertTrue(plan.changes.contains { $0.path == "graphics/trainers/front_pics/hiker_front_pic.png" })
        XCTAssertTrue(plan.changes.contains { $0.path == "graphics/trainers/palettes/hiker.pal" })

        let result = try TrainerMutationApplier.apply(plan: plan)
        XCTAssertTrue(result.appliedChanges.contains { $0.path == "graphics/trainers/front_pics/hiker_front_pic.png" })
        XCTAssertEqual(try Data(contentsOf: temp.url.appendingPathComponent("graphics/trainers/front_pics/hiker_front_pic.png")), replacementPNG)
        XCTAssertEqual(try Data(contentsOf: temp.url.appendingPathComponent("graphics/trainers/palettes/hiker.pal")), replacementPalette)
    }

    func testTrainerPaletteReplacementBlocksGeneratedPNGPaletteReferences() throws {
        let temp = try TrainerCatalogTemporaryDirectory()
        try writeEmeraldFixture(at: temp.url)
        try writeTrainerGraphicsReferences(
            at: temp.url,
            frontReference: #"graphics/trainers/front_pics/hiker.png"#,
            paletteReference: #"graphics/trainers/front_pics/hiker.png"#
        )
        try write(testPNGData(width: 64, height: 64, paletteColorCount: 16), to: temp.url.appendingPathComponent("graphics/trainers/front_pics/hiker.png"))

        let catalog = try ProjectTrainerCatalogBuilder.build(path: temp.url.path)
        let trainer = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_DEFAULT" })
        var draft = try XCTUnwrap(TrainerEditDraft(detail: trainer))
        draft.assetData[.palette] = testJASCPalette(colorCount: 16)

        let plan = TrainerMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "TRAINER_ASSET_PALETTE_GENERATED_FROM_PNG" })
        XCTAssertFalse(plan.changes.contains { $0.path.hasSuffix(".pal") })
    }

    func testTrainerPaletteReplacementBlocksBinaryGBAPaletteBytesForSourceTargets() throws {
        let temp = try TrainerCatalogTemporaryDirectory()
        try writeEmeraldFixture(at: temp.url)
        try writeTrainerGraphicsReferences(
            at: temp.url,
            frontReference: #"graphics/trainers/front_pics/hiker_front_pic.4bpp.lz"#,
            paletteReference: #"graphics/trainers/palettes/hiker.gbapal.lz"#
        )
        try write(Data("old-front".utf8), to: temp.url.appendingPathComponent("graphics/trainers/front_pics/hiker_front_pic.png"))
        try write(Data("old-palette".utf8), to: temp.url.appendingPathComponent("graphics/trainers/palettes/hiker.pal"))

        let catalog = try ProjectTrainerCatalogBuilder.build(path: temp.url.path)
        let trainer = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_DEFAULT" })
        var draft = try XCTUnwrap(TrainerEditDraft(detail: trainer))
        let binaryPalette = Data(repeating: 0, count: 32)
        let provenance = SourceAssetImportValidator.provenance(
            sourcePath: temp.url.appendingPathComponent("incoming/hiker.gbapal").path,
            expectedContent: .sourcePalette,
            targetPath: "graphics/trainers/palettes/hiker.pal",
            data: binaryPalette
        )
        draft.assetData[.palette] = binaryPalette
        draft.assetImports[.palette] = provenance

        let plan = TrainerMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(provenance.status, .blocked)
        XCTAssertTrue(provenance.diagnostics.contains { $0.code == "ASSET_IMPORT_BINARY_PALETTE_BLOCKED" })
        XCTAssertFalse(plan.changes.contains { $0.path == "graphics/trainers/palettes/hiker.pal" })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "ASSET_IMPORT_BINARY_PALETTE_BLOCKED" })
        XCTAssertFalse(plan.isApplyable)
    }

    func testTrainerAssetReplacementBlocksApplyAfterSourceHashChanges() throws {
        let temp = try TrainerCatalogTemporaryDirectory()
        try writeEmeraldFixture(at: temp.url)
        try writeTrainerGraphicsReferences(
            at: temp.url,
            frontReference: #"graphics/trainers/front_pics/hiker_front_pic.4bpp.lz"#,
            paletteReference: #"graphics/trainers/palettes/hiker.gbapal.lz"#
        )
        try write(Data("old-front".utf8), to: temp.url.appendingPathComponent("graphics/trainers/front_pics/hiker_front_pic.png"))
        try write(Data("old-palette".utf8), to: temp.url.appendingPathComponent("graphics/trainers/palettes/hiker.pal"))

        let catalog = try ProjectTrainerCatalogBuilder.build(path: temp.url.path)
        let trainer = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_DEFAULT" })
        var draft = try XCTUnwrap(TrainerEditDraft(detail: trainer))
        draft.assetData[.frontSprite] = testPNGData(width: 64, height: 64, paletteColorCount: 16)
        let plan = TrainerMutationPlanner.plan(catalog: catalog, draft: draft)

        try write(Data("changed-front".utf8), to: temp.url.appendingPathComponent("graphics/trainers/front_pics/hiker_front_pic.png"))

        let applyability = plan.validateApplyability()

        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(applyability.diagnostics.contains { $0.code == "TRAINER_APPLY_ORIGINAL_SIZE_MISMATCH" || $0.code == "TRAINER_APPLY_ORIGINAL_HASH_MISMATCH" })
    }

    func testTrainerMutationPlannerHandlesPartyRemovalAndItemUpdates() throws {
        let temp = try TrainerCatalogTemporaryDirectory()
        try writeEmeraldFixture(at: temp.url)
        let catalog = try ProjectTrainerCatalogBuilder.build(path: temp.url.path)

        let trainer = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_ITEM_CUSTOM" })
        var draft = try XCTUnwrap(TrainerEditDraft(detail: trainer))

        draft.party.append(TrainerPartyPokemonDraft(
            slot: 1,
            species: "SPECIES_MUDKIP",
            level: 10,
            iv: 0,
            ivs: .uniform(0),
            nature: "NATURE_HARDY",
            heldItem: "ITEM_NONE",
            moves: ["MOVE_NONE", "MOVE_NONE", "MOVE_NONE", "MOVE_NONE"],
            defaultMoves: ["MOVE_POUND", "MOVE_NONE", "MOVE_NONE", "MOVE_NONE"]
        ))

        let planWithTwo = TrainerMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertTrue(planWithTwo.isApplyable)
        XCTAssertTrue(planWithTwo.changes.first { $0.path == "src/data/trainer_parties.h" }?.textPreview?.contains(".species = SPECIES_MUDKIP") == true)

        draft.party.remove(at: 0)
        draft.party[0].slot = 0

        let planWithOneRemoved = TrainerMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertTrue(planWithOneRemoved.isApplyable)
        let partyPreview = planWithOneRemoved.changes.first { $0.path == "src/data/trainer_parties.h" }?.textPreview ?? ""
        XCTAssertFalse(partyPreview.contains("SPECIES_TREECKO"))
        XCTAssertTrue(partyPreview.contains("SPECIES_MUDKIP"))

        _ = try TrainerMutationApplier.apply(plan: planWithOneRemoved)
        let reloaded = try ProjectTrainerCatalogBuilder.build(path: temp.url.path)
        let edited = try XCTUnwrap(reloaded.trainers.first { $0.trainerID == "TRAINER_ITEM_CUSTOM" })
        XCTAssertEqual(edited.party.map(\.species), ["SPECIES_MUDKIP"])
    }

    func testTrainerDraftUsesDefaultMovesAsCustomMoveStartingPoint() throws {
        let temp = try TrainerCatalogTemporaryDirectory()
        try writeEmeraldFixture(at: temp.url)
        let catalog = try ProjectTrainerCatalogBuilder.build(path: temp.url.path)
        let trainer = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_DEFAULT" })

        let draft = try XCTUnwrap(TrainerEditDraft(detail: trainer))

        XCTAssertEqual(draft.party.first?.defaultMoves, ["MOVE_POUND", "MOVE_ABSORB", "MOVE_NONE", "MOVE_NONE"])
        XCTAssertEqual(draft.party.first?.moves, ["MOVE_POUND", "MOVE_ABSORB", "MOVE_NONE", "MOVE_NONE"])
    }

    func testTrainerPlannerBlocksPerStatIVsAndUnsupportedNatureForClassicParties() throws {
        let temp = try TrainerCatalogTemporaryDirectory()
        try writeEmeraldFixture(at: temp.url)
        let catalog = try ProjectTrainerCatalogBuilder.build(path: temp.url.path)
        let trainer = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_DEFAULT" })
        var draft = try XCTUnwrap(TrainerEditDraft(detail: trainer))
        draft.party[0].ivs = TrainerPokemonIVs(hp: 31, attack: 30, defense: 31, speed: 31, spAttack: 31, spDefense: 31)
        draft.party[0].nature = "NATURE_ADAMANT"

        let plan = TrainerMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "TRAINER_PARTY_INDIVIDUAL_IVS_UNSUPPORTED" })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "TRAINER_PARTY_NATURE_UNSUPPORTED" })
    }

    func testTrainerMutationPlannerBlocksUnsupportedPartyMembers() throws {
        let temp = try TrainerCatalogTemporaryDirectory()
        try writeEmeraldFixture(at: temp.url)
        let catalog = try ProjectTrainerCatalogBuilder.build(path: temp.url.path)
        let trainer = try XCTUnwrap(catalog.trainers.first { $0.trainerID == "TRAINER_DUMMY" })
        let draft = try XCTUnwrap(TrainerEditDraft(detail: trainer))

        let plan = TrainerMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertFalse(trainer.isEditable)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "TRAINER_NOT_EDITABLE" })
    }

    private func writeEmeraldFixture(at root: URL) throws {
        try writeProjectSkeleton(at: root, makefile: "POKEMON EMER\n")
        try writeConstants(at: root)
        try write(emeraldTrainers, to: root.appendingPathComponent("src/data/trainers.h"))
        try write(classicTrainerParties, to: root.appendingPathComponent("src/data/trainer_parties.h"))
    }

    private func writeFireRedFixture(at root: URL) throws {
        try writeProjectSkeleton(at: root, makefile: "poke$(BUILD_NAME).gba\n")
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/quest_log"), withIntermediateDirectories: true)
        try writeConstants(at: root)
        try write(
            """
            const struct Trainer gTrainers[] = {
                [TRAINER_FIRE] = {
                    .trainerClass = TRAINER_CLASS_RIVAL,
                    .encounterMusic_gender = TRAINER_ENCOUNTER_MUSIC_MALE,
                    .trainerPic = TRAINER_PIC_RIVAL,
                    .trainerName = _("FIRE"),
                    .items = {},
                    .doubleBattle = FALSE,
                    .aiFlags = AI_SCRIPT_CHECK_BAD_MOVE,
                    .party = ITEM_CUSTOM_MOVES(sParty_Fire),
                },
            };
            """,
            to: root.appendingPathComponent("src/data/trainers.h")
        )
        try write(
            """
            static const struct TrainerMonItemCustomMoves sParty_Fire[] = {
                {
                    .iv = 50,
                    .lvl = 18,
                    .species = SPECIES_CHARMANDER,
                    .heldItem = ITEM_ORAN_BERRY,
                    .moves = { MOVE_EMBER, MOVE_POUND, MOVE_NONE, MOVE_NONE },
                },
            };
            """,
            to: root.appendingPathComponent("src/data/trainer_parties.h")
        )
    }

    private func writeRubyFixture(at root: URL) throws {
        try writeProjectSkeleton(at: root, makefile: "GAME_VERSION=RUBY\npokeruby.gba\n")
        try writeRubyConstants(at: root)
        try write(rubyTrainers, to: root.appendingPathComponent("src/data/trainers_en.h"))
        try write(rubyTrainerParties, to: root.appendingPathComponent("src/data/trainer_parties.h"))
    }

    private func writeRubyConstants(at root: URL) throws {
        try write(
            """
            #define SPECIES_NONE 0
            #define SPECIES_HUNTAIL 1
            #define SPECIES_SHARPEDO 2
            #define SPECIES_LINOONE 3
            #define SPECIES_ZIGZAGOON 4
            #define SPECIES_POOCHYENA 5
            """,
            to: root.appendingPathComponent("include/constants/species.h")
        )
        try write(
            """
            #define MOVE_NONE 0
            #define MOVE_FURY_SWIPES 1
            #define MOVE_MUD_SPORT 2
            #define MOVE_ODOR_SLEUTH 3
            #define MOVE_SAND_ATTACK 4
            #define MOVE_TACKLE 5
            #define MOVE_TAIL_WHIP 6
            #define MOVE_BITE 7
            """,
            to: root.appendingPathComponent("include/constants/moves.h")
        )
        try write(
            """
            #define ITEM_NONE 0
            #define ITEM_NUGGET 1
            #define ITEM_SUPER_POTION 2
            #define ITEM_HYPER_POTION 3
            #define ITEM_ORAN_BERRY 4
            """,
            to: root.appendingPathComponent("include/constants/items.h")
        )
        try write(
            """
            #define TRAINER_ENCOUNTER_MUSIC_MALE 0
            #define TRAINER_ENCOUNTER_MUSIC_AQUA 1
            #define F_TRAINER_PARTY_CUSTOM_MOVESET 1 << 0
            #define F_TRAINER_PARTY_HELD_ITEM 1 << 1

            enum {
                TRAINER_PIC_BRENDAN,
                TRAINER_PIC_ARCHIE,
                TRAINER_PIC_HIKER,
            };

            enum {
                TRAINER_CLASS_POKEMON_TRAINER_1,
                TRAINER_CLASS_AQUA_LEADER,
                TRAINER_CLASS_LADY,
            };
            """,
            to: root.appendingPathComponent("include/constants/trainers.h")
        )
        try write(
            """
            #define NATURE_HARDY 0
            """,
            to: root.appendingPathComponent("include/constants/pokemon.h")
        )
    }

    private func writeTrainerGraphicsReferences(at root: URL, frontReference: String, paletteReference: String) throws {
        try write(
            """
            const u32 gTrainerFrontPic_Hiker[] = INCBIN_U32("\(frontReference)");
            const u32 gTrainerPalette_Hiker[] = INCGFX_U32("\(paletteReference)", ".gbapal.lz");
            """,
            to: root.appendingPathComponent("src/data/graphics/trainers.h")
        )
    }

    private func writeProjectSkeleton(at root: URL, makefile: String) throws {
        try write(makefile, to: root.appendingPathComponent("Makefile"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics"), withIntermediateDirectories: true)
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try write("const struct SpeciesInfo gSpeciesInfo[] = { [SPECIES_TREECKO] = { .baseHP = 40 }, };\n", to: root.appendingPathComponent("src/data/pokemon/species_info.h"))
        try write("const struct Item gItems[] = { [ITEM_POTION] = { .name = _(\"POTION\"), .itemId = ITEM_POTION }, };\n", to: root.appendingPathComponent("src/data/items.h"))
        try writeLevelUpLearnsets(at: root)
    }

    private func writeConstants(at root: URL) throws {
        try write(
            """
            #define SPECIES_NONE 0
            #define SPECIES_TREECKO 1
            #define SPECIES_TORCHIC 2
            #define SPECIES_MUDKIP 3
            #define SPECIES_CHARMANDER 4
            """,
            to: root.appendingPathComponent("include/constants/species.h")
        )
        try write(
            """
            #define MOVE_NONE 0
            #define MOVE_POUND 1
            #define MOVE_ABSORB 2
            #define MOVE_EMBER 3
            """,
            to: root.appendingPathComponent("include/constants/moves.h")
        )
        try write(
            """
            #define ITEM_NONE 0
            #define ITEM_POTION 1
            #define ITEM_SUPER_POTION 2
            #define ITEM_HYPER_POTION 3
            #define ITEM_ORAN_BERRY 4
            """,
            to: root.appendingPathComponent("include/constants/items.h")
        )
        try write(
            """
            #define TRAINER_CLASS_PKMN_TRAINER_1 1
            #define TRAINER_CLASS_RIVAL 2
            #define TRAINER_PIC_HIKER 1
            #define TRAINER_PIC_RIVAL 2
            #define TRAINER_ENCOUNTER_MUSIC_MALE 1
            #define TRAINER_ENCOUNTER_MUSIC_FEMALE 2
            #define F_TRAINER_FEMALE (1 << 7)
            """,
            to: root.appendingPathComponent("include/constants/trainers.h")
        )
        try write(
            """
            #define AI_SCRIPT_CHECK_BAD_MOVE (1 << 0)
            #define AI_SCRIPT_TRY_TO_FAINT (1 << 1)
            #define AI_SCRIPT_CHECK_VIABILITY (1 << 2)
            """,
            to: root.appendingPathComponent("include/constants/battle_ai.h")
        )
        try write(
            """
            #define NATURE_HARDY 0
            #define NATURE_ADAMANT 1
            #define TYPE_NORMAL 0
            """,
            to: root.appendingPathComponent("include/constants/pokemon.h")
        )
    }

    private func writeLevelUpLearnsets(at root: URL) throws {
        try write(
            """
            const u16 *const gLevelUpLearnsets[NUM_SPECIES] =
            {
                [SPECIES_TREECKO] = sTreeckoLevelUpLearnset,
                [SPECIES_TORCHIC] = sTorchicLevelUpLearnset,
                [SPECIES_MUDKIP] = sMudkipLevelUpLearnset,
                [SPECIES_CHARMANDER] = sCharmanderLevelUpLearnset,
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/level_up_learnset_pointers.h")
        )
        try write(
            """
            #define LEVEL_UP_MOVE(lvl, move) ((lvl << 9) | move)

            static const u16 sTreeckoLevelUpLearnset[] = {
                LEVEL_UP_MOVE(1, MOVE_POUND),
                LEVEL_UP_MOVE(5, MOVE_ABSORB),
                LEVEL_UP_END
            };

            static const u16 sTorchicLevelUpLearnset[] = {
                LEVEL_UP_MOVE(1, MOVE_POUND),
                LEVEL_UP_MOVE(10, MOVE_EMBER),
                LEVEL_UP_END
            };

            static const u16 sMudkipLevelUpLearnset[] = {
                LEVEL_UP_MOVE(1, MOVE_POUND),
                LEVEL_UP_END
            };

            static const u16 sCharmanderLevelUpLearnset[] = {
                LEVEL_UP_MOVE(1, MOVE_POUND),
                LEVEL_UP_MOVE(7, MOVE_EMBER),
                LEVEL_UP_END
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/level_up_learnsets.h")
        )
    }

    private var emeraldTrainers: String {
        """
        const struct Trainer gTrainers[] = {
            [TRAINER_DEFAULT] =
            {
                .trainerClass = TRAINER_CLASS_PKMN_TRAINER_1,
                .encounterMusic_gender = TRAINER_ENCOUNTER_MUSIC_MALE,
                .trainerPic = TRAINER_PIC_HIKER,
                .trainerName = _("DEFAULT"),
                .items = {},
                .doubleBattle = FALSE,
                .aiFlags = AI_SCRIPT_CHECK_BAD_MOVE,
                .party = NO_ITEM_DEFAULT_MOVES(sParty_Default),
            },
            [TRAINER_CUSTOM] =
            {
                .trainerClass = TRAINER_CLASS_PKMN_TRAINER_1,
                .encounterMusic_gender = F_TRAINER_FEMALE | TRAINER_ENCOUNTER_MUSIC_FEMALE,
                .trainerPic = TRAINER_PIC_HIKER,
                .trainerName = _("CUSTOM"),
                .items = {},
                .doubleBattle = FALSE,
                .aiFlags = AI_SCRIPT_CHECK_BAD_MOVE,
                .party = NO_ITEM_CUSTOM_MOVES(sParty_Custom),
            },
            [TRAINER_ITEM_DEFAULT] =
            {
                .trainerClass = TRAINER_CLASS_RIVAL,
                .encounterMusic_gender = TRAINER_ENCOUNTER_MUSIC_MALE,
                .trainerPic = TRAINER_PIC_RIVAL,
                .trainerName = _("ITEM"),
                .items = {},
                .doubleBattle = FALSE,
                .aiFlags = AI_SCRIPT_CHECK_BAD_MOVE,
                .party = ITEM_DEFAULT_MOVES(sParty_ItemDefault),
            },
            [TRAINER_ITEM_CUSTOM] =
            {
                .trainerClass = TRAINER_CLASS_RIVAL,
                .encounterMusic_gender = TRAINER_ENCOUNTER_MUSIC_MALE,
                .trainerPic = TRAINER_PIC_RIVAL,
                .trainerName = _("BOSS"),
                .items = {ITEM_SUPER_POTION, ITEM_NONE, ITEM_NONE, ITEM_NONE},
                .doubleBattle = FALSE,
                .aiFlags = AI_SCRIPT_CHECK_BAD_MOVE | AI_SCRIPT_TRY_TO_FAINT,
                .party = ITEM_CUSTOM_MOVES(sParty_ItemCustom),
            },
            [TRAINER_DUMMY] =
            {
                .trainerClass = TRAINER_CLASS_RIVAL,
                .encounterMusic_gender = TRAINER_ENCOUNTER_MUSIC_MALE,
                .trainerPic = TRAINER_PIC_RIVAL,
                .trainerName = _("DUMMY"),
                .items = {},
                .doubleBattle = FALSE,
                .aiFlags = AI_SCRIPT_CHECK_BAD_MOVE,
                .party = NO_ITEM_DEFAULT_MOVES(sParty_Dummy),
            },
        };
        """
    }

    private var rubyTrainers: String {
        """
        const struct Trainer gTrainers[] = {
            [TRAINER_ARCHIE_1] =
            {
                .partyFlags = 0,
                .trainerClass = TRAINER_CLASS_AQUA_LEADER,
                .encounterMusic_gender = TRAINER_ENCOUNTER_MUSIC_AQUA,
                .trainerPic = TRAINER_PIC_ARCHIE,
                .trainerName = _("ARCHIE"),
                .items = {ITEM_SUPER_POTION, ITEM_SUPER_POTION, ITEM_NONE, ITEM_NONE},
                .doubleBattle = FALSE,
                .aiFlags = 0x7,
                .partySize = 1,
                .party = {.NoItemDefaultMoves = gTrainerParty_Archie1 }
            },

            [TRAINER_CINDY_1] =
            {
                .partyFlags = F_TRAINER_PARTY_HELD_ITEM | F_TRAINER_PARTY_CUSTOM_MOVESET,
                .trainerClass = TRAINER_CLASS_LADY,
                .encounterMusic_gender = TRAINER_ENCOUNTER_MUSIC_MALE,
                .trainerPic = TRAINER_PIC_HIKER,
                .trainerName = _("CINDY1"),
                .items = {ITEM_NONE, ITEM_NONE, ITEM_NONE, ITEM_NONE},
                .doubleBattle = FALSE,
                .aiFlags = 0x7,
                .partySize = 1,
                .party = {.ItemCustomMoves = gTrainerParty_Cindy1 }
            },

            [TRAINER_UNSUPPORTED] =
            {
                .partyFlags = 0,
                .trainerClass = TRAINER_CLASS_POKEMON_TRAINER_1,
                .encounterMusic_gender = TRAINER_ENCOUNTER_MUSIC_MALE,
                .trainerPic = TRAINER_PIC_BRENDAN,
                .trainerName = _("BAD"),
                .items = {ITEM_NONE, ITEM_NONE, ITEM_NONE, ITEM_NONE},
                .doubleBattle = FALSE,
                .aiFlags = 0x0,
                .partySize = 1,
                .party = {.UnsupportedMoves = gTrainerParty_Archie1 }
            },

            [TRAINER_MISSING] =
            {
                .partyFlags = 0,
                .trainerClass = TRAINER_CLASS_POKEMON_TRAINER_1,
                .encounterMusic_gender = TRAINER_ENCOUNTER_MUSIC_MALE,
                .trainerPic = TRAINER_PIC_BRENDAN,
                .trainerName = _("MISS"),
                .items = {ITEM_NONE, ITEM_NONE, ITEM_NONE, ITEM_NONE},
                .doubleBattle = FALSE,
                .aiFlags = 0x0,
                .partySize = 1,
                .party = {.NoItemDefaultMoves = gTrainerParty_Missing }
            },
        };
        """
    }

    private var classicTrainerParties: String {
        """
        #define DUMMY_TRAINER_MON {0}

        static const struct TrainerMonNoItemDefaultMoves sParty_Default[] = {
            {
                .iv = 0,
                .lvl = 5,
                .species = SPECIES_TREECKO,
            },
        };

        static const struct TrainerMonNoItemCustomMoves sParty_Custom[] = {
            {
                .iv = 10,
                .lvl = 12,
                .species = SPECIES_TORCHIC,
                .moves = { MOVE_POUND, MOVE_ABSORB, MOVE_NONE, MOVE_NONE },
            },
        };

        static const struct TrainerMonItemDefaultMoves sParty_ItemDefault[] = {
            {
                .iv = 20,
                .lvl = 18,
                .species = SPECIES_MUDKIP,
                .heldItem = ITEM_POTION,
            },
        };

        static const struct TrainerMonItemCustomMoves sParty_ItemCustom[] = {
            {
                .iv = 100,
                .lvl = 30,
                .species = SPECIES_TREECKO,
                .heldItem = ITEM_POTION,
                .moves = { MOVE_POUND, MOVE_ABSORB, MOVE_NONE, MOVE_NONE },
            },
        };

        static const struct TrainerMonNoItemDefaultMoves sParty_Dummy[] = {DUMMY_TRAINER_MON};
        """
    }

    private var rubyTrainerParties: String {
        """
        const struct TrainerMonNoItemDefaultMoves gTrainerParty_Archie1[] = {
            {
                .iv = 0,
                .level = 17,
                .species = SPECIES_HUNTAIL
            }
        };

        const struct TrainerMonItemCustomMoves gTrainerParty_Cindy1[] = {
            {
                .iv = 40,
                .level = 36,
                .species = SPECIES_LINOONE,
                .heldItem = ITEM_NUGGET,
                .moves = MOVE_FURY_SWIPES, MOVE_MUD_SPORT, MOVE_ODOR_SLEUTH, MOVE_SAND_ATTACK
            }
        };
        """
    }

    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func write(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }

    private func testPNGData(width: UInt32, height: UInt32, paletteColorCount: Int? = nil) -> Data {
        var data = Data([137, 80, 78, 71, 13, 10, 26, 10])
        var ihdr = Data()
        ihdr.appendTrainerTestUInt32BE(width)
        ihdr.appendTrainerTestUInt32BE(height)
        ihdr.append(contentsOf: [8, 3, 0, 0, 0])
        data.appendTrainerTestPNGChunk(type: "IHDR", payload: ihdr)
        if let paletteColorCount {
            data.appendTrainerTestPNGChunk(type: "PLTE", payload: Data(repeating: 0, count: paletteColorCount * 3))
        }
        data.appendTrainerTestPNGChunk(type: "IEND", payload: Data())
        return data
    }

    private func testJASCPalette(colorCount: Int) -> Data {
        let colors = (0..<colorCount).map { index -> String in
            let channel = (index * 8) % 256
            return "\(channel) \(channel) \(channel)"
        }
        return Data(("JASC-PAL\n0100\n\(colorCount)\n" + colors.joined(separator: "\n") + "\n").utf8)
    }
}

private extension Data {
    mutating func appendTrainerTestUInt32BE(_ value: UInt32) {
        append(UInt8((value >> 24) & 0xff))
        append(UInt8((value >> 16) & 0xff))
        append(UInt8((value >> 8) & 0xff))
        append(UInt8(value & 0xff))
    }

    mutating func appendTrainerTestPNGChunk(type: String, payload: Data) {
        appendTrainerTestUInt32BE(UInt32(payload.count))
        append(contentsOf: type.utf8)
        append(payload)
        appendTrainerTestUInt32BE(0)
    }
}

private final class TrainerCatalogTemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackTrainerCatalogTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
