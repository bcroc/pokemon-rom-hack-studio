import Foundation

public enum DiagnosticSeverity: String, Codable, Equatable, CaseIterable {
    case info
    case warning
    case error
}

public struct SourceSpan: Codable, Equatable, Sendable {
    public let relativePath: String
    public let startLine: Int
    public let startColumn: Int
    public let endLine: Int
    public let endColumn: Int

    public init(
        relativePath: String,
        startLine: Int,
        startColumn: Int = 1,
        endLine: Int? = nil,
        endColumn: Int? = nil
    ) {
        self.relativePath = relativePath
        self.startLine = startLine
        self.startColumn = startColumn
        self.endLine = endLine ?? startLine
        self.endColumn = endColumn ?? startColumn
    }
}

public enum SourceKind: String, Codable, Equatable, CaseIterable {
    case assembly
    case binary
    case cHeader
    case cSource
    case configuration
    case generated
    case graphics
    case json
    case layoutJson
    case makefile
    case mapJson
    case palette
    case rom
    case script
    case text
    case unknown
}

public enum SourceRole: String, Codable, Equatable, CaseIterable {
    case source
    case generated
    case artifact
    case reference
    case localInput
}

public struct SourceDocument: Codable, Equatable, Identifiable {
    public var id: String { relativePath }

    public let relativePath: String
    public let kind: SourceKind
    public let role: SourceRole
    public let exists: Bool
    public let preservesUnknownFields: Bool

    public init(
        relativePath: String,
        kind: SourceKind,
        role: SourceRole = .source,
        exists: Bool,
        preservesUnknownFields: Bool = false
    ) {
        self.relativePath = relativePath
        self.kind = kind
        self.role = role
        self.exists = exists
        self.preservesUnknownFields = preservesUnknownFields
    }
}

public struct Diagnostic: Codable, Equatable, Identifiable {
    public let id: String
    public let severity: DiagnosticSeverity
    public let code: String
    public let message: String
    public let span: SourceSpan?

    public init(
        id: String = UUID().uuidString,
        severity: DiagnosticSeverity,
        code: String,
        message: String,
        span: SourceSpan? = nil
    ) {
        self.id = id
        self.severity = severity
        self.code = code
        self.message = message
        self.span = span
    }
}

public enum WritePolicy: String, Codable, Equatable, CaseIterable {
    case readOnly
    case mutationPlanOnly
    case explicitApply
    case generatedArtifactOnly
}

public struct PlannedChange: Codable, Equatable, Identifiable {
    public let id: String
    public let path: String
    public let summary: String
    public let span: SourceSpan?

    public init(id: String = UUID().uuidString, path: String, summary: String, span: SourceSpan? = nil) {
        self.id = id
        self.path = path
        self.summary = summary
        self.span = span
    }
}

public struct MutationPlan: Codable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let summary: String
    public let changes: [PlannedChange]
    public let diagnostics: [Diagnostic]
    public let requiresExplicitApply: Bool

    public init(
        id: String = UUID().uuidString,
        title: String,
        summary: String,
        changes: [PlannedChange] = [],
        diagnostics: [Diagnostic] = [],
        requiresExplicitApply: Bool = true
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.changes = changes
        self.diagnostics = diagnostics
        self.requiresExplicitApply = requiresExplicitApply
    }
}

public enum CoreCapability: String, Codable, Equatable, CaseIterable {
    case resourceIndex
    case mapIndex
    case layoutIndex
    case scriptOutline
    case trainerEditor
    case speciesEditor
    case binaryROMGraph
    case patchPlanning
    case buildRunner
    case playtestBridge
    case diagnostics
}

public enum BuildTargetKind: String, Codable, Equatable, CaseIterable {
    case build
    case generated
    case test
    case debug
    case release
}

public struct BuildTarget: Codable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let kind: BuildTargetKind
    public let command: [String]
    public let outputPath: String?

    public init(id: String, name: String, kind: BuildTargetKind, command: [String], outputPath: String? = nil) {
        self.id = id
        self.name = name
        self.kind = kind
        self.command = command
        self.outputPath = outputPath
    }
}

public enum PlaytestMode: String, Codable, Equatable, CaseIterable {
    case interactive
    case headless
}

public struct PlaytestSession: Codable, Equatable, Identifiable {
    public let id: String
    public let mode: PlaytestMode
    public let emulator: String
    public let romPath: String?
    public let arguments: [String]
    public let artifacts: [PlaytestSessionArtifact]
    public let isRunnable: Bool
    public let diagnostics: [Diagnostic]

    public init(
        id: String = UUID().uuidString,
        mode: PlaytestMode,
        emulator: String = "mGBA",
        romPath: String?,
        arguments: [String] = [],
        artifacts: [PlaytestSessionArtifact] = [],
        isRunnable: Bool = false,
        diagnostics: [Diagnostic] = []
    ) {
        self.id = id
        self.mode = mode
        self.emulator = emulator
        self.romPath = romPath
        self.arguments = arguments
        self.artifacts = artifacts
        self.isRunnable = isRunnable
        self.diagnostics = diagnostics
    }
}

public enum PlaytestSessionArtifactKind: String, Codable, Equatable, CaseIterable {
    case runLog
    case screenshot
    case saveState
    case stdout
    case stderr
}

public struct PlaytestSessionArtifact: Codable, Equatable, Identifiable {
    public var id: String { "\(kind.rawValue):\(relativePath)" }

    public let kind: PlaytestSessionArtifactKind
    public let relativePath: String
    public let isExpected: Bool
    public let exists: Bool
    public let detail: String

    public init(
        kind: PlaytestSessionArtifactKind,
        relativePath: String,
        isExpected: Bool = true,
        exists: Bool = false,
        detail: String
    ) {
        self.kind = kind
        self.relativePath = relativePath
        self.isExpected = isExpected
        self.exists = exists
        self.detail = detail
    }
}

public struct ProjectIndex: Codable, Equatable {
    public let root: SourceLocation
    public let profile: GameProfile
    public let adapterID: String
    public let adapterName: String
    public let editorModules: [EditorModule]
    public let capabilities: [CoreCapability]
    public let writePolicy: WritePolicy
    public let documents: [SourceDocument]
    public let generatedOutputs: [SourceDocument]
    public let diagnostics: [Diagnostic]
    public let buildTargets: [BuildTarget]

    public init(
        root: SourceLocation,
        profile: GameProfile,
        adapterID: String,
        adapterName: String,
        editorModules: [EditorModule],
        capabilities: [CoreCapability],
        writePolicy: WritePolicy,
        documents: [SourceDocument],
        generatedOutputs: [SourceDocument] = [],
        diagnostics: [Diagnostic] = [],
        buildTargets: [BuildTarget] = []
    ) {
        self.root = root
        self.profile = profile
        self.adapterID = adapterID
        self.adapterName = adapterName
        self.editorModules = editorModules
        self.capabilities = capabilities
        self.writePolicy = writePolicy
        self.documents = documents
        self.generatedOutputs = generatedOutputs
        self.diagnostics = diagnostics
        self.buildTargets = buildTargets
    }
}

public protocol GameAdapter {
    var id: String { get }
    var displayName: String { get }
    var supportedProfiles: [GameProfile] { get }
    var supportedModules: [EditorModule] { get }
    var capabilities: [CoreCapability] { get }
    var writePolicy: WritePolicy { get }

    func canOpen(root: URL, fileManager: FileManager) -> Bool
    func index(root: URL, fileManager: FileManager) throws -> ProjectIndex
}

public struct EmeraldAdapter: GameAdapter {
    public let id = "pret.pokeemerald"
    public let displayName = "pokeemerald"
    public let supportedProfiles: [GameProfile] = [.pokeemerald]
    public let supportedModules: [EditorModule] = [.maps, .scripts, .graphics, .pokemon, .trainers, .items, .encounters, .text, .build]
    public let capabilities: [CoreCapability] = [.resourceIndex, .mapIndex, .layoutIndex, .scriptOutline, .speciesEditor, .trainerEditor, .patchPlanning, .buildRunner, .playtestBridge, .diagnostics]
    public let writePolicy: WritePolicy = .mutationPlanOnly

    public init() {}

    public func canOpen(root: URL, fileManager: FileManager = .default) -> Bool {
        (try? ProjectInspector.detectProfile(at: root, fileManager: fileManager)) == .pokeemerald
    }

    public func index(root: URL, fileManager: FileManager = .default) throws -> ProjectIndex {
        try DecompIndexFactory.makeIndex(
            root: root,
            profile: .pokeemerald,
            adapterID: id,
            adapterName: displayName,
            modules: supportedModules,
            capabilities: capabilities,
            writePolicy: writePolicy,
            documents: DecompIndexFactory.emeraldDocuments(root: root, fileManager: fileManager),
            generatedOutputs: DecompIndexFactory.pretGeneratedOutputs(root: root, fileManager: fileManager),
            buildTargets: [
                BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba"),
                BuildTarget(id: "emerald-debug", name: "Build Debug ROM", kind: .debug, command: ["make", "debug"], outputPath: "pokeemerald.gba")
            ]
        )
    }
}

public struct FireRedAdapter: GameAdapter {
    public let id = "pret.pokefirered"
    public let displayName = "pokefirered"
    public let supportedProfiles: [GameProfile] = [.pokefirered]
    public let supportedModules: [EditorModule] = [.maps, .scripts, .graphics, .pokemon, .trainers, .items, .encounters, .text, .build]
    public let capabilities: [CoreCapability] = [.resourceIndex, .mapIndex, .layoutIndex, .scriptOutline, .speciesEditor, .trainerEditor, .patchPlanning, .buildRunner, .playtestBridge, .diagnostics]
    public let writePolicy: WritePolicy = .mutationPlanOnly

    public init() {}

    public func canOpen(root: URL, fileManager: FileManager = .default) -> Bool {
        (try? ProjectInspector.detectProfile(at: root, fileManager: fileManager)) == .pokefirered
    }

    public func index(root: URL, fileManager: FileManager = .default) throws -> ProjectIndex {
        try DecompIndexFactory.makeIndex(
            root: root,
            profile: .pokefirered,
            adapterID: id,
            adapterName: displayName,
            modules: supportedModules,
            capabilities: capabilities,
            writePolicy: writePolicy,
            documents: DecompIndexFactory.fireRedDocuments(root: root, fileManager: fileManager),
            generatedOutputs: DecompIndexFactory.pretGeneratedOutputs(root: root, fileManager: fileManager),
            buildTargets: [
                BuildTarget(id: "firered-build", name: "Build FireRed", kind: .build, command: ["make", "firered"], outputPath: "pokefirered.gba"),
                BuildTarget(id: "firered-rev1-build", name: "Build FireRed Rev 1", kind: .build, command: ["make", "firered_rev1"], outputPath: "pokefirered_rev1.gba"),
                BuildTarget(id: "firered-switch-build", name: "Build FireRed Switch", kind: .build, command: ["make", "firered_switch"], outputPath: "pokefirered_switch.gba"),
                BuildTarget(id: "leafgreen-build", name: "Build LeafGreen", kind: .build, command: ["make", "leafgreen"], outputPath: "pokeleafgreen.gba"),
                BuildTarget(id: "leafgreen-rev1-build", name: "Build LeafGreen Rev 1", kind: .build, command: ["make", "leafgreen_rev1"], outputPath: "pokeleafgreen_rev1.gba"),
                BuildTarget(id: "leafgreen-switch-build", name: "Build LeafGreen Switch", kind: .build, command: ["make", "leafgreen_switch"], outputPath: "pokeleafgreen_switch.gba")
            ]
        )
    }
}

public struct RubySapphireAdapter: GameAdapter {
    public let id = "pret.pokeruby"
    public let displayName = "pokeruby / pokesapphire"
    public let supportedProfiles: [GameProfile] = [.pokeruby]
    public let supportedModules: [EditorModule] = [.maps, .scripts, .graphics, .pokemon, .trainers, .items, .encounters, .text, .build]
    public let capabilities: [CoreCapability] = [.resourceIndex, .mapIndex, .layoutIndex, .scriptOutline, .speciesEditor, .trainerEditor, .patchPlanning, .buildRunner, .playtestBridge, .diagnostics]
    public let writePolicy: WritePolicy = .mutationPlanOnly

    public init() {}

    public func canOpen(root: URL, fileManager: FileManager = .default) -> Bool {
        (try? ProjectInspector.detectProfile(at: root, fileManager: fileManager)) == .pokeruby
    }

    public func index(root: URL, fileManager: FileManager = .default) throws -> ProjectIndex {
        try DecompIndexFactory.makeIndex(
            root: root,
            profile: .pokeruby,
            adapterID: id,
            adapterName: displayName,
            modules: supportedModules,
            capabilities: capabilities,
            writePolicy: writePolicy,
            documents: DecompIndexFactory.rubyDocuments(root: root, fileManager: fileManager),
            generatedOutputs: DecompIndexFactory.pretGeneratedOutputs(root: root, fileManager: fileManager),
            buildTargets: [
                BuildTarget(id: "ruby-build", name: "Build Ruby", kind: .build, command: ["make", "ruby"], outputPath: "pokeruby.gba"),
                BuildTarget(id: "ruby-rev1-build", name: "Build Ruby Rev 1", kind: .build, command: ["make", "ruby_rev1"], outputPath: "pokeruby_rev1.gba"),
                BuildTarget(id: "ruby-rev2-build", name: "Build Ruby Rev 2", kind: .build, command: ["make", "ruby_rev2"], outputPath: "pokeruby_rev2.gba"),
                BuildTarget(id: "sapphire-build", name: "Build Sapphire", kind: .build, command: ["make", "sapphire"], outputPath: "pokesapphire.gba"),
                BuildTarget(id: "sapphire-rev1-build", name: "Build Sapphire Rev 1", kind: .build, command: ["make", "sapphire_rev1"], outputPath: "pokesapphire_rev1.gba"),
                BuildTarget(id: "sapphire-rev2-build", name: "Build Sapphire Rev 2", kind: .build, command: ["make", "sapphire_rev2"], outputPath: "pokesapphire_rev2.gba"),
                BuildTarget(id: "ruby-de-build", name: "Build Ruby German", kind: .build, command: ["make", "ruby_de"], outputPath: "pokeruby_de.gba"),
                BuildTarget(id: "sapphire-de-build", name: "Build Sapphire German", kind: .build, command: ["make", "sapphire_de"], outputPath: "pokesapphire_de.gba"),
                BuildTarget(id: "ruby-modern", name: "Build Modern", kind: .build, command: ["make", "modern"], outputPath: "pokeruby.gba")
            ]
        )
    }
}

public struct ExpansionAdapter: GameAdapter {
    public let id = "rhh.pokeemerald-expansion"
    public let displayName = "pokeemerald-expansion"
    public let supportedProfiles: [GameProfile] = [.pokeemeraldExpansion]
    public let supportedModules: [EditorModule] = [.maps, .scripts, .graphics, .pokemon, .trainers, .items, .encounters, .text, .build]
    public let capabilities: [CoreCapability] = [.resourceIndex, .mapIndex, .layoutIndex, .scriptOutline, .speciesEditor, .trainerEditor, .patchPlanning, .buildRunner, .playtestBridge, .diagnostics]
    public let writePolicy: WritePolicy = .mutationPlanOnly

    public init() {}

    public func canOpen(root: URL, fileManager: FileManager = .default) -> Bool {
        (try? ProjectInspector.detectProfile(at: root, fileManager: fileManager)) == .pokeemeraldExpansion
    }

    public func index(root: URL, fileManager: FileManager = .default) throws -> ProjectIndex {
        var documents = DecompIndexFactory.expansionDocuments(root: root, fileManager: fileManager)
        documents.append(contentsOf: [
            DecompIndexFactory.document(root: root, "include/constants/expansion.h", .cHeader, fileManager: fileManager),
            DecompIndexFactory.document(root: root, "src/rom_header_rhh.c", .cSource, fileManager: fileManager),
            DecompIndexFactory.document(root: root, "src/data/gimmicks.h", .cHeader, fileManager: fileManager),
            DecompIndexFactory.document(root: root, "src/data/pokemon/form_change_tables.h", .cHeader, fileManager: fileManager),
            DecompIndexFactory.document(root: root, "include/config/battle.h", .configuration, fileManager: fileManager),
            DecompIndexFactory.document(root: root, "include/config/pokemon.h", .configuration, fileManager: fileManager),
            DecompIndexFactory.document(root: root, "include/config/species_enabled.h", .configuration, fileManager: fileManager),
            DecompIndexFactory.document(root: root, "migration_scripts/README.md", .text, fileManager: fileManager),
            DecompIndexFactory.document(root: root, "test/test_runner.c", .cSource, fileManager: fileManager)
        ])

        return try DecompIndexFactory.makeIndex(
            root: root,
            profile: .pokeemeraldExpansion,
            adapterID: id,
            adapterName: displayName,
            modules: supportedModules,
            capabilities: capabilities,
            writePolicy: writePolicy,
            documents: documents,
            generatedOutputs: DecompIndexFactory.pretGeneratedOutputs(root: root, fileManager: fileManager),
            buildTargets: [
                BuildTarget(id: "expansion-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba"),
                BuildTarget(id: "expansion-generated", name: "Refresh Generated Data", kind: .generated, command: ["make", "generated"]),
                BuildTarget(id: "expansion-check", name: "Run Test Suite", kind: .test, command: ["make", "check"])
            ]
        )
    }
}

public struct BinaryROMAdapter: GameAdapter {
    public let id = "gen3.binary-rom"
    public let displayName = "Gen III binary ROM"
    public let supportedProfiles: [GameProfile] = [.binaryROM]
    public let supportedModules: [EditorModule] = [.rom, .patches, .diagnostics]
    public let capabilities: [CoreCapability] = [.resourceIndex, .binaryROMGraph, .patchPlanning, .diagnostics, .playtestBridge]
    public let writePolicy: WritePolicy = .mutationPlanOnly

    public init() {}

    public static func isSupportedROM(_ root: URL, fileManager: FileManager = .default) -> Bool {
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: root.path, isDirectory: &isDirectory)
            && !isDirectory.boolValue
            && root.pathExtension.lowercased() == "gba"
    }

    public func canOpen(root: URL, fileManager: FileManager = .default) -> Bool {
        Self.isSupportedROM(root, fileManager: fileManager)
    }

    public func index(root: URL, fileManager: FileManager = .default) throws -> ProjectIndex {
        guard canOpen(root: root, fileManager: fileManager) else {
            throw PokemonHackCoreError.unsupportedProject(root.path)
        }

        let document = SourceDocument(
            relativePath: root.lastPathComponent,
            kind: .rom,
            role: .localInput,
            exists: true
        )

        return ProjectIndex(
            root: SourceLocation(path: root.path, exists: true),
            profile: .binaryROM,
            adapterID: id,
            adapterName: displayName,
            editorModules: supportedModules,
            capabilities: capabilities,
            writePolicy: writePolicy,
            documents: [document],
            diagnostics: [
                Diagnostic(
                    severity: .info,
                    code: "ROM_READ_ONLY",
                    message: "Binary ROM workflows are staged as patch plans before export."
                )
            ]
        )
    }
}

public struct GameCubeDiscAdapter: GameAdapter {
    public let id = "gen3.gamecube-disc"
    public let displayName = "Generation III GameCube disc"
    public let supportedProfiles: [GameProfile] = [.pokemonColosseum, .pokemonXD, .pokemonBox, .pokemonChannel, .gameCubeMedia]
    public let supportedModules: [EditorModule] = [.rom, .graphics, .pokemon, .trainers, .items, .moves, .text, .diagnostics]
    public let capabilities: [CoreCapability] = [.resourceIndex, .diagnostics]
    public let writePolicy: WritePolicy = .mutationPlanOnly

    public init() {}

    public func canOpen(root: URL, fileManager: FileManager = .default) -> Bool {
        GameCubeDiscParser.isSupportedDiscImage(root, fileManager: fileManager)
    }

    public func index(root: URL, fileManager: FileManager = .default) throws -> ProjectIndex {
        let disc = GameCubeDiscParser.parse(path: root.path, fileManager: fileManager)
        guard disc.header != nil || disc.profile != .unknown else {
            throw PokemonHackCoreError.unsupportedProject(root.path)
        }

        let documentCap = 256
        let documents = disc.resources.prefix(documentCap).map { resource in
            SourceDocument(
                relativePath: resource.path,
                kind: sourceKind(for: resource),
                role: .localInput,
                exists: true
            )
        }
        var diagnostics = disc.diagnostics
        if disc.resources.count > documents.count {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "GAMECUBE_RESOURCE_DOCUMENT_CAP",
                    message: "Indexed \(documents.count) of \(disc.resources.count) GameCube resources as ProjectIndex documents; use resource-index for the full parser report."
                )
            )
        }

        return ProjectIndex(
            root: SourceLocation(path: root.standardizedFileURL.path, exists: true),
            profile: disc.profile,
            adapterID: id,
            adapterName: adapterName(for: disc.profile),
            editorModules: supportedModules,
            capabilities: capabilities,
            writePolicy: writePolicy,
            documents: documents.isEmpty ? [
                SourceDocument(relativePath: root.lastPathComponent, kind: .rom, role: .localInput, exists: true)
            ] : documents,
            diagnostics: diagnostics,
            buildTargets: []
        )
    }

    private func adapterName(for profile: GameProfile) -> String {
        switch profile {
        case .pokemonColosseum:
            "Pokemon Colosseum disc"
        case .pokemonXD:
            "Pokemon XD disc"
        case .pokemonBox:
            "Pokemon Box disc"
        case .pokemonChannel:
            "Pokemon Channel disc"
        default:
            displayName
        }
    }

    private func sourceKind(for resource: GameCubeResource) -> SourceKind {
        switch resource.kind {
        case .filesystem, .archive, .archiveMember, .dol:
            .binary
        case .text:
            .text
        case .pokemonTable, .trainerTable, .itemTable, .moveTable:
            .configuration
        case .model, .texture:
            .graphics
        case .audio:
            .binary
        case .unknown:
            .unknown
        }
    }
}

public enum GameAdapterRegistry {
    public static var all: [any GameAdapter] {
        [
            GameCubeDiscAdapter(),
            ExpansionAdapter(),
            RubySapphireAdapter(),
            FireRedAdapter(),
            EmeraldAdapter(),
            BinaryROMAdapter()
        ]
    }

    public static func adapter(for path: String, fileManager: FileManager = .default) throws -> (any GameAdapter)? {
        let root = URL(fileURLWithPath: path).standardizedFileURL
        guard fileManager.fileExists(atPath: root.path) else {
            throw PokemonHackCoreError.pathNotFound(root.path)
        }
        return all.first { $0.canOpen(root: root, fileManager: fileManager) }
    }

    public static func index(path: String, fileManager: FileManager = .default) throws -> ProjectIndex {
        let root = URL(fileURLWithPath: path).standardizedFileURL
        guard let adapter = try adapter(for: root.path, fileManager: fileManager) else {
            throw PokemonHackCoreError.unsupportedProject(root.path)
        }
        return try adapter.index(root: root, fileManager: fileManager)
    }
}

enum DecompIndexFactory {
    static func makeIndex(
        root: URL,
        profile: GameProfile,
        adapterID: String,
        adapterName: String,
        modules: [EditorModule],
        capabilities: [CoreCapability],
        writePolicy: WritePolicy,
        documents: [SourceDocument],
        generatedOutputs: [SourceDocument],
        buildTargets: [BuildTarget]
    ) throws -> ProjectIndex {
        let diagnostics = missingDocumentDiagnostics(documents)
        return ProjectIndex(
            root: SourceLocation(path: root.standardizedFileURL.path, exists: true),
            profile: profile,
            adapterID: adapterID,
            adapterName: adapterName,
            editorModules: modules,
            capabilities: capabilities,
            writePolicy: writePolicy,
            documents: documents,
            generatedOutputs: generatedOutputs,
            diagnostics: diagnostics,
            buildTargets: buildTargets
        )
    }

    static func emeraldDocuments(root: URL, fileManager: FileManager) -> [SourceDocument] {
        decompDocuments(
            root: root,
            fileManager: fileManager,
            trainerDocuments: [
                document(root: root, "src/data/trainers.h", .cHeader, fileManager: fileManager)
            ],
            itemDocument: document(root: root, "src/data/items.h", .cHeader, fileManager: fileManager)
        )
    }

    static func fireRedDocuments(root: URL, fileManager: FileManager) -> [SourceDocument] {
        var documents = decompDocuments(
            root: root,
            fileManager: fileManager,
            trainerDocuments: [
                document(root: root, "src/data/trainers.h", .cHeader, fileManager: fileManager)
            ],
            itemDocument: preferredDocument(
                root: root,
                primary: ("src/data/items.h", .cHeader),
                fallback: ("src/data/items.json", .json),
                fallbackPreservesUnknownFields: true,
                fileManager: fileManager
            )
        )
        documents.append(document(root: root, "graphics/quest_log", .graphics, fileManager: fileManager))
        return documents
    }

    static func expansionDocuments(root: URL, fileManager: FileManager) -> [SourceDocument] {
        decompDocuments(
            root: root,
            fileManager: fileManager,
            trainerDocuments: [
                document(root: root, "src/data/trainers.party", .text, fileManager: fileManager),
                document(root: root, "src/data/trainer_parties.h", .cHeader, fileManager: fileManager)
            ],
            itemDocument: document(root: root, "src/data/items.h", .cHeader, fileManager: fileManager)
        )
    }

    private static func decompDocuments(
        root: URL,
        fileManager: FileManager,
        trainerDocuments: [SourceDocument],
        itemDocument: SourceDocument
    ) -> [SourceDocument] {
        [
            document(root: root, "Makefile", .makefile, fileManager: fileManager),
            document(root: root, "data/maps/map_groups.json", .mapJson, preservesUnknownFields: true, fileManager: fileManager),
            document(root: root, "data/layouts/layouts.json", .layoutJson, preservesUnknownFields: true, fileManager: fileManager),
            document(root: root, "data/scripts", .script, fileManager: fileManager),
            document(root: root, "data/text", .text, fileManager: fileManager),
            document(root: root, "src/data/pokemon/species_info.h", .cHeader, fileManager: fileManager),
        ] + trainerDocuments + [
            itemDocument,
            document(root: root, "src/data/wild_encounters.json", .json, preservesUnknownFields: true, fileManager: fileManager),
            document(root: root, "graphics/pokemon", .graphics, fileManager: fileManager),
            document(root: root, "graphics/trainers", .graphics, fileManager: fileManager)
        ]
    }

    static func rubyDocuments(root: URL, fileManager: FileManager) -> [SourceDocument] {
        [
            document(root: root, "Makefile", .makefile, fileManager: fileManager),
            document(root: root, "config.mk", .configuration, fileManager: fileManager),
            document(root: root, "data/maps/map_groups.json", .mapJson, preservesUnknownFields: true, fileManager: fileManager),
            document(root: root, "data/layouts/layouts.json", .layoutJson, preservesUnknownFields: true, fileManager: fileManager),
            document(root: root, "data/event_scripts.s", .assembly, fileManager: fileManager),
            document(root: root, "data/map_events.s", .assembly, fileManager: fileManager),
            document(root: root, "data/maps", .mapJson, preservesUnknownFields: true, fileManager: fileManager),
            document(root: root, "src/data/pokemon/base_stats.h", .cHeader, fileManager: fileManager),
            document(root: root, "src/data/items_en.h", .cHeader, fileManager: fileManager),
            document(root: root, "src/data/trainers_en.h", .cHeader, fileManager: fileManager),
            document(root: root, "charmap.txt", .text, fileManager: fileManager),
            document(root: root, "data-de", .text, fileManager: fileManager),
            document(root: root, "graphics-de", .graphics, fileManager: fileManager)
        ]
    }

    static func pretGeneratedOutputs(root: URL, fileManager: FileManager) -> [SourceDocument] {
        [
            generated(root: root, "data/maps/*/header.inc", .generated, fileManager: fileManager),
            generated(root: root, "data/maps/*/events.inc", .generated, fileManager: fileManager),
            generated(root: root, "data/maps/*/connections.inc", .generated, fileManager: fileManager),
            generated(root: root, "data/layouts/layouts.inc", .generated, fileManager: fileManager),
            generated(root: root, "build", .artifact, fileManager: fileManager),
            generated(root: root, "*.gba", .artifact, fileManager: fileManager),
            generated(root: root, "*.elf", .artifact, fileManager: fileManager),
            generated(root: root, "*.map", .artifact, fileManager: fileManager)
        ]
    }

    static func document(
        root: URL,
        _ relativePath: String,
        _ kind: SourceKind,
        role: SourceRole = .source,
        preservesUnknownFields: Bool = false,
        fileManager: FileManager
    ) -> SourceDocument {
        SourceDocument(
            relativePath: relativePath,
            kind: kind,
            role: role,
            exists: fileManager.fileExists(atPath: root.appendingPathComponent(relativePath).path),
            preservesUnknownFields: preservesUnknownFields
        )
    }

    private static func preferredDocument(
        root: URL,
        primary: (String, SourceKind),
        fallback: (String, SourceKind),
        primaryPreservesUnknownFields: Bool = false,
        fallbackPreservesUnknownFields: Bool = false,
        fileManager: FileManager
    ) -> SourceDocument {
        let primaryURL = root.appendingPathComponent(primary.0)
        if fileManager.fileExists(atPath: primaryURL.path) {
            return document(root: root, primary.0, primary.1, preservesUnknownFields: primaryPreservesUnknownFields, fileManager: fileManager)
        }
        return document(root: root, fallback.0, fallback.1, preservesUnknownFields: fallbackPreservesUnknownFields, fileManager: fileManager)
    }

    static func generated(root: URL, _ relativePath: String, _ role: SourceRole, fileManager: FileManager) -> SourceDocument {
        SourceDocument(
            relativePath: relativePath,
            kind: .generated,
            role: role,
            exists: fileManager.fileExists(atPath: root.appendingPathComponent(relativePath).path)
        )
    }

    private static func missingDocumentDiagnostics(_ documents: [SourceDocument]) -> [Diagnostic] {
        documents.compactMap { document in
            guard !document.exists, document.role == .source else {
                return nil
            }
            return Diagnostic(
                severity: .warning,
                code: "SOURCE_MISSING",
                message: "Expected source path is not present: \(document.relativePath)",
                span: SourceSpan(relativePath: document.relativePath, startLine: 1)
            )
        }
    }
}

public struct MapGroupIndex: Codable, Equatable {
    public let groupOrder: [String]
    public let groups: [String: [String]]
    public let connectionsIncludeOrder: [String]

    public init(groupOrder: [String], groups: [String: [String]], connectionsIncludeOrder: [String] = []) {
        self.groupOrder = groupOrder
        self.groups = groups
        self.connectionsIncludeOrder = connectionsIncludeOrder
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        let groupOrderKey = DynamicCodingKey("group_order")
        let connectionsIncludeOrderKey = DynamicCodingKey("connections_include_order")
        groupOrder = try container.decode([String].self, forKey: groupOrderKey)
        connectionsIncludeOrder = try container.decodeIfPresent([String].self, forKey: connectionsIncludeOrderKey) ?? []

        var groups: [String: [String]] = [:]
        for key in container.allKeys
            where key.stringValue != groupOrderKey.stringValue
                && key.stringValue != connectionsIncludeOrderKey.stringValue {
            groups[key.stringValue] = try container.decode([String].self, forKey: key)
        }
        self.groups = groups
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        try container.encode(groupOrder, forKey: DynamicCodingKey("group_order"))
        for key in groupOrder where groups[key] != nil {
            try container.encode(groups[key], forKey: DynamicCodingKey(key))
        }
        if !connectionsIncludeOrder.isEmpty {
            try container.encode(connectionsIncludeOrder, forKey: DynamicCodingKey("connections_include_order"))
        }
    }
}

public struct LayoutIndex: Codable, Equatable {
    public let layoutsTableLabel: String
    public let layouts: [LayoutDescriptor]
    public let layoutSlots: [LayoutDescriptor?]

    public init(layoutsTableLabel: String, layouts: [LayoutDescriptor]) {
        self.layoutsTableLabel = layoutsTableLabel
        let indexedLayouts = layouts.enumerated().map { index, layout in
            layout.withSlotIndex(index)
        }
        self.layouts = indexedLayouts
        self.layoutSlots = indexedLayouts.map(Optional.some)
    }

    private enum CodingKeys: String, CodingKey {
        case layoutsTableLabel = "layouts_table_label"
        case layouts
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        layoutsTableLabel = try container.decode(String.self, forKey: .layoutsTableLabel)

        let rawLayouts = try container.decode([OptionalLayoutDescriptor].self, forKey: .layouts)
        layoutSlots = rawLayouts.enumerated().map { index, rawLayout in
            rawLayout.descriptor?.withSlotIndex(index)
        }
        layouts = layoutSlots.compactMap { $0 }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(layoutsTableLabel, forKey: .layoutsTableLabel)
        try container.encode(layoutSlots.map(OptionalLayoutDescriptor.init), forKey: .layouts)
    }
}

public struct LayoutDescriptor: Codable, Equatable, Identifiable {
    public let id: String
    public let slotIndex: Int?
    public let name: String
    public let width: Int
    public let height: Int
    public let borderWidth: Int?
    public let borderHeight: Int?
    public let primaryTileset: String
    public let secondaryTileset: String
    public let borderFilepath: String
    public let blockdataFilepath: String

    public init(
        id: String,
        slotIndex: Int? = nil,
        name: String,
        width: Int,
        height: Int,
        borderWidth: Int? = nil,
        borderHeight: Int? = nil,
        primaryTileset: String,
        secondaryTileset: String,
        borderFilepath: String,
        blockdataFilepath: String
    ) {
        self.id = id
        self.slotIndex = slotIndex
        self.name = name
        self.width = width
        self.height = height
        self.borderWidth = borderWidth
        self.borderHeight = borderHeight
        self.primaryTileset = primaryTileset
        self.secondaryTileset = secondaryTileset
        self.borderFilepath = borderFilepath
        self.blockdataFilepath = blockdataFilepath
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case width
        case height
        case borderWidth = "border_width"
        case borderHeight = "border_height"
        case primaryTileset = "primary_tileset"
        case secondaryTileset = "secondary_tileset"
        case borderFilepath = "border_filepath"
        case blockdataFilepath = "blockdata_filepath"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        slotIndex = nil
        name = try container.decode(String.self, forKey: .name)
        width = try container.decode(Int.self, forKey: .width)
        height = try container.decode(Int.self, forKey: .height)
        borderWidth = try container.decodeIfPresent(Int.self, forKey: .borderWidth)
        borderHeight = try container.decodeIfPresent(Int.self, forKey: .borderHeight)
        primaryTileset = try container.decode(String.self, forKey: .primaryTileset)
        secondaryTileset = try container.decode(String.self, forKey: .secondaryTileset)
        borderFilepath = try container.decode(String.self, forKey: .borderFilepath)
        blockdataFilepath = try container.decode(String.self, forKey: .blockdataFilepath)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encodeIfPresent(borderWidth, forKey: .borderWidth)
        try container.encodeIfPresent(borderHeight, forKey: .borderHeight)
        try container.encode(primaryTileset, forKey: .primaryTileset)
        try container.encode(secondaryTileset, forKey: .secondaryTileset)
        try container.encode(borderFilepath, forKey: .borderFilepath)
        try container.encode(blockdataFilepath, forKey: .blockdataFilepath)
    }

    fileprivate func withSlotIndex(_ slotIndex: Int) -> LayoutDescriptor {
        LayoutDescriptor(
            id: id,
            slotIndex: slotIndex,
            name: name,
            width: width,
            height: height,
            borderWidth: borderWidth,
            borderHeight: borderHeight,
            primaryTileset: primaryTileset,
            secondaryTileset: secondaryTileset,
            borderFilepath: borderFilepath,
            blockdataFilepath: blockdataFilepath
        )
    }
}

private struct OptionalLayoutDescriptor: Codable, Equatable {
    let descriptor: LayoutDescriptor?

    init(_ descriptor: LayoutDescriptor?) {
        self.descriptor = descriptor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        if container.allKeys.isEmpty {
            descriptor = nil
        } else {
            descriptor = try LayoutDescriptor(from: decoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        guard let descriptor else {
            _ = encoder.container(keyedBy: DynamicCodingKey.self)
            return
        }
        try descriptor.encode(to: encoder)
    }
}

public enum SourceParsers {
    public static func decodeMapGroups(_ data: Data) throws -> MapGroupIndex {
        try JSONDecoder().decode(MapGroupIndex.self, from: data)
    }

    public static func decodeLayouts(_ data: Data) throws -> LayoutIndex {
        try JSONDecoder().decode(LayoutIndex.self, from: data)
    }
}

public struct CInitializerEntry: Codable, Equatable, Identifiable {
    public var id: String { symbol }

    public let symbol: String
    public let body: String
    public let span: SourceSpan
    public let ordinal: Int?
    public let fields: [String: String]

    public init(
        symbol: String,
        body: String,
        span: SourceSpan,
        ordinal: Int? = nil,
        fields: [String: String] = [:]
    ) {
        self.symbol = symbol
        self.body = body
        self.span = span
        self.ordinal = ordinal
        self.fields = fields
    }
}

public enum CInitializerParser {
    public static func entries(in text: String, relativePath: String) -> [CInitializerEntry] {
        let lines = text.components(separatedBy: .newlines)
        var entries: [CInitializerEntry] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]
            guard
                let openBracket = line.firstIndex(of: "["),
                let closeBracket = line[openBracket...].firstIndex(of: "]"),
                line[closeBracket...].contains("=")
            else {
                index += 1
                continue
            }

            let symbol = String(line[line.index(after: openBracket)..<closeBracket])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !symbol.isEmpty else {
                index += 1
                continue
            }

            let startLine = index + 1
            var bodyLines = [line]
            var braceDepth = line.reduce(0) { depth, character in
                depth + (character == "{" ? 1 : 0) - (character == "}" ? 1 : 0)
            }
            var sawOpeningBrace = line.contains("{")

            index += 1
            while index < lines.count, !sawOpeningBrace || braceDepth > 0 {
                let nextLine = lines[index]
                bodyLines.append(nextLine)
                sawOpeningBrace = sawOpeningBrace || nextLine.contains("{")
                braceDepth += nextLine.reduce(0) { depth, character in
                    depth + (character == "{" ? 1 : 0) - (character == "}" ? 1 : 0)
                }
                index += 1
            }

            entries.append(
                CInitializerEntry(
                    symbol: symbol,
                    body: bodyLines.joined(separator: "\n"),
                    span: SourceSpan(relativePath: relativePath, startLine: startLine, endLine: max(startLine, index))
                )
            )
        }

        return entries
    }
}

public enum ScriptTextDiagnostics {
    public static func diagnose(
        text: String,
        relativePath: String,
        maxLineLength: Int = 68
    ) -> [Diagnostic] {
        text.components(separatedBy: .newlines).enumerated().flatMap { lineIndex, line -> [Diagnostic] in
            var diagnostics: [Diagnostic] = []
            let lineNumber = lineIndex + 1

            if line.count > maxLineLength {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "TEXT_LINE_LONG",
                        message: "Line exceeds \(maxLineLength) characters.",
                        span: SourceSpan(relativePath: relativePath, startLine: lineNumber, startColumn: maxLineLength + 1)
                    )
                )
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix(".string"), trimmed.contains("\""), !trimmed.contains("$") {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "TEXT_TERMINATOR_MISSING",
                        message: "Gen III text strings usually need a $ terminator.",
                        span: SourceSpan(relativePath: relativePath, startLine: lineNumber)
                    )
                )
            }

            return diagnostics
        }
    }
}

public struct ROMImage: Codable, Equatable {
    public let path: String
    public let size: Int
    public let title: String?
    public let gameCode: String?
    public let makerCode: String?
    public let version: UInt8?
    public let complementChecksum: UInt8?
    public let expectedComplementChecksum: UInt8?
    public let isComplementChecksumValid: Bool?
    public let hasNintendoLogoData: Bool

    public init(path: String, data: Data) {
        self.path = path
        self.size = data.count
        self.title = ROMImage.asciiString(data: data, offset: 0xA0, length: 12)
        self.gameCode = ROMImage.asciiString(data: data, offset: 0xAC, length: 4)
        self.makerCode = ROMImage.asciiString(data: data, offset: 0xB0, length: 2)
        let version = data.count > 0xBC ? data[0xBC] : nil
        let complementChecksum = data.count > 0xBD ? data[0xBD] : nil
        let expectedComplementChecksum = ROMImage.expectedComplementChecksum(data: data)
        self.version = version
        self.complementChecksum = complementChecksum
        self.expectedComplementChecksum = expectedComplementChecksum
        if let complementChecksum, let expectedComplementChecksum {
            self.isComplementChecksumValid = complementChecksum == expectedComplementChecksum
        } else {
            self.isComplementChecksumValid = nil
        }
        self.hasNintendoLogoData = data.count >= 0xA0 && data[0x04..<0xA0].contains { $0 != 0 }
    }

    private static func asciiString(data: Data, offset: Int, length: Int) -> String? {
        guard data.count >= offset + length else {
            return nil
        }
        let bytes = data[offset..<(offset + length)]
        let string = String(decoding: bytes, as: UTF8.self).trimmingCharacters(in: .controlCharacters.union(.whitespaces))
        return string.isEmpty ? nil : string
    }

    private static func expectedComplementChecksum(data: Data) -> UInt8? {
        guard data.count > 0xBC else { return nil }
        let sum = data[0xA0...0xBC].reduce(0) { ($0 + Int($1)) & 0xff }
        return UInt8((0x19 - sum) & 0xff)
    }
}

public struct GBAPointer: Codable, Equatable {
    public static let romBase: UInt32 = 0x08000000

    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(offset: UInt32) {
        self.rawValue = Self.romBase + offset
    }

    public var romOffset: UInt32? {
        guard rawValue >= Self.romBase else {
            return nil
        }
        return rawValue - Self.romBase
    }
}

public struct BinaryROMGraph: Codable, Equatable {
    public let image: ROMImage
    public let headerFacts: [BinaryROMGraphFact]
    public let semanticRuns: [BinaryROMSemanticRun]
    public let anchors: [BinaryROMAnchor]
    public let pointerCandidates: [BinaryROMPointerCandidate]
    public let rejectedPointerCandidates: [BinaryROMRejectedPointerCandidate]
    public let freeSpaceRanges: [BinaryROMRange]
    public let diagnostics: [Diagnostic]

    public init(
        image: ROMImage,
        headerFacts: [BinaryROMGraphFact],
        semanticRuns: [BinaryROMSemanticRun] = [],
        anchors: [BinaryROMAnchor] = [],
        pointerCandidates: [BinaryROMPointerCandidate],
        rejectedPointerCandidates: [BinaryROMRejectedPointerCandidate] = [],
        freeSpaceRanges: [BinaryROMRange],
        diagnostics: [Diagnostic] = []
    ) {
        self.image = image
        self.headerFacts = headerFacts
        self.semanticRuns = semanticRuns
        self.anchors = anchors
        self.pointerCandidates = pointerCandidates
        self.rejectedPointerCandidates = rejectedPointerCandidates
        self.freeSpaceRanges = freeSpaceRanges
        self.diagnostics = diagnostics
    }
}

public struct BinaryROMGraphFact: Codable, Equatable, Identifiable {
    public var id: String { key }

    public let key: String
    public let value: String
    public let confidence: String

    public init(key: String, value: String, confidence: String = "high") {
        self.key = key
        self.value = value
        self.confidence = confidence
    }
}

public struct BinaryROMPointerCandidate: Codable, Equatable, Identifiable {
    public var id: String { "\(sourceOffset):\(targetOffset)" }

    public let sourceOffset: UInt32
    public let rawValue: UInt32
    public let targetOffset: UInt32
    public let confidence: String

    public init(sourceOffset: UInt32, rawValue: UInt32, targetOffset: UInt32, confidence: String = "medium") {
        self.sourceOffset = sourceOffset
        self.rawValue = rawValue
        self.targetOffset = targetOffset
        self.confidence = confidence
    }
}

public struct BinaryROMRejectedPointerCandidate: Codable, Equatable, Identifiable {
    public var id: String { "\(sourceOffset):\(rawValue)" }

    public let sourceOffset: UInt32
    public let rawValue: UInt32
    public let reason: String

    public init(sourceOffset: UInt32, rawValue: UInt32, reason: String) {
        self.sourceOffset = sourceOffset
        self.rawValue = rawValue
        self.reason = reason
    }
}

public struct BinaryROMRange: Codable, Equatable, Identifiable {
    public var id: String { "\(offset):\(length)" }

    public let offset: UInt32
    public let length: UInt32
    public let fillByte: UInt8
    public let confidence: String

    public init(offset: UInt32, length: UInt32, fillByte: UInt8, confidence: String = "medium") {
        self.offset = offset
        self.length = length
        self.fillByte = fillByte
        self.confidence = confidence
    }
}

public enum BinaryROMSemanticRunKind: String, Codable, Equatable {
    case header
    case nintendoLogo
    case pointer
    case freeSpace
    case unknown
}

public struct BinaryROMSemanticRun: Codable, Equatable, Identifiable {
    public var id: String { "\(kind.rawValue):\(offset):\(length)" }

    public let kind: BinaryROMSemanticRunKind
    public let label: String
    public let offset: UInt32
    public let length: UInt32
    public let confidence: String
    public let detail: String

    public init(
        kind: BinaryROMSemanticRunKind,
        label: String,
        offset: UInt32,
        length: UInt32,
        confidence: String,
        detail: String
    ) {
        self.kind = kind
        self.label = label
        self.offset = offset
        self.length = length
        self.confidence = confidence
        self.detail = detail
    }
}

public struct BinaryROMAnchor: Codable, Equatable, Identifiable {
    public var id: String { "\(label):\(offset)" }

    public let label: String
    public let offset: UInt32
    public let kind: String
    public let confidence: String

    public init(label: String, offset: UInt32, kind: String, confidence: String) {
        self.label = label
        self.offset = offset
        self.kind = kind
        self.confidence = confidence
    }
}

public enum BinaryROMGraphBuilder {
    public static func build(
        path: String,
        data: Data,
        maxPointers: Int = 64,
        maxRejectedPointers: Int = 32,
        minimumFreeSpaceLength: Int = 32
    ) -> BinaryROMGraph {
        let image = ROMImage(path: path, data: data)
        var facts: [BinaryROMGraphFact] = [
            BinaryROMGraphFact(key: "Size", value: "\(image.size) bytes"),
            BinaryROMGraphFact(key: "Title", value: image.title ?? "Unavailable", confidence: image.title == nil ? "low" : "high"),
            BinaryROMGraphFact(key: "Game Code", value: image.gameCode ?? "Unavailable", confidence: image.gameCode == nil ? "low" : "high"),
            BinaryROMGraphFact(key: "Maker Code", value: image.makerCode ?? "Unavailable", confidence: image.makerCode == nil ? "low" : "high"),
            BinaryROMGraphFact(key: "Revision", value: image.version.map { "\($0)" } ?? "Unavailable", confidence: image.version == nil ? "low" : "high"),
            BinaryROMGraphFact(key: "Nintendo Logo", value: image.hasNintendoLogoData ? "Present" : "Missing", confidence: image.hasNintendoLogoData ? "medium" : "low")
        ]
        if let actual = image.complementChecksum, let expected = image.expectedComplementChecksum {
            facts.append(BinaryROMGraphFact(key: "Header Complement", value: String(format: "0x%02X expected 0x%02X", actual, expected), confidence: actual == expected ? "high" : "medium"))
        }

        let scan = pointerScan(data: data, maxPointers: maxPointers, maxRejectedPointers: maxRejectedPointers)
        let pointers = scan.accepted
        let rejectedPointers = scan.rejected
        let freeSpace = freeSpaceRanges(data: data, minimumLength: minimumFreeSpaceLength)
        let runs = semanticRuns(data: data, pointers: pointers, freeSpace: freeSpace)
        let anchors = anchors(image: image, pointers: pointers, freeSpace: freeSpace)
        var diagnostics: [Diagnostic] = []
        if image.isComplementChecksumValid == false {
            diagnostics.append(Diagnostic(severity: .warning, code: "BINARY_ROM_HEADER_COMPLEMENT_MISMATCH", message: "The GBA header complement checksum does not match the calculated value."))
        }
        if pointers.isEmpty {
            diagnostics.append(Diagnostic(severity: .info, code: "BINARY_ROM_POINTERS_NOT_FOUND", message: "No aligned GBA pointer candidates were found in the first graph pass."))
        }
        if !rejectedPointers.isEmpty {
            diagnostics.append(Diagnostic(severity: .info, code: "BINARY_ROM_POINTER_CANDIDATES_REJECTED", message: "\(rejectedPointers.count) GBA-looking pointer candidate(s) were rejected because they point outside this ROM image."))
        }

        return BinaryROMGraph(
            image: image,
            headerFacts: facts,
            semanticRuns: runs,
            anchors: anchors,
            pointerCandidates: pointers,
            rejectedPointerCandidates: rejectedPointers,
            freeSpaceRanges: freeSpace,
            diagnostics: diagnostics
        )
    }

    private static func pointerScan(
        data: Data,
        maxPointers: Int,
        maxRejectedPointers: Int
    ) -> (accepted: [BinaryROMPointerCandidate], rejected: [BinaryROMRejectedPointerCandidate]) {
        guard data.count >= 4 else { return ([], []) }
        var accepted: [BinaryROMPointerCandidate] = []
        var rejected: [BinaryROMRejectedPointerCandidate] = []
        for offset in stride(from: 0, through: data.count - 4, by: 4) {
            let raw = readUInt32LE(data, offset: offset)
            guard let target = GBAPointer(rawValue: raw).romOffset else { continue }
            if target < data.count {
                accepted.append(BinaryROMPointerCandidate(sourceOffset: UInt32(offset), rawValue: raw, targetOffset: target))
            } else if rejected.count < maxRejectedPointers {
                rejected.append(BinaryROMRejectedPointerCandidate(sourceOffset: UInt32(offset), rawValue: raw, reason: "Target offset is outside the ROM image."))
            }
            if accepted.count >= maxPointers, rejected.count >= maxRejectedPointers { break }
        }
        return (accepted, rejected)
    }

    private static func freeSpaceRanges(data: Data, minimumLength: Int) -> [BinaryROMRange] {
        var ranges: [BinaryROMRange] = []
        var start: Int?
        var byte: UInt8 = 0
        for index in 0...data.count {
            let current = index < data.count ? data[index] : 0xff ^ byte
            let isFree = current == 0x00 || current == 0xff
            if isFree, start == nil {
                start = index
                byte = current
            } else if (!isFree || current != byte), let rangeStart = start {
                let length = index - rangeStart
                if length >= minimumLength {
                    ranges.append(BinaryROMRange(offset: UInt32(rangeStart), length: UInt32(length), fillByte: byte))
                }
                start = isFree ? index : nil
                byte = current
            }
        }
        return ranges
    }

    private static func semanticRuns(
        data: Data,
        pointers: [BinaryROMPointerCandidate],
        freeSpace: [BinaryROMRange]
    ) -> [BinaryROMSemanticRun] {
        var runs: [BinaryROMSemanticRun] = []
        if data.count >= 0xC0 {
            runs.append(
                BinaryROMSemanticRun(
                    kind: .header,
                    label: "GBA header",
                    offset: 0,
                    length: 0xC0,
                    confidence: "high",
                    detail: "Header, logo, title, game code, maker code, and complement checksum area."
                )
            )
        }
        if data.count >= 0xA0 {
            runs.append(
                BinaryROMSemanticRun(
                    kind: .nintendoLogo,
                    label: "Nintendo logo data",
                    offset: 0x04,
                    length: 0x9C,
                    confidence: "medium",
                    detail: "Logo bytes are present in the fixed GBA header region."
                )
            )
        }
        runs.append(contentsOf: pointers.prefix(32).map {
            BinaryROMSemanticRun(
                kind: .pointer,
                label: String(format: "Pointer 0x%06X -> 0x%06X", $0.sourceOffset, $0.targetOffset),
                offset: $0.sourceOffset,
                length: 4,
                confidence: $0.confidence,
                detail: String(format: "Little-endian GBA pointer value 0x%08X.", $0.rawValue)
            )
        })
        runs.append(contentsOf: freeSpace.prefix(32).map {
            BinaryROMSemanticRun(
                kind: .freeSpace,
                label: String(format: "Free space 0x%06X", $0.offset),
                offset: $0.offset,
                length: $0.length,
                confidence: $0.confidence,
                detail: String(format: "Contiguous fill bytes 0x%02X.", $0.fillByte)
            )
        })
        return runs.sorted { lhs, rhs in
            lhs.offset == rhs.offset ? lhs.kind.rawValue < rhs.kind.rawValue : lhs.offset < rhs.offset
        }
    }

    private static func anchors(
        image: ROMImage,
        pointers: [BinaryROMPointerCandidate],
        freeSpace: [BinaryROMRange]
    ) -> [BinaryROMAnchor] {
        var anchors: [BinaryROMAnchor] = [
            BinaryROMAnchor(label: image.title ?? "ROM header", offset: 0xA0, kind: "title", confidence: image.title == nil ? "low" : "high")
        ]
        if image.gameCode != nil {
            anchors.append(BinaryROMAnchor(label: "Game code", offset: 0xAC, kind: "gameCode", confidence: "high"))
        }
        anchors.append(contentsOf: pointers.prefix(16).map {
            BinaryROMAnchor(label: String(format: "Pointer target 0x%06X", $0.targetOffset), offset: $0.targetOffset, kind: "pointerTarget", confidence: $0.confidence)
        })
        anchors.append(contentsOf: freeSpace.prefix(16).map {
            BinaryROMAnchor(label: String(format: "Free space 0x%06X", $0.offset), offset: $0.offset, kind: "freeSpace", confidence: $0.confidence)
        })
        return anchors.sorted { $0.offset < $1.offset }
    }

    private static func readUInt32LE(_ data: Data, offset: Int) -> UInt32 {
        UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }
}

public enum ByteCursorError: Error, Equatable, LocalizedError {
    case unexpectedEOF(offset: Int, requested: Int, size: Int)

    public var errorDescription: String? {
        switch self {
        case .unexpectedEOF(let offset, let requested, let size):
            return "Unexpected EOF at \(offset); requested \(requested) bytes from \(size)-byte buffer."
        }
    }
}

public struct ByteCursor {
    public private(set) var offset: Int
    private let data: [UInt8]

    public init(data: Data, offset: Int = 0) {
        self.data = Array(data)
        self.offset = offset
    }

    public var isAtEnd: Bool {
        offset >= data.count
    }

    public mutating func readUInt8() throws -> UInt8 {
        try require(count: 1)
        defer { offset += 1 }
        return data[offset]
    }

    public mutating func readUInt16LE() throws -> UInt16 {
        let bytes = try readBytes(count: 2)
        return UInt16(bytes[0]) | (UInt16(bytes[1]) << 8)
    }

    public mutating func readUInt16BE() throws -> UInt16 {
        let bytes = try readBytes(count: 2)
        return (UInt16(bytes[0]) << 8) | UInt16(bytes[1])
    }

    public mutating func readUInt24BE() throws -> UInt32 {
        let bytes = try readBytes(count: 3)
        return (UInt32(bytes[0]) << 16) | (UInt32(bytes[1]) << 8) | UInt32(bytes[2])
    }

    public mutating func readUInt32LE() throws -> UInt32 {
        let bytes = try readBytes(count: 4)
        return UInt32(bytes[0]) | (UInt32(bytes[1]) << 8) | (UInt32(bytes[2]) << 16) | (UInt32(bytes[3]) << 24)
    }

    public mutating func readBytes(count: Int) throws -> [UInt8] {
        try require(count: count)
        defer { offset += count }
        return Array(data[offset..<(offset + count)])
    }

    public mutating func readVariableLengthQuantity() throws -> UInt64 {
        var value: UInt64 = 0
        var shift: UInt64 = 1

        while true {
            let byte = UInt64(try readUInt8())
            value += (byte & 0x7F) * shift
            if byte & 0x80 != 0 {
                break
            }
            shift <<= 7
            value += shift
        }

        return value
    }

    private func require(count: Int) throws {
        guard offset + count <= data.count else {
            throw ByteCursorError.unexpectedEOF(offset: offset, requested: count, size: data.count)
        }
    }
}

public enum PatchFormatID: String, Codable, Equatable, CaseIterable {
    case ips
    case bps
    case ups
    case apsGBA
    case unknown
}

public struct PatchSummary: Codable, Equatable {
    public let format: PatchFormatID
    public let recordCount: Int?
    public let sourceSize: UInt64?
    public let targetSize: UInt64?
    public let hasEmbeddedChecksums: Bool

    public init(
        format: PatchFormatID,
        recordCount: Int? = nil,
        sourceSize: UInt64? = nil,
        targetSize: UInt64? = nil,
        hasEmbeddedChecksums: Bool
    ) {
        self.format = format
        self.recordCount = recordCount
        self.sourceSize = sourceSize
        self.targetSize = targetSize
        self.hasEmbeddedChecksums = hasEmbeddedChecksums
    }
}

public struct PatchManifestSummary: Codable, Equatable {
    public let name: String
    public let format: PatchFormatID
    public let baseChecksums: [String: String]
    public let outputName: String?
    public let optionalPatches: [String]

    public init(
        name: String,
        format: PatchFormatID,
        baseChecksums: [String: String] = [:],
        outputName: String? = nil,
        optionalPatches: [String] = []
    ) {
        self.name = name
        self.format = format
        self.baseChecksums = baseChecksums
        self.outputName = outputName
        self.optionalPatches = optionalPatches
    }
}

public protocol PatchFormat {
    var id: PatchFormatID { get }
    func parseSummary(data: Data) throws -> PatchSummary
}

public enum PatchParser {
    public static func sniff(data: Data) -> PatchFormatID {
        if data.starts(with: Data("PATCH".utf8)) {
            return .ips
        }
        if data.starts(with: Data("BPS1".utf8)) {
            return .bps
        }
        if data.starts(with: Data("UPS1".utf8)) {
            return .ups
        }
        if data.starts(with: Data("APS1".utf8)) {
            return .apsGBA
        }
        return .unknown
    }

    public static func parseSummary(data: Data) throws -> PatchSummary {
        switch sniff(data: data) {
        case .ips:
            return try parseIPS(data: data)
        case .bps:
            return try parseBPS(data: data)
        case .ups:
            return try parseUPS(data: data)
        case .apsGBA:
            return PatchSummary(format: .apsGBA, hasEmbeddedChecksums: true)
        case .unknown:
            return PatchSummary(format: .unknown, hasEmbeddedChecksums: false)
        }
    }

    private static func parseIPS(data: Data) throws -> PatchSummary {
        var cursor = ByteCursor(data: data)
        _ = try cursor.readBytes(count: 5)
        var records = 0

        while !cursor.isAtEnd {
            let offset = try cursor.readUInt24BE()
            if offset == 0x454F46 {
                return PatchSummary(format: .ips, recordCount: records, hasEmbeddedChecksums: false)
            }

            let size = try cursor.readUInt16BE()
            if size == 0 {
                _ = try cursor.readUInt16BE()
                _ = try cursor.readUInt8()
            } else {
                _ = try cursor.readBytes(count: Int(size))
            }
            records += 1
        }

        return PatchSummary(format: .ips, recordCount: records, hasEmbeddedChecksums: false)
    }

    private static func parseBPS(data: Data) throws -> PatchSummary {
        var cursor = ByteCursor(data: data)
        _ = try cursor.readBytes(count: 4)
        let sourceSize = try cursor.readVariableLengthQuantity()
        let targetSize = try cursor.readVariableLengthQuantity()
        let metadataSize = try cursor.readVariableLengthQuantity()
        if metadataSize > 0 {
            _ = try cursor.readBytes(count: Int(metadataSize))
        }

        return PatchSummary(
            format: .bps,
            sourceSize: sourceSize,
            targetSize: targetSize,
            hasEmbeddedChecksums: true
        )
    }

    private static func parseUPS(data: Data) throws -> PatchSummary {
        var cursor = ByteCursor(data: data)
        _ = try cursor.readBytes(count: 4)
        let sourceSize = try cursor.readVariableLengthQuantity()
        let targetSize = try cursor.readVariableLengthQuantity()

        return PatchSummary(
            format: .ups,
            sourceSize: sourceSize,
            targetSize: targetSize,
            hasEmbeddedChecksums: true
        )
    }
}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int? = nil

    init(_ stringValue: String) {
        self.stringValue = stringValue
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        return nil
    }
}
