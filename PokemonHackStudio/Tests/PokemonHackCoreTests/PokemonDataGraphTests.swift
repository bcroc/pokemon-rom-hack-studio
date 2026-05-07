import XCTest
@testable import PokemonHackCore

final class PokemonDataGraphTests: XCTestCase {
    func testMoveGraphBuildsTypedLearnsetBucketsAndDiagnostics() throws {
        let sourceIndex = ProjectSourceIndex(
            root: SourceLocation(path: "/tmp/graphs", exists: true),
            profile: .pokeemerald,
            adapterID: "test.graphs",
            adapterName: "Graphs",
            records: [
                SourceIndexRecord(
                    id: "move-pound",
                    module: .moves,
                    title: "MOVE_POUND",
                    subtitle: "src/data/battle_moves.h",
                    sourceSpan: SourceSpan(relativePath: "src/data/battle_moves.h", startLine: 1)
                ),
                SourceIndexRecord(
                    id: "learnset-treecko",
                    module: .learnsets,
                    title: "SPECIES_TREECKO",
                    subtitle: "src/data/pokemon/level_up_learnset_pointers.h",
                    sourceSpan: SourceSpan(relativePath: "src/data/pokemon/level_up_learnset_pointers.h", startLine: 5),
                    preview: "LEVEL_UP_MOVE(1, MOVE_POUND)\nLEVEL_UP_MOVE(4, MOVE_ABSENT)"
                )
            ]
        )

        let graph = try MoveGraphBuilder.build(index: projectIndex(), sourceIndex: sourceIndex)

        XCTAssertEqual(graph.moves.map(\.moveID), ["MOVE_POUND"])
        XCTAssertEqual(graph.learnsets.first?.bucket, .levelUp)
        XCTAssertEqual(graph.learnsets.first?.moveIDs, ["MOVE_POUND", "MOVE_ABSENT"])
        XCTAssertTrue(graph.diagnostics.contains { $0.code == "MOVE_GRAPH_MOVE_UNRESOLVED" })
    }

    func testSpeciesGraphBuildsEvolutionAndRelatedEdges() throws {
        let sourceIndex = ProjectSourceIndex(
            root: SourceLocation(path: "/tmp/graphs", exists: true),
            profile: .pokeemerald,
            adapterID: "test.graphs",
            adapterName: "Graphs",
            records: [
                SourceIndexRecord(
                    id: "species-treecko",
                    module: .pokemon,
                    title: "SPECIES_TREECKO",
                    subtitle: "src/data/pokemon/species_info.h",
                    sourceSpan: SourceSpan(relativePath: "src/data/pokemon/species_info.h", startLine: 3)
                ),
                SourceIndexRecord(
                    id: "species-grovyle",
                    module: .pokemon,
                    title: "SPECIES_GROVYLE",
                    subtitle: "src/data/pokemon/species_info.h",
                    sourceSpan: SourceSpan(relativePath: "src/data/pokemon/species_info.h", startLine: 20)
                ),
                SourceIndexRecord(
                    id: "evo-treecko",
                    module: .evolutions,
                    title: "SPECIES_TREECKO",
                    subtitle: "src/data/pokemon/evolution.h",
                    sourceSpan: SourceSpan(relativePath: "src/data/pokemon/evolution.h", startLine: 7),
                    preview: "{{EVO_LEVEL, 16, SPECIES_GROVYLE}}"
                ),
                SourceIndexRecord(
                    id: "dex-treecko",
                    module: .pokedex,
                    title: "SPECIES_TREECKO",
                    subtitle: "src/data/pokemon/pokedex_entries.h",
                    sourceSpan: SourceSpan(relativePath: "src/data/pokemon/pokedex_entries.h", startLine: 9)
                )
            ]
        )
        let assetCatalog = GenIIIAssetCatalog(
            root: SourceLocation(path: "/tmp/graphs", exists: true),
            profile: .pokeemerald,
            adapterID: "test.graphs",
            adapterName: "Graphs",
            assets: [
                GenIIIAsset(
                    id: "graphics-treecko",
                    title: "treecko.png",
                    subtitle: "Pokemon sprite",
                    relativePath: "graphics/pokemon/treecko/normal.png",
                    category: .graphics,
                    kind: "sourceInventory",
                    role: .source
                )
            ]
        )

        let graph = try SpeciesGraphBuilder.build(index: projectIndex(), sourceIndex: sourceIndex, assetCatalog: assetCatalog)

        XCTAssertTrue(graph.species.contains { $0.speciesID == "SPECIES_TREECKO" && $0.pokedexSpan != nil })
        XCTAssertTrue(graph.evolutions.contains { $0.fromSpeciesID == "SPECIES_TREECKO" && $0.toSpeciesID == "SPECIES_GROVYLE" })
        XCTAssertTrue(graph.relatedNodes.contains { $0.id == "SPECIES_TREECKO:pokedex" && $0.kind == .pokedex })
        XCTAssertTrue(graph.relatedNodes.contains { $0.id == "graphics/pokemon/treecko/normal.png" && $0.kind == .asset })
        XCTAssertTrue(graph.relatedEdges.contains { $0.kind == .evolvesTo })
        XCTAssertTrue(graph.relatedEdges.contains { $0.kind == .hasPokedexEntry })
        let relatedNodeIDs = Set(graph.relatedNodes.map(\.id))
        XCTAssertTrue(graph.relatedEdges.allSatisfy { relatedNodeIDs.contains($0.fromID) && relatedNodeIDs.contains($0.toID) })
    }

    private func projectIndex() -> ProjectIndex {
        ProjectIndex(
            root: SourceLocation(path: "/tmp/graphs", exists: true),
            profile: .pokeemerald,
            adapterID: "test.graphs",
            adapterName: "Graphs",
            editorModules: [.pokemon, .moves],
            capabilities: [.diagnostics],
            writePolicy: .mutationPlanOnly,
            documents: []
        )
    }
}
