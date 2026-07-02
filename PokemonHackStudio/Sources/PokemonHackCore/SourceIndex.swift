import Foundation

public enum SourceIndexModule: String, Codable, Equatable, CaseIterable {
    case scripts
    case text
    case pokemon
    case trainers
    case items
    case moves
    case learnsets
    case evolutions
    case pokedex
    case encounters
}

public struct SourceIndexFact: Codable, Equatable, Identifiable {
    public var id: String { label }

    public let label: String
    public let value: String

    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}

public struct SourceIndexRecord: Codable, Equatable, Identifiable {
    public let id: String
    public let module: SourceIndexModule
    public let title: String
    public let subtitle: String
    public let sourceSpan: SourceSpan
    public let tags: [String]
    public let facts: [SourceIndexFact]
    public let preview: String?
    public let diagnostics: [Diagnostic]

    public init(
        id: String,
        module: SourceIndexModule,
        title: String,
        subtitle: String,
        sourceSpan: SourceSpan,
        tags: [String] = [],
        facts: [SourceIndexFact] = [],
        preview: String? = nil,
        diagnostics: [Diagnostic] = []
    ) {
        self.id = id
        self.module = module
        self.title = title
        self.subtitle = subtitle
        self.sourceSpan = sourceSpan
        self.tags = tags
        self.facts = facts
        self.preview = preview
        self.diagnostics = diagnostics
    }
}

public struct ProjectSourceIndex: Codable, Equatable {
    public let root: SourceLocation
    public let profile: GameProfile
    public let adapterID: String
    public let adapterName: String
    public let records: [SourceIndexRecord]
    public let diagnostics: [Diagnostic]

    public init(
        root: SourceLocation,
        profile: GameProfile,
        adapterID: String,
        adapterName: String,
        records: [SourceIndexRecord],
        diagnostics: [Diagnostic] = []
    ) {
        self.root = root
        self.profile = profile
        self.adapterID = adapterID
        self.adapterName = adapterName
        self.records = records
        self.diagnostics = diagnostics
    }
}

public struct PokemonLearnablesCoverage: Codable, Equatable, Sendable {
    public let generatedSpeciesCount: Int
    public let parsedSourceSpeciesCount: Int
    public let matchingSpeciesCount: Int
    public let mismatchSpeciesCount: Int
    public let generatedOnlySpeciesCount: Int
    public let sourceOnlySpeciesCount: Int
    public let moveMismatchSpeciesCount: Int
    public let staleSourceFileCount: Int
    public let newestStaleSourcePath: String?
    public let staleSourcePaths: [String]
    public let disagreements: [PokemonLearnablesCoverageDisagreement]
    public let regenerationPlan: PokemonLearnablesRegenerationPlan?

    public init(
        generatedSpeciesCount: Int,
        parsedSourceSpeciesCount: Int,
        matchingSpeciesCount: Int,
        mismatchSpeciesCount: Int,
        generatedOnlySpeciesCount: Int,
        sourceOnlySpeciesCount: Int,
        moveMismatchSpeciesCount: Int,
        staleSourceFileCount: Int,
        newestStaleSourcePath: String? = nil,
        staleSourcePaths: [String] = [],
        disagreements: [PokemonLearnablesCoverageDisagreement] = [],
        regenerationPlan: PokemonLearnablesRegenerationPlan? = nil
    ) {
        self.generatedSpeciesCount = generatedSpeciesCount
        self.parsedSourceSpeciesCount = parsedSourceSpeciesCount
        self.matchingSpeciesCount = matchingSpeciesCount
        self.mismatchSpeciesCount = mismatchSpeciesCount
        self.generatedOnlySpeciesCount = generatedOnlySpeciesCount
        self.sourceOnlySpeciesCount = sourceOnlySpeciesCount
        self.moveMismatchSpeciesCount = moveMismatchSpeciesCount
        self.staleSourceFileCount = staleSourceFileCount
        self.newestStaleSourcePath = newestStaleSourcePath
        self.staleSourcePaths = staleSourcePaths
        self.disagreements = disagreements
        self.regenerationPlan = regenerationPlan
    }
}

public struct PokemonLearnablesSourceBucketPaths: Codable, Equatable, Sendable {
    public let bucket: String
    public let paths: [String]

    public init(bucket: String, paths: [String]) {
        self.bucket = bucket
        self.paths = paths
    }
}

public struct PokemonLearnablesRegenerationPlan: Codable, Equatable, Sendable {
    public let posture: String
    public let generatedPath: String
    public let sourceBuckets: [String]
    public let bucketPaths: [PokemonLearnablesSourceBucketPaths]
    public let generatedOnlyMoveIDs: [String]
    public let sourceOnlyMoveIDs: [String]
    public let reviewItems: [PokemonLearnablesCoverageDisagreement]
    public let reportCommands: [String]
    public let reviewGuidance: String

    public init(
        posture: String,
        generatedPath: String,
        sourceBuckets: [String],
        bucketPaths: [PokemonLearnablesSourceBucketPaths],
        generatedOnlyMoveIDs: [String],
        sourceOnlyMoveIDs: [String],
        reviewItems: [PokemonLearnablesCoverageDisagreement],
        reportCommands: [String],
        reviewGuidance: String
    ) {
        self.posture = posture
        self.generatedPath = generatedPath
        self.sourceBuckets = sourceBuckets
        self.bucketPaths = bucketPaths
        self.generatedOnlyMoveIDs = generatedOnlyMoveIDs
        self.sourceOnlyMoveIDs = sourceOnlyMoveIDs
        self.reviewItems = reviewItems
        self.reportCommands = reportCommands
        self.reviewGuidance = reviewGuidance
    }
}

public enum PokemonLearnablesCoverageDisagreementStatus: String, Codable, Equatable, Sendable {
    case generatedOnly
    case sourceOnly
    case moveMismatch
}

public struct PokemonLearnablesSourceMove: Codable, Equatable, Sendable {
    public let move: String
    public let bucket: String
    public let sourceSpan: SourceSpan

    public init(move: String, bucket: String, sourceSpan: SourceSpan) {
        self.move = move
        self.bucket = bucket
        self.sourceSpan = sourceSpan
    }
}

public struct PokemonLearnablesCoverageDisagreement: Codable, Equatable, Sendable {
    public let speciesID: String
    public let status: PokemonLearnablesCoverageDisagreementStatus
    public let generatedOnlyMoves: [String]
    public let sourceOnlyMoves: [PokemonLearnablesSourceMove]
    public let contributingSourcePaths: [String]

    public init(
        speciesID: String,
        status: PokemonLearnablesCoverageDisagreementStatus,
        generatedOnlyMoves: [String],
        sourceOnlyMoves: [PokemonLearnablesSourceMove],
        contributingSourcePaths: [String]
    ) {
        self.speciesID = speciesID
        self.status = status
        self.generatedOnlyMoves = generatedOnlyMoves
        self.sourceOnlyMoves = sourceOnlyMoves
        self.contributingSourcePaths = contributingSourcePaths
    }
}

public enum CInitializerEntryStyle: String, Codable, Equatable {
    case bracketed
    case positional
}

public struct CInitializerTableDescriptor: Codable, Equatable {
    public let module: SourceIndexModule
    public let relativePath: String
    public let tableSymbol: String
    public let entryStyle: CInitializerEntryStyle
    public let idField: String?
    public let knownFields: [String]
    public let warnsOnUnknownFields: Bool
    public let isOptional: Bool

    public init(
        module: SourceIndexModule,
        relativePath: String,
        tableSymbol: String,
        entryStyle: CInitializerEntryStyle,
        idField: String? = nil,
        knownFields: [String] = [],
        warnsOnUnknownFields: Bool = false,
        isOptional: Bool = false
    ) {
        self.module = module
        self.relativePath = relativePath
        self.tableSymbol = tableSymbol
        self.entryStyle = entryStyle
        self.idField = idField
        self.knownFields = knownFields
        self.warnsOnUnknownFields = warnsOnUnknownFields
        self.isOptional = isOptional
    }

    enum CodingKeys: String, CodingKey {
        case module
        case relativePath
        case tableSymbol
        case entryStyle
        case idField
        case knownFields
        case warnsOnUnknownFields
        case isOptional
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        module = try container.decode(SourceIndexModule.self, forKey: .module)
        relativePath = try container.decode(String.self, forKey: .relativePath)
        tableSymbol = try container.decode(String.self, forKey: .tableSymbol)
        entryStyle = try container.decode(CInitializerEntryStyle.self, forKey: .entryStyle)
        idField = try container.decodeIfPresent(String.self, forKey: .idField)
        knownFields = try container.decodeIfPresent([String].self, forKey: .knownFields) ?? []
        warnsOnUnknownFields = try container.decodeIfPresent(Bool.self, forKey: .warnsOnUnknownFields) ?? false
        isOptional = try container.decodeIfPresent(Bool.self, forKey: .isOptional) ?? false
    }
}

public struct CInitializerTableParseResult: Codable, Equatable {
    public let descriptor: CInitializerTableDescriptor
    public let entries: [CInitializerEntry]
    public let diagnostics: [Diagnostic]

    public init(
        descriptor: CInitializerTableDescriptor,
        entries: [CInitializerEntry],
        diagnostics: [Diagnostic] = []
    ) {
        self.descriptor = descriptor
        self.entries = entries
        self.diagnostics = diagnostics
    }
}

public extension CInitializerParser {
    static func tableEntries(
        in text: String,
        descriptor: CInitializerTableDescriptor
    ) -> CInitializerTableParseResult {
        let scanner = CInitializerTableScanner(
            text: text,
            relativePath: descriptor.relativePath,
            descriptor: descriptor
        )
        return scanner.parse()
    }
}

public enum ProjectSourceIndexLoader {
    public static func load(
        from index: ProjectIndex,
        fileManager: FileManager = .default
    ) throws -> ProjectSourceIndex {
        let scriptOutline = try ProjectScriptOutlineLoader.load(from: index, fileManager: fileManager)
        return try load(from: index, scriptOutline: scriptOutline, fileManager: fileManager)
    }

    public static func load(
        from index: ProjectIndex,
        scriptOutline: ProjectScriptOutline,
        fileManager: FileManager = .default
    ) throws -> ProjectSourceIndex {
        let root = URL(fileURLWithPath: index.root.path)
        let descriptors = SourceIndexDescriptorSet.descriptors(for: index.profile)
        var records: [SourceIndexRecord] = []
        var diagnostics: [Diagnostic] = []

        for descriptor in descriptors.tables {
            let path = root.appendingPathComponent(descriptor.relativePath)
            guard fileManager.fileExists(atPath: path.path) else {
                if descriptor.isOptional {
                    continue
                }
                if let fallback = try fallbackRecords(for: descriptor, root: root, fileManager: fileManager) {
                    records.append(contentsOf: fallback.records)
                    diagnostics.append(contentsOf: fallback.diagnostics)
                    continue
                }
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "SOURCE_INDEX_DESCRIPTOR_MISSING",
                        message: "Source index descriptor path is not present: \(descriptor.relativePath)",
                        span: SourceSpan(relativePath: descriptor.relativePath, startLine: 1)
                    )
                )
                continue
            }

            let text = try readSourceText(at: path)
            let parsed = CInitializerParser.tableEntries(in: text, descriptor: descriptor)
            diagnostics.append(contentsOf: parsed.diagnostics)
            records.append(contentsOf: parsed.entries.map { record(from: $0, descriptor: descriptor) })
        }

        for scanner in descriptors.specialScanners {
            let scanned = try scanner.scan(root: root, fileManager: fileManager)
            records.append(contentsOf: scanned.records)
            diagnostics.append(contentsOf: scanned.diagnostics)
        }

        records = ExpansionAllLearnablesCoverageBuilder.annotate(
            records: records,
            index: index,
            fileManager: fileManager
        )

        for descriptor in descriptors.trainerPartyFiles {
            let path = root.appendingPathComponent(descriptor)
            guard fileManager.fileExists(atPath: path.path) else {
                continue
            }

            let text = try readSourceText(at: path)
            records.append(contentsOf: TrainerPartyIndexScanner.records(in: text, relativePath: descriptor))
        }

        records.append(contentsOf: scriptOutline.labels.filter { $0.kind != .text }.map(record(from:)))
        records.append(contentsOf: scriptOutline.textBlocks.map(record(from:)))
        diagnostics.append(contentsOf: scriptOutline.diagnostics)

        diagnostics.append(contentsOf: records.flatMap(\.diagnostics))

        return ProjectSourceIndex(
            root: index.root,
            profile: index.profile,
            adapterID: index.adapterID,
            adapterName: index.adapterName,
            records: records.sorted { lhs, rhs in
                if lhs.module.rawValue == rhs.module.rawValue {
                    return lhs.sourceSpan.relativePath == rhs.sourceSpan.relativePath
                        ? lhs.sourceSpan.startLine < rhs.sourceSpan.startLine
                        : lhs.sourceSpan.relativePath < rhs.sourceSpan.relativePath
                }
                return lhs.module.rawValue < rhs.module.rawValue
            },
            diagnostics: diagnostics
        )
    }

    private static func fallbackRecords(
        for descriptor: CInitializerTableDescriptor,
        root: URL,
        fileManager: FileManager
    ) throws -> (records: [SourceIndexRecord], diagnostics: [Diagnostic])? {
        guard descriptor.module == .items, descriptor.relativePath == "src/data/items.h" else {
            return nil
        }

        let jsonPath = "src/data/items.json"
        let url = root.appendingPathComponent(jsonPath)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let text = try readSourceText(at: url)
        return try JSONSourceIndexScanner.itemRecords(in: text, relativePath: jsonPath)
    }

    private static func record(
        from entry: CInitializerEntry,
        descriptor: CInitializerTableDescriptor
    ) -> SourceIndexRecord {
        let module = descriptor.module
        let title = title(for: entry, descriptor: descriptor)
        let tags = tags(for: module, descriptor: descriptor)
        let facts = facts(for: entry, descriptor: descriptor)
        let diagnostics = diagnostics(for: entry, descriptor: descriptor)

        return SourceIndexRecord(
            id: "\(module.rawValue):\(descriptor.relativePath):\(entry.symbol)",
            module: module,
            title: title,
            subtitle: descriptor.relativePath,
            sourceSpan: entry.span,
            tags: tags,
            facts: facts,
            preview: preview(entry.body),
            diagnostics: diagnostics
        )
    }

    private static func record(from label: ScriptOutlineLabel) -> SourceIndexRecord {
        SourceIndexRecord(
            id: "scripts:\(label.sourcePath):\(label.label)",
            module: .scripts,
            title: label.label,
            subtitle: label.sourcePath,
            sourceSpan: label.sourceSpan,
            tags: ["script", "outline", label.kind.rawValue, label.sourceRole.rawValue],
            facts: [
                SourceIndexFact(label: "Commands", value: "\(label.commands.count)"),
                SourceIndexFact(label: "Text Refs", value: "\(label.textReferences.count)"),
                SourceIndexFact(label: "Kind", value: label.kind.title),
                SourceIndexFact(label: "Lines", value: "\(label.sourceSpan.startLine)-\(label.sourceSpan.endLine)")
            ],
            preview: label.bodyPreview,
            diagnostics: label.diagnostics
        )
    }

    private static func record(from textBlock: ScriptTextBlock) -> SourceIndexRecord {
        SourceIndexRecord(
            id: "text:\(textBlock.sourcePath):\(textBlock.label)",
            module: .text,
            title: textBlock.label,
            subtitle: textBlock.sourcePath,
            sourceSpan: textBlock.sourceSpan,
            tags: ["text", "outline"],
            facts: [
                SourceIndexFact(label: "String Lines", value: "\(textBlock.stringLineCount)"),
                SourceIndexFact(label: "Characters", value: "\(textBlock.characterCount)"),
                SourceIndexFact(label: "Lines", value: "\(textBlock.sourceSpan.startLine)-\(textBlock.sourceSpan.endLine)")
            ],
            preview: textBlock.preview,
            diagnostics: textBlock.diagnostics
        )
    }

    private static func title(
        for entry: CInitializerEntry,
        descriptor: CInitializerTableDescriptor
    ) -> String {
        if descriptor.entryStyle == .positional, let idField = descriptor.idField {
            return entry.fields[idField] ?? entry.symbol
        }
        return entry.symbol
    }

    private static func tags(
        for module: SourceIndexModule,
        descriptor: CInitializerTableDescriptor
    ) -> [String] {
        switch (module, descriptor.entryStyle) {
        case (.pokemon, _):
            return ["species", "table"]
        case (.trainers, _):
            return ["trainer", "table"]
        case (.items, .positional):
            return ["item", "positional"]
        case (.items, .bracketed):
            return ["item", "bracketed"]
        case (.moves, _):
            return ["move", "table"]
        case (.learnsets, _):
            return ["learnset", "table"]
        case (.evolutions, _):
            return ["evolution", "table"]
        case (.pokedex, _):
            return ["pokedex", "table"]
        default:
            return ["table"]
        }
    }

    private static func facts(
        for entry: CInitializerEntry,
        descriptor: CInitializerTableDescriptor
    ) -> [SourceIndexFact] {
        let preferred = preferredFactFields(for: descriptor)
        var facts: [SourceIndexFact] = []
        if let ordinal = entry.ordinal {
            facts.append(SourceIndexFact(label: "Index", value: "\(ordinal)"))
        }
        for key in preferred {
            if let value = entry.fields[key] {
                facts.append(SourceIndexFact(label: key, value: compact(value)))
            }
        }
        appendExpansionMoveContestResourceFact(for: entry, descriptor: descriptor, facts: &facts)
        facts.append(SourceIndexFact(label: "Lines", value: "\(entry.span.startLine)-\(entry.span.endLine)"))
        return Array(facts.prefix(factLimit(for: descriptor)))
    }

    private static func preferredFactFields(for descriptor: CInitializerTableDescriptor) -> [String] {
        switch descriptor.module {
        case .pokemon:
            return ["baseHP", "baseAttack", "baseDefense", "baseSpeed", "types", "type1", "type2", "abilities", "ability1", "ability2", "growthRate"]
        case .trainers:
            return ["trainerName", "trainerClass", "encounterMusic_gender", "items", "doubleBattle", "aiFlags", "party"]
        case .items:
            return ["itemId", "name", "price", "holdEffect", "holdEffectParam", "importance", "registrability", "pocket", "sortType", "type", "exitsBagOnUse", "effect", "fieldUseFunc", "battleUsage", "battleUseFunc", "secondaryId", "iconPic", "iconPalette"]
        case .moves:
            if isExpansionMoveInfoDescriptor(descriptor) {
                return ["effect", "power", "type", "accuracy", "pp", "secondaryEffectChance", "target", "priority", "flags", "contestCategory", "contestAppeal", "contestJam", "contestComboStarterId", "contestComboMoves"]
            }
            return ["effect", "power", "type", "accuracy", "pp", "secondaryEffectChance", "target", "priority", "flags", "contestEffect", "contestCategory", "comboStarterId", "comboMoves"]
        case .pokedex:
            return ["categoryName", "height", "weight", "description", "description1", "description2", "pokemonScale", "trainerScale"]
        default:
            return []
        }
    }

    private static func appendExpansionMoveContestResourceFact(
        for entry: CInitializerEntry,
        descriptor: CInitializerTableDescriptor,
        facts: inout [SourceIndexFact]
    ) {
        guard isExpansionMoveInfoDescriptor(descriptor) else { return }
        let contestMetadataFields = ["contestCategory", "contestAppeal", "contestJam", "contestComboStarterId", "contestComboMoves"]
        guard contestMetadataFields.contains(where: { entry.fields[$0] != nil }) else { return }
        facts.append(
            SourceIndexFact(
                label: "Expansion Contest Resource Facts",
                value: "preview-only facts; blocked: constants, generated all_learnables.json writes, reference writes, ROM/build/export paths, binary writes, data row creation/removal/reorder"
            )
        )
    }

    private static func factLimit(for descriptor: CInitializerTableDescriptor) -> Int {
        if descriptor.module == .items {
            return 24
        }
        if isExpansionMoveInfoDescriptor(descriptor) {
            return 24
        }
        if descriptor.module == .moves {
            return 12
        }
        return 8
    }

    private static func isExpansionMoveInfoDescriptor(_ descriptor: CInitializerTableDescriptor) -> Bool {
        descriptor.module == .moves
            && descriptor.relativePath == "src/data/moves_info.h"
            && descriptor.tableSymbol == "gMovesInfo"
    }

    private static func diagnostics(
        for entry: CInitializerEntry,
        descriptor: CInitializerTableDescriptor
    ) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []

        if
            descriptor.entryStyle == .positional,
            let idField = descriptor.idField,
            entry.fields[idField] == nil
        {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "TABLE_ENTRY_ID_MISSING",
                    message: "Positional entry is missing expected \(idField) field.",
                    span: entry.span
                )
            )
        }

        if descriptor.warnsOnUnknownFields, !descriptor.knownFields.isEmpty {
            let knownFields = Set(descriptor.knownFields)
            let unknownFields = entry.fields.keys
                .filter { !knownFields.contains($0) }
                .sorted()
            diagnostics.append(contentsOf: unknownFields.map { field in
                Diagnostic(
                    severity: .warning,
                    code: "TABLE_ENTRY_UNKNOWN_FIELD",
                    message: "\(entry.symbol) has unknown designated field \(field); preserving it as raw source for later mutation-plan support.",
                    span: entry.span
                )
            })
        }

        return diagnostics
    }

    private static func preview(_ text: String) -> String {
        text.components(separatedBy: .newlines)
            .prefix(12)
            .joined(separator: "\n")
    }

    private static func compact(_ value: String) -> String {
        value.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func readSourceText(at url: URL) throws -> String {
        if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
            return utf8
        }
        return try String(contentsOf: url, encoding: .isoLatin1)
    }

    private static func sourceFiles(
        root: URL,
        roots: [String],
        extensions: Set<String>,
        fileManager: FileManager
    ) -> [String] {
        var paths: [String] = []

        for relativeRoot in roots {
            let url = root.appendingPathComponent(relativeRoot)
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else { continue }

            if isDirectory.boolValue {
                guard let enumerator = fileManager.enumerator(
                    at: url,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                ) else {
                    continue
                }

                for case let fileURL as URL in enumerator {
                    guard
                        (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true,
                        extensions.contains(fileURL.pathExtension.lowercased())
                    else {
                        continue
                    }
                    paths.append(relativePath(for: fileURL, root: root))
                }
            } else if extensions.contains(url.pathExtension.lowercased()) {
                paths.append(relativeRoot)
            }
        }

        return Array(Set(paths)).sorted()
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

struct ExpansionAllLearnablesCoverageReport: Equatable {
    let summary: PokemonLearnablesCoverage
    let species: [String: ExpansionAllLearnablesSpeciesCoverage]
}

struct ExpansionAllLearnablesSpeciesCoverage: Equatable {
    enum Status: String, Equatable {
        case matching
        case generatedOnly
        case sourceOnly
        case moveMismatch
    }

    let speciesID: String
    let status: Status
    let generatedMoveCount: Int
    let parsedSourceMoveCount: Int
    let missingGeneratedMoveCount: Int
    let extraGeneratedMoveCount: Int
    let missingGeneratedMoves: [PokemonLearnablesSourceMove]
    let extraGeneratedMoves: [String]
}

enum ExpansionAllLearnablesCoverageBuilder {
    static let generatedPath = "src/data/pokemon/all_learnables.json"
    private static let regenerationPosture = "copyReportOnly"
    private static let regenerationBucketPaths = [
        PokemonLearnablesSourceBucketPaths(bucket: "levelUp", paths: [
            "src/data/pokemon/level_up_learnsets.h",
            "src/data/pokemon/level_up_learnsets"
        ]),
        PokemonLearnablesSourceBucketPaths(bucket: "tmhm", paths: ["src/data/pokemon/tmhm_learnsets.h"]),
        PokemonLearnablesSourceBucketPaths(bucket: "tutor", paths: ["src/data/pokemon/tutor_learnsets.h"]),
        PokemonLearnablesSourceBucketPaths(bucket: "egg", paths: ["src/data/pokemon/egg_moves.h"])
    ]
    private static let regenerationReportCommands = [
        "swift run --package-path PokemonHackStudio pokemonhack-cli pokemon-compatibility <project-root> --json",
        "swift run --package-path PokemonHackStudio pokemonhack-cli asset-index <project-root> --json"
    ]
    private static let regenerationReviewGuidance =
        "Review generated-only and source-only move IDs with the reported bucket/source spans, then run the project's documented all_learnables generator outside PokemonHackStudio. PokemonHackStudio will not run regeneration or write generated JSON."

    static func annotate(
        records: [SourceIndexRecord],
        index: ProjectIndex,
        fileManager: FileManager
    ) -> [SourceIndexRecord] {
        guard index.profile == .pokeemeraldExpansion,
              records.contains(where: isAllLearnablesRecord),
              let report = report(index: index, fileManager: fileManager)
        else {
            return records
        }

        return records.map { record in
            guard isAllLearnablesRecord(record) else { return record }
            let speciesCoverage = report.species[record.title]
            return record.appendingFacts(facts(for: speciesCoverage, summary: report.summary))
        }
    }

    static func report(
        index: ProjectIndex,
        speciesCatalog providedSpeciesCatalog: ProjectSpeciesCatalog? = nil,
        fileManager: FileManager = .default
    ) -> ExpansionAllLearnablesCoverageReport? {
        guard index.profile == .pokeemeraldExpansion else { return nil }
        let root = URL(fileURLWithPath: index.root.path).standardizedFileURL
        guard let generatedMoveSets = generatedMoveSets(root: root, fileManager: fileManager) else { return nil }
        let speciesCatalog: ProjectSpeciesCatalog
        if let providedSpeciesCatalog {
            speciesCatalog = providedSpeciesCatalog
        } else if let loadedCatalog = try? ProjectSpeciesCatalogBuilder.build(index: index, fileManager: fileManager) {
            speciesCatalog = loadedCatalog
        } else {
            return nil
        }

        let parsedMoveSets = parsedMoveSets(from: speciesCatalog)
        let generatedSpecies = Set(generatedMoveSets.keys)
        let parsedSpecies = Set(parsedMoveSets.keys)
        var speciesCoverage: [String: ExpansionAllLearnablesSpeciesCoverage] = [:]
        var disagreements: [PokemonLearnablesCoverageDisagreement] = []
        var matchingSpeciesCount = 0
        var moveMismatchSpeciesCount = 0

        for speciesID in generatedSpecies.union(parsedSpecies).sorted() {
            let generatedMoves = generatedMoveSets[speciesID] ?? []
            let parsedMoves = parsedMoveSets[speciesID] ?? []
            let parsedMoveIDs = Set(parsedMoves.map(\.move))
            let status: ExpansionAllLearnablesSpeciesCoverage.Status
            let missingGeneratedMoves: [PokemonLearnablesSourceMove]
            let extraGeneratedMoves: [String]
            if generatedSpecies.contains(speciesID), parsedSpecies.contains(speciesID) {
                missingGeneratedMoves = parsedMoves
                    .filter { !generatedMoves.contains($0.move) }
                    .sorted(by: sourceMoveSort)
                extraGeneratedMoves = generatedMoves
                    .subtracting(parsedMoveIDs)
                    .sorted()
                if missingGeneratedMoves.isEmpty && extraGeneratedMoves.isEmpty {
                    status = .matching
                    matchingSpeciesCount += 1
                } else {
                    status = .moveMismatch
                    moveMismatchSpeciesCount += 1
                }
            } else if generatedSpecies.contains(speciesID) {
                status = .generatedOnly
                missingGeneratedMoves = []
                extraGeneratedMoves = generatedMoves.sorted()
            } else {
                status = .sourceOnly
                missingGeneratedMoves = parsedMoves.sorted(by: sourceMoveSort)
                extraGeneratedMoves = []
            }

            speciesCoverage[speciesID] = ExpansionAllLearnablesSpeciesCoverage(
                speciesID: speciesID,
                status: status,
                generatedMoveCount: generatedMoves.count,
                parsedSourceMoveCount: parsedMoveIDs.count,
                missingGeneratedMoveCount: Set(missingGeneratedMoves.map(\.move)).count,
                extraGeneratedMoveCount: extraGeneratedMoves.count,
                missingGeneratedMoves: missingGeneratedMoves,
                extraGeneratedMoves: extraGeneratedMoves
            )
            if status != .matching {
                disagreements.append(
                    PokemonLearnablesCoverageDisagreement(
                        speciesID: speciesID,
                        status: PokemonLearnablesCoverageDisagreementStatus(rawValue: status.rawValue) ?? .moveMismatch,
                        generatedOnlyMoves: extraGeneratedMoves,
                        sourceOnlyMoves: missingGeneratedMoves,
                        contributingSourcePaths: contributingSourcePaths(for: missingGeneratedMoves)
                    )
                )
            }
        }

        let generatedOnlySpeciesCount = generatedSpecies.subtracting(parsedSpecies).count
        let sourceOnlySpeciesCount = parsedSpecies.subtracting(generatedSpecies).count
        let staleSourcePaths = staleSourcePaths(root: root, fileManager: fileManager)
        let mismatchSpeciesCount = generatedOnlySpeciesCount + sourceOnlySpeciesCount + moveMismatchSpeciesCount
        let regenerationPlan = regenerationPlan(disagreements: disagreements)
        let summary = PokemonLearnablesCoverage(
            generatedSpeciesCount: generatedSpecies.count,
            parsedSourceSpeciesCount: parsedSpecies.count,
            matchingSpeciesCount: matchingSpeciesCount,
            mismatchSpeciesCount: mismatchSpeciesCount,
            generatedOnlySpeciesCount: generatedOnlySpeciesCount,
            sourceOnlySpeciesCount: sourceOnlySpeciesCount,
            moveMismatchSpeciesCount: moveMismatchSpeciesCount,
            staleSourceFileCount: staleSourcePaths.count,
            newestStaleSourcePath: staleSourcePaths.first,
            staleSourcePaths: staleSourcePaths,
            disagreements: disagreements,
            regenerationPlan: regenerationPlan
        )

        return ExpansionAllLearnablesCoverageReport(summary: summary, species: speciesCoverage)
    }

    private static func generatedMoveSets(root: URL, fileManager: FileManager) -> [String: Set<String>]? {
        let url = root.appendingPathComponent(generatedPath)
        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        var result: [String: Set<String>] = [:]
        for (key, value) in object {
            guard let moves = value as? [String] else { continue }
            result[normalizedSpeciesID(key)] = Set(moves.map(normalizedMoveID).filter { !$0.isEmpty })
        }
        return result
    }

    private static func parsedMoveSets(from catalog: ProjectSpeciesCatalog) -> [String: [PokemonLearnablesSourceMove]] {
        var result: [String: [PokemonLearnablesSourceMove]] = [:]
        for species in catalog.species {
            var moves: [PokemonLearnablesSourceMove] = []
            moves.append(contentsOf: species.learnsets.levelUp.compactMap { sourceMove(move: $0.move, bucket: "levelUp", span: $0.sourceSpan) })
            moves.append(contentsOf: species.learnsets.tmhm.compactMap { sourceMove(move: $0.move, bucket: "tmhm", span: $0.sourceSpan) })
            moves.append(contentsOf: species.learnsets.tutor.compactMap { sourceMove(move: $0.move, bucket: "tutor", span: $0.sourceSpan) })
            moves.append(contentsOf: species.learnsets.egg.compactMap { sourceMove(move: $0.move, bucket: "egg", span: $0.sourceSpan) })
            if !moves.isEmpty {
                result[species.speciesID] = moves
            }
        }
        return result
    }

    private static func sourceMove(move: String, bucket: String, span: SourceSpan) -> PokemonLearnablesSourceMove? {
        let normalized = normalizedMoveID(move)
        guard !normalized.isEmpty else { return nil }
        return PokemonLearnablesSourceMove(move: normalized, bucket: bucket, sourceSpan: span)
    }

    private static func sourceMoveSort(
        lhs: PokemonLearnablesSourceMove,
        rhs: PokemonLearnablesSourceMove
    ) -> Bool {
        if lhs.move != rhs.move {
            return lhs.move < rhs.move
        }
        let lhsBucket = bucketSortIndex(lhs.bucket)
        let rhsBucket = bucketSortIndex(rhs.bucket)
        if lhsBucket != rhsBucket {
            return lhsBucket < rhsBucket
        }
        if lhs.sourceSpan.relativePath != rhs.sourceSpan.relativePath {
            return lhs.sourceSpan.relativePath < rhs.sourceSpan.relativePath
        }
        return lhs.sourceSpan.startLine < rhs.sourceSpan.startLine
    }

    private static func bucketSortIndex(_ bucket: String) -> Int {
        switch bucket {
        case "levelUp": return 0
        case "tmhm": return 1
        case "tutor": return 2
        case "egg": return 3
        default: return 4
        }
    }

    private static func contributingSourcePaths(for moves: [PokemonLearnablesSourceMove]) -> [String] {
        Array(Set(moves.map { $0.sourceSpan.relativePath })).sorted()
    }

    private static func regenerationPlan(
        disagreements: [PokemonLearnablesCoverageDisagreement]
    ) -> PokemonLearnablesRegenerationPlan? {
        guard !disagreements.isEmpty else { return nil }
        let reviewItems = disagreements.sorted { lhs, rhs in
            lhs.speciesID < rhs.speciesID
        }
        let generatedOnlyMoveIDs = Array(Set(reviewItems.flatMap(\.generatedOnlyMoves))).sorted()
        let sourceOnlyMoveIDs = Array(Set(reviewItems.flatMap { $0.sourceOnlyMoves.map(\.move) })).sorted()
        return PokemonLearnablesRegenerationPlan(
            posture: regenerationPosture,
            generatedPath: generatedPath,
            sourceBuckets: regenerationBucketPaths.map(\.bucket),
            bucketPaths: regenerationBucketPaths,
            generatedOnlyMoveIDs: generatedOnlyMoveIDs,
            sourceOnlyMoveIDs: sourceOnlyMoveIDs,
            reviewItems: reviewItems,
            reportCommands: regenerationReportCommands,
            reviewGuidance: regenerationReviewGuidance
        )
    }

    private static func staleSourcePaths(
        root: URL,
        fileManager: FileManager
    ) -> [String] {
        guard let generatedModifiedAt = modificationDate(for: generatedPath, root: root, fileManager: fileManager) else {
            return []
        }
        let staleSources = learnsetSourcePaths(root: root, fileManager: fileManager)
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
        return staleSources.map(\.path)
    }

    private static func learnsetSourcePaths(root: URL, fileManager: FileManager) -> [String] {
        var paths = [
            "src/data/pokemon/level_up_learnsets.h",
            "src/data/pokemon/tmhm_learnsets.h",
            "src/data/pokemon/tutor_learnsets.h",
            "src/data/pokemon/egg_moves.h"
        ].filter { fileManager.fileExists(atPath: root.appendingPathComponent($0).path) }

        let levelUpDirectoryPath = "src/data/pokemon/level_up_learnsets"
        let levelUpDirectory = root.appendingPathComponent(levelUpDirectoryPath)
        if let enumerator = fileManager.enumerator(
            at: levelUpDirectory,
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
    }

    private static func modificationDate(
        for relativePath: String,
        root: URL,
        fileManager: FileManager
    ) -> Date? {
        let url = root.appendingPathComponent(relativePath)
        return (try? fileManager.attributesOfItem(atPath: url.path)[.modificationDate]) as? Date
    }

    private static func facts(
        for speciesCoverage: ExpansionAllLearnablesSpeciesCoverage?,
        summary: PokemonLearnablesCoverage
    ) -> [SourceIndexFact] {
        var facts: [SourceIndexFact] = []
        if let speciesCoverage {
            facts.append(SourceIndexFact(label: "Coverage Status", value: speciesCoverage.status.rawValue))
            facts.append(SourceIndexFact(label: "Parsed Source Moves", value: "\(speciesCoverage.parsedSourceMoveCount)"))
            facts.append(SourceIndexFact(label: "Missing Generated Moves", value: "\(speciesCoverage.missingGeneratedMoveCount)"))
            facts.append(SourceIndexFact(label: "Extra Generated Moves", value: "\(speciesCoverage.extraGeneratedMoveCount)"))
            let missingMoveIDs = Array(Set(speciesCoverage.missingGeneratedMoves.map(\.move))).sorted()
            if !missingMoveIDs.isEmpty {
                facts.append(SourceIndexFact(label: "Missing Generated Move IDs", value: missingMoveIDs.joined(separator: ", ")))
            }
            if !speciesCoverage.extraGeneratedMoves.isEmpty {
                facts.append(SourceIndexFact(label: "Extra Generated Move IDs", value: speciesCoverage.extraGeneratedMoves.joined(separator: ", ")))
            }
        }
        facts.append(SourceIndexFact(label: "Generated Species", value: "\(summary.generatedSpeciesCount)"))
        facts.append(SourceIndexFact(label: "Parsed Source Species", value: "\(summary.parsedSourceSpeciesCount)"))
        facts.append(SourceIndexFact(label: "Coverage Matches", value: "\(summary.matchingSpeciesCount)"))
        facts.append(SourceIndexFact(label: "Coverage Mismatches", value: "\(summary.mismatchSpeciesCount)"))
        facts.append(SourceIndexFact(label: "Generated-only Species", value: "\(summary.generatedOnlySpeciesCount)"))
        facts.append(SourceIndexFact(label: "Source-only Species", value: "\(summary.sourceOnlySpeciesCount)"))
        facts.append(SourceIndexFact(label: "Move-set Mismatches", value: "\(summary.moveMismatchSpeciesCount)"))
        facts.append(SourceIndexFact(label: "Stale Source Files", value: "\(summary.staleSourceFileCount)"))
        if let newestStaleSourcePath = summary.newestStaleSourcePath {
            facts.append(SourceIndexFact(label: "Newest Stale Source", value: newestStaleSourcePath))
        }
        if let regenerationPlan = summary.regenerationPlan {
            facts.append(SourceIndexFact(label: "Regeneration Posture", value: "copy/report-only; no generated JSON writes or command execution"))
            facts.append(SourceIndexFact(label: "Regeneration Source Buckets", value: regenerationPlan.sourceBuckets.joined(separator: ", ")))
            facts.append(SourceIndexFact(label: "Regeneration Source Paths", value: regenerationPlan.bucketPaths.flatMap(\.paths).joined(separator: "; ")))
            if !regenerationPlan.sourceOnlyMoveIDs.isEmpty {
                facts.append(SourceIndexFact(label: "Regeneration Source-only Move IDs", value: regenerationPlan.sourceOnlyMoveIDs.joined(separator: ", ")))
            }
            if !regenerationPlan.generatedOnlyMoveIDs.isEmpty {
                facts.append(SourceIndexFact(label: "Regeneration Generated-only Move IDs", value: regenerationPlan.generatedOnlyMoveIDs.joined(separator: ", ")))
            }
            facts.append(SourceIndexFact(label: "Regeneration Report Commands", value: regenerationPlan.reportCommands.joined(separator: "; ")))
            facts.append(SourceIndexFact(label: "Regeneration Guidance", value: regenerationPlan.reviewGuidance))
        }
        return facts
    }

    private static func isAllLearnablesRecord(_ record: SourceIndexRecord) -> Bool {
        record.module == .learnsets
            && record.sourceSpan.relativePath == generatedPath
            && record.tags.contains("all-learnables")
    }

    private static func normalizedSpeciesID(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("SPECIES_") ? trimmed : "SPECIES_\(trimmed)"
    }

    private static func normalizedMoveID(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
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

private extension SourceIndexRecord {
    func appendingFacts(_ additionalFacts: [SourceIndexFact]) -> SourceIndexRecord {
        SourceIndexRecord(
            id: id,
            module: module,
            title: title,
            subtitle: subtitle,
            sourceSpan: sourceSpan,
            tags: tags,
            facts: facts + additionalFacts,
            preview: preview,
            diagnostics: diagnostics
        )
    }
}

struct SourceIndexDescriptorSet {
    let tables: [CInitializerTableDescriptor]
    let trainerPartyFiles: [String]
    let scriptRoots: [String]
    let textRoots: [String]
    let specialScanners: [SourceIndexSpecialScanner]

    init(
        tables: [CInitializerTableDescriptor],
        trainerPartyFiles: [String],
        scriptRoots: [String],
        textRoots: [String],
        specialScanners: [SourceIndexSpecialScanner] = []
    ) {
        self.tables = tables
        self.trainerPartyFiles = trainerPartyFiles
        self.scriptRoots = scriptRoots
        self.textRoots = textRoots
        self.specialScanners = specialScanners
    }

    private static let speciesFields = [
        "baseHP", "baseAttack", "baseDefense", "baseSpeed", "baseSpAttack", "baseSpDefense",
        "types", "type1", "type2", "catchRate", "expYield",
        "evYield_HP", "evYield_Attack", "evYield_Defense", "evYield_Speed", "evYield_SpAttack", "evYield_SpDefense",
        "itemCommon", "itemRare", "item1", "item2",
        "genderRatio", "eggCycles", "friendship", "growthRate",
        "eggGroups", "eggGroup1", "eggGroup2",
        "abilities", "ability1", "ability2",
        "safariZoneFleeRate", "bodyColor", "noFlip"
    ]

    private static let trainerFields = [
        "trainerClass", "encounterMusic_gender", "trainerPic", "trainerName",
        "items", "doubleBattle", "aiFlags", "party", "partyFlags", "partySize"
    ]

    private static let itemFields = [
        "itemId", "name", "price", "holdEffect", "holdEffectParam",
        "description", "descriptionPage1", "descriptionPage2",
        "importance", "registrability", "pocket", "sortType", "type",
        "fieldUseFunc", "battleUsage", "battleUseFunc", "secondaryId", "exitsBagOnUse",
        "effect", "iconPic", "iconPalette"
    ]

    private static let moveFields = [
        "effect", "power", "type", "accuracy", "pp",
        "secondaryEffectChance", "target", "priority", "flags", "description",
        "contestEffect"
    ]

    private static let contestMoveFields = [
        "effect", "contestCategory", "comboStarterId", "comboMoves"
    ]

    private static let pokedexFields = [
        "categoryName", "height", "weight",
        "description", "description1", "description2", "descriptionPage1", "descriptionPage2", "unusedDescription",
        "pokemonScale", "pokemonOffset", "trainerScale", "trainerOffset"
    ]

    private static let formScanners: [SourceIndexSpecialScanner] = [
        .formSpeciesTables("src/data/pokemon/form_species_tables.h"),
        .formChangeTables("src/data/pokemon/form_change_tables.h")
    ]

    static func descriptors(for profile: GameProfile) -> SourceIndexDescriptorSet {
        switch profile {
        case .pokeruby:
            SourceIndexDescriptorSet(
                tables: [
                    CInitializerTableDescriptor(module: .pokemon, relativePath: "src/data/pokemon/base_stats.h", tableSymbol: "gBaseStats", entryStyle: .bracketed, knownFields: speciesFields, warnsOnUnknownFields: true),
                    CInitializerTableDescriptor(module: .trainers, relativePath: "src/data/trainers_en.h", tableSymbol: "gTrainers", entryStyle: .bracketed, knownFields: trainerFields, warnsOnUnknownFields: true),
                    CInitializerTableDescriptor(module: .items, relativePath: "src/data/items_en.h", tableSymbol: "gItems", entryStyle: .positional, idField: "itemId", knownFields: itemFields, warnsOnUnknownFields: true),
                    CInitializerTableDescriptor(module: .moves, relativePath: "src/data/battle_moves.c", tableSymbol: "gBattleMoves", entryStyle: .bracketed, knownFields: moveFields, warnsOnUnknownFields: true),
                    CInitializerTableDescriptor(module: .moves, relativePath: "src/data/contest_moves.h", tableSymbol: "gContestMoves", entryStyle: .bracketed, knownFields: contestMoveFields, warnsOnUnknownFields: true, isOptional: true),
                    CInitializerTableDescriptor(module: .learnsets, relativePath: "src/data/pokemon/level_up_learnset_pointers.h", tableSymbol: "gLevelUpLearnsets", entryStyle: .positional),
                    CInitializerTableDescriptor(module: .learnsets, relativePath: "src/data/pokemon/tmhm_learnsets.h", tableSymbol: "gTMHMLearnsets", entryStyle: .bracketed),
                    CInitializerTableDescriptor(module: .evolutions, relativePath: "src/data/pokemon/evolution.h", tableSymbol: "gEvolutionTable", entryStyle: .bracketed),
                    CInitializerTableDescriptor(module: .pokedex, relativePath: "src/data/pokedex_entries_en.h", tableSymbol: "gPokedexEntries", entryStyle: .positional, knownFields: pokedexFields, warnsOnUnknownFields: true)
                ],
                trainerPartyFiles: [],
                scriptRoots: ["data/scripts", "data"],
                textRoots: ["data/text", "src/data/text", "data-de"],
                specialScanners: formScanners + [
                    .wildEncountersJSON("src/data/wild_encounters.json")
                ]
            )
        case .pokefirered:
            SourceIndexDescriptorSet(
                tables: [
                    CInitializerTableDescriptor(module: .pokemon, relativePath: "src/data/pokemon/species_info.h", tableSymbol: "gSpeciesInfo", entryStyle: .bracketed, knownFields: speciesFields, warnsOnUnknownFields: true),
                    CInitializerTableDescriptor(module: .trainers, relativePath: "src/data/trainers.h", tableSymbol: "gTrainers", entryStyle: .bracketed, knownFields: trainerFields, warnsOnUnknownFields: true),
                    CInitializerTableDescriptor(module: .items, relativePath: "src/data/items.h", tableSymbol: "gItems", entryStyle: .positional, idField: "itemId", knownFields: itemFields, warnsOnUnknownFields: true),
                    CInitializerTableDescriptor(module: .moves, relativePath: "src/data/battle_moves.h", tableSymbol: "gBattleMoves", entryStyle: .bracketed, knownFields: moveFields, warnsOnUnknownFields: true),
                    CInitializerTableDescriptor(module: .learnsets, relativePath: "src/data/pokemon/level_up_learnset_pointers.h", tableSymbol: "gLevelUpLearnsets", entryStyle: .bracketed),
                    CInitializerTableDescriptor(module: .learnsets, relativePath: "src/data/pokemon/tmhm_learnsets.h", tableSymbol: "sTMHMLearnsets", entryStyle: .bracketed),
                    CInitializerTableDescriptor(module: .evolutions, relativePath: "src/data/pokemon/evolution.h", tableSymbol: "gEvolutionTable", entryStyle: .bracketed),
                    CInitializerTableDescriptor(module: .pokedex, relativePath: "src/data/pokemon/pokedex_entries.h", tableSymbol: "gPokedexEntries", entryStyle: .positional, knownFields: pokedexFields, warnsOnUnknownFields: true)
                ],
                trainerPartyFiles: [],
                scriptRoots: ["data/scripts", "data/maps"],
                textRoots: ["data/text", "src/data/text"],
                specialScanners: formScanners + [
                    .wildEncountersJSON("src/data/wild_encounters.json")
                ]
            )
        case .pokeemeraldExpansion:
            SourceIndexDescriptorSet(
                tables: [
                    CInitializerTableDescriptor(module: .pokemon, relativePath: "src/data/pokemon/species_info.h", tableSymbol: "gSpeciesInfo", entryStyle: .bracketed, knownFields: speciesFields),
                    CInitializerTableDescriptor(module: .items, relativePath: "src/data/items.h", tableSymbol: "gItemsInfo", entryStyle: .bracketed, knownFields: itemFields),
                    CInitializerTableDescriptor(module: .moves, relativePath: "src/data/moves_info.h", tableSymbol: "gMovesInfo", entryStyle: .bracketed, knownFields: moveFields)
                ],
                trainerPartyFiles: [
                    "src/data/trainers.party",
                    "src/data/trainers_frlg.party",
                    "src/data/battle_partners.party",
                    "src/data/debug_trainers.party"
                ],
                scriptRoots: ["data/scripts", "data/maps"],
                textRoots: ["data/text", "src/data/text"],
                specialScanners: formScanners + [
                    .levelUpLearnsetDirectory("src/data/pokemon/level_up_learnsets"),
                    .allLearnablesJSON("src/data/pokemon/all_learnables.json"),
                    .speciesFamilySupplements("src/data/pokemon/species_info"),
                    .wildEncountersJSON("src/data/wild_encounters.json")
                ]
            )
        case .pokeemerald:
            SourceIndexDescriptorSet(
                tables: [
                    CInitializerTableDescriptor(module: .pokemon, relativePath: "src/data/pokemon/species_info.h", tableSymbol: "gSpeciesInfo", entryStyle: .bracketed, knownFields: speciesFields, warnsOnUnknownFields: true),
                    CInitializerTableDescriptor(module: .trainers, relativePath: "src/data/trainers.h", tableSymbol: "gTrainers", entryStyle: .bracketed, knownFields: trainerFields, warnsOnUnknownFields: true),
                    CInitializerTableDescriptor(module: .items, relativePath: "src/data/items.h", tableSymbol: "gItems", entryStyle: .bracketed, knownFields: itemFields, warnsOnUnknownFields: true),
                    CInitializerTableDescriptor(module: .moves, relativePath: "src/data/battle_moves.h", tableSymbol: "gBattleMoves", entryStyle: .bracketed, knownFields: moveFields, warnsOnUnknownFields: true),
                    CInitializerTableDescriptor(module: .learnsets, relativePath: "src/data/pokemon/level_up_learnset_pointers.h", tableSymbol: "gLevelUpLearnsets", entryStyle: .bracketed),
                    CInitializerTableDescriptor(module: .learnsets, relativePath: "src/data/pokemon/tmhm_learnsets.h", tableSymbol: "gTMHMLearnsets", entryStyle: .bracketed),
                    CInitializerTableDescriptor(module: .evolutions, relativePath: "src/data/pokemon/evolution.h", tableSymbol: "gEvolutionTable", entryStyle: .bracketed),
                    CInitializerTableDescriptor(module: .pokedex, relativePath: "src/data/pokemon/pokedex_entries.h", tableSymbol: "gPokedexEntries", entryStyle: .positional, knownFields: pokedexFields, warnsOnUnknownFields: true)
                ],
                trainerPartyFiles: [],
                scriptRoots: ["data/scripts", "data/maps"],
                textRoots: ["data/text", "src/data/text"],
                specialScanners: formScanners + [
                    .wildEncountersJSON("src/data/wild_encounters.json")
                ]
            )
        case .binaryROM, .ndsROM, .pokediamond, .pokeplatinum, .pokeheartgold, .pokeblack, .pmdSky,
             .pokemonColosseum, .pokemonXD, .pokemonBox, .pokemonChannel, .gameCubeMedia, .unknown:
            SourceIndexDescriptorSet(
                tables: [],
                trainerPartyFiles: [],
                scriptRoots: [],
                textRoots: []
            )
        }
    }
}

enum SourceIndexSpecialScanner {
    case allLearnablesJSON(String)
    case formChangeTables(String)
    case formSpeciesTables(String)
    case levelUpLearnsetDirectory(String)
    case speciesFamilySupplements(String)
    case wildEncountersJSON(String)

    func scan(root: URL, fileManager: FileManager) throws -> (records: [SourceIndexRecord], diagnostics: [Diagnostic]) {
        switch self {
        case .allLearnablesJSON(let relativePath):
            let url = root.appendingPathComponent(relativePath)
            guard fileManager.fileExists(atPath: url.path) else { return ([], []) }
            let text = try readText(at: url)
            return try JSONSourceIndexScanner.learnableRecords(in: text, relativePath: relativePath)
        case .formChangeTables(let relativePath):
            let url = root.appendingPathComponent(relativePath)
            guard fileManager.fileExists(atPath: url.path) else { return ([], []) }
            let text = try readText(at: url)
            return (FormTableSourceScanner.formChangeRecords(in: text, relativePath: relativePath), [])
        case .formSpeciesTables(let relativePath):
            let url = root.appendingPathComponent(relativePath)
            guard fileManager.fileExists(atPath: url.path) else { return ([], []) }
            let text = try readText(at: url)
            return (FormTableSourceScanner.formSpeciesRecords(in: text, relativePath: relativePath), [])
        case .levelUpLearnsetDirectory(let relativeRoot):
            let files = sourceFiles(root: root, relativeRoot: relativeRoot, extensions: ["h"], fileManager: fileManager)
            var records: [SourceIndexRecord] = []
            for file in files {
                let text = try readText(at: root.appendingPathComponent(file))
                records.append(contentsOf: LevelUpLearnsetSourceScanner.records(in: text, relativePath: file))
            }
            return (records, [])
        case .speciesFamilySupplements(let relativeRoot):
            let files = sourceFiles(root: root, relativeRoot: relativeRoot, extensions: ["h"], fileManager: fileManager)
            var records: [SourceIndexRecord] = []
            for file in files {
                let text = try readText(at: root.appendingPathComponent(file))
                records.append(contentsOf: SpeciesFamilySupplementScanner.records(in: text, relativePath: file))
            }
            return (records, [])
        case .wildEncountersJSON(let relativePath):
            let url = root.appendingPathComponent(relativePath)
            guard fileManager.fileExists(atPath: url.path) else { return ([], []) }
            let text = try readText(at: url)
            return try JSONSourceIndexScanner.encounterRecords(in: text, relativePath: relativePath)
        }
    }

    private func sourceFiles(
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

    private func readText(at url: URL) throws -> String {
        if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
            return utf8
        }
        return try String(contentsOf: url, encoding: .isoLatin1)
    }

    private func relativePath(for url: URL, root: URL) -> String {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        if path.hasPrefix(rootPath + "/") {
            return String(path.dropFirst(rootPath.count + 1))
        }
        return path
    }
}

private enum JSONSourceIndexScanner {
    static func itemRecords(in text: String, relativePath: String) throws -> (records: [SourceIndexRecord], diagnostics: [Diagnostic]) {
        let data = Data(text.utf8)
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let items = root["items"] as? [[String: Any]]
        else {
            return ([], [jsonDiagnostic("JSON_ITEM_INDEX_UNREADABLE", "Could not read FireRed item JSON.", relativePath: relativePath)])
        }

        let records = items.enumerated().map { index, item in
            let itemID = stringValue(item["itemId"]) ?? "ITEM_\(index)"
            let line = lineNumber(containing: itemID, in: text) ?? 1
            let facts = [
                SourceIndexFact(label: "Index", value: "\(index)"),
                SourceIndexFact(label: "name", value: stringValue(item["english"]) ?? "Unknown"),
                SourceIndexFact(label: "price", value: stringValue(item["price"]) ?? "Unknown"),
                SourceIndexFact(label: "pocket", value: stringValue(item["pocket"]) ?? "Unknown"),
                SourceIndexFact(label: "type", value: stringValue(item["type"]) ?? "Unknown")
            ]
            return SourceIndexRecord(
                id: "items:\(relativePath):\(itemID)",
                module: .items,
                title: itemID,
                subtitle: relativePath,
                sourceSpan: SourceSpan(relativePath: relativePath, startLine: line),
                tags: ["item", "json", "firered"],
                facts: facts,
                preview: jsonPreview(item)
            )
        }
        return (records, [])
    }

    static func learnableRecords(in text: String, relativePath: String) throws -> (records: [SourceIndexRecord], diagnostics: [Diagnostic]) {
        let data = Data(text.utf8)
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ([], [jsonDiagnostic("JSON_LEARNABLES_INDEX_UNREADABLE", "Could not read all-learnables JSON.", relativePath: relativePath)])
        }

        let records = root.keys.sorted().compactMap { key -> SourceIndexRecord? in
            guard let moves = root[key] as? [String] else { return nil }
            let species = key.hasPrefix("SPECIES_") ? key : "SPECIES_\(key)"
            return SourceIndexRecord(
                id: "learnsets:\(relativePath):\(species)",
                module: .learnsets,
                title: species,
                subtitle: relativePath,
                sourceSpan: SourceSpan(relativePath: relativePath, startLine: 1),
                tags: ["learnset", "json", "all-learnables", "generated", "read-only"],
                facts: [
                    SourceIndexFact(label: "Expansion Learnset Source Role", value: "generatedAllLearnablesIndex"),
                    SourceIndexFact(label: "Generated From", value: "level-up, TM/HM, tutor, egg learnsets"),
                    SourceIndexFact(label: "Readiness", value: "read-only generated context"),
                    SourceIndexFact(label: "Blocked Actions", value: "apply; generated output writes; reference writes; ROM/binary writes"),
                    SourceIndexFact(label: "Moves", value: "\(moves.count)"),
                    SourceIndexFact(label: "First Moves", value: moves.prefix(4).joined(separator: ", "))
                ],
                preview: moves.prefix(12).joined(separator: "\n")
            )
        }
        return (records, [])
    }

    static func encounterRecords(in text: String, relativePath: String) throws -> (records: [SourceIndexRecord], diagnostics: [Diagnostic]) {
        let data = Data(text.utf8)
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let groups = root["wild_encounter_groups"] as? [[String: Any]]
        else {
            return ([], [jsonDiagnostic("JSON_ENCOUNTERS_INDEX_UNREADABLE", "Could not read wild encounter JSON.", relativePath: relativePath)])
        }

        var records: [SourceIndexRecord] = []
        for group in groups {
            guard let encounters = group["encounters"] as? [[String: Any]] else { continue }
            for encounter in encounters {
                guard let mapName = encounter["map"] as? String else { continue }
                let line = lineNumber(containing: mapName, in: text) ?? 1
                
                var facts: [SourceIndexFact] = []
                if let baseLabel = encounter["base_label"] as? String {
                    facts.append(SourceIndexFact(label: "Base Label", value: baseLabel))
                }
                
                let types = ["land_mons", "water_mons", "rock_smash_mons", "fishing_mons"]
                for type in types {
                    if let typeData = encounter[type] as? [String: Any],
                       let mons = typeData["mons"] as? [[Any]] {
                        facts.append(SourceIndexFact(label: type.replacingOccurrences(of: "_", with: " ").capitalized, value: "\(mons.count) slots"))
                    } else if let typeData = encounter[type] as? [String: Any],
                              let mons = typeData["mons"] as? [[String: Any]] {
                         facts.append(SourceIndexFact(label: type.replacingOccurrences(of: "_", with: " ").capitalized, value: "\(mons.count) slots"))
                    }
                }

                records.append(SourceIndexRecord(
                    id: "encounters:\(relativePath):\(mapName)",
                    module: .encounters,
                    title: mapName,
                    subtitle: relativePath,
                    sourceSpan: SourceSpan(relativePath: relativePath, startLine: line),
                    tags: ["encounters", "wild", "map"],
                    facts: facts,
                    preview: jsonPreview(encounter)
                ))
            }
        }
        return (records, [])
    }

    private static func stringValue(_ value: Any?) -> String? {
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            return number.stringValue
        default:
            return nil
        }
    }

    private static func jsonPreview(_ value: Any) -> String? {
        guard
            JSONSerialization.isValidJSONObject(value),
            let data = try? JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted]),
            let text = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return text.components(separatedBy: .newlines).prefix(12).joined(separator: "\n")
    }

    private static func jsonDiagnostic(_ code: String, _ message: String, relativePath: String) -> Diagnostic {
        Diagnostic(
            severity: .warning,
            code: code,
            message: message,
            span: SourceSpan(relativePath: relativePath, startLine: 1)
        )
    }
}

private enum LevelUpLearnsetSourceScanner {
    static func records(in text: String, relativePath: String) -> [SourceIndexRecord] {
        let lines = text.components(separatedBy: .newlines)
        var records: [SourceIndexRecord] = []
        var index = 0
        while index < lines.count {
            guard let symbol = learnsetSymbol(in: lines[index]) else {
                index += 1
                continue
            }

            let start = index
            var end = index
            while end < lines.count, !lines[end].contains("};") {
                end += 1
            }
            let clampedEnd = min(end, lines.count - 1)
            let body = lines[start...clampedEnd].joined(separator: "\n")
            let moves = symbolTokens(in: body).filter { $0.hasPrefix("MOVE_") && $0 != "MOVE_NONE" && $0 != "LEVEL_UP_MOVE_END" }
            let species = speciesConstant(fromLearnsetSymbol: symbol)
            records.append(SourceIndexRecord(
                id: "learnsets:\(relativePath):\(symbol)",
                module: .learnsets,
                title: species,
                subtitle: relativePath,
                sourceSpan: SourceSpan(
                    relativePath: relativePath,
                    startLine: start + 1,
                    endLine: clampedEnd + 1
                ),
                tags: ["learnset", "level-up", symbol],
                facts: [
                    SourceIndexFact(label: "Symbol", value: symbol),
                    SourceIndexFact(label: "Moves", value: "\(Set(moves).count)"),
                    SourceIndexFact(label: "First Moves", value: Array(moves.prefix(4)).joined(separator: ", "))
                ],
                preview: body.components(separatedBy: .newlines).prefix(12).joined(separator: "\n")
            ))
            index = clampedEnd + 1
        }
        return records
    }

    private static func learnsetSymbol(in line: String) -> String? {
        guard
            line.contains("LevelUpLearnset"),
            let range = line.range(of: #"s[A-Za-z0-9_]+LevelUpLearnset"#, options: .regularExpression)
        else {
            return nil
        }
        return String(line[range])
    }

    private static func speciesConstant(fromLearnsetSymbol symbol: String) -> String {
        var name = symbol
        if name.hasPrefix("s") {
            name.removeFirst()
        }
        if name.hasSuffix("LevelUpLearnset") {
            name.removeLast("LevelUpLearnset".count)
        }
        return "SPECIES_\(screamingSnakeCase(name))"
    }
}

private enum FormTableSourceScanner {
    static func formSpeciesRecords(in text: String, relativePath: String) -> [SourceIndexRecord] {
        records(
            in: text,
            relativePath: relativePath,
            symbolPattern: #"\bs[A-Za-z0-9_]+FormSpeciesIdTable\b"#,
            tag: "form-species-table"
        ) { body in
            let species = uniqueTokens(in: body, prefix: "SPECIES_")
            return [
                SourceIndexFact(label: "Kind", value: "Form Species Table"),
                SourceIndexFact(label: "Forms", value: "\(species.count)"),
                SourceIndexFact(label: "First Species", value: species.prefix(4).joined(separator: ", "))
            ]
        }
    }

    static func formChangeRecords(in text: String, relativePath: String) -> [SourceIndexRecord] {
        records(
            in: text,
            relativePath: relativePath,
            symbolPattern: #"\bs[A-Za-z0-9_]+FormChangeTable\b"#,
            tag: "form-change-table"
        ) { body in
            let formChangeTokens = uniqueTokens(in: body, prefix: "FORM_CHANGE_")
            let changes = formChangeTokens.filter { token in
                !["FORM_CHANGE_END", "FORM_CHANGE_TERMINATOR"].contains(token)
            }
            let species = uniqueTokens(in: body, prefix: "SPECIES_")
            return [
                SourceIndexFact(label: "Kind", value: "Form Change Table"),
                SourceIndexFact(label: "Changes", value: "\(changes.count)"),
                SourceIndexFact(label: "Methods", value: changes.prefix(4).joined(separator: ", ")),
                SourceIndexFact(label: "Target Species", value: species.prefix(4).joined(separator: ", "))
            ]
        }
    }

    private static func records(
        in text: String,
        relativePath: String,
        symbolPattern: String,
        tag: String,
        facts: (String) -> [SourceIndexFact]
    ) -> [SourceIndexRecord] {
        let symbols = Array(Set(regexMatches(symbolPattern, in: text).compactMap(\.first))).sorted()
        return symbols.map { symbol in
            let preview = preview(for: symbol, in: text)
            let startLine = lineNumber(containing: symbol, in: text) ?? 1
            let endLine = startLine + max(0, preview.components(separatedBy: .newlines).count - 1)
            return SourceIndexRecord(
                id: "forms:\(relativePath):\(symbol)",
                module: .pokemon,
                title: symbol,
                subtitle: relativePath,
                sourceSpan: SourceSpan(relativePath: relativePath, startLine: startLine, endLine: endLine),
                tags: ["form", tag, "read-only"],
                facts: facts(preview),
                preview: preview
            )
        }
    }

    private static func preview(for symbol: String, in text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        guard let start = lines.firstIndex(where: { $0.contains(symbol) }) else {
            return lines.prefix(12).joined(separator: "\n")
        }
        var end = start
        while end < lines.count, !lines[end].contains("};") {
            end += 1
        }
        let clampedEnd = min(end, lines.count - 1)
        return lines[start...clampedEnd].prefix(12).joined(separator: "\n")
    }

    private static func uniqueTokens(in text: String, prefix: String) -> [String] {
        var seen = Set<String>()
        return symbolTokens(in: text)
            .filter { $0.hasPrefix(prefix) }
            .filter { seen.insert($0).inserted }
    }
}

private enum SpeciesFamilySupplementScanner {
    static func records(in text: String, relativePath: String) -> [SourceIndexRecord] {
        let blocks = bracketedSpeciesBlocks(in: text, relativePath: relativePath)
        var records: [SourceIndexRecord] = []
        for block in blocks {
            let fields = CFieldExtractor.fields(in: block.body)
            if fields["formSpeciesIdTable"] != nil || fields["formChangeTable"] != nil {
                records.append(
                    SourceIndexRecord(
                        id: "forms:\(relativePath):\(block.species)",
                        module: .pokemon,
                        title: block.species,
                        subtitle: relativePath,
                        sourceSpan: block.span,
                        tags: ["form", "form-supplement", "species-info", "read-only"],
                        facts: [
                            SourceIndexFact(label: "Form Species Table", value: fields["formSpeciesIdTable"] ?? "None"),
                            SourceIndexFact(label: "Form Change Table", value: fields["formChangeTable"] ?? "None"),
                            SourceIndexFact(label: "Lines", value: "\(block.span.startLine)-\(block.span.endLine)")
                        ],
                        preview: block.body.components(separatedBy: .newlines).prefix(12).joined(separator: "\n")
                    )
                )
            }
            if block.body.contains(".evolutions") {
                records.append(
                    SourceIndexRecord(
                        id: "evolutions:\(relativePath):\(block.species)",
                        module: .evolutions,
                        title: block.species,
                        subtitle: relativePath,
                        sourceSpan: block.span,
                        tags: ["evolution", "species-info"],
                        facts: [
                            SourceIndexFact(label: "Evolution", value: compact(block.body, marker: ".evolutions"))
                        ],
                        preview: preview(block.body, marker: ".evolutions")
                    )
                )
            }

            if fields["categoryName"] != nil || fields["description"] != nil || fields["natDexNum"] != nil {
                records.append(
                    SourceIndexRecord(
                        id: "pokedex:\(relativePath):\(block.species)",
                        module: .pokedex,
                        title: block.species,
                        subtitle: relativePath,
                        sourceSpan: block.span,
                        tags: ["pokedex", "species-info"],
                        facts: [
                            SourceIndexFact(label: "Category", value: fields["categoryName"] ?? "Unknown"),
                            SourceIndexFact(label: "Height", value: fields["height"] ?? "Unknown"),
                            SourceIndexFact(label: "Weight", value: fields["weight"] ?? "Unknown"),
                            SourceIndexFact(label: "Description", value: fields["description"] ?? "Unknown")
                        ],
                        preview: block.body.components(separatedBy: .newlines).prefix(12).joined(separator: "\n")
                    )
                )
            }
        }
        return records
    }

    private static func bracketedSpeciesBlocks(in text: String, relativePath: String) -> [(species: String, body: String, span: SourceSpan)] {
        let lines = text.components(separatedBy: .newlines)
        var blocks: [(species: String, body: String, span: SourceSpan)] = []
        var index = 0
        while index < lines.count {
            guard let species = speciesName(in: lines[index]) else {
                index += 1
                continue
            }

            let start = index
            var end = index
            var depth = 0
            var foundOpenBrace = false
            while end < lines.count {
                for character in lines[end] {
                    if character == "{" {
                        depth += 1
                        foundOpenBrace = true
                    } else if character == "}" {
                        depth = max(0, depth - 1)
                    }
                }
                if foundOpenBrace, depth == 0, end > start {
                    break
                }
                end += 1
            }

            let clampedEnd = min(end, lines.count - 1)
            let body = lines[start...clampedEnd].joined(separator: "\n")
            blocks.append(
                (
                    species: species,
                    body: body,
                    span: SourceSpan(relativePath: relativePath, startLine: start + 1, endLine: clampedEnd + 1)
                )
            )
            index = clampedEnd + 1
        }
        return blocks
    }

    private static func speciesName(in line: String) -> String? {
        guard
            let open = line.range(of: "[SPECIES_"),
            let close = line[open.upperBound...].firstIndex(of: "]")
        else {
            return nil
        }
        return String(line[line.index(after: open.lowerBound)..<close])
    }

    private static func compact(_ body: String, marker: String) -> String {
        preview(body, marker: marker)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func preview(_ body: String, marker: String) -> String {
        let lines = body.components(separatedBy: .newlines)
        guard let index = lines.firstIndex(where: { $0.contains(marker) }) else {
            return lines.prefix(8).joined(separator: "\n")
        }
        return lines[index..<min(lines.count, index + 8)].joined(separator: "\n")
    }
}

private struct CInitializerTableScanner {
    let text: String
    let relativePath: String
    let descriptor: CInitializerTableDescriptor

    func parse() -> CInitializerTableParseResult {
        let characters = Array(text)
        guard let tableRange = text.range(of: descriptor.tableSymbol) else {
            return CInitializerTableParseResult(
                descriptor: descriptor,
                entries: [],
                diagnostics: [
                    Diagnostic(
                        severity: .warning,
                        code: "TABLE_NOT_FOUND",
                        message: "Could not find C initializer table \(descriptor.tableSymbol).",
                        span: SourceSpan(relativePath: relativePath, startLine: 1)
                    )
                ]
            )
        }

        guard let openOffset = firstOpenBrace(after: text.distance(from: text.startIndex, to: tableRange.upperBound), in: characters) else {
            return CInitializerTableParseResult(
                descriptor: descriptor,
                entries: [],
                diagnostics: [
                    Diagnostic(
                        severity: .warning,
                        code: "TABLE_INITIALIZER_MISSING",
                        message: "Could not find an initializer body for C table \(descriptor.tableSymbol).",
                        span: SourceSpan(
                            relativePath: relativePath,
                            startLine: lineNumber(at: text.distance(from: text.startIndex, to: tableRange.lowerBound), in: text)
                        )
                    )
                ]
            )
        }

        guard let closeOffset = matchingCloseBrace(from: openOffset, in: characters) else {
            return CInitializerTableParseResult(
                descriptor: descriptor,
                entries: [],
                diagnostics: [
                    Diagnostic(
                        severity: .warning,
                        code: "TABLE_INITIALIZER_UNTERMINATED",
                        message: "Could not find the closing brace for C table \(descriptor.tableSymbol).",
                        span: SourceSpan(
                            relativePath: relativePath,
                            startLine: lineNumber(at: openOffset, in: text)
                        )
                    )
                ]
            )
        }

        let lineNumbers = lineNumberMap(for: characters)
        let segments = topLevelSegments(in: characters, openOffset: openOffset, closeOffset: closeOffset)
        var entries: [CInitializerEntry] = []
        var diagnostics: [Diagnostic] = []
        var ordinal = 0

        for segment in segments {
            guard let bounds = trimmedBounds(for: segment, in: characters) else { continue }
            let body = String(characters[bounds.start..<bounds.end])
            guard !body.isEmpty else { continue }
            let span = SourceSpan(
                relativePath: relativePath,
                startLine: lineNumbers[min(bounds.start, lineNumbers.count - 1)],
                endLine: lineNumbers[min(max(bounds.end - 1, bounds.start), lineNumbers.count - 1)]
            )

            let symbol = symbol(for: body, ordinal: ordinal)
            let fields = CFieldExtractor.fields(in: body)
            if let diagnostic = unsupportedShapeDiagnostic(for: body, ordinal: ordinal, span: span) {
                diagnostics.append(diagnostic)
            }
            entries.append(
                CInitializerEntry(
                    symbol: symbol,
                    body: body,
                    span: span,
                    ordinal: descriptor.entryStyle == .positional ? ordinal : nil,
                    fields: fields
                )
            )
            ordinal += 1
        }

        return CInitializerTableParseResult(descriptor: descriptor, entries: entries, diagnostics: diagnostics)
    }

    private func firstOpenBrace(after start: Int, in characters: [Character]) -> Int? {
        var index = start
        while index < characters.count {
            if characters[index] == "{" {
                return index
            }
            index += 1
        }
        return nil
    }

    private func matchingCloseBrace(from openOffset: Int, in characters: [Character]) -> Int? {
        var index = openOffset
        var depth = 0
        var state = ScannerState.normal

        while index < characters.count {
            let character = characters[index]
            let next = index + 1 < characters.count ? characters[index + 1] : nil
            updateState(&state, character: character, next: next, index: &index)

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

            index += 1
        }

        return nil
    }

    private func topLevelSegments(
        in characters: [Character],
        openOffset: Int,
        closeOffset: Int
    ) -> [(start: Int, end: Int)] {
        var segments: [(start: Int, end: Int)] = []
        var segmentStart = openOffset + 1
        var index = openOffset + 1
        var depth = 0
        var state = ScannerState.normal

        while index < closeOffset {
            let character = characters[index]
            let next = index + 1 < characters.count ? characters[index + 1] : nil
            updateState(&state, character: character, next: next, index: &index)

            if state == .normal {
                if character == "{" {
                    depth += 1
                } else if character == "}" {
                    depth = max(0, depth - 1)
                } else if character == "," && depth == 0 {
                    segments.append((segmentStart, index))
                    segmentStart = index + 1
                }
            }

            index += 1
        }

        if segmentStart < closeOffset {
            segments.append((segmentStart, closeOffset))
        }
        return segments
    }

    private func trimmedBounds(
        for segment: (start: Int, end: Int),
        in characters: [Character]
    ) -> (start: Int, end: Int)? {
        var start = segment.start
        var end = segment.end
        while start < end, characters[start].isWhitespace {
            start += 1
        }
        while end > start, characters[end - 1].isWhitespace {
            end -= 1
        }
        guard start < end else { return nil }
        return (start, end)
    }

    private func symbol(for body: String, ordinal: Int) -> String {
        if descriptor.entryStyle == .bracketed, let symbol = bracketedSymbol(in: body) {
            return symbol
        }

        if
            descriptor.entryStyle == .positional,
            let idField = descriptor.idField,
            let idValue = CFieldExtractor.fields(in: body)[idField],
            !idValue.isEmpty
        {
            return idValue
        }

        return "\(descriptor.tableSymbol)[\(ordinal)]"
    }

    private func bracketedSymbol(in body: String) -> String? {
        guard
            let open = body.firstIndex(of: "["),
            let close = body[open...].firstIndex(of: "]")
        else {
            return nil
        }

        let symbol = body[body.index(after: open)..<close]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return symbol.isEmpty ? nil : symbol
    }

    private func unsupportedShapeDiagnostic(for body: String, ordinal: Int, span: SourceSpan) -> Diagnostic? {
        guard descriptor.entryStyle == .bracketed, bracketedSymbol(in: body) == nil else {
            return nil
        }

        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { return nil }
        return Diagnostic(
            severity: .warning,
            code: "TABLE_ENTRY_UNSUPPORTED_SHAPE",
            message: "Bracketed entry \(descriptor.tableSymbol)[\(ordinal)] does not expose a [SYMBOL] designator; preserving raw source with a fallback identity.",
            span: span
        )
    }
}

private enum CFieldExtractor {
    static func fields(in text: String) -> [String: String] {
        guard let characters = initializerContent(in: text) else { return [:] }
        var fields: [String: String] = [:]
        var index = 0
        var depth = 0
        var state = ScannerState.normal

        while index < characters.count {
            let character = characters[index]
            let next = index + 1 < characters.count ? characters[index + 1] : nil
            updateState(&state, character: character, next: next, index: &index)

            if state == .normal {
                if character == "{" || character == "(" || character == "[" {
                    depth += 1
                    index += 1
                    continue
                } else if character == "}" || character == ")" || character == "]" {
                    depth = max(0, depth - 1)
                    index += 1
                    continue
                }
            }

            guard state == .normal, depth == 0, character == "." else {
                index += 1
                continue
            }
            let nameStart = index + 1
            var nameEnd = nameStart
            while nameEnd < characters.count, isIdentifier(characters[nameEnd]) {
                nameEnd += 1
            }
            guard nameEnd > nameStart else {
                index += 1
                continue
            }

            var cursor = nameEnd
            while cursor < characters.count, characters[cursor].isWhitespace {
                cursor += 1
            }
            guard cursor < characters.count, characters[cursor] == "=" else {
                index += 1
                continue
            }
            cursor += 1
            while cursor < characters.count, characters[cursor].isWhitespace {
                cursor += 1
            }

            let valueStart = cursor
            var valueEnd = cursor
            var depth = 0
            var state = ScannerState.normal

            while valueEnd < characters.count {
                let character = characters[valueEnd]
                let next = valueEnd + 1 < characters.count ? characters[valueEnd + 1] : nil
                updateState(&state, character: character, next: next, index: &valueEnd)

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

                valueEnd += 1
            }

            let name = String(characters[nameStart..<nameEnd])
            let value = String(characters[valueStart..<valueEnd])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            fields[name] = value
            index = max(valueEnd, index + 1)
        }

        return fields
    }

    private static func initializerContent(in text: String) -> [Character]? {
        let characters = Array(text)
        guard !characters.isEmpty else { return nil }

        let equals = firstEquals(in: characters)
        let firstOpen = firstOpenBrace(after: 0, in: characters)
        let open: Int?
        if let firstOpen, let equals, firstOpen < equals {
            open = firstOpen
        } else if let firstOpen, equals == nil {
            open = firstOpen
        } else if let equals {
            open = firstOpenBrace(after: equals + 1, in: characters)
        } else {
            open = firstOpen
        }

        guard
            let open,
            let close = matchingCloseBrace(from: open, in: characters),
            open + 1 <= close
        else {
            return nil
        }

        return Array(characters[(open + 1)..<close])
    }

    private static func firstEquals(in characters: [Character]) -> Int? {
        var index = 0
        var state = ScannerState.normal

        while index < characters.count {
            let character = characters[index]
            let next = index + 1 < characters.count ? characters[index + 1] : nil
            updateState(&state, character: character, next: next, index: &index)
            if state == .normal, character == "=" {
                return index
            }
            index += 1
        }
        return nil
    }

    private static func firstOpenBrace(after start: Int, in characters: [Character]) -> Int? {
        var index = start
        var state = ScannerState.normal

        while index < characters.count {
            let character = characters[index]
            let next = index + 1 < characters.count ? characters[index + 1] : nil
            updateState(&state, character: character, next: next, index: &index)
            if state == .normal, character == "{" {
                return index
            }
            index += 1
        }
        return nil
    }

    private static func matchingCloseBrace(from openOffset: Int, in characters: [Character]) -> Int? {
        var index = openOffset
        var depth = 0
        var state = ScannerState.normal

        while index < characters.count {
            let character = characters[index]
            let next = index + 1 < characters.count ? characters[index + 1] : nil
            updateState(&state, character: character, next: next, index: &index)

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

            index += 1
        }

        return nil
    }

    private static func isIdentifier(_ character: Character) -> Bool {
        character == "_" || character.isLetter || character.isNumber
    }
}

private enum ScriptSourceIndexScanner {
    static func scriptRecords(in text: String, relativePath: String) -> [SourceIndexRecord] {
        labelBlocks(in: text, relativePath: relativePath).map { block in
            let commands = commandNames(in: block.body)
            let textRefs = symbolTokens(in: block.body).filter { token in
                token.hasPrefix("gText_") || token.hasPrefix("Text_")
            }
            return SourceIndexRecord(
                id: "scripts:\(relativePath):\(block.label)",
                module: .scripts,
                title: block.label,
                subtitle: relativePath,
                sourceSpan: block.span,
                tags: ["script", "read-only"],
                facts: [
                    SourceIndexFact(label: "Commands", value: "\(commands.count)"),
                    SourceIndexFact(label: "Text Refs", value: "\(Set(textRefs).count)"),
                    SourceIndexFact(label: "Lines", value: "\(block.span.startLine)-\(block.span.endLine)")
                ],
                preview: block.body.components(separatedBy: .newlines).prefix(12).joined(separator: "\n")
            )
        }
    }

    static func textRecords(
        in text: String,
        relativePath: String
    ) -> (records: [SourceIndexRecord], diagnostics: [Diagnostic]) {
        var allDiagnostics: [Diagnostic] = []
        let records = labelBlocks(in: text, relativePath: relativePath).compactMap { block -> SourceIndexRecord? in
            let stringLines = block.body.components(separatedBy: .newlines).filter { line in
                line.trimmingCharacters(in: .whitespaces).hasPrefix(".string")
            }
            guard !stringLines.isEmpty else { return nil }

            let diagnostics = sourceTextDiagnostics(for: block, stringLines: stringLines)
            allDiagnostics.append(contentsOf: diagnostics)
            return SourceIndexRecord(
                id: "text:\(relativePath):\(block.label)",
                module: .text,
                title: block.label,
                subtitle: relativePath,
                sourceSpan: block.span,
                tags: ["text", "read-only"],
                facts: [
                    SourceIndexFact(label: "String Lines", value: "\(stringLines.count)"),
                    SourceIndexFact(label: "Characters", value: "\(stringLines.joined().count)"),
                    SourceIndexFact(label: "Lines", value: "\(block.span.startLine)-\(block.span.endLine)")
                ],
                preview: stringLines.prefix(8).joined(separator: "\n"),
                diagnostics: diagnostics
            )
        }
        return (records, allDiagnostics)
    }

    private static func sourceTextDiagnostics(
        for block: LabelBlock,
        stringLines: [String],
        maxLineLength: Int = 68
    ) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        let lines = block.body.components(separatedBy: .newlines)

        for (offset, line) in lines.enumerated() where line.count > maxLineLength {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "TEXT_LINE_LONG",
                    message: "Line exceeds \(maxLineLength) characters.",
                    span: SourceSpan(
                        relativePath: block.span.relativePath,
                        startLine: block.span.startLine + offset,
                        startColumn: maxLineLength + 1
                    )
                )
            )
        }

        if !stringLines.contains(where: { $0.contains("$") }) {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "TEXT_TERMINATOR_MISSING",
                    message: "Text block has no $ terminator.",
                    span: block.span
                )
            )
        }

        return diagnostics
    }

    private static func commandNames(in body: String) -> [String] {
        body.components(separatedBy: .newlines).compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard
                !trimmed.isEmpty,
                !trimmed.hasPrefix("@"),
                !trimmed.hasSuffix("::")
            else {
                return nil
            }
            return trimmed.split(whereSeparator: { $0.isWhitespace }).first.map(String.init)
        }
    }
}

private struct TrainerPartyIndexScanner {
    static func records(in text: String, relativePath: String) -> [SourceIndexRecord] {
        let lines = text.components(separatedBy: .newlines)
        var records: [SourceIndexRecord] = []
        var currentLabel: String?
        var currentStart = 0

        for (index, line) in lines.enumerated() {
            guard let label = trainerHeader(line) else { continue }
            if let currentLabel {
                records.append(record(label: currentLabel, start: currentStart, end: index, lines: lines, relativePath: relativePath))
            }
            currentLabel = label
            currentStart = index
        }

        if let currentLabel {
            records.append(record(label: currentLabel, start: currentStart, end: lines.count, lines: lines, relativePath: relativePath))
        }
        return records
    }

    private static func trainerHeader(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("=== "), trimmed.hasSuffix(" ===") else { return nil }
        return trimmed
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private static func record(
        label: String,
        start: Int,
        end: Int,
        lines: [String],
        relativePath: String
    ) -> SourceIndexRecord {
        let body = lines[start..<end].joined(separator: "\n")
        let pokemonCount = body.components(separatedBy: .newlines).filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return !trimmed.isEmpty
                && !trimmed.contains(":")
                && !trimmed.hasPrefix("===")
                && !trimmed.hasPrefix("- ")
                && !trimmed.hasPrefix("/*")
                && !trimmed.hasPrefix("*")
        }.count

        return SourceIndexRecord(
            id: "trainers:\(relativePath):\(label)",
            module: .trainers,
            title: label,
            subtitle: relativePath,
            sourceSpan: SourceSpan(relativePath: relativePath, startLine: start + 1, endLine: max(start + 1, end)),
            tags: ["trainer", "party"],
            facts: [
                SourceIndexFact(label: "Party Mons", value: "\(pokemonCount)"),
                SourceIndexFact(label: "Lines", value: "\(start + 1)-\(max(start + 1, end))")
            ],
            preview: body.components(separatedBy: .newlines).prefix(12).joined(separator: "\n")
        )
    }
}

private struct LabelBlock {
    let label: String
    let body: String
    let span: SourceSpan
}

private func labelBlocks(in text: String, relativePath: String) -> [LabelBlock] {
    let lines = text.components(separatedBy: .newlines)
    var blocks: [LabelBlock] = []
    var currentLabel: String?
    var currentStart = 0

    for (index, line) in lines.enumerated() {
        guard let label = sourceLabel(line) else { continue }
        if let currentLabel {
            let body = lines[currentStart..<index].joined(separator: "\n")
            blocks.append(
                LabelBlock(
                    label: currentLabel,
                    body: body,
                    span: SourceSpan(relativePath: relativePath, startLine: currentStart + 1, endLine: max(currentStart + 1, index))
                )
            )
        }
        currentLabel = label
        currentStart = index
    }

    if let currentLabel {
        let body = lines[currentStart..<lines.count].joined(separator: "\n")
        blocks.append(
            LabelBlock(
                label: currentLabel,
                body: body,
                span: SourceSpan(relativePath: relativePath, startLine: currentStart + 1, endLine: max(currentStart + 1, lines.count))
            )
        )
    }

    return blocks
}

private func sourceLabel(_ line: String) -> String? {
    let trimmed = line.trimmingCharacters(in: .whitespaces)
    guard trimmed.hasSuffix("::") else { return nil }
    let label = String(trimmed.dropLast(2))
    guard label.allSatisfy({ $0 == "_" || $0.isLetter || $0.isNumber }) else { return nil }
    return label
}

private func symbolTokens(in text: String) -> [String] {
    text.split { character in
        !(character == "_" || character.isLetter || character.isNumber)
    }.map(String.init)
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

private func lineNumber(containing needle: String, in text: String) -> Int? {
    guard let range = text.range(of: needle) else { return nil }
    return lineNumber(at: text.distance(from: text.startIndex, to: range.lowerBound), in: text)
}

private func lineNumber(at offset: Int, in text: String) -> Int {
    var line = 1
    for (index, character) in text.enumerated() {
        if index >= offset {
            break
        }
        if character == "\n" {
            line += 1
        }
    }
    return line
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

private enum ScannerState: Equatable {
    case normal
    case string
    case character
    case lineComment
    case blockComment
}

private func updateState(
    _ state: inout ScannerState,
    character: Character,
    next: Character?,
    index: inout Int
) {
    switch state {
    case .normal:
        if character == "/", next == "/" {
            state = .lineComment
            index += 1
        } else if character == "/", next == "*" {
            state = .blockComment
            index += 1
        } else if character == "\"" {
            state = .string
        } else if character == "'" {
            state = .character
        }
    case .string:
        if character == "\\" {
            index += 1
        } else if character == "\"" {
            state = .normal
        }
    case .character:
        if character == "\\" {
            index += 1
        } else if character == "'" {
            state = .normal
        }
    case .lineComment:
        if character == "\n" {
            state = .normal
        }
    case .blockComment:
        if character == "*", next == "/" {
            state = .normal
            index += 1
        }
    }
}

private func lineNumberMap(for characters: [Character]) -> [Int] {
    var line = 1
    return characters.map { character in
        defer {
            if character == "\n" {
                line += 1
            }
        }
        return line
    }
}
