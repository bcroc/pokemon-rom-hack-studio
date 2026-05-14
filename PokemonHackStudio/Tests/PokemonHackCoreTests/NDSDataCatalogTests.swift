import XCTest
@testable import PokemonHackCore

final class NDSDataCatalogTests: XCTestCase {
    private var temporaryDirectories: [NDSDataCatalogTemporaryDirectory] = []

    override func tearDown() {
        temporaryDirectories.removeAll()
        super.tearDown()
    }

    func testPlatinumSemanticSourcePathsBuildReadOnlyCatalog() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)

        let index = try GameAdapterRegistry.index(path: root.path)
        let catalog = NDSDataCatalogBuilder.build(index: index)

        XCTAssertEqual(catalog.profile, .pokeplatinum)
        XCTAssertEqual(catalog.family, .platinum)
        XCTAssertTrue(catalog.isReadOnly)
        XCTAssertTrue(index.capabilities.contains(.ndsDataCatalog))
        XCTAssertFalse(index.capabilities.contains(.buildRunner))
        XCTAssertFalse(index.editorModules.contains(.pokemon))
        XCTAssertEqual(count(for: .species, in: catalog), 1)
        XCTAssertEqual(count(for: .moves, in: catalog), 1)
        XCTAssertEqual(count(for: .items, in: catalog), 1)
        XCTAssertEqual(count(for: .trainers, in: catalog), 1)
        XCTAssertEqual(count(for: .encounters, in: catalog), 1)
        XCTAssertEqual(count(for: .text, in: catalog), 1)
        XCTAssertEqual(count(for: .scripts, in: catalog), 1)
        XCTAssertEqual(count(for: .maps, in: catalog), 3)
        let personalNARC = try XCTUnwrap(catalog.records.first { $0.relativePath == "res/prebuilt/poketool/personal/personal.narc" })
        XCTAssertEqual(personalNARC.domain, .personal)
        XCTAssertEqual(personalNARC.containerSummary?.kind, .narc)
        XCTAssertEqual(personalNARC.containerSummary?.memberCount, 2)
        XCTAssertEqual(personalNARC.containerSummary?.sampleMemberPaths, ["first.bin", "second.bin"])
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "res/pokemon/abra/data.json" && $0.format == .json && $0.recordCount == 1 })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "res/items/items.csv" && $0.format == .csv && $0.recordCount == 1 })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "platinum.us/filesys.csv" && $0.role == .nitroFSManifest })
        let routeMap = try XCTUnwrap(catalog.records.first { $0.relativePath == "res/field/maps/route201/map.bin" })
        XCTAssertEqual(routeMap.readiness?.status, .ready)
        XCTAssertTrue(routeMap.relatedRecords.contains { $0.recordID == "maps:res/field/matrices/route201.json" && $0.label == "Matrix" })
        XCTAssertTrue(routeMap.relatedRecords.contains { $0.recordID == "scripts:res/field/scripts/route201.s" && $0.label == "Script resource" })
        XCTAssertTrue(routeMap.facts.contains { $0.label == "Related Rows" && $0.value == "3" })
        XCTAssertTrue(routeMap.diagnostics.contains { $0.code == "NDS_DATA_READINESS_PREVIEW_ONLY" })
        let filesys = try XCTUnwrap(catalog.records.first { $0.relativePath == "platinum.us/filesys.csv" })
        XCTAssertEqual(filesys.readiness?.status, .partial)
        XCTAssertTrue(filesys.readiness?.blockedActions.contains("ROM rebuild") == true)
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "NDS_DATA_CATALOG_READ_ONLY" })
    }

    func testHeartGoldCatalogIncludesNARCPlaceholderAndSourceAnchors() throws {
        let root = try makeRoot(name: "pokeheartgold", configure: makeHeartGoldFixture)

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        XCTAssertEqual(catalog.profile, .pokeheartgold)
        XCTAssertEqual(catalog.family, .heartGoldSoulSilver)
        let movesNARC = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/poketool/waza/waza_tbl.narc" })
        XCTAssertEqual(movesNARC.domain, .moves)
        XCTAssertEqual(movesNARC.format, .narc)
        XCTAssertEqual(movesNARC.role, .binaryContainer)
        XCTAssertEqual(movesNARC.recordCount, 2)
        XCTAssertEqual(movesNARC.containerSummary?.namedMemberCount, 2)
        let malformedNARC = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/data/broken.narc" })
        XCTAssertTrue(malformedNARC.diagnostics.contains { $0.code == "NARC_REQUIRED_BLOCK_MISSING" })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "src/data/map_headers.h" && $0.domain == .maps && $0.format == .cHeader })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "files/fielddata/eventdata/zone_event/zone_001.json" && $0.domain == .scripts })
        XCTAssertTrue(catalog.summary.nitroFSBackedCount > 0)
        XCTAssertTrue(catalog.isReadOnly)
    }

    func testDiamondCatalogKeepsCSourceAnchorsConservative() throws {
        let root = try makeRoot(name: "pokediamond", configure: makeDiamondFixture)

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        XCTAssertEqual(catalog.profile, .pokediamond)
        XCTAssertEqual(catalog.family, .diamondPearl)
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "arm9/src/pokemon.c" && $0.domain == .species && $0.format == .cSource })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "arm9/src/script.c" && $0.domain == .scripts && $0.format == .cSource })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "files/fielddata/mapmatrix/matrix.bin" && $0.domain == .maps && $0.format == .binary })
        let unpacked = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/script/scr_seq_release" })
        XCTAssertEqual(unpacked.domain, .scripts)
        XCTAssertEqual(unpacked.containerSummary?.kind, .unpackedArchiveDirectory)
        XCTAssertEqual(unpacked.containerSummary?.memberCount, 2)
        XCTAssertEqual(unpacked.containerSummary?.unnamedMemberCount, 2)
        XCTAssertEqual(unpacked.readiness?.status, .blocked)
        XCTAssertTrue(unpacked.diagnostics.contains { $0.code == "NDS_DATA_READINESS_WRITE_BLOCKED" })
        XCTAssertTrue(catalog.isReadOnly)
    }

    func testPMDSkyReportsSpinOffInventoryOnly() throws {
        let root = try makeRoot(name: "pmd-sky", configure: makePMDSkyFixture)

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        XCTAssertEqual(catalog.profile, .pmdSky)
        XCTAssertEqual(catalog.family, .ndsUnknown)
        XCTAssertTrue(catalog.records.allSatisfy { $0.domain == .resources })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "files/MESSAGE/text_us.str" })
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "NDS_DATA_CATALOG_SPINOFF_DEFERRED" })
        XCTAssertTrue(catalog.isReadOnly)
    }

    func testBinaryNDSROMSurfacesReadOnlyNARCSummaries() throws {
        let temp = try NDSDataCatalogTemporaryDirectory()
        temporaryDirectories.append(temp)
        let rom = temp.url.appendingPathComponent("diamond.nds")
        try syntheticNDSROM().write(to: rom)

        let catalog = try NDSDataCatalogBuilder.build(path: rom.path)

        XCTAssertEqual(catalog.profile, .ndsROM)
        XCTAssertEqual(catalog.family, .diamondPearl)
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "sub/child.narc" && $0.domain == .resources })
        let narc = try XCTUnwrap(catalog.records.first { $0.relativePath == "sub/child.narc" })
        XCTAssertEqual(narc.containerSummary?.kind, .narc)
        XCTAssertEqual(narc.containerSummary?.memberCount, 2)
        XCTAssertEqual(narc.preview, "first.bin, second.bin")
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "NDS_DATA_CATALOG_BINARY_SUMMARY_READ_ONLY" })
        XCTAssertTrue(catalog.isReadOnly)
    }

    func testResourceRegistrySurfacesCatalogRowsForNDSSourceRoots() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)

        let entry = GenIIIResourceRegistry.resourceIndex(path: root.path)
        let assetCatalog = GenIIIAssetCatalogBuilder.build(path: root.path)

        XCTAssertEqual(entry.platform, .ndsSource)
        XCTAssertEqual(entry.writePolicy, .readOnly)
        XCTAssertTrue(entry.items.contains { $0.category == "NDS Data species" && $0.path == "res/pokemon/abra/data.json" })
        XCTAssertTrue(entry.items.contains { $0.category == "NDS Data items" && $0.path == "res/items/items.csv" })
        XCTAssertTrue(entry.items.contains { $0.category == "NDS Data personal" && $0.path == "res/prebuilt/poketool/personal/personal.narc" && $0.kind == "narc (2 members)" && $0.uncompressedSize == 2 })
        let mapItem = try XCTUnwrap(entry.items.first { $0.category == "NDS Data maps" && $0.path == "res/field/maps/route201/map.bin" })
        XCTAssertTrue(mapItem.facts.contains { $0.label == "Readiness" && $0.value == "ready" })
        XCTAssertTrue(mapItem.facts.contains { $0.label == "Related Domains" && $0.value.contains("scripts") })
        XCTAssertTrue(assetCatalog.assets.contains { $0.relativePath == "res/pokemon/abra/data.json" && $0.category == .species })
        XCTAssertTrue(assetCatalog.assets.contains { $0.relativePath == "res/items/items.csv" && $0.category == .items })
        let mapAsset = try XCTUnwrap(assetCatalog.assets.first { $0.relativePath == "res/field/maps/route201/map.bin" })
        XCTAssertTrue(mapAsset.facts.contains { $0.label == "Readiness" && $0.value == "ready" })
        XCTAssertTrue(mapAsset.tags.contains("ndsSource"))
    }

    func testNDSDataMutationPlanAppliesSourceBackedJSONRecordWithBackup() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let draft = NDSDataEditDraft(recordID: "species:res/pokemon/abra/data.json", editedText: "{\"base_hp\":26}\n")

        let plan = NDSDataMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertTrue(plan.diagnostics.allSatisfy { $0.severity != .error }, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(plan.changes.count, 1)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_GENERATED_OUTPUTS_STALE" })
        XCTAssertTrue(plan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("res/pokemon/abra/data.json"), encoding: .utf8),
            "{\"base_hp\":26}\n"
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))
    }

    func testNDSDataSemanticEditorPlansFieldLevelJSONEditsThroughMutationGate() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "species:res/pokemon/abra/data.json")
        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(snapshot.fields.first?.key, "base_hp")
        XCTAssertEqual(snapshot.fields.first?.value, "25")

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "species:res/pokemon/abra/data.json",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "base_hp", value: "28")]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(semanticPlan.textDraft.editedText, "{\"base_hp\":28}\n")
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("res/pokemon/abra/data.json"), encoding: .utf8),
            "{\"base_hp\":28}\n"
        )
    }

    func testNDSDataSemanticEditorPlansTrainerScalarEditsOnlyForTrainerDataJSON() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        try write("{\"cell_animation\":1}\n", to: root.appendingPathComponent("res/trainers/classes/youngster.json"))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "trainers:res/trainers/data/youngster.json")
        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(snapshot.fields.contains { $0.key == "name" && $0.value == "Youngster" && $0.valueKind == .string })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "class" && $0.value == "TRAINER_CLASS_YOUNGSTER" && $0.valueKind == .string })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "double_battle" && $0.value == "false" && $0.valueKind == .bool })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "party" })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "items" })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "messages" })

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "trainers:res/trainers/data/youngster.json",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "name", value: "Youngster Ben"),
                    NDSDataSemanticFieldEdit(key: "double_battle", value: "true")
                ]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"name\": \"Youngster Ben\""))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"double_battle\": true"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"party\": [{\"species\":\"STARLY\",\"level\":5}]"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"messages\": [\"I like shorts!\"]"))
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("res/trainers/data/youngster.json"), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"name\": \"Youngster Ben\""))
        XCTAssertTrue(updated.contains("\"double_battle\": true"))
        XCTAssertTrue(updated.contains("\"party\": [{\"species\":\"STARLY\",\"level\":5}]"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let classSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "trainers:res/trainers/classes/youngster.json")
        XCTAssertFalse(classSnapshot.canEdit)
        XCTAssertTrue(classSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_TRAINER_PATH_BLOCKED" })
    }

    func testNDSDataSemanticEditorKeepsNonPlatinumAndContainerRowsBlocked() throws {
        let platinum = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let platinumCatalog = try NDSDataCatalogBuilder.build(path: platinum.path)
        let narcSnapshot = NDSDataSemanticEditor.snapshot(catalog: platinumCatalog, recordID: "personal:res/prebuilt/poketool/personal/personal.narc")
        XCTAssertFalse(narcSnapshot.canEdit)
        XCTAssertTrue(narcSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let heartGold = try makeRoot(name: "pokeheartgold", configure: makeHeartGoldFixture)
        let heartGoldCatalog = try NDSDataCatalogBuilder.build(path: heartGold.path)
        let heartGoldSnapshot = NDSDataSemanticEditor.snapshot(catalog: heartGoldCatalog, recordID: "trainers:files/poketool/trainer/trainers.json")
        XCTAssertFalse(heartGoldSnapshot.canEdit)
        XCTAssertTrue(heartGoldSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_PROFILE_BLOCKED" })

        let pmd = try makeRoot(name: "pmd-sky", configure: makePMDSkyFixture)
        let pmdCatalog = try NDSDataCatalogBuilder.build(path: pmd.path)
        let pmdSnapshot = NDSDataSemanticEditor.snapshot(catalog: pmdCatalog, recordID: "resources:files/MESSAGE/text_us.str")
        XCTAssertFalse(pmdSnapshot.canEdit)
        XCTAssertTrue(pmdSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_PROFILE_BLOCKED" })
    }

    func testNDSDataMutationPlanBlocksHashMismatchBeforeApply() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let draft = NDSDataEditDraft(recordID: "species:res/pokemon/abra/data.json", editedText: "{\"base_hp\":26}\n")
        let plan = NDSDataMutationPlanner.plan(catalog: catalog, draft: draft)
        try "{\"base_hp\":27}\n".write(to: root.appendingPathComponent("res/pokemon/abra/data.json"), atomically: true, encoding: .utf8)

        let applyability = plan.validateApplyability()

        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(applyability.diagnostics.contains { $0.code == "NDS_DATA_APPLY_SOURCE_HASH_CHANGED" })
    }

    func testNDSDataMutationPlanBlocksInvalidJSONDraft() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let draft = NDSDataEditDraft(recordID: "species:res/pokemon/abra/data.json", editedText: "{\"base_hp\":")

        let plan = NDSDataMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_JSON_INVALID" })
        XCTAssertFalse(plan.validateApplyability().isApplyable)
    }

    func testNDSDataMutationPlanKeepsUnsupportedRowsReadOnly() throws {
        let platinum = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let platinumCatalog = try NDSDataCatalogBuilder.build(path: platinum.path)
        let narcDraft = NDSDataEditDraft(recordID: "personal:res/prebuilt/poketool/personal/personal.narc", editedText: "ignored")

        let narcPlan = NDSDataMutationPlanner.plan(catalog: platinumCatalog, draft: narcDraft)

        XCTAssertTrue(narcPlan.changes.isEmpty)
        XCTAssertTrue(narcPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_ROLE_BLOCKED" })
        XCTAssertTrue(narcPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_FORMAT_BLOCKED" })
        XCTAssertTrue(narcPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_CONTAINER_BLOCKED" })

        let romTemp = try NDSDataCatalogTemporaryDirectory()
        temporaryDirectories.append(romTemp)
        let rom = romTemp.url.appendingPathComponent("diamond.nds")
        try syntheticNDSROM().write(to: rom)
        let romCatalog = try NDSDataCatalogBuilder.build(path: rom.path)
        let romPlan = NDSDataMutationPlanner.plan(
            catalog: romCatalog,
            draft: NDSDataEditDraft(recordID: "resources:sub/child.narc", editedText: "ignored")
        )

        XCTAssertTrue(romPlan.changes.isEmpty)
        XCTAssertTrue(romPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_BINARY_ROM_BLOCKED" })

        let pmd = try makeRoot(name: "pmd-sky", configure: makePMDSkyFixture)
        let pmdCatalog = try NDSDataCatalogBuilder.build(path: pmd.path)
        let pmdPlan = NDSDataMutationPlanner.plan(
            catalog: pmdCatalog,
            draft: NDSDataEditDraft(recordID: "resources:files/MESSAGE/text_us.str", editedText: "hello again\n")
        )

        XCTAssertTrue(pmdPlan.changes.isEmpty)
        XCTAssertTrue(pmdPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_SPINOFF_BLOCKED" })

        let generatedPlan = NDSDataMutationPlanner.plan(
            catalog: platinumCatalog,
            draft: NDSDataEditDraft(recordID: "resources:generated/species.txt", editedText: "SPECIES_MEW\n")
        )
        XCTAssertTrue(generatedPlan.changes.isEmpty)
        XCTAssertTrue(generatedPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_ROLE_BLOCKED" })

        try Data([0xff, 0xfe]).write(to: platinum.appendingPathComponent("res/items/items.csv"))
        let nonUTF8Catalog = try NDSDataCatalogBuilder.build(path: platinum.path)
        let nonUTF8Plan = NDSDataMutationPlanner.plan(
            catalog: nonUTF8Catalog,
            draft: NDSDataEditDraft(recordID: "items:res/items/items.csv", editedText: "id,name\n1,POTION\n")
        )
        XCTAssertTrue(nonUTF8Plan.changes.isEmpty)
        XCTAssertTrue(nonUTF8Plan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_SOURCE_NOT_UTF8" })
    }

    func testNDSDataMutationPlanBlocksReferenceRoots() throws {
        let root = try makeRoot(name: "references/pokeplatinum", configure: makePlatinumFixture)
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let plan = NDSDataMutationPlanner.plan(
            catalog: catalog,
            draft: NDSDataEditDraft(recordID: "species:res/pokemon/abra/data.json", editedText: "{\"base_hp\":26}\n")
        )

        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_REFERENCE_BLOCKED" })
    }

    private func makeRoot(name: String, configure: (URL) throws -> Void) throws -> URL {
        let temp = try NDSDataCatalogTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent(name)
        try makeDirectory(root)
        try configure(root)
        return root
    }

    private func makePlatinumFixture(root: URL) throws {
        try write("rom: build/pokeplatinum.us.nds\n", to: root.appendingPathComponent("Makefile"))
        try write("project('pokeplatinum')\n", to: root.appendingPathComponent("meson.build"))
        try write("path,sha1\n", to: root.appendingPathComponent("platinum.us/filesys.csv"))
        try write("cccccccccccccccccccccccccccccccccccccccc  pokeplatinum.us.nds\n", to: root.appendingPathComponent("platinum.us/rom_rev1.sha1"))
        try makeDirectory(root.appendingPathComponent("src"))
        try makeDirectory(root.appendingPathComponent("asm"))
        try write("{\"base_hp\":25}\n", to: root.appendingPathComponent("res/pokemon/abra/data.json"))
        try write("{\"power\":40}\n", to: root.appendingPathComponent("res/battle/moves/tackle.json"))
        try write("id,name\n1,POTION\n", to: root.appendingPathComponent("res/items/items.csv"))
        try write(
            """
            {"name": "Youngster", "class": "TRAINER_CLASS_YOUNGSTER", "double_battle": false, "party": [{"species":"STARLY","level":5}], "items": ["POTION"], "messages": ["I like shorts!"]}

            """,
            to: root.appendingPathComponent("res/trainers/data/youngster.json")
        )
        try write("[{\"species\":\"BIDOOF\"}]\n", to: root.appendingPathComponent("res/field/encounters/route201.json"))
        try write("{\"message\":\"hello\"}\n", to: root.appendingPathComponent("res/text/story.json"))
        try write("scrcmd_end\n", to: root.appendingPathComponent("res/field/scripts/route201.s"))
        try write("{\"event\":1}\n", to: root.appendingPathComponent("res/field/events/route201.json"))
        try write(Data([0x01, 0x02]), to: root.appendingPathComponent("res/field/maps/route201/map.bin"))
        try write("{\"matrix\":1}\n", to: root.appendingPathComponent("res/field/matrices/route201.json"))
        try write(makeTestNARC(), to: root.appendingPathComponent("res/prebuilt/poketool/personal/personal.narc"))
        try write("SPECIES_ABRA\n", to: root.appendingPathComponent("generated/species.txt"))
    }

    private func makeHeartGoldFixture(root: URL) throws {
        try write("GAME_VERSION ?= HEARTGOLD\nGAME_CODE := IPK\n", to: root.appendingPathComponent("config.mk"))
        try write("ROM := $(BUILD_DIR)/poke$(buildname).nds\n", to: root.appendingPathComponent("Makefile"))
        try write("HostRoot files/\n", to: root.appendingPathComponent("rom.rsf"))
        try write("filesystem: $(NITROFS_FILES)\n", to: root.appendingPathComponent("filesystem.mk"))
        try write("dddddddddddddddddddddddddddddddddddddddd  pokeheartgold.us.nds\n", to: root.appendingPathComponent("heartgold.us/rom.sha1"))
        try makeDirectory(root.appendingPathComponent("soulsilver.us"))
        try makeDirectory(root.appendingPathComponent("files"))
        try makeDirectory(root.appendingPathComponent("src"))
        try makeDirectory(root.appendingPathComponent("asm"))
        try write("{\"species\":\"CHIKORITA\"}\n", to: root.appendingPathComponent("files/poketool/personal/personal.json"))
        try write(makeTestNARC(), to: root.appendingPathComponent("files/poketool/waza/waza_tbl.narc"))
        try write(Data("NARC".utf8) + Data(repeating: 0, count: 12), to: root.appendingPathComponent("files/data/broken.narc"))
        try write("id,name\n1,POTION\n", to: root.appendingPathComponent("files/itemtool/itemdata/item_data.csv"))
        try write("[{\"id\":1}]\n", to: root.appendingPathComponent("files/poketool/trainer/trainers.json"))
        try write("[{\"slot\":1}]\n", to: root.appendingPathComponent("files/fielddata/encountdata/gs_enc_data.json"))
        try write("{\"zone\":1}\n", to: root.appendingPathComponent("files/fielddata/eventdata/zone_event/zone_001.json"))
        try write("message\n", to: root.appendingPathComponent("files/msgdata/msg/0001.txt"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/fielddata/script/scr_seq/0001.bin"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/fielddata/mapmatrix/0001.bin"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/fielddata/maptable/map.bin"))
        try write("#define MAP_NEW_BARK 1\n", to: root.appendingPathComponent("src/data/map_headers.h"))
    }

    private func makeDiamondFixture(root: URL) throws {
        try write("GAME_VERSION ?= DIAMOND\nGAME_CODE := ADA\n", to: root.appendingPathComponent("config.mk"))
        try write("ROM := $(BUILD_DIR)/$(TARGET).nds\n", to: root.appendingPathComponent("Makefile"))
        try write("HostRoot files/\n", to: root.appendingPathComponent("rom.rsf"))
        try write("filesystem: $(HOSTFS_FILES)\n", to: root.appendingPathComponent("filesystem.mk"))
        try write("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  build/diamond.us/pokediamond.us.nds\n", to: root.appendingPathComponent("pokediamond.us.sha1"))
        try makeDirectory(root.appendingPathComponent("files"))
        try makeDirectory(root.appendingPathComponent("arm9"))
        try makeDirectory(root.appendingPathComponent("arm7"))
        try write("void Pokemon_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/pokemon.c"))
        try write("void Waza_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/waza.c"))
        try write("void Item_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/itemtool.c"))
        try write("void Trainer_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/trainer_data.c"))
        try write("void Encounter_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/encounter.c"))
        try write("void MapHeader_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/map_header.c"))
        try write("void Script_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/script.c"))
        try write("{\"personal\":1}\n", to: root.appendingPathComponent("files/poketool/personal/personal.json"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/fielddata/mapmatrix/matrix.bin"))
        try write("ignored\n", to: root.appendingPathComponent("files/fielddata/script/scr_seq_release/.knarcignore"))
        try write(Data([0x01, 0x02]), to: root.appendingPathComponent("files/fielddata/script/scr_seq_release/narc_0000.bin"))
        try write(Data([0x03]), to: root.appendingPathComponent("files/fielddata/script/scr_seq_release/narc_0001.bin"))
    }

    private func makePMDSkyFixture(root: URL) throws {
        try write("GAME_CODE := C2S\nGAME_LANGUAGE ?= NORTH_AMERICA\n", to: root.appendingPathComponent("config.mk"))
        try write("ROM := $(BUILD_DIR)/$(buildname).nds\n", to: root.appendingPathComponent("Makefile"))
        try write("HostRoot files/\n", to: root.appendingPathComponent("rom.rsf"))
        try write("NITROFS_FILES_FILE := nitrofs_files.txt\n", to: root.appendingPathComponent("filesystem.mk"))
        try write("files/MESSAGE/text_us.str\n", to: root.appendingPathComponent("nitrofs_files.txt"))
        try write("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee  pmdsky.us.nds\n", to: root.appendingPathComponent("pmdsky.us/rom.sha1"))
        try makeDirectory(root.appendingPathComponent("files"))
        try makeDirectory(root.appendingPathComponent("src"))
        try makeDirectory(root.appendingPathComponent("asm"))
        try write("hello\n", to: root.appendingPathComponent("files/MESSAGE/text_us.str"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/MONSTER/monster.md"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/BALANCE/item.dat"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/TABLEDAT/table.dat"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/DUNGEON/dungeon.bin"))
    }

    private func syntheticNDSROM() -> Data {
        var data = Data(repeating: 0, count: 0x900)
        writeASCII("POKEMON D", into: &data, at: 0x00, length: 12)
        writeASCII("ADAE", into: &data, at: 0x0C, length: 4)
        writeASCII("01", into: &data, at: 0x10, length: 2)
        data[0x14] = 0x09
        writeUInt32LE(0x200, into: &data, at: 0x20)
        writeUInt32LE(0x20, into: &data, at: 0x2C)
        writeUInt32LE(0x220, into: &data, at: 0x30)
        writeUInt32LE(0x20, into: &data, at: 0x3C)

        let fnt = syntheticFNT()
        writeUInt32LE(0x300, into: &data, at: 0x40)
        writeUInt32LE(UInt32(fnt.count), into: &data, at: 0x44)
        data.replaceSubrange(0x300..<(0x300 + fnt.count), with: fnt)

        let narc = makeTestNARC()
        var fat = Data()
        appendUInt32LE(0x400, to: &fat)
        appendUInt32LE(0x404, to: &fat)
        appendUInt32LE(0x500, to: &fat)
        appendUInt32LE(UInt32(0x500 + narc.count), to: &fat)
        writeUInt32LE(0x380, into: &data, at: 0x48)
        writeUInt32LE(UInt32(fat.count), into: &data, at: 0x4C)
        data.replaceSubrange(0x380..<(0x380 + fat.count), with: fat)
        writeUInt32LE(0x700, into: &data, at: 0x68)
        writeUInt16LE(0x5678, into: &data, at: 0x15E)

        data.replaceSubrange(0x400..<0x404, with: Data("ROOT".utf8))
        data.replaceSubrange(0x500..<(0x500 + narc.count), with: narc)
        return data
    }

    private func syntheticFNT() -> Data {
        var rootEntries = Data()
        appendFNTFile("root.bin", to: &rootEntries)
        appendFNTDirectory("sub", directoryID: 0xF001, to: &rootEntries)
        rootEntries.append(0)

        var childEntries = Data()
        appendFNTFile("child.narc", to: &childEntries)
        childEntries.append(0)

        var fnt = Data()
        appendUInt32LE(16, to: &fnt)
        appendUInt16LE(0, to: &fnt)
        appendUInt16LE(2, to: &fnt)
        appendUInt32LE(UInt32(16 + rootEntries.count), to: &fnt)
        appendUInt16LE(1, to: &fnt)
        appendUInt16LE(0xF000, to: &fnt)
        fnt.append(rootEntries)
        fnt.append(childEntries)
        return fnt
    }

    private func makeTestNARC() -> Data {
        let payload = Data([0xAA, 0xBB, 0xCC, 0xDD, 0x11, 0x22, 0x33])
        var fat = Data("BTAF".utf8)
        appendUInt32LE(28, to: &fat)
        appendUInt16LE(2, to: &fat)
        appendUInt16LE(0, to: &fat)
        appendUInt32LE(0, to: &fat)
        appendUInt32LE(4, to: &fat)
        appendUInt32LE(4, to: &fat)
        appendUInt32LE(UInt32(payload.count), to: &fat)

        var namesData = Data()
        appendUInt32LE(8, to: &namesData)
        appendUInt16LE(0, to: &namesData)
        appendUInt16LE(1, to: &namesData)
        appendFNTFile("first.bin", to: &namesData)
        appendFNTFile("second.bin", to: &namesData)
        namesData.append(0)
        var fnt = Data("BTNF".utf8)
        appendUInt32LE(UInt32(8 + namesData.count), to: &fnt)
        fnt.append(namesData)

        var image = Data("GMIF".utf8)
        appendUInt32LE(UInt32(8 + payload.count), to: &image)
        image.append(payload)

        let fileSize = UInt32(16 + fat.count + fnt.count + image.count)
        var header = Data("NARC".utf8)
        appendUInt16LE(0xFFFE, to: &header)
        appendUInt16LE(0x0100, to: &header)
        appendUInt32LE(fileSize, to: &header)
        appendUInt16LE(0x10, to: &header)
        appendUInt16LE(3, to: &header)
        return header + fat + fnt + image
    }

    private func count(for domain: NDSDataDomain, in catalog: ProjectNDSDataCatalog) -> Int {
        catalog.summary.domainCounts.first { $0.domain == domain }?.count ?? 0
    }

    private func makeDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private func write(_ text: String, to url: URL) throws {
        try makeDirectory(url.deletingLastPathComponent())
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func write(_ data: Data, to url: URL) throws {
        try makeDirectory(url.deletingLastPathComponent())
        try data.write(to: url)
    }

    private func appendFNTFile(_ name: String, to data: inout Data) {
        data.append(UInt8(name.utf8.count))
        data.append(Data(name.utf8))
    }

    private func appendFNTDirectory(_ name: String, directoryID: UInt16, to data: inout Data) {
        data.append(UInt8(0x80 | name.utf8.count))
        data.append(Data(name.utf8))
        appendUInt16LE(directoryID, to: &data)
    }

    private func writeASCII(_ string: String, into data: inout Data, at offset: Int, length: Int) {
        let bytes = Array(string.utf8.prefix(length))
        data.replaceSubrange(offset..<(offset + bytes.count), with: bytes)
    }

    private func writeUInt16LE(_ value: UInt16, into data: inout Data, at offset: Int) {
        data[offset] = UInt8(value & 0xff)
        data[offset + 1] = UInt8((value >> 8) & 0xff)
    }

    private func writeUInt32LE(_ value: UInt32, into data: inout Data, at offset: Int) {
        data[offset] = UInt8(value & 0xff)
        data[offset + 1] = UInt8((value >> 8) & 0xff)
        data[offset + 2] = UInt8((value >> 16) & 0xff)
        data[offset + 3] = UInt8((value >> 24) & 0xff)
    }

    private func appendUInt16LE(_ value: UInt16, to data: inout Data) {
        data.append(UInt8(value & 0xff))
        data.append(UInt8((value >> 8) & 0xff))
    }

    private func appendUInt32LE(_ value: UInt32, to data: inout Data) {
        data.append(UInt8(value & 0xff))
        data.append(UInt8((value >> 8) & 0xff))
        data.append(UInt8((value >> 16) & 0xff))
        data.append(UInt8((value >> 24) & 0xff))
    }
}

private final class NDSDataCatalogTemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackCoreNDSDataCatalogTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
