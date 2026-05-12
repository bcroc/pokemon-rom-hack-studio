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
        let makeRow = try XCTUnwrap(report.rows.first { $0.id == "external:make" })
        XCTAssertEqual(makeRow.status, .ready)
        XCTAssertEqual(makeRow.actions.first?.kind, .copyPath)
        XCTAssertEqual(makeRow.actions.first?.payload, "/usr/bin/make")
        XCTAssertEqual(report.rows.first { $0.id == "rom-header:configuration" }?.status, .ready)
        let headerRow = try XCTUnwrap(report.rows.first { $0.id == "rom-header:emerald-build" })
        XCTAssertEqual(headerRow.status, .ready)
        XCTAssertEqual(headerRow.actions.first?.kind, .copyPath)
        XCTAssertEqual(report.rows.first { $0.id == "generated:adapter-outputs" }?.status, .ready)
        XCTAssertTrue(report.rows.flatMap(\.actions).allSatisfy(\.isPreviewOnly))
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
        XCTAssertTrue(headerRow.actions.contains { $0.kind == .rerunGuidance })
        XCTAssertTrue(report.diagnostics.contains { $0.code == "ROM_HEADER_MISMATCH" })
    }

    func testHealthMatrixActionsGuideMissingToolSetupWithoutExecutingWork() throws {
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

        let index = makeIndex(
            root: root,
            generatedOutputs: [
                SourceDocument(relativePath: "*.gba", kind: .generated, role: .artifact, exists: false)
            ],
            buildTargets: [
                BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
            ]
        )
        let buildReport = BuildValidationReportBuilder.build(index: index, toolResolver: availableTools([:]))
        let playtestReport = PlaytestHandoffReportBuilder.build(index: index, toolResolver: availableTools([:]))

        let report = ToolchainHealthMatrixBuilder.build(
            index: index,
            toolResolver: availableTools([:]),
            buildReport: buildReport,
            playtestReport: playtestReport
        )

        let makeRow = try XCTUnwrap(report.rows.first { $0.id == "external:make" })
        XCTAssertEqual(makeRow.status, .error)
        XCTAssertTrue(makeRow.actions.contains { $0.kind == .rerunGuidance && $0.detail.contains("outside PokemonHackStudio") })
        XCTAssertTrue(makeRow.actions.contains { $0.kind == .copyPath && $0.payload == "Makefile" })

        let localToolRow = try XCTUnwrap(report.rows.first { $0.id == "external:local:tools/gbagfx/gbagfx" })
        XCTAssertEqual(localToolRow.status, .warning)
        XCTAssertTrue(localToolRow.actions.contains { $0.kind == .copyCommand && $0.command == "make tools" })

        let missingROMRow = try XCTUnwrap(report.rows.first { $0.id == "rom-header:emerald-build" })
        XCTAssertEqual(missingROMRow.status, .warning)
        XCTAssertTrue(missingROMRow.actions.contains { $0.kind == .rerunGuidance })
        XCTAssertTrue(missingROMRow.actions.contains { $0.kind == .copyCommand && $0.command == "make" })
        XCTAssertTrue(report.rows.flatMap(\.actions).allSatisfy(\.isPreviewOnly))
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
        XCTAssertTrue(report.rows.first { $0.id == "graphics-conversion:gbagfx" }?.actions.contains { $0.kind == .rerunGuidance } == true)
        XCTAssertTrue(report.rows.first { $0.id == "generated:graphics-conversions" }?.actions.contains { $0.kind == .rerunGuidance } == true)
        XCTAssertTrue(report.diagnostics.contains { $0.code == "GRAPHICS_CONVERSION_TOOL_MISSING" })
    }

    func testHealthMatrixRowsDecodeOlderJSONWithoutActions() throws {
        let json = """
        {
          "id": "external:make",
          "category": "externalTools",
          "title": "make",
          "subject": "Build ROM",
          "status": "ready",
          "detail": "Found make.",
          "diagnostics": []
        }
        """

        let row = try JSONDecoder().decode(ToolchainHealthMatrixRow.self, from: Data(json.utf8))

        XCTAssertEqual(row.id, "external:make")
        XCTAssertEqual(row.actions, [])
    }

    func testHealthMatrixActionDecodeKeepsPayloadPreviewOnly() throws {
        let json = """
        {
          "id": "copy-build-command",
          "kind": "copyCommand",
          "title": "Copy build command",
          "detail": "Copies the build command for manual terminal use.",
          "command": "make",
          "isPreviewOnly": false
        }
        """

        let action = try JSONDecoder().decode(ToolchainHealthAction.self, from: Data(json.utf8))

        XCTAssertEqual(action.kind, .copyCommand)
        XCTAssertEqual(action.command, "make")
        XCTAssertTrue(action.isPreviewOnly)
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
