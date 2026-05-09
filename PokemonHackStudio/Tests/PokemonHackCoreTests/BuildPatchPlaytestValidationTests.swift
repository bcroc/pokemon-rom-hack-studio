import XCTest
@testable import PokemonHackCore

final class BuildPatchPlaytestValidationTests: XCTestCase {
    private var temporaryDirectories: [ValidationTemporaryDirectory] = []

    override func tearDown() {
        temporaryDirectories.removeAll()
        super.tearDown()
    }

    func testBuildReportValidatesOutputChecksumFreshnessAndToolAvailability() throws {
        let root = try makeTemporaryRoot()
        let source = root.appendingPathComponent("src/main.c")
        let output = root.appendingPathComponent("pokeemerald.gba")
        try write("int main(void) { return 0; }\n", to: source)
        try write(Data("abc".utf8), to: output)
        try write("a9993e364706816aba3e25717850c26c9cd0d89d  pokeemerald.gba\n", to: root.appendingPathComponent("rom.sha1"))
        try setModificationDate(Date(timeIntervalSince1970: 200), for: source)
        try setModificationDate(Date(timeIntervalSince1970: 100), for: output)

        let report = BuildValidationReportBuilder.build(
            index: makeIndex(
                root: root,
                documents: [
                    SourceDocument(relativePath: "src/main.c", kind: .cSource, exists: true)
                ],
                buildTargets: [
                    BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
                ]
            ),
            toolResolver: availableTools(["make": "/usr/bin/make"])
        )

        let target = try XCTUnwrap(report.targets.first)
        XCTAssertEqual(report.sha1Expectations.first?.expectedSHA1, "a9993e364706816aba3e25717850c26c9cd0d89d")
        XCTAssertEqual(target.commandTool, ToolAvailability(name: "make", isAvailable: true, resolvedPath: "/usr/bin/make"))
        XCTAssertEqual(target.output?.checksumStatus, .matched)
        XCTAssertEqual(target.output?.freshnessStatus, .stale)
        XCTAssertEqual(target.output?.newestSourcePath, "src/main.c")
        XCTAssertTrue(target.diagnostics.contains { $0.code == "BUILD_OUTPUT_STALE" })
        XCTAssertTrue(report.isReady)
    }

    func testBuildReportFlagsChecksumMismatchAndMissingTool() throws {
        let root = try makeTemporaryRoot()
        let source = root.appendingPathComponent("src/main.c")
        let output = root.appendingPathComponent("pokeemerald.gba")
        try write("int main(void) { return 0; }\n", to: source)
        try write(Data("abcd".utf8), to: output)
        try write("a9993e364706816aba3e25717850c26c9cd0d89d\n", to: root.appendingPathComponent("rom.sha1"))
        try setModificationDate(Date(timeIntervalSince1970: 100), for: source)
        try setModificationDate(Date(timeIntervalSince1970: 200), for: output)

        let report = BuildValidationReportBuilder.build(
            index: makeIndex(
                root: root,
                documents: [
                    SourceDocument(relativePath: "src/main.c", kind: .cSource, exists: true)
                ],
                buildTargets: [
                    BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
                ]
            ),
            toolResolver: availableTools([:])
        )

        let target = try XCTUnwrap(report.targets.first)
        XCTAssertEqual(target.commandTool, ToolAvailability(name: "make", isAvailable: false))
        XCTAssertEqual(target.output?.checksumStatus, .mismatched)
        XCTAssertEqual(target.output?.freshnessStatus, .fresh)
        XCTAssertTrue(target.diagnostics.contains { $0.code == "BUILD_TOOL_MISSING" })
        XCTAssertTrue(target.diagnostics.contains { $0.code == "BUILD_OUTPUT_CHECKSUM_MISMATCH" })
        XCTAssertFalse(report.isReady)
    }

    func testBuildReportFlagsMissingOutputAndAbsentSHA1Expectation() throws {
        let root = try makeTemporaryRoot()
        try write("int main(void) { return 0; }\n", to: root.appendingPathComponent("src/main.c"))

        let report = BuildValidationReportBuilder.build(
            index: makeIndex(
                root: root,
                documents: [
                    SourceDocument(relativePath: "src/main.c", kind: .cSource, exists: true)
                ],
                buildTargets: [
                    BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
                ]
            ),
            toolResolver: availableTools(["make": "/usr/bin/make"])
        )

        let target = try XCTUnwrap(report.targets.first)
        XCTAssertTrue(report.sha1Expectations.isEmpty)
        XCTAssertEqual(target.output?.exists, false)
        XCTAssertEqual(target.output?.checksumStatus, .outputMissing)
        XCTAssertEqual(target.output?.freshnessStatus, .outputMissing)
        XCTAssertTrue(target.diagnostics.contains { $0.code == "BUILD_OUTPUT_MISSING" })
        XCTAssertTrue(report.isReady)
    }

    func testBuildReportInventoriesGeneratedArtifactsFromWildcardPatterns() throws {
        let root = try makeTemporaryRoot()
        try write("// generated\n", to: root.appendingPathComponent("data/maps/LittlerootTown/header.inc"))
        try write(Data("abc".utf8), to: root.appendingPathComponent("pokeemerald.gba"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("build"), withIntermediateDirectories: true)

        let report = BuildValidationReportBuilder.build(
            index: makeIndex(
                root: root,
                generatedOutputs: [
                    SourceDocument(relativePath: "data/maps/*/header.inc", kind: .generated, role: .generated, exists: false),
                    SourceDocument(relativePath: "*.gba", kind: .generated, role: .artifact, exists: false),
                    SourceDocument(relativePath: "build", kind: .generated, role: .artifact, exists: true)
                ]
            ),
            toolResolver: availableTools([:])
        )

        XCTAssertEqual(
            report.generatedArtifacts.first(where: { $0.relativePath == "data/maps/*/header.inc" })?.matchedPaths,
            ["data/maps/LittlerootTown/header.inc"]
        )
        XCTAssertEqual(
            report.generatedArtifacts.first(where: { $0.relativePath == "*.gba" })?.matchedPaths,
            ["pokeemerald.gba"]
        )
        XCTAssertEqual(report.generatedArtifacts.first(where: { $0.relativePath == "build" })?.matchCount, 1)
    }

    func testPatchReportWrapsParserAndReportsUnknownOrMalformedPatches() throws {
        let ips = Data("PATCH".utf8)
            + Data([0x00, 0x00, 0x01, 0x00, 0x02, 0xAA, 0xBB])
            + Data("EOF".utf8)
        let bps = Data("BPS1".utf8) + Data([0x85, 0x86, 0x80])
        let ups = Data("UPS1".utf8) + Data([0x85, 0x86])
        let aps = Data("APS1".utf8)

        let valid = PatchValidationReportBuilder.validate(data: ips)
        let validBPS = PatchValidationReportBuilder.validate(data: bps)
        let validUPS = PatchValidationReportBuilder.validate(data: ups)
        let validAPS = PatchValidationReportBuilder.validate(data: aps)
        let unknown = PatchValidationReportBuilder.validate(data: Data("not a patch".utf8))
        let malformed = PatchValidationReportBuilder.validate(data: Data("BPS1".utf8))

        XCTAssertTrue(valid.isValid)
        XCTAssertEqual(valid.summary?.format, .ips)
        XCTAssertEqual(valid.summary?.recordCount, 1)
        XCTAssertTrue(validBPS.isValid)
        XCTAssertEqual(validBPS.summary?.format, .bps)
        XCTAssertEqual(validBPS.summary?.sourceSize, 5)
        XCTAssertEqual(validBPS.summary?.targetSize, 6)
        XCTAssertTrue(validUPS.isValid)
        XCTAssertEqual(validUPS.summary?.format, .ups)
        XCTAssertEqual(validUPS.summary?.sourceSize, 5)
        XCTAssertEqual(validUPS.summary?.targetSize, 6)
        XCTAssertTrue(validAPS.isValid)
        XCTAssertEqual(validAPS.summary?.format, .apsGBA)
        XCTAssertEqual(validAPS.summary?.hasEmbeddedChecksums, true)
        XCTAssertFalse(unknown.isValid)
        XCTAssertEqual(unknown.summary?.format, .unknown)
        XCTAssertTrue(unknown.diagnostics.contains { $0.code == "PATCH_FORMAT_UNKNOWN" })
        XCTAssertFalse(malformed.isValid)
        XCTAssertEqual(malformed.summary?.format, .bps)
        XCTAssertTrue(malformed.diagnostics.contains { $0.code == "PATCH_MALFORMED" })
    }

    func testPatchManifestReportModelsBaseCandidatesAndDryRunPlans() throws {
        let root = try makeTemporaryRoot()
        try write("POKEMON EMER\nBPEE\n", to: root.appendingPathComponent("Makefile"))
        try write(#"{"group_order":[]}"#, to: root.appendingPathComponent("data/maps/map_groups.json"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("src"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics"), withIntermediateDirectories: true)
        try write("a9993e364706816aba3e25717850c26c9cd0d89d  pokeemerald.gba\n", to: root.appendingPathComponent("rom.sha1"))
        try write(Data("abc".utf8), to: root.appendingPathComponent("pokeemerald.gba"))
        try write(Data("APS1".utf8), to: root.appendingPathComponent("cleanroom.aps"))

        let report = try PatchManifestBuilder.build(
            patchPath: root.appendingPathComponent("cleanroom.aps").path,
            projectPath: root.path,
            baseROMPath: root.appendingPathComponent("pokeemerald.gba").path
        )

        XCTAssertEqual(report.patch.summary?.format, .apsGBA)
        XCTAssertEqual(report.compatibilityStatus, .compatible)
        XCTAssertEqual(report.selectedBaseROM?.sha1, "a9993e364706816aba3e25717850c26c9cd0d89d")
        XCTAssertEqual(report.selectedBaseROM?.matchedCandidateRelativePath, "rom.sha1")
        XCTAssertEqual(report.baseROMCandidates.count, 1)
        XCTAssertEqual(report.baseROMCandidates.first?.relativePath, "rom.sha1")
        XCTAssertEqual(report.baseROMCandidates.first?.builtOutputPath, "pokeemerald.gba")
        XCTAssertEqual(report.baseROMCandidates.first?.builtOutputSHA1, "a9993e364706816aba3e25717850c26c9cd0d89d")
        XCTAssertTrue(report.baseROMCandidates.first?.exists ?? false)
        XCTAssertTrue(report.artifactPlan.isPreviewOnly)
        XCTAssertEqual(report.artifactPlan.selectedBaseROMPath, root.appendingPathComponent("pokeemerald.gba").path)
        XCTAssertEqual(report.artifactPlan.patchFormat, .apsGBA)
        XCTAssertEqual(report.artifactPlan.expectedPatchedROMName, "pokeemerald-cleanroom.gba")
        XCTAssertEqual(report.artifactPlan.outputPath, ".pokemonhackstudio/patches/pokeemerald-cleanroom.gba")
        XCTAssertEqual(report.artifactPlan.checksumExpectations.baseROMSHA1, "a9993e364706816aba3e25717850c26c9cd0d89d")
        XCTAssertEqual(report.artifactPlan.checksumExpectations.expectedBaseROMSHA1, "a9993e364706816aba3e25717850c26c9cd0d89d")
        XCTAssertEqual(report.artifactPlan.headerPolicy.mode, "preserve-selected-base-rom-header")
        XCTAssertFalse(report.artifactPlan.headerPolicy.shouldRewriteHeader)
        XCTAssertEqual(report.artifactPlan.mgbaLaunchPreview.outputROMPath, root.appendingPathComponent(".pokemonhackstudio/patches/pokeemerald-cleanroom.gba").path)
        XCTAssertFalse(report.artifactPlan.mgbaLaunchPreview.isLaunchEnabled)
        XCTAssertEqual(report.dryRunPlans.map(\.id), ["verify", "apply"])
        XCTAssertTrue(report.diagnostics.contains { $0.code == "PATCH_BASE_ROM_MATCHED" })
        XCTAssertTrue(report.diagnostics.contains { $0.code == "PATCH_ARTIFACT_PLAN_ONLY" })
        XCTAssertTrue(report.diagnostics.contains { $0.code == "PATCH_MANIFEST_PLAN_ONLY" })
        XCTAssertFalse(FileManager.default.fileExists(atPath: report.artifactPlan.absoluteOutputPath))
    }

    func testPatchManifestReportsSelectedBaseROMMismatch() throws {
        let root = try makeTemporaryRoot()
        try write("POKEMON EMER\nBPEE\n", to: root.appendingPathComponent("Makefile"))
        try write(#"{"group_order":[]}"#, to: root.appendingPathComponent("data/maps/map_groups.json"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("src"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics"), withIntermediateDirectories: true)
        try write("a9993e364706816aba3e25717850c26c9cd0d89d  pokeemerald.gba\n", to: root.appendingPathComponent("rom.sha1"))
        try write(Data("wrong".utf8), to: root.appendingPathComponent("wrong.gba"))
        try write(Data("APS1".utf8), to: root.appendingPathComponent("cleanroom.aps"))

        let report = try PatchManifestBuilder.build(
            patchPath: root.appendingPathComponent("cleanroom.aps").path,
            projectPath: root.path,
            baseROMPath: root.appendingPathComponent("wrong.gba").path
        )

        XCTAssertEqual(report.compatibilityStatus, .baseROMMismatch)
        XCTAssertNil(report.selectedBaseROM?.matchedCandidateRelativePath)
        XCTAssertTrue(report.diagnostics.contains { $0.code == "PATCH_BASE_ROM_MISMATCH" })
    }

    func testPatchManifestNoSelectedBaseROMAndInvalidPatchCompatibilityRemainStable() throws {
        let root = try makeTemporaryRoot()
        let ips = Data("PATCH".utf8)
            + Data([0x00, 0x00, 0x01, 0x00, 0x02, 0xAA, 0xBB])
            + Data("EOF".utf8)
        try write(ips, to: root.appendingPathComponent("change.ips"))
        try write(Data("BPS1".utf8), to: root.appendingPathComponent("broken.bps"))

        let needsBase = try PatchManifestBuilder.build(patchPath: root.appendingPathComponent("change.ips").path)
        let invalid = try PatchManifestBuilder.build(patchPath: root.appendingPathComponent("broken.bps").path)

        XCTAssertEqual(needsBase.compatibilityStatus, .needsBaseROM)
        XCTAssertNil(needsBase.selectedBaseROM)
        XCTAssertEqual(invalid.compatibilityStatus, .invalidPatch)
        XCTAssertTrue(invalid.diagnostics.contains { $0.code == "PATCH_MALFORMED" })
    }

    func testPlaytestReportChecksROMCandidateAndInjectedMGBAAvailability() throws {
        let root = try makeTemporaryRoot()
        let output = root.appendingPathComponent("pokeemerald.gba")
        try write(Data("abc".utf8), to: output)
        let index = makeIndex(
            root: root,
            buildTargets: [
                BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
            ]
        )

        let runnable = PlaytestHandoffReportBuilder.build(
            index: index,
            mode: .headless,
            toolResolver: availableTools(["mgba": "/Applications/mGBA.app"])
        )
        let missingEmulator = PlaytestHandoffReportBuilder.build(
            index: index,
            mode: .headless,
            toolResolver: availableTools([:])
        )

        XCTAssertTrue(runnable.isRunnable)
        XCTAssertTrue(runnable.session.isRunnable)
        XCTAssertEqual(runnable.session.arguments, ["--headless"])
        XCTAssertEqual(runnable.romCandidate?.relativePath, "pokeemerald.gba")
        XCTAssertTrue(runnable.session.artifacts.contains { $0.kind == .runLog && $0.relativePath.hasSuffix("/run.log") })
        XCTAssertTrue(runnable.session.artifacts.contains { $0.kind == .screenshot && $0.relativePath.hasSuffix("/screenshot.png") })
        XCTAssertTrue(runnable.session.artifacts.contains { $0.kind == .saveState && $0.relativePath.hasSuffix("/headless.ss0") })
        XCTAssertFalse(runnable.diagnostics.contains { $0.code == "PLAYTEST_EMULATOR_MISSING" })
        XCTAssertFalse(missingEmulator.isRunnable)
        XCTAssertTrue(missingEmulator.diagnostics.contains { $0.code == "PLAYTEST_EMULATOR_MISSING" })
    }

    func testPlaytestReportReportsMissingBuiltROMCandidate() throws {
        let root = try makeTemporaryRoot()
        let report = PlaytestHandoffReportBuilder.build(
            index: makeIndex(
                root: root,
                buildTargets: [
                    BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
                ]
            ),
            mode: .headless,
            toolResolver: availableTools(["mgba": "/Applications/mGBA.app"])
        )

        XCTAssertFalse(report.isRunnable)
        XCTAssertEqual(report.romCandidate?.relativePath, "pokeemerald.gba")
        XCTAssertTrue(report.diagnostics.contains { $0.code == "PLAYTEST_ROM_NOT_BUILT" })
    }

    func testPlaytestLauncherStartsRunnableROMAndWritesLogs() throws {
        let root = try makeTemporaryRoot()
        let output = root.appendingPathComponent("pokeemerald.gba")
        let emulator = root.appendingPathComponent("tools/mGBA")
        try write(Data("abc".utf8), to: output)
        try writeExecutable("#!/bin/sh\n", to: emulator)

        var capturedRequest: PlaytestProcessRequest?
        let launchedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let result = PlaytestLauncher.launch(
            index: makeIndex(
                root: root,
                buildTargets: [
                    BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
                ]
            ),
            mode: .interactive,
            toolResolver: availableTools(["mgba": emulator.path]),
            processRunner: { request in
                capturedRequest = request
                return 4242
            },
            now: { launchedAt }
        )

        let request = try XCTUnwrap(capturedRequest)
        XCTAssertEqual(result.status, .launched)
        XCTAssertEqual(result.processID, 4242)
        XCTAssertEqual(result.command, [emulator.path, output.path])
        XCTAssertEqual(request.executableURL.path, emulator.path)
        XCTAssertEqual(request.arguments, [output.path])
        XCTAssertEqual(request.workingDirectoryURL.standardizedFileURL.path, root.standardizedFileURL.path)
        XCTAssertTrue(result.artifacts.contains { $0.kind == .runLog && $0.exists })
        XCTAssertTrue(result.artifacts.contains { $0.kind == .stdout && $0.exists })
        XCTAssertTrue(result.artifacts.contains { $0.kind == .stderr && $0.exists })

        let runLogURL = root.appendingPathComponent(".pokemonhackstudio/playtests/pokeemerald/run.log")
        let runLog = try String(contentsOf: runLogURL, encoding: .utf8)
        XCTAssertTrue(runLog.contains("processID: 4242"))
        XCTAssertTrue(runLog.contains("romSHA1: a9993e364706816aba3e25717850c26c9cd0d89d"))
        XCTAssertTrue(runLog.contains("targetID: emerald-build"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/playtests/pokeemerald/stdout.log").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/playtests/pokeemerald/stderr.log").path))
    }

    func testPlaytestLauncherBlocksMissingROMWithoutRunningProcess() throws {
        let root = try makeTemporaryRoot()
        let emulator = root.appendingPathComponent("tools/mGBA")
        try writeExecutable("#!/bin/sh\n", to: emulator)
        var didRun = false

        let result = PlaytestLauncher.launch(
            index: makeIndex(
                root: root,
                buildTargets: [
                    BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
                ]
            ),
            mode: .interactive,
            toolResolver: availableTools(["mgba": emulator.path]),
            processRunner: { _ in
                didRun = true
                return 1
            }
        )

        XCTAssertEqual(result.status, .blocked)
        XCTAssertFalse(didRun)
        XCTAssertTrue(result.diagnostics.contains { $0.code == "PLAYTEST_ROM_NOT_BUILT" })
        XCTAssertTrue(result.diagnostics.contains { $0.code == "PLAYTEST_LAUNCH_BLOCKED" })
    }

    func testPlaytestLauncherBlocksMissingEmulatorWithoutRunningProcess() throws {
        let root = try makeTemporaryRoot()
        try write(Data("abc".utf8), to: root.appendingPathComponent("pokeemerald.gba"))
        var didRun = false

        let result = PlaytestLauncher.launch(
            index: makeIndex(
                root: root,
                buildTargets: [
                    BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
                ]
            ),
            mode: .interactive,
            toolResolver: availableTools([:]),
            processRunner: { _ in
                didRun = true
                return 1
            }
        )

        XCTAssertEqual(result.status, .blocked)
        XCTAssertFalse(didRun)
        XCTAssertTrue(result.diagnostics.contains { $0.code == "PLAYTEST_EMULATOR_MISSING" })
        XCTAssertTrue(result.diagnostics.contains { $0.code == "PLAYTEST_LAUNCH_BLOCKED" })
    }

    func testPlaytestLauncherResolvesMacApplicationBundleExecutable() throws {
        let root = try makeTemporaryRoot()
        let appExecutable = root.appendingPathComponent("mGBA.app/Contents/MacOS/mGBA")
        try writeExecutable("#!/bin/sh\n", to: appExecutable)

        let resolved = PlaytestLauncher.executablePath(
            for: ToolAvailability(name: "mgba", isAvailable: true, resolvedPath: root.appendingPathComponent("mGBA.app").path)
        )

        XCTAssertEqual(resolved, appExecutable.path)
    }

    func testPlaytestLauncherReportsFailedProcessRunner() throws {
        let root = try makeTemporaryRoot()
        let output = root.appendingPathComponent("pokeemerald.gba")
        let emulator = root.appendingPathComponent("tools/mGBA")
        try write(Data("abc".utf8), to: output)
        try writeExecutable("#!/bin/sh\n", to: emulator)

        let result = PlaytestLauncher.launch(
            index: makeIndex(
                root: root,
                buildTargets: [
                    BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
                ]
            ),
            mode: .interactive,
            toolResolver: availableTools(["mgba": emulator.path]),
            processRunner: { _ in
                throw NSError(domain: "PlaytestLauncherTests", code: 1)
            }
        )

        XCTAssertEqual(result.status, .failed)
        XCTAssertTrue(result.diagnostics.contains { $0.code == "PLAYTEST_LAUNCH_FAILED" })
    }

    private func makeIndex(
        root: URL,
        profile: GameProfile = .pokeemerald,
        documents: [SourceDocument] = [],
        generatedOutputs: [SourceDocument] = [],
        buildTargets: [BuildTarget] = []
    ) -> ProjectIndex {
        ProjectIndex(
            root: SourceLocation(path: root.path, exists: true),
            profile: profile,
            adapterID: "test.adapter",
            adapterName: "Test Adapter",
            editorModules: [.build],
            capabilities: [.buildRunner, .playtestBridge, .diagnostics],
            writePolicy: .mutationPlanOnly,
            documents: documents,
            generatedOutputs: generatedOutputs,
            diagnostics: [],
            buildTargets: buildTargets
        )
    }

    private func makeTemporaryRoot() throws -> URL {
        let temp = try ValidationTemporaryDirectory()
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

    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func write(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }

    private func writeExecutable(_ text: String, to url: URL) throws {
        try write(text, to: url)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }

    private func setModificationDate(_ date: Date, for url: URL) throws {
        try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: url.path)
    }
}

private final class ValidationTemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("BuildPatchPlaytestValidationTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
