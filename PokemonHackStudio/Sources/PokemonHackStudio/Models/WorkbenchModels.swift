import Foundation

enum WorkbenchModule: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case maps = "Maps"
    case trainers = "Trainers"
    case items = "Items"
    case pokemon = "Pokemon"
    case encounters = "Encounters"
    case scripts = "Scripts"
    case text = "Text"
    case build = "Build"
    case issues = "Issues"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .maps: "map"
        case .trainers: "person.2"
        case .items: "shippingbox"
        case .pokemon: "sparkles"
        case .encounters: "leaf"
        case .scripts: "curlybraces"
        case .text: "text.quote"
        case .build: "hammer"
        case .issues: "exclamationmark.triangle"
        }
    }

    var subtitle: String {
        switch self {
        case .dashboard: "Project health"
        case .maps: "Layouts, events, warps"
        case .trainers: "Parties and AI flags"
        case .items: "Prices and field effects"
        case .pokemon: "Species tables"
        case .encounters: "Wild slots"
        case .scripts: "Event scripts"
        case .text: "Message tables"
        case .build: "Targets and artifacts"
        case .issues: "Validation queue"
        }
    }
}

enum ValidationState: String, Identifiable {
    case valid = "Valid"
    case warning = "Warning"
    case error = "Error"

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
