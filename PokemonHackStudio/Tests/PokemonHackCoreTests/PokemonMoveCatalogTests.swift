import XCTest
@testable import PokemonHackCore

final class PokemonMoveCatalogTests: XCTestCase {
    func testMoveCatalogBuildsReadOnlyMoveDetailsAndMemberships() throws {
        let root = try temporaryRoot()
        try write(
            """
            #define MOVE_NONE 0
            #define MOVE_TACKLE 1
            #define MOVE_TACKLE 2
            #define MOVE_DUPLICATE_VALUE 1

            """,
            to: root.appendingPathComponent("include/constants/moves.h")
        )
        try write(
            """
            static const u16 gTutorMoves[] = {
                MOVE_TACKLE,
            };

            static const u16 gTutorLearnsets[][2] =
            {
                [SPECIES_TREECKO] = { MOVE_TACKLE, MOVE_NONE },
            };

            """,
            to: root.appendingPathComponent("src/data/pokemon/tutor_learnsets.h")
        )

        let sourceIndex = ProjectSourceIndex(
            root: SourceLocation(path: root.path, exists: true),
            profile: .pokeemerald,
            adapterID: "test.moves",
            adapterName: "Move Fixture",
            records: [
                moveRecord("MOVE_NONE", ordinal: 0, line: 3),
                moveRecord(
                    "MOVE_TACKLE",
                    ordinal: 1,
                    line: 8,
                    facts: [
                        SourceIndexFact(label: "Index", value: "1"),
                        SourceIndexFact(label: "effect", value: "EFFECT_HIT"),
                        SourceIndexFact(label: "power", value: "40"),
                        SourceIndexFact(label: "type", value: "TYPE_NORMAL"),
                        SourceIndexFact(label: "accuracy", value: "100"),
                        SourceIndexFact(label: "pp", value: "35"),
                        SourceIndexFact(label: "secondaryEffectChance", value: "0"),
                        SourceIndexFact(label: "target", value: "MOVE_TARGET_SELECTED"),
                        SourceIndexFact(label: "priority", value: "0"),
                        SourceIndexFact(label: "flags", value: "FLAG_MAKES_CONTACT | FLAG_PROTECT_AFFECTED")
                    ]
                ),
                SourceIndexRecord(
                    id: "learnsets:treecko",
                    module: .learnsets,
                    title: "SPECIES_TREECKO",
                    subtitle: "src/data/pokemon/level_up_learnsets.h",
                    sourceSpan: SourceSpan(relativePath: "src/data/pokemon/level_up_learnsets.h", startLine: 12),
                    preview: "LEVEL_UP_MOVE(1, MOVE_TACKLE)\nLEVEL_UP_MOVE(4, MOVE_ABSENT)\nLEVEL_UP_MOVE(0, MOVE_NONE)"
                ),
                SourceIndexRecord(
                    id: "tmhm:treecko",
                    module: .learnsets,
                    title: "SPECIES_TREECKO",
                    subtitle: "src/data/pokemon/tmhm_learnsets.h",
                    sourceSpan: SourceSpan(relativePath: "src/data/pokemon/tmhm_learnsets.h", startLine: 20),
                    preview: "[SPECIES_TREECKO] = { MOVE_TACKLE }"
                )
            ]
        )
        let speciesCatalog = ProjectSpeciesCatalog(
            root: SourceLocation(path: root.path, exists: true),
            profile: .pokeemerald,
            adapterID: "test.moves",
            adapterName: "Move Fixture",
            species: [
                SpeciesDetail(
                    speciesID: "SPECIES_TREECKO",
                    displayName: "Treecko",
                    sourceSpan: SourceSpan(relativePath: "src/data/pokemon/species_info.h", startLine: 5),
                    baseStats: SpeciesBaseStats(),
                    learnsets: SpeciesLearnsets(
                        levelUp: [
                            SpeciesLevelUpMove(
                                level: 1,
                                move: "MOVE_TACKLE",
                                sourceSpan: SourceSpan(relativePath: "src/data/pokemon/level_up_learnsets.h", startLine: 12)
                            )
                        ],
                        tmhm: [
                            SpeciesMoveReference(
                                move: "MOVE_TACKLE",
                                sourceSpan: SourceSpan(relativePath: "src/data/pokemon/tmhm_learnsets.h", startLine: 20)
                            )
                        ]
                    )
                )
            ],
            constants: [
                .tmhmMoves: [
                    SpeciesConstant(
                        group: .tmhmMoves,
                        symbol: "MOVE_TACKLE",
                        value: "TM01_TACKLE",
                        sourceSpan: SourceSpan(relativePath: "include/constants/items.h", startLine: 2)
                    )
                ]
            ]
        )

        let catalog = try ProjectMoveCatalogBuilder.build(
            index: projectIndex(root: root),
            sourceIndex: sourceIndex,
            speciesCatalog: speciesCatalog
        )

        XCTAssertEqual(catalog.summary.moveCount, 1)
        let tackle = try XCTUnwrap(catalog.moves.first)
        XCTAssertEqual(tackle.moveID, "MOVE_TACKLE")
        XCTAssertEqual(tackle.displayName, "Tackle")
        XCTAssertEqual(tackle.ordinal, 1)
        XCTAssertEqual(tackle.facts.first { $0.label == "power" }?.value, "40")
        XCTAssertEqual(tackle.flags, ["FLAG_MAKES_CONTACT", "FLAG_PROTECT_AFFECTED"])
        XCTAssertEqual(tackle.machineMemberships.first?.token, "TM01_TACKLE")
        XCTAssertEqual(tackle.tutorMemberships.first?.eligibleSpeciesIDs, ["SPECIES_TREECKO"])
        XCTAssertTrue(tackle.learnedBy.contains { $0.bucket == .levelUp && $0.level == 1 })
        XCTAssertEqual(Set(tackle.learnedBy.map(\.speciesID)), ["SPECIES_TREECKO"])
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "MOVE_CATALOG_CONSTANT_DUPLICATE" })
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "MOVE_CATALOG_MOVE_UNRESOLVED" })
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "MOVE_CATALOG_SENTINEL_EXCLUDED" })

        let encoded = try JSONEncoder().encode(catalog)
        XCTAssertFalse(encoded.isEmpty)
    }

    func testMoveCatalogReportsMissingMoveAndTutorTables() throws {
        let root = try temporaryRoot()
        let sourceIndex = ProjectSourceIndex(
            root: SourceLocation(path: root.path, exists: true),
            profile: .pokeemerald,
            adapterID: "test.moves",
            adapterName: "Move Fixture",
            records: []
        )

        let catalog = try ProjectMoveCatalogBuilder.build(
            index: projectIndex(root: root),
            sourceIndex: sourceIndex,
            speciesCatalog: nil
        )

        XCTAssertTrue(catalog.moves.isEmpty)
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "MOVE_CATALOG_MOVE_TABLE_MISSING" })
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "MOVE_CATALOG_TUTOR_TABLE_MISSING" })
    }

    private func temporaryRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonMoveCatalogTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: root)
        }
        return root
    }

    private func projectIndex(root: URL) -> ProjectIndex {
        ProjectIndex(
            root: SourceLocation(path: root.path, exists: true),
            profile: .pokeemerald,
            adapterID: "test.moves",
            adapterName: "Move Fixture",
            editorModules: [.pokemon, .moves],
            capabilities: [.diagnostics],
            writePolicy: .mutationPlanOnly,
            documents: []
        )
    }

    private func moveRecord(
        _ moveID: String,
        ordinal: Int,
        line: Int,
        facts: [SourceIndexFact]? = nil
    ) -> SourceIndexRecord {
        SourceIndexRecord(
            id: "moves:\(moveID)",
            module: .moves,
            title: moveID,
            subtitle: "src/data/battle_moves.h",
            sourceSpan: SourceSpan(relativePath: "src/data/battle_moves.h", startLine: line),
            facts: facts ?? [SourceIndexFact(label: "Index", value: "\(ordinal)")],
            preview: "[\(moveID)] = { .effect = EFFECT_HIT }"
        )
    }

    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
}
