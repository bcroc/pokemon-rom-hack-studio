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

private struct WorkbenchWorkflowContextState: Codable {
    let selection: String
    let selectedResourceAssetID: String?
    let selectedResourceLibraryEntryID: String
    let selectedResourceLibraryMode: String
    let selectedBuildWorkbenchTab: String
    let selectedBuildReportRowID: String
    let selectedDiagnosticBucket: String
    let selectedDiagnosticRowID: String
    let searchText: String
    let moduleSearchTextByModule: [String: String]
    let recentModules: [String]
    let recentTargets: [PersistedWorkbenchRecentTarget]
}

private struct PersistedWorkbenchRecentTarget: Codable {
    let kind: String
    let identifier: String
    let title: String
    let subtitle: String
    let systemImage: String
}

private struct SourceGraphLoadPayload: Codable {
    let index: PokemonHackCore.ProjectIndex
    let scriptOutline: PokemonHackCore.ProjectScriptOutline?
    let sourceIndex: PokemonHackCore.ProjectSourceIndex
}

private struct SpeciesCatalogLoadPayload: Codable {
    let index: PokemonHackCore.ProjectIndex
    let catalog: PokemonHackCore.ProjectSpeciesCatalog
}

private struct TrainerCatalogLoadPayload: Codable {
    let index: PokemonHackCore.ProjectIndex
    let catalog: PokemonHackCore.ProjectTrainerCatalog
}

private struct MoveCatalogLoadPayload: Codable {
    let index: PokemonHackCore.ProjectIndex
    let sourceIndex: PokemonHackCore.ProjectSourceIndex
    let speciesCatalog: PokemonHackCore.ProjectSpeciesCatalog?
    let catalog: PokemonHackCore.ProjectMoveCatalog
}

private struct ItemCatalogLoadPayload: Codable {
    let index: PokemonHackCore.ProjectIndex
    let sourceIndex: PokemonHackCore.ProjectSourceIndex?
    let catalog: PokemonHackCore.ProjectItemCatalog
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
    let actions: [BuildReportRowActionExportPayload]
}

private struct BuildReportRowActionExportPayload: Codable {
    let kind: String
    let title: String
    let detail: String
    let command: String?
    let payload: String?
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

enum WorkbenchToolbarMutationTarget: String, Equatable {
    case none
    case map
    case pokemon
    case pokemonBatch
    case trainer
    case move
    case item
    case graphics
    case ndsData

    var title: String {
        switch self {
        case .none: "No Editable Selection"
        case .map: "Map Changes"
        case .pokemon: "Pokemon Changes"
        case .pokemonBatch: "Pokemon Batch Changes"
        case .trainer: "Trainer Changes"
        case .move: "Move Changes"
        case .item: "Item Changes"
        case .graphics: "Graphics Changes"
        case .ndsData: "NDS Data Changes"
        }
    }

    var systemImage: String {
        switch self {
        case .none: "doc.text.magnifyingglass"
        case .map: "map"
        case .pokemon: "sparkles"
        case .pokemonBatch: "sparkles.rectangle.stack"
        case .trainer: "person.2"
        case .move: "bolt"
        case .item: "shippingbox"
        case .graphics: "photo.on.rectangle"
        case .ndsData: "doc.text"
        }
    }
}

struct WorkbenchToolbarMutationState: Equatable {
    let target: WorkbenchToolbarMutationTarget
    let canPreview: Bool
    let canApply: Bool
    let canDiscard: Bool
    let previewBlockedReason: String?
    let applyBlockedReason: String?

    var hasEditableTarget: Bool {
        target != .none
    }

    var title: String {
        target.title
    }

    var systemImage: String {
        target.systemImage
    }

    var previewHelp: String {
        previewBlockedReason ?? "Preview staged \(title.lowercased())"
    }

    var applyHelp: String {
        applyBlockedReason ?? "Apply previewed \(title.lowercased())"
    }

    var discardHelp: String {
        "Discard staged \(title.lowercased())"
    }

    static let unavailable = WorkbenchToolbarMutationState(
        target: .none,
        canPreview: false,
        canApply: false,
        canDiscard: false,
        previewBlockedReason: "Select an editable module before previewing mutations.",
        applyBlockedReason: "Preview a mutation plan before applying."
    )
}

@MainActor
final class WorkbenchStore: ObservableObject {
    @Published var selection: WorkbenchModule = .dashboard {
        didSet { persistWorkflowContext() }
    }
    @Published var selectedTargetID: BuildTarget.ID = "emerald-dev"
    @Published var selectedProjectID: IndexedProjectSummary.ID = ""
    @Published var selectedMapID: String = ""
    @Published var selectedSpeciesID: String = ""
    @Published var selectedTrainerID: String = ""
    @Published var selectedMoveID: String = ""
    @Published var selectedMoveWorkbenchFilter: MoveWorkbenchFilter = .all
    @Published var selectedItemID: String = ""
    @Published var selectedItemWorkbenchFilter: ItemWorkbenchFilter = .all
    @Published var selectedResourceAssetID: ResourceAssetRowViewState.ID? {
        didSet { persistWorkflowContext() }
    }
    @Published var selectedResourceLibraryEntryID: ResourceLibraryEntryViewState.ID = "" {
        didSet { persistWorkflowContext() }
    }
    @Published var selectedResourceLibraryMode: ResourceLibraryMode = .assets {
        didSet { persistWorkflowContext() }
    }
    @Published var selectedGameCubeResourcePath: String = ""
    @Published var selectedPatchPath: String = ""
    @Published var selectedBaseROMPath: String = ""
    @Published var selectedDecompBuildTargetID: String = ""
    @Published var scriptReadinessTargetMode: ScriptReadinessTargetMode = .map
    @Published var selectedScriptReadinessLabel: String = ""
    @Published var selectedScriptSourceID: String = ""
    @Published var selectedScriptLabelID: String = ""
    @Published var selectedScriptTextBlockID: String = ""
    @Published var selectedMapWorkbenchTab: MapWorkbenchTab = .overviewLayers
    @Published var selectedBuildWorkbenchTab: BuildWorkbenchTab = .build {
        didSet { persistWorkflowContext() }
    }
    @Published var selectedBuildReportRowID: String = "" {
        didSet { persistWorkflowContext() }
    }
    @Published var selectedGraphicsReportRowID: String = ""
    @Published var selectedGraphicsImportPackagePath: String = ""
    @Published var selectedDiagnosticBucket: DiagnosticSummaryBucket = .blockingErrors {
        didSet { persistWorkflowContext() }
    }
    @Published var selectedDiagnosticRowID: String = "" {
        didSet { persistWorkflowContext() }
    }
    @Published var selectedGuidedFlowID: String = ""
    @Published var selectedRecordIDsByModule: [WorkbenchModule: UUID] = [:]
    @Published var mapShowsPalette = true
    @Published var mapMetatileFilter = ""
    @Published var mapViewportRequest: MapCanvasViewportRequest?
    @Published var searchText = "" {
        didSet { persistWorkflowContext() }
    }
    @Published var resourceAssetCategory = WorkbenchStore.allResourceAssetCategories
    @Published var resourceAssetSortMode: ResourceAssetSortMode = .category
    @Published var pendingMapNavigation: PendingMapNavigation?
    @Published private(set) var recentModules: [WorkbenchModule] = [] {
        didSet { persistWorkflowContext() }
    }
    @Published private(set) var recentWorkbenchTargets: [WorkbenchRecentTarget] = [] {
        didSet { persistWorkflowContext() }
    }
    @Published private(set) var indexedProjects: [IndexedProjectSummary] = []
    @Published private(set) var projectIndexStatus: ProjectIndexLoadStatus = .idle
    @Published private(set) var selectedMapCatalog: MapCatalogViewState?
    @Published private(set) var mapCatalogStatus: MapCatalogLoadStatus = .idle
    @Published private(set) var mapEditorSession = MapEditorSession()
    @Published private(set) var mapVisualStatus: MapVisualLoadStatus = .idle
    @Published private(set) var latestSavedWorkspace: PokemonHackCore.SavedHackWorkspace?
    @Published private(set) var workspacePersistenceStatus = "Not saved"
    @Published private(set) var workspacePersistenceError: String?
    @Published private(set) var workspaceAutosavePending = false
    @Published private(set) var recentProjectRoots: [String]
    @Published private(set) var resourceLibrary: ResourceLibraryViewState?
    @Published private(set) var explicitGameCubeResourceEntry: ResourceLibraryEntryViewState?
    @Published private(set) var gameCubeResourceLoadStatus: GameCubeResourceLoadStatus = .idle
    @Published private(set) var selectedScriptReadinessReport: ScriptReadinessReportViewState?
    @Published private(set) var sourceGraphLoadStatus: SourceGraphLoadStatus = .idle
    @Published private(set) var assetCatalogLoadStatus: ResourceAssetCatalogLoadStatus = .idle
    @Published private(set) var speciesCatalogLoadStatus: SpeciesCatalogLoadStatus = .idle
    @Published private(set) var trainerCatalogLoadStatus: TrainerCatalogLoadStatus = .idle
    @Published private(set) var moveCatalogLoadStatus: MoveCatalogLoadStatus = .idle
    @Published private(set) var itemCatalogLoadStatus: ItemCatalogLoadStatus = .idle
    @Published private(set) var patchManifestLoadStatus: PatchManifestLoadStatus = .idle
    @Published private(set) var selectedPatchManifestReport: PatchManifestReportViewState?
    @Published private(set) var graphicsImportPackagePlanStatus: GraphicsImportPackagePlanLoadStatus = .idle
    @Published private(set) var selectedGraphicsImportPackagePlan: GraphicsImportPackagePlanViewState?
    @Published private(set) var latestSpeciesEditPlan: PokemonHackCore.SpeciesEditPlan?
    @Published private(set) var latestSpeciesApplyResult: PokemonHackCore.SpeciesApplyResult?
    @Published private(set) var latestSpeciesBatchEditPlans: [PokemonHackCore.SpeciesEditPlan] = []
    @Published private(set) var latestSpeciesBatchApplyResult: PokemonHackCore.SpeciesApplyResult?
    @Published private(set) var latestTrainerEditPlan: PokemonHackCore.TrainerEditPlan?
    @Published private(set) var latestTrainerApplyResult: PokemonHackCore.TrainerApplyResult?
    @Published private(set) var latestMoveEditPlan: PokemonHackCore.MoveEditPlan?
    @Published private(set) var latestMoveApplyResult: PokemonHackCore.MoveApplyResult?
    @Published private(set) var latestItemEditPlan: PokemonHackCore.ItemEditPlan?
    @Published private(set) var latestItemApplyResult: PokemonHackCore.ItemApplyResult?
    @Published private(set) var latestGraphicsEditPlan: PokemonHackCore.GraphicsEditPlan?
    @Published private(set) var latestGraphicsApplyResult: PokemonHackCore.GraphicsApplyResult?
    @Published private(set) var latestNDSDataEditPlan: PokemonHackCore.NDSDataEditPlan?
    @Published private(set) var latestNDSDataApplyResult: PokemonHackCore.NDSDataApplyResult?
    @Published private var speciesDraftsByKey: [String: PokemonHackCore.SpeciesEditDraft] = [:]
    @Published private var trainerDraftsByKey: [String: PokemonHackCore.TrainerEditDraft] = [:]
    @Published private var moveDraftsByKey: [String: PokemonHackCore.MoveEditDraft] = [:]
    @Published private var itemDraftsByKey: [String: PokemonHackCore.ItemEditDraft] = [:]
    @Published private var graphicsDraftsByKey: [String: PokemonHackCore.GraphicsEditDraft] = [:]
    @Published private var ndsDataDraftsByKey: [String: PokemonHackCore.NDSDataEditDraft] = [:]
    @Published private var playtestLaunchResultsByID: [String: PlaytestLaunchResultViewState] = [:]
    @Published private var playtestCaptureResultsByID: [String: PlaytestCaptureResultViewState] = [:]
    @Published private var buildRunResultsByID: [String: BuildRunResultViewState] = [:]
    @Published private var buildRunLogLinesByID: [String: [BuildRunLogLineViewState]] = [:]
    @Published private(set) var runningBuildTargetID: String?

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
    private var rawGraphicsImportPackagePlan: PokemonHackCore.GraphicsImportPackagePlan?
    private var graphicsReportsByID: [String: GraphicsDiagnosticsReportViewState] = [:]
    private var mapCatalogsByID: [String: PokemonHackCore.ProjectMapCatalog] = [:]
    private var romInspectorReportsByID: [String: PokemonHackCore.BinaryROMInspectorReport] = [:]
    private var scriptReadinessReportsByID: [String: ScriptReadinessReportViewState] = [:]
    private var speciesCatalogsByID: [String: PokemonHackCore.ProjectSpeciesCatalog] = [:]
    private var trainerCatalogsByID: [String: PokemonHackCore.ProjectTrainerCatalog] = [:]
    private var coreMoveCatalogsByID: [String: PokemonHackCore.ProjectMoveCatalog] = [:]
    private var moveCatalogsByID: [String: MoveCatalogViewState] = [:]
    private var itemCatalogsByID: [String: PokemonHackCore.ProjectItemCatalog] = [:]
    private var assetCatalogsByID: [String: ResourceAssetCatalogViewState] = [:]
    private var assetCatalogFingerprintsByID: [String: String] = [:]
    private var ndsDataCatalogsByID: [String: PokemonHackCore.ProjectNDSDataCatalog] = [:]
    private var ndsDataCatalogFingerprintsByID: [String: String] = [:]
    private var sourceGraphTask: Task<Void, Never>?
    private var speciesCatalogTask: Task<Void, Never>?
    private var trainerCatalogTask: Task<Void, Never>?
    private var moveCatalogTask: Task<Void, Never>?
    private var itemCatalogTask: Task<Void, Never>?
    private var assetCatalogTask: Task<Void, Never>?
    private var mapCatalogTask: Task<Void, Never>?
    private var mapVisualTask: Task<Void, Never>?
    private var decompBuildTask: Task<Void, Never>?
    private var mapVisualSharedCacheDataByID: [String: Data] = [:]
    private var resourceAssetRowsCache: ResourceAssetRowsCache?
    private var pendingRelatedMapTargetID: String?
    private var pendingResourceAssetFocus: String?
    private var pendingScriptAssetTargetID: String?
    private var moduleSearchTextByModule: [WorkbenchModule: String] = [:]
    private var pendingMapNavigationSearchBehavior: WorkbenchSearchBehavior?
    private var pendingMapNavigationSearchIdentifier: String?
    private var pendingMapNavigationSource: String?
    private var pendingMapNavigationShouldRefreshScriptReadiness = false
    private var settingsCancellable: AnyCancellable?
    private var mapEditorCancellable: AnyCancellable?
    private var autosaveTask: Task<Void, Never>?
    private var savedMapDraftsByProjectID: [String: [PokemonHackCore.SavedMapDraftSnapshot]] = [:]
    private var projectLoadGeneration = 0

    private static let recentRootsKey = "PokemonHackStudio.recentProjectRoots"
    private static let workflowContextKey = "PokemonHackStudio.workflowContext"
    private static let autosaveDelayNanoseconds: UInt64 = 600_000_000
    static let allResourceAssetCategories = "All"

    private static let workspaceSavedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    init(
        userDefaults: UserDefaults = .standard,
        userSettings: WorkbenchUserSettings? = nil,
        fileManager: FileManager = .default,
        toolResolver: @escaping ToolAvailabilityResolver = ToolAvailabilityResolverFactory.pathEnvironment(),
        workspaceRoot: URL? = nil,
        autoLoadProjects: Bool = true
    ) {
        self.userDefaults = userDefaults
        self.userSettings = userSettings ?? WorkbenchUserSettings(defaults: userDefaults)
        self.fileManager = fileManager
        self.toolResolver = toolResolver
        self.workspaceRoot = workspaceRoot ?? Self.inferredWorkspaceRoot()
        recentProjectRoots = userDefaults.stringArray(forKey: Self.recentRootsKey) ?? []

        targets = FixtureData.targets
        records = FixtureData.records
        issues = FixtureData.issues
        buildSteps = FixtureData.buildSteps
        restoreWorkflowContext()

        settingsCancellable = self.userSettings.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        mapEditorCancellable = mapEditorSession.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.scheduleDraftAutosaveIfNeeded()
            }
        }

        if autoLoadProjects && self.userSettings.autoLoadProjects {
            DispatchQueue.main.async { [weak self] in
                self?.refreshProjectIndexes()
            }
        }
    }

    private func restoreWorkflowContext() {
        guard
            let data = userDefaults.data(forKey: Self.workflowContextKey),
            let state = try? JSONDecoder().decode(WorkbenchWorkflowContextState.self, from: data)
        else { return }

        if let module = WorkbenchModule(rawValue: state.selection) {
            selection = module
        }
        selectedResourceAssetID = state.selectedResourceAssetID
        selectedResourceLibraryEntryID = state.selectedResourceLibraryEntryID
        selectedResourceLibraryMode = ResourceLibraryMode(rawValue: state.selectedResourceLibraryMode) ?? .assets
        selectedBuildWorkbenchTab = BuildWorkbenchTab(rawValue: state.selectedBuildWorkbenchTab) ?? .build
        selectedBuildReportRowID = state.selectedBuildReportRowID
        selectedDiagnosticBucket = DiagnosticSummaryBucket(rawValue: state.selectedDiagnosticBucket) ?? .blockingErrors
        selectedDiagnosticRowID = state.selectedDiagnosticRowID
        searchText = state.searchText
        moduleSearchTextByModule = Dictionary(
            uniqueKeysWithValues: state.moduleSearchTextByModule.compactMap { entry in
                guard let module = WorkbenchModule(rawValue: entry.key) else { return nil }
                return (module, entry.value)
            }
        )
        recentModules = state.recentModules.compactMap(WorkbenchModule.init(rawValue:))
        recentWorkbenchTargets = state.recentTargets.compactMap(Self.recentTarget(from:))
    }

    private func persistWorkflowContext() {
        let state = WorkbenchWorkflowContextState(
            selection: selection.rawValue,
            selectedResourceAssetID: selectedResourceAssetID,
            selectedResourceLibraryEntryID: selectedResourceLibraryEntryID,
            selectedResourceLibraryMode: selectedResourceLibraryMode.rawValue,
            selectedBuildWorkbenchTab: selectedBuildWorkbenchTab.rawValue,
            selectedBuildReportRowID: selectedBuildReportRowID,
            selectedDiagnosticBucket: selectedDiagnosticBucket.rawValue,
            selectedDiagnosticRowID: selectedDiagnosticRowID,
            searchText: searchText,
            moduleSearchTextByModule: Dictionary(
                uniqueKeysWithValues: moduleSearchTextByModule.map { ($0.key.rawValue, $0.value) }
            ),
            recentModules: recentModules.map(\.rawValue),
            recentTargets: recentWorkbenchTargets.map(Self.persistedTarget(from:))
        )
        guard let data = try? JSONEncoder().encode(state) else { return }
        userDefaults.set(data, forKey: Self.workflowContextKey)
    }

    private static func persistedTarget(from target: WorkbenchRecentTarget) -> PersistedWorkbenchRecentTarget {
        let kind: String
        let identifier: String
        switch target.target {
        case .map(let value):
            kind = "map"
            identifier = value
        case .species(let value):
            kind = "species"
            identifier = value
        case .trainer(let value):
            kind = "trainer"
            identifier = value
        case .move(let value):
            kind = "move"
            identifier = value
        case .item(let value):
            kind = "item"
            identifier = value
        case .resourceAsset(let value):
            kind = "resourceAsset"
            identifier = value
        case .resourceEntry(let value):
            kind = "resourceEntry"
            identifier = value
        case .scriptLabel(let value):
            kind = "scriptLabel"
            identifier = value
        case .buildRow(let value):
            kind = "buildRow"
            identifier = value
        case .diagnostic(let value):
            kind = "diagnostic"
            identifier = value
        }

        return PersistedWorkbenchRecentTarget(
            kind: kind,
            identifier: identifier,
            title: target.title,
            subtitle: target.subtitle,
            systemImage: target.systemImage
        )
    }

    private static func recentTarget(from persisted: PersistedWorkbenchRecentTarget) -> WorkbenchRecentTarget? {
        let focusTarget: WorkbenchFocusTarget
        switch persisted.kind {
        case "map":
            focusTarget = .map(persisted.identifier)
        case "species":
            focusTarget = .species(persisted.identifier)
        case "trainer":
            focusTarget = .trainer(persisted.identifier)
        case "move":
            focusTarget = .move(persisted.identifier)
        case "item":
            focusTarget = .item(persisted.identifier)
        case "resourceAsset":
            focusTarget = .resourceAsset(persisted.identifier)
        case "resourceEntry":
            focusTarget = .resourceEntry(persisted.identifier)
        case "scriptLabel":
            focusTarget = .scriptLabel(persisted.identifier)
        case "buildRow":
            focusTarget = .buildRow(persisted.identifier)
        case "diagnostic":
            focusTarget = .diagnostic(persisted.identifier)
        default:
            return nil
        }

        return WorkbenchRecentTarget(
            target: focusTarget,
            module: focusTarget.module,
            title: persisted.title,
            subtitle: persisted.subtitle,
            systemImage: persisted.systemImage
        )
    }

    var selectedTarget: BuildTarget {
        targets.first { $0.id == selectedTargetID } ?? targets[0]
    }

    var selectedIndexedProject: IndexedProjectSummary? {
        indexedProjects.first { $0.id == selectedProjectID } ?? defaultIndexedProject
    }

    private var defaultIndexedProject: IndexedProjectSummary? {
        indexedProjects.first(where: Self.isEditableIndexedProject) ?? indexedProjects.first
    }

    private static func isEditableIndexedProject(_ project: IndexedProjectSummary) -> Bool {
        project.originLabel == "Editable"
    }

    var recentMapTargets: [WorkbenchRecentTarget] {
        recentWorkbenchTargets.filter { $0.module == .maps }
    }

    var recentSpeciesTargets: [WorkbenchRecentTarget] {
        recentWorkbenchTargets.filter { $0.module == .pokemon }
    }

    var recentMoveTargets: [WorkbenchRecentTarget] {
        recentWorkbenchTargets.filter { $0.module == .moves }
    }

    var pendingMapNavigationTitle: String {
        guard let pendingMapNavigation else { return "Staged map edits" }
        switch pendingMapNavigation {
        case .project(let projectID):
            let title = indexedProjects.first { $0.id == projectID }?.title ?? "selected project"
            return "Switch to \(title)?"
        case .map(let mapID):
            let title = selectedMapCatalog?.maps.first { $0.id == mapID }?.name ?? mapID
            return "Switch to \(title)?"
        case .refreshMaps:
            return "Refresh maps?"
        }
    }

    var pendingMapNavigationMessage: String {
        guard let pendingMapNavigation else {
            return "This map has staged edits. Preview or discard them before changing selection."
        }
        switch pendingMapNavigation {
        case .project:
            return "This map has staged edits. Preview or discard them before switching projects."
        case .map(let mapID):
            let title = selectedMapCatalog?.maps.first { $0.id == mapID }?.name ?? mapID
            return "This map has staged edits. Preview or discard them before opening \(title)."
        case .refreshMaps:
            return "This map has staged edits. Preview or discard them before refreshing the map catalog."
        }
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

    var selectedCoreMoveCatalog: PokemonHackCore.ProjectMoveCatalog? {
        guard let selectedIndexedProject else { return nil }
        return coreMoveCatalogsByID[selectedIndexedProject.id]
    }

    var selectedItemCatalog: PokemonHackCore.ProjectItemCatalog? {
        guard let selectedIndexedProject else { return nil }
        return itemCatalogsByID[selectedIndexedProject.id]
    }

    var selectedItemCatalogView: ItemCatalogViewState? {
        guard let selectedIndexedProject, let catalog = selectedItemCatalog else { return nil }
        return Self.itemCatalog(from: catalog, project: selectedIndexedProject)
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
        if let selected = catalog.moves.first(where: { $0.moveID == selectedMoveID }) {
            return selected
        }
        return catalog.moves.first { $0.isEditable } ?? catalog.moves.first
    }

    var selectedCoreMoveDetail: PokemonHackCore.MoveDetail? {
        guard let catalog = selectedCoreMoveCatalog else { return nil }
        if let selected = catalog.moves.first(where: { $0.moveID == selectedMoveID }) {
            return selected
        }
        return catalog.moves.first { $0.isEditable } ?? catalog.moves.first
    }

    var selectedMoveIsHiddenByCurrentFilter: Bool {
        guard !selectedMoveID.isEmpty, selectedMoveCatalog != nil else { return false }
        return !filteredMoveDetails.contains { $0.moveID == selectedMoveID }
    }

    var selectedMoveDraft: PokemonHackCore.MoveEditDraft? {
        guard let detail = selectedCoreMoveDetail else { return nil }
        if let selectedIndexedProject {
            let key = moveDraftKey(projectID: selectedIndexedProject.id, moveID: detail.moveID)
            if let draft = moveDraftsByKey[key] {
                return draft
            }
        }
        return PokemonHackCore.MoveEditDraft(detail: detail)
    }

    var selectedMoveIsDirty: Bool {
        guard
            let selectedIndexedProject,
            let detail = selectedCoreMoveDetail,
            let baseDraft = PokemonHackCore.MoveEditDraft(detail: detail)
        else {
            return false
        }
        let key = moveDraftKey(projectID: selectedIndexedProject.id, moveID: detail.moveID)
        guard let draft = moveDraftsByKey[key] else { return false }
        return draft != baseDraft
    }

    var canPreviewSelectedMoveMutationPlan: Bool {
        selectedMoveIsDirty && selectedMoveDraft != nil
    }

    var canApplySelectedMoveMutationPlan: Bool {
        latestMoveEditPlan?.validateApplyability(fileManager: fileManager).isApplyable == true
    }

    var canDiscardMoveEdits: Bool {
        selectedMoveIsDirty || latestMoveEditPlan != nil || latestMoveApplyResult != nil
    }

    var movePreviewBlockedReason: String? {
        guard selectedCoreMoveCatalog != nil else { return "Load a move catalog before previewing edits." }
        guard selectedCoreMoveDetail != nil else { return "Select a move before previewing edits." }
        guard selectedMoveDraft != nil else { return "This move source shape is read-only." }
        guard selectedMoveIsDirty else { return "Change move battle data before previewing a mutation plan." }
        return nil
    }

    var moveApplyBlockedReason: String? {
        guard let plan = latestMoveEditPlan else { return "Preview move mutations before applying." }
        let applyability = plan.validateApplyability(fileManager: fileManager)
        if applyability.isApplyable {
            return nil
        }
        return applyability.diagnostics.first?.message ?? "Resolve move mutation diagnostics before applying."
    }

    var filteredItemDetails: [ItemDetailViewState] {
        guard let catalog = selectedItemCatalogView else { return [] }
        let filteredByMode: [ItemDetailViewState]
        switch selectedItemWorkbenchFilter {
        case .all:
            filteredByMode = catalog.items
        case .editable:
            filteredByMode = catalog.items.filter(\.isEditable)
        case .diagnostics:
            filteredByMode = catalog.items.filter { !$0.diagnostics.isEmpty }
        }
        guard !searchText.isEmpty else { return filteredByMode }
        let needle = searchText.lowercased()
        return filteredByMode.filter { $0.searchBlob.contains(needle) }
    }

    var selectedItemDetail: ItemDetailViewState? {
        guard let catalog = selectedItemCatalogView else { return nil }
        if let selected = filteredItemDetails.first(where: { $0.itemID == selectedItemID }) {
            return selected
        }
        return filteredItemDetails.first ?? catalog.items.first
    }

    var selectedCoreItemDetail: PokemonHackCore.ItemDetail? {
        guard let catalog = selectedItemCatalog else { return nil }
        if let selected = catalog.items.first(where: { $0.itemID == selectedItemID }) {
            return selected
        }
        return catalog.items.first { $0.isEditable } ?? catalog.items.first
    }

    var selectedItemDraft: PokemonHackCore.ItemEditDraft? {
        guard let detail = selectedCoreItemDetail else { return nil }
        if let selectedIndexedProject {
            let key = itemDraftKey(projectID: selectedIndexedProject.id, itemID: detail.itemID)
            if let draft = itemDraftsByKey[key] {
                return draft
            }
        }
        return PokemonHackCore.ItemEditDraft(detail: detail)
    }

    var selectedItemIsDirty: Bool {
        guard
            let selectedIndexedProject,
            let detail = selectedCoreItemDetail,
            let baseDraft = PokemonHackCore.ItemEditDraft(detail: detail)
        else {
            return false
        }
        let key = itemDraftKey(projectID: selectedIndexedProject.id, itemID: detail.itemID)
        guard let draft = itemDraftsByKey[key] else { return false }
        return draft != baseDraft
    }

    var canPreviewSelectedItemMutationPlan: Bool {
        selectedItemIsDirty && selectedItemDraft != nil
    }

    var canApplySelectedItemMutationPlan: Bool {
        latestItemEditPlan?.validateApplyability(fileManager: fileManager).isApplyable == true
    }

    var canDiscardItemEdits: Bool {
        selectedItemIsDirty || latestItemEditPlan != nil || latestItemApplyResult != nil
    }

    var itemPreviewBlockedReason: String? {
        guard selectedItemCatalog != nil else { return "Load an item catalog before previewing edits." }
        guard selectedCoreItemDetail != nil else { return "Select an item before previewing edits." }
        guard selectedItemDraft != nil else { return "This item source shape is read-only." }
        guard selectedItemIsDirty else { return "Change item data before previewing a mutation plan." }
        return nil
    }

    var itemApplyBlockedReason: String? {
        guard let plan = latestItemEditPlan else { return "Preview item mutations before applying." }
        let applyability = plan.validateApplyability(fileManager: fileManager)
        if applyability.isApplyable {
            return nil
        }
        return applyability.diagnostics.first?.message ?? "Resolve item mutation diagnostics before applying."
    }

    var filteredSpeciesDetails: [PokemonHackCore.SpeciesDetail] {
        guard let catalog = selectedSpeciesCatalog else { return [] }
        guard !searchText.isEmpty else { return catalog.species }
        let needle = searchText.lowercased()
        return catalog.species.filter { species in
            Self.speciesSearchBlob(species).contains(needle)
        }
    }

    var selectedSpeciesIsHiddenByCurrentSearch: Bool {
        guard !selectedSpeciesID.isEmpty, selectedSpeciesCatalog != nil, !searchText.isEmpty else { return false }
        return !filteredSpeciesDetails.contains { $0.speciesID == selectedSpeciesID }
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

    var dirtySpeciesDraftCount: Int {
        guard let selectedIndexedProject, let catalog = selectedSpeciesCatalog else { return 0 }
        return catalog.species.filter { isSpeciesDirty($0.speciesID, projectID: selectedIndexedProject.id) }.count
    }

    var dirtySpeciesBatchDrafts: [PokemonHackCore.SpeciesEditDraft] {
        guard let selectedIndexedProject, let catalog = selectedSpeciesCatalog else { return [] }
        return catalog.species.compactMap { detail in
            let key = speciesDraftKey(projectID: selectedIndexedProject.id, speciesID: detail.speciesID)
            guard
                let draft = speciesDraftsByKey[key],
                let baseDraft = PokemonHackCore.SpeciesEditDraft(detail: detail),
                draft != baseDraft
            else {
                return nil
            }
            return draft
        }
        .sorted { $0.speciesID < $1.speciesID }
    }

    var canPreviewSpeciesBatchMutationPlan: Bool {
        !dirtySpeciesBatchDrafts.isEmpty
    }

    var canApplySpeciesBatchMutationPlan: Bool {
        !latestSpeciesBatchEditPlans.isEmpty
            && latestSpeciesBatchEditPlans.allSatisfy { $0.validateApplyability(fileManager: fileManager).isApplyable }
    }

    var canDiscardSpeciesBatchEdits: Bool {
        !dirtySpeciesBatchDrafts.isEmpty || !latestSpeciesBatchEditPlans.isEmpty || latestSpeciesBatchApplyResult != nil
    }

    var speciesBatchPreviewBlockedReason: String? {
        guard selectedSpeciesCatalog != nil else { return "Load a Pokemon catalog before previewing compatibility changes." }
        guard !dirtySpeciesBatchDrafts.isEmpty else { return "Change Pokemon compatibility before previewing a batch mutation plan." }
        return nil
    }

    var speciesBatchApplyBlockedReason: String? {
        guard !latestSpeciesBatchEditPlans.isEmpty else { return "Preview Pokemon compatibility changes before applying." }
        let diagnostics = latestSpeciesBatchEditPlans.flatMap { $0.validateApplyability(fileManager: fileManager).diagnostics }
        if diagnostics.isEmpty {
            return nil
        }
        return diagnostics.first?.message ?? "Resolve Pokemon compatibility diagnostics before applying."
    }

    var dirtyMoveDraftCount: Int {
        guard let selectedIndexedProject, let catalog = selectedCoreMoveCatalog else { return 0 }
        return catalog.moves.filter { isMoveDirty($0.moveID, projectID: selectedIndexedProject.id) }.count
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

    var selectedTrainerAssetSources: [PokemonHackCore.TrainerAssetSource] {
        guard let catalog = selectedTrainerCatalog, let trainer = selectedTrainerDetail else { return [] }
        return PokemonHackCore.TrainerAssetResolver.sources(catalog: catalog, trainer: trainer, fileManager: fileManager)
    }

    func selectedTrainerAssetImportBlockedReason(kind: PokemonHackCore.TrainerAssetKind) -> String? {
        guard let selectedIndexedProject else {
            return "Open an editable source project before importing trainer assets."
        }
        guard !Self.pathIsBundledAssetRoot(selectedIndexedProject.rootPath) else {
            return "Bundled fallback projects are read-only; open the local source tree to import trainer assets."
        }
        guard let catalog = selectedTrainerCatalog, let trainer = selectedTrainerDetail else {
            return "Select a trainer before importing assets."
        }
        guard selectedTrainerDraft != nil else {
            return "\(trainer.trainerID) is read-only for this project profile."
        }
        guard let source = PokemonHackCore.TrainerAssetResolver.source(kind: kind, catalog: catalog, trainer: trainer, fileManager: fileManager) else {
            return "\(kind.title) has no indexed source row."
        }
        if let error = source.diagnostics.first(where: { $0.severity == .error }) {
            return error.message
        }
        guard let relativePath = source.relativePath, source.exists, source.isExplicitSource else {
            return "\(kind.title) replacement requires an existing source PNG or .pal file."
        }
        let lowercased = relativePath.lowercased()
        if relativePath.contains("..") || relativePath.hasPrefix("/") {
            return "\(kind.title) source path is unsafe."
        }
        if lowercased.contains(".4bpp") || lowercased.contains(".gbapal") || lowercased.contains("/build/") || lowercased.hasSuffix(".lz") {
            return "\(kind.title) imports must target source PNG or .pal files, not generated outputs."
        }
        switch kind {
        case .frontSprite where !lowercased.hasSuffix(".png"):
            return "\(kind.title) imports must target a PNG source path."
        case .palette where !lowercased.hasSuffix(".pal"):
            return "\(kind.title) imports must target a .pal source path."
        default:
            return nil
        }
    }

    @discardableResult
    func importSelectedTrainerAsset(
        kind: PokemonHackCore.TrainerAssetKind,
        from sourceURL: URL
    ) -> PokemonHackCore.SourceAssetImportProvenance? {
        guard
            selectedTrainerAssetImportBlockedReason(kind: kind) == nil,
            let catalog = selectedTrainerCatalog,
            let trainer = selectedTrainerDetail,
            let targetPath = PokemonHackCore.TrainerAssetResolver.source(kind: kind, catalog: catalog, trainer: trainer, fileManager: fileManager)?.relativePath,
            var draft = selectedTrainerDraft,
            let data = try? Data(contentsOf: sourceURL)
        else {
            return nil
        }

        let provenance = PokemonHackCore.SourceAssetImportValidator.provenance(
            sourcePath: sourceURL.path,
            expectedContent: kind.expectedContent,
            targetPath: targetPath,
            data: data
        )
        draft.assetData[kind] = data
        draft.assetImports[kind] = provenance
        updateSelectedTrainerDraft(draft)
        return provenance
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

    var selectedPlaytestCaptureResult: PlaytestCaptureResultViewState? {
        guard let selectedIndexedProject else { return nil }
        return playtestCaptureResultsByID[selectedIndexedProject.id]
    }

    var selectedBuildRunResult: BuildRunResultViewState? {
        guard let selectedIndexedProject else { return nil }
        return buildRunResultsByID[selectedIndexedProject.id]
    }

    var selectedBuildRunLogLines: [BuildRunLogLineViewState] {
        guard let selectedIndexedProject else { return [] }
        return buildRunLogLinesByID[selectedIndexedProject.id] ?? []
    }

    var selectedLatestPlaytestCaptureArtifact: PlaytestArtifactViewState? {
        selectedPlaytestCaptureResult?.primaryArtifact
    }

    var selectedNDSHealthActionRows: [BuildReportRow] {
        guard selectedBuildReport?.isNDS == true else { return [] }
        return selectedBuildReport?.healthMatrix.rows.filter { !$0.actions.isEmpty } ?? []
    }

    var canLaunchSelectedPlaytest: Bool {
        selectedBuildReport?.playtest.isRunnable == true
    }

    var selectedRunnableBuildTargets: [BuildTargetValidationViewState] {
        if let profile = selectedIndexedProject?.profile,
           Self.ndsBuildPreviewOnlyProfiles.contains(profile) {
            return []
        }
        guard selectedIndexedProject?.buildTargetCount ?? 0 > 0 else {
            return []
        }
        return selectedBuildReport?.buildTargets.filter { $0.command.split(separator: " ").first == "make" } ?? []
    }

    var selectedEffectiveDecompBuildTargetID: String {
        if selectedRunnableBuildTargets.contains(where: { $0.id == selectedDecompBuildTargetID }) {
            return selectedDecompBuildTargetID
        }
        return selectedRunnableBuildTargets.first?.id ?? ""
    }

    var canRunSelectedDecompBuild: Bool {
        guard runningBuildTargetID == nil else { return false }
        guard !selectedEffectiveDecompBuildTargetID.isEmpty else { return false }
        guard let selectedIndexedProject, projectIndexesByID[selectedIndexedProject.id] != nil else { return false }
        return true
    }

    func buildWorkflowActions(includePatchActions: Bool) -> [BuildWorkflowActionViewState] {
        Self.buildWorkflowActions(
            canRunBuild: canRunSelectedDecompBuild,
            isBuildRunning: runningBuildTargetID != nil,
            canLaunchPlaytest: canLaunchSelectedPlaytest,
            includePatchActions: includePatchActions
        )
    }

    var fixtureBuildWorkflowActions: [BuildWorkflowActionViewState] {
        Self.buildWorkflowActions(canRunBuild: false, isBuildRunning: false, canLaunchPlaytest: false, includePatchActions: false)
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

    var selectedROMInspectorReport: PokemonHackCore.BinaryROMInspectorReport? {
        guard let selectedIndexedProject else { return nil }
        return romInspectorReportsByID[selectedIndexedProject.id]
    }

    private var resourceLibraryEntriesForWorkbench: [ResourceLibraryEntryViewState] {
        var entries = resourceLibrary?.entries ?? []
        if let explicitGameCubeResourceEntry,
           !entries.contains(where: { $0.id == explicitGameCubeResourceEntry.id })
        {
            entries.insert(explicitGameCubeResourceEntry, at: 0)
        }
        return entries
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
        let itemDiagnostics = selectedItemCatalog?.diagnostics.map {
            Self.diagnostic(from: $0, rootPath: selectedIndexedProject.rootPath)
        } ?? []
        let resourceDiagnostics = (resourceLibrary?.allDiagnostics ?? [])
            + (explicitGameCubeResourceEntry.map { $0.diagnostics } ?? [])
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
            + itemDiagnostics
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

    var hasStagedEdits: Bool {
        hasStagedMapEdits
            || selectedSpeciesIsDirty
            || selectedTrainerIsDirty
            || selectedMoveIsDirty
            || selectedItemIsDirty
            || selectedGraphicsIsDirty
            || selectedNDSDataIsDirty
    }

    var currentDraftCounts: PokemonHackCore.SavedDraftCounts {
        currentDraftSnapshot().counts
    }

    var currentDraftCount: Int {
        currentDraftCounts.total
    }

    var savedDraftCount: Int {
        latestSavedWorkspace?.drafts.counts.total ?? 0
    }

    var workspaceLastSavedLabel: String {
        guard let savedAt = latestSavedWorkspace?.savedAt else {
            return workspacePersistenceStatus
        }
        return Self.workspaceSavedDateFormatter.string(from: savedAt)
    }

    var canSaveProjectWorkspace: Bool {
        selectedIndexedProject != nil
    }

    var toolbarMutationState: WorkbenchToolbarMutationState {
        switch selection {
        case .maps:
            return WorkbenchToolbarMutationState(
                target: .map,
                canPreview: mapEditorSession.canPreviewSelectedMapMutationPlan,
                canApply: mapEditorSession.canApplySelectedMapMutationPlan,
                canDiscard: mapEditorSession.canDiscardMapEdits,
                previewBlockedReason: mapEditorSession.previewBlockedReason,
                applyBlockedReason: mapEditorSession.applyBlockedReason
            )
        case .pokemon:
            return WorkbenchToolbarMutationState(
                target: .pokemon,
                canPreview: canPreviewSelectedSpeciesMutationPlan,
                canApply: canApplySelectedSpeciesMutationPlan,
                canDiscard: canDiscardSpeciesEdits,
                previewBlockedReason: speciesPreviewBlockedReason,
                applyBlockedReason: speciesApplyBlockedReason
            )
        case .trainers:
            return WorkbenchToolbarMutationState(
                target: .trainer,
                canPreview: canPreviewSelectedTrainerMutationPlan,
                canApply: canApplySelectedTrainerMutationPlan,
                canDiscard: canDiscardTrainerEdits,
                previewBlockedReason: trainerPreviewBlockedReason,
                applyBlockedReason: trainerApplyBlockedReason
            )
        case .moves:
            if canDiscardSpeciesBatchEdits {
                return WorkbenchToolbarMutationState(
                    target: .pokemonBatch,
                    canPreview: canPreviewSpeciesBatchMutationPlan,
                    canApply: canApplySpeciesBatchMutationPlan,
                    canDiscard: canDiscardSpeciesBatchEdits,
                    previewBlockedReason: speciesBatchPreviewBlockedReason,
                    applyBlockedReason: speciesBatchApplyBlockedReason
                )
            }
            return WorkbenchToolbarMutationState(
                target: .move,
                canPreview: canPreviewSelectedMoveMutationPlan,
                canApply: canApplySelectedMoveMutationPlan,
                canDiscard: canDiscardMoveEdits,
                previewBlockedReason: movePreviewBlockedReason,
                applyBlockedReason: moveApplyBlockedReason
            )
        case .items:
            return WorkbenchToolbarMutationState(
                target: .item,
                canPreview: canPreviewSelectedItemMutationPlan,
                canApply: canApplySelectedItemMutationPlan,
                canDiscard: canDiscardItemEdits,
                previewBlockedReason: itemPreviewBlockedReason,
                applyBlockedReason: itemApplyBlockedReason
            )
        case .graphics:
            return WorkbenchToolbarMutationState(
                target: .graphics,
                canPreview: canPreviewSelectedGraphicsMutationPlan,
                canApply: canApplySelectedGraphicsMutationPlan,
                canDiscard: canDiscardGraphicsEdits,
                previewBlockedReason: graphicsPreviewBlockedReason,
                applyBlockedReason: graphicsApplyBlockedReason
            )
        case .resources:
            guard selectedNDSDataRecordID != nil else {
                return .unavailable
            }
            return WorkbenchToolbarMutationState(
                target: .ndsData,
                canPreview: canPreviewSelectedNDSDataMutationPlan,
                canApply: canApplySelectedNDSDataMutationPlan,
                canDiscard: canDiscardNDSDataEdits,
                previewBlockedReason: ndsDataPreviewBlockedReason,
                applyBlockedReason: ndsDataApplyBlockedReason
            )
        case .dashboard, .encounters, .scripts, .text, .build, .issues:
            return .unavailable
        }
    }

    var selectedMapVisualDocument: PokemonHackCore.MapVisualDocument? {
        mapEditorSession.selectedMapVisualDocument
    }

    var selectedCoreMapCatalog: PokemonHackCore.ProjectMapCatalog? {
        guard let selectedIndexedProject else { return nil }
        return mapCatalogsByID[selectedIndexedProject.id]
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
        filter(resourceEntries: resourceLibraryEntriesForWorkbench)
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

        let rows = selectedAssetCatalog.index.filteredRows(
            category: resourceAssetCategory,
            allCategory: Self.allResourceAssetCategories,
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
           let selected = selectedAssetCatalog?.index.rowsByID[selectedResourceAssetID]
        {
            return selected
        }
        return filteredResourceAssetRows.first ?? selectedAssetCatalog?.rows.first
    }

    var selectedResourceLibraryEntry: ResourceLibraryEntryViewState? {
        if let selected = filteredResourceLibraryEntries.first(where: { $0.id == selectedResourceLibraryEntryID }) {
            return selected
        }
        return filteredResourceLibraryEntries.first ?? resourceLibraryEntriesForWorkbench.first
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

    var selectedGraphicsDraft: PokemonHackCore.GraphicsEditDraft? {
        guard let selectedIndexedProject, let row = selectedGraphicsReportRow else { return nil }
        let key = graphicsDraftKey(projectID: selectedIndexedProject.id, tilesetSymbol: row.source.symbol)
        return graphicsDraftsByKey[key] ?? PokemonHackCore.GraphicsEditDraft(tilesetSymbol: row.source.symbol)
    }

    var selectedGraphicsIsDirty: Bool {
        guard let selectedIndexedProject, let row = selectedGraphicsReportRow else { return false }
        let key = graphicsDraftKey(projectID: selectedIndexedProject.id, tilesetSymbol: row.source.symbol)
        return !(graphicsDraftsByKey[key]?.operations.isEmpty ?? true)
    }

    var canPreviewSelectedGraphicsMutationPlan: Bool {
        selectedGraphicsIsDirty && selectedGraphicsDraft != nil
    }

    var canApplySelectedGraphicsMutationPlan: Bool {
        latestGraphicsEditPlan?.validateApplyability(fileManager: fileManager).isApplyable == true
    }

    var canDiscardGraphicsEdits: Bool {
        selectedGraphicsIsDirty || latestGraphicsEditPlan != nil || latestGraphicsApplyResult != nil
    }

    var graphicsPreviewBlockedReason: String? {
        guard selectedGraphicsReport != nil else { return "Load graphics diagnostics before previewing edits." }
        guard selectedGraphicsReportRow != nil else { return "Select a tileset, metatile, or palette source row before previewing edits." }
        guard selectedGraphicsIsDirty else { return "Stage a supported graphics source edit before previewing a mutation plan." }
        return nil
    }

    var graphicsApplyBlockedReason: String? {
        guard let plan = latestGraphicsEditPlan else { return "Preview graphics mutations before applying." }
        let applyability = plan.validateApplyability(fileManager: fileManager)
        if applyability.isApplyable {
            return nil
        }
        return applyability.diagnostics.first?.message ?? "Resolve graphics mutation diagnostics before applying."
    }

    var selectedNDSDataEditor: NDSDataResourceEditorViewState? {
        guard let asset = selectedResourceAsset, let recordID = ndsDataRecordID(fromAssetID: asset.id) else {
            return nil
        }
        let canEdit = selectedNDSDataCanEditSourceText
        let draftText = selectedNDSDataDraft?.editedText ?? selectedNDSDataSourceText ?? ""
        return NDSDataResourceEditorViewState(
            recordID: recordID,
            text: draftText,
            semanticFields: selectedNDSDataSemanticFields(sourceText: draftText),
            canEdit: canEdit,
            isDirty: selectedNDSDataIsDirty,
            canPreview: canPreviewSelectedNDSDataMutationPlan,
            canApply: canApplySelectedNDSDataMutationPlan,
            canDiscard: canDiscardNDSDataEdits,
            blockedReason: ndsDataPreviewBlockedReason,
            applyBlockedReason: ndsDataApplyBlockedReason
        )
    }

    var selectedNDSDataDraft: PokemonHackCore.NDSDataEditDraft? {
        guard let selectedIndexedProject, let recordID = selectedNDSDataRecordID else { return nil }
        let key = ndsDataDraftKey(projectID: selectedIndexedProject.id, recordID: recordID)
        if let draft = ndsDataDraftsByKey[key] {
            return draft
        }
        return selectedNDSDataSourceText.map { PokemonHackCore.NDSDataEditDraft(recordID: recordID, editedText: $0) }
    }

    var selectedNDSDataSourceText: String? {
        guard let catalog = selectedNDSDataCatalog, let recordID = selectedNDSDataRecordID else { return nil }
        return PokemonHackCore.NDSDataMutationPlanner.sourceText(catalog: catalog, recordID: recordID, fileManager: fileManager)
    }

    var selectedNDSDataCanEditSourceText: Bool {
        guard let catalog = selectedNDSDataCatalog, let recordID = selectedNDSDataRecordID else { return false }
        let diagnostics = PokemonHackCore.NDSDataMutationPlanner.editabilityDiagnostics(catalog: catalog, recordID: recordID, fileManager: fileManager)
        return diagnostics.allSatisfy { $0.severity != .error }
    }

    var selectedNDSDataIsDirty: Bool {
        guard
            let selectedIndexedProject,
            let recordID = selectedNDSDataRecordID,
            let sourceText = selectedNDSDataSourceText
        else {
            return false
        }
        let key = ndsDataDraftKey(projectID: selectedIndexedProject.id, recordID: recordID)
        guard let draft = ndsDataDraftsByKey[key] else { return false }
        return draft.editedText != sourceText
    }

    var canPreviewSelectedNDSDataMutationPlan: Bool {
        selectedNDSDataIsDirty && selectedNDSDataDraft != nil
    }

    var canApplySelectedNDSDataMutationPlan: Bool {
        latestNDSDataEditPlan?.validateApplyability(fileManager: fileManager).isApplyable == true
    }

    var canDiscardNDSDataEdits: Bool {
        selectedNDSDataIsDirty || latestNDSDataEditPlan != nil || latestNDSDataApplyResult != nil
    }

    var ndsDataPreviewBlockedReason: String? {
        guard selectedNDSDataRecordID != nil else { return "Select an NDS data resource row before previewing edits." }
        guard let catalog = selectedNDSDataCatalog, let recordID = selectedNDSDataRecordID else { return "Load an NDS source project before previewing edits." }
        let diagnostics = PokemonHackCore.NDSDataMutationPlanner.editabilityDiagnostics(catalog: catalog, recordID: recordID, fileManager: fileManager)
        if let diagnostic = diagnostics.first(where: { $0.severity == .error }) {
            return diagnostic.message
        }
        guard selectedNDSDataDraft != nil else { return "This NDS data row is not editable as UTF-8 source text." }
        guard selectedNDSDataIsDirty else { return "Change NDS data text before previewing a mutation plan." }
        return nil
    }

    var ndsDataApplyBlockedReason: String? {
        guard let plan = latestNDSDataEditPlan else { return "Preview NDS data mutations before applying." }
        let applyability = plan.validateApplyability(fileManager: fileManager)
        if applyability.isApplyable {
            return nil
        }
        return applyability.diagnostics.first?.message ?? "Resolve NDS data mutation diagnostics before applying."
    }

    private var selectedNDSDataRecordID: String? {
        selectedResourceAsset.flatMap { ndsDataRecordID(fromAssetID: $0.id) }
    }

    private var selectedNDSDataCatalog: PokemonHackCore.ProjectNDSDataCatalog? {
        guard let selectedIndexedProject else { return nil }
        return ndsDataCatalog(for: selectedIndexedProject)
    }

    private func ndsDataCatalog(for project: IndexedProjectSummary) -> PokemonHackCore.ProjectNDSDataCatalog? {
        let fingerprint = Self.assetCatalogFingerprint(rootPath: project.rootPath, fileManager: fileManager)
        if ndsDataCatalogFingerprintsByID[project.id] == fingerprint,
           let cached = ndsDataCatalogsByID[project.id] {
            return cached
        }
        guard let catalog = try? PokemonHackCore.NDSDataCatalogBuilder.build(path: project.rootPath, fileManager: fileManager) else {
            ndsDataCatalogsByID.removeValue(forKey: project.id)
            ndsDataCatalogFingerprintsByID.removeValue(forKey: project.id)
            return nil
        }
        ndsDataCatalogsByID[project.id] = catalog
        ndsDataCatalogFingerprintsByID[project.id] = fingerprint
        return catalog
    }

    private func selectedNDSDataSemanticFields(sourceText: String) -> [NDSDataSemanticFieldViewState] {
        guard let catalog = selectedNDSDataCatalog, let recordID = selectedNDSDataRecordID else { return [] }
        let snapshot = PokemonHackCore.NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: recordID, fileManager: fileManager)
        guard snapshot.canEdit else { return [] }
        return PokemonHackCore.NDSDataSemanticEditor.fields(sourceText: sourceText, recordID: recordID).map {
            NDSDataSemanticFieldViewState(
                id: $0.id,
                key: $0.key,
                label: $0.label,
                value: $0.value,
                valueKind: $0.valueKind.rawValue
            )
        }
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
            + [report.toolchain.status, healthMatrix.status, report.playtest.status, report.playtestDebug.status]
            + report.diagnostics.map(\.severity)

        return BuildPatchPlaytestReportViewState(
            id: report.id,
            projectTitle: report.projectTitle,
            rootPath: report.rootPath,
            profile: report.profile,
            isNDS: report.isNDS,
            status: Self.validationStatus(for: states),
            buildTargets: report.buildTargets,
            generatedArtifacts: report.generatedArtifacts,
            toolchain: report.toolchain,
            healthMatrix: healthMatrix,
            playtest: report.playtest,
            playtestDebug: report.playtestDebug,
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
            isNDS: matrix.isNDS,
            status: status,
            detail: "Visible health matrix: \(ready) ready, \(warnings) warning, \(errors) error, \(notApplicable) not applicable.",
            readyCount: ready,
            warningCount: warnings,
            errorCount: errors,
            notApplicableCount: notApplicable,
            rows: rows,
            ndsGroups: matrix.isNDS ? ndsHealthGroups(from: rows) : []
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
                || ((userSettings.resourceSearchMatchesNestedItems || entry.platform == GenIIIResourcePlatform.gameCube.rawValue)
                    && entry.items.contains { item in
                        Self.resourceItemMatchesSearch(item, searchText: searchText)
                    })
        }
    }

    private static func resourceItemMatchesSearch(_ item: ResourceLibraryItemViewState, searchText: String) -> Bool {
        item.title.localizedCaseInsensitiveContains(searchText)
            || item.path.localizedCaseInsensitiveContains(searchText)
            || item.kind.localizedCaseInsensitiveContains(searchText)
            || item.category.localizedCaseInsensitiveContains(searchText)
            || item.locationSummary.localizedCaseInsensitiveContains(searchText)
            || item.sizeSummary.localizedCaseInsensitiveContains(searchText)
            || item.checksumSummary.localizedCaseInsensitiveContains(searchText)
            || item.source.path.localizedCaseInsensitiveContains(searchText)
            || item.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
    }

    static func filterAndSort(
        assetRows: [ResourceAssetRowViewState],
        category: String,
        searchText: String,
        sortMode: ResourceAssetSortMode
    ) -> [ResourceAssetRowViewState] {
        ResourceAssetCatalogIndex(rows: assetRows).filteredRows(
            category: category,
            allCategory: Self.allResourceAssetCategories,
            searchText: searchText,
            sortMode: sortMode
        )
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

    private func moveDraftKey(projectID: String, moveID: String) -> String {
        "\(projectID)::move::\(moveID)"
    }

    func isSpeciesDirty(_ speciesID: String) -> Bool {
        guard let selectedIndexedProject else { return false }
        return isSpeciesDirty(speciesID, projectID: selectedIndexedProject.id)
    }

    private func isSpeciesDirty(_ speciesID: String, projectID: String) -> Bool {
        guard
            let catalog = speciesCatalogsByID[projectID],
            let detail = catalog.species.first(where: { $0.speciesID == speciesID }),
            let baseDraft = PokemonHackCore.SpeciesEditDraft(detail: detail)
        else {
            return false
        }
        let key = speciesDraftKey(projectID: projectID, speciesID: speciesID)
        guard let draft = speciesDraftsByKey[key] else { return false }
        return draft != baseDraft
    }

    func isMoveDirty(_ moveID: String) -> Bool {
        guard let selectedIndexedProject else { return false }
        return isMoveDirty(moveID, projectID: selectedIndexedProject.id)
    }

    private func isMoveDirty(_ moveID: String, projectID: String) -> Bool {
        guard
            let catalog = coreMoveCatalogsByID[projectID],
            let detail = catalog.moves.first(where: { $0.moveID == moveID })
        else {
            return false
        }
        let baseDraft = PokemonHackCore.MoveEditDraft(detail: detail)
        let key = moveDraftKey(projectID: projectID, moveID: moveID)
        guard let draft = moveDraftsByKey[key] else { return false }
        return draft != baseDraft
    }

    private func itemDraftKey(projectID: String, itemID: String) -> String {
        "\(projectID)::item::\(itemID)"
    }

    private func graphicsDraftKey(projectID: String, tilesetSymbol: String) -> String {
        "\(projectID)::graphics::\(tilesetSymbol)"
    }

    private func ndsDataDraftKey(projectID: String, recordID: String) -> String {
        "\(projectID)::nds-data::\(recordID)"
    }

    private func ndsDataRecordID(fromAssetID assetID: String) -> String? {
        guard let range = assetID.range(of: ":nds-data:") else { return nil }
        return String(assetID[range.upperBound...])
    }

    private static let ndsBuildPreviewOnlyProfiles: Set<String> = [
        "ndsROM",
        "pokediamond",
        "pokeplatinum",
        "pokeheartgold",
        "pmdSky"
    ]

    private func draftKeyPrefix(projectID: String, kind: String) -> String {
        "\(projectID)::\(kind)::"
    }

    private func currentDraftSnapshot(projectID: String? = nil) -> PokemonHackCore.SavedDraftSnapshot {
        guard let projectID = projectID ?? selectedIndexedProject?.id else {
            return PokemonHackCore.SavedDraftSnapshot()
        }

        let speciesPrefix = draftKeyPrefix(projectID: projectID, kind: "species")
        let trainerPrefix = draftKeyPrefix(projectID: projectID, kind: "trainer")
        let movePrefix = draftKeyPrefix(projectID: projectID, kind: "move")
        let itemPrefix = draftKeyPrefix(projectID: projectID, kind: "item")
        let graphicsPrefix = draftKeyPrefix(projectID: projectID, kind: "graphics")
        let ndsDataPrefix = draftKeyPrefix(projectID: projectID, kind: "nds-data")

        var mapDrafts = savedMapDraftsByProjectID[projectID] ?? []
        if
            let document = mapEditorSession.selectedMapVisualDocument,
            mapEditorSession.isDirty,
            !mapEditorSession.mapEditOperations.isEmpty
        {
            mapDrafts.removeAll { $0.mapID == document.mapID }
            mapDrafts.append(
                PokemonHackCore.SavedMapDraftSnapshot(
                    mapID: document.mapID,
                    documentID: document.id,
                    operations: mapEditorSession.mapEditOperations
                )
            )
        }

        return PokemonHackCore.SavedDraftSnapshot(
            speciesDrafts: speciesDraftsByKey
                .filter { $0.key.hasPrefix(speciesPrefix) }
                .map(\.value)
                .sorted { $0.speciesID < $1.speciesID },
            trainerDrafts: trainerDraftsByKey
                .filter { $0.key.hasPrefix(trainerPrefix) }
                .map(\.value)
                .sorted { $0.trainerID < $1.trainerID },
            moveDrafts: moveDraftsByKey
                .filter { $0.key.hasPrefix(movePrefix) }
                .map(\.value)
                .sorted { $0.moveID < $1.moveID },
            itemDrafts: itemDraftsByKey
                .filter { $0.key.hasPrefix(itemPrefix) }
                .map(\.value)
                .sorted { $0.itemID < $1.itemID },
            mapDrafts: mapDrafts.sorted { $0.mapID < $1.mapID },
            graphicsDrafts: graphicsDraftsByKey
                .filter { $0.key.hasPrefix(graphicsPrefix) }
                .map(\.value)
                .filter { !$0.operations.isEmpty }
                .sorted { $0.tilesetSymbol < $1.tilesetSymbol },
            ndsDataDrafts: ndsDataDraftsByKey
                .filter { $0.key.hasPrefix(ndsDataPrefix) }
                .map(\.value)
                .sorted { $0.recordID < $1.recordID }
        )
    }

    private func workspaceSnapshot(savedAt: Date = Date()) -> PokemonHackCore.SavedHackWorkspace? {
        guard let project = selectedIndexedProject else { return nil }
        let index = projectIndexesByID[project.id]
        return PokemonHackCore.SavedHackWorkspace(
            savedAt: savedAt,
            projectRootPath: project.rootPath,
            projectTitle: project.title,
            profile: index?.profile ?? PokemonHackCore.GameProfile(rawValue: project.profile) ?? .unknown,
            adapterID: index?.adapterID ?? project.adapterName,
            selectedModule: selection.rawValue,
            selectedMapID: selectedMapID.isEmpty ? nil : selectedMapID,
            selectedSpeciesID: selectedSpeciesID.isEmpty ? nil : selectedSpeciesID,
            selectedTrainerID: selectedTrainerID.isEmpty ? nil : selectedTrainerID,
            selectedMoveID: selectedMoveID.isEmpty ? nil : selectedMoveID,
            selectedItemID: selectedItemID.isEmpty ? nil : selectedItemID,
            drafts: currentDraftSnapshot(projectID: project.id)
        )
    }

    private func clearDrafts(for projectID: String) {
        speciesDraftsByKey = speciesDraftsByKey.filter { !$0.key.hasPrefix(draftKeyPrefix(projectID: projectID, kind: "species")) }
        trainerDraftsByKey = trainerDraftsByKey.filter { !$0.key.hasPrefix(draftKeyPrefix(projectID: projectID, kind: "trainer")) }
        moveDraftsByKey = moveDraftsByKey.filter { !$0.key.hasPrefix(draftKeyPrefix(projectID: projectID, kind: "move")) }
        itemDraftsByKey = itemDraftsByKey.filter { !$0.key.hasPrefix(draftKeyPrefix(projectID: projectID, kind: "item")) }
        graphicsDraftsByKey = graphicsDraftsByKey.filter { !$0.key.hasPrefix(draftKeyPrefix(projectID: projectID, kind: "graphics")) }
        ndsDataDraftsByKey = ndsDataDraftsByKey.filter { !$0.key.hasPrefix(draftKeyPrefix(projectID: projectID, kind: "nds-data")) }
        savedMapDraftsByProjectID.removeValue(forKey: projectID)
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
        case .items:
            itemModuleStatus
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
        return Self.validationStatus(for: [outlineStatus, sourceGraphLoadStatus.validationState, selectedScriptReadinessReport?.status ?? .valid])
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

    private var itemModuleStatus: ValidationState {
        guard let catalog = selectedItemCatalogView else {
            return Self.validationStatus(for: records(for: .items).map(\.validation) + [itemCatalogLoadStatus.validationState])
        }
        return Self.validationStatus(
            for: [catalog.status, itemCatalogLoadStatus.validationState]
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

    private func prepareForSelectedProjectChange() {
        projectLoadGeneration += 1
        sourceGraphTask?.cancel()
        speciesCatalogTask?.cancel()
        trainerCatalogTask?.cancel()
        moveCatalogTask?.cancel()
        itemCatalogTask?.cancel()
        assetCatalogTask?.cancel()
        mapCatalogTask?.cancel()
        mapVisualTask?.cancel()
        pendingScriptAssetTargetID = nil
        clearSelectedMapVisualDocument()
        updateLazyLoadStatusesForSelection()
    }

    private func updateLazyLoadStatusesForSelection() {
        updateSourceGraphLoadStatusForSelection()
        updateAssetCatalogLoadStatusForSelection()
        refreshSelectedSpeciesSelection()
        refreshSelectedTrainerSelection()
        refreshSelectedMoveSelection()
        refreshSelectedItemSelection()
    }

    private func updateSourceGraphLoadStatusForSelection() {
        guard let selectedIndexedProject else {
            sourceGraphLoadStatus = .idle
            return
        }
        if let sourceIndex = sourceIndexesByID[selectedIndexedProject.id] {
            let labelCount = scriptOutlinesByID[selectedIndexedProject.id]?.labels.count ?? 0
            sourceGraphLoadStatus = .loaded(recordCount: sourceIndex.records.count, labelCount: labelCount)
        } else {
            sourceGraphLoadStatus = .idle
        }
    }

    func refreshProjectIndexes() {
        let previousProjectID = selectedProjectID
        projectIndexStatus = .loading

        let coreResourceLibrary = refreshResourceLibrary()

        let resourceRoots = coreResourceLibrary.entries
            .filter { entry in
                (entry.platform == .gbaSource || entry.platform == .gbaROM || entry.platform == .ndsSource || entry.platform == .ndsROM)
                    && !entry.path.isEmpty
                    && !Self.pathIsBundledAssetRoot(entry.path)
                    && (userSettings.includeReferenceRootsInResources || !Self.pathIsReferenceRoot(entry.path))
            }
            .map(\.path)
        let configuredRecentRoots = userSettings.includeRecentProjectsInRefresh ? recentProjectRoots : []
        let roots = Self.uniquePaths(resourceRoots + defaultProjectRoots() + configuredRecentRoots)
        var summaries: [IndexedProjectSummary] = []
        var indexes: [String: PokemonHackCore.ProjectIndex] = [:]
        var buildReports: [String: BuildPatchPlaytestReportViewState] = [:]
        var graphicsReports: [String: GraphicsDiagnosticsReportViewState] = [:]
        var retainedScriptReadinessReports: [String: ScriptReadinessReportViewState] = [:]
        var romInspectorReports: [String: PokemonHackCore.BinaryROMInspectorReport] = [:]
        var retainedAssetCatalogs: [String: ResourceAssetCatalogViewState] = [:]
        var retainedFingerprints: [String: String] = [:]

        for root in roots {
            guard fileManager.fileExists(atPath: root) else { continue }

            do {
                let index = try GameAdapterRegistry.index(path: root, fileManager: fileManager)
                let summary = Self.summary(from: index)
                summaries.append(summary)
                indexes[summary.id] = index
                if index.profile == .binaryROM,
                   let report = try? BinaryROMInspectorReportBuilder.build(path: root, fileManager: fileManager, toolResolver: toolResolver) {
                    romInspectorReports[summary.id] = report
                }
                if userSettings.autoRefreshHealthOnProjectRefresh || buildReportsByID[summary.id] == nil {
                    let coreBuildReport = BuildValidationReportBuilder.build(index: index, fileManager: fileManager, toolResolver: toolResolver)
                    buildReports[summary.id] = Self.buildReport(from: index, project: summary, fileManager: fileManager, toolResolver: toolResolver, buildReport: coreBuildReport)
                } else {
                    buildReports[summary.id] = buildReportsByID[summary.id]
                }
                graphicsReports[summary.id] = Self.graphicsReport(from: index, project: summary, fileManager: fileManager)
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
        sourceIndexesByID = sourceIndexesByID.filter { indexes.keys.contains($0.key) }
        scriptOutlinesByID = scriptOutlinesByID.filter { indexes.keys.contains($0.key) }
        buildReportsByID = buildReports
        graphicsReportsByID = graphicsReports
        scriptReadinessReportsByID = retainedScriptReadinessReports
        speciesCatalogsByID = speciesCatalogsByID.filter { indexes.keys.contains($0.key) }
        trainerCatalogsByID = trainerCatalogsByID.filter { indexes.keys.contains($0.key) }
        coreMoveCatalogsByID = coreMoveCatalogsByID.filter { indexes.keys.contains($0.key) }
        moveCatalogsByID = moveCatalogsByID.filter { indexes.keys.contains($0.key) }
        itemCatalogsByID = itemCatalogsByID.filter { indexes.keys.contains($0.key) }
        romInspectorReportsByID = romInspectorReports
        assetCatalogsByID = retainedAssetCatalogs
        assetCatalogFingerprintsByID = retainedFingerprints
        ndsDataCatalogsByID = ndsDataCatalogsByID.filter { indexes.keys.contains($0.key) }
        ndsDataCatalogFingerprintsByID = ndsDataCatalogFingerprintsByID.filter { indexes.keys.contains($0.key) }
        savedMapDraftsByProjectID = savedMapDraftsByProjectID.filter { indexes.keys.contains($0.key) }
        mapVisualSharedCacheDataByID = [:]
        resourceAssetRowsCache = nil
        if !summaries.contains(where: { $0.id == selectedProjectID }) {
            selectedProjectID = summaries.first(where: Self.isEditableIndexedProject)?.id ?? summaries.first?.id ?? ""
            resetPatchManifestReportForProjectChange()
            resetGraphicsImportPackagePlanForProjectChange()
        }
        if previousProjectID != selectedProjectID {
            prepareForSelectedProjectChange()
        } else {
            updateLazyLoadStatusesForSelection()
        }
        refreshSelectedMapCatalog()
        refreshSelectedScriptReadinessReportIfVisible()
        refreshSelectedSpeciesSelection()
        refreshSelectedTrainerSelection()
        refreshSelectedMoveSelection()
        refreshSelectedItemSelection()
        loadSavedWorkspaceForSelectedProject()
        updateAssetCatalogLoadStatusForSelection()
        if userSettings.autoLoadAssetCatalog {
            loadSelectedAssetCatalogIfNeeded()
        }
        projectIndexStatus = .loaded(summaries.count)
    }

    func openProject(at url: URL) {
        openProject(path: url.standardizedFileURL.path)
    }

    func selectWorkbenchModule(
        _ module: WorkbenchModule,
        focus: WorkbenchFocusTarget? = nil,
        search: WorkbenchSearchBehavior = .restoreModule
    ) {
        storeSearchTextForCurrentModule()
        selection = module
        applySearchBehavior(search, for: module, targetIdentifier: focus?.rawIdentifier)
        recordRecentModule(module)
        loadSelectedModuleDataIfNeeded()
        if let focus {
            focusWorkbenchTarget(focus, search: .preserve)
        }
    }

    func selectModule(_ module: WorkbenchModule, search: WorkbenchSearchBehavior = .restoreModule) {
        selectWorkbenchModule(module, search: search)
    }

    @discardableResult
    func focusMap(_ mapID: String, search: WorkbenchSearchBehavior = .replaceTargetIdentifier) -> Bool {
        let trimmed = mapID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let resolvedMapID: String
        if let catalog = selectedMapCatalog {
            guard let match = Self.mapID(forRelatedTarget: trimmed, in: catalog) else { return false }
            resolvedMapID = match
        } else {
            resolvedMapID = trimmed
            pendingRelatedMapTargetID = trimmed
        }
        focusWorkbenchTarget(.map(resolvedMapID), search: search)
        if selectedMapCatalog == nil {
            loadSelectedMapCatalogIfNeeded()
        }
        return true
    }

    @discardableResult
    func focusSpecies(_ speciesID: String, search: WorkbenchSearchBehavior = .replaceTargetIdentifier) -> Bool {
        let trimmed = speciesID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if let catalog = selectedSpeciesCatalog,
           !catalog.species.contains(where: { $0.speciesID == trimmed }) {
            return false
        }
        focusWorkbenchTarget(.species(trimmed), search: search)
        if selectedSpeciesCatalog == nil {
            loadSelectedSpeciesCatalogIfNeeded()
        }
        return true
    }

    @discardableResult
    func focusMove(_ moveID: String, search: WorkbenchSearchBehavior = .replaceTargetIdentifier) -> Bool {
        let trimmed = moveID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if let catalog = selectedMoveCatalog,
           !catalog.moves.contains(where: { $0.moveID == trimmed }) {
            return false
        }
        focusWorkbenchTarget(.move(trimmed), search: search)
        if selectedMoveCatalog == nil {
            loadSelectedMoveCatalogIfNeeded()
        }
        return true
    }

    @discardableResult
    func focusResourceAsset(_ identifier: String, search: WorkbenchSearchBehavior = .replaceTargetIdentifier) -> Bool {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if let catalog = selectedAssetCatalog {
            let needle = trimmed.lowercased()
            guard catalog.index.exactMatch(identifier: trimmed) != nil
                    || catalog.index.substringMatch(needle: needle) != nil
            else { return false }
        }
        selectWorkbenchModule(.resources, search: search == .replaceTargetIdentifier ? .replace(trimmed) : search)
        selectedResourceLibraryMode = .assets
        resourceAssetCategory = Self.allResourceAssetCategories
        if selectResourceAsset(matching: trimmed) {
            recordRecentTarget(recentResourceAssetTarget(for: selectedResourceAssetID ?? trimmed))
        } else {
            pendingResourceAssetFocus = trimmed
            loadSelectedAssetCatalogIfNeeded()
            recordRecentTarget(recentResourceAssetTarget(for: trimmed))
        }
        return true
    }

    @discardableResult
    func focusResourceEntry(_ entryID: String, search: WorkbenchSearchBehavior = .replaceTargetIdentifier) -> Bool {
        let trimmed = entryID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if let resourceLibrary,
           !resourceLibrary.entries.contains(where: { $0.id == trimmed }) {
            return false
        }
        selectWorkbenchModule(.resources, search: search == .replaceTargetIdentifier ? .replace(trimmed) : search)
        selectedResourceLibraryMode = .entries
        requestResourceLibraryEntrySelection(trimmed)
        recordRecentTarget(recentResourceEntryTarget(for: trimmed))
        return true
    }

    func focusWorkbenchTarget(
        _ target: WorkbenchFocusTarget,
        search: WorkbenchSearchBehavior = .replaceTargetIdentifier
    ) {
        if case .map(let id) = target {
            if selection != target.module {
                selectWorkbenchModule(target.module, search: .restoreModule)
            }
            if requestMapSelection(id, source: "Navigation", deferredSearch: search) {
                applySearchBehavior(search, for: target.module, targetIdentifier: id)
            }
            return
        }

        if selection != target.module {
            selectWorkbenchModule(target.module, focus: target, search: search)
            return
        } else {
            applySearchBehavior(search, for: target.module, targetIdentifier: target.rawIdentifier)
        }

        switch target {
        case .map:
            break
        case .species(let id):
            requestSpeciesSelection(id)
        case .trainer(let id):
            requestTrainerSelection(id)
        case .move(let id):
            requestMoveSelection(id)
        case .item(let id):
            requestItemSelection(id)
        case .resourceAsset(let id):
            requestResourceAssetSelection(id)
        case .resourceEntry(let id):
            requestResourceLibraryEntrySelection(id)
        case .scriptLabel(let id):
            requestScriptLabelSelection(id)
        case .buildRow(let id):
            requestBuildReportRowSelection(id)
        case .diagnostic(let id):
            requestDiagnosticRowSelection(id)
        }
    }

    func clearCurrentModuleSearch() {
        searchText = ""
        moduleSearchTextByModule[selection] = ""
    }

    func revealSelectedSpeciesInSidebar() {
        clearCurrentModuleSearch()
    }

    func revealSelectedMoveInSidebar() {
        selectedMoveWorkbenchFilter = .all
        clearCurrentModuleSearch()
    }

    private func storeSearchTextForCurrentModule() {
        moduleSearchTextByModule[selection] = searchText
    }

    private func applySearchBehavior(
        _ behavior: WorkbenchSearchBehavior,
        for module: WorkbenchModule,
        targetIdentifier: String? = nil
    ) {
        switch behavior {
        case .preserve:
            break
        case .restoreModule:
            searchText = moduleSearchTextByModule[module] ?? ""
        case .replace(let value):
            searchText = value
            moduleSearchTextByModule[module] = value
        case .replaceTargetIdentifier:
            let value = targetIdentifier ?? ""
            searchText = value
            moduleSearchTextByModule[module] = value
        case .clear:
            searchText = ""
            moduleSearchTextByModule[module] = ""
        }
    }

    private func recordRecentModule(_ module: WorkbenchModule) {
        recentModules.removeAll { $0 == module }
        recentModules.insert(module, at: 0)
        recentModules = Array(recentModules.prefix(6))
    }

    private func recordRecentTarget(_ target: WorkbenchRecentTarget?) {
        guard let target else { return }
        recentWorkbenchTargets.removeAll { $0.id == target.id }
        recentWorkbenchTargets.insert(target, at: 0)
        recentWorkbenchTargets = Array(recentWorkbenchTargets.prefix(18))
    }

    func requestProjectSelection(_ projectID: String) {
        guard projectID != selectedProjectID else { return }
        if hasStagedMapEdits {
            pendingMapNavigation = .project(projectID)
            clearPendingMapNavigationContext()
        } else {
            applyProjectSelection(projectID)
        }
    }

    private func applyProjectSelection(_ projectID: String) {
        selectedProjectID = projectID
        prepareForSelectedProjectChange()
        selectedScriptReadinessReport = scriptReadinessReportsByID[projectID]
        resetPatchManifestReportForProjectChange()
        resetGraphicsImportPackagePlanForProjectChange()
        resetSidebarSelectionsForProjectChange()
        resourceAssetCategory = Self.allResourceAssetCategories
        selectedResourceAssetID = nil
        pendingRelatedMapTargetID = nil
        pendingResourceAssetFocus = nil
        resourceAssetRowsCache = nil
        refreshSelectedSpeciesSelection()
        refreshSelectedTrainerSelection()
        refreshSelectedMoveSelection()
        refreshSelectedItemSelection()
        loadSavedWorkspaceForSelectedProject()
        latestSpeciesEditPlan = nil
        latestSpeciesApplyResult = nil
        latestTrainerEditPlan = nil
        latestTrainerApplyResult = nil
        latestMoveEditPlan = nil
        latestMoveApplyResult = nil
        latestItemEditPlan = nil
        latestItemApplyResult = nil
        updateAssetCatalogLoadStatusForSelection()
        loadSelectedModuleDataIfNeeded()
    }

    @discardableResult
    func requestMapSelection(
        _ mapID: String,
        source: String? = nil,
        deferredSearch: WorkbenchSearchBehavior? = nil
    ) -> Bool {
        guard mapID != selectedMapID else { return true }
        if hasStagedMapEdits {
            pendingMapNavigation = .map(mapID)
            pendingMapNavigationSource = source
            pendingMapNavigationSearchBehavior = deferredSearch
            pendingMapNavigationSearchIdentifier = mapID
            pendingMapNavigationShouldRefreshScriptReadiness = false
            return false
        } else {
            selectedMapID = mapID
            recordRecentTarget(recentMapTarget(for: mapID, source: source))
            return true
        }
    }

    func openNewMapPlanFromToolbar() {
        selectedMapWorkbenchTab = .workflow
    }

    func requestSpeciesSelection(_ speciesID: String) {
        guard speciesID != selectedSpeciesID else { return }
        selectedSpeciesID = speciesID
        recordRecentTarget(recentSpeciesTarget(for: speciesID))
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
        recordRecentTarget(recentMoveTarget(for: moveID))
        latestMoveEditPlan = nil
        latestMoveApplyResult = nil
    }

    func requestItemSelection(_ itemID: String) {
        guard itemID != selectedItemID else { return }
        selectedItemID = itemID
        latestItemEditPlan = nil
        latestItemApplyResult = nil
    }

    func requestResourceAssetSelection(_ assetID: ResourceAssetRowViewState.ID?) {
        selectedResourceAssetID = assetID
        latestNDSDataEditPlan = nil
        latestNDSDataApplyResult = nil
        if let assetID {
            recordRecentTarget(recentResourceAssetTarget(for: assetID))
        }
    }

    func requestResourceLibraryEntrySelection(_ entryID: ResourceLibraryEntryViewState.ID) {
        selectedResourceLibraryEntryID = entryID
        recordRecentTarget(recentResourceEntryTarget(for: entryID))
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

    func requestGraphicsImportPackagePath(_ path: String) {
        selectedGraphicsImportPackagePath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        rawGraphicsImportPackagePlan = nil
        selectedGraphicsImportPackagePlan = nil
        graphicsImportPackagePlanStatus = selectedGraphicsImportPackagePath.isEmpty ? .idle : .idle
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

    private func resetGraphicsImportPackagePlanForProjectChange() {
        rawGraphicsImportPackagePlan = nil
        selectedGraphicsImportPackagePlan = nil
        graphicsImportPackagePlanStatus = .idle
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
        selectedScriptReadinessLabel = ""
        selectedRecordIDsByModule = [:]
        latestMoveEditPlan = nil
        latestMoveApplyResult = nil
        latestItemEditPlan = nil
        latestItemApplyResult = nil
        latestGraphicsEditPlan = nil
        latestGraphicsApplyResult = nil
        latestNDSDataEditPlan = nil
        latestNDSDataApplyResult = nil
        rawGraphicsImportPackagePlan = nil
        selectedGraphicsImportPackagePlan = nil
        graphicsImportPackagePlanStatus = .idle
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

    func loadSelectedGraphicsImportPackagePlan() {
        guard !selectedGraphicsImportPackagePath.isEmpty else {
            rawGraphicsImportPackagePlan = nil
            selectedGraphicsImportPackagePlan = nil
            graphicsImportPackagePlanStatus = .idle
            return
        }

        guard let selectedIndexedProject else {
            rawGraphicsImportPackagePlan = nil
            selectedGraphicsImportPackagePlan = nil
            graphicsImportPackagePlanStatus = .failed("Open a supported project before loading a graphics package.")
            return
        }

        graphicsImportPackagePlanStatus = .loading

        do {
            let plan = try GraphicsImportPackagePlanBuilder.build(
                projectPath: selectedIndexedProject.rootPath,
                packagePath: selectedGraphicsImportPackagePath,
                fileManager: fileManager
            )
            rawGraphicsImportPackagePlan = plan
            selectedGraphicsImportPackagePlan = Self.graphicsImportPackagePlanViewState(
                from: plan,
                rootPath: selectedIndexedProject.rootPath
            )
            graphicsImportPackagePlanStatus = .loaded(selectedGraphicsImportPackagePlan?.readiness ?? plan.readiness.rawValue)
        } catch {
            rawGraphicsImportPackagePlan = nil
            selectedGraphicsImportPackagePlan = nil
            graphicsImportPackagePlanStatus = .failed(error.localizedDescription)
        }
    }

    func stageSelectedGraphicsOperation(_ operation: PokemonHackCore.GraphicsEditOperation) {
        guard let selectedIndexedProject, let row = selectedGraphicsReportRow else { return }
        let key = graphicsDraftKey(projectID: selectedIndexedProject.id, tilesetSymbol: row.source.symbol)
        var draft = graphicsDraftsByKey[key] ?? PokemonHackCore.GraphicsEditDraft(tilesetSymbol: row.source.symbol)
        draft.operations.append(operation)
        graphicsDraftsByKey[key] = draft
        latestGraphicsEditPlan = nil
        latestGraphicsApplyResult = nil
        scheduleDraftAutosave()
    }

    func removeSelectedGraphicsOperation(id: String) {
        guard let selectedIndexedProject, let row = selectedGraphicsReportRow else { return }
        let key = graphicsDraftKey(projectID: selectedIndexedProject.id, tilesetSymbol: row.source.symbol)
        guard var draft = graphicsDraftsByKey[key] else { return }
        draft.operations.removeAll { $0.id == id }
        if draft.operations.isEmpty {
            graphicsDraftsByKey.removeValue(forKey: key)
        } else {
            graphicsDraftsByKey[key] = draft
        }
        latestGraphicsEditPlan = nil
        latestGraphicsApplyResult = nil
        scheduleDraftAutosaveIfNeeded()
    }

    func discardGraphicsEdits() {
        guard let selectedIndexedProject, let row = selectedGraphicsReportRow else {
            latestGraphicsEditPlan = nil
            latestGraphicsApplyResult = nil
            return
        }
        graphicsDraftsByKey.removeValue(forKey: graphicsDraftKey(projectID: selectedIndexedProject.id, tilesetSymbol: row.source.symbol))
        latestGraphicsEditPlan = nil
        latestGraphicsApplyResult = nil
        scheduleDraftAutosaveIfNeeded()
    }

    func previewSelectedGraphicsMutationPlan() {
        guard let selectedIndexedProject, let draft = selectedGraphicsDraft else {
            latestGraphicsEditPlan = nil
            latestGraphicsApplyResult = nil
            return
        }
        latestGraphicsEditPlan = GraphicsMutationPlanner.plan(rootPath: selectedIndexedProject.rootPath, draft: draft, fileManager: fileManager)
        latestGraphicsApplyResult = nil
    }

    func applySelectedGraphicsMutationPlan() {
        if latestGraphicsEditPlan == nil {
            previewSelectedGraphicsMutationPlan()
        }

        guard let plan = latestGraphicsEditPlan else { return }
        let projectIDBeforeApply = selectedProjectID
        let tilesetSymbolBeforeApply = plan.draft.tilesetSymbol

        do {
            let result = try GraphicsMutationApplier.apply(plan: plan, fileManager: fileManager)
            latestGraphicsApplyResult = result
            guard !result.appliedChanges.isEmpty else { return }
            if !projectIDBeforeApply.isEmpty {
                graphicsDraftsByKey.removeValue(
                    forKey: graphicsDraftKey(projectID: projectIDBeforeApply, tilesetSymbol: tilesetSymbolBeforeApply)
                )
            }
            reloadSelectedProjectAfterGraphicsApply(projectID: projectIDBeforeApply)
            if indexedProjects.contains(where: { $0.id == projectIDBeforeApply }) {
                selectedProjectID = projectIDBeforeApply
            }
            latestGraphicsEditPlan = nil
            latestGraphicsApplyResult = result
            scheduleDraftAutosaveIfNeeded()
        } catch {
            latestGraphicsApplyResult = GraphicsApplyResult(
                backupRootPath: plan.backupRelativeRoot,
                appliedChanges: [],
                diagnostics: [
                    Diagnostic(
                        severity: .error,
                        code: "GRAPHICS_APPLY_FAILED",
                        message: error.localizedDescription
                    )
                ]
            )
        }
    }

    func updateSelectedNDSDataDraftText(_ text: String) {
        guard let selectedIndexedProject, let recordID = selectedNDSDataRecordID else { return }
        let key = ndsDataDraftKey(projectID: selectedIndexedProject.id, recordID: recordID)
        guard selectedNDSDataCanEditSourceText else {
            ndsDataDraftsByKey.removeValue(forKey: key)
            latestNDSDataEditPlan = nil
            latestNDSDataApplyResult = nil
            scheduleDraftAutosaveIfNeeded()
            return
        }
        if let sourceText = selectedNDSDataSourceText, text == sourceText {
            ndsDataDraftsByKey.removeValue(forKey: key)
        } else {
            ndsDataDraftsByKey[key] = PokemonHackCore.NDSDataEditDraft(recordID: recordID, editedText: text)
        }
        latestNDSDataEditPlan = nil
        latestNDSDataApplyResult = nil
        scheduleDraftAutosaveIfNeeded()
    }

    func updateSelectedNDSDataSemanticField(key fieldKey: String, value: String) {
        guard
            let catalog = selectedNDSDataCatalog,
            let sourceText = selectedNDSDataDraft?.editedText ?? selectedNDSDataSourceText,
            let recordID = selectedNDSDataRecordID
        else {
            return
        }
        let snapshot = PokemonHackCore.NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: recordID, fileManager: fileManager)
        guard snapshot.canEdit else { return }
        let result = PokemonHackCore.NDSDataSemanticEditor.updateSourceText(
            sourceText,
            fieldEdit: PokemonHackCore.NDSDataSemanticFieldEdit(key: fieldKey, value: value),
            recordID: recordID
        )
        guard result.diagnostics.allSatisfy({ $0.severity != .error }) else { return }
        updateSelectedNDSDataDraftText(result.text)
    }

    func discardNDSDataEdits() {
        guard let selectedIndexedProject, let recordID = selectedNDSDataRecordID else {
            latestNDSDataEditPlan = nil
            latestNDSDataApplyResult = nil
            return
        }
        ndsDataDraftsByKey.removeValue(forKey: ndsDataDraftKey(projectID: selectedIndexedProject.id, recordID: recordID))
        latestNDSDataEditPlan = nil
        latestNDSDataApplyResult = nil
        scheduleDraftAutosaveIfNeeded()
    }

    func previewSelectedNDSDataMutationPlan() {
        guard let catalog = selectedNDSDataCatalog, let draft = selectedNDSDataDraft else {
            latestNDSDataEditPlan = nil
            latestNDSDataApplyResult = nil
            return
        }
        latestNDSDataEditPlan = PokemonHackCore.NDSDataMutationPlanner.plan(catalog: catalog, draft: draft, fileManager: fileManager)
        latestNDSDataApplyResult = nil
    }

    func applySelectedNDSDataMutationPlan() {
        if latestNDSDataEditPlan == nil {
            previewSelectedNDSDataMutationPlan()
        }

        guard let plan = latestNDSDataEditPlan else { return }
        let projectIDBeforeApply = selectedProjectID
        let recordIDBeforeApply = plan.recordID

        do {
            let result = try PokemonHackCore.NDSDataMutationApplier.apply(plan: plan, fileManager: fileManager)
            latestNDSDataApplyResult = result
            guard !result.appliedChanges.isEmpty else { return }
            if !projectIDBeforeApply.isEmpty {
                ndsDataDraftsByKey.removeValue(
                    forKey: ndsDataDraftKey(projectID: projectIDBeforeApply, recordID: recordIDBeforeApply)
                )
            }
            ndsDataCatalogsByID.removeValue(forKey: projectIDBeforeApply)
            ndsDataCatalogFingerprintsByID.removeValue(forKey: projectIDBeforeApply)
            loadSelectedAssetCatalogIfNeeded(force: true)
            if indexedProjects.contains(where: { $0.id == projectIDBeforeApply }) {
                selectedProjectID = projectIDBeforeApply
            }
            latestNDSDataEditPlan = nil
            latestNDSDataApplyResult = result
            scheduleDraftAutosaveIfNeeded()
        } catch {
            latestNDSDataApplyResult = PokemonHackCore.NDSDataApplyResult(
                backupRootPath: plan.backupRelativeRoot,
                appliedChanges: [],
                diagnostics: [
                    Diagnostic(
                        severity: .error,
                        code: "NDS_DATA_APPLY_FAILED",
                        message: error.localizedDescription
                    )
                ]
            )
        }
    }

    func navigateToAsset(_ asset: ResourceAssetRowViewState) {
        guard let targetModule = asset.targetModule else { return }
        selectedResourceAssetID = asset.id
        selectWorkbenchModule(targetModule, search: .preserve)
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
            applySearchBehavior(.replace(asset.targetID ?? asset.path), for: targetModule)
        default:
            applySearchBehavior(.replace(asset.targetID ?? asset.path), for: targetModule)
            break
        }
    }

    func navigateToResourceAsset(path: String) {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        selectWorkbenchModule(.resources, search: .preserve)
        selectedResourceLibraryMode = .assets
        resourceAssetCategory = Self.allResourceAssetCategories
        applySearchBehavior(.replace(trimmed), for: .resources)
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
        if let catalog = selectedMapCatalog,
           let mapID = Self.mapID(forRelatedTarget: targetID, in: catalog)
        {
            pendingRelatedMapTargetID = nil
            if requestMapSelection(mapID, source: "Resources", deferredSearch: .replace(targetID)) {
                applySearchBehavior(.replace(targetID), for: .maps)
            }
        } else {
            applySearchBehavior(.replace(targetID), for: .maps)
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
        } else {
            pendingScriptAssetTargetID = targetID
            loadSelectedSourceGraphIfNeeded()
        }
    }

    private func navigateToPokemonAssetTarget(_ targetID: String?) {
        guard let targetID, !targetID.isEmpty else { return }
        applySearchBehavior(.replace(targetID), for: .pokemon)
        if let catalog = selectedSpeciesCatalog {
            guard catalog.species.contains(where: { $0.speciesID == targetID }) else { return }
            requestSpeciesSelection(targetID)
        } else {
            loadSelectedSpeciesCatalogIfNeeded()
            requestSpeciesSelection(targetID)
        }
    }

    private func navigateToTrainerAssetTarget(_ targetID: String?) {
        guard let targetID, !targetID.isEmpty else { return }
        applySearchBehavior(.replace(targetID), for: .trainers)
        if let catalog = selectedTrainerCatalog {
            guard catalog.trainers.contains(where: { $0.trainerID == targetID }) else { return }
            requestTrainerSelection(targetID)
        } else {
            loadSelectedTrainerCatalogIfNeeded()
            requestTrainerSelection(targetID)
        }
    }

    private func navigateToMoveAssetTarget(_ targetID: String?) {
        guard let targetID, !targetID.isEmpty else { return }
        applySearchBehavior(.replace(targetID), for: .moves)
        if let catalog = selectedMoveCatalog {
            guard catalog.moves.contains(where: { $0.moveID == targetID }) else { return }
            requestMoveSelection(targetID)
        } else {
            loadSelectedMoveCatalogIfNeeded()
            requestMoveSelection(targetID)
        }
    }

    @discardableResult
    private func selectResourceAsset(matching identifier: String) -> Bool {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let catalog = selectedAssetCatalog else { return false }
        let needle = trimmed.lowercased()
        let fallbackMatch = catalog.index.exactMatch(identifier: trimmed)
            ?? catalog.index.substringMatch(needle: needle)
        selectedResourceAssetID = fallbackMatch?.id
        return fallbackMatch != nil
    }

    private func resolvePendingResourceAssetFocusIfNeeded() {
        guard let pendingResourceAssetFocus else { return }
        _ = selectResourceAsset(matching: pendingResourceAssetFocus)
        self.pendingResourceAssetFocus = nil
    }

    private func recentMapTarget(for mapID: String, source: String? = nil) -> WorkbenchRecentTarget {
        let map = selectedMapCatalog?.maps.first { $0.id == mapID }
        let subtitleParts = [
            source,
            map?.groupName,
            map?.layout?.name
        ].compactMap { value in
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? nil : trimmed
        }
        return WorkbenchRecentTarget(
            target: .map(mapID),
            module: .maps,
            title: map?.name ?? mapID,
            subtitle: subtitleParts.joined(separator: " · "),
            systemImage: WorkbenchModule.maps.systemImage
        )
    }

    private func recentSpeciesTarget(for speciesID: String) -> WorkbenchRecentTarget {
        let species = selectedSpeciesCatalog?.species.first { $0.speciesID == speciesID }
        return WorkbenchRecentTarget(
            target: .species(speciesID),
            module: .pokemon,
            title: species?.displayName ?? speciesID,
            subtitle: speciesID,
            systemImage: species?.isEditable == true ? "pencil" : "lock"
        )
    }

    private func recentMoveTarget(for moveID: String) -> WorkbenchRecentTarget {
        let move = selectedMoveCatalog?.moves.first { $0.moveID == moveID }
        let learnerText = move.map { "\($0.learnerCount) learners" } ?? "Move"
        return WorkbenchRecentTarget(
            target: .move(moveID),
            module: .moves,
            title: move?.displayName ?? moveID,
            subtitle: "\(moveID) · \(learnerText)",
            systemImage: WorkbenchModule.moves.systemImage
        )
    }

    private func recentResourceAssetTarget(for identifier: String) -> WorkbenchRecentTarget {
        let asset = selectedAssetCatalog?.rows.first {
            $0.id == identifier || $0.path == identifier || $0.targetID == identifier || $0.title == identifier
        }
        return WorkbenchRecentTarget(
            target: .resourceAsset(asset?.id ?? identifier),
            module: .resources,
            title: asset?.title ?? identifier,
            subtitle: asset.map { "\($0.category) · \($0.availabilitySummary)" } ?? "Resource asset",
            systemImage: WorkbenchModule.resources.systemImage
        )
    }

    private func recentResourceEntryTarget(for entryID: String) -> WorkbenchRecentTarget {
        let entry = resourceLibrary?.entries.first { $0.id == entryID || $0.path == entryID }
        return WorkbenchRecentTarget(
            target: .resourceEntry(entry?.id ?? entryID),
            module: .resources,
            title: entry?.title ?? entryID,
            subtitle: entry.map { "\($0.family) · \($0.parseStatus)" } ?? "Resource entry",
            systemImage: WorkbenchModule.resources.systemImage
        )
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
        clearPendingMapNavigationContext()
    }

    func previewBeforePendingMapNavigation() {
        previewSelectedMapMutationPlan()
        pendingMapNavigation = nil
        clearPendingMapNavigationContext()
        selection = .maps
    }

    func discardMapEdits() {
        let projectID = selectedIndexedProject?.id
        let mapID = mapEditorSession.selectedMapVisualDocument?.mapID
        mapEditorSession.discardChanges()
        if let projectID, let mapID {
            savedMapDraftsByProjectID[projectID]?.removeAll { $0.mapID == mapID }
        }
        scheduleDraftAutosaveIfNeeded()
    }

    func discardMapEditsAndContinueNavigation() {
        guard let pendingMapNavigation else { return }
        let pendingSearchBehavior = pendingMapNavigationSearchBehavior
        let pendingSearchIdentifier = pendingMapNavigationSearchIdentifier
        let pendingSource = pendingMapNavigationSource
        let shouldRefreshScriptReadiness = pendingMapNavigationShouldRefreshScriptReadiness
        discardMapEdits()
        self.pendingMapNavigation = nil
        clearPendingMapNavigationContext()

        switch pendingMapNavigation {
        case .project(let projectID):
            applyProjectSelection(projectID)
        case .map(let mapID):
            selectedMapID = mapID
            recordRecentTarget(recentMapTarget(for: mapID, source: pendingSource ?? "Navigation"))
            if let pendingSearchBehavior {
                applySearchBehavior(
                    pendingSearchBehavior,
                    for: .maps,
                    targetIdentifier: pendingSearchIdentifier ?? mapID
                )
            }
            if shouldRefreshScriptReadiness, scriptReadinessTargetMode == .map {
                refreshSelectedScriptReadinessReport()
            }
        case .refreshMaps:
            if refreshSelectedMapCatalog(ignoringStagedEdits: true) {
                loadSelectedMapCatalogIfNeeded()
            }
        }
    }

    private func clearPendingMapNavigationContext() {
        pendingMapNavigationSearchBehavior = nil
        pendingMapNavigationSearchIdentifier = nil
        pendingMapNavigationSource = nil
        pendingMapNavigationShouldRefreshScriptReadiness = false
    }

    func openProject(path: String) {
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path

        do {
            let index = try GameAdapterRegistry.index(path: standardizedPath, fileManager: fileManager)
            let summary = Self.summary(from: index)
            projectIndexesByID[summary.id] = index
            if index.profile == .binaryROM {
                romInspectorReportsByID[summary.id] = try? BinaryROMInspectorReportBuilder.build(path: standardizedPath, fileManager: fileManager, toolResolver: toolResolver)
            } else {
                romInspectorReportsByID.removeValue(forKey: summary.id)
            }
            if Self.isGameCubeProfile(index.profile) {
                selectedGameCubeResourcePath = standardizedPath
                let entry = GenIIIResourceRegistry.resourceIndex(path: standardizedPath, role: .localInput, fileManager: fileManager)
                let viewState = Self.resourceEntryViewState(from: entry)
                explicitGameCubeResourceEntry = viewState
                selectedResourceLibraryEntryID = viewState.id
                selectedResourceLibraryMode = .entries
                gameCubeResourceLoadStatus = .loaded(itemCount: viewState.items.count)
            }
            let coreBuildReport = BuildValidationReportBuilder.build(index: index, fileManager: fileManager, toolResolver: toolResolver)
            buildReportsByID[summary.id] = Self.buildReport(from: index, project: summary, fileManager: fileManager, toolResolver: toolResolver, buildReport: coreBuildReport)
            graphicsReportsByID[summary.id] = Self.graphicsReport(from: index, project: summary, fileManager: fileManager)
            sourceIndexesByID.removeValue(forKey: summary.id)
            scriptOutlinesByID.removeValue(forKey: summary.id)
            speciesCatalogsByID.removeValue(forKey: summary.id)
            trainerCatalogsByID.removeValue(forKey: summary.id)
            coreMoveCatalogsByID.removeValue(forKey: summary.id)
            moveCatalogsByID.removeValue(forKey: summary.id)
            itemCatalogsByID.removeValue(forKey: summary.id)
            assetCatalogsByID.removeValue(forKey: summary.id)
            assetCatalogFingerprintsByID.removeValue(forKey: summary.id)
            ndsDataCatalogsByID.removeValue(forKey: summary.id)
            ndsDataCatalogFingerprintsByID.removeValue(forKey: summary.id)
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
            if hasStagedMapEdits {
                pendingMapNavigation = .project(summary.id)
                clearPendingMapNavigationContext()
                projectIndexStatus = .loaded(indexedProjects.count)
                return
            }
            applyProjectSelection(summary.id)
            projectIndexStatus = .loaded(indexedProjects.count)
        } catch {
            projectIndexStatus = .failed(error.localizedDescription)
        }
    }

    func loadSelectedModuleDataIfNeeded() {
        switch selection {
        case .resources:
            loadSelectedAssetCatalogIfNeeded()
        case .maps:
            loadSelectedMapCatalogIfNeeded()
            loadSelectedMapVisualDocumentIfNeeded()
        case .scripts:
            loadSelectedSourceGraphIfNeeded()
            refreshSelectedScriptReadinessReport()
        case .text:
            loadSelectedSourceGraphIfNeeded()
        case .pokemon:
            loadSelectedSpeciesCatalogIfNeeded()
        case .trainers:
            loadSelectedTrainerCatalogIfNeeded()
        case .moves:
            loadSelectedMoveCatalogIfNeeded()
        case .items:
            loadSelectedItemCatalogIfNeeded()
        case .dashboard, .build, .graphics, .issues, .encounters:
            break
        }
    }

    func refreshSelectedModuleContext() {
        switch selection {
        case .dashboard:
            refreshHealthChecks()
        case .resources:
            refreshResourceLibrary()
            loadSelectedAssetCatalogIfNeeded(force: true)
        case .maps:
            if refreshSelectedMapCatalog() {
                loadSelectedMapCatalogIfNeeded()
            }
        case .scripts:
            loadSelectedSourceGraphIfNeeded(force: true)
            refreshSelectedScriptReadinessReport()
        case .text, .encounters:
            loadSelectedSourceGraphIfNeeded(force: true)
        case .pokemon:
            loadSelectedSpeciesCatalogIfNeeded(force: true)
        case .trainers:
            loadSelectedTrainerCatalogIfNeeded(force: true)
        case .moves:
            loadSelectedMoveCatalogIfNeeded(force: true)
        case .items:
            loadSelectedItemCatalogIfNeeded(force: true)
        case .graphics, .build, .issues:
            refreshHealthChecks()
        }
    }

    func previewToolbarMutationTarget() {
        switch toolbarMutationState.target {
        case .map:
            previewSelectedMapMutationPlan()
        case .pokemon:
            previewSelectedSpeciesMutationPlan()
        case .pokemonBatch:
            previewSpeciesBatchMutationPlan()
        case .trainer:
            previewSelectedTrainerMutationPlan()
        case .move:
            previewSelectedMoveMutationPlan()
        case .item:
            previewSelectedItemMutationPlan()
        case .graphics:
            previewSelectedGraphicsMutationPlan()
        case .ndsData:
            previewSelectedNDSDataMutationPlan()
        case .none:
            break
        }
    }

    func applyToolbarMutationTarget() {
        switch toolbarMutationState.target {
        case .map:
            applySelectedMapMutationPlan()
        case .pokemon:
            applySelectedSpeciesMutationPlan()
        case .pokemonBatch:
            applySpeciesBatchMutationPlan()
        case .trainer:
            applySelectedTrainerMutationPlan()
        case .move:
            applySelectedMoveMutationPlan()
        case .item:
            applySelectedItemMutationPlan()
        case .graphics:
            applySelectedGraphicsMutationPlan()
        case .ndsData:
            applySelectedNDSDataMutationPlan()
        case .none:
            break
        }
    }

    func discardToolbarMutationTarget() {
        switch toolbarMutationState.target {
        case .map:
            discardMapEdits()
        case .pokemon:
            discardSpeciesEdits()
        case .pokemonBatch:
            discardSpeciesBatchEdits()
        case .trainer:
            discardTrainerEdits()
        case .move:
            discardMoveEdits()
        case .item:
            discardItemEdits()
        case .graphics:
            discardGraphicsEdits()
        case .ndsData:
            discardNDSDataEdits()
        case .none:
            break
        }
    }

    func requestScriptReadinessMode(_ mode: ScriptReadinessTargetMode) {
        scriptReadinessTargetMode = mode
        if mode == .script, selectedScriptReadinessLabel.isEmpty {
            selectedScriptReadinessLabel = selectedScriptOutline?.labels.first?.label ?? ""
        }
        refreshSelectedScriptReadinessReport()
    }

    func loadSelectedSourceGraphIfNeeded(force: Bool = false) {
        guard let selectedIndexedProject else {
            sourceGraphLoadStatus = .idle
            return
        }
        if !force,
           sourceIndexesByID[selectedIndexedProject.id] != nil,
           scriptOutlinesByID[selectedIndexedProject.id] != nil
        {
            updateSourceGraphLoadStatusForSelection()
            return
        }

        sourceGraphTask?.cancel()
        sourceGraphLoadStatus = .loading
        let projectID = selectedIndexedProject.id
        let rootPath = selectedIndexedProject.rootPath
        let generation = projectLoadGeneration

        sourceGraphTask = Task { @MainActor [weak self] in
            do {
                let payloadData = try await Task.detached(priority: .userInitiated) { () throws -> Data in
                    let index = try GameAdapterRegistry.index(path: rootPath, fileManager: .default)
                    let scriptOutline = try? ProjectScriptOutlineLoader.load(from: index, fileManager: .default)
                    let sourceIndex: ProjectSourceIndex
                    if let scriptOutline {
                        sourceIndex = try ProjectSourceIndexLoader.load(from: index, scriptOutline: scriptOutline, fileManager: .default)
                    } else {
                        sourceIndex = try ProjectSourceIndexLoader.load(from: index, fileManager: .default)
                    }
                    return try JSONEncoder().encode(
                        SourceGraphLoadPayload(
                            index: index,
                            scriptOutline: scriptOutline,
                            sourceIndex: sourceIndex
                        )
                    )
                }.value
                guard !Task.isCancelled else { return }
                let payload = try JSONDecoder().decode(SourceGraphLoadPayload.self, from: payloadData)
                guard let self,
                      self.projectLoadGeneration == generation,
                      self.selectedIndexedProject?.id == projectID
                else { return }

                projectIndexesByID[projectID] = payload.index
                sourceIndexesByID[projectID] = payload.sourceIndex
                if let scriptOutline = payload.scriptOutline {
                    scriptOutlinesByID[projectID] = scriptOutline
                    if let pendingScriptAssetTargetID,
                       let label = Self.scriptReadinessLabel(for: pendingScriptAssetTargetID, outline: scriptOutline) {
                        self.pendingScriptAssetTargetID = nil
                        selectedScriptReadinessLabel = label
                    } else if selectedScriptReadinessLabel.isEmpty {
                        selectedScriptReadinessLabel = scriptOutline.labels.first?.label ?? ""
                    }
                } else {
                    scriptOutlinesByID.removeValue(forKey: projectID)
                }
                sourceGraphLoadStatus = .loaded(
                    recordCount: payload.sourceIndex.records.count,
                    labelCount: payload.scriptOutline?.labels.count ?? 0
                )
                refreshSelectedScriptReadinessReportIfVisible()
            } catch {
                guard let self,
                      self.projectLoadGeneration == generation,
                      self.selectedIndexedProject?.id == projectID
                else { return }
                sourceGraphLoadStatus = .failed(error.localizedDescription)
            }
        }
    }

    func requestScriptReadinessMapSelection(_ mapID: String) {
        let didSelect = requestMapSelection(mapID, source: "Scripts")
        guard didSelect else {
            pendingMapNavigationShouldRefreshScriptReadiness = scriptReadinessTargetMode == .map
            return
        }
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

        speciesCatalogTask?.cancel()
        speciesCatalogLoadStatus = .loading
        let projectID = selectedIndexedProject.id
        let rootPath = selectedIndexedProject.rootPath
        let generation = projectLoadGeneration

        speciesCatalogTask = Task { @MainActor [weak self] in
            do {
                let payloadData = try await Task.detached(priority: .userInitiated) { () throws -> Data in
                    let index = try GameAdapterRegistry.index(path: rootPath, fileManager: .default)
                    let catalog = try ProjectSpeciesCatalogBuilder.build(index: index, fileManager: .default)
                    return try JSONEncoder().encode(SpeciesCatalogLoadPayload(index: index, catalog: catalog))
                }.value
                guard !Task.isCancelled else { return }
                let payload = try JSONDecoder().decode(SpeciesCatalogLoadPayload.self, from: payloadData)
                guard let self,
                      self.projectLoadGeneration == generation,
                      self.selectedIndexedProject?.id == projectID
                else { return }

                projectIndexesByID[projectID] = payload.index
                speciesCatalogsByID[projectID] = payload.catalog
                speciesCatalogLoadStatus = .loaded(payload.catalog.speciesCount)
                refreshSelectedSpeciesSelection()
            } catch {
                guard let self,
                      self.projectLoadGeneration == generation,
                      self.selectedIndexedProject?.id == projectID
                else { return }
                speciesCatalogLoadStatus = .failed(error.localizedDescription)
            }
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

        moveCatalogTask?.cancel()
        moveCatalogLoadStatus = .loading
        let projectID = selectedIndexedProject.id
        let rootPath = selectedIndexedProject.rootPath
        let projectSummary = selectedIndexedProject
        let retainedSourceIndexData = sourceIndexesByID[projectID].flatMap { try? JSONEncoder().encode($0) }
        let retainedSpeciesCatalogData = speciesCatalogsByID[projectID].flatMap { try? JSONEncoder().encode($0) }
        let generation = projectLoadGeneration

        moveCatalogTask = Task { @MainActor [weak self] in
            do {
                let payloadData = try await Task.detached(priority: .userInitiated) { () throws -> Data in
                    let index = try GameAdapterRegistry.index(path: rootPath, fileManager: .default)
                    let sourceIndex: ProjectSourceIndex
                    if let retainedSourceIndexData {
                        sourceIndex = try JSONDecoder().decode(ProjectSourceIndex.self, from: retainedSourceIndexData)
                    } else {
                        sourceIndex = try ProjectSourceIndexLoader.load(from: index, fileManager: .default)
                    }
                    let speciesCatalog: ProjectSpeciesCatalog
                    if let retainedSpeciesCatalogData {
                        speciesCatalog = try JSONDecoder().decode(ProjectSpeciesCatalog.self, from: retainedSpeciesCatalogData)
                    } else {
                        speciesCatalog = try ProjectSpeciesCatalogBuilder.build(index: index, fileManager: .default)
                    }
                    let catalog = try ProjectMoveCatalogBuilder.build(
                        index: index,
                        sourceIndex: sourceIndex,
                        speciesCatalog: speciesCatalog,
                        fileManager: .default
                    )
                    return try JSONEncoder().encode(
                        MoveCatalogLoadPayload(
                            index: index,
                            sourceIndex: sourceIndex,
                            speciesCatalog: speciesCatalog,
                            catalog: catalog
                        )
                    )
                }.value
                guard !Task.isCancelled else { return }
                let payload = try JSONDecoder().decode(MoveCatalogLoadPayload.self, from: payloadData)
                guard let self,
                      self.projectLoadGeneration == generation,
                      self.selectedIndexedProject?.id == projectID
                else { return }

                let catalog = Self.moveCatalog(from: payload.catalog, project: projectSummary)
                projectIndexesByID[projectID] = payload.index
                sourceIndexesByID[projectID] = payload.sourceIndex
                if let speciesCatalog = payload.speciesCatalog {
                    speciesCatalogsByID[projectID] = speciesCatalog
                    speciesCatalogLoadStatus = .loaded(speciesCatalog.speciesCount)
                }
                coreMoveCatalogsByID[projectID] = payload.catalog
                moveCatalogsByID[projectID] = catalog
                updateSourceGraphLoadStatusForSelection()
                moveCatalogLoadStatus = .loaded(catalog.moveCount)
                refreshSelectedMoveSelection()
            } catch {
                guard let self,
                      self.projectLoadGeneration == generation,
                      self.selectedIndexedProject?.id == projectID
                else { return }
                moveCatalogLoadStatus = .failed(error.localizedDescription)
            }
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
            selectedMoveID = catalog.moves.first { $0.isEditable }?.moveID
                ?? catalog.moves.first?.moveID
                ?? ""
        }
        moveCatalogLoadStatus = .loaded(catalog.moveCount)
    }

    func loadSelectedItemCatalogIfNeeded(force: Bool = false) {
        guard let selectedIndexedProject else {
            itemCatalogLoadStatus = .idle
            selectedItemID = ""
            return
        }
        if !force, let catalog = itemCatalogsByID[selectedIndexedProject.id] {
            itemCatalogLoadStatus = .loaded(catalog.itemCount)
            refreshSelectedItemSelection()
            return
        }

        itemCatalogTask?.cancel()
        itemCatalogLoadStatus = .loading
        let projectID = selectedIndexedProject.id
        let rootPath = selectedIndexedProject.rootPath
        let retainedSourceIndexData = sourceIndexesByID[projectID].flatMap { try? JSONEncoder().encode($0) }
        let generation = projectLoadGeneration

        itemCatalogTask = Task { @MainActor [weak self] in
            do {
                let payloadData = try await Task.detached(priority: .userInitiated) { () throws -> Data in
                    let index = try GameAdapterRegistry.index(path: rootPath, fileManager: .default)
                    let sourceIndex: ProjectSourceIndex?
                    if let retainedSourceIndexData {
                        sourceIndex = try JSONDecoder().decode(ProjectSourceIndex.self, from: retainedSourceIndexData)
                    } else {
                        sourceIndex = try? ProjectSourceIndexLoader.load(from: index, fileManager: .default)
                    }
                    let catalog = try ProjectItemCatalogBuilder.build(index: index, sourceIndex: sourceIndex, fileManager: .default)
                    return try JSONEncoder().encode(ItemCatalogLoadPayload(index: index, sourceIndex: sourceIndex, catalog: catalog))
                }.value
                guard !Task.isCancelled else { return }
                let payload = try JSONDecoder().decode(ItemCatalogLoadPayload.self, from: payloadData)
                guard let self,
                      self.projectLoadGeneration == generation,
                      self.selectedIndexedProject?.id == projectID
                else { return }

                projectIndexesByID[projectID] = payload.index
                if let sourceIndex = payload.sourceIndex {
                    sourceIndexesByID[projectID] = sourceIndex
                    updateSourceGraphLoadStatusForSelection()
                }
                itemCatalogsByID[projectID] = payload.catalog
                itemCatalogLoadStatus = .loaded(payload.catalog.itemCount)
                refreshSelectedItemSelection()
            } catch {
                guard let self,
                      self.projectLoadGeneration == generation,
                      self.selectedIndexedProject?.id == projectID
                else { return }
                itemCatalogLoadStatus = .failed(error.localizedDescription)
            }
        }
    }

    private func refreshSelectedItemSelection() {
        guard let selectedIndexedProject else {
            itemCatalogLoadStatus = .idle
            selectedItemID = ""
            return
        }

        guard let catalog = itemCatalogsByID[selectedIndexedProject.id] else {
            itemCatalogLoadStatus = .idle
            selectedItemID = ""
            return
        }

        if !catalog.items.contains(where: { $0.itemID == selectedItemID }) {
            selectedItemID = catalog.items.first { $0.isEditable }?.itemID
                ?? catalog.items.first?.itemID
                ?? ""
        }
        itemCatalogLoadStatus = .loaded(catalog.itemCount)
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
        latestSpeciesBatchEditPlans = []
        latestSpeciesBatchApplyResult = nil
        scheduleDraftAutosave()
    }

    func selectedSpeciesAssetImportBlockedReason(kind: PokemonHackCore.SpeciesAssetKind) -> String? {
        guard let selectedIndexedProject else {
            return "Open an editable source project before importing assets."
        }
        guard !Self.pathIsBundledAssetRoot(selectedIndexedProject.rootPath) else {
            return "Bundled fallback projects are read-only; open the local source tree to import assets."
        }
        guard let detail = selectedSpeciesDetail else {
            return "Select a Pokemon before importing assets."
        }
        guard let asset = detail.assets.first(where: { $0.kind == kind }) else {
            return "\(kind.title) has no indexed source asset row."
        }
        guard asset.exists else {
            return "\(kind.title) source asset is missing; create the source path before importing a replacement."
        }
        guard selectedSpeciesDraft != nil else {
            return "\(detail.speciesID) is read-only for this project profile."
        }
        let lowercased = asset.relativePath.lowercased()
        if asset.relativePath.contains("..") || asset.relativePath.hasPrefix("/") {
            return "\(kind.title) source path is unsafe."
        }
        if lowercased.contains(".4bpp") || lowercased.hasSuffix(".gbapal") || lowercased.contains("/build/") {
            return "\(kind.title) imports must target source PNG or .pal files, not generated outputs."
        }
        if kind.isSpriteAsset && !lowercased.hasSuffix(".png") {
            return "\(kind.title) imports must target a PNG source path."
        }
        if kind.isPaletteAsset && !lowercased.hasSuffix(".pal") {
            return "\(kind.title) imports must target a .pal source path."
        }
        return nil
    }

    @discardableResult
    func importSelectedSpeciesAsset(
        kind: PokemonHackCore.SpeciesAssetKind,
        from sourceURL: URL
    ) -> PokemonHackCore.SpeciesAssetImportProvenance? {
        guard selectedSpeciesAssetImportBlockedReason(kind: kind) == nil,
              var draft = selectedSpeciesDraft,
              let data = try? Data(contentsOf: sourceURL)
        else {
            return nil
        }

        let provenance = PokemonHackCore.SpeciesAssetImportValidator.provenance(
            sourcePath: sourceURL.path,
            expectedKind: kind,
            data: data
        )
        draft.assetData[kind] = data
        draft.assetImports[kind] = provenance
        updateSelectedSpeciesDraft(draft)
        return provenance
    }

    func speciesCompatibilityValue(
        speciesID: String,
        moveID: String,
        bucket: PokemonHackCore.LearnsetBucket
    ) -> Bool {
        guard let selectedIndexedProject, let catalog = selectedSpeciesCatalog else { return false }
        let key = speciesDraftKey(projectID: selectedIndexedProject.id, speciesID: speciesID)
        if let draft = speciesDraftsByKey[key] {
            switch bucket {
            case .tmhm:
                return draft.tmhmMoves.contains(moveID)
            case .tutor:
                return draft.tutorMoves.contains(moveID)
            default:
                return false
            }
        }
        guard let detail = catalog.species.first(where: { $0.speciesID == speciesID }) else { return false }
        switch bucket {
        case .tmhm:
            return detail.learnsets.tmhm.contains { $0.move == moveID }
        case .tutor:
            return detail.learnsets.tutor.contains { $0.move == moveID }
        default:
            return false
        }
    }

    func setSpeciesCompatibility(
        speciesID: String,
        moveID: String,
        bucket: PokemonHackCore.LearnsetBucket,
        isEnabled: Bool
    ) {
        guard
            let selectedIndexedProject,
            let detail = selectedSpeciesCatalog?.species.first(where: { $0.speciesID == speciesID }),
            var draft = speciesDraftsByKey[speciesDraftKey(projectID: selectedIndexedProject.id, speciesID: speciesID)]
                ?? PokemonHackCore.SpeciesEditDraft(detail: detail)
        else { return }

        switch bucket {
        case .tmhm:
            setMove(moveID, isEnabled: isEnabled, in: &draft.tmhmMoves)
        case .tutor:
            setMove(moveID, isEnabled: isEnabled, in: &draft.tutorMoves)
        default:
            return
        }

        let key = speciesDraftKey(projectID: selectedIndexedProject.id, speciesID: speciesID)
        if let base = PokemonHackCore.SpeciesEditDraft(detail: detail), base == draft {
            speciesDraftsByKey.removeValue(forKey: key)
        } else {
            speciesDraftsByKey[key] = draft
        }
        latestSpeciesEditPlan = nil
        latestSpeciesApplyResult = nil
        latestSpeciesBatchEditPlans = []
        latestSpeciesBatchApplyResult = nil
        scheduleDraftAutosave()
    }

    private func setMove(_ moveID: String, isEnabled: Bool, in moves: inout [String]) {
        if isEnabled {
            if !moves.contains(moveID) {
                moves.append(moveID)
                moves.sort()
            }
        } else {
            moves.removeAll { $0 == moveID }
        }
    }

    func updateSelectedMoveDraft(_ draft: PokemonHackCore.MoveEditDraft) {
        guard let selectedIndexedProject else { return }
        let key = moveDraftKey(projectID: selectedIndexedProject.id, moveID: draft.moveID)
        if let base = selectedCoreMoveCatalog?.moves.first(where: { $0.moveID == draft.moveID })
            .flatMap(PokemonHackCore.MoveEditDraft.init(detail:)),
           base == draft
        {
            moveDraftsByKey.removeValue(forKey: key)
        } else {
            moveDraftsByKey[key] = draft
        }
        latestMoveEditPlan = nil
        latestMoveApplyResult = nil
        scheduleDraftAutosave()
    }

    func discardMoveEdits() {
        guard let selectedIndexedProject, let detail = selectedCoreMoveDetail else {
            latestMoveEditPlan = nil
            latestMoveApplyResult = nil
            return
        }
        moveDraftsByKey.removeValue(forKey: moveDraftKey(projectID: selectedIndexedProject.id, moveID: detail.moveID))
        latestMoveEditPlan = nil
        latestMoveApplyResult = nil
        scheduleDraftAutosaveIfNeeded()
    }

    func previewSelectedMoveMutationPlan() {
        guard let catalog = selectedCoreMoveCatalog, let draft = selectedMoveDraft else {
            latestMoveEditPlan = nil
            latestMoveApplyResult = nil
            return
        }
        latestMoveEditPlan = MoveMutationPlanner.plan(catalog: catalog, draft: draft, fileManager: fileManager)
        latestMoveApplyResult = nil
    }

    func applySelectedMoveMutationPlan() {
        if latestMoveEditPlan == nil {
            previewSelectedMoveMutationPlan()
        }

        guard let plan = latestMoveEditPlan else { return }
        let projectIDBeforeApply = selectedProjectID
        let moveIDBeforeApply = plan.moveID

        do {
            let result = try MoveMutationApplier.apply(plan: plan, fileManager: fileManager)
            latestMoveApplyResult = result
            guard !result.appliedChanges.isEmpty else { return }
            if !projectIDBeforeApply.isEmpty {
                moveDraftsByKey.removeValue(forKey: moveDraftKey(projectID: projectIDBeforeApply, moveID: moveIDBeforeApply))
            }
            reloadSelectedProjectAfterMoveApply(projectID: projectIDBeforeApply)
            if indexedProjects.contains(where: { $0.id == projectIDBeforeApply }) {
                selectedProjectID = projectIDBeforeApply
            }
            refreshSelectedMoveSelection()
            if selectedCoreMoveCatalog?.moves.contains(where: { $0.moveID == moveIDBeforeApply }) == true {
                selectedMoveID = moveIDBeforeApply
            }
            latestMoveEditPlan = nil
            latestMoveApplyResult = result
            scheduleDraftAutosaveIfNeeded()
        } catch {
            latestMoveApplyResult = MoveApplyResult(
                backupRootPath: plan.backupRelativeRoot,
                appliedChanges: [],
                diagnostics: [
                    Diagnostic(
                        severity: .error,
                        code: "MOVE_APPLY_FAILED",
                        message: error.localizedDescription
                    )
                ]
            )
        }
    }

    func updateSelectedItemDraft(_ draft: PokemonHackCore.ItemEditDraft) {
        guard let selectedIndexedProject else { return }
        let key = itemDraftKey(projectID: selectedIndexedProject.id, itemID: draft.itemID)
        if let base = selectedItemCatalog?.items.first(where: { $0.itemID == draft.itemID })
            .flatMap(PokemonHackCore.ItemEditDraft.init(detail:)),
           base == draft
        {
            itemDraftsByKey.removeValue(forKey: key)
        } else {
            itemDraftsByKey[key] = draft
        }
        latestItemEditPlan = nil
        latestItemApplyResult = nil
        scheduleDraftAutosave()
    }

    func discardItemEdits() {
        guard let selectedIndexedProject, let detail = selectedCoreItemDetail else {
            latestItemEditPlan = nil
            latestItemApplyResult = nil
            return
        }
        itemDraftsByKey.removeValue(forKey: itemDraftKey(projectID: selectedIndexedProject.id, itemID: detail.itemID))
        latestItemEditPlan = nil
        latestItemApplyResult = nil
        scheduleDraftAutosaveIfNeeded()
    }

    func previewSelectedItemMutationPlan() {
        guard let catalog = selectedItemCatalog, let draft = selectedItemDraft else {
            latestItemEditPlan = nil
            latestItemApplyResult = nil
            return
        }
        latestItemEditPlan = ItemMutationPlanner.plan(catalog: catalog, draft: draft, fileManager: fileManager)
        latestItemApplyResult = nil
    }

    func applySelectedItemMutationPlan() {
        if latestItemEditPlan == nil {
            previewSelectedItemMutationPlan()
        }

        guard let plan = latestItemEditPlan else { return }
        let projectIDBeforeApply = selectedProjectID
        let itemIDBeforeApply = plan.itemID

        do {
            let result = try ItemMutationApplier.apply(plan: plan, fileManager: fileManager)
            latestItemApplyResult = result
            guard !result.appliedChanges.isEmpty else { return }
            if !projectIDBeforeApply.isEmpty {
                itemDraftsByKey.removeValue(forKey: itemDraftKey(projectID: projectIDBeforeApply, itemID: itemIDBeforeApply))
            }
            reloadSelectedProjectAfterItemApply(projectID: projectIDBeforeApply)
            if indexedProjects.contains(where: { $0.id == projectIDBeforeApply }) {
                selectedProjectID = projectIDBeforeApply
            }
            refreshSelectedItemSelection()
            if selectedItemCatalog?.items.contains(where: { $0.itemID == itemIDBeforeApply }) == true {
                selectedItemID = itemIDBeforeApply
            }
            latestItemEditPlan = nil
            latestItemApplyResult = result
            scheduleDraftAutosaveIfNeeded()
        } catch {
            latestItemApplyResult = ItemApplyResult(
                backupRootPath: plan.backupRelativeRoot,
                appliedChanges: [],
                diagnostics: [
                    Diagnostic(
                        severity: .error,
                        code: "ITEM_APPLY_FAILED",
                        message: error.localizedDescription
                    )
                ]
            )
        }
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
        scheduleDraftAutosaveIfNeeded()
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
            scheduleDraftAutosaveIfNeeded()
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

    func discardSpeciesBatchEdits() {
        guard let selectedIndexedProject else {
            latestSpeciesBatchEditPlans = []
            latestSpeciesBatchApplyResult = nil
            return
        }
        let speciesIDs = Set(dirtySpeciesBatchDrafts.map(\.speciesID))
        for speciesID in speciesIDs {
            speciesDraftsByKey.removeValue(forKey: speciesDraftKey(projectID: selectedIndexedProject.id, speciesID: speciesID))
        }
        latestSpeciesBatchEditPlans = []
        latestSpeciesBatchApplyResult = nil
        latestSpeciesEditPlan = nil
        latestSpeciesApplyResult = nil
        scheduleDraftAutosaveIfNeeded()
    }

    func previewSpeciesBatchMutationPlan() {
        guard let catalog = selectedSpeciesCatalog else {
            latestSpeciesBatchEditPlans = []
            latestSpeciesBatchApplyResult = nil
            return
        }
        latestSpeciesBatchEditPlans = dirtySpeciesBatchDrafts.map { draft in
            SpeciesMutationPlanner.plan(catalog: catalog, draft: draft, fileManager: fileManager)
        }
        latestSpeciesBatchApplyResult = nil
    }

    func applySpeciesBatchMutationPlan() {
        if latestSpeciesBatchEditPlans.isEmpty {
            previewSpeciesBatchMutationPlan()
        }

        guard
            let selectedIndexedProject,
            !latestSpeciesBatchEditPlans.isEmpty
        else { return }

        let projectIDBeforeApply = selectedIndexedProject.id
        let rootPath = selectedIndexedProject.rootPath
        let drafts = latestSpeciesBatchEditPlans.map(\.draft)
        var appliedChanges: [AppliedSpeciesFileChange] = []
        var diagnostics: [Diagnostic] = []
        var backupRootPath = latestSpeciesBatchEditPlans.first?.backupRelativeRoot ?? ".pokemonhackstudio/backups"

        do {
            var catalog = try ProjectSpeciesCatalogBuilder.build(path: rootPath, fileManager: fileManager)
            for draft in drafts {
                let plan = SpeciesMutationPlanner.plan(catalog: catalog, draft: draft, fileManager: fileManager)
                backupRootPath = plan.backupRelativeRoot
                let applyability = plan.validateApplyability(fileManager: fileManager)
                guard applyability.isApplyable else {
                    diagnostics.append(contentsOf: applyability.diagnostics)
                    break
                }
                let result = try SpeciesMutationApplier.apply(plan: plan, fileManager: fileManager)
                appliedChanges.append(contentsOf: result.appliedChanges)
                diagnostics.append(contentsOf: result.diagnostics)
                speciesDraftsByKey.removeValue(forKey: speciesDraftKey(projectID: projectIDBeforeApply, speciesID: draft.speciesID))
                catalog = try ProjectSpeciesCatalogBuilder.build(path: rootPath, fileManager: fileManager)
            }

            latestSpeciesBatchApplyResult = SpeciesApplyResult(
                backupRootPath: backupRootPath,
                appliedChanges: appliedChanges,
                diagnostics: diagnostics
            )
            guard !appliedChanges.isEmpty else { return }
            reloadSelectedProjectAfterSpeciesApply(projectID: projectIDBeforeApply)
            if indexedProjects.contains(where: { $0.id == projectIDBeforeApply }) {
                selectedProjectID = projectIDBeforeApply
            }
            refreshSelectedSpeciesSelection()
            latestSpeciesBatchEditPlans = []
            latestSpeciesEditPlan = nil
            latestSpeciesApplyResult = nil
            scheduleDraftAutosaveIfNeeded()
        } catch {
            latestSpeciesBatchApplyResult = SpeciesApplyResult(
                backupRootPath: backupRootPath,
                appliedChanges: appliedChanges,
                diagnostics: [
                    Diagnostic(
                        severity: .error,
                        code: "SPECIES_BATCH_APPLY_FAILED",
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

        trainerCatalogTask?.cancel()
        trainerCatalogLoadStatus = .loading
        let projectID = selectedIndexedProject.id
        let rootPath = selectedIndexedProject.rootPath
        let generation = projectLoadGeneration

        trainerCatalogTask = Task { @MainActor [weak self] in
            do {
                let payloadData = try await Task.detached(priority: .userInitiated) { () throws -> Data in
                    let index = try GameAdapterRegistry.index(path: rootPath, fileManager: .default)
                    let catalog = try ProjectTrainerCatalogBuilder.build(index: index, fileManager: .default)
                    return try JSONEncoder().encode(TrainerCatalogLoadPayload(index: index, catalog: catalog))
                }.value
                guard !Task.isCancelled else { return }
                let payload = try JSONDecoder().decode(TrainerCatalogLoadPayload.self, from: payloadData)
                guard let self,
                      self.projectLoadGeneration == generation,
                      self.selectedIndexedProject?.id == projectID
                else { return }

                projectIndexesByID[projectID] = payload.index
                trainerCatalogsByID[projectID] = payload.catalog
                trainerCatalogLoadStatus = .loaded(payload.catalog.trainerCount)
                refreshSelectedTrainerSelection()
            } catch {
                guard let self,
                      self.projectLoadGeneration == generation,
                      self.selectedIndexedProject?.id == projectID
                else { return }
                trainerCatalogLoadStatus = .failed(error.localizedDescription)
            }
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
        scheduleDraftAutosave()
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
        scheduleDraftAutosaveIfNeeded()
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
            scheduleDraftAutosaveIfNeeded()
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

    private func reloadSelectedProjectAfterMoveApply(projectID: String) {
        let rootPath = indexedProjects.first { $0.id == projectID }?.rootPath ?? projectID
        guard fileManager.fileExists(atPath: rootPath) else { return }

        do {
            let index = try GameAdapterRegistry.index(path: rootPath, fileManager: fileManager)
            let summary = Self.summary(from: index)
            projectIndexesByID[summary.id] = index
            let sourceIndex = try ProjectSourceIndexLoader.load(from: index, fileManager: fileManager)
            sourceIndexesByID[summary.id] = sourceIndex
            let speciesCatalog = try? ProjectSpeciesCatalogBuilder.build(index: index, fileManager: fileManager)
            speciesCatalogsByID[summary.id] = speciesCatalog
            let moveCatalog = try ProjectMoveCatalogBuilder.build(index: index, sourceIndex: sourceIndex, speciesCatalog: speciesCatalog, fileManager: fileManager)
            coreMoveCatalogsByID[summary.id] = moveCatalog
            moveCatalogsByID[summary.id] = Self.moveCatalog(from: moveCatalog, project: summary)
            upsert(summary)
            selectedProjectID = summary.id
            refreshSelectedMoveSelection()
        } catch {
            moveCatalogLoadStatus = .failed(error.localizedDescription)
        }
    }

    private func reloadSelectedProjectAfterItemApply(projectID: String) {
        let rootPath = indexedProjects.first { $0.id == projectID }?.rootPath ?? projectID
        guard fileManager.fileExists(atPath: rootPath) else { return }

        do {
            let index = try GameAdapterRegistry.index(path: rootPath, fileManager: fileManager)
            let summary = Self.summary(from: index)
            projectIndexesByID[summary.id] = index
            let sourceIndex = try ProjectSourceIndexLoader.load(from: index, fileManager: fileManager)
            sourceIndexesByID[summary.id] = sourceIndex
            itemCatalogsByID[summary.id] = try ProjectItemCatalogBuilder.build(index: index, sourceIndex: sourceIndex, fileManager: fileManager)
            upsert(summary)
            selectedProjectID = summary.id
            refreshSelectedItemSelection()
        } catch {
            itemCatalogLoadStatus = .failed(error.localizedDescription)
        }
    }

    private func reloadSelectedProjectAfterGraphicsApply(projectID: String) {
        let rootPath = indexedProjects.first { $0.id == projectID }?.rootPath ?? projectID
        guard fileManager.fileExists(atPath: rootPath) else { return }

        do {
            let index = try GameAdapterRegistry.index(path: rootPath, fileManager: fileManager)
            let summary = Self.summary(from: index)
            projectIndexesByID[summary.id] = index
            let sourceIndex = try ProjectSourceIndexLoader.load(from: index, fileManager: fileManager)
            sourceIndexesByID[summary.id] = sourceIndex
            graphicsReportsByID[summary.id] = Self.graphicsReport(from: index, project: summary, fileManager: fileManager)
            upsert(summary)
            selectedProjectID = summary.id
        } catch {
            graphicsImportPackagePlanStatus = .failed(error.localizedDescription)
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
    func saveProjectWorkspace() -> Bool {
        guard let workspace = workspaceSnapshot(), let project = selectedIndexedProject else { return false }

        do {
            try ProjectWorkspacePersistence.saveProject(workspace, root: URL(fileURLWithPath: project.rootPath), fileManager: fileManager)
            latestSavedWorkspace = workspace
            workspacePersistenceStatus = "Project saved"
            workspacePersistenceError = nil
            workspaceAutosavePending = false
            return true
        } catch {
            workspacePersistenceStatus = "Save failed"
            workspacePersistenceError = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func saveDraftsNow() -> Bool {
        autosaveTask?.cancel()
        guard let workspace = workspaceSnapshot(), let project = selectedIndexedProject else {
            workspaceAutosavePending = false
            return false
        }

        do {
            try ProjectWorkspacePersistence.saveAutosave(workspace, root: URL(fileURLWithPath: project.rootPath), fileManager: fileManager)
            latestSavedWorkspace = workspace
            workspacePersistenceStatus = workspace.drafts.isEmpty ? "No drafts saved" : "Drafts saved"
            workspacePersistenceError = nil
            workspaceAutosavePending = false
            return true
        } catch {
            workspacePersistenceStatus = "Autosave failed"
            workspacePersistenceError = error.localizedDescription
            workspaceAutosavePending = false
            return false
        }
    }

    @discardableResult
    func loadSavedWorkspaceForSelectedProject() -> Bool {
        guard let project = selectedIndexedProject else { return false }
        let root = URL(fileURLWithPath: project.rootPath)

        do {
            let autosave = try ProjectWorkspacePersistence.loadAutosave(root: root, fileManager: fileManager)
            let projectSave = try ProjectWorkspacePersistence.loadProject(root: root, fileManager: fileManager)
            guard let workspace = [autosave, projectSave].compactMap(\.self).max(by: { $0.savedAt < $1.savedAt }) else {
                latestSavedWorkspace = nil
                workspacePersistenceStatus = "Not saved"
                workspacePersistenceError = nil
                return false
            }

            applySavedWorkspace(workspace, toProjectID: project.id)
            workspacePersistenceStatus = workspace.drafts.isEmpty ? "Project loaded" : "Drafts loaded"
            workspacePersistenceError = nil
            return true
        } catch {
            latestSavedWorkspace = nil
            workspacePersistenceStatus = "Load failed"
            workspacePersistenceError = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func discardSavedDrafts() -> Bool {
        guard let project = selectedIndexedProject else { return false }
        let projectID = project.id
        let root = URL(fileURLWithPath: project.rootPath)

        autosaveTask?.cancel()
        clearDrafts(for: projectID)
        if mapEditorSession.isDirty {
            mapEditorSession.discardChanges()
        }
        latestSpeciesEditPlan = nil
        latestSpeciesApplyResult = nil
        latestTrainerEditPlan = nil
        latestTrainerApplyResult = nil
        latestMoveEditPlan = nil
        latestMoveApplyResult = nil
        latestItemEditPlan = nil
        latestItemApplyResult = nil
        latestGraphicsEditPlan = nil
        latestGraphicsApplyResult = nil
        latestNDSDataEditPlan = nil
        latestNDSDataApplyResult = nil

        do {
            try ProjectWorkspacePersistence.discardAutosave(root: root, fileManager: fileManager)
            if let workspace = workspaceSnapshot() {
                try ProjectWorkspacePersistence.saveProject(workspace, root: root, fileManager: fileManager)
                latestSavedWorkspace = workspace
            } else {
                latestSavedWorkspace = nil
            }
            workspacePersistenceStatus = "Drafts discarded"
            workspacePersistenceError = nil
            workspaceAutosavePending = false
            return true
        } catch {
            workspacePersistenceStatus = "Discard failed"
            workspacePersistenceError = error.localizedDescription
            workspaceAutosavePending = false
            return false
        }
    }

    private func scheduleDraftAutosave() {
        guard selectedIndexedProject != nil else { return }
        autosaveTask?.cancel()
        workspaceAutosavePending = true
        autosaveTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: Self.autosaveDelayNanoseconds)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            _ = self?.saveDraftsNow()
        }
    }

    private func scheduleDraftAutosaveIfNeeded() {
        guard selectedIndexedProject != nil else { return }
        if hasStagedEdits || savedDraftCount > 0 || workspaceAutosavePending {
            scheduleDraftAutosave()
        }
    }

    private func applySavedWorkspace(_ workspace: PokemonHackCore.SavedHackWorkspace, toProjectID projectID: String) {
        clearDrafts(for: projectID)
        latestSavedWorkspace = workspace

        if let selectedModule = workspace.selectedModule.flatMap(WorkbenchModule.init(rawValue:)) {
            selection = selectedModule
        }
        if let mapID = workspace.selectedMapID, !mapID.isEmpty {
            selectedMapID = mapID
        }
        if let speciesID = workspace.selectedSpeciesID, !speciesID.isEmpty {
            selectedSpeciesID = speciesID
        }
        if let trainerID = workspace.selectedTrainerID, !trainerID.isEmpty {
            selectedTrainerID = trainerID
        }
        if let moveID = workspace.selectedMoveID, !moveID.isEmpty {
            selectedMoveID = moveID
        }
        if let itemID = workspace.selectedItemID, !itemID.isEmpty {
            selectedItemID = itemID
        }

        for draft in workspace.drafts.speciesDrafts {
            speciesDraftsByKey[speciesDraftKey(projectID: projectID, speciesID: draft.speciesID)] = draft
        }
        for draft in workspace.drafts.trainerDrafts {
            trainerDraftsByKey[trainerDraftKey(projectID: projectID, trainerID: draft.trainerID)] = draft
        }
        for draft in workspace.drafts.moveDrafts {
            moveDraftsByKey[moveDraftKey(projectID: projectID, moveID: draft.moveID)] = draft
        }
        for draft in workspace.drafts.itemDrafts {
            itemDraftsByKey[itemDraftKey(projectID: projectID, itemID: draft.itemID)] = draft
        }
        for draft in workspace.drafts.graphicsDrafts where !draft.operations.isEmpty {
            graphicsDraftsByKey[graphicsDraftKey(projectID: projectID, tilesetSymbol: draft.tilesetSymbol)] = draft
        }
        for draft in workspace.drafts.ndsDataDrafts {
            ndsDataDraftsByKey[ndsDataDraftKey(projectID: projectID, recordID: draft.recordID)] = draft
        }
        savedMapDraftsByProjectID[projectID] = workspace.drafts.mapDrafts
        restoreSelectedMapDraftIfAvailable(projectID: projectID)
    }

    private func restoreSelectedMapDraftIfAvailable(projectID: String? = nil) {
        guard let projectID = projectID ?? selectedIndexedProject?.id,
              let document = mapEditorSession.selectedMapVisualDocument,
              let draft = savedMapDraftsByProjectID[projectID]?.first(where: { $0.mapID == document.mapID })
        else {
            return
        }
        mapEditorSession.restoreSavedDraft(operations: draft.operations)
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

    func chooseGameCubeResourceImage() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["iso", "gcm"]
        if panel.runModal() == .OK, let url = panel.url {
            selectedGameCubeResourcePath = url.standardizedFileURL.path
            loadSelectedGameCubeResourcePath()
        }
    }

    func loadSelectedGameCubeResourcePath() {
        let trimmed = selectedGameCubeResourcePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            explicitGameCubeResourceEntry = nil
            selectedResourceLibraryEntryID = ""
            gameCubeResourceLoadStatus = .idle
            return
        }

        let entry = GenIIIResourceRegistry.resourceIndex(
            path: trimmed,
            role: .localInput,
            fileManager: fileManager
        )
        guard entry.platform == .gameCube else {
            explicitGameCubeResourceEntry = nil
            selectedResourceLibraryEntryID = ""
            gameCubeResourceLoadStatus = .failed("Select a supported .iso or .gcm GameCube disc image.")
            return
        }

        let viewState = Self.resourceEntryViewState(from: entry)
        explicitGameCubeResourceEntry = viewState
        selectedResourceLibraryEntryID = viewState.id
        selectedResourceLibraryMode = .entries
        gameCubeResourceLoadStatus = .loaded(itemCount: viewState.items.count)
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

    func openPlaytestArtifact(_ artifact: PlaytestArtifactViewState) {
        guard artifact.canOpenOrReveal, let absolutePath = artifact.absolutePath else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: absolutePath))
    }

    func revealPlaytestArtifact(_ artifact: PlaytestArtifactViewState) {
        guard artifact.canOpenOrReveal, let absolutePath = artifact.absolutePath else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: absolutePath)])
    }

    private func appendBuildRunLog(_ event: PokemonHackCore.DecompBuildLogEvent, projectID: String) {
        var lines = buildRunLogLinesByID[projectID] ?? []
        lines.append(
            BuildRunLogLineViewState(
                id: event.id,
                stream: event.stream.rawValue,
                message: event.message,
                emittedAt: event.emittedAt
            )
        )
        buildRunLogLinesByID[projectID] = Array(lines.suffix(400))
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

    func copyBuildReportRowActionToPasteboard(_ action: BuildReportRowAction) {
        guard let value = action.copyValue else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    func copyGraphicsImportPackagePlanJSONToPasteboard() {
        guard let rawGraphicsImportPackagePlan else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        if let data = try? encoder.encode(rawGraphicsImportPackagePlan), let json = String(data: data, encoding: .utf8) {
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
            rootPath: selectedIndexedProject.rootPath,
            artifactRootPath: (artifactRoot ?? workspaceRoot).path
        )
    }

    func runSelectedDecompBuild(
        artifactRoot: URL? = nil,
        runner: @escaping (
            PokemonHackCore.ProjectIndex,
            String,
            URL?,
            FileManager,
            @escaping ToolAvailabilityResolver,
            @escaping DecompBuildLogHandler
        ) async -> PokemonHackCore.DecompBuildResult = { index, targetID, artifactRoot, fileManager, toolResolver, logHandler in
            await PokemonHackCore.DecompBuildRunner.run(
                index: index,
                targetID: targetID,
                artifactRoot: artifactRoot,
                fileManager: fileManager,
                toolResolver: toolResolver,
                logHandler: logHandler
            )
        }
    ) {
        guard runningBuildTargetID == nil,
              let selectedIndexedProject,
              let index = projectIndexesByID[selectedIndexedProject.id] else {
            return
        }
        let targetID = selectedEffectiveDecompBuildTargetID
        guard !targetID.isEmpty else { return }

        selectedDecompBuildTargetID = targetID
        runningBuildTargetID = targetID
        buildRunLogLinesByID[selectedIndexedProject.id] = []
        buildRunResultsByID.removeValue(forKey: selectedIndexedProject.id)

        let project = selectedIndexedProject
        let resolvedArtifactRoot = artifactRoot ?? workspaceRoot
        decompBuildTask = Task { @MainActor in
            let result = await runner(
                index,
                targetID,
                resolvedArtifactRoot,
                .default,
                toolResolver
            ) { [weak self] event in
                Task { @MainActor in
                    self?.appendBuildRunLog(event, projectID: project.id)
                }
            }

            guard projectIndexesByID[project.id] != nil else { return }
            buildRunResultsByID[project.id] = Self.buildRunResult(
                from: result,
                rootPath: project.rootPath
            )
            let coreBuildReport = BuildValidationReportBuilder.build(index: index, fileManager: fileManager, toolResolver: toolResolver)
            buildReportsByID[project.id] = Self.buildReport(from: index, project: project, fileManager: fileManager, toolResolver: toolResolver, buildReport: coreBuildReport)
            runningBuildTargetID = nil
            decompBuildTask = nil
        }
    }

    func cancelSelectedDecompBuild() {
        decompBuildTask?.cancel()
    }

    func captureSelectedPlaytest(
        kind: PlaytestCaptureKind,
        artifactRoot: URL? = nil,
        processRunner: PlaytestProcessRunner = PlaytestLauncher.defaultProcessRunner
    ) {
        guard let selectedIndexedProject,
              let index = projectIndexesByID[selectedIndexedProject.id] else {
            return
        }

        let result = PlaytestLauncher.capture(
            index: index,
            kind: kind,
            mode: .interactive,
            artifactRoot: artifactRoot ?? workspaceRoot,
            fileManager: fileManager,
            toolResolver: toolResolver,
            processRunner: processRunner
        )
        playtestCaptureResultsByID[selectedIndexedProject.id] = Self.playtestCaptureResult(
            from: result,
            rootPath: selectedIndexedProject.rootPath,
            artifactRootPath: (artifactRoot ?? workspaceRoot).path
        )
    }

    func loadSelectedAssetCatalogIfNeeded(force: Bool = false) {
        guard let project = selectedIndexedProject else {
            assetCatalogLoadStatus = .idle
            return
        }

        let fingerprint = Self.assetCatalogFingerprint(rootPath: project.rootPath, fileManager: fileManager)
        if force {
            ndsDataCatalogsByID.removeValue(forKey: project.id)
            ndsDataCatalogFingerprintsByID.removeValue(forKey: project.id)
        }
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
        let generation = projectLoadGeneration

        assetCatalogTask = Task { @MainActor [weak self] in
            do {
                let data = try await Task.detached(priority: .userInitiated) { () throws -> Data in
                    let catalog = GenIIIAssetCatalogBuilder.build(path: rootPath)
                    return try JSONEncoder().encode(catalog)
                }.value
                guard !Task.isCancelled else { return }
                let catalog = try JSONDecoder().decode(GenIIIAssetCatalog.self, from: data)
                guard let self,
                      self.projectLoadGeneration == generation,
                      self.selectedIndexedProject?.id == projectID
                else { return }
                let viewState = Self.assetCatalogViewState(from: catalog, project: projectSummary)
                assetCatalogsByID[projectID] = viewState
                assetCatalogFingerprintsByID[projectID] = fingerprint
                _ = self.ndsDataCatalog(for: projectSummary)
                resourceAssetRowsCache = nil
                resolvePendingResourceAssetFocusIfNeeded()
                assetCatalogLoadStatus = .loaded(viewState.assetCount)
            } catch {
                guard let self,
                      self.projectLoadGeneration == generation,
                      self.selectedIndexedProject?.id == projectID
                else { return }
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

    @discardableResult
    func refreshSelectedMapCatalog(ignoringStagedEdits: Bool = false) -> Bool {
        if hasStagedMapEdits && !ignoringStagedEdits {
            pendingMapNavigation = .refreshMaps
            clearPendingMapNavigationContext()
            return false
        }
        mapCatalogTask?.cancel()
        mapVisualTask?.cancel()
        selectedMapCatalog = nil
        if let selectedIndexedProject {
            mapCatalogsByID.removeValue(forKey: selectedIndexedProject.id)
        }
        selectedMapID = ""
        mapCatalogStatus = selectedIndexedProject == nil ? .idle : .loading
        clearSelectedMapVisualDocument()
        return true
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
        let generation = projectLoadGeneration

        mapCatalogTask = Task { @MainActor [weak self] in
            do {
                let payloadData = try await Task.detached(priority: .userInitiated) { () throws -> Data in
                    let index = try GameAdapterRegistry.index(path: rootPath, fileManager: .default)
                    let catalog = try ProjectMapCatalogLoader.load(from: index, fileManager: .default)
                    return try JSONEncoder().encode(MapCatalogLoadPayload(index: index, catalog: catalog))
                }.value
                guard !Task.isCancelled else { return }
                let payload = try JSONDecoder().decode(MapCatalogLoadPayload.self, from: payloadData)
                guard let self,
                      self.projectLoadGeneration == generation,
                      self.selectedIndexedProject?.id == projectID
                else { return }

                projectIndexesByID[projectID] = payload.index
                mapCatalogsByID[projectID] = payload.catalog
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
                if !hasStagedMapEdits {
                    loadSelectedMapVisualDocumentIfNeeded()
                }
                refreshSelectedScriptReadinessReportIfVisible()
            } catch {
                guard let self,
                      self.projectLoadGeneration == generation,
                      self.selectedIndexedProject?.id == projectID
                else { return }
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
        let generation = projectLoadGeneration

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
                      self.projectLoadGeneration == generation,
                      self.selectedIndexedProject?.id == projectID,
                      self.selectedMapID == mapID
                else { return }

                mapVisualSharedCacheDataByID[projectID] = try? JSONEncoder().encode(payload.sharedCache)
                mapEditorSession.load(document: payload.document, preserveSelection: false)
                applyMapEditorDefaults()
                restoreSelectedMapDraftIfAvailable(projectID: projectID)
                mapVisualStatus = .loaded(payload.document.mapName)
            } catch {
                guard let self,
                      self.projectLoadGeneration == generation,
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
                savedMapDraftsByProjectID[projectIDBeforeApply]?.removeAll { $0.mapID == mapIDBeforeApply }
            }
            if selectedProjectID == projectIDBeforeApply {
                loadSelectedMapCatalog()
                loadSelectedMapVisualDocument()
            }
            scheduleDraftAutosaveIfNeeded()
        } catch {
            mapEditorSession.recordApplyFailure(error)
        }
    }

    private func defaultProjectRoots() -> [String] {
        #if DEBUG
        guard userSettings.includeDefaultDebugProjects else { return [] }
        return ["pokeemerald", "pokefirered", "pokediamond", "pokeplatinum", "pokeheartgold", "pokesoulsilver", "pmd-sky"]
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
        let components = URL(fileURLWithPath: path).standardizedFileURL.pathComponents
        if components.contains("references") {
            return true
        }
        guard let projectsIndex = components.firstIndex(of: "projects"),
              components.indices.contains(projectsIndex + 2)
        else {
            return false
        }
        return components[projectsIndex + 1] == "reference-repos"
            && components[projectsIndex + 2] == "repos"
    }

    private static func pathIsBundledAssetRoot(_ path: String) -> Bool {
        URL(fileURLWithPath: path).standardizedFileURL.pathComponents.contains(bundledAssetsDirectoryName)
    }

    private static func isGameCubeProfile(_ profile: PokemonHackCore.GameProfile) -> Bool {
        switch profile {
        case .pokemonColosseum, .pokemonXD, .pokemonBox, .pokemonChannel, .gameCubeMedia:
            return true
        default:
            return false
        }
    }

    private static func isNDSSourceProject(_ index: PokemonHackCore.ProjectIndex) -> Bool {
        index.platform == .nds && index.projectKind == .sourceTree
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
        let displayWritePolicy = writePolicyDisplayValue(for: index)
        let isReadOnlyProject = displayWritePolicy == PokemonHackCore.WritePolicy.readOnly.rawValue
        let sourceSurfaces = index.documents.map { surface(from: $0, isReadOnlyProject: isReadOnlyProject) }
        let generatedOutputs = index.generatedOutputs.map { surface(from: $0, isReadOnlyProject: isReadOnlyProject) }
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
            writePolicy: displayWritePolicy,
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
        if pathIsReferenceRoot(rootURL.path) {
            return ("Reference", "Read-only reference source")
        }
        if isNDSSourceProject(index) {
            return ("Local Source", "Read-only NDS source root")
        }
        return ("Editable", "Editable source root")
    }

    private static func writePolicyDisplayValue(for index: PokemonHackCore.ProjectIndex) -> String {
        isNDSSourceProject(index) ? PokemonHackCore.WritePolicy.readOnly.rawValue : index.writePolicy.rawValue
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
        let playtestDebug = playtestDebugPlan(
            from: PlaytestDebugPlanBuilder.build(
                handoff: playtestReport,
                fileManager: fileManager,
                toolResolver: toolResolver
            ),
            rootPath: project.rootPath
        )
        let baseROMOptions = baseROMOptions(from: buildReport, rootPath: project.rootPath)
        let diagnostics = (buildReport.diagnostics + playtestReport.diagnostics + healthReport.diagnostics).map {
            diagnostic(from: $0, rootPath: project.rootPath)
        }
        let states = buildTargets.map(\.status)
            + generatedArtifacts.map(\.status)
            + toolchain.rows.map(\.status)
            + healthMatrix.rows.map(\.status)
            + [toolchain.status, healthMatrix.status, playtest.status, playtestDebug.status]
            + diagnostics.map(\.severity)

        return BuildPatchPlaytestReportViewState(
            id: project.id,
            projectTitle: project.title,
            rootPath: project.rootPath,
            profile: project.profile,
            isNDS: index.profile.platform == .nds,
            status: validationStatus(for: states),
            buildTargets: buildTargets,
            generatedArtifacts: generatedArtifacts,
            toolchain: toolchain,
            healthMatrix: healthMatrix,
            playtest: playtest,
            playtestDebug: playtestDebug,
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

    private static func graphicsImportPackagePlanViewState(
        from plan: PokemonHackCore.GraphicsImportPackagePlan,
        rootPath: String
    ) -> GraphicsImportPackagePlanViewState {
        let diagnostics = plan.diagnostics.map {
            diagnostic(from: $0, rootPath: plan.packageRoot.path)
        }
        let status = validationStatus(for: diagnostics.map(\.severity))
        let inventory = plan.sourceFiles.map(graphicsImportInventoryRow)
        let creditRows = inventory.filter { row in
            row.tags.contains(PokemonHackCore.GraphicsImportSourceKind.creditMetadata.rawValue)
        }
        let copyTargets = plan.copyPlan.map(graphicsImportCopyTargetRow)
        let layeredDryRun = graphicsImportLayeredDryRunViewState(from: plan.layeredTilesetDryRun)
        let palettePreviews = plan.paletteFitPreviews.map { preview in
            graphicsImportPaletteFitPreviewViewState(from: preview, packageRootPath: plan.packageRoot.path)
        }

        return GraphicsImportPackagePlanViewState(
            id: plan.packageRoot.path,
            projectRootPath: plan.projectRoot.path.isEmpty ? rootPath : plan.projectRoot.path,
            packageRootPath: plan.packageRoot.path,
            packageTitle: plan.packageTitle,
            readiness: plan.readiness.rawValue,
            status: status,
            isPreviewOnly: plan.isPreviewOnly,
            inventoryRows: inventory,
            creditMetadataRows: creditRows,
            copyTargets: copyTargets,
            layeredDryRun: layeredDryRun,
            paletteFitPreviews: palettePreviews,
            expectedOutputs: plan.layeredTilesetDryRun.expectedGeneratedOutputs,
            diagnostics: diagnostics
        )
    }

    private static func graphicsImportInventoryRow(
        from file: PokemonHackCore.GraphicsImportSourceFile
    ) -> GraphicsImportInventoryRowViewState {
        let kindTitle = graphicsImportSourceKindTitle(file.kind)
        let checksum = "sha1 \(file.sha1.prefix(8))"
        var details = ["\(file.sizeBytes) bytes", checksum]
        if let png = file.png {
            let paletteCount = png.paletteColorCount.map { "\($0) indexed colors" } ?? "no PLTE chunk"
            details.append("PNG \(png.width)x\(png.height), bit \(png.bitDepth), color type \(png.colorType), \(paletteCount)")
        }
        if let palette = file.palette {
            details.append("\(palette.format), \(palette.colorCount) colors, \(palette.gbaPrecisionLossCount) precision-loss colors")
        }
        let status: ValidationState = file.kind == .unsupported ? .warning : .valid
        return GraphicsImportInventoryRowViewState(
            id: file.relativePath,
            title: URL(fileURLWithPath: file.relativePath).lastPathComponent,
            subtitle: kindTitle,
            detail: details.joined(separator: "; "),
            status: status,
            source: SourceLocation(path: file.relativePath, symbol: kindTitle, line: 1),
            tags: [file.relativePath, file.kind.rawValue, kindTitle, checksum]
        )
    }

    private static func graphicsImportCopyTargetRow(
        from copyPlan: PokemonHackCore.GraphicsImportCopyPlan
    ) -> GraphicsImportCopyTargetViewState {
        let overwrite = copyPlan.willOverwriteExistingSource
        return GraphicsImportCopyTargetViewState(
            id: copyPlan.id,
            title: copyPlan.destinationRelativePath,
            subtitle: copyPlan.sourceRelativePath,
            detail: overwrite ? "Would overwrite an existing project source path." : "Would copy into a new project source path.",
            status: overwrite ? .warning : .valid,
            source: SourceLocation(path: copyPlan.destinationRelativePath, symbol: "Copy Target", line: 1),
            tags: [
                copyPlan.sourceRelativePath,
                copyPlan.destinationRelativePath,
                overwrite ? "overwrite" : "new"
            ],
            willOverwriteExistingSource: overwrite
        )
    }

    private static func graphicsImportLayeredDryRunViewState(
        from dryRun: PokemonHackCore.GraphicsLayeredTilesetDryRun
    ) -> GraphicsImportLayeredDryRunViewState {
        let status: ValidationState = dryRun.missingLayerNames.isEmpty ? .valid : .warning
        let detected = dryRun.detectedLayerPaths.isEmpty
            ? "No layered PNGs detected"
            : "\(dryRun.detectedLayerPaths.count) layered PNG(s) detected"
        let missing = dryRun.missingLayerNames.isEmpty
            ? "all top/middle/bottom layers present"
            : "missing \(dryRun.missingLayerNames.joined(separator: ", "))"
        let attributes = dryRun.attributesPath.map { "attributes \($0)" } ?? "attributes not found"
        return GraphicsImportLayeredDryRunViewState(
            title: "Layered tileset dry run",
            detail: "\(detected); \(missing); \(attributes); \(dryRun.animationFileCount) animation file(s).",
            status: status,
            detectedLayerPaths: dryRun.detectedLayerPaths,
            missingLayerNames: dryRun.missingLayerNames,
            attributesPath: dryRun.attributesPath,
            animationFileCount: dryRun.animationFileCount,
            expectedGeneratedOutputs: dryRun.expectedGeneratedOutputs,
            externalToolPlan: dryRun.externalToolPlan
        )
    }

    private static func graphicsImportPaletteFitPreviewViewState(
        from preview: PokemonHackCore.GraphicsPaletteFitPreview,
        packageRootPath: String
    ) -> GraphicsImportPaletteFitPreviewViewState {
        let diagnostics = preview.diagnostics.map {
            diagnostic(from: $0, rootPath: packageRootPath)
        }
        let status = preview.isReadyFor4bpp
            ? validationStatus(for: diagnostics.map(\.severity))
            : .warning
        return GraphicsImportPaletteFitPreviewViewState(
            id: preview.id,
            title: preview.sourceRelativePath,
            detail: "\(preview.colorSummary). \(preview.transparencySummary) \(preview.precisionSummary) \(preview.nearestPaletteSummary)",
            status: status,
            source: SourceLocation(path: preview.sourceRelativePath, symbol: "Palette Fit", line: 1),
            tags: [
                preview.sourceRelativePath,
                preview.colorSummary,
                preview.transparencySummary,
                preview.precisionSummary,
                preview.nearestPaletteSummary,
                preview.isReadyFor4bpp ? "ready" : "needs review"
            ],
            diagnostics: diagnostics
        )
    }

    private static func graphicsImportSourceKindTitle(_ kind: PokemonHackCore.GraphicsImportSourceKind) -> String {
        switch kind {
        case .tileImage:
            "Tile image"
        case .palette:
            "Palette"
        case .layeredTileImage:
            "Layered tile image"
        case .attributes:
            "Attributes"
        case .animation:
            "Animation"
        case .creditMetadata:
            "Credit metadata"
        case .designSource:
            "Design source"
        case .unsupported:
            "Unsupported"
        }
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
            writePolicy: resourceEntryWritePolicyDisplayValue(for: entry),
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

    private static func resourceEntryWritePolicyDisplayValue(for entry: PokemonHackCore.GenIIIResourceEntry) -> String {
        entry.platform == .ndsSource ? PokemonHackCore.WritePolicy.readOnly.rawValue : entry.writePolicy.rawValue
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
                healthStatus: WorkbenchHealthCheckStatus(rawValue: row.status.rawValue),
                actions: row.actions.map(buildReportRowAction)
            )
        }

        let status = validationStatus(for: rows.map(\.status))
        let summary = report.summary.all
        return ToolchainHealthMatrixViewState(
            id: "health:\(report.rootPath)",
            isNDS: report.profile.platform == .nds,
            status: status,
            detail: "Preview-only matrix: \(summary.ready) ready, \(summary.warnings) warning, \(summary.errors) error, \(summary.notApplicable) not applicable.",
            readyCount: summary.ready,
            warningCount: summary.warnings,
            errorCount: summary.errors,
            notApplicableCount: summary.notApplicable,
            rows: rows,
            ndsGroups: report.profile.platform == .nds ? ndsHealthGroups(from: rows) : []
        )
    }

    private static func ndsHealthGroups(from rows: [BuildReportRow]) -> [NDSToolchainHealthGroupViewState] {
        let groups: [(id: String, title: String, detail: String, matches: (BuildReportRow) -> Bool)] = [
            (
                "build-sdks",
                "Build SDKs",
                "devkitPro, devkitARM, BlocksDS, build-system, and compiler prerequisites.",
                { row in
                    row.healthCategory == .externalTools && (
                        row.title.localizedCaseInsensitiveContains("devkit")
                            || row.title.localizedCaseInsensitiveContains("arm-none-eabi")
                            || row.title.localizedCaseInsensitiveContains("BlocksDS")
                            || row.title == "make"
                            || row.title == "meson"
                            || row.title == "ninja"
                            || row.title == "cmake"
                            || row.title == "grit"
                            || row.title == "mmutil"
                    )
                }
            ),
            (
                "packaging-inspection",
                "Packaging/Inspection",
                "NDS ROM/package inspection prerequisites such as ndstool.",
                { row in
                    row.healthCategory == .externalTools
                        && row.title.localizedCaseInsensitiveContains("ndstool")
                }
            ),
            (
                "python-ndspy",
                "Python/ndspy-compatible",
                "Python and ndspy-compatible inspection tooling.",
                { row in
                    row.healthCategory == .externalTools
                        && (row.title == "python3" || row.title.localizedCaseInsensitiveContains("ndspy"))
                }
            ),
            (
                "manual-emulators",
                "Manual Emulators",
                "melonDS and DeSmuME are detected for manual use only; the app does not launch them.",
                { row in
                    row.healthCategory == .externalTools
                        && (row.title.localizedCaseInsensitiveContains("melonDS") || row.title.localizedCaseInsensitiveContains("DeSmuME"))
                }
            ),
            (
                "reference-tools",
                "Reference Tools",
                "Read-only reference checkouts for clean-room orientation.",
                { row in
                    row.id.contains("reference")
                        || row.title.localizedCaseInsensitiveContains("DSPRE")
                        || row.title.localizedCaseInsensitiveContains("Tinke")
                }
            ),
            (
                "headers",
                "Headers",
                "NDS header facts and manual rerun guidance for missing declared ROM outputs.",
                { row in row.healthCategory == .romHeaders }
            ),
            (
                "declared-outputs",
                "Declared Outputs",
                "Declared NDS generated outputs and checksum artifacts.",
                { row in row.healthCategory == .generatedArtifacts }
            )
        ]

        return groups.compactMap { group in
            let groupRows = rows.filter(group.matches)
            guard !groupRows.isEmpty else { return nil }
            return NDSToolchainHealthGroupViewState(
                id: group.id,
                title: group.title,
                detail: group.detail,
                rows: groupRows
            )
        }
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

    private static func buildReportRowAction(
        from action: PokemonHackCore.ToolchainHealthAction
    ) -> BuildReportRowAction {
        let kind: BuildReportRowAction.Kind
        switch action.kind {
        case .copyCommand:
            kind = .copyCommand
        case .copyPath:
            kind = .copyPath
        case .rerunGuidance:
            kind = .rerunGuidance
        }
        return BuildReportRowAction(
            id: action.id,
            kind: kind,
            title: action.title,
            detail: action.detail,
            command: action.command,
            payload: action.payload
        )
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
                absolutePath: nil,
                detail: artifact.detail,
                exists: false,
                isPrimaryCaptureArtifact: false,
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

    private static func playtestDebugPlan(
        from plan: PokemonHackCore.PlaytestDebugPlan,
        rootPath: String
    ) -> PlaytestDebugPlanViewState {
        let diagnostics = plan.diagnostics.map { diagnostic(from: $0, rootPath: rootPath) }
        let status = validationStatus(
            for: diagnostics.map(\.severity)
                + plan.capabilities.map { validationState(for: $0.status) }
        )
        let romPath = plan.romCandidate?.relativePath ?? plan.romCandidate?.absolutePath
        let artifacts = plan.artifacts.map { artifact in
            PlaytestArtifactViewState(
                id: "debug:\(artifact.kind.rawValue):\(artifact.relativePath)",
                kind: artifact.kind.rawValue,
                path: artifact.relativePath,
                absolutePath: nil,
                detail: artifact.detail,
                exists: false,
                isPrimaryCaptureArtifact: false,
                source: SourceLocation(path: artifact.relativePath, symbol: artifact.kind.rawValue, line: 1)
            )
        }
        let capabilities = plan.capabilities.map { capability in
            PlaytestDebugCapabilityViewState(
                id: capability.id,
                toolName: capability.toolName,
                status: validationState(for: capability.status),
                statusLabel: capability.status.rawValue,
                resolvedPath: capability.resolvedPath,
                supportedActions: capability.supportedActions,
                command: capability.commandPreview.joined(separator: " "),
                detail: capability.detail,
                source: SourceLocation(path: capability.resolvedPath ?? rootPath, symbol: capability.toolName, line: 1)
            )
        }
        let detail = plan.isRunnable
            ? "Debugger/access-log handoff is ready to copy or inspect; launch remains disabled in this planning slice."
            : "Debugger/access-log handoff is planned only; review ROM and emulator readiness."
        return PlaytestDebugPlanViewState(
            id: "playtest-debug:\(rootPath)",
            status: status,
            detail: detail,
            command: plan.commandPreview.joined(separator: " "),
            isRunnable: plan.isRunnable,
            isLaunchEnabled: plan.isLaunchEnabled,
            artifacts: artifacts,
            capabilities: capabilities,
            diagnostics: diagnostics,
            source: SourceLocation(path: romPath ?? rootPath, symbol: plan.emulator.name, line: 1)
        )
    }

    private static func validationState(for status: PokemonHackCore.PlaytestDebugCapabilityStatus) -> ValidationState {
        switch status {
        case .ready:
            .valid
        case .warning:
            .warning
        case .notAvailable:
            .warning
        }
    }

    private static func playtestLaunchResult(
        from result: PokemonHackCore.PlaytestLaunchResult,
        rootPath: String,
        artifactRootPath: String
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
                absolutePath: artifactAbsolutePath(relativePath: artifact.relativePath, artifactRootPath: artifactRootPath),
                detail: artifact.exists ? "\(artifact.detail) Created." : artifact.detail,
                exists: artifact.exists,
                isPrimaryCaptureArtifact: false,
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

    private static func buildRunResult(
        from result: PokemonHackCore.DecompBuildResult,
        rootPath: String
    ) -> BuildRunResultViewState {
        let status: ValidationState
        switch result.status {
        case .succeeded:
            status = .valid
        case .blocked, .cancelled:
            status = .warning
        case .failed:
            status = .error
        }
        let outputDetail: String
        if let output = result.output {
            let checksum = output.sha1.map { "sha1 \($0.prefix(8))" } ?? "checksum unavailable"
            outputDetail = output.exists
                ? "\(output.relativePath) exists; \(checksum); checksum \(output.checksumStatus.rawValue); freshness \(output.freshnessStatus.rawValue)."
                : "\(output.relativePath) is still missing; checksum \(output.checksumStatus.rawValue); freshness \(output.freshnessStatus.rawValue)."
        } else {
            outputDetail = "No output artifact is declared for this target."
        }
        let diagnostics = result.diagnostics.map { diagnostic(from: $0, rootPath: rootPath) }
        let artifacts = result.artifacts.map { artifact in
            BuildRunArtifactViewState(
                id: artifact.id,
                kind: artifact.kind.rawValue,
                path: artifact.relativePath,
                absolutePath: artifact.absolutePath,
                detail: artifact.detail,
                exists: artifact.exists,
                source: SourceLocation(path: artifact.relativePath, symbol: artifact.kind.rawValue, line: 1)
            )
        }
        let command = result.command.joined(separator: " ")
        let sourcePath = result.output?.relativePath ?? rootPath
        return BuildRunResultViewState(
            id: "build-run:\(result.targetID ?? rootPath)",
            title: result.targetName ?? "Build run",
            status: status,
            statusLabel: result.status.rawValue,
            detail: result.diagnostics.last?.message ?? "Build \(result.status.rawValue).",
            command: command,
            processID: result.processID.map { "PID \($0)" } ?? result.status.rawValue,
            exitCode: result.exitCode.map { "Exit \($0)" } ?? "No exit code",
            outputPath: result.output?.relativePath,
            outputDetail: outputDetail,
            artifacts: artifacts,
            diagnostics: diagnostics,
            source: SourceLocation(path: sourcePath, symbol: command.isEmpty ? "Build" : command, line: 1)
        )
    }

    private static func playtestCaptureResult(
        from result: PokemonHackCore.PlaytestCaptureResult,
        rootPath: String,
        artifactRootPath: String
    ) -> PlaytestCaptureResultViewState {
        let status: ValidationState
        let detail: String
        switch result.status {
        case .launched:
            status = .valid
            detail = "mGBA \(result.captureKind.rawValue) capture launched with process \(result.processID.map(String.init) ?? "unknown")."
        case .blocked:
            status = .warning
            detail = result.diagnostics.last?.message ?? "mGBA capture is blocked by the current handoff report."
        case .failed:
            status = .error
            detail = result.diagnostics.last?.message ?? "mGBA capture failed."
        }

        let artifacts = result.artifacts.map { artifact in
            PlaytestArtifactViewState(
                id: "\(artifact.kind.rawValue):\(artifact.relativePath)",
                kind: artifact.kind.rawValue,
                path: artifact.relativePath,
                absolutePath: artifactAbsolutePath(relativePath: artifact.relativePath, artifactRootPath: artifactRootPath),
                detail: artifact.exists ? "\(artifact.detail) Created." : artifact.detail,
                exists: artifact.exists,
                isPrimaryCaptureArtifact: artifact.kind == primaryCaptureArtifactKind(for: result.captureKind),
                source: SourceLocation(path: artifact.relativePath, symbol: artifact.kind.rawValue, line: 1)
            )
        }
        let command = result.command.joined(separator: " ")
        let sourcePath = result.romPath ?? result.emulatorPath ?? rootPath

        return PlaytestCaptureResultViewState(
            id: "playtest-capture:\(rootPath)",
            title: result.captureKind == .screenshot ? "mGBA screenshot capture" : "mGBA savestate capture",
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

    private static func artifactAbsolutePath(relativePath: String, artifactRootPath: String) -> String {
        URL(fileURLWithPath: artifactRootPath).appendingPathComponent(relativePath).path
    }

    private static func primaryCaptureArtifactKind(
        for kind: PokemonHackCore.PlaytestCaptureKind
    ) -> PokemonHackCore.PlaytestSessionArtifactKind {
        switch kind {
        case .screenshot:
            return .screenshot
        case .saveState:
            return .saveState
        }
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
        rows.append(contentsOf: patchArtifactPlanRows(from: report.artifactPlan, patchSourcePath: patchSourcePath))
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

    private static func patchArtifactPlanRows(
        from plan: PokemonHackCore.PatchArtifactPlan,
        patchSourcePath: String
    ) -> [BuildReportRow] {
        let checksum = plan.checksumExpectations
        let baseSHA1 = checksum.baseROMSHA1.map { "base sha1 \($0.prefix(8))" } ?? "base sha1 unavailable"
        let expectedBase = checksum.expectedBaseROMSHA1.map { "expected \($0.prefix(8))" } ?? "expected base unknown"
        let targetSize = checksum.targetSizeBytes.map { "target size \($0) bytes" } ?? "target size unknown"
        let embedded = checksum.patchHasEmbeddedChecksums ? "embedded patch checksums" : "no embedded patch checksums"
        let launch = plan.mgbaLaunchPreview
        let launchCommand = launch.command.joined(separator: " ")
        let launchDetail = [
            launch.disabledReason ?? "Launch preview is disabled.",
            "Command preview: \(launchCommand)."
        ].joined(separator: " ")

        var rows = [
            BuildReportRow(
                id: "patch:artifact:output",
                section: .patchManifest,
                title: "Output artifact plan",
                subtitle: "\(plan.expectedPatchedROMName) · \(plan.patchFormat.rawValue.uppercased())",
                detail: "Preview-only output path \(plan.outputPath); apply/export writes remain disabled.",
                status: .warning,
                source: SourceLocation(path: plan.absoluteOutputPath, symbol: plan.expectedPatchedROMName, line: 1),
                tags: [plan.outputPath, plan.absoluteOutputPath, plan.patchFormat.rawValue, patchSourcePath]
            ),
            BuildReportRow(
                id: "patch:artifact:checksums",
                section: .patchManifest,
                title: "Checksum expectations",
                subtitle: "\(baseSHA1); \(expectedBase)",
                detail: "\(embedded); \(targetSize). \(checksum.policy)",
                status: checksum.baseROMSHA1 == nil ? .warning : .valid,
                source: SourceLocation(path: plan.selectedBaseROMPath ?? patchSourcePath, symbol: "checksums", line: 1),
                tags: [
                    checksum.baseROMSHA1 ?? "",
                    checksum.expectedBaseROMSHA1 ?? "",
                    checksum.matchedCandidateRelativePath ?? "",
                    checksum.policy
                ]
            ),
            BuildReportRow(
                id: "patch:artifact:header-policy",
                section: .patchManifest,
                title: "Header policy",
                subtitle: plan.headerPolicy.mode,
                detail: plan.headerPolicy.detail,
                status: plan.headerPolicy.shouldRewriteHeader ? .warning : .valid,
                source: SourceLocation(path: plan.selectedBaseROMPath ?? patchSourcePath, symbol: "rom-header", line: 1),
                tags: [plan.headerPolicy.mode, plan.headerPolicy.detail]
            ),
            BuildReportRow(
                id: "patch:artifact:mgba-preview",
                section: .patchManifest,
                title: "mGBA launch preview",
                subtitle: launch.isLaunchEnabled ? "Launch enabled" : "Launch disabled",
                detail: launchDetail,
                status: launch.isLaunchEnabled ? .valid : .warning,
                source: SourceLocation(path: launch.outputROMPath, symbol: launch.emulatorName, line: 1),
                tags: [launch.outputROMPath, launch.emulatorPath ?? "", launchCommand]
            )
        ]
        if let diff = plan.binaryDiffPreview {
            let blockedReasons = diff.applyExportState.reasons.joined(separator: " ")
            rows.append(
                BuildReportRow(
                    id: "patch:binary-diff:summary",
                    section: .patchManifest,
                    title: "Binary ROM diff preview",
                    subtitle: "\(diff.previewedChangeCount) change preview(s); \(diff.changedByteCount) byte(s)",
                    detail: "\(diff.patchFormat.rawValue.uppercased()) preview is read-only. \(blockedReasons)",
                    status: diff.changes.isEmpty ? .warning : .valid,
                    source: SourceLocation(path: diff.baseROMPath ?? patchSourcePath, symbol: "binary-diff", line: 1),
                    tags: [diff.patchFormat.rawValue, "\(diff.changedByteCount)", blockedReasons]
                )
            )
            rows.append(contentsOf: diff.changes.prefix(8).map { change in
                BuildReportRow(
                    id: "patch:binary-diff:change:\(change.id)",
                    section: .patchManifest,
                    title: String(format: "ROM bytes 0x%06X", change.offset),
                    subtitle: "\(change.kind.rawValue) · \(change.length) byte(s)",
                    detail: "\(change.detail) Original: \(change.originalPreviewHex ?? "unavailable"); patched: \(change.patchedPreviewHex ?? "unavailable").",
                    status: .valid,
                    source: SourceLocation(path: diff.baseROMPath ?? patchSourcePath, symbol: "byte-span", line: 1),
                    tags: [change.detail, change.originalPreviewHex ?? "", change.patchedPreviewHex ?? ""]
                )
            })
            rows.append(contentsOf: diff.freeSpaceSuitability.prefix(5).map { suitability in
                BuildReportRow(
                    id: "patch:binary-diff:free-space:\(suitability.id)",
                    section: .patchManifest,
                    title: String(format: "Free space 0x%06X", suitability.freeSpaceOffset),
                    subtitle: suitability.isSuitable ? "Suitable" : "Too small",
                    detail: suitability.detail,
                    status: suitability.isSuitable ? .valid : .warning,
                    source: SourceLocation(path: diff.baseROMPath ?? patchSourcePath, symbol: "free-space", line: 1),
                    tags: [suitability.detail]
                )
            })
            rows.append(contentsOf: diff.pointerRepointPlans.prefix(8).map { repoint in
                BuildReportRow(
                    id: "patch:binary-diff:repoint:\(repoint.id)",
                    section: .patchManifest,
                    title: String(format: "Pointer repoint 0x%06X", repoint.pointerSourceOffset),
                    subtitle: String(format: "0x%06X -> 0x%06X", repoint.oldTargetOffset, repoint.plannedTargetOffset),
                    detail: "\(repoint.detail) Planned raw value: \(String(format: "0x%08X", repoint.plannedRawValue)).",
                    status: .warning,
                    source: SourceLocation(path: diff.baseROMPath ?? patchSourcePath, symbol: "pointer-repoint", line: 1),
                    tags: [repoint.detail]
                )
            })
            rows.append(
                BuildReportRow(
                    id: "patch:binary-diff:manifest",
                    section: .patchManifest,
                    title: "Backup/export manifest",
                    subtitle: diff.backupExportManifest.patchedROMSHA1.map { "patched sha1 \($0.prefix(8))" } ?? "patched sha1 unavailable",
                    detail: "\(diff.backupExportManifest.detail) Backup: \(diff.backupExportManifest.backupPath ?? "not planned"); manifest: \(diff.backupExportManifest.manifestPath).",
                    status: .warning,
                    source: SourceLocation(path: diff.backupExportManifest.manifestPath, symbol: "export-manifest", line: 1),
                    tags: [
                        diff.backupExportManifest.outputPath,
                        diff.backupExportManifest.backupPath ?? "",
                        diff.backupExportManifest.manifestPath
                    ]
                )
            )
        }
        return rows
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
            tags: row.tags,
            actions: row.actions.map {
                BuildReportRowActionExportPayload(
                    kind: $0.kind.rawValue,
                    title: $0.title,
                    detail: $0.detail,
                    command: $0.command,
                    payload: $0.payload
                )
            }
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

    private static func surface(from document: SourceDocument, isReadOnlyProject: Bool = false) -> IndexedSourceSurface {
        let title = URL(fileURLWithPath: document.relativePath).lastPathComponent
        let displayTitle = title.isEmpty ? document.relativePath : title
        let role = document.role.rawValue
        let kind = document.kind.rawValue
        let subtitle = isReadOnlyProject && document.role == .source
            ? "\(kind) · \(role) · readOnly"
            : "\(kind) · \(role)"

        return IndexedSourceSurface(
            id: "\(role):\(document.relativePath)",
            title: displayTitle,
            subtitle: subtitle,
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
                isEditable: move.isEditable,
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

    private static func itemCatalog(
        from catalog: PokemonHackCore.ProjectItemCatalog,
        project: IndexedProjectSummary
    ) -> ItemCatalogViewState {
        let rootPath = project.rootPath
        let items = catalog.items.map { item in
            let diagnostics = item.diagnostics.map { diagnostic(from: $0, rootPath: rootPath) }
            let facts = itemFacts(item)
            let source = SourceLocation(path: item.sourceSpan.relativePath, symbol: item.itemID, line: item.sourceSpan.startLine)
            let searchBlob = (
                [
                    item.itemID,
                    item.displayName,
                    item.sourceSpan.relativePath,
                    item.sourcePreview ?? "",
                    item.descriptionSymbol ?? "",
                    item.descriptionText ?? ""
                ]
                + facts.flatMap { [$0.label, $0.value] }
                + diagnostics.flatMap { [$0.title, $0.message, $0.source.path] }
            )
            .joined(separator: " ")
            .lowercased()
            return ItemDetailViewState(
                id: item.itemID,
                itemID: item.itemID,
                displayName: item.displayName,
                status: validationStatus(for: diagnostics.map(\.severity)),
                facts: facts,
                source: source,
                sourcePreview: item.sourcePreview,
                isEditable: item.isEditable,
                isDescriptionEditable: item.isDescriptionEditable,
                descriptionText: item.descriptionText,
                diagnostics: diagnostics,
                searchBlob: searchBlob
            )
        }
        let diagnostics = catalog.diagnostics.map { diagnostic(from: $0, rootPath: rootPath) }
        return ItemCatalogViewState(
            id: "items:\(project.id)",
            projectTitle: project.title,
            rootPath: project.rootPath,
            profile: catalog.profile.rawValue,
            status: validationStatus(for: items.map(\.status) + diagnostics.map(\.severity)),
            itemCount: catalog.itemCount,
            editableCount: items.filter(\.isEditable).count,
            items: items.sorted { $0.itemID < $1.itemID },
            diagnostics: diagnostics
        )
    }

    private static func itemFacts(_ item: PokemonHackCore.ItemDetail) -> [Fact] {
        [
            ("Name", item.name),
            ("Price", item.price),
            ("Pocket", item.pocket),
            ("Type", item.type),
            ("Hold Effect", item.holdEffect),
            ("Hold Param", item.holdEffectParam),
            ("Battle Use", item.battleUsage),
            ("Field Func", item.fieldUseFunc),
            ("Battle Func", item.battleUseFunc),
            ("Secondary", item.secondaryId),
            ("Description", item.descriptionSymbol),
            ("Description Text", item.descriptionText),
            ("Editable", item.isEditable ? "Yes" : "No")
        ].compactMap { label, value in
            value.map { Fact(label: label, value: $0) }
        }
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
        canRunBuild: Bool,
        isBuildRunning: Bool,
        canLaunchPlaytest: Bool,
        includePatchActions: Bool
    ) -> [BuildWorkflowActionViewState] {
        var actions = [
            BuildWorkflowActionViewState(
                id: "build-rom",
                title: isBuildRunning ? "Building..." : "Build ROM",
                systemImage: "hammer",
                isEnabled: canRunBuild,
                isPreviewLocked: false
            ),
            BuildWorkflowActionViewState(
                id: "cancel-build",
                title: "Cancel Build",
                systemImage: "xmark.circle",
                isEnabled: isBuildRunning,
                isPreviewLocked: false
            ),
            BuildWorkflowActionViewState(
                id: "open-playtest",
                title: "Open Playtest",
                systemImage: "play.fill",
                isEnabled: canLaunchPlaytest,
                isPreviewLocked: false
            ),
            BuildWorkflowActionViewState(
                id: "capture-screenshot",
                title: "Capture Screenshot",
                systemImage: "camera",
                isEnabled: canLaunchPlaytest,
                isPreviewLocked: false
            ),
            BuildWorkflowActionViewState(
                id: "capture-savestate",
                title: "Capture Savestate",
                systemImage: "memories",
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
