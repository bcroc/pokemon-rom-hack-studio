import Foundation

public struct SavedDraftCounts: Codable, Equatable {
    public let species: Int
    public let trainers: Int
    public let moves: Int
    public let items: Int
    public let maps: Int
    public let graphics: Int
    public let ndsData: Int

    public init(species: Int, trainers: Int, moves: Int, items: Int, maps: Int, graphics: Int = 0, ndsData: Int = 0) {
        self.species = species
        self.trainers = trainers
        self.moves = moves
        self.items = items
        self.maps = maps
        self.graphics = graphics
        self.ndsData = ndsData
    }

    public var total: Int {
        species + trainers + moves + items + maps + graphics + ndsData
    }
}

public struct SavedMapDraftSnapshot: Codable, Equatable, Identifiable {
    public var id: String { "\(documentID)::\(mapID)" }

    public let mapID: String
    public let documentID: String
    public let operations: [MapEditOperation]

    public init(mapID: String, documentID: String, operations: [MapEditOperation]) {
        self.mapID = mapID
        self.documentID = documentID
        self.operations = operations
    }
}

public struct SavedDraftSnapshot: Codable, Equatable {
    public let speciesDrafts: [SpeciesEditDraft]
    public let trainerDrafts: [TrainerEditDraft]
    public let moveDrafts: [MoveEditDraft]
    public let itemDrafts: [ItemEditDraft]
    public let mapDrafts: [SavedMapDraftSnapshot]
    public let graphicsDrafts: [GraphicsEditDraft]
    public let ndsDataDrafts: [NDSDataEditDraft]

    public init(
        speciesDrafts: [SpeciesEditDraft] = [],
        trainerDrafts: [TrainerEditDraft] = [],
        moveDrafts: [MoveEditDraft] = [],
        itemDrafts: [ItemEditDraft] = [],
        mapDrafts: [SavedMapDraftSnapshot] = [],
        graphicsDrafts: [GraphicsEditDraft] = [],
        ndsDataDrafts: [NDSDataEditDraft] = []
    ) {
        self.speciesDrafts = speciesDrafts
        self.trainerDrafts = trainerDrafts
        self.moveDrafts = moveDrafts
        self.itemDrafts = itemDrafts
        self.mapDrafts = mapDrafts
        self.graphicsDrafts = graphicsDrafts
        self.ndsDataDrafts = ndsDataDrafts
    }

    private enum CodingKeys: String, CodingKey {
        case speciesDrafts
        case trainerDrafts
        case moveDrafts
        case itemDrafts
        case mapDrafts
        case graphicsDrafts
        case ndsDataDrafts
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        speciesDrafts = try container.decodeIfPresent([SpeciesEditDraft].self, forKey: .speciesDrafts) ?? []
        trainerDrafts = try container.decodeIfPresent([TrainerEditDraft].self, forKey: .trainerDrafts) ?? []
        moveDrafts = try container.decodeIfPresent([MoveEditDraft].self, forKey: .moveDrafts) ?? []
        itemDrafts = try container.decodeIfPresent([ItemEditDraft].self, forKey: .itemDrafts) ?? []
        mapDrafts = try container.decodeIfPresent([SavedMapDraftSnapshot].self, forKey: .mapDrafts) ?? []
        graphicsDrafts = try container.decodeIfPresent([GraphicsEditDraft].self, forKey: .graphicsDrafts) ?? []
        ndsDataDrafts = try container.decodeIfPresent([NDSDataEditDraft].self, forKey: .ndsDataDrafts) ?? []
    }

    public var counts: SavedDraftCounts {
        SavedDraftCounts(
            species: speciesDrafts.count,
            trainers: trainerDrafts.count,
            moves: moveDrafts.count,
            items: itemDrafts.count,
            maps: mapDrafts.count,
            graphics: graphicsDrafts.count,
            ndsData: ndsDataDrafts.count
        )
    }

    public var isEmpty: Bool {
        counts.total == 0
    }
}

public struct SavedHackWorkspace: Codable, Equatable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let savedAt: Date
    public let projectRootPath: String
    public let projectTitle: String
    public let profile: GameProfile
    public let adapterID: String
    public let selectedModule: String?
    public let selectedMapID: String?
    public let selectedSpeciesID: String?
    public let selectedTrainerID: String?
    public let selectedMoveID: String?
    public let selectedItemID: String?
    public let drafts: SavedDraftSnapshot

    public init(
        schemaVersion: Int = Self.currentSchemaVersion,
        savedAt: Date = Date(),
        projectRootPath: String,
        projectTitle: String,
        profile: GameProfile,
        adapterID: String,
        selectedModule: String? = nil,
        selectedMapID: String? = nil,
        selectedSpeciesID: String? = nil,
        selectedTrainerID: String? = nil,
        selectedMoveID: String? = nil,
        selectedItemID: String? = nil,
        drafts: SavedDraftSnapshot = SavedDraftSnapshot()
    ) {
        self.schemaVersion = schemaVersion
        self.savedAt = savedAt
        self.projectRootPath = projectRootPath
        self.projectTitle = projectTitle
        self.profile = profile
        self.adapterID = adapterID
        self.selectedModule = selectedModule
        self.selectedMapID = selectedMapID
        self.selectedSpeciesID = selectedSpeciesID
        self.selectedTrainerID = selectedTrainerID
        self.selectedMoveID = selectedMoveID
        self.selectedItemID = selectedItemID
        self.drafts = drafts
    }
}

public enum ProjectWorkspacePersistenceError: Error, Equatable, LocalizedError {
    case unsupportedSchemaVersion(Int)
    case unsafeWorkspacePath(code: String, message: String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedSchemaVersion(let version):
            "Unsupported PokemonHackStudio workspace schema version: \(version)."
        case .unsafeWorkspacePath(_, let message):
            message
        }
    }
}

public enum ProjectWorkspacePersistence {
    public static let workspaceDirectoryName = ".pokemonhackstudio"
    public static let projectRelativePath = ".pokemonhackstudio/project.json"
    public static let autosaveRelativePath = ".pokemonhackstudio/drafts/autosave.json"

    public static func projectFileURL(root: URL) -> URL {
        root.standardizedFileURL.appendingPathComponent(projectRelativePath)
    }

    public static func autosaveFileURL(root: URL) -> URL {
        root.standardizedFileURL.appendingPathComponent(autosaveRelativePath)
    }

    public static func saveProject(
        _ workspace: SavedHackWorkspace,
        root: URL,
        fileManager: FileManager = .default
    ) throws {
        let url = try validatedWorkspaceFileURL(relativePath: projectRelativePath, root: root, fileManager: fileManager)
        try save(workspace, to: url, fileManager: fileManager)
    }

    public static func loadProject(
        root: URL,
        fileManager: FileManager = .default
    ) throws -> SavedHackWorkspace? {
        let url = try validatedWorkspaceFileURL(relativePath: projectRelativePath, root: root, fileManager: fileManager)
        return try load(from: url, fileManager: fileManager)
    }

    public static func saveAutosave(
        _ workspace: SavedHackWorkspace,
        root: URL,
        fileManager: FileManager = .default
    ) throws {
        let url = try validatedWorkspaceFileURL(relativePath: autosaveRelativePath, root: root, fileManager: fileManager)
        try save(workspace, to: url, fileManager: fileManager)
    }

    public static func loadAutosave(
        root: URL,
        fileManager: FileManager = .default
    ) throws -> SavedHackWorkspace? {
        let url = try validatedWorkspaceFileURL(relativePath: autosaveRelativePath, root: root, fileManager: fileManager)
        return try load(from: url, fileManager: fileManager)
    }

    public static func discardAutosave(root: URL, fileManager: FileManager = .default) throws {
        let url = try validatedWorkspaceFileURL(relativePath: autosaveRelativePath, root: root, fileManager: fileManager)
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    private static func validatedWorkspaceFileURL(
        relativePath: String,
        root: URL,
        fileManager: FileManager
    ) throws -> URL {
        let standardizedRoot = root.standardizedFileURL
        let diagnostics = SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
            relativePath,
            root: standardizedRoot,
            fileManager: fileManager,
            codePrefix: "WORKSPACE",
            subject: "PokemonHackStudio workspace path"
        )
        if let diagnostic = diagnostics.first(where: { $0.severity == .error }) {
            throw ProjectWorkspacePersistenceError.unsafeWorkspacePath(
                code: diagnostic.code,
                message: diagnostic.message
            )
        }
        return standardizedRoot.appendingPathComponent(relativePath).standardizedFileURL
    }

    private static func save(
        _ workspace: SavedHackWorkspace,
        to url: URL,
        fileManager: FileManager
    ) throws {
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(workspace)
        try data.write(to: url, options: .atomic)
    }

    private static func load(from url: URL, fileManager: FileManager) throws -> SavedHackWorkspace? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let workspace = try decoder.decode(SavedHackWorkspace.self, from: data)
        guard workspace.schemaVersion == SavedHackWorkspace.currentSchemaVersion else {
            throw ProjectWorkspacePersistenceError.unsupportedSchemaVersion(workspace.schemaVersion)
        }
        return workspace
    }
}
