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
    public let descriptionSymbol: String?
    public let descriptionText: String?
    public let isDescriptionEditable: Bool
    public let isEditable: Bool
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
        descriptionSymbol: String? = nil,
        descriptionText: String? = nil,
        isDescriptionEditable: Bool = false,
        isEditable: Bool = false,
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
        self.descriptionSymbol = descriptionSymbol
        self.descriptionText = descriptionText
        self.isDescriptionEditable = isDescriptionEditable
        self.isEditable = isEditable
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

public struct MoveEditDraft: Codable, Equatable, Identifiable {
    public var id: String { moveID }

    public var moveID: String
    public var effect: String
    public var power: Int
    public var type: String
    public var accuracy: Int
    public var pp: Int
    public var secondaryEffectChance: Int
    public var target: String
    public var priority: Int
    public var flags: [String]
    public var descriptionText: String?

    public init(
        moveID: String,
        effect: String,
        power: Int,
        type: String,
        accuracy: Int,
        pp: Int,
        secondaryEffectChance: Int,
        target: String,
        priority: Int,
        flags: [String],
        descriptionText: String? = nil
    ) {
        self.moveID = moveID
        self.effect = effect
        self.power = power
        self.type = type
        self.accuracy = accuracy
        self.pp = pp
        self.secondaryEffectChance = secondaryEffectChance
        self.target = target
        self.priority = priority
        self.flags = normalizedFlags(flags)
        self.descriptionText = descriptionText
    }

    public init?(detail: MoveDetail) {
        let previewFields = detail.sourcePreview.map { MoveTopLevelFieldScanner.fields(in: $0) } ?? [:]

        func fact(_ key: String) -> String? {
            detail.facts.first { $0.label == key }?.value ?? previewFields[key]?.value
        }

        let isExpansionMoveInfo = detail.sourceSpan.relativePath == "src/data/moves_info.h"
        let secondaryEffectChance = fact("secondaryEffectChance").flatMap { Int(compactMoveValue($0)) }
        let flags = simpleFlags(in: fact("flags") ?? "") ?? detail.flags

        guard
            let effect = fact("effect"),
            let power = fact("power").flatMap({ Int(compactMoveValue($0)) }),
            let type = fact("type"),
            let accuracy = fact("accuracy").flatMap({ Int(compactMoveValue($0)) }),
            let pp = fact("pp").flatMap({ Int(compactMoveValue($0)) }),
            let target = fact("target"),
            let priority = fact("priority").flatMap({ Int(compactMoveValue($0)) })
        else {
            return nil
        }

        guard let resolvedSecondaryEffectChance = secondaryEffectChance ?? (isExpansionMoveInfo ? 0 : nil) else {
            return nil
        }

        self.init(
            moveID: detail.moveID,
            effect: compactMoveValue(effect),
            power: power,
            type: compactMoveValue(type),
            accuracy: accuracy,
            pp: pp,
            secondaryEffectChance: resolvedSecondaryEffectChance,
            target: compactMoveValue(target),
            priority: priority,
            flags: flags,
            descriptionText: detail.isDescriptionEditable ? detail.descriptionText : nil
        )
    }
}

public struct MoveEditFileChange: Codable, Equatable, Identifiable {
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

public struct MoveEditPlan: Codable, Equatable, Identifiable {
    public let id: String
    public let rootPath: String
    public let moveID: String
    public let draft: MoveEditDraft
    public let changes: [MoveEditFileChange]
    public let diagnostics: [Diagnostic]
    public let mutationPlan: MutationPlan
    public let backupRelativeRoot: String

    public init(
        id: String = UUID().uuidString,
        rootPath: String,
        moveID: String,
        draft: MoveEditDraft,
        changes: [MoveEditFileChange],
        diagnostics: [Diagnostic],
        mutationPlan: MutationPlan,
        backupRelativeRoot: String
    ) {
        self.id = id
        self.rootPath = rootPath
        self.moveID = moveID
        self.draft = draft
        self.changes = changes
        self.diagnostics = diagnostics
        self.mutationPlan = mutationPlan
        self.backupRelativeRoot = backupRelativeRoot
    }
}

public struct MoveEditApplyability: Codable, Equatable {
    public let isApplyable: Bool
    public let diagnostics: [Diagnostic]

    public init(isApplyable: Bool, diagnostics: [Diagnostic]) {
        self.isApplyable = isApplyable
        self.diagnostics = diagnostics
    }
}

public extension MoveEditPlan {
    var applyability: MoveEditApplyability {
        validateApplyability()
    }

    var isApplyable: Bool {
        applyability.isApplyable
    }

    func validateApplyability(fileManager: FileManager = .default) -> MoveEditApplyability {
        MoveEditApplySafety.applyability(for: self, fileManager: fileManager)
    }
}

public struct AppliedMoveFileChange: Codable, Equatable, Identifiable {
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

public struct MoveApplyResult: Codable, Equatable, Identifiable {
    public let id: String
    public let backupRootPath: String
    public let appliedChanges: [AppliedMoveFileChange]
    public let diagnostics: [Diagnostic]

    public init(id: String = UUID().uuidString, backupRootPath: String, appliedChanges: [AppliedMoveFileChange], diagnostics: [Diagnostic] = []) {
        self.id = id
        self.backupRootPath = backupRootPath
        self.appliedChanges = appliedChanges
        self.diagnostics = diagnostics
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
        diagnostics.append(contentsOf: expansionKnownFieldDiagnostics(root: root, profile: index.profile, fileManager: fileManager))

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
        let descriptionTexts = moveDescriptionTexts(root: root, profile: index.profile, fileManager: fileManager)

        let moves = moveRecords.compactMap { record -> MoveDetail? in
            let moveID = normalizedMoveID(record.title)
            guard moveID != "MOVE_NONE" else { return nil }
            let fullPreview = sourceEntryPreview(root: root, record: record, fileManager: fileManager) ?? record.preview
            let previewFields = fullPreview.map { MoveTopLevelFieldScanner.fields(in: $0) } ?? [:]
            let descriptionSymbol = expansionMoveDescriptionSymbol(profile: index.profile, fields: previewFields)
            let descriptionText = descriptionSymbol.flatMap { descriptionTexts[$0]?.text }
            let editDiagnostics = editabilityDiagnostics(record: record, profile: index.profile, preview: fullPreview)
            let moveDiagnostics = record.diagnostics + editDiagnostics + diagnostics.filter { $0.span == record.sourceSpan }
            return MoveDetail(
                moveID: moveID,
                displayName: displayName(forMoveID: moveID),
                ordinal: ordinal(from: record),
                sourceSpan: record.sourceSpan,
                sourcePreview: fullPreview,
                facts: record.facts,
                flags: flags(in: record.facts, preview: fullPreview),
                descriptionSymbol: descriptionSymbol,
                descriptionText: descriptionText,
                isDescriptionEditable: descriptionSymbol.flatMap { descriptionTexts[$0] } != nil
                    && index.profile == .pokeemeraldExpansion
                    && record.sourceSpan.relativePath == editableMoveSourcePath(for: index.profile),
                isEditable: moveDiagnostics.allSatisfy { $0.severity != .error },
                machineMemberships: machineByMove[moveID] ?? [],
                tutorMemberships: tutorByMove[moveID] ?? [],
                learnedBy: learnedByMove[moveID] ?? [],
                diagnostics: moveDiagnostics
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

    private static func flags(in facts: [SourceIndexFact], preview: String?) -> [String] {
        let factValue = facts.first(where: { $0.label == "flags" })?.value
        let previewValue = preview.flatMap { MoveTopLevelFieldScanner.fields(in: $0)["flags"]?.value }
        return simpleFlags(in: factValue ?? previewValue ?? "") ?? []
    }

    private static func editabilityDiagnostics(record: SourceIndexRecord, profile: GameProfile, preview: String?) -> [Diagnostic] {
        guard let expectedPath = editableMoveSourcePath(for: profile) else {
            return [
                Diagnostic(
                    severity: .error,
                    code: "MOVE_CATALOG_READ_ONLY_PROFILE",
                    message: "Move editing is currently available for classic Emerald/FireRed battle_moves.h rows, Ruby/Sapphire battle_moves.c rows, and local Expansion gMovesInfo rows.",
                    span: record.sourceSpan
                )
            ]
        }
        guard record.sourceSpan.relativePath == expectedPath else {
            return [
                Diagnostic(
                    severity: .error,
                    code: "MOVE_CATALOG_READ_ONLY_SOURCE",
                    message: "Move editing requires \(expectedPath) source for \(profile.rawValue).",
                    span: record.sourceSpan
                )
            ]
        }
        let fields = preview.map { MoveTopLevelFieldScanner.fields(in: $0) } ?? [:]
        let missing = requiredEditableMoveFields(for: profile).filter { fields[$0] == nil }
        if !missing.isEmpty {
            return [
                Diagnostic(
                    severity: .error,
                    code: "MOVE_CATALOG_EDIT_FIELDS_MISSING",
                    message: "\(record.title) is missing editable field(s): \(missing.joined(separator: ", ")).",
                    span: record.sourceSpan
                )
            ]
        }
        if let flags = fields["flags"], simpleFlags(in: flags.value) == nil {
            return [
                Diagnostic(
                    severity: .error,
                    code: "MOVE_CATALOG_FLAGS_UNSUPPORTED_EXPRESSION",
                    message: "\(record.title) uses a non-simple flags expression that cannot be round-tripped safely.",
                    span: record.sourceSpan
                )
            ]
        }
        return []
    }

    private static func moveDescriptionTexts(
        root: URL,
        profile: GameProfile,
        fileManager: FileManager
    ) -> [String: MoveDescriptionText] {
        guard profile == .pokeemeraldExpansion else { return [:] }
        let path = expansionMoveDescriptionSourcePath
        let url = root.appendingPathComponent(path)
        guard fileManager.fileExists(atPath: url.path), let text = try? moveReadText(at: url) else {
            return [:]
        }
        return MoveDescriptionScanner.descriptions(in: text, relativePath: path)
    }

    private static func sourceEntryPreview(root: URL, record: SourceIndexRecord, fileManager: FileManager) -> String? {
        let url = root.appendingPathComponent(record.sourceSpan.relativePath)
        guard
            fileManager.fileExists(atPath: url.path),
            let text = try? moveReadText(at: url)
        else {
            return nil
        }
        return moveSourceEntryText(in: text, span: record.sourceSpan)
    }

    private static func expansionKnownFieldDiagnostics(
        root: URL,
        profile: GameProfile,
        fileManager: FileManager
    ) -> [Diagnostic] {
        guard profile == .pokeemeraldExpansion else { return [] }
        let relativePath = "src/data/moves_info.h"
        let url = root.appendingPathComponent(relativePath)
        guard
            fileManager.fileExists(atPath: url.path),
            let text = try? moveReadText(at: url)
        else {
            return []
        }

        let parsed = CInitializerParser.tableEntries(
            in: text,
            descriptor: CInitializerTableDescriptor(
                module: .moves,
                relativePath: relativePath,
                tableSymbol: "gMovesInfo",
                entryStyle: .bracketed
            )
        )
        var diagnostics = parsed.diagnostics
        let knownFields = Set(expansionKnownMoveFields)
        for entry in parsed.entries {
            let unknownFields = entry.fields.keys
                .filter { !knownFields.contains($0) }
                .sorted()
            diagnostics.append(contentsOf: unknownFields.map { field in
                Diagnostic(
                    severity: .warning,
                    code: "MOVE_CATALOG_UNKNOWN_FIELD",
                    message: "\(entry.symbol) has unknown Expansion gMovesInfo field \(field); preserving it as raw source while simple move fields remain editable.",
                    span: entry.span
                )
            })
        }
        return diagnostics
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

    private static func expansionMoveDescriptionSymbol(profile: GameProfile, fields: [String: MoveFieldSlice]) -> String? {
        guard profile == .pokeemeraldExpansion, let value = fields["description"]?.value else { return nil }
        let compacted = compactMoveValue(value)
        return isMoveDescriptionSymbol(compacted) ? compacted : nil
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

public enum MoveMutationPlanner {
    public static func plan(
        catalog: ProjectMoveCatalog,
        draft: MoveEditDraft,
        fileManager: FileManager = .default
    ) -> MoveEditPlan {
        let root = URL(fileURLWithPath: catalog.root.path).standardizedFileURL
        guard editableMoveSourcePath(for: catalog.profile) != nil else {
            return blockedPlan(
                catalog: catalog,
                draft: draft,
                diagnostics: [
                    Diagnostic(severity: .error, code: "MOVE_PLAN_UNSUPPORTED_PROFILE", message: "Move apply is available for classic Emerald/FireRed battle_moves.h source trees, Ruby/Sapphire battle_moves.c source trees, and local Expansion gMovesInfo rows.")
                ]
            )
        }
        guard draft.moveID != "MOVE_NONE" else {
            return blockedPlan(
                catalog: catalog,
                draft: draft,
                diagnostics: [
                    Diagnostic(severity: .error, code: "MOVE_PLAN_SENTINEL_UNSUPPORTED", message: "MOVE_NONE is a sentinel and cannot be edited.")
                ]
            )
        }
        guard let move = catalog.moves.first(where: { $0.moveID == draft.moveID }) else {
            return blockedPlan(
                catalog: catalog,
                draft: draft,
                diagnostics: [
                    Diagnostic(severity: .error, code: "MOVE_PLAN_TARGET_MISSING", message: "Move \(draft.moveID) is not in the current catalog.")
                ]
            )
        }

        var diagnostics = plannerDiagnostics(profile: catalog.profile, move: move, draft: draft)
        var changes: [MoveEditFileChange] = []

        if diagnostics.allSatisfy({ $0.severity != .error }) {
            let rewrite = rewriteChange(root: root, profile: catalog.profile, move: move, draft: draft)
            diagnostics.append(contentsOf: rewrite.diagnostics)
            if let change = rewrite.change {
                changes.append(change)
            }
            if diagnostics.allSatisfy({ $0.severity != .error }) {
                let descriptionRewrite = rewriteDescriptionChange(root: root, profile: catalog.profile, move: move, draft: draft)
                diagnostics.append(contentsOf: descriptionRewrite.diagnostics)
                if let change = descriptionRewrite.change {
                    changes.append(change)
                }
            }
        }
        if changes.isEmpty, diagnostics.allSatisfy({ $0.severity != .error }) {
            diagnostics.append(Diagnostic(severity: .warning, code: "MOVE_PLAN_NO_CHANGES", message: "No move source changes are staged.", span: move.sourceSpan))
        }

        let plannedChanges = changes.map {
            PlannedChange(path: $0.path, summary: $0.summary, span: SourceSpan(relativePath: $0.path, startLine: 1))
        }
        let mutationPlan = MutationPlan(
            title: "Apply move edits to \(draft.moveID)",
            summary: "\(changes.count) source file change(s) for move data.",
            changes: plannedChanges,
            diagnostics: diagnostics,
            requiresExplicitApply: true
        )
        return MoveEditPlan(
            rootPath: catalog.root.path,
            moveID: draft.moveID,
            draft: draft,
            changes: changes,
            diagnostics: diagnostics,
            mutationPlan: mutationPlan,
            backupRelativeRoot: ".pokemonhackstudio/backups/\(backupTimestamp())"
        )
    }

    private static func blockedPlan(catalog: ProjectMoveCatalog, draft: MoveEditDraft, diagnostics: [Diagnostic]) -> MoveEditPlan {
        let mutationPlan = MutationPlan(
            title: "Move edits blocked for \(draft.moveID)",
            summary: "No source files are applyable until diagnostics are resolved.",
            diagnostics: diagnostics,
            requiresExplicitApply: true
        )
        return MoveEditPlan(
            rootPath: catalog.root.path,
            moveID: draft.moveID,
            draft: draft,
            changes: [],
            diagnostics: diagnostics,
            mutationPlan: mutationPlan,
            backupRelativeRoot: ".pokemonhackstudio/backups/\(backupTimestamp())"
        )
    }

    private static func plannerDiagnostics(profile: GameProfile, move: MoveDetail, draft: MoveEditDraft) -> [Diagnostic] {
        var diagnostics = move.diagnostics.filter { $0.severity == .error }
        if move.diagnostics.contains(where: { $0.code == "MOVE_CATALOG_FLAGS_UNSUPPORTED_EXPRESSION" }) {
            diagnostics.append(Diagnostic(severity: .error, code: "MOVE_FLAGS_UNSUPPORTED_EXPRESSION", message: "\(move.moveID) uses a non-simple flags expression that cannot be round-tripped safely.", span: move.sourceSpan))
        }
        if let expectedPath = editableMoveSourcePath(for: profile), move.sourceSpan.relativePath != expectedPath {
            diagnostics.append(Diagnostic(severity: .error, code: "MOVE_SOURCE_UNSUPPORTED", message: "\(move.moveID) is not backed by \(expectedPath) source for \(profile.rawValue).", span: move.sourceSpan))
        }
        if
            let preview = move.sourcePreview,
            let flags = MoveTopLevelFieldScanner.fields(in: preview)["flags"],
            simpleFlags(in: flags.value) == nil
        {
            diagnostics.append(Diagnostic(severity: .error, code: "MOVE_FLAGS_UNSUPPORTED_EXPRESSION", message: "\(move.moveID) uses a non-simple flags expression that cannot be round-tripped safely.", span: move.sourceSpan))
        }
        appendRangeDiagnostics(move: move, draft: draft, diagnostics: &diagnostics)
        appendSymbolDiagnostics(move: move, draft: draft, diagnostics: &diagnostics)
        if let draftDescription = draft.descriptionText,
           draftDescription != move.descriptionText,
           !move.isDescriptionEditable
        {
            diagnostics.append(Diagnostic(severity: .error, code: "MOVE_DESCRIPTION_NOT_EDITABLE", message: "\(move.moveID) does not have a source-backed Expansion move description declaration that can be rewritten.", span: move.sourceSpan))
        }
        return diagnostics
    }

    private static func appendRangeDiagnostics(move: MoveDetail, draft: MoveEditDraft, diagnostics: inout [Diagnostic]) {
        let unsignedByteFields = [
            ("power", draft.power),
            ("pp", draft.pp)
        ]
        for (label, value) in unsignedByteFields where !(0...255).contains(value) {
            diagnostics.append(Diagnostic(severity: .error, code: "MOVE_NUMERIC_RANGE_INVALID", message: "\(label) must be between 0 and 255.", span: move.sourceSpan))
        }
        let percentageFields = [
            ("accuracy", draft.accuracy),
            ("secondaryEffectChance", draft.secondaryEffectChance)
        ]
        for (label, value) in percentageFields where !(0...100).contains(value) {
            diagnostics.append(Diagnostic(severity: .error, code: "MOVE_NUMERIC_RANGE_INVALID", message: "\(label) must be between 0 and 100.", span: move.sourceSpan))
        }
        if !(-128...127).contains(draft.priority) {
            diagnostics.append(Diagnostic(severity: .error, code: "MOVE_NUMERIC_RANGE_INVALID", message: "priority must be between -128 and 127.", span: move.sourceSpan))
        }
    }

    private static func appendSymbolDiagnostics(move: MoveDetail, draft: MoveEditDraft, diagnostics: inout [Diagnostic]) {
        let symbols = [
            ("effect", draft.effect),
            ("type", draft.type),
            ("target", draft.target)
        ]
        for (label, symbol) in symbols where !isSimpleSymbol(symbol) {
            diagnostics.append(Diagnostic(severity: .error, code: "MOVE_SYMBOL_INVALID", message: "\(label) must be a single C constant symbol.", span: move.sourceSpan))
        }
        for flag in draft.flags where !isFlagToken(flag) {
            diagnostics.append(Diagnostic(severity: .error, code: "MOVE_FLAG_INVALID", message: "\(flag) is not a simple FLAG_* token.", span: move.sourceSpan))
        }
    }

    private static func rewriteChange(root: URL, profile: GameProfile, move: MoveDetail, draft: MoveEditDraft) -> (change: MoveEditFileChange?, diagnostics: [Diagnostic]) {
        let path = move.sourceSpan.relativePath
        let url = root.appendingPathComponent(path)
        guard let originalText = try? moveReadText(at: url), let originalData = originalText.data(using: .utf8) else {
            return (
                nil,
                [Diagnostic(severity: .error, code: "MOVE_SOURCE_MISSING", message: "Move source file is missing or unreadable: \(path).", span: move.sourceSpan)]
            )
        }

        let entryText = moveSourceEntryText(in: originalText, span: move.sourceSpan)
        let fields = MoveTopLevelFieldScanner.fields(in: entryText)
        var diagnostics = missingFieldDiagnostics(profile: profile, move: move, fields: fields)
        if let flags = fields["flags"], simpleFlags(in: flags.value) == nil {
            diagnostics.append(Diagnostic(severity: .error, code: "MOVE_FLAGS_UNSUPPORTED_EXPRESSION", message: "\(move.moveID) uses a non-simple flags expression that cannot be round-tripped safely.", span: move.sourceSpan))
        }
        guard diagnostics.allSatisfy({ $0.severity != .error }) else {
            return (nil, diagnostics)
        }

        var replacements: [(field: MoveFieldSlice, value: String)] = []
        appendReplacement(field: "effect", newValue: draft.effect, fields: fields, replacements: &replacements)
        appendNumericReplacement(field: "power", newValue: draft.power, fields: fields, replacements: &replacements)
        appendReplacement(field: "type", newValue: draft.type, fields: fields, replacements: &replacements)
        appendNumericReplacement(field: "accuracy", newValue: draft.accuracy, fields: fields, replacements: &replacements)
        appendNumericReplacement(field: "pp", newValue: draft.pp, fields: fields, replacements: &replacements)
        appendNumericReplacement(field: "secondaryEffectChance", newValue: draft.secondaryEffectChance, fields: fields, replacements: &replacements)
        appendReplacement(field: "target", newValue: draft.target, fields: fields, replacements: &replacements)
        appendNumericReplacement(field: "priority", newValue: draft.priority, fields: fields, replacements: &replacements)
        appendFlagsReplacement(newFlags: draft.flags, fields: fields, replacements: &replacements)

        guard !replacements.isEmpty else { return (nil, []) }
        var replacementEntry = entryText
        for replacement in replacements.sorted(by: { $0.field.valueRange.lowerBound > $1.field.valueRange.lowerBound }) {
            replacementEntry.replaceSubrange(replacement.field.valueRange, with: replacement.value)
        }

        let newText = moveReplaceLines(in: originalText, span: move.sourceSpan, replacement: replacementEntry)
        guard newText != originalText, let newData = newText.data(using: .utf8) else { return (nil, []) }
        return (
            MoveEditFileChange(
                path: path,
                summary: "Update move source fields",
                originalByteCount: originalData.count,
                originalSHA1: pokemonHackSHA1Hex(originalData),
                newByteCount: newData.count,
                newData: newData,
                textPreview: replacementEntry
            ),
            []
        )
    }

    private static func rewriteDescriptionChange(root: URL, profile: GameProfile, move: MoveDetail, draft: MoveEditDraft) -> (change: MoveEditFileChange?, diagnostics: [Diagnostic]) {
        guard profile == .pokeemeraldExpansion else { return (nil, []) }
        guard let draftText = draft.descriptionText, draftText != move.descriptionText else { return (nil, []) }
        guard let symbol = move.descriptionSymbol else {
            return (
                nil,
                [Diagnostic(severity: .error, code: "MOVE_DESCRIPTION_SOURCE_MISSING", message: "\(move.moveID) does not have a description symbol that can be rewritten.", span: move.sourceSpan)]
            )
        }

        let path = expansionMoveDescriptionSourcePath
        let url = root.appendingPathComponent(path)
        guard let originalText = try? moveReadText(at: url), let originalData = originalText.data(using: .utf8) else {
            return (
                nil,
                [Diagnostic(severity: .error, code: "MOVE_DESCRIPTION_SOURCE_UNREADABLE", message: "Move description source file could not be read before planning: \(path).", span: SourceSpan(relativePath: path, startLine: 1))]
            )
        }
        guard let description = MoveDescriptionScanner.descriptions(in: originalText, relativePath: path)[symbol] else {
            return (
                nil,
                [Diagnostic(severity: .error, code: "MOVE_DESCRIPTION_SYMBOL_MISSING", message: "Description symbol \(symbol) was not found in \(path).", span: SourceSpan(relativePath: path, startLine: 1))]
            )
        }

        let replacement = renderMoveDescriptionDeclaration(symbol: symbol, text: draftText, usesStatic: description.usesStatic)
        let mutableText = NSMutableString(string: originalText)
        mutableText.replaceCharacters(
            in: NSRange(location: description.startOffset, length: description.endOffset - description.startOffset),
            with: replacement
        )
        let newText = mutableText as String
        guard newText != originalText, let newData = newText.data(using: .utf8) else { return (nil, []) }
        return (
            MoveEditFileChange(
                path: path,
                summary: "Update move description text",
                originalByteCount: originalData.count,
                originalSHA1: pokemonHackSHA1Hex(originalData),
                newByteCount: newData.count,
                newData: newData,
                textPreview: replacement
            ),
            []
        )
    }

    private static func missingFieldDiagnostics(profile: GameProfile, move: MoveDetail, fields: [String: MoveFieldSlice]) -> [Diagnostic] {
        requiredEditableMoveFields(for: profile).compactMap { field in
            guard fields[field] == nil else { return nil }
            return Diagnostic(severity: .error, code: "MOVE_SOURCE_FIELD_MISSING", message: "\(move.moveID) is missing editable field \(field).", span: move.sourceSpan)
        }
    }

    private static func appendReplacement(
        field: String,
        newValue: String,
        fields: [String: MoveFieldSlice],
        replacements: inout [(field: MoveFieldSlice, value: String)]
    ) {
        guard let slice = fields[field] else { return }
        let rendered = compactMoveValue(newValue)
        if compactMoveValue(slice.value) != rendered {
            replacements.append((slice, rendered))
        }
    }

    private static func appendNumericReplacement(
        field: String,
        newValue: Int,
        fields: [String: MoveFieldSlice],
        replacements: inout [(field: MoveFieldSlice, value: String)]
    ) {
        guard let slice = fields[field] else { return }
        let rendered = "\(newValue)"
        if Int(compactMoveValue(slice.value)) != newValue {
            replacements.append((slice, rendered))
        }
    }

    private static func appendFlagsReplacement(
        newFlags: [String],
        fields: [String: MoveFieldSlice],
        replacements: inout [(field: MoveFieldSlice, value: String)]
    ) {
        guard let slice = fields["flags"], let originalFlags = simpleFlags(in: slice.value) else { return }
        let normalized = normalizedFlags(newFlags)
        if originalFlags != normalized {
            replacements.append((slice, renderFlags(normalized)))
        }
    }

    private static func backupTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "\(formatter.string(from: Date()))-\(UUID().uuidString.prefix(8))"
    }
}

public enum MoveMutationApplier {
    public static func apply(plan: MoveEditPlan, fileManager: FileManager = .default) throws -> MoveApplyResult {
        let root = URL(fileURLWithPath: plan.rootPath).standardizedFileURL
        let backupRoot = root.appendingPathComponent(plan.backupRelativeRoot)
        let applyability = plan.validateApplyability(fileManager: fileManager)
        guard applyability.isApplyable else {
            return MoveApplyResult(backupRootPath: backupRoot.path, appliedChanges: [], diagnostics: applyability.diagnostics)
        }
        guard !plan.changes.isEmpty else {
            return MoveApplyResult(backupRootPath: backupRoot.path, appliedChanges: [])
        }
        let backupDiagnostics = SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
            plan.backupRelativeRoot,
            root: root,
            fileManager: fileManager,
            codePrefix: "MOVE_APPLY_BACKUP",
            subject: "Move backup path"
        )
        guard backupDiagnostics.isEmpty else {
            return MoveApplyResult(backupRootPath: backupRoot.path, appliedChanges: [], diagnostics: backupDiagnostics)
        }

        try fileManager.createDirectory(at: backupRoot, withIntermediateDirectories: true)
        var applied: [AppliedMoveFileChange] = []
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
            applied.append(AppliedMoveFileChange(path: change.path, backupPath: backup.path, byteCount: change.newData.count))
        }
        return MoveApplyResult(backupRootPath: backupRoot.path, appliedChanges: applied)
    }
}

private enum MoveEditApplySafety {
    static func applyability(for plan: MoveEditPlan, fileManager: FileManager) -> MoveEditApplyability {
        var diagnostics = plan.diagnostics.filter { $0.severity == .error }
        let root = URL(fileURLWithPath: plan.rootPath).standardizedFileURL
        guard !plan.rootPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            diagnostics.append(Diagnostic(severity: .error, code: "MOVE_APPLY_ROOT_MISSING", message: "Move apply root path is missing."))
            return MoveEditApplyability(isApplyable: false, diagnostics: diagnostics)
        }
        guard fileManager.fileExists(atPath: root.path) else {
            diagnostics.append(Diagnostic(severity: .error, code: "MOVE_APPLY_ROOT_MISSING", message: "Move apply root does not exist: \(plan.rootPath)."))
            return MoveEditApplyability(isApplyable: false, diagnostics: diagnostics)
        }
        guard !plan.changes.isEmpty else {
            diagnostics.append(Diagnostic(severity: .warning, code: "MOVE_APPLY_NO_CHANGES", message: "No move source changes are staged."))
            return MoveEditApplyability(isApplyable: false, diagnostics: diagnostics)
        }
        for change in plan.changes {
            diagnostics.append(contentsOf: diagnosticsForChange(change, root: root, fileManager: fileManager))
        }
        return MoveEditApplyability(isApplyable: diagnostics.allSatisfy { $0.severity != .error }, diagnostics: diagnostics)
    }

    private static func diagnosticsForChange(_ change: MoveEditFileChange, root: URL, fileManager: FileManager) -> [Diagnostic] {
        let destination = root.appendingPathComponent(change.path).standardizedFileURL
        let pathDiagnostics = SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
            change.path,
            root: root,
            fileManager: fileManager,
            codePrefix: "MOVE_APPLY",
            subject: "Move apply path"
        )
        guard pathDiagnostics.isEmpty else {
            return pathDiagnostics
        }
        guard fileManager.fileExists(atPath: destination.path) else {
            return [pathDiagnostic("MOVE_APPLY_SOURCE_MISSING", "Move source file is missing before apply: \(change.path).", path: change.path)]
        }
        guard let currentData = try? Data(contentsOf: destination) else {
            return [pathDiagnostic("MOVE_APPLY_SOURCE_UNREADABLE", "Move source file could not be read before apply: \(change.path).", path: change.path)]
        }
        guard currentData.count == change.originalByteCount else {
            return [pathDiagnostic("MOVE_APPLY_ORIGINAL_SIZE_MISMATCH", "Move source file changed since planning: \(change.path).", path: change.path)]
        }
        if let originalSHA1 = change.originalSHA1, pokemonHackSHA1Hex(currentData) != originalSHA1 {
            return [pathDiagnostic("MOVE_APPLY_ORIGINAL_HASH_MISMATCH", "Move source file contents changed since planning: \(change.path).", path: change.path)]
        }
        return []
    }

    private static func pathDiagnostic(_ code: String, _ message: String, path: String) -> Diagnostic {
        Diagnostic(severity: .error, code: code, message: message, span: SourceSpan(relativePath: path, startLine: 1))
    }
}

private func editableMoveSourcePath(for profile: GameProfile) -> String? {
    switch profile {
    case .pokeemerald, .pokefirered:
        return "src/data/battle_moves.h"
    case .pokeruby:
        return "src/data/battle_moves.c"
    case .pokeemeraldExpansion:
        return "src/data/moves_info.h"
    default:
        return nil
    }
}

private func requiredEditableMoveFields(for profile: GameProfile) -> [String] {
    switch profile {
    case .pokeemeraldExpansion:
        return editableMoveFields.filter { $0 != "secondaryEffectChance" && $0 != "flags" }
    default:
        return editableMoveFields
    }
}

private let editableMoveFields = [
    "effect", "power", "type", "accuracy", "pp",
    "secondaryEffectChance", "target", "priority", "flags"
]

private let expansionKnownMoveFields = editableMoveFields + [
    "absorbPercentage", "accIncreaseByTenOnSameType", "accuracy50InSun",
    "additionalEffects", "alwaysCriticalHit", "alwaysHitsInHailSnow",
    "alwaysHitsInRain", "alwaysHitsOnSameType", "argument", "assistBanned",
    "ballisticMove", "battleAnimScript", "bitingMove", "cantUseTwice",
    "category", "chance", "contestAppeal", "contestCategory",
    "contestComboMoves", "contestComboStarterId", "contestEffect",
    "contestJam", "copycatBanned", "criticalHitStage", "damageCategories",
    "damagePercent", "damagePercentage", "damagesAirborne",
    "damagesAirborneDoubleDamage", "damagesUnderground", "damagesUnderwater",
    "dampBanned", "danceMove", "description", "encoreBanned", "explosion",
    "fixedDamage", "forcePressure", "gravityBanned", "groundCheck",
    "healingMove", "hitsBothFoes", "holdEffect",
    "ignoreTypeIfFlyingAndUngrounded", "ignoresKingsRock", "ignoresProtect",
    "ignoresSubstitute", "ignoresTargetAbility",
    "ignoresTargetDefenseEvasionStages", "instructBanned", "magicCoatAffected",
    "makesContact", "maxMovePower", "meFirstBanned", "metronomeBanned",
    "mimicBanned", "minimizeDoubleDamage", "mirrorMoveBanned", "moveEffect",
    "moveProperty", "multiHit", "name", "noAffectOnSameTypeTarget",
    "nonVolatileStatus", "numOfHits", "onChargeTurnOnly",
    "onlyIfTargetRaisedStats", "overwriteAbility", "parentalBondBanned",
    "percent", "powderMove", "powerOverride", "preAttackEffect",
    "protectMethod", "pulseMove", "punchingMove", "recoilPercentage", "self",
    "sheerForceOverride", "sketchBanned", "skyBattleBanned", "sleepTalkBanned",
    "slicingMove", "snatchAffected", "soundMove", "species", "split",
    "status", "strikeCount", "stringId", "terrain", "terrainBoost",
    "thawsUser", "twoTurnAttack", "validApprenticeMove", "weather",
    "weatherType", "windMove", "wrapped", "zMove", "zMoveEffect",
    "zMovePower"
]

private let expansionMoveDescriptionSourcePath = "src/data/text/move_descriptions.h"

private struct MoveFieldSlice {
    let name: String
    let value: String
    let valueRange: Range<String.Index>
}

private enum MoveTopLevelFieldScanner {
    static func fields(in text: String) -> [String: MoveFieldSlice] {
        guard let open = firstOpenBrace(in: text) else {
            return [:]
        }
        let close = matchingCloseBrace(from: open, in: text) ?? text.endIndex

        var fields: [String: MoveFieldSlice] = [:]
        var index = text.index(after: open)
        var depth = 0
        var state = MoveScannerState.normal
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

    private static func fieldSlice(startingAt dot: String.Index, close: String.Index, in text: String) -> MoveFieldSlice? {
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
        return MoveFieldSlice(name: name, value: String(text[range]), valueRange: range)
    }

    private static func valueEnd(start: String.Index, close: String.Index, in text: String) -> String.Index {
        var index = start
        var depth = 0
        var state = MoveScannerState.normal
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
                        break
                    }
                    depth -= 1
                } else if character == "," && depth == 0 {
                    break
                }
            }
            index = text.index(after: index)
        }
        return index
    }

    private static func firstOpenBrace(in text: String) -> String.Index? {
        var index = text.startIndex
        var state = MoveScannerState.normal
        while index < text.endIndex {
            let character = text[index]
            if consumeScannerState(&state, text: text, index: &index) {
                continue
            }
            if state == .normal, character == "{" {
                return index
            }
            index = text.index(after: index)
        }
        return nil
    }

    private static func matchingCloseBrace(from open: String.Index, in text: String) -> String.Index? {
        var index = open
        var depth = 0
        var state = MoveScannerState.normal
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

    private static func consumeScannerState(_ state: inout MoveScannerState, text: String, index: inout String.Index) -> Bool {
        let character = text[index]
        let next = text.index(after: index)
        let nextCharacter = next < text.endIndex ? text[next] : nil
        switch state {
        case .normal:
            if character == "/", nextCharacter == "/" {
                state = .lineComment
                index = next < text.endIndex ? text.index(after: next) : next
                return true
            }
            if character == "/", nextCharacter == "*" {
                state = .blockComment
                index = next < text.endIndex ? text.index(after: next) : next
                return true
            }
            if character == "\"" {
                state = .string
                index = text.index(after: index)
                return true
            }
            if character == "'" {
                state = .character
                index = text.index(after: index)
                return true
            }
            return false
        case .lineComment:
            if character == "\n" {
                state = .normal
            }
            index = text.index(after: index)
            return true
        case .blockComment:
            if character == "*", nextCharacter == "/" {
                state = .normal
                index = next < text.endIndex ? text.index(after: next) : next
            } else {
                index = text.index(after: index)
            }
            return true
        case .string:
            if character == "\\" {
                index = next < text.endIndex ? text.index(after: next) : next
            } else {
                if character == "\"" {
                    state = .normal
                }
                index = text.index(after: index)
            }
            return true
        case .character:
            if character == "\\" {
                index = next < text.endIndex ? text.index(after: next) : next
            } else {
                if character == "'" {
                    state = .normal
                }
                index = text.index(after: index)
            }
            return true
        }
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
        while lower < upper {
            let previous = text.index(before: upper)
            guard text[previous].isWhitespace else { break }
            upper = previous
        }
        return lower..<upper
    }

    private static func isIdentifier(_ character: Character) -> Bool {
        character == "_" || character.isLetter || character.isNumber
    }
}

private enum MoveScannerState {
    case normal
    case lineComment
    case blockComment
    case string
    case character
}

private struct MoveDescriptionText {
    let symbol: String
    let text: String
    let span: SourceSpan
    let startOffset: Int
    let endOffset: Int
    let usesStatic: Bool
}

private enum MoveDescriptionScanner {
    static func descriptions(in text: String, relativePath: String) -> [String: MoveDescriptionText] {
        let pattern = #"(static\s+)?const\s+u8\s+([A-Za-z_][A-Za-z0-9_]*)\[\]\s*=\s*_\(\s*((?:"(?:\\.|[^"])*"\s*)+)\);"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return [:]
        }
        let nsText = text as NSString
        var result: [String: MoveDescriptionText] = [:]
        for match in regex.matches(in: text, range: NSRange(location: 0, length: nsText.length)) {
            guard match.numberOfRanges >= 4 else { continue }
            let symbol = nsText.substring(with: match.range(at: 2))
            let literalBlock = nsText.substring(with: match.range(at: 3))
            let description = quotedStrings(in: literalBlock)
                .map(unescapeMoveCString)
                .joined(separator: "\n")
            let fullRange = match.range(at: 0)
            result[symbol] = MoveDescriptionText(
                symbol: symbol,
                text: description,
                span: SourceSpan(
                    relativePath: relativePath,
                    startLine: moveLineNumber(forUTF16Offset: fullRange.location, in: text),
                    endLine: moveLineNumber(forUTF16Offset: fullRange.location + fullRange.length, in: text)
                ),
                startOffset: fullRange.location,
                endOffset: fullRange.location + fullRange.length,
                usesStatic: match.range(at: 1).location != NSNotFound
            )
        }
        return result
    }

    private static func quotedStrings(in text: String) -> [String] {
        let characters = Array(text)
        var strings: [String] = []
        var index = 0
        while index < characters.count {
            guard characters[index] == "\"" else {
                index += 1
                continue
            }
            index += 1
            var value = ""
            while index < characters.count {
                let character = characters[index]
                if character == "\\" {
                    value.append(character)
                    index += 1
                    if index < characters.count {
                        value.append(characters[index])
                    }
                } else if character == "\"" {
                    break
                } else {
                    value.append(character)
                }
                index += 1
            }
            strings.append(value.trimmingCharacters(in: .whitespacesAndNewlines))
            index += 1
        }
        return strings
    }
}

private func simpleFlags(in value: String) -> [String]? {
    let compact = compactMoveValue(value)
    guard !compact.isEmpty else { return [] }
    if compact == "0" { return [] }
    let parts = compact.split(separator: "|").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    guard !parts.isEmpty, parts.allSatisfy({ isFlagToken($0) }) else { return nil }
    return normalizedFlags(parts)
}

private func normalizedFlags(_ flags: [String]) -> [String] {
    var seen: Set<String> = []
    var result: [String] = []
    for flag in flags.map(compactMoveValue).filter({ !$0.isEmpty }) where seen.insert(flag).inserted {
        result.append(flag)
    }
    return result.sorted()
}

private func renderFlags(_ flags: [String]) -> String {
    flags.isEmpty ? "0" : flags.joined(separator: " | ")
}

private func isFlagToken(_ value: String) -> Bool {
    value.range(of: #"^FLAG_[A-Z0-9_]+$"#, options: .regularExpression) != nil
}

private func isSimpleSymbol(_ value: String) -> Bool {
    value.range(of: #"^[A-Z_][A-Z0-9_]*$"#, options: .regularExpression) != nil
}

private func isMoveDescriptionSymbol(_ value: String) -> Bool {
    value.range(of: #"^[A-Za-z_][A-Za-z0-9_]*$"#, options: .regularExpression) != nil
}

private func compactMoveValue(_ value: String) -> String {
    value.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private func moveReadText(at url: URL) throws -> String {
    if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
        return utf8
    }
    return try String(contentsOf: url, encoding: .isoLatin1)
}

private func moveSourceEntryText(in text: String, span: SourceSpan) -> String {
    let lines = text.components(separatedBy: "\n")
    guard !lines.isEmpty else { return "" }
    let start = max(0, span.startLine - 1)
    let end = min(max(start, span.endLine - 1), max(0, lines.count - 1))
    guard start <= end, start < lines.count else { return "" }
    return lines[start...end].joined(separator: "\n")
}

private func moveReplaceLines(in text: String, span: SourceSpan, replacement: String) -> String {
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

private func renderMoveDescriptionDeclaration(symbol: String, text: String, usesStatic: Bool) -> String {
    let prefix = usesStatic ? "static const u8" : "const u8"
    let lines = text.components(separatedBy: "\n")
    if lines.count <= 1 {
        return "\(prefix) \(symbol)[] = _(\"" + escapeMoveCString(text) + "\");"
    }
    let body = lines
        .map { "    \"\(escapeMoveCString($0))\"" }
        .joined(separator: "\n")
    return "\(prefix) \(symbol)[] = _(\n\(body));"
}

private func escapeMoveCString(_ value: String) -> String {
    value
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: "\\n")
}

private func unescapeMoveCString(_ value: String) -> String {
    var result = ""
    var iterator = value.makeIterator()
    while let character = iterator.next() {
        if character == "\\", let escaped = iterator.next() {
            switch escaped {
            case "n": result.append("\n")
            case "t": result.append("\t")
            case "\"": result.append("\"")
            case "\\": result.append("\\")
            default:
                result.append(escaped)
            }
        } else {
            result.append(character)
        }
    }
    return result
}

private func moveLineNumber(forUTF16Offset offset: Int, in text: String) -> Int {
    let clamped = max(0, min(offset, (text as NSString).length))
    let prefix = (text as NSString).substring(to: clamped)
    return prefix.reduce(1) { count, character in
        character == "\n" ? count + 1 : count
    }
}
