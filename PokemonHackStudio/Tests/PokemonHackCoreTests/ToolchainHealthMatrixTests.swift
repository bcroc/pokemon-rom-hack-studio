import XCTest
@testable import PokemonHackCore

final class ToolchainHealthMatrixTests: XCTestCase {
    private var temporaryDirectories: [ToolchainHealthTemporaryDirectory] = []

    override func tearDown() {
        temporaryDirectories.removeAll()
        super.tearDown()
    }

    func testHealthMatrixReportsPreviewOnlyExternalToolsROMHeaderAndGeneratedOutputs() throws {
        let root = try makeTemporaryRoot()
        try write(
            """
            TITLE       := POKEMON EMER
            GAME_CODE   := BPEE
            MAKER_CODE  := 01
            REVISION    := 0
            \t$(FIX) $@ -t"$(TITLE)" -c$(GAME_CODE) -m$(MAKER_CODE) -r$(REVISION) --silent
            """,
            to: root.appendingPathComponent("Makefile")
        )
        try write("// header\n", to: root.appendingPathComponent("src/rom_header_gf.c"))
        try write(gbaROM(title: "POKEMON EMER", gameCode: "BPEE", makerCode: "01", revision: 0), to: root.appendingPathComponent("pokeemerald.gba"))

        let index = makeIndex(
            root: root,
            generatedOutputs: [
                SourceDocument(relativePath: "*.gba", kind: .generated, role: .artifact, exists: false)
            ],
            buildTargets: [
                BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
            ]
        )
        let buildReport = BuildValidationReportBuilder.build(index: index, toolResolver: availableTools(["make": "/usr/bin/make"]))
        let playtestReport = PlaytestHandoffReportBuilder.build(index: index, toolResolver: availableTools(["mgba": "/Applications/mGBA.app"]))

        let report = ToolchainHealthMatrixBuilder.build(
            index: index,
            toolResolver: availableTools(["make": "/usr/bin/make", "mgba": "/Applications/mGBA.app"]),
            buildReport: buildReport,
            playtestReport: playtestReport
        )

        XCTAssertTrue(report.isPreviewOnly)
        XCTAssertTrue(report.diagnostics.contains { $0.code == "TOOLCHAIN_HEALTH_PREVIEW_ONLY" })
        XCTAssertEqual(report.rows.first { $0.id == "external:make" }?.status, .ready)
        XCTAssertEqual(report.rows.first { $0.id == "rom-header:configuration" }?.status, .ready)
        XCTAssertEqual(report.rows.first { $0.id == "rom-header:emerald-build" }?.status, .ready)
        XCTAssertEqual(report.rows.first { $0.id == "generated:adapter-outputs" }?.status, .ready)
    }

    func testHealthMatrixWarnsWhenBuiltROMHeaderDiffersFromTargetExpectation() throws {
        let root = try makeTemporaryRoot()
        try write(
            """
            TITLE       := POKEMON EMER
            GAME_CODE   := BPEE
            MAKER_CODE  := 01
            REVISION    := 0
            \t$(FIX) $@ -t"$(TITLE)" -c$(GAME_CODE) -m$(MAKER_CODE) -r$(REVISION) --silent
            """,
            to: root.appendingPathComponent("Makefile")
        )
        try write("// header\n", to: root.appendingPathComponent("src/rom_header_gf.c"))
        try write(gbaROM(title: "POKEMON EMER", gameCode: "BAD!", makerCode: "01", revision: 0), to: root.appendingPathComponent("pokeemerald.gba"))

        let index = makeIndex(
            root: root,
            buildTargets: [
                BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
            ]
        )
        let buildReport = BuildValidationReportBuilder.build(index: index, toolResolver: availableTools(["make": "/usr/bin/make"]))
        let playtestReport = PlaytestHandoffReportBuilder.build(index: index, toolResolver: availableTools(["mgba": "/Applications/mGBA.app"]))

        let report = ToolchainHealthMatrixBuilder.build(
            index: index,
            toolResolver: availableTools(["make": "/usr/bin/make", "mgba": "/Applications/mGBA.app"]),
            buildReport: buildReport,
            playtestReport: playtestReport
        )

        let headerRow = try XCTUnwrap(report.rows.first { $0.id == "rom-header:emerald-build" })
        XCTAssertEqual(headerRow.status, .warning)
        XCTAssertTrue(report.diagnostics.contains { $0.code == "ROM_HEADER_MISMATCH" })
    }

    func testHealthMatrixSummarizesGraphicsConversionPrerequisitesAndGeneratedFreshness() throws {
        let root = try makeTemporaryRoot()
        try write(
            """
            TITLE       := POKEMON EMER
            GAME_CODE   := BPEE
            MAKER_CODE  := 01
            REVISION    := 0
            \t$(FIX) $@ -t"$(TITLE)" -c$(GAME_CODE) -m$(MAKER_CODE) -r$(REVISION) --silent
            """,
            to: root.appendingPathComponent("Makefile")
        )
        try write("// header\n", to: root.appendingPathComponent("src/rom_header_gf.c"))

        let tileImage = GraphicsArtifactStatus(
            relativePath: "data/tilesets/primary/test/tiles.png",
            kind: .tileImage,
            exists: true,
            generatedRelativePath: "data/tilesets/primary/test/tiles.4bpp.lz",
            generatedExists: false,
            freshness: .generatedMissing
        )
        let palette = GraphicsArtifactStatus(
            relativePath: "data/tilesets/primary/test/palettes/00.pal",
            kind: .palette,
            exists: true,
            generatedRelativePath: "data/tilesets/primary/test/palettes/00.gbapal",
            generatedExists: false,
            freshness: .generatedMissing
        )
        let graphicsReport = GraphicsDiagnosticsReport(
            root: SourceLocation(path: root.path, exists: true),
            profile: .pokeemerald,
            adapterID: "test.adapter",
            adapterName: "Test Adapter",
            inventory: GraphicsSourceAssetInventory(rootRelativePath: "data/tilesets", tileImageCount: 1, paletteFileCount: 1),
            tilesets: [
                GraphicsTilesetDiagnostics(
                    symbol: "gTileset_Test",
                    role: "Primary",
                    tileImage: tileImage,
                    palettes: [palette],
                    metatiles: nil,
                    metatileAttributes: nil,
                    animation: nil,
                    metatileCount: 0,
                    layerSummary: GraphicsLayerModeSummary(),
                    diagnostics: []
                )
            ],
            diagnostics: [
                Diagnostic(
                    severity: .warning,
                    code: "GRAPHICS_GENERATED_ARTIFACT_MISSING",
                    message: "Generated conversion artifact is missing.",
                    span: SourceSpan(relativePath: "data/tilesets/primary/test/tiles.4bpp.lz", startLine: 1)
                )
            ]
        )

        let index = makeIndex(root: root, editorModules: [.graphics, .build])
        let buildReport = BuildValidationReportBuilder.build(index: index, toolResolver: availableTools(["make": "/usr/bin/make"]))
        let playtestReport = PlaytestHandoffReportBuilder.build(index: index, toolResolver: availableTools(["mgba": "/Applications/mGBA.app"]))

        let report = ToolchainHealthMatrixBuilder.build(
            index: index,
            toolResolver: availableTools(["make": "/usr/bin/make", "mgba": "/Applications/mGBA.app"]),
            buildReport: buildReport,
            playtestReport: playtestReport,
            graphicsReport: graphicsReport
        )

        XCTAssertEqual(report.rows.first { $0.id == "graphics-conversion:gbagfx" }?.status, .warning)
        XCTAssertEqual(report.rows.first { $0.id == "graphics-conversion:generated-freshness" }?.status, .warning)
        XCTAssertEqual(report.rows.first { $0.id == "generated:graphics-conversions" }?.status, .warning)
        XCTAssertTrue(report.diagnostics.contains { $0.code == "GRAPHICS_CONVERSION_TOOL_MISSING" })
    }

    private func makeIndex(
        root: URL,
        editorModules: [EditorModule] = [.build],
        generatedOutputs: [SourceDocument] = [],
        buildTargets: [BuildTarget] = []
    ) -> ProjectIndex {
        ProjectIndex(
            root: SourceLocation(path: root.path, exists: true),
            profile: .pokeemerald,
            adapterID: "test.adapter",
            adapterName: "Test Adapter",
            editorModules: editorModules,
            capabilities: [.buildRunner, .playtestBridge, .diagnostics],
            writePolicy: .mutationPlanOnly,
            documents: [],
            generatedOutputs: generatedOutputs,
            diagnostics: [],
            buildTargets: buildTargets
        )
    }

    private func makeTemporaryRoot() throws -> URL {
        let temp = try ToolchainHealthTemporaryDirectory()
        temporaryDirectories.append(temp)
        return temp.url
    }

    private func availableTools(_ pathsByTool: [String: String]) -> ToolAvailabilityResolver {
        { tool in
            if let path = pathsByTool[tool] {
                return ToolAvailability(name: tool, isAvailable: true, resolvedPath: path)
            }
            return ToolAvailability(name: tool, isAvailable: false)
        }
    }

    private func gbaROM(title: String, gameCode: String, makerCode: String, revision: UInt8) -> Data {
        var data = Data(repeating: 0, count: 0xC0)
        writeASCII(title, offset: 0xA0, length: 12, to: &data)
        writeASCII(gameCode, offset: 0xAC, length: 4, to: &data)
        writeASCII(makerCode, offset: 0xB0, length: 2, to: &data)
        data[0xBC] = revision
        return data
    }

    private func writeASCII(_ text: String, offset: Int, length: Int, to data: inout Data) {
        let bytes = Array(text.utf8.prefix(length))
        for index in 0..<length {
            data[offset + index] = index < bytes.count ? bytes[index] : 0
        }
    }

    private func write(_ text: String, to url: URL) throws {
        try write(Data(text.utf8), to: url)
    }

    private func write(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }
}

private final class ToolchainHealthTemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackToolchainHealthTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
