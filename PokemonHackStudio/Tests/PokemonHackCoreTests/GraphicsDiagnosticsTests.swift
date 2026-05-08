import XCTest
@testable import PokemonHackCore

final class GraphicsDiagnosticsTests: XCTestCase {
    private var temporaryDirectories: [GraphicsDiagnosticsTemporaryDirectory] = []

    override func tearDown() {
        temporaryDirectories.removeAll()
        super.tearDown()
    }

    func testGraphicsReportSummarizesTilesetArtifactsAndLayerModes() throws {
        let root = try makeGraphicsProject()
        let report = GraphicsDiagnosticsReportBuilder.build(index: projectIndex(root: root))

        XCTAssertTrue(report.isReadOnly)
        XCTAssertEqual(report.inventory.tileImageCount, 1)
        XCTAssertEqual(report.inventory.paletteFileCount, 2)
        XCTAssertEqual(report.inventory.metatileBinaryCount, 1)
        XCTAssertEqual(report.inventory.attributeBinaryCount, 1)
        XCTAssertEqual(report.inventory.animationDirectoryCount, 1)
        XCTAssertEqual(report.tilesets.count, 1)

        let tileset = try XCTUnwrap(report.tilesets.first)
        XCTAssertEqual(tileset.symbol, "gTileset_Test")
        XCTAssertEqual(tileset.metatileCount, 4)
        XCTAssertEqual(tileset.layerSummary.normal, 1)
        XCTAssertEqual(tileset.layerSummary.covered, 1)
        XCTAssertEqual(tileset.layerSummary.split, 1)
        XCTAssertEqual(tileset.layerSummary.unknown, 1)
        XCTAssertEqual(tileset.tileImage?.png?.width, 16)
        XCTAssertEqual(tileset.tileImage?.png?.paletteColorCount, 17)
        XCTAssertEqual(tileset.tileImage?.generatedRelativePath, "data/tilesets/primary/test/tiles.4bpp.lz")
        XCTAssertEqual(tileset.tileImage?.freshness, .generatedMissing)
        XCTAssertEqual(tileset.animation?.exists, true)
        XCTAssertEqual(tileset.animation?.fileCount, 1)
        XCTAssertEqual(report.conversionPlans.count, 1)
        XCTAssertEqual(tileset.conversionPlan.tilesetSymbol, "gTileset_Test")
        XCTAssertEqual(tileset.conversionPlan.expectedOutputs.sorted(), [
            "data/tilesets/primary/test/palettes/01.gbapal",
            "data/tilesets/primary/test/tiles.4bpp.lz"
        ])
        XCTAssertTrue(tileset.conversionPlan.provenanceRequired)
        XCTAssertTrue(tileset.conversionPlan.paletteFitSummary.contains("17 palette color"))
        XCTAssertTrue(report.diagnostics.contains { $0.code == "GRAPHICS_METATILE_LAYER_UNKNOWN" })
        XCTAssertTrue(report.diagnostics.contains { $0.code == "GRAPHICS_IMAGE_TOO_MANY_COLORS_FOR_4BPP" })
        XCTAssertTrue(report.diagnostics.contains { $0.code == "GRAPHICS_GENERATED_ARTIFACT_MISSING" })
        XCTAssertTrue(report.diagnostics.contains { $0.code == "GRAPHICS_15BIT_PRECISION_LOSS" })
        XCTAssertTrue(report.diagnostics.contains { $0.code == "GRAPHICS_CONVERSION_PALETTE_FIT_BLOCKED" })
    }

    func testGraphicsReportFlagsStaleGeneratedArtifacts() throws {
        let root = try makeGraphicsProject()
        let generatedTiles = root.appendingPathComponent("data/tilesets/primary/test/tiles.4bpp.lz")
        try write(Data([1, 2, 3, 4]), to: generatedTiles)
        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSince1970: 1)],
            ofItemAtPath: generatedTiles.path
        )

        let report = GraphicsDiagnosticsReportBuilder.build(index: projectIndex(root: root))
        let tileset = try XCTUnwrap(report.tilesets.first)

        XCTAssertEqual(tileset.tileImage?.generatedExists, true)
        XCTAssertEqual(tileset.tileImage?.freshness, .generatedStale)
        XCTAssertNotNil(tileset.tileImage?.sha1)
        XCTAssertTrue(report.diagnostics.contains { $0.code == "GRAPHICS_GENERATED_ARTIFACT_STALE" })
    }

    func testGraphicsReportPairsMissingGeneratedPalettesWithSourcePalettes() throws {
        let root = try makeGraphicsProject()
        try FileManager.default.removeItem(at: root.appendingPathComponent("data/tilesets/primary/test/palettes/00.gbapal"))
        try writeJASCPalette(
            colors: Array(repeating: (0, 0, 0), count: 16),
            to: root.appendingPathComponent("data/tilesets/primary/test/palettes/00.pal")
        )

        let report = GraphicsDiagnosticsReportBuilder.build(index: projectIndex(root: root))
        let tileset = try XCTUnwrap(report.tilesets.first)
        let palette = try XCTUnwrap(tileset.palettes.first { $0.generatedRelativePath == "data/tilesets/primary/test/palettes/00.gbapal" })

        XCTAssertEqual(palette.relativePath, "data/tilesets/primary/test/palettes/00.pal")
        XCTAssertEqual(palette.exists, true)
        XCTAssertEqual(palette.generatedExists, false)
        XCTAssertEqual(palette.freshness, .generatedMissing)
        XCTAssertEqual(palette.palette?.colorCount, 16)
    }

    func testGraphicsReportFlagsMissingAndUnexpectedPaletteInputs() throws {
        let root = try makeGraphicsProject()
        try FileManager.default.removeItem(at: root.appendingPathComponent("data/tilesets/primary/test/metatile_attributes.bin"))
        try writeJASCPalette(
            colors: [
                (0, 0, 0),
                (16, 16, 16),
                (24, 24, 24)
            ],
            to: root.appendingPathComponent("data/tilesets/primary/test/palettes/01.pal")
        )

        let report = GraphicsDiagnosticsReportBuilder.build(index: projectIndex(root: root))
        let tileset = try XCTUnwrap(report.tilesets.first)

        XCTAssertEqual(tileset.layerSummary.missing, 4)
        XCTAssertTrue(report.diagnostics.contains { $0.code == "GRAPHICS_METATILE_ATTRIBUTES_MISSING" })
        XCTAssertTrue(report.diagnostics.contains { $0.code == "GRAPHICS_PALETTE_COLOR_COUNT_UNEXPECTED" })
    }

    func testGraphicsInventoryFlagsSpacesAndUnsupportedSourceArtifacts() throws {
        let root = try makeGraphicsProject()
        try write(Data("design".utf8), to: root.appendingPathComponent("data/tilesets/primary/test/source art.psd"))

        let report = GraphicsDiagnosticsReportBuilder.build(index: projectIndex(root: root))

        XCTAssertEqual(report.inventory.pathsWithSpacesCount, 1)
        XCTAssertEqual(report.inventory.unsupportedSourceArtifactCount, 1)
        XCTAssertTrue(report.diagnostics.contains { $0.code == "GRAPHICS_PATH_CONTAINS_SPACES" })
        XCTAssertTrue(report.diagnostics.contains { $0.code == "GRAPHICS_UNSUPPORTED_SOURCE_ARTIFACT" })
    }

    func testGraphicsConversionPlanFindsNearbyCreditMetadata() throws {
        let root = try makeGraphicsProject()
        try write("Credit: local test asset\n", to: root.appendingPathComponent("data/tilesets/primary/test/credits.txt"))

        let report = GraphicsDiagnosticsReportBuilder.build(index: projectIndex(root: root))
        let plan = try XCTUnwrap(report.conversionPlans.first)

        XCTAssertEqual(plan.creditMetadataPaths, ["data/tilesets/primary/test/credits.txt"])
        XCTAssertTrue(plan.externalToolPlan.contains("Preview external conversion only"))
    }

    func testGraphicsImportPlanRequiresCreditAndPreviewsPaletteFit() throws {
        let project = try makeGraphicsImportProject()
        let package = try makeTemporaryRoot().appendingPathComponent("missing-credit")
        try writePNG(width: 16, height: 16, paletteColors: 17, to: package.appendingPathComponent("tiles.png"))
        try writeJASCPalette(colors: Array(repeating: (0, 0, 0), count: 16), to: package.appendingPathComponent("palettes/00.pal"))

        let plan = try GraphicsImportPackagePlanBuilder.build(projectPath: project.path, packagePath: package.path)

        XCTAssertEqual(plan.readiness, .blocked)
        XCTAssertTrue(plan.isPreviewOnly)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "GRAPHICS_IMPORT_PROVENANCE_MISSING" })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "GRAPHICS_IMPORT_PALETTE_TOO_LARGE" })
        XCTAssertEqual(plan.paletteFitPreviews.first { $0.sourceRelativePath == "tiles.png" }?.isReadyFor4bpp, false)
        XCTAssertTrue(plan.copyPlan.contains { $0.destinationRelativePath == "data/tilesets/imports/missing-credit/tiles.png" })
    }

    func testGraphicsImportPlanDetectsLayeredPackageAndCredits() throws {
        let project = try makeGraphicsImportProject()
        let package = try makeTemporaryRoot().appendingPathComponent("route-tiles")
        try write("Author: Local Fixture\nLicense: Test Only\n", to: package.appendingPathComponent("README.md"))
        try writePNG(width: 16, height: 16, paletteColors: 8, to: package.appendingPathComponent("top.png"))
        try writePNG(width: 16, height: 16, paletteColors: 8, to: package.appendingPathComponent("middle.png"))
        try write("id,behavior,layer\n0,MB_NORMAL,normal\n", to: package.appendingPathComponent("attributes.csv"))
        try write("// anim\n", to: package.appendingPathComponent("anim/water.c"))

        let plan = try GraphicsImportPackagePlanBuilder.build(projectPath: project.path, packagePath: package.path)

        XCTAssertEqual(plan.readiness, .ready)
        XCTAssertEqual(plan.creditMetadataPaths, ["README.md"])
        XCTAssertEqual(plan.layeredTilesetDryRun.detectedLayerPaths, ["middle.png", "top.png"])
        XCTAssertEqual(plan.layeredTilesetDryRun.missingLayerNames, ["bottom"])
        XCTAssertEqual(plan.layeredTilesetDryRun.attributesPath, "attributes.csv")
        XCTAssertEqual(plan.layeredTilesetDryRun.animationFileCount, 1)
        XCTAssertTrue(plan.layeredTilesetDryRun.expectedGeneratedOutputs.contains("data/tilesets/imports/route-tiles/metatiles.bin"))
    }

    private func makeGraphicsProject() throws -> URL {
        let root = try makeTemporaryRoot()
        try writeHeaders(to: root)
        try writeGraphicsRefs(to: root)
        try writeMetatileRefs(to: root)
        try write("#define NUM_METATILES_IN_PRIMARY 0x200\n#define NUM_METATILES_TOTAL 0x400\n", to: root.appendingPathComponent("include/fieldmap.h"))
        try writePNG(width: 16, height: 16, paletteColors: 17, to: root.appendingPathComponent("data/tilesets/primary/test/tiles.png"))
        try writeWords(Array(repeating: 0, count: 32), to: root.appendingPathComponent("data/tilesets/primary/test/metatiles.bin"))
        try writeWords([0x0000, 0x1000, 0x2000, 0x3000], to: root.appendingPathComponent("data/tilesets/primary/test/metatile_attributes.bin"))
        try write(Data([0, 0]), to: root.appendingPathComponent("data/tilesets/primary/test/palettes/00.gbapal"))
        try writeJASCPalette(
            colors: Array(repeating: (0, 0, 0), count: 15) + [(7, 15, 31)],
            to: root.appendingPathComponent("data/tilesets/primary/test/palettes/01.pal")
        )
        try write("// anim\n", to: root.appendingPathComponent("data/tilesets/primary/test/anim/water.c"))
        return root
    }

    private func makeGraphicsImportProject() throws -> URL {
        let root = try makeGraphicsProject()
        try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/pokenav"), withIntermediateDirectories: true)
        return root
    }

    private func projectIndex(root: URL) -> ProjectIndex {
        ProjectIndex(
            root: SourceLocation(path: root.path, exists: true),
            profile: .pokeemerald,
            adapterID: "test.graphics",
            adapterName: "Graphics Test",
            editorModules: [.graphics],
            capabilities: [.resourceIndex, .diagnostics],
            writePolicy: .mutationPlanOnly,
            documents: []
        )
    }

    private func makeTemporaryRoot() throws -> URL {
        let directory = GraphicsDiagnosticsTemporaryDirectory()
        temporaryDirectories.append(directory)
        let root = directory.url
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func writeHeaders(to root: URL) throws {
        try write(
            """
            const struct Tileset gTileset_Test = {
                .isCompressed = TRUE,
                .isSecondary = FALSE,
                .tiles = gTilesetTiles_Test,
                .palettes = gTilesetPalettes_Test,
                .metatiles = gMetatiles_Test,
                .metatileAttributes = gMetatileAttributes_Test,
                .callback = NULL,
            };
            """,
            to: root.appendingPathComponent("src/data/tilesets/headers.h")
        )
    }

    private func writeGraphicsRefs(to root: URL) throws {
        try write(
            """
            const u32 gTilesetTiles_Test[] = INCGFX_U32("data/tilesets/primary/test/tiles.4bpp.lz");
            const u16 gTilesetPalettes_Test[][16] =
            {
                INCBIN_U16("data/tilesets/primary/test/palettes/00.gbapal"),
                INCBIN_U16("data/tilesets/primary/test/palettes/01.pal"),
            };
            """,
            to: root.appendingPathComponent("src/data/tilesets/graphics.h")
        )
    }

    private func writeMetatileRefs(to root: URL) throws {
        try write(
            """
            const u16 gMetatiles_Test[] = INCBIN_U16("data/tilesets/primary/test/metatiles.bin");
            const u16 gMetatileAttributes_Test[] = INCBIN_U16("data/tilesets/primary/test/metatile_attributes.bin");
            """,
            to: root.appendingPathComponent("src/data/tilesets/metatiles.h")
        )
    }

    private func writeJASCPalette(colors: [(Int, Int, Int)], to url: URL) throws {
        let body = colors.map { "\($0.0) \($0.1) \($0.2)" }.joined(separator: "\n")
        try write("JASC-PAL\n0100\n\(colors.count)\n\(body)\n", to: url)
    }

    private func writePNG(width: UInt32, height: UInt32, paletteColors: Int, to url: URL) throws {
        var data = Data([137, 80, 78, 71, 13, 10, 26, 10])
        appendChunk("IHDR", payload: pngIHDR(width: width, height: height), to: &data)
        appendChunk("PLTE", payload: Data(repeating: 0, count: paletteColors * 3), to: &data)
        appendChunk("IEND", payload: Data(), to: &data)
        try write(data, to: url)
    }

    private func pngIHDR(width: UInt32, height: UInt32) -> Data {
        var data = Data()
        appendUInt32BE(width, to: &data)
        appendUInt32BE(height, to: &data)
        data.append(contentsOf: [8, 3, 0, 0, 0])
        return data
    }

    private func appendChunk(_ type: String, payload: Data, to data: inout Data) {
        appendUInt32BE(UInt32(payload.count), to: &data)
        data.append(Data(type.utf8))
        data.append(payload)
        appendUInt32BE(0, to: &data)
    }

    private func appendUInt32BE(_ value: UInt32, to data: inout Data) {
        data.append(UInt8((value >> 24) & 0xff))
        data.append(UInt8((value >> 16) & 0xff))
        data.append(UInt8((value >> 8) & 0xff))
        data.append(UInt8(value & 0xff))
    }

    private func writeWords(_ words: [UInt16], to url: URL) throws {
        var data = Data()
        for word in words {
            data.append(UInt8(word & 0xff))
            data.append(UInt8((word >> 8) & 0xff))
        }
        try write(data, to: url)
    }

    private func write(_ text: String, to url: URL) throws {
        try write(Data(text.utf8), to: url)
    }

    private func write(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }
}

private final class GraphicsDiagnosticsTemporaryDirectory {
    let url: URL

    init() {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pokemonhack-graphics-\(UUID().uuidString)")
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
