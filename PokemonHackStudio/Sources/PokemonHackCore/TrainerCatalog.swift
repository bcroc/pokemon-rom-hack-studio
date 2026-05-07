import Foundation

public enum TrainerPartyShape: String, Codable, Equatable, CaseIterable, Identifiable {
    case noItemDefaultMoves
    case noItemCustomMoves
    case itemDefaultMoves
    case itemCustomMoves

    public var id: String { rawValue }

    public var usesHeldItems: Bool {
        self == .itemDefaultMoves || self == .itemCustomMoves
    }

    public var usesCustomMoves: Bool {
        self == .noItemCustomMoves || self == .itemCustomMoves
    }

    public var macroName: String {
        switch self {
        case .noItemDefaultMoves:
            "NO_ITEM_DEFAULT_MOVES"
        case .noItemCustomMoves:
            "NO_ITEM_CUSTOM_MOVES"
        case .itemDefaultMoves:
            "ITEM_DEFAULT_MOVES"
        case .itemCustomMoves:
            "ITEM_CUSTOM_MOVES"
        }
    }

    public var structName: String {
        switch self {
        case .noItemDefaultMoves:
            "TrainerMonNoItemDefaultMoves"
        case .noItemCustomMoves:
            "TrainerMonNoItemCustomMoves"
        case .itemDefaultMoves:
            "TrainerMonItemDefaultMoves"
        case .itemCustomMoves:
            "TrainerMonItemCustomMoves"
        }
    }

    static func macro(_ value: String) -> TrainerPartyShape? {
        switch value {
        case "NO_ITEM_DEFAULT_MOVES":
            .noItemDefaultMoves
        case "NO_ITEM_CUSTOM_MOVES":
            .noItemCustomMoves
        case "ITEM_DEFAULT_MOVES":
            .itemDefaultMoves
        case "ITEM_CUSTOM_MOVES":
            .itemCustomMoves
        default:
            nil
        }
    }

    static func structName(_ value: String) -> TrainerPartyShape? {
        switch value {
        case "TrainerMonNoItemDefaultMoves":
            .noItemDefaultMoves
        case "TrainerMonNoItemCustomMoves":
            .noItemCustomMoves
        case "TrainerMonItemDefaultMoves":
            .itemDefaultMoves
        case "TrainerMonItemCustomMoves":
            .itemCustomMoves
        default:
            nil
        }
    }
}

public enum TrainerConstantGroup: String, Codable, Equatable, CaseIterable, Identifiable {
    case species
    case moves
    case items
    case natures
    case trainerClasses
    case trainerPics
    case encounterMusic
    case aiFlags

    public var id: String { rawValue }
}

public struct TrainerConstant: Codable, Equatable, Identifiable, Sendable {
    public var id: String { symbol }

    public let symbol: String
    public let value: String
    public let sourceSpan: SourceSpan

    public init(symbol: String, value: String, sourceSpan: SourceSpan) {
        self.symbol = symbol
        self.value = value
        self.sourceSpan = sourceSpan
    }
}

public struct TrainerPokemonIVs: Codable, Equatable, Sendable {
    public var hp: Int
    public var attack: Int
    public var defense: Int
    public var speed: Int
    public var spAttack: Int
    public var spDefense: Int

    public init(hp: Int, attack: Int, defense: Int, speed: Int, spAttack: Int, spDefense: Int) {
        self.hp = hp
        self.attack = attack
        self.defense = defense
        self.speed = speed
        self.spAttack = spAttack
        self.spDefense = spDefense
    }

    public static func uniform(_ value: Int) -> TrainerPokemonIVs {
        TrainerPokemonIVs(hp: value, attack: value, defense: value, speed: value, spAttack: value, spDefense: value)
    }

    public var values: [Int] {
        [hp, attack, defense, speed, spAttack, spDefense]
    }

    public var isUniform: Bool {
        Set(values).count <= 1
    }

    public var uniformValue: Int? {
        isUniform ? hp : nil
    }
}

public struct TrainerPartyPokemon: Codable, Equatable, Identifiable {
    public var id: String { "\(slot):\(sourceSpan.relativePath):\(sourceSpan.startLine)" }

    public let slot: Int
    public let species: String
    public let level: Int?
    public let iv: Int?
    public let ivs: TrainerPokemonIVs
    public let nature: String?
    public let defaultMoves: [String]
    public let heldItem: String?
    public let moves: [String]
    public let supportsIndividualIVs: Bool
    public let supportsNature: Bool
    public let sourceSpan: SourceSpan
    public let diagnostics: [Diagnostic]
    public let sourcePreview: String

    public init(
        slot: Int,
        species: String,
        level: Int?,
        iv: Int?,
        ivs: TrainerPokemonIVs? = nil,
        nature: String? = nil,
        defaultMoves: [String] = [],
        heldItem: String? = nil,
        moves: [String] = [],
        supportsIndividualIVs: Bool = false,
        supportsNature: Bool = false,
        sourceSpan: SourceSpan,
        diagnostics: [Diagnostic] = [],
        sourcePreview: String = ""
    ) {
        self.slot = slot
        self.species = species
        self.level = level
        self.iv = iv
        self.ivs = ivs ?? TrainerPokemonIVs.uniform(sourceIVToActualIV(iv ?? 0))
        self.nature = nature
        self.defaultMoves = Array((defaultMoves + Array(repeating: "MOVE_NONE", count: 4)).prefix(4))
        self.heldItem = heldItem
        self.moves = moves
        self.supportsIndividualIVs = supportsIndividualIVs
        self.supportsNature = supportsNature
        self.sourceSpan = sourceSpan
        self.diagnostics = diagnostics
        self.sourcePreview = sourcePreview
    }
}

private extension TrainerPartyPokemon {
    func withDefaultMoves(_ defaultMoves: [String]) -> TrainerPartyPokemon {
        TrainerPartyPokemon(
            slot: slot,
            species: species,
            level: level,
            iv: iv,
            ivs: ivs,
            nature: nature,
            defaultMoves: defaultMoves,
            heldItem: heldItem,
            moves: moves,
            supportsIndividualIVs: supportsIndividualIVs,
            supportsNature: supportsNature,
            sourceSpan: sourceSpan,
            diagnostics: diagnostics,
            sourcePreview: sourcePreview
        )
    }
}

public struct TrainerDetail: Codable, Equatable, Identifiable {
    public var id: String { trainerID }

    public let trainerID: String
    public let displayName: String
    public let trainerName: String
    public let trainerClass: String
    public let encounterMusicGender: String
    public let trainerPic: String
    public let trainerItems: [String]
    public let doubleBattle: Bool
    public let aiFlags: [String]
    public let aiFlagsExpression: String
    public let partyShape: TrainerPartyShape?
    public let partySymbol: String?
    public let sourceSpan: SourceSpan
    public let partySourceSpan: SourceSpan?
    public let party: [TrainerPartyPokemon]
    public let diagnostics: [Diagnostic]
    public let sourcePreview: String
    public let partyPreview: String?
    public let isEditable: Bool

    public init(
        trainerID: String,
        displayName: String,
        trainerName: String,
        trainerClass: String,
        encounterMusicGender: String,
        trainerPic: String,
        trainerItems: [String],
        doubleBattle: Bool,
        aiFlags: [String],
        aiFlagsExpression: String,
        partyShape: TrainerPartyShape?,
        partySymbol: String?,
        sourceSpan: SourceSpan,
        partySourceSpan: SourceSpan?,
        party: [TrainerPartyPokemon],
        diagnostics: [Diagnostic] = [],
        sourcePreview: String = "",
        partyPreview: String? = nil,
        isEditable: Bool
    ) {
        self.trainerID = trainerID
        self.displayName = displayName
        self.trainerName = trainerName
        self.trainerClass = trainerClass
        self.encounterMusicGender = encounterMusicGender
        self.trainerPic = trainerPic
        self.trainerItems = trainerItems
        self.doubleBattle = doubleBattle
        self.aiFlags = aiFlags
        self.aiFlagsExpression = aiFlagsExpression
        self.partyShape = partyShape
        self.partySymbol = partySymbol
        self.sourceSpan = sourceSpan
        self.partySourceSpan = partySourceSpan
        self.party = party
        self.diagnostics = diagnostics
        self.sourcePreview = sourcePreview
        self.partyPreview = partyPreview
        self.isEditable = isEditable
    }
}

public struct TrainerLevelUpMove: Codable, Equatable, Sendable {
    public let level: Int
    public let move: String

    public init(level: Int, move: String) {
        self.level = level
        self.move = move
    }
}

public struct ProjectTrainerCatalog: Codable, Equatable {
    public let root: SourceLocation
    public let profile: GameProfile
    public let adapterID: String
    public let adapterName: String
    public let trainers: [TrainerDetail]
    public let constants: [TrainerConstantGroup: [TrainerConstant]]
    public let defaultMoveLearnsets: [String: [TrainerLevelUpMove]]
    public let diagnostics: [Diagnostic]

    public var trainerCount: Int { trainers.count }

    public init(
        root: SourceLocation,
        profile: GameProfile,
        adapterID: String,
        adapterName: String,
        trainers: [TrainerDetail],
        constants: [TrainerConstantGroup: [TrainerConstant]] = [:],
        defaultMoveLearnsets: [String: [TrainerLevelUpMove]] = [:],
        diagnostics: [Diagnostic] = []
    ) {
        self.root = root
        self.profile = profile
        self.adapterID = adapterID
        self.adapterName = adapterName
        self.trainers = trainers
        self.constants = constants
        self.defaultMoveLearnsets = defaultMoveLearnsets
        self.diagnostics = diagnostics
    }
}

public struct TrainerPartyPokemonDraft: Codable, Equatable, Identifiable {
    public var id: Int { slot }

    public var slot: Int
    public var species: String
    public var level: Int
    public var iv: Int
    public var ivs: TrainerPokemonIVs
    public var nature: String
    public var heldItem: String
    public var moves: [String]
    public var defaultMoves: [String]

    public init(
        slot: Int,
        species: String,
        level: Int,
        iv: Int,
        ivs: TrainerPokemonIVs? = nil,
        nature: String = "NATURE_HARDY",
        heldItem: String = "ITEM_NONE",
        moves: [String] = [],
        defaultMoves: [String] = []
    ) {
        self.slot = slot
        self.species = species
        self.level = level
        self.iv = iv
        self.ivs = ivs ?? TrainerPokemonIVs.uniform(sourceIVToActualIV(iv))
        self.nature = nature
        self.heldItem = heldItem
        self.moves = Array((moves + Array(repeating: "MOVE_NONE", count: 4)).prefix(4))
        self.defaultMoves = Array((defaultMoves + Array(repeating: "MOVE_NONE", count: 4)).prefix(4))
    }
}

public struct TrainerEditDraft: Codable, Equatable, Identifiable {
    public var id: String { trainerID }

    public var trainerID: String
    public var trainerName: String
    public var trainerClass: String
    public var encounterMusicGender: String
    public var trainerPic: String
    public var trainerItems: [String]
    public var doubleBattle: Bool
    public var aiFlags: [String]
    public var partyShape: TrainerPartyShape
    public var partySymbol: String
    public var party: [TrainerPartyPokemonDraft]

    public init(
        trainerID: String,
        trainerName: String,
        trainerClass: String,
        encounterMusicGender: String,
        trainerPic: String,
        trainerItems: [String],
        doubleBattle: Bool,
        aiFlags: [String],
        partyShape: TrainerPartyShape,
        partySymbol: String,
        party: [TrainerPartyPokemonDraft]
    ) {
        self.trainerID = trainerID
        self.trainerName = trainerName
        self.trainerClass = trainerClass
        self.encounterMusicGender = encounterMusicGender
        self.trainerPic = trainerPic
        self.trainerItems = Array((trainerItems + Array(repeating: "ITEM_NONE", count: 4)).prefix(4))
        self.doubleBattle = doubleBattle
        self.aiFlags = aiFlags
        self.partyShape = partyShape
        self.partySymbol = partySymbol
        self.party = party
    }

    public init?(detail: TrainerDetail) {
        guard let partyShape = detail.partyShape, let partySymbol = detail.partySymbol else {
            return nil
        }
        self.init(
            trainerID: detail.trainerID,
            trainerName: detail.trainerName,
            trainerClass: detail.trainerClass,
            encounterMusicGender: detail.encounterMusicGender,
            trainerPic: detail.trainerPic,
            trainerItems: detail.trainerItems,
            doubleBattle: detail.doubleBattle,
            aiFlags: detail.aiFlags,
            partyShape: partyShape,
            partySymbol: partySymbol,
            party: detail.party.map {
                TrainerPartyPokemonDraft(
                    slot: $0.slot,
                    species: $0.species,
                    level: $0.level ?? 1,
                    iv: $0.iv ?? 0,
                    ivs: $0.ivs,
                    nature: $0.nature ?? "NATURE_HARDY",
                    heldItem: $0.heldItem ?? "ITEM_NONE",
                    moves: $0.moves.isEmpty ? $0.defaultMoves : $0.moves,
                    defaultMoves: $0.defaultMoves
                )
            }
        )
    }
}

public struct TrainerEditFileChange: Codable, Equatable, Identifiable {
    public var id: String { path }

    public let path: String
    public let summary: String
    public let originalByteCount: Int
    public let originalSHA1: String?
    public let newByteCount: Int
    public let newData: Data
    public let textPreview: String?

    public init(
        path: String,
        summary: String,
        originalByteCount: Int,
        originalSHA1: String? = nil,
        newByteCount: Int,
        newData: Data,
        textPreview: String? = nil
    ) {
        self.path = path
        self.summary = summary
        self.originalByteCount = originalByteCount
        self.originalSHA1 = originalSHA1
        self.newByteCount = newByteCount
        self.newData = newData
        self.textPreview = textPreview
    }
}

public struct TrainerEditPlan: Codable, Equatable, Identifiable {
    public let id: String
    public let rootPath: String
    public let trainerID: String
    public let draft: TrainerEditDraft
    public let changes: [TrainerEditFileChange]
    public let diagnostics: [Diagnostic]
    public let mutationPlan: MutationPlan
    public let backupRelativeRoot: String

    public init(
        id: String = UUID().uuidString,
        rootPath: String,
        trainerID: String,
        draft: TrainerEditDraft,
        changes: [TrainerEditFileChange],
        diagnostics: [Diagnostic],
        mutationPlan: MutationPlan,
        backupRelativeRoot: String
    ) {
        self.id = id
        self.rootPath = rootPath
        self.trainerID = trainerID
        self.draft = draft
        self.changes = changes
        self.diagnostics = diagnostics
        self.mutationPlan = mutationPlan
        self.backupRelativeRoot = backupRelativeRoot
    }
}

public struct TrainerEditApplyability: Codable, Equatable {
    public let isApplyable: Bool
    public let diagnostics: [Diagnostic]

    public init(isApplyable: Bool, diagnostics: [Diagnostic]) {
        self.isApplyable = isApplyable
        self.diagnostics = diagnostics
    }
}

public extension TrainerEditPlan {
    var applyability: TrainerEditApplyability {
        validateApplyability()
    }

    var isApplyable: Bool {
        applyability.isApplyable
    }

    func validateApplyability(fileManager: FileManager = .default) -> TrainerEditApplyability {
        TrainerEditApplySafety.applyability(for: self, fileManager: fileManager)
    }
}

public struct AppliedTrainerFileChange: Codable, Equatable, Identifiable {
    public var id: String { path }

    public let path: String
    public let backupPath: String
    public let byteCount: Int

    public init(path: String, backupPath: String, byteCount: Int) {
        self.path = path
        self.backupPath = backupPath
        self.byteCount = byteCount
    }
}

public struct TrainerApplyResult: Codable, Equatable, Identifiable {
    public let id: String
    public let backupRootPath: String
    public let appliedChanges: [AppliedTrainerFileChange]
    public let diagnostics: [Diagnostic]

    public init(id: String = UUID().uuidString, backupRootPath: String, appliedChanges: [AppliedTrainerFileChange], diagnostics: [Diagnostic] = []) {
        self.id = id
        self.backupRootPath = backupRootPath
        self.appliedChanges = appliedChanges
        self.diagnostics = diagnostics
    }
}

public enum ProjectTrainerCatalogBuilder {
    public static func build(path: String, fileManager: FileManager = .default) throws -> ProjectTrainerCatalog {
        let index = try GameAdapterRegistry.index(path: path, fileManager: fileManager)
        return try build(index: index, fileManager: fileManager)
    }

    public static func build(index: ProjectIndex, fileManager: FileManager = .default) throws -> ProjectTrainerCatalog {
        let root = URL(fileURLWithPath: index.root.path).standardizedFileURL
        guard let descriptor = TrainerCatalogDescriptor.descriptor(for: index.profile) else {
            return ProjectTrainerCatalog(
                root: index.root,
                profile: index.profile,
                adapterID: index.adapterID,
                adapterName: index.adapterName,
                trainers: [],
                diagnostics: [
                    Diagnostic(
                        severity: .warning,
                        code: "TRAINER_CATALOG_UNSUPPORTED_PROFILE",
                        message: "Trainer editing is currently available for classic Emerald and FireRed source trees. This profile remains read-only.",
                        span: SourceSpan(relativePath: index.root.path, startLine: 1)
                    )
                ]
            )
        }

        var diagnostics: [Diagnostic] = []
        let constants = readConstants(descriptor: descriptor, root: root, fileManager: fileManager)
        let trainerEntries = try readTrainerEntries(descriptor: descriptor, root: root, fileManager: fileManager, diagnostics: &diagnostics)
        let partyBlocks = try readPartyBlocks(descriptor: descriptor, root: root, fileManager: fileManager, diagnostics: &diagnostics)
        let defaultMovesBySpecies = try readDefaultMoves(descriptor: descriptor, root: root, fileManager: fileManager)
        let partyBySymbol = Dictionary(uniqueKeysWithValues: partyBlocks.map { ($0.symbol, $0) })
        let constantSymbols = constants.mapValues { Set($0.map(\.symbol)) }

        let trainers = trainerEntries.map { entry -> TrainerDetail in
            detail(
                from: entry,
                partyBySymbol: partyBySymbol,
                defaultMovesBySpecies: defaultMovesBySpecies,
                constants: constantSymbols,
                descriptor: descriptor
            )
        }

        diagnostics.append(contentsOf: trainers.flatMap(\.diagnostics))
        return ProjectTrainerCatalog(
            root: index.root,
            profile: index.profile,
            adapterID: index.adapterID,
            adapterName: index.adapterName,
            trainers: trainers.sorted { $0.sourceSpan.startLine < $1.sourceSpan.startLine },
            constants: constants,
            defaultMoveLearnsets: defaultMovesBySpecies,
            diagnostics: diagnostics
        )
    }

    private static func readTrainerEntries(
        descriptor: TrainerCatalogDescriptor,
        root: URL,
        fileManager: FileManager,
        diagnostics: inout [Diagnostic]
    ) throws -> [CInitializerEntry] {
        let path = root.appendingPathComponent(descriptor.trainerPath)
        guard fileManager.fileExists(atPath: path.path) else {
            diagnostics.append(missingDiagnostic("TRAINERS_SOURCE_MISSING", path: descriptor.trainerPath))
            return []
        }
        let text = try readText(path)
        let parsed = CInitializerParser.tableEntries(
            in: text,
            descriptor: CInitializerTableDescriptor(
                module: .trainers,
                relativePath: descriptor.trainerPath,
                tableSymbol: "gTrainers",
                entryStyle: .bracketed
            )
        )
        diagnostics.append(contentsOf: parsed.diagnostics)
        let startLinesBySymbol = trainerStartLines(in: text)
        return parsed.entries
            .filter { $0.symbol.hasPrefix("TRAINER_") }
            .map { adjustedTrainerEntry($0, startLinesBySymbol: startLinesBySymbol, relativePath: descriptor.trainerPath) }
    }

    private static func readPartyBlocks(
        descriptor: TrainerCatalogDescriptor,
        root: URL,
        fileManager: FileManager,
        diagnostics: inout [Diagnostic]
    ) throws -> [TrainerPartyBlock] {
        let path = root.appendingPathComponent(descriptor.partyPath)
        guard fileManager.fileExists(atPath: path.path) else {
            diagnostics.append(missingDiagnostic("TRAINER_PARTIES_SOURCE_MISSING", path: descriptor.partyPath))
            return []
        }
        let text = try readText(path)
        return TrainerPartyBlockScanner.blocks(in: text, relativePath: descriptor.partyPath)
    }

    private static func readDefaultMoves(
        descriptor: TrainerCatalogDescriptor,
        root: URL,
        fileManager: FileManager
    ) throws -> [String: [TrainerLevelUpMove]] {
        var learnsetSymbolsBySpecies: [String: String] = [:]
        if let pointerPath = descriptor.levelUpPointerPath {
            let url = root.appendingPathComponent(pointerPath)
            if fileManager.fileExists(atPath: url.path) {
                let text = try readText(url)
                let parsed = CInitializerParser.tableEntries(
                    in: text,
                    descriptor: CInitializerTableDescriptor(
                        module: .learnsets,
                        relativePath: pointerPath,
                        tableSymbol: "gLevelUpLearnsets",
                        entryStyle: .bracketed
                    )
                )
                for entry in parsed.entries where entry.symbol.hasPrefix("SPECIES_") {
                    if let symbol = symbolTokens(in: entry.body).first(where: { $0.hasSuffix("LevelUpLearnset") }) {
                        learnsetSymbolsBySpecies[entry.symbol] = symbol
                    }
                }
            }
        }

        var learnsetsBySymbol: [String: [TrainerLevelUpMove]] = [:]
        for relativePath in descriptor.levelUpPaths {
            let url = root.appendingPathComponent(relativePath)
            guard fileManager.fileExists(atPath: url.path) else { continue }
            let text = try readText(url)
            for block in trainerLevelUpLearnsetBlocks(in: text, relativePath: relativePath) {
                learnsetsBySymbol[block.symbol] = block.moves
                let inferredSpecies = speciesConstant(fromLearnsetSymbol: block.symbol)
                learnsetSymbolsBySpecies[inferredSpecies, default: block.symbol] = block.symbol
            }
        }

        return Dictionary(uniqueKeysWithValues: learnsetSymbolsBySpecies.compactMap { species, symbol in
            guard let moves = learnsetsBySymbol[symbol] else { return nil }
            return (species, moves)
        })
    }

    private static func detail(
        from entry: CInitializerEntry,
        partyBySymbol: [String: TrainerPartyBlock],
        defaultMovesBySpecies: [String: [TrainerLevelUpMove]],
        constants: [TrainerConstantGroup: Set<String>],
        descriptor: TrainerCatalogDescriptor
    ) -> TrainerDetail {
        let fields = entry.fields
        let trainerName = displayTrainerName(fields["trainerName"])
        let trainerClass = compact(fields["trainerClass"]) ?? "TRAINER_CLASS_PKMN_TRAINER_1"
        let encounterMusicGender = compact(fields["encounterMusic_gender"]) ?? "TRAINER_ENCOUNTER_MUSIC_MALE"
        let trainerPic = compact(fields["trainerPic"]) ?? "TRAINER_PIC_HIKER"
        let trainerItems = itemList(fields["items"])
        let doubleBattle = boolValue(fields["doubleBattle"])
        let aiExpression = compact(fields["aiFlags"]) ?? "0"
        let aiFlags = aiExpression == "0" ? [] : symbolTokens(in: aiExpression).filter { $0.hasPrefix("AI_SCRIPT_") }
        let partyReference = partyReference(fields["party"])
        let partyBlock = partyReference.flatMap { partyBySymbol[$0.symbol] }
        var diagnostics: [Diagnostic] = []

        if let partyReference {
            if partyBlock == nil {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "TRAINER_PARTY_UNRESOLVED",
                        message: "\(entry.symbol) references \(partyReference.symbol), but that party array was not found.",
                        span: entry.span
                    )
                )
            } else if partyBlock?.shape != partyReference.shape {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "TRAINER_PARTY_SHAPE_MISMATCH",
                        message: "\(entry.symbol) uses \(partyReference.shape.macroName), but \(partyReference.symbol) is declared as \(partyBlock?.shape.structName ?? "unknown").",
                        span: entry.span
                    )
                )
            }
        } else if fields["party"] != nil || entry.symbol != "TRAINER_NONE" {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "TRAINER_PARTY_UNSUPPORTED",
                    message: "\(entry.symbol) does not use a supported trainer party macro.",
                    span: entry.span
                )
            )
        }

        diagnostics.append(contentsOf: unsupportedFieldDiagnostics(entry: entry))
        diagnostics.append(contentsOf: constantDiagnostics(entry: entry, fields: fields, trainerItems: trainerItems, partyBlock: partyBlock, constants: constants))

        let party = (partyBlock?.members ?? []).map { member in
            member.withDefaultMoves(defaultMoves(for: member.species, level: member.level, learnsets: defaultMovesBySpecies[member.species] ?? []))
        }
        let isEditable = diagnostics.allSatisfy { $0.severity != .error }
            && partyReference != nil
            && partyBlock != nil
            && partyBlock?.shape == partyReference?.shape

        return TrainerDetail(
            trainerID: entry.symbol,
            displayName: displayName(id: entry.symbol, trainerName: trainerName),
            trainerName: trainerName,
            trainerClass: trainerClass,
            encounterMusicGender: encounterMusicGender,
            trainerPic: trainerPic,
            trainerItems: trainerItems,
            doubleBattle: doubleBattle,
            aiFlags: aiFlags,
            aiFlagsExpression: aiExpression,
            partyShape: partyReference?.shape,
            partySymbol: partyReference?.symbol,
            sourceSpan: entry.span,
            partySourceSpan: partyBlock?.span,
            party: party,
            diagnostics: diagnostics,
            sourcePreview: preview(entry.body, limit: 18),
            partyPreview: partyBlock.map { preview($0.body, limit: 18) },
            isEditable: isEditable
        )
    }

    private static func unsupportedFieldDiagnostics(entry: CInitializerEntry) -> [Diagnostic] {
        let supported = Set([
            "trainerClass",
            "encounterMusic_gender",
            "trainerPic",
            "trainerName",
            "items",
            "doubleBattle",
            "aiFlags",
            "party"
        ])
        let unsupported = Set(entry.fields.keys).subtracting(supported)
        guard !unsupported.isEmpty else { return [] }
        return [
            Diagnostic(
                severity: .error,
                code: "TRAINER_ENTRY_UNSUPPORTED_FIELDS",
                message: "\(entry.symbol) has unsupported trainer fields: \(unsupported.sorted().joined(separator: ", ")).",
                span: entry.span
            )
        ]
    }

    private static func constantDiagnostics(
        entry: CInitializerEntry,
        fields: [String: String],
        trainerItems: [String],
        partyBlock: TrainerPartyBlock?,
        constants: [TrainerConstantGroup: Set<String>]
    ) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        appendUnknown(symbols: symbolTokens(in: fields["trainerClass"] ?? "").filter { $0.hasPrefix("TRAINER_CLASS_") }, group: .trainerClasses, constants: constants, entry: entry, diagnostics: &diagnostics)
        appendUnknown(symbols: symbolTokens(in: fields["trainerPic"] ?? "").filter { $0.hasPrefix("TRAINER_PIC_") }, group: .trainerPics, constants: constants, entry: entry, diagnostics: &diagnostics)
        appendUnknown(symbols: symbolTokens(in: fields["encounterMusic_gender"] ?? "").filter { $0.hasPrefix("TRAINER_ENCOUNTER_MUSIC_") || $0 == "F_TRAINER_FEMALE" }, group: .encounterMusic, constants: constants, entry: entry, diagnostics: &diagnostics)
        appendUnknown(symbols: symbolTokens(in: fields["aiFlags"] ?? "").filter { $0.hasPrefix("AI_SCRIPT_") }, group: .aiFlags, constants: constants, entry: entry, diagnostics: &diagnostics)
        appendUnknown(symbols: trainerItems.filter { $0 != "ITEM_NONE" }, group: .items, constants: constants, entry: entry, diagnostics: &diagnostics)

        for member in partyBlock?.members ?? [] {
            appendUnknown(symbols: [member.species].filter { !$0.isEmpty && $0 != "SPECIES_NONE" }, group: .species, constants: constants, entry: entry, diagnostics: &diagnostics)
            appendUnknown(symbols: [member.heldItem].compactMap { $0 }.filter { $0 != "ITEM_NONE" }, group: .items, constants: constants, entry: entry, diagnostics: &diagnostics)
            appendUnknown(symbols: member.moves.filter { $0 != "MOVE_NONE" }, group: .moves, constants: constants, entry: entry, diagnostics: &diagnostics)
            appendUnknown(symbols: [member.nature].compactMap { $0 }.filter { !$0.isEmpty }, group: .natures, constants: constants, entry: entry, diagnostics: &diagnostics)
            diagnostics.append(contentsOf: member.diagnostics)
        }
        return diagnostics
    }

    private static func appendUnknown(
        symbols: [String],
        group: TrainerConstantGroup,
        constants: [TrainerConstantGroup: Set<String>],
        entry: CInitializerEntry,
        diagnostics: inout [Diagnostic]
    ) {
        let known = constants[group] ?? []
        for symbol in Set(symbols) where !known.contains(symbol) {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "TRAINER_CONSTANT_UNRESOLVED",
                    message: "\(entry.symbol) references \(symbol), but it is not defined in the current project constants.",
                    span: entry.span
                )
            )
        }
    }

    private static func readConstants(
        descriptor: TrainerCatalogDescriptor,
        root: URL,
        fileManager: FileManager
    ) -> [TrainerConstantGroup: [TrainerConstant]] {
        var result: [TrainerConstantGroup: [TrainerConstant]] = [:]
        for constantDescriptor in descriptor.constants {
            let url = root.appendingPathComponent(constantDescriptor.path)
            guard fileManager.fileExists(atPath: url.path), let text = try? readText(url) else {
                continue
            }
            result[constantDescriptor.group, default: []].append(contentsOf: constants(in: text, descriptor: constantDescriptor))
        }
        return result.mapValues { constants in
            constants.sorted { $0.symbol < $1.symbol }
        }
    }

    private static func constants(in text: String, descriptor: TrainerConstantDescriptor) -> [TrainerConstant] {
        let lines = text.components(separatedBy: .newlines)
        return lines.enumerated().compactMap { index, line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("#define ") else { return nil }
            let parts = trimmed.split(maxSplits: 2, whereSeparator: { $0.isWhitespace }).map(String.init)
            guard parts.count >= 3 else { return nil }
            let symbol = parts[1]
            guard descriptor.prefixes.contains(where: { symbol.hasPrefix($0) }) || descriptor.exactSymbols.contains(symbol) else {
                return nil
            }
            return TrainerConstant(symbol: symbol, value: parts[2], sourceSpan: SourceSpan(relativePath: descriptor.path, startLine: index + 1))
        }
    }

    private static func missingDiagnostic(_ code: String, path: String) -> Diagnostic {
        Diagnostic(severity: .warning, code: code, message: "Trainer catalog source is missing: \(path).", span: SourceSpan(relativePath: path, startLine: 1))
    }

    private static func trainerStartLines(in text: String) -> [String: Int] {
        var result: [String: Int] = [:]
        for (index, line) in text.components(separatedBy: .newlines).enumerated() {
            guard let open = line.firstIndex(of: "["), let close = line[open...].firstIndex(of: "]") else {
                continue
            }
            let symbol = line[line.index(after: open)..<close].trimmingCharacters(in: .whitespacesAndNewlines)
            guard symbol.hasPrefix("TRAINER_") else { continue }
            result[symbol] = index + 1
        }
        return result
    }

    private static func adjustedTrainerEntry(
        _ entry: CInitializerEntry,
        startLinesBySymbol: [String: Int],
        relativePath: String
    ) -> CInitializerEntry {
        guard let startLine = startLinesBySymbol[entry.symbol] else {
            return entry
        }
        return CInitializerEntry(
            symbol: entry.symbol,
            body: entry.body,
            span: SourceSpan(
                relativePath: relativePath,
                startLine: startLine,
                endLine: max(startLine, entry.span.endLine)
            ),
            ordinal: entry.ordinal,
            fields: entry.fields
        )
    }
}

public enum TrainerMutationPlanner {
    public static func plan(
        catalog: ProjectTrainerCatalog,
        draft: TrainerEditDraft,
        fileManager: FileManager = .default
    ) -> TrainerEditPlan {
        let root = URL(fileURLWithPath: catalog.root.path).standardizedFileURL
        guard let descriptor = TrainerCatalogDescriptor.descriptor(for: catalog.profile) else {
            return blockedPlan(
                catalog: catalog,
                draft: draft,
                diagnostics: [
                    Diagnostic(severity: .error, code: "TRAINER_PLAN_UNSUPPORTED_PROFILE", message: "Trainer apply is only available for classic Emerald and FireRed source trees.")
                ]
            )
        }
        guard let trainer = catalog.trainers.first(where: { $0.trainerID == draft.trainerID }) else {
            return blockedPlan(
                catalog: catalog,
                draft: draft,
                diagnostics: [
                    Diagnostic(severity: .error, code: "TRAINER_PLAN_TARGET_MISSING", message: "Trainer \(draft.trainerID) is not in the current catalog.")
                ]
            )
        }

        var diagnostics = plannerDiagnostics(catalog: catalog, trainer: trainer, draft: draft)
        var changes: [TrainerEditFileChange] = []

        if diagnostics.allSatisfy({ $0.severity != .error }) {
            if let trainerChange = rewriteChange(
                root: root,
                path: descriptor.trainerPath,
                span: trainer.sourceSpan,
                replacement: renderTrainerEntry(draft)
            ) {
                changes.append(trainerChange)
            }
            if let partySpan = trainer.partySourceSpan,
               let partyChange = rewriteChange(
                root: root,
                path: descriptor.partyPath,
                span: partySpan,
                replacement: renderPartyBlock(draft, originalTrainer: trainer)
               ) {
                changes.append(partyChange)
            } else {
                diagnostics.append(
                    Diagnostic(severity: .error, code: "TRAINER_PARTY_SPAN_MISSING", message: "\(draft.trainerID) has no editable party source span.")
                )
            }
        }

        let plannedChanges = changes.map {
            PlannedChange(path: $0.path, summary: $0.summary, span: SourceSpan(relativePath: $0.path, startLine: 1))
        }
        let mutationPlan = MutationPlan(
            title: "Apply trainer edits to \(draft.trainerID)",
            summary: "\(changes.count) source file change(s) for trainer battle data.",
            changes: plannedChanges,
            diagnostics: diagnostics,
            requiresExplicitApply: true
        )
        return TrainerEditPlan(
            rootPath: catalog.root.path,
            trainerID: draft.trainerID,
            draft: draft,
            changes: changes,
            diagnostics: diagnostics,
            mutationPlan: mutationPlan,
            backupRelativeRoot: ".pokemonhackstudio/backups/\(backupTimestamp())"
        )
    }

    private static func blockedPlan(catalog: ProjectTrainerCatalog, draft: TrainerEditDraft, diagnostics: [Diagnostic]) -> TrainerEditPlan {
        let mutationPlan = MutationPlan(
            title: "Trainer edits blocked for \(draft.trainerID)",
            summary: "No source files are applyable until diagnostics are resolved.",
            diagnostics: diagnostics,
            requiresExplicitApply: true
        )
        return TrainerEditPlan(
            rootPath: catalog.root.path,
            trainerID: draft.trainerID,
            draft: draft,
            changes: [],
            diagnostics: diagnostics,
            mutationPlan: mutationPlan,
            backupRelativeRoot: ".pokemonhackstudio/backups/\(backupTimestamp())"
        )
    }

    private static func plannerDiagnostics(catalog: ProjectTrainerCatalog, trainer: TrainerDetail, draft: TrainerEditDraft) -> [Diagnostic] {
        var diagnostics = trainer.diagnostics.filter { $0.severity == .error }
        guard trainer.isEditable else {
            diagnostics.append(Diagnostic(severity: .error, code: "TRAINER_NOT_EDITABLE", message: "\(trainer.trainerID) is read-only until its source diagnostics are resolved.", span: trainer.sourceSpan))
            return diagnostics
        }
        if draft.party.isEmpty || draft.party.count > 6 {
            diagnostics.append(Diagnostic(severity: .error, code: "TRAINER_PARTY_SIZE_INVALID", message: "Trainer parties must contain 1 to 6 Pokemon.", span: trainer.sourceSpan))
        }
        if draft.partySymbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            diagnostics.append(Diagnostic(severity: .error, code: "TRAINER_PARTY_SYMBOL_MISSING", message: "Trainer party symbol is required.", span: trainer.sourceSpan))
        }
        let constants = catalog.constants.mapValues { Set($0.map(\.symbol)) }
        appendDraftConstantDiagnostics(draft: draft, constants: constants, trainer: trainer, diagnostics: &diagnostics)
        return diagnostics
    }

    private static func appendDraftConstantDiagnostics(
        draft: TrainerEditDraft,
        constants: [TrainerConstantGroup: Set<String>],
        trainer: TrainerDetail,
        diagnostics: inout [Diagnostic]
    ) {
        appendDraftUnknown([draft.trainerClass], group: .trainerClasses, constants: constants, trainer: trainer, diagnostics: &diagnostics)
        appendDraftUnknown(symbolTokens(in: draft.encounterMusicGender).filter { $0.hasPrefix("TRAINER_ENCOUNTER_MUSIC_") || $0 == "F_TRAINER_FEMALE" }, group: .encounterMusic, constants: constants, trainer: trainer, diagnostics: &diagnostics)
        appendDraftUnknown([draft.trainerPic], group: .trainerPics, constants: constants, trainer: trainer, diagnostics: &diagnostics)
        appendDraftUnknown(draft.trainerItems.filter { $0 != "ITEM_NONE" }, group: .items, constants: constants, trainer: trainer, diagnostics: &diagnostics)
        appendDraftUnknown(draft.aiFlags, group: .aiFlags, constants: constants, trainer: trainer, diagnostics: &diagnostics)
        let originalMembersBySlot = Dictionary(uniqueKeysWithValues: trainer.party.map { ($0.slot, $0) })
        for member in draft.party {
            let originalMember = originalMembersBySlot[member.slot]
            appendDraftUnknown([member.species], group: .species, constants: constants, trainer: trainer, diagnostics: &diagnostics)
            if draft.partyShape.usesHeldItems {
                appendDraftUnknown([member.heldItem].filter { $0 != "ITEM_NONE" }, group: .items, constants: constants, trainer: trainer, diagnostics: &diagnostics)
            }
            if draft.partyShape.usesCustomMoves {
                appendDraftUnknown(member.moves.filter { $0 != "MOVE_NONE" }, group: .moves, constants: constants, trainer: trainer, diagnostics: &diagnostics)
            }
            let originalNature = originalMember?.nature ?? "NATURE_HARDY"
            if originalMember?.supportsNature == true || member.nature != originalNature {
                appendDraftUnknown([member.nature].filter { !$0.isEmpty }, group: .natures, constants: constants, trainer: trainer, diagnostics: &diagnostics)
            }
            if !(1...100).contains(member.level) {
                diagnostics.append(Diagnostic(severity: .error, code: "TRAINER_PARTY_LEVEL_INVALID", message: "Party slot \(member.slot + 1) level must be between 1 and 100.", span: trainer.sourceSpan))
            }
            if !(0...255).contains(member.iv) {
                diagnostics.append(Diagnostic(severity: .error, code: "TRAINER_PARTY_IV_SOURCE_INVALID", message: "Party slot \(member.slot + 1) source IV byte must be between 0 and 255.", span: trainer.sourceSpan))
            }
            for value in member.ivs.values where !(0...31).contains(value) {
                diagnostics.append(Diagnostic(severity: .error, code: "TRAINER_PARTY_IV_INVALID", message: "Party slot \(member.slot + 1) IVs must be between 0 and 31.", span: trainer.sourceSpan))
                break
            }
            if !member.ivs.isUniform && originalMember?.supportsIndividualIVs != true {
                diagnostics.append(Diagnostic(severity: .error, code: "TRAINER_PARTY_INDIVIDUAL_IVS_UNSUPPORTED", message: "Classic trainer party sources store one shared IV value for party slot \(member.slot + 1). Set all six IVs equal or use a source format with per-stat IVs.", span: trainer.sourceSpan))
            }
            if originalMember?.supportsNature != true && member.nature != originalNature {
                diagnostics.append(Diagnostic(severity: .error, code: "TRAINER_PARTY_NATURE_UNSUPPORTED", message: "This trainer party source does not store a nature for party slot \(member.slot + 1). Nature edits are visible, but cannot be applied until the source shape supports natures.", span: trainer.sourceSpan))
            }
        }
    }

    private static func appendDraftUnknown(
        _ symbols: [String],
        group: TrainerConstantGroup,
        constants: [TrainerConstantGroup: Set<String>],
        trainer: TrainerDetail,
        diagnostics: inout [Diagnostic]
    ) {
        let known = constants[group] ?? []
        for symbol in Set(symbols) where !symbol.isEmpty && !known.contains(symbol) {
            diagnostics.append(Diagnostic(severity: .error, code: "TRAINER_DRAFT_CONSTANT_UNRESOLVED", message: "\(symbol) is not defined in the current project constants.", span: trainer.sourceSpan))
        }
    }

    private static func rewriteChange(root: URL, path: String, span: SourceSpan, replacement: String) -> TrainerEditFileChange? {
        let url = root.appendingPathComponent(path)
        guard let originalText = try? readText(url), let originalData = originalText.data(using: .utf8) else {
            return TrainerEditFileChange(
                path: path,
                summary: "Read \(path) before trainer rewrite",
                originalByteCount: 0,
                newByteCount: 0,
                newData: Data(),
                textPreview: nil
            )
        }
        let newText = replaceLines(in: originalText, span: span, replacement: replacement)
        guard newText != originalText, let newData = newText.data(using: .utf8) else { return nil }
        return TrainerEditFileChange(
            path: path,
            summary: "Update \(span.relativePath == path ? "trainer source block" : "trainer data")",
            originalByteCount: originalData.count,
            originalSHA1: pokemonHackSHA1Hex(originalData),
            newByteCount: newData.count,
            newData: newData,
            textPreview: replacement
        )
    }

    private static func renderTrainerEntry(_ draft: TrainerEditDraft) -> String {
        let items = normalizedTrainerItems(draft.trainerItems)
        let itemsText = items.allSatisfy { $0 == "ITEM_NONE" } ? "{}" : "{\(items.joined(separator: ", "))}"
        let aiText = draft.aiFlags.isEmpty ? "0" : draft.aiFlags.joined(separator: " | ")
        return """
            [\(draft.trainerID)] =
            {
                .trainerClass = \(draft.trainerClass),
                .encounterMusic_gender = \(draft.encounterMusicGender),
                .trainerPic = \(draft.trainerPic),
                .trainerName = _("\(escapeCString(draft.trainerName))"),
                .items = \(itemsText),
                .doubleBattle = \(draft.doubleBattle ? "TRUE" : "FALSE"),
                .aiFlags = \(aiText),
                .party = \(draft.partyShape.macroName)(\(draft.partySymbol)),
            },
        """
    }

    private static func renderPartyBlock(_ draft: TrainerEditDraft, originalTrainer: TrainerDetail) -> String {
        let originalMembersBySlot = Dictionary(uniqueKeysWithValues: originalTrainer.party.map { ($0.slot, $0) })
        let members = draft.party.sorted { $0.slot < $1.slot }.map { renderPartyMember($0, shape: draft.partyShape, originalMember: originalMembersBySlot[$0.slot]) }
            .joined(separator: "\n")
        return """
        static const struct \(draft.partyShape.structName) \(draft.partySymbol)[] = {
        \(members)
        };
        """
    }

    private static func renderPartyMember(_ member: TrainerPartyPokemonDraft, shape: TrainerPartyShape, originalMember: TrainerPartyPokemon?) -> String {
        var lines = [
            "    {",
            "        .iv = \(sourceIV(for: member, originalMember: originalMember)),",
            "        .lvl = \(member.level),",
            "        .species = \(member.species),"
        ]
        if shape.usesHeldItems {
            lines.append("        .heldItem = \(member.heldItem),")
        }
        if originalMember?.supportsNature == true {
            lines.append("        .nature = \(member.nature),")
        }
        if shape.usesCustomMoves {
            let moves = Array((member.moves + Array(repeating: "MOVE_NONE", count: 4)).prefix(4))
            lines.append("        .moves = { \(moves.joined(separator: ", ")) },")
        }
        lines.append("    },")
        return lines.joined(separator: "\n")
    }

    private static func sourceIV(for member: TrainerPartyPokemonDraft, originalMember: TrainerPartyPokemon?) -> Int {
        let originalSource = originalMember?.iv ?? member.iv
        let originalIVs = originalMember?.ivs ?? TrainerPokemonIVs.uniform(sourceIVToActualIV(member.iv))
        if member.iv != originalSource && member.ivs == originalIVs {
            return min(255, max(0, member.iv))
        }
        if member.ivs == originalIVs {
            return min(255, max(0, originalSource))
        }
        if let uniformValue = member.ivs.uniformValue {
            return actualIVToSourceIV(uniformValue)
        }
        return min(255, max(0, member.iv))
    }

    private static func backupTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "\(formatter.string(from: Date()))-\(UUID().uuidString.prefix(8))"
    }
}

public enum TrainerMutationApplier {
    public static func apply(plan: TrainerEditPlan, fileManager: FileManager = .default) throws -> TrainerApplyResult {
        let root = URL(fileURLWithPath: plan.rootPath).standardizedFileURL
        let backupRoot = root.appendingPathComponent(plan.backupRelativeRoot)
        let applyability = plan.validateApplyability(fileManager: fileManager)
        guard applyability.isApplyable else {
            return TrainerApplyResult(backupRootPath: backupRoot.path, appliedChanges: [], diagnostics: applyability.diagnostics)
        }
        guard !plan.changes.isEmpty else {
            return TrainerApplyResult(backupRootPath: backupRoot.path, appliedChanges: [])
        }

        try fileManager.createDirectory(at: backupRoot, withIntermediateDirectories: true)
        var applied: [AppliedTrainerFileChange] = []
        for change in plan.changes {
            let destination = root.appendingPathComponent(change.path)
            let backup = backupRoot.appendingPathComponent(change.path)
            try fileManager.createDirectory(at: backup.deletingLastPathComponent(), withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: destination.path) {
                if fileManager.fileExists(atPath: backup.path) {
                    try fileManager.removeItem(at: backup)
                }
                try fileManager.copyItem(at: destination, to: backup)
            }
            try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            try change.newData.write(to: destination, options: .atomic)
            applied.append(AppliedTrainerFileChange(path: change.path, backupPath: backup.path, byteCount: change.newData.count))
        }
        return TrainerApplyResult(backupRootPath: backupRoot.path, appliedChanges: applied)
    }
}

private struct TrainerCatalogDescriptor {
    let trainerPath: String
    let partyPath: String
    let levelUpPointerPath: String?
    let levelUpPaths: [String]
    let constants: [TrainerConstantDescriptor]

    static func descriptor(for profile: GameProfile) -> TrainerCatalogDescriptor? {
        switch profile {
        case .pokeemerald, .pokefirered:
            TrainerCatalogDescriptor(
                trainerPath: "src/data/trainers.h",
                partyPath: "src/data/trainer_parties.h",
                levelUpPointerPath: "src/data/pokemon/level_up_learnset_pointers.h",
                levelUpPaths: ["src/data/pokemon/level_up_learnsets.h"],
                constants: [
                    TrainerConstantDescriptor(path: "include/constants/species.h", group: .species, prefixes: ["SPECIES_"]),
                    TrainerConstantDescriptor(path: "include/constants/moves.h", group: .moves, prefixes: ["MOVE_"]),
                    TrainerConstantDescriptor(path: "include/constants/items.h", group: .items, prefixes: ["ITEM_"]),
                    TrainerConstantDescriptor(path: "include/constants/pokemon.h", group: .natures, prefixes: ["NATURE_"]),
                    TrainerConstantDescriptor(path: "include/constants/trainers.h", group: .trainerClasses, prefixes: ["TRAINER_CLASS_"]),
                    TrainerConstantDescriptor(path: "include/constants/trainers.h", group: .trainerPics, prefixes: ["TRAINER_PIC_"]),
                    TrainerConstantDescriptor(path: "include/constants/trainers.h", group: .encounterMusic, prefixes: ["TRAINER_ENCOUNTER_MUSIC_"], exactSymbols: ["F_TRAINER_FEMALE"]),
                    TrainerConstantDescriptor(path: "include/constants/battle_ai.h", group: .aiFlags, prefixes: ["AI_SCRIPT_"])
                ]
            )
        default:
            nil
        }
    }
}

private struct TrainerConstantDescriptor {
    let path: String
    let group: TrainerConstantGroup
    let prefixes: [String]
    let exactSymbols: [String]

    init(path: String, group: TrainerConstantGroup, prefixes: [String], exactSymbols: [String] = []) {
        self.path = path
        self.group = group
        self.prefixes = prefixes
        self.exactSymbols = exactSymbols
    }
}

private struct TrainerPartyReference {
    let shape: TrainerPartyShape
    let symbol: String
}

private struct TrainerPartyBlock {
    let symbol: String
    let shape: TrainerPartyShape
    let span: SourceSpan
    let body: String
    let members: [TrainerPartyPokemon]
}

private enum TrainerPartyBlockScanner {
    static func blocks(in text: String, relativePath: String) -> [TrainerPartyBlock] {
        let pattern = #"(?m)^\s*static\s+const\s+struct\s+(TrainerMon(?:NoItem|Item)(?:DefaultMoves|CustomMoves))\s+(sParty_[A-Za-z0-9_]+)\[\]\s*="#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let characters = Array(text)
        let lineNumbers = LineNumberIndex(text: text)
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: nsRange).compactMap { regexMatch in
            let match = (0..<regexMatch.numberOfRanges).map { index -> String in
                let range = regexMatch.range(at: index)
                guard range.location != NSNotFound, let swiftRange = Range(range, in: text) else { return "" }
                return String(text[swiftRange])
            }
            guard
                match.count >= 3,
                let declarationRange = Range(regexMatch.range(at: 0), in: text),
                let shape = TrainerPartyShape.structName(match[1])
            else {
                return nil
            }
            let startOffset = text.distance(from: text.startIndex, to: declarationRange.lowerBound)
            let searchOffset = text.distance(from: text.startIndex, to: declarationRange.upperBound)
            guard
                let openOffset = firstCharacter("{", in: characters, after: searchOffset),
                let closeOffset = matchingCloseBrace(in: characters, from: openOffset),
                let semicolonOffset = firstCharacter(";", in: characters, after: closeOffset)
            else {
                return nil
            }
            let endOffset = semicolonOffset + 1
            let startIndex = text.index(text.startIndex, offsetBy: startOffset)
            let endIndex = text.index(text.startIndex, offsetBy: endOffset)
            let body = String(text[startIndex..<endIndex])
            let symbol = match[2]
            let parsed = CInitializerParser.tableEntries(
                in: body,
                descriptor: CInitializerTableDescriptor(
                    module: .trainers,
                    relativePath: relativePath,
                    tableSymbol: symbol,
                    entryStyle: .positional
                )
            )
            let startLine = lineNumbers.lineNumber(at: startOffset)
            let members = parsed.entries.enumerated().map { index, entry in
                partyMember(from: entry, slot: index, shape: shape)
            }
            return TrainerPartyBlock(
                symbol: symbol,
                shape: shape,
                span: SourceSpan(relativePath: relativePath, startLine: startLine, endLine: lineNumbers.lineNumber(at: semicolonOffset)),
                body: body,
                members: members
            )
        }
    }

    private static func partyMember(from entry: CInitializerEntry, slot: Int, shape: TrainerPartyShape) -> TrainerPartyPokemon {
        let fields = entry.fields
        var diagnostics: [Diagnostic] = []
        if fields.isEmpty {
            diagnostics.append(Diagnostic(severity: .error, code: "TRAINER_PARTY_MEMBER_UNSUPPORTED", message: "Party slot \(slot + 1) uses a macro or unsupported initializer shape.", span: entry.span))
        }
        let species = compact(fields["species"]) ?? "SPECIES_NONE"
        let level = intValue(fields["lvl"])
        let iv = intValue(fields["iv"])
        let nature = compact(fields["nature"])
        if level == nil {
            diagnostics.append(Diagnostic(severity: .error, code: "TRAINER_PARTY_LEVEL_MISSING", message: "Party slot \(slot + 1) is missing lvl.", span: entry.span))
        }
        if iv == nil {
            diagnostics.append(Diagnostic(severity: .error, code: "TRAINER_PARTY_IV_MISSING", message: "Party slot \(slot + 1) is missing iv.", span: entry.span))
        }
        let moves = shape.usesCustomMoves ? symbolTokens(in: fields["moves"] ?? "").filter { $0.hasPrefix("MOVE_") } : []
        return TrainerPartyPokemon(
            slot: slot,
            species: species,
            level: level,
            iv: iv,
            ivs: TrainerPokemonIVs.uniform(sourceIVToActualIV(iv ?? 0)),
            nature: nature,
            heldItem: shape.usesHeldItems ? compact(fields["heldItem"]) ?? "ITEM_NONE" : nil,
            moves: shape.usesCustomMoves ? Array((moves + Array(repeating: "MOVE_NONE", count: 4)).prefix(4)) : [],
            supportsIndividualIVs: false,
            supportsNature: nature != nil,
            sourceSpan: entry.span,
            diagnostics: diagnostics,
            sourcePreview: preview(entry.body, limit: 12)
        )
    }
}

private enum TrainerEditApplySafety {
    static func applyability(for plan: TrainerEditPlan, fileManager: FileManager) -> TrainerEditApplyability {
        var diagnostics = plan.diagnostics.filter { $0.severity == .error }
        let root = URL(fileURLWithPath: plan.rootPath).standardizedFileURL
        guard !plan.rootPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            diagnostics.append(Diagnostic(severity: .error, code: "TRAINER_APPLY_ROOT_MISSING", message: "Trainer apply root path is missing."))
            return TrainerEditApplyability(isApplyable: false, diagnostics: diagnostics)
        }
        guard fileManager.fileExists(atPath: root.path) else {
            diagnostics.append(Diagnostic(severity: .error, code: "TRAINER_APPLY_ROOT_MISSING", message: "Trainer apply root does not exist: \(plan.rootPath)."))
            return TrainerEditApplyability(isApplyable: false, diagnostics: diagnostics)
        }
        guard !plan.changes.isEmpty else {
            diagnostics.append(Diagnostic(severity: .warning, code: "TRAINER_APPLY_NO_CHANGES", message: "No trainer source changes are staged."))
            return TrainerEditApplyability(isApplyable: false, diagnostics: diagnostics)
        }
        for change in plan.changes {
            diagnostics.append(contentsOf: diagnosticsForChange(change, root: root, fileManager: fileManager))
        }
        return TrainerEditApplyability(isApplyable: diagnostics.allSatisfy { $0.severity != .error }, diagnostics: diagnostics)
    }

    private static func diagnosticsForChange(_ change: TrainerEditFileChange, root: URL, fileManager: FileManager) -> [Diagnostic] {
        let destination = root.appendingPathComponent(change.path).standardizedFileURL
        guard isContained(destination, in: root) else {
            return [pathDiagnostic("TRAINER_APPLY_PATH_OUTSIDE_ROOT", "Trainer apply path is outside the project root: \(change.path).", path: change.path)]
        }
        guard fileManager.fileExists(atPath: destination.path) else {
            return [pathDiagnostic("TRAINER_APPLY_SOURCE_MISSING", "Trainer source file is missing before apply: \(change.path).", path: change.path)]
        }
        guard let currentData = try? Data(contentsOf: destination) else {
            return [pathDiagnostic("TRAINER_APPLY_SOURCE_UNREADABLE", "Trainer source file could not be read before apply: \(change.path).", path: change.path)]
        }
        guard currentData.count == change.originalByteCount else {
            return [pathDiagnostic("TRAINER_APPLY_ORIGINAL_SIZE_MISMATCH", "Trainer source file changed since planning: \(change.path).", path: change.path)]
        }
        if let originalSHA1 = change.originalSHA1, pokemonHackSHA1Hex(currentData) != originalSHA1 {
            return [pathDiagnostic("TRAINER_APPLY_ORIGINAL_HASH_MISMATCH", "Trainer source file contents changed since planning: \(change.path).", path: change.path)]
        }
        return []
    }

    private static func isContained(_ url: URL, in root: URL) -> Bool {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        return path == rootPath || path.hasPrefix(rootPath + "/")
    }

    private static func pathDiagnostic(_ code: String, _ message: String, path: String) -> Diagnostic {
        Diagnostic(severity: .error, code: code, message: message, span: SourceSpan(relativePath: path, startLine: 1))
    }
}

private func partyReference(_ value: String?) -> TrainerPartyReference? {
    guard let value else { return nil }
    let pattern = #"(NO_ITEM_DEFAULT_MOVES|NO_ITEM_CUSTOM_MOVES|ITEM_DEFAULT_MOVES|ITEM_CUSTOM_MOVES)\s*\(\s*([A-Za-z0-9_]+)\s*\)"#
    guard let match = regexMatches(pattern, in: value).first, match.count >= 3, let shape = TrainerPartyShape.macro(match[1]) else {
        return nil
    }
    return TrainerPartyReference(shape: shape, symbol: match[2])
}

private func defaultMoves(for species: String, level: Int?, learnsets: [TrainerLevelUpMove]) -> [String] {
    guard let level, !learnsets.isEmpty else {
        return Array(repeating: "MOVE_NONE", count: 4)
    }
    let moves = learnsets
        .filter { $0.level <= level }
        .map(\.move)
        .suffix(4)
    return Array((Array(moves) + Array(repeating: "MOVE_NONE", count: 4)).prefix(4))
}

private func trainerLevelUpLearnsetBlocks(in text: String, relativePath: String) -> [(symbol: String, moves: [TrainerLevelUpMove])] {
    let lines = text.components(separatedBy: .newlines)
    var blocks: [(symbol: String, moves: [TrainerLevelUpMove])] = []
    var index = 0
    while index < lines.count {
        guard let match = regexMatches(#"static\s+const\s+(?:struct\s+LevelUpMove|u16)\s+([A-Za-z0-9_]+)\[\]\s*=\s*\{"#, in: lines[index]).first, match.count >= 2 else {
            index += 1
            continue
        }
        let symbol = match[1]
        let start = index
        var end = index
        while end < lines.count, !lines[end].contains("};") {
            end += 1
        }
        let clampedEnd = min(end, lines.count - 1)
        var moves: [TrainerLevelUpMove] = []
        for lineIndex in start...clampedEnd {
            for moveMatch in regexMatches(#"LEVEL_UP_MOVE\(\s*([0-9]+)\s*,\s*(MOVE_[A-Z0-9_]+)\s*\)"#, in: lines[lineIndex]) {
                guard moveMatch.count >= 3, let level = Int(moveMatch[1]) else { continue }
                moves.append(TrainerLevelUpMove(level: level, move: moveMatch[2]))
            }
        }
        blocks.append((symbol: symbol, moves: moves))
        index = clampedEnd + 1
    }
    return blocks
}

private func speciesConstant(fromLearnsetSymbol symbol: String) -> String {
    var name = symbol
    if name.hasPrefix("s") {
        name.removeFirst()
    }
    if name.hasSuffix("LevelUpLearnset") {
        name.removeLast("LevelUpLearnset".count)
    }
    return "SPECIES_\(screamingSnakeCase(name))"
}

private func screamingSnakeCase(_ value: String) -> String {
    var output = ""
    var previousWasLowercaseOrNumber = false
    for character in value {
        if character == "_" {
            output.append("_")
            previousWasLowercaseOrNumber = false
            continue
        }
        if character.isUppercase, previousWasLowercaseOrNumber, !output.hasSuffix("_") {
            output.append("_")
        }
        output.append(character.uppercased())
        previousWasLowercaseOrNumber = character.isLowercase || character.isNumber
    }
    return output
}

private func sourceIVToActualIV(_ value: Int) -> Int {
    min(31, max(0, value) * 31 / 255)
}

private func actualIVToSourceIV(_ value: Int) -> Int {
    let clamped = min(31, max(0, value))
    guard clamped < 31 else { return 255 }
    return (clamped * 255 + 30) / 31
}

private func boolValue(_ value: String?) -> Bool {
    compact(value) == "TRUE" || compact(value) == "true" || compact(value) == "1"
}

private func itemList(_ value: String?) -> [String] {
    let items = symbolTokens(in: value ?? "").filter { $0.hasPrefix("ITEM_") }
    return normalizedTrainerItems(items)
}

private func normalizedTrainerItems(_ items: [String]) -> [String] {
    Array((items + Array(repeating: "ITEM_NONE", count: 4)).prefix(4))
}

private func displayTrainerName(_ value: String?) -> String {
    guard var value = compact(value) else { return "" }
    if value.hasPrefix("_(\""), value.hasSuffix("\")") {
        value.removeFirst(3)
        value.removeLast(2)
        return value
    }
    if value.hasPrefix("\""), value.hasSuffix("\"") {
        value.removeFirst()
        value.removeLast()
    }
    return value
}

private func displayName(id: String, trainerName: String) -> String {
    trainerName.isEmpty ? id : "\(trainerName) (\(id))"
}

private func compact(_ value: String?) -> String? {
    guard let value else { return nil }
    let compacted = value
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    return compacted.isEmpty ? nil : compacted
}

private func symbolTokens(in text: String) -> [String] {
    text.split { character in
        !(character == "_" || character.isLetter || character.isNumber)
    }.map(String.init)
}

private func intValue(_ value: String?) -> Int? {
    guard let value = compact(value) else { return nil }
    if let integer = Int(value) {
        return integer
    }
    if value.hasPrefix("0x") || value.hasPrefix("0X") {
        return Int(value.dropFirst(2), radix: 16)
    }
    return nil
}

private func preview(_ text: String, limit: Int) -> String {
    text.components(separatedBy: .newlines).prefix(limit).joined(separator: "\n")
}

private func readText(_ url: URL) throws -> String {
    if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
        return utf8
    }
    return try String(contentsOf: url, encoding: .isoLatin1)
}

private func replaceLines(in text: String, span: SourceSpan, replacement: String) -> String {
    var lines = text.components(separatedBy: "\n")
    let hadTrailingNewline = lines.last == ""
    let start = max(0, span.startLine - 1)
    let end = min(max(start, span.endLine - 1), max(0, lines.count - 1))
    let replacementLines = replacement.components(separatedBy: "\n")
    if start <= end, start < lines.count {
        lines.replaceSubrange(start...end, with: replacementLines)
    }
    var joined = lines.joined(separator: "\n")
    if hadTrailingNewline, !joined.hasSuffix("\n") {
        joined.append("\n")
    }
    return joined
}

private func regexMatches(_ pattern: String, in text: String) -> [[String]] {
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
    let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
    return regex.matches(in: text, range: nsRange).map { match in
        (0..<match.numberOfRanges).map { index in
            let range = match.range(at: index)
            guard range.location != NSNotFound, let swiftRange = Range(range, in: text) else { return "" }
            return String(text[swiftRange])
        }
    }
}

private struct LineNumberIndex {
    private let newlineOffsets: [Int]

    init(text: String) {
        var offsets: [Int] = []
        offsets.reserveCapacity(text.count / 40)
        for (offset, character) in text.enumerated() where character == "\n" {
            offsets.append(offset)
        }
        newlineOffsets = offsets
    }

    func lineNumber(at offset: Int) -> Int {
        var low = 0
        var high = newlineOffsets.count
        while low < high {
            let middle = (low + high) / 2
            if newlineOffsets[middle] < offset {
                low = middle + 1
            } else {
                high = middle
            }
        }
        return low + 1
    }
}

private func firstCharacter(_ character: Character, in characters: [Character], after offset: Int) -> Int? {
    var index = max(0, offset)
    while index < characters.count {
        if characters[index] == character {
            return index
        }
        index += 1
    }
    return nil
}

private func matchingCloseBrace(in characters: [Character], from openOffset: Int) -> Int? {
    var index = openOffset
    var depth = 0
    while index < characters.count {
        if characters[index] == "{" {
            depth += 1
        } else if characters[index] == "}" {
            depth -= 1
            if depth == 0 {
                return index
            }
        }
        index += 1
    }
    return nil
}

private func escapeCString(_ value: String) -> String {
    value
        .replacingOccurrences(of: #"\"#, with: #"\\"#)
        .replacingOccurrences(of: #"""#, with: #"\""#)
}
