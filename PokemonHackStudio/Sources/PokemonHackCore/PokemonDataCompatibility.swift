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
    case tutorLearnsets
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

public enum GBACryAudioMutationPlanStatus: String, Codable, Equatable, CaseIterable {
    case previewOnly
    case blocked
}

public struct GBACryAudioSourceFile: Codable, Equatable {
    public let path: String
    public let kind: String
    public let sizeBytes: UInt64
    public let sha1: String

    public init(path: String, kind: String, sizeBytes: UInt64, sha1: String) {
        self.path = path
        self.kind = kind
        self.sizeBytes = sizeBytes
        self.sha1 = sha1
    }
}

public struct GBACryAudioMutationPlan: Codable, Equatable {
    public let status: GBACryAudioMutationPlanStatus
    public let summary: String
    public let sourceFiles: [GBACryAudioSourceFile]
    public let plannedChanges: [String]
    public let blockedActions: [String]
    public let diagnostics: [Diagnostic]

    public init(
        status: GBACryAudioMutationPlanStatus,
        summary: String,
        sourceFiles: [GBACryAudioSourceFile],
        plannedChanges: [String],
        blockedActions: [String],
        diagnostics: [Diagnostic]
    ) {
        self.status = status
        self.summary = summary
        self.sourceFiles = sourceFiles
        self.plannedChanges = plannedChanges
        self.blockedActions = blockedActions
        self.diagnostics = diagnostics
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
    public let cryAudioPlan: GBACryAudioMutationPlan?
    public let sourceTables: [PokemonDataCompatibilitySourceTable]?

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
        diagnostics: [Diagnostic] = [],
        cryAudioPlan: GBACryAudioMutationPlan? = nil,
        sourceTables: [PokemonDataCompatibilitySourceTable]? = nil
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
        self.cryAudioPlan = cryAudioPlan
        self.sourceTables = sourceTables
    }
}

public struct PokemonDataCompatibilitySourceTable: Codable, Equatable {
    public let path: String
    public let tableSymbol: String?
    public let indexedCount: Int
    public let status: PokemonDataCompatibilityStatus
    public let note: String?

    public init(
        path: String,
        tableSymbol: String?,
        indexedCount: Int,
        status: PokemonDataCompatibilityStatus,
        note: String? = nil
    ) {
        self.path = path
        self.tableSymbol = tableSymbol
        self.indexedCount = indexedCount
        self.status = status
        self.note = note
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
        entries.append(learnsetEntry(surface: .tutorLearnsets, index: index, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex))
        entries.append(evolutionsEntry(index: index, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex))
        entries.append(pokedexEntry(index: index, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex))
        entries.append(assetsEntry(index: index, assetCatalog: assetCatalog))
        entries.append(criesEntry(index: index, fileManager: fileManager))
        entries.append(formsEntry(index: index, sourceIndex: sourceIndex))

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
            diagnostics: catalog?.diagnostics ?? [],
            sourceTables: moveSourceTables(
                profile: index.profile,
                indexedCount: indexed,
                editableCount: editable
            )
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
            diagnostics: catalog?.diagnostics ?? [],
            sourceTables: itemSourceTables(
                profile: index.profile,
                indexedCount: indexed,
                editableCount: editable
            )
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
        case .tutorLearnsets:
            indexed = speciesCatalog?.species.filter { !$0.learnsets.tutor.isEmpty }.count
                ?? learnsetRecordCount(in: sourceIndex, matching: ["tutor"])
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
        let editable = supportsSpeciesEditing(index.profile) && indexed > 0 ? indexed : 0
        return entry(
            surface: .evolutions,
            index: index,
            descriptor: descriptor,
            indexedCount: indexed,
            editableCount: editable,
            unsupportedFields: editable > 0 ? ["missing evolution row insertion"] : ["evolution method edits", "target species edits", "parameter edits", "evolution row insertion/reordering"],
            recommendedFutureRow: editable > 0 ? nil : "PHS-T57"
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
        let editable = supportsSpeciesEditing(index.profile) && indexed > 0 ? indexed : 0
        return entry(
            surface: .pokedex,
            index: index,
            descriptor: descriptor,
            indexedCount: indexed,
            editableCount: editable,
            unsupportedFields: editable > 0 ? ["national dex identity changes", "missing Pokedex row insertion"] : ["category text edits", "height/weight edits", "description text rewrites", "national dex identity changes"],
            recommendedFutureRow: editable > 0 ? nil : "PHS-T57"
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
        let plan = cryAudioPlan(index: index, fileManager: fileManager)
        let count = plan.sourceFiles.count
        return entry(
            surface: .cries,
            index: index,
            descriptor: descriptor,
            indexedCount: count,
            editableCount: 0,
            unsupportedFields: ["audio conversion", "generated audio output writes", "ROM cry table rewrites", "playback", "mutation apply"],
            blockedReason: count == 0 ? "No explicit local GBA cry source files were detected for this fixture/profile." : nil,
            recommendedFutureRow: nil,
            diagnostics: plan.diagnostics,
            cryAudioPlan: plan
        )
    }

    private static func formsEntry(
        index: ProjectIndex,
        sourceIndex: ProjectSourceIndex
    ) -> PokemonDataCompatibilityEntry {
        let descriptor = descriptor(for: .forms, profile: index.profile)
        let formRecords = sourceIndex.records.filter(isFormCompatibilityRecord)
        let sourceTables = formSourceTables(in: sourceIndex)
        let count = formRecords.count
        return entry(
            surface: .forms,
            index: index,
            descriptor: descriptor,
            indexedCount: count,
            editableCount: 0,
            unsupportedFields: ["form editing", "form table mutation/apply", "form graphics sync", "generated family supplement apply", "binary-only form table writes", "ROM/export/source writes"],
            blockedReason: count == 0 ? "No form table or species supplement source graph was detected for this fixture/profile." : nil,
            recommendedFutureRow: "PHS-T57E",
            diagnostics: formDiagnostics(records: formRecords),
            sourceTables: sourceTables
        )
    }

    private static func formSourceTables(in sourceIndex: ProjectSourceIndex) -> [PokemonDataCompatibilitySourceTable] {
        let formSpeciesPath = "src/data/pokemon/form_species_tables.h"
        let formChangePath = "src/data/pokemon/form_change_tables.h"
        let speciesInfoRoot = "src/data/pokemon/species_info/"
        let formSpeciesCount = formRecords(in: sourceIndex, path: formSpeciesPath).count
        let formChangeCount = formRecords(in: sourceIndex, path: formChangePath).count
        let speciesInfoCount = sourceIndex.records.filter { record in
            record.module == .pokemon
                && isFormCompatibilityRecord(record)
                && record.tags.contains("species-info")
                && record.sourceSpan.relativePath.hasPrefix(speciesInfoRoot)
        }.count
        return [
            PokemonDataCompatibilitySourceTable(
                path: formSpeciesPath,
                tableSymbol: "s*FormSpeciesIdTable",
                indexedCount: formSpeciesCount,
                status: formSpeciesCount > 0 ? .readOnly : .blocked,
                note: "Read-only form species table metadata for PHS-T57E."
            ),
            PokemonDataCompatibilitySourceTable(
                path: formChangePath,
                tableSymbol: "s*FormChangeTable",
                indexedCount: formChangeCount,
                status: formChangeCount > 0 ? .readOnly : .blocked,
                note: "Read-only form change table metadata for PHS-T57E."
            ),
            PokemonDataCompatibilitySourceTable(
                path: speciesInfoRoot,
                tableSymbol: "formSpeciesIdTable/formChangeTable",
                indexedCount: speciesInfoCount,
                status: speciesInfoCount > 0 ? .readOnly : .blocked,
                note: "Read-only species-info form links; generated family supplement apply stays blocked."
            )
        ]
    }

    private static func itemSourceTables(
        profile: GameProfile,
        indexedCount: Int,
        editableCount: Int
    ) -> [PokemonDataCompatibilitySourceTable]? {
        guard profile == .pokeemeraldExpansion else { return nil }
        let sourceStatus: PokemonDataCompatibilityStatus
        if editableCount > 0 {
            sourceStatus = .editable
        } else if indexedCount > 0 {
            sourceStatus = .readOnly
        } else {
            sourceStatus = .blocked
        }
        return [
            PokemonDataCompatibilitySourceTable(
                path: "src/data/items.h",
                tableSymbol: "gItemsInfo",
                indexedCount: indexedCount,
                status: sourceStatus,
                note: "Local source-backed Expansion ItemInfo rows and simple inline COMPOUND_STRING descriptions use the item mutation-plan gate."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "include/config/item.h",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Config-gated item behavior remains blocked; this slice does not rewrite configuration rows."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "generated",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Generated item outputs remain blocked and must be refreshed outside this mutation plan."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "references/pokeemerald-expansion/src/data/items.h",
                tableSymbol: "gItemsInfo",
                indexedCount: 0,
                status: .blocked,
                note: "Reference Expansion clones remain read-only research inputs."
            )
        ]
    }

    private static func moveSourceTables(
        profile: GameProfile,
        indexedCount: Int,
        editableCount: Int
    ) -> [PokemonDataCompatibilitySourceTable]? {
        guard profile == .pokeemeraldExpansion else { return nil }
        let sourceStatus: PokemonDataCompatibilityStatus
        if editableCount > 0 {
            sourceStatus = .editable
        } else if indexedCount > 0 {
            sourceStatus = .readOnly
        } else {
            sourceStatus = .blocked
        }
        return [
            PokemonDataCompatibilitySourceTable(
                path: "src/data/moves_info.h",
                tableSymbol: "gMovesInfo",
                indexedCount: indexedCount,
                status: sourceStatus,
                note: "Local source-backed Expansion MoveInfo rows use the move mutation-plan gate for simple core fields."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "include/constants/moves.h",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Move constants, identity changes, and row creation/reordering remain blocked."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "src/data/text/move_descriptions.h",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Move description text remains read-only for this slice."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "src/data/contest_moves.h",
                tableSymbol: "gContestMoves",
                indexedCount: 0,
                status: .blocked,
                note: "Contest data remains read-only for this slice."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "src/data/pokemon/tmhm_learnsets.h",
                tableSymbol: "sTMHMLearnsets",
                indexedCount: 0,
                status: .blocked,
                note: "TM/HM compatibility edits remain blocked from move row plans."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "src/data/pokemon/tutor_learnsets.h",
                tableSymbol: "gTutorLearnsets",
                indexedCount: 0,
                status: .blocked,
                note: "Tutor compatibility edits remain blocked from move row plans."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "generated",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Generated move outputs remain blocked and must be refreshed outside this mutation plan."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "references/pokeemerald-expansion/src/data/moves_info.h",
                tableSymbol: "gMovesInfo",
                indexedCount: 0,
                status: .blocked,
                note: "Reference Expansion clones remain read-only research inputs."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "ROM output",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Binary ROM writes remain blocked."
            )
        ]
    }

    private static func formRecords(in sourceIndex: ProjectSourceIndex, path: String) -> [SourceIndexRecord] {
        sourceIndex.records.filter { record in
            record.module == .pokemon
                && isFormCompatibilityRecord(record)
                && record.sourceSpan.relativePath == path
        }
    }

    private static func isFormCompatibilityRecord(_ record: SourceIndexRecord) -> Bool {
        record.tags.contains("form") && record.tags.contains { tag in
            tag == "form-species-table"
                || tag == "form-change-table"
                || tag == "form-supplement"
        }
    }

    private static func formDiagnostics(records: [SourceIndexRecord]) -> [Diagnostic] {
        guard !records.isEmpty else { return [] }
        return [
            Diagnostic(
                severity: .info,
                code: "GBA_FORMS_SOURCE_GRAPH_DETECTED",
                message: "Detected \(records.count) read-only form source graph record(s); compatibility reports can distinguish form tables and supplements, but mutation workflows remain unavailable.",
                span: records.first?.sourceSpan
            ),
            Diagnostic(
                severity: .warning,
                code: "GBA_FORMS_MUTATION_WORKFLOW_BLOCKED",
                message: "Form editing, table mutation/apply, graphics sync, generated supplement apply, binary-only form table writes, builds, ROM export, and mutation apply remain blocked.",
                span: records.first?.sourceSpan
            )
        ]
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
        diagnostics: [Diagnostic] = [],
        cryAudioPlan: GBACryAudioMutationPlan? = nil,
        sourceTables: [PokemonDataCompatibilitySourceTable]? = nil
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
            diagnostics: diagnostics,
            cryAudioPlan: cryAudioPlan,
            sourceTables: sourceTables
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

    private static func cryAudioPlan(index: ProjectIndex, fileManager: FileManager) -> GBACryAudioMutationPlan {
        let root = URL(fileURLWithPath: index.root.path).standardizedFileURL
        let sourceFiles = cryAudioSourceFiles(root: root, fileManager: fileManager)
        let blockedActions = [
            "Audio conversion",
            "Generated audio output writes",
            "Build artifact writes",
            "Playback",
            "ROM export",
            "Mutation apply"
        ]
        if sourceFiles.isEmpty {
            return GBACryAudioMutationPlan(
                status: .blocked,
                summary: "No mutation plan is available because no explicit local GBA cry source files were found.",
                sourceFiles: [],
                plannedChanges: [],
                blockedActions: blockedActions,
                diagnostics: [
                    Diagnostic(
                        severity: .warning,
                        code: "GBA_CRY_AUDIO_SOURCE_MISSING",
                        message: "GBA cry/audio planning is blocked until an explicit local source file exists under sound/direct_sound_samples/cries or sound/songs/mus_cry*.s.",
                        span: SourceSpan(relativePath: "sound/direct_sound_samples/cries", startLine: 1)
                    )
                ]
            )
        }

        let previewCount = sourceFiles.count == 1 ? "1 source file" : "\(sourceFiles.count) source files"
        return GBACryAudioMutationPlan(
            status: .previewOnly,
            summary: "Detected \(previewCount) for source-backed GBA cry/audio review. Replacement, conversion, generated outputs, playback, ROM export, and mutation apply remain disabled.",
            sourceFiles: sourceFiles,
            plannedChanges: [
                "Review existing cry source provenance, size, and SHA1 before any future edit.",
                "Stage only one-for-one source-file replacement after a dedicated cry import row defines validation.",
                "Keep generated audio artifacts and ROM output unchanged."
            ],
            blockedActions: blockedActions,
            diagnostics: [
                Diagnostic(
                    severity: .info,
                    code: "GBA_CRY_AUDIO_PLAN_PREVIEW_ONLY",
                    message: "Detected explicit local GBA cry/audio source files; this row reports diagnostics and a preview-only mutation plan without writing source, generated audio, or ROM output.",
                    span: SourceSpan(relativePath: sourceFiles[0].path, startLine: 1)
                )
            ]
        )
    }

    private static func cryAudioSourceFiles(root: URL, fileManager: FileManager) -> [GBACryAudioSourceFile] {
        var files: [GBACryAudioSourceFile] = []
        appendCryFiles(
            under: root.appendingPathComponent("sound/direct_sound_samples/cries"),
            root: root,
            kind: "directSoundCrySample",
            fileManager: fileManager,
            into: &files
        )
        appendCrySongFiles(
            under: root.appendingPathComponent("sound/songs"),
            root: root,
            fileManager: fileManager,
            into: &files
        )
        return files.sorted { $0.path < $1.path }
    }

    private static func appendCryFiles(
        under directory: URL,
        root: URL,
        kind: String,
        fileManager: FileManager,
        into files: inout [GBACryAudioSourceFile]
    ) {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory), isDirectory.boolValue else { return }
        let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        )
        while let url = enumerator?.nextObject() as? URL {
            guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey]),
                  values.isDirectory != true
            else {
                continue
            }
            appendCrySourceFile(url: url, root: root, kind: kind, sizeBytes: values.fileSize, into: &files)
        }
    }

    private static func appendCrySongFiles(
        under directory: URL,
        root: URL,
        fileManager: FileManager,
        into files: inout [GBACryAudioSourceFile]
    ) {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory), isDirectory.boolValue else { return }
        let urls = (try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        for url in urls {
            let name = url.lastPathComponent.lowercased()
            guard name.hasPrefix("mus_cry"), ["s", "inc"].contains(url.pathExtension.lowercased()) else { continue }
            let values = try? url.resourceValues(forKeys: [.fileSizeKey])
            appendCrySourceFile(url: url, root: root, kind: "crySongAssembly", sizeBytes: values?.fileSize, into: &files)
        }
    }

    private static func appendCrySourceFile(
        url: URL,
        root: URL,
        kind: String,
        sizeBytes: Int?,
        into files: inout [GBACryAudioSourceFile]
    ) {
        guard let data = try? Data(contentsOf: url) else { return }
        files.append(
            GBACryAudioSourceFile(
                path: relativePath(for: url, root: root),
                kind: kind,
                sizeBytes: UInt64(sizeBytes ?? data.count),
                sha1: pokemonHackSHA1Hex(data)
            )
        )
    }

    private static func relativePath(for url: URL, root: URL) -> String {
        let standardizedRoot = root.standardizedFileURL.path
        let standardizedPath = url.standardizedFileURL.path
        guard standardizedPath.hasPrefix(standardizedRoot + "/") else { return url.lastPathComponent }
        return String(standardizedPath.dropFirst(standardizedRoot.count + 1))
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
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/moves_info.h", tableSymbol: "gMovesInfo", supportsEditing: true, readOnlyReason: nil, recommendedFutureRow: nil)
        default:
            return nil
        }
    case .items:
        switch profile {
        case .pokeemerald:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/items.h", tableSymbol: "gItems", supportsEditing: true, readOnlyReason: nil, recommendedFutureRow: nil)
        case .pokefirered:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/items.h", tableSymbol: "gItems", supportsEditing: true, readOnlyReason: nil, recommendedFutureRow: nil)
        case .pokeruby:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/items_en.h", tableSymbol: "gItems", supportsEditing: true, readOnlyReason: nil, recommendedFutureRow: nil)
        case .pokeemeraldExpansion:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/items.h", tableSymbol: "gItemsInfo", supportsEditing: true, readOnlyReason: nil, recommendedFutureRow: nil)
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
        return pokemonTableDescriptor(profile: profile, path: "src/data/pokemon/tmhm_learnsets.h", emeraldTable: "gTMHMLearnsets", fireRedTable: "sTMHMLearnsets", rubyTable: "gTMHMLearnsets", expansionTable: "sTMHMLearnsets", supportsEditing: supportsSpeciesEditing(profile))
    case .eggMoves:
        return pokemonTableDescriptor(profile: profile, path: "src/data/pokemon/egg_moves.h", emeraldTable: "gEggMoves", fireRedTable: "gEggMoves", rubyTable: "gEggMoves", expansionTable: "gEggMoves", supportsEditing: supportsSpeciesEditing(profile))
    case .evolutions:
        return pokemonTableDescriptor(profile: profile, path: "src/data/pokemon/evolution.h", emeraldTable: "gEvolutionTable", fireRedTable: "gEvolutionTable", rubyTable: "gEvolutionTable", expansionTable: "gEvolutionTable", supportsEditing: supportsSpeciesEditing(profile))
    case .pokedex:
        switch profile {
        case .pokeruby:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/pokedex_entries_en.h", tableSymbol: "gPokedexEntries", supportsEditing: false, readOnlyReason: "Pokedex rows are indexed for navigation only in this row.", recommendedFutureRow: "PHS-T57")
        default:
            return pokemonTableDescriptor(profile: profile, path: "src/data/pokemon/pokedex_entries.h", emeraldTable: "gPokedexEntries", fireRedTable: "gPokedexEntries", rubyTable: "gPokedexEntries", expansionTable: "gPokedexEntries", supportsEditing: supportsSpeciesEditing(profile))
        }
    case .tutorLearnsets:
        return pokemonTableDescriptor(profile: profile, path: "src/data/pokemon/tutor_learnsets.h", emeraldTable: "gTutorLearnsets", fireRedTable: "gTutorLearnsets", rubyTable: nil, expansionTable: "gTutorLearnsets", supportsEditing: supportsSpeciesEditing(profile))
    case .assets:
        switch profile {
        case .pokeemerald, .pokefirered, .pokeruby, .pokeemeraldExpansion:
            return PokemonDataSurfaceDescriptor(sourcePath: "graphics/pokemon", tableSymbol: nil, supportsEditing: false, readOnlyReason: "Pokemon assets are indexed as read-only source links.", recommendedFutureRow: "PHS-T57")
        default:
            return nil
        }
    case .cries:
        switch profile {
        case .pokeemerald, .pokefirered, .pokeruby, .pokeemeraldExpansion:
            return PokemonDataSurfaceDescriptor(sourcePath: "sound/direct_sound_samples/cries", tableSymbol: nil, supportsEditing: true, readOnlyReason: nil, recommendedFutureRow: nil)
        default:
            return nil
        }
    case .forms:
        switch profile {
        case .pokeemeraldExpansion:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/pokemon/form_species_tables.h", tableSymbol: "FormSpeciesIdTable/FormChangeTable", supportsEditing: false, readOnlyReason: "Expansion form tables and species supplements are detected for diagnostics only; form mutation workflows are not editable yet.", recommendedFutureRow: "PHS-T57E")
        case .pokeemerald, .pokefirered, .pokeruby:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/pokemon/form_species_tables.h", tableSymbol: "FormSpeciesIdTable/FormChangeTable", supportsEditing: false, readOnlyReason: "Classic form tables are detected for diagnostics only when present; form mutation workflows are not editable yet.", recommendedFutureRow: "PHS-T57E")
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
    rubyTable: String? = nil,
    expansionTable: String,
    supportsEditing: Bool,
    readOnlyReason: String? = nil,
    futureRow: String? = nil
) -> PokemonDataSurfaceDescriptor? {
    switch profile {
    case .pokeemerald:
        return PokemonDataSurfaceDescriptor(sourcePath: path, tableSymbol: emeraldTable, supportsEditing: supportsEditing, readOnlyReason: supportsEditing ? nil : readOnlyReason, recommendedFutureRow: supportsEditing ? nil : futureRow)
    case .pokefirered:
        return PokemonDataSurfaceDescriptor(sourcePath: path, tableSymbol: fireRedTable, supportsEditing: supportsEditing, readOnlyReason: supportsEditing ? nil : readOnlyReason, recommendedFutureRow: supportsEditing ? nil : futureRow)
    case .pokeruby:
        guard let rubyTable = rubyTable else { return nil }
        return PokemonDataSurfaceDescriptor(sourcePath: path, tableSymbol: rubyTable, supportsEditing: false, readOnlyReason: readOnlyReason ?? "Surface is not editable for this profile.", recommendedFutureRow: futureRow)
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
    var fields = ["species identity changes", "new/reordered species constants", "asset/cries/form rewrites"]
    if !supportsSpeciesEditing(profile) {
        fields.append("pokedex text rewrites")
    }
    if profile == .pokeruby {
        fields.append("Ruby/Sapphire base_stats positional apply")
    }
    if profile == .pokeemeraldExpansion {
        fields.append("Expansion generated family supplement apply")
    }
    return fields
}

private func movesUnsupportedFields(profile: GameProfile) -> [String] {
    var fields = ["new/reordered move constants", "contest data", "description text rewrites"]
    if !supportsSpeciesEditing(profile) {
        fields.append("TM/HM/tutor compatibility edits")
    }
    if profile == .pokeemeraldExpansion {
        fields.append(contentsOf: [
            "gMovesInfo non-simple flags expressions",
            "generated move output writes",
            "reference-only move source writes",
            "binary ROM move writes",
            "broad Expansion move schema rewrites"
        ])
    }
    return fields
}

private func itemsUnsupportedFields(profile: GameProfile) -> [String] {
    switch profile {
    case .pokeemerald:
        return ["item identity changes", "new/reordered item constants", "TM/HM item compatibility edits"]
    case .pokefirered:
        return ["item identity changes", "new/reordered item constants", "TM/HM item compatibility edits"]
    case .pokeruby:
        return ["item identity changes", "new/reordered item constants", "description text rewrites", "TM/HM item compatibility edits"]
    case .pokeemeraldExpansion:
        return [
            "item identity changes",
            "new/reordered item constants",
            "non-simple/non-COMPOUND_STRING description rewrites",
            "TM/HM item compatibility edits",
            "item effect/icon asset rewrites",
            "include/config/item.h rewrites",
            "generated item output writes",
            "reference-only item source writes",
            "Modern Emerald item writers",
            "binary ROM item writes",
            "broad Expansion item schema rewrites"
        ]
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
        fields = ["TM/HM item mapping edits", "machine constant creation"]
        if !supportsSpeciesEditing(profile) {
            fields.append("compatibility matrix bulk edits")
        }
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
