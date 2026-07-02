import AppKit
import CryptoKit
import PokemonHackCore
import XCTest

final class MapEditorStoreTests: XCTestCase {
    private var temporaryDirectories: [MapEditorStoreTemporaryDirectory] = []

    override func tearDown() {
        temporaryDirectories.removeAll()
        super.tearDown()
    }

    @MainActor
    func testSourceIndexRecordsReplaceFixturesForDataAndScriptModules() async throws {
        let root = try makeSourceIndexProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        XCTAssertNil(store.selectedSourceIndex)
        XCTAssertEqual(store.sourceGraphLoadStatus, .idle)

        store.loadSelectedSourceGraphIfNeeded()
        try await waitForSelectedSourceGraph(store)

        let script = try XCTUnwrap(store.records(for: .scripts).first { $0.title == "Test_EventScript" })
        let text = try XCTUnwrap(store.records(for: .text).first { $0.title == "gText_Test" })
        let pokemon = try XCTUnwrap(store.records(for: .pokemon).first { $0.title == "SPECIES_TREECKO" })
        let trainer = try XCTUnwrap(store.records(for: .trainers).first { $0.title == "TRAINER_TEST" })
        let item = try XCTUnwrap(store.records(for: .items).first { $0.title == "ITEM_POTION" })

        XCTAssertFalse(script.isDirty)
        XCTAssertFalse(text.isDirty)
        XCTAssertFalse(pokemon.isDirty)
        XCTAssertFalse(trainer.isDirty)
        XCTAssertFalse(item.isDirty)
        XCTAssertEqual(script.source.path, "data/scripts/test.inc")
        XCTAssertEqual(text.source.path, "data/text/test.inc")
        XCTAssertTrue(item.facts.contains { $0.label == "price" && $0.value == "300" })
    }

    @MainActor
    func testToolbarMutationStateDefaultsWithoutEditableModule() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        let state = store.toolbarMutationState

        XCTAssertEqual(state.target, .map)
        XCTAssertTrue(state.hasEditableTarget)
        XCTAssertFalse(state.canPreview)
        XCTAssertFalse(state.canApply)
        XCTAssertFalse(state.canDiscard)
        XCTAssertEqual(state.previewBlockedReason, "No map document is loaded.")
        XCTAssertEqual(store.mutationActionBarState.target, .map)
        XCTAssertEqual(store.mutationActionBarState.previewHelp, "No map document is loaded.")
    }

    @MainActor
    func testToolbarMutationStateRoutesMapPreviewAndDiscard() async throws {
        let store = try await makeLoadedStore()
        store.selection = .maps

        XCTAssertEqual(store.toolbarMutationState.target, .map)
        XCTAssertEqual(store.mutationActionBarState.target, .map)
        XCTAssertFalse(store.toolbarMutationState.canPreview)
        XCTAssertEqual(store.toolbarMutationState.previewBlockedReason, "No staged edits to preview.")

        store.selectBrush(rawValue: 0x0044)
        store.paintMapCell(x: 0, y: 0)

        XCTAssertTrue(store.toolbarMutationState.canPreview)
        XCTAssertTrue(store.mutationActionBarState.canPreview)
        XCTAssertTrue(store.toolbarMutationState.canDiscard)

        store.previewToolbarMutationTarget()

        XCTAssertNotNil(store.latestMapEditPlan)
        XCTAssertTrue(store.toolbarMutationState.canApply)

        store.discardToolbarMutationTarget()

        XCTAssertFalse(store.mapEditorSession.isDirty)
        XCTAssertNil(store.latestMapEditPlan)
        XCTAssertFalse(store.toolbarMutationState.canDiscard)
    }

    @MainActor
    func testToolbarMutationStateRoutesTrainerPreviewAndDiscard() async throws {
        let root = try makeTrainerProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)
        settings.includeDefaultDebugProjects = false
        let store = WorkbenchStore(userDefaults: defaults, userSettings: settings, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selection = .trainers
        store.loadSelectedTrainerCatalogIfNeeded()
        try await waitForSelectedTrainerCatalog(store)
        store.requestTrainerSelection("TRAINER_BOSS")

        var draft = try XCTUnwrap(store.selectedTrainerDraft)
        draft.trainerName = "EDITED"
        store.updateSelectedTrainerDraft(draft)

        XCTAssertEqual(store.toolbarMutationState.target, .trainer)
        XCTAssertEqual(store.mutationActionBarState.target, .trainer)
        XCTAssertTrue(store.toolbarMutationState.canPreview)
        XCTAssertTrue(store.mutationActionBarState.canPreview)
        XCTAssertTrue(store.toolbarMutationState.canDiscard)

        store.previewToolbarMutationTarget()

        XCTAssertNotNil(store.latestTrainerEditPlan)
        XCTAssertTrue(store.toolbarMutationState.canApply)

        store.discardToolbarMutationTarget()

        XCTAssertFalse(store.selectedTrainerIsDirty)
        XCTAssertNil(store.latestTrainerEditPlan)
        XCTAssertFalse(store.toolbarMutationState.canDiscard)
    }

    @MainActor
    func testTrainerCatalogLoadsSelectionAndFilteringIntoStore() async throws {
        let root = try makeTrainerProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)
        settings.includeDefaultDebugProjects = false
        let store = WorkbenchStore(userDefaults: defaults, userSettings: settings, autoLoadProjects: false)

        store.openProject(path: root.path)
        XCTAssertNil(store.selectedTrainerCatalog)
        XCTAssertEqual(store.trainerCatalogLoadStatus, .idle)

        store.loadSelectedTrainerCatalogIfNeeded()
        let catalog = try await waitForSelectedTrainerCatalog(store)

        XCTAssertEqual(catalog.trainerCount, 2)
        XCTAssertEqual(store.trainerCatalogLoadStatus, .loaded(2))
        XCTAssertEqual(store.selectedTrainerID, "TRAINER_TEST")
        XCTAssertEqual(store.selectedTrainerDetail?.trainerName, "TEST")
        XCTAssertEqual(store.selectedTrainerDraft?.party.first?.species, "SPECIES_TREECKO")

        store.searchText = "boss"

        XCTAssertEqual(store.filteredTrainerDetails.map(\.trainerID), ["TRAINER_BOSS"])
    }

    @MainActor
    func testTrainerDraftPreviewContextApplyAndDiscardFlow() async throws {
        let root = try makeTrainerProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)
        settings.includeDefaultDebugProjects = false
        let store = WorkbenchStore(userDefaults: defaults, userSettings: settings, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedTrainerCatalogIfNeeded()
        try await waitForSelectedTrainerCatalog(store)
        store.requestTrainerSelection("TRAINER_BOSS")

        var draft = try XCTUnwrap(store.selectedTrainerDraft)
        draft.trainerName = "EDITED"
        draft.trainerItems = ["ITEM_SUPER_POTION", "ITEM_NONE", "ITEM_NONE", "ITEM_NONE"]
        draft.doubleBattle = true
        draft.aiFlags = ["AI_SCRIPT_CHECK_BAD_MOVE", "AI_SCRIPT_CHECK_VIABILITY"]
        draft.partyShape = .itemCustomMoves
        draft.party[0].species = "SPECIES_TORCHIC"
        draft.party[0].level = 24
        draft.party[0].iv = 90
        draft.party[0].heldItem = "ITEM_ORAN_BERRY"
        draft.party[0].moves = ["MOVE_EMBER", "MOVE_POUND", "MOVE_NONE", "MOVE_NONE"]

        store.updateSelectedTrainerDraft(draft)

        XCTAssertTrue(store.selectedTrainerIsDirty)
        XCTAssertTrue(store.canPreviewSelectedTrainerMutationPlan)

        store.previewSelectedTrainerMutationPlan()

        let plan = try XCTUnwrap(store.latestTrainerEditPlan)
        XCTAssertEqual(plan.changes.map(\.path).sorted(), ["src/data/trainer_parties.h", "src/data/trainers.h"])
        XCTAssertTrue(store.canApplySelectedTrainerMutationPlan)

        let context = try XCTUnwrap(
            MutationPlanPanelContext.trainer(
                plan: store.latestTrainerEditPlan,
                result: store.latestTrainerApplyResult,
                isDirty: store.selectedTrainerIsDirty,
                canPreview: store.canPreviewSelectedTrainerMutationPlan,
                canApply: store.canApplySelectedTrainerMutationPlan,
                canDiscard: store.canDiscardTrainerEdits,
                previewBlockedReason: store.trainerPreviewBlockedReason,
                applyBlockedReason: store.trainerApplyBlockedReason
            )
        )
        XCTAssertEqual(context.changes.count, 2)
        XCTAssertTrue(context.canApply)

        store.discardTrainerEdits()

        XCTAssertFalse(store.selectedTrainerIsDirty)
        XCTAssertNil(store.latestTrainerEditPlan)

        store.updateSelectedTrainerDraft(draft)
        store.previewSelectedTrainerMutationPlan()
        store.applySelectedTrainerMutationPlan()

        XCTAssertEqual(store.latestTrainerApplyResult?.appliedChanges.count, 2)
        XCTAssertFalse(store.selectedTrainerIsDirty)
        XCTAssertEqual(store.selectedTrainerDetail?.trainerName, "EDITED")
        XCTAssertEqual(store.selectedTrainerDetail?.party.first?.species, "SPECIES_TORCHIC")
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.latestTrainerApplyResult?.backupRootPath ?? ""))
    }

    @MainActor
    func testSpeciesDraftPreviewContextApplyAndDiscardFlow() async throws {
        let root = try makePokemonProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)
        settings.includeDefaultDebugProjects = false
        let store = WorkbenchStore(userDefaults: defaults, userSettings: settings, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selection = .pokemon
        store.loadSelectedSpeciesCatalogIfNeeded()
        try await waitForSelectedSpeciesCatalog(store)
        store.requestSpeciesSelection("SPECIES_TREECKO")

        if case let .loaded(count) = store.speciesCatalogLoadStatus {
            XCTAssertGreaterThanOrEqual(count, 2)
        } else {
            XCTFail("Expected loaded species catalog")
        }
        XCTAssertEqual(store.selectedSpeciesDetail?.displayName, "Treecko")
        var draft = try XCTUnwrap(store.selectedSpeciesDraft)
        draft.baseStats.hp = 44
        draft.types[1] = "TYPE_FIRE"
        draft.abilities[1] = "ABILITY_CHLOROPHYLL"
        draft.levelUpMoves.append(SpeciesLevelUpMoveDraft(level: 9, move: "MOVE_FLASH"))
        draft.tmhmMoves.append("MOVE_FLASH")
        draft.eggMoves = ["MOVE_LEECH_SEED", "MOVE_FLASH"]

        store.updateSelectedSpeciesDraft(draft)

        XCTAssertTrue(store.selectedSpeciesIsDirty)
        XCTAssertEqual(store.mutationActionBarState.target, .pokemon)
        XCTAssertTrue(store.mutationActionBarState.canPreview)
        XCTAssertTrue(store.canPreviewSelectedSpeciesMutationPlan)

        store.previewSelectedSpeciesMutationPlan()

        let plan = try XCTUnwrap(store.latestSpeciesEditPlan)
        XCTAssertEqual(
            plan.changes.map(\.path).sorted(),
            [
                "src/data/pokemon/egg_moves.h",
                "src/data/pokemon/level_up_learnsets.h",
                "src/data/pokemon/species_info.h",
                "src/data/pokemon/tmhm_learnsets.h",
            ]
        )
        XCTAssertTrue(store.canApplySelectedSpeciesMutationPlan)

        let context = try XCTUnwrap(
            MutationPlanPanelContext.species(
                plan: store.latestSpeciesEditPlan,
                result: store.latestSpeciesApplyResult,
                isDirty: store.selectedSpeciesIsDirty,
                canPreview: store.canPreviewSelectedSpeciesMutationPlan,
                canApply: store.canApplySelectedSpeciesMutationPlan,
                canDiscard: store.canDiscardSpeciesEdits,
                previewBlockedReason: store.speciesPreviewBlockedReason,
                applyBlockedReason: store.speciesApplyBlockedReason
            )
        )
        XCTAssertEqual(context.target, .pokemon)
        XCTAssertEqual(context.changes.count, 4)
        XCTAssertTrue(context.canApply)

        store.discardSpeciesEdits()

        XCTAssertFalse(store.selectedSpeciesIsDirty)
        XCTAssertNil(store.latestSpeciesEditPlan)

        store.updateSelectedSpeciesDraft(draft)
        store.previewSelectedSpeciesMutationPlan()
        store.applySelectedSpeciesMutationPlan()

        XCTAssertEqual(store.latestSpeciesApplyResult?.appliedChanges.count, 4)
        XCTAssertFalse(store.selectedSpeciesIsDirty)
        XCTAssertEqual(store.selectedSpeciesID, "SPECIES_TREECKO")
        XCTAssertEqual(store.selectedSpeciesDetail?.baseStats.hp, 44)
        XCTAssertEqual(store.selectedSpeciesDetail?.types, ["TYPE_GRASS", "TYPE_FIRE"])
        XCTAssertTrue(store.selectedSpeciesDetail?.learnsets.tmhm.map(\.move).contains("MOVE_FLASH") == true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.latestSpeciesApplyResult?.backupRootPath ?? ""))
    }

    @MainActor
    func testMovesCompatibilityBatchPreviewApplyAndDiscardFlow() async throws {
        let root = try makePokemonProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)
        settings.includeDefaultDebugProjects = false
        let store = WorkbenchStore(userDefaults: defaults, userSettings: settings, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selection = .moves
        store.loadSelectedSpeciesCatalogIfNeeded()
        try await waitForSelectedSpeciesCatalog(store)

        store.setSpeciesCompatibility(speciesID: "SPECIES_TREECKO", moveID: "MOVE_CUT", bucket: .tmhm, isEnabled: false)
        store.setSpeciesCompatibility(speciesID: "SPECIES_GROVYLE", moveID: "MOVE_FLASH", bucket: .tmhm, isEnabled: true)

        XCTAssertEqual(store.dirtySpeciesBatchDrafts.map(\.speciesID), ["SPECIES_GROVYLE", "SPECIES_TREECKO"])
        XCTAssertEqual(store.toolbarMutationState.target, .pokemonBatch)
        XCTAssertEqual(store.mutationActionBarState.target, .pokemonBatch)
        XCTAssertTrue(store.toolbarMutationState.canPreview)
        XCTAssertTrue(store.mutationActionBarState.canPreview)
        XCTAssertTrue(store.toolbarMutationState.canDiscard)

        store.previewToolbarMutationTarget()

        XCTAssertEqual(store.latestSpeciesBatchEditPlans.count, 2)
        XCTAssertTrue(store.toolbarMutationState.canApply)
        let context = try XCTUnwrap(
            MutationPlanPanelContext.speciesBatch(
                plans: store.latestSpeciesBatchEditPlans,
                result: store.latestSpeciesBatchApplyResult,
                dirtyDraftCount: store.dirtySpeciesBatchDrafts.count,
                canPreview: store.canPreviewSpeciesBatchMutationPlan,
                canApply: store.canApplySpeciesBatchMutationPlan,
                canDiscard: store.canDiscardSpeciesBatchEdits,
                previewBlockedReason: store.speciesBatchPreviewBlockedReason,
                applyBlockedReason: store.speciesBatchApplyBlockedReason
            )
        )
        XCTAssertEqual(context.target, .pokemonBatch)
        XCTAssertEqual(context.operationCount, 2)
        XCTAssertTrue(context.canApply)

        store.discardToolbarMutationTarget()

        XCTAssertTrue(store.dirtySpeciesBatchDrafts.isEmpty)
        XCTAssertTrue(store.latestSpeciesBatchEditPlans.isEmpty)

        store.setSpeciesCompatibility(speciesID: "SPECIES_TREECKO", moveID: "MOVE_CUT", bucket: .tmhm, isEnabled: false)
        store.setSpeciesCompatibility(speciesID: "SPECIES_GROVYLE", moveID: "MOVE_FLASH", bucket: .tmhm, isEnabled: true)
        store.previewToolbarMutationTarget()
        store.applyToolbarMutationTarget()

        XCTAssertTrue((store.latestSpeciesBatchApplyResult?.appliedChanges.count ?? 0) > 0)
        XCTAssertTrue(store.dirtySpeciesBatchDrafts.isEmpty)
        let catalog = try XCTUnwrap(store.selectedSpeciesCatalog)
        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        let grovyle = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_GROVYLE" })
        XCTAssertFalse(treecko.learnsets.tmhm.map(\.move).contains("MOVE_CUT"))
        XCTAssertTrue(grovyle.learnsets.tmhm.map(\.move).contains("MOVE_FLASH"))
    }

    @MainActor
    func testFixtureRecordsRemainAvailableWithoutLoadedProject() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        XCTAssertTrue(store.records(for: .scripts).contains { $0.title == "Professor Birch Intro" })
        XCTAssertTrue(store.records(for: .items).contains { $0.title == "Mach Bike" })
    }

    @MainActor
    func testResourceLibraryRefreshesWhenOpeningProjectAndFiltersEntries() async throws {
        let root = try makeSourceIndexProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        XCTAssertNil(store.resourceLibrary)

        store.openProject(path: root.path)

        let library = try XCTUnwrap(store.resourceLibrary)
        let openedEntry = try XCTUnwrap(library.entries.first { $0.path == root.path })
        XCTAssertEqual(openedEntry.detailMode, "summary")
        XCTAssertTrue(openedEntry.items.isEmpty)
        XCTAssertTrue(store.filteredResourceLibraryEntries.contains { $0.path == root.path })
        XCTAssertNil(store.selectedAssetCatalog)
        XCTAssertEqual(store.assetCatalogLoadStatus, .idle)

        store.loadResourceEntryDetails(openedEntry)
        let detailedEntry = try await waitForResourceEntry(store, id: openedEntry.id)
        XCTAssertEqual(detailedEntry.detailMode, "full")
        XCTAssertFalse(detailedEntry.items.isEmpty)
        XCTAssertTrue(detailedEntry.items.contains { $0.path == "Makefile" })

        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        XCTAssertFalse(assetCatalog.rows.isEmpty)
        XCTAssertEqual(store.assetCatalogLoadStatus, .loaded(assetCatalog.assetCount))
        XCTAssertTrue(assetCatalog.rows.contains { $0.path == "Makefile" })
        XCTAssertTrue(assetCatalog.rows.contains { $0.title == "ITEM_POTION" && $0.category == "items" })

        store.searchText = root.lastPathComponent

        XCTAssertEqual(store.filteredResourceLibraryEntries.map(\.path), [root.path])

        store.searchText = "Makefile"

        XCTAssertTrue(store.filteredResourceLibraryEntries.contains { entry in
            entry.items.contains { $0.path == "Makefile" }
        })
        XCTAssertTrue(store.filteredResourceAssetRows.contains { $0.path == "Makefile" })

        store.searchText = "ITEM_POTION"

        XCTAssertTrue(store.filteredResourceAssetRows.allSatisfy { $0.searchBlob.contains("item_potion") })
        XCTAssertTrue(store.filteredResourceAssetRows.contains { $0.category == "items" })

        store.searchText = ""
        store.resourceAssetCategory = "items"
        store.resourceAssetSortMode = .title

        let itemRows = store.filteredResourceAssetRows
        XCTAssertFalse(itemRows.isEmpty)
        XCTAssertTrue(itemRows.allSatisfy { $0.category == "items" })
        XCTAssertEqual(itemRows.map(\.title), itemRows.map(\.title).sorted())
        XCTAssertTrue(itemRows.contains { $0.title == "ITEM_POTION" && $0.availability == "availableSource" })

        store.loadSelectedAssetCatalogIfNeeded()
        XCTAssertEqual(store.assetCatalogLoadStatus, .loaded(assetCatalog.assetCount))
        XCTAssertEqual(store.filteredResourceAssetRows.map(\.id), itemRows.map(\.id))

        store.resourceAssetSortMode = .availability

        XCTAssertFalse(store.filteredResourceAssetRows.isEmpty)
        XCTAssertTrue(store.filteredResourceAssetRows.allSatisfy { $0.category == "items" })
    }

    @MainActor
    func testResourceAssetSelectionSurvivesWorkflowFiltersThatHideTheRow() async throws {
        let root = try makeSourceIndexProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let itemRow = try XCTUnwrap(assetCatalog.rows.first { $0.title == "ITEM_POTION" && $0.category == "items" })

        store.requestResourceAssetSelection(itemRow.id)
        XCTAssertEqual(store.selectedResourceAsset?.id, itemRow.id)

        store.resourceAssetWorkflowFacet = .related

        XCTAssertFalse(store.filteredResourceAssetRows.contains { $0.id == itemRow.id })
        XCTAssertEqual(store.selectedResourceAsset?.id, itemRow.id)

        store.resourceAssetCategory = "maps"

        XCTAssertFalse(store.filteredResourceAssetRows.contains { $0.id == itemRow.id })
        XCTAssertEqual(store.selectedResourceAsset?.id, itemRow.id)
    }

    @MainActor
    func testResourceEntrySelectionHydratesStandaloneGBAAndNDSDetails() async throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let gbaROM = try makeStandaloneGBAROM(named: "Pokemon - Emerald Version (USA, Europe).gba", under: temp.url)
        let ndsROM = try makeStandaloneNDSROM(named: "Pokemon - Diamond Version (USA).nds", under: temp.url)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, workspaceRoot: temp.url, autoLoadProjects: false)

        store.refreshResourceLibrary()
        store.selectedResourceLibraryMode = .entries

        let gbaSummary = try XCTUnwrap(store.resourceLibrary?.entries.first { $0.path == gbaROM.path })
        XCTAssertEqual(gbaSummary.platform, "gbaROM")
        XCTAssertEqual(gbaSummary.detailMode, "summary")
        XCTAssertTrue(gbaSummary.items.isEmpty)

        store.requestResourceLibraryEntrySelection(gbaROM.path)
        XCTAssertEqual(store.selectedResourceLibraryEntryID, gbaSummary.id)
        let gbaEntry = try await waitForResourceEntry(store, id: gbaSummary.id)
        XCTAssertEqual(gbaEntry.detailMode, "full")
        XCTAssertTrue(gbaEntry.items.contains { $0.category == "GBA ROM" })
        XCTAssertTrue(gbaEntry.items.contains { $0.category == "ROM Header" })

        let ndsSummary = try XCTUnwrap(store.resourceLibrary?.entries.first { $0.path == ndsROM.path })
        XCTAssertEqual(ndsSummary.platform, "ndsROM")
        XCTAssertEqual(ndsSummary.detailMode, "summary")
        XCTAssertTrue(ndsSummary.items.isEmpty)

        store.requestResourceLibraryEntrySelection(ndsROM.path)
        XCTAssertEqual(store.selectedResourceLibraryEntryID, ndsSummary.id)
        let ndsEntry = try await waitForResourceEntry(store, id: ndsSummary.id)
        XCTAssertEqual(ndsEntry.detailMode, "full")
        XCTAssertTrue(ndsEntry.items.contains { $0.category == "NitroFS File" })
        XCTAssertTrue(ndsEntry.items.contains { $0.category == "NARC Member" })
    }

    @MainActor
    func testBundledFallbackAppendsNDSSourceEntries() throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let projectsRoot = temp.url.appendingPathComponent("PokemonHackStudioAssets/Projects")
        try makeNDSBlackSourceProject(at: projectsRoot.appendingPathComponent("pokeblack"))
        let baseLibrary = GenIIIResourceLibrary(workspaceRoot: temp.url.path, entries: [], diagnostics: [])

        let library = WorkbenchStore.libraryByAppendingBundledAssets(
            to: baseLibrary,
            projectsRoot: projectsRoot,
            fileManager: .default
        )

        let bundled = try XCTUnwrap(library.entries.first { $0.profile == .pokeblack })
        XCTAssertEqual(bundled.platform, .ndsSource)
        XCTAssertEqual(bundled.family, .blackWhite)
        XCTAssertEqual(bundled.role, .referenceSource)
        XCTAssertEqual(bundled.writePolicy, .readOnly)
        XCTAssertTrue(bundled.title.hasSuffix(" (Bundled)"))
        XCTAssertTrue(bundled.items.contains { $0.category == "NDS Variant" && $0.path == "pokeblack.nds" })
        let whitePath = "unavailable-titles/Pokemon - White Version (USA, Europe) (NDSi Enhanced).nds"
        let whiteReason = "No materialized White source decomp is available in the current central corpus; the available pokeblack tree currently supports black.us only."
        let whiteUnavailable = try XCTUnwrap(bundled.items.first { $0.category == "NDS Data resources" && $0.path == whitePath })
        XCTAssertEqual(whiteUnavailable.kind, "unknown")
        XCTAssertTrue(whiteUnavailable.facts.contains { $0.label == "Gen V Readiness" && $0.value == "unavailable" })
        XCTAssertTrue(whiteUnavailable.facts.contains { $0.label == "Gen V Source Role" && $0.value == "titleUnavailable" })
        XCTAssertTrue(whiteUnavailable.facts.contains { $0.label == "Gen V Unavailable Reason" && $0.value == whiteReason })
        XCTAssertTrue(whiteUnavailable.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("build, playtest, and export actions are disabled") })
        XCTAssertTrue(bundled.items.contains { item in
            item.category == "NDS Data resources"
                && item.facts.contains { $0.label == "Gen V Family" && $0.value == "black2White2" }
                && item.facts.contains { $0.label == "Gen V Source Name" && $0.value == "none" }
        })
    }

    @MainActor
    func testGenVSourceInventoryRowsStayPreviewOnlyInResourcesSelection() async throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent("pokeblack")
        try makeNDSBlackSourceProject(at: root)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let encounterRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "data/encounters/route_1.txt" })
        XCTAssertTrue(encounterRow.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertTrue(encounterRow.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })

        store.requestResourceAssetSelection(encounterRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(editor.recordID.hasSuffix("data/encounters/route_1.txt"))
        XCTAssertFalse(editor.canEdit)
        XCTAssertFalse(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        XCTAssertEqual(editor.lensSummary, "This NDS data row stays read-only in the current Resources editing slice.")
        XCTAssertTrue(editor.blockedReason?.contains("Pokemon Black/White source rows are read-only Gen V readiness metadata") == true)

        store.updateSelectedNDSDataDraftText("changed\n")
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("data/encounters/route_1.txt"), encoding: .utf8),
            "encounter\n"
        )
    }

    @MainActor
    func testGenVManualOnlySourceRootsStayPreviewOnlyInResourcesSelection() async throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent("pokeblack")
        try makeNDSBlackSourceProject(at: root)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let makefileRow = try XCTUnwrap(assetCatalog.rows.first { row in
            row.path == "Makefile"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "buildConfig" }
        })
        XCTAssertTrue(makefileRow.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("build, playtest, and export actions are disabled") })

        let sourceRootRow = try XCTUnwrap(assetCatalog.rows.first { row in
            row.path == "src"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "sourceCodeInventory" }
        })
        XCTAssertEqual(sourceRootRow.sizeSummary, "92 bytes")
        XCTAssertTrue(sourceRootRow.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertEqual(factValue("Gen V Source Root Members", in: sourceRootRow.facts), "5")
        XCTAssertEqual(factValue("Gen V Source Root Bytes", in: sourceRootRow.facts), "92")
        XCTAssertTrue(factValue("Gen V Source Root Sample Paths", in: sourceRootRow.facts)?.contains("src/init.c") == true)
        XCTAssertTrue(factValue("Gen V Source Root Sample Paths", in: sourceRootRow.facts)?.contains("src/data/pokemon/source_pokemon.inc") == true)
        XCTAssertTrue(sourceRootRow.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        XCTAssertFalse(sourceRootRow.facts.contains { $0.label == "Migration Status" })

        let assemblyRootRow = try XCTUnwrap(assetCatalog.rows.first { row in
            row.path == "asm"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "assemblyInventory" }
        })
        XCTAssertEqual(assemblyRootRow.sizeSummary, "5 bytes")
        XCTAssertEqual(factValue("Gen V Assembly Root Members", in: assemblyRootRow.facts), "1")
        XCTAssertEqual(factValue("Gen V Assembly Root Bytes", in: assemblyRootRow.facts), "5")
        XCTAssertEqual(factValue("Gen V Assembly Root Sample Paths", in: assemblyRootRow.facts), "asm/arm9_remaining.s")
        XCTAssertTrue(assemblyRootRow.facts.contains { $0.label == "Gen V Blocked Actions" && $0.value.contains("mutation apply") })
        XCTAssertFalse(assemblyRootRow.facts.contains { $0.label == "Migration Status" })

        let headerRootRow = try XCTUnwrap(assetCatalog.rows.first { row in
            row.path == "include"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "headerInventory" }
        })
        XCTAssertEqual(headerRootRow.sizeSummary, "16 bytes")
        XCTAssertEqual(factValue("Gen V Header Root Members", in: headerRootRow.facts), "1")
        XCTAssertEqual(factValue("Gen V Header Root Bytes", in: headerRootRow.facts), "16")
        XCTAssertEqual(factValue("Gen V Header Root Sample Paths", in: headerRootRow.facts), "include/globals.h")
        XCTAssertFalse(headerRootRow.facts.contains { $0.label == "Migration Status" })

        let blackMarkerRow = try XCTUnwrap(assetCatalog.rows.first { row in
            row.path == "black.us"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "variantSourceInventory" }
        })
        XCTAssertTrue(blackMarkerRow.facts.contains { $0.label == "Gen V Variant ID" && $0.value == "black.us" })
        XCTAssertFalse(blackMarkerRow.facts.contains { $0.label == "Migration Status" })

        store.requestResourceAssetSelection(sourceRootRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "resources:src")
        XCTAssertFalse(editor.canEdit)
        XCTAssertFalse(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        XCTAssertEqual(editor.lensSummary, "This NDS data row stays read-only in the current Resources editing slice.")
        XCTAssertTrue(editor.blockedReason?.contains("Pokemon Black/White source rows are read-only Gen V readiness metadata") == true)

        store.updateSelectedNDSDataDraftText("changed\n")
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent("src/init.c").path))
    }

    @MainActor
    func testGenVDataRootInventoryStaysPreviewOnlyInResourcesSelection() async throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent("pokeblack")
        try makeNDSBlackSourceProject(at: root)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let dataRootRow = try XCTUnwrap(assetCatalog.rows.first { row in
            row.path == "data"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "dataInventory" }
        })
        XCTAssertEqual(dataRootRow.kind, "directory")
        XCTAssertTrue(dataRootRow.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertTrue(dataRootRow.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        XCTAssertFalse(dataRootRow.facts.contains { $0.label == "Migration Status" })
        XCTAssertTrue(assetCatalog.rows.contains { row in
            row.path == "data/encounters/route_1.txt"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "encounterPreview" }
        })

        store.requestResourceAssetSelection(dataRootRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "resources:data")
        XCTAssertFalse(editor.canEdit)
        XCTAssertFalse(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        XCTAssertEqual(editor.lensSummary, "This NDS data row stays read-only in the current Resources editing slice.")
        XCTAssertTrue(editor.blockedReason?.contains("Pokemon Black/White source rows are read-only Gen V readiness metadata") == true)

        store.updateSelectedNDSDataDraftText("changed\n")
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("data/encounters/route_1.txt"), encoding: .utf8),
            "encounter\n"
        )
    }

    @MainActor
    func testGenVSourceDataDomainInventoryStaysPreviewOnlyInResourcesSelection() async throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent("pokeblack")
        try makeNDSBlackSourceProject(at: root)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let samples: [(domainValue: String, root: String, child: String, inventoryRole: String, memberRole: String, category: String, contents: String)] = [
            ("pokemon", "data/pokemon", "data/pokemon/source_pokemon.txt", "pokemonDataInventory", "pokemonDataMember", "species", "pokemon-source\n"),
            ("move", "data/moves", "data/moves/source_moves.txt", "moveDataInventory", "moveDataMember", "moves", "moves-source\n"),
            ("item", "data/items", "data/items/source_items.txt", "itemDataInventory", "itemDataMember", "items", "items-source\n"),
            ("trainer", "data/trainers", "data/trainers/source_trainers.txt", "trainerDataInventory", "trainerDataMember", "trainers", "trainers-source\n"),
            ("pokemon", "src/data/pokemon", "src/data/pokemon/source_pokemon.inc", "pokemonDataInventory", "pokemonDataMember", "species", "pokemon-source-inc\n"),
            ("move", "src/data/moves", "src/data/moves/source_moves.inc", "moveDataInventory", "moveDataMember", "moves", "moves-source-inc\n"),
            ("item", "src/data/items", "src/data/items/source_items.inc", "itemDataInventory", "itemDataMember", "items", "items-source-inc\n"),
            ("trainer", "src/data/trainers", "src/data/trainers/source_trainers.inc", "trainerDataInventory", "trainerDataMember", "trainers", "trainers-source-inc\n")
        ]
        let expectedRelatedRows = "20"
        let allGenVContextDomains = "encounters, items, maps, moves, resources, scripts, species, text, trainers"
        let expectedBlockedActions = "parser, decoded preview, semantic controls, source writes, extraction, NARC packing, build/playtest, ROM export, mutation apply, binary writes"

        for sample in samples {
            let byteCount = sample.contents.utf8.count
            let rootRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == sample.root && $0.category == sample.category })
            XCTAssertEqual(rootRow.kind, "directory")
            XCTAssertEqual(rootRow.sizeSummary, "\(byteCount) bytes")
            XCTAssertEqual(factValue("Gen V Source Role", in: rootRow.facts), sample.inventoryRole)
            XCTAssertEqual(factValue("Gen V Source Data Domain", in: rootRow.facts), sample.domainValue)
            XCTAssertEqual(factValue("Gen V Source Data Root", in: rootRow.facts), sample.root)
            XCTAssertEqual(factValue("Gen V Source Data Members", in: rootRow.facts), "1")
            XCTAssertEqual(factValue("Gen V Source Data Bytes", in: rootRow.facts), "\(byteCount)")
            XCTAssertEqual(factValue("Gen V Source Data Sample Paths", in: rootRow.facts), sample.child)
            XCTAssertEqual(factValue("Gen V Source Data Basis", in: rootRow.facts), "pathFilenameCountBytesOnly")
            XCTAssertEqual(factValue("Gen V Source Data Posture", in: rootRow.facts), "previewOnlyNoParser")
            XCTAssertEqual(factValue("Gen V Source Data Blocked Actions", in: rootRow.facts), expectedBlockedActions)
            XCTAssertEqual(factValue("Gen V Source Data Blocked Reason", in: rootRow.facts), "domainInventoryPreviewOnly")
            XCTAssertEqual(factValue("Related Rows", in: rootRow.facts), expectedRelatedRows)
            XCTAssertEqual(factValue("Related Domains", in: rootRow.facts), allGenVContextDomains)
            XCTAssertEqual(factValue("Readiness", in: rootRow.facts), "partial")
            XCTAssertNil(factValue("Migration Status", in: rootRow.facts))
            XCTAssertNil(factValue("Text Bank Preview", in: rootRow.facts))
            assertNoGenVSourceDataSemanticFacts(rootRow.facts)

            let childRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == sample.child && $0.category == sample.category })
            XCTAssertEqual(childRow.sizeSummary, "\(byteCount) bytes")
            XCTAssertEqual(factValue("Gen V Source Role", in: childRow.facts), sample.memberRole)
            XCTAssertEqual(factValue("Gen V Source Data Domain", in: childRow.facts), sample.domainValue)
            XCTAssertEqual(factValue("Gen V Source Data Root", in: childRow.facts), sample.root)
            XCTAssertEqual(factValue("Gen V Source Data Filename", in: childRow.facts), URL(fileURLWithPath: sample.child).lastPathComponent)
            XCTAssertEqual(factValue("Gen V Source Data Extension", in: childRow.facts), URL(fileURLWithPath: sample.child).pathExtension)
            XCTAssertEqual(factValue("Gen V Source Data Bytes", in: childRow.facts), "\(byteCount)")
            XCTAssertEqual(factValue("Gen V Source Data Basis", in: childRow.facts), "pathFilenameCountBytesOnly")
            XCTAssertEqual(factValue("Gen V Source Data Posture", in: childRow.facts), "previewOnlyNoParser")
            XCTAssertEqual(factValue("Gen V Source Data Blocked Actions", in: childRow.facts), expectedBlockedActions)
            XCTAssertEqual(factValue("Gen V Source Data Blocked Reason", in: childRow.facts), "memberMetadataPreviewOnly")
            XCTAssertNil(factValue("Related Rows", in: childRow.facts))
            XCTAssertNil(factValue("Related Domains", in: childRow.facts))
            XCTAssertNil(factValue("Migration Status", in: childRow.facts))
            XCTAssertNil(factValue("Text Bank Preview", in: childRow.facts))
            assertNoGenVSourceDataSemanticFacts(childRow.facts)
        }

        let selectedPath = "data/pokemon/source_pokemon.txt"
        let selectedRootRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "data/pokemon" && $0.category == "species" })
        let selectedRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == selectedPath && $0.category == "species" })
        let originalContents = try String(contentsOf: root.appendingPathComponent(selectedPath), encoding: .utf8)

        store.requestResourceAssetSelection(selectedRootRow.id)

        var editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "species:data/pokemon")
        XCTAssertFalse(editor.canEdit)
        XCTAssertFalse(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        XCTAssertEqual(editor.lensSummary, "This NDS data row stays read-only in the current Resources editing slice.")
        XCTAssertTrue(editor.blockedReason?.contains("Pokemon Black/White source rows are read-only Gen V readiness metadata") == true)

        store.updateSelectedNDSDataDraftText("changed root\n")
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(selectedPath), encoding: .utf8),
            originalContents
        )

        store.requestResourceAssetSelection(selectedRow.id)

        editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "species:data/pokemon/source_pokemon.txt")
        XCTAssertFalse(editor.canEdit)
        XCTAssertFalse(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        XCTAssertEqual(editor.lensSummary, "This NDS data row stays read-only in the current Resources editing slice.")
        XCTAssertTrue(editor.blockedReason?.contains("Pokemon Black/White source rows are read-only Gen V readiness metadata") == true)

        store.updateSelectedNDSDataDraftText("changed\n")
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(selectedPath), encoding: .utf8),
            originalContents
        )
    }

    @MainActor
    func testGenVSourceDataVariantCoverageStaysPreviewOnlyInResourcesSelection() async throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent("pokeblack")
        try makeNDSBlackSourceProject(at: root)
        try write("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee  pokewhite.nds\n", to: root.appendingPathComponent("white.us/rom.sha1"))
        try write("not-a-sha1\n", to: root.appendingPathComponent("black2.us/rom.sha1"))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let rootRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "data/pokemon" && $0.category == "species" })
        XCTAssertEqual(factValue("Gen V Source Data Variant Coverage", in: rootRow.facts), "3/4")
        XCTAssertEqual(factValue("Gen V Source Data Variant Present", in: rootRow.facts), "black.us, white.us, black2.us")
        XCTAssertEqual(factValue("Gen V Source Data Variant Missing", in: rootRow.facts), "white2.us")
        XCTAssertEqual(factValue("Gen V Source Data Variant Basis", in: rootRow.facts), "sourceMarkersAndRootPresenceOnly")

        let childRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "data/pokemon/source_pokemon.txt" && $0.category == "species" })
        XCTAssertNil(factValue("Gen V Source Data Variant Coverage", in: childRow.facts))
        XCTAssertNil(factValue("Gen V Source Data Variant Present", in: childRow.facts))
        XCTAssertNil(factValue("Gen V Source Data Variant Missing", in: childRow.facts))
        XCTAssertNil(factValue("Gen V Source Data Variant Basis", in: childRow.facts))

        let originalContents = try String(contentsOf: root.appendingPathComponent("data/pokemon/source_pokemon.txt"), encoding: .utf8)
        store.requestResourceAssetSelection(rootRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "species:data/pokemon")
        XCTAssertFalse(editor.canEdit)
        XCTAssertFalse(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        XCTAssertEqual(editor.lensSummary, "This NDS data row stays read-only in the current Resources editing slice.")
        XCTAssertTrue(editor.blockedReason?.contains("Pokemon Black/White source rows are read-only Gen V readiness metadata") == true)

        store.updateSelectedNDSDataDraftText("changed root\n")
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("data/pokemon/source_pokemon.txt"), encoding: .utf8),
            originalContents
        )
    }

    @MainActor
    func testGenVVariantReadinessPacketStaysPreviewOnlyInResourcesSelection() async throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent("pokeblack")
        try makeNDSBlackSourceProject(at: root)
        try write("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee  pokewhite.nds\n", to: root.appendingPathComponent("white.us/rom.sha1"))
        try write("not-a-sha1\n", to: root.appendingPathComponent("black2.us/rom.sha1"))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let packetRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "gen-v/variant-readiness-packet" })
        XCTAssertEqual(packetRow.kind, "unknown")
        XCTAssertEqual(factValue("Gen V Source Role", in: packetRow.facts), "variantReadinessPacket")
        XCTAssertEqual(factValue("Gen V Variant Readiness Packet", in: packetRow.facts), "previewOnly")
        XCTAssertEqual(factValue("Gen V Variant Readiness Basis", in: packetRow.facts), "existingCatalogFactsOnly")
        XCTAssertEqual(factValue("Gen V Variant Readiness Posture", in: packetRow.facts), "previewOnlyNoParserNoWrites")
        XCTAssertEqual(
            factValue("Gen V Variant Marker States", in: packetRow.facts),
            "black.us=sourceMarkerPresent, white.us=sourceMarkerPresent, black2.us=sourceMarkerPresent, white2.us=unavailable"
        )
        XCTAssertEqual(
            factValue("Gen V SHA1 Text States", in: packetRow.facts),
            "black.us=valid, white.us=valid, black2.us=invalid, white2.us=missing"
        )
        XCTAssertEqual(
            factValue("Gen V Message Summary", in: packetRow.facts),
            "candidates=6, extensions=bin, dat, gmm, msg, str, txt, noDecodedPreviewRows=6"
        )
        XCTAssertTrue(factValue("Gen V Build Metadata Summary", in: packetRow.facts)?.contains("Makefile=present") == true)
        XCTAssertNil(factValue("Migration Status", in: packetRow.facts))
        XCTAssertNil(factValue("Text Bank Preview", in: packetRow.facts))

        store.requestResourceAssetSelection(packetRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "resources:gen-v/variant-readiness-packet")
        XCTAssertFalse(editor.canEdit)
        XCTAssertFalse(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        XCTAssertEqual(editor.lensSummary, "This NDS data row stays read-only in the current Resources editing slice.")
        XCTAssertTrue(editor.blockedReason?.contains("Pokemon Black/White source rows are read-only Gen V readiness metadata") == true)

        let copyCommand = try XCTUnwrap(store.workbenchCommands.first { $0.id == "copy:resource-readiness-packet-json" })
        XCTAssertTrue(copyCommand.availability.isEnabled)

        NSPasteboard.general.clearContents()
        store.executeCommand(copyCommand)

        let packetJSON = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let packetData = try XCTUnwrap(packetJSON.data(using: .utf8))
        let packetObject = try JSONSerialization.jsonObject(with: packetData) as? [String: Any]
        let assetObject = try XCTUnwrap(packetObject?["asset"] as? [String: Any])
        XCTAssertEqual(assetObject["path"] as? String, "gen-v/variant-readiness-packet")
        let readinessObject = try XCTUnwrap(packetObject?["ndsReadiness"] as? [String: Any])
        XCTAssertEqual(readinessObject["recordID"] as? String, "resources:gen-v/variant-readiness-packet")
        XCTAssertEqual(readinessObject["canEdit"] as? Bool, false)
        XCTAssertEqual(readinessObject["canPreview"] as? Bool, false)
        XCTAssertEqual(readinessObject["canApply"] as? Bool, false)
        XCTAssertTrue((readinessObject["blockedReason"] as? String)?.contains("Pokemon Black/White source rows are read-only Gen V readiness metadata") == true)

        store.updateSelectedNDSDataDraftText("changed\n")
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("gen-v/variant-readiness-packet").path))
    }

    @MainActor
    func testGenVGeneratedOutputFreshnessPacketStaysPreviewOnlyInResourcesSelection() async throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent("pokeblack")
        try makeNDSBlackSourceProject(at: root)
        try write("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee  pokewhite.nds\n", to: root.appendingPathComponent("white.us/rom.sha1"))
        try write("not-a-sha1\n", to: root.appendingPathComponent("black2.us/rom.sha1"))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let packetRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "gen-v/generated-output-freshness-packet" })
        XCTAssertEqual(packetRow.kind, "unknown")
        XCTAssertEqual(factValue("Gen V Source Role", in: packetRow.facts), "generatedOutputFreshnessPacket")
        XCTAssertEqual(factValue("Gen V Generated Output Freshness Packet", in: packetRow.facts), "previewOnly")
        XCTAssertEqual(factValue("Gen V Generated Output Freshness Basis", in: packetRow.facts), "existingCatalogAndBuildValidationFactsOnly")
        XCTAssertEqual(factValue("Gen V Generated Output Freshness Posture", in: packetRow.facts), "previewOnlyNoBuildNoGeneratedOutputWrites")
        XCTAssertEqual(
            factValue("Gen V Source Marker States", in: packetRow.facts),
            "black.us=sourceMarkerPresent, white.us=sourceMarkerPresent, black2.us=sourceMarkerPresent, white2.us=unavailable"
        )
        XCTAssertEqual(
            factValue("Gen V SHA1 Text States", in: packetRow.facts),
            "black.us=valid, white.us=valid, black2.us=invalid, white2.us=missing"
        )
        XCTAssertTrue(factValue("Gen V Build Metadata Summary", in: packetRow.facts)?.contains("Makefile=present") == true)
        XCTAssertTrue(factValue("Gen V Variant Readiness Summary", in: packetRow.facts)?.contains("packet=present") == true)
        XCTAssertTrue(factValue("Gen V Declared Generated Outputs", in: packetRow.facts)?.contains("pokeblack.nds=missing") == true)
        XCTAssertTrue(factValue("Gen V Build Target Output Freshness", in: packetRow.facts)?.contains("black-rom:pokeblack.nds=missing") == true)
        XCTAssertTrue(factValue("Gen V Build Target Output Freshness", in: packetRow.facts)?.contains("freshness=outputMissing") == true)
        XCTAssertNil(factValue("Migration Status", in: packetRow.facts))
        XCTAssertNil(factValue("Text Bank Preview", in: packetRow.facts))

        store.requestResourceAssetSelection(packetRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "resources:gen-v/generated-output-freshness-packet")
        XCTAssertFalse(editor.canEdit)
        XCTAssertFalse(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        XCTAssertEqual(editor.lensSummary, "This NDS data row stays read-only in the current Resources editing slice.")
        XCTAssertTrue(editor.blockedReason?.contains("Pokemon Black/White source rows are read-only Gen V readiness metadata") == true)

        let copyCommand = try XCTUnwrap(store.workbenchCommands.first { $0.id == "copy:resource-readiness-packet-json" })
        XCTAssertTrue(copyCommand.availability.isEnabled)

        NSPasteboard.general.clearContents()
        store.executeCommand(copyCommand)

        let packetJSON = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let packetData = try XCTUnwrap(packetJSON.data(using: .utf8))
        let packetObject = try JSONSerialization.jsonObject(with: packetData) as? [String: Any]
        let assetObject = try XCTUnwrap(packetObject?["asset"] as? [String: Any])
        XCTAssertEqual(assetObject["path"] as? String, "gen-v/generated-output-freshness-packet")
        let readinessObject = try XCTUnwrap(packetObject?["ndsReadiness"] as? [String: Any])
        XCTAssertEqual(readinessObject["recordID"] as? String, "resources:gen-v/generated-output-freshness-packet")
        XCTAssertEqual(readinessObject["canEdit"] as? Bool, false)
        XCTAssertEqual(readinessObject["canPreview"] as? Bool, false)
        XCTAssertEqual(readinessObject["canApply"] as? Bool, false)
        XCTAssertTrue((readinessObject["blockedReason"] as? String)?.contains("Pokemon Black/White source rows are read-only Gen V readiness metadata") == true)

        store.updateSelectedNDSDataDraftText("changed\n")
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("gen-v/generated-output-freshness-packet").path))
    }

    @MainActor
    func testGenVBlockedActionAuditPacketStaysPreviewOnlyInResourcesSelection() async throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent("pokeblack")
        try makeNDSBlackSourceProject(at: root)
        try write("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee  pokewhite.nds\n", to: root.appendingPathComponent("white.us/rom.sha1"))
        try write("not-a-sha1\n", to: root.appendingPathComponent("black2.us/rom.sha1"))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let packetRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "gen-v/blocked-action-audit-packet" })
        XCTAssertEqual(packetRow.kind, "unknown")
        XCTAssertEqual(factValue("Gen V Source Role", in: packetRow.facts), "blockedActionAuditPacket")
        XCTAssertEqual(factValue("Gen V Blocked Action Audit Packet", in: packetRow.facts), "previewOnly")
        XCTAssertEqual(factValue("Gen V Blocked Action Audit Basis", in: packetRow.facts), "existingReadinessBlockedActionsAndDiagnosticsOnly")
        XCTAssertEqual(factValue("Gen V Blocked Action Audit Posture", in: packetRow.facts), "previewOnlyNoParserNoWritesNoExecution")
        XCTAssertTrue(factValue("Gen V Readiness Status Summary", in: packetRow.facts)?.contains("partial=") == true)
        XCTAssertTrue(factValue("Gen V Unique Blocked Actions", in: packetRow.facts)?.contains("binary write") == true)
        XCTAssertTrue(factValue("Gen V Unique Blocked Actions", in: packetRow.facts)?.contains("source writes") == true)
        XCTAssertTrue(factValue("Gen V Diagnostic Code Summary", in: packetRow.facts)?.contains("NDS_GEN_V_WRITE_BLOCKED") == true)
        XCTAssertTrue(factValue("Gen V Prior Packet Coverage", in: packetRow.facts)?.contains("gen-v/variant-readiness-packet=present") == true)
        XCTAssertNil(factValue("Migration Status", in: packetRow.facts))
        XCTAssertNil(factValue("Text Bank Preview", in: packetRow.facts))

        store.requestResourceAssetSelection(packetRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "resources:gen-v/blocked-action-audit-packet")
        XCTAssertFalse(editor.canEdit)
        XCTAssertFalse(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        XCTAssertEqual(editor.lensSummary, "This NDS data row stays read-only in the current Resources editing slice.")
        XCTAssertTrue(editor.blockedReason?.contains("Pokemon Black/White source rows are read-only Gen V readiness metadata") == true)

        let copyCommand = try XCTUnwrap(store.workbenchCommands.first { $0.id == "copy:resource-readiness-packet-json" })
        XCTAssertTrue(copyCommand.availability.isEnabled)

        NSPasteboard.general.clearContents()
        store.executeCommand(copyCommand)

        let packetJSON = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let packetData = try XCTUnwrap(packetJSON.data(using: .utf8))
        let packetObject = try JSONSerialization.jsonObject(with: packetData) as? [String: Any]
        let assetObject = try XCTUnwrap(packetObject?["asset"] as? [String: Any])
        XCTAssertEqual(assetObject["path"] as? String, "gen-v/blocked-action-audit-packet")
        let readinessObject = try XCTUnwrap(packetObject?["ndsReadiness"] as? [String: Any])
        XCTAssertEqual(readinessObject["recordID"] as? String, "resources:gen-v/blocked-action-audit-packet")
        XCTAssertEqual(readinessObject["canEdit"] as? Bool, false)
        XCTAssertEqual(readinessObject["canPreview"] as? Bool, false)
        XCTAssertEqual(readinessObject["canApply"] as? Bool, false)
        XCTAssertTrue((readinessObject["blockedReason"] as? String)?.contains("Pokemon Black/White source rows are read-only Gen V readiness metadata") == true)

        store.updateSelectedNDSDataDraftText("changed\n")
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("gen-v/blocked-action-audit-packet").path))
    }

    @MainActor
    func testGenVNitroArchiveGroupInventoryStaysPreviewOnlyInResourcesSelection() async throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent("pokeblack")
        try makeNDSBlackSourceProject(at: root)
        let archiveGroupChild = root.appendingPathComponent("files/a/0/0/0/resource.bin")
        try write(Data([0x2A]), to: archiveGroupChild)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let archiveGroupRootRow = try XCTUnwrap(assetCatalog.rows.first { row in
            row.path == "files/a"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "nitroArchiveGroupInventory" }
        })
        XCTAssertEqual(archiveGroupRootRow.kind, "directory")
        XCTAssertTrue(archiveGroupRootRow.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertTrue(archiveGroupRootRow.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        XCTAssertFalse(archiveGroupRootRow.facts.contains { $0.label == "Migration Status" })
        XCTAssertTrue(assetCatalog.rows.contains { row in
            row.path == "files/a/0/0/0/resource.bin"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "nitroArchiveGroup" }
        })

        store.requestResourceAssetSelection(archiveGroupRootRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "resources:files/a")
        XCTAssertFalse(editor.canEdit)
        XCTAssertFalse(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        XCTAssertEqual(editor.lensSummary, "This NDS data row stays read-only in the current Resources editing slice.")
        XCTAssertTrue(editor.blockedReason?.contains("Pokemon Black/White source rows are read-only Gen V readiness metadata") == true)

        store.updateSelectedNDSDataDraftText("changed\n")
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(try Data(contentsOf: archiveGroupChild), Data([0x2A]))
    }

    @MainActor
    func testGenVNitroFSRootInventoryStaysPreviewOnlyInResourcesSelection() async throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent("pokeblack")
        try makeNDSBlackSourceProject(at: root)
        let archiveGroupChild = root.appendingPathComponent("files/a/0/0/0/resource.bin")
        try write(Data([0x2A]), to: archiveGroupChild)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let filesRootRow = try XCTUnwrap(assetCatalog.rows.first { row in
            row.path == "files"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "nitroFSRootInventory" }
        })
        XCTAssertEqual(filesRootRow.kind, "directory")
        let shallowCount = Int(filesRootRow.facts.first { $0.label == "Shallow Count" }?.value ?? "0") ?? 0
        XCTAssertGreaterThanOrEqual(shallowCount, 8)
        XCTAssertTrue(filesRootRow.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertTrue(filesRootRow.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        XCTAssertFalse(filesRootRow.facts.contains { $0.label == "Migration Status" })
        XCTAssertFalse(filesRootRow.facts.contains { $0.label == "Text Bank Preview" })
        XCTAssertTrue(assetCatalog.rows.contains { row in
            row.path == "files/a/0/0/0/resource.bin"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "nitroArchiveGroup" }
        })
        XCTAssertTrue(assetCatalog.rows.contains { row in
            row.path == "files/msgdata/story/message_bank.txt"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "messageBankMetadata" }
        })
        XCTAssertTrue(assetCatalog.rows.contains { row in
            row.path == "files/wb_sound_data.sdat"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "soundArchiveMetadata" }
        })

        store.requestResourceAssetSelection(filesRootRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "resources:files")
        XCTAssertFalse(editor.canEdit)
        XCTAssertFalse(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        XCTAssertEqual(editor.lensSummary, "This NDS data row stays read-only in the current Resources editing slice.")
        XCTAssertTrue(editor.blockedReason?.contains("Pokemon Black/White source rows are read-only Gen V readiness metadata") == true)

        store.updateSelectedNDSDataDraftText("changed\n")
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(try Data(contentsOf: archiveGroupChild), Data([0x2A]))
    }

    @MainActor
    func testGenVFielddataInventoryStaysPreviewOnlyInResourcesSelection() async throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent("pokeblack")
        try makeNDSBlackSourceProject(at: root)
        let mapMatrixChild = root.appendingPathComponent("files/fielddata/mapmatrix/0001.bin")
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let fielddataRootRow = try XCTUnwrap(assetCatalog.rows.first { row in
            row.path == "files/fielddata"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "fielddataInventory" }
        })
        XCTAssertEqual(fielddataRootRow.kind, "directory")
        XCTAssertTrue(fielddataRootRow.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertTrue(fielddataRootRow.facts.contains { $0.label == "Gen V Blocked Actions" && $0.value.contains("NARC pack") })
        XCTAssertTrue(fielddataRootRow.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        XCTAssertFalse(fielddataRootRow.facts.contains { $0.label == "Migration Status" })

        XCTAssertTrue(assetCatalog.rows.contains { row in
            row.path == "files/fielddata/mapmatrix"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "fielddataMapMatrixInventory" }
        })
        XCTAssertTrue(assetCatalog.rows.contains { row in
            row.path == "files/fielddata/mapmatrix/0001.bin"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "fielddataMapMatrixMember" }
        })
        XCTAssertTrue(assetCatalog.rows.contains { row in
            row.path == "files/fielddata/maptable"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "fielddataMapTableInventory" }
        })
        XCTAssertTrue(assetCatalog.rows.contains { row in
            row.path == "files/fielddata/maptable/map.bin"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "fielddataMapTableMember" }
        })
        XCTAssertTrue(assetCatalog.rows.contains { row in
            row.path == "files/fielddata/script"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "fielddataScriptInventory" }
        })
        XCTAssertTrue(assetCatalog.rows.contains { row in
            row.path == "files/fielddata/script/scr_seq/0001.bin"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "fielddataScriptMember" }
        })
        XCTAssertTrue(assetCatalog.rows.contains { row in
            row.path == "files/fielddata/eventdata/zone_event"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "fielddataZoneEventInventory" }
        })
        XCTAssertTrue(assetCatalog.rows.contains { row in
            row.path == "files/fielddata/eventdata/zone_event/zone_001.json"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "fielddataZoneEventMetadata" }
        })

        store.requestResourceAssetSelection(fielddataRootRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "resources:files/fielddata")
        XCTAssertFalse(editor.canEdit)
        XCTAssertFalse(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        XCTAssertEqual(editor.lensSummary, "This NDS data row stays read-only in the current Resources editing slice.")
        XCTAssertTrue(editor.blockedReason?.contains("Pokemon Black/White source rows are read-only Gen V readiness metadata") == true)

        store.updateSelectedNDSDataDraftText("changed\n")
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(try Data(contentsOf: mapMatrixChild), Data([0x10]))
    }

    @MainActor
    func testGenVMessageBankInventoryStaysPreviewOnlyInResourcesSelection() async throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent("pokeblack")
        try makeNDSBlackSourceProject(at: root)
        let messageBankChild = root.appendingPathComponent("files/msgdata/story/message_bank.txt")
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let messageBankRootRow = try XCTUnwrap(assetCatalog.rows.first { row in
            row.path == "files/msgdata"
                && row.category == "text"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "messageBankInventory" }
        })
        XCTAssertEqual(messageBankRootRow.kind, "directory")
        XCTAssertTrue(messageBankRootRow.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertTrue(messageBankRootRow.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        XCTAssertFalse(messageBankRootRow.facts.contains { $0.label == "Migration Status" })
        XCTAssertFalse(messageBankRootRow.facts.contains { $0.label == "Text Bank Preview" })
        XCTAssertTrue(assetCatalog.rows.contains { row in
            row.path == "files/msgdata/story/message_bank.txt"
                && row.category == "source"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "messageBankMetadata" }
                && !row.facts.contains { $0.label == "Text Bank Preview" }
        })

        store.requestResourceAssetSelection(messageBankRootRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "text:files/msgdata")
        XCTAssertFalse(editor.canEdit)
        XCTAssertFalse(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        XCTAssertEqual(editor.lensSummary, "This NDS data row stays read-only in the current Resources editing slice.")
        XCTAssertTrue(editor.blockedReason?.contains("Pokemon Black/White source rows are read-only Gen V readiness metadata") == true)

        store.updateSelectedNDSDataDraftText("changed\n")
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(
            try String(contentsOf: messageBankChild, encoding: .utf8),
            "Route 1 hello\n"
        )
    }

    @MainActor
    func testGenVOverlayAndDisassemblyConfigInventoryStayPreviewOnlyInResourcesSelection() async throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent("pokeblack")
        try makeNDSBlackSourceProject(at: root)
        let overlaySource = root.appendingPathComponent("overlays/overlay_93/source.s")
        let configSource = root.appendingPathComponent("ndsdisasm_config/ARM9.cfg")
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let overlayRootRow = try XCTUnwrap(assetCatalog.rows.first { row in
            row.path == "overlays"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "overlayInventory" }
        })
        XCTAssertEqual(overlayRootRow.kind, "directory")
        XCTAssertTrue(overlayRootRow.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertTrue(overlayRootRow.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        XCTAssertFalse(overlayRootRow.facts.contains { $0.label == "Migration Status" })
        XCTAssertTrue(assetCatalog.rows.contains { row in
            row.path == "overlays/overlay_93/source.s"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "overlayRouting" }
        })

        let configRootRow = try XCTUnwrap(assetCatalog.rows.first { row in
            row.path == "ndsdisasm_config"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "disassemblyConfigInventory" }
        })
        XCTAssertEqual(configRootRow.kind, "directory")
        XCTAssertTrue(configRootRow.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertTrue(configRootRow.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        XCTAssertFalse(configRootRow.facts.contains { $0.label == "Migration Status" })
        XCTAssertTrue(assetCatalog.rows.contains { row in
            row.path == "ndsdisasm_config/ARM9.cfg"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "disassemblyConfig" }
        })

        store.requestResourceAssetSelection(overlayRootRow.id)

        let overlayEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(overlayEditor.recordID, "scripts:overlays")
        XCTAssertFalse(overlayEditor.canEdit)
        XCTAssertFalse(overlayEditor.canPreview)
        XCTAssertFalse(overlayEditor.canApply)
        XCTAssertEqual(overlayEditor.lensSummary, "This NDS data row stays read-only in the current Resources editing slice.")
        XCTAssertTrue(overlayEditor.blockedReason?.contains("Pokemon Black/White source rows are read-only Gen V readiness metadata") == true)

        store.updateSelectedNDSDataDraftText("changed overlay\n")
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)

        store.requestResourceAssetSelection(configRootRow.id)

        let configEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(configEditor.recordID, "resources:ndsdisasm_config")
        XCTAssertFalse(configEditor.canEdit)
        XCTAssertFalse(configEditor.canPreview)
        XCTAssertFalse(configEditor.canApply)
        XCTAssertEqual(configEditor.lensSummary, "This NDS data row stays read-only in the current Resources editing slice.")
        XCTAssertTrue(configEditor.blockedReason?.contains("Pokemon Black/White source rows are read-only Gen V readiness metadata") == true)

        store.updateSelectedNDSDataDraftText("changed config\n")
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(try String(contentsOf: overlaySource, encoding: .utf8), "overlay\n")
        XCTAssertEqual(try String(contentsOf: configSource, encoding: .utf8), "config\n")
    }

    @MainActor
    func testGenVSoundAndContainerRowsStayManualOnlyInResourcesSelection() async throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent("pokeblack")
        try makeNDSBlackSourceProject(at: root)
        let nestedSDAT = root.appendingPathComponent("files/sound/bgm/main.sdat")
        let soundNARC = root.appendingPathComponent("files/sound/bgm/sound_bank.narc")
        let boundedContainer = root.appendingPathComponent("files/system/container.narc")
        let archiveGroupChild = root.appendingPathComponent("files/a/0/0/0/resource.bin")
        let nestedSDATData = Data("SDAT".utf8) + Data(repeating: 0, count: 12)
        let soundNARCData = makeTestNARC()
        let boundedContainerData = makeTestNARC()
        try write(nestedSDATData, to: nestedSDAT)
        try write(soundNARCData, to: soundNARC)
        try write(boundedContainerData, to: boundedContainer)
        try write(Data([0x2A]), to: archiveGroupChild)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let nestedSDATRow = try XCTUnwrap(assetCatalog.rows.first { row in
            row.category == "audio"
                && row.path == "files/sound/bgm/main.sdat"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "soundArchiveMetadata" }
        })
        XCTAssertTrue(nestedSDATRow.facts.contains { $0.label == "Audio Preview" && $0.value == "ready" })
        XCTAssertTrue(nestedSDATRow.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })

        let soundNARCRow = try XCTUnwrap(assetCatalog.rows.first { row in
            row.category == "audio"
                && row.path == "files/sound/bgm/sound_bank.narc"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "soundContainerRoute" }
        })
        XCTAssertTrue(soundNARCRow.facts.contains { $0.label == "Members" && $0.value == "2" })
        XCTAssertTrue(soundNARCRow.facts.contains { $0.label == "Gen V Blocked Actions" && $0.value.contains("NARC pack") })

        let boundedContainerRow = try XCTUnwrap(assetCatalog.rows.first { row in
            row.category == "source"
                && row.path == "files/system/container.narc"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "boundedContainerSummary" }
        })
        XCTAssertTrue(boundedContainerRow.facts.contains { $0.label == "Members" && $0.value == "2" })
        XCTAssertTrue(assetCatalog.rows.contains { row in
            row.path == "files/a/0/0/0/resource.bin"
                && row.facts.contains { $0.label == "Gen V Source Role" && $0.value == "nitroArchiveGroup" }
        })

        store.requestResourceAssetSelection(nestedSDATRow.id)
        var editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "audio:files/sound/bgm/main.sdat")
        XCTAssertFalse(editor.canEdit)
        XCTAssertFalse(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        XCTAssertTrue(editor.blockedReason?.contains("Pokemon Black/White source rows are read-only Gen V readiness metadata") == true)
        store.updateSelectedNDSDataDraftText("changed\n")
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)

        store.requestResourceAssetSelection(soundNARCRow.id)
        editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "audio:files/sound/bgm/sound_bank.narc")
        XCTAssertFalse(editor.canEdit)
        XCTAssertFalse(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        store.updateSelectedNDSDataDraftText("changed\n")
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)

        store.requestResourceAssetSelection(boundedContainerRow.id)
        editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "resources:files/system/container.narc")
        XCTAssertFalse(editor.canEdit)
        XCTAssertFalse(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        store.updateSelectedNDSDataDraftText("changed\n")
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(try Data(contentsOf: nestedSDAT), nestedSDATData)
        XCTAssertEqual(try Data(contentsOf: soundNARC), soundNARCData)
        XCTAssertEqual(try Data(contentsOf: boundedContainer), boundedContainerData)
        XCTAssertEqual(try Data(contentsOf: archiveGroupChild), Data([0x2A]))
    }

    @MainActor
    func testNDSSourceProjectStaysReadOnlyInProjectAndResourceSummaries() async throws {
        let root = try makeNDSSourceProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)

        let project = try XCTUnwrap(store.selectedIndexedProject)
        XCTAssertEqual(project.profile, "pokediamond")
        XCTAssertEqual(project.originLabel, "Local Source")
        XCTAssertEqual(project.writePolicy, "readOnly")
        XCTAssertTrue(project.menuSubtitle.contains("Read-only NDS source root"))
        XCTAssertTrue(project.sourceSurfaces.contains { $0.source.path == "Makefile" })
        XCTAssertTrue(store.selectedRunnableBuildTargets.isEmpty)
        XCTAssertFalse(store.canRunSelectedDecompBuild)

        let summaryEntry = try XCTUnwrap(store.resourceLibrary?.entries.first { $0.path == root.path })
        XCTAssertEqual(summaryEntry.detailMode, "summary")
        XCTAssertTrue(summaryEntry.items.isEmpty)
        store.loadResourceEntryDetails(summaryEntry)
        let entry = try await waitForResourceEntry(store, id: summaryEntry.id)
        XCTAssertEqual(entry.platform, "ndsSource")
        XCTAssertEqual(entry.role, "editableSource")
        XCTAssertEqual(entry.writePolicy, "readOnly")
        XCTAssertTrue(entry.items.contains { $0.path == "filesystem.mk" && $0.category.hasPrefix("NDS ") })
        XCTAssertTrue(entry.items.contains { $0.path == "arm9/src/pokemon.c" && $0.category == "NDS Data species" })
        let matrixRootItem = try XCTUnwrap(entry.items.first { $0.path == "files/fielddata/mapmatrix" && $0.category == "NDS Data maps" })
        XCTAssertTrue(matrixRootItem.facts.contains { $0.label == "Gen IV Source Role" && $0.value == "dpMapMatrixInventory" })
        XCTAssertTrue(matrixRootItem.facts.contains { $0.label == "Gen IV Action State" && $0.value.contains("inventory-only map metadata") })
        XCTAssertTrue(entry.items.contains { $0.path == "files/fielddata/mapmatrix/matrix.bin" && $0.category == "NDS Data maps" })
        let tableRootItem = try XCTUnwrap(entry.items.first { $0.path == "files/fielddata/maptable" && $0.category == "NDS Data maps" })
        XCTAssertTrue(tableRootItem.facts.contains { $0.label == "Gen IV Source Role" && $0.value == "dpMapTableInventory" })
        let landRootItem = try XCTUnwrap(entry.items.first { $0.path == "files/fielddata/land_data" && $0.category == "NDS Data maps" })
        XCTAssertTrue(landRootItem.facts.contains { $0.label == "Gen IV Source Role" && $0.value == "dpLandDataInventory" })
        let areaRootItem = try XCTUnwrap(entry.items.first { $0.path == "files/fielddata/areadata" && $0.category == "NDS Data maps" })
        XCTAssertTrue(areaRootItem.facts.contains { $0.label == "Gen IV Source Role" && $0.value == "dpAreaDataInventory" })
        XCTAssertTrue(store.filteredResourceLibraryEntries.contains { $0.id == entry.id })

        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        XCTAssertTrue(assetCatalog.rows.contains { $0.path == "arm9/src/pokemon.c" && $0.category == "species" })
        let matrixRootAsset = try XCTUnwrap(assetCatalog.rows.first { $0.path == "files/fielddata/mapmatrix" && $0.category == "maps" })
        XCTAssertTrue(matrixRootAsset.facts.contains { $0.label == "Gen IV Source Role" && $0.value == "dpMapMatrixInventory" })
        XCTAssertTrue(assetCatalog.rows.contains { $0.path == "files/fielddata/mapmatrix/matrix.bin" && $0.category == "maps" })
        let tableRootAsset = try XCTUnwrap(assetCatalog.rows.first { $0.path == "files/fielddata/maptable" && $0.category == "maps" })
        XCTAssertTrue(tableRootAsset.facts.contains { $0.label == "Gen IV Source Role" && $0.value == "dpMapTableInventory" })
        let landRootAsset = try XCTUnwrap(assetCatalog.rows.first { $0.path == "files/fielddata/land_data" && $0.category == "maps" })
        XCTAssertTrue(landRootAsset.facts.contains { $0.label == "Gen IV Source Role" && $0.value == "dpLandDataInventory" })
        let areaRootAsset = try XCTUnwrap(assetCatalog.rows.first { $0.path == "files/fielddata/areadata" && $0.category == "maps" })
        XCTAssertTrue(areaRootAsset.facts.contains { $0.label == "Gen IV Source Role" && $0.value == "dpAreaDataInventory" })
        XCTAssertFalse(entry.moduleSummary.contains("pokemon"))
    }

    @MainActor
    func testResourceDetailHydrationIgnoresStaleSelectionResults() async throws {
        let root = try makeNDSSourceProject()
        for index in 0 ..< 500 {
            try write(
                "{\"base_hp\":\(index),\"attack\":\(index + 1)}\n",
                to: root.appendingPathComponent("files/poketool/personal/personal_\(String(format: "%04d", index)).json")
            )
        }
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        let summaryEntry = try XCTUnwrap(store.resourceLibrary?.entries.first { $0.path == root.path })
        store.requestResourceLibraryEntrySelection(summaryEntry.id)

        store.loadResourceEntryDetails(summaryEntry)
        XCTAssertEqual(store.loadingResourceLibraryEntryID, summaryEntry.id)

        store.requestResourceLibraryEntrySelection("other-resource-entry")
        XCTAssertNil(store.loadingResourceLibraryEntryID)

        try await Task.sleep(nanoseconds: 750_000_000)
        let retainedEntry = try XCTUnwrap(store.resourceLibrary?.entries.first { $0.id == summaryEntry.id })
        XCTAssertEqual(retainedEntry.detailMode, "summary")
        XCTAssertTrue(retainedEntry.items.isEmpty)
    }

    @MainActor
    func testNDSToolchainHealthAppSliceGroupsRowsAndKeepsActionsManualOnly() throws {
        let root = try makeNDSSourceProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)

        let report = try XCTUnwrap(store.selectedBuildReport)
        XCTAssertTrue(report.isNDS)
        XCTAssertTrue(store.selectedRunnableBuildTargets.isEmpty)
        XCTAssertFalse(store.canRunSelectedDecompBuild)

        let actionStates = Dictionary(uniqueKeysWithValues: store.buildWorkflowActions(includePatchActions: true).map { ($0.id, $0.isEnabled) })
        XCTAssertEqual(actionStates["build-rom"], false)
        XCTAssertEqual(actionStates["open-playtest"], false)
        XCTAssertEqual(actionStates["capture-screenshot"], false)
        XCTAssertEqual(actionStates["capture-savestate"], false)
        let actionReasons = Dictionary(uniqueKeysWithValues: store.buildWorkflowActions(includePatchActions: true).map { ($0.id, $0.disabledReason) })
        XCTAssertTrue(actionReasons["build-rom"]??.contains("No runnable declared make target") == true)
        XCTAssertTrue(actionReasons["open-playtest"]??.contains("ROM output and emulator") == true)
        XCTAssertTrue(actionReasons["apply-patch"]??.contains("compatible BPS or IPS patch") == true)

        let groupTitles = Set(report.healthMatrix.ndsGroups.map(\.title))
        XCTAssertTrue(groupTitles.contains("Build SDKs"), "\(groupTitles)")
        XCTAssertTrue(groupTitles.contains("Packaging/Inspection"), "\(groupTitles)")
        XCTAssertTrue(groupTitles.contains("Python/ndspy-compatible"), "\(groupTitles)")
        XCTAssertTrue(groupTitles.contains("Manual Emulators"), "\(groupTitles)")
        XCTAssertTrue(groupTitles.contains("Reference Tools"), "\(groupTitles)")
        XCTAssertTrue(groupTitles.contains("Headers"), "\(groupTitles)")
        XCTAssertTrue(groupTitles.contains("Declared Outputs"), "\(groupTitles)")

        let groupedRows = report.healthMatrix.ndsGroups.flatMap(\.rows)
        XCTAssertTrue(groupedRows.contains { $0.title == "devkitPro" })
        XCTAssertTrue(groupedRows.contains { $0.title == "BlocksDS Docker image" })
        XCTAssertTrue(groupedRows.contains { $0.title == "ndstool" })
        XCTAssertTrue(groupedRows.contains { $0.title == "ndspy" || $0.title == "python3" })
        XCTAssertTrue(groupedRows.contains { $0.title == "melonDS" })
        XCTAssertTrue(groupedRows.contains { $0.title == "DeSmuME" })
        XCTAssertTrue(groupedRows.contains { $0.healthCategory == .romHeaders })
        XCTAssertTrue(groupedRows.contains { $0.healthCategory == .generatedArtifacts })

        let actionRows = store.selectedNDSHealthActionRows
        XCTAssertFalse(actionRows.isEmpty)
        XCTAssertTrue(actionRows.flatMap(\.actions).allSatisfy { $0.copyValue != nil || $0.kind == .rerunGuidance })
    }

    @MainActor
    func testPokeBlackManualBuildReadinessRowsStayCopyOnlyInBuildWorkbench() throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent("pokeblack")
        try makeNDSBlackSourceProject(at: root)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)

        let report = try XCTUnwrap(store.selectedBuildReport)
        XCTAssertTrue(report.isNDS)
        XCTAssertTrue(store.selectedRunnableBuildTargets.isEmpty)
        XCTAssertFalse(store.canRunSelectedDecompBuild)
        XCTAssertFalse(store.canLaunchSelectedPlaytest)
        let actionStates = Dictionary(uniqueKeysWithValues: store.buildWorkflowActions(includePatchActions: true).map { ($0.id, $0.isEnabled) })
        XCTAssertEqual(actionStates["build-rom"], false)
        XCTAssertEqual(actionStates["open-playtest"], false)

        let genVGroup = try XCTUnwrap(report.healthMatrix.ndsGroups.first { $0.title == "Gen V Manual Build Readiness" })
        XCTAssertEqual(
            Set(genVGroup.rows.map(\.id)),
            [
                "health:gen-v-build-readiness:metadata",
                "health:gen-v-build-readiness:source-roots",
                "health:gen-v-build-readiness:variant-sha1",
                "health:gen-v-build-readiness:generated-output"
            ]
        )
        XCTAssertTrue(genVGroup.rows.allSatisfy { $0.section == .healthMatrix })
        XCTAssertTrue(genVGroup.rows.allSatisfy { $0.healthCategory == .generatedArtifacts })
        XCTAssertTrue(genVGroup.rows.flatMap(\.actions).allSatisfy { $0.copyValue != nil || $0.kind == .rerunGuidance })

        let metadata = try XCTUnwrap(genVGroup.rows.first { $0.id == "health:gen-v-build-readiness:metadata" })
        XCTAssertEqual(metadata.status, .valid)
        XCTAssertTrue(metadata.detail.contains("Makefile=present"))
        XCTAssertTrue(metadata.detail.contains("config.mk=present"))
        XCTAssertTrue(metadata.detail.contains("arm9.ld=present, arm7.ld=present"))
        XCTAssertTrue(metadata.actions.contains { $0.kind == .copyCommand && $0.copyValue == "make" })

        let sourceRoots = try XCTUnwrap(genVGroup.rows.first { $0.id == "health:gen-v-build-readiness:source-roots" })
        XCTAssertEqual(sourceRoots.status, .valid)
        XCTAssertTrue(sourceRoots.detail.contains("src=5 members/92 bytes"))
        XCTAssertTrue(sourceRoots.detail.contains("include=1 members/16 bytes"))

        let generatedOutput = try XCTUnwrap(genVGroup.rows.first { $0.id == "health:gen-v-build-readiness:generated-output" })
        XCTAssertEqual(generatedOutput.status, .warning)
        XCTAssertTrue(generatedOutput.detail.contains("pokeblack.nds=missing"))
        XCTAssertTrue(generatedOutput.actions.contains { $0.kind == .copyPath && $0.copyValue == "pokeblack.nds" })
        XCTAssertTrue(generatedOutput.actions.contains { $0.kind == .rerunGuidance })

        store.copyBuildPatchPlaytestReportJSONToPasteboard()
        let json = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let data = try XCTUnwrap(json.data(using: .utf8))
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let buildRows = try XCTUnwrap(object?["buildRows"] as? [[String: Any]])
        let exportedMetadata = try XCTUnwrap(buildRows.first { $0["title"] as? String == "Gen V build metadata" })
        XCTAssertTrue((exportedMetadata["detail"] as? String)?.contains("Makefile=present") == true)
        let exportedGenerated = try XCTUnwrap(buildRows.first { $0["title"] as? String == "Gen V generated outputs" })
        XCTAssertTrue((exportedGenerated["detail"] as? String)?.contains("generated-output writes remain disabled") == true)
        let exportedActions = try XCTUnwrap(exportedGenerated["actions"] as? [[String: Any]])
        XCTAssertTrue(exportedActions.contains { $0["kind"] as? String == "Copy Command" && $0["command"] as? String == "make" })
        XCTAssertTrue(exportedActions.contains { $0["kind"] as? String == "Copy Path" && $0["payload"] as? String == "pokeblack.nds" })
    }

    @MainActor
    func testGenVResourcesToBuildBridgeRowsNavigateAndStayCopyOnly() async throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent("pokeblack")
        try makeNDSBlackSourceProject(at: root)
        try write("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee  pokewhite.nds\n", to: root.appendingPathComponent("white.us/rom.sha1"))
        try write("not-a-sha1\n", to: root.appendingPathComponent("black2.us/rom.sha1"))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let selectedRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "files/msgdata" })

        store.requestResourceAssetSelection(selectedRow.id)

        let bridgeRows = store.genVResourcesToBuildBridgeRows
        XCTAssertEqual(
            Set(bridgeRows.map(\.id)),
            [
                "gen-v-resources-build-bridge:selected-resource",
                "gen-v-resources-build-bridge:manual-readiness",
                "gen-v-resources-build-bridge:generated-output-freshness",
            ]
        )
        XCTAssertTrue(bridgeRows.allSatisfy { $0.section == .healthMatrix })
        XCTAssertTrue(
            bridgeRows.flatMap(\.actions).allSatisfy { action in
                action.kind == .copyPath || action.kind == .copyCommand || action.kind == .rerunGuidance
            }
        )
        XCTAssertTrue(bridgeRows.first { $0.id == "gen-v-resources-build-bridge:selected-resource" }?.detail.contains("files/msgdata") == true)
        XCTAssertTrue(bridgeRows.first { $0.id == "gen-v-resources-build-bridge:manual-readiness" }?.detail.contains("no NDS build") == true)
        XCTAssertTrue(bridgeRows.first { $0.id == "gen-v-resources-build-bridge:generated-output-freshness" }?.detail.contains("black-rom:pokeblack.nds=missing") == true)
        XCTAssertTrue(store.selectedRunnableBuildTargets.isEmpty)
        XCTAssertFalse(store.canRunSelectedDecompBuild)
        XCTAssertFalse(store.canLaunchSelectedPlaytest)

        store.copyBuildPatchPlaytestReportJSONToPasteboard()
        let json = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let data = try XCTUnwrap(json.data(using: .utf8))
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let buildRows = try XCTUnwrap(object?["buildRows"] as? [[String: Any]])
        XCTAssertTrue(buildRows.contains { $0["title"] as? String == "Selected Gen V resource" && ($0["detail"] as? String)?.contains("files/msgdata") == true })
        XCTAssertTrue(buildRows.contains { $0["title"] as? String == "Gen V Manual Build Readiness bridge" })
        XCTAssertTrue(buildRows.contains { $0["title"] as? String == "Generated-output freshness packet" && ($0["detail"] as? String)?.contains("generated-output writes") == true })

        store.focusSelectedGenVResourcesToBuildBridgeAsset()
        XCTAssertEqual(store.selection, .resources)
        XCTAssertEqual(store.selectedResourceAsset?.path, "files/msgdata")

        store.focusGenVManualBuildReadinessForBridge()
        XCTAssertEqual(store.selection, .build)
        XCTAssertEqual(store.selectedBuildWorkbenchTab, .build)
        XCTAssertTrue(store.selectedBuildReportRowID.hasPrefix("health:gen-v-build-readiness:"))

        store.focusGenVGeneratedOutputFreshnessPacketForBridge()
        XCTAssertEqual(store.selection, .resources)
        XCTAssertEqual(store.selectedResourceAsset?.path, "gen-v/generated-output-freshness-packet")
    }

    @MainActor
    func testNDSSourceResourceRecordEditsPreviewApplyAndBlockBinaryRows() async throws {
        let root = try makeNDSSourceProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let sourceRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "arm9/src/pokemon.c" })

        store.requestResourceAssetSelection(sourceRow.id)
        store.resourceAssetWorkflowFacet = .editableSource
        XCTAssertTrue(store.filteredResourceAssetRows.contains { $0.id == sourceRow.id })

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "species:arm9/src/pokemon.c")
        XCTAssertFalse(editor.canPreview)
        XCTAssertTrue(editor.blockedReason?.contains("Change NDS data text") == true)

        store.updateSelectedNDSDataDraftText("void Pokemon_Load(void) { /* edited */ }\n")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("arm9/src/pokemon.c"), encoding: .utf8),
            "void Pokemon_Load(void) { /* edited */ }\n"
        )

        let binaryRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "files/fielddata/mapmatrix/matrix.bin" })
        XCTAssertFalse(store.filteredResourceAssetRows.contains { $0.id == binaryRow.id })
        store.requestResourceAssetSelection(binaryRow.id)

        let blockedEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertFalse(blockedEditor.canPreview)
        XCTAssertFalse(blockedEditor.canEdit)
        XCTAssertTrue(blockedEditor.blockedReason?.contains("binary") == true || blockedEditor.blockedReason?.contains("read-only") == true)

        store.updateSelectedNDSDataDraftText("hidden draft should not be retained")
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
    }

    @MainActor
    func testNDSResourceEditorKeepsHiddenDirtyDraftVisibleAndRedactsEvidence() async throws {
        let root = try makeNDSSourceProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let sourceRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "arm9/src/pokemon.c" })

        store.requestResourceAssetSelection(sourceRow.id)
        let secret = "SECRET_REPLACEMENT_TOKEN"
        let editedText = "void Pokemon_Load(void) {}\n// \(String(repeating: "x", count: 520)) \(secret)\n"
        store.updateSelectedNDSDataDraftText(editedText)
        XCTAssertTrue(store.selectedNDSDataIsDirty)

        store.searchText = "no matching nds row"
        XCTAssertFalse(store.filteredResourceAssetRows.contains { $0.id == sourceRow.id })
        let hiddenEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(hiddenEditor.isDirty)
        XCTAssertTrue(hiddenEditor.isHiddenByFilters)
        XCTAssertEqual(hiddenEditor.assetID, sourceRow.id)
        XCTAssertTrue(hiddenEditor.hiddenDraftSummary?.contains("hidden") == true)
        XCTAssertGreaterThan(hiddenEditor.draftByteCount, hiddenEditor.sourceByteCount)

        store.searchText = ""
        store.resourceAssetWorkflowFacet = .hiddenDrafts
        XCTAssertEqual(store.filteredResourceAssetRows.map(\.id), [sourceRow.id])
        XCTAssertFalse(try XCTUnwrap(store.selectedNDSDataEditor).isHiddenByFilters)

        store.resourceAssetCategory = "NDS Data maps"
        XCTAssertFalse(store.filteredResourceAssetRows.contains { $0.id == sourceRow.id })
        XCTAssertTrue(try XCTUnwrap(store.selectedNDSDataEditor).isHiddenByFilters)

        store.previewSelectedNDSDataMutationPlan()
        let context = try XCTUnwrap(MutationPlanPanelContext.ndsData(
            plan: store.latestNDSDataEditPlan,
            result: store.latestNDSDataApplyResult,
            editor: store.selectedNDSDataEditor
        ))
        let change = try XCTUnwrap(context.changes.first)
        XCTAssertTrue(change.evidenceIsTruncated)
        XCTAssertTrue(change.evidenceDetail?.contains("redacted") == true)
        XCTAssertFalse(change.detail?.contains(secret) == true)
        XCTAssertFalse(change.evidenceDetail?.contains(secret) == true)

        store.discardNDSDataEdits()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
    }

    @MainActor
    func testNDSResourceEditorSurfacesRawSemanticDraftAndPlanReadiness() async throws {
        let root = try makeNDSPlatinumSourceProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let speciesRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "res/pokemon/abra/data.json" })

        store.requestResourceAssetSelection(speciesRow.id)

        var editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "species:res/pokemon/abra/data.json")
        XCTAssertTrue(editor.canEdit)
        XCTAssertFalse(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        XCTAssertEqual(editor.readiness.rawSource.value, "Editable UTF-8")
        XCTAssertEqual(editor.readiness.semanticSource.value, "4 field(s)")
        XCTAssertEqual(editor.readiness.draft.value, "Clean")
        XCTAssertEqual(editor.readiness.mutationPlan.value, "Waiting")
        XCTAssertTrue(editor.readiness.blockers.isEmpty)

        store.updateSelectedNDSDataSemanticField(key: "base_hp", value: "26")

        editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(editor.isDirty)
        XCTAssertTrue(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        XCTAssertEqual(editor.readiness.rawSource.value, "Editable UTF-8")
        XCTAssertEqual(editor.readiness.semanticSource.value, "4 field(s)")
        XCTAssertEqual(editor.readiness.draft.value, "Dirty draft")
        XCTAssertEqual(editor.readiness.mutationPlan.value, "Preview ready")
        XCTAssertTrue(editor.readiness.blockers.isEmpty)

        store.previewSelectedNDSDataMutationPlan()

        editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertNotNil(store.latestNDSDataEditPlan)
        XCTAssertTrue(editor.canApply)
        XCTAssertEqual(editor.readiness.draft.value, "Previewed")
        XCTAssertEqual(editor.readiness.mutationPlan.value, "Apply ready")
        XCTAssertTrue(editor.readiness.blockers.isEmpty)
    }

    @MainActor
    func testNDSResourceEditorExplainsBlockedResourceRows() async throws {
        func makeStore(root: URL) -> WorkbenchStore {
            let defaults = UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)")!
            let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)
            store.openProject(path: root.path)
            store.selectWorkbenchModule(.resources)
            return store
        }

        func selectBlockedRow(
            in store: WorkbenchStore,
            path: String,
            expectedTitle: String
        ) async throws -> NDSDataResourceEditorViewState {
            store.loadSelectedAssetCatalogIfNeeded()
            let assetCatalog = try await waitForSelectedAssetCatalog(store)
            let row = try XCTUnwrap(assetCatalog.rows.first { $0.path == path }, path)
            store.requestResourceAssetSelection(row.id)

            let editor = try XCTUnwrap(store.selectedNDSDataEditor)
            XCTAssertFalse(editor.canEdit, path)
            XCTAssertFalse(editor.canPreview, path)
            XCTAssertFalse(editor.canApply, path)
            XCTAssertEqual(editor.readiness.rawSource.value, "Blocked", path)
            XCTAssertEqual(editor.readiness.mutationPlan.value, "Blocked", path)
            XCTAssertTrue(editor.readiness.blockers.contains { $0.title == expectedTitle }, "\(path): \(editor.readiness.blockers.map(\.title))")

            store.updateSelectedNDSDataDraftText("changed\n")
            XCTAssertNil(store.selectedNDSDataDraft, path)
            XCTAssertNil(store.latestNDSDataEditPlan, path)
            XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan, path)

            return editor
        }

        let genVTemp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(genVTemp)
        let genVRoot = genVTemp.url.appendingPathComponent("pokeblack")
        try makeNDSBlackSourceProject(at: genVRoot)
        let genVStore = makeStore(root: genVRoot)
        _ = try await selectBlockedRow(
            in: genVStore,
            path: "data/encounters/route_1.txt",
            expectedTitle: "Gen V preview-only"
        )
        XCTAssertEqual(
            try String(contentsOf: genVRoot.appendingPathComponent("data/encounters/route_1.txt"), encoding: .utf8),
            "encounter\n"
        )

        let referenceTemp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(referenceTemp)
        let referenceRoot = referenceTemp.url.appendingPathComponent("references/pokeplatinum")
        try makeNDSPlatinumSourceProject(at: referenceRoot)
        let referenceStore = makeStore(root: referenceRoot)
        _ = try await selectBlockedRow(
            in: referenceStore,
            path: "res/pokemon/abra/data.json",
            expectedTitle: "Reference root"
        )
        XCTAssertEqual(
            try String(contentsOf: referenceRoot.appendingPathComponent("res/pokemon/abra/data.json"), encoding: .utf8),
            "{\"base_hp\":25,\"evolutions\":[[\"EVO_LEVEL\",16,\"SPECIES_KADABRA\"]]}\n"
        )

        let platinumRoot = try makeNDSPlatinumSourceProject()
        try write("generated\n", to: platinumRoot.appendingPathComponent("generated/species.txt"))
        let platinumStore = makeStore(root: platinumRoot)

        let containerEditor = try await selectBlockedRow(
            in: platinumStore,
            path: "res/prebuilt/poketool/personal/personal.narc",
            expectedTitle: "Container row"
        )
        XCTAssertTrue(containerEditor.readiness.blockers.contains { $0.title == "Unsafe format" })

        _ = try await selectBlockedRow(
            in: platinumStore,
            path: "res/field/maps/route201/map.bin",
            expectedTitle: "Unsafe format"
        )

        _ = try await selectBlockedRow(
            in: platinumStore,
            path: "generated/species.txt",
            expectedTitle: "Generated/reference path"
        )
        XCTAssertEqual(
            try String(contentsOf: platinumRoot.appendingPathComponent("generated/species.txt"), encoding: .utf8),
            "generated\n"
        )
    }

    @MainActor
    func testResourcesGuidedFlowSurfacesNDSDraftReadinessAndBlockers() async throws {
        let root = try makeNDSPlatinumSourceProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let speciesRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "res/pokemon/abra/data.json" })
        store.requestResourceAssetSelection(speciesRow.id)
        store.updateSelectedNDSDataSemanticField(key: "base_hp", value: "26")

        var session = store.currentModuleEditorSession
        XCTAssertEqual(session.stage, .draftReady)
        XCTAssertTrue(session.canPreview)
        XCTAssertEqual(session.nextActionTitle, "Preview NDS Data Changes")

        var resourcesFlow = try XCTUnwrap(store.guidedFlows.first { $0.id == "resources-assets" })
        XCTAssertEqual(resourcesFlow.run.state, .needsPreview)
        XCTAssertEqual(resourcesFlow.run.mutationGate, "NDS Data: Preview -> Apply -> Backup")
        XCTAssertEqual(resourcesFlow.facts.first { $0.label == "NDS Draft" }?.value, "Dirty draft")
        XCTAssertEqual(resourcesFlow.facts.first { $0.label == "NDS Semantic" }?.value, "4 field(s)")
        XCTAssertEqual(resourcesFlow.facts.first { $0.label == "NDS Plan" }?.value, "Preview ready")

        store.previewSelectedNDSDataMutationPlan()

        session = store.currentModuleEditorSession
        XCTAssertEqual(session.stage, .previewReady)
        XCTAssertTrue(session.canApply)
        XCTAssertEqual(session.nextActionTitle, "Apply NDS Data Changes")

        resourcesFlow = try XCTUnwrap(store.guidedFlows.first { $0.id == "resources-assets" })
        XCTAssertEqual(resourcesFlow.run.state, .previewReady)
        XCTAssertEqual(resourcesFlow.facts.first { $0.label == "NDS Draft" }?.value, "Previewed")
        XCTAssertEqual(resourcesFlow.facts.first { $0.label == "NDS Plan" }?.value, "Apply ready")

        let genVTemp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(genVTemp)
        let genVRoot = genVTemp.url.appendingPathComponent("pokeblack")
        try makeNDSBlackSourceProject(at: genVRoot)
        let genVDefaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let genVStore = WorkbenchStore(userDefaults: genVDefaults, autoLoadProjects: false)
        genVStore.openProject(path: genVRoot.path)
        genVStore.selectWorkbenchModule(.resources)
        genVStore.loadSelectedAssetCatalogIfNeeded()
        let genVAssetCatalog = try await waitForSelectedAssetCatalog(genVStore)
        let encounterRow = try XCTUnwrap(genVAssetCatalog.rows.first { $0.path == "data/encounters/route_1.txt" })
        genVStore.requestResourceAssetSelection(encounterRow.id)

        let blockedSession = genVStore.currentModuleEditorSession
        XCTAssertEqual(blockedSession.stage, .blocked)
        XCTAssertEqual(blockedSession.nextActionTitle, "Review Gen V preview-only")
        XCTAssertTrue(blockedSession.blockedReason?.contains("Pokemon Black/White source rows are read-only Gen V readiness metadata") == true)

        let blockedFlow = try XCTUnwrap(genVStore.guidedFlows.first { $0.id == "resources-assets" })
        XCTAssertEqual(blockedFlow.run.state, .blocked)
        XCTAssertEqual(blockedFlow.run.mutationGate, "NDS Data: Gen V preview-only")
        XCTAssertEqual(blockedFlow.facts.first { $0.label == "NDS Blocker" }?.value, "Gen V preview-only")
        XCTAssertEqual(blockedFlow.facts.first { $0.label == "NDS Plan" }?.value, "Blocked")
    }

    @MainActor
    func testNDSSemanticJSONFieldEditsFlowThroughResourceEditor() async throws {
        let root = try makeNDSPlatinumSourceProject()
        let blockedTrainerResourcePath = "res/trainers/resources/youngster.json"
        try write("{\"cell_animation\":1}\n", to: root.appendingPathComponent(blockedTrainerResourcePath))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let mapRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "res/field/maps/route201/map.bin" })
        XCTAssertTrue(mapRow.facts.contains { $0.label == "Readiness" && $0.value == "ready" })
        XCTAssertTrue(mapRow.facts.contains { $0.label == "Related Domains" && $0.value.contains("scripts") })
        XCTAssertEqual(mapRow.targetModule, .resources)
        let personalNARCRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "res/prebuilt/poketool/personal/personal.narc" })
        XCTAssertTrue(personalNARCRow.facts.contains { $0.label == "Preview Hints" && $0.value.contains("nitroPalette") })
        XCTAssertTrue(personalNARCRow.facts.contains { $0.label == "Blocked Previews" && $0.value == "1" })

        let speciesRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "res/pokemon/abra/data.json" })

        store.requestResourceAssetSelection(speciesRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "species:res/pokemon/abra/data.json")
        XCTAssertEqual(editor.semanticFields.first?.key, "base_hp")
        XCTAssertEqual(editor.semanticFields.first?.value, "25")
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "evolutions.0.parameter" && $0.value == "16" })

        store.updateSelectedNDSDataSemanticField(key: "base_hp", value: "29")
        store.updateSelectedNDSDataSemanticField(key: "evolutions.0.target", value: "SPECIES_ALAKAZAM")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        let updatedSpecies = try String(contentsOf: root.appendingPathComponent("res/pokemon/abra/data.json"), encoding: .utf8)
        XCTAssertTrue(updatedSpecies.contains("\"base_hp\":29"))
        XCTAssertTrue(updatedSpecies.contains("[\"EVO_LEVEL\",16,\"SPECIES_ALAKAZAM\"]"))

        let itemRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "res/items/potion.json" })
        store.requestResourceAssetSelection(itemRow.id)

        let itemEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(itemEditor.recordID, "items:res/items/potion.json")
        XCTAssertTrue(itemEditor.semanticFields.contains { $0.key == "name" && $0.value == "Potion" })
        XCTAssertTrue(itemEditor.semanticFields.contains { $0.key == "price" && $0.value == "300" })
        XCTAssertTrue(itemEditor.semanticFields.contains { $0.key == "field_use" && $0.value == "true" })
        XCTAssertFalse(itemEditor.semanticFields.contains { $0.key == "effects" })

        store.updateSelectedNDSDataSemanticField(key: "price", value: "250")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        XCTAssertTrue(
            try String(contentsOf: root.appendingPathComponent("res/items/potion.json"), encoding: .utf8)
                .contains("\"price\": 250")
        )

        let trainerRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "res/trainers/data/youngster.json" })
        store.requestResourceAssetSelection(trainerRow.id)

        let trainerEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(trainerEditor.recordID, "trainers:res/trainers/data/youngster.json")
        XCTAssertTrue(trainerEditor.semanticFields.contains { $0.key == "name" && $0.value == "Youngster" })
        XCTAssertTrue(trainerEditor.semanticFields.contains { $0.key == "double_battle" && $0.value == "false" })
        XCTAssertFalse(trainerEditor.semanticFields.contains { $0.key == "party" })

        store.updateSelectedNDSDataSemanticField(key: "double_battle", value: "true")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        XCTAssertTrue(
            try String(contentsOf: root.appendingPathComponent("res/trainers/data/youngster.json"), encoding: .utf8)
                .contains("\"double_battle\": true")
        )

        let trainerResourceRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == blockedTrainerResourcePath })
        store.requestResourceAssetSelection(trainerResourceRow.id)

        let trainerResourceEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(trainerResourceEditor.semanticFields.isEmpty)
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        store.updateSelectedNDSDataSemanticField(key: "cell_animation", value: "2")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(blockedTrainerResourcePath), encoding: .utf8),
            "{\"cell_animation\":1}\n"
        )

        let itemCSVRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "res/items/items.csv" })
        store.requestResourceAssetSelection(itemCSVRow.id)

        let itemCSVEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(itemCSVEditor.semanticFields.isEmpty)
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        store.updateSelectedNDSDataSemanticField(key: "name", value: "Super Potion")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("res/items/items.csv"), encoding: .utf8),
            "id,name\n1,POTION\n"
        )
    }

    @MainActor
    func testPlatinumTrainerClassSemanticFieldEditsFlowThroughResourceEditor() async throws {
        let root = try makeNDSPlatinumSourceProject()
        let classPath = "res/trainers/classes/youngster.json"
        let nestedPath = "res/trainers/classes/sinnoh/ace.json"
        let resourcePath = "res/trainers/resources/youngster.json"
        let textPath = "res/trainers/classes/youngster.txt"
        try write(
            "{\"cell_animation\":1,\"label\":\"Youngster\",\"enabled\":true,\"palette\":null,\"frames\":[{\"id\":1}],\"metadata\":{\"kind\":\"class\"}}\n",
            to: root.appendingPathComponent(classPath)
        )
        try write("{\"cell_animation\":2}\n", to: root.appendingPathComponent(nestedPath))
        try write("{\"cell_animation\":3}\n", to: root.appendingPathComponent(resourcePath))
        try write("cell_animation=4\n", to: root.appendingPathComponent(textPath))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let classRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == classPath })
        store.requestResourceAssetSelection(classRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "trainers:\(classPath)")
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "cell_animation" && $0.value == "1" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "label" && $0.value == "Youngster" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "enabled" && $0.value == "true" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "palette" && $0.value == "null" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "frames" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "metadata" })

        store.updateSelectedNDSDataSemanticField(key: "frames.0.id", value: "2")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(classPath), encoding: .utf8),
            "{\"cell_animation\":1,\"label\":\"Youngster\",\"enabled\":true,\"palette\":null,\"frames\":[{\"id\":1}],\"metadata\":{\"kind\":\"class\"}}\n"
        )

        store.updateSelectedNDSDataSemanticField(key: "cell_animation", value: "6")
        store.updateSelectedNDSDataSemanticField(key: "label", value: "Youngster Prime")
        store.updateSelectedNDSDataSemanticField(key: "enabled", value: "false")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(classPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"cell_animation\":6"))
        XCTAssertTrue(updated.contains("\"label\":\"Youngster Prime\""))
        XCTAssertTrue(updated.contains("\"enabled\":false"))
        XCTAssertTrue(updated.contains("\"frames\":[{\"id\":1}]"))
        XCTAssertTrue(updated.contains("\"metadata\":{\"kind\":\"class\"}"))

        let nestedRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == nestedPath })
        store.requestResourceAssetSelection(nestedRow.id)
        let nestedEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(nestedEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "cell_animation", value: "7")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(nestedPath), encoding: .utf8),
            "{\"cell_animation\":2}\n"
        )

        let resourceRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == resourcePath })
        store.requestResourceAssetSelection(resourceRow.id)
        let resourceEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(resourceEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "cell_animation", value: "7")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(resourcePath), encoding: .utf8),
            "{\"cell_animation\":3}\n"
        )

        let textRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == textPath })
        store.requestResourceAssetSelection(textRow.id)
        let textEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(textEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "cell_animation", value: "7")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8),
            "cell_animation=4\n"
        )
    }

    @MainActor
    func testPlatinumSourceTextLineSemanticFieldEditsFlowThroughResourceEditor() async throws {
        let root = try makeNDSPlatinumSourceProject()
        let textPath = "res/text/route201.txt"
        let bmgPath = "res/text/battle.bmg"
        let containerPath = "res/prebuilt/poketool/personal/personal.narc"
        let originalBMG = try Data(contentsOf: root.appendingPathComponent(bmgPath))
        let originalContainer = try Data(contentsOf: root.appendingPathComponent(containerPath))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let textRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == textPath })
        store.requestResourceAssetSelection(textRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "text:\(textPath)")
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "lines.0.text" && $0.label == "Line 1" && $0.value == "hello" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "lines.1.text" && $0.label == "Line 2" && $0.value == "world" })

        store.updateSelectedNDSDataSemanticField(key: "lines.0.text", value: "hello route")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8),
            "hello route\nworld\n"
        )

        let bmgRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == bmgPath })
        store.requestResourceAssetSelection(bmgRow.id)
        let bmgEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(bmgEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "lines.0.text", value: "blocked")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(bmgPath)), originalBMG)

        let containerRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == containerPath })
        store.requestResourceAssetSelection(containerRow.id)
        let containerEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(containerEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "lines.0.text", value: "blocked")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(containerPath)), originalContainer)
    }

    @MainActor
    func testPlatinumTextLineRowOperationsFlowThroughResourceEditor() async throws {
        let root = try makeNDSPlatinumSourceProject()
        let textPath = "res/text/route201.txt"
        let bmgPath = "res/text/battle.bmg"
        let originalBMG = try Data(contentsOf: root.appendingPathComponent(bmgPath))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let textRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == textPath })
        store.requestResourceAssetSelection(textRow.id)

        var editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "text:\(textPath)")
        XCTAssertEqual(editor.rowOperations?.family, .textLines)
        XCTAssertEqual(editor.rowOperations?.stagedCount, 0)

        store.stageSelectedNDSDataRowOperation(kind: .insert, index: 1, insertValue: "discarded raw replacement")
        editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.rowOperations?.stagedCount, 1)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.updateSelectedNDSDataDraftText("hello raw\nworld\n")
        editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.rowOperations?.stagedCount, 0)
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        store.discardNDSDataEdits()

        store.stageSelectedNDSDataRowOperation(kind: .insert, index: 1, insertValue: "middle")
        store.stageSelectedNDSDataRowOperation(kind: .delete, index: 0)
        store.stageSelectedNDSDataRowOperation(kind: .reorder, fromIndex: 1, toIndex: 0)

        editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.rowOperations?.stagedCount, 3)
        XCTAssertTrue(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        XCTAssertEqual(editor.readiness.draft.value, "Dirty draft")
        XCTAssertEqual(editor.readiness.mutationPlan.value, "Preview ready")

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)
        let context = try XCTUnwrap(MutationPlanPanelContext.ndsData(
            plan: store.latestNDSDataEditPlan,
            result: store.latestNDSDataApplyResult,
            editor: store.selectedNDSDataEditor
        ))
        XCTAssertEqual(context.operationCount, 3)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8),
            "world\nmiddle\n"
        )

        let bmgRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == bmgPath })
        store.requestResourceAssetSelection(bmgRow.id)
        XCTAssertNil(store.selectedNDSDataEditor?.rowOperations)
        store.stageSelectedNDSDataRowOperation(kind: .insert, index: 0, insertValue: "blocked")
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(bmgPath)), originalBMG)
    }

    @MainActor
    func testPlatinumMoveSemanticFieldEditsFlowThroughResourceEditor() async throws {
        let root = try makeNDSPlatinumSourceProject()
        let movePath = "res/battle/moves/tackle.json"
        let nestedPath = "res/battle/moves/custom/tackle.json"
        try write(
            "{\"power\":40,\"accuracy\":100,\"contact\":true,\"flags\":{\"protect\":true},\"contest\":[\"cool\"]}\n",
            to: root.appendingPathComponent(movePath)
        )
        try write("{\"power\":60}\n", to: root.appendingPathComponent(nestedPath))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let moveRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == movePath })
        store.requestResourceAssetSelection(moveRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "moves:\(movePath)")
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "power" && $0.value == "40" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "accuracy" && $0.value == "100" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "contact" && $0.value == "true" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "flags" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "contest" })

        store.updateSelectedNDSDataSemanticField(key: "power", value: "60")
        store.updateSelectedNDSDataSemanticField(key: "accuracy", value: "95")
        store.updateSelectedNDSDataSemanticField(key: "contact", value: "false")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(movePath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"power\":60"))
        XCTAssertTrue(updated.contains("\"accuracy\":95"))
        XCTAssertTrue(updated.contains("\"contact\":false"))
        XCTAssertTrue(updated.contains("\"flags\":{\"protect\":true}"))

        let nestedMoveRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == nestedPath })
        store.requestResourceAssetSelection(nestedMoveRow.id)
        let nestedEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(nestedEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "power", value: "70")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(nestedPath), encoding: .utf8),
            "{\"power\":60}\n"
        )
    }

    @MainActor
    func testPlatinumEncounterSlotSemanticFieldEditsFlowThroughResourceEditor() async throws {
        let root = try makeNDSPlatinumSourceProject()
        let encounterPath = "res/field/encounters/route201.json"
        let textPath = "res/field/encounters/route202.txt"
        try write(
            "{\"land_rate\":30,\"land_encounters\":[{\"level\":2,\"species\":\"SPECIES_STARLY\"},{\"level\":3,\"species\":\"SPECIES_BIDOOF\"}],\"swarms\":[\"SPECIES_DODUO\",\"SPECIES_DODUO\"],\"map_category\":{\"map_type\":\"field\",\"map_number\":12}}\n",
            to: root.appendingPathComponent(encounterPath)
        )
        try write("land_rate=15\n", to: root.appendingPathComponent(textPath))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let encounterRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == encounterPath })
        store.requestResourceAssetSelection(encounterRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "encounters:\(encounterPath)")
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "land_rate" && $0.value == "30" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "land_encounters.0.level" && $0.value == "2" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "land_encounters.0.species" && $0.value == "SPECIES_STARLY" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "swarms.0" && $0.value == "SPECIES_DODUO" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "land_encounters" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "map_category.map_type" })

        store.updateSelectedNDSDataSemanticField(key: "land_encounters.0.level", value: "5")
        store.updateSelectedNDSDataSemanticField(key: "land_encounters.0.species", value: "SPECIES_BIDOOF")
        store.updateSelectedNDSDataSemanticField(key: "swarms.1", value: "SPECIES_NIDORAN_M")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(encounterPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"land_encounters\":[{\"level\":5,\"species\":\"SPECIES_BIDOOF\"}"))
        XCTAssertTrue(updated.contains("\"swarms\":[\"SPECIES_DODUO\",\"SPECIES_NIDORAN_M\"]"))
        XCTAssertTrue(updated.contains("\"map_category\":{\"map_type\":\"field\",\"map_number\":12}"))

        let textRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == textPath })
        store.requestResourceAssetSelection(textRow.id)
        let textEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(textEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "land_rate", value: "20")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8),
            "land_rate=15\n"
        )
    }

    @MainActor
    func testPlatinumEncounterJSONRowOperationsFlowThroughResourceEditor() async throws {
        let root = try makeNDSPlatinumSourceProject()
        let encounterPath = "res/field/encounters/route201.json"
        let nestedPath = "res/field/encounters/nested/route202.json"
        let textPath = "res/field/encounters/route203.txt"
        try write(
            "{\"land_rate\":30,\"land_encounters\":[{\"level\":2,\"species\":\"SPECIES_STARLY\"},{\"level\":3,\"species\":\"SPECIES_BIDOOF\"}],\"swarms\":[\"SPECIES_DODUO\",\"SPECIES_DODUO\"],\"map_category\":{\"map_type\":\"field\",\"map_number\":12}}\n",
            to: root.appendingPathComponent(encounterPath)
        )
        try write("{\"land_encounters\":[{\"level\":2,\"species\":\"SPECIES_BIDOOF\"}]}\n", to: root.appendingPathComponent(nestedPath))
        try write("land_rate=15\n", to: root.appendingPathComponent(textPath))
        let originalNested = try String(contentsOf: root.appendingPathComponent(nestedPath), encoding: .utf8)
        let originalText = try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let encounterRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == encounterPath })
        store.requestResourceAssetSelection(encounterRow.id)

        var editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "encounters:\(encounterPath)")
        XCTAssertEqual(editor.rowOperations?.family, .encounterJSONRows)
        XCTAssertEqual(editor.rowOperations?.targetOptions.map(\.key), ["land_encounters"])
        XCTAssertEqual(editor.rowOperations?.selectedTargetKey, "land_encounters")
        XCTAssertEqual(editor.rowOperations?.stagedCount, 0)
        XCTAssertFalse(editor.rowOperations?.targetOptions.contains { $0.key == "swarms" } == true)

        store.stageSelectedNDSDataRowOperation(
            kind: .insert,
            targetKey: "land_encounters",
            index: 1,
            insertValue: "{\"level\":4,\"species\":\"SPECIES_DISCARDED\"}"
        )
        editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.rowOperations?.stagedCount, 1)
        XCTAssertEqual(editor.rowOperations?.selectedTargetKey, "land_encounters")
        XCTAssertEqual(editor.rowOperations?.canChangeTarget, false)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.updateSelectedNDSDataDraftText("raw replacement\n")
        editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.rowOperations?.stagedCount, 0)
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        store.discardNDSDataEdits()

        store.stageSelectedNDSDataRowOperation(
            kind: .insert,
            targetKey: "land_encounters",
            index: 1,
            insertValue: "{\"level\":4,\"species\":\"SPECIES_SHINX\"}"
        )
        store.stageSelectedNDSDataRowOperation(kind: .delete, targetKey: "land_encounters", index: 0)
        store.stageSelectedNDSDataRowOperation(kind: .reorder, targetKey: "land_encounters", fromIndex: 1, toIndex: 0)

        editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.rowOperations?.stagedCount, 3)
        XCTAssertEqual(editor.rowOperations?.countSummary, "2 -> 2")
        XCTAssertTrue(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        XCTAssertEqual(editor.readiness.draft.value, "Dirty draft")
        XCTAssertEqual(editor.readiness.mutationPlan.value, "Preview ready")

        store.resourceAssetWorkflowFacet = .hiddenDrafts
        XCTAssertTrue(store.filteredResourceAssetRows.contains { $0.id == encounterRow.id })
        XCTAssertFalse(try XCTUnwrap(store.selectedNDSDataEditor).isHiddenByFilters)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)
        let context = try XCTUnwrap(MutationPlanPanelContext.ndsData(
            plan: store.latestNDSDataEditPlan,
            result: store.latestNDSDataApplyResult,
            editor: store.selectedNDSDataEditor
        ))
        XCTAssertEqual(context.operationCount, 3)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        let appliedChange = try XCTUnwrap(store.latestNDSDataApplyResult?.appliedChanges.first)
        XCTAssertTrue(FileManager.default.fileExists(atPath: appliedChange.backupPath))
        let updated = try String(contentsOf: root.appendingPathComponent(encounterPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"land_encounters\":[{\"level\":3,\"species\":\"SPECIES_BIDOOF\"},{\"level\":4,\"species\":\"SPECIES_SHINX\"}]"))
        XCTAssertTrue(updated.contains("\"swarms\":[\"SPECIES_DODUO\",\"SPECIES_DODUO\"]"))
        XCTAssertTrue(updated.contains("\"map_category\":{\"map_type\":\"field\",\"map_number\":12}"))

        let nestedRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == nestedPath })
        store.requestResourceAssetSelection(nestedRow.id)
        XCTAssertNil(store.selectedNDSDataEditor?.rowOperations)
        store.stageSelectedNDSDataRowOperation(
            kind: .insert,
            targetKey: "land_encounters",
            index: 0,
            insertValue: "{\"level\":5,\"species\":\"SPECIES_NESTED\"}"
        )
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(try String(contentsOf: root.appendingPathComponent(nestedPath), encoding: .utf8), originalNested)

        let textRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == textPath })
        store.requestResourceAssetSelection(textRow.id)
        XCTAssertNil(store.selectedNDSDataEditor?.rowOperations)
        store.stageSelectedNDSDataRowOperation(
            kind: .insert,
            targetKey: "land_encounters",
            index: 0,
            insertValue: "{\"level\":5,\"species\":\"SPECIES_TEXT\"}"
        )
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8), originalText)
    }

    @MainActor
    func testHeartGoldSoulSilverEncounterJSONRowOperationsFlowThroughResourceEditor() async throws {
        let root = try makeNDSHeartGoldSourceProject()
        let encounterPath = "files/fielddata/encountdata/johto/route29.json"
        let scalarOnlyPath = "files/fielddata/encountdata/johto/scalar_only.json"
        let textPath = "files/fielddata/encountdata/gs_enc_data.txt"
        let cAnchorPath = "files/fielddata/encountdata/encounter.c"
        try write(
            "{\"morning_rate\":20,\"slots\":[{\"species\":\"RATTATA\",\"rate\":30,\"enabled\":true},{\"species\":\"PIDGEY\",\"rate\":20,\"enabled\":false}],\"swarms\":[\"PIDGEY\",\"SENTRET\"],\"metadata\":{\"map\":\"ROUTE_29\"}}\n",
            to: root.appendingPathComponent(encounterPath)
        )
        try write("{\"morning_rate\":20,\"swarms\":[\"PIDGEY\",\"SENTRET\"]}\n", to: root.appendingPathComponent(scalarOnlyPath))
        try write("rate=15\n", to: root.appendingPathComponent(textPath))
        try write("void Encounter_Load(void) {}\n", to: root.appendingPathComponent(cAnchorPath))
        let originalScalarOnly = try String(contentsOf: root.appendingPathComponent(scalarOnlyPath), encoding: .utf8)
        let originalText = try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8)
        let originalCAnchor = try String(contentsOf: root.appendingPathComponent(cAnchorPath), encoding: .utf8)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let encounterRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == encounterPath })
        store.requestResourceAssetSelection(encounterRow.id)

        var editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "encounters:\(encounterPath)")
        XCTAssertEqual(editor.rowOperations?.family, .encounterJSONRows)
        XCTAssertEqual(editor.rowOperations?.targetOptions.map(\.key), ["slots"])
        XCTAssertEqual(editor.rowOperations?.selectedTargetKey, "slots")
        XCTAssertEqual(editor.rowOperations?.stagedCount, 0)
        XCTAssertFalse(editor.rowOperations?.targetOptions.contains { $0.key == "swarms" } == true)

        store.stageSelectedNDSDataRowOperation(
            kind: .insert,
            targetKey: "slots",
            index: 1,
            insertValue: "{\"species\":\"SENTRET\",\"rate\":10,\"enabled\":true}"
        )
        editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.rowOperations?.stagedCount, 1)
        XCTAssertEqual(editor.rowOperations?.selectedTargetKey, "slots")
        XCTAssertEqual(editor.rowOperations?.canChangeTarget, false)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.updateSelectedNDSDataDraftText("raw replacement\n")
        editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.rowOperations?.stagedCount, 0)
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        store.discardNDSDataEdits()

        store.stageSelectedNDSDataRowOperation(
            kind: .insert,
            targetKey: "slots",
            index: 1,
            insertValue: "{\"species\":\"HOOTHOOT\",\"rate\":25,\"enabled\":true}"
        )
        store.stageSelectedNDSDataRowOperation(kind: .delete, targetKey: "slots", index: 0)
        store.stageSelectedNDSDataRowOperation(kind: .reorder, targetKey: "slots", fromIndex: 1, toIndex: 0)

        editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.rowOperations?.stagedCount, 3)
        XCTAssertEqual(editor.rowOperations?.countSummary, "2 -> 2")
        XCTAssertTrue(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        XCTAssertEqual(editor.readiness.draft.value, "Dirty draft")
        XCTAssertEqual(editor.readiness.mutationPlan.value, "Preview ready")

        store.resourceAssetWorkflowFacet = .hiddenDrafts
        XCTAssertTrue(store.filteredResourceAssetRows.contains { $0.id == encounterRow.id })
        XCTAssertFalse(try XCTUnwrap(store.selectedNDSDataEditor).isHiddenByFilters)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)
        let context = try XCTUnwrap(MutationPlanPanelContext.ndsData(
            plan: store.latestNDSDataEditPlan,
            result: store.latestNDSDataApplyResult,
            editor: store.selectedNDSDataEditor
        ))
        XCTAssertEqual(context.operationCount, 3)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        let appliedChange = try XCTUnwrap(store.latestNDSDataApplyResult?.appliedChanges.first)
        XCTAssertTrue(FileManager.default.fileExists(atPath: appliedChange.backupPath))
        let updated = try String(contentsOf: root.appendingPathComponent(encounterPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"slots\":[{\"species\":\"PIDGEY\",\"rate\":20,\"enabled\":false},{\"species\":\"HOOTHOOT\",\"rate\":25,\"enabled\":true}]"))
        XCTAssertTrue(updated.contains("\"swarms\":[\"PIDGEY\",\"SENTRET\"]"))
        XCTAssertTrue(updated.contains("\"metadata\":{\"map\":\"ROUTE_29\"}"))

        let scalarOnlyRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == scalarOnlyPath })
        store.requestResourceAssetSelection(scalarOnlyRow.id)
        XCTAssertNil(store.selectedNDSDataEditor?.rowOperations)
        store.stageSelectedNDSDataRowOperation(
            kind: .insert,
            targetKey: "slots",
            index: 0,
            insertValue: "{\"species\":\"RATTATA\",\"rate\":10,\"enabled\":true}"
        )
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(try String(contentsOf: root.appendingPathComponent(scalarOnlyPath), encoding: .utf8), originalScalarOnly)

        let textRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == textPath })
        store.requestResourceAssetSelection(textRow.id)
        XCTAssertNil(store.selectedNDSDataEditor?.rowOperations)
        store.stageSelectedNDSDataRowOperation(
            kind: .insert,
            targetKey: "slots",
            index: 0,
            insertValue: "{\"species\":\"PIDGEY\",\"rate\":10,\"enabled\":true}"
        )
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8), originalText)

        let cAnchorRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == cAnchorPath })
        store.requestResourceAssetSelection(cAnchorRow.id)
        XCTAssertNil(store.selectedNDSDataEditor?.rowOperations)
        store.stageSelectedNDSDataRowOperation(
            kind: .delete,
            targetKey: "slots",
            index: 0
        )
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(try String(contentsOf: root.appendingPathComponent(cAnchorPath), encoding: .utf8), originalCAnchor)
    }

    @MainActor
    func testDiamondPearlEncounterJSONRowOperationsFlowThroughResourceEditor() async throws {
        let root = try makeNDSSourceProject()
        let encounterPath = "files/fielddata/encountdata/sinnoh/route201.json"
        let scalarOnlyPath = "files/fielddata/encountdata/sinnoh/scalar_only.json"
        let textPath = "files/fielddata/encountdata/sinnoh/route202.txt"
        let cAnchorPath = "arm9/src/encounter.c"
        try write(
            "{\"rate\":20,\"slots\":[{\"species\":\"BIDOOF\",\"rate\":30,\"enabled\":true},{\"species\":\"STARLY\",\"rate\":20,\"enabled\":false}],\"swarms\":[\"DODUO\",\"NIDORAN_F\"],\"metadata\":{\"map\":\"ROUTE_201\"}}\n",
            to: root.appendingPathComponent(encounterPath)
        )
        try write("{\"rate\":20,\"swarms\":[\"DODUO\",\"NIDORAN_F\"]}\n", to: root.appendingPathComponent(scalarOnlyPath))
        try write("rate=15\n", to: root.appendingPathComponent(textPath))
        try write("void Encounter_Load(void) {}\n", to: root.appendingPathComponent(cAnchorPath))
        let originalScalarOnly = try String(contentsOf: root.appendingPathComponent(scalarOnlyPath), encoding: .utf8)
        let originalText = try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8)
        let originalCAnchor = try String(contentsOf: root.appendingPathComponent(cAnchorPath), encoding: .utf8)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let encounterRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == encounterPath })
        store.requestResourceAssetSelection(encounterRow.id)

        var editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "encounters:\(encounterPath)")
        XCTAssertEqual(editor.rowOperations?.family, .encounterJSONRows)
        XCTAssertEqual(editor.rowOperations?.targetOptions.map(\.key), ["slots"])
        XCTAssertEqual(editor.rowOperations?.selectedTargetKey, "slots")
        XCTAssertEqual(editor.rowOperations?.stagedCount, 0)
        XCTAssertFalse(editor.rowOperations?.targetOptions.contains { $0.key == "swarms" } == true)

        store.stageSelectedNDSDataRowOperation(
            kind: .insert,
            targetKey: "slots",
            index: 1,
            insertValue: "{\"species\":\"DISCARDED\",\"rate\":99,\"enabled\":true}"
        )
        editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.rowOperations?.stagedCount, 1)
        XCTAssertEqual(editor.rowOperations?.selectedTargetKey, "slots")
        XCTAssertEqual(editor.rowOperations?.canChangeTarget, false)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.updateSelectedNDSDataDraftText("raw replacement\n")
        editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.rowOperations?.stagedCount, 0)
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        store.discardNDSDataEdits()

        store.stageSelectedNDSDataRowOperation(
            kind: .insert,
            targetKey: "slots",
            index: 1,
            insertValue: "{\"species\":\"SHINX\",\"rate\":25,\"enabled\":true}"
        )
        store.stageSelectedNDSDataRowOperation(kind: .delete, targetKey: "slots", index: 0)
        store.stageSelectedNDSDataRowOperation(kind: .reorder, targetKey: "slots", fromIndex: 1, toIndex: 0)

        editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.rowOperations?.stagedCount, 3)
        XCTAssertEqual(editor.rowOperations?.countSummary, "2 -> 2")
        XCTAssertTrue(editor.canPreview)
        XCTAssertFalse(editor.canApply)
        XCTAssertEqual(editor.readiness.draft.value, "Dirty draft")
        XCTAssertEqual(editor.readiness.mutationPlan.value, "Preview ready")

        store.resourceAssetWorkflowFacet = .hiddenDrafts
        XCTAssertTrue(store.filteredResourceAssetRows.contains { $0.id == encounterRow.id })
        XCTAssertFalse(try XCTUnwrap(store.selectedNDSDataEditor).isHiddenByFilters)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)
        let context = try XCTUnwrap(MutationPlanPanelContext.ndsData(
            plan: store.latestNDSDataEditPlan,
            result: store.latestNDSDataApplyResult,
            editor: store.selectedNDSDataEditor
        ))
        XCTAssertEqual(context.operationCount, 3)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        let appliedChange = try XCTUnwrap(store.latestNDSDataApplyResult?.appliedChanges.first)
        XCTAssertTrue(FileManager.default.fileExists(atPath: appliedChange.backupPath))
        let updated = try String(contentsOf: root.appendingPathComponent(encounterPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"slots\":[{\"species\":\"STARLY\",\"rate\":20,\"enabled\":false},{\"species\":\"SHINX\",\"rate\":25,\"enabled\":true}]"))
        XCTAssertTrue(updated.contains("\"swarms\":[\"DODUO\",\"NIDORAN_F\"]"))
        XCTAssertTrue(updated.contains("\"metadata\":{\"map\":\"ROUTE_201\"}"))

        let scalarOnlyRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == scalarOnlyPath })
        store.requestResourceAssetSelection(scalarOnlyRow.id)
        XCTAssertNil(store.selectedNDSDataEditor?.rowOperations)
        store.stageSelectedNDSDataRowOperation(
            kind: .insert,
            targetKey: "slots",
            index: 0,
            insertValue: "{\"species\":\"BIDOOF\",\"rate\":30,\"enabled\":true}"
        )
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(try String(contentsOf: root.appendingPathComponent(scalarOnlyPath), encoding: .utf8), originalScalarOnly)

        let textRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == textPath })
        store.requestResourceAssetSelection(textRow.id)
        XCTAssertNil(store.selectedNDSDataEditor?.rowOperations)
        store.stageSelectedNDSDataRowOperation(
            kind: .insert,
            targetKey: "slots",
            index: 0,
            insertValue: "{\"species\":\"BIDOOF\",\"rate\":30,\"enabled\":true}"
        )
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8), originalText)

        let cAnchorRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == cAnchorPath })
        store.requestResourceAssetSelection(cAnchorRow.id)
        XCTAssertNil(store.selectedNDSDataEditor?.rowOperations)
        store.stageSelectedNDSDataRowOperation(
            kind: .delete,
            targetKey: "slots",
            index: 0
        )
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(try String(contentsOf: root.appendingPathComponent(cAnchorPath), encoding: .utf8), originalCAnchor)
    }

    @MainActor
    func testPlatinumFieldEventSemanticFieldEditsFlowThroughResourceEditor() async throws {
        let root = try makeNDSPlatinumSourceProject()
        let eventPath = "res/field/events/route201.json"
        let nestedPath = "res/field/events/nested/route202.json"
        try write(
            "{\"event_id\":1,\"weather\":\"CLEAR\",\"has_rival\":true,\"object_events\":[{\"id\":1,\"script\":\"Route201_Rival\"}]}\n",
            to: root.appendingPathComponent(eventPath)
        )
        try write("{\"event_id\":2}\n", to: root.appendingPathComponent(nestedPath))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let eventRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == eventPath })
        store.requestResourceAssetSelection(eventRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "maps:\(eventPath)")
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "event_id" && $0.value == "1" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "weather" && $0.value == "CLEAR" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "has_rival" && $0.value == "true" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "object_events" })

        store.updateSelectedNDSDataSemanticField(key: "event_id", value: "5")
        store.updateSelectedNDSDataSemanticField(key: "weather", value: "RAIN")
        store.updateSelectedNDSDataSemanticField(key: "has_rival", value: "false")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(eventPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"event_id\":5"))
        XCTAssertTrue(updated.contains("\"weather\":\"RAIN\""))
        XCTAssertTrue(updated.contains("\"has_rival\":false"))
        XCTAssertTrue(updated.contains("\"object_events\":[{\"id\":1,\"script\":\"Route201_Rival\"}]"))

        let nestedEventRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == nestedPath })
        store.requestResourceAssetSelection(nestedEventRow.id)
        let nestedEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(nestedEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "event_id", value: "6")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(nestedPath), encoding: .utf8),
            "{\"event_id\":2}\n"
        )
    }

    @MainActor
    func testPlatinumMapMatrixSemanticFieldEditsFlowThroughResourceEditor() async throws {
        let root = try makeNDSPlatinumSourceProject()
        let matrixPath = "res/field/matrices/route201.json"
        let nestedPath = "res/field/matrices/sinnoh/route202.json"
        let areaDataPath = "res/field/area_data/route201.json"
        try write(
            "{\"matrix\":1,\"width\":32,\"name\":\"Route 201\",\"enabled\":true,\"layout\":[[1,2]],\"evolutions\":[[\"LEVEL\",16,\"MONFERNO\"]],\"metadata\":{\"region\":\"SINNOH\"}}\n",
            to: root.appendingPathComponent(matrixPath)
        )
        try write("{\"matrix\":2}\n", to: root.appendingPathComponent(nestedPath))
        try write("{\"area\":1}\n", to: root.appendingPathComponent(areaDataPath))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let matrixRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == matrixPath })
        store.requestResourceAssetSelection(matrixRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "maps:\(matrixPath)")
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "matrix" && $0.value == "1" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "width" && $0.value == "32" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "name" && $0.value == "Route 201" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "enabled" && $0.value == "true" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "layout" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key.hasPrefix("evolutions.") })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "metadata" })

        store.updateSelectedNDSDataSemanticField(key: "evolutions.0.parameter", value: "20")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(matrixPath), encoding: .utf8),
            "{\"matrix\":1,\"width\":32,\"name\":\"Route 201\",\"enabled\":true,\"layout\":[[1,2]],\"evolutions\":[[\"LEVEL\",16,\"MONFERNO\"]],\"metadata\":{\"region\":\"SINNOH\"}}\n"
        )

        store.updateSelectedNDSDataSemanticField(key: "matrix", value: "5")
        store.updateSelectedNDSDataSemanticField(key: "name", value: "Route 201 North")
        store.updateSelectedNDSDataSemanticField(key: "enabled", value: "false")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(matrixPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"matrix\":5"))
        XCTAssertTrue(updated.contains("\"name\":\"Route 201 North\""))
        XCTAssertTrue(updated.contains("\"enabled\":false"))
        XCTAssertTrue(updated.contains("\"layout\":[[1,2]]"))
        XCTAssertTrue(updated.contains("\"evolutions\":[[\"LEVEL\",16,\"MONFERNO\"]]"))
        XCTAssertTrue(updated.contains("\"metadata\":{\"region\":\"SINNOH\"}"))

        let nestedRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == nestedPath })
        store.requestResourceAssetSelection(nestedRow.id)
        let nestedEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(nestedEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "matrix", value: "6")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(nestedPath), encoding: .utf8),
            "{\"matrix\":2}\n"
        )

        let areaDataRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == areaDataPath })
        store.requestResourceAssetSelection(areaDataRow.id)
        let areaDataEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(areaDataEditor.semanticFields.contains { $0.key == "area" && $0.value == "1" })
        store.updateSelectedNDSDataSemanticField(key: "area", value: "2")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)
        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)
        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(try String(contentsOf: root.appendingPathComponent(areaDataPath), encoding: .utf8), "{\"area\":2}\n")

        let mapBinaryRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "res/field/maps/route201/map.bin" })
        store.requestResourceAssetSelection(mapBinaryRow.id)
        let mapBinaryEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(mapBinaryEditor.semanticFields.isEmpty)
    }

    @MainActor
    func testGenIVMapReviewPacketBridgeSurfacesRowsCopyAndJumpTargetsInResources() async throws {
        let platinumRoot = try makeNDSPlatinumSourceProject()
        let platinumDefaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let platinumStore = WorkbenchStore(userDefaults: platinumDefaults, autoLoadProjects: false)

        platinumStore.openProject(path: platinumRoot.path)
        platinumStore.selectWorkbenchModule(.resources)
        platinumStore.loadSelectedAssetCatalogIfNeeded()
        let platinumCatalog = try await waitForSelectedAssetCatalog(platinumStore)
        let platinumMapRow = try XCTUnwrap(platinumCatalog.rows.first { $0.path == "res/field/maps/route201/map.bin" })
        platinumStore.requestResourceAssetSelection(platinumMapRow.id)

        let platinumEditor = try XCTUnwrap(platinumStore.selectedNDSDataEditor)
        let platinumBridge = try XCTUnwrap(platinumEditor.mapReviewBridge)
        XCTAssertEqual(platinumBridge.recordID, "maps:res/field/maps/route201/map.bin")
        XCTAssertEqual(platinumBridge.component, "map")
        XCTAssertEqual(platinumBridge.posture, "reviewOnly")
        XCTAssertEqual(platinumBridge.packetRowCount, platinumBridge.rows.count)
        XCTAssertEqual(platinumBridge.relatedRecordCount, 4)
        XCTAssertEqual(platinumBridge.includedRecordCount, 5)
        XCTAssertGreaterThan(platinumBridge.blockedActionCount, 0)
        XCTAssertGreaterThan(
            Int(factValue("Map Review Component map", in: platinumBridge.catalogSummary.componentCounts) ?? "0") ?? 0,
            0
        )
        XCTAssertNotNil(platinumBridge.rows.first { $0.id == "blocked-actions" && $0.detail?.contains("mutation apply") == true })

        NSPasteboard.general.clearContents()
        platinumStore.copySelectedNDSMapReviewPacketJSONToPasteboard()
        let json = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        XCTAssertEqual(payload["recordID"] as? String, "maps:res/field/maps/route201/map.bin")
        XCTAssertEqual(payload["relativePath"] as? String, "res/field/maps/route201/map.bin")
        let packet = try XCTUnwrap(payload["packet"] as? [String: Any])
        XCTAssertEqual(packet["component"] as? String, "map")
        XCTAssertEqual(packet["posture"] as? String, "reviewOnly")
        let summary = try XCTUnwrap(payload["catalogSummary"] as? [String: Any])
        XCTAssertGreaterThanOrEqual(summary["totalPacketCount"] as? Int ?? 0, 1)

        NSPasteboard.general.clearContents()
        platinumStore.copySelectedNDSMapReviewPacketMarkdownToPasteboard()
        let markdown = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        XCTAssertTrue(markdown.contains("# Gen IV Map Review Handoff"))
        XCTAssertTrue(markdown.contains("maps:res/field/maps/route201/map.bin"))
        XCTAssertTrue(markdown.contains("mutation apply"))

        let matrixTarget = try XCTUnwrap(platinumBridge.targets.first { $0.recordID == "maps:res/field/matrices/route201.json" })
        XCTAssertTrue(matrixTarget.canJump)
        XCTAssertTrue(platinumStore.focusNDSMapReviewTarget(matrixTarget))
        XCTAssertEqual(platinumStore.selectedResourceAssetID, matrixTarget.assetID)
        XCTAssertEqual(platinumStore.selectedResourceAsset?.path, "res/field/matrices/route201.json")

        let diamondRoot = try makeNDSSourceProject()
        try write(
            """
            #include "map_header.h"

            static const struct MapHeader sMapHeaders[] = {
                { NARC_area_data_narc_0000_bin, 20, NARC_map_matrix_narc_0000_bin, NARC_scr_seq_release_narc_0001_bin, NARC_scr_seq_release_narc_0464_bin, NARC_msg_narc_0018_bin, SEQ_CITY01_D, SEQ_CITY01_N, 0xFFFF, NARC_zone_event_release_narc_0001_bin, MAPSEC_JUBILIFE_CITY, 0, 4, 4, 6, TRUE, TRUE, FALSE, TRUE },
            };

            void MapHeader_Load(void) {}

            """,
            to: diamondRoot.appendingPathComponent("arm9/src/map_header.c")
        )
        let diamondDefaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let diamondStore = WorkbenchStore(userDefaults: diamondDefaults, autoLoadProjects: false)

        diamondStore.openProject(path: diamondRoot.path)
        diamondStore.selectWorkbenchModule(.resources)
        diamondStore.loadSelectedAssetCatalogIfNeeded()
        let diamondCatalog = try await waitForSelectedAssetCatalog(diamondStore)
        let diamondMatrixRow = try XCTUnwrap(diamondCatalog.rows.first { $0.path == "files/fielddata/mapmatrix" })
        diamondStore.requestResourceAssetSelection(diamondMatrixRow.id)

        let diamondBridge = try XCTUnwrap(diamondStore.selectedNDSDataEditor?.mapReviewBridge)
        XCTAssertEqual(diamondBridge.family, "diamondPearl")
        XCTAssertGreaterThan(
            Int(factValue("Map Review Component mapHeader", in: diamondBridge.catalogSummary.componentCounts) ?? "0") ?? 0,
            0
        )
        XCTAssertGreaterThan(
            Int(factValue("Map Review Component matrix", in: diamondBridge.catalogSummary.componentCounts) ?? "0") ?? 0,
            0
        )
        XCTAssertGreaterThan(
            Int(factValue("Map Review Component table", in: diamondBridge.catalogSummary.componentCounts) ?? "0") ?? 0,
            0
        )
        XCTAssertGreaterThan(
            Int(factValue("Map Review Component land", in: diamondBridge.catalogSummary.componentCounts) ?? "0") ?? 0,
            0
        )
        XCTAssertGreaterThan(
            Int(factValue("Map Review Component area", in: diamondBridge.catalogSummary.componentCounts) ?? "0") ?? 0,
            0
        )

        let heartGoldRoot = try makeNDSHeartGoldSourceProject()
        let heartGoldDefaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let heartGoldStore = WorkbenchStore(userDefaults: heartGoldDefaults, autoLoadProjects: false)

        heartGoldStore.openProject(path: heartGoldRoot.path)
        heartGoldStore.selectWorkbenchModule(.resources)
        heartGoldStore.loadSelectedAssetCatalogIfNeeded()
        let heartGoldCatalog = try await waitForSelectedAssetCatalog(heartGoldStore)
        let heartGoldMatrixRow = try XCTUnwrap(heartGoldCatalog.rows.first { $0.path == "files/fielddata/mapmatrix" })
        heartGoldStore.requestResourceAssetSelection(heartGoldMatrixRow.id)

        let heartGoldEditor = try XCTUnwrap(heartGoldStore.selectedNDSDataEditor)
        let heartGoldBridge = try XCTUnwrap(heartGoldEditor.mapReviewBridge)
        XCTAssertFalse(heartGoldEditor.canEdit)
        XCTAssertFalse(heartGoldEditor.canPreview)
        XCTAssertFalse(heartGoldEditor.canApply)
        XCTAssertEqual(heartGoldBridge.family, "heartGoldSoulSilver")
        XCTAssertGreaterThan(
            Int(factValue("Map Review Component matrix", in: heartGoldBridge.catalogSummary.componentCounts) ?? "0") ?? 0,
            0
        )
        XCTAssertGreaterThan(
            Int(factValue("Map Review Component table", in: heartGoldBridge.catalogSummary.componentCounts) ?? "0") ?? 0,
            0
        )
        XCTAssertGreaterThan(
            Int(factValue("Map Review Component mapHeader", in: heartGoldBridge.catalogSummary.componentCounts) ?? "0") ?? 0,
            0
        )
        XCTAssertTrue(heartGoldBridge.targets.contains { $0.recordID == "maps:files/fielddata/maptable" && $0.canJump })
        XCTAssertTrue(heartGoldBridge.targets.contains { $0.recordID == "maps:src/data/map_headers.h" && $0.canJump })
    }

    @MainActor
    func testHGSSPersonalTrainerAndItemSemanticFieldEditsFlowThroughResourceEditor() async throws {
        let root = try makeNDSHeartGoldSourceProject()
        let personalPath = "files/poketool/personal/personal.json"
        let personalBinaryPath = "files/poketool/personal/personal_0000.bin"
        let trainerPath = "files/poketool/trainer/trainers.json"
        let trainerBinaryPath = "files/poketool/trainer/trainer_0000.bin"
        let itemPath = "files/itemtool/itemdata/potion.json"
        let itemCSVPath = "files/itemtool/itemdata/item_data.csv"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let personalRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == personalPath })
        store.requestResourceAssetSelection(personalRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "personal:\(personalPath)")
        XCTAssertEqual(editor.semanticFields.map(\.key), ["species"])
        XCTAssertEqual(editor.semanticFields.first?.value, "CHIKORITA")

        store.updateSelectedNDSDataSemanticField(key: "species", value: "CYNDAQUIL")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        XCTAssertTrue(
            try String(contentsOf: root.appendingPathComponent(personalPath), encoding: .utf8)
                .contains("\"species\":\"CYNDAQUIL\"")
        )

        let trainerRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == trainerPath })
        store.requestResourceAssetSelection(trainerRow.id)
        let trainerEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(trainerEditor.recordID, "trainers:\(trainerPath)")
        XCTAssertTrue(trainerEditor.semanticFields.contains { $0.key == "id" && $0.value == "1" })
        XCTAssertTrue(trainerEditor.semanticFields.contains { $0.key == "name" && $0.value == "Youngster Joey" })
        XCTAssertTrue(trainerEditor.semanticFields.contains { $0.key == "double_battle" && $0.value == "false" })
        XCTAssertFalse(trainerEditor.semanticFields.contains { $0.key == "party" })
        store.updateSelectedNDSDataSemanticField(key: "double_battle", value: "true")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        XCTAssertTrue(
            try String(contentsOf: root.appendingPathComponent(trainerPath), encoding: .utf8)
                .contains("\"double_battle\":true")
        )

        let itemJSONRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == itemPath })
        store.requestResourceAssetSelection(itemJSONRow.id)
        let itemJSONEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(itemJSONEditor.recordID, "items:\(itemPath)")
        XCTAssertTrue(itemJSONEditor.semanticFields.contains { $0.key == "name" && $0.value == "POTION" })
        XCTAssertTrue(itemJSONEditor.semanticFields.contains { $0.key == "price" && $0.value == "300" })
        XCTAssertTrue(itemJSONEditor.semanticFields.contains { $0.key == "field_use" && $0.value == "true" })
        XCTAssertFalse(itemJSONEditor.semanticFields.contains { $0.key == "effects" })
        store.updateSelectedNDSDataSemanticField(key: "price", value: "700")
        store.updateSelectedNDSDataSemanticField(key: "field_use", value: "false")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        let updatedItemJSON = try String(
            contentsOf: root.appendingPathComponent(itemPath),
            encoding: .utf8
        )
        XCTAssertTrue(updatedItemJSON.contains("\"price\":700"))
        XCTAssertTrue(updatedItemJSON.contains("\"field_use\":false"))
        XCTAssertTrue(updatedItemJSON.contains("\"effects\":[{\"kind\":\"heal\",\"amount\":20}]"))

        let itemRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == itemCSVPath })
        store.requestResourceAssetSelection(itemRow.id)
        let itemEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(itemEditor.recordID, "items:\(itemCSVPath)")
        XCTAssertTrue(itemEditor.semanticFields.contains { $0.key == "rows.0.id" && $0.value == "1" })
        XCTAssertTrue(itemEditor.semanticFields.contains { $0.key == "rows.0.name" && $0.value == "POTION" })
        store.updateSelectedNDSDataSemanticField(key: "name", value: "SUPER_POTION")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertNil(store.latestNDSDataEditPlan)

        let personalBinaryRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == personalBinaryPath })
        store.requestResourceAssetSelection(personalBinaryRow.id)
        let personalBinaryEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(personalBinaryEditor.recordID, "personal:\(personalBinaryPath)")
        XCTAssertTrue(personalBinaryEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "species", value: "TOTODILE")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertNil(store.latestNDSDataEditPlan)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(personalBinaryPath)), Data([0x01]))

        let trainerBinaryRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == trainerBinaryPath })
        store.requestResourceAssetSelection(trainerBinaryRow.id)
        let trainerBinaryEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(trainerBinaryEditor.recordID, "trainers:\(trainerBinaryPath)")
        XCTAssertTrue(trainerBinaryEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "double_battle", value: "false")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertNil(store.latestNDSDataEditPlan)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(trainerBinaryPath)), Data([0x02]))
    }

    @MainActor
    func testHeartGoldSoulSilverItemCSVSemanticFieldEditsFlowThroughResourceEditor() async throws {
        let root = try makeNDSHeartGoldSourceProject()
        let itemCSVPath = "files/itemtool/itemdata/item_data.csv"
        let nestedCSVPath = "files/itemtool/itemdata/nested/item_data.csv"
        let binaryItemPath = "files/itemtool/itemdata/item_0000.bin"
        try write(
            """
            id,name,description
            1,POTION,"Basic, heal"
            2,ANTIDOTE,Status

            """,
            to: root.appendingPathComponent(itemCSVPath)
        )
        try write("id,name\n1,NESTED\n", to: root.appendingPathComponent(nestedCSVPath))
        try write(Data([0x05]), to: root.appendingPathComponent(binaryItemPath))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let itemCSVRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == itemCSVPath })
        store.requestResourceAssetSelection(itemCSVRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "items:\(itemCSVPath)")
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "rows.0.name" && $0.value == "POTION" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "rows.0.description" && $0.value == "Basic, heal" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "rows.1.name" && $0.value == "ANTIDOTE" })

        store.updateSelectedNDSDataSemanticField(key: "rows.0.name", value: "SUPER, POTION")
        store.updateSelectedNDSDataSemanticField(key: "rows.1.description", value: "Cures \"poison\"")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(itemCSVPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("1,\"SUPER, POTION\",\"Basic, heal\""))
        XCTAssertTrue(updated.contains("2,ANTIDOTE,\"Cures \"\"poison\"\"\""))

        let nestedRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == nestedCSVPath })
        store.requestResourceAssetSelection(nestedRow.id)
        let nestedEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(nestedEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "rows.0.name", value: "NESTED_EDIT")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(nestedCSVPath), encoding: .utf8),
            "id,name\n1,NESTED\n"
        )

        let binaryItemRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == binaryItemPath })
        store.requestResourceAssetSelection(binaryItemRow.id)
        let binaryEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(binaryEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "rows.0.name", value: "BINARY")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(binaryItemPath)), Data([0x05]))
    }

    @MainActor
    func testHeartGoldSoulSilverItemCSVRowOperationsFlowThroughResourceEditor() async throws {
        let root = try makeNDSHeartGoldSourceProject()
        let itemCSVPath = "files/itemtool/itemdata/item_data.csv"
        let nestedCSVPath = "files/itemtool/itemdata/nested/item_data.csv"
        let binaryItemPath = "files/itemtool/itemdata/item_0000.bin"
        try write(
            """
            id,name,description
            1,POTION,Basic heal
            2,ANTIDOTE,Status

            """,
            to: root.appendingPathComponent(itemCSVPath)
        )
        try write("id,name\n1,NESTED\n", to: root.appendingPathComponent(nestedCSVPath))
        try write(Data([0x05]), to: root.appendingPathComponent(binaryItemPath))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let itemCSVRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == itemCSVPath })
        store.requestResourceAssetSelection(itemCSVRow.id)

        var editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "items:\(itemCSVPath)")
        XCTAssertEqual(editor.rowOperations?.family, .itemCSVRows)
        XCTAssertEqual(editor.rowOperations?.stagedCount, 0)

        store.stageSelectedNDSDataRowOperation(kind: .insert, index: 1, insertValue: "3,\"SUPER, POTION\",Large heal")
        store.stageSelectedNDSDataRowOperation(kind: .delete, index: 0)
        store.stageSelectedNDSDataRowOperation(kind: .reorder, fromIndex: 1, toIndex: 0)

        editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.rowOperations?.stagedCount, 3)
        XCTAssertEqual(editor.rowOperations?.countSummary, "2 -> 2")
        XCTAssertTrue(editor.canPreview)
        XCTAssertFalse(editor.canApply)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(itemCSVPath), encoding: .utf8),
            """
            id,name,description
            2,ANTIDOTE,Status
            3,\"SUPER, POTION\",Large heal

            """
        )

        store.requestResourceAssetSelection(itemCSVRow.id)
        store.stageSelectedNDSDataRowOperation(kind: .insert, index: 0, insertValue: "4,ETHER,Restore")
        XCTAssertEqual(store.selectedNDSDataEditor?.rowOperations?.stagedCount, 1)
        store.removeLastSelectedNDSDataRowOperation()
        XCTAssertEqual(store.selectedNDSDataEditor?.rowOperations?.stagedCount, 0)
        store.stageSelectedNDSDataRowOperation(kind: .insert, index: 0, insertValue: "4,ETHER,Restore")
        store.clearSelectedNDSDataRowOperations()
        XCTAssertEqual(store.selectedNDSDataEditor?.rowOperations?.stagedCount, 0)

        let nestedRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == nestedCSVPath })
        store.requestResourceAssetSelection(nestedRow.id)
        XCTAssertNil(store.selectedNDSDataEditor?.rowOperations)
        store.stageSelectedNDSDataRowOperation(kind: .insert, index: 0, insertValue: "2,NESTED2")
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(nestedCSVPath), encoding: .utf8),
            "id,name\n1,NESTED\n"
        )

        let binaryItemRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == binaryItemPath })
        store.requestResourceAssetSelection(binaryItemRow.id)
        XCTAssertNil(store.selectedNDSDataEditor?.rowOperations)
        store.stageSelectedNDSDataRowOperation(kind: .insert, index: 0, insertValue: "4,BINARY,Blocked")
        XCTAssertFalse(store.canPreviewSelectedNDSDataMutationPlan)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(binaryItemPath)), Data([0x05]))
    }

    @MainActor
    func testHeartGoldSoulSilverMapHeaderSemanticFieldEditsFlowThroughResourceEditor() async throws {
        let root = try makeNDSHeartGoldSourceProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let mapHeaderRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "src/data/map_headers.h" })
        store.requestResourceAssetSelection(mapHeaderRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "maps:src/data/map_headers.h")
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "mapHeaders.MAP_EVERYWHERE.areaDataBank" && $0.value == "0" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "mapHeaders.MAP_EVERYWHERE.worldMapX" && $0.value == "0" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "mapHeaders.MAP_NEW_BARK.weather" && $0.value == "1" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "mapHeaders.MAP_EVERYWHERE.mapType" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "mapHeaders.MAP_EVERYWHERE.bikeAllowed" })

        store.updateSelectedNDSDataSemanticField(key: "mapHeaders.MAP_EVERYWHERE.areaDataBank", value: "8")
        store.updateSelectedNDSDataSemanticField(key: "mapHeaders.MAP_EVERYWHERE.worldMapX", value: "9")
        store.updateSelectedNDSDataSemanticField(key: "mapHeaders.MAP_NEW_BARK.cameraType", value: "4")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("src/data/map_headers.h"), encoding: .utf8)
        XCTAssertTrue(updated.contains(".areaDataBank = 8"))
        XCTAssertTrue(updated.contains(".worldMapX = 9"))
        XCTAssertTrue(updated.contains("[MAP_NEW_BARK] = { .areaDataBank = 3, .worldMapX = 4, .worldMapY = 7, .weather = 1, .cameraType = 4, .bikeAllowed = FALSE }"))

        let matrixRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "files/fielddata/mapmatrix/0001.bin" })
        store.requestResourceAssetSelection(matrixRow.id)
        let matrixEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(matrixEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "mapHeaders.MAP_EVERYWHERE.areaDataBank", value: "7")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertNil(store.latestNDSDataEditPlan)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent("files/fielddata/mapmatrix/0001.bin")), Data([0x00]))
    }

    @MainActor
    func testDiamondPearlPersonalAndTrainerJSONSemanticFieldEditsFlowThroughResourceEditor() async throws {
        let root = try makeNDSSourceProject()
        let personalPath = "files/poketool/personal/turtwig.json"
        let personalPearlPath = "files/poketool/personal_pearl/piplup.json"
        let personalBinaryPath = "files/poketool/personal/personal_0000.bin"
        let trainerPath = "files/poketool/trainer/youngster.json"
        let trainerBinaryPath = "files/poketool/trainer/trainer_0000.bin"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)

        let personalRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == personalPath })
        store.requestResourceAssetSelection(personalRow.id)
        let personalEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(personalEditor.recordID, "personal:\(personalPath)")
        XCTAssertTrue(personalEditor.semanticFields.contains { $0.key == "species" && $0.value == "TURTWIG" })
        XCTAssertTrue(personalEditor.semanticFields.contains { $0.key == "base_hp" && $0.value == "55" })
        XCTAssertTrue(personalEditor.semanticFields.contains { $0.key == "catch_rate" && $0.value == "45" })
        XCTAssertFalse(personalEditor.semanticFields.contains { $0.key == "forms" })

        store.updateSelectedNDSDataSemanticField(key: "species", value: "GROTLE")
        store.updateSelectedNDSDataSemanticField(key: "base_hp", value: "75")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        let updatedPersonal = try String(contentsOf: root.appendingPathComponent(personalPath), encoding: .utf8)
        XCTAssertTrue(updatedPersonal.contains("\"species\":\"GROTLE\""))
        XCTAssertTrue(updatedPersonal.contains("\"base_hp\":75"))
        XCTAssertTrue(updatedPersonal.contains("\"forms\":[{\"form\":\"default\"}]"))

        let personalPearlRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == personalPearlPath })
        store.requestResourceAssetSelection(personalPearlRow.id)
        let personalPearlEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(personalPearlEditor.recordID, "personal:\(personalPearlPath)")
        XCTAssertTrue(personalPearlEditor.semanticFields.contains { $0.key == "species" && $0.value == "PIPLUP" })
        XCTAssertTrue(personalPearlEditor.semanticFields.contains { $0.key == "base_hp" && $0.value == "53" })
        XCTAssertFalse(personalPearlEditor.semanticFields.contains { $0.key == "forms" })

        store.updateSelectedNDSDataSemanticField(key: "catch_rate", value: "30")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        let updatedPersonalPearl = try String(contentsOf: root.appendingPathComponent(personalPearlPath), encoding: .utf8)
        XCTAssertTrue(updatedPersonalPearl.contains("\"catch_rate\":30"))
        XCTAssertTrue(updatedPersonalPearl.contains("\"forms\":[{\"form\":\"pearl\"}]"))

        let trainerRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == trainerPath })
        store.requestResourceAssetSelection(trainerRow.id)
        let trainerEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(trainerEditor.recordID, "trainers:\(trainerPath)")
        XCTAssertTrue(trainerEditor.semanticFields.contains { $0.key == "id" && $0.value == "7" })
        XCTAssertTrue(trainerEditor.semanticFields.contains { $0.key == "name" && $0.value == "Youngster Dan" })
        XCTAssertTrue(trainerEditor.semanticFields.contains { $0.key == "double_battle" && $0.value == "false" })
        XCTAssertFalse(trainerEditor.semanticFields.contains { $0.key == "party" })

        store.updateSelectedNDSDataSemanticField(key: "name", value: "Youngster Dawn")
        store.updateSelectedNDSDataSemanticField(key: "double_battle", value: "true")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        let updatedTrainer = try String(contentsOf: root.appendingPathComponent(trainerPath), encoding: .utf8)
        XCTAssertTrue(updatedTrainer.contains("\"name\":\"Youngster Dawn\""))
        XCTAssertTrue(updatedTrainer.contains("\"double_battle\":true"))
        XCTAssertTrue(updatedTrainer.contains("\"party\":[{\"species\":\"STARLY\",\"level\":5}]"))

        let personalBinaryRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == personalBinaryPath })
        store.requestResourceAssetSelection(personalBinaryRow.id)
        let personalBinaryEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(personalBinaryEditor.recordID, "personal:\(personalBinaryPath)")
        XCTAssertTrue(personalBinaryEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "species", value: "CHIMCHAR")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertNil(store.latestNDSDataEditPlan)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(personalBinaryPath)), Data([0x03]))

        let trainerBinaryRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == trainerBinaryPath })
        store.requestResourceAssetSelection(trainerBinaryRow.id)
        let trainerBinaryEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(trainerBinaryEditor.recordID, "trainers:\(trainerBinaryPath)")
        XCTAssertTrue(trainerBinaryEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "double_battle", value: "false")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertNil(store.selectedNDSDataDraft)
        XCTAssertNil(store.latestNDSDataEditPlan)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(trainerBinaryPath)), Data([0x04]))
    }

    @MainActor
    func testHiddenNDSDraftFacetInvalidatesCachedResourceRowsWhenDraftChanges() async throws {
        let root = try makeNDSSourceProject()
        let personalPath = "files/poketool/personal/turtwig.json"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let personalRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == personalPath })

        store.resourceAssetWorkflowFacet = .hiddenDrafts
        XCTAssertFalse(store.filteredResourceAssetRows.contains { $0.id == personalRow.id })

        store.requestResourceAssetSelection(personalRow.id)
        store.updateSelectedNDSDataSemanticField(key: "species", value: "GROTLE")

        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.filteredResourceAssetRows.contains { $0.id == personalRow.id })

        store.discardNDSDataEdits()

        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertFalse(store.filteredResourceAssetRows.contains { $0.id == personalRow.id })
    }

    @MainActor
    func testDiamondPearlItemMappingSemanticFieldEditsFlowThroughResourceEditor() async throws {
        let root = try makeNDSSourceProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let itemCRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "arm9/src/itemtool.c" })
        store.requestResourceAssetSelection(itemCRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "items:arm9/src/itemtool.c")
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "itemIndexMappings.1.itemDataIndex" && $0.value == "1" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "itemIndexMappings.1.iconIndex" && $0.value == "2" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "itemIndexMappings.2.itemDataIndex" })

        store.updateSelectedNDSDataSemanticField(key: "itemIndexMappings.1.itemDataIndex", value: "42")
        store.updateSelectedNDSDataSemanticField(key: "itemIndexMappings.1.iconIndex", value: "24")
        store.updateSelectedNDSDataSemanticField(key: "itemIndexMappings.1.paletteIndex", value: "11")
        store.updateSelectedNDSDataSemanticField(key: "itemIndexMappings.1.gen3Index", value: "9")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("arm9/src/itemtool.c"), encoding: .utf8)
        XCTAssertTrue(updated.contains("{ 42, 24, 11, 9 }"))
        XCTAssertTrue(updated.contains("ITEM_DATA_COUNT"))

        let binaryItemRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "files/itemtool/itemdata/item_0000.bin" })
        store.requestResourceAssetSelection(binaryItemRow.id)
        let binaryEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(binaryEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "itemIndexMappings.0.itemDataIndex", value: "7")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
    }

    @MainActor
    func testDiamondPearlTrainerClassGenderSemanticFieldEditsFlowThroughResourceEditor() async throws {
        let root = try makeNDSSourceProject()
        try write(Data([0x00]), to: root.appendingPathComponent("files/poketool/trainer/trainer_0000.bin"))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let trainerCRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "arm9/src/trainer_data.c" })
        store.requestResourceAssetSelection(trainerCRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "trainers:arm9/src/trainer_data.c")
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "trainerClassGenderCounts.0.genderCount" && $0.value == "0" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "trainerClassGenderCounts.1.genderCount" && $0.value == "1" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "trainerClassGenderCounts.2.genderCount" && $0.value == "2" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "trainerClassGenderCounts.3.genderCount" })

        store.updateSelectedNDSDataSemanticField(key: "trainerClassGenderCounts.0.genderCount", value: "1")
        store.updateSelectedNDSDataSemanticField(key: "trainerClassGenderCounts.2.genderCount", value: "0")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("arm9/src/trainer_data.c"), encoding: .utf8)
        XCTAssertTrue(updated.contains("/*TRAINER_CLASS_PKMN_TRAINER_M*/ 1"))
        XCTAssertTrue(updated.contains("/*TRAINER_CLASS_TWINS*/ 0"))
        XCTAssertTrue(updated.contains("TRAINER_CLASS_GENDER_COUNT_SENTINEL"))

        let binaryTrainerRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "files/poketool/trainer/trainer_0000.bin" })
        store.requestResourceAssetSelection(binaryTrainerRow.id)
        let binaryEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(binaryEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "trainerClassGenderCounts.0.genderCount", value: "2")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
    }

    @MainActor
    func testDiamondPearlItemJSONSemanticFieldEditsFlowThroughResourceEditor() async throws {
        let root = try makeNDSSourceProject()
        let itemPath = "files/itemtool/itemdata/potion.json"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let itemRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == itemPath })
        store.requestResourceAssetSelection(itemRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "items:\(itemPath)")
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "name" && $0.value == "POTION" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "price" && $0.value == "300" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "field_use" && $0.value == "true" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "effects" })

        store.updateSelectedNDSDataSemanticField(key: "name", value: "SUPER_POTION")
        store.updateSelectedNDSDataSemanticField(key: "price", value: "700")
        store.updateSelectedNDSDataSemanticField(key: "field_use", value: "false")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(itemPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"name\":\"SUPER_POTION\""))
        XCTAssertTrue(updated.contains("\"price\":700"))
        XCTAssertTrue(updated.contains("\"field_use\":false"))
        XCTAssertTrue(updated.contains("\"effects\":[{\"kind\":\"heal\",\"amount\":20}]"))

        let binaryItemRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "files/itemtool/itemdata/item_0000.bin" })
        store.requestResourceAssetSelection(binaryItemRow.id)
        let binaryEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(binaryEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "price", value: "800")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
    }

    @MainActor
    func testDiamondPearlEncounterSemanticFieldEditsFlowThroughResourceEditor() async throws {
        let root = try makeNDSSourceProject()
        let encounterPath = "files/fielddata/encountdata/sinnoh/route201.json"
        try write(
            """
            {"rate": 20, "morning_rate": 10, "enabled": true, "slots": [{"species":"BIDOOF","rate":30}], "metadata": {"map":"ROUTE_201"}}

            """,
            to: root.appendingPathComponent(encounterPath)
        )
        try write("rate=15\n", to: root.appendingPathComponent("files/fielddata/encountdata/route202.txt"))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let encounterRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == encounterPath })
        store.requestResourceAssetSelection(encounterRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "encounters:\(encounterPath)")
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "rate" && $0.value == "20" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "enabled" && $0.value == "true" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "slots" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "metadata" })

        store.updateSelectedNDSDataSemanticField(key: "rate", value: "25")
        store.updateSelectedNDSDataSemanticField(key: "enabled", value: "false")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(encounterPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"rate\": 25"))
        XCTAssertTrue(updated.contains("\"enabled\": false"))
        XCTAssertTrue(updated.contains("\"slots\": [{\"species\":\"BIDOOF\",\"rate\":30}]"))

        let textRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "files/fielddata/encountdata/route202.txt" })
        store.requestResourceAssetSelection(textRow.id)
        let textEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(textEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "rate", value: "20")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("files/fielddata/encountdata/route202.txt"), encoding: .utf8),
            "rate=15\n"
        )
    }

    @MainActor
    func testDiamondPearlFieldEventSemanticFieldEditsFlowThroughResourceEditor() async throws {
        let root = try makeNDSSourceProject()
        let eventPath = "files/fielddata/eventdata/route201.json"
        let nestedPath = "files/fielddata/eventdata/sinnoh/route202.json"
        let textPath = "files/fielddata/eventdata/route203.txt"
        try write(
            """
            {"event_id": 10, "weather": "CLEAR", "has_rival": true, "object_events": [{"id":1,"script":"Route201_Rival"}], "metadata": {"map":"ROUTE_201"}}

            """,
            to: root.appendingPathComponent(eventPath)
        )
        try write("{\"event_id\":11}\n", to: root.appendingPathComponent(nestedPath))
        try write("event_id=12\n", to: root.appendingPathComponent(textPath))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let eventRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == eventPath })
        store.requestResourceAssetSelection(eventRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "maps:\(eventPath)")
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "event_id" && $0.value == "10" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "weather" && $0.value == "CLEAR" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "has_rival" && $0.value == "true" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "object_events" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "metadata" })

        store.updateSelectedNDSDataSemanticField(key: "event_id", value: "15")
        store.updateSelectedNDSDataSemanticField(key: "weather", value: "RAIN")
        store.updateSelectedNDSDataSemanticField(key: "has_rival", value: "false")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(eventPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"event_id\": 15"))
        XCTAssertTrue(updated.contains("\"weather\": \"RAIN\""))
        XCTAssertTrue(updated.contains("\"has_rival\": false"))
        XCTAssertTrue(updated.contains("\"object_events\": [{\"id\":1,\"script\":\"Route201_Rival\"}]"))

        let nestedRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == nestedPath })
        store.requestResourceAssetSelection(nestedRow.id)
        let nestedEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(nestedEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "event_id", value: "20")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(nestedPath), encoding: .utf8),
            "{\"event_id\":11}\n"
        )

        let textRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == textPath })
        store.requestResourceAssetSelection(textRow.id)
        let textEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(textEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "event_id", value: "20")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8),
            "event_id=12\n"
        )
    }

    @MainActor
    func testDiamondPearlLandDataSemanticFieldEditsFlowThroughResourceEditor() async throws {
        let root = try makeNDSSourceProject()
        let landDataPath = "files/fielddata/land_data/land_0002.json"
        let nestedPath = "files/fielddata/land_data/sinnoh/land_0003.json"
        try write(
            """
            {"land_id": 10, "name": "Route 202 Land", "enabled": true, "weather": null, "tiles": [{"terrain":"grass"}], "metadata": {"map":"ROUTE_202"}}

            """,
            to: root.appendingPathComponent(landDataPath)
        )
        try write("{\"land_id\":11}\n", to: root.appendingPathComponent(nestedPath))
        let binaryLandPath = "files/fielddata/land_data/land_0001.bin"
        let binaryLandData = try Data(contentsOf: root.appendingPathComponent(binaryLandPath))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let landDataRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == landDataPath })
        store.requestResourceAssetSelection(landDataRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "maps:\(landDataPath)")
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "land_id" && $0.value == "10" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "name" && $0.value == "Route 202 Land" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "enabled" && $0.value == "true" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "weather" && $0.value == "null" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "tiles" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "metadata" })

        store.updateSelectedNDSDataSemanticField(key: "land_id", value: "15")
        store.updateSelectedNDSDataSemanticField(key: "name", value: "Route 202 North Land")
        store.updateSelectedNDSDataSemanticField(key: "enabled", value: "false")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)

        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(landDataPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"land_id\": 15"))
        XCTAssertTrue(updated.contains("\"name\": \"Route 202 North Land\""))
        XCTAssertTrue(updated.contains("\"enabled\": false"))
        XCTAssertTrue(updated.contains("\"tiles\": [{\"terrain\":\"grass\"}]"))

        let nestedRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == nestedPath })
        store.requestResourceAssetSelection(nestedRow.id)
        let nestedEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(nestedEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "land_id", value: "20")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(nestedPath), encoding: .utf8),
            "{\"land_id\":11}\n"
        )

        let binaryRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == binaryLandPath })
        store.requestResourceAssetSelection(binaryRow.id)
        let binaryEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(binaryEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "land_id", value: "20")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(binaryLandPath)), binaryLandData)
    }

    @MainActor
    func testHGSSZoneEventSemanticFieldEditsFlowThroughResourceEditor() async throws {
        let root = try makeNDSHeartGoldSourceProject()
        let zoneEventPath = "files/fielddata/eventdata/zone_event/zone_001.json"
        let nestedPath = "files/fielddata/eventdata/zone_event/johto/zone_002.json"
        try write(
            "{\"zone_id\":1,\"script\":\"Route29_Intro\",\"enabled\":true,\"object_events\":[{\"id\":1,\"script\":\"Route29_NPC\"}],\"metadata\":{\"map\":\"ROUTE_29\"}}\n",
            to: root.appendingPathComponent(zoneEventPath)
        )
        try write("{\"zone_id\":2}\n", to: root.appendingPathComponent(nestedPath))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let zoneEventRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == zoneEventPath })
        store.requestResourceAssetSelection(zoneEventRow.id)

        let editor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertEqual(editor.recordID, "scripts:\(zoneEventPath)")
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "zone_id" && $0.value == "1" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "script" && $0.value == "Route29_Intro" })
        XCTAssertTrue(editor.semanticFields.contains { $0.key == "enabled" && $0.value == "true" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "object_events" })
        XCTAssertFalse(editor.semanticFields.contains { $0.key == "metadata" })

        store.updateSelectedNDSDataSemanticField(key: "zone_id", value: "3")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        XCTAssertTrue(store.canPreviewSelectedNDSDataMutationPlan)
        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)
        store.discardNDSDataEdits()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(zoneEventPath), encoding: .utf8),
            "{\"zone_id\":1,\"script\":\"Route29_Intro\",\"enabled\":true,\"object_events\":[{\"id\":1,\"script\":\"Route29_NPC\"}],\"metadata\":{\"map\":\"ROUTE_29\"}}\n"
        )

        store.updateSelectedNDSDataSemanticField(key: "script", value: "Route29_Edit")
        store.updateSelectedNDSDataSemanticField(key: "enabled", value: "false")
        XCTAssertTrue(store.selectedNDSDataIsDirty)
        store.previewSelectedNDSDataMutationPlan()
        XCTAssertEqual(store.latestNDSDataEditPlan?.changes.count, 1)
        XCTAssertTrue(store.canApplySelectedNDSDataMutationPlan)

        store.applySelectedNDSDataMutationPlan()
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(store.latestNDSDataApplyResult?.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(zoneEventPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"script\":\"Route29_Edit\""))
        XCTAssertTrue(updated.contains("\"enabled\":false"))
        XCTAssertTrue(updated.contains("\"object_events\":[{\"id\":1,\"script\":\"Route29_NPC\"}]"))
        XCTAssertTrue(updated.contains("\"metadata\":{\"map\":\"ROUTE_29\"}"))

        let nestedZoneEventRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == nestedPath })
        store.requestResourceAssetSelection(nestedZoneEventRow.id)
        let nestedEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(nestedEditor.semanticFields.isEmpty)
        store.updateSelectedNDSDataSemanticField(key: "zone_id", value: "6")
        XCTAssertFalse(store.selectedNDSDataIsDirty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(nestedPath), encoding: .utf8),
            "{\"zone_id\":2}\n"
        )

        let scriptBinaryRow = try XCTUnwrap(assetCatalog.rows.first { $0.path == "files/fielddata/script/scr_seq/0001.bin" })
        XCTAssertTrue(scriptBinaryRow.facts.contains { $0.label == "Gen IV Source Role" && $0.value == "hgssScriptSequenceMember" })
        XCTAssertTrue(scriptBinaryRow.facts.contains { $0.label == "Gen IV Source Provenance" && $0.value == "heartGoldSoulSilver:files/fielddata/script/scr_seq" })
        XCTAssertTrue(scriptBinaryRow.facts.contains { $0.label == "Gen IV Blocked Actions" && $0.value.contains("script binary write") })
        XCTAssertTrue(scriptBinaryRow.facts.contains { $0.label == "Gen IV Action State" && $0.value.contains("inventory-only HGSS script-sequence metadata") })
        store.requestResourceAssetSelection(scriptBinaryRow.id)
        let scriptBinaryEditor = try XCTUnwrap(store.selectedNDSDataEditor)
        XCTAssertTrue(scriptBinaryEditor.semanticFields.isEmpty)
    }

    @MainActor
    func testLocalPlatinumSourceAndROMSurfaceTextAndMigrationFactsInResources() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let sourcePath = environment["PHS_LOCAL_PLATINUM_SOURCE_PATH"], !sourcePath.isEmpty else {
            throw XCTSkip("Set PHS_LOCAL_PLATINUM_SOURCE_PATH to run the local Platinum Resources smoke.")
        }
        guard let romPath = environment["PHS_LOCAL_PLATINUM_ROM_PATH"], !romPath.isEmpty else {
            throw XCTSkip("Set PHS_LOCAL_PLATINUM_ROM_PATH to run the local Platinum ROM Resources smoke.")
        }

        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: sourcePath)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded()
        let sourceCatalog = try await waitForSelectedAssetCatalog(store)
        let abilityNames = try XCTUnwrap(sourceCatalog.rows.first { $0.path == "res/text/ability_names.json" })
        XCTAssertTrue(abilityNames.facts.contains { $0.label == "Text Bank Preview" && $0.value == "ready" })
        XCTAssertTrue(abilityNames.facts.contains { $0.label == "Decoded Strings" && (Int($0.value) ?? 0) > 0 })
        XCTAssertTrue(abilityNames.facts.contains { $0.label == "Text Samples" && $0.value.contains("Stench") })
        XCTAssertTrue(abilityNames.facts.contains { $0.label == "Text Preview Blocked Actions" && $0.value.contains("Text-bank writer") })

        let messageNARC = try XCTUnwrap(sourceCatalog.rows.first { $0.path == "res/prebuilt/msgdata/msg.narc" })
        XCTAssertTrue(messageNARC.facts.contains { $0.label == "Migration Status" && $0.value == "previewOnly" })
        XCTAssertTrue(messageNARC.facts.contains { $0.label == "Source Candidates" && !$0.value.contains("res/prebuilt/res/prebuilt") })
        XCTAssertTrue(messageNARC.facts.contains { $0.label == "Extracted Candidates" && $0.value.contains("res/prebuilt/msgdata/msg") })
        XCTAssertTrue(messageNARC.facts.contains { $0.label == "Migration Blocked Actions" && $0.value.contains("NARC repack") })

        store.openProject(path: romPath)
        store.selectWorkbenchModule(.resources)
        store.loadSelectedAssetCatalogIfNeeded(force: true)
        let romCatalog = try await waitForSelectedAssetCatalog(store)
        let romMigrationRow = try XCTUnwrap(romCatalog.rows.first { row in
            row.facts.contains { $0.label == "Migration Status" && $0.value == "previewOnly" }
        })
        XCTAssertTrue(romMigrationRow.tags.contains("ndsROM"))
        XCTAssertTrue(romMigrationRow.facts.contains { $0.label == "Source Candidates" && !$0.value.isEmpty })
        XCTAssertTrue(romMigrationRow.facts.contains { $0.label == "Extracted Candidates" && !$0.value.isEmpty })
        XCTAssertTrue(romMigrationRow.facts.contains { $0.label == "Migration Blocked Actions" && $0.value.contains("ROM export") })
    }

    @MainActor
    func testExplicitGameCubeResourcePathLoadsReadOnlyEntryAndFiltersNestedItems() throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let image = temp.url.appendingPathComponent("Pokemon Colosseum.iso")
        try writeSyntheticGameCubeDisc(to: image)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.refreshResourceLibrary()
        XCTAssertFalse(store.filteredResourceLibraryEntries.contains { $0.platform == "gameCube" })

        store.selectedGameCubeResourcePath = image.path
        store.loadSelectedGameCubeResourcePath()

        let entry = try XCTUnwrap(store.explicitGameCubeResourceEntry)
        XCTAssertEqual(entry.platform, "gameCube")
        XCTAssertEqual(entry.family, "colosseum")
        XCTAssertEqual(entry.writePolicy, "readOnly")
        XCTAssertEqual(store.gameCubeResourceLoadStatus, .loaded(itemCount: entry.items.count))
        XCTAssertTrue(entry.items.contains { $0.path == "files/common.fsys" && $0.kind == "archive" })
        XCTAssertTrue(entry.items.contains { $0.path.contains("common_rel.fdat") && $0.kind == "pokemonTable" })
        XCTAssertTrue(entry.items.contains { $0.path.contains("msg_shop.bin") && $0.kind == "text" })
        XCTAssertEqual(store.selectedResourceLibraryMode, .entries)
        XCTAssertEqual(store.selectedResourceLibraryEntryID, entry.id)

        func filteredGameCubeEntryIDs() -> [String] {
            store.filteredResourceLibraryEntries
                .filter { $0.platform == "gameCube" }
                .map(\.id)
        }

        store.searchText = "0x2080"
        XCTAssertEqual(filteredGameCubeEntryIDs(), [entry.id])

        store.searchText = "pokemonTable"
        XCTAssertEqual(filteredGameCubeEntryIDs(), [entry.id])

        store.searchText = "msg_shop"
        XCTAssertEqual(filteredGameCubeEntryIDs(), [entry.id])
    }

    @MainActor
    func testOpeningGameCubeProjectIndexesExplicitResourceWithoutAutoLoadingGameCubeMedia() throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let image = temp.url.appendingPathComponent("Pokemon Colosseum.gcm")
        try writeSyntheticGameCubeDisc(to: image)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: image.path)

        let project = try XCTUnwrap(store.selectedIndexedProject)
        let entry = try XCTUnwrap(store.explicitGameCubeResourceEntry)
        XCTAssertEqual(project.profile, "pokemonColosseum")
        XCTAssertEqual(project.writePolicy, "readOnly")
        XCTAssertEqual(entry.path, image.path)
        XCTAssertEqual(entry.writePolicy, "readOnly")
        XCTAssertTrue(entry.items.contains { $0.path == "files/common.fsys" })
    }

    @MainActor
    func testResourceAssetNavigationResolvesLayoutAndReportTargets() async throws {
        let root = try makeVisualProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedAssetCatalogIfNeeded()

        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let layoutAsset = try XCTUnwrap(assetCatalog.rows.first { $0.category == "layouts" && $0.targetID == "LAYOUT_ROUTE2" })

        store.navigateToAsset(layoutAsset)

        _ = try await waitForSelectedMapCatalog(store)
        XCTAssertEqual(store.selection, .maps)
        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE2")
        XCTAssertEqual(store.searchText, "LAYOUT_ROUTE2")
        XCTAssertEqual(store.selectedResourceAssetID, layoutAsset.id)

        let graphicsAsset = try XCTUnwrap(assetCatalog.rows.first { $0.targetModule == .graphics && $0.targetID != nil })
        store.navigateToAsset(graphicsAsset)

        XCTAssertEqual(store.selection, .graphics)
        XCTAssertEqual(store.searchText, graphicsAsset.targetID)

        let buildAsset = try XCTUnwrap(assetCatalog.rows.first { $0.targetModule == .build && $0.targetID != nil })
        store.navigateToAsset(buildAsset)

        XCTAssertEqual(store.selection, .build)
        XCTAssertEqual(store.searchText, buildAsset.targetID)
    }

    @MainActor
    func testResourceAssetNavigationFocusesScriptsPokemonAndBacklinks() async throws {
        let root = try makeSourceIndexProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedAssetCatalogIfNeeded()

        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let scriptSourceAsset = try XCTUnwrap(assetCatalog.rows.first { $0.category == "scripts" && $0.targetID == "data/scripts/test.inc" })

        store.navigateToAsset(scriptSourceAsset)
        try await waitForSelectedSourceGraph(store)

        XCTAssertEqual(store.selection, .scripts)
        XCTAssertEqual(store.searchText, "data/scripts/test.inc")
        XCTAssertEqual(store.scriptReadinessTargetMode, .script)
        XCTAssertEqual(store.selectedScriptReadinessLabel, "Test_EventScript")
        XCTAssertEqual(store.selectedResourceAssetID, scriptSourceAsset.id)

        let speciesAsset = try XCTUnwrap(assetCatalog.rows.first { $0.category == "species" && $0.targetID == "SPECIES_TREECKO" })
        store.navigateToAsset(speciesAsset)
        try await waitForSelectedSpeciesCatalog(store)

        XCTAssertEqual(store.selection, .pokemon)
        XCTAssertEqual(store.selectedSpeciesID, "SPECIES_TREECKO")
        XCTAssertEqual(store.searchText, "SPECIES_TREECKO")

        store.navigateToResourceAsset(path: "data/scripts/test.inc")

        XCTAssertEqual(store.selection, .resources)
        XCTAssertEqual(store.resourceAssetCategory, WorkbenchStore.allResourceAssetCategories)
        XCTAssertEqual(store.searchText, "data/scripts/test.inc")
        XCTAssertEqual(store.selectedResourceAssetID, scriptSourceAsset.id)
    }

    @MainActor
    func testRelatedResourceWorkflowFacetKeepsRelatedRowNavigation() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)
        let relatedAsset = Self.makeAssetRow(
            id: "related-script",
            title: "Related Script",
            path: "data/scripts/test.inc",
            category: "scripts",
            facts: [
                Fact(label: "Related Rows", value: "3"),
                Fact(label: "Related Domains", value: "maps, text"),
            ],
            targetModule: .graphics,
            targetID: "graphics/tilesets/primary/test"
        )
        let unrelatedAsset = Self.makeAssetRow(
            id: "unrelated-script",
            title: "Unrelated Script",
            path: "data/scripts/other.inc",
            category: "scripts",
            targetModule: .graphics,
            targetID: "graphics/tilesets/primary/other"
        )

        let filtered = WorkbenchStore.filterAndSort(
            assetRows: [unrelatedAsset, relatedAsset],
            category: WorkbenchStore.allResourceAssetCategories,
            searchText: "",
            sortMode: .title,
            workflowFacet: .related
        )

        XCTAssertEqual(filtered.map(\.id), [relatedAsset.id])

        store.navigateToAsset(relatedAsset)

        XCTAssertEqual(store.selection, .graphics)
        XCTAssertEqual(store.selectedResourceAssetID, relatedAsset.id)
        XCTAssertEqual(store.searchText, "graphics/tilesets/primary/test")
    }

    @MainActor
    func testGuidedFlowsRouteToModulesAndPreserveResourceBacklinks() async throws {
        let root = try makeSourceIndexProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)

        XCTAssertEqual(
            store.guidedFlows.map(\.id),
            ["maps-events", "pokemon-data", "trainer-battles", "resources-assets", "ship-preview", "diagnostics-triage"]
        )

        let mapFlow = try XCTUnwrap(store.guidedFlows.first { $0.id == "maps-events" })
        XCTAssertEqual(mapFlow.primaryAction.flowID, "maps-events")
        let mapAssetAction = try XCTUnwrap(mapFlow.secondaryActions.first)
        XCTAssertEqual(mapAssetAction.flowID, "maps-events")
        store.route(to: mapAssetAction)

        XCTAssertEqual(store.selectedGuidedFlowID, "maps-events")
        XCTAssertEqual(store.selection, .resources)
        XCTAssertEqual(store.resourceAssetCategory, "layouts")
        XCTAssertEqual(store.searchText, "layout")

        let pokemonFlow = try XCTUnwrap(store.guidedFlows.first { $0.id == "pokemon-data" })
        XCTAssertEqual(pokemonFlow.primaryAction.flowID, "pokemon-data")
        store.route(to: pokemonFlow.primaryAction)
        store.loadSelectedSpeciesCatalogIfNeeded()
        try await waitForSelectedSpeciesCatalog(store)

        XCTAssertEqual(store.selectedGuidedFlowID, "pokemon-data")
        XCTAssertEqual(store.selection, .pokemon)
        XCTAssertEqual(store.selectedSpeciesID, "SPECIES_TREECKO")

        let pokemonAssetAction = try XCTUnwrap(pokemonFlow.secondaryActions.first)
        XCTAssertEqual(pokemonAssetAction.flowID, "pokemon-data")
        store.route(to: pokemonAssetAction)

        XCTAssertEqual(store.selectedGuidedFlowID, "pokemon-data")
        XCTAssertEqual(store.selection, .resources)
        XCTAssertEqual(store.searchText, "pokemon")
        XCTAssertEqual(store.resourceAssetCategory, "graphics")

        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let speciesAsset = try XCTUnwrap(assetCatalog.rows.first { $0.category == "species" && $0.targetID == "SPECIES_TREECKO" })

        store.navigateToAsset(speciesAsset)
        try await waitForSelectedSpeciesCatalog(store)

        XCTAssertEqual(store.selection, .pokemon)
        XCTAssertEqual(store.selectedSpeciesID, "SPECIES_TREECKO")
        XCTAssertEqual(store.selectedResourceAssetID, speciesAsset.id)
        XCTAssertEqual(store.selectedGuidedFlowID, "pokemon-data")

        let shipFlow = try XCTUnwrap(store.guidedFlows.first { $0.id == "ship-preview" })
        let patchAction = try XCTUnwrap(shipFlow.secondaryActions.first)
        store.route(to: patchAction)

        XCTAssertEqual(store.selectedGuidedFlowID, "ship-preview")
        XCTAssertEqual(store.selection, .build)
        XCTAssertEqual(store.selectedBuildWorkbenchTab, .patch)
        XCTAssertEqual(store.searchText, "")

        let diagnosticsFlow = try XCTUnwrap(store.guidedFlows.first { $0.id == "diagnostics-triage" })
        store.selectedDiagnosticBucket = .generatedArtifacts
        store.route(to: diagnosticsFlow.primaryAction)

        XCTAssertEqual(store.selectedGuidedFlowID, "diagnostics-triage")
        XCTAssertEqual(store.selection, .issues)
        XCTAssertEqual(store.selectedDiagnosticBucket, .blockingErrors)
    }

    @MainActor
    func testSingleLeftPanelDefaultsAndStoreOwnedSelections() async throws {
        let store = try await makeLoadedStore()

        XCTAssertEqual(store.selectedResourceLibraryMode, .assets)
        XCTAssertEqual(store.selectedMapWorkbenchTab, .overviewLayers)
        XCTAssertEqual(store.selectedBuildWorkbenchTab, .build)
        XCTAssertEqual(store.selectedDiagnosticBucket, .blockingErrors)
        XCTAssertTrue(store.mapShowsPalette)
        XCTAssertNil(store.mapViewportRequest)

        store.selectedMapWorkbenchTab = .eventsScripts
        store.mapShowsPalette = false
        store.mapMetatileFilter = "grass"
        store.mapViewportRequest = MapCanvasViewportRequest(centerX: 2, centerY: 3)

        XCTAssertEqual(store.selectedMapWorkbenchTab, .eventsScripts)
        XCTAssertFalse(store.mapShowsPalette)
        XCTAssertEqual(store.mapMetatileFilter, "grass")
        XCTAssertEqual(store.mapViewportRequest?.centerX, 2)
        XCTAssertEqual(store.mapViewportRequest?.centerY, 3)

        store.selectedBuildWorkbenchTab = .playtest
        let playtestRow = try XCTUnwrap(store.filteredBuildRowsForSelectedTab.first)
        store.requestBuildReportRowSelection(playtestRow.id)

        XCTAssertEqual(store.selectedBuildReportRow?.id, playtestRow.id)

        store.requestDiagnosticBucketSelection(.generatedArtifacts)
        XCTAssertEqual(store.selectedDiagnosticBucket, .generatedArtifacts)
        XCTAssertEqual(store.selectedDiagnosticRowID, store.diagnosticSummary.bucket(.generatedArtifacts).diagnostics.first?.id ?? "")
    }

    @MainActor
    func testBuildAndRunCommandsRouteToIntendedShipTabs() async throws {
        let store = try await makeLoadedStore()

        store.selectedBuildWorkbenchTab = .patch
        store.showBuildCommandTab()
        XCTAssertEqual(store.selection, .build)
        XCTAssertEqual(store.selectedBuildWorkbenchTab, .build)

        store.showRunCommandTab()
        XCTAssertEqual(store.selection, .build)
        XCTAssertEqual(store.selectedBuildWorkbenchTab, .playtest)
        XCTAssertEqual(store.selectedBuildReportRow?.section, .playtest)
    }

    @MainActor
    func testWorkbenchModuleSwitchingRestoresScopedSearchAndTracksSessionRecents() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.searchText = "dashboard"
        store.selectWorkbenchModule(.pokemon, search: .replace("treecko"))
        XCTAssertEqual(store.selection, .pokemon)
        XCTAssertEqual(store.searchText, "treecko")

        store.searchText = "grovyle"
        store.selectWorkbenchModule(.moves, search: .replace("pound"))
        XCTAssertEqual(store.selection, .moves)
        XCTAssertEqual(store.searchText, "pound")

        store.searchText = "flash"
        store.selectWorkbenchModule(.pokemon)

        XCTAssertEqual(store.searchText, "grovyle")
        XCTAssertEqual(Array(store.recentModules.prefix(2)), [.pokemon, .moves])
    }

    @MainActor
    func testWorkbenchWorkflowContextPersistsAcrossStoreInstances() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))

        let first = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)
        first.selectWorkbenchModule(.resources, search: .replace("asset-search"))
        first.selectedResourceLibraryMode = .entries
        first.requestResourceAssetSelection("asset:species-treecko")
        first.requestResourceLibraryEntrySelection("entry:pokeplatinum")
        first.selectedBuildWorkbenchTab = .playtest
        first.requestBuildReportRowSelection("playtest-row")
        first.requestDiagnosticBucketSelection(.generatedArtifacts)
        first.requestDiagnosticRowSelection("diagnostic-row")
        first.selectWorkbenchModule(.build, search: .replace("playtest-search"))

        let restored = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        XCTAssertEqual(restored.selection, .build)
        XCTAssertEqual(restored.searchText, "playtest-search")
        XCTAssertEqual(restored.selectedResourceLibraryMode, .entries)
        XCTAssertEqual(restored.selectedResourceAssetID, "asset:species-treecko")
        XCTAssertEqual(restored.selectedResourceLibraryEntryID, "entry:pokeplatinum")
        XCTAssertEqual(restored.selectedBuildWorkbenchTab, .playtest)
        XCTAssertEqual(restored.selectedBuildReportRowID, "playtest-row")
        XCTAssertEqual(restored.selectedDiagnosticBucket, .generatedArtifacts)
        XCTAssertEqual(restored.selectedDiagnosticRowID, "diagnostic-row")
        XCTAssertEqual(restored.recentModules.first, .build)
        XCTAssertTrue(restored.recentWorkbenchTargets.contains { $0.target == .resourceEntry("entry:pokeplatinum") })
    }

    @MainActor
    func testSpeciesFocusPreservesDraftsAndRecordsRecentTargets() async throws {
        let root = try makePokemonProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)
        settings.includeDefaultDebugProjects = false
        let store = WorkbenchStore(userDefaults: defaults, userSettings: settings, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.pokemon, search: .clear)
        try await waitForSelectedSpeciesCatalog(store)

        XCTAssertTrue(store.focusSpecies("SPECIES_TREECKO"))
        var draft = try XCTUnwrap(store.selectedSpeciesDraft)
        draft.baseStats.hp = 47
        store.updateSelectedSpeciesDraft(draft)

        XCTAssertTrue(store.focusSpecies("SPECIES_GROVYLE"))
        XCTAssertTrue(store.focusSpecies("SPECIES_TREECKO"))

        XCTAssertEqual(store.selection, .pokemon)
        XCTAssertEqual(store.selectedSpeciesID, "SPECIES_TREECKO")
        XCTAssertEqual(store.searchText, "SPECIES_TREECKO")
        XCTAssertEqual(store.selectedSpeciesDraft?.baseStats.hp, 47)
        XCTAssertTrue(store.isSpeciesDirty("SPECIES_TREECKO"))
        XCTAssertEqual(store.dirtySpeciesDraftCount, 1)
        XCTAssertEqual(store.recentSpeciesTargets.first?.target, .species("SPECIES_TREECKO"))
    }

    @MainActor
    func testMoveFocusKeepsDetailDraftToolbarAndInspectorOnSameHiddenMove() async throws {
        let root = try makePokemonProject()
        try writeBattleMoveTable(to: root)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)
        settings.includeDefaultDebugProjects = false
        let store = WorkbenchStore(userDefaults: defaults, userSettings: settings, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.moves, search: .replace("pound"))
        let catalog = try await waitForSelectedMoveCatalog(store)
        XCTAssertTrue(catalog.moves.contains { $0.moveID == "MOVE_ABSORB" })

        XCTAssertTrue(store.focusMove("MOVE_ABSORB"))
        var draft = try XCTUnwrap(store.selectedMoveDraft)
        draft.power = 24
        store.updateSelectedMoveDraft(draft)
        store.selectedMoveWorkbenchFilter = .tmhm

        XCTAssertEqual(store.selectedMoveID, "MOVE_ABSORB")
        XCTAssertEqual(store.selectedMoveDetail?.moveID, "MOVE_ABSORB")
        XCTAssertEqual(store.selectedCoreMoveDetail?.moveID, "MOVE_ABSORB")
        XCTAssertEqual(store.selectedMoveDraft?.moveID, "MOVE_ABSORB")
        XCTAssertEqual(store.selectedMoveDraft?.power, 24)
        XCTAssertTrue(store.selectedMoveIsDirty)
        XCTAssertTrue(store.selectedMoveIsHiddenByCurrentFilter)

        XCTAssertTrue(store.focusMove("MOVE_POUND"))
        XCTAssertTrue(store.focusMove("MOVE_ABSORB"))

        XCTAssertEqual(store.selectedMoveDraft?.power, 24)
        XCTAssertTrue(store.isMoveDirty("MOVE_ABSORB"))
        XCTAssertEqual(store.dirtyMoveDraftCount, 1)
        XCTAssertEqual(store.recentMoveTargets.first?.target, .move("MOVE_ABSORB"))

        let learner = try XCTUnwrap(store.selectedMoveDetail?.learnedBy.first)
        XCTAssertTrue(store.focusSpecies(learner.speciesID))
        XCTAssertEqual(store.selection, .pokemon)
        XCTAssertEqual(store.selectedSpeciesID, "SPECIES_TREECKO")
        XCTAssertEqual(store.searchText, "SPECIES_TREECKO")
    }

    @MainActor
    func testRubySapphireMoveDraftPreviewApplyAndReloadsThroughStore() async throws {
        let root = try makeRubyPokemonProject()
        try writeRubyBattleMoveTable(to: root)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)
        settings.includeDefaultDebugProjects = false
        let store = WorkbenchStore(userDefaults: defaults, userSettings: settings, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.moves, search: .replace("pound"))
        let catalog = try await waitForSelectedMoveCatalog(store)
        XCTAssertEqual(catalog.profile, "pokeruby")
        XCTAssertTrue(store.focusMove("MOVE_POUND"))
        XCTAssertEqual(store.selectedMoveDetail?.source.path, "src/data/battle_moves.c")

        var draft = try XCTUnwrap(store.selectedMoveDraft)
        draft.power = 55
        draft.pp = 30
        draft.flags = ["FLAG_MAGIC_COAT_AFFECTED", "FLAG_PROTECT_AFFECTED"]
        draft.descriptionText = "A sharper pound."
        store.updateSelectedMoveDraft(draft)

        XCTAssertTrue(store.selectedMoveIsDirty)
        XCTAssertTrue(store.canPreviewSelectedMoveMutationPlan)
        store.previewSelectedMoveMutationPlan()

        let plan = try XCTUnwrap(store.latestMoveEditPlan)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/battle_moves.c"])
        XCTAssertTrue(store.canApplySelectedMoveMutationPlan)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".power = 55") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains("A sharper pound.") == true)

        store.applySelectedMoveMutationPlan()

        XCTAssertEqual(store.latestMoveApplyResult?.appliedChanges.map(\.path), ["src/data/battle_moves.c"])
        XCTAssertFalse(store.selectedMoveIsDirty)
        XCTAssertEqual(store.selectedMoveID, "MOVE_POUND")
        let editedDraft = try XCTUnwrap(store.selectedMoveDraft)
        XCTAssertEqual(editedDraft.power, 55)
        XCTAssertEqual(editedDraft.pp, 30)
        XCTAssertEqual(editedDraft.flags, ["FLAG_MAGIC_COAT_AFFECTED", "FLAG_PROTECT_AFFECTED"])
        XCTAssertEqual(editedDraft.descriptionText, "A sharper pound.")
    }

    @MainActor
    func testRubySapphireContestMoveScalarsAndComboMovesDraftPreviewApplyAndReloadsThroughStore() async throws {
        let root = try makeRubyPokemonProject()
        try writeRubyBattleMoveTable(to: root)
        try writeRubyContestMoveTable(to: root)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)
        settings.includeDefaultDebugProjects = false
        let store = WorkbenchStore(userDefaults: defaults, userSettings: settings, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.moves, search: .replace("pound"))
        let catalog = try await waitForSelectedMoveCatalog(store)
        XCTAssertEqual(catalog.profile, "pokeruby")
        XCTAssertTrue(store.focusMove("MOVE_POUND"))
        XCTAssertEqual(store.selectedMoveDetail?.source.path, "src/data/battle_moves.c")

        var draft = try XCTUnwrap(store.selectedMoveDraft)
        XCTAssertEqual(draft.contestEffect, "CONTEST_EFFECT_NONE")
        XCTAssertEqual(draft.contestMoveEffect, "CONTEST_EFFECT_HIGHLY_APPEALING")
        XCTAssertEqual(draft.contestCategory, "CONTEST_CATEGORY_TOUGH")
        XCTAssertEqual(draft.contestComboStarterId, "COMBO_STARTER_POUND")
        XCTAssertEqual(draft.contestComboMoves, ["COMBO_STARTER_GROWL"])
        draft.contestMoveEffect = "CONTEST_EFFECT_STARTLE_PREVENTION"
        draft.contestCategory = "CONTEST_CATEGORY_COOL"
        draft.contestComboStarterId = "COMBO_STARTER_NONE"
        draft.contestComboMoves = ["COMBO_STARTER_POUND", "COMBO_STARTER_GROWL"]
        store.updateSelectedMoveDraft(draft)

        XCTAssertTrue(store.selectedMoveIsDirty)
        XCTAssertTrue(store.canPreviewSelectedMoveMutationPlan)
        store.previewSelectedMoveMutationPlan()

        let plan = try XCTUnwrap(store.latestMoveEditPlan)
        XCTAssertTrue(plan.isApplyable, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/contest_moves.h"])
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".effect = CONTEST_EFFECT_STARTLE_PREVENTION") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".contestCategory = CONTEST_CATEGORY_COOL") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".comboStarterId = COMBO_STARTER_NONE") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".comboMoves = { COMBO_STARTER_POUND, COMBO_STARTER_GROWL }") == true)
        XCTAssertTrue(store.canApplySelectedMoveMutationPlan)

        store.applySelectedMoveMutationPlan()

        XCTAssertEqual(store.latestMoveApplyResult?.appliedChanges.map(\.path), ["src/data/contest_moves.h"])
        XCTAssertFalse(store.selectedMoveIsDirty)
        XCTAssertEqual(store.selectedMoveID, "MOVE_POUND")
        let editedDraft = try XCTUnwrap(store.selectedMoveDraft)
        XCTAssertEqual(editedDraft.contestEffect, "CONTEST_EFFECT_NONE")
        XCTAssertEqual(editedDraft.contestMoveEffect, "CONTEST_EFFECT_STARTLE_PREVENTION")
        XCTAssertEqual(editedDraft.contestCategory, "CONTEST_CATEGORY_COOL")
        XCTAssertEqual(editedDraft.contestComboStarterId, "COMBO_STARTER_NONE")
        XCTAssertEqual(editedDraft.contestComboMoves, ["COMBO_STARTER_POUND", "COMBO_STARTER_GROWL"])
    }

    @MainActor
    func testExpansionMoveContestComboMovesDraftPreviewApplyAndReloadsThroughMovesEditor() async throws {
        let root = try makeExpansionPokemonProject()
        try writeExpansionMoveInfoTable(to: root)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.moves, search: .replace("pound"))
        let catalog = try await waitForSelectedMoveCatalog(store)
        XCTAssertEqual(catalog.profile, "pokeemeraldExpansion")
        XCTAssertTrue(store.focusMove("MOVE_POUND"))
        XCTAssertEqual(store.selectedMoveDetail?.source.path, "src/data/moves_info.h")

        var draft = try XCTUnwrap(store.selectedMoveDraft)
        XCTAssertEqual(draft.contestComboMoves, ["MOVE_ABSORB", "MOVE_MEGA_PUNCH"])
        draft.contestComboMoves = ["MOVE_MEGA_PUNCH", "MOVE_POUND", "MOVE_ABSORB"]
        store.updateSelectedMoveDraft(draft)

        XCTAssertTrue(store.selectedMoveIsDirty)
        XCTAssertTrue(store.canPreviewSelectedMoveMutationPlan)
        store.previewSelectedMoveMutationPlan()

        let plan = try XCTUnwrap(store.latestMoveEditPlan)
        XCTAssertTrue(plan.isApplyable, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/moves_info.h"])
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".contestComboMoves = { MOVE_MEGA_PUNCH, MOVE_POUND, MOVE_ABSORB }") == true)
        XCTAssertTrue(store.canApplySelectedMoveMutationPlan)

        store.applySelectedMoveMutationPlan()

        XCTAssertEqual(store.latestMoveApplyResult?.appliedChanges.map(\.path), ["src/data/moves_info.h"])
        XCTAssertFalse(store.selectedMoveIsDirty)
        XCTAssertEqual(store.selectedMoveID, "MOVE_POUND")
        let editedDraft = try XCTUnwrap(store.selectedMoveDraft)
        XCTAssertEqual(editedDraft.contestComboMoves, ["MOVE_MEGA_PUNCH", "MOVE_POUND", "MOVE_ABSORB"])
    }

    @MainActor
    func testExpansionMoveMissingFlagsDraftPreviewApplyAndReloadsThroughMovesEditor() async throws {
        let root = try makeExpansionPokemonProject()
        try writeExpansionMoveInfoTable(to: root)
        let movesInfoURL = root.appendingPathComponent("src/data/moves_info.h")
        var movesInfo = try String(contentsOf: movesInfoURL, encoding: .utf8)
        let movesInfoWithFlags = movesInfo
        movesInfo = movesInfo
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.contains(".flags = FLAG_MAKES_CONTACT,") }
            .joined(separator: "\n")
        XCTAssertNotEqual(movesInfo, movesInfoWithFlags)
        XCTAssertFalse(movesInfo.contains(".flags = FLAG_MAKES_CONTACT,"))
        try movesInfo.write(to: movesInfoURL, atomically: true, encoding: .utf8)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.moves, search: .replace("pound"))
        let catalog = try await waitForSelectedMoveCatalog(store)
        XCTAssertEqual(catalog.profile, "pokeemeraldExpansion")
        XCTAssertTrue(store.focusMove("MOVE_POUND"))
        XCTAssertEqual(store.selectedMoveDetail?.source.path, "src/data/moves_info.h")

        var draft = try XCTUnwrap(store.selectedMoveDraft)
        XCTAssertEqual(draft.flags, [])
        draft.flags = ["FLAG_PROTECT_AFFECTED", "FLAG_MAKES_CONTACT"]
        store.updateSelectedMoveDraft(draft)

        XCTAssertTrue(store.selectedMoveIsDirty)
        XCTAssertTrue(store.canPreviewSelectedMoveMutationPlan)
        store.previewSelectedMoveMutationPlan()

        let plan = try XCTUnwrap(store.latestMoveEditPlan)
        XCTAssertTrue(plan.isApplyable, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/moves_info.h"])
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".flags = FLAG_MAKES_CONTACT | FLAG_PROTECT_AFFECTED") == true)
        XCTAssertTrue(store.canApplySelectedMoveMutationPlan)

        store.applySelectedMoveMutationPlan()

        XCTAssertEqual(store.latestMoveApplyResult?.appliedChanges.map(\.path), ["src/data/moves_info.h"])
        XCTAssertFalse(store.selectedMoveIsDirty)
        XCTAssertEqual(store.selectedMoveID, "MOVE_POUND")
        let editedDraft = try XCTUnwrap(store.selectedMoveDraft)
        XCTAssertEqual(editedDraft.flags, ["FLAG_MAKES_CONTACT", "FLAG_PROTECT_AFFECTED"])
    }

    @MainActor
    func testExpansionItemBagClassificationEditsFlowThroughItemsEditor() async throws {
        let root = try makeExpansionPokemonProject()
        try writeExpansionItemInfoTable(to: root)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.items, search: .replace("potion"))
        let catalog = try await waitForSelectedItemCatalog(store)
        XCTAssertEqual(catalog.profile, .pokeemeraldExpansion)
        store.requestItemSelection("ITEM_POTION")
        XCTAssertEqual(store.selectedItemID, "ITEM_POTION")
        XCTAssertEqual(store.selectedItemDetail?.source.path, "src/data/items.h")

        var draft = try XCTUnwrap(store.selectedItemDraft)
        XCTAssertEqual(draft.importance, "0")
        XCTAssertEqual(draft.registrability, "0")
        XCTAssertEqual(draft.sortType, "ITEM_TYPE_HEALTH_RECOVERY")
        XCTAssertEqual(draft.exitsBagOnUse, "FALSE")
        draft.importance = "1"
        draft.registrability = "ITEM_REGISTER_ALLOWED"
        draft.sortType = "ITEM_TYPE_FIELD_USE"
        draft.exitsBagOnUse = "TRUE"
        store.updateSelectedItemDraft(draft)

        XCTAssertTrue(store.selectedItemIsDirty)
        XCTAssertTrue(store.canPreviewSelectedItemMutationPlan)
        store.previewSelectedItemMutationPlan()

        let plan = try XCTUnwrap(store.latestItemEditPlan)
        XCTAssertTrue(plan.isApplyable, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/items.h"])
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".importance = 1,") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".registrability = ITEM_REGISTER_ALLOWED,") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".sortType = ITEM_TYPE_FIELD_USE,") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".exitsBagOnUse = TRUE,") == true)
        XCTAssertTrue(store.canApplySelectedItemMutationPlan)

        store.applySelectedItemMutationPlan()

        XCTAssertEqual(store.latestItemApplyResult?.appliedChanges.map(\.path), ["src/data/items.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.latestItemApplyResult?.backupRootPath ?? ""))
        XCTAssertFalse(store.selectedItemIsDirty)
        XCTAssertEqual(store.selectedItemID, "ITEM_POTION")
        let editedDraft = try XCTUnwrap(store.selectedItemDraft)
        XCTAssertEqual(editedDraft.importance, "1")
        XCTAssertEqual(editedDraft.registrability, "ITEM_REGISTER_ALLOWED")
        XCTAssertEqual(editedDraft.sortType, "ITEM_TYPE_FIELD_USE")
        XCTAssertEqual(editedDraft.exitsBagOnUse, "TRUE")
    }

    @MainActor
    func testExpansionItemMissingBehaviorScalarsInsertThroughItemsEditor() async throws {
        let root = try makeExpansionPokemonProject()
        try writeExpansionItemInfoTable(to: root, includeBehaviorScalars: false)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.items, search: .replace("potion"))
        let catalog = try await waitForSelectedItemCatalog(store)
        XCTAssertEqual(catalog.profile, .pokeemeraldExpansion)
        store.requestItemSelection("ITEM_POTION")
        XCTAssertEqual(store.selectedItemID, "ITEM_POTION")

        var draft = try XCTUnwrap(store.selectedItemDraft)
        XCTAssertNil(draft.fieldUseFunc)
        XCTAssertNil(draft.battleUsage)
        XCTAssertNil(draft.battleUseFunc)
        XCTAssertNil(draft.secondaryId)
        draft.fieldUseFunc = "ItemUseOutOfBattle_EscapeRope"
        draft.battleUsage = "EFFECT_ITEM_CURE_POISON"
        draft.battleUseFunc = "ItemUseInBattle_Medicine"
        draft.secondaryId = "ITEM_ANTIDOTE"
        store.updateSelectedItemDraft(draft)

        XCTAssertTrue(store.selectedItemIsDirty)
        XCTAssertTrue(store.canPreviewSelectedItemMutationPlan)
        store.previewSelectedItemMutationPlan()

        let plan = try XCTUnwrap(store.latestItemEditPlan)
        XCTAssertTrue(plan.isApplyable, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/items.h"])
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".fieldUseFunc = ItemUseOutOfBattle_EscapeRope,") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".battleUsage = EFFECT_ITEM_CURE_POISON,") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".battleUseFunc = ItemUseInBattle_Medicine,") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".secondaryId = ITEM_ANTIDOTE,") == true)
        XCTAssertTrue(store.canApplySelectedItemMutationPlan)

        store.applySelectedItemMutationPlan()

        XCTAssertEqual(store.latestItemApplyResult?.appliedChanges.map(\.path), ["src/data/items.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.latestItemApplyResult?.backupRootPath ?? ""))
        XCTAssertFalse(store.selectedItemIsDirty)
        XCTAssertEqual(store.selectedItemID, "ITEM_POTION")
        let editedDraft = try XCTUnwrap(store.selectedItemDraft)
        XCTAssertEqual(editedDraft.fieldUseFunc, "ItemUseOutOfBattle_EscapeRope")
        XCTAssertEqual(editedDraft.battleUsage, "EFFECT_ITEM_CURE_POISON")
        XCTAssertEqual(editedDraft.battleUseFunc, "ItemUseInBattle_Medicine")
        XCTAssertEqual(editedDraft.secondaryId, "ITEM_ANTIDOTE")
    }

    @MainActor
    func testExpansionItemMissingUsageScalarsInsertThroughItemsEditor() async throws {
        let root = try makeExpansionPokemonProject()
        try writeExpansionItemInfoTable(to: root, includeUsageScalars: false)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.items, search: .replace("potion"))
        let catalog = try await waitForSelectedItemCatalog(store)
        XCTAssertEqual(catalog.profile, .pokeemeraldExpansion)
        store.requestItemSelection("ITEM_POTION")
        XCTAssertEqual(store.selectedItemID, "ITEM_POTION")

        var draft = try XCTUnwrap(store.selectedItemDraft)
        XCTAssertNil(draft.holdEffect)
        XCTAssertNil(draft.holdEffectParam)
        XCTAssertNil(draft.pocket)
        XCTAssertNil(draft.type)
        draft.holdEffect = "HOLD_EFFECT_RESTORE_HP"
        draft.holdEffectParam = "60"
        draft.pocket = "POCKET_MEDICINE"
        draft.type = "ITEM_USE_PARTY_MENU"
        store.updateSelectedItemDraft(draft)

        XCTAssertTrue(store.selectedItemIsDirty)
        XCTAssertTrue(store.canPreviewSelectedItemMutationPlan)
        store.previewSelectedItemMutationPlan()

        let plan = try XCTUnwrap(store.latestItemEditPlan)
        XCTAssertTrue(plan.isApplyable, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/items.h"])
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".holdEffect = HOLD_EFFECT_RESTORE_HP,") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".holdEffectParam = 60,") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".pocket = POCKET_MEDICINE,") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".type = ITEM_USE_PARTY_MENU,") == true)
        XCTAssertTrue(store.canApplySelectedItemMutationPlan)

        store.applySelectedItemMutationPlan()

        XCTAssertEqual(store.latestItemApplyResult?.appliedChanges.map(\.path), ["src/data/items.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.latestItemApplyResult?.backupRootPath ?? ""))
        XCTAssertFalse(store.selectedItemIsDirty)
        XCTAssertEqual(store.selectedItemID, "ITEM_POTION")
        let editedDraft = try XCTUnwrap(store.selectedItemDraft)
        XCTAssertEqual(editedDraft.holdEffect, "HOLD_EFFECT_RESTORE_HP")
        XCTAssertEqual(editedDraft.holdEffectParam, "60")
        XCTAssertEqual(editedDraft.pocket, "POCKET_MEDICINE")
        XCTAssertEqual(editedDraft.type, "ITEM_USE_PARTY_MENU")
    }

    @MainActor
    func testRubySapphireTrainerDraftPreviewApplyAndReloadsThroughStore() async throws {
        let root = try makeRubyPokemonProject()
        try writeRubyTrainerSources(to: root)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)
        settings.includeDefaultDebugProjects = false
        let store = WorkbenchStore(userDefaults: defaults, userSettings: settings, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectWorkbenchModule(.trainers, search: .replace("ruby"))
        let catalog = try await waitForSelectedTrainerCatalog(store)
        XCTAssertEqual(catalog.profile, .pokeruby)
        store.requestTrainerSelection("TRAINER_RUBY")
        XCTAssertEqual(store.selectedTrainerID, "TRAINER_RUBY")
        XCTAssertEqual(store.selectedTrainerDetail?.sourceSpan.relativePath, "src/data/trainers_en.h")

        var draft = try XCTUnwrap(store.selectedTrainerDraft)
        draft.trainerName = "RUBY2"
        draft.trainerItems = ["ITEM_POTION", "ITEM_NONE", "ITEM_NONE", "ITEM_NONE"]
        draft.doubleBattle = true
        draft.party[0].level = 9
        draft.party[0].heldItem = "ITEM_POTION"
        draft.party[0].moves = ["MOVE_ABSORB", "MOVE_POUND", "MOVE_NONE", "MOVE_NONE"]
        store.updateSelectedTrainerDraft(draft)

        XCTAssertTrue(store.selectedTrainerIsDirty)
        XCTAssertTrue(store.canPreviewSelectedTrainerMutationPlan)
        store.previewSelectedTrainerMutationPlan()

        let plan = try XCTUnwrap(store.latestTrainerEditPlan)
        XCTAssertEqual(plan.changes.map(\.path).sorted(), ["src/data/trainer_parties.h", "src/data/trainers_en.h"])
        XCTAssertTrue(store.canApplySelectedTrainerMutationPlan)
        XCTAssertTrue(plan.changes.first { $0.path == "src/data/trainers_en.h" }?.textPreview?.contains(".trainerName = _(\"RUBY2\")") == true)
        XCTAssertTrue(plan.changes.first { $0.path == "src/data/trainers_en.h" }?.textPreview?.contains(".partySize = 1") == true)
        XCTAssertTrue(plan.changes.first { $0.path == "src/data/trainers_en.h" }?.textPreview?.contains(".party = {.ItemCustomMoves = gTrainerParty_Ruby }") == true)
        XCTAssertTrue(plan.changes.first { $0.path == "src/data/trainer_parties.h" }?.textPreview?.contains(".level = 9") == true)

        store.applySelectedTrainerMutationPlan()

        XCTAssertEqual(store.latestTrainerApplyResult?.appliedChanges.map(\.path).sorted(), ["src/data/trainer_parties.h", "src/data/trainers_en.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.latestTrainerApplyResult?.backupRootPath ?? ""))
        XCTAssertFalse(store.selectedTrainerIsDirty)
        XCTAssertEqual(store.selectedTrainerID, "TRAINER_RUBY")
        let editedDraft = try XCTUnwrap(store.selectedTrainerDraft)
        XCTAssertEqual(editedDraft.trainerName, "RUBY2")
        XCTAssertEqual(editedDraft.trainerItems, ["ITEM_POTION", "ITEM_NONE", "ITEM_NONE", "ITEM_NONE"])
        XCTAssertTrue(editedDraft.doubleBattle)
        XCTAssertEqual(editedDraft.party.first?.level, 9)
        XCTAssertEqual(editedDraft.party.first?.heldItem, "ITEM_POTION")
        XCTAssertEqual(editedDraft.party.first?.moves, ["MOVE_ABSORB", "MOVE_POUND", "MOVE_NONE", "MOVE_NONE"])
    }

    @MainActor
    func testSidebarSearchFallbacksAndGenericRecordSelection() async throws {
        let root = try makeSourceIndexProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedSourceGraphIfNeeded()
        try await waitForSelectedSourceGraph(store)

        let itemRows = store.records(for: .items)
        let item = try XCTUnwrap(itemRows.first { $0.title == "ITEM_POTION" })
        store.requestRecordSelection(item.id, module: .items)

        XCTAssertEqual(store.selectedRecord(for: .items)?.title, "ITEM_POTION")

        store.searchText = "no matching item"

        XCTAssertTrue(store.records(for: .items).isEmpty)
        XCTAssertNil(store.selectedRecord(for: .items))

        store.searchText = "Potion"

        XCTAssertEqual(store.selectedRecord(for: .items)?.title, "ITEM_POTION")
    }

    @MainActor
    func testDashboardMapMetricUsesSourceIndexBeforeFullCatalogLoads() async throws {
        let root = try makeSourceIndexProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedSourceGraphIfNeeded()
        try await waitForSelectedSourceGraph(store)

        XCTAssertEqual(store.records(for: .maps).count, 1)
        XCTAssertEqual(store.dashboardMapMetric.value, "1")
        XCTAssertNotEqual(store.dashboardMapMetric.detail, "Loading map catalog")
    }

    @MainActor
    func testProjectOpenDefersScriptReadinessUntilScriptsSurfaceRequestsIt() throws {
        let root = try makeSourceIndexProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)

        XCTAssertNil(store.selectedScriptReadinessReport)

        store.selection = .scripts
        store.refreshSelectedScriptReadinessReport()

        let report = try XCTUnwrap(store.selectedScriptReadinessReport)
        XCTAssertFalse(report.rows.isEmpty)
    }

    @MainActor
    func testProjectOpenDefersHeavyCatalogsUntilRequested() async throws {
        let root = try makeSourceIndexProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)

        XCTAssertNotNil(store.selectedIndexedProject)
        XCTAssertNotNil(store.selectedBuildReport)
        XCTAssertNotNil(store.selectedGraphicsReport)
        XCTAssertNil(store.selectedSourceIndex)
        XCTAssertNil(store.selectedScriptOutline)
        XCTAssertNil(store.selectedSpeciesCatalog)
        XCTAssertNil(store.selectedTrainerCatalog)
        XCTAssertNil(store.selectedMoveCatalog)
        XCTAssertNil(store.selectedItemCatalog)
        XCTAssertNil(store.selectedAssetCatalog)
        XCTAssertEqual(store.sourceGraphLoadStatus, .idle)
        XCTAssertEqual(store.speciesCatalogLoadStatus, .idle)
        XCTAssertEqual(store.trainerCatalogLoadStatus, .idle)
        XCTAssertEqual(store.moveCatalogLoadStatus, .idle)
        XCTAssertEqual(store.itemCatalogLoadStatus, .idle)
        XCTAssertEqual(store.assetCatalogLoadStatus, .idle)

        store.loadSelectedSourceGraphIfNeeded()
        try await waitForSelectedSourceGraph(store)
        XCTAssertNotNil(store.selectedScriptOutline)

        store.loadSelectedSpeciesCatalogIfNeeded()
        try await waitForSelectedSpeciesCatalog(store)

        store.loadSelectedTrainerCatalogIfNeeded()
        try await waitForSelectedTrainerCatalog(store)

        store.loadSelectedMoveCatalogIfNeeded()
        try await waitForSelectedMoveCatalog(store)

        store.loadSelectedItemCatalogIfNeeded()
        try await waitForSelectedItemCatalog(store)
    }

    @MainActor
    func testStaleSourceGraphLoadDoesNotOverwriteNewlySelectedProject() async throws {
        let firstRoot = try makeSourceIndexProject()
        let secondRoot = try makeTrainerProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: firstRoot.path)
        store.loadSelectedSourceGraphIfNeeded()
        store.openProject(path: secondRoot.path)

        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(store.selectedIndexedProject?.rootPath, secondRoot.path)
        XCTAssertNotEqual(store.selectedSourceIndex?.root.path, firstRoot.path)
    }

    @MainActor
    func testActivePokemonCatalogReloadsAfterProjectChangeWithoutViewReappearing() async throws {
        let firstRoot = try makeSourceIndexProject()
        let secondRoot = try makeSourceIndexProject()
        try write(
            """
            const struct SpeciesInfo gSpeciesInfo[] =
            {
                [SPECIES_TORCHIC] = { .baseHP = 45 },
            };
            """,
            to: secondRoot.appendingPathComponent("src/data/pokemon/species_info.h")
        )
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: firstRoot.path)
        let firstProjectID = try XCTUnwrap(store.selectedIndexedProject?.id)
        store.selection = .pokemon
        store.loadSelectedModuleDataIfNeeded()
        try await waitForSelectedSpeciesCatalog(store)
        XCTAssertEqual(store.selectedSpeciesID, "SPECIES_TREECKO")

        store.openProject(path: secondRoot.path)
        try await waitForSelectedSpeciesCatalog(store)
        XCTAssertEqual(store.selectedIndexedProject?.rootPath, secondRoot.path)
        XCTAssertEqual(store.selectedSpeciesID, "SPECIES_TORCHIC")

        store.requestProjectSelection(firstProjectID)
        try await waitForSelectedSpeciesCatalog(store)
        XCTAssertEqual(store.selectedIndexedProject?.rootPath, firstRoot.path)
        XCTAssertEqual(store.selectedSpeciesID, "SPECIES_TREECKO")
    }

    @MainActor
    func testActiveScriptsSourceGraphReloadsAfterProjectChangeWithoutViewReappearing() async throws {
        let firstRoot = try makeSourceIndexProject()
        let secondRoot = try makeSourceIndexProject()
        try write(
            """
            Other_EventScript::
                lock
                msgbox gText_Test
                release
                end
            """,
            to: secondRoot.appendingPathComponent("data/scripts/test.inc")
        )
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: firstRoot.path)
        store.selection = .scripts
        store.requestScriptReadinessMode(.script)
        store.loadSelectedModuleDataIfNeeded()
        try await waitForSelectedSourceGraph(store)
        XCTAssertTrue(store.selectedScriptOutline?.labels.contains { $0.label == "Test_EventScript" } == true)

        store.openProject(path: secondRoot.path)
        try await waitForSelectedSourceGraph(store)

        XCTAssertEqual(store.selectedIndexedProject?.rootPath, secondRoot.path)
        XCTAssertTrue(store.selectedScriptOutline?.labels.contains { $0.label == "Other_EventScript" } == true)
        XCTAssertFalse(store.selectedScriptOutline?.labels.contains { $0.label == "Test_EventScript" } == true)
        XCTAssertEqual(store.selectedScriptReadinessLabel, "Other_EventScript")
    }

    func testDiagnosticSummaryGroupsFindingsByTriageIntent() {
        let rows = [
            IndexedDiagnosticRow(
                id: "blocking",
                title: "MAP_PARSE_FAILED",
                message: "Map JSON could not be parsed.",
                severity: .error,
                source: SourceLocation(path: "data/maps/Test/map.json", symbol: "MAP_TEST", line: 1)
            ),
            IndexedDiagnosticRow(
                id: "source",
                title: "SPECIES_FIELD_UNKNOWN",
                message: "A species field needs review.",
                severity: .warning,
                source: SourceLocation(path: "src/data/pokemon/species_info.h", symbol: "SPECIES_TEST", line: 10)
            ),
            IndexedDiagnosticRow(
                id: "health",
                title: "TOOLCHAIN_TOOL_MISSING",
                message: "make is not available.",
                severity: .warning,
                source: SourceLocation(path: "Makefile", symbol: "make", line: 1)
            ),
            IndexedDiagnosticRow(
                id: "generated",
                title: "BUILD_OUTPUT_MISSING",
                message: "pokeemerald.gba was not found.",
                severity: .warning,
                source: SourceLocation(path: "pokeemerald.gba", symbol: "build", line: 1)
            ),
            IndexedDiagnosticRow(
                id: "asset",
                title: "GRAPHICS_PALETTE_MISSING",
                message: "Palette asset is missing.",
                severity: .warning,
                source: SourceLocation(path: "graphics/pokemon/test/palette.pal", symbol: "palette", line: 1)
            ),
        ]

        let summary = DiagnosticSummary(diagnostics: rows)

        XCTAssertEqual(summary.totalCount, 5)
        XCTAssertEqual(summary.blockingErrorCount, 1)
        XCTAssertEqual(summary.sourceWarningCount, 1)
        XCTAssertEqual(summary.healthCount, 1)
        XCTAssertEqual(summary.generatedArtifactCount, 1)
        XCTAssertEqual(summary.optionalAssetCount, 1)
        XCTAssertEqual(summary.status, .error)
        XCTAssertTrue(summary.detail.contains("1 optional asset"))

        let pluralSummary = DiagnosticSummary(diagnostics: rows + [
            IndexedDiagnosticRow(
                id: "asset-2",
                title: "GRAPHICS_SPRITE_MISSING",
                message: "Sprite asset is missing.",
                severity: .warning,
                source: SourceLocation(path: "graphics/pokemon/test/front.png", symbol: "front", line: 1)
            ),
        ])
        XCTAssertTrue(pluralSummary.detail.contains("2 optional assets"))
    }

    @MainActor
    func testCatalogDefaultsPreferEditableContentRows() async throws {
        let pokemonRoot = try makePokemonProject()
        let pokemonDefaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let pokemonSettings = WorkbenchUserSettings(defaults: pokemonDefaults)
        pokemonSettings.includeDefaultDebugProjects = false
        let pokemonStore = WorkbenchStore(userDefaults: pokemonDefaults, userSettings: pokemonSettings, autoLoadProjects: false)

        pokemonStore.openProject(path: pokemonRoot.path)
        pokemonStore.loadSelectedSpeciesCatalogIfNeeded()
        try await waitForSelectedSpeciesCatalog(pokemonStore)

        XCTAssertEqual(pokemonStore.selectedSpeciesID, "SPECIES_TREECKO")
        XCTAssertEqual(pokemonStore.selectedSpeciesDetail?.displayName, "Treecko")
        XCTAssertTrue(pokemonStore.selectedSpeciesDetail?.isEditable == true)

        let trainerRoot = try makeTrainerProject()
        let trainerDefaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let trainerSettings = WorkbenchUserSettings(defaults: trainerDefaults)
        trainerSettings.includeDefaultDebugProjects = false
        let trainerStore = WorkbenchStore(userDefaults: trainerDefaults, userSettings: trainerSettings, autoLoadProjects: false)

        trainerStore.openProject(path: trainerRoot.path)
        trainerStore.loadSelectedTrainerCatalogIfNeeded()
        try await waitForSelectedTrainerCatalog(trainerStore)

        XCTAssertEqual(trainerStore.selectedTrainerID, "TRAINER_TEST")
        XCTAssertTrue(trainerStore.selectedTrainerDetail?.isEditable == true)
    }

    @MainActor
    func testProjectMenuTitlesDistinguishEditableAndReferenceRoots() throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let editable = try makeFireRedProject(named: "pokefirered", under: temp.url)
        let reference = try makeFireRedProject(named: "pokefirered", under: temp.url.appendingPathComponent("references"))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: editable.path)
        store.openProject(path: reference.path)

        let editableProject = try XCTUnwrap(store.indexedProjects.first { $0.rootPath == editable.path })
        let referenceProject = try XCTUnwrap(store.indexedProjects.first { $0.rootPath == reference.path })

        XCTAssertEqual(editableProject.originLabel, "Editable")
        XCTAssertEqual(editableProject.menuTitle, "pokefirered · Editable")
        XCTAssertTrue(editableProject.menuSubtitle.contains("Editable source root"))
        XCTAssertEqual(referenceProject.originLabel, "Reference")
        XCTAssertEqual(referenceProject.menuTitle, "pokefirered · Reference")
        XCTAssertTrue(referenceProject.menuSubtitle.contains("Read-only reference source"))
        XCTAssertNotEqual(editableProject.menuTitle, referenceProject.menuTitle)
    }

    @MainActor
    func testRefreshProjectIndexesDefaultsToEditableProjectWhenMixedRootsDiscovered() throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let editable = try makeFireRedProject(named: "pokefirered", under: temp.url)
        let reference = try makeFireRedProject(named: "pokefirered", under: temp.url.appendingPathComponent("references"))
        let rom = try makeStandaloneGBAROM(named: "standalone.gba", under: temp.url)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let seedSettings = WorkbenchUserSettings(defaults: defaults)
        seedSettings.includeDefaultDebugProjects = false
        let seedStore = WorkbenchStore(userDefaults: defaults, userSettings: seedSettings, autoLoadProjects: false)
        seedStore.openProject(path: rom.path)
        seedStore.openProject(path: reference.path)
        seedStore.openProject(path: editable.path)

        let settings = WorkbenchUserSettings(defaults: defaults)
        settings.includeDefaultDebugProjects = false
        let store = WorkbenchStore(userDefaults: defaults, userSettings: settings, autoLoadProjects: false)

        store.refreshProjectIndexes()

        let editableProject = try XCTUnwrap(store.indexedProjects.first { $0.rootPath == editable.path })
        let referenceProject = try XCTUnwrap(store.indexedProjects.first { $0.rootPath == reference.path })
        let romProject = try XCTUnwrap(store.indexedProjects.first { $0.rootPath == rom.path })
        XCTAssertEqual(editableProject.originLabel, "Editable")
        XCTAssertEqual(referenceProject.originLabel, "Reference")
        XCTAssertEqual(romProject.originLabel, "Local Input")
        XCTAssertEqual(store.selectedIndexedProject?.originLabel, "Editable")
        XCTAssertNotEqual(store.selectedIndexedProject?.id, referenceProject.id)
        XCTAssertNotEqual(store.selectedIndexedProject?.id, romProject.id)

        store.selectedProjectID = romProject.id
        store.refreshProjectIndexes()

        XCTAssertEqual(store.selectedIndexedProject?.id, romProject.id)
        XCTAssertEqual(store.selectedIndexedProject?.originLabel, "Local Input")
    }

    @MainActor
    func testResourceAssetFilteringHandlesLargeSyntheticCatalog() {
        let rows = (0 ..< 50000).map(Self.syntheticAssetRow)
        let index = ResourceAssetCatalogIndex(rows: rows)

        let searchResult = index.filteredRows(
            category: "items",
            allCategory: WorkbenchStore.allResourceAssetCategories,
            searchText: "needle-49999",
            sortMode: .path
        )

        XCTAssertEqual(searchResult.map(\.id), ["asset-49999"])

        let mapRows = index.filteredRows(
            category: "maps",
            allCategory: WorkbenchStore.allResourceAssetCategories,
            searchText: "",
            sortMode: .availability
        )

        XCTAssertEqual(mapRows.count, 25000)
        XCTAssertTrue(mapRows.allSatisfy { $0.category == "maps" })
        XCTAssertTrue(mapRows.prefix(100).allSatisfy { $0.availability == "availableSource" })
        XCTAssertEqual(index.categoryBuckets["maps"]?.count, 25000)
        XCTAssertEqual(index.sortedRowsByMode[.path]?.count, rows.count)
        XCTAssertEqual(index.availabilityCountsByValue["availableSource"], 25000)
        XCTAssertEqual(index.availabilityProblemCount, 0)
    }

    @MainActor
    func testResourceAssetWorkflowFacetFilteringAndGrouping() {
        let hiddenRecordID = "species:arm9/src/pokemon.c"
        let hiddenAssetID = "resource:project:nds-data:\(hiddenRecordID)"
        let rows = [
            Self.makeAssetRow(
                id: "editable-source",
                title: "Editable Source",
                path: "src/data/items.h",
                category: "items"
            ),
            Self.makeAssetRow(
                id: "resource:project:nds-data:messages:files/msgdata/root",
                title: "Preview Only",
                path: "files/msgdata/root",
                category: "NDS Data resources",
                facts: [Fact(label: "Gen V Readiness", value: "previewOnly")]
            ),
            Self.makeAssetRow(
                id: "resource:project:nds-data:encounters:arm9/src/encounter.c",
                title: "Blocked Row",
                path: "arm9/src/encounter.c",
                category: "NDS Data encounters",
                status: .error,
                availability: "parserError",
                facts: [Fact(label: "Gen IV Readiness", value: "loaderOnlyBlocked")]
            ),
            Self.makeAssetRow(
                id: "resource:project:nds-data:maps:files/fielddata/mapmatrix",
                title: "Related Row",
                path: "files/fielddata/mapmatrix",
                category: "NDS Data maps",
                facts: [
                    Fact(label: "Related Rows", value: "2"),
                    Fact(label: "Related Domains", value: "maps"),
                ]
            ),
            Self.makeAssetRow(
                id: "generated-row",
                title: "Generated Row",
                path: "build/pokeplatinum.us.nds",
                category: "generated",
                role: "generated",
                availability: "availableGenerated",
                tags: ["generated"]
            ),
            Self.makeAssetRow(
                id: hiddenAssetID,
                title: "Hidden Draft",
                path: "arm9/src/pokemon.c",
                category: "NDS Data species"
            ),
        ]

        XCTAssertEqual(
            WorkbenchStore.filterAndSort(
                assetRows: rows,
                category: WorkbenchStore.allResourceAssetCategories,
                searchText: "",
                sortMode: .title,
                workflowFacet: .editableSource,
                hiddenDraftRecordIDs: [hiddenRecordID],
                ndsEditableRecordIDs: [hiddenRecordID]
            ).map(\.id),
            ["editable-source", hiddenAssetID]
        )
        XCTAssertEqual(
            WorkbenchStore.filterAndSort(
                assetRows: rows,
                category: WorkbenchStore.allResourceAssetCategories,
                searchText: "",
                sortMode: .title,
                workflowFacet: .previewOnly,
                hiddenDraftRecordIDs: [hiddenRecordID],
                ndsEditableRecordIDs: [hiddenRecordID]
            ).map(\.id),
            ["resource:project:nds-data:messages:files/msgdata/root"]
        )
        XCTAssertEqual(
            WorkbenchStore.filterAndSort(
                assetRows: rows,
                category: WorkbenchStore.allResourceAssetCategories,
                searchText: "",
                sortMode: .title,
                workflowFacet: .blocked,
                hiddenDraftRecordIDs: [hiddenRecordID],
                ndsEditableRecordIDs: [hiddenRecordID]
            ).map(\.id),
            ["resource:project:nds-data:encounters:arm9/src/encounter.c"]
        )
        XCTAssertEqual(
            WorkbenchStore.filterAndSort(
                assetRows: rows,
                category: WorkbenchStore.allResourceAssetCategories,
                searchText: "",
                sortMode: .title,
                workflowFacet: .related,
                hiddenDraftRecordIDs: [hiddenRecordID],
                ndsEditableRecordIDs: [hiddenRecordID]
            ).map(\.id),
            ["resource:project:nds-data:maps:files/fielddata/mapmatrix"]
        )
        XCTAssertEqual(
            WorkbenchStore.filterAndSort(
                assetRows: rows,
                category: WorkbenchStore.allResourceAssetCategories,
                searchText: "",
                sortMode: .title,
                workflowFacet: .generatedReference,
                hiddenDraftRecordIDs: [hiddenRecordID],
                ndsEditableRecordIDs: [hiddenRecordID]
            ).map(\.id),
            ["generated-row"]
        )
        XCTAssertEqual(
            WorkbenchStore.filterAndSort(
                assetRows: rows,
                category: WorkbenchStore.allResourceAssetCategories,
                searchText: "",
                sortMode: .title,
                workflowFacet: .hiddenDrafts,
                hiddenDraftRecordIDs: [hiddenRecordID],
                ndsEditableRecordIDs: [hiddenRecordID]
            ).map(\.id),
            [hiddenAssetID]
        )

        let groups = WorkbenchStore.workflowGroups(
            for: rows,
            hiddenDraftRecordIDs: [hiddenRecordID],
            ndsEditableRecordIDs: [hiddenRecordID]
        )
        XCTAssertEqual(groups.map(\.facet), [.hiddenDrafts, .editableSource, .previewOnly, .blocked, .related, .generatedReference])
        XCTAssertEqual(groups.first?.rows.map(\.id), [hiddenAssetID])
    }

    @MainActor
    func testAllLearnablesRegenerationReviewRowsSurfaceCopyOnlyPlan() async throws {
        let root = try makeExpansionPokemonProject(includeTutorLearnsets: true)
        let allLearnablesURL = root.appendingPathComponent("src/data/pokemon/all_learnables.json")
        let originalAllLearnablesData = try Data(contentsOf: allLearnablesURL)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selectedBuildWorkbenchTab = .patch
        store.loadSelectedAssetCatalogIfNeeded()

        let catalog = try await waitForSelectedAssetCatalog(store)
        XCTAssertEqual(catalog.profile, "pokeemeraldExpansion")
        let allLearnablesAsset = try XCTUnwrap(catalog.rows.first {
            $0.path == "src/data/pokemon/all_learnables.json"
                && factValue("Regeneration Posture", in: $0.facts) != nil
        })
        store.requestResourceAssetSelection(allLearnablesAsset.id)

        let selectedAsset = try XCTUnwrap(store.selectedResourceAsset)
        XCTAssertEqual(selectedAsset.id, allLearnablesAsset.id)
        XCTAssertEqual(factValue("Regeneration Posture", in: selectedAsset.facts), "copy/report-only; no generated JSON writes or command execution")
        XCTAssertTrue(factValue("Regeneration Report Commands", in: selectedAsset.facts)?.contains("pokemon-compatibility <project-root> --json") == true)
        XCTAssertTrue(factValue("Regeneration Guidance", in: selectedAsset.facts)?.contains("will not run regeneration") == true)

        let rows = store.filteredAllLearnablesRegenerationReviewRows
        let row = try XCTUnwrap(rows.first)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(row.title, "All Learnables Regeneration Review")
        XCTAssertEqual(row.section, .patchManifest)
        XCTAssertEqual(row.status, .warning)
        XCTAssertTrue(row.detail.contains("copy/report-only"))
        XCTAssertTrue(row.detail.contains("PokemonHackStudio will not run regeneration"))
        XCTAssertTrue(row.tags.contains("copy-report-only"))
        XCTAssertTrue(store.filteredBuildRowsForSelectedTab.contains { $0.id == row.id })

        XCTAssertEqual(row.actions.map(\.kind), [.copyPath, .copyCommand, .copyValue])
        XCTAssertEqual(row.actions.first?.copyValue, "src/data/pokemon/all_learnables.json")
        let commandsAction = try XCTUnwrap(row.actions.first { $0.id == "all-learnables-regeneration-review:copy-commands" })
        XCTAssertTrue(commandsAction.copyValue?.contains("pokemon-compatibility <project-root> --json") == true)
        XCTAssertTrue(commandsAction.copyValue?.contains("asset-index <project-root> --json") == true)
        let summaryAction = try XCTUnwrap(row.actions.first { $0.id == "all-learnables-regeneration-review:copy-summary" })
        XCTAssertTrue(summaryAction.copyValue?.contains("All Learnables Regeneration Review") == true)
        XCTAssertTrue(summaryAction.copyValue?.contains("Source buckets: levelUp, tmhm, tutor, egg") == true)
        XCTAssertFalse(row.actions.contains { $0.kind == .rerunGuidance })
        XCTAssertEqual(try Data(contentsOf: allLearnablesURL), originalAllLearnablesData)
    }

    @MainActor
    func testResourceAssetIndexExactLookupPrecedence() {
        let rows = [
            Self.makeAssetRow(
                id: "source-match",
                title: "Source",
                path: "source/path",
                sourcePath: "shared-key"
            ),
            Self.makeAssetRow(
                id: "title-match",
                title: "shared-key",
                path: "title/path"
            ),
            Self.makeAssetRow(
                id: "path-match",
                title: "Path",
                path: "shared-key"
            ),
            Self.makeAssetRow(
                id: "path-target-match",
                title: "Path Target",
                path: "shared-key",
                targetID: "shared-key"
            ),
            Self.makeAssetRow(
                id: "target-match",
                title: "Target",
                path: "target/path",
                targetID: "shared-key"
            ),
            Self.makeAssetRow(
                id: "shared-key",
                title: "ID",
                path: "id/path",
                targetID: "other-target"
            ),
            Self.makeAssetRow(
                id: "availability-warning",
                title: "Availability Warning",
                path: "warning/path",
                status: .warning,
                availability: "requiredSourceMissing",
                affectsResourceAvailability: true
            ),
        ]
        let index = ResourceAssetCatalogIndex(rows: rows)

        XCTAssertEqual(index.exactMatch(identifier: "shared-key")?.id, "shared-key")
        XCTAssertEqual(index.exactMatch(identifier: "other-target")?.id, "shared-key")
        XCTAssertEqual(index.exactMatch(identifier: "warning/path")?.id, "availability-warning")
        XCTAssertEqual(index.exactMatch(identifier: "Availability Warning")?.id, "availability-warning")
        XCTAssertEqual(index.exactMatch(identifier: "source/path")?.id, "source-match")
        XCTAssertEqual(index.availabilityCountsByValue["requiredSourceMissing"], 1)
        XCTAssertEqual(index.availabilityStatusCounts[.warning], 1)
        XCTAssertEqual(index.availabilityProblemStatusCounts[.warning], 1)
        XCTAssertEqual(index.availabilityProblemCount, 1)
    }

    @MainActor
    func testPendingResourceAssetFocusResolvesAfterLazyAssetLoad() async throws {
        let root = try makeSourceIndexProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        XCTAssertNil(store.selectedAssetCatalog)

        store.navigateToResourceAsset(path: "data/scripts/test.inc")
        XCTAssertEqual(store.selection, .resources)
        XCTAssertEqual(store.searchText, "data/scripts/test.inc")

        let catalog = try await waitForSelectedAssetCatalog(store)
        let scriptSourceAsset = try XCTUnwrap(catalog.index.exactMatch(identifier: "data/scripts/test.inc"))

        XCTAssertEqual(store.selectedResourceAssetID, scriptSourceAsset.id)
        XCTAssertEqual(store.selectedResourceAsset?.id, scriptSourceAsset.id)
    }

    @MainActor
    func testBuildReportLoadsIntoStoreAndContributesDiagnostics() throws {
        let root = try makeSourceIndexProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)

        let report = try XCTUnwrap(store.selectedBuildReport)
        XCTAssertFalse(report.buildTargets.isEmpty)
        XCTAssertFalse(report.generatedArtifacts.isEmpty)
        XCTAssertFalse(report.healthMatrix.rows.isEmpty)
        XCTAssertFalse(store.filteredBuildReportRows.isEmpty)
        XCTAssertEqual(store.moduleStatus(for: .build), .warning)
        XCTAssertTrue(store.filteredBuildReportRows.contains { $0.section == .healthMatrix })
        XCTAssertTrue(store.selectedDiagnosticRows.contains { $0.title == "BUILD_OUTPUT_MISSING" })
        XCTAssertGreaterThanOrEqual(store.issueCount, report.diagnostics.count)
    }

    @MainActor
    func testMapRenderAuditLoadsIntoBuildWorkbenchAndCopiesJSONReadOnly() throws {
        let root = try makeVisualProject()
        let missingTileImage = root.appendingPathComponent("data/tilesets/secondary/route/tiles.png")
        try FileManager.default.removeItem(at: missingTileImage)
        let trackedSourceURLs = [
            root.appendingPathComponent("data/maps/map_groups.json"),
            root.appendingPathComponent("data/maps/Route1/map.json"),
            root.appendingPathComponent("data/layouts/Route1/map.bin"),
            root.appendingPathComponent("src/data/tilesets/graphics.h"),
        ]
        let sourceSnapshots = try Dictionary(uniqueKeysWithValues: trackedSourceURLs.map { ($0.path, try Data(contentsOf: $0)) })
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        XCTAssertNil(store.selectedMapRenderAuditReport)
        XCTAssertEqual(store.mapRenderAuditLoadStatus, .idle)

        store.loadSelectedMapRenderAudit()

        let report = try XCTUnwrap(store.selectedMapRenderAuditReport)
        XCTAssertEqual(report.targetCount, 1)
        XCTAssertEqual(report.auditedTargetCount, 1)
        XCTAssertEqual(report.skippedTargetCount, 0)
        XCTAssertEqual(report.mapCount, 2)
        XCTAssertEqual(report.auditedMapCount, 2)
        XCTAssertGreaterThan(report.textureCount, 0)
        XCTAssertGreaterThan(report.warningBucketCount, 0)
        XCTAssertGreaterThan(report.warningCount, 0)
        XCTAssertGreaterThan(report.failureCount, 0)
        XCTAssertEqual(store.mapRenderAuditLoadStatus, .loaded(label: report.statusLabel, status: report.status))
        XCTAssertTrue(store.filteredMapRenderAuditRows.contains { $0.title == "Map render audit" && $0.detail.contains("texture check") })
        XCTAssertTrue(store.filteredMapRenderAuditRows.contains { $0.id.hasPrefix("map-render-audit:target:") })
        XCTAssertTrue(store.filteredMapRenderAuditRows.contains { $0.id.hasPrefix("map-render-audit:warning-bucket:") })
        XCTAssertTrue(store.filteredMapRenderAuditRows.contains { $0.id.hasPrefix("map-render-audit:failure:") })
        XCTAssertTrue(store.filteredBuildRowsForSelectedTab.contains { $0.section == .mapRenderAudit })
        XCTAssertTrue(store.selectedDiagnosticRows.contains { $0.id.hasPrefix("map-render-audit:") })

        store.copyMapRenderAuditJSONToPasteboard()
        var json = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        var data = try XCTUnwrap(json.data(using: .utf8))
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let summary = try XCTUnwrap(object["summary"] as? [String: Any])
        XCTAssertEqual(summary["mapCount"] as? Int, report.mapCount)
        XCTAssertEqual(summary["textureCount"] as? Int, report.textureCount)

        store.copyBuildPatchPlaytestReportJSONToPasteboard()
        json = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        data = try XCTUnwrap(json.data(using: .utf8))
        object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let exportedAudit = try XCTUnwrap(object["mapRenderAudit"] as? [String: Any])
        XCTAssertEqual(exportedAudit["status"] as? String, "failed")

        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("screenshots").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("exports").path))
        for (path, data) in sourceSnapshots {
            XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: path)), data)
        }

        let romTemp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(romTemp)
        let rom = romTemp.url.appendingPathComponent("standalone.gba")
        try writeBinaryMutationSyntheticGBA(to: rom)

        store.openProject(path: rom.path)
        store.loadSelectedMapRenderAudit()

        let skippedReport = try XCTUnwrap(store.selectedMapRenderAuditReport)
        XCTAssertEqual(skippedReport.targetCount, 1)
        XCTAssertEqual(skippedReport.auditedTargetCount, 0)
        XCTAssertEqual(skippedReport.skippedTargetCount, 1)
        XCTAssertTrue(skippedReport.rows.contains { $0.id.hasPrefix("map-render-audit:skipped:") })
        XCTAssertFalse(FileManager.default.fileExists(atPath: romTemp.url.appendingPathComponent(".pokemonhackstudio").path))
    }

    @MainActor
    func testBuildReportSearchFiltersTargetsAndOutputPaths() throws {
        let root = try makeSourceIndexProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        XCTAssertTrue(store.filteredBuildReportRows.contains { $0.title == "Build ROM" })

        store.searchText = "pokeemerald.gba"

        XCTAssertFalse(store.filteredBuildReportRows.isEmpty)
        XCTAssertTrue(store.filteredBuildReportRows.allSatisfy { row in
            row.title.localizedCaseInsensitiveContains("pokeemerald.gba")
                || row.subtitle.localizedCaseInsensitiveContains("pokeemerald.gba")
                || row.detail.localizedCaseInsensitiveContains("pokeemerald.gba")
                || row.source.path.localizedCaseInsensitiveContains("pokeemerald.gba")
                || row.tags.contains { $0.localizedCaseInsensitiveContains("pokeemerald.gba") }
        })
    }

    @MainActor
    func testPatchManifestPreviewLoadsBaseROMSelectionAndCopiesJSON() throws {
        let root = try makeSourceIndexProject()
        let gba = root.appendingPathComponent("pokeemerald.gba")
        let wrongGBA = root.appendingPathComponent("wrong.gba")
        let patch = root.appendingPathComponent("cleanroom.aps")
        try write("a9993e364706816aba3e25717850c26c9cd0d89d  pokeemerald.gba\n", to: root.appendingPathComponent("rom.sha1"))
        try write(Data("abc".utf8), to: gba)
        try write(Data("wrong".utf8), to: wrongGBA)
        try write(Data("APS1".utf8), to: patch)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        XCTAssertTrue(store.baseROMOptions.contains { $0.path == gba.path && $0.sourceKind == "Project" })

        store.requestPatchPath(patch.path)
        store.loadSelectedPatchManifestReport()

        let needsBaseReport = try XCTUnwrap(store.selectedPatchManifestReport)
        XCTAssertEqual(needsBaseReport.compatibilityLabel, "Compatibility unknown")
        XCTAssertFalse(needsBaseReport.rows.isEmpty)
        XCTAssertFalse(needsBaseReport.dryRunPlans.isEmpty)

        store.requestBaseROMPath("  \(gba.path)  ")

        let matchedReport = try XCTUnwrap(store.selectedPatchManifestReport)
        XCTAssertEqual(store.selectedBaseROMPath, gba.path)
        XCTAssertEqual(matchedReport.compatibilityLabel, "Base ROM matched")
        XCTAssertEqual(matchedReport.selectedBaseROM?.matchedCandidate, "rom.sha1")
        XCTAssertTrue(store.filteredPatchManifestRows.contains { $0.title == "pokeemerald.gba" })
        XCTAssertTrue(store.filteredPatchManifestRows.contains { $0.title == "Output artifact plan" && $0.detail.contains("compatible BPS or IPS patch") })
        XCTAssertTrue(store.filteredPatchManifestRows.contains { $0.title == "Checksum expectations" && $0.subtitle.contains("base sha1 a9993e36") })
        XCTAssertTrue(store.filteredPatchManifestRows.contains { $0.title == "Header policy" && $0.subtitle == "preserve-selected-base-rom-header" })
        XCTAssertTrue(store.filteredPatchManifestRows.contains { $0.title == "mGBA launch preview" && $0.subtitle == "Launch disabled" })
        let patchActions = Dictionary(uniqueKeysWithValues: store.buildWorkflowActions(includePatchActions: true).map { ($0.id, $0) })
        XCTAssertEqual(patchActions["apply-patch"]?.isEnabled, false)
        XCTAssertEqual(patchActions["apply-patch"]?.isPreviewLocked, false)
        XCTAssertTrue(patchActions["apply-patch"]?.disabledReason?.contains("compatible BPS or IPS patch") == true)

        store.requestBaseROMPath(wrongGBA.path)

        let mismatchReport = try XCTUnwrap(store.selectedPatchManifestReport)
        XCTAssertEqual(mismatchReport.compatibilityLabel, "Base ROM mismatch")
        XCTAssertTrue(mismatchReport.diagnostics.contains { $0.title == "PATCH_BASE_ROM_MISMATCH" })

        store.copyBuildPatchPlaytestReportJSONToPasteboard()

        let json = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let data = try XCTUnwrap(json.data(using: .utf8))
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(object?["patchManifest"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: patch.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: gba.path))
    }

    @MainActor
    func testPatchCreationPreviewLoadsReadonlyMetadataWithoutWritingPatchArtifacts() throws {
        let root = try makeSourceIndexProject()
        let baseROM = root.appendingPathComponent("clean-base.gba")
        let builtOutput = root.appendingPathComponent("pokeemerald.gba")
        let baseData = Data("abc".utf8)
        let builtData = Data("abcd".utf8)
        try write(baseData, to: baseROM)
        try write(builtData, to: builtOutput)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        let targetID = try XCTUnwrap(store.selectedRunnableBuildTargets.first?.id)
        store.selectedDecompBuildTargetID = targetID
        store.requestBaseROMPath("  \(baseROM.path)  ")
        store.loadSelectedPatchCreationPreview()

        XCTAssertEqual(store.patchCreationPreviewLoadStatus, .loaded(isReady: true, label: "Ready"))
        let preview = try XCTUnwrap(store.selectedPatchCreationPreviewReport)
        XCTAssertTrue(preview.isPreviewOnly)
        XCTAssertTrue(preview.isReady)
        XCTAssertEqual(preview.candidateFormat, "BPS")
        XCTAssertEqual(preview.sizeDeltaBytes, 1)
        XCTAssertEqual(preview.hashesMatch, false)
        XCTAssertEqual(preview.plannedPatchPath, ".pokemonhackstudio/patches/clean-base-to-pokeemerald.bps")
        XCTAssertEqual(preview.absolutePlannedPatchPath, root.appendingPathComponent(".pokemonhackstudio/patches/clean-base-to-pokeemerald.bps").path)
        XCTAssertTrue(preview.blockedActions.contains("BPS/IPS patch file writes"))
        XCTAssertTrue(preview.blockedActions.contains("ROM export"))
        XCTAssertTrue(store.filteredPatchCreationPreviewRows.contains { $0.title == "Patch creation preview" && $0.detail.contains("no patch files") })
        XCTAssertTrue(store.filteredPatchCreationPreviewRows.contains { $0.title == "ROM comparison" && $0.subtitle.contains("+1 bytes") })
        XCTAssertTrue(store.filteredPatchCreationPreviewRows.contains { $0.title == "Header policy" && $0.subtitle == "no-header-rewrite" })
        XCTAssertTrue(store.filteredPatchCreationPreviewRows.contains { $0.title == "Blocked actions" && $0.detail.contains("binary writes") })

        let plannedPatchURL = URL(fileURLWithPath: preview.absolutePlannedPatchPath)
        XCTAssertFalse(FileManager.default.fileExists(atPath: plannedPatchURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: plannedPatchURL.path + ".manifest.json"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/patches").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/builds").path))
        XCTAssertEqual(try Data(contentsOf: baseROM), baseData)
        XCTAssertEqual(try Data(contentsOf: builtOutput), builtData)

        store.copyBuildPatchPlaytestReportJSONToPasteboard()

        let json = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let data = try XCTUnwrap(json.data(using: .utf8))
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let rawPreview = try XCTUnwrap(object?["patchCreationPreview"] as? [String: Any])
        XCTAssertEqual(rawPreview["plannedPatchPath"] as? String, preview.plannedPatchPath)
        XCTAssertNil(object?["patchManifest"])
    }

    @MainActor
    func testPatchCreationStoreWritesBPSPatchAndManifestWithoutExportingROM() throws {
        let root = try makeSourceIndexProject()
        let baseROM = root.appendingPathComponent("clean-base.gba")
        let builtOutput = root.appendingPathComponent("pokeemerald.gba")
        let baseData = Data("abc".utf8)
        let targetData = Data("abxyz".utf8)
        try write(baseData, to: baseROM)
        try write(targetData, to: builtOutput)
        try write("a9993e364706816aba3e25717850c26c9cd0d89d  clean-base.gba\n", to: root.appendingPathComponent("rom.sha1"))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        let targetID = try XCTUnwrap(store.selectedRunnableBuildTargets.first?.id)
        store.selectedDecompBuildTargetID = targetID
        store.requestBaseROMPath(baseROM.path)
        store.loadSelectedPatchCreationPreview()

        XCTAssertTrue(store.canCreateSelectedBPSPatch)

        store.createSelectedBPSPatch()

        let result = try XCTUnwrap(store.latestPatchCreationResult)
        let report = try XCTUnwrap(store.selectedPatchCreationResultReport)
        let patchURL = root.appendingPathComponent(".pokemonhackstudio/patches/clean-base-to-pokeemerald.bps")
        let manifestURL = root.appendingPathComponent(".pokemonhackstudio/patches/clean-base-to-pokeemerald.bps.manifest.json")
        XCTAssertEqual(result.status, .created)
        XCTAssertEqual(result.patchPath, patchURL.path)
        XCTAssertEqual(result.manifestPath, manifestURL.path)
        XCTAssertEqual(result.verification?.status, .passed)
        XCTAssertEqual(result.verification?.expectedBuiltOutputSHA1, result.verification?.appliedOutputSHA1)
        XCTAssertEqual(report.status, .valid)
        XCTAssertTrue(store.filteredPatchCreationResultRows.contains { $0.title == "BPS patch creation" && $0.subtitle == "created" })
        XCTAssertTrue(store.filteredPatchCreationResultRows.contains { $0.title == "Patch verification" && $0.subtitle == "passed" })
        XCTAssertTrue(store.filteredPatchCreationResultRows.contains { $0.title == "Patch creation manifest" })
        XCTAssertEqual(try BPSPatchCodec.apply(patchData: Data(contentsOf: patchURL), baseData: baseData), targetData)
        XCTAssertTrue(FileManager.default.fileExists(atPath: manifestURL.path))
        XCTAssertNil(store.latestPatchApplyExportResult)
        XCTAssertFalse(store.canApplyExportSelectedPatch)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/patches/clean-base-to-pokeemerald.gba").path))

        store.copyBuildPatchPlaytestReportJSONToPasteboard()

        let json = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let data = try XCTUnwrap(json.data(using: .utf8))
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let rawResult = try XCTUnwrap(object?["patchCreationResult"] as? [String: Any])
        XCTAssertEqual(rawResult["status"] as? String, "created")
        let rawVerification = try XCTUnwrap(rawResult["verification"] as? [String: Any])
        XCTAssertEqual(rawVerification["status"] as? String, "passed")
        XCTAssertEqual(rawVerification["sha1Matches"] as? Bool, true)
        XCTAssertEqual(rawVerification["crc32Matches"] as? Bool, true)
        XCTAssertEqual(rawVerification["sizeMatches"] as? Bool, true)
        XCTAssertNotNil(rawResult["manifest"] as? [String: Any])
        XCTAssertNil(object?["patchManifest"])
    }

    @MainActor
    func testPatchCreationRefreshesPatchLibraryAndSelectsCreatedBPSArtifact() throws {
        let root = try makeSourceIndexProject()
        let baseROM = root.appendingPathComponent("clean-base.gba")
        let builtOutput = root.appendingPathComponent("pokeemerald.gba")
        let baseData = Data("abc".utf8)
        let targetData = Data("abxyz".utf8)
        try write(baseData, to: baseROM)
        try write(targetData, to: builtOutput)
        try write("a9993e364706816aba3e25717850c26c9cd0d89d  clean-base.gba\n", to: root.appendingPathComponent("rom.sha1"))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        let targetID = try XCTUnwrap(store.selectedRunnableBuildTargets.first?.id)
        store.selectedDecompBuildTargetID = targetID
        store.requestBaseROMPath(baseROM.path)
        store.loadSelectedPatchCreationPreview()
        store.createSelectedBPSPatch()

        let patchURL = root.appendingPathComponent(".pokemonhackstudio/patches/clean-base-to-pokeemerald.bps")
        let manifestURL = root.appendingPathComponent(".pokemonhackstudio/patches/clean-base-to-pokeemerald.bps.manifest.json")
        let library = try XCTUnwrap(store.selectedPatchArtifactLibrary)
        XCTAssertEqual(store.patchArtifactLibraryLoadStatus, .loaded(count: 1, status: .valid))
        XCTAssertEqual(library.items.count, 1)
        let item = try XCTUnwrap(library.items.first)
        XCTAssertEqual(item.patchPath, patchURL.path)
        XCTAssertEqual(item.manifestPath, manifestURL.path)
        XCTAssertEqual(item.manifestStatus, PatchArtifactLibraryManifestStatus.matched.rawValue)
        XCTAssertEqual(item.patchChecksumStatus, PatchArtifactLibraryCheckStatus.matched.rawValue)
        XCTAssertEqual(item.baseROMStatus, PatchArtifactLibraryCheckStatus.matched.rawValue)
        XCTAssertEqual(item.builtOutputStatus, PatchArtifactLibraryCheckStatus.matched.rawValue)
        XCTAssertEqual(store.selectedPatchArtifactLibraryItemID, patchURL.path)
        XCTAssertTrue(store.filteredPatchArtifactLibraryRows.contains { $0.title == "BPS patch artifact" })
        XCTAssertTrue(store.filteredPatchArtifactLibraryRows.contains { $0.title == "Creation manifest" })
        XCTAssertTrue(store.filteredPatchArtifactLibraryRows.contains { $0.title == "Base ROM status" })
        XCTAssertTrue(store.filteredPatchArtifactLibraryRows.contains { $0.title == "Built output status" })
        XCTAssertEqual(store.selectedPatchPath, "")
        XCTAssertNil(store.latestPatchApplyExportResult)
        XCTAssertFalse(store.canApplyExportSelectedPatch)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/patches/clean-base-to-pokeemerald.gba").path))

        NSPasteboard.general.clearContents()
        store.copyPatchArtifactLibraryJSONToPasteboard()

        let libraryJSON = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let libraryData = try XCTUnwrap(libraryJSON.data(using: .utf8))
        let libraryObject = try JSONSerialization.jsonObject(with: libraryData) as? [String: Any]
        let rawItems = try XCTUnwrap(libraryObject?["items"] as? [[String: Any]])
        XCTAssertEqual(rawItems.count, 1)
        XCTAssertEqual(rawItems.first?["patchPath"] as? String, patchURL.path)

        store.copyBuildPatchPlaytestReportJSONToPasteboard()

        let reportJSON = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let reportData = try XCTUnwrap(reportJSON.data(using: .utf8))
        let reportObject = try JSONSerialization.jsonObject(with: reportData) as? [String: Any]
        XCTAssertNotNil(reportObject?["patchCreationResult"] as? [String: Any])
        XCTAssertNotNil(reportObject?["patchArtifactLibrary"] as? [String: Any])
        XCTAssertNil(reportObject?["patchManifest"])
    }

    @MainActor
    func testPatchDistributionReadinessRowsCopyJSONAndRequireExplicitPatchSelection() throws {
        let root = try makeSourceIndexProject()
        let baseROM = root.appendingPathComponent("clean-base.gba")
        let builtOutput = root.appendingPathComponent("pokeemerald.gba")
        let baseData = Data("abc".utf8)
        let targetData = Data("abxyz".utf8)
        try write(baseData, to: baseROM)
        try write(targetData, to: builtOutput)
        try write("a9993e364706816aba3e25717850c26c9cd0d89d  clean-base.gba\n", to: root.appendingPathComponent("rom.sha1"))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        let targetID = try XCTUnwrap(store.selectedRunnableBuildTargets.first?.id)
        store.selectedDecompBuildTargetID = targetID
        store.requestBaseROMPath(baseROM.path)
        store.loadSelectedPatchCreationPreview()
        store.createSelectedBPSPatch()

        let patchURL = root.appendingPathComponent(".pokemonhackstudio/patches/clean-base-to-pokeemerald.bps")
        XCTAssertEqual(store.selectedPatchArtifactLibraryItemID, patchURL.path)
        XCTAssertEqual(store.selectedPatchDistributionReadinessPatchPath, "")
        XCTAssertNil(store.selectedPatchDistributionReadinessReport)

        let missingPacketCommand = try XCTUnwrap(store.workbenchCommands.first { $0.id == "copy:patch-distribution-readiness-json" })
        XCTAssertFalse(missingPacketCommand.availability.isEnabled)
        XCTAssertEqual(missingPacketCommand.availability.disabledReason, "Refresh patch distribution readiness before copying JSON.")

        let beforeReadinessFiles = try recursiveRelativeFiles(in: root)
        store.loadSelectedPatchDistributionReadinessPacket()

        let blockedReport = try XCTUnwrap(store.selectedPatchDistributionReadinessReport)
        XCTAssertEqual(blockedReport.status, .error)
        XCTAssertEqual(blockedReport.statusLabel, "blocked")
        XCTAssertNil(blockedReport.selectedPatchPath)
        XCTAssertTrue(blockedReport.rows.contains { $0.title == "Selected patch artifact" && $0.subtitle == "not selected" })
        XCTAssertTrue(blockedReport.diagnostics.contains { $0.title == "PATCH_DISTRIBUTION_PATCH_NOT_SELECTED" })
        XCTAssertTrue(store.filteredPatchDistributionReadinessRows.contains { $0.title == "Patch distribution readiness" })
        XCTAssertEqual(try recursiveRelativeFiles(in: root), beforeReadinessFiles)

        let blockedPacketCommand = try XCTUnwrap(store.workbenchCommands.first { $0.id == "copy:patch-distribution-readiness-json" })
        XCTAssertTrue(blockedPacketCommand.availability.isEnabled)

        NSPasteboard.general.clearContents()
        store.executeCommand(blockedPacketCommand)

        let blockedPacketJSON = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let blockedPacketData = try XCTUnwrap(blockedPacketJSON.data(using: .utf8))
        let blockedPacketObject = try JSONSerialization.jsonObject(with: blockedPacketData) as? [String: Any]
        XCTAssertEqual(blockedPacketObject?["status"] as? String, "blocked")
        XCTAssertNil(blockedPacketObject?["selectedPatchPath"])

        store.requestPatchDistributionReadinessPatchSelection(patchURL.path)
        XCTAssertNil(store.selectedPatchDistributionReadinessReport)
        store.loadSelectedPatchDistributionReadinessPacket()

        let report = try XCTUnwrap(store.selectedPatchDistributionReadinessReport)
        XCTAssertNotEqual(report.status, .error)
        XCTAssertEqual(report.selectedPatchPath, patchURL.path)
        XCTAssertTrue(store.filteredPatchDistributionReadinessRows.contains { $0.title == "Patch distribution readiness" })
        XCTAssertTrue(store.filteredPatchDistributionReadinessRows.contains { $0.title == "Selected patch artifact" && $0.subtitle == "valid" })
        XCTAssertTrue(store.filteredPatchDistributionReadinessRows.contains { $0.title == "Patch artifact library" })
        XCTAssertTrue(store.filteredPatchDistributionReadinessRows.contains { $0.title == "Base ROM identity" })
        XCTAssertTrue(store.filteredPatchDistributionReadinessRows.contains { $0.title == "Built output identity" })
        XCTAssertTrue(store.filteredPatchDistributionReadinessRows.contains { $0.title == "Header policy" && $0.subtitle == "no-header-rewrite" })
        XCTAssertTrue(store.filteredPatchDistributionReadinessRows.contains { $0.title == "Manual playtest readiness" })
        XCTAssertTrue(
            store.filteredPatchDistributionReadinessRows.contains { $0.title == "Blocked actions" && $0.detail.contains("Patch file creation") },
            store.filteredPatchDistributionReadinessRows.map { "\($0.title): \($0.detail)" }.joined(separator: "\n")
        )
        store.selectedBuildWorkbenchTab = .patch
        XCTAssertTrue(store.filteredBuildRowsForSelectedTab.contains { $0.title == "Patch distribution readiness" })
        XCTAssertEqual(try recursiveRelativeFiles(in: root), beforeReadinessFiles)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/patches/clean-base-to-pokeemerald.gba").path))

        NSPasteboard.general.clearContents()
        store.copyPatchDistributionReadinessJSONToPasteboard()

        let packetJSON = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let packetData = try XCTUnwrap(packetJSON.data(using: .utf8))
        let packetObject = try JSONSerialization.jsonObject(with: packetData) as? [String: Any]
        XCTAssertTrue(["ready", "readyWithWarnings"].contains(packetObject?["status"] as? String))
        XCTAssertEqual(packetObject?["selectedPatchPath"] as? String, patchURL.path)

        let packetCommand = try XCTUnwrap(store.workbenchCommands.first { $0.id == "copy:patch-distribution-readiness-json" })
        XCTAssertTrue(packetCommand.availability.isEnabled)

        NSPasteboard.general.clearContents()
        store.executeCommand(packetCommand)

        let commandPacketJSON = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let commandPacketData = try XCTUnwrap(commandPacketJSON.data(using: .utf8))
        let commandPacketObject = try JSONSerialization.jsonObject(with: commandPacketData) as? [String: Any]
        XCTAssertTrue(["ready", "readyWithWarnings"].contains(commandPacketObject?["status"] as? String))
        XCTAssertEqual(commandPacketObject?["selectedPatchPath"] as? String, patchURL.path)

        store.copyBuildPatchPlaytestReportJSONToPasteboard()

        let reportJSON = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let reportData = try XCTUnwrap(reportJSON.data(using: .utf8))
        let reportObject = try JSONSerialization.jsonObject(with: reportData) as? [String: Any]
        let rawPacket = try XCTUnwrap(reportObject?["patchDistributionReadiness"] as? [String: Any])
        XCTAssertEqual(rawPacket["selectedPatchPath"] as? String, patchURL.path)
    }

    @MainActor
    func testShipPreviewDigestSummarizesLoadedReadinessWithoutExecutingActions() throws {
        let root = try makeSourceIndexProject()
        let baseROM = root.appendingPathComponent("clean-base.gba")
        let builtOutput = root.appendingPathComponent("pokeemerald.gba")
        try write(Data("abc".utf8), to: baseROM)
        try write(Data("abcd".utf8), to: builtOutput)
        let binaryTemp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(binaryTemp)
        let rom = binaryTemp.url.appendingPathComponent("dry-run.gba")
        try writeBinaryMutationSyntheticGBA(to: rom)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        let targetID = try XCTUnwrap(store.selectedRunnableBuildTargets.first?.id)
        store.selectedDecompBuildTargetID = targetID
        store.requestBaseROMPath(baseROM.path)
        store.loadSelectedPatchCreationPreview()
        store.recheckPatchArtifactLibrary()
        store.loadSelectedPatchDistributionReadinessPacket()
        store.loadSelectedMapRenderAudit()
        store.requestBinaryROMMutationDryRunPath(rom.path)
        store.loadSelectedBinaryROMMutationDryRunManifest()

        let beforeProjectFiles = try recursiveRelativeFiles(in: root)
        let beforeROMFiles = try recursiveRelativeFiles(in: binaryTemp.url)
        let digest = try XCTUnwrap(store.selectedShipPreviewDigest)

        XCTAssertEqual(digest.title, "Ship Preview Digest")
        XCTAssertEqual(digest.rows.map(\.area), ShipPreviewDigestArea.allCases)
        XCTAssertTrue(digest.rows.first { $0.area == .validation }?.detail.contains("does not run validation") == true)
        XCTAssertTrue(digest.rows.first { $0.area == .buildOutputs }?.subtitle.contains("generated output") == true)
        XCTAssertTrue(digest.rows.first { $0.area == .patchCreation }?.detail.contains("preview-only") == true)
        XCTAssertTrue(digest.rows.first { $0.area == .patchLibrary }?.detail.contains("Read-only") == true)
        XCTAssertTrue(digest.rows.first { $0.area == .patchDistribution }?.subtitle.contains("blocked") == true)
        XCTAssertTrue(digest.rows.first { $0.area == .mapRenderAudit }?.subtitle.contains("maps") == true)
        XCTAssertTrue(digest.rows.first { $0.area == .playtest }?.detail.isEmpty == false)
        XCTAssertTrue(digest.rows.first { $0.area == .binaryMutationAudit }?.detail.contains("Dry-run manifest") == true)

        store.copyShipPreviewDigestJSONToPasteboard()
        store.copyShipPreviewDigestMarkdownToPasteboard()

        XCTAssertNil(store.selectedBuildRunResult)
        XCTAssertNil(store.selectedPlaytestLaunchResult)
        XCTAssertNil(store.selectedPlaytestCaptureResult)
        XCTAssertNil(store.latestPatchCreationResult)
        XCTAssertNil(store.latestPatchApplyExportResult)
        XCTAssertNil(store.latestBinaryROMMutationApplyResult)
        XCTAssertEqual(try recursiveRelativeFiles(in: root), beforeProjectFiles)
        XCTAssertEqual(try recursiveRelativeFiles(in: binaryTemp.url), beforeROMFiles)
    }

    @MainActor
    func testShipPreviewDigestCopiesJSONMarkdownAndNavigatesToOwningSections() throws {
        let root = try makeSourceIndexProject()
        let baseROM = root.appendingPathComponent("clean-base.gba")
        let builtOutput = root.appendingPathComponent("pokeemerald.gba")
        try write(Data("abc".utf8), to: baseROM)
        try write(Data("abcd".utf8), to: builtOutput)
        let binaryTemp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(binaryTemp)
        let rom = binaryTemp.url.appendingPathComponent("dry-run.gba")
        try writeBinaryMutationSyntheticGBA(to: rom)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        let targetID = try XCTUnwrap(store.selectedRunnableBuildTargets.first?.id)
        store.selectedDecompBuildTargetID = targetID
        store.requestBaseROMPath(baseROM.path)
        store.loadSelectedPatchCreationPreview()
        store.loadSelectedMapRenderAudit()
        store.requestBinaryROMMutationDryRunPath(rom.path)
        store.loadSelectedBinaryROMMutationDryRunManifest()

        let digest = try XCTUnwrap(store.selectedShipPreviewDigest)
        NSPasteboard.general.clearContents()
        store.copyShipPreviewDigestJSONToPasteboard()

        let json = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let data = try XCTUnwrap(json.data(using: .utf8))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let rows = try XCTUnwrap(object["rows"] as? [[String: Any]])
        XCTAssertEqual(object["title"] as? String, "Ship Preview Digest")
        XCTAssertEqual(rows.count, ShipPreviewDigestArea.allCases.count)
        XCTAssertEqual(rows.first?["area"] as? String, ShipPreviewDigestArea.validation.rawValue)
        XCTAssertTrue(rows.contains { $0["targetTab"] as? String == BuildWorkbenchTab.patch.rawValue })

        store.copyShipPreviewDigestMarkdownToPasteboard()
        let markdown = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        XCTAssertTrue(markdown.contains("# Ship Preview Digest"))
        XCTAssertTrue(markdown.contains("Patch creation state"))
        XCTAssertTrue(markdown.contains("Binary mutation audit"))

        let patchCreationRow = try XCTUnwrap(digest.rows.first { $0.area == .patchCreation })
        let patchTarget = try XCTUnwrap(patchCreationRow.targetRowID)
        store.selectedBuildWorkbenchTab = .build
        store.requestBuildReportRowSelection("")
        store.openShipPreviewDigestRow(patchCreationRow)
        XCTAssertEqual(store.selectedBuildWorkbenchTab, .patch)
        XCTAssertEqual(store.selectedBuildReportRowID, patchTarget)

        let playtestRow = try XCTUnwrap(digest.rows.first { $0.area == .playtest })
        let playtestTarget = try XCTUnwrap(playtestRow.targetRowID)
        store.openShipPreviewDigestRow(playtestRow)
        XCTAssertEqual(store.selectedBuildWorkbenchTab, .playtest)
        XCTAssertEqual(store.selectedBuildReportRowID, playtestTarget)
    }

    @MainActor
    func testPatchLibraryRowsIncludeResourcesWorkflowFacetContextWithoutChangingPatchAuthority() async throws {
        let root = try makeSourceIndexProject()
        let baseROM = root.appendingPathComponent("clean-base.gba")
        let builtOutput = root.appendingPathComponent("pokeemerald.gba")
        let baseData = Data("abc".utf8)
        let targetData = Data("abxyz".utf8)
        try write(baseData, to: baseROM)
        try write(targetData, to: builtOutput)
        try write("a9993e364706816aba3e25717850c26c9cd0d89d  clean-base.gba\n", to: root.appendingPathComponent("rom.sha1"))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        XCTAssertTrue(assetCatalog.rows.contains { $0.availability == "availableSource" })
        XCTAssertTrue(assetCatalog.rows.contains { $0.role == "generated" || $0.role == "artifact" })

        let targetID = try XCTUnwrap(store.selectedRunnableBuildTargets.first?.id)
        store.selectedDecompBuildTargetID = targetID
        store.requestBaseROMPath(baseROM.path)
        store.loadSelectedPatchCreationPreview()
        store.createSelectedBPSPatch()

        let patchURL = root.appendingPathComponent(".pokemonhackstudio/patches/clean-base-to-pokeemerald.bps")
        let patchedROMURL = root.appendingPathComponent(".pokemonhackstudio/patches/clean-base-to-pokeemerald.gba")
        let rows = store.filteredPatchArtifactLibraryRows
        let patchRowIndex = try XCTUnwrap(rows.firstIndex { $0.title == "BPS patch artifact" })
        let resourcesSummaryIndex = try XCTUnwrap(rows.firstIndex { $0.title == "Resources workflow facets" })

        XCTAssertLessThan(patchRowIndex, resourcesSummaryIndex)
        XCTAssertTrue(rows.contains { $0.title == "Resources: Editable Source" && $0.detail.contains("Sample:") })
        XCTAssertTrue(rows.contains { $0.title == "Resources: Generated/Reference" && $0.detail.contains("Existing Resources facet only") })
        XCTAssertTrue(rows.contains { $0.title == "Resources workflow facets" && $0.detail.contains("no parser") })
        XCTAssertEqual(store.selectedPatchArtifactLibraryItemID, patchURL.path)
        XCTAssertEqual(store.selectedPatchPath, "")
        XCTAssertNil(store.latestPatchApplyExportResult)
        XCTAssertFalse(store.canApplyExportSelectedPatch)
        XCTAssertFalse(FileManager.default.fileExists(atPath: patchedROMURL.path))
    }

    @MainActor
    func testBinaryROMMutationDryRunLoadsSelectedLocalGBAAndCopiesJSONWithoutWritingOutputs() throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let rom = temp.url.appendingPathComponent("dry-run.gba")
        try writeBinaryMutationSyntheticGBA(to: rom)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.requestBinaryROMMutationDryRunPath("  \(rom.path)  ")
        store.loadSelectedBinaryROMMutationDryRunManifest()

        let report = try XCTUnwrap(store.selectedBinaryROMMutationDryRunReport)
        XCTAssertEqual(store.selectedBinaryROMMutationDryRunPath, rom.path)
        XCTAssertTrue(report.isDryRun)
        XCTAssertFalse(report.canApply)
        XCTAssertEqual(report.sourceTreeStatus, BinaryROMMutationSourceTreeStatus.binaryOnlyCandidate.rawValue)
        XCTAssertNotNil(report.baseIdentity)
        XCTAssertFalse(report.ignoredOutputGuidance.willWriteFiles)
        XCTAssertEqual(report.ignoredOutputGuidance.relativeManifestPath, ".pokemonhackstudio/rom-mutations/dry-run/manifest.json")
        XCTAssertTrue(report.operationPreviews.isEmpty)
        XCTAssertTrue(report.diagnostics.contains { $0.title == "BINARY_ROM_MUTATION_NO_OPERATIONS" })
        XCTAssertTrue(store.filteredBinaryROMMutationDryRunRows.contains { $0.title == "Base ROM identity" })
        if case let .loaded(label, state) = store.binaryROMMutationDryRunLoadStatus {
            XCTAssertEqual(label, "Dry Run")
            XCTAssertEqual(state, report.status)
        } else {
            XCTFail("Expected loaded binary ROM mutation dry-run status")
        }

        NSPasteboard.general.clearContents()
        store.copyBinaryROMMutationDryRunManifestJSONToPasteboard()

        let manifestJSON = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let manifestData = try XCTUnwrap(manifestJSON.data(using: .utf8))
        let manifestObject = try JSONSerialization.jsonObject(with: manifestData) as? [String: Any]
        XCTAssertEqual(manifestObject?["isDryRun"] as? Bool, true)
        XCTAssertEqual(manifestObject?["canApply"] as? Bool, false)
        let ignoredOutput = manifestObject?["ignoredOutputGuidance"] as? [String: Any]
        XCTAssertEqual(ignoredOutput?["willWriteFiles"] as? Bool, false)

        store.copyBuildPatchPlaytestReportJSONToPasteboard()

        let reportJSON = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let reportData = try XCTUnwrap(reportJSON.data(using: .utf8))
        let reportObject = try JSONSerialization.jsonObject(with: reportData) as? [String: Any]
        XCTAssertNotNil(reportObject?["binaryROMMutationDryRunManifest"])
        XCTAssertFalse(FileManager.default.fileExists(atPath: temp.url.appendingPathComponent(".pokemonhackstudio").path))
    }

    @MainActor
    func testBinaryROMMutationDryRunRefusesMatchingSourceTreeCandidateWithoutWritingOutputs() throws {
        let root = try makeSourceIndexProject()
        let rom = root.appendingPathComponent("source-first.gba")
        try writeBinaryMutationSyntheticGBA(to: rom)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.requestBinaryROMMutationDryRunPath(rom.path)
        store.loadSelectedBinaryROMMutationDryRunManifest()

        let report = try XCTUnwrap(store.selectedBinaryROMMutationDryRunReport)
        XCTAssertTrue(report.isDryRun)
        XCTAssertFalse(report.canApply)
        XCTAssertEqual(report.sourceTreeStatus, BinaryROMMutationSourceTreeStatus.refusedSourceTreeAvailable.rawValue)
        XCTAssertEqual(report.sourceCandidates, [root.path])
        XCTAssertTrue(report.operationPreviews.isEmpty)
        XCTAssertTrue(report.diagnostics.contains { $0.title == "BINARY_ROM_MUTATION_SOURCE_TREE_AVAILABLE_REFUSED" })
        XCTAssertTrue(store.selectedDiagnosticRows.contains { $0.title == "BINARY_ROM_MUTATION_SOURCE_TREE_AVAILABLE_REFUSED" })
        if case let .loaded(label, state) = store.binaryROMMutationDryRunLoadStatus {
            XCTAssertEqual(label, "Blocked")
            XCTAssertEqual(state, .error)
        } else {
            XCTFail("Expected blocked binary ROM mutation dry-run status")
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio").path))
    }

    @MainActor
    func testBinaryROMMutationApplyReviewAppliesSelectedManifestWithToken() throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let rom = temp.url.appendingPathComponent("phs-t79d.gba")
        try writeBinaryMutationSyntheticGBA(to: rom)
        let originalData = try Data(contentsOf: rom)
        let manifest = BinaryROMMutationDryRunManifestBuilder.build(
            path: rom.path,
            request: BinaryROMMutationDryRunRequest(
                workspaceRoot: temp.url.path,
                replacements: [
                    BinaryROMMutationReplacementRequest(offset: 0x120, length: 2, replacementBytes: [0xAA, 0xBB])
                ]
            )
        )
        let token = try XCTUnwrap(manifest.applyReview?.reviewToken)
        let manifestURL = temp.url.appendingPathComponent("phs-t79d-dry-run.json")
        try writeBinaryMutationManifest(manifest, to: manifestURL)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.requestBinaryROMMutationDryRunPath(rom.path)
        store.requestBinaryROMMutationDryRunManifestPath(manifestURL.path)
        store.loadSelectedBinaryROMMutationDryRunManifestFromJSON()
        store.binaryROMMutationApplyConfirmationToken = token

        XCTAssertTrue(store.canApplySelectedBinaryROMMutationReview)
        XCTAssertTrue(store.filteredBinaryROMMutationDryRunRows.contains { $0.title == "Apply review token" })
        XCTAssertTrue(store.filteredBinaryROMMutationDryRunRows.contains { $0.title == "Blocked broader binary actions" && $0.detail.contains("app auto-apply") })
        XCTAssertTrue(store.filteredBinaryROMMutationApplyAuditRows.contains { $0.title == "Audit status" && $0.subtitle == "ready" })
        XCTAssertTrue(store.filteredBinaryROMMutationApplyAuditRows.contains { $0.title == "Ignored backup destination" && $0.subtitle == "pending explicit apply" })
        XCTAssertNil(store.latestBinaryROMMutationApplyResult)

        let auditCommand = try XCTUnwrap(store.workbenchCommands.first { $0.id == "copy:binary-rom-mutation-apply-audit-json" })
        XCTAssertTrue(auditCommand.availability.isEnabled)

        NSPasteboard.general.clearContents()
        store.executeCommand(auditCommand)

        let auditJSON = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let auditData = try XCTUnwrap(auditJSON.data(using: .utf8))
        let auditObject = try JSONSerialization.jsonObject(with: auditData) as? [String: Any]
        XCTAssertEqual(auditObject?["status"] as? String, "ready")
        let artifactReviewsBeforeApply = try XCTUnwrap(auditObject?["artifactReviews"] as? [[String: Any]])
        XCTAssertTrue(artifactReviewsBeforeApply.contains { $0["kind"] as? String == "originalROMBackup" && $0["status"] as? String == "pendingExplicitApply" })
        XCTAssertNil(store.latestBinaryROMMutationApplyResult)
        XCTAssertEqual(try Data(contentsOf: rom), originalData)

        store.applySelectedBinaryROMMutationReview()

        let result = try XCTUnwrap(store.latestBinaryROMMutationApplyResult)
        XCTAssertEqual(result.status, .applied)
        XCTAssertEqual(result.appliedReplacements.count, 1)
        XCTAssertEqual(Array(try Data(contentsOf: rom)[0x120 ..< 0x122]), [0xAA, 0xBB])
        let backupPath = try XCTUnwrap(result.backupPath)
        let applyManifestPath = try XCTUnwrap(result.manifestPath)
        XCTAssertTrue(backupPath.contains(".pokemonhackstudio/rom-mutations/phs-t79d/"))
        XCTAssertTrue(applyManifestPath.contains(".pokemonhackstudio/rom-mutations/phs-t79d/"))
        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: backupPath)), originalData)
        XCTAssertTrue(FileManager.default.fileExists(atPath: applyManifestPath))
        XCTAssertFalse(FileManager.default.fileExists(atPath: temp.url.appendingPathComponent(".pokemonhackstudio/rom-mutations/phs-t79d/phs-t79d-patched.gba").path))
        XCTAssertTrue(store.filteredBinaryROMMutationApplyResultRows.contains { $0.title == "Apply manifest" })
        XCTAssertTrue(store.filteredBinaryROMMutationApplyAuditRows.contains { $0.title == "Ignored backup destination" && $0.subtitle == "written after apply" })
        XCTAssertTrue(store.filteredBinaryROMMutationApplyAuditRows.contains { $0.title == "Ignored apply-manifest destination" && $0.subtitle == "written after apply" })
        XCTAssertTrue(store.filteredBinaryROMMutationApplyAuditRows.contains { $0.title == "Irreversible replace-only apply status" && $0.subtitle == "applied in this session" })

        NSPasteboard.general.clearContents()
        store.copyBuildPatchPlaytestReportJSONToPasteboard()
        let reportJSON = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let reportData = try XCTUnwrap(reportJSON.data(using: .utf8))
        let reportObject = try JSONSerialization.jsonObject(with: reportData) as? [String: Any]
        let rawResult = try XCTUnwrap(reportObject?["binaryROMMutationApplyResult"] as? [String: Any])
        XCTAssertEqual(rawResult["status"] as? String, "applied")
        let rawAudit = try XCTUnwrap(reportObject?["binaryROMMutationApplyAudit"] as? [String: Any])
        XCTAssertEqual(rawAudit["status"] as? String, "ready")
        let artifactReviews = try XCTUnwrap(rawAudit["artifactReviews"] as? [[String: Any]])
        XCTAssertTrue(artifactReviews.contains { $0["kind"] as? String == "originalROMBackup" && $0["status"] as? String == "writtenAfterApply" })
    }

    @MainActor
    func testBinaryROMMutationApplyReviewBlocksWrongTokenWithoutWriting() throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let rom = temp.url.appendingPathComponent("phs-t79d.gba")
        try writeBinaryMutationSyntheticGBA(to: rom)
        let originalData = try Data(contentsOf: rom)
        let manifest = BinaryROMMutationDryRunManifestBuilder.build(
            path: rom.path,
            request: BinaryROMMutationDryRunRequest(
                workspaceRoot: temp.url.path,
                replacements: [
                    BinaryROMMutationReplacementRequest(offset: 0x120, length: 2, replacementBytes: [0xAA, 0xBB])
                ]
            )
        )
        let manifestURL = temp.url.appendingPathComponent("phs-t79d-dry-run.json")
        try writeBinaryMutationManifest(manifest, to: manifestURL)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.requestBinaryROMMutationDryRunPath(rom.path)
        store.requestBinaryROMMutationDryRunManifestPath(manifestURL.path)
        store.loadSelectedBinaryROMMutationDryRunManifestFromJSON()
        store.binaryROMMutationApplyConfirmationToken = "romreplace-wrong"

        XCTAssertTrue(store.canApplySelectedBinaryROMMutationReview)
        store.applySelectedBinaryROMMutationReview()

        let result = try XCTUnwrap(store.latestBinaryROMMutationApplyResult)
        XCTAssertEqual(result.status, .blocked)
        XCTAssertTrue(result.diagnostics.contains { $0.code == "BINARY_ROM_MUTATION_APPLY_CONFIRMATION_MISMATCH" })
        XCTAssertEqual(try Data(contentsOf: rom), originalData)
        XCTAssertFalse(FileManager.default.fileExists(atPath: temp.url.appendingPathComponent(".pokemonhackstudio").path))
        XCTAssertTrue(store.filteredBinaryROMMutationApplyResultRows.contains { $0.title == "Binary ROM replacement apply" && $0.subtitle == "blocked" })
        XCTAssertTrue(store.filteredBinaryROMMutationApplyAuditRows.contains { $0.title == "Ignored backup destination" && $0.subtitle == "blocked before write" })
    }

    @MainActor
    func testBinaryROMMutationApplyReviewRefusesSourceTreeCandidateAndDrift() throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let rom = temp.url.appendingPathComponent("phs-t79d.gba")
        try writeBinaryMutationSyntheticGBA(to: rom)
        let originalData = try Data(contentsOf: rom)
        let manifest = BinaryROMMutationDryRunManifestBuilder.build(
            path: rom.path,
            request: BinaryROMMutationDryRunRequest(
                workspaceRoot: temp.url.path,
                replacements: [
                    BinaryROMMutationReplacementRequest(offset: 0x120, length: 2, replacementBytes: [0xAA, 0xBB])
                ]
            )
        )
        let token = try XCTUnwrap(manifest.applyReview?.reviewToken)
        let manifestURL = temp.url.appendingPathComponent("phs-t79d-dry-run.json")
        try writeBinaryMutationManifest(manifest, to: manifestURL)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)
        store.requestBinaryROMMutationDryRunPath(rom.path)
        store.requestBinaryROMMutationDryRunManifestPath(manifestURL.path)
        store.loadSelectedBinaryROMMutationDryRunManifestFromJSON()
        store.binaryROMMutationApplyConfirmationToken = token

        let sourceRoot = temp.url.appendingPathComponent("pokeemerald")
        try writeMinimalEmeraldSourceTree(at: sourceRoot)
        store.applySelectedBinaryROMMutationReview()

        var result = try XCTUnwrap(store.latestBinaryROMMutationApplyResult)
        XCTAssertEqual(result.status, .blocked)
        XCTAssertTrue(result.diagnostics.contains { $0.code == "BINARY_ROM_MUTATION_APPLY_SOURCE_TREE_AVAILABLE_REFUSED" })
        XCTAssertEqual(try Data(contentsOf: rom), originalData)
        XCTAssertFalse(FileManager.default.fileExists(atPath: temp.url.appendingPathComponent(".pokemonhackstudio").path))

        try FileManager.default.removeItem(at: sourceRoot)
        var drifted = originalData
        drifted[0x130] = 0x44
        try drifted.write(to: rom)
        store.applySelectedBinaryROMMutationReview()

        result = try XCTUnwrap(store.latestBinaryROMMutationApplyResult)
        XCTAssertEqual(result.status, .blocked)
        XCTAssertTrue(result.diagnostics.contains { $0.code == "BINARY_ROM_MUTATION_APPLY_BASE_SHA1_DRIFT" })
        XCTAssertEqual(try Data(contentsOf: rom), drifted)
        XCTAssertFalse(FileManager.default.fileExists(atPath: temp.url.appendingPathComponent(".pokemonhackstudio").path))
    }

    @MainActor
    func testBinaryROMMutationApplyAuditRowsDisableApplyWhenCurrentStateDrifts() throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let rom = temp.url.appendingPathComponent("phs-t79e.gba")
        try writeBinaryMutationSyntheticGBA(to: rom)
        let originalData = try Data(contentsOf: rom)
        let manifest = BinaryROMMutationDryRunManifestBuilder.build(
            path: rom.path,
            request: BinaryROMMutationDryRunRequest(
                workspaceRoot: temp.url.path,
                replacements: [
                    BinaryROMMutationReplacementRequest(offset: 0x120, length: 2, replacementBytes: [0xAA, 0xBB])
                ]
            )
        )
        let token = try XCTUnwrap(manifest.applyReview?.reviewToken)
        let manifestURL = temp.url.appendingPathComponent("phs-t79e-dry-run.json")
        try writeBinaryMutationManifest(manifest, to: manifestURL)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.requestBinaryROMMutationDryRunPath(rom.path)
        store.requestBinaryROMMutationDryRunManifestPath(manifestURL.path)
        store.loadSelectedBinaryROMMutationDryRunManifestFromJSON()
        store.binaryROMMutationApplyConfirmationToken = token

        XCTAssertTrue(store.canApplySelectedBinaryROMMutationReview)
        XCTAssertTrue(store.filteredBinaryROMMutationApplyAuditRows.contains { $0.title == "Audit status" && $0.subtitle == "ready" })

        let sourceRoot = temp.url.appendingPathComponent("pokeemerald")
        try writeMinimalEmeraldSourceTree(at: sourceRoot)
        store.loadSelectedBinaryROMMutationDryRunManifestFromJSON()
        store.binaryROMMutationApplyConfirmationToken = token

        XCTAssertFalse(store.canApplySelectedBinaryROMMutationReview)
        XCTAssertTrue(store.binaryROMMutationApplyDisabledReason?.contains("audit is blocked") == true)
        XCTAssertTrue(store.filteredBinaryROMMutationApplyAuditRows.contains { $0.title == "Audit status" && $0.subtitle == "blocked" })
        XCTAssertTrue(store.filteredBinaryROMMutationApplyAuditRows.contains { $0.title == "Ignored backup destination" && $0.subtitle == "blocked before write" })
        XCTAssertTrue(store.filteredBinaryROMMutationApplyAuditRows.contains { $0.tags.contains("BINARY_ROM_MUTATION_AUDIT_SOURCE_TREE_AVAILABLE_REFUSED") })
        XCTAssertEqual(try Data(contentsOf: rom), originalData)
        XCTAssertFalse(FileManager.default.fileExists(atPath: temp.url.appendingPathComponent(".pokemonhackstudio").path))

        try FileManager.default.removeItem(at: sourceRoot)
        var drifted = originalData
        drifted[0x120] = 0x99
        try drifted.write(to: rom)
        store.loadSelectedBinaryROMMutationDryRunManifestFromJSON()
        store.binaryROMMutationApplyConfirmationToken = token

        XCTAssertFalse(store.canApplySelectedBinaryROMMutationReview)
        XCTAssertTrue(store.filteredBinaryROMMutationApplyAuditRows.contains { $0.tags.contains("BINARY_ROM_MUTATION_APPLY_BASE_SHA1_DRIFT") })
        XCTAssertTrue(store.filteredBinaryROMMutationApplyAuditRows.contains { $0.tags.contains("BINARY_ROM_MUTATION_APPLY_ORIGINAL_BYTES_MISMATCH") })
        XCTAssertEqual(try Data(contentsOf: rom), drifted)
        XCTAssertFalse(FileManager.default.fileExists(atPath: temp.url.appendingPathComponent(".pokemonhackstudio").path))
    }

    @MainActor
    func testBinaryROMMutationApplyAuditRowsSeparateCopyableStateBeforeApplyGate() throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let rom = temp.url.appendingPathComponent("phs-t79g.gba")
        try writeBinaryMutationSyntheticGBA(to: rom)
        let originalData = try Data(contentsOf: rom)
        let manifest = BinaryROMMutationDryRunManifestBuilder.build(
            path: rom.path,
            request: BinaryROMMutationDryRunRequest(
                workspaceRoot: temp.url.path,
                replacements: [
                    BinaryROMMutationReplacementRequest(offset: 0x120, length: 2, replacementBytes: [0xAA, 0xBB])
                ]
            )
        )
        let token = try XCTUnwrap(manifest.applyReview?.reviewToken)
        let manifestURL = temp.url.appendingPathComponent("phs-t79g-dry-run.json")
        try writeBinaryMutationManifest(manifest, to: manifestURL)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.requestBinaryROMMutationDryRunPath(rom.path)
        store.requestBinaryROMMutationDryRunManifestPath(manifestURL.path)
        store.loadSelectedBinaryROMMutationDryRunManifestFromJSON()

        let auditRows = store.filteredBinaryROMMutationApplyAuditRows
        XCTAssertEqual(
            auditRows.prefix(6).map(\.title),
            [
                "Audit status",
                "Review token state",
                "Current-state drift",
                "Ignored backup destination",
                "Ignored apply-manifest destination",
                "Irreversible replace-only apply status",
            ]
        )
        XCTAssertTrue(store.filteredBinaryROMMutationDryRunRows.contains { $0.title == "Apply review token" })
        XCTAssertTrue(auditRows.prefix(6).allSatisfy { row in
            row.actions.contains { $0.kind == .copyValue && $0.copyValue?.isEmpty == false }
        })

        let statusRow = try XCTUnwrap(auditRows.first { $0.title == "Audit status" })
        store.copyBuildReportRowActionToPasteboard(try XCTUnwrap(statusRow.actions.first))
        var copied = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        XCTAssertTrue(copied.contains("status=ready"))
        XCTAssertTrue(copied.contains("inputPath=\(rom.path)"))
        XCTAssertTrue(copied.contains("dryRunManifestPath=\(manifestURL.path)"))

        let tokenRow = try XCTUnwrap(auditRows.first { $0.title == "Review token state" })
        store.copyBuildReportRowActionToPasteboard(try XCTUnwrap(tokenRow.actions.first))
        copied = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        XCTAssertTrue(copied.contains("reviewToken=\(token)"))
        XCTAssertTrue(copied.contains("expectedReviewToken=\(token)"))
        XCTAssertTrue(copied.contains("isReviewTokenStale=false"))
        XCTAssertTrue(copied.contains("--confirm \(token)"))

        let driftRow = try XCTUnwrap(auditRows.first { $0.title == "Current-state drift" })
        XCTAssertEqual(driftRow.subtitle, "no drift detected")
        store.copyBuildReportRowActionToPasteboard(try XCTUnwrap(driftRow.actions.first))
        copied = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        XCTAssertTrue(copied.contains("sourceTreeFirst=clear"))
        XCTAssertTrue(copied.contains("originalBytes=clear"))

        let backupRow = try XCTUnwrap(auditRows.first { $0.title == "Ignored backup destination" })
        store.copyBuildReportRowActionToPasteboard(try XCTUnwrap(backupRow.actions.first))
        copied = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        XCTAssertTrue(copied.contains("status=pending explicit apply"))
        XCTAssertTrue(copied.contains(".pokemonhackstudio/rom-mutations/phs-t79g/"))

        let irreversibleRow = try XCTUnwrap(auditRows.first { $0.title == "Irreversible replace-only apply status" })
        XCTAssertEqual(irreversibleRow.subtitle, "pending explicit token")
        store.copyBuildReportRowActionToPasteboard(try XCTUnwrap(irreversibleRow.actions.first))
        copied = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        XCTAssertTrue(copied.contains("status=pending explicit token"))
        XCTAssertTrue(copied.contains("No patched-copy output"))
        XCTAssertTrue(copied.contains("checksum repair"))

        store.copyBinaryROMMutationApplyAuditJSONToPasteboard()
        let auditJSON = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let auditData = try XCTUnwrap(auditJSON.data(using: .utf8))
        let auditObject = try JSONSerialization.jsonObject(with: auditData) as? [String: Any]
        XCTAssertEqual(auditObject?["status"] as? String, "ready")
        XCTAssertEqual(auditObject?["reviewToken"] as? String, token)
        XCTAssertEqual(try Data(contentsOf: rom), originalData)
        XCTAssertFalse(FileManager.default.fileExists(atPath: temp.url.appendingPathComponent(".pokemonhackstudio").path))
    }

    @MainActor
    func testPatchApplyExportAuditRowsCopyJSONWithoutWritingArtifacts() throws {
        let root = try makeSourceIndexProject()
        let baseROM = root.appendingPathComponent("pokeemerald.gba")
        let patch = root.appendingPathComponent("cleanroom.bps")
        let baseData = Data("abc".utf8)
        let targetData = Data("abd".utf8)
        try write("a9993e364706816aba3e25717850c26c9cd0d89d  pokeemerald.gba\n", to: root.appendingPathComponent("rom.sha1"))
        try write(baseData, to: baseROM)
        try write(makeBPSPatch(source: baseData, target: targetData), to: patch)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.requestPatchPath(patch.path)
        store.requestBaseROMPath(baseROM.path)
        let beforeFiles = try recursiveRelativeFiles(in: root)

        store.loadSelectedPatchApplyExportAudit()

        let report = try XCTUnwrap(store.selectedPatchApplyExportAuditReport)
        XCTAssertEqual(store.patchApplyExportAuditLoadStatus, .loaded("ready", .valid))
        XCTAssertEqual(report.status, .valid)
        XCTAssertEqual(report.statusLabel, "ready")
        XCTAssertEqual(report.plannedOutputPath, root.appendingPathComponent(".pokemonhackstudio/patches/pokeemerald-cleanroom.gba").path)
        XCTAssertTrue(store.filteredPatchApplyExportAuditRows.contains { $0.title == "Patch Apply/Export Audit" && $0.subtitle == "ready" })
        XCTAssertTrue(store.filteredPatchApplyExportAuditRows.contains { $0.title == "Selected patch" && $0.subtitle.contains("BPS") })
        XCTAssertTrue(store.filteredPatchApplyExportAuditRows.contains { $0.title == "Selected base ROM" && $0.subtitle.contains("sha1 a9993e36") })
        XCTAssertTrue(store.filteredPatchApplyExportAuditRows.contains { $0.title == "Planned output path" })
        XCTAssertTrue(store.filteredPatchApplyExportAuditRows.contains { $0.title == "Overwrite and backup posture" && $0.detail.contains("Backup will be created: no") })
        XCTAssertTrue(store.filteredPatchApplyExportAuditRows.contains { $0.title == "Header policy" && $0.subtitle == "preserve-selected-base-rom-header" })
        XCTAssertTrue(store.filteredPatchApplyExportAuditRows.contains { $0.title == "Manifest compatibility" && $0.subtitle == "Base ROM matched" })
        XCTAssertTrue(store.filteredPatchApplyExportAuditRows.contains { $0.title == "Supported patch format" && $0.subtitle == "BPS" })
        XCTAssertTrue(store.filteredPatchApplyExportAuditRows.contains { $0.title == "Blocked actions" && $0.detail.contains("Patched ROM writes") })

        store.selectedBuildWorkbenchTab = .patch
        XCTAssertTrue(store.filteredBuildRowsForSelectedTab.contains { $0.title == "Patch Apply/Export Audit" })
        XCTAssertEqual(try recursiveRelativeFiles(in: root), beforeFiles)

        NSPasteboard.general.clearContents()
        store.copyPatchApplyExportAuditJSONToPasteboard()

        let auditJSON = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let auditData = try XCTUnwrap(auditJSON.data(using: .utf8))
        let auditObject = try JSONSerialization.jsonObject(with: auditData) as? [String: Any]
        XCTAssertEqual(auditObject?["status"] as? String, "ready")
        XCTAssertEqual(auditObject?["isReadOnly"] as? Bool, true)
        XCTAssertEqual(auditObject?["patchFormat"] as? String, "bps")
        XCTAssertEqual(auditObject?["plannedOutputPath"] as? String, report.plannedOutputPath)
        XCTAssertEqual(auditObject?["backupWillBeCreated"] as? Bool, false)
        XCTAssertEqual(try recursiveRelativeFiles(in: root), beforeFiles)

        NSPasteboard.general.clearContents()
        store.copyBuildPatchPlaytestReportJSONToPasteboard()

        let aggregateJSON = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let aggregateData = try XCTUnwrap(aggregateJSON.data(using: .utf8))
        let aggregateObject = try JSONSerialization.jsonObject(with: aggregateData) as? [String: Any]
        let rawAudit = try XCTUnwrap(aggregateObject?["patchApplyExportAudit"] as? [String: Any])
        XCTAssertEqual(rawAudit["status"] as? String, "ready")
        XCTAssertEqual(rawAudit["plannedOutputPath"] as? String, report.plannedOutputPath)

        XCTAssertEqual(try recursiveRelativeFiles(in: root), beforeFiles)
        XCTAssertEqual(try Data(contentsOf: baseROM), baseData)
        XCTAssertFalse(FileManager.default.fileExists(atPath: report.plannedOutputPath))
        XCTAssertFalse(FileManager.default.fileExists(atPath: report.plannedOutputPath.appending(".manifest.json")))
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/backups").path))
        XCTAssertNil(store.latestPatchApplyExportResult)
        XCTAssertNil(store.latestPatchCreationResult)
    }

    @MainActor
    func testPatchApplyExportStoreWritesPatchedROMAndManifest() throws {
        let root = try makeSourceIndexProject()
        let baseROM = root.appendingPathComponent("pokeemerald.gba")
        let patch = root.appendingPathComponent("cleanroom.bps")
        let baseData = Data("abc".utf8)
        let targetData = Data("abd".utf8)
        try write("a9993e364706816aba3e25717850c26c9cd0d89d  pokeemerald.gba\n", to: root.appendingPathComponent("rom.sha1"))
        try write(baseData, to: baseROM)
        try write(makeBPSPatch(source: baseData, target: targetData), to: patch)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.requestPatchPath(patch.path)
        store.requestBaseROMPath(baseROM.path)
        store.loadSelectedPatchManifestReport()

        XCTAssertTrue(store.canApplyExportSelectedPatch)

        store.applyExportSelectedPatchROM()

        let result = try XCTUnwrap(store.latestPatchApplyExportResult)
        let outputURL = root.appendingPathComponent(".pokemonhackstudio/patches/pokeemerald-cleanroom.gba")
        XCTAssertEqual(result.status, .exported)
        XCTAssertEqual(result.outputPath, outputURL.path)
        XCTAssertEqual(result.manifest?.patchFormat, .bps)
        XCTAssertEqual(try Data(contentsOf: outputURL), targetData)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path.appending(".manifest.json")))

        store.applyExportSelectedPatchROM()

        let blocked = try XCTUnwrap(store.latestPatchApplyExportResult)
        XCTAssertEqual(blocked.status, .blocked)
        XCTAssertNil(blocked.backupPath)
        XCTAssertTrue(blocked.diagnostics.contains { $0.code == "PATCH_EXPORT_OUTPUT_EXISTS" })
        XCTAssertEqual(try Data(contentsOf: outputURL), targetData)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/backups").path))
    }

    @MainActor
    func testGraphicsImportPackagePlanLoadsPreviewRowsAndCopiesJSON() throws {
        let root = try makeSourceIndexProject()
        let packageTemp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(packageTemp)
        let package = packageTemp.url.appendingPathComponent("Town Package")
        try write("Credits: local clean-room fixture\n", to: package.appendingPathComponent("README.md"))
        try write(Data("top".utf8), to: package.appendingPathComponent("layers/top.png"))
        try write(Data("middle".utf8), to: package.appendingPathComponent("layers/middle.png"))
        try write("metatile,behavior\n0,0\n", to: package.appendingPathComponent("attributes.csv"))
        try write(
            """
            JASC-PAL
            0100
            2
            0 0 0
            248 248 248
            """,
            to: package.appendingPathComponent("palettes/main.pal")
        )
        try write(
            Data("existing".utf8),
            to: root.appendingPathComponent("data/tilesets/imports/town-package/layers/top.png")
        )
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.requestGraphicsImportPackagePath("  \(package.path)  ")
        store.loadSelectedGraphicsImportPackagePlan()

        let plan = try XCTUnwrap(store.selectedGraphicsImportPackagePlan)
        XCTAssertEqual(store.selectedGraphicsImportPackagePath, package.path)
        XCTAssertEqual(plan.packageTitle, "Town Package")
        XCTAssertEqual(plan.readiness, "ready")
        XCTAssertTrue(plan.isPreviewOnly)
        XCTAssertEqual(plan.inventoryRows.count, 5)
        XCTAssertEqual(plan.creditMetadataRows.map(\.id), ["README.md"])
        XCTAssertEqual(plan.copyTargets.count, 5)
        XCTAssertTrue(plan.copyTargets.contains { $0.willOverwriteExistingSource && $0.title == "data/tilesets/imports/town-package/layers/top.png" })
        XCTAssertEqual(plan.layeredDryRun.detectedLayerPaths, ["layers/middle.png", "layers/top.png"])
        XCTAssertEqual(plan.layeredDryRun.missingLayerNames, ["bottom"])
        XCTAssertEqual(plan.expectedOutputs.count, 4)
        XCTAssertEqual(plan.paletteFitPreviews.map(\.id), ["palettes/main.pal"])
        XCTAssertTrue(plan.diagnostics.contains { $0.title == "GRAPHICS_IMPORT_DESTINATION_EXISTS" && $0.severity == .warning })

        store.copyGraphicsImportPackagePlanJSONToPasteboard()

        let json = try XCTUnwrap(NSPasteboard.general.string(forType: .string))
        let data = try XCTUnwrap(json.data(using: .utf8))
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(object?["packageTitle"] as? String, "Town Package")
        XCTAssertEqual(object?["isPreviewOnly"] as? Bool, true)
        XCTAssertNotNil(object?["copyPlan"])
    }

    @MainActor
    func testSpeciesAssetImportStagesFrontPNGWithoutWritingSourceBeforeApply() async throws {
        let root = try makePokemonProject()
        let originalData = Data("old-front".utf8)
        try write(originalData, to: root.appendingPathComponent("graphics/pokemon/treecko/front.png"))
        let importURL = root.appendingPathComponent("incoming/front.png")
        let importedData = testPNGData(width: 64, height: 64, paletteColorCount: 16)
        try write(importedData, to: importURL)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedSpeciesCatalogIfNeeded()
        try await waitForSelectedSpeciesCatalog(store)
        store.requestSpeciesSelection("SPECIES_TREECKO")
        let provenance = try XCTUnwrap(store.importSelectedSpeciesAsset(kind: .front, from: importURL))

        XCTAssertEqual(provenance.detectedKind, .png)
        XCTAssertEqual(provenance.status, .ready)
        XCTAssertEqual(provenance.byteCount, importedData.count)
        XCTAssertEqual(store.selectedSpeciesDraft?.assetData[.front], importedData)
        XCTAssertEqual(store.selectedSpeciesDraft?.assetImports[.front]?.sourcePath, importURL.path)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent("graphics/pokemon/treecko/front.png")), originalData)

        store.previewSelectedSpeciesMutationPlan()

        let plan = try XCTUnwrap(store.latestSpeciesEditPlan)
        XCTAssertTrue(plan.isApplyable)
        XCTAssertTrue(plan.changes.contains { $0.path == "graphics/pokemon/treecko/front.png" })

        store.applySelectedSpeciesMutationPlan()

        let result = try XCTUnwrap(store.latestSpeciesApplyResult)
        let appliedChange = try XCTUnwrap(result.appliedChanges.first { $0.path == "graphics/pokemon/treecko/front.png" })
        XCTAssertTrue(FileManager.default.fileExists(atPath: appliedChange.backupPath))
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent("graphics/pokemon/treecko/front.png")), importedData)
    }

    @MainActor
    func testRubySapphireSpeciesAssetImportIsBlockedBeforeStaging() async throws {
        let root = try makeRubyPokemonProject()
        let importURL = root.appendingPathComponent("incoming/front.png")
        try write(testPNGData(width: 64, height: 64, paletteColorCount: 16), to: importURL)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedSpeciesCatalogIfNeeded()
        try await waitForSelectedSpeciesCatalog(store)
        store.requestSpeciesSelection("SPECIES_TREECKO")

        XCTAssertNotNil(store.selectedSpeciesDraft)
        XCTAssertEqual(store.selectedSpeciesCatalog?.profile, .pokeruby)
        XCTAssertTrue(store.selectedSpeciesAssetImportBlockedReason(kind: .front)?.contains("base_stats.h") == true)
        XCTAssertNil(store.importSelectedSpeciesAsset(kind: .front, from: importURL))
        XCTAssertNil(store.selectedSpeciesDraft?.assetData[.front])
    }

    @MainActor
    func testRubySapphireCryAudioReplacementStagesThroughSpeciesMutationPlan() async throws {
        let root = try makeRubyPokemonProject()
        let targetPath = "sound/direct_sound_samples/cries/treecko.aif"
        let originalData = Data([0x01, 0x02, 0x03])
        let importedData = Data([0x10, 0x20, 0x30, 0x40])
        try write(originalData, to: root.appendingPathComponent(targetPath))
        let importURL = root.appendingPathComponent("incoming/treecko.aif")
        try write(importedData, to: importURL)
        let frontImportURL = root.appendingPathComponent("incoming/front.png")
        try write(testPNGData(width: 64, height: 64, paletteColorCount: 16), to: frontImportURL)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedSpeciesCatalogIfNeeded()
        try await waitForSelectedSpeciesCatalog(store)
        store.requestSpeciesSelection("SPECIES_TREECKO")

        let source = try XCTUnwrap(store.selectedSpeciesCryAudioSources.first { $0.path == targetPath })
        XCTAssertNil(store.selectedSpeciesCryAudioImportBlockedReason(source: source))
        let replacement = try XCTUnwrap(store.importSelectedSpeciesCryAudioSource(target: source, from: importURL))

        XCTAssertEqual(replacement.status, .ready)
        XCTAssertEqual(replacement.replacementSHA1, pokemonHackSHA1Hex(importedData))
        XCTAssertEqual(store.selectedSpeciesDraft?.cryAudioReplacements?[targetPath]?.data, importedData)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(targetPath)), originalData)
        XCTAssertTrue(store.selectedSpeciesAssetImportBlockedReason(kind: .front)?.contains("base_stats.h") == true)
        XCTAssertNil(store.importSelectedSpeciesAsset(kind: .front, from: frontImportURL))
        XCTAssertNil(store.selectedSpeciesDraft?.assetData[.front])

        store.previewSelectedSpeciesMutationPlan()

        let plan = try XCTUnwrap(store.latestSpeciesEditPlan)
        XCTAssertTrue(plan.isApplyable)
        XCTAssertTrue(plan.changes.contains { $0.path == targetPath })

        store.applySelectedSpeciesMutationPlan()

        let result = try XCTUnwrap(store.latestSpeciesApplyResult)
        let appliedChange = try XCTUnwrap(result.appliedChanges.first { $0.path == targetPath })
        XCTAssertTrue(FileManager.default.fileExists(atPath: appliedChange.backupPath))
        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: appliedChange.backupPath)), originalData)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(targetPath)), importedData)
    }

    @MainActor
    func testRubySapphireEvolutionDraftPreviewApplyAndReloadsThroughStore() async throws {
        let root = try makeRubyPokemonProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)
        settings.includeDefaultDebugProjects = false
        let store = WorkbenchStore(userDefaults: defaults, userSettings: settings, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedSpeciesCatalogIfNeeded()
        let catalog = try await waitForSelectedSpeciesCatalog(store)
        XCTAssertEqual(catalog.profile, .pokeruby)
        store.requestSpeciesSelection("SPECIES_TREECKO")

        var draft = try XCTUnwrap(store.selectedSpeciesDraft)
        XCTAssertEqual(draft.evolutions.first?.targetSpecies, "SPECIES_GROVYLE")
        draft.evolutions[0].parameter = "18"
        draft.evolutions[0].targetSpecies = "SPECIES_TREECKO"
        store.updateSelectedSpeciesDraft(draft)

        XCTAssertTrue(store.selectedSpeciesIsDirty)
        XCTAssertTrue(store.canPreviewSelectedSpeciesMutationPlan)
        store.previewSelectedSpeciesMutationPlan()

        let plan = try XCTUnwrap(store.latestSpeciesEditPlan)
        let diagnosticCodes = plan.diagnostics.map(\.code).joined(separator: ",")
        XCTAssertTrue(plan.isApplyable, diagnosticCodes)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/evolution.h"], diagnosticCodes)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains("EVO_LEVEL, 18, SPECIES_TREECKO") == true)
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_EVOLUTION_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertTrue(store.canApplySelectedSpeciesMutationPlan)

        store.applySelectedSpeciesMutationPlan()

        let result = try XCTUnwrap(store.latestSpeciesApplyResult)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/evolution.h"])
        XCTAssertTrue(result.appliedChanges.allSatisfy { FileManager.default.fileExists(atPath: $0.backupPath) })
        XCTAssertFalse(store.selectedSpeciesIsDirty)
        XCTAssertEqual(store.selectedSpeciesID, "SPECIES_TREECKO")

        let reloaded = try XCTUnwrap(store.selectedSpeciesCatalog?.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(reloaded.evolutions.count, 1)
        XCTAssertEqual(reloaded.evolutions.first?.method, "EVO_LEVEL")
        XCTAssertEqual(reloaded.evolutions.first?.parameter, "18")
        XCTAssertEqual(reloaded.evolutions.first?.targetSpecies, "SPECIES_TREECKO")
    }

    @MainActor
    func testRubySapphireLevelUpLearnsetDraftPreviewApplyAndReloadsThroughStore() async throws {
        let root = try makeRubyPokemonProject()
        let levelUpPath = root.appendingPathComponent("src/data/pokemon/level_up_learnsets.h")
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)
        settings.includeDefaultDebugProjects = false
        let store = WorkbenchStore(userDefaults: defaults, userSettings: settings, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedSpeciesCatalogIfNeeded()
        let catalog = try await waitForSelectedSpeciesCatalog(store)
        XCTAssertEqual(catalog.profile, .pokeruby)
        store.requestSpeciesSelection("SPECIES_TREECKO")

        let selected = try XCTUnwrap(store.selectedSpeciesDetail)
        XCTAssertEqual(selected.learnsets.levelUpSourceSpan?.relativePath, "src/data/pokemon/level_up_learnsets.h")
        XCTAssertEqual(selected.learnsets.levelUpSymbol, "gTreeckoLevelUpLearnset")
        XCTAssertEqual(selected.learnsets.levelUp.map(\.move), ["MOVE_POUND", "MOVE_ABSORB"])

        var draft = try XCTUnwrap(store.selectedSpeciesDraft)
        draft.levelUpMoves.append(SpeciesLevelUpMoveDraft(level: 9, move: "MOVE_FLASH"))
        store.updateSelectedSpeciesDraft(draft)

        XCTAssertTrue(store.selectedSpeciesIsDirty)
        XCTAssertTrue(store.canPreviewSelectedSpeciesMutationPlan)
        store.previewSelectedSpeciesMutationPlan()

        let plan = try XCTUnwrap(store.latestSpeciesEditPlan)
        let diagnosticCodes = plan.diagnostics.map(\.code).joined(separator: ",")
        XCTAssertTrue(plan.isApplyable, diagnosticCodes)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/level_up_learnsets.h"], diagnosticCodes)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains("const u16 gTreeckoLevelUpLearnset[] = {") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains("LEVEL_UP_MOVE( 9, MOVE_FLASH),") == true)
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_LEVEL_UP_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertTrue(store.canApplySelectedSpeciesMutationPlan)

        store.applySelectedSpeciesMutationPlan()

        let result = try XCTUnwrap(store.latestSpeciesApplyResult)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/level_up_learnsets.h"])
        XCTAssertTrue(result.appliedChanges.allSatisfy { FileManager.default.fileExists(atPath: $0.backupPath) })
        XCTAssertFalse(store.selectedSpeciesIsDirty)
        XCTAssertEqual(store.selectedSpeciesID, "SPECIES_TREECKO")

        let source = try String(contentsOf: levelUpPath, encoding: .utf8)
        XCTAssertTrue(source.contains("const u16 gTreeckoLevelUpLearnset[] = {"))
        XCTAssertTrue(source.contains("LEVEL_UP_MOVE( 9, MOVE_FLASH),"))
        let reloaded = try XCTUnwrap(store.selectedSpeciesCatalog?.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(reloaded.learnsets.levelUp.map(\.move), ["MOVE_POUND", "MOVE_ABSORB", "MOVE_FLASH"])
        XCTAssertEqual(reloaded.learnsets.levelUp.map(\.level), [1, 6, 9])
    }

    @MainActor
    func testRubySapphireMoveCompatibilityTMHMBatchPreviewApplyAndReloadsThroughMovesStore() async throws {
        let root = try makeRubyPokemonProject()
        try writeRubyBattleMoveTable(to: root)
        let tmhmPath = root.appendingPathComponent("src/data/pokemon/tmhm_learnsets.h")
        try write("#define ITEM_NONE 0\n#define ITEM_TM01_POUND 1\n", to: root.appendingPathComponent("include/constants/items.h"))
        try write(
            """
            static const u32 gTMHMLearnsets[] =
            {
                [SPECIES_TREECKO] = TMHM(TM01_POUND),
            };

            """,
            to: tmhmPath
        )
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)
        settings.includeDefaultDebugProjects = false
        let store = WorkbenchStore(userDefaults: defaults, userSettings: settings, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selection = .moves
        store.loadSelectedSpeciesCatalogIfNeeded()
        let catalog = try await waitForSelectedSpeciesCatalog(store)
        XCTAssertEqual(catalog.profile, .pokeruby)

        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(treecko.learnsets.tmhmSourceSpan?.relativePath, "src/data/pokemon/tmhm_learnsets.h")
        XCTAssertEqual(treecko.learnsets.tmhm.map(\.move), ["MOVE_POUND"])
        XCTAssertTrue(store.speciesCompatibilityValue(speciesID: "SPECIES_TREECKO", moveID: "MOVE_POUND", bucket: .tmhm))

        store.setSpeciesCompatibility(speciesID: "SPECIES_TREECKO", moveID: "MOVE_POUND", bucket: .tmhm, isEnabled: false)

        XCTAssertEqual(store.dirtySpeciesBatchDrafts.map(\.speciesID), ["SPECIES_TREECKO"])
        XCTAssertEqual(store.toolbarMutationState.target, .pokemonBatch)
        XCTAssertTrue(store.toolbarMutationState.canPreview)

        store.previewToolbarMutationTarget()

        let plan = try XCTUnwrap(store.latestSpeciesBatchEditPlans.first)
        let diagnosticCodes = plan.diagnostics.map(\.code).joined(separator: ",")
        XCTAssertEqual(store.latestSpeciesBatchEditPlans.count, 1)
        XCTAssertTrue(plan.isApplyable, diagnosticCodes)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/tmhm_learnsets.h"], diagnosticCodes)
        XCTAssertFalse(plan.changes.first?.textPreview?.contains("TM01_POUND") == true)
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_TMHM_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertTrue(store.toolbarMutationState.canApply)

        store.applyToolbarMutationTarget()

        let result = try XCTUnwrap(store.latestSpeciesBatchApplyResult)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/tmhm_learnsets.h"])
        XCTAssertTrue(result.appliedChanges.allSatisfy { FileManager.default.fileExists(atPath: $0.backupPath) })
        XCTAssertTrue(store.dirtySpeciesBatchDrafts.isEmpty)

        let source = try String(contentsOf: tmhmPath, encoding: .utf8)
        XCTAssertFalse(source.contains("TM01_POUND"))
        let reloaded = try XCTUnwrap(store.selectedSpeciesCatalog?.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertTrue(reloaded.learnsets.tmhm.isEmpty)
    }

    @MainActor
    func testRubySapphireMoveCompatibilityTutorBatchPreviewApplyAndReloadsThroughMovesStore() async throws {
        let root = try makeRubyPokemonProject()
        try writeRubyBattleMoveTable(to: root)
        let tutorPath = root.appendingPathComponent("src/data/pokemon/tutor_learnsets.h")
        try write(
            """
            #define TUTOR_MEGA_PUNCH 0
            #define TUTOR_SWORD_DANCE 1
            #define TUTOR_FURY_CUTTER 2

            const u16 sTutorLearnsets[] =
            {
                [SPECIES_TREECKO] = (TUTOR(MEGA_PUNCH) | TUTOR(SWORD_DANCE)),
            };

            """,
            to: tutorPath
        )
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)
        settings.includeDefaultDebugProjects = false
        let store = WorkbenchStore(userDefaults: defaults, userSettings: settings, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selection = .moves
        store.loadSelectedSpeciesCatalogIfNeeded()
        let catalog = try await waitForSelectedSpeciesCatalog(store)
        XCTAssertEqual(catalog.profile, .pokeruby)

        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(treecko.learnsets.tutorSourceSpan?.relativePath, "src/data/pokemon/tutor_learnsets.h")
        XCTAssertEqual(treecko.learnsets.tutor.map(\.move).sorted(), ["MOVE_MEGA_PUNCH", "MOVE_SWORD_DANCE"])
        XCTAssertTrue(store.speciesCompatibilityValue(speciesID: "SPECIES_TREECKO", moveID: "MOVE_MEGA_PUNCH", bucket: .tutor))
        XCTAssertFalse(store.speciesCompatibilityValue(speciesID: "SPECIES_TREECKO", moveID: "MOVE_FURY_CUTTER", bucket: .tutor))

        store.setSpeciesCompatibility(speciesID: "SPECIES_TREECKO", moveID: "MOVE_MEGA_PUNCH", bucket: .tutor, isEnabled: false)
        store.setSpeciesCompatibility(speciesID: "SPECIES_TREECKO", moveID: "MOVE_FURY_CUTTER", bucket: .tutor, isEnabled: true)

        XCTAssertEqual(store.dirtySpeciesBatchDrafts.map(\.speciesID), ["SPECIES_TREECKO"])
        XCTAssertEqual(store.toolbarMutationState.target, .pokemonBatch)
        XCTAssertTrue(store.toolbarMutationState.canPreview)

        store.previewToolbarMutationTarget()

        let plan = try XCTUnwrap(store.latestSpeciesBatchEditPlans.first)
        let diagnosticCodes = plan.diagnostics.map(\.code).joined(separator: ",")
        XCTAssertEqual(store.latestSpeciesBatchEditPlans.count, 1)
        XCTAssertTrue(plan.isApplyable, diagnosticCodes)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/tutor_learnsets.h"], diagnosticCodes)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains("TUTOR(FURY_CUTTER)") == true)
        XCTAssertFalse(plan.changes.first?.textPreview?.contains("TUTOR(MEGA_PUNCH)") == true)
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_TUTOR_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertTrue(store.toolbarMutationState.canApply)

        store.applyToolbarMutationTarget()

        let result = try XCTUnwrap(store.latestSpeciesBatchApplyResult)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/tutor_learnsets.h"])
        XCTAssertTrue(result.appliedChanges.allSatisfy { FileManager.default.fileExists(atPath: $0.backupPath) })
        XCTAssertTrue(store.dirtySpeciesBatchDrafts.isEmpty)

        let source = try String(contentsOf: tutorPath, encoding: .utf8)
        XCTAssertTrue(source.contains("TUTOR(FURY_CUTTER)"))
        XCTAssertFalse(source.contains("TUTOR(MEGA_PUNCH)"))
        let reloaded = try XCTUnwrap(store.selectedSpeciesCatalog?.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(reloaded.learnsets.tutor.map(\.move).sorted(), ["MOVE_FURY_CUTTER", "MOVE_SWORD_DANCE"])
        XCTAssertTrue(store.speciesCompatibilityValue(speciesID: "SPECIES_TREECKO", moveID: "MOVE_FURY_CUTTER", bucket: .tutor))
        XCTAssertFalse(store.speciesCompatibilityValue(speciesID: "SPECIES_TREECKO", moveID: "MOVE_MEGA_PUNCH", bucket: .tutor))
    }

    @MainActor
    func testRubySapphireMoveCompatibilityEggBatchPreviewApplyAndReloadsThroughMovesStore() async throws {
        let root = try makeRubyPokemonProject()
        try writeRubyBattleMoveTable(to: root)
        let eggPath = root.appendingPathComponent("src/data/pokemon/egg_moves.h")
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)
        settings.includeDefaultDebugProjects = false
        let store = WorkbenchStore(userDefaults: defaults, userSettings: settings, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selection = .moves
        store.loadSelectedSpeciesCatalogIfNeeded()
        let catalog = try await waitForSelectedSpeciesCatalog(store)
        XCTAssertEqual(catalog.profile, .pokeruby)

        let treecko = try XCTUnwrap(catalog.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(treecko.learnsets.eggSourceSpan?.relativePath, "src/data/pokemon/egg_moves.h")
        XCTAssertEqual(treecko.learnsets.egg.map(\.move), ["MOVE_CRUNCH", "MOVE_LEECH_SEED"])
        XCTAssertFalse(store.speciesCompatibilityValue(speciesID: "SPECIES_TREECKO", moveID: "MOVE_POUND", bucket: .egg))

        store.setSpeciesCompatibility(speciesID: "SPECIES_TREECKO", moveID: "MOVE_POUND", bucket: .egg, isEnabled: true)

        XCTAssertEqual(store.dirtySpeciesBatchDrafts.map(\.speciesID), ["SPECIES_TREECKO"])
        XCTAssertEqual(store.toolbarMutationState.target, .pokemonBatch)
        XCTAssertTrue(store.toolbarMutationState.canPreview)

        store.previewToolbarMutationTarget()

        let plan = try XCTUnwrap(store.latestSpeciesBatchEditPlans.first)
        let diagnosticCodes = plan.diagnostics.map(\.code).joined(separator: ",")
        XCTAssertEqual(store.latestSpeciesBatchEditPlans.count, 1)
        XCTAssertTrue(plan.isApplyable, diagnosticCodes)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/egg_moves.h"], diagnosticCodes)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains("egg_moves(TREECKO,") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains("MOVE_POUND") == true)
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_EGG_MOVES_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_EGG_MOVES_SPAN_MISSING" })
        XCTAssertTrue(store.toolbarMutationState.canApply)

        store.applyToolbarMutationTarget()

        let result = try XCTUnwrap(store.latestSpeciesBatchApplyResult)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/egg_moves.h"])
        XCTAssertTrue(result.appliedChanges.allSatisfy { FileManager.default.fileExists(atPath: $0.backupPath) })
        XCTAssertTrue(store.dirtySpeciesBatchDrafts.isEmpty)

        let source = try String(contentsOf: eggPath, encoding: .utf8)
        XCTAssertTrue(source.contains("MOVE_CRUNCH,\n              MOVE_LEECH_SEED,\n              MOVE_POUND"))
        let reloaded = try XCTUnwrap(store.selectedSpeciesCatalog?.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(reloaded.learnsets.egg.map(\.move), ["MOVE_CRUNCH", "MOVE_LEECH_SEED", "MOVE_POUND"])
        XCTAssertTrue(store.speciesCompatibilityValue(speciesID: "SPECIES_TREECKO", moveID: "MOVE_POUND", bucket: .egg))
    }

    @MainActor
    func testRubySapphireEggMoveDraftPreviewApplyAndReloadsThroughPokemonEditor() async throws {
        let root = try makeRubyPokemonProject()
        let eggPath = root.appendingPathComponent("src/data/pokemon/egg_moves.h")
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)
        settings.includeDefaultDebugProjects = false
        let store = WorkbenchStore(userDefaults: defaults, userSettings: settings, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedSpeciesCatalogIfNeeded()
        let catalog = try await waitForSelectedSpeciesCatalog(store)
        XCTAssertEqual(catalog.profile, .pokeruby)
        store.requestSpeciesSelection("SPECIES_TREECKO")

        let selected = try XCTUnwrap(store.selectedSpeciesDetail)
        XCTAssertEqual(selected.learnsets.eggSourceSpan?.relativePath, "src/data/pokemon/egg_moves.h")
        XCTAssertEqual(selected.learnsets.egg.map(\.move), ["MOVE_CRUNCH", "MOVE_LEECH_SEED"])

        var draft = try XCTUnwrap(store.selectedSpeciesDraft)
        draft.eggMoves = ["MOVE_LEECH_SEED", "MOVE_FLASH", "MOVE_CRUNCH"]
        store.updateSelectedSpeciesDraft(draft)

        XCTAssertTrue(store.selectedSpeciesIsDirty)
        XCTAssertTrue(store.canPreviewSelectedSpeciesMutationPlan)
        store.previewSelectedSpeciesMutationPlan()

        let plan = try XCTUnwrap(store.latestSpeciesEditPlan)
        let diagnosticCodes = plan.diagnostics.map(\.code).joined(separator: ",")
        XCTAssertTrue(plan.isApplyable, diagnosticCodes)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/egg_moves.h"], diagnosticCodes)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains("egg_moves(TREECKO,") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains("MOVE_FLASH") == true)
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_EGG_MOVES_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertTrue(store.canApplySelectedSpeciesMutationPlan)

        store.applySelectedSpeciesMutationPlan()

        let result = try XCTUnwrap(store.latestSpeciesApplyResult)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/egg_moves.h"])
        XCTAssertTrue(result.appliedChanges.allSatisfy { FileManager.default.fileExists(atPath: $0.backupPath) })
        XCTAssertFalse(store.selectedSpeciesIsDirty)
        XCTAssertEqual(store.selectedSpeciesID, "SPECIES_TREECKO")

        let source = try String(contentsOf: eggPath, encoding: .utf8)
        XCTAssertTrue(source.contains("egg_moves(TREECKO,"))
        XCTAssertTrue(source.contains("MOVE_FLASH"))
        XCTAssertTrue(source.contains("egg_moves(GROVYLE,"))
        let reloaded = try XCTUnwrap(store.selectedSpeciesCatalog?.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(reloaded.learnsets.egg.map(\.move), ["MOVE_LEECH_SEED", "MOVE_FLASH", "MOVE_CRUNCH"])
    }

    @MainActor
    func testExpansionSpeciesInfoScalarEditsFlowThroughPokemonEditor() async throws {
        let root = try makeExpansionPokemonProject()
        let familyPath = root.appendingPathComponent("src/data/pokemon/species_info/gen_3_families.h")
        let originalFamilyText = try String(contentsOf: familyPath, encoding: .utf8)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedSpeciesCatalogIfNeeded()
        let catalog = try await waitForSelectedSpeciesCatalog(store)
        XCTAssertEqual(catalog.profile, .pokeemeraldExpansion)
        XCTAssertTrue(catalog.species.map(\.sourceSpan.relativePath).allSatisfy { $0 == "src/data/pokemon/species_info.h" })
        XCTAssertTrue(catalog.species.contains { $0.speciesID == "SPECIES_TREECKO" })
        store.requestSpeciesSelection("SPECIES_TREECKO")

        var draft = try XCTUnwrap(store.selectedSpeciesDraft)
        draft.baseStats.hp = 41
        draft.types[1] = "TYPE_FIRE"
        draft.abilities[1] = "ABILITY_CHLOROPHYLL"
        draft.expYield = "66"
        draft.itemCommon = "ITEM_POTION"
        draft.eggGroups[1] = "EGG_GROUP_MONSTER"
        draft.bodyColor = "BODY_COLOR_RED"
        draft.noFlip = true
        store.updateSelectedSpeciesDraft(draft)

        XCTAssertTrue(store.canPreviewSelectedSpeciesMutationPlan)
        store.previewSelectedSpeciesMutationPlan()

        let plan = try XCTUnwrap(store.latestSpeciesEditPlan)
        let diagnosticCodes = plan.diagnostics.map(\.code).joined(separator: ",")
        XCTAssertTrue(plan.isApplyable, diagnosticCodes)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/species_info.h"], diagnosticCodes)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".baseHP = 41") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".type2 = TYPE_FIRE") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".baseExp = 66") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".ability2 = ABILITY_CHLOROPHYLL") == true)
        XCTAssertTrue(store.canApplySelectedSpeciesMutationPlan)

        store.applySelectedSpeciesMutationPlan()

        let result = try XCTUnwrap(store.latestSpeciesApplyResult)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/species_info.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))
        XCTAssertEqual(try String(contentsOf: familyPath, encoding: .utf8), originalFamilyText)
        let source = try String(contentsOf: root.appendingPathComponent("src/data/pokemon/species_info.h"), encoding: .utf8)
        XCTAssertTrue(source.contains(".baseHP = 41"))
        XCTAssertTrue(source.contains(".type2 = TYPE_FIRE"))
        XCTAssertTrue(source.contains(".baseExp = 66"))
        XCTAssertTrue(source.contains(".item1 = ITEM_POTION"))
        XCTAssertTrue(source.contains(".ability2 = ABILITY_CHLOROPHYLL"))
        XCTAssertTrue(source.contains(".hiddenAbility = ABILITY_CHLOROPHYLL"))
        XCTAssertTrue(source.contains(".formSpeciesIdTable = sTreeckoFormSpeciesIdTable"))

        let reloaded = try XCTUnwrap(store.selectedSpeciesCatalog?.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(store.selectedSpeciesID, "SPECIES_TREECKO")
        XCTAssertEqual(reloaded.baseStats.hp, 41)
        XCTAssertEqual(reloaded.types, ["TYPE_GRASS", "TYPE_FIRE"])
        XCTAssertEqual(reloaded.abilities, ["ABILITY_OVERGROW", "ABILITY_CHLOROPHYLL", "ABILITY_CHLOROPHYLL"])
        XCTAssertEqual(reloaded.training.expYield, "66")
        XCTAssertEqual(reloaded.heldItems.common, "ITEM_POTION")
        XCTAssertEqual(reloaded.bodyColor, "BODY_COLOR_RED")
        XCTAssertEqual(reloaded.noFlip, "TRUE")

        store.loadSelectedSourceGraphIfNeeded()
        let sourceIndex = try await waitForSelectedSourceGraph(store)
        XCTAssertTrue(sourceIndex.records.contains { record in
            record.sourceSpan.relativePath == "src/data/pokemon/species_info/gen_3_families.h"
                && record.tags.contains("form-supplement")
                && record.tags.contains("read-only")
        })

        var blockedDraft = try XCTUnwrap(store.selectedSpeciesDraft)
        blockedDraft.assetData[.front] = testPNGData(width: 64, height: 64, paletteColorCount: 16)
        store.updateSelectedSpeciesDraft(blockedDraft)
        store.previewSelectedSpeciesMutationPlan()

        let blockedPlan = try XCTUnwrap(store.latestSpeciesEditPlan)
        XCTAssertEqual(blockedPlan.changes.count, 0)
        XCTAssertFalse(blockedPlan.isApplyable)
        XCTAssertTrue(blockedPlan.diagnostics.contains { $0.code == "SPECIES_ASSET_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertFalse(store.canApplySelectedSpeciesMutationPlan)
    }

    @MainActor
    func testExpansionSpeciesPokedexEditsFlowThroughPokemonEditor() async throws {
        let root = try makeExpansionPokemonProject()
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
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedSpeciesCatalogIfNeeded()
        let catalog = try await waitForSelectedSpeciesCatalog(store)
        XCTAssertEqual(catalog.profile, .pokeemeraldExpansion)
        store.requestSpeciesSelection("SPECIES_TREECKO")

        let selected = try XCTUnwrap(store.selectedSpeciesDetail)
        XCTAssertEqual(selected.pokedex?.sourceSpan.relativePath, "src/data/pokemon/pokedex_entries.h")
        XCTAssertEqual(selected.pokedex?.descriptionSpan?.relativePath, "src/data/pokemon/pokedex_text.h")
        XCTAssertEqual(selected.pokedex?.height, "5")
        XCTAssertEqual(selected.pokedex?.description, "Wood gecko.")

        var draft = try XCTUnwrap(store.selectedSpeciesDraft)
        draft.pokedex?.height = "6"
        draft.pokedex?.categoryName = "EXPANSION GECKO"
        draft.pokedex?.description = "Expansion Pokedex text."
        store.updateSelectedSpeciesDraft(draft)

        XCTAssertTrue(store.canPreviewSelectedSpeciesMutationPlan)
        store.previewSelectedSpeciesMutationPlan()

        let plan = try XCTUnwrap(store.latestSpeciesEditPlan)
        let diagnosticCodes = plan.diagnostics.map(\.code).joined(separator: ",")
        XCTAssertTrue(plan.isApplyable, diagnosticCodes)
        XCTAssertEqual(plan.changes.map(\.path).sorted(), [
            "src/data/pokemon/pokedex_entries.h",
            "src/data/pokemon/pokedex_text.h"
        ], diagnosticCodes)
        XCTAssertTrue(plan.changes.first { $0.path == "src/data/pokemon/pokedex_entries.h" }?.textPreview?.contains(".height = 6") == true)
        XCTAssertTrue(plan.changes.first { $0.path == "src/data/pokemon/pokedex_text.h" }?.textPreview?.contains("Expansion Pokedex text.") == true)
        XCTAssertTrue(store.canApplySelectedSpeciesMutationPlan)

        store.applySelectedSpeciesMutationPlan()

        let result = try XCTUnwrap(store.latestSpeciesApplyResult)
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
        XCTAssertTrue(try String(contentsOf: textPath, encoding: .utf8).contains("Expansion Pokedex text."))
        XCTAssertFalse(store.selectedSpeciesIsDirty)
        XCTAssertEqual(store.selectedSpeciesID, "SPECIES_TREECKO")
        let reloaded = try XCTUnwrap(store.selectedSpeciesCatalog?.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(reloaded.pokedex?.height, "6")
        XCTAssertEqual(reloaded.pokedex?.categoryName, "EXPANSION GECKO")
        XCTAssertEqual(reloaded.pokedex?.description, "Expansion Pokedex text.")
    }

    @MainActor
    func testExpansionFormTableEditsFlowThroughPokemonEditor() async throws {
        let root = try makeExpansionPokemonProject()
        let formSpeciesPath = root.appendingPathComponent("src/data/pokemon/form_species_tables.h")
        let formChangePath = root.appendingPathComponent("src/data/pokemon/form_change_tables.h")
        let familyPath = root.appendingPathComponent("src/data/pokemon/species_info/gen_3_families.h")
        let generatedPath = root.appendingPathComponent("generated/species/forms.json")
        let referencePath = root.appendingPathComponent("references/pokeemerald-expansion/src/data/pokemon/form_species_tables.h")
        let romPath = root.appendingPathComponent("build/pokeemerald.gba")
        try write("{\"forms\":[]}\n", to: generatedPath)
        try write("// reference form species\n", to: referencePath)
        try write(Data([0x47, 0x42, 0x41]), to: romPath)
        let originalFamilyText = try String(contentsOf: familyPath, encoding: .utf8)
        let originalGeneratedText = try String(contentsOf: generatedPath, encoding: .utf8)
        let originalReferenceText = try String(contentsOf: referencePath, encoding: .utf8)
        let originalROMData = try Data(contentsOf: romPath)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedSpeciesCatalogIfNeeded()
        let catalog = try await waitForSelectedSpeciesCatalog(store)
        XCTAssertEqual(catalog.profile, .pokeemeraldExpansion)
        store.requestSpeciesSelection("SPECIES_TREECKO")

        let selected = try XCTUnwrap(store.selectedSpeciesDetail)
        XCTAssertEqual(selected.forms.formSpeciesSourceSpan?.relativePath, "src/data/pokemon/form_species_tables.h")
        XCTAssertEqual(selected.forms.formChangeSourceSpan?.relativePath, "src/data/pokemon/form_change_tables.h")
        XCTAssertEqual(selected.forms.species.map(\.speciesID), ["SPECIES_TREECKO", "SPECIES_TREECKO_MEGA"])
        XCTAssertEqual(selected.forms.changes.map(\.method), ["FORM_CHANGE_BATTLE_MEGA_EVOLUTION"])

        var draft = try XCTUnwrap(store.selectedSpeciesDraft)
        draft.formSpecies[1].speciesID = "SPECIES_TREECKO_PRIMAL"
        draft.formChanges[0].method = "FORM_CHANGE_ITEM_HOLD"
        draft.formChanges[0].targetSpecies = "SPECIES_TREECKO_PRIMAL"
        store.updateSelectedSpeciesDraft(draft)

        XCTAssertTrue(store.canPreviewSelectedSpeciesMutationPlan)
        store.previewSelectedSpeciesMutationPlan()

        let plan = try XCTUnwrap(store.latestSpeciesEditPlan)
        let diagnosticCodes = plan.diagnostics.map(\.code).joined(separator: ",")
        XCTAssertTrue(plan.isApplyable, diagnosticCodes)
        XCTAssertEqual(plan.changes.map(\.path).sorted(), [
            "src/data/pokemon/form_change_tables.h",
            "src/data/pokemon/form_species_tables.h"
        ], diagnosticCodes)
        XCTAssertTrue(plan.changes.first { $0.path == "src/data/pokemon/form_species_tables.h" }?.textPreview?.contains("SPECIES_TREECKO_PRIMAL") == true)
        XCTAssertTrue(plan.changes.first { $0.path == "src/data/pokemon/form_change_tables.h" }?.textPreview?.contains("{ FORM_CHANGE_ITEM_HOLD, SPECIES_TREECKO_PRIMAL },") == true)
        XCTAssertTrue(store.canApplySelectedSpeciesMutationPlan)

        store.applySelectedSpeciesMutationPlan()

        let result = try XCTUnwrap(store.latestSpeciesApplyResult)
        XCTAssertEqual(result.appliedChanges.map(\.path).sorted(), [
            "src/data/pokemon/form_change_tables.h",
            "src/data/pokemon/form_species_tables.h"
        ])
        XCTAssertTrue(result.appliedChanges.allSatisfy { FileManager.default.fileExists(atPath: $0.backupPath) })
        XCTAssertEqual(try String(contentsOf: familyPath, encoding: .utf8), originalFamilyText)
        XCTAssertEqual(try String(contentsOf: generatedPath, encoding: .utf8), originalGeneratedText)
        XCTAssertEqual(try String(contentsOf: referencePath, encoding: .utf8), originalReferenceText)
        XCTAssertEqual(try Data(contentsOf: romPath), originalROMData)
        XCTAssertFalse(store.selectedSpeciesIsDirty)
        XCTAssertEqual(store.selectedSpeciesID, "SPECIES_TREECKO")

        let formSpeciesSource = try String(contentsOf: formSpeciesPath, encoding: .utf8)
        let formChangeSource = try String(contentsOf: formChangePath, encoding: .utf8)
        XCTAssertTrue(formSpeciesSource.contains("SPECIES_TREECKO_PRIMAL"))
        XCTAssertTrue(formChangeSource.contains("{ FORM_CHANGE_ITEM_HOLD, SPECIES_TREECKO_PRIMAL },"))
        let reloaded = try XCTUnwrap(store.selectedSpeciesCatalog?.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(reloaded.forms.species.map(\.speciesID), ["SPECIES_TREECKO", "SPECIES_TREECKO_PRIMAL"])
        XCTAssertEqual(reloaded.forms.changes.map(\.method), ["FORM_CHANGE_ITEM_HOLD"])
        XCTAssertEqual(reloaded.forms.changes.map(\.targetSpecies), ["SPECIES_TREECKO_PRIMAL"])
    }

    @MainActor
    func testExpansionSpeciesEvolutionEditsFlowThroughPokemonEditor() async throws {
        let root = try makeExpansionPokemonProject(includeEvolutionRows: true)
        let evolutionPath = root.appendingPathComponent("src/data/pokemon/evolution.h")
        let familyPath = root.appendingPathComponent("src/data/pokemon/species_info/gen_3_families.h")
        let generatedPath = root.appendingPathComponent("generated/species/evolutions.json")
        let referencePath = root.appendingPathComponent("references/pokeemerald-expansion/src/data/pokemon/evolution.h")
        let romPath = root.appendingPathComponent("build/pokeemerald.gba")
        try write("{\"evolutions\":[]}\n", to: generatedPath)
        try write("// reference evolution table\n", to: referencePath)
        try write(Data([0x47, 0x42, 0x41]), to: romPath)
        let originalFamilyText = try String(contentsOf: familyPath, encoding: .utf8)
        let originalGeneratedText = try String(contentsOf: generatedPath, encoding: .utf8)
        let originalReferenceText = try String(contentsOf: referencePath, encoding: .utf8)
        let originalROMData = try Data(contentsOf: romPath)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedSpeciesCatalogIfNeeded()
        let catalog = try await waitForSelectedSpeciesCatalog(store)
        XCTAssertEqual(catalog.profile, .pokeemeraldExpansion)
        store.requestSpeciesSelection("SPECIES_TREECKO")

        let selected = try XCTUnwrap(store.selectedSpeciesDetail)
        XCTAssertEqual(selected.evolutions.map(\.method), ["EVO_LEVEL", "EVO_ITEM"])
        XCTAssertEqual(selected.evolutions.map(\.parameter), ["16", "ITEM_POTION"])
        XCTAssertEqual(selected.evolutions.map(\.targetSpecies), ["SPECIES_GROVYLE", "SPECIES_TREECKO_MEGA"])
        XCTAssertEqual(selected.evolutions.first?.sourceSpan.relativePath, "src/data/pokemon/evolution.h")

        var draft = try XCTUnwrap(store.selectedSpeciesDraft)
        draft.evolutions[0].method = "EVO_ITEM"
        draft.evolutions[0].parameter = "ITEM_POTION"
        draft.evolutions[0].targetSpecies = "SPECIES_TREECKO_PRIMAL"
        draft.evolutions[1].method = "EVO_LEVEL"
        draft.evolutions[1].parameter = "20"
        draft.evolutions[1].targetSpecies = "SPECIES_GROVYLE"
        store.updateSelectedSpeciesDraft(draft)

        XCTAssertTrue(store.canPreviewSelectedSpeciesMutationPlan)
        store.previewSelectedSpeciesMutationPlan()

        let plan = try XCTUnwrap(store.latestSpeciesEditPlan)
        let diagnosticCodes = plan.diagnostics.map(\.code).joined(separator: ",")
        XCTAssertTrue(plan.isApplyable, diagnosticCodes)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/evolution.h"], diagnosticCodes)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains("{ EVO_ITEM, ITEM_POTION, SPECIES_TREECKO_PRIMAL },") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains("{ EVO_LEVEL, 20, SPECIES_GROVYLE }") == true)
        XCTAssertTrue(store.canApplySelectedSpeciesMutationPlan)

        store.applySelectedSpeciesMutationPlan()

        let result = try XCTUnwrap(store.latestSpeciesApplyResult)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/evolution.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))
        XCTAssertEqual(try String(contentsOf: familyPath, encoding: .utf8), originalFamilyText)
        XCTAssertEqual(try String(contentsOf: generatedPath, encoding: .utf8), originalGeneratedText)
        XCTAssertEqual(try String(contentsOf: referencePath, encoding: .utf8), originalReferenceText)
        XCTAssertEqual(try Data(contentsOf: romPath), originalROMData)
        XCTAssertFalse(store.selectedSpeciesIsDirty)
        XCTAssertEqual(store.selectedSpeciesID, "SPECIES_TREECKO")

        let source = try String(contentsOf: evolutionPath, encoding: .utf8)
        XCTAssertTrue(source.contains("{ EVO_ITEM, ITEM_POTION, SPECIES_TREECKO_PRIMAL },"))
        XCTAssertTrue(source.contains("{ EVO_LEVEL, 20, SPECIES_GROVYLE }"))
        let reloaded = try XCTUnwrap(store.selectedSpeciesCatalog?.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(reloaded.evolutions.map(\.method), ["EVO_ITEM", "EVO_LEVEL"])
        XCTAssertEqual(reloaded.evolutions.map(\.parameter), ["ITEM_POTION", "20"])
        XCTAssertEqual(reloaded.evolutions.map(\.targetSpecies), ["SPECIES_TREECKO_PRIMAL", "SPECIES_GROVYLE"])
    }

    @MainActor
    func testExpansionSpeciesLevelUpLearnsetEditsFlowThroughPokemonEditor() async throws {
        let root = try makeExpansionPokemonProject(includeLevelUpLearnsets: true)
        let levelUpPath = root.appendingPathComponent("src/data/pokemon/level_up_learnsets/treecko.h")
        let familyPath = root.appendingPathComponent("src/data/pokemon/species_info/gen_3_families.h")
        let allLearnablesPath = root.appendingPathComponent("src/data/pokemon/all_learnables.json")
        let originalFamilyText = try String(contentsOf: familyPath, encoding: .utf8)
        let originalAllLearnablesText = try String(contentsOf: allLearnablesPath, encoding: .utf8)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedSpeciesCatalogIfNeeded()
        let catalog = try await waitForSelectedSpeciesCatalog(store)
        XCTAssertEqual(catalog.profile, .pokeemeraldExpansion)
        store.requestSpeciesSelection("SPECIES_TREECKO")

        let selected = try XCTUnwrap(store.selectedSpeciesDetail)
        XCTAssertEqual(selected.learnsets.levelUpSourceSpan?.relativePath, "src/data/pokemon/level_up_learnsets/treecko.h")
        XCTAssertEqual(selected.learnsets.levelUp.map(\.move), ["MOVE_POUND", "MOVE_ABSORB"])

        var draft = try XCTUnwrap(store.selectedSpeciesDraft)
        draft.levelUpMoves.append(SpeciesLevelUpMoveDraft(level: 9, move: "MOVE_FLASH"))
        store.updateSelectedSpeciesDraft(draft)

        XCTAssertTrue(store.canPreviewSelectedSpeciesMutationPlan)
        store.previewSelectedSpeciesMutationPlan()

        let plan = try XCTUnwrap(store.latestSpeciesEditPlan)
        let diagnosticCodes = plan.diagnostics.map(\.code).joined(separator: ",")
        XCTAssertTrue(plan.isApplyable, diagnosticCodes)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/level_up_learnsets/treecko.h"], diagnosticCodes)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains("LEVEL_UP_MOVE( 9, MOVE_FLASH),") == true)
        XCTAssertTrue(store.canApplySelectedSpeciesMutationPlan)

        store.applySelectedSpeciesMutationPlan()

        let result = try XCTUnwrap(store.latestSpeciesApplyResult)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/level_up_learnsets/treecko.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))
        XCTAssertEqual(try String(contentsOf: familyPath, encoding: .utf8), originalFamilyText)
        XCTAssertEqual(try String(contentsOf: allLearnablesPath, encoding: .utf8), originalAllLearnablesText)

        let source = try String(contentsOf: levelUpPath, encoding: .utf8)
        XCTAssertTrue(source.contains("LEVEL_UP_MOVE( 9, MOVE_FLASH),"))
        let reloaded = try XCTUnwrap(store.selectedSpeciesCatalog?.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(reloaded.learnsets.levelUp.map(\.move), ["MOVE_POUND", "MOVE_ABSORB", "MOVE_FLASH"])
        XCTAssertEqual(reloaded.learnsets.levelUp.map(\.level), [1, 6, 9])
    }

    @MainActor
    func testExpansionSpeciesTMHMLearnsetEditsFlowThroughPokemonEditor() async throws {
        let root = try makeExpansionPokemonProject(includeTMHMLearnsets: true)
        let tmhmPath = root.appendingPathComponent("src/data/pokemon/tmhm_learnsets.h")
        let familyPath = root.appendingPathComponent("src/data/pokemon/species_info/gen_3_families.h")
        let allLearnablesPath = root.appendingPathComponent("src/data/pokemon/all_learnables.json")
        let originalFamilyText = try String(contentsOf: familyPath, encoding: .utf8)
        let originalAllLearnablesText = try String(contentsOf: allLearnablesPath, encoding: .utf8)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedSpeciesCatalogIfNeeded()
        let catalog = try await waitForSelectedSpeciesCatalog(store)
        XCTAssertEqual(catalog.profile, .pokeemeraldExpansion)
        store.requestSpeciesSelection("SPECIES_TREECKO")

        let selected = try XCTUnwrap(store.selectedSpeciesDetail)
        XCTAssertEqual(selected.learnsets.tmhmSourceSpan?.relativePath, "src/data/pokemon/tmhm_learnsets.h")
        XCTAssertEqual(selected.learnsets.tmhm.map(\.move), ["MOVE_BULLET_SEED", "MOVE_CUT"])

        var draft = try XCTUnwrap(store.selectedSpeciesDraft)
        draft.tmhmMoves.removeAll { $0 == "MOVE_CUT" }
        draft.tmhmMoves.append("MOVE_FLASH")
        store.updateSelectedSpeciesDraft(draft)

        XCTAssertTrue(store.canPreviewSelectedSpeciesMutationPlan)
        store.previewSelectedSpeciesMutationPlan()

        let plan = try XCTUnwrap(store.latestSpeciesEditPlan)
        let diagnosticCodes = plan.diagnostics.map(\.code).joined(separator: ",")
        XCTAssertTrue(plan.isApplyable, diagnosticCodes)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/tmhm_learnsets.h"], diagnosticCodes)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains(".FLASH = TRUE") == true)
        XCTAssertFalse(plan.changes.first?.textPreview?.contains(".CUT = TRUE") == true)
        XCTAssertTrue(store.canApplySelectedSpeciesMutationPlan)

        store.applySelectedSpeciesMutationPlan()

        let result = try XCTUnwrap(store.latestSpeciesApplyResult)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/tmhm_learnsets.h"])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges.first?.backupPath ?? ""))
        XCTAssertEqual(try String(contentsOf: familyPath, encoding: .utf8), originalFamilyText)
        XCTAssertEqual(try String(contentsOf: allLearnablesPath, encoding: .utf8), originalAllLearnablesText)

        let source = try String(contentsOf: tmhmPath, encoding: .utf8)
        XCTAssertTrue(source.contains(".FLASH = TRUE"))
        XCTAssertFalse(source.contains(".CUT = TRUE"))
        let reloaded = try XCTUnwrap(store.selectedSpeciesCatalog?.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(reloaded.learnsets.tmhm.map(\.move), ["MOVE_BULLET_SEED", "MOVE_FLASH"])
    }

    @MainActor
    func testExpansionSpeciesTutorLearnsetEditsFlowThroughPokemonAndMovesStore() async throws {
        let root = try makeExpansionPokemonProject(includeTutorLearnsets: true)
        let tutorPath = root.appendingPathComponent("src/data/pokemon/tutor_learnsets.h")
        let familyPath = root.appendingPathComponent("src/data/pokemon/species_info/gen_3_families.h")
        let allLearnablesPath = root.appendingPathComponent("src/data/pokemon/all_learnables.json")
        let originalFamilyText = try String(contentsOf: familyPath, encoding: .utf8)
        let originalAllLearnablesText = try String(contentsOf: allLearnablesPath, encoding: .utf8)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.selection = .moves
        store.loadSelectedSpeciesCatalogIfNeeded()
        let catalog = try await waitForSelectedSpeciesCatalog(store)
        XCTAssertEqual(catalog.profile, .pokeemeraldExpansion)
        store.requestSpeciesSelection("SPECIES_TREECKO")

        let selected = try XCTUnwrap(store.selectedSpeciesDetail)
        XCTAssertEqual(selected.learnsets.tutorSourceSpan?.relativePath, "src/data/pokemon/tutor_learnsets.h")
        XCTAssertEqual(selected.learnsets.tutor.map(\.move).sorted(), ["MOVE_MEGA_PUNCH", "MOVE_SWORD_DANCE"])
        XCTAssertTrue(store.speciesCompatibilityValue(speciesID: "SPECIES_TREECKO", moveID: "MOVE_MEGA_PUNCH", bucket: .tutor))
        XCTAssertFalse(store.speciesCompatibilityValue(speciesID: "SPECIES_TREECKO", moveID: "MOVE_FURY_CUTTER", bucket: .tutor))

        store.setSpeciesCompatibility(speciesID: "SPECIES_TREECKO", moveID: "MOVE_MEGA_PUNCH", bucket: .tutor, isEnabled: false)
        store.setSpeciesCompatibility(speciesID: "SPECIES_TREECKO", moveID: "MOVE_FURY_CUTTER", bucket: .tutor, isEnabled: true)

        XCTAssertEqual(store.dirtySpeciesBatchDrafts.map(\.speciesID), ["SPECIES_TREECKO"])
        XCTAssertEqual(store.toolbarMutationState.target, .pokemonBatch)
        XCTAssertTrue(store.toolbarMutationState.canPreview)

        store.previewToolbarMutationTarget()

        let plan = try XCTUnwrap(store.latestSpeciesBatchEditPlans.first)
        let diagnosticCodes = plan.diagnostics.map(\.code).joined(separator: ",")
        XCTAssertEqual(store.latestSpeciesBatchEditPlans.count, 1)
        XCTAssertTrue(plan.isApplyable, diagnosticCodes)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/tutor_learnsets.h"], diagnosticCodes)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains("TUTOR(FURY_CUTTER)") == true)
        XCTAssertFalse(plan.changes.first?.textPreview?.contains("TUTOR(MEGA_PUNCH)") == true)
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_TUTOR_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertTrue(store.toolbarMutationState.canApply)

        store.applyToolbarMutationTarget()

        let result = try XCTUnwrap(store.latestSpeciesBatchApplyResult)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/tutor_learnsets.h"])
        XCTAssertTrue(result.appliedChanges.allSatisfy { FileManager.default.fileExists(atPath: $0.backupPath) })
        XCTAssertTrue(store.dirtySpeciesBatchDrafts.isEmpty)
        XCTAssertEqual(try String(contentsOf: familyPath, encoding: .utf8), originalFamilyText)
        XCTAssertEqual(try String(contentsOf: allLearnablesPath, encoding: .utf8), originalAllLearnablesText)

        let source = try String(contentsOf: tutorPath, encoding: .utf8)
        XCTAssertTrue(source.contains("TUTOR(FURY_CUTTER)"))
        XCTAssertFalse(source.contains("TUTOR(MEGA_PUNCH)"))
        let reloaded = try XCTUnwrap(store.selectedSpeciesCatalog?.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(reloaded.learnsets.tutor.map(\.move).sorted(), ["MOVE_FURY_CUTTER", "MOVE_SWORD_DANCE"])
        XCTAssertTrue(store.speciesCompatibilityValue(speciesID: "SPECIES_TREECKO", moveID: "MOVE_FURY_CUTTER", bucket: .tutor))
        XCTAssertFalse(store.speciesCompatibilityValue(speciesID: "SPECIES_TREECKO", moveID: "MOVE_MEGA_PUNCH", bucket: .tutor))
    }

    @MainActor
    func testExpansionSpeciesEggMoveDraftPreviewApplyAndReloadsThroughPokemonEditor() async throws {
        let root = try makeExpansionPokemonProject(includeEggMoves: true)
        let eggPath = root.appendingPathComponent("src/data/pokemon/egg_moves.h")
        let familyPath = root.appendingPathComponent("src/data/pokemon/species_info/gen_3_families.h")
        let allLearnablesPath = root.appendingPathComponent("src/data/pokemon/all_learnables.json")
        let originalFamilyText = try String(contentsOf: familyPath, encoding: .utf8)
        let originalAllLearnablesText = try String(contentsOf: allLearnablesPath, encoding: .utf8)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedSpeciesCatalogIfNeeded()
        let catalog = try await waitForSelectedSpeciesCatalog(store)
        XCTAssertEqual(catalog.profile, .pokeemeraldExpansion)
        store.requestSpeciesSelection("SPECIES_TREECKO")

        let selected = try XCTUnwrap(store.selectedSpeciesDetail)
        XCTAssertEqual(selected.learnsets.eggSourceSpan?.relativePath, "src/data/pokemon/egg_moves.h")
        XCTAssertEqual(selected.learnsets.egg.map(\.move), ["MOVE_CRUNCH", "MOVE_LEECH_SEED"])

        var draft = try XCTUnwrap(store.selectedSpeciesDraft)
        draft.eggMoves = ["MOVE_LEECH_SEED", "MOVE_FLASH", "MOVE_CRUNCH"]
        store.updateSelectedSpeciesDraft(draft)

        XCTAssertTrue(store.selectedSpeciesIsDirty)
        XCTAssertTrue(store.canPreviewSelectedSpeciesMutationPlan)
        store.previewSelectedSpeciesMutationPlan()

        let plan = try XCTUnwrap(store.latestSpeciesEditPlan)
        let diagnosticCodes = plan.diagnostics.map(\.code).joined(separator: ",")
        XCTAssertTrue(plan.isApplyable, diagnosticCodes)
        XCTAssertEqual(plan.changes.map(\.path), ["src/data/pokemon/egg_moves.h"], diagnosticCodes)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains("egg_moves(TREECKO,") == true)
        XCTAssertTrue(plan.changes.first?.textPreview?.contains("MOVE_FLASH") == true)
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "SPECIES_EGG_MOVES_EDIT_UNSUPPORTED_PROFILE" })
        XCTAssertTrue(store.canApplySelectedSpeciesMutationPlan)

        store.applySelectedSpeciesMutationPlan()

        let result = try XCTUnwrap(store.latestSpeciesApplyResult)
        XCTAssertEqual(result.appliedChanges.map(\.path), ["src/data/pokemon/egg_moves.h"])
        XCTAssertTrue(result.appliedChanges.allSatisfy { FileManager.default.fileExists(atPath: $0.backupPath) })
        XCTAssertFalse(store.selectedSpeciesIsDirty)
        XCTAssertEqual(store.selectedSpeciesID, "SPECIES_TREECKO")
        XCTAssertEqual(try String(contentsOf: familyPath, encoding: .utf8), originalFamilyText)
        XCTAssertEqual(try String(contentsOf: allLearnablesPath, encoding: .utf8), originalAllLearnablesText)

        let source = try String(contentsOf: eggPath, encoding: .utf8)
        XCTAssertTrue(source.contains("egg_moves(TREECKO,"))
        XCTAssertTrue(source.contains("MOVE_FLASH"))
        XCTAssertTrue(source.contains("egg_moves(GROVYLE,"))
        let reloaded = try XCTUnwrap(store.selectedSpeciesCatalog?.species.first { $0.speciesID == "SPECIES_TREECKO" })
        XCTAssertEqual(reloaded.learnsets.egg.map(\.move), ["MOVE_LEECH_SEED", "MOVE_FLASH", "MOVE_CRUNCH"])
    }

    @MainActor
    func testSpeciesAssetImportStagesPaletteForPreview() async throws {
        let root = try makePokemonProject()
        try write(testJASCPalette(colorCount: 16), to: root.appendingPathComponent("graphics/pokemon/treecko/normal.pal"))
        let importURL = root.appendingPathComponent("incoming/normal.pal")
        let importedData = testJASCPalette(colorCount: 16)
        try write(importedData, to: importURL)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedSpeciesCatalogIfNeeded()
        try await waitForSelectedSpeciesCatalog(store)
        store.requestSpeciesSelection("SPECIES_TREECKO")
        let provenance = try XCTUnwrap(store.importSelectedSpeciesAsset(kind: .normalPalette, from: importURL))
        store.previewSelectedSpeciesMutationPlan()

        XCTAssertEqual(provenance.detectedKind, .palette)
        XCTAssertEqual(provenance.status, .ready)
        XCTAssertEqual(store.selectedSpeciesDraft?.assetData[.normalPalette], importedData)
        XCTAssertTrue(store.latestSpeciesEditPlan?.changes.contains { $0.path == "graphics/pokemon/treecko/normal.pal" } == true)
        XCTAssertTrue(store.latestSpeciesEditPlan?.isApplyable == true)
    }

    @MainActor
    func testSpeciesAssetImportMalformedOrWrongKindBlocksApplyability() async throws {
        let root = try makePokemonProject()
        try write(Data("old-front".utf8), to: root.appendingPathComponent("graphics/pokemon/treecko/front.png"))
        let importURL = root.appendingPathComponent("incoming/front.pal")
        try write(testJASCPalette(colorCount: 16), to: importURL)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedSpeciesCatalogIfNeeded()
        try await waitForSelectedSpeciesCatalog(store)
        store.requestSpeciesSelection("SPECIES_TREECKO")
        let provenance = try XCTUnwrap(store.importSelectedSpeciesAsset(kind: .front, from: importURL))
        store.previewSelectedSpeciesMutationPlan()

        XCTAssertEqual(provenance.detectedKind, .palette)
        XCTAssertEqual(provenance.status, .blocked)
        XCTAssertTrue(provenance.diagnostics.contains { $0.code == "SPECIES_ASSET_IMPORT_KIND_MISMATCH" })
        XCTAssertTrue(store.latestSpeciesEditPlan?.diagnostics.contains { $0.code == "SPECIES_ASSET_PNG_INVALID" } == true)
        XCTAssertEqual(store.latestSpeciesEditPlan?.changes.count, 0)
        XCTAssertFalse(store.canApplySelectedSpeciesMutationPlan)
    }

    @MainActor
    func testSpeciesAssetImportSourceDriftAfterPreviewBlocksApply() async throws {
        let root = try makePokemonProject()
        try write(Data("old-front".utf8), to: root.appendingPathComponent("graphics/pokemon/treecko/front.png"))
        let importURL = root.appendingPathComponent("incoming/front.png")
        try write(testPNGData(width: 64, height: 64, paletteColorCount: 16), to: importURL)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedSpeciesCatalogIfNeeded()
        try await waitForSelectedSpeciesCatalog(store)
        store.requestSpeciesSelection("SPECIES_TREECKO")
        store.importSelectedSpeciesAsset(kind: .front, from: importURL)
        store.previewSelectedSpeciesMutationPlan()

        try write(Data("changed-front".utf8), to: root.appendingPathComponent("graphics/pokemon/treecko/front.png"))

        XCTAssertFalse(store.canApplySelectedSpeciesMutationPlan)
        XCTAssertTrue(
            store.latestSpeciesEditPlan?.validateApplyability().diagnostics.contains {
                $0.code == "SPECIES_APPLY_ORIGINAL_SIZE_MISMATCH" || $0.code == "SPECIES_APPLY_ORIGINAL_HASH_MISMATCH"
            } == true
        )
    }

    @MainActor
    func testBuildReportFixtureFallbackWithoutLoadedProject() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        XCTAssertNil(store.selectedBuildReport)
        XCTAssertTrue(store.filteredBuildReportRows.isEmpty)
        XCTAssertEqual(store.moduleStatus(for: .build), .warning)
        XCTAssertTrue(store.fixtureBuildWorkflowActions.allSatisfy { !$0.isEnabled && $0.isPreviewLocked })
    }

    @MainActor
    func testStandaloneGBAROMOpensReadOnlyInspectorProject() throws {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let rom = temp.url.appendingPathComponent("standalone.gba")
        var bytes = [UInt8](repeating: 0xFF, count: 0x200)
        bytes.replaceSubrange(0x04 ..< 0xA0, with: Array(repeating: 1, count: 0x9C))
        bytes.replaceSubrange(0xA0 ..< 0xAC, with: Array("POKEMON TEST".utf8))
        bytes.replaceSubrange(0xAC ..< 0xB0, with: Array("BPEE".utf8))
        bytes.replaceSubrange(0xB0 ..< 0xB2, with: Array("01".utf8))
        bytes[0x100] = 0x80
        bytes[0x101] = 0x00
        bytes[0x102] = 0x00
        bytes[0x103] = 0x08
        try Data(bytes).write(to: rom)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(
            userDefaults: defaults,
            toolResolver: { tool in
                ToolAvailability(name: tool, isAvailable: true, resolvedPath: "/usr/local/bin/mgba")
            },
            autoLoadProjects: false
        )

        store.openProject(path: rom.path)

        let project = try XCTUnwrap(store.selectedIndexedProject)
        let report = try XCTUnwrap(store.selectedROMInspectorReport)
        XCTAssertEqual(project.profile, "binaryROM")
        XCTAssertEqual(project.originLabel, "Local Input")
        XCTAssertEqual(project.writePolicy, "mutationPlanOnly")
        XCTAssertEqual(report.graph.image.gameCode, "BPEE")
        XCTAssertTrue(report.resourceEntry.items.contains { $0.category == "GBA Pointer" })
        XCTAssertTrue(report.playtestReport.isRunnable)
    }

    @MainActor
    func testPlaytestLaunchUsesInjectedRunnerAndStoresResult() throws {
        let root = try makeSourceIndexProject()
        let rom = root.appendingPathComponent("pokeemerald.gba")
        let emulator = root.appendingPathComponent("tools/mGBA")
        try write(Data("abc".utf8), to: rom)
        try writeExecutable("#!/bin/sh\n", to: emulator)

        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(
            userDefaults: defaults,
            toolResolver: { tool in
                tool == "mgba"
                    ? ToolAvailability(name: tool, isAvailable: true, resolvedPath: emulator.path)
                    : ToolAvailability(name: tool, isAvailable: false)
            },
            autoLoadProjects: false
        )

        store.openProject(path: root.path)

        XCTAssertTrue(store.selectedBuildReport?.playtest.isRunnable == true)
        XCTAssertTrue(store.canLaunchSelectedPlaytest)
        let actions = store.buildWorkflowActions(includePatchActions: true)
        XCTAssertEqual(actions.first { $0.id == "open-playtest" }?.isEnabled, true)
        XCTAssertEqual(actions.first { $0.id == "capture-screenshot" }?.isEnabled, true)
        XCTAssertEqual(actions.first { $0.id == "capture-savestate" }?.isEnabled, true)
        XCTAssertEqual(actions.first { $0.id == "build-rom" }?.isEnabled, true)
        XCTAssertEqual(actions.first { $0.id == "apply-patch" }?.isEnabled, false)
        XCTAssertEqual(actions.first { $0.id == "apply-patch" }?.isPreviewLocked, false)
        XCTAssertTrue(actions.first { $0.id == "apply-patch" }?.disabledReason?.contains("compatible BPS or IPS patch") == true)

        var capturedRequest: PlaytestProcessRequest?
        store.launchSelectedPlaytest(artifactRoot: root) { request in
            capturedRequest = request
            return 7331
        }

        let request = try XCTUnwrap(capturedRequest)
        let result = try XCTUnwrap(store.selectedPlaytestLaunchResult)
        XCTAssertEqual(request.executableURL.path, emulator.path)
        XCTAssertEqual(request.arguments, [rom.path])
        XCTAssertEqual(result.status, .valid)
        XCTAssertEqual(result.processID, "PID 7331")
        XCTAssertTrue(result.artifacts.contains { $0.kind == "runLog" && $0.path.hasSuffix("/run.log") })
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/playtests/pokeemerald/run.log").path))
    }

    @MainActor
    func testDecompBuildRunnerUsesSelectedTargetAndStoresLiveLogs() async throws {
        let root = try makeSourceIndexProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(
            userDefaults: defaults,
            toolResolver: { tool in
                tool == "make"
                    ? ToolAvailability(name: tool, isAvailable: true, resolvedPath: "/usr/bin/make")
                    : ToolAvailability(name: tool, isAvailable: false)
            },
            autoLoadProjects: false
        )

        store.openProject(path: root.path)
        let targetID = try XCTUnwrap(store.selectedRunnableBuildTargets.first?.id)
        store.selectedDecompBuildTargetID = targetID

        store.runSelectedDecompBuild(artifactRoot: root) { index, targetID, artifactRoot, _, _, logHandler in
            let root = URL(fileURLWithPath: index.root.path)
            logHandler(DecompBuildLogEvent(stream: .stdout, message: "building \(targetID)"))
            return DecompBuildResult(
                status: .succeeded,
                projectRootPath: index.root.path,
                targetID: targetID,
                targetName: "Build ROM",
                command: ["make"],
                processID: 9001,
                exitCode: 0,
                artifacts: [
                    DecompBuildArtifact(
                        kind: .stdout,
                        relativePath: ".pokemonhackstudio/builds/\(targetID)/stdout.log",
                        absolutePath: (artifactRoot ?? root).appendingPathComponent(".pokemonhackstudio/builds/\(targetID)/stdout.log").path,
                        exists: true,
                        detail: "stdout"
                    ),
                ],
                output: BuildOutputValidation(
                    relativePath: "pokeemerald.gba",
                    absolutePath: root.appendingPathComponent("pokeemerald.gba").path,
                    exists: true,
                    checksumStatus: .expectationMissing,
                    freshnessStatus: .unknown
                ),
                diagnostics: []
            )
        }

        let result = try await waitForBuildRunResult(store)
        XCTAssertEqual(result.status, .valid)
        XCTAssertEqual(result.processID, "PID 9001")
        XCTAssertTrue(store.selectedBuildRunLogLines.contains { $0.stream == "stdout" && $0.message == "building \(targetID)" })
        XCTAssertNil(store.runningBuildTargetID)
    }

    @MainActor
    func testDecompBuildActionReflectsRunningAndCancelState() async throws {
        let root = try makeSourceIndexProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(
            userDefaults: defaults,
            toolResolver: { tool in
                tool == "make"
                    ? ToolAvailability(name: tool, isAvailable: true, resolvedPath: "/usr/bin/make")
                    : ToolAvailability(name: tool, isAvailable: false)
            },
            autoLoadProjects: false
        )
        store.openProject(path: root.path)
        store.loadSelectedBuildReportIfNeeded(force: true)
        let targetID = try XCTUnwrap(store.selectedRunnableBuildTargets.first?.id)
        store.selectedDecompBuildTargetID = targetID

        XCTAssertTrue(store.canRunSelectedDecompBuild)
        XCTAssertEqual(store.buildWorkflowActions(includePatchActions: false).first { $0.id == "build-rom" }?.isEnabled, true)

        store.runSelectedDecompBuild(artifactRoot: root) { index, targetID, _, _, _, _ in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            return DecompBuildResult(
                status: Task.isCancelled ? .cancelled : .succeeded,
                projectRootPath: index.root.path,
                targetID: targetID,
                targetName: targetID,
                command: ["make"],
                artifacts: [],
                diagnostics: []
            )
        }

        XCTAssertNotNil(store.runningBuildTargetID)
        XCTAssertEqual(store.buildWorkflowActions(includePatchActions: false).first { $0.id == "build-rom" }?.isEnabled, false)
        XCTAssertEqual(store.buildWorkflowActions(includePatchActions: false).first { $0.id == "cancel-build" }?.isEnabled, true)

        store.cancelSelectedDecompBuild()

        XCTAssertNil(store.runningBuildTargetID)
        XCTAssertTrue(store.canRunSelectedDecompBuild)
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertNil(store.selectedBuildRunResult)
        XCTAssertNil(store.runningBuildTargetID)
    }

    @MainActor
    func testDecompBuildProjectSwitchClearsRunningStateAndSuppressesStaleResult() async throws {
        let firstRoot = try makeSourceIndexProject()
        let secondRoot = try makeSourceIndexProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(
            userDefaults: defaults,
            toolResolver: { tool in
                tool == "make"
                    ? ToolAvailability(name: tool, isAvailable: true, resolvedPath: "/usr/bin/make")
                    : ToolAvailability(name: tool, isAvailable: false)
            },
            autoLoadProjects: false
        )
        store.openProject(path: firstRoot.path)
        store.loadSelectedBuildReportIfNeeded(force: true)
        let targetID = try XCTUnwrap(store.selectedRunnableBuildTargets.first?.id)
        store.selectedDecompBuildTargetID = targetID

        store.runSelectedDecompBuild(artifactRoot: firstRoot) { index, targetID, _, _, _, _ in
            try? await Task.sleep(nanoseconds: 500_000_000)
            return DecompBuildResult(
                status: .succeeded,
                projectRootPath: index.root.path,
                targetID: targetID,
                targetName: targetID,
                command: ["make"],
                artifacts: [],
                diagnostics: []
            )
        }

        XCTAssertNotNil(store.runningBuildTargetID)

        store.openProject(path: secondRoot.path)

        XCTAssertEqual(store.selectedIndexedProject?.rootPath, secondRoot.path)
        XCTAssertNil(store.runningBuildTargetID)
        try await Task.sleep(nanoseconds: 700_000_000)
        XCTAssertNil(store.selectedBuildRunResult)
    }

    @MainActor
    func testPlaytestCaptureUsesInjectedRunnerAndStoresResult() throws {
        let root = try makeSourceIndexProject()
        let rom = root.appendingPathComponent("pokeemerald.gba")
        let emulator = root.appendingPathComponent("tools/mGBA")
        try write(Data("abc".utf8), to: rom)
        try writeExecutable("#!/bin/sh\n", to: emulator)

        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(
            userDefaults: defaults,
            toolResolver: { tool in
                tool == "mgba"
                    ? ToolAvailability(name: tool, isAvailable: true, resolvedPath: emulator.path)
                    : ToolAvailability(name: tool, isAvailable: false)
            },
            autoLoadProjects: false
        )

        store.openProject(path: root.path)

        var capturedRequest: PlaytestProcessRequest?
        store.captureSelectedPlaytest(kind: .saveState, artifactRoot: root) { request in
            capturedRequest = request
            try write(Data("state".utf8), to: root.appendingPathComponent(".pokemonhackstudio/playtests/pokeemerald/savestate.ss0"))
            return 7444
        }

        let request = try XCTUnwrap(capturedRequest)
        let result = try XCTUnwrap(store.selectedPlaytestCaptureResult)
        XCTAssertEqual(request.executableURL.path, emulator.path)
        XCTAssertEqual(request.arguments, ["--script", root.appendingPathComponent(".pokemonhackstudio/playtests/pokeemerald/savestate-capture.lua").path, rom.path])
        XCTAssertEqual(result.status, .valid)
        XCTAssertEqual(result.processID, "PID 7444")
        XCTAssertEqual(result.title, "mGBA savestate capture")
        let primary = try XCTUnwrap(result.primaryArtifact)
        XCTAssertEqual(primary.kind, "saveState")
        XCTAssertEqual(primary.absolutePath, root.appendingPathComponent(".pokemonhackstudio/playtests/pokeemerald/savestate.ss0").path)
        XCTAssertTrue(primary.exists)
        XCTAssertTrue(primary.canOpenOrReveal)
        XCTAssertEqual(store.selectedLatestPlaytestCaptureArtifact?.id, primary.id)
        XCTAssertTrue(result.artifacts.contains { $0.kind == "saveState" && $0.path.hasSuffix("/savestate.ss0") && $0.detail.contains("Created") })
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/playtests/pokeemerald/savestate-capture.log").path))
    }

    @MainActor
    func testPlaytestScreenshotCaptureTracksMissingPrimaryArtifactWithoutFileActions() throws {
        let root = try makeSourceIndexProject()
        let rom = root.appendingPathComponent("pokeemerald.gba")
        let emulator = root.appendingPathComponent("tools/mGBA")
        try write(Data("abc".utf8), to: rom)
        try writeExecutable("#!/bin/sh\n", to: emulator)

        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(
            userDefaults: defaults,
            toolResolver: { tool in
                tool == "mgba"
                    ? ToolAvailability(name: tool, isAvailable: true, resolvedPath: emulator.path)
                    : ToolAvailability(name: tool, isAvailable: false)
            },
            autoLoadProjects: false
        )

        store.openProject(path: root.path)

        store.captureSelectedPlaytest(kind: .screenshot, artifactRoot: root) { _ in
            7555
        }

        let result = try XCTUnwrap(store.selectedPlaytestCaptureResult)
        let primary = try XCTUnwrap(result.primaryArtifact)
        XCTAssertEqual(primary.kind, "screenshot")
        XCTAssertEqual(primary.absolutePath, root.appendingPathComponent(".pokemonhackstudio/playtests/pokeemerald/screenshot.png").path)
        XCTAssertFalse(primary.exists)
        XCTAssertFalse(primary.canOpenOrReveal)
        XCTAssertEqual(store.selectedLatestPlaytestCaptureArtifact?.id, primary.id)

        try write(Data("png".utf8), to: root.appendingPathComponent(".pokemonhackstudio/playtests/pokeemerald/screenshot.png"))
        store.selectedBuildWorkbenchTab = .build
        store.selectedBuildWorkbenchTab = .playtest

        let refreshedPrimary = try XCTUnwrap(store.selectedLatestPlaytestCaptureArtifact)
        XCTAssertTrue(refreshedPrimary.exists)
        XCTAssertTrue(refreshedPrimary.canOpenOrReveal)
    }

    @MainActor
    func testPlaytestLaunchGateBlocksMissingROMWithoutRunning() throws {
        let root = try makeSourceIndexProject()
        let emulator = root.appendingPathComponent("tools/mGBA")
        try writeExecutable("#!/bin/sh\n", to: emulator)

        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(
            userDefaults: defaults,
            toolResolver: { tool in
                tool == "mgba"
                    ? ToolAvailability(name: tool, isAvailable: true, resolvedPath: emulator.path)
                    : ToolAvailability(name: tool, isAvailable: false)
            },
            autoLoadProjects: false
        )

        store.openProject(path: root.path)

        XCTAssertFalse(store.canLaunchSelectedPlaytest)
        XCTAssertEqual(store.buildWorkflowActions(includePatchActions: false).first { $0.id == "open-playtest" }?.isEnabled, false)
        XCTAssertEqual(store.buildWorkflowActions(includePatchActions: false).first { $0.id == "capture-screenshot" }?.isEnabled, false)
        XCTAssertEqual(store.buildWorkflowActions(includePatchActions: false).first { $0.id == "capture-savestate" }?.isEnabled, false)

        var didRun = false
        store.launchSelectedPlaytest(artifactRoot: root) { _ in
            didRun = true
            return 1
        }

        let result = try XCTUnwrap(store.selectedPlaytestLaunchResult)
        XCTAssertFalse(didRun)
        XCTAssertEqual(result.status, .warning)
        XCTAssertEqual(result.statusLabel, "blocked")
    }

    @MainActor
    func testUserSettingsPersistHealthAndEditorPreferences() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)

        settings.autoLoadProjects = false
        settings.healthNoiseLevel = .warningsAndErrors
        settings.showNotApplicableHealthRows = false
        settings.enabledHealthCategories = [.externalTools, .romHeaders]
        settings.editorStartupTool = .pencil
        settings.mapZoomDefault = .oneHundred

        let reloaded = WorkbenchUserSettings(defaults: defaults)
        XCTAssertFalse(reloaded.autoLoadProjects)
        XCTAssertEqual(reloaded.healthNoiseLevel, .warningsAndErrors)
        XCTAssertFalse(reloaded.showNotApplicableHealthRows)
        XCTAssertEqual(reloaded.enabledHealthCategories, [.externalTools, .romHeaders])
        XCTAssertEqual(reloaded.editorStartupTool, .pencil)
        XCTAssertEqual(reloaded.mapZoomDefault, .oneHundred)
    }

    @MainActor
    func testHealthSettingsFilterBuildMatrixRowsWithoutRebuildingCoreReport() throws {
        let root = try makeSourceIndexProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)
        let store = WorkbenchStore(userDefaults: defaults, userSettings: settings, autoLoadProjects: false)

        store.openProject(path: root.path)
        let rawReport = try XCTUnwrap(store.selectedRawBuildReport)
        XCTAssertTrue(rawReport.healthMatrix.rows.contains { $0.healthCategory == .externalTools })
        XCTAssertTrue(rawReport.healthMatrix.rows.contains { $0.healthCategory != .externalTools })

        settings.enabledHealthCategories = [.externalTools]

        let filteredReport = try XCTUnwrap(store.selectedBuildReport)
        XCTAssertFalse(filteredReport.healthMatrix.rows.isEmpty)
        XCTAssertTrue(filteredReport.healthMatrix.rows.allSatisfy { $0.healthCategory == .externalTools })
        XCTAssertGreaterThan(rawReport.healthMatrix.rows.count, filteredReport.healthMatrix.rows.count)
    }

    @MainActor
    func testHealthSettingsCanHideHealthDiagnosticsFromGlobalIssues() throws {
        let root = try makeSourceIndexProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)
        let store = WorkbenchStore(userDefaults: defaults, userSettings: settings, autoLoadProjects: false)

        store.openProject(path: root.path)

        XCTAssertTrue(store.selectedDiagnosticRows.contains(where: WorkbenchUserSettings.isHealthDiagnostic))

        settings.includeHealthDiagnosticsInGlobalIssues = false

        XCTAssertFalse(store.selectedDiagnosticRows.contains(where: WorkbenchUserSettings.isHealthDiagnostic))
        XCTAssertNotNil(store.selectedBuildReport?.diagnostics.first(where: WorkbenchUserSettings.isHealthDiagnostic))
    }

    @MainActor
    func testRecentProjectSettingsAndClearAction() throws {
        let root = try makeSourceIndexProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let settings = WorkbenchUserSettings(defaults: defaults)
        settings.maxRecentProjects = 1
        let store = WorkbenchStore(userDefaults: defaults, userSettings: settings, autoLoadProjects: false)

        store.openProject(path: root.path)

        XCTAssertEqual(store.recentProjectRoots, [root.path])
        XCTAssertEqual(defaults.stringArray(forKey: "PokemonHackStudio.recentProjectRoots"), [root.path])

        store.clearRecentProjects()

        XCTAssertTrue(store.recentProjectRoots.isEmpty)
        XCTAssertNil(defaults.stringArray(forKey: "PokemonHackStudio.recentProjectRoots"))
    }

    @MainActor
    func testBrushSelectionUndoAndRedoStacks() async throws {
        let store = try await makeLoadedStore()

        store.selectMapCell(x: 0, y: 0)
        store.selectBrush(rawValue: 0x0022)
        store.paintMapCell(x: 1, y: 0)

        XCTAssertEqual(store.selectedMapTool, .pencil)
        XCTAssertEqual(store.stagedMapBlockdataValues[1], 0x0022)
        XCTAssertEqual(store.mapEditorSession.stagedMapBlockdataValues[1], 0x0022)
        XCTAssertEqual(store.mapEditOperations, store.mapEditorSession.mapEditOperations)
        XCTAssertEqual(store.mapEditOperations.count, 1)
        XCTAssertTrue(store.undoneMapEditOperations.isEmpty)

        store.undoLastMapEdit()
        XCTAssertEqual(store.stagedMapBlockdataValues[1], 0x0002)
        XCTAssertEqual(store.stagedMapBlockdataValues, store.mapEditorSession.stagedMapBlockdataValues)
        XCTAssertTrue(store.mapEditOperations.isEmpty)
        XCTAssertEqual(store.undoneMapEditOperations.count, 1)

        store.redoMapEdit()
        XCTAssertEqual(store.stagedMapBlockdataValues[1], 0x0022)
        XCTAssertEqual(store.mapEditOperations, store.mapEditorSession.mapEditOperations)
        XCTAssertEqual(store.mapEditOperations.count, 1)
        XCTAssertTrue(store.undoneMapEditOperations.isEmpty)
    }

    @MainActor
    func testDirtyMapNavigationGuardStillBlocksSidebarMapRows() async throws {
        let store = try await makeLoadedStore()

        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE1")
        store.selectBrush(rawValue: 0x0033)
        store.paintMapCell(x: 0, y: 0)

        XCTAssertTrue(store.mapEditorSession.isDirty)

        store.requestMapSelection("MAP_ROUTE2")

        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE1")
        XCTAssertNotNil(store.pendingMapNavigation)

        store.discardMapEditsAndContinueNavigation()

        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE2")
        XCTAssertNil(store.pendingMapNavigation)
        XCTAssertFalse(store.mapEditorSession.isDirty)
    }

    @MainActor
    func testMapTitleSwitcherUsesMapSelectionPathForCleanSelection() async throws {
        let store = try await makeLoadedStore()

        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE1")

        let didSelect = store.requestMapSelection("MAP_ROUTE2", source: "Map title", deferredSearch: .preserve)

        XCTAssertTrue(didSelect)
        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE2")
        XCTAssertNil(store.pendingMapNavigation)
        XCTAssertEqual(store.recentMapTargets.first?.target, .map("MAP_ROUTE2"))
        XCTAssertTrue(store.recentMapTargets.first?.subtitle.contains("Map title") == true)
    }

    @MainActor
    func testMapTitleSwitcherSelectionUsesDirtyNavigationGuard() async throws {
        let store = try await makeLoadedStore()

        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE1")
        store.selectBrush(rawValue: 0x0033)
        store.paintMapCell(x: 0, y: 0)

        let didSelect = store.requestMapSelection("MAP_ROUTE2", source: "Map title", deferredSearch: .preserve)

        XCTAssertFalse(didSelect)
        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE1")
        XCTAssertEqual(store.pendingMapNavigation, .map("MAP_ROUTE2"))
        XCTAssertTrue(store.mapEditorSession.isDirty)

        store.discardMapEditsAndContinueNavigation()

        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE2")
        XCTAssertNil(store.pendingMapNavigation)
        XCTAssertFalse(store.mapEditorSession.isDirty)
        XCTAssertEqual(store.recentMapTargets.first?.target, .map("MAP_ROUTE2"))
        XCTAssertTrue(store.recentMapTargets.first?.subtitle.contains("Map title") == true)
    }

    @MainActor
    func testNewMapToolbarActionOpensWorkflowPlanWithoutChangingSelectionOrDirtyState() async throws {
        let store = try await makeLoadedStore()

        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE1")
        store.selectedMapWorkbenchTab = .overviewLayers
        store.selectBrush(rawValue: 0x0033)
        store.paintMapCell(x: 0, y: 0)
        XCTAssertTrue(store.mapEditorSession.isDirty)

        store.openNewMapPlanFromToolbar()

        XCTAssertEqual(store.selectedMapWorkbenchTab, .workflow)
        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE1")
        XCTAssertTrue(store.mapEditorSession.isDirty)
        XCTAssertNil(store.pendingMapNavigation)
    }

    @MainActor
    func testDirtyMapNavigationGuardStillBlocksHiddenSidebarTargets() async throws {
        let store = try await makeLoadedStore()

        store.searchText = "Route2"
        store.selectBrush(rawValue: 0x0033)
        store.paintMapCell(x: 0, y: 0)

        XCTAssertTrue(store.mapEditorSession.isDirty)

        store.requestMapSelection("MAP_ROUTE2")

        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE1")
        XCTAssertEqual(store.pendingMapNavigation, .map("MAP_ROUTE2"))

        store.cancelPendingMapNavigation()
        store.searchText = ""

        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE1")
        XCTAssertNil(store.pendingMapNavigation)
        XCTAssertTrue(store.mapEditorSession.isDirty)
    }

    @MainActor
    func testMapRefreshIsGuardedWhenVisualEditsAreStaged() async throws {
        let store = try await makeLoadedStore()
        store.loadSelectedMapCatalog()
        try await waitForSelectedMapCatalog(store)

        store.selectBrush(rawValue: 0x0033)
        store.paintMapCell(x: 0, y: 0)

        store.refreshSelectedMapCatalog()

        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE1")
        XCTAssertEqual(store.pendingMapNavigation, .refreshMaps)
        XCTAssertNotNil(store.selectedMapCatalog)
        XCTAssertTrue(store.mapEditorSession.isDirty)
    }

    @MainActor
    func testModuleRefreshDefersMapReloadWhenVisualEditsAreStaged() async throws {
        let store = try await makeLoadedStore()
        store.selectWorkbenchModule(.maps)

        store.selectBrush(rawValue: 0x0033)
        store.paintMapCell(x: 0, y: 0)

        store.refreshSelectedModuleContext()
        try await Task.sleep(nanoseconds: 150_000_000)

        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE1")
        XCTAssertEqual(store.selectedMapVisualDocument?.mapID, "MAP_ROUTE1")
        XCTAssertEqual(store.pendingMapNavigation, .refreshMaps)
        XCTAssertTrue(store.mapEditorSession.isDirty)
    }

    @MainActor
    func testDirtyMapRefreshDiscardContinueReloadsCatalogAndSelection() async throws {
        let store = try await makeLoadedStore()
        store.selectWorkbenchModule(.maps)

        store.selectBrush(rawValue: 0x0033)
        store.paintMapCell(x: 0, y: 0)

        store.refreshSelectedMapCatalog()
        store.discardMapEditsAndContinueNavigation()

        let catalog = try await waitForSelectedMapCatalog(store)
        try await waitForSelectedMapVisual(store, mapID: "MAP_ROUTE1")

        XCTAssertEqual(catalog.mapCount, 2)
        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE1")
        XCTAssertNil(store.pendingMapNavigation)
        XCTAssertFalse(store.mapEditorSession.isDirty)
    }

    @MainActor
    func testDirtyMapNavigationCancelPreservesSearchAndAcceptedNavigationAppliesTargetSearch() async throws {
        let store = try await makeLoadedStore()
        store.selectWorkbenchModule(.maps, search: .replace("Route1"))

        store.selectBrush(rawValue: 0x0033)
        store.paintMapCell(x: 0, y: 0)

        store.focusWorkbenchTarget(.map("MAP_ROUTE2"), search: .replace("Route2"))

        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE1")
        XCTAssertEqual(store.searchText, "Route1")
        XCTAssertEqual(store.pendingMapNavigation, .map("MAP_ROUTE2"))

        store.cancelPendingMapNavigation()

        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE1")
        XCTAssertEqual(store.searchText, "Route1")
        XCTAssertTrue(store.mapEditorSession.isDirty)

        store.focusWorkbenchTarget(.map("MAP_ROUTE2"), search: .replace("Route2"))
        store.discardMapEditsAndContinueNavigation()

        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE2")
        XCTAssertEqual(store.searchText, "Route2")
        XCTAssertNil(store.pendingMapNavigation)
        XCTAssertFalse(store.mapEditorSession.isDirty)
    }

    @MainActor
    func testOpenProjectWhileMapIsDirtyDefersSelectionUntilDiscardContinue() async throws {
        let firstRoot = try makeVisualProject()
        let secondRoot = try makeVisualProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: firstRoot.path)
        store.selectedMapID = "MAP_ROUTE1"
        store.loadSelectedMapVisualDocument()
        try await waitForSelectedMapVisual(store, mapID: "MAP_ROUTE1")
        let firstProjectID = store.selectedProjectID

        store.selectedResourceAssetID = "stale-resource"
        store.resourceAssetCategory = "maps"
        store.selectBrush(rawValue: 0x0033)
        store.paintMapCell(x: 0, y: 0)

        store.openProject(path: secondRoot.path)

        XCTAssertEqual(store.selectedProjectID, firstProjectID)
        XCTAssertEqual(store.selectedIndexedProject?.rootPath, firstRoot.path)
        XCTAssertTrue(store.mapEditorSession.isDirty)
        XCTAssertNotNil(store.pendingMapNavigation)

        store.discardMapEditsAndContinueNavigation()

        XCTAssertEqual(store.selectedIndexedProject?.rootPath, secondRoot.path)
        XCTAssertNil(store.selectedResourceAssetID)
        XCTAssertEqual(store.resourceAssetCategory, WorkbenchStore.allResourceAssetCategories)
        XCTAssertNil(store.pendingMapNavigation)
        XCTAssertFalse(store.mapEditorSession.isDirty)
    }

    @MainActor
    func testScriptReadinessMapSwitchUsesDirtyNavigationGuard() async throws {
        let store = try await makeLoadedStore()

        store.scriptReadinessTargetMode = .map
        store.selectBrush(rawValue: 0x0033)
        store.paintMapCell(x: 0, y: 0)

        store.requestScriptReadinessMapSelection("MAP_ROUTE2")

        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE1")
        XCTAssertEqual(store.pendingMapNavigation, .map("MAP_ROUTE2"))
        XCTAssertTrue(store.mapEditorSession.isDirty)
    }

    @MainActor
    func testScriptReadinessMapSwitchRefreshesAfterDirtyDiscardContinue() async throws {
        let store = try await makeLoadedStore()

        store.selection = .scripts
        store.scriptReadinessTargetMode = .map
        store.refreshSelectedScriptReadinessReport()
        XCTAssertEqual(store.selectedScriptReadinessReport?.mapContext?.mapID, "MAP_ROUTE1")

        store.selectBrush(rawValue: 0x0033)
        store.paintMapCell(x: 0, y: 0)

        store.requestScriptReadinessMapSelection("MAP_ROUTE2")
        store.discardMapEditsAndContinueNavigation()

        XCTAssertEqual(store.selectedMapID, "MAP_ROUTE2")
        XCTAssertEqual(store.selectedScriptReadinessReport?.mapContext?.mapID, "MAP_ROUTE2")
        XCTAssertNil(store.pendingMapNavigation)
    }

    @MainActor
    func testResourceBacklinksForceMatchingResourceMode() async throws {
        let root = try makeSourceIndexProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.openProject(path: root.path)
        store.loadSelectedAssetCatalogIfNeeded()
        let assetCatalog = try await waitForSelectedAssetCatalog(store)
        let scriptAsset = try XCTUnwrap(assetCatalog.rows.first { $0.category == "scripts" && $0.targetID == "data/scripts/test.inc" })
        let rootEntry = try XCTUnwrap(store.resourceLibrary?.entries.first { $0.path == root.path })

        store.selectedResourceLibraryMode = .entries
        store.resourceAssetWorkflowFacet = .generatedReference
        XCTAssertTrue(store.focusResourceAsset(scriptAsset.id))
        XCTAssertEqual(store.selection, .resources)
        XCTAssertEqual(store.selectedResourceLibraryMode, .assets)
        XCTAssertEqual(store.resourceAssetWorkflowFacet, .all)
        XCTAssertEqual(store.selectedResourceAssetID, scriptAsset.id)

        store.selectedResourceLibraryMode = .assets
        XCTAssertTrue(store.focusResourceEntry(rootEntry.id))
        XCTAssertEqual(store.selection, .resources)
        XCTAssertEqual(store.selectedResourceLibraryMode, .entries)
        XCTAssertEqual(store.selectedResourceLibraryEntryID, rootEntry.id)
    }

    @MainActor
    func testInvalidResourceBacklinksDoNotPoisonPokemonMoveOrTrainerSelection() async throws {
        let pokemonRoot = try makePokemonProject()
        try writeBattleMoveTable(to: pokemonRoot)
        let pokemonDefaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let pokemonStore = WorkbenchStore(userDefaults: pokemonDefaults, autoLoadProjects: false)

        pokemonStore.openProject(path: pokemonRoot.path)
        pokemonStore.selectWorkbenchModule(.pokemon)
        try await waitForSelectedSpeciesCatalog(pokemonStore)
        XCTAssertTrue(pokemonStore.focusSpecies("SPECIES_TREECKO"))
        let speciesRecentCount = pokemonStore.recentSpeciesTargets.count

        pokemonStore.navigateToAsset(Self.makeAssetRow(
            id: "invalid-species",
            title: "Invalid Species",
            path: "src/data/pokemon/species_info.h",
            category: "species",
            targetModule: .pokemon,
            targetID: "SPECIES_MISSINGNO"
        ))

        XCTAssertEqual(pokemonStore.selectedSpeciesID, "SPECIES_TREECKO")
        XCTAssertEqual(pokemonStore.recentSpeciesTargets.count, speciesRecentCount)
        XCTAssertFalse(pokemonStore.recentSpeciesTargets.contains { $0.target == .species("SPECIES_MISSINGNO") })

        pokemonStore.selectWorkbenchModule(.moves)
        try await waitForSelectedMoveCatalog(pokemonStore)
        XCTAssertTrue(pokemonStore.focusMove("MOVE_POUND"))
        let moveRecentCount = pokemonStore.recentMoveTargets.count

        pokemonStore.navigateToAsset(Self.makeAssetRow(
            id: "invalid-move",
            title: "Invalid Move",
            path: "src/data/battle_moves.h",
            category: "moves",
            targetModule: .moves,
            targetID: "MOVE_SPLASHIER"
        ))

        XCTAssertEqual(pokemonStore.selectedMoveID, "MOVE_POUND")
        XCTAssertEqual(pokemonStore.recentMoveTargets.count, moveRecentCount)
        XCTAssertFalse(pokemonStore.recentMoveTargets.contains { $0.target == .move("MOVE_SPLASHIER") })

        let trainerRoot = try makeTrainerProject()
        let trainerDefaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let trainerStore = WorkbenchStore(userDefaults: trainerDefaults, autoLoadProjects: false)

        trainerStore.openProject(path: trainerRoot.path)
        trainerStore.selectWorkbenchModule(.trainers)
        try await waitForSelectedTrainerCatalog(trainerStore)
        trainerStore.requestTrainerSelection("TRAINER_TEST")

        trainerStore.navigateToAsset(Self.makeAssetRow(
            id: "invalid-trainer",
            title: "Invalid Trainer",
            path: "src/data/trainers.h",
            category: "trainers",
            targetModule: .trainers,
            targetID: "TRAINER_MISSING"
        ))

        XCTAssertEqual(trainerStore.selectedTrainerID, "TRAINER_TEST")
    }

    @MainActor
    func testSelectionPersistenceAndMapSwitchClearsDirtyState() async throws {
        let store = try await makeLoadedStore()

        store.selectMapCell(x: 1, y: 1)
        XCTAssertEqual(store.selectedMapCell?.metatileID, 4)

        store.selectBrush(rawValue: 0x0033)
        store.paintMapCell(x: 1, y: 1)
        XCTAssertEqual(store.mapEditOperations.count, 1)

        store.selectedMapID = "MAP_ROUTE2"
        store.loadSelectedMapVisualDocument()
        try await waitForSelectedMapVisual(store, mapID: "MAP_ROUTE2")

        XCTAssertEqual(store.selectedMapVisualDocument?.mapID, "MAP_ROUTE2")
        XCTAssertEqual(store.mapEditOperations.count, 0)
        XCTAssertNil(store.selectedMapCell)
        XCTAssertNil(store.latestMapEditPlan)
        XCTAssertEqual(store.stagedMapBlockdataValues, [5, 6, 7, 8])
    }

    @MainActor
    func testMutationPreviewAndApplyGatingState() async throws {
        let store = try await makeLoadedStore()

        XCTAssertNil(store.latestMapEditPlan)
        store.previewSelectedMapMutationPlan()
        XCTAssertNil(store.latestMapEditPlan)

        store.selectBrush(rawValue: 0x0044)
        store.paintMapCell(x: 0, y: 0)
        XCTAssertNil(store.latestMapEditPlan)

        store.previewSelectedMapMutationPlan()

        let plan = try XCTUnwrap(store.latestMapEditPlan)
        XCTAssertEqual(plan.changes.map(\.path), ["data/layouts/Route1/map.bin"])
        XCTAssertTrue(plan.mutationPlan.requiresExplicitApply)
        XCTAssertTrue(plan.changes.allSatisfy { !$0.path.hasSuffix(".inc") })
    }

    @MainActor
    func testEventPropertyEditsStageJSONMutation() async throws {
        let store = try await makeLoadedStore()

        store.selectMapEvent(id: "object-0")
        store.updateSelectedMapEventProperty(key: "script", value: "Route1_EventScript_New")
        store.previewSelectedMapMutationPlan()

        XCTAssertEqual(store.stagedMapEvents.first?.properties.first { $0.key == "script" }?.value, "Route1_EventScript_New")
        XCTAssertEqual(store.stagedMapEvents, store.mapEditorSession.stagedMapEvents)
        let jsonPreview = try XCTUnwrap(store.latestMapEditPlan?.changes.first { $0.path == "data/maps/Route1/map.json" }?.textPreview)
        XCTAssertTrue(jsonPreview.contains(#""script": "Route1_EventScript_New""#))
    }

    @MainActor
    func testStoreMapEditingFacadeUsesSessionAsSingleOwner() async throws {
        let store = try await makeLoadedStore()

        store.selectBrush(rawValue: 0x0088)
        store.paintMapCell(x: 0, y: 0)
        store.selectMapEvent(id: "object-0")
        store.updateSelectedMapEventProperty(key: "elevation", value: "4")

        XCTAssertTrue(store.mapEditorSession.isDirty)
        XCTAssertEqual(store.selectedBrushRawValue, store.mapEditorSession.selectedBrushRawValue)
        XCTAssertEqual(store.selectedMapCell, store.mapEditorSession.selectedMapCell)
        XCTAssertEqual(store.selectedMapEventID, store.mapEditorSession.selectedMapEventID)
        XCTAssertEqual(store.stagedMapBlockdataValues, store.mapEditorSession.stagedMapBlockdataValues)
        XCTAssertEqual(store.stagedMapEvents, store.mapEditorSession.stagedMapEvents)
        XCTAssertEqual(store.mapEditOperations, store.mapEditorSession.mapEditOperations)

        store.discardMapEdits()

        XCTAssertFalse(store.mapEditorSession.isDirty)
        XCTAssertEqual(store.stagedMapBlockdataValues, [1, 2, 3, 4])
        XCTAssertEqual(store.stagedMapEvents, store.mapEditorSession.stagedMapEvents)
        XCTAssertTrue(store.mapEditOperations.isEmpty)
    }

    @MainActor
    private func makeLoadedStore() async throws -> WorkbenchStore {
        let root = try makeVisualProject()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "MapEditorStoreTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)
        store.openProject(path: root.path)
        store.selectedMapID = "MAP_ROUTE1"
        store.loadSelectedMapVisualDocument()
        try await waitForSelectedMapVisual(store, mapID: "MAP_ROUTE1")
        return store
    }

    @MainActor
    @discardableResult
    private func waitForSelectedMapCatalog(_ store: WorkbenchStore) async throws -> MapCatalogViewState {
        for _ in 0 ..< 100 {
            if let catalog = store.selectedMapCatalog {
                return catalog
            }
            if case let .failed(message) = store.mapCatalogStatus {
                throw StoreTestError.mapCatalogFailed(message)
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.mapCatalogTimedOut
    }

    @MainActor
    @discardableResult
    private func waitForSelectedMapVisual(_ store: WorkbenchStore, mapID: String) async throws -> MapVisualDocument {
        for _ in 0 ..< 100 {
            if let document = store.selectedMapVisualDocument, document.mapID == mapID {
                return document
            }
            if case let .failed(message) = store.mapVisualStatus {
                throw StoreTestError.mapVisualFailed(message)
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.mapVisualTimedOut
    }

    @MainActor
    private func waitForSelectedAssetCatalog(_ store: WorkbenchStore) async throws -> ResourceAssetCatalogViewState {
        for _ in 0 ..< 100 {
            if let catalog = store.selectedAssetCatalog {
                return catalog
            }
            if case let .failed(message) = store.assetCatalogLoadStatus {
                throw StoreTestError.assetCatalogFailed(message)
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.assetCatalogTimedOut
    }

    @MainActor
    private func waitForResourceEntry(
        _ store: WorkbenchStore,
        id: ResourceLibraryEntryViewState.ID
    ) async throws -> ResourceLibraryEntryViewState {
        for _ in 0 ..< 100 {
            if let entry = store.resourceLibrary?.entries.first(where: { $0.id == id }),
               entry.detailMode == "full"
            {
                return entry
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.resourceEntryTimedOut
    }

    @MainActor
    @discardableResult
    private func waitForSelectedSourceGraph(_ store: WorkbenchStore) async throws -> ProjectSourceIndex {
        for _ in 0 ..< 100 {
            if let sourceIndex = store.selectedSourceIndex {
                return sourceIndex
            }
            if case let .failed(message) = store.sourceGraphLoadStatus {
                throw StoreTestError.sourceGraphFailed(message)
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.sourceGraphTimedOut
    }

    @MainActor
    @discardableResult
    private func waitForSelectedSpeciesCatalog(_ store: WorkbenchStore) async throws -> ProjectSpeciesCatalog {
        for _ in 0 ..< 100 {
            if let catalog = store.selectedSpeciesCatalog {
                return catalog
            }
            if case let .failed(message) = store.speciesCatalogLoadStatus {
                throw StoreTestError.speciesCatalogFailed(message)
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.speciesCatalogTimedOut
    }

    @MainActor
    @discardableResult
    private func waitForSelectedTrainerCatalog(_ store: WorkbenchStore) async throws -> ProjectTrainerCatalog {
        for _ in 0 ..< 100 {
            if let catalog = store.selectedTrainerCatalog {
                return catalog
            }
            if case let .failed(message) = store.trainerCatalogLoadStatus {
                throw StoreTestError.trainerCatalogFailed(message)
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.trainerCatalogTimedOut
    }

    @MainActor
    @discardableResult
    private func waitForSelectedMoveCatalog(_ store: WorkbenchStore) async throws -> MoveCatalogViewState {
        for _ in 0 ..< 100 {
            if let catalog = store.selectedMoveCatalog {
                return catalog
            }
            if case let .failed(message) = store.moveCatalogLoadStatus {
                throw StoreTestError.moveCatalogFailed(message)
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.moveCatalogTimedOut
    }

    @MainActor
    @discardableResult
    private func waitForSelectedItemCatalog(_ store: WorkbenchStore) async throws -> ProjectItemCatalog {
        for _ in 0 ..< 100 {
            if let catalog = store.selectedItemCatalog {
                return catalog
            }
            if case let .failed(message) = store.itemCatalogLoadStatus {
                throw StoreTestError.itemCatalogFailed(message)
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.itemCatalogTimedOut
    }

    private func makeVisualProject() throws -> URL {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url

        try write("POKEMON EMER\n", to: root.appendingPathComponent("Makefile"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/pokenav"), withIntermediateDirectories: true)

        try write(
            """
            {
              "group_order": ["gMapGroup_Routes"],
              "gMapGroup_Routes": ["Route1", "Route2"]
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
                },
                {
                  "id": "LAYOUT_ROUTE2",
                  "name": "Route2_Layout",
                  "width": 2,
                  "height": 2,
                  "border_width": 2,
                  "border_height": 2,
                  "primary_tileset": "gTileset_General",
                  "secondary_tileset": "gTileset_Route",
                  "border_filepath": "data/layouts/Route2/border.bin",
                  "blockdata_filepath": "data/layouts/Route2/map.bin"
                }
              ]
            }
            """,
            to: root.appendingPathComponent("data/layouts/layouts.json")
        )
        try writeMapJSON(name: "Route1", mapID: "MAP_ROUTE1", layoutID: "LAYOUT_ROUTE1", to: root.appendingPathComponent("data/maps/Route1/map.json"))
        try writeMapJSON(name: "Route2", mapID: "MAP_ROUTE2", layoutID: "LAYOUT_ROUTE2", to: root.appendingPathComponent("data/maps/Route2/map.json"))

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

        try writeWords([1, 2, 3, 4], to: root.appendingPathComponent("data/layouts/Route1/map.bin"))
        try writeWords([5, 6, 7, 8], to: root.appendingPathComponent("data/layouts/Route2/map.bin"))
        try writeWords([9, 10, 11, 12], to: root.appendingPathComponent("data/layouts/Route1/border.bin"))
        try writeWords([13, 14, 15, 16], to: root.appendingPathComponent("data/layouts/Route2/border.bin"))
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

    private func makeFireRedProject(named name: String, under parent: URL) throws -> URL {
        let root = parent.appendingPathComponent(name)

        try write("ROM := poke$(BUILD_NAME).gba\n", to: root.appendingPathComponent("Makefile"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/pokemon"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/trainers"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/quest_log"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("data/scripts"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("data/text"), withIntermediateDirectories: true)
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try write("const struct SpeciesInfo gSpeciesInfo[] = {};\n", to: root.appendingPathComponent("src/data/pokemon/species_info.h"))
        try write("const struct Trainer gTrainers[] = {};\n", to: root.appendingPathComponent("src/data/trainers.h"))
        try write("[]\n", to: root.appendingPathComponent("src/data/items.json"))
        try write("[]\n", to: root.appendingPathComponent("src/data/wild_encounters.json"))

        return root
    }

    private func makeStandaloneGBAROM(named name: String, under parent: URL) throws -> URL {
        let rom = parent.appendingPathComponent(name)
        var bytes = [UInt8](repeating: 0xFF, count: 0x200)
        bytes.replaceSubrange(0x04 ..< 0xA0, with: Array(repeating: 1, count: 0x9C))
        bytes.replaceSubrange(0xA0 ..< 0xAC, with: Array("POKEMON TEST".utf8))
        bytes.replaceSubrange(0xAC ..< 0xB0, with: Array("BPEE".utf8))
        bytes.replaceSubrange(0xB0 ..< 0xB2, with: Array("01".utf8))
        bytes[0x100] = 0x80
        bytes[0x101] = 0x00
        bytes[0x102] = 0x00
        bytes[0x103] = 0x08
        try Data(bytes).write(to: rom)
        return rom
    }

    private func makeStandaloneNDSROM(named name: String, under parent: URL) throws -> URL {
        let rom = parent.appendingPathComponent(name)
        var data = Data(repeating: 0, count: 0x900)
        writeASCII("POKEMON D", into: &data, at: 0x00, length: 12)
        writeASCII("ADAE", into: &data, at: 0x0C, length: 4)
        writeASCII("01", into: &data, at: 0x10, length: 2)
        data[0x14] = 0x09
        writeUInt32LE(0x200, into: &data, at: 0x20)
        writeUInt32LE(0x20, into: &data, at: 0x2C)
        writeUInt32LE(0x220, into: &data, at: 0x30)
        writeUInt32LE(0x20, into: &data, at: 0x3C)

        let fnt = makeTestFNT()
        writeUInt32LE(0x300, into: &data, at: 0x40)
        writeUInt32LE(UInt32(fnt.count), into: &data, at: 0x44)
        data.replaceSubrange(0x300 ..< (0x300 + fnt.count), with: fnt)

        let narc = makeTestNARC()
        var fat = Data()
        appendUInt32LE(0x400, to: &fat)
        appendUInt32LE(0x404, to: &fat)
        appendUInt32LE(0x440, to: &fat)
        appendUInt32LE(0x450, to: &fat)
        appendUInt32LE(0x500, to: &fat)
        appendUInt32LE(UInt32(0x500 + narc.count), to: &fat)
        writeUInt32LE(0x380, into: &data, at: 0x48)
        writeUInt32LE(UInt32(fat.count), into: &data, at: 0x4C)
        data.replaceSubrange(0x380 ..< (0x380 + fat.count), with: fat)
        writeUInt32LE(0x700, into: &data, at: 0x68)
        writeUInt16LE(0x5678, into: &data, at: 0x15E)

        data.replaceSubrange(0x400 ..< 0x404, with: Data("ROOT".utf8))
        data.replaceSubrange(0x440 ..< 0x450, with: Data("SDAT".utf8) + Data(repeating: 0, count: 12))
        data.replaceSubrange(0x500 ..< (0x500 + narc.count), with: narc)
        try data.write(to: rom)
        return rom
    }

    private func makeNDSSourceProject() throws -> URL {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url

        try write("diamond: ; @echo build\n", to: root.appendingPathComponent("Makefile"))
        try write("GAME_VERSION ?= DIAMOND\n", to: root.appendingPathComponent("config.mk"))
        try write("NitroROMSpec\n", to: root.appendingPathComponent("rom.rsf"))
        try write("FILESYSTEM_ROOT := files\n", to: root.appendingPathComponent("filesystem.mk"))
        try write("0" + String(repeating: "a", count: 39) + "  pokediamond.us.nds\n", to: root.appendingPathComponent("pokediamond.us.sha1"))
        try write("arm9 source\n", to: root.appendingPathComponent("arm9/main.c"))
        try write("void Pokemon_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/pokemon.c"))
        try write("void Waza_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/waza.c"))
        try write(
            """
            #include "global.h"

            static const u16 sItemIndexMappings[][4] = {
                { 0, 1, 2, 0 },
                { 1, 2, 3, 1 },
                { ITEM_DATA_COUNT, 4, 5, 6 },
            };

            void Item_Load(void) {}

            """,
            to: root.appendingPathComponent("arm9/src/itemtool.c")
        )
        try write(
            """
            #include "trainer_data.h"

            const u8 sTrainerClassGenderCountTbl[] = {
                /*TRAINER_CLASS_PKMN_TRAINER_M*/ 0,
                /*TRAINER_CLASS_LASS*/ 1,
                /*TRAINER_CLASS_TWINS*/ 2,
                TRAINER_CLASS_GENDER_COUNT_SENTINEL,
            };

            void Trainer_Load(void) {}

            """,
            to: root.appendingPathComponent("arm9/src/trainer_data.c")
        )
        try write("void Script_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/script.c"))
        try write("arm7 source\n", to: root.appendingPathComponent("arm7/main.s"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/root.bin"))
        try write(
            "{\"species\":\"TURTWIG\",\"base_hp\":55,\"catch_rate\":45,\"forms\":[{\"form\":\"default\"}]}\n",
            to: root.appendingPathComponent("files/poketool/personal/turtwig.json")
        )
        try write(
            "{\"species\":\"PIPLUP\",\"base_hp\":53,\"catch_rate\":45,\"forms\":[{\"form\":\"pearl\"}]}\n",
            to: root.appendingPathComponent("files/poketool/personal_pearl/piplup.json")
        )
        try write(Data([0x03]), to: root.appendingPathComponent("files/poketool/personal/personal_0000.bin"))
        try write(
            "{\"id\":7,\"name\":\"Youngster Dan\",\"double_battle\":false,\"party\":[{\"species\":\"STARLY\",\"level\":5}]}\n",
            to: root.appendingPathComponent("files/poketool/trainer/youngster.json")
        )
        try write(Data([0x04]), to: root.appendingPathComponent("files/poketool/trainer/trainer_0000.bin"))
        try write("{\"name\":\"POTION\",\"price\":300,\"field_use\":true,\"effects\":[{\"kind\":\"heal\",\"amount\":20}]}\n", to: root.appendingPathComponent("files/itemtool/itemdata/potion.json"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/itemtool/itemdata/item_0000.bin"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/fielddata/mapmatrix/matrix.bin"))
        try write(Data([0x01]), to: root.appendingPathComponent("files/fielddata/maptable/map.bin"))
        try write(Data([0x02]), to: root.appendingPathComponent("files/fielddata/land_data/land_0001.bin"))
        try write(Data([0x03]), to: root.appendingPathComponent("files/fielddata/areadata/area_0001.bin"))
        try write(Data([0x00]), to: root.appendingPathComponent("graphics/icon.bin"))
        try write("// header\n", to: root.appendingPathComponent("include/config.h"))

        return root
    }

    private func makeNDSPlatinumSourceProject() throws -> URL {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url

        try makeNDSPlatinumSourceProject(at: root)
        return root
    }

    private func makeNDSPlatinumSourceProject(at root: URL) throws {
        try write("rom: build/pokeplatinum.us.nds\n", to: root.appendingPathComponent("Makefile"))
        try write("project('pokeplatinum')\n", to: root.appendingPathComponent("meson.build"))
        try write("path,sha1\n", to: root.appendingPathComponent("platinum.us/filesys.csv"))
        try write("cccccccccccccccccccccccccccccccccccccccc  pokeplatinum.us.nds\n", to: root.appendingPathComponent("platinum.us/rom_rev1.sha1"))
        try write("src\n", to: root.appendingPathComponent("src/main.c"))
        try write("asm\n", to: root.appendingPathComponent("asm/main.s"))
        try write("{\"base_hp\":25,\"evolutions\":[[\"EVO_LEVEL\",16,\"SPECIES_KADABRA\"]]}\n", to: root.appendingPathComponent("res/pokemon/abra/data.json"))
        try write("{\"power\":40}\n", to: root.appendingPathComponent("res/battle/moves/tackle.json"))
        try write("id,name\n1,POTION\n", to: root.appendingPathComponent("res/items/items.csv"))
        try write(
            """
            {"name": "Potion", "price": 300, "field_use": true, "effects": [{"kind":"heal","amount":20}]}

            """,
            to: root.appendingPathComponent("res/items/potion.json")
        )
        try write(
            """
            {"name": "Youngster", "class": "TRAINER_CLASS_YOUNGSTER", "double_battle": false, "party": [{"species":"STARLY","level":5}], "messages": ["I like shorts!"]}

            """,
            to: root.appendingPathComponent("res/trainers/data/youngster.json")
        )
        try write("{\"cell_animation\":1}\n", to: root.appendingPathComponent("res/trainers/classes/youngster.json"))
        try write("{\"message\":\"hello\"}\n", to: root.appendingPathComponent("res/text/story.json"))
        try write("hello\nworld\n", to: root.appendingPathComponent("res/text/route201.txt"))
        try write(Data("BMG Test\u{0}Hello there\u{0}Goodbye\u{0}".utf8), to: root.appendingPathComponent("res/text/battle.bmg"))
        try write("scrcmd_end\n", to: root.appendingPathComponent("res/field/scripts/route201.s"))
        try write("{\"event\":1}\n", to: root.appendingPathComponent("res/field/events/route201.json"))
        try write(Data([0x01, 0x02]), to: root.appendingPathComponent("res/field/maps/route201/map.bin"))
        try write("{\"matrix\":1}\n", to: root.appendingPathComponent("res/field/matrices/route201.json"))
        try write(makeTestNARC(), to: root.appendingPathComponent("res/prebuilt/poketool/personal/personal.narc"))
    }

    private func makeNDSHeartGoldSourceProject() throws -> URL {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url

        try write("GAME_VERSION ?= HEARTGOLD\nGAME_CODE := IPK\n", to: root.appendingPathComponent("config.mk"))
        try write("ROM := $(BUILD_DIR)/poke$(buildname).nds\n", to: root.appendingPathComponent("Makefile"))
        try write("HostRoot files/\n", to: root.appendingPathComponent("rom.rsf"))
        try write("filesystem: $(NITROFS_FILES)\n", to: root.appendingPathComponent("filesystem.mk"))
        try write("dddddddddddddddddddddddddddddddddddddddd  pokeheartgold.us.nds\n", to: root.appendingPathComponent("heartgold.us/rom.sha1"))
        try write("{\"species\":\"CHIKORITA\"}\n", to: root.appendingPathComponent("files/poketool/personal/personal.json"))
        try write(Data([0x01]), to: root.appendingPathComponent("files/poketool/personal/personal_0000.bin"))
        try write("{\"id\":1,\"name\":\"Youngster Joey\",\"double_battle\":false,\"party\":[{\"species\":\"RATTATA\",\"level\":4}]}\n", to: root.appendingPathComponent("files/poketool/trainer/trainers.json"))
        try write(Data([0x02]), to: root.appendingPathComponent("files/poketool/trainer/trainer_0000.bin"))
        try write("id,name\n1,POTION\n", to: root.appendingPathComponent("files/itemtool/itemdata/item_data.csv"))
        try write("{\"name\":\"POTION\",\"price\":300,\"field_use\":true,\"effects\":[{\"kind\":\"heal\",\"amount\":20}]}\n", to: root.appendingPathComponent("files/itemtool/itemdata/potion.json"))
        try write("{\"zone\":1}\n", to: root.appendingPathComponent("files/fielddata/eventdata/zone_event/zone_001.json"))
        try write("message\n", to: root.appendingPathComponent("files/msgdata/msg/0001.txt"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/fielddata/script/scr_seq/0001.bin"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/fielddata/mapmatrix/0001.bin"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/fielddata/maptable/map.bin"))
        try write(
            """
            static const MapHeader sMapHeaders[] = {
                [MAP_EVERYWHERE] = {
                    .wildEncounterBank = ENCDATA_NA,
                    .areaDataBank = 0,
                    .moveModelBank = 15,
                    .worldMapX = 0,
                    .worldMapY = 0,
                    .matrixId = NARC_map_matrix_map_matrix_0000_EVERYWHERE_bin,
                    .scriptsBank = NARC_scr_seq_scr_seq_0139_EVERYWHERE_bin,
                    .scriptHeaderBank = NARC_scr_seq_scr_seq_0399_EVERYWHERE_hdr_bin,
                    .msgBank = NARC_msg_msg_0003_EVERYWHERE_bin,
                    .dayMusicId = SEQ_DUMMY,
                    .nightMusicId = SEQ_DUMMY,
                    .eventsBank = NARC_zone_event_000_DUMMY_bin,
                    .mapsec = MAPSEC_MYSTERY_ZONE,
                    .areaIcon = 6,
                    .momCallIntroParam = 10,
                    .regionNo = MAP_REGION_JOHTO,
                    .weather = 0,
                    .mapType = MAP_TYPE_ROUTE,
                    .cameraType = 0,
                    .followMode = MAP_FOLLOWMODE_PREVENT,
                    .battleBg = BATTLE_BG_FOREST,
                    .bikeAllowed = TRUE,
                    .runningAllowed_Unused = TRUE,
                    .escapeRopeAllowed = TRUE,
                    .flyAllowed = FALSE,
                    .outgoingCalls = FALSE,
                    .incomingCalls = FALSE,
                    .radioSignal = FALSE,
                },
                [MAP_NEW_BARK] = { .areaDataBank = 3, .worldMapX = 4, .worldMapY = 7, .weather = 1, .cameraType = 2, .bikeAllowed = FALSE },
                { .areaDataBank = 99 },
            };

            """,
            to: root.appendingPathComponent("src/data/map_headers.h")
        )

        return root
    }

    private func makeNDSBlackSourceProject(at root: URL) throws {
        try write("GAME_VERSION  ?= BLACK\nSUPPORTED_ROMS   := black.us\n", to: root.appendingPathComponent("config.mk"))
        try write("ROM            := pokeblack.nds\n", to: root.appendingPathComponent("Makefile"))
        try write("NitroROMSpec\n", to: root.appendingPathComponent("main.rsf"))
        try write("main linker script\n", to: root.appendingPathComponent("main.lsf"))
        try write("arm9 linker script\n", to: root.appendingPathComponent("arm9.ld"))
        try write("arm7 linker script\n", to: root.appendingPathComponent("arm7.ld"))
        try write("ffffffffffffffffffffffffffffffffffffffff  pokeblack.nds\n", to: root.appendingPathComponent("black.us/rom.sha1"))
        try write("void Init(void) {}\n", to: root.appendingPathComponent("src/init.c"))
        try write("arm9\n", to: root.appendingPathComponent("asm/arm9_remaining.s"))
        try write("#define BLACK 1\n", to: root.appendingPathComponent("include/globals.h"))
        try write("encounter\n", to: root.appendingPathComponent("data/encounters/route_1.txt"))
        try write("pokemon-source\n", to: root.appendingPathComponent("data/pokemon/source_pokemon.txt"))
        try write("moves-source\n", to: root.appendingPathComponent("data/moves/source_moves.txt"))
        try write("items-source\n", to: root.appendingPathComponent("data/items/source_items.txt"))
        try write("trainers-source\n", to: root.appendingPathComponent("data/trainers/source_trainers.txt"))
        try write("pokemon-source-inc\n", to: root.appendingPathComponent("src/data/pokemon/source_pokemon.inc"))
        try write("moves-source-inc\n", to: root.appendingPathComponent("src/data/moves/source_moves.inc"))
        try write("items-source-inc\n", to: root.appendingPathComponent("src/data/items/source_items.inc"))
        try write("trainers-source-inc\n", to: root.appendingPathComponent("src/data/trainers/source_trainers.inc"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/root.bin"))
        try write(Data([0x10]), to: root.appendingPathComponent("files/fielddata/mapmatrix/0001.bin"))
        try write(Data([0x11]), to: root.appendingPathComponent("files/fielddata/maptable/map.bin"))
        try write(Data([0x12]), to: root.appendingPathComponent("files/fielddata/script/scr_seq/0001.bin"))
        try write("{\"zone\":1}\n", to: root.appendingPathComponent("files/fielddata/eventdata/zone_event/zone_001.json"))
        try write(Data("SDAT".utf8), to: root.appendingPathComponent("files/wb_sound_data.sdat"))
        try write("Route 1 hello\n", to: root.appendingPathComponent("files/msgdata/story/message_bank.txt"))
        try write("Trainer message candidate\n", to: root.appendingPathComponent("files/msgdata/battle/trainer_messages.gmm"))
        try write(Data([0x10, 0x00, 0x00, 0x00]), to: root.appendingPathComponent("files/msgdata/msg/0001.bin"))
        try write("Alpha\nBeta\n", to: root.appendingPathComponent("files/msgdata/system/help.str"))
        try write(Data([0x30, 0x31, 0x32]), to: root.appendingPathComponent("files/msgdata/msg/msg_0099.msg"))
        try write(Data([0x20, 0x00, 0x00, 0x00]), to: root.appendingPathComponent("files/msgdata/system/msg_0002.dat"))
        try write("overlay\n", to: root.appendingPathComponent("overlays/overlay_93/source.s"))
        try write("config\n", to: root.appendingPathComponent("ndsdisasm_config/ARM9.cfg"))
    }

    private func makeTestFNT() -> Data {
        var rootEntries = Data()
        appendFNTFile("root.bin", to: &rootEntries)
        appendFNTFile("sound_data.sdat", to: &rootEntries)
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
        appendUInt16LE(2, to: &fnt)
        appendUInt16LE(0xF000, to: &fnt)
        fnt.append(rootEntries)
        fnt.append(childEntries)
        return fnt
    }

    private func makeTestNARC() -> Data {
        let payload = Data("NCLR".utf8) + Data([0x10, 0x00, 0x00, 0x00])
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

    private func appendFNTFile(_ name: String, to data: inout Data) {
        let bytes = Array(name.utf8)
        data.append(UInt8(bytes.count))
        data.append(contentsOf: bytes)
    }

    private func appendFNTDirectory(_ name: String, directoryID: UInt16, to data: inout Data) {
        let bytes = Array(name.utf8)
        data.append(UInt8(0x80 | bytes.count))
        data.append(contentsOf: bytes)
        appendUInt16LE(directoryID, to: &data)
    }

    private func writeASCII(_ string: String, into data: inout Data, at offset: Int, length: Int) {
        let bytes = Array(string.utf8.prefix(length))
        data.replaceSubrange(offset ..< (offset + bytes.count), with: bytes)
    }

    private func writeUInt16LE(_ value: UInt16, into data: inout Data, at offset: Int) {
        data[offset] = UInt8(value & 0xFF)
        data[offset + 1] = UInt8((value >> 8) & 0xFF)
    }

    private func writeUInt32LE(_ value: UInt32, into data: inout Data, at offset: Int) {
        data[offset] = UInt8(value & 0xFF)
        data[offset + 1] = UInt8((value >> 8) & 0xFF)
        data[offset + 2] = UInt8((value >> 16) & 0xFF)
        data[offset + 3] = UInt8((value >> 24) & 0xFF)
    }

    private func appendUInt16LE(_ value: UInt16, to data: inout Data) {
        data.append(UInt8(value & 0xFF))
        data.append(UInt8((value >> 8) & 0xFF))
    }

    private func appendUInt32LE(_ value: UInt32, to data: inout Data) {
        data.append(UInt8(value & 0xFF))
        data.append(UInt8((value >> 8) & 0xFF))
        data.append(UInt8((value >> 16) & 0xFF))
        data.append(UInt8((value >> 24) & 0xFF))
    }

    private func makeSourceIndexProject() throws -> URL {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url

        try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/pokenav"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/pokemon"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/trainers"), withIntermediateDirectories: true)
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try write(
            """
            const struct SpeciesInfo gSpeciesInfo[] =
            {
                [SPECIES_TREECKO] = { .baseHP = 40 },
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/species_info.h")
        )
        try write(
            """
            const struct Trainer gTrainers[] = {
                [TRAINER_TEST] = { .trainerName = _("TEST"), .party = NO_ITEM_DEFAULT_MOVES(sParty_Test) },
            };
            """,
            to: root.appendingPathComponent("src/data/trainers.h")
        )
        try write(
            """
            const struct Item gItems[] =
            {
                [ITEM_POTION] = { .name = _("POTION"), .itemId = ITEM_POTION, .price = 300 },
            };
            """,
            to: root.appendingPathComponent("src/data/items.h")
        )
        try write(
            """
            Test_EventScript::
                lock
                msgbox gText_Test
                release
                end
            """,
            to: root.appendingPathComponent("data/scripts/test.inc")
        )
        try write(
            """
            gText_Test::
                .string "A short source-index text block.$"
            """,
            to: root.appendingPathComponent("data/text/test.inc")
        )

        return root
    }

    private func makeTrainerProject() throws -> URL {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url

        try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include/constants"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/pokenav"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/pokemon"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/trainers"), withIntermediateDirectories: true)
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try write("const struct SpeciesInfo gSpeciesInfo[] = { [SPECIES_TREECKO] = { .baseHP = 40 }, };\n", to: root.appendingPathComponent("src/data/pokemon/species_info.h"))
        try write("const struct Item gItems[] = { [ITEM_POTION] = { .name = _(\"POTION\"), .itemId = ITEM_POTION, .price = 300 }, };\n", to: root.appendingPathComponent("src/data/items.h"))
        try writeTrainerConstants(at: root)
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

        return root
    }

    private func makePokemonProject() throws -> URL {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url

        try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include/constants"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/pokenav"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/pokemon"), withIntermediateDirectories: true)
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try writePokemonConstants(at: root)

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
                [SPECIES_GROVYLE] =
                {
                    .baseHP = 50,
                    .baseAttack = 65,
                    .baseDefense = 45,
                    .baseSpeed = 95,
                    .baseSpAttack = 85,
                    .baseSpDefense = 65,
                    .types = { TYPE_GRASS, TYPE_GRASS },
                    .catchRate = 45,
                    .expYield = 141,
                    .evYield_HP = 0,
                    .evYield_Attack = 0,
                    .evYield_Defense = 0,
                    .evYield_Speed = 2,
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
            const u16 *const gLevelUpLearnsets[] =
            {
                [SPECIES_TREECKO] = sTreeckoLevelUpLearnset,
                [SPECIES_GROVYLE] = sGrovyleLevelUpLearnset,
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/level_up_learnset_pointers.h")
        )
        try write(
            """
            static const u16 sTreeckoLevelUpLearnset[] = {
                LEVEL_UP_MOVE( 1, MOVE_POUND),
                LEVEL_UP_MOVE( 6, MOVE_ABSORB),
                LEVEL_UP_END
            };

            static const u16 sGrovyleLevelUpLearnset[] = {
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
                [SPECIES_TREECKO] = { .learnset = {
                    .BULLET_SEED = TRUE,
                    .CUT = TRUE,
                } },
                [SPECIES_GROVYLE] = { .learnset = {
                    .CUT = TRUE,
                } },
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/tmhm_learnsets.h")
        )
        try write(
            """
            static const u16 sEggMoveLearnsets[] = {
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

        return root
    }

    private func makeExpansionPokemonProject(
        includeLevelUpLearnsets: Bool = false,
        includeTMHMLearnsets: Bool = false,
        includeTutorLearnsets: Bool = false,
        includeEvolutionRows: Bool = false,
        includeEggMoves: Bool = false
    ) throws -> URL {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url

        try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include/constants"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics"), withIntermediateDirectories: true)
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try write("// Expansion marker\n", to: root.appendingPathComponent("include/constants/expansion.h"))
        try writePokemonConstants(at: root)
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
                    .friendship = STANDARD_FRIENDSHIP,
                    .growthRate = GROWTH_MEDIUM_SLOW,
                    .eggGroup1 = EGG_GROUP_MONSTER,
                    .eggGroup2 = EGG_GROUP_DRAGON,
                    .ability1 = ABILITY_OVERGROW,
                    .ability2 = ABILITY_NONE,
                    .hiddenAbility = ABILITY_CHLOROPHYLL,
                    .safariZoneFleeRate = 0,
                    .bodyColor = BODY_COLOR_GREEN,
                    .formSpeciesIdTable = sTreeckoFormSpeciesIdTable,
                    .formChangeTable = sTreeckoFormChangeTable,
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
        if includeLevelUpLearnsets || includeTMHMLearnsets || includeTutorLearnsets || includeEggMoves {
            try write(
                """
                {
                  "SPECIES_TREECKO": [
                    "MOVE_POUND",
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
        return root
    }

    private func makeRubyPokemonProject() throws -> URL {
        let temp = try MapEditorStoreTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url

        try write("GAME_VERSION ?= RUBY\n", to: root.appendingPathComponent("config.mk"))
        try write("placeholder\n", to: root.appendingPathComponent("ruby.sha1"))
        try write("all:\n\t@true\n", to: root.appendingPathComponent("Makefile"))
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try writePokemonConstants(at: root)
        try write(testPNGData(width: 64, height: 64, paletteColorCount: 16), to: root.appendingPathComponent("graphics/pokemon/treecko/front.png"))

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
                    .friendship = STANDARD_FRIENDSHIP,
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
                    .baseHP = 50,
                    .baseAttack = 65,
                    .baseDefense = 45,
                    .baseSpeed = 95,
                    .baseSpAttack = 85,
                    .baseSpDefense = 65,
                    .type1 = TYPE_GRASS,
                    .type2 = TYPE_GRASS,
                    .catchRate = 45,
                    .expYield = 141,
                    .evYield_HP = 0,
                    .evYield_Attack = 0,
                    .evYield_Defense = 0,
                    .evYield_Speed = 2,
                    .evYield_SpAttack = 0,
                    .evYield_SpDefense = 0,
                    .item1 = ITEM_NONE,
                    .item2 = ITEM_NONE,
                    .genderRatio = PERCENT_FEMALE(12.5),
                    .eggCycles = 20,
                    .friendship = STANDARD_FRIENDSHIP,
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
                LEVEL_UP_MOVE( 6, MOVE_ABSORB),
                LEVEL_UP_END
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/level_up_learnsets.h")
        )
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

        return root
    }

    private func writeTrainerConstants(at root: URL) throws {
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
            #define MOVE_NONE 0
            #define MOVE_POUND 1
            #define MOVE_ABSORB 2
            #define MOVE_EMBER 3
            #define MOVE_GROWL 4
            """,
            to: root.appendingPathComponent("include/constants/moves.h")
        )
        try write(
            """
            #define ITEM_NONE 0
            #define ITEM_POTION 1
            #define ITEM_SUPER_POTION 2
            #define ITEM_ORAN_BERRY 3
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

    private func writePokemonConstants(at root: URL) throws {
        try write(
            """
            #define SPECIES_NONE 0
            #define SPECIES_TREECKO 1
            #define SPECIES_GROVYLE 2
            #define SPECIES_TREECKO_MEGA 3
            #define SPECIES_TREECKO_PRIMAL 4
            """,
            to: root.appendingPathComponent("include/constants/species.h")
        )
        try write(
            """
            #define TYPE_NORMAL 0
            #define TYPE_GRASS 1
            #define TYPE_FIRE 2
            #define EGG_GROUP_NONE 0
            #define EGG_GROUP_MONSTER 1
            #define EGG_GROUP_DRAGON 2
            #define GROWTH_MEDIUM_SLOW 1
            #define GROWTH_FAST 2
            #define BODY_COLOR_RED 1
            #define BODY_COLOR_GREEN 2
            #define EVO_LEVEL 4
            #define EVO_ITEM 7
            #define FORM_CHANGE_BATTLE_MEGA_EVOLUTION 1
            #define FORM_CHANGE_ITEM_HOLD 2
            #define FLAG_MAKES_CONTACT (1 << 0)
            #define FLAG_PROTECT_AFFECTED (1 << 1)
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
            #define MOVE_NONE 0
            #define MOVE_POUND 1
            #define MOVE_ABSORB 2
            #define MOVE_CRUNCH 3
            #define MOVE_LEECH_SEED 4
            #define MOVE_FLASH 5
            #define MOVE_CUT 6
            #define MOVE_BULLET_SEED 7
            #define MOVE_FURY_CUTTER 8
            #define MOVE_MEGA_PUNCH 9
            #define MOVE_SWORD_DANCE 10
            #define MOVE_GROWL 11
            """,
            to: root.appendingPathComponent("include/constants/moves.h")
        )
        try write(
            """
            #define ITEM_NONE 0
            #define ITEM_POTION 1
            #define ITEM_TM09_BULLET_SEED 100
            #define ITEM_HM01_CUT 101
            #define ITEM_HM05_FLASH 105
            """,
            to: root.appendingPathComponent("include/constants/items.h")
        )
    }

    private func writeBattleMoveTable(to root: URL) throws {
        try write(
            """
            const struct BattleMove gBattleMoves[] =
            {
                [MOVE_NONE] =
                {
                    .effect = EFFECT_HIT,
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
                },
                [MOVE_ABSORB] =
                {
                    .effect = EFFECT_ABSORB,
                    .power = 20,
                    .type = TYPE_GRASS,
                    .accuracy = 100,
                    .pp = 25,
                    .secondaryEffectChance = 0,
                    .target = MOVE_TARGET_SELECTED,
                    .priority = 0,
                    .flags = FLAG_PROTECT_AFFECTED,
                },
                [MOVE_FLASH] =
                {
                    .effect = EFFECT_ACCURACY_DOWN,
                    .power = 0,
                    .type = TYPE_NORMAL,
                    .accuracy = 70,
                    .pp = 20,
                    .secondaryEffectChance = 0,
                    .target = MOVE_TARGET_SELECTED,
                    .priority = 0,
                    .flags = 0,
                },
            };
            """,
            to: root.appendingPathComponent("src/data/battle_moves.h")
        )
    }

    private func writeExpansionMoveInfoTable(to root: URL) throws {
        try write(
            """
            const struct MoveInfo gMovesInfo[] =
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
                    .description = sPoundDescription,
                    .contestCategory = CONTEST_CATEGORY_TOUGH,
                    .contestAppeal = 2,
                    .contestJam = 1,
                    .contestComboStarterId = COMBO_STARTER_POUND,
                    .contestComboMoves = { MOVE_ABSORB, MOVE_MEGA_PUNCH },
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

    private func writeExpansionItemInfoTable(
        to root: URL,
        includeUsageScalars: Bool = true,
        includeBehaviorScalars: Bool = true
    ) throws {
        var source = """
            const struct ItemInfo gItemsInfo[] =
            {
                [ITEM_POTION] =
                {
                    .name = ITEM_NAME("Potion"),
                    .price = 300,
            """
        if includeUsageScalars {
            source += """
                    .holdEffect = HOLD_EFFECT_NONE,
                    .holdEffectParam = 20,
            """
        }
        source += """
                    .description = COMPOUND_STRING(
                                    "Restores HP."),
            """
        if includeUsageScalars {
            source += """
                    .pocket = POCKET_ITEMS,
            """
        }
        source += """
                    .importance = 0,
                    .registrability = 0,
                    .sortType = ITEM_TYPE_HEALTH_RECOVERY,
            """
        if includeUsageScalars {
            source += """
                    .type = ITEM_USE_PARTY_MENU,
            """
        }
        source += """
                    .exitsBagOnUse = FALSE,
                    .effect = ITEM_EFFECT_HEAL,
            """
        if includeBehaviorScalars {
            source += """
                    .fieldUseFunc = ItemUseOutOfBattle_Medicine,
                    .battleUsage = EFFECT_ITEM_RESTORE_HP,
                    .battleUseFunc = NULL,
                    .secondaryId = 0,
            """
        }
        source += """
                    .iconPic = gItemIcon_Potion,
                    .iconPalette = gItemIconPalette_Potion,
                },
            };

            """
        try write(source, to: root.appendingPathComponent("src/data/items.h"))
    }

    private func writeRubyBattleMoveTable(to root: URL) throws {
        try write(
            """
            static const u8 gMoveDescription_None[] = _("No move.");
            const u8 gMoveDescription_Pound[] = _("Pounds the foe.");

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
                    .description = gMoveDescription_None,
                    .contestEffect = CONTEST_EFFECT_NONE,
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
                    .description = gMoveDescription_Pound,
                    .contestEffect = CONTEST_EFFECT_NONE,
                },
            };
            """,
            to: root.appendingPathComponent("src/data/battle_moves.c")
        )
    }

    private func writeRubyContestMoveTable(to root: URL) throws {
        try write(
            """
            const struct ContestMove gContestMoves[MOVES_COUNT] =
            {
                [MOVE_POUND] =
                {
                    .effect = CONTEST_EFFECT_HIGHLY_APPEALING,
                    .contestCategory = CONTEST_CATEGORY_TOUGH,
                    .comboStarterId = COMBO_STARTER_POUND,
                    .comboMoves = { COMBO_STARTER_GROWL },
                },
            };
            """,
            to: root.appendingPathComponent("src/data/contest_moves.h")
        )
    }

    private func writeRubyTrainerSources(to root: URL) throws {
        try write(
            """
            #define TRAINER_ENCOUNTER_MUSIC_MALE 1
            #define F_TRAINER_PARTY_CUSTOM_MOVESET 1 << 0
            #define F_TRAINER_PARTY_HELD_ITEM 1 << 1

            enum {
                TRAINER_PIC_HIKER,
                TRAINER_PIC_RIVAL,
            };

            enum {
                TRAINER_CLASS_PKMN_TRAINER_1,
                TRAINER_CLASS_RIVAL,
            };

            """,
            to: root.appendingPathComponent("include/constants/trainers.h")
        )
        try write(
            """
            const struct Trainer gTrainers[] = {
                [TRAINER_RUBY] =
                {
                    .partyFlags = F_TRAINER_PARTY_HELD_ITEM | F_TRAINER_PARTY_CUSTOM_MOVESET,
                    .trainerClass = TRAINER_CLASS_RIVAL,
                    .encounterMusic_gender = TRAINER_ENCOUNTER_MUSIC_MALE,
                    .trainerPic = TRAINER_PIC_HIKER,
                    .trainerName = _("RUBY"),
                    .items = {ITEM_NONE, ITEM_NONE, ITEM_NONE, ITEM_NONE},
                    .doubleBattle = FALSE,
                    .aiFlags = 0x7,
                    .partySize = 1,
                    .party = {.ItemCustomMoves = gTrainerParty_Ruby }
                },
            };

            """,
            to: root.appendingPathComponent("src/data/trainers_en.h")
        )
        try write(
            """
            const struct TrainerMonItemCustomMoves gTrainerParty_Ruby[] = {
                {
                    .iv = 40,
                    .level = 6,
                    .species = SPECIES_TREECKO,
                    .heldItem = ITEM_NONE,
                    .moves = MOVE_POUND, MOVE_ABSORB, MOVE_NONE, MOVE_NONE
                }
            };

            """,
            to: root.appendingPathComponent("src/data/trainer_parties.h")
        )
    }

    private func writeMapJSON(name: String, mapID: String, layoutID: String, to url: URL) throws {
        try write(
            """
            {
              "id": "\(mapID)",
              "name": "\(name)",
              "layout": "\(layoutID)",
              "music": "MUS_ROUTE",
              "region_map_section": "MAPSEC_ROUTE",
              "weather": "WEATHER_SUNNY",
              "map_type": "MAP_TYPE_ROUTE",
              "connections": [],
              "object_events": [
                {
                  "local_id": "LOCALID_ROUTE_NPC",
                  "type": "object",
                  "graphics_id": "OBJ_EVENT_GFX_BOY_1",
                  "x": 1,
                  "y": 1,
                  "elevation": 3,
                  "script": "\(name)_EventScript_NPC"
                }
              ],
              "warp_events": [],
              "coord_events": [],
              "bg_events": []
            }
            """,
            to: url
        )
    }

    private func writeWords(_ words: [UInt16], to url: URL) throws {
        var data = Data()
        for word in words {
            data.append(UInt8(word & 0x00FF))
            data.append(UInt8((word >> 8) & 0x00FF))
        }
        try write(data, to: url)
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
        let colors = (0 ..< colorCount).map { index -> String in
            let channel = (index * 8) % 256
            return "\(channel) \(channel) \(channel)"
        }
        return Data(("JASC-PAL\n0100\n\(colorCount)\n" + colors.joined(separator: "\n") + "\n").utf8)
    }

    private func writeBinaryMutationSyntheticGBA(to rom: URL) throws {
        var bytes = [UInt8](repeating: 0xFF, count: 0x240)
        bytes.replaceSubrange(0x04 ..< 0xA0, with: Array(repeating: 1, count: 0x9C))
        bytes.replaceSubrange(0xA0 ..< 0xAC, with: Array("POKEMON TEST".utf8))
        bytes.replaceSubrange(0xAC ..< 0xB0, with: Array("BPEE".utf8))
        bytes.replaceSubrange(0xB0 ..< 0xB2, with: Array("01".utf8))
        bytes[0x100] = 0x20
        bytes[0x101] = 0x01
        bytes[0x102] = 0x00
        bytes[0x103] = 0x08
        bytes[0x120] = 0x11
        bytes[0x121] = 0x22
        let headerSum = bytes[0xA0...0xBC].reduce(0) { ($0 + Int($1)) & 0xff }
        bytes[0xBD] = UInt8((0x19 - headerSum) & 0xff)
        try write(Data(bytes), to: rom)
    }

    private func writeBinaryMutationManifest(_ manifest: BinaryROMMutationDryRunManifest, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try write(encoder.encode(manifest), to: url)
    }

    private func writeMinimalEmeraldSourceTree(at root: URL) throws {
        try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("src"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/pokenav"), withIntermediateDirectories: true)
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
    }

    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func write(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }

    private func recursiveRelativeFiles(in root: URL) throws -> [String] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: []
        ) else {
            return []
        }
        var files: [String] = []
        for case let url as URL in enumerator {
            let values = try url.resourceValues(forKeys: [.isRegularFileKey])
            guard values.isRegularFile == true else { continue }
            files.append(String(url.standardizedFileURL.path.dropFirst(root.standardizedFileURL.path.count + 1)))
        }
        return files.sorted()
    }

    private func pokemonHackSHA1Hex(_ data: Data) -> String {
        Insecure.SHA1.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private func writeExecutable(_ text: String, to url: URL) throws {
        try write(text, to: url)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }

    @MainActor
    private func waitForBuildRunResult(_ store: WorkbenchStore) async throws -> BuildRunResultViewState {
        for _ in 0 ..< 100 {
            if let result = store.selectedBuildRunResult {
                return result
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTFail("Timed out waiting for build run result")
        throw NSError(domain: "MapEditorStoreTests", code: 1)
    }

    private func writeSyntheticGameCubeDisc(to url: URL) throws {
        var bytes = [UInt8](repeating: 0, count: 0x2400)
        replaceASCII("GC6E", at: 0x0, in: &bytes)
        replaceASCII("01", at: 0x4, in: &bytes)
        replaceASCII("POKEMON COLOSSEUM", at: 0x20, in: &bytes)
        writeBE32(0x1000, at: 0x420, in: &bytes)
        writeBE32(0x1800, at: 0x424, in: &bytes)

        let fsys = syntheticFSYSArchive()
        let fsysOffset = 0x2000
        bytes.replaceSubrange(fsysOffset ..< (fsysOffset + fsys.count), with: fsys)

        let names = Array("\0files\0common.fsys\0".utf8)
        let entryCount = 3
        let fstSize = entryCount * 12 + names.count
        writeBE32(UInt32(fstSize), at: 0x428, in: &bytes)

        var fst = [UInt8](repeating: 0, count: fstSize)
        writeBE32(0x0100_0000, at: 0, in: &fst)
        writeBE32(0, at: 4, in: &fst)
        writeBE32(UInt32(entryCount), at: 8, in: &fst)
        writeBE32(0x0100_0001, at: 12, in: &fst)
        writeBE32(0, at: 16, in: &fst)
        writeBE32(UInt32(entryCount), at: 20, in: &fst)
        writeBE32(0x0000_0007, at: 24, in: &fst)
        writeBE32(UInt32(fsysOffset), at: 28, in: &fst)
        writeBE32(UInt32(fsys.count), at: 32, in: &fst)
        fst.replaceSubrange((entryCount * 12) ..< fstSize, with: names)
        bytes.replaceSubrange(0x1800 ..< (0x1800 + fst.count), with: fst)

        try write(Data(bytes), to: url)
    }

    private func syntheticFSYSArchive() -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: 0x180)
        replaceASCII("common_rel.fdat", at: 0x10, in: &bytes)
        replaceASCII("msg_shop.bin", at: 0x30, in: &bytes)
        replaceASCII("LZSS", at: 0x80, in: &bytes)
        writeBE32(8, at: 0x84, in: &bytes)
        writeBE32(24, at: 0x88, in: &bytes)
        replaceASCII("POKEMON1", at: 0x90, in: &bytes)
        replaceASCII("LZSS", at: 0xB0, in: &bytes)
        writeBE32(8, at: 0xB4, in: &bytes)
        writeBE32(32, at: 0xB8, in: &bytes)
        replaceASCII("TEXTDATA", at: 0xC0, in: &bytes)
        return bytes
    }

    private func replaceASCII(_ string: String, at offset: Int, in bytes: inout [UInt8]) {
        let replacement = Array(string.utf8)
        bytes.replaceSubrange(offset ..< (offset + replacement.count), with: replacement)
    }

    private func writeBE32(_ value: UInt32, at offset: Int, in bytes: inout [UInt8]) {
        bytes[offset] = UInt8((value >> 24) & 0xFF)
        bytes[offset + 1] = UInt8((value >> 16) & 0xFF)
        bytes[offset + 2] = UInt8((value >> 8) & 0xFF)
        bytes[offset + 3] = UInt8(value & 0xFF)
    }

    private func makeBPSPatch(source: Data, target: Data) -> Data {
        var body = Data("BPS1".utf8)
        body.append(contentsOf: encodeBPSVariableLength(UInt64(source.count)))
        body.append(contentsOf: encodeBPSVariableLength(UInt64(target.count)))
        body.append(contentsOf: encodeBPSVariableLength(0))

        var prefixLength = 0
        let sourceBytes = Array(source)
        let targetBytes = Array(target)
        while prefixLength < min(sourceBytes.count, targetBytes.count),
              sourceBytes[prefixLength] == targetBytes[prefixLength]
        {
            prefixLength += 1
        }
        if prefixLength > 0 {
            body.append(contentsOf: encodeBPSVariableLength(UInt64((prefixLength - 1) << 2)))
        }
        if prefixLength < targetBytes.count {
            let length = targetBytes.count - prefixLength
            body.append(contentsOf: encodeBPSVariableLength(UInt64(((length - 1) << 2) | 1)))
            body.append(contentsOf: targetBytes[prefixLength...])
        }

        appendUInt32LE(crc32(source), to: &body)
        appendUInt32LE(crc32(target), to: &body)
        appendUInt32LE(crc32(body), to: &body)
        return body
    }

    private func encodeBPSVariableLength(_ value: UInt64) -> [UInt8] {
        var data = value
        var bytes: [UInt8] = []
        while true {
            let byte = UInt8(data & 0x7F)
            data >>= 7
            if data == 0 {
                bytes.append(byte | 0x80)
                break
            }
            bytes.append(byte)
            data -= 1
        }
        return bytes
    }

    private func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0 ..< 8 {
                let mask = 0 &- (crc & 1)
                crc = (crc >> 1) ^ (0xEDB8_8320 & mask)
            }
        }
        return ~crc
    }

    private static func syntheticAssetRow(index: Int) -> ResourceAssetRowViewState {
        let isMap = index.isMultiple(of: 2)
        let category = isMap ? "maps" : "items"
        let title = isMap ? "Map \(index)" : "Item \(index)"
        let availability = isMap ? "availableSource" : "optionalGeneratedMissing"
        return makeAssetRow(
            id: "asset-\(index)",
            title: title,
            path: "data/synthetic/\(category)/\(index).inc",
            category: category,
            kind: isMap ? "map" : "generated",
            role: isMap ? "source" : "generated",
            availability: availability,
            tags: [category, "needle-\(index)"],
            targetModule: isMap ? .maps : .items,
            targetID: title
        )
    }

    private static func makeAssetRow(
        id: String,
        title: String,
        path: String,
        category: String = "maps",
        kind: String = "source",
        role: String = "source",
        status: ValidationState = .valid,
        availability: String = "availableSource",
        affectsResourceAvailability: Bool = false,
        sourcePath: String? = nil,
        tags: [String] = [],
        facts: [Fact] = [],
        diagnostics: [IndexedDiagnosticRow] = [],
        targetModule: WorkbenchModule? = .maps,
        targetID: String? = nil
    ) -> ResourceAssetRowViewState {
        ResourceAssetRowViewState(
            id: id,
            title: title,
            subtitle: "Synthetic \(category)",
            path: path,
            category: category,
            kind: kind,
            role: role,
            status: status,
            availability: availability,
            availabilitySummary: availability == "availableSource" ? "Source available" : "Source missing",
            affectsResourceAvailability: affectsResourceAvailability,
            sizeSummary: "1 KB",
            checksumSummary: "Not checked",
            source: SourceLocation(path: sourcePath ?? path, symbol: title, line: 1),
            tags: tags,
            facts: facts,
            diagnostics: diagnostics,
            targetModule: targetModule,
            targetID: targetID,
            searchBlob: (
                [title, path, category, kind, role, availability, targetID ?? ""]
                    + tags
                    + facts.flatMap { [$0.label, $0.value] }
                    + diagnostics.flatMap { [$0.title, $0.message] }
            )
                .joined(separator: " ")
                .lowercased()
        )
    }

    private func factValue(_ label: String, in facts: [Fact]) -> String? {
        facts.first { $0.label == label }?.value
    }

    private func assertNoGenVSourceDataSemanticFacts(_ facts: [Fact], file: StaticString = #filePath, line: UInt = #line) {
        let semanticLabels = ["Base HP", "Catch Rate", "Power", "PP", "Price", "Party Count", "Decoded Strings", "Text Samples"]
        for label in semanticLabels {
            XCTAssertNil(factValue(label, in: facts), file: file, line: line)
        }
        XCTAssertFalse(facts.contains { $0.label.localizedCaseInsensitiveContains("Semantic") }, file: file, line: line)
    }
}

private extension Data {
    mutating func appendUInt32BE(_ value: UInt32) {
        append(UInt8((value >> 24) & 0xFF))
        append(UInt8((value >> 16) & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
        append(UInt8(value & 0xFF))
    }

    mutating func appendPNGChunk(type: String, payload: Data) {
        appendUInt32BE(UInt32(payload.count))
        append(contentsOf: type.utf8)
        append(payload)
        appendUInt32BE(0)
    }
}

private final class MapEditorStoreTemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackMapEditorStoreTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}

private enum StoreTestError: Error {
    case assetCatalogFailed(String)
    case assetCatalogTimedOut
    case resourceEntryTimedOut
    case sourceGraphFailed(String)
    case sourceGraphTimedOut
    case speciesCatalogFailed(String)
    case speciesCatalogTimedOut
    case trainerCatalogFailed(String)
    case trainerCatalogTimedOut
    case moveCatalogFailed(String)
    case moveCatalogTimedOut
    case itemCatalogFailed(String)
    case itemCatalogTimedOut
    case mapCatalogFailed(String)
    case mapCatalogTimedOut
    case mapVisualFailed(String)
    case mapVisualTimedOut
}
