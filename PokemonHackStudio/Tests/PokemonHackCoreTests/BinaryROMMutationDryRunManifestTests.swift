import XCTest
@testable import PokemonHackCore

final class BinaryROMMutationDryRunManifestTests: XCTestCase {
    private var temporaryDirectories: [BinaryROMMutationManifestTemporaryDirectory] = []

    override func tearDown() {
        temporaryDirectories.removeAll()
        super.tearDown()
    }

    func testValidGBADryRunManifestCapturesIdentityGraphPreviewsAndIgnoredOutputGuidance() throws {
        let rom = try makeSyntheticGBA()
        let data = try Data(contentsOf: rom)
        let manifest = BinaryROMMutationDryRunManifestBuilder.build(
            path: rom.path,
            request: BinaryROMMutationDryRunRequest(
                expectedSHA1: pokemonHackSHA1Hex(data),
                replacements: [
                    BinaryROMMutationReplacementRequest(offset: 0x120, length: 2, replacementBytes: [0xAA, 0xBB])
                ],
                repoints: [
                    BinaryROMMutationRepointRequest(pointerOffset: 0x100, newTargetOffset: 0x180)
                ],
                allocations: [
                    BinaryROMMutationAllocationRequest(byteCount: 0x20, alignment: 0x10)
                ]
            )
        )

        XCTAssertEqual(manifest.schemaVersion, 1)
        XCTAssertTrue(manifest.isDryRun)
        XCTAssertFalse(manifest.canApply)
        XCTAssertEqual(manifest.profile, .binaryROM)
        XCTAssertEqual(manifest.sourceTreeFirst.status, .binaryOnlyCandidate)
        XCTAssertEqual(manifest.sourceTreeFirst.canUseBinaryOnlyPlan, true)
        let baseROM = try XCTUnwrap(manifest.baseROM)
        XCTAssertEqual(baseROM.sha1, pokemonHackSHA1Hex(data))
        XCTAssertEqual(baseROM.crc32, pokemonHackCRC32Hex(data))
        XCTAssertEqual(baseROM.sizeBytes, UInt64(data.count))
        XCTAssertEqual(baseROM.title, "POKEMON TEST")
        XCTAssertEqual(baseROM.gameCode, "BPEE")
        XCTAssertTrue(baseROM.headerFacts.contains { $0.key == "Game Code" && $0.value == "BPEE" })

        let replacement = try XCTUnwrap(manifest.operationPreviews.first { $0.kind == .replaceBytes })
        XCTAssertFalse(replacement.canApply)
        XCTAssertEqual(replacement.status, .previewOnly)
        XCTAssertEqual(replacement.originalPreviewHex, "11 22")
        XCTAssertEqual(replacement.replacementPreviewHex, "AA BB")
        XCTAssertEqual(replacement.replacementSHA1, pokemonHackSHA1Hex(Data([0xAA, 0xBB])))

        let repoint = try XCTUnwrap(manifest.operationPreviews.first { $0.kind == .repointPointer })
        XCTAssertFalse(repoint.canApply)
        XCTAssertEqual(repoint.status, .previewOnly)
        XCTAssertEqual(repoint.pointerSourceOffset, 0x100)
        XCTAssertEqual(repoint.oldTargetOffset, 0x120)
        XCTAssertEqual(repoint.oldRawValue, 0x0800_0120)
        XCTAssertEqual(repoint.plannedTargetOffset, 0x180)
        XCTAssertEqual(repoint.plannedRawValue, 0x0800_0180)

        let allocation = try XCTUnwrap(manifest.operationPreviews.first { $0.kind == .allocateFreeSpace })
        XCTAssertFalse(allocation.canApply)
        XCTAssertEqual(allocation.status, .previewOnly)
        XCTAssertEqual(allocation.selectedFreeSpaceOffset, 0xC0)
        XCTAssertGreaterThanOrEqual(allocation.selectedFreeSpaceLength ?? 0, 0x20)
        XCTAssertEqual(allocation.selectedFreeSpaceFillByte, 0xFF)
        XCTAssertTrue(allocation.diagnostics.contains { $0.code == "BINARY_ROM_MUTATION_ROM_EXPANSION_BLOCKED" })

        XCTAssertFalse(manifest.ignoredOutputGuidance.willWriteFiles)
        XCTAssertEqual(manifest.ignoredOutputGuidance.relativeRoot, ".pokemonhackstudio/rom-mutations/test")
        XCTAssertEqual(manifest.ignoredOutputGuidance.relativeManifestPath, ".pokemonhackstudio/rom-mutations/test/manifest.json")
        XCTAssertEqual(manifest.ignoredOutputGuidance.relativeOutputROMPath, ".pokemonhackstudio/rom-mutations/test/test-patched.gba")
        XCTAssertTrue(manifest.diagnostics.contains { $0.code == "BINARY_ROM_MUTATION_DRY_RUN_ONLY" })
        XCTAssertTrue(manifest.diagnostics.contains { $0.code == "BINARY_ROM_MUTATION_IGNORED_OUTPUT_GUIDANCE" })
        XCTAssertFalse(FileManager.default.fileExists(atPath: rom.deletingLastPathComponent().appendingPathComponent(".pokemonhackstudio").path))
    }

    func testSourceTreeInputRefusesBinaryOnlyManifestPlanning() throws {
        let sourceRoot = try makeEmeraldSourceTree()

        let manifest = BinaryROMMutationDryRunManifestBuilder.build(path: sourceRoot.path)

        XCTAssertFalse(manifest.canApply)
        XCTAssertNil(manifest.baseROM)
        XCTAssertEqual(manifest.sourceTreeFirst.status, .refusedSourceTreeInput)
        XCTAssertEqual(manifest.sourceTreeFirst.canUseBinaryOnlyPlan, false)
        XCTAssertTrue(manifest.operationPreviews.isEmpty)
        XCTAssertTrue(manifest.diagnostics.contains { $0.code == "BINARY_ROM_MUTATION_SOURCE_TREE_INPUT_REFUSED" })
        XCTAssertFalse(FileManager.default.fileExists(atPath: sourceRoot.appendingPathComponent(".pokemonhackstudio").path))
    }

    func testWorkspaceSourceCandidateRefusesBinaryOnlyOperationPreviews() throws {
        let temp = try makeTemporaryDirectory()
        let rom = try makeSyntheticGBA(in: temp.url)
        let sourceRoot = temp.url.appendingPathComponent("pokeemerald")
        try makeEmeraldSourceTree(at: sourceRoot)

        let manifest = BinaryROMMutationDryRunManifestBuilder.build(
            path: rom.path,
            request: BinaryROMMutationDryRunRequest(
                workspaceRoot: temp.url.path,
                replacements: [
                    BinaryROMMutationReplacementRequest(offset: 0x120, length: 2, replacementBytes: [0xAA, 0xBB])
                ]
            )
        )

        XCTAssertFalse(manifest.canApply)
        XCTAssertNotNil(manifest.baseROM)
        XCTAssertEqual(manifest.sourceTreeFirst.status, .refusedSourceTreeAvailable)
        XCTAssertEqual(manifest.sourceTreeFirst.canUseBinaryOnlyPlan, false)
        XCTAssertEqual(manifest.sourceTreeFirst.sourceCandidates.first?.path, sourceRoot.path)
        XCTAssertTrue(manifest.operationPreviews.isEmpty)
        XCTAssertTrue(manifest.diagnostics.contains { $0.code == "BINARY_ROM_MUTATION_SOURCE_TREE_AVAILABLE_REFUSED" })
        XCTAssertFalse(FileManager.default.fileExists(atPath: temp.url.appendingPathComponent(".pokemonhackstudio").path))
    }

    func testDiagnosticsCoverHashBoundsHeaderOverlapPointerAndFreeSpaceFailures() throws {
        let rom = try makeSyntheticGBA()

        let manifest = BinaryROMMutationDryRunManifestBuilder.build(
            path: rom.path,
            request: BinaryROMMutationDryRunRequest(
                expectedSHA1: "0000000000000000000000000000000000000000",
                replacements: [
                    BinaryROMMutationReplacementRequest(offset: 0x10, length: 4, replacementBytes: [0x01, 0x02]),
                    BinaryROMMutationReplacementRequest(offset: 0x11, length: 2, replacementBytes: [0x03, 0x04]),
                    BinaryROMMutationReplacementRequest(offset: 0x23F, length: 4, replacementBytes: [0x05, 0x06, 0x07, 0x08])
                ],
                repoints: [
                    BinaryROMMutationRepointRequest(pointerOffset: 0x104, newTargetOffset: 0x500)
                ],
                allocations: [
                    BinaryROMMutationAllocationRequest(byteCount: 0x200, alignment: 0x10)
                ]
            )
        )

        XCTAssertFalse(manifest.canApply)
        let codes = Set(manifest.diagnostics.map(\.code))
        XCTAssertTrue(codes.contains("BINARY_ROM_MUTATION_BASE_SHA1_MISMATCH"))
        XCTAssertTrue(codes.contains("BINARY_ROM_MUTATION_REPLACEMENT_LENGTH_MISMATCH"))
        XCTAssertTrue(codes.contains("BINARY_ROM_MUTATION_HEADER_REGION_BLOCKED"))
        XCTAssertTrue(codes.contains("BINARY_ROM_MUTATION_REPLACEMENT_OVERLAP"))
        XCTAssertTrue(codes.contains("BINARY_ROM_MUTATION_RANGE_OUT_OF_BOUNDS"))
        XCTAssertTrue(codes.contains("BINARY_ROM_MUTATION_POINTER_CANDIDATE_MISSING"))
        XCTAssertTrue(codes.contains("BINARY_ROM_MUTATION_POINTER_TARGET_OUT_OF_BOUNDS"))
        XCTAssertTrue(codes.contains("BINARY_ROM_MUTATION_ROM_EXPANSION_BLOCKED"))
        XCTAssertTrue(codes.contains("BINARY_ROM_MUTATION_FREE_SPACE_INSUFFICIENT"))
        XCTAssertTrue(manifest.operationPreviews.allSatisfy { !$0.canApply })
        XCTAssertTrue(manifest.operationPreviews.contains { $0.status == .blocked })
        XCTAssertFalse(FileManager.default.fileExists(atPath: rom.deletingLastPathComponent().appendingPathComponent(".pokemonhackstudio").path))
    }

    private func makeSyntheticGBA(in root: URL? = nil) throws -> URL {
        let directory = try root.map { BinaryROMMutationManifestTemporaryDirectory(existingURL: $0) } ?? makeTemporaryDirectory()
        let rom = directory.url.appendingPathComponent("test.gba")
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
        try Data(bytes).write(to: rom)
        return rom
    }

    private func makeEmeraldSourceTree() throws -> URL {
        let temp = try makeTemporaryDirectory()
        try makeEmeraldSourceTree(at: temp.url)
        return temp.url
    }

    private func makeEmeraldSourceTree(at root: URL) throws {
        try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try FileManager.default.createDirectory(at: root.appendingPathComponent("include"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("src"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("graphics/pokenav"), withIntermediateDirectories: true)
    }

    private func makeTemporaryDirectory() throws -> BinaryROMMutationManifestTemporaryDirectory {
        let temp = try BinaryROMMutationManifestTemporaryDirectory()
        temporaryDirectories.append(temp)
        return temp
    }

    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
}

private final class BinaryROMMutationManifestTemporaryDirectory {
    let url: URL
    private let removesOnDeinit: Bool

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("BinaryROMMutationDryRunManifestTests")
            .appendingPathComponent(UUID().uuidString)
        removesOnDeinit = true
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    init(existingURL: URL) {
        url = existingURL
        removesOnDeinit = false
    }

    deinit {
        guard removesOnDeinit else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
