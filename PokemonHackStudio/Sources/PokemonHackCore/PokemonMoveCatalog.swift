import Foundation

public struct ProjectMoveCatalog: Codable, Equatable {
    public let root: SourceLocation
    public let profile: GameProfile
    public let adapterID: String
    public let adapterName: String
    public let summary: MoveCatalogSummary
    public let moves: [MoveDetail]
    public let machineMemberships: [MoveMachineMembership]
    public let tutorMemberships: [MoveTutorMembership]
    public let learnsetMemberships: [MoveLearnsetMembership]
    public let diagnostics: [Diagnostic]

    public init(
        root: SourceLocation,
        profile: GameProfile,
        adapterID: String,
        adapterName: String,
        summary: MoveCatalogSummary,
        moves: [MoveDetail],
        machineMemberships: [MoveMachineMembership] = [],
        tutorMemberships: [MoveTutorMembership] = [],
        learnsetMemberships: [MoveLearnsetMembership] = [],
        diagnostics: [Diagnostic] = []
    ) {
        self.root = root
        self.profile = profile
        self.adapterID = adapterID
        self.adapterName = adapterName
        self.summary = summary
        self.moves = moves
        self.machineMemberships = machineMemberships
        self.tutorMemberships = tutorMemberships
        self.learnsetMemberships = learnsetMemberships
        self.diagnostics = diagnostics
    }
}

public struct MoveCatalogSummary: Codable, Equatable {
    public let moveCount: Int
    public let machineMoveCount: Int
    public let tutorMoveCount: Int
    public let learnsetReferenceCount: Int
    public let unresolvedReferenceCount: Int

    public init(
        moveCount: Int,
        machineMoveCount: Int,
        tutorMoveCount: Int,
        learnsetReferenceCount: Int,
        unresolvedReferenceCount: Int
    ) {
        self.moveCount = moveCount
        self.machineMoveCount = machineMoveCount
        self.tutorMoveCount = tutorMoveCount
        self.learnsetReferenceCount = learnsetReferenceCount
        self.unresolvedReferenceCount = unresolvedReferenceCount
    }
}

public struct MoveDetail: Codable, Equatable, Identifiable {
    public var id: String { moveID }

    public let moveID: String
    public let displayName: String
    public let ordinal: Int?
    public let sourceSpan: SourceSpan
    public let sourcePreview: String?
    public let facts: [SourceIndexFact]
    public let flags: [String]
    public let machineMemberships: [MoveMachineMembership]
    public let tutorMemberships: [MoveTutorMembership]
    public let learnedBy: [MoveLearnsetMembership]
    public let diagnostics: [Diagnostic]

    public init(
        moveID: String,
        displayName: String,
        ordinal: Int?,
        sourceSpan: SourceSpan,
        sourcePreview: String? = nil,
        facts: [SourceIndexFact] = [],
        flags: [String] = [],
        machineMemberships: [MoveMachineMembership] = [],
        tutorMemberships: [MoveTutorMembership] = [],
        learnedBy: [MoveLearnsetMembership] = [],
        diagnostics: [Diagnostic] = []
    ) {
        self.moveID = moveID
        self.displayName = displayName
        self.ordinal = ordinal
        self.sourceSpan = sourceSpan
        self.sourcePreview = sourcePreview
        self.facts = facts
        self.flags = flags
        self.machineMemberships = machineMemberships
        self.tutorMemberships = tutorMemberships
        self.learnedBy = learnedBy
        self.diagnostics = diagnostics
    }
}

public struct MoveMachineMembership: Codable, Equatable, Identifiable {
    public var id: String { "\(moveID):\(token)" }

    public let moveID: String
    public let itemSymbol: String
    public let token: String
    public let ordinal: Int?
    public let sourceSpan: SourceSpan
    public let eligibleSpeciesCount: Int
    public let eligibleSpeciesIDs: [String]
    public let learnsetSourceSpans: [SourceSpan]

    public init(
        moveID: String,
        itemSymbol: String,
        token: String,
        ordinal: Int?,
        sourceSpan: SourceSpan,
        eligibleSpeciesIDs: [String] = [],
        learnsetSourceSpans: [SourceSpan] = []
    ) {
        self.moveID = moveID
        self.itemSymbol = itemSymbol
        self.token = token
        self.ordinal = ordinal
        self.sourceSpan = sourceSpan
        self.eligibleSpeciesCount = eligibleSpeciesIDs.count
        self.eligibleSpeciesIDs = eligibleSpeciesIDs
        self.learnsetSourceSpans = learnsetSourceSpans
    }
}

public struct MoveTutorMembership: Codable, Equatable, Identifiable {
    public var id: String { "\(moveID):\(tutorSymbol):\(tableIndex ?? -1)" }

    public let moveID: String
    public let tutorSymbol: String
    public let tableIndex: Int?
    public let sourceSpan: SourceSpan
    public let eligibleSpeciesCount: Int
    public let eligibleSpeciesIDs: [String]
    public let learnsetSourceSpans: [SourceSpan]

    public init(
        moveID: String,
        tutorSymbol: String,
        tableIndex: Int?,
        sourceSpan: SourceSpan,
        eligibleSpeciesIDs: [String] = [],
        learnsetSourceSpans: [SourceSpan] = []
    ) {
        self.moveID = moveID
        self.tutorSymbol = tutorSymbol
        self.tableIndex = tableIndex
        self.sourceSpan = sourceSpan
        self.eligibleSpeciesCount = eligibleSpeciesIDs.count
        self.eligibleSpeciesIDs = eligibleSpeciesIDs
        self.learnsetSourceSpans = learnsetSourceSpans
    }
}

public struct MoveLearnsetMembership: Codable, Equatable, Identifiable {
    public var id: String {
        "\(moveID):\(speciesID):\(bucket.rawValue):\(level.map(String.init) ?? "-"):\(sourceSpan.relativePath):\(sourceSpan.startLine)"
    }

    public let moveID: String
    public let speciesID: String
    public let bucket: LearnsetBucket
    public let level: Int?
    public let sourceSpan: SourceSpan

    public init(moveID: String, speciesID: String, bucket: LearnsetBucket, level: Int? = nil, sourceSpan: SourceSpan) {
        self.moveID = moveID
        self.speciesID = speciesID
        self.bucket = bucket
        self.level = level
        self.sourceSpan = sourceSpan
    }
}

public enum ProjectMoveCatalogBuilder {
    public static func build(path: String, fileManager: FileManager = .default) throws -> ProjectMoveCatalog {
        try build(index: GameAdapterRegistry.index(path: path), fileManager: fileManager)
    }

    public static func build(
        index: ProjectIndex,
        sourceIndex: ProjectSourceIndex? = nil,
        speciesCatalog: ProjectSpeciesCatalog? = nil,
        fileManager: FileManager = .default
    ) throws -> ProjectMoveCatalog {
        let sourceIndex = try sourceIndex ?? ProjectSourceIndexLoader.load(from: index, fileManager: fileManager)
        let moveGraph = try MoveGraphBuilder.build(index: index, sourceIndex: sourceIndex, fileManager: fileManager)
        let speciesCatalog = try speciesCatalog ?? ProjectSpeciesCatalogBuilder.build(index: index, fileManager: fileManager)
        var diagnostics = sourceIndex.diagnostics + moveGraph.diagnostics + speciesCatalog.diagnostics

        let root = URL(fileURLWithPath: index.root.path)
        let moveRecords = sourceIndex.records.filter { $0.module == .moves }
        if moveRecords.isEmpty {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "MOVE_CATALOG_MOVE_TABLE_MISSING",
                    message: "No source-index move table records were found for this project.",
                    span: nil
                )
            )
        }

        diagnostics.append(contentsOf: sentinelDiagnostics(in: moveRecords))
        diagnostics.append(contentsOf: duplicateConstantDiagnostics(root: root, fileManager: fileManager))

        let moveRecordGroups = Dictionary(grouping: moveRecords) { normalizedMoveID($0.title) }
        for (moveID, records) in moveRecordGroups where moveID != "MOVE_NONE" && records.count > 1 {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "MOVE_CATALOG_DUPLICATE_MOVE",
                    message: "\(moveID) appears in \(records.count) indexed move records.",
                    span: records.first?.sourceSpan
                )
            )
        }

        let learnsetMemberships = learnedByMemberships(speciesCatalog: speciesCatalog, moveGraph: moveGraph)
        let machineMemberships = machineMemberships(speciesCatalog: speciesCatalog)
        let tutorScan = tutorMemberships(root: root, profile: index.profile, fileManager: fileManager)
        diagnostics.append(contentsOf: tutorScan.diagnostics)

        let knownMoveIDs = Set(moveRecords.map { normalizedMoveID($0.title) }.filter { $0 != "MOVE_NONE" })
        let referencedMoveIDs = Set(learnsetMemberships.map(\.moveID))
        let unresolvedReferences = referencedMoveIDs.subtracting(knownMoveIDs).filter { $0 != "MOVE_NONE" }.sorted()
        diagnostics.append(contentsOf: unresolvedReferences.prefix(20).map { moveID in
            Diagnostic(
                severity: .warning,
                code: "MOVE_CATALOG_MOVE_UNRESOLVED",
                message: "\(moveID) is referenced by a learnset but not present in the indexed move table.",
                span: learnsetMemberships.first { $0.moveID == moveID }?.sourceSpan
            )
        })

        let machineByMove = Dictionary(grouping: machineMemberships, by: \.moveID)
        let tutorByMove = Dictionary(grouping: tutorScan.memberships, by: \.moveID)
        let learnedByMove = Dictionary(grouping: learnsetMemberships, by: \.moveID)

        let moves = moveRecords.compactMap { record -> MoveDetail? in
            let moveID = normalizedMoveID(record.title)
            guard moveID != "MOVE_NONE" else { return nil }
            return MoveDetail(
                moveID: moveID,
                displayName: displayName(forMoveID: moveID),
                ordinal: ordinal(from: record),
                sourceSpan: record.sourceSpan,
                sourcePreview: record.preview,
                facts: record.facts,
                flags: flags(in: record.facts),
                machineMemberships: machineByMove[moveID] ?? [],
                tutorMemberships: tutorByMove[moveID] ?? [],
                learnedBy: learnedByMove[moveID] ?? [],
                diagnostics: record.diagnostics + diagnostics.filter { $0.span == record.sourceSpan }
            )
        }
        .sorted { lhs, rhs in
            switch (lhs.ordinal, rhs.ordinal) {
            case let (left?, right?) where left != right:
                return left < right
            default:
                return lhs.moveID < rhs.moveID
            }
        }

        let summary = MoveCatalogSummary(
            moveCount: moves.count,
            machineMoveCount: Set(machineMemberships.map(\.moveID)).count,
            tutorMoveCount: Set(tutorScan.memberships.map(\.moveID)).count,
            learnsetReferenceCount: learnsetMemberships.count,
            unresolvedReferenceCount: unresolvedReferences.count
        )

        return ProjectMoveCatalog(
            root: index.root,
            profile: index.profile,
            adapterID: index.adapterID,
            adapterName: index.adapterName,
            summary: summary,
            moves: moves,
            machineMemberships: machineMemberships,
            tutorMemberships: tutorScan.memberships,
            learnsetMemberships: learnsetMemberships,
            diagnostics: diagnostics
        )
    }

    private static func learnedByMemberships(speciesCatalog: ProjectSpeciesCatalog, moveGraph: MoveGraph) -> [MoveLearnsetMembership] {
        var memberships: [MoveLearnsetMembership] = []
        for species in speciesCatalog.species {
            memberships.append(contentsOf: species.learnsets.levelUp.map {
                MoveLearnsetMembership(moveID: $0.move, speciesID: species.speciesID, bucket: .levelUp, level: $0.level, sourceSpan: $0.sourceSpan)
            })
            memberships.append(contentsOf: species.learnsets.tmhm.map {
                MoveLearnsetMembership(moveID: $0.move, speciesID: species.speciesID, bucket: .tmhm, sourceSpan: $0.sourceSpan)
            })
            memberships.append(contentsOf: species.learnsets.egg.map {
                MoveLearnsetMembership(moveID: $0.move, speciesID: species.speciesID, bucket: .egg, sourceSpan: $0.sourceSpan)
            })
        }

        var existingIDs = Set(memberships.map(\.id))
        for entry in moveGraph.learnsets {
            for moveID in entry.moveIDs where moveID != "MOVE_NONE" {
                let membership = MoveLearnsetMembership(
                    moveID: moveID,
                    speciesID: entry.speciesID,
                    bucket: entry.bucket,
                    sourceSpan: entry.sourceSpan
                )
                if !existingIDs.contains(membership.id) {
                    memberships.append(membership)
                    existingIDs.insert(membership.id)
                }
            }
        }

        return memberships.sorted {
            if $0.moveID != $1.moveID { return $0.moveID < $1.moveID }
            if $0.speciesID != $1.speciesID { return $0.speciesID < $1.speciesID }
            return $0.bucket.rawValue < $1.bucket.rawValue
        }
    }

    private static func machineMemberships(speciesCatalog: ProjectSpeciesCatalog) -> [MoveMachineMembership] {
        let membershipsByMove = Dictionary(grouping: speciesCatalog.species.flatMap { species in
            species.learnsets.tmhm.map { (species: species.speciesID, reference: $0) }
        }) { $0.reference.move }

        return (speciesCatalog.constants[.tmhmMoves] ?? []).enumerated().map { index, constant in
            let eligible = (membershipsByMove[constant.symbol] ?? []).sorted { $0.species < $1.species }
            let speciesIDs = eligible.map(\.species)
            let spans = uniqueSpans(eligible.map(\.reference.sourceSpan))
            return MoveMachineMembership(
                moveID: constant.symbol,
                itemSymbol: "ITEM_\(constant.value)",
                token: constant.value,
                ordinal: index,
                sourceSpan: constant.sourceSpan,
                eligibleSpeciesIDs: speciesIDs,
                learnsetSourceSpans: spans
            )
        }
    }

    private static func tutorMemberships(
        root: URL,
        profile: GameProfile,
        fileManager: FileManager
    ) -> (memberships: [MoveTutorMembership], diagnostics: [Diagnostic]) {
        let relativePath = "src/data/pokemon/tutor_learnsets.h"
        let url = root.appendingPathComponent(relativePath)
        guard fileManager.fileExists(atPath: url.path) else {
            return ([], [
                Diagnostic(
                    severity: .warning,
                    code: "MOVE_CATALOG_TUTOR_TABLE_MISSING",
                    message: "No tutor learnset table was detected for \(profile.rawValue).",
                    span: SourceSpan(relativePath: relativePath, startLine: 1)
                )
            ])
        }
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            return ([], [
                Diagnostic(
                    severity: .warning,
                    code: "MOVE_CATALOG_TUTOR_TABLE_UNREADABLE",
                    message: "Could not read tutor learnset table.",
                    span: SourceSpan(relativePath: relativePath, startLine: 1)
                )
            ])
        }

        let tutorMoves = tutorMoveTable(in: text, relativePath: relativePath)
        let speciesByMove = tutorSpeciesMemberships(in: text, relativePath: relativePath)
        let memberships = tutorMoves.enumerated().map { index, move in
            let eligible = (speciesByMove[move.moveID] ?? []).sorted { $0.speciesID < $1.speciesID }
            return MoveTutorMembership(
                moveID: move.moveID,
                tutorSymbol: tutorSymbol(forMoveID: move.moveID),
                tableIndex: index,
                sourceSpan: move.span,
                eligibleSpeciesIDs: eligible.map(\.speciesID),
                learnsetSourceSpans: uniqueSpans(eligible.map(\.span))
            )
        }

        return (memberships, tutorMoves.isEmpty ? [
            Diagnostic(
                severity: .warning,
                code: "MOVE_CATALOG_TUTOR_MOVES_MISSING",
                message: "Tutor learnset source exists, but no tutor move table entries were detected.",
                span: SourceSpan(relativePath: relativePath, startLine: 1)
            )
        ] : [])
    }

    private static func tutorMoveTable(in text: String, relativePath: String) -> [(moveID: String, span: SourceSpan)] {
        let lines = text.components(separatedBy: .newlines)
        guard let start = lines.firstIndex(where: { $0.contains("gTutorMoves") || $0.contains("sTutorMoves") }) else {
            return []
        }
        var result: [(String, SourceSpan)] = []
        var index = start
        while index < lines.count {
            let line = lines[index]
            for match in regexMatches(#"(MOVE_[A-Z0-9_]+)"#, in: line) where match.count >= 2 && match[1] != "MOVE_NONE" {
                result.append((match[1], SourceSpan(relativePath: relativePath, startLine: index + 1)))
            }
            if index > start, line.contains("};") { break }
            index += 1
        }
        return result
    }

    private static func tutorSpeciesMemberships(
        in text: String,
        relativePath: String
    ) -> [String: [(speciesID: String, span: SourceSpan)]] {
        let parsed = ["sTutorLearnsets", "gTutorLearnsets"].lazy.map {
            CInitializerParser.tableEntries(
                in: text,
                descriptor: CInitializerTableDescriptor(
                    module: .learnsets,
                    relativePath: relativePath,
                    tableSymbol: $0,
                    entryStyle: .bracketed
                )
            )
        }.first { !$0.entries.isEmpty } ?? CInitializerParser.tableEntries(
            in: text,
            descriptor: CInitializerTableDescriptor(
                module: .learnsets,
                relativePath: relativePath,
                tableSymbol: "sTutorLearnsets",
                entryStyle: .bracketed
            )
        )
        var result: [String: [(speciesID: String, span: SourceSpan)]] = [:]
        for entry in parsed.entries where entry.symbol.hasPrefix("SPECIES_") {
            for moveID in tutorMoves(in: entry.body) {
                result[moveID, default: []].append((entry.symbol, entry.span))
            }
        }
        return result
    }

    private static func tutorMoves(in body: String) -> [String] {
        var moves: [String] = []
        moves.append(contentsOf: regexMatches(#"\.([A-Z0-9_]+)\s*=\s*TRUE"#, in: body).compactMap { match in
            guard match.count >= 2 else { return nil }
            return "MOVE_\(match[1])"
        })
        moves.append(contentsOf: regexMatches(#"TUTOR\(\s*([A-Z0-9_]+)\s*\)"#, in: body).compactMap { match in
            guard match.count >= 2 else { return nil }
            return "MOVE_\(match[1])"
        })
        moves.append(contentsOf: regexMatches(#"(MOVE_[A-Z0-9_]+)"#, in: body).compactMap { match in
            guard match.count >= 2 else { return nil }
            return match[1]
        })
        return Array(Set(moves.filter { $0 != "MOVE_NONE" })).sorted()
    }

    private static func sentinelDiagnostics(in records: [SourceIndexRecord]) -> [Diagnostic] {
        records.compactMap { record in
            guard normalizedMoveID(record.title) == "MOVE_NONE" else { return nil }
            return Diagnostic(
                severity: .info,
                code: "MOVE_CATALOG_SENTINEL_EXCLUDED",
                message: "MOVE_NONE is a sentinel and is excluded from the move catalog.",
                span: record.sourceSpan
            )
        }
    }

    private static func duplicateConstantDiagnostics(root: URL, fileManager: FileManager) -> [Diagnostic] {
        let relativePath = "include/constants/moves.h"
        let url = root.appendingPathComponent(relativePath)
        guard
            fileManager.fileExists(atPath: url.path),
            let text = try? String(contentsOf: url, encoding: .utf8)
        else {
            return []
        }

        let constants = text.components(separatedBy: .newlines).enumerated().compactMap { lineIndex, line -> (symbol: String, value: String, span: SourceSpan)? in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("#define MOVE_") else { return nil }
            let parts = trimmed.split(maxSplits: 2, whereSeparator: { $0.isWhitespace }).map(String.init)
            guard parts.count >= 3 else { return nil }
            return (parts[1], parts[2], SourceSpan(relativePath: relativePath, startLine: lineIndex + 1))
        }

        var diagnostics: [Diagnostic] = []
        for (symbol, entries) in Dictionary(grouping: constants, by: \.symbol) where entries.count > 1 {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "MOVE_CATALOG_CONSTANT_DUPLICATE",
                    message: "\(symbol) is defined \(entries.count) times in move constants.",
                    span: entries.first?.span
                )
            )
        }
        for (value, entries) in Dictionary(grouping: constants.filter { $0.symbol != "MOVE_NONE" }, by: \.value) where entries.count > 1 {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "MOVE_CATALOG_CONSTANT_DUPLICATE",
                    message: "Move constant value \(value) is shared by \(entries.map(\.symbol).sorted().joined(separator: ", ")).",
                    span: entries.first?.span
                )
            )
        }
        return diagnostics
    }

    private static func flags(in facts: [SourceIndexFact]) -> [String] {
        guard let value = facts.first(where: { $0.label == "flags" })?.value else { return [] }
        return regexMatches(#"FLAG_[A-Z0-9_]+"#, in: value).compactMap { $0.count >= 1 ? $0[0] : nil }.sorted()
    }

    private static func ordinal(from record: SourceIndexRecord) -> Int? {
        let match = firstRegexMatch(#"^#([0-9]+)$"#, in: record.title)
        return match.flatMap(Int.init) ?? record.facts.first { $0.label == "Index" }.flatMap { Int($0.value) }
    }

    private static func displayName(forMoveID moveID: String) -> String {
        let raw = moveID.replacingOccurrences(of: "MOVE_", with: "")
        return raw.split(separator: "_").map { token in
            token.prefix(1) + token.dropFirst().lowercased()
        }.joined(separator: " ")
    }

    private static func tutorSymbol(forMoveID moveID: String) -> String {
        "TUTOR_\(moveID)"
    }

    private static func uniqueSpans(_ spans: [SourceSpan]) -> [SourceSpan] {
        var seen: Set<String> = []
        return spans.filter { span in
            let key = "\(span.relativePath):\(span.startLine):\(span.endLine)"
            return seen.insert(key).inserted
        }
    }

    private static func normalizedMoveID(_ value: String) -> String {
        if value.hasPrefix("MOVE_") { return value }
        if value.hasPrefix("#"), let ordinal = Int(value.dropFirst()), ordinal == 0 { return "MOVE_NONE" }
        return value
    }

    private static func firstRegexMatch(_ pattern: String, in text: String) -> String? {
        regexMatches(pattern, in: text).first?.dropFirst().first
    }

    private static func regexMatches(_ pattern: String, in text: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).map { match in
            (0..<match.numberOfRanges).compactMap { index in
                let range = match.range(at: index)
                guard let swiftRange = Range(range, in: text) else { return nil }
                return String(text[swiftRange])
            }
        }
    }
}
