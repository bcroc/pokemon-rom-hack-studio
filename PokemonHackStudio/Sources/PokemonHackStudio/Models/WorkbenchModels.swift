import Foundation
import CoreGraphics
import PokemonHackCore

struct MapCanvasViewportRequest: Equatable, Identifiable {
    let id: String
    let centerX: CGFloat
    let centerY: CGFloat

    init(id: String = UUID().uuidString, centerX: CGFloat, centerY: CGFloat) {
        self.id = id
        self.centerX = centerX
        self.centerY = centerY
    }
}

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
            [.resources, .graphics, .moves, .items, .encounters, .text]
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
    case moves = "Moves"
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
        case .resources, .graphics, .moves, .items, .encounters, .text:
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
        case .moves: "bolt"
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
        case .moves: "Battle moves and learnability"
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
    case workflow

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overviewLayers: "Overview/Layers"
        case .paintCollision: "Paint/Collision"
        case .eventsScripts: "Events/Scripts"
        case .mapData: "Map Data"
        case .workflow: "Workflow"
        }
    }

    var systemImage: String {
        switch self {
        case .overviewLayers: "square.stack.3d.up"
        case .paintCollision: "paintbrush.pointed"
        case .eventsScripts: "point.3.connected.trianglepath.dotted"
        case .mapData: "doc.text.magnifyingglass"
        case .workflow: "arrow.triangle.branch"
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

enum WorkbenchSearchBehavior: Equatable {
    case preserve
    case restoreModule
    case replace(String)
    case replaceTargetIdentifier
    case clear
}

enum WorkbenchFocusTarget: Hashable, Identifiable {
    case map(String)
    case species(String)
    case trainer(String)
    case move(String)
    case item(String)
    case resourceAsset(String)
    case resourceEntry(String)
    case scriptLabel(String)
    case buildRow(String)
    case diagnostic(String)

    var id: String {
        "\(module.id)::\(rawIdentifier)"
    }

    var module: WorkbenchModule {
        switch self {
        case .map:
            .maps
        case .species:
            .pokemon
        case .trainer:
            .trainers
        case .move:
            .moves
        case .item:
            .items
        case .resourceAsset, .resourceEntry:
            .resources
        case .scriptLabel:
            .scripts
        case .buildRow:
            .build
        case .diagnostic:
            .issues
        }
    }

    var rawIdentifier: String {
        switch self {
        case .map(let id),
             .species(let id),
             .trainer(let id),
             .move(let id),
             .item(let id),
             .resourceAsset(let id),
             .resourceEntry(let id),
             .scriptLabel(let id),
             .buildRow(let id),
             .diagnostic(let id):
            id
        }
    }
}

struct WorkbenchRecentTarget: Identifiable, Hashable {
    let target: WorkbenchFocusTarget
    let module: WorkbenchModule
    let title: String
    let subtitle: String
    let systemImage: String

    var id: String {
        "\(module.id)::\(target.rawIdentifier)"
    }
}

enum ValidationState: String, Identifiable {
    case valid = "Valid"
    case warning = "Warning"
    case error = "Error"

    var id: String { rawValue }
}

enum ProjectIdentityKind: String, Identifiable {
    case editableSource
    case bundledFallback
    case reference
    case romInput
    case localSourceReadOnly
    case fixtureDev

    var id: String { rawValue }

    var title: String {
        switch self {
        case .editableSource:
            "Editable Project"
        case .bundledFallback:
            "Bundled Fallback"
        case .reference:
            "Reference Source"
        case .romInput:
            "ROM Input"
        case .localSourceReadOnly:
            "Read-Only Source"
        case .fixtureDev:
            "Demo Fixture"
        }
    }

    var systemImage: String {
        switch self {
        case .editableSource:
            "folder.badge.gearshape"
        case .bundledFallback:
            "shippingbox"
        case .reference:
            "books.vertical"
        case .romInput:
            "opticaldiscdrive"
        case .localSourceReadOnly:
            "folder.badge.questionmark"
        case .fixtureDev:
            "testtube.2"
        }
    }
}

struct ProjectWritePolicy: Equatable, Identifiable {
    let kind: ProjectIdentityKind
    let title: String
    let detail: String
    let isWritable: Bool

    var id: String { "\(kind.rawValue)::\(title)" }

    static func policy(originLabel: String, rawWritePolicy: String) -> ProjectWritePolicy {
        switch originLabel {
        case "Editable":
            if rawWritePolicy.caseInsensitiveCompare("editable") == .orderedSame {
                return ProjectWritePolicy(
                    kind: .editableSource,
                    title: "Editable source",
                    detail: "Source-tree writes require preview, explicit apply, and backups.",
                    isWritable: true
                )
            }
            return ProjectWritePolicy(
                kind: .localSourceReadOnly,
                title: "Read-only source",
                detail: "Source is indexed for inspection; mutation apply is blocked.",
                isWritable: false
            )
        case "Bundled Fallback":
            return ProjectWritePolicy(
                kind: .bundledFallback,
                title: "Read-only bundled fallback",
                detail: "Bundled data is for exploration; open a local source tree before editing.",
                isWritable: false
            )
        case "Reference":
            return ProjectWritePolicy(
                kind: .reference,
                title: "Read-only reference",
                detail: "Reference repositories are research material, not editable project roots.",
                isWritable: false
            )
        case "Local Input":
            return ProjectWritePolicy(
                kind: .romInput,
                title: "Read-only ROM input",
                detail: "Standalone ROMs can be inspected; direct binary mutation remains blocked.",
                isWritable: false
            )
        case "Local Source":
            return ProjectWritePolicy(
                kind: .localSourceReadOnly,
                title: "Read-only source",
                detail: "This source tree is preview/readiness-only until an explicit writer row opens it.",
                isWritable: false
            )
        default:
            return ProjectWritePolicy(
                kind: rawWritePolicy.caseInsensitiveCompare("editable") == .orderedSame ? .editableSource : .localSourceReadOnly,
                title: rawWritePolicy.caseInsensitiveCompare("editable") == .orderedSame ? "Editable source" : "Review before writing",
                detail: "Review the selected project policy before applying mutations.",
                isWritable: rawWritePolicy.caseInsensitiveCompare("editable") == .orderedSame
            )
        }
    }

    static let fixture = ProjectWritePolicy(
        kind: .fixtureDev,
        title: "Read-only fixture",
        detail: "Demo records are safe fallback data and do not write to a project.",
        isWritable: false
    )
}

struct ProjectIdentity: Equatable, Identifiable {
    let id: String
    let title: String
    let rootPath: String
    let originLabel: String
    let writePolicy: ProjectWritePolicy

    var kind: ProjectIdentityKind { writePolicy.kind }
    var isWritable: Bool { writePolicy.isWritable }
    var kindTitle: String { kind.title }
    var systemImage: String { kind.systemImage }

    var rootDisplay: String {
        rootPath.isEmpty ? "No source root selected" : rootPath
    }

    static func fixture(title: String) -> ProjectIdentity {
        ProjectIdentity(
            id: "fixture::\(title)",
            title: title,
            rootPath: "",
            originLabel: "Demo Fixture",
            writePolicy: .fixture
        )
    }
}

enum GuidedWorkflowStepState: String, Identifiable {
    case ready = "Ready"
    case needsProject = "Needs Project"
    case needsSelection = "Needs Selection"
    case hasDraft = "Draft Active"
    case needsPreview = "Preview Needed"
    case previewReady = "Preview Ready"
    case blocked = "Blocked"

    var id: String { rawValue }

    var validationState: ValidationState {
        switch self {
        case .ready, .previewReady:
            .valid
        case .needsProject, .needsSelection, .hasDraft, .needsPreview:
            .warning
        case .blocked:
            .error
        }
    }
}

struct GuidedWorkflowRun: Identifiable {
    let id: String
    let currentStep: String
    let state: GuidedWorkflowStepState
    let activeObject: String
    let mutationGate: String
    let nextAction: String
    let diagnosticsCount: Int
    let artifacts: [String]
}

enum ModuleEditorMutationStage: String, Identifiable {
    case browse = "Browse"
    case draftReady = "Draft Ready"
    case previewReady = "Preview Ready"
    case blocked = "Blocked"

    var id: String { rawValue }

    var validationState: ValidationState {
        switch self {
        case .browse, .previewReady:
            .valid
        case .draftReady:
            .warning
        case .blocked:
            .error
        }
    }
}

struct ModuleEditorSession: Identifiable {
    let module: WorkbenchModule
    let selectedObjectTitle: String
    let selectedObjectID: String?
    let isDirty: Bool
    let canPreview: Bool
    let canApply: Bool
    let canDiscard: Bool
    let stage: ModuleEditorMutationStage
    let nextActionTitle: String
    let blockedReason: String?
    let diagnosticsCount: Int

    var id: String {
        "\(module.id)::\(selectedObjectID ?? "none")"
    }
}

enum SourceLocationAction: String, CaseIterable, Identifiable {
    case copyPath = "Copy Path"
    case revealInFinder = "Reveal in Finder"
    case openExternally = "Open Externally"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .copyPath:
            "doc.on.doc"
        case .revealInFinder:
            "finder"
        case .openExternally:
            "arrow.up.forward.app"
        }
    }
}

enum ValidationTier: String, CaseIterable, Identifiable {
    case synthetic
    case localGBAFixtures
    case centralNDSReferences
    case appGUISmoke
    case releaseCandidate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .synthetic:
            "Synthetic"
        case .localGBAFixtures:
            "Local GBA Fixtures"
        case .centralNDSReferences:
            "Central NDS References"
        case .appGUISmoke:
            "App GUI Smoke"
        case .releaseCandidate:
            "Release Candidate"
        }
    }

    var command: String {
        switch self {
        case .synthetic:
            "make validate-synthetic"
        case .localGBAFixtures:
            "make validate-gba-fixtures"
        case .centralNDSReferences:
            "make validate-nds-strict"
        case .appGUISmoke:
            "make validate-gui-smoke"
        case .releaseCandidate:
            "make validate-release-candidate"
        }
    }
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

struct SourceInspectorContext {
    let title: String
    let subtitle: String
    let systemImage: String
    let status: ValidationState?
    let facts: [SourceInspectorFact]
    let sources: [SourceInspectorSource]
    let diagnostics: [SourceInspectorDiagnostic]
}

struct SourceInspectorFact: Identifiable {
    let id: String
    let label: String
    let value: String

    init(label: String, value: String) {
        id = label
        self.label = label
        self.value = value
    }
}

struct SourceInspectorSource: Identifiable {
    let id: String
    let title: String
    let source: SourceLocation
    let status: ValidationState?

    init(title: String, source: SourceLocation, status: ValidationState? = nil) {
        id = "\(title):\(source.label):\(source.symbol)"
        self.title = title
        self.source = source
        self.status = status
    }
}

struct SourceInspectorDiagnostic: Identifiable {
    let id: String
    let title: String
    let message: String
    let status: ValidationState
    let source: SourceLocation?

    init(id: String, title: String, message: String, status: ValidationState, source: SourceLocation? = nil) {
        self.id = id
        self.title = title
        self.message = message
        self.status = status
        self.source = source
    }
}

extension SourceInspectorDiagnostic {
    init(diagnostic: IndexedDiagnosticRow) {
        self.init(
            id: diagnostic.id,
            title: diagnostic.title,
            message: diagnostic.message,
            status: diagnostic.severity,
            source: diagnostic.source
        )
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
    let disabledReason: String?
}

enum BuildReportSection: String, CaseIterable, Identifiable, Hashable {
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
    let isNDS: Bool
    let status: ValidationState
    let buildTargets: [BuildTargetValidationViewState]
    let generatedArtifacts: [GeneratedArtifactValidationViewState]
    let toolchain: ToolchainReadinessViewState
    let healthMatrix: ToolchainHealthMatrixViewState
    let playtest: PlaytestHandoffPlanViewState
    let playtestDebug: PlaytestDebugPlanViewState
    let baseROMOptions: [BaseROMOptionViewState]
    let diagnostics: [IndexedDiagnosticRow]

    var rows: [BuildReportRow] {
        buildTargets.map(BuildReportRow.init(target:))
            + generatedArtifacts.map(BuildReportRow.init(artifact:))
            + toolchain.rows
            + healthMatrix.rows
            + [BuildReportRow(playtest: playtest)]
            + playtestDebug.rows
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
    let isNDS: Bool
    let status: ValidationState
    let detail: String
    let readyCount: Int
    let warningCount: Int
    let errorCount: Int
    let notApplicableCount: Int
    let rows: [BuildReportRow]
    let ndsGroups: [NDSToolchainHealthGroupViewState]
}

struct NDSToolchainHealthGroupViewState: Identifiable {
    let id: String
    let title: String
    let detail: String
    let rows: [BuildReportRow]

    var readyCount: Int {
        rows.filter { $0.healthStatus == .ready }.count
    }

    var warningCount: Int {
        rows.filter { $0.healthStatus == .warning }.count
    }

    var notApplicableCount: Int {
        rows.filter { $0.healthStatus == .notApplicable }.count
    }

    var status: ValidationState {
        if rows.contains(where: { $0.status == .error }) {
            return .error
        }
        if rows.contains(where: { $0.status == .warning }) {
            return .warning
        }
        return .valid
    }
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

struct BuildRunLogLineViewState: Identifiable {
    let id: String
    let stream: String
    let message: String
    let emittedAt: Date
}

struct BuildRunArtifactViewState: Identifiable {
    let id: String
    let kind: String
    let path: String
    let absolutePath: String
    let detail: String
    let exists: Bool
    let source: SourceLocation
}

struct BuildRunResultViewState: Identifiable {
    let id: String
    let title: String
    let status: ValidationState
    let statusLabel: String
    let detail: String
    let command: String
    let processID: String
    let exitCode: String
    let outputPath: String?
    let outputDetail: String
    let artifacts: [BuildRunArtifactViewState]
    let diagnostics: [IndexedDiagnosticRow]
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

struct PlaytestDebugCapabilityViewState: Identifiable {
    let id: String
    let toolName: String
    let status: ValidationState
    let statusLabel: String
    let resolvedPath: String?
    let supportedActions: [String]
    let command: String
    let detail: String
    let source: SourceLocation
}

struct PlaytestDebugPlanViewState: Identifiable {
    let id: String
    let status: ValidationState
    let detail: String
    let command: String
    let isRunnable: Bool
    let isLaunchEnabled: Bool
    let artifacts: [PlaytestArtifactViewState]
    let capabilities: [PlaytestDebugCapabilityViewState]
    let diagnostics: [IndexedDiagnosticRow]
    let source: SourceLocation

    var rows: [BuildReportRow] {
        capabilities.map(BuildReportRow.init(debugCapability:))
            + diagnostics.map(BuildReportRow.init(diagnostic:))
    }
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

struct PlaytestCaptureResultViewState: Identifiable {
    let id: String
    let title: String
    let status: ValidationState
    let statusLabel: String
    let detail: String
    let emulatorPath: String?
    let romPath: String?
    let command: String
    let processID: String
    let artifacts: [PlaytestArtifactViewState]
    let source: SourceLocation

    var primaryArtifact: PlaytestArtifactViewState? {
        artifacts.first(where: \.isPrimaryCaptureArtifact)
    }
}

struct PlaytestArtifactViewState: Identifiable {
    let id: String
    let kind: String
    let path: String
    let absolutePath: String?
    let detail: String
    let exists: Bool
    let isPrimaryCaptureArtifact: Bool
    let source: SourceLocation

    var canOpenOrReveal: Bool {
        exists && absolutePath != nil
    }
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
    let actions: [BuildReportRowAction]

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
        healthStatus: WorkbenchHealthCheckStatus? = nil,
        actions: [BuildReportRowAction] = []
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
        self.actions = actions
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

    init(debugCapability: PlaytestDebugCapabilityViewState) {
        self.init(
            id: "playtest-debug:\(debugCapability.id)",
            section: .playtest,
            title: debugCapability.toolName,
            subtitle: debugCapability.statusLabel,
            detail: debugCapability.detail,
            status: debugCapability.status,
            source: debugCapability.source,
            tags: [debugCapability.toolName, debugCapability.command, debugCapability.supportedActions.joined(separator: " ")]
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

    init(captureResult: PlaytestCaptureResultViewState) {
        self.init(
            id: "playtest-capture:\(captureResult.id)",
            section: .playtest,
            title: captureResult.title,
            subtitle: captureResult.processID,
            detail: captureResult.detail,
            status: captureResult.status,
            source: captureResult.source,
            tags: [captureResult.statusLabel, captureResult.command, captureResult.romPath ?? ""]
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

struct BuildReportRowAction: Identifiable {
    enum Kind: String, Equatable {
        case copyCommand = "Copy Command"
        case copyPath = "Copy Path"
        case rerunGuidance = "Rerun Guidance"
    }

    let id: String
    let kind: Kind
    let title: String
    let detail: String
    let command: String?
    let payload: String?

    var copyValue: String? {
        command ?? payload
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

enum GraphicsImportPackagePlanLoadStatus: Equatable {
    case idle
    case loading
    case loaded(String)
    case failed(String)

    var label: String {
        switch self {
        case .idle:
            "No graphics import package loaded"
        case .loading:
            "Loading graphics import package"
        case .loaded(let readiness):
            "Graphics import plan loaded: \(readiness)"
        case .failed(let message):
            "Graphics import plan failed: \(message)"
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

struct GraphicsImportPackagePlanViewState: Identifiable {
    let id: String
    let projectRootPath: String
    let packageRootPath: String
    let packageTitle: String
    let readiness: String
    let status: ValidationState
    let isPreviewOnly: Bool
    let inventoryRows: [GraphicsImportInventoryRowViewState]
    let creditMetadataRows: [GraphicsImportInventoryRowViewState]
    let copyTargets: [GraphicsImportCopyTargetViewState]
    let layeredDryRun: GraphicsImportLayeredDryRunViewState
    let paletteFitPreviews: [GraphicsImportPaletteFitPreviewViewState]
    let expectedOutputs: [String]
    let diagnostics: [IndexedDiagnosticRow]
}

struct GraphicsImportInventoryRowViewState: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let detail: String
    let status: ValidationState
    let source: SourceLocation
    let tags: [String]
}

struct GraphicsImportCopyTargetViewState: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let detail: String
    let status: ValidationState
    let source: SourceLocation
    let tags: [String]
    let willOverwriteExistingSource: Bool
}

struct GraphicsImportLayeredDryRunViewState {
    let title: String
    let detail: String
    let status: ValidationState
    let detectedLayerPaths: [String]
    let missingLayerNames: [String]
    let attributesPath: String?
    let animationFileCount: Int
    let expectedGeneratedOutputs: [String]
    let externalToolPlan: String
}

struct GraphicsImportPaletteFitPreviewViewState: Identifiable {
    let id: String
    let title: String
    let detail: String
    let status: ValidationState
    let source: SourceLocation
    let tags: [String]
    let diagnostics: [IndexedDiagnosticRow]
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

    var identity: ProjectIdentity {
        ProjectIdentity(
            id: id,
            title: title,
            rootPath: rootPath,
            originLabel: originLabel,
            writePolicy: ProjectWritePolicy.policy(originLabel: originLabel, rawWritePolicy: writePolicy)
        )
    }
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
    let index: ResourceAssetCatalogIndex

    init(
        id: String,
        projectTitle: String,
        rootPath: String,
        profile: String,
        assetCount: Int,
        categoryCounts: [ResourceAssetCategoryCount],
        availabilityCounts: [ResourceAssetAvailabilityCount],
        rows: [ResourceAssetRowViewState],
        diagnostics: [IndexedDiagnosticRow],
        index: ResourceAssetCatalogIndex? = nil
    ) {
        self.id = id
        self.projectTitle = projectTitle
        self.rootPath = rootPath
        self.profile = profile
        self.assetCount = assetCount
        self.categoryCounts = categoryCounts
        self.availabilityCounts = availabilityCounts
        self.rows = rows
        self.diagnostics = diagnostics
        self.index = index ?? ResourceAssetCatalogIndex(rows: rows)
    }

    var categoryTitles: [String] {
        categoryCounts.map(\.category)
    }
}

struct ResourceAssetCatalogIndex {
    let rows: [ResourceAssetRowViewState]
    let rowsByID: [String: ResourceAssetRowViewState]
    let rowsByTargetID: [String: ResourceAssetRowViewState]
    let rowsByPath: [String: ResourceAssetRowViewState]
    let rowsByPathMatchingTargetID: [String: ResourceAssetRowViewState]
    let rowsByTitle: [String: ResourceAssetRowViewState]
    let rowsBySourcePath: [String: ResourceAssetRowViewState]
    let categoryBuckets: [String: [ResourceAssetRowViewState]]
    let sortedRowsByMode: [ResourceAssetSortMode: [ResourceAssetRowViewState]]
    let sortedCategoryBucketsByMode: [ResourceAssetSortMode: [String: [ResourceAssetRowViewState]]]
    let availabilityCountsByValue: [String: Int]
    let availabilityStatusCounts: [ValidationState: Int]
    let availabilityProblemStatusCounts: [ValidationState: Int]
    let availabilityProblemCount: Int

    init(rows: [ResourceAssetRowViewState]) {
        var rowsByID: [String: ResourceAssetRowViewState] = [:]
        var rowsByTargetID: [String: ResourceAssetRowViewState] = [:]
        var rowsByPath: [String: ResourceAssetRowViewState] = [:]
        var rowsByPathMatchingTargetID: [String: ResourceAssetRowViewState] = [:]
        var rowsByTitle: [String: ResourceAssetRowViewState] = [:]
        var rowsBySourcePath: [String: ResourceAssetRowViewState] = [:]
        var categoryBuckets: [String: [ResourceAssetRowViewState]] = [:]
        var availabilityCountsByValue: [String: Int] = [:]
        var availabilityStatusCounts: [ValidationState: Int] = [:]
        var availabilityProblemStatusCounts: [ValidationState: Int] = [:]

        for row in rows {
            rowsByID[row.id] = rowsByID[row.id] ?? row
            if let targetID = row.targetID, !targetID.isEmpty {
                rowsByTargetID[targetID] = rowsByTargetID[targetID] ?? row
                if row.path == targetID {
                    rowsByPathMatchingTargetID[targetID] = rowsByPathMatchingTargetID[targetID] ?? row
                }
            }
            rowsByPath[row.path] = rowsByPath[row.path] ?? row
            rowsByTitle[row.title] = rowsByTitle[row.title] ?? row
            rowsBySourcePath[row.source.path] = rowsBySourcePath[row.source.path] ?? row
            categoryBuckets[row.category, default: []].append(row)
            availabilityCountsByValue[row.availability, default: 0] += 1
            availabilityStatusCounts[row.status, default: 0] += 1
            if row.affectsResourceAvailability, row.status != .valid {
                availabilityProblemStatusCounts[row.status, default: 0] += 1
            }
        }

        var sortedRowsByMode: [ResourceAssetSortMode: [ResourceAssetRowViewState]] = [:]
        var sortedCategoryBucketsByMode: [ResourceAssetSortMode: [String: [ResourceAssetRowViewState]]] = [:]
        for sortMode in ResourceAssetSortMode.allCases {
            sortedRowsByMode[sortMode] = Self.sorted(rows, by: sortMode)
            var buckets: [String: [ResourceAssetRowViewState]] = [:]
            for (category, bucketRows) in categoryBuckets {
                buckets[category] = Self.sorted(bucketRows, by: sortMode)
            }
            sortedCategoryBucketsByMode[sortMode] = buckets
        }

        self.rows = rows
        self.rowsByID = rowsByID
        self.rowsByTargetID = rowsByTargetID
        self.rowsByPath = rowsByPath
        self.rowsByPathMatchingTargetID = rowsByPathMatchingTargetID
        self.rowsByTitle = rowsByTitle
        self.rowsBySourcePath = rowsBySourcePath
        self.categoryBuckets = categoryBuckets
        self.sortedRowsByMode = sortedRowsByMode
        self.sortedCategoryBucketsByMode = sortedCategoryBucketsByMode
        self.availabilityCountsByValue = availabilityCountsByValue
        self.availabilityStatusCounts = availabilityStatusCounts
        self.availabilityProblemStatusCounts = availabilityProblemStatusCounts
        self.availabilityProblemCount = availabilityProblemStatusCounts.values.reduce(0, +)
    }

    func exactMatch(identifier: String) -> ResourceAssetRowViewState? {
        rowsByID[identifier]
            ?? rowsByTargetID[identifier]
            ?? rowsByPathMatchingTargetID[identifier]
            ?? rowsByPath[identifier]
            ?? rowsByTitle[identifier]
            ?? rowsBySourcePath[identifier]
    }

    func substringMatch(needle: String) -> ResourceAssetRowViewState? {
        rows.first { $0.searchBlob.contains(needle) }
    }

    func filteredRows(
        category: String,
        allCategory: String,
        searchText: String,
        sortMode: ResourceAssetSortMode
    ) -> [ResourceAssetRowViewState] {
        let sortedRows: [ResourceAssetRowViewState]
        if category == allCategory {
            sortedRows = sortedRowsByMode[sortMode] ?? []
        } else {
            sortedRows = sortedCategoryBucketsByMode[sortMode]?[category] ?? []
        }

        let needle = searchText.lowercased()
        guard !needle.isEmpty else { return sortedRows }
        return sortedRows.filter { $0.searchBlob.contains(needle) }
    }

    static func sorted(
        _ rows: [ResourceAssetRowViewState],
        by sortMode: ResourceAssetSortMode
    ) -> [ResourceAssetRowViewState] {
        rows.sorted { lhs, rhs in
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

enum GameCubeResourceLoadStatus: Equatable {
    case idle
    case loaded(itemCount: Int)
    case failed(String)

    var label: String {
        switch self {
        case .idle:
            "No GameCube media loaded"
        case .loaded(let itemCount):
            itemCount == 1 ? "1 GameCube resource indexed" : "\(itemCount) GameCube resources indexed"
        case .failed(let message):
            "GameCube resource failed: \(message)"
        }
    }

    var validationState: ValidationState {
        switch self {
        case .failed:
            .warning
        case .idle, .loaded:
            .valid
        }
    }
}

enum SourceGraphLoadStatus: Equatable {
    case idle
    case loading
    case loaded(recordCount: Int, labelCount: Int)
    case failed(String)

    var label: String {
        switch self {
        case .idle:
            "Source graph not loaded"
        case .loading:
            "Loading source graph"
        case .loaded(let recordCount, let labelCount):
            "\(recordCount) source records, \(labelCount) script labels"
        case .failed(let message):
            "Source graph failed: \(message)"
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

enum MoveCatalogLoadStatus: Equatable {
    case idle
    case loading
    case loaded(Int)
    case failed(String)

    var label: String {
        switch self {
        case .idle:
            "Move catalog not loaded"
        case .loading:
            "Loading move catalog"
        case .loaded(let count):
            count == 1 ? "1 move loaded" : "\(count) moves loaded"
        case .failed(let message):
            "Move catalog failed: \(message)"
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

enum ItemCatalogLoadStatus: Equatable {
    case idle
    case loading
    case loaded(Int)
    case failed(String)

    var label: String {
        switch self {
        case .idle:
            "Item catalog not loaded"
        case .loading:
            "Loading item catalog"
        case .loaded(let count):
            count == 1 ? "1 item loaded" : "\(count) items loaded"
        case .failed(let message):
            "Item catalog failed: \(message)"
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

enum MoveWorkbenchFilter: String, CaseIterable, Identifiable, Hashable {
    case all = "All"
    case tmhm = "TM/HM"
    case tutor = "Tutor"
    case learnedBy = "Learned By"
    case diagnostics = "Diagnostics"

    var id: String { rawValue }
}

struct MoveCatalogViewState: Identifiable {
    let id: String
    let projectTitle: String
    let rootPath: String
    let profile: String
    let status: ValidationState
    let moveCount: Int
    let learnsetEntryCount: Int
    let tmhmMoveCount: Int
    let tutorMoveCount: Int
    let moves: [MoveDetailViewState]
    let diagnostics: [IndexedDiagnosticRow]
}

struct MoveDetailViewState: Identifiable {
    let id: String
    let moveID: String
    let displayName: String
    let status: ValidationState
    let facts: [Fact]
    let battleFacts: [Fact]
    let source: SourceLocation
    let sourcePreview: String?
    let isEditable: Bool
    let isDescriptionEditable: Bool
    let descriptionText: String?
    let tmhmLearners: [MoveLearnerRowViewState]
    let tutorLearners: [MoveLearnerRowViewState]
    let learnedBy: [MoveLearnerRowViewState]
    let diagnostics: [IndexedDiagnosticRow]
    let searchBlob: String

    var learnerCount: Int {
        tmhmLearners.count + tutorLearners.count + learnedBy.count
    }
}

enum ItemWorkbenchFilter: String, CaseIterable, Identifiable, Hashable {
    case all = "All"
    case editable = "Editable"
    case diagnostics = "Diagnostics"

    var id: String { rawValue }
}

struct ItemCatalogViewState: Identifiable {
    let id: String
    let projectTitle: String
    let rootPath: String
    let profile: String
    let status: ValidationState
    let itemCount: Int
    let editableCount: Int
    let items: [ItemDetailViewState]
    let diagnostics: [IndexedDiagnosticRow]
}

struct ItemDetailViewState: Identifiable {
    let id: String
    let itemID: String
    let displayName: String
    let status: ValidationState
    let facts: [Fact]
    let source: SourceLocation
    let sourcePreview: String?
    let isEditable: Bool
    let isDescriptionEditable: Bool
    let descriptionText: String?
    let diagnostics: [IndexedDiagnosticRow]
    let searchBlob: String
}

struct MoveLearnerRowViewState: Identifiable {
    let id: String
    let speciesID: String
    let bucket: LearnsetBucket
    let detail: String
    let source: SourceLocation

    var bucketTitle: String {
        switch bucket {
        case .levelUp:
            "Level Up"
        case .tmhm:
            "TM/HM"
        case .tutor:
            "Tutor"
        case .egg:
            "Egg"
        case .allLearnables:
            "All Learnables"
        case .other:
            "Other"
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
    let detailMode: String
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

struct NDSDataResourceEditorViewState {
    let assetID: String
    let recordID: String
    let text: String
    let semanticFields: [NDSDataSemanticFieldViewState]
    let canEdit: Bool
    let isDirty: Bool
    let isHiddenByFilters: Bool
    let sourceByteCount: Int
    let draftByteCount: Int
    let lensSummary: String
    let hiddenDraftSummary: String?
    let canPreview: Bool
    let canApply: Bool
    let canDiscard: Bool
    let blockedReason: String?
    let applyBlockedReason: String?
}

struct NDSDataSemanticFieldViewState: Identifiable {
    let id: String
    let key: String
    let label: String
    let value: String
    let valueKind: String
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
    case refreshMaps

    var id: String {
        switch self {
        case .project(let id):
            "project:\(id)"
        case .map(let id):
            "map:\(id)"
        case .refreshMaps:
            "refreshMaps"
        }
    }

    var title: String {
        switch self {
        case .project:
            "Switch project?"
        case .map:
            "Switch map?"
        case .refreshMaps:
            "Refresh maps?"
        }
    }

    var message: String {
        "This map has staged edits. Preview or discard them before changing selection."
    }
}
