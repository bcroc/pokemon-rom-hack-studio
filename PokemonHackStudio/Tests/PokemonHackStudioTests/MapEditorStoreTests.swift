import PokemonHackCore
import AppKit
import XCTest
@testable import PokemonHackStudio

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
        store.loadSelectedSpeciesCatalogIfNeeded()
        try await waitForSelectedSpeciesCatalog(store)
        store.requestSpeciesSelection("SPECIES_TREECKO")

        XCTAssertEqual(store.speciesCatalogLoadStatus, .loaded(2))
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
        XCTAssertTrue(store.canPreviewSelectedSpeciesMutationPlan)

        store.previewSelectedSpeciesMutationPlan()

        let plan = try XCTUnwrap(store.latestSpeciesEditPlan)
        XCTAssertEqual(
            plan.changes.map(\.path).sorted(),
            [
                "src/data/pokemon/egg_moves.h",
                "src/data/pokemon/level_up_learnsets.h",
                "src/data/pokemon/species_info.h",
                "src/data/pokemon/tmhm_learnsets.h"
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
        XCTAssertFalse(openedEntry.items.isEmpty)
        XCTAssertTrue(openedEntry.items.contains { $0.path == "Makefile" })
        XCTAssertTrue(store.filteredResourceLibraryEntries.contains { $0.path == root.path })
        XCTAssertNil(store.selectedAssetCatalog)
        XCTAssertEqual(store.assetCatalogLoadStatus, .idle)

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
        let mapAssetAction = try XCTUnwrap(mapFlow.secondaryActions.first)
        store.route(to: mapAssetAction)

        XCTAssertEqual(store.selection, .resources)
        XCTAssertEqual(store.resourceAssetCategory, "layouts")
        XCTAssertEqual(store.searchText, "layout")

        let pokemonFlow = try XCTUnwrap(store.guidedFlows.first { $0.id == "pokemon-data" })
        store.route(to: pokemonFlow.primaryAction)
        store.loadSelectedSpeciesCatalogIfNeeded()
        try await waitForSelectedSpeciesCatalog(store)

        XCTAssertEqual(store.selection, .pokemon)
        XCTAssertEqual(store.selectedSpeciesID, "SPECIES_TREECKO")

        let pokemonAssetAction = try XCTUnwrap(pokemonFlow.secondaryActions.first)
        store.route(to: pokemonAssetAction)

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

        let shipFlow = try XCTUnwrap(store.guidedFlows.first { $0.id == "ship-preview" })
        let patchAction = try XCTUnwrap(shipFlow.secondaryActions.first)
        store.route(to: patchAction)

        XCTAssertEqual(store.selection, .build)
        XCTAssertEqual(store.selectedBuildWorkbenchTab, .patch)
        XCTAssertEqual(store.searchText, "")

        let diagnosticsFlow = try XCTUnwrap(store.guidedFlows.first { $0.id == "diagnostics-triage" })
        store.selectedDiagnosticBucket = .generatedArtifacts
        store.route(to: diagnosticsFlow.primaryAction)

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
            )
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
            )
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
    func testResourceAssetFilteringHandlesLargeSyntheticCatalog() throws {
        let rows = (0..<50_000).map(Self.syntheticAssetRow)

        let searchResult = WorkbenchStore.filterAndSort(
            assetRows: rows,
            category: "items",
            searchText: "needle-49999",
            sortMode: .path
        )

        XCTAssertEqual(searchResult.map(\.id), ["asset-49999"])

        let mapRows = WorkbenchStore.filterAndSort(
            assetRows: rows,
            category: "maps",
            searchText: "",
            sortMode: .availability
        )

        XCTAssertEqual(mapRows.count, 25_000)
        XCTAssertTrue(mapRows.allSatisfy { $0.category == "maps" })
        XCTAssertTrue(mapRows.prefix(100).allSatisfy { $0.availability == "availableSource" })
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
        XCTAssertTrue(store.filteredPatchManifestRows.contains { $0.title == "Output artifact plan" && $0.detail.contains("apply/export writes remain disabled") })
        XCTAssertTrue(store.filteredPatchManifestRows.contains { $0.title == "Checksum expectations" && $0.subtitle.contains("base sha1 a9993e36") })
        XCTAssertTrue(store.filteredPatchManifestRows.contains { $0.title == "Header policy" && $0.subtitle == "preserve-selected-base-rom-header" })
        XCTAssertTrue(store.filteredPatchManifestRows.contains { $0.title == "mGBA launch preview" && $0.subtitle == "Launch disabled" })

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
        var bytes = [UInt8](repeating: 0xff, count: 0x200)
        bytes.replaceSubrange(0x04..<0xA0, with: Array(repeating: 1, count: 0x9C))
        bytes.replaceSubrange(0xA0..<0xAC, with: Array("POKEMON TEST".utf8))
        bytes.replaceSubrange(0xAC..<0xB0, with: Array("BPEE".utf8))
        bytes.replaceSubrange(0xB0..<0xB2, with: Array("01".utf8))
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
        XCTAssertEqual(actions.first { $0.id == "build-rom" }?.isEnabled, false)
        XCTAssertEqual(actions.first { $0.id == "apply-patch" }?.isPreviewLocked, true)

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
        XCTAssertTrue(result.artifacts.contains { $0.kind == "saveState" && $0.path.hasSuffix("/savestate.ss0") && $0.detail.contains("Created") })
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/playtests/pokeemerald/savestate-capture.log").path))
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
        for _ in 0..<100 {
            if let catalog = store.selectedMapCatalog {
                return catalog
            }
            if case .failed(let message) = store.mapCatalogStatus {
                throw StoreTestError.mapCatalogFailed(message)
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.mapCatalogTimedOut
    }

    @MainActor
    @discardableResult
    private func waitForSelectedMapVisual(_ store: WorkbenchStore, mapID: String) async throws -> MapVisualDocument {
        for _ in 0..<100 {
            if let document = store.selectedMapVisualDocument, document.mapID == mapID {
                return document
            }
            if case .failed(let message) = store.mapVisualStatus {
                throw StoreTestError.mapVisualFailed(message)
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.mapVisualTimedOut
    }

    @MainActor
    private func waitForSelectedAssetCatalog(_ store: WorkbenchStore) async throws -> ResourceAssetCatalogViewState {
        for _ in 0..<100 {
            if let catalog = store.selectedAssetCatalog {
                return catalog
            }
            if case .failed(let message) = store.assetCatalogLoadStatus {
                throw StoreTestError.assetCatalogFailed(message)
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.assetCatalogTimedOut
    }

    @MainActor
    @discardableResult
    private func waitForSelectedSourceGraph(_ store: WorkbenchStore) async throws -> ProjectSourceIndex {
        for _ in 0..<100 {
            if let sourceIndex = store.selectedSourceIndex {
                return sourceIndex
            }
            if case .failed(let message) = store.sourceGraphLoadStatus {
                throw StoreTestError.sourceGraphFailed(message)
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.sourceGraphTimedOut
    }

    @MainActor
    @discardableResult
    private func waitForSelectedSpeciesCatalog(_ store: WorkbenchStore) async throws -> ProjectSpeciesCatalog {
        for _ in 0..<100 {
            if let catalog = store.selectedSpeciesCatalog {
                return catalog
            }
            if case .failed(let message) = store.speciesCatalogLoadStatus {
                throw StoreTestError.speciesCatalogFailed(message)
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.speciesCatalogTimedOut
    }

    @MainActor
    @discardableResult
    private func waitForSelectedTrainerCatalog(_ store: WorkbenchStore) async throws -> ProjectTrainerCatalog {
        for _ in 0..<100 {
            if let catalog = store.selectedTrainerCatalog {
                return catalog
            }
            if case .failed(let message) = store.trainerCatalogLoadStatus {
                throw StoreTestError.trainerCatalogFailed(message)
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.trainerCatalogTimedOut
    }

    @MainActor
    @discardableResult
    private func waitForSelectedMoveCatalog(_ store: WorkbenchStore) async throws -> MoveCatalogViewState {
        for _ in 0..<100 {
            if let catalog = store.selectedMoveCatalog {
                return catalog
            }
            if case .failed(let message) = store.moveCatalogLoadStatus {
                throw StoreTestError.moveCatalogFailed(message)
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw StoreTestError.moveCatalogTimedOut
    }

    @MainActor
    @discardableResult
    private func waitForSelectedItemCatalog(_ store: WorkbenchStore) async throws -> ProjectItemCatalog {
        for _ in 0..<100 {
            if let catalog = store.selectedItemCatalog {
                return catalog
            }
            if case .failed(let message) = store.itemCatalogLoadStatus {
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
            data.append(UInt8(word & 0x00ff))
            data.append(UInt8((word >> 8) & 0x00ff))
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

    private func writeExecutable(_ text: String, to url: URL) throws {
        try write(text, to: url)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }

    private static func syntheticAssetRow(index: Int) -> ResourceAssetRowViewState {
        let isMap = index.isMultiple(of: 2)
        let category = isMap ? "maps" : "items"
        let title = isMap ? "Map \(index)" : "Item \(index)"
        let availability = isMap ? "availableSource" : "optionalGeneratedMissing"
        return ResourceAssetRowViewState(
            id: "asset-\(index)",
            title: title,
            subtitle: "Synthetic \(category)",
            path: "data/synthetic/\(category)/\(index).inc",
            category: category,
            kind: isMap ? "map" : "generated",
            role: isMap ? "source" : "generated",
            status: .valid,
            availability: availability,
            availabilitySummary: isMap ? "Source available" : "Optional generated output missing",
            affectsResourceAvailability: false,
            sizeSummary: "1 KB",
            checksumSummary: "Not checked",
            source: SourceLocation(path: "data/synthetic/\(category)/\(index).inc", symbol: title, line: 1),
            tags: [category, "needle-\(index)"],
            facts: [],
            diagnostics: [],
            targetModule: isMap ? .maps : .items,
            targetID: title,
            searchBlob: "\(title.lowercased()) data/synthetic/\(category)/\(index).inc \(category) needle-\(index)"
        )
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
