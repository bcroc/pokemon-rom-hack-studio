import XCTest
@testable import PokemonHackCore

final class GraphicsAuthoringTests: XCTestCase {
    func testPlannerAppliesMetatileAttributeAndPaletteEditsWithBackups() throws {
        let root = try makeTemporaryProjectRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        try write(Data(repeating: 0, count: 32), to: root.appendingPathComponent("data/tilesets/general/metatiles.bin"))
        try write(Data(repeating: 0, count: 8), to: root.appendingPathComponent("data/tilesets/general/metatile_attributes.bin"))
        try write(Data(repeating: 0, count: 32), to: root.appendingPathComponent("data/tilesets/general/primary.gbapal"))
        try write(
            """
            JASC-PAL
            0100
            4
            0 0 0
            8 8 8
            16 16 16
            24 24 24

            """,
            to: root.appendingPathComponent("data/tilesets/general/secondary.pal")
        )

        let draft = GraphicsEditDraft(
            tilesetSymbol: "gTileset_General",
            operations: [
                .metatileTile(
                    path: "data/tilesets/general/metatiles.bin",
                    metatileLocalID: 1,
                    tileEntryIndex: 2,
                    rawTileValue: 0x1234
                ),
                .metatileAttribute(
                    path: "data/tilesets/general/metatile_attributes.bin",
                    metatileLocalID: 1,
                    rawAttributeValue: 0x0042
                ),
                .paletteColor(
                    path: "data/tilesets/general/primary.gbapal",
                    colorIndex: 2,
                    red: 248,
                    green: 0,
                    blue: 0
                ),
                .paletteColor(
                    path: "data/tilesets/general/secondary.pal",
                    colorIndex: 1,
                    red: 1,
                    green: 2,
                    blue: 3
                )
            ]
        )

        let plan = GraphicsMutationPlanner.plan(rootPath: root.path, draft: draft)
        XCTAssertTrue(plan.diagnostics.isEmpty)
        XCTAssertEqual(plan.changes.map(\.path), [
            "data/tilesets/general/metatile_attributes.bin",
            "data/tilesets/general/metatiles.bin",
            "data/tilesets/general/primary.gbapal",
            "data/tilesets/general/secondary.pal"
        ])
        XCTAssertTrue(plan.validateApplyability().isApplyable)

        let result = try GraphicsMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.count, 4)

        let metatiles = try Data(contentsOf: root.appendingPathComponent("data/tilesets/general/metatiles.bin"))
        XCTAssertEqual(metatiles[20], 0x34)
        XCTAssertEqual(metatiles[21], 0x12)

        let attributes = try Data(contentsOf: root.appendingPathComponent("data/tilesets/general/metatile_attributes.bin"))
        XCTAssertEqual(attributes[2], 0x42)
        XCTAssertEqual(attributes[3], 0x00)

        let gbaPalette = try Data(contentsOf: root.appendingPathComponent("data/tilesets/general/primary.gbapal"))
        XCTAssertEqual(gbaPalette[4], 0x1f)
        XCTAssertEqual(gbaPalette[5], 0x00)

        let jascPalette = try String(contentsOf: root.appendingPathComponent("data/tilesets/general/secondary.pal"), encoding: .utf8)
        XCTAssertTrue(jascPalette.contains("1 2 3"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))
    }

    func testApplyabilityBlocksExternalChangesAfterPreview() throws {
        let root = try makeTemporaryProjectRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let source = root.appendingPathComponent("data/tilesets/general/metatiles.bin")
        try write(Data(repeating: 0, count: 16), to: source)

        let draft = GraphicsEditDraft(
            tilesetSymbol: "gTileset_General",
            operations: [
                .metatileTile(
                    path: "data/tilesets/general/metatiles.bin",
                    metatileLocalID: 0,
                    tileEntryIndex: 0,
                    rawTileValue: 0x2222
                )
            ]
        )
        let plan = GraphicsMutationPlanner.plan(rootPath: root.path, draft: draft)
        try write(Data(repeating: 1, count: 16), to: source)

        let applyability = plan.validateApplyability()
        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(applyability.diagnostics.contains { $0.code == "GRAPHICS_APPLY_ORIGINAL_HASH_MISMATCH" })
    }

    func testPlannerBlocksGeneratedReferenceAndRomPaths() throws {
        let root = try makeTemporaryProjectRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        try write(Data(repeating: 0, count: 16), to: root.appendingPathComponent("build/metatiles.bin"))
        try write(Data(repeating: 0, count: 16), to: root.appendingPathComponent("references/upstream/metatiles.bin"))
        try write(Data(repeating: 0, count: 16), to: root.appendingPathComponent("exports/test.gba"))

        let draft = GraphicsEditDraft(
            tilesetSymbol: "gTileset_General",
            operations: [
                .metatileTile(path: "build/metatiles.bin", metatileLocalID: 0, tileEntryIndex: 0, rawTileValue: 1),
                .metatileTile(path: "references/upstream/metatiles.bin", metatileLocalID: 0, tileEntryIndex: 0, rawTileValue: 1),
                .metatileTile(path: "exports/test.gba", metatileLocalID: 0, tileEntryIndex: 0, rawTileValue: 1)
            ]
        )

        let plan = GraphicsMutationPlanner.plan(rootPath: root.path, draft: draft)
        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertEqual(plan.diagnostics.filter { $0.code == "GRAPHICS_SOURCE_PATH_BLOCKED" }.count, 3)
    }

    private func makeTemporaryProjectRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("pokemonhack-graphics-authoring-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func write(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }

    private func write(_ text: String, to url: URL) throws {
        try write(Data(text.utf8), to: url)
    }
}
