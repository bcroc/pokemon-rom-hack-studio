import Foundation

public enum NDSDataSemanticCoverageRowStatus: String, Codable, Equatable, CaseIterable {
    case eligible
    case blocked
    case skipped
}

public struct NDSDataSemanticCoverageSummary: Codable, Equatable {
    public let catalogRows: Int
    public let scannedRows: Int
    public let eligibleRows: Int
    public let eligibleFields: Int
    public let blockedRows: Int
    public let skippedRows: Int

    public init(
        catalogRows: Int,
        scannedRows: Int,
        eligibleRows: Int,
        eligibleFields: Int,
        blockedRows: Int,
        skippedRows: Int
    ) {
        self.catalogRows = catalogRows
        self.scannedRows = scannedRows
        self.eligibleRows = eligibleRows
        self.eligibleFields = eligibleFields
        self.blockedRows = blockedRows
        self.skippedRows = skippedRows
    }
}

public struct NDSDataSemanticCoverageDomainSummary: Codable, Equatable, Identifiable {
    public var id: String { domain.rawValue }

    public let domain: NDSDataDomain
    public let catalogRows: Int
    public let scannedRows: Int
    public let eligibleRows: Int
    public let eligibleFields: Int
    public let blockedRows: Int
    public let skippedRows: Int

    public init(
        domain: NDSDataDomain,
        catalogRows: Int,
        scannedRows: Int,
        eligibleRows: Int,
        eligibleFields: Int,
        blockedRows: Int,
        skippedRows: Int
    ) {
        self.domain = domain
        self.catalogRows = catalogRows
        self.scannedRows = scannedRows
        self.eligibleRows = eligibleRows
        self.eligibleFields = eligibleFields
        self.blockedRows = blockedRows
        self.skippedRows = skippedRows
    }
}

public struct NDSDataSemanticCoverageFieldKindCount: Codable, Equatable, Identifiable {
    public var id: String { kind.rawValue }

    public let kind: NDSDataSemanticFieldValueKind
    public let count: Int

    public init(kind: NDSDataSemanticFieldValueKind, count: Int) {
        self.kind = kind
        self.count = count
    }
}

public struct NDSDataSemanticCoverageBlockedReasonBucket: Codable, Equatable, Identifiable {
    public var id: String { reason }

    public let reason: String
    public let rowCount: Int
    public let sampleRecordIDs: [String]

    public init(reason: String, rowCount: Int, sampleRecordIDs: [String]) {
        self.reason = reason
        self.rowCount = rowCount
        self.sampleRecordIDs = sampleRecordIDs
    }
}

public struct NDSDataSemanticCoverageRow: Codable, Equatable, Identifiable {
    public let id: String
    public let domain: NDSDataDomain
    public let relativePath: String
    public let status: NDSDataSemanticCoverageRowStatus
    public let fieldCount: Int
    public let fieldKindCounts: [NDSDataSemanticCoverageFieldKindCount]
    public let diagnosticCodes: [String]
    public let skipReason: String?

    public init(
        id: String,
        domain: NDSDataDomain,
        relativePath: String,
        status: NDSDataSemanticCoverageRowStatus,
        fieldCount: Int,
        fieldKindCounts: [NDSDataSemanticCoverageFieldKindCount],
        diagnosticCodes: [String],
        skipReason: String? = nil
    ) {
        self.id = id
        self.domain = domain
        self.relativePath = relativePath
        self.status = status
        self.fieldCount = fieldCount
        self.fieldKindCounts = fieldKindCounts
        self.diagnosticCodes = diagnosticCodes
        self.skipReason = skipReason
    }
}

public struct NDSDataSemanticCoverageReport: Codable, Equatable {
    public let profile: GameProfile
    public let family: GenIIIGameFamily
    public let rootPath: String
    public let summary: NDSDataSemanticCoverageSummary
    public let domainSummaries: [NDSDataSemanticCoverageDomainSummary]
    public let fieldKindCounts: [NDSDataSemanticCoverageFieldKindCount]
    public let blockedReasonBuckets: [NDSDataSemanticCoverageBlockedReasonBucket]
    public let rows: [NDSDataSemanticCoverageRow]

    public init(
        profile: GameProfile,
        family: GenIIIGameFamily,
        rootPath: String,
        summary: NDSDataSemanticCoverageSummary,
        domainSummaries: [NDSDataSemanticCoverageDomainSummary],
        fieldKindCounts: [NDSDataSemanticCoverageFieldKindCount],
        blockedReasonBuckets: [NDSDataSemanticCoverageBlockedReasonBucket],
        rows: [NDSDataSemanticCoverageRow]
    ) {
        self.profile = profile
        self.family = family
        self.rootPath = rootPath
        self.summary = summary
        self.domainSummaries = domainSummaries
        self.fieldKindCounts = fieldKindCounts
        self.blockedReasonBuckets = blockedReasonBuckets
        self.rows = rows
    }
}

public enum NDSDataSemanticCoverageReportBuilder {
    private static let bucketSampleLimit = 5
    private static let semanticFieldKinds: [NDSDataSemanticFieldValueKind] = [.string, .number, .bool, .null]

    public static func build(
        path: String,
        fileManager: FileManager = .default
    ) throws -> NDSDataSemanticCoverageReport {
        try build(catalog: NDSDataCatalogBuilder.build(path: path, fileManager: fileManager), fileManager: fileManager)
    }

    public static func build(
        catalog: ProjectNDSDataCatalog,
        fileManager: FileManager = .default
    ) -> NDSDataSemanticCoverageReport {
        let referenceRoot = isReferenceResearchRoot(catalog.root.path, fileManager: fileManager)
        let rows = catalog.records.map { record -> NDSDataSemanticCoverageRow in
            if let skipReason = snapshotSkipReason(catalog: catalog, record: record, isReferenceRoot: referenceRoot) {
                return coverageRow(record: record, status: .skipped, diagnosticCodes: [], skipReason: skipReason)
            }

            let snapshot = NDSDataSemanticEditor.snapshot(
                catalog: catalog,
                recordID: record.id,
                fileManager: fileManager
            )
            let fieldKindCounts = countsByFieldKind(snapshot.fields.map(\.valueKind))
            let diagnosticCodes = stableDiagnosticCodes(snapshot.diagnostics)
            let status: NDSDataSemanticCoverageRowStatus = snapshot.canEdit ? .eligible : .blocked
            let skipReason = status == .blocked
                ? primaryBlockedReason(diagnosticCodes: diagnosticCodes, fields: snapshot.fields)
                : nil
            return NDSDataSemanticCoverageRow(
                id: record.id,
                domain: record.domain,
                relativePath: record.relativePath,
                status: status,
                fieldCount: snapshot.fields.count,
                fieldKindCounts: fieldKindCounts,
                diagnosticCodes: diagnosticCodes,
                skipReason: skipReason
            )
        }

        return NDSDataSemanticCoverageReport(
            profile: catalog.profile,
            family: catalog.family,
            rootPath: catalog.root.path,
            summary: summary(catalogRows: catalog.records.count, rows: rows),
            domainSummaries: domainSummaries(records: catalog.records, rows: rows),
            fieldKindCounts: countsByFieldKind(rows.filter { $0.status == .eligible }.flatMap { row in
                row.fieldKindCounts.flatMap { Array(repeating: $0.kind, count: $0.count) }
            }),
            blockedReasonBuckets: blockedReasonBuckets(rows: rows),
            rows: rows
        )
    }

    private static func coverageRow(
        record: NDSDataCatalogRecord,
        status: NDSDataSemanticCoverageRowStatus,
        diagnosticCodes: [String],
        skipReason: String
    ) -> NDSDataSemanticCoverageRow {
        NDSDataSemanticCoverageRow(
            id: record.id,
            domain: record.domain,
            relativePath: record.relativePath,
            status: status,
            fieldCount: 0,
            fieldKindCounts: countsByFieldKind([]),
            diagnosticCodes: diagnosticCodes,
            skipReason: skipReason
        )
    }

    private static func snapshotSkipReason(
        catalog: ProjectNDSDataCatalog,
        record: NDSDataCatalogRecord,
        isReferenceRoot: Bool
    ) -> String? {
        if isReferenceRoot {
            return "referenceRoot"
        }
        if catalog.profile == .pokeblack {
            return "genVReadOnly"
        }
        if catalog.profile == .ndsROM {
            return "standaloneNDSROM"
        }
        if catalog.profile == .pmdSky {
            return "spinOffReadOnly"
        }
        if record.role == .generatedReference {
            return "generatedReference"
        }
        if record.role == .binaryContainer || record.containerSummary != nil || record.format == .narc {
            return "containerOrNARC"
        }
        if record.role == .nitroFSManifest {
            return "nitroFSManifest"
        }
        if record.role == .metadataPacket {
            return "metadataPacket"
        }
        if record.role == .metadataUnavailable {
            return "metadataUnavailable"
        }
        return nil
    }

    private static func summary(
        catalogRows: Int,
        rows: [NDSDataSemanticCoverageRow]
    ) -> NDSDataSemanticCoverageSummary {
        NDSDataSemanticCoverageSummary(
            catalogRows: catalogRows,
            scannedRows: rows.filter { $0.status != .skipped }.count,
            eligibleRows: rows.filter { $0.status == .eligible }.count,
            eligibleFields: rows.filter { $0.status == .eligible }.reduce(0) { $0 + $1.fieldCount },
            blockedRows: rows.filter { $0.status == .blocked }.count,
            skippedRows: rows.filter { $0.status == .skipped }.count
        )
    }

    private static func domainSummaries(
        records: [NDSDataCatalogRecord],
        rows: [NDSDataSemanticCoverageRow]
    ) -> [NDSDataSemanticCoverageDomainSummary] {
        NDSDataDomain.allCases.compactMap { domain in
            let domainRows = rows.filter { $0.domain == domain }
            let catalogRows = records.filter { $0.domain == domain }.count
            guard catalogRows > 0 else { return nil }
            return NDSDataSemanticCoverageDomainSummary(
                domain: domain,
                catalogRows: catalogRows,
                scannedRows: domainRows.filter { $0.status != .skipped }.count,
                eligibleRows: domainRows.filter { $0.status == .eligible }.count,
                eligibleFields: domainRows.filter { $0.status == .eligible }.reduce(0) { $0 + $1.fieldCount },
                blockedRows: domainRows.filter { $0.status == .blocked }.count,
                skippedRows: domainRows.filter { $0.status == .skipped }.count
            )
        }
    }

    private static func countsByFieldKind(
        _ kinds: [NDSDataSemanticFieldValueKind]
    ) -> [NDSDataSemanticCoverageFieldKindCount] {
        semanticFieldKinds.map { kind in
            NDSDataSemanticCoverageFieldKindCount(kind: kind, count: kinds.filter { $0 == kind }.count)
        }
    }

    private static func blockedReasonBuckets(
        rows: [NDSDataSemanticCoverageRow]
    ) -> [NDSDataSemanticCoverageBlockedReasonBucket] {
        var buckets: [String: [String]] = [:]
        for row in rows where row.status != .eligible {
            let reason = row.skipReason ?? "unknownBlocked"
            buckets[reason, default: []].append(row.id)
        }
        return buckets
            .map { reason, recordIDs in
                NDSDataSemanticCoverageBlockedReasonBucket(
                    reason: reason,
                    rowCount: recordIDs.count,
                    sampleRecordIDs: Array(recordIDs.sorted().prefix(bucketSampleLimit))
                )
            }
            .sorted {
                if $0.rowCount != $1.rowCount {
                    return $0.rowCount > $1.rowCount
                }
                return $0.reason < $1.reason
            }
    }

    private static func stableDiagnosticCodes(_ diagnostics: [Diagnostic]) -> [String] {
        var codes: [String] = []
        var seen = Set<String>()
        for diagnostic in diagnostics where seen.insert(diagnostic.code).inserted {
            codes.append(diagnostic.code)
        }
        return codes
    }

    private static func primaryBlockedReason(
        diagnosticCodes: [String],
        fields: [NDSDataSemanticField]
    ) -> String {
        if let first = diagnosticCodes.first {
            return first
        }
        if fields.isEmpty {
            return "noSemanticFields"
        }
        return "semanticSnapshotBlocked"
    }

    private static func isReferenceResearchRoot(
        _ path: String,
        fileManager: FileManager
    ) -> Bool {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        var candidates = [
            url,
            url.resolvingSymlinksInPath().standardizedFileURL
        ]
        if let destination = try? fileManager.destinationOfSymbolicLink(atPath: url.path) {
            let destinationURL = URL(
                fileURLWithPath: destination,
                relativeTo: url.deletingLastPathComponent()
            ).standardizedFileURL
            candidates.append(destinationURL)
            candidates.append(destinationURL.resolvingSymlinksInPath().standardizedFileURL)
        }
        return candidates.contains { candidate in
            let components = candidate.pathComponents
            return components.contains("references") || components.contains("reference-repos")
        }
    }
}
