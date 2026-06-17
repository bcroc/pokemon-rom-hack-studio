import PokemonHackCore
import XCTest

final class ProjectWorkspaceStoreTests: XCTestCase {
    private var temporaryDirectories: [ProjectWorkspaceTemporaryDirectory] = []

    override func tearDown() {
        temporaryDirectories.removeAll()
        super.tearDown()
    }

    @MainActor
    func testDataDraftsSaveReloadPreviewApplyAndClear() async throws {
        let root = try makeUnifiedDataProject()
        let firstStore = try makeStore(workspaceRoot: root.deletingLastPathComponent())

        firstStore.openProject(path: root.path)
        firstStore.loadSelectedSpeciesCatalogIfNeeded()
        try await waitForSelectedSpeciesCatalog(firstStore)
        firstStore.loadSelectedTrainerCatalogIfNeeded()
        try await waitForSelectedTrainerCatalog(firstStore)
        firstStore.loadSelectedMoveCatalogIfNeeded()
        try await waitForSelectedMoveCatalog(firstStore)
        firstStore.loadSelectedItemCatalogIfNeeded()
        try await waitForSelectedItemCatalog(firstStore)

        firstStore.requestSpeciesSelection("SPECIES_TREECKO")
        var speciesDraft = try XCTUnwrap(firstStore.selectedSpeciesDraft)
        speciesDraft.baseStats.hp = 44
        firstStore.updateSelectedSpeciesDraft(speciesDraft)

        firstStore.requestTrainerSelection("TRAINER_BOSS")
        var trainerDraft = try XCTUnwrap(firstStore.selectedTrainerDraft)
        trainerDraft.trainerName = "SAVED"
        firstStore.updateSelectedTrainerDraft(trainerDraft)

        firstStore.requestMoveSelection("MOVE_TACKLE")
        var moveDraft = try XCTUnwrap(firstStore.selectedMoveDraft)
        moveDraft.power = 55
        firstStore.updateSelectedMoveDraft(moveDraft)

        firstStore.requestItemSelection("ITEM_POTION")
        var itemDraft = try XCTUnwrap(firstStore.selectedItemDraft)
        itemDraft.price = "400"
        firstStore.updateSelectedItemDraft(itemDraft)

        XCTAssertEqual(firstStore.currentDraftCount, 4)
        XCTAssertTrue(firstStore.saveDraftsNow())
        XCTAssertEqual(firstStore.savedDraftCount, 4)

        let reloadedStore = try makeStore(workspaceRoot: root.deletingLastPathComponent())
        reloadedStore.openProject(path: root.path)
        reloadedStore.loadSelectedSpeciesCatalogIfNeeded()
        try await waitForSelectedSpeciesCatalog(reloadedStore)
        reloadedStore.loadSelectedTrainerCatalogIfNeeded()
        try await waitForSelectedTrainerCatalog(reloadedStore)
        reloadedStore.loadSelectedMoveCatalogIfNeeded()
        try await waitForSelectedMoveCatalog(reloadedStore)
        reloadedStore.loadSelectedItemCatalogIfNeeded()
        try await waitForSelectedItemCatalog(reloadedStore)

        reloadedStore.requestSpeciesSelection("SPECIES_TREECKO")
        XCTAssertTrue(reloadedStore.selectedSpeciesIsDirty)
        reloadedStore.previewSelectedSpeciesMutationPlan()
        XCTAssertTrue(reloadedStore.canApplySelectedSpeciesMutationPlan)
        reloadedStore.applySelectedSpeciesMutationPlan()
        XCTAssertFalse(reloadedStore.selectedSpeciesIsDirty)
        XCTAssertEqual(reloadedStore.selectedSpeciesDetail?.baseStats.hp, 44)

        reloadedStore.requestTrainerSelection("TRAINER_BOSS")
        XCTAssertTrue(reloadedStore.selectedTrainerIsDirty)
        reloadedStore.previewSelectedTrainerMutationPlan()
        XCTAssertTrue(reloadedStore.canApplySelectedTrainerMutationPlan)
        reloadedStore.applySelectedTrainerMutationPlan()
        XCTAssertFalse(reloadedStore.selectedTrainerIsDirty)
        XCTAssertEqual(reloadedStore.selectedTrainerDetail?.trainerName, "SAVED")

        reloadedStore.requestMoveSelection("MOVE_TACKLE")
        XCTAssertTrue(reloadedStore.selectedMoveIsDirty)
        reloadedStore.previewSelectedMoveMutationPlan()
        XCTAssertTrue(reloadedStore.canApplySelectedMoveMutationPlan)
        reloadedStore.applySelectedMoveMutationPlan()
        XCTAssertFalse(reloadedStore.selectedMoveIsDirty)
        XCTAssertEqual(reloadedStore.selectedCoreMoveDetail?.facts.first { $0.label == "power" }?.value, "55")

        reloadedStore.requestItemSelection("ITEM_POTION")
        XCTAssertTrue(reloadedStore.selectedItemIsDirty)
        reloadedStore.previewSelectedItemMutationPlan()
        XCTAssertTrue(reloadedStore.canApplySelectedItemMutationPlan)
        reloadedStore.applySelectedItemMutationPlan()
        XCTAssertFalse(reloadedStore.selectedItemIsDirty)
        XCTAssertEqual(reloadedStore.selectedCoreItemDetail?.price, "400")

        XCTAssertTrue(reloadedStore.saveDraftsNow())
        XCTAssertEqual(reloadedStore.savedDraftCount, 0)
        XCTAssertEqual(try ProjectWorkspacePersistence.loadAutosave(root: root)?.drafts.counts.total, 0)
    }

    @MainActor
    func testMapDraftSaveReloadPreviewAndDiscard() async throws {
        let root = try makeVisualProject()
        let firstStore = try makeStore(workspaceRoot: root.deletingLastPathComponent())

        firstStore.openProject(path: root.path)
        firstStore.selection = .maps
        firstStore.loadSelectedModuleDataIfNeeded()
        try await waitForSelectedMapVisual(firstStore, mapID: "MAP_ROUTE1")

        firstStore.mapEditorSession.selectBrush(rawValue: 0x22)
        XCTAssertTrue(firstStore.mapEditorSession.paintMapCell(x: 1, y: 0))
        XCTAssertEqual(firstStore.currentDraftCount, 1)
        XCTAssertTrue(firstStore.saveDraftsNow())

        let reloadedStore = try makeStore(workspaceRoot: root.deletingLastPathComponent())
        reloadedStore.openProject(path: root.path)
        reloadedStore.loadSelectedModuleDataIfNeeded()
        try await waitForSelectedMapVisual(reloadedStore, mapID: "MAP_ROUTE1")

        XCTAssertTrue(reloadedStore.mapEditorSession.isDirty)
        XCTAssertEqual(reloadedStore.mapEditorSession.stagedMapBlockdataValues, [1, 0x22, 3, 4])
        XCTAssertNotNil(reloadedStore.mapEditorSession.previewSelectedMapMutationPlan())

        XCTAssertTrue(reloadedStore.discardSavedDrafts())
        XCTAssertFalse(reloadedStore.mapEditorSession.isDirty)
        XCTAssertEqual(reloadedStore.currentDraftCount, 0)
        XCTAssertNil(try ProjectWorkspacePersistence.loadAutosave(root: root)?.drafts.mapDrafts.first)
    }

    @MainActor
    func testGraphicsDraftSaveReloadPreviewApplyAndClear() async throws {
        let root = try makeVisualProject()
        let firstStore = try makeStore(workspaceRoot: root.deletingLastPathComponent())

        firstStore.openProject(path: root.path)
        firstStore.selection = .graphics
        firstStore.loadSelectedModuleDataIfNeeded()
        try await waitForSelectedGraphicsReport(firstStore)
        try selectGeneralMetatilesRow(firstStore)
        firstStore.stageSelectedGraphicsOperation(
            .metatileTile(
                path: "data/tilesets/primary/general/metatiles.bin",
                metatileLocalID: 0,
                tileEntryIndex: 0,
                rawTileValue: 0x0044
            )
        )

        XCTAssertEqual(firstStore.currentDraftCounts.graphics, 1)
        XCTAssertTrue(firstStore.selectedGraphicsIsDirty)
        XCTAssertTrue(firstStore.canPreviewSelectedGraphicsMutationPlan)
        XCTAssertEqual(firstStore.toolbarMutationState.target, .graphics)
        XCTAssertTrue(firstStore.saveDraftsNow())
        XCTAssertEqual(firstStore.savedDraftCount, 1)

        let reloadedStore = try makeStore(workspaceRoot: root.deletingLastPathComponent())
        reloadedStore.openProject(path: root.path)
        reloadedStore.selection = .graphics
        reloadedStore.loadSelectedModuleDataIfNeeded()
        try await waitForSelectedGraphicsReport(reloadedStore)
        try selectGeneralMetatilesRow(reloadedStore)

        XCTAssertTrue(reloadedStore.selectedGraphicsIsDirty)
        reloadedStore.previewSelectedGraphicsMutationPlan()
        XCTAssertTrue(reloadedStore.canApplySelectedGraphicsMutationPlan)
        reloadedStore.applySelectedGraphicsMutationPlan()
        XCTAssertFalse(reloadedStore.selectedGraphicsIsDirty)

        let metatiles = try Data(contentsOf: root.appendingPathComponent("data/tilesets/primary/general/metatiles.bin"))
        XCTAssertEqual(metatiles[0], 0x44)
        XCTAssertEqual(metatiles[1], 0x00)
        XCTAssertTrue(reloadedStore.saveDraftsNow())
        XCTAssertEqual(reloadedStore.savedDraftCount, 0)
    }

    @MainActor
    func testNDSDataDraftSaveReloadPreviewApplyAndClear() async throws {
        let root = try makeNDSSourceProject()
        let firstStore = try makeStore(workspaceRoot: root.deletingLastPathComponent())

        firstStore.openProject(path: root.path)
        firstStore.selectWorkbenchModule(.resources)
        firstStore.loadSelectedAssetCatalogIfNeeded()
        let firstCatalog = try await waitForSelectedAssetCatalog(firstStore)
        let sourceRow = try XCTUnwrap(firstCatalog.rows.first { $0.path == "arm9/src/pokemon.c" })
        firstStore.requestResourceAssetSelection(sourceRow.id)
        firstStore.updateSelectedNDSDataDraftText("void Pokemon_Load(void) { /* saved */ }\n")

        XCTAssertTrue(firstStore.selectedNDSDataIsDirty)
        XCTAssertEqual(firstStore.currentDraftCounts.ndsData, 1)
        XCTAssertTrue(firstStore.saveDraftsNow())
        XCTAssertEqual(firstStore.savedDraftCount, 1)

        let reloadedStore = try makeStore(workspaceRoot: root.deletingLastPathComponent())
        reloadedStore.openProject(path: root.path)
        reloadedStore.selectWorkbenchModule(.resources)
        reloadedStore.loadSelectedAssetCatalogIfNeeded()
        let reloadedCatalog = try await waitForSelectedAssetCatalog(reloadedStore)
        let reloadedRow = try XCTUnwrap(reloadedCatalog.rows.first { $0.path == "arm9/src/pokemon.c" })
        reloadedStore.requestResourceAssetSelection(reloadedRow.id)

        XCTAssertTrue(reloadedStore.selectedNDSDataIsDirty)
        reloadedStore.previewSelectedNDSDataMutationPlan()
        XCTAssertTrue(reloadedStore.canApplySelectedNDSDataMutationPlan)
        reloadedStore.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(reloadedStore.selectedNDSDataIsDirty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("arm9/src/pokemon.c"), encoding: .utf8),
            "void Pokemon_Load(void) { /* saved */ }\n"
        )

        XCTAssertTrue(reloadedStore.saveDraftsNow())
        XCTAssertEqual(reloadedStore.savedDraftCount, 0)
        XCTAssertEqual(try ProjectWorkspacePersistence.loadAutosave(root: root)?.drafts.counts.total, 0)
    }

    @MainActor
    func testProjectSwitchGuardCoversSpeciesDrafts() async throws {
        let firstRoot = try makeUnifiedDataProject()
        let secondRoot = try makeUnifiedDataProject()
        let store = try makeStore(workspaceRoot: firstRoot.deletingLastPathComponent())

        store.openProject(path: firstRoot.path)
        store.selectWorkbenchModule(.pokemon)
        store.loadSelectedSpeciesCatalogIfNeeded()
        try await waitForSelectedSpeciesCatalog(store)
        store.requestSpeciesSelection("SPECIES_TREECKO")
        let firstProjectID = store.selectedProjectID

        var draft = try XCTUnwrap(store.selectedSpeciesDraft)
        draft.baseStats.hp = 47
        store.updateSelectedSpeciesDraft(draft)
        XCTAssertTrue(store.selectedSpeciesIsDirty)

        store.openProject(path: secondRoot.path)

        XCTAssertEqual(store.selectedProjectID, firstProjectID)
        XCTAssertEqual(store.selectedIndexedProject?.rootPath, firstRoot.path)
        XCTAssertTrue(store.selectedSpeciesIsDirty)
        XCTAssertNotNil(store.pendingMapNavigation)

        store.discardMapEditsAndContinueNavigation()

        XCTAssertEqual(store.selectedIndexedProject?.rootPath, secondRoot.path)
        XCTAssertNil(store.pendingMapNavigation)
        XCTAssertFalse(store.selectedSpeciesIsDirty)
    }

    @MainActor
    func testProjectSwitchGuardCoversOffSelectionDrafts() async throws {
        let firstRoot = try makeUnifiedDataProject()
        let secondRoot = try makeUnifiedDataProject()
        let store = try makeStore(workspaceRoot: firstRoot.deletingLastPathComponent())

        store.openProject(path: firstRoot.path)
        store.selectWorkbenchModule(.trainers)
        store.loadSelectedTrainerCatalogIfNeeded()
        try await waitForSelectedTrainerCatalog(store)
        store.requestTrainerSelection("TRAINER_TEST")
        let firstProjectID = store.selectedProjectID

        var draft = try XCTUnwrap(store.selectedTrainerDraft)
        draft.trainerName = "OFFSCREEN"
        store.updateSelectedTrainerDraft(draft)
        XCTAssertEqual(store.currentDraftCounts.trainers, 1)
        store.requestTrainerSelection("TRAINER_BOSS")
        XCTAssertFalse(store.selectedTrainerIsDirty)
        XCTAssertTrue(store.hasStagedEdits)

        store.openProject(path: secondRoot.path)

        XCTAssertEqual(store.selectedProjectID, firstProjectID)
        XCTAssertEqual(store.selectedIndexedProject?.rootPath, firstRoot.path)
        XCTAssertNotNil(store.pendingMapNavigation)

        store.discardMapEditsAndContinueNavigation()

        XCTAssertEqual(store.selectedIndexedProject?.rootPath, secondRoot.path)
        XCTAssertNil(store.pendingMapNavigation)
        XCTAssertEqual(store.currentDraftCount, 0)
    }

    @MainActor
    func testItemsHiddenByFilterKeepDetailAndDraftAligned() async throws {
        let root = try makeUnifiedDataProject()
        let store = try makeStore(workspaceRoot: root.deletingLastPathComponent())

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.items)
        store.loadSelectedItemCatalogIfNeeded()
        try await waitForSelectedItemCatalog(store)
        store.requestItemSelection("ITEM_POTION")

        store.searchText = "super"

        XCTAssertEqual(store.filteredItemDetails.map(\.itemID), ["ITEM_SUPER_POTION"])
        XCTAssertEqual(store.selectedItemDetail?.itemID, "ITEM_POTION")
        XCTAssertEqual(store.selectedItemDraft?.itemID, "ITEM_POTION")
        XCTAssertEqual(store.selectedCoreItemDetail?.itemID, "ITEM_POTION")

        let selectedItem = try XCTUnwrap(store.selectedItemDetail)
        XCTAssertEqual(selectedItem.source.path, "src/data/items.h")
        XCTAssertEqual(selectedItem.source.symbol, "ITEM_POTION")

        let inspector = store.itemSourceInspectorContext
        XCTAssertEqual(inspector.title, selectedItem.displayName)
        XCTAssertEqual(inspector.subtitle, "ITEM_POTION")
        XCTAssertEqual(inspector.sources.first?.title, "Item Definition")
        XCTAssertEqual(inspector.sources.first?.source.path, selectedItem.source.path)
        XCTAssertEqual(inspector.sources.first?.source.symbol, selectedItem.source.symbol)
        XCTAssertEqual(inspector.sources.first?.source.line, selectedItem.source.line)
    }

    @MainActor
    func testEncountersFirstOpenLoadsLiveSourceRows() async throws {
        let root = try makeUnifiedDataProject()
        let store = try makeStore(workspaceRoot: root.deletingLastPathComponent())

        store.openProject(path: root.path)
        XCTAssertNil(store.selectedSourceIndex)
        store.selectWorkbenchModule(.encounters)

        _ = try await waitForSelectedSourceGraph(store)

        let encounters = store.records(for: .encounters)
        XCTAssertTrue(encounters.contains { $0.title == "MAP_ROUTE101" })
        XCTAssertTrue(encounters.contains { $0.source.path == "src/data/wild_encounters.json" })
    }

    @MainActor
    func testNDSDataApplyBlocksWhenSourceChangesAfterPreview() async throws {
        let root = try makeNDSSourceProject()
        let store = try makeStore(workspaceRoot: root.deletingLastPathComponent())

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let catalog = try await waitForSelectedAssetCatalog(store)
        let sourceRow = try XCTUnwrap(catalog.rows.first { $0.path == "arm9/src/pokemon.c" })
        store.requestResourceAssetSelection(sourceRow.id)
        store.updateSelectedNDSDataDraftText("void Pokemon_Load(void) { /* edited */ }\n")

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        try write("void Pokemon_Load(void) { /* changed elsewhere */ }\n", to: root.appendingPathComponent("arm9/src/pokemon.c"))

        store.applySelectedNDSDataMutationPlan()

        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 0)
        XCTAssertTrue(store.latestNDSDataApplyResult?.diagnostics.contains { $0.code.hasPrefix("NDS_DATA_APPLY_SOURCE_") } == true)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("arm9/src/pokemon.c"), encoding: .utf8),
            "void Pokemon_Load(void) { /* changed elsewhere */ }\n"
        )
    }

    @MainActor
    private func makeStore(workspaceRoot: URL) throws -> WorkbenchStore {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "ProjectWorkspaceStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)
        settings.includeDefaultDebugProjects = false
        settings.includeRecentProjectsInRefresh = false
        return WorkbenchStore(
            userDefaults: defaults,
            userSettings: settings,
            workspaceRoot: workspaceRoot,
            autoLoadProjects: false
        )
    }

    @MainActor
    private func waitForSelectedSpeciesCatalog(_ store: WorkbenchStore) async throws {
        for _ in 0..<80 {
            if store.selectedSpeciesCatalog != nil { return }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.speciesCatalogTimedOut
    }

    @MainActor
    private func waitForSelectedTrainerCatalog(_ store: WorkbenchStore) async throws {
        for _ in 0..<80 {
            if store.selectedTrainerCatalog != nil { return }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.trainerCatalogTimedOut
    }

    @MainActor
    private func waitForSelectedMoveCatalog(_ store: WorkbenchStore) async throws {
        for _ in 0..<80 {
            if store.selectedCoreMoveCatalog != nil { return }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.moveCatalogTimedOut
    }

    @MainActor
    private func waitForSelectedItemCatalog(_ store: WorkbenchStore) async throws {
        for _ in 0..<80 {
            if store.selectedItemCatalog != nil { return }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.itemCatalogTimedOut
    }

    @MainActor
    private func waitForSelectedMapVisual(_ store: WorkbenchStore, mapID: String) async throws {
        for _ in 0..<80 {
            if store.selectedMapVisualDocument?.mapID == mapID { return }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.mapVisualTimedOut
    }

    @MainActor
    private func waitForSelectedGraphicsReport(_ store: WorkbenchStore) async throws {
        for _ in 0..<80 {
            if store.selectedGraphicsReport != nil { return }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.graphicsReportTimedOut
    }

    @MainActor
    private func waitForSelectedSourceGraph(_ store: WorkbenchStore) async throws -> ProjectSourceIndex {
        for _ in 0..<80 {
            if let sourceIndex = store.selectedSourceIndex {
                return sourceIndex
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.sourceGraphTimedOut
    }

    @MainActor
    private func waitForSelectedAssetCatalog(_ store: WorkbenchStore) async throws -> ResourceAssetCatalogViewState {
        for _ in 0..<80 {
            if let catalog = store.selectedAssetCatalog { return catalog }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.assetCatalogTimedOut
    }

    @MainActor
    private func selectGeneralMetatilesRow(_ store: WorkbenchStore) throws {
        let row = try XCTUnwrap(
            store.filteredGraphicsReportRows.first {
                $0.source.path == "data/tilesets/primary/general/metatiles.bin"
            }
        )
        store.requestGraphicsReportRowSelection(row.id)
    }

    private func makeUnifiedDataProject() throws -> URL {
        let temp = try ProjectWorkspaceTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url

        try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/pokenav"), withIntermediateDirectories: true)
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try writeConstants(root: root)
        try writeSpeciesSources(root: root)
        try writeTrainerSources(root: root)
        try writeMoveSources(root: root)
        try writeItemSources(root: root)
        try writeEncounterSources(root: root)
        return root
    }

    private func makeNDSSourceProject() throws -> URL {
        let temp = try ProjectWorkspaceTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url

        try write("diamond: ; @echo build\n", to: root.appendingPathComponent("Makefile"))
        try write("GAME_VERSION ?= DIAMOND\n", to: root.appendingPathComponent("config.mk"))
        try write("NitroROMSpec\n", to: root.appendingPathComponent("rom.rsf"))
        try write("FILESYSTEM_ROOT := files\n", to: root.appendingPathComponent("filesystem.mk"))
        try write("0" + String(repeating: "a", count: 39) + "  pokediamond.us.nds\n", to: root.appendingPathComponent("pokediamond.us.sha1"))
        try write("arm9 source\n", to: root.appendingPathComponent("arm9/main.c"))
        try write("void Pokemon_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/pokemon.c"))
        try write("void Script_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/script.c"))
        try write("arm7 source\n", to: root.appendingPathComponent("arm7/main.s"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/root.bin"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/fielddata/mapmatrix/matrix.bin"))
        try write(Data([0x00]), to: root.appendingPathComponent("graphics/icon.bin"))
        try write("// header\n", to: root.appendingPathComponent("include/config.h"))

        return root
    }

    private func writeConstants(root: URL) throws {
        try write(
            """
            #define SPECIES_NONE 0
            #define SPECIES_TREECKO 1
            #define SPECIES_TORCHIC 2
            """,
            to: root.appendingPathComponent("include/constants/species.h")
        )
        try write(
            """
            #define TYPE_NORMAL 0
            #define TYPE_GRASS 1
            #define TYPE_FIRE 2
            #define EGG_GROUP_MONSTER 1
            #define EGG_GROUP_DRAGON 2
            #define GROWTH_MEDIUM_SLOW 1
            #define BODY_COLOR_GREEN 2
            """,
            to: root.appendingPathComponent("include/constants/pokemon.h")
        )
        try write(
            """
            #define ABILITY_NONE 0
            #define ABILITY_OVERGROW 65
            """,
            to: root.appendingPathComponent("include/constants/abilities.h")
        )
        try write(
            """
            #define MOVE_NONE 0
            #define MOVE_TACKLE 1
            #define MOVE_POUND 2
            #define MOVE_ABSORB 3
            #define MOVE_EMBER 4
            #define MOVE_FLASH 5
            #define MOVE_CUT 6
            #define MOVE_BULLET_SEED 7
            """,
            to: root.appendingPathComponent("include/constants/moves.h")
        )
        try write(
            """
            #define ITEM_NONE 0
            #define ITEM_POTION 1
            #define ITEM_SUPER_POTION 2
            #define ITEM_ORAN_BERRY 3
            #define ITEM_TM09_BULLET_SEED 100
            #define ITEM_HM01_CUT 101
            #define ITEM_HM05_FLASH 105
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
            """,
            to: root.appendingPathComponent("include/constants/trainers.h")
        )
        try write(
            """
            #define AI_SCRIPT_CHECK_BAD_MOVE (1 << 0)
            #define AI_SCRIPT_CHECK_VIABILITY (1 << 1)
            """,
            to: root.appendingPathComponent("include/constants/battle_ai.h")
        )
    }

    private func writeSpeciesSources(root: URL) throws {
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
                    .expYield = 65,
                    .evYield_HP = 0,
                    .evYield_Attack = 0,
                    .evYield_Defense = 0,
                    .evYield_Speed = 1,
                    .evYield_SpAttack = 0,
                    .evYield_SpDefense = 0,
                    .itemCommon = ITEM_NONE,
                    .itemRare = ITEM_NONE,
                    .genderRatio = PERCENT_FEMALE(12.5),
                    .eggCycles = 20,
                    .friendship = STANDARD_FRIENDSHIP,
                    .growthRate = GROWTH_MEDIUM_SLOW,
                    .eggGroups = { EGG_GROUP_MONSTER, EGG_GROUP_DRAGON },
                    .abilities = { ABILITY_OVERGROW, ABILITY_NONE },
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
            const u16 *const gLevelUpLearnsets[] = { [SPECIES_TREECKO] = sTreeckoLevelUpLearnset };
            """,
            to: root.appendingPathComponent("src/data/pokemon/level_up_learnset_pointers.h")
        )
        try write(
            """
            static const u16 sTreeckoLevelUpLearnset[] = {
                LEVEL_UP_MOVE( 1, MOVE_POUND),
                LEVEL_UP_END
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/level_up_learnsets.h")
        )
        try write(
            """
            const struct TMHMLearnset gTMHMLearnsets[] =
            {
                [SPECIES_TREECKO] = { .learnset = { .CUT = TRUE } },
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/tmhm_learnsets.h")
        )
        try write(
            """
            static const u16 sEggMoveLearnsets[] = {
                egg_moves(TREECKO, MOVE_ABSORB),
                EGG_MOVES_TERMINATOR
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/egg_moves.h")
        )
    }

    private func writeTrainerSources(root: URL) throws {
        try write(
            """
            const struct Trainer gTrainers[] = {
                [TRAINER_TEST] =
                {
                    .trainerClass = TRAINER_CLASS_PKMN_TRAINER_1,
                    .encounterMusic_gender = TRAINER_ENCOUNTER_MUSIC_MALE,
                    .trainerPic = TRAINER_PIC_HIKER,
                    .trainerName = _("TEST"),
                    .items = {},
                    .doubleBattle = FALSE,
                    .aiFlags = AI_SCRIPT_CHECK_BAD_MOVE,
                    .party = NO_ITEM_DEFAULT_MOVES(sParty_Test),
                },
                [TRAINER_BOSS] =
                {
                    .trainerClass = TRAINER_CLASS_RIVAL,
                    .encounterMusic_gender = TRAINER_ENCOUNTER_MUSIC_MALE,
                    .trainerPic = TRAINER_PIC_RIVAL,
                    .trainerName = _("BOSS"),
                    .items = {ITEM_POTION, ITEM_NONE, ITEM_NONE, ITEM_NONE},
                    .doubleBattle = FALSE,
                    .aiFlags = AI_SCRIPT_CHECK_BAD_MOVE,
                    .party = ITEM_CUSTOM_MOVES(sParty_Boss),
                },
            };
            """,
            to: root.appendingPathComponent("src/data/trainers.h")
        )
        try write(
            """
            static const struct TrainerMonNoItemDefaultMoves sParty_Test[] = {
                {
                    .iv = 0,
                    .lvl = 5,
                    .species = SPECIES_TREECKO,
                },
            };

            static const struct TrainerMonItemCustomMoves sParty_Boss[] = {
                {
                    .iv = 80,
                    .lvl = 20,
                    .species = SPECIES_TREECKO,
                    .heldItem = ITEM_POTION,
                    .moves = { MOVE_POUND, MOVE_ABSORB, MOVE_NONE, MOVE_NONE },
                },
            };
            """,
            to: root.appendingPathComponent("src/data/trainer_parties.h")
        )
    }

    private func writeMoveSources(root: URL) throws {
        try write(
            """
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
                },
            };
            """,
            to: root.appendingPathComponent("src/data/battle_moves.h")
        )
    }

    private func writeItemSources(root: URL) throws {
        try write(
            """
            const struct Item gItems[] =
            {
                [ITEM_POTION] =
                {
                    .name = _("POTION"),
                    .itemId = ITEM_POTION,
                    .price = 300,
                    .holdEffect = HOLD_EFFECT_NONE,
                    .holdEffectParam = 0,
                    .pocket = POCKET_ITEMS,
                    .type = ITEM_USE_BAG_MENU,
                    .battleUsage = 0,
                    .secondaryId = 0,
                    .fieldUseFunc = ItemUseOutOfBattle_CannotUse,
                    .battleUseFunc = NULL,
                },
                [ITEM_SUPER_POTION] =
                {
                    .name = _("SUPER POTION"),
                    .itemId = ITEM_SUPER_POTION,
                    .price = 700,
                    .holdEffect = HOLD_EFFECT_NONE,
                    .holdEffectParam = 0,
                    .pocket = POCKET_ITEMS,
                    .type = ITEM_USE_BAG_MENU,
                    .battleUsage = 0,
                    .secondaryId = 0,
                    .fieldUseFunc = ItemUseOutOfBattle_CannotUse,
                    .battleUseFunc = NULL,
                },
            };
            """,
            to: root.appendingPathComponent("src/data/items.h")
        )
    }

    private func writeEncounterSources(root: URL) throws {
        try write(
            """
            {
              "wild_encounter_groups": [
                {
                  "label": "gWildMonHeaders",
                  "encounters": [
                    {
                      "map": "MAP_ROUTE101",
                      "base_label": "gRoute101",
                      "land_mons": {
                        "encounter_rate": 20,
                        "mons": [
                          { "species": "SPECIES_TREECKO", "min_level": 2, "max_level": 2 }
                        ]
                      }
                    }
                  ]
                }
              ]
            }
            """,
            to: root.appendingPathComponent("src/data/wild_encounters.json")
        )
    }

    private func makeVisualProject() throws -> URL {
        let temp = try ProjectWorkspaceTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url

        try write("POKEMON EMER\n", to: root.appendingPathComponent("Makefile"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/pokenav"), withIntermediateDirectories: true)
        try write(
            """
            {
              "group_order": ["gMapGroup_Routes"],
              "gMapGroup_Routes": ["Route1"]
            }
            """,
            to: root.appendingPathComponent("data/maps/map_groups.json")
        )
        try write(
            """
            {
              "layouts_table_label": "gMapLayouts",
              "layouts": [
                {
                  "id": "LAYOUT_ROUTE1",
                  "name": "Route1_Layout",
                  "width": 2,
                  "height": 2,
                  "border_width": 2,
                  "border_height": 2,
                  "primary_tileset": "gTileset_General",
                  "secondary_tileset": "gTileset_Route",
                  "border_filepath": "data/layouts/Route1/border.bin",
                  "blockdata_filepath": "data/layouts/Route1/map.bin"
                }
              ]
            }
            """,
            to: root.appendingPathComponent("data/layouts/layouts.json")
        )
        try writeMapJSON(name: "Route1", mapID: "MAP_ROUTE1", layoutID: "LAYOUT_ROUTE1", to: root.appendingPathComponent("data/maps/Route1/map.json"))
        try writeTilesetHeaders(root: root)
        try writeWords([1, 2, 3, 4], to: root.appendingPathComponent("data/layouts/Route1/map.bin"))
        try writeWords([9, 10, 11, 12], to: root.appendingPathComponent("data/layouts/Route1/border.bin"))
        try writeWords([1, 2, 3, 4, 5, 6, 7, 8], to: root.appendingPathComponent("data/tilesets/primary/general/metatiles.bin"))
        try writeWords([1], to: root.appendingPathComponent("data/tilesets/primary/general/metatile_attributes.bin"))
        try writeWords([1, 2, 3, 4, 5, 6, 7, 8], to: root.appendingPathComponent("data/tilesets/secondary/route/metatiles.bin"))
        try writeWords([1], to: root.appendingPathComponent("data/tilesets/secondary/route/metatile_attributes.bin"))
        try write(Data(), to: root.appendingPathComponent("data/tilesets/primary/general/tiles.png"))
        try write(Data(), to: root.appendingPathComponent("data/tilesets/secondary/route/tiles.png"))
        try write(Data(), to: root.appendingPathComponent("data/tilesets/primary/general/palettes/00.pal"))
        try write(Data(), to: root.appendingPathComponent("data/tilesets/secondary/route/palettes/00.gbapal"))
        return root
    }

    private func writeTilesetHeaders(root: URL) throws {
        try write(
            """
            const struct Tileset gTileset_General =
            {
                .isCompressed = TRUE,
                .isSecondary = FALSE,
                .tiles = gTilesetTiles_General,
                .palettes = gTilesetPalettes_General,
                .metatiles = gMetatiles_General,
                .metatileAttributes = gMetatileAttributes_General,
                .callback = NULL,
            };

            const struct Tileset gTileset_Route =
            {
                .isCompressed = TRUE,
                .isSecondary = TRUE,
                .tiles = gTilesetTiles_Route,
                .palettes = gTilesetPalettes_Route,
                .metatiles = gMetatiles_Route,
                .metatileAttributes = gMetatileAttributes_Route,
                .callback = NULL,
            };
            """,
            to: root.appendingPathComponent("src/data/tilesets/headers.h")
        )
        try write(
            """
            const u32 gTilesetTiles_General[] = INCGFX_U32("data/tilesets/primary/general/tiles.png", ".4bpp.lz", "-num_tiles 1");
            const u16 gTilesetPalettes_General[][16] =
            {
                INCGFX_U16("data/tilesets/primary/general/palettes/00.pal", ".gbapal"),
            };
            const u32 gTilesetTiles_Route[] = INCBIN_U32("data/tilesets/secondary/route/tiles.4bpp.lz");
            const u16 gTilesetPalettes_Route[][16] =
            {
                INCBIN_U16("data/tilesets/secondary/route/palettes/00.gbapal"),
            };
            """,
            to: root.appendingPathComponent("src/data/tilesets/graphics.h")
        )
        try write(
            """
            const u16 gMetatiles_General[] = INCBIN_U16("data/tilesets/primary/general/metatiles.bin");
            const u16 gMetatileAttributes_General[] = INCBIN_U16("data/tilesets/primary/general/metatile_attributes.bin");
            const u16 gMetatiles_Route[] = INCBIN_U16("data/tilesets/secondary/route/metatiles.bin");
            const u16 gMetatileAttributes_Route[] = INCBIN_U16("data/tilesets/secondary/route/metatile_attributes.bin");
            """,
            to: root.appendingPathComponent("src/data/tilesets/metatiles.h")
        )
    }

    private func writeMapJSON(name: String, mapID: String, layoutID: String, to url: URL) throws {
        try write(
            """
            {
              "id": "\(mapID)",
              "name": "\(name)",
              "layout": "\(layoutID)",
              "events": {
                "object_events": [],
                "warp_events": [],
                "coord_events": [],
                "bg_events": []
              },
              "connections": []
            }
            """,
            to: url
        )
    }

    private func writeWords(_ words: [UInt16], to url: URL) throws {
        var data = Data()
        for word in words {
            data.append(UInt8(word & 0xff))
            data.append(UInt8((word >> 8) & 0xff))
        }
        try write(data, to: url)
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

private final class ProjectWorkspaceTemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackProjectWorkspaceStoreTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}

private enum StoreTestError: Error {
    case speciesCatalogTimedOut
    case trainerCatalogTimedOut
    case moveCatalogTimedOut
    case itemCatalogTimedOut
    case mapVisualTimedOut
    case graphicsReportTimedOut
    case sourceGraphTimedOut
    case assetCatalogTimedOut
}
