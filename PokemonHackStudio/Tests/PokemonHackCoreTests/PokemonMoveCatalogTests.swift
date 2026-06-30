import XCTest
@testable import PokemonHackCore

final class PokemonMoveCatalogTests: XCTestCase {
    func testMoveCatalogBuildsReadOnlyMoveDetailsAndMemberships() throws {
        let root = try temporaryRoot()
        try write(
            """
            #define MOVE_NONE 0
            #define MOVE_TACKLE 1
            #define MOVE_TACKLE 2
            #define MOVE_DUPLICATE_VALUE 1

            """,
            to: root.appendingPathComponent("include/constants/moves.h")
        )
        try write(
            """
            static const u16 gTutorMoves[] = {
                MOVE_TACKLE,
            };

            static const u16 gTutorLearnsets[][2] =
            {
                [SPECIES_TREECKO] = { MOVE_TACKLE, MOVE_NONE },
            };

            """,
            to: root.appendingPathComponent("src/data/pokemon/tutor_learnsets.h")
        )

        let sourceIndex = ProjectSourceIndex(
            root: SourceLocation(path: root.path, exists: true),
            profile: .pokeemerald,
            adapterID: "test.moves",
            adapterName: "Move Fixture",
            records: [
                moveRecord("MOVE_NONE", ordinal: 0, line: 3),
                moveRecord(
                    "MOVE_TACKLE",
                    ordinal: 1,
                    line: 8,
                    facts: [
                        SourceIndexFact(label: "Index", value: "1"),
                        SourceIndexFact(label: "effect", value: "EFFECT_HIT"),
                        SourceIndexFact(label: "power", value: "40"),
                        SourceIndexFact(label: "type", value: "TYPE_NORMAL"),
                        SourceIndexFact(label: "accuracy", value: "100"),
                        SourceIndexFact(label: "pp", value: "35"),
                        SourceIndexFact(label: "secondaryEffectChance", value: "0"),
                        SourceIndexFact(label: "target", value: "MOVE_TARGET_SELECTED"),
                        SourceIndexFact(label: "priority", value: "0"),
                        SourceIndexFact(label: "flags", value: "FLAG_MAKES_CONTACT | FLAG_PROTECT_AFFECTED")
                    ]
                ),
                SourceIndexRecord(
                    id: "learnsets:treecko",
                    module: .learnsets,
                    title: "SPECIES_TREECKO",
                    subtitle: "src/data/pokemon/level_up_learnsets.h",
                    sourceSpan: SourceSpan(relativePath: "src/data/pokemon/level_up_learnsets.h", startLine: 12),
                    preview: "LEVEL_UP_MOVE(1, MOVE_TACKLE)\nLEVEL_UP_MOVE(4, MOVE_ABSENT)\nLEVEL_UP_MOVE(0, MOVE_NONE)"
                ),
                SourceIndexRecord(
                    id: "tmhm:treecko",
                    module: .learnsets,
                    title: "SPECIES_TREECKO",
                    subtitle: "src/data/pokemon/tmhm_learnsets.h",
                    sourceSpan: SourceSpan(relativePath: "src/data/pokemon/tmhm_learnsets.h", startLine: 20),
                    preview: "[SPECIES_TREECKO] = { MOVE_TACKLE }"
                )
            ]
        )
        let speciesCatalog = ProjectSpeciesCatalog(
            root: SourceLocation(path: root.path, exists: true),
            profile: .pokeemerald,
            adapterID: "test.moves",
            adapterName: "Move Fixture",
            species: [
                SpeciesDetail(
                    speciesID: "SPECIES_TREECKO",
                    displayName: "Treecko",
                    sourceSpan: SourceSpan(relativePath: "src/data/pokemon/species_info.h", startLine: 5),
                    baseStats: SpeciesBaseStats(),
                    learnsets: SpeciesLearnsets(
                        levelUp: [
                            SpeciesLevelUpMove(
                                level: 1,
                                move: "MOVE_TACKLE",
                                sourceSpan: SourceSpan(relativePath: "src/data/pokemon/level_up_learnsets.h", startLine: 12)
                            )
                        ],
                        tmhm: [
                            SpeciesMoveReference(
                                move: "MOVE_TACKLE",
                                sourceSpan: SourceSpan(relativePath: "src/data/pokemon/tmhm_learnsets.h", startLine: 20)
                            )
                        ]
                    )
                )
            ],
            constants: [
                .tmhmMoves: [
                    SpeciesConstant(
                        group: .tmhmMoves,
                        symbol: "MOVE_TACKLE",
                        value: "TM01_TACKLE",
                        sourceSpan: SourceSpan(relativePath: "include/constants/items.h", startLine: 2)
                    )
                ]
            ]
        )

        let catalog = try ProjectMoveCatalogBuilder.build(
            index: projectIndex(root: root),
            sourceIndex: sourceIndex,
            speciesCatalog: speciesCatalog
        )

        XCTAssertEqual(catalog.summary.moveCount, 1)
        let tackle = try XCTUnwrap(catalog.moves.first)
        XCTAssertEqual(tackle.moveID, "MOVE_TACKLE")
        XCTAssertEqual(tackle.displayName, "Tackle")
        XCTAssertEqual(tackle.ordinal, 1)
        XCTAssertEqual(tackle.facts.first { $0.label == "power" }?.value, "40")
        XCTAssertEqual(tackle.flags, ["FLAG_MAKES_CONTACT", "FLAG_PROTECT_AFFECTED"])
        XCTAssertEqual(tackle.machineMemberships.first?.token, "TM01_TACKLE")
        XCTAssertEqual(tackle.tutorMemberships.first?.eligibleSpeciesIDs, ["SPECIES_TREECKO"])
        XCTAssertTrue(tackle.learnedBy.contains { $0.bucket == .levelUp && $0.level == 1 })
        XCTAssertEqual(Set(tackle.learnedBy.map(\.speciesID)), ["SPECIES_TREECKO"])
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "MOVE_CATALOG_CONSTANT_DUPLICATE" })
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "MOVE_CATALOG_MOVE_UNRESOLVED" })
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "MOVE_CATALOG_SENTINEL_EXCLUDED" })

        let encoded = try JSONEncoder().encode(catalog)
        XCTAssertFalse(encoded.isEmpty)
    }

    func testMoveMutationPlannerPatchesTopLevelFieldsThenAppliesWithBackupAndReloads() throws {
        let root = try temporaryRoot()
        try makeBattleMovesProject(at: root)
        let catalog = try liveMoveCatalog(root: root)
        let tackle = try XCTUnwrap(catalog.moves.first { $0.moveID == "MOVE_TACKLE" })
        var draft = try XCTUnwrap(MoveEditDraft(detail: tackle))
        draft.power = 55
        draft.accuracy = 95
        draft.pp = 30
        draft.secondaryEffectChance = 10
        draft.target = "MOVE_TARGET_BOTH"
        draft.priority = 1
        draft.flags = ["FLAG_MAGIC_COAT_AFFECTED", "FLAG_PROTECT_AFFECTED"]

        let plan = MoveMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(plan.changes.map(\.path), ["src/data/battle_moves.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertTrue(plan.isApplyable, "\(plan.applyability.diagnostics)")
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains(".power = 55"))
        XCTAssertTrue(preview.contains(".accuracy = 95"))
        XCTAssertTrue(preview.contains(".flags = FLAG_MAGIC_COAT_AFFECTED | FLAG_PROTECT_AFFECTED"))
        XCTAssertTrue(preview.contains(".unknownField = KEEP_ME"))

        let result = try MoveMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))

        let editedText = try String(contentsOf: root.appendingPathComponent("src/data/battle_moves.h"), encoding: .utf8)
        XCTAssertTrue(editedText.contains(".power = 55"))
        XCTAssertTrue(editedText.contains(".unknownField = KEEP_ME"))
        XCTAssertTrue(editedText.contains("[MOVE_GROWL]"))

        let reloaded = try liveMoveCatalog(root: root)
        let edited = try XCTUnwrap(reloaded.moves.first { $0.moveID == "MOVE_TACKLE" })
        XCTAssertEqual(edited.facts.first { $0.label == "power" }?.value, "55")
        XCTAssertEqual(edited.flags, ["FLAG_MAGIC_COAT_AFFECTED", "FLAG_PROTECT_AFFECTED"])
        let reloadedDraft = try XCTUnwrap(MoveEditDraft(detail: edited))
        XCTAssertEqual(reloadedDraft.target, "MOVE_TARGET_BOTH")
        XCTAssertEqual(reloadedDraft.priority, 1)
    }

    func testRubySapphireMoveRowsPlanApplyBackupReloadAndKeepAdjacentScopesBlocked() throws {
        let root = try temporaryRoot()
        try makeRubyBattleMovesProject(at: root)
        let catalog = try liveMoveCatalog(root: root, profile: .pokeruby)
        let tackle = try XCTUnwrap(catalog.moves.first { $0.moveID == "MOVE_TACKLE" })

        XCTAssertEqual(tackle.sourceSpan.relativePath, "src/data/battle_moves.c")
        XCTAssertTrue(tackle.isEditable)
        XCTAssertTrue(tackle.isDescriptionEditable)
        XCTAssertEqual(tackle.descriptionSymbol, "gMoveDescription_Tackle")
        XCTAssertEqual(tackle.descriptionText, "A physical attack.")
        XCTAssertEqual(tackle.contestEffect, "CONTEST_EFFECT_NONE")
        XCTAssertTrue(tackle.isContestEffectEditable)
        XCTAssertEqual(tackle.facts.first { $0.label == "contestEffect" }?.value, "CONTEST_EFFECT_NONE")
        XCTAssertTrue(tackle.diagnostics.allSatisfy { $0.severity != .error })
        let encodedMove = try JSONSerialization.jsonObject(with: JSONEncoder().encode(tackle)) as? [String: Any]
        XCTAssertEqual(encodedMove?["contestEffect"] as? String, "CONTEST_EFFECT_NONE")
        XCTAssertEqual(encodedMove?["isContestEffectEditable"] as? Bool, true)

        var draft = try XCTUnwrap(MoveEditDraft(detail: tackle))
        draft.power = 55
        draft.accuracy = 95
        draft.pp = 30
        draft.secondaryEffectChance = 10
        draft.target = "MOVE_TARGET_BOTH"
        draft.priority = 1
        draft.flags = ["FLAG_MAGIC_COAT_AFFECTED", "FLAG_PROTECT_AFFECTED"]
        draft.descriptionText = "A clean tackle.\nIt lands fast."
        draft.contestEffect = "CONTEST_EFFECT_HIGHLY_APPEALING"

        let plan = MoveMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertTrue(plan.isApplyable, "\(plan.applyability.diagnostics)")
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/battle_moves.c"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains(".power = 55"))
        XCTAssertTrue(preview.contains(".accuracy = 95"))
        XCTAssertTrue(preview.contains(".flags = FLAG_MAGIC_COAT_AFFECTED | FLAG_PROTECT_AFFECTED"))
        XCTAssertTrue(preview.contains(".description = gMoveDescription_Tackle"))
        XCTAssertTrue(preview.contains(#""A clean tackle.""#))
        XCTAssertTrue(preview.contains(#""It lands fast.""#))
        XCTAssertTrue(preview.contains(".contestEffect = CONTEST_EFFECT_HIGHLY_APPEALING"))

        let applyabilityBeforeDrift = plan.validateApplyability()
        XCTAssertTrue(applyabilityBeforeDrift.isApplyable)
        try "changed\n".write(to: root.appendingPathComponent("src/data/battle_moves.c"), atomically: true, encoding: .utf8)
        let driftApplyability = plan.validateApplyability()
        XCTAssertFalse(driftApplyability.isApplyable)
        XCTAssertTrue(driftApplyability.diagnostics.contains { $0.code == "MOVE_APPLY_ORIGINAL_SIZE_MISMATCH" || $0.code == "MOVE_APPLY_ORIGINAL_HASH_MISMATCH" })

        try makeRubyBattleMovesProject(at: root)
        let freshCatalog = try liveMoveCatalog(root: root, profile: .pokeruby)
        let freshTackle = try XCTUnwrap(freshCatalog.moves.first { $0.moveID == "MOVE_TACKLE" })
        var freshDraft = try XCTUnwrap(MoveEditDraft(detail: freshTackle))
        freshDraft.power = 60
        freshDraft.descriptionText = "A sharper tackle."
        freshDraft.contestEffect = "CONTEST_EFFECT_USER_MORE_EASILY_STARTLED"
        let freshPlan = MoveMutationPlanner.plan(catalog: freshCatalog, draft: freshDraft)
        let result = try MoveMutationApplier.apply(plan: freshPlan)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/battle_moves.c"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))

        let reloaded = try liveMoveCatalog(root: root, profile: .pokeruby)
        let edited = try XCTUnwrap(reloaded.moves.first { $0.moveID == "MOVE_TACKLE" })
        XCTAssertEqual(MoveEditDraft(detail: edited)?.power, 60)
        XCTAssertEqual(edited.descriptionText, "A sharper tackle.")
        XCTAssertEqual(edited.contestEffect, "CONTEST_EFFECT_USER_MORE_EASILY_STARTLED")
        XCTAssertEqual(MoveEditDraft(detail: edited)?.contestEffect, "CONTEST_EFFECT_USER_MORE_EASILY_STARTLED")
        XCTAssertTrue(edited.sourcePreview?.contains(".description = gMoveDescription_Tackle") == true)
        XCTAssertTrue(edited.sourcePreview?.contains(".contestEffect = CONTEST_EFFECT_USER_MORE_EASILY_STARTLED") == true)

        let sentinelDraft = MoveEditDraft(
            moveID: "MOVE_NONE",
            effect: "EFFECT_NONE",
            power: 0,
            type: "TYPE_NORMAL",
            accuracy: 0,
            pp: 0,
            secondaryEffectChance: 0,
            target: "MOVE_TARGET_SELECTED",
            priority: 0,
            flags: []
        )
        let sentinelPlan = MoveMutationPlanner.plan(catalog: freshCatalog, draft: sentinelDraft)
        XCTAssertTrue(sentinelPlan.changes.isEmpty)
        XCTAssertTrue(sentinelPlan.diagnostics.contains { $0.code == "MOVE_PLAN_SENTINEL_UNSUPPORTED" })

        try makeRubyBattleMovesProject(at: root, omitPP: true)
        let missingCatalog = try liveMoveCatalog(root: root, profile: .pokeruby)
        let missingTackle = try XCTUnwrap(missingCatalog.moves.first { $0.moveID == "MOVE_TACKLE" })
        XCTAssertFalse(missingTackle.isEditable)
        XCTAssertTrue(missingTackle.diagnostics.contains { $0.code == "MOVE_CATALOG_EDIT_FIELDS_MISSING" })

        try makeRubyBattleMovesProject(at: root, flagsExpression: "FLAG_MAKES_CONTACT | MOVE_FLAG_ALIAS(FLAG_PROTECT_AFFECTED)")
        let nonSimpleCatalog = try liveMoveCatalog(root: root, profile: .pokeruby)
        let nonSimpleTackle = try XCTUnwrap(nonSimpleCatalog.moves.first { $0.moveID == "MOVE_TACKLE" })
        XCTAssertFalse(nonSimpleTackle.isEditable)
        XCTAssertTrue(nonSimpleTackle.diagnostics.contains { $0.code == "MOVE_CATALOG_FLAGS_UNSUPPORTED_EXPRESSION" })
        let nonSimpleDraft = try XCTUnwrap(MoveEditDraft(detail: nonSimpleTackle))
        let nonSimplePlan = MoveMutationPlanner.plan(catalog: nonSimpleCatalog, draft: nonSimpleDraft)
        XCTAssertTrue(nonSimplePlan.changes.isEmpty)
        XCTAssertTrue(nonSimplePlan.diagnostics.contains { $0.code == "MOVE_FLAGS_UNSUPPORTED_EXPRESSION" })

        try makeRubyBattleMovesProject(at: root, includeContestEffect: false)
        let missingContestCatalog = try liveMoveCatalog(root: root, profile: .pokeruby)
        let missingContestTackle = try XCTUnwrap(missingContestCatalog.moves.first { $0.moveID == "MOVE_TACKLE" })
        XCTAssertNil(missingContestTackle.contestEffect)
        XCTAssertFalse(missingContestTackle.isContestEffectEditable)
        var missingContestDraft = try XCTUnwrap(MoveEditDraft(detail: missingContestTackle))
        missingContestDraft.contestEffect = "CONTEST_EFFECT_NONE"
        let missingContestPlan = MoveMutationPlanner.plan(catalog: missingContestCatalog, draft: missingContestDraft)
        XCTAssertTrue(missingContestPlan.changes.isEmpty)
        XCTAssertTrue(missingContestPlan.diagnostics.contains { $0.code == "MOVE_CONTEST_EFFECT_NOT_EDITABLE" })

        try makeRubyBattleMovesProject(at: root, contestEffectExpression: "CONTEST_EFFECT_ALIAS(CONTEST_EFFECT_NONE)")
        let nonSimpleContestCatalog = try liveMoveCatalog(root: root, profile: .pokeruby)
        let nonSimpleContestTackle = try XCTUnwrap(nonSimpleContestCatalog.moves.first { $0.moveID == "MOVE_TACKLE" })
        XCTAssertNil(nonSimpleContestTackle.contestEffect)
        XCTAssertFalse(nonSimpleContestTackle.isContestEffectEditable)
        var nonSimpleContestDraft = try XCTUnwrap(MoveEditDraft(detail: nonSimpleContestTackle))
        nonSimpleContestDraft.contestEffect = "CONTEST_EFFECT_NONE"
        let nonSimpleContestPlan = MoveMutationPlanner.plan(catalog: nonSimpleContestCatalog, draft: nonSimpleContestDraft)
        XCTAssertTrue(nonSimpleContestPlan.changes.isEmpty)
        XCTAssertTrue(nonSimpleContestPlan.diagnostics.contains { $0.code == "MOVE_CONTEST_EFFECT_UNSUPPORTED_EXPRESSION" })

        let wrongSourceCatalog = ProjectMoveCatalog(
            root: catalog.root,
            profile: .pokeruby,
            adapterID: catalog.adapterID,
            adapterName: catalog.adapterName,
            summary: catalog.summary,
            moves: catalog.moves.map { move in
                guard move.moveID == "MOVE_TACKLE" else { return move }
                return MoveDetail(
                    moveID: move.moveID,
                    displayName: move.displayName,
                    ordinal: move.ordinal,
                    sourceSpan: SourceSpan(relativePath: "src/data/battle_moves.h", startLine: move.sourceSpan.startLine),
                    sourcePreview: move.sourcePreview,
                    facts: move.facts,
                    flags: move.flags,
                    descriptionSymbol: move.descriptionSymbol,
                    descriptionText: move.descriptionText,
                    isDescriptionEditable: move.isDescriptionEditable,
                    isEditable: true,
                    machineMemberships: move.machineMemberships,
                    tutorMemberships: move.tutorMemberships,
                    learnedBy: move.learnedBy,
                    diagnostics: []
                )
            }
        )
        let wrongSourcePlan = MoveMutationPlanner.plan(catalog: wrongSourceCatalog, draft: draft)
        XCTAssertTrue(wrongSourcePlan.changes.isEmpty)
        XCTAssertTrue(wrongSourcePlan.diagnostics.contains { $0.code == "MOVE_SOURCE_UNSUPPORTED" })

        var constantDraft = try XCTUnwrap(MoveEditDraft(detail: tackle))
        constantDraft.effect = "EFFECT_HIT + EFFECT_ALIAS"
        let constantPlan = MoveMutationPlanner.plan(catalog: catalog, draft: constantDraft)
        XCTAssertTrue(constantPlan.changes.isEmpty)
        XCTAssertTrue(constantPlan.diagnostics.contains { $0.code == "MOVE_SYMBOL_INVALID" })
    }

    func testRubySapphireMoveDescriptionTextBlocksMissingDeclaration() throws {
        let root = try temporaryRoot()
        try makeRubyBattleMovesProject(at: root, includeDescriptionDeclarations: false)
        let catalog = try liveMoveCatalog(root: root, profile: .pokeruby)
        let tackle = try XCTUnwrap(catalog.moves.first { $0.moveID == "MOVE_TACKLE" })

        XCTAssertEqual(tackle.descriptionSymbol, "gMoveDescription_Tackle")
        XCTAssertNil(tackle.descriptionText)
        XCTAssertFalse(tackle.isDescriptionEditable)

        var draft = try XCTUnwrap(MoveEditDraft(detail: tackle))
        draft.descriptionText = "This must stay blocked."
        let plan = MoveMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "MOVE_DESCRIPTION_NOT_EDITABLE" })
        XCTAssertFalse(plan.isApplyable)
    }

    func testMoveMutationPlannerRendersZeroFlagsAndBlocksNoOp() throws {
        let root = try temporaryRoot()
        try makeBattleMovesProject(at: root)
        let catalog = try liveMoveCatalog(root: root)
        let tackle = try XCTUnwrap(catalog.moves.first { $0.moveID == "MOVE_TACKLE" })
        let originalDraft = try XCTUnwrap(MoveEditDraft(detail: tackle))

        let noOp = MoveMutationPlanner.plan(catalog: catalog, draft: originalDraft)
        XCTAssertTrue(noOp.changes.isEmpty)
        XCTAssertFalse(noOp.isApplyable)
        XCTAssertTrue(noOp.diagnostics.contains { $0.code == "MOVE_PLAN_NO_CHANGES" })

        var draft = originalDraft
        draft.flags = []
        let flagPlan = MoveMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertEqual(flagPlan.changes.count, 1)
        XCTAssertTrue(flagPlan.changes.first?.textPreview?.contains(".flags = 0") == true)
    }

    func testMoveMutationPlannerBlocksChangedSourceHash() throws {
        let root = try temporaryRoot()
        try makeBattleMovesProject(at: root)
        let catalog = try liveMoveCatalog(root: root)
        let tackle = try XCTUnwrap(catalog.moves.first { $0.moveID == "MOVE_TACKLE" })
        var draft = try XCTUnwrap(MoveEditDraft(detail: tackle))
        draft.power = 60
        let plan = MoveMutationPlanner.plan(catalog: catalog, draft: draft)

        try "changed\n".write(to: root.appendingPathComponent("src/data/battle_moves.h"), atomically: true, encoding: .utf8)

        let applyability = plan.validateApplyability()
        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(applyability.diagnostics.contains { $0.code == "MOVE_APPLY_ORIGINAL_SIZE_MISMATCH" || $0.code == "MOVE_APPLY_ORIGINAL_HASH_MISMATCH" })
    }

    func testMoveMutationPlannerBlocksUnsupportedAndInvalidCases() throws {
        let root = try temporaryRoot()
        try makeBattleMovesProject(at: root)
        let catalog = try liveMoveCatalog(root: root)
        let tackle = try XCTUnwrap(catalog.moves.first { $0.moveID == "MOVE_TACKLE" })
        var draft = try XCTUnwrap(MoveEditDraft(detail: tackle))

        var invalidDraft = draft
        invalidDraft.power = -1
        invalidDraft.accuracy = 101
        invalidDraft.priority = 200
        let invalidPlan = MoveMutationPlanner.plan(catalog: catalog, draft: invalidDraft)
        XCTAssertTrue(invalidPlan.changes.isEmpty)
        XCTAssertTrue(invalidPlan.diagnostics.contains { $0.code == "MOVE_NUMERIC_RANGE_INVALID" })

        let sentinelDraft = MoveEditDraft(
            moveID: "MOVE_NONE",
            effect: "EFFECT_NONE",
            power: 0,
            type: "TYPE_NORMAL",
            accuracy: 0,
            pp: 0,
            secondaryEffectChance: 0,
            target: "MOVE_TARGET_SELECTED",
            priority: 0,
            flags: []
        )
        let sentinelPlan = MoveMutationPlanner.plan(catalog: catalog, draft: sentinelDraft)
        XCTAssertTrue(sentinelPlan.diagnostics.contains { $0.code == "MOVE_PLAN_SENTINEL_UNSUPPORTED" })

        let unsupportedCatalog = ProjectMoveCatalog(
            root: catalog.root,
            profile: .binaryROM,
            adapterID: catalog.adapterID,
            adapterName: catalog.adapterName,
            summary: catalog.summary,
            moves: catalog.moves
        )
        let unsupportedPlan = MoveMutationPlanner.plan(catalog: unsupportedCatalog, draft: draft)
        XCTAssertTrue(unsupportedPlan.diagnostics.contains { $0.code == "MOVE_PLAN_UNSUPPORTED_PROFILE" })

        let wrongSourceCatalog = ProjectMoveCatalog(
            root: catalog.root,
            profile: .pokeemeraldExpansion,
            adapterID: catalog.adapterID,
            adapterName: catalog.adapterName,
            summary: catalog.summary,
            moves: catalog.moves
        )
        let wrongSourcePlan = MoveMutationPlanner.plan(catalog: wrongSourceCatalog, draft: draft)
        XCTAssertTrue(wrongSourcePlan.diagnostics.contains { $0.code == "MOVE_SOURCE_UNSUPPORTED" })

        try makeBattleMovesProject(at: root, flagsExpression: "FLAG_MAKES_CONTACT | MOVE_FLAG_ALIAS(FLAG_PROTECT_AFFECTED)")
        let nonSimpleCatalog = try liveMoveCatalog(root: root)
        let nonSimpleTackle = try XCTUnwrap(nonSimpleCatalog.moves.first { $0.moveID == "MOVE_TACKLE" })
        draft = try XCTUnwrap(MoveEditDraft(detail: nonSimpleTackle))
        draft.power = 70
        let nonSimplePlan = MoveMutationPlanner.plan(catalog: nonSimpleCatalog, draft: draft)
        XCTAssertTrue(nonSimplePlan.changes.isEmpty)
        XCTAssertTrue(nonSimplePlan.diagnostics.contains { $0.code == "MOVE_FLAGS_UNSUPPORTED_EXPRESSION" })

        try FileManager.default.removeItem(at: root.appendingPathComponent("src/data/battle_moves.h"))
        let missingSourcePlan = MoveMutationPlanner.plan(catalog: catalog, draft: invalidSourceEditDraft(from: tackle))
        XCTAssertTrue(missingSourcePlan.changes.isEmpty)
        XCTAssertTrue(missingSourcePlan.diagnostics.contains { $0.code == "MOVE_SOURCE_MISSING" })
    }

    func testMoveCatalogReportsMissingMoveAndTutorTables() throws {
        let root = try temporaryRoot()
        let sourceIndex = ProjectSourceIndex(
            root: SourceLocation(path: root.path, exists: true),
            profile: .pokeemerald,
            adapterID: "test.moves",
            adapterName: "Move Fixture",
            records: []
        )

        let catalog = try ProjectMoveCatalogBuilder.build(
            index: projectIndex(root: root),
            sourceIndex: sourceIndex,
            speciesCatalog: nil
        )

        XCTAssertTrue(catalog.moves.isEmpty)
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "MOVE_CATALOG_MOVE_TABLE_MISSING" })
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "MOVE_CATALOG_TUTOR_TABLE_MISSING" })
    }

    func testExpansionMovesInfoRowsPlanApplyAndReloadThroughDescriptor() throws {
        let root = try temporaryRoot()
        try makeExpansionMovesInfoProject(at: root)
        let catalog = try liveMoveCatalog(root: root, profile: .pokeemeraldExpansion)

        XCTAssertEqual(catalog.summary.moveCount, 1)
        let pound = try XCTUnwrap(catalog.moves.first { $0.moveID == "MOVE_POUND" })
        XCTAssertEqual(pound.sourceSpan.relativePath, "src/data/moves_info.h")
        XCTAssertTrue(pound.isEditable)
        XCTAssertTrue(pound.isDescriptionEditable)
        XCTAssertEqual(pound.descriptionSymbol, "sPoundDescription")
        XCTAssertEqual(pound.descriptionText, "Pounds with forelegs.")
        XCTAssertTrue(pound.diagnostics.allSatisfy { $0.severity != .error })
        XCTAssertTrue(pound.sourcePreview?.contains(".description = sPoundDescription") == true)
        XCTAssertTrue(pound.sourcePreview?.contains(".contestCategory = CONTEST_CATEGORY_TOUGH") == true)
        XCTAssertNil(pound.contestEffect)
        XCTAssertFalse(pound.isContestEffectEditable)
        let contestMetadata = try XCTUnwrap(pound.contestMetadata)
        XCTAssertEqual(contestMetadata.contestCategory, "CONTEST_CATEGORY_TOUGH")
        XCTAssertEqual(contestMetadata.contestAppeal, "2")
        XCTAssertEqual(contestMetadata.contestJam, "1")
        XCTAssertEqual(contestMetadata.contestComboStarterId, "COMBO_STARTER_POUND")
        XCTAssertEqual(contestMetadata.contestComboMoves, "{ MOVE_DOUBLE_SLAP, MOVE_MEGA_PUNCH }")
        XCTAssertEqual(pound.facts.first { $0.label == "contestCategory" }?.value, "CONTEST_CATEGORY_TOUGH")
        XCTAssertEqual(pound.facts.first { $0.label == "contestAppeal" }?.value, "2")
        XCTAssertEqual(pound.facts.first { $0.label == "contestJam" }?.value, "1")
        XCTAssertEqual(pound.facts.first { $0.label == "contestComboStarterId" }?.value, "COMBO_STARTER_POUND")
        XCTAssertEqual(pound.facts.first { $0.label == "contestComboMoves" }?.value, "{ MOVE_DOUBLE_SLAP, MOVE_MEGA_PUNCH }")
        XCTAssertEqual(pound.facts.first { $0.label == "Contest Metadata Readiness" }?.value, "factsOnly")
        XCTAssertTrue((pound.facts.first { $0.label == "Contest Metadata Blocked Actions" }?.value ?? "").contains("contest writers"))
        let encodedMove = try JSONSerialization.jsonObject(with: JSONEncoder().encode(pound)) as? [String: Any]
        let encodedContestMetadata = try XCTUnwrap(encodedMove?["contestMetadata"] as? [String: Any])
        XCTAssertEqual(encodedContestMetadata["contestCategory"] as? String, "CONTEST_CATEGORY_TOUGH")
        XCTAssertEqual(encodedContestMetadata["contestAppeal"] as? String, "2")
        XCTAssertEqual(encodedContestMetadata["contestJam"] as? String, "1")
        XCTAssertEqual(encodedContestMetadata["contestComboStarterId"] as? String, "COMBO_STARTER_POUND")
        XCTAssertEqual(encodedContestMetadata["contestComboMoves"] as? String, "{ MOVE_DOUBLE_SLAP, MOVE_MEGA_PUNCH }")
        XCTAssertEqual(encodedMove?["isContestEffectEditable"] as? Bool, false)
        XCTAssertFalse(catalog.diagnostics.contains { $0.code == "MOVE_CATALOG_UNKNOWN_FIELD" && ($0.message.contains("description") || $0.message.contains("contestCategory")) })
        var draft = try XCTUnwrap(MoveEditDraft(detail: pound))
        draft.power = 55
        draft.pp = 30
        draft.flags = ["FLAG_MAKES_CONTACT", "FLAG_PROTECT_AFFECTED"]

        let plan = MoveMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertTrue(plan.isApplyable, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/moves_info.h"])
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains(".power = 55"))
        XCTAssertTrue(preview.contains(".pp = 30"))
        XCTAssertTrue(preview.contains(".flags = FLAG_MAKES_CONTACT | FLAG_PROTECT_AFFECTED"))
        XCTAssertTrue(preview.contains(".description = sPoundDescription"))
        XCTAssertTrue(preview.contains(".contestCategory = CONTEST_CATEGORY_TOUGH"))
        XCTAssertTrue(preview.contains(".contestAppeal = 2"))
        XCTAssertTrue(preview.contains(".contestJam = 1"))
        XCTAssertTrue(preview.contains(".contestComboStarterId = COMBO_STARTER_POUND"))
        XCTAssertTrue(preview.contains(".contestComboMoves = { MOVE_DOUBLE_SLAP, MOVE_MEGA_PUNCH }"))

        let applyabilityBeforeDrift = plan.validateApplyability()
        XCTAssertTrue(applyabilityBeforeDrift.isApplyable)
        try "changed\n".write(to: root.appendingPathComponent("src/data/moves_info.h"), atomically: true, encoding: .utf8)
        let driftApplyability = plan.validateApplyability()
        XCTAssertFalse(driftApplyability.isApplyable)
        XCTAssertTrue(driftApplyability.diagnostics.contains { $0.code == "MOVE_APPLY_ORIGINAL_SIZE_MISMATCH" || $0.code == "MOVE_APPLY_ORIGINAL_HASH_MISMATCH" })

        try makeExpansionMovesInfoProject(at: root)
        let hashCatalog = try liveMoveCatalog(root: root, profile: .pokeemeraldExpansion)
        let hashPound = try XCTUnwrap(hashCatalog.moves.first { $0.moveID == "MOVE_POUND" })
        var hashDraft = try XCTUnwrap(MoveEditDraft(detail: hashPound))
        hashDraft.power = 65
        let hashPlan = MoveMutationPlanner.plan(catalog: hashCatalog, draft: hashDraft)
        var sameSizeText = try String(contentsOf: root.appendingPathComponent("src/data/moves_info.h"), encoding: .utf8)
        sameSizeText = sameSizeText.replacingOccurrences(of: "TYPE_NORMAL", with: "TYPE_DRAGON")
        try sameSizeText.write(to: root.appendingPathComponent("src/data/moves_info.h"), atomically: true, encoding: .utf8)
        let hashApplyability = hashPlan.validateApplyability()
        XCTAssertFalse(hashApplyability.isApplyable)
        XCTAssertTrue(hashApplyability.diagnostics.contains { $0.code == "MOVE_APPLY_ORIGINAL_HASH_MISMATCH" })

        try makeExpansionMovesInfoProject(at: root)
        let freshCatalog = try liveMoveCatalog(root: root, profile: .pokeemeraldExpansion)
        let freshPound = try XCTUnwrap(freshCatalog.moves.first { $0.moveID == "MOVE_POUND" })
        var freshDraft = try XCTUnwrap(MoveEditDraft(detail: freshPound))
        freshDraft.power = 60
        let freshPlan = MoveMutationPlanner.plan(catalog: freshCatalog, draft: freshDraft)
        let result = try MoveMutationApplier.apply(plan: freshPlan)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/moves_info.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))
        let reloaded = try liveMoveCatalog(root: root, profile: .pokeemeraldExpansion)
        let edited = try XCTUnwrap(reloaded.moves.first { $0.moveID == "MOVE_POUND" })
        XCTAssertEqual(MoveEditDraft(detail: edited)?.power, 60)

        let sentinelDraft = MoveEditDraft(
            moveID: "MOVE_NONE",
            effect: "EFFECT_NONE",
            power: 0,
            type: "TYPE_NORMAL",
            accuracy: 0,
            pp: 0,
            secondaryEffectChance: 0,
            target: "MOVE_TARGET_SELECTED",
            priority: 0,
            flags: []
        )
        let sentinelPlan = MoveMutationPlanner.plan(catalog: catalog, draft: sentinelDraft)
        XCTAssertTrue(sentinelPlan.changes.isEmpty)
        XCTAssertTrue(sentinelPlan.diagnostics.contains { $0.code == "MOVE_PLAN_SENTINEL_UNSUPPORTED" })

        try makeExpansionMovesInfoProject(at: root, flagsExpression: "FLAG_MAKES_CONTACT | MOVE_FLAG_ALIAS(FLAG_PROTECT_AFFECTED)")
        let nonSimpleCatalog = try liveMoveCatalog(root: root, profile: .pokeemeraldExpansion)
        let nonSimplePound = try XCTUnwrap(nonSimpleCatalog.moves.first { $0.moveID == "MOVE_POUND" })
        XCTAssertFalse(nonSimplePound.isEditable)
        XCTAssertTrue(nonSimplePound.diagnostics.contains { $0.code == "MOVE_CATALOG_FLAGS_UNSUPPORTED_EXPRESSION" })
        let nonSimpleDraft = try XCTUnwrap(MoveEditDraft(detail: nonSimplePound))
        let nonSimplePlan = MoveMutationPlanner.plan(catalog: nonSimpleCatalog, draft: nonSimpleDraft)
        XCTAssertTrue(nonSimplePlan.changes.isEmpty)
        XCTAssertTrue(nonSimplePlan.diagnostics.contains { $0.code == "MOVE_FLAGS_UNSUPPORTED_EXPRESSION" })
    }

    func testExpansionMovesInfoRowsWithoutLegacyChanceAndFlagsStillEditExistingScalars() throws {
        let root = try temporaryRoot()
        try makeExpansionMovesInfoProjectWithoutLegacyFields(at: root)
        let catalog = try liveMoveCatalog(root: root, profile: .pokeemeraldExpansion)

        let pound = try XCTUnwrap(catalog.moves.first { $0.moveID == "MOVE_POUND" })
        XCTAssertTrue(pound.isEditable)
        XCTAssertTrue(pound.diagnostics.allSatisfy { $0.severity != .error })
        var draft = try XCTUnwrap(MoveEditDraft(detail: pound))
        XCTAssertEqual(draft.secondaryEffectChance, 0)
        XCTAssertEqual(draft.flags, [])
        draft.power = 55

        let plan = MoveMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertTrue(plan.isApplyable, plan.diagnostics.map(\.code).joined(separator: ","))
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains(".power = 55"))
        XCTAssertFalse(preview.contains("secondaryEffectChance"))
        XCTAssertFalse(preview.contains(".flags"))
    }

    func testExpansionMoveDescriptionTextPlansAppliesAndReloadsThroughDraft() throws {
        let root = try temporaryRoot()
        try makeExpansionMovesInfoProject(at: root)
        let catalog = try liveMoveCatalog(root: root, profile: .pokeemeraldExpansion)
        let pound = try XCTUnwrap(catalog.moves.first { $0.moveID == "MOVE_POUND" })
        var draft = try XCTUnwrap(MoveEditDraft(detail: pound))
        draft.descriptionText = "A clean jab.\nIt lands fast."

        let plan = MoveMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertTrue(plan.isApplyable, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/text/move_descriptions.h"])
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains("static const u8 sPoundDescription[] = _("))
        XCTAssertTrue(preview.contains(#""A clean jab.""#))
        XCTAssertTrue(preview.contains(#""It lands fast.""#))

        let result = try MoveMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/text/move_descriptions.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))
        let editedText = try String(contentsOf: root.appendingPathComponent("src/data/text/move_descriptions.h"), encoding: .utf8)
        XCTAssertTrue(editedText.contains("A clean jab."))
        XCTAssertTrue(editedText.contains("It lands fast."))

        let reloaded = try liveMoveCatalog(root: root, profile: .pokeemeraldExpansion)
        let edited = try XCTUnwrap(reloaded.moves.first { $0.moveID == "MOVE_POUND" })
        XCTAssertEqual(edited.descriptionText, "A clean jab.\nIt lands fast.")
        XCTAssertEqual(MoveEditDraft(detail: edited)?.descriptionText, "A clean jab.\nIt lands fast.")
    }

    func testExpansionMoveDescriptionTextBlocksMissingSourceDeclaration() throws {
        let root = try temporaryRoot()
        try makeExpansionMovesInfoProject(at: root)
        try FileManager.default.removeItem(at: root.appendingPathComponent("src/data/text/move_descriptions.h"))
        let catalog = try liveMoveCatalog(root: root, profile: .pokeemeraldExpansion)
        let pound = try XCTUnwrap(catalog.moves.first { $0.moveID == "MOVE_POUND" })
        XCTAssertFalse(pound.isDescriptionEditable)

        var draft = try XCTUnwrap(MoveEditDraft(detail: pound))
        draft.descriptionText = "This must stay blocked."
        let plan = MoveMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "MOVE_DESCRIPTION_NOT_EDITABLE" })
        XCTAssertFalse(plan.isApplyable)
    }

    private func temporaryRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonMoveCatalogTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: root)
        }
        return root
    }

    private func makeBattleMovesProject(at root: URL, flagsExpression: String = "FLAG_MAKES_CONTACT | FLAG_PROTECT_AFFECTED") throws {
        try write(
            """
            #define MOVE_NONE 0
            #define MOVE_TACKLE 1
            #define MOVE_GROWL 2

            """,
            to: root.appendingPathComponent("include/constants/moves.h")
        )
        try write(
            """
            const struct BattleMove gBattleMoves[] =
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
                    .flags = \(flagsExpression),
                    .unknownField = KEEP_ME,
                },
                [MOVE_GROWL] =
                {
                    .effect = EFFECT_ATTACK_DOWN,
                    .power = 0,
                    .type = TYPE_NORMAL,
                    .accuracy = 100,
                    .pp = 40,
                    .secondaryEffectChance = 0,
                    .target = MOVE_TARGET_BOTH,
                    .priority = 0,
                    .flags = FLAG_PROTECT_AFFECTED,
                },
            };

            """,
            to: root.appendingPathComponent("src/data/battle_moves.h")
        )
    }

    private func makeRubyBattleMovesProject(
        at root: URL,
        flagsExpression: String = "FLAG_MAKES_CONTACT | FLAG_PROTECT_AFFECTED",
        contestEffectExpression: String = "CONTEST_EFFECT_NONE",
        omitPP: Bool = false,
        includeDescriptionDeclarations: Bool = true,
        includeContestEffect: Bool = true
    ) throws {
        try write(
            """
            #define MOVE_NONE 0
            #define MOVE_TACKLE 1
            #define MOVE_GROWL 2

            """,
            to: root.appendingPathComponent("include/constants/moves.h")
        )
        let ppLine = omitPP ? "" : "        .pp = 35,\n"
        let contestEffectLine = includeContestEffect ? "        .contestEffect = \(contestEffectExpression),\n" : ""
        let descriptionDeclarations = includeDescriptionDeclarations
            ? """
            static const u8 gMoveDescription_None[] = _("No move.");
            const u8 gMoveDescription_Tackle[] = _("A physical attack.");

            """
            : ""
        try write(
            """
            \(descriptionDeclarations)\
            const struct BattleMove gBattleMoves[] =
            {
                [MOVE_NONE] =
                {
                    .effect = EFFECT_NONE,
                    .power = 0,
                    .type = TYPE_NORMAL,
                    .accuracy = 0,
            \(ppLine)        .secondaryEffectChance = 0,
                    .target = MOVE_TARGET_SELECTED,
                    .priority = 0,
                    .flags = 0,
                    .description = gMoveDescription_None,
            \(contestEffectLine)\
                },
                [MOVE_TACKLE] =
                {
                    .effect = EFFECT_HIT,
                    .power = 40,
                    .type = TYPE_NORMAL,
                    .accuracy = 100,
            \(ppLine)        .secondaryEffectChance = 0,
                    .target = MOVE_TARGET_SELECTED,
                    .priority = 0,
                    .flags = \(flagsExpression),
                    .description = gMoveDescription_Tackle,
            \(contestEffectLine)\
                },
            };

            """,
            to: root.appendingPathComponent("src/data/battle_moves.c")
        )
    }

    private func makeExpansionMovesInfoProject(at root: URL, flagsExpression: String = "FLAG_MAKES_CONTACT") throws {
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
                    .flags = \(flagsExpression),
                    .split = SPLIT_PHYSICAL,
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
        try writeExpansionMoveDescriptions(at: root)
    }

    private func makeExpansionMovesInfoProjectWithoutLegacyFields(at root: URL) throws {
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
                    .target = MOVE_TARGET_SELECTED,
                    .priority = 0,
                },
                [MOVE_POUND] =
                {
                    .effect = EFFECT_HIT,
                    .power = 40,
                    .type = TYPE_NORMAL,
                    .accuracy = 100,
                    .pp = 35,
                    .target = MOVE_TARGET_SELECTED,
                    .priority = 0,
                    .description = sPoundDescription,
                    .category = DAMAGE_CATEGORY_PHYSICAL,
                },
            };

            """,
            to: root.appendingPathComponent("src/data/moves_info.h")
        )
        try writeExpansionMoveDescriptions(at: root)
    }

    private func writeExpansionMoveDescriptions(at root: URL) throws {
        try write(
            """
            static const u8 sPoundDescription[] = _("Pounds with forelegs.");

            """,
            to: root.appendingPathComponent("src/data/text/move_descriptions.h")
        )
    }

    private func liveMoveCatalog(root: URL, profile: GameProfile = .pokeemerald) throws -> ProjectMoveCatalog {
        let index = projectIndex(root: root, profile: profile)
        let sourceIndex = try ProjectSourceIndexLoader.load(
            from: index,
            scriptOutline: ProjectScriptOutline(
                root: index.root,
                profile: index.profile,
                adapterID: index.adapterID,
                adapterName: index.adapterName,
                sources: [],
                labels: [],
                textBlocks: []
            )
        )
        return try ProjectMoveCatalogBuilder.build(
            index: index,
            sourceIndex: sourceIndex,
            speciesCatalog: emptySpeciesCatalog(root: root, profile: profile)
        )
    }

    private func emptySpeciesCatalog(root: URL, profile: GameProfile = .pokeemerald) -> ProjectSpeciesCatalog {
        ProjectSpeciesCatalog(
            root: SourceLocation(path: root.path, exists: true),
            profile: profile,
            adapterID: "test.moves",
            adapterName: "Move Fixture",
            species: []
        )
    }

    private func projectIndex(root: URL, profile: GameProfile = .pokeemerald) -> ProjectIndex {
        ProjectIndex(
            root: SourceLocation(path: root.path, exists: true),
            profile: profile,
            adapterID: "test.moves",
            adapterName: "Move Fixture",
            editorModules: [.pokemon, .moves],
            capabilities: [.diagnostics],
            writePolicy: .mutationPlanOnly,
            documents: []
        )
    }

    private func moveRecord(
        _ moveID: String,
        ordinal: Int,
        line: Int,
        facts: [SourceIndexFact]? = nil
    ) -> SourceIndexRecord {
        SourceIndexRecord(
            id: "moves:\(moveID)",
            module: .moves,
            title: moveID,
            subtitle: "src/data/battle_moves.h",
            sourceSpan: SourceSpan(relativePath: "src/data/battle_moves.h", startLine: line),
            facts: facts ?? [SourceIndexFact(label: "Index", value: "\(ordinal)")],
            preview: "[\(moveID)] = { .effect = EFFECT_HIT }"
        )
    }

    private func invalidSourceEditDraft(from detail: MoveDetail) -> MoveEditDraft {
        var draft = MoveEditDraft(detail: detail) ?? MoveEditDraft(
            moveID: detail.moveID,
            effect: "EFFECT_HIT",
            power: 40,
            type: "TYPE_NORMAL",
            accuracy: 100,
            pp: 35,
            secondaryEffectChance: 0,
            target: "MOVE_TARGET_SELECTED",
            priority: 0,
            flags: []
        )
        draft.power += 1
        return draft
    }

    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
}
