import Foundation

enum WorkbenchHealthCheckCategory: String, CaseIterable, Identifiable {
    case externalTools
    case romHeaders
    case graphicsConversion
    case generatedArtifacts

    var id: String { rawValue }

    var title: String {
        switch self {
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

    var systemImage: String {
        switch self {
        case .externalTools:
            "wrench.and.screwdriver"
        case .romHeaders:
            "memorychip"
        case .graphicsConversion:
            "paintpalette"
        case .generatedArtifacts:
            "archivebox"
        }
    }
}

enum WorkbenchHealthCheckStatus: String, CaseIterable {
    case ready
    case warning
    case error
    case notApplicable
}

enum WorkbenchHealthNoiseLevel: String, CaseIterable, Identifiable {
    case all
    case warningsAndErrors
    case errorsOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            "All Rows"
        case .warningsAndErrors:
            "Warnings and Errors"
        case .errorsOnly:
            "Errors Only"
        }
    }

    func includes(_ status: WorkbenchHealthCheckStatus?) -> Bool {
        guard let status else { return true }
        switch self {
        case .all:
            return true
        case .warningsAndErrors:
            return status == .warning || status == .error
        case .errorsOnly:
            return status == .error
        }
    }
}

enum WorkbenchEditorStartupTool: String, CaseIterable, Identifiable {
    case select
    case hand
    case pencil
    case eyedropper

    var id: String { rawValue }

    var title: String {
        switch self {
        case .select:
            "Select"
        case .hand:
            "Pan"
        case .pencil:
            "Pencil"
        case .eyedropper:
            "Eyedropper"
        }
    }
}

enum WorkbenchMapZoomDefault: String, CaseIterable, Identifiable {
    case fit
    case oneHundred
    case twoHundred

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fit:
            "Fit"
        case .oneHundred:
            "100%"
        case .twoHundred:
            "200%"
        }
    }
}

@MainActor
final class WorkbenchUserSettings: ObservableObject {
    private enum Key {
        static let autoLoadProjects = "PokemonHackStudio.settings.autoLoadProjects"
        static let rememberRecentProjects = "PokemonHackStudio.settings.rememberRecentProjects"
        static let includeDefaultDebugProjects = "PokemonHackStudio.settings.includeDefaultDebugProjects"
        static let includeRecentProjectsInRefresh = "PokemonHackStudio.settings.includeRecentProjectsInRefresh"
        static let maxRecentProjects = "PokemonHackStudio.settings.maxRecentProjects"
        static let autoLoadAssetCatalog = "PokemonHackStudio.settings.autoLoadAssetCatalog"
        static let autoRefreshHealthOnProjectRefresh = "PokemonHackStudio.settings.autoRefreshHealthOnProjectRefresh"
        static let includeHealthDiagnosticsInGlobalIssues = "PokemonHackStudio.settings.includeHealthDiagnosticsInGlobalIssues"
        static let showNotApplicableHealthRows = "PokemonHackStudio.settings.showNotApplicableHealthRows"
        static let healthNoiseLevel = "PokemonHackStudio.settings.healthNoiseLevel"
        static let enabledHealthCategories = "PokemonHackStudio.settings.enabledHealthCategories"
        static let editorStartupTool = "PokemonHackStudio.settings.editorStartupTool"
        static let mapZoomDefault = "PokemonHackStudio.settings.mapZoomDefault"
        static let showGridByDefault = "PokemonHackStudio.settings.showGridByDefault"
        static let showCollisionByDefault = "PokemonHackStudio.settings.showCollisionByDefault"
        static let preferCompactMapControls = "PokemonHackStudio.settings.preferCompactMapControls"
        static let showSourceInspectorByDefault = "PokemonHackStudio.settings.showSourceInspectorByDefault"
        static let resourceAutoRefreshOnOpen = "PokemonHackStudio.settings.resourceAutoRefreshOnOpen"
        static let includeReferenceRootsInResources = "PokemonHackStudio.settings.includeReferenceRootsInResources"
        static let resourceSearchMatchesNestedItems = "PokemonHackStudio.settings.resourceSearchMatchesNestedItems"
    }

    private let defaults: UserDefaults

    @Published var autoLoadProjects: Bool { didSet { set(autoLoadProjects, forKey: Key.autoLoadProjects) } }
    @Published var rememberRecentProjects: Bool { didSet { set(rememberRecentProjects, forKey: Key.rememberRecentProjects) } }
    @Published var includeDefaultDebugProjects: Bool { didSet { set(includeDefaultDebugProjects, forKey: Key.includeDefaultDebugProjects) } }
    @Published var includeRecentProjectsInRefresh: Bool { didSet { set(includeRecentProjectsInRefresh, forKey: Key.includeRecentProjectsInRefresh) } }
    @Published var maxRecentProjects: Int { didSet { set(maxRecentProjects, forKey: Key.maxRecentProjects) } }
    @Published var autoLoadAssetCatalog: Bool { didSet { set(autoLoadAssetCatalog, forKey: Key.autoLoadAssetCatalog) } }
    @Published var autoRefreshHealthOnProjectRefresh: Bool { didSet { set(autoRefreshHealthOnProjectRefresh, forKey: Key.autoRefreshHealthOnProjectRefresh) } }
    @Published var includeHealthDiagnosticsInGlobalIssues: Bool { didSet { set(includeHealthDiagnosticsInGlobalIssues, forKey: Key.includeHealthDiagnosticsInGlobalIssues) } }
    @Published var showNotApplicableHealthRows: Bool { didSet { set(showNotApplicableHealthRows, forKey: Key.showNotApplicableHealthRows) } }
    @Published var healthNoiseLevel: WorkbenchHealthNoiseLevel { didSet { set(healthNoiseLevel.rawValue, forKey: Key.healthNoiseLevel) } }
    @Published var enabledHealthCategories: Set<WorkbenchHealthCheckCategory> { didSet { set(enabledHealthCategories.map(\.rawValue), forKey: Key.enabledHealthCategories) } }
    @Published var editorStartupTool: WorkbenchEditorStartupTool { didSet { set(editorStartupTool.rawValue, forKey: Key.editorStartupTool) } }
    @Published var mapZoomDefault: WorkbenchMapZoomDefault { didSet { set(mapZoomDefault.rawValue, forKey: Key.mapZoomDefault) } }
    @Published var showGridByDefault: Bool { didSet { set(showGridByDefault, forKey: Key.showGridByDefault) } }
    @Published var showCollisionByDefault: Bool { didSet { set(showCollisionByDefault, forKey: Key.showCollisionByDefault) } }
    @Published var preferCompactMapControls: Bool { didSet { set(preferCompactMapControls, forKey: Key.preferCompactMapControls) } }
    @Published var showSourceInspectorByDefault: Bool { didSet { set(showSourceInspectorByDefault, forKey: Key.showSourceInspectorByDefault) } }
    @Published var resourceAutoRefreshOnOpen: Bool { didSet { set(resourceAutoRefreshOnOpen, forKey: Key.resourceAutoRefreshOnOpen) } }
    @Published var includeReferenceRootsInResources: Bool { didSet { set(includeReferenceRootsInResources, forKey: Key.includeReferenceRootsInResources) } }
    @Published var resourceSearchMatchesNestedItems: Bool { didSet { set(resourceSearchMatchesNestedItems, forKey: Key.resourceSearchMatchesNestedItems) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        autoLoadProjects = Self.bool(forKey: Key.autoLoadProjects, defaultValue: true, defaults: defaults)
        rememberRecentProjects = Self.bool(forKey: Key.rememberRecentProjects, defaultValue: true, defaults: defaults)
        includeDefaultDebugProjects = Self.bool(forKey: Key.includeDefaultDebugProjects, defaultValue: true, defaults: defaults)
        includeRecentProjectsInRefresh = Self.bool(forKey: Key.includeRecentProjectsInRefresh, defaultValue: true, defaults: defaults)
        maxRecentProjects = Self.integer(forKey: Key.maxRecentProjects, defaultValue: 8, defaults: defaults)
        autoLoadAssetCatalog = Self.bool(forKey: Key.autoLoadAssetCatalog, defaultValue: false, defaults: defaults)
        autoRefreshHealthOnProjectRefresh = Self.bool(forKey: Key.autoRefreshHealthOnProjectRefresh, defaultValue: true, defaults: defaults)
        includeHealthDiagnosticsInGlobalIssues = Self.bool(forKey: Key.includeHealthDiagnosticsInGlobalIssues, defaultValue: true, defaults: defaults)
        showNotApplicableHealthRows = Self.bool(forKey: Key.showNotApplicableHealthRows, defaultValue: true, defaults: defaults)
        healthNoiseLevel = Self.enumValue(forKey: Key.healthNoiseLevel, defaultValue: .all, defaults: defaults)
        let storedCategories = Set((defaults.stringArray(forKey: Key.enabledHealthCategories) ?? []).compactMap(WorkbenchHealthCheckCategory.init(rawValue:)))
        enabledHealthCategories = storedCategories.isEmpty ? Set(WorkbenchHealthCheckCategory.allCases) : storedCategories
        editorStartupTool = Self.enumValue(forKey: Key.editorStartupTool, defaultValue: .select, defaults: defaults)
        mapZoomDefault = Self.enumValue(forKey: Key.mapZoomDefault, defaultValue: .fit, defaults: defaults)
        showGridByDefault = Self.bool(forKey: Key.showGridByDefault, defaultValue: true, defaults: defaults)
        showCollisionByDefault = Self.bool(forKey: Key.showCollisionByDefault, defaultValue: false, defaults: defaults)
        preferCompactMapControls = Self.bool(forKey: Key.preferCompactMapControls, defaultValue: false, defaults: defaults)
        showSourceInspectorByDefault = Self.bool(forKey: Key.showSourceInspectorByDefault, defaultValue: true, defaults: defaults)
        resourceAutoRefreshOnOpen = Self.bool(forKey: Key.resourceAutoRefreshOnOpen, defaultValue: true, defaults: defaults)
        includeReferenceRootsInResources = Self.bool(forKey: Key.includeReferenceRootsInResources, defaultValue: true, defaults: defaults)
        resourceSearchMatchesNestedItems = Self.bool(forKey: Key.resourceSearchMatchesNestedItems, defaultValue: true, defaults: defaults)
    }

    func isHealthCategoryEnabled(_ category: WorkbenchHealthCheckCategory) -> Bool {
        enabledHealthCategories.contains(category)
    }

    func setHealthCategory(_ category: WorkbenchHealthCheckCategory, isEnabled: Bool) {
        if isEnabled {
            enabledHealthCategories.insert(category)
        } else {
            enabledHealthCategories.remove(category)
        }
    }

    func shouldShowHealthRow(category: WorkbenchHealthCheckCategory?, status: WorkbenchHealthCheckStatus?) -> Bool {
        if let category, !enabledHealthCategories.contains(category) {
            return false
        }
        if status == .notApplicable && !showNotApplicableHealthRows {
            return false
        }
        return healthNoiseLevel.includes(status)
    }

    func shouldShowHealthDiagnosticInGlobalIssues(_ diagnostic: IndexedDiagnosticRow) -> Bool {
        includeHealthDiagnosticsInGlobalIssues || !Self.isHealthDiagnostic(diagnostic)
    }

    func resetDefaults() {
        for key in Self.allKeys {
            defaults.removeObject(forKey: key)
        }
        let fresh = WorkbenchUserSettings(defaults: defaults)
        autoLoadProjects = fresh.autoLoadProjects
        rememberRecentProjects = fresh.rememberRecentProjects
        includeDefaultDebugProjects = fresh.includeDefaultDebugProjects
        includeRecentProjectsInRefresh = fresh.includeRecentProjectsInRefresh
        maxRecentProjects = fresh.maxRecentProjects
        autoLoadAssetCatalog = fresh.autoLoadAssetCatalog
        autoRefreshHealthOnProjectRefresh = fresh.autoRefreshHealthOnProjectRefresh
        includeHealthDiagnosticsInGlobalIssues = fresh.includeHealthDiagnosticsInGlobalIssues
        showNotApplicableHealthRows = fresh.showNotApplicableHealthRows
        healthNoiseLevel = fresh.healthNoiseLevel
        enabledHealthCategories = fresh.enabledHealthCategories
        editorStartupTool = fresh.editorStartupTool
        mapZoomDefault = fresh.mapZoomDefault
        showGridByDefault = fresh.showGridByDefault
        showCollisionByDefault = fresh.showCollisionByDefault
        preferCompactMapControls = fresh.preferCompactMapControls
        showSourceInspectorByDefault = fresh.showSourceInspectorByDefault
        resourceAutoRefreshOnOpen = fresh.resourceAutoRefreshOnOpen
        includeReferenceRootsInResources = fresh.includeReferenceRootsInResources
        resourceSearchMatchesNestedItems = fresh.resourceSearchMatchesNestedItems
    }

    func exportSnapshot() -> String {
        let categories = enabledHealthCategories.map(\.rawValue).sorted().joined(separator: ", ")
        return """
        PokemonHackStudio Settings
        autoLoadProjects=\(autoLoadProjects)
        rememberRecentProjects=\(rememberRecentProjects)
        includeDefaultDebugProjects=\(includeDefaultDebugProjects)
        includeRecentProjectsInRefresh=\(includeRecentProjectsInRefresh)
        maxRecentProjects=\(maxRecentProjects)
        autoLoadAssetCatalog=\(autoLoadAssetCatalog)
        autoRefreshHealthOnProjectRefresh=\(autoRefreshHealthOnProjectRefresh)
        includeHealthDiagnosticsInGlobalIssues=\(includeHealthDiagnosticsInGlobalIssues)
        showNotApplicableHealthRows=\(showNotApplicableHealthRows)
        healthNoiseLevel=\(healthNoiseLevel.rawValue)
        enabledHealthCategories=\(categories)
        editorStartupTool=\(editorStartupTool.rawValue)
        mapZoomDefault=\(mapZoomDefault.rawValue)
        showGridByDefault=\(showGridByDefault)
        showCollisionByDefault=\(showCollisionByDefault)
        preferCompactMapControls=\(preferCompactMapControls)
        showSourceInspectorByDefault=\(showSourceInspectorByDefault)
        resourceAutoRefreshOnOpen=\(resourceAutoRefreshOnOpen)
        includeReferenceRootsInResources=\(includeReferenceRootsInResources)
        resourceSearchMatchesNestedItems=\(resourceSearchMatchesNestedItems)
        """
    }

    static func isHealthDiagnostic(_ diagnostic: IndexedDiagnosticRow) -> Bool {
        let code = diagnostic.title
        return code.hasPrefix("TOOLCHAIN_")
            || code.hasPrefix("ROM_HEADER_")
            || code.hasPrefix("GRAPHICS_CONVERSION_")
            || code.hasPrefix("GRAPHICS_GENERATED_ARTIFACT_")
            || code.hasPrefix("GENERATED_ARTIFACT_")
    }

    private static var allKeys: [String] {
        [
            Key.autoLoadProjects,
            Key.rememberRecentProjects,
            Key.includeDefaultDebugProjects,
            Key.includeRecentProjectsInRefresh,
            Key.maxRecentProjects,
            Key.autoLoadAssetCatalog,
            Key.autoRefreshHealthOnProjectRefresh,
            Key.includeHealthDiagnosticsInGlobalIssues,
            Key.showNotApplicableHealthRows,
            Key.healthNoiseLevel,
            Key.enabledHealthCategories,
            Key.editorStartupTool,
            Key.mapZoomDefault,
            Key.showGridByDefault,
            Key.showCollisionByDefault,
            Key.preferCompactMapControls,
            Key.showSourceInspectorByDefault,
            Key.resourceAutoRefreshOnOpen,
            Key.includeReferenceRootsInResources,
            Key.resourceSearchMatchesNestedItems
        ]
    }

    private func set(_ value: Any, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    private static func bool(forKey key: String, defaultValue: Bool, defaults: UserDefaults) -> Bool {
        defaults.object(forKey: key) == nil ? defaultValue : defaults.bool(forKey: key)
    }

    private static func integer(forKey key: String, defaultValue: Int, defaults: UserDefaults) -> Int {
        defaults.object(forKey: key) == nil ? defaultValue : defaults.integer(forKey: key)
    }

    private static func enumValue<T: RawRepresentable>(forKey key: String, defaultValue: T, defaults: UserDefaults) -> T where T.RawValue == String {
        guard let rawValue = defaults.string(forKey: key), let value = T(rawValue: rawValue) else {
            return defaultValue
        }
        return value
    }
}
