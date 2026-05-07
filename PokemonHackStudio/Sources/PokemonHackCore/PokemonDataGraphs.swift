import Foundation

public enum LearnsetBucket: String, Codable, Equatable, CaseIterable {
    case levelUp
    case tmhm
    case tutor
    case egg
    case allLearnables
    case other
}

public enum RelatedDataNodeKind: String, Codable, Equatable, CaseIterable {
    case species
    case move
    case learnset
    case evolution
    case pokedex
    case asset
}

public enum RelatedDataEdgeKind: String, Codable, Equatable, CaseIterable {
    case learnsMove
    case hasLearnset
    case evolvesTo
    case hasPokedexEntry
    case usesAsset
}

public struct MoveGraphMove: Codable, Equatable, Identifiable {
    public var id: String { moveID }

    public let moveID: String
    public let sourceSpan: SourceSpan
    public let facts: [SourceIndexFact]
    public let diagnostics: [Diagnostic]

    public init(moveID: String, sourceSpan: SourceSpan, facts: [SourceIndexFact] = [], diagnostics: [Diagnostic] = []) {
        self.moveID = moveID
        self.sourceSpan = sourceSpan
        self.facts = facts
        self.diagnostics = diagnostics
    }
}

public struct LearnsetGraphEntry: Codable, Equatable, Identifiable {
    public var id: String { "\(speciesID):\(bucket.rawValue):\(sourceSpan.relativePath):\(sourceSpan.startLine)" }

    public let speciesID: String
    public let bucket: LearnsetBucket
    public let moveIDs: [String]
    public let sourceSpan: SourceSpan
    public let diagnostics: [Diagnostic]

    public init(
        speciesID: String,
        bucket: LearnsetBucket,
        moveIDs: [String],
        sourceSpan: SourceSpan,
        diagnostics: [Diagnostic] = []
    ) {
        self.speciesID = speciesID
        self.bucket = bucket
        self.moveIDs = moveIDs
        self.sourceSpan = sourceSpan
        self.diagnostics = diagnostics
    }
}

public struct MoveGraph: Codable, Equatable {
    public let root: SourceLocation
    public let profile: GameProfile
    public let moves: [MoveGraphMove]
    public let learnsets: [LearnsetGraphEntry]
    public let diagnostics: [Diagnostic]

    public init(
        root: SourceLocation,
        profile: GameProfile,
        moves: [MoveGraphMove],
        learnsets: [LearnsetGraphEntry],
        diagnostics: [Diagnostic] = []
    ) {
        self.root = root
        self.profile = profile
        self.moves = moves
        self.learnsets = learnsets
        self.diagnostics = diagnostics
    }
}

public struct SpeciesGraphNode: Codable, Equatable, Identifiable {
    public var id: String { speciesID }

    public let speciesID: String
    public let sourceSpan: SourceSpan?
    public let facts: [SourceIndexFact]
    public let pokedexSpan: SourceSpan?
    public let evolutionSpan: SourceSpan?
    public let assetPaths: [String]
    public let diagnostics: [Diagnostic]

    public init(
        speciesID: String,
        sourceSpan: SourceSpan?,
        facts: [SourceIndexFact] = [],
        pokedexSpan: SourceSpan? = nil,
        evolutionSpan: SourceSpan? = nil,
        assetPaths: [String] = [],
        diagnostics: [Diagnostic] = []
    ) {
        self.speciesID = speciesID
        self.sourceSpan = sourceSpan
        self.facts = facts
        self.pokedexSpan = pokedexSpan
        self.evolutionSpan = evolutionSpan
        self.assetPaths = assetPaths
        self.diagnostics = diagnostics
    }
}

public struct SpeciesEvolutionEdge: Codable, Equatable, Identifiable {
    public var id: String { "\(fromSpeciesID)->\(toSpeciesID):\(method):\(sourceSpan.relativePath):\(sourceSpan.startLine)" }

    public let fromSpeciesID: String
    public let toSpeciesID: String
    public let method: String
    public let parameter: String?
    public let sourceSpan: SourceSpan

    public init(fromSpeciesID: String, toSpeciesID: String, method: String, parameter: String?, sourceSpan: SourceSpan) {
        self.fromSpeciesID = fromSpeciesID
        self.toSpeciesID = toSpeciesID
        self.method = method
        self.parameter = parameter
        self.sourceSpan = sourceSpan
    }
}

public struct RelatedDataNode: Codable, Equatable, Identifiable {
    public let id: String
    public let kind: RelatedDataNodeKind
    public let title: String
    public let sourceSpan: SourceSpan?

    public init(id: String, kind: RelatedDataNodeKind, title: String, sourceSpan: SourceSpan? = nil) {
        self.id = id
        self.kind = kind
        self.title = title
        self.sourceSpan = sourceSpan
    }
}

public struct RelatedDataEdge: Codable, Equatable, Identifiable {
    public var id: String { "\(kind.rawValue):\(fromID)->\(toID)" }

    public let fromID: String
    public let toID: String
    public let kind: RelatedDataEdgeKind
    public let sourceSpan: SourceSpan?

    public init(fromID: String, toID: String, kind: RelatedDataEdgeKind, sourceSpan: SourceSpan? = nil) {
        self.fromID = fromID
        self.toID = toID
        self.kind = kind
        self.sourceSpan = sourceSpan
    }
}

public struct SpeciesGraph: Codable, Equatable {
    public let root: SourceLocation
    public let profile: GameProfile
    public let species: [SpeciesGraphNode]
    public let evolutions: [SpeciesEvolutionEdge]
    public let relatedNodes: [RelatedDataNode]
    public let relatedEdges: [RelatedDataEdge]
    public let diagnostics: [Diagnostic]

    public init(
        root: SourceLocation,
        profile: GameProfile,
        species: [SpeciesGraphNode],
        evolutions: [SpeciesEvolutionEdge],
        relatedNodes: [RelatedDataNode],
        relatedEdges: [RelatedDataEdge],
        diagnostics: [Diagnostic] = []
    ) {
        self.root = root
        self.profile = profile
        self.species = species
        self.evolutions = evolutions
        self.relatedNodes = relatedNodes
        self.relatedEdges = relatedEdges
        self.diagnostics = diagnostics
    }
}

public enum MoveGraphBuilder {
    public static func build(
        index: ProjectIndex,
        sourceIndex: ProjectSourceIndex? = nil,
        fileManager: FileManager = .default
    ) throws -> MoveGraph {
        let sourceIndex = try sourceIndex ?? ProjectSourceIndexLoader.load(from: index, fileManager: fileManager)
        let moveRecords = sourceIndex.records.filter { $0.module == .moves }
        let learnsetRecords = sourceIndex.records.filter { $0.module == .learnsets }
        let moves = moveRecords.map {
            MoveGraphMove(moveID: normalizedMoveID($0.title), sourceSpan: $0.sourceSpan, facts: $0.facts, diagnostics: $0.diagnostics)
        }
        let moveIDs = Set(moves.map(\.moveID))
        var diagnostics = sourceIndex.diagnostics
        var learnsets: [LearnsetGraphEntry] = []

        for record in learnsetRecords {
            let moveRefs = uniqueSymbols(in: record.preview ?? "", prefix: "MOVE_")
            let missing = moveRefs.filter { !moveIDs.contains($0) }
            let recordDiagnostics = missing.prefix(8).map {
                Diagnostic(
                    severity: .warning,
                    code: "MOVE_GRAPH_MOVE_UNRESOLVED",
                    message: "\(record.title) references \($0), but that move is not indexed.",
                    span: record.sourceSpan
                )
            }
            diagnostics.append(contentsOf: recordDiagnostics)
            learnsets.append(
                LearnsetGraphEntry(
                    speciesID: normalizedSpeciesID(record.title),
                    bucket: bucket(for: record),
                    moveIDs: moveRefs,
                    sourceSpan: record.sourceSpan,
                    diagnostics: recordDiagnostics
                )
            )
        }

        return MoveGraph(
            root: sourceIndex.root,
            profile: sourceIndex.profile,
            moves: moves.sorted { $0.moveID < $1.moveID },
            learnsets: learnsets.sorted { $0.speciesID == $1.speciesID ? $0.bucket.rawValue < $1.bucket.rawValue : $0.speciesID < $1.speciesID },
            diagnostics: diagnostics
        )
    }

    private static func bucket(for record: SourceIndexRecord) -> LearnsetBucket {
        let path = record.sourceSpan.relativePath.lowercased()
        if path.contains("all_learnables") { return .allLearnables }
        if path.contains("tmhm") { return .tmhm }
        if path.contains("tutor") { return .tutor }
        if path.contains("egg") { return .egg }
        if path.contains("level_up") || path.contains("learnset") { return .levelUp }
        return .other
    }
}

public enum SpeciesGraphBuilder {
    public static func build(
        index: ProjectIndex,
        sourceIndex: ProjectSourceIndex? = nil,
        assetCatalog: GenIIIAssetCatalog? = nil,
        fileManager: FileManager = .default
    ) throws -> SpeciesGraph {
        let sourceIndex = try sourceIndex ?? ProjectSourceIndexLoader.load(from: index, fileManager: fileManager)
        let assets = assetCatalog ?? GenIIIAssetCatalogBuilder.build(index: index, sourceIndex: sourceIndex)
        let pokemonRecords = sourceIndex.records.filter { $0.module == .pokemon }
        let pokedexRecords = Dictionary(grouping: sourceIndex.records.filter { $0.module == .pokedex }, by: { normalizedSpeciesID($0.title) })
        let evolutionRecords = Dictionary(grouping: sourceIndex.records.filter { $0.module == .evolutions }, by: { normalizedSpeciesID($0.title) })
        let assetPathsBySpecies = speciesAssetPaths(from: assets)
        var diagnostics = sourceIndex.diagnostics + assets.diagnostics

        let nodes = pokemonRecords.map { record in
            let speciesID = normalizedSpeciesID(record.title)
            return SpeciesGraphNode(
                speciesID: speciesID,
                sourceSpan: record.sourceSpan,
                facts: record.facts,
                pokedexSpan: pokedexRecords[speciesID]?.first?.sourceSpan,
                evolutionSpan: evolutionRecords[speciesID]?.first?.sourceSpan,
                assetPaths: assetPathsBySpecies[speciesID] ?? [],
                diagnostics: record.diagnostics
            )
        }

        let speciesIDs = Set(nodes.map(\.speciesID))
        var evolutionEdges: [SpeciesEvolutionEdge] = []
        for record in sourceIndex.records where record.module == .evolutions {
            let from = normalizedSpeciesID(record.title)
            for edge in evolutionEdgesFromPreview(record.preview ?? "", from: from, sourceSpan: record.sourceSpan) {
                if !speciesIDs.contains(edge.toSpeciesID) {
                    diagnostics.append(
                        Diagnostic(
                            severity: .warning,
                            code: "SPECIES_GRAPH_EVOLUTION_TARGET_UNRESOLVED",
                            message: "\(from) evolves to \(edge.toSpeciesID), but that species is not indexed.",
                            span: edge.sourceSpan
                        )
                    )
                }
                evolutionEdges.append(edge)
            }
        }

        let moveGraph = try? MoveGraphBuilder.build(index: index, sourceIndex: sourceIndex, fileManager: fileManager)
        let relatedNodes = relatedNodesForSpecies(nodes, evolutions: evolutionEdges, moveGraph: moveGraph)
        let relatedEdges = relatedEdgesForSpecies(nodes, evolutions: evolutionEdges, moveGraph: moveGraph)

        return SpeciesGraph(
            root: sourceIndex.root,
            profile: sourceIndex.profile,
            species: nodes.sorted { $0.speciesID < $1.speciesID },
            evolutions: evolutionEdges,
            relatedNodes: relatedNodes,
            relatedEdges: relatedEdges,
            diagnostics: diagnostics
        )
    }

    private static func speciesAssetPaths(from catalog: GenIIIAssetCatalog) -> [String: [String]] {
        var paths: [String: [String]] = [:]
        for asset in catalog.assets {
            let path = asset.relativePath.lowercased()
            guard path.contains("graphics/pokemon") else { continue }
            for token in symbolWords(in: asset.relativePath) {
                let speciesID = "SPECIES_\(token.uppercased())"
                paths[speciesID, default: []].append(asset.relativePath)
            }
        }
        return paths
    }

    private static func evolutionEdgesFromPreview(_ preview: String, from: String, sourceSpan: SourceSpan) -> [SpeciesEvolutionEdge] {
        let tokens = tokens(in: preview)
        var edges: [SpeciesEvolutionEdge] = []
        for index in tokens.indices where tokens[index].hasPrefix("EVO_") {
            let method = tokens[index]
            let parameter = tokens.indices.contains(index + 1) ? tokens[index + 1] : nil
            guard let target = tokens.dropFirst(index + 1).first(where: { $0.hasPrefix("SPECIES_") }) else { continue }
            edges.append(SpeciesEvolutionEdge(fromSpeciesID: from, toSpeciesID: target, method: method, parameter: parameter, sourceSpan: sourceSpan))
        }
        return edges
    }

    private static func relatedNodesForSpecies(
        _ species: [SpeciesGraphNode],
        evolutions: [SpeciesEvolutionEdge],
        moveGraph: MoveGraph?
    ) -> [RelatedDataNode] {
        var nodes = species.map {
            RelatedDataNode(id: $0.speciesID, kind: .species, title: $0.speciesID, sourceSpan: $0.sourceSpan)
        }
        let indexedSpeciesIDs = Set(species.map(\.speciesID))
        let linkedSpeciesIDs = Set(evolutions.flatMap { [$0.fromSpeciesID, $0.toSpeciesID] } + (moveGraph?.learnsets.map(\.speciesID) ?? []))
        nodes.append(contentsOf: linkedSpeciesIDs.subtracting(indexedSpeciesIDs).sorted().map {
            RelatedDataNode(id: $0, kind: .species, title: $0)
        })
        for node in species {
            if let pokedexSpan = node.pokedexSpan {
                nodes.append(RelatedDataNode(id: "\(node.speciesID):pokedex", kind: .pokedex, title: "\(node.speciesID) Pokedex", sourceSpan: pokedexSpan))
            }
            for path in node.assetPaths {
                nodes.append(RelatedDataNode(id: path, kind: .asset, title: URL(fileURLWithPath: path).lastPathComponent, sourceSpan: SourceSpan(relativePath: path, startLine: 1)))
            }
        }
        nodes.append(contentsOf: (moveGraph?.learnsets ?? []).map {
            RelatedDataNode(id: $0.id, kind: .learnset, title: "\($0.speciesID) \($0.bucket.rawValue)", sourceSpan: $0.sourceSpan)
        })
        nodes.append(contentsOf: (moveGraph?.moves ?? []).map {
            RelatedDataNode(id: $0.moveID, kind: .move, title: $0.moveID, sourceSpan: $0.sourceSpan)
        })
        let indexedMoveIDs = Set((moveGraph?.moves ?? []).map(\.moveID))
        let linkedMoveIDs = Set((moveGraph?.learnsets ?? []).flatMap(\.moveIDs))
        nodes.append(contentsOf: linkedMoveIDs.subtracting(indexedMoveIDs).sorted().map {
            RelatedDataNode(id: $0, kind: .move, title: $0)
        })
        return uniqueRelatedNodes(nodes)
    }

    private static func relatedEdgesForSpecies(_ species: [SpeciesGraphNode], evolutions: [SpeciesEvolutionEdge], moveGraph: MoveGraph?) -> [RelatedDataEdge] {
        var edges = evolutions.map {
            RelatedDataEdge(fromID: $0.fromSpeciesID, toID: $0.toSpeciesID, kind: .evolvesTo, sourceSpan: $0.sourceSpan)
        }
        for node in species {
            if let pokedexSpan = node.pokedexSpan {
                edges.append(RelatedDataEdge(fromID: node.speciesID, toID: "\(node.speciesID):pokedex", kind: .hasPokedexEntry, sourceSpan: pokedexSpan))
            }
            for path in node.assetPaths {
                edges.append(RelatedDataEdge(fromID: node.speciesID, toID: path, kind: .usesAsset, sourceSpan: SourceSpan(relativePath: path, startLine: 1)))
            }
        }
        for learnset in moveGraph?.learnsets ?? [] {
            edges.append(RelatedDataEdge(fromID: learnset.speciesID, toID: learnset.id, kind: .hasLearnset, sourceSpan: learnset.sourceSpan))
            for move in learnset.moveIDs {
                edges.append(RelatedDataEdge(fromID: learnset.speciesID, toID: move, kind: .learnsMove, sourceSpan: learnset.sourceSpan))
            }
        }
        return uniqueRelatedEdges(edges)
    }

    private static func uniqueRelatedNodes(_ nodes: [RelatedDataNode]) -> [RelatedDataNode] {
        var seen: Set<String> = []
        return nodes.filter { seen.insert($0.id).inserted }
    }

    private static func uniqueRelatedEdges(_ edges: [RelatedDataEdge]) -> [RelatedDataEdge] {
        var seen: Set<String> = []
        return edges.filter { seen.insert($0.id).inserted }
    }
}

private func normalizedMoveID(_ value: String) -> String {
    value.hasPrefix("MOVE_") ? value : "MOVE_\(value)"
}

private func normalizedSpeciesID(_ value: String) -> String {
    value.hasPrefix("SPECIES_") ? value : "SPECIES_\(value)"
}

private func uniqueSymbols(in text: String, prefix: String) -> [String] {
    var seen: Set<String> = []
    var values: [String] = []
    for token in tokens(in: text) where token.hasPrefix(prefix) && token != "\(prefix)NONE" {
        if seen.insert(token).inserted {
            values.append(token)
        }
    }
    return values
}

private func tokens(in text: String) -> [String] {
    text.split { character in
        !(character == "_" || character.isLetter || character.isNumber)
    }.map(String.init)
}

private func symbolWords(in path: String) -> [String] {
    path.split(separator: "/")
        .map(String.init)
        .filter { !$0.contains(".") && !$0.isEmpty }
}
