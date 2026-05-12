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

    func testNDSHealthMatrixReportsPreviewOnlyMissingToolsAndGeneratedGuidance() throws {
        let root = try makeTemporaryRoot()
        try write("rom:\n\tmake rom\n", to: root.appendingPathComponent("Makefile"))
        try write("project('pokeplatinum')\n", to: root.appendingPathComponent("meson.build"))

        let index = makeNDSIndex(
            root: root,
            generatedOutputs: [
                SourceDocument(relativePath: "build/pokeplatinum.us.nds", kind: .generated, role: .artifact, exists: false)
            ],
            buildTargets: [
                BuildTarget(id: "platinum-rom", name: "Build Platinum ROM", kind: .build, command: ["make", "rom"], outputPath: "build/pokeplatinum.us.nds")
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

        XCTAssertEqual(report.profile, .pokeplatinum)
        XCTAssertNotNil(report.rows.first { $0.id == "external:nds:devkitpro-root" })
        XCTAssertTrue(report.rows.contains { $0.id == "external:arm-none-eabi-gcc" && $0.status == .warning })
        XCTAssertNotNil(report.rows.first { $0.id == "external:nds:blocksds-docker" })
        XCTAssertTrue(report.rows.contains { $0.id == "external:meson" && $0.status == .warning })
        XCTAssertNotNil(report.rows.first { $0.id == "external:nds:ndstool" })
        XCTAssertNotNil(report.rows.first { $0.id == "external:python3" })
        XCTAssertNotNil(report.rows.first { $0.id == "external:nds:reference:dspre" })
        XCTAssertNotNil(report.rows.first { $0.id == "external:nds:reference:tinke" })
        XCTAssertNotNil(report.rows.first { $0.id == "external:nds:melonDS" })
        XCTAssertFalse(report.rows.contains { $0.id == "external:mgba" })
        XCTAssertEqual(report.rows.first { $0.id == "rom-header:platinum-rom" }?.status, .warning)
        XCTAssertTrue(report.rows.first { $0.id == "rom-header:platinum-rom" }?.actions.contains { $0.kind == .copyCommand && $0.command == "make rom" } == true)
        XCTAssertEqual(report.rows.first { $0.id == "graphics-conversion:nds-preview-only" }?.status, .notApplicable)
        XCTAssertEqual(report.rows.first { $0.id == "generated:nds-build-output:platinum-rom" }?.status, .warning)
        XCTAssertTrue(report.rows.flatMap(\.actions).allSatisfy(\.isPreviewOnly))
        XCTAssertTrue(report.diagnostics.contains { $0.code == "NDS_TOOLCHAIN_TOOL_MISSING" || $0.code == "NDS_BLOCKSDS_DOCKER_MISSING" })
        XCTAssertTrue(report.diagnostics.contains { $0.code == "NDS_HEADER_OUTPUT_MISSING" })
    }

    func testNDSHealthMatrixMarksDiscoveredToolsReadyWithoutLaunchingThem() throws {
        let root = try makeTemporaryRoot()
        try write("rom:\n\tmake rom\n", to: root.appendingPathComponent("Makefile"))
        try write("project('pokeplatinum')\n", to: root.appendingPathComponent("meson.build"))
        try write(ndsROM(title: "POKEMON PL", gameCode: "CPUE", makerCode: "01"), to: root.appendingPathComponent("build/pokeplatinum.us.nds"))

        let tools = availableTools([
            "make": "/usr/bin/make",
            "arm-none-eabi-gcc": "/opt/devkitpro/devkitARM/bin/arm-none-eabi-gcc",
            "blocksds": "/opt/blocksds/bin/blocksds",
            "meson": "/usr/local/bin/meson",
            "ninja": "/usr/local/bin/ninja",
            "ndstool": "/opt/devkitpro/tools/bin/ndstool",
            "ndspy": "/usr/local/bin/ndspy",
            "python3": "/usr/bin/python3",
            "docker": "/usr/local/bin/docker",
            "melonDS": "/Applications/melonDS.app",
            "DeSmuME": "/Applications/DeSmuME.app"
        ])
        let index = makeNDSIndex(
            root: root,
            generatedOutputs: [
                SourceDocument(relativePath: "build/pokeplatinum.us.nds", kind: .generated, role: .artifact, exists: true)
            ],
            buildTargets: [
                BuildTarget(id: "platinum-rom", name: "Build Platinum ROM", kind: .build, command: ["make", "rom"], outputPath: "build/pokeplatinum.us.nds")
            ]
        )
        let buildReport = BuildValidationReportBuilder.build(index: index, toolResolver: tools)
        let playtestReport = PlaytestHandoffReportBuilder.build(index: index, toolResolver: tools)

        let report = ToolchainHealthMatrixBuilder.build(
            index: index,
            toolResolver: tools,
            buildReport: buildReport,
            playtestReport: playtestReport
        )

        for id in [
            "external:make",
            "external:arm-none-eabi-gcc",
            "external:meson",
            "external:ninja",
            "external:nds:ndstool",
            "external:nds:ndspy",
            "external:python3",
            "external:nds:melonDS",
            "external:nds:DeSmuME"
        ] {
            let row = try XCTUnwrap(report.rows.first { $0.id == id }, id)
            XCTAssertEqual(row.status, .ready, id)
            XCTAssertTrue(row.actions.contains { $0.kind == .copyPath }, id)
        }
        let blocksDSRow = try XCTUnwrap(report.rows.first { $0.id == "external:nds:blocksds-docker" })
        XCTAssertEqual(blocksDSRow.status, .ready)
        XCTAssertTrue(blocksDSRow.detail.contains("will not inspect, pull, or run"))
        XCTAssertTrue(blocksDSRow.actions.contains { $0.command == "docker image inspect skylyrac/blocksds:slim-latest" })
        XCTAssertTrue(blocksDSRow.actions.contains { $0.command == "docker image pull skylyrac/blocksds:slim-latest" })
        XCTAssertTrue(blocksDSRow.actions.allSatisfy(\.isPreviewOnly))
        XCTAssertNotNil(report.rows.first { $0.id == "external:nds:reference:dspre" })
        XCTAssertNotNil(report.rows.first { $0.id == "external:nds:reference:tinke" })
        XCTAssertEqual(report.rows.first { $0.id == "rom-header:platinum-rom" }?.status, .ready)
        XCTAssertEqual(report.rows.first { $0.id == "generated:nds-build-output:platinum-rom" }?.status, .ready)
        XCTAssertTrue(report.rows.flatMap(\.actions).allSatisfy(\.isPreviewOnly))
    }

    func testNDSROMHealthMatrixReportsHeaderAndManualEmulatorGuidanceOnly() throws {
        let root = try makeTemporaryRoot()
        let rom = root.appendingPathComponent("sample.nds")
        try write(ndsROM(title: "POKEMON D", gameCode: "ADAE", makerCode: "01"), to: rom)
        let tools = availableTools(["ndstool": "/usr/local/bin/ndstool", "melonDS": "/Applications/melonDS.app"])
        let index = ProjectIndex(
            root: SourceLocation(path: rom.path, exists: true),
            profile: .ndsROM,
            adapterID: "nds.binary-rom",
            adapterName: "Pokemon Diamond",
            editorModules: [.rom, .diagnostics],
            capabilities: [.resourceIndex, .ndsROMInspection, .nitroFSIndex, .narcInspection, .diagnostics],
            writePolicy: .readOnly,
            documents: [SourceDocument(relativePath: rom.lastPathComponent, kind: .binary, role: .localInput, exists: true)],
            generatedOutputs: [],
            diagnostics: [],
            buildTargets: []
        )
        let buildReport = BuildValidationReportBuilder.build(index: index, toolResolver: tools)
        let playtestReport = PlaytestHandoffReportBuilder.build(index: index, toolResolver: tools)

        let report = ToolchainHealthMatrixBuilder.build(
            index: index,
            toolResolver: tools,
            buildReport: buildReport,
            playtestReport: playtestReport
        )

        XCTAssertEqual(report.rows.first { $0.id == "rom-header:nds-rom" }?.status, .ready)
        XCTAssertTrue(report.rows.first { $0.id == "rom-header:nds-rom" }?.detail.contains("ADAE") == true)
        XCTAssertEqual(report.rows.first { $0.id == "generated:nds-rom-input" }?.status, .notApplicable)
        XCTAssertEqual(report.rows.first { $0.id == "external:nds:ndstool" }?.status, .ready)
        XCTAssertEqual(report.rows.first { $0.id == "external:nds:melonDS" }?.status, .ready)
        XCTAssertNotNil(report.rows.first { $0.id == "external:nds:DeSmuME" })
        XCTAssertFalse(report.rows.contains { $0.id == "external:mgba" })
        XCTAssertTrue(report.rows.flatMap(\.actions).allSatisfy(\.isPreviewOnly))
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

    private func makeNDSIndex(
        root: URL,
        generatedOutputs: [SourceDocument] = [],
        buildTargets: [BuildTarget] = []
    ) -> ProjectIndex {
        ProjectIndex(
            root: SourceLocation(path: root.path, exists: true),
            profile: .pokeplatinum,
            adapterID: "pret.pokeplatinum",
            adapterName: "pokeplatinum",
            editorModules: [.rom, .build, .diagnostics],
            capabilities: [.resourceIndex, .ndsSourceTreeIndex, .ndsDataCatalog, .diagnostics],
            writePolicy: .readOnly,
            documents: [
                SourceDocument(relativePath: "Makefile", kind: .makefile, role: .marker, exists: true),
                SourceDocument(relativePath: "meson.build", kind: .configuration, role: .marker, exists: true)
            ],
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

    private func ndsROM(title: String, gameCode: String, makerCode: String) -> Data {
        var data = Data(repeating: 0, count: 0x200)
        writeASCII(title, offset: 0x00, length: 12, to: &data)
        writeASCII(gameCode, offset: 0x0C, length: 4, to: &data)
        writeASCII(makerCode, offset: 0x10, length: 2, to: &data)
        data[0x12] = 0x00
        data[0x14] = 0x08
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
