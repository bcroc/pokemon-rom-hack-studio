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

public enum GBACryAudioReplacementStatus: String, Codable, Equatable, CaseIterable {
    case ready
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

public struct GBACryAudioReplacementGate: Codable, Equatable {
    public let status: PokemonDataCompatibilityStatus
    public let summary: String
    public let targetPaths: [String]
    public let blockedActions: [String]
    public let diagnostics: [Diagnostic]

    public init(
        status: PokemonDataCompatibilityStatus,
        summary: String,
        targetPaths: [String],
        blockedActions: [String],
        diagnostics: [Diagnostic]
    ) {
        self.status = status
        self.summary = summary
        self.targetPaths = targetPaths
        self.blockedActions = blockedActions
        self.diagnostics = diagnostics
    }
}

public struct GBACryAudioReplacementDraft: Codable, Equatable, Identifiable {
    public var id: String { targetPath }

    public let targetPath: String
    public let sourceKind: String
    public let originalSizeBytes: UInt64
    public let originalSHA1: String
    public let replacementSourcePath: String
    public let replacementSizeBytes: UInt64
    public let replacementSHA1: String
    public let status: GBACryAudioReplacementStatus
    public let diagnostics: [Diagnostic]
    public let blockedActions: [String]
    public let data: Data

    public init(
        targetPath: String,
        sourceKind: String,
        originalSizeBytes: UInt64,
        originalSHA1: String,
        replacementSourcePath: String,
        replacementSizeBytes: UInt64,
        replacementSHA1: String,
        status: GBACryAudioReplacementStatus,
        diagnostics: [Diagnostic],
        blockedActions: [String],
        data: Data
    ) {
        self.targetPath = targetPath
        self.sourceKind = sourceKind
        self.originalSizeBytes = originalSizeBytes
        self.originalSHA1 = originalSHA1
        self.replacementSourcePath = replacementSourcePath
        self.replacementSizeBytes = replacementSizeBytes
        self.replacementSHA1 = replacementSHA1
        self.status = status
        self.diagnostics = diagnostics
        self.blockedActions = blockedActions
        self.data = data
    }
}

public enum GBACryAudioSourceFileScanner {
    public static let candidateSourcePaths = [
        "sound/direct_sound_samples/cries/*",
        "sound/songs/mus_cry*.s",
        "sound/songs/mus_cry*.inc"
    ]

    public static func sourceFiles(rootPath: String, fileManager: FileManager = .default) -> [GBACryAudioSourceFile] {
        let root = URL(fileURLWithPath: rootPath).standardizedFileURL
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

public enum GBACryAudioReplacementValidator {
    public static let blockedActions = [
        "Audio conversion",
        "Generated audio output writes",
        "Source generation",
        "Missing source creation",
        "Playback",
        "ROM export",
        "Binary mutation",
        "Reference writes",
        "Broad audio schema rewrites"
    ]

    public static func replacementDraft(
        target: GBACryAudioSourceFile,
        replacementSourcePath: String,
        data: Data
    ) -> GBACryAudioReplacementDraft {
        var diagnostics: [Diagnostic] = []
        let span = SourceSpan(relativePath: target.path, startLine: 1)
        if data.isEmpty {
            diagnostics.append(Diagnostic(
                severity: .error,
                code: "GBA_CRY_AUDIO_REPLACEMENT_EMPTY",
                message: "Cry/audio replacement data is empty for \(target.path).",
                span: span
            ))
        }

        let targetExtension = URL(fileURLWithPath: target.path).pathExtension.lowercased()
        let replacementExtension = URL(fileURLWithPath: replacementSourcePath).pathExtension.lowercased()
        if targetExtension != replacementExtension {
            diagnostics.append(Diagnostic(
                severity: .error,
                code: "GBA_CRY_AUDIO_REPLACEMENT_KIND_MISMATCH",
                message: "Cry/audio replacement for \(target.path) must use the same .\(targetExtension) source kind.",
                span: span
            ))
        }

        if !["directSoundCrySample", "crySongAssembly"].contains(target.kind) {
            diagnostics.append(Diagnostic(
                severity: .error,
                code: "GBA_CRY_AUDIO_REPLACEMENT_KIND_UNSUPPORTED",
                message: "Cry/audio replacement kind is not supported for \(target.path): \(target.kind).",
                span: span
            ))
        }

        let status: GBACryAudioReplacementStatus = diagnostics.contains { $0.severity == .error } ? .blocked : .ready
        return GBACryAudioReplacementDraft(
            targetPath: target.path,
            sourceKind: target.kind,
            originalSizeBytes: target.sizeBytes,
            originalSHA1: target.sha1,
            replacementSourcePath: URL(fileURLWithPath: replacementSourcePath).standardizedFileURL.path,
            replacementSizeBytes: UInt64(data.count),
            replacementSHA1: pokemonHackSHA1Hex(data),
            status: status,
            diagnostics: diagnostics,
            blockedActions: blockedActions,
            data: data
        )
    }
}

public struct GBACryAudioMutationPlan: Codable, Equatable {
    public let status: GBACryAudioMutationPlanStatus
    public let summary: String
    public let candidateSourcePaths: [String]
    public let sourceFiles: [GBACryAudioSourceFile]
    public let replacementConstraints: [String]
    public let blockedReasons: [String]
    public let plannedChanges: [String]
    public let blockedActions: [String]
    public let replacementGate: GBACryAudioReplacementGate?
    public let diagnostics: [Diagnostic]

    public init(
        status: GBACryAudioMutationPlanStatus,
        summary: String,
        candidateSourcePaths: [String],
        sourceFiles: [GBACryAudioSourceFile],
        replacementConstraints: [String],
        blockedReasons: [String],
        plannedChanges: [String],
        blockedActions: [String],
        replacementGate: GBACryAudioReplacementGate? = nil,
        diagnostics: [Diagnostic]
    ) {
        self.status = status
        self.summary = summary
        self.candidateSourcePaths = candidateSourcePaths
        self.sourceFiles = sourceFiles
        self.replacementConstraints = replacementConstraints
        self.blockedReasons = blockedReasons
        self.plannedChanges = plannedChanges
        self.blockedActions = blockedActions
        self.replacementGate = replacementGate
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
    public let sourceRole: String?
    public let recommendedFutureRow: String?
    public let readiness: String?
    public let relatedSourcePaths: [String]?
    public let blockedActions: [String]?
    public let learnablesCoverage: PokemonLearnablesCoverage?

    public init(
        path: String,
        tableSymbol: String?,
        indexedCount: Int,
        status: PokemonDataCompatibilityStatus,
        note: String? = nil,
        sourceRole: String? = nil,
        recommendedFutureRow: String? = nil,
        readiness: String? = nil,
        relatedSourcePaths: [String]? = nil,
        blockedActions: [String]? = nil,
        learnablesCoverage: PokemonLearnablesCoverage? = nil
    ) {
        self.path = path
        self.tableSymbol = tableSymbol
        self.indexedCount = indexedCount
        self.status = status
        self.note = note
        self.sourceRole = sourceRole
        self.recommendedFutureRow = recommendedFutureRow
        self.readiness = readiness
        self.relatedSourcePaths = relatedSourcePaths
        self.blockedActions = blockedActions
        self.learnablesCoverage = learnablesCoverage
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
        entries.append(movesEntry(index: index, catalog: moveCatalog, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex, fileManager: fileManager))
        entries.append(itemsEntry(index: index, catalog: itemCatalog, sourceIndex: sourceIndex))
        entries.append(learnsetEntry(surface: .levelUpLearnsets, index: index, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex, fileManager: fileManager))
        entries.append(learnsetEntry(surface: .tmhmLearnsets, index: index, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex, fileManager: fileManager))
        entries.append(learnsetEntry(surface: .eggMoves, index: index, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex, fileManager: fileManager))
        entries.append(learnsetEntry(surface: .tutorLearnsets, index: index, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex, fileManager: fileManager))
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
            diagnostics: (catalog?.diagnostics ?? []) + modernEmeraldUnsupportedDiagnostics(surface: .species, profile: index.profile),
            sourceTables: speciesSourceTables(
                profile: index.profile,
                sourceIndex: sourceIndex,
                indexedCount: indexed,
                editableCount: editable
            )
        )
    }

    private static func movesEntry(
        index: ProjectIndex,
        catalog: ProjectMoveCatalog?,
        speciesCatalog: ProjectSpeciesCatalog?,
        sourceIndex: ProjectSourceIndex,
        fileManager: FileManager
    ) -> PokemonDataCompatibilityEntry {
        let descriptor = descriptor(for: .moves, profile: index.profile)
        let indexed = catalog?.summary.moveCount ?? recordCount(.moves, in: sourceIndex)
        let editable = catalog?.moves.filter(\.isEditable).count ?? 0
        let descriptionEditable = catalog?.moves.filter(\.isDescriptionEditable).count ?? 0
        let contestEffectEditable = catalog?.moves.filter(\.isContestEffectEditable).count ?? 0
        let contestScalarsEditable = catalog?.moves.filter(\.isContestScalarsEditable).count ?? 0
        let contestComboMovesEditable = catalog?.moves.filter(\.isContestComboMovesEditable).count ?? 0
        let expansionFlagsEditable = index.profile == .pokeemeraldExpansion ? editable : 0
        let contestMoveFactCount = rubyContestMoveRecordCount(profile: index.profile, in: sourceIndex)
        let rubyMoveConstantsReadiness = moveConstantsReadiness(
            profile: index.profile,
            root: URL(fileURLWithPath: index.root.path).standardizedFileURL,
            fileManager: fileManager
        )
        return entry(
            surface: .moves,
            index: index,
            descriptor: descriptor,
            indexedCount: indexed,
            editableCount: editable,
            unsupportedFields: movesUnsupportedFields(profile: index.profile),
            diagnostics: (catalog?.diagnostics ?? []) + modernEmeraldUnsupportedDiagnostics(surface: .moves, profile: index.profile),
            sourceTables: moveSourceTables(
                profile: index.profile,
                indexedCount: indexed,
                editableCount: editable,
                descriptionEditableCount: descriptionEditable,
                contestEffectEditableCount: contestEffectEditable,
                contestScalarsEditableCount: contestScalarsEditable,
                contestComboMovesEditableCount: contestComboMovesEditable,
                expansionFlagsEditableCount: expansionFlagsEditable,
                contestMoveFactCount: contestMoveFactCount,
                rubyTMHMIndexedCount: rubyTMHMIndexedCount(profile: index.profile, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex),
                rubyTMHMEditableCount: rubyTMHMEditableCount(profile: index.profile, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex),
                rubyTutorIndexedCount: rubyTutorIndexedCount(profile: index.profile, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex),
                rubyTutorEditableCount: rubyTutorEditableCount(profile: index.profile, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex),
                rubyEggIndexedCount: rubyEggIndexedCount(profile: index.profile, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex),
                rubyEggEditableCount: rubyEggEditableCount(profile: index.profile, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex),
                moveConstantsReadiness: rubyMoveConstantsReadiness
            )
        )
    }

    private struct MoveConstantsReadiness {
        let indexedCount: Int
        let status: PokemonDataCompatibilityStatus
        let note: String
        let readiness: String
    }

    private static func moveConstantsReadiness(
        profile: GameProfile,
        root: URL,
        fileManager: FileManager
    ) -> MoveConstantsReadiness? {
        guard profile == .pokeruby else { return nil }
        do {
            let constants = try moveConstantDefinitions(root: root, fileManager: fileManager)
            return MoveConstantsReadiness(
                indexedCount: constants.count,
                status: .readOnly,
                note: "Move constants are indexed for row identity guidance only; constant creation, identity changes, and row creation/reordering remain blocked.",
                readiness: "read-only \(constants.count) MOVE_* constants indexed"
            )
        } catch MoveConstantDefinitionError.missing {
            return MoveConstantsReadiness(
                indexedCount: 0,
                status: .blocked,
                note: "Local include/constants/moves.h is missing; move row identity guidance is limited to table symbols, and constant creation remains blocked.",
                readiness: "missing local move constants header"
            )
        } catch {
            return MoveConstantsReadiness(
                indexedCount: 0,
                status: .blocked,
                note: "Local include/constants/moves.h could not be read; move row identity guidance is limited to table symbols, and constant creation remains blocked.",
                readiness: "unreadable local move constants header"
            )
        }
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
        let metadataFactCount = catalog?.items.filter {
            $0.effect != nil || $0.iconPic != nil || $0.iconPalette != nil
        }.count ?? itemMetadataFactCount(in: sourceIndex)
        let behaviorScalarFactCount = catalog?.items.filter {
            $0.fieldUseFunc != nil
                || $0.battleUsage != nil
                || $0.battleUseFunc != nil
                || $0.secondaryId != nil
        }.count ?? itemBehaviorScalarFactCount(in: sourceIndex)
        let usageScalarFactCount = catalog?.items.filter {
            $0.holdEffect != nil
                || $0.holdEffectParam != nil
                || $0.pocket != nil
                || $0.type != nil
        }.count ?? itemUsageScalarFactCount(in: sourceIndex)
        let bagClassificationScalarFactCount = catalog?.items.filter {
            $0.importance != nil
                || $0.registrability != nil
                || $0.sortType != nil
                || $0.exitsBagOnUse != nil
        }.count ?? itemBagClassificationScalarFactCount(in: sourceIndex)
        return entry(
            surface: .items,
            index: index,
            descriptor: descriptor,
            indexedCount: indexed,
            editableCount: editable,
            unsupportedFields: itemsUnsupportedFields(profile: index.profile),
            diagnostics: (catalog?.diagnostics ?? []) + modernEmeraldUnsupportedDiagnostics(surface: .items, profile: index.profile),
            sourceTables: itemSourceTables(
                profile: index.profile,
                indexedCount: indexed,
                editableCount: editable,
                metadataFactCount: metadataFactCount,
                behaviorScalarFactCount: behaviorScalarFactCount,
                usageScalarFactCount: usageScalarFactCount,
                bagClassificationScalarFactCount: bagClassificationScalarFactCount
            )
        )
    }

    private static func learnsetEntry(
        surface: PokemonDataCompatibilitySurface,
        index: ProjectIndex,
        speciesCatalog: ProjectSpeciesCatalog?,
        sourceIndex: ProjectSourceIndex,
        fileManager: FileManager
    ) -> PokemonDataCompatibilityEntry {
        let descriptor = descriptor(for: surface, profile: index.profile)
        let indexed: Int
        switch surface {
        case .levelUpLearnsets:
            indexed = speciesCatalog?.species.filter { !$0.learnsets.levelUp.isEmpty }.count
                ?? learnsetRecordCount(in: sourceIndex, matching: ["level_up", "learnset"])
        case .tmhmLearnsets:
            if let speciesCatalog {
                if index.profile == .pokeemeraldExpansion {
                    indexed = speciesCatalog.species.filter { species in
                        isExpansionTMHMLearnsetSourcePath(species.learnsets.tmhmSourceSpan?.relativePath)
                    }.count
                } else {
                    indexed = speciesCatalog.species.filter { $0.learnsets.tmhmSourceSpan != nil }.count
                }
            } else {
                indexed = learnsetRecordCount(in: sourceIndex, matching: ["tmhm"])
            }
        case .eggMoves:
            if index.profile == .pokeemeraldExpansion {
                indexed = speciesCatalog?.species.filter { species in
                    isExpansionEggMoveSourcePath(species.learnsets.eggSourceSpan?.relativePath)
                }.count ?? learnsetRecordCount(in: sourceIndex, matching: ["egg"])
            } else {
                indexed = speciesCatalog?.species.filter { !$0.learnsets.egg.isEmpty }.count
                    ?? learnsetRecordCount(in: sourceIndex, matching: ["egg"])
            }
        case .tutorLearnsets:
            if index.profile == .pokeruby || index.profile == .pokeemeraldExpansion {
                indexed = speciesCatalog?.species.filter { species in
                    species.learnsets.tutorSourceSpan?.relativePath == "src/data/pokemon/tutor_learnsets.h"
                }.count ?? learnsetRecordCount(in: sourceIndex, matching: ["tutor"])
            } else {
                indexed = speciesCatalog?.species.filter { !$0.learnsets.tutor.isEmpty }.count
                    ?? learnsetRecordCount(in: sourceIndex, matching: ["tutor"])
            }
        default:
            indexed = 0
        }
        let editable = supportsLearnsetMutationEditing(surface: surface, profile: index.profile) && indexed > 0 ? indexed : 0
        let allLearnablesCoverage = ExpansionAllLearnablesCoverageBuilder.report(
            index: index,
            speciesCatalog: speciesCatalog,
            fileManager: fileManager
        )?.summary
        let sourceTables: [PokemonDataCompatibilitySourceTable]?
        switch surface {
        case .levelUpLearnsets:
            sourceTables = levelUpLearnsetSourceTables(
                profile: index.profile,
                sourceIndex: sourceIndex,
                indexedCount: indexed,
                editableCount: editable,
                rubyTMHMIndexedCount: rubyTMHMIndexedCount(profile: index.profile, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex),
                rubyTMHMEditableCount: rubyTMHMEditableCount(profile: index.profile, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex),
                rubyEggIndexedCount: rubyEggIndexedCount(profile: index.profile, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex),
                rubyEggEditableCount: rubyEggEditableCount(profile: index.profile, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex),
                learnablesCoverage: allLearnablesCoverage
            )
        case .tmhmLearnsets:
            sourceTables = tmhmLearnsetSourceTables(
                profile: index.profile,
                sourceIndex: sourceIndex,
                indexedCount: indexed,
                editableCount: editable,
                learnablesCoverage: allLearnablesCoverage
            )
        case .tutorLearnsets:
            sourceTables = tutorLearnsetSourceTables(
                profile: index.profile,
                sourceIndex: sourceIndex,
                indexedCount: indexed,
                editableCount: editable,
                learnablesCoverage: allLearnablesCoverage
            )
        case .eggMoves:
            sourceTables = eggMoveSourceTables(
                profile: index.profile,
                sourceIndex: sourceIndex,
                indexedCount: indexed,
                editableCount: editable,
                learnablesCoverage: allLearnablesCoverage
            )
        default:
            sourceTables = nil
        }
        return entry(
            surface: surface,
            index: index,
            descriptor: descriptor,
            indexedCount: indexed,
            editableCount: editable,
            unsupportedFields: learnsetUnsupportedFields(surface: surface, profile: index.profile),
            recommendedFutureRow: editable > 0 ? nil : descriptor?.recommendedFutureRow,
            diagnostics: expansionLearnsetGeneratedStalenessDiagnostics(surface: surface, index: index, fileManager: fileManager),
            sourceTables: sourceTables
        )
    }

    private static func evolutionsEntry(
        index: ProjectIndex,
        speciesCatalog: ProjectSpeciesCatalog?,
        sourceIndex: ProjectSourceIndex
    ) -> PokemonDataCompatibilityEntry {
        let descriptor = descriptor(for: .evolutions, profile: index.profile)
        let indexed: Int
        if let speciesCatalog, index.profile == .pokeemeraldExpansion {
            indexed = speciesCatalog.species.filter { species in
                species.evolutions.contains { $0.sourceSpan.relativePath == "src/data/pokemon/evolution.h" }
            }.count
        } else {
            indexed = speciesCatalog?.species.filter { !$0.evolutions.isEmpty }.count
                ?? recordCount(.evolutions, in: sourceIndex)
        }
        let editable = supportsEvolutionMutationEditing(index.profile) && indexed > 0 ? indexed : 0
        return entry(
            surface: .evolutions,
            index: index,
            descriptor: descriptor,
            indexedCount: indexed,
            editableCount: editable,
            unsupportedFields: evolutionUnsupportedFields(profile: index.profile, editableCount: editable),
            recommendedFutureRow: editable > 0 ? nil : descriptor?.recommendedFutureRow,
            sourceTables: evolutionSourceTables(
                profile: index.profile,
                indexedCount: indexed,
                editableCount: editable
            )
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
        let editable = supportsPokedexMutationEditing(index.profile) && indexed > 0 ? indexed : 0
        return entry(
            surface: .pokedex,
            index: index,
            descriptor: descriptor,
            indexedCount: indexed,
            editableCount: editable,
            unsupportedFields: pokedexUnsupportedFields(profile: index.profile, editableCount: editable),
            recommendedFutureRow: editable > 0 ? nil : "PHS-T57",
            sourceTables: pokedexSourceTables(
                profile: index.profile,
                indexedCount: indexed,
                editableCount: editable
            )
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
        let editable = index.profile == .pokeruby && count > 0 ? count : 0
        var unsupportedFields = [
            "audio conversion",
            "generated audio output writes",
            "source generation",
            "missing-source creation",
            "ROM cry table rewrites",
            "playback",
            "binary mutation",
            "reference writes",
            "broad audio schema rewrites"
        ]
        if editable == 0 {
            unsupportedFields.append("source mutation apply")
        }
        return entry(
            surface: .cries,
            index: index,
            descriptor: descriptor,
            indexedCount: count,
            editableCount: editable,
            unsupportedFields: unsupportedFields,
            blockedReason: count == 0 ? plan.blockedReasons.joined(separator: " ") : nil,
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
        let compatibilityRecords = sourceIndex.records.filter(isFormCompatibilityRecord)
        let formSpeciesCount = formRecords(in: sourceIndex, path: "src/data/pokemon/form_species_tables.h").count
        let formChangeCount = formRecords(in: sourceIndex, path: "src/data/pokemon/form_change_tables.h").count
        let editable = index.profile == .pokeemeraldExpansion ? formSpeciesCount + formChangeCount : 0
        let sourceTables = formSourceTables(profile: index.profile, in: sourceIndex)
        let count = compatibilityRecords.count
        return entry(
            surface: .forms,
            index: index,
            descriptor: descriptor,
            indexedCount: count,
            editableCount: editable,
            unsupportedFields: editable > 0
                ? ["form row insertion/removal/reorder", "unsupported form change tuple shapes", "form graphics sync", "generated family supplement apply", "reference-only form source writes", "ROM/export/build outputs", "binary-only form table writes"]
                : ["form editing", "form table mutation/apply", "form graphics sync", "generated family supplement apply", "binary-only form table writes", "ROM/export/source writes"],
            blockedReason: count == 0 ? "No form table or species supplement source graph was detected for this fixture/profile." : nil,
            recommendedFutureRow: editable > 0 ? nil : "PHS-T57E",
            diagnostics: formDiagnostics(records: compatibilityRecords, editableCount: editable),
            sourceTables: sourceTables
        )
    }

    private static func formSourceTables(profile: GameProfile, in sourceIndex: ProjectSourceIndex) -> [PokemonDataCompatibilitySourceTable] {
        let formSpeciesPath = "src/data/pokemon/form_species_tables.h"
        let formChangePath = "src/data/pokemon/form_change_tables.h"
        let speciesInfoRoot = "src/data/pokemon/species_info/"
        let formSpeciesCount = formRecords(in: sourceIndex, path: formSpeciesPath).count
        let formChangeCount = formRecords(in: sourceIndex, path: formChangePath).count
        let localTablesEditable = profile == .pokeemeraldExpansion
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
                status: formSpeciesCount > 0 ? (localTablesEditable ? .editable : .readOnly) : .blocked,
                note: localTablesEditable
                    ? "Local source-backed form species table rows use the Species mutation-plan gate for existing rows only."
                    : "Read-only form species table metadata for PHS-T57E."
            ),
            PokemonDataCompatibilitySourceTable(
                path: formChangePath,
                tableSymbol: "s*FormChangeTable",
                indexedCount: formChangeCount,
                status: formChangeCount > 0 ? (localTablesEditable ? .editable : .readOnly) : .blocked,
                note: localTablesEditable
                    ? "Local source-backed form change table rows use the Species mutation-plan gate for existing simple rows only."
                    : "Read-only form change table metadata for PHS-T57E."
            ),
            PokemonDataCompatibilitySourceTable(
                path: speciesInfoRoot,
                tableSymbol: "formSpeciesIdTable/formChangeTable",
                indexedCount: speciesInfoCount,
                status: speciesInfoCount > 0 ? .readOnly : .blocked,
                note: "Read-only species-info form links; generated family supplement apply stays blocked."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "generated",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Generated form/family supplement apply stays blocked."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "references/pokeemerald-expansion/src/data/pokemon/form_species_tables.h",
                tableSymbol: "s*FormSpeciesIdTable",
                indexedCount: 0,
                status: .blocked,
                note: "Reference-only form species table writes stay blocked."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "references/pokeemerald-expansion/src/data/pokemon/form_change_tables.h",
                tableSymbol: "s*FormChangeTable",
                indexedCount: 0,
                status: .blocked,
                note: "Reference-only form change table writes stay blocked."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "graphics/pokemon",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Form graphics sync stays blocked."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "ROM output",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "ROM/export/build outputs and binary form table writes stay blocked."
            )
        ]
    }

    private static func evolutionSourceTables(
        profile: GameProfile,
        indexedCount: Int,
        editableCount: Int
    ) -> [PokemonDataCompatibilitySourceTable]? {
        guard profile == .pokeemeraldExpansion else { return nil }
        let localStatus: PokemonDataCompatibilityStatus
        if editableCount > 0 {
            localStatus = .editable
        } else if indexedCount > 0 {
            localStatus = .readOnly
        } else {
            localStatus = .blocked
        }
        return [
            PokemonDataCompatibilitySourceTable(
                path: "src/data/pokemon/evolution.h",
                tableSymbol: "gEvolutionTable",
                indexedCount: indexedCount,
                status: localStatus,
                note: "Local source-backed Expansion evolution tuples use the Species mutation-plan gate for existing parsed rows only."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "include/constants/pokemon.h",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Evolution method constants, species constants, identity changes, and row creation/reordering remain blocked."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "generated",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Generated evolution outputs remain blocked and must be refreshed outside this mutation plan."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "references/pokeemerald-expansion/src/data/pokemon/evolution.h",
                tableSymbol: "gEvolutionTable",
                indexedCount: 0,
                status: .blocked,
                note: "Reference Expansion clones remain read-only research inputs."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "ROM output",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "ROM/export/build outputs and binary writes remain blocked."
            )
        ]
    }

    private static func speciesSourceTables(
        profile: GameProfile,
        sourceIndex: ProjectSourceIndex,
        indexedCount: Int,
        editableCount: Int
    ) -> [PokemonDataCompatibilitySourceTable]? {
        guard profile == .pokeemeraldExpansion else { return nil }
        let familySupplementCount = Set(
            sourceIndex.records
                .filter { $0.sourceSpan.relativePath.hasPrefix("src/data/pokemon/species_info/") }
                .map { "\($0.sourceSpan.relativePath):\($0.title)" }
        ).count
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
                path: "src/data/pokemon/species_info.h",
                tableSymbol: "gSpeciesInfo",
                indexedCount: indexedCount,
                status: sourceStatus,
                note: "Local source-backed Expansion gSpeciesInfo rows use the species mutation-plan gate for existing top-level scalar fields only."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "include/config/species_enabled.h",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Species enablement config remains read-only for this slice."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "include/config/pokemon.h",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Pokemon config and schema toggles remain read-only for this slice."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "src/data/pokemon/species_info/",
                tableSymbol: "family supplements",
                indexedCount: familySupplementCount,
                status: .blocked,
                note: "Generated/family supplement species_info rows remain read-only under PHS-T57D."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "generated",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Generated species outputs remain blocked and must be refreshed outside this mutation plan."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "references/pokeemerald-expansion/src/data/pokemon/species_info.h",
                tableSymbol: "gSpeciesInfo",
                indexedCount: 0,
                status: .blocked,
                note: "Reference Expansion clones remain read-only research inputs."
            ),
            modernEmeraldReferenceSourceTable(
                path: "references/modern-emerald/src/data/pokemon/species_info.h",
                tableSymbol: "gSpeciesInfo",
                note: "Modern Emerald species data is reference-only schema pressure; species writers and generated outputs remain future PHS-T78 work."
            ),
            modernEmeraldReferenceSourceTable(
                path: "references/modern-emerald/include/constants/species.h",
                tableSymbol: nil,
                note: "Modern Emerald species constants stay reference-only; identity and constant creation remain blocked."
            ),
            modernEmeraldReferenceSourceTable(
                path: "references/modern-emerald/include/constants/pokemon.h",
                tableSymbol: nil,
                note: "Modern Emerald Pokemon constants stay reference-only; identity and schema rewrites remain blocked."
            ),
            modernEmeraldReferenceSourceTable(
                path: "references/modern-emerald/include/config.h",
                tableSymbol: nil,
                note: "Modern Emerald aggregate config gates are reference-only compatibility pressure; config writes remain blocked."
            ),
            modernEmeraldReferenceSourceTable(
                path: "references/modern-emerald/graphics/pokemon",
                tableSymbol: "species graphics/icon paths",
                note: "Modern Emerald Pokemon graphics and icon paths are reference-only metadata; graphics sync and asset writes remain blocked."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "ROM output",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Binary ROM/export writes remain blocked."
            )
        ]
    }

    private static func itemSourceTables(
        profile: GameProfile,
        indexedCount: Int,
        editableCount: Int,
        metadataFactCount: Int,
        behaviorScalarFactCount: Int,
        usageScalarFactCount: Int,
        bagClassificationScalarFactCount: Int
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
                path: "src/data/items.h",
                tableSymbol: "gItemsInfo .effect/.iconPic/.iconPalette",
                indexedCount: metadataFactCount,
                status: metadataFactCount > 0 ? .editable : .blocked,
                note: "Expansion ItemInfo effect/icon fields are editable only as existing simple C-symbol fields through the item mutation-plan gate.",
                sourceRole: "editableSourceFields",
                readiness: metadataFactCount > 0 ? "editable existing source fields" : "no existing effect/icon fields indexed",
                blockedActions: [
                    "icon asset rewrites",
                    "generated output writes",
                    "Modern Emerald writes",
                    "ROM/build/export paths",
                    "identity edits"
                ]
            ),
            PokemonDataCompatibilitySourceTable(
                path: "src/data/items.h",
                tableSymbol: "gItemsInfo .holdEffect/.holdEffectParam/.pocket/.type",
                indexedCount: usageScalarFactCount,
                status: usageScalarFactCount > 0 || editableCount > 0 ? .editable : .blocked,
                note: "Expansion ItemInfo usage/classification scalars are editable as existing simple local source fields, or inserted as one complete anchored usage/classification group, through the item mutation-plan gate.",
                sourceRole: "editableUsageScalars",
                readiness: usageScalarFactCount > 0 ? "editable existing usage/classification scalar fields; complete missing group insertion is anchor-gated" : "complete missing usage/classification scalar group can be inserted when .price, .description, and .sortType anchors exist",
                blockedActions: [
                    "constants-file edits/creation",
                    "partial missing-field insertion/removal",
                    "row insertion/removal/reorder",
                    "generated outputs",
                    "reference writes",
                    "ROM/build/export paths",
                    "binary writes",
                    "broad schema rewrites"
                ]
            ),
            PokemonDataCompatibilitySourceTable(
                path: "src/data/items.h",
                tableSymbol: "gItemsInfo .fieldUseFunc/.battleUsage/.battleUseFunc/.secondaryId",
                indexedCount: behaviorScalarFactCount,
                status: behaviorScalarFactCount > 0 || editableCount > 0 ? .editable : .blocked,
                note: "Expansion ItemInfo behavior/function scalars are editable as existing simple local source fields, or inserted as one complete anchored behavior/function group, through the item mutation-plan gate.",
                sourceRole: "editableBehaviorScalars",
                readiness: behaviorScalarFactCount > 0 ? "editable existing behavior/function scalar fields; complete missing group insertion is anchor-gated" : "complete missing behavior/function scalar group can be inserted when .effect and .iconPic anchors exist",
                blockedActions: [
                    "constants-file edits/creation",
                    "partial missing-field insertion/removal",
                    "row insertion/removal/reorder",
                    "generated outputs",
                    "reference writes",
                    "ROM/build/export paths",
                    "binary writes",
                    "broad schema rewrites"
                ]
            ),
            PokemonDataCompatibilitySourceTable(
                path: "src/data/items.h",
                tableSymbol: "gItemsInfo .importance/.registrability/.sortType/.exitsBagOnUse",
                indexedCount: bagClassificationScalarFactCount,
                status: bagClassificationScalarFactCount > 0 ? .editable : .blocked,
                note: "Expansion ItemInfo bag/classification scalars are editable only as existing simple local source fields through the item mutation-plan gate.",
                sourceRole: "editableBagClassificationScalars",
                readiness: bagClassificationScalarFactCount > 0 ? "editable existing bag/classification scalar fields" : "no existing bag/classification scalar fields indexed",
                blockedActions: [
                    "constants-file edits/creation",
                    "missing-field insertion",
                    "row insertion/removal/reorder",
                    "generated outputs",
                    "reference writes",
                    "ROM/build/export paths",
                    "binary writes",
                    "broad schema rewrites"
                ]
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
            ),
            modernEmeraldReferenceSourceTable(
                path: "references/modern-emerald/src/data/items.h",
                tableSymbol: "gItems",
                note: "Modern Emerald item rows use a reference-only shape for compatibility pressure; item writers remain future PHS-T78 work."
            ),
            modernEmeraldReferenceSourceTable(
                path: "references/modern-emerald/include/constants/items.h",
                tableSymbol: nil,
                note: "Modern Emerald item constants stay reference-only; identity and constant creation remain blocked."
            ),
            modernEmeraldReferenceSourceTable(
                path: "references/modern-emerald/include/config.h",
                tableSymbol: nil,
                note: "Modern Emerald aggregate config gates are reference-only compatibility pressure; item config writes remain blocked."
            ),
            modernEmeraldReferenceSourceTable(
                path: "references/modern-emerald/src/data/graphics/items.h",
                tableSymbol: "item graphics metadata",
                note: "Modern Emerald item graphics metadata is reference-only; icon/effect asset rewrites stay blocked."
            ),
            modernEmeraldReferenceSourceTable(
                path: "references/modern-emerald/graphics/items/icons",
                tableSymbol: "item icon PNG paths",
                note: "Modern Emerald item icon paths are reference-only metadata; icon asset writes remain blocked."
            ),
            modernEmeraldReferenceSourceTable(
                path: "references/modern-emerald/graphics/items/icon_palettes",
                tableSymbol: "item icon palette paths",
                note: "Modern Emerald item icon palette paths are reference-only metadata; palette writes remain blocked."
            )
        ]
    }

    private static func moveSourceTables(
        profile: GameProfile,
        indexedCount: Int,
        editableCount: Int,
        descriptionEditableCount: Int,
        contestEffectEditableCount: Int,
        contestScalarsEditableCount: Int,
        contestComboMovesEditableCount: Int,
        expansionFlagsEditableCount: Int,
        contestMoveFactCount: Int,
        rubyTMHMIndexedCount: Int,
        rubyTMHMEditableCount: Int,
        rubyTutorIndexedCount: Int,
        rubyTutorEditableCount: Int,
        rubyEggIndexedCount: Int,
        rubyEggEditableCount: Int,
        moveConstantsReadiness: MoveConstantsReadiness?
    ) -> [PokemonDataCompatibilitySourceTable]? {
        let sourceStatus: PokemonDataCompatibilityStatus
        if editableCount > 0 {
            sourceStatus = .editable
        } else if indexedCount > 0 {
            sourceStatus = .readOnly
        } else {
            sourceStatus = .blocked
        }
        let descriptionStatus: PokemonDataCompatibilityStatus
        if descriptionEditableCount > 0 {
            descriptionStatus = .editable
        } else if indexedCount > 0 {
            descriptionStatus = .readOnly
        } else {
            descriptionStatus = .blocked
        }
        let contestEffectStatus: PokemonDataCompatibilityStatus = contestEffectEditableCount > 0 ? .editable : .blocked
        let contestMoveStatus: PokemonDataCompatibilityStatus = (contestScalarsEditableCount > 0 || contestComboMovesEditableCount > 0)
            ? .editable
            : (contestMoveFactCount > 0 ? .readOnly : .blocked)
        if profile == .pokeruby {
            let tmhmStatus: PokemonDataCompatibilityStatus
            if rubyTMHMEditableCount > 0 {
                tmhmStatus = .editable
            } else if rubyTMHMIndexedCount > 0 {
                tmhmStatus = .readOnly
            } else {
                tmhmStatus = .blocked
            }
            let tutorStatus: PokemonDataCompatibilityStatus
            if rubyTutorEditableCount > 0 {
                tutorStatus = .editable
            } else if rubyTutorIndexedCount > 0 {
                tutorStatus = .readOnly
            } else {
                tutorStatus = .blocked
            }
            let eggStatus: PokemonDataCompatibilityStatus
            if rubyEggEditableCount > 0 {
                eggStatus = .editable
            } else if rubyEggIndexedCount > 0 {
                eggStatus = .readOnly
            } else {
                eggStatus = .blocked
            }
            let contestMoveNote: String
            if contestScalarsEditableCount > 0 && contestComboMovesEditableCount > 0 {
                contestMoveNote = "Existing simple Ruby/Sapphire contest move effect, contestCategory, comboStarterId scalar fields, and comboMoves arrays are editable through move drafts."
            } else if contestScalarsEditableCount > 0 {
                contestMoveNote = "Existing simple Ruby/Sapphire contest move effect, contestCategory, and comboStarterId scalar fields are editable through move drafts; non-simple or missing comboMoves arrays remain blocked."
            } else if contestComboMovesEditableCount > 0 {
                contestMoveNote = "Existing simple Ruby/Sapphire contest move comboMoves arrays are editable through move drafts; contest scalar writers remain blocked for missing or non-simple scalar fields."
            } else {
                contestMoveNote = "Ruby/Sapphire contest move metadata is surfaced as read-only facts linked back to move IDs; contest scalar writers and combo edits remain blocked."
            }
            let contestMoveSourceRole: String
            switch (contestScalarsEditableCount > 0, contestComboMovesEditableCount > 0) {
            case (true, true):
                contestMoveSourceRole = "editableContestScalarsAndComboMoves"
            case (true, false):
                contestMoveSourceRole = "editableContestScalars"
            case (false, true):
                contestMoveSourceRole = "editableContestComboMoves"
            case (false, false):
                contestMoveSourceRole = "readOnlyContestMetadata"
            }
            let contestMoveReadiness: String?
            switch (contestScalarsEditableCount > 0, contestComboMovesEditableCount > 0, contestMoveFactCount > 0) {
            case (true, true, _):
                contestMoveReadiness = "editable existing simple scalar fields and combo arrays"
            case (true, false, _):
                contestMoveReadiness = "editable existing simple scalar fields"
            case (false, true, _):
                contestMoveReadiness = "editable existing simple combo arrays"
            case (false, false, true):
                contestMoveReadiness = "factsOnly"
            default:
                contestMoveReadiness = nil
            }
            var contestMoveBlockedActions = [
                "constants",
                "missing-field insertion",
                "row insertion/removal/reorder",
                "generated writes",
                "reference writes",
                "ROM writes",
                "binary writes"
            ]
            if contestComboMovesEditableCount <= 0 {
                contestMoveBlockedActions.insert("combo array editing", at: 0)
            }
            return [
                PokemonDataCompatibilitySourceTable(
                    path: "src/data/battle_moves.c",
                    tableSymbol: "gBattleMoves",
                    indexedCount: indexedCount,
                    status: sourceStatus,
                    note: "Local Ruby/Sapphire battle move rows use the move mutation-plan gate."
                ),
                PokemonDataCompatibilitySourceTable(
                    path: "src/data/battle_moves.c",
                    tableSymbol: "gMoveDescription_*",
                    indexedCount: descriptionEditableCount,
                    status: descriptionStatus,
                    note: "Existing in-file Ruby/Sapphire move description declarations referenced by gBattleMoves are editable through move drafts."
                ),
                PokemonDataCompatibilitySourceTable(
                    path: "include/constants/moves.h",
                    tableSymbol: "MOVE_*",
                    indexedCount: moveConstantsReadiness?.indexedCount ?? 0,
                    status: moveConstantsReadiness?.status ?? .blocked,
                    note: moveConstantsReadiness?.note ?? "Move constants, identity changes, and row creation/reordering remain blocked.",
                    sourceRole: "readOnlyMoveConstants",
                    readiness: moveConstantsReadiness?.readiness,
                    blockedActions: [
                        "constant creation",
                        "constant rename",
                        "row insertion/removal/reorder",
                        "generated writes",
                        "reference writes",
                        "ROM writes",
                        "binary writes"
                    ]
                ),
                PokemonDataCompatibilitySourceTable(
                    path: "src/data/battle_moves.c",
                    tableSymbol: ".contestEffect",
                    indexedCount: contestEffectEditableCount,
                    status: contestEffectStatus,
                    note: "Existing simple Ruby/Sapphire contestEffect fields are editable through move drafts; missing or non-simple fields stay blocked."
                ),
                PokemonDataCompatibilitySourceTable(
                    path: "src/data/contest_moves.h",
                    tableSymbol: "gContestMoves",
                    indexedCount: contestMoveFactCount,
                    status: contestMoveStatus,
                    note: contestMoveNote,
                    sourceRole: contestMoveSourceRole,
                    readiness: contestMoveReadiness,
                    blockedActions: contestMoveBlockedActions
                ),
                PokemonDataCompatibilitySourceTable(
                    path: "src/data/pokemon/tmhm_learnsets.h",
                    tableSymbol: "gTMHMLearnsets",
                    indexedCount: rubyTMHMIndexedCount,
                    status: tmhmStatus,
                    note: "Existing local Ruby/Sapphire gTMHMLearnsets rows are editable from move-centric compatibility drafts through the species mutation-plan gate.",
                    sourceRole: "editableTMHMLearnsets",
                    readiness: rubyTMHMEditableCount > 0 ? "editable existing gTMHMLearnsets rows" : "no editable existing gTMHMLearnsets rows indexed",
                    blockedActions: [
                        "TM/HM item mapping edits",
                        "machine constant creation",
                        "missing TM/HM row insertion",
                        "row insertion/removal/reorder",
                        "generated writes",
                        "reference writes",
                        "ROM writes",
                        "binary writes"
                    ]
                ),
                PokemonDataCompatibilitySourceTable(
                    path: "src/data/pokemon/tutor_learnsets.h",
                    tableSymbol: "sTutorLearnsets/gTutorLearnsets",
                    indexedCount: rubyTutorIndexedCount,
                    status: tutorStatus,
                    note: "Existing local Ruby/Sapphire tutor rows are editable from move-centric compatibility drafts through the species mutation-plan gate.",
                    sourceRole: "editableTutorLearnsets",
                    readiness: rubyTutorEditableCount > 0 ? "editable existing sTutorLearnsets/gTutorLearnsets rows" : "no editable existing sTutorLearnsets/gTutorLearnsets rows indexed",
                    blockedActions: [
                        "move constant creation",
                        "tutor constant creation",
                        "missing tutor row insertion",
                        "row insertion/removal/reorder",
                        "generated writes",
                        "reference writes",
                        "ROM writes",
                        "binary writes"
                    ]
                ),
                PokemonDataCompatibilitySourceTable(
                    path: "src/data/pokemon/egg_moves.h",
                    tableSymbol: "gEggMoves",
                    indexedCount: rubyEggIndexedCount,
                    status: eggStatus,
                    note: "Existing local Ruby/Sapphire egg-move rows are editable from move-centric compatibility drafts through the species mutation-plan gate.",
                    sourceRole: "editableEggMoves",
                    readiness: rubyEggEditableCount > 0 ? "editable existing gEggMoves rows" : "no editable existing gEggMoves rows indexed",
                    blockedActions: [
                        "move constant creation",
                        "move identity changes",
                        "missing egg-move species row insertion",
                        "family reshaping",
                        "row insertion/removal/reorder",
                        "generated writes",
                        "reference writes",
                        "ROM writes",
                        "binary writes"
                    ]
                ),
                PokemonDataCompatibilitySourceTable(
                    path: "generated",
                    tableSymbol: nil,
                    indexedCount: 0,
                    status: .blocked,
                    note: "Generated move outputs remain blocked and must be refreshed outside this mutation plan."
                ),
                PokemonDataCompatibilitySourceTable(
                    path: "references/pokeruby/src/data/battle_moves.c",
                    tableSymbol: "gBattleMoves",
                    indexedCount: 0,
                    status: .blocked,
                    note: "Reference Ruby/Sapphire clones remain read-only research inputs."
                ),
                PokemonDataCompatibilitySourceTable(
                    path: "ROM output",
                    tableSymbol: nil,
                    indexedCount: 0,
                    status: .blocked,
                    note: "ROM and binary move writes remain blocked."
                )
            ]
        }
        guard profile == .pokeemeraldExpansion else { return nil }
        return [
            PokemonDataCompatibilitySourceTable(
                path: "src/data/moves_info.h",
                tableSymbol: "gMovesInfo",
                indexedCount: indexedCount,
                status: sourceStatus,
                note: "Local source-backed Expansion MoveInfo rows and move description declarations use the move mutation-plan gate."
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
                indexedCount: descriptionEditableCount,
                status: descriptionStatus,
                note: "Local source-backed Expansion move description declarations are editable through move drafts."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "src/data/moves_info.h",
                tableSymbol: "gMovesInfo flags",
                indexedCount: expansionFlagsEditableCount,
                status: expansionFlagsEditableCount > 0 ? .editable : (indexedCount > 0 ? .readOnly : .blocked),
                note: "Existing simple Expansion flags fields and missing flags fields on existing rows are editable through move drafts with local FLAG_* validation.",
                sourceRole: "editableFlags",
                readiness: expansionFlagsEditableCount > 0 ? "editable existing or missing simple FLAG_* field values" : "no editable flags rows indexed",
                blockedActions: [
                    "constant creation",
                    "non-simple flags expressions",
                    "row insertion/removal/reorder",
                    "generated outputs",
                    "reference writes",
                    "ROM/build/export paths",
                    "binary writes"
                ]
            ),
            PokemonDataCompatibilitySourceTable(
                path: "src/data/moves_info.h",
                tableSymbol: "gMovesInfo contest scalars",
                indexedCount: contestScalarsEditableCount,
                status: contestScalarsEditableCount > 0 ? .editable : (indexedCount > 0 ? .readOnly : .blocked),
                note: "Existing simple Expansion contestCategory, contestAppeal, contestJam, and contestComboStarterId fields are editable through move drafts.",
                sourceRole: "editableContestScalars",
                readiness: contestScalarsEditableCount > 0 ? "editable existing simple scalar fields" : "no existing simple contest scalar fields indexed",
                blockedActions: [
                    "constants",
                    "missing-field insertion",
                    "row insertion/removal/reorder",
                    "generated outputs",
                    "reference writes",
                    "ROM/binary writes"
                ]
            ),
            PokemonDataCompatibilitySourceTable(
                path: "src/data/moves_info.h",
                tableSymbol: "gMovesInfo contest combo moves",
                indexedCount: contestComboMovesEditableCount,
                status: contestComboMovesEditableCount > 0 ? .editable : (indexedCount > 0 ? .readOnly : .blocked),
                note: "Existing simple Expansion contestComboMoves MOVE_* arrays are editable through move drafts.",
                sourceRole: "editableContestComboMoves",
                readiness: contestComboMovesEditableCount > 0 ? "editable existing simple MOVE_* arrays" : "no simple contestComboMoves arrays indexed",
                blockedActions: [
                    "constants",
                    "missing-field insertion",
                    "row insertion/removal/reorder",
                    "generated outputs",
                    "reference writes",
                    "ROM/build/export paths",
                    "binary writes"
                ]
            ),
            PokemonDataCompatibilitySourceTable(
                path: "src/data/contest_moves.h",
                tableSymbol: "gContestMoves",
                indexedCount: 0,
                status: .blocked,
                note: "Adjacent contest tables remain blocked for this slice."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "src/data/pokemon/tmhm_learnsets.h",
                tableSymbol: "sTMHMLearnsets",
                indexedCount: 0,
                status: .blocked,
                note: "TM/HM compatibility edits remain blocked from move row plans."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "src/data/pokemon/egg_moves.h",
                tableSymbol: "gEggMoves",
                indexedCount: 0,
                status: .blocked,
                note: "Egg compatibility edits remain blocked from move row plans."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "src/data/pokemon/tutor_learnsets.h",
                tableSymbol: "gTutorLearnsets",
                indexedCount: rubyTutorIndexedCount,
                status: rubyTutorEditableCount > 0 ? .editable : (rubyTutorIndexedCount > 0 ? .readOnly : .blocked),
                note: "Existing local Expansion tutor rows are editable from move-centric compatibility drafts through the species mutation-plan gate.",
                sourceRole: "editableTutorLearnsets",
                readiness: rubyTutorEditableCount > 0 ? "editable existing gTutorLearnsets rows" : "no editable existing gTutorLearnsets rows indexed",
                blockedActions: [
                    "tutor constant creation",
                    "missing tutor row insertion",
                    "row insertion/removal/reorder",
                    "generated all_learnables.json writes",
                    "generated outputs",
                    "reference writes",
                    "ROM/build/export paths",
                    "binary writes"
                ]
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
            modernEmeraldReferenceSourceTable(
                path: "references/modern-emerald/src/data/battle_moves.h",
                tableSymbol: "gBattleMoves",
                note: "Modern Emerald battle move rows are reference-only schema pressure; move writers remain future PHS-T78 work."
            ),
            modernEmeraldReferenceSourceTable(
                path: "references/modern-emerald/include/constants/moves.h",
                tableSymbol: nil,
                note: "Modern Emerald move constants stay reference-only; identity and constant creation remain blocked."
            ),
            modernEmeraldReferenceSourceTable(
                path: "references/modern-emerald/include/config.h",
                tableSymbol: nil,
                note: "Modern Emerald aggregate config gates are reference-only compatibility pressure; move config writes remain blocked."
            ),
            modernEmeraldReferenceSourceTable(
                path: "references/modern-emerald/src/data/pokemon/tmhm_learnsets.h",
                tableSymbol: "gTMHMLearnsets",
                note: "Modern Emerald TM/HM compatibility data stays reference-only and blocked from move row plans."
            ),
            modernEmeraldReferenceSourceTable(
                path: "references/modern-emerald/src/data/pokemon/tutor_learnsets.h",
                tableSymbol: "gTutorLearnsets",
                note: "Modern Emerald tutor compatibility data stays reference-only and blocked from move row plans."
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

    private static func levelUpLearnsetSourceTables(
        profile: GameProfile,
        sourceIndex: ProjectSourceIndex,
        indexedCount: Int,
        editableCount: Int,
        rubyTMHMIndexedCount: Int = 0,
        rubyTMHMEditableCount: Int = 0,
        rubyEggIndexedCount: Int = 0,
        rubyEggEditableCount: Int = 0,
        learnablesCoverage: PokemonLearnablesCoverage? = nil
    ) -> [PokemonDataCompatibilitySourceTable]? {
        if profile == .pokeruby {
            let sourceStatus: PokemonDataCompatibilityStatus
            if editableCount > 0 {
                sourceStatus = .editable
            } else if indexedCount > 0 {
                sourceStatus = .readOnly
            } else {
                sourceStatus = .blocked
            }
            let tmhmStatus: PokemonDataCompatibilityStatus
            if rubyTMHMEditableCount > 0 {
                tmhmStatus = .editable
            } else if rubyTMHMIndexedCount > 0 {
                tmhmStatus = .readOnly
            } else {
                tmhmStatus = .blocked
            }
            let eggStatus: PokemonDataCompatibilityStatus
            if rubyEggEditableCount > 0 {
                eggStatus = .editable
            } else if rubyEggIndexedCount > 0 {
                eggStatus = .readOnly
            } else {
                eggStatus = .blocked
            }
            return [
                PokemonDataCompatibilitySourceTable(
                    path: "src/data/pokemon/level_up_learnsets.h",
                    tableSymbol: "gLevelUpLearnsets",
                    indexedCount: indexedCount,
                    status: sourceStatus,
                    note: "Ruby/Sapphire level-up writes are limited to existing local g*LevelUpLearnset blocks parsed from source."
                ),
                PokemonDataCompatibilitySourceTable(
                    path: "src/data/pokemon/tmhm_learnsets.h",
                    tableSymbol: "gTMHMLearnsets",
                    indexedCount: rubyTMHMIndexedCount,
                    status: tmhmStatus,
                    note: "Ruby/Sapphire TM/HM writes are limited to existing local gTMHMLearnsets rows parsed from source."
                ),
                PokemonDataCompatibilitySourceTable(
                    path: "src/data/pokemon/egg_moves.h",
                    tableSymbol: "gEggMoves",
                    indexedCount: rubyEggIndexedCount,
                    status: eggStatus,
                    note: "Ruby/Sapphire egg move writes are limited to existing local egg_moves(...) rows parsed from source."
                ),
                PokemonDataCompatibilitySourceTable(
                    path: "src/data/pokemon/tutor_learnsets.h",
                    tableSymbol: nil,
                    indexedCount: 0,
                    status: .blocked,
                    note: "Ruby/Sapphire tutor move apply remains blocked."
                ),
                PokemonDataCompatibilitySourceTable(
                    path: "references/pokeruby/src/data/pokemon/level_up_learnsets.h",
                    tableSymbol: "g*LevelUpLearnset",
                    indexedCount: 0,
                    status: .blocked,
                    note: "Reference Ruby/Sapphire clones remain read-only research inputs."
                ),
                PokemonDataCompatibilitySourceTable(
                    path: "ROM output",
                    tableSymbol: nil,
                    indexedCount: 0,
                    status: .blocked,
                    note: "Binary ROM/export writes remain blocked."
                )
            ]
        }
        guard profile == .pokeemeraldExpansion else { return nil }
        let localBlockCount = Set(
            sourceIndex.records
                .filter {
                    $0.module == .learnsets
                        && $0.tags.contains("level-up")
                        && isExpansionLevelUpLearnsetSourcePath($0.sourceSpan.relativePath)
                }
                .map { "\($0.sourceSpan.relativePath):\($0.title)" }
        ).count
        let allLearnablesCount = allLearnablesIndexedCount(in: sourceIndex)
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
                path: "src/data/pokemon/level_up_learnsets",
                tableSymbol: "s*LevelUpLearnset",
                indexedCount: max(localBlockCount, editableCount),
                status: sourceStatus,
                note: "Local source-backed Expansion level-up blocks use the species mutation-plan gate only when an existing block span is parsed."
            ),
            expansionAllLearnablesSourceTable(indexedCount: allLearnablesCount, learnablesCoverage: learnablesCoverage),
            PokemonDataCompatibilitySourceTable(
                path: "generated",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Generated learnset outputs remain blocked and must be refreshed outside this mutation plan."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "references/pokeemerald-expansion/src/data/pokemon/level_up_learnsets",
                tableSymbol: "s*LevelUpLearnset",
                indexedCount: 0,
                status: .blocked,
                note: "Reference Expansion clones remain read-only research inputs."
            ),
            modernEmeraldReferenceSourceTable(
                path: "references/modern-emerald/src/data/pokemon/level_up_learnsets.h",
                tableSymbol: "s*LevelUpLearnset",
                note: "Modern Emerald level-up learnsets stay reference-only; learnset writers and generated outputs remain blocked."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "ROM output",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Binary ROM/export writes remain blocked."
            )
        ]
    }

    private static func tmhmLearnsetSourceTables(
        profile: GameProfile,
        sourceIndex: ProjectSourceIndex,
        indexedCount: Int,
        editableCount: Int,
        learnablesCoverage: PokemonLearnablesCoverage? = nil
    ) -> [PokemonDataCompatibilitySourceTable]? {
        guard profile == .pokeemeraldExpansion else { return nil }
        let localRowCount = Set(
            sourceIndex.records
                .filter {
                    $0.module == .learnsets
                        && isExpansionTMHMLearnsetSourcePath($0.sourceSpan.relativePath)
                }
                .map { "\($0.sourceSpan.relativePath):\($0.title)" }
        ).count
        let allLearnablesCount = allLearnablesIndexedCount(in: sourceIndex)
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
                path: "src/data/pokemon/tmhm_learnsets.h",
                tableSymbol: "sTMHMLearnsets/gTMHMLearnsets",
                indexedCount: max(localRowCount, editableCount),
                status: sourceStatus,
                note: "Local source-backed Expansion TM/HM rows use the species mutation-plan gate only when an existing species row span is parsed."
            ),
            expansionAllLearnablesSourceTable(indexedCount: allLearnablesCount, learnablesCoverage: learnablesCoverage),
            PokemonDataCompatibilitySourceTable(
                path: "generated",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Generated learnset outputs remain blocked and must be refreshed outside this mutation plan."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "references/pokeemerald-expansion/src/data/pokemon/tmhm_learnsets.h",
                tableSymbol: "sTMHMLearnsets/gTMHMLearnsets",
                indexedCount: 0,
                status: .blocked,
                note: "Reference Expansion clones remain read-only research inputs."
            ),
            modernEmeraldReferenceSourceTable(
                path: "references/modern-emerald/src/data/pokemon/tmhm_learnsets.h",
                tableSymbol: "gTMHMLearnsets",
                note: "Modern Emerald TM/HM learnsets stay reference-only; compatibility writers and generated outputs remain blocked."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "ROM output",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Binary ROM/export writes remain blocked."
            )
        ]
    }

    private static func tutorLearnsetSourceTables(
        profile: GameProfile,
        sourceIndex: ProjectSourceIndex,
        indexedCount: Int,
        editableCount: Int,
        learnablesCoverage: PokemonLearnablesCoverage? = nil
    ) -> [PokemonDataCompatibilitySourceTable]? {
        guard profile == .pokeruby || profile == .pokeemeraldExpansion else { return nil }
        let sourceStatus: PokemonDataCompatibilityStatus
        if editableCount > 0 {
            sourceStatus = .editable
        } else if indexedCount > 0 {
            sourceStatus = .readOnly
        } else {
            sourceStatus = .blocked
        }
        let familyLabel = profile == .pokeruby ? "Ruby/Sapphire" : "Expansion"
        let tableSymbol = profile == .pokeruby ? "sTutorLearnsets/gTutorLearnsets" : "gTutorLearnsets"
        let referencePath = profile == .pokeruby
            ? "references/pokeruby/src/data/pokemon/tutor_learnsets.h"
            : "references/pokeemerald-expansion/src/data/pokemon/tutor_learnsets.h"
        let allLearnablesSourceTable = profile == .pokeemeraldExpansion
            ? expansionAllLearnablesSourceTable(indexedCount: allLearnablesIndexedCount(in: sourceIndex), learnablesCoverage: learnablesCoverage)
            : PokemonDataCompatibilitySourceTable(
                path: "src/data/pokemon/all_learnables.json",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Generated/all-learnables JSON remains indexed for context and freshness reporting only; apply is blocked and refresh must happen outside PokemonHackStudio."
            )
        var tables = [
            PokemonDataCompatibilitySourceTable(
                path: "src/data/pokemon/tutor_learnsets.h",
                tableSymbol: tableSymbol,
                indexedCount: indexedCount,
                status: sourceStatus,
                note: "Local source-backed \(familyLabel) tutor rows use the species mutation-plan gate only when an existing species row span is parsed."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "include/constants/moves.h",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Move constants, tutor constants, identity changes, and row creation/reordering remain blocked."
            ),
            allLearnablesSourceTable,
            PokemonDataCompatibilitySourceTable(
                path: "generated",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Generated learnset outputs remain blocked and must be refreshed outside this mutation plan."
            ),
            PokemonDataCompatibilitySourceTable(
                path: referencePath,
                tableSymbol: tableSymbol,
                indexedCount: 0,
                status: .blocked,
                note: "Reference \(familyLabel) clones remain read-only research inputs."
            )
        ]
        if profile == .pokeemeraldExpansion {
            tables.append(
                modernEmeraldReferenceSourceTable(
                    path: "references/modern-emerald/src/data/pokemon/tutor_learnsets.h",
                    tableSymbol: "gTutorMoves/s*TutorLearnset",
                    note: "Modern Emerald tutor learnsets stay reference-only; tutor compatibility writers and generated outputs remain blocked."
                )
            )
        }
        tables.append(
            PokemonDataCompatibilitySourceTable(
                path: "ROM output",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Binary ROM/export writes remain blocked."
            )
        )
        return tables
    }

    private static func pokedexSourceTables(
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
                path: "src/data/pokemon/pokedex_entries.h",
                tableSymbol: "gPokedexEntries",
                indexedCount: indexedCount,
                status: sourceStatus,
                note: "Local source-backed Expansion Pokedex rows use the Species mutation-plan gate for existing parsed rows only."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "src/data/pokemon/pokedex_text.h",
                tableSymbol: "g*PokedexText",
                indexedCount: indexedCount,
                status: sourceStatus,
                note: "Local source-backed Expansion Pokedex text declarations use the Species mutation-plan gate for simple existing declarations only."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "generated",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Generated Pokedex outputs remain blocked and must be refreshed outside this mutation plan."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "references/pokeemerald-expansion/src/data/pokemon/pokedex_entries.h",
                tableSymbol: "gPokedexEntries",
                indexedCount: 0,
                status: .blocked,
                note: "Reference Expansion Pokedex entry writes remain blocked."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "references/pokeemerald-expansion/src/data/pokemon/pokedex_text.h",
                tableSymbol: "g*PokedexText",
                indexedCount: 0,
                status: .blocked,
                note: "Reference Expansion Pokedex text writes remain blocked."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "ROM output",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "ROM/export/build outputs and binary Pokedex writes remain blocked."
            )
        ]
    }

    private static func eggMoveSourceTables(
        profile: GameProfile,
        sourceIndex: ProjectSourceIndex,
        indexedCount: Int,
        editableCount: Int,
        learnablesCoverage: PokemonLearnablesCoverage? = nil
    ) -> [PokemonDataCompatibilitySourceTable]? {
        guard profile == .pokeemeraldExpansion else { return nil }
        let localRowCount = Set(
            sourceIndex.records
                .filter {
                    $0.module == .learnsets
                        && isExpansionEggMoveSourcePath($0.sourceSpan.relativePath)
                }
                .map { "\($0.sourceSpan.relativePath):\($0.title)" }
        ).count
        let allLearnablesCount = allLearnablesIndexedCount(in: sourceIndex)
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
                path: "src/data/pokemon/egg_moves.h",
                tableSymbol: "gEggMoves",
                indexedCount: max(localRowCount, editableCount),
                status: sourceStatus,
                note: "Local source-backed Expansion egg-move rows use the species mutation-plan gate only when an existing egg_moves(...) span is parsed."
            ),
            expansionAllLearnablesSourceTable(indexedCount: allLearnablesCount, learnablesCoverage: learnablesCoverage),
            PokemonDataCompatibilitySourceTable(
                path: "generated",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Generated learnset outputs remain blocked and must be refreshed outside this mutation plan."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "references/pokeemerald-expansion/src/data/pokemon/egg_moves.h",
                tableSymbol: "gEggMoves",
                indexedCount: 0,
                status: .blocked,
                note: "Reference Expansion clones remain read-only research inputs."
            ),
            modernEmeraldReferenceSourceTable(
                path: "references/modern-emerald/src/data/pokemon/egg_moves.h",
                tableSymbol: "gEggMoves",
                note: "Modern Emerald egg moves stay reference-only; egg-move writers and generated outputs remain blocked."
            ),
            PokemonDataCompatibilitySourceTable(
                path: "ROM output",
                tableSymbol: nil,
                indexedCount: 0,
                status: .blocked,
                note: "Binary ROM/export writes remain blocked."
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

    private static let expansionAllLearnablesRelatedSourcePaths = [
        "src/data/pokemon/level_up_learnsets.h",
        "src/data/pokemon/level_up_learnsets",
        "src/data/pokemon/tmhm_learnsets.h",
        "src/data/pokemon/tutor_learnsets.h",
        "src/data/pokemon/egg_moves.h"
    ]

    private static let expansionAllLearnablesBlockedActions = [
        "apply",
        "generated output writes",
        "reference writes",
        "ROM/binary writes"
    ]

    private static func allLearnablesIndexedCount(in sourceIndex: ProjectSourceIndex) -> Int {
        Set(
            sourceIndex.records
                .filter {
                    $0.module == .learnsets
                        && $0.tags.contains("all-learnables")
                        && $0.sourceSpan.relativePath == "src/data/pokemon/all_learnables.json"
                }
                .map(\.title)
        ).count
    }

    private static func expansionAllLearnablesSourceTable(
        indexedCount: Int,
        learnablesCoverage: PokemonLearnablesCoverage? = nil
    ) -> PokemonDataCompatibilitySourceTable {
        PokemonDataCompatibilitySourceTable(
            path: "src/data/pokemon/all_learnables.json",
            tableSymbol: nil,
            indexedCount: indexedCount,
            status: .blocked,
            note: "Generated/all-learnables JSON remains indexed for context and freshness reporting only; apply is blocked and refresh must happen outside PokemonHackStudio.",
            sourceRole: "generatedAllLearnablesIndex",
            readiness: "read-only generated context",
            relatedSourcePaths: expansionAllLearnablesRelatedSourcePaths,
            blockedActions: expansionAllLearnablesBlockedActions,
            learnablesCoverage: learnablesCoverage
        )
    }

    private static func isFormCompatibilityRecord(_ record: SourceIndexRecord) -> Bool {
        record.tags.contains("form") && record.tags.contains { tag in
            tag == "form-species-table"
                || tag == "form-change-table"
                || tag == "form-supplement"
        }
    }

    private static func rubyTMHMIndexedCount(
        profile: GameProfile,
        speciesCatalog: ProjectSpeciesCatalog?,
        sourceIndex: ProjectSourceIndex
    ) -> Int {
        guard profile == .pokeruby else { return 0 }
        return speciesCatalog?.species.filter { $0.learnsets.tmhmSourceSpan?.relativePath == "src/data/pokemon/tmhm_learnsets.h" }.count
            ?? learnsetRecordCount(in: sourceIndex, matching: ["tmhm"])
    }

    private static func rubyTMHMEditableCount(
        profile: GameProfile,
        speciesCatalog: ProjectSpeciesCatalog?,
        sourceIndex: ProjectSourceIndex
    ) -> Int {
        let indexed = rubyTMHMIndexedCount(profile: profile, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex)
        return supportsLearnsetMutationEditing(surface: .tmhmLearnsets, profile: profile) && indexed > 0 ? indexed : 0
    }

    private static func rubyTutorIndexedCount(
        profile: GameProfile,
        speciesCatalog: ProjectSpeciesCatalog?,
        sourceIndex: ProjectSourceIndex
    ) -> Int {
        guard profile == .pokeruby || profile == .pokeemeraldExpansion else { return 0 }
        return speciesCatalog?.species.filter { $0.learnsets.tutorSourceSpan?.relativePath == "src/data/pokemon/tutor_learnsets.h" }.count
            ?? learnsetRecordCount(in: sourceIndex, matching: ["tutor"])
    }

    private static func rubyTutorEditableCount(
        profile: GameProfile,
        speciesCatalog: ProjectSpeciesCatalog?,
        sourceIndex: ProjectSourceIndex
    ) -> Int {
        let indexed = rubyTutorIndexedCount(profile: profile, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex)
        return supportsLearnsetMutationEditing(surface: .tutorLearnsets, profile: profile) && indexed > 0 ? indexed : 0
    }

    private static func rubyEggIndexedCount(
        profile: GameProfile,
        speciesCatalog: ProjectSpeciesCatalog?,
        sourceIndex: ProjectSourceIndex
    ) -> Int {
        guard profile == .pokeruby else { return 0 }
        return speciesCatalog?.species.filter { !$0.learnsets.egg.isEmpty }.count
            ?? learnsetRecordCount(in: sourceIndex, matching: ["egg"])
    }

    private static func rubyEggEditableCount(
        profile: GameProfile,
        speciesCatalog: ProjectSpeciesCatalog?,
        sourceIndex: ProjectSourceIndex
    ) -> Int {
        let indexed = rubyEggIndexedCount(profile: profile, speciesCatalog: speciesCatalog, sourceIndex: sourceIndex)
        return supportsLearnsetMutationEditing(surface: .eggMoves, profile: profile) && indexed > 0 ? indexed : 0
    }

    private static func formDiagnostics(records: [SourceIndexRecord], editableCount: Int) -> [Diagnostic] {
        guard !records.isEmpty else { return [] }
        if editableCount > 0 {
            return [
                Diagnostic(
                    severity: .info,
                    code: "GBA_FORMS_SOURCE_GRAPH_DETECTED",
                    message: "Detected \(records.count) form source graph record(s); local Expansion form table rows can edit through Species mutation plans while adjacent form workflows remain blocked.",
                    span: records.first?.sourceSpan
                ),
                Diagnostic(
                    severity: .warning,
                    code: "GBA_FORMS_ADJACENT_WORKFLOWS_BLOCKED",
                    message: "Form row insertion/reorder, graphics sync, generated supplement apply, reference writes, builds, ROM export, and binary writes remain blocked.",
                    span: records.first?.sourceSpan
                )
            ]
        }
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

    private static func modernEmeraldReferenceSourceTable(
        path: String,
        tableSymbol: String?,
        note: String
    ) -> PokemonDataCompatibilitySourceTable {
        PokemonDataCompatibilitySourceTable(
            path: path,
            tableSymbol: tableSymbol,
            indexedCount: 0,
            status: .blocked,
            note: note,
            sourceRole: "referenceOnly",
            recommendedFutureRow: "PHS-T78"
        )
    }

    private static func modernEmeraldUnsupportedDiagnostics(
        surface: PokemonDataCompatibilitySurface,
        profile: GameProfile
    ) -> [Diagnostic] {
        guard profile == .pokeemeraldExpansion else { return [] }
        switch surface {
        case .species:
            return [
                Diagnostic(
                    severity: .info,
                    code: "GBA_MODERN_EMERALD_SPECIES_UNSUPPORTED",
                    message: "Modern Emerald species paths under references/modern-emerald are reference-only schema pressure for PHS-T78; source writes, generated outputs, ROM/export/build outputs, and binary writes remain blocked.",
                    span: SourceSpan(relativePath: "references/modern-emerald/src/data/pokemon/species_info.h", startLine: 1)
                )
            ]
        case .moves:
            return [
                Diagnostic(
                    severity: .info,
                    code: "GBA_MODERN_EMERALD_MOVES_UNSUPPORTED",
                    message: "Modern Emerald move and compatibility paths under references/modern-emerald are reference-only schema pressure for PHS-T78; move writers, generated outputs, ROM/export/build outputs, and binary writes remain blocked.",
                    span: SourceSpan(relativePath: "references/modern-emerald/src/data/battle_moves.h", startLine: 1)
                )
            ]
        case .items:
            return [
                Diagnostic(
                    severity: .info,
                    code: "GBA_MODERN_EMERALD_ITEMS_UNSUPPORTED",
                    message: "Modern Emerald item, constant, and graphics metadata paths under references/modern-emerald are reference-only schema pressure for PHS-T78; item writers, generated outputs, ROM/export/build outputs, and binary writes remain blocked.",
                    span: SourceSpan(relativePath: "references/modern-emerald/src/data/items.h", startLine: 1)
                )
            ]
        default:
            return []
        }
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

    private static func rubyContestMoveRecordCount(profile: GameProfile, in sourceIndex: ProjectSourceIndex) -> Int {
        guard profile == .pokeruby else { return 0 }
        return sourceIndex.records.filter { record in
            record.module == .moves
                && record.sourceSpan.relativePath == "src/data/contest_moves.h"
                && record.title != "MOVE_NONE"
        }.count
    }

    private static func itemMetadataFactCount(in sourceIndex: ProjectSourceIndex) -> Int {
        sourceIndex.records.filter { record in
            guard record.module == .items else { return false }
            let labels = Set(record.facts.map(\.label))
            return labels.contains("effect")
                || labels.contains("iconPic")
                || labels.contains("iconPalette")
        }.count
    }

    private static func itemBehaviorScalarFactCount(in sourceIndex: ProjectSourceIndex) -> Int {
        sourceIndex.records.filter { record in
            guard record.module == .items else { return false }
            let labels = Set(record.facts.map(\.label))
            return labels.contains("fieldUseFunc")
                || labels.contains("battleUsage")
                || labels.contains("battleUseFunc")
                || labels.contains("secondaryId")
        }.count
    }

    private static func itemUsageScalarFactCount(in sourceIndex: ProjectSourceIndex) -> Int {
        sourceIndex.records.filter { record in
            guard record.module == .items else { return false }
            let labels = Set(record.facts.map(\.label))
            return labels.contains("holdEffect")
                || labels.contains("holdEffectParam")
                || labels.contains("pocket")
                || labels.contains("type")
        }.count
    }

    private static func itemBagClassificationScalarFactCount(in sourceIndex: ProjectSourceIndex) -> Int {
        sourceIndex.records.filter { record in
            guard record.module == .items else { return false }
            let labels = Set(record.facts.map(\.label))
            return labels.contains("importance")
                || labels.contains("registrability")
                || labels.contains("sortType")
                || labels.contains("exitsBagOnUse")
        }.count
    }

    private static func learnsetRecordCount(in sourceIndex: ProjectSourceIndex, matching tokens: [String]) -> Int {
        sourceIndex.records.filter { record in
            guard record.module == .learnsets else { return false }
            let path = record.sourceSpan.relativePath.lowercased()
            return tokens.contains { path.contains($0) }
        }.count
    }

    private static func expansionLearnsetGeneratedStalenessDiagnostics(
        surface: PokemonDataCompatibilitySurface,
        index: ProjectIndex,
        fileManager: FileManager
    ) -> [Diagnostic] {
        guard index.profile == .pokeemeraldExpansion,
              [.levelUpLearnsets, .tmhmLearnsets, .eggMoves, .tutorLearnsets].contains(surface)
        else {
            return []
        }

        let generatedPath = "src/data/pokemon/all_learnables.json"
        let root = URL(fileURLWithPath: index.root.path)
        guard let generatedModifiedAt = modificationDate(for: generatedPath, root: root, fileManager: fileManager) else {
            return []
        }

        let staleSources = learnsetSourcePaths(for: surface, root: root, fileManager: fileManager)
            .compactMap { path -> (path: String, modifiedAt: Date)? in
                guard let modifiedAt = modificationDate(for: path, root: root, fileManager: fileManager),
                      modifiedAt > generatedModifiedAt
                else {
                    return nil
                }
                return (path, modifiedAt)
            }
            .sorted { lhs, rhs in
                if lhs.modifiedAt == rhs.modifiedAt {
                    return lhs.path < rhs.path
                }
                return lhs.modifiedAt > rhs.modifiedAt
            }

        guard let newest = staleSources.first else { return [] }
        let surfaceLabel: String
        switch surface {
        case .levelUpLearnsets:
            surfaceLabel = "Expansion level-up learnset"
        case .tmhmLearnsets:
            surfaceLabel = "Expansion TM/HM learnset"
        case .eggMoves:
            surfaceLabel = "Expansion egg-move"
        case .tutorLearnsets:
            surfaceLabel = "Expansion tutor learnset"
        default:
            surfaceLabel = "Expansion learnset"
        }
        let suffix = staleSources.count == 1 ? "" : " and \(staleSources.count - 1) other source file(s)"
        return [
            Diagnostic(
                severity: .warning,
                code: "GBA_EXPANSION_LEARNSET_GENERATED_STALE",
                message: "\(surfaceLabel) source \(newest.path)\(suffix) is newer than \(generatedPath); refresh generated learnset artifacts outside PokemonHackStudio before relying on generated learnables.",
                span: SourceSpan(relativePath: newest.path, startLine: 1)
            )
        ]
    }

    private static func learnsetSourcePaths(
        for surface: PokemonDataCompatibilitySurface,
        root: URL,
        fileManager: FileManager
    ) -> [String] {
        switch surface {
        case .levelUpLearnsets:
            var paths = ["src/data/pokemon/level_up_learnsets.h"].filter {
                fileManager.fileExists(atPath: root.appendingPathComponent($0).path)
            }
            let directoryPath = "src/data/pokemon/level_up_learnsets"
            let directory = root.appendingPathComponent(directoryPath)
            if let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) {
                for case let url as URL in enumerator {
                    guard url.pathExtension.lowercased() == "h",
                          (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true
                    else {
                        continue
                    }
                    paths.append(relativePath(for: url, root: root))
                }
            }
            return Array(Set(paths)).sorted()
        case .tmhmLearnsets:
            return ["src/data/pokemon/tmhm_learnsets.h"].filter {
                fileManager.fileExists(atPath: root.appendingPathComponent($0).path)
            }
        case .eggMoves:
            return ["src/data/pokemon/egg_moves.h"].filter {
                fileManager.fileExists(atPath: root.appendingPathComponent($0).path)
            }
        case .tutorLearnsets:
            return ["src/data/pokemon/tutor_learnsets.h"].filter {
                fileManager.fileExists(atPath: root.appendingPathComponent($0).path)
            }
        default:
            return []
        }
    }

    private static func modificationDate(for relativePath: String, root: URL, fileManager: FileManager) -> Date? {
        let path = root.appendingPathComponent(relativePath).path
        return (try? fileManager.attributesOfItem(atPath: path)[.modificationDate]) as? Date
    }

    private static func existingPaths(_ paths: [String], root: String, fileManager: FileManager) -> [String] {
        let rootURL = URL(fileURLWithPath: root)
        return paths.filter { fileManager.fileExists(atPath: rootURL.appendingPathComponent($0).path) }
    }

    private static func cryAudioPlan(index: ProjectIndex, fileManager: FileManager) -> GBACryAudioMutationPlan {
        let sourceFiles = GBACryAudioSourceFileScanner.sourceFiles(rootPath: index.root.path, fileManager: fileManager)
        let candidateSourcePaths = GBACryAudioSourceFileScanner.candidateSourcePaths
        let isRubySapphire = index.profile == .pokeruby
        let replacementConstraints = [
            isRubySapphire
                ? "Replacement must target an existing local Ruby/Sapphire source file reported in sourceFiles."
                : "Replacement is future-only and must target an existing local source file reported in sourceFiles.",
            "Replacement must be one-for-one with the same project-relative path and source kind.",
            "Missing cry source insertion and directory creation are disabled.",
            isRubySapphire
                ? "Generated audio outputs, build artifacts, ROM targets, binary mutation, playback, source generation, reference writes, and broad audio schema rewrites are disabled."
                : "Generated audio outputs, build artifacts, ROM targets, binary mutation, playback, and source mutation apply are disabled."
        ]
        let blockedActions = isRubySapphire ? GBACryAudioReplacementValidator.blockedActions : [
            "Audio conversion",
            "Generated audio output writes",
            "Playback",
            "ROM export",
            "Binary mutation",
            "Source mutation apply"
        ]
        let replacementGate = GBACryAudioReplacementGate(
            status: sourceFiles.isEmpty ? .blocked : (isRubySapphire ? .editable : .readOnly),
            summary: sourceFiles.isEmpty
                ? "No existing local GBA cry/audio source files are available for replacement review."
                : (isRubySapphire
                    ? "Existing local Ruby/Sapphire cry/audio source files may be replaced one-for-one through the Pokemon mutation-plan review gate."
                    : "Existing GBA cry/audio source files are reported for preview only; replacement apply is not enabled for this profile."),
            targetPaths: sourceFiles.map(\.path),
            blockedActions: blockedActions,
            diagnostics: []
        )
        if sourceFiles.isEmpty {
            let blockedReasons = [
                "No existing local files matched sound/direct_sound_samples/cries/*.",
                "No existing local files matched sound/songs/mus_cry*.s or sound/songs/mus_cry*.inc."
            ]
            return GBACryAudioMutationPlan(
                status: .blocked,
                summary: "No mutation plan is available because no explicit local GBA cry source files were found.",
                candidateSourcePaths: candidateSourcePaths,
                sourceFiles: [],
                replacementConstraints: replacementConstraints,
                blockedReasons: blockedReasons,
                plannedChanges: [],
                blockedActions: blockedActions,
                replacementGate: replacementGate,
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
        let summary = isRubySapphire
            ? "Detected \(previewCount) for source-backed Ruby/Sapphire GBA cry/audio review. One-for-one source replacement can be staged through a Pokemon mutation plan; conversion, generated outputs, playback, ROM export, binary mutation, reference writes, and broad audio schema rewrites remain disabled."
            : "Detected \(previewCount) for source-backed GBA cry/audio review. Replacement, conversion, generated outputs, playback, ROM export, binary mutation, and source mutation apply remain disabled."
        let plannedChanges = isRubySapphire
            ? [
                "Review existing cry source provenance, size, and SHA1 before staging a replacement.",
                "Stage only one-for-one source-file replacement through a Pokemon mutation plan.",
                "Keep generated audio artifacts and ROM output unchanged."
            ]
            : [
                "Review existing cry source provenance, size, and SHA1 before any future edit.",
                "Stage only one-for-one source-file replacement after a dedicated cry import row defines validation.",
                "Keep generated audio artifacts and ROM output unchanged."
            ]
        let diagnosticCode = isRubySapphire ? "GBA_CRY_AUDIO_REPLACEMENT_GATE_EDITABLE" : "GBA_CRY_AUDIO_PLAN_PREVIEW_ONLY"
        let diagnosticMessage = isRubySapphire
            ? "Detected explicit local Ruby/Sapphire GBA cry/audio source files; one-for-one replacement may be reviewed through the Pokemon mutation-plan gate without conversion, generated audio, or ROM output."
            : "Detected explicit local GBA cry/audio source files; this row reports diagnostics and a preview-only mutation plan without writing source, generated audio, or ROM output."
        return GBACryAudioMutationPlan(
            status: .previewOnly,
            summary: summary,
            candidateSourcePaths: candidateSourcePaths,
            sourceFiles: sourceFiles,
            replacementConstraints: replacementConstraints,
            blockedReasons: [],
            plannedChanges: plannedChanges,
            blockedActions: blockedActions,
            replacementGate: replacementGate,
            diagnostics: [
                Diagnostic(
                    severity: .info,
                    code: diagnosticCode,
                    message: diagnosticMessage,
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
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/pokemon/base_stats.h", tableSymbol: "gBaseStats", supportsEditing: true, readOnlyReason: nil, recommendedFutureRow: nil)
        case .pokeemeraldExpansion:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/pokemon/species_info.h", tableSymbol: "gSpeciesInfo", supportsEditing: true, readOnlyReason: nil, recommendedFutureRow: nil)
        default:
            return nil
        }
    case .moves:
        switch profile {
        case .pokeemerald, .pokefirered:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/battle_moves.h", tableSymbol: "gBattleMoves", supportsEditing: true, readOnlyReason: nil, recommendedFutureRow: nil)
        case .pokeruby:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/battle_moves.c", tableSymbol: "gBattleMoves", supportsEditing: true, readOnlyReason: nil, recommendedFutureRow: nil)
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
            let supportsEditing = supportsLearnsetMutationEditing(surface: .levelUpLearnsets, profile: profile)
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/pokemon/level_up_learnsets.h", tableSymbol: "gLevelUpLearnsets", supportsEditing: supportsEditing, readOnlyReason: "Learnset edits are currently tied to source-backed species mutation plans.", recommendedFutureRow: supportsEditing ? nil : "PHS-T57")
        case .pokeemeraldExpansion:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/pokemon/level_up_learnsets", tableSymbol: "s*LevelUpLearnset", supportsEditing: true, readOnlyReason: nil, recommendedFutureRow: nil)
        default:
            return nil
        }
    case .tmhmLearnsets:
        if profile == .pokeemeraldExpansion {
            let supportsEditing = supportsLearnsetMutationEditing(surface: .tmhmLearnsets, profile: profile)
            return PokemonDataSurfaceDescriptor(
                sourcePath: "src/data/pokemon/tmhm_learnsets.h",
                tableSymbol: "sTMHMLearnsets/gTMHMLearnsets",
                supportsEditing: supportsEditing,
                readOnlyReason: supportsEditing ? nil : "TM/HM edits are currently tied to source-backed species mutation plans.",
                recommendedFutureRow: supportsEditing ? nil : "PHS-T78G"
            )
        }
        return pokemonTableDescriptor(profile: profile, path: "src/data/pokemon/tmhm_learnsets.h", emeraldTable: "gTMHMLearnsets", fireRedTable: "sTMHMLearnsets", rubyTable: "gTMHMLearnsets", expansionTable: "sTMHMLearnsets", supportsEditing: supportsLearnsetMutationEditing(surface: .tmhmLearnsets, profile: profile))
    case .eggMoves:
        if profile == .pokeemeraldExpansion {
            let supportsEditing = supportsLearnsetMutationEditing(surface: .eggMoves, profile: profile)
            return PokemonDataSurfaceDescriptor(
                sourcePath: "src/data/pokemon/egg_moves.h",
                tableSymbol: "gEggMoves",
                supportsEditing: supportsEditing,
                readOnlyReason: supportsEditing ? nil : "Egg-move edits are currently tied to source-backed species mutation plans.",
                recommendedFutureRow: supportsEditing ? nil : "PHS-T78J"
            )
        }
        return pokemonTableDescriptor(profile: profile, path: "src/data/pokemon/egg_moves.h", emeraldTable: "gEggMoves", fireRedTable: "gEggMoves", rubyTable: "gEggMoves", expansionTable: "gEggMoves", supportsEditing: supportsLearnsetMutationEditing(surface: .eggMoves, profile: profile))
    case .evolutions:
        return pokemonTableDescriptor(profile: profile, path: "src/data/pokemon/evolution.h", emeraldTable: "gEvolutionTable", fireRedTable: "gEvolutionTable", rubyTable: "gEvolutionTable", expansionTable: "gEvolutionTable", supportsEditing: supportsEvolutionMutationEditing(profile))
    case .pokedex:
        switch profile {
        case .pokeruby:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/pokedex_entries_en.h", tableSymbol: "gPokedexEntries", supportsEditing: true, readOnlyReason: nil, recommendedFutureRow: nil)
        case .pokeemeraldExpansion:
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/pokemon/pokedex_entries.h", tableSymbol: "gPokedexEntries", supportsEditing: true, readOnlyReason: nil, recommendedFutureRow: nil)
        default:
            return pokemonTableDescriptor(profile: profile, path: "src/data/pokemon/pokedex_entries.h", emeraldTable: "gPokedexEntries", fireRedTable: "gPokedexEntries", rubyTable: "gPokedexEntries", expansionTable: "gPokedexEntries", supportsEditing: supportsClassicSpeciesMutationEditing(profile))
        }
    case .tutorLearnsets:
        if profile == .pokeruby {
            return PokemonDataSurfaceDescriptor(
                sourcePath: "src/data/pokemon/tutor_learnsets.h",
                tableSymbol: "sTutorLearnsets/gTutorLearnsets",
                supportsEditing: supportsLearnsetMutationEditing(surface: .tutorLearnsets, profile: profile),
                readOnlyReason: nil,
                recommendedFutureRow: nil
            )
        }
        if profile == .pokeemeraldExpansion {
            return PokemonDataSurfaceDescriptor(
                sourcePath: "src/data/pokemon/tutor_learnsets.h",
                tableSymbol: "gTutorLearnsets",
                supportsEditing: supportsLearnsetMutationEditing(surface: .tutorLearnsets, profile: profile),
                readOnlyReason: nil,
                recommendedFutureRow: nil
            )
        }
        return pokemonTableDescriptor(profile: profile, path: "src/data/pokemon/tutor_learnsets.h", emeraldTable: "gTutorLearnsets", fireRedTable: "gTutorLearnsets", rubyTable: nil, expansionTable: "gTutorLearnsets", supportsEditing: supportsClassicSpeciesMutationEditing(profile))
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
            return PokemonDataSurfaceDescriptor(sourcePath: "src/data/pokemon/form_species_tables.h", tableSymbol: "FormSpeciesIdTable/FormChangeTable", supportsEditing: true, readOnlyReason: nil, recommendedFutureRow: nil)
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
        return PokemonDataSurfaceDescriptor(sourcePath: path, tableSymbol: rubyTable, supportsEditing: supportsEditing, readOnlyReason: supportsEditing ? nil : readOnlyReason ?? "Surface is not editable for this profile.", recommendedFutureRow: supportsEditing ? nil : futureRow)
    case .pokeemeraldExpansion:
        return PokemonDataSurfaceDescriptor(sourcePath: path, tableSymbol: expansionTable, supportsEditing: false, readOnlyReason: readOnlyReason, recommendedFutureRow: futureRow)
    default:
        return nil
    }
}

private func supportsSpeciesBaseStatsEditing(_ profile: GameProfile) -> Bool {
    profile == .pokeemerald || profile == .pokefirered || profile == .pokeruby || profile == .pokeemeraldExpansion
}

private func supportsClassicSpeciesMutationEditing(_ profile: GameProfile) -> Bool {
    profile == .pokeemerald || profile == .pokefirered
}

private func supportsPokedexMutationEditing(_ profile: GameProfile) -> Bool {
    supportsClassicSpeciesMutationEditing(profile) || profile == .pokeruby || profile == .pokeemeraldExpansion
}

private func supportsEvolutionMutationEditing(_ profile: GameProfile) -> Bool {
    supportsClassicSpeciesMutationEditing(profile) || profile == .pokeruby || profile == .pokeemeraldExpansion
}

private func supportsLearnsetMutationEditing(surface: PokemonDataCompatibilitySurface, profile: GameProfile) -> Bool {
    switch surface {
    case .levelUpLearnsets:
        return supportsClassicSpeciesMutationEditing(profile) || profile == .pokeruby || profile == .pokeemeraldExpansion
    case .tmhmLearnsets:
        return supportsClassicSpeciesMutationEditing(profile) || profile == .pokeruby || profile == .pokeemeraldExpansion
    case .eggMoves:
        return supportsClassicSpeciesMutationEditing(profile) || profile == .pokeruby || profile == .pokeemeraldExpansion
    case .tutorLearnsets:
        return supportsClassicSpeciesMutationEditing(profile) || profile == .pokeruby || profile == .pokeemeraldExpansion
    default:
        return false
    }
}

private func isExpansionLevelUpLearnsetSourcePath(_ path: String) -> Bool {
    path == "src/data/pokemon/level_up_learnsets.h"
        || path.hasPrefix("src/data/pokemon/level_up_learnsets/")
}

private func isExpansionTMHMLearnsetSourcePath(_ path: String?) -> Bool {
    path == "src/data/pokemon/tmhm_learnsets.h"
}

private func isExpansionEggMoveSourcePath(_ path: String?) -> Bool {
    path == "src/data/pokemon/egg_moves.h"
}

private func evolutionUnsupportedFields(profile: GameProfile, editableCount: Int) -> [String] {
    if profile == .pokeemeraldExpansion {
        return editableCount > 0
            ? [
                "evolution row insertion/removal/reorder",
                "evolution method constant creation",
                "species constant/identity changes",
                "generated evolution output writes",
                "reference-only evolution source writes",
                "ROM/export/build outputs",
                "binary ROM evolution writes"
            ]
            : [
                "evolution method edits",
                "target species edits",
                "parameter edits",
                "evolution row insertion/removal/reorder",
                "generated/reference/ROM evolution writes"
            ]
    }
    return editableCount > 0
        ? ["missing evolution row insertion"]
        : ["evolution method edits", "target species edits", "parameter edits", "evolution row insertion/reordering"]
}

private func speciesUnsupportedFields(profile: GameProfile) -> [String] {
    var fields = ["species identity changes", "new/reordered species constants", "asset/cries/form rewrites"]
    if !supportsSpeciesBaseStatsEditing(profile), profile != .pokeemeraldExpansion {
        fields.append("pokedex text rewrites")
    }
    if profile == .pokeruby {
        fields.append(contentsOf: [
            "tutor learnset rewrites"
        ])
    }
    if profile == .pokeemeraldExpansion {
        fields.append(contentsOf: [
            "type/ability/egg group brace-list rewrites",
            "TM/HM/egg move rewrites",
            "evolution row insertion/removal/reorder",
            "species asset/cries/form rewrites",
            "include/config/species_enabled.h rewrites",
            "include/config/pokemon.h rewrites",
            "generated species family supplement apply",
            "generated species output writes",
            "reference-only species source writes",
            "Modern Emerald species writers",
            "binary ROM species writes",
            "broad Expansion species schema rewrites"
        ])
    }
    return fields
}

private func pokedexUnsupportedFields(profile: GameProfile, editableCount: Int) -> [String] {
    if editableCount <= 0 {
        return ["category text edits", "height/weight edits", "description text rewrites", "national dex identity changes"]
    }
    var fields = ["national dex identity changes", "missing Pokedex row insertion"]
    if profile == .pokeemeraldExpansion {
        fields.append(contentsOf: [
            "generated Pokedex output writes",
            "reference-only Pokedex source writes",
            "ROM/export/build outputs",
            "binary-only Pokedex writes",
            "broad Expansion Pokedex schema rewrites"
        ])
    }
    return fields
}

private func movesUnsupportedFields(profile: GameProfile) -> [String] {
    var fields = ["new/reordered move constants"]
    if profile == .pokeruby {
        fields.append("missing or non-simple contest combo arrays and non-simple contest scalar expressions")
    } else if profile == .pokeemeraldExpansion {
        fields.append(contentsOf: [
            "gMovesInfo non-simple contest scalar expressions",
            "gMovesInfo non-simple contest combo move arrays"
        ])
    } else {
        fields.append("contest data")
    }
    if profile != .pokeemeraldExpansion && profile != .pokeruby {
        fields.append("description text rewrites")
    }
    if profile == .pokeruby {
        fields.append(contentsOf: [
            "TM/HM item mapping edits",
            "machine constant creation",
            "missing TM/HM row insertion",
            "tutor constant creation",
            "missing tutor row insertion"
        ])
    } else if profile != .pokeemeraldExpansion && !supportsClassicSpeciesMutationEditing(profile) {
        fields.append("TM/HM/tutor compatibility edits")
    }
    if profile == .pokeruby {
        fields.append(contentsOf: [
            "generated move output writes",
            "reference-only move source writes",
            "binary ROM move writes",
            "broad Ruby/Sapphire move schema rewrites"
        ])
    }
    if profile == .pokeemeraldExpansion {
        fields.append(contentsOf: [
            "non-source-backed move description rewrites",
            "gMovesInfo non-simple flags expressions",
            "TM/HM compatibility edits from move row plans",
            "egg compatibility edits from move row plans",
            "tutor constant creation",
            "missing tutor row insertion",
            "generated all_learnables.json writes",
            "generated move output writes",
            "reference-only move source writes",
            "Modern Emerald move writers",
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
        return ["item identity changes", "new/reordered item constants", "TM/HM item compatibility edits"]
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
        fields = ["learnset symbol renames", "shared learnset extraction", "missing learnset block insertion"]
    case .tmhmLearnsets:
        fields = ["TM/HM item mapping edits", "machine constant creation"]
        if !supportsLearnsetMutationEditing(surface: surface, profile: profile) {
            fields.append("compatibility matrix bulk edits")
        }
    case .eggMoves:
        fields = ["egg move family reshaping", "cross-species egg move validation", "missing egg-move species row insertion"]
    case .tutorLearnsets:
        fields = ["learnset symbol renames", "tutor constant creation", "missing tutor row insertion"]
    default:
        fields = []
    }
    if profile == .pokeemeraldExpansion {
        switch surface {
        case .levelUpLearnsets:
            fields.append(contentsOf: [
                "all_learnables.json apply",
                "generated learnset output writes",
                "reference-only learnset source writes",
                "binary ROM learnset writes"
            ])
        case .tmhmLearnsets:
            fields.append(contentsOf: [
                "missing TM/HM row insertion",
                "all_learnables.json apply",
                "generated learnset output writes",
                "reference-only learnset source writes",
                "binary ROM learnset writes"
            ])
        case .tutorLearnsets:
            fields.append(contentsOf: [
                "all_learnables.json apply",
                "generated learnset output writes",
                "reference-only learnset source writes",
                "binary ROM learnset writes"
            ])
        case .eggMoves:
            fields.append(contentsOf: [
                "all_learnables.json apply",
                "generated learnset output writes",
                "reference-only learnset source writes",
                "binary ROM learnset writes",
                "broad Expansion egg-move schema rewrites"
            ])
        default:
            fields.append("Expansion generated learnable JSON apply")
        }
    }
    if profile == .pokeruby {
        switch surface {
        case .levelUpLearnsets:
            fields.append(contentsOf: [
                "generated learnset output writes",
                "reference-only learnset source writes",
                "binary ROM learnset writes"
            ])
        case .tmhmLearnsets:
            fields.append(contentsOf: [
                "missing TM/HM row insertion",
                "generated learnset output writes",
                "reference-only learnset source writes",
                "binary ROM learnset writes"
            ])
        case .eggMoves:
            fields.append(contentsOf: [
                "generated learnset output writes",
                "reference-only learnset source writes",
                "binary ROM learnset writes",
                "broad Ruby/Sapphire egg-move schema rewrites"
            ])
        case .tutorLearnsets:
            fields.append(contentsOf: [
                "generated learnset output writes",
                "reference-only learnset source writes",
                "binary ROM learnset writes",
                "broad Ruby/Sapphire tutor schema rewrites"
            ])
        default:
            break
        }
    }
    return fields
}
