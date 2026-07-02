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
        XCTAssertEqual(count(for: .maps, in: catalog), 4)
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
        let mapRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "res/field/maps" })
        XCTAssertEqual(mapRoot.domain, .maps)
        XCTAssertEqual(mapRoot.format, .directory)
        XCTAssertEqual(mapRoot.recordCount, 1)
        XCTAssertEqual(factValue("Gen IV Source Role", in: mapRoot), "platinumMapInventory")
        XCTAssertEqual(factValue("Gen IV Source Provenance", in: mapRoot), "platinum:res/field/maps")
        XCTAssertEqual(factValue("Gen IV Readiness", in: mapRoot), "inventoryOnly")
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: mapRoot)?.contains("semantic editing") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: mapRoot)?.contains("NARC/container work") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: mapRoot)?.contains("mutation apply") == true)
        XCTAssertTrue(factValue("Gen IV Action State", in: mapRoot)?.contains("inventory-only map metadata") == true)
        XCTAssertNil(factValue("Migration Status", in: mapRoot))
        XCTAssertTrue(mapRoot.diagnostics.contains { $0.code == "NDS_DATA_PLATINUM_MAP_INVENTORY_PREVIEW_ONLY" })
        XCTAssertTrue(mapRoot.diagnostics.contains { $0.code == "NDS_DATA_PLATINUM_MAP_WRITE_BLOCKED" })
        let routeMap = try XCTUnwrap(catalog.records.first { $0.relativePath == "res/field/maps/route201/map.bin" })
        XCTAssertEqual(factValue("Gen IV Source Role", in: routeMap), "platinumMapMember")
        XCTAssertEqual(factValue("Gen IV Source Provenance", in: routeMap), "platinum:res/field/maps")
        XCTAssertEqual(factValue("Gen IV Readiness", in: routeMap), "inventoryOnly")
        XCTAssertEqual(routeMap.readiness?.status, .ready)
        XCTAssertTrue(routeMap.relatedRecords.contains { $0.recordID == "maps:res/field/matrices/route201.json" && $0.label == "Matrix" })
        XCTAssertTrue(routeMap.relatedRecords.contains { $0.recordID == "maps:res/field/events/route201.json" && $0.label == "Map resource" })
        XCTAssertTrue(routeMap.relatedRecords.contains { $0.recordID == "scripts:res/field/scripts/route201.s" && $0.label == "Script resource" })
        XCTAssertTrue(routeMap.relatedRecords.contains { $0.recordID == "text:res/text/route201.txt" && $0.label == "Text bank" })
        XCTAssertTrue(routeMap.facts.contains { $0.label == "Related Rows" && $0.value == "4" })
        let routeMapPacket = try XCTUnwrap(routeMap.mapReviewPacket)
        XCTAssertEqual(routeMapPacket.posture, "reviewOnly")
        XCTAssertEqual(routeMapPacket.component, "map")
        XCTAssertEqual(routeMapPacket.sourceRole, "platinumMapMember")
        XCTAssertEqual(routeMapPacket.sourceProvenance, "platinum:res/field/maps")
        XCTAssertEqual(routeMapPacket.readiness?.status, .ready)
        XCTAssertEqual(routeMapPacket.includedRecords.count, 5)
        XCTAssertEqual(routeMapPacket.truncatedRelatedRecordCount, 0)
        XCTAssertTrue(routeMapPacket.includedRecords.contains { $0.recordID == "maps:res/field/matrices/route201.json" && $0.label == "Matrix" })
        XCTAssertTrue(routeMapPacket.includedRecords.contains { $0.recordID == "maps:res/field/events/route201.json" && $0.label == "Map resource" })
        XCTAssertTrue(routeMapPacket.includedRecords.contains { $0.recordID == "scripts:res/field/scripts/route201.s" && $0.label == "Script resource" })
        XCTAssertTrue(routeMapPacket.includedRecords.contains { $0.recordID == "text:res/text/route201.txt" && $0.label == "Text bank" })
        XCTAssertTrue(routeMapPacket.rows.contains { $0.id == "blocked-actions" && $0.detail?.contains("mutation apply") == true })
        XCTAssertEqual(factValue("Gen IV Map Review Packet", in: routeMap), "reviewOnly")
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: routeMap), "map")
        XCTAssertEqual(factValue("Gen IV Map Review Related Rows", in: routeMap), "4")
        XCTAssertTrue(routeMap.diagnostics.contains { $0.code == "NDS_DATA_PLATINUM_MAP_WRITE_BLOCKED" })
        XCTAssertTrue(routeMap.diagnostics.contains { $0.code == "NDS_DATA_READINESS_PREVIEW_ONLY" })
        let mapBinarySnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:res/field/maps/route201/map.bin")
        XCTAssertFalse(mapBinarySnapshot.canEdit)
        XCTAssertTrue(mapBinarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(mapBinarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
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
        let matrixRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/mapmatrix" })
        XCTAssertEqual(matrixRoot.domain, .maps)
        XCTAssertEqual(matrixRoot.format, .directory)
        XCTAssertEqual(matrixRoot.recordCount, 1)
        XCTAssertEqual(factValue("Gen IV Source Role", in: matrixRoot), "hgssMapMatrixInventory")
        XCTAssertEqual(factValue("Gen IV Source Provenance", in: matrixRoot), "heartGoldSoulSilver:files/fielddata/mapmatrix")
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: matrixRoot)?.contains("semantic editing") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: matrixRoot)?.contains("ROM export") == true)
        XCTAssertTrue(factValue("Gen IV Action State", in: matrixRoot)?.contains("inventory-only HGSS map metadata") == true)
        XCTAssertFalse(matrixRoot.facts.contains { $0.label == "Migration Status" })
        XCTAssertTrue(matrixRoot.diagnostics.contains { $0.code == "NDS_DATA_HGSS_MAP_INVENTORY_PREVIEW_ONLY" })
        XCTAssertTrue(matrixRoot.diagnostics.contains { $0.code == "NDS_DATA_HGSS_MAP_WRITE_BLOCKED" })
        XCTAssertEqual(matrixRoot.readiness?.status, .ready)
        XCTAssertEqual(factValue("Related Rows", in: matrixRoot), "2")
        XCTAssertEqual(factValue("Related Domains", in: matrixRoot), "maps")
        XCTAssertTrue(matrixRoot.relatedRecords.contains { $0.recordID == "maps:files/fielddata/maptable" && $0.label == "Map header" })
        XCTAssertTrue(matrixRoot.relatedRecords.contains { $0.recordID == "maps:src/data/map_headers.h" && $0.label == "Map header" })
        let matrixRootPacket = try XCTUnwrap(matrixRoot.mapReviewPacket)
        XCTAssertEqual(matrixRootPacket.posture, "reviewOnly")
        XCTAssertEqual(matrixRootPacket.component, "matrix")
        XCTAssertEqual(matrixRootPacket.sourceRole, "hgssMapMatrixInventory")
        XCTAssertEqual(matrixRootPacket.sourceProvenance, "heartGoldSoulSilver:files/fielddata/mapmatrix")
        XCTAssertEqual(matrixRootPacket.includedRecords.count, 3)
        XCTAssertEqual(matrixRootPacket.truncatedRelatedRecordCount, 0)
        XCTAssertTrue(matrixRootPacket.includedRecords.contains { $0.recordID == "maps:files/fielddata/maptable" })
        XCTAssertTrue(matrixRootPacket.includedRecords.contains { $0.recordID == "maps:src/data/map_headers.h" })
        XCTAssertTrue(matrixRootPacket.rows.contains { $0.id == "blocked-actions" && $0.detail?.contains("ROM export") == true })
        XCTAssertEqual(factValue("Gen IV Map Review Packet", in: matrixRoot), "reviewOnly")
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: matrixRoot), "matrix")
        XCTAssertEqual(factValue("Gen IV Map Review Related Rows", in: matrixRoot), "2")

        let tableRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/maptable" })
        XCTAssertEqual(tableRoot.domain, .maps)
        XCTAssertEqual(tableRoot.format, .directory)
        XCTAssertEqual(tableRoot.recordCount, 1)
        XCTAssertEqual(factValue("Gen IV Source Role", in: tableRoot), "hgssMapTableInventory")
        XCTAssertEqual(factValue("Gen IV Source Provenance", in: tableRoot), "heartGoldSoulSilver:files/fielddata/maptable")
        XCTAssertEqual(tableRoot.readiness?.status, .ready)
        XCTAssertNotNil(factValue("Related Rows", in: tableRoot))
        XCTAssertEqual(factValue("Related Domains", in: tableRoot), "maps")
        XCTAssertTrue(tableRoot.relatedRecords.contains { $0.recordID == "maps:files/fielddata/mapmatrix" && $0.label == "Matrix" })
        XCTAssertTrue(tableRoot.relatedRecords.contains { $0.recordID == "maps:src/data/map_headers.h" && $0.label == "Map header" })
        XCTAssertFalse(tableRoot.facts.contains { $0.label == "Migration Status" })
        let tableRootPacket = try XCTUnwrap(tableRoot.mapReviewPacket)
        XCTAssertEqual(tableRootPacket.component, "table")
        XCTAssertEqual(tableRootPacket.sourceRole, "hgssMapTableInventory")
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: tableRoot), "table")

        let mapHeader = try XCTUnwrap(catalog.records.first { $0.relativePath == "src/data/map_headers.h" && $0.domain == .maps && $0.format == .cHeader })
        XCTAssertEqual(factValue("Gen IV Source Role", in: mapHeader), "hgssMapHeaderInventory")
        XCTAssertEqual(factValue("Gen IV Source Provenance", in: mapHeader), "heartGoldSoulSilver:src/data/map_headers.h")
        XCTAssertEqual(factValue("Gen IV Readiness", in: mapHeader), "semanticIntegerScalars")
        XCTAssertEqual(mapHeader.readiness?.status, .ready)
        XCTAssertNotNil(factValue("Related Rows", in: mapHeader))
        XCTAssertEqual(factValue("Related Domains", in: mapHeader), "maps")
        XCTAssertTrue(mapHeader.relatedRecords.contains { $0.recordID == "maps:files/fielddata/mapmatrix" && $0.label == "Matrix" })
        XCTAssertTrue(mapHeader.relatedRecords.contains { $0.recordID == "maps:files/fielddata/maptable" && $0.label == "Map header" })
        XCTAssertTrue(factValue("Gen IV Action State", in: mapHeader)?.contains("integer-literal sMapHeaders scalars") == true)
        XCTAssertFalse(factValue("Gen IV Blocked Actions", in: mapHeader)?.contains("semantic editing") == true)
        XCTAssertFalse(factValue("Gen IV Blocked Actions", in: mapHeader)?.contains("raw C-anchor write") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: mapHeader)?.contains("non-integer C scalar write") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: mapHeader)?.contains("binary write") == true)
        XCTAssertTrue(mapHeader.diagnostics.contains { $0.code == "NDS_DATA_HGSS_MAP_HEADER_SEMANTIC_SCALARS" })
        XCTAssertTrue(mapHeader.diagnostics.contains { $0.code == "NDS_DATA_HGSS_MAP_HEADER_WRITE_LIMITED" })
        let mapHeaderPacket = try XCTUnwrap(mapHeader.mapReviewPacket)
        XCTAssertEqual(mapHeaderPacket.component, "mapHeader")
        XCTAssertEqual(mapHeaderPacket.sourceRole, "hgssMapHeaderInventory")
        XCTAssertTrue(mapHeaderPacket.blockedActions.contains("binary write"))
        XCTAssertFalse(mapHeaderPacket.blockedActions.contains("semantic editing"))
        XCTAssertFalse(mapHeaderPacket.blockedActions.contains("raw C-anchor write"))
        XCTAssertTrue(mapHeaderPacket.includedRecords.contains { $0.recordID == "maps:files/fielddata/mapmatrix" })
        XCTAssertTrue(mapHeaderPacket.includedRecords.contains { $0.recordID == "maps:files/fielddata/maptable" })
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: mapHeader), "mapHeader")
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "files/fielddata/eventdata/zone_event/zone_001.json" && $0.domain == .scripts })
        let scriptSequenceRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/script/scr_seq" })
        XCTAssertEqual(scriptSequenceRoot.domain, .scripts)
        XCTAssertEqual(scriptSequenceRoot.format, .directory)
        XCTAssertEqual(scriptSequenceRoot.recordCount, 1)
        XCTAssertEqual(factValue("Gen IV Source Role", in: scriptSequenceRoot), "hgssScriptSequenceInventory")
        XCTAssertEqual(factValue("Gen IV Source Provenance", in: scriptSequenceRoot), "heartGoldSoulSilver:files/fielddata/script/scr_seq")
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: scriptSequenceRoot)?.contains("script parsing") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: scriptSequenceRoot)?.contains("script binary write") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: scriptSequenceRoot)?.contains("ROM export") == true)
        XCTAssertTrue(factValue("Gen IV Action State", in: scriptSequenceRoot)?.contains("inventory-only HGSS script-sequence metadata") == true)
        XCTAssertEqual(scriptSequenceRoot.readiness?.status, .partial)
        XCTAssertTrue(scriptSequenceRoot.readiness?.blockedActions.contains("script compiler") == true)
        XCTAssertFalse(scriptSequenceRoot.facts.contains { $0.label == "Migration Status" })
        XCTAssertTrue(scriptSequenceRoot.diagnostics.contains { $0.code == "NDS_DATA_HGSS_SCRIPT_SEQUENCE_INVENTORY_PREVIEW_ONLY" })
        XCTAssertTrue(scriptSequenceRoot.diagnostics.contains { $0.code == "NDS_DATA_HGSS_SCRIPT_SEQUENCE_WRITE_BLOCKED" })
        let scriptSequenceMember = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/script/scr_seq/0001.bin" })
        XCTAssertEqual(factValue("Gen IV Source Role", in: scriptSequenceMember), "hgssScriptSequenceMember")
        XCTAssertEqual(factValue("Gen IV Source Provenance", in: scriptSequenceMember), "heartGoldSoulSilver:files/fielddata/script/scr_seq")
        XCTAssertTrue(factValue("Gen IV Action State", in: scriptSequenceMember)?.contains("mutation apply path is enabled") == true)
        XCTAssertTrue(scriptSequenceMember.diagnostics.contains { $0.code == "NDS_DATA_HGSS_SCRIPT_SEQUENCE_WRITE_BLOCKED" })
        let matrix = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/mapmatrix/0001.bin" })
        XCTAssertEqual(factValue("Gen IV Source Role", in: matrix), "hgssMapMatrixMember")
        XCTAssertEqual(factValue("Gen IV Source Provenance", in: matrix), "heartGoldSoulSilver:files/fielddata/mapmatrix")
        XCTAssertEqual(matrix.readiness?.status, .ready)
        XCTAssertTrue(matrix.relatedRecords.contains { $0.recordID == "scripts:files/fielddata/script/scr_seq/0001.bin" })
        XCTAssertTrue(matrix.relatedRecords.contains { $0.recordID == "text:files/msgdata/msg/0001.txt" })
        XCTAssertTrue(matrix.relatedRecords.contains { $0.recordID == "scripts:files/fielddata/eventdata/zone_event/zone_001.json" })
        let tableMember = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/maptable/map.bin" })
        XCTAssertEqual(factValue("Gen IV Source Role", in: tableMember), "hgssMapTableMember")
        XCTAssertEqual(factValue("Gen IV Source Provenance", in: tableMember), "heartGoldSoulSilver:files/fielddata/maptable")
        XCTAssertTrue(tableMember.diagnostics.contains { $0.code == "NDS_DATA_HGSS_MAP_INVENTORY_PREVIEW_ONLY" })
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
        XCTAssertEqual(scriptSource.readiness?.status, .blocked)
        XCTAssertEqual(scriptSource.readiness?.title, "Diamond/Pearl script C-anchor loader-only readiness")
        XCTAssertTrue(scriptSource.relatedRecords.contains { $0.recordID == "maps:arm9/src/map_header.c" && $0.label == "Map header" })
        XCTAssertTrue(scriptSource.relatedRecords.contains { $0.recordID == "text:arm9/src/msgdata.c" && $0.label == "Text bank" })
        XCTAssertEqual(factValue("Readiness", in: scriptSource), "blocked")
        XCTAssertTrue(factValue("Blocked Actions", in: scriptSource)?.contains("script parser") == true)
        XCTAssertEqual(factValue("Related Rows", in: scriptSource), "2")
        XCTAssertEqual(factValue("Related Domains", in: scriptSource), "maps, text")
        XCTAssertEqual(factValue("Gen IV Source Role", in: scriptSource), "dpScriptCAnchorLoaderOnly")
        XCTAssertEqual(factValue("Gen IV Source Provenance", in: scriptSource), "diamondPearl:arm9/src/script.c")
        XCTAssertEqual(factValue("Gen IV Readiness", in: scriptSource), "loaderOnlyBlocked")
        XCTAssertEqual(factValue("Gen IV C Anchor Shape", in: scriptSource), "loaderTaskFlow")
        XCTAssertNil(factValue("Gen IV Future Row", in: scriptSource))
        let scriptBlockedActions = try XCTUnwrap(factValue("Gen IV Blocked Actions", in: scriptSource))
        for action in [
            "semantic editing",
            "script parser",
            "script C-anchor writer",
            "raw scalar writer",
            "script compiler",
            "row insert/remove/reorder",
            "NARC/container work",
            "generated output write",
            "reference write",
            "ROM rebuild",
            "ROM export",
            "mutation apply",
            "binary write"
        ] {
            XCTAssertTrue(scriptBlockedActions.contains(action), action)
            XCTAssertTrue(scriptSource.readiness?.blockedActions.contains(action) == true, action)
        }
        XCTAssertTrue(factValue("Gen IV Action State", in: scriptSource)?.contains("loader/task source") == true)
        XCTAssertTrue(factValue("Gen IV Action State", in: scriptSource)?.contains("exact scalar table") == true)
        XCTAssertTrue(factValue("Gen IV Action State", in: scriptSource)?.contains("script parser") == true)
        XCTAssertTrue(scriptSource.diagnostics.contains { $0.code == "NDS_DATA_DP_SCRIPT_C_ANCHOR_LOADER_ONLY" })
        let scriptSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "scripts:arm9/src/script.c")
        XCTAssertFalse(scriptSnapshot.canEdit)
        XCTAssertTrue(scriptSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(scriptSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_SCRIPT_PATH_BLOCKED" })
        let mapHeader = try XCTUnwrap(catalog.records.first { $0.relativePath == "arm9/src/map_header.c" && $0.domain == .maps })
        XCTAssertEqual(factValue("Gen IV Source Role", in: mapHeader), "dpMapHeaderCAnchor")
        XCTAssertEqual(factValue("Gen IV Source Provenance", in: mapHeader), "diamondPearl:arm9/src/map_header.c")
        XCTAssertEqual(factValue("Gen IV Readiness", in: mapHeader), "semanticIntegerScalars")
        XCTAssertFalse(factValue("Gen IV Blocked Actions", in: mapHeader)?.contains("raw C-anchor write") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: mapHeader)?.contains("non-integer C scalar write") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: mapHeader)?.contains("map matrix write") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: mapHeader)?.contains("binary write") == true)
        XCTAssertTrue(factValue("Gen IV Action State", in: mapHeader)?.contains("semantic mutation-plan gate") == true)
        XCTAssertTrue(mapHeader.diagnostics.contains { $0.code == "NDS_DATA_DP_MAP_HEADER_SEMANTIC_SCALARS" })
        XCTAssertTrue(mapHeader.diagnostics.contains { $0.code == "NDS_DATA_DP_MAP_HEADER_WRITE_LIMITED" })
        let mapHeaderPacket = try XCTUnwrap(mapHeader.mapReviewPacket)
        XCTAssertEqual(mapHeaderPacket.posture, "reviewOnly")
        XCTAssertEqual(mapHeaderPacket.component, "mapHeader")
        XCTAssertEqual(mapHeaderPacket.sourceRole, "dpMapHeaderCAnchor")
        XCTAssertEqual(mapHeaderPacket.sourceProvenance, "diamondPearl:arm9/src/map_header.c")
        XCTAssertTrue(mapHeaderPacket.blockedActions.contains("non-integer C scalar write"))
        XCTAssertFalse(mapHeaderPacket.blockedActions.contains("raw C-anchor write"))
        XCTAssertEqual(factValue("Gen IV Map Review Packet", in: mapHeader), "reviewOnly")
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: mapHeader), "mapHeader")

        let moveCAnchor = try XCTUnwrap(catalog.records.first { $0.relativePath == "arm9/src/waza.c" && $0.domain == .moves })
        XCTAssertEqual(moveCAnchor.format, .cSource)
        XCTAssertEqual(factValue("Gen IV Source Role", in: moveCAnchor), "dpMoveCAnchorSemanticScalars")
        XCTAssertEqual(factValue("Gen IV Source Provenance", in: moveCAnchor), "diamondPearl:arm9/src/waza.c")
        XCTAssertEqual(factValue("Gen IV Readiness", in: moveCAnchor), "semanticSimpleScalars")
        XCTAssertNil(factValue("Gen IV Future Row", in: moveCAnchor))
        XCTAssertFalse(factValue("Gen IV Blocked Actions", in: moveCAnchor)?.contains("semantic editing") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: moveCAnchor)?.contains("non-simple move C scalar write") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: moveCAnchor)?.contains("row insert/remove/reorder") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: moveCAnchor)?.contains("encounter C-anchor writer") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: moveCAnchor)?.contains("NARC/container work") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: moveCAnchor)?.contains("ROM export") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: moveCAnchor)?.contains("binary write") == true)
        XCTAssertTrue(factValue("Gen IV Action State", in: moveCAnchor)?.contains("semantic mutation-plan gate") == true)
        XCTAssertEqual(moveCAnchor.readiness?.status, .partial)
        XCTAssertTrue(moveCAnchor.readiness?.blockedActions.contains("non-simple move C scalar write") == true)
        XCTAssertTrue(moveCAnchor.diagnostics.contains { $0.code == "NDS_DATA_DP_MOVE_C_ANCHOR_SEMANTIC_SCALARS" })
        XCTAssertTrue(moveCAnchor.diagnostics.contains { $0.code == "NDS_DATA_DP_MOVE_C_ANCHOR_WRITE_LIMITED" })
        let moveSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "moves:arm9/src/waza.c")
        XCTAssertTrue(moveSnapshot.canEdit, moveSnapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertFalse(moveSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertFalse(moveSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MOVE_PATH_BLOCKED" })
        XCTAssertFalse(moveSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let encounterCAnchor = try XCTUnwrap(catalog.records.first { $0.relativePath == "arm9/src/encounter.c" && $0.domain == .encounters })
        XCTAssertEqual(encounterCAnchor.format, .cSource)
        XCTAssertEqual(factValue("Gen IV Source Role", in: encounterCAnchor), "dpEncounterCAnchorLoaderOnly")
        XCTAssertEqual(factValue("Gen IV Source Provenance", in: encounterCAnchor), "diamondPearl:arm9/src/encounter.c")
        XCTAssertEqual(factValue("Gen IV Readiness", in: encounterCAnchor), "loaderOnlyBlocked")
        XCTAssertEqual(factValue("Gen IV C Anchor Shape", in: encounterCAnchor), "loaderTaskFlow")
        XCTAssertNil(factValue("Gen IV Future Row", in: encounterCAnchor))
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: encounterCAnchor)?.contains("semantic editing") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: encounterCAnchor)?.contains("encounter C-anchor writer") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: encounterCAnchor)?.contains("raw scalar writer") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: encounterCAnchor)?.contains("row insert/remove/reorder") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: encounterCAnchor)?.contains("NARC/container work") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: encounterCAnchor)?.contains("ROM rebuild") == true)
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: encounterCAnchor)?.contains("binary write") == true)
        XCTAssertTrue(factValue("Gen IV Action State", in: encounterCAnchor)?.contains("loader/task source") == true)
        XCTAssertTrue(factValue("Gen IV Action State", in: encounterCAnchor)?.contains("exact scalar table") == true)
        XCTAssertEqual(encounterCAnchor.readiness?.status, .blocked)
        XCTAssertTrue(encounterCAnchor.readiness?.blockedActions.contains("encounter C-anchor writer") == true)
        XCTAssertTrue(encounterCAnchor.readiness?.blockedActions.contains("raw scalar writer") == true)
        XCTAssertTrue(encounterCAnchor.diagnostics.contains { $0.code == "NDS_DATA_DP_ENCOUNTER_C_ANCHOR_LOADER_ONLY" })
        let encounterSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "encounters:arm9/src/encounter.c")
        XCTAssertFalse(encounterSnapshot.canEdit)
        XCTAssertTrue(encounterSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(encounterSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_ENCOUNTER_PATH_BLOCKED" })
        XCTAssertTrue(encounterSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let matrixRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/mapmatrix" })
        XCTAssertEqual(matrixRoot.domain, .maps)
        XCTAssertEqual(matrixRoot.format, .directory)
        XCTAssertEqual(matrixRoot.recordCount, 1)
        XCTAssertEqual(factValue("Gen IV Source Role", in: matrixRoot), "dpMapMatrixInventory")
        XCTAssertEqual(factValue("Gen IV Source Provenance", in: matrixRoot), "diamondPearl:files/fielddata/mapmatrix")
        XCTAssertEqual(factValue("Gen IV Readiness", in: matrixRoot), "inventoryOnly")
        XCTAssertNil(factValue("Migration Status", in: matrixRoot))
        let matrixRootPacket = try XCTUnwrap(matrixRoot.mapReviewPacket)
        XCTAssertEqual(matrixRootPacket.component, "matrix")
        XCTAssertEqual(matrixRootPacket.sourceRole, "dpMapMatrixInventory")
        XCTAssertTrue(matrixRootPacket.blockedActions.contains("raw C-anchor write"))
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: matrixRoot), "matrix")

        let matrixMember = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/mapmatrix/matrix.bin" && $0.domain == .maps && $0.format == .binary })
        XCTAssertEqual(factValue("Gen IV Source Role", in: matrixMember), "dpMapMatrixMember")
        XCTAssertEqual(factValue("Gen IV Source Provenance", in: matrixMember), "diamondPearl:files/fielddata/mapmatrix")

        let tableRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/maptable" })
        XCTAssertEqual(factValue("Gen IV Source Role", in: tableRoot), "dpMapTableInventory")
        XCTAssertEqual(factValue("Gen IV Source Provenance", in: tableRoot), "diamondPearl:files/fielddata/maptable")
        XCTAssertEqual(factValue("Gen IV Readiness", in: tableRoot), "inventoryOnly")
        XCTAssertNil(factValue("Migration Status", in: tableRoot))
        let tableRootPacket = try XCTUnwrap(tableRoot.mapReviewPacket)
        XCTAssertEqual(tableRootPacket.component, "table")
        XCTAssertEqual(tableRootPacket.sourceRole, "dpMapTableInventory")
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: tableRoot), "table")
        let tableMember = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/maptable/map.bin" })
        XCTAssertEqual(factValue("Gen IV Source Role", in: tableMember), "dpMapTableMember")

        let landRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/land_data" })
        XCTAssertEqual(factValue("Gen IV Source Role", in: landRoot), "dpLandDataInventory")
        XCTAssertEqual(factValue("Gen IV Source Provenance", in: landRoot), "diamondPearl:files/fielddata/land_data")
        XCTAssertNil(factValue("Migration Status", in: landRoot))
        let landRootPacket = try XCTUnwrap(landRoot.mapReviewPacket)
        XCTAssertEqual(landRootPacket.component, "land")
        XCTAssertEqual(landRootPacket.sourceRole, "dpLandDataInventory")
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: landRoot), "land")
        let landMember = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/land_data/land_0001.bin" })
        XCTAssertEqual(factValue("Gen IV Source Role", in: landMember), "dpLandDataMember")

        let areaRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/areadata" })
        XCTAssertEqual(factValue("Gen IV Source Role", in: areaRoot), "dpAreaDataInventory")
        XCTAssertEqual(factValue("Gen IV Source Provenance", in: areaRoot), "diamondPearl:files/fielddata/areadata")
        XCTAssertNil(factValue("Migration Status", in: areaRoot))
        let areaRootPacket = try XCTUnwrap(areaRoot.mapReviewPacket)
        XCTAssertEqual(areaRootPacket.component, "area")
        XCTAssertEqual(areaRootPacket.sourceRole, "dpAreaDataInventory")
        XCTAssertEqual(factValue("Gen IV Map Review Component", in: areaRoot), "area")
        let areaMember = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/areadata/area_0001.bin" })
        XCTAssertEqual(factValue("Gen IV Source Role", in: areaMember), "dpAreaDataMember")

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
        let resourceIndex = GenIIIResourceRegistry.resourceIndex(path: root.path)
        let moveResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data moves" && $0.path == "arm9/src/waza.c" })
        XCTAssertTrue(moveResourceItem.facts.contains { $0.label == "Gen IV Source Role" && $0.value == "dpMoveCAnchorSemanticScalars" })
        XCTAssertFalse(moveResourceItem.facts.contains { $0.label == "Gen IV Future Row" && $0.value == "PHS-T98" })
        XCTAssertTrue(moveResourceItem.facts.contains { $0.label == "Gen IV Blocked Actions" && $0.value.contains("non-simple move C scalar write") })
        let scriptResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data scripts" && $0.path == "arm9/src/script.c" })
        XCTAssertTrue(scriptResourceItem.facts.contains { $0.label == "Gen IV Source Role" && $0.value == "dpScriptCAnchorLoaderOnly" })
        XCTAssertTrue(scriptResourceItem.facts.contains { $0.label == "Gen IV Readiness" && $0.value == "loaderOnlyBlocked" })
        XCTAssertTrue(scriptResourceItem.facts.contains { $0.label == "Gen IV C Anchor Shape" && $0.value == "loaderTaskFlow" })
        XCTAssertTrue(scriptResourceItem.facts.contains { $0.label == "Readiness" && $0.value == "blocked" })
        XCTAssertTrue(scriptResourceItem.facts.contains { $0.label == "Related Rows" && $0.value == "2" })
        XCTAssertTrue(scriptResourceItem.facts.contains { $0.label == "Related Domains" && $0.value == "maps, text" })
        XCTAssertFalse(scriptResourceItem.facts.contains { $0.label == "Gen IV Future Row" })
        XCTAssertTrue(scriptResourceItem.facts.contains { $0.label == "Gen IV Blocked Actions" && $0.value.contains("script parser") })
        XCTAssertTrue(scriptResourceItem.facts.contains { $0.label == "Gen IV Blocked Actions" && $0.value.contains("mutation apply") })
        let encounterResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data encounters" && $0.path == "arm9/src/encounter.c" })
        XCTAssertTrue(encounterResourceItem.facts.contains { $0.label == "Gen IV Source Role" && $0.value == "dpEncounterCAnchorLoaderOnly" })
        XCTAssertTrue(encounterResourceItem.facts.contains { $0.label == "Gen IV Readiness" && $0.value == "loaderOnlyBlocked" })
        XCTAssertTrue(encounterResourceItem.facts.contains { $0.label == "Gen IV C Anchor Shape" && $0.value == "loaderTaskFlow" })
        XCTAssertFalse(encounterResourceItem.facts.contains { $0.label == "Gen IV Future Row" })
        XCTAssertTrue(encounterResourceItem.facts.contains { $0.label == "Gen IV Blocked Actions" && $0.value.contains("encounter C-anchor writer") })

        let assetCatalog = GenIIIAssetCatalogBuilder.build(path: root.path)
        let moveAsset = try XCTUnwrap(assetCatalog.assets.first { $0.relativePath == "arm9/src/waza.c" && $0.category == .moves })
        XCTAssertTrue(moveAsset.facts.contains { $0.label == "Gen IV Source Role" && $0.value == "dpMoveCAnchorSemanticScalars" })
        XCTAssertFalse(moveAsset.facts.contains { $0.label == "Gen IV Future Row" && $0.value == "PHS-T98" })
        let scriptAsset = try XCTUnwrap(assetCatalog.assets.first { $0.relativePath == "arm9/src/script.c" && $0.category == .scripts })
        XCTAssertTrue(scriptAsset.facts.contains { $0.label == "Gen IV Source Role" && $0.value == "dpScriptCAnchorLoaderOnly" })
        XCTAssertTrue(scriptAsset.facts.contains { $0.label == "Gen IV Readiness" && $0.value == "loaderOnlyBlocked" })
        XCTAssertTrue(scriptAsset.facts.contains { $0.label == "Gen IV C Anchor Shape" && $0.value == "loaderTaskFlow" })
        XCTAssertTrue(scriptAsset.facts.contains { $0.label == "Readiness" && $0.value == "blocked" })
        XCTAssertTrue(scriptAsset.facts.contains { $0.label == "Related Rows" && $0.value == "2" })
        XCTAssertFalse(scriptAsset.facts.contains { $0.label == "Gen IV Future Row" })
        let encounterAsset = try XCTUnwrap(assetCatalog.assets.first { $0.relativePath == "arm9/src/encounter.c" && $0.category == .encounters })
        XCTAssertTrue(encounterAsset.facts.contains { $0.label == "Gen IV Source Role" && $0.value == "dpEncounterCAnchorLoaderOnly" })
        XCTAssertTrue(encounterAsset.facts.contains { $0.label == "Gen IV Readiness" && $0.value == "loaderOnlyBlocked" })
        XCTAssertTrue(encounterAsset.facts.contains { $0.label == "Gen IV C Anchor Shape" && $0.value == "loaderTaskFlow" })
        XCTAssertFalse(encounterAsset.facts.contains { $0.label == "Gen IV Future Row" })
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

    func testPokeBlackCatalogSurfacesGenVReadinessFacts() throws {
        let root = try makeRoot(name: "pokeblack", configure: makeBlackFixture)

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        XCTAssertEqual(catalog.profile, .pokeblack)
        XCTAssertEqual(catalog.family, .blackWhite)
        XCTAssertTrue(catalog.isReadOnly)

        let makefile = try XCTUnwrap(catalog.records.first { $0.relativePath == "Makefile" })
        XCTAssertEqual(makefile.format, .text)
        XCTAssertEqual(factValue("Gen V Source Role", in: makefile), "buildConfig")
        XCTAssertEqual(factValue("Gen V Build Metadata", in: makefile), "previewOnly")
        XCTAssertEqual(factValue("Gen V Makefile Presence", in: makefile), "present")
        XCTAssertEqual(factValue("Gen V Config Presence", in: makefile), "present")
        XCTAssertEqual(factValue("Gen V Linker Presence", in: makefile), "arm9.ld=present, arm7.ld=present")
        XCTAssertEqual(
            factValue("Gen V Variant Hash Presence", in: makefile),
            "black.us/rom.sha1=present, white.us/rom.sha1=missing, black2.us/rom.sha1=missing, white2.us/rom.sha1=missing"
        )
        XCTAssertEqual(factValue("Gen V main.rsf Presence", in: makefile), "present")
        XCTAssertEqual(factValue("Gen V main.lsf Presence", in: makefile), "present")
        XCTAssertEqual(makefile.readiness?.status, .partial)
        XCTAssertTrue(makefile.readiness?.detail.contains("manual setup") == true)

        let sourceRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "src" })
        XCTAssertEqual(sourceRoot.format, .directory)
        XCTAssertEqual(sourceRoot.recordCount, 5)
        XCTAssertEqual(sourceRoot.byteCount, UInt64(92))
        XCTAssertEqual(factValue("Gen V Source Role", in: sourceRoot), "sourceCodeInventory")
        XCTAssertEqual(factValue("Gen V Source Root Members", in: sourceRoot), "5")
        XCTAssertEqual(factValue("Gen V Source Root Bytes", in: sourceRoot), "92")
        XCTAssertTrue(factValue("Gen V Source Root Sample Paths", in: sourceRoot)?.contains("src/init.c") == true)
        XCTAssertTrue(factValue("Gen V Source Root Sample Paths", in: sourceRoot)?.contains("src/data/pokemon/source_pokemon.inc") == true)
        XCTAssertTrue(sourceRoot.preview?.contains("src/init.c") == true)
        XCTAssertNil(sourceRoot.textBankPreview)
        XCTAssertNil(sourceRoot.migrationPlan)
        XCTAssertNil(factValue("Migration Status", in: sourceRoot))
        XCTAssertTrue(factValue("Gen V Action State", in: sourceRoot)?.contains("source inventory stays preview-only") == true)

        let assemblyRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "asm" })
        XCTAssertEqual(assemblyRoot.format, .directory)
        XCTAssertEqual(assemblyRoot.recordCount, 1)
        XCTAssertEqual(assemblyRoot.byteCount, UInt64(5))
        XCTAssertEqual(factValue("Gen V Source Role", in: assemblyRoot), "assemblyInventory")
        XCTAssertEqual(factValue("Gen V Assembly Root Members", in: assemblyRoot), "1")
        XCTAssertEqual(factValue("Gen V Assembly Root Bytes", in: assemblyRoot), "5")
        XCTAssertEqual(factValue("Gen V Assembly Root Sample Paths", in: assemblyRoot), "asm/arm9_remaining.s")
        XCTAssertTrue(factValue("Gen V Blocked Actions", in: assemblyRoot)?.contains("mutation apply") == true)
        XCTAssertNil(assemblyRoot.textBankPreview)
        XCTAssertNil(assemblyRoot.migrationPlan)
        XCTAssertNil(factValue("Migration Status", in: assemblyRoot))

        let headerRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "include" })
        XCTAssertEqual(headerRoot.format, .directory)
        XCTAssertEqual(headerRoot.recordCount, 1)
        XCTAssertEqual(headerRoot.byteCount, UInt64(16))
        XCTAssertEqual(factValue("Gen V Source Role", in: headerRoot), "headerInventory")
        XCTAssertEqual(factValue("Gen V Header Root Members", in: headerRoot), "1")
        XCTAssertEqual(factValue("Gen V Header Root Bytes", in: headerRoot), "16")
        XCTAssertEqual(factValue("Gen V Header Root Sample Paths", in: headerRoot), "include/globals.h")
        XCTAssertNil(headerRoot.textBankPreview)
        XCTAssertNil(headerRoot.migrationPlan)
        XCTAssertNil(factValue("Migration Status", in: headerRoot))

        let linkerConfig = try XCTUnwrap(catalog.records.first { $0.relativePath == "arm9.ld" })
        XCTAssertEqual(linkerConfig.format, .text)
        XCTAssertEqual(factValue("Gen V Source Role", in: linkerConfig), "linkerConfig")

        let blackMarker = try XCTUnwrap(catalog.records.first { $0.relativePath == "black.us" })
        XCTAssertEqual(blackMarker.format, .directory)
        XCTAssertEqual(blackMarker.recordCount, 1)
        XCTAssertEqual(factValue("Gen V Source Role", in: blackMarker), "variantSourceInventory")
        XCTAssertEqual(factValue("Gen V Variant ID", in: blackMarker), "black.us")
        XCTAssertEqual(factValue("Gen V Source Marker", in: blackMarker), "black.us")
        XCTAssertNil(factValue("Migration Status", in: blackMarker))

        let encounter = try XCTUnwrap(catalog.records.first { $0.relativePath == "data/encounters/route_1.txt" })
        XCTAssertEqual(factValue("Gen V Readiness", in: encounter), "previewOnly")
        XCTAssertEqual(factValue("Gen V Source Role", in: encounter), "encounterPreview")
        XCTAssertEqual(factValue("Gen V Encounter Record", in: encounter), "previewOnly")
        XCTAssertEqual(factValue("Gen V Encounter Source", in: encounter), "data/encounters")
        XCTAssertEqual(factValue("Gen V Encounter Key", in: encounter), "route_1")
        XCTAssertEqual(factValue("Gen V Encounter Format", in: encounter), "text")
        XCTAssertEqual(factValue("Gen V Encounter Parse State", in: encounter), "metadataOnly")
        XCTAssertEqual(factValue("Gen V Encounter Shallow Count", in: encounter), "1")
        XCTAssertEqual(factValue("Gen V Encounter Bytes", in: encounter), "8")
        XCTAssertEqual(factValue("Gen V Reference Posture", in: encounter), "cleanRoomReferenceOnly")
        XCTAssertTrue(factValue("Gen V Blocked Actions", in: encounter)?.contains("raw source writer") == true)
        XCTAssertTrue(factValue("Gen V Action State", in: encounter)?.contains("build, playtest, and export actions are disabled") == true)
        XCTAssertEqual(encounter.readiness?.status, .partial)
        XCTAssertTrue(encounter.readiness?.blockedActions.contains("build execution") == true)
        XCTAssertTrue(encounter.readiness?.detail.contains("source inventory stays preview-only") == true)
        XCTAssertTrue(encounter.diagnostics.contains { $0.code == "NDS_GEN_V_READINESS_PREVIEW_ONLY" })
        XCTAssertTrue(encounter.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })

        let dataRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "data" })
        XCTAssertEqual(dataRoot.domain, .resources)
        XCTAssertEqual(dataRoot.format, .directory)
        XCTAssertEqual(dataRoot.recordCount, 5)
        XCTAssertEqual(factValue("Gen V Source Role", in: dataRoot), "dataInventory")
        XCTAssertEqual(factValue("Gen V Readiness", in: dataRoot), "previewOnly")
        XCTAssertEqual(factValue("Gen V Reference Posture", in: dataRoot), "cleanRoomReferenceOnly")
        XCTAssertTrue(factValue("Gen V Action State", in: dataRoot)?.contains("source inventory stays preview-only") == true)
        XCTAssertEqual(dataRoot.readiness?.status, .partial)
        XCTAssertTrue(dataRoot.readiness?.detail.contains("data root") == true)
        XCTAssertNil(factValue("Migration Status", in: dataRoot))
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "data/encounters/route_1.txt" })

        let archiveGroup = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/a/0/0/0/resource.bin" })
        XCTAssertEqual(factValue("Gen V Source Role", in: archiveGroup), "nitroArchiveGroup")
        XCTAssertEqual(archiveGroup.readiness?.status, .partial)

        let overlay = try XCTUnwrap(catalog.records.first { $0.relativePath == "overlays/overlay_93/source.s" })
        XCTAssertEqual(factValue("Gen V Source Role", in: overlay), "overlayRouting")
        XCTAssertTrue(factValue("Gen V Blocked Actions", in: overlay)?.contains("playtest launch") == true)

        let config = try XCTUnwrap(catalog.records.first { $0.relativePath == "ndsdisasm_config/ARM9.cfg" })
        XCTAssertEqual(factValue("Gen V Source Role", in: config), "disassemblyConfig")

        let filesystemManifest = try XCTUnwrap(catalog.records.first { $0.relativePath == "main.rsf" })
        XCTAssertEqual(factValue("Gen V Source Role", in: filesystemManifest), "filesystemManifest")
        XCTAssertEqual(filesystemManifest.readiness?.status, .partial)

        let linkerScript = try XCTUnwrap(catalog.records.first { $0.relativePath == "main.lsf" })
        XCTAssertEqual(factValue("Gen V Source Role", in: linkerScript), "linkerScript")

        let checksum = try XCTUnwrap(catalog.records.first { $0.relativePath == "black.us/rom.sha1" })
        XCTAssertEqual(factValue("Gen V Source Role", in: checksum), "checksumExpectation")
        XCTAssertEqual(factValue("Gen V Variant ID", in: checksum), "black.us")
        XCTAssertEqual(factValue("Gen V Title", in: checksum), "Pokemon - Black Version (USA, Europe) (NDSi Enhanced).nds")
        XCTAssertEqual(factValue("Gen V Source Marker", in: checksum), "black.us/rom.sha1")
        XCTAssertEqual(factValue("Gen V Variant State", in: checksum), "sourceMarkerPresent")
        XCTAssertEqual(factValue("Gen V SHA1 Text State", in: checksum), "valid")
        XCTAssertEqual(factValue("Gen V SHA1 Text Digest", in: checksum), "ffffffffffffffffffffffffffffffffffffffff")

        let audio = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/wb_sound_data.sdat" && $0.domain == .audio })
        XCTAssertEqual(factValue("Audio Preview", in: audio), "ready")
        XCTAssertEqual(factValue("Gen V Source Role", in: audio), "soundArchiveMetadata")

        let narc = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/soundstatus.narc" && $0.domain == .audio })
        XCTAssertEqual(factValue("Gen V Source Role", in: narc), "soundContainerRoute")
        XCTAssertEqual(narc.readiness?.status, .blocked)

        let unavailableRows = catalog.records.filter { $0.role == .metadataUnavailable }
        XCTAssertEqual(unavailableRows.count, 3)
        let whiteReason = "No materialized White source decomp is available in the current central corpus; the available pokeblack tree currently supports black.us only."
        let black2Reason = "No public/materialized Black 2 decomp source root was found in the configured central corpus."
        let white2Reason = "No public/materialized White 2 decomp source root was found in the configured central corpus."
        let whiteTitle = "Pokemon - White Version (USA, Europe) (NDSi Enhanced).nds"
        let white = try XCTUnwrap(catalog.records.first { $0.relativePath == "unavailable-titles/\(whiteTitle)" })
        XCTAssertEqual(white.domain, .resources)
        XCTAssertEqual(white.title, whiteTitle)
        XCTAssertEqual(white.format, .unknown)
        XCTAssertEqual(white.role, .metadataUnavailable)
        XCTAssertFalse(white.exists)
        XCTAssertNil(white.byteCount)
        XCTAssertNil(white.preview)
        XCTAssertEqual(white.readiness?.status, .blocked)
        XCTAssertEqual(factValue("Gen V Title", in: white), whiteTitle)
        XCTAssertEqual(factValue("Gen V Variant ID", in: white), "white.us")
        XCTAssertEqual(factValue("Gen V Family", in: white), "blackWhite")
        XCTAssertEqual(factValue("Gen V Source Name", in: white), "pokeblack")
        XCTAssertEqual(factValue("Gen V Source Marker", in: white), "white.us, white.us/rom.sha1")
        XCTAssertEqual(factValue("Gen V Variant State", in: white), "unavailable")
        XCTAssertEqual(factValue("Gen V Unavailable Reason", in: white), whiteReason)
        XCTAssertEqual(factValue("Gen V Readiness", in: white), "unavailable")
        XCTAssertEqual(factValue("Gen V Source Role", in: white), "titleUnavailable")
        XCTAssertTrue(factValue("Gen V Action State", in: white)?.contains("editing/apply") == true)
        XCTAssertEqual(factValue("Gen V Reference Posture", in: white), "cleanRoomReferenceOnly")
        XCTAssertTrue(white.readiness?.blockedActions.contains("binary write") == true)
        XCTAssertTrue(white.readiness?.detail.contains("source inventory stays preview-only") == true)
        XCTAssertTrue(white.diagnostics.contains { $0.code == "NDS_GEN_V_TITLE_UNAVAILABLE" })
        XCTAssertTrue(white.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })

        let black2 = try XCTUnwrap(catalog.records.first { $0.relativePath == "unavailable-titles/Pokemon - Black Version 2 (USA, Europe) (NDSi Enhanced).nds" })
        XCTAssertEqual(factValue("Gen V Family", in: black2), "black2White2")
        XCTAssertEqual(factValue("Gen V Source Name", in: black2), "none")
        XCTAssertEqual(factValue("Gen V Unavailable Reason", in: black2), black2Reason)
        XCTAssertEqual(black2.readiness?.status, .blocked)
        XCTAssertTrue(black2.diagnostics.contains { $0.code == "NDS_GEN_V_TITLE_UNAVAILABLE" })

        let white2 = try XCTUnwrap(catalog.records.first { $0.relativePath == "unavailable-titles/Pokemon - White Version 2 (USA, Europe) (NDSi Enhanced).nds" })
        XCTAssertEqual(factValue("Gen V Family", in: white2), "black2White2")
        XCTAssertEqual(factValue("Gen V Source Name", in: white2), "none")
        XCTAssertEqual(factValue("Gen V Unavailable Reason", in: white2), white2Reason)
        XCTAssertEqual(white2.readiness?.status, .blocked)
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "NDS_GEN_V_TITLE_UNAVAILABLE" })

        let resourceIndex = GenIIIResourceRegistry.resourceIndex(path: root.path)
        let makefileResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "Makefile" })
        XCTAssertTrue(makefileResourceItem.facts.contains { $0.label == "Gen V Build Metadata" && $0.value == "previewOnly" })
        XCTAssertTrue(makefileResourceItem.facts.contains { $0.label == "Gen V Variant Hash Presence" && $0.value.contains("black2.us/rom.sha1=missing") })
        XCTAssertTrue(makefileResourceItem.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        let sourceRootResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "src" })
        XCTAssertEqual(sourceRootResourceItem.kind, "directory")
        XCTAssertEqual(sourceRootResourceItem.size, UInt64(92))
        XCTAssertTrue(sourceRootResourceItem.facts.contains { $0.label == "Gen V Source Role" && $0.value == "sourceCodeInventory" })
        XCTAssertTrue(sourceRootResourceItem.facts.contains { $0.label == "Gen V Source Root Members" && $0.value == "5" })
        XCTAssertTrue(sourceRootResourceItem.facts.contains { $0.label == "Gen V Source Root Bytes" && $0.value == "92" })
        XCTAssertTrue(sourceRootResourceItem.facts.contains { $0.label == "Gen V Source Root Sample Paths" && $0.value.contains("src/data/pokemon/source_pokemon.inc") })
        XCTAssertFalse(sourceRootResourceItem.facts.contains { $0.label == "Migration Status" })
        let assemblyRootResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "asm" })
        XCTAssertEqual(assemblyRootResourceItem.size, UInt64(5))
        XCTAssertTrue(assemblyRootResourceItem.facts.contains { $0.label == "Gen V Assembly Root Sample Paths" && $0.value == "asm/arm9_remaining.s" })
        let headerRootResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "include" })
        XCTAssertEqual(headerRootResourceItem.size, UInt64(16))
        XCTAssertTrue(headerRootResourceItem.facts.contains { $0.label == "Gen V Header Root Sample Paths" && $0.value == "include/globals.h" })
        let dataRootResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "data" })
        XCTAssertEqual(dataRootResourceItem.kind, "directory")
        XCTAssertTrue(dataRootResourceItem.facts.contains { $0.label == "Gen V Source Role" && $0.value == "dataInventory" })
        XCTAssertTrue(dataRootResourceItem.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertTrue(dataRootResourceItem.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        XCTAssertFalse(dataRootResourceItem.facts.contains { $0.label == "Migration Status" })
        let encounterResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.path == "data/encounters/route_1.txt" })
        XCTAssertTrue(encounterResourceItem.facts.contains { $0.label == "Gen V Encounter Record" && $0.value == "previewOnly" })
        XCTAssertTrue(encounterResourceItem.facts.contains { $0.label == "Gen V Encounter Key" && $0.value == "route_1" })

        let whiteResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == white.relativePath })
        XCTAssertEqual(whiteResourceItem.kind, "unknown")
        XCTAssertTrue(whiteResourceItem.facts.contains { $0.label == "Gen V Readiness" && $0.value == "unavailable" })
        XCTAssertTrue(whiteResourceItem.facts.contains { $0.label == "Gen V Source Role" && $0.value == "titleUnavailable" })
        XCTAssertTrue(whiteResourceItem.facts.contains { $0.label == "Gen V Unavailable Reason" && $0.value == whiteReason })
        XCTAssertTrue(whiteResourceItem.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("build, playtest, and export actions are disabled") })

        let assetCatalog = GenIIIAssetCatalogBuilder.build(path: root.path)
        let whiteRelativePath = white.relativePath
        let whiteAssetCandidates = assetCatalog.assets.filter { $0.relativePath == whiteRelativePath }
        let whiteAsset = try XCTUnwrap(whiteAssetCandidates.first { $0.category == GenIIIAssetCategory.source })
        XCTAssertTrue(whiteAsset.facts.contains { $0.label == "Gen V Readiness" && $0.value == "unavailable" })
        XCTAssertTrue(whiteAsset.facts.contains { $0.label == "Gen V Source Role" && $0.value == "titleUnavailable" })
        XCTAssertTrue(whiteAsset.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })

        let plan = NDSDataMutationPlanner.plan(
            catalog: catalog,
            draft: NDSDataEditDraft(recordID: encounter.id, editedText: "route 1 changed\n")
        )
        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })
    }

    func testPokeBlackCatalogSurfacesGenVSourceDataDomainInventoryFacts() throws {
        let root = try makeRoot(name: "pokeblack", configure: makeBlackFixture)

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let samples: [(domain: NDSDataDomain, domainValue: String, root: String, child: String, inventoryRole: String, memberRole: String, category: String, contents: String)] = [
            (.species, "pokemon", "data/pokemon", "data/pokemon/source_pokemon.txt", "pokemonDataInventory", "pokemonDataMember", "NDS Data species", "pokemon-source\n"),
            (.moves, "move", "data/moves", "data/moves/source_moves.txt", "moveDataInventory", "moveDataMember", "NDS Data moves", "moves-source\n"),
            (.items, "item", "data/items", "data/items/source_items.txt", "itemDataInventory", "itemDataMember", "NDS Data items", "items-source\n"),
            (.trainers, "trainer", "data/trainers", "data/trainers/source_trainers.txt", "trainerDataInventory", "trainerDataMember", "NDS Data trainers", "trainers-source\n"),
            (.species, "pokemon", "src/data/pokemon", "src/data/pokemon/source_pokemon.inc", "pokemonDataInventory", "pokemonDataMember", "NDS Data species", "pokemon-source-inc\n"),
            (.moves, "move", "src/data/moves", "src/data/moves/source_moves.inc", "moveDataInventory", "moveDataMember", "NDS Data moves", "moves-source-inc\n"),
            (.items, "item", "src/data/items", "src/data/items/source_items.inc", "itemDataInventory", "itemDataMember", "NDS Data items", "items-source-inc\n"),
            (.trainers, "trainer", "src/data/trainers", "src/data/trainers/source_trainers.inc", "trainerDataInventory", "trainerDataMember", "NDS Data trainers", "trainers-source-inc\n")
        ]
        let expectedBlockedActions = "parser, decoded preview, semantic controls, source writes, extraction, NARC packing, build/playtest, ROM export, mutation apply, binary writes"

        for sample in samples {
            let byteCount = UInt64(sample.contents.utf8.count)
            let rootRecord = try XCTUnwrap(
                catalog.records.first { $0.relativePath == sample.root && $0.domain == sample.domain },
                "Missing root \(sample.root)"
            )
            XCTAssertEqual(rootRecord.domain, sample.domain)
            XCTAssertEqual(rootRecord.format, .directory)
            XCTAssertEqual(rootRecord.recordCount, 1)
            XCTAssertEqual(rootRecord.byteCount, byteCount)
            XCTAssertEqual(factValue("Gen V Source Role", in: rootRecord), sample.inventoryRole)
            XCTAssertEqual(factValue("Gen V Source Data Domain", in: rootRecord), sample.domainValue)
            XCTAssertEqual(factValue("Gen V Source Data Root", in: rootRecord), sample.root)
            XCTAssertEqual(factValue("Gen V Source Data Members", in: rootRecord), "1")
            XCTAssertEqual(factValue("Gen V Source Data Bytes", in: rootRecord), "\(byteCount)")
            XCTAssertEqual(factValue("Gen V Source Data Sample Paths", in: rootRecord), sample.child)
            XCTAssertEqual(factValue("Gen V Source Data Basis", in: rootRecord), "pathFilenameCountBytesOnly")
            XCTAssertEqual(factValue("Gen V Source Data Posture", in: rootRecord), "previewOnlyNoParser")
            XCTAssertEqual(factValue("Gen V Source Data Blocked Actions", in: rootRecord), expectedBlockedActions)
            XCTAssertEqual(factValue("Gen V Source Data Blocked Reason", in: rootRecord), "domainInventoryPreviewOnly")
            XCTAssertEqual(factValue("Gen V Source Data Relationship Audit", in: rootRecord), "rootRelatedRecordsPresent")
            XCTAssertEqual(factValue("Gen V Source Data Readiness Audit", in: rootRecord), "partial")
            XCTAssertNil(factValue("Gen V Source Data Root Record", in: rootRecord))
            XCTAssertNil(rootRecord.migrationPlan)
            XCTAssertNil(rootRecord.textBankPreview)
            XCTAssertNil(factValue("Migration Status", in: rootRecord))
            XCTAssertNil(factValue("Text Bank Preview", in: rootRecord))
            assertNoGenVSourceDataSemanticFacts(rootRecord)

            let childRecord = try XCTUnwrap(
                catalog.records.first { $0.relativePath == sample.child && $0.domain == sample.domain },
                "Missing child \(sample.child)"
            )
            XCTAssertEqual(childRecord.domain, sample.domain)
            XCTAssertEqual(childRecord.byteCount, byteCount)
            XCTAssertEqual(factValue("Gen V Source Role", in: childRecord), sample.memberRole)
            XCTAssertEqual(factValue("Gen V Source Data Domain", in: childRecord), sample.domainValue)
            XCTAssertEqual(factValue("Gen V Source Data Root", in: childRecord), sample.root)
            XCTAssertEqual(factValue("Gen V Source Data Filename", in: childRecord), URL(fileURLWithPath: sample.child).lastPathComponent)
            XCTAssertEqual(factValue("Gen V Source Data Extension", in: childRecord), URL(fileURLWithPath: sample.child).pathExtension)
            XCTAssertEqual(factValue("Gen V Source Data Bytes", in: childRecord), "\(byteCount)")
            XCTAssertEqual(factValue("Gen V Source Data Basis", in: childRecord), "pathFilenameCountBytesOnly")
            XCTAssertEqual(factValue("Gen V Source Data Posture", in: childRecord), "previewOnlyNoParser")
            XCTAssertEqual(factValue("Gen V Source Data Blocked Actions", in: childRecord), expectedBlockedActions)
            XCTAssertEqual(factValue("Gen V Source Data Blocked Reason", in: childRecord), "memberMetadataPreviewOnly")
            XCTAssertEqual(factValue("Gen V Source Data Relationship Audit", in: childRecord), "memberRootContextOnly")
            XCTAssertEqual(factValue("Gen V Source Data Readiness Audit", in: childRecord), "partial")
            XCTAssertEqual(factValue("Gen V Source Data Root Record", in: childRecord), "\(sample.domain.rawValue):\(sample.root)")
            XCTAssertTrue(childRecord.relatedRecords.isEmpty)
            XCTAssertNil(factValue("Related Rows", in: childRecord))
            XCTAssertNil(childRecord.migrationPlan)
            XCTAssertNil(childRecord.textBankPreview)
            XCTAssertNil(factValue("Migration Status", in: childRecord))
            XCTAssertNil(factValue("Text Bank Preview", in: childRecord))
            assertNoGenVSourceDataSemanticFacts(childRecord)
        }

        let resourceIndex = GenIIIResourceRegistry.resourceIndex(path: root.path)
        for sample in samples {
            let byteCount = UInt64(sample.contents.utf8.count)
            let rootItem = try XCTUnwrap(resourceIndex.items.first { $0.category == sample.category && $0.path == sample.root })
            XCTAssertEqual(rootItem.kind, "directory")
            XCTAssertEqual(rootItem.size, byteCount)
            XCTAssertEqual(factValue("Gen V Source Role", in: rootItem.facts), sample.inventoryRole)
            XCTAssertEqual(factValue("Gen V Source Data Members", in: rootItem.facts), "1")
            XCTAssertEqual(factValue("Gen V Source Data Bytes", in: rootItem.facts), "\(byteCount)")
            XCTAssertEqual(factValue("Gen V Source Data Sample Paths", in: rootItem.facts), sample.child)
            XCTAssertEqual(factValue("Gen V Source Data Blocked Actions", in: rootItem.facts), expectedBlockedActions)
            XCTAssertEqual(factValue("Gen V Source Data Blocked Reason", in: rootItem.facts), "domainInventoryPreviewOnly")
            XCTAssertEqual(factValue("Gen V Source Data Relationship Audit", in: rootItem.facts), "rootRelatedRecordsPresent")
            XCTAssertEqual(factValue("Gen V Source Data Readiness Audit", in: rootItem.facts), "partial")
            XCTAssertNil(factValue("Gen V Source Data Root Record", in: rootItem.facts))
            XCTAssertFalse(rootItem.facts.contains { $0.label == "Migration Status" })
            XCTAssertFalse(rootItem.facts.contains { $0.label == "Text Bank Preview" })

            let childItem = try XCTUnwrap(resourceIndex.items.first { $0.category == sample.category && $0.path == sample.child })
            XCTAssertEqual(childItem.size, byteCount)
            XCTAssertEqual(factValue("Gen V Source Role", in: childItem.facts), sample.memberRole)
            XCTAssertEqual(factValue("Gen V Source Data Filename", in: childItem.facts), URL(fileURLWithPath: sample.child).lastPathComponent)
            XCTAssertEqual(factValue("Gen V Source Data Bytes", in: childItem.facts), "\(byteCount)")
            XCTAssertEqual(factValue("Gen V Source Data Blocked Actions", in: childItem.facts), expectedBlockedActions)
            XCTAssertEqual(factValue("Gen V Source Data Blocked Reason", in: childItem.facts), "memberMetadataPreviewOnly")
            XCTAssertEqual(factValue("Gen V Source Data Relationship Audit", in: childItem.facts), "memberRootContextOnly")
            XCTAssertEqual(factValue("Gen V Source Data Readiness Audit", in: childItem.facts), "partial")
            XCTAssertEqual(factValue("Gen V Source Data Root Record", in: childItem.facts), "\(sample.domain.rawValue):\(sample.root)")
            XCTAssertFalse(childItem.facts.contains { $0.label == "Related Rows" })
            XCTAssertFalse(childItem.facts.contains { $0.label == "Migration Status" })
            XCTAssertFalse(childItem.facts.contains { $0.label == "Text Bank Preview" })
        }
    }

    func testPokeBlackCatalogSurfacesGenVSourceDataVariantCoverageRollups() throws {
        let root = try makeRoot(name: "pokeblack", configure: makeBlackFixture)
        try write("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee  pokewhite.nds\n", to: root.appendingPathComponent("white.us/rom.sha1"))
        try write("not-a-sha1\n", to: root.appendingPathComponent("black2.us/rom.sha1"))

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let roots: [(domain: NDSDataDomain, root: String, child: String)] = [
            (.species, "data/pokemon", "data/pokemon/source_pokemon.txt"),
            (.moves, "data/moves", "data/moves/source_moves.txt"),
            (.items, "data/items", "data/items/source_items.txt"),
            (.trainers, "data/trainers", "data/trainers/source_trainers.txt"),
            (.species, "src/data/pokemon", "src/data/pokemon/source_pokemon.inc"),
            (.moves, "src/data/moves", "src/data/moves/source_moves.inc"),
            (.items, "src/data/items", "src/data/items/source_items.inc"),
            (.trainers, "src/data/trainers", "src/data/trainers/source_trainers.inc")
        ]

        for sample in roots {
            let rootRecord = try XCTUnwrap(
                catalog.records.first { $0.relativePath == sample.root && $0.domain == sample.domain },
                "Missing source-data root \(sample.root)"
            )
            XCTAssertEqual(factValue("Gen V Source Data Variant Coverage", in: rootRecord), "3/4")
            XCTAssertEqual(factValue("Gen V Source Data Variant Present", in: rootRecord), "black.us, white.us, black2.us")
            XCTAssertEqual(factValue("Gen V Source Data Variant Missing", in: rootRecord), "white2.us")
            XCTAssertEqual(factValue("Gen V Source Data Variant Basis", in: rootRecord), "sourceMarkersAndRootPresenceOnly")

            let childRecord = try XCTUnwrap(
                catalog.records.first { $0.relativePath == sample.child && $0.domain == sample.domain },
                "Missing source-data child \(sample.child)"
            )
            XCTAssertNil(factValue("Gen V Source Data Variant Coverage", in: childRecord))
            XCTAssertNil(factValue("Gen V Source Data Variant Present", in: childRecord))
            XCTAssertNil(factValue("Gen V Source Data Variant Missing", in: childRecord))
            XCTAssertNil(factValue("Gen V Source Data Variant Basis", in: childRecord))
        }

        let dataRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "data" })
        XCTAssertNil(factValue("Gen V Source Data Variant Coverage", in: dataRoot))
        let white2Unavailable = try XCTUnwrap(catalog.records.first { $0.relativePath.contains("White Version 2") && $0.role == .metadataUnavailable })
        XCTAssertNil(factValue("Gen V Source Data Variant Coverage", in: white2Unavailable))
    }

    func testPokeBlackCatalogSurfacesGenVVariantReadinessPacket() throws {
        let root = try makeRoot(name: "pokeblack", configure: makeBlackFixture)
        try write("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee  pokewhite.nds\n", to: root.appendingPathComponent("white.us/rom.sha1"))
        try write("not-a-sha1\n", to: root.appendingPathComponent("black2.us/rom.sha1"))

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let packet = try XCTUnwrap(catalog.records.first { $0.id == "resources:gen-v/variant-readiness-packet" })
        XCTAssertEqual(packet.domain, .resources)
        XCTAssertEqual(packet.relativePath, "gen-v/variant-readiness-packet")
        XCTAssertEqual(packet.format, .unknown)
        XCTAssertEqual(packet.role, .metadataPacket)
        XCTAssertTrue(packet.exists)
        XCTAssertEqual(packet.readiness?.status, .partial)
        XCTAssertEqual(factValue("Gen V Source Role", in: packet), "variantReadinessPacket")
        XCTAssertEqual(factValue("Gen V Variant Readiness Packet", in: packet), "previewOnly")
        XCTAssertEqual(factValue("Gen V Variant Readiness Basis", in: packet), "existingCatalogFactsOnly")
        XCTAssertEqual(factValue("Gen V Variant Readiness Posture", in: packet), "previewOnlyNoParserNoWrites")
        XCTAssertEqual(
            factValue("Gen V Variant Marker States", in: packet),
            "black.us=sourceMarkerPresent, white.us=sourceMarkerPresent, black2.us=sourceMarkerPresent, white2.us=unavailable"
        )
        XCTAssertEqual(
            factValue("Gen V SHA1 Text States", in: packet),
            "black.us=valid, white.us=valid, black2.us=invalid, white2.us=missing"
        )
        XCTAssertEqual(
            factValue("Gen V SHA1 Valid Digests", in: packet),
            "black.us=ffffffffffffffffffffffffffffffffffffffff, white.us=eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        )
        XCTAssertEqual(factValue("Gen V Source Root Summaries", in: packet), "src=5/92, asm=1/5, include=1/16")
        XCTAssertTrue(factValue("Gen V Source Data Summary", in: packet)?.contains("roots=8, members=8, variantCoverage=3/4") == true)
        XCTAssertTrue(factValue("Gen V Fielddata Summary", in: packet)?.contains("roots=5") == true)
        XCTAssertEqual(
            factValue("Gen V Message Summary", in: packet),
            "candidates=6, extensions=bin, dat, gmm, msg, str, txt, noDecodedPreviewRows=6"
        )
        XCTAssertTrue(factValue("Gen V Overlay Summary", in: packet)?.contains("overlays=") == true)
        XCTAssertTrue(factValue("Gen V Overlay Summary", in: packet)?.contains("ndsdisasm_config=") == true)
        XCTAssertTrue(factValue("Gen V Build Metadata Summary", in: packet)?.contains("Makefile=present") == true)
        XCTAssertTrue(factValue("Gen V Build Metadata Summary", in: packet)?.contains("variantHashes=black.us/rom.sha1=present") == true)
        XCTAssertTrue(factValue("Gen V Blocked Actions", in: packet)?.contains("binary write") == true)
        XCTAssertNil(packet.textBankPreview)
        XCTAssertNil(packet.migrationPlan)
        XCTAssertTrue(packet.diagnostics.contains { $0.code == "NDS_GEN_V_VARIANT_READINESS_PACKET_PREVIEW_ONLY" })
        XCTAssertTrue(packet.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })

        let plan = NDSDataMutationPlanner.plan(
            catalog: catalog,
            draft: NDSDataEditDraft(recordID: packet.id, editedText: "changed\n")
        )
        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_ROLE_BLOCKED" })

        let resourceIndex = GenIIIResourceRegistry.resourceIndex(path: root.path)
        let packetItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "gen-v/variant-readiness-packet" })
        XCTAssertEqual(packetItem.kind, "unknown")
        XCTAssertTrue(packetItem.facts.contains { $0.label == "Gen V Source Role" && $0.value == "variantReadinessPacket" })
        XCTAssertTrue(packetItem.facts.contains { $0.label == "Gen V Variant Readiness Packet" && $0.value == "previewOnly" })
        XCTAssertTrue(packetItem.facts.contains { $0.label == "Gen V Variant Readiness Basis" && $0.value == "existingCatalogFactsOnly" })
        XCTAssertFalse(packetItem.facts.contains { $0.label == "Migration Status" })
        XCTAssertFalse(packetItem.facts.contains { $0.label == "Text Bank Preview" })
    }

    func testPokeBlackCatalogSurfacesGenVGeneratedOutputFreshnessPacket() throws {
        let root = try makeRoot(name: "pokeblack", configure: makeBlackFixture)
        try write("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee  pokewhite.nds\n", to: root.appendingPathComponent("white.us/rom.sha1"))
        try write("not-a-sha1\n", to: root.appendingPathComponent("black2.us/rom.sha1"))

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let packet = try XCTUnwrap(catalog.records.first { $0.id == "resources:gen-v/generated-output-freshness-packet" })
        XCTAssertEqual(packet.domain, .resources)
        XCTAssertEqual(packet.relativePath, "gen-v/generated-output-freshness-packet")
        XCTAssertEqual(packet.format, .unknown)
        XCTAssertEqual(packet.role, .metadataPacket)
        XCTAssertTrue(packet.exists)
        XCTAssertEqual(packet.readiness?.status, .partial)
        XCTAssertEqual(factValue("Gen V Source Role", in: packet), "generatedOutputFreshnessPacket")
        XCTAssertEqual(factValue("Gen V Generated Output Freshness Packet", in: packet), "previewOnly")
        XCTAssertEqual(factValue("Gen V Generated Output Freshness Basis", in: packet), "existingCatalogAndBuildValidationFactsOnly")
        XCTAssertEqual(factValue("Gen V Generated Output Freshness Posture", in: packet), "previewOnlyNoBuildNoGeneratedOutputWrites")
        XCTAssertEqual(
            factValue("Gen V Source Marker States", in: packet),
            "black.us=sourceMarkerPresent, white.us=sourceMarkerPresent, black2.us=sourceMarkerPresent, white2.us=unavailable"
        )
        XCTAssertEqual(
            factValue("Gen V SHA1 Text States", in: packet),
            "black.us=valid, white.us=valid, black2.us=invalid, white2.us=missing"
        )
        XCTAssertEqual(
            factValue("Gen V SHA1 Valid Digests", in: packet),
            "black.us=ffffffffffffffffffffffffffffffffffffffff, white.us=eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
        )
        XCTAssertTrue(factValue("Gen V Build Metadata Summary", in: packet)?.contains("Makefile=present") == true)
        XCTAssertEqual(factValue("Gen V Source Root Summaries", in: packet), "src=5/92, asm=1/5, include=1/16")
        XCTAssertTrue(factValue("Gen V Variant Readiness Summary", in: packet)?.contains("packet=present") == true)
        XCTAssertTrue(factValue("Gen V Variant Readiness Summary", in: packet)?.contains("sha1States=black.us=valid") == true)
        XCTAssertTrue(factValue("Gen V Declared Generated Outputs", in: packet)?.contains("build=missing") == true)
        XCTAssertTrue(factValue("Gen V Declared Generated Outputs", in: packet)?.contains("pokeblack.nds=missing") == true)
        XCTAssertTrue(factValue("Gen V Build Target Output Freshness", in: packet)?.contains("black-rom:pokeblack.nds=missing") == true)
        XCTAssertTrue(factValue("Gen V Build Target Output Freshness", in: packet)?.contains("checksum=outputMissing") == true)
        XCTAssertTrue(factValue("Gen V Build Target Output Freshness", in: packet)?.contains("freshness=outputMissing") == true)
        XCTAssertTrue(factValue("Gen V Blocked Actions", in: packet)?.contains("binary write") == true)
        XCTAssertNil(packet.textBankPreview)
        XCTAssertNil(packet.migrationPlan)
        XCTAssertTrue(packet.diagnostics.contains { $0.code == "NDS_GEN_V_GENERATED_OUTPUT_FRESHNESS_PACKET_PREVIEW_ONLY" })
        XCTAssertTrue(packet.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })

        let plan = NDSDataMutationPlanner.plan(
            catalog: catalog,
            draft: NDSDataEditDraft(recordID: packet.id, editedText: "changed\n")
        )
        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_ROLE_BLOCKED" })

        let resourceIndex = GenIIIResourceRegistry.resourceIndex(path: root.path)
        let packetItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "gen-v/generated-output-freshness-packet" })
        XCTAssertEqual(packetItem.kind, "unknown")
        XCTAssertTrue(packetItem.facts.contains { $0.label == "Gen V Source Role" && $0.value == "generatedOutputFreshnessPacket" })
        XCTAssertTrue(packetItem.facts.contains { $0.label == "Gen V Generated Output Freshness Packet" && $0.value == "previewOnly" })
        XCTAssertTrue(packetItem.facts.contains { $0.label == "Gen V Build Target Output Freshness" && $0.value.contains("black-rom:pokeblack.nds=missing") })
        XCTAssertFalse(packetItem.facts.contains { $0.label == "Migration Status" })
        XCTAssertFalse(packetItem.facts.contains { $0.label == "Text Bank Preview" })
    }

    func testPokeBlackCatalogSurfacesGenVBlockedActionAuditPacket() throws {
        let root = try makeRoot(name: "pokeblack", configure: makeBlackFixture)
        try write("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee  pokewhite.nds\n", to: root.appendingPathComponent("white.us/rom.sha1"))
        try write("not-a-sha1\n", to: root.appendingPathComponent("black2.us/rom.sha1"))

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let packet = try XCTUnwrap(catalog.records.first { $0.id == "resources:gen-v/blocked-action-audit-packet" })
        XCTAssertEqual(packet.domain, .resources)
        XCTAssertEqual(packet.relativePath, "gen-v/blocked-action-audit-packet")
        XCTAssertEqual(packet.format, .unknown)
        XCTAssertEqual(packet.role, .metadataPacket)
        XCTAssertTrue(packet.exists)
        XCTAssertEqual(packet.readiness?.status, .partial)
        XCTAssertEqual(factValue("Gen V Source Role", in: packet), "blockedActionAuditPacket")
        XCTAssertEqual(factValue("Gen V Blocked Action Audit Packet", in: packet), "previewOnly")
        XCTAssertEqual(factValue("Gen V Blocked Action Audit Basis", in: packet), "existingReadinessBlockedActionsAndDiagnosticsOnly")
        XCTAssertEqual(factValue("Gen V Blocked Action Audit Posture", in: packet), "previewOnlyNoParserNoWritesNoExecution")
        XCTAssertTrue(factValue("Gen V Readiness Status Summary", in: packet)?.contains("partial=") == true)
        XCTAssertTrue(factValue("Gen V Readiness Status Summary", in: packet)?.contains("blocked=") == true)
        XCTAssertTrue(factValue("Gen V Unique Blocked Actions", in: packet)?.contains("binary write") == true)
        XCTAssertTrue(factValue("Gen V Unique Blocked Actions", in: packet)?.contains("source writes") == true)
        XCTAssertTrue(factValue("Gen V Unique Blocked Actions", in: packet)?.contains("NARC packing") == true)
        XCTAssertTrue(factValue("Gen V Source Data Blocked Reason Summary", in: packet)?.contains("domainInventoryPreviewOnly=") == true)
        XCTAssertTrue(factValue("Gen V Source Data Blocked Reason Summary", in: packet)?.contains("memberMetadataPreviewOnly=") == true)
        XCTAssertTrue(factValue("Gen V Diagnostic Severity Summary", in: packet)?.contains("info=") == true)
        XCTAssertTrue(factValue("Gen V Diagnostic Severity Summary", in: packet)?.contains("warning=") == true)
        XCTAssertTrue(factValue("Gen V Diagnostic Code Summary", in: packet)?.contains("NDS_GEN_V_WRITE_BLOCKED=") == true)
        XCTAssertTrue(
            factValue("Gen V Prior Packet Coverage", in: packet)?.contains("gen-v/variant-readiness-packet=present") == true
        )
        XCTAssertTrue(
            factValue("Gen V Prior Packet Coverage", in: packet)?.contains("gen-v/generated-output-freshness-packet=present") == true
        )
        XCTAssertTrue(factValue("Gen V Blocked Actions", in: packet)?.contains("binary write") == true)
        XCTAssertNil(packet.textBankPreview)
        XCTAssertNil(packet.migrationPlan)
        XCTAssertTrue(packet.diagnostics.contains { $0.code == "NDS_GEN_V_BLOCKED_ACTION_AUDIT_PACKET_PREVIEW_ONLY" })
        XCTAssertTrue(packet.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })

        let plan = NDSDataMutationPlanner.plan(
            catalog: catalog,
            draft: NDSDataEditDraft(recordID: packet.id, editedText: "changed\n")
        )
        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_ROLE_BLOCKED" })

        let resourceIndex = GenIIIResourceRegistry.resourceIndex(path: root.path)
        let packetItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "gen-v/blocked-action-audit-packet" })
        XCTAssertEqual(packetItem.kind, "unknown")
        XCTAssertTrue(packetItem.facts.contains { $0.label == "Gen V Source Role" && $0.value == "blockedActionAuditPacket" })
        XCTAssertTrue(packetItem.facts.contains { $0.label == "Gen V Blocked Action Audit Packet" && $0.value == "previewOnly" })
        XCTAssertTrue(packetItem.facts.contains { $0.label == "Gen V Unique Blocked Actions" && $0.value.contains("binary write") })
        XCTAssertTrue(packetItem.facts.contains { $0.label == "Gen V Diagnostic Code Summary" && $0.value.contains("NDS_GEN_V_WRITE_BLOCKED") })
        XCTAssertFalse(packetItem.facts.contains { $0.label == "Migration Status" })
        XCTAssertFalse(packetItem.facts.contains { $0.label == "Text Bank Preview" })
    }

    func testPokeBlackCatalogSurfacesGenVReadinessDigestPacket() throws {
        let root = try makeRoot(name: "pokeblack", configure: makeBlackFixture)
        try write("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee  pokewhite.nds\n", to: root.appendingPathComponent("white.us/rom.sha1"))
        try write("not-a-sha1\n", to: root.appendingPathComponent("black2.us/rom.sha1"))

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let packet = try XCTUnwrap(catalog.records.first { $0.id == "resources:gen-v/readiness-digest-packet" })
        XCTAssertEqual(packet.domain, .resources)
        XCTAssertEqual(packet.relativePath, "gen-v/readiness-digest-packet")
        XCTAssertEqual(packet.format, .unknown)
        XCTAssertEqual(packet.role, .metadataPacket)
        XCTAssertTrue(packet.exists)
        XCTAssertEqual(packet.readiness?.status, .partial)
        XCTAssertEqual(factValue("Gen V Source Role", in: packet), "readinessDigestPacket")
        XCTAssertEqual(factValue("Gen V Readiness Digest Packet", in: packet), "previewOnly")
        XCTAssertEqual(factValue("Gen V Readiness Digest Basis", in: packet), "existingCatalogPacketFactsOnly")
        XCTAssertEqual(factValue("Gen V Readiness Digest Posture", in: packet), "previewOnlyNoParserNoWritesNoExecution")
        XCTAssertTrue(factValue("Gen V Readiness Digest Inputs", in: packet)?.contains("gen-v/variant-readiness-packet=present") == true)
        XCTAssertTrue(factValue("Gen V Readiness Digest Inputs", in: packet)?.contains("gen-v/generated-output-freshness-packet=present") == true)
        XCTAssertTrue(factValue("Gen V Readiness Digest Inputs", in: packet)?.contains("gen-v/blocked-action-audit-packet=present") == true)
        XCTAssertTrue(factValue("Gen V Digest Variant Readiness Summary", in: packet)?.contains("Gen V Variant Marker States=black.us=sourceMarkerPresent") == true)
        XCTAssertTrue(factValue("Gen V Digest Generated Output Summary", in: packet)?.contains("black-rom:pokeblack.nds=missing") == true)
        XCTAssertTrue(factValue("Gen V Digest Blocked Action Summary", in: packet)?.contains("Gen V Unique Blocked Actions=") == true)
        XCTAssertTrue(factValue("Gen V Digest Blocked Action Summary", in: packet)?.contains("binary write") == true)
        XCTAssertTrue(factValue("Gen V Source Data Coverage Summary", in: packet)?.contains("roots=8, members=8, variantCoverage=3/4") == true)
        XCTAssertTrue(factValue("Gen V Manual Build Readiness Summary", in: packet)?.contains("metadata=Makefile=present") == true)
        XCTAssertTrue(factValue("Gen V Manual Build Readiness Summary", in: packet)?.contains("targetFreshness=black-rom:pokeblack.nds=missing") == true)
        XCTAssertEqual(factValue("Gen V Readiness Digest Copy Guidance", in: packet), "copyOnlyUseBuildPatchPlaytestReportRowsForManualReview")
        XCTAssertTrue(factValue("Gen V Blocked Actions", in: packet)?.contains("binary write") == true)
        XCTAssertNil(packet.textBankPreview)
        XCTAssertNil(packet.migrationPlan)
        XCTAssertTrue(packet.diagnostics.contains { $0.code == "NDS_GEN_V_READINESS_DIGEST_PACKET_PREVIEW_ONLY" })
        XCTAssertTrue(packet.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })

        let plan = NDSDataMutationPlanner.plan(
            catalog: catalog,
            draft: NDSDataEditDraft(recordID: packet.id, editedText: "changed\n")
        )
        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_ROLE_BLOCKED" })

        let resourceIndex = GenIIIResourceRegistry.resourceIndex(path: root.path)
        let packetItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "gen-v/readiness-digest-packet" })
        XCTAssertEqual(packetItem.kind, "unknown")
        XCTAssertTrue(packetItem.facts.contains { $0.label == "Gen V Source Role" && $0.value == "readinessDigestPacket" })
        XCTAssertTrue(packetItem.facts.contains { $0.label == "Gen V Readiness Digest Packet" && $0.value == "previewOnly" })
        XCTAssertTrue(packetItem.facts.contains { $0.label == "Gen V Readiness Digest Inputs" && $0.value.contains("blocked-action-audit-packet=present") })
        XCTAssertTrue(packetItem.facts.contains { $0.label == "Gen V Manual Build Readiness Summary" && $0.value.contains("pokeblack.nds=missing") })
        XCTAssertFalse(packetItem.facts.contains { $0.label == "Migration Status" })
        XCTAssertFalse(packetItem.facts.contains { $0.label == "Text Bank Preview" })
    }

    func testPokeBlackCatalogSurfacesGenVArchiveGroupInventoryFacts() throws {
        let root = try makeRoot(name: "pokeblack", configure: makeBlackFixture)

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let archiveGroupRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/a" })
        XCTAssertEqual(archiveGroupRoot.domain, .resources)
        XCTAssertEqual(archiveGroupRoot.format, .directory)
        XCTAssertEqual(archiveGroupRoot.recordCount, 1)
        XCTAssertEqual(factValue("Gen V Source Role", in: archiveGroupRoot), "nitroArchiveGroupInventory")
        XCTAssertEqual(factValue("Gen V Readiness", in: archiveGroupRoot), "previewOnly")
        XCTAssertEqual(factValue("Gen V Reference Posture", in: archiveGroupRoot), "cleanRoomReferenceOnly")
        XCTAssertTrue(factValue("Gen V Action State", in: archiveGroupRoot)?.contains("source inventory stays preview-only") == true)
        XCTAssertEqual(archiveGroupRoot.readiness?.status, .partial)
        XCTAssertTrue(archiveGroupRoot.readiness?.detail.contains("archive-group root") == true)
        XCTAssertNil(factValue("Migration Status", in: archiveGroupRoot))

        let archiveGroupChild = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/a/0/0/0/resource.bin" })
        XCTAssertEqual(factValue("Gen V Source Role", in: archiveGroupChild), "nitroArchiveGroup")

        let resourceIndex = GenIIIResourceRegistry.resourceIndex(path: root.path)
        let archiveGroupResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "files/a" })
        XCTAssertEqual(archiveGroupResourceItem.kind, "directory")
        XCTAssertTrue(archiveGroupResourceItem.facts.contains { $0.label == "Gen V Source Role" && $0.value == "nitroArchiveGroupInventory" })
        XCTAssertTrue(archiveGroupResourceItem.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertTrue(archiveGroupResourceItem.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        XCTAssertFalse(archiveGroupResourceItem.facts.contains { $0.label == "Migration Status" })
    }

    func testPokeBlackCatalogSurfacesGenVNitroFSRootInventoryFacts() throws {
        let root = try makeRoot(name: "pokeblack", configure: makeBlackFixture)

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let filesRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "files" })
        XCTAssertEqual(filesRoot.id, "resources:files")
        XCTAssertEqual(filesRoot.domain, .resources)
        XCTAssertEqual(filesRoot.format, .directory)
        XCTAssertEqual(filesRoot.recordCount, 15)
        XCTAssertEqual(factValue("Shallow Count", in: filesRoot), "15")
        XCTAssertEqual(factValue("Gen V Source Role", in: filesRoot), "nitroFSRootInventory")
        XCTAssertEqual(factValue("Gen V Readiness", in: filesRoot), "previewOnly")
        XCTAssertEqual(factValue("Gen V Reference Posture", in: filesRoot), "cleanRoomReferenceOnly")
        XCTAssertTrue(factValue("Gen V Action State", in: filesRoot)?.contains("source inventory stays preview-only") == true)
        XCTAssertEqual(filesRoot.readiness?.status, .partial)
        XCTAssertTrue(filesRoot.readiness?.detail.contains("files root") == true)
        XCTAssertNil(factValue("Migration Status", in: filesRoot))
        XCTAssertNil(factValue("Text Bank Preview", in: filesRoot))

        let archiveGroupChild = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/a/0/0/0/resource.bin" })
        XCTAssertEqual(factValue("Gen V Source Role", in: archiveGroupChild), "nitroArchiveGroup")
        let messageBankChild = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/msgdata/story/message_bank.txt" })
        XCTAssertEqual(factValue("Gen V Source Role", in: messageBankChild), "messageBankMetadata")
        let soundArchiveChild = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/wb_sound_data.sdat" })
        XCTAssertEqual(factValue("Gen V Source Role", in: soundArchiveChild), "soundArchiveMetadata")

        let resourceIndex = GenIIIResourceRegistry.resourceIndex(path: root.path)
        let filesResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "files" })
        XCTAssertEqual(filesResourceItem.kind, "directory")
        XCTAssertTrue(filesResourceItem.facts.contains { $0.label == "Shallow Count" && $0.value == "15" })
        XCTAssertTrue(filesResourceItem.facts.contains { $0.label == "Gen V Source Role" && $0.value == "nitroFSRootInventory" })
        XCTAssertTrue(filesResourceItem.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertTrue(filesResourceItem.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        XCTAssertFalse(filesResourceItem.facts.contains { $0.label == "Migration Status" })

        let plan = NDSDataMutationPlanner.plan(
            catalog: catalog,
            draft: NDSDataEditDraft(recordID: filesRoot.id, editedText: "changed\n")
        )
        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })
    }

    func testPokeBlackCatalogSurfacesGenVFielddataInventoryFacts() throws {
        let root = try makeRoot(name: "pokeblack", configure: makeBlackFixture)

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let fielddataRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata" })
        XCTAssertEqual(fielddataRoot.id, "resources:files/fielddata")
        XCTAssertEqual(fielddataRoot.domain, .resources)
        XCTAssertEqual(fielddataRoot.format, .directory)
        XCTAssertEqual(fielddataRoot.recordCount, 5)
        XCTAssertEqual(factValue("Gen V Source Role", in: fielddataRoot), "fielddataInventory")
        XCTAssertEqual(factValue("Gen V Readiness", in: fielddataRoot), "previewOnly")
        XCTAssertEqual(factValue("Gen V Reference Posture", in: fielddataRoot), "cleanRoomReferenceOnly")
        XCTAssertTrue(factValue("Gen V Blocked Actions", in: fielddataRoot)?.contains("NARC pack") == true)
        XCTAssertTrue(factValue("Gen V Action State", in: fielddataRoot)?.contains("source inventory stays preview-only") == true)
        XCTAssertEqual(fielddataRoot.readiness?.status, .partial)
        XCTAssertTrue(fielddataRoot.readiness?.detail.contains("fielddata inventory") == true)
        XCTAssertNil(factValue("Migration Status", in: fielddataRoot))

        let mapMatrixRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/mapmatrix" })
        XCTAssertEqual(mapMatrixRoot.id, "maps:files/fielddata/mapmatrix")
        XCTAssertEqual(mapMatrixRoot.domain, .maps)
        XCTAssertEqual(mapMatrixRoot.format, .directory)
        XCTAssertEqual(mapMatrixRoot.recordCount, 1)
        XCTAssertEqual(factValue("Gen V Source Role", in: mapMatrixRoot), "fielddataMapMatrixInventory")
        XCTAssertTrue(factValue("Gen V Action State", in: mapMatrixRoot)?.contains("source inventory stays preview-only") == true)
        XCTAssertNil(factValue("Migration Status", in: mapMatrixRoot))

        let mapMatrixChild = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/mapmatrix/0001.bin" })
        XCTAssertEqual(factValue("Gen V Source Role", in: mapMatrixChild), "fielddataMapMatrixMember")
        XCTAssertEqual(factValue("Gen V Readiness", in: mapMatrixChild), "previewOnly")
        XCTAssertFalse(mapMatrixChild.relatedRecords.contains { $0.recordID == fielddataRoot.id })

        let mapTableRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/maptable" })
        XCTAssertEqual(mapTableRoot.id, "maps:files/fielddata/maptable")
        XCTAssertEqual(mapTableRoot.domain, .maps)
        XCTAssertEqual(mapTableRoot.format, .directory)
        XCTAssertEqual(mapTableRoot.recordCount, 1)
        XCTAssertEqual(factValue("Gen V Source Role", in: mapTableRoot), "fielddataMapTableInventory")
        XCTAssertNil(factValue("Migration Status", in: mapTableRoot))

        let mapTableChild = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/maptable/map.bin" })
        XCTAssertEqual(factValue("Gen V Source Role", in: mapTableChild), "fielddataMapTableMember")
        XCTAssertEqual(factValue("Gen V Readiness", in: mapTableChild), "previewOnly")
        XCTAssertFalse(mapTableChild.relatedRecords.contains { $0.recordID == fielddataRoot.id })

        let scriptRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/script" })
        XCTAssertEqual(scriptRoot.id, "scripts:files/fielddata/script")
        XCTAssertEqual(scriptRoot.domain, .scripts)
        XCTAssertEqual(scriptRoot.format, .directory)
        XCTAssertEqual(scriptRoot.recordCount, 2)
        XCTAssertEqual(scriptRoot.byteCount, UInt64(4))
        XCTAssertEqual(factValue("Shallow Count", in: scriptRoot), "2")
        XCTAssertEqual(factValue("Bytes", in: scriptRoot), "4")
        XCTAssertEqual(factValue("Gen V Script Members", in: scriptRoot), "2")
        XCTAssertEqual(factValue("Gen V Script Bytes", in: scriptRoot), "4")
        XCTAssertTrue(factValue("Gen V Script Sample Paths", in: scriptRoot)?.contains("files/fielddata/script/scr_seq/0001.bin") == true)
        XCTAssertTrue(factValue("Gen V Script Sample Paths", in: scriptRoot)?.contains("files/fielddata/script/scr_seq/0002.bin") == true)
        XCTAssertEqual(factValue("Gen V Source Role", in: scriptRoot), "fielddataScriptInventory")
        XCTAssertEqual(factValue("Gen V Readiness", in: scriptRoot), "previewOnly")
        XCTAssertTrue(factValue("Gen V Blocked Actions", in: scriptRoot)?.contains("NARC pack") == true)
        XCTAssertTrue(scriptRoot.diagnostics.contains { $0.code == "NDS_GEN_V_READINESS_PREVIEW_ONLY" })
        XCTAssertTrue(scriptRoot.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })
        XCTAssertNil(factValue("Migration Status", in: scriptRoot))

        let scriptChild = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/script/scr_seq/0001.bin" })
        XCTAssertEqual(scriptChild.byteCount, UInt64(1))
        XCTAssertEqual(factValue("Bytes", in: scriptChild), "1")
        XCTAssertEqual(factValue("Gen V Source Role", in: scriptChild), "fielddataScriptMember")
        XCTAssertEqual(factValue("Gen V Readiness", in: scriptChild), "previewOnly")
        XCTAssertTrue(factValue("Gen V Blocked Actions", in: scriptChild)?.contains("binary write") == true)
        XCTAssertTrue(scriptChild.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })
        XCTAssertFalse(scriptChild.relatedRecords.contains { $0.recordID == fielddataRoot.id })

        let secondScriptChild = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/script/scr_seq/0002.bin" })
        XCTAssertEqual(secondScriptChild.byteCount, UInt64(3))
        XCTAssertEqual(factValue("Bytes", in: secondScriptChild), "3")
        XCTAssertEqual(factValue("Gen V Source Role", in: secondScriptChild), "fielddataScriptMember")
        XCTAssertTrue(secondScriptChild.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })

        let zoneEventRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/eventdata/zone_event" })
        XCTAssertEqual(zoneEventRoot.id, "scripts:files/fielddata/eventdata/zone_event")
        XCTAssertEqual(zoneEventRoot.domain, .scripts)
        XCTAssertEqual(zoneEventRoot.format, .directory)
        XCTAssertEqual(zoneEventRoot.recordCount, 1)
        XCTAssertEqual(factValue("Gen V Source Role", in: zoneEventRoot), "fielddataZoneEventInventory")
        XCTAssertNil(factValue("Migration Status", in: zoneEventRoot))

        let zoneEventChild = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/eventdata/zone_event/zone_001.json" })
        XCTAssertEqual(factValue("Gen V Source Role", in: zoneEventChild), "fielddataZoneEventMetadata")
        XCTAssertEqual(factValue("Gen V Readiness", in: zoneEventChild), "previewOnly")
        XCTAssertFalse(zoneEventChild.relatedRecords.contains { $0.recordID == fielddataRoot.id })

        let genVContextIDs = genVEncounterFielddataMessageContextRecordIDs()
        let expectedRelatedRows = "\(genVContextIDs.count - 1)"
        let allGenVContextDomains = "encounters, items, maps, moves, resources, scripts, species, text, trainers"
        func assertFielddataRootRelationships(_ record: NDSDataCatalogRecord, relatedDomains: String) {
            XCTAssertEqual(Set(record.relatedRecords.map(\.recordID)), genVContextIDs.subtracting([record.id]))
            XCTAssertEqual(factValue("Related Rows", in: record), expectedRelatedRows)
            XCTAssertEqual(factValue("Related Domains", in: record), relatedDomains)
        }
        assertFielddataRootRelationships(fielddataRoot, relatedDomains: allGenVContextDomains)
        assertFielddataRootRelationships(mapMatrixRoot, relatedDomains: allGenVContextDomains)
        assertFielddataRootRelationships(mapTableRoot, relatedDomains: allGenVContextDomains)
        assertFielddataRootRelationships(scriptRoot, relatedDomains: allGenVContextDomains)
        assertFielddataRootRelationships(zoneEventRoot, relatedDomains: allGenVContextDomains)

        let resourceIndex = GenIIIResourceRegistry.resourceIndex(path: root.path)
        let fielddataResource = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "files/fielddata" })
        XCTAssertTrue(fielddataResource.facts.contains { $0.label == "Gen V Source Role" && $0.value == "fielddataInventory" })
        XCTAssertTrue(fielddataResource.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertTrue(fielddataResource.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        XCTAssertTrue(fielddataResource.facts.contains { $0.label == "Related Rows" && $0.value == expectedRelatedRows })
        XCTAssertTrue(fielddataResource.facts.contains { $0.label == "Related Domains" && $0.value == allGenVContextDomains })
        XCTAssertFalse(fielddataResource.facts.contains { $0.label == "Migration Status" })

        let mapMatrixResource = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data maps" && $0.path == "files/fielddata/mapmatrix" })
        XCTAssertTrue(mapMatrixResource.facts.contains { $0.label == "Gen V Source Role" && $0.value == "fielddataMapMatrixInventory" })
        XCTAssertTrue(mapMatrixResource.facts.contains { $0.label == "Related Rows" && $0.value == expectedRelatedRows })
        XCTAssertTrue(mapMatrixResource.facts.contains { $0.label == "Related Domains" && $0.value == allGenVContextDomains })
        XCTAssertFalse(mapMatrixResource.facts.contains { $0.label == "Migration Status" })

        let mapTableResource = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data maps" && $0.path == "files/fielddata/maptable" })
        XCTAssertTrue(mapTableResource.facts.contains { $0.label == "Gen V Source Role" && $0.value == "fielddataMapTableInventory" })
        XCTAssertTrue(mapTableResource.facts.contains { $0.label == "Related Rows" && $0.value == expectedRelatedRows })
        XCTAssertTrue(mapTableResource.facts.contains { $0.label == "Related Domains" && $0.value == allGenVContextDomains })
        XCTAssertFalse(mapTableResource.facts.contains { $0.label == "Migration Status" })

        let scriptResource = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data scripts" && $0.path == "files/fielddata/script" })
        XCTAssertEqual(scriptResource.size, UInt64(4))
        XCTAssertTrue(scriptResource.facts.contains { $0.label == "Gen V Source Role" && $0.value == "fielddataScriptInventory" })
        XCTAssertTrue(scriptResource.facts.contains { $0.label == "Gen V Script Members" && $0.value == "2" })
        XCTAssertTrue(scriptResource.facts.contains { $0.label == "Gen V Script Bytes" && $0.value == "4" })
        XCTAssertTrue(scriptResource.facts.contains { $0.label == "Related Rows" && $0.value == expectedRelatedRows })
        XCTAssertTrue(scriptResource.facts.contains { $0.label == "Related Domains" && $0.value == allGenVContextDomains })
        XCTAssertFalse(scriptResource.facts.contains { $0.label == "Migration Status" })

        let zoneEventResource = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data scripts" && $0.path == "files/fielddata/eventdata/zone_event" })
        XCTAssertTrue(zoneEventResource.facts.contains { $0.label == "Gen V Source Role" && $0.value == "fielddataZoneEventInventory" })
        XCTAssertTrue(zoneEventResource.facts.contains { $0.label == "Related Rows" && $0.value == expectedRelatedRows })
        XCTAssertTrue(zoneEventResource.facts.contains { $0.label == "Related Domains" && $0.value == allGenVContextDomains })
        XCTAssertFalse(zoneEventResource.facts.contains { $0.label == "Migration Status" })

        let plan = NDSDataMutationPlanner.plan(
            catalog: catalog,
            draft: NDSDataEditDraft(recordID: fielddataRoot.id, editedText: "changed\n")
        )
        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })

        let scriptPlan = NDSDataMutationPlanner.plan(
            catalog: catalog,
            draft: NDSDataEditDraft(recordID: scriptRoot.id, editedText: "changed\n")
        )
        XCTAssertTrue(scriptPlan.changes.isEmpty)
        XCTAssertTrue(scriptPlan.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })
    }

    func testPokeBlackCatalogLinksGenVSourceDataDomainInventoryRelatedRows() throws {
        let root = try makeRoot(name: "pokeblack", configure: makeBlackFixture)

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let recordsByID = Dictionary(uniqueKeysWithValues: catalog.records.map { ($0.id, $0) })
        let contextIDs = genVEncounterFielddataMessageContextRecordIDs()
        let expectedRelatedRows = "\(contextIDs.count - 1)"
        let allGenVContextDomains = "encounters, items, maps, moves, resources, scripts, species, text, trainers"
        let expectedBlockedActions = "parser, decoded preview, semantic controls, source writes, extraction, NARC packing, build/playtest, ROM export, mutation apply, binary writes"

        for id in contextIDs {
            let record = try XCTUnwrap(recordsByID[id], "Missing Gen V context record \(id)")
            XCTAssertEqual(Set(record.relatedRecords.map(\.recordID)), contextIDs.subtracting([id]), "Unexpected related rows for \(id)")
            XCTAssertEqual(factValue("Related Rows", in: record), expectedRelatedRows, "Unexpected related-row fact for \(id)")
            XCTAssertEqual(factValue("Readiness", in: record), "partial", "Unexpected readiness fact for \(id)")
        }

        let encounter = try XCTUnwrap(recordsByID["encounters:data/encounters/route_1.txt"])
        XCTAssertEqual(factValue("Gen V Source Role", in: encounter), "encounterPreview")
        XCTAssertEqual(factValue("Gen V Encounter Record", in: encounter), "previewOnly")
        XCTAssertEqual(factValue("Related Domains", in: encounter), "items, maps, moves, resources, scripts, species, text, trainers")

        let fielddataRoot = try XCTUnwrap(recordsByID["resources:files/fielddata"])
        XCTAssertEqual(factValue("Gen V Source Role", in: fielddataRoot), "fielddataInventory")
        XCTAssertEqual(factValue("Related Domains", in: fielddataRoot), allGenVContextDomains)

        let messageBankRoot = try XCTUnwrap(recordsByID["text:files/msgdata"])
        XCTAssertEqual(factValue("Gen V Source Role", in: messageBankRoot), "messageBankInventory")
        XCTAssertEqual(factValue("Gen V Message Candidate Count", in: messageBankRoot), "6")
        XCTAssertEqual(factValue("Related Domains", in: messageBankRoot), "encounters, items, maps, moves, resources, scripts, species, trainers")

        let numberedMessageCandidate = try XCTUnwrap(recordsByID["resources:files/msgdata/msg/0001.bin"])
        XCTAssertEqual(factValue("Gen V Source Role", in: numberedMessageCandidate), "messageBankMetadata")
        XCTAssertEqual(factValue("Gen V Message Decoded Preview", in: numberedMessageCandidate), "noDecodedPreview")
        XCTAssertEqual(factValue("Gen V Message Numeric Bank Hint", in: numberedMessageCandidate), "0001")
        XCTAssertEqual(factValue("Related Domains", in: numberedMessageCandidate), allGenVContextDomains)
        XCTAssertFalse(numberedMessageCandidate.relatedRecords.contains { $0.recordID == "maps:files/fielddata/mapmatrix/0001.bin" })
        XCTAssertFalse(numberedMessageCandidate.relatedRecords.contains { $0.recordID == "resources:files/fielddata/script/scr_seq/0001.bin" })

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
            XCTAssertEqual(factValue("Gen V Source Role", in: rootRecord), rootRole)
            XCTAssertEqual(factValue("Related Rows", in: rootRecord), expectedRelatedRows)
            XCTAssertEqual(factValue("Related Domains", in: rootRecord), allGenVContextDomains)
            XCTAssertEqual(factValue("Readiness", in: rootRecord), "partial")
            XCTAssertEqual(factValue("Gen V Source Data Relationship Audit", in: rootRecord), "rootRelatedRecordsPresent")
            XCTAssertEqual(factValue("Gen V Source Data Readiness Audit", in: rootRecord), "partial")
            XCTAssertEqual(factValue("Gen V Source Data Blocked Actions", in: rootRecord), expectedBlockedActions)
            XCTAssertEqual(factValue("Gen V Source Data Blocked Reason", in: rootRecord), "domainInventoryPreviewOnly")
            XCTAssertNil(factValue("Gen V Source Data Root Record", in: rootRecord))

            let memberRecord = try XCTUnwrap(recordsByID[memberID], "Missing Gen V source data member \(memberID)")
            XCTAssertEqual(factValue("Gen V Source Role", in: memberRecord), memberRole)
            XCTAssertEqual(factValue("Gen V Source Data Relationship Audit", in: memberRecord), "memberRootContextOnly")
            XCTAssertEqual(factValue("Gen V Source Data Readiness Audit", in: memberRecord), "partial")
            XCTAssertEqual(factValue("Gen V Source Data Blocked Actions", in: memberRecord), expectedBlockedActions)
            XCTAssertEqual(factValue("Gen V Source Data Blocked Reason", in: memberRecord), "memberMetadataPreviewOnly")
            XCTAssertEqual(factValue("Gen V Source Data Root Record", in: memberRecord), rootID)
            XCTAssertTrue(memberRecord.relatedRecords.isEmpty)
            XCTAssertNil(factValue("Related Rows", in: memberRecord))
        }

        let pokemonSourceMember = try XCTUnwrap(recordsByID["species:data/pokemon/source_pokemon.txt"])
        XCTAssertEqual(factValue("Gen V Source Role", in: pokemonSourceMember), "pokemonDataMember")
        XCTAssertEqual(factValue("Gen V Source Data Posture", in: pokemonSourceMember), "previewOnlyNoParser")
        XCTAssertTrue(pokemonSourceMember.relatedRecords.isEmpty)
        XCTAssertNil(factValue("Related Rows", in: pokemonSourceMember))

        let scriptChild = try XCTUnwrap(recordsByID["resources:files/fielddata/script/scr_seq/0001.bin"])
        XCTAssertEqual(factValue("Gen V Source Role", in: scriptChild), "fielddataScriptMember")
        XCTAssertFalse(scriptChild.relatedRecords.contains { $0.recordID == numberedMessageCandidate.id })
        XCTAssertFalse(scriptChild.relatedRecords.contains { $0.recordID == fielddataRoot.id })

        let encounterPlan = NDSDataMutationPlanner.plan(
            catalog: catalog,
            draft: NDSDataEditDraft(recordID: encounter.id, editedText: "changed\n")
        )
        XCTAssertTrue(encounterPlan.changes.isEmpty)
        XCTAssertTrue(encounterPlan.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })

        let messagePlan = NDSDataMutationPlanner.plan(
            catalog: catalog,
            draft: NDSDataEditDraft(recordID: numberedMessageCandidate.id, editedText: "changed\n")
        )
        XCTAssertTrue(messagePlan.changes.isEmpty)
        XCTAssertTrue(messagePlan.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })

        let scriptChildPlan = NDSDataMutationPlanner.plan(
            catalog: catalog,
            draft: NDSDataEditDraft(recordID: scriptChild.id, editedText: "changed\n")
        )
        XCTAssertTrue(scriptChildPlan.changes.isEmpty)
        XCTAssertTrue(scriptChildPlan.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })
    }

    func testPokeBlackCatalogSurfacesGenVMessageBankInventoryFacts() throws {
        let root = try makeRoot(name: "pokeblack", configure: makeBlackFixture)

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let messageBankRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/msgdata" })
        XCTAssertEqual(messageBankRoot.id, "text:files/msgdata")
        XCTAssertEqual(messageBankRoot.domain, .text)
        XCTAssertEqual(messageBankRoot.format, .directory)
        XCTAssertEqual(messageBankRoot.recordCount, 6)
        XCTAssertNil(messageBankRoot.textBankPreview)
        XCTAssertEqual(factValue("Gen V Source Role", in: messageBankRoot), "messageBankInventory")
        XCTAssertEqual(factValue("Gen V Readiness", in: messageBankRoot), "previewOnly")
        XCTAssertEqual(factValue("Gen V Reference Posture", in: messageBankRoot), "cleanRoomReferenceOnly")
        XCTAssertTrue(factValue("Gen V Action State", in: messageBankRoot)?.contains("source inventory stays preview-only") == true)
        XCTAssertEqual(factValue("Gen V Message Candidate Count", in: messageBankRoot), "6")
        XCTAssertEqual(factValue("Gen V Message Candidate Extensions", in: messageBankRoot), "bin, dat, gmm, msg, str, txt")
        XCTAssertEqual(factValue("Gen V Message Candidate Basis", in: messageBankRoot), "pathExtensionOnly")
        XCTAssertEqual(factValue("Gen V Message Candidate Posture", in: messageBankRoot), "previewOnlyFilenameFacts")
        XCTAssertEqual(messageBankRoot.readiness?.status, .partial)
        XCTAssertTrue(messageBankRoot.readiness?.detail.contains("message-bank inventory") == true)
        XCTAssertNil(factValue("Migration Status", in: messageBankRoot))
        XCTAssertNil(factValue("Text Bank Preview", in: messageBankRoot))

        let messageBankChild = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/msgdata/story/message_bank.txt" })
        XCTAssertEqual(messageBankChild.domain, .resources)
        XCTAssertEqual(factValue("Gen V Source Role", in: messageBankChild), "messageBankMetadata")
        XCTAssertEqual(factValue("Gen V Message Candidate Kind", in: messageBankChild), "sourceTextCandidate")
        XCTAssertEqual(factValue("Gen V Message Candidate Basis", in: messageBankChild), "pathExtensionOnly")
        XCTAssertEqual(factValue("Gen V Message Candidate Posture", in: messageBankChild), "previewOnlyFilenameFacts")
        XCTAssertEqual(factValue("Gen V Message Decoded Preview", in: messageBankChild), "noDecodedPreview")
        XCTAssertEqual(factValue("Gen V Message Candidate Bytes", in: messageBankChild), "14")
        XCTAssertEqual(factValue("Gen V Message Candidate Lines", in: messageBankChild), "1")
        XCTAssertNil(factValue("Gen V Message Numeric Bank Hint", in: messageBankChild))
        XCTAssertNil(messageBankChild.textBankPreview)
        XCTAssertNil(factValue("Text Bank Preview", in: messageBankChild))
        XCTAssertNil(factValue("Migration Status", in: messageBankChild))

        let binaryMessageBankChild = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/msgdata/msg/0001.bin" })
        XCTAssertEqual(factValue("Gen V Source Role", in: binaryMessageBankChild), "messageBankMetadata")
        XCTAssertEqual(factValue("Gen V Message Candidate Kind", in: binaryMessageBankChild), "numberedBinaryBankCandidate")
        XCTAssertEqual(factValue("Gen V Message Decoded Preview", in: binaryMessageBankChild), "noDecodedPreview")
        XCTAssertEqual(factValue("Gen V Message Candidate Bytes", in: binaryMessageBankChild), "4")
        XCTAssertEqual(factValue("Gen V Message Numeric Bank Hint", in: binaryMessageBankChild), "0001")
        XCTAssertNil(factValue("Gen V Message Candidate Lines", in: binaryMessageBankChild))
        XCTAssertNil(binaryMessageBankChild.textBankPreview)
        XCTAssertNil(factValue("Text Bank Preview", in: binaryMessageBankChild))
        XCTAssertNil(factValue("Migration Status", in: binaryMessageBankChild))

        let gmmMessageBankChild = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/msgdata/battle/trainer_messages.gmm" })
        XCTAssertEqual(factValue("Gen V Source Role", in: gmmMessageBankChild), "messageBankMetadata")
        XCTAssertEqual(factValue("Gen V Message Candidate Kind", in: gmmMessageBankChild), "sourceTextCandidate")
        XCTAssertEqual(factValue("Gen V Message Decoded Preview", in: gmmMessageBankChild), "noDecodedPreview")
        XCTAssertEqual(factValue("Gen V Message Candidate Bytes", in: gmmMessageBankChild), "26")
        XCTAssertEqual(factValue("Gen V Message Candidate Lines", in: gmmMessageBankChild), "1")
        XCTAssertNil(gmmMessageBankChild.textBankPreview)
        XCTAssertNil(factValue("Text Bank Preview", in: gmmMessageBankChild))
        XCTAssertNil(factValue("Migration Status", in: gmmMessageBankChild))

        let strMessageBankChild = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/msgdata/system/help.str" })
        XCTAssertEqual(factValue("Gen V Source Role", in: strMessageBankChild), "messageBankMetadata")
        XCTAssertEqual(factValue("Gen V Message Candidate Kind", in: strMessageBankChild), "sourceTextCandidate")
        XCTAssertEqual(factValue("Gen V Message Decoded Preview", in: strMessageBankChild), "noDecodedPreview")
        XCTAssertEqual(factValue("Gen V Message Candidate Bytes", in: strMessageBankChild), "11")
        XCTAssertEqual(factValue("Gen V Message Candidate Lines", in: strMessageBankChild), "2")
        XCTAssertNil(factValue("Gen V Message Numeric Bank Hint", in: strMessageBankChild))
        XCTAssertNil(strMessageBankChild.textBankPreview)
        XCTAssertNil(factValue("Text Bank Preview", in: strMessageBankChild))
        XCTAssertNil(factValue("Migration Status", in: strMessageBankChild))

        let msgMessageBankChild = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/msgdata/msg/msg_0099.msg" })
        XCTAssertEqual(factValue("Gen V Source Role", in: msgMessageBankChild), "messageBankMetadata")
        XCTAssertEqual(factValue("Gen V Message Candidate Kind", in: msgMessageBankChild), "numberedBinaryBankCandidate")
        XCTAssertEqual(factValue("Gen V Message Decoded Preview", in: msgMessageBankChild), "noDecodedPreview")
        XCTAssertEqual(factValue("Gen V Message Candidate Bytes", in: msgMessageBankChild), "3")
        XCTAssertEqual(factValue("Gen V Message Numeric Bank Hint", in: msgMessageBankChild), "0099")
        XCTAssertNil(factValue("Gen V Message Candidate Lines", in: msgMessageBankChild))
        XCTAssertNil(msgMessageBankChild.textBankPreview)
        XCTAssertNil(factValue("Text Bank Preview", in: msgMessageBankChild))
        XCTAssertNil(factValue("Migration Status", in: msgMessageBankChild))

        let datMessageBankChild = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/msgdata/system/msg_0002.dat" })
        XCTAssertEqual(factValue("Gen V Source Role", in: datMessageBankChild), "messageBankMetadata")
        XCTAssertEqual(factValue("Gen V Message Candidate Kind", in: datMessageBankChild), "numberedBinaryBankCandidate")
        XCTAssertEqual(factValue("Gen V Message Decoded Preview", in: datMessageBankChild), "noDecodedPreview")
        XCTAssertEqual(factValue("Gen V Message Candidate Bytes", in: datMessageBankChild), "4")
        XCTAssertEqual(factValue("Gen V Message Numeric Bank Hint", in: datMessageBankChild), "0002")
        XCTAssertNil(factValue("Gen V Message Candidate Lines", in: datMessageBankChild))
        XCTAssertNil(datMessageBankChild.textBankPreview)
        XCTAssertNil(factValue("Text Bank Preview", in: datMessageBankChild))
        XCTAssertNil(factValue("Migration Status", in: datMessageBankChild))

        let resourceIndex = GenIIIResourceRegistry.resourceIndex(path: root.path)
        let messageBankResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data text" && $0.path == "files/msgdata" })
        XCTAssertEqual(messageBankResourceItem.kind, "directory")
        XCTAssertTrue(messageBankResourceItem.facts.contains { $0.label == "Gen V Source Role" && $0.value == "messageBankInventory" })
        XCTAssertTrue(messageBankResourceItem.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertTrue(messageBankResourceItem.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        XCTAssertTrue(messageBankResourceItem.facts.contains { $0.label == "Gen V Message Candidate Count" && $0.value == "6" })
        XCTAssertTrue(messageBankResourceItem.facts.contains { $0.label == "Gen V Message Candidate Extensions" && $0.value == "bin, dat, gmm, msg, str, txt" })
        XCTAssertFalse(messageBankResourceItem.facts.contains { $0.label == "Migration Status" })
        XCTAssertFalse(messageBankResourceItem.facts.contains { $0.label == "Text Bank Preview" })
        let messageBankResourceChild = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "files/msgdata/msg/0001.bin" })
        XCTAssertTrue(messageBankResourceChild.facts.contains { $0.label == "Gen V Source Role" && $0.value == "messageBankMetadata" })
        XCTAssertTrue(messageBankResourceChild.facts.contains { $0.label == "Gen V Message Candidate Kind" && $0.value == "numberedBinaryBankCandidate" })
        XCTAssertTrue(messageBankResourceChild.facts.contains { $0.label == "Gen V Message Decoded Preview" && $0.value == "noDecodedPreview" })
        XCTAssertTrue(messageBankResourceChild.facts.contains { $0.label == "Gen V Message Candidate Bytes" && $0.value == "4" })
        XCTAssertTrue(messageBankResourceChild.facts.contains { $0.label == "Gen V Message Numeric Bank Hint" && $0.value == "0001" })
        XCTAssertFalse(messageBankResourceChild.facts.contains { $0.label == "Gen V Message Candidate Lines" })
        XCTAssertFalse(messageBankResourceChild.facts.contains { $0.label == "Text Bank Preview" })
        XCTAssertFalse(messageBankResourceChild.facts.contains { $0.label == "Migration Status" })

        let textMessageBankResourceChild = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "files/msgdata/system/help.str" })
        XCTAssertTrue(textMessageBankResourceChild.facts.contains { $0.label == "Gen V Message Decoded Preview" && $0.value == "noDecodedPreview" })
        XCTAssertTrue(textMessageBankResourceChild.facts.contains { $0.label == "Gen V Message Candidate Bytes" && $0.value == "11" })
        XCTAssertTrue(textMessageBankResourceChild.facts.contains { $0.label == "Gen V Message Candidate Lines" && $0.value == "2" })
        XCTAssertFalse(textMessageBankResourceChild.facts.contains { $0.label == "Gen V Message Numeric Bank Hint" })
        XCTAssertFalse(textMessageBankResourceChild.facts.contains { $0.label == "Text Bank Preview" })
        XCTAssertFalse(textMessageBankResourceChild.facts.contains { $0.label == "Migration Status" })

        let msgMessageBankResourceChild = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "files/msgdata/msg/msg_0099.msg" })
        XCTAssertTrue(msgMessageBankResourceChild.facts.contains { $0.label == "Gen V Message Decoded Preview" && $0.value == "noDecodedPreview" })
        XCTAssertTrue(msgMessageBankResourceChild.facts.contains { $0.label == "Gen V Message Candidate Bytes" && $0.value == "3" })
        XCTAssertTrue(msgMessageBankResourceChild.facts.contains { $0.label == "Gen V Message Numeric Bank Hint" && $0.value == "0099" })
        XCTAssertFalse(msgMessageBankResourceChild.facts.contains { $0.label == "Gen V Message Candidate Lines" })
        XCTAssertFalse(msgMessageBankResourceChild.facts.contains { $0.label == "Text Bank Preview" })
        XCTAssertFalse(msgMessageBankResourceChild.facts.contains { $0.label == "Migration Status" })

        let datMessageBankResourceChild = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "files/msgdata/system/msg_0002.dat" })
        XCTAssertTrue(datMessageBankResourceChild.facts.contains { $0.label == "Gen V Message Decoded Preview" && $0.value == "noDecodedPreview" })
        XCTAssertTrue(datMessageBankResourceChild.facts.contains { $0.label == "Gen V Message Candidate Bytes" && $0.value == "4" })
        XCTAssertTrue(datMessageBankResourceChild.facts.contains { $0.label == "Gen V Message Numeric Bank Hint" && $0.value == "0002" })
        XCTAssertFalse(datMessageBankResourceChild.facts.contains { $0.label == "Gen V Message Candidate Lines" })
        XCTAssertFalse(datMessageBankResourceChild.facts.contains { $0.label == "Text Bank Preview" })
        XCTAssertFalse(datMessageBankResourceChild.facts.contains { $0.label == "Migration Status" })

        let plan = NDSDataMutationPlanner.plan(
            catalog: catalog,
            draft: NDSDataEditDraft(recordID: messageBankRoot.id, editedText: "changed\n")
        )
        XCTAssertTrue(plan.changes.isEmpty)
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })
    }

    func testPokeBlackCatalogSurfacesGenVOverlayAndDisassemblyConfigInventoryFacts() throws {
        let root = try makeRoot(name: "pokeblack", configure: makeBlackFixture)

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let overlayRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "overlays" })
        XCTAssertEqual(overlayRoot.id, "scripts:overlays")
        XCTAssertEqual(overlayRoot.domain, .scripts)
        XCTAssertEqual(overlayRoot.format, .directory)
        XCTAssertEqual(overlayRoot.recordCount, 2)
        XCTAssertEqual(overlayRoot.byteCount, UInt64(10))
        XCTAssertEqual(factValue("Gen V Overlay Members", in: overlayRoot), "2")
        XCTAssertEqual(factValue("Gen V Overlay Bytes", in: overlayRoot), "10")
        XCTAssertTrue(factValue("Gen V Overlay Sample Paths", in: overlayRoot)?.contains("overlays/overlay_93/source.s") == true)
        XCTAssertTrue(factValue("Gen V Overlay Sample Paths", in: overlayRoot)?.contains("overlays/overlay_94/source.s") == true)
        XCTAssertEqual(factValue("Gen V Source Role", in: overlayRoot), "overlayInventory")
        XCTAssertEqual(factValue("Gen V Readiness", in: overlayRoot), "previewOnly")
        XCTAssertEqual(factValue("Gen V Reference Posture", in: overlayRoot), "cleanRoomReferenceOnly")
        XCTAssertTrue(factValue("Gen V Action State", in: overlayRoot)?.contains("source inventory stays preview-only") == true)
        XCTAssertEqual(overlayRoot.readiness?.status, .partial)
        XCTAssertTrue(overlayRoot.readiness?.detail.contains("overlays root") == true)
        XCTAssertNil(factValue("Migration Status", in: overlayRoot))

        let overlayChild = try XCTUnwrap(catalog.records.first { $0.relativePath == "overlays/overlay_93/source.s" })
        XCTAssertEqual(factValue("Gen V Source Role", in: overlayChild), "overlayRouting")

        let configRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "ndsdisasm_config" })
        XCTAssertEqual(configRoot.id, "resources:ndsdisasm_config")
        XCTAssertEqual(configRoot.domain, .resources)
        XCTAssertEqual(configRoot.format, .directory)
        XCTAssertEqual(configRoot.recordCount, 2)
        XCTAssertEqual(configRoot.byteCount, UInt64(10))
        XCTAssertEqual(factValue("Gen V Disassembly Config Members", in: configRoot), "2")
        XCTAssertEqual(factValue("Gen V Disassembly Config Bytes", in: configRoot), "10")
        XCTAssertTrue(factValue("Gen V Disassembly Config Sample Paths", in: configRoot)?.contains("ndsdisasm_config/ARM9.cfg") == true)
        XCTAssertTrue(factValue("Gen V Disassembly Config Sample Paths", in: configRoot)?.contains("ndsdisasm_config/overlays/overlay_94.cfg") == true)
        XCTAssertEqual(factValue("Gen V Source Role", in: configRoot), "disassemblyConfigInventory")
        XCTAssertEqual(factValue("Gen V Readiness", in: configRoot), "previewOnly")
        XCTAssertEqual(factValue("Gen V Reference Posture", in: configRoot), "cleanRoomReferenceOnly")
        XCTAssertTrue(factValue("Gen V Action State", in: configRoot)?.contains("source inventory stays preview-only") == true)
        XCTAssertEqual(configRoot.readiness?.status, .partial)
        XCTAssertTrue(configRoot.readiness?.detail.contains("ndsdisasm_config root") == true)
        XCTAssertNil(factValue("Migration Status", in: configRoot))

        let configChild = try XCTUnwrap(catalog.records.first { $0.relativePath == "ndsdisasm_config/ARM9.cfg" })
        XCTAssertEqual(factValue("Gen V Source Role", in: configChild), "disassemblyConfig")

        let resourceIndex = GenIIIResourceRegistry.resourceIndex(path: root.path)
        let overlayResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data scripts" && $0.path == "overlays" })
        XCTAssertEqual(overlayResourceItem.kind, "directory")
        XCTAssertEqual(overlayResourceItem.size, UInt64(10))
        XCTAssertTrue(overlayResourceItem.facts.contains { $0.label == "Gen V Source Role" && $0.value == "overlayInventory" })
        XCTAssertTrue(overlayResourceItem.facts.contains { $0.label == "Gen V Overlay Members" && $0.value == "2" })
        XCTAssertTrue(overlayResourceItem.facts.contains { $0.label == "Gen V Overlay Bytes" && $0.value == "10" })
        XCTAssertTrue(overlayResourceItem.facts.contains { $0.label == "Gen V Overlay Sample Paths" && $0.value.contains("overlays/overlay_93/source.s") })
        XCTAssertTrue(overlayResourceItem.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertTrue(overlayResourceItem.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        XCTAssertFalse(overlayResourceItem.facts.contains { $0.label == "Migration Status" })

        let configResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "ndsdisasm_config" })
        XCTAssertEqual(configResourceItem.kind, "directory")
        XCTAssertEqual(configResourceItem.size, UInt64(10))
        XCTAssertTrue(configResourceItem.facts.contains { $0.label == "Gen V Source Role" && $0.value == "disassemblyConfigInventory" })
        XCTAssertTrue(configResourceItem.facts.contains { $0.label == "Gen V Disassembly Config Members" && $0.value == "2" })
        XCTAssertTrue(configResourceItem.facts.contains { $0.label == "Gen V Disassembly Config Bytes" && $0.value == "10" })
        XCTAssertTrue(configResourceItem.facts.contains { $0.label == "Gen V Disassembly Config Sample Paths" && $0.value.contains("ndsdisasm_config/ARM9.cfg") })
        XCTAssertTrue(configResourceItem.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertTrue(configResourceItem.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        XCTAssertFalse(configResourceItem.facts.contains { $0.label == "Migration Status" })
    }

    func testPokeBlackCatalogSurfacesGenVSoundAndContainerFacts() throws {
        let root = try makeRoot(name: "pokeblack", configure: makeBlackFixture)
        try write(Data("SDAT".utf8) + Data(repeating: 0, count: 12), to: root.appendingPathComponent("files/sound/bgm/main.sdat"))
        try write(makeTestNARC(), to: root.appendingPathComponent("files/sound/bgm/sound_bank.narc"))
        try write(makeTestNARC(), to: root.appendingPathComponent("files/system/container.narc"))
        try write(makeTestNARC(), to: root.appendingPathComponent("files/a/0/0/0/child.narc"))

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let nestedSDAT = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/sound/bgm/main.sdat" && $0.domain == .audio })
        XCTAssertEqual(nestedSDAT.format, .binary)
        XCTAssertEqual(factValue("Audio Preview", in: nestedSDAT), "ready")
        XCTAssertEqual(factValue("Audio Format", in: nestedSDAT), "nitroSoundArchive")
        XCTAssertEqual(factValue("Gen V Source Role", in: nestedSDAT), "soundArchiveMetadata")
        XCTAssertEqual(nestedSDAT.readiness?.status, .partial)
        XCTAssertTrue(nestedSDAT.readiness?.detail.contains("SDAT") == true)
        XCTAssertTrue(nestedSDAT.readiness?.blockedActions.contains("raw source writer") == true)
        XCTAssertTrue(nestedSDAT.readiness?.blockedActions.contains("NARC pack") == true)

        let soundNARC = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/sound/bgm/sound_bank.narc" && $0.domain == .audio })
        XCTAssertEqual(soundNARC.format, .narc)
        XCTAssertEqual(soundNARC.role, .binaryContainer)
        XCTAssertEqual(soundNARC.containerSummary?.kind, .narc)
        XCTAssertEqual(soundNARC.containerSummary?.memberCount, 2)
        XCTAssertEqual(factValue("Gen V Source Role", in: soundNARC), "soundContainerRoute")
        XCTAssertEqual(factValue("Gen V Readiness", in: soundNARC), "previewOnly")
        XCTAssertEqual(soundNARC.readiness?.status, .blocked)
        XCTAssertTrue(soundNARC.readiness?.blockedActions.contains("NARC pack") == true)
        XCTAssertTrue(factValue("Gen V Blocked Actions", in: soundNARC)?.contains("mutation apply") == true)
        XCTAssertTrue(factValue("Gen V Action State", in: soundNARC)?.contains("source inventory stays preview-only") == true)

        let boundedContainer = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/system/container.narc" && $0.domain == .resources })
        XCTAssertEqual(boundedContainer.containerSummary?.memberCount, 2)
        XCTAssertEqual(factValue("Gen V Source Role", in: boundedContainer), "boundedContainerSummary")
        XCTAssertEqual(factValue("Members", in: boundedContainer), "2")
        XCTAssertEqual(factValue("Gen V Readiness", in: boundedContainer), "previewOnly")
        XCTAssertEqual(boundedContainer.readiness?.status, .blocked)

        let archiveGroupRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/a" })
        XCTAssertEqual(factValue("Gen V Source Role", in: archiveGroupRoot), "nitroArchiveGroupInventory")
        let archiveGroupChild = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/a/0/0/0/resource.bin" })
        XCTAssertEqual(factValue("Gen V Source Role", in: archiveGroupChild), "nitroArchiveGroup")
        let archiveGroupNARCChild = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/a/0/0/0/child.narc" })
        XCTAssertEqual(factValue("Gen V Source Role", in: archiveGroupNARCChild), "nitroArchiveGroup")

        let resourceIndex = GenIIIResourceRegistry.resourceIndex(path: root.path)
        let audioItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data audio" && $0.path == "files/sound/bgm/main.sdat" })
        XCTAssertTrue(audioItem.facts.contains { $0.label == "Gen V Source Role" && $0.value == "soundArchiveMetadata" })
        XCTAssertTrue(audioItem.facts.contains { $0.label == "Audio Preview" && $0.value == "ready" })
        let soundNARCItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data audio" && $0.path == "files/sound/bgm/sound_bank.narc" })
        XCTAssertTrue(soundNARCItem.facts.contains { $0.label == "Gen V Source Role" && $0.value == "soundContainerRoute" })
        XCTAssertTrue(soundNARCItem.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        let boundedItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "files/system/container.narc" })
        XCTAssertTrue(boundedItem.facts.contains { $0.label == "Gen V Source Role" && $0.value == "boundedContainerSummary" })
        XCTAssertTrue(boundedItem.facts.contains { $0.label == "Members" && $0.value == "2" })
    }

    func testPokeBlackCatalogUsesWhiteMarkersWhenSourceShapeExists() throws {
        let root = try makeRoot(name: "pokeblack", configure: makeBlackFixture)
        try write("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee  pokewhite.nds\n", to: root.appendingPathComponent("white.us/rom.sha1"))

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let whiteTitle = "Pokemon - White Version (USA, Europe) (NDSi Enhanced).nds"
        let whiteMarker = try XCTUnwrap(catalog.records.first { $0.relativePath == "white.us/rom.sha1" })
        XCTAssertEqual(whiteMarker.role, .sourceTree)
        XCTAssertTrue(whiteMarker.exists)
        XCTAssertEqual(factValue("Gen V Readiness", in: whiteMarker), "previewOnly")
        XCTAssertEqual(factValue("Gen V Source Role", in: whiteMarker), "checksumExpectation")
        XCTAssertEqual(factValue("Gen V Title", in: whiteMarker), whiteTitle)
        XCTAssertEqual(factValue("Gen V Variant ID", in: whiteMarker), "white.us")
        XCTAssertEqual(factValue("Gen V Family", in: whiteMarker), "blackWhite")
        XCTAssertEqual(factValue("Gen V Source Name", in: whiteMarker), "pokeblack")
        XCTAssertEqual(factValue("Gen V Source Marker", in: whiteMarker), "white.us/rom.sha1")
        XCTAssertEqual(factValue("Gen V Variant State", in: whiteMarker), "sourceMarkerPresent")
        XCTAssertEqual(factValue("Gen V Reference Posture", in: whiteMarker), "cleanRoomReferenceOnly")
        XCTAssertTrue(whiteMarker.readiness?.blockedActions.contains("ROM export") == true)
        XCTAssertTrue(whiteMarker.diagnostics.contains { $0.code == "NDS_GEN_V_READINESS_PREVIEW_ONLY" })
        XCTAssertFalse(catalog.records.contains { $0.relativePath == "unavailable-titles/\(whiteTitle)" })

        let unavailableRows = catalog.records.filter { $0.role == .metadataUnavailable }
        XCTAssertEqual(unavailableRows.count, 2)
        XCTAssertTrue(unavailableRows.allSatisfy { factValue("Gen V Family", in: $0) == "black2White2" })
        XCTAssertTrue(unavailableRows.allSatisfy { factValue("Gen V Variant State", in: $0) == "unavailable" })
        XCTAssertTrue(unavailableRows.allSatisfy { $0.readiness?.status == .blocked })

        let resourceIndex = GenIIIResourceRegistry.resourceIndex(path: root.path)
        let whiteResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "white.us/rom.sha1" })
        XCTAssertTrue(whiteResourceItem.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertTrue(whiteResourceItem.facts.contains { $0.label == "Gen V Variant ID" && $0.value == "white.us" })
        XCTAssertTrue(whiteResourceItem.facts.contains { $0.label == "Gen V Variant State" && $0.value == "sourceMarkerPresent" })
    }

    func testPokeBlackCatalogSurfacesBlack2White2InventoryWhenSourceShapeExists() throws {
        let root = try makeRoot(name: "pokeblack", configure: makeBlackFixture)
        try write("\n", to: root.appendingPathComponent("white.us/rom.sha1"))
        try write("not-a-sha1\n", to: root.appendingPathComponent("black2.us/rom.sha1"))
        try write("3333333333333333333333333333333333333333  pokewhite2.nds\n", to: root.appendingPathComponent("white2.us/rom.sha1"))
        try write("Black 2 source note\n", to: root.appendingPathComponent("black2.us/source_notes.txt"))

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let black2Title = "Pokemon - Black Version 2 (USA, Europe) (NDSi Enhanced).nds"
        let white2Title = "Pokemon - White Version 2 (USA, Europe) (NDSi Enhanced).nds"
        let makefile = try XCTUnwrap(catalog.records.first { $0.relativePath == "Makefile" })
        XCTAssertEqual(
            factValue("Gen V Variant Hash Presence", in: makefile),
            "black.us/rom.sha1=present, white.us/rom.sha1=present, black2.us/rom.sha1=present, white2.us/rom.sha1=present"
        )
        let blackChecksum = try XCTUnwrap(catalog.records.first { $0.relativePath == "black.us/rom.sha1" })
        XCTAssertEqual(factValue("Gen V SHA1 Text State", in: blackChecksum), "valid")
        XCTAssertEqual(factValue("Gen V SHA1 Text Digest", in: blackChecksum), "ffffffffffffffffffffffffffffffffffffffff")

        let whiteChecksum = try XCTUnwrap(catalog.records.first { $0.relativePath == "white.us/rom.sha1" })
        XCTAssertEqual(factValue("Gen V SHA1 Text State", in: whiteChecksum), "empty")
        XCTAssertNil(factValue("Gen V SHA1 Text Digest", in: whiteChecksum))

        let black2Checksum = try XCTUnwrap(catalog.records.first { $0.relativePath == "black2.us/rom.sha1" })
        XCTAssertEqual(black2Checksum.role, .sourceTree)
        XCTAssertEqual(factValue("Gen V Readiness", in: black2Checksum), "previewOnly")
        XCTAssertEqual(factValue("Gen V Source Role", in: black2Checksum), "checksumExpectation")
        XCTAssertEqual(factValue("Gen V Title", in: black2Checksum), black2Title)
        XCTAssertEqual(factValue("Gen V Variant ID", in: black2Checksum), "black2.us")
        XCTAssertEqual(factValue("Gen V Family", in: black2Checksum), "black2White2")
        XCTAssertEqual(factValue("Gen V Source Name", in: black2Checksum), "localBlack2White2SourceInventory")
        XCTAssertEqual(factValue("Gen V Source Marker", in: black2Checksum), "black2.us/rom.sha1")
        XCTAssertEqual(factValue("Gen V Variant State", in: black2Checksum), "sourceMarkerPresent")
        XCTAssertTrue(factValue("Gen V Blocked Actions", in: black2Checksum)?.contains("binary write") == true)
        XCTAssertTrue(factValue("Gen V Action State", in: black2Checksum)?.contains("editing/apply") == true)
        XCTAssertEqual(factValue("Gen V SHA1 Text State", in: black2Checksum), "invalid")
        XCTAssertNil(factValue("Gen V SHA1 Text Digest", in: black2Checksum))
        XCTAssertEqual(black2Checksum.readiness?.status, .partial)
        XCTAssertTrue(black2Checksum.diagnostics.contains { $0.code == "NDS_GEN_V_READINESS_PREVIEW_ONLY" })
        XCTAssertTrue(black2Checksum.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })

        let black2Marker = try XCTUnwrap(catalog.records.first { $0.relativePath == "black2.us" })
        XCTAssertEqual(black2Marker.format, .directory)
        XCTAssertEqual(black2Marker.recordCount, 2)
        XCTAssertEqual(factValue("Gen V Source Role", in: black2Marker), "variantSourceInventory")
        XCTAssertEqual(factValue("Gen V Variant ID", in: black2Marker), "black2.us")
        XCTAssertEqual(factValue("Gen V Source Name", in: black2Marker), "localBlack2White2SourceInventory")
        XCTAssertNil(factValue("Migration Status", in: black2Marker))

        let black2Note = try XCTUnwrap(catalog.records.first { $0.relativePath == "black2.us/source_notes.txt" })
        XCTAssertEqual(factValue("Gen V Source Role", in: black2Note), "sourceInventory")
        XCTAssertEqual(factValue("Gen V Title", in: black2Note), black2Title)
        XCTAssertEqual(factValue("Gen V Variant ID", in: black2Note), "black2.us")
        XCTAssertEqual(black2Note.readiness?.status, .partial)

        let white2Checksum = try XCTUnwrap(catalog.records.first { $0.relativePath == "white2.us/rom.sha1" })
        XCTAssertEqual(factValue("Gen V Title", in: white2Checksum), white2Title)
        XCTAssertEqual(factValue("Gen V Variant ID", in: white2Checksum), "white2.us")
        XCTAssertEqual(factValue("Gen V Family", in: white2Checksum), "black2White2")
        XCTAssertEqual(factValue("Gen V Source Role", in: white2Checksum), "checksumExpectation")
        XCTAssertEqual(factValue("Gen V Variant State", in: white2Checksum), "sourceMarkerPresent")
        XCTAssertEqual(factValue("Gen V SHA1 Text State", in: white2Checksum), "valid")
        XCTAssertEqual(factValue("Gen V SHA1 Text Digest", in: white2Checksum), "3333333333333333333333333333333333333333")
        XCTAssertFalse(catalog.records.contains { $0.relativePath == "unavailable-titles/\(black2Title)" })
        XCTAssertFalse(catalog.records.contains { $0.relativePath == "unavailable-titles/\(white2Title)" })

        let resourceIndex = GenIIIResourceRegistry.resourceIndex(path: root.path)
        let black2ResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "black2.us/source_notes.txt" })
        XCTAssertTrue(black2ResourceItem.facts.contains { $0.label == "Gen V Source Role" && $0.value == "sourceInventory" })
        XCTAssertTrue(black2ResourceItem.facts.contains { $0.label == "Gen V Blocked Actions" && $0.value.contains("NARC pack") })
        XCTAssertTrue(black2ResourceItem.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        let white2ResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "white2.us/rom.sha1" })
        XCTAssertTrue(white2ResourceItem.facts.contains { $0.label == "Gen V Variant ID" && $0.value == "white2.us" })
        XCTAssertTrue(white2ResourceItem.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertTrue(white2ResourceItem.facts.contains { $0.label == "Gen V SHA1 Text State" && $0.value == "valid" })
        XCTAssertTrue(white2ResourceItem.facts.contains { $0.label == "Gen V SHA1 Text Digest" && $0.value == "3333333333333333333333333333333333333333" })

        let blockedPlan = NDSDataMutationPlanner.plan(
            catalog: catalog,
            draft: NDSDataEditDraft(recordID: black2Note.id, editedText: "changed\n")
        )
        XCTAssertTrue(blockedPlan.changes.isEmpty)
        XCTAssertTrue(blockedPlan.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })
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

    func testNDSDataSemanticEditorPlansPlatinumSourceTextLineEditsOnly() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        var catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let textRecordID = "text:res/text/route201.txt"

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: textRecordID)
        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(snapshot.fields.map(\.key), ["lines.0.text", "lines.1.text"])
        XCTAssertEqual(snapshot.fields[0].label, "Line 1")
        XCTAssertEqual(snapshot.fields[0].value, "hello")
        XCTAssertEqual(snapshot.fields[0].valueKind, .string)
        XCTAssertEqual(snapshot.fields[1].label, "Line 2")
        XCTAssertEqual(snapshot.fields[1].value, "world")

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: textRecordID,
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "lines.0.text", value: "bonjour"),
                    NDSDataSemanticFieldEdit(key: "lines.1.text", value: "wide world")
                ]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(semanticPlan.textDraft.editedText, "bonjour\nwide world\n")
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("res/text/route201.txt"), encoding: .utf8),
            "bonjour\nwide world\n"
        )

        catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let multilinePlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: textRecordID,
                fieldEdits: [NDSDataSemanticFieldEdit(key: "lines.0.text", value: "bad\nline")]
            )
        )
        XCTAssertTrue(multilinePlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_VALUE_INVALID" })
        XCTAssertTrue(multilinePlan.editPlan.changes.isEmpty)
        XCTAssertFalse(multilinePlan.editPlan.validateApplyability().isApplyable)

        let missingLinePlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: textRecordID,
                fieldEdits: [NDSDataSemanticFieldEdit(key: "lines.2.text", value: "new line")]
            )
        )
        XCTAssertTrue(missingLinePlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FIELD_MISSING" })
        XCTAssertTrue(missingLinePlan.editPlan.changes.isEmpty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("res/text/route201.txt"), encoding: .utf8),
            "bonjour\nwide world\n"
        )

        let originalBMG = try Data(contentsOf: root.appendingPathComponent("res/text/battle.bmg"))
        let bmgSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "text:res/text/battle.bmg")
        XCTAssertFalse(bmgSnapshot.canEdit)
        XCTAssertTrue(bmgSnapshot.fields.isEmpty)
        XCTAssertTrue(bmgSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_TEXT_PATH_BLOCKED" })
        XCTAssertTrue(bmgSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
        let bmgPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "text:res/text/battle.bmg",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "lines.0.text", value: "blocked")]
            )
        )
        XCTAssertTrue(bmgPlan.editPlan.changes.isEmpty)
        XCTAssertEqual(try Data(contentsOf: root.appendingPathComponent("res/text/battle.bmg")), originalBMG)

        let generatedPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "resources:generated/species.txt",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "lines.0.text", value: "SPECIES_MEW")]
            )
        )
        XCTAssertTrue(generatedPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_ROLE_BLOCKED" })
        XCTAssertTrue(generatedPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DOMAIN_BLOCKED" })
        XCTAssertTrue(generatedPlan.editPlan.changes.isEmpty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("generated/species.txt"), encoding: .utf8),
            "SPECIES_ABRA\n"
        )

        let containerSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "personal:res/prebuilt/poketool/personal/personal.narc")
        XCTAssertFalse(containerSnapshot.canEdit)
        XCTAssertTrue(containerSnapshot.fields.isEmpty)
        XCTAssertTrue(containerSnapshot.diagnostics.contains { $0.code == "NDS_DATA_EDIT_CONTAINER_BLOCKED" })
        XCTAssertTrue(containerSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let referenceRoot = try makeRoot(name: "references/pokeplatinum", configure: makePlatinumFixture)
        let referenceCatalog = try NDSDataCatalogBuilder.build(path: referenceRoot.path)
        let referencePlan = NDSDataSemanticEditor.plan(
            catalog: referenceCatalog,
            draft: NDSDataSemanticEditDraft(
                recordID: textRecordID,
                fieldEdits: [NDSDataSemanticFieldEdit(key: "lines.0.text", value: "reference edit")]
            )
        )
        XCTAssertTrue(referencePlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_REFERENCE_BLOCKED" })
        XCTAssertTrue(referencePlan.editPlan.changes.isEmpty)
        XCTAssertEqual(
            try String(contentsOf: referenceRoot.appendingPathComponent("res/text/route201.txt"), encoding: .utf8),
            "hello\nworld\n"
        )
    }

    func testNDSDataTextLineOperationPlanner() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        try write("{\"message\":\"hello\"}\n", to: root.appendingPathComponent("res/text/story.json"))
        var catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let textRecordID = "text:res/text/route201.txt"

        let plan = NDSDataTextLineOperationPlanner.plan(
            catalog: catalog,
            draft: NDSDataTextLineOperationDraft(
                recordID: textRecordID,
                operations: [
                    .insert(index: 1, text: "middle"),
                    .delete(index: 0),
                    .reorder(fromIndex: 1, toIndex: 0)
                ]
            )
        )

        XCTAssertEqual(plan.beforeLineCount, 2)
        XCTAssertEqual(plan.afterLineCount, 2)
        XCTAssertTrue(plan.diagnostics.allSatisfy { $0.severity != .error }, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(plan.editPlan.changes.count, 1)
        XCTAssertEqual(plan.editPlan.changes.first?.path, "res/text/route201.txt")
        XCTAssertTrue(plan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: plan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("res/text/route201.txt"), encoding: .utf8),
            "world\nmiddle\n"
        )

        catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let newlinePlan = NDSDataTextLineOperationPlanner.plan(
            catalog: catalog,
            draft: NDSDataTextLineOperationDraft(
                recordID: textRecordID,
                operations: [.insert(index: 1, text: "bad\nline")]
            )
        )
        XCTAssertTrue(newlinePlan.diagnostics.contains { $0.code == "NDS_DATA_TEXT_LINES_NEWLINE_BLOCKED" })
        XCTAssertTrue(newlinePlan.editPlan.changes.isEmpty)
        XCTAssertFalse(newlinePlan.editPlan.validateApplyability().isApplyable)

        let missingLinePlan = NDSDataTextLineOperationPlanner.plan(
            catalog: catalog,
            draft: NDSDataTextLineOperationDraft(
                recordID: textRecordID,
                operations: [.delete(index: 4)]
            )
        )
        XCTAssertTrue(missingLinePlan.diagnostics.contains { $0.code == "NDS_DATA_TEXT_LINES_INDEX_OUT_OF_RANGE" })
        XCTAssertTrue(missingLinePlan.editPlan.changes.isEmpty)

        let badReorderPlan = NDSDataTextLineOperationPlanner.plan(
            catalog: catalog,
            draft: NDSDataTextLineOperationDraft(
                recordID: textRecordID,
                operations: [.reorder(fromIndex: 0, toIndex: 3)]
            )
        )
        XCTAssertTrue(badReorderPlan.diagnostics.contains { $0.code == "NDS_DATA_TEXT_LINES_INDEX_OUT_OF_RANGE" })
        XCTAssertTrue(badReorderPlan.editPlan.changes.isEmpty)

        let bmgPlan = NDSDataTextLineOperationPlanner.plan(
            catalog: catalog,
            draft: NDSDataTextLineOperationDraft(
                recordID: "text:res/text/battle.bmg",
                operations: [.insert(index: 0, text: "blocked")]
            )
        )
        XCTAssertTrue(bmgPlan.diagnostics.contains { $0.code == "NDS_DATA_TEXT_LINES_PATH_BLOCKED" })
        XCTAssertTrue(bmgPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_FORMAT_BLOCKED" })
        XCTAssertTrue(bmgPlan.editPlan.changes.isEmpty)

        let textJSONPlan = NDSDataTextLineOperationPlanner.plan(
            catalog: catalog,
            draft: NDSDataTextLineOperationDraft(
                recordID: "text:res/text/story.json",
                operations: [.insert(index: 0, text: "blocked")]
            )
        )
        XCTAssertTrue(textJSONPlan.diagnostics.contains { $0.code == "NDS_DATA_TEXT_LINES_PATH_BLOCKED" })
        XCTAssertTrue(textJSONPlan.editPlan.changes.isEmpty)

        let containerPlan = NDSDataTextLineOperationPlanner.plan(
            catalog: catalog,
            draft: NDSDataTextLineOperationDraft(
                recordID: "personal:res/prebuilt/poketool/personal/personal.narc",
                operations: [.insert(index: 0, text: "blocked")]
            )
        )
        XCTAssertTrue(containerPlan.diagnostics.contains { $0.code == "NDS_DATA_TEXT_LINES_PATH_BLOCKED" })
        XCTAssertTrue(containerPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_CONTAINER_BLOCKED" })
        XCTAssertTrue(containerPlan.editPlan.changes.isEmpty)

        let generatedPlan = NDSDataTextLineOperationPlanner.plan(
            catalog: catalog,
            draft: NDSDataTextLineOperationDraft(
                recordID: "resources:generated/species.txt",
                operations: [.insert(index: 0, text: "SPECIES_MEW")]
            )
        )
        XCTAssertTrue(generatedPlan.diagnostics.contains { $0.code == "NDS_DATA_TEXT_LINES_PATH_BLOCKED" })
        XCTAssertTrue(generatedPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_ROLE_BLOCKED" })
        XCTAssertTrue(generatedPlan.editPlan.changes.isEmpty)
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent("generated/species.txt"), encoding: .utf8),
            "SPECIES_ABRA\n"
        )

        let referenceRoot = try makeRoot(name: "references/pokeplatinum", configure: makePlatinumFixture)
        let referenceCatalog = try NDSDataCatalogBuilder.build(path: referenceRoot.path)
        let referencePlan = NDSDataTextLineOperationPlanner.plan(
            catalog: referenceCatalog,
            draft: NDSDataTextLineOperationDraft(
                recordID: textRecordID,
                operations: [.insert(index: 0, text: "reference edit")]
            )
        )
        XCTAssertTrue(referencePlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_REFERENCE_BLOCKED" })
        XCTAssertTrue(referencePlan.editPlan.changes.isEmpty)
        XCTAssertEqual(
            try String(contentsOf: referenceRoot.appendingPathComponent("res/text/route201.txt"), encoding: .utf8),
            "hello\nworld\n"
        )
    }

    func testNDSDataSemanticEditorPlansPlatinumTextJSONStringLeavesOnly() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let textPath = "res/text/story.json"
        try write(
            """
            {"message":"hello","messages":{"intro":"Welcome","count":2,"enabled":true,"nested":{"line":"Deep"},"choices":["Yes","No",{"label":"Maybe","value":3}]},"null_value":null}

            """,
            to: root.appendingPathComponent(textPath)
        )
        var catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let textRecordID = "text:\(textPath)"

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: textRecordID)
        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        let fields = Dictionary(uniqueKeysWithValues: snapshot.fields.map { ($0.key, $0) })
        XCTAssertEqual(fields["message"]?.value, "hello")
        XCTAssertEqual(fields["messages.intro"]?.value, "Welcome")
        XCTAssertEqual(fields["messages.nested.line"]?.value, "Deep")
        XCTAssertEqual(fields["messages.choices.0"]?.value, "Yes")
        XCTAssertEqual(fields["messages.choices.1"]?.value, "No")
        XCTAssertEqual(fields["messages.choices.2.label"]?.value, "Maybe")
        XCTAssertFalse(fields.keys.contains("messages.count"))
        XCTAssertFalse(fields.keys.contains("messages.enabled"))
        XCTAssertFalse(fields.keys.contains("messages"))
        XCTAssertFalse(fields.keys.contains("messages.choices.2.value"))
        XCTAssertFalse(fields.keys.contains("null_value"))

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: textRecordID,
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "message", value: "bonjour"),
                    NDSDataSemanticFieldEdit(key: "messages.intro", value: "Welcome back"),
                    NDSDataSemanticFieldEdit(key: "messages.choices.2.label", value: "Later")
                ]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains(#""message":"bonjour""#))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains(#""intro":"Welcome back""#))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains(#""label":"Later""#))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains(#""count":2"#))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains(#""enabled":true"#))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains(#""value":3"#))
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))
        let updated = try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8)
        XCTAssertTrue(updated.contains(#""message":"bonjour""#))
        XCTAssertTrue(updated.contains(#""intro":"Welcome back""#))
        XCTAssertTrue(updated.contains(#""label":"Later""#))
        XCTAssertTrue(updated.contains(#""count":2"#))

        catalog = try NDSDataCatalogBuilder.build(path: root.path)
        let multilinePlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: textRecordID,
                fieldEdits: [NDSDataSemanticFieldEdit(key: "messages.intro", value: "bad\nline")]
            )
        )
        XCTAssertTrue(multilinePlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_VALUE_INVALID" })
        XCTAssertTrue(multilinePlan.editPlan.changes.isEmpty)
        XCTAssertFalse(multilinePlan.editPlan.validateApplyability().isApplyable)

        let nonStringPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: textRecordID,
                fieldEdits: [NDSDataSemanticFieldEdit(key: "messages.count", value: "3")]
            )
        )
        XCTAssertTrue(nonStringPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FIELD_MISSING" })
        XCTAssertTrue(nonStringPlan.editPlan.changes.isEmpty)

        let objectPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: textRecordID,
                fieldEdits: [NDSDataSemanticFieldEdit(key: "messages", value: "new object")]
            )
        )
        XCTAssertTrue(objectPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FIELD_MISSING" })
        XCTAssertTrue(objectPlan.editPlan.changes.isEmpty)

        let missingPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: textRecordID,
                fieldEdits: [NDSDataSemanticFieldEdit(key: "messages.choices.3", value: "Insert")]
            )
        )
        XCTAssertTrue(missingPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FIELD_MISSING" })
        XCTAssertTrue(missingPlan.editPlan.changes.isEmpty)

        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(textPath), encoding: .utf8),
            updated
        )
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

        let resourcePath = "res/trainers/resources/youngster.json"
        try write("{\"cell_animation\":1}\n", to: root.appendingPathComponent(resourcePath))
        let refreshedCatalog = try NDSDataCatalogBuilder.build(path: root.path)
        let resourceSnapshot = NDSDataSemanticEditor.snapshot(catalog: refreshedCatalog, recordID: "trainers:\(resourcePath)")
        XCTAssertFalse(resourceSnapshot.canEdit)
        XCTAssertTrue(resourceSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_TRAINER_PATH_BLOCKED" })

        let blockedResourcePlan = NDSDataSemanticEditor.plan(
            catalog: refreshedCatalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "trainers:\(resourcePath)",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "cell_animation", value: "2")]
            )
        )
        XCTAssertTrue(blockedResourcePlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_TRAINER_PATH_BLOCKED" })
        XCTAssertTrue(blockedResourcePlan.editPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_TRAINER_PATH_BLOCKED" })
        XCTAssertEqual(blockedResourcePlan.editPlan.changes.count, 0)
        XCTAssertFalse(blockedResourcePlan.editPlan.validateApplyability().isApplyable)
    }

    func testNDSDataSemanticEditorPlansPlatinumTrainerClassJSONScalars() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let classPath = "res/trainers/classes/youngster.json"
        let nestedClassPath = "res/trainers/classes/sinnoh/ace.json"
        let resourcePath = "res/trainers/resources/youngster.json"
        let textPath = "res/trainers/classes/youngster.txt"
        try write(
            """
            {"cell_animation": 1, "label": "Youngster", "enabled": true, "palette": null, "frames": [{"id":1}], "metadata": {"kind":"class"}}

            """,
            to: root.appendingPathComponent(classPath)
        )
        try write("{\"cell_animation\":2}\n", to: root.appendingPathComponent(nestedClassPath))
        try write("{\"cell_animation\":3}\n", to: root.appendingPathComponent(resourcePath))
        try write("cell_animation=4\n", to: root.appendingPathComponent(textPath))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "trainers:\(classPath)")
        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(snapshot.fields.contains { $0.key == "cell_animation" && $0.value == "1" && $0.valueKind == .number })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "label" && $0.value == "Youngster" && $0.valueKind == .string })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "enabled" && $0.value == "true" && $0.valueKind == .bool })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "palette" && $0.value == "null" && $0.valueKind == .null })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "frames" })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "metadata" })

        let nestedPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "trainers:\(classPath)",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "frames.0.id", value: "2")]
            )
        )
        XCTAssertTrue(nestedPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertEqual(nestedPlan.editPlan.changes.count, 0)
        XCTAssertFalse(nestedPlan.editPlan.validateApplyability().isApplyable)

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "trainers:\(classPath)",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "cell_animation", value: "5"),
                    NDSDataSemanticFieldEdit(key: "label", value: "Youngster Prime"),
                    NDSDataSemanticFieldEdit(key: "enabled", value: "false")
                ]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"cell_animation\": 5"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"label\": \"Youngster Prime\""))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"enabled\": false"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"palette\": null"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"frames\": [{\"id\":1}]"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"metadata\": {\"kind\":\"class\"}"))
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(classPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"cell_animation\": 5"))
        XCTAssertTrue(updated.contains("\"label\": \"Youngster Prime\""))
        XCTAssertTrue(updated.contains("\"enabled\": false"))
        XCTAssertTrue(updated.contains("\"frames\": [{\"id\":1}]"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let nestedClassSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "trainers:\(nestedClassPath)")
        XCTAssertFalse(nestedClassSnapshot.canEdit)
        XCTAssertTrue(nestedClassSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_TRAINER_PATH_BLOCKED" })

        let resourceSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "trainers:\(resourcePath)")
        XCTAssertFalse(resourceSnapshot.canEdit)
        XCTAssertTrue(resourceSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_TRAINER_PATH_BLOCKED" })

        let textSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "trainers:\(textPath)")
        XCTAssertFalse(textSnapshot.canEdit)
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_TRAINER_PATH_BLOCKED" })
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
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

    func testNDSDataSemanticEditorPlansPlatinumMoveJSONScalars() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let movePath = "res/battle/moves/tackle.json"
        let nestedPath = "res/battle/moves/custom/tackle.json"
        let textPath = "res/battle/moves/tackle.txt"
        try write(
            """
            {"power": 40, "accuracy": 100, "contact": true, "flags": {"protect": true}, "contest": ["cool"]}

            """,
            to: root.appendingPathComponent(movePath)
        )
        try write("{\"power\": 60}\n", to: root.appendingPathComponent(nestedPath))
        try write("power=50\n", to: root.appendingPathComponent(textPath))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "moves:\(movePath)")
        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        let fields = Dictionary(uniqueKeysWithValues: snapshot.fields.map { ($0.key, $0) })
        XCTAssertEqual(fields["power"]?.value, "40")
        XCTAssertEqual(fields["power"]?.valueKind, .number)
        XCTAssertEqual(fields["accuracy"]?.value, "100")
        XCTAssertEqual(fields["contact"]?.value, "true")
        XCTAssertEqual(fields["contact"]?.valueKind, .bool)
        XCTAssertNil(fields["flags"])
        XCTAssertNil(fields["contest"])

        let nestedPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "moves:\(movePath)",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "flags.protect", value: "false")]
            )
        )
        XCTAssertTrue(nestedPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertTrue(nestedPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(nestedPlan.editPlan.validateApplyability().isApplyable)

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "moves:\(movePath)",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "power", value: "60"),
                    NDSDataSemanticFieldEdit(key: "accuracy", value: "95"),
                    NDSDataSemanticFieldEdit(key: "contact", value: "false")
                ]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"power\": 60"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"accuracy\": 95"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"contact\": false"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"flags\": {\"protect\": true}"))
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(movePath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"power\": 60"))
        XCTAssertTrue(updated.contains("\"accuracy\": 95"))
        XCTAssertTrue(updated.contains("\"contact\": false"))
        XCTAssertTrue(updated.contains("\"flags\": {\"protect\": true}"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let nestedPathSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "moves:\(nestedPath)")
        XCTAssertFalse(nestedPathSnapshot.canEdit)
        XCTAssertTrue(nestedPathSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MOVE_PATH_BLOCKED" })

        let textSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "moves:\(textPath)")
        XCTAssertFalse(textSnapshot.canEdit)
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MOVE_PATH_BLOCKED" })
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticEditorPlansPlatinumEncounterRateJSONScalars() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        try write(
            """
            {"land_rate": 30, "land_encounters": [{"level":2,"species":"SPECIES_STARLY"},{"level":3,"species":"SPECIES_BIDOOF"}], "swarms": ["SPECIES_DODUO","SPECIES_DODUO"], "rate_form0": 0, "map_category": {"map_type":"field","map_number":12}}

            """,
            to: root.appendingPathComponent("res/field/encounters/route201.json")
        )
        try write("{\"rate\": 15}\n", to: root.appendingPathComponent("res/field/encounters/nested/route202.json"))
        try write("rate=15\n", to: root.appendingPathComponent("res/field/encounters/route203.txt"))
        try write("[{\"level\":2,\"species\":\"SPECIES_BIDOOF\"}]\n", to: root.appendingPathComponent("res/field/encounters/array.json"))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "encounters:res/field/encounters/route201.json")
        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(snapshot.fields.contains { $0.key == "land_rate" && $0.value == "30" && $0.valueKind == .number })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "land_encounters.0.level" && $0.value == "2" && $0.valueKind == .number })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "land_encounters.0.species" && $0.value == "SPECIES_STARLY" && $0.valueKind == .string })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "swarms.0" && $0.value == "SPECIES_DODUO" && $0.valueKind == .string })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "rate_form0" && $0.value == "0" && $0.valueKind == .number })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "land_encounters" })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "map_category.map_type" })

        let nestedObjectPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "encounters:res/field/encounters/route201.json",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "map_category.map_type", value: "building")]
            )
        )
        XCTAssertTrue(nestedObjectPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertTrue(nestedObjectPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(nestedObjectPlan.editPlan.validateApplyability().isApplyable)

        let missingSlotPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "encounters:res/field/encounters/route201.json",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "land_encounters.99.level", value: "5")]
            )
        )
        XCTAssertTrue(missingSlotPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FIELD_MISSING" })
        XCTAssertTrue(missingSlotPlan.editPlan.changes.isEmpty)

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "encounters:res/field/encounters/route201.json",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "land_rate", value: "25"),
                    NDSDataSemanticFieldEdit(key: "land_encounters.0.level", value: "4"),
                    NDSDataSemanticFieldEdit(key: "land_encounters.0.species", value: "SPECIES_BIDOOF"),
                    NDSDataSemanticFieldEdit(key: "swarms.1", value: "SPECIES_NIDORAN_M")
                ]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"land_rate\": 25"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"land_encounters\": [{\"level\":4,\"species\":\"SPECIES_BIDOOF\"}"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"swarms\": [\"SPECIES_DODUO\",\"SPECIES_NIDORAN_M\"]"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"map_category\": {\"map_type\":\"field\",\"map_number\":12}"))
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("res/field/encounters/route201.json"), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"land_rate\": 25"))
        XCTAssertTrue(updated.contains("\"land_encounters\": [{\"level\":4,\"species\":\"SPECIES_BIDOOF\"}"))
        XCTAssertTrue(updated.contains("\"swarms\": [\"SPECIES_DODUO\",\"SPECIES_NIDORAN_M\"]"))
        XCTAssertTrue(updated.contains("\"map_category\": {\"map_type\":\"field\",\"map_number\":12}"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let arraySnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "encounters:res/field/encounters/array.json")
        XCTAssertFalse(arraySnapshot.canEdit)
        XCTAssertTrue(arraySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_JSON_OBJECT_REQUIRED" })

        let nestedPathSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "encounters:res/field/encounters/nested/route202.json")
        XCTAssertFalse(nestedPathSnapshot.canEdit)
        XCTAssertTrue(nestedPathSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_ENCOUNTER_PATH_BLOCKED" })

        let textSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "encounters:res/field/encounters/route203.txt")
        XCTAssertFalse(textSnapshot.canEdit)
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_ENCOUNTER_PATH_BLOCKED" })
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let heartGold = try makeRoot(name: "pokeheartgold", configure: makeHeartGoldFixture)
        let heartGoldCatalog = try NDSDataCatalogBuilder.build(path: heartGold.path)
        let heartGoldSnapshot = NDSDataSemanticEditor.snapshot(catalog: heartGoldCatalog, recordID: "encounters:files/fielddata/encountdata/gs_enc_data.json")
        XCTAssertFalse(heartGoldSnapshot.canEdit)
        XCTAssertTrue(heartGoldSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_JSON_OBJECT_REQUIRED" })

        let diamond = try makeRoot(name: "pokediamond", configure: makeDiamondFixture)
        let diamondCatalog = try NDSDataCatalogBuilder.build(path: diamond.path)
        let diamondSnapshot = NDSDataSemanticEditor.snapshot(catalog: diamondCatalog, recordID: "encounters:arm9/src/encounter.c")
        XCTAssertFalse(diamondSnapshot.canEdit)
        XCTAssertTrue(diamondSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(diamondSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_ENCOUNTER_PATH_BLOCKED" })
        XCTAssertTrue(diamondSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticEditorPlansPlatinumFieldEventJSONScalars() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let eventPath = "res/field/events/route201.json"
        let nestedPath = "res/field/events/nested/route202.json"
        let textPath = "res/field/events/route203.txt"
        try write(
            """
            {"event_id": 1, "weather": "CLEAR", "has_rival": true, "object_events": [{"id": 1, "script": "Route201_Rival"}]}

            """,
            to: root.appendingPathComponent(eventPath)
        )
        try write("{\"event_id\": 2}\n", to: root.appendingPathComponent(nestedPath))
        try write("event_id=3\n", to: root.appendingPathComponent(textPath))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:\(eventPath)")
        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(snapshot.fields.contains { $0.key == "event_id" && $0.value == "1" && $0.valueKind == .number })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "weather" && $0.value == "CLEAR" && $0.valueKind == .string })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "has_rival" && $0.value == "true" && $0.valueKind == .bool })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "object_events" })

        let nestedPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:\(eventPath)",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "object_events.0.id", value: "2")]
            )
        )
        XCTAssertTrue(nestedPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertTrue(nestedPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(nestedPlan.editPlan.validateApplyability().isApplyable)

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:\(eventPath)",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "event_id", value: "4"),
                    NDSDataSemanticFieldEdit(key: "weather", value: "RAIN"),
                    NDSDataSemanticFieldEdit(key: "has_rival", value: "false")
                ]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"event_id\": 4"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"weather\": \"RAIN\""))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"has_rival\": false"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"object_events\": [{\"id\": 1, \"script\": \"Route201_Rival\"}]"))
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(eventPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"event_id\": 4"))
        XCTAssertTrue(updated.contains("\"weather\": \"RAIN\""))
        XCTAssertTrue(updated.contains("\"has_rival\": false"))
        XCTAssertTrue(updated.contains("\"object_events\": [{\"id\": 1, \"script\": \"Route201_Rival\"}]"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let nestedPathSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:\(nestedPath)")
        XCTAssertFalse(nestedPathSnapshot.canEdit)
        XCTAssertTrue(nestedPathSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })

        let textSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:\(textPath)")
        XCTAssertFalse(textSnapshot.canEdit)
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let mapBinarySnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:res/field/maps/route201/map.bin")
        XCTAssertFalse(mapBinarySnapshot.canEdit)
        XCTAssertTrue(mapBinarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(mapBinarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let generatedSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "resources:generated/species.txt")
        XCTAssertFalse(generatedSnapshot.canEdit)
        XCTAssertTrue(generatedSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DOMAIN_BLOCKED" })
        XCTAssertTrue(generatedSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticEditorPlansPlatinumMapMatrixJSONScalars() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let matrixPath = "res/field/matrices/route201.json"
        let nestedPath = "res/field/matrices/sinnoh/route202.json"
        let textPath = "res/field/matrices/route203.txt"
        try write(
            """
            {"matrix": 1, "width": 32, "name": "Route 201", "enabled": true, "layout": [[1,2]], "evolutions": [["LEVEL",16,"MONFERNO"]], "metadata": {"region":"SINNOH"}}

            """,
            to: root.appendingPathComponent(matrixPath)
        )
        try write("{\"matrix\":2}\n", to: root.appendingPathComponent(nestedPath))
        try write("matrix=3\n", to: root.appendingPathComponent(textPath))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:\(matrixPath)")
        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(snapshot.fields.contains { $0.key == "matrix" && $0.value == "1" && $0.valueKind == .number })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "width" && $0.value == "32" && $0.valueKind == .number })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "name" && $0.value == "Route 201" && $0.valueKind == .string })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "enabled" && $0.value == "true" && $0.valueKind == .bool })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "layout" })
        XCTAssertFalse(snapshot.fields.contains { $0.key.hasPrefix("evolutions.") })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "metadata" })

        let nestedPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:\(matrixPath)",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "layout.0.0", value: "3")]
            )
        )
        XCTAssertTrue(nestedPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertTrue(nestedPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(nestedPlan.editPlan.validateApplyability().isApplyable)

        let evolutionTuplePlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:\(matrixPath)",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "evolutions.0.parameter", value: "20")]
            )
        )
        XCTAssertTrue(evolutionTuplePlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertTrue(evolutionTuplePlan.editPlan.changes.isEmpty)
        XCTAssertFalse(evolutionTuplePlan.editPlan.validateApplyability().isApplyable)

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:\(matrixPath)",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "matrix", value: "4"),
                    NDSDataSemanticFieldEdit(key: "name", value: "Route 201 North"),
                    NDSDataSemanticFieldEdit(key: "enabled", value: "false")
                ]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"matrix\": 4"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"name\": \"Route 201 North\""))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"enabled\": false"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"layout\": [[1,2]]"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"evolutions\": [[\"LEVEL\",16,\"MONFERNO\"]]"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"metadata\": {\"region\":\"SINNOH\"}"))
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(matrixPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"matrix\": 4"))
        XCTAssertTrue(updated.contains("\"name\": \"Route 201 North\""))
        XCTAssertTrue(updated.contains("\"enabled\": false"))
        XCTAssertTrue(updated.contains("\"layout\": [[1,2]]"))
        XCTAssertTrue(updated.contains("\"evolutions\": [[\"LEVEL\",16,\"MONFERNO\"]]"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let nestedPathSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:\(nestedPath)")
        XCTAssertFalse(nestedPathSnapshot.canEdit)
        XCTAssertTrue(nestedPathSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })

        let textSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:\(textPath)")
        XCTAssertFalse(textSnapshot.canEdit)
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let mapBinarySnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:res/field/maps/route201/map.bin")
        XCTAssertFalse(mapBinarySnapshot.canEdit)
        XCTAssertTrue(mapBinarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(mapBinarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let generatedSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "resources:generated/species.txt")
        XCTAssertFalse(generatedSnapshot.canEdit)
        XCTAssertTrue(generatedSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DOMAIN_BLOCKED" })
        XCTAssertTrue(generatedSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticEditorPlansPlatinumAreaDataJSONScalars() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let areaDataPath = "res/field/area_data/route201.json"
        let nestedPath = "res/field/area_data/sinnoh/route202.json"
        let textPath = "res/field/area_data/route203.txt"
        try write(
            """
            {"area_id": 1, "name": "Route 201", "enabled": true, "weather": null, "warps": [{"target":"Sandgem"}], "metadata": {"region":"SINNOH"}}

            """,
            to: root.appendingPathComponent(areaDataPath)
        )
        try write("{\"area_id\": 2}\n", to: root.appendingPathComponent(nestedPath))
        try write("area_id=3\n", to: root.appendingPathComponent(textPath))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:\(areaDataPath)")
        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(snapshot.fields.contains { $0.key == "area_id" && $0.value == "1" && $0.valueKind == .number })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "name" && $0.value == "Route 201" && $0.valueKind == .string })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "enabled" && $0.value == "true" && $0.valueKind == .bool })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "weather" && $0.value == "null" && $0.valueKind == .null })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "warps" })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "metadata" })

        let nestedPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:\(areaDataPath)",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "warps.0.target", value: "Jubilife")]
            )
        )
        XCTAssertTrue(nestedPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertTrue(nestedPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(nestedPlan.editPlan.validateApplyability().isApplyable)

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:\(areaDataPath)",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "area_id", value: "4"),
                    NDSDataSemanticFieldEdit(key: "name", value: "Route 201 North"),
                    NDSDataSemanticFieldEdit(key: "enabled", value: "false"),
                    NDSDataSemanticFieldEdit(key: "weather", value: "null")
                ]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"area_id\": 4"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"name\": \"Route 201 North\""))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"enabled\": false"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"weather\": null"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"warps\": [{\"target\":\"Sandgem\"}]"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"metadata\": {\"region\":\"SINNOH\"}"))
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(areaDataPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"area_id\": 4"))
        XCTAssertTrue(updated.contains("\"name\": \"Route 201 North\""))
        XCTAssertTrue(updated.contains("\"enabled\": false"))
        XCTAssertTrue(updated.contains("\"weather\": null"))
        XCTAssertTrue(updated.contains("\"warps\": [{\"target\":\"Sandgem\"}]"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let nestedPathSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:\(nestedPath)")
        XCTAssertFalse(nestedPathSnapshot.canEdit)
        XCTAssertTrue(nestedPathSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })

        let textSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:\(textPath)")
        XCTAssertFalse(textSnapshot.canEdit)
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let mapBinarySnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:res/field/maps/route201/map.bin")
        XCTAssertFalse(mapBinarySnapshot.canEdit)
        XCTAssertTrue(mapBinarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(mapBinarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let generatedSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "resources:generated/species.txt")
        XCTAssertFalse(generatedSnapshot.canEdit)
        XCTAssertTrue(generatedSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DOMAIN_BLOCKED" })
        XCTAssertTrue(generatedSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticEditorPlansHeartGoldSoulSilverEncounterJSONScalars() throws {
        let root = try makeRoot(name: "pokeheartgold", configure: makeHeartGoldFixture)
        let encounterPath = "files/fielddata/encountdata/johto/route29.json"
        try write(
            """
            {"morning_rate": 20, "day_rate": 15, "night_rate": 10, "enabled": true, "slots": [{"species":"RATTATA","rate":30,"enabled":true}], "swarms": ["PIDGEY","SENTRET"], "metadata": {"map":"ROUTE_29"}}

            """,
            to: root.appendingPathComponent(encounterPath)
        )
        try write("rate=15\n", to: root.appendingPathComponent("files/fielddata/encountdata/gs_enc_data.txt"))
        try write("void Encounter_Load(void) {}\n", to: root.appendingPathComponent("files/fielddata/encountdata/encounter.c"))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "encounters:\(encounterPath)")
        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(snapshot.fields.contains { $0.key == "morning_rate" && $0.value == "20" && $0.valueKind == .number })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "day_rate" && $0.value == "15" && $0.valueKind == .number })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "night_rate" && $0.value == "10" && $0.valueKind == .number })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "enabled" && $0.value == "true" && $0.valueKind == .bool })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "slots.0.species" && $0.value == "RATTATA" && $0.valueKind == .string })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "slots.0.rate" && $0.value == "30" && $0.valueKind == .number })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "slots.0.enabled" && $0.value == "true" && $0.valueKind == .bool })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "swarms.1" && $0.value == "SENTRET" && $0.valueKind == .string })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "slots" })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "metadata" })

        let nestedPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "encounters:\(encounterPath)",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "metadata.map", value: "ROUTE_30")]
            )
        )
        XCTAssertTrue(nestedPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertTrue(nestedPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(nestedPlan.editPlan.validateApplyability().isApplyable)

        let missingSlotPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "encounters:\(encounterPath)",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "slots.99.rate", value: "35")]
            )
        )
        XCTAssertTrue(missingSlotPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FIELD_MISSING" })
        XCTAssertTrue(missingSlotPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(missingSlotPlan.editPlan.validateApplyability().isApplyable)

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "encounters:\(encounterPath)",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "morning_rate", value: "25"),
                    NDSDataSemanticFieldEdit(key: "enabled", value: "false"),
                    NDSDataSemanticFieldEdit(key: "slots.0.rate", value: "35"),
                    NDSDataSemanticFieldEdit(key: "slots.0.species", value: "SENTRET"),
                    NDSDataSemanticFieldEdit(key: "swarms.1", value: "HOOTHOOT")
                ]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"morning_rate\": 25"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"enabled\": false"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"slots\": [{\"species\":\"SENTRET\",\"rate\":35,\"enabled\":true}]"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"swarms\": [\"PIDGEY\",\"HOOTHOOT\"]"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"metadata\": {\"map\":\"ROUTE_29\"}"))
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(encounterPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"morning_rate\": 25"))
        XCTAssertTrue(updated.contains("\"enabled\": false"))
        XCTAssertTrue(updated.contains("\"slots\": [{\"species\":\"SENTRET\",\"rate\":35,\"enabled\":true}]"))
        XCTAssertTrue(updated.contains("\"swarms\": [\"PIDGEY\",\"HOOTHOOT\"]"))
        XCTAssertTrue(updated.contains("\"metadata\": {\"map\":\"ROUTE_29\"}"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let textSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "encounters:files/fielddata/encountdata/gs_enc_data.txt")
        XCTAssertFalse(textSnapshot.canEdit)
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_ENCOUNTER_PATH_BLOCKED" })
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let cAnchorSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "encounters:files/fielddata/encountdata/encounter.c")
        XCTAssertFalse(cAnchorSnapshot.canEdit)
        XCTAssertTrue(cAnchorSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })
        XCTAssertTrue(cAnchorSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_ENCOUNTER_PATH_BLOCKED" })
        XCTAssertTrue(cAnchorSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticEditorPlansHeartGoldSoulSilverZoneEventJSONScalars() throws {
        let root = try makeRoot(name: "pokeheartgold", configure: makeHeartGoldFixture)
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
        try write(Data([0x00]), to: root.appendingPathComponent("files/fielddata/script/scr_seq/0002.bin"))
        try write(Data([0x01]), to: root.appendingPathComponent("files/fielddata/mapmatrix/johto/0002.bin"))
        try write(Data([0x02]), to: root.appendingPathComponent("files/fielddata/maptable/johto/map.bin"))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "scripts:\(zoneEventPath)")
        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(snapshot.fields.contains { $0.key == "zone_id" && $0.value == "1" && $0.valueKind == .number })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "script" && $0.value == "Route29_Intro" && $0.valueKind == .string })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "enabled" && $0.value == "true" && $0.valueKind == .bool })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "object_events" })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "metadata" })

        let nestedPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "scripts:\(zoneEventPath)",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "object_events.0.id", value: "2")]
            )
        )
        XCTAssertTrue(nestedPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertTrue(nestedPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(nestedPlan.editPlan.validateApplyability().isApplyable)

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "scripts:\(zoneEventPath)",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "zone_id", value: "4"),
                    NDSDataSemanticFieldEdit(key: "script", value: "Route29_Edit"),
                    NDSDataSemanticFieldEdit(key: "enabled", value: "false")
                ]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"zone_id\": 4"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"script\": \"Route29_Edit\""))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"enabled\": false"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"object_events\": [{\"id\":1,\"script\":\"Route29_NPC\"}]"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"metadata\": {\"map\":\"ROUTE_29\"}"))
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(zoneEventPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"zone_id\": 4"))
        XCTAssertTrue(updated.contains("\"script\": \"Route29_Edit\""))
        XCTAssertTrue(updated.contains("\"enabled\": false"))
        XCTAssertTrue(updated.contains("\"object_events\": [{\"id\":1,\"script\":\"Route29_NPC\"}]"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let nestedPathSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "scripts:\(nestedPath)")
        XCTAssertFalse(nestedPathSnapshot.canEdit)
        XCTAssertTrue(nestedPathSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })
        XCTAssertTrue(nestedPathSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_SCRIPT_PATH_BLOCKED" })

        let textSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "scripts:files/fielddata/eventdata/zone_event/zone_003.txt")
        XCTAssertFalse(textSnapshot.canEdit)
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_SCRIPT_PATH_BLOCKED" })
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let binaryScriptSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "scripts:files/fielddata/script/scr_seq/0002.bin")
        XCTAssertFalse(binaryScriptSnapshot.canEdit)
        XCTAssertTrue(binaryScriptSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })
        XCTAssertTrue(binaryScriptSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_SCRIPT_PATH_BLOCKED" })
        XCTAssertTrue(binaryScriptSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let mapMatrixSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:files/fielddata/mapmatrix/0001.bin")
        XCTAssertFalse(mapMatrixSnapshot.canEdit)
        XCTAssertTrue(mapMatrixSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })
        XCTAssertTrue(mapMatrixSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(mapMatrixSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let mapMatrixPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:files/fielddata/mapmatrix/0001.bin",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "matrix", value: "2")]
            )
        )
        XCTAssertTrue(mapMatrixPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(mapMatrixPlan.editPlan.validateApplyability().isApplyable)

        let mapTableSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:files/fielddata/maptable/map.bin")
        XCTAssertFalse(mapTableSnapshot.canEdit)
        XCTAssertTrue(mapTableSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })
        XCTAssertTrue(mapTableSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(mapTableSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let mapTablePlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:files/fielddata/maptable/map.bin",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "table", value: "2")]
            )
        )
        XCTAssertTrue(mapTablePlan.editPlan.changes.isEmpty)
        XCTAssertFalse(mapTablePlan.editPlan.validateApplyability().isApplyable)

        let nestedMatrixSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:files/fielddata/mapmatrix/johto/0002.bin")
        XCTAssertFalse(nestedMatrixSnapshot.canEdit)
        XCTAssertTrue(nestedMatrixSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })
        XCTAssertTrue(nestedMatrixSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(nestedMatrixSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let nestedTableSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:files/fielddata/maptable/johto/map.bin")
        XCTAssertFalse(nestedTableSnapshot.canEdit)
        XCTAssertTrue(nestedTableSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })
        XCTAssertTrue(nestedTableSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(nestedTableSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticEditorPlansHeartGoldSoulSilverMapHeaderCIntegerScalars() throws {
        let root = try makeRoot(name: "pokeheartgold", configure: makeHeartGoldFixture)
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:src/data/map_headers.h")

        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        let fields = Dictionary(uniqueKeysWithValues: snapshot.fields.map { ($0.key, $0) })
        XCTAssertEqual(fields["mapHeaders.MAP_EVERYWHERE.areaDataBank"]?.value, "0")
        XCTAssertEqual(fields["mapHeaders.MAP_EVERYWHERE.worldMapX"]?.value, "0")
        XCTAssertEqual(fields["mapHeaders.MAP_EVERYWHERE.worldMapY"]?.value, "0")
        XCTAssertEqual(fields["mapHeaders.MAP_EVERYWHERE.weather"]?.value, "0")
        XCTAssertEqual(fields["mapHeaders.MAP_EVERYWHERE.cameraType"]?.value, "0")
        XCTAssertEqual(fields["mapHeaders.MAP_EVERYWHERE.areaDataBank"]?.valueKind, .number)
        XCTAssertNil(fields["mapHeaders.MAP_EVERYWHERE.matrixId"])
        XCTAssertNil(fields["mapHeaders.MAP_EVERYWHERE.mapType"])
        XCTAssertNil(fields["mapHeaders.MAP_EVERYWHERE.bikeAllowed"])
        XCTAssertEqual(fields["mapHeaders.MAP_NEW_BARK.worldMapX"]?.value, "4")
        XCTAssertEqual(fields["mapHeaders.MAP_NEW_BARK.weather"]?.value, "1")
        XCTAssertNil(fields["mapHeaders.0.areaDataBank"])
        XCTAssertTrue(snapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_C_SCALAR_UNSUPPORTED" })

        let plan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:src/data/map_headers.h",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "mapHeaders.MAP_EVERYWHERE.areaDataBank", value: "8"),
                    NDSDataSemanticFieldEdit(key: "mapHeaders.MAP_EVERYWHERE.worldMapX", value: "9"),
                    NDSDataSemanticFieldEdit(key: "mapHeaders.MAP_NEW_BARK.weather", value: "3"),
                    NDSDataSemanticFieldEdit(key: "mapHeaders.MAP_NEW_BARK.cameraType", value: "4")
                ]
            )
        )

        XCTAssertTrue(plan.diagnostics.allSatisfy { $0.severity != .error }, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(plan.textDraft.editedText.contains(".areaDataBank = 8"))
        XCTAssertTrue(plan.textDraft.editedText.contains(".worldMapX = 9"))
        XCTAssertTrue(plan.textDraft.editedText.contains("[MAP_NEW_BARK] = { .areaDataBank = 3, .worldMapX = 4, .worldMapY = 7, .weather = 3, .cameraType = 4, .bikeAllowed = FALSE }"))
        XCTAssertTrue(plan.textDraft.editedText.contains("{ .areaDataBank = 99 }"))
        XCTAssertEqual(plan.editPlan.changes.count, 1)
        XCTAssertTrue(plan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: plan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("src/data/map_headers.h"), encoding: .utf8)
        XCTAssertTrue(updated.contains(".areaDataBank = 8"))
        XCTAssertTrue(updated.contains(".worldMapX = 9"))
        XCTAssertTrue(updated.contains(".weather = 3"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let invalidPlan = NDSDataSemanticEditor.plan(
            catalog: try NDSDataCatalogBuilder.build(path: root.path),
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:src/data/map_headers.h",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "mapHeaders.MAP_EVERYWHERE.weather", value: "MAP_WEATHER_RAIN")
                ]
            )
        )
        XCTAssertTrue(invalidPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_VALUE_INVALID" })
        XCTAssertTrue(invalidPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(invalidPlan.editPlan.validateApplyability().isApplyable)

        let booleanPlan = NDSDataSemanticEditor.plan(
            catalog: try NDSDataCatalogBuilder.build(path: root.path),
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:src/data/map_headers.h",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "mapHeaders.MAP_EVERYWHERE.bikeAllowed", value: "FALSE")
                ]
            )
        )
        XCTAssertTrue(booleanPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FIELD_MISSING" })
        XCTAssertTrue(booleanPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(booleanPlan.editPlan.validateApplyability().isApplyable)

        let matrixSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:files/fielddata/mapmatrix/0001.bin")
        XCTAssertFalse(matrixSnapshot.canEdit)
        XCTAssertTrue(matrixSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })
        XCTAssertTrue(matrixSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(matrixSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let scriptSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "scripts:files/fielddata/script/scr_seq/0001.bin")
        XCTAssertFalse(scriptSnapshot.canEdit)
        XCTAssertTrue(scriptSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })
        XCTAssertTrue(scriptSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_SCRIPT_PATH_BLOCKED" })
        XCTAssertTrue(scriptSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticEditorPlansHeartGoldSoulSilverPersonalTrainerAndItemJSONScalars() throws {
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

        let itemJSONSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "items:files/itemtool/itemdata/potion.json")
        XCTAssertTrue(itemJSONSnapshot.canEdit, itemJSONSnapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(itemJSONSnapshot.fields.contains { $0.key == "name" && $0.value == "POTION" })
        XCTAssertTrue(itemJSONSnapshot.fields.contains { $0.key == "price" && $0.value == "300" })
        XCTAssertTrue(itemJSONSnapshot.fields.contains { $0.key == "field_use" && $0.value == "true" })
        XCTAssertFalse(itemJSONSnapshot.fields.contains { $0.key == "effects" })

        let nestedItemPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "items:files/itemtool/itemdata/potion.json",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "effects.0.kind", value: "boost")]
            )
        )
        XCTAssertTrue(nestedItemPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertTrue(nestedItemPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(nestedItemPlan.editPlan.validateApplyability().isApplyable)

        let itemJSONPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "items:files/itemtool/itemdata/potion.json",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "name", value: "SUPER_POTION"),
                    NDSDataSemanticFieldEdit(key: "price", value: "700"),
                    NDSDataSemanticFieldEdit(key: "field_use", value: "false")
                ]
            )
        )

        XCTAssertTrue(itemJSONPlan.diagnostics.allSatisfy { $0.severity != .error }, itemJSONPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(itemJSONPlan.textDraft.editedText.contains("\"name\":\"SUPER_POTION\""))
        XCTAssertTrue(itemJSONPlan.textDraft.editedText.contains("\"price\":700"))
        XCTAssertTrue(itemJSONPlan.textDraft.editedText.contains("\"field_use\":false"))
        XCTAssertTrue(itemJSONPlan.textDraft.editedText.contains("\"effects\":[{\"kind\":\"heal\",\"amount\":20}]"))
        XCTAssertEqual(itemJSONPlan.editPlan.changes.count, 1)
        XCTAssertTrue(itemJSONPlan.editPlan.validateApplyability().isApplyable)

        let itemJSONResult = try NDSDataMutationApplier.apply(plan: itemJSONPlan.editPlan)
        XCTAssertEqual(itemJSONResult.appliedChanges.count, 1)
        let itemJSONUpdated = try String(contentsOf: root.appendingPathComponent("files/itemtool/itemdata/potion.json"), encoding: .utf8)
        XCTAssertTrue(itemJSONUpdated.contains("\"name\":\"SUPER_POTION\""))
        XCTAssertTrue(itemJSONUpdated.contains("\"price\":700"))
        XCTAssertTrue(itemJSONUpdated.contains("\"field_use\":false"))
        XCTAssertTrue(itemJSONUpdated.contains("\"effects\":[{\"kind\":\"heal\",\"amount\":20}]"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: itemJSONResult.appliedChanges[0].backupPath))

        let itemSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "items:files/itemtool/itemdata/item_data.csv")
        XCTAssertTrue(itemSnapshot.canEdit, itemSnapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(itemSnapshot.fields.contains { $0.key == "rows.0.name" && $0.value == "POTION" })
    }

    func testNDSDataSemanticEditorPlansHeartGoldSoulSilverItemCSVScalars() throws {
        let root = try makeRoot(name: "pokeheartgold", configure: makeHeartGoldFixture)
        try write(
            """
            id,name,description
            1,POTION,"Basic, heal"
            2,ANTIDOTE,Status

            """,
            to: root.appendingPathComponent("files/itemtool/itemdata/item_data.csv")
        )
        try write("id,name\n1,NESTED\n", to: root.appendingPathComponent("files/itemtool/itemdata/nested/item_data.csv"))
        try write("id=1\n", to: root.appendingPathComponent("files/itemtool/itemdata/item_data.txt"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/itemtool/itemdata/item_0000.bin"))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "items:files/itemtool/itemdata/item_data.csv")
        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(snapshot.fields.contains { $0.key == "rows.0.id" && $0.value == "1" && $0.valueKind == .string })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "rows.0.name" && $0.value == "POTION" && $0.valueKind == .string })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "rows.0.description" && $0.value == "Basic, heal" && $0.valueKind == .string })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "rows.1.name" && $0.value == "ANTIDOTE" && $0.valueKind == .string })

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "items:files/itemtool/itemdata/item_data.csv",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "rows.0.name", value: "SUPER, POTION"),
                    NDSDataSemanticFieldEdit(key: "rows.1.description", value: "Cures \"poison\"")
                ]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("1,\"SUPER, POTION\",\"Basic, heal\""))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("2,ANTIDOTE,\"Cures \"\"poison\"\"\""))
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertEqual(semanticPlan.editPlan.changes.first?.path, "files/itemtool/itemdata/item_data.csv")
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("files/itemtool/itemdata/item_data.csv"), encoding: .utf8)
        XCTAssertTrue(updated.contains("1,\"SUPER, POTION\",\"Basic, heal\""))
        XCTAssertTrue(updated.contains("2,ANTIDOTE,\"Cures \"\"poison\"\"\""))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let newlinePlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "items:files/itemtool/itemdata/item_data.csv",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "rows.0.name", value: "BAD\nVALUE")]
            )
        )
        XCTAssertTrue(newlinePlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_VALUE_INVALID" })
        XCTAssertTrue(newlinePlan.editPlan.changes.isEmpty)
        XCTAssertFalse(newlinePlan.editPlan.validateApplyability().isApplyable)

        let nestedSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "items:files/itemtool/itemdata/nested/item_data.csv")
        XCTAssertFalse(nestedSnapshot.canEdit)
        XCTAssertTrue(nestedSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })
        XCTAssertTrue(nestedSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_ITEM_PATH_BLOCKED" })

        let textSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "items:files/itemtool/itemdata/item_data.txt")
        XCTAssertFalse(textSnapshot.canEdit)
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_ITEM_PATH_BLOCKED" })
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let binarySnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "items:files/itemtool/itemdata/item_0000.bin")
        XCTAssertFalse(binarySnapshot.canEdit)
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_ITEM_PATH_BLOCKED" })
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataItemCSVRowOperationPlanner() throws {
        let root = try makeRoot(name: "pokeheartgold", configure: makeHeartGoldFixture)
        let itemCSVPath = "files/itemtool/itemdata/item_data.csv"
        try write(
            """
            id,name,description
            1,POTION,Basic heal
            2,ANTIDOTE,Status

            """,
            to: root.appendingPathComponent(itemCSVPath)
        )
        try write("id,name\n1,NESTED\n", to: root.appendingPathComponent("files/itemtool/itemdata/nested/item_data.csv"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/itemtool/itemdata/item_0000.bin"))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let plan = NDSDataItemCSVRowOperationPlanner.plan(
            catalog: catalog,
            draft: NDSDataItemCSVRowOperationDraft(
                recordID: "items:\(itemCSVPath)",
                operations: [
                    .insert(index: 1, rowText: "3,\"SUPER, POTION\",Large heal"),
                    .delete(index: 0),
                    .reorder(fromIndex: 1, toIndex: 0)
                ]
            )
        )

        XCTAssertEqual(plan.beforeRowCount, 2)
        XCTAssertEqual(plan.afterRowCount, 2)
        XCTAssertTrue(plan.diagnostics.allSatisfy { $0.severity != .error }, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(plan.editPlan.changes.count, 1)
        XCTAssertEqual(plan.editPlan.changes.first?.path, itemCSVPath)
        XCTAssertTrue(plan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: plan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))
        XCTAssertEqual(
            try String(contentsOf: root.appendingPathComponent(itemCSVPath), encoding: .utf8),
            """
            id,name,description
            2,ANTIDOTE,Status
            3,\"SUPER, POTION\",Large heal

            """
        )

        let updatedCatalog = try NDSDataCatalogBuilder.build(path: root.path)
        let newlinePlan = NDSDataItemCSVRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataItemCSVRowOperationDraft(
                recordID: "items:\(itemCSVPath)",
                operations: [.insert(index: 1, rowText: "4,BAD\nROW,Blocked")]
            )
        )
        XCTAssertTrue(newlinePlan.diagnostics.contains { $0.code == "NDS_DATA_ITEM_CSV_ROWS_NEWLINE_BLOCKED" })
        XCTAssertTrue(newlinePlan.editPlan.changes.isEmpty)
        XCTAssertFalse(newlinePlan.editPlan.validateApplyability().isApplyable)

        let badShapePlan = NDSDataItemCSVRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataItemCSVRowOperationDraft(
                recordID: "items:\(itemCSVPath)",
                operations: [.insert(index: 1, rowText: "4,ETHER")]
            )
        )
        XCTAssertTrue(badShapePlan.diagnostics.contains { $0.code == "NDS_DATA_ITEM_CSV_ROWS_INSERT_ROW_BAD_SHAPE" })
        XCTAssertTrue(badShapePlan.editPlan.changes.isEmpty)

        let unclosedQuotePlan = NDSDataItemCSVRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataItemCSVRowOperationDraft(
                recordID: "items:\(itemCSVPath)",
                operations: [.insert(index: 1, rowText: "4,\"BROKEN,Blocked")]
            )
        )
        XCTAssertTrue(unclosedQuotePlan.diagnostics.contains { $0.code == "NDS_DATA_ITEM_CSV_ROWS_QUOTE_UNCLOSED" })
        XCTAssertTrue(unclosedQuotePlan.editPlan.changes.isEmpty)

        let missingRowPlan = NDSDataItemCSVRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataItemCSVRowOperationDraft(
                recordID: "items:\(itemCSVPath)",
                operations: [.delete(index: 7)]
            )
        )
        XCTAssertTrue(missingRowPlan.diagnostics.contains { $0.code == "NDS_DATA_ITEM_CSV_ROWS_INDEX_OUT_OF_RANGE" })
        XCTAssertTrue(missingRowPlan.editPlan.changes.isEmpty)

        let nestedPlan = NDSDataItemCSVRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataItemCSVRowOperationDraft(
                recordID: "items:files/itemtool/itemdata/nested/item_data.csv",
                operations: [.insert(index: 0, rowText: "2,NESTED2")]
            )
        )
        XCTAssertTrue(nestedPlan.diagnostics.contains { $0.code == "NDS_DATA_ITEM_CSV_ROWS_PATH_BLOCKED" })
        XCTAssertTrue(nestedPlan.editPlan.changes.isEmpty)

        let jsonPlan = NDSDataItemCSVRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataItemCSVRowOperationDraft(
                recordID: "items:files/itemtool/itemdata/potion.json",
                operations: [.insert(index: 0, rowText: "4,POTION_JSON,Blocked")]
            )
        )
        XCTAssertTrue(jsonPlan.diagnostics.contains { $0.code == "NDS_DATA_ITEM_CSV_ROWS_PATH_BLOCKED" })
        XCTAssertTrue(jsonPlan.editPlan.changes.isEmpty)

        let binaryPlan = NDSDataItemCSVRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataItemCSVRowOperationDraft(
                recordID: "items:files/itemtool/itemdata/item_0000.bin",
                operations: [.insert(index: 0, rowText: "4,BINARY,Blocked")]
            )
        )
        XCTAssertTrue(binaryPlan.diagnostics.contains { $0.code == "NDS_DATA_ITEM_CSV_ROWS_PATH_BLOCKED" })
        XCTAssertTrue(binaryPlan.editPlan.changes.isEmpty)

        let containerRecord = try XCTUnwrap(updatedCatalog.records.first { $0.relativePath.hasSuffix(".narc") })
        let containerPlan = NDSDataItemCSVRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataItemCSVRowOperationDraft(
                recordID: containerRecord.id,
                operations: [.insert(index: 0, rowText: "4,CONTAINER,Blocked")]
            )
        )
        XCTAssertTrue(containerPlan.diagnostics.contains { $0.code == "NDS_DATA_ITEM_CSV_ROWS_PATH_BLOCKED" })
        XCTAssertTrue(containerPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_CONTAINER_BLOCKED" })
        XCTAssertTrue(containerPlan.editPlan.changes.isEmpty)

        let referenceRoot = try makeRoot(name: "references/pokeheartgold", configure: makeHeartGoldFixture)
        let referenceCatalog = try NDSDataCatalogBuilder.build(path: referenceRoot.path)
        let referencePlan = NDSDataItemCSVRowOperationPlanner.plan(
            catalog: referenceCatalog,
            draft: NDSDataItemCSVRowOperationDraft(
                recordID: "items:\(itemCSVPath)",
                operations: [.insert(index: 0, rowText: "4,REFERENCE,Blocked")]
            )
        )
        XCTAssertTrue(referencePlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_REFERENCE_BLOCKED" })
        XCTAssertTrue(referencePlan.editPlan.changes.isEmpty)

        let platinum = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let platinumCatalog = try NDSDataCatalogBuilder.build(path: platinum.path)
        let generatedPlan = NDSDataItemCSVRowOperationPlanner.plan(
            catalog: platinumCatalog,
            draft: NDSDataItemCSVRowOperationDraft(
                recordID: "resources:generated/species.txt",
                operations: [.insert(index: 0, rowText: "4,GENERATED,Blocked")]
            )
        )
        XCTAssertTrue(generatedPlan.diagnostics.contains { $0.code == "NDS_DATA_ITEM_CSV_ROWS_PATH_BLOCKED" })
        XCTAssertTrue(generatedPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_ROLE_BLOCKED" })
        XCTAssertTrue(generatedPlan.editPlan.changes.isEmpty)

        let bmgPlan = NDSDataItemCSVRowOperationPlanner.plan(
            catalog: platinumCatalog,
            draft: NDSDataItemCSVRowOperationDraft(
                recordID: "text:res/text/battle.bmg",
                operations: [.insert(index: 0, rowText: "4,BMG,Blocked")]
            )
        )
        XCTAssertTrue(bmgPlan.diagnostics.contains { $0.code == "NDS_DATA_ITEM_CSV_ROWS_PATH_BLOCKED" })
        XCTAssertTrue(bmgPlan.editPlan.changes.isEmpty)
    }

    func testNDSDataEncounterJSONRowOperationPlanner() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let encounterPath = "res/field/encounters/route201.json"
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
        try write("{\"land_encounters\":[{\"level\":2,\"level\":3,\"species\":\"SPECIES_BIDOOF\"}]}\n", to: root.appendingPathComponent("res/field/encounters/duplicate.json"))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let plan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: catalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:\(encounterPath)",
                arrayKey: "land_encounters",
                operations: [
                    .insert(index: 1, rowText: "{\"level\":4,\"species\":\"SPECIES_SHINX\"}"),
                    .delete(index: 0),
                    .reorder(fromIndex: 1, toIndex: 0)
                ]
            )
        )

        XCTAssertEqual(plan.beforeRowCount, 2)
        XCTAssertEqual(plan.afterRowCount, 2)
        XCTAssertTrue(plan.diagnostics.allSatisfy { $0.severity != .error }, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(plan.editPlan.changes.count, 1)
        XCTAssertEqual(plan.editPlan.changes.first?.path, encounterPath)
        XCTAssertTrue(plan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: plan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))
        let updated = try String(contentsOf: root.appendingPathComponent(encounterPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"land_encounters\": [{\"level\":3,\"species\":\"SPECIES_BIDOOF\"},{\"level\":4,\"species\":\"SPECIES_SHINX\"}]"))
        XCTAssertTrue(updated.contains("\"swarms\": [\"SPECIES_DODUO\",\"SPECIES_DODUO\"]"))
        XCTAssertTrue(updated.contains("\"map_category\": {\"map_type\":\"field\",\"map_number\":12}"))

        let updatedCatalog = try NDSDataCatalogBuilder.build(path: root.path)
        let scalarArrayPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:\(encounterPath)",
                arrayKey: "swarms",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(scalarArrayPlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_OBJECT_ROWS_REQUIRED" })
        XCTAssertTrue(scalarArrayPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(scalarArrayPlan.editPlan.validateApplyability().isApplyable)

        let missingArrayPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:\(encounterPath)",
                arrayKey: "missing_encounters",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(missingArrayPlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_ARRAY_MISSING" })
        XCTAssertTrue(missingArrayPlan.editPlan.changes.isEmpty)

        let nestedInsertPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:\(encounterPath)",
                arrayKey: "land_encounters",
                operations: [.insert(index: 0, rowText: "{\"level\":4,\"species\":\"SPECIES_SHINX\",\"metadata\":{\"time\":\"day\"}}")]
            )
        )
        XCTAssertTrue(nestedInsertPlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_NESTED_VALUE_BLOCKED" })
        XCTAssertTrue(nestedInsertPlan.editPlan.changes.isEmpty)

        let badShapePlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:\(encounterPath)",
                arrayKey: "land_encounters",
                operations: [.insert(index: 0, rowText: "{\"level\":4}")]
            )
        )
        XCTAssertTrue(badShapePlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_INSERT_ROW_BAD_SHAPE" })
        XCTAssertTrue(badShapePlan.editPlan.changes.isEmpty)

        let newlinePlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:\(encounterPath)",
                arrayKey: "land_encounters",
                operations: [.insert(index: 0, rowText: "{\"level\":4,\n\"species\":\"SPECIES_SHINX\"}")]
            )
        )
        XCTAssertTrue(newlinePlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_NEWLINE_BLOCKED" })
        XCTAssertTrue(newlinePlan.editPlan.changes.isEmpty)

        let rangePlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:\(encounterPath)",
                arrayKey: "land_encounters",
                operations: [.delete(index: 7)]
            )
        )
        XCTAssertTrue(rangePlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_INDEX_OUT_OF_RANGE" })
        XCTAssertTrue(rangePlan.editPlan.changes.isEmpty)

        let malformedPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:res/field/encounters/malformed.json",
                arrayKey: "land_encounters",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(malformedPlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_JSON_MALFORMED" })
        XCTAssertTrue(malformedPlan.editPlan.changes.isEmpty)

        let duplicatePlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:res/field/encounters/duplicate.json",
                arrayKey: "land_encounters",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(duplicatePlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_KEY_DUPLICATE" })
        XCTAssertTrue(duplicatePlan.editPlan.changes.isEmpty)

        let topLevelArrayPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:res/field/encounters/array.json",
                arrayKey: "land_encounters",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(topLevelArrayPlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_OBJECT_REQUIRED" })
        XCTAssertTrue(topLevelArrayPlan.editPlan.changes.isEmpty)

        let nestedPathPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:res/field/encounters/nested/route202.json",
                arrayKey: "land_encounters",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(nestedPathPlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_PATH_BLOCKED" })
        XCTAssertTrue(nestedPathPlan.editPlan.changes.isEmpty)

        let textPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:res/field/encounters/route203.txt",
                arrayKey: "land_encounters",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(textPlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_PATH_BLOCKED" })
        XCTAssertTrue(textPlan.editPlan.changes.isEmpty)

        let containerRecord = try XCTUnwrap(updatedCatalog.records.first { $0.relativePath.hasSuffix(".narc") })
        let containerPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: containerRecord.id,
                arrayKey: "land_encounters",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(containerPlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_PATH_BLOCKED" })
        XCTAssertTrue(containerPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_CONTAINER_BLOCKED" })
        XCTAssertTrue(containerPlan.editPlan.changes.isEmpty)

        let generatedPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "resources:generated/species.txt",
                arrayKey: "land_encounters",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(generatedPlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_PATH_BLOCKED" })
        XCTAssertTrue(generatedPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_ROLE_BLOCKED" })
        XCTAssertTrue(generatedPlan.editPlan.changes.isEmpty)

        let referenceRoot = try makeRoot(name: "references/pokeplatinum", configure: makePlatinumFixture)
        try write(
            "{\"land_encounters\":[{\"level\":2,\"species\":\"SPECIES_BIDOOF\"}]}\n",
            to: referenceRoot.appendingPathComponent(encounterPath)
        )
        let referenceCatalog = try NDSDataCatalogBuilder.build(path: referenceRoot.path)
        let referencePlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: referenceCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:\(encounterPath)",
                arrayKey: "land_encounters",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(referencePlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_REFERENCE_BLOCKED" })
        XCTAssertTrue(referencePlan.editPlan.changes.isEmpty)
    }

    func testNDSDataEncounterJSONRowOperationPlannerHeartGoldSoulSilver() throws {
        let root = try makeRoot(name: "pokeheartgold", configure: makeHeartGoldFixture)
        let encounterPath = "files/fielddata/encountdata/johto/route29.json"
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
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let plan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: catalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:\(encounterPath)",
                arrayKey: "slots",
                operations: [
                    .insert(index: 1, rowText: "{\"species\":\"HOOTHOOT\",\"rate\":25,\"enabled\":true}"),
                    .delete(index: 0),
                    .reorder(fromIndex: 1, toIndex: 0)
                ]
            )
        )

        XCTAssertEqual(plan.beforeRowCount, 2)
        XCTAssertEqual(plan.afterRowCount, 2)
        XCTAssertTrue(plan.diagnostics.allSatisfy { $0.severity != .error }, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(plan.editPlan.changes.count, 1)
        XCTAssertEqual(plan.editPlan.changes.first?.path, encounterPath)
        XCTAssertTrue(plan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: plan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))
        let updated = try String(contentsOf: root.appendingPathComponent(encounterPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"slots\": [{\"species\":\"PIDGEY\",\"rate\":20,\"enabled\":false},{\"species\":\"HOOTHOOT\",\"rate\":25,\"enabled\":true}]"))
        XCTAssertTrue(updated.contains("\"swarms\": [\"PIDGEY\",\"SENTRET\"]"))
        XCTAssertTrue(updated.contains("\"metadata\": {\"map\":\"ROUTE_29\"}"))

        let updatedCatalog = try NDSDataCatalogBuilder.build(path: root.path)
        let scalarArrayPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:\(encounterPath)",
                arrayKey: "swarms",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(scalarArrayPlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_OBJECT_ROWS_REQUIRED" })
        XCTAssertTrue(scalarArrayPlan.editPlan.changes.isEmpty)

        let missingArrayPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:\(encounterPath)",
                arrayKey: "missing_slots",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(missingArrayPlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_ARRAY_MISSING" })
        XCTAssertTrue(missingArrayPlan.editPlan.changes.isEmpty)

        let emptyArrayPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:files/fielddata/encountdata/empty.json",
                arrayKey: "slots",
                operations: [.insert(index: 0, rowText: "{\"species\":\"HOOTHOOT\",\"rate\":25,\"enabled\":true}")]
            )
        )
        XCTAssertTrue(emptyArrayPlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_EMPTY_BLOCKED" })
        XCTAssertTrue(emptyArrayPlan.editPlan.changes.isEmpty)

        let nestedInsertPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:\(encounterPath)",
                arrayKey: "slots",
                operations: [.insert(index: 0, rowText: "{\"species\":\"HOOTHOOT\",\"rate\":25,\"enabled\":true,\"metadata\":{\"time\":\"night\"}}")]
            )
        )
        XCTAssertTrue(nestedInsertPlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_NESTED_VALUE_BLOCKED" })
        XCTAssertTrue(nestedInsertPlan.editPlan.changes.isEmpty)

        let mismatchPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:files/fielddata/encountdata/mismatch.json",
                arrayKey: "slots",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(mismatchPlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_ROW_SHAPE_MISMATCH" })
        XCTAssertTrue(mismatchPlan.editPlan.changes.isEmpty)

        let duplicatePlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:files/fielddata/encountdata/duplicate.json",
                arrayKey: "slots",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(duplicatePlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_KEY_DUPLICATE" })
        XCTAssertTrue(duplicatePlan.editPlan.changes.isEmpty)

        let nestedArrayPathPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:\(encounterPath)",
                arrayKey: "metadata.slots",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(nestedArrayPathPlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_ARRAY_PATH_BLOCKED" })
        XCTAssertTrue(nestedArrayPathPlan.editPlan.changes.isEmpty)

        let textPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:files/fielddata/encountdata/gs_enc_data.txt",
                arrayKey: "slots",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(textPlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_PATH_BLOCKED" })
        XCTAssertTrue(textPlan.editPlan.changes.isEmpty)

        let cAnchorPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:files/fielddata/encountdata/encounter.c",
                arrayKey: "slots",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(cAnchorPlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_PATH_BLOCKED" })
        XCTAssertTrue(cAnchorPlan.editPlan.changes.isEmpty)

        let containerRecord = try XCTUnwrap(updatedCatalog.records.first { $0.relativePath.hasSuffix(".narc") })
        let containerPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: updatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: containerRecord.id,
                arrayKey: "slots",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(containerPlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_PATH_BLOCKED" })
        XCTAssertTrue(containerPlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_CONTAINER_BLOCKED" })
        XCTAssertTrue(containerPlan.editPlan.changes.isEmpty)

        let referenceRoot = try makeRoot(name: "references/pokeheartgold", configure: makeHeartGoldFixture)
        try write(
            "{\"slots\":[{\"species\":\"RATTATA\",\"rate\":30,\"enabled\":true}]}\n",
            to: referenceRoot.appendingPathComponent(encounterPath)
        )
        let referenceCatalog = try NDSDataCatalogBuilder.build(path: referenceRoot.path)
        let referencePlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: referenceCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:\(encounterPath)",
                arrayKey: "slots",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(referencePlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_REFERENCE_BLOCKED" })
        XCTAssertTrue(referencePlan.editPlan.changes.isEmpty)

        let diamondRoot = try makeRoot(name: "pokediamond", configure: makeDiamondFixture)
        let diamondPath = "files/fielddata/encountdata/sinnoh/route201.json"
        try write(
            "{\"rate\":20,\"slots\":[{\"species\":\"BIDOOF\",\"rate\":30,\"enabled\":true},{\"species\":\"STARLY\",\"rate\":20,\"enabled\":false}],\"swarms\":[\"DODUO\",\"NIDORAN_F\"],\"metadata\":{\"map\":\"ROUTE_201\"}}\n",
            to: diamondRoot.appendingPathComponent(diamondPath)
        )
        try write("{\"slots\":[]}\n", to: diamondRoot.appendingPathComponent("files/fielddata/encountdata/empty.json"))
        try write("{\"slots\":[{\"species\":\"BIDOOF\",\"rate\":30},{\"species\":\"STARLY\"}]}\n", to: diamondRoot.appendingPathComponent("files/fielddata/encountdata/mismatch.json"))
        try write("{\"slots\":[{\"species\":\"BIDOOF\",\"species\":\"STARLY\",\"rate\":30,\"enabled\":true}]}\n", to: diamondRoot.appendingPathComponent("files/fielddata/encountdata/duplicate.json"))
        try write("rate=15\n", to: diamondRoot.appendingPathComponent("files/fielddata/encountdata/route202.txt"))
        try write("ignored\n", to: diamondRoot.appendingPathComponent("files/arc/encdata_ex/encounter_slots/.knarcignore"))
        let diamondCatalog = try NDSDataCatalogBuilder.build(path: diamondRoot.path)
        let diamondPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: diamondCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:\(diamondPath)",
                arrayKey: "slots",
                operations: [
                    .insert(index: 1, rowText: "{\"species\":\"SHINX\",\"rate\":25,\"enabled\":true}"),
                    .delete(index: 0),
                    .reorder(fromIndex: 1, toIndex: 0)
                ]
            )
        )
        XCTAssertEqual(diamondPlan.beforeRowCount, 2)
        XCTAssertEqual(diamondPlan.afterRowCount, 2)
        XCTAssertTrue(diamondPlan.diagnostics.allSatisfy { $0.severity != .error }, diamondPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(diamondPlan.editPlan.changes.count, 1)
        XCTAssertEqual(diamondPlan.editPlan.changes.first?.path, diamondPath)
        XCTAssertTrue(diamondPlan.editPlan.validateApplyability().isApplyable)

        let diamondResult = try NDSDataMutationApplier.apply(plan: diamondPlan.editPlan)
        XCTAssertEqual(diamondResult.appliedChanges.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: diamondResult.appliedChanges[0].backupPath))
        let diamondUpdated = try String(contentsOf: diamondRoot.appendingPathComponent(diamondPath), encoding: .utf8)
        XCTAssertTrue(diamondUpdated.contains("\"slots\":[{\"species\":\"STARLY\",\"rate\":20,\"enabled\":false},{\"species\":\"SHINX\",\"rate\":25,\"enabled\":true}]"))
        XCTAssertTrue(diamondUpdated.contains("\"swarms\":[\"DODUO\",\"NIDORAN_F\"]"))
        XCTAssertTrue(diamondUpdated.contains("\"metadata\":{\"map\":\"ROUTE_201\"}"))

        let diamondUpdatedCatalog = try NDSDataCatalogBuilder.build(path: diamondRoot.path)
        let diamondBlockedPlans: [(String, String, NDSDataEncounterJSONRowOperation, String)] = [
            ("encounters:\(diamondPath)", "swarms", .delete(index: 0), "NDS_DATA_ENCOUNTER_JSON_ROWS_OBJECT_ROWS_REQUIRED"),
            ("encounters:\(diamondPath)", "missing_slots", .delete(index: 0), "NDS_DATA_ENCOUNTER_JSON_ROWS_ARRAY_MISSING"),
            ("encounters:files/fielddata/encountdata/empty.json", "slots", .insert(index: 0, rowText: "{\"species\":\"SHINX\",\"rate\":25,\"enabled\":true}"), "NDS_DATA_ENCOUNTER_JSON_ROWS_EMPTY_BLOCKED"),
            ("encounters:\(diamondPath)", "slots", .insert(index: 0, rowText: "{\"species\":\"SHINX\",\"rate\":25,\"enabled\":true,\"metadata\":{\"time\":\"morning\"}}"), "NDS_DATA_ENCOUNTER_JSON_ROWS_NESTED_VALUE_BLOCKED"),
            ("encounters:files/fielddata/encountdata/mismatch.json", "slots", .delete(index: 0), "NDS_DATA_ENCOUNTER_JSON_ROWS_ROW_SHAPE_MISMATCH"),
            ("encounters:files/fielddata/encountdata/duplicate.json", "slots", .delete(index: 0), "NDS_DATA_ENCOUNTER_JSON_ROWS_KEY_DUPLICATE"),
            ("encounters:files/fielddata/encountdata/route202.txt", "slots", .delete(index: 0), "NDS_DATA_ENCOUNTER_JSON_ROWS_PATH_BLOCKED"),
            ("encounters:arm9/src/encounter.c", "slots", .delete(index: 0), "NDS_DATA_ENCOUNTER_JSON_ROWS_PATH_BLOCKED")
        ]
        for (recordID, arrayKey, operation, expectedCode) in diamondBlockedPlans {
            let blockedPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
                catalog: diamondUpdatedCatalog,
                draft: NDSDataEncounterJSONRowOperationDraft(
                    recordID: recordID,
                    arrayKey: arrayKey,
                    operations: [operation]
                )
            )
            XCTAssertTrue(blockedPlan.diagnostics.contains { $0.code == expectedCode }, "\(recordID) expected \(expectedCode)")
            XCTAssertTrue(blockedPlan.editPlan.changes.isEmpty)
        }

        let diamondNestedArrayPathPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: diamondUpdatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:\(diamondPath)",
                arrayKey: "metadata.slots",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(diamondNestedArrayPathPlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_ARRAY_PATH_BLOCKED" })
        XCTAssertTrue(diamondNestedArrayPathPlan.editPlan.changes.isEmpty)

        let diamondContainerRecord = try XCTUnwrap(diamondUpdatedCatalog.records.first { $0.relativePath.contains("encdata_ex") && $0.role == .binaryContainer })
        XCTAssertEqual(diamondContainerRecord.role, .binaryContainer)
        let diamondContainerPlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: diamondUpdatedCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: diamondContainerRecord.id,
                arrayKey: "slots",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(diamondContainerPlan.diagnostics.contains { $0.code == "NDS_DATA_ENCOUNTER_JSON_ROWS_PATH_BLOCKED" })
        XCTAssertTrue(diamondContainerPlan.editPlan.changes.isEmpty)

        let diamondReferenceRoot = try makeRoot(name: "references/pokediamond", configure: makeDiamondFixture)
        try write(
            "{\"slots\":[{\"species\":\"BIDOOF\",\"rate\":30,\"enabled\":true}]}\n",
            to: diamondReferenceRoot.appendingPathComponent(diamondPath)
        )
        let diamondReferenceCatalog = try NDSDataCatalogBuilder.build(path: diamondReferenceRoot.path)
        let diamondReferencePlan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: diamondReferenceCatalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:\(diamondPath)",
                arrayKey: "slots",
                operations: [.delete(index: 0)]
            )
        )
        XCTAssertTrue(diamondReferencePlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_REFERENCE_BLOCKED" })
        XCTAssertTrue(diamondReferencePlan.editPlan.changes.isEmpty)
    }

    func testNDSDataEncounterJSONRowOperationsPreserveUnknownFieldsObjectOrderAndOuterFormatting() throws {
        try assertEncounterJSONRowOperationsPreserveUnknownFieldsObjectOrderAndOuterFormatting(
            rootName: "pokeplatinum",
            configure: makePlatinumFixture,
            encounterPath: "res/field/encounters/route201.json",
            arrayKey: "land_encounters",
            firstRow: #"{"level": 2, "species": "SPECIES_STARLY", "unknown_note": "first", "enabled": true}"#,
            secondRow: #"{"level": 3, "species": "SPECIES_BIDOOF", "unknown_note": "second", "enabled": false}"#,
            insertedRow: #"{"level": 4, "species": "SPECIES_SHINX", "unknown_note": "inserted", "enabled": true}"#
        )
        try assertEncounterJSONRowOperationsPreserveUnknownFieldsObjectOrderAndOuterFormatting(
            rootName: "pokeheartgold",
            configure: makeHeartGoldFixture,
            encounterPath: "files/fielddata/encountdata/johto/route29.json",
            arrayKey: "slots",
            firstRow: #"{"species": "RATTATA", "rate": 30, "enabled": true, "unknown_note": "first"}"#,
            secondRow: #"{"species": "PIDGEY", "rate": 20, "enabled": false, "unknown_note": "second"}"#,
            insertedRow: #"{"species": "HOOTHOOT", "rate": 25, "enabled": true, "unknown_note": "inserted"}"#
        )
        try assertEncounterJSONRowOperationsPreserveUnknownFieldsObjectOrderAndOuterFormatting(
            rootName: "pokediamond",
            configure: makeDiamondFixture,
            encounterPath: "files/fielddata/encountdata/sinnoh/route201.json",
            arrayKey: "slots",
            firstRow: #"{"species": "BIDOOF", "rate": 30, "enabled": true, "unknown_note": "first"}"#,
            secondRow: #"{"species": "STARLY", "rate": 20, "enabled": false, "unknown_note": "second"}"#,
            insertedRow: #"{"species": "SHINX", "rate": 25, "enabled": true, "unknown_note": "inserted"}"#
        )
    }

    func testNDSDataSemanticEditorPlansDiamondPearlPersonalJSONScalars() throws {
        let root = try makeRoot(name: "pokediamond", configure: makeDiamondFixture)
        try write("{\"personal\":2,\"growth_rate\":\"medium\",\"forms\":[{\"id\":1}]}\n", to: root.appendingPathComponent("files/poketool/personal_pearl/personal.json"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/poketool/personal/personal_0000.bin"))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "personal:files/poketool/personal/personal.json")

        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(snapshot.fields.map(\.key), ["personal"])
        XCTAssertEqual(snapshot.fields.first?.value, "1")
        XCTAssertEqual(snapshot.fields.first?.valueKind, .number)

        let plan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "personal:files/poketool/personal/personal.json",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "personal", value: "5")]
            )
        )

        XCTAssertTrue(plan.diagnostics.allSatisfy { $0.severity != .error }, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"personal\":5"))
        XCTAssertEqual(plan.editPlan.changes.count, 1)
        XCTAssertTrue(plan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: plan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("files/poketool/personal/personal.json"), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"personal\":5"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let pearlSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "personal:files/poketool/personal_pearl/personal.json")
        XCTAssertTrue(pearlSnapshot.canEdit, pearlSnapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(pearlSnapshot.fields.contains { $0.key == "personal" && $0.value == "2" })
        XCTAssertTrue(pearlSnapshot.fields.contains { $0.key == "growth_rate" && $0.value == "medium" })
        XCTAssertFalse(pearlSnapshot.fields.contains { $0.key == "forms" })

        let nestedPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "personal:files/poketool/personal_pearl/personal.json",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "forms.0.id", value: "2")]
            )
        )
        XCTAssertTrue(nestedPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertTrue(nestedPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(nestedPlan.editPlan.validateApplyability().isApplyable)

        let binarySnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "personal:files/poketool/personal/personal_0000.bin")
        XCTAssertFalse(binarySnapshot.canEdit)
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticEditorPlansDiamondPearlTrainerJSONScalars() throws {
        let root = try makeRoot(name: "pokediamond", configure: makeDiamondFixture)
        try write(
            "{\"id\":7,\"name\":\"Lass Dana\",\"double_battle\":false,\"party\":[{\"species\":\"BIDOOF\",\"level\":5}]}\n",
            to: root.appendingPathComponent("files/poketool/trainer/routes/route201.json")
        )
        try write(Data([0x00]), to: root.appendingPathComponent("files/poketool/trainer/trainer_0000.bin"))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "trainers:files/poketool/trainer/routes/route201.json")

        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        let fields = Dictionary(uniqueKeysWithValues: snapshot.fields.map { ($0.key, $0) })
        XCTAssertEqual(fields["id"]?.value, "7")
        XCTAssertEqual(fields["id"]?.valueKind, .number)
        XCTAssertEqual(fields["name"]?.value, "Lass Dana")
        XCTAssertEqual(fields["name"]?.valueKind, .string)
        XCTAssertEqual(fields["double_battle"]?.value, "false")
        XCTAssertEqual(fields["double_battle"]?.valueKind, .bool)
        XCTAssertNil(fields["party"])

        let nestedPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "trainers:files/poketool/trainer/routes/route201.json",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "party.0.level", value: "6")]
            )
        )
        XCTAssertTrue(nestedPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertTrue(nestedPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(nestedPlan.editPlan.validateApplyability().isApplyable)

        let plan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "trainers:files/poketool/trainer/routes/route201.json",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "name", value: "Ace Dana"),
                    NDSDataSemanticFieldEdit(key: "double_battle", value: "true")
                ]
            )
        )

        XCTAssertTrue(plan.diagnostics.allSatisfy { $0.severity != .error }, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"name\":\"Ace Dana\""))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"double_battle\":true"))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"party\":[{\"species\":\"BIDOOF\",\"level\":5}]"))
        XCTAssertEqual(plan.editPlan.changes.count, 1)
        XCTAssertTrue(plan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: plan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("files/poketool/trainer/routes/route201.json"), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"name\":\"Ace Dana\""))
        XCTAssertTrue(updated.contains("\"double_battle\":true"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let binarySnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "trainers:files/poketool/trainer/trainer_0000.bin")
        XCTAssertFalse(binarySnapshot.canEdit)
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let cAnchorSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "trainers:arm9/src/trainer_data.c")
        XCTAssertTrue(cAnchorSnapshot.canEdit, cAnchorSnapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(cAnchorSnapshot.fields.contains { $0.key == "trainerClassGenderCounts.0.genderCount" })
    }

    func testNDSDataSemanticEditorPlansDiamondPearlItemJSONScalars() throws {
        let root = try makeRoot(name: "pokediamond", configure: makeDiamondFixture)
        let itemPath = "files/itemtool/itemdata/potion.json"
        let escapedPath = "files/itemtool/itemdata/escaped.json"
        let binaryPath = "files/itemtool/itemdata/item_0000.bin"
        let duplicatePath = "files/itemtool/itemdata/duplicate.json"
        let malformedPath = "files/itemtool/itemdata/malformed.json"
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "items:\(itemPath)")

        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        let fields = Dictionary(uniqueKeysWithValues: snapshot.fields.map { ($0.key, $0) })
        XCTAssertEqual(fields["name"]?.value, "POTION")
        XCTAssertEqual(fields["name"]?.valueKind, .string)
        XCTAssertEqual(fields["price"]?.value, "300")
        XCTAssertEqual(fields["price"]?.valueKind, .number)
        XCTAssertEqual(fields["field_use"]?.value, "true")
        XCTAssertEqual(fields["field_use"]?.valueKind, .bool)
        XCTAssertNil(fields["effects"])

        let escapedSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "items:\(escapedPath)")
        XCTAssertTrue(escapedSnapshot.canEdit, escapedSnapshot.diagnostics.map(\.code).joined(separator: ","))
        let escapedFields = Dictionary(uniqueKeysWithValues: escapedSnapshot.fields.map { ($0.key, $0) })
        XCTAssertEqual(escapedFields["name"]?.value, "POTION\nTAB\té")
        XCTAssertEqual(escapedFields["description"]?.value, "quoted \"text\" and slash \\")

        let nestedPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "items:\(itemPath)",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "effects.0.amount", value: "50")]
            )
        )
        XCTAssertTrue(nestedPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertTrue(nestedPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(nestedPlan.editPlan.validateApplyability().isApplyable)

        let plan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "items:\(itemPath)",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "name", value: "SUPER_POTION"),
                    NDSDataSemanticFieldEdit(key: "price", value: "700"),
                    NDSDataSemanticFieldEdit(key: "field_use", value: "false")
                ]
            )
        )

        XCTAssertTrue(plan.diagnostics.allSatisfy { $0.severity != .error }, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"name\":\"SUPER_POTION\""))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"price\":700"))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"field_use\":false"))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"effects\":[{\"kind\":\"heal\",\"amount\":20}]"))
        XCTAssertEqual(plan.editPlan.changes.count, 1)
        XCTAssertTrue(plan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: plan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(itemPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"name\":\"SUPER_POTION\""))
        XCTAssertTrue(updated.contains("\"price\":700"))
        XCTAssertTrue(updated.contains("\"field_use\":false"))
        XCTAssertTrue(updated.contains("\"effects\":[{\"kind\":\"heal\",\"amount\":20}]"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let binarySnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "items:\(binaryPath)")
        XCTAssertFalse(binarySnapshot.canEdit)
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_ITEM_PATH_BLOCKED" })
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let duplicateSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "items:\(duplicatePath)")
        XCTAssertFalse(duplicateSnapshot.canEdit)
        XCTAssertTrue(duplicateSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_JSON_KEY_DUPLICATE" })

        let malformedSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "items:\(malformedPath)")
        XCTAssertFalse(malformedSnapshot.canEdit)
        XCTAssertTrue(malformedSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_JSON_MALFORMED" })

        let cAnchorSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "items:arm9/src/itemtool.c")
        XCTAssertTrue(cAnchorSnapshot.canEdit, cAnchorSnapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(cAnchorSnapshot.fields.contains { $0.key == "itemIndexMappings.1.itemDataIndex" && $0.value == "1" })
    }

    func testNDSDataSemanticEditorPlansDiamondPearlEncounterJSONScalars() throws {
        let root = try makeRoot(name: "pokediamond", configure: makeDiamondFixture)
        let encounterPath = "files/fielddata/encountdata/sinnoh/route201.json"
        let textPath = "files/fielddata/encountdata/route202.txt"
        let binaryPath = "files/fielddata/encountdata/encounter_0000.bin"
        let duplicatePath = "files/fielddata/encountdata/duplicate.json"
        let malformedPath = "files/fielddata/encountdata/malformed.json"
        try write(
            "{\"rate\":20,\"morning_rate\":10,\"enabled\":true,\"slots\":[{\"species\":\"BIDOOF\",\"rate\":30,\"metadata\":{\"time\":\"morning\"}},{\"species\":\"STARLY\",\"rate\":20}],\"swarms\":[\"DODUO\",\"NIDORAN_F\"],\"metadata\":{\"map\":\"ROUTE_201\"}}\n",
            to: root.appendingPathComponent(encounterPath)
        )
        try write("rate=15\n", to: root.appendingPathComponent(textPath))
        try write(Data([0x00]), to: root.appendingPathComponent(binaryPath))
        try write("{\"rate\":10,\"rate\":12}\n", to: root.appendingPathComponent(duplicatePath))
        try write("{\"rate\": }\n", to: root.appendingPathComponent(malformedPath))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "encounters:\(encounterPath)")

        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        let fields = Dictionary(uniqueKeysWithValues: snapshot.fields.map { ($0.key, $0) })
        XCTAssertEqual(fields["rate"]?.value, "20")
        XCTAssertEqual(fields["rate"]?.valueKind, .number)
        XCTAssertEqual(fields["morning_rate"]?.value, "10")
        XCTAssertEqual(fields["enabled"]?.value, "true")
        XCTAssertEqual(fields["enabled"]?.valueKind, .bool)
        XCTAssertNil(fields["slots"])
        XCTAssertEqual(fields["slots.0.species"]?.value, "BIDOOF")
        XCTAssertEqual(fields["slots.0.species"]?.valueKind, .string)
        XCTAssertEqual(fields["slots.0.rate"]?.value, "30")
        XCTAssertEqual(fields["slots.0.rate"]?.valueKind, .number)
        XCTAssertEqual(fields["slots.1.species"]?.value, "STARLY")
        XCTAssertEqual(fields["swarms.0"]?.value, "DODUO")
        XCTAssertEqual(fields["swarms.0"]?.valueKind, .string)
        XCTAssertNil(fields["metadata"])
        XCTAssertNil(fields["metadata.map"])
        XCTAssertNil(fields["slots.0.metadata.time"])

        let nestedPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "encounters:\(encounterPath)",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "metadata.map", value: "ROUTE_202")]
            )
        )
        XCTAssertTrue(nestedPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertTrue(nestedPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(nestedPlan.editPlan.validateApplyability().isApplyable)

        let missingSlotPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "encounters:\(encounterPath)",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "slots.99.rate", value: "35")]
            )
        )
        XCTAssertTrue(missingSlotPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FIELD_MISSING" })
        XCTAssertTrue(missingSlotPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(missingSlotPlan.editPlan.validateApplyability().isApplyable)

        let plan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "encounters:\(encounterPath)",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "morning_rate", value: "25"),
                    NDSDataSemanticFieldEdit(key: "enabled", value: "false"),
                    NDSDataSemanticFieldEdit(key: "slots.0.species", value: "KRICKETOT"),
                    NDSDataSemanticFieldEdit(key: "slots.0.rate", value: "35"),
                    NDSDataSemanticFieldEdit(key: "swarms.1", value: "NIDORAN_M")
                ]
            )
        )

        XCTAssertTrue(plan.diagnostics.allSatisfy { $0.severity != .error }, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"morning_rate\":25"))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"enabled\":false"))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"slots\":[{\"species\":\"KRICKETOT\",\"rate\":35,\"metadata\":{\"time\":\"morning\"}},{\"species\":\"STARLY\",\"rate\":20}]"))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"swarms\":[\"DODUO\",\"NIDORAN_M\"]"))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"metadata\":{\"map\":\"ROUTE_201\"}"))
        XCTAssertEqual(plan.editPlan.changes.count, 1)
        XCTAssertTrue(plan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: plan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(encounterPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"morning_rate\":25"))
        XCTAssertTrue(updated.contains("\"enabled\":false"))
        XCTAssertTrue(updated.contains("\"slots\":[{\"species\":\"KRICKETOT\",\"rate\":35,\"metadata\":{\"time\":\"morning\"}},{\"species\":\"STARLY\",\"rate\":20}]"))
        XCTAssertTrue(updated.contains("\"swarms\":[\"DODUO\",\"NIDORAN_M\"]"))
        XCTAssertTrue(updated.contains("\"metadata\":{\"map\":\"ROUTE_201\"}"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let textSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "encounters:\(textPath)")
        XCTAssertFalse(textSnapshot.canEdit)
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_ENCOUNTER_PATH_BLOCKED" })
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let binarySnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "encounters:\(binaryPath)")
        XCTAssertFalse(binarySnapshot.canEdit)
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_ENCOUNTER_PATH_BLOCKED" })
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let cAnchorSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "encounters:arm9/src/encounter.c")
        XCTAssertFalse(cAnchorSnapshot.canEdit)
        XCTAssertTrue(cAnchorSnapshot.fields.isEmpty)
        XCTAssertTrue(cAnchorSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(cAnchorSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_ENCOUNTER_PATH_BLOCKED" })
        XCTAssertTrue(cAnchorSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let duplicateSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "encounters:\(duplicatePath)")
        XCTAssertFalse(duplicateSnapshot.canEdit)
        XCTAssertTrue(duplicateSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_JSON_KEY_DUPLICATE" })

        let malformedSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "encounters:\(malformedPath)")
        XCTAssertFalse(malformedSnapshot.canEdit)
        XCTAssertTrue(malformedSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_JSON_MALFORMED" })
    }

    func testNDSDataSemanticEditorPlansDiamondPearlFieldEventJSONScalars() throws {
        let root = try makeRoot(name: "pokediamond", configure: makeDiamondFixture)
        let eventPath = "files/fielddata/eventdata/route201.json"
        let nestedPath = "files/fielddata/eventdata/sinnoh/route202.json"
        let textPath = "files/fielddata/eventdata/route203.txt"
        try write(
            "{\"event_id\":10,\"weather\":\"CLEAR\",\"has_rival\":true,\"object_events\":[{\"id\":1,\"script\":\"Route201_Rival\"}],\"metadata\":{\"map\":\"ROUTE_201\"}}\n",
            to: root.appendingPathComponent(eventPath)
        )
        try write("{\"event_id\":11}\n", to: root.appendingPathComponent(nestedPath))
        try write("event_id=12\n", to: root.appendingPathComponent(textPath))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:\(eventPath)")

        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        let fields = Dictionary(uniqueKeysWithValues: snapshot.fields.map { ($0.key, $0) })
        XCTAssertEqual(fields["event_id"]?.value, "10")
        XCTAssertEqual(fields["event_id"]?.valueKind, .number)
        XCTAssertEqual(fields["weather"]?.value, "CLEAR")
        XCTAssertEqual(fields["weather"]?.valueKind, .string)
        XCTAssertEqual(fields["has_rival"]?.value, "true")
        XCTAssertEqual(fields["has_rival"]?.valueKind, .bool)
        XCTAssertNil(fields["object_events"])
        XCTAssertNil(fields["metadata"])

        let nestedPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:\(eventPath)",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "object_events.0.id", value: "2")]
            )
        )
        XCTAssertTrue(nestedPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertTrue(nestedPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(nestedPlan.editPlan.validateApplyability().isApplyable)

        let plan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:\(eventPath)",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "event_id", value: "15"),
                    NDSDataSemanticFieldEdit(key: "weather", value: "RAIN"),
                    NDSDataSemanticFieldEdit(key: "has_rival", value: "false")
                ]
            )
        )

        XCTAssertTrue(plan.diagnostics.allSatisfy { $0.severity != .error }, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"event_id\":15"))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"weather\":\"RAIN\""))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"has_rival\":false"))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"object_events\":[{\"id\":1,\"script\":\"Route201_Rival\"}]"))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"metadata\":{\"map\":\"ROUTE_201\"}"))
        XCTAssertEqual(plan.editPlan.changes.count, 1)
        XCTAssertTrue(plan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: plan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(eventPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"event_id\":15"))
        XCTAssertTrue(updated.contains("\"weather\":\"RAIN\""))
        XCTAssertTrue(updated.contains("\"has_rival\":false"))
        XCTAssertTrue(updated.contains("\"object_events\":[{\"id\":1,\"script\":\"Route201_Rival\"}]"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let nestedPathSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:\(nestedPath)")
        XCTAssertFalse(nestedPathSnapshot.canEdit)
        XCTAssertTrue(nestedPathSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(nestedPathSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })

        let textSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:\(textPath)")
        XCTAssertFalse(textSnapshot.canEdit)
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(textSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let matrixSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:files/fielddata/mapmatrix/matrix.bin")
        XCTAssertFalse(matrixSnapshot.canEdit)
        XCTAssertTrue(matrixSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(matrixSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(matrixSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let tableSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:files/fielddata/maptable/map.bin")
        XCTAssertFalse(tableSnapshot.canEdit)
        XCTAssertTrue(tableSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(tableSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(tableSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let landDataRootSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:files/fielddata/land_data")
        XCTAssertFalse(landDataRootSnapshot.canEdit)
        XCTAssertTrue(landDataRootSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(landDataRootSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
    }

    func testNDSDataSemanticEditorPlansDiamondPearlAreaDataJSONScalars() throws {
        let root = try makeRoot(name: "pokediamond", configure: makeDiamondFixture)
        let areaDataPath = "files/fielddata/areadata/area_0002.json"
        let nestedPath = "files/fielddata/areadata/sinnoh/area_0003.json"
        let nestedLandDataPath = "files/fielddata/land_data/sinnoh/land_0002.json"
        try write(
            """
            {"area_id": 2, "name": "Route 202", "enabled": true, "weather": null, "warps": [{"target":"Jubilife"}], "metadata": {"region":"SINNOH"}}

            """,
            to: root.appendingPathComponent(areaDataPath)
        )
        try write("{\"area_id\": 3}\n", to: root.appendingPathComponent(nestedPath))
        try write("{\"land_id\": 2}\n", to: root.appendingPathComponent(nestedLandDataPath))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let areaRecord = try XCTUnwrap(catalog.records.first { $0.relativePath == areaDataPath })
        XCTAssertEqual(factValue("Gen IV Source Role", in: areaRecord), "dpAreaDataSemanticScalars")
        XCTAssertEqual(factValue("Gen IV Readiness", in: areaRecord), "semanticJSONScalars")
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: areaRecord)?.contains("NARC/container work") == true)
        XCTAssertTrue(factValue("Gen IV Action State", in: areaRecord)?.contains("semantic mutation-plan gate") == true)
        XCTAssertTrue(areaRecord.diagnostics.contains { $0.code == "NDS_DATA_DP_AREA_DATA_SEMANTIC_SCALARS" })
        XCTAssertTrue(areaRecord.diagnostics.contains { $0.code == "NDS_DATA_DP_AREA_DATA_WRITE_LIMITED" })

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:\(areaDataPath)")
        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(snapshot.fields.contains { $0.key == "area_id" && $0.value == "2" && $0.valueKind == .number })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "name" && $0.value == "Route 202" && $0.valueKind == .string })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "enabled" && $0.value == "true" && $0.valueKind == .bool })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "weather" && $0.value == "null" && $0.valueKind == .null })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "warps" })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "metadata" })

        let nestedPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:\(areaDataPath)",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "warps.0.target", value: "Oreburgh")]
            )
        )
        XCTAssertTrue(nestedPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertTrue(nestedPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(nestedPlan.editPlan.validateApplyability().isApplyable)

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:\(areaDataPath)",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "area_id", value: "5"),
                    NDSDataSemanticFieldEdit(key: "name", value: "Route 202 North"),
                    NDSDataSemanticFieldEdit(key: "enabled", value: "false"),
                    NDSDataSemanticFieldEdit(key: "weather", value: "null")
                ]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"area_id\": 5"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"name\": \"Route 202 North\""))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"enabled\": false"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"weather\": null"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"warps\": [{\"target\":\"Jubilife\"}]"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"metadata\": {\"region\":\"SINNOH\"}"))
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(areaDataPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"area_id\": 5"))
        XCTAssertTrue(updated.contains("\"name\": \"Route 202 North\""))
        XCTAssertTrue(updated.contains("\"enabled\": false"))
        XCTAssertTrue(updated.contains("\"weather\": null"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let invalidPlan = NDSDataSemanticEditor.plan(
            catalog: try NDSDataCatalogBuilder.build(path: root.path),
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:\(areaDataPath)",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "area_id", value: "AREA_TWO")]
            )
        )
        XCTAssertTrue(invalidPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_VALUE_INVALID" })
        XCTAssertTrue(invalidPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(invalidPlan.editPlan.validateApplyability().isApplyable)

        let nestedPathSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:\(nestedPath)")
        XCTAssertFalse(nestedPathSnapshot.canEdit)
        XCTAssertTrue(nestedPathSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(nestedPathSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })

        let binarySnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:files/fielddata/areadata/area_0001.bin")
        XCTAssertFalse(binarySnapshot.canEdit)
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let landDataSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:\(nestedLandDataPath)")
        XCTAssertFalse(landDataSnapshot.canEdit)
        XCTAssertTrue(landDataSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(landDataSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
    }

    func testNDSDataSemanticEditorPlansDiamondPearlLandDataJSONScalars() throws {
        let root = try makeRoot(name: "pokediamond", configure: makeDiamondFixture)
        let landDataPath = "files/fielddata/land_data/land_0002.json"
        let nestedPath = "files/fielddata/land_data/sinnoh/land_0003.json"
        try write(
            """
            {"land_id": 2, "name": "Route 202 Land", "enabled": true, "weather": null, "tiles": [{"terrain":"grass"}], "metadata": {"region":"SINNOH"}}

            """,
            to: root.appendingPathComponent(landDataPath)
        )
        try write("{\"land_id\": 3}\n", to: root.appendingPathComponent(nestedPath))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let landRecord = try XCTUnwrap(catalog.records.first { $0.relativePath == landDataPath })
        XCTAssertEqual(factValue("Gen IV Source Role", in: landRecord), "dpLandDataSemanticScalars")
        XCTAssertEqual(factValue("Gen IV Readiness", in: landRecord), "semanticJSONScalars")
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: landRecord)?.contains("NARC/container work") == true)
        XCTAssertTrue(factValue("Gen IV Action State", in: landRecord)?.contains("semantic mutation-plan gate") == true)
        XCTAssertTrue(landRecord.diagnostics.contains { $0.code == "NDS_DATA_DP_LAND_DATA_SEMANTIC_SCALARS" })
        XCTAssertTrue(landRecord.diagnostics.contains { $0.code == "NDS_DATA_DP_LAND_DATA_WRITE_LIMITED" })

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:\(landDataPath)")
        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(snapshot.fields.contains { $0.key == "land_id" && $0.value == "2" && $0.valueKind == .number })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "name" && $0.value == "Route 202 Land" && $0.valueKind == .string })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "enabled" && $0.value == "true" && $0.valueKind == .bool })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "weather" && $0.value == "null" && $0.valueKind == .null })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "tiles" })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "metadata" })

        let nestedPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:\(landDataPath)",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "tiles.0.terrain", value: "sand")]
            )
        )
        XCTAssertTrue(nestedPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertTrue(nestedPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(nestedPlan.editPlan.validateApplyability().isApplyable)

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:\(landDataPath)",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "land_id", value: "5"),
                    NDSDataSemanticFieldEdit(key: "name", value: "Route 202 North Land"),
                    NDSDataSemanticFieldEdit(key: "enabled", value: "false"),
                    NDSDataSemanticFieldEdit(key: "weather", value: "null")
                ]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"land_id\": 5"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"name\": \"Route 202 North Land\""))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"enabled\": false"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"weather\": null"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"tiles\": [{\"terrain\":\"grass\"}]"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"metadata\": {\"region\":\"SINNOH\"}"))
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(landDataPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"land_id\": 5"))
        XCTAssertTrue(updated.contains("\"name\": \"Route 202 North Land\""))
        XCTAssertTrue(updated.contains("\"enabled\": false"))
        XCTAssertTrue(updated.contains("\"weather\": null"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let invalidPlan = NDSDataSemanticEditor.plan(
            catalog: try NDSDataCatalogBuilder.build(path: root.path),
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:\(landDataPath)",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "land_id", value: "LAND_TWO")]
            )
        )
        XCTAssertTrue(invalidPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_VALUE_INVALID" })
        XCTAssertTrue(invalidPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(invalidPlan.editPlan.validateApplyability().isApplyable)

        let nestedPathSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:\(nestedPath)")
        XCTAssertFalse(nestedPathSnapshot.canEdit)
        XCTAssertTrue(nestedPathSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(nestedPathSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })

        let binarySnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:files/fielddata/land_data/land_0001.bin")
        XCTAssertFalse(binarySnapshot.canEdit)
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticEditorPlansDiamondPearlMapHeaderCScalars() throws {
        let root = try makeRoot(name: "pokediamond", configure: makeDiamondFixture)
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:arm9/src/map_header.c")

        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        let fields = Dictionary(uniqueKeysWithValues: snapshot.fields.map { ($0.key, $0) })
        XCTAssertNil(fields["mapHeaders.0.areaDataBank"])
        XCTAssertEqual(fields["mapHeaders.0.moveModelBank"]?.value, "20")
        XCTAssertEqual(fields["mapHeaders.0.wildEncounterBank"]?.value, "0xFFFF")
        XCTAssertEqual(fields["mapHeaders.0.weatherType"]?.value, "0")
        XCTAssertEqual(fields["mapHeaders.0.cameraType"]?.value, "4")
        XCTAssertEqual(fields["mapHeaders.0.mapType"]?.value, "4")
        XCTAssertEqual(fields["mapHeaders.0.battleBg"]?.value, "6")
        XCTAssertEqual(fields["mapHeaders.0.weatherType"]?.valueKind, .number)
        XCTAssertNil(fields["mapHeaders.0.isBikeAllowed"])
        XCTAssertEqual(fields["mapHeaders.1.areaDataBank"]?.value, "1")
        XCTAssertEqual(fields["mapHeaders.1.isFlyAllowed"]?.value, "1")
        XCTAssertNil(fields["mapHeaders.2.areaDataBank"])
        XCTAssertTrue(snapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_C_SCALAR_UNSUPPORTED" })
        XCTAssertTrue(snapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_C_ROW_BAD_SHAPE" })

        let plan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:arm9/src/map_header.c",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "mapHeaders.0.weatherType", value: "14"),
                    NDSDataSemanticFieldEdit(key: "mapHeaders.0.cameraType", value: "3"),
                    NDSDataSemanticFieldEdit(key: "mapHeaders.0.battleBg", value: "9"),
                    NDSDataSemanticFieldEdit(key: "mapHeaders.1.areaDataBank", value: "8")
                ]
            )
        )

        XCTAssertTrue(plan.diagnostics.allSatisfy { $0.severity != .error }, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(plan.textDraft.editedText.contains("MAPSEC_JUBILIFE_CITY, 14, 3, 4, 9, TRUE"))
        XCTAssertTrue(plan.textDraft.editedText.contains("{ 8, 2, 3, 4, 5, 6"))
        XCTAssertTrue(plan.textDraft.editedText.contains("{ 1, 2, 3 },"))
        XCTAssertEqual(plan.editPlan.changes.count, 1)
        XCTAssertTrue(plan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: plan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("arm9/src/map_header.c"), encoding: .utf8)
        XCTAssertTrue(updated.contains("MAPSEC_JUBILIFE_CITY, 14, 3, 4, 9, TRUE"))
        XCTAssertTrue(updated.contains("{ 8, 2, 3, 4, 5, 6"))
        XCTAssertTrue(updated.contains("void MapHeader_Load(void) {}"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let invalidPlan = NDSDataSemanticEditor.plan(
            catalog: try NDSDataCatalogBuilder.build(path: root.path),
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:arm9/src/map_header.c",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "mapHeaders.0.weatherType", value: "MAP_WEATHER_RAIN")
                ]
            )
        )
        XCTAssertTrue(invalidPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_VALUE_INVALID" })
        XCTAssertTrue(invalidPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(invalidPlan.editPlan.validateApplyability().isApplyable)

        let booleanPlan = NDSDataSemanticEditor.plan(
            catalog: try NDSDataCatalogBuilder.build(path: root.path),
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:arm9/src/map_header.c",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "mapHeaders.0.isBikeAllowed", value: "FALSE")
                ]
            )
        )
        XCTAssertTrue(booleanPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FIELD_MISSING" })
        XCTAssertTrue(booleanPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(booleanPlan.editPlan.validateApplyability().isApplyable)

        let matrixSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:files/fielddata/mapmatrix/matrix.bin")
        XCTAssertFalse(matrixSnapshot.canEdit)
        XCTAssertTrue(matrixSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        let areaRootSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:files/fielddata/areadata")
        XCTAssertFalse(areaRootSnapshot.canEdit)
        XCTAssertTrue(areaRootSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        let scriptSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "scripts:arm9/src/script.c")
        XCTAssertFalse(scriptSnapshot.canEdit)
        XCTAssertTrue(scriptSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(scriptSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_SCRIPT_PATH_BLOCKED" })
    }

    func testNDSDataSemanticEditorPlansDiamondPearlMoveCAnchorScalars() throws {
        let root = try makeRoot(name: "pokediamond", configure: makeDiamondFixture)
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "moves:arm9/src/waza.c")

        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        let fields = Dictionary(uniqueKeysWithValues: snapshot.fields.map { ($0.key, $0) })
        XCTAssertEqual(fields["waza.MOVE_TACKLE.effect"]?.value, "MOVE_EFFECT_HIT")
        XCTAssertEqual(fields["waza.MOVE_TACKLE.effect"]?.valueKind, .string)
        XCTAssertEqual(fields["waza.MOVE_TACKLE.class"]?.value, "CLASS_PHYSICAL")
        XCTAssertEqual(fields["waza.MOVE_TACKLE.power"]?.value, "35")
        XCTAssertEqual(fields["waza.MOVE_TACKLE.power"]?.valueKind, .number)
        XCTAssertEqual(fields["waza.MOVE_TACKLE.type"]?.value, "TYPE_NORMAL")
        XCTAssertEqual(fields["waza.MOVE_TACKLE.accuracy"]?.value, "95")
        XCTAssertEqual(fields["waza.MOVE_TACKLE.pp"]?.value, "35")
        XCTAssertEqual(fields["waza.MOVE_TACKLE.effectChance"]?.value, "0")
        XCTAssertEqual(fields["waza.MOVE_TACKLE.unk8"]?.value, "0x0")
        XCTAssertEqual(fields["waza.MOVE_TACKLE.priority"]?.value, "0")
        XCTAssertEqual(fields["waza.MOVE_TACKLE.unkB"]?.value, "0")
        XCTAssertEqual(fields["waza.MOVE_TACKLE.unkC"]?.value, "0")
        XCTAssertEqual(fields["waza.MOVE_TACKLE.contestType"]?.value, "CONTEST_TYPE_COOL")
        XCTAssertNil(fields["waza.MOVE_TACKLE.padding"])
        XCTAssertNil(fields["waza.MOVE_FAKE.power"])
        XCTAssertNil(fields["waza.MOVE_COMPLEX.power"])
        XCTAssertEqual(fields["waza.MOVE_COMPLEX.effect"]?.value, "MOVE_EFFECT_HIT")
        XCTAssertTrue(snapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_C_SCALAR_UNSUPPORTED" })
        XCTAssertTrue(snapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_C_ROW_BAD_SHAPE" })

        let plan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "moves:arm9/src/waza.c",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "waza.MOVE_TACKLE.effect", value: "MOVE_EFFECT_QUICK_ATTACK"),
                    NDSDataSemanticFieldEdit(key: "waza.MOVE_TACKLE.class", value: "CLASS_SPECIAL"),
                    NDSDataSemanticFieldEdit(key: "waza.MOVE_TACKLE.power", value: "40"),
                    NDSDataSemanticFieldEdit(key: "waza.MOVE_TACKLE.type", value: "TYPE_FIGHTING")
                ]
            )
        )

        XCTAssertTrue(plan.diagnostics.allSatisfy { $0.severity != .error }, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(plan.textDraft.editedText.contains(".effect = MOVE_EFFECT_QUICK_ATTACK"))
        XCTAssertTrue(plan.textDraft.editedText.contains(".class = CLASS_SPECIAL"))
        XCTAssertTrue(plan.textDraft.editedText.contains(".power = 40"))
        XCTAssertTrue(plan.textDraft.editedText.contains(".type = TYPE_FIGHTING"))
        XCTAssertTrue(plan.textDraft.editedText.contains("ReadWholeNarcMemberByIdPair"))
        XCTAssertTrue(plan.textDraft.editedText.contains("MOVE_FAKE"))
        XCTAssertEqual(plan.editPlan.changes.count, 1)
        XCTAssertTrue(plan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: plan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("arm9/src/waza.c"), encoding: .utf8)
        XCTAssertTrue(updated.contains(".effect = MOVE_EFFECT_QUICK_ATTACK"))
        XCTAssertTrue(updated.contains(".class = CLASS_SPECIAL"))
        XCTAssertTrue(updated.contains(".power = 40"))
        XCTAssertTrue(updated.contains(".type = TYPE_FIGHTING"))
        XCTAssertTrue(updated.contains("ReadWholeNarcMemberByIdPair"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        for invalidValue in ["MOVE_EFFECT(1)", "(MOVE_EFFECT_HIT)", "20 + 10", "{ 1 }", "\"MOVE_EFFECT_HIT\""] {
            let invalidPlan = NDSDataSemanticEditor.plan(
                catalog: try NDSDataCatalogBuilder.build(path: root.path),
                draft: NDSDataSemanticEditDraft(
                    recordID: "moves:arm9/src/waza.c",
                    fieldEdits: [
                        NDSDataSemanticFieldEdit(key: "waza.MOVE_TACKLE.effect", value: invalidValue)
                    ]
                )
            )
            XCTAssertTrue(invalidPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_VALUE_INVALID" }, invalidValue)
            XCTAssertTrue(invalidPlan.editPlan.changes.isEmpty, invalidValue)
            XCTAssertFalse(invalidPlan.editPlan.validateApplyability().isApplyable, invalidValue)
        }

        let duplicatePlan = NDSDataSemanticEditor.plan(
            catalog: try NDSDataCatalogBuilder.build(path: root.path),
            draft: NDSDataSemanticEditDraft(
                recordID: "moves:arm9/src/waza.c",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "waza.MOVE_TACKLE.power", value: "50"),
                    NDSDataSemanticFieldEdit(key: "waza.MOVE_TACKLE.power", value: "60")
                ]
            )
        )
        XCTAssertTrue(duplicatePlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FIELD_DUPLICATE" })
        XCTAssertTrue(duplicatePlan.editPlan.changes.isEmpty)
        XCTAssertFalse(duplicatePlan.editPlan.validateApplyability().isApplyable)

        let missingPlan = NDSDataSemanticEditor.plan(
            catalog: try NDSDataCatalogBuilder.build(path: root.path),
            draft: NDSDataSemanticEditDraft(
                recordID: "moves:arm9/src/waza.c",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "waza.MOVE_TACKLE.padding", value: "1"),
                    NDSDataSemanticFieldEdit(key: "waza.MOVE_MISSING.power", value: "40")
                ]
            )
        )
        XCTAssertTrue(missingPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FIELD_MISSING" })
        XCTAssertTrue(missingPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(missingPlan.editPlan.validateApplyability().isApplyable)

        let encounterPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "encounters:arm9/src/encounter.c",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "waza.MOVE_TACKLE.power", value: "40")
                ]
            )
        )
        XCTAssertTrue(encounterPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(encounterPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_ENCOUNTER_PATH_BLOCKED" })
        XCTAssertTrue(encounterPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
        XCTAssertTrue(encounterPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(encounterPlan.editPlan.validateApplyability().isApplyable)
    }

    func testNDSDataSemanticEditorPlansDiamondPearlItemCAnchorScalars() throws {
        let root = try makeRoot(name: "pokediamond", configure: makeDiamondFixture)
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "items:arm9/src/itemtool.c")

        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        let fields = Dictionary(uniqueKeysWithValues: snapshot.fields.map { ($0.key, $0) })
        XCTAssertEqual(fields["itemIndexMappings.1.itemDataIndex"]?.value, "1")
        XCTAssertEqual(fields["itemIndexMappings.1.iconIndex"]?.value, "2")
        XCTAssertEqual(fields["itemIndexMappings.1.paletteIndex"]?.value, "3")
        XCTAssertEqual(fields["itemIndexMappings.1.gen3Index"]?.value, "1")
        XCTAssertEqual(fields["itemIndexMappings.1.itemDataIndex"]?.valueKind, .number)
        XCTAssertNil(fields["itemIndexMappings.2.itemDataIndex"])
        XCTAssertEqual(fields["itemIndexMappings.2.iconIndex"]?.value, "4")
        XCTAssertTrue(snapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_C_SCALAR_UNSUPPORTED" })

        let plan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "items:arm9/src/itemtool.c",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "itemIndexMappings.1.itemDataIndex", value: "42"),
                    NDSDataSemanticFieldEdit(key: "itemIndexMappings.1.iconIndex", value: "24"),
                    NDSDataSemanticFieldEdit(key: "itemIndexMappings.1.paletteIndex", value: "11"),
                    NDSDataSemanticFieldEdit(key: "itemIndexMappings.1.gen3Index", value: "9")
                ]
            )
        )

        XCTAssertTrue(plan.diagnostics.allSatisfy { $0.severity != .error }, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(plan.textDraft.editedText.contains("{ 42, 24, 11, 9 }"))
        XCTAssertTrue(plan.textDraft.editedText.contains("ITEM_DATA_COUNT"))
        XCTAssertEqual(plan.editPlan.changes.count, 1)
        XCTAssertTrue(plan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: plan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("arm9/src/itemtool.c"), encoding: .utf8)
        XCTAssertTrue(updated.contains("{ 42, 24, 11, 9 }"))
        XCTAssertTrue(updated.contains("void Item_Load(void) {}"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let invalidPlan = NDSDataSemanticEditor.plan(
            catalog: try NDSDataCatalogBuilder.build(path: root.path),
            draft: NDSDataSemanticEditDraft(
                recordID: "items:arm9/src/itemtool.c",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "itemIndexMappings.1.iconIndex", value: "ITEM_ICON_POTION")
                ]
            )
        )
        XCTAssertTrue(invalidPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_VALUE_INVALID" })
        XCTAssertTrue(invalidPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(invalidPlan.editPlan.validateApplyability().isApplyable)

        let binarySnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "items:files/itemtool/itemdata/item_0000.bin")
        XCTAssertFalse(binarySnapshot.canEdit)
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticEditorPlansDiamondPearlTrainerClassGenderCScalars() throws {
        let root = try makeRoot(name: "pokediamond", configure: makeDiamondFixture)
        try write(Data([0x00]), to: root.appendingPathComponent("files/poketool/trainer/trainer_0000.bin"))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "trainers:arm9/src/trainer_data.c")

        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        let fields = Dictionary(uniqueKeysWithValues: snapshot.fields.map { ($0.key, $0) })
        XCTAssertEqual(fields["trainerClassGenderCounts.0.genderCount"]?.value, "0")
        XCTAssertEqual(fields["trainerClassGenderCounts.1.genderCount"]?.value, "1")
        XCTAssertEqual(fields["trainerClassGenderCounts.2.genderCount"]?.value, "2")
        XCTAssertEqual(fields["trainerClassGenderCounts.1.genderCount"]?.valueKind, .number)
        XCTAssertNil(fields["trainerClassGenderCounts.3.genderCount"])
        XCTAssertTrue(snapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_C_SCALAR_UNSUPPORTED" })

        let plan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "trainers:arm9/src/trainer_data.c",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "trainerClassGenderCounts.0.genderCount", value: "1"),
                    NDSDataSemanticFieldEdit(key: "trainerClassGenderCounts.2.genderCount", value: "0")
                ]
            )
        )

        XCTAssertTrue(plan.diagnostics.allSatisfy { $0.severity != .error }, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(plan.textDraft.editedText.contains("/*TRAINER_CLASS_PKMN_TRAINER_M*/ 1"))
        XCTAssertTrue(plan.textDraft.editedText.contains("/*TRAINER_CLASS_TWINS*/ 0"))
        XCTAssertTrue(plan.textDraft.editedText.contains("TRAINER_CLASS_GENDER_COUNT_SENTINEL"))
        XCTAssertEqual(plan.editPlan.changes.count, 1)
        XCTAssertTrue(plan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: plan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("arm9/src/trainer_data.c"), encoding: .utf8)
        XCTAssertTrue(updated.contains("/*TRAINER_CLASS_PKMN_TRAINER_M*/ 1"))
        XCTAssertTrue(updated.contains("/*TRAINER_CLASS_TWINS*/ 0"))
        XCTAssertTrue(updated.contains("void Trainer_Load(void) {}"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

        let invalidPlan = NDSDataSemanticEditor.plan(
            catalog: try NDSDataCatalogBuilder.build(path: root.path),
            draft: NDSDataSemanticEditDraft(
                recordID: "trainers:arm9/src/trainer_data.c",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "trainerClassGenderCounts.1.genderCount", value: "TRAINER_CLASS_GENDER_COUNT_FEMALE")
                ]
            )
        )
        XCTAssertTrue(invalidPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_VALUE_INVALID" })
        XCTAssertTrue(invalidPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(invalidPlan.editPlan.validateApplyability().isApplyable)

        let binarySnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "trainers:files/poketool/trainer/trainer_0000.bin")
        XCTAssertFalse(binarySnapshot.canEdit)
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(binarySnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
    }

    func testNDSDataSemanticEditorKeepsNonPlatinumAndContainerRowsBlocked() throws {
        let platinum = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let platinumCatalog = try NDSDataCatalogBuilder.build(path: platinum.path)
        let narcSnapshot = NDSDataSemanticEditor.snapshot(catalog: platinumCatalog, recordID: "personal:res/prebuilt/poketool/personal/personal.narc")
        XCTAssertFalse(narcSnapshot.canEdit)
        XCTAssertTrue(narcSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let heartGold = try makeRoot(name: "pokeheartgold", configure: makeHeartGoldFixture)
        try write("id,name\n1,NESTED\n", to: heartGold.appendingPathComponent("files/itemtool/itemdata/nested/item_data.csv"))
        let heartGoldCatalog = try NDSDataCatalogBuilder.build(path: heartGold.path)
        let heartGoldItemSnapshot = NDSDataSemanticEditor.snapshot(catalog: heartGoldCatalog, recordID: "items:files/itemtool/itemdata/nested/item_data.csv")
        XCTAssertFalse(heartGoldItemSnapshot.canEdit)
        XCTAssertTrue(heartGoldItemSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })

        let diamond = try makeRoot(name: "pokediamond", configure: makeDiamondFixture)
        let diamondCatalog = try NDSDataCatalogBuilder.build(path: diamond.path)
        let diamondSnapshot = NDSDataSemanticEditor.snapshot(catalog: diamondCatalog, recordID: "species:arm9/src/pokemon.c")
        XCTAssertFalse(diamondSnapshot.canEdit)
        XCTAssertTrue(diamondSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_PROFILE_BLOCKED" })

        let pmd = try makeRoot(name: "pmd-sky", configure: makePMDSkyFixture)
        let pmdCatalog = try NDSDataCatalogBuilder.build(path: pmd.path)
        let pmdSnapshot = NDSDataSemanticEditor.snapshot(catalog: pmdCatalog, recordID: "resources:files/MESSAGE/text_us.str")
        XCTAssertFalse(pmdSnapshot.canEdit)
        XCTAssertTrue(pmdSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_PROFILE_BLOCKED" })
    }

    func testNDSDataSemanticCoverageReportSummarizesEligibleCountsAndBlockedBuckets() throws {
        let platinum = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let platinumCatalog = try NDSDataCatalogBuilder.build(path: platinum.path)

        let report = NDSDataSemanticCoverageReportBuilder.build(catalog: platinumCatalog)

        XCTAssertEqual(report.profile, .pokeplatinum)
        XCTAssertEqual(report.family, .platinum)
        XCTAssertEqual(report.rootPath, platinum.path)
        XCTAssertEqual(report.summary.catalogRows, platinumCatalog.records.count)
        XCTAssertGreaterThan(report.summary.scannedRows, 0)
        XCTAssertGreaterThan(report.summary.eligibleRows, 0)
        XCTAssertGreaterThan(report.summary.eligibleFields, 0)
        XCTAssertGreaterThan(report.summary.blockedRows, 0)
        XCTAssertGreaterThan(report.summary.skippedRows, 0)
        XCTAssertGreaterThan(report.fieldKindCounts.first { $0.kind == .number }?.count ?? 0, 0)
        XCTAssertGreaterThan(report.fieldKindCounts.first { $0.kind == .string }?.count ?? 0, 0)
        XCTAssertGreaterThan(report.fieldKindCounts.first { $0.kind == .bool }?.count ?? 0, 0)
        XCTAssertTrue(report.domainSummaries.contains { $0.domain == .species && $0.eligibleRows > 0 && $0.eligibleFields > 0 })

        let speciesRow = try XCTUnwrap(report.rows.first { $0.id == "species:res/pokemon/abra/data.json" })
        XCTAssertEqual(speciesRow.status, .eligible)
        XCTAssertGreaterThan(speciesRow.fieldCount, 0)
        XCTAssertGreaterThan(speciesRow.fieldKindCounts.first { $0.kind == .number }?.count ?? 0, 0)
        XCTAssertNil(speciesRow.skipReason)

        let textRow = try XCTUnwrap(report.rows.first { $0.id == "text:res/text/route201.txt" })
        XCTAssertEqual(textRow.status, .eligible)
        XCTAssertGreaterThan(textRow.fieldKindCounts.first { $0.kind == .string }?.count ?? 0, 0)

        let containerRow = try XCTUnwrap(report.rows.first { $0.id == "personal:res/prebuilt/poketool/personal/personal.narc" })
        XCTAssertEqual(containerRow.status, .skipped)
        XCTAssertEqual(containerRow.fieldCount, 0)
        XCTAssertEqual(containerRow.skipReason, "containerOrNARC")

        let generatedRow = try XCTUnwrap(report.rows.first { $0.id == "resources:generated/species.txt" })
        XCTAssertEqual(generatedRow.status, .skipped)
        XCTAssertEqual(generatedRow.fieldCount, 0)
        XCTAssertEqual(generatedRow.skipReason, "generatedReference")

        XCTAssertTrue(report.blockedReasonBuckets.contains { $0.reason == "containerOrNARC" && $0.rowCount > 0 && $0.sampleRecordIDs.contains(containerRow.id) })
        XCTAssertTrue(report.blockedReasonBuckets.contains { $0.reason == "generatedReference" && $0.rowCount > 0 && $0.sampleRecordIDs.contains(generatedRow.id) })

        let encoded = String(decoding: try JSONEncoder().encode(report), as: UTF8.self)
        XCTAssertFalse(encoded.contains("SPECIES_KADABRA"))
        XCTAssertFalse(encoded.contains("hello\\nworld"))
        XCTAssertFalse(encoded.contains("I like shorts!"))
        XCTAssertFalse(encoded.contains("NDSDataSemanticSnapshot"))

        let referenceRoot = try makeRoot(name: "references/pokeplatinum", configure: makePlatinumFixture)
        let referenceReport = NDSDataSemanticCoverageReportBuilder.build(
            catalog: try NDSDataCatalogBuilder.build(path: referenceRoot.path)
        )
        XCTAssertEqual(referenceReport.summary.scannedRows, 0)
        XCTAssertEqual(referenceReport.summary.eligibleRows, 0)
        XCTAssertTrue(referenceReport.rows.allSatisfy { $0.status == .skipped && $0.skipReason == "referenceRoot" })
        XCTAssertTrue(referenceReport.blockedReasonBuckets.contains { $0.reason == "referenceRoot" && $0.rowCount == referenceReport.summary.catalogRows })

        let black = try makeRoot(name: "pokeblack", configure: makeBlackFixture)
        let blackReport = NDSDataSemanticCoverageReportBuilder.build(
            catalog: try NDSDataCatalogBuilder.build(path: black.path)
        )
        XCTAssertEqual(blackReport.profile, .pokeblack)
        XCTAssertEqual(blackReport.summary.scannedRows, 0)
        XCTAssertEqual(blackReport.summary.eligibleRows, 0)
        XCTAssertTrue(blackReport.rows.allSatisfy { $0.status == .skipped && $0.skipReason == "genVReadOnly" })
        XCTAssertTrue(blackReport.blockedReasonBuckets.contains { $0.reason == "genVReadOnly" && $0.rowCount == blackReport.summary.catalogRows })
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

    func testNDSBlockedEditabilityRegressionKeepsUnsupportedRowsNonApplyable() throws {
        func assertBlockedPlan(
            catalog: ProjectNDSDataCatalog,
            recordID: String,
            editedText: String = "blocked\n",
            expectedDiagnostics: [String],
            file: StaticString = #filePath,
            line: UInt = #line
        ) {
            let plan = NDSDataMutationPlanner.plan(
                catalog: catalog,
                draft: NDSDataEditDraft(recordID: recordID, editedText: editedText)
            )

            XCTAssertTrue(plan.changes.isEmpty, recordID, file: file, line: line)
            XCTAssertFalse(plan.validateApplyability().isApplyable, recordID, file: file, line: line)
            for expectedCode in expectedDiagnostics {
                XCTAssertTrue(
                    plan.diagnostics.contains { $0.code == expectedCode },
                    "\(recordID) missing \(expectedCode); saw \(plan.diagnostics.map(\.code).joined(separator: ", "))",
                    file: file,
                    line: line
                )
            }
        }

        let black = try makeRoot(name: "pokeblack", configure: makeBlackFixture)
        let blackCatalog = try NDSDataCatalogBuilder.build(path: black.path)
        assertBlockedPlan(
            catalog: blackCatalog,
            recordID: "encounters:data/encounters/route_1.txt",
            expectedDiagnostics: ["NDS_GEN_V_WRITE_BLOCKED"]
        )
        let genVSnapshot = NDSDataSemanticEditor.snapshot(
            catalog: blackCatalog,
            recordID: "encounters:data/encounters/route_1.txt"
        )
        XCTAssertFalse(genVSnapshot.canEdit)
        XCTAssertTrue(genVSnapshot.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })
        XCTAssertTrue(genVSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_PROFILE_BLOCKED" })
        let genVSemanticPlan = NDSDataSemanticEditor.plan(
            catalog: blackCatalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "encounters:data/encounters/route_1.txt",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "route", value: "2")]
            )
        )
        XCTAssertTrue(genVSemanticPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(genVSemanticPlan.editPlan.validateApplyability().isApplyable)
        XCTAssertTrue(genVSemanticPlan.diagnostics.contains { $0.code == "NDS_GEN_V_WRITE_BLOCKED" })

        let romTemp = try NDSDataCatalogTemporaryDirectory()
        temporaryDirectories.append(romTemp)
        let rom = romTemp.url.appendingPathComponent("diamond.nds")
        try syntheticNDSROM().write(to: rom)
        let romCatalog = try NDSDataCatalogBuilder.build(path: rom.path)
        assertBlockedPlan(
            catalog: romCatalog,
            recordID: "resources:sub/child.narc",
            expectedDiagnostics: ["NDS_DATA_EDIT_BINARY_ROM_BLOCKED"]
        )

        let platinum = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)
        let platinumCatalog = try NDSDataCatalogBuilder.build(path: platinum.path)
        assertBlockedPlan(
            catalog: platinumCatalog,
            recordID: "personal:res/prebuilt/poketool/personal/personal.narc",
            expectedDiagnostics: [
                "NDS_DATA_EDIT_ROLE_BLOCKED",
                "NDS_DATA_EDIT_FORMAT_BLOCKED",
                "NDS_DATA_EDIT_CONTAINER_BLOCKED"
            ]
        )
        assertBlockedPlan(
            catalog: platinumCatalog,
            recordID: "resources:generated/species.txt",
            expectedDiagnostics: ["NDS_DATA_EDIT_ROLE_BLOCKED"]
        )

        let referenceRoot = try makeRoot(name: "references/pokeplatinum", configure: makePlatinumFixture)
        let referenceCatalog = try NDSDataCatalogBuilder.build(path: referenceRoot.path)
        assertBlockedPlan(
            catalog: referenceCatalog,
            recordID: "species:res/pokemon/abra/data.json",
            editedText: "{\"base_hp\":26}\n",
            expectedDiagnostics: ["NDS_DATA_EDIT_REFERENCE_BLOCKED"]
        )

        let pmd = try makeRoot(name: "pmd-sky", configure: makePMDSkyFixture)
        let pmdCatalog = try NDSDataCatalogBuilder.build(path: pmd.path)
        assertBlockedPlan(
            catalog: pmdCatalog,
            recordID: "resources:files/MESSAGE/text_us.str",
            expectedDiagnostics: ["NDS_DATA_EDIT_SPINOFF_BLOCKED"]
        )
        let pmdSnapshot = NDSDataSemanticEditor.snapshot(
            catalog: pmdCatalog,
            recordID: "resources:files/MESSAGE/text_us.str"
        )
        XCTAssertFalse(pmdSnapshot.canEdit)
        XCTAssertTrue(pmdSnapshot.diagnostics.contains { $0.code == "NDS_DATA_EDIT_SPINOFF_BLOCKED" })
        XCTAssertTrue(pmdSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_PROFILE_BLOCKED" })
    }

    func testNDSDataMutationPlanBlocksReferenceRoots() throws {
        let directCentral = try makeRoot(name: "reference-repos/repos/pret__pokeplatinum", configure: makePlatinumFixture)
        let repoLocal = try makeRoot(name: "references/pokeplatinum", configure: makePlatinumFixture)
        let symlinkReference = try makeRoot(name: "reference-repos/repos/symlink-target-pokeplatinum", configure: makePlatinumFixture)
        let symlinkContainer = try NDSDataCatalogTemporaryDirectory()
        temporaryDirectories.append(symlinkContainer)
        let symlinkRoot = symlinkContainer.url.appendingPathComponent("linked-pokeplatinum")
        try FileManager.default.createSymbolicLink(at: symlinkRoot, withDestinationURL: symlinkReference)

        for root in [directCentral, repoLocal, symlinkRoot] {
            let catalog = try NDSDataCatalogBuilder.build(path: root.path)
            let recordID = try XCTUnwrap(catalog.records.first { $0.domain == .species && $0.role == .sourceTree }?.id)
            let plan = NDSDataMutationPlanner.plan(
                catalog: catalog,
                draft: NDSDataEditDraft(recordID: recordID, editedText: "{\"base_hp\":26}\n")
            )

            XCTAssertTrue(plan.changes.isEmpty, root.path)
            XCTAssertTrue(plan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_REFERENCE_BLOCKED" }, root.path)
        }

        let similarlyNamedEditable = try makeRoot(name: "my-references-work/pokeplatinum", configure: makePlatinumFixture)
        let editableCatalog = try NDSDataCatalogBuilder.build(path: similarlyNamedEditable.path)
        let editableRecordID = try XCTUnwrap(editableCatalog.records.first { $0.domain == .species && $0.role == .sourceTree }?.id)
        let editablePlan = NDSDataMutationPlanner.plan(
            catalog: editableCatalog,
            draft: NDSDataEditDraft(recordID: editableRecordID, editedText: "{\"base_hp\":26}\n")
        )
        XCTAssertFalse(editablePlan.diagnostics.contains { $0.code == "NDS_DATA_EDIT_REFERENCE_BLOCKED" })
        XCTAssertEqual(editablePlan.changes.count, 1)
    }

    func testNDSDataMutationApplyBlocksSymlinkEscapedSourcePath() throws {
        let temp = try NDSDataCatalogTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent("pokediamond")
        let outside = temp.url.appendingPathComponent("outside")
        try makeDirectory(root)
        try makeDirectory(outside)
        let outsideFile = outside.appendingPathComponent("item.json")
        let original = Data(#"{"name":"POTION"}"#.utf8)
        let edited = Data(#"{"name":"SUPER_POTION"}"#.utf8)
        try write(original, to: outsideFile)
        try FileManager.default.createSymbolicLink(
            at: root.appendingPathComponent("linked"),
            withDestinationURL: outside
        )

        let plan = NDSDataEditPlan(
            rootPath: root.path,
            recordID: "items:linked/item.json",
            draft: NDSDataEditDraft(recordID: "items:linked/item.json", editedText: #"{"name":"SUPER_POTION"}"#),
            changes: [
                NDSDataEditFileChange(
                    path: "linked/item.json",
                    summary: "Attempt escaped symlink write",
                    originalSHA1: pokemonHackSHA1Hex(original),
                    originalByteCount: original.count,
                    newByteCount: edited.count,
                    textPreview: #"{"name":"SUPER_POTION"}"#,
                    newData: edited
                )
            ],
            diagnostics: [],
            mutationPlan: MutationPlan(title: "Apply escaped write", summary: "Test plan"),
            backupRelativeRoot: ".pokemonhackstudio/backups/test"
        )

        let applyability = plan.validateApplyability()
        XCTAssertFalse(applyability.isApplyable)
        XCTAssertTrue(applyability.diagnostics.contains { $0.code == "NDS_DATA_APPLY_PATH_SYMLINK_OUTSIDE_ROOT" })

        let result = try NDSDataMutationApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.count, 0)
        XCTAssertTrue(result.diagnostics.contains { $0.code == "NDS_DATA_APPLY_PATH_SYMLINK_OUTSIDE_ROOT" })
        XCTAssertEqual(try Data(contentsOf: outsideFile), original)
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(".pokemonhackstudio/backups/test").path))
    }

    private func assertEncounterJSONRowOperationsPreserveUnknownFieldsObjectOrderAndOuterFormatting(
        rootName: String,
        configure: (URL) throws -> Void,
        encounterPath: String,
        arrayKey: String,
        firstRow: String,
        secondRow: String,
        insertedRow: String
    ) throws {
        let root = try makeRoot(name: rootName, configure: configure)
        let source = """
        {
          "zeta_unknown": "kept-before",
          "\(arrayKey)": [
            \(firstRow),
            \(secondRow)
          ],
          "swarms": [
            "UNCHANGED_ONE",
            "UNCHANGED_TWO"
          ],
          "map_category": {
            "map_type": "field",
            "map_number": 12
          },
          "alpha_unknown": "kept-after"
        }

        """
        try write(source, to: root.appendingPathComponent(encounterPath))
        let original = try String(contentsOf: root.appendingPathComponent(encounterPath), encoding: .utf8)
        let prefixMarker = "  \"\(arrayKey)\": "
        let suffixMarker = ",\n  \"swarms\":"
        let originalPrefixEnd = try XCTUnwrap(original.range(of: prefixMarker)?.upperBound)
        let originalSuffixStart = try XCTUnwrap(original.range(of: suffixMarker, range: originalPrefixEnd..<original.endIndex)?.lowerBound)
        let originalPrefix = String(original[..<originalPrefixEnd])
        let originalSuffix = String(original[originalSuffixStart...])
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let plan = NDSDataEncounterJSONRowOperationPlanner.plan(
            catalog: catalog,
            draft: NDSDataEncounterJSONRowOperationDraft(
                recordID: "encounters:\(encounterPath)",
                arrayKey: arrayKey,
                operations: [
                    .insert(index: 1, rowText: insertedRow),
                    .delete(index: 0),
                    .reorder(fromIndex: 1, toIndex: 0)
                ]
            )
        )

        XCTAssertTrue(plan.diagnostics.allSatisfy { $0.severity != .error }, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertEqual(plan.beforeRowCount, 2)
        XCTAssertEqual(plan.afterRowCount, 2)
        XCTAssertTrue(plan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: plan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(encounterPath), encoding: .utf8)
        let updatedPrefixEnd = try XCTUnwrap(updated.range(of: prefixMarker)?.upperBound)
        let updatedSuffixStart = try XCTUnwrap(updated.range(of: suffixMarker, range: updatedPrefixEnd..<updated.endIndex)?.lowerBound)

        XCTAssertEqual(String(updated[..<updatedPrefixEnd]), originalPrefix)
        XCTAssertEqual(String(updated[updatedSuffixStart...]), originalSuffix)
        let expectedArray = "  \"\(arrayKey)\": [\n    \(secondRow),\n    \(insertedRow)\n  ]"
        XCTAssertTrue(
            updated.contains(expectedArray),
            updated
        )
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
        try write("{\"name\":\"POTION\",\"price\":300,\"field_use\":true,\"effects\":[{\"kind\":\"heal\",\"amount\":20}]}\n", to: root.appendingPathComponent("files/itemtool/itemdata/potion.json"))
        try write("{\"id\":1,\"name\":\"Youngster Joey\",\"double_battle\":false,\"party\":[{\"species\":\"RATTATA\",\"level\":4}]}\n", to: root.appendingPathComponent("files/poketool/trainer/trainers.json"))
        try write("[{\"slot\":1}]\n", to: root.appendingPathComponent("files/fielddata/encountdata/gs_enc_data.json"))
        try write("{\"zone\":1}\n", to: root.appendingPathComponent("files/fielddata/eventdata/zone_event/zone_001.json"))
        try write("message\n", to: root.appendingPathComponent("files/msgdata/msg/0001.txt"))
        try write(Data("SDAT".utf8) + Data(repeating: 0, count: 12), to: root.appendingPathComponent("files/data/sound/sound_data.sdat"))
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

            /* static const u16 sItemIndexMappings[][4] = {
                { 99, 99, 99, 99 },
            }; */
            static const char *sItemIndexMappingsDebug = "sItemIndexMappings { { 88, 88, 88, 88 } }";

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

            /* static const u8 sTrainerClassGenderCountTbl[] = {
                9,
            }; */
            static const char *sTrainerClassGenderCountTblDebug = "sTrainerClassGenderCountTbl { 8 }";

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

            /* static const struct MapHeader sMapHeaders[] = {
                { 99, 99, 99 },
            }; */
            static const char *sMapHeadersDebug = "sMapHeaders { { 88, 88, 88 } }";

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
        try write(#"{"name":"POTION\nTAB\t\u00e9","description":"quoted \"text\" and slash \\","price":300}"# + "\n", to: root.appendingPathComponent("files/itemtool/itemdata/escaped.json"))
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

    private func makeBlackFixture(root: URL) throws {
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

    private func factValue(_ label: String, in record: NDSDataCatalogRecord) -> String? {
        record.facts.first { $0.label == label }?.value
    }

    private func factValue(_ label: String, in facts: [SourceIndexFact]) -> String? {
        facts.first { $0.label == label }?.value
    }

    private func assertNoGenVSourceDataSemanticFacts(_ record: NDSDataCatalogRecord, file: StaticString = #filePath, line: UInt = #line) {
        let semanticLabels = ["Base HP", "Catch Rate", "Power", "PP", "Price", "Party Count", "Decoded Strings", "Text Samples"]
        for label in semanticLabels {
            XCTAssertNil(factValue(label, in: record), file: file, line: line)
        }
        XCTAssertFalse(record.facts.contains { $0.label.localizedCaseInsensitiveContains("Semantic") }, file: file, line: line)
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
