import Foundation
import PokemonHackCore

enum WorkbenchModuleGroup: String, CaseIterable, Identifiable, Hashable {
    case workspace = "Workspace"
    case create = "Create"
    case dataAssets = "Data & Assets"
    case ship = "Ship"

    var id: String { rawValue }

    var modules: [WorkbenchModule] {
        switch self {
        case .workspace:
            [.dashboard]
        case .create:
            [.maps, .pokemon, .trainers, .scripts]
        case .dataAssets:
            [.resources, .graphics, .items, .encounters, .text]
        case .ship:
            [.build, .issues]
        }
    }
}

enum WorkbenchModule: String, CaseIterable, Identifiable, Hashable {
    case dashboard = "Project"
    case resources = "Resources"
    case maps = "Maps"
    case pokemon = "Pokemon"
    case trainers = "Trainers"
    case items = "Items"
    case encounters = "Encounters"
    case scripts = "Scripts"
    case text = "Text"
    case graphics = "Graphics"
    case build = "Build/Patch/Playtest"
    case issues = "Diagnostics"

    var id: String { rawValue }

    var title: String { rawValue }

    var group: WorkbenchModuleGroup {
        switch self {
        case .dashboard:
            .workspace
        case .maps, .pokemon, .trainers, .scripts:
            .create
        case .resources, .graphics, .items, .encounters, .text:
            .dataAssets
        case .build:
            .ship
        case .issues:
            .ship
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .resources: "externaldrive.connected.to.line.below"
        case .maps: "map"
        case .pokemon: "sparkles"
        case .trainers: "person.2"
        case .items: "shippingbox"
        case .encounters: "leaf"
        case .scripts: "curlybraces"
        case .text: "text.quote"
        case .graphics: "photo.on.rectangle"
        case .build: "hammer"
        case .issues: "exclamationmark.triangle"
        }
    }

    var subtitle: String {
        switch self {
        case .dashboard: "Guided project hub"
        case .resources: "Assets and source links"
        case .maps: "Maps, events, warps"
        case .pokemon: "Stats and learnsets"
        case .trainers: "Parties and battle setup"
        case .items: "Items and field data"
        case .encounters: "Wild encounter tables"
        case .scripts: "Event script readiness"
        case .text: "Message sources"
        case .graphics: "Tilesets and palettes"
        case .build: "Readiness, patch, playtest"
        case .issues: "Grouped triage"
        }
    }
}

enum MapWorkbenchTab: String, CaseIterable, Identifiable, Hashable {
    case overviewLayers
    case paintCollision
    case eventsScripts
    case mapData

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overviewLayers: "Overview/Layers"
        case .paintCollision: "Paint/Collision"
        case .eventsScripts: "Events/Scripts"
        case .mapData: "Map Data"
        }
    }

    var systemImage: String {
        switch self {
        case .overviewLayers: "square.stack.3d.up"
        case .paintCollision: "paintbrush.pointed"
        case .eventsScripts: "point.3.connected.trianglepath.dotted"
        case .mapData: "doc.text.magnifyingglass"
        }
    }

    var accessibilityLabel: String {
        "\(title) editor tab"
    }
}

enum BuildWorkbenchTab: String, CaseIterable, Identifiable, Hashable {
    case build
    case patch
    case playtest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .build: "Build Readiness"
        case .patch: "Patch Check"
        case .playtest: "Playtest Handoff"
        }
    }

    var systemImage: String {
        switch self {
        case .build: "hammer"
        case .patch: "doc.badge.gearshape"
        case .playtest: "gamecontroller"
        }
    }
}

enum ResourceLibraryMode: String, CaseIterable, Identifiable, Hashable {
    case assets
    case entries

    var id: String { rawValue }

    var title: String {
        switch self {
        case .assets:
            "Assets"
        case .entries:
            "Entries"
        }
    }

    var systemImage: String {
        switch self {
        case .assets:
            "square.grid.3x3"
        case .entries:
            "externaldrive.connected.to.line.below"
        }
    }
}

enum WorkbenchSidebarSelection: Hashable {
    case resourceAsset(ResourceAssetRowViewState.ID)
    case resourceEntry(ResourceLibraryEntryViewState.ID)
    case map(String)
    case pokemon(String)
    case trainer(String)
    case scriptSource(String)
    case scriptLabel(String)
    case scriptTextBlock(String)
    case record(WorkbenchModule, UUID)
    case graphics(String)
    case build(String)
    case diagnostic(String)
    case diagnosticBucket(DiagnosticSummaryBucket)
    case guidedFlow(String)
}

enum ValidationState: String, Identifiable {
    case valid = "Valid"
    case warning = "Warning"
    case error = "Error"

    var id: String { rawValue }
}

enum ScriptReadinessTargetMode: String, CaseIterable, Identifiable {
    case map = "Map"
    case script = "Script"

    var id: String { rawValue }
}

struct SourceLocation: Identifiable {
    let id = UUID()
    let path: String
    let symbol: String
    let line: Int

    var label: String {
        "\(path):\(line)"
    }
}

struct WorkbenchRecord: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let module: WorkbenchModule
    let source: SourceLocation
    let validation: ValidationState
    let isDirty: Bool
    let tags: [String]
    let facts: [Fact]
    let notes: [String]
    let preview: String?

    init(
        title: String,
        subtitle: String,
        module: WorkbenchModule,
        source: SourceLocation,
        validation: ValidationState,
        isDirty: Bool,
        tags: [String],
        facts: [Fact],
        notes: [String],
        preview: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.module = module
        self.source = source
        self.validation = validation
        self.isDirty = isDirty
        self.tags = tags
        self.facts = facts
        self.notes = notes
        self.preview = preview
    }
}

struct Fact: Identifiable {
    let id = UUID()
    let label: String
    let value: String
}

struct BuildTarget: Identifiable, Hashable {
    let id: String
    let name: String
    let romBase: String
}

struct WorkbenchIssue: Identifiable {
    let id = UUID()
    let title: String
    let severity: ValidationState
    let source: SourceLocation
    let message: String
}

struct BuildStep: Identifiable {
    let id = UUID()
    let name: String
    let status: ValidationState
    let detail: String
    let source: SourceLocation
}

struct BuildWorkflowActionViewState: Identifiable, Equatable {
    let id: String
    let title: String
    let systemImage: String
    let isEnabled: Bool
    let isPreviewLocked: Bool
}

enum BuildReportSection: String, CaseIterable, Identifiable {
    case buildTargets = "Build Targets"
    case generatedArtifacts = "Generated Artifacts"
    case toolchain = "Toolchain Readiness"
    case healthMatrix = "Toolchain Health Matrix"
    case patchManifest = "Patch Manifest"
    case playtest = "Playtest Handoff"
    case diagnostics = "Diagnostics"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .buildTargets:
            "hammer"
        case .generatedArtifacts:
            "archivebox"
        case .toolchain:
            "wrench.and.screwdriver"
        case .healthMatrix:
            "checklist"
        case .patchManifest:
            "doc.badge.gearshape"
        case .playtest:
            "gamecontroller"
        case .diagnostics:
            "exclamationmark.triangle"
        }
    }
}

struct BuildPatchPlaytestReportViewState: Identifiable {
    let id: String
    let projectTitle: String
    let rootPath: String
    let profile: String
    let status: ValidationState
    let buildTargets: [BuildTargetValidationViewState]
    let generatedArtifacts: [GeneratedArtifactValidationViewState]
    let toolchain: ToolchainReadinessViewState
    let healthMatrix: ToolchainHealthMatrixViewState
    let playtest: PlaytestHandoffPlanViewState
    let baseROMOptions: [BaseROMOptionViewState]
    let diagnostics: [IndexedDiagnosticRow]

    var rows: [BuildReportRow] {
        buildTargets.map(BuildReportRow.init(target:))
            + generatedArtifacts.map(BuildReportRow.init(artifact:))
            + toolchain.rows
            + healthMatrix.rows
            + [BuildReportRow(playtest: playtest)]
            + diagnostics.map(BuildReportRow.init(diagnostic:))
    }
}

enum PatchManifestLoadStatus: Equatable {
    case idle
    case loading
    case loaded(String)
    case failed(String)

    var label: String {
        switch self {
        case .idle:
            "No patch manifest loaded"
        case .loading:
            "Loading patch manifest"
        case .loaded(let status):
            "Patch manifest loaded: \(status)"
        case .failed(let message):
            "Patch manifest failed: \(message)"
        }
    }

    var validationState: ValidationState {
        switch self {
        case .failed:
            .warning
        case .idle, .loading, .loaded:
            .valid
        }
    }
}

struct BaseROMOptionViewState: Identifiable, Hashable {
    let id: String
    let title: String
    let path: String
    let subtitle: String
    let detail: String
    let status: ValidationState
    let sourceKind: String
    let sha1Summary: String
}

struct PatchManifestReportViewState: Identifiable {
    let id: String
    let patchPath: String
    let patchTitle: String
    let patchSubtitle: String
    let patchDetail: String
    let compatibilityLabel: String
    let status: ValidationState
    let selectedBaseROM: PatchSelectedBaseROMViewState?
    let baseROMCandidates: [PatchBaseROMCandidateViewState]
    let dryRunPlans: [PatchDryRunPlanViewState]
    let diagnostics: [IndexedDiagnosticRow]
    let rows: [BuildReportRow]
}

struct PatchSelectedBaseROMViewState: Identifiable {
    let id: String
    let title: String
    let path: String
    let detail: String
    let status: ValidationState
    let sha1Summary: String
    let matchedCandidate: String?
}

struct PatchBaseROMCandidateViewState: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let detail: String
    let status: ValidationState
    let sha1Summary: String
    let source: SourceLocation
}

struct PatchDryRunPlanViewState: Identifiable {
    let id: String
    let title: String
    let steps: [String]
    let diagnostics: [IndexedDiagnosticRow]
    let status: ValidationState
}

struct ToolchainHealthMatrixViewState: Identifiable {
    let id: String
    let status: ValidationState
    let detail: String
    let readyCount: Int
    let warningCount: Int
    let errorCount: Int
    let notApplicableCount: Int
    let rows: [BuildReportRow]
}

struct BuildTargetValidationViewState: Identifiable {
    let id: String
    let name: String
    let kind: String
    let command: String
    let outputPath: String?
    let status: ValidationState
    let detail: String
    let source: SourceLocation
}

struct GeneratedArtifactValidationViewState: Identifiable {
    let id: String
    let title: String
    let path: String
    let role: String
    let exists: Bool
    let checksumSummary: String
    let freshnessSummary: String
    let status: ValidationState
    let source: SourceLocation
}

struct ToolchainReadinessViewState: Identifiable {
    let id: String
    let status: ValidationState
    let detail: String
    let rows: [BuildReportRow]
}

struct PlaytestHandoffPlanViewState: Identifiable {
    let id: String
    let emulator: String
    let romPath: String?
    let arguments: [String]
    let artifacts: [PlaytestArtifactViewState]
    let isRunnable: Bool
    let status: ValidationState
    let detail: String
    let source: SourceLocation
}

struct PlaytestLaunchResultViewState: Identifiable {
    let id: String
    let status: ValidationState
    let statusLabel: String
    let detail: String
    let emulatorPath: String?
    let romPath: String?
    let command: String
    let processID: String
    let artifacts: [PlaytestArtifactViewState]
    let source: SourceLocation
}

struct PlaytestArtifactViewState: Identifiable {
    let id: String
    let kind: String
    let path: String
    let detail: String
    let source: SourceLocation
}

struct BuildReportRow: Identifiable {
    let id: String
    let section: BuildReportSection
    let title: String
    let subtitle: String
    let detail: String
    let status: ValidationState
    let source: SourceLocation
    let tags: [String]
    let healthCategory: WorkbenchHealthCheckCategory?
    let healthStatus: WorkbenchHealthCheckStatus?

    init(
        id: String,
        section: BuildReportSection,
        title: String,
        subtitle: String,
        detail: String,
        status: ValidationState,
        source: SourceLocation,
        tags: [String] = [],
        healthCategory: WorkbenchHealthCheckCategory? = nil,
        healthStatus: WorkbenchHealthCheckStatus? = nil
    ) {
        self.id = id
        self.section = section
        self.title = title
        self.subtitle = subtitle
        self.detail = detail
        self.status = status
        self.source = source
        self.tags = tags
        self.healthCategory = healthCategory
        self.healthStatus = healthStatus
    }

    init(target: BuildTargetValidationViewState) {
        self.init(
            id: "target:\(target.id)",
            section: .buildTargets,
            title: target.name,
            subtitle: target.kind,
            detail: target.detail,
            status: target.status,
            source: target.source,
            tags: [target.kind, target.command, target.outputPath ?? ""]
        )
    }

    init(artifact: GeneratedArtifactValidationViewState) {
        self.init(
            id: "artifact:\(artifact.id)",
            section: .generatedArtifacts,
            title: artifact.title,
            subtitle: artifact.role,
            detail: "\(artifact.freshnessSummary) \(artifact.checksumSummary)",
            status: artifact.status,
            source: artifact.source,
            tags: [artifact.path, artifact.role]
        )
    }

    init(playtest: PlaytestHandoffPlanViewState) {
        self.init(
            id: "playtest:\(playtest.id)",
            section: .playtest,
            title: "\(playtest.emulator) handoff",
            subtitle: playtest.romPath ?? "No ROM output selected",
            detail: playtest.detail,
            status: playtest.status,
            source: playtest.source,
            tags: [playtest.emulator] + playtest.arguments
        )
    }

    init(launchResult: PlaytestLaunchResultViewState) {
        self.init(
            id: "playtest-launch:\(launchResult.id)",
            section: .playtest,
            title: "mGBA launch",
            subtitle: launchResult.processID,
            detail: launchResult.detail,
            status: launchResult.status,
            source: launchResult.source,
            tags: [launchResult.statusLabel, launchResult.command, launchResult.romPath ?? ""]
        )
    }

    init(diagnostic: IndexedDiagnosticRow) {
        self.init(
            id: "diagnostic:\(diagnostic.id)",
            section: .diagnostics,
            title: diagnostic.title,
            subtitle: diagnostic.source.path,
            detail: diagnostic.message,
            status: diagnostic.severity,
            source: diagnostic.source,
            tags: [diagnostic.title, diagnostic.message]
        )
    }
}

enum ScriptReadinessReportSection: String, CaseIterable, Identifiable {
    case source = "Source"
    case build = "Build"
    case playtest = "Playtest"
    case workflow = "Workflow"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .source:
            "curlybraces"
        case .build:
            "hammer"
        case .playtest:
            "gamecontroller"
        case .workflow:
            "lock.doc"
        }
    }
}

struct ScriptReadinessReportViewState: Identifiable {
    let id: String
    let projectTitle: String
    let rootPath: String
    let profile: String
    let targetMode: ScriptReadinessTargetMode
    let targetTitle: String
    let status: ValidationState
    let isReady: Bool
    let isReadOnly: Bool
    let mapContext: ScriptReadinessMapContextViewState?
    let scriptContext: ScriptReadinessScriptContextViewState?
    let rows: [ScriptReadinessReportRow]
    let diagnostics: [IndexedDiagnosticRow]
}

struct ScriptReadinessMapContextViewState {
    let mapID: String
    let mapName: String
    let sourcePath: String
    let layoutID: String?
    let scriptSourceCount: Int
    let eventScriptCount: Int
}

struct ScriptReadinessScriptContextViewState {
    let label: String
    let kind: String
    let sourcePath: String
    let sourceRole: String
    let commandCount: Int
    let textReferenceCount: Int
}

struct ScriptReadinessReportRow: Identifiable {
    let id: String
    let section: ScriptReadinessReportSection
    let title: String
    let subtitle: String
    let detail: String
    let status: ValidationState
    let source: SourceLocation
    let tags: [String]
}

enum GraphicsReportSection: String, CaseIterable, Identifiable {
    case tilesets = "Tilesets"
    case artifacts = "Artifacts"
    case palettes = "Palettes"
    case animations = "Animations"
    case conversionPlans = "Conversion Plans"
    case diagnostics = "Diagnostics"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .tilesets:
            "square.grid.3x3"
        case .artifacts:
            "photo.stack"
        case .palettes:
            "paintpalette"
        case .animations:
            "film.stack"
        case .conversionPlans:
            "wand.and.stars"
        case .diagnostics:
            "exclamationmark.triangle"
        }
    }
}

struct GraphicsDiagnosticsReportViewState: Identifiable {
    let id: String
    let projectTitle: String
    let rootPath: String
    let profile: String
    let status: ValidationState
    let tilesetCount: Int
    let tileImageCount: Int
    let paletteFileCount: Int
    let animationDirectoryCount: Int
    let unsupportedSourceArtifactCount: Int
    let readOnlyDetail: String
    let rows: [GraphicsReportRow]
    let diagnostics: [IndexedDiagnosticRow]
}

struct GraphicsReportRow: Identifiable {
    let id: String
    let section: GraphicsReportSection
    let title: String
    let subtitle: String
    let detail: String
    let status: ValidationState
    let source: SourceLocation
    let tags: [String]
}

enum ProjectIndexLoadStatus: Equatable {
    case idle
    case loading
    case loaded(Int)
    case failed(String)

    var label: String {
        switch self {
        case .idle:
            "No project index loaded"
        case .loading:
            "Loading project indexes"
        case .loaded(let count):
            count == 1 ? "1 project indexed" : "\(count) projects indexed"
        case .failed(let message):
            "Index failed: \(message)"
        }
    }

    var validationState: ValidationState {
        switch self {
        case .failed:
            .error
        case .loaded(0):
            .warning
        default:
            .valid
        }
    }
}

struct IndexedProjectSummary: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let rootPath: String
    let originLabel: String
    let menuTitle: String
    let menuSubtitle: String
    let profile: String
    let adapterName: String
    let writePolicy: String
    let status: ValidationState
    let sourceDocumentCount: Int
    let existingSourceDocumentCount: Int
    let missingSourceDocumentCount: Int
    let generatedOutputCount: Int
    let artifactCount: Int
    let diagnosticCount: Int
    let buildTargetCount: Int
    let sourceSurfaces: [IndexedSourceSurface]
    let generatedOutputs: [IndexedSourceSurface]
    let diagnostics: [IndexedDiagnosticRow]
    let buildTargets: [IndexedBuildTargetPreview]
}

struct IndexedSourceSurface: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let kind: String
    let role: String
    let exists: Bool
    let preservesUnknownFields: Bool
    let validation: ValidationState
    let source: SourceLocation
}

struct IndexedDiagnosticRow: Identifiable {
    let id: String
    let title: String
    let message: String
    let severity: ValidationState
    let source: SourceLocation
}

struct IndexedBuildTargetPreview: Identifiable {
    let id: String
    let name: String
    let kind: String
    let command: String
    let outputPath: String?
}

struct ResourceLibraryViewState: Identifiable {
    let id: String
    let workspaceRoot: String
    let entries: [ResourceLibraryEntryViewState]
    let diagnostics: [IndexedDiagnosticRow]

    var entryCount: Int { entries.count }
    var parsedCount: Int { entries.filter { $0.status == .valid }.count }
    var missingCount: Int { entries.filter { $0.parseStatus == "missing" }.count }
    var itemCount: Int { entries.reduce(0) { $0 + $1.items.count } }
    var allDiagnostics: [IndexedDiagnosticRow] { diagnostics + entries.flatMap(\.diagnostics) }
}

struct ResourceAssetCatalogViewState: Identifiable {
    let id: String
    let projectTitle: String
    let rootPath: String
    let profile: String
    let assetCount: Int
    let categoryCounts: [ResourceAssetCategoryCount]
    let availabilityCounts: [ResourceAssetAvailabilityCount]
    let rows: [ResourceAssetRowViewState]
    let diagnostics: [IndexedDiagnosticRow]

    var categoryTitles: [String] {
        categoryCounts.map(\.category)
    }
}

struct ResourceAssetCategoryCount: Identifiable {
    var id: String { category }

    let category: String
    let count: Int
}

struct ResourceAssetAvailabilityCount: Identifiable {
    var id: String { availability }

    let availability: String
    let count: Int
}

enum ResourceAssetCatalogLoadStatus: Equatable {
    case idle
    case loading
    case loaded(Int)
    case failed(String)

    var label: String {
        switch self {
        case .idle:
            "Asset catalog not loaded"
        case .loading:
            "Loading assets"
        case .loaded(let count):
            count == 1 ? "1 asset loaded" : "\(count) assets loaded"
        case .failed(let message):
            "Asset catalog failed: \(message)"
        }
    }

    var validationState: ValidationState {
        switch self {
        case .failed:
            .warning
        case .idle, .loading, .loaded:
            .valid
        }
    }
}

enum SpeciesCatalogLoadStatus: Equatable {
    case idle
    case loading
    case loaded(Int)
    case failed(String)

    var label: String {
        switch self {
        case .idle:
            "Pokemon catalog not loaded"
        case .loading:
            "Loading Pokemon catalog"
        case .loaded(let count):
            count == 1 ? "1 species loaded" : "\(count) species loaded"
        case .failed(let message):
            "Pokemon catalog failed: \(message)"
        }
    }

    var validationState: ValidationState {
        switch self {
        case .failed:
            .warning
        case .idle, .loading, .loaded:
            .valid
        }
    }
}

enum TrainerCatalogLoadStatus: Equatable {
    case idle
    case loading
    case loaded(Int)
    case failed(String)

    var label: String {
        switch self {
        case .idle:
            "Trainer catalog not loaded"
        case .loading:
            "Loading trainer catalog"
        case .loaded(let count):
            count == 1 ? "1 trainer loaded" : "\(count) trainers loaded"
        case .failed(let message):
            "Trainer catalog failed: \(message)"
        }
    }

    var validationState: ValidationState {
        switch self {
        case .failed:
            .warning
        case .idle, .loading, .loaded:
            .valid
        }
    }
}

enum ResourceAssetSortMode: String, CaseIterable, Identifiable {
    case category
    case title
    case path
    case status
    case availability

    var id: String { rawValue }

    var title: String {
        switch self {
        case .category:
            "Category"
        case .title:
            "Title"
        case .path:
            "Path"
        case .status:
            "Status"
        case .availability:
            "Availability"
        }
    }
}

struct ResourceAssetRowViewState: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let path: String
    let category: String
    let kind: String
    let role: String
    let status: ValidationState
    let availability: String
    let availabilitySummary: String
    let affectsResourceAvailability: Bool
    let sizeSummary: String
    let checksumSummary: String
    let source: SourceLocation
    let tags: [String]
    let facts: [Fact]
    let diagnostics: [IndexedDiagnosticRow]
    let targetModule: WorkbenchModule?
    let targetID: String?
    let searchBlob: String
}

struct ResourceLibraryEntryViewState: Identifiable {
    let id: String
    let title: String
    let path: String
    let platform: String
    let family: String
    let profile: String
    let role: String
    let writePolicy: String
    let parseStatus: String
    let status: ValidationState
    let variantSummary: String
    let moduleSummary: String
    let resourceCount: Int
    let diagnosticCount: Int
    let items: [ResourceLibraryItemViewState]
    let diagnostics: [IndexedDiagnosticRow]
    let source: SourceLocation
}

struct ResourceLibraryItemViewState: Identifiable {
    let id: String
    let title: String
    let path: String
    let kind: String
    let category: String
    let locationSummary: String
    let sizeSummary: String
    let checksumSummary: String
    let source: SourceLocation
    let tags: [String]
}

enum MapCatalogLoadStatus: Equatable {
    case idle
    case loading
    case loaded(Int)
    case failed(String)

    var label: String {
        switch self {
        case .idle:
            "No map catalog loaded"
        case .loading:
            "Loading map catalog"
        case .loaded(let count):
            count == 1 ? "1 map indexed" : "\(count) maps indexed"
        case .failed(let message):
            "Map catalog failed: \(message)"
        }
    }
}

struct MapCatalogViewState: Identifiable {
    let id: String
    let projectTitle: String
    let rootPath: String
    let groupCount: Int
    let mapCount: Int
    let layoutCount: Int
    let diagnostics: [IndexedDiagnosticRow]
    let groups: [MapGroupViewState]
    let maps: [MapSummaryViewState]
}

struct MapGroupViewState: Identifiable {
    let id: String
    let name: String
    let mapCount: Int
    let mapIDs: [String]
}

struct MapSummaryViewState: Identifiable {
    let id: String
    let mapID: String
    let name: String
    let groupName: String
    let source: SourceLocation
    let layout: MapLayoutViewState?
    let music: String?
    let mapType: String?
    let weather: String?
    let regionMapSection: String?
    let eventCounts: MapEventCountViewState
    let connections: [MapConnectionViewState]
    let notes: [String]
}

struct MapLayoutViewState: Identifiable {
    let id: String
    let name: String
    let width: Int
    let height: Int
    let primaryTileset: String?
    let secondaryTileset: String?
    let borderFilepath: String?
    let blockdataFilepath: String?
    let blockPreview: LayoutBlockPreviewViewState?
}

struct MapEventCountViewState: Equatable {
    let objectEvents: Int
    let warpEvents: Int
    let coordEvents: Int
    let bgEvents: Int

    var total: Int {
        objectEvents + warpEvents + coordEvents + bgEvents
    }
}

struct MapConnectionViewState: Identifiable {
    let id: String
    let direction: String
    let map: String
    let offset: Int
}

struct LayoutBlockPreviewViewState: Equatable {
    let width: Int
    let height: Int
    let visibleWidth: Int
    let visibleHeight: Int
    let metatileIDs: [Int]
    let isComplete: Bool
    let diagnostic: String?
}

enum MapVisualLoadStatus: Equatable {
    case idle
    case loading
    case loaded(String)
    case failed(String)

    var label: String {
        switch self {
        case .idle:
            "No visual map loaded"
        case .loading:
            "Loading visual map"
        case .loaded(let mapName):
            "Loaded \(mapName)"
        case .failed(let message):
            "Visual map failed: \(message)"
        }
    }
}

enum MapEditorToolGroup: String, CaseIterable, Identifiable {
    case navigation
    case paint
    case events

    var id: String { rawValue }

    var title: String {
        switch self {
        case .navigation: "Navigation"
        case .paint: "Paint"
        case .events: "Events"
        }
    }
}

enum MapEditorTool: String, CaseIterable, Identifiable {
    case select
    case hand
    case eyedropper
    case pencil
    case rectangleFill
    case eventMove
    case addEvent
    case duplicate
    case delete

    var id: String { rawValue }

    var title: String {
        switch self {
        case .select: "Select"
        case .hand: "Pan"
        case .eyedropper: "Pick"
        case .pencil: "Paint"
        case .rectangleFill: "Fill"
        case .eventMove: "Move Event"
        case .addEvent: "Add Event"
        case .duplicate: "Duplicate"
        case .delete: "Delete"
        }
    }

    var shortTitle: String {
        switch self {
        case .select: "Select"
        case .hand: "Pan"
        case .eyedropper: "Pick"
        case .pencil: "Paint"
        case .rectangleFill: "Fill"
        case .eventMove: "Move"
        case .addEvent: "Add"
        case .duplicate: "Copy"
        case .delete: "Delete"
        }
    }

    var group: MapEditorToolGroup {
        switch self {
        case .select, .hand:
            .navigation
        case .eyedropper, .pencil, .rectangleFill:
            .paint
        case .eventMove, .addEvent, .duplicate, .delete:
            .events
        }
    }

    var systemImage: String {
        switch self {
        case .select: "cursorarrow"
        case .hand: "hand.draw"
        case .eyedropper: "eyedropper"
        case .pencil: "pencil.tip"
        case .rectangleFill: "rectangle.fill.on.rectangle.fill"
        case .eventMove: "point.3.connected.trianglepath.dotted"
        case .addEvent: "plus.circle"
        case .duplicate: "plus.square.on.square"
        case .delete: "trash"
        }
    }

    var accessibilityLabel: String {
        "\(title) map editor tool"
    }

    var helpText: String {
        switch self {
        case .select:
            "Select map cells or events"
        case .hand:
            "Pan the map canvas"
        case .eyedropper:
            "Pick a metatile from the canvas"
        case .pencil:
            "Paint the selected metatile"
        case .rectangleFill:
            "Fill a rectangular map area"
        case .eventMove:
            "Move the selected map event"
        case .addEvent:
            "Add an event using the selected event template"
        case .duplicate:
            "Duplicate the selected event"
        case .delete:
            "Delete the selected event"
        }
    }

    static func tools(in group: MapEditorToolGroup) -> [MapEditorTool] {
        allCases.filter { $0.group == group }
    }
}

struct MapCellSelection: Equatable {
    let x: Int
    let y: Int
    let rawValue: UInt16

    var metatileID: Int {
        Int(rawValue & 0x03ff)
    }
}

enum PendingMapNavigation: Identifiable, Equatable {
    case project(String)
    case map(String)

    var id: String {
        switch self {
        case .project(let id):
            "project:\(id)"
        case .map(let id):
            "map:\(id)"
        }
    }

    var title: String {
        switch self {
        case .project:
            "Switch project?"
        case .map:
            "Switch map?"
        }
    }

    var message: String {
        "This map has staged edits. Preview or discard them before changing selection."
    }
}
