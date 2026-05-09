import AppKit
import Combine
import Foundation
import PokemonHackCore

private struct ResourceAssetRowsCache {
    let projectID: String
    let rowCount: Int
    let searchText: String
    let category: String
    let sortMode: ResourceAssetSortMode
    let rows: [ResourceAssetRowViewState]
}

private struct MapCatalogLoadPayload: Codable {
    let index: PokemonHackCore.ProjectIndex
    let catalog: PokemonHackCore.ProjectMapCatalog
}

private struct MapVisualLoadPayload: Codable {
    let sharedCache: PokemonHackCore.ProjectMapVisualSharedCache
    let document: PokemonHackCore.MapVisualDocument
}

private struct BuildPatchPlaytestReportExportPayload: Codable {
    let projectTitle: String?
    let rootPath: String?
    let profile: String?
    let status: String
    let buildRows: [BuildReportRowExportPayload]
    let patchManifest: PokemonHackCore.PatchManifestReport?
    let playtest: PlaytestReportExportPayload?
}

private struct BuildReportRowExportPayload: Codable {
    let section: String
    let title: String
    let subtitle: String
    let detail: String
    let status: String
    let path: String
    let symbol: String
    let tags: [String]
}

private struct PlaytestReportExportPayload: Codable {
    let emulator: String
    let romPath: String?
    let arguments: [String]
    let artifacts: [PlaytestArtifactExportPayload]
    let isRunnable: Bool
    let status: String
    let detail: String
}

private struct PlaytestArtifactExportPayload: Codable {
    let kind: String
    let path: String
    let detail: String
}

@MainActor
final class WorkbenchStore: ObservableObject {
    @Published var selection: WorkbenchModule = .dashboard
    @Published var selectedTargetID: BuildTarget.ID = "emerald-dev"
    @Published var selectedProjectID: IndexedProjectSummary.ID = ""
    @Published var selectedMapID: String = ""
    @Published var selectedSpeciesID: String = ""
    @Published var selectedTrainerID: String = ""
    @Published var selectedMoveID: String = ""
    @Published var selectedMoveWorkbenchFilter: MoveWorkbenchFilter = .all
    @Published var selectedResourceAssetID: ResourceAssetRowViewState.ID?
    @Published var selectedResourceLibraryEntryID: ResourceLibraryEntryViewState.ID = ""
    @Published var selectedResourceLibraryMode: ResourceLibraryMode = .assets
    @Published var selectedPatchPath: String = ""
    @Published var selectedBaseROMPath: String = ""
    @Published var scriptReadinessTargetMode: ScriptReadinessTargetMode = .map
    @Published var selectedScriptReadinessLabel: String = ""
    @Published var selectedScriptSourceID: String = ""
    @Published var selectedScriptLabelID: String = ""
    @Published var selectedScriptTextBlockID: String = ""
    @Published var selectedMapWorkbenchTab: MapWorkbenchTab = .overviewLayers
    @Published var selectedBuildWorkbenchTab: BuildWorkbenchTab = .build
    @Published var selectedBuildReportRowID: String = ""
    @Published var selectedGraphicsReportRowID: String = ""
    @Published var selectedDiagnosticBucket: DiagnosticSummaryBucket = .blockingErrors
    @Published var selectedDiagnosticRowID: String = ""
    @Published var selectedGuidedFlowID: String = ""
    @Published var selectedRecordIDsByModule: [WorkbenchModule: UUID] = [:]
    @Published var mapShowsPalette = true
    @Published var mapMetatileFilter = ""
    @Published var mapViewportRequest: MapCanvasViewportRequest?
    @Published var searchText = ""
    @Published var resourceAssetCategory = WorkbenchStore.allResourceAssetCategories
    @Published var resourceAssetSortMode: ResourceAssetSortMode = .category
    @Published var pendingMapNavigation: PendingMapNavigation?
    @Published private(set) var indexedProjects: [IndexedProjectSummary] = []
    @Published private(set) var projectIndexStatus: ProjectIndexLoadStatus = .idle
    @Published private(set) var selectedMapCatalog: MapCatalogViewState?
    @Published private(set) var mapCatalogStatus: MapCatalogLoadStatus = .idle
    @Published private(set) var mapEditorSession = MapEditorSession()
    @Published private(set) var mapVisualStatus: MapVisualLoadStatus = .idle
    @Published private(set) var recentProjectRoots: [String]
    @Published private(set) var resourceLibrary: ResourceLibraryViewState?
    @Published private(set) var selectedScriptReadinessReport: ScriptReadinessReportViewState?
    @Published private(set) var assetCatalogLoadStatus: ResourceAssetCatalogLoadStatus = .idle
    @Published private(set) var speciesCatalogLoadStatus: SpeciesCatalogLoadStatus = .idle
    @Published private(set) var trainerCatalogLoadStatus: TrainerCatalogLoadStatus = .idle
    @Published private(set) var moveCatalogLoadStatus: MoveCatalogLoadStatus = .idle
    @Published private(set) var patchManifestLoadStatus: PatchManifestLoadStatus = .idle
    @Published private(set) var selectedPatchManifestReport: PatchManifestReportViewState?
    @Published private(set) var latestSpeciesEditPlan: PokemonHackCore.SpeciesEditPlan?
    @Published private(set) var latestSpeciesApplyResult: PokemonHackCore.SpeciesApplyResult?
    @Published private(set) var latestTrainerEditPlan: PokemonHackCore.TrainerEditPlan?
    @Published private(set) var latestTrainerApplyResult: PokemonHackCore.TrainerApplyResult?
    @Published private var speciesDraftsByKey: [String: PokemonHackCore.SpeciesEditDraft] = [:]
    @Published private var trainerDraftsByKey: [String: PokemonHackCore.TrainerEditDraft] = [:]
    @Published private var playtestLaunchResultsByID: [String: PlaytestLaunchResultViewState] = [:]

    let userSettings: WorkbenchUserSettings
    let targets: [BuildTarget]
    let records: [WorkbenchRecord]
    let issues: [WorkbenchIssue]
    let buildSteps: [BuildStep]

    private let userDefaults: UserDefaults
    private let fileManager: FileManager
    private let toolResolver: ToolAvailabilityResolver
    private let workspaceRoot: URL
    private var projectIndexesByID: [String: PokemonHackCore.ProjectIndex] = [:]
    private var sourceIndexesByID: [String: PokemonHackCore.ProjectSourceIndex] = [:]
    private var scriptOutlinesByID: [String: PokemonHackCore.ProjectScriptOutline] = [:]
    private var buildReportsByID: [String: BuildPatchPlaytestReportViewState] = [:]
    private var rawPatchManifestReport: PokemonHackCore.PatchManifestReport?
    private var graphicsReportsByID: [String: GraphicsDiagnosticsReportViewState] = [:]
    private var scriptReadinessReportsByID: [String: ScriptReadinessReportViewState] = [:]
    private var speciesCatalogsByID: [String: PokemonHackCore.ProjectSpeciesCatalog] = [:]
    private var trainerCatalogsByID: [String: PokemonHackCore.ProjectTrainerCatalog] = [:]
    private var moveCatalogsByID: [String: MoveCatalogViewState] = [:]
    private var assetCatalogsByID: [String: ResourceAssetCatalogViewState] = [:]
    private var assetCatalogFingerprintsByID: [String: String] = [:]
    private var assetCatalogTask: Task<Void, Never>?
    private var mapCatalogTask: Task<Void, Never>?
    private var mapVisualTask: Task<Void, Never>?
    private var mapVisualSharedCacheDataByID: [String: Data] = [:]
    private var resourceAssetRowsCache: ResourceAssetRowsCache?
    private var pendingRelatedMapTargetID: String?
    private var pendingResourceAssetFocus: String?
    private var settingsCancellable: AnyCancellable?

    private static let recentRootsKey = "PokemonHackStudio.recentProjectRoots"
    static let allResourceAssetCategories = "All"

    init(
        userDefaults: UserDefaults = .standard,
        userSettings: WorkbenchUserSettings? = nil,
        fileManager: FileManager = .default,
        toolResolver: @escaping ToolAvailabilityResolver = ToolAvailabilityResolverFactory.pathEnvironment(),
        autoLoadProjects: Bool = true
    ) {
        self.userDefaults = userDefaults
        self.userSettings = userSettings ?? WorkbenchUserSettings(defaults: userDefaults)
        self.fileManager = fileManager
        self.toolResolver = toolResolver
        workspaceRoot = Self.inferredWorkspaceRoot()
        recentProjectRoots = userDefaults.stringArray(forKey: Self.recentRootsKey) ?? []

        targets = FixtureData.targets
        records = FixtureData.records
        issues = FixtureData.issues
        buildSteps = FixtureData.buildSteps

        settingsCancellable = self.userSettings.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }

        if autoLoadProjects && self.userSettings.autoLoadProjects {
            DispatchQueue.main.async { [weak self] in
                self?.refreshProjectIndexes()
            }
        }
    }

    var selectedTarget: BuildTarget {
        targets.first { $0.id == selectedTargetID } ?? targets[0]
    }

    var selectedIndexedProject: IndexedProjectSummary? {
        indexedProjects.first { $0.id == selectedProjectID } ?? indexedProjects.first
    }

    var selectedSourceIndex: PokemonHackCore.ProjectSourceIndex? {
        guard let selectedIndexedProject else { return nil }
        return sourceIndexesByID[selectedIndexedProject.id]
    }

    var selectedScriptOutline: PokemonHackCore.ProjectScriptOutline? {
        guard let selectedIndexedProject else { return nil }
        return scriptOutlinesByID[selectedIndexedProject.id]
    }

    var selectedSpeciesCatalog: PokemonHackCore.ProjectSpeciesCatalog? {
        guard let selectedIndexedProject else { return nil }
        return speciesCatalogsByID[selectedIndexedProject.id]
    }

    var selectedTrainerCatalog: PokemonHackCore.ProjectTrainerCatalog? {
        guard let selectedIndexedProject else { return nil }
        return trainerCatalogsByID[selectedIndexedProject.id]
    }

    var selectedMoveCatalog: MoveCatalogViewState? {
        guard let selectedIndexedProject else { return nil }
        return moveCatalogsByID[selectedIndexedProject.id]
    }

    var filteredMoveDetails: [MoveDetailViewState] {
        guard let catalog = selectedMoveCatalog else { return [] }
        let filteredByMode: [MoveDetailViewState]
        switch selectedMoveWorkbenchFilter {
        case .all:
            filteredByMode = catalog.moves
        case .tmhm:
            filteredByMode = catalog.moves.filter { !$0.tmhmLearners.isEmpty }
        case .tutor:
            filteredByMode = catalog.moves.filter { !$0.tutorLearners.isEmpty }
        case .learnedBy:
            filteredByMode = catalog.moves.filter { $0.learnerCount > 0 }
        case .diagnostics:
            filteredByMode = catalog.moves.filter { !$0.diagnostics.isEmpty }
        }
        guard !searchText.isEmpty else { return filteredByMode }
        let needle = searchText.lowercased()
        return filteredByMode.filter { $0.searchBlob.contains(needle) }
    }

    var selectedMoveDetail: MoveDetailViewState? {
        guard let catalog = selectedMoveCatalog else { return nil }
        if let selected = filteredMoveDetails.first(where: { $0.moveID == selectedMoveID }) {
            return selected
        }
        return filteredMoveDetails.first ?? catalog.moves.first
    }

    var filteredSpeciesDetails: [PokemonHackCore.SpeciesDetail] {
        guard let catalog = selectedSpeciesCatalog else { return [] }
        guard !searchText.isEmpty else { return catalog.species }
        let needle = searchText.lowercased()
        return catalog.species.filter { species in
            Self.speciesSearchBlob(species).contains(needle)
        }
    }

    var selectedSpeciesDetail: PokemonHackCore.SpeciesDetail? {
        guard let catalog = selectedSpeciesCatalog else { return nil }
        if let selected = catalog.species.first(where: { $0.speciesID == selectedSpeciesID }) {
            return selected
        }
        return Self.defaultEditableSpecies(in: filteredSpeciesDetails)
            ?? Self.defaultEditableSpecies(in: catalog.species)
            ?? catalog.species.first
    }

    var selectedSpeciesDraft: PokemonHackCore.SpeciesEditDraft? {
        guard let detail = selectedSpeciesDetail else { return nil }
        if let selectedIndexedProject {
            let key = speciesDraftKey(projectID: selectedIndexedProject.id, speciesID: detail.speciesID)
            if let draft = speciesDraftsByKey[key] {
                return draft
            }
        }
        return PokemonHackCore.SpeciesEditDraft(detail: detail)
    }

    var selectedSpeciesIsDirty: Bool {
        guard
            let selectedIndexedProject,
            let detail = selectedSpeciesDetail,
            let baseDraft = PokemonHackCore.SpeciesEditDraft(detail: detail)
        else {
            return false
        }
        let key = speciesDraftKey(projectID: selectedIndexedProject.id, speciesID: detail.speciesID)
        guard let draft = speciesDraftsByKey[key] else { return false }
        return draft != baseDraft
    }

    var canPreviewSelectedSpeciesMutationPlan: Bool {
        selectedSpeciesIsDirty && selectedSpeciesDraft != nil
    }

    var canApplySelectedSpeciesMutationPlan: Bool {
        latestSpeciesEditPlan?.validateApplyability(fileManager: fileManager).isApplyable == true
    }

    var canDiscardSpeciesEdits: Bool {
        selectedSpeciesIsDirty || latestSpeciesEditPlan != nil || latestSpeciesApplyResult != nil
    }

    var speciesPreviewBlockedReason: String? {
        guard selectedSpeciesCatalog != nil else { return "Load a Pokemon catalog before previewing edits." }
        guard selectedSpeciesDetail != nil else { return "Select a Pokemon before previewing edits." }
        guard selectedSpeciesDraft != nil else { return "This Pokemon source shape is read-only." }
        guard selectedSpeciesIsDirty else { return "Change Pokemon data before previewing a mutation plan." }
        return nil
    }

    var speciesApplyBlockedReason: String? {
        guard let plan = latestSpeciesEditPlan else { return "Preview Pokemon mutations before applying." }
        let applyability = plan.validateApplyability(fileManager: fileManager)
        if applyability.isApplyable {
            return nil
        }
        return applyability.diagnostics.first?.message ?? "Resolve Pokemon mutation diagnostics before applying."
    }

    var filteredTrainerDetails: [PokemonHackCore.TrainerDetail] {
        guard let catalog = selectedTrainerCatalog else { return [] }
        guard !searchText.isEmpty else { return catalog.trainers }
        let needle = searchText.lowercased()
        return catalog.trainers.filter { trainer in
            Self.trainerSearchBlob(trainer).contains(needle)
        }
    }

    var selectedTrainerDetail: PokemonHackCore.TrainerDetail? {
        guard let catalog = selectedTrainerCatalog else { return nil }
        if let selected = catalog.trainers.first(where: { $0.trainerID == selectedTrainerID }) {
            return selected
        }
        return Self.defaultEditableTrainer(in: filteredTrainerDetails)
            ?? Self.defaultEditableTrainer(in: catalog.trainers)
            ?? catalog.trainers.first
    }

    var selectedTrainerDraft: PokemonHackCore.TrainerEditDraft? {
        guard let detail = selectedTrainerDetail else { return nil }
        if let selectedIndexedProject {
            let key = trainerDraftKey(projectID: selectedIndexedProject.id, trainerID: detail.trainerID)
            if let draft = trainerDraftsByKey[key] {
                return draft
            }
        }
        return PokemonHackCore.TrainerEditDraft(detail: detail)
    }

    var selectedTrainerIsDirty: Bool {
        guard
            let selectedIndexedProject,
            let detail = selectedTrainerDetail,
            let baseDraft = PokemonHackCore.TrainerEditDraft(detail: detail)
        else {
            return false
        }
        let key = trainerDraftKey(projectID: selectedIndexedProject.id, trainerID: detail.trainerID)
        guard let draft = trainerDraftsByKey[key] else { return false }
        return draft != baseDraft
    }

    var canPreviewSelectedTrainerMutationPlan: Bool {
        selectedTrainerIsDirty && selectedTrainerDraft != nil
    }

    var canApplySelectedTrainerMutationPlan: Bool {
        latestTrainerEditPlan?.validateApplyability(fileManager: fileManager).isApplyable == true
    }

    var canDiscardTrainerEdits: Bool {
        selectedTrainerIsDirty || latestTrainerEditPlan != nil || latestTrainerApplyResult != nil
    }

    var trainerPreviewBlockedReason: String? {
        guard selectedTrainerCatalog != nil else { return "Load a trainer catalog before previewing edits." }
        guard selectedTrainerDetail != nil else { return "Select a trainer before previewing edits." }
        guard selectedTrainerDraft != nil else { return "This trainer source shape is read-only." }
        guard selectedTrainerIsDirty else { return "Change trainer data before previewing a mutation plan." }
        return nil
    }

    var trainerApplyBlockedReason: String? {
        guard let plan = latestTrainerEditPlan else { return "Preview trainer mutations before applying." }
        let applyability = plan.validateApplyability(fileManager: fileManager)
        if applyability.isApplyable {
            return nil
        }
        return applyability.diagnostics.first?.message ?? "Resolve trainer mutation diagnostics before applying."
    }

    var selectedBuildReport: BuildPatchPlaytestReportViewState? {
        guard let selectedIndexedProject else { return nil }
        guard let report = buildReportsByID[selectedIndexedProject.id] else { return nil }
        return reportApplyingSettings(report)
    }

    var selectedRawBuildReport: BuildPatchPlaytestReportViewState? {
        guard let selectedIndexedProject else { return nil }
        return buildReportsByID[selectedIndexedProject.id]
    }

    var selectedPlaytestLaunchResult: PlaytestLaunchResultViewState? {
        guard let selectedIndexedProject else { return nil }
        return playtestLaunchResultsByID[selectedIndexedProject.id]
    }

    var canLaunchSelectedPlaytest: Bool {
        selectedBuildReport?.playtest.isRunnable == true
    }

    func buildWorkflowActions(includePatchActions: Bool) -> [BuildWorkflowActionViewState] {
        Self.buildWorkflowActions(
            canLaunchPlaytest: canLaunchSelectedPlaytest,
            includePatchActions: includePatchActions
        )
    }

    var fixtureBuildWorkflowActions: [BuildWorkflowActionViewState] {
        Self.buildWorkflowActions(canLaunchPlaytest: false, includePatchActions: false)
            .map { action in
                BuildWorkflowActionViewState(
                    id: action.id,
                    title: action.title,
                    systemImage: action.systemImage,
                    isEnabled: false,
                    isPreviewLocked: true
                )
            }
    }

    var baseROMOptions: [BaseROMOptionViewState] {
        let projectOptions = selectedRawBuildReport?.baseROMOptions ?? []
        let resourceOptions = (resourceLibrary?.entries ?? [])
            .filter { $0.platform == GenIIIResourcePlatform.gbaROM.rawValue }
            .map(Self.baseROMOption(fromResourceEntry:))
        return uniqueBaseROMOptions(projectOptions + resourceOptions)
    }

    var selectedGraphicsReport: GraphicsDiagnosticsReportViewState? {
        guard let selectedIndexedProject else { return nil }
        return graphicsReportsByID[selectedIndexedProject.id]
    }

    var selectedAssetCatalog: ResourceAssetCatalogViewState? {
        guard let selectedIndexedProject else { return nil }
        return assetCatalogsByID[selectedIndexedProject.id]
    }

    var selectedDiagnosticRows: [IndexedDiagnosticRow] {
        guard let selectedIndexedProject else { return [] }
        let sourceDiagnostics = selectedSourceIndex?.diagnostics.map {
            Self.diagnostic(from: $0, rootPath: selectedIndexedProject.rootPath)
        } ?? []
        let buildDiagnostics = (selectedBuildReport?.diagnostics ?? [])
            .filter(userSettings.shouldShowHealthDiagnosticInGlobalIssues)
        let patchDiagnostics = selectedPatchManifestReport?.diagnostics ?? []
        let scriptReadinessDiagnostics = selectedScriptReadinessReport?.diagnostics ?? []
        let graphicsDiagnostics = selectedGraphicsReport?.diagnostics ?? []
        let speciesDiagnostics = selectedSpeciesCatalog?.diagnostics.map {
            Self.diagnostic(from: $0, rootPath: selectedIndexedProject.rootPath)
        } ?? []
        let trainerDiagnostics = selectedTrainerCatalog?.diagnostics.map {
            Self.diagnostic(from: $0, rootPath: selectedIndexedProject.rootPath)
        } ?? []
        let moveDiagnostics = selectedMoveCatalog?.diagnostics ?? []
        let resourceDiagnostics = resourceLibrary?.allDiagnostics ?? []
        let assetDiagnostics = selectedAssetCatalog?.diagnostics ?? []
        return selectedIndexedProject.diagnostics
            + sourceDiagnostics
            + buildDiagnostics
            + patchDiagnostics
            + scriptReadinessDiagnostics
            + graphicsDiagnostics
            + speciesDiagnostics
            + trainerDiagnostics
            + moveDiagnostics
            + resourceDiagnostics
            + assetDiagnostics
    }

    var hasIndexedProjects: Bool {
        !indexedProjects.isEmpty
    }

    var issueCount: Int {
        if selectedIndexedProject != nil {
            return selectedDiagnosticRows.count
        }
        return issues.count
    }

    var hasStagedMapEdits: Bool {
        mapEditorSession.isDirty
    }

    var selectedMapVisualDocument: PokemonHackCore.MapVisualDocument? {
        mapEditorSession.selectedMapVisualDocument
    }

    var selectedMapTool: MapEditorTool {
        get { mapEditorSession.selectedMapTool }
        set { mapEditorSession.selectedMapTool = newValue }
    }

    var mapOverlaySettings: MapOverlaySettings {
        get { mapEditorSession.mapOverlaySettings }
        set { mapEditorSession.mapOverlaySettings = newValue }
    }

    var selectedBrushRawValue: UInt16? {
        mapEditorSession.selectedBrushRawValue
    }

    var selectedMapCell: MapCellSelection? {
        mapEditorSession.selectedMapCell
    }

    var selectedMapEventID: String? {
        mapEditorSession.selectedMapEventID
    }

    var stagedMapBlockdataValues: [UInt16] {
        mapEditorSession.stagedMapBlockdataValues
    }

    var stagedMapEvents: [PokemonHackCore.MapEventDescriptor] {
        mapEditorSession.stagedMapEvents
    }

    var mapEditOperations: [PokemonHackCore.MapEditOperation] {
        mapEditorSession.mapEditOperations
    }

    var undoneMapEditOperations: [PokemonHackCore.MapEditOperation] {
        mapEditorSession.undoneMapEditOperations
    }

    var latestMapEditPlan: PokemonHackCore.MapEditPlan? {
        mapEditorSession.latestMapEditPlan
    }

    var latestMapApplyResult: PokemonHackCore.MapApplyResult? {
        mapEditorSession.latestMapApplyResult
    }

    var filteredBuildReportRows: [BuildReportRow] {
        guard let selectedBuildReport else { return [] }
        return filter(buildRows: selectedBuildReport.rows)
    }

    var filteredPatchManifestRows: [BuildReportRow] {
        guard let selectedPatchManifestReport else { return [] }
        return filter(buildRows: selectedPatchManifestReport.rows)
    }

    var filteredScriptReadinessRows: [ScriptReadinessReportRow] {
        guard let selectedScriptReadinessReport else { return [] }
        return filter(scriptReadinessRows: selectedScriptReadinessReport.rows)
    }

    var filteredGraphicsReportRows: [GraphicsReportRow] {
        guard let selectedGraphicsReport else { return [] }
        return filter(graphicsRows: selectedGraphicsReport.rows)
    }

    var filteredResourceLibraryEntries: [ResourceLibraryEntryViewState] {
        guard let resourceLibrary else { return [] }
        return filter(resourceEntries: resourceLibrary.entries)
    }

    var filteredResourceAssetRows: [ResourceAssetRowViewState] {
        guard let selectedIndexedProject, let selectedAssetCatalog else { return [] }
        if
            let cache = resourceAssetRowsCache,
            cache.projectID == selectedIndexedProject.id,
            cache.rowCount == selectedAssetCatalog.rows.count,
            cache.searchText == searchText,
            cache.category == resourceAssetCategory,
            cache.sortMode == resourceAssetSortMode
        {
            return cache.rows
        }

        let rows = Self.filterAndSort(
            assetRows: selectedAssetCatalog.rows,
            category: resourceAssetCategory,
            searchText: searchText,
            sortMode: resourceAssetSortMode
        )
        resourceAssetRowsCache = ResourceAssetRowsCache(
            projectID: selectedIndexedProject.id,
            rowCount: selectedAssetCatalog.rows.count,
            searchText: searchText,
            category: resourceAssetCategory,
            sortMode: resourceAssetSortMode,
            rows: rows
        )
        return rows
    }

    var filteredScriptOutlineSources: [PokemonHackCore.ScriptOutlineSource] {
        guard let selectedScriptOutline else { return [] }
        guard !searchText.isEmpty else { return selectedScriptOutline.sources }

        return selectedScriptOutline.sources.filter { source in
            source.path.localizedCaseInsensitiveContains(searchText)
                || source.module.rawValue.localizedCaseInsensitiveContains(searchText)
                || source.role.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var filteredScriptOutlineLabels: [PokemonHackCore.ScriptOutlineLabel] {
        guard let selectedScriptOutline else { return [] }
        guard !searchText.isEmpty else { return selectedScriptOutline.labels }

        return selectedScriptOutline.labels.filter { label in
            label.label.localizedCaseInsensitiveContains(searchText)
                || label.sourcePath.localizedCaseInsensitiveContains(searchText)
                || label.kind.rawValue.localizedCaseInsensitiveContains(searchText)
                || label.textReferences.contains { $0.localizedCaseInsensitiveContains(searchText) }
                || label.commands.contains {
                    $0.name.localizedCaseInsensitiveContains(searchText)
                        || $0.arguments.localizedCaseInsensitiveContains(searchText)
                }
        }
    }

    var filteredScriptTextBlocks: [PokemonHackCore.ScriptTextBlock] {
        guard let selectedScriptOutline else { return [] }
        guard !searchText.isEmpty else { return selectedScriptOutline.textBlocks }

        return selectedScriptOutline.textBlocks.filter { block in
            block.label.localizedCaseInsensitiveContains(searchText)
                || block.sourcePath.localizedCaseInsensitiveContains(searchText)
                || block.preview.localizedCaseInsensitiveContains(searchText)
        }
    }

    var selectedResourceAsset: ResourceAssetRowViewState? {
        if let selectedResourceAssetID,
           let selected = filteredResourceAssetRows.first(where: { $0.id == selectedResourceAssetID })
        {
            return selected
        }
        if let selectedResourceAssetID,
           let selected = selectedAssetCatalog?.rows.first(where: { $0.id == selectedResourceAssetID })
        {
            return selected
        }
        return filteredResourceAssetRows.first ?? selectedAssetCatalog?.rows.first
    }

    var selectedResourceLibraryEntry: ResourceLibraryEntryViewState? {
        if let selected = filteredResourceLibraryEntries.first(where: { $0.id == selectedResourceLibraryEntryID }) {
            return selected
        }
        return filteredResourceLibraryEntries.first ?? resourceLibrary?.entries.first
    }

    var selectedScriptSource: PokemonHackCore.ScriptOutlineSource? {
        if let selected = filteredScriptOutlineSources.first(where: { $0.id == selectedScriptSourceID }) {
            return selected
        }
        return filteredScriptOutlineSources.first ?? selectedScriptOutline?.sources.first
    }

    var selectedScriptLabel: PokemonHackCore.ScriptOutlineLabel? {
        if let selected = filteredScriptOutlineLabels.first(where: { $0.id == selectedScriptLabelID }) {
            return selected
        }
        return filteredScriptOutlineLabels.first ?? selectedScriptOutline?.labels.first
    }

    var selectedScriptTextBlock: PokemonHackCore.ScriptTextBlock? {
        if let selected = filteredScriptTextBlocks.first(where: { $0.id == selectedScriptTextBlockID }) {
            return selected
        }
        return filteredScriptTextBlocks.first ?? selectedScriptOutline?.textBlocks.first
    }

    var filteredBuildRowsForSelectedTab: [BuildReportRow] {
        switch selectedBuildWorkbenchTab {
        case .build:
            return filteredBuildReportRows.filter { $0.section != .diagnostics && $0.section != .patchManifest }
        case .patch:
            return filteredPatchManifestRows
        case .playtest:
            guard let selectedBuildReport else { return [] }
            return [BuildReportRow(playtest: selectedBuildReport.playtest)]
        }
    }

    var selectedBuildReportRow: BuildReportRow? {
        if let selected = filteredBuildRowsForSelectedTab.first(where: { $0.id == selectedBuildReportRowID }) {
            return selected
        }
        return filteredBuildRowsForSelectedTab.first
    }

    var selectedGraphicsReportRow: GraphicsReportRow? {
        if let selected = filteredGraphicsReportRows.first(where: { $0.id == selectedGraphicsReportRowID }) {
            return selected
        }
        return filteredGraphicsReportRows.first
    }

    var selectedDiagnosticBucketSummary: DiagnosticBucketSummary {
        diagnosticSummary.bucket(selectedDiagnosticBucket)
    }

    var selectedDiagnosticRow: IndexedDiagnosticRow? {
        if let selected = selectedDiagnosticBucketSummary.diagnostics.first(where: { $0.id == selectedDiagnosticRowID }) {
            return selected
        }
        if let selected = selectedDiagnosticRows.first(where: { $0.id == selectedDiagnosticRowID }) {
            return selected
        }
        return selectedDiagnosticBucketSummary.diagnostics.first ?? selectedDiagnosticRows.first
    }

    func selectedRecord(for module: WorkbenchModule) -> WorkbenchRecord? {
        let moduleRecords = records(for: module)
        if let selectedID = selectedRecordIDsByModule[module],
           let selected = moduleRecords.first(where: { $0.id == selectedID })
        {
            return selected
        }
        return moduleRecords.first
    }

    func records(for module: WorkbenchModule) -> [WorkbenchRecord] {
        if let sourceRecords = liveRecords(for: module), !sourceRecords.isEmpty {
            return filter(records: sourceRecords)
        }

        let moduleRecords = records.filter { $0.module == module }
        return filter(records: moduleRecords)
    }

    private func filter(records: [WorkbenchRecord]) -> [WorkbenchRecord] {
        guard !searchText.isEmpty else { return records }

        return records.filter { record in
            record.title.localizedCaseInsensitiveContains(searchText)
                || record.subtitle.localizedCaseInsensitiveContains(searchText)
                || record.source.path.localizedCaseInsensitiveContains(searchText)
                || record.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private func reportApplyingSettings(_ report: BuildPatchPlaytestReportViewState) -> BuildPatchPlaytestReportViewState {
        let visibleHealthRows = report.healthMatrix.rows.filter { row in
            userSettings.shouldShowHealthRow(category: row.healthCategory, status: row.healthStatus)
        }
        let healthMatrix = Self.healthMatrixApplyingSettings(report.healthMatrix, rows: visibleHealthRows)
        let states = report.buildTargets.map(\.status)
            + report.generatedArtifacts.map(\.status)
            + report.toolchain.rows.map(\.status)
            + healthMatrix.rows.map(\.status)
            + [report.toolchain.status, healthMatrix.status, report.playtest.status]
            + report.diagnostics.map(\.severity)

        return BuildPatchPlaytestReportViewState(
            id: report.id,
            projectTitle: report.projectTitle,
            rootPath: report.rootPath,
            profile: report.profile,
            status: Self.validationStatus(for: states),
            buildTargets: report.buildTargets,
            generatedArtifacts: report.generatedArtifacts,
            toolchain: report.toolchain,
            healthMatrix: healthMatrix,
            playtest: report.playtest,
            baseROMOptions: report.baseROMOptions,
            diagnostics: report.diagnostics
        )
    }

    private static func healthMatrixApplyingSettings(
        _ matrix: ToolchainHealthMatrixViewState,
        rows: [BuildReportRow]
    ) -> ToolchainHealthMatrixViewState {
        let ready = rows.filter { $0.healthStatus == .ready }.count
        let warnings = rows.filter { $0.healthStatus == .warning }.count
        let errors = rows.filter { $0.healthStatus == .error }.count
        let notApplicable = rows.filter { $0.healthStatus == .notApplicable }.count
        let status = validationStatus(for: rows.map(\.status))

        return ToolchainHealthMatrixViewState(
            id: matrix.id,
            status: status,
            detail: "Visible health matrix: \(ready) ready, \(warnings) warning, \(errors) error, \(notApplicable) not applicable.",
            readyCount: ready,
            warningCount: warnings,
            errorCount: errors,
            notApplicableCount: notApplicable,
            rows: rows
        )
    }

    private func filter(buildRows: [BuildReportRow]) -> [BuildReportRow] {
        guard !searchText.isEmpty else { return buildRows }

        return buildRows.filter { row in
            row.section.rawValue.localizedCaseInsensitiveContains(searchText)
                || row.title.localizedCaseInsensitiveContains(searchText)
                || row.subtitle.localizedCaseInsensitiveContains(searchText)
                || row.detail.localizedCaseInsensitiveContains(searchText)
                || row.source.path.localizedCaseInsensitiveContains(searchText)
                || row.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private func filter(scriptReadinessRows: [ScriptReadinessReportRow]) -> [ScriptReadinessReportRow] {
        guard !searchText.isEmpty else { return scriptReadinessRows }

        return scriptReadinessRows.filter { row in
            row.section.rawValue.localizedCaseInsensitiveContains(searchText)
                || row.title.localizedCaseInsensitiveContains(searchText)
                || row.subtitle.localizedCaseInsensitiveContains(searchText)
                || row.detail.localizedCaseInsensitiveContains(searchText)
                || row.source.path.localizedCaseInsensitiveContains(searchText)
                || row.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private func filter(graphicsRows: [GraphicsReportRow]) -> [GraphicsReportRow] {
        guard !searchText.isEmpty else { return graphicsRows }

        return graphicsRows.filter { row in
            row.section.rawValue.localizedCaseInsensitiveContains(searchText)
                || row.title.localizedCaseInsensitiveContains(searchText)
                || row.subtitle.localizedCaseInsensitiveContains(searchText)
                || row.detail.localizedCaseInsensitiveContains(searchText)
                || row.source.path.localizedCaseInsensitiveContains(searchText)
                || row.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private func filter(resourceEntries: [ResourceLibraryEntryViewState]) -> [ResourceLibraryEntryViewState] {
        guard !searchText.isEmpty else { return resourceEntries }

        return resourceEntries.filter { entry in
            entry.title.localizedCaseInsensitiveContains(searchText)
                || entry.path.localizedCaseInsensitiveContains(searchText)
                || entry.platform.localizedCaseInsensitiveContains(searchText)
                || entry.family.localizedCaseInsensitiveContains(searchText)
                || entry.profile.localizedCaseInsensitiveContains(searchText)
                || entry.role.localizedCaseInsensitiveContains(searchText)
                || entry.parseStatus.localizedCaseInsensitiveContains(searchText)
                || entry.variantSummary.localizedCaseInsensitiveContains(searchText)
                || entry.moduleSummary.localizedCaseInsensitiveContains(searchText)
                || entry.diagnostics.contains {
                    $0.title.localizedCaseInsensitiveContains(searchText)
                        || $0.message.localizedCaseInsensitiveContains(searchText)
                        || $0.source.path.localizedCaseInsensitiveContains(searchText)
                }
                || (userSettings.resourceSearchMatchesNestedItems && entry.items.contains { item in
                    item.title.localizedCaseInsensitiveContains(searchText)
                        || item.path.localizedCaseInsensitiveContains(searchText)
                        || item.kind.localizedCaseInsensitiveContains(searchText)
                        || item.category.localizedCaseInsensitiveContains(searchText)
                        || item.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
                })
        }
    }

    static func filterAndSort(
        assetRows: [ResourceAssetRowViewState],
        category: String,
        searchText: String,
        sortMode: ResourceAssetSortMode
    ) -> [ResourceAssetRowViewState] {
        let needle = searchText.lowercased()
        let filtered = assetRows.filter { row in
            (category == Self.allResourceAssetCategories || row.category == category)
                && (needle.isEmpty || row.searchBlob.contains(needle))
        }
        return filtered.sorted { lhs, rhs in
            switch sortMode {
            case .category:
                if lhs.category == rhs.category {
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
                return lhs.category < rhs.category
            case .title:
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            case .path:
                return lhs.path.localizedCaseInsensitiveCompare(rhs.path) == .orderedAscending
            case .status:
                if lhs.status.rawValue == rhs.status.rawValue {
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
                return lhs.status.rawValue < rhs.status.rawValue
            case .availability:
                if lhs.availability == rhs.availability {
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
                return lhs.availability < rhs.availability
            }
        }
    }

    private static func speciesSearchBlob(_ species: PokemonHackCore.SpeciesDetail) -> String {
        (
            [
                species.speciesID,
                species.displayName,
                species.sourceSpan.relativePath,
                species.training.growthRate ?? "",
                species.training.expYield ?? "",
                species.training.catchRate ?? "",
                species.bodyColor ?? "",
                species.pokedex?.categoryName ?? "",
                species.pokedex?.description ?? ""
            ]
            + species.types
            + species.abilities
            + species.breeding.eggGroups
            + species.learnsets.levelUp.map(\.move)
            + species.learnsets.tmhm.map(\.move)
            + species.learnsets.egg.map(\.move)
            + species.evolutions.map(\.targetSpecies)
            + species.assets.map(\.relativePath)
        )
        .joined(separator: " ")
        .lowercased()
    }

    private static func trainerSearchBlob(_ trainer: PokemonHackCore.TrainerDetail) -> String {
        (
            [
                trainer.trainerID,
                trainer.displayName,
                trainer.trainerName,
                trainer.trainerClass,
                trainer.trainerPic,
                trainer.encounterMusicGender,
                trainer.partyShape?.macroName ?? "",
                trainer.partySymbol ?? "",
                trainer.sourceSpan.relativePath,
                trainer.partySourceSpan?.relativePath ?? ""
            ]
            + trainer.trainerItems
            + trainer.aiFlags
            + trainer.party.flatMap { member in
                [
                    member.species,
                    member.heldItem ?? "",
                    member.nature ?? "",
                    "level \(member.level.map(String.init) ?? "")",
                    "iv \(member.iv.map(String.init) ?? "")",
                    "ivs \(member.ivs.values.map(String.init).joined(separator: " "))"
                ] + member.moves + member.defaultMoves
            }
            + trainer.diagnostics.map { "\($0.code) \($0.message)" }
        )
        .joined(separator: " ")
        .lowercased()
    }

    private static func defaultEditableSpecies(in species: [PokemonHackCore.SpeciesDetail]) -> PokemonHackCore.SpeciesDetail? {
        species.first { detail in
            detail.isEditable && detail.speciesID != "SPECIES_NONE"
        } ?? species.first { $0.isEditable }
    }

    private static func defaultEditableTrainer(in trainers: [PokemonHackCore.TrainerDetail]) -> PokemonHackCore.TrainerDetail? {
        trainers.first { detail in
            detail.isEditable
                && detail.trainerID != "TRAINER_NONE"
                && detail.trainerID != "TRAINER_NONE_0"
        } ?? trainers.first { $0.isEditable }
    }

    private func speciesDraftKey(projectID: String, speciesID: String) -> String {
        "\(projectID)::species::\(speciesID)"
    }

    private func trainerDraftKey(projectID: String, trainerID: String) -> String {
        "\(projectID)::trainer::\(trainerID)"
    }

    func moduleStatus(for module: WorkbenchModule) -> ValidationState {
        switch module {
        case .dashboard:
            selectedIndexedProject?.status ?? projectIndexStatus.validationState
        case .resources:
            resourceModuleStatus
        case .maps:
            mapModuleStatus
        case .build:
            Self.validationStatus(
                for: [
                    selectedBuildReport?.status ?? Self.validationStatus(for: buildSteps.map(\.status)),
                    patchManifestLoadStatus.validationState,
                    selectedPatchManifestReport?.status ?? .valid
                ]
            )
        case .issues:
            diagnosticSummary.status
        case .graphics:
            graphicsModuleStatus
        case .scripts:
            scriptModuleStatus
        case .pokemon:
            speciesModuleStatus
        case .trainers:
            trainerModuleStatus
        case .moves:
            moveModuleStatus
        default:
            Self.validationStatus(for: records(for: module).map(\.validation))
        }
    }

    private var resourceModuleStatus: ValidationState {
        guard let resourceLibrary else { return .valid }
        return Self.validationStatus(
            for: resourceLibrary.entries.map(\.status)
                + resourceLibrary.diagnostics.map(\.severity)
                + [assetCatalogLoadStatus.validationState]
                + (selectedAssetCatalog?.rows.filter(\.affectsResourceAvailability).map(\.status) ?? [])
                + (selectedAssetCatalog?.diagnostics.map(\.severity) ?? [])
        )
    }

    private var mapModuleStatus: ValidationState {
        if case .failed = mapCatalogStatus {
            return .error
        }

        if let catalog = selectedMapCatalog, !catalog.diagnostics.isEmpty {
            return Self.validationStatus(for: catalog.diagnostics.map(\.severity))
        }

        return .valid
    }

    private var graphicsModuleStatus: ValidationState {
        if let selectedGraphicsReport {
            return selectedGraphicsReport.status
        }
        guard let project = selectedIndexedProject else { return .valid }
        let graphicsSurfaces = project.sourceSurfaces.filter { surface in
            surface.kind == "graphics" || surface.kind == "palette"
        }
        return Self.validationStatus(for: graphicsSurfaces.map(\.validation))
    }

    private var scriptModuleStatus: ValidationState {
        let outlineStatus: ValidationState
        if let selectedScriptOutline {
            outlineStatus = selectedScriptOutline.diagnostics.contains { $0.severity == .error }
                ? .error
                : selectedScriptOutline.diagnostics.isEmpty ? .valid : .warning
        } else {
            outlineStatus = Self.validationStatus(for: records(for: .scripts).map(\.validation))
        }
        return Self.validationStatus(for: [outlineStatus, selectedScriptReadinessReport?.status ?? .valid])
    }

    private var speciesModuleStatus: ValidationState {
        guard let catalog = selectedSpeciesCatalog else {
            return Self.validationStatus(for: records(for: .pokemon).map(\.validation) + [speciesCatalogLoadStatus.validationState])
        }
        return Self.validationStatus(
            for: catalog.diagnostics.map { Self.validationState(for: $0.severity) } + [speciesCatalogLoadStatus.validationState]
        )
    }

    private var trainerModuleStatus: ValidationState {
        guard let catalog = selectedTrainerCatalog else {
            return Self.validationStatus(for: records(for: .trainers).map(\.validation) + [trainerCatalogLoadStatus.validationState])
        }
        return Self.validationStatus(
            for: catalog.diagnostics.map { Self.validationState(for: $0.severity) } + [trainerCatalogLoadStatus.validationState]
        )
    }

    private var moveModuleStatus: ValidationState {
        guard let catalog = selectedMoveCatalog else {
            return Self.validationStatus(for: records(for: .moves).map(\.validation) + [moveCatalogLoadStatus.validationState])
        }
        return Self.validationStatus(
            for: [catalog.status, moveCatalogLoadStatus.validationState]
        )
    }

    private func liveRecords(for module: WorkbenchModule) -> [WorkbenchRecord]? {
        guard let selectedSourceIndex else { return nil }
        let sourceModule: SourceIndexModule?
        switch module {
        case .scripts:
            sourceModule = .scripts
        case .text:
            sourceModule = .text
        case .pokemon:
            sourceModule = .pokemon
        case .moves:
            sourceModule = .moves
        case .trainers:
            sourceModule = .trainers
        case .items:
            sourceModule = .items
        case .encounters:
            sourceModule = .encounters
        default:
            sourceModule = nil
        }

        guard let sourceModule else { return nil }
        return selectedSourceIndex.records
            .filter { $0.module == sourceModule }
            .map(Self.record(from:))
    }

    func refreshProjectIndexes() {
        projectIndexStatus = .loading

        let coreResourceLibrary = refreshResourceLibrary()

        let resourceRoots = coreResourceLibrary.entries
            .filter { entry in
                entry.platform == .gbaSource
                    && !entry.path.isEmpty
                    && !Self.pathIsBundledAssetRoot(entry.path)
                    && (userSettings.includeReferenceRootsInResources || !Self.pathIsReferenceRoot(entry.path))
            }
            .map(\.path)
        let configuredRecentRoots = userSettings.includeRecentProjectsInRefresh ? recentProjectRoots : []
        let roots = Self.uniquePaths(resourceRoots + defaultProjectRoots() + configuredRecentRoots)
        var summaries: [IndexedProjectSummary] = []
        var indexes: [String: PokemonHackCore.ProjectIndex] = [:]
        var sourceIndexes: [String: PokemonHackCore.ProjectSourceIndex] = [:]
        var scriptOutlines: [String: PokemonHackCore.ProjectScriptOutline] = [:]
        var buildReports: [String: BuildPatchPlaytestReportViewState] = [:]
        var graphicsReports: [String: GraphicsDiagnosticsReportViewState] = [:]
        var retainedScriptReadinessReports: [String: ScriptReadinessReportViewState] = [:]
        var speciesCatalogs: [String: PokemonHackCore.ProjectSpeciesCatalog] = [:]
        var trainerCatalogs: [String: PokemonHackCore.ProjectTrainerCatalog] = [:]
        var moveCatalogs: [String: MoveCatalogViewState] = [:]
        var retainedAssetCatalogs: [String: ResourceAssetCatalogViewState] = [:]
        var retainedFingerprints: [String: String] = [:]

        for root in roots {
            guard fileManager.fileExists(atPath: root) else { continue }

            do {
                let index = try GameAdapterRegistry.index(path: root, fileManager: fileManager)
                let summary = Self.summary(from: index)
                summaries.append(summary)
                indexes[summary.id] = index
                let scriptOutline = try? ProjectScriptOutlineLoader.load(from: index, fileManager: fileManager)
                let sourceIndex: PokemonHackCore.ProjectSourceIndex?
                if let scriptOutline {
                    scriptOutlines[summary.id] = scriptOutline
                    sourceIndex = try? ProjectSourceIndexLoader.load(from: index, scriptOutline: scriptOutline, fileManager: fileManager)
                    sourceIndexes[summary.id] = sourceIndex
                } else {
                    sourceIndex = try? ProjectSourceIndexLoader.load(from: index, fileManager: fileManager)
                    sourceIndexes[summary.id] = sourceIndex
                }
                if userSettings.autoRefreshHealthOnProjectRefresh || buildReportsByID[summary.id] == nil {
                    let coreBuildReport = BuildValidationReportBuilder.build(index: index, fileManager: fileManager, toolResolver: toolResolver)
                    buildReports[summary.id] = Self.buildReport(from: index, project: summary, fileManager: fileManager, toolResolver: toolResolver, buildReport: coreBuildReport)
                } else {
                    buildReports[summary.id] = buildReportsByID[summary.id]
                }
                graphicsReports[summary.id] = Self.graphicsReport(from: index, project: summary, fileManager: fileManager)
                let speciesCatalog = try? ProjectSpeciesCatalogBuilder.build(index: index, fileManager: fileManager)
                if let speciesCatalog {
                    speciesCatalogs[summary.id] = speciesCatalog
                }
                if let trainerCatalog = try? ProjectTrainerCatalogBuilder.build(index: index, fileManager: fileManager) {
                    trainerCatalogs[summary.id] = trainerCatalog
                }
                if
                    let sourceIndex,
                    let moveCatalog = try? ProjectMoveCatalogBuilder.build(
                        index: index,
                        sourceIndex: sourceIndex,
                        speciesCatalog: speciesCatalog,
                        fileManager: fileManager
                    )
                {
                    moveCatalogs[summary.id] = Self.moveCatalog(from: moveCatalog, project: summary)
                }
                let fingerprint = Self.assetCatalogFingerprint(rootPath: summary.rootPath, fileManager: fileManager)
                if
                    assetCatalogFingerprintsByID[summary.id] == fingerprint,
                    let cached = assetCatalogsByID[summary.id]
                {
                    retainedAssetCatalogs[summary.id] = cached
                    retainedFingerprints[summary.id] = fingerprint
                }
                if let cached = scriptReadinessReportsByID[summary.id] {
                    retainedScriptReadinessReports[summary.id] = cached
                }
            } catch {
                continue
            }
        }

        indexedProjects = summaries
        projectIndexesByID = indexes
        sourceIndexesByID = sourceIndexes
        scriptOutlinesByID = scriptOutlines
        buildReportsByID = buildReports
        graphicsReportsByID = graphicsReports
        scriptReadinessReportsByID = retainedScriptReadinessReports
        speciesCatalogsByID = speciesCatalogs
        trainerCatalogsByID = trainerCatalogs
        moveCatalogsByID = moveCatalogs
        assetCatalogsByID = retainedAssetCatalogs
        assetCatalogFingerprintsByID = retainedFingerprints
        mapVisualSharedCacheDataByID = [:]
        resourceAssetRowsCache = nil
        if !summaries.contains(where: { $0.id == selectedProjectID }) {
            selectedProjectID = summaries.first?.id ?? ""
            resetPatchManifestReportForProjectChange()
        }
        refreshSelectedMapCatalog()
        refreshSelectedScriptReadinessReportIfVisible()
        refreshSelectedSpeciesSelection()
        refreshSelectedTrainerSelection()
        refreshSelectedMoveSelection()
        updateAssetCatalogLoadStatusForSelection()
        if userSettings.autoLoadAssetCatalog {
            loadSelectedAssetCatalogIfNeeded()
        }
        projectIndexStatus = .loaded(summaries.count)
    }

    func openProject(at url: URL) {
        openProject(path: url.standardizedFileURL.path)
    }

    func requestProjectSelection(_ projectID: String) {
        guard projectID != selectedProjectID else { return }
        if hasStagedMapEdits {
            pendingMapNavigation = .project(projectID)
        } else {
            selectedProjectID = projectID
            selectedScriptReadinessReport = scriptReadinessReportsByID[projectID]
            resetPatchManifestReportForProjectChange()
            resetSidebarSelectionsForProjectChange()
            resourceAssetCategory = Self.allResourceAssetCategories
            selectedResourceAssetID = nil
            pendingRelatedMapTargetID = nil
            pendingResourceAssetFocus = nil
            resourceAssetRowsCache = nil
            refreshSelectedSpeciesSelection()
            refreshSelectedTrainerSelection()
            refreshSelectedMoveSelection()
            latestSpeciesEditPlan = nil
            latestSpeciesApplyResult = nil
            latestTrainerEditPlan = nil
            latestTrainerApplyResult = nil
            updateAssetCatalogLoadStatusForSelection()
            if selection == .resources || userSettings.autoLoadAssetCatalog {
                loadSelectedAssetCatalogIfNeeded()
            }
        }
    }

    func requestMapSelection(_ mapID: String) {
        guard mapID != selectedMapID else { return }
        if hasStagedMapEdits {
            pendingMapNavigation = .map(mapID)
        } else {
            selectedMapID = mapID
        }
    }

    func requestSpeciesSelection(_ speciesID: String) {
        guard speciesID != selectedSpeciesID else { return }
        selectedSpeciesID = speciesID
        latestSpeciesEditPlan = nil
        latestSpeciesApplyResult = nil
    }

    func requestTrainerSelection(_ trainerID: String) {
        guard trainerID != selectedTrainerID else { return }
        selectedTrainerID = trainerID
        latestTrainerEditPlan = nil
        latestTrainerApplyResult = nil
    }

    func requestMoveSelection(_ moveID: String) {
        guard moveID != selectedMoveID else { return }
        selectedMoveID = moveID
    }

    func requestResourceAssetSelection(_ assetID: ResourceAssetRowViewState.ID?) {
        selectedResourceAssetID = assetID
    }

    func requestResourceLibraryEntrySelection(_ entryID: ResourceLibraryEntryViewState.ID) {
        selectedResourceLibraryEntryID = entryID
    }

    func requestScriptSourceSelection(_ sourceID: String) {
        selectedScriptSourceID = sourceID
    }

    func requestScriptLabelSelection(_ labelID: String) {
        selectedScriptLabelID = labelID
        selectedScriptReadinessLabel = labelID
        scriptReadinessTargetMode = .script
        refreshSelectedScriptReadinessReport()
    }

    func requestScriptTextBlockSelection(_ textBlockID: String) {
        selectedScriptTextBlockID = textBlockID
    }

    func requestRecordSelection(_ recordID: UUID, module: WorkbenchModule) {
        selectedRecordIDsByModule[module] = recordID
    }

    func requestBuildReportRowSelection(_ rowID: String) {
        selectedBuildReportRowID = rowID
    }

    func requestGraphicsReportRowSelection(_ rowID: String) {
        selectedGraphicsReportRowID = rowID
    }

    func requestDiagnosticBucketSelection(_ bucket: DiagnosticSummaryBucket) {
        selectedDiagnosticBucket = bucket
        selectedDiagnosticRowID = diagnosticSummary.bucket(bucket).diagnostics.first?.id ?? ""
    }

    func requestDiagnosticRowSelection(_ rowID: String) {
        selectedDiagnosticRowID = rowID
    }

    func requestGuidedFlowSelection(_ flowID: String) {
        selectedGuidedFlowID = flowID
    }

    func requestPatchPath(_ path: String) {
        selectedPatchPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        rawPatchManifestReport = nil
        selectedPatchManifestReport = nil
        patchManifestLoadStatus = selectedPatchPath.isEmpty ? .idle : .idle
    }

    func requestBaseROMPath(_ path: String) {
        selectedBaseROMPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if !selectedPatchPath.isEmpty, selectedPatchManifestReport != nil {
            loadSelectedPatchManifestReport()
        }
    }

    private func resetPatchManifestReportForProjectChange() {
        selectedBaseROMPath = ""
        rawPatchManifestReport = nil
        selectedPatchManifestReport = nil
        patchManifestLoadStatus = .idle
    }

    private func resetSidebarSelectionsForProjectChange() {
        selectedResourceLibraryEntryID = ""
        selectedScriptSourceID = ""
        selectedScriptLabelID = ""
        selectedScriptTextBlockID = ""
        selectedBuildReportRowID = ""
        selectedGraphicsReportRowID = ""
        selectedDiagnosticBucket = .blockingErrors
        selectedDiagnosticRowID = ""
        selectedGuidedFlowID = ""
        selectedRecordIDsByModule = [:]
        mapViewportRequest = nil
    }

    func loadSelectedPatchManifestReport() {
        guard !selectedPatchPath.isEmpty else {
            rawPatchManifestReport = nil
            selectedPatchManifestReport = nil
            patchManifestLoadStatus = .idle
            return
        }

        patchManifestLoadStatus = .loading

        do {
            let report = try PatchManifestBuilder.build(
                patchPath: selectedPatchPath,
                projectPath: selectedIndexedProject?.rootPath,
                baseROMPath: selectedBaseROMPath.isEmpty ? nil : selectedBaseROMPath,
                fileManager: fileManager
            )
            rawPatchManifestReport = report
            selectedPatchManifestReport = Self.patchManifestReportViewState(
                from: report,
                patchPath: selectedPatchPath,
                rootPath: selectedIndexedProject?.rootPath ?? workspaceRoot.path
            )
            patchManifestLoadStatus = .loaded(selectedPatchManifestReport?.compatibilityLabel ?? report.compatibilityStatus.rawValue)
        } catch {
            rawPatchManifestReport = nil
            selectedPatchManifestReport = nil
            patchManifestLoadStatus = .failed(error.localizedDescription)
        }
    }

    func navigateToAsset(_ asset: ResourceAssetRowViewState) {
        guard let targetModule = asset.targetModule else { return }
        selectedResourceAssetID = asset.id
        selection = targetModule
        switch targetModule {
        case .maps:
            navigateToMapAssetTarget(asset.targetID)
        case .scripts:
            navigateToScriptAssetTarget(asset.targetID)
        case .pokemon:
            navigateToPokemonAssetTarget(asset.targetID)
        case .trainers:
            navigateToTrainerAssetTarget(asset.targetID)
        case .moves:
            navigateToMoveAssetTarget(asset.targetID ?? asset.path)
        case .graphics, .build, .text, .items:
            searchText = asset.targetID ?? asset.path
        default:
            searchText = asset.targetID ?? asset.path
            break
        }
    }

    func navigateToResourceAsset(path: String) {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        selection = .resources
        resourceAssetCategory = Self.allResourceAssetCategories
        searchText = trimmed
        if !selectResourceAsset(matching: trimmed) {
            pendingResourceAssetFocus = trimmed
            loadSelectedAssetCatalogIfNeeded()
        }
    }

    private func navigateToMapAssetTarget(_ targetID: String?) {
        guard let targetID, !targetID.isEmpty else {
            loadSelectedMapCatalogIfNeeded()
            return
        }
        searchText = targetID
        if let catalog = selectedMapCatalog,
           let mapID = Self.mapID(forRelatedTarget: targetID, in: catalog)
        {
            pendingRelatedMapTargetID = nil
            requestMapSelection(mapID)
        } else {
            pendingRelatedMapTargetID = targetID
            loadSelectedMapCatalogIfNeeded()
        }
    }

    private func navigateToScriptAssetTarget(_ targetID: String?) {
        guard let targetID, !targetID.isEmpty else { return }
        searchText = targetID
        scriptReadinessTargetMode = .script
        if let label = Self.scriptReadinessLabel(for: targetID, outline: selectedScriptOutline) {
            selectedScriptReadinessLabel = label
            refreshSelectedScriptReadinessReport()
        }
    }

    private func navigateToPokemonAssetTarget(_ targetID: String?) {
        guard let targetID, !targetID.isEmpty else { return }
        searchText = targetID
        if selectedSpeciesCatalog == nil {
            loadSelectedSpeciesCatalogIfNeeded()
        }
        if selectedSpeciesCatalog?.species.contains(where: { $0.speciesID == targetID }) == true {
            requestSpeciesSelection(targetID)
        }
    }

    private func navigateToTrainerAssetTarget(_ targetID: String?) {
        guard let targetID, !targetID.isEmpty else { return }
        searchText = targetID
        if selectedTrainerCatalog == nil {
            loadSelectedTrainerCatalogIfNeeded()
        }
        if selectedTrainerCatalog?.trainers.contains(where: { $0.trainerID == targetID }) == true {
            requestTrainerSelection(targetID)
        }
    }

    private func navigateToMoveAssetTarget(_ targetID: String?) {
        guard let targetID, !targetID.isEmpty else { return }
        searchText = targetID
        if selectedMoveCatalog == nil {
            loadSelectedMoveCatalogIfNeeded()
        }
        if selectedMoveCatalog?.moves.contains(where: { $0.moveID == targetID }) == true {
            requestMoveSelection(targetID)
        }
    }

    @discardableResult
    private func selectResourceAsset(matching identifier: String) -> Bool {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let catalog = selectedAssetCatalog else { return false }
        let needle = trimmed.lowercased()
        let exactMatch = catalog.rows.first { $0.id == trimmed }
            ?? catalog.rows.first { $0.targetID == trimmed }
            ?? catalog.rows.first { $0.path == trimmed && $0.targetID == trimmed }
            ?? catalog.rows.first { $0.path == trimmed }
            ?? catalog.rows.first { $0.title == trimmed }
            ?? catalog.rows.first { $0.source.path == trimmed }
        let fallbackMatch = exactMatch ?? catalog.rows.first { row in
            row.searchBlob.contains(needle)
        }
        selectedResourceAssetID = fallbackMatch?.id
        return fallbackMatch != nil
    }

    private func resolvePendingResourceAssetFocusIfNeeded() {
        guard let pendingResourceAssetFocus else { return }
        _ = selectResourceAsset(matching: pendingResourceAssetFocus)
        self.pendingResourceAssetFocus = nil
    }

    private static func mapID(forRelatedTarget targetID: String, in catalog: MapCatalogViewState) -> String? {
        catalog.maps.first { map in
            map.id == targetID
                || map.mapID == targetID
                || map.name == targetID
                || map.source.path == targetID
                || map.layout?.id == targetID
                || map.layout?.name == targetID
                || map.layout?.borderFilepath == targetID
                || map.layout?.blockdataFilepath == targetID
        }?.id
    }

    private static func scriptReadinessLabel(for targetID: String, outline: PokemonHackCore.ProjectScriptOutline?) -> String? {
        guard let outline else { return nil }
        if outline.labels.contains(where: { $0.label == targetID }) {
            return targetID
        }
        return outline.labels.first { $0.sourcePath == targetID }?.label
    }

    func cancelPendingMapNavigation() {
        pendingMapNavigation = nil
    }

    func previewBeforePendingMapNavigation() {
        previewSelectedMapMutationPlan()
        pendingMapNavigation = nil
        selection = .maps
    }

    func discardMapEdits() {
        mapEditorSession.discardChanges()
    }

    func discardMapEditsAndContinueNavigation() {
        guard let pendingMapNavigation else { return }
        discardMapEdits()
        self.pendingMapNavigation = nil

        switch pendingMapNavigation {
        case .project(let projectID):
            selectedProjectID = projectID
            selectedScriptReadinessReport = scriptReadinessReportsByID[projectID]
            resetPatchManifestReportForProjectChange()
            resetSidebarSelectionsForProjectChange()
            resourceAssetCategory = Self.allResourceAssetCategories
            resourceAssetRowsCache = nil
            refreshSelectedSpeciesSelection()
            refreshSelectedTrainerSelection()
            refreshSelectedMoveSelection()
            latestSpeciesEditPlan = nil
            latestSpeciesApplyResult = nil
            latestTrainerEditPlan = nil
            latestTrainerApplyResult = nil
            updateAssetCatalogLoadStatusForSelection()
            if selection == .resources || userSettings.autoLoadAssetCatalog {
                loadSelectedAssetCatalogIfNeeded()
            }
        case .map(let mapID):
            selectedMapID = mapID
        }
    }

    func openProject(path: String) {
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path

        do {
            let index = try GameAdapterRegistry.index(path: standardizedPath, fileManager: fileManager)
            let summary = Self.summary(from: index)
            projectIndexesByID[summary.id] = index
            let scriptOutline = try? ProjectScriptOutlineLoader.load(from: index, fileManager: fileManager)
            let sourceIndex: PokemonHackCore.ProjectSourceIndex?
            if let scriptOutline {
                scriptOutlinesByID[summary.id] = scriptOutline
                sourceIndex = try? ProjectSourceIndexLoader.load(from: index, scriptOutline: scriptOutline, fileManager: fileManager)
                sourceIndexesByID[summary.id] = sourceIndex
            } else {
                scriptOutlinesByID.removeValue(forKey: summary.id)
                sourceIndex = try? ProjectSourceIndexLoader.load(from: index, fileManager: fileManager)
                sourceIndexesByID[summary.id] = sourceIndex
            }
            let coreBuildReport = BuildValidationReportBuilder.build(index: index, fileManager: fileManager, toolResolver: toolResolver)
            buildReportsByID[summary.id] = Self.buildReport(from: index, project: summary, fileManager: fileManager, toolResolver: toolResolver, buildReport: coreBuildReport)
            graphicsReportsByID[summary.id] = Self.graphicsReport(from: index, project: summary, fileManager: fileManager)
            let speciesCatalog = try? ProjectSpeciesCatalogBuilder.build(index: index, fileManager: fileManager)
            speciesCatalogsByID[summary.id] = speciesCatalog
            trainerCatalogsByID[summary.id] = try? ProjectTrainerCatalogBuilder.build(index: index, fileManager: fileManager)
            if
                let sourceIndex,
                let moveCatalog = try? ProjectMoveCatalogBuilder.build(
                    index: index,
                    sourceIndex: sourceIndex,
                    speciesCatalog: speciesCatalog,
                    fileManager: fileManager
                )
            {
                moveCatalogsByID[summary.id] = Self.moveCatalog(from: moveCatalog, project: summary)
            } else {
                moveCatalogsByID.removeValue(forKey: summary.id)
            }
            assetCatalogsByID.removeValue(forKey: summary.id)
            assetCatalogFingerprintsByID.removeValue(forKey: summary.id)
            selectedResourceAssetID = nil
            pendingRelatedMapTargetID = nil
            pendingResourceAssetFocus = nil
            resourceAssetRowsCache = nil
            scriptReadinessReportsByID.removeValue(forKey: summary.id)
            upsert(summary)
            rememberRecentRoot(standardizedPath)
            if userSettings.resourceAutoRefreshOnOpen {
                refreshResourceLibrary()
            }
            selectedProjectID = summary.id
            resetPatchManifestReportForProjectChange()
            resetSidebarSelectionsForProjectChange()
            refreshSelectedMapCatalog()
            refreshSelectedScriptReadinessReportIfVisible()
            refreshSelectedSpeciesSelection()
            refreshSelectedTrainerSelection()
            refreshSelectedMoveSelection()
            latestSpeciesEditPlan = nil
            latestSpeciesApplyResult = nil
            latestTrainerEditPlan = nil
            latestTrainerApplyResult = nil
            updateAssetCatalogLoadStatusForSelection()
            if selection == .resources || userSettings.autoLoadAssetCatalog {
                loadSelectedAssetCatalogIfNeeded()
            }
            projectIndexStatus = .loaded(indexedProjects.count)
        } catch {
            projectIndexStatus = .failed(error.localizedDescription)
        }
    }

    func requestScriptReadinessMode(_ mode: ScriptReadinessTargetMode) {
        scriptReadinessTargetMode = mode
        if mode == .script, selectedScriptReadinessLabel.isEmpty {
            selectedScriptReadinessLabel = selectedScriptOutline?.labels.first?.label ?? ""
        }
        refreshSelectedScriptReadinessReport()
    }

    func requestScriptReadinessMapSelection(_ mapID: String) {
        selectedMapID = mapID
        if scriptReadinessTargetMode == .map {
            refreshSelectedScriptReadinessReport()
        }
    }

    func requestScriptReadinessLabel(_ label: String) {
        selectedScriptReadinessLabel = label
        if scriptReadinessTargetMode == .script {
            refreshSelectedScriptReadinessReport()
        }
    }

    func refreshSelectedScriptReadinessReport() {
        guard let selectedIndexedProject else {
            selectedScriptReadinessReport = nil
            return
        }

        guard let index = projectIndexesByID[selectedIndexedProject.id] else {
            selectedScriptReadinessReport = scriptReadinessReportsByID[selectedIndexedProject.id]
            return
        }

        guard let target = selectedScriptReadinessTarget(index: index) else {
            selectedScriptReadinessReport = scriptReadinessReportsByID[selectedIndexedProject.id]
            return
        }

        let report = ScriptReadinessReportBuilder.build(
            index: index,
            target: target,
            fileManager: fileManager
        )
        let viewState = Self.scriptReadinessReport(from: report, project: selectedIndexedProject)
        scriptReadinessReportsByID[selectedIndexedProject.id] = viewState
        selectedScriptReadinessReport = viewState
    }

    private func refreshSelectedScriptReadinessReportIfVisible() {
        guard selection == .scripts else {
            selectedScriptReadinessReport = selectedIndexedProject.flatMap { scriptReadinessReportsByID[$0.id] }
            return
        }

        refreshSelectedScriptReadinessReport()
    }

    func loadSelectedSpeciesCatalogIfNeeded(force: Bool = false) {
        guard let selectedIndexedProject else {
            speciesCatalogLoadStatus = .idle
            selectedSpeciesID = ""
            return
        }
        if !force, let catalog = speciesCatalogsByID[selectedIndexedProject.id] {
            speciesCatalogLoadStatus = .loaded(catalog.speciesCount)
            refreshSelectedSpeciesSelection()
            return
        }

        speciesCatalogLoadStatus = .loading
        do {
            let index: PokemonHackCore.ProjectIndex
            if let retainedIndex = projectIndexesByID[selectedIndexedProject.id] {
                index = retainedIndex
            } else {
                index = try GameAdapterRegistry.index(path: selectedIndexedProject.rootPath, fileManager: fileManager)
                projectIndexesByID[selectedIndexedProject.id] = index
            }

            let catalog = try ProjectSpeciesCatalogBuilder.build(index: index, fileManager: fileManager)
            speciesCatalogsByID[selectedIndexedProject.id] = catalog
            speciesCatalogLoadStatus = .loaded(catalog.speciesCount)
            refreshSelectedSpeciesSelection()
        } catch {
            speciesCatalogLoadStatus = .failed(error.localizedDescription)
        }
    }

    private func refreshSelectedSpeciesSelection() {
        guard let selectedIndexedProject else {
            speciesCatalogLoadStatus = .idle
            selectedSpeciesID = ""
            return
        }

        guard let catalog = speciesCatalogsByID[selectedIndexedProject.id] else {
            speciesCatalogLoadStatus = .idle
            selectedSpeciesID = ""
            return
        }

        if !catalog.species.contains(where: { $0.speciesID == selectedSpeciesID }) {
            selectedSpeciesID = Self.defaultEditableSpecies(in: catalog.species)?.speciesID
                ?? catalog.species.first?.speciesID
                ?? ""
        }
        speciesCatalogLoadStatus = .loaded(catalog.speciesCount)
    }

    func loadSelectedMoveCatalogIfNeeded(force: Bool = false) {
        guard let selectedIndexedProject else {
            moveCatalogLoadStatus = .idle
            selectedMoveID = ""
            return
        }
        if !force, let catalog = moveCatalogsByID[selectedIndexedProject.id] {
            moveCatalogLoadStatus = .loaded(catalog.moveCount)
            refreshSelectedMoveSelection()
            return
        }

        moveCatalogLoadStatus = .loading
        do {
            let index: PokemonHackCore.ProjectIndex
            if let retainedIndex = projectIndexesByID[selectedIndexedProject.id] {
                index = retainedIndex
            } else {
                index = try GameAdapterRegistry.index(path: selectedIndexedProject.rootPath, fileManager: fileManager)
                projectIndexesByID[selectedIndexedProject.id] = index
            }

            let sourceIndex: PokemonHackCore.ProjectSourceIndex
            if let retainedSourceIndex = sourceIndexesByID[selectedIndexedProject.id] {
                sourceIndex = retainedSourceIndex
            } else {
                sourceIndex = try ProjectSourceIndexLoader.load(from: index, fileManager: fileManager)
                sourceIndexesByID[selectedIndexedProject.id] = sourceIndex
            }

            let speciesCatalog = speciesCatalogsByID[selectedIndexedProject.id]
            let coreCatalog = try ProjectMoveCatalogBuilder.build(
                index: index,
                sourceIndex: sourceIndex,
                speciesCatalog: speciesCatalog,
                fileManager: fileManager
            )
            let catalog = Self.moveCatalog(from: coreCatalog, project: selectedIndexedProject)
            moveCatalogsByID[selectedIndexedProject.id] = catalog
            moveCatalogLoadStatus = .loaded(catalog.moveCount)
            refreshSelectedMoveSelection()
        } catch {
            moveCatalogLoadStatus = .failed(error.localizedDescription)
        }
    }

    private func refreshSelectedMoveSelection() {
        guard let selectedIndexedProject else {
            moveCatalogLoadStatus = .idle
            selectedMoveID = ""
            return
        }

        guard let catalog = moveCatalogsByID[selectedIndexedProject.id] else {
            moveCatalogLoadStatus = .idle
            selectedMoveID = ""
            return
        }

        if !catalog.moves.contains(where: { $0.moveID == selectedMoveID }) {
            selectedMoveID = catalog.moves.first?.moveID ?? ""
        }
        moveCatalogLoadStatus = .loaded(catalog.moveCount)
    }

    func updateSelectedSpeciesDraft(_ draft: PokemonHackCore.SpeciesEditDraft) {
        guard let selectedIndexedProject else { return }
        let key = speciesDraftKey(projectID: selectedIndexedProject.id, speciesID: draft.speciesID)
        if let base = selectedSpeciesCatalog?.species.first(where: { $0.speciesID == draft.speciesID })
            .flatMap(PokemonHackCore.SpeciesEditDraft.init(detail:)),
           base == draft
        {
            speciesDraftsByKey.removeValue(forKey: key)
        } else {
            speciesDraftsByKey[key] = draft
        }
        latestSpeciesEditPlan = nil
        latestSpeciesApplyResult = nil
    }

    func discardSpeciesEdits() {
        guard let selectedIndexedProject, let detail = selectedSpeciesDetail else {
            latestSpeciesEditPlan = nil
            latestSpeciesApplyResult = nil
            return
        }
        speciesDraftsByKey.removeValue(forKey: speciesDraftKey(projectID: selectedIndexedProject.id, speciesID: detail.speciesID))
        latestSpeciesEditPlan = nil
        latestSpeciesApplyResult = nil
    }

    func previewSelectedSpeciesMutationPlan() {
        guard let catalog = selectedSpeciesCatalog, let draft = selectedSpeciesDraft else {
            latestSpeciesEditPlan = nil
            latestSpeciesApplyResult = nil
            return
        }
        latestSpeciesEditPlan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft, fileManager: fileManager)
        latestSpeciesApplyResult = nil
    }

    func applySelectedSpeciesMutationPlan() {
        if latestSpeciesEditPlan == nil {
            previewSelectedSpeciesMutationPlan()
        }

        guard let plan = latestSpeciesEditPlan else { return }
        let projectIDBeforeApply = selectedProjectID
        let speciesIDBeforeApply = plan.speciesID

        do {
            let result = try SpeciesMutationApplier.apply(plan: plan, fileManager: fileManager)
            latestSpeciesApplyResult = result
            guard !result.appliedChanges.isEmpty else { return }
            if !projectIDBeforeApply.isEmpty {
                speciesDraftsByKey.removeValue(forKey: speciesDraftKey(projectID: projectIDBeforeApply, speciesID: speciesIDBeforeApply))
            }
            reloadSelectedProjectAfterSpeciesApply(projectID: projectIDBeforeApply)
            if indexedProjects.contains(where: { $0.id == projectIDBeforeApply }) {
                selectedProjectID = projectIDBeforeApply
            }
            refreshSelectedSpeciesSelection()
            if selectedSpeciesCatalog?.species.contains(where: { $0.speciesID == speciesIDBeforeApply }) == true {
                selectedSpeciesID = speciesIDBeforeApply
            }
            latestSpeciesEditPlan = nil
            latestSpeciesApplyResult = result
        } catch {
            latestSpeciesApplyResult = SpeciesApplyResult(
                backupRootPath: plan.backupRelativeRoot,
                appliedChanges: [],
                diagnostics: [
                    Diagnostic(
                        severity: .error,
                        code: "SPECIES_APPLY_FAILED",
                        message: error.localizedDescription
                    )
                ]
            )
        }
    }

    func loadSelectedTrainerCatalogIfNeeded(force: Bool = false) {
        guard let selectedIndexedProject else {
            trainerCatalogLoadStatus = .idle
            selectedTrainerID = ""
            return
        }
        if !force, let catalog = trainerCatalogsByID[selectedIndexedProject.id] {
            trainerCatalogLoadStatus = .loaded(catalog.trainerCount)
            refreshSelectedTrainerSelection()
            return
        }

        trainerCatalogLoadStatus = .loading
        do {
            let index: PokemonHackCore.ProjectIndex
            if let retainedIndex = projectIndexesByID[selectedIndexedProject.id] {
                index = retainedIndex
            } else {
                index = try GameAdapterRegistry.index(path: selectedIndexedProject.rootPath, fileManager: fileManager)
                projectIndexesByID[selectedIndexedProject.id] = index
            }

            let catalog = try ProjectTrainerCatalogBuilder.build(index: index, fileManager: fileManager)
            trainerCatalogsByID[selectedIndexedProject.id] = catalog
            trainerCatalogLoadStatus = .loaded(catalog.trainerCount)
            refreshSelectedTrainerSelection()
        } catch {
            trainerCatalogLoadStatus = .failed(error.localizedDescription)
        }
    }

    private func refreshSelectedTrainerSelection() {
        guard let selectedIndexedProject else {
            trainerCatalogLoadStatus = .idle
            selectedTrainerID = ""
            return
        }

        guard let catalog = trainerCatalogsByID[selectedIndexedProject.id] else {
            trainerCatalogLoadStatus = .idle
            selectedTrainerID = ""
            return
        }

        if !catalog.trainers.contains(where: { $0.trainerID == selectedTrainerID }) {
            selectedTrainerID = Self.defaultEditableTrainer(in: catalog.trainers)?.trainerID
                ?? catalog.trainers.first?.trainerID
                ?? ""
        }
        trainerCatalogLoadStatus = .loaded(catalog.trainerCount)
    }

    func updateSelectedTrainerDraft(_ draft: PokemonHackCore.TrainerEditDraft) {
        guard let selectedIndexedProject else { return }
        let key = trainerDraftKey(projectID: selectedIndexedProject.id, trainerID: draft.trainerID)
        if let base = selectedTrainerCatalog?.trainers.first(where: { $0.trainerID == draft.trainerID })
            .flatMap(PokemonHackCore.TrainerEditDraft.init(detail:)),
           base == draft
        {
            trainerDraftsByKey.removeValue(forKey: key)
        } else {
            trainerDraftsByKey[key] = draft
        }
        latestTrainerEditPlan = nil
        latestTrainerApplyResult = nil
    }

    func discardTrainerEdits() {
        guard let selectedIndexedProject, let detail = selectedTrainerDetail else {
            latestTrainerEditPlan = nil
            latestTrainerApplyResult = nil
            return
        }
        trainerDraftsByKey.removeValue(forKey: trainerDraftKey(projectID: selectedIndexedProject.id, trainerID: detail.trainerID))
        latestTrainerEditPlan = nil
        latestTrainerApplyResult = nil
    }

    func previewSelectedTrainerMutationPlan() {
        guard let catalog = selectedTrainerCatalog, let draft = selectedTrainerDraft else {
            latestTrainerEditPlan = nil
            latestTrainerApplyResult = nil
            return
        }
        latestTrainerEditPlan = TrainerMutationPlanner.plan(catalog: catalog, draft: draft, fileManager: fileManager)
        latestTrainerApplyResult = nil
    }

    func applySelectedTrainerMutationPlan() {
        if latestTrainerEditPlan == nil {
            previewSelectedTrainerMutationPlan()
        }

        guard let plan = latestTrainerEditPlan else { return }
        let projectIDBeforeApply = selectedProjectID
        let trainerIDBeforeApply = plan.trainerID

        do {
            let result = try TrainerMutationApplier.apply(plan: plan, fileManager: fileManager)
            latestTrainerApplyResult = result
            guard !result.appliedChanges.isEmpty else { return }
            if !projectIDBeforeApply.isEmpty {
                trainerDraftsByKey.removeValue(forKey: trainerDraftKey(projectID: projectIDBeforeApply, trainerID: trainerIDBeforeApply))
            }
            reloadSelectedProjectAfterTrainerApply(projectID: projectIDBeforeApply)
            if indexedProjects.contains(where: { $0.id == projectIDBeforeApply }) {
                selectedProjectID = projectIDBeforeApply
            }
            refreshSelectedTrainerSelection()
            if selectedTrainerCatalog?.trainers.contains(where: { $0.trainerID == trainerIDBeforeApply }) == true {
                selectedTrainerID = trainerIDBeforeApply
            }
            latestTrainerEditPlan = nil
            latestTrainerApplyResult = result
        } catch {
            latestTrainerApplyResult = TrainerApplyResult(
                backupRootPath: plan.backupRelativeRoot,
                appliedChanges: [],
                diagnostics: [
                    Diagnostic(
                        severity: .error,
                        code: "TRAINER_APPLY_FAILED",
                        message: error.localizedDescription
                    )
                ]
            )
        }
    }

    private func reloadSelectedProjectAfterSpeciesApply(projectID: String) {
        let rootPath = indexedProjects.first { $0.id == projectID }?.rootPath ?? projectID
        guard fileManager.fileExists(atPath: rootPath) else { return }

        do {
            let index = try GameAdapterRegistry.index(path: rootPath, fileManager: fileManager)
            let summary = Self.summary(from: index)
            projectIndexesByID[summary.id] = index

            let scriptOutline = try? ProjectScriptOutlineLoader.load(from: index, fileManager: fileManager)
            if let scriptOutline {
                scriptOutlinesByID[summary.id] = scriptOutline
                sourceIndexesByID[summary.id] = try? ProjectSourceIndexLoader.load(from: index, scriptOutline: scriptOutline, fileManager: fileManager)
            } else {
                scriptOutlinesByID.removeValue(forKey: summary.id)
                sourceIndexesByID[summary.id] = try? ProjectSourceIndexLoader.load(from: index, fileManager: fileManager)
            }

            speciesCatalogsByID[summary.id] = try? ProjectSpeciesCatalogBuilder.build(index: index, fileManager: fileManager)
            upsert(summary)
            selectedProjectID = summary.id
            refreshSelectedSpeciesSelection()
        } catch {
            speciesCatalogLoadStatus = .failed(error.localizedDescription)
        }
    }

    private func reloadSelectedProjectAfterTrainerApply(projectID: String) {
        let rootPath = indexedProjects.first { $0.id == projectID }?.rootPath ?? projectID
        guard fileManager.fileExists(atPath: rootPath) else { return }

        do {
            let index = try GameAdapterRegistry.index(path: rootPath, fileManager: fileManager)
            let summary = Self.summary(from: index)
            projectIndexesByID[summary.id] = index

            let scriptOutline = try? ProjectScriptOutlineLoader.load(from: index, fileManager: fileManager)
            if let scriptOutline {
                scriptOutlinesByID[summary.id] = scriptOutline
                sourceIndexesByID[summary.id] = try? ProjectSourceIndexLoader.load(from: index, scriptOutline: scriptOutline, fileManager: fileManager)
            } else {
                scriptOutlinesByID.removeValue(forKey: summary.id)
                sourceIndexesByID[summary.id] = try? ProjectSourceIndexLoader.load(from: index, fileManager: fileManager)
            }

            trainerCatalogsByID[summary.id] = try? ProjectTrainerCatalogBuilder.build(index: index, fileManager: fileManager)
            upsert(summary)
            selectedProjectID = summary.id
            refreshSelectedTrainerSelection()
        } catch {
            trainerCatalogLoadStatus = .failed(error.localizedDescription)
        }
    }

    private func selectedScriptReadinessTarget(index: PokemonHackCore.ProjectIndex) -> PokemonHackCore.ScriptReadinessTarget? {
        switch scriptReadinessTargetMode {
        case .map:
            if !selectedMapID.isEmpty {
                return ScriptReadinessTarget(kind: .map, identifier: selectedMapID)
            }
            if let mapID = selectedMapCatalog?.maps.first?.id {
                return ScriptReadinessTarget(kind: .map, identifier: mapID)
            }
            return Self.defaultScriptReadinessTarget(for: index, fileManager: fileManager)
        case .script:
            if selectedScriptReadinessLabel.isEmpty {
                selectedScriptReadinessLabel = selectedScriptOutline?.labels.first?.label ?? ""
            }
            guard !selectedScriptReadinessLabel.isEmpty else { return nil }
            return ScriptReadinessTarget(kind: .script, identifier: selectedScriptReadinessLabel)
        }
    }

    private func upsert(_ summary: IndexedProjectSummary) {
        if let index = indexedProjects.firstIndex(where: { $0.id == summary.id }) {
            indexedProjects[index] = summary
        } else {
            indexedProjects.insert(summary, at: 0)
        }
    }

    private func rememberRecentRoot(_ path: String) {
        guard userSettings.rememberRecentProjects else { return }
        let limit = max(1, userSettings.maxRecentProjects)
        let roots = Array(Self.uniquePaths([path] + recentProjectRoots).prefix(limit))
        recentProjectRoots = roots
        userDefaults.set(roots, forKey: Self.recentRootsKey)
    }

    func clearRecentProjects() {
        recentProjectRoots = []
        userDefaults.removeObject(forKey: Self.recentRootsKey)
        refreshResourceLibrary()
    }

    @discardableResult
    func refreshResourceLibrary() -> PokemonHackCore.GenIIIResourceLibrary {
        let workspaceLibrary = GenIIIResourceRegistry.load(
            workspaceRoot: workspaceRoot.path,
            recentRoots: recentProjectRoots,
            fileManager: fileManager
        )
        let coreResourceLibrary = Self.libraryByAppendingBundledAssets(
            to: workspaceLibrary,
            fileManager: fileManager
        )
        resourceLibrary = Self.resourceLibraryViewState(from: coreResourceLibrary)
        return coreResourceLibrary
    }

    func refreshHealthChecks() {
        guard !projectIndexesByID.isEmpty else {
            refreshProjectIndexes()
            return
        }

        for project in indexedProjects {
            guard let index = projectIndexesByID[project.id] else { continue }
            let coreBuildReport = BuildValidationReportBuilder.build(index: index, fileManager: fileManager, toolResolver: toolResolver)
            buildReportsByID[project.id] = Self.buildReport(from: index, project: project, fileManager: fileManager, toolResolver: toolResolver, buildReport: coreBuildReport)
        }
    }

    func revealSelectedProjectInFinder() {
        guard let selectedIndexedProject else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: selectedIndexedProject.rootPath)])
    }

    func exportSettingsSnapshotToPasteboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(userSettings.exportSnapshot(), forType: .string)
    }

    func copyBuildPatchPlaytestReportJSONToPasteboard() {
        let report = selectedBuildReport
        let payload = BuildPatchPlaytestReportExportPayload(
            projectTitle: report?.projectTitle,
            rootPath: report?.rootPath,
            profile: report?.profile,
            status: report?.status.rawValue ?? moduleStatus(for: .build).rawValue,
            buildRows: (report?.rows ?? []).map(Self.exportPayload(from:)),
            patchManifest: rawPatchManifestReport,
            playtest: report.map(Self.exportPayload(fromPlaytest:))
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        if let data = try? encoder.encode(payload), let json = String(data: data, encoding: .utf8) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(json, forType: .string)
        }
    }

    func launchSelectedPlaytest(
        artifactRoot: URL? = nil,
        processRunner: PlaytestProcessRunner = PlaytestLauncher.defaultProcessRunner
    ) {
        guard let selectedIndexedProject,
              let index = projectIndexesByID[selectedIndexedProject.id] else {
            return
        }

        let result = PlaytestLauncher.launch(
            index: index,
            mode: .interactive,
            artifactRoot: artifactRoot ?? workspaceRoot,
            fileManager: fileManager,
            toolResolver: toolResolver,
            processRunner: processRunner
        )
        playtestLaunchResultsByID[selectedIndexedProject.id] = Self.playtestLaunchResult(
            from: result,
            rootPath: selectedIndexedProject.rootPath
        )
    }

    func loadSelectedAssetCatalogIfNeeded(force: Bool = false) {
        guard let project = selectedIndexedProject else {
            assetCatalogLoadStatus = .idle
            return
        }

        let fingerprint = Self.assetCatalogFingerprint(rootPath: project.rootPath, fileManager: fileManager)
        if
            !force,
            assetCatalogFingerprintsByID[project.id] == fingerprint,
            let cached = assetCatalogsByID[project.id]
        {
            assetCatalogLoadStatus = .loaded(cached.assetCount)
            resolvePendingResourceAssetFocusIfNeeded()
            return
        }

        assetCatalogTask?.cancel()
        assetCatalogLoadStatus = .loading
        let projectID = project.id
        let rootPath = project.rootPath
        let projectSummary = project

        assetCatalogTask = Task { @MainActor [weak self] in
            do {
                let data = try await Task.detached(priority: .userInitiated) { () throws -> Data in
                    let catalog = GenIIIAssetCatalogBuilder.build(path: rootPath)
                    return try JSONEncoder().encode(catalog)
                }.value
                guard !Task.isCancelled else { return }
                let catalog = try JSONDecoder().decode(GenIIIAssetCatalog.self, from: data)
                guard let self, self.selectedIndexedProject?.id == projectID else { return }
                let viewState = Self.assetCatalogViewState(from: catalog, project: projectSummary)
                assetCatalogsByID[projectID] = viewState
                assetCatalogFingerprintsByID[projectID] = fingerprint
                resourceAssetRowsCache = nil
                resolvePendingResourceAssetFocusIfNeeded()
                assetCatalogLoadStatus = .loaded(viewState.assetCount)
            } catch {
                guard let self, self.selectedIndexedProject?.id == projectID else { return }
                assetCatalogLoadStatus = .failed(error.localizedDescription)
            }
        }
    }

    private func updateAssetCatalogLoadStatusForSelection() {
        guard let selectedIndexedProject else {
            assetCatalogLoadStatus = .idle
            return
        }
        if let catalog = assetCatalogsByID[selectedIndexedProject.id] {
            assetCatalogLoadStatus = .loaded(catalog.assetCount)
        } else {
            assetCatalogLoadStatus = .idle
        }
    }

    func refreshSelectedMapCatalog() {
        mapCatalogTask?.cancel()
        mapVisualTask?.cancel()
        selectedMapCatalog = nil
        selectedMapID = ""
        mapCatalogStatus = selectedIndexedProject == nil ? .idle : .loading
        clearSelectedMapVisualDocument()
    }

    func loadSelectedMapCatalogIfNeeded() {
        guard selectedMapCatalog == nil else { return }
        loadSelectedMapCatalog()
    }

    func loadSelectedMapCatalog() {
        guard let selectedIndexedProject else {
            mapCatalogTask?.cancel()
            selectedMapCatalog = nil
            selectedMapID = ""
            mapCatalogStatus = .idle
            return
        }

        mapCatalogTask?.cancel()
        mapCatalogStatus = .loading
        let projectID = selectedIndexedProject.id
        let rootPath = selectedIndexedProject.rootPath
        let projectSummary = selectedIndexedProject

        mapCatalogTask = Task { @MainActor [weak self] in
            do {
                let payloadData = try await Task.detached(priority: .userInitiated) { () throws -> Data in
                    let index = try GameAdapterRegistry.index(path: rootPath, fileManager: .default)
                    let catalog = try ProjectMapCatalogLoader.load(from: index, fileManager: .default)
                    return try JSONEncoder().encode(MapCatalogLoadPayload(index: index, catalog: catalog))
                }.value
                guard !Task.isCancelled else { return }
                let payload = try JSONDecoder().decode(MapCatalogLoadPayload.self, from: payloadData)
                guard let self, self.selectedIndexedProject?.id == projectID else { return }

                projectIndexesByID[projectID] = payload.index
                mapVisualSharedCacheDataByID.removeValue(forKey: projectID)
                let viewState = Self.mapCatalogViewState(from: payload.catalog, project: projectSummary)
                selectedMapCatalog = viewState
                if
                    let pendingRelatedMapTargetID,
                    let resolvedMapID = Self.mapID(forRelatedTarget: pendingRelatedMapTargetID, in: viewState)
                {
                    self.pendingRelatedMapTargetID = nil
                    requestMapSelection(resolvedMapID)
                } else {
                    self.pendingRelatedMapTargetID = nil
                }
                if !viewState.maps.contains(where: { $0.id == selectedMapID }) {
                    selectedMapID = viewState.maps.first?.id ?? ""
                }
                mapCatalogStatus = .loaded(viewState.mapCount)
                loadSelectedMapVisualDocument()
                refreshSelectedScriptReadinessReportIfVisible()
            } catch {
                guard let self, self.selectedIndexedProject?.id == projectID else { return }
                selectedMapCatalog = nil
                selectedMapID = ""
                mapCatalogStatus = .failed(error.localizedDescription)
                clearSelectedMapVisualDocument()
                refreshSelectedScriptReadinessReportIfVisible()
            }
        }
    }

    func loadSelectedMapVisualDocumentIfNeeded() {
        guard selectedMapVisualDocument?.mapID != selectedMapID else { return }
        loadSelectedMapVisualDocument()
    }

    func loadSelectedMapVisualDocument() {
        guard !selectedMapID.isEmpty, let selectedIndexedProject else {
            clearSelectedMapVisualDocument()
            return
        }

        mapVisualTask?.cancel()
        mapVisualStatus = .loading
        let projectID = selectedIndexedProject.id
        let rootPath = selectedIndexedProject.rootPath
        let mapID = selectedMapID
        let cachedSharedCacheData = mapVisualSharedCacheDataByID[projectID]

        mapVisualTask = Task { @MainActor [weak self] in
            do {
                let payloadData = try await Task.detached(priority: .userInitiated) { () throws -> Data in
                    let sharedCache: ProjectMapVisualSharedCache
                    if let cachedSharedCacheData {
                        sharedCache = try JSONDecoder().decode(ProjectMapVisualSharedCache.self, from: cachedSharedCacheData)
                    } else {
                        let index = try GameAdapterRegistry.index(path: rootPath, fileManager: .default)
                        sharedCache = try ProjectMapVisualSharedCache.load(from: index, fileManager: .default)
                    }
                    let document = try ProjectMapVisualLoader.load(from: sharedCache, mapID: mapID, fileManager: .default)
                    return try JSONEncoder().encode(MapVisualLoadPayload(sharedCache: sharedCache, document: document))
                }.value
                guard !Task.isCancelled else { return }
                let payload = try JSONDecoder().decode(MapVisualLoadPayload.self, from: payloadData)
                guard let self,
                      self.selectedIndexedProject?.id == projectID,
                      self.selectedMapID == mapID
                else { return }

                mapVisualSharedCacheDataByID[projectID] = try? JSONEncoder().encode(payload.sharedCache)
                mapEditorSession.load(document: payload.document, preserveSelection: false)
                applyMapEditorDefaults()
                mapVisualStatus = .loaded(payload.document.mapName)
            } catch {
                guard let self,
                      self.selectedIndexedProject?.id == projectID,
                      self.selectedMapID == mapID
                else { return }
                mapEditorSession.reset()
                mapVisualStatus = .failed(error.localizedDescription)
            }
        }
    }

    private func applyMapEditorDefaults() {
        mapEditorSession.selectedMapTool = preferredMapEditorTool
        mapEditorSession.setOverlay(.grid, isVisible: userSettings.showGridByDefault)
        mapEditorSession.setOverlay(.collision, isVisible: userSettings.showCollisionByDefault)
    }

    private var preferredMapEditorTool: MapEditorTool {
        switch userSettings.editorStartupTool {
        case .select:
            .select
        case .hand:
            .hand
        case .pencil:
            .pencil
        case .eyedropper:
            .eyedropper
        }
    }

    func clearSelectedMapVisualDocument() {
        mapVisualTask?.cancel()
        mapEditorSession.reset()
        mapVisualStatus = .idle
    }

    func selectMapCell(x: Int, y: Int) {
        mapEditorSession.selectMapCell(x: x, y: y)
    }

    func selectBrush(rawValue: UInt16) {
        mapEditorSession.selectBrush(rawValue: rawValue)
    }

    func eyedropMapCell(x: Int, y: Int) {
        mapEditorSession.eyedropMapCell(x: x, y: y)
    }

    func paintMapCell(x: Int, y: Int) {
        _ = mapEditorSession.paintMapCell(x: x, y: y)
    }

    func fillMapFromSelection(to x: Int, y: Int) {
        _ = mapEditorSession.fillMapFromSelection(toX: x, y: y)
    }

    func selectMapEvent(id: String?) {
        mapEditorSession.selectMapEvent(id: id)
    }

    func moveSelectedMapEvent(toX x: Int, y: Int) {
        _ = mapEditorSession.moveSelectedMapEvent(toX: x, y: y)
    }

    func updateSelectedMapEventProperty(key: String, value: String) {
        _ = mapEditorSession.updateSelectedMapEventProperty(key: key, value: value)
    }

    func duplicateSelectedMapEvent() {
        _ = mapEditorSession.duplicateSelectedMapEvent()
    }

    func deleteSelectedMapEvent() {
        _ = mapEditorSession.deleteSelectedMapEvent()
    }

    func addObjectEvent(atX x: Int, y: Int) {
        _ = mapEditorSession.addObjectEvent(atX: x, y: y)
    }

    func undoLastMapEdit() {
        mapEditorSession.undoLastMapEdit()
    }

    func redoMapEdit() {
        mapEditorSession.redoMapEdit()
    }

    func previewSelectedMapMutationPlan() {
        _ = mapEditorSession.previewSelectedMapMutationPlan()
    }

    func applySelectedMapMutationPlan() {
        applySelectedMapEditorSessionMutationPlan()
    }

    private func applySelectedMapEditorSessionMutationPlan() {
        if mapEditorSession.latestMapEditPlan == nil {
            _ = mapEditorSession.previewSelectedMapMutationPlan()
        }

        let projectIDBeforeApply = selectedProjectID
        let mapIDBeforeApply = mapEditorSession.selectedMapVisualDocument?.mapID ?? selectedMapID
        do {
            guard let result = try mapEditorSession.applySelectedMapMutationPlan(fileManager: fileManager) else { return }
            _ = result
            refreshProjectIndexes()
            if indexedProjects.contains(where: { $0.id == projectIDBeforeApply }) {
                selectedProjectID = projectIDBeforeApply
            }
            if !mapIDBeforeApply.isEmpty {
                selectedMapID = mapIDBeforeApply
            }
            if selectedProjectID == projectIDBeforeApply {
                loadSelectedMapCatalog()
                loadSelectedMapVisualDocument()
            }
        } catch {
            mapEditorSession.recordApplyFailure(error)
        }
    }

    private func defaultProjectRoots() -> [String] {
        #if DEBUG
        guard userSettings.includeDefaultDebugProjects else { return [] }
        return ["pokeemerald", "pokefirered"]
            .map { workspaceRoot.appendingPathComponent($0).path }
            .filter { fileManager.fileExists(atPath: $0) }
        #else
        return []
        #endif
    }

    private static func inferredWorkspaceRoot() -> URL {
        #if DEBUG
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 {
            root.deleteLastPathComponent()
        }
        return root.standardizedFileURL
        #else
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath).standardizedFileURL
        #endif
    }

    private static func uniquePaths(_ paths: [String]) -> [String] {
        var seen: Set<String> = []
        var unique: [String] = []

        for path in paths {
            let standardized = URL(fileURLWithPath: path).standardizedFileURL.path
            guard seen.insert(standardized).inserted else { continue }
            unique.append(standardized)
        }

        return unique
    }

    private static func pathIsReferenceRoot(_ path: String) -> Bool {
        URL(fileURLWithPath: path).standardizedFileURL.pathComponents.contains("references")
    }

    private static func pathIsBundledAssetRoot(_ path: String) -> Bool {
        URL(fileURLWithPath: path).standardizedFileURL.pathComponents.contains(bundledAssetsDirectoryName)
    }

    private static let bundledAssetsDirectoryName = "PokemonHackStudioAssets"
    private static let bundledProjectsDirectoryName = "Projects"

    private static func libraryByAppendingBundledAssets(
        to library: PokemonHackCore.GenIIIResourceLibrary,
        fileManager: FileManager
    ) -> PokemonHackCore.GenIIIResourceLibrary {
        guard let bundledProjectsRoot = bundledAssetProjectsRoot(fileManager: fileManager) else {
            return library
        }

        let bundledLibrary = GenIIIResourceRegistry.load(
            workspaceRoot: bundledProjectsRoot.path,
            recentRoots: [],
            fileManager: fileManager
        )
        let existingSourceTitles = Set(
            library.entries
                .filter { $0.platform == .gbaSource }
                .map { $0.title.lowercased() }
        )
        let bundledEntries = bundledLibrary.entries
            .filter { $0.platform == .gbaSource }
            .filter { !existingSourceTitles.contains($0.title.lowercased()) }
            .map { Self.bundledResourceEntry($0) }

        guard !bundledEntries.isEmpty else {
            return library
        }

        let entries = (library.entries + bundledEntries).sorted { lhs, rhs in
            if lhs.platform.rawValue == rhs.platform.rawValue {
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
            return lhs.platform.rawValue < rhs.platform.rawValue
        }

        return PokemonHackCore.GenIIIResourceLibrary(
            workspaceRoot: library.workspaceRoot,
            entries: entries,
            diagnostics: library.diagnostics + bundledLibrary.diagnostics
        )
    }

    private static func bundledAssetProjectsRoot(fileManager: FileManager) -> URL? {
        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        let projectsRoot = resourceURL
            .appendingPathComponent(bundledAssetsDirectoryName)
            .appendingPathComponent(bundledProjectsDirectoryName)
            .standardizedFileURL
        guard fileManager.fileExists(atPath: projectsRoot.path) else { return nil }
        return projectsRoot
    }

    private static func bundledResourceEntry(_ entry: PokemonHackCore.GenIIIResourceEntry) -> PokemonHackCore.GenIIIResourceEntry {
        PokemonHackCore.GenIIIResourceEntry(
            id: "bundled:\(entry.id)",
            title: "\(entry.title) (Bundled)",
            path: entry.path,
            platform: entry.platform,
            family: entry.family,
            profile: entry.profile,
            variants: entry.variants,
            role: .referenceSource,
            parseStatus: entry.parseStatus,
            adapterID: entry.adapterID,
            writePolicy: .readOnly,
            modules: entry.modules,
            resourceCount: entry.resourceCount,
            items: entry.items,
            diagnostics: entry.diagnostics
        )
    }

    private static func assetCatalogFingerprint(rootPath: String, fileManager: FileManager) -> String {
        let root = URL(fileURLWithPath: rootPath).standardizedFileURL
        let trackedPaths = [
            "Makefile",
            "config.mk",
            "rom.sha1",
            "firered.sha1",
            "leafgreen.sha1",
            "data",
            "graphics",
            "sound",
            "songs",
            "src/data",
            "include",
            "constants"
        ]
        var parts = [root.path]
        for path in trackedPaths {
            let url = root.appendingPathComponent(path)
            guard let attributes = try? fileManager.attributesOfItem(atPath: url.path) else {
                continue
            }
            let modified = (attributes[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
            let size = attributes[.size] as? UInt64 ?? 0
            parts.append("\(path):\(Int(modified)):\(size)")
        }
        return parts.joined(separator: "|")
    }

    private static func summary(from index: PokemonHackCore.ProjectIndex) -> IndexedProjectSummary {
        let rootURL = URL(fileURLWithPath: index.root.path)
        let origin = projectOrigin(for: index)
        let sourceSurfaces = index.documents.map { surface(from: $0) }
        let generatedOutputs = index.generatedOutputs.map { surface(from: $0) }
        let diagnostics = index.diagnostics.map { diagnostic(from: $0, rootPath: index.root.path) }
        let buildTargets = index.buildTargets.map { target in
            IndexedBuildTargetPreview(
                id: target.id,
                name: target.name,
                kind: target.kind.rawValue,
                command: target.command.joined(separator: " "),
                outputPath: target.outputPath
            )
        }
        let missingSourceDocuments = index.documents.filter { !$0.exists && $0.role == .source }.count
        let existingSourceDocuments = index.documents.filter(\.exists).count

        return IndexedProjectSummary(
            id: index.root.path,
            title: rootURL.lastPathComponent,
            subtitle: "\(index.adapterName) · \(index.profile.rawValue)",
            rootPath: index.root.path,
            originLabel: origin.label,
            menuTitle: "\(rootURL.lastPathComponent) · \(origin.label)",
            menuSubtitle: "\(origin.detail) · \(index.adapterName) · \(index.profile.rawValue)",
            profile: index.profile.rawValue,
            adapterName: index.adapterName,
            writePolicy: index.writePolicy.rawValue,
            status: status(for: diagnostics, missingSourceDocuments: missingSourceDocuments),
            sourceDocumentCount: index.documents.count,
            existingSourceDocumentCount: existingSourceDocuments,
            missingSourceDocumentCount: missingSourceDocuments,
            generatedOutputCount: index.generatedOutputs.count,
            artifactCount: index.generatedOutputs.filter { $0.role == .artifact }.count,
            diagnosticCount: diagnostics.count,
            buildTargetCount: buildTargets.count,
            sourceSurfaces: sourceSurfaces,
            generatedOutputs: generatedOutputs,
            diagnostics: diagnostics,
            buildTargets: buildTargets
        )
    }

    private static func projectOrigin(for index: PokemonHackCore.ProjectIndex) -> (label: String, detail: String) {
        let rootURL = URL(fileURLWithPath: index.root.path).standardizedFileURL
        if index.documents.allSatisfy({ $0.role == .localInput }) {
            return ("Local Input", "Local ROM/media input")
        }
        if rootURL.pathComponents.contains("references") {
            return ("Reference", "Read-only reference source")
        }
        return ("Editable", "Editable source root")
    }

    private static func buildReport(
        from index: PokemonHackCore.ProjectIndex,
        project: IndexedProjectSummary,
        fileManager: FileManager,
        toolResolver: ToolAvailabilityResolver = ToolAvailabilityResolverFactory.pathEnvironment(),
        buildReport providedBuildReport: BuildValidationReport? = nil
    ) -> BuildPatchPlaytestReportViewState {
        let buildReport = providedBuildReport ?? BuildValidationReportBuilder.build(index: index, fileManager: fileManager, toolResolver: toolResolver)
        let playtestReport = PlaytestHandoffReportBuilder.build(index: index, fileManager: fileManager, toolResolver: toolResolver)
        let graphicsReport = index.editorModules.contains(.graphics)
            ? GraphicsDiagnosticsReportBuilder.build(index: index, fileManager: fileManager)
            : nil
        let healthReport = ToolchainHealthMatrixBuilder.build(
            index: index,
            fileManager: fileManager,
            toolResolver: toolResolver,
            buildReport: buildReport,
            playtestReport: playtestReport,
            graphicsReport: graphicsReport
        )
        let buildTargets = buildReport.targets.map(buildTargetValidation(from:))
        let generatedArtifacts = buildReport.generatedArtifacts.map(generatedArtifactValidation(from:))
        let toolchain = toolchainReadiness(from: buildReport, playtestReport: playtestReport)
        let healthMatrix = toolchainHealthMatrix(from: healthReport, rootPath: project.rootPath)
        let playtest = playtestHandoffPlan(from: playtestReport, rootPath: project.rootPath)
        let baseROMOptions = baseROMOptions(from: buildReport, rootPath: project.rootPath)
        let diagnostics = (buildReport.diagnostics + playtestReport.diagnostics + healthReport.diagnostics).map {
            diagnostic(from: $0, rootPath: project.rootPath)
        }
        let states = buildTargets.map(\.status)
            + generatedArtifacts.map(\.status)
            + toolchain.rows.map(\.status)
            + healthMatrix.rows.map(\.status)
            + [toolchain.status, healthMatrix.status, playtest.status]
            + diagnostics.map(\.severity)

        return BuildPatchPlaytestReportViewState(
            id: project.id,
            projectTitle: project.title,
            rootPath: project.rootPath,
            profile: project.profile,
            status: validationStatus(for: states),
            buildTargets: buildTargets,
            generatedArtifacts: generatedArtifacts,
            toolchain: toolchain,
            healthMatrix: healthMatrix,
            playtest: playtest,
            baseROMOptions: baseROMOptions,
            diagnostics: diagnostics
        )
    }

    private static func graphicsReport(
        from index: PokemonHackCore.ProjectIndex,
        project: IndexedProjectSummary,
        fileManager: FileManager
    ) -> GraphicsDiagnosticsReportViewState {
        let report = GraphicsDiagnosticsReportBuilder.build(index: index, fileManager: fileManager)
        let diagnostics = report.diagnostics.map {
            diagnostic(from: $0, rootPath: project.rootPath)
        }
        var rows: [GraphicsReportRow] = []

        for tileset in report.tilesets {
            let animationDetail = tileset.animation?.exists == true
                ? "\(tileset.animation?.fileCount ?? 0) animation file(s)"
                : "No animation folder"
            let layerDetail = "Layers normal \(tileset.layerSummary.normal), covered \(tileset.layerSummary.covered), split \(tileset.layerSummary.split), unknown \(tileset.layerSummary.unknown)."
            rows.append(
                GraphicsReportRow(
                    id: "tileset:\(tileset.symbol)",
                    section: .tilesets,
                    title: tileset.symbol,
                    subtitle: tileset.role,
                    detail: "\(tileset.metatileCount) metatiles; \(tileset.palettes.count) palettes; \(animationDetail). \(layerDetail)",
                    status: validationStatus(for: tileset.diagnostics.map(diagnostic(from:))),
                    source: SourceLocation(path: tileset.metatiles?.relativePath ?? tileset.tileImage?.relativePath ?? project.rootPath, symbol: tileset.symbol, line: 1),
                    tags: [tileset.role, tileset.symbol, animationDetail, layerDetail]
                )
            )

            for artifact in [tileset.tileImage, tileset.metatiles, tileset.metatileAttributes].compactMap({ $0 }) {
                rows.append(graphicsArtifactRow(artifact, tilesetSymbol: tileset.symbol))
            }

            for palette in tileset.palettes {
                rows.append(graphicsPaletteRow(palette, tilesetSymbol: tileset.symbol))
            }

            if let animation = tileset.animation {
                rows.append(graphicsAnimationRow(animation, tilesetSymbol: tileset.symbol))
            }

            rows.append(graphicsConversionPlanRow(tileset.conversionPlan))
        }

        rows.append(contentsOf: diagnostics.map { diagnostic in
            GraphicsReportRow(
                id: "diagnostic:\(diagnostic.id)",
                section: .diagnostics,
                title: diagnostic.title,
                subtitle: diagnostic.source.path,
                detail: diagnostic.message,
                status: diagnostic.severity,
                source: diagnostic.source,
                tags: [diagnostic.title, diagnostic.message]
            )
        })

        let states = rows.map(\.status) + diagnostics.map(\.severity)
        return GraphicsDiagnosticsReportViewState(
            id: project.id,
            projectTitle: project.title,
            rootPath: project.rootPath,
            profile: project.profile,
            status: validationStatus(for: states),
            tilesetCount: report.tilesets.count,
            tileImageCount: report.inventory.tileImageCount,
            paletteFileCount: report.inventory.paletteFileCount,
            animationDirectoryCount: report.inventory.animationDirectoryCount,
            unsupportedSourceArtifactCount: report.inventory.unsupportedSourceArtifactCount,
            readOnlyDetail: report.isReadOnly ? "Read-only diagnostics; no graphics tools are invoked." : "Review write policy before using this report.",
            rows: rows,
            diagnostics: diagnostics
        )
    }

    private static func defaultScriptReadinessTarget(
        for index: PokemonHackCore.ProjectIndex,
        fileManager: FileManager
    ) -> PokemonHackCore.ScriptReadinessTarget? {
        if let catalog = try? ProjectMapCatalogLoader.load(from: index, fileManager: fileManager),
           let map = catalog.maps.first {
            return ScriptReadinessTarget(kind: .map, identifier: map.id)
        }
        if let outline = try? ProjectScriptOutlineLoader.load(from: index, fileManager: fileManager),
           let label = outline.labels.first {
            return ScriptReadinessTarget(kind: .script, identifier: label.label)
        }
        return nil
    }

    private static func scriptReadinessReport(
        from report: PokemonHackCore.ScriptReadinessReport,
        project: IndexedProjectSummary
    ) -> ScriptReadinessReportViewState {
        let rows = report.checks.map {
            scriptReadinessRow(from: $0, rootPath: project.rootPath)
        }
        let diagnostics = report.diagnostics.map {
            diagnostic(from: $0, rootPath: project.rootPath)
        }
        let targetMode: ScriptReadinessTargetMode = report.target.kind == .map ? .map : .script
        let targetTitle: String
        if let map = report.mapContext {
            targetTitle = map.mapName
        } else if let script = report.scriptContext {
            targetTitle = script.label
        } else {
            targetTitle = report.target.identifier
        }

        return ScriptReadinessReportViewState(
            id: report.target.id,
            projectTitle: project.title,
            rootPath: project.rootPath,
            profile: project.profile,
            targetMode: targetMode,
            targetTitle: targetTitle,
            status: validationState(for: report.status),
            isReady: report.isReady,
            isReadOnly: report.isReadOnly,
            mapContext: report.mapContext.map {
                ScriptReadinessMapContextViewState(
                    mapID: $0.mapID,
                    mapName: $0.mapName,
                    sourcePath: $0.sourcePath,
                    layoutID: $0.layoutID,
                    scriptSourceCount: $0.scriptSourcePaths.count,
                    eventScriptCount: $0.eventScriptLabels.count
                )
            },
            scriptContext: report.scriptContext.map {
                ScriptReadinessScriptContextViewState(
                    label: $0.label,
                    kind: $0.kind.title,
                    sourcePath: $0.sourcePath,
                    sourceRole: $0.sourceRole.title,
                    commandCount: $0.commandCount,
                    textReferenceCount: $0.textReferenceCount
                )
            },
            rows: rows,
            diagnostics: diagnostics
        )
    }

    private static func scriptReadinessRow(
        from check: PokemonHackCore.ScriptReadinessCheck,
        rootPath: String
    ) -> ScriptReadinessReportRow {
        let section = scriptReadinessSection(from: check.category)
        let source = check.sourceSpan.map {
            SourceLocation(path: $0.relativePath, symbol: check.title, line: $0.startLine)
        } ?? SourceLocation(path: rootPath, symbol: check.title, line: 1)
        return ScriptReadinessReportRow(
            id: check.id,
            section: section,
            title: check.title,
            subtitle: check.status.rawValue,
            detail: check.detail,
            status: validationState(for: check.status),
            source: source,
            tags: [check.category.rawValue, check.status.rawValue, check.title, check.detail]
        )
    }

    private static func scriptReadinessSection(
        from category: PokemonHackCore.ScriptReadinessCheckCategory
    ) -> ScriptReadinessReportSection {
        switch category {
        case .source:
            .source
        case .build:
            .build
        case .playtest:
            .playtest
        case .workflow:
            .workflow
        }
    }

    private static func graphicsArtifactRow(
        _ artifact: PokemonHackCore.GraphicsArtifactStatus,
        tilesetSymbol: String
    ) -> GraphicsReportRow {
        let status: ValidationState = artifact.exists && artifact.freshness != .generatedStale && artifact.freshness != .generatedMissing ? .valid : .warning
        let checksum = artifact.sha1.map { "sha1 \($0.prefix(8))" } ?? "checksum unavailable"
        let size = artifact.sizeBytes.map { "\($0) bytes" } ?? "missing"
        let pngDetail = artifact.png.map { " PNG \($0.width)x\($0.height), bit depth \($0.bitDepth), color type \($0.colorType)." } ?? ""
        let generatedDetail = graphicsGeneratedArtifactDetail(artifact)

        return GraphicsReportRow(
            id: "artifact:\(tilesetSymbol):\(artifact.id)",
            section: .artifacts,
            title: URL(fileURLWithPath: artifact.relativePath).lastPathComponent,
            subtitle: artifact.kind.rawValue,
            detail: artifact.exists ? "\(size); \(checksum).\(pngDetail) \(generatedDetail)" : "Missing expected graphics artifact. \(generatedDetail)",
            status: status,
            source: SourceLocation(path: artifact.relativePath, symbol: tilesetSymbol, line: 1),
            tags: [tilesetSymbol, artifact.relativePath, artifact.kind.rawValue, checksum, artifact.freshness.rawValue]
        )
    }

    private static func graphicsPaletteRow(
        _ palette: PokemonHackCore.GraphicsArtifactStatus,
        tilesetSymbol: String
    ) -> GraphicsReportRow {
        let status: ValidationState = palette.exists && palette.freshness != .generatedStale && palette.freshness != .generatedMissing ? .valid : .warning
        let metadata = palette.palette
        let detail = metadata.map {
            "\($0.format); \($0.colorCount) color(s); \($0.gbaPrecisionLossCount) precision-loss color(s). \(graphicsGeneratedArtifactDetail(palette))"
        } ?? (palette.exists ? "Palette metadata was not parsed." : "Missing palette file.")

        return GraphicsReportRow(
            id: "palette:\(tilesetSymbol):\(palette.relativePath)",
            section: .palettes,
            title: URL(fileURLWithPath: palette.relativePath).lastPathComponent,
            subtitle: tilesetSymbol,
            detail: detail,
            status: status,
            source: SourceLocation(path: palette.relativePath, symbol: tilesetSymbol, line: 1),
            tags: [tilesetSymbol, palette.relativePath, metadata?.format ?? "", palette.freshness.rawValue]
        )
    }

    private static func graphicsGeneratedArtifactDetail(_ artifact: PokemonHackCore.GraphicsArtifactStatus) -> String {
        guard let generatedPath = artifact.generatedRelativePath else {
            return "No generated conversion artifact is tracked for this source."
        }
        switch artifact.freshness {
        case .generatedFresh:
            return "\(generatedPath) is fresh."
        case .generatedStale:
            return "\(generatedPath) is stale."
        case .generatedMissing:
            return "\(generatedPath) is missing."
        case .unknown:
            return "\(generatedPath) freshness is unknown."
        case .sourceOnly:
            return "No generated conversion artifact is tracked for this source."
        }
    }

    private static func graphicsAnimationRow(
        _ animation: PokemonHackCore.GraphicsAnimationStatus,
        tilesetSymbol: String
    ) -> GraphicsReportRow {
        GraphicsReportRow(
            id: "animation:\(tilesetSymbol):\(animation.relativePath)",
            section: .animations,
            title: URL(fileURLWithPath: animation.relativePath).lastPathComponent,
            subtitle: tilesetSymbol,
            detail: animation.exists ? "\(animation.fileCount) animation source file(s) found." : "No animation source directory found for this tileset.",
            status: .valid,
            source: SourceLocation(path: animation.relativePath, symbol: tilesetSymbol, line: 1),
            tags: [tilesetSymbol, animation.relativePath]
        )
    }

    private static func graphicsConversionPlanRow(
        _ plan: PokemonHackCore.GraphicsConversionPlan
    ) -> GraphicsReportRow {
        let status = plan.diagnostics.contains { $0.severity == .error }
            ? ValidationState.error
            : (plan.diagnostics.contains { $0.severity == .warning } ? .warning : .valid)
        let provenance = plan.creditMetadataPaths.isEmpty
            ? "Credit metadata needed"
            : "Credit metadata: \(plan.creditMetadataPaths.joined(separator: ", "))"
        let outputs = plan.expectedOutputs.isEmpty
            ? "No generated outputs are currently inferred."
            : "Expected outputs: \(plan.expectedOutputs.joined(separator: ", "))"

        return GraphicsReportRow(
            id: "conversion:\(plan.id)",
            section: .conversionPlans,
            title: "\(plan.tilesetSymbol) conversion preview",
            subtitle: plan.targetKind,
            detail: "\(provenance). \(plan.paletteFitSummary) \(outputs) \(plan.externalToolPlan)",
            status: status,
            source: SourceLocation(path: plan.sourcePaths.first ?? "data/tilesets", symbol: plan.tilesetSymbol, line: 1),
            tags: [plan.tilesetSymbol, plan.targetKind, provenance, plan.paletteFitSummary, outputs, "preview only"]
        )
    }

    private static func resourceLibraryViewState(
        from library: PokemonHackCore.GenIIIResourceLibrary
    ) -> ResourceLibraryViewState {
        ResourceLibraryViewState(
            id: library.workspaceRoot,
            workspaceRoot: library.workspaceRoot,
            entries: library.entries.map(resourceEntryViewState(from:)),
            diagnostics: library.diagnostics.map { diagnostic(from: $0, rootPath: library.workspaceRoot) }
        )
    }

    private static func assetCatalogViewState(
        from catalog: PokemonHackCore.GenIIIAssetCatalog,
        project: IndexedProjectSummary
    ) -> ResourceAssetCatalogViewState {
        let diagnostics = catalog.diagnostics.map {
            diagnostic(from: $0, rootPath: catalog.root.path)
        }
        let rows = catalog.assets.map {
            resourceAssetRow(from: $0, rootPath: catalog.root.path)
        }
        var countsByCategory: [String: Int] = [:]
        for row in rows {
            countsByCategory[row.category, default: 0] += 1
        }
        var counts: [ResourceAssetCategoryCount] = []
        for (category, count) in countsByCategory {
            counts.append(ResourceAssetCategoryCount(category: category, count: count))
        }
        counts.sort { lhs, rhs in
            if lhs.category == rhs.category {
                return lhs.count > rhs.count
            }
            return lhs.category < rhs.category
        }
        let availabilityCounts = catalog.availabilityCounts.map {
            ResourceAssetAvailabilityCount(availability: $0.availability.rawValue, count: $0.count)
        }

        return ResourceAssetCatalogViewState(
            id: catalog.root.path,
            projectTitle: project.title,
            rootPath: catalog.root.path,
            profile: catalog.profile.rawValue,
            assetCount: rows.count,
            categoryCounts: counts,
            availabilityCounts: availabilityCounts,
            rows: rows,
            diagnostics: diagnostics
        )
    }

    private static func resourceAssetRow(
        from asset: PokemonHackCore.GenIIIAsset,
        rootPath: String
    ) -> ResourceAssetRowViewState {
        let diagnostics = asset.diagnostics.map {
            diagnostic(from: $0, rootPath: rootPath)
        }
        let path = asset.relativePath.isEmpty ? rootPath : asset.relativePath
        let sourceSpan = asset.sourceSpan ?? PokemonHackCore.SourceSpan(relativePath: path, startLine: 1)
        let source = SourceLocation(path: sourceSpan.relativePath, symbol: asset.title, line: sourceSpan.startLine)
        let targetModule = asset.navigationTarget.flatMap { module(from: $0.module) }
        let sizeSummary = asset.sizeBytes.map { "\($0) bytes" } ?? "size unavailable"
        let checksumSummary = asset.sha1.map { "sha1 \($0.prefix(8))" } ?? "checksum skipped"
        let facts = asset.facts.map { Fact(label: $0.label, value: $0.value) }
        let searchFields = [
            asset.title,
            asset.subtitle,
            path,
            asset.category.rawValue,
            asset.kind,
            asset.role.rawValue,
            asset.status.rawValue,
            sizeSummary,
            checksumSummary,
            asset.navigationTarget?.identifier ?? ""
        ] + asset.tags + facts.map { "\($0.label) \($0.value)" } + diagnostics.map { "\($0.title) \($0.message) \($0.source.path)" }

        return ResourceAssetRowViewState(
            id: asset.id,
            title: asset.title,
            subtitle: asset.subtitle,
            path: path,
            category: asset.category.rawValue,
            kind: asset.kind,
            role: asset.role.rawValue,
            status: validationState(for: asset.availability),
            availability: asset.availability.rawValue,
            availabilitySummary: availabilitySummary(for: asset.availability),
            affectsResourceAvailability: asset.availability.affectsResourceAvailability,
            sizeSummary: sizeSummary,
            checksumSummary: checksumSummary,
            source: source,
            tags: asset.tags,
            facts: facts,
            diagnostics: diagnostics,
            targetModule: targetModule,
            targetID: asset.navigationTarget?.identifier,
            searchBlob: searchFields.joined(separator: " ").lowercased()
        )
    }

    private static func resourceEntryViewState(
        from entry: PokemonHackCore.GenIIIResourceEntry
    ) -> ResourceLibraryEntryViewState {
        let path = entry.path.isEmpty ? "Missing local media" : entry.path
        let diagnostics = entry.diagnostics.map { diagnostic(from: $0, rootPath: path) }
        let status = entry.parseStatus == .missing
            ? .warning
            : validationStatus(for: diagnostics.map(\.severity))
        let variants = entry.variants.map(\.title).prefix(3).joined(separator: ", ")
        let modules = entry.modules.map(\.rawValue).prefix(4).joined(separator: ", ")

        return ResourceLibraryEntryViewState(
            id: entry.id,
            title: entry.title,
            path: path,
            platform: entry.platform.rawValue,
            family: entry.family.rawValue,
            profile: entry.profile.rawValue,
            role: entry.role.rawValue,
            writePolicy: entry.writePolicy.rawValue,
            parseStatus: entry.parseStatus.rawValue,
            status: status,
            variantSummary: variants.isEmpty ? "No variants detected" : variants,
            moduleSummary: modules.isEmpty ? "No editor modules" : modules,
            resourceCount: entry.resourceCount,
            diagnosticCount: entry.diagnostics.count,
            items: entry.items.map { resourceItemViewState(from: $0, entryPath: path) },
            diagnostics: diagnostics,
            source: SourceLocation(path: path, symbol: entry.adapterID ?? entry.profile.rawValue, line: 1)
        )
    }

    private static func resourceItemViewState(
        from item: PokemonHackCore.GenIIIResourceItem,
        entryPath: String
    ) -> ResourceLibraryItemViewState {
        let title = URL(fileURLWithPath: item.path).lastPathComponent.isEmpty
            ? item.kind
            : URL(fileURLWithPath: item.path).lastPathComponent
        let locationSummary = resourceLocationSummary(offset: item.offset, size: item.size)
        let sizeSummary = resourceSizeSummary(size: item.size, uncompressedSize: item.uncompressedSize)
        let checksumSummary = item.sha1.map { "sha1 \($0.prefix(8))" } ?? "checksum unavailable"
        let sourcePath = item.path.isEmpty ? entryPath : item.path

        return ResourceLibraryItemViewState(
            id: item.id,
            title: title,
            path: item.path,
            kind: item.kind,
            category: item.category,
            locationSummary: locationSummary,
            sizeSummary: sizeSummary,
            checksumSummary: checksumSummary,
            source: SourceLocation(path: sourcePath, symbol: item.kind, line: 1),
            tags: [
                item.kind,
                item.category,
                item.path,
                locationSummary,
                sizeSummary,
                checksumSummary
            ]
        )
    }

    private static func resourceLocationSummary(offset: UInt64?, size: UInt64?) -> String {
        guard let offset else { return "source path" }
        if let size {
            return "0x\(String(offset, radix: 16, uppercase: true)) + \(size) bytes"
        }
        return "0x\(String(offset, radix: 16, uppercase: true))"
    }

    private static func resourceSizeSummary(size: UInt64?, uncompressedSize: UInt64?) -> String {
        switch (size, uncompressedSize) {
        case let (.some(size), .some(uncompressedSize)):
            return "\(size) bytes compressed; \(uncompressedSize) bytes unpacked"
        case let (.some(size), .none):
            return "\(size) bytes"
        case let (.none, .some(uncompressedSize)):
            return "\(uncompressedSize) bytes unpacked"
        case (.none, .none):
            return "size unavailable"
        }
    }

    private static func buildTargetValidation(
        from validation: PokemonHackCore.BuildTargetValidation
    ) -> BuildTargetValidationViewState {
        let target = validation.target
        let command = target.command.joined(separator: " ")
        let status = validationStatus(for: validation.diagnostics.map(diagnostic(from:)))
        let detail: String

        if let output = validation.output {
            if output.exists {
                let checksum = output.sha1.map { "sha1 \($0.prefix(8))" } ?? "checksum unavailable"
                detail = "\(output.relativePath) exists; \(checksum); checksum \(output.checksumStatus.rawValue); freshness \(output.freshnessStatus.rawValue)."
            } else {
                detail = "\(output.relativePath) is expected but not present; checksum \(output.checksumStatus.rawValue); freshness \(output.freshnessStatus.rawValue)."
            }
        } else {
            detail = validation.commandTool?.isAvailable == false
                ? "\(validation.commandTool?.name ?? "tool") is not available."
                : "No output artifact is declared for this target."
        }

        return BuildTargetValidationViewState(
            id: target.id,
            name: target.name,
            kind: target.kind.rawValue,
            command: command,
            outputPath: target.outputPath,
            status: status,
            detail: detail,
            source: SourceLocation(path: "Makefile", symbol: command.isEmpty ? target.id : command, line: 1)
        )
    }

    private static func generatedArtifactValidation(
        from artifact: PokemonHackCore.GeneratedArtifactInventoryItem
    ) -> GeneratedArtifactValidationViewState {
        let path = artifact.relativePath
        let title = URL(fileURLWithPath: path).lastPathComponent.isEmpty
            ? path
            : URL(fileURLWithPath: path).lastPathComponent
        let status: ValidationState = artifact.exists ? .valid : .warning
        let freshnessSummary = artifact.exists
            ? "\(artifact.matchCount) generated path\(artifact.matchCount == 1 ? "" : "s") matched."
            : "No generated files matched this adapter expectation."
        let checksumSummary = artifact.matchedPaths.prefix(3).joined(separator: ", ")

        return GeneratedArtifactValidationViewState(
            id: path,
            title: title,
            path: path,
            role: artifact.role.rawValue,
            exists: artifact.exists,
            checksumSummary: checksumSummary.isEmpty ? "Checksum is not computed for this generated-output group." : checksumSummary,
            freshnessSummary: freshnessSummary,
            status: status,
            source: SourceLocation(path: path, symbol: artifact.kind.rawValue, line: 1)
        )
    }

    private static func baseROMOptions(
        from report: PokemonHackCore.BuildValidationReport,
        rootPath: String
    ) -> [BaseROMOptionViewState] {
        var outputsByExpectation: [String: PokemonHackCore.BuildOutputValidation] = [:]
        for target in report.targets {
            guard let output = target.output, let expectation = output.expectation else { continue }
            if let existing = outputsByExpectation[expectation.relativePath], existing.exists {
                continue
            }
            outputsByExpectation[expectation.relativePath] = output
        }

        return report.sha1Expectations.map { expectation in
            let output = outputsByExpectation[expectation.relativePath]
            let path = output?.absolutePath ?? URL(fileURLWithPath: rootPath)
                .appendingPathComponent(expectation.relativePath)
                .standardizedFileURL
                .path
            let titlePath = output?.relativePath ?? expectation.relativePath
            let title = URL(fileURLWithPath: titlePath).lastPathComponent.isEmpty
                ? titlePath
                : URL(fileURLWithPath: titlePath).lastPathComponent
            let sha1 = output?.sha1 ?? expectation.expectedSHA1
            let status: ValidationState
            if output?.exists == true {
                status = output?.checksumStatus == .matched ? .valid : .warning
            } else {
                status = .warning
            }
            let detail = output?.exists == true
                ? "Build output is present; selected ROM can be checked against \(expectation.relativePath)."
                : "Build output is not present yet; this remains a known SHA1 candidate only."

            return BaseROMOptionViewState(
                id: "project:\(expectation.relativePath):\(path)",
                title: title,
                path: path,
                subtitle: "Project SHA1 candidate",
                detail: detail,
                status: status,
                sourceKind: "Project",
                sha1Summary: sha1.map { "sha1 \($0.prefix(8))" } ?? "sha1 unavailable"
            )
        }
    }

    private static func baseROMOption(
        fromResourceEntry entry: ResourceLibraryEntryViewState
    ) -> BaseROMOptionViewState {
        let checksum = entry.items
            .compactMap { item in
                item.checksumSummary.hasPrefix("sha1 ") ? item.checksumSummary : nil
            }
            .first
        return BaseROMOptionViewState(
            id: "resource:\(entry.id)",
            title: entry.title,
            path: entry.path,
            subtitle: "Resource library ROM",
            detail: entry.variantSummary.isEmpty ? entry.moduleSummary : entry.variantSummary,
            status: entry.status,
            sourceKind: "Resources",
            sha1Summary: checksum ?? "sha1 unavailable"
        )
    }

    private func uniqueBaseROMOptions(_ options: [BaseROMOptionViewState]) -> [BaseROMOptionViewState] {
        var seen: Set<String> = []
        var unique: [BaseROMOptionViewState] = []
        for option in options {
            let key = option.path.isEmpty ? option.id : option.path
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            unique.append(option)
        }
        return unique
    }

    private static func toolchainReadiness(
        from report: PokemonHackCore.BuildValidationReport,
        playtestReport: PokemonHackCore.PlaytestHandoffReport
    ) -> ToolchainReadinessViewState {
        var rows = report.targets.compactMap { target -> BuildReportRow? in
            guard let tool = target.commandTool else { return nil }
            let status: ValidationState = tool.isAvailable ? .valid : .error
            return BuildReportRow(
                id: "toolchain:build:\(target.id):\(tool.name)",
                section: .toolchain,
                title: tool.name,
                subtitle: tool.isAvailable ? "Available" : "Missing",
                detail: tool.resolvedPath ?? "Required by \(target.target.name), but no executable was found.",
                status: status,
                source: SourceLocation(path: "Makefile", symbol: tool.name, line: 1),
                tags: [tool.name, target.target.name, tool.resolvedPath ?? ""]
            )
        }

        let emulator = playtestReport.emulator
        rows.append(
            BuildReportRow(
                id: "toolchain:playtest:\(emulator.name)",
                section: .toolchain,
                title: emulator.name,
                subtitle: emulator.isAvailable ? "Available" : "Missing",
                detail: emulator.resolvedPath ?? "mGBA was not found in PATH or common macOS application locations.",
                status: emulator.isAvailable ? .valid : .warning,
                source: SourceLocation(path: report.rootPath, symbol: emulator.name, line: 1),
                tags: [emulator.name, emulator.resolvedPath ?? ""]
            )
        )

        if rows.isEmpty {
            rows.append(
                BuildReportRow(
                    id: "toolchain:none",
                    section: .toolchain,
                    title: "Toolchain",
                    subtitle: "No external commands",
                    detail: "No build or playtest tools are required by this report.",
                    status: .valid,
                    source: SourceLocation(path: report.rootPath, symbol: report.adapterID, line: 1)
                )
            )
        }

        return ToolchainReadinessViewState(
            id: "toolchain:\(report.rootPath)",
            status: validationStatus(for: rows.map(\.status)),
            detail: rows.contains { $0.status != .valid } ? "Toolchain readiness needs review." : "Toolchain inputs are discoverable.",
            rows: rows
        )
    }

    private static func toolchainHealthMatrix(
        from report: PokemonHackCore.ToolchainHealthMatrixReport,
        rootPath: String
    ) -> ToolchainHealthMatrixViewState {
        let rows = report.rows.map { row in
            let source = row.source.map {
                SourceLocation(path: $0.relativePath, symbol: row.title, line: $0.startLine)
            } ?? SourceLocation(path: rootPath, symbol: row.title, line: 1)
            return BuildReportRow(
                id: "health:\(row.id)",
                section: .healthMatrix,
                title: row.title,
                subtitle: "\(healthCategoryTitle(row.category)) · \(row.subject)",
                detail: row.detail,
                status: validationState(for: row.status),
                source: source,
                tags: [
                    row.category.rawValue,
                    row.status.rawValue,
                    row.subject,
                    row.detail,
                    row.resolvedPath ?? ""
                ],
                healthCategory: WorkbenchHealthCheckCategory(rawValue: row.category.rawValue),
                healthStatus: WorkbenchHealthCheckStatus(rawValue: row.status.rawValue)
            )
        }

        let status = validationStatus(for: rows.map(\.status))
        let summary = report.summary.all
        return ToolchainHealthMatrixViewState(
            id: "health:\(report.rootPath)",
            status: status,
            detail: "Preview-only matrix: \(summary.ready) ready, \(summary.warnings) warning, \(summary.errors) error, \(summary.notApplicable) not applicable.",
            readyCount: summary.ready,
            warningCount: summary.warnings,
            errorCount: summary.errors,
            notApplicableCount: summary.notApplicable,
            rows: rows
        )
    }

    private static func healthCategoryTitle(_ category: PokemonHackCore.ToolchainHealthCategory) -> String {
        switch category {
        case .externalTools:
            "External Tools"
        case .romHeaders:
            "ROM Headers"
        case .graphicsConversion:
            "Graphics Conversion"
        case .generatedArtifacts:
            "Generated Artifacts"
        }
    }

    private static func validationState(for status: PokemonHackCore.ToolchainHealthStatus) -> ValidationState {
        switch status {
        case .ready, .notApplicable:
            .valid
        case .warning:
            .warning
        case .error:
            .error
        }
    }

    private static func playtestHandoffPlan(
        from report: PokemonHackCore.PlaytestHandoffReport,
        rootPath: String
    ) -> PlaytestHandoffPlanViewState {
        let status = validationStatus(for: report.diagnostics.map(diagnostic(from:)))
        let romPath = report.romCandidate?.relativePath ?? report.romCandidate?.absolutePath
        let detail = report.isRunnable
            ? "ROM output and emulator are available for explicit mGBA launch."
            : "Handoff is planned only; review ROM output and emulator readiness."
        let artifacts = report.session.artifacts.map { artifact in
            PlaytestArtifactViewState(
                id: "\(artifact.kind.rawValue):\(artifact.relativePath)",
                kind: artifact.kind.rawValue,
                path: artifact.relativePath,
                detail: artifact.detail,
                source: SourceLocation(path: artifact.relativePath, symbol: artifact.kind.rawValue, line: 1)
            )
        }

        return PlaytestHandoffPlanViewState(
            id: "playtest:\(rootPath)",
            emulator: report.emulator.name,
            romPath: romPath,
            arguments: report.session.arguments,
            artifacts: artifacts,
            isRunnable: report.isRunnable,
            status: status,
            detail: detail,
            source: SourceLocation(path: romPath ?? rootPath, symbol: report.emulator.name, line: 1)
        )
    }

    private static func playtestLaunchResult(
        from result: PokemonHackCore.PlaytestLaunchResult,
        rootPath: String
    ) -> PlaytestLaunchResultViewState {
        let status: ValidationState
        let detail: String
        switch result.status {
        case .launched:
            status = .valid
            detail = "mGBA launched with process \(result.processID.map(String.init) ?? "unknown")."
        case .blocked:
            status = .warning
            detail = result.diagnostics.last?.message ?? "mGBA launch is blocked by the current handoff report."
        case .failed:
            status = .error
            detail = result.diagnostics.last?.message ?? "mGBA launch failed."
        }

        let artifacts = result.artifacts.map { artifact in
            PlaytestArtifactViewState(
                id: "\(artifact.kind.rawValue):\(artifact.relativePath)",
                kind: artifact.kind.rawValue,
                path: artifact.relativePath,
                detail: artifact.exists ? "\(artifact.detail) Created." : artifact.detail,
                source: SourceLocation(path: artifact.relativePath, symbol: artifact.kind.rawValue, line: 1)
            )
        }
        let command = result.command.joined(separator: " ")
        let sourcePath = result.romPath ?? result.emulatorPath ?? rootPath

        return PlaytestLaunchResultViewState(
            id: "playtest-launch:\(rootPath)",
            status: status,
            statusLabel: result.status.rawValue,
            detail: detail,
            emulatorPath: result.emulatorPath,
            romPath: result.romPath,
            command: command,
            processID: result.processID.map { "PID \($0)" } ?? result.status.rawValue,
            artifacts: artifacts,
            source: SourceLocation(path: sourcePath, symbol: "mGBA", line: 1)
        )
    }

    private static func patchManifestReportViewState(
        from report: PokemonHackCore.PatchManifestReport,
        patchPath: String,
        rootPath: String
    ) -> PatchManifestReportViewState {
        let patchSourcePath = report.patch.path ?? patchPath
        let title = URL(fileURLWithPath: patchSourcePath).lastPathComponent
        let format = report.patch.summary?.format.rawValue.uppercased() ?? "unknown"
        let embedded = report.patch.summary?.hasEmbeddedChecksums == true ? "embedded checksums" : "no embedded checksums"
        let size = report.patch.sizeBytes.map { "\($0) bytes" } ?? "size unavailable"
        let compatibility = compatibilityLabel(for: report.compatibilityStatus)
        let status = validationState(for: report.compatibilityStatus)
        let selectedBaseROM = report.selectedBaseROM.map {
            selectedBaseROMViewState(from: $0, compatibility: report.compatibilityStatus)
        }
        let candidates = report.baseROMCandidates.map {
            patchBaseROMCandidateViewState(from: $0, rootPath: report.projectRoot ?? rootPath)
        }
        let diagnostics = report.diagnostics.map { diagnostic(from: $0, rootPath: rootPath) }
        let dryRuns = report.dryRunPlans.map { plan in
            let rows = plan.diagnostics.map { diagnostic(from: $0, rootPath: rootPath) }
            return PatchDryRunPlanViewState(
                id: plan.id,
                title: plan.title,
                steps: plan.steps,
                diagnostics: rows,
                status: validationStatus(for: rows.map(\.severity))
            )
        }
        var rows: [BuildReportRow] = [
            BuildReportRow(
                id: "patch:metadata",
                section: .patchManifest,
                title: title.isEmpty ? "Patch" : title,
                subtitle: "\(format) · \(compatibility)",
                detail: "\(size); \(embedded).",
                status: status,
                source: SourceLocation(path: patchSourcePath, symbol: format, line: 1),
                tags: [patchSourcePath, format, compatibility]
            )
        ]
        if let selected = selectedBaseROM {
            rows.append(
                BuildReportRow(
                    id: "patch:selected-base-rom",
                    section: .patchManifest,
                    title: selected.title,
                    subtitle: selected.sha1Summary,
                    detail: selected.detail,
                    status: selected.status,
                    source: SourceLocation(path: selected.path, symbol: selected.title, line: 1),
                    tags: [selected.path, selected.sha1Summary, selected.matchedCandidate ?? ""]
                )
            )
        }
        rows.append(contentsOf: candidates.map { candidate in
            BuildReportRow(
                id: "patch:candidate:\(candidate.id)",
                section: .patchManifest,
                title: candidate.title,
                subtitle: candidate.subtitle,
                detail: candidate.detail,
                status: candidate.status,
                source: candidate.source,
                tags: [candidate.sha1Summary, candidate.source.path]
            )
        })
        rows.append(contentsOf: dryRuns.map { plan in
            BuildReportRow(
                id: "patch:dry-run:\(plan.id)",
                section: .patchManifest,
                title: plan.title,
                subtitle: "\(plan.steps.count) preview step\(plan.steps.count == 1 ? "" : "s")",
                detail: plan.steps.joined(separator: " "),
                status: plan.status,
                source: SourceLocation(path: patchSourcePath, symbol: plan.id, line: 1),
                tags: plan.steps
            )
        })
        rows.append(contentsOf: diagnostics.map(BuildReportRow.init(diagnostic:)))

        return PatchManifestReportViewState(
            id: "patch-manifest:\(patchSourcePath)",
            patchPath: patchSourcePath,
            patchTitle: title.isEmpty ? "Patch" : title,
            patchSubtitle: "\(format) · \(compatibility)",
            patchDetail: "\(size); \(embedded).",
            compatibilityLabel: compatibility,
            status: validationStatus(for: [status] + diagnostics.map(\.severity)),
            selectedBaseROM: selectedBaseROM,
            baseROMCandidates: candidates,
            dryRunPlans: dryRuns,
            diagnostics: diagnostics,
            rows: rows
        )
    }

    private static func selectedBaseROMViewState(
        from selected: PokemonHackCore.PatchSelectedBaseROM,
        compatibility: PokemonHackCore.PatchManifestCompatibilityStatus
    ) -> PatchSelectedBaseROMViewState {
        let title = URL(fileURLWithPath: selected.absolutePath).lastPathComponent
        let status: ValidationState
        if !selected.exists {
            status = .warning
        } else if compatibility == .compatible {
            status = .valid
        } else if compatibility == .baseROMMismatch {
            status = .warning
        } else {
            status = .warning
        }
        let size = selected.sizeBytes.map { "\($0) bytes" } ?? "size unavailable"
        let match = selected.matchedCandidateRelativePath
        let detail = match.map { "\(size); matches candidate \($0)." } ?? "\(size); no candidate match."
        return PatchSelectedBaseROMViewState(
            id: selected.absolutePath,
            title: title.isEmpty ? "Selected base ROM" : title,
            path: selected.absolutePath,
            detail: detail,
            status: status,
            sha1Summary: selected.sha1.map { "sha1 \($0.prefix(8))" } ?? "sha1 unavailable",
            matchedCandidate: match
        )
    }

    private static func patchBaseROMCandidateViewState(
        from candidate: PokemonHackCore.PatchBaseROMCandidate,
        rootPath: String
    ) -> PatchBaseROMCandidateViewState {
        let title = URL(fileURLWithPath: candidate.builtOutputPath ?? candidate.relativePath).lastPathComponent
        let sha1 = candidate.builtOutputSHA1 ?? candidate.expectedSHA1
        let subtitle = candidate.exists ? "Build output present" : "Known SHA1 candidate"
        let detail = candidate.builtOutputPath.map { "Expected by \(candidate.relativePath); output \($0)." }
            ?? "Expected by \(candidate.relativePath)."
        return PatchBaseROMCandidateViewState(
            id: candidate.relativePath,
            title: title.isEmpty ? candidate.relativePath : title,
            subtitle: subtitle,
            detail: detail,
            status: candidate.exists ? .valid : .warning,
            sha1Summary: sha1.map { "sha1 \($0.prefix(8))" } ?? "sha1 unavailable",
            source: SourceLocation(path: candidate.builtOutputPath ?? candidate.relativePath, symbol: candidate.relativePath, line: 1)
        )
    }

    private static func compatibilityLabel(
        for status: PokemonHackCore.PatchManifestCompatibilityStatus
    ) -> String {
        switch status {
        case .compatible:
            "Base ROM matched"
        case .needsBaseROM:
            "Needs base ROM"
        case .baseROMMismatch:
            "Base ROM mismatch"
        case .unknown:
            "Compatibility unknown"
        case .invalidPatch:
            "Invalid patch"
        }
    }

    private static func validationState(
        for status: PokemonHackCore.PatchManifestCompatibilityStatus
    ) -> ValidationState {
        switch status {
        case .compatible:
            .valid
        case .needsBaseROM, .baseROMMismatch, .unknown:
            .warning
        case .invalidPatch:
            .error
        }
    }

    private static func exportPayload(
        from row: BuildReportRow
    ) -> BuildReportRowExportPayload {
        BuildReportRowExportPayload(
            section: row.section.rawValue,
            title: row.title,
            subtitle: row.subtitle,
            detail: row.detail,
            status: row.status.rawValue,
            path: row.source.path,
            symbol: row.source.symbol,
            tags: row.tags
        )
    }

    private static func exportPayload(
        fromPlaytest report: BuildPatchPlaytestReportViewState
    ) -> PlaytestReportExportPayload {
        PlaytestReportExportPayload(
            emulator: report.playtest.emulator,
            romPath: report.playtest.romPath,
            arguments: report.playtest.arguments,
            artifacts: report.playtest.artifacts.map {
                PlaytestArtifactExportPayload(kind: $0.kind, path: $0.path, detail: $0.detail)
            },
            isRunnable: report.playtest.isRunnable,
            status: report.playtest.status.rawValue,
            detail: report.playtest.detail
        )
    }

    private static func surface(from document: SourceDocument) -> IndexedSourceSurface {
        let title = URL(fileURLWithPath: document.relativePath).lastPathComponent
        let displayTitle = title.isEmpty ? document.relativePath : title
        let role = document.role.rawValue
        let kind = document.kind.rawValue

        return IndexedSourceSurface(
            id: "\(role):\(document.relativePath)",
            title: displayTitle,
            subtitle: "\(kind) · \(role)",
            kind: kind,
            role: role,
            exists: document.exists,
            preservesUnknownFields: document.preservesUnknownFields,
            validation: document.exists || document.role != .source ? .valid : .warning,
            source: SourceLocation(path: document.relativePath, symbol: kind, line: 1)
        )
    }

    private static func diagnostic(
        from diagnostic: PokemonHackCore.Diagnostic,
        rootPath: String
    ) -> IndexedDiagnosticRow {
        let span = diagnostic.span
        let path = span?.relativePath ?? rootPath

        return IndexedDiagnosticRow(
            id: diagnostic.id,
            title: diagnostic.code,
            message: diagnostic.message,
            severity: validationState(for: diagnostic.severity),
            source: SourceLocation(path: path, symbol: diagnostic.code, line: span?.startLine ?? 1)
        )
    }

    private static func moveCatalog(
        from catalog: PokemonHackCore.ProjectMoveCatalog,
        project: IndexedProjectSummary
    ) -> MoveCatalogViewState {
        let rootPath = project.rootPath

        let moves = catalog.moves.map { move in
            let diagnostics = move.diagnostics.map { diagnostic(from: $0, rootPath: rootPath) }
            let battleFacts = move.facts
                .filter { !["Index", "Lines"].contains($0.label) }
                .map { Fact(label: displayFactLabel($0.label), value: $0.value) }
            let facts = moveFacts(
                ordinal: move.ordinal,
                flags: move.flags,
                sourceSpan: move.sourceSpan,
                battleFacts: battleFacts
            )
            let source = SourceLocation(
                path: move.sourceSpan.relativePath,
                symbol: move.moveID,
                line: move.sourceSpan.startLine
            )
            let tmhmLearners = move.machineMemberships.flatMap(machineLearnerRows)
            let tutorLearners = move.tutorMemberships.flatMap(tutorLearnerRows)
            let learnedBy = move.learnedBy
                .filter { $0.bucket != .tmhm && $0.bucket != .tutor }
                .map(learnsetLearnerRow)
            let searchBlob = (
                [
                    move.moveID,
                    move.displayName,
                    move.sourceSpan.relativePath,
                    move.sourcePreview ?? ""
                ]
                + move.flags
                + facts.flatMap { [$0.label, $0.value] }
                + tmhmLearners.flatMap { [$0.speciesID, $0.detail, $0.source.path] }
                + tutorLearners.flatMap { [$0.speciesID, $0.detail, $0.source.path] }
                + learnedBy.flatMap { [$0.speciesID, $0.detail, $0.bucketTitle, $0.source.path] }
                + diagnostics.flatMap { [$0.title, $0.message, $0.source.path] }
            )
            .joined(separator: " ")
            .lowercased()

            return MoveDetailViewState(
                id: move.moveID,
                moveID: move.moveID,
                displayName: move.displayName,
                status: validationStatus(for: diagnostics.map(\.severity)),
                facts: facts,
                battleFacts: battleFacts,
                source: source,
                sourcePreview: move.sourcePreview,
                tmhmLearners: tmhmLearners,
                tutorLearners: tutorLearners,
                learnedBy: learnedBy,
                diagnostics: diagnostics,
                searchBlob: searchBlob
            )
        }

        let diagnostics = catalog.diagnostics.map { diagnostic(from: $0, rootPath: rootPath) }
        return MoveCatalogViewState(
            id: "moves:\(project.id)",
            projectTitle: project.title,
            rootPath: project.rootPath,
            profile: catalog.profile.rawValue,
            status: validationStatus(for: moves.map(\.status) + diagnostics.map(\.severity)),
            moveCount: catalog.summary.moveCount,
            learnsetEntryCount: catalog.summary.learnsetReferenceCount,
            tmhmMoveCount: catalog.summary.machineMoveCount,
            tutorMoveCount: catalog.summary.tutorMoveCount,
            moves: moves.sorted { $0.moveID < $1.moveID },
            diagnostics: diagnostics
        )
    }

    private static func machineLearnerRows(_ membership: PokemonHackCore.MoveMachineMembership) -> [MoveLearnerRowViewState] {
        membership.eligibleSpeciesIDs.map { speciesID in
            membershipRow(
                id: "\(membership.id):\(speciesID)",
                speciesID: speciesID,
                bucket: .tmhm,
                detail: membership.token,
                span: membership.learnsetSourceSpans.first ?? membership.sourceSpan
            )
        }
    }

    private static func tutorLearnerRows(_ membership: PokemonHackCore.MoveTutorMembership) -> [MoveLearnerRowViewState] {
        membership.eligibleSpeciesIDs.map { speciesID in
            membershipRow(
                id: "\(membership.id):\(speciesID)",
                speciesID: speciesID,
                bucket: .tutor,
                detail: membership.tutorSymbol,
                span: membership.learnsetSourceSpans.first ?? membership.sourceSpan
            )
        }
    }

    private static func learnsetLearnerRow(_ membership: PokemonHackCore.MoveLearnsetMembership) -> MoveLearnerRowViewState {
        let levelDetail = membership.level.map { "Level \($0)" }
        return membershipRow(
            id: membership.id,
            speciesID: membership.speciesID,
            bucket: membership.bucket,
            detail: levelDetail ?? membership.bucket.rawValue,
            span: membership.sourceSpan
        )
    }

    private static func membershipRow(
        id: String,
        speciesID: String?,
        bucket: PokemonHackCore.LearnsetBucket,
        detail: String,
        span: PokemonHackCore.SourceSpan?
    ) -> MoveLearnerRowViewState {
        let title = speciesID ?? "All species"
        return MoveLearnerRowViewState(
            id: id,
            speciesID: title,
            bucket: bucket,
            detail: detail,
            source: SourceLocation(
                path: span?.relativePath ?? "source unavailable",
                symbol: speciesID ?? title,
                line: span?.startLine ?? 1
            )
        )
    }

    private static func moveFacts(
        ordinal: Int?,
        flags: [String],
        sourceSpan: PokemonHackCore.SourceSpan,
        battleFacts: [Fact]
    ) -> [Fact] {
        var facts = battleFacts
        if let ordinal {
            facts.insert(Fact(label: "Index", value: "\(ordinal)"), at: 0)
        }
        if !flags.isEmpty {
            facts.append(Fact(label: "Flags", value: flags.joined(separator: ", ")))
        }
        facts.append(Fact(label: "Lines", value: "\(sourceSpan.startLine)-\(sourceSpan.endLine)"))
        return facts
    }

    private static func battleFacts(
        effect: String?,
        power: String?,
        type: String?,
        accuracy: String?,
        pp: String?,
        secondaryEffectChance: String?,
        target: String?,
        priority: String?
    ) -> [Fact] {
        [
            ("Effect", effect),
            ("Power", power),
            ("Type", type),
            ("Accuracy", accuracy),
            ("PP", pp),
            ("Secondary Effect", secondaryEffectChance),
            ("Target", target),
            ("Priority", priority)
        ].compactMap { label, value in
            value.map { Fact(label: label, value: $0) }
        }
    }

    private static func displayFactLabel(_ label: String) -> String {
        switch label {
        case "pp":
            "PP"
        case "tmhm":
            "TM/HM"
        default:
            label
                .replacingOccurrences(of: "_", with: " ")
                .replacingOccurrences(of: "secondaryEffectChance", with: "Secondary Effect")
                .replacingOccurrences(of: "base", with: "Base ")
                .capitalized
        }
    }

    private static func record(from record: PokemonHackCore.SourceIndexRecord) -> WorkbenchRecord {
        let diagnostics = record.diagnostics
        let validation = validationStatus(for: diagnostics.map { diagnostic(from: $0) })
        let notes = diagnostics.isEmpty
            ? ["Read-only source index record."]
            : diagnostics.map { "\($0.code): \($0.message)" }

        return WorkbenchRecord(
            title: record.title,
            subtitle: record.subtitle,
            module: module(from: record.module),
            source: SourceLocation(
                path: record.sourceSpan.relativePath,
                symbol: record.title,
                line: record.sourceSpan.startLine
            ),
            validation: validation,
            isDirty: false,
            tags: record.tags,
            facts: record.facts.map { Fact(label: $0.label, value: $0.value) },
            notes: notes,
            preview: record.preview
        )
    }

    private static func module(from module: PokemonHackCore.SourceIndexModule) -> WorkbenchModule {
        switch module {
        case .scripts:
            .scripts
        case .text:
            .text
        case .pokemon, .learnsets, .evolutions, .pokedex:
            .pokemon
        case .moves:
            .moves
        case .trainers:
            .trainers
        case .items:
            .items
        case .encounters:
            .encounters
        }
    }

    private static func module(from module: PokemonHackCore.EditorModule) -> WorkbenchModule? {
        switch module {
        case .maps:
            .maps
        case .scripts:
            .scripts
        case .graphics:
            .graphics
        case .pokemon:
            .pokemon
        case .moves:
            .moves
        case .trainers:
            .trainers
        case .items:
            .items
        case .encounters:
            .encounters
        case .text:
            .text
        case .build, .patches, .playtest:
            .build
        case .diagnostics, .debugger:
            .issues
        case .rom, .unknown:
            .resources
        }
    }

    private static func diagnostic(from diagnostic: PokemonHackCore.Diagnostic) -> ValidationState {
        switch diagnostic.severity {
        case .info:
            .valid
        case .warning:
            .warning
        case .error:
            .error
        }
    }

    private static func validationStatus(for states: [ValidationState]) -> ValidationState {
        if states.contains(.error) {
            return .error
        }

        if states.contains(.warning) {
            return .warning
        }

        return .valid
    }

    static func validationState(for severity: DiagnosticSeverity) -> ValidationState {
        switch severity {
        case .info:
            .valid
        case .warning:
            .warning
        case .error:
            .error
        }
    }

    static func validationState(for status: ScriptReadinessCheckStatus) -> ValidationState {
        switch status {
        case .passed, .info:
            .valid
        case .needsReview:
            .warning
        case .blocked:
            .error
        }
    }

    static func validationState(for status: GenIIIAssetStatus) -> ValidationState {
        switch status {
        case .valid:
            .valid
        case .warning, .missing, .unsupported:
            .warning
        case .error:
            .error
        }
    }

    static func validationState(for availability: GenIIIAssetAvailability) -> ValidationState {
        switch availability {
        case .parserError, .unsupported:
            .error
        case .missingRequiredSource, .parserWarning:
            .warning
        case .availableSource, .availableGenerated, .availableLocalInput, .optionalGeneratedMissing, .generatedStale:
            .valid
        }
    }

    static func availabilitySummary(for availability: GenIIIAssetAvailability) -> String {
        switch availability {
        case .availableSource:
            "Source available"
        case .availableGenerated:
            "Generated output available"
        case .availableLocalInput:
            "Local input available"
        case .optionalGeneratedMissing:
            "Optional generated output missing"
        case .generatedStale:
            "Generated output stale"
        case .missingRequiredSource:
            "Required source missing"
        case .parserWarning:
            "Parser warning"
        case .parserError:
            "Parser error"
        case .unsupported:
            "Unsupported"
        }
    }

    private static func status(
        for diagnostics: [IndexedDiagnosticRow],
        missingSourceDocuments: Int
    ) -> ValidationState {
        if diagnostics.contains(where: { $0.severity == .error }) {
            return .error
        }

        if missingSourceDocuments > 0 || diagnostics.contains(where: { $0.severity == .warning }) {
            return .warning
        }

        return .valid
    }

    private static func mapCatalogViewState(
        from catalog: PokemonHackCore.ProjectMapCatalog,
        project: IndexedProjectSummary
    ) -> MapCatalogViewState {
        let layoutSlotsByIndex = Dictionary(uniqueKeysWithValues: catalog.layoutSlots.map { ($0.slotIndex, $0) })
        let maps = catalog.maps.map { map in
            mapSummary(from: map, layoutSlot: map.layoutSlotIndex.flatMap { layoutSlotsByIndex[$0] })
        }
        let mapsByID = Dictionary(uniqueKeysWithValues: maps.map { ($0.name, $0.id) })
        let groups = catalog.mapGroups.map { group in
            MapGroupViewState(
                id: group.id,
                name: group.id,
                mapCount: group.mapNames.count,
                mapIDs: group.mapNames.compactMap { mapsByID[$0] }
            )
        }

        return MapCatalogViewState(
            id: catalog.id,
            projectTitle: project.title,
            rootPath: catalog.rootPath,
            groupCount: catalog.mapGroups.count,
            mapCount: catalog.maps.count,
            layoutCount: catalog.layoutSlots.filter { !$0.isEmpty }.count,
            diagnostics: catalog.diagnostics.map { diagnostic(from: $0, rootPath: catalog.rootPath) },
            groups: groups,
            maps: maps
        )
    }

    private static func mapSummary(
        from map: PokemonHackCore.MapDescriptor,
        layoutSlot: PokemonHackCore.LayoutSlot?
    ) -> MapSummaryViewState {
        MapSummaryViewState(
            id: map.id,
            mapID: map.id,
            name: map.name,
            groupName: map.groupID ?? "Ungrouped",
            source: SourceLocation(path: map.sourcePath, symbol: map.id, line: 1),
            layout: layoutSlot.map(layout(from:)),
            music: map.music,
            mapType: map.mapType,
            weather: map.weather,
            regionMapSection: map.regionMapSection,
            eventCounts: MapEventCountViewState(
                objectEvents: map.eventCounts.objectEvents,
                warpEvents: map.eventCounts.warpEvents,
                coordEvents: map.eventCounts.coordEvents,
                bgEvents: map.eventCounts.bgEvents
            ),
            connections: map.connections.map { connection in
                MapConnectionViewState(
                    id: connection.id,
                    direction: connection.direction ?? "connection",
                    map: connection.map ?? "Unknown map",
                    offset: connection.offset ?? 0
                )
            },
            notes: mapNotes(from: map)
        )
    }

    private static func layout(from slot: PokemonHackCore.LayoutSlot) -> MapLayoutViewState {
        MapLayoutViewState(
            id: slot.layoutID ?? slot.id,
            name: slot.name ?? "Empty layout slot \(slot.slotIndex)",
            width: slot.width ?? 0,
            height: slot.height ?? 0,
            primaryTileset: slot.primaryTileset,
            secondaryTileset: slot.secondaryTileset,
            borderFilepath: slot.borderFilepath,
            blockdataFilepath: slot.blockdataFilepath,
            blockPreview: slot.blockdataPreview.map(blockPreview(from:))
        )
    }

    private static func blockPreview(
        from preview: PokemonHackCore.LayoutBlockdataPreview
    ) -> LayoutBlockPreviewViewState {
        let visibleWidth = min(preview.width, 24)
        let rowsAvailable = Int(ceil(Double(preview.metatileIDs.count) / Double(max(preview.width, 1))))
        let visibleHeight = min(preview.height, max(1, rowsAvailable), 18)

        return LayoutBlockPreviewViewState(
            width: preview.width,
            height: preview.height,
            visibleWidth: visibleWidth,
            visibleHeight: visibleHeight,
            metatileIDs: preview.metatileIDs.map(Int.init),
            isComplete: !preview.isCapped && preview.isByteCountValid,
            diagnostic: blockPreviewDiagnostic(preview)
        )
    }

    private static func blockPreviewDiagnostic(
        _ preview: PokemonHackCore.LayoutBlockdataPreview
    ) -> String? {
        if !preview.isByteCountValid {
            return "\(preview.actualByteCount) bytes, expected \(preview.expectedByteCount)"
        }
        if preview.isCapped {
            return "preview capped at \(preview.maxMetatileCount) metatiles"
        }
        return nil
    }

    private static func mapNotes(from map: PokemonHackCore.MapDescriptor) -> [String] {
        var notes: [String] = []
        if map.connectionsNoInclude {
            notes.append("Connections are declared without a generated include.")
        }
        if let sharedEventsMap = map.sharedEventsMap {
            notes.append("Shares events with \(sharedEventsMap).")
        }
        if let sharedScriptsMap = map.sharedScriptsMap {
            notes.append("Shares scripts with \(sharedScriptsMap).")
        }
        return notes
    }

    private static func buildWorkflowActions(
        canLaunchPlaytest: Bool,
        includePatchActions: Bool
    ) -> [BuildWorkflowActionViewState] {
        var actions = [
            BuildWorkflowActionViewState(
                id: "build-rom",
                title: "Build ROM",
                systemImage: "hammer",
                isEnabled: false,
                isPreviewLocked: true
            ),
            BuildWorkflowActionViewState(
                id: "open-playtest",
                title: "Open Playtest",
                systemImage: "play.fill",
                isEnabled: canLaunchPlaytest,
                isPreviewLocked: false
            ),
            BuildWorkflowActionViewState(
                id: "validate-sources",
                title: "Validate Sources",
                systemImage: "checkmark.seal",
                isEnabled: false,
                isPreviewLocked: true
            )
        ]

        if includePatchActions {
            actions.append(contentsOf: [
                BuildWorkflowActionViewState(
                    id: "apply-patch",
                    title: "Apply Patch",
                    systemImage: "wand.and.stars",
                    isEnabled: false,
                    isPreviewLocked: true
                ),
                BuildWorkflowActionViewState(
                    id: "export-rom",
                    title: "Export ROM",
                    systemImage: "square.and.arrow.down",
                    isEnabled: false,
                    isPreviewLocked: true
                )
            ])
        }

        return actions
    }
}

private enum FixtureData {
    static let targets = [
        BuildTarget(id: "emerald-dev", name: "Emerald Dev", romBase: "Pokemon Emerald"),
        BuildTarget(id: "firered-lab", name: "FireRed Lab", romBase: "Pokemon FireRed"),
        BuildTarget(id: "emerald-release", name: "Emerald Release", romBase: "Pokemon Emerald")
    ]

    static let records = [
        WorkbenchRecord(
            title: "Littleroot Town",
            subtitle: "Outdoor layout with 4 warps, 7 objects, 2 signposts",
            module: .maps,
            source: SourceLocation(path: "data/maps/LittlerootTown/map.json", symbol: "MAP_LITTLEROOT_TOWN", line: 1),
            validation: .warning,
            isDirty: true,
            tags: ["layout", "events", "warps"],
            facts: [
                Fact(label: "Layout", value: "LittlerootTown"),
                Fact(label: "Tileset", value: "General / Petalburg"),
                Fact(label: "Connections", value: "Route 101 north")
            ],
            notes: ["Object 5 has a pending script pointer review.", "Preview is fixture-only and does not write map JSON."]
        ),
        WorkbenchRecord(
            title: "Route 110 Rival",
            subtitle: "May/Brendan trainer battle variants",
            module: .trainers,
            source: SourceLocation(path: "src/data/trainers.h", symbol: "TRAINER_MAY_ROUTE110", line: 1847),
            validation: .valid,
            isDirty: false,
            tags: ["party", "ai", "battle"],
            facts: [
                Fact(label: "Class", value: "Pokemon Trainer"),
                Fact(label: "AI", value: "Check bad move / Try status"),
                Fact(label: "Party", value: "3 mons, starter branch")
            ],
            notes: ["Party preview groups source variants side by side."]
        ),
        WorkbenchRecord(
            title: "Mach Bike",
            subtitle: "Key item with overworld use callback",
            module: .items,
            source: SourceLocation(path: "src/data/items.h", symbol: "ITEM_MACH_BIKE", line: 732),
            validation: .warning,
            isDirty: true,
            tags: ["key item", "field use"],
            facts: [
                Fact(label: "Price", value: "0"),
                Fact(label: "Pocket", value: "Key Items"),
                Fact(label: "Use", value: "ItemUseOutOfBattle_MachBike")
            ],
            notes: ["Dirty badge represents staged mock edits only."]
        ),
        WorkbenchRecord(
            title: "Treecko",
            subtitle: "Species base stats and evolution table links",
            module: .pokemon,
            source: SourceLocation(path: "src/data/pokemon/species_info.h", symbol: "SPECIES_TREECKO", line: 2771),
            validation: .valid,
            isDirty: false,
            tags: ["base stats", "abilities", "evolution"],
            facts: [
                Fact(label: "BST", value: "310"),
                Fact(label: "Abilities", value: "Overgrow / Unburden"),
                Fact(label: "Growth", value: "Medium Slow")
            ],
            notes: ["Source links show the table row the editor would jump to."]
        ),
        WorkbenchRecord(
            title: "Route 102 Grass",
            subtitle: "Morning grass slots and level bands",
            module: .encounters,
            source: SourceLocation(path: "src/data/wild_encounters.json", symbol: "Route102_LandMons", line: 418),
            validation: .error,
            isDirty: true,
            tags: ["land", "levels", "rates"],
            facts: [
                Fact(label: "Encounter Rate", value: "20%"),
                Fact(label: "Slots", value: "12"),
                Fact(label: "Level Range", value: "3-5")
            ],
            notes: ["Slot 8 references a species not enabled for this target."]
        ),
        WorkbenchRecord(
            title: "Professor Birch Intro",
            subtitle: "Initial scene script and text branches",
            module: .scripts,
            source: SourceLocation(path: "data/scripts/new_game.inc", symbol: "NewGame_BirchSpeech", line: 42),
            validation: .warning,
            isDirty: false,
            tags: ["script", "movement", "text"],
            facts: [
                Fact(label: "Commands", value: "31"),
                Fact(label: "Text refs", value: "6"),
                Fact(label: "Labels", value: "4")
            ],
            notes: ["Command list is displayed as a read-only source outline."]
        ),
        WorkbenchRecord(
            title: "Birch Bag Prompt",
            subtitle: "Localized string for starter bag interaction",
            module: .text,
            source: SourceLocation(path: "data/text/birch.inc", symbol: "gText_BirchBagPrompt", line: 118),
            validation: .valid,
            isDirty: true,
            tags: ["string", "event text"],
            facts: [
                Fact(label: "Length", value: "82 chars"),
                Fact(label: "References", value: "2 scripts"),
                Fact(label: "Control Codes", value: "PLAYER, PAUSE")
            ],
            notes: ["Text editor shows control-code awareness without changing source files."]
        )
    ]

    static let issues = [
        WorkbenchIssue(
            title: "Encounter species gated from target",
            severity: .error,
            source: SourceLocation(path: "src/data/wild_encounters.json", symbol: "Route102_LandMons[8]", line: 447),
            message: "Selected species is not available in Emerald Dev target flags."
        ),
        WorkbenchIssue(
            title: "Object script pointer needs review",
            severity: .warning,
            source: SourceLocation(path: "data/maps/LittlerootTown/events.inc", symbol: "LittlerootTown_EventScript_Object5", line: 93),
            message: "Map event points to a script label outside the current source folder."
        ),
        WorkbenchIssue(
            title: "Item field use callback has no mock preview",
            severity: .warning,
            source: SourceLocation(path: "src/data/items.h", symbol: "ITEM_MACH_BIKE", line: 746),
            message: "Workbench can display the callback symbol but not its field behavior yet."
        )
    ]

    static let buildSteps = [
        BuildStep(
            name: "Scan source tree",
            status: .valid,
            detail: "pokeemerald headers, data tables, scripts, and map JSON discovered.",
            source: SourceLocation(path: "Makefile", symbol: "all", line: 1)
        ),
        BuildStep(
            name: "Validate fixtures",
            status: .warning,
            detail: "3 warnings and 1 error are shown in the Issues module.",
            source: SourceLocation(path: "tools/studio/mock_validation.json", symbol: "FixtureValidation", line: 1)
        ),
        BuildStep(
            name: "Build ROM",
            status: .valid,
            detail: "Mock target output: build/emerald-dev/pokeemerald.gba",
            source: SourceLocation(path: "Makefile", symbol: "pokeemerald.gba", line: 191)
        )
    ]
}
