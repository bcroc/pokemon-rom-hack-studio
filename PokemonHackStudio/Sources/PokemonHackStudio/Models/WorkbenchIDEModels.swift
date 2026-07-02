import Foundation

struct WorkbenchEditorTab: Identifiable, Hashable, Codable {
    let id: String
    let moduleRawValue: String
    let title: String
    let subtitle: String
    let systemImage: String
    let targetID: String?

    var module: WorkbenchModule {
        WorkbenchModule(rawValue: moduleRawValue) ?? .dashboard
    }

    static func module(_ module: WorkbenchModule, targetID: String? = nil, subtitle: String? = nil) -> WorkbenchEditorTab {
        let id = targetID.map { "\(module.id)::\($0)" } ?? module.id
        return WorkbenchEditorTab(
            id: id,
            moduleRawValue: module.rawValue,
            title: module.title,
            subtitle: subtitle ?? module.subtitle,
            systemImage: module.systemImage,
            targetID: targetID
        )
    }
}

enum WorkbenchNavigatorGroup: String, CaseIterable, Identifiable, Codable {
    case workspace = "Workspace"
    case visual = "Visual"
    case data = "Data"
    case assets = "Assets"
    case ship = "Ship"
    case diagnostics = "Diagnostics"
    case romInputs = "ROM Inputs"
    case references = "References"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .workspace: "folder"
        case .visual: "rectangle.3.group"
        case .data: "tablecells"
        case .assets: "photo.stack"
        case .ship: "paperplane"
        case .diagnostics: "exclamationmark.triangle"
        case .romInputs: "opticaldiscdrive"
        case .references: "books.vertical"
        }
    }
}

struct WorkbenchNavigatorNode: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let status: ValidationState?
    let badge: String?
    let module: WorkbenchModule?
    let target: WorkbenchFocusTarget?
    let children: [WorkbenchNavigatorNode]

    init(
        id: String,
        title: String,
        subtitle: String,
        systemImage: String,
        status: ValidationState? = nil,
        badge: String? = nil,
        module: WorkbenchModule? = nil,
        target: WorkbenchFocusTarget? = nil,
        children: [WorkbenchNavigatorNode] = []
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.status = status
        self.badge = badge
        self.module = module
        self.target = target
        self.children = children
    }
}

enum WorkbenchInspectorMode: String, CaseIterable, Identifiable, Codable {
    case source = "Source"
    case selection = "Selection"
    case diagnostics = "Diagnostics"
    case mutation = "Mutation"
    case artifacts = "Artifacts"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .source: "doc.text.magnifyingglass"
        case .selection: "scope"
        case .diagnostics: "exclamationmark.triangle"
        case .mutation: "checkmark.seal"
        case .artifacts: "archivebox"
        }
    }
}

enum WorkbenchBottomPanelMode: String, CaseIterable, Identifiable, Codable {
    case activity = "Activity"
    case buildLogs = "Build Logs"
    case playtest = "Playtest"
    case artifacts = "Artifacts"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .activity: "waveform.path.ecg"
        case .buildLogs: "terminal"
        case .playtest: "gamecontroller"
        case .artifacts: "archivebox"
        }
    }
}

enum WorkbenchActivityCategory: String, CaseIterable, Identifiable, Codable {
    case build = "Build"
    case playtest = "Playtest"
    case patch = "Patch"
    case mutation = "Mutation"
    case diagnostics = "Diagnostics"
    case resources = "Resources"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .build: "hammer"
        case .playtest: "gamecontroller"
        case .patch: "doc.badge.gearshape"
        case .mutation: "checkmark.seal"
        case .diagnostics: "exclamationmark.triangle"
        case .resources: "externaldrive.connected.to.line.below"
        }
    }
}

struct WorkbenchActivityEvent: Identifiable, Equatable {
    let id: String
    let category: WorkbenchActivityCategory
    let title: String
    let detail: String
    let status: ValidationState
    let source: SourceLocation?

    static func == (lhs: WorkbenchActivityEvent, rhs: WorkbenchActivityEvent) -> Bool {
        lhs.id == rhs.id
            && lhs.category == rhs.category
            && lhs.title == rhs.title
            && lhs.detail == rhs.detail
            && lhs.status == rhs.status
            && lhs.source?.path == rhs.source?.path
            && lhs.source?.symbol == rhs.source?.symbol
            && lhs.source?.line == rhs.source?.line
    }
}

enum WorkbenchCommandAction: Hashable {
    case selectModule(WorkbenchModule)
    case openCommandPalette
    case refreshCurrent
    case refreshProjects
    case refreshResources
    case refreshHealth
    case previewMutation
    case applyMutation
    case discardMutation
    case runBuild
    case cancelBuild
    case openPlaytest
    case captureScreenshot
    case captureSavestate
    case copyValidationCommand(String)
    case copyReportJSON
    case copyMapRenderAuditJSON
    case copyPatchDistributionReadinessJSON
    case copyBinaryROMMutationApplyAuditJSON
    case copySelectedResourceReadinessPacketJSON
}

struct WorkbenchCommandAvailability: Equatable {
    let isEnabled: Bool
    let disabledReason: String?
    let isGuarded: Bool

    static let enabled = WorkbenchCommandAvailability(isEnabled: true, disabledReason: nil, isGuarded: false)

    static func guarded(_ isEnabled: Bool, disabledReason: String?) -> WorkbenchCommandAvailability {
        WorkbenchCommandAvailability(isEnabled: isEnabled, disabledReason: disabledReason, isGuarded: true)
    }

    static func disabled(_ reason: String, guarded: Bool = false) -> WorkbenchCommandAvailability {
        WorkbenchCommandAvailability(isEnabled: false, disabledReason: reason, isGuarded: guarded)
    }
}

struct WorkbenchCommand: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let scope: String
    let keyboardHint: String?
    let action: WorkbenchCommandAction
    let availability: WorkbenchCommandAvailability

    var searchBlob: String {
        [title, subtitle, scope, keyboardHint ?? ""]
            .joined(separator: " ")
            .lowercased()
    }
}

struct WorkbenchCommandPaletteState: Equatable {
    var isPresented: Bool = false
    var searchText: String = ""
    var selectedCommandID: String?
}
