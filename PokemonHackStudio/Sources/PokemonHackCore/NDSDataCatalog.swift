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
            records: enrichRelationships(
                records: uniqueRecords(
                    descriptors.flatMap { descriptor in
                        catalogRecords(for: descriptor, root: rootURL, fileManager: fileManager)
                    }
                    + discoveredContainerRecords(for: index.profile, root: rootURL, fileManager: fileManager)
                    + genVUnavailableTitleRecords(for: index.profile, root: rootURL, fileManager: fileManager)
                ).sorted(by: recordSort),
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
                CatalogPathDescriptor(.scripts, "files/fielddata/script/scr_seq"),
                CatalogPathDescriptor(.maps, "files/fielddata/mapmatrix"),
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
                CatalogPathDescriptor(.maps, "files/fielddata/mapmatrix", required: false),
                CatalogPathDescriptor(.maps, "files/fielddata/land_data", required: false),
                CatalogPathDescriptor(.maps, "files/fielddata/areadata", required: false),
                CatalogPathDescriptor(.maps, "files/fielddata/maptable", required: false),
                CatalogPathDescriptor(.maps, "files/fielddata/eventdata", required: false),
                CatalogPathDescriptor(.audio, "files/data/sound", required: false),
                CatalogPathDescriptor(.audio, "files/sound", required: false),
                CatalogPathDescriptor(.resources, "filesystem.mk", role: .nitroFSManifest)
            ]
        case .pokeblack:
            return [
                CatalogPathDescriptor(.encounters, "data/encounters", required: false),
                CatalogPathDescriptor(.resources, "data", required: false),
                CatalogPathDescriptor(.resources, "files"),
                CatalogPathDescriptor(.audio, "files/wb_sound_data.sdat", required: false),
                CatalogPathDescriptor(.audio, "files/soundstatus.narc", role: .binaryContainer, format: .narc, required: false),
                CatalogPathDescriptor(.scripts, "overlays", required: false),
                CatalogPathDescriptor(.resources, "ndsdisasm_config", required: false),
                CatalogPathDescriptor(.resources, "black.us/rom.sha1", required: false),
                CatalogPathDescriptor(.resources, "white.us/rom.sha1", required: false),
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
        let byteCount = containerSummary?.byteCount ?? (exists && !isDirectory ? fileByteCount(url, fileManager: fileManager) : nil)
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
        let migrationPlan = ndsMigrationPlan(
            relativePath: relativePath,
            domain: descriptor.domain,
            format: format,
            role: descriptor.role,
            exists: exists
        )
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
        )
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
            preview: containerPreview(containerSummary) ?? preview(url: url, format: format),
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

    private static func literalNARCRecords(root: URL, searchRoot: String, fileManager: FileManager) -> [NDSDataCatalogRecord] {
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
            guard url.pathExtension.lowercased() == "narc" else { continue }
            paths.append(relativePath(for: url, root: root))
        }

        return paths
            .sorted()
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
        let relationshipRecordIDsByID = relationshipRecordIDs(records: records, relationshipKeysByID: relationshipKeysByID)
        return records.map { record in
            let related = relatedRecords(for: record, recordsByID: recordsByID, relationshipRecordIDsByID: relationshipRecordIDsByID)
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

    private static func relationshipRecordIDs(
        records: [NDSDataCatalogRecord],
        relationshipKeysByID: [String: Set<String>]
    ) -> [String: Set<String>] {
        var recordIDsByKey: [String: Set<String>] = [:]
        for record in records where relationshipDomains.contains(record.domain) {
            for key in relationshipKeysByID[record.id] ?? [] {
                recordIDsByKey[key, default: []].insert(record.id)
            }
        }

        var relatedIDsByID: [String: Set<String>] = [:]
        for record in records where relationshipDomains.contains(record.domain) {
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
        relationshipRecordIDsByID: [String: Set<String>]
    ) -> [NDSDataRelatedRecord] {
        guard relationshipDomains.contains(record.domain),
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
        return records.map { record in
            let readiness = genVReadinessSummary(for: record)
            return record.copy(
                facts: record.facts + genVReadinessFacts(for: record),
                readiness: .some(readiness),
                diagnostics: record.diagnostics + genVReadinessDiagnostics(for: record, readiness: readiness)
            )
        }
    }

    private static func genVReadinessSummary(for record: NDSDataCatalogRecord) -> NDSDataReadinessSummary {
        let sourceRole = genVSourceRole(for: record)
        if isGenVUnavailableTitle(record) {
            return NDSDataReadinessSummary(
                status: .blocked,
                title: "Gen V title unavailable",
                detail: "\(genVUnavailableReason(for: record) ?? genVSourceRoleDetail(for: sourceRole)) This is diagnostic-only title coverage metadata; no source tree, editor, extraction, rebuild, playtest, export, or binary write path is available.",
                blockedActions: genVBlockedActions
            )
        }
        let status: NDSDataReadinessStatus = record.role == .binaryContainer || record.containerSummary != nil || record.format == .narc
            ? .blocked
            : .partial
        return NDSDataReadinessSummary(
            status: status,
            title: "Gen V read-only readiness",
            detail: "\(genVSourceRoleDetail(for: sourceRole)) This is clean-room Gen V routing metadata only; editing, extraction, rebuild, playtest, export, and binary writes remain disabled.",
            blockedActions: genVBlockedActions
        )
    }

    private static func genVReadinessFacts(for record: NDSDataCatalogRecord) -> [SourceIndexFact] {
        var facts = [
            SourceIndexFact(label: "Gen V Readiness", value: isGenVUnavailableTitle(record) ? "unavailable" : "previewOnly"),
            SourceIndexFact(label: "Gen V Source Role", value: genVSourceRole(for: record)),
            SourceIndexFact(label: "Gen V Blocked Actions", value: genVBlockedActions.joined(separator: ", ")),
            SourceIndexFact(label: "Gen V Reference Posture", value: "cleanRoomReferenceOnly")
        ]
        facts.append(contentsOf: genVVariantFacts(for: record))
        return facts
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
            facts.append(SourceIndexFact(label: "Gen V Source Name", value: spec.sourceName))
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
                message: "Pokemon Black/White source rows remain read-only in this slice; blocked actions: \(genVBlockedActions.joined(separator: ", ")).",
                span: record.sourceSpan
            )
        ]
    }

    private static func genVSourceRole(for record: NDSDataCatalogRecord) -> String {
        if isGenVUnavailableTitle(record) {
            return "titleUnavailable"
        }
        let lower = record.relativePath.lowercased()
        if lower.hasPrefix("data/encounters/") {
            return "encounterPreview"
        }
        if record.domain == .audio {
            return "audioMetadata"
        }
        if record.role == .binaryContainer || record.containerSummary != nil || record.format == .narc {
            return "nitroArchiveRoute"
        }
        if lower.hasPrefix("files/a/") {
            return "nitroArchiveGroup"
        }
        if lower.hasPrefix("files/") {
            return "nitroFSResource"
        }
        if lower.hasPrefix("overlays/") {
            return "overlayRouting"
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

    private static func genVSourceRoleDetail(for role: String) -> String {
        switch role {
        case "encounterPreview":
            return "Encounter data is indexed for preview context."
        case "audioMetadata":
            return "SDAT/SSEQ/SBNK/SWAR/STRM candidates retain read-only audio metadata facts."
        case "nitroArchiveRoute":
            return "NARC or container-like resources are routed for inventory and migration planning only."
        case "nitroArchiveGroup":
            return "files/a archive-group paths are identified for future Gen V container routing."
        case "nitroFSResource":
            return "NitroFS resource files are indexed as source-tree inventory."
        case "overlayRouting":
            return "Overlay sources are indexed for disassembly and script-routing context."
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

        if lower.contains("map_headers") || lower.contains("map_header") || lower.contains("maptable") {
            keys.insert("map-header")
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
            return ["Makefile", "config.mk", "main.rsf", "main.lsf", "black.us", "white.us", "files", "data", "src", "asm", "include", "overlays", "ndsdisasm_config"]
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
            sourceMarkerPaths: [],
            unavailableReason: "No public/materialized Black 2 decomp source root was found in the configured central corpus."
        ),
        GenVTitleCoverageSpec(
            id: "white2.us",
            title: "Pokemon - White Version 2 (USA, Europe) (NDSi Enhanced).nds",
            family: "black2White2",
            sourceName: "none",
            sourceMarkerPaths: [],
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

    init(
        _ domain: NDSDataDomain,
        _ relativePath: String,
        role: NDSDataSourceRole = .sourceTree,
        allowedExtensions: Set<String>? = nil,
        format: NDSDataSourceFormat? = nil,
        required: Bool = true
    ) {
        self.domain = domain
        self.relativePath = relativePath
        self.role = role
        self.allowedExtensions = allowedExtensions
        self.format = format
        self.required = required
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
