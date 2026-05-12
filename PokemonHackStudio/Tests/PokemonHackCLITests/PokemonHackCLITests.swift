import XCTest
@testable import pokemonhack_cli

final class PokemonHackCLITests: XCTestCase {
    private var temporaryDirectories: [URL] = []

    override func tearDownWithError() throws {
        for url in temporaryDirectories {
            try? FileManager.default.removeItem(at: url)
        }
        temporaryDirectories.removeAll()
        try super.tearDownWithError()
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
        XCTAssertEqual(fileSystem["fileCount"] as? Int, 2)
        let narcArchives = try XCTUnwrap(inspect["narcArchives"] as? [[String: Any]])
        XCTAssertEqual(narcArchives.count, 1)

        let files = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-files", rom.path, "--json"])
        )
        XCTAssertEqual(files["fileCount"] as? Int, 2)
        let rows = try XCTUnwrap(files["files"] as? [[String: Any]])
        XCTAssertTrue(rows.contains { $0["path"] as? String == "sub/child.narc" })

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
        let diagnostics = try XCTUnwrap(catalog["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(diagnostics.contains { $0["code"] as? String == "NDS_DATA_CATALOG_READ_ONLY" })

        let rom = try makeTestNDSROM()
        let romCatalog = try decodeJSON(
            PokemonHackCLI.run(arguments: ["nds-data-catalog", rom.path, "--json"])
        )
        XCTAssertEqual(romCatalog["profile"] as? String, "ndsROM")
        let romRecords = try XCTUnwrap(romCatalog["records"] as? [[String: Any]])
        XCTAssertTrue(romRecords.contains { $0["relativePath"] as? String == "sub/child.narc" })
        let romDiagnostics = try XCTUnwrap(romCatalog["diagnostics"] as? [[String: Any]])
        XCTAssertTrue(romDiagnostics.contains { $0["code"] as? String == "NDS_DATA_CATALOG_BINARY_SUMMARY_READ_ONLY" })
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
                "--json"
            ])
        )

        let textDraft = try XCTUnwrap(plan["textDraft"] as? [String: Any])
        XCTAssertEqual(textDraft["editedText"] as? String, "{\"base_hp\":31}\n")
        let editPlan = try XCTUnwrap(plan["editPlan"] as? [String: Any])
        let changes = try XCTUnwrap(editPlan["changes"] as? [[String: Any]])
        XCTAssertEqual(changes.count, 1)

        let apply = try decodeJSON(
            PokemonHackCLI.run(arguments: [
                "nds-data-semantic-apply",
                root.path,
                "species:res/pokemon/abra/data.json",
                "--set",
                "base_hp=31",
                "--json"
            ])
        )
        let appliedChanges = try XCTUnwrap(apply["appliedChanges"] as? [[String: Any]])
        XCTAssertEqual(appliedChanges.count, 1)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("res/pokemon/abra/data.json"), encoding: .utf8),
            "{\"base_hp\":31}\n"
        )
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

    func testItemCatalogCommandEmitsEditableJSON() throws {
        let root = try makeItemCatalogProject()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["item-catalog", root.path, "--json"])
        )

        XCTAssertEqual(result["itemCount"] as? Int, 1)
        XCTAssertNotNil(result["items"])
        XCTAssertNotNil(result["diagnostics"])
    }

    func testPokemonCompatibilityCommandEmitsPreviewJSON() throws {
        let root = try makeItemCatalogProject()

        let result = try decodeJSON(
            PokemonHackCLI.run(arguments: ["pokemon-compatibility", root.path, "--json"])
        )

        XCTAssertEqual(result["profile"] as? String, "pokeemerald")
        XCTAssertNotNil(result["summary"])
        let entries = try XCTUnwrap(result["entries"] as? [[String: Any]])
        XCTAssertTrue(entries.contains { $0["surface"] as? String == "items" && $0["status"] as? String == "editable" })
        XCTAssertTrue(entries.contains { $0["surface"] as? String == "cries" && $0["status"] as? String == "blocked" })
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

    private func makeTemporaryDirectory() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackCLITests-\(UUID().uuidString)")
        temporaryDirectories.append(root)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func makeTestROM() throws -> URL {
        let root = try makeTemporaryDirectory()
        let rom = root.appendingPathComponent("test.gba")
        var bytes = [UInt8](repeating: 0xff, count: 0x200)
        bytes.replaceSubrange(0x04..<0xA0, with: Array(repeating: 1, count: 0x9C))
        bytes.replaceSubrange(0xA0..<0xAC, with: Array("POKEMON TEST".utf8))
        bytes.replaceSubrange(0xAC..<0xB0, with: Array("BPEE".utf8))
        bytes.replaceSubrange(0xB0..<0xB2, with: Array("01".utf8))
        bytes[0x100] = 0x80
        bytes[0x101] = 0x00
        bytes[0x102] = 0x00
        bytes[0x103] = 0x08
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
        appendUInt32LE(0x500, to: &fat)
        appendUInt32LE(UInt32(0x500 + narc.count), to: &fat)
        writeUInt32LE(0x380, into: &data, at: 0x48)
        writeUInt32LE(UInt32(fat.count), into: &data, at: 0x4C)
        data.replaceSubrange(0x380..<(0x380 + fat.count), with: fat)
        writeUInt32LE(0x700, into: &data, at: 0x68)
        writeUInt16LE(0x5678, into: &data, at: 0x15E)

        data.replaceSubrange(0x400..<0x404, with: Data("ROOT".utf8))
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
        try write("{\"base_hp\":25}\n", to: root.appendingPathComponent("res/pokemon/abra/data.json"))
        try write("{\"power\":40}\n", to: root.appendingPathComponent("res/battle/moves/tackle.json"))
        try write("id,name\n1,POTION\n", to: root.appendingPathComponent("res/items/items.csv"))
        try write("[{\"id\":1}]\n", to: root.appendingPathComponent("res/trainers/data/youngster.json"))
        try write("[{\"slot\":1}]\n", to: root.appendingPathComponent("res/field/encounters/route201.json"))
        try write("{\"message\":\"hello\"}\n", to: root.appendingPathComponent("res/text/story.json"))
        try write("scrcmd_end\n", to: root.appendingPathComponent("res/field/scripts/route201.s"))
        try write("{\"event\":1}\n", to: root.appendingPathComponent("res/field/events/route201.json"))
        try write(Data([0x01]), to: root.appendingPathComponent("res/field/maps/route201/map.bin"))
        try write(makeTestNARC(), to: root.appendingPathComponent("res/prebuilt/poketool/personal/personal.narc"))
        return root
    }

    private func makeTestFNT() -> Data {
        var rootEntries = Data()
        appendFNTFile("root.bin", to: &rootEntries)
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
        appendUInt16LE(1, to: &fnt)
        appendUInt16LE(0xF000, to: &fnt)
        fnt.append(rootEntries)
        fnt.append(childEntries)
        return fnt
    }

    private func makeTestNARC() -> Data {
        let payload = Data([0xAA, 0xBB, 0xCC, 0xDD, 0x11, 0x22, 0x33])
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

    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func write(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
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
}
