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
    case resources
}

public enum NDSDataSourceRole: String, Codable, Equatable, CaseIterable, Sendable {
    case sourceTree
    case generatedReference
    case nitroFSManifest
    case binaryContainer
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

public struct NDSDataContainerSummary: Codable, Equatable {
    public let kind: NDSDataContainerKind
    public let memberCount: Int
    public let namedMemberCount: Int
    public let unnamedMemberCount: Int
    public let byteCount: UInt64?
    public let sampleMemberPaths: [String]
    public let isReadOnly: Bool
    public let diagnostics: [Diagnostic]

    public init(
        kind: NDSDataContainerKind,
        memberCount: Int,
        namedMemberCount: Int,
        unnamedMemberCount: Int,
        byteCount: UInt64?,
        sampleMemberPaths: [String],
        isReadOnly: Bool = true,
        diagnostics: [Diagnostic] = []
    ) {
        self.kind = kind
        self.memberCount = memberCount
        self.namedMemberCount = namedMemberCount
        self.unnamedMemberCount = unnamedMemberCount
        self.byteCount = byteCount
        self.sampleMemberPaths = sampleMemberPaths
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
        self.diagnostics = diagnostics
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

        let records = uniqueRecords(
            descriptors.flatMap { descriptor in
                catalogRecords(for: descriptor, root: rootURL, fileManager: fileManager)
            } + discoveredContainerRecords(for: index.profile, root: rootURL, fileManager: fileManager)
        ).sorted(by: recordSort)

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
                CatalogPathDescriptor(.resources, "filesystem.mk", role: .nitroFSManifest)
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
        diagnostics.append(contentsOf: containerSummary?.diagnostics ?? [])

        let facts = factsForRecord(format: format, role: descriptor.role, byteCount: byteCount, recordCount: recordCount, containerSummary: containerSummary)
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

    private static func discoveredContainerRecords(for profile: GameProfile, root: URL, fileManager: FileManager) -> [NDSDataCatalogRecord] {
        switch profile {
        case .pokeplatinum:
            return literalNARCRecords(root: root, searchRoot: "res/prebuilt", fileManager: fileManager)
        case .pokeheartgold:
            return literalNARCRecords(root: root, searchRoot: "files", fileManager: fileManager)
        case .pokediamond:
            return unpackedArchiveDirectoryRecords(root: root, searchRoot: "files", fileManager: fileManager)
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
        report.narcArchives.map { archive in
            let domain = domain(forContainerPath: archive.path)
            let summary = containerSummary(for: archive.index, byteCount: archive.size)
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
                    containerSummary: summary
                ),
                preview: containerPreview(summary),
                containerSummary: summary,
                diagnostics: archive.index.diagnostics
            )
        }.sorted(by: recordSort)
    }

    private static func uniqueRecords(_ records: [NDSDataCatalogRecord]) -> [NDSDataCatalogRecord] {
        var seen: Set<String> = []
        var unique: [NDSDataCatalogRecord] = []
        for record in records where seen.insert(record.id).inserted {
            unique.append(record)
        }
        return unique
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
            return containerSummary(for: NARCParser.parse(path: relativePath, data: data), byteCount: UInt64(data.count))
        }
        if isDirectory {
            return unpackedArchiveSummary(url: url, fileManager: fileManager)
        }
        return nil
    }

    private static func containerSummary(for index: NARCIndex, byteCount: UInt64?) -> NDSDataContainerSummary {
        let namedCount = index.members.filter { $0.name != nil }.count
        return NDSDataContainerSummary(
            kind: .narc,
            memberCount: index.memberCount,
            namedMemberCount: namedCount,
            unnamedMemberCount: max(index.memberCount - namedCount, 0),
            byteCount: byteCount,
            sampleMemberPaths: Array(index.members.prefix(maxContainerSampleMembers).map(\.path)),
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
            diagnostics: []
        )
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

    private static func factsForRecord(
        format: NDSDataSourceFormat,
        role: NDSDataSourceRole,
        byteCount: UInt64?,
        recordCount: Int?,
        containerSummary: NDSDataContainerSummary? = nil
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
        case "bin", "dat", "sdat", "bmd0", "nsbmd", "ncgr", "nclr", "nscr", "ncer", "nanr":
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

    private static let excludedDirectoryNames: Set<String> = [
        ".git",
        ".pokemonhackstudio",
        ".swiftpm",
        "build",
        "DerivedData"
    ]

    private static let maxDiscoveredContainerRecords = 256
    private static let maxContainerSampleMembers = 8
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
        case .resources: return 9
        }
    }
}
