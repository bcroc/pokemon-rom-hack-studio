import Foundation

public enum PokemonDataCompatibilitySurface: String, Codable, Equatable, CaseIterable, Sendable {
    case species
    case moves
    case items
    case levelUpLearnsets
    case tmhmLearnsets
    case eggMoves
    case evolutions
    case pokedex
    case assets
    case cries
    case forms
}

public enum PokemonDataCompatibilityStatus: String, Codable, Equatable, CaseIterable, Sendable {
    case indexed
    case editable
    case readOnly
    case blocked
}

public struct PokemonDataCompatibilityReport: Codable, Equatable {
    public let root: SourceLocation
    public let profile: GameProfile
    public let adapterID: String
    public let adapterName: String
    public let summary: PokemonDataCompatibilitySummary
    public let entries: [PokemonDataCompatibilityEntry]
    public let diagnostics: [Diagnostic]

    public init(
        root: SourceLocation,
        profile: GameProfile,
        adapterID: String,
        adapterName: String,
        entries: [PokemonDataCompatibilityEntry],
        diagnostics: [Diagnostic] = []
    ) {
        self.root = root
        self.profile = profile
        self.adapterID = adapterID
        self.adapterName = adapterName
        self.summary = PokemonDataCompatibilitySummary(entries: entries)
        self.entries = entries
        self.diagnostics = diagnostics
    }
}

public struct PokemonDataCompatibilitySummary: Codable, Equatable {
    public let entryCount: Int
    public let editableCount: Int
    public let readOnlyCount: Int
    public let indexedCount: Int
    public let blockedCount: Int

    public init(entries: [PokemonDataCompatibilityEntry]) {
        self.entryCount = entries.count
        self.editableCount = entries.filter { $0.status == .editable }.count
        self.readOnlyCount = entries.filter { $0.status == .readOnly }.count
        self.indexedCount = entries.filter { $0.status == .indexed }.count
        self.blockedCount = entries.filter { $0.status == .blocked }.count
    }
}

public struct PokemonDataCompatibilityEntry: Codable, Equatable, Identifiable {
    public var id: String { surface.rawValue }

    public let surface: PokemonDataCompatibilitySurface
    public let status: PokemonDataCompatibilityStatus
    public let adapterID: String
    public let adapterName: String
    public let profile: GameProfile
    public let sourcePath: String?
    public let tableSymbol: String?
    public let indexedCount: Int
    public let editableCount: Int
    public let readOnlyCount: Int
    public let unsupportedFields: [String]
    public let blockedReason: String?
    public let recommendedFutureRow: String?
    public let diagnostics: [Diagnostic]

    public init(
        surface: PokemonDataCompatibilitySurface,
        status: PokemonDataCompatibilityStatus,
        adapterID: String,
        adapterName: String,
        profile: GameProfile,
        sourcePath: String? = nil,
        tableSymbol: String? = nil,
        indexedCount: Int = 0,
        editableCount: Int = 0,
        readOnlyCount: Int = 0,
        unsupportedFields: [String] = [],
        blockedReason: String? = nil,
        recommendedFutureRow: String? = nil,
        diagnostics: [Diagnostic] = []
    ) {
        self.surface = surface
        self.status = status
        self.adapterID = adapterID
        self.adapterName = adapterName
        self.profile = profile
        self.sourcePath = sourcePath
        self.tableSymbol = tableSymbol
        self.indexedCount = indexedCount
        self.editableCount = editableCount
        self.readOnlyCount = readOnlyCount
        self.unsupportedFields = unsupportedFields
        self.blockedReason = blockedReason
        self.recommendedFutureRow = recommendedFutureRow
        self.diagnostics = diagnostics
    }
}

public enum PokemonDataCompatibilityReportBuilder {
    public static func build(path: String, fileManager: FileManager = .default) throws -> PokemonDataCompatibilityReport {
        try build(index: GameAdapterRegistry.index(path: path, fileManager: fileManager), fileManager: fileManager)
    }

    public static func build(
        index: ProjectIndex,
        sourceIndex providedSourceIndex: ProjectSourceIndex? = nil,
        fileManager: FileManager = .default
    ) throws -> PokemonDataCompatibilityReport {
        let sourceIndex = try providedSourceIndex ?? ProjectSourceIndexLoader.load(from: index, fileManager: fileManager)
        let speciesCatalog = try? ProjectSpeciesCatalogBuilder.build(index: index, fileManager: fileManager)
        let moveCatalog = try? ProjectMoveCatalogBuilder.build(index: index, sourceIndex: sourceIndex, fileManager: fileManager)
        let itemCatalog = try? ProjectItemCatalogBuilder.build(index: index, sourceIndex: sourceIndex, fileManager: fileManager)
        let assetCatalog = GenIIIAssetCatalogBuilder.build(index: index, sourceIndex: sourceIndex)

        var entries: [PokemonDataCompatibilityEntry] = []
        entries.append(speciesEntry(index: index, catalog: speciesCatalog, sourceIndex: sourceIndex))
        entries.append(movesEntry(index: index, catalog: moveCatalog, sourceIndex: sourceIndex))
        entries.append(itemsEntry(index: index, catalog: itemCatalog, sourceIndex: sourceIndex))
        entries.append(learnsetEntry(surface: .levelUpLearnsets, index: index, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex))
        entries.append(learnsetEntry(surface: .tmhmLearnsets, index: index, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex))
        entries.append(learnsetEntry(surface: .eggMoves, index: index, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex))
        entries.append(evolutionsEntry(index: index, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex))
        entries.append(pokedexEntry(index: index, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex))
        entries.append(assetsEntry(index: index, assetCatalog: assetCatalog))
        entries.append(criesEntry(index: index, fileManager: fileManager))
        entries.append(formsEntry(index: index, sourceIndex: sourceIndex, fileManager: fileManager))

        let diagnostics = index.diagnostics
            + sourceIndex.diagnostics
            + (speciesCatalog?.diagnostics ?? [])
            + (moveCatalog?.diagnostics ?? [])
            + (itemCatalog?.diagnostics ?? [])
            + assetCatalog.diagnostics
            + entries.flatMap(\.diagnostics)

        return PokemonDataCompatibilityReport(
            root: index.root,
            profile: index.profile,
            adapterID: index.adapterID,
            adapterName: index.adapterName,
            entries: entries,
            diagnostics: diagnostics
        )
    }

    private static func speciesEntry(
        index: ProjectIndex,
        catalog: ProjectSpeciesCatalog?,
        sourceIndex: ProjectSourceIndex
    ) -> PokemonDataCompatibilityEntry {
        let descriptor = descriptor(for: .species, profile: index.profile)
        let indexed = catalog?.speciesCount ?? recordCount(.pokemon, in: sourceIndex)
        let editable = catalog?.species.filter(\.isEditable).count ?? 0
        return entry(
            surface: .species,
            index: index,
            descriptor: descriptor,
            indexedCount: indexed,
            editableCount: editable,
            unsupportedFields: speciesUnsupportedFields(profile: index.profile),
            diagnostics: catalog?.diagnostics ?? []
        )
    }

    private static func movesEntry(
        index: ProjectIndex,
        catalog: ProjectMoveCatalog?,
        sourceIndex: ProjectSourceIndex
    ) -> PokemonDataCompatibilityEntry {
        let descriptor = descriptor(for: .moves, profile: index.profile)
        let indexed = catalog?.summary.moveCount ?? recordCount(.moves, in: sourceIndex)
        let editable = catalog?.moves.filter(\.isEditable).count ?? 0
        return entry(
            surface: .moves,
            index: index,
            descriptor: descriptor,
            indexedCount: indexed,
            editableCount: editable,
            unsupportedFields: movesUnsupportedFields(profile: index.profile),
            diagnostics: catalog?.diagnostics ?? []
        )
    }

    private static func itemsEntry(
        index: ProjectIndex,
        catalog: ProjectItemCatalog?,
        sourceIndex: ProjectSourceIndex
    ) -> PokemonDataCompatibilityEntry {
        let descriptor = descriptor(for: .items, profile: index.profile)
        let sourceIndexed = recordCount(.items, in: sourceIndex)
        let indexed = max(catalog?.itemCount ?? 0, sourceIndexed)
        let editable = catalog?.items.filter { $0.isEditable || $0.isDescriptionEditable }.count ?? 0
        return entry(
            surface: .items,
            index: index,
            descriptor: descriptor,
            indexedCount: indexed,
            editableCount: editable,
            unsupportedFields: itemsUnsupportedFields(profile: index.profile),
            diagnostics: catalog?.diagnostics ?? []
        )
    }

    private static func learnsetEntry(
        surface: PokemonDataCompatibilitySurface,
        index: ProjectIndex,
        speciesCatalog: ProjectSpeciesCatalog?,
        sourceIndex: ProjectSourceIndex
    ) -> PokemonDataCompatibilityEntry {
        let descriptor = descriptor(for: surface, profile: index.profile)
        let indexed: Int
        switch surface {
        case .levelUpLearnsets:
            indexed = speciesCatalog?.species.filter { !$0.learnsets.levelUp.isEmpty }.count
                ?? learnsetRecordCount(in: sourceIndex, matching: ["level_up", "learnset"])
        case .tmhmLearnsets:
            indexed = speciesCatalog?.species.filter { !$0.learnsets.tmhm.isEmpty }.count
                ?? learnsetRecordCount(in: sourceIndex, matching: ["tmhm"])
        case .eggMoves:
            indexed = speciesCatalog?.species.filter { !$0.learnsets.egg.isEmpty }.count
                ?? learnsetRecordCount(in: sourceIndex, matching: ["egg"])
        default:
            indexed = 0
        }
        let editable = supportsSpeciesEditing(index.profile) && indexed > 0 ? indexed : 0
        return entry(
            surface: surface,
            index: index,
            descriptor: descriptor,
            indexedCount: indexed,
            editableCount: editable,
            unsupportedFields: learnsetUnsupportedFields(surface: surface, profile: index.profile),
            recommendedFutureRow: editable > 0 ? nil : "PHS-T57"
        )
    }

    private static func evolutionsEntry(
        index: ProjectIndex,
        speciesCatalog: ProjectSpeciesCatalog?,
        sourceIndex: ProjectSourceIndex
    ) -> PokemonDataCompatibilityEntry {
        let descriptor = descriptor(for: .evolutions, profile: index.profile)
        let indexed = speciesCatalog?.species.filter { !$0.evolutions.isEmpty }.count
            ?? recordCount(.evolutions, in: sourceIndex)
        return entry(
            surface: .evolutions,
            index: index,
            descriptor: descriptor,
            indexedCount: indexed,
            editableCount: 0,
            unsupportedFields: ["evolution method edits", "target species edits", "parameter edits", "evolution row insertion/reordering"],
            recommendedFutureRow: "PHS-T57"
        )
    }

    private static func pokedexEntry(
        index: ProjectIndex,
        speciesCatalog: ProjectSpeciesCatalog?,
        sourceIndex: ProjectSourceIndex
    ) -> PokemonDataCompatibilityEntry {
        let descriptor = descriptor(for: .pokedex, profile: index.profile)
        let indexed = speciesCatalog?.species.filter { $0.pokedex != nil }.count
            ?? recordCount(.pokedex, in: sourceIndex)
        return entry(
            surface: .pokedex,
            index: index,
            descriptor: descriptor,
            indexedCount: indexed,
            editableCount: 0,
            unsupportedFields: ["category text edits", "height/weight edits", "description text rewrites", "national dex identity changes"],
            recommendedFutureRow: "PHS-T57"
        )
    }

    private static func assetsEntry(index: ProjectIndex, assetCatalog: GenIIIAssetCatalog) -> PokemonDataCompatibilityEntry {
        entry(
            surface: .assets,
            index: index,
            descriptor: descriptor(for: .assets, profile: index.profile),
            indexedCount: assetCatalog.assetCount,
            editableCount: 0,
            unsupportedFields: ["sprite import", "palette conversion", "icon/footprint rewrites", "cry asset sync"],
            diagnostics: assetCatalog.diagnostics
        )
    }

    private static func criesEntry(
        index: ProjectIndex,
        fileManager: FileManager
    ) -> PokemonDataCompatibilityEntry {
        let descriptor = descriptor(for: .cries, profile: index.profile)
        let count = existingPaths(["sound/direct_sound_samples/cries", "sound/songs/mus_cry"], root: index.root.path, fileManager: fileManager).count
        return entry(
            surface: .cries,
            index: index,
            descriptor: descriptor,
            indexedCount: count,
            editableCount: 0,
            unsupportedFields: ["cry table indexing", "audio import/export", "sample conversion"],
            blockedReason: count == 0 ? "No known cry source path was detected for this fixture/profile." : nil
        )
    }

    private static func formsEntry(
        index: ProjectIndex,
        sourceIndex: ProjectSourceIndex,
        fileManager: FileManager
    ) -> PokemonDataCompatibilityEntry {
        let descriptor = descriptor(for: .forms, profile: index.profile)
        let count = recordCount(.pokemon, in: sourceIndex, pathContains: "species_info/")
            + existingPaths(["src/data/pokemon/form_change_tables.h"], root: index.root.path, fileManager: fileManager).count
        return entry(
            surface: .forms,
            index: index,
            descriptor: descriptor,
            indexedCount: count,
            editableCount: 0,
            unsupportedFields: ["form table editing", "form graphics sync", "generated family supplement apply"],
            blockedReason: count == 0 ? "No form supplement or form change table was detected for this fixture/profile." : nil,
            recommendedFutureRow: "PHS-T57"
        )
    }

    private static func entry(
        surface: PokemonDataCompatibilitySurface,
        index: ProjectIndex,
        descriptor: PokemonDataSurfaceDescriptor?,
        indexedCount: Int,
        editableCount: Int,
        unsupportedFields: [String],
        blockedReason providedBlockedReason: String? = nil,
        recommendedFutureRow providedFutureRow: String? = nil,
        diagnostics: [Diagnostic] = []
    ) -> PokemonDataCompatibilityEntry {
        let readOnlyCount = max(0, indexedCount - editableCount)
        let blockedReason = providedBlockedReason ?? blockedReason(for: surface, profile: index.profile, indexedCount: indexedCount, descriptor: descriptor)
        let status: PokemonDataCompatibilityStatus
        if editableCount > 0 {
            status = .editable
        } else if indexedCount > 0 {
            status = .readOnly
        } else if blockedReason != nil {
            status = .blocked
        } else {
            status = .indexed
        }
        return PokemonDataCompatibilityEntry(
            surface: surface,
            status: status,
            adapterID: index.adapterID,
            adapterName: index.adapterName,
            profile: index.profile,
            sourcePath: descriptor?.sourcePath,
            tableSymbol: descriptor?.tableSymbol,
            indexedCount: indexedCount,
            editableCount: editableCount,
            readOnlyCount: readOnlyCount,
            unsupportedFields: unsupportedFields,
            blockedReason: blockedReason,
            recommendedFutureRow: providedFutureRow ?? descriptor?.recommendedFutureRow,
            diagnostics: diagnostics
        )
    }

    private static func blockedReason(
        for surface: PokemonDataCompatibilitySurface,
        profile: GameProfile,
        indexedCount: Int,
        descriptor: PokemonDataSurfaceDescriptor?
    ) -> String? {
        if descriptor == nil {
            return "\(surface.rawValue) compatibility is not mapped for \(profile.rawValue)."
        }
        if indexedCount == 0 {
            return "No indexed \(surface.rawValue) records were found at the expected source path."
        }
        if descriptor?.supportsEditing == false {
            return descriptor?.readOnlyReason
        }
        return nil
    }

    private static func recordCount(_ module: SourceIndexModule, in sourceIndex: ProjectSourceIndex, pathContains: String? = nil) -> Int {
        sourceIndex.records.filter { record in
            record.module == module
                && (pathContains == nil || record.sourceSpan.relativePath.contains(pathContains ?? ""))
        }.count
    }

    private static func learnsetRecordCount(in sourceIndex: ProjectSourceIndex, matching tokens: [String]) -> Int {
        sourceIndex.records.filter { record in
            guard record.module == .learnsets else { return false }
            let path = record.sourceSpan.relativePath.lowercased()
            return tokens.contains { path.contains($0) }
        }.count
    }

    private static func existingPaths(_ paths: [String], root: String, fileManager: FileManager) -> [String] {
        let rootURL = URL(fileURLWithPath: root)
        return paths.filter { fileManager.fileExists(atPath: rootURL.appendingPathComponent($0).path) }
    }
}

private struct PokemonDataSurfaceDescriptor {
    let sourcePath: String
    let tableSymbol: String?
    let supportsEditing: Bool
    let readOnlyReason: String?
    let recommendedFutureRow: String?
}

private func descriptor(for surface: PokemonDataCompatibilitySurface, profile: GameProfile) -> PokemonDataSurfaceDescriptor? {
    switch surface {
    case .species:
        switch profile {
        case .pokeemerald, .pokefirered:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/pokemon/species_info.h", tableSymbol: "gSpeciesInfo", supportsEditing: true, readOnlyReason: nil, recommendedFutureRow: nil)
        case .pokeruby:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/pokemon/base_stats.h", tableSymbol: "gBaseStats", supportsEditing: false, readOnlyReason: "Ruby/Sapphire species rows are indexed but not applyable yet.", recommendedFutureRow: "PHS-T57")
        case .pokeemeraldExpansion:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/pokemon/species_info.h", tableSymbol: "gSpeciesInfo", supportsEditing: false, readOnlyReason: "Expansion species data includes generated/family supplement shapes that are read-only in this row.", recommendedFutureRow: "PHS-T57")
        default:
            return nil
        }
    case .moves:
        switch profile {
        case .pokeemerald, .pokefirered:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/battle_moves.h", tableSymbol: "gBattleMoves", supportsEditing: true, readOnlyReason: nil, recommendedFutureRow: nil)
        case .pokeruby:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/battle_moves.c", tableSymbol: "gBattleMoves", supportsEditing: false, readOnlyReason: "Ruby/Sapphire move rows are indexed but not applyable yet.", recommendedFutureRow: "PHS-T57")
        case .pokeemeraldExpansion:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/moves_info.h", tableSymbol: "gMovesInfo", supportsEditing: false, readOnlyReason: "Expansion gMovesInfo rows use a separate schema and are read-only in this row.", recommendedFutureRow: "PHS-T57")
        default:
            return nil
        }
    case .items:
        switch profile {
        case .pokeemerald:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/items.h", tableSymbol: "gItems", supportsEditing: true, readOnlyReason: nil, recommendedFutureRow: nil)
        case .pokefirered:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/items.h", tableSymbol: "gItems", supportsEditing: true, readOnlyReason: nil, recommendedFutureRow: "PHS-T57")
        case .pokeruby:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/items_en.h", tableSymbol: "gItems", supportsEditing: false, readOnlyReason: "Ruby/Sapphire positional item rows are read-only until positional rewrites are planned.", recommendedFutureRow: "PHS-T57")
        case .pokeemeraldExpansion:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/items.h", tableSymbol: "gItemsInfo", supportsEditing: false, readOnlyReason: "Expansion ItemInfo rows are indexed but blocked from apply until the schema is modeled.", recommendedFutureRow: "PHS-T57")
        default:
            return nil
        }
    case .levelUpLearnsets:
        switch profile {
        case .pokeemerald, .pokefirered, .pokeruby:
            let supportsEditing = supportsSpeciesEditing(profile)
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/pokemon/level_up_learnsets.h", tableSymbol: "gLevelUpLearnsets", supportsEditing: supportsEditing, readOnlyReason: "Learnset edits are currently tied to classic species mutation plans.", recommendedFutureRow: supportsEditing ? nil : "PHS-T57")
        case .pokeemeraldExpansion:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/pokemon/level_up_learnsets", tableSymbol: nil, supportsEditing: false, readOnlyReason: "Expansion directory learnsets are indexed but read-only until generated/family layouts are modeled.", recommendedFutureRow: "PHS-T57")
        default:
            return nil
        }
    case .tmhmLearnsets:
        return pokemonTableDescriptor(profile: profile, path: "src/data/pokemon/tmhm_learnsets.h", emeraldTable: "gTMHMLearnsets", fireRedTable: "sTMHMLearnsets", rubyTable: "gTMHMLearnsets", expansionTable: "sTMHMLearnsets", supportsEditing: supportsSpeciesEditing(profile), readOnlyReason: "TM/HM compatibility edits are indexed but remain a dedicated follow-up surface.", futureRow: "PHS-T57")
    case .eggMoves:
        return pokemonTableDescriptor(profile: profile, path: "src/data/pokemon/egg_moves.h", emeraldTable: "gEggMoves", fireRedTable: "gEggMoves", rubyTable: "gEggMoves", expansionTable: "gEggMoves", supportsEditing: supportsSpeciesEditing(profile), readOnlyReason: "Egg move edits are indexed but remain a dedicated follow-up surface.", futureRow: "PHS-T57")
    case .evolutions:
        return pokemonTableDescriptor(profile: profile, path: "src/data/pokemon/evolution.h", emeraldTable: "gEvolutionTable", fireRedTable: "gEvolutionTable", rubyTable: "gEvolutionTable", expansionTable: "gEvolutionTable", supportsEditing: false, readOnlyReason: "Evolution rows are indexed for navigation only in this row.", futureRow: "PHS-T57")
    case .pokedex:
        switch profile {
        case .pokeruby:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/pokedex_entries_en.h", tableSymbol: "gPokedexEntries", supportsEditing: false, readOnlyReason: "Pokedex rows are indexed for navigation only in this row.", recommendedFutureRow: "PHS-T57")
        default:
            return pokemonTableDescriptor(profile: profile, path: "src/data/pokemon/pokedex_entries.h", emeraldTable: "gPokedexEntries", fireRedTable: "gPokedexEntries", rubyTable: "gPokedexEntries", expansionTable: "gPokedexEntries", supportsEditing: false, readOnlyReason: "Pokedex rows are indexed for navigation only in this row.", futureRow: "PHS-T57")
        }
    case .assets:
        switch profile {
        case .pokeemerald, .pokefirered, .pokeruby, .pokeemeraldExpansion:
            return PokemonDataSurfaceDescriptor(sourcePath: "graphics/pokemon", tableSymbol: nil, supportsEditing: false, readOnlyReason: "Pokemon assets are indexed as read-only source links.", recommendedFutureRow: nil)
        default:
            return nil
        }
    case .cries:
        switch profile {
        case .pokeemerald, .pokefirered, .pokeruby, .pokeemeraldExpansion:
            return PokemonDataSurfaceDescriptor(sourcePath: "sound/direct_sound_samples/cries", tableSymbol: nil, supportsEditing: false, readOnlyReason: "Cry assets are not structurally indexed or editable yet.", recommendedFutureRow: nil)
        default:
            return nil
        }
    case .forms:
        switch profile {
        case .pokeemeraldExpansion:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/pokemon/form_change_tables.h", tableSymbol: "sFormChangeTable", supportsEditing: false, readOnlyReason: "Expansion form data is detected when present but not editable yet.", recommendedFutureRow: "PHS-T57")
        case .pokeemerald, .pokefirered, .pokeruby:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/pokemon/species_info.h", tableSymbol: nil, supportsEditing: false, readOnlyReason: "Classic form-specific tables are not present in the indexed fixture/profile.", recommendedFutureRow: "PHS-T57")
        default:
            return nil
        }
    }
}

private func pokemonTableDescriptor(
    profile: GameProfile,
    path: String,
    emeraldTable: String,
    fireRedTable: String,
    rubyTable: String,
    expansionTable: String,
    supportsEditing: Bool,
    readOnlyReason: String,
    futureRow: String
) -> PokemonDataSurfaceDescriptor? {
    switch profile {
    case .pokeemerald:
        return PokemonDataSurfaceDescriptor(sourcePath: path, tableSymbol: emeraldTable, supportsEditing: supportsEditing, readOnlyReason: supportsEditing ? nil : readOnlyReason, recommendedFutureRow: supportsEditing ? nil : futureRow)
    case .pokefirered:
        return PokemonDataSurfaceDescriptor(sourcePath: path, tableSymbol: fireRedTable, supportsEditing: supportsEditing, readOnlyReason: supportsEditing ? nil : readOnlyReason, recommendedFutureRow: supportsEditing ? nil : futureRow)
    case .pokeruby:
        return PokemonDataSurfaceDescriptor(sourcePath: path, tableSymbol: rubyTable, supportsEditing: false, readOnlyReason: readOnlyReason, recommendedFutureRow: futureRow)
    case .pokeemeraldExpansion:
        return PokemonDataSurfaceDescriptor(sourcePath: path, tableSymbol: expansionTable, supportsEditing: false, readOnlyReason: readOnlyReason, recommendedFutureRow: futureRow)
    default:
        return nil
    }
}

private func supportsSpeciesEditing(_ profile: GameProfile) -> Bool {
    profile == .pokeemerald || profile == .pokefirered
}

private func speciesUnsupportedFields(profile: GameProfile) -> [String] {
    var fields = ["species identity changes", "new/reordered species constants", "pokedex text rewrites", "asset/cries/form rewrites"]
    if profile == .pokeruby {
        fields.append("Ruby/Sapphire base_stats positional apply")
    }
    if profile == .pokeemeraldExpansion {
        fields.append("Expansion generated family supplement apply")
    }
    return fields
}

private func movesUnsupportedFields(profile: GameProfile) -> [String] {
    var fields = ["new/reordered move constants", "TM/HM/tutor compatibility edits", "contest data", "description text rewrites"]
    if profile == .pokeemeraldExpansion {
        fields.append("Expansion gMovesInfo schema apply")
    }
    return fields
}

private func itemsUnsupportedFields(profile: GameProfile) -> [String] {
    switch profile {
    case .pokeemerald:
        return ["item identity changes", "new/reordered item constants", "TM/HM item compatibility edits"]
    case .pokefirered:
        return ["FireRed row-field rewrites", "item identity changes"]
    case .pokeruby:
        return ["Ruby/Sapphire positional gItems rewrites", "item identity changes", "description text rewrites"]
    case .pokeemeraldExpansion:
        return ["Expansion ItemInfo rewrites", "item identity changes", "description text rewrites"]
    default:
        return ["item source apply"]
    }
}

private func learnsetUnsupportedFields(surface: PokemonDataCompatibilitySurface, profile: GameProfile) -> [String] {
    var fields: [String]
    switch surface {
    case .levelUpLearnsets:
        fields = ["learnset symbol renames", "shared learnset extraction", "generated learnset directory apply"]
    case .tmhmLearnsets:
        fields = ["TM/HM item mapping edits", "machine constant creation", "compatibility matrix bulk edits"]
    case .eggMoves:
        fields = ["egg move family reshaping", "cross-species egg move validation"]
    default:
        fields = []
    }
    if profile == .pokeemeraldExpansion {
        fields.append("Expansion generated learnable JSON apply")
    }
    return fields
}
