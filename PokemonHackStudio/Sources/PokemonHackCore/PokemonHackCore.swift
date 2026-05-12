import Foundation

public struct HackProject: Codable, Equatable {
    public let root: SourceLocation
    public let profile: GameProfile
    public let editorModules: [EditorModule]
    public let issues: [ValidationIssue]

    public init(
        root: SourceLocation,
        profile: GameProfile,
        editorModules: [EditorModule],
        issues: [ValidationIssue] = []
    ) {
        self.root = root
        self.profile = profile
        self.editorModules = editorModules
        self.issues = issues
    }
}

public enum GameProfile: String, Codable, Equatable, CaseIterable, Sendable {
    case pokeemerald
    case pokefirered
    case pokeruby
    case pokeemeraldExpansion
    case binaryROM
    case ndsROM
    case pokediamond
    case pokeplatinum
    case pokeheartgold
    case pmdSky
    case pokemonColosseum
    case pokemonXD
    case pokemonBox
    case pokemonChannel
    case gameCubeMedia
    case unknown
}

public enum GamePlatform: String, Codable, Equatable, CaseIterable, Sendable {
    case gba
    case nds
    case gameCube
    case unknown
}

public enum ProjectKind: String, Codable, Equatable, CaseIterable, Sendable {
    case sourceTree
    case binaryROM
    case discImage
    case unknown
}

public extension GameProfile {
    var platform: GamePlatform {
        switch self {
        case .pokeemerald, .pokefirered, .pokeruby, .pokeemeraldExpansion, .binaryROM:
            return .gba
        case .ndsROM, .pokediamond, .pokeplatinum, .pokeheartgold, .pmdSky:
            return .nds
        case .pokemonColosseum, .pokemonXD, .pokemonBox, .pokemonChannel, .gameCubeMedia:
            return .gameCube
        case .unknown:
            return .unknown
        }
    }

    var projectKind: ProjectKind {
        switch self {
        case .pokeemerald, .pokefirered, .pokeruby, .pokeemeraldExpansion,
             .pokediamond, .pokeplatinum, .pokeheartgold, .pmdSky:
            return .sourceTree
        case .binaryROM, .ndsROM:
            return .binaryROM
        case .pokemonColosseum, .pokemonXD, .pokemonBox, .pokemonChannel, .gameCubeMedia:
            return .discImage
        case .unknown:
            return .unknown
        }
    }
}

public struct SourceLocation: Codable, Equatable {
    public let path: String
    public let exists: Bool

    public init(path: String, exists: Bool) {
        self.path = path
        self.exists = exists
    }
}

public struct ReferenceRepo: Codable, Equatable {
    public let name: String
    public let path: String
    public let url: String?
    public let description: String?
    public let modules: [EditorModule]
    public let branch: String?
    public let head: String?
    public let license: String?
    public let risk: String?

    public init(
        name: String,
        path: String,
        url: String? = nil,
        description: String? = nil,
        modules: [EditorModule] = [],
        branch: String? = nil,
        head: String? = nil,
        license: String? = nil,
        risk: String? = nil
    ) {
        self.name = name
        self.path = path
        self.url = url
        self.description = description
        self.modules = modules
        self.branch = branch
        self.head = head
        self.license = license
        self.risk = risk
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case path
        case folder
        case url
        case repoUrl
        case description
        case usage
        case modules
        case branch
        case head
        case license
        case risk
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        path = try container.decodeIfPresent(String.self, forKey: .path)
            ?? container.decode(String.self, forKey: .folder)
        url = try container.decodeIfPresent(String.self, forKey: .url)
            ?? container.decodeIfPresent(String.self, forKey: .repoUrl)
        description = try container.decodeIfPresent(String.self, forKey: .description)
            ?? container.decodeIfPresent(String.self, forKey: .usage)
        modules = try container.decodeIfPresent([EditorModule].self, forKey: .modules)
            ?? Self.inferredModules(for: name)
        branch = try container.decodeIfPresent(String.self, forKey: .branch)
        head = try container.decodeIfPresent(String.self, forKey: .head)
        risk = try container.decodeIfPresent(String.self, forKey: .risk)

        if let licenseText = try? container.decodeIfPresent(String.self, forKey: .license) {
            license = licenseText
        } else {
            license = try container.decodeIfPresent(ReferenceLicense.self, forKey: .license)?.spdx
        }
    }

    private static func inferredModules(for name: String) -> [EditorModule] {
        switch name {
        case "porymap":
            return [.maps, .scripts, .encounters]
        case "poryscript":
            return [.scripts, .text]
        case "porytiles":
            return [.graphics]
        case "rompatcher-js":
            return [.patches, .rom]
        case "mgba":
            return [.playtest, .debugger]
        case "pokeemerald-expansion":
            return [.pokemon, .trainers, .items, .moves, .encounters, .maps, .scripts, .build]
        case "pokeruby":
            return [.pokemon, .trainers, .items, .encounters, .maps, .scripts, .build]
        case "hex-maniac-advance", "pokemon-game-editor":
            return [.maps, .graphics, .pokemon, .trainers, .items, .moves, .rom, .patches]
        default:
            return []
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(path, forKey: .path)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(modules, forKey: .modules)
        try container.encodeIfPresent(branch, forKey: .branch)
        try container.encodeIfPresent(head, forKey: .head)
        try container.encodeIfPresent(license, forKey: .license)
        try container.encodeIfPresent(risk, forKey: .risk)
    }
}

public struct ReferenceLicense: Codable, Equatable {
    public let spdx: String
    public let notes: String?
}

public enum EditorModule: String, Codable, Equatable, CaseIterable {
    case maps
    case scripts
    case graphics
    case pokemon
    case trainers
    case items
    case moves
    case encounters
    case text
    case build
    case patches
    case playtest
    case debugger
    case diagnostics
    case rom
    case unknown

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = EditorModule(rawValue: rawValue) ?? .unknown
    }
}

public struct ValidationIssue: Codable, Equatable {
    public enum Severity: String, Codable {
        case warning
        case error
    }

    public let severity: Severity
    public let message: String
    public let location: SourceLocation?

    public init(severity: Severity, message: String, location: SourceLocation? = nil) {
        self.severity = severity
        self.message = message
        self.location = location
    }
}

public enum PokemonHackCoreError: Error, Equatable, LocalizedError {
    case pathNotFound(String)
    case unsupportedProject(String)
    case referenceManifestNotFound([String])
    case manifestDecodeFailed(String)

    public var errorDescription: String? {
        switch self {
        case .pathNotFound(let path):
            return "Path does not exist: \(path)"
        case .unsupportedProject(let path):
            return "No supported Pokemon decomp project found at: \(path)"
        case .referenceManifestNotFound(let searchedPaths):
            return "Reference manifest not found. Searched: \(searchedPaths.joined(separator: ", "))"
        case .manifestDecodeFailed(let message):
            return "Reference manifest could not be decoded: \(message)"
        }
    }
}

public struct ReferenceManifest: Codable, Equatable {
    public let repositories: [ReferenceRepo]

    public init(repositories: [ReferenceRepo]) {
        self.repositories = repositories
    }

    private enum CodingKeys: String, CodingKey {
        case repositories
        case references
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        repositories = try container.decodeIfPresent([ReferenceRepo].self, forKey: .repositories)
            ?? container.decode([ReferenceRepo].self, forKey: .references)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(repositories, forKey: .repositories)
    }
}

public enum ProjectInspector {
    public static func inspect(path: String, fileManager: FileManager = .default) throws -> HackProject {
        let root = URL(fileURLWithPath: path).standardizedFileURL
        guard fileManager.fileExists(atPath: root.path) else {
            throw PokemonHackCoreError.pathNotFound(root.path)
        }

        let profile = try detectProfile(at: root, fileManager: fileManager)
        guard profile != .unknown else {
            throw PokemonHackCoreError.unsupportedProject(root.path)
        }

        return HackProject(
            root: SourceLocation(path: root.path, exists: true),
            profile: profile,
            editorModules: modulesAvailable(at: root, fileManager: fileManager),
            issues: validationIssues(at: root, profile: profile, fileManager: fileManager)
        )
    }

    public static func detectProfile(at root: URL, fileManager: FileManager = .default) throws -> GameProfile {
        guard fileManager.fileExists(atPath: root.path) else {
            throw PokemonHackCoreError.pathNotFound(root.path)
        }

        if GameCubeDiscParser.isSupportedDiscImage(root) {
            return GameCubeDiscParser.detectProfile(at: root, fileManager: fileManager)
        }

        if NDSROMAdapter.isSupportedROM(root, fileManager: fileManager) {
            return .ndsROM
        }

        if BinaryROMAdapter.isSupportedROM(root, fileManager: fileManager) {
            return .binaryROM
        }

        if let ndsDecompProfile = NDSDecompSourceTreeIndexBuilder.detectProfile(at: root, fileManager: fileManager) {
            return ndsDecompProfile
        }

        guard hasRequiredProjectSkeleton(at: root, fileManager: fileManager) else {
            return .unknown
        }

        let makefileText = readTextIfPresent(root.appendingPathComponent("Makefile"))
        let configText = readTextIfPresent(root.appendingPathComponent("config.mk"))
        let sha1Files = sha1FileNames(at: root, fileManager: fileManager)

        if hasExpansionAnchors(at: root, fileManager: fileManager) {
            return .pokeemeraldExpansion
        }

        if makefileText.contains("pokeruby.gba")
            || makefileText.contains("pokesapphire.gba")
            || makefileText.contains("GAME_VERSION=RUBY")
            || makefileText.contains("GAME_VERSION=SAPPHIRE")
            || configText.contains("GAME_VERSION  ?= RUBY")
            || configText.contains("GAME_VERSION ?= RUBY")
            || fileManager.fileExists(atPath: root.appendingPathComponent("ruby.sha1").path)
            || fileManager.fileExists(atPath: root.appendingPathComponent("sapphire.sha1").path) {
            return .pokeruby
        }

        if makefileText.contains("poke$(BUILD_NAME).gba")
            || sha1Files.contains(where: { $0.contains("firered") || $0.contains("leafgreen") })
            || directoryExists(root.appendingPathComponent("graphics/quest_log"), fileManager: fileManager) {
            return .pokefirered
        }

        if makefileText.contains("POKEMON EMER")
            || makefileText.contains("BPEE")
            || sha1Files.contains("rom.sha1")
            || directoryExists(root.appendingPathComponent("graphics/pokenav"), fileManager: fileManager) {
            return .pokeemerald
        }

        return .unknown
    }

    private static func hasRequiredProjectSkeleton(at root: URL, fileManager: FileManager) -> Bool {
        fileManager.fileExists(atPath: root.appendingPathComponent("Makefile").path)
            && fileManager.fileExists(atPath: root.appendingPathComponent("data/maps/map_groups.json").path)
            && directoryExists(root.appendingPathComponent("src"), fileManager: fileManager)
            && directoryExists(root.appendingPathComponent("include"), fileManager: fileManager)
            && directoryExists(root.appendingPathComponent("graphics"), fileManager: fileManager)
    }

    private static func modulesAvailable(at root: URL, fileManager: FileManager) -> [EditorModule] {
        if NDSDecompSourceTreeIndexBuilder.detectProfile(at: root, fileManager: fileManager) != nil {
            return [.rom, .build, .diagnostics]
        }

        var modules: [EditorModule] = []
        if fileManager.fileExists(atPath: root.appendingPathComponent("data/maps/map_groups.json").path) {
            modules.append(.maps)
        }
        if directoryExists(root.appendingPathComponent("data/scripts"), fileManager: fileManager) {
            modules.append(.scripts)
        }
        if directoryExists(root.appendingPathComponent("graphics"), fileManager: fileManager) {
            modules.append(.graphics)
        }
        if directoryExists(root.appendingPathComponent("graphics/pokemon"), fileManager: fileManager) {
            modules.append(.pokemon)
        }
        if directoryExists(root.appendingPathComponent("graphics/trainers"), fileManager: fileManager) {
            modules.append(.trainers)
        }
        if directoryExists(root.appendingPathComponent("graphics/items"), fileManager: fileManager) {
            modules.append(.items)
        }
        if fileManager.fileExists(atPath: root.appendingPathComponent("src/data/moves_info.h").path)
            || fileManager.fileExists(atPath: root.appendingPathComponent("src/data/moves.h").path) {
            modules.append(.moves)
        }
        if fileManager.fileExists(atPath: root.appendingPathComponent("src/data/wild_encounters.json").path) {
            modules.append(.encounters)
        }
        if directoryExists(root.appendingPathComponent("data/text"), fileManager: fileManager) {
            modules.append(.text)
        }
        if NDSROMAdapter.isSupportedROM(root, fileManager: fileManager) {
            modules.append(.rom)
        } else if NDSDecompSourceTreeIndexBuilder.detectProfile(at: root, fileManager: fileManager) != nil {
            modules.append(.rom)
        } else if GameCubeDiscParser.isSupportedDiscImage(root)
            || BinaryROMAdapter.isSupportedROM(root, fileManager: fileManager) {
            modules.append(.rom)
            modules.append(.patches)
            modules.append(.playtest)
        }
        modules.append(.build)
        modules.append(.diagnostics)
        return modules
    }

    private static func validationIssues(at root: URL, profile: GameProfile, fileManager: FileManager) -> [ValidationIssue] {
        if profile.platform != .gba || profile.projectKind != .sourceTree {
            return []
        }

        let requiredPaths = [
            "Makefile",
            "data/maps/map_groups.json"
        ]
        return requiredPaths.compactMap { (relativePath: String) -> ValidationIssue? in
            let url = root.appendingPathComponent(relativePath)
            guard !fileManager.fileExists(atPath: url.path) else {
                return nil
            }
            return ValidationIssue(
                severity: .warning,
                message: "Missing \(relativePath)",
                location: SourceLocation(path: url.path, exists: false)
            )
        }
    }

    private static func sha1FileNames(at root: URL, fileManager: FileManager) -> [String] {
        guard let contents = try? fileManager.contentsOfDirectory(atPath: root.path) else {
            return []
        }
        return contents.filter { $0.hasSuffix(".sha1") }
    }

    private static func readTextIfPresent(_ url: URL) -> String {
        (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    private static func directoryExists(_ url: URL, fileManager: FileManager) -> Bool {
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private static func hasExpansionAnchors(at root: URL, fileManager: FileManager) -> Bool {
        fileManager.fileExists(atPath: root.appendingPathComponent("include/constants/expansion.h").path)
            || fileManager.fileExists(atPath: root.appendingPathComponent("src/rom_header_rhh.c").path)
            || fileManager.fileExists(atPath: root.appendingPathComponent("src/data/trainers.party").path)
    }
}

public enum ReferenceManifestLoader {
    public static func load(
        from startPath: String = FileManager.default.currentDirectoryPath,
        fileManager: FileManager = .default
    ) throws -> ReferenceManifest {
        let start = URL(fileURLWithPath: startPath).standardizedFileURL
        let candidates = manifestCandidates(startingAt: start)
        for candidate in candidates where fileManager.fileExists(atPath: candidate.path) {
            do {
                let data = try Data(contentsOf: candidate)
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode(ReferenceManifest.self, from: data)
            } catch let error as DecodingError {
                throw PokemonHackCoreError.manifestDecodeFailed(String(describing: error))
            } catch {
                throw PokemonHackCoreError.manifestDecodeFailed(error.localizedDescription)
            }
        }
        throw PokemonHackCoreError.referenceManifestNotFound(candidates.map(\.path))
    }

    public static func manifestCandidates(startingAt start: URL) -> [URL] {
        var candidates: [URL] = []
        var seen: Set<String> = []

        func append(_ url: URL) {
            let standardized = url.standardizedFileURL
            guard !seen.contains(standardized.path) else {
                return
            }
            seen.insert(standardized.path)
            candidates.append(standardized)
        }

        var current: URL? = start
        while let directory = current {
            append(directory.appendingPathComponent("references/manifest.json"))
            append(directory.appendingPathComponent("../references/manifest.json"))

            let parent = directory.deletingLastPathComponent()
            current = parent.path == directory.path ? nil : parent
        }

        return candidates
    }
}
