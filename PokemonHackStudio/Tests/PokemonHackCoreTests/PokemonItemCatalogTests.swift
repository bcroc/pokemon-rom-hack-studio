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

    func testRubySapphireItemRowsPlanApplyBackUpAndReloadWithoutDescriptionWrites() throws {
        let root = try temporaryRoot()
        try makeRubyProject(at: root)

        let catalog = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeruby))
        let potion = try XCTUnwrap(catalog.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertTrue(potion.isEditable)
        XCTAssertFalse(potion.isDescriptionEditable)
        XCTAssertEqual(potion.name, "POTION")
        XCTAssertEqual(potion.price, "300")
        XCTAssertEqual(potion.descriptionSymbol, "sPotionDesc")
        XCTAssertNil(potion.descriptionText)

        var draft = try XCTUnwrap(ItemEditDraft(detail: potion))
        draft.name = "SUPER POTION"
        draft.price = "700"
        draft.holdEffectParam = "60"
        draft.pocket = "POCKET_MEDICINE"
        draft.type = "ITEM_USE_PARTY_MENU"

        let plan = ItemMutationPlanner.plan(catalog: catalog, draft: draft)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/items_en.h"])
        XCTAssertTrue(plan.diagnostics.filter { $0.severity == .error }.isEmpty, "\(plan.diagnostics)")
        XCTAssertTrue(plan.isApplyable)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(#".name = _("SUPER POTION")"#) == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".price = 700") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".holdEffectParam = 60") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".description = sPotionDesc") == true)

        let result = try ItemMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let reloaded = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeruby))
        let edited = try XCTUnwrap(reloaded.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertTrue(edited.isEditable)
        XCTAssertFalse(edited.isDescriptionEditable)
        XCTAssertEqual(edited.name, "SUPER POTION")
        XCTAssertEqual(edited.price, "700")
        XCTAssertEqual(edited.holdEffectParam, "60")
        XCTAssertEqual(edited.pocket, "POCKET_MEDICINE")
        XCTAssertEqual(edited.type, "ITEM_USE_PARTY_MENU")
        XCTAssertNil(edited.descriptionText)
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

        var draft = try XCTUnwrap(ItemEditDraft(detail: potion))
        draft.name = "Potion Plus"
        draft.price = "250"
        draft.holdEffectParam = "30"
        draft.descriptionText = "Restores HP by\n30 points."

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

        let result = try ItemMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/items.h"])

        let reloaded = try ProjectItemCatalogBuilder.build(index: projectIndex(root: root, profile: .pokeemeraldExpansion))
        let edited = try XCTUnwrap(reloaded.items.first { $0.itemID == "ITEM_POTION" })
        XCTAssertTrue(edited.isEditable)
        XCTAssertTrue(edited.isDescriptionEditable)
        XCTAssertEqual(edited.name, "Potion Plus")
        XCTAssertEqual(edited.price, "250")
        XCTAssertEqual(edited.holdEffectParam, "30")
        XCTAssertEqual(edited.descriptionText, "Restores HP by\n30 points.")
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

    private func makeRubyProject(at root: URL) throws {
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
                    .description = sPotionDesc,
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
    }

    private func makeExpansionItemInfoProject(
        at root: URL,
        descriptionValue: String = """
        COMPOUND_STRING(
                        "Restores HP.")
        """
    ) throws {
        try write(
            """
            const struct ItemInfo gItemsInfo[] =
            {
                [ITEM_POTION] =
                {
                    .name = ITEM_NAME("Potion"),
                    .price = (I_PRICE >= GEN_7) ? 200 : 300,
                    .holdEffectParam = 20,
                    .description = \(descriptionValue),
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
}
