import Foundation

public enum NDSDataDomain: String, Codable, Equatable, CaseIterable, Sendable {
    case species
    case personal
    case moves
    case items
    case trainers
    case encounters
    case text
    case scripts
    case maps
    case audio
    case resources
}

public enum NDSDataSourceRole: String, Codable, Equatable, CaseIterable, Sendable {
    case sourceTree
    case generatedReference
    case nitroFSManifest
    case binaryContainer
    case metadataUnavailable
}

public enum NDSDataSourceFormat: String, Codable, Equatable, Hashable, CaseIterable, Sendable {
    case json
    case csv
    case cSource
    case cHeader
    case narc
    case binary
    case directory
    case text
    case unknown
}

public enum NDSDataContainerKind: String, Codable, Equatable, CaseIterable, Sendable {
    case narc
    case unpackedArchiveDirectory
}

public enum NDSDataContainerMemberPreviewStatus: String, Codable, Equatable, CaseIterable, Sendable {
    case ready
    case blocked
}

public struct NDSDataContainerMemberPreview: Codable, Equatable {
    public let status: NDSDataContainerMemberPreviewStatus
    public let format: String
    public let summary: String
    public let blockedActions: [String]
    public let diagnostics: [Diagnostic]

    public init(
        status: NDSDataContainerMemberPreviewStatus,
        format: String,
        summary: String,
        blockedActions: [String] = [],
        diagnostics: [Diagnostic] = []
    ) {
        self.status = status
        self.format = format
        self.summary = summary
        self.blockedActions = blockedActions
        self.diagnostics = diagnostics
    }
}

public struct NDSDataContainerMemberFingerprint: Codable, Equatable, Identifiable {
    public var id: String { "\(memberIndex):\(path)" }

    public let memberIndex: Int
    public let path: String
    public let byteCount: UInt64?
    public let fileExtension: String?
    public let leadingMagicHex: String?
    public let leadingMagicASCII: String?
    public let formatHint: String
    public let compressionHint: String
    public let confidence: String
    public let preview: NDSDataContainerMemberPreview?
    public let diagnostics: [Diagnostic]

    public init(
        memberIndex: Int,
        path: String,
        byteCount: UInt64?,
        fileExtension: String?,
        leadingMagicHex: String?,
        leadingMagicASCII: String?,
        formatHint: String,
        compressionHint: String,
        confidence: String,
        preview: NDSDataContainerMemberPreview? = nil,
        diagnostics: [Diagnostic] = []
    ) {
        self.memberIndex = memberIndex
        self.path = path
        self.byteCount = byteCount
        self.fileExtension = fileExtension
        self.leadingMagicHex = leadingMagicHex
        self.leadingMagicASCII = leadingMagicASCII
        self.formatHint = formatHint
        self.compressionHint = compressionHint
        self.confidence = confidence
        self.preview = preview
        self.diagnostics = diagnostics
    }
}

public struct NDSDataContainerSummary: Codable, Equatable {
    public let kind: NDSDataContainerKind
    public let memberCount: Int
    public let namedMemberCount: Int
    public let unnamedMemberCount: Int
    public let byteCount: UInt64?
    public let sampleMemberPaths: [String]
    public let memberFingerprints: [NDSDataContainerMemberFingerprint]
    public let isReadOnly: Bool
    public let diagnostics: [Diagnostic]

    public init(
        kind: NDSDataContainerKind,
        memberCount: Int,
        namedMemberCount: Int,
        unnamedMemberCount: Int,
        byteCount: UInt64?,
        sampleMemberPaths: [String],
        memberFingerprints: [NDSDataContainerMemberFingerprint] = [],
        isReadOnly: Bool = true,
        diagnostics: [Diagnostic] = []
    ) {
        self.kind = kind
        self.memberCount = memberCount
        self.namedMemberCount = namedMemberCount
        self.unnamedMemberCount = unnamedMemberCount
        self.byteCount = byteCount
        self.sampleMemberPaths = sampleMemberPaths
        self.memberFingerprints = memberFingerprints
        self.isReadOnly = isReadOnly
        self.diagnostics = diagnostics
    }
}

public struct NDSDataDomainCount: Codable, Equatable, Identifiable {
    public var id: String { domain.rawValue }

    public let domain: NDSDataDomain
    public let count: Int

    public init(domain: NDSDataDomain, count: Int) {
        self.domain = domain
        self.count = count
    }
}

public struct NDSDataCatalogSummary: Codable, Equatable {
    public let recordCount: Int
    public let domainCounts: [NDSDataDomainCount]
    public let sourceBackedCount: Int
    public let nitroFSBackedCount: Int
    public let missingExpectedCount: Int

    public init(
        recordCount: Int,
        domainCounts: [NDSDataDomainCount],
        sourceBackedCount: Int,
        nitroFSBackedCount: Int,
        missingExpectedCount: Int
    ) {
        self.recordCount = recordCount
        self.domainCounts = domainCounts
        self.sourceBackedCount = sourceBackedCount
        self.nitroFSBackedCount = nitroFSBackedCount
        self.missingExpectedCount = missingExpectedCount
    }
}

public enum NDSDataReadinessStatus: String, Codable, Equatable, CaseIterable, Sendable {
    case ready
    case partial
    case blocked
}

public struct NDSDataRelatedRecord: Codable, Equatable, Identifiable, Sendable {
    public var id: String { recordID }

    public let recordID: String
    public let label: String
    public let domain: NDSDataDomain
    public let relativePath: String

    public init(recordID: String, label: String, domain: NDSDataDomain, relativePath: String) {
        self.recordID = recordID
        self.label = label
        self.domain = domain
        self.relativePath = relativePath
    }
}

public struct NDSDataReadinessSummary: Codable, Equatable, Sendable {
    public let status: NDSDataReadinessStatus
    public let title: String
    public let detail: String
    public let blockedActions: [String]

    public init(status: NDSDataReadinessStatus, title: String, detail: String, blockedActions: [String] = []) {
        self.status = status
        self.title = title
        self.detail = detail
        self.blockedActions = blockedActions
    }
}

public enum NDSDataTextBankPreviewStatus: String, Codable, Equatable, CaseIterable {
    case ready
    case blocked
}

public struct NDSDataTextBankPreview: Codable, Equatable {
    public let status: NDSDataTextBankPreviewStatus
    public let format: String
    public let decodedStringCount: Int
    public let sampleStrings: [String]
    public let blockedActions: [String]
    public let diagnostics: [Diagnostic]

    public init(
        status: NDSDataTextBankPreviewStatus,
        format: String,
        decodedStringCount: Int,
        sampleStrings: [String],
        blockedActions: [String],
        diagnostics: [Diagnostic] = []
    ) {
        self.status = status
        self.format = format
        self.decodedStringCount = decodedStringCount
        self.sampleStrings = sampleStrings
        self.blockedActions = blockedActions
        self.diagnostics = diagnostics
    }
}

public enum NDSDataMigrationPlanStatus: String, Codable, Equatable, CaseIterable {
    case previewOnly
    case blocked
}

public struct NDSDataMigrationPlan: Codable, Equatable {
    public let status: NDSDataMigrationPlanStatus
    public let sourceTreeCandidates: [String]
    public let extractedDirectoryCandidates: [String]
    public let unsupportedSteps: [String]
    public let blockedActions: [String]
    public let diagnostics: [Diagnostic]

    public init(
        status: NDSDataMigrationPlanStatus,
        sourceTreeCandidates: [String],
        extractedDirectoryCandidates: [String],
        unsupportedSteps: [String],
        blockedActions: [String],
        diagnostics: [Diagnostic] = []
    ) {
        self.status = status
        self.sourceTreeCandidates = sourceTreeCandidates
        self.extractedDirectoryCandidates = extractedDirectoryCandidates
        self.unsupportedSteps = unsupportedSteps
        self.blockedActions = blockedActions
        self.diagnostics = diagnostics
    }
}

public enum NDSDataAudioPreviewStatus: String, Codable, Equatable, CaseIterable {
    case ready
    case blocked
}

public struct NDSDataAudioPreview: Codable, Equatable {
    public let status: NDSDataAudioPreviewStatus
    public let format: String
    public let summary: String
    public let detectedHints: [String]
    public let blockedActions: [String]
    public let diagnostics: [Diagnostic]

    public init(
        status: NDSDataAudioPreviewStatus,
        format: String,
        summary: String,
        detectedHints: [String],
        blockedActions: [String],
        diagnostics: [Diagnostic] = []
    ) {
        self.status = status
        self.format = format
        self.summary = summary
        self.detectedHints = detectedHints
        self.blockedActions = blockedActions
        self.diagnostics = diagnostics
    }
}

public struct NDSDataCatalogRecord: Codable, Equatable, Identifiable {
    public let id: String
    public let domain: NDSDataDomain
    public let title: String
    public let relativePath: String
    public let containerPath: String?
    public let format: NDSDataSourceFormat
    public let role: NDSDataSourceRole
    public let exists: Bool
    public let recordCount: Int?
    public let byteCount: UInt64?
    public let sourceSpan: SourceSpan?
    public let facts: [SourceIndexFact]
    public let preview: String?
    public let containerSummary: NDSDataContainerSummary?
    public let textBankPreview: NDSDataTextBankPreview?
    public let migrationPlan: NDSDataMigrationPlan?
    public let audioPreview: NDSDataAudioPreview?
    public let relatedRecords: [NDSDataRelatedRecord]
    public let readiness: NDSDataReadinessSummary?
    public let diagnostics: [Diagnostic]

    public init(
        id: String,
        domain: NDSDataDomain,
        title: String,
        relativePath: String,
        containerPath: String? = nil,
        format: NDSDataSourceFormat,
        role: NDSDataSourceRole,
        exists: Bool,
        recordCount: Int? = nil,
        byteCount: UInt64? = nil,
        sourceSpan: SourceSpan? = nil,
        facts: [SourceIndexFact] = [],
        preview: String? = nil,
        containerSummary: NDSDataContainerSummary? = nil,
        textBankPreview: NDSDataTextBankPreview? = nil,
        migrationPlan: NDSDataMigrationPlan? = nil,
        audioPreview: NDSDataAudioPreview? = nil,
        relatedRecords: [NDSDataRelatedRecord] = [],
        readiness: NDSDataReadinessSummary? = nil,
        diagnostics: [Diagnostic] = []
    ) {
        self.id = id
        self.domain = domain
        self.title = title
        self.relativePath = relativePath
        self.containerPath = containerPath
        self.format = format
        self.role = role
        self.exists = exists
        self.recordCount = recordCount
        self.byteCount = byteCount
        self.sourceSpan = sourceSpan
        self.facts = facts
        self.preview = preview
        self.containerSummary = containerSummary
        self.textBankPreview = textBankPreview
        self.migrationPlan = migrationPlan
        self.audioPreview = audioPreview
        self.relatedRecords = relatedRecords
        self.readiness = readiness
        self.diagnostics = diagnostics
    }

    public func copy(
        id: String? = nil,
        domain: NDSDataDomain? = nil,
        title: String? = nil,
        relativePath: String? = nil,
        containerPath: String?? = nil,
        format: NDSDataSourceFormat? = nil,
        role: NDSDataSourceRole? = nil,
        exists: Bool? = nil,
        recordCount: Int?? = nil,
        byteCount: UInt64?? = nil,
        sourceSpan: SourceSpan?? = nil,
        facts: [SourceIndexFact]? = nil,
        preview: String?? = nil,
        containerSummary: NDSDataContainerSummary?? = nil,
        textBankPreview: NDSDataTextBankPreview?? = nil,
        migrationPlan: NDSDataMigrationPlan?? = nil,
        audioPreview: NDSDataAudioPreview?? = nil,
        relatedRecords: [NDSDataRelatedRecord]? = nil,
        readiness: NDSDataReadinessSummary?? = nil,
        diagnostics: [Diagnostic]? = nil
    ) -> NDSDataCatalogRecord {
        NDSDataCatalogRecord(
            id: id ?? self.id,
            domain: domain ?? self.domain,
            title: title ?? self.title,
            relativePath: relativePath ?? self.relativePath,
            containerPath: containerPath ?? self.containerPath,
            format: format ?? self.format,
            role: role ?? self.role,
            exists: exists ?? self.exists,
            recordCount: recordCount ?? self.recordCount,
            byteCount: byteCount ?? self.byteCount,
            sourceSpan: sourceSpan ?? self.sourceSpan,
            facts: facts ?? self.facts,
            preview: preview ?? self.preview,
            containerSummary: containerSummary ?? self.containerSummary,
            textBankPreview: textBankPreview ?? self.textBankPreview,
            migrationPlan: migrationPlan ?? self.migrationPlan,
            audioPreview: audioPreview ?? self.audioPreview,
            relatedRecords: relatedRecords ?? self.relatedRecords,
            readiness: readiness ?? self.readiness,
            diagnostics: diagnostics ?? self.diagnostics
        )
    }
}

public struct ProjectNDSDataCatalog: Codable, Equatable {
    public let root: SourceLocation
    public let profile: GameProfile
    public let family: GenIIIGameFamily
    public let adapterID: String
    public let adapterName: String
    public let isReadOnly: Bool
    public let summary: NDSDataCatalogSummary
    public let records: [NDSDataCatalogRecord]
    public let diagnostics: [Diagnostic]

    public init(
        root: SourceLocation,
        profile: GameProfile,
        family: GenIIIGameFamily,
        adapterID: String,
        adapterName: String,
        isReadOnly: Bool,
        summary: NDSDataCatalogSummary,
        records: [NDSDataCatalogRecord],
        diagnostics: [Diagnostic]
    ) {
        self.root = root
        self.profile = profile
        self.family = family
        self.adapterID = adapterID
        self.adapterName = adapterName
        self.isReadOnly = isReadOnly
        self.summary = summary
        self.records = records
        self.diagnostics = diagnostics
    }
}

public enum NDSDataCatalogBuilder {
    public static func sourceFingerprint(path: String, fileManager: FileManager = .default) throws -> String {
        let index = try GameAdapterRegistry.index(path: path, fileManager: fileManager)
        return sourceFingerprint(index: index, fileManager: fileManager)
    }

    public static func sourceFingerprint(index: ProjectIndex, fileManager: FileManager = .default) -> String {
        let root = URL(fileURLWithPath: index.root.path).standardizedFileURL
        let payload = NDSDataSourceFingerprintPayload(
            profile: index.profile,
            adapterID: index.adapterID,
            adapterName: index.adapterName,
            rootPath: root.path,
            files: sourceFingerprintEntries(root: root, profile: index.profile, fileManager: fileManager)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(payload) else {
            return "\(root.path)|\(index.profile.rawValue)|\(index.adapterID)"
        }
        return pokemonHackSHA1Hex(data)
    }

    public static func build(path: String, fileManager: FileManager = .default) throws -> ProjectNDSDataCatalog {
        let index = try GameAdapterRegistry.index(path: path, fileManager: fileManager)
        return build(index: index, fileManager: fileManager)
    }

    public static func build(index: ProjectIndex, fileManager: FileManager = .default) -> ProjectNDSDataCatalog {
        let rootURL = URL(fileURLWithPath: index.root.path).standardizedFileURL
        let root = SourceLocation(path: rootURL.path, exists: fileManager.fileExists(atPath: rootURL.path))

        if index.profile == .ndsROM {
            let report = try? NDSROMInspectorReportBuilder.build(index: index, fileManager: fileManager)
            let records = report.map { romContainerRecords(report: $0) } ?? []
            var diagnostics = [readOnlyDiagnostic(), binaryReadOnlyDiagnostic()]
            if let report {
                diagnostics.append(contentsOf: report.diagnostics)
            } else {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "NDS_DATA_CATALOG_BINARY_SUMMARY_FAILED",
                        message: "NDS ROM NARC summaries could not be built from this binary input."
                    )
                )
            }
            return catalog(
                root: root,
                profile: index.profile,
                family: family(for: index, fileManager: fileManager),
                adapterID: index.adapterID,
                adapterName: index.adapterName,
                records: records,
                diagnostics: diagnostics + records.flatMap(\.diagnostics)
            )
        }

        guard index.profile.platform == .nds, index.profile.projectKind == .sourceTree else {
            return catalog(
                root: root,
                profile: index.profile,
                family: family(for: index, fileManager: fileManager),
                adapterID: index.adapterID,
                adapterName: index.adapterName,
                records: [],
                diagnostics: [
                    Diagnostic(
                        severity: .warning,
                        code: "NDS_DATA_CATALOG_UNSUPPORTED_PROFILE",
                        message: "Gen IV data catalogs support NDS source-tree profiles only."
                    )
                ]
            )
        }

        let sourceTree = try? NDSDecompSourceTreeIndexBuilder.build(root: rootURL, fileManager: fileManager)
        let family = sourceTree?.family ?? family(for: index, fileManager: fileManager)
        var diagnostics = [readOnlyDiagnostic()] + (sourceTree?.diagnostics ?? [])

        if index.profile == .pmdSky {
            let records = spinOffInventoryRecords(root: rootURL, fileManager: fileManager)
            diagnostics.append(
                Diagnostic(
                    severity: .info,
                    code: "NDS_DATA_CATALOG_SPINOFF_DEFERRED",
                    message: "PMD-Sky is indexed as a read-only spin-off resource inventory; mainline Gen IV RPG data semantics are not applied."
                )
            )
            return catalog(
                root: root,
                profile: index.profile,
                family: family,
                adapterID: index.adapterID,
                adapterName: index.adapterName,
                records: records,
                diagnostics: diagnostics + records.flatMap(\.diagnostics)
            )
        }

        guard let descriptors = descriptors(for: index.profile) else {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "NDS_DATA_CATALOG_UNSUPPORTED_PROFILE",
                    message: "No Gen IV data catalog descriptor is available for \(index.profile.rawValue)."
                )
            )
            return catalog(
                root: root,
                profile: index.profile,
                family: family,
                adapterID: index.adapterID,
                adapterName: index.adapterName,
                records: [],
                diagnostics: diagnostics
            )
        }

        let records = enrichGenVReadiness(
            records: enrichDiamondPearlCAnchorFutureReadiness(
                records: enrichDiamondPearlMoveCAnchorReadiness(
                    records: enrichDiamondPearlMapInventory(
                        records: enrichHeartGoldSoulSilverScriptSequenceInventory(
                            records: enrichHeartGoldSoulSilverMapInventory(
                                records: enrichPlatinumMapInventory(
                                    records: enrichRelationships(
                                        records: uniqueRecords(
                                            descriptors.flatMap { descriptor in
                                                catalogRecords(for: descriptor, root: rootURL, fileManager: fileManager)
                                            }
                                            + discoveredContainerRecords(for: index.profile, root: rootURL, fileManager: fileManager)
                                            + discoveredGenVAudioRecords(for: index.profile, root: rootURL, fileManager: fileManager)
                                            + genVUnavailableTitleRecords(for: index.profile, root: rootURL, fileManager: fileManager)
                                        ).sorted(by: recordSort),
                                        profile: index.profile
                                    ),
                                    profile: index.profile
                                ),
                                profile: index.profile
                            ),
                            profile: index.profile
                        ),
                        profile: index.profile
                    ),
                    profile: index.profile
                ),
                profile: index.profile
            ),
            profile: index.profile
        )

        return catalog(
            root: root,
            profile: index.profile,
            family: family,
            adapterID: index.adapterID,
            adapterName: index.adapterName,
            records: records,
            diagnostics: diagnostics + records.flatMap(\.diagnostics)
        )
    }

    private static func catalog(
        root: SourceLocation,
        profile: GameProfile,
        family: GenIIIGameFamily,
        adapterID: String,
        adapterName: String,
        records: [NDSDataCatalogRecord],
        diagnostics: [Diagnostic]
    ) -> ProjectNDSDataCatalog {
        ProjectNDSDataCatalog(
            root: root,
            profile: profile,
            family: family,
            adapterID: adapterID,
            adapterName: adapterName,
            isReadOnly: true,
            summary: summary(records: records),
            records: records,
            diagnostics: diagnostics
        )
    }

    private static func summary(records: [NDSDataCatalogRecord]) -> NDSDataCatalogSummary {
        let domains = NDSDataDomain.allCases.compactMap { domain -> NDSDataDomainCount? in
            let count = records.filter { $0.domain == domain }.count
            return count == 0 ? nil : NDSDataDomainCount(domain: domain, count: count)
        }
        return NDSDataCatalogSummary(
            recordCount: records.count,
            domainCounts: domains,
            sourceBackedCount: records.filter { $0.role == .sourceTree || $0.role == .generatedReference }.count,
            nitroFSBackedCount: records.filter { $0.role == .nitroFSManifest || $0.role == .binaryContainer }.count,
            missingExpectedCount: records.filter { !$0.exists }.count
        )
    }

    private static func descriptors(for profile: GameProfile) -> [CatalogPathDescriptor]? {
        switch profile {
        case .pokeplatinum:
            return [
                CatalogPathDescriptor(.species, "res/pokemon"),
                CatalogPathDescriptor(.moves, "res/battle/moves"),
                CatalogPathDescriptor(.items, "res/items"),
                CatalogPathDescriptor(.trainers, "res/trainers"),
                CatalogPathDescriptor(.encounters, "res/field/encounters"),
                CatalogPathDescriptor(.text, "res/text"),
                CatalogPathDescriptor(.scripts, "res/field/scripts"),
                CatalogPathDescriptor(.scripts, "res/field/frontier_scripts", required: false),
                CatalogPathDescriptor(.maps, "res/field/maps", summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.maps, "res/field/maps"),
                CatalogPathDescriptor(.maps, "res/field/matrices", required: false),
                CatalogPathDescriptor(.maps, "res/field/events"),
                CatalogPathDescriptor(.maps, "res/field/area_data", required: false),
                CatalogPathDescriptor(.audio, "res/sound", required: false),
                CatalogPathDescriptor(.resources, "generated", role: .generatedReference, allowedExtensions: ["txt"]),
                CatalogPathDescriptor(.resources, "platinum.us/filesys.csv", role: .nitroFSManifest)
            ]
        case .pokeheartgold:
            return [
                CatalogPathDescriptor(.personal, "files/poketool/personal"),
                CatalogPathDescriptor(.moves, "files/poketool/waza/waza_tbl.narc", role: .binaryContainer, format: .narc),
                CatalogPathDescriptor(.moves, "files/poketool/waza", role: .binaryContainer, required: false),
                CatalogPathDescriptor(.items, "files/itemtool/itemdata"),
                CatalogPathDescriptor(.trainers, "files/poketool/trainer"),
                CatalogPathDescriptor(.encounters, "files/fielddata/encountdata"),
                CatalogPathDescriptor(.scripts, "files/fielddata/eventdata/zone_event"),
                CatalogPathDescriptor(.text, "files/msgdata"),
                CatalogPathDescriptor(.text, "files/msgdata/scenario", required: false),
                CatalogPathDescriptor(.scripts, "files/fielddata/script/scr_seq", summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.scripts, "files/fielddata/script/scr_seq"),
                CatalogPathDescriptor(.maps, "files/fielddata/mapmatrix", summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.maps, "files/fielddata/mapmatrix"),
                CatalogPathDescriptor(.maps, "files/fielddata/maptable", summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.maps, "files/fielddata/maptable"),
                CatalogPathDescriptor(.maps, "files/fielddata/graphic", required: false),
                CatalogPathDescriptor(.maps, "src/data/map_headers.h", format: .cHeader),
                CatalogPathDescriptor(.maps, "src/data/fieldmap.h", format: .cHeader, required: false),
                CatalogPathDescriptor(.audio, "files/data/sound", required: false),
                CatalogPathDescriptor(.audio, "files/sound", required: false),
                CatalogPathDescriptor(.resources, "filesystem.mk", role: .nitroFSManifest)
            ]
        case .pokediamond:
            return [
                CatalogPathDescriptor(.species, "arm9/src/pokemon.c", format: .cSource),
                CatalogPathDescriptor(.moves, "arm9/src/waza.c", format: .cSource),
                CatalogPathDescriptor(.items, "arm9/src/itemtool.c", format: .cSource),
                CatalogPathDescriptor(.trainers, "arm9/src/trainer_data.c", format: .cSource),
                CatalogPathDescriptor(.encounters, "arm9/src/encounter.c", format: .cSource),
                CatalogPathDescriptor(.maps, "arm9/src/map_header.c", format: .cSource),
                CatalogPathDescriptor(.scripts, "arm9/src/script.c", format: .cSource),
                CatalogPathDescriptor(.text, "arm9/src/msgdata.c", format: .cSource, required: false),
                CatalogPathDescriptor(.personal, "files/poketool/personal"),
                CatalogPathDescriptor(.personal, "files/poketool/personal_pearl", required: false),
                CatalogPathDescriptor(.moves, "files/poketool/waza", role: .binaryContainer, required: false),
                CatalogPathDescriptor(.items, "files/itemtool/itemdata", required: false),
                CatalogPathDescriptor(.trainers, "files/poketool/trainer", required: false),
                CatalogPathDescriptor(.encounters, "files/fielddata/encountdata", required: false),
                CatalogPathDescriptor(.encounters, "files/arc/encdata_ex", role: .binaryContainer, required: false),
                CatalogPathDescriptor(.text, "files/msgdata/msg", required: false),
                CatalogPathDescriptor(.text, "files/msgdata/scenario", required: false),
                CatalogPathDescriptor(.scripts, "files/fielddata/script", required: false),
                CatalogPathDescriptor(.maps, "files/fielddata/mapmatrix", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.maps, "files/fielddata/mapmatrix", required: false),
                CatalogPathDescriptor(.maps, "files/fielddata/land_data", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.maps, "files/fielddata/land_data", required: false),
                CatalogPathDescriptor(.maps, "files/fielddata/areadata", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.maps, "files/fielddata/areadata", required: false),
                CatalogPathDescriptor(.maps, "files/fielddata/maptable", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.maps, "files/fielddata/maptable", required: false),
                CatalogPathDescriptor(.maps, "files/fielddata/eventdata", required: false),
                CatalogPathDescriptor(.audio, "files/data/sound", required: false),
                CatalogPathDescriptor(.audio, "files/sound", required: false),
                CatalogPathDescriptor(.resources, "filesystem.mk", role: .nitroFSManifest)
            ]
        case .pokeblack:
            return [
                CatalogPathDescriptor(.resources, "Makefile", format: .text, required: false),
                CatalogPathDescriptor(.resources, "config.mk", required: false),
                CatalogPathDescriptor(.resources, "src", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.resources, "asm", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.resources, "include", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.encounters, "data/encounters", required: false),
                CatalogPathDescriptor(.resources, "data", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.resources, "files/a", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.resources, "files/fielddata", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.maps, "files/fielddata/mapmatrix", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.maps, "files/fielddata/maptable", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.scripts, "files/fielddata/script", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.scripts, "files/fielddata/eventdata/zone_event", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.text, "files/msgdata", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.resources, "files", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.resources, "files"),
                CatalogPathDescriptor(.audio, "files/wb_sound_data.sdat", required: false),
                CatalogPathDescriptor(.audio, "files/soundstatus.narc", role: .binaryContainer, format: .narc, required: false),
                CatalogPathDescriptor(.scripts, "overlays", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.scripts, "overlays", required: false),
                CatalogPathDescriptor(.resources, "ndsdisasm_config", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.resources, "ndsdisasm_config", required: false),
                CatalogPathDescriptor(.resources, "arm9.ld", format: .text, required: false),
                CatalogPathDescriptor(.resources, "arm7.ld", format: .text, required: false),
                CatalogPathDescriptor(.resources, "black.us", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.resources, "white.us", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.resources, "black2.us", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.resources, "white2.us", required: false, summarizeDirectory: true, includeMigrationPlan: false),
                CatalogPathDescriptor(.resources, "black.us/rom.sha1", required: false),
                CatalogPathDescriptor(.resources, "white.us/rom.sha1", required: false),
                CatalogPathDescriptor(.resources, "black2.us", required: false),
                CatalogPathDescriptor(.resources, "white2.us", required: false),
                CatalogPathDescriptor(.resources, "main.rsf", role: .nitroFSManifest),
                CatalogPathDescriptor(.resources, "main.lsf", required: false)
            ]
        default:
            return nil
        }
    }

    private static func catalogRecords(
        for descriptor: CatalogPathDescriptor,
        root: URL,
        fileManager: FileManager
    ) -> [NDSDataCatalogRecord] {
        let url = root.appendingPathComponent(descriptor.relativePath)
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            guard descriptor.required else { return [] }
            return [record(for: descriptor, relativePath: descriptor.relativePath, root: root, exists: false, fileManager: fileManager)]
        }

        guard isDirectory.boolValue else {
            return [record(for: descriptor, relativePath: descriptor.relativePath, root: root, exists: true, fileManager: fileManager)]
        }

        if descriptor.summarizeDirectory {
            return [record(for: descriptor, relativePath: descriptor.relativePath, root: root, exists: true, isDirectory: true, fileManager: fileManager)]
        }

        let files = matchingFiles(root: url, projectRoot: root, descriptor: descriptor, fileManager: fileManager)
        if files.isEmpty {
            return [record(for: descriptor, relativePath: descriptor.relativePath, root: root, exists: true, isDirectory: true, fileManager: fileManager)]
        }
        return files.map { relativePath in
            record(for: descriptor, relativePath: relativePath, root: root, exists: true, fileManager: fileManager)
        }
    }

    private static func matchingFiles(
        root: URL,
        projectRoot: URL,
        descriptor: CatalogPathDescriptor,
        fileManager: FileManager
    ) -> [String] {
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var paths: [String] = []
        while let fileURL = enumerator.nextObject() as? URL {
            let values = try? fileURL.resourceValues(forKeys: [.isDirectoryKey])
            if values?.isDirectory == true {
                if excludedDirectoryNames.contains(fileURL.lastPathComponent) {
                    enumerator.skipDescendants()
                }
                continue
            }
            let relativePath = relativePath(for: fileURL, root: projectRoot)
            if let allowedExtensions = descriptor.allowedExtensions,
               !allowedExtensions.contains(fileURL.pathExtension.lowercased()) {
                continue
            }
            paths.append(relativePath)
        }
        return paths.sorted()
    }

    private static func record(
        for descriptor: CatalogPathDescriptor,
        relativePath: String,
        root: URL,
        exists: Bool,
        isDirectory: Bool = false,
        fileManager: FileManager
    ) -> NDSDataCatalogRecord {
        let url = root.appendingPathComponent(relativePath)
        let format = descriptor.format ?? (isDirectory ? .directory : format(for: relativePath))
        let containerSummary = exists
            ? containerSummary(url: url, relativePath: relativePath, format: format, isDirectory: isDirectory, fileManager: fileManager)
            : nil
        let genVDirectoryInventory = genVDirectoryInventory(relativePath: relativePath, url: url, exists: exists, isDirectory: isDirectory, fileManager: fileManager)
        let byteCount = containerSummary?.byteCount ?? genVDirectoryInventory?.byteCount ?? (exists && !isDirectory ? fileByteCount(url, fileManager: fileManager) : nil)
        let recordCount = containerSummary?.memberCount ?? (exists ? shallowRecordCount(url: url, format: format, isDirectory: isDirectory, fileManager: fileManager) : nil)
        var diagnostics: [Diagnostic] = []

        if !exists {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "NDS_DATA_SOURCE_MISSING",
                    message: "Expected NDS data source is not present: \(relativePath)",
                    span: SourceSpan(relativePath: relativePath, startLine: 1)
                )
            )
        } else if format == .json,
                  let data = try? Data(contentsOf: url),
                  (try? JSONSerialization.jsonObject(with: data)) == nil {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "NDS_DATA_JSON_PARSE_FAILED",
                    message: "Could not parse JSON data source: \(relativePath)",
                    span: SourceSpan(relativePath: relativePath, startLine: 1)
                )
            )
        }
        let textPreview = textBankPreview(
            url: url,
            relativePath: relativePath,
            domain: descriptor.domain,
            format: format,
            exists: exists,
            isDirectory: isDirectory
        )
        let migrationPlan = descriptor.includeMigrationPlan
            ? ndsMigrationPlan(
                relativePath: relativePath,
                domain: descriptor.domain,
                format: format,
                role: descriptor.role,
                exists: exists
            )
            : nil
        let audioPreview = ndsAudioPreview(
            url: url,
            relativePath: relativePath,
            domain: descriptor.domain,
            format: format,
            exists: exists,
            isDirectory: isDirectory,
            containerSummary: containerSummary,
            fileManager: fileManager
        )
        diagnostics.append(contentsOf: containerSummary?.diagnostics ?? [])
        diagnostics.append(contentsOf: textPreview?.diagnostics ?? [])
        diagnostics.append(contentsOf: migrationPlan?.diagnostics ?? [])
        diagnostics.append(contentsOf: audioPreview?.diagnostics ?? [])

        let facts = factsForRecord(
            format: format,
            role: descriptor.role,
            byteCount: byteCount,
            recordCount: recordCount,
            containerSummary: containerSummary,
            textBankPreview: textPreview,
            migrationPlan: migrationPlan,
            audioPreview: audioPreview
        ) + genVDirectoryInventoryFacts(genVDirectoryInventory)
          + genVSHA1TextFacts(relativePath: relativePath, url: url, exists: exists, isDirectory: isDirectory)
        return NDSDataCatalogRecord(
            id: "\(descriptor.domain.rawValue):\(relativePath)",
            domain: descriptor.domain,
            title: title(for: relativePath, domain: descriptor.domain),
            relativePath: relativePath,
            format: format,
            role: descriptor.role,
            exists: exists,
            recordCount: recordCount,
            byteCount: byteCount,
            sourceSpan: SourceSpan(relativePath: relativePath, startLine: 1),
            facts: facts,
            preview: genVDirectoryInventoryPreview(genVDirectoryInventory) ?? containerPreview(containerSummary) ?? preview(url: url, format: format),
            containerSummary: containerSummary,
            textBankPreview: textPreview,
            migrationPlan: migrationPlan,
            audioPreview: audioPreview,
            diagnostics: diagnostics
        )
    }

    private static func spinOffInventoryRecords(root: URL, fileManager: FileManager) -> [NDSDataCatalogRecord] {
        let descriptors = [
            CatalogPathDescriptor(.resources, "files/MONSTER"),
            CatalogPathDescriptor(.resources, "files/BALANCE"),
            CatalogPathDescriptor(.resources, "files/TABLEDAT"),
            CatalogPathDescriptor(.resources, "files/DUNGEON"),
            CatalogPathDescriptor(.resources, "files/MESSAGE"),
            CatalogPathDescriptor(.resources, "files/language-specific/US/SCRIPT", required: false),
            CatalogPathDescriptor(.resources, "files/language-specific/EU/SCRIPT", required: false),
            CatalogPathDescriptor(.resources, "files/language-specific/JP/SCRIPT", required: false),
            CatalogPathDescriptor(.resources, "files/MAP_BG", required: false),
            CatalogPathDescriptor(.resources, "files/GROUND", required: false),
            CatalogPathDescriptor(.resources, "filesystem.mk", role: .nitroFSManifest)
        ]
        return uniqueRecords(descriptors.flatMap { descriptor in
            catalogRecords(for: descriptor, root: root, fileManager: fileManager)
        }).sorted(by: recordSort)
    }

    private static func genVUnavailableTitleRecords(
        for profile: GameProfile,
        root: URL,
        fileManager: FileManager
    ) -> [NDSDataCatalogRecord] {
        guard profile == .pokeblack else { return [] }
        return genVTitleCoverageSpecs.filter { !genVSourceMarkerExists(for: $0, root: root, fileManager: fileManager) }.map { spec in
            let relativePath = "unavailable-titles/\(spec.title)"
            return NDSDataCatalogRecord(
                id: "resources:\(relativePath)",
                domain: .resources,
                title: spec.title,
                relativePath: relativePath,
                format: .unknown,
                role: .metadataUnavailable,
                exists: false,
                sourceSpan: SourceSpan(relativePath: relativePath, startLine: 1),
                facts: [
                    SourceIndexFact(label: "Gen V Title", value: spec.title),
                    SourceIndexFact(label: "Gen V Variant ID", value: spec.id),
                    SourceIndexFact(label: "Gen V Family", value: spec.family),
                    SourceIndexFact(label: "Gen V Source Name", value: spec.sourceName),
                    SourceIndexFact(label: "Gen V Source Marker", value: spec.sourceMarkerPaths.isEmpty ? "none" : spec.sourceMarkerPaths.joined(separator: ", ")),
                    SourceIndexFact(label: "Gen V Variant State", value: "unavailable"),
                    SourceIndexFact(label: "Gen V Unavailable Reason", value: spec.unavailableReason)
                ],
                preview: nil
            )
        }
    }

    private static func discoveredContainerRecords(for profile: GameProfile, root: URL, fileManager: FileManager) -> [NDSDataCatalogRecord] {
        switch profile {
        case .pokeplatinum:
            return literalNARCRecords(root: root, searchRoot: "res/prebuilt", fileManager: fileManager)
        case .pokeheartgold:
            return literalNARCRecords(root: root, searchRoot: "files", fileManager: fileManager)
        case .pokediamond:
            return unpackedArchiveDirectoryRecords(root: root, searchRoot: "files", fileManager: fileManager)
        case .pokeblack:
            return literalNARCRecords(root: root, searchRoot: "files", fileManager: fileManager)
        default:
            return []
        }
    }

    private static func discoveredGenVAudioRecords(for profile: GameProfile, root: URL, fileManager: FileManager) -> [NDSDataCatalogRecord] {
        guard profile == .pokeblack else { return [] }
        return discoveredFiles(root: root, searchRoot: "files", extensions: ["sdat"], fileManager: fileManager)
            .map { relativePath in
                record(
                    for: CatalogPathDescriptor(.audio, relativePath, required: false),
                    relativePath: relativePath,
                    root: root,
                    exists: true,
                    fileManager: fileManager
                )
            }
    }

    private static func literalNARCRecords(root: URL, searchRoot: String, fileManager: FileManager) -> [NDSDataCatalogRecord] {
        discoveredFiles(root: root, searchRoot: searchRoot, extensions: ["narc"], fileManager: fileManager)
            .prefix(maxDiscoveredContainerRecords)
            .map { relativePath in
                containerRecord(
                    relativePath: relativePath,
                    root: root,
                    domain: domain(forContainerPath: relativePath),
                    format: .narc,
                    isDirectory: false,
                    fileManager: fileManager
                )
            }
    }

    private static func discoveredFiles(
        root: URL,
        searchRoot: String,
        extensions: Set<String>,
        fileManager: FileManager
    ) -> [String] {
        let searchURL = root.appendingPathComponent(searchRoot)
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: searchURL.path, isDirectory: &isDirectory), isDirectory.boolValue,
              let enumerator = fileManager.enumerator(
                at: searchURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
              )
        else {
            return []
        }

        var paths: [String] = []
        while let url = enumerator.nextObject() as? URL {
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
            if values?.isDirectory == true {
                if excludedDirectoryNames.contains(url.lastPathComponent) {
                    enumerator.skipDescendants()
                }
                continue
            }
            guard extensions.contains(url.pathExtension.lowercased()) else { continue }
            paths.append(relativePath(for: url, root: root))
        }
        return paths.sorted()
    }

    private static func unpackedArchiveDirectoryRecords(root: URL, searchRoot: String, fileManager: FileManager) -> [NDSDataCatalogRecord] {
        let searchURL = root.appendingPathComponent(searchRoot)
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: searchURL.path, isDirectory: &isDirectory), isDirectory.boolValue,
              let enumerator = fileManager.enumerator(
                at: searchURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
              )
        else {
            return []
        }

        var paths: [String] = []
        while let url = enumerator.nextObject() as? URL {
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
            guard values?.isDirectory == true else { continue }
            if excludedDirectoryNames.contains(url.lastPathComponent) {
                enumerator.skipDescendants()
                continue
            }
            guard hasImmediateUnpackedArchiveSignal(url: url, fileManager: fileManager) else { continue }
            paths.append(relativePath(for: url, root: root))
            enumerator.skipDescendants()
        }

        return paths
            .sorted()
            .prefix(maxDiscoveredContainerRecords)
            .map { relativePath in
                containerRecord(
                    relativePath: relativePath,
                    root: root,
                    domain: domain(forContainerPath: relativePath),
                    format: .directory,
                    isDirectory: true,
                    fileManager: fileManager
                )
            }
    }

    private static func containerRecord(
        relativePath: String,
        root: URL,
        domain: NDSDataDomain,
        format: NDSDataSourceFormat,
        isDirectory: Bool,
        fileManager: FileManager
    ) -> NDSDataCatalogRecord {
        record(
            for: CatalogPathDescriptor(domain, relativePath, role: .binaryContainer, format: format),
            relativePath: relativePath,
            root: root,
            exists: true,
            isDirectory: isDirectory,
            fileManager: fileManager
        )
    }

    private static func romContainerRecords(report: NDSROMInspectorReport) -> [NDSDataCatalogRecord] {
        let narcRecords = report.narcArchives.map { archive in
            let domain = domain(forContainerPath: archive.path)
            let summary = containerSummary(
                for: archive.index,
                memberFingerprints: archive.memberFingerprints,
                byteCount: archive.size
            )
            let migrationPlan = ndsMigrationPlan(
                relativePath: archive.path,
                domain: domain,
                format: .narc,
                role: .binaryContainer,
                exists: true
            )
            let audioPreview = ndsAudioPreview(
                relativePath: archive.path,
                domain: domain,
                format: .narc,
                exists: true,
                isDirectory: false,
                containerSummary: summary
            )
            return NDSDataCatalogRecord(
                id: "\(domain.rawValue):\(archive.path)",
                domain: domain,
                title: title(for: archive.path, domain: domain),
                relativePath: archive.path,
                format: .narc,
                role: .binaryContainer,
                exists: true,
                recordCount: summary.memberCount,
                byteCount: archive.size,
                sourceSpan: SourceSpan(relativePath: archive.path, startLine: 1),
                facts: factsForRecord(
                    format: .narc,
                    role: .binaryContainer,
                    byteCount: archive.size,
                    recordCount: summary.memberCount,
                    containerSummary: summary,
                    migrationPlan: migrationPlan,
                    audioPreview: audioPreview
                ),
                preview: containerPreview(summary),
                containerSummary: summary,
                migrationPlan: migrationPlan,
                audioPreview: audioPreview,
                diagnostics: archive.index.diagnostics + (migrationPlan?.diagnostics ?? []) + (audioPreview?.diagnostics ?? [])
            )
        }
        let audioRecords = report.fileSystem.files.filter { file in
            file.kind == .audio || ndsAudioFileExtensions.contains(URL(fileURLWithPath: file.path).pathExtension.lowercased())
        }.map { file -> NDSDataCatalogRecord in
            let audioPreview = ndsAudioPreview(
                relativePath: file.path,
                domain: .audio,
                format: format(for: file.path),
                exists: true,
                isDirectory: false,
                containerSummary: nil
            )
            return NDSDataCatalogRecord(
                id: "audio:\(file.path)",
                domain: .audio,
                title: title(for: file.path, domain: .audio),
                relativePath: file.path,
                format: format(for: file.path),
                role: .binaryContainer,
                exists: true,
                byteCount: file.size,
                sourceSpan: SourceSpan(relativePath: file.path, startLine: 1),
                facts: factsForRecord(
                    format: format(for: file.path),
                    role: .binaryContainer,
                    byteCount: file.size,
                    recordCount: nil,
                    audioPreview: audioPreview
                ),
                audioPreview: audioPreview,
                diagnostics: audioPreview?.diagnostics ?? []
            )
        }
        let records = (narcRecords + audioRecords).sorted(by: recordSort)
        return enrichRelationships(records: records, profile: .ndsROM)
    }

    private static func uniqueRecords(_ records: [NDSDataCatalogRecord]) -> [NDSDataCatalogRecord] {
        var seen: Set<String> = []
        var unique: [NDSDataCatalogRecord] = []
        for record in records where seen.insert(record.id).inserted {
            unique.append(record)
        }
        return unique
    }

    private static func enrichRelationships(records: [NDSDataCatalogRecord], profile: GameProfile) -> [NDSDataCatalogRecord] {
        let recordsByID = Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })
        let relationshipKeysByID = Dictionary(uniqueKeysWithValues: records.map { ($0.id, relationshipKeys(for: $0, profile: profile)) })
        let relationshipRecordIDsByID = relationshipRecordIDs(records: records, relationshipKeysByID: relationshipKeysByID, profile: profile)
        return records.map { record in
            let related = relatedRecords(for: record, recordsByID: recordsByID, relationshipRecordIDsByID: relationshipRecordIDsByID, profile: profile)
            let readiness = readinessSummary(for: record, profile: profile, relatedRecords: related)
            let relationshipFacts = factsForRelationships(related, readiness: readiness)
            let diagnostics = record.diagnostics + diagnosticsForReadiness(readiness, record: record)
            return record.copy(
                facts: record.facts + relationshipFacts,
                relatedRecords: related,
                readiness: .some(readiness),
                diagnostics: diagnostics
            )
        }
    }

    private static let relationshipDomains: Set<NDSDataDomain> = [.maps, .scripts, .text]
    private static let genVFielddataRelationshipRootPaths: Set<String> = [
        "files/fielddata",
        "files/fielddata/mapmatrix",
        "files/fielddata/maptable",
        "files/fielddata/script",
        "files/fielddata/eventdata/zone_event"
    ]
    private static let heartGoldSoulSilverMapInventoryRelationshipRootPaths: Set<String> = [
        "files/fielddata/mapmatrix",
        "files/fielddata/maptable",
        "src/data/map_headers.h"
    ]

    private static func relationshipRecordIDs(
        records: [NDSDataCatalogRecord],
        relationshipKeysByID: [String: Set<String>],
        profile: GameProfile
    ) -> [String: Set<String>] {
        var recordIDsByKey: [String: Set<String>] = [:]
        for record in records where participatesInRelationships(record, profile: profile) {
            for key in relationshipKeysByID[record.id] ?? [] {
                recordIDsByKey[key, default: []].insert(record.id)
            }
        }

        var relatedIDsByID: [String: Set<String>] = [:]
        for record in records where participatesInRelationships(record, profile: profile) {
            var relatedIDs: Set<String> = []
            for key in relationshipKeysByID[record.id] ?? [] {
                relatedIDs.formUnion(recordIDsByKey[key] ?? [])
            }
            relatedIDs.remove(record.id)
            if !relatedIDs.isEmpty {
                relatedIDsByID[record.id] = relatedIDs
            }
        }
        return relatedIDsByID
    }

    private static func relatedRecords(
        for record: NDSDataCatalogRecord,
        recordsByID: [String: NDSDataCatalogRecord],
        relationshipRecordIDsByID: [String: Set<String>],
        profile: GameProfile
    ) -> [NDSDataRelatedRecord] {
        guard participatesInRelationships(record, profile: profile),
              let relatedIDs = relationshipRecordIDsByID[record.id],
              !relatedIDs.isEmpty
        else { return [] }

        return relatedIDs.compactMap { relatedID in
            guard let candidate = recordsByID[relatedID] else { return nil }
            return NDSDataRelatedRecord(
                recordID: candidate.id,
                label: relationshipLabel(for: candidate),
                domain: candidate.domain,
                relativePath: candidate.relativePath
            )
        }.sorted { lhs, rhs in
            if lhs.domain.sortOrder == rhs.domain.sortOrder {
                return lhs.relativePath.localizedStandardCompare(rhs.relativePath) == .orderedAscending
            }
            return lhs.domain.sortOrder < rhs.domain.sortOrder
        }
    }

    private static func readinessSummary(
        for record: NDSDataCatalogRecord,
        profile: GameProfile,
        relatedRecords: [NDSDataRelatedRecord]
    ) -> NDSDataReadinessSummary? {
        if profile == .pokeblack {
            return genVReadinessSummary(for: record)
        }

        if record.role == .binaryContainer {
            return NDSDataReadinessSummary(
                status: .blocked,
                title: "NDS container readiness",
                detail: "Container rows are read-only inventory for routing future graphics, text, map, and migration work.",
                blockedActions: ["container extraction", "decompression", "NARC rebuild", "ROM export"]
            )
        }

        switch record.domain {
        case .maps:
            let status: NDSDataReadinessStatus = relatedRecords.isEmpty ? .partial : .ready
            return NDSDataReadinessSummary(
                status: status,
                title: "Gen IV map readiness",
                detail: relatedRecords.isEmpty
                    ? "Map data is indexed, but no same-key matrix/script/text relationship was found."
                    : "Map, matrix, script, or text rows share a source-tree key and can be reviewed together.",
                blockedActions: ["map editor", "matrix compiler", "NARC rebuild", "ROM export"]
            )
        case .scripts:
            return NDSDataReadinessSummary(
                status: relatedRecords.isEmpty ? .partial : .ready,
                title: "Gen IV script readiness",
                detail: relatedRecords.isEmpty
                    ? "Script data is indexed without a same-key map or text row."
                    : "Script rows have same-key map or text context for read-only review.",
                blockedActions: ["script compiler", "event editor", "NARC rebuild", "ROM export"]
            )
        case .text:
            return NDSDataReadinessSummary(
                status: profile == .pmdSky ? .blocked : (relatedRecords.isEmpty ? .partial : .ready),
                title: "Gen IV text readiness",
                detail: profile == .pmdSky
                    ? "PMD-Sky text is spin-off inventory only and is not treated as mainline Gen IV RPG text."
                    : (record.textBankPreview == nil && relatedRecords.isEmpty
                        ? "Text data is indexed without decoded message-bank or same-key map/script context."
                        : "Text rows have decoded read-only preview facts or same-key map/script context for review."),
                blockedActions: ndsTextBankPreviewBlockedActions
            )
        case .audio:
            return NDSDataReadinessSummary(
                status: record.audioPreview?.status == .ready ? .partial : .blocked,
                title: "NDS audio preview readiness",
                detail: record.audioPreview?.status == .ready
                    ? "Audio rows expose read-only SDAT/SSEQ/SBNK/SWAR/STRM metadata only."
                    : "Audio rows are indexed, but decode, playback, conversion, extraction, rebuild, export, and mutation apply are not available.",
                blockedActions: ndsAudioPreviewBlockedActions
            )
        case .resources where record.role == .nitroFSManifest:
            return NDSDataReadinessSummary(
                status: .partial,
                title: "NDS filesystem manifest readiness",
                detail: "Filesystem manifests are source-tree context for routing resources; extraction, packing, and rebuilds stay external.",
                blockedActions: ["filesystem extraction", "NARC pack", "ROM rebuild", "ROM export"]
            )
        default:
            return nil
        }
    }

    private static func enrichGenVReadiness(
        records: [NDSDataCatalogRecord],
        profile: GameProfile
    ) -> [NDSDataCatalogRecord] {
        guard profile == .pokeblack else { return records }
        let existingRelativePaths = Set(records.map { $0.relativePath.lowercased() })
        return records.map { record in
            let readiness = genVReadinessSummary(for: record)
            return record.copy(
                facts: record.facts + genVReadinessFacts(for: record, existingRelativePaths: existingRelativePaths),
                readiness: .some(readiness),
                diagnostics: record.diagnostics + genVReadinessDiagnostics(for: record, readiness: readiness)
            )
        }
    }

    private static let platinumMapBlockedActions = [
        "semantic editing",
        "nested map writer",
        "extraction",
        "NARC/container work",
        "generated output write",
        "reference write",
        "build/playtest execution",
        "ROM export",
        "mutation apply",
        "binary write"
    ]

    private static let platinumMapActionState = "Platinum res/field/maps rows are inventory-only map metadata; no semantic editor, nested map writer, extraction, NARC/container work, generated/reference write, build/playtest, ROM export, mutation apply, or binary write path is enabled."

    private static func enrichPlatinumMapInventory(
        records: [NDSDataCatalogRecord],
        profile: GameProfile
    ) -> [NDSDataCatalogRecord] {
        guard profile == .pokeplatinum else { return records }
        return records.map { record in
            guard let sourceRole = platinumMapSourceRole(for: record) else {
                return record
            }

            let facts = [
                SourceIndexFact(label: "Gen IV Source Role", value: sourceRole),
                SourceIndexFact(label: "Gen IV Source Provenance", value: "platinum:res/field/maps"),
                SourceIndexFact(label: "Gen IV Readiness", value: "inventoryOnly"),
                SourceIndexFact(label: "Gen IV Blocked Actions", value: platinumMapBlockedActions.joined(separator: ", ")),
                SourceIndexFact(label: "Gen IV Action State", value: platinumMapActionState)
            ]
            return record.copy(
                facts: record.facts + facts,
                diagnostics: record.diagnostics + platinumMapDiagnostics(for: record)
            )
        }
    }

    private static func platinumMapSourceRole(for record: NDSDataCatalogRecord) -> String? {
        guard record.domain == .maps else { return nil }
        let lower = record.relativePath.lowercased()
        if lower == "res/field/maps" {
            return "platinumMapInventory"
        }
        if lower.hasPrefix("res/field/maps/") {
            return "platinumMapMember"
        }
        return nil
    }

    private static func platinumMapDiagnostics(for record: NDSDataCatalogRecord) -> [Diagnostic] {
        return [
            Diagnostic(
                severity: .info,
                code: "NDS_DATA_PLATINUM_MAP_INVENTORY_PREVIEW_ONLY",
                message: "Platinum map inventory for \(record.relativePath) is source provenance and blocker metadata only.",
                span: record.sourceSpan
            ),
            Diagnostic(
                severity: .warning,
                code: "NDS_DATA_PLATINUM_MAP_WRITE_BLOCKED",
                message: "Platinum res/field/maps edits, extraction, NARC/container work, generated/reference writes, build/playtest, ROM export, mutation apply, and binary writes remain blocked; blocked actions: \(platinumMapBlockedActions.joined(separator: ", ")).",
                span: record.sourceSpan
            )
        ]
    }

    private static let heartGoldSoulSilverMapBlockedActions = [
        "semantic editing",
        "map editor",
        "nested map directory editing",
        "script editing",
        "generated output write",
        "reference write",
        "NARC rebuild",
        "ROM rebuild",
        "ROM export",
        "binary write"
    ]

    private static let heartGoldSoulSilverMapHeaderBlockedActions = [
        "non-integer C scalar write",
        "identifier or macro write",
        "complex expression write",
        "row insertion/removal/reorder",
        "map editor",
        "nested map directory editing",
        "map matrix write",
        "map table write",
        "script editing",
        "generated output write",
        "reference write",
        "NARC rebuild",
        "ROM rebuild",
        "ROM export",
        "binary write"
    ]

    private static let heartGoldSoulSilverMapActionState = "HeartGold/SoulSilver map matrix and map table rows are inventory-only HGSS map metadata; no semantic editor, compiler, container rebuild, generated output, reference, or ROM write path is enabled."
    private static let heartGoldSoulSilverMapHeaderActionState = "HeartGold/SoulSilver map header rows expose existing integer-literal sMapHeaders scalars through the semantic mutation-plan gate; map matrix, map table, scripts, generated/reference writes, NARC rebuild, ROM rebuild/export, and binary writes remain blocked."

    private static func enrichHeartGoldSoulSilverMapInventory(
        records: [NDSDataCatalogRecord],
        profile: GameProfile
    ) -> [NDSDataCatalogRecord] {
        guard profile == .pokeheartgold else { return records }
        return records.map { record in
            guard let sourceRole = heartGoldSoulSilverMapSourceRole(for: record),
                  let provenance = heartGoldSoulSilverMapSourceProvenance(for: record)
            else {
                return record
            }

            let facts = [
                SourceIndexFact(label: "Gen IV Source Role", value: sourceRole),
                SourceIndexFact(label: "Gen IV Source Provenance", value: provenance),
                SourceIndexFact(label: "Gen IV Readiness", value: heartGoldSoulSilverMapReadiness(for: record)),
                SourceIndexFact(label: "Gen IV Blocked Actions", value: heartGoldSoulSilverMapBlockedActions(for: record).joined(separator: ", ")),
                SourceIndexFact(label: "Gen IV Action State", value: heartGoldSoulSilverMapActionState(for: record))
            ]
            return record.copy(
                facts: record.facts + facts,
                diagnostics: record.diagnostics + heartGoldSoulSilverMapDiagnostics(for: record)
            )
        }
    }

    private static func heartGoldSoulSilverMapSourceRole(for record: NDSDataCatalogRecord) -> String? {
        guard record.domain == .maps else { return nil }
        let lower = record.relativePath.lowercased()
        if lower == "files/fielddata/mapmatrix" {
            return "hgssMapMatrixInventory"
        }
        if lower.hasPrefix("files/fielddata/mapmatrix/") {
            return "hgssMapMatrixMember"
        }
        if lower == "files/fielddata/maptable" {
            return "hgssMapTableInventory"
        }
        if lower.hasPrefix("files/fielddata/maptable/") {
            return "hgssMapTableMember"
        }
        if lower == "src/data/map_headers.h" {
            return "hgssMapHeaderInventory"
        }
        return nil
    }

    private static func heartGoldSoulSilverMapSourceProvenance(for record: NDSDataCatalogRecord) -> String? {
        let lower = record.relativePath.lowercased()
        if lower == "files/fielddata/mapmatrix" || lower.hasPrefix("files/fielddata/mapmatrix/") {
            return "heartGoldSoulSilver:files/fielddata/mapmatrix"
        }
        if lower == "files/fielddata/maptable" || lower.hasPrefix("files/fielddata/maptable/") {
            return "heartGoldSoulSilver:files/fielddata/maptable"
        }
        if lower == "src/data/map_headers.h" {
            return "heartGoldSoulSilver:src/data/map_headers.h"
        }
        return nil
    }

    private static func isHeartGoldSoulSilverMapHeaderRecord(_ record: NDSDataCatalogRecord) -> Bool {
        record.domain == .maps && record.relativePath.lowercased() == "src/data/map_headers.h"
    }

    private static func heartGoldSoulSilverMapReadiness(for record: NDSDataCatalogRecord) -> String {
        isHeartGoldSoulSilverMapHeaderRecord(record) ? "semanticIntegerScalars" : "inventoryOnly"
    }

    private static func heartGoldSoulSilverMapBlockedActions(for record: NDSDataCatalogRecord) -> [String] {
        isHeartGoldSoulSilverMapHeaderRecord(record) ? heartGoldSoulSilverMapHeaderBlockedActions : heartGoldSoulSilverMapBlockedActions
    }

    private static func heartGoldSoulSilverMapActionState(for record: NDSDataCatalogRecord) -> String {
        isHeartGoldSoulSilverMapHeaderRecord(record) ? heartGoldSoulSilverMapHeaderActionState : heartGoldSoulSilverMapActionState
    }

    private static func heartGoldSoulSilverMapDiagnostics(for record: NDSDataCatalogRecord) -> [Diagnostic] {
        if isHeartGoldSoulSilverMapHeaderRecord(record) {
            return [
                Diagnostic(
                    severity: .info,
                    code: "NDS_DATA_HGSS_MAP_HEADER_SEMANTIC_SCALARS",
                    message: "HeartGold/SoulSilver map header C anchor for \(record.relativePath) exposes existing integer-literal sMapHeaders scalar fields through the semantic mutation-plan gate.",
                    span: record.sourceSpan
                ),
                Diagnostic(
                    severity: .warning,
                    code: "NDS_DATA_HGSS_MAP_HEADER_WRITE_LIMITED",
                    message: "HeartGold/SoulSilver map header writes are limited to existing integer-literal sMapHeaders scalar replacements; blocked actions: \(heartGoldSoulSilverMapHeaderBlockedActions.joined(separator: ", ")).",
                    span: record.sourceSpan
                )
            ]
        }
        return [
            Diagnostic(
                severity: .info,
                code: "NDS_DATA_HGSS_MAP_INVENTORY_PREVIEW_ONLY",
                message: "HeartGold/SoulSilver map inventory for \(record.relativePath) is source provenance and blocker metadata only.",
                span: record.sourceSpan
            ),
            Diagnostic(
                severity: .warning,
                code: "NDS_DATA_HGSS_MAP_WRITE_BLOCKED",
                message: "HeartGold/SoulSilver map matrix and map table writes remain blocked; blocked actions: \(heartGoldSoulSilverMapBlockedActions.joined(separator: ", ")).",
                span: record.sourceSpan
            )
        ]
    }

    private static let heartGoldSoulSilverScriptSequenceBlockedActions = [
        "script parsing",
        "semantic editing",
        "script binary write",
        "script compiler",
        "generated output write",
        "reference write",
        "NARC rebuild",
        "container rebuild",
        "ROM rebuild",
        "ROM export",
        "binary write"
    ]

    private static let heartGoldSoulSilverScriptSequenceActionState = "HeartGold/SoulSilver script sequence rows are inventory-only HGSS script-sequence metadata; no parser, compiler, semantic editor, binary writer, container rebuild, ROM export, ROM rebuild, or mutation apply path is enabled."

    private static func enrichHeartGoldSoulSilverScriptSequenceInventory(
        records: [NDSDataCatalogRecord],
        profile: GameProfile
    ) -> [NDSDataCatalogRecord] {
        guard profile == .pokeheartgold else { return records }
        return records.map { record in
            guard let sourceRole = heartGoldSoulSilverScriptSequenceSourceRole(for: record) else {
                return record
            }

            let facts = [
                SourceIndexFact(label: "Gen IV Source Role", value: sourceRole),
                SourceIndexFact(label: "Gen IV Source Provenance", value: "heartGoldSoulSilver:files/fielddata/script/scr_seq"),
                SourceIndexFact(label: "Gen IV Blocked Actions", value: heartGoldSoulSilverScriptSequenceBlockedActions.joined(separator: ", ")),
                SourceIndexFact(label: "Gen IV Action State", value: heartGoldSoulSilverScriptSequenceActionState)
            ]
            return record.copy(
                facts: record.facts + facts,
                diagnostics: record.diagnostics + heartGoldSoulSilverScriptSequenceDiagnostics(for: record)
            )
        }
    }

    private static func heartGoldSoulSilverScriptSequenceSourceRole(for record: NDSDataCatalogRecord) -> String? {
        guard record.domain == .scripts else { return nil }
        let lower = record.relativePath.lowercased()
        if lower == "files/fielddata/script/scr_seq" {
            return "hgssScriptSequenceInventory"
        }
        if lower.hasPrefix("files/fielddata/script/scr_seq/") {
            return "hgssScriptSequenceMember"
        }
        return nil
    }

    private static func heartGoldSoulSilverScriptSequenceDiagnostics(for record: NDSDataCatalogRecord) -> [Diagnostic] {
        return [
            Diagnostic(
                severity: .info,
                code: "NDS_DATA_HGSS_SCRIPT_SEQUENCE_INVENTORY_PREVIEW_ONLY",
                message: "HeartGold/SoulSilver script sequence inventory for \(record.relativePath) is source provenance and blocker metadata only.",
                span: record.sourceSpan
            ),
            Diagnostic(
                severity: .warning,
                code: "NDS_DATA_HGSS_SCRIPT_SEQUENCE_WRITE_BLOCKED",
                message: "HeartGold/SoulSilver script sequence parsing, compilation, binary writes, rebuilds, exports, and mutation apply remain blocked; blocked actions: \(heartGoldSoulSilverScriptSequenceBlockedActions.joined(separator: ", ")).",
                span: record.sourceSpan
            )
        ]
    }

    private static let diamondPearlMapInventoryBlockedActions = [
        "semantic editing",
        "raw C-anchor write",
        "map editor",
        "matrix compiler",
        "map data compiler",
        "generated output write",
        "reference write",
        "NARC rebuild",
        "ROM rebuild",
        "ROM export",
        "binary write"
    ]

    private static let diamondPearlMapHeaderBlockedActions = [
        "non-integer C scalar write",
        "row add/remove/reorder",
        "map table write",
        "map matrix write",
        "land data write",
        "area data write",
        "script write",
        "map editor",
        "matrix compiler",
        "map data compiler",
        "generated output write",
        "reference write",
        "NARC rebuild",
        "ROM rebuild",
        "ROM export",
        "binary write"
    ]

    private static let diamondPearlMapInventoryActionState = "Diamond/Pearl map matrix, map table, land data, and area data rows are inventory-only map metadata; no semantic editor, raw C-anchor writer, compiler, rebuild, export, or binary write path is enabled."
    private static let diamondPearlMapHeaderActionState = "Diamond/Pearl map header rows expose existing integer-literal sMapHeaders scalars through the semantic mutation-plan gate; map table, map matrix, land data, area data, scripts, compilers, generated/reference writes, ROM rebuild/export, and binary writes remain blocked."

    private static func enrichDiamondPearlMapInventory(
        records: [NDSDataCatalogRecord],
        profile: GameProfile
    ) -> [NDSDataCatalogRecord] {
        guard profile == .pokediamond else { return records }
        return records.map { record in
            guard let sourceRole = diamondPearlMapSourceRole(for: record),
                  let provenance = diamondPearlMapSourceProvenance(for: record)
            else {
                return record
            }

            let facts = [
                SourceIndexFact(label: "Gen IV Source Role", value: sourceRole),
                SourceIndexFact(label: "Gen IV Source Provenance", value: provenance),
                SourceIndexFact(label: "Gen IV Readiness", value: diamondPearlMapReadiness(for: record)),
                SourceIndexFact(label: "Gen IV Blocked Actions", value: diamondPearlMapBlockedActions(for: record).joined(separator: ", ")),
                SourceIndexFact(label: "Gen IV Action State", value: diamondPearlMapActionState(for: record))
            ]
            return record.copy(
                facts: record.facts + facts,
                diagnostics: record.diagnostics + diamondPearlMapDiagnostics(for: record)
            )
        }
    }

    private static func diamondPearlMapSourceRole(for record: NDSDataCatalogRecord) -> String? {
        guard record.domain == .maps else { return nil }
        let lower = record.relativePath.lowercased()
        if lower == "arm9/src/map_header.c" {
            return "dpMapHeaderCAnchor"
        }
        if lower == "files/fielddata/mapmatrix" {
            return "dpMapMatrixInventory"
        }
        if lower.hasPrefix("files/fielddata/mapmatrix/") {
            return "dpMapMatrixMember"
        }
        if lower == "files/fielddata/maptable" {
            return "dpMapTableInventory"
        }
        if lower.hasPrefix("files/fielddata/maptable/") {
            return "dpMapTableMember"
        }
        if lower == "files/fielddata/land_data" {
            return "dpLandDataInventory"
        }
        if lower.hasPrefix("files/fielddata/land_data/") {
            return "dpLandDataMember"
        }
        if lower == "files/fielddata/areadata" {
            return "dpAreaDataInventory"
        }
        if lower.hasPrefix("files/fielddata/areadata/") {
            return "dpAreaDataMember"
        }
        return nil
    }

    private static func diamondPearlMapSourceProvenance(for record: NDSDataCatalogRecord) -> String? {
        let lower = record.relativePath.lowercased()
        if lower == "arm9/src/map_header.c" {
            return "diamondPearl:arm9/src/map_header.c"
        }
        if lower == "files/fielddata/mapmatrix" || lower.hasPrefix("files/fielddata/mapmatrix/") {
            return "diamondPearl:files/fielddata/mapmatrix"
        }
        if lower == "files/fielddata/maptable" || lower.hasPrefix("files/fielddata/maptable/") {
            return "diamondPearl:files/fielddata/maptable"
        }
        if lower == "files/fielddata/land_data" || lower.hasPrefix("files/fielddata/land_data/") {
            return "diamondPearl:files/fielddata/land_data"
        }
        if lower == "files/fielddata/areadata" || lower.hasPrefix("files/fielddata/areadata/") {
            return "diamondPearl:files/fielddata/areadata"
        }
        return nil
    }

    private static func isDiamondPearlMapHeaderRecord(_ record: NDSDataCatalogRecord) -> Bool {
        record.domain == .maps && record.relativePath.lowercased() == "arm9/src/map_header.c"
    }

    private static func diamondPearlMapReadiness(for record: NDSDataCatalogRecord) -> String {
        isDiamondPearlMapHeaderRecord(record) ? "semanticIntegerScalars" : "inventoryOnly"
    }

    private static func diamondPearlMapBlockedActions(for record: NDSDataCatalogRecord) -> [String] {
        isDiamondPearlMapHeaderRecord(record) ? diamondPearlMapHeaderBlockedActions : diamondPearlMapInventoryBlockedActions
    }

    private static func diamondPearlMapActionState(for record: NDSDataCatalogRecord) -> String {
        isDiamondPearlMapHeaderRecord(record) ? diamondPearlMapHeaderActionState : diamondPearlMapInventoryActionState
    }

    private static func diamondPearlMapDiagnostics(for record: NDSDataCatalogRecord) -> [Diagnostic] {
        if isDiamondPearlMapHeaderRecord(record) {
            return [
                Diagnostic(
                    severity: .info,
                    code: "NDS_DATA_DP_MAP_HEADER_SEMANTIC_SCALARS",
                    message: "Diamond/Pearl map header C anchor for \(record.relativePath) exposes existing integer-literal sMapHeaders scalar fields through the semantic mutation-plan gate.",
                    span: record.sourceSpan
                ),
                Diagnostic(
                    severity: .warning,
                    code: "NDS_DATA_DP_MAP_HEADER_WRITE_LIMITED",
                    message: "Diamond/Pearl map header writes are limited to existing integer-literal sMapHeaders scalar replacements; blocked actions: \(diamondPearlMapHeaderBlockedActions.joined(separator: ", ")).",
                    span: record.sourceSpan
                )
            ]
        }
        return [
            Diagnostic(
                severity: .info,
                code: "NDS_DATA_DP_MAP_INVENTORY_PREVIEW_ONLY",
                message: "Diamond/Pearl map inventory for \(record.relativePath) is source provenance and blocker metadata only.",
                span: record.sourceSpan
            ),
            Diagnostic(
                severity: .warning,
                code: "NDS_DATA_DP_MAP_WRITE_BLOCKED",
                message: "Diamond/Pearl map matrix, map table, land data, and area data writes remain blocked; blocked actions: \(diamondPearlMapInventoryBlockedActions.joined(separator: ", ")).",
                span: record.sourceSpan
            )
        ]
    }

    private static let diamondPearlMoveCAnchorBlockedActions = [
        "non-simple move C scalar write",
        "missing field insertion",
        "row insert/remove/reorder",
        "encounter C-anchor writer",
        "NARC/container work",
        "generated output write",
        "reference write",
        "ROM rebuild",
        "ROM export",
        "binary write"
    ]

    private static let diamondPearlMoveCAnchorActionState = "Diamond/Pearl move C anchor arm9/src/waza.c exposes existing simple scalar fields in exact static const struct WazaTbl sWazaTbl[] direct designated entries through the semantic mutation-plan gate; encounters, non-simple expressions, missing fields, row insert/remove/reorder, NARC/container work, generated/reference writes, ROM rebuild/export, and binary writes remain blocked."

    private static func enrichDiamondPearlMoveCAnchorReadiness(
        records: [NDSDataCatalogRecord],
        profile: GameProfile
    ) -> [NDSDataCatalogRecord] {
        guard profile == .pokediamond else { return records }
        return records.map { record in
            guard isDiamondPearlMoveCAnchorRecord(record) else {
                return record
            }
            let facts = [
                SourceIndexFact(label: "Gen IV Source Role", value: "dpMoveCAnchorSemanticScalars"),
                SourceIndexFact(label: "Gen IV Source Provenance", value: "diamondPearl:arm9/src/waza.c"),
                SourceIndexFact(label: "Gen IV Readiness", value: "semanticSimpleScalars"),
                SourceIndexFact(label: "Gen IV Blocked Actions", value: diamondPearlMoveCAnchorBlockedActions.joined(separator: ", ")),
                SourceIndexFact(label: "Gen IV Action State", value: diamondPearlMoveCAnchorActionState)
            ]
            return record.copy(
                facts: record.facts + facts,
                readiness: .some(diamondPearlMoveCAnchorReadiness(for: record)),
                diagnostics: record.diagnostics + diamondPearlMoveCAnchorDiagnostics(for: record)
            )
        }
    }

    private static func isDiamondPearlMoveCAnchorRecord(_ record: NDSDataCatalogRecord) -> Bool {
        record.domain == .moves
            && record.relativePath.lowercased() == "arm9/src/waza.c"
            && record.format == .cSource
    }

    private static func diamondPearlMoveCAnchorReadiness(for record: NDSDataCatalogRecord) -> NDSDataReadinessSummary {
        NDSDataReadinessSummary(
            status: .partial,
            title: "Diamond/Pearl move C-anchor simple scalar readiness",
            detail: "\(record.relativePath) exposes existing simple scalar fields in exact static const struct WazaTbl sWazaTbl[] direct designated entries through the semantic mutation-plan gate; adjacent C anchors, non-simple expressions, missing fields, row shape changes, NARC/container work, generated/reference writes, ROM rebuild/export, and binary writes remain blocked.",
            blockedActions: diamondPearlMoveCAnchorBlockedActions
        )
    }

    private static func diamondPearlMoveCAnchorDiagnostics(for record: NDSDataCatalogRecord) -> [Diagnostic] {
        [
            Diagnostic(
                severity: .info,
                code: "NDS_DATA_DP_MOVE_C_ANCHOR_SEMANTIC_SCALARS",
                message: "Diamond/Pearl move C anchor \(record.relativePath) exposes existing simple scalar WazaTbl fields through the semantic mutation-plan gate.",
                span: record.sourceSpan
            ),
            Diagnostic(
                severity: .warning,
                code: "NDS_DATA_DP_MOVE_C_ANCHOR_WRITE_LIMITED",
                message: "Diamond/Pearl move C-anchor writes are limited to existing simple scalar replacements; blocked actions: \(diamondPearlMoveCAnchorBlockedActions.joined(separator: ", ")).",
                span: record.sourceSpan
            )
        ]
    }

    private struct DiamondPearlCAnchorFutureSpec {
        let domain: NDSDataDomain
        let relativePath: String
        let sourceRole: String
        let domainLabel: String
        let diagnosticCode: String
    }

    private static let diamondPearlCAnchorFutureSpecs = [
        DiamondPearlCAnchorFutureSpec(
            domain: .encounters,
            relativePath: "arm9/src/encounter.c",
            sourceRole: "dpEncounterCAnchorFutureRow",
            domainLabel: "encounter",
            diagnosticCode: "NDS_DATA_DP_ENCOUNTER_C_ANCHOR_FUTURE_ROW"
        )
    ]

    private static func enrichDiamondPearlCAnchorFutureReadiness(
        records: [NDSDataCatalogRecord],
        profile: GameProfile
    ) -> [NDSDataCatalogRecord] {
        guard profile == .pokediamond else { return records }
        return records.map { record in
            guard let spec = diamondPearlCAnchorFutureSpec(for: record) else {
                return record
            }
            let blockedActions = diamondPearlCAnchorFutureBlockedActions(for: spec)
            let readiness = diamondPearlCAnchorFutureReadiness(for: record, spec: spec, blockedActions: blockedActions)
            let facts = [
                SourceIndexFact(label: "Gen IV Source Role", value: spec.sourceRole),
                SourceIndexFact(label: "Gen IV Source Provenance", value: "diamondPearl:\(spec.relativePath)"),
                SourceIndexFact(label: "Gen IV Readiness", value: "futureRowBlocked"),
                SourceIndexFact(label: "Gen IV Future Row", value: "PHS-T98"),
                SourceIndexFact(label: "Gen IV Blocked Actions", value: blockedActions.joined(separator: ", ")),
                SourceIndexFact(label: "Gen IV Action State", value: diamondPearlCAnchorFutureActionState(for: spec))
            ]
            return record.copy(
                facts: record.facts + facts,
                readiness: .some(readiness),
                diagnostics: record.diagnostics + diamondPearlCAnchorFutureDiagnostics(
                    for: record,
                    spec: spec,
                    blockedActions: blockedActions
                )
            )
        }
    }

    private static func diamondPearlCAnchorFutureSpec(for record: NDSDataCatalogRecord) -> DiamondPearlCAnchorFutureSpec? {
        let lower = record.relativePath.lowercased()
        return diamondPearlCAnchorFutureSpecs.first { spec in
            record.domain == spec.domain && lower == spec.relativePath
        }
    }

    private static func diamondPearlCAnchorFutureBlockedActions(for spec: DiamondPearlCAnchorFutureSpec) -> [String] {
        [
            "semantic editing",
            "\(spec.domainLabel) C-anchor writer",
            "NARC/container work",
            "generated output write",
            "reference write",
            "ROM rebuild",
            "ROM export",
            "binary write"
        ]
    }

    private static func diamondPearlCAnchorFutureActionState(for spec: DiamondPearlCAnchorFutureSpec) -> String {
        "Diamond/Pearl \(spec.domainLabel) C anchor \(spec.relativePath) is indexed as a future PHS-T98 row only; no parser, semantic editor, \(spec.domainLabel) C-anchor writer, NARC/container work, generated/reference write, ROM rebuild/export, or binary write path is enabled."
    }

    private static func diamondPearlCAnchorFutureReadiness(
        for record: NDSDataCatalogRecord,
        spec: DiamondPearlCAnchorFutureSpec,
        blockedActions: [String]
    ) -> NDSDataReadinessSummary {
        NDSDataReadinessSummary(
            status: .blocked,
            title: "Diamond/Pearl \(spec.domainLabel) C-anchor future-row readiness",
            detail: "\(record.relativePath) is visible for future PHS-T98 schema work only; no parser, semantic editor, \(spec.domainLabel) C-anchor writer, NARC/container work, generated/reference write, ROM rebuild/export, or binary write path is enabled.",
            blockedActions: blockedActions
        )
    }

    private static func diamondPearlCAnchorFutureDiagnostics(
        for record: NDSDataCatalogRecord,
        spec: DiamondPearlCAnchorFutureSpec,
        blockedActions: [String]
    ) -> [Diagnostic] {
        [
            Diagnostic(
                severity: .warning,
                code: spec.diagnosticCode,
                message: "Diamond/Pearl \(spec.domainLabel) C anchor \(record.relativePath) is a read-only future-row catalog fact; blocked actions: \(blockedActions.joined(separator: ", ")).",
                span: record.sourceSpan
            )
        ]
    }

    private static func genVReadinessSummary(for record: NDSDataCatalogRecord) -> NDSDataReadinessSummary {
        let sourceRole = genVSourceRole(for: record)
        if isGenVUnavailableTitle(record) {
            return NDSDataReadinessSummary(
                status: .blocked,
                title: "Gen V title unavailable",
                detail: "\(genVUnavailableReason(for: record) ?? genVSourceRoleDetail(for: sourceRole)) This is diagnostic-only title coverage metadata; no source tree, editor, extraction, rebuild, playtest, export, or binary write path is available. \(Self.genVActionStateSummary)",
                blockedActions: genVBlockedActions
            )
        }
        let status: NDSDataReadinessStatus = record.role == .binaryContainer || record.containerSummary != nil || record.format == .narc
            ? .blocked
            : .partial
        return NDSDataReadinessSummary(
            status: status,
            title: "Gen V read-only readiness",
            detail: "\(genVSourceRoleDetail(for: sourceRole)) This is clean-room Gen V routing metadata only; \(Self.genVActionStateSummary)",
            blockedActions: genVBlockedActions
        )
    }

    private static func genVReadinessFacts(
        for record: NDSDataCatalogRecord,
        existingRelativePaths: Set<String>
    ) -> [SourceIndexFact] {
        var facts = [
            SourceIndexFact(label: "Gen V Readiness", value: isGenVUnavailableTitle(record) ? "unavailable" : "previewOnly"),
            SourceIndexFact(label: "Gen V Source Role", value: genVSourceRole(for: record)),
            SourceIndexFact(label: "Gen V Blocked Actions", value: genVBlockedActions.joined(separator: ", ")),
            SourceIndexFact(label: "Gen V Action State", value: Self.genVActionStateSummary),
            SourceIndexFact(label: "Gen V Reference Posture", value: "cleanRoomReferenceOnly")
        ]
        facts.append(contentsOf: genVBuildMetadataFacts(for: record, existingRelativePaths: existingRelativePaths))
        facts.append(contentsOf: genVMessageCandidateFacts(for: record, existingRelativePaths: existingRelativePaths))
        facts.append(contentsOf: genVEncounterRecordFacts(for: record))
        facts.append(contentsOf: genVVariantFacts(for: record))
        return facts
    }

    private static func genVEncounterRecordFacts(for record: NDSDataCatalogRecord) -> [SourceIndexFact] {
        guard record.domain == .encounters,
              record.relativePath.lowercased().hasPrefix("data/encounters/")
        else {
            return []
        }

        let path = URL(fileURLWithPath: record.relativePath)
        var facts = [
            SourceIndexFact(label: "Gen V Encounter Record", value: "previewOnly"),
            SourceIndexFact(label: "Gen V Encounter Source", value: "data/encounters"),
            SourceIndexFact(label: "Gen V Encounter Key", value: path.deletingPathExtension().lastPathComponent),
            SourceIndexFact(label: "Gen V Encounter Format", value: record.format.rawValue),
            SourceIndexFact(label: "Gen V Encounter Parse State", value: "metadataOnly")
        ]
        if let recordCount = record.recordCount {
            facts.append(SourceIndexFact(label: "Gen V Encounter Shallow Count", value: "\(recordCount)"))
        }
        if let byteCount = record.byteCount {
            facts.append(SourceIndexFact(label: "Gen V Encounter Bytes", value: "\(byteCount)"))
        }
        return facts
    }

    private static func genVMessageCandidateFacts(
        for record: NDSDataCatalogRecord,
        existingRelativePaths: Set<String>
    ) -> [SourceIndexFact] {
        let lower = record.relativePath.lowercased()
        guard lower == "files/msgdata" || lower.hasPrefix("files/msgdata/") else { return [] }

        if lower == "files/msgdata" {
            let candidatePaths = existingRelativePaths
                .filter { $0.hasPrefix("files/msgdata/") }
                .sorted()
            let extensions = Array(Set(candidatePaths.map { URL(fileURLWithPath: $0).pathExtension.lowercased() }.filter { !$0.isEmpty })).sorted()
            var facts = [
                SourceIndexFact(label: "Gen V Message Candidate Count", value: "\(candidatePaths.count)"),
                SourceIndexFact(label: "Gen V Message Candidate Basis", value: "pathExtensionOnly"),
                SourceIndexFact(label: "Gen V Message Candidate Posture", value: "previewOnlyFilenameFacts")
            ]
            if !extensions.isEmpty {
                facts.append(SourceIndexFact(label: "Gen V Message Candidate Extensions", value: extensions.joined(separator: ", ")))
            }
            return facts
        }

        let url = URL(fileURLWithPath: record.relativePath)
        let ext = url.pathExtension.lowercased()
        let stem = url.deletingPathExtension().lastPathComponent
        var facts = [
            SourceIndexFact(label: "Gen V Message Candidate Kind", value: genVMessageCandidateKind(for: lower)),
            SourceIndexFact(label: "Gen V Message Candidate Basis", value: "pathExtensionOnly"),
            SourceIndexFact(label: "Gen V Message Candidate Posture", value: "previewOnlyFilenameFacts"),
            SourceIndexFact(label: "Gen V Message Decoded Preview", value: "noDecodedPreview")
        ]
        if let byteCount = record.byteCount {
            facts.append(SourceIndexFact(label: "Gen V Message Candidate Bytes", value: "\(byteCount)"))
        }
        if ["txt", "gmm", "str"].contains(ext),
           let lineCount = record.recordCount {
            facts.append(SourceIndexFact(label: "Gen V Message Candidate Lines", value: "\(lineCount)"))
        }
        if ["bin", "dat", "msg"].contains(ext) {
            let hints = digitRuns(in: stem)
            if !hints.isEmpty {
                facts.append(SourceIndexFact(label: "Gen V Message Numeric Bank Hint", value: hints.joined(separator: ", ")))
            }
        }
        return facts
    }

    private static func genVMessageCandidateKind(for relativePath: String) -> String {
        let url = URL(fileURLWithPath: relativePath)
        let ext = url.pathExtension.lowercased()
        let stem = url.deletingPathExtension().lastPathComponent.lowercased()
        switch ext {
        case "txt", "gmm", "str":
            return "sourceTextCandidate"
        case "bin", "dat", "msg":
            return stem.contains { $0.isNumber } ? "numberedBinaryBankCandidate" : "binaryBankCandidate"
        default:
            return ext.isEmpty ? "messagePathCandidate" : "messageAssetCandidate"
        }
    }

    private static func digitRuns(in value: String) -> [String] {
        var runs: [String] = []
        var current = ""
        for character in value {
            if character.isNumber {
                current.append(character)
            } else if !current.isEmpty {
                runs.append(current)
                current = ""
            }
        }
        if !current.isEmpty {
            runs.append(current)
        }
        return runs
    }

    private static func genVBuildMetadataFacts(
        for record: NDSDataCatalogRecord,
        existingRelativePaths: Set<String>
    ) -> [SourceIndexFact] {
        guard record.relativePath.lowercased() == "makefile" else { return [] }

        func presence(_ path: String) -> String {
            existingRelativePaths.contains(path.lowercased()) ? "present" : "missing"
        }

        let linkerPresence = ["arm9.ld", "arm7.ld"]
            .map { "\($0)=\(presence($0))" }
            .joined(separator: ", ")
        let variantHashPresence = ["black.us/rom.sha1", "white.us/rom.sha1", "black2.us/rom.sha1", "white2.us/rom.sha1"]
            .map { "\($0)=\(presence($0))" }
            .joined(separator: ", ")

        return [
            SourceIndexFact(label: "Gen V Build Metadata", value: "previewOnly"),
            SourceIndexFact(label: "Gen V Makefile Presence", value: presence("Makefile")),
            SourceIndexFact(label: "Gen V Config Presence", value: presence("config.mk")),
            SourceIndexFact(label: "Gen V Linker Presence", value: linkerPresence),
            SourceIndexFact(label: "Gen V Variant Hash Presence", value: variantHashPresence),
            SourceIndexFact(label: "Gen V main.rsf Presence", value: presence("main.rsf")),
            SourceIndexFact(label: "Gen V main.lsf Presence", value: presence("main.lsf"))
        ]
    }

    private static func genVSHA1TextFacts(
        relativePath: String,
        url: URL,
        exists: Bool,
        isDirectory: Bool
    ) -> [SourceIndexFact] {
        let checksumPaths: Set<String> = [
            "black.us/rom.sha1",
            "white.us/rom.sha1",
            "black2.us/rom.sha1",
            "white2.us/rom.sha1"
        ]
        guard exists, !isDirectory, checksumPaths.contains(relativePath.lowercased()) else { return [] }
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8)
        else {
            return [SourceIndexFact(label: "Gen V SHA1 Text State", value: "invalid")]
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return [SourceIndexFact(label: "Gen V SHA1 Text State", value: "empty")]
        }

        guard let firstToken = trimmed.split(whereSeparator: { $0.isWhitespace }).first,
              firstToken.count == 40,
              firstToken.allSatisfy({ $0.isHexDigit })
        else {
            return [SourceIndexFact(label: "Gen V SHA1 Text State", value: "invalid")]
        }

        let digest = firstToken.lowercased()
        return [
            SourceIndexFact(label: "Gen V SHA1 Text State", value: "valid"),
            SourceIndexFact(label: "Gen V SHA1 Text Digest", value: digest)
        ]
    }

    private struct GenVDirectoryInventorySummary {
        let factLabelPrefix: String
        let memberCount: Int
        let byteCount: UInt64
        let samplePaths: [String]
    }

    private static func genVDirectoryInventory(
        relativePath: String,
        url: URL,
        exists: Bool,
        isDirectory: Bool,
        fileManager: FileManager
    ) -> GenVDirectoryInventorySummary? {
        guard exists, isDirectory else {
            return nil
        }
        let factLabelPrefix: String
        switch relativePath.lowercased() {
        case "files/fielddata/script":
            factLabelPrefix = "Gen V Script"
        case "overlays":
            factLabelPrefix = "Gen V Overlay"
        case "ndsdisasm_config":
            factLabelPrefix = "Gen V Disassembly Config"
        default:
            return nil
        }

        let members = recursiveMemberFiles(url: url, fileManager: fileManager)
        let byteCount = members.reduce(UInt64(0)) { total, member in
            total + (member.byteCount ?? UInt64(0))
        }
        let samplePaths = members.prefix(maxContainerSampleMembers).map { member in
            "\(relativePath)/\(member.relativePath)"
        }
        return GenVDirectoryInventorySummary(
            factLabelPrefix: factLabelPrefix,
            memberCount: members.count,
            byteCount: byteCount,
            samplePaths: samplePaths
        )
    }

    private static func genVDirectoryInventoryFacts(
        _ inventory: GenVDirectoryInventorySummary?
    ) -> [SourceIndexFact] {
        guard let inventory else { return [] }
        var facts = [
            SourceIndexFact(label: "\(inventory.factLabelPrefix) Members", value: "\(inventory.memberCount)"),
            SourceIndexFact(label: "\(inventory.factLabelPrefix) Bytes", value: "\(inventory.byteCount)")
        ]
        if !inventory.samplePaths.isEmpty {
            facts.append(SourceIndexFact(label: "\(inventory.factLabelPrefix) Sample Paths", value: inventory.samplePaths.joined(separator: ", ")))
        }
        return facts
    }

    private static func genVDirectoryInventoryPreview(
        _ inventory: GenVDirectoryInventorySummary?
    ) -> String? {
        guard let inventory, !inventory.samplePaths.isEmpty else { return nil }
        return inventory.samplePaths.joined(separator: ", ")
    }

    private static func genVVariantFacts(for record: NDSDataCatalogRecord) -> [SourceIndexFact] {
        guard let spec = genVTitleCoverageSpec(for: record) else { return [] }
        var facts: [SourceIndexFact] = []
        if genVTitle(for: record) == nil {
            facts.append(SourceIndexFact(label: "Gen V Title", value: spec.title))
        }
        if record.facts.first(where: { $0.label == "Gen V Variant ID" }) == nil {
            facts.append(SourceIndexFact(label: "Gen V Variant ID", value: spec.id))
        }
        if record.facts.first(where: { $0.label == "Gen V Family" }) == nil {
            facts.append(SourceIndexFact(label: "Gen V Family", value: spec.family))
        }
        if record.facts.first(where: { $0.label == "Gen V Source Name" }) == nil {
            facts.append(SourceIndexFact(label: "Gen V Source Name", value: genVSourceName(for: record, spec: spec)))
        }
        if record.facts.first(where: { $0.label == "Gen V Source Marker" }) == nil {
            let exactMarker = spec.sourceMarkerPaths.first { record.relativePath == $0 }
            let parentMarker = spec.sourceMarkerPaths.first { record.relativePath.hasPrefix($0 + "/") }
            let marker = exactMarker ?? parentMarker ?? spec.sourceMarkerPaths.joined(separator: ", ")
            facts.append(SourceIndexFact(label: "Gen V Source Marker", value: marker))
        }
        if record.facts.first(where: { $0.label == "Gen V Variant State" }) == nil {
            facts.append(SourceIndexFact(label: "Gen V Variant State", value: isGenVUnavailableTitle(record) ? "unavailable" : "sourceMarkerPresent"))
        }
        return facts
    }

    private static func genVReadinessDiagnostics(
        for record: NDSDataCatalogRecord,
        readiness: NDSDataReadinessSummary
    ) -> [Diagnostic] {
        if isGenVUnavailableTitle(record) {
            return [
                Diagnostic(
                    severity: .warning,
                    code: "NDS_GEN_V_TITLE_UNAVAILABLE",
                    message: "\(genVTitle(for: record) ?? record.title) is listed as unavailable Gen V coverage. \(readiness.detail)",
                    span: record.sourceSpan
                ),
                Diagnostic(
                    severity: .warning,
                    code: "NDS_GEN_V_WRITE_BLOCKED",
                    message: "Unavailable Gen V title rows are diagnostic-only; blocked actions: \(genVBlockedActions.joined(separator: ", ")).",
                    span: record.sourceSpan
                )
            ]
        }
        return [
            Diagnostic(
                severity: .info,
                code: "NDS_GEN_V_READINESS_PREVIEW_ONLY",
                message: "Gen V readiness for \(record.relativePath) is preview-only metadata. \(readiness.detail)",
                span: record.sourceSpan
            ),
            Diagnostic(
                severity: .warning,
                code: "NDS_GEN_V_WRITE_BLOCKED",
                message: "Gen V source rows remain read-only in this slice; blocked actions: \(genVBlockedActions.joined(separator: ", ")).",
                span: record.sourceSpan
            )
        ]
    }

    private static func genVSourceName(for record: NDSDataCatalogRecord, spec: GenVTitleCoverageSpec) -> String {
        guard spec.sourceName == "none", !isGenVUnavailableTitle(record), spec.family == "black2White2" else {
            return spec.sourceName
        }
        return "localBlack2White2SourceInventory"
    }

    private static func genVSourceRole(for record: NDSDataCatalogRecord) -> String {
        if isGenVUnavailableTitle(record) {
            return "titleUnavailable"
        }
        let lower = record.relativePath.lowercased()
        if lower.hasPrefix("data/encounters/") {
            return "encounterPreview"
        }
        if lower == "data" {
            return "dataInventory"
        }
        if lower == "makefile" || lower == "config.mk" {
            return "buildConfig"
        }
        if lower == "arm9.ld" || lower == "arm7.ld" {
            return "linkerConfig"
        }
        if lower == "src" {
            return "sourceCodeInventory"
        }
        if lower == "asm" {
            return "assemblyInventory"
        }
        if lower == "include" {
            return "headerInventory"
        }
        if genVTitleCoverageSpecs.contains(where: { $0.id == lower }) {
            return "variantSourceInventory"
        }
        if lower == "files" {
            return "nitroFSRootInventory"
        }
        if lower == "files/a" {
            return "nitroArchiveGroupInventory"
        }
        if lower.hasPrefix("files/a/") {
            return "nitroArchiveGroup"
        }
        if lower == "files/fielddata" {
            return "fielddataInventory"
        }
        if lower == "files/fielddata/mapmatrix" {
            return "fielddataMapMatrixInventory"
        }
        if lower.hasPrefix("files/fielddata/mapmatrix/") {
            return "fielddataMapMatrixMember"
        }
        if lower == "files/fielddata/maptable" {
            return "fielddataMapTableInventory"
        }
        if lower.hasPrefix("files/fielddata/maptable/") {
            return "fielddataMapTableMember"
        }
        if lower == "files/fielddata/script" {
            return "fielddataScriptInventory"
        }
        if lower.hasPrefix("files/fielddata/script/") {
            return "fielddataScriptMember"
        }
        if lower == "files/fielddata/eventdata/zone_event" {
            return "fielddataZoneEventInventory"
        }
        if lower.hasPrefix("files/fielddata/eventdata/zone_event/") {
            return "fielddataZoneEventMetadata"
        }
        if lower == "files/msgdata" {
            return "messageBankInventory"
        }
        if lower.hasPrefix("files/"), lower.hasSuffix(".sdat") {
            return "soundArchiveMetadata"
        }
        if isGenVSoundContainer(record, lower: lower) {
            return "soundContainerRoute"
        }
        if record.domain == .audio {
            return "audioMetadata"
        }
        if record.role == .binaryContainer || record.containerSummary != nil || record.format == .narc {
            return "boundedContainerSummary"
        }
        if lower.hasPrefix("files/msgdata/") {
            return "messageBankMetadata"
        }
        if lower.hasPrefix("files/") {
            return "nitroFSResource"
        }
        if lower == "overlays" {
            return "overlayInventory"
        }
        if lower.hasPrefix("overlays/") {
            return "overlayRouting"
        }
        if lower == "ndsdisasm_config" {
            return "disassemblyConfigInventory"
        }
        if lower.hasPrefix("ndsdisasm_config/") {
            return "disassemblyConfig"
        }
        if lower == "main.rsf" {
            return "filesystemManifest"
        }
        if lower == "main.lsf" {
            return "linkerScript"
        }
        if lower.hasSuffix("/rom.sha1") || lower.hasSuffix(".sha1") {
            return "checksumExpectation"
        }
        return "sourceInventory"
    }

    private static func isGenVSoundContainer(_ record: NDSDataCatalogRecord, lower: String) -> Bool {
        guard lower.hasSuffix(".narc"),
              record.role == .binaryContainer || record.containerSummary != nil || record.format == .narc
        else {
            return false
        }
        return record.domain == .audio
            || lower.contains("sound")
            || lower.contains("/snd")
            || lower.contains("sdat")
            || lower.contains("sseq")
            || lower.contains("sbnk")
            || lower.contains("swar")
            || lower.contains("strm")
            || lower.contains("bgm")
            || lower.contains("music")
            || lower.contains("cries")
    }

    private static func genVSourceRoleDetail(for role: String) -> String {
        switch role {
        case "encounterPreview":
            return "Encounter data is indexed for preview-only record facts."
        case "dataInventory":
            return "The Gen V data root is summarized as manual-only source inventory."
        case "audioMetadata":
            return "SDAT/SSEQ/SBNK/SWAR/STRM candidates retain read-only audio metadata facts."
        case "soundArchiveMetadata":
            return "Gen V SDAT files under files/ retain read-only sound archive metadata facts."
        case "soundContainerRoute":
            return "Sound-adjacent Gen V NARC rows are routed as manual-only container metadata."
        case "boundedContainerSummary":
            return "Gen V NARC or container-like rows are summarized as bounded manual-only inventory."
        case "buildConfig":
            return "Build configuration is indexed for manual setup and checksum orientation only."
        case "linkerConfig":
            return "Linker configuration is indexed for manual build orientation only."
        case "sourceCodeInventory":
            return "C source roots are summarized as manual-only source inventory."
        case "assemblyInventory":
            return "Assembly roots are summarized as manual-only disassembly inventory."
        case "headerInventory":
            return "Header roots are summarized as manual-only source inventory."
        case "variantSourceInventory":
            return "Variant marker folders are summarized for title coverage and manual-only source orientation."
        case "nitroFSRootInventory":
            return "The files root is summarized as manual-only NitroFS source inventory."
        case "nitroArchiveGroupInventory":
            return "The files/a archive-group root is summarized as manual-only NitroFS inventory."
        case "nitroArchiveGroup":
            return "files/a archive-group paths are identified for future Gen V container routing."
        case "fielddataInventory":
            return "The files/fielddata root is summarized as manual-only Gen V fielddata inventory."
        case "fielddataMapMatrixInventory":
            return "Gen V map matrix roots are summarized as manual-only fielddata map inventory."
        case "fielddataMapMatrixMember":
            return "Gen V map matrix paths are indexed as manual-only fielddata map metadata."
        case "fielddataMapTableInventory":
            return "Gen V map table roots are summarized as manual-only fielddata map inventory."
        case "fielddataMapTableMember":
            return "Gen V map table paths are indexed as manual-only fielddata map metadata."
        case "fielddataScriptInventory":
            return "Gen V fielddata script roots are summarized as manual-only script inventory."
        case "fielddataScriptMember":
            return "Gen V fielddata script paths are indexed as manual-only script metadata."
        case "fielddataZoneEventInventory":
            return "Gen V zone-event roots are summarized as manual-only fielddata event inventory."
        case "fielddataZoneEventMetadata":
            return "Gen V zone-event paths are indexed as manual-only fielddata event metadata."
        case "messageBankInventory":
            return "The files/msgdata root is summarized as manual-only Gen V message-bank inventory."
        case "messageBankMetadata":
            return "Gen V message-bank source paths are indexed as manual-only routing metadata."
        case "nitroFSResource":
            return "NitroFS resource files are indexed as source-tree inventory."
        case "overlayInventory":
            return "The overlays root is summarized as manual-only overlay source inventory."
        case "overlayRouting":
            return "Overlay sources are indexed for disassembly and script-routing context."
        case "disassemblyConfigInventory":
            return "The ndsdisasm_config root is summarized as manual-only disassembly configuration inventory."
        case "disassemblyConfig":
            return "Disassembly configuration files are indexed as orientation metadata."
        case "filesystemManifest":
            return "Filesystem manifest metadata is indexed for source-tree routing."
        case "linkerScript":
            return "Linker script metadata is indexed for source-tree routing."
        case "checksumExpectation":
            return "Checksum expectation files are indexed for build-output comparison context."
        case "titleUnavailable":
            return "No materialized source root is available for this Gen V title."
        default:
            return "Gen V source inventory is indexed for reference orientation."
        }
    }

    private static func isGenVUnavailableTitle(_ record: NDSDataCatalogRecord) -> Bool {
        record.role == .metadataUnavailable && record.relativePath.hasPrefix("unavailable-titles/")
    }

    private static func genVTitle(for record: NDSDataCatalogRecord) -> String? {
        record.facts.first { $0.label == "Gen V Title" }?.value
    }

    private static func genVUnavailableReason(for record: NDSDataCatalogRecord) -> String? {
        record.facts.first { $0.label == "Gen V Unavailable Reason" }?.value
    }

    private static func genVTitleCoverageSpec(for record: NDSDataCatalogRecord) -> GenVTitleCoverageSpec? {
        if let title = genVTitle(for: record) {
            return genVTitleCoverageSpecs.first { $0.title == title }
        }
        return genVTitleCoverageSpecs.first { spec in
            spec.sourceMarkerPaths.contains { marker in
                record.relativePath == marker || record.relativePath.hasPrefix(marker + "/")
            }
        }
    }

    private static func genVSourceMarkerExists(
        for spec: GenVTitleCoverageSpec,
        root: URL,
        fileManager: FileManager
    ) -> Bool {
        spec.sourceMarkerPaths.contains { marker in
            fileManager.fileExists(atPath: root.appendingPathComponent(marker).path)
        }
    }

    private static func factsForRelationships(
        _ relatedRecords: [NDSDataRelatedRecord],
        readiness: NDSDataReadinessSummary?
    ) -> [SourceIndexFact] {
        var facts: [SourceIndexFact] = []
        if let readiness {
            facts.append(SourceIndexFact(label: "Readiness", value: readiness.status.rawValue))
            facts.append(SourceIndexFact(label: "Blocked Actions", value: readiness.blockedActions.joined(separator: ", ")))
        }
        if !relatedRecords.isEmpty {
            facts.append(SourceIndexFact(label: "Related Rows", value: "\(relatedRecords.count)"))
            facts.append(SourceIndexFact(label: "Related Domains", value: Array(Set(relatedRecords.map { $0.domain.rawValue })).sorted().joined(separator: ", ")))
        }
        return facts
    }

    private static func diagnosticsForReadiness(
        _ readiness: NDSDataReadinessSummary?,
        record: NDSDataCatalogRecord
    ) -> [Diagnostic] {
        guard let readiness else { return [] }
        let severity: DiagnosticSeverity = readiness.status == .blocked ? .warning : .info
        return [
            Diagnostic(
                severity: severity,
                code: readiness.status == .blocked ? "NDS_DATA_READINESS_WRITE_BLOCKED" : "NDS_DATA_READINESS_PREVIEW_ONLY",
                message: "\(readiness.title): \(readiness.detail) Blocked actions: \(readiness.blockedActions.joined(separator: ", ")).",
                span: record.sourceSpan
            )
        ]
    }

    private static func relationshipKeys(for record: NDSDataCatalogRecord, profile: GameProfile) -> Set<String> {
        let lower = record.relativePath.lowercased()
        var keys: Set<String> = []

        if profile == .pokeblack,
           genVFielddataRelationshipRootPaths.contains(lower) {
            keys.insert("gen-v-fielddata-roots")
        }

        if lower.contains("map_headers") || lower.contains("map_header") || lower.contains("maptable") {
            keys.insert("map-header")
        }

        if profile == .pokeheartgold,
           heartGoldSoulSilverMapInventoryRelationshipRootPaths.contains(lower) {
            keys.insert("hgss-map-inventory-roots")
        }

        if profile == .pokediamond,
           lower.hasPrefix("arm9/src/"),
           ["map_header.c", "script.c", "msgdata.c"].contains(URL(fileURLWithPath: lower).lastPathComponent) {
            keys.insert("arm9-field-source")
        }

        let url = URL(fileURLWithPath: record.relativePath)
        guard !relationshipExcludedFileNames.contains(url.lastPathComponent.lowercased()) else {
            return keys
        }
        let fileStem = url.deletingPathExtension().lastPathComponent
        let parent = url.deletingLastPathComponent().lastPathComponent
        let raw = fileStem == "map" || fileStem == "script" || fileStem == "text" ? parent : fileStem
        for normalized in relationshipTokenVariants(raw) where !normalized.isEmpty {
            keys.insert("token:\(normalized)")
        }
        return keys
    }

    private static func participatesInRelationships(_ record: NDSDataCatalogRecord, profile: GameProfile) -> Bool {
        if relationshipDomains.contains(record.domain) {
            return true
        }
        return profile == .pokeblack
            && record.domain == .resources
            && genVFielddataRelationshipRootPaths.contains(record.relativePath.lowercased())
    }

    private static func relationshipTokenVariants(_ value: String) -> Set<String> {
        var token = value.lowercased()
            .replacingOccurrences(of: "map_data_", with: "")
            .replacingOccurrences(of: "map_matrix_", with: "")
            .replacingOccurrences(of: "map_", with: "")
            .replacingOccurrences(of: "matrix_", with: "")
            .replacingOccurrences(of: "events_", with: "")
            .replacingOccurrences(of: "scripts_init_", with: "")
            .replacingOccurrences(of: "scripts_", with: "")
            .replacingOccurrences(of: "script_", with: "")
            .replacingOccurrences(of: "scr_seq_", with: "")
            .replacingOccurrences(of: "scr_", with: "")
            .replacingOccurrences(of: "zone_", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        while token.count > 1, token.first == "0", token.dropFirst().allSatisfy(\.isNumber) {
            token.removeFirst()
        }

        var variants: Set<String> = token.isEmpty ? [] : [token]
        if let suffix = token.split(separator: "_").last.map(String.init),
           !suffix.isEmpty,
           suffix.allSatisfy(\.isNumber) {
            variants.insert(suffix)
        }
        return variants
    }

    private static func relationshipLabel(for record: NDSDataCatalogRecord) -> String {
        switch record.domain {
        case .maps where record.relativePath.lowercased().contains("matri"):
            return "Matrix"
        case .maps where record.relativePath.lowercased().contains("header") || record.relativePath.lowercased().contains("maptable"):
            return "Map header"
        case .maps:
            return "Map resource"
        case .scripts:
            return "Script resource"
        case .text:
            return "Text bank"
        default:
            return record.domain.rawValue
        }
    }

    private static func shallowRecordCount(
        url: URL,
        format: NDSDataSourceFormat,
        isDirectory: Bool,
        fileManager: FileManager
    ) -> Int? {
        if isDirectory {
            return recursiveFileCount(url: url, fileManager: fileManager)
        }
        guard let data = try? Data(contentsOf: url) else { return nil }
        switch format {
        case .json:
            guard let json = try? JSONSerialization.jsonObject(with: data) else { return nil }
            if let array = json as? [Any] { return array.count }
            return 1
        case .csv:
            guard let text = String(data: data, encoding: .utf8) else { return nil }
            let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            return max(lines.count - 1, 0)
        case .text, .cHeader, .cSource:
            guard let text = String(data: data, encoding: .utf8) else { return nil }
            return text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        case .directory:
            return recursiveFileCount(url: url, fileManager: fileManager)
        case .narc, .binary, .unknown:
            return nil
        }
    }

    private static func recursiveFileCount(url: URL, fileManager: FileManager) -> Int {
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return 0
        }
        var count = 0
        while let fileURL = enumerator.nextObject() as? URL {
            let values = try? fileURL.resourceValues(forKeys: [.isDirectoryKey])
            if values?.isDirectory == true {
                if excludedDirectoryNames.contains(fileURL.lastPathComponent) {
                    enumerator.skipDescendants()
                }
                continue
            }
            count += 1
        }
        return count
    }

    private static func containerSummary(
        url: URL,
        relativePath: String,
        format: NDSDataSourceFormat,
        isDirectory: Bool,
        fileManager: FileManager
    ) -> NDSDataContainerSummary? {
        if format == .narc, !isDirectory, let data = try? Data(contentsOf: url) {
            return containerSummary(for: NARCParser.parse(path: relativePath, data: data), data: data, byteCount: UInt64(data.count))
        }
        if isDirectory {
            return unpackedArchiveSummary(url: url, fileManager: fileManager)
        }
        return nil
    }

    private static func containerSummary(
        for index: NARCIndex,
        data: Data? = nil,
        memberFingerprints: [NDSDataContainerMemberFingerprint]? = nil,
        byteCount: UInt64?
    ) -> NDSDataContainerSummary {
        let namedCount = index.members.filter { $0.name != nil }.count
        let fingerprints = memberFingerprints ?? Self.memberFingerprints(for: index, data: data)
        return NDSDataContainerSummary(
            kind: .narc,
            memberCount: index.memberCount,
            namedMemberCount: namedCount,
            unnamedMemberCount: max(index.memberCount - namedCount, 0),
            byteCount: byteCount,
            sampleMemberPaths: Array(index.members.prefix(maxContainerSampleMembers).map(\.path)),
            memberFingerprints: fingerprints,
            diagnostics: index.diagnostics
        )
    }

    private static func unpackedArchiveSummary(url: URL, fileManager: FileManager) -> NDSDataContainerSummary? {
        guard hasImmediateUnpackedArchiveSignal(url: url, fileManager: fileManager) else {
            return nil
        }
        let files = recursiveMemberFiles(url: url, fileManager: fileManager)
        let candidates = files.filter { !isArchiveMarker($0.relativePath) }
        let narcNamedMembers = candidates.filter { isUnpackedArchiveMember($0.relativePath) }
        let members = narcNamedMembers.isEmpty ? candidates : narcNamedMembers
        guard !members.isEmpty else {
            return NDSDataContainerSummary(
                kind: .unpackedArchiveDirectory,
                memberCount: 0,
                namedMemberCount: 0,
                unnamedMemberCount: 0,
                byteCount: 0,
                sampleMemberPaths: [],
                memberFingerprints: [],
                diagnostics: []
            )
        }
        let unnamedCount = members.filter { isUnpackedArchiveMember($0.relativePath) }.count
        let byteCount = members.reduce(UInt64(0)) { $0 + ($1.byteCount ?? 0) }
        return NDSDataContainerSummary(
            kind: .unpackedArchiveDirectory,
            memberCount: members.count,
            namedMemberCount: max(members.count - unnamedCount, 0),
            unnamedMemberCount: unnamedCount,
            byteCount: byteCount,
            sampleMemberPaths: Array(members.prefix(maxContainerSampleMembers).map(\.relativePath)),
            memberFingerprints: unpackedMemberFingerprints(root: url, members: members, fileManager: fileManager),
            diagnostics: []
        )
    }

    public static func memberFingerprints(for index: NARCIndex, data: Data?) -> [NDSDataContainerMemberFingerprint] {
        index.members.prefix(maxContainerSampleMembers).map { member in
            let sample: Data?
            if let data, let gmifDataOffset = index.gmifDataOffset {
                let start = Int(gmifDataOffset + member.offset)
                let availableEnd = min(data.count, start + Int(member.size))
                if start >= 0, start < availableEnd, start < data.count {
                    sample = data.subdata(in: start..<min(availableEnd, start + maxMemberFingerprintBytes))
                } else {
                    sample = nil
                }
            } else {
                sample = nil
            }
            return memberFingerprint(
                memberIndex: member.fileID,
                path: member.path,
                byteCount: member.size,
                sample: sample
            )
        }
    }

    private static func unpackedMemberFingerprints(
        root: URL,
        members: [(relativePath: String, byteCount: UInt64?)],
        fileManager: FileManager
    ) -> [NDSDataContainerMemberFingerprint] {
        members.prefix(maxContainerSampleMembers).enumerated().map { index, member in
            let sample = leadingBytes(
                url: root.appendingPathComponent(member.relativePath),
                byteCount: maxMemberFingerprintBytes,
                fileManager: fileManager
            )
            return memberFingerprint(
                memberIndex: index,
                path: member.relativePath,
                byteCount: member.byteCount,
                sample: sample
            )
        }
    }

    private static func memberFingerprint(
        memberIndex: Int,
        path: String,
        byteCount: UInt64?,
        sample: Data?
    ) -> NDSDataContainerMemberFingerprint {
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        let fileExtension = ext.isEmpty ? nil : ext
        let leading = sample.map { Data($0.prefix(maxMemberMagicBytes)) } ?? Data()
        let leadingHex = leading.isEmpty ? nil : leading.map { String(format: "%02X", $0) }.joined(separator: " ")
        let leadingASCII = safeASCII(leading)
        let classification = classifyMember(path: path, leadingBytes: leading)
        let diagnostics: [Diagnostic] = sample == nil && (byteCount ?? 0) > 0
            ? [Diagnostic(severity: .warning, code: "NDS_DATA_MEMBER_FINGERPRINT_UNAVAILABLE", message: "Could not read leading bytes for NDS container member: \(path).")]
            : []
        let preview = memberPreview(
            path: path,
            byteCount: byteCount,
            leadingBytes: leading,
            classification: classification,
            diagnostics: diagnostics
        )
        return NDSDataContainerMemberFingerprint(
            memberIndex: memberIndex,
            path: path,
            byteCount: byteCount,
            fileExtension: fileExtension,
            leadingMagicHex: leadingHex,
            leadingMagicASCII: leadingASCII,
            formatHint: classification.formatHint,
            compressionHint: classification.compressionHint,
            confidence: classification.confidence,
            preview: preview,
            diagnostics: diagnostics
        )
    }

    private static func memberPreview(
        path: String,
        byteCount: UInt64?,
        leadingBytes: Data,
        classification: (formatHint: String, compressionHint: String, confidence: String),
        diagnostics: [Diagnostic]
    ) -> NDSDataContainerMemberPreview? {
        if classification.compressionHint != "unknown" {
            return NDSDataContainerMemberPreview(
                status: .blocked,
                format: classification.formatHint,
                summary: "Compressed NDS member candidate; preview remains metadata-only.",
                blockedActions: ndsGraphicsPreviewBlockedActions,
                diagnostics: diagnostics + [
                    Diagnostic(
                        severity: .warning,
                        code: "NDS_DATA_MEMBER_PREVIEW_COMPRESSED_BLOCKED",
                        message: "NDS member \(path) has compression hint \(classification.compressionHint); preview metadata is read-only and no decompression is attempted."
                    )
                ]
            )
        }

        guard ndsGraphicsPreviewFormats.contains(classification.formatHint) else {
            return NDSDataContainerMemberPreview(
                status: .blocked,
                format: classification.formatHint,
                summary: "Unsupported NDS member preview format; catalog keeps routing metadata only.",
                blockedActions: ndsGraphicsPreviewBlockedActions,
                diagnostics: diagnostics + [
                    Diagnostic(
                        severity: .info,
                        code: "NDS_DATA_MEMBER_PREVIEW_UNSUPPORTED",
                        message: "NDS member \(path) is not in the read-only graphics preview allowlist."
                    )
                ]
            )
        }

        guard leadingBytes.count >= 4 else {
            return NDSDataContainerMemberPreview(
                status: .blocked,
                format: classification.formatHint,
                summary: "Too few bytes for NDS graphics preview metadata.",
                blockedActions: ndsGraphicsPreviewBlockedActions,
                diagnostics: diagnostics + [
                    Diagnostic(
                        severity: .warning,
                        code: "NDS_DATA_MEMBER_PREVIEW_TOO_SHORT",
                        message: "NDS member \(path) is too short for bounded graphics preview metadata."
                    )
                ]
            )
        }

        let byteSummary = byteCount.map { "\($0) bytes" } ?? "unknown size"
        return NDSDataContainerMemberPreview(
            status: .ready,
            format: classification.formatHint,
            summary: "\(displayName(forMemberFormat: classification.formatHint)) metadata candidate, \(byteSummary).",
            blockedActions: ndsGraphicsPreviewBlockedActions
        )
    }

    private static func classifyMember(path: String, leadingBytes: Data) -> (formatHint: String, compressionHint: String, confidence: String) {
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        if let hint = formatHint(forExtension: ext) {
            return (hint, compressionHint(for: leadingBytes), "medium")
        }

        let magic = safeASCII(Data(leadingBytes.prefix(8))) ?? ""
        let upperMagic = magic.uppercased()
        for signature in ["NCLR", "RLCN", "NCGR", "RGCN", "NSCR", "RCSN", "NCER", "RECN", "NANR", "RNAN", "NFTR", "RTFN", "BMG", "MESG", "NSBMD", "BMD0", "NSBTX", "BTX0", "SDAT", "SSEQ", "SBNK", "SWAR", "STRM", "SWAV", "NARC"] {
            if upperMagic.hasPrefix(signature) {
                return (formatHint(forSignature: signature), compressionHint(for: leadingBytes), "high")
            }
        }

        let compression = compressionHint(for: leadingBytes)
        if compression != "unknown" {
            return ("compressedCandidate", compression, "low")
        }
        return ("unknown", "unknown", "low")
    }

    private static func formatHint(forExtension ext: String) -> String? {
        switch ext {
        case "nclr", "rlcn": return "nitroPalette"
        case "ncgr", "rgcn": return "nitroCharacterGraphics"
        case "nscr", "rcsn": return "nitroScreenMap"
        case "ncer", "recn": return "nitroCell"
        case "nanr", "rnan": return "nitroAnimation"
        case "nftr", "rtfn": return "nitroFont"
        case "bmg": return "messageBank"
        case "nsbmd", "bmd0": return "nitroModel"
        case "nsbtx", "btx0": return "nitroTexture"
        case "sdat": return "nitroSoundArchive"
        case "sseq": return "nitroSoundSequence"
        case "sbnk": return "nitroSoundBank"
        case "swar": return "nitroWaveArchive"
        case "strm": return "nitroStream"
        case "swav": return "nitroWaveSample"
        case "narc": return "narcContainer"
        default: return nil
        }
    }

    private static func formatHint(forSignature signature: String) -> String {
        switch signature {
        case "NCLR", "RLCN": return "nitroPalette"
        case "NCGR", "RGCN": return "nitroCharacterGraphics"
        case "NSCR", "RCSN": return "nitroScreenMap"
        case "NCER", "RECN": return "nitroCell"
        case "NANR", "RNAN": return "nitroAnimation"
        case "NFTR", "RTFN": return "nitroFont"
        case "BMG", "MESG": return "messageBank"
        case "NSBMD", "BMD0": return "nitroModel"
        case "NSBTX", "BTX0": return "nitroTexture"
        case "SDAT": return "nitroSoundArchive"
        case "SSEQ": return "nitroSoundSequence"
        case "SBNK": return "nitroSoundBank"
        case "SWAR": return "nitroWaveArchive"
        case "STRM": return "nitroStream"
        case "SWAV": return "nitroWaveSample"
        case "NARC": return "narcContainer"
        default: return "unknown"
        }
    }

    private static func displayName(forMemberFormat format: String) -> String {
        switch format {
        case "nitroPalette": return "Nitro palette"
        case "nitroCharacterGraphics": return "Nitro character graphics"
        case "nitroScreenMap": return "Nitro screen map"
        case "nitroCell": return "Nitro cell"
        case "nitroAnimation": return "Nitro animation"
        case "nitroFont": return "Nitro font"
        case "messageBank": return "NDS message bank"
        case "nitroModel": return "Nitro model"
        case "nitroTexture": return "Nitro texture"
        case "nitroSoundArchive": return "Nitro sound archive"
        case "nitroSoundSequence": return "Nitro sound sequence"
        case "nitroSoundBank": return "Nitro sound bank"
        case "nitroWaveArchive": return "Nitro wave archive"
        case "nitroStream": return "Nitro stream"
        case "nitroWaveSample": return "Nitro wave sample"
        default: return "NDS member"
        }
    }

    private static func compressionHint(for bytes: Data) -> String {
        guard let first = bytes.first else { return "unknown" }
        switch first {
        case 0x10: return "lz77Candidate"
        case 0x11: return "lz11Candidate"
        case 0x24: return "huffmanCandidate"
        case 0x30: return "rleCandidate"
        default: return "unknown"
        }
    }

    private static func safeASCII(_ data: Data) -> String? {
        guard !data.isEmpty,
              data.allSatisfy({ byte in
                byte == 0x20 || (byte >= 0x21 && byte <= 0x7E)
              })
        else {
            return nil
        }
        return String(data: data, encoding: .ascii)
    }

    private static func leadingBytes(url: URL, byteCount: Int, fileManager: FileManager) -> Data? {
        guard fileManager.fileExists(atPath: url.path),
              let handle = try? FileHandle(forReadingFrom: url)
        else {
            return nil
        }
        defer { try? handle.close() }
        if #available(macOS 10.15.4, *) {
            return try? handle.read(upToCount: byteCount)
        }
        return handle.readData(ofLength: byteCount)
    }

    private static func recursiveMemberFiles(url: URL, fileManager: FileManager) -> [(relativePath: String, byteCount: UInt64?)] {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        var members: [(relativePath: String, byteCount: UInt64?)] = []
        while let fileURL = enumerator.nextObject() as? URL {
            let values = try? fileURL.resourceValues(forKeys: [.isDirectoryKey])
            if values?.isDirectory == true {
                if excludedDirectoryNames.contains(fileURL.lastPathComponent) {
                    enumerator.skipDescendants()
                }
                continue
            }
            members.append((relativePath(for: fileURL, root: url), fileByteCount(fileURL, fileManager: fileManager)))
        }
        return members.sorted { $0.relativePath.localizedStandardCompare($1.relativePath) == .orderedAscending }
    }

    private static func hasImmediateUnpackedArchiveSignal(url: URL, fileManager: FileManager) -> Bool {
        guard let contents = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: []) else {
            return false
        }
        return contents.contains { item in
            let name = item.lastPathComponent.lowercased()
            return isArchiveMarker(name) || isUnpackedArchiveMember(name)
        }
    }

    private static func isArchiveMarker(_ relativePath: String) -> Bool {
        let name = URL(fileURLWithPath: relativePath).lastPathComponent.lowercased()
        return name == ".narcignore" || name == ".knarcignore" || name == "narcignore" || name == "knarcignore"
    }

    private static func isUnpackedArchiveMember(_ relativePath: String) -> Bool {
        URL(fileURLWithPath: relativePath).lastPathComponent.lowercased().hasPrefix("narc_")
    }

    private static func containerPreview(_ summary: NDSDataContainerSummary?) -> String? {
        guard let summary, !summary.sampleMemberPaths.isEmpty else { return nil }
        return summary.sampleMemberPaths.joined(separator: ", ")
    }

    private static func textBankPreview(
        url: URL,
        relativePath: String,
        domain: NDSDataDomain,
        format: NDSDataSourceFormat,
        exists: Bool,
        isDirectory: Bool
    ) -> NDSDataTextBankPreview? {
        guard domain == .text, exists, !isDirectory else { return nil }
        if [.text, .cSource, .cHeader, .json, .csv].contains(format),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            let samples = decodedTextSamples(text, format: format)
            guard !samples.isEmpty else { return nil }
            return NDSDataTextBankPreview(
                status: .ready,
                format: "sourceText",
                decodedStringCount: samples.count,
                sampleStrings: Array(samples.prefix(maxTextBankSampleStrings)),
                blockedActions: ndsTextBankPreviewBlockedActions,
                diagnostics: [
                    Diagnostic(
                        severity: .info,
                        code: "NDS_TEXT_BANK_PREVIEW_READ_ONLY",
                        message: "Decoded text-bank samples for \(relativePath) are read-only preview facts; text-bank writers, NARC rebuilds, and ROM export remain disabled.",
                        span: SourceSpan(relativePath: relativePath, startLine: 1)
                    )
                ]
            )
        }

        let ext = url.pathExtension.lowercased()
        guard ["bmg", "msg", "bin"].contains(ext),
              let data = try? Data(contentsOf: url)
        else { return nil }

        let classification = classifyMember(path: relativePath, leadingBytes: Data(data.prefix(maxMemberFingerprintBytes)))
        guard classification.formatHint == "messageBank" || ext == "msg" else { return nil }
        let samples = decodedBinaryTextSamples(data)
        let status: NDSDataTextBankPreviewStatus = samples.isEmpty ? .blocked : .ready
        return NDSDataTextBankPreview(
            status: status,
            format: classification.formatHint,
            decodedStringCount: samples.count,
            sampleStrings: Array(samples.prefix(maxTextBankSampleStrings)),
            blockedActions: ndsTextBankPreviewBlockedActions,
            diagnostics: [
                Diagnostic(
                    severity: status == .ready ? .info : .warning,
                    code: status == .ready ? "NDS_TEXT_BANK_BINARY_PREVIEW_READ_ONLY" : "NDS_TEXT_BANK_BINARY_PREVIEW_BLOCKED",
                    message: status == .ready
                        ? "Decoded bounded printable strings for \(relativePath) as read-only message-bank preview facts; binary text writes and export remain disabled."
                        : "Could not safely decode printable message-bank samples for \(relativePath); no extraction, conversion, write, or export was attempted.",
                    span: SourceSpan(relativePath: relativePath, startLine: 1)
                )
            ]
        )
    }

    private static func decodedTextSamples(_ text: String, format: NDSDataSourceFormat) -> [String] {
        if format == .json,
           let data = text.data(using: .utf8),
           let value = try? JSONSerialization.jsonObject(with: data) {
            let samples = decodedJSONTextSamples(value)
            if !samples.isEmpty {
                return samples
            }
        }
        return text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { line in
                !line.isEmpty && !line.hasPrefix("#") && !line.hasPrefix("//")
            }
    }

    private static func decodedJSONTextSamples(_ value: Any, key: String? = nil) -> [String] {
        if let string = value as? String {
            guard key != "id" else { return [] }
            let sample = normalizedTextSample(string)
            return sample.isEmpty ? [] : [sample]
        }
        if let array = value as? [Any] {
            return array.flatMap { decodedJSONTextSamples($0, key: key) }
        }
        if let object = value as? [String: Any] {
            return object.keys.sorted().flatMap { childKey in
                decodedJSONTextSamples(object[childKey] as Any, key: childKey)
            }
        }
        return []
    }

    private static func normalizedTextSample(_ text: String) -> String {
        text.replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func decodedBinaryTextSamples(_ data: Data) -> [String] {
        var samples: [String] = []
        var current: [UInt8] = []
        for byte in data.prefix(maxTextBankPreviewBytes) {
            if byte == 0x20 || (byte >= 0x21 && byte <= 0x7E) {
                current.append(byte)
            } else {
                appendBinaryTextSample(current, to: &samples)
                current.removeAll(keepingCapacity: true)
            }
        }
        appendBinaryTextSample(current, to: &samples)
        return samples
    }

    private static func appendBinaryTextSample(_ bytes: [UInt8], to samples: inout [String]) {
        guard bytes.count >= 2, let text = String(bytes: bytes, encoding: .ascii) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.rangeOfCharacter(from: .letters) != nil else { return }
        samples.append(trimmed)
    }

    private static func ndsAudioPreview(
        url: URL? = nil,
        relativePath: String,
        domain: NDSDataDomain,
        format: NDSDataSourceFormat,
        exists: Bool,
        isDirectory: Bool,
        containerSummary: NDSDataContainerSummary?,
        fileManager: FileManager? = nil
    ) -> NDSDataAudioPreview? {
        guard domain == .audio, exists else { return nil }

        var hints: [String] = []
        if let containerSummary {
            hints.append(contentsOf: containerSummary.memberFingerprints.map(\.formatHint).filter { ndsAudioPreviewFormats.contains($0) })
        }
        if !isDirectory,
           let url,
           let fileManager,
           let leading = leadingBytes(url: url, byteCount: maxMemberFingerprintBytes, fileManager: fileManager) {
            let classification = classifyMember(path: relativePath, leadingBytes: leading)
            if ndsAudioPreviewFormats.contains(classification.formatHint) {
                hints.append(classification.formatHint)
            }
        } else if format == .binary || format == .narc {
            let classification = classifyMember(path: relativePath, leadingBytes: Data())
            if ndsAudioPreviewFormats.contains(classification.formatHint) {
                hints.append(classification.formatHint)
            }
        }

        let uniqueHints = Array(Set(hints)).sorted()
        let status: NDSDataAudioPreviewStatus = uniqueHints.isEmpty ? .blocked : .ready
        let formatLabel = uniqueHints.first ?? "ndsAudioCandidate"
        let detail = uniqueHints.isEmpty
            ? "Audio path is indexed, but no supported SDAT/SSEQ/SBNK/SWAR/STRM signature or extension was detected."
            : "Read-only \(displayName(forMemberFormat: formatLabel)) metadata is available for review."
        return NDSDataAudioPreview(
            status: status,
            format: formatLabel,
            summary: "\(detail) Decode, playback, conversion, extraction, rebuild, export, and mutation apply remain disabled.",
            detectedHints: uniqueHints,
            blockedActions: ndsAudioPreviewBlockedActions,
            diagnostics: [
                Diagnostic(
                    severity: status == .ready ? .info : .warning,
                    code: status == .ready ? "NDS_AUDIO_PREVIEW_READ_ONLY" : "NDS_AUDIO_PREVIEW_BLOCKED",
                    message: status == .ready
                        ? "Detected read-only NDS audio metadata for \(relativePath); no decode, playback, conversion, extraction, rebuild, export, or write was attempted."
                        : "NDS audio preview for \(relativePath) stays blocked because no supported SDAT/SSEQ/SBNK/SWAR/STRM metadata hint was detected.",
                    span: SourceSpan(relativePath: relativePath, startLine: 1)
                )
            ]
        )
    }

    private static func ndsMigrationPlan(
        relativePath: String,
        domain: NDSDataDomain,
        format: NDSDataSourceFormat,
        role: NDSDataSourceRole,
        exists: Bool
    ) -> NDSDataMigrationPlan? {
        guard exists,
              role == .binaryContainer || role == .nitroFSManifest || format == .narc || format == .directory
        else { return nil }

        let sourceCandidates = sourceTreeMigrationCandidates(relativePath: relativePath, domain: domain)
        let extractedCandidates = extractedDirectoryMigrationCandidates(relativePath: relativePath, format: format)
        let status: NDSDataMigrationPlanStatus = sourceCandidates.isEmpty && extractedCandidates.isEmpty ? .blocked : .previewOnly
        return NDSDataMigrationPlan(
            status: status,
            sourceTreeCandidates: sourceCandidates,
            extractedDirectoryCandidates: extractedCandidates,
            unsupportedSteps: ndsMigrationUnsupportedSteps,
            blockedActions: ndsMigrationBlockedActions,
            diagnostics: [
                Diagnostic(
                    severity: .info,
                    code: "NDS_DATA_MIGRATION_PREVIEW_ONLY",
                    message: "NDS migration plan for \(relativePath) is read-only candidate routing only; extraction, repacking, rebuilds, exports, and writes remain disabled.",
                    span: SourceSpan(relativePath: relativePath, startLine: 1)
                )
            ]
        )
    }

    private static func sourceTreeMigrationCandidates(relativePath: String, domain: NDSDataDomain) -> [String] {
        let path = relativePath as NSString
        let fileName = path.lastPathComponent
        let stem = (fileName as NSString).deletingPathExtension
        var candidates: [String] = []

        switch domain {
        case .species, .personal:
            candidates.append("res/pokemon/\(stem)")
            candidates.append("files/poketool/personal/\(fileName)")
        case .moves:
            candidates.append("res/battle/moves/\(stem).json")
            candidates.append("files/poketool/waza/\(fileName)")
        case .items:
            candidates.append("res/items/\(stem).json")
            candidates.append("files/itemtool/itemdata/\(fileName)")
        case .trainers:
            candidates.append("res/trainers/data/\(stem).json")
            candidates.append("files/poketool/trainer/\(fileName)")
        case .encounters:
            candidates.append("res/field/encounters/\(stem).json")
            candidates.append("files/fielddata/encountdata/\(fileName)")
        case .text:
            candidates.append("res/text/\(stem).txt")
            candidates.append("files/msgdata/msg/\(stem).txt")
        case .scripts:
            candidates.append("res/field/scripts/\(stem).s")
            candidates.append("files/fielddata/script/\(stem)")
        case .maps:
            candidates.append("res/field/maps/\(stem)/map.bin")
            candidates.append("files/fielddata/mapmatrix/\(fileName)")
        case .audio:
            candidates.append("res/sound/\(fileName)")
            candidates.append("files/data/sound/\(fileName)")
            candidates.append("files/sound/\(fileName)")
        case .resources:
            if !relativePath.hasPrefix("res/prebuilt/") {
                candidates.append("res/prebuilt/\(relativePath)")
            }
            if !relativePath.hasPrefix("files/") {
                candidates.append("files/\(relativePath)")
            }
        }

        candidates.append(relativePath)
        return uniqueNonEmptyPaths(candidates)
    }

    private static func extractedDirectoryMigrationCandidates(relativePath: String, format: NDSDataSourceFormat) -> [String] {
        let path = relativePath as NSString
        let parent = path.deletingLastPathComponent
        let stem = (path.lastPathComponent as NSString).deletingPathExtension
        var candidates = [
            path.deletingPathExtension,
            "\(relativePath).d",
            parent == "." || parent.isEmpty ? "\(stem)_extracted" : "\(parent)/\(stem)_extracted"
        ]
        if format == .narc {
            candidates.append(parent == "." || parent.isEmpty ? "narc_\(stem)" : "\(parent)/narc_\(stem)")
        }
        return uniqueNonEmptyPaths(candidates)
    }

    private static func uniqueNonEmptyPaths(_ paths: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for path in paths {
            let normalized = path.replacingOccurrences(of: "//", with: "/")
            guard !normalized.isEmpty, seen.insert(normalized).inserted else { continue }
            result.append(normalized)
        }
        return result
    }

    private static func factsForRecord(
        format: NDSDataSourceFormat,
        role: NDSDataSourceRole,
        byteCount: UInt64?,
        recordCount: Int?,
        containerSummary: NDSDataContainerSummary? = nil,
        textBankPreview: NDSDataTextBankPreview? = nil,
        migrationPlan: NDSDataMigrationPlan? = nil,
        audioPreview: NDSDataAudioPreview? = nil
    ) -> [SourceIndexFact] {
        var facts = [
            SourceIndexFact(label: "Format", value: format.rawValue),
            SourceIndexFact(label: "Role", value: role.rawValue)
        ]
        if let containerSummary {
            facts.append(SourceIndexFact(label: "Container", value: containerSummary.kind.rawValue))
            facts.append(SourceIndexFact(label: "Members", value: "\(containerSummary.memberCount)"))
            facts.append(SourceIndexFact(label: "Named Members", value: "\(containerSummary.namedMemberCount)"))
            facts.append(SourceIndexFact(label: "Unnamed Members", value: "\(containerSummary.unnamedMemberCount)"))
            let formatHints = Array(Set(containerSummary.memberFingerprints.map(\.formatHint))).sorted()
            let compressionHints = Array(Set(containerSummary.memberFingerprints.map(\.compressionHint).filter { $0 != "unknown" })).sorted()
            let previewHints = Array(Set(containerSummary.memberFingerprints.compactMap { fingerprint in
                fingerprint.preview?.status == .ready ? fingerprint.preview?.format : nil
            })).sorted()
            let blockedPreviewCount = containerSummary.memberFingerprints.filter { $0.preview?.status == .blocked }.count
            if !formatHints.isEmpty {
                facts.append(SourceIndexFact(label: "Member Hints", value: formatHints.joined(separator: ", ")))
            }
            if !compressionHints.isEmpty {
                facts.append(SourceIndexFact(label: "Compression Hints", value: compressionHints.joined(separator: ", ")))
            }
            if !previewHints.isEmpty {
                facts.append(SourceIndexFact(label: "Preview Hints", value: previewHints.joined(separator: ", ")))
            }
            if blockedPreviewCount > 0 {
                facts.append(SourceIndexFact(label: "Blocked Previews", value: "\(blockedPreviewCount)"))
            }
        }
        if let textBankPreview {
            facts.append(SourceIndexFact(label: "Text Bank Preview", value: textBankPreview.status.rawValue))
            facts.append(SourceIndexFact(label: "Decoded Strings", value: "\(textBankPreview.decodedStringCount)"))
            if !textBankPreview.sampleStrings.isEmpty {
                facts.append(SourceIndexFact(label: "Text Samples", value: textBankPreview.sampleStrings.joined(separator: " | ")))
            }
            facts.append(SourceIndexFact(label: "Text Preview Blocked Actions", value: textBankPreview.blockedActions.joined(separator: ", ")))
        }
        if let migrationPlan {
            facts.append(SourceIndexFact(label: "Migration Status", value: migrationPlan.status.rawValue))
            if !migrationPlan.sourceTreeCandidates.isEmpty {
                facts.append(SourceIndexFact(label: "Source Candidates", value: migrationPlan.sourceTreeCandidates.prefix(3).joined(separator: ", ")))
            }
            if !migrationPlan.extractedDirectoryCandidates.isEmpty {
                facts.append(SourceIndexFact(label: "Extracted Candidates", value: migrationPlan.extractedDirectoryCandidates.prefix(3).joined(separator: ", ")))
            }
            facts.append(SourceIndexFact(label: "Unsupported Migration Steps", value: migrationPlan.unsupportedSteps.joined(separator: ", ")))
            facts.append(SourceIndexFact(label: "Migration Blocked Actions", value: migrationPlan.blockedActions.joined(separator: ", ")))
        }
        if let audioPreview {
            facts.append(SourceIndexFact(label: "Audio Preview", value: audioPreview.status.rawValue))
            facts.append(SourceIndexFact(label: "Audio Format", value: audioPreview.format))
            if !audioPreview.detectedHints.isEmpty {
                facts.append(SourceIndexFact(label: "Audio Hints", value: audioPreview.detectedHints.joined(separator: ", ")))
            }
            facts.append(SourceIndexFact(label: "Audio Preview Blocked Actions", value: audioPreview.blockedActions.joined(separator: ", ")))
        }
        if let recordCount {
            facts.append(SourceIndexFact(label: "Shallow Count", value: "\(recordCount)"))
        }
        if let byteCount {
            facts.append(SourceIndexFact(label: "Bytes", value: "\(byteCount)"))
        }
        return facts
    }

    private static func preview(url: URL, format: NDSDataSourceFormat) -> String? {
        switch format {
        case .json, .csv, .cSource, .cHeader, .text:
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
            let trimmed = text
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty }
            guard let trimmed else { return nil }
            return String(trimmed.prefix(160))
        case .narc, .binary, .directory, .unknown:
            return nil
        }
    }

    private static func format(for relativePath: String) -> NDSDataSourceFormat {
        let ext = URL(fileURLWithPath: relativePath).pathExtension.lowercased()
        switch ext {
        case "json":
            return .json
        case "csv":
            return .csv
        case "c":
            return .cSource
        case "h", "hpp":
            return .cHeader
        case "narc":
            return .narc
        case "bin", "dat", "sdat", "sseq", "sbnk", "swar", "strm", "swav", "bmd0", "nsbmd", "ncgr", "nclr", "nscr", "ncer", "nanr":
            return .binary
        case "txt", "mk", "rsf", "s", "inc", "gmm", "str":
            return .text
        default:
            return ext.isEmpty ? .unknown : .binary
        }
    }

    private static func title(for relativePath: String, domain: NDSDataDomain) -> String {
        let url = URL(fileURLWithPath: relativePath)
        let name = url.deletingPathExtension().lastPathComponent
        if name.isEmpty {
            return domain.rawValue
        }
        return name
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }

    private static func fileByteCount(_ url: URL, fileManager: FileManager) -> UInt64? {
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        return (attributes?[.size] as? NSNumber)?.uint64Value
    }

    private static func relativePath(for url: URL, root: URL) -> String {
        let standardizedRoot = root.standardizedFileURL.path
        let standardizedPath = url.standardizedFileURL.path
        guard standardizedPath.hasPrefix(standardizedRoot + "/") else {
            return url.lastPathComponent
        }
        return String(standardizedPath.dropFirst(standardizedRoot.count + 1))
    }

    private static func family(for index: ProjectIndex, fileManager: FileManager) -> GenIIIGameFamily {
        switch index.profile {
        case .pokediamond:
            return .diamondPearl
        case .pokeplatinum:
            return .platinum
        case .pokeheartgold:
            return .heartGoldSoulSilver
        case .pokeblack:
            return .blackWhite
        case .ndsROM:
            guard
                let data = try? Data(contentsOf: URL(fileURLWithPath: index.root.path)),
                let header = NDSROMHeaderParser.parse(path: index.root.path, data: data).header
            else {
                return .ndsUnknown
            }
            return NDSResourceEntryFactory.family(for: header.gameCode)
        case .pmdSky:
            return .ndsUnknown
        default:
            return .unknown
        }
    }

    private static func domain(forContainerPath relativePath: String) -> NDSDataDomain {
        let lower = relativePath.lowercased()
        if lower.contains("personal") || lower.contains("/pms") {
            return .personal
        }
        if lower.contains("waza") || lower.contains("move") || lower.contains("kowaza") {
            return .moves
        }
        if lower.contains("item") || lower.contains("bag") {
            return .items
        }
        if lower.contains("trainer") || lower.contains("/tr_") || lower.contains("/trmsg") || lower.contains("trtbl") {
            return .trainers
        }
        if lower.contains("encount") || lower.contains("encdata") || lower.contains("enc_") {
            return .encounters
        }
        if lower.contains("msg") || lower.contains("text") || lower.contains("font") {
            return .text
        }
        if lower.contains("sound") || lower.contains("audio") || lower.contains("sdat") || lower.contains("sseq")
            || lower.contains("sbnk") || lower.contains("swar") || lower.contains("strm")
            || lower.contains("/seq") || lower.contains("bgm") || lower.contains("music") || lower.contains("cries") {
            return .audio
        }
        if lower.contains("script") || lower.contains("scr_") || lower.contains("scrseq") {
            return .scripts
        }
        if lower.contains("map") || lower.contains("fielddata") || lower.contains("/field/") {
            return .maps
        }
        if lower.contains("/pokemon/") || lower.contains("pokezukan") || lower.contains("zukan") {
            return .species
        }
        return .resources
    }

    private static func readOnlyDiagnostic() -> Diagnostic {
        Diagnostic(
            severity: .info,
            code: "NDS_DATA_CATALOG_READ_ONLY",
            message: "Gen IV/NDS data catalogs are preview-first; semantic editors, rebuilds, extraction, and binary writes remain disabled."
        )
    }

    private static func binaryReadOnlyDiagnostic() -> Diagnostic {
        Diagnostic(
            severity: .info,
            code: "NDS_DATA_CATALOG_BINARY_SUMMARY_READ_ONLY",
            message: "NDS ROM data catalogs summarize reachable NARC containers only; extraction, decompression, rebuilds, and binary writes remain disabled."
        )
    }

    private static func recordSort(_ lhs: NDSDataCatalogRecord, _ rhs: NDSDataCatalogRecord) -> Bool {
        if lhs.domain.sortOrder == rhs.domain.sortOrder {
            return lhs.relativePath.localizedStandardCompare(rhs.relativePath) == .orderedAscending
        }
        return lhs.domain.sortOrder < rhs.domain.sortOrder
    }

    private static func sourceFingerprintEntries(
        root: URL,
        profile: GameProfile,
        fileManager: FileManager
    ) -> [NDSDataSourceFingerprintEntry] {
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: root.path, isDirectory: &isDirectory), !isDirectory.boolValue {
            return [sourceFingerprintEntry(relativePath: root.lastPathComponent, url: root, kind: profile.rawValue)]
        }
        let roots = sourceFingerprintRoots(for: profile)
        var entries: [NDSDataSourceFingerprintEntry] = []
        for relativePath in roots {
            let url = root.appendingPathComponent(relativePath)
            guard fileManager.fileExists(atPath: url.path) else {
                entries.append(NDSDataSourceFingerprintEntry(relativePath: relativePath, kind: "missing", byteCount: nil, sha1: nil))
                continue
            }
            entries.append(contentsOf: sourceFingerprintEntries(relativePath: relativePath, root: root, fileManager: fileManager))
        }
        return entries.sorted { lhs, rhs in lhs.relativePath < rhs.relativePath }
    }

    private static func sourceFingerprintRoots(for profile: GameProfile) -> [String] {
        switch profile {
        case .pokeplatinum:
            return ["Makefile", "meson.build", "meson.options", "platinum.us", "res", "generated"]
        case .pokeheartgold:
            return ["Makefile", "config.mk", "filesystem.mk", "rom.rsf", "heartgold.us", "soulsilver.us", "files", "src"]
        case .pokediamond:
            return ["Makefile", "config.mk", "filesystem.mk", "rom.rsf", "pokediamond.us.sha1", "files", "arm9"]
        case .pokeblack:
            return ["Makefile", "config.mk", "main.rsf", "main.lsf", "black.us", "white.us", "black2.us", "white2.us", "files", "data", "src", "asm", "include", "overlays", "ndsdisasm_config"]
        case .pmdSky:
            return ["Makefile", "config.mk", "filesystem.mk", "rom.rsf", "nitrofs_files.txt", "pmdsky.us", "files", "src", "asm"]
        case .ndsROM:
            return []
        default:
            return descriptors(for: profile)?.map(\.relativePath) ?? []
        }
    }

    private static func sourceFingerprintEntries(
        relativePath: String,
        root: URL,
        fileManager: FileManager
    ) -> [NDSDataSourceFingerprintEntry] {
        let url = root.appendingPathComponent(relativePath)
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return [NDSDataSourceFingerprintEntry(relativePath: relativePath, kind: "missing", byteCount: nil, sha1: nil)]
        }
        guard isDirectory.boolValue else {
            return [sourceFingerprintEntry(relativePath: relativePath, url: url, kind: format(for: relativePath).rawValue)]
        }
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return [NDSDataSourceFingerprintEntry(relativePath: relativePath, kind: "directory", byteCount: nil, sha1: nil)]
        }
        var entries: [NDSDataSourceFingerprintEntry] = [
            NDSDataSourceFingerprintEntry(relativePath: relativePath, kind: "directory", byteCount: nil, sha1: nil)
        ]
        while let fileURL = enumerator.nextObject() as? URL {
            let values = try? fileURL.resourceValues(forKeys: [.isDirectoryKey])
            if values?.isDirectory == true {
                if excludedDirectoryNames.contains(fileURL.lastPathComponent) {
                    enumerator.skipDescendants()
                }
                continue
            }
            let entryPath = Self.relativePath(for: fileURL, root: root)
            entries.append(sourceFingerprintEntry(relativePath: entryPath, url: fileURL, kind: format(for: entryPath).rawValue))
        }
        return entries
    }

    private static func sourceFingerprintEntry(
        relativePath: String,
        url: URL,
        kind: String
    ) -> NDSDataSourceFingerprintEntry {
        guard let data = try? Data(contentsOf: url) else {
            return NDSDataSourceFingerprintEntry(relativePath: relativePath, kind: kind, byteCount: nil, sha1: nil)
        }
        return NDSDataSourceFingerprintEntry(
            relativePath: relativePath,
            kind: kind,
            byteCount: UInt64(data.count),
            sha1: pokemonHackSHA1Hex(data)
        )
    }

    private static let excludedDirectoryNames: Set<String> = [
        ".git",
        ".pokemonhackstudio",
        ".swiftpm",
        "build",
        "DerivedData"
    ]
    private static let relationshipExcludedFileNames: Set<String> = [
        "makefile",
        "meson.build",
        "readme.md"
    ]
    private static let ndsGraphicsPreviewFormats: Set<String> = [
        "nitroPalette",
        "nitroCharacterGraphics",
        "nitroScreenMap",
        "nitroCell",
        "nitroAnimation",
        "nitroFont",
        "messageBank",
        "nitroModel",
        "nitroTexture"
    ]
    private static let ndsAudioPreviewFormats: Set<String> = [
        "nitroSoundArchive",
        "nitroSoundSequence",
        "nitroSoundBank",
        "nitroWaveArchive",
        "nitroStream",
        "nitroWaveSample"
    ]
    private static let ndsAudioFileExtensions: Set<String> = [
        "sdat",
        "sseq",
        "sbnk",
        "swar",
        "strm",
        "swav"
    ]
    private static let ndsGraphicsPreviewBlockedActions = [
        "Extraction",
        "Decompression",
        "Conversion",
        "NARC rebuild",
        "ROM export",
        "Mutation apply"
    ]
    private static let ndsTextBankPreviewBlockedActions = [
        "Message decoder apply",
        "Text-bank writer",
        "NARC rebuild",
        "ROM export",
        "Mutation apply"
    ]
    private static let ndsAudioPreviewBlockedActions = [
        "Audio decode",
        "Playback",
        "Conversion",
        "Extraction",
        "NARC rebuild",
        "ROM export",
        "Mutation apply"
    ]
    private static let ndsMigrationBlockedActions = [
        "ROM extraction",
        "NARC unpack",
        "NARC repack",
        "ROM rebuild",
        "ROM export",
        "Mutation apply"
    ]
    private static let ndsMigrationUnsupportedSteps = [
        "Confirm matching source-tree profile",
        "Decode container members",
        "Preserve file ordering and IDs",
        "Rebuild containers externally"
    ]
    private static let genVBlockedActions = [
        "semantic editor",
        "raw source writer",
        "extraction",
        "decompression",
        "build execution",
        "playtest launch",
        "NARC pack",
        "ROM export",
        "binary write",
        "mutation apply"
    ]
    private static let genVActionStateSummary = "editing/apply, build, playtest, and export actions are disabled; source inventory stays preview-only"

    private struct GenVTitleCoverageSpec: Sendable {
        let id: String
        let title: String
        let family: String
        let sourceName: String
        let sourceMarkerPaths: [String]
        let unavailableReason: String
    }

    private static let genVTitleCoverageSpecs = [
        GenVTitleCoverageSpec(
            id: "black.us",
            title: "Pokemon - Black Version (USA, Europe) (NDSi Enhanced).nds",
            family: "blackWhite",
            sourceName: "pokeblack",
            sourceMarkerPaths: ["black.us", "black.us/rom.sha1"],
            unavailableReason: "No materialized Black source marker is available in the current pokeblack source tree."
        ),
        GenVTitleCoverageSpec(
            id: "white.us",
            title: "Pokemon - White Version (USA, Europe) (NDSi Enhanced).nds",
            family: "blackWhite",
            sourceName: "pokeblack",
            sourceMarkerPaths: ["white.us", "white.us/rom.sha1"],
            unavailableReason: "No materialized White source decomp is available in the current central corpus; the available pokeblack tree currently supports black.us only."
        ),
        GenVTitleCoverageSpec(
            id: "black2.us",
            title: "Pokemon - Black Version 2 (USA, Europe) (NDSi Enhanced).nds",
            family: "black2White2",
            sourceName: "none",
            sourceMarkerPaths: ["black2.us", "black2.us/rom.sha1"],
            unavailableReason: "No public/materialized Black 2 decomp source root was found in the configured central corpus."
        ),
        GenVTitleCoverageSpec(
            id: "white2.us",
            title: "Pokemon - White Version 2 (USA, Europe) (NDSi Enhanced).nds",
            family: "black2White2",
            sourceName: "none",
            sourceMarkerPaths: ["white2.us", "white2.us/rom.sha1"],
            unavailableReason: "No public/materialized White 2 decomp source root was found in the configured central corpus."
        )
    ]

    private static let maxDiscoveredContainerRecords = 256
    private static let maxContainerSampleMembers = 8
    private static let maxMemberFingerprintBytes = 32
    private static let maxMemberMagicBytes = 8
    private static let maxTextBankPreviewBytes = 65536
    private static let maxTextBankSampleStrings = 5
}

private struct CatalogPathDescriptor {
    let domain: NDSDataDomain
    let relativePath: String
    let role: NDSDataSourceRole
    let allowedExtensions: Set<String>?
    let format: NDSDataSourceFormat?
    let required: Bool
    let summarizeDirectory: Bool
    let includeMigrationPlan: Bool

    init(
        _ domain: NDSDataDomain,
        _ relativePath: String,
        role: NDSDataSourceRole = .sourceTree,
        allowedExtensions: Set<String>? = nil,
        format: NDSDataSourceFormat? = nil,
        required: Bool = true,
        summarizeDirectory: Bool = false,
        includeMigrationPlan: Bool = true
    ) {
        self.domain = domain
        self.relativePath = relativePath
        self.role = role
        self.allowedExtensions = allowedExtensions
        self.format = format
        self.required = required
        self.summarizeDirectory = summarizeDirectory
        self.includeMigrationPlan = includeMigrationPlan
    }
}

private struct NDSDataSourceFingerprintPayload: Codable, Equatable {
    let profile: GameProfile
    let adapterID: String
    let adapterName: String
    let rootPath: String
    let files: [NDSDataSourceFingerprintEntry]
}

private struct NDSDataSourceFingerprintEntry: Codable, Equatable {
    let relativePath: String
    let kind: String
    let byteCount: UInt64?
    let sha1: String?
}

private extension NDSDataDomain {
    var sortOrder: Int {
        switch self {
        case .species: return 0
        case .personal: return 1
        case .moves: return 2
        case .items: return 3
        case .trainers: return 4
        case .encounters: return 5
        case .text: return 6
        case .scripts: return 7
        case .maps: return 8
        case .audio: return 9
        case .resources: return 10
        }
    }
}
