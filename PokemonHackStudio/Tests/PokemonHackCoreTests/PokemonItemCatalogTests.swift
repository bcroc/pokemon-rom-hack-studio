import XCTest
@testable import PokemonHackCore

final class PokemonItemCatalogTests: XCTestCase {
    func testEmeraldItemCatalogPlansAppliesBacksUpAndReloads() throws {
        let root = try temporaryRoot()
        try makeEmeraldProject(at: root, descriptionText: "Restores HP.")

        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemerald))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertEqual(potion.name, "POTION")
        XCTAssertEqual(potion.price, "300")
        XCTAssertEqual(potion.descriptionSymbol, "sPotionDesc")
        XCTAssertEqual(potion.descriptionText, "Restores HP.")
        XCTAssertTrue(potion.isEditable)
        XCTAssertTrue(potion.isDescriptionEditable)

        var draft = try XCTUnwrap(ItemEditDraft(detail: potion))
        draft.name = "SUPER POTION"
        draft.price = "700"
        draft.descriptionText = "Restores HP by\n60 points."
        draft.holdEffect = "HOLD_EFFECT_RESTORE_HP"
        draft.holdEffectParam = "60"
        draft.pocket = "POCKET_MEDICINE"
        draft.type = "ITEM_USE_PARTY_MENU"
        draft.battleUsage = "ITEM_B_USE_MEDICINE"
        draft.secondaryId = "ITEM_SUPER_POTION"
        draft.fieldUseFunc = "ItemUseOutOfBattle_Medicine"
        draft.battleUseFunc = "ItemUseInBattle_Medicine"

        let plan = ItemMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/items.h", "src/data/text/item_descriptions.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty, "\(plan.diagnostics)")
        XCTAssertTrue(plan.isApplyable)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(#".name = _("SUPER POTION")"#) == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".price = 700") == true)
        XCTAssertTrue(plan.changes.last?.textPreview?.contains(#""Restores HP by""#) == true)

        let result = try ItemMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.count, 2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let reloaded = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemerald))
        let edited = try XCTUnwrap(reloaded.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertEqual(edited.name, "SUPER POTION")
        XCTAssertEqual(edited.price, "700")
        XCTAssertEqual(edited.holdEffect, "HOLD_EFFECT_RESTORE_HP")
        XCTAssertEqual(edited.holdEffectParam, "60")
        XCTAssertEqual(edited.pocket, "POCKET_MEDICINE")
        XCTAssertEqual(edited.type, "ITEM_USE_PARTY_MENU")
        XCTAssertEqual(edited.battleUsage, "ITEM_B_USE_MEDICINE")
        XCTAssertEqual(edited.secondaryId, "ITEM_SUPER_POTION")
        XCTAssertEqual(edited.fieldUseFunc, "ItemUseOutOfBattle_Medicine")
        XCTAssertEqual(edited.battleUseFunc, "ItemUseInBattle_Medicine")
        XCTAssertEqual(edited.descriptionText, "Restores HP by\n60 points.")
    }

    func testRubySapphireItemRowsAndDescriptionsPlanApplyBackUpAndReload() throws {
        let root = try temporaryRoot()
        try makeRubyProject(at: root)

        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeruby))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertTrue(potion.isEditable)
        XCTAssertTrue(potion.isDescriptionEditable)
        XCTAssertEqual(potion.name, "POTION")
        XCTAssertEqual(potion.price, "300")
        XCTAssertEqual(potion.descriptionSymbol, "gItemDescription_Potion")
        XCTAssertEqual(potion.descriptionText, "Restores HP.")

        var draft = try XCTUnwrap(ItemEditDraft(detail: potion))
        draft.name = "SUPER POTION"
        draft.price = "700"
        draft.descriptionText = "Restores HP by\n20 points."
        draft.holdEffectParam = "60"
        draft.pocket = "POCKET_MEDICINE"
        draft.type = "ITEM_USE_PARTY_MENU"

        let plan = ItemMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/items_en.h", "src/data/item_descriptions_en.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty, "\(plan.diagnostics)")
        XCTAssertTrue(plan.isApplyable)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(#".name = _("SUPER POTION")"#) == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".price = 700") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".holdEffectParam = 60") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".description = gItemDescription_Potion") == true)
        XCTAssertTrue(plan.changes.last?.textPreview?.contains("gItemDescription_Potion") == true)
        XCTAssertTrue(plan.changes.last?.textPreview?.contains(#""Restores HP by""#) == true)

        let result = try ItemMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.count, 2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let reloaded = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeruby))
        let edited = try XCTUnwrap(reloaded.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertTrue(edited.isEditable)
        XCTAssertTrue(edited.isDescriptionEditable)
        XCTAssertEqual(edited.name, "SUPER POTION")
        XCTAssertEqual(edited.price, "700")
        XCTAssertEqual(edited.holdEffectParam, "60")
        XCTAssertEqual(edited.pocket, "POCKET_MEDICINE")
        XCTAssertEqual(edited.type, "ITEM_USE_PARTY_MENU")
        XCTAssertEqual(edited.descriptionText, "Restores HP by\n20 points.")
    }

    func testRubySapphireDescriptionOnlyPlanAppliesBacksUpAndReloads() throws {
        let root = try temporaryRoot()
        try makeRubyProject(at: root)

        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeruby))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertTrue(potion.isEditable)
        XCTAssertTrue(potion.isDescriptionEditable)
        XCTAssertEqual(potion.descriptionText, "Restores HP.")

        var draft = try XCTUnwrap(ItemEditDraft(detail: potion))
        draft.descriptionText = "A spray medicine.\nIt restores 20 HP."

        let plan = ItemMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/item_descriptions_en.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty, "\(plan.diagnostics)")
        XCTAssertTrue(plan.isApplyable)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains("static const u8 gItemDescription_Potion") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(#""A spray medicine.""#) == true)

        let result = try ItemMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/item_descriptions_en.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let reloaded = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeruby))
        let edited = try XCTUnwrap(reloaded.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertEqual(edited.descriptionText, "A spray medicine.\nIt restores 20 HP.")
    }

    func testRubySapphireMissingOrNonSimpleDescriptionDeclarationStaysDescriptionReadOnly() throws {
        let missingRoot = try temporaryRoot()
        try makeRubyProject(at: missingRoot, descriptionText: nil)

        let missingCatalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: missingRoot, profile: .pokeruby))
        let missingPotion = try XCTUnwrap(missingCatalog.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertTrue(missingPotion.isEditable)
        XCTAssertFalse(missingPotion.isDescriptionEditable)
        XCTAssertEqual(missingPotion.descriptionSymbol, "gItemDescription_Potion")
        XCTAssertNil(missingPotion.descriptionText)

        let missingPlan = ItemMutationPlanner.plan(
            catalog: missingCatalog,
            draft: ItemEditDraft(itemID: "ITEM_POTION", descriptionText: "Should stay blocked.")
        )
        XCTAssertTrue(missingPlan.changes.isEmpty)
        XCTAssertFalse(missingPlan.isApplyable)
        XCTAssertTrue(missingPlan.diagnostics.contains { $0.code == "ITEM_DESCRIPTION_NOT_EDITABLE" })

        let nonSimpleRoot = try temporaryRoot()
        try makeRubyProject(
            at: nonSimpleRoot,
            descriptionDeclaration: #"static const u8 gItemDescription_Potion[] = GetItemDescription(ITEM_POTION);"#
        )

        let nonSimpleCatalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: nonSimpleRoot, profile: .pokeruby))
        let nonSimplePotion = try XCTUnwrap(nonSimpleCatalog.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertTrue(nonSimplePotion.isEditable)
        XCTAssertFalse(nonSimplePotion.isDescriptionEditable)
        XCTAssertEqual(nonSimplePotion.descriptionSymbol, "gItemDescription_Potion")
        XCTAssertNil(nonSimplePotion.descriptionText)
    }

    func testExpansionItemInfoRowsPlanApplyAndReloadThroughDescriptor() throws {
        let root = try temporaryRoot()
        try makeExpansionItemInfoProject(at: root)

        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertTrue(potion.isEditable)
        XCTAssertTrue(potion.isDescriptionEditable)
        XCTAssertEqual(potion.name, "Potion")
        XCTAssertEqual(potion.price, "(I_PRICE >= GEN_7) ? 200 : 300")
        XCTAssertEqual(potion.descriptionText, "Restores HP.")
        XCTAssertEqual(potion.effect, "ITEM_EFFECT_HEAL")
        XCTAssertEqual(potion.iconPic, "gItemIcon_Potion")
        XCTAssertEqual(potion.iconPalette, "gItemIconPalette_Potion")

        let sourceIndex = try ProjectSourceIndexLoader.load(from: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let potionSource = try XCTUnwrap(sourceIndex.records.first { $0.module == .items && $0.title == "ITEM_POTION" })
        XCTAssertEqual(fact("effect", in: potionSource.facts), "ITEM_EFFECT_HEAL")
        XCTAssertEqual(fact("iconPic", in: potionSource.facts), "gItemIcon_Potion")
        XCTAssertEqual(fact("iconPalette", in: potionSource.facts), "gItemIconPalette_Potion")

        var draft = try XCTUnwrap(ItemEditDraft(detail: potion))
        draft.name = "Potion Plus"
        draft.price = "250"
        draft.holdEffectParam = "30"
        draft.descriptionText = "Restores HP by\n30 points."
        draft.effect = "ITEM_EFFECT_RESTORE_HP"
        draft.iconPic = "gItemIcon_PotionPlus"
        draft.iconPalette = "gItemIconPalette_PotionPlus"

        let plan = ItemMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/items.h"])
        XCTAssertTrue(plan.isApplyable)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains(#".name = ITEM_NAME("Potion Plus")"#))
        XCTAssertTrue(preview.contains(".price = 250"))
        XCTAssertTrue(preview.contains(".holdEffectParam = 30"))
        XCTAssertTrue(preview.contains(".description = COMPOUND_STRING("))
        XCTAssertTrue(preview.contains(#""Restores HP by\n""#))
        XCTAssertTrue(preview.contains(#""30 points.""#))
        XCTAssertTrue(preview.contains(".sortType = ITEM_TYPE_HEALTH_RECOVERY,"))
        XCTAssertTrue(preview.contains(".effect = ITEM_EFFECT_RESTORE_HP,"))
        XCTAssertTrue(preview.contains(".iconPic = gItemIcon_PotionPlus,"))
        XCTAssertTrue(preview.contains(".iconPalette = gItemIconPalette_PotionPlus,"))

        let result = try ItemMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/items.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))
        let updatedSource = try String(contentsOf: root.appendingPathComponent("src/data/items.h"), encoding: .utf8)
        XCTAssertEqual(updatedSource.components(separatedBy: "[ITEM_POTION]").count - 1, 1)

        let reloaded = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let edited = try XCTUnwrap(reloaded.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertTrue(edited.isEditable)
        XCTAssertTrue(edited.isDescriptionEditable)
        XCTAssertEqual(edited.name, "Potion Plus")
        XCTAssertEqual(edited.price, "250")
        XCTAssertEqual(edited.holdEffectParam, "30")
        XCTAssertEqual(edited.descriptionText, "Restores HP by\n30 points.")
        XCTAssertEqual(edited.effect, "ITEM_EFFECT_RESTORE_HP")
        XCTAssertEqual(edited.iconPic, "gItemIcon_PotionPlus")
        XCTAssertEqual(edited.iconPalette, "gItemIconPalette_PotionPlus")
    }

    func testExpansionItemInfoUsageScalarsPlanApplyBackUpAndReload() throws {
        let root = try temporaryRoot()
        try makeExpansionItemInfoProject(at: root)

        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertEqual(potion.holdEffect, "HOLD_EFFECT_NONE")
        XCTAssertEqual(potion.holdEffectParam, "20")
        XCTAssertEqual(potion.pocket, "POCKET_ITEMS")
        XCTAssertEqual(potion.type, "ITEM_USE_PARTY_MENU")

        var draft = try XCTUnwrap(ItemEditDraft(detail: potion))
        draft.holdEffect = "HOLD_EFFECT_RESTORE_HP"
        draft.holdEffectParam = "ITEM_POTION"
        draft.pocket = "POCKET_MEDICINE"
        draft.type = "ITEM_USE_FIELD"

        let plan = ItemMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/items.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty, "\(plan.diagnostics)")
        XCTAssertTrue(plan.isApplyable)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains(".holdEffect = HOLD_EFFECT_RESTORE_HP,"))
        XCTAssertTrue(preview.contains(".holdEffectParam = ITEM_POTION,"))
        XCTAssertTrue(preview.contains(".pocket = POCKET_MEDICINE,"))
        XCTAssertTrue(preview.contains(".type = ITEM_USE_FIELD,"))
        XCTAssertTrue(preview.contains(".sortType = ITEM_TYPE_HEALTH_RECOVERY,"))
        XCTAssertTrue(preview.contains(".effect = ITEM_EFFECT_HEAL,"))

        let result = try ItemMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/items.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let reloaded = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let edited = try XCTUnwrap(reloaded.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertEqual(edited.holdEffect, "HOLD_EFFECT_RESTORE_HP")
        XCTAssertEqual(edited.holdEffectParam, "ITEM_POTION")
        XCTAssertEqual(edited.pocket, "POCKET_MEDICINE")
        XCTAssertEqual(edited.type, "ITEM_USE_FIELD")
    }

    func testExpansionItemInfoBehaviorScalarsPlanApplyBackUpAndReload() throws {
        let root = try temporaryRoot()
        try makeExpansionItemInfoProject(at: root)

        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertEqual(potion.fieldUseFunc, "ItemUseOutOfBattle_Medicine")
        XCTAssertEqual(potion.battleUsage, "EFFECT_ITEM_RESTORE_HP")
        XCTAssertEqual(potion.battleUseFunc, "NULL")
        XCTAssertEqual(potion.secondaryId, "0")

        var draft = try XCTUnwrap(ItemEditDraft(detail: potion))
        draft.fieldUseFunc = "ItemUseOutOfBattle_EscapeRope"
        draft.battleUsage = "EFFECT_ITEM_CURE_POISON"
        draft.battleUseFunc = "ItemUseInBattle_Medicine"
        draft.secondaryId = "ITEM_ANTIDOTE"

        let plan = ItemMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/items.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty, "\(plan.diagnostics)")
        XCTAssertTrue(plan.isApplyable)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains(".fieldUseFunc = ItemUseOutOfBattle_EscapeRope,"))
        XCTAssertTrue(preview.contains(".battleUsage = EFFECT_ITEM_CURE_POISON,"))
        XCTAssertTrue(preview.contains(".battleUseFunc = ItemUseInBattle_Medicine,"))
        XCTAssertTrue(preview.contains(".secondaryId = ITEM_ANTIDOTE,"))
        XCTAssertTrue(preview.contains(".sortType = ITEM_TYPE_HEALTH_RECOVERY,"))

        let result = try ItemMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/items.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let reloaded = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let edited = try XCTUnwrap(reloaded.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertEqual(edited.fieldUseFunc, "ItemUseOutOfBattle_EscapeRope")
        XCTAssertEqual(edited.battleUsage, "EFFECT_ITEM_CURE_POISON")
        XCTAssertEqual(edited.battleUseFunc, "ItemUseInBattle_Medicine")
        XCTAssertEqual(edited.secondaryId, "ITEM_ANTIDOTE")
    }

    func testExpansionItemInfoMissingBehaviorScalarsInsertAsAnchoredGroupBackUpReloadAndBlockDrift() throws {
        let root = try temporaryRoot()
        try makeExpansionItemInfoProject(at: root, includeBehaviorScalars: false)

        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertNil(potion.fieldUseFunc)
        XCTAssertNil(potion.battleUsage)
        XCTAssertNil(potion.battleUseFunc)
        XCTAssertNil(potion.secondaryId)

        var draft = try XCTUnwrap(ItemEditDraft(detail: potion))
        draft.fieldUseFunc = "ItemUseOutOfBattle_EscapeRope"
        draft.battleUsage = "EFFECT_ITEM_CURE_POISON"
        draft.battleUseFunc = "ItemUseInBattle_Medicine"
        draft.secondaryId = "ITEM_ANTIDOTE"

        let plan = ItemMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/items.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty, "\(plan.diagnostics)")
        XCTAssertTrue(plan.isApplyable)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        let effectOffset = try XCTUnwrap(offset(of: ".effect = ITEM_EFFECT_HEAL,", in: preview))
        let fieldUseOffset = try XCTUnwrap(offset(of: ".fieldUseFunc = ItemUseOutOfBattle_EscapeRope,", in: preview))
        let battleUsageOffset = try XCTUnwrap(offset(of: ".battleUsage = EFFECT_ITEM_CURE_POISON,", in: preview))
        let battleUseOffset = try XCTUnwrap(offset(of: ".battleUseFunc = ItemUseInBattle_Medicine,", in: preview))
        let secondaryOffset = try XCTUnwrap(offset(of: ".secondaryId = ITEM_ANTIDOTE,", in: preview))
        let iconOffset = try XCTUnwrap(offset(of: ".iconPic = gItemIcon_Potion,", in: preview))
        XCTAssertLessThan(effectOffset, fieldUseOffset)
        XCTAssertLessThan(fieldUseOffset, battleUsageOffset)
        XCTAssertLessThan(battleUsageOffset, battleUseOffset)
        XCTAssertLessThan(battleUseOffset, secondaryOffset)
        XCTAssertLessThan(secondaryOffset, iconOffset)

        let sourcePath = root.appendingPathComponent("src/data/items.h")
        let original = try String(contentsOf: sourcePath, encoding: .utf8)
        try "\(original)\n// drift\n".write(to: sourcePath, atomically: true, encoding: .utf8)
        let driftApplyability = plan.validateApplyability()
        XCTAssertFalse(driftApplyability.isApplyable)
        XCTAssertTrue(driftApplyability.diagnostics.contains { $0.code == "ITEM_APPLY_ORIGINAL_SIZE_MISMATCH" || $0.code == "ITEM_APPLY_ORIGINAL_HASH_MISMATCH" })
        try original.write(to: sourcePath, atomically: true, encoding: .utf8)

        let result = try ItemMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/items.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let reloaded = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let edited = try XCTUnwrap(reloaded.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertEqual(edited.fieldUseFunc, "ItemUseOutOfBattle_EscapeRope")
        XCTAssertEqual(edited.battleUsage, "EFFECT_ITEM_CURE_POISON")
        XCTAssertEqual(edited.battleUseFunc, "ItemUseInBattle_Medicine")
        XCTAssertEqual(edited.secondaryId, "ITEM_ANTIDOTE")
    }

    func testExpansionItemInfoMissingUsageScalarsInsertAsSplitAnchoredGroupBackUpReloadAndBlockDrift() throws {
        let root = try temporaryRoot()
        try makeExpansionItemInfoProject(at: root, includeUsageScalars: false)
        let sourcePath = root.appendingPathComponent("src/data/items.h")
        let source = try String(contentsOf: sourcePath, encoding: .utf8)
            .replacingOccurrences(
                of: ".description =",
                with: ".customBeforeUsage = CUSTOM_VALUE, // keep me\n                .description ="
            )
        try source.write(to: sourcePath, atomically: true, encoding: .utf8)

        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertNil(potion.holdEffect)
        XCTAssertNil(potion.holdEffectParam)
        XCTAssertNil(potion.pocket)
        XCTAssertNil(potion.type)

        var draft = try XCTUnwrap(ItemEditDraft(detail: potion))
        draft.holdEffect = "HOLD_EFFECT_RESTORE_HP"
        draft.holdEffectParam = "60"
        draft.pocket = "POCKET_MEDICINE"
        draft.type = "ITEM_USE_PARTY_MENU"

        let plan = ItemMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/items.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty, "\(plan.diagnostics)")
        XCTAssertTrue(plan.isApplyable)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        let priceOffset = try XCTUnwrap(offset(of: ".price = (I_PRICE >= GEN_7) ? 200 : 300,", in: preview))
        let holdEffectOffset = try XCTUnwrap(offset(of: ".holdEffect = HOLD_EFFECT_RESTORE_HP,", in: preview))
        let holdParamOffset = try XCTUnwrap(offset(of: ".holdEffectParam = 60,", in: preview))
        let customOffset = try XCTUnwrap(offset(of: ".customBeforeUsage = CUSTOM_VALUE, // keep me", in: preview))
        let descriptionOffset = try XCTUnwrap(offset(of: ".description =", in: preview))
        let pocketOffset = try XCTUnwrap(offset(of: ".pocket = POCKET_MEDICINE,", in: preview))
        let importanceOffset = try XCTUnwrap(offset(of: ".importance = 0,", in: preview))
        let sortTypeOffset = try XCTUnwrap(offset(of: ".sortType = ITEM_TYPE_HEALTH_RECOVERY,", in: preview))
        let typeOffset = try XCTUnwrap(offset(of: ".type = ITEM_USE_PARTY_MENU,", in: preview))
        let exitsOffset = try XCTUnwrap(offset(of: ".exitsBagOnUse = FALSE,", in: preview))
        XCTAssertLessThan(priceOffset, holdEffectOffset)
        XCTAssertLessThan(holdEffectOffset, holdParamOffset)
        XCTAssertLessThan(holdParamOffset, customOffset)
        XCTAssertLessThan(customOffset, descriptionOffset)
        XCTAssertLessThan(descriptionOffset, pocketOffset)
        XCTAssertLessThan(pocketOffset, importanceOffset)
        XCTAssertLessThan(sortTypeOffset, typeOffset)
        XCTAssertLessThan(typeOffset, exitsOffset)

        let original = try String(contentsOf: sourcePath, encoding: .utf8)
        try "\(original)\n// drift\n".write(to: sourcePath, atomically: true, encoding: .utf8)
        let driftApplyability = plan.validateApplyability()
        XCTAssertFalse(driftApplyability.isApplyable)
        XCTAssertTrue(driftApplyability.diagnostics.contains { $0.code == "ITEM_APPLY_ORIGINAL_SIZE_MISMATCH" || $0.code == "ITEM_APPLY_ORIGINAL_HASH_MISMATCH" })
        try original.write(to: sourcePath, atomically: true, encoding: .utf8)

        let result = try ItemMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/items.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let reloaded = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let edited = try XCTUnwrap(reloaded.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertEqual(edited.holdEffect, "HOLD_EFFECT_RESTORE_HP")
        XCTAssertEqual(edited.holdEffectParam, "60")
        XCTAssertEqual(edited.pocket, "POCKET_MEDICINE")
        XCTAssertEqual(edited.type, "ITEM_USE_PARTY_MENU")
    }

    func testExpansionItemInfoUsageScalarsRejectNonSimpleValuesRemovalAndMissingFields() throws {
        let root = try temporaryRoot()
        try makeExpansionItemInfoProject(at: root)

        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        var draft = try XCTUnwrap(ItemEditDraft(detail: potion))
        draft.holdEffect = "HOLD_EFFECT_NONE | HOLD_EFFECT_RESTORE_HP"
        draft.holdEffectParam = "20 + 1"
        draft.pocket = nil
        draft.type = "GetItemType(ITEM_POTION)"

        let plan = ItemMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "ITEM_USAGE_SCALAR_INVALID" && $0.message.contains("holdEffect") })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "ITEM_USAGE_SCALAR_INVALID" && $0.message.contains("holdEffectParam") })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "ITEM_USAGE_SCALAR_REQUIRED" && $0.message.contains("pocket") })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "ITEM_USAGE_SCALAR_INVALID" && $0.message.contains("type") })

        let missingRoot = try temporaryRoot()
        try makeExpansionItemInfoProject(at: missingRoot, includeUsageScalars: false)
        let missingCatalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: missingRoot, profile: .pokeemeraldExpansion))
        let missingPotion = try XCTUnwrap(missingCatalog.items.first { $0.itemID == "ITEM_POTION" })
        var missingDraft = try XCTUnwrap(ItemEditDraft(detail: missingPotion))
        missingDraft.pocket = "POCKET_MEDICINE"

        let missingPlan = ItemMutationPlanner.plan(catalog: missingCatalog, draft: missingDraft)
        XCTAssertTrue(missingPlan.changes.isEmpty)
        XCTAssertFalse(missingPlan.isApplyable)
        XCTAssertTrue(missingPlan.diagnostics.contains { $0.code == "ITEM_USAGE_SCALAR_INSERTION_REQUIRED" && $0.message.contains("together") })

        let missingAnchorRoot = try temporaryRoot()
        try makeExpansionItemInfoProject(at: missingAnchorRoot, includeUsageScalars: false, includeBagClassificationScalars: false)
        let missingAnchorCatalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: missingAnchorRoot, profile: .pokeemeraldExpansion))
        let missingAnchorPotion = try XCTUnwrap(missingAnchorCatalog.items.first { $0.itemID == "ITEM_POTION" })
        var missingAnchorDraft = try XCTUnwrap(ItemEditDraft(detail: missingAnchorPotion))
        missingAnchorDraft.holdEffect = "HOLD_EFFECT_RESTORE_HP"
        missingAnchorDraft.holdEffectParam = "60"
        missingAnchorDraft.pocket = "POCKET_MEDICINE"
        missingAnchorDraft.type = "ITEM_USE_PARTY_MENU"

        let missingAnchorPlan = ItemMutationPlanner.plan(catalog: missingAnchorCatalog, draft: missingAnchorDraft)
        XCTAssertTrue(missingAnchorPlan.changes.isEmpty)
        XCTAssertFalse(missingAnchorPlan.isApplyable)
        XCTAssertTrue(missingAnchorPlan.diagnostics.contains { $0.code == "ITEM_USAGE_SCALAR_INSERTION_ANCHOR_MISSING" })

        let partialExistingRoot = try temporaryRoot()
        try makeExpansionItemInfoProject(at: partialExistingRoot, includeUsageScalars: false, includePartialUsageScalars: true)
        let partialExistingCatalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: partialExistingRoot, profile: .pokeemeraldExpansion))
        let partialExistingPotion = try XCTUnwrap(partialExistingCatalog.items.first { $0.itemID == "ITEM_POTION" })
        var partialExistingDraft = try XCTUnwrap(ItemEditDraft(detail: partialExistingPotion))
        partialExistingDraft.holdEffect = "HOLD_EFFECT_RESTORE_HP"
        partialExistingDraft.holdEffectParam = "60"
        partialExistingDraft.pocket = "POCKET_MEDICINE"
        partialExistingDraft.type = "ITEM_USE_PARTY_MENU"

        let partialExistingPlan = ItemMutationPlanner.plan(catalog: partialExistingCatalog, draft: partialExistingDraft)
        XCTAssertTrue(partialExistingPlan.changes.isEmpty)
        XCTAssertFalse(partialExistingPlan.isApplyable)
        XCTAssertTrue(partialExistingPlan.diagnostics.contains { $0.code == "ITEM_USAGE_SCALAR_NOT_EDITABLE" && $0.message.contains("partial missing-field insertion") })

        let nonSimpleCurrentRoot = try temporaryRoot()
        try makeExpansionItemInfoProject(at: nonSimpleCurrentRoot, holdEffectValue: "HOLD_EFFECT_ALIAS(HOLD_EFFECT_NONE)")
        let nonSimpleCurrentCatalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: nonSimpleCurrentRoot, profile: .pokeemeraldExpansion))
        let nonSimpleCurrentPotion = try XCTUnwrap(nonSimpleCurrentCatalog.items.first { $0.itemID == "ITEM_POTION" })
        var nonSimpleCurrentDraft = try XCTUnwrap(ItemEditDraft(detail: nonSimpleCurrentPotion))
        nonSimpleCurrentDraft.holdEffect = "HOLD_EFFECT_RESTORE_HP"

        let nonSimpleCurrentPlan = ItemMutationPlanner.plan(catalog: nonSimpleCurrentCatalog, draft: nonSimpleCurrentDraft)
        XCTAssertTrue(nonSimpleCurrentPlan.changes.isEmpty)
        XCTAssertFalse(nonSimpleCurrentPlan.isApplyable)
        XCTAssertTrue(nonSimpleCurrentPlan.diagnostics.contains { $0.code == "ITEM_USAGE_SCALAR_UNSUPPORTED_EXPRESSION" && $0.message.contains("holdEffect") })
    }

    func testExpansionItemInfoBehaviorScalarsRejectNonSimpleValuesRemovalAndMissingFields() throws {
        let root = try temporaryRoot()
        try makeExpansionItemInfoProject(at: root)

        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        var draft = try XCTUnwrap(ItemEditDraft(detail: potion))
        draft.fieldUseFunc = "ItemUseOutOfBattle_Medicine(ITEM_POTION)"
        draft.battleUsage = "EFFECT_ITEM_RESTORE_HP | EFFECT_ITEM_CURE"
        draft.battleUseFunc = nil
        draft.secondaryId = "ITEM_POTION + 1"

        let plan = ItemMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "ITEM_BEHAVIOR_SCALAR_INVALID" && $0.message.contains("fieldUseFunc") })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "ITEM_BEHAVIOR_SCALAR_INVALID" && $0.message.contains("battleUsage") })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "ITEM_BEHAVIOR_SCALAR_REQUIRED" && $0.message.contains("battleUseFunc") })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "ITEM_BEHAVIOR_SCALAR_INVALID" && $0.message.contains("secondaryId") })

        let missingRoot = try temporaryRoot()
        try makeExpansionItemInfoProject(at: missingRoot, includeBehaviorScalars: false)
        let missingCatalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: missingRoot, profile: .pokeemeraldExpansion))
        let missingPotion = try XCTUnwrap(missingCatalog.items.first { $0.itemID == "ITEM_POTION" })
        var missingDraft = try XCTUnwrap(ItemEditDraft(detail: missingPotion))
        missingDraft.fieldUseFunc = "ItemUseOutOfBattle_Medicine"

        let missingPlan = ItemMutationPlanner.plan(catalog: missingCatalog, draft: missingDraft)
        XCTAssertTrue(missingPlan.changes.isEmpty)
        XCTAssertFalse(missingPlan.isApplyable)
        XCTAssertTrue(missingPlan.diagnostics.contains { $0.code == "ITEM_BEHAVIOR_SCALAR_INSERTION_REQUIRED" && $0.message.contains("together") })

        let missingAnchorRoot = try temporaryRoot()
        try makeExpansionItemInfoProject(at: missingAnchorRoot, includeBehaviorScalars: false, includeIconPicAnchor: false)
        let missingAnchorCatalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: missingAnchorRoot, profile: .pokeemeraldExpansion))
        let missingAnchorPotion = try XCTUnwrap(missingAnchorCatalog.items.first { $0.itemID == "ITEM_POTION" })
        var missingAnchorDraft = try XCTUnwrap(ItemEditDraft(detail: missingAnchorPotion))
        missingAnchorDraft.fieldUseFunc = "ItemUseOutOfBattle_Medicine"
        missingAnchorDraft.battleUsage = "EFFECT_ITEM_RESTORE_HP"
        missingAnchorDraft.battleUseFunc = "NULL"
        missingAnchorDraft.secondaryId = "0"

        let missingAnchorPlan = ItemMutationPlanner.plan(catalog: missingAnchorCatalog, draft: missingAnchorDraft)
        XCTAssertTrue(missingAnchorPlan.changes.isEmpty)
        XCTAssertFalse(missingAnchorPlan.isApplyable)
        XCTAssertTrue(missingAnchorPlan.diagnostics.contains { $0.code == "ITEM_BEHAVIOR_SCALAR_INSERTION_ANCHOR_MISSING" })

        let nonSimpleCurrentRoot = try temporaryRoot()
        try makeExpansionItemInfoProject(at: nonSimpleCurrentRoot, fieldUseFuncValue: "GetFieldUseFunc(ITEM_POTION)")
        let nonSimpleCurrentCatalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: nonSimpleCurrentRoot, profile: .pokeemeraldExpansion))
        let nonSimpleCurrentPotion = try XCTUnwrap(nonSimpleCurrentCatalog.items.first { $0.itemID == "ITEM_POTION" })
        var nonSimpleCurrentDraft = try XCTUnwrap(ItemEditDraft(detail: nonSimpleCurrentPotion))
        nonSimpleCurrentDraft.fieldUseFunc = "ItemUseOutOfBattle_Medicine"

        let nonSimpleCurrentPlan = ItemMutationPlanner.plan(catalog: nonSimpleCurrentCatalog, draft: nonSimpleCurrentDraft)
        XCTAssertTrue(nonSimpleCurrentPlan.changes.isEmpty)
        XCTAssertFalse(nonSimpleCurrentPlan.isApplyable)
        XCTAssertTrue(nonSimpleCurrentPlan.diagnostics.contains { $0.code == "ITEM_BEHAVIOR_SCALAR_UNSUPPORTED_EXPRESSION" && $0.message.contains("fieldUseFunc") })
    }

    func testExpansionItemInfoBagClassificationScalarsPlanApplyBackUpReloadAndBlockDrift() throws {
        let root = try temporaryRoot()
        try makeExpansionItemInfoProject(at: root)

        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertEqual(potion.importance, "0")
        XCTAssertEqual(potion.registrability, "0")
        XCTAssertEqual(potion.sortType, "ITEM_TYPE_HEALTH_RECOVERY")
        XCTAssertEqual(potion.exitsBagOnUse, "FALSE")

        let sourceIndex = try ProjectSourceIndexLoader.load(from: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let potionSource = try XCTUnwrap(sourceIndex.records.first { $0.module == .items && $0.title == "ITEM_POTION" })
        XCTAssertEqual(fact("sortType", in: potionSource.facts), "ITEM_TYPE_HEALTH_RECOVERY")
        XCTAssertEqual(fact("exitsBagOnUse", in: potionSource.facts), "FALSE")

        var draft = try XCTUnwrap(ItemEditDraft(detail: potion))
        draft.importance = "1"
        draft.registrability = "ITEM_REGISTER_ALLOWED"
        draft.sortType = "ITEM_TYPE_FIELD_USE"
        draft.exitsBagOnUse = "TRUE"

        let plan = ItemMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/items.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty, "\(plan.diagnostics)")
        XCTAssertTrue(plan.isApplyable)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains(".importance = 1,"))
        XCTAssertTrue(preview.contains(".registrability = ITEM_REGISTER_ALLOWED,"))
        XCTAssertTrue(preview.contains(".sortType = ITEM_TYPE_FIELD_USE,"))
        XCTAssertTrue(preview.contains(".exitsBagOnUse = TRUE,"))
        XCTAssertTrue(preview.contains(".fieldUseFunc = ItemUseOutOfBattle_Medicine,"))

        let sourcePath = root.appendingPathComponent("src/data/items.h")
        let original = try String(contentsOf: sourcePath, encoding: .utf8)
        try "\(original)\n// drift\n".write(to: sourcePath, atomically: true, encoding: .utf8)
        let driftApplyability = plan.validateApplyability()
        XCTAssertFalse(driftApplyability.isApplyable)
        XCTAssertTrue(driftApplyability.diagnostics.contains { $0.code == "ITEM_APPLY_ORIGINAL_SIZE_MISMATCH" || $0.code == "ITEM_APPLY_ORIGINAL_HASH_MISMATCH" })
        try original.write(to: sourcePath, atomically: true, encoding: .utf8)

        let result = try ItemMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/items.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let reloaded = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let edited = try XCTUnwrap(reloaded.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertEqual(edited.importance, "1")
        XCTAssertEqual(edited.registrability, "ITEM_REGISTER_ALLOWED")
        XCTAssertEqual(edited.sortType, "ITEM_TYPE_FIELD_USE")
        XCTAssertEqual(edited.exitsBagOnUse, "TRUE")
    }

    func testExpansionItemInfoBagClassificationScalarsRejectNonSimpleValuesRemovalAndMissingFields() throws {
        let root = try temporaryRoot()
        try makeExpansionItemInfoProject(at: root)

        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        var draft = try XCTUnwrap(ItemEditDraft(detail: potion))
        draft.importance = "(1 + 2)"
        draft.registrability = nil
        draft.sortType = "ITEM_TYPE_HEALTH_RECOVERY | ITEM_TYPE_FIELD_USE"
        draft.exitsBagOnUse = "GetExitFlag()"

        let plan = ItemMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "ITEM_BAG_CLASSIFICATION_SCALAR_INVALID" && $0.message.contains("importance") })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "ITEM_BAG_CLASSIFICATION_SCALAR_REQUIRED" && $0.message.contains("registrability") })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "ITEM_BAG_CLASSIFICATION_SCALAR_INVALID" && $0.message.contains("sortType") })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "ITEM_BAG_CLASSIFICATION_SCALAR_INVALID" && $0.message.contains("exitsBagOnUse") })

        let missingRoot = try temporaryRoot()
        try makeExpansionItemInfoProject(at: missingRoot, includeBagClassificationScalars: false)
        let missingCatalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: missingRoot, profile: .pokeemeraldExpansion))
        let missingPotion = try XCTUnwrap(missingCatalog.items.first { $0.itemID == "ITEM_POTION" })
        var missingDraft = try XCTUnwrap(ItemEditDraft(detail: missingPotion))
        missingDraft.sortType = "ITEM_TYPE_FIELD_USE"

        let missingPlan = ItemMutationPlanner.plan(catalog: missingCatalog, draft: missingDraft)
        XCTAssertTrue(missingPlan.changes.isEmpty)
        XCTAssertFalse(missingPlan.isApplyable)
        XCTAssertTrue(missingPlan.diagnostics.contains { $0.code == "ITEM_BAG_CLASSIFICATION_SCALAR_NOT_EDITABLE" && $0.message.contains("missing-field insertion") })

        let nonSimpleCurrentRoot = try temporaryRoot()
        try makeExpansionItemInfoProject(at: nonSimpleCurrentRoot, sortTypeValue: "GetItemSortType(ITEM_POTION)")
        let nonSimpleCurrentCatalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: nonSimpleCurrentRoot, profile: .pokeemeraldExpansion))
        let nonSimpleCurrentPotion = try XCTUnwrap(nonSimpleCurrentCatalog.items.first { $0.itemID == "ITEM_POTION" })
        var nonSimpleCurrentDraft = try XCTUnwrap(ItemEditDraft(detail: nonSimpleCurrentPotion))
        nonSimpleCurrentDraft.sortType = "ITEM_TYPE_FIELD_USE"

        let nonSimpleCurrentPlan = ItemMutationPlanner.plan(catalog: nonSimpleCurrentCatalog, draft: nonSimpleCurrentDraft)
        XCTAssertTrue(nonSimpleCurrentPlan.changes.isEmpty)
        XCTAssertFalse(nonSimpleCurrentPlan.isApplyable)
        XCTAssertTrue(nonSimpleCurrentPlan.diagnostics.contains { $0.code == "ITEM_BAG_CLASSIFICATION_SCALAR_UNSUPPORTED_EXPRESSION" && $0.message.contains("sortType") })
    }

    func testExpansionItemInfoEffectIconRejectsNonSimpleSymbolsAndRemoval() throws {
        let root = try temporaryRoot()
        try makeExpansionItemInfoProject(at: root)

        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        var draft = try XCTUnwrap(ItemEditDraft(detail: potion))
        draft.effect = "ITEM_EFFECT_HEAL | ITEM_EFFECT_CURE"
        draft.iconPic = "GetItemIcon(ITEM_POTION)"
        draft.iconPalette = nil

        let plan = ItemMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "ITEM_EFFECT_ICON_SYMBOL_INVALID" && $0.message.contains("effect") })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "ITEM_EFFECT_ICON_SYMBOL_INVALID" && $0.message.contains("iconPic") })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "ITEM_EFFECT_ICON_REQUIRED" && $0.message.contains("iconPalette") })
    }

    func testExpansionInlineCompoundStringConcatenatesCLiteralsWithoutExtraBlankLines() throws {
        let root = try temporaryRoot()
        try makeExpansionItemInfoProject(at: root, descriptionValue: #"COMPOUND_STRING("A\n" "B.")"#)

        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertTrue(potion.isDescriptionEditable)
        XCTAssertEqual(potion.descriptionText, "A\nB.")

        var draft = try XCTUnwrap(ItemEditDraft(detail: potion))
        draft.descriptionText = "A\nC."

        let plan = ItemMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertTrue(plan.isApplyable)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)
        XCTAssertTrue(preview.contains(#""A\n""#))
        XCTAssertTrue(preview.contains(#""C.""#))

        _ = try ItemMutationApplier.apply(plan: plan)

        let reloaded = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let edited = try XCTUnwrap(reloaded.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertEqual(edited.descriptionText, "A\nC.")
        XCTAssertFalse(edited.descriptionText?.contains("\n\n") == true)
    }

    func testExpansionItemInfoNonSimpleDescriptionStaysDescriptionReadOnly() throws {
        let root = try temporaryRoot()
        try makeExpansionItemInfoProject(at: root, descriptionValue: "GetItemDescription(ITEM_POTION)")

        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertTrue(potion.isEditable)
        XCTAssertFalse(potion.isDescriptionEditable)
        XCTAssertNil(potion.descriptionText)
        XCTAssertEqual(potion.descriptionSymbol, "GetItemDescription(ITEM_POTION)")

        let plan = ItemMutationPlanner.plan(
            catalog: catalog,
            draft: ItemEditDraft(itemID: "ITEM_POTION", descriptionText: "Should stay blocked.")
        )
        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "ITEM_DESCRIPTION_NOT_EDITABLE" })
    }

    func testFireRedItemRowsAndDescriptionPlanAsSingleFileChange() throws {
        let root = try temporaryRoot()
        try makeFireRedProject(at: root)

        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokefirered))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertTrue(potion.isEditable)
        XCTAssertTrue(potion.isDescriptionEditable)
        XCTAssertEqual(potion.descriptionSymbol, "gItemDescription_ITEM_POTION")
        XCTAssertEqual(potion.descriptionText, "A spray medicine.\nIt restores HP.")

        var draft = try XCTUnwrap(ItemEditDraft(detail: potion))
        draft.price = "700"
        draft.holdEffectParam = "60"
        draft.descriptionText = "A compact medicine.\nIt restores 20 HP."

        let plan = ItemMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/items.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty, "\(plan.diagnostics)")
        XCTAssertTrue(plan.isApplyable)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains("gItemDescription_ITEM_POTION") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".price = 700") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".holdEffectParam = 60") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(#""A compact medicine.""#) == true)

        let result = try ItemMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.count, 1)

        let reloaded = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokefirered))
        let edited = try XCTUnwrap(reloaded.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertTrue(edited.isEditable)
        XCTAssertTrue(edited.isDescriptionEditable)
        XCTAssertEqual(edited.price, "700")
        XCTAssertEqual(edited.holdEffectParam, "60")
        XCTAssertEqual(edited.descriptionText, "A compact medicine.\nIt restores 20 HP.")
    }

    func testItemIdMismatchBlocksEditing() throws {
        let root = try temporaryRoot()
        try makeEmeraldProject(
            at: root,
            itemId: "ITEM_ANTIDOTE"
        )

        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemerald))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertFalse(potion.isEditable)
        XCTAssertTrue(potion.diagnostics.contains { $0.code == "ITEM_ENTRY_ID_MISMATCH" })

        let plan = ItemMutationPlanner.plan(catalog: catalog, draft: ItemEditDraft(itemID: "ITEM_POTION", price: "700"))
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "ITEM_NOT_EDITABLE" })
        XCTAssertTrue(plan.changes.isEmpty)
    }

    func testNoOpPlanHasNoChangesAndIsNotApplyable() throws {
        let root = try temporaryRoot()
        try makeEmeraldProject(at: root)
        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemerald))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        let draft = try XCTUnwrap(ItemEditDraft(detail: potion))

        let plan = ItemMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty)
        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.applyability.diagnostics.contains { $0.code == "ITEM_APPLY_NO_CHANGES" })
    }

    func testApplySafetyReportsSizeAndHashMismatches() throws {
        let sizeRoot = try temporaryRoot()
        try makeEmeraldProject(at: sizeRoot)
        let sizePlan = try pricePlan(root: sizeRoot, price: "700")
        try "changed\n".write(to: sizeRoot.appendingPathComponent("src/data/items.h"), atomically: true, encoding: .utf8)
        let sizeApplyability = sizePlan.validateApplyability()
        XCTAssertFalse(sizeApplyability.isApplyable)
        XCTAssertTrue(sizeApplyability.diagnostics.contains { $0.code == "ITEM_APPLY_ORIGINAL_SIZE_MISMATCH" })

        let hashRoot = try temporaryRoot()
        try makeEmeraldProject(at: hashRoot)
        let hashPlan = try pricePlan(root: hashRoot, price: "700")
        let original = try String(contentsOf: hashRoot.appendingPathComponent("src/data/items.h"), encoding: .utf8)
        let sameSize = original.replacingOccurrences(of: "POTION", with: "LOTION")
        XCTAssertEqual(Data(original.utf8).count, Data(sameSize.utf8).count)
        try sameSize.write(to: hashRoot.appendingPathComponent("src/data/items.h"), atomically: true, encoding: .utf8)
        let hashApplyability = hashPlan.validateApplyability()
        XCTAssertFalse(hashApplyability.isApplyable)
        XCTAssertTrue(hashApplyability.diagnostics.contains { $0.code == "ITEM_APPLY_ORIGINAL_HASH_MISMATCH" })
    }

    func testPlannerPreservesUnknownFieldsOrderAndComments() throws {
        let root = try temporaryRoot()
        try makeEmeraldProject(at: root)
        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemerald))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        var draft = try XCTUnwrap(ItemEditDraft(detail: potion))
        draft.price = "700"

        let plan = ItemMutationPlanner.plan(catalog: catalog, draft: draft)
        let preview = try XCTUnwrap(plan.changes.first?.textPreview)

        XCTAssertTrue(preview.contains(".customField = CUSTOM_VALUE, // keep me"))
        XCTAssertTrue(preview.contains("/* keep block comment */"))
        XCTAssertTrue(preview.contains(".description = sPotionDesc,"))
        XCTAssertTrue(preview.contains(".price = 700, // shop price"))
        XCTAssertLessThan(
            preview.range(of: ".customField")?.lowerBound ?? preview.endIndex,
            preview.range(of: ".price")?.lowerBound ?? preview.startIndex
        )
    }

    private func makeRubyProject(
        at root: URL,
        descriptionText: String? = "Restores HP.",
        descriptionDeclaration: String? = nil
    ) throws {
        try write(
            """
            const struct Item gItems[] =
            {
                {
                    .name = _(\"POTION\"),
                    .itemId = ITEM_POTION,
                    .customField = CUSTOM_VALUE, // keep me
                    .price = 300, // shop price
                    .holdEffect = HOLD_EFFECT_NONE,
                    .holdEffectParam = 0,
                    .description = gItemDescription_Potion,
                    .pocket = POCKET_ITEMS,
                    .type = ITEM_USE_FIELD,
                    .fieldUseFunc = ItemUseOutOfBattle_Medicine,
                    .battleUsage = 0,
                    .battleUseFunc = NULL,
                    .secondaryId = 0,
                },
            };
            """,
            to: root.appendingPathComponent("src/data/items_en.h")
        )
        if let descriptionDeclaration {
            try write(
                descriptionDeclaration,
                to: root.appendingPathComponent("src/data/item_descriptions_en.h")
            )
        } else if let descriptionText {
            let lines = descriptionText.components(separatedBy: "\n")
                .map { #"    "\#($0)""# }
                .joined(separator: "\n")
            try write(
                """
                static const u8 gItemDescription_Potion[] = _(
                \(lines));
                """,
                to: root.appendingPathComponent("src/data/item_descriptions_en.h")
            )
        }
    }

    private func makeExpansionItemInfoProject(
        at root: URL,
        descriptionValue: String = """
        COMPOUND_STRING(
                        "Restores HP.")
        """,
        holdEffectValue: String = "HOLD_EFFECT_NONE",
        sortTypeValue: String = "ITEM_TYPE_HEALTH_RECOVERY",
        fieldUseFuncValue: String = "ItemUseOutOfBattle_Medicine",
        includeUsageScalars: Bool = true,
        includePartialUsageScalars: Bool = false,
        includeBehaviorScalars: Bool = true,
        includeBagClassificationScalars: Bool = true,
        includeIconPicAnchor: Bool = true
    ) throws {
        var source = """
            const struct ItemInfo gItemsInfo[] =
            {
                [ITEM_POTION] =
                {
                    .name = ITEM_NAME("Potion"),
                    .price = (I_PRICE >= GEN_7) ? 200 : 300,
            """
        if includeUsageScalars {
            source += """
                    .holdEffect = \(holdEffectValue),
                    .holdEffectParam = 20,
            """
        } else if includePartialUsageScalars {
            source += """
                    .holdEffect = \(holdEffectValue),
            """
        }
        source += """
                    .description = \(descriptionValue),
            """
        if includeUsageScalars {
            source += """
                    .pocket = POCKET_ITEMS,
            """
        }
        if includeBagClassificationScalars {
            source += """
                    .importance = 0,
                    .registrability = 0,
                    .sortType = \(sortTypeValue),
                    .exitsBagOnUse = FALSE,
            """
        }
        if includeUsageScalars {
            source += """
                    .type = ITEM_USE_PARTY_MENU,
            """
        }
        source += """
                    .effect = ITEM_EFFECT_HEAL,
            """
        if includeBehaviorScalars {
            source += """
                    .fieldUseFunc = \(fieldUseFuncValue),
                    .battleUsage = EFFECT_ITEM_RESTORE_HP,
                    .battleUseFunc = NULL,
                    .secondaryId = 0,
            """
        }
        if includeIconPicAnchor {
            source += """
                    .iconPic = gItemIcon_Potion,
            """
        }
        source += """
                    .iconPalette = gItemIconPalette_Potion,
                },
            };
            """
        try write(source, to: root.appendingPathComponent("src/data/items.h"))
    }

    private func pricePlan(root: URL, price: String) throws -> ItemEditPlan {
        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemerald))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        var draft = try XCTUnwrap(ItemEditDraft(detail: potion))
        draft.price = price
        return ItemMutationPlanner.plan(catalog: catalog, draft: draft)
    }

    private func makeEmeraldProject(
        at root: URL,
        itemId: String = "ITEM_POTION",
        descriptionText: String? = nil
    ) throws {
        try write(
            """
            const struct Item gItems[] =
            {
                [ITEM_NONE] =
                {
                    .name = _(\"????????\"),
                    .itemId = ITEM_NONE,
                    .price = 0,
                    .holdEffect = HOLD_EFFECT_NONE,
                    .holdEffectParam = 0,
                    .description = sDummyDesc,
                    .pocket = POCKET_ITEMS,
                    .type = ITEM_USE_FIELD,
                    .fieldUseFunc = ItemUseOutOfBattle_CannotUse,
                    .battleUsage = 0,
                    .battleUseFunc = NULL,
                    .secondaryId = 0,
                },
                [ITEM_POTION] =
                {
                    .name = _(\"POTION\"),
                    .itemId = \(itemId),
                    .customField = CUSTOM_VALUE, // keep me
                    .price = 300, // shop price
                    .holdEffect = HOLD_EFFECT_NONE,
                    .holdEffectParam = 0,
                    .description = sPotionDesc,
                    /* keep block comment */
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
        if let descriptionText {
            let lines = descriptionText.components(separatedBy: "\n")
                .map { #"    "\#($0)""# }
                .joined(separator: "\n")
            try write(
                """
                static const u8 sPotionDesc[] = _(
                \(lines));
                """,
                to: root.appendingPathComponent("src/data/text/item_descriptions.h")
            )
        }
    }

    private func makeFireRedProject(at root: URL) throws {
        try write(
            """
            const u8 gItemDescription_ITEM_POTION[] = _(\"A spray medicine.\\nIt restores HP.\");
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
    }

    private func sourceIndex(profile: GameProfile, path: String, tags: [String]) -> ProjectSourceIndex {
        let root = URL(fileURLWithPath: "/tmp/pokemonhack-items-read-only-\(profile.rawValue)")
        return ProjectSourceIndex(
            root: SourceLocation(path: root.path, exists: true),
            profile: profile,
            adapterID: "test.items",
            adapterName: "Item Fixture",
            records: [
                SourceIndexRecord(
                    id: "items:\(profile.rawValue):ITEM_POTION",
                    module: .items,
                    title: "ITEM_POTION",
                    subtitle: path,
                    sourceSpan: SourceSpan(relativePath: path, startLine: 1),
                    tags: tags,
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

    private func projectIndex(root: URL, profile: GameProfile) -> ProjectIndex {
        ProjectIndex(
            root: SourceLocation(path: root.path, exists: true),
            profile: profile,
            adapterID: "test.items",
            adapterName: "Item Fixture",
            editorModules: [.items],
            capabilities: [.diagnostics],
            writePolicy: .mutationPlanOnly,
            documents: []
        )
    }

    private func temporaryRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonItemCatalogTests-\(UUID().uuidString)", isDirectory: true)
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

    private func fact(_ label: String, in facts: [SourceIndexFact]) -> String? {
        facts.first { $0.label == label }?.value
    }

    private func offset(of needle: String, in haystack: String) -> Int? {
        haystack.range(of: needle).map { haystack.distance(from: haystack.startIndex, to: $0.lowerBound) }
    }
}
