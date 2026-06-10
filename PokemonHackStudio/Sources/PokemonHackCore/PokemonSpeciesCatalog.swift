import Foundation

public struct ProjectSpeciesCatalog: Codable, Equatable {
    public let root: SourceLocation
    public let profile: GameProfile
    public let adapterID: String
    public let adapterName: String
    public let speciesCount: Int
    public let species: [SpeciesDetail]
    public let constants: [SpeciesConstantGroup: [SpeciesConstant]]
    public let diagnostics: [Diagnostic]

    public init(
        root: SourceLocation,
        profile: GameProfile,
        adapterID: String,
        adapterName: String,
        species: [SpeciesDetail],
        constants: [SpeciesConstantGroup: [SpeciesConstant]] = [:],
        diagnostics: [Diagnostic] = []
    ) {
        self.root = root
        self.profile = profile
        self.adapterID = adapterID
        self.adapterName = adapterName
        self.speciesCount = species.count
        self.species = species
        self.constants = constants
        self.diagnostics = diagnostics
    }
}

public enum SpeciesConstantGroup: String, Codable, Equatable, CaseIterable, Identifiable, Sendable {
    case types
    case abilities
    case eggGroups
    case growthRates
    case bodyColors
    case items
    case moves
    case tmhmMoves
    case tutorMoves
    case evolutionMethods

    public var id: String { rawValue }
}

public struct SpeciesConstant: Codable, Equatable, Identifiable {
    public var id: String { "\(group.rawValue):\(symbol)" }

    public let group: SpeciesConstantGroup
    public let symbol: String
    public let value: String
    public let sourceSpan: SourceSpan

    public init(group: SpeciesConstantGroup, symbol: String, value: String, sourceSpan: SourceSpan) {
        self.group = group
        self.symbol = symbol
        self.value = value
        self.sourceSpan = sourceSpan
    }
}

public struct SpeciesDetail: Codable, Equatable, Identifiable {
    public var id: String { speciesID }

    public let speciesID: String
    public let displayName: String
    public let sourceSpan: SourceSpan
    public let baseStats: SpeciesBaseStats
    public let types: [String]
    public let abilities: [String]
    public let evYield: SpeciesEVYield
    public let training: SpeciesTrainingData
    public let breeding: SpeciesBreedingData
    public let heldItems: SpeciesHeldItems
    public let bodyColor: String?
    public let noFlip: String?
    public let learnsets: SpeciesLearnsets
    public let evolutions: [SpeciesEvolution]
    public let pokedex: SpeciesPokedexEntry?
    public let assets: [SpeciesAsset]
    public let diagnostics: [Diagnostic]
    public let sourcePreview: String
    public let isEditable: Bool

    public init(
        speciesID: String,
        displayName: String,
        sourceSpan: SourceSpan,
        baseStats: SpeciesBaseStats,
        types: [String] = [],
        abilities: [String] = [],
        evYield: SpeciesEVYield = SpeciesEVYield(),
        training: SpeciesTrainingData = SpeciesTrainingData(),
        breeding: SpeciesBreedingData = SpeciesBreedingData(),
        heldItems: SpeciesHeldItems = SpeciesHeldItems(),
        bodyColor: String? = nil,
        noFlip: String? = nil,
        learnsets: SpeciesLearnsets = SpeciesLearnsets(),
        evolutions: [SpeciesEvolution] = [],
        pokedex: SpeciesPokedexEntry? = nil,
        assets: [SpeciesAsset] = [],
        diagnostics: [Diagnostic] = [],
        sourcePreview: String = "",
        isEditable: Bool = false
    ) {
        self.speciesID = speciesID
        self.displayName = displayName
        self.sourceSpan = sourceSpan
        self.baseStats = baseStats
        self.types = types
        self.abilities = abilities
        self.evYield = evYield
        self.training = training
        self.breeding = breeding
        self.heldItems = heldItems
        self.bodyColor = bodyColor
        self.noFlip = noFlip
        self.learnsets = learnsets
        self.evolutions = evolutions
        self.pokedex = pokedex
        self.assets = assets
        self.diagnostics = diagnostics
        self.sourcePreview = sourcePreview
        self.isEditable = isEditable
    }
}

public struct SpeciesBaseStats: Codable, Equatable {
    public let hp: Int?
    public let attack: Int?
    public let defense: Int?
    public let speed: Int?
    public let spAttack: Int?
    public let spDefense: Int?

    public var total: Int? {
        let values = [hp, attack, defense, speed, spAttack, spDefense]
        guard values.allSatisfy({ $0 != nil }) else { return nil }
        return values.compactMap { $0 }.reduce(0, +)
    }

    public init(
        hp: Int? = nil,
        attack: Int? = nil,
        defense: Int? = nil,
        speed: Int? = nil,
        spAttack: Int? = nil,
        spDefense: Int? = nil
    ) {
        self.hp = hp
        self.attack = attack
        self.defense = defense
        self.speed = speed
        self.spAttack = spAttack
        self.spDefense = spDefense
    }
}

public struct SpeciesEVYield: Codable, Equatable {
    public let hp: Int
    public let attack: Int
    public let defense: Int
    public let speed: Int
    public let spAttack: Int
    public let spDefense: Int

    public var total: Int {
        hp + attack + defense + speed + spAttack + spDefense
    }

    public init(
        hp: Int = 0,
        attack: Int = 0,
        defense: Int = 0,
        speed: Int = 0,
        spAttack: Int = 0,
        spDefense: Int = 0
    ) {
        self.hp = hp
        self.attack = attack
        self.defense = defense
        self.speed = speed
        self.spAttack = spAttack
        self.spDefense = spDefense
    }
}

public struct SpeciesTrainingData: Codable, Equatable {
    public let catchRate: String?
    public let expYield: String?
    public let genderRatio: String?
    public let eggCycles: String?
    public let friendship: String?
    public let growthRate: String?
    public let safariZoneFleeRate: String?

    public init(
        catchRate: String? = nil,
        expYield: String? = nil,
        genderRatio: String? = nil,
        eggCycles: String? = nil,
        friendship: String? = nil,
        growthRate: String? = nil,
        safariZoneFleeRate: String? = nil
    ) {
        self.catchRate = catchRate
        self.expYield = expYield
        self.genderRatio = genderRatio
        self.eggCycles = eggCycles
        self.friendship = friendship
        self.growthRate = growthRate
        self.safariZoneFleeRate = safariZoneFleeRate
    }
}

public struct SpeciesBreedingData: Codable, Equatable {
    public let eggGroups: [String]

    public init(eggGroups: [String] = []) {
        self.eggGroups = eggGroups
    }
}

public struct SpeciesHeldItems: Codable, Equatable {
    public let common: String?
    public let rare: String?

    public init(common: String? = nil, rare: String? = nil) {
        self.common = common
        self.rare = rare
    }
}

public struct SpeciesLearnsets: Codable, Equatable {
    public let levelUp: [SpeciesLevelUpMove]
    public let tmhm: [SpeciesMoveReference]
    public let egg: [SpeciesMoveReference]
    public let tutor: [SpeciesMoveReference]
    public let levelUpSymbol: String?
    public let levelUpSourceSpan: SourceSpan?
    public let tmhmSourceSpan: SourceSpan?
    public let eggSourceSpan: SourceSpan?
    public let tutorSourceSpan: SourceSpan?

    public init(
        levelUp: [SpeciesLevelUpMove] = [],
        tmhm: [SpeciesMoveReference] = [],
        egg: [SpeciesMoveReference] = [],
        tutor: [SpeciesMoveReference] = [],
        levelUpSymbol: String? = nil,
        levelUpSourceSpan: SourceSpan? = nil,
        tmhmSourceSpan: SourceSpan? = nil,
        eggSourceSpan: SourceSpan? = nil,
        tutorSourceSpan: SourceSpan? = nil
    ) {
        self.levelUp = levelUp
        self.tmhm = tmhm
        self.egg = egg
        self.tutor = tutor
        self.levelUpSymbol = levelUpSymbol
        self.levelUpSourceSpan = levelUpSourceSpan
        self.tmhmSourceSpan = tmhmSourceSpan
        self.eggSourceSpan = eggSourceSpan
        self.tutorSourceSpan = tutorSourceSpan
    }
}

public struct SpeciesLevelUpMove: Codable, Equatable, Identifiable {
    public var id: String { "\(level):\(move):\(sourceSpan.relativePath):\(sourceSpan.startLine)" }

    public let level: Int
    public let move: String
    public let sourceSpan: SourceSpan

    public init(level: Int, move: String, sourceSpan: SourceSpan) {
        self.level = level
        self.move = move
        self.sourceSpan = sourceSpan
    }
}

public struct SpeciesMoveReference: Codable, Equatable, Identifiable {
    public var id: String { "\(move):\(sourceSpan.relativePath):\(sourceSpan.startLine)" }

    public let move: String
    public let sourceSpan: SourceSpan

    public init(move: String, sourceSpan: SourceSpan) {
        self.move = move
        self.sourceSpan = sourceSpan
    }
}

public struct SpeciesEvolution: Codable, Equatable, Identifiable {
    public var id: String { "\(method):\(parameter):\(targetSpecies):\(sourceSpan.relativePath):\(sourceSpan.startLine)" }

    public let method: String
    public let parameter: String
    public let targetSpecies: String
    public let sourceSpan: SourceSpan

    public init(method: String, parameter: String, targetSpecies: String, sourceSpan: SourceSpan) {
        self.method = method
        self.parameter = parameter
        self.targetSpecies = targetSpecies
        self.sourceSpan = sourceSpan
    }
}

public struct SpeciesPokedexEntry: Codable, Equatable {
    public let categoryName: String?
    public let height: String?
    public let weight: String?
    public let pokemonScale: String?
    public let pokemonOffset: String?
    public let trainerScale: String?
    public let trainerOffset: String?
    public let descriptionSymbol: String?
    public let description: String?
    public let sourceSpan: SourceSpan
    public let descriptionSpan: SourceSpan?

    public init(
        categoryName: String? = nil,
        height: String? = nil,
        weight: String? = nil,
        pokemonScale: String? = nil,
        pokemonOffset: String? = nil,
        trainerScale: String? = nil,
        trainerOffset: String? = nil,
        descriptionSymbol: String? = nil,
        description: String? = nil,
        sourceSpan: SourceSpan,
        descriptionSpan: SourceSpan? = nil
    ) {
        self.categoryName = categoryName
        self.height = height
        self.weight = weight
        self.pokemonScale = pokemonScale
        self.pokemonOffset = pokemonOffset
        self.trainerScale = trainerScale
        self.trainerOffset = trainerOffset
        self.descriptionSymbol = descriptionSymbol
        self.description = description
        self.sourceSpan = sourceSpan
        self.descriptionSpan = descriptionSpan
    }
}

public enum SpeciesAssetKind: String, Codable, Equatable, CaseIterable {
    case front
    case back
    case icon
    case footprint
    case animFront
    case normalPalette
    case shinyPalette

    public var title: String {
        switch self {
        case .front: "Front"
        case .back: "Back"
        case .icon: "Icon"
        case .footprint: "Footprint"
        case .animFront: "Front Animation"
        case .normalPalette: "Normal Palette"
        case .shinyPalette: "Shiny Palette"
        }
    }

    public var filename: String {
        switch self {
        case .front: "front.png"
        case .back: "back.png"
        case .icon: "icon.png"
        case .footprint: "footprint.png"
        case .animFront: "anim_front.png"
        case .normalPalette: "normal.pal"
        case .shinyPalette: "shiny.pal"
        }
    }

    public var isSpriteAsset: Bool {
        switch self {
        case .front, .back, .icon, .footprint, .animFront:
            return true
        case .normalPalette, .shinyPalette:
            return false
        }
    }

    public var isPaletteAsset: Bool {
        !isSpriteAsset
    }

    public var expectedPNGDimensions: (width: Int, height: Int)? {
        switch self {
        case .icon:
            return (32, 64)
        case .footprint:
            return (16, 16)
        default:
            return nil
        }
    }

    public var pngPaletteColorLimit: Int {
        switch self {
        case .footprint:
            return 2
        default:
            return 16
        }
    }
}

public enum SpeciesAssetImportDetectedKind: String, Codable, Equatable {
    case png
    case palette
    case unsupported
}

public enum SpeciesAssetImportValidationStatus: String, Codable, Equatable {
    case ready
    case warning
    case blocked
}

public struct SpeciesAssetImportProvenance: Codable, Equatable {
    public let sourcePath: String
    public let sourceFileName: String
    public let byteCount: Int
    public let sha1: String
    public let expectedKind: SpeciesAssetKind
    public let detectedKind: SpeciesAssetImportDetectedKind
    public let pngMetadata: GraphicsPNGMetadata?
    public let paletteMetadata: GraphicsPaletteMetadata?
    public let status: SpeciesAssetImportValidationStatus
    public let diagnostics: [Diagnostic]

    public init(
        sourcePath: String,
        sourceFileName: String,
        byteCount: Int,
        sha1: String,
        expectedKind: SpeciesAssetKind,
        detectedKind: SpeciesAssetImportDetectedKind,
        pngMetadata: GraphicsPNGMetadata? = nil,
        paletteMetadata: GraphicsPaletteMetadata? = nil,
        status: SpeciesAssetImportValidationStatus,
        diagnostics: [Diagnostic]
    ) {
        self.sourcePath = sourcePath
        self.sourceFileName = sourceFileName
        self.byteCount = byteCount
        self.sha1 = sha1
        self.expectedKind = expectedKind
        self.detectedKind = detectedKind
        self.pngMetadata = pngMetadata
        self.paletteMetadata = paletteMetadata
        self.status = status
        self.diagnostics = diagnostics
    }
}

public enum SpeciesAssetImportValidator {
    public static func provenance(
        sourcePath: String,
        expectedKind: SpeciesAssetKind,
        data: Data
    ) -> SpeciesAssetImportProvenance {
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let pngMetadata = GraphicsMetadataParser.pngMetadata(from: data)
        let sourcePaletteMetadata = sourcePath.lowercased().hasSuffix(".pal")
            ? GraphicsMetadataParser.paletteMetadata(from: data, path: sourcePath)
            : nil
        let binaryPaletteMetadata = GraphicsMetadataParser.gbaPaletteMetadata(from: data)
        let paletteMetadata = sourcePaletteMetadata ?? binaryPaletteMetadata
        let detectedKind = detectedKind(pngMetadata: pngMetadata, paletteMetadata: paletteMetadata)
        let diagnostics = diagnostics(
            sourcePath: sourcePath,
            expectedKind: expectedKind,
            detectedKind: detectedKind,
            data: data,
            pngMetadata: pngMetadata,
            sourcePaletteMetadata: sourcePaletteMetadata,
            binaryPaletteMetadata: binaryPaletteMetadata
        )
        let status: SpeciesAssetImportValidationStatus
        if diagnostics.contains(where: { $0.severity == .error }) {
            status = .blocked
        } else if diagnostics.contains(where: { $0.severity == .warning }) {
            status = .warning
        } else {
            status = .ready
        }

        return SpeciesAssetImportProvenance(
            sourcePath: sourceURL.standardizedFileURL.path,
            sourceFileName: sourceURL.lastPathComponent,
            byteCount: data.count,
            sha1: pokemonHackSHA1Hex(data),
            expectedKind: expectedKind,
            detectedKind: detectedKind,
            pngMetadata: pngMetadata,
            paletteMetadata: paletteMetadata,
            status: status,
            diagnostics: diagnostics
        )
    }

    private static func detectedKind(
        pngMetadata: GraphicsPNGMetadata?,
        paletteMetadata: GraphicsPaletteMetadata?
    ) -> SpeciesAssetImportDetectedKind {
        if pngMetadata != nil {
            return .png
        }
        if paletteMetadata != nil {
            return .palette
        }
        return .unsupported
    }

    private static func diagnostics(
        sourcePath: String,
        expectedKind: SpeciesAssetKind,
        detectedKind: SpeciesAssetImportDetectedKind,
        data: Data,
        pngMetadata: GraphicsPNGMetadata?,
        sourcePaletteMetadata: GraphicsPaletteMetadata?,
        binaryPaletteMetadata: GraphicsPaletteMetadata?
    ) -> [Diagnostic] {
        let span = SourceSpan(relativePath: sourcePath, startLine: 1)
        guard !data.isEmpty else {
            return [
                Diagnostic(
                    severity: .error,
                    code: "SPECIES_ASSET_IMPORT_EMPTY",
                    message: "Imported \(expectedKind.title) asset data is empty.",
                    span: span
                )
            ]
        }

        if expectedKind.isSpriteAsset {
            guard detectedKind == .png,
                  let png = pngMetadata,
                  png.width > 0,
                  png.height > 0
            else {
                return [
                    Diagnostic(
                        severity: .error,
                        code: "SPECIES_ASSET_IMPORT_KIND_MISMATCH",
                        message: "\(expectedKind.title) imports must be readable PNG source assets.",
                        span: span
                    )
                ]
            }

            var diagnostics: [Diagnostic] = []
            diagnostics.append(contentsOf: pngFormatDiagnostics(
                kind: expectedKind,
                png: png,
                codePrefix: "SPECIES_ASSET_IMPORT",
                span: span
            ))
            return diagnostics
        }

        guard detectedKind == .palette,
              let palette = sourcePaletteMetadata ?? binaryPaletteMetadata
        else {
            return [
                Diagnostic(
                    severity: .error,
                    code: "SPECIES_ASSET_IMPORT_KIND_MISMATCH",
                    message: "\(expectedKind.title) imports must be JASC .pal source files.",
                    span: span
                )
            ]
        }

        var diagnostics: [Diagnostic] = []
        if sourcePaletteMetadata == nil, binaryPaletteMetadata != nil {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "SPECIES_ASSET_IMPORT_BINARY_PALETTE_BLOCKED",
                    message: "Binary .gbapal palette bytes cannot replace source .pal files until a conversion workflow is available.",
                    span: span
                )
            )
        }
        if !palette.hasSlotZero {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "SPECIES_ASSET_IMPORT_PALETTE_SLOT_ZERO_MISSING",
                    message: "\(expectedKind.title) palette must include slot 0.",
                    span: span
                )
            )
        }
        if palette.colorCount > 16 {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "SPECIES_ASSET_IMPORT_PALETTE_OVER_LIMIT",
                    message: "\(expectedKind.title) palette has \(palette.colorCount) colors; Gen III species palettes must fit 16 colors.",
                    span: span
                )
            )
        }
        if palette.colorCount < 16 {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "SPECIES_ASSET_IMPORT_PALETTE_UNDER_LIMIT",
                    message: "\(expectedKind.title) palette has \(palette.colorCount) colors; expected species palettes normally carry 16 colors.",
                    span: span
                )
            )
        }
        if palette.gbaPrecisionLossCount > 0 {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "SPECIES_ASSET_IMPORT_PALETTE_PRECISION_LOSS",
                    message: "\(expectedKind.title) palette has \(palette.gbaPrecisionLossCount) color(s) that lose precision in GBA 15-bit color.",
                    span: span
                )
            )
        }
        return diagnostics
    }

    private static func pngFormatDiagnostics(
        kind: SpeciesAssetKind,
        png: GraphicsPNGMetadata,
        codePrefix: String,
        span: SourceSpan
    ) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        if let expected = kind.expectedPNGDimensions,
           png.width != expected.width || png.height != expected.height
        {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "\(codePrefix)_PNG_DIMENSIONS_UNSUPPORTED",
                    message: "\(kind.title) PNG must be \(expected.width)x\(expected.height); detected \(png.width)x\(png.height).",
                    span: span
                )
            )
        }
        if let paletteColorCount = png.paletteColorCount, paletteColorCount > kind.pngPaletteColorLimit {
            let paletteDescription = kind.pngPaletteColorLimit == 16
                ? "Gen III sprite sources must fit 16 colors."
                : "\(kind.title) source PNGs must fit \(kind.pngPaletteColorLimit) colors."
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "\(codePrefix)_PNG_PALETTE_OVER_LIMIT",
                    message: "\(kind.title) PNG declares \(paletteColorCount) palette colors; \(paletteDescription)",
                    span: span
                )
            )
        }
        if png.paletteColorCount == nil {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "\(codePrefix)_PNG_PALETTE_UNVERIFIED",
                    message: "\(kind.title) PNG has no PLTE chunk; palette fit must be reviewed before conversion.",
                    span: span
                )
            )
        }
        return diagnostics
    }

}

public struct SpeciesAsset: Codable, Equatable, Identifiable {
    public var id: String { "\(kind.rawValue):\(relativePath)" }

    public let kind: SpeciesAssetKind
    public let relativePath: String
    public let exists: Bool
    public let sourceSpan: SourceSpan
    public let diagnostics: [Diagnostic]

    public init(
        kind: SpeciesAssetKind,
        relativePath: String,
        exists: Bool,
        sourceSpan: SourceSpan,
        diagnostics: [Diagnostic] = []
    ) {
        self.kind = kind
        self.relativePath = relativePath
        self.exists = exists
        self.sourceSpan = sourceSpan
        self.diagnostics = diagnostics
    }
}

public struct SpeciesBaseStatsDraft: Codable, Equatable {
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

    public init(stats: SpeciesBaseStats) {
        self.init(
            hp: stats.hp ?? 0,
            attack: stats.attack ?? 0,
            defense: stats.defense ?? 0,
            speed: stats.speed ?? 0,
            spAttack: stats.spAttack ?? 0,
            spDefense: stats.spDefense ?? 0
        )
    }
}

public struct SpeciesEVYieldDraft: Codable, Equatable {
    public var hp: Int
    public var attack: Int
    public var defense: Int
    public var speed: Int
    public var spAttack: Int
    public var spDefense: Int

    public var total: Int {
        hp + attack + defense + speed + spAttack + spDefense
    }

    public init(hp: Int, attack: Int, defense: Int, speed: Int, spAttack: Int, spDefense: Int) {
        self.hp = hp
        self.attack = attack
        self.defense = defense
        self.speed = speed
        self.spAttack = spAttack
        self.spDefense = spDefense
    }

    public init(evYield: SpeciesEVYield) {
        self.init(
            hp: evYield.hp,
            attack: evYield.attack,
            defense: evYield.defense,
            speed: evYield.speed,
            spAttack: evYield.spAttack,
            spDefense: evYield.spDefense
        )
    }
}

public struct SpeciesPokedexDraft: Codable, Equatable {
    public var categoryName: String
    public var height: String
    public var weight: String
    public var pokemonScale: String
    public var pokemonOffset: String
    public var trainerScale: String
    public var trainerOffset: String
    public var description: String

    public init(entry: SpeciesPokedexEntry) {
        self.categoryName = entry.categoryName ?? ""
        self.height = entry.height ?? "0"
        self.weight = entry.weight ?? "0"
        self.pokemonScale = entry.pokemonScale ?? "256"
        self.pokemonOffset = entry.pokemonOffset ?? "0"
        self.trainerScale = entry.trainerScale ?? "256"
        self.trainerOffset = entry.trainerOffset ?? "0"
        self.description = entry.description ?? ""
    }
}

public struct SpeciesLevelUpMoveDraft: Codable, Equatable, Identifiable {
    public var id: String
    public var level: Int
    public var move: String

    public init(id: String = UUID().uuidString, level: Int, move: String) {
        self.id = id
        self.level = level
        self.move = move
    }
}

public struct SpeciesEvolutionDraft: Codable, Equatable, Identifiable {
    public var id: String
    public var method: String
    public var parameter: String
    public var targetSpecies: String

    public init(id: String = UUID().uuidString, method: String, parameter: String, targetSpecies: String) {
        self.id = id
        self.method = method
        self.parameter = parameter
        self.targetSpecies = targetSpecies
    }

    public init(evolution: SpeciesEvolution) {
        self.init(
            method: evolution.method,
            parameter: evolution.parameter,
            targetSpecies: evolution.targetSpecies
        )
    }
}

public struct SpeciesEditDraft: Codable, Equatable, Identifiable {
    public var id: String { speciesID }

    public var speciesID: String
    public var baseStats: SpeciesBaseStatsDraft
    public var types: [String]
    public var abilities: [String]
    public var evYield: SpeciesEVYieldDraft
    public var catchRate: String
    public var expYield: String
    public var genderRatio: String
    public var eggCycles: String
    public var friendship: String
    public var growthRate: String
    public var safariZoneFleeRate: String
    public var eggGroups: [String]
    public var itemCommon: String
    public var itemRare: String
    public var bodyColor: String
    public var noFlip: Bool
    public var levelUpMoves: [SpeciesLevelUpMoveDraft]
    public var tmhmMoves: [String]
    public var eggMoves: [String]
    public var tutorMoves: [String]
    public var evolutions: [SpeciesEvolutionDraft]
    public var pokedex: SpeciesPokedexDraft?
    public var assetData: [SpeciesAssetKind: Data]
    public var assetImports: [SpeciesAssetKind: SpeciesAssetImportProvenance]

    public init(
        speciesID: String,
        baseStats: SpeciesBaseStatsDraft,
        types: [String],
        abilities: [String],
        evYield: SpeciesEVYieldDraft,
        catchRate: String,
        expYield: String,
        genderRatio: String,
        eggCycles: String,
        friendship: String,
        growthRate: String,
        safariZoneFleeRate: String,
        eggGroups: [String],
        itemCommon: String,
        itemRare: String,
        bodyColor: String,
        noFlip: Bool,
        levelUpMoves: [SpeciesLevelUpMoveDraft],
        tmhmMoves: [String],
        eggMoves: [String],
        tutorMoves: [String],
        evolutions: [SpeciesEvolutionDraft],
        pokedex: SpeciesPokedexDraft? = nil,
        assetData: [SpeciesAssetKind: Data] = [:],
        assetImports: [SpeciesAssetKind: SpeciesAssetImportProvenance] = [:]
    ) {
        self.speciesID = speciesID
        self.baseStats = baseStats
        self.types = normalizedFixedList(types, count: 2, fallback: "TYPE_NORMAL")
        self.abilities = normalizedFixedList(abilities, count: 2, fallback: "ABILITY_NONE")
        self.evYield = evYield
        self.catchRate = catchRate
        self.expYield = expYield
        self.genderRatio = genderRatio
        self.eggCycles = eggCycles
        self.friendship = friendship
        self.growthRate = growthRate
        self.safariZoneFleeRate = safariZoneFleeRate
        self.eggGroups = normalizedFixedList(eggGroups, count: 2, fallback: "EGG_GROUP_NONE")
        self.itemCommon = itemCommon
        self.itemRare = itemRare
        self.bodyColor = bodyColor
        self.noFlip = noFlip
        self.levelUpMoves = levelUpMoves
        self.tmhmMoves = Array(Set(tmhmMoves)).sorted()
        self.eggMoves = eggMoves
        self.tutorMoves = Array(Set(tutorMoves)).sorted()
        self.evolutions = evolutions
        self.pokedex = pokedex
        self.assetData = assetData
        self.assetImports = assetImports
    }

    public init?(detail: SpeciesDetail) {
        guard detail.isEditable else { return nil }

        let levelUpMoves = detail.learnsets.levelUp.map { SpeciesLevelUpMoveDraft(level: $0.level, move: $0.move) }
        let tmhmMoves = detail.learnsets.tmhm.map(\.move)
        let eggMoves = detail.learnsets.egg.map(\.move)
        let tutorMoves = detail.learnsets.tutor.map(\.move)
        let evolutions = detail.evolutions.map { SpeciesEvolutionDraft(evolution: $0) }
        let pokedex = detail.pokedex.map { SpeciesPokedexDraft(entry: $0) }

        self.init(
            speciesID: detail.speciesID,
            baseStats: SpeciesBaseStatsDraft(stats: detail.baseStats),
            types: detail.types,
            abilities: detail.abilities,
            evYield: SpeciesEVYieldDraft(evYield: detail.evYield),
            catchRate: detail.training.catchRate ?? "0",
            expYield: detail.training.expYield ?? "0",
            genderRatio: detail.training.genderRatio ?? "MON_GENDERLESS",
            eggCycles: detail.training.eggCycles ?? "0",
            friendship: detail.training.friendship ?? "0",
            growthRate: detail.training.growthRate ?? "GROWTH_MEDIUM_FAST",
            safariZoneFleeRate: detail.training.safariZoneFleeRate ?? "0",
            eggGroups: detail.breeding.eggGroups,
            itemCommon: detail.heldItems.common ?? "ITEM_NONE",
            itemRare: detail.heldItems.rare ?? "ITEM_NONE",
            bodyColor: detail.bodyColor ?? "BODY_COLOR_RED",
            noFlip: boolValue(detail.noFlip),
            levelUpMoves: levelUpMoves,
            tmhmMoves: tmhmMoves,
            eggMoves: eggMoves,
            tutorMoves: tutorMoves,
            evolutions: evolutions,
            pokedex: pokedex,
            assetData: [:],
            assetImports: [:]
        )
    }
}

public struct SpeciesEditFileChange: Codable, Equatable, Identifiable {
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

public struct SpeciesEditPlan: Codable, Equatable, Identifiable {
    public let id: String
    public let rootPath: String
    public let speciesID: String
    public let draft: SpeciesEditDraft
    public let changes: [SpeciesEditFileChange]
    public let diagnostics: [Diagnostic]
    public let mutationPlan: MutationPlan
    public let backupRelativeRoot: String

    public init(
        id: String = UUID().uuidString,
        rootPath: String,
        speciesID: String,
        draft: SpeciesEditDraft,
        changes: [SpeciesEditFileChange],
        diagnostics: [Diagnostic],
        mutationPlan: MutationPlan,
        backupRelativeRoot: String
    ) {
        self.id = id
        self.rootPath = rootPath
        self.speciesID = speciesID
        self.draft = draft
        self.changes = changes
        self.diagnostics = diagnostics
        self.mutationPlan = mutationPlan
        self.backupRelativeRoot = backupRelativeRoot
    }
}

public struct SpeciesEditApplyability: Codable, Equatable {
    public let isApplyable: Bool
    public let diagnostics: [Diagnostic]

    public init(isApplyable: Bool, diagnostics: [Diagnostic]) {
        self.isApplyable = isApplyable
        self.diagnostics = diagnostics
    }
}

public extension SpeciesEditPlan {
    var applyability: SpeciesEditApplyability {
        validateApplyability()
    }

    var isApplyable: Bool {
        applyability.isApplyable
    }

    func validateApplyability(fileManager: FileManager = .default) -> SpeciesEditApplyability {
        SpeciesEditApplySafety.applyability(for: self, fileManager: fileManager)
    }
}

public struct AppliedSpeciesFileChange: Codable, Equatable, Identifiable {
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

public struct SpeciesApplyResult: Codable, Equatable, Identifiable {
    public let id: String
    public let backupRootPath: String
    public let appliedChanges: [AppliedSpeciesFileChange]
    public let diagnostics: [Diagnostic]

    public init(id: String = UUID().uuidString, backupRootPath: String, appliedChanges: [AppliedSpeciesFileChange], diagnostics: [Diagnostic] = []) {
        self.id = id
        self.backupRootPath = backupRootPath
        self.appliedChanges = appliedChanges
        self.diagnostics = diagnostics
    }
}

private struct SpeciesLevelUpLearnsetRecord {
    let symbol: String
    let span: SourceSpan
    let moves: [SpeciesLevelUpMove]
}

private struct SpeciesMoveListRecord {
    let span: SourceSpan?
    let moves: [SpeciesMoveReference]
}

public enum ProjectSpeciesCatalogBuilder {
    public static func build(
        path: String,
        fileManager: FileManager = .default
    ) throws -> ProjectSpeciesCatalog {
        let index = try GameAdapterRegistry.index(path: path, fileManager: fileManager)
        return try build(index: index, fileManager: fileManager)
    }

    public static func build(
        index: ProjectIndex,
        fileManager: FileManager = .default
    ) throws -> ProjectSpeciesCatalog {
        let root = URL(fileURLWithPath: index.root.path)
        guard let descriptor = SpeciesCatalogDescriptor.descriptor(for: index.profile) else {
            return ProjectSpeciesCatalog(
                root: index.root,
                profile: index.profile,
                adapterID: index.adapterID,
                adapterName: index.adapterName,
                species: [],
                diagnostics: [
                    Diagnostic(
                        severity: .warning,
                        code: "SPECIES_CATALOG_UNSUPPORTED_PROFILE",
                        message: "Species catalog is not available for \(index.profile.rawValue).",
                        span: SourceSpan(relativePath: index.root.path, startLine: 1)
                    )
                ]
            )
        }

        var diagnostics: [Diagnostic] = []
        let constants = readConstants(descriptor: descriptor, root: root, fileManager: fileManager)
        let speciesEntries = try readSpeciesEntries(descriptor: descriptor, root: root, fileManager: fileManager, diagnostics: &diagnostics)
        let levelUpLearnsets = try readLevelUpLearnsets(descriptor: descriptor, root: root, fileManager: fileManager)
        let tmhmLearnsets = try readTMHMLearnsets(descriptor: descriptor, root: root, fileManager: fileManager, diagnostics: &diagnostics)
        let eggMoves = try readEggMoves(descriptor: descriptor, root: root, fileManager: fileManager)
        let tutorLearnsets = try readTutorLearnsets(descriptor: descriptor, root: root, fileManager: fileManager, diagnostics: &diagnostics)
        let evolutions = try readEvolutions(descriptor: descriptor, root: root, fileManager: fileManager, diagnostics: &diagnostics)
        let pokedexEntries = try readPokedexEntries(descriptor: descriptor, root: root, fileManager: fileManager, diagnostics: &diagnostics)

        let species = speciesEntries.map { entry -> SpeciesDetail in
            let fields = entry.fields
            let speciesID = entry.symbol
            let assets = assetLinks(for: speciesID, root: root, fileManager: fileManager)
            let assetDiagnostics = assets.flatMap(\.diagnostics)
            let editDiagnostics = editabilityDiagnostics(entry: entry, descriptor: descriptor)
            let detailDiagnostics = assetDiagnostics + editDiagnostics
            let levelUp = levelUpLearnsets[speciesID]
            let tmhm = tmhmLearnsets[speciesID]
            let egg = eggMoves[speciesID]
            let tutor = tutorLearnsets[speciesID]
            return SpeciesDetail(
                speciesID: speciesID,
                displayName: displayName(for: speciesID),
                sourceSpan: entry.span,
                baseStats: SpeciesBaseStats(
                    hp: intValue(fields["baseHP"]),
                    attack: intValue(fields["baseAttack"]),
                    defense: intValue(fields["baseDefense"]),
                    speed: intValue(fields["baseSpeed"]),
                    spAttack: intValue(fields["baseSpAttack"]),
                    spDefense: intValue(fields["baseSpDefense"])
                ),
                types: constantList(fields["types"]) + [fields["type1"], fields["type2"]].compactMap { compact($0) },
                abilities: constantList(fields["abilities"]) + [fields["ability1"], fields["ability2"], fields["hiddenAbility"]].compactMap { compact($0) },
                evYield: SpeciesEVYield(
                    hp: intValue(fields["evYield_HP"]) ?? 0,
                    attack: intValue(fields["evYield_Attack"]) ?? 0,
                    defense: intValue(fields["evYield_Defense"]) ?? 0,
                    speed: intValue(fields["evYield_Speed"]) ?? 0,
                    spAttack: intValue(fields["evYield_SpAttack"]) ?? 0,
                    spDefense: intValue(fields["evYield_SpDefense"]) ?? 0
                ),
                training: SpeciesTrainingData(
                    catchRate: compact(fields["catchRate"]),
                    expYield: compact(fields["expYield"] ?? fields["baseExp"]),
                    genderRatio: compact(fields["genderRatio"]),
                    eggCycles: compact(fields["eggCycles"]),
                    friendship: compact(fields["friendship"]),
                    growthRate: compact(fields["growthRate"]),
                    safariZoneFleeRate: compact(fields["safariZoneFleeRate"])
                ),
                breeding: SpeciesBreedingData(
                    eggGroups: constantList(fields["eggGroups"])
                        + [fields["eggGroup1"], fields["eggGroup2"]].compactMap { compact($0) }
                ),
                heldItems: SpeciesHeldItems(
                    common: compact(fields["itemCommon"] ?? fields["item1"]),
                    rare: compact(fields["itemRare"] ?? fields["item2"])
                ),
                bodyColor: compact(fields["bodyColor"]),
                noFlip: compact(fields["noFlip"]),
                learnsets: SpeciesLearnsets(
                    levelUp: levelUp?.moves ?? [],
                    tmhm: tmhm?.moves ?? [],
                    egg: egg?.moves ?? [],
                    tutor: tutor?.moves ?? [],
                    levelUpSymbol: levelUp?.symbol,
                    levelUpSourceSpan: levelUp?.span,
                    tmhmSourceSpan: tmhm?.span,
                    eggSourceSpan: egg?.span,
                    tutorSourceSpan: tutor?.span
                ),
                evolutions: evolutions[speciesID] ?? [],
                pokedex: pokedexEntries[speciesID],
                assets: assets,
                diagnostics: detailDiagnostics,
                sourcePreview: preview(entry.body),
                isEditable: descriptor.editCapabilities.speciesInfo && editDiagnostics.allSatisfy { $0.severity != .error }
            )
        }

        return ProjectSpeciesCatalog(
            root: index.root,
            profile: index.profile,
            adapterID: index.adapterID,
            adapterName: index.adapterName,
            species: species.sorted { $0.sourceSpan.startLine < $1.sourceSpan.startLine },
            constants: constants,
            diagnostics: diagnostics
        )
    }

    private static func readConstants(
        descriptor: SpeciesCatalogDescriptor,
        root: URL,
        fileManager: FileManager
    ) -> [SpeciesConstantGroup: [SpeciesConstant]] {
        var result: [SpeciesConstantGroup: [SpeciesConstant]] = [:]
        for constantDescriptor in descriptor.constants {
            let url = root.appendingPathComponent(constantDescriptor.path)
            guard fileManager.fileExists(atPath: url.path), let text = try? readText(at: url) else {
                continue
            }
            result[constantDescriptor.group, default: []].append(contentsOf: constants(in: text, descriptor: constantDescriptor))
        }
        let tmhmMoves = tmhmMoveConstants(from: result[.items] ?? [])
        if !tmhmMoves.isEmpty {
            result[.tmhmMoves] = tmhmMoves
        }
        let tutorMoves = tutorMoveConstants(descriptor: descriptor, root: root, fileManager: fileManager)
        if !tutorMoves.isEmpty {
            result[.tutorMoves] = tutorMoves
        }
        return result.mapValues { constants in
            constants.sorted { lhs, rhs in
                let lhsNumeric = Int(lhs.value)
                let rhsNumeric = Int(rhs.value)
                if let lhsNumeric, let rhsNumeric, lhsNumeric != rhsNumeric {
                    return lhsNumeric < rhsNumeric
                }
                return lhs.symbol < rhs.symbol
            }
        }
    }

    private static func constants(in text: String, descriptor: SpeciesConstantDescriptor) -> [SpeciesConstant] {
        text.components(separatedBy: .newlines).enumerated().compactMap { index, line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("#define ") else { return nil }
            let parts = trimmed.split(maxSplits: 2, whereSeparator: { $0.isWhitespace }).map(String.init)
            guard parts.count >= 3 else { return nil }
            let symbol = parts[1]
            guard descriptor.prefixes.contains(where: { symbol.hasPrefix($0) }) || descriptor.exactSymbols.contains(symbol) else {
                return nil
            }
            return SpeciesConstant(
                group: descriptor.group,
                symbol: symbol,
                value: parts[2],
                sourceSpan: SourceSpan(relativePath: descriptor.path, startLine: index + 1)
            )
        }
    }

    private static func tutorMoveConstants(descriptor: SpeciesCatalogDescriptor, root: URL, fileManager: FileManager) -> [SpeciesConstant] {
        guard let path = descriptor.tutorPath else { return [] }
        let url = root.appendingPathComponent(path)
        guard let text = try? readText(at: url) else { return [] }

        let lines = text.components(separatedBy: .newlines)
        var result: [SpeciesConstant] = []
        for (index, line) in lines.enumerated() {
            if let match = firstRegexMatch(#"#define\s+TUTOR_([A-Z0-9_]+)\s+"#, in: line) {
                result.append(
                    SpeciesConstant(
                        group: .tutorMoves,
                        symbol: "MOVE_\(match)",
                        value: match,
                        sourceSpan: SourceSpan(relativePath: path, startLine: index + 1)
                    )
                )
            }
        }
        return result
    }

    private static func tmhmMoveConstants(from itemConstants: [SpeciesConstant]) -> [SpeciesConstant] {
        itemConstants.compactMap { item in
            guard let token = tmhmToken(fromItemSymbol: item.symbol) else { return nil }
            return SpeciesConstant(
                group: .tmhmMoves,
                symbol: "MOVE_\(tmhmMoveName(from: token))",
                value: token,
                sourceSpan: item.sourceSpan
            )
        }
    }

    private static func editabilityDiagnostics(
        entry: CInitializerEntry,
        descriptor: SpeciesCatalogDescriptor
    ) -> [Diagnostic] {
        guard descriptor.editCapabilities.speciesInfo else {
            return [
                Diagnostic(
                    severity: .warning,
                    code: "SPECIES_EDIT_UNSUPPORTED_PROFILE",
                    message: "Species row editing is not available for this project profile.",
                    span: entry.span
                )
            ]
        }
        guard !entry.fields.isEmpty else {
            return [
                Diagnostic(
                    severity: .error,
                    code: "SPECIES_ENTRY_UNSUPPORTED_SHAPE",
                    message: "\(entry.symbol) uses a macro or initializer shape that cannot be safely rewritten yet.",
                    span: entry.span
                )
            ]
        }
        if descriptor.speciesInfoStyle == .expansionSpeciesScalars {
            let unsupported = Set(entry.fields.keys).subtracting(Self.knownExpansionSpeciesInfoFields)
            return unsupported.sorted().map { field in
                Diagnostic(
                    severity: .warning,
                    code: "SPECIES_ENTRY_EXPANSION_FIELD_READ_ONLY",
                    message: "\(entry.symbol) has Expansion species field \(field); preserving it as raw source while scalar fields remain editable.",
                    span: entry.span
                )
            }
        }
        let unsupported = Set(entry.fields.keys).subtracting(Self.supportedSpeciesInfoFields)
        guard !unsupported.isEmpty else { return [] }
        return [
            Diagnostic(
                severity: .error,
                code: "SPECIES_ENTRY_UNSUPPORTED_FIELDS",
                message: "\(entry.symbol) has unsupported species fields: \(unsupported.sorted().joined(separator: ", ")).",
                span: entry.span
            )
        ]
    }

    private static let supportedSpeciesInfoFields: Set<String> = [
        "baseHP",
        "baseAttack",
        "baseDefense",
        "baseSpeed",
        "baseSpAttack",
        "baseSpDefense",
        "types",
        "type1",
        "type2",
        "catchRate",
        "expYield",
        "baseExp",
        "evYield_HP",
        "evYield_Attack",
        "evYield_Defense",
        "evYield_Speed",
        "evYield_SpAttack",
        "evYield_SpDefense",
        "itemCommon",
        "itemRare",
        "item1",
        "item2",
        "genderRatio",
        "eggCycles",
        "friendship",
        "growthRate",
        "eggGroups",
        "eggGroup1",
        "eggGroup2",
        "abilities",
        "ability1",
        "ability2",
        "hiddenAbility",
        "safariZoneFleeRate",
        "bodyColor",
        "noFlip"
    ]

    private static let knownExpansionSpeciesInfoFields: Set<String> = supportedSpeciesInfoFields.union([
        "formSpeciesIdTable",
        "formChangeTable"
    ])

    private static func readSpeciesEntries(
        descriptor: SpeciesCatalogDescriptor,
        root: URL,
        fileManager: FileManager,
        diagnostics: inout [Diagnostic]
    ) throws -> [CInitializerEntry] {
        let path = root.appendingPathComponent(descriptor.speciesPath)
        guard fileManager.fileExists(atPath: path.path) else {
            diagnostics.append(missingSourceDiagnostic(path: descriptor.speciesPath, code: "SPECIES_INFO_MISSING"))
            return []
        }
        let text = try readText(at: path)
        let parsed = CInitializerParser.tableEntries(
            in: text,
            descriptor: CInitializerTableDescriptor(
                module: .pokemon,
                relativePath: descriptor.speciesPath,
                tableSymbol: descriptor.speciesTableSymbol,
                entryStyle: .bracketed
            )
        )
        diagnostics.append(contentsOf: parsed.diagnostics)
        return parsed.entries.filter { $0.symbol.hasPrefix("SPECIES_") }
    }

    private static func readLevelUpLearnsets(
        descriptor: SpeciesCatalogDescriptor,
        root: URL,
        fileManager: FileManager
    ) throws -> [String: SpeciesLevelUpLearnsetRecord] {
        let symbolToSpecies = try readLevelUpPointerMap(descriptor: descriptor, root: root, fileManager: fileManager)
        let paths = levelUpSourcePaths(descriptor: descriptor, root: root, fileManager: fileManager)
        var learnsets: [String: SpeciesLevelUpLearnsetRecord] = [:]

        for relativePath in paths {
            let url = root.appendingPathComponent(relativePath)
            guard fileManager.fileExists(atPath: url.path) else { continue }
            let text = try readText(at: url)
            for block in learnsetBlocks(in: text, relativePath: relativePath) {
                let speciesID = symbolToSpecies[block.symbol] ?? speciesConstant(fromLearnsetSymbol: block.symbol)
                if let existing = learnsets[speciesID] {
                    learnsets[speciesID] = SpeciesLevelUpLearnsetRecord(
                        symbol: existing.symbol,
                        span: existing.span,
                        moves: existing.moves + block.moves
                    )
                } else {
                    learnsets[speciesID] = SpeciesLevelUpLearnsetRecord(symbol: block.symbol, span: block.span, moves: block.moves)
                }
            }
        }

        return learnsets
    }

    private static func readLevelUpPointerMap(
        descriptor: SpeciesCatalogDescriptor,
        root: URL,
        fileManager: FileManager
    ) throws -> [String: String] {
        guard let relativePath = descriptor.levelUpPointerPath else { return [:] }
        let url = root.appendingPathComponent(relativePath)
        guard fileManager.fileExists(atPath: url.path) else { return [:] }
        let text = try readText(at: url)
        var result: [String: String] = [:]
        for match in regexMatches(#"\[(SPECIES_[A-Z0-9_]+)\]\s*=\s*(s[A-Za-z0-9_]+LevelUpLearnset)"#, in: text) {
            guard match.count >= 3 else { continue }
            result[match[2]] = match[1]
        }
        return result
    }

    private static func levelUpSourcePaths(
        descriptor: SpeciesCatalogDescriptor,
        root: URL,
        fileManager: FileManager
    ) -> [String] {
        var paths: [String] = []
        for path in descriptor.levelUpPaths {
            if fileManager.fileExists(atPath: root.appendingPathComponent(path).path) {
                paths.append(path)
            }
        }
        if let directory = descriptor.levelUpDirectory {
            paths.append(contentsOf: sourceFiles(root: root, relativeRoot: directory, extensions: ["h"], fileManager: fileManager))
        }
        return Array(Set(paths)).sorted()
    }

    private static func learnsetBlocks(
        in text: String,
        relativePath: String
    ) -> [(symbol: String, span: SourceSpan, moves: [SpeciesLevelUpMove])] {
        let lines = text.components(separatedBy: .newlines)
        var blocks: [(symbol: String, span: SourceSpan, moves: [SpeciesLevelUpMove])] = []
        var index = 0
        while index < lines.count {
            guard let symbol = firstRegexMatch(#"(s[A-Za-z0-9_]+LevelUpLearnset)"#, in: lines[index]) else {
                index += 1
                continue
            }

            let start = index
            var end = index
            while end < lines.count, !lines[end].contains("};") {
                end += 1
            }
            let clampedEnd = min(end, lines.count - 1)
            var moves: [SpeciesLevelUpMove] = []
            for lineIndex in start...clampedEnd {
                let line = lines[lineIndex]
                for match in regexMatches(#"LEVEL_UP_MOVE\(\s*([0-9]+)\s*,\s*(MOVE_[A-Z0-9_]+)\s*\)"#, in: line) {
                    guard match.count >= 3, let level = Int(match[1]) else { continue }
                    moves.append(
                        SpeciesLevelUpMove(
                            level: level,
                            move: match[2],
                            sourceSpan: SourceSpan(relativePath: relativePath, startLine: lineIndex + 1)
                        )
                    )
                }
            }
            blocks.append((
                symbol: symbol,
                span: SourceSpan(relativePath: relativePath, startLine: start + 1, endLine: clampedEnd + 1),
                moves: moves
            ))
            index = clampedEnd + 1
        }
        return blocks
    }

    private static func readTMHMLearnsets(
        descriptor: SpeciesCatalogDescriptor,
        root: URL,
        fileManager: FileManager,
        diagnostics: inout [Diagnostic]
    ) throws -> [String: SpeciesMoveListRecord] {
        guard let relativePath = descriptor.tmhmPath else { return [:] }
        let url = root.appendingPathComponent(relativePath)
        guard fileManager.fileExists(atPath: url.path) else { return [:] }
        let text = try readText(at: url)

        for symbol in descriptor.tmhmTableSymbols {
            let parsed = CInitializerParser.tableEntries(
                in: text,
                descriptor: CInitializerTableDescriptor(
                    module: .learnsets,
                    relativePath: relativePath,
                    tableSymbol: symbol,
                    entryStyle: .bracketed
                )
            )
            guard !parsed.entries.isEmpty else {
                diagnostics.append(contentsOf: parsed.diagnostics)
                continue
            }
            return Dictionary(uniqueKeysWithValues: parsed.entries.compactMap { entry in
                guard entry.symbol.hasPrefix("SPECIES_") else { return nil }
                let moves = tmhmMoves(in: entry.body, sourceSpan: entry.span)
                return (entry.symbol, SpeciesMoveListRecord(span: entry.span, moves: moves.sorted { $0.move < $1.move }))
            })
        }
        return [:]
    }

    private static func tmhmMoves(in body: String, sourceSpan: SourceSpan) -> [SpeciesMoveReference] {
        var moves = regexMatches(#"\.([A-Z0-9_]+)\s*=\s*TRUE"#, in: body)
            .compactMap { match -> String? in
                guard match.count >= 2 else { return nil }
                return "MOVE_\(match[1])"
            }

        moves.append(contentsOf: regexMatches(#"TMHM\(((?:TM|HM)[0-9]{2}_[A-Z0-9_]+)\)"#, in: body).compactMap { match -> String? in
            guard match.count >= 2 else { return nil }
            let item = match[1]
            guard let underscore = item.firstIndex(of: "_") else { return nil }
            return "MOVE_\(item[item.index(after: underscore)...])"
        })

        return Array(Set(moves)).sorted().map {
            SpeciesMoveReference(move: $0, sourceSpan: sourceSpan)
        }
    }

    private static func readTutorLearnsets(
        descriptor: SpeciesCatalogDescriptor,
        root: URL,
        fileManager: FileManager,
        diagnostics: inout [Diagnostic]
    ) throws -> [String: SpeciesMoveListRecord] {
        guard let relativePath = descriptor.tutorPath else { return [:] }
        let url = root.appendingPathComponent(relativePath)
        guard fileManager.fileExists(atPath: url.path) else { return [:] }
        let text = try readText(at: url)

        for symbol in descriptor.tutorTableSymbols {
            let parsed = CInitializerParser.tableEntries(
                in: text,
                descriptor: CInitializerTableDescriptor(
                    module: .learnsets,
                    relativePath: relativePath,
                    tableSymbol: symbol,
                    entryStyle: .bracketed
                )
            )
            guard !parsed.entries.isEmpty else {
                diagnostics.append(contentsOf: parsed.diagnostics)
                continue
            }
            return Dictionary(uniqueKeysWithValues: parsed.entries.compactMap { entry in
                guard entry.symbol.hasPrefix("SPECIES_") else { return nil }
                let moves = tutorMoves(in: entry.body, sourceSpan: entry.span)
                return (entry.symbol, SpeciesMoveListRecord(span: entry.span, moves: moves.sorted { $0.move < $1.move }))
            })
        }
        return [:]
    }

    private static func tutorMoves(in body: String, sourceSpan: SourceSpan) -> [SpeciesMoveReference] {
        var moves: [String] = []
        moves.append(contentsOf: regexMatches(#"TUTOR\(\s*([A-Z0-9_]+)\s*\)"#, in: body).compactMap { match in
            guard match.count >= 2 else { return nil }
            return "MOVE_\(match[1])"
        })
        moves.append(contentsOf: regexMatches(#"(MOVE_[A-Z0-9_]+)"#, in: body).compactMap { match in
            guard match.count >= 2 else { return nil }
            return match[1]
        })
        return Array(Set(moves.filter { $0 != "MOVE_NONE" })).map {
            SpeciesMoveReference(move: $0, sourceSpan: sourceSpan)
        }
    }

    private static func readEggMoves(
        descriptor: SpeciesCatalogDescriptor,
        root: URL,
        fileManager: FileManager
    ) throws -> [String: SpeciesMoveListRecord] {
        guard let relativePath = descriptor.eggMovesPath else { return [:] }
        let url = root.appendingPathComponent(relativePath)
        guard fileManager.fileExists(atPath: url.path) else { return [:] }
        let text = try readText(at: url)
        let lines = text.components(separatedBy: .newlines)
        var result: [String: SpeciesMoveListRecord] = [:]
        var index = 0

        while index < lines.count {
            guard let match = regexMatches(#"egg_moves\(\s*([A-Z0-9_]+)"#, in: lines[index]).first, match.count >= 2 else {
                index += 1
                continue
            }
            let species = "SPECIES_\(match[1])"
            let start = index
            var end = index
            while end < lines.count, !lines[end].contains(")") {
                end += 1
            }
            let clampedEnd = min(end, lines.count - 1)
            let body = lines[start...clampedEnd].joined(separator: "\n")
            let moves = symbolTokens(in: body)
                .filter { $0.hasPrefix("MOVE_") }
                .map { SpeciesMoveReference(move: $0, sourceSpan: SourceSpan(relativePath: relativePath, startLine: start + 1, endLine: clampedEnd + 1)) }
            result[species] = SpeciesMoveListRecord(
                span: SourceSpan(relativePath: relativePath, startLine: start + 1, endLine: clampedEnd + 1),
                moves: moves
            )
            index = clampedEnd + 1
        }

        return result
    }

    private static func readEvolutions(
        descriptor: SpeciesCatalogDescriptor,
        root: URL,
        fileManager: FileManager,
        diagnostics: inout [Diagnostic]
    ) throws -> [String: [SpeciesEvolution]] {
        guard let relativePath = descriptor.evolutionPath else { return [:] }
        let url = root.appendingPathComponent(relativePath)
        guard fileManager.fileExists(atPath: url.path) else { return [:] }
        let text = try readText(at: url)
        let parsed = CInitializerParser.tableEntries(
            in: text,
            descriptor: CInitializerTableDescriptor(
                module: .evolutions,
                relativePath: relativePath,
                tableSymbol: "gEvolutionTable",
                entryStyle: .bracketed
            )
        )
        diagnostics.append(contentsOf: parsed.diagnostics)
        return Dictionary(uniqueKeysWithValues: parsed.entries.compactMap { entry in
            guard entry.symbol.hasPrefix("SPECIES_") else { return nil }
            let evolutions = regexMatches(#"\{\s*(EVO_[A-Z0-9_]+)\s*,\s*([^,{}]+)\s*,\s*(SPECIES_[A-Z0-9_]+)\s*\}"#, in: entry.body)
                .compactMap { match -> SpeciesEvolution? in
                    guard match.count >= 4 else { return nil }
                    return SpeciesEvolution(
                        method: compact(match[1]) ?? match[1],
                        parameter: compact(match[2]) ?? match[2],
                        targetSpecies: compact(match[3]) ?? match[3],
                        sourceSpan: entry.span
                    )
                }
            return (entry.symbol, evolutions)
        })
    }

    private static func readPokedexEntries(
        descriptor: SpeciesCatalogDescriptor,
        root: URL,
        fileManager: FileManager,
        diagnostics: inout [Diagnostic]
    ) throws -> [String: SpeciesPokedexEntry] {
        guard let relativePath = descriptor.pokedexPath else { return [:] }
        let url = root.appendingPathComponent(relativePath)
        guard fileManager.fileExists(atPath: url.path) else { return [:] }
        let text = try readText(at: url)
        let descriptionText = try readPokedexDescriptionText(descriptor: descriptor, root: root, fileManager: fileManager)
        let parsed = CInitializerParser.tableEntries(
            in: text,
            descriptor: CInitializerTableDescriptor(
                module: .pokedex,
                relativePath: relativePath,
                tableSymbol: "gPokedexEntries",
                entryStyle: .bracketed
            )
        )
        diagnostics.append(contentsOf: parsed.diagnostics)
        return Dictionary(uniqueKeysWithValues: parsed.entries.compactMap { entry in
            let species = speciesConstant(fromDexSymbol: entry.symbol)
            guard species.hasPrefix("SPECIES_") else { return nil }
            let descriptionSymbol = compact(entry.fields["description"])
            let textData = descriptionSymbol.flatMap { descriptionText[$0] }
            let pokedex = SpeciesPokedexEntry(
                categoryName: unwrapTextMacro(entry.fields["categoryName"]),
                height: compact(entry.fields["height"]),
                weight: compact(entry.fields["weight"]),
                pokemonScale: compact(entry.fields["pokemonScale"]),
                pokemonOffset: compact(entry.fields["pokemonOffset"]),
                trainerScale: compact(entry.fields["trainerScale"]),
                trainerOffset: compact(entry.fields["trainerOffset"]),
                descriptionSymbol: descriptionSymbol,
                description: textData?.text,
                sourceSpan: entry.span,
                descriptionSpan: textData?.span
            )
            return (species, pokedex)
        })
    }

    private static func readPokedexDescriptionText(
        descriptor: SpeciesCatalogDescriptor,
        root: URL,
        fileManager: FileManager
    ) throws -> [String: (text: String, span: SourceSpan)] {
        guard let relativePath = descriptor.pokedexTextPath else { return [:] }
        let url = root.appendingPathComponent(relativePath)
        guard fileManager.fileExists(atPath: url.path) else { return [:] }
        let text = try readText(at: url)
        var result: [String: (text: String, span: SourceSpan)] = [:]

        let pattern = #"const\s+u8\s+(g[A-Za-z0-9_]+PokedexText)\[\]\s*=\s*_\(\s*((?:"(?:\\.|[^"])*"\s*)+)\);"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else { return [:] }
        let nsText = text as NSString

        for match in regex.matches(in: text, range: NSRange(location: 0, length: nsText.length)) {
            guard match.numberOfRanges >= 3 else { continue }
            let symbol = nsText.substring(with: match.range(at: 1))
            let fullMatchRange = match.range(at: 0)
            let fullTextRange = match.range(at: 2)
            let fullText = nsText.substring(with: fullTextRange)

            let lines = regexMatches(#""((?:\\.|[^"])*)""#, in: fullText, options: [.dotMatchesLineSeparators]).compactMap { quoted -> String? in
                guard quoted.count >= 2 else { return nil }
                return quoted[1]
                    .replacingOccurrences(of: "\\n", with: "\n")
                    .replacingOccurrences(of: "\\\"", with: "\"")
            }

            result[symbol] = (
                text: lines.joined(separator: "\n"),
                span: SourceSpan.span(for: fullMatchRange, in: text, relativePath: relativePath)
            )
        }
        return result
    }

    private static func assetLinks(
        for speciesID: String,
        root: URL,
        fileManager: FileManager
    ) -> [SpeciesAsset] {
        let directory = "graphics/pokemon/\(assetSlug(for: speciesID))"
        return SpeciesAssetKind.allCases.map { kind in
            let relativePath = "\(directory)/\(kind.filename)"
            let exists = fileManager.fileExists(atPath: root.appendingPathComponent(relativePath).path)
            let span = SourceSpan(relativePath: relativePath, startLine: 1)
            let diagnostics = exists ? [] : [
                Diagnostic(
                    severity: .info,
                    code: "SPECIES_ASSET_MISSING",
                    message: "\(kind.title) asset is not present at \(relativePath).",
                    span: span
                )
            ]
            return SpeciesAsset(
                kind: kind,
                relativePath: relativePath,
                exists: exists,
                sourceSpan: span,
                diagnostics: diagnostics
            )
        }
    }

    private static func readText(at url: URL) throws -> String {
        if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
            return utf8
        }
        return try String(contentsOf: url, encoding: .isoLatin1)
    }

    private static func sourceFiles(
        root: URL,
        relativeRoot: String,
        extensions: Set<String>,
        fileManager: FileManager
    ) -> [String] {
        let url = root.appendingPathComponent(relativeRoot)
        guard
            let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
        else {
            return []
        }

        var paths: [String] = []
        for case let fileURL as URL in enumerator {
            guard
                (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true,
                extensions.contains(fileURL.pathExtension.lowercased())
            else {
                continue
            }
            paths.append(relativePath(for: fileURL, root: root))
        }
        return paths.sorted()
    }

    private static func missingSourceDiagnostic(path: String, code: String) -> Diagnostic {
        Diagnostic(
            severity: .warning,
            code: code,
            message: "Species catalog source is not present: \(path)",
            span: SourceSpan(relativePath: path, startLine: 1)
        )
    }

    private static func relativePath(for url: URL, root: URL) -> String {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        if path.hasPrefix(rootPath + "/") {
            return String(path.dropFirst(rootPath.count + 1))
        }
        return path
    }
}

public enum SpeciesMutationPlanner {
    public static func plan(
        catalog: ProjectSpeciesCatalog,
        draft: SpeciesEditDraft,
        fileManager: FileManager = .default
    ) -> SpeciesEditPlan {
        let root = URL(fileURLWithPath: catalog.root.path).standardizedFileURL
        guard let descriptor = SpeciesCatalogDescriptor.descriptor(for: catalog.profile), descriptor.supportsEditing else {
            return blockedPlan(
                catalog: catalog,
                draft: draft,
                diagnostics: [
                    Diagnostic(severity: .error, code: "SPECIES_PLAN_UNSUPPORTED_PROFILE", message: "Species apply is not available for this project profile.")
                ]
            )
        }
        guard let species = catalog.species.first(where: { $0.speciesID == draft.speciesID }) else {
            return blockedPlan(
                catalog: catalog,
                draft: draft,
                diagnostics: [
                    Diagnostic(severity: .error, code: "SPECIES_PLAN_TARGET_MISSING", message: "Species \(draft.speciesID) is not in the current catalog.")
                ]
            )
        }

        var diagnostics = plannerDiagnostics(catalog: catalog, species: species, draft: draft, descriptor: descriptor)
        if descriptor.editCapabilities.assets {
            diagnostics.append(contentsOf: assetDiagnostics(catalog: catalog, species: species, draft: draft, root: root, fileManager: fileManager))
        } else if !draft.assetData.isEmpty || !draft.assetImports.isEmpty {
            diagnostics.append(
                unsupportedEditDiagnostic(
                    code: "SPECIES_ASSET_EDIT_UNSUPPORTED_PROFILE",
                    message: "\(draft.speciesID) asset imports are read-only for \(catalog.profile.rawValue).",
                    span: species.sourceSpan
                )
            )
        }
        var changes: [SpeciesEditFileChange] = []

        if diagnostics.allSatisfy({ $0.severity != .error }) {
            if speciesInfoChanged(species: species, draft: draft) {
                let speciesRewrite = rewriteSpeciesInfoChange(
                    root: root,
                    descriptor: descriptor,
                    species: species,
                    draft: draft
                )
                diagnostics.append(contentsOf: speciesRewrite.diagnostics)
                if let speciesChange = speciesRewrite.change {
                    changes.append(speciesChange)
                }
            }
            if levelUpChanged(species: species, draft: draft) {
                if let span = species.learnsets.levelUpSourceSpan,
                   let symbol = species.learnsets.levelUpSymbol,
                   let path = descriptor.levelUpPaths.first(where: { $0 == span.relativePath }) ?? species.learnsets.levelUpSourceSpan?.relativePath,
                   let levelUpChange = rewriteChange(
                    root: root,
                    path: path,
                    span: span,
                    replacement: renderLevelUpLearnset(symbol: symbol, moves: draft.levelUpMoves)
                   ) {
                    changes.append(levelUpChange)
                } else {
                    diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_LEVEL_UP_SPAN_MISSING", message: "\(draft.speciesID) has no editable level-up learnset source span.", span: species.sourceSpan))
                }
            }
            if tmhmChanged(species: species, draft: draft) {
                if let span = species.learnsets.tmhmSourceSpan,
                   let path = descriptor.tmhmPath,
                   let tmhmChange = rewriteChange(
                    root: root,
                    path: path,
                    span: span,
                    replacement: renderTMHMLearnset(speciesID: draft.speciesID, moves: draft.tmhmMoves, catalog: catalog, profile: catalog.profile)
                   ) {
                    changes.append(tmhmChange)
                } else {
                    diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_TMHM_SPAN_MISSING", message: "\(draft.speciesID) has no editable TM/HM learnset source span.", span: species.sourceSpan))
                }
            }
            if eggChanged(species: species, draft: draft) {
                if let span = species.learnsets.eggSourceSpan,
                   let path = descriptor.eggMovesPath,
                   let eggChange = rewriteChange(
                    root: root,
                    path: path,
                    span: span,
                    replacement: renderEggMoves(speciesID: draft.speciesID, moves: draft.eggMoves)
                   ) {
                    changes.append(eggChange)
                } else {
                    diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_EGG_MOVES_SPAN_MISSING", message: "\(draft.speciesID) has no editable egg-move source span. Adding new egg-move blocks is not supported yet.", span: species.sourceSpan))
                }
            }
            if evolutionChanged(species: species, draft: draft) {
                if let span = species.evolutions.first?.sourceSpan,
                   let path = descriptor.evolutionPath,
                   let evolutionChange = rewriteChange(
                    root: root,
                    path: path,
                    span: span,
                    replacement: renderEvolutionEntry(speciesID: draft.speciesID, evolutions: draft.evolutions)
                   ) {
                    changes.append(evolutionChange)
                } else if descriptor.evolutionPath != nil {
                    diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_EVOLUTION_SPAN_MISSING", message: "\(draft.speciesID) has no editable evolution source span.", span: species.sourceSpan))
                }
            }
            if pokedexChanged(species: species, draft: draft) {
                if let span = species.pokedex?.sourceSpan,
                   let path = descriptor.pokedexPath,
                   let pokedexDraft = draft.pokedex,
                   let pokedexChange = rewriteChange(
                    root: root,
                    path: path,
                    span: span,
                    replacement: renderPokedexEntry(speciesID: draft.speciesID, draft: pokedexDraft, descriptionSymbol: species.pokedex?.descriptionSymbol)
                   ) {
                    changes.append(pokedexChange)
                } else {
                    diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_POKEDEX_SPAN_MISSING", message: "\(draft.speciesID) has no editable Pokedex source span.", span: species.sourceSpan))
                }
            }
            if pokedexTextChanged(species: species, draft: draft) {
                if let span = species.pokedex?.descriptionSpan,
                   let path = descriptor.pokedexTextPath,
                   let text = draft.pokedex?.description,
                   let symbol = species.pokedex?.descriptionSymbol,
                   let pokedexTextChange = rewriteChange(
                    root: root,
                    path: path,
                    span: span,
                    replacement: renderPokedexText(symbol: symbol, text: text)
                   ) {
                    changes.append(pokedexTextChange)
                } else {
                    diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_POKEDEX_TEXT_SPAN_MISSING", message: "\(draft.speciesID) has no editable Pokedex description source span.", span: species.sourceSpan))
                }
            }
            if tutorChanged(species: species, draft: draft) {
                if let span = species.learnsets.tutorSourceSpan,
                   let path = descriptor.tutorPath,
                   let tutorChange = rewriteChange(
                    root: root,
                    path: path,
                    span: span,
                    replacement: renderTutorLearnset(speciesID: draft.speciesID, moves: draft.tutorMoves)
                   ) {
                    changes.append(tutorChange)
                } else {
                    diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_TUTOR_SPAN_MISSING", message: "\(draft.speciesID) has no editable tutor learnset source span. Bitfield-based tutor learnsets are only supported if they already exist in the source.", span: species.sourceSpan))
                }
            }

            changes.append(contentsOf: assetChanges(catalog: catalog, draft: draft, root: root, fileManager: fileManager))
        }

        let plannedChanges = changes.map {
            PlannedChange(path: $0.path, summary: $0.summary, span: SourceSpan(relativePath: $0.path, startLine: 1))
        }
        let mutationPlan = MutationPlan(
            title: "Apply Pokemon edits to \(draft.speciesID)",
            summary: "\(changes.count) source file change(s) for Pokemon species data.",
            changes: plannedChanges,
            diagnostics: diagnostics,
            requiresExplicitApply: true
        )
        return SpeciesEditPlan(
            rootPath: catalog.root.path,
            speciesID: draft.speciesID,
            draft: draft,
            changes: changes,
            diagnostics: diagnostics,
            mutationPlan: mutationPlan,
            backupRelativeRoot: ".pokemonhackstudio/backups/\(backupTimestamp())"
        )
    }

    private static func blockedPlan(catalog: ProjectSpeciesCatalog, draft: SpeciesEditDraft, diagnostics: [Diagnostic]) -> SpeciesEditPlan {
        let mutationPlan = MutationPlan(
            title: "Pokemon edits blocked for \(draft.speciesID)",
            summary: "No source files are applyable until diagnostics are resolved.",
            diagnostics: diagnostics,
            requiresExplicitApply: true
        )
        return SpeciesEditPlan(
            rootPath: catalog.root.path,
            speciesID: draft.speciesID,
            draft: draft,
            changes: [],
            diagnostics: diagnostics,
            mutationPlan: mutationPlan,
            backupRelativeRoot: ".pokemonhackstudio/backups/\(backupTimestamp())"
        )
    }

    private static func plannerDiagnostics(catalog: ProjectSpeciesCatalog, species: SpeciesDetail, draft: SpeciesEditDraft, descriptor: SpeciesCatalogDescriptor) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        appendStructuralDiagnostics(draft: draft, species: species, diagnostics: &diagnostics)
        appendCapabilityDiagnostics(descriptor: descriptor, species: species, draft: draft, diagnostics: &diagnostics)
        appendConstantDiagnostics(catalog: catalog, draft: draft, species: species, descriptor: descriptor, diagnostics: &diagnostics)
        appendEvolutionDiagnostics(catalog: catalog, draft: draft, species: species, descriptor: descriptor, diagnostics: &diagnostics)

        if descriptor.editCapabilities.eggMoves, eggChanged(species: species, draft: draft), species.learnsets.eggSourceSpan == nil {
            diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_EGG_MOVES_SPAN_MISSING", message: "\(draft.speciesID) has no editable egg-move source span.", span: species.sourceSpan))
        }

        return diagnostics
    }

    private static func appendCapabilityDiagnostics(
        descriptor: SpeciesCatalogDescriptor,
        species: SpeciesDetail,
        draft: SpeciesEditDraft,
        diagnostics: inout [Diagnostic]
    ) {
        let capabilities = descriptor.editCapabilities
        if speciesInfoChanged(species: species, draft: draft), !capabilities.speciesInfo {
            diagnostics.append(unsupportedEditDiagnostic(code: "SPECIES_INFO_EDIT_UNSUPPORTED_PROFILE", message: "\(draft.speciesID) base stat/species-info rows are read-only for this profile.", span: species.sourceSpan))
        }
        if levelUpChanged(species: species, draft: draft), !capabilities.levelUp {
            diagnostics.append(unsupportedEditDiagnostic(code: "SPECIES_LEVEL_UP_EDIT_UNSUPPORTED_PROFILE", message: "\(draft.speciesID) level-up learnsets are read-only for this profile.", span: species.learnsets.levelUpSourceSpan ?? species.sourceSpan))
        }
        if tmhmChanged(species: species, draft: draft), !capabilities.tmhm {
            diagnostics.append(unsupportedEditDiagnostic(code: "SPECIES_TMHM_EDIT_UNSUPPORTED_PROFILE", message: "\(draft.speciesID) TM/HM learnsets are read-only for this profile.", span: species.learnsets.tmhmSourceSpan ?? species.sourceSpan))
        }
        if eggChanged(species: species, draft: draft), !capabilities.eggMoves {
            diagnostics.append(unsupportedEditDiagnostic(code: "SPECIES_EGG_MOVES_EDIT_UNSUPPORTED_PROFILE", message: "\(draft.speciesID) egg moves are read-only for this profile.", span: species.learnsets.eggSourceSpan ?? species.sourceSpan))
        }
        if tutorChanged(species: species, draft: draft), !capabilities.tutor {
            diagnostics.append(unsupportedEditDiagnostic(code: "SPECIES_TUTOR_EDIT_UNSUPPORTED_PROFILE", message: "\(draft.speciesID) tutor learnsets are read-only for this profile.", span: species.learnsets.tutorSourceSpan ?? species.sourceSpan))
        }
        if evolutionChanged(species: species, draft: draft), !capabilities.evolutions {
            diagnostics.append(unsupportedEditDiagnostic(code: "SPECIES_EVOLUTION_EDIT_UNSUPPORTED_PROFILE", message: "\(draft.speciesID) evolution rows are read-only for this profile.", span: species.evolutions.first?.sourceSpan ?? species.sourceSpan))
        }
        if pokedexChanged(species: species, draft: draft), !capabilities.pokedex {
            diagnostics.append(unsupportedEditDiagnostic(code: "SPECIES_POKEDEX_EDIT_UNSUPPORTED_PROFILE", message: "\(draft.speciesID) Pokedex rows are read-only for this profile.", span: species.pokedex?.sourceSpan ?? species.sourceSpan))
        }
        if pokedexTextChanged(species: species, draft: draft), !capabilities.pokedexText {
            diagnostics.append(unsupportedEditDiagnostic(code: "SPECIES_POKEDEX_TEXT_EDIT_UNSUPPORTED_PROFILE", message: "\(draft.speciesID) Pokedex description text is read-only for this profile.", span: species.pokedex?.descriptionSpan ?? species.pokedex?.sourceSpan ?? species.sourceSpan))
        }
    }

    private static func unsupportedEditDiagnostic(code: String, message: String, span: SourceSpan?) -> Diagnostic {
        Diagnostic(severity: .error, code: code, message: message, span: span)
    }

    private static func appendStructuralDiagnostics(draft: SpeciesEditDraft, species: SpeciesDetail, diagnostics: inout [Diagnostic]) {
        let stats = [
            ("HP", draft.baseStats.hp),
            ("Attack", draft.baseStats.attack),
            ("Defense", draft.baseStats.defense),
            ("Speed", draft.baseStats.speed),
            ("Sp. Attack", draft.baseStats.spAttack),
            ("Sp. Defense", draft.baseStats.spDefense)
        ]
        for (label, value) in stats where !(0...255).contains(value) {
            diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_BASE_STAT_INVALID", message: "\(label) must be between 0 and 255.", span: species.sourceSpan))
        }
        let evs = [
            ("HP EV", draft.evYield.hp),
            ("Attack EV", draft.evYield.attack),
            ("Defense EV", draft.evYield.defense),
            ("Speed EV", draft.evYield.speed),
            ("Sp. Attack EV", draft.evYield.spAttack),
            ("Sp. Defense EV", draft.evYield.spDefense)
        ]
        for (label, value) in evs where !(0...3).contains(value) {
            diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_EV_YIELD_INVALID", message: "\(label) must be between 0 and 3.", span: species.sourceSpan))
        }
        if draft.evYield.total > 3 {
            diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_EV_TOTAL_INVALID", message: "EV yield total must not exceed 3.", span: species.sourceSpan))
        }
        if draft.types.count != 2 {
            diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_TYPES_INVALID", message: "Exactly two type slots are required.", span: species.sourceSpan))
        }
        if draft.abilities.count != 2 {
            diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_ABILITIES_INVALID", message: "Exactly two ability slots are required.", span: species.sourceSpan))
        }
        if draft.eggGroups.count != 2 {
            diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_EGG_GROUPS_INVALID", message: "Exactly two egg group slots are required.", span: species.sourceSpan))
        }
        for move in draft.levelUpMoves {
            if !(1...100).contains(move.level) {
                diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_LEVEL_UP_LEVEL_INVALID", message: "Level-up move levels must be between 1 and 100.", span: species.learnsets.levelUpSourceSpan ?? species.sourceSpan))
            }
        }
        if draft.evolutions.count > 5 {
            diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_EVOLUTIONS_EXCEEDED", message: "Species cannot have more than 5 evolutions.", span: species.evolutions.first?.sourceSpan ?? species.sourceSpan))
        }
        if let pokedex = draft.pokedex {
            appendPokedexNumericDiagnostic(label: "height", value: pokedex.height, code: "SPECIES_POKEDEX_HEIGHT_INVALID", species: species, diagnostics: &diagnostics)
            appendPokedexNumericDiagnostic(label: "weight", value: pokedex.weight, code: "SPECIES_POKEDEX_WEIGHT_INVALID", species: species, diagnostics: &diagnostics)
            appendPokedexNumericDiagnostic(label: "Pokemon scale", value: pokedex.pokemonScale, code: "SPECIES_POKEDEX_POKEMON_SCALE_INVALID", species: species, diagnostics: &diagnostics)
            appendPokedexNumericDiagnostic(label: "Pokemon offset", value: pokedex.pokemonOffset, code: "SPECIES_POKEDEX_POKEMON_OFFSET_INVALID", species: species, diagnostics: &diagnostics)
            appendPokedexNumericDiagnostic(label: "trainer scale", value: pokedex.trainerScale, code: "SPECIES_POKEDEX_TRAINER_SCALE_INVALID", species: species, diagnostics: &diagnostics)
            appendPokedexNumericDiagnostic(label: "trainer offset", value: pokedex.trainerOffset, code: "SPECIES_POKEDEX_TRAINER_OFFSET_INVALID", species: species, diagnostics: &diagnostics)
        }
    }

    private static func appendPokedexNumericDiagnostic(
        label: String,
        value: String,
        code: String,
        species: SpeciesDetail,
        diagnostics: inout [Diagnostic]
    ) {
        if Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) == nil {
            diagnostics.append(Diagnostic(severity: .error, code: code, message: "Pokedex \(label) must be a numeric value.", span: species.pokedex?.sourceSpan ?? species.sourceSpan))
        }
    }

    private static func appendConstantDiagnostics(catalog: ProjectSpeciesCatalog, draft: SpeciesEditDraft, species: SpeciesDetail, descriptor: SpeciesCatalogDescriptor, diagnostics: inout [Diagnostic]) {
        let constants = catalog.constants.mapValues { Set($0.map(\.symbol)) }
        if descriptor.speciesInfoStyle == .expansionSpeciesScalars {
            guard let original = SpeciesEditDraft(detail: species) else { return }
            if draft.types != original.types {
                appendUnknown(draft.types, group: .types, constants: constants, species: species, diagnostics: &diagnostics)
            }
            if draft.abilities != original.abilities {
                appendUnknown(draft.abilities, group: .abilities, constants: constants, species: species, diagnostics: &diagnostics)
            }
            if draft.eggGroups != original.eggGroups {
                appendUnknown(draft.eggGroups, group: .eggGroups, constants: constants, species: species, diagnostics: &diagnostics)
            }
            if draft.growthRate != original.growthRate {
                appendUnknown([draft.growthRate], group: .growthRates, constants: constants, species: species, diagnostics: &diagnostics)
            }
            if draft.bodyColor != original.bodyColor {
                appendUnknown([draft.bodyColor], group: .bodyColors, constants: constants, species: species, diagnostics: &diagnostics)
            }
            let changedItems = [
                draft.itemCommon != original.itemCommon ? draft.itemCommon : nil,
                draft.itemRare != original.itemRare ? draft.itemRare : nil
            ]
            appendUnknown(changedItems.compactMap { $0 }.filter { $0 != "ITEM_NONE" }, group: .items, constants: constants, species: species, diagnostics: &diagnostics)
            return
        }
        appendUnknown(draft.types, group: .types, constants: constants, species: species, diagnostics: &diagnostics)
        appendUnknown(draft.abilities, group: .abilities, constants: constants, species: species, diagnostics: &diagnostics)
        appendUnknown(draft.eggGroups, group: .eggGroups, constants: constants, species: species, diagnostics: &diagnostics)
        appendUnknown([draft.growthRate], group: .growthRates, constants: constants, species: species, diagnostics: &diagnostics)
        appendUnknown([draft.bodyColor], group: .bodyColors, constants: constants, species: species, diagnostics: &diagnostics)
        appendUnknown([draft.itemCommon, draft.itemRare].filter { $0 != "ITEM_NONE" }, group: .items, constants: constants, species: species, diagnostics: &diagnostics)
        if descriptor.editCapabilities.levelUp || levelUpChanged(species: species, draft: draft) {
            appendUnknown(draft.levelUpMoves.map(\.move).filter { $0 != "MOVE_NONE" }, group: .moves, constants: constants, species: species, diagnostics: &diagnostics)
        }
        if descriptor.editCapabilities.eggMoves || eggChanged(species: species, draft: draft) {
            appendUnknown(draft.eggMoves.filter { $0 != "MOVE_NONE" }, group: .moves, constants: constants, species: species, diagnostics: &diagnostics)
        }
        if descriptor.editCapabilities.tutor || tutorChanged(species: species, draft: draft) {
            appendUnknown(draft.tutorMoves, group: .moves, constants: constants, species: species, diagnostics: &diagnostics)
        }
        if descriptor.editCapabilities.tmhm || tmhmChanged(species: species, draft: draft) {
            appendUnknown(draft.tmhmMoves, group: .tmhmMoves, constants: constants, species: species, diagnostics: &diagnostics)
        }
    }

    private static func appendEvolutionDiagnostics(catalog: ProjectSpeciesCatalog, draft: SpeciesEditDraft, species: SpeciesDetail, descriptor: SpeciesCatalogDescriptor, diagnostics: inout [Diagnostic]) {
        guard descriptor.editCapabilities.evolutions || evolutionChanged(species: species, draft: draft) else { return }
        let constants = catalog.constants.mapValues { Set($0.map(\.symbol)) }
        appendUnknown(draft.evolutions.map(\.method), group: .evolutionMethods, constants: constants, species: species, diagnostics: &diagnostics)

        let knownSpecies = Set(catalog.species.map(\.speciesID))
        for evolution in draft.evolutions {
            if !knownSpecies.contains(evolution.targetSpecies) {
                diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_DRAFT_CONSTANT_UNRESOLVED", message: "\(evolution.targetSpecies) is not a valid species in the current project.", span: species.sourceSpan))
            }
            if itemParameterEvolutionMethods.contains(evolution.method) {
                appendUnknown([evolution.parameter], group: .items, constants: constants, species: species, diagnostics: &diagnostics)
            }
            if zeroParameterEvolutionMethods.contains(evolution.method), compact(evolution.parameter) != "0" {
                diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_EVOLUTION_PARAMETER_INVALID", message: "\(evolution.method) requires parameter 0.", span: species.evolutions.first?.sourceSpan ?? species.sourceSpan))
            }
        }
    }

    private static func assetDiagnostics(
        catalog: ProjectSpeciesCatalog,
        species: SpeciesDetail,
        draft: SpeciesEditDraft,
        root: URL,
        fileManager: FileManager
    ) -> [Diagnostic] {
        let directory = speciesAssetDirectory(for: draft.speciesID)
        return SpeciesAssetKind.allCases.flatMap { kind -> [Diagnostic] in
            guard let data = draft.assetData[kind] else { return [] }
            let path = "\(directory)/\(kind.filename)"
            var diagnostics = validateAssetPath(kind: kind, path: path, species: species)
            if species.assets.first(where: { $0.kind == kind }) == nil {
                diagnostics.append(assetDiagnostic(
                    .error,
                    "SPECIES_ASSET_SOURCE_UNINDEXED",
                    "\(draft.speciesID) has no indexed \(kind.title) asset source row.",
                    path: path,
                    species: species
                ))
            }
            if !fileManager.fileExists(atPath: root.appendingPathComponent(path).path) {
                diagnostics.append(assetDiagnostic(
                    .error,
                    "SPECIES_ASSET_SOURCE_MISSING",
                    "\(draft.speciesID) \(kind.title) source asset is missing: \(path).",
                    path: path,
                    species: species
                ))
            }
            diagnostics.append(contentsOf: validateAssetData(kind: kind, data: data, path: path, species: species))
            return diagnostics
        }
    }

    private static func validateAssetPath(kind: SpeciesAssetKind, path: String, species: SpeciesDetail) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        let lowercased = path.lowercased()
        if path.contains("..") || path.hasPrefix("/") {
            diagnostics.append(assetDiagnostic(.error, "SPECIES_ASSET_PATH_UNSAFE", "Pokemon asset import path must stay inside the project source tree.", path: path, species: species))
        }
        if lowercased.contains(".4bpp") || lowercased.hasSuffix(".gbapal") || lowercased.contains("/build/") {
            diagnostics.append(assetDiagnostic(.error, "SPECIES_ASSET_GENERATED_OUTPUT_BLOCKED", "Pokemon asset imports must target source PNG or palette files, not generated outputs.", path: path, species: species))
        }
        if kind.isSpriteAsset, !lowercased.hasSuffix(".png") {
            diagnostics.append(assetDiagnostic(.error, "SPECIES_ASSET_KIND_PATH_MISMATCH", "\(kind.title) imports must target a PNG source path.", path: path, species: species))
        }
        if kind.isPaletteAsset, !lowercased.hasSuffix(".pal") {
            diagnostics.append(assetDiagnostic(.error, "SPECIES_ASSET_KIND_PATH_MISMATCH", "\(kind.title) imports must target a palette source path.", path: path, species: species))
        }
        return diagnostics
    }

    private static func validateAssetData(kind: SpeciesAssetKind, data: Data, path: String, species: SpeciesDetail) -> [Diagnostic] {
        guard !data.isEmpty else {
            return [assetDiagnostic(.error, "SPECIES_ASSET_DATA_EMPTY", "\(kind.title) import data is empty.", path: path, species: species)]
        }

        if kind.isSpriteAsset {
            guard let png = GraphicsMetadataParser.pngMetadata(from: data), png.width > 0, png.height > 0 else {
                return [assetDiagnostic(.error, "SPECIES_ASSET_PNG_INVALID", "\(kind.title) import must be a valid PNG with readable IHDR metadata.", path: path, species: species)]
            }
            var diagnostics: [Diagnostic] = []
            if let expected = kind.expectedPNGDimensions,
               png.width != expected.width || png.height != expected.height
            {
                diagnostics.append(assetDiagnostic(.error, "SPECIES_ASSET_PNG_DIMENSIONS_UNSUPPORTED", "\(kind.title) PNG must be \(expected.width)x\(expected.height); detected \(png.width)x\(png.height).", path: path, species: species))
            }
            if let paletteColorCount = png.paletteColorCount, paletteColorCount > kind.pngPaletteColorLimit {
                let paletteDescription = kind.pngPaletteColorLimit == 16
                    ? "Gen III sprite sources must fit 16 colors."
                    : "\(kind.title) source PNGs must fit \(kind.pngPaletteColorLimit) colors."
                diagnostics.append(assetDiagnostic(.error, "SPECIES_ASSET_PNG_PALETTE_OVER_LIMIT", "\(kind.title) PNG declares \(paletteColorCount) palette colors; \(paletteDescription)", path: path, species: species))
            }
            if png.paletteColorCount == nil {
                diagnostics.append(assetDiagnostic(.warning, "SPECIES_ASSET_PNG_PALETTE_UNVERIFIED", "\(kind.title) PNG has no PLTE chunk; palette fit must be reviewed before conversion.", path: path, species: species))
            }
            return diagnostics
        }

        let sourcePalette = GraphicsMetadataParser.paletteMetadata(from: data, path: path)
        let binaryPalette = GraphicsMetadataParser.gbaPaletteMetadata(from: data)
        guard let palette = sourcePalette ?? binaryPalette
        else {
            return [assetDiagnostic(.error, "SPECIES_ASSET_PALETTE_INVALID", "\(kind.title) import must be a JASC .pal source file.", path: path, species: species)]
        }

        var diagnostics: [Diagnostic] = []
        if sourcePalette == nil, binaryPalette != nil {
            diagnostics.append(assetDiagnostic(.error, "SPECIES_ASSET_BINARY_PALETTE_BLOCKED", "Binary .gbapal palette bytes cannot replace source .pal files until a conversion workflow is available.", path: path, species: species))
        }
        if !palette.hasSlotZero {
            diagnostics.append(assetDiagnostic(.error, "SPECIES_ASSET_PALETTE_SLOT_ZERO_MISSING", "\(kind.title) palette must include slot 0.", path: path, species: species))
        }
        if palette.colorCount > 16 {
            diagnostics.append(assetDiagnostic(.error, "SPECIES_ASSET_PALETTE_OVER_LIMIT", "\(kind.title) palette has \(palette.colorCount) colors; Gen III species palettes must fit 16 colors.", path: path, species: species))
        }
        if palette.colorCount < 16 {
            diagnostics.append(assetDiagnostic(.warning, "SPECIES_ASSET_PALETTE_UNDER_LIMIT", "\(kind.title) palette has \(palette.colorCount) colors; expected species palettes normally carry 16 colors.", path: path, species: species))
        }
        if palette.gbaPrecisionLossCount > 0 {
            diagnostics.append(assetDiagnostic(.warning, "SPECIES_ASSET_PALETTE_PRECISION_LOSS", "\(kind.title) palette has \(palette.gbaPrecisionLossCount) color(s) that lose precision in GBA 15-bit color.", path: path, species: species))
        }
        return diagnostics
    }

    private static func assetDiagnostic(_ severity: DiagnosticSeverity, _ code: String, _ message: String, path: String, species: SpeciesDetail) -> Diagnostic {
        Diagnostic(severity: severity, code: code, message: message, span: SourceSpan(relativePath: path, startLine: species.sourceSpan.startLine))
    }

    private static func appendUnknown(
        _ symbols: [String],
        group: SpeciesConstantGroup,
        constants: [SpeciesConstantGroup: Set<String>],
        species: SpeciesDetail,
        diagnostics: inout [Diagnostic]
    ) {
        let known = constants[group] ?? []
        for symbol in Set(symbols) where !symbol.isEmpty && !known.contains(symbol) {
            diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_DRAFT_CONSTANT_UNRESOLVED", message: "\(symbol) is not defined in the current project constants.", span: species.sourceSpan))
        }
    }

    private static func rewriteSpeciesInfoChange(
        root: URL,
        descriptor: SpeciesCatalogDescriptor,
        species: SpeciesDetail,
        draft: SpeciesEditDraft
    ) -> (change: SpeciesEditFileChange?, diagnostics: [Diagnostic]) {
        switch descriptor.speciesInfoStyle {
        case .classicSpeciesInfo, .rubyBaseStats:
            return (
                rewriteChange(
                    root: root,
                    path: descriptor.speciesPath,
                    span: species.sourceSpan,
                    replacement: renderSpeciesInfoEntry(draft, style: descriptor.speciesInfoStyle)
                ),
                []
            )
        case .expansionSpeciesScalars:
            return rewriteExpansionSpeciesInfoScalarChange(
                root: root,
                path: descriptor.speciesPath,
                species: species,
                draft: draft
            )
        }
    }

    private static func rewriteExpansionSpeciesInfoScalarChange(
        root: URL,
        path: String,
        species: SpeciesDetail,
        draft: SpeciesEditDraft
    ) -> (change: SpeciesEditFileChange?, diagnostics: [Diagnostic]) {
        let url = root.appendingPathComponent(path)
        guard let originalText = try? readText(at: url), let originalData = originalText.data(using: .utf8) else {
            return (
                nil,
                [Diagnostic(severity: .error, code: "SPECIES_SOURCE_MISSING", message: "Species source file is missing or unreadable: \(path).", span: species.sourceSpan)]
            )
        }

        let entryText = sourceEntryText(in: originalText, span: species.sourceSpan)
        let fields = SpeciesInfoScalarFieldPatcher.fields(in: entryText)
        let fieldChanges = expansionSpeciesInfoScalarFieldChanges(species: species, draft: draft, fields: fields)
        guard !fieldChanges.isEmpty else { return (nil, []) }

        var diagnostics: [Diagnostic] = []
        guard let replacementEntry = SpeciesInfoScalarFieldPatcher.patch(
            entryBody: entryText,
            changes: fieldChanges,
            diagnostics: &diagnostics,
            span: species.sourceSpan
        ) else {
            return (nil, diagnostics)
        }

        let newText = replaceLines(in: originalText, span: species.sourceSpan, replacement: replacementEntry)
        guard newText != originalText, let newData = newText.data(using: .utf8) else {
            return (nil, diagnostics)
        }
        return (
            SpeciesEditFileChange(
                path: path,
                summary: "Update Expansion species_info.h scalar fields",
                originalByteCount: originalData.count,
                originalSHA1: pokemonHackSHA1Hex(originalData),
                newByteCount: newData.count,
                newData: newData,
                textPreview: replacementEntry
            ),
            diagnostics
        )
    }

    private static func expansionSpeciesInfoScalarFieldChanges(
        species: SpeciesDetail,
        draft: SpeciesEditDraft,
        fields: [String: SpeciesInfoFieldSlice]
    ) -> [SpeciesInfoScalarFieldChange] {
        guard let original = SpeciesEditDraft(detail: species) else { return [] }
        var changes: [SpeciesInfoScalarFieldChange] = []

        appendExpansionFieldChange(["baseHP"], newValue: "\(draft.baseStats.hp)", didChange: draft.baseStats.hp != original.baseStats.hp, fields: fields, changes: &changes)
        appendExpansionFieldChange(["baseAttack"], newValue: "\(draft.baseStats.attack)", didChange: draft.baseStats.attack != original.baseStats.attack, fields: fields, changes: &changes)
        appendExpansionFieldChange(["baseDefense"], newValue: "\(draft.baseStats.defense)", didChange: draft.baseStats.defense != original.baseStats.defense, fields: fields, changes: &changes)
        appendExpansionFieldChange(["baseSpeed"], newValue: "\(draft.baseStats.speed)", didChange: draft.baseStats.speed != original.baseStats.speed, fields: fields, changes: &changes)
        appendExpansionFieldChange(["baseSpAttack"], newValue: "\(draft.baseStats.spAttack)", didChange: draft.baseStats.spAttack != original.baseStats.spAttack, fields: fields, changes: &changes)
        appendExpansionFieldChange(["baseSpDefense"], newValue: "\(draft.baseStats.spDefense)", didChange: draft.baseStats.spDefense != original.baseStats.spDefense, fields: fields, changes: &changes)
        appendExpansionFieldChange(["type1", "types"], newValue: fixedValue(draft.types, index: 0, fallback: "TYPE_NORMAL"), didChange: fixedValue(draft.types, index: 0, fallback: "TYPE_NORMAL") != fixedValue(original.types, index: 0, fallback: "TYPE_NORMAL"), fields: fields, changes: &changes)
        appendExpansionFieldChange(["type2", "types"], newValue: fixedValue(draft.types, index: 1, fallback: "TYPE_NORMAL"), didChange: fixedValue(draft.types, index: 1, fallback: "TYPE_NORMAL") != fixedValue(original.types, index: 1, fallback: "TYPE_NORMAL"), fields: fields, changes: &changes)
        appendExpansionFieldChange(["catchRate"], newValue: draft.catchRate, didChange: draft.catchRate != original.catchRate, fields: fields, changes: &changes)
        appendExpansionFieldChange(["expYield", "baseExp"], newValue: draft.expYield, didChange: draft.expYield != original.expYield, fields: fields, changes: &changes)
        appendExpansionFieldChange(["evYield_HP"], newValue: "\(draft.evYield.hp)", didChange: draft.evYield.hp != original.evYield.hp, fields: fields, changes: &changes)
        appendExpansionFieldChange(["evYield_Attack"], newValue: "\(draft.evYield.attack)", didChange: draft.evYield.attack != original.evYield.attack, fields: fields, changes: &changes)
        appendExpansionFieldChange(["evYield_Defense"], newValue: "\(draft.evYield.defense)", didChange: draft.evYield.defense != original.evYield.defense, fields: fields, changes: &changes)
        appendExpansionFieldChange(["evYield_Speed"], newValue: "\(draft.evYield.speed)", didChange: draft.evYield.speed != original.evYield.speed, fields: fields, changes: &changes)
        appendExpansionFieldChange(["evYield_SpAttack"], newValue: "\(draft.evYield.spAttack)", didChange: draft.evYield.spAttack != original.evYield.spAttack, fields: fields, changes: &changes)
        appendExpansionFieldChange(["evYield_SpDefense"], newValue: "\(draft.evYield.spDefense)", didChange: draft.evYield.spDefense != original.evYield.spDefense, fields: fields, changes: &changes)
        appendExpansionFieldChange(["itemCommon", "item1"], newValue: draft.itemCommon, didChange: draft.itemCommon != original.itemCommon, fields: fields, changes: &changes)
        appendExpansionFieldChange(["itemRare", "item2"], newValue: draft.itemRare, didChange: draft.itemRare != original.itemRare, fields: fields, changes: &changes)
        appendExpansionFieldChange(["genderRatio"], newValue: draft.genderRatio, didChange: draft.genderRatio != original.genderRatio, fields: fields, changes: &changes)
        appendExpansionFieldChange(["eggCycles"], newValue: draft.eggCycles, didChange: draft.eggCycles != original.eggCycles, fields: fields, changes: &changes)
        appendExpansionFieldChange(["friendship"], newValue: draft.friendship, didChange: draft.friendship != original.friendship, fields: fields, changes: &changes)
        appendExpansionFieldChange(["growthRate"], newValue: draft.growthRate, didChange: draft.growthRate != original.growthRate, fields: fields, changes: &changes)
        appendExpansionFieldChange(["eggGroup1", "eggGroups"], newValue: fixedValue(draft.eggGroups, index: 0, fallback: "EGG_GROUP_NONE"), didChange: fixedValue(draft.eggGroups, index: 0, fallback: "EGG_GROUP_NONE") != fixedValue(original.eggGroups, index: 0, fallback: "EGG_GROUP_NONE"), fields: fields, changes: &changes)
        appendExpansionFieldChange(["eggGroup2", "eggGroups"], newValue: fixedValue(draft.eggGroups, index: 1, fallback: "EGG_GROUP_NONE"), didChange: fixedValue(draft.eggGroups, index: 1, fallback: "EGG_GROUP_NONE") != fixedValue(original.eggGroups, index: 1, fallback: "EGG_GROUP_NONE"), fields: fields, changes: &changes)
        appendExpansionFieldChange(["ability1", "abilities"], newValue: fixedValue(draft.abilities, index: 0, fallback: "ABILITY_NONE"), didChange: fixedValue(draft.abilities, index: 0, fallback: "ABILITY_NONE") != fixedValue(original.abilities, index: 0, fallback: "ABILITY_NONE"), fields: fields, changes: &changes)
        appendExpansionFieldChange(["ability2", "abilities"], newValue: fixedValue(draft.abilities, index: 1, fallback: "ABILITY_NONE"), didChange: fixedValue(draft.abilities, index: 1, fallback: "ABILITY_NONE") != fixedValue(original.abilities, index: 1, fallback: "ABILITY_NONE"), fields: fields, changes: &changes)
        appendExpansionFieldChange(["safariZoneFleeRate"], newValue: draft.safariZoneFleeRate, didChange: draft.safariZoneFleeRate != original.safariZoneFleeRate, fields: fields, changes: &changes)
        appendExpansionFieldChange(["bodyColor"], newValue: draft.bodyColor, didChange: draft.bodyColor != original.bodyColor, fields: fields, changes: &changes)
        appendExpansionFieldChange(["noFlip"], newValue: draft.noFlip ? "TRUE" : "FALSE", didChange: draft.noFlip != original.noFlip, fields: fields, changes: &changes)

        return changes
    }

    private static func appendExpansionFieldChange(
        _ candidateFields: [String],
        newValue: String,
        didChange: Bool,
        fields: [String: SpeciesInfoFieldSlice],
        changes: inout [SpeciesInfoScalarFieldChange]
    ) {
        guard didChange else { return }
        let field = candidateFields.first { fields[$0] != nil } ?? candidateFields[0]
        if let current = fields[field], compact(current.value) == compact(newValue) {
            return
        }
        changes.append(SpeciesInfoScalarFieldChange(field: field, replacement: newValue))
    }

    private static func sourceEntryText(in text: String, span: SourceSpan) -> String {
        let lines = text.components(separatedBy: "\n")
        let start = max(0, span.startLine - 1)
        let end = min(max(start, span.endLine - 1), max(0, lines.count - 1))
        guard start <= end, start < lines.count else { return "" }
        return lines[start...end].joined(separator: "\n")
    }

    private static func rewriteChange(root: URL, path: String, span: SourceSpan, replacement: String) -> SpeciesEditFileChange? {
        let url = root.appendingPathComponent(path)
        guard let originalText = try? readText(at: url), let originalData = originalText.data(using: .utf8) else {
            return SpeciesEditFileChange(
                path: path,
                summary: "Read \(path) before Pokemon rewrite",
                originalByteCount: 0,
                newByteCount: 0,
                newData: Data(),
                textPreview: nil
            )
        }
        let newText = replaceLines(in: originalText, span: span, replacement: replacement)
        guard newText != originalText, let newData = newText.data(using: .utf8) else { return nil }
        return SpeciesEditFileChange(
            path: path,
            summary: "Update Pokemon source block",
            originalByteCount: originalData.count,
            originalSHA1: pokemonHackSHA1Hex(originalData),
            newByteCount: newData.count,
            newData: newData,
            textPreview: replacement
        )
    }

    private static func assetChanges(
        catalog: ProjectSpeciesCatalog,
        draft: SpeciesEditDraft,
        root: URL,
        fileManager: FileManager
    ) -> [SpeciesEditFileChange] {
        let directory = speciesAssetDirectory(for: draft.speciesID)
        return SpeciesAssetKind.allCases.compactMap { kind in
            guard let newData = draft.assetData[kind] else { return nil }
            let path = "\(directory)/\(kind.filename)"
            let url = root.appendingPathComponent(path)
            let originalData = try? Data(contentsOf: url)

            return SpeciesEditFileChange(
                path: path,
                summary: "Replace \(kind.rawValue) asset",
                originalByteCount: originalData?.count ?? 0,
                originalSHA1: originalData.map { pokemonHackSHA1Hex($0) },
                newByteCount: newData.count,
                newData: newData,
                textPreview: nil
            )
        }
    }

    private static func speciesAssetDirectory(for speciesID: String) -> String {
        "graphics/pokemon/\(assetSlug(for: speciesID))"
    }

    private static func speciesInfoChanged(species: SpeciesDetail, draft: SpeciesEditDraft) -> Bool {
        guard let original = SpeciesEditDraft(detail: species) else { return true }
        return draft.baseStats != original.baseStats ||
            draft.types != original.types ||
            draft.abilities != original.abilities ||
            draft.evYield != original.evYield ||
            draft.catchRate != original.catchRate ||
            draft.expYield != original.expYield ||
            draft.genderRatio != original.genderRatio ||
            draft.eggCycles != original.eggCycles ||
            draft.friendship != original.friendship ||
            draft.growthRate != original.growthRate ||
            draft.safariZoneFleeRate != original.safariZoneFleeRate ||
            draft.eggGroups != original.eggGroups ||
            draft.itemCommon != original.itemCommon ||
            draft.itemRare != original.itemRare ||
            draft.bodyColor != original.bodyColor ||
            draft.noFlip != original.noFlip
    }

    private static func pokedexChanged(species: SpeciesDetail, draft: SpeciesEditDraft) -> Bool {
        guard let old = species.pokedex, let new = draft.pokedex else {
            return (species.pokedex != nil) != (draft.pokedex != nil)
        }
        return old.categoryName != new.categoryName ||
               old.height != new.height ||
               old.weight != new.weight ||
               old.pokemonScale != new.pokemonScale ||
               old.pokemonOffset != new.pokemonOffset ||
               old.trainerScale != new.trainerScale ||
               old.trainerOffset != new.trainerOffset
    }

    private static func pokedexTextChanged(species: SpeciesDetail, draft: SpeciesEditDraft) -> Bool {
        guard let oldText = species.pokedex?.description, let newText = draft.pokedex?.description else {
            return (species.pokedex?.description != nil) != (draft.pokedex?.description != nil)
        }
        return oldText != newText
    }

    private static func renderPokedexEntry(speciesID: String, draft: SpeciesPokedexDraft, descriptionSymbol: String?) -> String {
        var lines: [String] = []
        let dexID = speciesID.replacingOccurrences(of: "SPECIES_", with: "NATIONAL_DEX_")
        lines.append("    [\(dexID)] =")
        lines.append("    {")
        lines.append("        .categoryName = _(\(cStringLiteral(draft.categoryName))),")
        lines.append("        .height = \(draft.height),")
        lines.append("        .weight = \(draft.weight),")
        lines.append("        .description = \(descriptionSymbol ?? "gDummyPokedexText"),")
        lines.append("        .pokemonScale = \(draft.pokemonScale),")
        lines.append("        .pokemonOffset = \(draft.pokemonOffset),")
        lines.append("        .trainerScale = \(draft.trainerScale),")
        lines.append("        .trainerOffset = \(draft.trainerOffset),")
        lines.append("    },")
        return lines.joined(separator: "\n")
    }

    private static func renderPokedexText(symbol: String, text: String) -> String {
        "const u8 \(symbol)[] = _(\(cStringLiteral(text)));"
    }

    private static func cStringLiteral(_ text: String) -> String {
        var result = "\""
        for scalar in text.unicodeScalars {
            switch scalar {
            case "\\":
                result += "\\\\"
            case "\"":
                result += "\\\""
            case "\n":
                result += "\\n"
            case "\r":
                result += "\\r"
            case "\t":
                result += "\\t"
            default:
                result.unicodeScalars.append(scalar)
            }
        }
        result += "\""
        return result
    }

    private static func renderSpeciesInfoEntry(_ draft: SpeciesEditDraft, style: SpeciesInfoStyle) -> String {
        switch style {
        case .classicSpeciesInfo:
            return """
                [\(draft.speciesID)] =
                {
                    .baseHP = \(draft.baseStats.hp),
                    .baseAttack = \(draft.baseStats.attack),
                    .baseDefense = \(draft.baseStats.defense),
                    .baseSpeed = \(draft.baseStats.speed),
                    .baseSpAttack = \(draft.baseStats.spAttack),
                    .baseSpDefense = \(draft.baseStats.spDefense),
                    .types = {\(draft.types.joined(separator: ", "))},
                    .catchRate = \(draft.catchRate),
                    .expYield = \(draft.expYield),
                    .evYield_HP = \(draft.evYield.hp),
                    .evYield_Attack = \(draft.evYield.attack),
                    .evYield_Defense = \(draft.evYield.defense),
                    .evYield_Speed = \(draft.evYield.speed),
                    .evYield_SpAttack = \(draft.evYield.spAttack),
                    .evYield_SpDefense = \(draft.evYield.spDefense),
                    .itemCommon = \(draft.itemCommon),
                    .itemRare = \(draft.itemRare),
                    .genderRatio = \(draft.genderRatio),
                    .eggCycles = \(draft.eggCycles),
                    .friendship = \(draft.friendship),
                    .growthRate = \(draft.growthRate),
                    .eggGroups = {\(draft.eggGroups.joined(separator: ", "))},
                    .abilities = {\(draft.abilities.joined(separator: ", "))},
                    .safariZoneFleeRate = \(draft.safariZoneFleeRate),
                    .bodyColor = \(draft.bodyColor),
                    .noFlip = \(draft.noFlip ? "TRUE" : "FALSE"),
                },
            """
        case .expansionSpeciesScalars:
            return """
                [\(draft.speciesID)] =
                {
                    .baseHP = \(draft.baseStats.hp),
                    .baseAttack = \(draft.baseStats.attack),
                    .baseDefense = \(draft.baseStats.defense),
                    .baseSpeed = \(draft.baseStats.speed),
                    .baseSpAttack = \(draft.baseStats.spAttack),
                    .baseSpDefense = \(draft.baseStats.spDefense),
                    .catchRate = \(draft.catchRate),
                    .expYield = \(draft.expYield),
                    .evYield_HP = \(draft.evYield.hp),
                    .evYield_Attack = \(draft.evYield.attack),
                    .evYield_Defense = \(draft.evYield.defense),
                    .evYield_Speed = \(draft.evYield.speed),
                    .evYield_SpAttack = \(draft.evYield.spAttack),
                    .evYield_SpDefense = \(draft.evYield.spDefense),
                    .itemCommon = \(draft.itemCommon),
                    .itemRare = \(draft.itemRare),
                    .genderRatio = \(draft.genderRatio),
                    .eggCycles = \(draft.eggCycles),
                    .friendship = \(draft.friendship),
                    .growthRate = \(draft.growthRate),
                    .safariZoneFleeRate = \(draft.safariZoneFleeRate),
                    .bodyColor = \(draft.bodyColor),
                    .noFlip = \(draft.noFlip ? "TRUE" : "FALSE"),
                },
            """
        case .rubyBaseStats:
            return """
                [\(draft.speciesID)] =
                {
                    .baseHP = \(draft.baseStats.hp),
                    .baseAttack = \(draft.baseStats.attack),
                    .baseDefense = \(draft.baseStats.defense),
                    .baseSpeed = \(draft.baseStats.speed),
                    .baseSpAttack = \(draft.baseStats.spAttack),
                    .baseSpDefense = \(draft.baseStats.spDefense),
                    .type1 = \(fixedValue(draft.types, index: 0, fallback: "TYPE_NORMAL")),
                    .type2 = \(fixedValue(draft.types, index: 1, fallback: "TYPE_NORMAL")),
                    .catchRate = \(draft.catchRate),
                    .expYield = \(draft.expYield),
                    .evYield_HP = \(draft.evYield.hp),
                    .evYield_Attack = \(draft.evYield.attack),
                    .evYield_Defense = \(draft.evYield.defense),
                    .evYield_Speed = \(draft.evYield.speed),
                    .evYield_SpAttack = \(draft.evYield.spAttack),
                    .evYield_SpDefense = \(draft.evYield.spDefense),
                    .item1 = \(draft.itemCommon),
                    .item2 = \(draft.itemRare),
                    .genderRatio = \(draft.genderRatio),
                    .eggCycles = \(draft.eggCycles),
                    .friendship = \(draft.friendship),
                    .growthRate = \(draft.growthRate),
                    .eggGroup1 = \(fixedValue(draft.eggGroups, index: 0, fallback: "EGG_GROUP_NONE")),
                    .eggGroup2 = \(fixedValue(draft.eggGroups, index: 1, fallback: "EGG_GROUP_NONE")),
                    .ability1 = \(fixedValue(draft.abilities, index: 0, fallback: "ABILITY_NONE")),
                    .ability2 = \(fixedValue(draft.abilities, index: 1, fallback: "ABILITY_NONE")),
                    .safariZoneFleeRate = \(draft.safariZoneFleeRate),
                    .bodyColor = \(draft.bodyColor),
                    .noFlip = \(draft.noFlip ? "TRUE" : "FALSE"),
                },
            """
        }
    }

    private static func fixedValue(_ values: [String], index: Int, fallback: String) -> String {
        values.indices.contains(index) ? values[index] : fallback
    }

    private static func renderLevelUpLearnset(symbol: String, moves: [SpeciesLevelUpMoveDraft]) -> String {
        let rows = moves.map { move in
            "    LEVEL_UP_MOVE(\(String(format: "%2d", move.level)), \(move.move)),"
        }.joined(separator: "\n")
        return """
        static const u16 \(symbol)[] = {
        \(rows)
            LEVEL_UP_END
        };
        """
    }

    private static func renderTMHMLearnset(speciesID: String, moves: [String], catalog: ProjectSpeciesCatalog, profile: GameProfile) -> String {
        let orderedMoves = orderedTMHMMoves(moves, catalog: catalog)
        switch profile {
        case .pokefirered:
            guard !orderedMoves.isEmpty else {
                return "    [\(speciesID)]     = TMHM_LEARNSET(0),"
            }
            let tokensByMove = Dictionary(uniqueKeysWithValues: (catalog.constants[.tmhmMoves] ?? []).map { ($0.symbol, $0.value) })
            let rows = orderedMoves.compactMap { move -> String? in
                guard let token = tokensByMove[move] else { return nil }
                return "                                        | TMHM(\(token))"
            }
            guard let first = rows.first else {
                return "    [\(speciesID)]     = TMHM_LEARNSET(0),"
            }
            let firstLine = "    [\(speciesID)]     = TMHM_LEARNSET(\(first.replacingOccurrences(of: "                                        | ", with: ""))"
            let rest = rows.dropFirst().joined(separator: "\n")
            if rest.isEmpty {
                return "\(firstLine)),"
            }
            return "\(firstLine)\n\(rest)),"
        default:
            let rows = orderedMoves.map { move in
                "        .\(String(move.dropFirst("MOVE_".count))) = TRUE,"
            }.joined(separator: "\n")
            return """
                [\(speciesID)] = { .learnset = {
            \(rows)
                } },
            """
        }
    }

    private static func renderEggMoves(speciesID: String, moves: [String]) -> String {
        let speciesName = speciesID.replacingOccurrences(of: "SPECIES_", with: "")
        guard !moves.isEmpty else {
            return "    egg_moves(\(speciesName)),"
        }
        let rows = moves.map { "              \($0)" }.joined(separator: ",\n")
        return """
            egg_moves(\(speciesName),
        \(rows)),
        """
    }

    private static func renderEvolutionEntry(speciesID: String, evolutions: [SpeciesEvolutionDraft]) -> String {
        guard !evolutions.isEmpty else {
            return "    [\(speciesID)] = {},"
        }
        let rows = evolutions.map { evo in
            "{ \(evo.method), \(evo.parameter), \(evo.targetSpecies) }"
        }.joined(separator: ",\n                            ")

        if evolutions.count > 1 {
            return "    [\(speciesID)] = {\n                            \(rows)\n                        },"
        } else {
            return "    [\(speciesID)] = {\(rows)},"
        }
    }

    private static func orderedTMHMMoves(_ moves: [String], catalog: ProjectSpeciesCatalog) -> [String] {
        let moveSet = Set(moves)
        let ordered = (catalog.constants[.tmhmMoves] ?? []).map(\.symbol).filter { moveSet.contains($0) }
        let leftovers = moveSet.subtracting(ordered).sorted()
        return ordered + leftovers
    }

    private static func levelUpChanged(species: SpeciesDetail, draft: SpeciesEditDraft) -> Bool {
        draft.levelUpMoves.map { "\($0.level):\($0.move)" } != species.learnsets.levelUp.map { "\($0.level):\($0.move)" }
    }

    private static func tmhmChanged(species: SpeciesDetail, draft: SpeciesEditDraft) -> Bool {
        Set(draft.tmhmMoves) != Set(species.learnsets.tmhm.map(\.move))
    }

    private static func eggChanged(species: SpeciesDetail, draft: SpeciesEditDraft) -> Bool {
        draft.eggMoves != species.learnsets.egg.map(\.move)
    }

    private static func evolutionChanged(species: SpeciesDetail, draft: SpeciesEditDraft) -> Bool {
        draft.evolutions.map { "\($0.method):\($0.parameter):\($0.targetSpecies)" } != species.evolutions.map { "\($0.method):\($0.parameter):\($0.targetSpecies)" }
    }

    private static func tutorChanged(species: SpeciesDetail, draft: SpeciesEditDraft) -> Bool {
        Set(draft.tutorMoves) != Set(species.learnsets.tutor.map(\.move))
    }

    private static func renderTutorLearnset(speciesID: String, moves: [String]) -> String {
        var lines: [String] = []
        lines.append("    [\(speciesID)]             = (")
        if moves.isEmpty {
            lines.append("                                0")
        } else {
            for (index, move) in moves.enumerated() {
                let suffix = index == moves.count - 1 ? "" : " |"
                let moveConstant = move.replacingOccurrences(of: "MOVE_", with: "")
                lines.append("                                TUTOR(\(moveConstant))\(suffix)")
            }
        }
        lines.append("                                ),")
        return lines.joined(separator: "\n")
    }

    private static func backupTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "\(formatter.string(from: Date()))-\(UUID().uuidString.prefix(8))"
    }

    private static let itemParameterEvolutionMethods: Set<String> = [
        "EVO_ITEM",
        "EVO_TRADE_ITEM"
    ]

    private static let zeroParameterEvolutionMethods: Set<String> = [
        "EVO_FRIENDSHIP",
        "EVO_FRIENDSHIP_DAY",
        "EVO_FRIENDSHIP_NIGHT",
        "EVO_TRADE"
    ]
}

public enum SpeciesMutationApplier {
    public static func apply(plan: SpeciesEditPlan, fileManager: FileManager = .default) throws -> SpeciesApplyResult {
        let root = URL(fileURLWithPath: plan.rootPath).standardizedFileURL
        let backupRoot = root.appendingPathComponent(plan.backupRelativeRoot)
        let applyability = plan.validateApplyability(fileManager: fileManager)
        guard applyability.isApplyable else {
            return SpeciesApplyResult(backupRootPath: backupRoot.path, appliedChanges: [], diagnostics: applyability.diagnostics)
        }
        guard !plan.changes.isEmpty else {
            return SpeciesApplyResult(backupRootPath: backupRoot.path, appliedChanges: [])
        }
        let backupDiagnostics = SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
            plan.backupRelativeRoot,
            root: root,
            fileManager: fileManager,
            codePrefix: "SPECIES_APPLY_BACKUP",
            subject: "Pokemon backup path"
        )
        guard backupDiagnostics.isEmpty else {
            return SpeciesApplyResult(backupRootPath: backupRoot.path, appliedChanges: [], diagnostics: backupDiagnostics)
        }

        try fileManager.createDirectory(at: backupRoot, withIntermediateDirectories: true)
        var applied: [AppliedSpeciesFileChange] = []
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
            applied.append(AppliedSpeciesFileChange(path: change.path, backupPath: backup.path, byteCount: change.newData.count))
        }
        return SpeciesApplyResult(backupRootPath: backupRoot.path, appliedChanges: applied)
    }
}

private enum SpeciesEditApplySafety {
    static func applyability(for plan: SpeciesEditPlan, fileManager: FileManager) -> SpeciesEditApplyability {
        var diagnostics = plan.diagnostics.filter { $0.severity == .error }
        let root = URL(fileURLWithPath: plan.rootPath).standardizedFileURL
        guard !plan.rootPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_APPLY_ROOT_MISSING", message: "Pokemon apply root path is missing."))
            return SpeciesEditApplyability(isApplyable: false, diagnostics: diagnostics)
        }
        guard fileManager.fileExists(atPath: root.path) else {
            diagnostics.append(Diagnostic(severity: .error, code: "SPECIES_APPLY_ROOT_MISSING", message: "Pokemon apply root does not exist: \(plan.rootPath)."))
            return SpeciesEditApplyability(isApplyable: false, diagnostics: diagnostics)
        }
        guard !plan.changes.isEmpty else {
            diagnostics.append(Diagnostic(severity: .warning, code: "SPECIES_APPLY_NO_CHANGES", message: "No Pokemon source changes are staged."))
            return SpeciesEditApplyability(isApplyable: false, diagnostics: diagnostics)
        }
        for change in plan.changes {
            diagnostics.append(contentsOf: diagnosticsForChange(change, root: root, fileManager: fileManager))
        }
        return SpeciesEditApplyability(isApplyable: diagnostics.allSatisfy { $0.severity != .error }, diagnostics: diagnostics)
    }

    private static func diagnosticsForChange(_ change: SpeciesEditFileChange, root: URL, fileManager: FileManager) -> [Diagnostic] {
        let destination = root.appendingPathComponent(change.path).standardizedFileURL
        let pathDiagnostics = SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
            change.path,
            root: root,
            fileManager: fileManager,
            codePrefix: "SPECIES_APPLY",
            subject: "Pokemon apply path"
        )
        guard pathDiagnostics.isEmpty else {
            return pathDiagnostics
        }
        guard fileManager.fileExists(atPath: destination.path) else {
            return [pathDiagnostic("SPECIES_APPLY_SOURCE_MISSING", "Pokemon source file is missing before apply: \(change.path).", path: change.path)]
        }
        guard let currentData = try? Data(contentsOf: destination) else {
            return [pathDiagnostic("SPECIES_APPLY_SOURCE_UNREADABLE", "Pokemon source file could not be read before apply: \(change.path).", path: change.path)]
        }
        guard currentData.count == change.originalByteCount else {
            return [pathDiagnostic("SPECIES_APPLY_ORIGINAL_SIZE_MISMATCH", "Pokemon source file changed since planning: \(change.path).", path: change.path)]
        }
        if let originalSHA1 = change.originalSHA1, pokemonHackSHA1Hex(currentData) != originalSHA1 {
            return [pathDiagnostic("SPECIES_APPLY_ORIGINAL_HASH_MISMATCH", "Pokemon source file contents changed since planning: \(change.path).", path: change.path)]
        }
        return []
    }

    private static func pathDiagnostic(_ code: String, _ message: String, path: String) -> Diagnostic {
        Diagnostic(severity: .error, code: code, message: message, span: SourceSpan(relativePath: path, startLine: 1))
    }
}

private struct SpeciesCatalogDescriptor {
    let speciesPath: String
    let speciesTableSymbol: String
    let speciesInfoStyle: SpeciesInfoStyle
    let levelUpPointerPath: String?
    let levelUpPaths: [String]
    let levelUpDirectory: String?
    let tmhmPath: String?
    let tmhmTableSymbols: [String]
    let eggMovesPath: String?
    let evolutionPath: String?
    let pokedexPath: String?
    let pokedexTextPath: String?
    let tutorPath: String?
    let tutorTableSymbols: [String]
    let editCapabilities: SpeciesEditCapabilities
    let constants: [SpeciesConstantDescriptor]

    var supportsEditing: Bool {
        editCapabilities.supportsAnyEditing
    }

    static func descriptor(for profile: GameProfile) -> SpeciesCatalogDescriptor? {
        switch profile {
        case .pokeemerald:
            return SpeciesCatalogDescriptor(
                speciesPath: "src/data/pokemon/species_info.h",
                speciesTableSymbol: "gSpeciesInfo",
                speciesInfoStyle: .classicSpeciesInfo,
                levelUpPointerPath: "src/data/pokemon/level_up_learnset_pointers.h",
                levelUpPaths: ["src/data/pokemon/level_up_learnsets.h"],
                levelUpDirectory: nil,
                tmhmPath: "src/data/pokemon/tmhm_learnsets.h",
                tmhmTableSymbols: ["gTMHMLearnsets"],
                eggMovesPath: "src/data/pokemon/egg_moves.h",
                evolutionPath: "src/data/pokemon/evolution.h",
                pokedexPath: "src/data/pokemon/pokedex_entries.h",
                pokedexTextPath: "src/data/pokemon/pokedex_text.h",
                tutorPath: "src/data/pokemon/tutor_learnsets.h",
                tutorTableSymbols: ["sTutorLearnsets", "gTutorLearnsets"],
                editCapabilities: .classic,
                constants: classicConstants
            )
        case .pokefirered:
            return SpeciesCatalogDescriptor(
                speciesPath: "src/data/pokemon/species_info.h",
                speciesTableSymbol: "gSpeciesInfo",
                speciesInfoStyle: .classicSpeciesInfo,
                levelUpPointerPath: "src/data/pokemon/level_up_learnset_pointers.h",
                levelUpPaths: ["src/data/pokemon/level_up_learnsets.h"],
                levelUpDirectory: nil,
                tmhmPath: "src/data/pokemon/tmhm_learnsets.h",
                tmhmTableSymbols: ["sTMHMLearnsets", "gTMHMLearnsets"],
                eggMovesPath: "src/data/pokemon/egg_moves.h",
                evolutionPath: "src/data/pokemon/evolution.h",
                pokedexPath: "src/data/pokemon/pokedex_entries.h",
                pokedexTextPath: "src/data/pokemon/pokedex_text.h",
                tutorPath: "src/data/pokemon/tutor_learnsets.h",
                tutorTableSymbols: ["sTutorLearnsets", "gTutorLearnsets"],
                editCapabilities: .classic,
                constants: classicConstants
            )
        case .pokeruby:
            return SpeciesCatalogDescriptor(
                speciesPath: "src/data/pokemon/base_stats.h",
                speciesTableSymbol: "gBaseStats",
                speciesInfoStyle: .rubyBaseStats,
                levelUpPointerPath: "src/data/pokemon/level_up_learnset_pointers.h",
                levelUpPaths: ["src/data/pokemon/level_up_learnsets.h"],
                levelUpDirectory: nil,
                tmhmPath: "src/data/pokemon/tmhm_learnsets.h",
                tmhmTableSymbols: ["gTMHMLearnsets"],
                eggMovesPath: "src/data/pokemon/egg_moves.h",
                evolutionPath: "src/data/pokemon/evolution.h",
                pokedexPath: "src/data/pokedex_entries_en.h",
                pokedexTextPath: "src/data/pokedex_text_en.h",
                tutorPath: nil,
                tutorTableSymbols: [],
                editCapabilities: .rubyBaseStats,
                constants: classicConstants
            )
        case .pokeemeraldExpansion:
            return SpeciesCatalogDescriptor(
                speciesPath: "src/data/pokemon/species_info.h",
                speciesTableSymbol: "gSpeciesInfo",
                speciesInfoStyle: .expansionSpeciesScalars,
                levelUpPointerPath: nil,
                levelUpPaths: ["src/data/pokemon/level_up_learnsets.h"],
                levelUpDirectory: "src/data/pokemon/level_up_learnsets",
                tmhmPath: "src/data/pokemon/tmhm_learnsets.h",
                tmhmTableSymbols: ["sTMHMLearnsets", "gTMHMLearnsets"],
                eggMovesPath: "src/data/pokemon/egg_moves.h",
                evolutionPath: "src/data/pokemon/evolution.h",
                pokedexPath: "src/data/pokemon/pokedex_entries.h",
                pokedexTextPath: "src/data/pokemon/pokedex_text.h",
                tutorPath: "src/data/pokemon/tutor_learnsets.h",
                tutorTableSymbols: ["sTutorLearnsets", "gTutorLearnsets"],
                editCapabilities: .expansionSpeciesScalars,
                constants: classicConstants
            )
        case .binaryROM, .ndsROM, .pokediamond, .pokeplatinum, .pokeheartgold, .pokeblack, .pmdSky,
             .pokemonColosseum, .pokemonXD, .pokemonBox, .pokemonChannel, .gameCubeMedia, .unknown:
            return nil
        }
    }

    private static let classicConstants = [
        SpeciesConstantDescriptor(path: "include/constants/pokemon.h", group: .types, prefixes: ["TYPE_"]),
        SpeciesConstantDescriptor(path: "include/constants/abilities.h", group: .abilities, prefixes: ["ABILITY_"]),
        SpeciesConstantDescriptor(path: "include/constants/pokemon.h", group: .eggGroups, prefixes: ["EGG_GROUP_"]),
        SpeciesConstantDescriptor(path: "include/constants/pokemon.h", group: .growthRates, prefixes: ["GROWTH_"]),
        SpeciesConstantDescriptor(path: "include/constants/pokemon.h", group: .bodyColors, prefixes: ["BODY_COLOR_"]),
        SpeciesConstantDescriptor(path: "include/constants/items.h", group: .items, prefixes: ["ITEM_"]),
        SpeciesConstantDescriptor(path: "include/constants/moves.h", group: .moves, prefixes: ["MOVE_"]),
        SpeciesConstantDescriptor(path: "include/constants/pokemon.h", group: .evolutionMethods, prefixes: ["EVO_"])
    ]
}

private struct SpeciesConstantDescriptor: Sendable {
    let path: String
    let group: SpeciesConstantGroup
    let prefixes: [String]
    let exactSymbols: [String]

    init(path: String, group: SpeciesConstantGroup, prefixes: [String], exactSymbols: [String] = []) {
        self.path = path
        self.group = group
        self.prefixes = prefixes
        self.exactSymbols = exactSymbols
    }
}

private enum SpeciesInfoStyle {
    case classicSpeciesInfo
    case rubyBaseStats
    case expansionSpeciesScalars
}

private struct SpeciesInfoScalarFieldChange {
    let field: String
    let replacement: String
}

private struct SpeciesInfoFieldSlice {
    let name: String
    let value: String
    let valueRange: Range<String.Index>
}

private enum SpeciesInfoScalarFieldPatcher {
    static func fields(in text: String) -> [String: SpeciesInfoFieldSlice] {
        guard let open = firstOpenBrace(in: text) else {
            return [:]
        }
        let close = matchingCloseBrace(from: open, in: text) ?? text.endIndex

        var fields: [String: SpeciesInfoFieldSlice] = [:]
        var index = text.index(after: open)
        var depth = 0
        var state = SpeciesInfoScannerState.normal
        while index < close {
            let character = text[index]
            if consumeScannerState(&state, text: text, index: &index) {
                continue
            }

            if state == .normal {
                if character == "{" || character == "(" || character == "[" {
                    depth += 1
                    index = text.index(after: index)
                    continue
                }
                if character == "}" || character == ")" || character == "]" {
                    depth = max(0, depth - 1)
                    index = text.index(after: index)
                    continue
                }
                if depth == 0, character == "." {
                    if let slice = fieldSlice(startingAt: index, close: close, in: text) {
                        fields[slice.name] = slice
                        index = slice.valueRange.upperBound
                        continue
                    }
                }
            }
            index = text.index(after: index)
        }
        return fields
    }

    static func patch(
        entryBody: String,
        changes: [SpeciesInfoScalarFieldChange],
        diagnostics: inout [Diagnostic],
        span: SourceSpan
    ) -> String? {
        let fields = fields(in: entryBody)
        var replacements: [(field: SpeciesInfoFieldSlice, value: String)] = []
        for change in changes {
            guard let field = fields[change.field] else {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "SPECIES_EXPANSION_SCALAR_FIELD_MISSING",
                        message: "Cannot edit \(change.field) because the existing Expansion species entry does not contain that top-level scalar field.",
                        span: span
                    )
                )
                continue
            }
            guard isSafeScalarValue(field.value) else {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "SPECIES_EXPANSION_NON_SCALAR_FIELD_BLOCKED",
                        message: "Cannot edit \(change.field) because the existing Expansion species field is not a single-value top-level scalar.",
                        span: span
                    )
                )
                continue
            }
            replacements.append((field, change.replacement))
        }
        guard diagnostics.allSatisfy({ $0.severity != .error }) else { return nil }
        guard !replacements.isEmpty else { return nil }

        var patched = entryBody
        for replacement in replacements.sorted(by: { $0.field.valueRange.lowerBound > $1.field.valueRange.lowerBound }) {
            patched.replaceSubrange(replacement.field.valueRange, with: replacement.value)
        }
        return patched
    }

    private static func fieldSlice(startingAt dot: String.Index, close: String.Index, in text: String) -> SpeciesInfoFieldSlice? {
        var cursor = text.index(after: dot)
        let nameStart = cursor
        while cursor < close, isIdentifier(text[cursor]) {
            cursor = text.index(after: cursor)
        }
        guard cursor > nameStart else { return nil }
        let name = String(text[nameStart..<cursor])
        cursor = skipWhitespace(from: cursor, upTo: close, in: text)
        guard cursor < close, text[cursor] == "=" else { return nil }
        cursor = text.index(after: cursor)
        cursor = skipWhitespace(from: cursor, upTo: close, in: text)
        let valueEnd = valueEnd(start: cursor, close: close, in: text)
        let range = trimmedRange(cursor..<valueEnd, in: text)
        return SpeciesInfoFieldSlice(name: name, value: String(text[range]), valueRange: range)
    }

    private static func valueEnd(start: String.Index, close: String.Index, in text: String) -> String.Index {
        var index = start
        var depth = 0
        var state = SpeciesInfoScannerState.normal
        while index < close {
            let character = text[index]
            if consumeScannerState(&state, text: text, index: &index) {
                continue
            }
            if state == .normal {
                if character == "{" || character == "(" || character == "[" {
                    depth += 1
                } else if character == "}" || character == ")" || character == "]" {
                    if depth == 0 {
                        return index
                    }
                    depth -= 1
                } else if character == "," && depth == 0 {
                    return index
                }
            }
            index = text.index(after: index)
        }
        return index
    }

    private static func firstOpenBrace(in text: String) -> String.Index? {
        text.firstIndex(of: "{")
    }

    private static func matchingCloseBrace(from open: String.Index, in text: String) -> String.Index? {
        var index = open
        var depth = 0
        var state = SpeciesInfoScannerState.normal
        while index < text.endIndex {
            let character = text[index]
            if consumeScannerState(&state, text: text, index: &index) {
                continue
            }
            if state == .normal {
                if character == "{" {
                    depth += 1
                } else if character == "}" {
                    depth -= 1
                    if depth == 0 {
                        return index
                    }
                }
            }
            index = text.index(after: index)
        }
        return nil
    }

    private static func skipWhitespace(from start: String.Index, upTo end: String.Index, in text: String) -> String.Index {
        var index = start
        while index < end, text[index].isWhitespace {
            index = text.index(after: index)
        }
        return index
    }

    private static func trimmedRange(_ range: Range<String.Index>, in text: String) -> Range<String.Index> {
        var lower = range.lowerBound
        var upper = range.upperBound
        while lower < upper, text[lower].isWhitespace {
            lower = text.index(after: lower)
        }
        while upper > lower {
            let before = text.index(before: upper)
            guard text[before].isWhitespace else { break }
            upper = before
        }
        return lower..<upper
    }

    private static func isIdentifier(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || character == "_"
    }

    private static func isSafeScalarValue(_ value: String) -> Bool {
        !value.contains("{") && !value.contains("}")
    }
}

private enum SpeciesInfoScannerState {
    case normal
    case lineComment
    case blockComment
    case string
    case character
}

private func consumeScannerState(_ state: inout SpeciesInfoScannerState, text: String, index: inout String.Index) -> Bool {
    let character = text[index]
    let nextIndex = text.index(after: index)
    let next = nextIndex < text.endIndex ? text[nextIndex] : nil

    switch state {
    case .normal:
        if character == "/", next == "/" {
            state = .lineComment
            index = text.index(after: nextIndex)
            return true
        }
        if character == "/", next == "*" {
            state = .blockComment
            index = text.index(after: nextIndex)
            return true
        }
        if character == "\"" {
            state = .string
            index = nextIndex
            return true
        }
        if character == "'" {
            state = .character
            index = nextIndex
            return true
        }
        return false
    case .lineComment:
        if character == "\n" {
            state = .normal
        }
        index = nextIndex
        return true
    case .blockComment:
        if character == "*", next == "/" {
            state = .normal
            index = text.index(after: nextIndex)
        } else {
            index = nextIndex
        }
        return true
    case .string:
        if character == "\\" {
            index = nextIndex < text.endIndex ? text.index(after: nextIndex) : nextIndex
        } else {
            if character == "\"" {
                state = .normal
            }
            index = nextIndex
        }
        return true
    case .character:
        if character == "\\" {
            index = nextIndex < text.endIndex ? text.index(after: nextIndex) : nextIndex
        } else {
            if character == "'" {
                state = .normal
            }
            index = nextIndex
        }
        return true
    }
}

private struct SpeciesEditCapabilities {
    let speciesInfo: Bool
    let levelUp: Bool
    let tmhm: Bool
    let eggMoves: Bool
    let evolutions: Bool
    let pokedex: Bool
    let pokedexText: Bool
    let tutor: Bool
    let assets: Bool

    var supportsAnyEditing: Bool {
        speciesInfo || levelUp || tmhm || eggMoves || evolutions || pokedex || pokedexText || tutor || assets
    }

    static let classic = SpeciesEditCapabilities(
        speciesInfo: true,
        levelUp: true,
        tmhm: true,
        eggMoves: true,
        evolutions: true,
        pokedex: true,
        pokedexText: true,
        tutor: true,
        assets: true
    )

    static let rubyBaseStats = SpeciesEditCapabilities(
        speciesInfo: true,
        levelUp: false,
        tmhm: false,
        eggMoves: false,
        evolutions: false,
        pokedex: false,
        pokedexText: false,
        tutor: false,
        assets: false
    )

    static let expansionSpeciesScalars = SpeciesEditCapabilities(
        speciesInfo: true,
        levelUp: false,
        tmhm: false,
        eggMoves: false,
        evolutions: false,
        pokedex: false,
        pokedexText: false,
        tutor: false,
        assets: false
    )

    static let none = SpeciesEditCapabilities(
        speciesInfo: false,
        levelUp: false,
        tmhm: false,
        eggMoves: false,
        evolutions: false,
        pokedex: false,
        pokedexText: false,
        tutor: false,
        assets: false
    )
}

private func constantList(_ value: String?) -> [String] {
    guard let value else { return [] }
    return symbolTokens(in: value).filter { token in
        token.hasPrefix("TYPE_")
            || token.hasPrefix("ABILITY_")
            || token.hasPrefix("EGG_GROUP_")
            || token.hasPrefix("ITEM_")
    }
}

private func symbolTokens(in text: String) -> [String] {
    text.split { character in
        !(character == "_" || character.isLetter || character.isNumber)
    }.map(String.init)
}

private func normalizedFixedList(_ values: [String], count: Int, fallback: String) -> [String] {
    Array((values.filter { !$0.isEmpty } + Array(repeating: fallback, count: count)).prefix(count))
}

private func intValue(_ value: String?) -> Int? {
    guard let value else { return nil }
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    if let integer = Int(trimmed) {
        return integer
    }
    if trimmed.hasPrefix("0x") || trimmed.hasPrefix("0X") {
        return Int(trimmed.dropFirst(2), radix: 16)
    }
    return nil
}

private func boolValue(_ value: String?) -> Bool {
    compact(value) == "TRUE" || compact(value) == "true" || compact(value) == "1"
}

private func compact(_ value: String?) -> String? {
    guard let value else { return nil }
    let compacted = value
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    return compacted.isEmpty ? nil : compacted
}

private func unwrapTextMacro(_ value: String?) -> String? {
    guard var value = compact(value) else { return nil }
    if value.hasPrefix("_("), value.hasSuffix(")") {
        value = String(value.dropFirst(2).dropLast())
    }
    if value.hasPrefix("\""), value.hasSuffix("\"") {
        value = String(value.dropFirst().dropLast())
    }
    return value.replacingOccurrences(of: #"\""#, with: "\"")
}

private func preview(_ text: String) -> String {
    text.components(separatedBy: .newlines)
        .prefix(16)
        .joined(separator: "\n")
}

private func assetSlug(for speciesID: String) -> String {
    speciesID.replacingOccurrences(of: "SPECIES_", with: "").lowercased()
}

private func tmhmToken(fromItemSymbol symbol: String) -> String? {
    let pattern = #"ITEM_((?:TM|HM)[0-9]{2}_[A-Z0-9_]+)"#
    guard let match = regexMatches(pattern, in: symbol).first, match.count >= 2 else {
        return nil
    }
    return match[1]
}

private func tmhmMoveName(from token: String) -> String {
    guard let underscore = token.firstIndex(of: "_") else { return token }
    return String(token[token.index(after: underscore)...])
}

private func displayName(for speciesID: String) -> String {
    speciesID.replacingOccurrences(of: "SPECIES_", with: "")
        .split(separator: "_")
        .map { part in
            part.prefix(1).uppercased() + part.dropFirst().lowercased()
        }
        .joined(separator: " ")
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

private func speciesConstant(fromDexSymbol symbol: String) -> String {
    if symbol.hasPrefix("NATIONAL_DEX_") {
        return "SPECIES_\(symbol.dropFirst("NATIONAL_DEX_".count))"
    }
    if symbol.hasPrefix("HOENN_DEX_") {
        return "SPECIES_\(symbol.dropFirst("HOENN_DEX_".count))"
    }
    return symbol
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

private func readText(at url: URL) throws -> String {
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

private func firstRegexMatch(_ pattern: String, in text: String) -> String? {
    regexMatches(pattern, in: text).first?.dropFirst().first
}

private func regexMatches(
    _ pattern: String,
    in text: String,
    options: NSRegularExpression.Options = []
) -> [[String]] {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
        return []
    }
    let nsText = text as NSString
    return regex.matches(in: text, range: NSRange(location: 0, length: nsText.length)).map { match in
        (0..<match.numberOfRanges).map { index in
            let range = match.range(at: index)
            guard range.location != NSNotFound else { return "" }
            return nsText.substring(with: range)
        }
    }
}
