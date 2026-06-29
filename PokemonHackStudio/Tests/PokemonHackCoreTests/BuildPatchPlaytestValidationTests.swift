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

    func testDecompBuildRunnerRunsMakeTargetWritesLogsAndVerifiesOutput() async throws {
        let root = try makeTemporaryRoot()
        let make = root.appendingPathComponent("tools/make")
        try write("a9993e364706816aba3e25717850c26c9cd0d89d  pokeemerald.gba\n", to: root.appendingPathComponent("rom.sha1"))
        try writeExecutable(
            """
            #!/bin/sh
            echo "building target"
            echo "warning line" >&2
            printf abc > pokeemerald.gba
            exit 0
            """,
            to: make
        )
        let events = DecompBuildLogEventCollector()

        let result = await DecompBuildRunner.run(
            index: makeIndex(
                root: root,
                documents: [SourceDocument(relativePath: "src/main.c", kind: .cSource, exists: true)],
                buildTargets: [
                    BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
                ]
            ),
            targetID: "emerald-build",
            artifactRoot: root,
            toolResolver: availableTools(["make": make.path]),
            logHandler: events.append
        )

        XCTAssertEqual(result.status, .succeeded)
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.output?.exists, true)
        XCTAssertEqual(result.output?.checksumStatus, .matched)
        let loggedEvents = events.values
        XCTAssertTrue(loggedEvents.contains { $0.stream == .stdout && $0.message == "building target" })
        XCTAssertTrue(loggedEvents.contains { $0.stream == .stderr && $0.message == "warning line" })
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/builds/emerald-build/stdout.log").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/builds/emerald-build/stderr.log").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/builds/emerald-build/run.log").path))
    }

    func testDecompBuildRunnerReportsFailedMakeExit() async throws {
        let root = try makeTemporaryRoot()
        let make = root.appendingPathComponent("tools/make")
        try writeExecutable("#!/bin/sh\necho nope >&2\nexit 2\n", to: make)

        let result = await DecompBuildRunner.run(
            index: makeIndex(
                root: root,
                buildTargets: [
                    BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
                ]
            ),
            targetID: "emerald-build",
            artifactRoot: root,
            toolResolver: availableTools(["make": make.path])
        )

        XCTAssertEqual(result.status, .failed)
        XCTAssertEqual(result.exitCode, 2)
        XCTAssertEqual(result.output?.exists, false)
    }

    func testDecompBuildRunnerBlocksUnsupportedCommandAndMissingTool() async throws {
        let root = try makeTemporaryRoot()
        let nonMake = await DecompBuildRunner.run(
            index: makeIndex(
                root: root,
                buildTargets: [
                    BuildTarget(id: "custom-build", name: "Custom", kind: .build, command: ["sh", "build.sh"], outputPath: "pokeemerald.gba")
                ]
            ),
            targetID: "custom-build",
            artifactRoot: root,
            toolResolver: availableTools(["sh": "/bin/sh"])
        )
        XCTAssertEqual(nonMake.status, .blocked)
        XCTAssertTrue(nonMake.diagnostics.contains { $0.code == "BUILD_COMMAND_NOT_SUPPORTED" })

        let missingMake = await DecompBuildRunner.run(
            index: makeIndex(
                root: root,
                buildTargets: [
                    BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
                ]
            ),
            targetID: "emerald-build",
            artifactRoot: root,
            toolResolver: availableTools([:])
        )
        XCTAssertEqual(missingMake.status, .blocked)
        XCTAssertTrue(missingMake.diagnostics.contains { $0.code == "BUILD_TOOL_MISSING" })
    }

    func testDecompBuildRunnerCancelsRunningMakeTarget() async throws {
        let root = try makeTemporaryRoot()
        let make = root.appendingPathComponent("tools/make")
        try writeExecutable("#!/bin/sh\necho started\nsleep 5\nprintf abc > pokeemerald.gba\n", to: make)
        let index = makeIndex(
            root: root,
            buildTargets: [
                BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
            ]
        )
        let resolver = availableTools(["make": make.path])
        let task = Task {
            await DecompBuildRunner.run(
                index: index,
                targetID: "emerald-build",
                artifactRoot: root,
                toolResolver: resolver
            )
        }

        try await Task.sleep(nanoseconds: 200_000_000)
        task.cancel()
        let result = await task.value

        XCTAssertEqual(result.status, .cancelled)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("pokeemerald.gba").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/builds/emerald-build/run.log").path))
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
        XCTAssertEqual(report.artifactPlan.binaryDiffPreview?.patchFormat, .apsGBA)
        XCTAssertEqual(report.artifactPlan.binaryDiffPreview?.applyExportState.canApply, false)
        XCTAssertEqual(report.artifactPlan.binaryDiffPreview?.backupExportManifest.outputPath, report.artifactPlan.absoluteOutputPath)
        XCTAssertEqual(report.dryRunPlans.map(\.id), ["verify", "apply"])
        XCTAssertTrue(report.diagnostics.contains { $0.code == "PATCH_BASE_ROM_MATCHED" })
        XCTAssertTrue(report.diagnostics.contains { $0.code == "PATCH_ARTIFACT_PLAN_ONLY" })
        XCTAssertTrue(report.diagnostics.contains { $0.code == "PATCH_MANIFEST_PLAN_ONLY" })
        XCTAssertFalse(FileManager.default.fileExists(atPath: report.artifactPlan.absoluteOutputPath))
    }

    func testPatchCreationPreviewComparesBaseROMAndBuiltOutputWithoutWritingPatch() throws {
        let root = try makeTemporaryRoot()
        try write("POKEMON EMER\nBPEE\n", to: root.appendingPathComponent("Makefile"))
        try write(#"{"group_order":[]}"#, to: root.appendingPathComponent("data/maps/map_groups.json"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("src"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics"), withIntermediateDirectories: true)

        let baseData = Data("abc".utf8)
        let builtData = Data("abcd".utf8)
        let baseROM = root.appendingPathComponent("clean-base.gba")
        let builtOutput = root.appendingPathComponent("pokeemerald.gba")
        try write(baseData, to: baseROM)
        try write(builtData, to: builtOutput)
        try write("\(pokemonHackSHA1Hex(baseData))  clean-base.gba\n", to: root.appendingPathComponent("rom.sha1"))

        let report = try PatchCreationPreviewBuilder.build(
            projectPath: root.path,
            baseROMPath: baseROM.path
        )

        XCTAssertTrue(report.isPreviewOnly)
        XCTAssertTrue(report.isReady)
        XCTAssertEqual(report.candidateFormat, .bps)
        XCTAssertEqual(report.baseROM.sha1, pokemonHackSHA1Hex(baseData))
        XCTAssertEqual(report.builtOutput?.sha1, pokemonHackSHA1Hex(builtData))
        XCTAssertEqual(report.builtOutput?.relativePath, "pokeemerald.gba")
        XCTAssertEqual(report.sizeDeltaBytes, 1)
        XCTAssertEqual(report.hashesMatch, false)
        XCTAssertEqual(report.plannedPatchPath, ".pokemonhackstudio/patches/clean-base-to-pokeemerald.bps")
        XCTAssertEqual(report.absolutePlannedPatchPath, root.appendingPathComponent(".pokemonhackstudio/patches/clean-base-to-pokeemerald.bps").path)
        XCTAssertFalse(report.headerPolicy.shouldRewriteHeader)
        XCTAssertTrue(report.blockedActions.contains("BPS/IPS patch file writes"))
        XCTAssertTrue(report.diagnostics.contains { $0.code == "PATCH_CREATION_PREVIEW_ONLY" })
        XCTAssertTrue(report.diagnostics.contains { $0.code == "PATCH_CREATION_BUILD_OUTPUT_CHECKSUM_FACT" })
        XCTAssertFalse(FileManager.default.fileExists(atPath: report.absolutePlannedPatchPath))
    }

    func testPatchCreationPreviewBlocksMissingBuiltOutputWithoutWritingPatch() throws {
        let root = try makeTemporaryRoot()
        try write("POKEMON EMER\nBPEE\n", to: root.appendingPathComponent("Makefile"))
        try write(#"{"group_order":[]}"#, to: root.appendingPathComponent("data/maps/map_groups.json"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("src"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics"), withIntermediateDirectories: true)

        let baseData = Data("abc".utf8)
        let baseROM = root.appendingPathComponent("clean-base.gba")
        try write(baseData, to: baseROM)
        try write("\(pokemonHackSHA1Hex(baseData))  clean-base.gba\n", to: root.appendingPathComponent("rom.sha1"))

        let report = try PatchCreationPreviewBuilder.build(
            projectPath: root.path,
            baseROMPath: baseROM.path
        )

        XCTAssertTrue(report.isPreviewOnly)
        XCTAssertFalse(report.isReady)
        XCTAssertEqual(report.candidateFormat, .bps)
        XCTAssertEqual(report.builtOutput?.relativePath, "pokeemerald.gba")
        XCTAssertEqual(report.builtOutput?.exists, false)
        XCTAssertNil(report.builtOutput?.sha1)
        XCTAssertNil(report.sizeDeltaBytes)
        XCTAssertNil(report.hashesMatch)
        XCTAssertEqual(report.plannedPatchPath, ".pokemonhackstudio/patches/clean-base-to-pokeemerald.bps")
        XCTAssertTrue(report.diagnostics.contains { $0.code == "PATCH_CREATION_BUILD_OUTPUT_MISSING" })
        XCTAssertFalse(FileManager.default.fileExists(atPath: report.absolutePlannedPatchPath))
    }

    func testPatchManifestBuildsReadonlyBinaryDiffFreeSpaceAndRepointPreview() throws {
        let root = try makeTemporaryRoot()
        var bytes = [UInt8](repeating: 0xFF, count: 0x240)
        bytes.replaceSubrange(0x04..<0xA0, with: Array(repeating: 1, count: 0x9C))
        bytes.replaceSubrange(0xA0..<0xAC, with: Array("POKEMON TEST".utf8))
        bytes.replaceSubrange(0xAC..<0xB0, with: Array("BPEE".utf8))
        bytes.replaceSubrange(0xB0..<0xB2, with: Array("01".utf8))
        bytes[0x100] = 0x20
        bytes[0x101] = 0x01
        bytes[0x102] = 0x00
        bytes[0x103] = 0x08
        bytes[0x120] = 0x11
        bytes[0x121] = 0x22
        bytes[0x122] = 0x33
        bytes[0x123] = 0x44
        let baseROM = root.appendingPathComponent("standalone.gba")
        try write(Data(bytes), to: baseROM)

        let ips = Data("PATCH".utf8)
            + Data([0x00, 0x01, 0x20, 0x00, 0x04, 0xAA, 0xBB, 0xCC, 0xDD])
            + Data("EOF".utf8)
        let patch = root.appendingPathComponent("change.ips")
        try write(ips, to: patch)

        let preview = PatchManifestBuilder.binaryDiffPreview(
            patchPath: patch.path,
            baseROMPath: baseROM.path,
            outputPath: root.appendingPathComponent("out.gba").path
        )

        XCTAssertTrue(preview.isPreviewOnly)
        XCTAssertEqual(preview.patchFormat, .ips)
        XCTAssertEqual(preview.previewedChangeCount, 1)
        XCTAssertEqual(preview.changedByteCount, 4)
        XCTAssertEqual(preview.changes.first?.offset, 0x120)
        XCTAssertEqual(preview.changes.first?.originalPreviewHex, "11 22 33 44")
        XCTAssertEqual(preview.changes.first?.patchedPreviewHex, "AA BB CC DD")
        XCTAssertTrue(preview.freeSpaceSuitability.contains { $0.isSuitable })
        XCTAssertTrue(preview.pointerRepointPlans.contains { $0.pointerSourceOffset == 0x100 && $0.oldTargetOffset == 0x120 })
        XCTAssertEqual(preview.applyExportState.canApply, false)
        XCTAssertEqual(preview.applyExportState.canExport, false)
        XCTAssertFalse(FileManager.default.fileExists(atPath: preview.backupExportManifest.outputPath))
        XCTAssertTrue(preview.diagnostics.contains { $0.code == "PATCH_BINARY_DIFF_PREVIEW_ONLY" })
    }

    func testPatchApplyExportWritesBPSOutputManifestAndBackup() throws {
        let root = try makeTemporaryRoot()
        try write("POKEMON EMER\nBPEE\n", to: root.appendingPathComponent("Makefile"))
        try write(#"{"group_order":[]}"#, to: root.appendingPathComponent("data/maps/map_groups.json"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("src"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics"), withIntermediateDirectories: true)

        var baseBytes = Array(repeating: UInt8(0xFF), count: 0xC0)
        baseBytes.replaceSubrange(0xA0..<0xAC, with: Array("POKEMON TEST".utf8))
        baseBytes.replaceSubrange(0xAC..<0xB0, with: Array("BPEE".utf8))
        let targetBytes = baseBytes.enumerated().map { index, byte in index == 0x10 ? UInt8(0x42) : byte }
        let baseData = Data(baseBytes)
        let targetData = Data(targetBytes)
        let baseROM = root.appendingPathComponent("pokeemerald.gba")
        let patch = root.appendingPathComponent("cleanroom.bps")
        try write(baseData, to: baseROM)
        try write("\(pokemonHackSHA1Hex(baseData))  pokeemerald.gba\n", to: root.appendingPathComponent("rom.sha1"))
        try write(makeBPSPatch(source: baseData, target: targetData), to: patch)

        let first = try PatchManifestBuilder.applyExport(
            patchPath: patch.path,
            projectPath: root.path,
            baseROMPath: baseROM.path
        )

        let outputPath = root.appendingPathComponent(".pokemonhackstudio/patches/pokeemerald-cleanroom.gba").path
        XCTAssertEqual(first.status, .exported)
        XCTAssertEqual(first.outputPath, outputPath)
        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: outputPath)), targetData)
        XCTAssertEqual(first.manifest?.patchFormat, .bps)
        XCTAssertEqual(first.manifest?.headerPolicy.shouldRewriteHeader, false)
        XCTAssertEqual(first.manifest?.baseROMSHA1, pokemonHackSHA1Hex(baseData))
        XCTAssertEqual(first.manifest?.outputROMSHA1, pokemonHackSHA1Hex(targetData))
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath.appending(".manifest.json")))

        let blocked = try PatchManifestBuilder.applyExport(
            patchPath: patch.path,
            projectPath: root.path,
            baseROMPath: baseROM.path
        )
        XCTAssertEqual(blocked.status, .blocked)
        XCTAssertNil(blocked.backupPath)
        XCTAssertTrue(blocked.diagnostics.contains { $0.code == "PATCH_EXPORT_OUTPUT_EXISTS" })
        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: outputPath)), targetData)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/backups").path))

        let second = try PatchManifestBuilder.applyExport(
            patchPath: patch.path,
            projectPath: root.path,
            baseROMPath: baseROM.path,
            overwrite: true
        )
        XCTAssertEqual(second.status, .exported)
        XCTAssertNotNil(second.backupPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: second.backupPath ?? ""))
    }

    func testPatchApplyExportBlocksSymlinkEscapedArtifactDirectory() throws {
        let root = try makeTemporaryRoot()
        let outside = try makeTemporaryRoot()
        try write("POKEMON EMER\nBPEE\n", to: root.appendingPathComponent("Makefile"))
        try write(#"{"group_order":[]}"#, to: root.appendingPathComponent("data/maps/map_groups.json"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("src"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics"), withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(
            at: root.appendingPathComponent(".pokemonhackstudio"),
            withDestinationURL: outside
        )

        let baseData = Data(repeating: 0xFF, count: 0xC0)
        var targetBytes = Array(baseData)
        targetBytes[0x10] = 0x42
        let targetData = Data(targetBytes)
        let baseROM = root.appendingPathComponent("pokeemerald.gba")
        let patch = root.appendingPathComponent("cleanroom.bps")
        try write(baseData, to: baseROM)
        try write("\(pokemonHackSHA1Hex(baseData))  pokeemerald.gba\n", to: root.appendingPathComponent("rom.sha1"))
        try write(makeBPSPatch(source: baseData, target: targetData), to: patch)

        let result = try PatchManifestBuilder.applyExport(
            patchPath: patch.path,
            projectPath: root.path,
            baseROMPath: baseROM.path
        )

        XCTAssertEqual(result.status, .blocked)
        XCTAssertTrue(result.diagnostics.contains { $0.code == "PATCH_EXPORT_OUTPUT_PATH_SYMLINK_OUTSIDE_ROOT" })
        XCTAssertFalse(FileManager.default.fileExists(atPath: outside.appendingPathComponent("patches/pokeemerald-cleanroom.gba").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: outside.appendingPathComponent("patches/pokeemerald-cleanroom.gba.manifest.json").path))
    }

    func testPatchApplyExportBackupRootsAreCollisionResistantAcrossRapidOverwrites() throws {
        let root = try makeTemporaryRoot()
        try write("POKEMON EMER\nBPEE\n", to: root.appendingPathComponent("Makefile"))
        try write(#"{"group_order":[]}"#, to: root.appendingPathComponent("data/maps/map_groups.json"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("src"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics"), withIntermediateDirectories: true)

        var baseBytes = Array(repeating: UInt8(0xFF), count: 0xC0)
        baseBytes.replaceSubrange(0xA0..<0xAC, with: Array("POKEMON TEST".utf8))
        baseBytes.replaceSubrange(0xAC..<0xB0, with: Array("BPEE".utf8))
        let targetBytes = baseBytes.enumerated().map { index, byte in index == 0x10 ? UInt8(0x42) : byte }
        let baseData = Data(baseBytes)
        let targetData = Data(targetBytes)
        let baseROM = root.appendingPathComponent("pokeemerald.gba")
        let patch = root.appendingPathComponent("cleanroom.bps")
        try write(baseData, to: baseROM)
        try write("\(pokemonHackSHA1Hex(baseData))  pokeemerald.gba\n", to: root.appendingPathComponent("rom.sha1"))
        try write(makeBPSPatch(source: baseData, target: targetData), to: patch)

        _ = try PatchManifestBuilder.applyExport(patchPath: patch.path, projectPath: root.path, baseROMPath: baseROM.path)
        let firstOverwrite = try PatchManifestBuilder.applyExport(
            patchPath: patch.path,
            projectPath: root.path,
            baseROMPath: baseROM.path,
            overwrite: true
        )
        let secondOverwrite = try PatchManifestBuilder.applyExport(
            patchPath: patch.path,
            projectPath: root.path,
            baseROMPath: baseROM.path,
            overwrite: true
        )

        let firstBackup = try XCTUnwrap(firstOverwrite.backupPath)
        let secondBackup = try XCTUnwrap(secondOverwrite.backupPath)
        XCTAssertNotEqual(firstBackup, secondBackup)
        XCTAssertTrue(FileManager.default.fileExists(atPath: firstBackup))
        XCTAssertTrue(FileManager.default.fileExists(atPath: secondBackup))
    }

    func testPatchApplyExportBlocksMismatchedBaseROM() throws {
        let root = try makeTemporaryRoot()
        try write("POKEMON EMER\nBPEE\n", to: root.appendingPathComponent("Makefile"))
        try write(#"{"group_order":[]}"#, to: root.appendingPathComponent("data/maps/map_groups.json"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("src"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics"), withIntermediateDirectories: true)
        let base = Data("abc".utf8)
        let wrong = Data("xyz".utf8)
        let baseROM = root.appendingPathComponent("wrong.gba")
        let patch = root.appendingPathComponent("cleanroom.ips")
        try write(wrong, to: baseROM)
        try write("\(pokemonHackSHA1Hex(base))  pokeemerald.gba\n", to: root.appendingPathComponent("rom.sha1"))
        try write(Data("PATCH".utf8) + Data([0x00, 0x00, 0x01, 0x00, 0x01, 0x64]) + Data("EOF".utf8), to: patch)

        let result = try PatchManifestBuilder.applyExport(
            patchPath: patch.path,
            projectPath: root.path,
            baseROMPath: baseROM.path
        )

        XCTAssertEqual(result.status, .blocked)
        XCTAssertTrue(result.diagnostics.contains { $0.code == "PATCH_EXPORT_BASE_ROM_NOT_COMPATIBLE" })
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/patches/wrong-cleanroom.gba").path))
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

    func testPlaytestDebugPlanReportsExternalDebuggerCapabilitiesWithoutLaunching() throws {
        let root = try makeTemporaryRoot()
        let output = root.appendingPathComponent("pokeemerald.gba")
        let emulator = root.appendingPathComponent("tools/mGBA")
        try write(Data("abc".utf8), to: output)
        try writeExecutable("#!/bin/sh\n", to: emulator)
        let index = makeIndex(
            root: root,
            buildTargets: [
                BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
            ]
        )

        let plan = PlaytestDebugPlanBuilder.build(
            index: index,
            toolResolver: availableTools([
                "mgba": emulator.path,
                "EmuHawk": "/Applications/EmuHawk",
                "visualboyadvance-m": "/usr/local/bin/visualboyadvance-m"
            ])
        )

        XCTAssertTrue(plan.isRunnable)
        XCTAssertFalse(plan.isLaunchEnabled)
        XCTAssertEqual(plan.commandPreview, [emulator.path, "--gdb", output.path])
        XCTAssertTrue(plan.artifacts.contains { $0.relativePath.hasSuffix("/debug/debug-plan.log") })
        XCTAssertTrue(plan.artifacts.contains { $0.relativePath.hasSuffix("/debug/access.log") })
        XCTAssertTrue(plan.capabilities.contains { $0.id == "mgba-debugger" && $0.status == .ready })
        XCTAssertTrue(plan.capabilities.contains { $0.id == "bizhawk-automation" && $0.status == .warning })
        XCTAssertTrue(plan.capabilities.contains { $0.id == "vba-m-debugger" && $0.status == .warning })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "PLAYTEST_DEBUG_PLAN_ONLY" })
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

    func testPlaytestCaptureStartsRunnableROMWithScriptAndWritesScreenshotArtifacts() throws {
        let root = try makeTemporaryRoot()
        let output = root.appendingPathComponent("pokeemerald.gba")
        let emulator = root.appendingPathComponent("tools/mGBA")
        try write(Data("abc".utf8), to: output)
        try writeExecutable("#!/bin/sh\n", to: emulator)

        var capturedRequest: PlaytestProcessRequest?
        let capturedAt = Date(timeIntervalSince1970: 1_700_000_100)
        let result = PlaytestLauncher.capture(
            index: makeIndex(
                root: root,
                buildTargets: [
                    BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
                ]
            ),
            kind: .screenshot,
            mode: .interactive,
            toolResolver: availableTools(["mgba": emulator.path]),
            processRunner: { request in
                capturedRequest = request
                let scriptPath = try XCTUnwrap(request.arguments.dropFirst().first)
                let script = try String(contentsOfFile: scriptPath, encoding: .utf8)
                XCTAssertTrue(script.contains("emu:screenshot(target)"))
                try write(Data("png".utf8), to: root.appendingPathComponent(".pokemonhackstudio/playtests/pokeemerald/screenshot.png"))
                return 5252
            },
            now: { capturedAt }
        )

        let request = try XCTUnwrap(capturedRequest)
        XCTAssertEqual(result.status, .launched)
        XCTAssertEqual(result.captureKind, .screenshot)
        XCTAssertEqual(result.processID, 5252)
        XCTAssertEqual(result.command, [emulator.path, "--script", root.appendingPathComponent(".pokemonhackstudio/playtests/pokeemerald/screenshot-capture.lua").path, output.path])
        XCTAssertEqual(request.executableURL.path, emulator.path)
        XCTAssertEqual(request.arguments, ["--script", root.appendingPathComponent(".pokemonhackstudio/playtests/pokeemerald/screenshot-capture.lua").path, output.path])
        XCTAssertTrue(result.artifacts.contains { $0.kind == .screenshot && $0.exists })
        XCTAssertTrue(result.artifacts.contains { $0.kind == .runLog && $0.relativePath.hasSuffix("/screenshot-capture.log") && $0.exists })

        let runLogURL = root.appendingPathComponent(".pokemonhackstudio/playtests/pokeemerald/screenshot-capture.log")
        let runLog = try String(contentsOf: runLogURL, encoding: .utf8)
        XCTAssertTrue(runLog.contains("captureKind: screenshot"))
        XCTAssertTrue(runLog.contains("processID: 5252"))
    }

    func testPlaytestCaptureStartsRunnableROMWithScriptAndWritesSavestateArtifacts() throws {
        let root = try makeTemporaryRoot()
        let output = root.appendingPathComponent("pokeemerald.gba")
        let emulator = root.appendingPathComponent("tools/mGBA")
        try write(Data("abc".utf8), to: output)
        try writeExecutable("#!/bin/sh\n", to: emulator)

        var capturedRequest: PlaytestProcessRequest?
        let result = PlaytestLauncher.capture(
            index: makeIndex(
                root: root,
                buildTargets: [
                    BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
                ]
            ),
            kind: .saveState,
            mode: .interactive,
            toolResolver: availableTools(["mgba": emulator.path]),
            processRunner: { request in
                capturedRequest = request
                let scriptPath = try XCTUnwrap(request.arguments.dropFirst().first)
                let script = try String(contentsOfFile: scriptPath, encoding: .utf8)
                XCTAssertTrue(script.contains("emu:saveStateFile(target)"))
                try write(Data("state".utf8), to: root.appendingPathComponent(".pokemonhackstudio/playtests/pokeemerald/savestate.ss0"))
                return 5353
            }
        )

        let request = try XCTUnwrap(capturedRequest)
        XCTAssertEqual(result.status, .launched)
        XCTAssertEqual(result.captureKind, .saveState)
        XCTAssertEqual(request.arguments, ["--script", root.appendingPathComponent(".pokemonhackstudio/playtests/pokeemerald/savestate-capture.lua").path, output.path])
        XCTAssertTrue(result.artifacts.contains { $0.kind == .saveState && $0.relativePath.hasSuffix("/savestate.ss0") && $0.exists })
        XCTAssertTrue(result.artifacts.contains { $0.kind == .runLog && $0.relativePath.hasSuffix("/savestate-capture.log") && $0.exists })
    }

    func testPlaytestCaptureBlocksMissingROMWithoutRunningProcess() throws {
        let root = try makeTemporaryRoot()
        let emulator = root.appendingPathComponent("tools/mGBA")
        try writeExecutable("#!/bin/sh\n", to: emulator)
        var didRun = false

        let result = PlaytestLauncher.capture(
            index: makeIndex(
                root: root,
                buildTargets: [
                    BuildTarget(id: "emerald-build", name: "Build ROM", kind: .build, command: ["make"], outputPath: "pokeemerald.gba")
                ]
            ),
            kind: .screenshot,
            mode: .interactive,
            toolResolver: availableTools(["mgba": emulator.path]),
            processRunner: { _ in
                didRun = true
                return 1
            }
        )

        XCTAssertEqual(result.status, .blocked)
        XCTAssertFalse(didRun)
        XCTAssertTrue(result.diagnostics.contains { $0.code == "PLAYTEST_CAPTURE_BLOCKED" })
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

    private func makeBPSPatch(source: Data, target: Data) -> Data {
        var body = Data("BPS1".utf8)
        body.append(contentsOf: encodeBPSVariableLength(UInt64(source.count)))
        body.append(contentsOf: encodeBPSVariableLength(UInt64(target.count)))
        body.append(contentsOf: encodeBPSVariableLength(0))

        var prefixLength = 0
        let sourceBytes = Array(source)
        let targetBytes = Array(target)
        while prefixLength < min(sourceBytes.count, targetBytes.count),
              sourceBytes[prefixLength] == targetBytes[prefixLength] {
            prefixLength += 1
        }
        if prefixLength > 0 {
            body.append(contentsOf: encodeBPSVariableLength(UInt64((prefixLength - 1) << 2)))
        }
        if prefixLength < targetBytes.count {
            let length = targetBytes.count - prefixLength
            body.append(contentsOf: encodeBPSVariableLength(UInt64(((length - 1) << 2) | 1)))
            body.append(contentsOf: targetBytes[prefixLength...])
        }

        appendUInt32LE(crc32(source), to: &body)
        appendUInt32LE(crc32(target), to: &body)
        appendUInt32LE(crc32(body), to: &body)
        return body
    }

    private func encodeBPSVariableLength(_ value: UInt64) -> [UInt8] {
        var data = value
        var bytes: [UInt8] = []
        while true {
            let byte = UInt8(data & 0x7F)
            data >>= 7
            if data == 0 {
                bytes.append(byte | 0x80)
                break
            }
            bytes.append(byte)
            data -= 1
        }
        return bytes
    }

    private func appendUInt32LE(_ value: UInt32, to data: inout Data) {
        data.append(UInt8(value & 0xFF))
        data.append(UInt8((value >> 8) & 0xFF))
        data.append(UInt8((value >> 16) & 0xFF))
        data.append(UInt8((value >> 24) & 0xFF))
    }

    private func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                let mask = 0 &- (crc & 1)
                crc = (crc >> 1) ^ (0xEDB8_8320 & mask)
            }
        }
        return ~crc
    }
}

private final class DecompBuildLogEventCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var events: [DecompBuildLogEvent] = []

    var values: [DecompBuildLogEvent] {
        lock.lock()
        defer { lock.unlock() }
        return events
    }

    func append(_ event: DecompBuildLogEvent) {
        lock.lock()
        events.append(event)
        lock.unlock()
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
