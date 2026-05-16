import XCTest
@testable import PokemonHackCore

final class NDSDataCatalogTests: XCTestCase {
    private var temporaryDirectories: [NDSDataCatalogTemporaryDirectory] = []

    override func tearDown() {
        temporaryDirectories.removeAll()
        super.tearDown()
    }

    func testPlatinumSemanticSourcePathsBuildReadOnlyCatalog() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)

        let index = try GameAdapterRegistry.index(path: root.path)
        let catalog = NDSDataCatalogBuilder.build(index: index)

        XCTAssertEqual(catalog.profile, .pokeplatinum)
        XCTAssertEqual(catalog.family, .platinum)
        XCTAssertTrue(catalog.isReadOnly)
        XCTAssertTrue(index.capabilities.contains(.ndsDataCatalog))
        XCTAssertFalse(index.capabilities.contains(.buildRunner))
        XCTAssertFalse(index.editorModules.contains(.pokemon))
        XCTAssertEqual(count(for: .species, in: catalog), 1)
        XCTAssertEqual(count(for: .moves, in: catalog), 1)
        XCTAssertEqual(count(for: .items, in: catalog), 2)
        XCTAssertEqual(count(for: .trainers, in: catalog), 1)
        XCTAssertEqual(count(for: .encounters, in: catalog), 1)
        XCTAssertEqual(count(for: .text, in: catalog), 2)
        XCTAssertEqual(count(for: .scripts, in: catalog), 1)
        XCTAssertEqual(count(for: .maps, in: catalog), 3)
        XCTAssertEqual(count(for: .audio, in: catalog), 2)
        let personalNARC = try XCTUnwrap(catalog.records.first { $0.relativePath == "res/prebuilt/poketool/personal/personal.narc" })
        XCTAssertEqual(personalNARC.domain, .personal)
        XCTAssertEqual(personalNARC.containerSummary?.kind, .narc)
        XCTAssertEqual(personalNARC.containerSummary?.memberCount, 2)
        XCTAssertEqual(personalNARC.containerSummary?.sampleMemberPaths, ["first.bin", "second.bin"])
        XCTAssertEqual(personalNARC.containerSummary?.memberFingerprints.count, 2)
        XCTAssertEqual(personalNARC.containerSummary?.memberFingerprints.first?.formatHint, "nitroPalette")
        XCTAssertEqual(personalNARC.containerSummary?.memberFingerprints.first?.leadingMagicASCII, "NCLR")
        XCTAssertEqual(personalNARC.containerSummary?.memberFingerprints.last?.compressionHint, "lz77Candidate")
        XCTAssertEqual(personalNARC.containerSummary?.memberFingerprints.first?.preview?.status, .ready)
        XCTAssertEqual(personalNARC.containerSummary?.memberFingerprints.first?.preview?.format, "nitroPalette")
        XCTAssertTrue(personalNARC.containerSummary?.memberFingerprints.first?.preview?.blockedActions.contains("Extraction") == true)
        XCTAssertEqual(personalNARC.containerSummary?.memberFingerprints.last?.preview?.status, .blocked)
        XCTAssertTrue(personalNARC.containerSummary?.memberFingerprints.last?.preview?.diagnostics.contains { $0.code == "NDS_DATA_MEMBER_PREVIEW_COMPRESSED_BLOCKED" } == true)
        XCTAssertTrue(personalNARC.facts.contains { $0.label == "Member Hints" && $0.value.contains("nitroPalette") })
        XCTAssertTrue(personalNARC.facts.contains { $0.label == "Compression Hints" && $0.value.contains("lz77Candidate") })
        XCTAssertTrue(personalNARC.facts.contains { $0.label == "Preview Hints" && $0.value.contains("nitroPalette") })
        XCTAssertTrue(personalNARC.facts.contains { $0.label == "Blocked Previews" && $0.value == "1" })
        XCTAssertEqual(personalNARC.migrationPlan?.status, .previewOnly)
        XCTAssertTrue(personalNARC.migrationPlan?.sourceTreeCandidates.contains("res/prebuilt/poketool/personal/personal.narc") == true)
        XCTAssertTrue(personalNARC.migrationPlan?.extractedDirectoryCandidates.contains("res/prebuilt/poketool/personal/personal") == true)
        XCTAssertTrue(personalNARC.migrationPlan?.unsupportedSteps.contains("Decode container members") == true)
        XCTAssertTrue(personalNARC.migrationPlan?.blockedActions.contains("NARC repack") == true)
        XCTAssertTrue(personalNARC.diagnostics.contains { $0.code == "NDS_DATA_MIGRATION_PREVIEW_ONLY" })
        XCTAssertTrue(personalNARC.facts.contains { $0.label == "Migration Status" && $0.value == "previewOnly" })
        XCTAssertTrue(personalNARC.facts.contains { $0.label == "Source Candidates" && $0.value.contains("files/poketool/personal/personal.narc") })
        XCTAssertTrue(personalNARC.facts.contains { $0.label == "Extracted Candidates" && $0.value.contains("res/prebuilt/poketool/personal/personal") })
        XCTAssertTrue(personalNARC.facts.contains { $0.label == "Migration Blocked Actions" && $0.value.contains("ROM export") })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "res/pokemon/abra/data.json" && $0.format == .json && $0.recordCount == 1 })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "res/items/potion.json" && $0.format == .json && $0.recordCount == 1 })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "res/items/items.csv" && $0.format == .csv && $0.recordCount == 1 })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "platinum.us/filesys.csv" && $0.role == .nitroFSManifest })
        let routeMap = try XCTUnwrap(catalog.records.first { $0.relativePath == "res/field/maps/route201/map.bin" })
        XCTAssertEqual(routeMap.readiness?.status, .ready)
        XCTAssertTrue(routeMap.relatedRecords.contains { $0.recordID == "maps:res/field/matrices/route201.json" && $0.label == "Matrix" })
        XCTAssertTrue(routeMap.relatedRecords.contains { $0.recordID == "scripts:res/field/scripts/route201.s" && $0.label == "Script resource" })
        XCTAssertTrue(routeMap.relatedRecords.contains { $0.recordID == "text:res/text/route201.txt" && $0.label == "Text bank" })
        XCTAssertTrue(routeMap.facts.contains { $0.label == "Related Rows" && $0.value == "4" })
        XCTAssertTrue(routeMap.diagnostics.contains { $0.code == "NDS_DATA_READINESS_PREVIEW_ONLY" })
        let filesys = try XCTUnwrap(catalog.records.first { $0.relativePath == "platinum.us/filesys.csv" })
        XCTAssertEqual(filesys.readiness?.status, .partial)
        XCTAssertTrue(filesys.readiness?.blockedActions.contains("ROM rebuild") == true)
        let textBank = try XCTUnwrap(catalog.records.first { $0.relativePath == "res/text/route201.txt" })
        XCTAssertEqual(textBank.textBankPreview?.status, .ready)
        XCTAssertEqual(textBank.textBankPreview?.decodedStringCount, 2)
        XCTAssertTrue(textBank.facts.contains { $0.label == "Text Bank Preview" && $0.value == "ready" })
        XCTAssertTrue(textBank.facts.contains { $0.label == "Decoded Strings" && $0.value == "2" })
        XCTAssertTrue(textBank.facts.contains { $0.label == "Text Samples" && $0.value.contains("hello") && $0.value.contains("world") })
        XCTAssertTrue(textBank.diagnostics.contains { $0.code == "NDS_TEXT_BANK_PREVIEW_READ_ONLY" })
        XCTAssertTrue(textBank.readiness?.blockedActions.contains("Text-bank writer") == true)
        let bmgBank = try XCTUnwrap(catalog.records.first { $0.relativePath == "res/text/battle.bmg" })
        XCTAssertEqual(bmgBank.textBankPreview?.status, .ready)
        XCTAssertEqual(bmgBank.textBankPreview?.format, "messageBank")
        XCTAssertTrue(bmgBank.facts.contains { $0.label == "Decoded Strings" && $0.value == "3" })
        XCTAssertTrue(bmgBank.diagnostics.contains { $0.code == "NDS_TEXT_BANK_BINARY_PREVIEW_READ_ONLY" })
        let soundArchive = try XCTUnwrap(catalog.records.first { $0.relativePath == "res/sound/main.sdat" })
        XCTAssertEqual(soundArchive.domain, .audio)
        XCTAssertEqual(soundArchive.audioPreview?.status, .ready)
        XCTAssertEqual(soundArchive.audioPreview?.format, "nitroSoundArchive")
        XCTAssertTrue(soundArchive.audioPreview?.detectedHints.contains("nitroSoundArchive") == true)
        XCTAssertTrue(soundArchive.audioPreview?.blockedActions.contains("Playback") == true)
        XCTAssertTrue(soundArchive.audioPreview?.blockedActions.contains("Mutation apply") == true)
        XCTAssertTrue(soundArchive.diagnostics.contains { $0.code == "NDS_AUDIO_PREVIEW_READ_ONLY" })
        XCTAssertTrue(soundArchive.facts.contains { $0.label == "Audio Preview" && $0.value == "ready" })
        XCTAssertTrue(soundArchive.facts.contains { $0.label == "Audio Format" && $0.value == "nitroSoundArchive" })
        XCTAssertTrue(soundArchive.facts.contains { $0.label == "Audio Preview Blocked Actions" && $0.value.contains("ROM export") })
        XCTAssertEqual(soundArchive.readiness?.status, .partial)
        XCTAssertTrue(soundArchive.readiness?.blockedActions.contains("Audio decode") == true)
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "NDS_DATA_CATALOG_READ_ONLY" })
    }

    func testHeartGoldCatalogIncludesNARCPlaceholderAndSourceAnchors() throws {
        let root = try makeRoot(name: "pokeheartgold", configure: makeHeartGoldFixture)

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        XCTAssertEqual(catalog.profile, .pokeheartgold)
        XCTAssertEqual(catalog.family, .heartGoldSoulSilver)
        let movesNARC = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/poketool/waza/waza_tbl.narc" })
        XCTAssertEqual(movesNARC.domain, .moves)
        XCTAssertEqual(movesNARC.format, .narc)
        XCTAssertEqual(movesNARC.role, .binaryContainer)
        XCTAssertEqual(movesNARC.recordCount, 2)
        XCTAssertEqual(movesNARC.containerSummary?.namedMemberCount, 2)
        XCTAssertEqual(movesNARC.containerSummary?.memberFingerprints.first?.formatHint, "nitroPalette")
        let malformedNARC = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/data/broken.narc" })
        XCTAssertTrue(malformedNARC.diagnostics.contains { $0.code == "NARC_REQUIRED_BLOCK_MISSING" })
        XCTAssertEqual(malformedNARC.containerSummary?.memberFingerprints, [])
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "src/data/map_headers.h" && $0.domain == .maps && $0.format == .cHeader })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "files/fielddata/eventdata/zone_event/zone_001.json" && $0.domain == .scripts })
        let matrix = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/mapmatrix/0001.bin" })
        XCTAssertEqual(matrix.readiness?.status, .ready)
        XCTAssertTrue(matrix.relatedRecords.contains { $0.recordID == "scripts:files/fielddata/script/scr_seq/0001.bin" })
        XCTAssertTrue(matrix.relatedRecords.contains { $0.recordID == "text:files/msgdata/msg/0001.txt" })
        XCTAssertTrue(matrix.relatedRecords.contains { $0.recordID == "scripts:files/fielddata/eventdata/zone_event/zone_001.json" })
        XCTAssertTrue(catalog.summary.nitroFSBackedCount > 0)
        XCTAssertTrue(catalog.isReadOnly)
    }

    func testDiamondCatalogKeepsCSourceAnchorsConservative() throws {
        let root = try makeRoot(name: "pokediamond", configure: makeDiamondFixture)

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        XCTAssertEqual(catalog.profile, .pokediamond)
        XCTAssertEqual(catalog.family, .diamondPearl)
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "arm9/src/pokemon.c" && $0.domain == .species && $0.format == .cSource })
        let scriptSource = try XCTUnwrap(catalog.records.first { $0.relativePath == "arm9/src/script.c" && $0.domain == .scripts && $0.format == .cSource })
        XCTAssertEqual(scriptSource.readiness?.status, .ready)
        XCTAssertTrue(scriptSource.relatedRecords.contains { $0.recordID == "maps:arm9/src/map_header.c" && $0.label == "Map header" })
        XCTAssertTrue(scriptSource.relatedRecords.contains { $0.recordID == "text:arm9/src/msgdata.c" && $0.label == "Text bank" })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "files/fielddata/mapmatrix/matrix.bin" && $0.domain == .maps && $0.format == .binary })
        let unpacked = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/script/scr_seq_release" })
        XCTAssertEqual(unpacked.domain, .scripts)
        XCTAssertEqual(unpacked.containerSummary?.kind, .unpackedArchiveDirectory)
        XCTAssertEqual(unpacked.containerSummary?.memberCount, 2)
        XCTAssertEqual(unpacked.containerSummary?.unnamedMemberCount, 2)
        XCTAssertEqual(unpacked.containerSummary?.memberFingerprints.count, 2)
        XCTAssertEqual(unpacked.containerSummary?.memberFingerprints.first?.formatHint, "nitroPalette")
        XCTAssertEqual(unpacked.containerSummary?.memberFingerprints.first?.preview?.status, .ready)
        XCTAssertEqual(unpacked.containerSummary?.memberFingerprints.first?.preview?.format, "nitroPalette")
        XCTAssertEqual(unpacked.containerSummary?.memberFingerprints.last?.formatHint, "unknown")
        XCTAssertEqual(unpacked.containerSummary?.memberFingerprints.last?.confidence, "low")
        XCTAssertEqual(unpacked.containerSummary?.memberFingerprints.last?.preview?.status, .blocked)
        XCTAssertTrue(unpacked.containerSummary?.memberFingerprints.last?.preview?.diagnostics.contains { $0.code == "NDS_DATA_MEMBER_PREVIEW_UNSUPPORTED" } == true)
        XCTAssertEqual(unpacked.migrationPlan?.status, .previewOnly)
        XCTAssertTrue(unpacked.migrationPlan?.extractedDirectoryCandidates.contains("files/fielddata/script/scr_seq_release.d") == true)
        XCTAssertTrue(unpacked.facts.contains { $0.label == "Migration Status" && $0.value == "previewOnly" })
        XCTAssertEqual(unpacked.readiness?.status, .blocked)
        XCTAssertTrue(unpacked.diagnostics.contains { $0.code == "NDS_DATA_READINESS_WRITE_BLOCKED" })
        XCTAssertTrue(catalog.isReadOnly)
    }

    func testPMDSkyReportsSpinOffInventoryOnly() throws {
        let root = try makeRoot(name: "pmd-sky", configure: makePMDSkyFixture)

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        XCTAssertEqual(catalog.profile, .pmdSky)
        XCTAssertEqual(catalog.family, .ndsUnknown)
        XCTAssertTrue(catalog.records.allSatisfy { $0.domain == .resources })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "files/MESSAGE/text_us.str" })
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "NDS_DATA_CATALOG_SPINOFF_DEFERRED" })
        XCTAssertTrue(catalog.isReadOnly)
    }

    func testBinaryNDSROMSurfacesReadOnlyNARCSummaries() throws {
        let temp = try NDSDataCatalogTemporaryDirectory()
        temporaryDirectories.append(temp)
        let rom = temp.url.appendingPathComponent("diamond.nds")
        try syntheticNDSROM().write(to: rom)

        let catalog = try NDSDataCatalogBuilder.build(path: rom.path)

        XCTAssertEqual(catalog.profile, .ndsROM)
        XCTAssertEqual(catalog.family, .diamondPearl)
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "sub/child.narc" && $0.domain == .resources })
        let narc = try XCTUnwrap(catalog.records.first { $0.relativePath == "sub/child.narc" })
        XCTAssertEqual(narc.containerSummary?.kind, .narc)
        XCTAssertEqual(narc.containerSummary?.memberCount, 2)
        XCTAssertEqual(narc.containerSummary?.memberFingerprints.first?.formatHint, "nitroPalette")
        XCTAssertEqual(narc.containerSummary?.memberFingerprints.first?.preview?.status, .ready)
        XCTAssertEqual(narc.containerSummary?.memberFingerprints.first?.preview?.format, "nitroPalette")
        XCTAssertEqual(narc.preview, "first.bin, second.bin")
        XCTAssertEqual(narc.migrationPlan?.status, .previewOnly)
        XCTAssertTrue(narc.migrationPlan?.sourceTreeCandidates.contains("files/sub/child.narc") == true)
        XCTAssertTrue(narc.migrationPlan?.extractedDirectoryCandidates.contains("sub/child") == true)
        XCTAssertTrue(narc.migrationPlan?.blockedActions.contains("ROM extraction") == true)
        XCTAssertTrue(narc.facts.contains { $0.label == "Migration Status" && $0.value == "previewOnly" })
        XCTAssertTrue(narc.facts.contains { $0.label == "Unsupported Migration Steps" && $0.value.contains("Preserve file ordering") })
        let romAudio = try XCTUnwrap(catalog.records.first { $0.relativePath == "sound_data.sdat" && $0.domain == .audio })
        XCTAssertEqual(romAudio.audioPreview?.status, .ready)
        XCTAssertEqual(romAudio.audioPreview?.format, "nitroSoundArchive")
        XCTAssertTrue(romAudio.facts.contains { $0.label == "Audio Preview" && $0.value == "ready" })
        XCTAssertTrue(romAudio.facts.contains { $0.label == "Audio Preview Blocked Actions" && $0.value.contains("Extraction") })
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "NDS_DATA_CATALOG_BINARY_SUMMARY_READ_ONLY" })
        XCTAssertTrue(catalog.isReadOnly)

        let entry = GenIIIResourceRegistry.resourceIndex(path: rom.path)
        let resourceItem = try XCTUnwrap(entry.items.first { $0.category == "NDS Data resources" && $0.path == "sub/child.narc" })
        XCTAssertTrue(resourceItem.facts.contains { $0.label == "Migration Status" && $0.value == "previewOnly" })
        XCTAssertTrue(resourceItem.facts.contains { $0.label == "Migration Blocked Actions" && $0.value.contains("ROM export") })
        let audioResourceItem = try XCTUnwrap(entry.items.first { $0.category == "NDS Data audio" && $0.path == "sound_data.sdat" })
        XCTAssertTrue(audioResourceItem.facts.contains { $0.label == "Audio Format" && $0.value == "nitroSoundArchive" })
        let assetCatalog = GenIIIAssetCatalogBuilder.build(path: rom.path)
        let resourceAsset = try XCTUnwrap(assetCatalog.assets.first {
            $0.relativePath == "sub/child.narc"
                && $0.tags.contains("ndsROM")
                && $0.facts.contains { $0.label == "Migration Status" && $0.value == "previewOnly" }
        })
        XCTAssertTrue(resourceAsset.facts.contains { $0.label == "Migration Blocked Actions" && $0.value.contains("ROM export") })
    }

    func testResourceRegistrySurfacesCatalogRowsForNDSSourceRoots() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)

        let entry = GenIIIResourceRegistry.resourceIndex(path: root.path)
        let assetCatalog = GenIIIAssetCatalogBuilder.build(path: root.path)

        XCTAssertEqual(entry.platform, .ndsSource)
        XCTAssertEqual(entry.writePolicy, .readOnly)
        XCTAssertTrue(entry.items.contains { $0.category == "NDS Data species" && $0.path == "res/pokemon/abra/data.json" })
        XCTAssertTrue(entry.items.contains { $0.category == "NDS Data items" && $0.path == "res/items/items.csv" })
        let personalItem = try XCTUnwrap(entry.items.first { $0.category == "NDS Data personal" && $0.path == "res/prebuilt/poketool/personal/personal.narc" })
        XCTAssertEqual(personalItem.kind, "narc (2 members)")
        XCTAssertEqual(personalItem.uncompressedSize, 2)
        XCTAssertTrue(personalItem.facts.contains { $0.label == "Preview Hints" && $0.value.contains("nitroPalette") })
        XCTAssertTrue(personalItem.facts.contains { $0.label == "Blocked Previews" && $0.value == "1" })
        XCTAssertTrue(personalItem.facts.contains { $0.label == "Migration Status" && $0.value == "previewOnly" })
        XCTAssertTrue(personalItem.facts.contains { $0.label == "Source Candidates" && $0.value.contains("files/poketool/personal/personal.narc") })
        let mapItem = try XCTUnwrap(entry.items.first { $0.category == "NDS Data maps" && $0.path == "res/field/maps/route201/map.bin" })
        XCTAssertTrue(mapItem.facts.contains { $0.label == "Readiness" && $0.value == "ready" })
        XCTAssertTrue(mapItem.facts.contains { $0.label == "Related Domains" && $0.value.contains("scripts") })
        let textItem = try XCTUnwrap(entry.items.first { $0.category == "NDS Data text" && $0.path == "res/text/route201.txt" })
        XCTAssertTrue(textItem.facts.contains { $0.label == "Decoded Strings" && $0.value == "2" })
        XCTAssertTrue(textItem.facts.contains { $0.label == "Text Samples" && $0.value.contains("hello") })
        let audioItem = try XCTUnwrap(entry.items.first { $0.category == "NDS Data audio" && $0.path == "res/sound/main.sdat" })
        XCTAssertTrue(audioItem.facts.contains { $0.label == "Audio Preview" && $0.value == "ready" })
        XCTAssertTrue(audioItem.facts.contains { $0.label == "Audio Preview Blocked Actions" && $0.value.contains("Playback") })
        XCTAssertTrue(assetCatalog.assets.contains { $0.relativePath == "res/pokemon/abra/data.json" && $0.category == .species })
        XCTAssertTrue(assetCatalog.assets.contains { $0.relativePath == "res/items/items.csv" && $0.category == .items })
        XCTAssertTrue(assetCatalog.assets.contains { $0.relativePath == "res/sound/main.sdat" && $0.category == .audio })
        let personalAsset = try XCTUnwrap(assetCatalog.assets.first { $0.relativePath == "res/prebuilt/poketool/personal/personal.narc" })
        XCTAssertTrue(personalAsset.facts.contains { $0.label == "Preview Hints" && $0.value.contains("nitroPalette") })
        XCTAssertTrue(personalAsset.facts.contains { $0.label == "Migration Status" && $0.value == "previewOnly" })
        let mapAsset = try XCTUnwrap(assetCatalog.assets.first { $0.relativePath == "res/field/maps/route201/map.bin" })
        XCTAssertTrue(mapAsset.facts.contains { $0.label == "Readiness" && $0.value == "ready" })
        XCTAssertTrue(mapAsset.tags.contains("ndsSource"))
        let textAsset = try XCTUnwrap(assetCatalog.assets.first { $0.relativePath == "res/text/route201.txt" })
        XCTAssertTrue(textAsset.facts.contains { $0.label == "Text Bank Preview" && $0.value == "ready" })
        XCTAssertTrue(textAsset.facts.contains { $0.label == "Decoded Strings" && $0.value == "2" })
    }

    func testNDSContainerFingerprintsStayBoundedAndReadOnlyWhenBytesAreUnavailable() throws {
        let members = (0..<10).map { index in
            NARCMember(
                fileID: index,
                path: "member_\(index).nclr",
                name: "member_\(index).nclr",
                offset: UInt64(index * 4),
                size: 4
            )
        }
        let index = NARCIndex(path: "broken.narc", byteCount: 8, gmifDataOffset: 1024, members: members)

        let fingerprints = NDSDataCatalogBuilder.memberFingerprints(for: index, data: Data("NARC".utf8))

        XCTAssertEqual(fingerprints.count, 8)
        XCTAssertEqual(fingerprints.first?.memberIndex, 0)
        XCTAssertEqual(fingerprints.last?.memberIndex, 7)
        XCTAssertTrue(fingerprints.allSatisfy { $0.diagnostics.contains { $0.code == "NDS_DATA_MEMBER_FINGERPRINT_UNAVAILABLE" } })
        XCTAssertTrue(fingerprints.allSatisfy { $0.preview?.status == .blocked })
        XCTAssertTrue(fingerprints.allSatisfy { $0.preview?.diagnostics.contains { $0.code == "NDS_DATA_MEMBER_PREVIEW_TOO_SHORT" } == true })
        XCTAssertTrue(fingerprints.allSatisfy { $0.preview?.blockedActions.contains("Mutation apply") == true })
    }

    func testNDSDataMutationPlanAppliesSourceBackedJSONRecordWithBackup() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let draft = NDSDataEditDraft(recordID: "species:res/pokemon/abra/data.json", editedText: "{\"base_hp\":26}\n")

        let plan = NDSDataMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertTrue(plan.diagnostics.allSatisfy { $0.severity != .error }, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(plan.changes.count, 1)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_GENERATED_OUTPUTS_STALE" })
        XCTAssertTrue(plan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("res/pokemon/abra/data.json"), encoding: .utf8),
            "{\"base_hp\":26}\n"
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))
    }

    func testNDSDataSemanticEditorPlansFieldLevelJSONEditsThroughMutationGate() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "species:res/pokemon/abra/data.json")
        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(snapshot.fields.first?.key, "base_hp")
        XCTAssertEqual(snapshot.fields.first?.value, "25")
        XCTAssertTrue(snapshot.fields.contains { $0.key == "evolutions.0.method" && $0.value == "EVO_LEVEL" && $0.valueKind == .string })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "evolutions.0.parameter" && $0.value == "16" && $0.valueKind == .number })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "evolutions.0.target" && $0.value == "SPECIES_KADABRA" && $0.valueKind == .string })

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "species:res/pokemon/abra/data.json",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "base_hp", value: "28"),
                    NDSDataSemanticFieldEdit(key: "evolutions.0.parameter", value: "22")
                ]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"base_hp\":28"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("[\"EVO_LEVEL\",22,\"SPECIES_KADABRA\"]"))
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("res/pokemon/abra/data.json"), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"base_hp\":28"))
        XCTAssertTrue(updated.contains("[\"EVO_LEVEL\",22,\"SPECIES_KADABRA\"]"))
    }

    func testNDSDataSemanticEditorBlocksDuplicateFieldEditsBeforeLowering() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "species:res/pokemon/abra/data.json",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "evolutions.0.parameter", value: "22"),
                    NDSDataSemanticFieldEdit(key: "evolutions.0.parameter", value: "24")
                ]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FIELD_DUPLICATE" })
        XCTAssertTrue(semanticPlan.editPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FIELD_DUPLICATE" })
        XCTAssertEqual(semanticPlan.textDraft.editedText, "{\"base_hp\":25,\"evolutions\":[[\"EVO_LEVEL\",16,\"SPECIES_KADABRA\"]]}\n")
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 0)
        XCTAssertFalse(semanticPlan.editPlan.validateApplyability().isApplyable)
    }

    func testNDSDataSemanticParserReportsDeterministicSourceDiagnostics() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)

        try write("{\"base_hp\":25,\"base_hp\":26}\n", to: root.appendingPathComponent("res/pokemon/abra/data.json"))
        var catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let duplicatePlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "species:res/pokemon/abra/data.json",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "base_hp", value: "27")]
            )
        )
        XCTAssertTrue(duplicatePlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_JSON_KEY_DUPLICATE" })
        XCTAssertTrue(duplicatePlan.editPlan.changes.isEmpty)

        try write("{\"base_hp\": nope}\n", to: root.appendingPathComponent("res/pokemon/abra/data.json"))
        catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let malformedPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "species:res/pokemon/abra/data.json",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "base_hp", value: "27")]
            )
        )
        XCTAssertTrue(malformedPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_JSON_MALFORMED" })
        XCTAssertTrue(malformedPlan.editPlan.changes.isEmpty)

        try write("{\"base_hp\":25,\"evolutions\":[[\"EVO_LEVEL\",{\"level\":16},\"SPECIES_KADABRA\",true]],\"party\":[{\"level\":5}]}\n", to: root.appendingPathComponent("res/pokemon/abra/data.json"))
        catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let badScalarPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "species:res/pokemon/abra/data.json",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "base_hp", value: "not-a-number"),
                    NDSDataSemanticFieldEdit(key: "party.0.level", value: "6")
                ]
            )
        )
        XCTAssertTrue(badScalarPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_VALUE_INVALID" })
        XCTAssertTrue(badScalarPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertTrue(badScalarPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_EVOLUTION_TUPLE_BAD_SHAPE" })
        XCTAssertTrue(badScalarPlan.editPlan.changes.isEmpty)
    }

    func testNDSDataBackupRootsAreCollisionResistantAcrossRapidPlans() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let draft = NDSDataEditDraft(recordID: "species:res/pokemon/abra/data.json", editedText: "{\"base_hp\":26}\n")

        let first = NDSDataMutationPlanner.plan(catalog: catalog, draft: draft)
        let second = NDSDataMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertNotEqual(first.backupRelativeRoot, second.backupRelativeRoot)
        XCTAssertTrue(first.backupRelativeRoot.hasPrefix(".pokemonhackstudio/backups/"))
        XCTAssertTrue(second.backupRelativeRoot.hasPrefix(".pokemonhackstudio/backups/"))
    }

    func testNDSDataCatalogRecordCopyPreservesEnrichedMetadata() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let record = try XCTUnwrap(catalog.records.first { $0.relativePath == "res/prebuilt/poketool/personal/personal.narc" })

        let copied = record.copy(
            relatedRecords: [NDSDataRelatedRecord(recordID: "text:res/text/route201.txt", label: "Text bank", domain: .text, relativePath: "res/text/route201.txt")],
            readiness: .some(NDSDataReadinessSummary(status: .blocked, title: "Copied", detail: "Copied detail.", blockedActions: ["Mutation apply"]))
        )

        XCTAssertEqual(copied.containerSummary, record.containerSummary)
        XCTAssertEqual(copied.migrationPlan, record.migrationPlan)
        XCTAssertEqual(copied.textBankPreview, record.textBankPreview)
        XCTAssertEqual(copied.audioPreview, record.audioPreview)
        XCTAssertEqual(copied.facts, record.facts)
        XCTAssertEqual(copied.diagnostics, record.diagnostics)
        XCTAssertEqual(copied.relatedRecords.count, 1)
        XCTAssertEqual(copied.readiness?.title, "Copied")
    }

    func testNDSDataCatalogSourceFingerprintTracksNDSInputs() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let first = try NDSDataCatalogBuilder.sourceFingerprint(path: root.path)

        try write("{\"base_hp\":26,\"evolutions\":[[\"EVO_LEVEL\",16,\"SPECIES_KADABRA\"]]}\n", to: root.appendingPathComponent("res/pokemon/abra/data.json"))
        let second = try NDSDataCatalogBuilder.sourceFingerprint(path: root.path)

        XCTAssertNotEqual(first, second)
        XCTAssertEqual(first.count, 40)
        XCTAssertEqual(second.count, 40)
    }

    func testNDSDataCatalogSourceFingerprintTracksNDSROMBytes() throws {
        let temp = try NDSDataCatalogTemporaryDirectory()
        temporaryDirectories.append(temp)
        let rom = temp.url.appendingPathComponent("diamond.nds")
        var bytes = syntheticNDSROM()
        try bytes.write(to: rom)
        let first = try NDSDataCatalogBuilder.sourceFingerprint(path: rom.path)

        bytes[0x200] = 0x7f
        try bytes.write(to: rom)
        let second = try NDSDataCatalogBuilder.sourceFingerprint(path: rom.path)

        XCTAssertNotEqual(first, second)
        XCTAssertEqual(first.count, 40)
        XCTAssertEqual(second.count, 40)
    }

    func testNDSDataSemanticEditorPlansTrainerScalarEditsOnlyForTrainerDataJSON() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        try write("{\"cell_animation\":1}\n", to: root.appendingPathComponent("res/trainers/classes/youngster.json"))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "trainers:res/trainers/data/youngster.json")
        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(snapshot.fields.contains { $0.key == "name" && $0.value == "Youngster" && $0.valueKind == .string })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "class" && $0.value == "TRAINER_CLASS_YOUNGSTER" && $0.valueKind == .string })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "double_battle" && $0.value == "false" && $0.valueKind == .bool })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "party" })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "items" })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "messages" })

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "trainers:res/trainers/data/youngster.json",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "name", value: "Youngster Ben"),
                    NDSDataSemanticFieldEdit(key: "double_battle", value: "true")
                ]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"name\": \"Youngster Ben\""))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"double_battle\": true"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"party\": [{\"species\":\"STARLY\",\"level\":5}]"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"messages\": [\"I like shorts!\"]"))
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("res/trainers/data/youngster.json"), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"name\": \"Youngster Ben\""))
        XCTAssertTrue(updated.contains("\"double_battle\": true"))
        XCTAssertTrue(updated.contains("\"party\": [{\"species\":\"STARLY\",\"level\":5}]"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let classSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "trainers:res/trainers/classes/youngster.json")
        XCTAssertFalse(classSnapshot.canEdit)
        XCTAssertTrue(classSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_TRAINER_PATH_BLOCKED" })

        let blockedClassPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "trainers:res/trainers/classes/youngster.json",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "cell_animation", value: "2")]
            )
        )
        XCTAssertTrue(blockedClassPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_TRAINER_PATH_BLOCKED" })
        XCTAssertTrue(blockedClassPlan.editPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_TRAINER_PATH_BLOCKED" })
        XCTAssertEqual(blockedClassPlan.editPlan.changes.count, 0)
        XCTAssertFalse(blockedClassPlan.editPlan.validateApplyability().isApplyable)
    }

    func testNDSDataSemanticEditorPlansItemScalarEditsOnlyForPlatinumItemJSON() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "items:res/items/potion.json")
        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(snapshot.fields.contains { $0.key == "name" && $0.value == "Potion" && $0.valueKind == .string })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "price" && $0.value == "300" && $0.valueKind == .number })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "field_use" && $0.value == "true" && $0.valueKind == .bool })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "effects" })

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "items:res/items/potion.json",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "price", value: "250"),
                    NDSDataSemanticFieldEdit(key: "field_use", value: "false")
                ]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"price\": 250"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"field_use\": false"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"effects\": [{\"kind\":\"heal\",\"amount\":20}]"))
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("res/items/potion.json"), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"price\": 250"))
        XCTAssertTrue(updated.contains("\"field_use\": false"))
        XCTAssertTrue(updated.contains("\"effects\": [{\"kind\":\"heal\",\"amount\":20}]"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let csvSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "items:res/items/items.csv")
        XCTAssertFalse(csvSnapshot.canEdit)
        XCTAssertTrue(csvSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_ITEM_PATH_BLOCKED" })
        XCTAssertTrue(csvSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticEditorPlansHeartGoldSoulSilverPersonalAndTrainerJSONScalars() throws {
        let root = try makeRoot(name: "pokeheartgold", configure: makeHeartGoldFixture)
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "personal:files/poketool/personal/personal.json")
        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(snapshot.fields.map(\.key), ["species"])
        XCTAssertEqual(snapshot.fields.first?.value, "CHIKORITA")

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "personal:files/poketool/personal/personal.json",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "species", value: "CYNDAQUIL")]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"species\":\"CYNDAQUIL\""))
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("files/poketool/personal/personal.json"), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"species\":\"CYNDAQUIL\""))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let trainerSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "trainers:files/poketool/trainer/trainers.json")
        XCTAssertTrue(trainerSnapshot.canEdit, trainerSnapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(trainerSnapshot.fields.contains { $0.key == "name" && $0.value == "Youngster Joey" })
        XCTAssertTrue(trainerSnapshot.fields.contains { $0.key == "double_battle" && $0.value == "false" })
        XCTAssertFalse(trainerSnapshot.fields.contains { $0.key == "party" })

        let trainerPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "trainers:files/poketool/trainer/trainers.json",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "name", value: "Youngster Ben"),
                    NDSDataSemanticFieldEdit(key: "double_battle", value: "true")
                ]
            )
        )

        XCTAssertTrue(trainerPlan.diagnostics.allSatisfy { $0.severity != .error }, trainerPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(trainerPlan.textDraft.editedText.contains("\"name\":\"Youngster Ben\""))
        XCTAssertTrue(trainerPlan.textDraft.editedText.contains("\"double_battle\":true"))
        XCTAssertTrue(trainerPlan.textDraft.editedText.contains("\"party\":[{\"species\":\"RATTATA\",\"level\":4}]"))
        XCTAssertEqual(trainerPlan.editPlan.changes.count, 1)
        XCTAssertTrue(trainerPlan.editPlan.validateApplyability().isApplyable)

        let trainerResult = try NDSDataMutationApplier.apply(plan: trainerPlan.editPlan)
        XCTAssertEqual(trainerResult.appliedChanges.count, 1)
        let trainerUpdated = try String(contentsOf: root.appendingPathComponent("files/poketool/trainer/trainers.json"), encoding: .utf8)
        XCTAssertTrue(trainerUpdated.contains("\"name\":\"Youngster Ben\""))
        XCTAssertTrue(trainerUpdated.contains("\"double_battle\":true"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: trainerResult.appliedChanges[0].backupPath))

        let itemSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "items:files/itemtool/itemdata/item_data.csv")
        XCTAssertFalse(itemSnapshot.canEdit)
        XCTAssertTrue(itemSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })
        XCTAssertTrue(itemSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_ITEM_PATH_BLOCKED" })
    }

    func testNDSDataSemanticEditorKeepsNonPlatinumAndContainerRowsBlocked() throws {
        let platinum = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let platinumCatalog = try NDSDataCatalogBuilder.build(path: platinum.path)
        let narcSnapshot = NDSDataSemanticEditor.snapshot(catalog: platinumCatalog, recordID: "personal:res/prebuilt/poketool/personal/personal.narc")
        XCTAssertFalse(narcSnapshot.canEdit)
        XCTAssertTrue(narcSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let heartGold = try makeRoot(name: "pokeheartgold", configure: makeHeartGoldFixture)
        let heartGoldCatalog = try NDSDataCatalogBuilder.build(path: heartGold.path)
        let heartGoldItemSnapshot = NDSDataSemanticEditor.snapshot(catalog: heartGoldCatalog, recordID: "items:files/itemtool/itemdata/item_data.csv")
        XCTAssertFalse(heartGoldItemSnapshot.canEdit)
        XCTAssertTrue(heartGoldItemSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })

        let diamond = try makeRoot(name: "pokediamond", configure: makeDiamondFixture)
        let diamondCatalog = try NDSDataCatalogBuilder.build(path: diamond.path)
        let diamondSnapshot = NDSDataSemanticEditor.snapshot(catalog: diamondCatalog, recordID: "items:arm9/src/itemtool.c")
        XCTAssertFalse(diamondSnapshot.canEdit)
        XCTAssertTrue(diamondSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_PROFILE_BLOCKED" })

        let pmd = try makeRoot(name: "pmd-sky", configure: makePMDSkyFixture)
        let pmdCatalog = try NDSDataCatalogBuilder.build(path: pmd.path)
        let pmdSnapshot = NDSDataSemanticEditor.snapshot(catalog: pmdCatalog, recordID: "resources:files/MESSAGE/text_us.str")
        XCTAssertFalse(pmdSnapshot.canEdit)
        XCTAssertTrue(pmdSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_PROFILE_BLOCKED" })
    }

    func testNDSDataMutationPlanBlocksHashMismatchBeforeApply() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let draft = NDSDataEditDraft(recordID: "species:res/pokemon/abra/data.json", editedText: "{\"base_hp\":26}\n")
        let plan = NDSDataMutationPlanner.plan(catalog: catalog, draft: draft)
        try "{\"base_hp\":27,\"evolutions\":[[\"EVO_LEVEL\",16,\"SPECIES_KADABRA\"]]}\n".write(to: root.appendingPathComponent("res/pokemon/abra/data.json"), atomically: true, encoding: .utf8)

        let applyability = plan.validateApplyability()

        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(applyability.diagnostics.contains { $0.code == "NDS_DATA_APPLY_SOURCE_HASH_CHANGED" })
    }

    func testNDSDataMutationPlanBlocksInvalidJSONDraft() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let draft = NDSDataEditDraft(recordID: "species:res/pokemon/abra/data.json", editedText: "{\"base_hp\":")

        let plan = NDSDataMutationPlanner.plan(catalog: catalog, draft: draft)

        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_JSON_INVALID" })
        XCTAssertFalse(plan.validateApplyability().isApplyable)
    }

    func testNDSDataMutationPlanKeepsUnsupportedRowsReadOnly() throws {
        let platinum = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let platinumCatalog = try NDSDataCatalogBuilder.build(path: platinum.path)
        let narcDraft = NDSDataEditDraft(recordID: "personal:res/prebuilt/poketool/personal/personal.narc", editedText: "ignored")

        let narcPlan = NDSDataMutationPlanner.plan(catalog: platinumCatalog, draft: narcDraft)

        XCTAssertTrue(narcPlan.changes.isEmpty)
        XCTAssertTrue(narcPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_ROLE_BLOCKED" })
        XCTAssertTrue(narcPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_FORMAT_BLOCKED" })
        XCTAssertTrue(narcPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_CONTAINER_BLOCKED" })

        let romTemp = try NDSDataCatalogTemporaryDirectory()
        temporaryDirectories.append(romTemp)
        let rom = romTemp.url.appendingPathComponent("diamond.nds")
        try syntheticNDSROM().write(to: rom)
        let romCatalog = try NDSDataCatalogBuilder.build(path: rom.path)
        let romPlan = NDSDataMutationPlanner.plan(
            catalog: romCatalog,
            draft: NDSDataEditDraft(recordID: "resources:sub/child.narc", editedText: "ignored")
        )

        XCTAssertTrue(romPlan.changes.isEmpty)
        XCTAssertTrue(romPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_BINARY_ROM_BLOCKED" })

        let pmd = try makeRoot(name: "pmd-sky", configure: makePMDSkyFixture)
        let pmdCatalog = try NDSDataCatalogBuilder.build(path: pmd.path)
        let pmdPlan = NDSDataMutationPlanner.plan(
            catalog: pmdCatalog,
            draft: NDSDataEditDraft(recordID: "resources:files/MESSAGE/text_us.str", editedText: "hello again\n")
        )

        XCTAssertTrue(pmdPlan.changes.isEmpty)
        XCTAssertTrue(pmdPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_SPINOFF_BLOCKED" })

        let generatedPlan = NDSDataMutationPlanner.plan(
            catalog: platinumCatalog,
            draft: NDSDataEditDraft(recordID: "resources:generated/species.txt", editedText: "SPECIES_MEW\n")
        )
        XCTAssertTrue(generatedPlan.changes.isEmpty)
        XCTAssertTrue(generatedPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_ROLE_BLOCKED" })

        try Data([0xff, 0xfe]).write(to: platinum.appendingPathComponent("res/items/items.csv"))
        let nonUTF8Catalog = try NDSDataCatalogBuilder.build(path: platinum.path)
        let nonUTF8Plan = NDSDataMutationPlanner.plan(
            catalog: nonUTF8Catalog,
            draft: NDSDataEditDraft(recordID: "items:res/items/items.csv", editedText: "id,name\n1,POTION\n")
        )
        XCTAssertTrue(nonUTF8Plan.changes.isEmpty)
        XCTAssertTrue(nonUTF8Plan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_SOURCE_NOT_UTF8" })
    }

    func testNDSDataMutationPlanBlocksReferenceRoots() throws {
        let root = try makeRoot(name: "references/pokeplatinum", configure: makePlatinumFixture)
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let plan = NDSDataMutationPlanner.plan(
            catalog: catalog,
            draft: NDSDataEditDraft(recordID: "species:res/pokemon/abra/data.json", editedText: "{\"base_hp\":26}\n")
        )

        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_REFERENCE_BLOCKED" })
    }

    private func makeRoot(name: String, configure: (URL) throws -> Void) throws -> URL {
        let temp = try NDSDataCatalogTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent(name)
        try makeDirectory(root)
        try configure(root)
        return root
    }

    private func makePlatinumFixture(root: URL) throws {
        try write("rom: build/pokeplatinum.us.nds\n", to: root.appendingPathComponent("Makefile"))
        try write("project('pokeplatinum')\n", to: root.appendingPathComponent("meson.build"))
        try write("path,sha1\n", to: root.appendingPathComponent("platinum.us/filesys.csv"))
        try write("cccccccccccccccccccccccccccccccccccccccc  pokeplatinum.us.nds\n", to: root.appendingPathComponent("platinum.us/rom_rev1.sha1"))
        try makeDirectory(root.appendingPathComponent("src"))
        try makeDirectory(root.appendingPathComponent("asm"))
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
            {"name": "Youngster", "class": "TRAINER_CLASS_YOUNGSTER", "double_battle": false, "party": [{"species":"STARLY","level":5}], "items": ["POTION"], "messages": ["I like shorts!"]}

            """,
            to: root.appendingPathComponent("res/trainers/data/youngster.json")
        )
        try write("[{\"species\":\"BIDOOF\"}]\n", to: root.appendingPathComponent("res/field/encounters/route201.json"))
        try write("hello\nworld\n", to: root.appendingPathComponent("res/text/route201.txt"))
        try write(Data("BMG Test\u{0}Hello there\u{0}Goodbye\u{0}".utf8), to: root.appendingPathComponent("res/text/battle.bmg"))
        try write(Data("SDAT".utf8) + Data(repeating: 0, count: 12), to: root.appendingPathComponent("res/sound/main.sdat"))
        try write(Data("SSEQ".utf8) + Data(repeating: 0, count: 12), to: root.appendingPathComponent("res/sound/opening.sseq"))
        try write("scrcmd_end\n", to: root.appendingPathComponent("res/field/scripts/route201.s"))
        try write("{\"event\":1}\n", to: root.appendingPathComponent("res/field/events/route201.json"))
        try write(Data([0x01, 0x02]), to: root.appendingPathComponent("res/field/maps/route201/map.bin"))
        try write("{\"matrix\":1}\n", to: root.appendingPathComponent("res/field/matrices/route201.json"))
        try write(makeTestNARC(), to: root.appendingPathComponent("res/prebuilt/poketool/personal/personal.narc"))
        try write("SPECIES_ABRA\n", to: root.appendingPathComponent("generated/species.txt"))
    }

    private func makeHeartGoldFixture(root: URL) throws {
        try write("GAME_VERSION ?= HEARTGOLD\nGAME_CODE := IPK\n", to: root.appendingPathComponent("config.mk"))
        try write("ROM := $(BUILD_DIR)/poke$(buildname).nds\n", to: root.appendingPathComponent("Makefile"))
        try write("HostRoot files/\n", to: root.appendingPathComponent("rom.rsf"))
        try write("filesystem: $(NITROFS_FILES)\n", to: root.appendingPathComponent("filesystem.mk"))
        try write("dddddddddddddddddddddddddddddddddddddddd  pokeheartgold.us.nds\n", to: root.appendingPathComponent("heartgold.us/rom.sha1"))
        try makeDirectory(root.appendingPathComponent("soulsilver.us"))
        try makeDirectory(root.appendingPathComponent("files"))
        try makeDirectory(root.appendingPathComponent("src"))
        try makeDirectory(root.appendingPathComponent("asm"))
        try write("{\"species\":\"CHIKORITA\"}\n", to: root.appendingPathComponent("files/poketool/personal/personal.json"))
        try write(makeTestNARC(), to: root.appendingPathComponent("files/poketool/waza/waza_tbl.narc"))
        try write(Data("NARC".utf8) + Data(repeating: 0, count: 12), to: root.appendingPathComponent("files/data/broken.narc"))
        try write("id,name\n1,POTION\n", to: root.appendingPathComponent("files/itemtool/itemdata/item_data.csv"))
        try write("{\"id\":1,\"name\":\"Youngster Joey\",\"double_battle\":false,\"party\":[{\"species\":\"RATTATA\",\"level\":4}]}\n", to: root.appendingPathComponent("files/poketool/trainer/trainers.json"))
        try write("[{\"slot\":1}]\n", to: root.appendingPathComponent("files/fielddata/encountdata/gs_enc_data.json"))
        try write("{\"zone\":1}\n", to: root.appendingPathComponent("files/fielddata/eventdata/zone_event/zone_001.json"))
        try write("message\n", to: root.appendingPathComponent("files/msgdata/msg/0001.txt"))
        try write(Data("SDAT".utf8) + Data(repeating: 0, count: 12), to: root.appendingPathComponent("files/data/sound/sound_data.sdat"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/fielddata/script/scr_seq/0001.bin"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/fielddata/mapmatrix/0001.bin"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/fielddata/maptable/map.bin"))
        try write("#define MAP_NEW_BARK 1\n", to: root.appendingPathComponent("src/data/map_headers.h"))
    }

    private func makeDiamondFixture(root: URL) throws {
        try write("GAME_VERSION ?= DIAMOND\nGAME_CODE := ADA\n", to: root.appendingPathComponent("config.mk"))
        try write("ROM := $(BUILD_DIR)/$(TARGET).nds\n", to: root.appendingPathComponent("Makefile"))
        try write("HostRoot files/\n", to: root.appendingPathComponent("rom.rsf"))
        try write("filesystem: $(HOSTFS_FILES)\n", to: root.appendingPathComponent("filesystem.mk"))
        try write("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  build/diamond.us/pokediamond.us.nds\n", to: root.appendingPathComponent("pokediamond.us.sha1"))
        try makeDirectory(root.appendingPathComponent("files"))
        try makeDirectory(root.appendingPathComponent("arm9"))
        try makeDirectory(root.appendingPathComponent("arm7"))
        try write("void Pokemon_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/pokemon.c"))
        try write("void Waza_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/waza.c"))
        try write("void Item_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/itemtool.c"))
        try write("void Trainer_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/trainer_data.c"))
        try write("void Encounter_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/encounter.c"))
        try write("void MapHeader_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/map_header.c"))
        try write("void Script_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/script.c"))
        try write("void Message_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/msgdata.c"))
        try write("{\"personal\":1}\n", to: root.appendingPathComponent("files/poketool/personal/personal.json"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/fielddata/mapmatrix/matrix.bin"))
        try write("ignored\n", to: root.appendingPathComponent("files/fielddata/script/scr_seq_release/.knarcignore"))
        try write(Data("NCLR".utf8), to: root.appendingPathComponent("files/fielddata/script/scr_seq_release/narc_0000.nclr"))
        try write(Data([0x03]), to: root.appendingPathComponent("files/fielddata/script/scr_seq_release/narc_0001.bin"))
    }

    private func makePMDSkyFixture(root: URL) throws {
        try write("GAME_CODE := C2S\nGAME_LANGUAGE ?= NORTH_AMERICA\n", to: root.appendingPathComponent("config.mk"))
        try write("ROM := $(BUILD_DIR)/$(buildname).nds\n", to: root.appendingPathComponent("Makefile"))
        try write("HostRoot files/\n", to: root.appendingPathComponent("rom.rsf"))
        try write("NITROFS_FILES_FILE := nitrofs_files.txt\n", to: root.appendingPathComponent("filesystem.mk"))
        try write("files/MESSAGE/text_us.str\n", to: root.appendingPathComponent("nitrofs_files.txt"))
        try write("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee  pmdsky.us.nds\n", to: root.appendingPathComponent("pmdsky.us/rom.sha1"))
        try makeDirectory(root.appendingPathComponent("files"))
        try makeDirectory(root.appendingPathComponent("src"))
        try makeDirectory(root.appendingPathComponent("asm"))
        try write("hello\n", to: root.appendingPathComponent("files/MESSAGE/text_us.str"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/MONSTER/monster.md"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/BALANCE/item.dat"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/TABLEDAT/table.dat"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/DUNGEON/dungeon.bin"))
    }

    private func syntheticNDSROM() -> Data {
        var data = Data(repeating: 0, count: 0x900)
        writeASCII("POKEMON D", into: &data, at: 0x00, length: 12)
        writeASCII("ADAE", into: &data, at: 0x0C, length: 4)
        writeASCII("01", into: &data, at: 0x10, length: 2)
        data[0x14] = 0x09
        writeUInt32LE(0x200, into: &data, at: 0x20)
        writeUInt32LE(0x20, into: &data, at: 0x2C)
        writeUInt32LE(0x220, into: &data, at: 0x30)
        writeUInt32LE(0x20, into: &data, at: 0x3C)

        let fnt = syntheticFNT()
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
        return data
    }

    private func syntheticFNT() -> Data {
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

    private func count(for domain: NDSDataDomain, in catalog: ProjectNDSDataCatalog) -> Int {
        catalog.summary.domainCounts.first { $0.domain == domain }?.count ?? 0
    }

    private func makeDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private func write(_ text: String, to url: URL) throws {
        try makeDirectory(url.deletingLastPathComponent())
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func write(_ data: Data, to url: URL) throws {
        try makeDirectory(url.deletingLastPathComponent())
        try data.write(to: url)
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
}

private final class NDSDataCatalogTemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackCoreNDSDataCatalogTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
