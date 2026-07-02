import XCTest
#if !POKEMONHACK_CLI_TESTING
@testable import pokemonhack_cli
#endif

final class PokemonHackCLITests: XCTestCase {
    private var temporaryDirectories: [URL] = []

    override func tearDownWithError() throws {
        for url in temporaryDirectories {
            try? FileManager.default.removeItem(at: url)
        }
        temporaryDirectories.removeAll()
        try super.tearDownWithError()
    }

    func testHelpUsesCommandMetadataForTextAndJSON() throws {
        let text = try PokemonHackCLI.run(arguments: ["--help"])
        XCTAssertTrue(text.contains("nds-data-semantic-plan <project> <record-id>"))
        XCTAssertTrue(text.contains("nds-data-item-csv-rows-plan <project> <record-id>"))
        XCTAssertTrue(text.contains("nds-data-encounter-json-rows-plan <project> <record-id>"))
        XCTAssertTrue(text.contains("patch-create-preview <project> --base-rom <path>"))
        XCTAssertTrue(text.contains("patch-create <project> --base-rom <path>"))
        XCTAssertTrue(text.contains("patch-library <project> --json"))
        XCTAssertTrue(text.contains("patch-distribution-readiness <project> --base-rom <path>"))
        XCTAssertTrue(text.contains("rom-mutation-manifest <rom-or-source-path>"))
        XCTAssertTrue(text.contains("rom-mutation-audit <rom> --manifest <dry-run-json>"))
        XCTAssertTrue(text.contains("rom-mutation-apply <rom> --manifest <dry-run-json>"))
        XCTAssertTrue(text.contains("validation-tiers --json"))
        XCTAssertTrue(text.contains("map-render-audit <path> --json"))
        XCTAssertTrue(text.contains("help --json"))

        let json = try decodeJSON(PokemonHackCLI.run(arguments: ["help", "--json"]))
        XCTAssertEqual(json["executable"] as? String, "pokemonhack-cli")
        let commands = try XCTUnwrap(json["commands"] as? [[String: Any]])
        XCTAssertTrue(commands.contains { $0["name"] as? String == "nds-data-semantic-plan" && ($0["usage"] as? String)?.contains("--set <field=value>") == true })
        XCTAssertTrue(commands.contains { $0["name"] as? String == "nds-data-item-csv-rows-plan" && ($0["usage"] as? String)?.contains("--insert <index> <csv-row>") == true })
        XCTAssertTrue(commands.contains { $0["name"] as? String == "nds-data-encounter-json-rows-plan" && ($0["usage"] as? String)?.contains("--array <array-key>") == true })
        XCTAssertTrue(commands.contains { $0["name"] as? String == "patch-create-preview" && ($0["usage"] as? String)?.contains("[--target <build-target-id>]") == true })
        XCTAssertTrue(commands.contains { $0["name"] as? String == "patch-create" && ($0["usage"] as? String)?.contains("[--target <build-target-id>]") == true })
        XCTAssertTrue(commands.contains { $0["name"] as? String == "patch-library" && $0["usage"] as? String == "patch-library <project> --json" })
        XCTAssertTrue(commands.contains { $0["name"] as? String == "patch-distribution-readiness" && ($0["usage"] as? String)?.contains("[--patch <bps-path>]") == true })
        XCTAssertTrue(commands.contains { $0["name"] as? String == "rom-mutation-manifest" && ($0["usage"] as? String)?.contains("--replace <offset:length:hex>") == true })
        let auditMetadata = try XCTUnwrap(commands.first { $0["name"] as? String == "rom-mutation-audit" })
        let auditUsage = try XCTUnwrap(auditMetadata["usage"] as? String)
        XCTAssertTrue(auditUsage.contains("--manifest <dry-run-json>"))
        XCTAssertTrue(auditUsage.contains("--workspace-root <path>"))
        XCTAssertFalse(auditUsage.contains("--confirm"))
        XCTAssertTrue(commands.contains { $0["name"] as? String == "rom-mutation-apply" && ($0["usage"] as? String)?.contains("--confirm <review-token>") == true })
        XCTAssertTrue(commands.contains { $0["name"] as? String == "validation-tiers" && $0["usage"] as? String == "validation-tiers --json" })
        XCTAssertTrue(commands.contains { $0["name"] as? String == "map-render-audit" && ($0["usage"] as? String)?.contains("--all --json") == true })
        XCTAssertTrue(commands.contains { $0["name"] as? String == "help" })
    }

    func testValidationTiersCommandUsesSharedCopyOnlyModelJSON() throws {
        let json = try decodeJSON(PokemonHackCLI.run(arguments: ["validation-tiers", "--json"]))
        let rows = try XCTUnwrap(json["rows"] as? [[String: Any]])

        XCTAssertEqual(
            rows.compactMap { $0["command"] as? String },
            [
                "make validate-synthetic",
                "make validate-gba-fixtures",
                "make validate-nds",
                "make validate-nds-strict",
                "make validate-gui-smoke",
                "make validate-release-candidate"
            ]
        )
        XCTAssertTrue(rows.allSatisfy { $0["copyValue"] as? String == $0["command"] as? String })
        XCTAssertTrue(rows.allSatisfy { $0["canRunInApp"] as? Bool == false })
        XCTAssertTrue(rows.allSatisfy { $0["canCopyCommand"] as? Bool == true })
        XCTAssertTrue(rows.allSatisfy { ($0["disabledReason"] as? String)?.contains("copy-only") == true })

        let optionalNDS = try XCTUnwrap(rows.first { $0["tier"] as? String == "ndsSyntheticAndOptionalReferences" })
        XCTAssertEqual(optionalNDS["strictnessTitle"] as? String, "Optional central NDS references")
        let optionalCauses = try XCTUnwrap(optionalNDS["skippedReferenceCauses"] as? [[String: Any]])
        XCTAssertEqual(optionalCauses.count, 4)
        XCTAssertTrue(optionalCauses.allSatisfy { $0["behavior"] as? String == "skippedWhenMissing" })
        XCTAssertTrue(optionalCauses.contains { $0["defaultPath"] as? String == "/Users/bryan/projects/reference-repos/repos/pret__pokeplatinum" })
        XCTAssertTrue(optionalCauses.allSatisfy { ($0["overrideEnvironmentVariables"] as? [String])?.contains("REFERENCE_REPOS_ROOT") == true })

        let strictNDS = try XCTUnwrap(rows.first { $0["tier"] as? String == "centralNDSReferences" })
        let strictNDSCauses = try XCTUnwrap(strictNDS["skippedReferenceCauses"] as? [[String: Any]])
        XCTAssertTrue(strictNDSCauses.allSatisfy { $0["behavior"] as? String == "failsWhenMissing" })
    }

    func testBlockedApplyExportOutputsMapToNonzeroExecutableExitCode() throws {
        XCTAssertEqual(
            PokemonHackCLI.exitCode(arguments: ["patch-apply-export"], output: #"{"status":"blocked"}"#),
            1
        )
        XCTAssertEqual(
            PokemonHackCLI.exitCode(arguments: ["patch-apply-export"], output: #"{"status":"exported"}"#),
            0
        )
        XCTAssertEqual(
            PokemonHackCLI.exitCode(arguments: ["patch-create"], output: #"{"status":"blocked"}"#),
            1
        )
        XCTAssertEqual(
            PokemonHackCLI.exitCode(arguments: ["patch-create"], output: #"{"status":"created"}"#),
            0
        )
        XCTAssertEqual(
            PokemonHackCLI.exitCode(arguments: ["patch-distribution-readiness"], output: #"{"status":"blocked"}"#),
            0
        )
        XCTAssertEqual(
            PokemonHackCLI.exitCode(arguments: ["rom-mutation-apply"], output: #"{"status":"blocked"}"#),
            1
        )
        XCTAssertEqual(
            PokemonHackCLI.exitCode(arguments: ["rom-mutation-apply"], output: #"{"status":"applied"}"#),
            0
        )
        XCTAssertEqual(
            PokemonHackCLI.exitCode(arguments: ["rom-mutation-audit"], output: #"{"status":"blocked"}"#),
            1
        )
        XCTAssertEqual(
            PokemonHackCLI.exitCode(arguments: ["rom-mutation-audit"], output: #"{"status":"ready"}"#),
            0
        )
        XCTAssertEqual(
            PokemonHackCLI.exitCode(
                arguments: ["nds-data-semantic-apply"],
                output: #"{"appliedChanges":[],"diagnostics":[{"severity":"error","code":"NDS_DATA_APPLY_PATH_OUTSIDE_ROOT","message":"blocked"}]}"#
            ),
            1
        )
        XCTAssertEqual(
            PokemonHackCLI.exitCode(
                arguments: ["nds-data-semantic-apply"],
                output: #"{"appliedChanges":[{"path":"res/items/potion.json"}],"diagnostics":[]}"#
            ),
            0
        )
        XCTAssertEqual(
            PokemonHackCLI.exitCode(arguments: ["map-render-audit"], output: #"{"status":"failed"}"#),
            1
        )
        XCTAssertEqual(
            PokemonHackCLI.exitCode(arguments: ["map-render-audit"], output: #"{"status":"passed"}"#),
            0
        )
    }

    func testMapRenderAuditPathJSONReportsPassed() throws {
        let root = try makeMapRenderAuditProject()

        let output = try PokemonHackCLI.run(arguments: ["map-render-audit", root.path, "--json"])
        let json = try decodeJSON(output)
        let summary = try XCTUnwrap(json["summary"] as? [String: Any])

        XCTAssertEqual(json["status"] as? String, "passed")
        XCTAssertEqual(summary["mapCount"] as? Int, 1)
        XCTAssertEqual(PokemonHackCLI.exitCode(arguments: ["map-render-audit", root.path, "--json"], output: output), 0)
    }

    func testMapRenderAuditAllJSONReportsSkippedUnsupportedTargets() throws {
        let workspace = try makeTemporaryDirectory()
        try makeMapRenderAuditProject(at: workspace.appendingPathComponent("pokeemerald"))
        try write(Data([0xde, 0xad, 0xbe, 0xef]), to: workspace.appendingPathComponent("local.nds"))
        let previousDirectory = FileManager.default.currentDirectoryPath
        XCTAssertTrue(FileManager.default.changeCurrentDirectoryPath(workspace.path))
        defer { FileManager.default.changeCurrentDirectoryPath(previousDirectory) }

        let json = try decodeJSON(PokemonHackCLI.run(arguments: ["map-render-audit", "--all", "--json"]))
        let summary = try XCTUnwrap(json["summary"] as? [String: Any])
        let skipped = try XCTUnwrap(json["skippedTargets"] as? [[String: Any]])

        XCTAssertEqual(json["status"] as? String, "passed")
        XCTAssertEqual(summary["auditedTargetCount"] as? Int, 1)
        XCTAssertEqual(summary["mapCount"] as? Int, 1)
        XCTAssertTrue(skipped.contains { ($0["path"] as? String)?.hasSuffix("local.nds") == true })
    }

    func testMapRenderAuditMissingTargetJSONIsSkipped() throws {
        let root = try makeTemporaryDirectory()
        let missing = root.appendingPathComponent("missing-source")

        let json = try decodeJSON(PokemonHackCLI.run(arguments: ["map-render-audit", missing.path, "--json"]))
        let skipped = try XCTUnwrap(json["skippedTargets"] as? [[String: Any]])

        XCTAssertEqual(json["status"] as? String, "passed")
        XCTAssertEqual(skipped.first?["reasonCode"] as? String, "MAP_RENDER_AUDIT_TARGET_MISSING")
    }

    func testMapRenderAuditFailureJSONShapeAndExitCode() throws {
        let root = try makeMapRenderAuditProject()
        try FileManager.default.removeItem(at: root.appendingPathComponent("data/tilesets/primary/general/tiles.png"))

        let output = try PokemonHackCLI.run(arguments: ["map-render-audit", root.path, "--json"])
        let json = try decodeJSON(output)
        let failures = try XCTUnwrap(json["failures"] as? [[String: Any]])

        XCTAssertEqual(json["status"] as? String, "failed")
        XCTAssertTrue(failures.contains { $0["code"] as? String == "MAP_RENDER_AUDIT_TILE_IMAGE_MISSING" })
        XCTAssertEqual(PokemonHackCLI.exitCode(arguments: ["map-render-audit", root.path, "--json"], output: output), 1)
    }

    func testJSONErrorReportUsesMachineReadableShapeAndExitCodes() throws {
        let usage = try decodeJSON(
            PokemonHackCLI.renderJSONError(arguments: ["--json"], error: CLIError.usage)
        )
        XCTAssertEqual(usage["status"] as? String, "error")
        XCTAssertEqual(usage["errorCode"] as? String, "CLI_USAGE")
        XCTAssertEqual(usage["command"] as? String, "--json")
        XCTAssertTrue((usage["message"] as? String)?.contains("pokemonhack-cli") == true)
        XCTAssertTrue((usage["usage"] as? String)?.contains("help --json") == true)
        XCTAssertEqual(PokemonHackCLI.jsonErrorExitCode(error: CLIError.usage), 2)

        let unknown = try decodeJSON(
            PokemonHackCLI.renderJSONError(arguments: ["bogus", "--json"], error: CLIError.unknownCommand("bogus"))
        )
        XCTAssertEqual(unknown["status"] as? String, "error")
        XCTAssertEqual(unknown["errorCode"] as? String, "CLI_UNKNOWN_COMMAND")
        XCTAssertEqual(unknown["message"] as? String, "Unknown command: bogus")
        XCTAssertEqual(unknown["command"] as? String, "bogus")
        XCTAssertTrue((unknown["usage"] as? String)?.contains("validation-tiers --json") == true)
        XCTAssertEqual(PokemonHackCLI.jsonErrorExitCode(error: CLIError.unknownCommand("bogus")), 2)

        let unexpected = try decodeJSON(
            PokemonHackCLI.renderJSONError(arguments: ["validate", "--json"], error: CocoaError(.fileReadNoSuchFile))
        )
        XCTAssertEqual(unexpected["status"] as? String, "error")
        XCTAssertEqual(unexpected["errorCode"] as? String, "CLI_ERROR")
        XCTAssertEqual(unexpected["command"] as? String, "validate")
        XCTAssertEqual(PokemonHackCLI.jsonErrorExitCode(error: CocoaError(.fileReadNoSuchFile)), 1)
    }

    func testPlaytestHeadlessAndLaunchEmitJSONWithoutApplyingSideEffects() throws {
        let root = try makeEmeraldProject()

        let headless = try decodeJSON(
            PokemonHackCLI.run(arguments: ["playtest", root.path, "--headless", "--json"])
        )
        XCTAssertEqual(headless["mode"] as? String, "headless")
        XCTAssertEqual(headless["isRunnable"] as? Bool, false)
        XCTAssertNotNil(headless["session"])

        let launch = try decodeJSON(
            PokemonHackCLI.run(arguments: ["playtest", root.path, "--launch", "--json"])
        )
        XCTAssertEqual(launch["mode"] as? String, "interactive")
        XCTAssertEqual(launch["status"] as? String, "blocked")
        XCTAssertNil(launch["processID"] as? Int)
        XCTAssertNotNil(launch["artifacts"])

        let screenshot = try decodeJSON(
            PokemonHackCLI.run(arguments: ["playtest", root.path, "--screenshot", "--json"])
        )
        XCTAssertEqual(screenshot["mode"] as? String, "interactive")
        XCTAssertEqual(screenshot["captureKind"] as? String, "screenshot")
        XCTAssertEqual(screenshot["status"] as? String, "blocked")
        XCTAssertNotNil(screenshot["artifacts"])

        let savestate = try decodeJSON(
            PokemonHackCLI.run(arguments: ["playtest", root.path, "--savestate", "--json"])
        )
        XCTAssertEqual(savestate["mode"] as? String, "interactive")
        XCTAssertEqual(savestate["captureKind"] as? String, "saveState")
        XCTAssertEqual(savestate["status"] as? String, "blocked")
        XCTAssertNotNil(savestate["artifacts"])
    }

    func testPlaytestDebugPlanCommandEmitsPlanningJSONWithoutLaunching() throws {
        let rom = try makeTestROM()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["playtest-debug-plan", rom.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "binaryROM")
        XCTAssertEqual(result["isLaunchEnabled"] as? Bool, false)
        XCTAssertNotNil(result["commandPreview"])
        let capabilities = try XCTUnwrap(result["capabilities"] as? [[String: Any]])
        XCTAssertTrue(capabilities.contains { $0["id"] as? String == "mgba-debugger" })
        XCTAssertTrue(capabilities.contains { $0["id"] as? String == "bizhawk-automation" })
        XCTAssertTrue(capabilities.contains { $0["id"] as? String == "vba-m-debugger" })
        let artifacts = try XCTUnwrap(result["artifacts"] as? [[String: Any]])
        XCTAssertTrue(artifacts.contains { ($0["relativePath"] as? String)?.hasSuffix("/debug/access.log") == true })
        let diagnostics = try XCTUnwrap(result["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "PLAYTEST_DEBUG_PLAN_ONLY" })
    }

    func testPlaytestUnknownModeThrowsUsage() throws {
        let root = try makeEmeraldProject()

        XCTAssertThrowsError(
            try PokemonHackCLI.run(arguments: ["playtest", root.path, "--bogus", "--json"])
        ) { error in
            XCTAssertEqual(error as? CLIError, .usage)
        }
    }

    func testGraphicsImportPlanCommandEmitsPreviewJSON() throws {
        let root = try makeEmeraldProject()
        let package = try makeTemporaryDirectory().appendingPathComponent("local-pack")
        try write("Credit: local fixture\n", to: package.appendingPathComponent("credits.txt"))
        try writePNG(width: 16, height: 16, paletteColors: 8, to: package.appendingPathComponent("top.png"))
        try write("id,behavior,layer\n", to: package.appendingPathComponent("attributes.csv"))

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["graphics-import-plan", root.path, package.path, "--json"])
        )

        XCTAssertEqual(result["readiness"] as? String, "ready")
        XCTAssertEqual(result["isPreviewOnly"] as? Bool, true)
        XCTAssertNotNil(result["copyPlan"])
        XCTAssertNotNil(result["layeredTilesetDryRun"])
    }

    func testScriptCommandEditPlanAndApplyCommandsEmitJSONAndWriteSource() throws {
        let root = try makeEmeraldProject()
        let scriptPath = "data/maps/Route1/scripts.inc"
        try write(
            """
            Route1_EventScript_Test::
                msgbox Route1_Text_Hello, MSGBOX_DEFAULT @ keep
                end
            """,
            to: root.appendingPathComponent(scriptPath)
        )

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "script-command-edit-plan",
                root.path,
                scriptPath,
                "2",
                "1",
                "MSGBOX_YESNO",
                "--json"
            ])
        )
        XCTAssertEqual(plan["rootPath"] as? String, root.path)
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.first?["path"] as? String, scriptPath)
        XCTAssertEqual(changes.first?["textPreview"] as? String, "    msgbox Route1_Text_Hello, MSGBOX_YESNO @ keep")

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "script-command-edit-apply",
                root.path,
                scriptPath,
                "2",
                "1",
                "MSGBOX_YESNO",
                "--json"
            ])
        )
        let applied = try XCTUnwrap(result["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(applied.first?["path"] as? String, scriptPath)
        let edited = try String(contentsOf: root.appendingPathComponent(scriptPath), encoding: .utf8)
        XCTAssertTrue(edited.contains("msgbox Route1_Text_Hello, MSGBOX_YESNO @ keep"))
    }

    func testPatchArtifactPlanCommandEmitsPreviewJSONWithoutWritingROM() throws {
        let root = try makeEmeraldProject()
        let patch = root.appendingPathComponent("cleanroom.aps")
        let baseROM = root.appendingPathComponent("pokeemerald.gba")
        try write("a9993e364706816aba3e25717850c26c9cd0d89d  pokeemerald.gba\n", to: root.appendingPathComponent("rom.sha1"))
        try Data("abc".utf8).write(to: baseROM)
        try Data("APS1".utf8).write(to: patch)

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["patch-artifact-plan", root.path, patch.path, "--base-rom", baseROM.path, "--json"])
        )

        XCTAssertEqual(result["isPreviewOnly"] as? Bool, true)
        XCTAssertEqual(result["patchFormat"] as? String, "apsGBA")
        XCTAssertEqual(result["expectedPatchedROMName"] as? String, "pokeemerald-cleanroom.gba")
        XCTAssertEqual(result["outputPath"] as? String, ".pokemonhackstudio/patches/pokeemerald-cleanroom.gba")
        XCTAssertNotNil(result["checksumExpectations"])
        XCTAssertNotNil(result["headerPolicy"])
        XCTAssertNotNil(result["mgbaLaunchPreview"])
        XCTAssertNotNil(result["binaryDiffPreview"])
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/patches/pokeemerald-cleanroom.gba").path))
    }

    func testPatchCreatePreviewCommandEmitsReadonlyJSON() throws {
        let root = try makeEmeraldProject()
        let baseROM = root.appendingPathComponent("clean-base.gba")
        let builtOutput = root.appendingPathComponent("pokeemerald.gba")
        try write(Data("abc".utf8), to: baseROM)
        try write(Data("abcd".utf8), to: builtOutput)
        try write("a9993e364706816aba3e25717850c26c9cd0d89d  clean-base.gba\n", to: root.appendingPathComponent("rom.sha1"))

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["patch-create-preview", root.path, "--base-rom", baseROM.path, "--json"])
        )

        XCTAssertEqual(result["isPreviewOnly"] as? Bool, true)
        XCTAssertEqual(result["isReady"] as? Bool, true)
        XCTAssertEqual(result["candidateFormat"] as? String, "bps")
        XCTAssertEqual(result["sizeDeltaBytes"] as? Int, 1)
        XCTAssertEqual(result["hashesMatch"] as? Bool, false)
        XCTAssertEqual(result["plannedPatchPath"] as? String, ".pokemonhackstudio/patches/clean-base-to-pokeemerald.bps")
        XCTAssertEqual(result["absolutePlannedPatchPath"] as? String, root.appendingPathComponent(".pokemonhackstudio/patches/clean-base-to-pokeemerald.bps").path)
        let base = try XCTUnwrap(result["baseROM"] as? [String: Any])
        XCTAssertEqual(base["sha1"] as? String, "a9993e364706816aba3e25717850c26c9cd0d89d")
        let output = try XCTUnwrap(result["builtOutput"] as? [String: Any])
        XCTAssertEqual(output["relativePath"] as? String, "pokeemerald.gba")
        XCTAssertEqual(output["sha1"] as? String, "81fe8bfe87576c3ecb22426f8e57847382917acf")
        let headerPolicy = try XCTUnwrap(result["headerPolicy"] as? [String: Any])
        XCTAssertEqual(headerPolicy["shouldRewriteHeader"] as? Bool, false)
        let blockedActions = try XCTUnwrap(result["blockedActions"] as? [String])
        XCTAssertTrue(blockedActions.contains("BPS/IPS patch file writes"))
        let diagnostics = try XCTUnwrap(result["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "PATCH_CREATION_PREVIEW_ONLY" })
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/patches/clean-base-to-pokeemerald.bps").path))
    }

    func testPatchCreateCommandWritesIgnoredBPSAndManifest() throws {
        let root = try makeEmeraldProject()
        let baseROM = root.appendingPathComponent("clean-base.gba")
        let builtOutput = root.appendingPathComponent("pokeemerald.gba")
        let baseData = Data("abc".utf8)
        let builtData = Data("abxyz".utf8)
        try write(baseData, to: baseROM)
        try write(builtData, to: builtOutput)
        try write("a9993e364706816aba3e25717850c26c9cd0d89d  clean-base.gba\n", to: root.appendingPathComponent("rom.sha1"))

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["patch-create", root.path, "--base-rom", baseROM.path, "--json"])
        )

        XCTAssertEqual(result["status"] as? String, "created")
        let patchPath = try XCTUnwrap(result["patchPath"] as? String)
        let manifestPath = try XCTUnwrap(result["manifestPath"] as? String)
        XCTAssertTrue(patchPath.hasSuffix(".pokemonhackstudio/patches/clean-base-to-pokeemerald.bps"))
        XCTAssertTrue(manifestPath.hasSuffix(".pokemonhackstudio/patches/clean-base-to-pokeemerald.bps.manifest.json"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: patchPath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: manifestPath))
        XCTAssertNotNil(result["patchSHA1"] as? String)
        let verification = try XCTUnwrap(result["verification"] as? [String: Any])
        XCTAssertEqual(verification["status"] as? String, "passed")
        XCTAssertEqual(verification["appliedOutputSHA1"] as? String, "cd4787c7c33dd2702d7beed6adf42c3e1b209e80")
        XCTAssertEqual(verification["appliedOutputCRC32"] as? String, "e790f51d")
        XCTAssertEqual(verification["appliedOutputSizeBytes"] as? Int, 5)
        XCTAssertEqual(verification["expectedBuiltOutputSHA1"] as? String, "cd4787c7c33dd2702d7beed6adf42c3e1b209e80")
        XCTAssertEqual(verification["expectedBuiltOutputCRC32"] as? String, "e790f51d")
        XCTAssertEqual(verification["expectedBuiltOutputSizeBytes"] as? Int, 5)
        XCTAssertEqual(verification["sha1Matches"] as? Bool, true)
        XCTAssertEqual(verification["crc32Matches"] as? Bool, true)
        XCTAssertEqual(verification["sizeMatches"] as? Bool, true)
        XCTAssertEqual(verification["headerPolicyMatches"] as? Bool, true)
        let verificationHeaderPolicy = try XCTUnwrap(verification["headerPolicy"] as? [String: Any])
        XCTAssertEqual(verificationHeaderPolicy["mode"] as? String, "no-header-rewrite")
        XCTAssertEqual(verificationHeaderPolicy["shouldRewriteHeader"] as? Bool, false)
        let manifest = try XCTUnwrap(result["manifest"] as? [String: Any])
        XCTAssertEqual(manifest["schemaVersion"] as? Int, 2)
        XCTAssertEqual(manifest["action"] as? String, "patch-create")
        XCTAssertEqual(manifest["patchFormat"] as? String, "bps")
        XCTAssertEqual(manifest["baseROMSHA1"] as? String, "a9993e364706816aba3e25717850c26c9cd0d89d")
        XCTAssertEqual(manifest["builtOutputSHA1"] as? String, "cd4787c7c33dd2702d7beed6adf42c3e1b209e80")
        let manifestVerification = try XCTUnwrap(manifest["verification"] as? [String: Any])
        XCTAssertEqual(manifestVerification["status"] as? String, "passed")
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/patches/clean-base-to-pokeemerald.gba").path))
    }

    func testPatchCreateCommandBlocksMismatchedBaseROMWithNonzeroExit() throws {
        let root = try makeEmeraldProject()
        let wrongBase = Data("xyz".utf8)
        let baseROM = root.appendingPathComponent("wrong-base.gba")
        try write(wrongBase, to: baseROM)
        try write(Data("abxyz".utf8), to: root.appendingPathComponent("pokeemerald.gba"))
        try write("a9993e364706816aba3e25717850c26c9cd0d89d  clean-base.gba\n", to: root.appendingPathComponent("rom.sha1"))

        let output = try PokemonHackCLI.run(arguments: ["patch-create", root.path, "--base-rom", baseROM.path, "--json"])
        let result = try decodeJSON(output)

        XCTAssertEqual(result["status"] as? String, "blocked")
        XCTAssertEqual(PokemonHackCLI.exitCode(arguments: ["patch-create"], output: output), 1)
        let diagnostics = try XCTUnwrap(result["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "PATCH_CREATION_BASE_ROM_NOT_COMPATIBLE" })
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/patches/wrong-base-to-pokeemerald.bps").path))
    }

    func testPatchLibraryCommandEmitsEmptyReadOnlyJSONWithoutCreatingDirectories() throws {
        let root = try makeEmeraldProject()

        let output = try PokemonHackCLI.run(arguments: ["patch-library", root.path, "--json"])
        let result = try decodeJSON(output)

        XCTAssertEqual(result["isReadOnly"] as? Bool, true)
        XCTAssertEqual(result["relativeArtifactRoot"] as? String, ".pokemonhackstudio/patches")
        XCTAssertEqual((result["items"] as? [[String: Any]])?.count, 0)
        let diagnostics = try XCTUnwrap(result["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "PATCH_ARTIFACT_LIBRARY_EMPTY" })
        XCTAssertEqual(PokemonHackCLI.exitCode(arguments: ["patch-library", root.path, "--json"], output: output), 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio").path))
    }

    func testPatchLibraryCommandEmitsCreatedArtifactJSONReadOnly() throws {
        let root = try makeEmeraldProject()
        let baseROM = root.appendingPathComponent("clean-base.gba")
        let builtOutput = root.appendingPathComponent("pokeemerald.gba")
        let baseData = Data("abc".utf8)
        let builtData = Data("abxyz".utf8)
        try write(baseData, to: baseROM)
        try write(builtData, to: builtOutput)
        try write("a9993e364706816aba3e25717850c26c9cd0d89d  clean-base.gba\n", to: root.appendingPathComponent("rom.sha1"))
        _ = try PokemonHackCLI.run(arguments: ["patch-create", root.path, "--base-rom", baseROM.path, "--json"])

        let patchRoot = root.appendingPathComponent(".pokemonhackstudio/patches")
        let beforeScanFiles = try FileManager.default.contentsOfDirectory(atPath: patchRoot.path).sorted()
        let output = try PokemonHackCLI.run(arguments: ["patch-library", root.path, "--json"])
        let result = try decodeJSON(output)

        XCTAssertEqual(result["isReadOnly"] as? Bool, true)
        XCTAssertEqual(result["relativeArtifactRoot"] as? String, ".pokemonhackstudio/patches")
        let items = try XCTUnwrap(result["items"] as? [[String: Any]])
        XCTAssertEqual(items.count, 1)
        let item = try XCTUnwrap(items.first)
        XCTAssertEqual(item["fileName"] as? String, "clean-base-to-pokeemerald.bps")
        XCTAssertEqual(item["status"] as? String, "valid")
        XCTAssertEqual(item["manifestStatus"] as? String, "matched")
        XCTAssertEqual(item["patchChecksumStatus"] as? String, "matched")
        XCTAssertEqual(item["baseROMStatus"] as? String, "matched")
        XCTAssertEqual(item["builtOutputStatus"] as? String, "matched")
        let patchSummary = try XCTUnwrap(item["patchSummary"] as? [String: Any])
        XCTAssertEqual(patchSummary["format"] as? String, "bps")
        XCTAssertTrue((item["verificationSummary"] as? String)?.contains("no apply/export was attempted") == true)
        XCTAssertEqual(PokemonHackCLI.exitCode(arguments: ["patch-library", root.path, "--json"], output: output), 0)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: patchRoot.path).sorted(), beforeScanFiles)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/patches/clean-base-to-pokeemerald.gba").path))
    }

    func testPatchDistributionReadinessCommandBlocksNoSelectionJSONWithoutCreatingArtifacts() throws {
        let root = try makeEmeraldProject()
        let baseROM = root.appendingPathComponent("clean-base.gba")
        let builtOutput = root.appendingPathComponent("pokeemerald.gba")
        let baseData = Data("abc".utf8)
        let builtData = Data("abxyz".utf8)
        try write(baseData, to: baseROM)
        try write(builtData, to: builtOutput)
        try write("a9993e364706816aba3e25717850c26c9cd0d89d  clean-base.gba\n", to: root.appendingPathComponent("rom.sha1"))
        _ = try PokemonHackCLI.run(arguments: ["patch-create", root.path, "--base-rom", baseROM.path, "--json"])
        let beforeFiles = try recursiveRelativeFiles(in: root)

        let output = try PokemonHackCLI.run(arguments: ["patch-distribution-readiness", root.path, "--base-rom", baseROM.path, "--json"])
        let result = try decodeJSON(output)

        XCTAssertEqual(result["schemaVersion"] as? Int, 1)
        XCTAssertEqual(result["status"] as? String, "blocked")
        XCTAssertEqual(result["isReadOnly"] as? Bool, true)
        XCTAssertNil(result["selectedPatch"] as? [String: Any])
        XCTAssertNil(result["selectedPatchPath"] as? String)
        XCTAssertNotNil(result["patchCreationPreview"] as? [String: Any])
        XCTAssertNotNil(result["patchArtifactLibrary"] as? [String: Any])
        XCTAssertNotNil(result["manualPlaytestReadiness"] as? [String: Any])
        let diagnostics = try XCTUnwrap(result["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "PATCH_DISTRIBUTION_PATCH_NOT_SELECTED" })
        XCTAssertEqual(PokemonHackCLI.exitCode(arguments: ["patch-distribution-readiness", root.path, "--base-rom", baseROM.path, "--json"], output: output), 0)
        XCTAssertEqual(try recursiveRelativeFiles(in: root), beforeFiles)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/patches/clean-base-to-pokeemerald.gba").path))
    }

    func testPatchDistributionReadinessCommandMatchesExplicitRelativePatchPath() throws {
        let root = try makeEmeraldProject()
        let baseROM = root.appendingPathComponent("clean-base.gba")
        let builtOutput = root.appendingPathComponent("pokeemerald.gba")
        let baseData = Data("abc".utf8)
        let builtData = Data("abxyz".utf8)
        try write(baseData, to: baseROM)
        try write(builtData, to: builtOutput)
        try write("a9993e364706816aba3e25717850c26c9cd0d89d  clean-base.gba\n", to: root.appendingPathComponent("rom.sha1"))
        let created = try decodeJSON(PokemonHackCLI.run(arguments: ["patch-create", root.path, "--base-rom", baseROM.path, "--json"]))
        let patchPath = try XCTUnwrap(created["patchPath"] as? String)
        let relativePatchPath = ".pokemonhackstudio/patches/clean-base-to-pokeemerald.bps"
        let beforeFiles = try recursiveRelativeFiles(in: root)

        let output = try PokemonHackCLI.run(
            arguments: [
                "patch-distribution-readiness",
                root.path,
                "--base-rom",
                baseROM.path,
                "--patch",
                relativePatchPath,
                "--json",
            ]
        )
        let result = try decodeJSON(output)

        XCTAssertTrue(["ready", "readyWithWarnings"].contains(result["status"] as? String))
        XCTAssertEqual(result["selectedPatchPath"] as? String, patchPath)
        XCTAssertEqual(result["selectedPatchRelativePath"] as? String, relativePatchPath)
        let selectedPatch = try XCTUnwrap(result["selectedPatch"] as? [String: Any])
        XCTAssertEqual(selectedPatch["status"] as? String, "valid")
        XCTAssertEqual(selectedPatch["relativePatchPath"] as? String, relativePatchPath)
        let preview = try XCTUnwrap(result["patchCreationPreview"] as? [String: Any])
        let headerPolicy = try XCTUnwrap(preview["headerPolicy"] as? [String: Any])
        XCTAssertEqual(headerPolicy["mode"] as? String, "no-header-rewrite")
        let blockedActions = try XCTUnwrap(result["blockedActions"] as? [String])
        XCTAssertTrue(blockedActions.contains("Patch file creation"))
        XCTAssertTrue(blockedActions.contains("Patch apply/export"))
        XCTAssertEqual(PokemonHackCLI.exitCode(arguments: ["patch-distribution-readiness", root.path, "--base-rom", baseROM.path, "--patch", relativePatchPath, "--json"], output: output), 0)
        XCTAssertEqual(try recursiveRelativeFiles(in: root), beforeFiles)
    }

    func testPatchDistributionReadinessCommandBlocksUnknownPatchPathWithoutAutoSelection() throws {
        let root = try makeEmeraldProject()
        let baseROM = root.appendingPathComponent("clean-base.gba")
        let builtOutput = root.appendingPathComponent("pokeemerald.gba")
        let baseData = Data("abc".utf8)
        let builtData = Data("abxyz".utf8)
        try write(baseData, to: baseROM)
        try write(builtData, to: builtOutput)
        try write("a9993e364706816aba3e25717850c26c9cd0d89d  clean-base.gba\n", to: root.appendingPathComponent("rom.sha1"))
        _ = try PokemonHackCLI.run(arguments: ["patch-create", root.path, "--base-rom", baseROM.path, "--json"])
        let missingRelativePath = ".pokemonhackstudio/patches/missing.bps"
        let beforeFiles = try recursiveRelativeFiles(in: root)

        let output = try PokemonHackCLI.run(
            arguments: [
                "patch-distribution-readiness",
                root.path,
                "--base-rom",
                baseROM.path,
                "--patch",
                missingRelativePath,
                "--json",
            ]
        )
        let result = try decodeJSON(output)

        XCTAssertEqual(result["status"] as? String, "blocked")
        XCTAssertNil(result["selectedPatch"] as? [String: Any])
        XCTAssertEqual(result["selectedPatchRelativePath"] as? String, missingRelativePath)
        let library = try XCTUnwrap(result["patchArtifactLibrary"] as? [String: Any])
        XCTAssertEqual((library["items"] as? [[String: Any]])?.count, 1)
        let diagnostics = try XCTUnwrap(result["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "PATCH_DISTRIBUTION_PATCH_NOT_FOUND" })
        XCTAssertEqual(PokemonHackCLI.exitCode(arguments: ["patch-distribution-readiness", root.path, "--base-rom", baseROM.path, "--patch", missingRelativePath, "--json"], output: output), 0)
        XCTAssertEqual(try recursiveRelativeFiles(in: root), beforeFiles)
    }

    func testROMMutationManifestCommandEmitsDryRunJSONWithoutWritingFiles() throws {
        let rom = try makeTestROM()
        let root = rom.deletingLastPathComponent()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "rom-mutation-manifest",
                rom.path,
                "--replace",
                "0x120:2:AABB",
                "--repoint",
                "0x100:0x180",
                "--allocate",
                "0x20:0x10",
                "--json"
            ])
        )

        XCTAssertEqual(result["schemaVersion"] as? Int, 1)
        XCTAssertEqual(result["isDryRun"] as? Bool, true)
        XCTAssertEqual(result["canApply"] as? Bool, false)
        XCTAssertEqual(result["profile"] as? String, "binaryROM")
        let baseROM = try XCTUnwrap(result["baseROM"] as? [String: Any])
        XCTAssertEqual(baseROM["fileName"] as? String, "test.gba")
        XCTAssertNotNil(baseROM["sha1"] as? String)
        XCTAssertNotNil(baseROM["crc32"] as? String)
        let sourceTreeFirst = try XCTUnwrap(result["sourceTreeFirst"] as? [String: Any])
        XCTAssertEqual(sourceTreeFirst["status"] as? String, "binaryOnlyCandidate")
        XCTAssertEqual(sourceTreeFirst["canUseBinaryOnlyPlan"] as? Bool, true)
        let previews = try XCTUnwrap(result["operationPreviews"] as? [[String: Any]])
        XCTAssertEqual(previews.count, 3)
        XCTAssertTrue(previews.allSatisfy { $0["canApply"] as? Bool == false })
        XCTAssertTrue(previews.contains { $0["kind"] as? String == "replaceBytes" && $0["status"] as? String == "previewOnly" })
        XCTAssertTrue(previews.contains { $0["kind"] as? String == "repointPointer" && $0["status"] as? String == "previewOnly" })
        XCTAssertTrue(previews.contains { $0["kind"] as? String == "allocateFreeSpace" && $0["status"] as? String == "previewOnly" })
        let ignoredOutputGuidance = try XCTUnwrap(result["ignoredOutputGuidance"] as? [String: Any])
        XCTAssertEqual(ignoredOutputGuidance["willWriteFiles"] as? Bool, false)
        XCTAssertEqual(ignoredOutputGuidance["relativeRoot"] as? String, ".pokemonhackstudio/rom-mutations/test")
        let diagnostics = try XCTUnwrap(result["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "BINARY_ROM_MUTATION_DRY_RUN_ONLY" })
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "BINARY_ROM_MUTATION_IGNORED_OUTPUT_GUIDANCE" })
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/rom-mutations").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/backups").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/rom-mutations/test/test-patched.gba").path))
    }

    func testROMMutationAuditCommandEmitsReadyJSONWithoutConfirmationOrWrites() throws {
        let rom = try makeTestROM()
        let root = rom.deletingLastPathComponent()
        let originalData = try Data(contentsOf: rom)
        let dryRunJSON = try PokemonHackCLI.run(arguments: [
            "rom-mutation-manifest",
            rom.path,
            "--workspace-root",
            root.path,
            "--replace",
            "0x120:2:AABB",
            "--json"
        ])
        let dryRun = try decodeJSON(dryRunJSON)
        let applyReview = try XCTUnwrap(dryRun["applyReview"] as? [String: Any])
        let reviewToken = try XCTUnwrap(applyReview["reviewToken"] as? String)
        let manifestURL = root.appendingPathComponent("dry-run.json")
        try dryRunJSON.write(to: manifestURL, atomically: true, encoding: .utf8)

        let output = try PokemonHackCLI.run(arguments: [
            "rom-mutation-audit",
            rom.path,
            "--manifest",
            manifestURL.path,
            "--workspace-root",
            root.path,
            "--json"
        ])
        let audit = try decodeJSON(output)

        XCTAssertEqual(audit["schemaVersion"] as? Int, 1)
        XCTAssertEqual(audit["status"] as? String, "ready")
        XCTAssertEqual(audit["inputPath"] as? String, rom.path)
        XCTAssertEqual(audit["dryRunManifestPath"] as? String, manifestURL.path)
        XCTAssertNotNil(audit["dryRunManifestSHA1"] as? String)
        XCTAssertEqual(audit["reviewToken"] as? String, reviewToken)
        XCTAssertEqual(audit["expectedReviewToken"] as? String, reviewToken)
        XCTAssertEqual(audit["isReviewTokenStale"] as? Bool, false)
        XCTAssertEqual(PokemonHackCLI.exitCode(arguments: ["rom-mutation-audit"], output: output), 0)
        let artifactReviews = try XCTUnwrap(audit["artifactReviews"] as? [[String: Any]])
        XCTAssertEqual(artifactReviews.first { $0["kind"] as? String == "originalROMBackup" }?["status"] as? String, "pendingExplicitApply")
        XCTAssertEqual(artifactReviews.first { $0["kind"] as? String == "applyManifest" }?["status"] as? String, "pendingExplicitApply")
        XCTAssertEqual(try Data(contentsOf: rom), originalData)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/rom-mutations/test/test-patched.gba").path))

        XCTAssertThrowsError(
            try PokemonHackCLI.run(arguments: [
                "rom-mutation-audit",
                rom.path,
                "--manifest",
                manifestURL.path,
                "--workspace-root",
                root.path,
                "--confirm",
                reviewToken,
                "--json"
            ])
        ) { error in
            XCTAssertEqual(error as? CLIError, .usage)
        }
    }

    func testROMMutationAuditCommandReturnsBlockedJSONForMissingInputs() throws {
        let rom = try makeTestROM()
        let root = rom.deletingLastPathComponent()
        let originalData = try Data(contentsOf: rom)
        let dryRunJSON = try PokemonHackCLI.run(arguments: [
            "rom-mutation-manifest",
            rom.path,
            "--workspace-root",
            root.path,
            "--replace",
            "0x120:2:AABB",
            "--json"
        ])
        let manifestURL = root.appendingPathComponent("dry-run.json")
        try dryRunJSON.write(to: manifestURL, atomically: true, encoding: .utf8)

        let missingManifestOutput = try PokemonHackCLI.run(arguments: [
            "rom-mutation-audit",
            rom.path,
            "--workspace-root",
            root.path,
            "--json"
        ])
        let missingManifest = try decodeJSON(missingManifestOutput)
        XCTAssertEqual(missingManifest["status"] as? String, "blocked")
        var diagnostics = try XCTUnwrap(missingManifest["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "BINARY_ROM_MUTATION_AUDIT_MANIFEST_REQUIRED" })
        XCTAssertEqual(PokemonHackCLI.exitCode(arguments: ["rom-mutation-audit"], output: missingManifestOutput), 1)

        let missingWorkspaceOutput = try PokemonHackCLI.run(arguments: [
            "rom-mutation-audit",
            rom.path,
            "--manifest",
            manifestURL.path,
            "--json"
        ])
        let missingWorkspace = try decodeJSON(missingWorkspaceOutput)
        XCTAssertEqual(missingWorkspace["status"] as? String, "blocked")
        diagnostics = try XCTUnwrap(missingWorkspace["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "BINARY_ROM_MUTATION_AUDIT_WORKSPACE_ROOT_REQUIRED" })
        XCTAssertEqual(PokemonHackCLI.exitCode(arguments: ["rom-mutation-audit"], output: missingWorkspaceOutput), 1)
        XCTAssertEqual(try Data(contentsOf: rom), originalData)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio").path))
    }

    func testROMMutationAuditCommandBlocksSourceTreeAndBaseDriftWithoutWriting() throws {
        let rom = try makeTestROM()
        let root = rom.deletingLastPathComponent()
        let originalData = try Data(contentsOf: rom)
        let dryRunJSON = try PokemonHackCLI.run(arguments: [
            "rom-mutation-manifest",
            rom.path,
            "--replace",
            "0x120:2:AABB",
            "--json"
        ])
        let manifestURL = root.appendingPathComponent("dry-run.json")
        try dryRunJSON.write(to: manifestURL, atomically: true, encoding: .utf8)
        let sourceRoot = root.appendingPathComponent("pokeemerald")
        try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: sourceRoot.appendingPathComponent("Makefile"))
        try write("{\"group_order\":[]}\n", to: sourceRoot.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: sourceRoot.appendingPathComponent("data/layouts/layouts.json"))
        try FileManager.default.createDirectory(at: sourceRoot.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: sourceRoot.appendingPathComponent("src"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: sourceRoot.appendingPathComponent("graphics/pokenav"), withIntermediateDirectories: true)

        let sourceBlockedOutput = try PokemonHackCLI.run(arguments: [
            "rom-mutation-audit",
            rom.path,
            "--manifest",
            manifestURL.path,
            "--workspace-root",
            root.path,
            "--json"
        ])
        let sourceBlocked = try decodeJSON(sourceBlockedOutput)
        XCTAssertEqual(sourceBlocked["status"] as? String, "blocked")
        var diagnostics = try XCTUnwrap(sourceBlocked["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "BINARY_ROM_MUTATION_AUDIT_SOURCE_TREE_AVAILABLE_REFUSED" })
        XCTAssertEqual(PokemonHackCLI.exitCode(arguments: ["rom-mutation-audit"], output: sourceBlockedOutput), 1)
        XCTAssertEqual(try Data(contentsOf: rom), originalData)

        try FileManager.default.removeItem(at: sourceRoot)
        var drifted = originalData
        drifted[0x130] = 0x44
        try drifted.write(to: rom)
        let driftBlockedOutput = try PokemonHackCLI.run(arguments: [
            "rom-mutation-audit",
            rom.path,
            "--manifest",
            manifestURL.path,
            "--workspace-root",
            root.path,
            "--json"
        ])
        let driftBlocked = try decodeJSON(driftBlockedOutput)
        XCTAssertEqual(driftBlocked["status"] as? String, "blocked")
        diagnostics = try XCTUnwrap(driftBlocked["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "BINARY_ROM_MUTATION_APPLY_BASE_SHA1_DRIFT" })
        XCTAssertEqual(PokemonHackCLI.exitCode(arguments: ["rom-mutation-audit"], output: driftBlockedOutput), 1)
        XCTAssertEqual(try Data(contentsOf: rom), drifted)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio").path))
    }

    func testROMMutationApplyCommandAppliesReviewedReplacementInPlace() throws {
        let rom = try makeTestROM()
        let root = rom.deletingLastPathComponent()
        let originalData = try Data(contentsOf: rom)
        let dryRunJSON = try PokemonHackCLI.run(arguments: [
            "rom-mutation-manifest",
            rom.path,
            "--workspace-root",
            root.path,
            "--replace",
            "0x120:2:AABB",
            "--json"
        ])
        let dryRun = try decodeJSON(dryRunJSON)
        let applyReview = try XCTUnwrap(dryRun["applyReview"] as? [String: Any])
        XCTAssertEqual(applyReview["isReviewable"] as? Bool, true)
        let reviewToken = try XCTUnwrap(applyReview["reviewToken"] as? String)
        let previews = try XCTUnwrap(dryRun["operationPreviews"] as? [[String: Any]])
        let replacement = try XCTUnwrap(previews.first)
        XCTAssertNotNil(replacement["originalSpanSHA1"] as? String)
        XCTAssertEqual(replacement["replacementHex"] as? String, "AABB")
        let manifestURL = root.appendingPathComponent("dry-run.json")
        try dryRunJSON.write(to: manifestURL, atomically: true, encoding: .utf8)

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "rom-mutation-apply",
                rom.path,
                "--manifest",
                manifestURL.path,
                "--workspace-root",
                root.path,
                "--confirm",
                reviewToken,
                "--json"
            ])
        )

        XCTAssertEqual(apply["status"] as? String, "applied")
        let updatedData = try Data(contentsOf: rom)
        XCTAssertEqual(Array(updatedData[0x120..<0x122]), [0xAA, 0xBB])
        let backupPath = try XCTUnwrap(apply["backupPath"] as? String)
        let applyManifestPath = try XCTUnwrap(apply["manifestPath"] as? String)
        XCTAssertTrue(backupPath.contains(".pokemonhackstudio/rom-mutations/test/"))
        XCTAssertTrue(applyManifestPath.contains(".pokemonhackstudio/rom-mutations/test/"))
        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: backupPath)), originalData)
        XCTAssertTrue(FileManager.default.fileExists(atPath: applyManifestPath))
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/rom-mutations/test/test-patched.gba").path))
    }

    func testROMMutationApplyCommandReturnsBlockedJSONForMissingOrWrongConfirmation() throws {
        let rom = try makeTestROM()
        let root = rom.deletingLastPathComponent()
        let originalData = try Data(contentsOf: rom)
        let dryRunJSON = try PokemonHackCLI.run(arguments: [
            "rom-mutation-manifest",
            rom.path,
            "--workspace-root",
            root.path,
            "--replace",
            "0x120:2:AABB",
            "--json"
        ])
        let manifestURL = root.appendingPathComponent("dry-run.json")
        try dryRunJSON.write(to: manifestURL, atomically: true, encoding: .utf8)

        let missing = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "rom-mutation-apply",
                rom.path,
                "--manifest",
                manifestURL.path,
                "--workspace-root",
                root.path,
                "--json"
            ])
        )
        XCTAssertEqual(missing["status"] as? String, "blocked")
        var diagnostics = try XCTUnwrap(missing["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "BINARY_ROM_MUTATION_APPLY_CONFIRMATION_MISMATCH" })

        let wrong = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "rom-mutation-apply",
                rom.path,
                "--manifest",
                manifestURL.path,
                "--workspace-root",
                root.path,
                "--confirm",
                "romreplace-wrong",
                "--json"
            ])
        )
        XCTAssertEqual(wrong["status"] as? String, "blocked")
        diagnostics = try XCTUnwrap(wrong["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "BINARY_ROM_MUTATION_APPLY_CONFIRMATION_MISMATCH" })
        XCTAssertEqual(try Data(contentsOf: rom), originalData)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio").path))
    }

    func testROMMutationApplyCommandBlocksSourceTreeAndBaseDriftWithoutWriting() throws {
        let rom = try makeTestROM()
        let root = rom.deletingLastPathComponent()
        let originalData = try Data(contentsOf: rom)
        let dryRunJSON = try PokemonHackCLI.run(arguments: [
            "rom-mutation-manifest",
            rom.path,
            "--replace",
            "0x120:2:AABB",
            "--json"
        ])
        let dryRun = try decodeJSON(dryRunJSON)
        let token = try XCTUnwrap((dryRun["applyReview"] as? [String: Any])?["reviewToken"] as? String)
        let manifestURL = root.appendingPathComponent("dry-run.json")
        try dryRunJSON.write(to: manifestURL, atomically: true, encoding: .utf8)
        let sourceRoot = root.appendingPathComponent("pokeemerald")
        try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: sourceRoot.appendingPathComponent("Makefile"))
        try write("{\"group_order\":[]}\n", to: sourceRoot.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: sourceRoot.appendingPathComponent("data/layouts/layouts.json"))
        try FileManager.default.createDirectory(at: sourceRoot.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: sourceRoot.appendingPathComponent("src"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: sourceRoot.appendingPathComponent("graphics/pokenav"), withIntermediateDirectories: true)

        let sourceBlocked = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "rom-mutation-apply",
                rom.path,
                "--manifest",
                manifestURL.path,
                "--workspace-root",
                root.path,
                "--confirm",
                token,
                "--json"
            ])
        )
        XCTAssertEqual(sourceBlocked["status"] as? String, "blocked")
        var diagnostics = try XCTUnwrap(sourceBlocked["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "BINARY_ROM_MUTATION_APPLY_SOURCE_TREE_AVAILABLE_REFUSED" })
        XCTAssertEqual(try Data(contentsOf: rom), originalData)

        try FileManager.default.removeItem(at: sourceRoot)
        var drifted = originalData
        drifted[0x130] = 0x44
        try drifted.write(to: rom)
        let driftBlocked = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "rom-mutation-apply",
                rom.path,
                "--manifest",
                manifestURL.path,
                "--workspace-root",
                root.path,
                "--confirm",
                token,
                "--json"
            ])
        )
        XCTAssertEqual(driftBlocked["status"] as? String, "blocked")
        diagnostics = try XCTUnwrap(driftBlocked["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "BINARY_ROM_MUTATION_APPLY_BASE_SHA1_DRIFT" })
        XCTAssertEqual(try Data(contentsOf: rom), drifted)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio").path))
    }

    func testPatchApplyExportCommandWritesIgnoredROMAndManifest() throws {
        let root = try makeEmeraldProject()
        let patch = root.appendingPathComponent("cleanroom.ips")
        let baseROM = root.appendingPathComponent("pokeemerald.gba")
        let baseData = Data("abc".utf8)
        let patchedData = Data("adc".utf8)
        try write("a9993e364706816aba3e25717850c26c9cd0d89d  pokeemerald.gba\n", to: root.appendingPathComponent("rom.sha1"))
        try baseData.write(to: baseROM)
        try (Data("PATCH".utf8) + Data([0x00, 0x00, 0x01, 0x00, 0x01, 0x64]) + Data("EOF".utf8)).write(to: patch)

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["patch-apply-export", root.path, patch.path, "--base-rom", baseROM.path, "--json"])
        )

        XCTAssertEqual(result["status"] as? String, "exported")
        XCTAssertEqual(result["outputROMSHA1"] as? String, "aa3159afc1d353ecf7d91cbd242724ce1f99d443")
        let outputPath = try XCTUnwrap(result["outputPath"] as? String)
        let manifestPath = try XCTUnwrap(result["manifestPath"] as? String)
        XCTAssertTrue(outputPath.hasSuffix(".pokemonhackstudio/patches/pokeemerald-cleanroom.gba"))
        XCTAssertTrue(manifestPath.hasSuffix(".pokemonhackstudio/patches/pokeemerald-cleanroom.gba.manifest.json"))
        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: outputPath)), patchedData)
        XCTAssertTrue(FileManager.default.fileExists(atPath: manifestPath))
    }

    func testRomDiffPreviewCommandEmitsStandaloneReadonlyPreview() throws {
        let rom = try makeTestROM()
        let patch = rom.deletingLastPathComponent().appendingPathComponent("change.ips")
        let ips = Data("PATCH".utf8)
            + Data([0x00, 0x01, 0x10, 0x00, 0x02, 0xAA, 0xBB])
            + Data("EOF".utf8)
        try ips.write(to: patch)

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["rom-diff-preview", patch.path, "--base-rom", rom.path, "--json"])
        )

        XCTAssertEqual(result["isPreviewOnly"] as? Bool, true)
        XCTAssertEqual(result["patchFormat"] as? String, "ips")
        XCTAssertEqual(result["previewedChangeCount"] as? Int, 1)
        XCTAssertEqual(result["changedByteCount"] as? Int, 2)
        XCTAssertNotNil(result["changes"])
        XCTAssertNotNil(result["freeSpaceSuitability"])
        XCTAssertNotNil(result["pointerRepointPlans"])
        XCTAssertNotNil(result["backupExportManifest"])
        XCTAssertNotNil(result["applyExportState"])
    }

    func testRomGraphCommandEmitsSemanticRuns() throws {
        let rom = try makeTestROM()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["rom-graph", rom.path, "--json"])
        )

        XCTAssertNotNil(result["headerFacts"])
        XCTAssertNotNil(result["semanticRuns"])
        XCTAssertNotNil(result["anchors"])
        XCTAssertNotNil(result["pointerCandidates"])
    }

    func testRomInspectCommandEmitsReadOnlyStandaloneReport() throws {
        let rom = try makeTestROM()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["rom-inspect", rom.path, "--json"])
        )

        XCTAssertEqual(result["isReadOnly"] as? Bool, true)
        XCTAssertNotNil(result["projectIndex"])
        XCTAssertNotNil(result["graph"])
        XCTAssertNotNil(result["resourceEntry"])
        XCTAssertNotNil(result["assetCatalog"])
        XCTAssertNotNil(result["playtestReport"])
    }

    func testNDSInspectCommandsEmitReadOnlyJSON() throws {
        let rom = try makeTestNDSROM()

        let inspect = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-inspect", rom.path, "--json"])
        )
        XCTAssertEqual(inspect["isReadOnly"] as? Bool, true)
        XCTAssertNotNil(inspect["projectIndex"])
        let header = try XCTUnwrap(inspect["header"] as? [String: Any])
        XCTAssertEqual(header["gameCode"] as? String, "ADAE")
        let fileSystem = try XCTUnwrap(inspect["fileSystem"] as? [String: Any])
        XCTAssertEqual(fileSystem["fileCount"] as? Int, 3)
        let narcArchives = try XCTUnwrap(inspect["narcArchives"] as? [[String: Any]])
        XCTAssertEqual(narcArchives.count, 1)

        let files = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-files", rom.path, "--json"])
        )
        XCTAssertEqual(files["fileCount"] as? Int, 3)
        let rows = try XCTUnwrap(files["files"] as? [[String: Any]])
        XCTAssertTrue(rows.contains { $0["path"] as? String == "sub/child.narc" })
        XCTAssertTrue(rows.contains { $0["path"] as? String == "sound_data.sdat" && $0["kind"] as? String == "audio" })

        let dispatched = try decodeJSON(
            PokemonHackCLI.run(arguments: ["rom-inspect", rom.path, "--json"])
        )
        XCTAssertNotNil(dispatched["fileSystem"])
        XCTAssertNotNil(dispatched["narcArchives"])
    }

    func testNARCInspectCommandEmitsMemberJSON() throws {
        let root = try makeTemporaryDirectory()
        let narc = root.appendingPathComponent("fixture.narc")
        try makeTestNARC().write(to: narc)

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["narc-inspect", narc.path, "--json"])
        )

        XCTAssertEqual(result["memberCount"] as? Int, 2)
        let members = try XCTUnwrap(result["members"] as? [[String: Any]])
        XCTAssertEqual(members.first?["path"] as? String, "first.bin")
    }

    func testResourceIndexCommandSurfacesNDSROMResources() throws {
        let rom = try makeTestNDSROM()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resource-index", rom.path, "--json"])
        )

        XCTAssertEqual(result["platform"] as? String, "ndsROM")
        XCTAssertEqual(result["family"] as? String, "diamondPearl")
        XCTAssertEqual(result["writePolicy"] as? String, "readOnly")
        let items = try XCTUnwrap(result["items"] as? [[String: Any]])
        XCTAssertTrue(items.contains { $0["category"] as? String == "NitroFS File" })
        XCTAssertTrue(items.contains { $0["category"] as? String == "NARC Member" })
    }

    func testResourcesSummaryCommandEmitsShallowEntries() throws {
        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resources", "--summary", "--json"])
        )

        let entries = try XCTUnwrap(result["entries"] as? [[String: Any]])
        XCTAssertFalse(entries.isEmpty)
        XCTAssertTrue(entries.allSatisfy { $0["detailMode"] as? String == "summary" })
        XCTAssertTrue(entries.allSatisfy { (($0["items"] as? [[String: Any]]) ?? []).isEmpty })
    }

    func testIndexAndResourceIndexCommandsSurfaceNDSSourceTrees() throws {
        let root = try makeTestNDSDecompRoot()

        let index = try decodeJSON(
            PokemonHackCLI.run(arguments: ["index", root.path, "--json"])
        )
        XCTAssertEqual(index["profile"] as? String, "pokeplatinum")
        XCTAssertEqual(index["writePolicy"] as? String, "readOnly")
        let capabilities = try XCTUnwrap(index["capabilities"] as? [String])
        XCTAssertTrue(capabilities.contains("ndsSourceTreeIndex"))
        XCTAssertTrue(capabilities.contains("ndsDataCatalog"))
        XCTAssertFalse(capabilities.contains("buildRunner"))

        let resource = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resource-index", root.path, "--json"])
        )
        XCTAssertEqual(resource["platform"] as? String, "ndsSource")
        XCTAssertEqual(resource["profile"] as? String, "pokeplatinum")
        XCTAssertEqual(resource["writePolicy"] as? String, "readOnly")
        let items = try XCTUnwrap(resource["items"] as? [[String: Any]])
        XCTAssertTrue(items.contains { $0["category"] as? String == "NDS Variant" })
        XCTAssertTrue(items.contains { $0["category"] as? String == "NDS Build Target" })
        XCTAssertTrue(items.contains { $0["category"] as? String == "NDS Data species" })
        let audioItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data audio" && $0["path"] as? String == "res/sound/main.sdat" })
        let audioFacts = try XCTUnwrap(audioItem["facts"] as? [[String: Any]])
        XCTAssertTrue(audioFacts.contains { $0["label"] as? String == "Audio Preview" && $0["value"] as? String == "ready" })
        XCTAssertTrue(audioFacts.contains { $0["label"] as? String == "Audio Preview Blocked Actions" && ($0["value"] as? String)?.contains("Playback") == true })
    }

    func testNDSDataCatalogCommandEmitsReadOnlyJSON() throws {
        let root = try makeTestNDSDecompRoot()

        let catalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", root.path, "--json"])
        )
        XCTAssertEqual(catalog["profile"] as? String, "pokeplatinum")
        XCTAssertEqual(catalog["family"] as? String, "platinum")
        XCTAssertEqual(catalog["isReadOnly"] as? Bool, true)
        let summary = try XCTUnwrap(catalog["summary"] as? [String: Any])
        XCTAssertGreaterThan(summary["recordCount"] as? Int ?? 0, 0)
        let records = try XCTUnwrap(catalog["records"] as? [[String: Any]])
        XCTAssertTrue(records.contains { $0["domain"] as? String == "species" && $0["relativePath"] as? String == "res/pokemon/abra/data.json" })
        let containerRecord = try XCTUnwrap(records.first { $0["relativePath"] as? String == "res/prebuilt/poketool/personal/personal.narc" })
        let containerSummary = try XCTUnwrap(containerRecord["containerSummary"] as? [String: Any])
        XCTAssertEqual(containerSummary["kind"] as? String, "narc")
        XCTAssertEqual(containerSummary["memberCount"] as? Int, 2)
        let memberFingerprints = try XCTUnwrap(containerSummary["memberFingerprints"] as? [[String: Any]])
        XCTAssertEqual(memberFingerprints.count, 2)
        XCTAssertEqual(memberFingerprints.first?["formatHint"] as? String, "nitroPalette")
        XCTAssertEqual(memberFingerprints.first?["leadingMagicASCII"] as? String, "NCLR")
        let firstPreview = try XCTUnwrap(memberFingerprints.first?["preview"] as? [String: Any])
        XCTAssertEqual(firstPreview["status"] as? String, "ready")
        XCTAssertEqual(firstPreview["format"] as? String, "nitroPalette")
        XCTAssertEqual(memberFingerprints.last?["compressionHint"] as? String, "lz77Candidate")
        let compressedPreview = try XCTUnwrap(memberFingerprints.last?["preview"] as? [String: Any])
        XCTAssertEqual(compressedPreview["status"] as? String, "blocked")
        let compressedDiagnostics = try XCTUnwrap(compressedPreview["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(compressedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_MEMBER_PREVIEW_COMPRESSED_BLOCKED" })
        let migrationPlan = try XCTUnwrap(containerRecord["migrationPlan"] as? [String: Any])
        XCTAssertEqual(migrationPlan["status"] as? String, "previewOnly")
        let sourceCandidates = try XCTUnwrap(migrationPlan["sourceTreeCandidates"] as? [String])
        XCTAssertTrue(sourceCandidates.contains("res/prebuilt/poketool/personal/personal.narc"))
        let migrationFacts = try XCTUnwrap(containerRecord["facts"] as? [[String: Any]])
        XCTAssertTrue(migrationFacts.contains { $0["label"] as? String == "Migration Status" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(migrationFacts.contains { $0["label"] as? String == "Migration Blocked Actions" && ($0["value"] as? String)?.contains("ROM export") == true })
        let textRecord = try XCTUnwrap(records.first { $0["relativePath"] as? String == "res/text/story.json" })
        let textPreview = try XCTUnwrap(textRecord["textBankPreview"] as? [String: Any])
        XCTAssertEqual(textPreview["status"] as? String, "ready")
        XCTAssertEqual(textPreview["decodedStringCount"] as? Int, 1)
        let textFacts = try XCTUnwrap(textRecord["facts"] as? [[String: Any]])
        XCTAssertTrue(textFacts.contains { $0["label"] as? String == "Text Bank Preview" && $0["value"] as? String == "ready" })
        XCTAssertTrue(textFacts.contains { $0["label"] as? String == "Decoded Strings" && $0["value"] as? String == "1" })
        let textDiagnostics = try XCTUnwrap(textRecord["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(textDiagnostics.contains { $0["code"] as? String == "NDS_TEXT_BANK_PREVIEW_READ_ONLY" })
        let audioRecord = try XCTUnwrap(records.first { $0["domain"] as? String == "audio" && $0["relativePath"] as? String == "res/sound/main.sdat" })
        let audioPreview = try XCTUnwrap(audioRecord["audioPreview"] as? [String: Any])
        XCTAssertEqual(audioPreview["status"] as? String, "ready")
        XCTAssertEqual(audioPreview["format"] as? String, "nitroSoundArchive")
        let audioBlockedActions = try XCTUnwrap(audioPreview["blockedActions"] as? [String])
        XCTAssertTrue(audioBlockedActions.contains("Playback"))
        XCTAssertTrue(audioBlockedActions.contains("Mutation apply"))
        let audioFacts = try XCTUnwrap(audioRecord["facts"] as? [[String: Any]])
        XCTAssertTrue(audioFacts.contains { $0["label"] as? String == "Audio Preview" && $0["value"] as? String == "ready" })
        XCTAssertTrue(audioFacts.contains { $0["label"] as? String == "Audio Preview Blocked Actions" && ($0["value"] as? String)?.contains("ROM export") == true })
        let diagnostics = try XCTUnwrap(catalog["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "NDS_DATA_CATALOG_READ_ONLY" })

        let rom = try makeTestNDSROM()
        let romCatalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", rom.path, "--json"])
        )
        XCTAssertEqual(romCatalog["profile"] as? String, "ndsROM")
        let romRecords = try XCTUnwrap(romCatalog["records"] as? [[String: Any]])
        XCTAssertTrue(romRecords.contains { $0["relativePath"] as? String == "sub/child.narc" })
        let romContainerRecord = try XCTUnwrap(romRecords.first { $0["relativePath"] as? String == "sub/child.narc" })
        let romContainerSummary = try XCTUnwrap(romContainerRecord["containerSummary"] as? [String: Any])
        let romFingerprints = try XCTUnwrap(romContainerSummary["memberFingerprints"] as? [[String: Any]])
        XCTAssertEqual(romFingerprints.first?["formatHint"] as? String, "nitroPalette")
        let romPreview = try XCTUnwrap(romFingerprints.first?["preview"] as? [String: Any])
        XCTAssertEqual(romPreview["status"] as? String, "ready")
        XCTAssertEqual(romPreview["format"] as? String, "nitroPalette")
        let romMigrationPlan = try XCTUnwrap(romContainerRecord["migrationPlan"] as? [String: Any])
        XCTAssertEqual(romMigrationPlan["status"] as? String, "previewOnly")
        let romExtractedCandidates = try XCTUnwrap(romMigrationPlan["extractedDirectoryCandidates"] as? [String])
        XCTAssertTrue(romExtractedCandidates.contains("sub/child"))
        let romAudioRecord = try XCTUnwrap(romRecords.first { $0["domain"] as? String == "audio" && $0["relativePath"] as? String == "sound_data.sdat" })
        let romAudioPreview = try XCTUnwrap(romAudioRecord["audioPreview"] as? [String: Any])
        XCTAssertEqual(romAudioPreview["status"] as? String, "ready")
        XCTAssertEqual(romAudioPreview["format"] as? String, "nitroSoundArchive")
        let romDiagnostics = try XCTUnwrap(romCatalog["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(romDiagnostics.contains { $0["code"] as? String == "NDS_DATA_CATALOG_BINARY_SUMMARY_READ_ONLY" })
    }

    func testNDSDataCatalogCommandEmitsPlatinumMapInventoryJSON() throws {
        let root = try makeTestNDSDecompRoot()

        let catalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", root.path, "--json"])
        )

        XCTAssertEqual(catalog["profile"] as? String, "pokeplatinum")
        XCTAssertEqual(catalog["family"] as? String, "platinum")
        let records = try XCTUnwrap(catalog["records"] as? [[String: Any]])
        let mapRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "res/field/maps" })
        XCTAssertEqual(mapRoot["domain"] as? String, "maps")
        XCTAssertEqual(mapRoot["format"] as? String, "directory")
        XCTAssertEqual(mapRoot["recordCount"] as? Int, 1)
        let mapRootFacts = try XCTUnwrap(mapRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(mapRootFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "platinumMapInventory" })
        XCTAssertTrue(mapRootFacts.contains { $0["label"] as? String == "Gen IV Source Provenance" && $0["value"] as? String == "platinum:res/field/maps" })
        XCTAssertTrue(mapRootFacts.contains { $0["label"] as? String == "Gen IV Readiness" && $0["value"] as? String == "inventoryOnly" })
        XCTAssertTrue(mapRootFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("semantic editing") == true })
        XCTAssertTrue(mapRootFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("NARC/container work") == true })
        XCTAssertTrue(mapRootFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("mutation apply") == true })
        XCTAssertTrue(mapRootFacts.contains { $0["label"] as? String == "Gen IV Action State" && ($0["value"] as? String)?.contains("inventory-only map metadata") == true })
        XCTAssertFalse(mapRootFacts.contains { $0["label"] as? String == "Migration Status" })
        let mapRootDiagnostics = try XCTUnwrap(mapRoot["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(mapRootDiagnostics.contains { $0["code"] as? String == "NDS_DATA_PLATINUM_MAP_INVENTORY_PREVIEW_ONLY" })
        XCTAssertTrue(mapRootDiagnostics.contains { $0["code"] as? String == "NDS_DATA_PLATINUM_MAP_WRITE_BLOCKED" })

        let mapMember = try XCTUnwrap(records.first { $0["relativePath"] as? String == "res/field/maps/route201/map.bin" })
        let mapMemberFacts = try XCTUnwrap(mapMember["facts"] as? [[String: Any]])
        XCTAssertTrue(mapMemberFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "platinumMapMember" })
        XCTAssertTrue(mapMemberFacts.contains { $0["label"] as? String == "Gen IV Source Provenance" && $0["value"] as? String == "platinum:res/field/maps" })
        XCTAssertTrue(mapMemberFacts.contains { $0["label"] as? String == "Related Rows" && $0["value"] as? String == "4" })
        let relatedRecords = try XCTUnwrap(mapMember["relatedRecords"] as? [[String: Any]])
        XCTAssertTrue(relatedRecords.contains { $0["recordID"] as? String == "maps:res/field/matrices/route201.json" })
        XCTAssertTrue(relatedRecords.contains { $0["recordID"] as? String == "maps:res/field/events/route201.json" })
        XCTAssertTrue(relatedRecords.contains { $0["recordID"] as? String == "scripts:res/field/scripts/route201.s" })
        XCTAssertTrue(relatedRecords.contains { $0["recordID"] as? String == "text:res/text/route201.txt" })
        let mapMemberPacket = try XCTUnwrap(mapMember["mapReviewPacket"] as? [String: Any])
        XCTAssertEqual(mapMemberPacket["posture"] as? String, "reviewOnly")
        XCTAssertEqual(mapMemberPacket["component"] as? String, "map")
        XCTAssertEqual(mapMemberPacket["sourceRole"] as? String, "platinumMapMember")
        XCTAssertEqual(mapMemberPacket["sourceProvenance"] as? String, "platinum:res/field/maps")
        XCTAssertEqual(mapMemberPacket["truncatedRelatedRecordCount"] as? Int, 0)
        let mapMemberPacketRecords = try XCTUnwrap(mapMemberPacket["includedRecords"] as? [[String: Any]])
        XCTAssertEqual(mapMemberPacketRecords.count, 5)
        XCTAssertTrue(mapMemberPacketRecords.contains { $0["recordID"] as? String == "maps:res/field/matrices/route201.json" })
        XCTAssertTrue(mapMemberPacketRecords.contains { $0["recordID"] as? String == "maps:res/field/events/route201.json" })
        XCTAssertTrue(mapMemberPacketRecords.contains { $0["recordID"] as? String == "scripts:res/field/scripts/route201.s" })
        XCTAssertTrue(mapMemberPacketRecords.contains { $0["recordID"] as? String == "text:res/text/route201.txt" })
        let mapMemberPacketRows = try XCTUnwrap(mapMemberPacket["rows"] as? [[String: Any]])
        XCTAssertTrue(mapMemberPacketRows.contains { $0["id"] as? String == "blocked-actions" && ($0["detail"] as? String)?.contains("mutation apply") == true })
        XCTAssertEqual(factValue("Gen IV Map Review Packet", in: mapMemberFacts), "reviewOnly")
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: mapMemberFacts), "map")
        XCTAssertEqual(factValue("Gen IV Map Review Related Rows", in: mapMemberFacts), "4")

        let resourceIndex = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resource-index", root.path, "--json"])
        )
        let items = try XCTUnwrap(resourceIndex["items"] as? [[String: Any]])
        let mapRootResource = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data maps" && $0["path"] as? String == "res/field/maps" })
        let mapRootResourceFacts = try XCTUnwrap(mapRootResource["facts"] as? [[String: Any]])
        XCTAssertTrue(mapRootResourceFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "platinumMapInventory" })
        XCTAssertTrue(mapRootResourceFacts.contains { $0["label"] as? String == "Gen IV Action State" && ($0["value"] as? String)?.contains("binary write path is enabled") == true })
        XCTAssertFalse(mapRootResourceFacts.contains { $0["label"] as? String == "Migration Status" })

        let mapMemberResource = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data maps" && $0["path"] as? String == "res/field/maps/route201/map.bin" })
        let mapMemberResourceFacts = try XCTUnwrap(mapMemberResource["facts"] as? [[String: Any]])
        XCTAssertTrue(mapMemberResourceFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "platinumMapMember" })
        XCTAssertTrue(mapMemberResourceFacts.contains { $0["label"] as? String == "Related Rows" && $0["value"] as? String == "4" })
        XCTAssertEqual(factValue("Gen IV Map Review Packet", in: mapMemberResourceFacts), "reviewOnly")
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: mapMemberResourceFacts), "map")
        XCTAssertEqual(factValue("Gen IV Map Review Related Rows", in: mapMemberResourceFacts), "4")
    }

    func testNDSDataCatalogCommandEmitsHeartGoldSoulSilverMapInventoryJSON() throws {
        let root = try makeTestHeartGoldDecompRoot()

        let catalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", root.path, "--json"])
        )

        XCTAssertEqual(catalog["profile"] as? String, "pokeheartgold")
        XCTAssertEqual(catalog["family"] as? String, "heartGoldSoulSilver")
        let records = try XCTUnwrap(catalog["records"] as? [[String: Any]])
        let matrixRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/mapmatrix" })
        XCTAssertEqual(matrixRoot["domain"] as? String, "maps")
        XCTAssertEqual(matrixRoot["format"] as? String, "directory")
        XCTAssertEqual(matrixRoot["recordCount"] as? Int, 1)
        let matrixRootFacts = try XCTUnwrap(matrixRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(matrixRootFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "hgssMapMatrixInventory" })
        XCTAssertTrue(matrixRootFacts.contains { $0["label"] as? String == "Gen IV Source Provenance" && $0["value"] as? String == "heartGoldSoulSilver:files/fielddata/mapmatrix" })
        XCTAssertTrue(matrixRootFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("semantic editing") == true })
        XCTAssertTrue(matrixRootFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("ROM export") == true })
        XCTAssertTrue(matrixRootFacts.contains { $0["label"] as? String == "Gen IV Action State" && ($0["value"] as? String)?.contains("inventory-only HGSS map metadata") == true })
        XCTAssertFalse(matrixRootFacts.contains { $0["label"] as? String == "Migration Status" })
        let matrixRootDiagnostics = try XCTUnwrap(matrixRoot["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(matrixRootDiagnostics.contains { $0["code"] as? String == "NDS_DATA_HGSS_MAP_INVENTORY_PREVIEW_ONLY" })
        XCTAssertTrue(matrixRootDiagnostics.contains { $0["code"] as? String == "NDS_DATA_HGSS_MAP_WRITE_BLOCKED" })
        XCTAssertTrue(matrixRootFacts.contains { $0["label"] as? String == "Related Rows" && $0["value"] as? String == "2" })
        XCTAssertTrue(matrixRootFacts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == "maps" })
        let matrixRootReadiness = try XCTUnwrap(matrixRoot["readiness"] as? [String: Any])
        XCTAssertEqual(matrixRootReadiness["status"] as? String, "ready")
        let matrixRootRelatedRecords = try XCTUnwrap(matrixRoot["relatedRecords"] as? [[String: Any]])
        XCTAssertTrue(matrixRootRelatedRecords.contains { $0["recordID"] as? String == "maps:files/fielddata/maptable" && $0["label"] as? String == "Map header" })
        XCTAssertTrue(matrixRootRelatedRecords.contains { $0["recordID"] as? String == "maps:src/data/map_headers.h" && $0["label"] as? String == "Map header" })
        let matrixRootPacket = try XCTUnwrap(matrixRoot["mapReviewPacket"] as? [String: Any])
        XCTAssertEqual(matrixRootPacket["posture"] as? String, "reviewOnly")
        XCTAssertEqual(matrixRootPacket["component"] as? String, "matrix")
        XCTAssertEqual(matrixRootPacket["sourceRole"] as? String, "hgssMapMatrixInventory")
        XCTAssertEqual(matrixRootPacket["sourceProvenance"] as? String, "heartGoldSoulSilver:files/fielddata/mapmatrix")
        XCTAssertEqual(matrixRootPacket["truncatedRelatedRecordCount"] as? Int, 0)
        let matrixRootPacketRecords = try XCTUnwrap(matrixRootPacket["includedRecords"] as? [[String: Any]])
        XCTAssertEqual(matrixRootPacketRecords.count, 3)
        XCTAssertTrue(matrixRootPacketRecords.contains { $0["recordID"] as? String == "maps:files/fielddata/maptable" })
        XCTAssertTrue(matrixRootPacketRecords.contains { $0["recordID"] as? String == "maps:src/data/map_headers.h" })
        let matrixRootPacketRows = try XCTUnwrap(matrixRootPacket["rows"] as? [[String: Any]])
        XCTAssertTrue(matrixRootPacketRows.contains { $0["id"] as? String == "blocked-actions" && ($0["detail"] as? String)?.contains("ROM export") == true })
        XCTAssertEqual(factValue("Gen IV Map Review Packet", in: matrixRootFacts), "reviewOnly")
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: matrixRootFacts), "matrix")
        XCTAssertEqual(factValue("Gen IV Map Review Related Rows", in: matrixRootFacts), "2")

        let matrixMember = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/mapmatrix/0001.bin" })
        let matrixMemberFacts = try XCTUnwrap(matrixMember["facts"] as? [[String: Any]])
        XCTAssertTrue(matrixMemberFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "hgssMapMatrixMember" })
        XCTAssertTrue(matrixMemberFacts.contains { $0["label"] as? String == "Gen IV Source Provenance" && $0["value"] as? String == "heartGoldSoulSilver:files/fielddata/mapmatrix" })

        let tableRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/maptable" })
        let tableRootFacts = try XCTUnwrap(tableRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(tableRootFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "hgssMapTableInventory" })
        XCTAssertTrue(tableRootFacts.contains { $0["label"] as? String == "Gen IV Source Provenance" && $0["value"] as? String == "heartGoldSoulSilver:files/fielddata/maptable" })
        XCTAssertTrue(tableRootFacts.contains { $0["label"] as? String == "Related Rows" })
        XCTAssertTrue(tableRootFacts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == "maps" })
        let tableRootReadiness = try XCTUnwrap(tableRoot["readiness"] as? [String: Any])
        XCTAssertEqual(tableRootReadiness["status"] as? String, "ready")
        let tableRootRelatedRecords = try XCTUnwrap(tableRoot["relatedRecords"] as? [[String: Any]])
        XCTAssertTrue(tableRootRelatedRecords.contains { $0["recordID"] as? String == "maps:files/fielddata/mapmatrix" && $0["label"] as? String == "Matrix" })
        XCTAssertTrue(tableRootRelatedRecords.contains { $0["recordID"] as? String == "maps:src/data/map_headers.h" && $0["label"] as? String == "Map header" })
        XCTAssertFalse(tableRootFacts.contains { $0["label"] as? String == "Migration Status" })
        let tableRootPacket = try XCTUnwrap(tableRoot["mapReviewPacket"] as? [String: Any])
        XCTAssertEqual(tableRootPacket["component"] as? String, "table")
        XCTAssertEqual(tableRootPacket["sourceRole"] as? String, "hgssMapTableInventory")
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: tableRootFacts), "table")

        let tableMember = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/maptable/map.bin" })
        let tableMemberFacts = try XCTUnwrap(tableMember["facts"] as? [[String: Any]])
        XCTAssertTrue(tableMemberFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "hgssMapTableMember" })

        let mapHeader = try XCTUnwrap(records.first { $0["relativePath"] as? String == "src/data/map_headers.h" })
        let mapHeaderFacts = try XCTUnwrap(mapHeader["facts"] as? [[String: Any]])
        XCTAssertTrue(mapHeaderFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "hgssMapHeaderInventory" })
        XCTAssertTrue(mapHeaderFacts.contains { $0["label"] as? String == "Gen IV Source Provenance" && $0["value"] as? String == "heartGoldSoulSilver:src/data/map_headers.h" })
        XCTAssertTrue(mapHeaderFacts.contains { $0["label"] as? String == "Related Rows" })
        XCTAssertTrue(mapHeaderFacts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == "maps" })
        let mapHeaderReadiness = try XCTUnwrap(mapHeader["readiness"] as? [String: Any])
        XCTAssertEqual(mapHeaderReadiness["status"] as? String, "ready")
        let mapHeaderRelatedRecords = try XCTUnwrap(mapHeader["relatedRecords"] as? [[String: Any]])
        XCTAssertTrue(mapHeaderRelatedRecords.contains { $0["recordID"] as? String == "maps:files/fielddata/mapmatrix" && $0["label"] as? String == "Matrix" })
        XCTAssertTrue(mapHeaderRelatedRecords.contains { $0["recordID"] as? String == "maps:files/fielddata/maptable" && $0["label"] as? String == "Map header" })
        XCTAssertTrue(mapHeaderFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("binary write") == true })
        let mapHeaderPacket = try XCTUnwrap(mapHeader["mapReviewPacket"] as? [String: Any])
        XCTAssertEqual(mapHeaderPacket["component"] as? String, "mapHeader")
        XCTAssertEqual(mapHeaderPacket["sourceRole"] as? String, "hgssMapHeaderInventory")
        let mapHeaderPacketBlockedActions = try XCTUnwrap(mapHeaderPacket["blockedActions"] as? [String])
        XCTAssertTrue(mapHeaderPacketBlockedActions.contains("binary write"))
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: mapHeaderFacts), "mapHeader")

        let resourceIndex = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resource-index", root.path, "--json"])
        )
        let items = try XCTUnwrap(resourceIndex["items"] as? [[String: Any]])
        let matrixRootResource = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data maps" && $0["path"] as? String == "files/fielddata/mapmatrix" })
        let matrixRootResourceFacts = try XCTUnwrap(matrixRootResource["facts"] as? [[String: Any]])
        XCTAssertTrue(matrixRootResourceFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "hgssMapMatrixInventory" })
        XCTAssertTrue(matrixRootResourceFacts.contains { $0["label"] as? String == "Gen IV Action State" && ($0["value"] as? String)?.contains("container rebuild") == true })
        XCTAssertTrue(matrixRootResourceFacts.contains { $0["label"] as? String == "Related Rows" && $0["value"] as? String == "2" })
        XCTAssertTrue(matrixRootResourceFacts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == "maps" })
        XCTAssertFalse(matrixRootResourceFacts.contains { $0["label"] as? String == "Migration Status" })
        XCTAssertEqual(factValue("Gen IV Map Review Packet", in: matrixRootResourceFacts), "reviewOnly")
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: matrixRootResourceFacts), "matrix")
        XCTAssertEqual(factValue("Gen IV Map Review Related Rows", in: matrixRootResourceFacts), "2")

        let tableRootResource = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data maps" && $0["path"] as? String == "files/fielddata/maptable" })
        let tableRootResourceFacts = try XCTUnwrap(tableRootResource["facts"] as? [[String: Any]])
        XCTAssertTrue(tableRootResourceFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "hgssMapTableInventory" })
        XCTAssertTrue(tableRootResourceFacts.contains { $0["label"] as? String == "Related Rows" })
        XCTAssertTrue(tableRootResourceFacts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == "maps" })
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: tableRootResourceFacts), "table")
        let mapHeaderResource = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data maps" && $0["path"] as? String == "src/data/map_headers.h" })
        let mapHeaderResourceFacts = try XCTUnwrap(mapHeaderResource["facts"] as? [[String: Any]])
        XCTAssertTrue(mapHeaderResourceFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "hgssMapHeaderInventory" })
        XCTAssertTrue(mapHeaderResourceFacts.contains { $0["label"] as? String == "Related Rows" })
        XCTAssertTrue(mapHeaderResourceFacts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == "maps" })
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: mapHeaderResourceFacts), "mapHeader")
    }

    func testNDSDataCatalogCommandEmitsDiamondPearlMapInventoryJSON() throws {
        let root = try makeTestDiamondDecompRoot()

        let catalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", root.path, "--json"])
        )

        XCTAssertEqual(catalog["profile"] as? String, "pokediamond")
        XCTAssertEqual(catalog["family"] as? String, "diamondPearl")
        let records = try XCTUnwrap(catalog["records"] as? [[String: Any]])
        let mapHeader = try XCTUnwrap(records.first { $0["relativePath"] as? String == "arm9/src/map_header.c" })
        let mapHeaderFacts = try XCTUnwrap(mapHeader["facts"] as? [[String: Any]])
        XCTAssertTrue(mapHeaderFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "dpMapHeaderCAnchor" })
        XCTAssertTrue(mapHeaderFacts.contains { $0["label"] as? String == "Gen IV Source Provenance" && $0["value"] as? String == "diamondPearl:arm9/src/map_header.c" })
        XCTAssertTrue(mapHeaderFacts.contains { $0["label"] as? String == "Gen IV Readiness" && $0["value"] as? String == "semanticIntegerScalars" })
        XCTAssertFalse(mapHeaderFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("raw C-anchor write") == true })
        XCTAssertTrue(mapHeaderFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("non-integer C scalar write") == true })
        XCTAssertTrue(mapHeaderFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("ROM export") == true })
        XCTAssertTrue(mapHeaderFacts.contains { $0["label"] as? String == "Gen IV Action State" && ($0["value"] as? String)?.contains("semantic mutation-plan gate") == true })
        let mapHeaderDiagnostics = try XCTUnwrap(mapHeader["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(mapHeaderDiagnostics.contains { $0["code"] as? String == "NDS_DATA_DP_MAP_HEADER_SEMANTIC_SCALARS" })
        XCTAssertTrue(mapHeaderDiagnostics.contains { $0["code"] as? String == "NDS_DATA_DP_MAP_HEADER_WRITE_LIMITED" })
        let mapHeaderPacket = try XCTUnwrap(mapHeader["mapReviewPacket"] as? [String: Any])
        XCTAssertEqual(mapHeaderPacket["posture"] as? String, "reviewOnly")
        XCTAssertEqual(mapHeaderPacket["component"] as? String, "mapHeader")
        XCTAssertEqual(mapHeaderPacket["sourceRole"] as? String, "dpMapHeaderCAnchor")
        XCTAssertEqual(mapHeaderPacket["sourceProvenance"] as? String, "diamondPearl:arm9/src/map_header.c")
        let mapHeaderPacketBlockedActions = try XCTUnwrap(mapHeaderPacket["blockedActions"] as? [String])
        XCTAssertTrue(mapHeaderPacketBlockedActions.contains("non-integer C scalar write"))
        XCTAssertFalse(mapHeaderPacketBlockedActions.contains("raw C-anchor write"))
        XCTAssertEqual(factValue("Gen IV Map Review Packet", in: mapHeaderFacts), "reviewOnly")
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: mapHeaderFacts), "mapHeader")

        let scriptCAnchor = try XCTUnwrap(records.first { $0["relativePath"] as? String == "arm9/src/script.c" })
        XCTAssertEqual(scriptCAnchor["domain"] as? String, "scripts")
        XCTAssertEqual(scriptCAnchor["format"] as? String, "cSource")
        let scriptCAnchorFacts = try XCTUnwrap(scriptCAnchor["facts"] as? [[String: Any]])
        XCTAssertTrue(scriptCAnchorFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "dpScriptCAnchorLoaderOnly" })
        XCTAssertTrue(scriptCAnchorFacts.contains { $0["label"] as? String == "Gen IV Source Provenance" && $0["value"] as? String == "diamondPearl:arm9/src/script.c" })
        XCTAssertTrue(scriptCAnchorFacts.contains { $0["label"] as? String == "Gen IV Readiness" && $0["value"] as? String == "loaderOnlyBlocked" })
        XCTAssertTrue(scriptCAnchorFacts.contains { $0["label"] as? String == "Gen IV C Anchor Shape" && $0["value"] as? String == "loaderTaskFlow" })
        XCTAssertTrue(scriptCAnchorFacts.contains { $0["label"] as? String == "Readiness" && $0["value"] as? String == "blocked" })
        XCTAssertTrue(scriptCAnchorFacts.contains { $0["label"] as? String == "Related Rows" && $0["value"] as? String == "2" })
        XCTAssertTrue(scriptCAnchorFacts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == "maps, text" })
        XCTAssertFalse(scriptCAnchorFacts.contains { $0["label"] as? String == "Gen IV Future Row" })
        XCTAssertTrue(scriptCAnchorFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("script parser") == true })
        XCTAssertTrue(scriptCAnchorFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("script C-anchor writer") == true })
        XCTAssertTrue(scriptCAnchorFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("mutation apply") == true })
        XCTAssertTrue(scriptCAnchorFacts.contains { $0["label"] as? String == "Gen IV Action State" && ($0["value"] as? String)?.contains("loader/task source") == true })
        let scriptCAnchorReadiness = try XCTUnwrap(scriptCAnchor["readiness"] as? [String: Any])
        XCTAssertEqual(scriptCAnchorReadiness["status"] as? String, "blocked")
        XCTAssertEqual(scriptCAnchorReadiness["title"] as? String, "Diamond/Pearl script C-anchor loader-only readiness")
        let scriptCAnchorBlockedActions = try XCTUnwrap(scriptCAnchorReadiness["blockedActions"] as? [String])
        XCTAssertTrue(scriptCAnchorBlockedActions.contains("script parser"))
        XCTAssertTrue(scriptCAnchorBlockedActions.contains("script C-anchor writer"))
        XCTAssertTrue(scriptCAnchorBlockedActions.contains("script compiler"))
        XCTAssertTrue(scriptCAnchorBlockedActions.contains("mutation apply"))
        let scriptCAnchorDiagnostics = try XCTUnwrap(scriptCAnchor["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(scriptCAnchorDiagnostics.contains { $0["code"] as? String == "NDS_DATA_DP_SCRIPT_C_ANCHOR_LOADER_ONLY" })

        let moveCAnchor = try XCTUnwrap(records.first { $0["relativePath"] as? String == "arm9/src/waza.c" })
        XCTAssertEqual(moveCAnchor["domain"] as? String, "moves")
        XCTAssertEqual(moveCAnchor["format"] as? String, "cSource")
        let moveCAnchorFacts = try XCTUnwrap(moveCAnchor["facts"] as? [[String: Any]])
        XCTAssertTrue(moveCAnchorFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "dpMoveCAnchorSemanticScalars" })
        XCTAssertTrue(moveCAnchorFacts.contains { $0["label"] as? String == "Gen IV Source Provenance" && $0["value"] as? String == "diamondPearl:arm9/src/waza.c" })
        XCTAssertTrue(moveCAnchorFacts.contains { $0["label"] as? String == "Gen IV Readiness" && $0["value"] as? String == "semanticSimpleScalars" })
        XCTAssertFalse(moveCAnchorFacts.contains { $0["label"] as? String == "Gen IV Future Row" && $0["value"] as? String == "PHS-T98" })
        XCTAssertTrue(moveCAnchorFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("non-simple move C scalar write") == true })
        XCTAssertTrue(moveCAnchorFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("row insert/remove/reorder") == true })
        XCTAssertTrue(moveCAnchorFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("encounter C-anchor writer") == true })
        XCTAssertTrue(moveCAnchorFacts.contains { $0["label"] as? String == "Gen IV Action State" && ($0["value"] as? String)?.contains("semantic mutation-plan gate") == true })
        let moveCAnchorReadiness = try XCTUnwrap(moveCAnchor["readiness"] as? [String: Any])
        XCTAssertEqual(moveCAnchorReadiness["status"] as? String, "partial")
        let moveCAnchorBlockedActions = try XCTUnwrap(moveCAnchorReadiness["blockedActions"] as? [String])
        XCTAssertTrue(moveCAnchorBlockedActions.contains("non-simple move C scalar write"))
        let moveCAnchorDiagnostics = try XCTUnwrap(moveCAnchor["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(moveCAnchorDiagnostics.contains { $0["code"] as? String == "NDS_DATA_DP_MOVE_C_ANCHOR_SEMANTIC_SCALARS" })
        XCTAssertTrue(moveCAnchorDiagnostics.contains { $0["code"] as? String == "NDS_DATA_DP_MOVE_C_ANCHOR_WRITE_LIMITED" })

        let encounterCAnchor = try XCTUnwrap(records.first { $0["relativePath"] as? String == "arm9/src/encounter.c" })
        XCTAssertEqual(encounterCAnchor["domain"] as? String, "encounters")
        XCTAssertEqual(encounterCAnchor["format"] as? String, "cSource")
        let encounterCAnchorFacts = try XCTUnwrap(encounterCAnchor["facts"] as? [[String: Any]])
        XCTAssertTrue(encounterCAnchorFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "dpEncounterCAnchorLoaderOnly" })
        XCTAssertTrue(encounterCAnchorFacts.contains { $0["label"] as? String == "Gen IV Source Provenance" && $0["value"] as? String == "diamondPearl:arm9/src/encounter.c" })
        XCTAssertTrue(encounterCAnchorFacts.contains { $0["label"] as? String == "Gen IV Readiness" && $0["value"] as? String == "loaderOnlyBlocked" })
        XCTAssertTrue(encounterCAnchorFacts.contains { $0["label"] as? String == "Gen IV C Anchor Shape" && $0["value"] as? String == "loaderTaskFlow" })
        XCTAssertFalse(encounterCAnchorFacts.contains { $0["label"] as? String == "Gen IV Future Row" })
        XCTAssertTrue(encounterCAnchorFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("encounter C-anchor writer") == true })
        XCTAssertTrue(encounterCAnchorFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("raw scalar writer") == true })
        XCTAssertTrue(encounterCAnchorFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("row insert/remove/reorder") == true })
        XCTAssertTrue(encounterCAnchorFacts.contains { $0["label"] as? String == "Gen IV Action State" && ($0["value"] as? String)?.contains("loader/task source") == true })
        XCTAssertTrue(encounterCAnchorFacts.contains { $0["label"] as? String == "Gen IV Action State" && ($0["value"] as? String)?.contains("exact scalar table") == true })
        let encounterCAnchorReadiness = try XCTUnwrap(encounterCAnchor["readiness"] as? [String: Any])
        XCTAssertEqual(encounterCAnchorReadiness["status"] as? String, "blocked")
        let encounterCAnchorBlockedActions = try XCTUnwrap(encounterCAnchorReadiness["blockedActions"] as? [String])
        XCTAssertTrue(encounterCAnchorBlockedActions.contains("encounter C-anchor writer"))
        XCTAssertTrue(encounterCAnchorBlockedActions.contains("raw scalar writer"))
        let encounterCAnchorDiagnostics = try XCTUnwrap(encounterCAnchor["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(encounterCAnchorDiagnostics.contains { $0["code"] as? String == "NDS_DATA_DP_ENCOUNTER_C_ANCHOR_LOADER_ONLY" })

        let matrixRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/mapmatrix" })
        XCTAssertEqual(matrixRoot["format"] as? String, "directory")
        XCTAssertEqual(matrixRoot["recordCount"] as? Int, 1)
        let matrixRootFacts = try XCTUnwrap(matrixRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(matrixRootFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "dpMapMatrixInventory" })
        XCTAssertTrue(matrixRootFacts.contains { $0["label"] as? String == "Gen IV Source Provenance" && $0["value"] as? String == "diamondPearl:files/fielddata/mapmatrix" })
        XCTAssertFalse(matrixRootFacts.contains { $0["label"] as? String == "Migration Status" })
        let matrixRootPacket = try XCTUnwrap(matrixRoot["mapReviewPacket"] as? [String: Any])
        XCTAssertEqual(matrixRootPacket["component"] as? String, "matrix")
        XCTAssertEqual(matrixRootPacket["sourceRole"] as? String, "dpMapMatrixInventory")
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: matrixRootFacts), "matrix")

        let matrixMember = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/mapmatrix/matrix.bin" })
        let matrixMemberFacts = try XCTUnwrap(matrixMember["facts"] as? [[String: Any]])
        XCTAssertTrue(matrixMemberFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "dpMapMatrixMember" })

        let tableRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/maptable" })
        let tableRootFacts = try XCTUnwrap(tableRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(tableRootFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "dpMapTableInventory" })
        XCTAssertTrue(tableRootFacts.contains { $0["label"] as? String == "Gen IV Source Provenance" && $0["value"] as? String == "diamondPearl:files/fielddata/maptable" })
        XCTAssertFalse(tableRootFacts.contains { $0["label"] as? String == "Migration Status" })
        let tableRootPacket = try XCTUnwrap(tableRoot["mapReviewPacket"] as? [String: Any])
        XCTAssertEqual(tableRootPacket["component"] as? String, "table")
        XCTAssertEqual(tableRootPacket["sourceRole"] as? String, "dpMapTableInventory")
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: tableRootFacts), "table")
        let tableMember = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/maptable/map.bin" })
        let tableMemberFacts = try XCTUnwrap(tableMember["facts"] as? [[String: Any]])
        XCTAssertTrue(tableMemberFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "dpMapTableMember" })

        let landRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/land_data" })
        let landRootFacts = try XCTUnwrap(landRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(landRootFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "dpLandDataInventory" })
        XCTAssertTrue(landRootFacts.contains { $0["label"] as? String == "Gen IV Source Provenance" && $0["value"] as? String == "diamondPearl:files/fielddata/land_data" })
        let landRootPacket = try XCTUnwrap(landRoot["mapReviewPacket"] as? [String: Any])
        XCTAssertEqual(landRootPacket["component"] as? String, "land")
        XCTAssertEqual(landRootPacket["sourceRole"] as? String, "dpLandDataInventory")
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: landRootFacts), "land")

        let areaRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/areadata" })
        let areaRootFacts = try XCTUnwrap(areaRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(areaRootFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "dpAreaDataInventory" })
        XCTAssertTrue(areaRootFacts.contains { $0["label"] as? String == "Gen IV Source Provenance" && $0["value"] as? String == "diamondPearl:files/fielddata/areadata" })
        let areaRootPacket = try XCTUnwrap(areaRoot["mapReviewPacket"] as? [String: Any])
        XCTAssertEqual(areaRootPacket["component"] as? String, "area")
        XCTAssertEqual(areaRootPacket["sourceRole"] as? String, "dpAreaDataInventory")
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: areaRootFacts), "area")

        let resourceIndex = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resource-index", root.path, "--json"])
        )
        let items = try XCTUnwrap(resourceIndex["items"] as? [[String: Any]])
        let matrixRootResource = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data maps" && $0["path"] as? String == "files/fielddata/mapmatrix" })
        let matrixRootResourceFacts = try XCTUnwrap(matrixRootResource["facts"] as? [[String: Any]])
        XCTAssertTrue(matrixRootResourceFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "dpMapMatrixInventory" })
        XCTAssertTrue(matrixRootResourceFacts.contains { $0["label"] as? String == "Gen IV Action State" && ($0["value"] as? String)?.contains("raw C-anchor writer") == true })
        XCTAssertFalse(matrixRootResourceFacts.contains { $0["label"] as? String == "Migration Status" })
        XCTAssertEqual(factValue("Gen IV Map Review Packet", in: matrixRootResourceFacts), "reviewOnly")
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: matrixRootResourceFacts), "matrix")

        let tableRootResource = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data maps" && $0["path"] as? String == "files/fielddata/maptable" })
        let tableRootResourceFacts = try XCTUnwrap(tableRootResource["facts"] as? [[String: Any]])
        XCTAssertTrue(tableRootResourceFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "dpMapTableInventory" })
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: tableRootResourceFacts), "table")
        let landRootResource = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data maps" && $0["path"] as? String == "files/fielddata/land_data" })
        let landRootResourceFacts = try XCTUnwrap(landRootResource["facts"] as? [[String: Any]])
        XCTAssertTrue(landRootResourceFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "dpLandDataInventory" })
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: landRootResourceFacts), "land")
        let areaRootResource = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data maps" && $0["path"] as? String == "files/fielddata/areadata" })
        let areaRootResourceFacts = try XCTUnwrap(areaRootResource["facts"] as? [[String: Any]])
        XCTAssertTrue(areaRootResourceFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "dpAreaDataInventory" })
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: areaRootResourceFacts), "area")
        let mapHeaderResource = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data maps" && $0["path"] as? String == "arm9/src/map_header.c" })
        let mapHeaderResourceFacts = try XCTUnwrap(mapHeaderResource["facts"] as? [[String: Any]])
        XCTAssertTrue(mapHeaderResourceFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "dpMapHeaderCAnchor" })
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: mapHeaderResourceFacts), "mapHeader")
        let moveCAnchorResource = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data moves" && $0["path"] as? String == "arm9/src/waza.c" })
        let moveCAnchorResourceFacts = try XCTUnwrap(moveCAnchorResource["facts"] as? [[String: Any]])
        XCTAssertTrue(moveCAnchorResourceFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "dpMoveCAnchorSemanticScalars" })
        XCTAssertFalse(moveCAnchorResourceFacts.contains { $0["label"] as? String == "Gen IV Future Row" && $0["value"] as? String == "PHS-T98" })
        XCTAssertTrue(moveCAnchorResourceFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("non-simple move C scalar write") == true })
        let scriptCAnchorResource = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data scripts" && $0["path"] as? String == "arm9/src/script.c" })
        let scriptCAnchorResourceFacts = try XCTUnwrap(scriptCAnchorResource["facts"] as? [[String: Any]])
        XCTAssertTrue(scriptCAnchorResourceFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "dpScriptCAnchorLoaderOnly" })
        XCTAssertTrue(scriptCAnchorResourceFacts.contains { $0["label"] as? String == "Gen IV Readiness" && $0["value"] as? String == "loaderOnlyBlocked" })
        XCTAssertTrue(scriptCAnchorResourceFacts.contains { $0["label"] as? String == "Gen IV C Anchor Shape" && $0["value"] as? String == "loaderTaskFlow" })
        XCTAssertTrue(scriptCAnchorResourceFacts.contains { $0["label"] as? String == "Readiness" && $0["value"] as? String == "blocked" })
        XCTAssertTrue(scriptCAnchorResourceFacts.contains { $0["label"] as? String == "Related Rows" && $0["value"] as? String == "2" })
        XCTAssertTrue(scriptCAnchorResourceFacts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == "maps, text" })
        XCTAssertFalse(scriptCAnchorResourceFacts.contains { $0["label"] as? String == "Gen IV Future Row" })
        XCTAssertTrue(scriptCAnchorResourceFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("script parser") == true })
        XCTAssertTrue(scriptCAnchorResourceFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("mutation apply") == true })
        let encounterCAnchorResource = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data encounters" && $0["path"] as? String == "arm9/src/encounter.c" })
        let encounterCAnchorResourceFacts = try XCTUnwrap(encounterCAnchorResource["facts"] as? [[String: Any]])
        XCTAssertTrue(encounterCAnchorResourceFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "dpEncounterCAnchorLoaderOnly" })
        XCTAssertTrue(encounterCAnchorResourceFacts.contains { $0["label"] as? String == "Gen IV Readiness" && $0["value"] as? String == "loaderOnlyBlocked" })
        XCTAssertTrue(encounterCAnchorResourceFacts.contains { $0["label"] as? String == "Gen IV C Anchor Shape" && $0["value"] as? String == "loaderTaskFlow" })
        XCTAssertFalse(encounterCAnchorResourceFacts.contains { $0["label"] as? String == "Gen IV Future Row" })
        XCTAssertTrue(encounterCAnchorResourceFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("encounter C-anchor writer") == true })
    }

    func testNDSDataCatalogCommandEmitsHeartGoldSoulSilverScriptSequenceInventoryJSON() throws {
        let root = try makeTestHeartGoldDecompRoot()

        let catalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", root.path, "--json"])
        )

        XCTAssertEqual(catalog["profile"] as? String, "pokeheartgold")
        XCTAssertEqual(catalog["family"] as? String, "heartGoldSoulSilver")
        let records = try XCTUnwrap(catalog["records"] as? [[String: Any]])
        let scriptRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/script/scr_seq" })
        XCTAssertEqual(scriptRoot["domain"] as? String, "scripts")
        XCTAssertEqual(scriptRoot["format"] as? String, "directory")
        XCTAssertEqual(scriptRoot["recordCount"] as? Int, 1)
        let scriptRootFacts = try XCTUnwrap(scriptRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(scriptRootFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "hgssScriptSequenceInventory" })
        XCTAssertTrue(scriptRootFacts.contains { $0["label"] as? String == "Gen IV Source Provenance" && $0["value"] as? String == "heartGoldSoulSilver:files/fielddata/script/scr_seq" })
        XCTAssertTrue(scriptRootFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("script parsing") == true })
        XCTAssertTrue(scriptRootFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("script binary write") == true })
        XCTAssertTrue(scriptRootFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("ROM export") == true })
        XCTAssertTrue(scriptRootFacts.contains { $0["label"] as? String == "Gen IV Action State" && ($0["value"] as? String)?.contains("inventory-only HGSS script-sequence metadata") == true })
        XCTAssertFalse(scriptRootFacts.contains { $0["label"] as? String == "Migration Status" })
        let scriptRootReadiness = try XCTUnwrap(scriptRoot["readiness"] as? [String: Any])
        XCTAssertEqual(scriptRootReadiness["status"] as? String, "partial")
        let scriptRootBlockedActions = try XCTUnwrap(scriptRootReadiness["blockedActions"] as? [String])
        XCTAssertTrue(scriptRootBlockedActions.contains("script compiler"))
        let scriptRootDiagnostics = try XCTUnwrap(scriptRoot["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(scriptRootDiagnostics.contains { $0["code"] as? String == "NDS_DATA_HGSS_SCRIPT_SEQUENCE_INVENTORY_PREVIEW_ONLY" })
        XCTAssertTrue(scriptRootDiagnostics.contains { $0["code"] as? String == "NDS_DATA_HGSS_SCRIPT_SEQUENCE_WRITE_BLOCKED" })

        let scriptMember = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/script/scr_seq/0001.bin" })
        let scriptMemberFacts = try XCTUnwrap(scriptMember["facts"] as? [[String: Any]])
        XCTAssertTrue(scriptMemberFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "hgssScriptSequenceMember" })
        XCTAssertTrue(scriptMemberFacts.contains { $0["label"] as? String == "Gen IV Source Provenance" && $0["value"] as? String == "heartGoldSoulSilver:files/fielddata/script/scr_seq" })
        XCTAssertTrue(scriptMemberFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("container rebuild") == true })

        let resourceIndex = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resource-index", root.path, "--json"])
        )
        let items = try XCTUnwrap(resourceIndex["items"] as? [[String: Any]])
        let scriptRootResource = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data scripts" && $0["path"] as? String == "files/fielddata/script/scr_seq" })
        let scriptRootResourceFacts = try XCTUnwrap(scriptRootResource["facts"] as? [[String: Any]])
        XCTAssertTrue(scriptRootResourceFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "hgssScriptSequenceInventory" })
        XCTAssertTrue(scriptRootResourceFacts.contains { $0["label"] as? String == "Gen IV Action State" && ($0["value"] as? String)?.contains("mutation apply path is enabled") == true })
        XCTAssertFalse(scriptRootResourceFacts.contains { $0["label"] as? String == "Migration Status" })

        let scriptMemberResource = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data scripts" && $0["path"] as? String == "files/fielddata/script/scr_seq/0001.bin" })
        let scriptMemberResourceFacts = try XCTUnwrap(scriptMemberResource["facts"] as? [[String: Any]])
        XCTAssertTrue(scriptMemberResourceFacts.contains { $0["label"] as? String == "Gen IV Source Role" && $0["value"] as? String == "hgssScriptSequenceMember" })
        XCTAssertTrue(scriptMemberResourceFacts.contains { $0["label"] as? String == "Gen IV Blocked Actions" && ($0["value"] as? String)?.contains("script binary write") == true })
    }

    func testNDSDataCatalogCommandEmitsPokeBlackReadinessJSON() throws {
        let root = try makeTestBlackDecompRoot()

        let catalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", root.path, "--json"])
        )

        XCTAssertEqual(catalog["profile"] as? String, "pokeblack")
        XCTAssertEqual(catalog["family"] as? String, "blackWhite")
        XCTAssertEqual(catalog["isReadOnly"] as? Bool, true)
        let records = try XCTUnwrap(catalog["records"] as? [[String: Any]])
        let makefile = try XCTUnwrap(records.first { $0["relativePath"] as? String == "Makefile" })
        let makefileFacts = try XCTUnwrap(makefile["facts"] as? [[String: Any]])
        XCTAssertTrue(makefileFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "buildConfig" })
        XCTAssertTrue(makefileFacts.contains { $0["label"] as? String == "Gen V Build Metadata" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(makefileFacts.contains { $0["label"] as? String == "Gen V Makefile Presence" && $0["value"] as? String == "present" })
        XCTAssertTrue(makefileFacts.contains { $0["label"] as? String == "Gen V Config Presence" && $0["value"] as? String == "present" })
        XCTAssertTrue(makefileFacts.contains { $0["label"] as? String == "Gen V Linker Presence" && $0["value"] as? String == "arm9.ld=present, arm7.ld=present" })
        XCTAssertTrue(makefileFacts.contains { $0["label"] as? String == "Gen V Variant Hash Presence" && $0["value"] as? String == "black.us/rom.sha1=present, white.us/rom.sha1=missing, black2.us/rom.sha1=missing, white2.us/rom.sha1=missing" })
        XCTAssertTrue(makefileFacts.contains { $0["label"] as? String == "Gen V main.rsf Presence" && $0["value"] as? String == "present" })
        XCTAssertTrue(makefileFacts.contains { $0["label"] as? String == "Gen V main.lsf Presence" && $0["value"] as? String == "present" })
        XCTAssertTrue(makefileFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("source inventory stays preview-only") == true })
        let makefileReadiness = try XCTUnwrap(makefile["readiness"] as? [String: Any])
        XCTAssertEqual(makefileReadiness["status"] as? String, "partial")
        XCTAssertTrue((makefileReadiness["detail"] as? String)?.contains("manual setup") == true)

        let sourceRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "src" })
        XCTAssertEqual(sourceRoot["format"] as? String, "directory")
        XCTAssertEqual(sourceRoot["recordCount"] as? Int, 5)
        XCTAssertEqual(sourceRoot["byteCount"] as? Int, 92)
        XCTAssertTrue((sourceRoot["preview"] as? String)?.contains("src/init.c") == true)
        let sourceRootFacts = try XCTUnwrap(sourceRoot["facts"] as? [[String: Any]])
        XCTAssertEqual(factValue("Gen V Source Role", in: sourceRootFacts), "sourceCodeInventory")
        XCTAssertEqual(factValue("Gen V Source Root Members", in: sourceRootFacts), "5")
        XCTAssertEqual(factValue("Gen V Source Root Bytes", in: sourceRootFacts), "92")
        XCTAssertTrue(factValue("Gen V Source Root Sample Paths", in: sourceRootFacts)?.contains("src/data/pokemon/source_pokemon.inc") == true)
        XCTAssertTrue(factValue("Gen V Blocked Actions", in: sourceRootFacts)?.contains("raw source writer") == true)
        XCTAssertTrue(factValue("Gen V Action State", in: sourceRootFacts)?.contains("source inventory stays preview-only") == true)
        XCTAssertFalse(sourceRootFacts.contains { $0["label"] as? String == "Migration Status" })
        XCTAssertNil(sourceRoot["migrationPlan"])
        XCTAssertNil(sourceRoot["textBankPreview"])

        let assemblyRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "asm" })
        XCTAssertEqual(assemblyRoot["recordCount"] as? Int, 1)
        XCTAssertEqual(assemblyRoot["byteCount"] as? Int, 5)
        let assemblyFacts = try XCTUnwrap(assemblyRoot["facts"] as? [[String: Any]])
        XCTAssertEqual(factValue("Gen V Source Role", in: assemblyFacts), "assemblyInventory")
        XCTAssertEqual(factValue("Gen V Assembly Root Members", in: assemblyFacts), "1")
        XCTAssertEqual(factValue("Gen V Assembly Root Bytes", in: assemblyFacts), "5")
        XCTAssertEqual(factValue("Gen V Assembly Root Sample Paths", in: assemblyFacts), "asm/arm9_remaining.s")
        XCTAssertTrue(factValue("Gen V Blocked Actions", in: assemblyFacts)?.contains("mutation apply") == true)
        XCTAssertFalse(assemblyFacts.contains { $0["label"] as? String == "Migration Status" })
        XCTAssertNil(assemblyRoot["migrationPlan"])
        XCTAssertNil(assemblyRoot["textBankPreview"])

        let headerRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "include" })
        XCTAssertEqual(headerRoot["recordCount"] as? Int, 1)
        XCTAssertEqual(headerRoot["byteCount"] as? Int, 16)
        let headerFacts = try XCTUnwrap(headerRoot["facts"] as? [[String: Any]])
        XCTAssertEqual(factValue("Gen V Source Role", in: headerFacts), "headerInventory")
        XCTAssertEqual(factValue("Gen V Header Root Members", in: headerFacts), "1")
        XCTAssertEqual(factValue("Gen V Header Root Bytes", in: headerFacts), "16")
        XCTAssertEqual(factValue("Gen V Header Root Sample Paths", in: headerFacts), "include/globals.h")
        XCTAssertFalse(headerFacts.contains { $0["label"] as? String == "Migration Status" })
        XCTAssertNil(headerRoot["migrationPlan"])
        XCTAssertNil(headerRoot["textBankPreview"])

        let linkerConfig = try XCTUnwrap(records.first { $0["relativePath"] as? String == "arm9.ld" })
        let linkerFacts = try XCTUnwrap(linkerConfig["facts"] as? [[String: Any]])
        XCTAssertTrue(linkerFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "linkerConfig" })

        let blackMarker = try XCTUnwrap(records.first { $0["relativePath"] as? String == "black.us" })
        XCTAssertEqual(blackMarker["format"] as? String, "directory")
        XCTAssertEqual(blackMarker["recordCount"] as? Int, 1)
        let blackMarkerFacts = try XCTUnwrap(blackMarker["facts"] as? [[String: Any]])
        XCTAssertTrue(blackMarkerFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "variantSourceInventory" })
        XCTAssertTrue(blackMarkerFacts.contains { $0["label"] as? String == "Gen V Variant ID" && $0["value"] as? String == "black.us" })
        XCTAssertFalse(blackMarkerFacts.contains { $0["label"] as? String == "Migration Status" })

        let encounter = try XCTUnwrap(records.first { $0["relativePath"] as? String == "data/encounters/route_1.txt" })
        let encounterFacts = try XCTUnwrap(encounter["facts"] as? [[String: Any]])
        XCTAssertTrue(encounterFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(encounterFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "encounterPreview" })
        XCTAssertTrue(encounterFacts.contains { $0["label"] as? String == "Gen V Encounter Record" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(encounterFacts.contains { $0["label"] as? String == "Gen V Encounter Source" && $0["value"] as? String == "data/encounters" })
        XCTAssertTrue(encounterFacts.contains { $0["label"] as? String == "Gen V Encounter Key" && $0["value"] as? String == "route_1" })
        XCTAssertTrue(encounterFacts.contains { $0["label"] as? String == "Gen V Encounter Format" && $0["value"] as? String == "text" })
        XCTAssertTrue(encounterFacts.contains { $0["label"] as? String == "Gen V Encounter Parse State" && $0["value"] as? String == "metadataOnly" })
        XCTAssertTrue(encounterFacts.contains { $0["label"] as? String == "Gen V Encounter Shallow Count" && $0["value"] as? String == "1" })
        XCTAssertTrue(encounterFacts.contains { $0["label"] as? String == "Gen V Encounter Bytes" && $0["value"] as? String == "8" })
        XCTAssertTrue(encounterFacts.contains { $0["label"] as? String == "Gen V Blocked Actions" && ($0["value"] as? String)?.contains("raw source writer") == true })
        XCTAssertTrue(encounterFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("build, playtest, and export actions are disabled") == true })
        let encounterReadiness = try XCTUnwrap(encounter["readiness"] as? [String: Any])
        XCTAssertEqual(encounterReadiness["status"] as? String, "partial")
        XCTAssertTrue((encounterReadiness["detail"] as? String)?.contains("source inventory stays preview-only") == true)
        let encounterDiagnostics = try XCTUnwrap(encounter["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(encounterDiagnostics.contains { $0["code"] as? String == "NDS_GEN_V_READINESS_PREVIEW_ONLY" })
        XCTAssertTrue(encounterDiagnostics.contains { $0["code"] as? String == "NDS_GEN_V_WRITE_BLOCKED" })

        let overlay = try XCTUnwrap(records.first { $0["relativePath"] as? String == "overlays/overlay_93/source.s" })
        let overlayFacts = try XCTUnwrap(overlay["facts"] as? [[String: Any]])
        XCTAssertTrue(overlayFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "overlayRouting" })

        let config = try XCTUnwrap(records.first { $0["relativePath"] as? String == "ndsdisasm_config/ARM9.cfg" })
        let configFacts = try XCTUnwrap(config["facts"] as? [[String: Any]])
        XCTAssertTrue(configFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "disassemblyConfig" })

        let checksum = try XCTUnwrap(records.first { $0["relativePath"] as? String == "black.us/rom.sha1" })
        let checksumFacts = try XCTUnwrap(checksum["facts"] as? [[String: Any]])
        XCTAssertTrue(checksumFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "checksumExpectation" })
        XCTAssertTrue(checksumFacts.contains { $0["label"] as? String == "Gen V SHA1 Text State" && $0["value"] as? String == "valid" })
        XCTAssertTrue(checksumFacts.contains { $0["label"] as? String == "Gen V SHA1 Text Digest" && $0["value"] as? String == "ffffffffffffffffffffffffffffffffffffffff" })

        let audio = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/wb_sound_data.sdat" && $0["domain"] as? String == "audio" })
        let audioFacts = try XCTUnwrap(audio["facts"] as? [[String: Any]])
        XCTAssertTrue(audioFacts.contains { $0["label"] as? String == "Audio Preview" && $0["value"] as? String == "ready" })
        XCTAssertTrue(audioFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "soundArchiveMetadata" })

        let unavailableRows = records.filter { $0["role"] as? String == "metadataUnavailable" }
        XCTAssertEqual(unavailableRows.count, 3)
        let whitePath = "unavailable-titles/Pokemon - White Version (USA, Europe) (NDSi Enhanced).nds"
        let whiteReason = "No materialized White source decomp is available in the current central corpus; the available pokeblack tree currently supports black.us only."
        let white = try XCTUnwrap(records.first { $0["relativePath"] as? String == whitePath })
        XCTAssertEqual(white["domain"] as? String, "resources")
        XCTAssertEqual(white["title"] as? String, "Pokemon - White Version (USA, Europe) (NDSi Enhanced).nds")
        XCTAssertEqual(white["format"] as? String, "unknown")
        XCTAssertEqual(white["exists"] as? Bool, false)
        XCTAssertNil(white["byteCount"])
        XCTAssertNil(white["preview"])
        let whiteReadiness = try XCTUnwrap(white["readiness"] as? [String: Any])
        XCTAssertEqual(whiteReadiness["status"] as? String, "blocked")
        let whiteFacts = try XCTUnwrap(white["facts"] as? [[String: Any]])
        XCTAssertTrue(whiteFacts.contains { $0["label"] as? String == "Gen V Title" && $0["value"] as? String == "Pokemon - White Version (USA, Europe) (NDSi Enhanced).nds" })
        XCTAssertTrue(whiteFacts.contains { $0["label"] as? String == "Gen V Family" && $0["value"] as? String == "blackWhite" })
        XCTAssertTrue(whiteFacts.contains { $0["label"] as? String == "Gen V Source Name" && $0["value"] as? String == "pokeblack" })
        XCTAssertTrue(whiteFacts.contains { $0["label"] as? String == "Gen V Unavailable Reason" && $0["value"] as? String == whiteReason })
        XCTAssertTrue(whiteFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "unavailable" })
        XCTAssertTrue(whiteFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "titleUnavailable" })
        XCTAssertTrue(whiteFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("editing/apply") == true })
        let whiteDiagnostics = try XCTUnwrap(white["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(whiteDiagnostics.contains { $0["code"] as? String == "NDS_GEN_V_TITLE_UNAVAILABLE" })
        XCTAssertTrue(whiteDiagnostics.contains { $0["code"] as? String == "NDS_GEN_V_WRITE_BLOCKED" })

        let black2 = try XCTUnwrap(records.first { $0["relativePath"] as? String == "unavailable-titles/Pokemon - Black Version 2 (USA, Europe) (NDSi Enhanced).nds" })
        let black2Facts = try XCTUnwrap(black2["facts"] as? [[String: Any]])
        XCTAssertTrue(black2Facts.contains { $0["label"] as? String == "Gen V Family" && $0["value"] as? String == "black2White2" })
        XCTAssertTrue(black2Facts.contains { $0["label"] as? String == "Gen V Source Name" && $0["value"] as? String == "none" })
        XCTAssertTrue(black2Facts.contains { $0["label"] as? String == "Gen V Unavailable Reason" && $0["value"] as? String == "No public/materialized Black 2 decomp source root was found in the configured central corpus." })

        let white2 = try XCTUnwrap(records.first { $0["relativePath"] as? String == "unavailable-titles/Pokemon - White Version 2 (USA, Europe) (NDSi Enhanced).nds" })
        let white2Facts = try XCTUnwrap(white2["facts"] as? [[String: Any]])
        XCTAssertTrue(white2Facts.contains { $0["label"] as? String == "Gen V Family" && $0["value"] as? String == "black2White2" })
        XCTAssertTrue(white2Facts.contains { $0["label"] as? String == "Gen V Source Name" && $0["value"] as? String == "none" })
        XCTAssertTrue(white2Facts.contains { $0["label"] as? String == "Gen V Unavailable Reason" && $0["value"] as? String == "No public/materialized White 2 decomp source root was found in the configured central corpus." })

        let resourceIndex = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resource-index", root.path, "--json"])
        )
        let items = try XCTUnwrap(resourceIndex["items"] as? [[String: Any]])
        let makefileResourceItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == "Makefile" })
        let makefileResourceFacts = try XCTUnwrap(makefileResourceItem["facts"] as? [[String: Any]])
        XCTAssertTrue(makefileResourceFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "buildConfig" })
        XCTAssertTrue(makefileResourceFacts.contains { $0["label"] as? String == "Gen V Build Metadata" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(makefileResourceFacts.contains { $0["label"] as? String == "Gen V Variant Hash Presence" && ($0["value"] as? String)?.contains("black2.us/rom.sha1=missing") == true })
        XCTAssertTrue(makefileResourceFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("build, playtest, and export actions are disabled") == true })

        let sourceRootResourceItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == "src" })
        XCTAssertEqual(sourceRootResourceItem["kind"] as? String, "directory")
        XCTAssertEqual(sourceRootResourceItem["size"] as? Int, 92)
        let sourceRootResourceFacts = try XCTUnwrap(sourceRootResourceItem["facts"] as? [[String: Any]])
        XCTAssertEqual(factValue("Gen V Source Role", in: sourceRootResourceFacts), "sourceCodeInventory")
        XCTAssertEqual(factValue("Gen V Source Root Members", in: sourceRootResourceFacts), "5")
        XCTAssertEqual(factValue("Gen V Source Root Bytes", in: sourceRootResourceFacts), "92")
        XCTAssertTrue(factValue("Gen V Source Root Sample Paths", in: sourceRootResourceFacts)?.contains("src/data/pokemon/source_pokemon.inc") == true)
        XCTAssertFalse(sourceRootResourceFacts.contains { $0["label"] as? String == "Migration Status" })

        let assemblyRootResourceItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == "asm" })
        XCTAssertEqual(assemblyRootResourceItem["size"] as? Int, 5)
        let assemblyRootResourceFacts = try XCTUnwrap(assemblyRootResourceItem["facts"] as? [[String: Any]])
        XCTAssertEqual(factValue("Gen V Assembly Root Sample Paths", in: assemblyRootResourceFacts), "asm/arm9_remaining.s")
        let headerRootResourceItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == "include" })
        XCTAssertEqual(headerRootResourceItem["size"] as? Int, 16)
        let headerRootResourceFacts = try XCTUnwrap(headerRootResourceItem["facts"] as? [[String: Any]])
        XCTAssertEqual(factValue("Gen V Header Root Sample Paths", in: headerRootResourceFacts), "include/globals.h")

        let encounterResourceItem = try XCTUnwrap(items.first { $0["path"] as? String == "data/encounters/route_1.txt" })
        let encounterResourceFacts = try XCTUnwrap(encounterResourceItem["facts"] as? [[String: Any]])
        XCTAssertTrue(encounterResourceFacts.contains { $0["label"] as? String == "Gen V Encounter Record" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(encounterResourceFacts.contains { $0["label"] as? String == "Gen V Encounter Key" && $0["value"] as? String == "route_1" })

        let whiteResourceItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == whitePath })
        XCTAssertEqual(whiteResourceItem["kind"] as? String, "unknown")
        let whiteResourceFacts = try XCTUnwrap(whiteResourceItem["facts"] as? [[String: Any]])
        XCTAssertTrue(whiteResourceFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "unavailable" })
        XCTAssertTrue(whiteResourceFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "titleUnavailable" })
        XCTAssertTrue(whiteResourceFacts.contains { $0["label"] as? String == "Gen V Unavailable Reason" && $0["value"] as? String == whiteReason })
        XCTAssertTrue(whiteResourceFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("source inventory stays preview-only") == true })
    }

    func testNDSDataCatalogCommandEmitsPokeBlackDataInventoryJSON() throws {
        let root = try makeTestBlackDecompRoot()

        let catalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", root.path, "--json"])
        )

        let records = try XCTUnwrap(catalog["records"] as? [[String: Any]])
        let dataRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "data" })
        XCTAssertEqual(dataRoot["domain"] as? String, "resources")
        XCTAssertEqual(dataRoot["format"] as? String, "directory")
        XCTAssertEqual(dataRoot["recordCount"] as? Int, 5)
        let dataRootFacts = try XCTUnwrap(dataRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(dataRootFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "dataInventory" })
        XCTAssertTrue(dataRootFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(dataRootFacts.contains { $0["label"] as? String == "Gen V Reference Posture" && $0["value"] as? String == "cleanRoomReferenceOnly" })
        XCTAssertTrue(dataRootFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("source inventory stays preview-only") == true })
        XCTAssertFalse(dataRootFacts.contains { $0["label"] as? String == "Migration Status" })
        let dataRootReadiness = try XCTUnwrap(dataRoot["readiness"] as? [String: Any])
        XCTAssertEqual(dataRootReadiness["status"] as? String, "partial")
        XCTAssertTrue((dataRootReadiness["detail"] as? String)?.contains("data root") == true)
        XCTAssertTrue(records.contains { $0["relativePath"] as? String == "data/encounters/route_1.txt" })

        let resourceIndex = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resource-index", root.path, "--json"])
        )
        let items = try XCTUnwrap(resourceIndex["items"] as? [[String: Any]])
        let dataRootResourceItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == "data" })
        XCTAssertEqual(dataRootResourceItem["kind"] as? String, "directory")
        let resourceFacts = try XCTUnwrap(dataRootResourceItem["facts"] as? [[String: Any]])
        XCTAssertTrue(resourceFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "dataInventory" })
        XCTAssertTrue(resourceFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(resourceFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("source inventory stays preview-only") == true })
        XCTAssertFalse(resourceFacts.contains { $0["label"] as? String == "Migration Status" })
    }

    func testNDSDataCatalogCommandEmitsPokeBlackSourceDataDomainInventoryJSON() throws {
        let root = try makeTestBlackDecompRoot()

        let catalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", root.path, "--json"])
        )

        let records = try XCTUnwrap(catalog["records"] as? [[String: Any]])
        let samples: [(domain: String, domainValue: String, root: String, child: String, inventoryRole: String, memberRole: String, category: String, contents: String)] = [
            ("species", "pokemon", "data/pokemon", "data/pokemon/source_pokemon.txt", "pokemonDataInventory", "pokemonDataMember", "NDS Data species", "pokemon-source\n"),
            ("moves", "move", "data/moves", "data/moves/source_moves.txt", "moveDataInventory", "moveDataMember", "NDS Data moves", "moves-source\n"),
            ("items", "item", "data/items", "data/items/source_items.txt", "itemDataInventory", "itemDataMember", "NDS Data items", "items-source\n"),
            ("trainers", "trainer", "data/trainers", "data/trainers/source_trainers.txt", "trainerDataInventory", "trainerDataMember", "NDS Data trainers", "trainers-source\n"),
            ("species", "pokemon", "src/data/pokemon", "src/data/pokemon/source_pokemon.inc", "pokemonDataInventory", "pokemonDataMember", "NDS Data species", "pokemon-source-inc\n"),
            ("moves", "move", "src/data/moves", "src/data/moves/source_moves.inc", "moveDataInventory", "moveDataMember", "NDS Data moves", "moves-source-inc\n"),
            ("items", "item", "src/data/items", "src/data/items/source_items.inc", "itemDataInventory", "itemDataMember", "NDS Data items", "items-source-inc\n"),
            ("trainers", "trainer", "src/data/trainers", "src/data/trainers/source_trainers.inc", "trainerDataInventory", "trainerDataMember", "NDS Data trainers", "trainers-source-inc\n")
        ]
        let expectedBlockedActions = "parser, decoded preview, semantic controls, source writes, extraction, NARC packing, build/playtest, ROM export, mutation apply, binary writes"

        for sample in samples {
            let byteCount = sample.contents.utf8.count
            let rootRecord = try XCTUnwrap(records.first { $0["relativePath"] as? String == sample.root })
            XCTAssertEqual(rootRecord["domain"] as? String, sample.domain)
            XCTAssertEqual(rootRecord["format"] as? String, "directory")
            XCTAssertEqual(rootRecord["recordCount"] as? Int, 1)
            XCTAssertEqual(rootRecord["byteCount"] as? Int, byteCount)
            let rootFacts = try XCTUnwrap(rootRecord["facts"] as? [[String: Any]])
            XCTAssertEqual(factValue("Gen V Source Role", in: rootFacts), sample.inventoryRole)
            XCTAssertEqual(factValue("Gen V Source Data Domain", in: rootFacts), sample.domainValue)
            XCTAssertEqual(factValue("Gen V Source Data Root", in: rootFacts), sample.root)
            XCTAssertEqual(factValue("Gen V Source Data Members", in: rootFacts), "1")
            XCTAssertEqual(factValue("Gen V Source Data Bytes", in: rootFacts), "\(byteCount)")
            XCTAssertEqual(factValue("Gen V Source Data Sample Paths", in: rootFacts), sample.child)
            XCTAssertEqual(factValue("Gen V Source Data Basis", in: rootFacts), "pathFilenameCountBytesOnly")
            XCTAssertEqual(factValue("Gen V Source Data Posture", in: rootFacts), "previewOnlyNoParser")
            XCTAssertEqual(factValue("Gen V Source Data Blocked Actions", in: rootFacts), expectedBlockedActions)
            XCTAssertEqual(factValue("Gen V Source Data Blocked Reason", in: rootFacts), "domainInventoryPreviewOnly")
            XCTAssertEqual(factValue("Gen V Source Data Relationship Audit", in: rootFacts), "rootRelatedRecordsPresent")
            XCTAssertEqual(factValue("Gen V Source Data Readiness Audit", in: rootFacts), "partial")
            XCTAssertNil(factValue("Gen V Source Data Root Record", in: rootFacts))
            XCTAssertNil(rootRecord["migrationPlan"] as? [String: Any])
            XCTAssertNil(rootRecord["textBankPreview"] as? [String: Any])
            assertNoGenVSourceDataSemanticFacts(rootFacts)

            let childRecord = try XCTUnwrap(records.first { $0["relativePath"] as? String == sample.child })
            XCTAssertEqual(childRecord["domain"] as? String, sample.domain)
            XCTAssertEqual(childRecord["byteCount"] as? Int, byteCount)
            let childFacts = try XCTUnwrap(childRecord["facts"] as? [[String: Any]])
            XCTAssertEqual(factValue("Gen V Source Role", in: childFacts), sample.memberRole)
            XCTAssertEqual(factValue("Gen V Source Data Domain", in: childFacts), sample.domainValue)
            XCTAssertEqual(factValue("Gen V Source Data Root", in: childFacts), sample.root)
            XCTAssertEqual(factValue("Gen V Source Data Filename", in: childFacts), URL(fileURLWithPath: sample.child).lastPathComponent)
            XCTAssertEqual(factValue("Gen V Source Data Extension", in: childFacts), URL(fileURLWithPath: sample.child).pathExtension)
            XCTAssertEqual(factValue("Gen V Source Data Bytes", in: childFacts), "\(byteCount)")
            XCTAssertEqual(factValue("Gen V Source Data Basis", in: childFacts), "pathFilenameCountBytesOnly")
            XCTAssertEqual(factValue("Gen V Source Data Posture", in: childFacts), "previewOnlyNoParser")
            XCTAssertEqual(factValue("Gen V Source Data Blocked Actions", in: childFacts), expectedBlockedActions)
            XCTAssertEqual(factValue("Gen V Source Data Blocked Reason", in: childFacts), "memberMetadataPreviewOnly")
            XCTAssertEqual(factValue("Gen V Source Data Relationship Audit", in: childFacts), "memberRootContextOnly")
            XCTAssertEqual(factValue("Gen V Source Data Readiness Audit", in: childFacts), "partial")
            XCTAssertEqual(factValue("Gen V Source Data Root Record", in: childFacts), "\(sample.domain):\(sample.root)")
            let childRelatedRecords = try XCTUnwrap(childRecord["relatedRecords"] as? [[String: Any]])
            XCTAssertTrue(childRelatedRecords.isEmpty)
            XCTAssertNil(factValue("Related Rows", in: childFacts))
            XCTAssertNil(childRecord["migrationPlan"] as? [String: Any])
            XCTAssertNil(childRecord["textBankPreview"] as? [String: Any])
            assertNoGenVSourceDataSemanticFacts(childFacts)
        }

        let resourceIndex = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resource-index", root.path, "--json"])
        )
        let items = try XCTUnwrap(resourceIndex["items"] as? [[String: Any]])
        for sample in samples {
            let byteCount = sample.contents.utf8.count
            let rootItem = try XCTUnwrap(items.first { $0["category"] as? String == sample.category && $0["path"] as? String == sample.root })
            XCTAssertEqual(rootItem["kind"] as? String, "directory")
            XCTAssertEqual(rootItem["size"] as? Int, byteCount)
            let rootFacts = try XCTUnwrap(rootItem["facts"] as? [[String: Any]])
            XCTAssertEqual(factValue("Gen V Source Role", in: rootFacts), sample.inventoryRole)
            XCTAssertEqual(factValue("Gen V Source Data Members", in: rootFacts), "1")
            XCTAssertEqual(factValue("Gen V Source Data Bytes", in: rootFacts), "\(byteCount)")
            XCTAssertEqual(factValue("Gen V Source Data Blocked Actions", in: rootFacts), expectedBlockedActions)
            XCTAssertEqual(factValue("Gen V Source Data Blocked Reason", in: rootFacts), "domainInventoryPreviewOnly")
            XCTAssertEqual(factValue("Gen V Source Data Relationship Audit", in: rootFacts), "rootRelatedRecordsPresent")
            XCTAssertEqual(factValue("Gen V Source Data Readiness Audit", in: rootFacts), "partial")
            XCTAssertNil(factValue("Gen V Source Data Root Record", in: rootFacts))
            XCTAssertFalse(rootFacts.contains { $0["label"] as? String == "Migration Status" })
            XCTAssertFalse(rootFacts.contains { $0["label"] as? String == "Text Bank Preview" })

            let childItem = try XCTUnwrap(items.first { $0["category"] as? String == sample.category && $0["path"] as? String == sample.child })
            XCTAssertEqual(childItem["size"] as? Int, byteCount)
            let childFacts = try XCTUnwrap(childItem["facts"] as? [[String: Any]])
            XCTAssertEqual(factValue("Gen V Source Role", in: childFacts), sample.memberRole)
            XCTAssertEqual(factValue("Gen V Source Data Filename", in: childFacts), URL(fileURLWithPath: sample.child).lastPathComponent)
            XCTAssertEqual(factValue("Gen V Source Data Bytes", in: childFacts), "\(byteCount)")
            XCTAssertEqual(factValue("Gen V Source Data Blocked Actions", in: childFacts), expectedBlockedActions)
            XCTAssertEqual(factValue("Gen V Source Data Blocked Reason", in: childFacts), "memberMetadataPreviewOnly")
            XCTAssertEqual(factValue("Gen V Source Data Relationship Audit", in: childFacts), "memberRootContextOnly")
            XCTAssertEqual(factValue("Gen V Source Data Readiness Audit", in: childFacts), "partial")
            XCTAssertEqual(factValue("Gen V Source Data Root Record", in: childFacts), "\(sample.domain):\(sample.root)")
            XCTAssertFalse(childFacts.contains { $0["label"] as? String == "Related Rows" })
            XCTAssertFalse(childFacts.contains { $0["label"] as? String == "Migration Status" })
            XCTAssertFalse(childFacts.contains { $0["label"] as? String == "Text Bank Preview" })
        }
    }

    func testNDSDataCatalogCommandEmitsPokeBlackSourceDataVariantCoverageJSON() throws {
        let root = try makeTestBlackDecompRoot()
        try write("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee  pokewhite.nds\n", to: root.appendingPathComponent("white.us/rom.sha1"))
        try write("not-a-sha1\n", to: root.appendingPathComponent("black2.us/rom.sha1"))

        let catalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", root.path, "--json"])
        )

        let records = try XCTUnwrap(catalog["records"] as? [[String: Any]])
        let samples: [(domain: String, root: String, child: String, category: String)] = [
            ("species", "data/pokemon", "data/pokemon/source_pokemon.txt", "NDS Data species"),
            ("moves", "data/moves", "data/moves/source_moves.txt", "NDS Data moves"),
            ("items", "data/items", "data/items/source_items.txt", "NDS Data items"),
            ("trainers", "data/trainers", "data/trainers/source_trainers.txt", "NDS Data trainers"),
            ("species", "src/data/pokemon", "src/data/pokemon/source_pokemon.inc", "NDS Data species"),
            ("moves", "src/data/moves", "src/data/moves/source_moves.inc", "NDS Data moves"),
            ("items", "src/data/items", "src/data/items/source_items.inc", "NDS Data items"),
            ("trainers", "src/data/trainers", "src/data/trainers/source_trainers.inc", "NDS Data trainers")
        ]

        for sample in samples {
            let rootRecord = try XCTUnwrap(records.first { $0["domain"] as? String == sample.domain && $0["relativePath"] as? String == sample.root })
            let rootFacts = try XCTUnwrap(rootRecord["facts"] as? [[String: Any]])
            XCTAssertEqual(factValue("Gen V Source Data Variant Coverage", in: rootFacts), "3/4")
            XCTAssertEqual(factValue("Gen V Source Data Variant Present", in: rootFacts), "black.us, white.us, black2.us")
            XCTAssertEqual(factValue("Gen V Source Data Variant Missing", in: rootFacts), "white2.us")
            XCTAssertEqual(factValue("Gen V Source Data Variant Basis", in: rootFacts), "sourceMarkersAndRootPresenceOnly")

            let childRecord = try XCTUnwrap(records.first { $0["domain"] as? String == sample.domain && $0["relativePath"] as? String == sample.child })
            let childFacts = try XCTUnwrap(childRecord["facts"] as? [[String: Any]])
            XCTAssertNil(factValue("Gen V Source Data Variant Coverage", in: childFacts))
            XCTAssertNil(factValue("Gen V Source Data Variant Present", in: childFacts))
            XCTAssertNil(factValue("Gen V Source Data Variant Missing", in: childFacts))
            XCTAssertNil(factValue("Gen V Source Data Variant Basis", in: childFacts))
        }

        let resourceIndex = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resource-index", root.path, "--json"])
        )
        let items = try XCTUnwrap(resourceIndex["items"] as? [[String: Any]])
        for sample in samples {
            let rootItem = try XCTUnwrap(items.first { $0["category"] as? String == sample.category && $0["path"] as? String == sample.root })
            let rootFacts = try XCTUnwrap(rootItem["facts"] as? [[String: Any]])
            XCTAssertEqual(factValue("Gen V Source Data Variant Coverage", in: rootFacts), "3/4")
            XCTAssertEqual(factValue("Gen V Source Data Variant Present", in: rootFacts), "black.us, white.us, black2.us")
            XCTAssertEqual(factValue("Gen V Source Data Variant Missing", in: rootFacts), "white2.us")
            XCTAssertEqual(factValue("Gen V Source Data Variant Basis", in: rootFacts), "sourceMarkersAndRootPresenceOnly")

            let childItem = try XCTUnwrap(items.first { $0["category"] as? String == sample.category && $0["path"] as? String == sample.child })
            let childFacts = try XCTUnwrap(childItem["facts"] as? [[String: Any]])
            XCTAssertNil(factValue("Gen V Source Data Variant Coverage", in: childFacts))
        }

        let dataRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "data" })
        let dataRootFacts = try XCTUnwrap(dataRoot["facts"] as? [[String: Any]])
        XCTAssertNil(factValue("Gen V Source Data Variant Coverage", in: dataRootFacts))
        let white2Unavailable = try XCTUnwrap(records.first { ($0["relativePath"] as? String)?.contains("White Version 2") == true })
        let white2Facts = try XCTUnwrap(white2Unavailable["facts"] as? [[String: Any]])
        XCTAssertNil(factValue("Gen V Source Data Variant Coverage", in: white2Facts))
    }

    func testNDSDataCatalogCommandEmitsPokeBlackVariantReadinessPacketJSON() throws {
        let root = try makeTestBlackDecompRoot()
        try write("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee  pokewhite.nds\n", to: root.appendingPathComponent("white.us/rom.sha1"))
        try write("not-a-sha1\n", to: root.appendingPathComponent("black2.us/rom.sha1"))

        let catalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", root.path, "--json"])
        )

        let records = try XCTUnwrap(catalog["records"] as? [[String: Any]])
        let packet = try XCTUnwrap(records.first { $0["id"] as? String == "resources:gen-v/variant-readiness-packet" })
        XCTAssertEqual(packet["domain"] as? String, "resources")
        XCTAssertEqual(packet["relativePath"] as? String, "gen-v/variant-readiness-packet")
        XCTAssertEqual(packet["format"] as? String, "unknown")
        XCTAssertEqual(packet["role"] as? String, "metadataPacket")
        XCTAssertEqual(packet["exists"] as? Bool, true)
        let readiness = try XCTUnwrap(packet["readiness"] as? [String: Any])
        XCTAssertEqual(readiness["status"] as? String, "partial")
        let facts = try XCTUnwrap(packet["facts"] as? [[String: Any]])
        XCTAssertEqual(factValue("Gen V Source Role", in: facts), "variantReadinessPacket")
        XCTAssertEqual(factValue("Gen V Variant Readiness Packet", in: facts), "previewOnly")
        XCTAssertEqual(factValue("Gen V Variant Readiness Basis", in: facts), "existingCatalogFactsOnly")
        XCTAssertEqual(factValue("Gen V Variant Readiness Posture", in: facts), "previewOnlyNoParserNoWrites")
        XCTAssertEqual(
            factValue("Gen V Variant Marker States", in: facts),
            "black.us=sourceMarkerPresent, white.us=sourceMarkerPresent, black2.us=sourceMarkerPresent, white2.us=unavailable"
        )
        XCTAssertEqual(
            factValue("Gen V SHA1 Text States", in: facts),
            "black.us=valid, white.us=valid, black2.us=invalid, white2.us=missing"
        )
        XCTAssertEqual(
            factValue("Gen V SHA1 Valid Digests", in: facts),
            "black.us=ffffffffffffffffffffffffffffffffffffffff, white.us=eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        )
        XCTAssertEqual(factValue("Gen V Source Root Summaries", in: facts), "src=5/92, asm=1/5, include=1/16")
        XCTAssertTrue(factValue("Gen V Source Data Summary", in: facts)?.contains("roots=8, members=8, variantCoverage=3/4") == true)
        XCTAssertTrue(factValue("Gen V Fielddata Summary", in: facts)?.contains("roots=5") == true)
        XCTAssertEqual(
            factValue("Gen V Message Summary", in: facts),
            "candidates=6, extensions=bin, dat, gmm, msg, str, txt, noDecodedPreviewRows=6"
        )
        XCTAssertTrue(factValue("Gen V Build Metadata Summary", in: facts)?.contains("variantHashes=black.us/rom.sha1=present") == true)
        XCTAssertTrue(factValue("Gen V Blocked Actions", in: facts)?.contains("binary write") == true)
        XCTAssertNil(packet["migrationPlan"])
        XCTAssertNil(packet["textBankPreview"])
        let diagnostics = try XCTUnwrap(packet["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "NDS_GEN_V_VARIANT_READINESS_PACKET_PREVIEW_ONLY" })
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "NDS_GEN_V_WRITE_BLOCKED" })

        let resourceIndex = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resource-index", root.path, "--json"])
        )
        let items = try XCTUnwrap(resourceIndex["items"] as? [[String: Any]])
        let packetItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == "gen-v/variant-readiness-packet" })
        XCTAssertEqual(packetItem["kind"] as? String, "unknown")
        let itemFacts = try XCTUnwrap(packetItem["facts"] as? [[String: Any]])
        XCTAssertEqual(factValue("Gen V Source Role", in: itemFacts), "variantReadinessPacket")
        XCTAssertEqual(factValue("Gen V Variant Readiness Packet", in: itemFacts), "previewOnly")
        XCTAssertEqual(factValue("Gen V Variant Readiness Basis", in: itemFacts), "existingCatalogFactsOnly")
        XCTAssertNil(factValue("Migration Status", in: itemFacts))
        XCTAssertNil(factValue("Text Bank Preview", in: itemFacts))
    }

    func testNDSDataCatalogCommandEmitsPokeBlackGeneratedOutputFreshnessPacketJSON() throws {
        let root = try makeTestBlackDecompRoot()
        try write("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee  pokewhite.nds\n", to: root.appendingPathComponent("white.us/rom.sha1"))
        try write("not-a-sha1\n", to: root.appendingPathComponent("black2.us/rom.sha1"))

        let catalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", root.path, "--json"])
        )

        let records = try XCTUnwrap(catalog["records"] as? [[String: Any]])
        let packet = try XCTUnwrap(records.first { $0["id"] as? String == "resources:gen-v/generated-output-freshness-packet" })
        XCTAssertEqual(packet["domain"] as? String, "resources")
        XCTAssertEqual(packet["relativePath"] as? String, "gen-v/generated-output-freshness-packet")
        XCTAssertEqual(packet["format"] as? String, "unknown")
        XCTAssertEqual(packet["role"] as? String, "metadataPacket")
        XCTAssertEqual(packet["exists"] as? Bool, true)
        let readiness = try XCTUnwrap(packet["readiness"] as? [String: Any])
        XCTAssertEqual(readiness["status"] as? String, "partial")
        let facts = try XCTUnwrap(packet["facts"] as? [[String: Any]])
        XCTAssertEqual(factValue("Gen V Source Role", in: facts), "generatedOutputFreshnessPacket")
        XCTAssertEqual(factValue("Gen V Generated Output Freshness Packet", in: facts), "previewOnly")
        XCTAssertEqual(factValue("Gen V Generated Output Freshness Basis", in: facts), "existingCatalogAndBuildValidationFactsOnly")
        XCTAssertEqual(factValue("Gen V Generated Output Freshness Posture", in: facts), "previewOnlyNoBuildNoGeneratedOutputWrites")
        XCTAssertEqual(
            factValue("Gen V Source Marker States", in: facts),
            "black.us=sourceMarkerPresent, white.us=sourceMarkerPresent, black2.us=sourceMarkerPresent, white2.us=unavailable"
        )
        XCTAssertEqual(
            factValue("Gen V SHA1 Text States", in: facts),
            "black.us=valid, white.us=valid, black2.us=invalid, white2.us=missing"
        )
        XCTAssertTrue(factValue("Gen V Build Metadata Summary", in: facts)?.contains("variantHashes=black.us/rom.sha1=present") == true)
        XCTAssertEqual(factValue("Gen V Source Root Summaries", in: facts), "src=5/92, asm=1/5, include=1/16")
        XCTAssertTrue(factValue("Gen V Variant Readiness Summary", in: facts)?.contains("packet=present") == true)
        XCTAssertTrue(factValue("Gen V Declared Generated Outputs", in: facts)?.contains("build=missing") == true)
        XCTAssertTrue(factValue("Gen V Declared Generated Outputs", in: facts)?.contains("pokeblack.nds=missing") == true)
        XCTAssertTrue(factValue("Gen V Build Target Output Freshness", in: facts)?.contains("black-rom:pokeblack.nds=missing") == true)
        XCTAssertTrue(factValue("Gen V Build Target Output Freshness", in: facts)?.contains("checksum=outputMissing") == true)
        XCTAssertTrue(factValue("Gen V Build Target Output Freshness", in: facts)?.contains("freshness=outputMissing") == true)
        XCTAssertTrue(factValue("Gen V Blocked Actions", in: facts)?.contains("binary write") == true)
        XCTAssertNil(packet["migrationPlan"])
        XCTAssertNil(packet["textBankPreview"])
        let diagnostics = try XCTUnwrap(packet["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "NDS_GEN_V_GENERATED_OUTPUT_FRESHNESS_PACKET_PREVIEW_ONLY" })
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "NDS_GEN_V_WRITE_BLOCKED" })

        let resourceIndex = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resource-index", root.path, "--json"])
        )
        let items = try XCTUnwrap(resourceIndex["items"] as? [[String: Any]])
        let packetItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == "gen-v/generated-output-freshness-packet" })
        XCTAssertEqual(packetItem["kind"] as? String, "unknown")
        let itemFacts = try XCTUnwrap(packetItem["facts"] as? [[String: Any]])
        XCTAssertEqual(factValue("Gen V Source Role", in: itemFacts), "generatedOutputFreshnessPacket")
        XCTAssertEqual(factValue("Gen V Generated Output Freshness Packet", in: itemFacts), "previewOnly")
        XCTAssertTrue(factValue("Gen V Build Target Output Freshness", in: itemFacts)?.contains("black-rom:pokeblack.nds=missing") == true)
        XCTAssertNil(factValue("Migration Status", in: itemFacts))
        XCTAssertNil(factValue("Text Bank Preview", in: itemFacts))
    }

    func testNDSDataCatalogCommandEmitsPokeBlackArchiveGroupInventoryJSON() throws {
        let root = try makeTestBlackDecompRoot()

        let catalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", root.path, "--json"])
        )

        let records = try XCTUnwrap(catalog["records"] as? [[String: Any]])
        let archiveGroupRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/a" })
        XCTAssertEqual(archiveGroupRoot["domain"] as? String, "resources")
        XCTAssertEqual(archiveGroupRoot["format"] as? String, "directory")
        XCTAssertEqual(archiveGroupRoot["recordCount"] as? Int, 1)
        let archiveGroupRootFacts = try XCTUnwrap(archiveGroupRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(archiveGroupRootFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "nitroArchiveGroupInventory" })
        XCTAssertTrue(archiveGroupRootFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(archiveGroupRootFacts.contains { $0["label"] as? String == "Gen V Reference Posture" && $0["value"] as? String == "cleanRoomReferenceOnly" })
        XCTAssertTrue(archiveGroupRootFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("source inventory stays preview-only") == true })
        XCTAssertFalse(archiveGroupRootFacts.contains { $0["label"] as? String == "Migration Status" })
        let archiveGroupRootReadiness = try XCTUnwrap(archiveGroupRoot["readiness"] as? [String: Any])
        XCTAssertEqual(archiveGroupRootReadiness["status"] as? String, "partial")
        XCTAssertTrue((archiveGroupRootReadiness["detail"] as? String)?.contains("archive-group root") == true)

        let archiveGroupChild = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/a/0/0/0/resource.bin" })
        let archiveGroupChildFacts = try XCTUnwrap(archiveGroupChild["facts"] as? [[String: Any]])
        XCTAssertTrue(archiveGroupChildFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "nitroArchiveGroup" })

        let resourceIndex = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resource-index", root.path, "--json"])
        )
        let items = try XCTUnwrap(resourceIndex["items"] as? [[String: Any]])
        let archiveGroupResourceItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == "files/a" })
        XCTAssertEqual(archiveGroupResourceItem["kind"] as? String, "directory")
        let resourceFacts = try XCTUnwrap(archiveGroupResourceItem["facts"] as? [[String: Any]])
        XCTAssertTrue(resourceFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "nitroArchiveGroupInventory" })
        XCTAssertTrue(resourceFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(resourceFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("source inventory stays preview-only") == true })
        XCTAssertFalse(resourceFacts.contains { $0["label"] as? String == "Migration Status" })
    }

    func testNDSDataCatalogCommandEmitsPokeBlackNitroFSRootInventoryJSON() throws {
        let root = try makeTestBlackDecompRoot()

        let catalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", root.path, "--json"])
        )

        let records = try XCTUnwrap(catalog["records"] as? [[String: Any]])
        let filesRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files" })
        XCTAssertEqual(filesRoot["id"] as? String, "resources:files")
        XCTAssertEqual(filesRoot["domain"] as? String, "resources")
        XCTAssertEqual(filesRoot["format"] as? String, "directory")
        XCTAssertEqual(filesRoot["recordCount"] as? Int, 15)
        let filesRootFacts = try XCTUnwrap(filesRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(filesRootFacts.contains { $0["label"] as? String == "Shallow Count" && $0["value"] as? String == "15" })
        XCTAssertTrue(filesRootFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "nitroFSRootInventory" })
        XCTAssertTrue(filesRootFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(filesRootFacts.contains { $0["label"] as? String == "Gen V Reference Posture" && $0["value"] as? String == "cleanRoomReferenceOnly" })
        XCTAssertTrue(filesRootFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("source inventory stays preview-only") == true })
        XCTAssertFalse(filesRootFacts.contains { $0["label"] as? String == "Migration Status" })
        XCTAssertFalse(filesRootFacts.contains { $0["label"] as? String == "Text Bank Preview" })
        let filesRootReadiness = try XCTUnwrap(filesRoot["readiness"] as? [String: Any])
        XCTAssertEqual(filesRootReadiness["status"] as? String, "partial")
        XCTAssertTrue((filesRootReadiness["detail"] as? String)?.contains("files root") == true)

        let archiveGroupChild = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/a/0/0/0/resource.bin" })
        let archiveGroupChildFacts = try XCTUnwrap(archiveGroupChild["facts"] as? [[String: Any]])
        XCTAssertTrue(archiveGroupChildFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "nitroArchiveGroup" })
        let messageBankChild = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/msgdata/story/message_bank.txt" })
        let messageBankChildFacts = try XCTUnwrap(messageBankChild["facts"] as? [[String: Any]])
        XCTAssertTrue(messageBankChildFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "messageBankMetadata" })
        let soundArchiveChild = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/wb_sound_data.sdat" })
        let soundArchiveChildFacts = try XCTUnwrap(soundArchiveChild["facts"] as? [[String: Any]])
        XCTAssertTrue(soundArchiveChildFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "soundArchiveMetadata" })

        let resourceIndex = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resource-index", root.path, "--json"])
        )
        let items = try XCTUnwrap(resourceIndex["items"] as? [[String: Any]])
        let filesResourceItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == "files" })
        XCTAssertEqual(filesResourceItem["kind"] as? String, "directory")
        let resourceFacts = try XCTUnwrap(filesResourceItem["facts"] as? [[String: Any]])
        XCTAssertTrue(resourceFacts.contains { $0["label"] as? String == "Shallow Count" && $0["value"] as? String == "15" })
        XCTAssertTrue(resourceFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "nitroFSRootInventory" })
        XCTAssertTrue(resourceFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(resourceFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("source inventory stays preview-only") == true })
        XCTAssertFalse(resourceFacts.contains { $0["label"] as? String == "Migration Status" })
    }

    func testNDSDataCatalogCommandEmitsPokeBlackFielddataInventoryJSON() throws {
        let root = try makeTestBlackDecompRoot()

        let catalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", root.path, "--json"])
        )

        let records = try XCTUnwrap(catalog["records"] as? [[String: Any]])
        let fielddataRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata" })
        XCTAssertEqual(fielddataRoot["id"] as? String, "resources:files/fielddata")
        XCTAssertEqual(fielddataRoot["domain"] as? String, "resources")
        XCTAssertEqual(fielddataRoot["format"] as? String, "directory")
        XCTAssertEqual(fielddataRoot["recordCount"] as? Int, 5)
        let fielddataRootFacts = try XCTUnwrap(fielddataRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(fielddataRootFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "fielddataInventory" })
        XCTAssertTrue(fielddataRootFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(fielddataRootFacts.contains { $0["label"] as? String == "Gen V Reference Posture" && $0["value"] as? String == "cleanRoomReferenceOnly" })
        XCTAssertTrue(fielddataRootFacts.contains { $0["label"] as? String == "Gen V Blocked Actions" && ($0["value"] as? String)?.contains("NARC pack") == true })
        XCTAssertTrue(fielddataRootFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("source inventory stays preview-only") == true })
        XCTAssertFalse(fielddataRootFacts.contains { $0["label"] as? String == "Migration Status" })
        let fielddataRootReadiness = try XCTUnwrap(fielddataRoot["readiness"] as? [String: Any])
        XCTAssertEqual(fielddataRootReadiness["status"] as? String, "partial")
        XCTAssertTrue((fielddataRootReadiness["detail"] as? String)?.contains("fielddata inventory") == true)

        let mapMatrixRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/mapmatrix" })
        XCTAssertEqual(mapMatrixRoot["id"] as? String, "maps:files/fielddata/mapmatrix")
        XCTAssertEqual(mapMatrixRoot["domain"] as? String, "maps")
        XCTAssertEqual(mapMatrixRoot["format"] as? String, "directory")
        XCTAssertEqual(mapMatrixRoot["recordCount"] as? Int, 1)
        let mapMatrixRootFacts = try XCTUnwrap(mapMatrixRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(mapMatrixRootFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "fielddataMapMatrixInventory" })
        XCTAssertFalse(mapMatrixRootFacts.contains { $0["label"] as? String == "Migration Status" })

        let mapMatrixChild = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/mapmatrix/0001.bin" })
        let mapMatrixChildFacts = try XCTUnwrap(mapMatrixChild["facts"] as? [[String: Any]])
        XCTAssertTrue(mapMatrixChildFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "fielddataMapMatrixMember" })
        XCTAssertTrue(mapMatrixChildFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        let mapMatrixChildRelatedRecords = try XCTUnwrap(mapMatrixChild["relatedRecords"] as? [[String: Any]])
        XCTAssertFalse(mapMatrixChildRelatedRecords.contains { $0["recordID"] as? String == "resources:files/fielddata" })

        let mapTableRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/maptable" })
        XCTAssertEqual(mapTableRoot["id"] as? String, "maps:files/fielddata/maptable")
        XCTAssertEqual(mapTableRoot["domain"] as? String, "maps")
        XCTAssertEqual(mapTableRoot["format"] as? String, "directory")
        XCTAssertEqual(mapTableRoot["recordCount"] as? Int, 1)
        let mapTableRootFacts = try XCTUnwrap(mapTableRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(mapTableRootFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "fielddataMapTableInventory" })
        XCTAssertFalse(mapTableRootFacts.contains { $0["label"] as? String == "Migration Status" })

        let mapTableChild = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/maptable/map.bin" })
        let mapTableChildFacts = try XCTUnwrap(mapTableChild["facts"] as? [[String: Any]])
        XCTAssertTrue(mapTableChildFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "fielddataMapTableMember" })
        XCTAssertTrue(mapTableChildFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        let mapTableChildRelatedRecords = try XCTUnwrap(mapTableChild["relatedRecords"] as? [[String: Any]])
        XCTAssertFalse(mapTableChildRelatedRecords.contains { $0["recordID"] as? String == "resources:files/fielddata" })

        let scriptRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/script" })
        XCTAssertEqual(scriptRoot["id"] as? String, "scripts:files/fielddata/script")
        XCTAssertEqual(scriptRoot["domain"] as? String, "scripts")
        XCTAssertEqual(scriptRoot["format"] as? String, "directory")
        XCTAssertEqual(scriptRoot["recordCount"] as? Int, 2)
        XCTAssertEqual(scriptRoot["byteCount"] as? Int, 4)
        let scriptRootFacts = try XCTUnwrap(scriptRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(scriptRootFacts.contains { $0["label"] as? String == "Shallow Count" && $0["value"] as? String == "2" })
        XCTAssertTrue(scriptRootFacts.contains { $0["label"] as? String == "Bytes" && $0["value"] as? String == "4" })
        XCTAssertTrue(scriptRootFacts.contains { $0["label"] as? String == "Gen V Script Members" && $0["value"] as? String == "2" })
        XCTAssertTrue(scriptRootFacts.contains { $0["label"] as? String == "Gen V Script Bytes" && $0["value"] as? String == "4" })
        XCTAssertTrue(scriptRootFacts.contains { $0["label"] as? String == "Gen V Script Sample Paths" && ($0["value"] as? String)?.contains("files/fielddata/script/scr_seq/0001.bin") == true })
        XCTAssertTrue(scriptRootFacts.contains { $0["label"] as? String == "Gen V Script Sample Paths" && ($0["value"] as? String)?.contains("files/fielddata/script/scr_seq/0002.bin") == true })
        XCTAssertTrue(scriptRootFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "fielddataScriptInventory" })
        XCTAssertTrue(scriptRootFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(scriptRootFacts.contains { $0["label"] as? String == "Gen V Blocked Actions" && ($0["value"] as? String)?.contains("NARC pack") == true })
        XCTAssertFalse(scriptRootFacts.contains { $0["label"] as? String == "Migration Status" })
        let scriptRootDiagnostics = try XCTUnwrap(scriptRoot["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(scriptRootDiagnostics.contains { $0["code"] as? String == "NDS_GEN_V_READINESS_PREVIEW_ONLY" })
        XCTAssertTrue(scriptRootDiagnostics.contains { $0["code"] as? String == "NDS_GEN_V_WRITE_BLOCKED" })

        let scriptChild = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/script/scr_seq/0001.bin" })
        XCTAssertEqual(scriptChild["byteCount"] as? Int, 1)
        let scriptChildFacts = try XCTUnwrap(scriptChild["facts"] as? [[String: Any]])
        XCTAssertTrue(scriptChildFacts.contains { $0["label"] as? String == "Bytes" && $0["value"] as? String == "1" })
        XCTAssertTrue(scriptChildFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "fielddataScriptMember" })
        XCTAssertTrue(scriptChildFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(scriptChildFacts.contains { $0["label"] as? String == "Gen V Blocked Actions" && ($0["value"] as? String)?.contains("binary write") == true })
        let scriptChildDiagnostics = try XCTUnwrap(scriptChild["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(scriptChildDiagnostics.contains { $0["code"] as? String == "NDS_GEN_V_WRITE_BLOCKED" })
        let scriptChildRelatedRecords = try XCTUnwrap(scriptChild["relatedRecords"] as? [[String: Any]])
        XCTAssertFalse(scriptChildRelatedRecords.contains { $0["recordID"] as? String == "resources:files/fielddata" })

        let secondScriptChild = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/script/scr_seq/0002.bin" })
        XCTAssertEqual(secondScriptChild["byteCount"] as? Int, 3)
        let secondScriptChildFacts = try XCTUnwrap(secondScriptChild["facts"] as? [[String: Any]])
        XCTAssertTrue(secondScriptChildFacts.contains { $0["label"] as? String == "Bytes" && $0["value"] as? String == "3" })
        XCTAssertTrue(secondScriptChildFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "fielddataScriptMember" })
        let secondScriptChildDiagnostics = try XCTUnwrap(secondScriptChild["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(secondScriptChildDiagnostics.contains { $0["code"] as? String == "NDS_GEN_V_WRITE_BLOCKED" })

        let zoneEventRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/eventdata/zone_event" })
        XCTAssertEqual(zoneEventRoot["id"] as? String, "scripts:files/fielddata/eventdata/zone_event")
        XCTAssertEqual(zoneEventRoot["domain"] as? String, "scripts")
        XCTAssertEqual(zoneEventRoot["format"] as? String, "directory")
        XCTAssertEqual(zoneEventRoot["recordCount"] as? Int, 1)
        let zoneEventRootFacts = try XCTUnwrap(zoneEventRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(zoneEventRootFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "fielddataZoneEventInventory" })
        XCTAssertFalse(zoneEventRootFacts.contains { $0["label"] as? String == "Migration Status" })

        let zoneEventChild = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/fielddata/eventdata/zone_event/zone_001.json" })
        let zoneEventChildFacts = try XCTUnwrap(zoneEventChild["facts"] as? [[String: Any]])
        XCTAssertTrue(zoneEventChildFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "fielddataZoneEventMetadata" })
        XCTAssertTrue(zoneEventChildFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        let zoneEventChildRelatedRecords = try XCTUnwrap(zoneEventChild["relatedRecords"] as? [[String: Any]])
        XCTAssertFalse(zoneEventChildRelatedRecords.contains { $0["recordID"] as? String == "resources:files/fielddata" })

        let fielddataRootIDs = genVEncounterFielddataMessageContextRecordIDs()
        let expectedRelatedRows = "\(fielddataRootIDs.count - 1)"
        let allGenVContextDomains = "encounters, items, maps, moves, resources, scripts, species, text, trainers"
        func assertFielddataRootRelationships(_ record: [String: Any], facts: [[String: Any]], relatedDomains: String) throws {
            let recordID = try XCTUnwrap(record["id"] as? String)
            let relatedRecords = try XCTUnwrap(record["relatedRecords"] as? [[String: Any]])
            XCTAssertEqual(Set(relatedRecords.compactMap { $0["recordID"] as? String }), fielddataRootIDs.subtracting([recordID]))
            XCTAssertTrue(facts.contains { $0["label"] as? String == "Related Rows" && $0["value"] as? String == expectedRelatedRows })
            XCTAssertTrue(facts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == relatedDomains })
        }
        try assertFielddataRootRelationships(fielddataRoot, facts: fielddataRootFacts, relatedDomains: allGenVContextDomains)
        try assertFielddataRootRelationships(mapMatrixRoot, facts: mapMatrixRootFacts, relatedDomains: allGenVContextDomains)
        try assertFielddataRootRelationships(mapTableRoot, facts: mapTableRootFacts, relatedDomains: allGenVContextDomains)
        try assertFielddataRootRelationships(scriptRoot, facts: scriptRootFacts, relatedDomains: allGenVContextDomains)
        try assertFielddataRootRelationships(zoneEventRoot, facts: zoneEventRootFacts, relatedDomains: allGenVContextDomains)

        let resourceIndex = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resource-index", root.path, "--json"])
        )
        let items = try XCTUnwrap(resourceIndex["items"] as? [[String: Any]])
        let fielddataResource = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == "files/fielddata" })
        let fielddataResourceFacts = try XCTUnwrap(fielddataResource["facts"] as? [[String: Any]])
        XCTAssertTrue(fielddataResourceFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "fielddataInventory" })
        XCTAssertTrue(fielddataResourceFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(fielddataResourceFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("source inventory stays preview-only") == true })
        XCTAssertTrue(fielddataResourceFacts.contains { $0["label"] as? String == "Related Rows" && $0["value"] as? String == expectedRelatedRows })
        XCTAssertTrue(fielddataResourceFacts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == allGenVContextDomains })
        XCTAssertFalse(fielddataResourceFacts.contains { $0["label"] as? String == "Migration Status" })

        let mapMatrixResource = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data maps" && $0["path"] as? String == "files/fielddata/mapmatrix" })
        let mapMatrixResourceFacts = try XCTUnwrap(mapMatrixResource["facts"] as? [[String: Any]])
        XCTAssertTrue(mapMatrixResourceFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "fielddataMapMatrixInventory" })
        XCTAssertTrue(mapMatrixResourceFacts.contains { $0["label"] as? String == "Related Rows" && $0["value"] as? String == expectedRelatedRows })
        XCTAssertTrue(mapMatrixResourceFacts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == allGenVContextDomains })
        XCTAssertFalse(mapMatrixResourceFacts.contains { $0["label"] as? String == "Migration Status" })

        let mapTableResource = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data maps" && $0["path"] as? String == "files/fielddata/maptable" })
        let mapTableResourceFacts = try XCTUnwrap(mapTableResource["facts"] as? [[String: Any]])
        XCTAssertTrue(mapTableResourceFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "fielddataMapTableInventory" })
        XCTAssertTrue(mapTableResourceFacts.contains { $0["label"] as? String == "Related Rows" && $0["value"] as? String == expectedRelatedRows })
        XCTAssertTrue(mapTableResourceFacts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == allGenVContextDomains })
        XCTAssertFalse(mapTableResourceFacts.contains { $0["label"] as? String == "Migration Status" })

        let scriptResource = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data scripts" && $0["path"] as? String == "files/fielddata/script" })
        XCTAssertEqual(scriptResource["size"] as? Int, 4)
        let scriptResourceFacts = try XCTUnwrap(scriptResource["facts"] as? [[String: Any]])
        XCTAssertTrue(scriptResourceFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "fielddataScriptInventory" })
        XCTAssertTrue(scriptResourceFacts.contains { $0["label"] as? String == "Gen V Script Members" && $0["value"] as? String == "2" })
        XCTAssertTrue(scriptResourceFacts.contains { $0["label"] as? String == "Gen V Script Bytes" && $0["value"] as? String == "4" })
        XCTAssertTrue(scriptResourceFacts.contains { $0["label"] as? String == "Related Rows" && $0["value"] as? String == expectedRelatedRows })
        XCTAssertTrue(scriptResourceFacts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == allGenVContextDomains })
        XCTAssertFalse(scriptResourceFacts.contains { $0["label"] as? String == "Migration Status" })

        let zoneEventResource = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data scripts" && $0["path"] as? String == "files/fielddata/eventdata/zone_event" })
        let zoneEventResourceFacts = try XCTUnwrap(zoneEventResource["facts"] as? [[String: Any]])
        XCTAssertTrue(zoneEventResourceFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "fielddataZoneEventInventory" })
        XCTAssertTrue(zoneEventResourceFacts.contains { $0["label"] as? String == "Related Rows" && $0["value"] as? String == expectedRelatedRows })
        XCTAssertTrue(zoneEventResourceFacts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == allGenVContextDomains })
        XCTAssertFalse(zoneEventResourceFacts.contains { $0["label"] as? String == "Migration Status" })
    }

    func testNDSDataCatalogCommandLinksPokeBlackSourceDataDomainInventoryRelatedRowsJSON() throws {
        let root = try makeTestBlackDecompRoot()

        let catalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", root.path, "--json"])
        )

        let records = try XCTUnwrap(catalog["records"] as? [[String: Any]])
        let recordsByID = Dictionary(uniqueKeysWithValues: records.compactMap { record -> (String, [String: Any])? in
            guard let id = record["id"] as? String else { return nil }
            return (id, record)
        })
        let contextIDs = genVEncounterFielddataMessageContextRecordIDs()
        let expectedRelatedRows = "\(contextIDs.count - 1)"
        let allGenVContextDomains = "encounters, items, maps, moves, resources, scripts, species, text, trainers"
        let expectedBlockedActions = "parser, decoded preview, semantic controls, source writes, extraction, NARC packing, build/playtest, ROM export, mutation apply, binary writes"
        for id in contextIDs {
            let record = try XCTUnwrap(recordsByID[id], "Missing Gen V context record \(id)")
            let relatedRecords = try XCTUnwrap(record["relatedRecords"] as? [[String: Any]])
            XCTAssertEqual(Set(relatedRecords.compactMap { $0["recordID"] as? String }), contextIDs.subtracting([id]), "Unexpected related rows for \(id)")
            let facts = try XCTUnwrap(record["facts"] as? [[String: Any]])
            XCTAssertTrue(facts.contains { $0["label"] as? String == "Related Rows" && $0["value"] as? String == expectedRelatedRows })
            XCTAssertTrue(facts.contains { $0["label"] as? String == "Readiness" && $0["value"] as? String == "partial" })
        }

        let encounter = try XCTUnwrap(recordsByID["encounters:data/encounters/route_1.txt"])
        let encounterFacts = try XCTUnwrap(encounter["facts"] as? [[String: Any]])
        XCTAssertTrue(encounterFacts.contains { $0["label"] as? String == "Gen V Encounter Record" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(encounterFacts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == "items, maps, moves, resources, scripts, species, text, trainers" })

        let messageBankRoot = try XCTUnwrap(recordsByID["text:files/msgdata"])
        let messageBankRootFacts = try XCTUnwrap(messageBankRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(messageBankRootFacts.contains { $0["label"] as? String == "Gen V Message Candidate Count" && $0["value"] as? String == "6" })
        XCTAssertTrue(messageBankRootFacts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == "encounters, items, maps, moves, resources, scripts, species, trainers" })

        let numberedMessageCandidate = try XCTUnwrap(recordsByID["resources:files/msgdata/msg/0001.bin"])
        let numberedMessageRelatedRecords = try XCTUnwrap(numberedMessageCandidate["relatedRecords"] as? [[String: Any]])
        XCTAssertFalse(numberedMessageRelatedRecords.contains { $0["recordID"] as? String == "maps:files/fielddata/mapmatrix/0001.bin" })
        XCTAssertFalse(numberedMessageRelatedRecords.contains { $0["recordID"] as? String == "resources:files/fielddata/script/scr_seq/0001.bin" })
        let numberedMessageFacts = try XCTUnwrap(numberedMessageCandidate["facts"] as? [[String: Any]])
        XCTAssertTrue(numberedMessageFacts.contains { $0["label"] as? String == "Gen V Message Decoded Preview" && $0["value"] as? String == "noDecodedPreview" })
        XCTAssertTrue(numberedMessageFacts.contains { $0["label"] as? String == "Gen V Message Numeric Bank Hint" && $0["value"] as? String == "0001" })
        XCTAssertTrue(numberedMessageFacts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == allGenVContextDomains })

        let sourceDataRows = [
            ("species:data/pokemon", "species:data/pokemon/source_pokemon.txt", "pokemonDataInventory", "pokemonDataMember"),
            ("moves:data/moves", "moves:data/moves/source_moves.txt", "moveDataInventory", "moveDataMember"),
            ("items:data/items", "items:data/items/source_items.txt", "itemDataInventory", "itemDataMember"),
            ("trainers:data/trainers", "trainers:data/trainers/source_trainers.txt", "trainerDataInventory", "trainerDataMember"),
            ("species:src/data/pokemon", "species:src/data/pokemon/source_pokemon.inc", "pokemonDataInventory", "pokemonDataMember"),
            ("moves:src/data/moves", "moves:src/data/moves/source_moves.inc", "moveDataInventory", "moveDataMember"),
            ("items:src/data/items", "items:src/data/items/source_items.inc", "itemDataInventory", "itemDataMember"),
            ("trainers:src/data/trainers", "trainers:src/data/trainers/source_trainers.inc", "trainerDataInventory", "trainerDataMember")
        ]
        for (rootID, memberID, rootRole, memberRole) in sourceDataRows {
            let rootRecord = try XCTUnwrap(recordsByID[rootID], "Missing Gen V source data root \(rootID)")
            let rootFacts = try XCTUnwrap(rootRecord["facts"] as? [[String: Any]])
            XCTAssertTrue(rootFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == rootRole })
            XCTAssertTrue(rootFacts.contains { $0["label"] as? String == "Related Rows" && $0["value"] as? String == expectedRelatedRows })
            XCTAssertTrue(rootFacts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == allGenVContextDomains })
            XCTAssertTrue(rootFacts.contains { $0["label"] as? String == "Readiness" && $0["value"] as? String == "partial" })
            XCTAssertEqual(factValue("Gen V Source Data Relationship Audit", in: rootFacts), "rootRelatedRecordsPresent")
            XCTAssertEqual(factValue("Gen V Source Data Readiness Audit", in: rootFacts), "partial")
            XCTAssertEqual(factValue("Gen V Source Data Blocked Actions", in: rootFacts), expectedBlockedActions)
            XCTAssertEqual(factValue("Gen V Source Data Blocked Reason", in: rootFacts), "domainInventoryPreviewOnly")
            XCTAssertNil(factValue("Gen V Source Data Root Record", in: rootFacts))

            let memberRecord = try XCTUnwrap(recordsByID[memberID], "Missing Gen V source data member \(memberID)")
            let memberFacts = try XCTUnwrap(memberRecord["facts"] as? [[String: Any]])
            XCTAssertEqual(factValue("Gen V Source Role", in: memberFacts), memberRole)
            XCTAssertEqual(factValue("Gen V Source Data Relationship Audit", in: memberFacts), "memberRootContextOnly")
            XCTAssertEqual(factValue("Gen V Source Data Readiness Audit", in: memberFacts), "partial")
            XCTAssertEqual(factValue("Gen V Source Data Blocked Actions", in: memberFacts), expectedBlockedActions)
            XCTAssertEqual(factValue("Gen V Source Data Blocked Reason", in: memberFacts), "memberMetadataPreviewOnly")
            XCTAssertEqual(factValue("Gen V Source Data Root Record", in: memberFacts), rootID)
            let memberRelatedRecords = try XCTUnwrap(memberRecord["relatedRecords"] as? [[String: Any]])
            XCTAssertTrue(memberRelatedRecords.isEmpty)
            XCTAssertNil(factValue("Related Rows", in: memberFacts))
        }

        let pokemonSourceMember = try XCTUnwrap(recordsByID["species:data/pokemon/source_pokemon.txt"])
        let pokemonSourceMemberFacts = try XCTUnwrap(pokemonSourceMember["facts"] as? [[String: Any]])
        XCTAssertTrue(pokemonSourceMemberFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "pokemonDataMember" })
        XCTAssertFalse(pokemonSourceMemberFacts.contains { $0["label"] as? String == "Related Rows" })
        let pokemonSourceMemberRelatedRecords = try XCTUnwrap(pokemonSourceMember["relatedRecords"] as? [[String: Any]])
        XCTAssertTrue(pokemonSourceMemberRelatedRecords.isEmpty)

        let scriptChild = try XCTUnwrap(recordsByID["resources:files/fielddata/script/scr_seq/0001.bin"])
        let scriptChildRelatedRecords = try XCTUnwrap(scriptChild["relatedRecords"] as? [[String: Any]])
        XCTAssertFalse(scriptChildRelatedRecords.contains { $0["recordID"] as? String == "resources:files/msgdata/msg/0001.bin" })
        XCTAssertFalse(scriptChildRelatedRecords.contains { $0["recordID"] as? String == "resources:files/fielddata" })

        let resourceIndex = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resource-index", root.path, "--json"])
        )
        let items = try XCTUnwrap(resourceIndex["items"] as? [[String: Any]])
        let encounterResourceItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data encounters" && $0["path"] as? String == "data/encounters/route_1.txt" })
        let encounterResourceFacts = try XCTUnwrap(encounterResourceItem["facts"] as? [[String: Any]])
        XCTAssertTrue(encounterResourceFacts.contains { $0["label"] as? String == "Related Rows" && $0["value"] as? String == expectedRelatedRows })
        XCTAssertTrue(encounterResourceFacts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == "items, maps, moves, resources, scripts, species, text, trainers" })

        let messageResourceItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == "files/msgdata/msg/0001.bin" })
        let messageResourceFacts = try XCTUnwrap(messageResourceItem["facts"] as? [[String: Any]])
        XCTAssertTrue(messageResourceFacts.contains { $0["label"] as? String == "Related Rows" && $0["value"] as? String == expectedRelatedRows })
        XCTAssertTrue(messageResourceFacts.contains { $0["label"] as? String == "Gen V Message Decoded Preview" && $0["value"] as? String == "noDecodedPreview" })

        let fielddataResourceItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == "files/fielddata" })
        let fielddataResourceFacts = try XCTUnwrap(fielddataResourceItem["facts"] as? [[String: Any]])
        XCTAssertTrue(fielddataResourceFacts.contains { $0["label"] as? String == "Related Rows" && $0["value"] as? String == expectedRelatedRows })
        XCTAssertTrue(fielddataResourceFacts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == allGenVContextDomains })

        let pokemonRootResourceItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data species" && $0["path"] as? String == "data/pokemon" })
        let pokemonRootResourceFacts = try XCTUnwrap(pokemonRootResourceItem["facts"] as? [[String: Any]])
        XCTAssertTrue(pokemonRootResourceFacts.contains { $0["label"] as? String == "Related Rows" && $0["value"] as? String == expectedRelatedRows })
        XCTAssertTrue(pokemonRootResourceFacts.contains { $0["label"] as? String == "Related Domains" && $0["value"] as? String == allGenVContextDomains })
    }

    func testNDSDataCatalogCommandEmitsPokeBlackMessageBankInventoryJSON() throws {
        let root = try makeTestBlackDecompRoot()

        let catalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", root.path, "--json"])
        )

        let records = try XCTUnwrap(catalog["records"] as? [[String: Any]])
        let messageBankRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/msgdata" })
        XCTAssertEqual(messageBankRoot["id"] as? String, "text:files/msgdata")
        XCTAssertEqual(messageBankRoot["domain"] as? String, "text")
        XCTAssertEqual(messageBankRoot["format"] as? String, "directory")
        XCTAssertEqual(messageBankRoot["recordCount"] as? Int, 6)
        XCTAssertNil(messageBankRoot["textBankPreview"])
        let messageBankRootFacts = try XCTUnwrap(messageBankRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(messageBankRootFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "messageBankInventory" })
        XCTAssertTrue(messageBankRootFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(messageBankRootFacts.contains { $0["label"] as? String == "Gen V Reference Posture" && $0["value"] as? String == "cleanRoomReferenceOnly" })
        XCTAssertTrue(messageBankRootFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("source inventory stays preview-only") == true })
        XCTAssertTrue(messageBankRootFacts.contains { $0["label"] as? String == "Gen V Message Candidate Count" && $0["value"] as? String == "6" })
        XCTAssertTrue(messageBankRootFacts.contains { $0["label"] as? String == "Gen V Message Candidate Extensions" && $0["value"] as? String == "bin, dat, gmm, msg, str, txt" })
        XCTAssertTrue(messageBankRootFacts.contains { $0["label"] as? String == "Gen V Message Candidate Basis" && $0["value"] as? String == "pathExtensionOnly" })
        XCTAssertTrue(messageBankRootFacts.contains { $0["label"] as? String == "Gen V Message Candidate Posture" && $0["value"] as? String == "previewOnlyFilenameFacts" })
        XCTAssertFalse(messageBankRootFacts.contains { $0["label"] as? String == "Migration Status" })
        XCTAssertFalse(messageBankRootFacts.contains { $0["label"] as? String == "Text Bank Preview" })
        let messageBankRootReadiness = try XCTUnwrap(messageBankRoot["readiness"] as? [String: Any])
        XCTAssertEqual(messageBankRootReadiness["status"] as? String, "partial")
        XCTAssertTrue((messageBankRootReadiness["detail"] as? String)?.contains("message-bank inventory") == true)

        let messageBankChild = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/msgdata/story/message_bank.txt" })
        XCTAssertEqual(messageBankChild["domain"] as? String, "resources")
        XCTAssertNil(messageBankChild["textBankPreview"])
        let childFacts = try XCTUnwrap(messageBankChild["facts"] as? [[String: Any]])
        XCTAssertTrue(childFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "messageBankMetadata" })
        XCTAssertTrue(childFacts.contains { $0["label"] as? String == "Gen V Message Candidate Kind" && $0["value"] as? String == "sourceTextCandidate" })
        XCTAssertTrue(childFacts.contains { $0["label"] as? String == "Gen V Message Candidate Basis" && $0["value"] as? String == "pathExtensionOnly" })
        XCTAssertTrue(childFacts.contains { $0["label"] as? String == "Gen V Message Candidate Posture" && $0["value"] as? String == "previewOnlyFilenameFacts" })
        XCTAssertTrue(childFacts.contains { $0["label"] as? String == "Gen V Message Decoded Preview" && $0["value"] as? String == "noDecodedPreview" })
        XCTAssertTrue(childFacts.contains { $0["label"] as? String == "Gen V Message Candidate Bytes" && $0["value"] as? String == "14" })
        XCTAssertTrue(childFacts.contains { $0["label"] as? String == "Gen V Message Candidate Lines" && $0["value"] as? String == "1" })
        XCTAssertFalse(childFacts.contains { $0["label"] as? String == "Gen V Message Numeric Bank Hint" })
        XCTAssertFalse(childFacts.contains { $0["label"] as? String == "Text Bank Preview" })
        XCTAssertFalse(childFacts.contains { $0["label"] as? String == "Migration Status" })

        let binaryMessageBankChild = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/msgdata/msg/0001.bin" })
        XCTAssertNil(binaryMessageBankChild["textBankPreview"])
        let binaryChildFacts = try XCTUnwrap(binaryMessageBankChild["facts"] as? [[String: Any]])
        XCTAssertTrue(binaryChildFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "messageBankMetadata" })
        XCTAssertTrue(binaryChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Kind" && $0["value"] as? String == "numberedBinaryBankCandidate" })
        XCTAssertTrue(binaryChildFacts.contains { $0["label"] as? String == "Gen V Message Decoded Preview" && $0["value"] as? String == "noDecodedPreview" })
        XCTAssertTrue(binaryChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Bytes" && $0["value"] as? String == "4" })
        XCTAssertTrue(binaryChildFacts.contains { $0["label"] as? String == "Gen V Message Numeric Bank Hint" && $0["value"] as? String == "0001" })
        XCTAssertFalse(binaryChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Lines" })
        XCTAssertFalse(binaryChildFacts.contains { $0["label"] as? String == "Text Bank Preview" })
        XCTAssertFalse(binaryChildFacts.contains { $0["label"] as? String == "Migration Status" })

        let gmmMessageBankChild = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/msgdata/battle/trainer_messages.gmm" })
        XCTAssertNil(gmmMessageBankChild["textBankPreview"])
        let gmmChildFacts = try XCTUnwrap(gmmMessageBankChild["facts"] as? [[String: Any]])
        XCTAssertTrue(gmmChildFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "messageBankMetadata" })
        XCTAssertTrue(gmmChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Kind" && $0["value"] as? String == "sourceTextCandidate" })
        XCTAssertTrue(gmmChildFacts.contains { $0["label"] as? String == "Gen V Message Decoded Preview" && $0["value"] as? String == "noDecodedPreview" })
        XCTAssertTrue(gmmChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Bytes" && $0["value"] as? String == "26" })
        XCTAssertTrue(gmmChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Lines" && $0["value"] as? String == "1" })
        XCTAssertFalse(gmmChildFacts.contains { $0["label"] as? String == "Text Bank Preview" })
        XCTAssertFalse(gmmChildFacts.contains { $0["label"] as? String == "Migration Status" })

        let strMessageBankChild = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/msgdata/system/help.str" })
        XCTAssertNil(strMessageBankChild["textBankPreview"])
        let strChildFacts = try XCTUnwrap(strMessageBankChild["facts"] as? [[String: Any]])
        XCTAssertTrue(strChildFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "messageBankMetadata" })
        XCTAssertTrue(strChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Kind" && $0["value"] as? String == "sourceTextCandidate" })
        XCTAssertTrue(strChildFacts.contains { $0["label"] as? String == "Gen V Message Decoded Preview" && $0["value"] as? String == "noDecodedPreview" })
        XCTAssertTrue(strChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Bytes" && $0["value"] as? String == "11" })
        XCTAssertTrue(strChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Lines" && $0["value"] as? String == "2" })
        XCTAssertFalse(strChildFacts.contains { $0["label"] as? String == "Gen V Message Numeric Bank Hint" })
        XCTAssertFalse(strChildFacts.contains { $0["label"] as? String == "Text Bank Preview" })
        XCTAssertFalse(strChildFacts.contains { $0["label"] as? String == "Migration Status" })

        let msgMessageBankChild = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/msgdata/msg/msg_0099.msg" })
        XCTAssertNil(msgMessageBankChild["textBankPreview"])
        let msgChildFacts = try XCTUnwrap(msgMessageBankChild["facts"] as? [[String: Any]])
        XCTAssertTrue(msgChildFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "messageBankMetadata" })
        XCTAssertTrue(msgChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Kind" && $0["value"] as? String == "numberedBinaryBankCandidate" })
        XCTAssertTrue(msgChildFacts.contains { $0["label"] as? String == "Gen V Message Decoded Preview" && $0["value"] as? String == "noDecodedPreview" })
        XCTAssertTrue(msgChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Bytes" && $0["value"] as? String == "3" })
        XCTAssertTrue(msgChildFacts.contains { $0["label"] as? String == "Gen V Message Numeric Bank Hint" && $0["value"] as? String == "0099" })
        XCTAssertFalse(msgChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Lines" })
        XCTAssertFalse(msgChildFacts.contains { $0["label"] as? String == "Text Bank Preview" })
        XCTAssertFalse(msgChildFacts.contains { $0["label"] as? String == "Migration Status" })

        let datMessageBankChild = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/msgdata/system/msg_0002.dat" })
        XCTAssertNil(datMessageBankChild["textBankPreview"])
        let datChildFacts = try XCTUnwrap(datMessageBankChild["facts"] as? [[String: Any]])
        XCTAssertTrue(datChildFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "messageBankMetadata" })
        XCTAssertTrue(datChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Kind" && $0["value"] as? String == "numberedBinaryBankCandidate" })
        XCTAssertTrue(datChildFacts.contains { $0["label"] as? String == "Gen V Message Decoded Preview" && $0["value"] as? String == "noDecodedPreview" })
        XCTAssertTrue(datChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Bytes" && $0["value"] as? String == "4" })
        XCTAssertTrue(datChildFacts.contains { $0["label"] as? String == "Gen V Message Numeric Bank Hint" && $0["value"] as? String == "0002" })
        XCTAssertFalse(datChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Lines" })
        XCTAssertFalse(datChildFacts.contains { $0["label"] as? String == "Text Bank Preview" })
        XCTAssertFalse(datChildFacts.contains { $0["label"] as? String == "Migration Status" })

        let resourceIndex = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resource-index", root.path, "--json"])
        )
        let items = try XCTUnwrap(resourceIndex["items"] as? [[String: Any]])
        let messageBankResourceItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data text" && $0["path"] as? String == "files/msgdata" })
        XCTAssertEqual(messageBankResourceItem["kind"] as? String, "directory")
        let resourceFacts = try XCTUnwrap(messageBankResourceItem["facts"] as? [[String: Any]])
        XCTAssertTrue(resourceFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "messageBankInventory" })
        XCTAssertTrue(resourceFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(resourceFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("source inventory stays preview-only") == true })
        XCTAssertTrue(resourceFacts.contains { $0["label"] as? String == "Gen V Message Candidate Count" && $0["value"] as? String == "6" })
        XCTAssertTrue(resourceFacts.contains { $0["label"] as? String == "Gen V Message Candidate Extensions" && $0["value"] as? String == "bin, dat, gmm, msg, str, txt" })
        XCTAssertFalse(resourceFacts.contains { $0["label"] as? String == "Migration Status" })
        XCTAssertFalse(resourceFacts.contains { $0["label"] as? String == "Text Bank Preview" })
        let messageBankResourceChild = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == "files/msgdata/msg/0001.bin" })
        let resourceChildFacts = try XCTUnwrap(messageBankResourceChild["facts"] as? [[String: Any]])
        XCTAssertTrue(resourceChildFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "messageBankMetadata" })
        XCTAssertTrue(resourceChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Kind" && $0["value"] as? String == "numberedBinaryBankCandidate" })
        XCTAssertTrue(resourceChildFacts.contains { $0["label"] as? String == "Gen V Message Decoded Preview" && $0["value"] as? String == "noDecodedPreview" })
        XCTAssertTrue(resourceChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Bytes" && $0["value"] as? String == "4" })
        XCTAssertTrue(resourceChildFacts.contains { $0["label"] as? String == "Gen V Message Numeric Bank Hint" && $0["value"] as? String == "0001" })
        XCTAssertFalse(resourceChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Lines" })
        XCTAssertFalse(resourceChildFacts.contains { $0["label"] as? String == "Migration Status" })
        XCTAssertFalse(resourceChildFacts.contains { $0["label"] as? String == "Text Bank Preview" })

        let textMessageBankResourceChild = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == "files/msgdata/system/help.str" })
        let textResourceChildFacts = try XCTUnwrap(textMessageBankResourceChild["facts"] as? [[String: Any]])
        XCTAssertTrue(textResourceChildFacts.contains { $0["label"] as? String == "Gen V Message Decoded Preview" && $0["value"] as? String == "noDecodedPreview" })
        XCTAssertTrue(textResourceChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Bytes" && $0["value"] as? String == "11" })
        XCTAssertTrue(textResourceChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Lines" && $0["value"] as? String == "2" })
        XCTAssertFalse(textResourceChildFacts.contains { $0["label"] as? String == "Gen V Message Numeric Bank Hint" })
        XCTAssertFalse(textResourceChildFacts.contains { $0["label"] as? String == "Migration Status" })
        XCTAssertFalse(textResourceChildFacts.contains { $0["label"] as? String == "Text Bank Preview" })

        let msgMessageBankResourceChild = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == "files/msgdata/msg/msg_0099.msg" })
        let msgResourceChildFacts = try XCTUnwrap(msgMessageBankResourceChild["facts"] as? [[String: Any]])
        XCTAssertTrue(msgResourceChildFacts.contains { $0["label"] as? String == "Gen V Message Decoded Preview" && $0["value"] as? String == "noDecodedPreview" })
        XCTAssertTrue(msgResourceChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Bytes" && $0["value"] as? String == "3" })
        XCTAssertTrue(msgResourceChildFacts.contains { $0["label"] as? String == "Gen V Message Numeric Bank Hint" && $0["value"] as? String == "0099" })
        XCTAssertFalse(msgResourceChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Lines" })
        XCTAssertFalse(msgResourceChildFacts.contains { $0["label"] as? String == "Migration Status" })
        XCTAssertFalse(msgResourceChildFacts.contains { $0["label"] as? String == "Text Bank Preview" })

        let datMessageBankResourceChild = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == "files/msgdata/system/msg_0002.dat" })
        let datResourceChildFacts = try XCTUnwrap(datMessageBankResourceChild["facts"] as? [[String: Any]])
        XCTAssertTrue(datResourceChildFacts.contains { $0["label"] as? String == "Gen V Message Decoded Preview" && $0["value"] as? String == "noDecodedPreview" })
        XCTAssertTrue(datResourceChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Bytes" && $0["value"] as? String == "4" })
        XCTAssertTrue(datResourceChildFacts.contains { $0["label"] as? String == "Gen V Message Numeric Bank Hint" && $0["value"] as? String == "0002" })
        XCTAssertFalse(datResourceChildFacts.contains { $0["label"] as? String == "Gen V Message Candidate Lines" })
        XCTAssertFalse(datResourceChildFacts.contains { $0["label"] as? String == "Migration Status" })
        XCTAssertFalse(datResourceChildFacts.contains { $0["label"] as? String == "Text Bank Preview" })
    }

    func testNDSDataCatalogCommandEmitsPokeBlackOverlayAndDisassemblyConfigInventoryJSON() throws {
        let root = try makeTestBlackDecompRoot()

        let catalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", root.path, "--json"])
        )

        let records = try XCTUnwrap(catalog["records"] as? [[String: Any]])
        let overlayRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "overlays" })
        XCTAssertEqual(overlayRoot["id"] as? String, "scripts:overlays")
        XCTAssertEqual(overlayRoot["domain"] as? String, "scripts")
        XCTAssertEqual(overlayRoot["format"] as? String, "directory")
        XCTAssertEqual(overlayRoot["recordCount"] as? Int, 2)
        XCTAssertEqual(overlayRoot["byteCount"] as? Int, 10)
        let overlayRootFacts = try XCTUnwrap(overlayRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(overlayRootFacts.contains { $0["label"] as? String == "Gen V Overlay Members" && $0["value"] as? String == "2" })
        XCTAssertTrue(overlayRootFacts.contains { $0["label"] as? String == "Gen V Overlay Bytes" && $0["value"] as? String == "10" })
        XCTAssertTrue(overlayRootFacts.contains { $0["label"] as? String == "Gen V Overlay Sample Paths" && ($0["value"] as? String)?.contains("overlays/overlay_93/source.s") == true })
        XCTAssertTrue(overlayRootFacts.contains { $0["label"] as? String == "Gen V Overlay Sample Paths" && ($0["value"] as? String)?.contains("overlays/overlay_94/source.s") == true })
        XCTAssertTrue(overlayRootFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "overlayInventory" })
        XCTAssertTrue(overlayRootFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(overlayRootFacts.contains { $0["label"] as? String == "Gen V Reference Posture" && $0["value"] as? String == "cleanRoomReferenceOnly" })
        XCTAssertTrue(overlayRootFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("source inventory stays preview-only") == true })
        XCTAssertFalse(overlayRootFacts.contains { $0["label"] as? String == "Migration Status" })
        let overlayRootReadiness = try XCTUnwrap(overlayRoot["readiness"] as? [String: Any])
        XCTAssertEqual(overlayRootReadiness["status"] as? String, "partial")
        XCTAssertTrue((overlayRootReadiness["detail"] as? String)?.contains("overlays root") == true)

        let overlayChild = try XCTUnwrap(records.first { $0["relativePath"] as? String == "overlays/overlay_93/source.s" })
        let overlayChildFacts = try XCTUnwrap(overlayChild["facts"] as? [[String: Any]])
        XCTAssertTrue(overlayChildFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "overlayRouting" })

        let configRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "ndsdisasm_config" })
        XCTAssertEqual(configRoot["id"] as? String, "resources:ndsdisasm_config")
        XCTAssertEqual(configRoot["domain"] as? String, "resources")
        XCTAssertEqual(configRoot["format"] as? String, "directory")
        XCTAssertEqual(configRoot["recordCount"] as? Int, 2)
        XCTAssertEqual(configRoot["byteCount"] as? Int, 10)
        let configRootFacts = try XCTUnwrap(configRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(configRootFacts.contains { $0["label"] as? String == "Gen V Disassembly Config Members" && $0["value"] as? String == "2" })
        XCTAssertTrue(configRootFacts.contains { $0["label"] as? String == "Gen V Disassembly Config Bytes" && $0["value"] as? String == "10" })
        XCTAssertTrue(configRootFacts.contains { $0["label"] as? String == "Gen V Disassembly Config Sample Paths" && ($0["value"] as? String)?.contains("ndsdisasm_config/ARM9.cfg") == true })
        XCTAssertTrue(configRootFacts.contains { $0["label"] as? String == "Gen V Disassembly Config Sample Paths" && ($0["value"] as? String)?.contains("ndsdisasm_config/overlays/overlay_94.cfg") == true })
        XCTAssertTrue(configRootFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "disassemblyConfigInventory" })
        XCTAssertTrue(configRootFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(configRootFacts.contains { $0["label"] as? String == "Gen V Reference Posture" && $0["value"] as? String == "cleanRoomReferenceOnly" })
        XCTAssertTrue(configRootFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("source inventory stays preview-only") == true })
        XCTAssertFalse(configRootFacts.contains { $0["label"] as? String == "Migration Status" })
        let configRootReadiness = try XCTUnwrap(configRoot["readiness"] as? [String: Any])
        XCTAssertEqual(configRootReadiness["status"] as? String, "partial")
        XCTAssertTrue((configRootReadiness["detail"] as? String)?.contains("ndsdisasm_config root") == true)

        let configChild = try XCTUnwrap(records.first { $0["relativePath"] as? String == "ndsdisasm_config/ARM9.cfg" })
        let configChildFacts = try XCTUnwrap(configChild["facts"] as? [[String: Any]])
        XCTAssertTrue(configChildFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "disassemblyConfig" })

        let resourceIndex = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resource-index", root.path, "--json"])
        )
        let items = try XCTUnwrap(resourceIndex["items"] as? [[String: Any]])
        let overlayResourceItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data scripts" && $0["path"] as? String == "overlays" })
        XCTAssertEqual(overlayResourceItem["kind"] as? String, "directory")
        XCTAssertEqual(overlayResourceItem["size"] as? Int, 10)
        let overlayResourceFacts = try XCTUnwrap(overlayResourceItem["facts"] as? [[String: Any]])
        XCTAssertTrue(overlayResourceFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "overlayInventory" })
        XCTAssertTrue(overlayResourceFacts.contains { $0["label"] as? String == "Gen V Overlay Members" && $0["value"] as? String == "2" })
        XCTAssertTrue(overlayResourceFacts.contains { $0["label"] as? String == "Gen V Overlay Bytes" && $0["value"] as? String == "10" })
        XCTAssertTrue(overlayResourceFacts.contains { $0["label"] as? String == "Gen V Overlay Sample Paths" && ($0["value"] as? String)?.contains("overlays/overlay_93/source.s") == true })
        XCTAssertTrue(overlayResourceFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(overlayResourceFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("source inventory stays preview-only") == true })
        XCTAssertFalse(overlayResourceFacts.contains { $0["label"] as? String == "Migration Status" })

        let configResourceItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == "ndsdisasm_config" })
        XCTAssertEqual(configResourceItem["kind"] as? String, "directory")
        XCTAssertEqual(configResourceItem["size"] as? Int, 10)
        let configResourceFacts = try XCTUnwrap(configResourceItem["facts"] as? [[String: Any]])
        XCTAssertTrue(configResourceFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "disassemblyConfigInventory" })
        XCTAssertTrue(configResourceFacts.contains { $0["label"] as? String == "Gen V Disassembly Config Members" && $0["value"] as? String == "2" })
        XCTAssertTrue(configResourceFacts.contains { $0["label"] as? String == "Gen V Disassembly Config Bytes" && $0["value"] as? String == "10" })
        XCTAssertTrue(configResourceFacts.contains { $0["label"] as? String == "Gen V Disassembly Config Sample Paths" && ($0["value"] as? String)?.contains("ndsdisasm_config/ARM9.cfg") == true })
        XCTAssertTrue(configResourceFacts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(configResourceFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("source inventory stays preview-only") == true })
        XCTAssertFalse(configResourceFacts.contains { $0["label"] as? String == "Migration Status" })
    }

    func testNDSDataCatalogCommandEmitsPokeBlackSoundAndContainerFactsJSON() throws {
        let root = try makeTestBlackDecompRoot()
        try write(Data("SDAT".utf8) + Data(repeating: 0, count: 12), to: root.appendingPathComponent("files/sound/bgm/main.sdat"))
        try write(makeTestNARC(), to: root.appendingPathComponent("files/sound/bgm/sound_bank.narc"))
        try write(makeTestNARC(), to: root.appendingPathComponent("files/system/container.narc"))
        try write(makeTestNARC(), to: root.appendingPathComponent("files/a/0/0/0/child.narc"))

        let catalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", root.path, "--json"])
        )

        let records = try XCTUnwrap(catalog["records"] as? [[String: Any]])
        let nestedSDAT = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/sound/bgm/main.sdat" && $0["domain"] as? String == "audio" })
        let nestedSDATFacts = try XCTUnwrap(nestedSDAT["facts"] as? [[String: Any]])
        XCTAssertTrue(nestedSDATFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "soundArchiveMetadata" })
        XCTAssertTrue(nestedSDATFacts.contains { $0["label"] as? String == "Audio Preview" && $0["value"] as? String == "ready" })
        XCTAssertTrue(nestedSDATFacts.contains { $0["label"] as? String == "Audio Format" && $0["value"] as? String == "nitroSoundArchive" })
        let nestedSDATReadiness = try XCTUnwrap(nestedSDAT["readiness"] as? [String: Any])
        XCTAssertEqual(nestedSDATReadiness["status"] as? String, "partial")
        let nestedSDATBlockedActions = try XCTUnwrap(nestedSDATReadiness["blockedActions"] as? [String])
        XCTAssertTrue(nestedSDATBlockedActions.contains("raw source writer"))
        XCTAssertTrue(nestedSDATBlockedActions.contains("NARC pack"))

        let soundNARC = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/sound/bgm/sound_bank.narc" && $0["domain"] as? String == "audio" })
        XCTAssertEqual(soundNARC["role"] as? String, "binaryContainer")
        let soundNARCFacts = try XCTUnwrap(soundNARC["facts"] as? [[String: Any]])
        XCTAssertTrue(soundNARCFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "soundContainerRoute" })
        XCTAssertTrue(soundNARCFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("source inventory stays preview-only") == true })
        let soundNARCReadiness = try XCTUnwrap(soundNARC["readiness"] as? [String: Any])
        XCTAssertEqual(soundNARCReadiness["status"] as? String, "blocked")

        let boundedContainer = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/system/container.narc" && $0["domain"] as? String == "resources" })
        let boundedFacts = try XCTUnwrap(boundedContainer["facts"] as? [[String: Any]])
        XCTAssertTrue(boundedFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "boundedContainerSummary" })
        XCTAssertTrue(boundedFacts.contains { $0["label"] as? String == "Members" && $0["value"] as? String == "2" })
        let boundedSummary = try XCTUnwrap(boundedContainer["containerSummary"] as? [String: Any])
        XCTAssertEqual(boundedSummary["memberCount"] as? Int, 2)

        let archiveGroupRoot = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/a" })
        let archiveGroupRootFacts = try XCTUnwrap(archiveGroupRoot["facts"] as? [[String: Any]])
        XCTAssertTrue(archiveGroupRootFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "nitroArchiveGroupInventory" })
        let archiveGroupChild = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/a/0/0/0/resource.bin" })
        let archiveGroupChildFacts = try XCTUnwrap(archiveGroupChild["facts"] as? [[String: Any]])
        XCTAssertTrue(archiveGroupChildFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "nitroArchiveGroup" })
        let archiveGroupNARCChild = try XCTUnwrap(records.first { $0["relativePath"] as? String == "files/a/0/0/0/child.narc" })
        let archiveGroupNARCChildFacts = try XCTUnwrap(archiveGroupNARCChild["facts"] as? [[String: Any]])
        XCTAssertTrue(archiveGroupNARCChildFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "nitroArchiveGroup" })

        let resourceIndex = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resource-index", root.path, "--json"])
        )
        let items = try XCTUnwrap(resourceIndex["items"] as? [[String: Any]])
        let audioItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data audio" && $0["path"] as? String == "files/sound/bgm/main.sdat" })
        let audioResourceFacts = try XCTUnwrap(audioItem["facts"] as? [[String: Any]])
        XCTAssertTrue(audioResourceFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "soundArchiveMetadata" })
        let soundNARCItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data audio" && $0["path"] as? String == "files/sound/bgm/sound_bank.narc" })
        let soundNARCResourceFacts = try XCTUnwrap(soundNARCItem["facts"] as? [[String: Any]])
        XCTAssertTrue(soundNARCResourceFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "soundContainerRoute" })
        let boundedItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == "files/system/container.narc" })
        let boundedResourceFacts = try XCTUnwrap(boundedItem["facts"] as? [[String: Any]])
        XCTAssertTrue(boundedResourceFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "boundedContainerSummary" })
    }

    func testNDSDataCatalogCommandEmitsBlack2White2InventoryReadinessJSON() throws {
        let root = try makeTestBlackDecompRoot()
        try write("\n", to: root.appendingPathComponent("white.us/rom.sha1"))
        try write("not-a-sha1\n", to: root.appendingPathComponent("black2.us/rom.sha1"))
        try write("3333333333333333333333333333333333333333  pokewhite2.nds\n", to: root.appendingPathComponent("white2.us/rom.sha1"))
        try write("Black 2 source note\n", to: root.appendingPathComponent("black2.us/source_notes.txt"))

        let catalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", root.path, "--json"])
        )

        let records = try XCTUnwrap(catalog["records"] as? [[String: Any]])
        let makefile = try XCTUnwrap(records.first { $0["relativePath"] as? String == "Makefile" })
        let makefileFacts = try XCTUnwrap(makefile["facts"] as? [[String: Any]])
        XCTAssertTrue(makefileFacts.contains { $0["label"] as? String == "Gen V Variant Hash Presence" && $0["value"] as? String == "black.us/rom.sha1=present, white.us/rom.sha1=present, black2.us/rom.sha1=present, white2.us/rom.sha1=present" })
        let black = try XCTUnwrap(records.first { $0["relativePath"] as? String == "black.us/rom.sha1" })
        let blackFacts = try XCTUnwrap(black["facts"] as? [[String: Any]])
        XCTAssertTrue(blackFacts.contains { $0["label"] as? String == "Gen V SHA1 Text State" && $0["value"] as? String == "valid" })
        XCTAssertTrue(blackFacts.contains { $0["label"] as? String == "Gen V SHA1 Text Digest" && $0["value"] as? String == "ffffffffffffffffffffffffffffffffffffffff" })
        let white = try XCTUnwrap(records.first { $0["relativePath"] as? String == "white.us/rom.sha1" })
        let whiteFacts = try XCTUnwrap(white["facts"] as? [[String: Any]])
        XCTAssertTrue(whiteFacts.contains { $0["label"] as? String == "Gen V SHA1 Text State" && $0["value"] as? String == "empty" })
        XCTAssertFalse(whiteFacts.contains { $0["label"] as? String == "Gen V SHA1 Text Digest" })
        let black2 = try XCTUnwrap(records.first { $0["relativePath"] as? String == "black2.us/rom.sha1" })
        let black2Facts = try XCTUnwrap(black2["facts"] as? [[String: Any]])
        XCTAssertTrue(black2Facts.contains { $0["label"] as? String == "Gen V Readiness" && $0["value"] as? String == "previewOnly" })
        XCTAssertTrue(black2Facts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "checksumExpectation" })
        XCTAssertTrue(black2Facts.contains { $0["label"] as? String == "Gen V Family" && $0["value"] as? String == "black2White2" })
        XCTAssertTrue(black2Facts.contains { $0["label"] as? String == "Gen V Source Name" && $0["value"] as? String == "localBlack2White2SourceInventory" })
        XCTAssertTrue(black2Facts.contains { $0["label"] as? String == "Gen V Variant State" && $0["value"] as? String == "sourceMarkerPresent" })
        XCTAssertTrue(black2Facts.contains { $0["label"] as? String == "Gen V Blocked Actions" && ($0["value"] as? String)?.contains("mutation apply") == true })
        XCTAssertTrue(black2Facts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("build, playtest, and export actions are disabled") == true })
        XCTAssertTrue(black2Facts.contains { $0["label"] as? String == "Gen V SHA1 Text State" && $0["value"] as? String == "invalid" })
        XCTAssertFalse(black2Facts.contains { $0["label"] as? String == "Gen V SHA1 Text Digest" })
        let black2Readiness = try XCTUnwrap(black2["readiness"] as? [String: Any])
        XCTAssertEqual(black2Readiness["status"] as? String, "partial")
        let black2Diagnostics = try XCTUnwrap(black2["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(black2Diagnostics.contains { $0["code"] as? String == "NDS_GEN_V_READINESS_PREVIEW_ONLY" })
        XCTAssertTrue(black2Diagnostics.contains { $0["code"] as? String == "NDS_GEN_V_WRITE_BLOCKED" })

        let black2Marker = try XCTUnwrap(records.first { $0["relativePath"] as? String == "black2.us" })
        XCTAssertEqual(black2Marker["format"] as? String, "directory")
        XCTAssertEqual(black2Marker["recordCount"] as? Int, 2)
        let black2MarkerFacts = try XCTUnwrap(black2Marker["facts"] as? [[String: Any]])
        XCTAssertTrue(black2MarkerFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "variantSourceInventory" })
        XCTAssertTrue(black2MarkerFacts.contains { $0["label"] as? String == "Gen V Source Name" && $0["value"] as? String == "localBlack2White2SourceInventory" })
        XCTAssertFalse(black2MarkerFacts.contains { $0["label"] as? String == "Migration Status" })

        let black2Note = try XCTUnwrap(records.first { $0["relativePath"] as? String == "black2.us/source_notes.txt" })
        let black2NoteFacts = try XCTUnwrap(black2Note["facts"] as? [[String: Any]])
        XCTAssertTrue(black2NoteFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "sourceInventory" })
        XCTAssertFalse(records.contains { $0["relativePath"] as? String == "unavailable-titles/Pokemon - Black Version 2 (USA, Europe) (NDSi Enhanced).nds" })
        XCTAssertFalse(records.contains { $0["relativePath"] as? String == "unavailable-titles/Pokemon - White Version 2 (USA, Europe) (NDSi Enhanced).nds" })
        let white2 = try XCTUnwrap(records.first { $0["relativePath"] as? String == "white2.us/rom.sha1" })
        let white2Facts = try XCTUnwrap(white2["facts"] as? [[String: Any]])
        XCTAssertTrue(white2Facts.contains { $0["label"] as? String == "Gen V SHA1 Text State" && $0["value"] as? String == "valid" })
        XCTAssertTrue(white2Facts.contains { $0["label"] as? String == "Gen V SHA1 Text Digest" && $0["value"] as? String == "3333333333333333333333333333333333333333" })

        let resourceIndex = try decodeJSON(
            PokemonHackCLI.run(arguments: ["resource-index", root.path, "--json"])
        )
        let items = try XCTUnwrap(resourceIndex["items"] as? [[String: Any]])
        let black2ResourceItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == "black2.us/source_notes.txt" })
        let resourceFacts = try XCTUnwrap(black2ResourceItem["facts"] as? [[String: Any]])
        XCTAssertTrue(resourceFacts.contains { $0["label"] as? String == "Gen V Source Role" && $0["value"] as? String == "sourceInventory" })
        XCTAssertTrue(resourceFacts.contains { $0["label"] as? String == "Gen V Blocked Actions" && ($0["value"] as? String)?.contains("binary write") == true })
        XCTAssertTrue(resourceFacts.contains { $0["label"] as? String == "Gen V Action State" && ($0["value"] as? String)?.contains("source inventory stays preview-only") == true })
        let white2ResourceItem = try XCTUnwrap(items.first { $0["category"] as? String == "NDS Data resources" && $0["path"] as? String == "white2.us/rom.sha1" })
        let white2ResourceFacts = try XCTUnwrap(white2ResourceItem["facts"] as? [[String: Any]])
        XCTAssertTrue(white2ResourceFacts.contains { $0["label"] as? String == "Gen V SHA1 Text State" && $0["value"] as? String == "valid" })
        XCTAssertTrue(white2ResourceFacts.contains { $0["label"] as? String == "Gen V SHA1 Text Digest" && $0["value"] as? String == "3333333333333333333333333333333333333333" })
    }

    func testNDSDataEditCommandsPlanApplyAndBlockReadOnlyRows() throws {
        let root = try makeTestNDSDecompRoot()
        let draftFile = try makeTemporaryDirectory().appendingPathComponent("draft.json")
        try "{\"base_hp\":26}\n".write(to: draftFile, atomically: true, encoding: .utf8)

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-edit-plan",
                root.path,
                "species:res/pokemon/abra/data.json",
                "--draft-file",
                draftFile.path,
                "--json"
            ])
        )
        XCTAssertEqual(plan["recordID"] as? String, "species:res/pokemon/abra/data.json")
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertNil(changes[0]["newData"])
        XCTAssertEqual(changes[0]["newByteCount"] as? Int, 15)
        XCTAssertTrue((changes[0]["textPreview"] as? String)?.contains("base_hp") == true)
        let planData = try JSONSerialization.data(withJSONObject: plan)
        XCTAssertFalse(String(data: planData, encoding: .utf8)?.contains("\"newData\"") == true)

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-edit-apply",
                root.path,
                "species:res/pokemon/abra/data.json",
                "--draft-file",
                draftFile.path,
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("res/pokemon/abra/data.json"), encoding: .utf8),
            "{\"base_hp\":26}\n"
        )

        let rom = try makeTestNDSROM()
        let blockedROM = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-edit-plan",
                rom.path,
                "resources:sub/child.narc",
                "--draft-file",
                draftFile.path,
                "--json"
            ])
        )
        let romDiagnostics = try XCTUnwrap(blockedROM["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(romDiagnostics.contains { $0["code"] as? String == "NDS_DATA_EDIT_BINARY_ROM_BLOCKED" })

        let blockedNARC = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-edit-plan",
                root.path,
                "personal:res/prebuilt/poketool/personal/personal.narc",
                "--draft-file",
                draftFile.path,
                "--json"
            ])
        )
        let narcDiagnostics = try XCTUnwrap(blockedNARC["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(narcDiagnostics.contains { $0["code"] as? String == "NDS_DATA_EDIT_CONTAINER_BLOCKED" })
    }

    func testNDSDataSemanticCommandsPlanAndApplyJSONFields() throws {
        let root = try makeTestNDSDecompRoot()

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "species:res/pokemon/abra/data.json",
                "--set",
                "base_hp=31",
                "--set",
                "evolutions.0.parameter=22",
                "--json"
            ])
        )

        XCTAssertNil(plan["textDraft"])
        XCTAssertNil(plan["editPlan"])
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(requestedFieldKeys, ["base_hp", "evolutions.0.parameter"])
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, "res/pokemon/abra/data.json")
        XCTAssertNotNil(changes.first?["originalByteCount"])
        XCTAssertNotNil(changes.first?["newByteCount"])
        XCTAssertNil(changes.first?["textPreview"])
        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            "species:res/pokemon/abra/data.json",
            "--set",
            "base_hp=31",
            "--set",
            "evolutions.0.parameter=22",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("\"base_hp\":31"))
        XCTAssertFalse(redactedPlan.contains("EVO_LEVEL\",22"))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "species:res/pokemon/abra/data.json",
                "--set",
                "base_hp=31",
                "--set",
                "evolutions.0.target=SPECIES_ALAKAZAM",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updatedSpecies = try String(contentsOf: root.appendingPathComponent("res/pokemon/abra/data.json"), encoding: .utf8)
        XCTAssertTrue(updatedSpecies.contains("\"base_hp\":31"))
        XCTAssertTrue(updatedSpecies.contains("[\"EVO_LEVEL\",16,\"SPECIES_ALAKAZAM\"]"))

        let duplicateApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "species:res/pokemon/abra/data.json",
                "--set",
                "evolutions.0.parameter=22",
                "--set",
                "evolutions.0.parameter=24",
                "--json"
            ])
        )
        let duplicateChanges = try XCTUnwrap(duplicateApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(duplicateChanges.count, 0)
        let duplicateDiagnostics = try XCTUnwrap(duplicateApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(duplicateDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FIELD_DUPLICATE" })
        XCTAssertTrue(
            try String(contentsOf: root.appendingPathComponent("res/pokemon/abra/data.json"), encoding: .utf8)
                .contains("[\"EVO_LEVEL\",16,\"SPECIES_ALAKAZAM\"]")
        )

        let itemPlan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "items:res/items/potion.json",
                "--set",
                "price=250",
                "--set",
                "field_use=false",
                "--json"
            ])
        )
        let itemRequestedFieldKeys = try XCTUnwrap(itemPlan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(itemRequestedFieldKeys, ["price", "field_use"])
        let itemChanges = try XCTUnwrap(itemPlan["changes"] as? [[String: Any]])
        XCTAssertEqual(itemChanges.count, 1)
        XCTAssertNil(itemChanges.first?["textPreview"])

        let itemApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "items:res/items/potion.json",
                "--set",
                "price=250",
                "--json"
            ])
        )
        let itemAppliedChanges = try XCTUnwrap(itemApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(itemAppliedChanges.count, 1)
        XCTAssertTrue(
            try String(contentsOf: root.appendingPathComponent("res/items/potion.json"), encoding: .utf8)
                .contains("\"price\": 250")
        )

        let trainerPlan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "trainers:res/trainers/data/youngster.json",
                "--set",
                "double_battle=true",
                "--json"
            ])
        )
        let trainerRequestedFieldKeys = try XCTUnwrap(trainerPlan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(trainerRequestedFieldKeys, ["double_battle"])
        let trainerChanges = try XCTUnwrap(trainerPlan["changes"] as? [[String: Any]])
        XCTAssertEqual(trainerChanges.count, 1)
        XCTAssertNil(trainerChanges.first?["textPreview"])

        let trainerApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "trainers:res/trainers/data/youngster.json",
                "--set",
                "double_battle=true",
                "--json"
            ])
        )
        let trainerAppliedChanges = try XCTUnwrap(trainerApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(trainerAppliedChanges.count, 1)
        XCTAssertTrue(
            try String(contentsOf: root.appendingPathComponent("res/trainers/data/youngster.json"), encoding: .utf8)
                .contains("\"double_battle\": true")
        )

        let blockedTrainerResourcePath = "res/trainers/resources/youngster.json"
        try write("{\"cell_animation\":1}\n", to: root.appendingPathComponent(blockedTrainerResourcePath))
        let blockedResourceApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "trainers:\(blockedTrainerResourcePath)",
                "--set",
                "cell_animation=2",
                "--json"
            ])
        )
        let blockedAppliedChanges = try XCTUnwrap(blockedResourceApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedAppliedChanges.count, 0)
        let blockedDiagnostics = try XCTUnwrap(blockedResourceApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_TRAINER_PATH_BLOCKED" })
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(blockedTrainerResourcePath), encoding: .utf8),
            "{\"cell_animation\":1}\n"
        )

        let blockedCSVApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "items:res/items/items.csv",
                "--set",
                "name=SUPER_POTION",
                "--json"
            ])
        )
        let blockedCSVChanges = try XCTUnwrap(blockedCSVApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedCSVChanges.count, 0)
        let blockedCSVDiagnostics = try XCTUnwrap(blockedCSVApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedCSVDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_ITEM_PATH_BLOCKED" })
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("res/items/items.csv"), encoding: .utf8),
            "id,name\n1,POTION\n"
        )

        let heartGoldRoot = try makeTestHeartGoldDecompRoot()
        let heartGoldPlan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                heartGoldRoot.path,
                "personal:files/poketool/personal/personal.json",
                "--set",
                "species=CYNDAQUIL",
                "--json"
            ])
        )
        let heartGoldRequestedFieldKeys = try XCTUnwrap(heartGoldPlan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(heartGoldRequestedFieldKeys, ["species"])
        let heartGoldChanges = try XCTUnwrap(heartGoldPlan["changes"] as? [[String: Any]])
        XCTAssertEqual(heartGoldChanges.count, 1)
        XCTAssertEqual(heartGoldChanges.first?["path"] as? String, "files/poketool/personal/personal.json")
        XCTAssertNil(heartGoldChanges.first?["textPreview"])

        let heartGoldApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                heartGoldRoot.path,
                "personal:files/poketool/personal/personal.json",
                "--set",
                "species=CYNDAQUIL",
                "--json"
            ])
        )
        let heartGoldAppliedChanges = try XCTUnwrap(heartGoldApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(heartGoldAppliedChanges.count, 1)
        XCTAssertTrue(
            try String(contentsOf: heartGoldRoot.appendingPathComponent("files/poketool/personal/personal.json"), encoding: .utf8)
                .contains("\"species\":\"CYNDAQUIL\"")
        )

        let heartGoldTrainerPlan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                heartGoldRoot.path,
                "trainers:files/poketool/trainer/trainers.json",
                "--set",
                "double_battle=true",
                "--json"
            ])
        )
        let heartGoldTrainerRequestedFieldKeys = try XCTUnwrap(heartGoldTrainerPlan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(heartGoldTrainerRequestedFieldKeys, ["double_battle"])
        let heartGoldTrainerChanges = try XCTUnwrap(heartGoldTrainerPlan["changes"] as? [[String: Any]])
        XCTAssertEqual(heartGoldTrainerChanges.count, 1)
        XCTAssertEqual(heartGoldTrainerChanges.first?["path"] as? String, "files/poketool/trainer/trainers.json")
        XCTAssertNil(heartGoldTrainerChanges.first?["textPreview"])

        let heartGoldTrainerApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                heartGoldRoot.path,
                "trainers:files/poketool/trainer/trainers.json",
                "--set",
                "name=Youngster Ben",
                "--set",
                "double_battle=true",
                "--json"
            ])
        )
        let heartGoldTrainerAppliedChanges = try XCTUnwrap(heartGoldTrainerApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(heartGoldTrainerAppliedChanges.count, 1)
        let updatedTrainer = try String(contentsOf: heartGoldRoot.appendingPathComponent("files/poketool/trainer/trainers.json"), encoding: .utf8)
        XCTAssertTrue(updatedTrainer.contains("\"name\":\"Youngster Ben\""))
        XCTAssertTrue(updatedTrainer.contains("\"double_battle\":true"))
        XCTAssertTrue(updatedTrainer.contains("\"party\":[{\"species\":\"RATTATA\",\"level\":4}]"))

        let heartGoldItemJSONPlan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                heartGoldRoot.path,
                "items:files/itemtool/itemdata/potion.json",
                "--set",
                "price=700",
                "--set",
                "field_use=false",
                "--json"
            ])
        )
        let heartGoldItemJSONRequestedFieldKeys = try XCTUnwrap(heartGoldItemJSONPlan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(heartGoldItemJSONRequestedFieldKeys, ["price", "field_use"])
        let heartGoldItemJSONChanges = try XCTUnwrap(heartGoldItemJSONPlan["changes"] as? [[String: Any]])
        XCTAssertEqual(heartGoldItemJSONChanges.count, 1)
        XCTAssertEqual(heartGoldItemJSONChanges.first?["path"] as? String, "files/itemtool/itemdata/potion.json")
        XCTAssertNil(heartGoldItemJSONChanges.first?["textPreview"])

        let heartGoldItemJSONApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                heartGoldRoot.path,
                "items:files/itemtool/itemdata/potion.json",
                "--set",
                "name=SUPER_POTION",
                "--set",
                "price=700",
                "--set",
                "field_use=false",
                "--json"
            ])
        )
        let heartGoldItemJSONAppliedChanges = try XCTUnwrap(heartGoldItemJSONApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(heartGoldItemJSONAppliedChanges.count, 1)
        let updatedHeartGoldItem = try String(contentsOf: heartGoldRoot.appendingPathComponent("files/itemtool/itemdata/potion.json"), encoding: .utf8)
        XCTAssertTrue(updatedHeartGoldItem.contains("\"name\":\"SUPER_POTION\""))
        XCTAssertTrue(updatedHeartGoldItem.contains("\"price\":700"))
        XCTAssertTrue(updatedHeartGoldItem.contains("\"field_use\":false"))
        XCTAssertTrue(updatedHeartGoldItem.contains("\"effects\":[{\"kind\":\"heal\",\"amount\":20}]"))

    }

    func testNDSDataSemanticCommandsPlanAndApplyHeartGoldSoulSilverItemCSVFields() throws {
        let root = try makeTestHeartGoldDecompRoot()
        try write(
            """
            id,name,description
            1,POTION,"Basic, heal"
            2,ANTIDOTE,Status

            """,
            to: root.appendingPathComponent("files/itemtool/itemdata/item_data.csv")
        )

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "items:files/itemtool/itemdata/item_data.csv",
                "--set",
                "rows.0.name=SUPER, POTION",
                "--set",
                "rows.1.description=Cures \"poison\"",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(requestedFieldKeys, ["rows.0.name", "rows.1.description"])
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, "files/itemtool/itemdata/item_data.csv")
        XCTAssertNil(changes.first?["textPreview"])

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            "items:files/itemtool/itemdata/item_data.csv",
            "--set",
            "rows.0.name=SUPER, POTION",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("SUPER, POTION"))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "items:files/itemtool/itemdata/item_data.csv",
                "--set",
                "rows.0.name=SUPER, POTION",
                "--set",
                "rows.1.description=Cures \"poison\"",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("files/itemtool/itemdata/item_data.csv"), encoding: .utf8)
        XCTAssertTrue(updated.contains("1,\"SUPER, POTION\",\"Basic, heal\""))
        XCTAssertTrue(updated.contains("2,ANTIDOTE,\"Cures \"\"poison\"\"\""))

        try write("id,name\n1,NESTED\n", to: root.appendingPathComponent("files/itemtool/itemdata/nested/item_data.csv"))
        let blockedNestedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "items:files/itemtool/itemdata/nested/item_data.csv",
                "--set",
                "rows.0.name=NESTED_EDIT",
                "--json"
            ])
        )
        let blockedNestedChanges = try XCTUnwrap(blockedNestedApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedNestedChanges.count, 0)
        let blockedNestedDiagnostics = try XCTUnwrap(blockedNestedApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedNestedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })

        try write(Data([0x00]), to: root.appendingPathComponent("files/itemtool/itemdata/item_0000.bin"))
        let blockedBinaryApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "items:files/itemtool/itemdata/item_0000.bin",
                "--set",
                "rows.0.name=BINARY",
                "--json"
            ])
        )
        let blockedBinaryChanges = try XCTUnwrap(blockedBinaryApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedBinaryChanges.count, 0)
        let blockedBinaryDiagnostics = try XCTUnwrap(blockedBinaryApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_ITEM_PATH_BLOCKED" })
        XCTAssertTrue(blockedBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataItemCSVRowOperationCommands() throws {
        let root = try makeTestHeartGoldDecompRoot()
        let itemPath = "files/itemtool/itemdata/item_data.csv"
        let itemRecordID = "items:\(itemPath)"
        try write(
            """
            id,name,description
            1,POTION,Basic heal
            2,ANTIDOTE,Status

            """,
            to: root.appendingPathComponent(itemPath)
        )
        try write("id,name\n1,NESTED\n", to: root.appendingPathComponent("files/itemtool/itemdata/nested/item_data.csv"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/itemtool/itemdata/item_0000.bin"))

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-item-csv-rows-plan",
            root.path,
            itemRecordID,
            "--insert",
            "1",
            "3,SECRET_ITEM,Secret text",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("SECRET_ITEM"))
        XCTAssertFalse(redactedPlan.contains("Secret text"))
        XCTAssertFalse(redactedPlan.contains("textPreview"))

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-item-csv-rows-plan",
                root.path,
                itemRecordID,
                "--insert",
                "1",
                "3,\"SUPER, POTION\",Large heal",
                "--delete",
                "0",
                "--reorder",
                "1",
                "0",
                "--json"
            ])
        )
        XCTAssertEqual(plan["recordID"] as? String, itemRecordID)
        XCTAssertEqual(plan["beforeRowCount"] as? Int, 2)
        XCTAssertEqual(plan["afterRowCount"] as? Int, 2)
        XCTAssertEqual(plan["changeCount"] as? Int, 1)
        let operations = try XCTUnwrap(plan["operations"] as? [[String: Any]])
        XCTAssertEqual(operations.count, 3)
        XCTAssertEqual(operations[0]["kind"] as? String, "insert")
        XCTAssertEqual(operations[0]["index"] as? Int, 1)
        XCTAssertEqual(operations[0]["insertedColumnCount"] as? Int, 3)
        XCTAssertNil(operations[0]["rowText"])
        XCTAssertEqual(operations[1]["kind"] as? String, "delete")
        XCTAssertEqual(operations[1]["index"] as? Int, 0)
        XCTAssertEqual(operations[2]["kind"] as? String, "reorder")
        XCTAssertEqual(operations[2]["fromIndex"] as? Int, 1)
        XCTAssertEqual(operations[2]["toIndex"] as? Int, 0)
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, itemPath)
        XCTAssertNil(changes.first?["textPreview"])

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-item-csv-rows-apply",
                root.path,
                itemRecordID,
                "--insert",
                "1",
                "3,\"SUPER, POTION\",Large heal",
                "--delete",
                "0",
                "--reorder",
                "1",
                "0",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        XCTAssertNotNil(appliedChanges.first?["backupPath"])
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(itemPath), encoding: .utf8),
            """
            id,name,description
            2,ANTIDOTE,Status
            3,\"SUPER, POTION\",Large heal

            """
        )

        let newlineApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-item-csv-rows-apply",
                root.path,
                itemRecordID,
                "--insert",
                "1",
                "4,BAD\nROW,Blocked",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(newlineApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(newlineApply["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_ITEM_CSV_ROWS_NEWLINE_BLOCKED" })

        let malformedPlan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-item-csv-rows-plan",
                root.path,
                itemRecordID,
                "--insert",
                "1",
                "4,\"BROKEN,Blocked",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(malformedPlan["changes"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(malformedPlan["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_ITEM_CSV_ROWS_QUOTE_UNCLOSED" })

        let wrongColumnPlan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-item-csv-rows-plan",
                root.path,
                itemRecordID,
                "--insert",
                "1",
                "4,ETHER",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(wrongColumnPlan["changes"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(wrongColumnPlan["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_ITEM_CSV_ROWS_INSERT_ROW_BAD_SHAPE" })

        let missingRowPlan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-item-csv-rows-plan",
                root.path,
                itemRecordID,
                "--delete",
                "8",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(missingRowPlan["changes"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(missingRowPlan["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_ITEM_CSV_ROWS_INDEX_OUT_OF_RANGE" })

        let blockedTargets = [
            "items:files/itemtool/itemdata/nested/item_data.csv",
            "items:files/itemtool/itemdata/potion.json",
            "items:files/itemtool/itemdata/item_0000.bin",
            "moves:files/poketool/waza/waza_tbl.narc"
        ]
        for recordID in blockedTargets {
            let blocked = try decodeJSON(
                PokemonHackCLI.run(arguments: [
                    "nds-data-item-csv-rows-plan",
                    root.path,
                    recordID,
                    "--insert",
                    "0",
                    "4,BLOCKED,Blocked",
                    "--json"
                ])
            )
            XCTAssertEqual(try XCTUnwrap(blocked["changes"] as? [[String: Any]]).count, 0, recordID)
            XCTAssertTrue(
                try XCTUnwrap(blocked["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_ITEM_CSV_ROWS_PATH_BLOCKED" },
                recordID
            )
        }

        let referenceRoot = try makeTemporaryDirectory().appendingPathComponent("references/pokeheartgold")
        try FileManager.default.createDirectory(at: referenceRoot, withIntermediateDirectories: true)
        try write("GAME_VERSION ?= HEARTGOLD\nGAME_CODE := IPK\n", to: referenceRoot.appendingPathComponent("config.mk"))
        try write("ROM := $(BUILD_DIR)/poke$(buildname).nds\n", to: referenceRoot.appendingPathComponent("Makefile"))
        try write("HostRoot files/\n", to: referenceRoot.appendingPathComponent("rom.rsf"))
        try write("filesystem: $(NITROFS_FILES)\n", to: referenceRoot.appendingPathComponent("filesystem.mk"))
        try write("dddddddddddddddddddddddddddddddddddddddd  pokeheartgold.us.nds\n", to: referenceRoot.appendingPathComponent("heartgold.us/rom.sha1"))
        try write("id,name,description\n1,POTION,Basic heal\n", to: referenceRoot.appendingPathComponent(itemPath))
        let referenceApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-item-csv-rows-apply",
                referenceRoot.path,
                itemRecordID,
                "--insert",
                "1",
                "4,REFERENCE,Blocked",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(referenceApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(referenceApply["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_EDIT_REFERENCE_BLOCKED" })

        let platinum = try makeTestNDSDecompRoot()
        try write("SPECIES_ABRA\n", to: platinum.appendingPathComponent("generated/species.txt"))
        let generatedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-item-csv-rows-apply",
                platinum.path,
                "resources:generated/species.txt",
                "--insert",
                "0",
                "4,GENERATED,Blocked",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(generatedApply["appliedChanges"] as? [[String: Any]]).count, 0)
        let generatedDiagnostics = try XCTUnwrap(generatedApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(generatedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_ITEM_CSV_ROWS_PATH_BLOCKED" })
        XCTAssertTrue(generatedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_EDIT_ROLE_BLOCKED" })

        let blockedBMGApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-item-csv-rows-apply",
                platinum.path,
                "text:res/text/battle.bmg",
                "--insert",
                "0",
                "4,BMG,Blocked",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(blockedBMGApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(blockedBMGApply["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_ITEM_CSV_ROWS_PATH_BLOCKED" })
    }

    func testNDSDataEncounterJSONRowOperationCommands() throws {
        let root = try makeTestNDSDecompRoot()
        let encounterPath = "res/field/encounters/route201.json"
        let encounterRecordID = "encounters:\(encounterPath)"
        try write(
            """
            {"land_rate": 30, "land_encounters": [{"level":2,"species":"SPECIES_STARLY"},{"level":3,"species":"SPECIES_BIDOOF"}], "swarms": ["SPECIES_DODUO","SPECIES_DODUO"], "map_category": {"map_type":"field","map_number":12}}

            """,
            to: root.appendingPathComponent(encounterPath)
        )
        try write("{\"land_encounters\":[{\"level\":2,\"species\":\"SPECIES_BIDOOF\"}]}\n", to: root.appendingPathComponent("res/field/encounters/nested/route202.json"))
        try write("rate=15\n", to: root.appendingPathComponent("res/field/encounters/route203.txt"))
        try write("[{\"level\":2,\"species\":\"SPECIES_BIDOOF\"}]\n", to: root.appendingPathComponent("res/field/encounters/array.json"))
        try write("{broken\n", to: root.appendingPathComponent("res/field/encounters/malformed.json"))
        try write("SPECIES_ABRA\n", to: root.appendingPathComponent("generated/species.txt"))

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-encounter-json-rows-plan",
            root.path,
            encounterRecordID,
            "--array",
            "land_encounters",
            "--insert",
            "1",
            "{\"level\":4,\"species\":\"SPECIES_SECRET\"}",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("SPECIES_SECRET"))
        XCTAssertFalse(redactedPlan.contains("\"level\":4"))
        XCTAssertFalse(redactedPlan.contains("textPreview"))

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-encounter-json-rows-plan",
                root.path,
                encounterRecordID,
                "--array",
                "land_encounters",
                "--insert",
                "1",
                "{\"level\":4,\"species\":\"SPECIES_SHINX\"}",
                "--delete",
                "0",
                "--reorder",
                "1",
                "0",
                "--json"
            ])
        )
        XCTAssertEqual(plan["recordID"] as? String, encounterRecordID)
        XCTAssertEqual(plan["arrayKey"] as? String, "land_encounters")
        XCTAssertEqual(plan["beforeRowCount"] as? Int, 2)
        XCTAssertEqual(plan["afterRowCount"] as? Int, 2)
        XCTAssertEqual(plan["changeCount"] as? Int, 1)
        let operations = try XCTUnwrap(plan["operations"] as? [[String: Any]])
        XCTAssertEqual(operations.count, 3)
        XCTAssertEqual(operations[0]["kind"] as? String, "insert")
        XCTAssertEqual(operations[0]["index"] as? Int, 1)
        XCTAssertEqual(operations[0]["insertedFieldCount"] as? Int, 2)
        XCTAssertNil(operations[0]["rowText"])
        XCTAssertEqual(operations[1]["kind"] as? String, "delete")
        XCTAssertEqual(operations[1]["index"] as? Int, 0)
        XCTAssertEqual(operations[2]["kind"] as? String, "reorder")
        XCTAssertEqual(operations[2]["fromIndex"] as? Int, 1)
        XCTAssertEqual(operations[2]["toIndex"] as? Int, 0)
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, encounterPath)
        XCTAssertNil(changes.first?["textPreview"])

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-encounter-json-rows-apply",
                root.path,
                encounterRecordID,
                "--array",
                "land_encounters",
                "--insert",
                "1",
                "{\"level\":4,\"species\":\"SPECIES_SHINX\"}",
                "--delete",
                "0",
                "--reorder",
                "1",
                "0",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        XCTAssertNotNil(appliedChanges.first?["backupPath"])
        let updated = try String(contentsOf: root.appendingPathComponent(encounterPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"land_encounters\": [{\"level\":3,\"species\":\"SPECIES_BIDOOF\"},{\"level\":4,\"species\":\"SPECIES_SHINX\"}]"))
        XCTAssertTrue(updated.contains("\"swarms\": [\"SPECIES_DODUO\",\"SPECIES_DODUO\"]"))

        let scalarArrayPlan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-encounter-json-rows-plan",
                root.path,
                encounterRecordID,
                "--array",
                "swarms",
                "--delete",
                "0",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(scalarArrayPlan["changes"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(scalarArrayPlan["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_ENCOUNTER_JSON_ROWS_OBJECT_ROWS_REQUIRED" })

        let missingArrayPlan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-encounter-json-rows-plan",
                root.path,
                encounterRecordID,
                "--array",
                "missing_encounters",
                "--delete",
                "0",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(missingArrayPlan["changes"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(missingArrayPlan["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_ENCOUNTER_JSON_ROWS_ARRAY_MISSING" })

        let nestedInsertPlan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-encounter-json-rows-plan",
                root.path,
                encounterRecordID,
                "--array",
                "land_encounters",
                "--insert",
                "0",
                "{\"level\":4,\"species\":\"SPECIES_SHINX\",\"metadata\":{\"time\":\"day\"}}",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(nestedInsertPlan["changes"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(nestedInsertPlan["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_ENCOUNTER_JSON_ROWS_NESTED_VALUE_BLOCKED" })

        let badShapePlan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-encounter-json-rows-plan",
                root.path,
                encounterRecordID,
                "--array",
                "land_encounters",
                "--insert",
                "0",
                "{\"level\":4}",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(badShapePlan["changes"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(badShapePlan["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_ENCOUNTER_JSON_ROWS_INSERT_ROW_BAD_SHAPE" })

        let rangePlan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-encounter-json-rows-plan",
                root.path,
                encounterRecordID,
                "--array",
                "land_encounters",
                "--delete",
                "8",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(rangePlan["changes"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(rangePlan["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_ENCOUNTER_JSON_ROWS_INDEX_OUT_OF_RANGE" })

        let malformedPlan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-encounter-json-rows-plan",
                root.path,
                "encounters:res/field/encounters/malformed.json",
                "--array",
                "land_encounters",
                "--delete",
                "0",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(malformedPlan["changes"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(malformedPlan["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_ENCOUNTER_JSON_ROWS_JSON_MALFORMED" })

        let blockedTargets = [
            "encounters:res/field/encounters/nested/route202.json",
            "encounters:res/field/encounters/route203.txt",
            "personal:res/prebuilt/poketool/personal/personal.narc",
            "resources:generated/species.txt"
        ]
        for blockedRecordID in blockedTargets {
            let blocked = try decodeJSON(
                PokemonHackCLI.run(arguments: [
                    "nds-data-encounter-json-rows-plan",
                    root.path,
                    blockedRecordID,
                    "--array",
                    "land_encounters",
                    "--delete",
                    "0",
                    "--json"
                ])
            )
            XCTAssertEqual(try XCTUnwrap(blocked["changes"] as? [[String: Any]]).count, 0, blockedRecordID)
            XCTAssertTrue(
                try XCTUnwrap(blocked["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_ENCOUNTER_JSON_ROWS_PATH_BLOCKED" },
                blockedRecordID
            )
        }

        let referenceRoot = try makeTemporaryDirectory().appendingPathComponent("references/pokeplatinum")
        try FileManager.default.createDirectory(at: referenceRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: referenceRoot.appendingPathComponent("src"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: referenceRoot.appendingPathComponent("asm"), withIntermediateDirectories: true)
        try write("rom: build/pokeplatinum.us.nds\n", to: referenceRoot.appendingPathComponent("Makefile"))
        try write("project('pokeplatinum')\n", to: referenceRoot.appendingPathComponent("meson.build"))
        try write("option('revision')\n", to: referenceRoot.appendingPathComponent("meson.options"))
        try write("path,sha1\n", to: referenceRoot.appendingPathComponent("platinum.us/filesys.csv"))
        try write("cccccccccccccccccccccccccccccccccccccccc  pokeplatinum.us.nds\n", to: referenceRoot.appendingPathComponent("platinum.us/rom_rev1.sha1"))
        try write("{\"land_encounters\":[{\"level\":2,\"species\":\"SPECIES_BIDOOF\"}]}\n", to: referenceRoot.appendingPathComponent(encounterPath))
        let referenceApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-encounter-json-rows-apply",
                referenceRoot.path,
                encounterRecordID,
                "--array",
                "land_encounters",
                "--delete",
                "0",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(referenceApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(referenceApply["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_EDIT_REFERENCE_BLOCKED" })
    }

    func testNDSDataEncounterJSONRowOperationCommandsHeartGoldSoulSilver() throws {
        let root = try makeTestHeartGoldDecompRoot()
        let encounterPath = "files/fielddata/encountdata/johto/route29.json"
        let encounterRecordID = "encounters:\(encounterPath)"
        try write(
            """
            {"morning_rate": 20, "slots": [{"species":"RATTATA","rate":30,"enabled":true},{"species":"PIDGEY","rate":20,"enabled":false}], "swarms": ["PIDGEY","SENTRET"], "metadata": {"map":"ROUTE_29"}}

            """,
            to: root.appendingPathComponent(encounterPath)
        )
        try write("{\"slots\":[]}\n", to: root.appendingPathComponent("files/fielddata/encountdata/empty.json"))
        try write("{\"slots\":[{\"species\":\"RATTATA\",\"rate\":30},{\"species\":\"PIDGEY\"}]}\n", to: root.appendingPathComponent("files/fielddata/encountdata/mismatch.json"))
        try write("{\"slots\":[{\"species\":\"RATTATA\",\"species\":\"PIDGEY\",\"rate\":30,\"enabled\":true}]}\n", to: root.appendingPathComponent("files/fielddata/encountdata/duplicate.json"))
        try write("rate=15\n", to: root.appendingPathComponent("files/fielddata/encountdata/gs_enc_data.txt"))
        try write("void Encounter_Load(void) {}\n", to: root.appendingPathComponent("files/fielddata/encountdata/encounter.c"))
        try write(makeTestNARC(), to: root.appendingPathComponent("files/poketool/waza/waza_tbl.narc"))

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-encounter-json-rows-plan",
            root.path,
            encounterRecordID,
            "--array",
            "slots",
            "--insert",
            "1",
            "{\"species\":\"SECRET\",\"rate\":99,\"enabled\":true}",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("SECRET"))
        XCTAssertFalse(redactedPlan.contains("\"rate\":99"))
        XCTAssertFalse(redactedPlan.contains("textPreview"))

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-encounter-json-rows-plan",
                root.path,
                encounterRecordID,
                "--array",
                "slots",
                "--insert",
                "1",
                "{\"species\":\"HOOTHOOT\",\"rate\":25,\"enabled\":true}",
                "--delete",
                "0",
                "--reorder",
                "1",
                "0",
                "--json"
            ])
        )
        XCTAssertEqual(plan["recordID"] as? String, encounterRecordID)
        XCTAssertEqual(plan["arrayKey"] as? String, "slots")
        XCTAssertEqual(plan["beforeRowCount"] as? Int, 2)
        XCTAssertEqual(plan["afterRowCount"] as? Int, 2)
        XCTAssertEqual(plan["changeCount"] as? Int, 1)
        let operations = try XCTUnwrap(plan["operations"] as? [[String: Any]])
        XCTAssertEqual(operations.count, 3)
        XCTAssertEqual(operations[0]["kind"] as? String, "insert")
        XCTAssertEqual(operations[0]["index"] as? Int, 1)
        XCTAssertEqual(operations[0]["insertedFieldCount"] as? Int, 3)
        XCTAssertNil(operations[0]["rowText"])
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, encounterPath)
        XCTAssertNil(changes.first?["textPreview"])

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-encounter-json-rows-apply",
                root.path,
                encounterRecordID,
                "--array",
                "slots",
                "--insert",
                "1",
                "{\"species\":\"HOOTHOOT\",\"rate\":25,\"enabled\":true}",
                "--delete",
                "0",
                "--reorder",
                "1",
                "0",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        XCTAssertNotNil(appliedChanges.first?["backupPath"])
        let updated = try String(contentsOf: root.appendingPathComponent(encounterPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"slots\": [{\"species\":\"PIDGEY\",\"rate\":20,\"enabled\":false},{\"species\":\"HOOTHOOT\",\"rate\":25,\"enabled\":true}]"))
        XCTAssertTrue(updated.contains("\"swarms\": [\"PIDGEY\",\"SENTRET\"]"))
        XCTAssertTrue(updated.contains("\"metadata\": {\"map\":\"ROUTE_29\"}"))

        let blockedPlans: [(String, String, [String], String?)] = [
            (encounterRecordID, "swarms", ["--delete", "0"], "NDS_DATA_ENCOUNTER_JSON_ROWS_OBJECT_ROWS_REQUIRED"),
            (encounterRecordID, "missing_slots", ["--delete", "0"], "NDS_DATA_ENCOUNTER_JSON_ROWS_ARRAY_MISSING"),
            ("encounters:files/fielddata/encountdata/empty.json", "slots", ["--insert", "0", "{\"species\":\"HOOTHOOT\",\"rate\":25,\"enabled\":true}"], "NDS_DATA_ENCOUNTER_JSON_ROWS_EMPTY_BLOCKED"),
            (encounterRecordID, "slots", ["--insert", "0", "{\"species\":\"HOOTHOOT\",\"rate\":25,\"enabled\":true,\"metadata\":{\"time\":\"night\"}}"], "NDS_DATA_ENCOUNTER_JSON_ROWS_NESTED_VALUE_BLOCKED"),
            ("encounters:files/fielddata/encountdata/mismatch.json", "slots", ["--delete", "0"], "NDS_DATA_ENCOUNTER_JSON_ROWS_ROW_SHAPE_MISMATCH"),
            ("encounters:files/fielddata/encountdata/duplicate.json", "slots", ["--delete", "0"], "NDS_DATA_ENCOUNTER_JSON_ROWS_KEY_DUPLICATE"),
            (encounterRecordID, "metadata.slots", ["--delete", "0"], "NDS_DATA_ENCOUNTER_JSON_ROWS_ARRAY_PATH_BLOCKED"),
            ("encounters:files/fielddata/encountdata/gs_enc_data.txt", "slots", ["--delete", "0"], "NDS_DATA_ENCOUNTER_JSON_ROWS_PATH_BLOCKED"),
            ("encounters:files/fielddata/encountdata/encounter.c", "slots", ["--delete", "0"], "NDS_DATA_ENCOUNTER_JSON_ROWS_PATH_BLOCKED"),
            ("moves:files/poketool/waza/waza_tbl.narc", "slots", ["--delete", "0"], "NDS_DATA_ENCOUNTER_JSON_ROWS_PATH_BLOCKED")
        ]
        for (recordID, arrayKey, operationArguments, expectedCode) in blockedPlans {
            let blocked = try decodeJSON(
                PokemonHackCLI.run(arguments: [
                    "nds-data-encounter-json-rows-plan",
                    root.path,
                    recordID,
                    "--array",
                    arrayKey
                ] + operationArguments + ["--json"])
            )
            XCTAssertEqual(try XCTUnwrap(blocked["changes"] as? [[String: Any]]).count, 0, recordID)
            XCTAssertTrue(
                try XCTUnwrap(blocked["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == expectedCode },
                "\(recordID) expected \(expectedCode ?? "nil")"
            )
        }

        let referenceRoot = try makeTemporaryDirectory().appendingPathComponent("references/pokeheartgold")
        try FileManager.default.createDirectory(at: referenceRoot, withIntermediateDirectories: true)
        try write("GAME_VERSION ?= HEARTGOLD\nGAME_CODE := IPK\n", to: referenceRoot.appendingPathComponent("config.mk"))
        try write("ROM := $(BUILD_DIR)/poke$(buildname).nds\n", to: referenceRoot.appendingPathComponent("Makefile"))
        try write("HostRoot files/\n", to: referenceRoot.appendingPathComponent("rom.rsf"))
        try write("filesystem: $(NITROFS_FILES)\n", to: referenceRoot.appendingPathComponent("filesystem.mk"))
        try write("dddddddddddddddddddddddddddddddddddddddd  pokeheartgold.us.nds\n", to: referenceRoot.appendingPathComponent("heartgold.us/rom.sha1"))
        try write("{\"slots\":[{\"species\":\"RATTATA\",\"rate\":30,\"enabled\":true}]}\n", to: referenceRoot.appendingPathComponent(encounterPath))
        let referenceApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-encounter-json-rows-apply",
                referenceRoot.path,
                encounterRecordID,
                "--array",
                "slots",
                "--delete",
                "0",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(referenceApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(referenceApply["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_EDIT_REFERENCE_BLOCKED" })

        let diamondRoot = try makeTestDiamondDecompRoot()
        let diamondPath = "files/fielddata/encountdata/sinnoh/route201.json"
        try write("{\"slots\":[{\"species\":\"BIDOOF\",\"rate\":30,\"enabled\":true}]}\n", to: diamondRoot.appendingPathComponent(diamondPath))
        let diamondPlan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-encounter-json-rows-plan",
                diamondRoot.path,
                "encounters:\(diamondPath)",
                "--array",
                "slots",
                "--delete",
                "0",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(diamondPlan["changes"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(diamondPlan["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_ENCOUNTER_JSON_ROWS_PATH_BLOCKED" })

        let platinumRoot = try makeTestNDSDecompRoot()
        try write("SPECIES_ABRA\n", to: platinumRoot.appendingPathComponent("generated/species.txt"))
        let generatedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-encounter-json-rows-apply",
                platinumRoot.path,
                "resources:generated/species.txt",
                "--array",
                "slots",
                "--delete",
                "0",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(generatedApply["appliedChanges"] as? [[String: Any]]).count, 0)
        let generatedDiagnostics = try XCTUnwrap(generatedApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(
            generatedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_ENCOUNTER_JSON_ROWS_PATH_BLOCKED" },
            "\(generatedDiagnostics)"
        )
    }

    func testNDSDataSemanticCommandsPlanAndApplyPlatinumTrainerClassJSONFields() throws {
        let root = try makeTestNDSDecompRoot()
        let classPath = "res/trainers/classes/youngster.json"
        let nestedPath = "res/trainers/classes/sinnoh/ace.json"
        let resourcePath = "res/trainers/resources/youngster.json"
        let textPath = "res/trainers/classes/youngster.txt"
        try write(
            "{\"cell_animation\":1,\"label\":\"Youngster\",\"enabled\":true,\"palette\":null,\"frames\":[{\"id\":1}],\"metadata\":{\"kind\":\"class\"}}\n",
            to: root.appendingPathComponent(classPath)
        )
        try write("{\"cell_animation\":2}\n", to: root.appendingPathComponent(nestedPath))
        try write("{\"cell_animation\":3}\n", to: root.appendingPathComponent(resourcePath))
        try write("cell_animation=4\n", to: root.appendingPathComponent(textPath))

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "trainers:\(classPath)",
                "--set",
                "cell_animation=5",
                "--set",
                "label=Youngster Prime",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(requestedFieldKeys, ["cell_animation", "label"])
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, classPath)
        XCTAssertNil(changes.first?["textPreview"])

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            "trainers:\(classPath)",
            "--set",
            "cell_animation=5",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("\"cell_animation\":5"))
        XCTAssertFalse(redactedPlan.contains("\"frames\""))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "trainers:\(classPath)",
                "--set",
                "cell_animation=6",
                "--set",
                "label=Youngster Prime",
                "--set",
                "enabled=false",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(classPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"cell_animation\":6"))
        XCTAssertTrue(updated.contains("\"label\":\"Youngster Prime\""))
        XCTAssertTrue(updated.contains("\"enabled\":false"))
        XCTAssertTrue(updated.contains("\"palette\":null"))
        XCTAssertTrue(updated.contains("\"frames\":[{\"id\":1}]"))
        XCTAssertTrue(updated.contains("\"metadata\":{\"kind\":\"class\"}"))

        let nestedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "trainers:\(classPath)",
                "--set",
                "frames.0.id=2",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(nestedApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(nestedApply["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })

        let blockedNestedPathApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "trainers:\(nestedPath)",
                "--set",
                "cell_animation=7",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(blockedNestedPathApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(blockedNestedPathApply["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_TRAINER_PATH_BLOCKED" })
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(nestedPath), encoding: .utf8),
            "{\"cell_animation\":2}\n"
        )

        let blockedResourceApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "trainers:\(resourcePath)",
                "--set",
                "cell_animation=7",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(blockedResourceApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(blockedResourceApply["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_TRAINER_PATH_BLOCKED" })
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(resourcePath), encoding: .utf8),
            "{\"cell_animation\":3}\n"
        )

        let blockedTextApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "trainers:\(textPath)",
                "--set",
                "cell_animation=7",
                "--json"
            ])
        )
        let blockedTextDiagnostics = try XCTUnwrap(blockedTextApply["diagnostics"] as? [[String: Any]])
        XCTAssertEqual(try XCTUnwrap(blockedTextApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_TRAINER_PATH_BLOCKED" })
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8),
            "cell_animation=4\n"
        )
    }

    func testNDSDataSemanticCommandsPlanAndApplyPlatinumSourceTextLineFields() throws {
        let root = try makeTestNDSDecompRoot()
        let textPath = "res/text/route201.txt"
        let textRecordID = "text:\(textPath)"

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                textRecordID,
                "--set",
                "lines.0.text=hello route",
                "--set",
                "lines.1.text=goodbye route",
                "--json"
            ])
        )

        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(requestedFieldKeys, ["lines.0.text", "lines.1.text"])
        let snapshot = try XCTUnwrap(plan["snapshot"] as? [String: Any])
        let fields = try XCTUnwrap(snapshot["fields"] as? [[String: Any]])
        XCTAssertTrue(fields.contains { $0["key"] as? String == "lines.0.text" && $0["label"] as? String == "Line 1" && $0["value"] as? String == "hello" })
        XCTAssertTrue(fields.contains { $0["key"] as? String == "lines.1.text" && $0["label"] as? String == "Line 2" && $0["value"] as? String == "world" })
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, textPath)
        XCTAssertNil(changes.first?["textPreview"])

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            textRecordID,
            "--set",
            "lines.0.text=secret route text",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("secret route text"))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                textRecordID,
                "--set",
                "lines.0.text=hello route",
                "--set",
                "lines.1.text=goodbye route",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8),
            "hello route\ngoodbye route\n"
        )

        let multilineApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                textRecordID,
                "--set",
                "lines.0.text=bad\nline",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(multilineApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(multilineApply["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_VALUE_INVALID" })
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8),
            "hello route\ngoodbye route\n"
        )

        let missingLinePlan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                textRecordID,
                "--set",
                "lines.2.text=new route text",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(missingLinePlan["changes"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(missingLinePlan["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FIELD_MISSING" })

        let bmgPath = "res/text/battle.bmg"
        let originalBMG = try Data(contentsOf: root.appendingPathComponent(bmgPath))
        let blockedBMGApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "text:\(bmgPath)",
                "--set",
                "lines.0.text=blocked",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(blockedBMGApply["appliedChanges"] as? [[String: Any]]).count, 0)
        let bmgDiagnostics = try XCTUnwrap(blockedBMGApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(bmgDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_TEXT_PATH_BLOCKED" })
        XCTAssertTrue(bmgDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(bmgPath)), originalBMG)

        let blockedContainerApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "personal:res/prebuilt/poketool/personal/personal.narc",
                "--set",
                "lines.0.text=blocked",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(blockedContainerApply["appliedChanges"] as? [[String: Any]]).count, 0)
        let containerDiagnostics = try XCTUnwrap(blockedContainerApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(containerDiagnostics.contains { $0["code"] as? String == "NDS_DATA_EDIT_CONTAINER_BLOCKED" })
        XCTAssertTrue(containerDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataTextLineOperationCommands() throws {
        let root = try makeTestNDSDecompRoot()
        let textPath = "res/text/route201.txt"
        let textRecordID = "text:\(textPath)"

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-text-lines-plan",
            root.path,
            textRecordID,
            "--insert",
            "1",
            "secret route text",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("secret route text"))

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-text-lines-plan",
                root.path,
                textRecordID,
                "--insert",
                "1",
                "middle",
                "--delete",
                "0",
                "--reorder",
                "1",
                "0",
                "--json"
            ])
        )
        XCTAssertEqual(plan["recordID"] as? String, textRecordID)
        XCTAssertEqual(plan["beforeLineCount"] as? Int, 2)
        XCTAssertEqual(plan["afterLineCount"] as? Int, 2)
        XCTAssertEqual(plan["changeCount"] as? Int, 1)
        let operations = try XCTUnwrap(plan["operations"] as? [[String: Any]])
        XCTAssertEqual(operations.count, 3)
        XCTAssertEqual(operations[0]["kind"] as? String, "insert")
        XCTAssertEqual(operations[0]["index"] as? Int, 1)
        XCTAssertNil(operations[0]["text"])
        XCTAssertEqual(operations[1]["kind"] as? String, "delete")
        XCTAssertEqual(operations[1]["index"] as? Int, 0)
        XCTAssertEqual(operations[2]["kind"] as? String, "reorder")
        XCTAssertEqual(operations[2]["fromIndex"] as? Int, 1)
        XCTAssertEqual(operations[2]["toIndex"] as? Int, 0)
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, textPath)
        XCTAssertNil(changes.first?["textPreview"])

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-text-lines-apply",
                root.path,
                textRecordID,
                "--insert",
                "1",
                "middle",
                "--delete",
                "0",
                "--reorder",
                "1",
                "0",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8),
            "world\nmiddle\n"
        )

        let newlineApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-text-lines-apply",
                root.path,
                textRecordID,
                "--insert",
                "1",
                "bad\nline",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(newlineApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(newlineApply["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_TEXT_LINES_NEWLINE_BLOCKED" })
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8),
            "world\nmiddle\n"
        )

        let missingLinePlan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-text-lines-plan",
                root.path,
                textRecordID,
                "--delete",
                "5",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(missingLinePlan["changes"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(missingLinePlan["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_TEXT_LINES_INDEX_OUT_OF_RANGE" })

        let bmgPath = "res/text/battle.bmg"
        let originalBMG = try Data(contentsOf: root.appendingPathComponent(bmgPath))
        let blockedBMGApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-text-lines-apply",
                root.path,
                "text:\(bmgPath)",
                "--insert",
                "0",
                "blocked",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(blockedBMGApply["appliedChanges"] as? [[String: Any]]).count, 0)
        let bmgDiagnostics = try XCTUnwrap(blockedBMGApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(bmgDiagnostics.contains { $0["code"] as? String == "NDS_DATA_TEXT_LINES_PATH_BLOCKED" })
        XCTAssertTrue(bmgDiagnostics.contains { $0["code"] as? String == "NDS_DATA_EDIT_FORMAT_BLOCKED" })
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(bmgPath)), originalBMG)

        let blockedJSONPlan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-text-lines-plan",
                root.path,
                "text:res/text/story.json",
                "--insert",
                "0",
                "blocked",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(blockedJSONPlan["changes"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(blockedJSONPlan["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_TEXT_LINES_PATH_BLOCKED" })

        let blockedContainerApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-text-lines-apply",
                root.path,
                "personal:res/prebuilt/poketool/personal/personal.narc",
                "--insert",
                "0",
                "blocked",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(blockedContainerApply["appliedChanges"] as? [[String: Any]]).count, 0)
        let containerDiagnostics = try XCTUnwrap(blockedContainerApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(containerDiagnostics.contains { $0["code"] as? String == "NDS_DATA_TEXT_LINES_PATH_BLOCKED" })
        XCTAssertTrue(containerDiagnostics.contains { $0["code"] as? String == "NDS_DATA_EDIT_CONTAINER_BLOCKED" })
    }

    func testNDSDataSemanticCommandsPlanAndApplyPlatinumTextJSONStringLeaves() throws {
        let root = try makeTestNDSDecompRoot()
        let textPath = "res/text/story.json"
        let textRecordID = "text:\(textPath)"
        try write(
            #"{"message":"hello","messages":{"intro":"start","choices":["yes","no"],"count":2},"enabled":true}"# + "\n",
            to: root.appendingPathComponent(textPath)
        )

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                textRecordID,
                "--set",
                "messages.intro=welcome back",
                "--set",
                "messages.choices.1=goodbye",
                "--json"
            ])
        )

        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(requestedFieldKeys, ["messages.intro", "messages.choices.1"])
        let snapshot = try XCTUnwrap(plan["snapshot"] as? [String: Any])
        let fields = try XCTUnwrap(snapshot["fields"] as? [[String: Any]])
        XCTAssertTrue(fields.contains { $0["key"] as? String == "message" && $0["value"] as? String == "hello" })
        XCTAssertTrue(fields.contains { $0["key"] as? String == "messages.intro" && $0["value"] as? String == "start" })
        XCTAssertTrue(fields.contains { $0["key"] as? String == "messages.choices.0" && $0["value"] as? String == "yes" })
        XCTAssertFalse(fields.contains { $0["key"] as? String == "messages.count" })
        XCTAssertFalse(fields.contains { $0["key"] as? String == "enabled" })
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, textPath)
        XCTAssertNil(changes.first?["textPreview"])

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            textRecordID,
            "--set",
            "message=secret route text",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("secret route text"))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                textRecordID,
                "--set",
                "message=bonjour",
                "--set",
                "messages.intro=welcome back",
                "--set",
                "messages.choices.1=goodbye",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8)
        XCTAssertTrue(updated.contains(#""message":"bonjour""#))
        XCTAssertTrue(updated.contains(#""intro":"welcome back""#))
        XCTAssertTrue(updated.contains(#""choices":["yes","goodbye"]"#))
        XCTAssertTrue(updated.contains(#""count":2"#))
        XCTAssertTrue(updated.contains(#""enabled":true"#))

        let multilineApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                textRecordID,
                "--set",
                "messages.intro=bad\nline",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(multilineApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(multilineApply["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_VALUE_INVALID" })

        let missingLeafPlan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                textRecordID,
                "--set",
                "messages.choices.2=inserted",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(missingLeafPlan["changes"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(missingLeafPlan["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FIELD_MISSING" })

        let nonStringPlan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                textRecordID,
                "--set",
                "messages.count=3",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(nonStringPlan["changes"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(nonStringPlan["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FIELD_MISSING" })

        let bmgPath = "res/text/battle.bmg"
        let originalBMG = try Data(contentsOf: root.appendingPathComponent(bmgPath))
        let blockedBMGApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "text:\(bmgPath)",
                "--set",
                "message=blocked",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(blockedBMGApply["appliedChanges"] as? [[String: Any]]).count, 0)
        let bmgDiagnostics = try XCTUnwrap(blockedBMGApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(bmgDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_TEXT_PATH_BLOCKED" })
        XCTAssertTrue(bmgDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent(bmgPath)), originalBMG)

        let blockedContainerApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "personal:res/prebuilt/poketool/personal/personal.narc",
                "--set",
                "message=blocked",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(blockedContainerApply["appliedChanges"] as? [[String: Any]]).count, 0)
        let containerDiagnostics = try XCTUnwrap(blockedContainerApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(containerDiagnostics.contains { $0["code"] as? String == "NDS_DATA_EDIT_CONTAINER_BLOCKED" })
        XCTAssertTrue(containerDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticCommandsPlanAndApplyPlatinumMoveJSONFields() throws {
        let root = try makeTestNDSDecompRoot()
        let movePath = "res/battle/moves/tackle.json"
        let nestedPath = "res/battle/moves/custom/tackle.json"
        let textPath = "res/battle/moves/tackle.txt"
        try write(
            "{\"power\":40,\"accuracy\":100,\"contact\":true,\"flags\":{\"protect\":true},\"contest\":[\"cool\"]}\n",
            to: root.appendingPathComponent(movePath)
        )
        try write("{\"power\":60}\n", to: root.appendingPathComponent(nestedPath))
        try write("power=50\n", to: root.appendingPathComponent(textPath))

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "moves:\(movePath)",
                "--set",
                "power=55",
                "--set",
                "contact=false",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(requestedFieldKeys, ["power", "contact"])
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, movePath)
        XCTAssertNil(changes.first?["textPreview"])

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            "moves:\(movePath)",
            "--set",
            "power=55",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("\"power\":55"))
        XCTAssertFalse(redactedPlan.contains("\"flags\""))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "moves:\(movePath)",
                "--set",
                "power=60",
                "--set",
                "accuracy=95",
                "--set",
                "contact=false",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(movePath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"power\":60"))
        XCTAssertTrue(updated.contains("\"accuracy\":95"))
        XCTAssertTrue(updated.contains("\"contact\":false"))
        XCTAssertTrue(updated.contains("\"flags\":{\"protect\":true}"))

        let nestedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "moves:\(movePath)",
                "--set",
                "flags.protect=false",
                "--json"
            ])
        )
        let nestedChanges = try XCTUnwrap(nestedApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(nestedChanges.count, 0)
        let nestedDiagnostics = try XCTUnwrap(nestedApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(nestedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })

        let blockedNestedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "moves:\(nestedPath)",
                "--set",
                "power=70",
                "--json"
            ])
        )
        let blockedNestedChanges = try XCTUnwrap(blockedNestedApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedNestedChanges.count, 0)
        let blockedNestedDiagnostics = try XCTUnwrap(blockedNestedApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedNestedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_MOVE_PATH_BLOCKED" })

        let blockedTextApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "moves:\(textPath)",
                "--set",
                "power=70",
                "--json"
            ])
        )
        let blockedTextChanges = try XCTUnwrap(blockedTextApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedTextChanges.count, 0)
        let blockedTextDiagnostics = try XCTUnwrap(blockedTextApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_MOVE_PATH_BLOCKED" })
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticCommandsPlanAndApplyPlatinumEncounterJSONFields() throws {
        let root = try makeTestNDSDecompRoot()
        try write(
            """
            {"land_rate": 30, "land_encounters": [{"level":2,"species":"SPECIES_STARLY"},{"level":3,"species":"SPECIES_BIDOOF"}], "swarms": ["SPECIES_DODUO","SPECIES_DODUO"], "map_category": {"map_type":"field","map_number":12}}

            """,
            to: root.appendingPathComponent("res/field/encounters/route201.json")
        )
        try write("rate=15\n", to: root.appendingPathComponent("res/field/encounters/route202.txt"))

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "encounters:res/field/encounters/route201.json",
                "--set",
                "land_rate=25",
                "--set",
                "land_encounters.0.level=4",
                "--set",
                "swarms.1=SPECIES_NIDORAN_M",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(requestedFieldKeys, ["land_rate", "land_encounters.0.level", "swarms.1"])
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, "res/field/encounters/route201.json")
        XCTAssertNil(changes.first?["textPreview"])

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            "encounters:res/field/encounters/route201.json",
            "--set",
            "land_encounters.0.level=4",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("\"land_rate\": 25"))
        XCTAssertFalse(redactedPlan.contains("\"level\":4"))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "encounters:res/field/encounters/route201.json",
                "--set",
                "land_encounters.0.level=5",
                "--set",
                "land_encounters.0.species=SPECIES_BIDOOF",
                "--set",
                "swarms.0=SPECIES_NIDORAN_F",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("res/field/encounters/route201.json"), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"land_encounters\": [{\"level\":5,\"species\":\"SPECIES_BIDOOF\"}"))
        XCTAssertTrue(updated.contains("\"swarms\": [\"SPECIES_NIDORAN_F\",\"SPECIES_DODUO\"]"))
        XCTAssertTrue(updated.contains("\"map_category\": {\"map_type\":\"field\",\"map_number\":12}"))

        let nestedObjectApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "encounters:res/field/encounters/route201.json",
                "--set",
                "map_category.map_type=building",
                "--json"
            ])
        )
        let nestedChanges = try XCTUnwrap(nestedObjectApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(nestedChanges.count, 0)
        let nestedDiagnostics = try XCTUnwrap(nestedObjectApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(nestedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })

        let missingSlotApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "encounters:res/field/encounters/route201.json",
                "--set",
                "land_encounters.99.level=10",
                "--json"
            ])
        )
        let missingSlotChanges = try XCTUnwrap(missingSlotApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(missingSlotChanges.count, 0)
        let missingSlotDiagnostics = try XCTUnwrap(missingSlotApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(missingSlotDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FIELD_MISSING" })

        let blockedTextApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "encounters:res/field/encounters/route202.txt",
                "--set",
                "rate=20",
                "--json"
            ])
        )
        let blockedTextChanges = try XCTUnwrap(blockedTextApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedTextChanges.count, 0)
        let blockedTextDiagnostics = try XCTUnwrap(blockedTextApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_ENCOUNTER_PATH_BLOCKED" })
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("res/field/encounters/route202.txt"), encoding: .utf8),
            "rate=15\n"
        )
    }

    func testNDSDataSemanticCommandsPlanAndApplyPlatinumFieldEventJSONFields() throws {
        let root = try makeTestNDSDecompRoot()
        let eventPath = "res/field/events/route201.json"
        let nestedPath = "res/field/events/nested/route202.json"
        let textPath = "res/field/events/route203.txt"
        try write(
            "{\"event_id\":1,\"weather\":\"CLEAR\",\"has_rival\":true,\"object_events\":[{\"id\":1,\"script\":\"Route201_Rival\"}]}\n",
            to: root.appendingPathComponent(eventPath)
        )
        try write("{\"event_id\":2}\n", to: root.appendingPathComponent(nestedPath))
        try write("event_id=3\n", to: root.appendingPathComponent(textPath))

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "maps:\(eventPath)",
                "--set",
                "event_id=4",
                "--set",
                "weather=RAIN",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(requestedFieldKeys, ["event_id", "weather"])
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, eventPath)
        XCTAssertNil(changes.first?["textPreview"])

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            "maps:\(eventPath)",
            "--set",
            "event_id=4",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("\"event_id\":4"))
        XCTAssertFalse(redactedPlan.contains("\"object_events\""))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(eventPath)",
                "--set",
                "event_id=5",
                "--set",
                "weather=RAIN",
                "--set",
                "has_rival=false",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(eventPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"event_id\":5"))
        XCTAssertTrue(updated.contains("\"weather\":\"RAIN\""))
        XCTAssertTrue(updated.contains("\"has_rival\":false"))
        XCTAssertTrue(updated.contains("\"object_events\":[{\"id\":1,\"script\":\"Route201_Rival\"}]"))

        let nestedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(eventPath)",
                "--set",
                "object_events.0.id=2",
                "--json"
            ])
        )
        let nestedChanges = try XCTUnwrap(nestedApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(nestedChanges.count, 0)
        let nestedDiagnostics = try XCTUnwrap(nestedApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(nestedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })

        let blockedNestedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(nestedPath)",
                "--set",
                "event_id=6",
                "--json"
            ])
        )
        let blockedNestedChanges = try XCTUnwrap(blockedNestedApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedNestedChanges.count, 0)
        let blockedNestedDiagnostics = try XCTUnwrap(blockedNestedApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedNestedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })

        let blockedTextApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(textPath)",
                "--set",
                "event_id=6",
                "--json"
            ])
        )
        let blockedTextChanges = try XCTUnwrap(blockedTextApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedTextChanges.count, 0)
        let blockedTextDiagnostics = try XCTUnwrap(blockedTextApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8),
            "event_id=3\n"
        )
    }

    func testNDSDataSemanticCommandsPlanAndApplyPlatinumMapMatrixJSONFields() throws {
        let root = try makeTestNDSDecompRoot()
        let matrixPath = "res/field/matrices/route201.json"
        let nestedPath = "res/field/matrices/sinnoh/route202.json"
        let textPath = "res/field/matrices/route203.txt"
        try write(
            "{\"matrix\":1,\"width\":32,\"name\":\"Route 201\",\"enabled\":true,\"layout\":[[1,2]],\"evolutions\":[[\"LEVEL\",16,\"MONFERNO\"]],\"metadata\":{\"region\":\"SINNOH\"}}\n",
            to: root.appendingPathComponent(matrixPath)
        )
        try write("{\"matrix\":2}\n", to: root.appendingPathComponent(nestedPath))
        try write("matrix=3\n", to: root.appendingPathComponent(textPath))
        try write("SPECIES_ABRA\n", to: root.appendingPathComponent("generated/species.txt"))

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "maps:\(matrixPath)",
                "--set",
                "matrix=4",
                "--set",
                "name=Route 201 North",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(requestedFieldKeys, ["matrix", "name"])
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, matrixPath)
        XCTAssertNil(changes.first?["textPreview"])

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            "maps:\(matrixPath)",
            "--set",
            "matrix=4",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("\"matrix\":4"))
        XCTAssertFalse(redactedPlan.contains("\"layout\""))
        XCTAssertFalse(redactedPlan.contains("\"evolutions\""))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(matrixPath)",
                "--set",
                "matrix=5",
                "--set",
                "name=Route 201 North",
                "--set",
                "enabled=false",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(matrixPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"matrix\":5"))
        XCTAssertTrue(updated.contains("\"name\":\"Route 201 North\""))
        XCTAssertTrue(updated.contains("\"enabled\":false"))
        XCTAssertTrue(updated.contains("\"layout\":[[1,2]]"))
        XCTAssertTrue(updated.contains("\"evolutions\":[[\"LEVEL\",16,\"MONFERNO\"]]"))
        XCTAssertTrue(updated.contains("\"metadata\":{\"region\":\"SINNOH\"}"))

        let nestedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(matrixPath)",
                "--set",
                "layout.0.0=3",
                "--json"
            ])
        )
        let nestedChanges = try XCTUnwrap(nestedApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(nestedChanges.count, 0)
        let nestedDiagnostics = try XCTUnwrap(nestedApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(nestedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })

        let evolutionTupleApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(matrixPath)",
                "--set",
                "evolutions.0.parameter=20",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(evolutionTupleApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(evolutionTupleApply["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })

        let blockedNestedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(nestedPath)",
                "--set",
                "matrix=6",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(blockedNestedApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(blockedNestedApply["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })

        let blockedTextApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(textPath)",
                "--set",
                "matrix=6",
                "--json"
            ])
        )
        let blockedTextDiagnostics = try XCTUnwrap(blockedTextApply["diagnostics"] as? [[String: Any]])
        XCTAssertEqual(try XCTUnwrap(blockedTextApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let blockedMapBinaryApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:res/field/maps/route201/map.bin",
                "--set",
                "matrix=6",
                "--json"
            ])
        )
        let blockedMapBinaryDiagnostics = try XCTUnwrap(blockedMapBinaryApply["diagnostics"] as? [[String: Any]])
        XCTAssertEqual(try XCTUnwrap(blockedMapBinaryApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(blockedMapBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(blockedMapBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let blockedGeneratedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "resources:generated/species.txt",
                "--set",
                "matrix=6",
                "--json"
            ])
        )
        let blockedGeneratedDiagnostics = try XCTUnwrap(blockedGeneratedApply["diagnostics"] as? [[String: Any]])
        XCTAssertEqual(try XCTUnwrap(blockedGeneratedApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(blockedGeneratedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_DOMAIN_BLOCKED" })
        XCTAssertTrue(blockedGeneratedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticCommandsPlanAndApplyPlatinumAreaDataJSONFields() throws {
        let root = try makeTestNDSDecompRoot()
        let areaDataPath = "res/field/area_data/route201.json"
        let nestedPath = "res/field/area_data/sinnoh/route202.json"
        let textPath = "res/field/area_data/route203.txt"
        try write(
            "{\"area_id\":1,\"name\":\"Route 201\",\"enabled\":true,\"weather\":null,\"warps\":[{\"target\":\"Sandgem\"}],\"metadata\":{\"region\":\"SINNOH\"}}\n",
            to: root.appendingPathComponent(areaDataPath)
        )
        try write("{\"area_id\":2}\n", to: root.appendingPathComponent(nestedPath))
        try write("area_id=3\n", to: root.appendingPathComponent(textPath))
        try write("SPECIES_ABRA\n", to: root.appendingPathComponent("generated/species.txt"))

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "maps:\(areaDataPath)",
                "--set",
                "area_id=4",
                "--set",
                "name=Route 201 North",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(requestedFieldKeys, ["area_id", "name"])
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, areaDataPath)
        XCTAssertNil(changes.first?["textPreview"])

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            "maps:\(areaDataPath)",
            "--set",
            "area_id=4",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("\"area_id\":4"))
        XCTAssertFalse(redactedPlan.contains("\"warps\""))
        XCTAssertFalse(redactedPlan.contains("\"metadata\""))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(areaDataPath)",
                "--set",
                "area_id=5",
                "--set",
                "name=Route 201 North",
                "--set",
                "enabled=false",
                "--set",
                "weather=null",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(areaDataPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"area_id\":5"))
        XCTAssertTrue(updated.contains("\"name\":\"Route 201 North\""))
        XCTAssertTrue(updated.contains("\"enabled\":false"))
        XCTAssertTrue(updated.contains("\"weather\":null"))
        XCTAssertTrue(updated.contains("\"warps\":[{\"target\":\"Sandgem\"}]"))
        XCTAssertTrue(updated.contains("\"metadata\":{\"region\":\"SINNOH\"}"))

        let nestedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(areaDataPath)",
                "--set",
                "warps.0.target=Jubilife",
                "--json"
            ])
        )
        let nestedChanges = try XCTUnwrap(nestedApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(nestedChanges.count, 0)
        let nestedDiagnostics = try XCTUnwrap(nestedApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(nestedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })

        let blockedNestedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(nestedPath)",
                "--set",
                "area_id=6",
                "--json"
            ])
        )
        XCTAssertEqual(try XCTUnwrap(blockedNestedApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(try XCTUnwrap(blockedNestedApply["diagnostics"] as? [[String: Any]]).contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })

        let blockedTextApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(textPath)",
                "--set",
                "area_id=6",
                "--json"
            ])
        )
        let blockedTextDiagnostics = try XCTUnwrap(blockedTextApply["diagnostics"] as? [[String: Any]])
        XCTAssertEqual(try XCTUnwrap(blockedTextApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let blockedMapBinaryApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:res/field/maps/route201/map.bin",
                "--set",
                "area_id=6",
                "--json"
            ])
        )
        let blockedMapBinaryDiagnostics = try XCTUnwrap(blockedMapBinaryApply["diagnostics"] as? [[String: Any]])
        XCTAssertEqual(try XCTUnwrap(blockedMapBinaryApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(blockedMapBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(blockedMapBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let blockedGeneratedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "resources:generated/species.txt",
                "--set",
                "area_id=6",
                "--json"
            ])
        )
        let blockedGeneratedDiagnostics = try XCTUnwrap(blockedGeneratedApply["diagnostics"] as? [[String: Any]])
        XCTAssertEqual(try XCTUnwrap(blockedGeneratedApply["appliedChanges"] as? [[String: Any]]).count, 0)
        XCTAssertTrue(blockedGeneratedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_DOMAIN_BLOCKED" })
        XCTAssertTrue(blockedGeneratedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticCommandsPlanAndApplyHeartGoldSoulSilverEncounterJSONFields() throws {
        let root = try makeTestHeartGoldDecompRoot()
        let encounterPath = "files/fielddata/encountdata/johto/route29.json"
        try write(
            """
            {"morning_rate": 20, "day_rate": 15, "night_rate": 10, "enabled": true, "slots": [{"species":"RATTATA","rate":30,"enabled":true}], "swarms": ["PIDGEY","SENTRET"], "metadata": {"map":"ROUTE_29"}}

            """,
            to: root.appendingPathComponent(encounterPath)
        )
        try write("rate=15\n", to: root.appendingPathComponent("files/fielddata/encountdata/gs_enc_data.txt"))
        try write("void Encounter_Load(void) {}\n", to: root.appendingPathComponent("files/fielddata/encountdata/encounter.c"))

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "encounters:\(encounterPath)",
                "--set",
                "morning_rate=25",
                "--set",
                "slots.0.rate=35",
                "--set",
                "swarms.1=HOOTHOOT",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(requestedFieldKeys, ["morning_rate", "slots.0.rate", "swarms.1"])
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, encounterPath)
        XCTAssertNil(changes.first?["textPreview"])

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            "encounters:\(encounterPath)",
            "--set",
            "slots.0.rate=35",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("\"rate\":35"))
        XCTAssertFalse(redactedPlan.contains("\"species\":\"RATTATA\""))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "encounters:\(encounterPath)",
                "--set",
                "day_rate=18",
                "--set",
                "enabled=false",
                "--set",
                "slots.0.species=SENTRET",
                "--set",
                "slots.0.rate=40",
                "--set",
                "swarms.0=HOOTHOOT",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(encounterPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"day_rate\": 18"))
        XCTAssertTrue(updated.contains("\"enabled\": false"))
        XCTAssertTrue(updated.contains("\"slots\": [{\"species\":\"SENTRET\",\"rate\":40,\"enabled\":true}]"))
        XCTAssertTrue(updated.contains("\"swarms\": [\"HOOTHOOT\",\"SENTRET\"]"))
        XCTAssertTrue(updated.contains("\"metadata\": {\"map\":\"ROUTE_29\"}"))

        let nestedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "encounters:\(encounterPath)",
                "--set",
                "metadata.map=ROUTE_30",
                "--json"
            ])
        )
        let nestedChanges = try XCTUnwrap(nestedApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(nestedChanges.count, 0)
        let nestedDiagnostics = try XCTUnwrap(nestedApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(nestedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })

        let missingSlotApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "encounters:\(encounterPath)",
                "--set",
                "slots.99.rate=35",
                "--json"
            ])
        )
        let missingSlotChanges = try XCTUnwrap(missingSlotApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(missingSlotChanges.count, 0)
        let missingSlotDiagnostics = try XCTUnwrap(missingSlotApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(missingSlotDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FIELD_MISSING" })

        let blockedTextApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "encounters:files/fielddata/encountdata/gs_enc_data.txt",
                "--set",
                "morning_rate=20",
                "--json"
            ])
        )
        let blockedTextChanges = try XCTUnwrap(blockedTextApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedTextChanges.count, 0)
        let blockedTextDiagnostics = try XCTUnwrap(blockedTextApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_ENCOUNTER_PATH_BLOCKED" })
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("files/fielddata/encountdata/gs_enc_data.txt"), encoding: .utf8),
            "rate=15\n"
        )

        let blockedCApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "encounters:files/fielddata/encountdata/encounter.c",
                "--set",
                "morning_rate=20",
                "--json"
            ])
        )
        let blockedCChanges = try XCTUnwrap(blockedCApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedCChanges.count, 0)
        let blockedCDiagnostics = try XCTUnwrap(blockedCApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedCDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })
        XCTAssertTrue(blockedCDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_ENCOUNTER_PATH_BLOCKED" })
        XCTAssertTrue(blockedCDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("files/fielddata/encountdata/encounter.c"), encoding: .utf8),
            "void Encounter_Load(void) {}\n"
        )
    }

    func testNDSDataSemanticCommandsPlanAndApplyHeartGoldSoulSilverZoneEventJSONFields() throws {
        let root = try makeTestHeartGoldDecompRoot()
        let zoneEventPath = "files/fielddata/eventdata/zone_event/zone_001.json"
        let nestedPath = "files/fielddata/eventdata/zone_event/johto/zone_002.json"
        try write(
            """
            {"zone_id": 1, "script": "Route29_Intro", "enabled": true, "object_events": [{"id":1,"script":"Route29_NPC"}], "metadata": {"map":"ROUTE_29"}}

            """,
            to: root.appendingPathComponent(zoneEventPath)
        )
        try write("{\"zone_id\":2}\n", to: root.appendingPathComponent(nestedPath))
        try write("zone_id=3\n", to: root.appendingPathComponent("files/fielddata/eventdata/zone_event/zone_003.txt"))

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "scripts:\(zoneEventPath)",
                "--set",
                "zone_id=4",
                "--set",
                "enabled=false",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(requestedFieldKeys, ["zone_id", "enabled"])
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, zoneEventPath)
        XCTAssertNil(changes.first?["textPreview"])

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            "scripts:\(zoneEventPath)",
            "--set",
            "zone_id=4",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("\"zone_id\": 4"))
        XCTAssertFalse(redactedPlan.contains("\"object_events\""))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "scripts:\(zoneEventPath)",
                "--set",
                "script=Route29_Edit",
                "--set",
                "enabled=false",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(zoneEventPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"script\": \"Route29_Edit\""))
        XCTAssertTrue(updated.contains("\"enabled\": false"))
        XCTAssertTrue(updated.contains("\"object_events\": [{\"id\":1,\"script\":\"Route29_NPC\"}]"))
        XCTAssertTrue(updated.contains("\"metadata\": {\"map\":\"ROUTE_29\"}"))

        let nestedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "scripts:\(zoneEventPath)",
                "--set",
                "object_events.0.id=2",
                "--json"
            ])
        )
        let nestedChanges = try XCTUnwrap(nestedApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(nestedChanges.count, 0)
        let nestedDiagnostics = try XCTUnwrap(nestedApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(nestedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })

        let blockedNestedPathApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "scripts:\(nestedPath)",
                "--set",
                "zone_id=5",
                "--json"
            ])
        )
        let blockedNestedPathChanges = try XCTUnwrap(blockedNestedPathApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedNestedPathChanges.count, 0)
        let blockedNestedPathDiagnostics = try XCTUnwrap(blockedNestedPathApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedNestedPathDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })
        XCTAssertTrue(blockedNestedPathDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_SCRIPT_PATH_BLOCKED" })
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(nestedPath), encoding: .utf8),
            "{\"zone_id\":2}\n"
        )

        let blockedTextApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "scripts:files/fielddata/eventdata/zone_event/zone_003.txt",
                "--set",
                "zone_id=6",
                "--json"
            ])
        )
        let blockedTextChanges = try XCTUnwrap(blockedTextApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedTextChanges.count, 0)
        let blockedTextDiagnostics = try XCTUnwrap(blockedTextApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_SCRIPT_PATH_BLOCKED" })
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("files/fielddata/eventdata/zone_event/zone_003.txt"), encoding: .utf8),
            "zone_id=3\n"
        )
    }

    func testNDSDataSemanticCommandsPlanAndApplyHeartGoldSoulSilverMapHeaderCIntegerScalars() throws {
        let root = try makeTestHeartGoldDecompRoot()

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "maps:src/data/map_headers.h",
                "--set",
                "mapHeaders.MAP_EVERYWHERE.areaDataBank=8",
                "--set",
                "mapHeaders.MAP_EVERYWHERE.worldMapX=9",
                "--set",
                "mapHeaders.MAP_NEW_BARK.weather=3",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(
            requestedFieldKeys,
            [
                "mapHeaders.MAP_EVERYWHERE.areaDataBank",
                "mapHeaders.MAP_EVERYWHERE.worldMapX",
                "mapHeaders.MAP_NEW_BARK.weather"
            ]
        )
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, "src/data/map_headers.h")
        XCTAssertNil(changes.first?["textPreview"])

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            "maps:src/data/map_headers.h",
            "--set",
            "mapHeaders.MAP_EVERYWHERE.areaDataBank=8",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains(".areaDataBank = 8"))
        XCTAssertFalse(redactedPlan.contains("sMapHeaders"))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:src/data/map_headers.h",
                "--set",
                "mapHeaders.MAP_EVERYWHERE.areaDataBank=8",
                "--set",
                "mapHeaders.MAP_EVERYWHERE.cameraType=5",
                "--set",
                "mapHeaders.MAP_NEW_BARK.worldMapY=10",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("src/data/map_headers.h"), encoding: .utf8)
        XCTAssertTrue(updated.contains(".areaDataBank = 8"))
        XCTAssertTrue(updated.contains(".cameraType = 5"))
        XCTAssertTrue(updated.contains("[MAP_NEW_BARK] = { .areaDataBank = 3, .worldMapX = 4, .worldMapY = 10, .weather = 1, .cameraType = 2, .bikeAllowed = FALSE }"))
        XCTAssertTrue(updated.contains("{ .areaDataBank = 99 }"))

        let invalidApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:src/data/map_headers.h",
                "--set",
                "mapHeaders.MAP_EVERYWHERE.weather=MAP_WEATHER_RAIN",
                "--json"
            ])
        )
        let invalidChanges = try XCTUnwrap(invalidApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(invalidChanges.count, 0)
        let invalidDiagnostics = try XCTUnwrap(invalidApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(invalidDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_VALUE_INVALID" })

        let blockedMatrixApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:files/fielddata/mapmatrix/0001.bin",
                "--set",
                "mapHeaders.MAP_EVERYWHERE.areaDataBank=9",
                "--json"
            ])
        )
        let blockedMatrixChanges = try XCTUnwrap(blockedMatrixApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedMatrixChanges.count, 0)
        let blockedMatrixDiagnostics = try XCTUnwrap(blockedMatrixApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedMatrixDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })
        XCTAssertTrue(blockedMatrixDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(blockedMatrixDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
        XCTAssertEqual(
            try Data(contentsOf: root.appendingPathComponent("files/fielddata/mapmatrix/0001.bin")),
            Data([0x00])
        )
    }

    func testNDSDataSemanticCommandsPlanAndApplyDiamondPearlEncounterJSONFields() throws {
        let root = try makeTestDiamondDecompRoot()
        let encounterPath = "files/fielddata/encountdata/sinnoh/route201.json"
        try write(
            """
            {"rate": 20, "morning_rate": 10, "enabled": true, "slots": [{"species":"BIDOOF","rate":30,"metadata":{"time":"morning"}},{"species":"STARLY","rate":20}], "swarms": ["DODUO","NIDORAN_F"], "metadata": {"map":"ROUTE_201"}}

            """,
            to: root.appendingPathComponent(encounterPath)
        )
        try write("rate=15\n", to: root.appendingPathComponent("files/fielddata/encountdata/route202.txt"))

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "encounters:\(encounterPath)",
                "--set",
                "rate=25",
                "--set",
                "slots.0.rate=35",
                "--set",
                "swarms.1=NIDORAN_M",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(requestedFieldKeys, ["rate", "slots.0.rate", "swarms.1"])
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, encounterPath)
        XCTAssertNil(changes.first?["textPreview"])

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            "encounters:\(encounterPath)",
            "--set",
            "slots.0.rate=35",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("\"rate\": 25"))
        XCTAssertFalse(redactedPlan.contains("\"species\":\"BIDOOF\""))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "encounters:\(encounterPath)",
                "--set",
                "morning_rate=15",
                "--set",
                "enabled=false",
                "--set",
                "slots.0.species=KRICKETOT",
                "--set",
                "slots.0.rate=35",
                "--set",
                "swarms.0=PIDGEY",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(encounterPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"morning_rate\": 15"))
        XCTAssertTrue(updated.contains("\"enabled\": false"))
        XCTAssertTrue(updated.contains("\"slots\": [{\"species\":\"KRICKETOT\",\"rate\":35,\"metadata\":{\"time\":\"morning\"}},{\"species\":\"STARLY\",\"rate\":20}]"))
        XCTAssertTrue(updated.contains("\"swarms\": [\"PIDGEY\",\"NIDORAN_F\"]"))
        XCTAssertTrue(updated.contains("\"metadata\": {\"map\":\"ROUTE_201\"}"))

        let nestedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "encounters:\(encounterPath)",
                "--set",
                "metadata.map=ROUTE_202",
                "--json"
            ])
        )
        let nestedChanges = try XCTUnwrap(nestedApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(nestedChanges.count, 0)
        let nestedDiagnostics = try XCTUnwrap(nestedApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(nestedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })

        let missingSlotApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "encounters:\(encounterPath)",
                "--set",
                "slots.99.rate=35",
                "--json"
            ])
        )
        let missingSlotChanges = try XCTUnwrap(missingSlotApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(missingSlotChanges.count, 0)
        let missingSlotDiagnostics = try XCTUnwrap(missingSlotApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(missingSlotDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FIELD_MISSING" })

        let blockedTextApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "encounters:files/fielddata/encountdata/route202.txt",
                "--set",
                "rate=20",
                "--json"
            ])
        )
        let blockedTextChanges = try XCTUnwrap(blockedTextApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedTextChanges.count, 0)
        let blockedTextDiagnostics = try XCTUnwrap(blockedTextApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_ENCOUNTER_PATH_BLOCKED" })
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("files/fielddata/encountdata/route202.txt"), encoding: .utf8),
            "rate=15\n"
        )

        let blockedCApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "encounters:arm9/src/encounter.c",
                "--set",
                "rate=20",
                "--json"
            ])
        )
        let blockedCChanges = try XCTUnwrap(blockedCApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedCChanges.count, 0)
        let blockedCDiagnostics = try XCTUnwrap(blockedCApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedCDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(blockedCDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_ENCOUNTER_PATH_BLOCKED" })
        XCTAssertTrue(blockedCDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("arm9/src/encounter.c"), encoding: .utf8),
            "void Encounter_Load(void) {}\n"
        )
    }

    func testNDSDataSemanticCommandsPlanAndApplyDiamondPearlFieldEventJSONFields() throws {
        let root = try makeTestDiamondDecompRoot()
        let eventPath = "files/fielddata/eventdata/route201.json"
        let nestedPath = "files/fielddata/eventdata/sinnoh/route202.json"
        let textPath = "files/fielddata/eventdata/route203.txt"
        try write(
            """
            {"event_id": 10, "weather": "CLEAR", "has_rival": true, "object_events": [{"id":1,"script":"Route201_Rival"}], "metadata": {"map":"ROUTE_201"}}

            """,
            to: root.appendingPathComponent(eventPath)
        )
        try write("{\"event_id\":11}\n", to: root.appendingPathComponent(nestedPath))
        try write("event_id=12\n", to: root.appendingPathComponent(textPath))

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "maps:\(eventPath)",
                "--set",
                "event_id=15",
                "--set",
                "weather=RAIN",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(requestedFieldKeys, ["event_id", "weather"])
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, eventPath)
        XCTAssertNil(changes.first?["textPreview"])

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            "maps:\(eventPath)",
            "--set",
            "event_id=15",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("\"event_id\": 15"))
        XCTAssertFalse(redactedPlan.contains("\"object_events\""))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(eventPath)",
                "--set",
                "weather=RAIN",
                "--set",
                "has_rival=false",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(eventPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"weather\": \"RAIN\""))
        XCTAssertTrue(updated.contains("\"has_rival\": false"))
        XCTAssertTrue(updated.contains("\"object_events\": [{\"id\":1,\"script\":\"Route201_Rival\"}]"))
        XCTAssertTrue(updated.contains("\"metadata\": {\"map\":\"ROUTE_201\"}"))

        let nestedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(eventPath)",
                "--set",
                "object_events.0.id=2",
                "--json"
            ])
        )
        let nestedChanges = try XCTUnwrap(nestedApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(nestedChanges.count, 0)
        let nestedDiagnostics = try XCTUnwrap(nestedApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(nestedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })

        let blockedNestedPathApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(nestedPath)",
                "--set",
                "event_id=20",
                "--json"
            ])
        )
        let blockedNestedPathChanges = try XCTUnwrap(blockedNestedPathApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedNestedPathChanges.count, 0)
        let blockedNestedPathDiagnostics = try XCTUnwrap(blockedNestedPathApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedNestedPathDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(blockedNestedPathDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(nestedPath), encoding: .utf8),
            "{\"event_id\":11}\n"
        )

        let blockedTextApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(textPath)",
                "--set",
                "event_id=20",
                "--json"
            ])
        )
        let blockedTextChanges = try XCTUnwrap(blockedTextApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedTextChanges.count, 0)
        let blockedTextDiagnostics = try XCTUnwrap(blockedTextApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(blockedTextDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8),
            "event_id=12\n"
        )

        let blockedMatrixApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:files/fielddata/mapmatrix/matrix.bin",
                "--set",
                "mapHeaders.0.weatherType=20",
                "--json"
            ])
        )
        let blockedMatrixChanges = try XCTUnwrap(blockedMatrixApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedMatrixChanges.count, 0)
        let blockedMatrixDiagnostics = try XCTUnwrap(blockedMatrixApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedMatrixDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(blockedMatrixDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(blockedMatrixDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
        XCTAssertEqual(
            try Data(contentsOf: root.appendingPathComponent("files/fielddata/mapmatrix/matrix.bin")),
            Data([0x00])
        )
    }

    func testNDSDataSemanticCommandsPlanAndApplyDiamondPearlAreaDataJSONFields() throws {
        let root = try makeTestDiamondDecompRoot()
        let areaDataPath = "files/fielddata/areadata/area_0002.json"
        let nestedPath = "files/fielddata/areadata/sinnoh/area_0003.json"
        let nestedLandDataPath = "files/fielddata/land_data/sinnoh/land_0002.json"
        try write(
            "{\"area_id\":2,\"name\":\"Route 202\",\"enabled\":true,\"weather\":null,\"warps\":[{\"target\":\"Jubilife\"}],\"metadata\":{\"region\":\"SINNOH\"}}\n",
            to: root.appendingPathComponent(areaDataPath)
        )
        try write("{\"area_id\":3}\n", to: root.appendingPathComponent(nestedPath))
        try write("{\"land_id\":2}\n", to: root.appendingPathComponent(nestedLandDataPath))

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "maps:\(areaDataPath)",
                "--set",
                "area_id=4",
                "--set",
                "name=Route 202 North",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(requestedFieldKeys, ["area_id", "name"])
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, areaDataPath)
        XCTAssertNil(changes.first?["textPreview"])

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            "maps:\(areaDataPath)",
            "--set",
            "area_id=4",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("\"area_id\":4"))
        XCTAssertFalse(redactedPlan.contains("\"warps\""))
        XCTAssertFalse(redactedPlan.contains("\"metadata\""))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(areaDataPath)",
                "--set",
                "area_id=5",
                "--set",
                "name=Route 202 North",
                "--set",
                "enabled=false",
                "--set",
                "weather=null",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(areaDataPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"area_id\":5"))
        XCTAssertTrue(updated.contains("\"name\":\"Route 202 North\""))
        XCTAssertTrue(updated.contains("\"enabled\":false"))
        XCTAssertTrue(updated.contains("\"weather\":null"))
        XCTAssertTrue(updated.contains("\"warps\":[{\"target\":\"Jubilife\"}]"))
        XCTAssertTrue(updated.contains("\"metadata\":{\"region\":\"SINNOH\"}"))

        let nestedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(areaDataPath)",
                "--set",
                "warps.0.target=Oreburgh",
                "--json"
            ])
        )
        let nestedChanges = try XCTUnwrap(nestedApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(nestedChanges.count, 0)
        let nestedDiagnostics = try XCTUnwrap(nestedApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(nestedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })

        let blockedNestedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(nestedPath)",
                "--set",
                "area_id=4",
                "--json"
            ])
        )
        let blockedNestedChanges = try XCTUnwrap(blockedNestedApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedNestedChanges.count, 0)
        let blockedNestedDiagnostics = try XCTUnwrap(blockedNestedApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedNestedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(blockedNestedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })

        let blockedLandApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(nestedLandDataPath)",
                "--set",
                "land_id=4",
                "--json"
            ])
        )
        let blockedLandChanges = try XCTUnwrap(blockedLandApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedLandChanges.count, 0)
        let blockedLandDiagnostics = try XCTUnwrap(blockedLandApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedLandDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(blockedLandDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })

        let blockedBinaryApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:files/fielddata/areadata/area_0001.bin",
                "--set",
                "area_id=7",
                "--json"
            ])
        )
        let blockedBinaryChanges = try XCTUnwrap(blockedBinaryApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedBinaryChanges.count, 0)
        let blockedBinaryDiagnostics = try XCTUnwrap(blockedBinaryApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(blockedBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(blockedBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
        XCTAssertEqual(
            try Data(contentsOf: root.appendingPathComponent("files/fielddata/areadata/area_0001.bin")),
            Data([0x03])
        )
    }

    func testNDSDataSemanticCommandsPlanAndApplyDiamondPearlLandDataJSONFields() throws {
        let root = try makeTestDiamondDecompRoot()
        let landDataPath = "files/fielddata/land_data/land_0002.json"
        let nestedPath = "files/fielddata/land_data/sinnoh/land_0003.json"
        try write(
            "{\"land_id\":2,\"name\":\"Route 202 Land\",\"enabled\":true,\"weather\":null,\"tiles\":[{\"terrain\":\"grass\"}],\"metadata\":{\"region\":\"SINNOH\"}}\n",
            to: root.appendingPathComponent(landDataPath)
        )
        try write("{\"land_id\":3}\n", to: root.appendingPathComponent(nestedPath))

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "maps:\(landDataPath)",
                "--set",
                "land_id=4",
                "--set",
                "name=Route 202 North Land",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(requestedFieldKeys, ["land_id", "name"])
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, landDataPath)
        XCTAssertNil(changes.first?["textPreview"])

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            "maps:\(landDataPath)",
            "--set",
            "land_id=4",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("\"land_id\":4"))
        XCTAssertFalse(redactedPlan.contains("\"tiles\""))
        XCTAssertFalse(redactedPlan.contains("\"metadata\""))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(landDataPath)",
                "--set",
                "land_id=5",
                "--set",
                "name=Route 202 North Land",
                "--set",
                "enabled=false",
                "--set",
                "weather=null",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(landDataPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"land_id\":5"))
        XCTAssertTrue(updated.contains("\"name\":\"Route 202 North Land\""))
        XCTAssertTrue(updated.contains("\"enabled\":false"))
        XCTAssertTrue(updated.contains("\"weather\":null"))
        XCTAssertTrue(updated.contains("\"tiles\":[{\"terrain\":\"grass\"}]"))
        XCTAssertTrue(updated.contains("\"metadata\":{\"region\":\"SINNOH\"}"))

        let nestedFieldApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(landDataPath)",
                "--set",
                "tiles.0.terrain=sand",
                "--json"
            ])
        )
        let nestedFieldChanges = try XCTUnwrap(nestedFieldApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(nestedFieldChanges.count, 0)
        let nestedFieldDiagnostics = try XCTUnwrap(nestedFieldApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(nestedFieldDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })

        let blockedNestedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:\(nestedPath)",
                "--set",
                "land_id=4",
                "--json"
            ])
        )
        let blockedNestedChanges = try XCTUnwrap(blockedNestedApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedNestedChanges.count, 0)
        let blockedNestedDiagnostics = try XCTUnwrap(blockedNestedApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedNestedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(blockedNestedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })

        let blockedBinaryApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:files/fielddata/land_data/land_0001.bin",
                "--set",
                "land_id=7",
                "--json"
            ])
        )
        let blockedBinaryChanges = try XCTUnwrap(blockedBinaryApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedBinaryChanges.count, 0)
        let blockedBinaryDiagnostics = try XCTUnwrap(blockedBinaryApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(blockedBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(blockedBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
        XCTAssertEqual(
            try Data(contentsOf: root.appendingPathComponent("files/fielddata/land_data/land_0001.bin")),
            Data([0x02])
        )
    }

    func testNDSDataSemanticCommandsPlanAndApplyDiamondPearlMapHeaderCScalars() throws {
        let root = try makeTestDiamondDecompRoot()

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "maps:arm9/src/map_header.c",
                "--set",
                "mapHeaders.0.weatherType=14",
                "--set",
                "mapHeaders.0.cameraType=3",
                "--set",
                "mapHeaders.1.areaDataBank=8",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(
            requestedFieldKeys,
            [
                "mapHeaders.0.weatherType",
                "mapHeaders.0.cameraType",
                "mapHeaders.1.areaDataBank"
            ]
        )
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, "arm9/src/map_header.c")
        XCTAssertNil(changes.first?["textPreview"])

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            "maps:arm9/src/map_header.c",
            "--set",
            "mapHeaders.0.weatherType=14",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("MAPSEC_JUBILIFE_CITY, 14"))
        XCTAssertFalse(redactedPlan.contains("sMapHeaders[]"))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:arm9/src/map_header.c",
                "--set",
                "mapHeaders.0.weatherType=14",
                "--set",
                "mapHeaders.0.cameraType=3",
                "--set",
                "mapHeaders.0.battleBg=9",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("arm9/src/map_header.c"), encoding: .utf8)
        XCTAssertTrue(updated.contains("MAPSEC_JUBILIFE_CITY, 14, 3, 4, 9, TRUE"))
        XCTAssertTrue(updated.contains("{ 1, 2, 3 },"))

        let invalidApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:arm9/src/map_header.c",
                "--set",
                "mapHeaders.0.weatherType=MAP_WEATHER_RAIN",
                "--json"
            ])
        )
        let invalidChanges = try XCTUnwrap(invalidApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(invalidChanges.count, 0)
        let invalidDiagnostics = try XCTUnwrap(invalidApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(invalidDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_VALUE_INVALID" })

        let booleanApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:arm9/src/map_header.c",
                "--set",
                "mapHeaders.0.isBikeAllowed=FALSE",
                "--json"
            ])
        )
        let booleanChanges = try XCTUnwrap(booleanApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(booleanChanges.count, 0)
        let booleanDiagnostics = try XCTUnwrap(booleanApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(booleanDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FIELD_MISSING" })

        let blockedAreaApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "maps:files/fielddata/areadata/area_0001.bin",
                "--set",
                "mapHeaders.0.weatherType=20",
                "--json"
            ])
        )
        let blockedAreaChanges = try XCTUnwrap(blockedAreaApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedAreaChanges.count, 0)
        let blockedAreaDiagnostics = try XCTUnwrap(blockedAreaApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedAreaDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(blockedAreaDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(blockedAreaDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
        XCTAssertEqual(
            try Data(contentsOf: root.appendingPathComponent("files/fielddata/areadata/area_0001.bin")),
            Data([0x03])
        )
    }

    func testNDSDataSemanticCommandsPlanAndApplyDiamondPearlMoveCAnchorScalars() throws {
        let root = try makeTestDiamondDecompRoot()

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "moves:arm9/src/waza.c",
                "--set",
                "waza.MOVE_TACKLE.effect=MOVE_EFFECT_QUICK_ATTACK",
                "--set",
                "waza.MOVE_TACKLE.power=40",
                "--set",
                "waza.MOVE_TACKLE.type=TYPE_FIGHTING",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(
            requestedFieldKeys,
            [
                "waza.MOVE_TACKLE.effect",
                "waza.MOVE_TACKLE.power",
                "waza.MOVE_TACKLE.type"
            ]
        )
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, "arm9/src/waza.c")
        XCTAssertNil(changes.first?["textPreview"])

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            "moves:arm9/src/waza.c",
            "--set",
            "waza.MOVE_TACKLE.power=40",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains(".power = 40"))
        XCTAssertFalse(redactedPlan.contains("sWazaTbl[]"))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "moves:arm9/src/waza.c",
                "--set",
                "waza.MOVE_TACKLE.effect=MOVE_EFFECT_QUICK_ATTACK",
                "--set",
                "waza.MOVE_TACKLE.class=CLASS_SPECIAL",
                "--set",
                "waza.MOVE_TACKLE.power=40",
                "--set",
                "waza.MOVE_TACKLE.type=TYPE_FIGHTING",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("arm9/src/waza.c"), encoding: .utf8)
        XCTAssertTrue(updated.contains(".effect = MOVE_EFFECT_QUICK_ATTACK"))
        XCTAssertTrue(updated.contains(".class = CLASS_SPECIAL"))
        XCTAssertTrue(updated.contains(".power = 40"))
        XCTAssertTrue(updated.contains(".type = TYPE_FIGHTING"))
        XCTAssertTrue(updated.contains("ReadWholeNarcMemberByIdPair"))

        let invalidApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "moves:arm9/src/waza.c",
                "--set",
                "waza.MOVE_TACKLE.power=20 + 10",
                "--json"
            ])
        )
        let invalidChanges = try XCTUnwrap(invalidApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(invalidChanges.count, 0)
        let invalidDiagnostics = try XCTUnwrap(invalidApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(invalidDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_VALUE_INVALID" })

        let missingApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "moves:arm9/src/waza.c",
                "--set",
                "waza.MOVE_TACKLE.padding=1",
                "--json"
            ])
        )
        let missingChanges = try XCTUnwrap(missingApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(missingChanges.count, 0)
        let missingDiagnostics = try XCTUnwrap(missingApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(missingDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FIELD_MISSING" })

        let blockedEncounterApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "encounters:arm9/src/encounter.c",
                "--set",
                "waza.MOVE_TACKLE.power=40",
                "--json"
            ])
        )
        let blockedEncounterChanges = try XCTUnwrap(blockedEncounterApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedEncounterChanges.count, 0)
        let blockedEncounterDiagnostics = try XCTUnwrap(blockedEncounterApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedEncounterDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(blockedEncounterDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_ENCOUNTER_PATH_BLOCKED" })
        XCTAssertTrue(blockedEncounterDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("arm9/src/encounter.c"), encoding: .utf8),
            "void Encounter_Load(void) {}\n"
        )
    }

    func testNDSDataSemanticCommandsPlanAndApplyDiamondPearlPersonalJSONFields() throws {
        let root = try makeTestDiamondDecompRoot()
        try write(Data([0x00]), to: root.appendingPathComponent("files/poketool/personal/personal_0000.bin"))

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "personal:files/poketool/personal/personal.json",
                "--set",
                "personal=7",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(requestedFieldKeys, ["personal"])
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, "files/poketool/personal/personal.json")
        XCTAssertNil(changes.first?["textPreview"])

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "personal:files/poketool/personal/personal.json",
                "--set",
                "personal=9",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        XCTAssertTrue(
            try String(contentsOf: root.appendingPathComponent("files/poketool/personal/personal.json"), encoding: .utf8)
                .contains("\"personal\":9")
        )

        let blockedBinaryApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "personal:files/poketool/personal/personal_0000.bin",
                "--set",
                "personal=10",
                "--json"
            ])
        )
        let blockedBinaryChanges = try XCTUnwrap(blockedBinaryApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedBinaryChanges.count, 0)
        let blockedBinaryDiagnostics = try XCTUnwrap(blockedBinaryApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(blockedBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticCommandsPlanAndApplyDiamondPearlTrainerJSONFields() throws {
        let root = try makeTestDiamondDecompRoot()
        try write(
            "{\"id\":1,\"name\":\"Youngster Dan\",\"double_battle\":false,\"party\":[{\"species\":\"STARLY\",\"level\":5}]}\n",
            to: root.appendingPathComponent("files/poketool/trainer/trainers.json")
        )
        try write(Data([0x00]), to: root.appendingPathComponent("files/poketool/trainer/trainer_0000.bin"))

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "trainers:files/poketool/trainer/trainers.json",
                "--set",
                "name=Youngster Jo",
                "--set",
                "double_battle=true",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(requestedFieldKeys, ["name", "double_battle"])
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, "files/poketool/trainer/trainers.json")
        XCTAssertNil(changes.first?["textPreview"])

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "trainers:files/poketool/trainer/trainers.json",
                "--set",
                "name=Youngster Lee",
                "--set",
                "double_battle=true",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("files/poketool/trainer/trainers.json"), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"name\":\"Youngster Lee\""))
        XCTAssertTrue(updated.contains("\"double_battle\":true"))
        XCTAssertTrue(updated.contains("\"party\":[{\"species\":\"STARLY\",\"level\":5}]"))

        let nestedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "trainers:files/poketool/trainer/trainers.json",
                "--set",
                "party.0.level=6",
                "--json"
            ])
        )
        let nestedChanges = try XCTUnwrap(nestedApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(nestedChanges.count, 0)
        let nestedDiagnostics = try XCTUnwrap(nestedApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(nestedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })

        let blockedBinaryApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "trainers:files/poketool/trainer/trainer_0000.bin",
                "--set",
                "name=Youngster Kay",
                "--json"
            ])
        )
        let blockedBinaryChanges = try XCTUnwrap(blockedBinaryApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedBinaryChanges.count, 0)
        let blockedBinaryDiagnostics = try XCTUnwrap(blockedBinaryApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(blockedBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticCommandsPlanAndApplyDiamondPearlItemJSONFields() throws {
        let root = try makeTestDiamondDecompRoot()
        let itemPath = "files/itemtool/itemdata/potion.json"

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "items:\(itemPath)",
                "--set",
                "price=500",
                "--set",
                "field_use=false",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(requestedFieldKeys, ["price", "field_use"])
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, itemPath)
        XCTAssertNil(changes.first?["textPreview"])

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            "items:\(itemPath)",
            "--set",
            "price=500",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("\"price\":500"))
        XCTAssertFalse(redactedPlan.contains("\"effects\""))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "items:\(itemPath)",
                "--set",
                "name=SUPER_POTION",
                "--set",
                "price=700",
                "--set",
                "field_use=false",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(itemPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"name\":\"SUPER_POTION\""))
        XCTAssertTrue(updated.contains("\"price\":700"))
        XCTAssertTrue(updated.contains("\"field_use\":false"))
        XCTAssertTrue(updated.contains("\"effects\":[{\"kind\":\"heal\",\"amount\":20}]"))

        let nestedApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "items:\(itemPath)",
                "--set",
                "effects.0.amount=50",
                "--json"
            ])
        )
        let nestedChanges = try XCTUnwrap(nestedApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(nestedChanges.count, 0)
        let nestedDiagnostics = try XCTUnwrap(nestedApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(nestedDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })

        let blockedBinaryApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "items:files/itemtool/itemdata/item_0000.bin",
                "--set",
                "price=800",
                "--json"
            ])
        )
        let blockedBinaryChanges = try XCTUnwrap(blockedBinaryApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedBinaryChanges.count, 0)
        let blockedBinaryDiagnostics = try XCTUnwrap(blockedBinaryApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(blockedBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_ITEM_PATH_BLOCKED" })
        XCTAssertTrue(blockedBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticCommandsPlanAndApplyDiamondPearlItemMappingCScalars() throws {
        let root = try makeTestDiamondDecompRoot()

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "items:arm9/src/itemtool.c",
                "--set",
                "itemIndexMappings.1.itemDataIndex=42",
                "--set",
                "itemIndexMappings.1.iconIndex=24",
                "--set",
                "itemIndexMappings.1.paletteIndex=11",
                "--set",
                "itemIndexMappings.1.gen3Index=9",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(
            requestedFieldKeys,
            [
                "itemIndexMappings.1.itemDataIndex",
                "itemIndexMappings.1.iconIndex",
                "itemIndexMappings.1.paletteIndex",
                "itemIndexMappings.1.gen3Index"
            ]
        )
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, "arm9/src/itemtool.c")
        XCTAssertNil(changes.first?["textPreview"])

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "items:arm9/src/itemtool.c",
                "--set",
                "itemIndexMappings.1.itemDataIndex=42",
                "--set",
                "itemIndexMappings.1.iconIndex=24",
                "--set",
                "itemIndexMappings.1.paletteIndex=11",
                "--set",
                "itemIndexMappings.1.gen3Index=9",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("arm9/src/itemtool.c"), encoding: .utf8)
        XCTAssertTrue(updated.contains("{ 42, 24, 11, 9 }"))
        XCTAssertTrue(updated.contains("ITEM_DATA_COUNT"))

        let invalidApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "items:arm9/src/itemtool.c",
                "--set",
                "itemIndexMappings.1.iconIndex=ITEM_ICON_POTION",
                "--json"
            ])
        )
        let invalidChanges = try XCTUnwrap(invalidApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(invalidChanges.count, 0)
        let invalidDiagnostics = try XCTUnwrap(invalidApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(invalidDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_VALUE_INVALID" })

        let blockedBinaryApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "items:files/itemtool/itemdata/item_0000.bin",
                "--set",
                "itemIndexMappings.0.itemDataIndex=7",
                "--json"
            ])
        )
        let blockedBinaryChanges = try XCTUnwrap(blockedBinaryApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedBinaryChanges.count, 0)
        let blockedBinaryDiagnostics = try XCTUnwrap(blockedBinaryApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(blockedBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticCommandsPlanAndApplyDiamondPearlTrainerClassGenderCScalars() throws {
        let root = try makeTestDiamondDecompRoot()
        try write(Data([0x00]), to: root.appendingPathComponent("files/poketool/trainer/trainer_0000.bin"))

        let plan = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-plan",
                root.path,
                "trainers:arm9/src/trainer_data.c",
                "--set",
                "trainerClassGenderCounts.0.genderCount=1",
                "--set",
                "trainerClassGenderCounts.2.genderCount=0",
                "--json"
            ])
        )
        let requestedFieldKeys = try XCTUnwrap(plan["requestedFieldKeys"] as? [String])
        XCTAssertEqual(
            requestedFieldKeys,
            [
                "trainerClassGenderCounts.0.genderCount",
                "trainerClassGenderCounts.2.genderCount"
            ]
        )
        let changes = try XCTUnwrap(plan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)
        XCTAssertEqual(changes.first?["path"] as? String, "arm9/src/trainer_data.c")
        XCTAssertNil(changes.first?["textPreview"])

        let redactedPlan = try PokemonHackCLI.run(arguments: [
            "nds-data-semantic-plan",
            root.path,
            "trainers:arm9/src/trainer_data.c",
            "--set",
            "trainerClassGenderCounts.0.genderCount=1",
            "--json"
        ])
        XCTAssertFalse(redactedPlan.contains("/*TRAINER_CLASS_PKMN_TRAINER_M*/ 1"))
        XCTAssertFalse(redactedPlan.contains("sTrainerClassGenderCountTbl"))

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "trainers:arm9/src/trainer_data.c",
                "--set",
                "trainerClassGenderCounts.0.genderCount=1",
                "--set",
                "trainerClassGenderCounts.2.genderCount=0",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("arm9/src/trainer_data.c"), encoding: .utf8)
        XCTAssertTrue(updated.contains("/*TRAINER_CLASS_PKMN_TRAINER_M*/ 1"))
        XCTAssertTrue(updated.contains("/*TRAINER_CLASS_TWINS*/ 0"))
        XCTAssertTrue(updated.contains("TRAINER_CLASS_GENDER_COUNT_SENTINEL"))

        let invalidApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "trainers:arm9/src/trainer_data.c",
                "--set",
                "trainerClassGenderCounts.1.genderCount=TRAINER_CLASS_GENDER_COUNT_FEMALE",
                "--json"
            ])
        )
        let invalidChanges = try XCTUnwrap(invalidApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(invalidChanges.count, 0)
        let invalidDiagnostics = try XCTUnwrap(invalidApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(invalidDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_VALUE_INVALID" })

        let blockedBinaryApply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "trainers:files/poketool/trainer/trainer_0000.bin",
                "--set",
                "trainerClassGenderCounts.0.genderCount=2",
                "--json"
            ])
        )
        let blockedBinaryChanges = try XCTUnwrap(blockedBinaryApply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(blockedBinaryChanges.count, 0)
        let blockedBinaryDiagnostics = try XCTUnwrap(blockedBinaryApply["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(blockedBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(blockedBinaryDiagnostics.contains { $0["code"] as? String == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testToolchainHealthCommandSurfacesNDSPreviewRows() throws {
        let root = try makeTestNDSDecompRoot()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["toolchain-health", root.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "pokeplatinum")
        XCTAssertEqual(result["isPreviewOnly"] as? Bool, true)
        let rows = try XCTUnwrap(result["rows"] as? [[String: Any]])
        XCTAssertTrue(rows.contains { $0["id"] as? String == "external:nds:devkitpro-root" })
        XCTAssertTrue(rows.contains { $0["id"] as? String == "external:nds:ndstool" })
        XCTAssertTrue(rows.contains { $0["id"] as? String == "external:nds:melonDS" })
        XCTAssertTrue(rows.contains { $0["id"] as? String == "rom-header:platinum-rom" })
        XCTAssertTrue(rows.contains { $0["id"] as? String == "generated:nds-build-output:platinum-rom" })
        XCTAssertTrue(rows.contains { $0["id"] as? String == "graphics-conversion:nds-preview-only" })
        XCTAssertFalse(rows.contains { $0["id"] as? String == "external:mgba" })
        let actions = rows.flatMap { $0["actions"] as? [[String: Any]] ?? [] }
        XCTAssertFalse(actions.isEmpty)
        XCTAssertTrue(actions.allSatisfy { $0["isPreviewOnly"] as? Bool == true })
    }

    func testToolchainHealthCommandSurfacesPokeBlackManualBuildReadinessJSON() throws {
        let root = try makeTestBlackDecompRoot()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["toolchain-health", root.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "pokeblack")
        XCTAssertEqual(result["isPreviewOnly"] as? Bool, true)
        let rows = try XCTUnwrap(result["rows"] as? [[String: Any]])
        let readinessRows = rows.filter { ($0["id"] as? String)?.hasPrefix("gen-v-build-readiness:") == true }
        XCTAssertEqual(
            Set(readinessRows.compactMap { $0["id"] as? String }),
            [
                "gen-v-build-readiness:metadata",
                "gen-v-build-readiness:source-roots",
                "gen-v-build-readiness:variant-sha1",
                "gen-v-build-readiness:generated-output"
            ]
        )

        let metadata = try XCTUnwrap(rows.first { $0["id"] as? String == "gen-v-build-readiness:metadata" })
        XCTAssertEqual(metadata["status"] as? String, "ready")
        XCTAssertTrue((metadata["detail"] as? String)?.contains("Makefile=present") == true)
        XCTAssertTrue((metadata["detail"] as? String)?.contains("config.mk=present") == true)
        XCTAssertTrue((metadata["detail"] as? String)?.contains("arm9.ld=present, arm7.ld=present") == true)

        let sourceRoots = try XCTUnwrap(rows.first { $0["id"] as? String == "gen-v-build-readiness:source-roots" })
        XCTAssertEqual(sourceRoots["status"] as? String, "ready")
        XCTAssertTrue((sourceRoots["detail"] as? String)?.contains("src=5 members/92 bytes") == true)
        XCTAssertTrue((sourceRoots["detail"] as? String)?.contains("include=1 members/16 bytes") == true)

        let variantSHA1 = try XCTUnwrap(rows.first { $0["id"] as? String == "gen-v-build-readiness:variant-sha1" })
        XCTAssertEqual(variantSHA1["status"] as? String, "warning")
        XCTAssertTrue((variantSHA1["detail"] as? String)?.contains("black.us/rom.sha1=valid:ffffffffffffffffffffffffffffffffffffffff") == true)
        XCTAssertTrue((variantSHA1["detail"] as? String)?.contains("white2.us/rom.sha1=missing") == true)

        let generatedOutput = try XCTUnwrap(rows.first { $0["id"] as? String == "gen-v-build-readiness:generated-output" })
        XCTAssertEqual(generatedOutput["status"] as? String, "warning")
        XCTAssertTrue((generatedOutput["detail"] as? String)?.contains("build=missing") == true)
        XCTAssertTrue((generatedOutput["detail"] as? String)?.contains("pokeblack.nds=missing") == true)
        XCTAssertTrue((generatedOutput["detail"] as? String)?.contains("black-rom:pokeblack.nds=missing") == true)

        let actions = readinessRows.flatMap { $0["actions"] as? [[String: Any]] ?? [] }
        XCTAssertFalse(actions.isEmpty)
        XCTAssertTrue(actions.allSatisfy { $0["isPreviewOnly"] as? Bool == true })
        XCTAssertTrue(actions.contains { $0["kind"] as? String == "copyCommand" && $0["command"] as? String == "make" })
        XCTAssertTrue(actions.contains { $0["kind"] as? String == "copyPath" && $0["payload"] as? String == "pokeblack.nds" })
        XCTAssertTrue(actions.contains { $0["kind"] as? String == "rerunGuidance" })
    }

    func testMoveCatalogCommandEmitsPreviewJSON() throws {
        let root = try makeMoveCatalogProject()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["move-catalog", root.path, "--json"])
        )

        XCTAssertNotNil(result["summary"])
        XCTAssertNotNil(result["moves"])
        XCTAssertNotNil(result["machineMemberships"])
        XCTAssertNotNil(result["tutorMemberships"])
        XCTAssertNotNil(result["learnsetMemberships"])
        XCTAssertNotNil(result["diagnostics"])
    }

    func testMoveCatalogCommandEmitsRubySapphireEditableJSON() throws {
        let root = try makeRubyMoveCatalogProject()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["move-catalog", root.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "pokeruby")
        let summary = try XCTUnwrap(result["summary"] as? [String: Any])
        XCTAssertEqual(summary["moveCount"] as? Int, 1)
        let moves = try XCTUnwrap(result["moves"] as? [[String: Any]])
        let pound = try XCTUnwrap(moves.first { $0["moveID"] as? String == "MOVE_POUND" })
        XCTAssertEqual(pound["isEditable"] as? Bool, true)
        XCTAssertEqual(pound["contestEffect"] as? String, "CONTEST_EFFECT_NONE")
        XCTAssertEqual(pound["isContestEffectEditable"] as? Bool, true)
        XCTAssertEqual(pound["isContestScalarsEditable"] as? Bool, true)
        XCTAssertEqual(pound["isContestComboMovesEditable"] as? Bool, true)
        let contestMetadata = try XCTUnwrap(pound["contestMetadata"] as? [String: Any])
        XCTAssertEqual(contestMetadata["contestEffect"] as? String, "CONTEST_EFFECT_HIGHLY_APPEALING")
        XCTAssertEqual(contestMetadata["contestCategory"] as? String, "CONTEST_CATEGORY_TOUGH")
        XCTAssertEqual(contestMetadata["contestComboStarterId"] as? String, "COMBO_STARTER_POUND")
        XCTAssertEqual(contestMetadata["contestComboMoves"] as? String, "{ COMBO_STARTER_GROWL }")
        let facts = try XCTUnwrap(pound["facts"] as? [[String: Any]])
        XCTAssertTrue(facts.contains { $0["label"] as? String == "contestCategory" && $0["value"] as? String == "CONTEST_CATEGORY_TOUGH" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "contestComboStarterId" && $0["value"] as? String == "COMBO_STARTER_POUND" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "contestComboMoves" && $0["value"] as? String == "{ COMBO_STARTER_GROWL }" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Contest Metadata Readiness" && $0["value"] as? String == "editableSimpleScalarsAndComboMoves" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Move Identity Readiness" && $0["value"] as? String == "constantMatched" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Move Constant Value" && $0["value"] as? String == "1" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Move Constant Source" && $0["value"] as? String == "include/constants/moves.h:2" })
        let sourceSpan = try XCTUnwrap(pound["sourceSpan"] as? [String: Any])
        XCTAssertEqual(sourceSpan["relativePath"] as? String, "src/data/battle_moves.c")
    }

    func testMoveCatalogCommandEmitsExpansionContestScalarJSON() throws {
        let root = try makeExpansionMoveCatalogProject()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["move-catalog", root.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "pokeemeraldExpansion")
        let moves = try XCTUnwrap(result["moves"] as? [[String: Any]])
        let pound = try XCTUnwrap(moves.first { $0["moveID"] as? String == "MOVE_POUND" })
        XCTAssertEqual(pound["flags"] as? [String], ["FLAG_MAKES_CONTACT"])
        XCTAssertEqual(pound["isContestScalarsEditable"] as? Bool, true)
        XCTAssertEqual(pound["isContestComboMovesEditable"] as? Bool, true)
        XCTAssertEqual(pound["isContestEffectEditable"] as? Bool, false)
        let contestMetadata = try XCTUnwrap(pound["contestMetadata"] as? [String: Any])
        XCTAssertEqual(contestMetadata["contestCategory"] as? String, "CONTEST_CATEGORY_TOUGH")
        XCTAssertEqual(contestMetadata["contestAppeal"] as? String, "2")
        XCTAssertEqual(contestMetadata["contestJam"] as? String, "1")
        XCTAssertEqual(contestMetadata["contestComboStarterId"] as? String, "COMBO_STARTER_POUND")
        XCTAssertEqual(contestMetadata["contestComboMoves"] as? String, "{ MOVE_DOUBLE_SLAP, MOVE_MEGA_PUNCH }")
        let facts = try XCTUnwrap(pound["facts"] as? [[String: Any]])
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Contest Metadata Readiness" && $0["value"] as? String == "editableSimpleScalarsAndComboMoves" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Contest Metadata Blocked Actions" && ($0["value"] as? String)?.contains("contestComboMoves arrays") != true })
    }

    func testAssetIndexCommandEmitsExpansionMoveContestResourceFacts() throws {
        let root = try makeExpansionMoveCatalogProject()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["asset-index", root.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "pokeemeraldExpansion")
        let assets = try XCTUnwrap(result["assets"] as? [[String: Any]])
        let pound = try XCTUnwrap(assets.first {
            $0["relativePath"] as? String == "src/data/moves_info.h"
                && $0["title"] as? String == "MOVE_POUND"
        })
        XCTAssertEqual(pound["category"] as? String, "moves")
        let facts = try XCTUnwrap(pound["facts"] as? [[String: Any]])
        XCTAssertTrue(facts.contains { $0["label"] as? String == "contestAppeal" && $0["value"] as? String == "2" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "contestJam" && $0["value"] as? String == "1" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "contestComboStarterId" && $0["value"] as? String == "COMBO_STARTER_POUND" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "contestComboMoves" && $0["value"] as? String == "{ MOVE_DOUBLE_SLAP, MOVE_MEGA_PUNCH }" })
        let readiness = try XCTUnwrap(facts.first { $0["label"] as? String == "Expansion Contest Resource Facts" }?["value"] as? String)
        XCTAssertTrue(readiness.contains("preview-only facts"))
        XCTAssertTrue(readiness.contains("constants"))
        XCTAssertTrue(readiness.contains("generated all_learnables.json writes"))
        XCTAssertTrue(readiness.contains("reference writes"))
        XCTAssertTrue(readiness.contains("ROM/build/export paths"))
        XCTAssertTrue(readiness.contains("binary writes"))
        XCTAssertTrue(readiness.contains("data row creation/removal/reorder"))
    }

    func testTrainerCatalogCommandEmitsRubySapphireEditableJSON() throws {
        let root = try makeRubyTrainerCatalogProject()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["trainer-catalog", root.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "pokeruby")
        let trainers = try XCTUnwrap(result["trainers"] as? [[String: Any]])
        let ruby = try XCTUnwrap(trainers.first { $0["trainerID"] as? String == "TRAINER_RUBY" })
        XCTAssertEqual(ruby["isEditable"] as? Bool, true)
        XCTAssertEqual(ruby["partySize"] as? Int, 1)
        XCTAssertEqual(ruby["partyShape"] as? String, "itemCustomMoves")
        let sourceSpan = try XCTUnwrap(ruby["sourceSpan"] as? [String: Any])
        XCTAssertEqual(sourceSpan["relativePath"] as? String, "src/data/trainers_en.h")
        let partySourceSpan = try XCTUnwrap(ruby["partySourceSpan"] as? [String: Any])
        XCTAssertEqual(partySourceSpan["relativePath"] as? String, "src/data/trainer_parties.h")
    }

    func testItemCatalogCommandEmitsEditableJSON() throws {
        let root = try makeItemCatalogProject()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["item-catalog", root.path, "--json"])
        )

        XCTAssertEqual(result["itemCount"] as? Int, 1)
        XCTAssertNotNil(result["items"])
        XCTAssertNotNil(result["diagnostics"])
    }

    func testItemCatalogCommandEmitsRubySapphireDescriptionJSON() throws {
        let root = try makeRubyItemCatalogProject()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["item-catalog", root.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "pokeruby")
        XCTAssertEqual(result["itemCount"] as? Int, 1)
        let items = try XCTUnwrap(result["items"] as? [[String: Any]])
        let potion = try XCTUnwrap(items.first { $0["itemID"] as? String == "ITEM_POTION" })
        XCTAssertEqual(potion["isEditable"] as? Bool, true)
        XCTAssertEqual(potion["isDescriptionEditable"] as? Bool, true)
        XCTAssertEqual(potion["descriptionSymbol"] as? String, "gItemDescription_Potion")
        XCTAssertEqual(potion["descriptionText"] as? String, "Restores HP.")
        let sourceSpan = try XCTUnwrap(potion["sourceSpan"] as? [String: Any])
        XCTAssertEqual(sourceSpan["relativePath"] as? String, "src/data/items_en.h")
    }

    func testPokemonCompatibilityCommandEmitsPreviewJSON() throws {
        let root = try makeItemCatalogProject()
        try write(Data([0x10, 0x20, 0x30]), to: root.appendingPathComponent("sound/direct_sound_samples/cries/treecko.aif"))
        try write(
            """
            static const u16 sTreeckoFormSpeciesIdTable[] = {
                SPECIES_TREECKO,
                SPECIES_TREECKO_MEGA,
                FORM_SPECIES_END,
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/form_species_tables.h")
        )
        try write(
            """
            static const struct FormChange sTreeckoFormChangeTable[] = {
                { FORM_CHANGE_BATTLE_MEGA_EVOLUTION, SPECIES_TREECKO_MEGA },
                { FORM_CHANGE_TERMINATOR },
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/form_change_tables.h")
        )

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["pokemon-compatibility", root.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "pokeemerald")
        XCTAssertNotNil(result["summary"])
        let entries = try XCTUnwrap(result["entries"] as? [[String: Any]])
        XCTAssertTrue(entries.contains { $0["surface"] as? String == "items" && $0["status"] as? String == "editable" })
        let cries = try XCTUnwrap(entries.first { $0["surface"] as? String == "cries" })
        XCTAssertEqual(cries["status"] as? String, "readOnly")
        let cryAudioPlan = try XCTUnwrap(cries["cryAudioPlan"] as? [String: Any])
        XCTAssertEqual(cryAudioPlan["status"] as? String, "previewOnly")
        let candidateSourcePaths = try XCTUnwrap(cryAudioPlan["candidateSourcePaths"] as? [String])
        XCTAssertEqual(candidateSourcePaths, [
            "sound/direct_sound_samples/cries/*",
            "sound/songs/mus_cry*.s",
            "sound/songs/mus_cry*.inc"
        ])
        let sourceFiles = try XCTUnwrap(cryAudioPlan["sourceFiles"] as? [[String: Any]])
        XCTAssertTrue(sourceFiles.contains { $0["path"] as? String == "sound/direct_sound_samples/cries/treecko.aif" && $0["sha1"] != nil })
        let replacementConstraints = try XCTUnwrap(cryAudioPlan["replacementConstraints"] as? [String])
        XCTAssertTrue(replacementConstraints.contains("Replacement must be one-for-one with the same project-relative path and source kind."))
        XCTAssertTrue(replacementConstraints.contains("Generated audio outputs, build artifacts, ROM targets, binary mutation, playback, and source mutation apply are disabled."))
        let blockedReasons = try XCTUnwrap(cryAudioPlan["blockedReasons"] as? [String])
        XCTAssertEqual(blockedReasons, [])
        let blockedActions = try XCTUnwrap(cryAudioPlan["blockedActions"] as? [String])
        XCTAssertTrue(blockedActions.contains("Generated audio output writes"))
        XCTAssertTrue(blockedActions.contains("Playback"))
        XCTAssertTrue(blockedActions.contains("ROM export"))
        XCTAssertTrue(blockedActions.contains("Binary mutation"))
        XCTAssertTrue(blockedActions.contains("Source mutation apply"))
        let forms = try XCTUnwrap(entries.first { $0["surface"] as? String == "forms" })
        XCTAssertEqual(forms["status"] as? String, "readOnly")
        XCTAssertEqual(forms["sourcePath"] as? String, "src/data/pokemon/form_species_tables.h")
        XCTAssertEqual(forms["tableSymbol"] as? String, "FormSpeciesIdTable/FormChangeTable")
        XCTAssertEqual(forms["indexedCount"] as? Int, 2)
        XCTAssertEqual(forms["readOnlyCount"] as? Int, 2)
        XCTAssertEqual(forms["recommendedFutureRow"] as? String, "PHS-T57E")
        let unsupportedFields = try XCTUnwrap(forms["unsupportedFields"] as? [String])
        XCTAssertTrue(unsupportedFields.contains("form table mutation/apply"))
        XCTAssertTrue(unsupportedFields.contains("binary-only form table writes"))
        let diagnostics = try XCTUnwrap(forms["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "GBA_FORMS_SOURCE_GRAPH_DETECTED" })
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "GBA_FORMS_MUTATION_WORKFLOW_BLOCKED" })
        let sourceTables = try XCTUnwrap(forms["sourceTables"] as? [[String: Any]])
        XCTAssertTrue(sourceTables.contains { $0["path"] as? String == "src/data/pokemon/form_species_tables.h" && $0["indexedCount"] as? Int == 1 && $0["status"] as? String == "readOnly" })
        XCTAssertTrue(sourceTables.contains { $0["path"] as? String == "src/data/pokemon/form_change_tables.h" && $0["indexedCount"] as? Int == 1 && $0["status"] as? String == "readOnly" })
    }

    func testPokemonCompatibilityCommandEmitsModernEmeraldMetadataJSON() throws {
        let root = try makeExpansionCompatibilityProject()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["pokemon-compatibility", root.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "pokeemeraldExpansion")
        let entries = try XCTUnwrap(result["entries"] as? [[String: Any]])
        try assertModernEmeraldSource(
            in: entries,
            surface: "species",
            path: "references/modern-emerald/src/data/pokemon/species_info.h",
            tableSymbol: "gSpeciesInfo",
            diagnosticCode: "GBA_MODERN_EMERALD_SPECIES_UNSUPPORTED"
        )
        try assertModernEmeraldSource(
            in: entries,
            surface: "species",
            path: "references/modern-emerald/include/constants/species.h",
            diagnosticCode: "GBA_MODERN_EMERALD_SPECIES_UNSUPPORTED"
        )
        try assertModernEmeraldSource(
            in: entries,
            surface: "species",
            path: "references/modern-emerald/include/constants/pokemon.h",
            diagnosticCode: "GBA_MODERN_EMERALD_SPECIES_UNSUPPORTED"
        )
        try assertModernEmeraldSource(
            in: entries,
            surface: "species",
            path: "references/modern-emerald/include/config.h",
            diagnosticCode: "GBA_MODERN_EMERALD_SPECIES_UNSUPPORTED"
        )
        try assertModernEmeraldSource(
            in: entries,
            surface: "species",
            path: "references/modern-emerald/graphics/pokemon",
            tableSymbol: "species graphics/icon paths",
            diagnosticCode: "GBA_MODERN_EMERALD_SPECIES_UNSUPPORTED"
        )
        try assertModernEmeraldSource(
            in: entries,
            surface: "moves",
            path: "references/modern-emerald/src/data/battle_moves.h",
            tableSymbol: "gBattleMoves",
            diagnosticCode: "GBA_MODERN_EMERALD_MOVES_UNSUPPORTED"
        )
        try assertModernEmeraldSource(
            in: entries,
            surface: "moves",
            path: "references/modern-emerald/include/constants/moves.h",
            diagnosticCode: "GBA_MODERN_EMERALD_MOVES_UNSUPPORTED"
        )
        try assertModernEmeraldSource(
            in: entries,
            surface: "moves",
            path: "references/modern-emerald/include/config.h",
            diagnosticCode: "GBA_MODERN_EMERALD_MOVES_UNSUPPORTED"
        )
        try assertModernEmeraldSource(
            in: entries,
            surface: "moves",
            path: "references/modern-emerald/src/data/pokemon/tmhm_learnsets.h",
            tableSymbol: "gTMHMLearnsets",
            diagnosticCode: "GBA_MODERN_EMERALD_MOVES_UNSUPPORTED"
        )
        try assertModernEmeraldSource(
            in: entries,
            surface: "moves",
            path: "references/modern-emerald/src/data/pokemon/tutor_learnsets.h",
            tableSymbol: "gTutorLearnsets",
            diagnosticCode: "GBA_MODERN_EMERALD_MOVES_UNSUPPORTED"
        )
        try assertModernEmeraldSource(
            in: entries,
            surface: "levelUpLearnsets",
            path: "references/modern-emerald/src/data/pokemon/level_up_learnsets.h",
            tableSymbol: "s*LevelUpLearnset"
        )
        try assertModernEmeraldSource(
            in: entries,
            surface: "tmhmLearnsets",
            path: "references/modern-emerald/src/data/pokemon/tmhm_learnsets.h",
            tableSymbol: "gTMHMLearnsets"
        )
        try assertModernEmeraldSource(
            in: entries,
            surface: "tutorLearnsets",
            path: "references/modern-emerald/src/data/pokemon/tutor_learnsets.h",
            tableSymbol: "gTutorMoves/s*TutorLearnset"
        )
        try assertModernEmeraldSource(
            in: entries,
            surface: "eggMoves",
            path: "references/modern-emerald/src/data/pokemon/egg_moves.h",
            tableSymbol: "gEggMoves"
        )
        try assertModernEmeraldSource(
            in: entries,
            surface: "items",
            path: "references/modern-emerald/src/data/items.h",
            tableSymbol: "gItems",
            diagnosticCode: "GBA_MODERN_EMERALD_ITEMS_UNSUPPORTED"
        )
        try assertModernEmeraldSource(
            in: entries,
            surface: "items",
            path: "references/modern-emerald/include/constants/items.h",
            diagnosticCode: "GBA_MODERN_EMERALD_ITEMS_UNSUPPORTED"
        )
        try assertModernEmeraldSource(
            in: entries,
            surface: "items",
            path: "references/modern-emerald/include/config.h",
            diagnosticCode: "GBA_MODERN_EMERALD_ITEMS_UNSUPPORTED"
        )
        try assertModernEmeraldSource(
            in: entries,
            surface: "items",
            path: "references/modern-emerald/src/data/graphics/items.h",
            tableSymbol: "item graphics metadata",
            diagnosticCode: "GBA_MODERN_EMERALD_ITEMS_UNSUPPORTED"
        )
        try assertModernEmeraldSource(
            in: entries,
            surface: "items",
            path: "references/modern-emerald/graphics/items/icons",
            tableSymbol: "item icon PNG paths",
            diagnosticCode: "GBA_MODERN_EMERALD_ITEMS_UNSUPPORTED"
        )
        try assertModernEmeraldSource(
            in: entries,
            surface: "items",
            path: "references/modern-emerald/graphics/items/icon_palettes",
            tableSymbol: "item icon palette paths",
            diagnosticCode: "GBA_MODERN_EMERALD_ITEMS_UNSUPPORTED"
        )
    }

    func testPokemonCompatibilityCommandEmitsExpansionItemEffectIconEditableJSON() throws {
        let root = try makeExpansionCompatibilityProject()
        try writeExpansionItemInfo(at: root)

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["pokemon-compatibility", root.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "pokeemeraldExpansion")
        let entries = try XCTUnwrap(result["entries"] as? [[String: Any]])
        let items = try XCTUnwrap(entries.first { $0["surface"] as? String == "items" })
        let sourceTables = try XCTUnwrap(items["sourceTables"] as? [[String: Any]])
        let effectIconSource = try XCTUnwrap(sourceTables.first {
            $0["path"] as? String == "src/data/items.h"
                && $0["tableSymbol"] as? String == "gItemsInfo .effect/.iconPic/.iconPalette"
        })
        XCTAssertEqual(effectIconSource["status"] as? String, "editable")
        XCTAssertEqual(effectIconSource["indexedCount"] as? Int, 1)
        XCTAssertEqual(effectIconSource["sourceRole"] as? String, "editableSourceFields")
        XCTAssertEqual(effectIconSource["readiness"] as? String, "editable existing source fields")
        XCTAssertEqual(effectIconSource["blockedActions"] as? [String], [
            "icon asset rewrites",
            "generated output writes",
            "Modern Emerald writes",
            "ROM/build/export paths",
            "identity edits"
        ])
    }

    func testPokemonCompatibilityCommandEmitsExpansionItemBehaviorScalarsEditableJSON() throws {
        let root = try makeExpansionCompatibilityProject()
        try writeExpansionItemInfo(at: root)

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["pokemon-compatibility", root.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "pokeemeraldExpansion")
        let entries = try XCTUnwrap(result["entries"] as? [[String: Any]])
        let items = try XCTUnwrap(entries.first { $0["surface"] as? String == "items" })
        let sourceTables = try XCTUnwrap(items["sourceTables"] as? [[String: Any]])
        let behaviorSource = try XCTUnwrap(sourceTables.first {
            $0["path"] as? String == "src/data/items.h"
                && $0["tableSymbol"] as? String == "gItemsInfo .fieldUseFunc/.battleUsage/.battleUseFunc/.secondaryId"
        })
        XCTAssertEqual(behaviorSource["status"] as? String, "editable")
        XCTAssertEqual(behaviorSource["indexedCount"] as? Int, 1)
        XCTAssertEqual(behaviorSource["sourceRole"] as? String, "editableBehaviorScalars")
        XCTAssertEqual(behaviorSource["readiness"] as? String, "editable existing behavior/function scalar fields; complete missing group insertion is anchor-gated")
        XCTAssertEqual(behaviorSource["blockedActions"] as? [String], [
            "constants-file edits/creation",
            "partial missing-field insertion/removal",
            "row insertion/removal/reorder",
            "generated outputs",
            "reference writes",
            "ROM/build/export paths",
            "binary writes",
            "broad schema rewrites"
        ])
    }

    func testPokemonCompatibilityCommandEmitsExpansionItemUsageScalarsEditableJSON() throws {
        let root = try makeExpansionCompatibilityProject()
        try writeExpansionItemInfo(at: root)

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["pokemon-compatibility", root.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "pokeemeraldExpansion")
        let entries = try XCTUnwrap(result["entries"] as? [[String: Any]])
        let items = try XCTUnwrap(entries.first { $0["surface"] as? String == "items" })
        let sourceTables = try XCTUnwrap(items["sourceTables"] as? [[String: Any]])
        let usageSource = try XCTUnwrap(sourceTables.first {
            $0["path"] as? String == "src/data/items.h"
                && $0["tableSymbol"] as? String == "gItemsInfo .holdEffect/.holdEffectParam/.pocket/.type"
        })
        XCTAssertEqual(usageSource["status"] as? String, "editable")
        XCTAssertEqual(usageSource["indexedCount"] as? Int, 1)
        XCTAssertEqual(usageSource["sourceRole"] as? String, "editableUsageScalars")
        XCTAssertEqual(usageSource["readiness"] as? String, "editable existing usage/classification scalar fields; complete missing group insertion is anchor-gated")
        XCTAssertEqual(usageSource["blockedActions"] as? [String], [
            "constants-file edits/creation",
            "partial missing-field insertion/removal",
            "row insertion/removal/reorder",
            "generated outputs",
            "reference writes",
            "ROM/build/export paths",
            "binary writes",
            "broad schema rewrites"
        ])
    }

    func testPokemonCompatibilityCommandEmitsExpansionItemBagClassificationScalarsEditableJSON() throws {
        let root = try makeExpansionCompatibilityProject()
        try writeExpansionItemInfo(at: root)

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["pokemon-compatibility", root.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "pokeemeraldExpansion")
        let entries = try XCTUnwrap(result["entries"] as? [[String: Any]])
        let items = try XCTUnwrap(entries.first { $0["surface"] as? String == "items" })
        let sourceTables = try XCTUnwrap(items["sourceTables"] as? [[String: Any]])
        let bagClassificationSource = try XCTUnwrap(sourceTables.first {
            $0["path"] as? String == "src/data/items.h"
                && $0["tableSymbol"] as? String == "gItemsInfo .importance/.registrability/.sortType/.exitsBagOnUse"
        })
        XCTAssertEqual(bagClassificationSource["status"] as? String, "editable")
        XCTAssertEqual(bagClassificationSource["indexedCount"] as? Int, 1)
        XCTAssertEqual(bagClassificationSource["sourceRole"] as? String, "editableBagClassificationScalars")
        XCTAssertEqual(bagClassificationSource["readiness"] as? String, "editable existing bag/classification scalar fields")
        XCTAssertEqual(bagClassificationSource["blockedActions"] as? [String], [
            "constants-file edits/creation",
            "missing-field insertion",
            "row insertion/removal/reorder",
            "generated outputs",
            "reference writes",
            "ROM/build/export paths",
            "binary writes",
            "broad schema rewrites"
        ])
    }

    func testPokemonCompatibilityAndAssetIndexCommandsEmitExpansionAllLearnablesFacts() throws {
        let root = try makeExpansionAllLearnablesProject()
        let expectedRelatedSourcePaths = [
            "src/data/pokemon/level_up_learnsets.h",
            "src/data/pokemon/level_up_learnsets",
            "src/data/pokemon/tmhm_learnsets.h",
            "src/data/pokemon/tutor_learnsets.h",
            "src/data/pokemon/egg_moves.h"
        ]
        let expectedBlockedActions = [
            "apply",
            "generated output writes",
            "reference writes",
            "ROM/binary writes"
        ]

        let compatibility = try decodeJSON(
            PokemonHackCLI.run(arguments: ["pokemon-compatibility", root.path, "--json"])
        )

        XCTAssertEqual(compatibility["profile"] as? String, "pokeemeraldExpansion")
        let entries = try XCTUnwrap(compatibility["entries"] as? [[String: Any]])
        var firstAllLearnablesSourceTable: [String: Any]?
        for surface in ["levelUpLearnsets", "tmhmLearnsets", "tutorLearnsets", "eggMoves"] {
            let entry = try XCTUnwrap(entries.first { $0["surface"] as? String == surface })
            let sourceTable = try assertAllLearnablesSourceTable(
                in: entry,
                expectedRelatedSourcePaths: expectedRelatedSourcePaths,
                expectedBlockedActions: expectedBlockedActions,
                expectedMatchingSpeciesCount: 0,
                expectedMismatchSpeciesCount: 1,
                expectedMoveMismatchSpeciesCount: 1,
                expectedDisagreementCount: 1
            )
            firstAllLearnablesSourceTable = firstAllLearnablesSourceTable ?? sourceTable
        }
        let coverage = try XCTUnwrap(firstAllLearnablesSourceTable?["learnablesCoverage"] as? [String: Any])
        XCTAssertEqual(coverage["staleSourcePaths"] as? [String], [])
        let regenerationPlan = try XCTUnwrap(coverage["regenerationPlan"] as? [String: Any])
        XCTAssertEqual(regenerationPlan["posture"] as? String, "copyReportOnly")
        XCTAssertEqual(regenerationPlan["generatedPath"] as? String, "src/data/pokemon/all_learnables.json")
        XCTAssertEqual(regenerationPlan["sourceBuckets"] as? [String], ["levelUp", "tmhm", "tutor", "egg"])
        let bucketPaths = try XCTUnwrap(regenerationPlan["bucketPaths"] as? [[String: Any]])
        XCTAssertEqual(bucketPaths.compactMap { $0["bucket"] as? String }, ["levelUp", "tmhm", "tutor", "egg"])
        XCTAssertEqual(bucketPaths.flatMap { ($0["paths"] as? [String]) ?? [] }, expectedRelatedSourcePaths)
        XCTAssertEqual(regenerationPlan["generatedOnlyMoveIDs"] as? [String], ["MOVE_QUICK_ATTACK"])
        XCTAssertEqual(regenerationPlan["sourceOnlyMoveIDs"] as? [String], ["MOVE_MEGA_PUNCH"])
        XCTAssertEqual(regenerationPlan["reportCommands"] as? [String], [
            "swift run --package-path PokemonHackStudio pokemonhack-cli pokemon-compatibility <project-root> --json",
            "swift run --package-path PokemonHackStudio pokemonhack-cli asset-index <project-root> --json"
        ])
        XCTAssertTrue((regenerationPlan["reviewGuidance"] as? String)?.contains("outside PokemonHackStudio") == true)
        XCTAssertTrue((regenerationPlan["reviewGuidance"] as? String)?.contains("will not run regeneration") == true)
        let reviewItems = try XCTUnwrap(regenerationPlan["reviewItems"] as? [[String: Any]])
        let reviewItem = try XCTUnwrap(reviewItems.first)
        XCTAssertEqual(reviewItem["speciesID"] as? String, "SPECIES_TREECKO")
        XCTAssertEqual(reviewItem["status"] as? String, "moveMismatch")
        XCTAssertEqual(reviewItem["generatedOnlyMoves"] as? [String], ["MOVE_QUICK_ATTACK"])
        let reviewSourceOnlyMoves = try XCTUnwrap(reviewItem["sourceOnlyMoves"] as? [[String: Any]])
        let reviewSourceOnlyMove = try XCTUnwrap(reviewSourceOnlyMoves.first)
        XCTAssertEqual(reviewSourceOnlyMove["move"] as? String, "MOVE_MEGA_PUNCH")
        XCTAssertEqual(reviewSourceOnlyMove["bucket"] as? String, "tutor")
        let reviewSourceSpan = try XCTUnwrap(reviewSourceOnlyMove["sourceSpan"] as? [String: Any])
        XCTAssertEqual(reviewSourceSpan["relativePath"] as? String, "src/data/pokemon/tutor_learnsets.h")
        XCTAssertEqual(reviewSourceSpan["startLine"] as? Int, 3)
        let disagreements = try XCTUnwrap(coverage["disagreements"] as? [[String: Any]])
        let disagreement = try XCTUnwrap(disagreements.first)
        XCTAssertEqual(disagreement["speciesID"] as? String, "SPECIES_TREECKO")
        XCTAssertEqual(disagreement["status"] as? String, "moveMismatch")
        XCTAssertEqual(disagreement["generatedOnlyMoves"] as? [String], ["MOVE_QUICK_ATTACK"])
        XCTAssertEqual(disagreement["contributingSourcePaths"] as? [String], ["src/data/pokemon/tutor_learnsets.h"])
        let sourceOnlyMoves = try XCTUnwrap(disagreement["sourceOnlyMoves"] as? [[String: Any]])
        let sourceOnlyMove = try XCTUnwrap(sourceOnlyMoves.first)
        XCTAssertEqual(sourceOnlyMove["move"] as? String, "MOVE_MEGA_PUNCH")
        XCTAssertEqual(sourceOnlyMove["bucket"] as? String, "tutor")
        let sourceSpan = try XCTUnwrap(sourceOnlyMove["sourceSpan"] as? [String: Any])
        XCTAssertEqual(sourceSpan["relativePath"] as? String, "src/data/pokemon/tutor_learnsets.h")
        XCTAssertEqual(sourceSpan["startLine"] as? Int, 3)

        let assetCatalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["asset-index", root.path, "--json"])
        )
        let assets = try XCTUnwrap(assetCatalog["assets"] as? [[String: Any]])
        let allLearnablesAsset = try XCTUnwrap(assets.first {
            $0["relativePath"] as? String == "src/data/pokemon/all_learnables.json"
                && $0["title"] as? String == "SPECIES_TREECKO"
        })
        XCTAssertEqual(allLearnablesAsset["category"] as? String, "learnsets")
        let facts = try XCTUnwrap(allLearnablesAsset["facts"] as? [[String: Any]])
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Expansion Learnset Source Role" && $0["value"] as? String == "generatedAllLearnablesIndex" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Generated From" && $0["value"] as? String == "level-up, TM/HM, tutor, egg learnsets" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Readiness" && $0["value"] as? String == "read-only generated context" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Blocked Actions" && $0["value"] as? String == "apply; generated output writes; reference writes; ROM/binary writes" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Coverage Status" && $0["value"] as? String == "moveMismatch" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Parsed Source Moves" && $0["value"] as? String == "4" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Missing Generated Moves" && $0["value"] as? String == "1" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Extra Generated Moves" && $0["value"] as? String == "1" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Missing Generated Move IDs" && $0["value"] as? String == "MOVE_MEGA_PUNCH" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Extra Generated Move IDs" && $0["value"] as? String == "MOVE_QUICK_ATTACK" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Generated Species" && $0["value"] as? String == "1" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Parsed Source Species" && $0["value"] as? String == "1" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Coverage Matches" && $0["value"] as? String == "0" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Coverage Mismatches" && $0["value"] as? String == "1" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Generated-only Species" && $0["value"] as? String == "0" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Source-only Species" && $0["value"] as? String == "0" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Move-set Mismatches" && $0["value"] as? String == "1" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Stale Source Files" && $0["value"] as? String == "0" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Regeneration Posture" && $0["value"] as? String == "copy/report-only; no generated JSON writes or command execution" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Regeneration Source Buckets" && $0["value"] as? String == "levelUp, tmhm, tutor, egg" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Regeneration Source-only Move IDs" && $0["value"] as? String == "MOVE_MEGA_PUNCH" })
        XCTAssertTrue(facts.contains { $0["label"] as? String == "Regeneration Generated-only Move IDs" && $0["value"] as? String == "MOVE_QUICK_ATTACK" })
        XCTAssertTrue(facts.contains { ($0["label"] as? String) == "Regeneration Report Commands" && (($0["value"] as? String)?.contains("asset-index <project-root> --json") == true) })
        XCTAssertTrue(facts.contains { ($0["label"] as? String) == "Regeneration Guidance" && (($0["value"] as? String)?.contains("will not run regeneration") == true) })
    }

    func testPokemonCompatibilityCommandEmitsCryAudioBlockedJSON() throws {
        let root = try makeItemCatalogProject()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["pokemon-compatibility", root.path, "--json"])
        )

        let entries = try XCTUnwrap(result["entries"] as? [[String: Any]])
        let cries = try XCTUnwrap(entries.first { $0["surface"] as? String == "cries" })
        XCTAssertEqual(cries["status"] as? String, "blocked")
        XCTAssertEqual(
            cries["blockedReason"] as? String,
            "No existing local files matched sound/direct_sound_samples/cries/*. No existing local files matched sound/songs/mus_cry*.s or sound/songs/mus_cry*.inc."
        )
        let cryAudioPlan = try XCTUnwrap(cries["cryAudioPlan"] as? [String: Any])
        XCTAssertEqual(cryAudioPlan["status"] as? String, "blocked")
        let candidateSourcePaths = try XCTUnwrap(cryAudioPlan["candidateSourcePaths"] as? [String])
        XCTAssertEqual(candidateSourcePaths, [
            "sound/direct_sound_samples/cries/*",
            "sound/songs/mus_cry*.s",
            "sound/songs/mus_cry*.inc"
        ])
        let replacementConstraints = try XCTUnwrap(cryAudioPlan["replacementConstraints"] as? [String])
        XCTAssertTrue(replacementConstraints.contains("Replacement is future-only and must target an existing local source file reported in sourceFiles."))
        XCTAssertTrue(replacementConstraints.contains("Missing cry source insertion and directory creation are disabled."))
        let blockedReasons = try XCTUnwrap(cryAudioPlan["blockedReasons"] as? [String])
        XCTAssertEqual(blockedReasons, [
            "No existing local files matched sound/direct_sound_samples/cries/*.",
            "No existing local files matched sound/songs/mus_cry*.s or sound/songs/mus_cry*.inc."
        ])
        let blockedActions = try XCTUnwrap(cryAudioPlan["blockedActions"] as? [String])
        XCTAssertTrue(blockedActions.contains("Audio conversion"))
        XCTAssertTrue(blockedActions.contains("Generated audio output writes"))
        XCTAssertTrue(blockedActions.contains("Playback"))
        XCTAssertTrue(blockedActions.contains("ROM export"))
        XCTAssertTrue(blockedActions.contains("Binary mutation"))
        XCTAssertTrue(blockedActions.contains("Source mutation apply"))
    }

    func testPokemonCompatibilityCommandEmitsRubySapphireMovesEditableJSON() throws {
        let root = try makeRubyMoveCatalogProject()
        try write(
            """
            #define TUTOR_POUND 0

            const u16 sTutorLearnsets[] =
            {
                [SPECIES_TREECKO] = TUTOR(POUND),
            };

            """,
            to: root.appendingPathComponent("src/data/pokemon/tutor_learnsets.h")
        )

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["pokemon-compatibility", root.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "pokeruby")
        let entries = try XCTUnwrap(result["entries"] as? [[String: Any]])
        let moves = try XCTUnwrap(entries.first { $0["surface"] as? String == "moves" })
        XCTAssertEqual(moves["status"] as? String, "editable")
        XCTAssertEqual(moves["sourcePath"] as? String, "src/data/battle_moves.c")
        XCTAssertEqual(moves["tableSymbol"] as? String, "gBattleMoves")
        XCTAssertEqual(moves["editableCount"] as? Int, 1)
        XCTAssertNil(moves["recommendedFutureRow"])
        let unsupportedFields = try XCTUnwrap(moves["unsupportedFields"] as? [String])
        XCTAssertFalse(unsupportedFields.contains("description text rewrites"))
        XCTAssertFalse(unsupportedFields.contains("contest data"))
        XCTAssertFalse(unsupportedFields.contains("contest data beyond existing .contestEffect"))
        XCTAssertTrue(unsupportedFields.contains("missing or non-simple contest combo arrays and non-simple contest scalar expressions"))
        XCTAssertFalse(unsupportedFields.contains("TM/HM/tutor compatibility edits"))
        XCTAssertFalse(unsupportedFields.contains("tutor compatibility edits"))
        XCTAssertTrue(unsupportedFields.contains("TM/HM item mapping edits"))
        XCTAssertTrue(unsupportedFields.contains("machine constant creation"))
        XCTAssertTrue(unsupportedFields.contains("missing TM/HM row insertion"))
        XCTAssertTrue(unsupportedFields.contains("tutor constant creation"))
        XCTAssertTrue(unsupportedFields.contains("missing tutor row insertion"))
        XCTAssertTrue(unsupportedFields.contains("generated move output writes"))
        XCTAssertTrue(unsupportedFields.contains("reference-only move source writes"))
        XCTAssertTrue(unsupportedFields.contains("binary ROM move writes"))
        let sourceTables = try XCTUnwrap(moves["sourceTables"] as? [[String: Any]])
        XCTAssertTrue(sourceTables.contains { $0["path"] as? String == "src/data/battle_moves.c" && $0["tableSymbol"] as? String == ".contestEffect" && $0["status"] as? String == "editable" })
        let moveConstants = try XCTUnwrap(sourceTables.first { $0["path"] as? String == "include/constants/moves.h" && $0["tableSymbol"] as? String == "MOVE_*" })
        XCTAssertEqual(moveConstants["status"] as? String, "readOnly")
        XCTAssertEqual(moveConstants["indexedCount"] as? Int, 4)
        XCTAssertEqual(moveConstants["sourceRole"] as? String, "readOnlyMoveConstants")
        XCTAssertEqual(moveConstants["readiness"] as? String, "read-only 4 MOVE_* constants indexed")
        let constantsBlockedActions = try XCTUnwrap(moveConstants["blockedActions"] as? [String])
        XCTAssertTrue(constantsBlockedActions.contains("constant creation"))
        XCTAssertTrue(constantsBlockedActions.contains("constant rename"))
        XCTAssertTrue(constantsBlockedActions.contains("row insertion/removal/reorder"))
        let tmhmLearnsets = try XCTUnwrap(sourceTables.first { $0["path"] as? String == "src/data/pokemon/tmhm_learnsets.h" && $0["tableSymbol"] as? String == "gTMHMLearnsets" })
        XCTAssertEqual(tmhmLearnsets["status"] as? String, "editable")
        XCTAssertEqual(tmhmLearnsets["indexedCount"] as? Int, 1)
        XCTAssertEqual(tmhmLearnsets["sourceRole"] as? String, "editableTMHMLearnsets")
        XCTAssertEqual(tmhmLearnsets["readiness"] as? String, "editable existing gTMHMLearnsets rows")
        let tmhmBlockedActions = try XCTUnwrap(tmhmLearnsets["blockedActions"] as? [String])
        XCTAssertTrue(tmhmBlockedActions.contains("TM/HM item mapping edits"))
        XCTAssertTrue(tmhmBlockedActions.contains("machine constant creation"))
        XCTAssertTrue(tmhmBlockedActions.contains("missing TM/HM row insertion"))
        XCTAssertTrue(tmhmBlockedActions.contains("row insertion/removal/reorder"))
        XCTAssertTrue(tmhmBlockedActions.contains("generated writes"))
        XCTAssertTrue(tmhmBlockedActions.contains("reference writes"))
        XCTAssertTrue(tmhmBlockedActions.contains("ROM writes"))
        XCTAssertTrue(tmhmBlockedActions.contains("binary writes"))
        let tutorLearnsets = try XCTUnwrap(sourceTables.first { $0["path"] as? String == "src/data/pokemon/tutor_learnsets.h" && $0["tableSymbol"] as? String == "sTutorLearnsets/gTutorLearnsets" })
        XCTAssertEqual(tutorLearnsets["status"] as? String, "editable")
        XCTAssertEqual(tutorLearnsets["indexedCount"] as? Int, 1)
        XCTAssertEqual(tutorLearnsets["sourceRole"] as? String, "editableTutorLearnsets")
        XCTAssertEqual(tutorLearnsets["readiness"] as? String, "editable existing sTutorLearnsets/gTutorLearnsets rows")
        let tutorBlockedActions = try XCTUnwrap(tutorLearnsets["blockedActions"] as? [String])
        XCTAssertTrue(tutorBlockedActions.contains("move constant creation"))
        XCTAssertTrue(tutorBlockedActions.contains("tutor constant creation"))
        XCTAssertTrue(tutorBlockedActions.contains("missing tutor row insertion"))
        XCTAssertTrue(tutorBlockedActions.contains("row insertion/removal/reorder"))
        XCTAssertTrue(tutorBlockedActions.contains("generated writes"))
        XCTAssertTrue(tutorBlockedActions.contains("reference writes"))
        XCTAssertTrue(tutorBlockedActions.contains("ROM writes"))
        XCTAssertTrue(tutorBlockedActions.contains("binary writes"))
        let eggMoves = try XCTUnwrap(sourceTables.first { $0["path"] as? String == "src/data/pokemon/egg_moves.h" && $0["tableSymbol"] as? String == "gEggMoves" })
        XCTAssertEqual(eggMoves["status"] as? String, "editable")
        XCTAssertEqual(eggMoves["indexedCount"] as? Int, 1)
        XCTAssertEqual(eggMoves["sourceRole"] as? String, "editableEggMoves")
        XCTAssertEqual(eggMoves["readiness"] as? String, "editable existing gEggMoves rows")
        let eggBlockedActions = try XCTUnwrap(eggMoves["blockedActions"] as? [String])
        XCTAssertTrue(eggBlockedActions.contains("move constant creation"))
        XCTAssertTrue(eggBlockedActions.contains("move identity changes"))
        XCTAssertTrue(eggBlockedActions.contains("missing egg-move species row insertion"))
        XCTAssertTrue(eggBlockedActions.contains("family reshaping"))
        XCTAssertTrue(eggBlockedActions.contains("row insertion/removal/reorder"))
        XCTAssertTrue(eggBlockedActions.contains("generated writes"))
        XCTAssertTrue(eggBlockedActions.contains("reference writes"))
        XCTAssertTrue(eggBlockedActions.contains("ROM writes"))
        XCTAssertTrue(eggBlockedActions.contains("binary writes"))
        XCTAssertTrue(sourceTables.contains { $0["path"] as? String == "generated" && $0["status"] as? String == "blocked" })
        XCTAssertTrue(sourceTables.contains { $0["path"] as? String == "references/pokeruby/src/data/battle_moves.c" && $0["status"] as? String == "blocked" })
        XCTAssertTrue(sourceTables.contains { $0["path"] as? String == "ROM output" && $0["status"] as? String == "blocked" })
        let contestMoves = try XCTUnwrap(sourceTables.first { $0["path"] as? String == "src/data/contest_moves.h" && $0["tableSymbol"] as? String == "gContestMoves" })
        XCTAssertEqual(contestMoves["status"] as? String, "editable")
        XCTAssertEqual(contestMoves["indexedCount"] as? Int, 1)
        XCTAssertEqual(contestMoves["sourceRole"] as? String, "editableContestScalarsAndComboMoves")
        XCTAssertEqual(contestMoves["readiness"] as? String, "editable existing simple scalar fields and combo arrays")
        let blockedActions = try XCTUnwrap(contestMoves["blockedActions"] as? [String])
        XCTAssertFalse(blockedActions.contains("combo array editing"))
        XCTAssertTrue(blockedActions.contains("constants"))
        XCTAssertTrue(blockedActions.contains("missing-field insertion"))
        XCTAssertTrue(blockedActions.contains("row insertion/removal/reorder"))
        XCTAssertTrue(blockedActions.contains("generated writes"))
        XCTAssertTrue(blockedActions.contains("reference writes"))
        XCTAssertTrue(blockedActions.contains("ROM writes"))
        XCTAssertTrue(blockedActions.contains("binary writes"))
    }

    func testPokemonCompatibilityCommandEmitsExpansionContestScalarsEditableJSON() throws {
        let root = try makeExpansionMoveCatalogProject()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["pokemon-compatibility", root.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "pokeemeraldExpansion")
        let entries = try XCTUnwrap(result["entries"] as? [[String: Any]])
        let moves = try XCTUnwrap(entries.first { $0["surface"] as? String == "moves" })
        XCTAssertEqual(moves["status"] as? String, "editable")
        XCTAssertEqual(moves["sourcePath"] as? String, "src/data/moves_info.h")
        XCTAssertEqual(moves["tableSymbol"] as? String, "gMovesInfo")
        XCTAssertEqual(moves["editableCount"] as? Int, 1)
        let unsupportedFields = try XCTUnwrap(moves["unsupportedFields"] as? [String])
        XCTAssertFalse(unsupportedFields.contains("contest data"))
        XCTAssertTrue(unsupportedFields.contains("gMovesInfo non-simple contest scalar expressions"))
        XCTAssertTrue(unsupportedFields.contains("gMovesInfo non-simple contest combo move arrays"))
        XCTAssertTrue(unsupportedFields.contains("generated move output writes"))
        XCTAssertTrue(unsupportedFields.contains("reference-only move source writes"))
        XCTAssertTrue(unsupportedFields.contains("binary ROM move writes"))
        let sourceTables = try XCTUnwrap(moves["sourceTables"] as? [[String: Any]])
        let flags = try XCTUnwrap(sourceTables.first { $0["path"] as? String == "src/data/moves_info.h" && $0["tableSymbol"] as? String == "gMovesInfo flags" })
        XCTAssertEqual(flags["status"] as? String, "editable")
        XCTAssertEqual(flags["indexedCount"] as? Int, 1)
        XCTAssertEqual(flags["sourceRole"] as? String, "editableFlags")
        XCTAssertEqual(flags["readiness"] as? String, "editable existing or missing simple FLAG_* field values")
        let flagBlockedActions = try XCTUnwrap(flags["blockedActions"] as? [String])
        XCTAssertTrue(flagBlockedActions.contains("constant creation"))
        XCTAssertTrue(flagBlockedActions.contains("non-simple flags expressions"))
        XCTAssertTrue(flagBlockedActions.contains("row insertion/removal/reorder"))
        XCTAssertTrue(flagBlockedActions.contains("generated outputs"))
        XCTAssertTrue(flagBlockedActions.contains("reference writes"))
        XCTAssertTrue(flagBlockedActions.contains("ROM/build/export paths"))
        XCTAssertTrue(flagBlockedActions.contains("binary writes"))
        let contestScalars = try XCTUnwrap(sourceTables.first { $0["path"] as? String == "src/data/moves_info.h" && $0["tableSymbol"] as? String == "gMovesInfo contest scalars" })
        XCTAssertEqual(contestScalars["status"] as? String, "editable")
        XCTAssertEqual(contestScalars["sourceRole"] as? String, "editableContestScalars")
        XCTAssertEqual(contestScalars["readiness"] as? String, "editable existing simple scalar fields")
        let blockedActions = try XCTUnwrap(contestScalars["blockedActions"] as? [String])
        XCTAssertTrue(blockedActions.contains("constants"))
        XCTAssertTrue(blockedActions.contains("missing-field insertion"))
        XCTAssertTrue(blockedActions.contains("row insertion/removal/reorder"))
        XCTAssertTrue(blockedActions.contains("generated outputs"))
        XCTAssertTrue(blockedActions.contains("reference writes"))
        XCTAssertTrue(blockedActions.contains("ROM/binary writes"))
        let contestCombos = try XCTUnwrap(sourceTables.first { $0["path"] as? String == "src/data/moves_info.h" && $0["tableSymbol"] as? String == "gMovesInfo contest combo moves" })
        XCTAssertEqual(contestCombos["status"] as? String, "editable")
        XCTAssertEqual(contestCombos["indexedCount"] as? Int, 1)
        XCTAssertEqual(contestCombos["sourceRole"] as? String, "editableContestComboMoves")
        XCTAssertEqual(contestCombos["readiness"] as? String, "editable existing simple MOVE_* arrays")
        let comboBlockedActions = try XCTUnwrap(contestCombos["blockedActions"] as? [String])
        XCTAssertTrue(comboBlockedActions.contains("constants"))
        XCTAssertTrue(comboBlockedActions.contains("missing-field insertion"))
        XCTAssertTrue(comboBlockedActions.contains("row insertion/removal/reorder"))
        XCTAssertTrue(comboBlockedActions.contains("generated outputs"))
        XCTAssertTrue(comboBlockedActions.contains("reference writes"))
        XCTAssertTrue(comboBlockedActions.contains("ROM/build/export paths"))
        XCTAssertTrue(comboBlockedActions.contains("binary writes"))
        XCTAssertTrue(sourceTables.contains { $0["path"] as? String == "src/data/contest_moves.h" && $0["status"] as? String == "blocked" })
        XCTAssertTrue(sourceTables.contains { $0["path"] as? String == "generated" && $0["status"] as? String == "blocked" })
        XCTAssertTrue(sourceTables.contains { $0["path"] as? String == "references/pokeemerald-expansion/src/data/moves_info.h" && $0["status"] as? String == "blocked" })
        XCTAssertTrue(sourceTables.contains { $0["path"] as? String == "ROM output" && $0["status"] as? String == "blocked" })
    }

    func testPokemonCompatibilityCommandEmitsExpansionTutorCompatibilityEditableFromMovesJSON() throws {
        let root = try makeExpansionMoveCatalogProject()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["pokemon-compatibility", root.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "pokeemeraldExpansion")
        let entries = try XCTUnwrap(result["entries"] as? [[String: Any]])
        let moves = try XCTUnwrap(entries.first { $0["surface"] as? String == "moves" })
        let unsupportedFields = try XCTUnwrap(moves["unsupportedFields"] as? [String])
        XCTAssertFalse(unsupportedFields.contains("TM/HM/tutor compatibility edits"))
        XCTAssertTrue(unsupportedFields.contains("TM/HM compatibility edits from move row plans"))
        XCTAssertTrue(unsupportedFields.contains("egg compatibility edits from move row plans"))
        XCTAssertTrue(unsupportedFields.contains("tutor constant creation"))
        XCTAssertTrue(unsupportedFields.contains("missing tutor row insertion"))
        XCTAssertTrue(unsupportedFields.contains("generated all_learnables.json writes"))

        let sourceTables = try XCTUnwrap(moves["sourceTables"] as? [[String: Any]])
        XCTAssertTrue(sourceTables.contains { $0["path"] as? String == "src/data/pokemon/tmhm_learnsets.h" && $0["status"] as? String == "blocked" })
        XCTAssertTrue(sourceTables.contains { $0["path"] as? String == "src/data/pokemon/egg_moves.h" && $0["status"] as? String == "blocked" })
        let tutor = try XCTUnwrap(sourceTables.first { $0["path"] as? String == "src/data/pokemon/tutor_learnsets.h" && $0["tableSymbol"] as? String == "gTutorLearnsets" })
        XCTAssertEqual(tutor["status"] as? String, "editable")
        XCTAssertEqual(tutor["indexedCount"] as? Int, 1)
        XCTAssertEqual(tutor["sourceRole"] as? String, "editableTutorLearnsets")
        XCTAssertEqual(tutor["readiness"] as? String, "editable existing gTutorLearnsets rows")
        let blockedActions = try XCTUnwrap(tutor["blockedActions"] as? [String])
        XCTAssertTrue(blockedActions.contains("tutor constant creation"))
        XCTAssertTrue(blockedActions.contains("missing tutor row insertion"))
        XCTAssertTrue(blockedActions.contains("row insertion/removal/reorder"))
        XCTAssertTrue(blockedActions.contains("generated all_learnables.json writes"))
        XCTAssertTrue(blockedActions.contains("generated outputs"))
        XCTAssertTrue(blockedActions.contains("reference writes"))
        XCTAssertTrue(blockedActions.contains("ROM/build/export paths"))
        XCTAssertTrue(blockedActions.contains("binary writes"))
        XCTAssertTrue(sourceTables.contains { $0["path"] as? String == "generated" && $0["status"] as? String == "blocked" })
        XCTAssertTrue(sourceTables.contains { $0["path"] as? String == "references/pokeemerald-expansion/src/data/moves_info.h" && $0["status"] as? String == "blocked" })
        XCTAssertTrue(sourceTables.contains { $0["path"] as? String == "ROM output" && $0["status"] as? String == "blocked" })
    }

    func testPokemonCompatibilityCommandEmitsRubySapphireTutorLearnsetsEditableJSON() throws {
        let root = try makeRubyMoveCatalogProject()
        try write(
            """
            #define MOVE_NONE 0
            #define MOVE_POUND 1
            #define MOVE_MEGA_PUNCH 5
            #define MOVE_SWORD_DANCE 14

            """,
            to: root.appendingPathComponent("include/constants/moves.h")
        )
        try write(
            """
            const struct BaseStats gBaseStats[] =
            {
                [SPECIES_TREECKO] =
                {
                    .baseHP = 40,
                    .baseAttack = 45,
                    .baseDefense = 35,
                    .baseSpeed = 70,
                    .baseSpAttack = 65,
                    .baseSpDefense = 55,
                },
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/base_stats.h")
        )
        try write(
            """
            const u16 sTutorLearnsets[] =
            {
                [SPECIES_TREECKO] = (TUTOR(MEGA_PUNCH) | TUTOR(SWORD_DANCE)),
            };
            """,
            to: root.appendingPathComponent("src/data/pokemon/tutor_learnsets.h")
        )

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["pokemon-compatibility", root.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "pokeruby")
        let entries = try XCTUnwrap(result["entries"] as? [[String: Any]])
        let tutor = try XCTUnwrap(entries.first { $0["surface"] as? String == "tutorLearnsets" })
        XCTAssertEqual(tutor["status"] as? String, "editable")
        XCTAssertEqual(tutor["sourcePath"] as? String, "src/data/pokemon/tutor_learnsets.h")
        XCTAssertEqual(tutor["tableSymbol"] as? String, "sTutorLearnsets/gTutorLearnsets")
        XCTAssertEqual(tutor["editableCount"] as? Int, 1)
        XCTAssertNil(tutor["recommendedFutureRow"])
        let unsupportedFields = try XCTUnwrap(tutor["unsupportedFields"] as? [String])
        XCTAssertTrue(unsupportedFields.contains("learnset symbol renames"))
        XCTAssertTrue(unsupportedFields.contains("tutor constant creation"))
        XCTAssertTrue(unsupportedFields.contains("missing tutor row insertion"))
        XCTAssertTrue(unsupportedFields.contains("generated learnset output writes"))
        XCTAssertTrue(unsupportedFields.contains("reference-only learnset source writes"))
        XCTAssertTrue(unsupportedFields.contains("binary ROM learnset writes"))
        XCTAssertTrue(unsupportedFields.contains("broad Ruby/Sapphire tutor schema rewrites"))
        let sourceTables = try XCTUnwrap(tutor["sourceTables"] as? [[String: Any]])
        XCTAssertTrue(sourceTables.contains { $0["path"] as? String == "src/data/pokemon/tutor_learnsets.h" && $0["tableSymbol"] as? String == "sTutorLearnsets/gTutorLearnsets" && $0["status"] as? String == "editable" && $0["indexedCount"] as? Int == 1 })
        XCTAssertTrue(sourceTables.contains { $0["path"] as? String == "include/constants/moves.h" && $0["status"] as? String == "blocked" })
        XCTAssertTrue(sourceTables.contains { $0["path"] as? String == "generated" && $0["status"] as? String == "blocked" })
        XCTAssertTrue(sourceTables.contains { $0["path"] as? String == "references/pokeruby/src/data/pokemon/tutor_learnsets.h" && $0["status"] as? String == "blocked" })
        XCTAssertTrue(sourceTables.contains { $0["path"] as? String == "ROM output" && $0["status"] as? String == "blocked" })
    }

    func testMigrationCoverageCommandEmitsSourceFirstAndBlockedJSON() throws {
        let root = try makeItemCatalogProject()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["migration-coverage", root.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "pokeemerald")
        XCTAssertEqual(result["isReadOnly"] as? Bool, true)
        XCTAssertNotNil(result["summary"])
        let entries = try XCTUnwrap(result["entries"] as? [[String: Any]])
        XCTAssertTrue(entries.contains { $0["domain"] as? String == "items" && $0["status"] as? String == "sourceFirstEditable" })
        XCTAssertTrue(entries.contains { $0["domain"] as? String == "patches" && $0["status"] as? String == "previewOnly" && $0["recommendedFutureRow"] as? String == "PHS-T73" })
        XCTAssertTrue(entries.contains { $0["domain"] as? String == "binaryBlocks" && $0["recommendedFutureRow"] as? String == "PHS-T79" })

        let rom = try makeTestROM()
        let binaryResult = try decodeJSON(
            PokemonHackCLI.run(arguments: ["migration-coverage", rom.path, "--json"])
        )
        XCTAssertEqual(binaryResult["profile"] as? String, "binaryROM")
        let binaryEntries = try XCTUnwrap(binaryResult["entries"] as? [[String: Any]])
        XCTAssertTrue(binaryEntries.contains { $0["domain"] as? String == "species" && $0["status"] as? String == "binaryOnlyBlocked" })
        XCTAssertTrue(binaryEntries.contains { $0["domain"] as? String == "graphics" && $0["status"] as? String == "migrationPlanOnly" && $0["recommendedFutureRow"] as? String == "PHS-T92" })

        let ndsRoot = try makeTestNDSDecompRoot()
        let ndsResult = try decodeJSON(
            PokemonHackCLI.run(arguments: ["migration-coverage", ndsRoot.path, "--json"])
        )
        XCTAssertEqual(ndsResult["profile"] as? String, "pokeplatinum")
        let ndsEntries = try XCTUnwrap(ndsResult["entries"] as? [[String: Any]])
        XCTAssertTrue(ndsEntries.contains { $0["domain"] as? String == "ndsContainers" && $0["status"] as? String == "migrationPlanOnly" })
        XCTAssertTrue(ndsEntries.contains { $0["domain"] as? String == "build" && $0["status"] as? String == "externalToolOnly" })
        XCTAssertTrue(ndsEntries.contains { $0["domain"] as? String == "items" && $0["recommendedFutureRow"] as? String == "PHS-T98" })
    }

    func testROMAssetMigrationPlanCommandEmitsReadOnlyPreviewJSON() throws {
        let rom = try makeTestROM(includeGraphicsPreviewBytes: true)

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["rom-asset-migration-plan", rom.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "binaryROM")
        XCTAssertEqual(result["gameFamily"] as? String, "emerald")
        XCTAssertEqual(result["familyConfidence"] as? String, "high")
        XCTAssertEqual(result["isReadOnly"] as? Bool, true)
        XCTAssertEqual(result["extractionEnabled"] as? Bool, false)
        XCTAssertEqual(result["exportEnabled"] as? Bool, false)
        XCTAssertNotNil(result["coverageEntry"])
        let summary = try XCTUnwrap(result["summary"] as? [String: Any])
        XCTAssertGreaterThan(summary["blockedTargetCount"] as? Int ?? 0, 0)
        XCTAssertGreaterThan(summary["tileCandidateCount"] as? Int ?? 0, 0)
        XCTAssertGreaterThan(summary["paletteCandidateCount"] as? Int ?? 0, 0)
        let plans = try XCTUnwrap(result["familyPlans"] as? [[String: Any]])
        XCTAssertTrue(plans.contains { plan in
            plan["family"] as? String == "pokemonSprites"
                && plan["status"] as? String == "migrationPlanOnly"
                && (plan["sourceMigrationTarget"] as? String)?.contains("pokeemerald") == true
        })
        let blockedTargets = plans.flatMap { $0["blockedTargets"] as? [[String: Any]] ?? [] }
        XCTAssertTrue(blockedTargets.contains { ($0["targetPath"] as? String)?.contains("graphics/pokemon/<species>/front.png") == true })
        let diagnostics = try XCTUnwrap(result["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "ROM_ASSET_MIGRATION_PLAN_ONLY" })
    }

    private func makeEmeraldProject() throws -> URL {
        let root = try makeTemporaryDirectory()
        try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("src"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/pokenav"), withIntermediateDirectories: true)
        return root
    }

    private func makeMapRenderAuditProject() throws -> URL {
        let root = try makeTemporaryDirectory()
        try makeMapRenderAuditProject(at: root)
        return root
    }

    private func makeMapRenderAuditProject(at root: URL) throws {
        try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("src"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/pokenav"), withIntermediateDirectories: true)
        try write(
            """
            #define NUM_METATILES_IN_PRIMARY 1
            #define NUM_METATILES_TOTAL 2
            #define NUM_TILES_IN_PRIMARY 1
            #define NUM_TILES_TOTAL 2
            """,
            to: root.appendingPathComponent("include/fieldmap.h")
        )
        try write(
            """
            {
              "group_order": ["gMapGroup_Routes"],
              "gMapGroup_Routes": ["Route1"]
            }
            """,
            to: root.appendingPathComponent("data/maps/map_groups.json")
        )
        try write(
            """
            {
              "layouts_table_label": "gMapLayouts",
              "layouts": [
                {
                  "id": "LAYOUT_ROUTE1",
                  "name": "Route1_Layout",
                  "width": 2,
                  "height": 2,
                  "border_width": 2,
                  "border_height": 2,
                  "primary_tileset": "gTileset_General",
                  "secondary_tileset": "gTileset_Route",
                  "border_filepath": "data/layouts/Route1/border.bin",
                  "blockdata_filepath": "data/layouts/Route1/map.bin"
                }
              ]
            }
            """,
            to: root.appendingPathComponent("data/layouts/layouts.json")
        )
        try write(
            """
            {
              "id": "MAP_ROUTE1",
              "name": "Route1",
              "layout": "LAYOUT_ROUTE1",
              "music": "MUS_ROUTE1",
              "region_map_section": "MAPSEC_ROUTE1",
              "weather": "WEATHER_SUNNY",
              "map_type": "MAP_TYPE_ROUTE",
              "connections": [],
              "object_events": [],
              "warp_events": [],
              "coord_events": [],
              "bg_events": []
            }
            """,
            to: root.appendingPathComponent("data/maps/Route1/map.json")
        )
        try write(
            """
            const struct Tileset gTileset_General =
            {
                .isCompressed = TRUE,
                .isSecondary = FALSE,
                .tiles = gTilesetTiles_General,
                .palettes = gTilesetPalettes_General,
                .metatiles = gMetatiles_General,
                .metatileAttributes = gMetatileAttributes_General,
                .callback = NULL,
            };

            const struct Tileset gTileset_Route =
            {
                .isCompressed = TRUE,
                .isSecondary = TRUE,
                .tiles = gTilesetTiles_Route,
                .palettes = gTilesetPalettes_Route,
                .metatiles = gMetatiles_Route,
                .metatileAttributes = gMetatileAttributes_Route,
                .callback = NULL,
            };
            """,
            to: root.appendingPathComponent("src/data/tilesets/headers.h")
        )
        try write(
            """
            const u32 gTilesetTiles_General[] = INCBIN_U32("data/tilesets/primary/general/tiles.4bpp.lz");
            const u32 gTilesetTiles_Route[] = INCBIN_U32("data/tilesets/secondary/route/tiles.4bpp.lz");
            const u16 gTilesetPalettes_General[][16] = {
                INCBIN_U16("data/tilesets/primary/general/palettes/00.gbapal"),
            };
            const u16 gTilesetPalettes_Route[][16] = {
                INCBIN_U16("data/tilesets/secondary/route/palettes/00.gbapal"),
            };
            """,
            to: root.appendingPathComponent("src/data/tilesets/graphics.h")
        )
        try write(
            """
            const u16 gMetatiles_General[] = INCBIN_U16("data/tilesets/primary/general/metatiles.bin");
            const u16 gMetatiles_Route[] = INCBIN_U16("data/tilesets/secondary/route/metatiles.bin");
            const u16 gMetatileAttributes_General[] = INCBIN_U16("data/tilesets/primary/general/metatile_attributes.bin");
            const u16 gMetatileAttributes_Route[] = INCBIN_U16("data/tilesets/secondary/route/metatile_attributes.bin");
            """,
            to: root.appendingPathComponent("src/data/tilesets/metatiles.h")
        )
        try writeWords([0, 0, 0, 0], to: root.appendingPathComponent("data/layouts/Route1/map.bin"))
        try writeWords([0, 0, 0, 0], to: root.appendingPathComponent("data/layouts/Route1/border.bin"))
        try writeWords(Array(repeating: 0, count: 8), to: root.appendingPathComponent("data/tilesets/primary/general/metatiles.bin"))
        try writeWords([0x0011], to: root.appendingPathComponent("data/tilesets/primary/general/metatile_attributes.bin"))
        try writeWords(Array(repeating: 0, count: 8), to: root.appendingPathComponent("data/tilesets/secondary/route/metatiles.bin"))
        try writeWords([0x0011], to: root.appendingPathComponent("data/tilesets/secondary/route/metatile_attributes.bin"))
        try writeIndexedPNG(width: 8, height: 8, paletteIndex: 1, to: root.appendingPathComponent("data/tilesets/primary/general/tiles.png"))
        try writeIndexedPNG(width: 8, height: 8, paletteIndex: 1, to: root.appendingPathComponent("data/tilesets/secondary/route/tiles.png"))
        try writeGBAPalette(colorCount: 16, to: root.appendingPathComponent("data/tilesets/primary/general/palettes/00.gbapal"))
        try writeGBAPalette(colorCount: 16, to: root.appendingPathComponent("data/tilesets/secondary/route/palettes/00.gbapal"))
    }

    private func makeTemporaryDirectory() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackCLITests-\(UUID().uuidString)")
        temporaryDirectories.append(root)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func makeTestROM(includeGraphicsPreviewBytes: Bool = false) throws -> URL {
        let root = try makeTemporaryDirectory()
        let rom = root.appendingPathComponent("test.gba")
        var bytes = [UInt8](repeating: 0xff, count: 0x240)
        bytes.replaceSubrange(0x04..<0xA0, with: Array(repeating: 1, count: 0x9C))
        bytes.replaceSubrange(0xA0..<0xAC, with: Array("POKEMON TEST".utf8))
        bytes.replaceSubrange(0xAC..<0xB0, with: Array("BPEE".utf8))
        bytes.replaceSubrange(0xB0..<0xB2, with: Array("01".utf8))
        bytes[0x100] = 0x80
        bytes[0x101] = 0x00
        bytes[0x102] = 0x00
        bytes[0x103] = 0x08
        if includeGraphicsPreviewBytes {
            for index in 0..<64 {
                bytes[0x140 + index] = UInt8((index % 31) + 1)
            }
        }
        try Data(bytes).write(to: rom)
        return rom
    }

    private func makeTestNDSROM() throws -> URL {
        let root = try makeTemporaryDirectory()
        let rom = root.appendingPathComponent("fixture.nds")
        var data = Data(repeating: 0, count: 0x900)
        writeASCII("POKEMON D", into: &data, at: 0x00, length: 12)
        writeASCII("ADAE", into: &data, at: 0x0C, length: 4)
        writeASCII("01", into: &data, at: 0x10, length: 2)
        data[0x14] = 0x09
        writeUInt32LE(0x200, into: &data, at: 0x20)
        writeUInt32LE(0x20, into: &data, at: 0x2C)
        writeUInt32LE(0x220, into: &data, at: 0x30)
        writeUInt32LE(0x20, into: &data, at: 0x3C)

        let fnt = makeTestFNT()
        writeUInt32LE(0x300, into: &data, at: 0x40)
        writeUInt32LE(UInt32(fnt.count), into: &data, at: 0x44)
        data.replaceSubrange(0x300..<(0x300 + fnt.count), with: fnt)

        let narc = makeTestNARC()
        var fat = Data()
        appendUInt32LE(0x400, to: &fat)
        appendUInt32LE(0x404, to: &fat)
        appendUInt32LE(0x440, to: &fat)
        appendUInt32LE(0x450, to: &fat)
        appendUInt32LE(0x500, to: &fat)
        appendUInt32LE(UInt32(0x500 + narc.count), to: &fat)
        writeUInt32LE(0x380, into: &data, at: 0x48)
        writeUInt32LE(UInt32(fat.count), into: &data, at: 0x4C)
        data.replaceSubrange(0x380..<(0x380 + fat.count), with: fat)
        writeUInt32LE(0x700, into: &data, at: 0x68)
        writeUInt16LE(0x5678, into: &data, at: 0x15E)

        data.replaceSubrange(0x400..<0x404, with: Data("ROOT".utf8))
        data.replaceSubrange(0x440..<0x450, with: Data("SDAT".utf8) + Data(repeating: 0, count: 12))
        data.replaceSubrange(0x500..<(0x500 + narc.count), with: narc)
        try data.write(to: rom)
        return rom
    }

    private func makeTestNDSDecompRoot() throws -> URL {
        let root = try makeTemporaryDirectory().appendingPathComponent("pokeplatinum")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try "rom: build/pokeplatinum.us.nds\n".write(to: root.appendingPathComponent("Makefile"), atomically: true, encoding: .utf8)
        try "project('pokeplatinum')\n".write(to: root.appendingPathComponent("meson.build"), atomically: true, encoding: .utf8)
        try "option('revision')\n".write(to: root.appendingPathComponent("meson.options"), atomically: true, encoding: .utf8)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("platinum.us"), withIntermediateDirectories: true)
        try "path,sha1\n".write(to: root.appendingPathComponent("platinum.us/filesys.csv"), atomically: true, encoding: .utf8)
        try "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb  filesys\n".write(to: root.appendingPathComponent("platinum.us/filesys.sha1"), atomically: true, encoding: .utf8)
        try "cccccccccccccccccccccccccccccccccccccccc  pokeplatinum.us.nds\n".write(to: root.appendingPathComponent("platinum.us/rom_rev1.sha1"), atomically: true, encoding: .utf8)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("src"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("asm"), withIntermediateDirectories: true)
        try write("{\"base_hp\":25,\"evolutions\":[[\"EVO_LEVEL\",16,\"SPECIES_KADABRA\"]]}\n", to: root.appendingPathComponent("res/pokemon/abra/data.json"))
        try write("{\"power\":40}\n", to: root.appendingPathComponent("res/battle/moves/tackle.json"))
        try write("id,name\n1,POTION\n", to: root.appendingPathComponent("res/items/items.csv"))
        try write(
            """
            {"name": "Potion", "price": 300, "field_use": true, "effects": [{"kind":"heal","amount":20}]}

            """,
            to: root.appendingPathComponent("res/items/potion.json")
        )
        try write(
            """
            {"name": "Youngster", "class": "TRAINER_CLASS_YOUNGSTER", "double_battle": false, "party": [{"species":"STARLY","level":5}], "messages": ["I like shorts!"]}

            """,
            to: root.appendingPathComponent("res/trainers/data/youngster.json")
        )
        try write("{\"cell_animation\":1}\n", to: root.appendingPathComponent("res/trainers/classes/youngster.json"))
        try write("[{\"slot\":1}]\n", to: root.appendingPathComponent("res/field/encounters/route201.json"))
        try write("{\"message\":\"hello\"}\n", to: root.appendingPathComponent("res/text/story.json"))
        try write("hello\nworld\n", to: root.appendingPathComponent("res/text/route201.txt"))
        try write(Data("BMG Test\u{0}Hello there\u{0}Goodbye\u{0}".utf8), to: root.appendingPathComponent("res/text/battle.bmg"))
        try write(Data("SDAT".utf8) + Data(repeating: 0, count: 12), to: root.appendingPathComponent("res/sound/main.sdat"))
        try write("scrcmd_end\n", to: root.appendingPathComponent("res/field/scripts/route201.s"))
        try write("{\"event\":1}\n", to: root.appendingPathComponent("res/field/events/route201.json"))
        try write(Data([0x01]), to: root.appendingPathComponent("res/field/maps/route201/map.bin"))
        try write("{\"matrix\":1}\n", to: root.appendingPathComponent("res/field/matrices/route201.json"))
        try write(makeTestNARC(), to: root.appendingPathComponent("res/prebuilt/poketool/personal/personal.narc"))
        return root
    }

    private func makeTestHeartGoldDecompRoot() throws -> URL {
        let root = try makeTemporaryDirectory().appendingPathComponent("pokeheartgold")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try write("GAME_VERSION ?= HEARTGOLD\nGAME_CODE := IPK\n", to: root.appendingPathComponent("config.mk"))
        try write("ROM := $(BUILD_DIR)/poke$(buildname).nds\n", to: root.appendingPathComponent("Makefile"))
        try write("HostRoot files/\n", to: root.appendingPathComponent("rom.rsf"))
        try write("filesystem: $(NITROFS_FILES)\n", to: root.appendingPathComponent("filesystem.mk"))
        try write("dddddddddddddddddddddddddddddddddddddddd  pokeheartgold.us.nds\n", to: root.appendingPathComponent("heartgold.us/rom.sha1"))
        try write("{\"species\":\"CHIKORITA\"}\n", to: root.appendingPathComponent("files/poketool/personal/personal.json"))
        try write("{\"id\":1,\"name\":\"Youngster Joey\",\"double_battle\":false,\"party\":[{\"species\":\"RATTATA\",\"level\":4}]}\n", to: root.appendingPathComponent("files/poketool/trainer/trainers.json"))
        try write("id,name\n1,POTION\n", to: root.appendingPathComponent("files/itemtool/itemdata/item_data.csv"))
        try write("{\"name\":\"POTION\",\"price\":300,\"field_use\":true,\"effects\":[{\"kind\":\"heal\",\"amount\":20}]}\n", to: root.appendingPathComponent("files/itemtool/itemdata/potion.json"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/fielddata/script/scr_seq/0001.bin"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/fielddata/mapmatrix/0001.bin"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/fielddata/maptable/map.bin"))
        try write(
            """
            static const MapHeader sMapHeaders[] = {
                [MAP_EVERYWHERE] = {
                    .wildEncounterBank = ENCDATA_NA,
                    .areaDataBank = 0,
                    .moveModelBank = 15,
                    .worldMapX = 0,
                    .worldMapY = 0,
                    .matrixId = NARC_map_matrix_map_matrix_0000_EVERYWHERE_bin,
                    .scriptsBank = NARC_scr_seq_scr_seq_0139_EVERYWHERE_bin,
                    .scriptHeaderBank = NARC_scr_seq_scr_seq_0399_EVERYWHERE_hdr_bin,
                    .msgBank = NARC_msg_msg_0003_EVERYWHERE_bin,
                    .dayMusicId = SEQ_DUMMY,
                    .nightMusicId = SEQ_DUMMY,
                    .eventsBank = NARC_zone_event_000_DUMMY_bin,
                    .mapsec = MAPSEC_MYSTERY_ZONE,
                    .areaIcon = 6,
                    .momCallIntroParam = 10,
                    .regionNo = MAP_REGION_JOHTO,
                    .weather = 0,
                    .mapType = MAP_TYPE_ROUTE,
                    .cameraType = 0,
                    .followMode = MAP_FOLLOWMODE_PREVENT,
                    .battleBg = BATTLE_BG_FOREST,
                    .bikeAllowed = TRUE,
                    .runningAllowed_Unused = TRUE,
                    .escapeRopeAllowed = TRUE,
                    .flyAllowed = FALSE,
                    .outgoingCalls = FALSE,
                    .incomingCalls = FALSE,
                    .radioSignal = FALSE,
                },
                [MAP_NEW_BARK] = { .areaDataBank = 3, .worldMapX = 4, .worldMapY = 7, .weather = 1, .cameraType = 2, .bikeAllowed = FALSE },
                { .areaDataBank = 99 },
            };

            """,
            to: root.appendingPathComponent("src/data/map_headers.h")
        )
        return root
    }

    private func makeTestDiamondDecompRoot() throws -> URL {
        let root = try makeTemporaryDirectory().appendingPathComponent("pokediamond")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("arm7"), withIntermediateDirectories: true)
        try write("GAME_VERSION ?= DIAMOND\nGAME_CODE := ADA\n", to: root.appendingPathComponent("config.mk"))
        try write("ROM := $(BUILD_DIR)/$(TARGET).nds\n", to: root.appendingPathComponent("Makefile"))
        try write("HostRoot files/\n", to: root.appendingPathComponent("rom.rsf"))
        try write("filesystem: $(HOSTFS_FILES)\n", to: root.appendingPathComponent("filesystem.mk"))
        try write("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  build/diamond.us/pokediamond.us.nds\n", to: root.appendingPathComponent("pokediamond.us.sha1"))
        try write("void Pokemon_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/pokemon.c"))
        try write(
            """
            #include "move_data.h"

            /* static const struct WazaTbl sWazaTbl[] = {
                [MOVE_FAKE] = { .power = 99 },
            }; */
            static const char *sWazaTblDebug = "sWazaTbl { [MOVE_FAKE] = { .power = 88 } }";

            static const struct WazaTbl sWazaTbl[] = {
                [MOVE_NONE] = { .effect = 0, .class = CLASS_STATUS, .power = 0, .type = TYPE_NORMAL, .accuracy = 0, .pp = 0, .effectChance = 0, .unk8 = 0, .priority = 0, .unkB = 0, .unkC = 0, .contestType = CONTEST_TYPE_COOL, .padding = 0 },
                [MOVE_TACKLE] = { .effect = MOVE_EFFECT_HIT, .class = CLASS_PHYSICAL, .power = 35, .type = TYPE_NORMAL, .accuracy = 95, .pp = 35, .effectChance = 0, .unk8 = 0x0, .priority = 0, .unkB = 0, .unkC = 0, .contestType = CONTEST_TYPE_COOL, .padding = 0 },
                [MOVE_COMPLEX] = { .effect = MOVE_EFFECT_HIT, .power = 20 + 10, .type = TYPE_NORMAL },
                { .power = 5 },
            };

            void Waza_Load(void) {}
            void LoadWazaEntry(u16 waza, struct WazaTbl *wazaTbl) { ReadWholeNarcMemberByIdPair(wazaTbl, NARC_POKETOOL_WAZA_WAZA_TBL, waza); }

            """,
            to: root.appendingPathComponent("arm9/src/waza.c")
        )
        try write(
            """
            #include "global.h"

            static const u16 sItemIndexMappings[][4] = {
                { 0, 1, 2, 0 },
                { 1, 2, 3, 1 },
                { ITEM_DATA_COUNT, 4, 5, 6 },
            };

            void Item_Load(void) {}

            """,
            to: root.appendingPathComponent("arm9/src/itemtool.c")
        )
        try write(
            """
            #include "trainer_data.h"

            const u8 sTrainerClassGenderCountTbl[] = {
                /*TRAINER_CLASS_PKMN_TRAINER_M*/ 0,
                /*TRAINER_CLASS_LASS*/ 1,
                /*TRAINER_CLASS_TWINS*/ 2,
                TRAINER_CLASS_GENDER_COUNT_SENTINEL,
            };

            void Trainer_Load(void) {}

            """,
            to: root.appendingPathComponent("arm9/src/trainer_data.c")
        )
        try write("void Encounter_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/encounter.c"))
        try write(
            """
            #include "map_header.h"

            static const struct MapHeader sMapHeaders[] = {
                { NARC_area_data_narc_0000_bin, 20, NARC_map_matrix_narc_0000_bin, NARC_scr_seq_release_narc_0001_bin, NARC_scr_seq_release_narc_0464_bin, NARC_msg_narc_0018_bin, SEQ_CITY01_D, SEQ_CITY01_N, 0xFFFF, NARC_zone_event_release_narc_0001_bin, MAPSEC_JUBILIFE_CITY, 0, 4, 4, 6, TRUE, TRUE, FALSE, TRUE },
                { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1, 2, 0, 1, 0, 1 },
                { 1, 2, 3 },
            };

            void MapHeader_Load(void) {}

            """,
            to: root.appendingPathComponent("arm9/src/map_header.c")
        )
        try write("void Script_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/script.c"))
        try write("void Message_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/msgdata.c"))
        try write("{\"personal\":1}\n", to: root.appendingPathComponent("files/poketool/personal/personal.json"))
        try write("{\"name\":\"POTION\",\"price\":300,\"field_use\":true,\"effects\":[{\"kind\":\"heal\",\"amount\":20}]}\n", to: root.appendingPathComponent("files/itemtool/itemdata/potion.json"))
        try write("{\"name\":\"POTION\",\"name\":\"SUPER_POTION\"}\n", to: root.appendingPathComponent("files/itemtool/itemdata/duplicate.json"))
        try write("{\"name\": }\n", to: root.appendingPathComponent("files/itemtool/itemdata/malformed.json"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/itemtool/itemdata/item_0000.bin"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/fielddata/mapmatrix/matrix.bin"))
        try write(Data([0x01]), to: root.appendingPathComponent("files/fielddata/maptable/map.bin"))
        try write(Data([0x02]), to: root.appendingPathComponent("files/fielddata/land_data/land_0001.bin"))
        try write(Data([0x03]), to: root.appendingPathComponent("files/fielddata/areadata/area_0001.bin"))
        try write("ignored\n", to: root.appendingPathComponent("files/fielddata/script/scr_seq_release/.knarcignore"))
        try write(Data("NCLR".utf8), to: root.appendingPathComponent("files/fielddata/script/scr_seq_release/narc_0000.nclr"))
        try write(Data([0x03]), to: root.appendingPathComponent("files/fielddata/script/scr_seq_release/narc_0001.bin"))
        return root
    }

    private func makeTestBlackDecompRoot() throws -> URL {
        let root = try makeTemporaryDirectory().appendingPathComponent("pokeblack")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try write("GAME_VERSION ?= BLACK\nSUPPORTED_ROMS := black.us\n", to: root.appendingPathComponent("config.mk"))
        try write("ROM := pokeblack.nds\n", to: root.appendingPathComponent("Makefile"))
        try write("NitroROMSpec\n", to: root.appendingPathComponent("main.rsf"))
        try write("main linker script\n", to: root.appendingPathComponent("main.lsf"))
        try write("arm9 linker script\n", to: root.appendingPathComponent("arm9.ld"))
        try write("arm7 linker script\n", to: root.appendingPathComponent("arm7.ld"))
        try write("ffffffffffffffffffffffffffffffffffffffff  pokeblack.nds\n", to: root.appendingPathComponent("black.us/rom.sha1"))
        try write("void Init(void) {}\n", to: root.appendingPathComponent("src/init.c"))
        try write("arm9\n", to: root.appendingPathComponent("asm/arm9_remaining.s"))
        try write("#define BLACK 1\n", to: root.appendingPathComponent("include/globals.h"))
        try write("route 1\n", to: root.appendingPathComponent("data/encounters/route_1.txt"))
        try write("pokemon-source\n", to: root.appendingPathComponent("data/pokemon/source_pokemon.txt"))
        try write("moves-source\n", to: root.appendingPathComponent("data/moves/source_moves.txt"))
        try write("items-source\n", to: root.appendingPathComponent("data/items/source_items.txt"))
        try write("trainers-source\n", to: root.appendingPathComponent("data/trainers/source_trainers.txt"))
        try write("pokemon-source-inc\n", to: root.appendingPathComponent("src/data/pokemon/source_pokemon.inc"))
        try write("moves-source-inc\n", to: root.appendingPathComponent("src/data/moves/source_moves.inc"))
        try write("items-source-inc\n", to: root.appendingPathComponent("src/data/items/source_items.inc"))
        try write("trainers-source-inc\n", to: root.appendingPathComponent("src/data/trainers/source_trainers.inc"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/root.bin"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/a/0/0/0/resource.bin"))
        try write(Data([0x01]), to: root.appendingPathComponent("files/fielddata/mapmatrix/0001.bin"))
        try write(Data([0x02]), to: root.appendingPathComponent("files/fielddata/maptable/map.bin"))
        try write(Data([0x03]), to: root.appendingPathComponent("files/fielddata/script/scr_seq/0001.bin"))
        try write(Data([0x04, 0x05, 0x06]), to: root.appendingPathComponent("files/fielddata/script/scr_seq/0002.bin"))
        try write("{\"zone\":1}\n", to: root.appendingPathComponent("files/fielddata/eventdata/zone_event/zone_001.json"))
        try write("Route 1 hello\n", to: root.appendingPathComponent("files/msgdata/story/message_bank.txt"))
        try write("Trainer message candidate\n", to: root.appendingPathComponent("files/msgdata/battle/trainer_messages.gmm"))
        try write(Data([0x10, 0x00, 0x00, 0x00]), to: root.appendingPathComponent("files/msgdata/msg/0001.bin"))
        try write("Alpha\nBeta\n", to: root.appendingPathComponent("files/msgdata/system/help.str"))
        try write(Data([0x30, 0x31, 0x32]), to: root.appendingPathComponent("files/msgdata/msg/msg_0099.msg"))
        try write(Data([0x20, 0x00, 0x00, 0x00]), to: root.appendingPathComponent("files/msgdata/system/msg_0002.dat"))
        try write(Data("NARC".utf8), to: root.appendingPathComponent("files/soundstatus.narc"))
        try write(Data("SDAT".utf8) + Data(repeating: 0, count: 12), to: root.appendingPathComponent("files/wb_sound_data.sdat"))
        try write("overlay\n", to: root.appendingPathComponent("overlays/overlay_93/source.s"))
        try write(Data([0xaa, 0xbb]), to: root.appendingPathComponent("overlays/overlay_94/source.s"))
        try write("config\n", to: root.appendingPathComponent("ndsdisasm_config/ARM9.cfg"))
        try write(Data([0x01, 0x02, 0x03]), to: root.appendingPathComponent("ndsdisasm_config/overlays/overlay_94.cfg"))
        return root
    }

    private func makeTestFNT() -> Data {
        var rootEntries = Data()
        appendFNTFile("root.bin", to: &rootEntries)
        appendFNTFile("sound_data.sdat", to: &rootEntries)
        appendFNTDirectory("sub", directoryID: 0xF001, to: &rootEntries)
        rootEntries.append(0)

        var childEntries = Data()
        appendFNTFile("child.narc", to: &childEntries)
        childEntries.append(0)

        var fnt = Data()
        appendUInt32LE(16, to: &fnt)
        appendUInt16LE(0, to: &fnt)
        appendUInt16LE(2, to: &fnt)
        appendUInt32LE(UInt32(16 + rootEntries.count), to: &fnt)
        appendUInt16LE(2, to: &fnt)
        appendUInt16LE(0xF000, to: &fnt)
        fnt.append(rootEntries)
        fnt.append(childEntries)
        return fnt
    }

    private func makeTestNARC() -> Data {
        let payload = Data("NCLR".utf8) + Data([0x10, 0x00, 0x00, 0x00])
        var fat = Data("BTAF".utf8)
        appendUInt32LE(28, to: &fat)
        appendUInt16LE(2, to: &fat)
        appendUInt16LE(0, to: &fat)
        appendUInt32LE(0, to: &fat)
        appendUInt32LE(4, to: &fat)
        appendUInt32LE(4, to: &fat)
        appendUInt32LE(UInt32(payload.count), to: &fat)

        var namesData = Data()
        appendUInt32LE(8, to: &namesData)
        appendUInt16LE(0, to: &namesData)
        appendUInt16LE(1, to: &namesData)
        appendFNTFile("first.bin", to: &namesData)
        appendFNTFile("second.bin", to: &namesData)
        namesData.append(0)
        var fnt = Data("BTNF".utf8)
        appendUInt32LE(UInt32(8 + namesData.count), to: &fnt)
        fnt.append(namesData)

        var image = Data("GMIF".utf8)
        appendUInt32LE(UInt32(8 + payload.count), to: &image)
        image.append(payload)

        let fileSize = UInt32(16 + fat.count + fnt.count + image.count)
        var header = Data("NARC".utf8)
        appendUInt16LE(0xFFFE, to: &header)
        appendUInt16LE(0x0100, to: &header)
        appendUInt32LE(fileSize, to: &header)
        appendUInt16LE(0x10, to: &header)
        appendUInt16LE(3, to: &header)
        return header + fat + fnt + image
    }

    private func makeMoveCatalogProject() throws -> URL {
        let root = try makeEmeraldProject()
        try write(
            """
            static const struct BattleMove gBattleMoves[] =
            {
                [MOVE_POUND] =
                {
                    .effect = EFFECT_HIT,
                    .power = 40,
                    .type = TYPE_NORMAL,
                    .accuracy = 100,
                    .pp = 35,
                    .secondaryEffectChance = 0,
                    .target = MOVE_TARGET_SELECTED,
                    .priority = 0,
                    .flags = FLAG_MAKES_CONTACT,
                },
            };

            """,
            to: root.appendingPathComponent("src/data/battle_moves.h")
        )
        try write(
            """
            static const struct SpeciesInfo gSpeciesInfo[] =
            {
                [SPECIES_TREECKO] =
                {
                    .baseHP = 40,
                    .baseAttack = 45,
                    .baseDefense = 35,
                    .baseSpeed = 70,
                    .baseSpAttack = 65,
                    .baseSpDefense = 55,
                },
            };

            """,
            to: root.appendingPathComponent("src/data/pokemon/species_info.h")
        )
        try write(
            """
            static const u16 sTreeckoLevelUpLearnset[] = {
                LEVEL_UP_MOVE(1, MOVE_POUND),
                LEVEL_UP_END
            };

            const u16 *const gLevelUpLearnsets[] =
            {
                [SPECIES_TREECKO] = sTreeckoLevelUpLearnset,
            };

            """,
            to: root.appendingPathComponent("src/data/pokemon/level_up_learnset_pointers.h")
        )
        try write(
            """
            static const u32 gTMHMLearnsets[] =
            {
                [SPECIES_TREECKO] = TMHM(TM01_POUND),
            };

            """,
            to: root.appendingPathComponent("src/data/pokemon/tmhm_learnsets.h")
        )
        try write(
            """
            #define ITEM_TM01_POUND 1

            """,
            to: root.appendingPathComponent("include/constants/items.h")
        )
        return root
    }

    private func makeExpansionMoveCatalogProject() throws -> URL {
        let root = try makeExpansionCompatibilityProject()
        try write(
            """
            const struct MoveInfo gMovesInfo[] =
            {
                [MOVE_POUND] =
                {
                    .effect = EFFECT_HIT,
                    .power = 40,
                    .type = TYPE_NORMAL,
                    .accuracy = 100,
                    .pp = 35,
                    .secondaryEffectChance = 0,
                    .target = MOVE_TARGET_SELECTED,
                    .priority = 0,
                    .flags = FLAG_MAKES_CONTACT,
                    .description = sPoundDescription,
                    .contestCategory = CONTEST_CATEGORY_TOUGH,
                    .contestAppeal = 2,
                    .contestJam = 1,
                    .contestComboStarterId = COMBO_STARTER_POUND,
                    .contestComboMoves = { MOVE_DOUBLE_SLAP, MOVE_MEGA_PUNCH },
                },
            };

            """,
            to: root.appendingPathComponent("src/data/moves_info.h")
        )
        try write(
            """
            static const u8 sPoundDescription[] = _("Pounds with forelegs.");

            """,
            to: root.appendingPathComponent("src/data/text/move_descriptions.h")
        )
        try write(
            """
            #define FLAG_MAKES_CONTACT (1 << 0)
            #define FLAG_PROTECT_AFFECTED (1 << 1)

            """,
            to: root.appendingPathComponent("include/constants/pokemon.h")
        )
        try write(
            """
            #define MOVE_NONE 0
            #define MOVE_POUND 1
            #define MOVE_DOUBLE_SLAP 3
            #define MOVE_MEGA_PUNCH 5
            #define MOVE_SWORD_DANCE 14

            """,
            to: root.appendingPathComponent("include/constants/moves.h")
        )
        try write("#define SPECIES_TREECKO 1\n", to: root.appendingPathComponent("include/constants/species.h"))
        try write(
            """
            const struct SpeciesInfo gSpeciesInfo[] =
            {
                [SPECIES_TREECKO] = { .baseHP = 40 },
            };

            """,
            to: root.appendingPathComponent("src/data/pokemon/species_info.h")
        )
        try write(
            """
            static const u16 gTutorMoves[] = {
                MOVE_MEGA_PUNCH,
                MOVE_SWORD_DANCE,
            };

            const u16 gTutorLearnsets[] =
            {
                [SPECIES_TREECKO] = (TUTOR(MEGA_PUNCH) | TUTOR(SWORD_DANCE)),
            };

            """,
            to: root.appendingPathComponent("src/data/pokemon/tutor_learnsets.h")
        )
        try write(
            """
            const u16 gEggMoves[] = {
                egg_moves(TREECKO),
                EGG_MOVES_TERMINATOR
            };

            """,
            to: root.appendingPathComponent("src/data/pokemon/egg_moves.h")
        )
        try write(
            """
            {
              "SPECIES_TREECKO": [
                "MOVE_MEGA_PUNCH",
                "MOVE_SWORD_DANCE"
              ]
            }

            """,
            to: root.appendingPathComponent("src/data/pokemon/all_learnables.json")
        )
        return root
    }

    private func makeRubyMoveCatalogProject() throws -> URL {
        let root = try makeTemporaryDirectory()
        try write("GAME_VERSION ?= RUBY\n", to: root.appendingPathComponent("config.mk"))
        try write("placeholder\n", to: root.appendingPathComponent("ruby.sha1"))
        try write("all:\n\t@true\n", to: root.appendingPathComponent("Makefile"))
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics"), withIntermediateDirectories: true)
        try write(
            """
            #define MOVE_NONE 0
            #define MOVE_POUND 1
            #define MOVE_GROWL 2
            #define MOVE_BULLET_SEED 3

            """,
            to: root.appendingPathComponent("include/constants/moves.h")
        )
        try write("#define SPECIES_TREECKO 1\n", to: root.appendingPathComponent("include/constants/species.h"))
        try write(
            """
            #define TYPE_NORMAL 0
            #define TYPE_GRASS 12
            #define EGG_GROUP_MONSTER 1
            #define EGG_GROUP_DRAGON 14
            #define GROWTH_MEDIUM_SLOW 3
            #define BODY_COLOR_GREEN 5

            """,
            to: root.appendingPathComponent("include/constants/pokemon.h")
        )
        try write("#define ABILITY_NONE 0\n#define ABILITY_OVERGROW 65\n", to: root.appendingPathComponent("include/constants/abilities.h"))
        try write("#define ITEM_NONE 0\n#define ITEM_TM09_BULLET_SEED 100\n", to: root.appendingPathComponent("include/constants/items.h"))
        try write(
            """
            const struct BaseStats gBaseStats[] =
            {
                [SPECIES_TREECKO] =
                {
                    .baseHP = 40,
                    .baseAttack = 45,
                    .baseDefense = 35,
                    .baseSpeed = 70,
                    .baseSpAttack = 65,
                    .baseSpDefense = 55,
                },
            };

            """,
            to: root.appendingPathComponent("src/data/pokemon/base_stats.h")
        )
        try write(
            """
            union TMHMLearnset gTMHMLearnsets[NUM_SPECIES] =
            {
                [SPECIES_TREECKO] = { .learnset = { .BULLET_SEED = TRUE } },
            };

            """,
            to: root.appendingPathComponent("src/data/pokemon/tmhm_learnsets.h")
        )
        try write(
            """
            const u16 gEggMoves[] = {
                egg_moves(TREECKO, MOVE_POUND),
                EGG_MOVES_TERMINATOR
            };

            """,
            to: root.appendingPathComponent("src/data/pokemon/egg_moves.h")
        )
        try write(
            """
            const struct BattleMove gBattleMoves[] =
            {
                [MOVE_POUND] =
                {
                    .effect = EFFECT_HIT,
                    .power = 40,
                    .type = TYPE_NORMAL,
                    .accuracy = 100,
                    .pp = 35,
                    .secondaryEffectChance = 0,
                    .target = MOVE_TARGET_SELECTED,
                    .priority = 0,
                    .flags = FLAG_MAKES_CONTACT,
                    .description = gMoveDescription_Pound,
                    .contestEffect = CONTEST_EFFECT_NONE,
                },
            };

            """,
            to: root.appendingPathComponent("src/data/battle_moves.c")
        )
        try write(
            """
            const struct ContestMove gContestMoves[MOVES_COUNT] =
            {
                [MOVE_POUND] =
                {
                    .effect = CONTEST_EFFECT_HIGHLY_APPEALING,
                    .contestCategory = CONTEST_CATEGORY_TOUGH,
                    .comboStarterId = COMBO_STARTER_POUND,
                    .comboMoves = { COMBO_STARTER_GROWL },
                },
            };

            """,
            to: root.appendingPathComponent("src/data/contest_moves.h")
        )
        return root
    }

    private func makeRubyItemCatalogProject() throws -> URL {
        let root = try makeTemporaryDirectory()
        try write("GAME_VERSION ?= RUBY\n", to: root.appendingPathComponent("config.mk"))
        try write("placeholder\n", to: root.appendingPathComponent("ruby.sha1"))
        try write("all:\n\t@true\n", to: root.appendingPathComponent("Makefile"))
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics"), withIntermediateDirectories: true)
        try write(
            """
            const struct Item gItems[] =
            {
                {
                    .name = _(\"POTION\"),
                    .itemId = ITEM_POTION,
                    .price = 300,
                    .holdEffect = HOLD_EFFECT_NONE,
                    .holdEffectParam = 0,
                    .description = gItemDescription_Potion,
                    .pocket = POCKET_ITEMS,
                    .type = ITEM_USE_PARTY_MENU,
                    .fieldUseFunc = ItemUseOutOfBattle_Medicine,
                    .battleUsage = ITEM_B_USE_MEDICINE,
                    .battleUseFunc = ItemUseInBattle_Medicine,
                    .secondaryId = 0,
                },
            };

            """,
            to: root.appendingPathComponent("src/data/items_en.h")
        )
        try write(
            """
            static const u8 gItemDescription_Potion[] = _(
                "Restores HP.");

            """,
            to: root.appendingPathComponent("src/data/item_descriptions_en.h")
        )
        return root
    }

    private func makeRubyTrainerCatalogProject() throws -> URL {
        let root = try makeTemporaryDirectory()
        try write("GAME_VERSION ?= RUBY\n", to: root.appendingPathComponent("config.mk"))
        try write("placeholder\n", to: root.appendingPathComponent("ruby.sha1"))
        try write("all:\n\t@true\n", to: root.appendingPathComponent("Makefile"))
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics"), withIntermediateDirectories: true)
        try write(
            """
            #define SPECIES_NONE 0
            #define SPECIES_TREECKO 1

            """,
            to: root.appendingPathComponent("include/constants/species.h")
        )
        try write(
            """
            #define MOVE_NONE 0
            #define MOVE_POUND 1
            #define MOVE_ABSORB 2

            """,
            to: root.appendingPathComponent("include/constants/moves.h")
        )
        try write(
            """
            #define ITEM_NONE 0
            #define ITEM_POTION 1

            """,
            to: root.appendingPathComponent("include/constants/items.h")
        )
        try write(
            """
            #define TRAINER_ENCOUNTER_MUSIC_MALE 1
            #define F_TRAINER_PARTY_CUSTOM_MOVESET 1 << 0
            #define F_TRAINER_PARTY_HELD_ITEM 1 << 1

            enum {
                TRAINER_PIC_HIKER,
            };

            enum {
                TRAINER_CLASS_RIVAL,
            };

            """,
            to: root.appendingPathComponent("include/constants/trainers.h")
        )
        try write(
            """
            #define NATURE_HARDY 0

            """,
            to: root.appendingPathComponent("include/constants/pokemon.h")
        )
        try write(
            """
            const struct Trainer gTrainers[] = {
                [TRAINER_RUBY] =
                {
                    .partyFlags = F_TRAINER_PARTY_HELD_ITEM | F_TRAINER_PARTY_CUSTOM_MOVESET,
                    .trainerClass = TRAINER_CLASS_RIVAL,
                    .encounterMusic_gender = TRAINER_ENCOUNTER_MUSIC_MALE,
                    .trainerPic = TRAINER_PIC_HIKER,
                    .trainerName = _("RUBY"),
                    .items = {ITEM_NONE, ITEM_NONE, ITEM_NONE, ITEM_NONE},
                    .doubleBattle = FALSE,
                    .aiFlags = 0x7,
                    .partySize = 1,
                    .party = {.ItemCustomMoves = gTrainerParty_Ruby }
                },
            };

            """,
            to: root.appendingPathComponent("src/data/trainers_en.h")
        )
        try write(
            """
            const struct TrainerMonItemCustomMoves gTrainerParty_Ruby[] = {
                {
                    .iv = 40,
                    .level = 6,
                    .species = SPECIES_TREECKO,
                    .heldItem = ITEM_NONE,
                    .moves = MOVE_POUND, MOVE_ABSORB, MOVE_NONE, MOVE_NONE
                }
            };

            """,
            to: root.appendingPathComponent("src/data/trainer_parties.h")
        )
        return root
    }

    private func makeItemCatalogProject() throws -> URL {
        let root = try makeEmeraldProject()
        try write(
            """
            const struct Item gItems[] =
            {
                [ITEM_POTION] =
                {
                    .name = _("POTION"),
                    .itemId = ITEM_POTION,
                    .price = 300,
                    .holdEffect = HOLD_EFFECT_NONE,
                    .holdEffectParam = 0,
                    .description = sPotionDesc,
                    .pocket = POCKET_ITEMS,
                    .type = ITEM_USE_PARTY_MENU,
                    .fieldUseFunc = ItemUseOutOfBattle_Medicine,
                    .battleUsage = ITEM_B_USE_MEDICINE,
                    .battleUseFunc = ItemUseInBattle_Medicine,
                    .secondaryId = 0,
                },
            };

            """,
            to: root.appendingPathComponent("src/data/items.h")
        )
        return root
    }

    private func makeExpansionCompatibilityProject() throws -> URL {
        let root = try makeEmeraldProject()
        try write("#define POKEMON_EXPANSION 1\n", to: root.appendingPathComponent("include/constants/expansion.h"))
        return root
    }

    private func writeExpansionItemInfo(at root: URL) throws {
        try write(
            """
            const struct ItemInfo gItemsInfo[] =
            {
                [ITEM_POTION] =
                {
                    .name = ITEM_NAME("Potion"),
                    .price = 300,
                    .holdEffect = HOLD_EFFECT_NONE,
                    .holdEffectParam = 20,
                    .description = COMPOUND_STRING("Restores HP."),
                    .pocket = POCKET_ITEMS,
                    .importance = 0,
                    .registrability = 0,
                    .sortType = ITEM_TYPE_HEALTH_RECOVERY,
                    .type = ITEM_USE_PARTY_MENU,
                    .exitsBagOnUse = FALSE,
                    .effect = ITEM_EFFECT_HEAL,
                    .fieldUseFunc = ItemUseOutOfBattle_Medicine,
                    .battleUsage = EFFECT_ITEM_RESTORE_HP,
                    .battleUseFunc = NULL,
                    .secondaryId = 0,
                    .iconPic = gItemIcon_Potion,
                    .iconPalette = gItemIconPalette_Potion,
                },
            };

            """,
            to: root.appendingPathComponent("src/data/items.h")
        )
    }

    private func makeExpansionAllLearnablesProject() throws -> URL {
        let root = try makeExpansionCompatibilityProject()
        try write(
            """
            const struct SpeciesInfo gSpeciesInfo[] =
            {
                [SPECIES_TREECKO] = { .baseHP = 40 },
            };

            """,
            to: root.appendingPathComponent("src/data/pokemon/species_info.h")
        )
        try write(
            """
            static const u16 sTreeckoLevelUpLearnset[] = {
                LEVEL_UP_MOVE(1, MOVE_POUND),
                LEVEL_UP_MOVE(6, MOVE_ABSORB),
                LEVEL_UP_END
            };

            """,
            to: root.appendingPathComponent("src/data/pokemon/level_up_learnsets/treecko.h")
        )
        try write(
            """
            const struct TMHMLearnset sTMHMLearnsets[] =
            {
                [SPECIES_TREECKO] = { .learnset = { .BULLET_SEED = TRUE } },
            };

            """,
            to: root.appendingPathComponent("src/data/pokemon/tmhm_learnsets.h")
        )
        try write(
            """
            const u16 gTutorLearnsets[] =
            {
                [SPECIES_TREECKO] = TUTOR(MEGA_PUNCH),
            };

            """,
            to: root.appendingPathComponent("src/data/pokemon/tutor_learnsets.h")
        )
        try write(
            """
            const u16 gEggMoves[] = {
                egg_moves(TREECKO),
                EGG_MOVES_TERMINATOR
            };

            """,
            to: root.appendingPathComponent("src/data/pokemon/egg_moves.h")
        )
        try write(
            """
            {
              "SPECIES_TREECKO": [
                "MOVE_POUND",
                "MOVE_ABSORB",
                "MOVE_BULLET_SEED",
                "MOVE_QUICK_ATTACK"
              ]
            }

            """,
            to: root.appendingPathComponent("src/data/pokemon/all_learnables.json")
        )
        return root
    }

    private func assertModernEmeraldSource(
        in entries: [[String: Any]],
        surface: String,
        path: String,
        tableSymbol: String? = nil,
        diagnosticCode: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let entry = try XCTUnwrap(entries.first { $0["surface"] as? String == surface }, file: file, line: line)
        let sourceTables = try XCTUnwrap(entry["sourceTables"] as? [[String: Any]], file: file, line: line)
        let sourceTable = try XCTUnwrap(
            sourceTables.first { $0["path"] as? String == path },
            "Missing Modern Emerald source table for \(path).",
            file: file,
            line: line
        )
        XCTAssertEqual(sourceTable["status"] as? String, "blocked", file: file, line: line)
        XCTAssertEqual(sourceTable["sourceRole"] as? String, "referenceOnly", file: file, line: line)
        XCTAssertEqual(sourceTable["recommendedFutureRow"] as? String, "PHS-T78", file: file, line: line)
        if let tableSymbol {
            XCTAssertEqual(sourceTable["tableSymbol"] as? String, tableSymbol, file: file, line: line)
        } else {
            XCTAssertNil(sourceTable["tableSymbol"], file: file, line: line)
        }
        if let diagnosticCode {
            let diagnostics = try XCTUnwrap(entry["diagnostics"] as? [[String: Any]], file: file, line: line)
            XCTAssertTrue(
                diagnostics.contains { $0["code"] as? String == diagnosticCode },
                "Missing diagnostic \(diagnosticCode).",
                file: file,
                line: line
            )
        }
    }

    @discardableResult
    private func assertAllLearnablesSourceTable(
        in entry: [String: Any],
        expectedRelatedSourcePaths: [String],
        expectedBlockedActions: [String],
        expectedMatchingSpeciesCount: Int = 1,
        expectedMismatchSpeciesCount: Int = 0,
        expectedMoveMismatchSpeciesCount: Int = 0,
        expectedDisagreementCount: Int = 0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [String: Any] {
        let sourceTables = try XCTUnwrap(entry["sourceTables"] as? [[String: Any]], file: file, line: line)
        let sourceTable = try XCTUnwrap(
            sourceTables.first { $0["path"] as? String == "src/data/pokemon/all_learnables.json" },
            "Missing all-learnables source table for \(entry["surface"] ?? "unknown surface").",
            file: file,
            line: line
        )
        XCTAssertEqual(sourceTable["status"] as? String, "blocked", file: file, line: line)
        XCTAssertEqual(sourceTable["indexedCount"] as? Int, 1, file: file, line: line)
        XCTAssertEqual(sourceTable["sourceRole"] as? String, "generatedAllLearnablesIndex", file: file, line: line)
        XCTAssertEqual(sourceTable["readiness"] as? String, "read-only generated context", file: file, line: line)
        XCTAssertEqual(sourceTable["relatedSourcePaths"] as? [String], expectedRelatedSourcePaths, file: file, line: line)
        XCTAssertEqual(sourceTable["blockedActions"] as? [String], expectedBlockedActions, file: file, line: line)
        let coverage = try XCTUnwrap(sourceTable["learnablesCoverage"] as? [String: Any], file: file, line: line)
        XCTAssertEqual(coverage["generatedSpeciesCount"] as? Int, 1, file: file, line: line)
        XCTAssertEqual(coverage["parsedSourceSpeciesCount"] as? Int, 1, file: file, line: line)
        XCTAssertEqual(coverage["matchingSpeciesCount"] as? Int, expectedMatchingSpeciesCount, file: file, line: line)
        XCTAssertEqual(coverage["mismatchSpeciesCount"] as? Int, expectedMismatchSpeciesCount, file: file, line: line)
        XCTAssertEqual(coverage["generatedOnlySpeciesCount"] as? Int, 0, file: file, line: line)
        XCTAssertEqual(coverage["sourceOnlySpeciesCount"] as? Int, 0, file: file, line: line)
        XCTAssertEqual(coverage["moveMismatchSpeciesCount"] as? Int, expectedMoveMismatchSpeciesCount, file: file, line: line)
        XCTAssertEqual(coverage["staleSourceFileCount"] as? Int, 0, file: file, line: line)
        XCTAssertNil(coverage["newestStaleSourcePath"], file: file, line: line)
        XCTAssertEqual(coverage["staleSourcePaths"] as? [String], [], file: file, line: line)
        XCTAssertEqual((coverage["disagreements"] as? [[String: Any]])?.count, expectedDisagreementCount, file: file, line: line)
        return sourceTable
    }

    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func write(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }

    private func recursiveRelativeFiles(in root: URL) throws -> [String] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: []
        ) else {
            return []
        }
        var files: [String] = []
        for case let url as URL in enumerator {
            let values = try url.resourceValues(forKeys: [.isRegularFileKey])
            guard values.isRegularFile == true else { continue }
            files.append(String(url.standardizedFileURL.path.dropFirst(root.standardizedFileURL.path.count + 1)))
        }
        return files.sorted()
    }

    private func genVEncounterFielddataMessageContextRecordIDs() -> Set<String> {
        [
            "encounters:data/encounters/route_1.txt",
            "resources:files/fielddata",
            "maps:files/fielddata/mapmatrix",
            "maps:files/fielddata/maptable",
            "scripts:files/fielddata/script",
            "scripts:files/fielddata/eventdata/zone_event",
            "text:files/msgdata",
            "species:data/pokemon",
            "moves:data/moves",
            "items:data/items",
            "trainers:data/trainers",
            "species:src/data/pokemon",
            "moves:src/data/moves",
            "items:src/data/items",
            "trainers:src/data/trainers",
            "resources:files/msgdata/story/message_bank.txt",
            "resources:files/msgdata/battle/trainer_messages.gmm",
            "resources:files/msgdata/msg/0001.bin",
            "resources:files/msgdata/system/help.str",
            "resources:files/msgdata/msg/msg_0099.msg",
            "resources:files/msgdata/system/msg_0002.dat"
        ]
    }

    private func writeWords(_ words: [UInt16], to url: URL) throws {
        var data = Data()
        for word in words {
            data.append(UInt8(word & 0x00ff))
            data.append(UInt8((word >> 8) & 0x00ff))
        }
        try write(data, to: url)
    }

    private func writeIndexedPNG(width: Int, height: Int, paletteIndex: UInt8, to url: URL) throws {
        var data = Data([137, 80, 78, 71, 13, 10, 26, 10])
        appendChunk("IHDR", payload: pngIHDR(width: UInt32(width), height: UInt32(height)), to: &data)
        appendChunk("PLTE", payload: Data([0, 0, 0, 255, 255, 255]), to: &data)
        var rows = Data()
        for _ in 0..<height {
            rows.append(0)
            rows.append(contentsOf: Array(repeating: paletteIndex, count: width))
        }
        appendChunk("IDAT", payload: rows, to: &data)
        appendChunk("IEND", payload: Data(), to: &data)
        try write(data, to: url)
    }

    private func writeGBAPalette(colorCount: Int, to url: URL) throws {
        var data = Data()
        for index in 0..<colorCount {
            let raw: UInt16 = index == 1 ? 0x7fff : 0
            data.append(UInt8(raw & 0x00ff))
            data.append(UInt8((raw >> 8) & 0x00ff))
        }
        try write(data, to: url)
    }

    private func writePNG(width: UInt32, height: UInt32, paletteColors: Int, to url: URL) throws {
        var data = Data([137, 80, 78, 71, 13, 10, 26, 10])
        appendChunk("IHDR", payload: pngIHDR(width: width, height: height), to: &data)
        appendChunk("PLTE", payload: Data(repeating: 0, count: paletteColors * 3), to: &data)
        appendChunk("IEND", payload: Data(), to: &data)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
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

    private func appendFNTFile(_ name: String, to data: inout Data) {
        data.append(UInt8(name.utf8.count))
        data.append(Data(name.utf8))
    }

    private func appendFNTDirectory(_ name: String, directoryID: UInt16, to data: inout Data) {
        data.append(UInt8(0x80 | name.utf8.count))
        data.append(Data(name.utf8))
        appendUInt16LE(directoryID, to: &data)
    }

    private func writeASCII(_ string: String, into data: inout Data, at offset: Int, length: Int) {
        let bytes = Array(string.utf8.prefix(length))
        data.replaceSubrange(offset..<(offset + bytes.count), with: bytes)
    }

    private func writeUInt16LE(_ value: UInt16, into data: inout Data, at offset: Int) {
        data[offset] = UInt8(value & 0xff)
        data[offset + 1] = UInt8((value >> 8) & 0xff)
    }

    private func writeUInt32LE(_ value: UInt32, into data: inout Data, at offset: Int) {
        data[offset] = UInt8(value & 0xff)
        data[offset + 1] = UInt8((value >> 8) & 0xff)
        data[offset + 2] = UInt8((value >> 16) & 0xff)
        data[offset + 3] = UInt8((value >> 24) & 0xff)
    }

    private func appendUInt16LE(_ value: UInt16, to data: inout Data) {
        data.append(UInt8(value & 0xff))
        data.append(UInt8((value >> 8) & 0xff))
    }

    private func appendUInt32LE(_ value: UInt32, to data: inout Data) {
        data.append(UInt8(value & 0xff))
        data.append(UInt8((value >> 8) & 0xff))
        data.append(UInt8((value >> 16) & 0xff))
        data.append(UInt8((value >> 24) & 0xff))
    }

    private func decodeJSON(_ json: String) throws -> [String: Any] {
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func factValue(_ label: String, in facts: [[String: Any]]) -> String? {
        facts.first { $0["label"] as? String == label }?["value"] as? String
    }

    private func assertNoGenVSourceDataSemanticFacts(_ facts: [[String: Any]], file: StaticString = #filePath, line: UInt = #line) {
        let semanticLabels = ["Base HP", "Catch Rate", "Power", "PP", "Price", "Party Count", "Decoded Strings", "Text Samples"]
        for label in semanticLabels {
            XCTAssertNil(factValue(label, in: facts), file: file, line: line)
        }
        XCTAssertFalse(facts.contains { ($0["label"] as? String)?.localizedCaseInsensitiveContains("Semantic") == true }, file: file, line: line)
    }
}
