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

        let tableRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/fielddata/maptable" })
        XCTAssertEqual(tableRoot.domain, .maps)
        XCTAssertEqual(tableRoot.format, .directory)
        XCTAssertEqual(tableRoot.recordCount, 1)
        XCTAssertEqual(factValue("Gen IV Source Role", in: tableRoot), "hgssMapTableInventory")
        XCTAssertEqual(factValue("Gen IV Source Provenance", in: tableRoot), "heartGoldSoulSilver:files/fielddata/maptable")
        XCTAssertFalse(tableRoot.facts.contains { $0.label == "Migration Status" })

        let mapHeader = try XCTUnwrap(catalog.records.first { $0.relativePath == "src/data/map_headers.h" && $0.domain == .maps && $0.format == .cHeader })
        XCTAssertEqual(factValue("Gen IV Source Role", in: mapHeader), "hgssMapHeaderInventory")
        XCTAssertEqual(factValue("Gen IV Source Provenance", in: mapHeader), "heartGoldSoulSilver:src/data/map_headers.h")
        XCTAssertTrue(factValue("Gen IV Blocked Actions", in: mapHeader)?.contains("binary write") == true)
        XCTAssertTrue(mapHeader.diagnostics.contains { $0.code == "NDS_DATA_HGSS_MAP_WRITE_BLOCKED" })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "files/fielddata/eventdata/zone_event/zone_001.json" && $0.domain == .scripts })
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
        XCTAssertEqual(sourceRoot.recordCount, 1)
        XCTAssertEqual(factValue("Gen V Source Role", in: sourceRoot), "sourceCodeInventory")
        XCTAssertNil(factValue("Migration Status", in: sourceRoot))
        XCTAssertTrue(factValue("Gen V Action State", in: sourceRoot)?.contains("source inventory stays preview-only") == true)

        let assemblyRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "asm" })
        XCTAssertEqual(assemblyRoot.format, .directory)
        XCTAssertEqual(factValue("Gen V Source Role", in: assemblyRoot), "assemblyInventory")

        let headerRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "include" })
        XCTAssertEqual(headerRoot.format, .directory)
        XCTAssertEqual(factValue("Gen V Source Role", in: headerRoot), "headerInventory")

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
        XCTAssertEqual(dataRoot.recordCount, 1)
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
        let dataRootResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "data" })
        XCTAssertEqual(dataRootResourceItem.kind, "directory")
        XCTAssertTrue(dataRootResourceItem.facts.contains { $0.label == "Gen V Source Role" && $0.value == "dataInventory" })
        XCTAssertTrue(dataRootResourceItem.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertTrue(dataRootResourceItem.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        XCTAssertFalse(dataRootResourceItem.facts.contains { $0.label == "Migration Status" })

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

    func testPokeBlackCatalogSurfacesGenVMessageBankInventoryFacts() throws {
        let root = try makeRoot(name: "pokeblack", configure: makeBlackFixture)

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let messageBankRoot = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/msgdata" })
        XCTAssertEqual(messageBankRoot.id, "text:files/msgdata")
        XCTAssertEqual(messageBankRoot.domain, .text)
        XCTAssertEqual(messageBankRoot.format, .directory)
        XCTAssertEqual(messageBankRoot.recordCount, 1)
        XCTAssertNil(messageBankRoot.textBankPreview)
        XCTAssertEqual(factValue("Gen V Source Role", in: messageBankRoot), "messageBankInventory")
        XCTAssertEqual(factValue("Gen V Readiness", in: messageBankRoot), "previewOnly")
        XCTAssertEqual(factValue("Gen V Reference Posture", in: messageBankRoot), "cleanRoomReferenceOnly")
        XCTAssertTrue(factValue("Gen V Action State", in: messageBankRoot)?.contains("source inventory stays preview-only") == true)
        XCTAssertEqual(messageBankRoot.readiness?.status, .partial)
        XCTAssertTrue(messageBankRoot.readiness?.detail.contains("message-bank inventory") == true)
        XCTAssertNil(factValue("Migration Status", in: messageBankRoot))
        XCTAssertNil(factValue("Text Bank Preview", in: messageBankRoot))

        let messageBankChild = try XCTUnwrap(catalog.records.first { $0.relativePath == "files/msgdata/story/message_bank.txt" })
        XCTAssertEqual(messageBankChild.domain, .resources)
        XCTAssertEqual(factValue("Gen V Source Role", in: messageBankChild), "messageBankMetadata")
        XCTAssertNil(messageBankChild.textBankPreview)
        XCTAssertNil(factValue("Text Bank Preview", in: messageBankChild))

        let resourceIndex = GenIIIResourceRegistry.resourceIndex(path: root.path)
        let messageBankResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data text" && $0.path == "files/msgdata" })
        XCTAssertEqual(messageBankResourceItem.kind, "directory")
        XCTAssertTrue(messageBankResourceItem.facts.contains { $0.label == "Gen V Source Role" && $0.value == "messageBankInventory" })
        XCTAssertTrue(messageBankResourceItem.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertTrue(messageBankResourceItem.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        XCTAssertFalse(messageBankResourceItem.facts.contains { $0.label == "Migration Status" })
        XCTAssertFalse(messageBankResourceItem.facts.contains { $0.label == "Text Bank Preview" })

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
        XCTAssertEqual(overlayRoot.recordCount, 1)
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
        XCTAssertEqual(configRoot.recordCount, 1)
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
        XCTAssertTrue(overlayResourceItem.facts.contains { $0.label == "Gen V Source Role" && $0.value == "overlayInventory" })
        XCTAssertTrue(overlayResourceItem.facts.contains { $0.label == "Gen V Readiness" && $0.value == "previewOnly" })
        XCTAssertTrue(overlayResourceItem.facts.contains { $0.label == "Gen V Action State" && $0.value.contains("source inventory stays preview-only") })
        XCTAssertFalse(overlayResourceItem.facts.contains { $0.label == "Migration Status" })

        let configResourceItem = try XCTUnwrap(resourceIndex.items.first { $0.category == "NDS Data resources" && $0.path == "ndsdisasm_config" })
        XCTAssertEqual(configResourceItem.kind, "directory")
        XCTAssertTrue(configResourceItem.facts.contains { $0.label == "Gen V Source Role" && $0.value == "disassemblyConfigInventory" })
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
        try write("2222222222222222222222222222222222222222  pokeblack2.nds\n", to: root.appendingPathComponent("black2.us/rom.sha1"))
        try write("3333333333333333333333333333333333333333  pokewhite2.nds\n", to: root.appendingPathComponent("white2.us/rom.sha1"))
        try write("Black 2 source note\n", to: root.appendingPathComponent("black2.us/source_notes.txt"))

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let black2Title = "Pokemon - Black Version 2 (USA, Europe) (NDSi Enhanced).nds"
        let white2Title = "Pokemon - White Version 2 (USA, Europe) (NDSi Enhanced).nds"
        let makefile = try XCTUnwrap(catalog.records.first { $0.relativePath == "Makefile" })
        XCTAssertEqual(
            factValue("Gen V Variant Hash Presence", in: makefile),
            "black.us/rom.sha1=present, white.us/rom.sha1=missing, black2.us/rom.sha1=present, white2.us/rom.sha1=present"
        )
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
            {"rate": 20, "morning_rate": 10, "night_rate": 5, "enabled": true, "slots": [{"species":"BIDOOF","rate":30}]}

            """,
            to: root.appendingPathComponent("res/field/encounters/route201.json")
        )
        try write("{\"rate\": 15}\n", to: root.appendingPathComponent("res/field/encounters/nested/route202.json"))
        try write("rate=15\n", to: root.appendingPathComponent("res/field/encounters/route203.txt"))
        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        let snapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "encounters:res/field/encounters/route201.json")
        XCTAssertTrue(snapshot.canEdit, snapshot.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(snapshot.fields.contains { $0.key == "rate" && $0.value == "20" && $0.valueKind == .number })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "morning_rate" && $0.value == "10" && $0.valueKind == .number })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "night_rate" && $0.value == "5" && $0.valueKind == .number })
        XCTAssertTrue(snapshot.fields.contains { $0.key == "enabled" && $0.value == "true" && $0.valueKind == .bool })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "slots" })

        let nestedPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "encounters:res/field/encounters/route201.json",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "slots.0.rate", value: "35")]
            )
        )
        XCTAssertTrue(nestedPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertTrue(nestedPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(nestedPlan.editPlan.validateApplyability().isApplyable)

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "encounters:res/field/encounters/route201.json",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "rate", value: "25"),
                    NDSDataSemanticFieldEdit(key: "enabled", value: "false")
                ]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"rate\": 25"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"enabled\": false"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"slots\": [{\"species\":\"BIDOOF\",\"rate\":30}]"))
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent("res/field/encounters/route201.json"), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"rate\": 25"))
        XCTAssertTrue(updated.contains("\"enabled\": false"))
        XCTAssertTrue(updated.contains("\"slots\": [{\"species\":\"BIDOOF\",\"rate\":30}]"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))

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
        let areaDataPath = "res/field/area_data/route201.json"
        try write(
            """
            {"matrix": 1, "width": 32, "name": "Route 201", "enabled": true, "layout": [[1,2]], "evolutions": [["LEVEL",16,"MONFERNO"]], "metadata": {"region":"SINNOH"}}

            """,
            to: root.appendingPathComponent(matrixPath)
        )
        try write("{\"matrix\":2}\n", to: root.appendingPathComponent(nestedPath))
        try write("matrix=3\n", to: root.appendingPathComponent(textPath))
        try write("{\"area\":1}\n", to: root.appendingPathComponent(areaDataPath))
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

        let areaDataSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:\(areaDataPath)")
        XCTAssertFalse(areaDataSnapshot.canEdit)
        XCTAssertTrue(areaDataSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })

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
            {"morning_rate": 20, "day_rate": 15, "night_rate": 10, "enabled": true, "slots": [{"species":"RATTATA","rate":30}], "metadata": {"map":"ROUTE_29"}}

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
        XCTAssertFalse(snapshot.fields.contains { $0.key == "slots" })
        XCTAssertFalse(snapshot.fields.contains { $0.key == "metadata" })

        let nestedPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "encounters:\(encounterPath)",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "slots.0.rate", value: "35")]
            )
        )
        XCTAssertTrue(nestedPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertTrue(nestedPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(nestedPlan.editPlan.validateApplyability().isApplyable)

        let semanticPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "encounters:\(encounterPath)",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "morning_rate", value: "25"),
                    NDSDataSemanticFieldEdit(key: "enabled", value: "false")
                ]
            )
        )

        XCTAssertTrue(semanticPlan.diagnostics.allSatisfy { $0.severity != .error }, semanticPlan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"morning_rate\": 25"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"enabled\": false"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"slots\": [{\"species\":\"RATTATA\",\"rate\":30}]"))
        XCTAssertTrue(semanticPlan.textDraft.editedText.contains("\"metadata\": {\"map\":\"ROUTE_29\"}"))
        XCTAssertEqual(semanticPlan.editPlan.changes.count, 1)
        XCTAssertTrue(semanticPlan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(encounterPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"morning_rate\": 25"))
        XCTAssertTrue(updated.contains("\"enabled\": false"))
        XCTAssertTrue(updated.contains("\"slots\": [{\"species\":\"RATTATA\",\"rate\":30}]"))
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

        let mapHeaderSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:src/data/map_headers.h")
        XCTAssertFalse(mapHeaderSnapshot.canEdit)
        XCTAssertTrue(mapHeaderSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED" })
        XCTAssertTrue(mapHeaderSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(mapHeaderSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let mapHeaderPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "maps:src/data/map_headers.h",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "header", value: "2")]
            )
        )
        XCTAssertTrue(mapHeaderPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(mapHeaderPlan.editPlan.validateApplyability().isApplyable)

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
            "{\"rate\":20,\"morning_rate\":10,\"enabled\":true,\"slots\":[{\"species\":\"BIDOOF\",\"rate\":30}],\"metadata\":{\"map\":\"ROUTE_201\"}}\n",
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
        XCTAssertNil(fields["metadata"])

        let nestedPlan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "encounters:\(encounterPath)",
                fieldEdits: [NDSDataSemanticFieldEdit(key: "slots.0.rate", value: "35")]
            )
        )
        XCTAssertTrue(nestedPlan.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED" })
        XCTAssertTrue(nestedPlan.editPlan.changes.isEmpty)
        XCTAssertFalse(nestedPlan.editPlan.validateApplyability().isApplyable)

        let plan = NDSDataSemanticEditor.plan(
            catalog: catalog,
            draft: NDSDataSemanticEditDraft(
                recordID: "encounters:\(encounterPath)",
                fieldEdits: [
                    NDSDataSemanticFieldEdit(key: "morning_rate", value: "25"),
                    NDSDataSemanticFieldEdit(key: "enabled", value: "false")
                ]
            )
        )

        XCTAssertTrue(plan.diagnostics.allSatisfy { $0.severity != .error }, plan.diagnostics.map(\.code).joined(separator: ","))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"morning_rate\":25"))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"enabled\":false"))
        XCTAssertTrue(plan.textDraft.editedText.contains("\"slots\":[{\"species\":\"BIDOOF\",\"rate\":30}]"))
        XCTAssertEqual(plan.editPlan.changes.count, 1)
        XCTAssertTrue(plan.editPlan.validateApplyability().isApplyable)

        let result = try NDSDataMutationApplier.apply(plan: plan.editPlan)
        XCTAssertEqual(result.appliedChanges.count, 1)
        let updated = try String(contentsOf: root.appendingPathComponent(encounterPath), encoding: .utf8)
        XCTAssertTrue(updated.contains("\"morning_rate\":25"))
        XCTAssertTrue(updated.contains("\"enabled\":false"))
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

        let cAnchorSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:arm9/src/map_header.c")
        XCTAssertFalse(cAnchorSnapshot.canEdit)
        XCTAssertTrue(cAnchorSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(cAnchorSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(cAnchorSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })

        let matrixSnapshot = NDSDataSemanticEditor.snapshot(catalog: catalog, recordID: "maps:files/fielddata/mapmatrix/matrix.bin")
        XCTAssertFalse(matrixSnapshot.canEdit)
        XCTAssertTrue(matrixSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED" })
        XCTAssertTrue(matrixSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED" })
        XCTAssertTrue(matrixSnapshot.diagnostics.contains { $0.code == "NDS_DATA_SEMANTIC_FORMAT_BLOCKED" })
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
        try write("void MapHeader_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/map_header.c"))
        try write("void Script_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/script.c"))
        try write("void Message_Load(void) {}\n", to: root.appendingPathComponent("arm9/src/msgdata.c"))
        try write("{\"personal\":1}\n", to: root.appendingPathComponent("files/poketool/personal/personal.json"))
        try write("{\"name\":\"POTION\",\"price\":300,\"field_use\":true,\"effects\":[{\"kind\":\"heal\",\"amount\":20}]}\n", to: root.appendingPathComponent("files/itemtool/itemdata/potion.json"))
        try write(#"{"name":"POTION\nTAB\t\u00e9","description":"quoted \"text\" and slash \\","price":300}"# + "\n", to: root.appendingPathComponent("files/itemtool/itemdata/escaped.json"))
        try write("{\"name\":\"POTION\",\"name\":\"SUPER_POTION\"}\n", to: root.appendingPathComponent("files/itemtool/itemdata/duplicate.json"))
        try write("{\"name\": }\n", to: root.appendingPathComponent("files/itemtool/itemdata/malformed.json"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/itemtool/itemdata/item_0000.bin"))
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
        try write(Data([0x00]), to: root.appendingPathComponent("files/root.bin"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/a/0/0/0/resource.bin"))
        try write("Route 1 hello\n", to: root.appendingPathComponent("files/msgdata/story/message_bank.txt"))
        try write(Data("NARC".utf8), to: root.appendingPathComponent("files/soundstatus.narc"))
        try write(Data("SDAT".utf8) + Data(repeating: 0, count: 12), to: root.appendingPathComponent("files/wb_sound_data.sdat"))
        try write("overlay\n", to: root.appendingPathComponent("overlays/overlay_93/source.s"))
        try write("config\n", to: root.appendingPathComponent("ndsdisasm_config/ARM9.cfg"))
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
