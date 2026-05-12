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
        XCTAssertEqual(count(for: .items, in: catalog), 1)
        XCTAssertEqual(count(for: .trainers, in: catalog), 1)
        XCTAssertEqual(count(for: .encounters, in: catalog), 1)
        XCTAssertEqual(count(for: .text, in: catalog), 1)
        XCTAssertEqual(count(for: .scripts, in: catalog), 1)
        XCTAssertEqual(count(for: .maps, in: catalog), 3)
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "res/pokemon/abra/data.json" && $0.format == .json && $0.recordCount == 1 })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "res/items/items.csv" && $0.format == .csv && $0.recordCount == 1 })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "platinum.us/filesys.csv" && $0.role == .nitroFSManifest })
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "NDS_DATA_CATALOG_READ_ONLY" })
    }

    func testHeartGoldCatalogIncludesNARCPlaceholderAndSourceAnchors() throws {
        let root = try makeRoot(name: "pokeheartgold", configure: makeHeartGoldFixture)

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        XCTAssertEqual(catalog.profile, .pokeheartgold)
        XCTAssertEqual(catalog.family, .heartGoldSoulSilver)
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "files/poketool/waza/waza_tbl.narc" && $0.domain == .moves && $0.format == .narc && $0.role == .binaryContainer })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "src/data/map_headers.h" && $0.domain == .maps && $0.format == .cHeader })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "files/fielddata/eventdata/zone_event/zone_001.json" && $0.domain == .scripts })
        XCTAssertTrue(catalog.summary.nitroFSBackedCount > 0)
        XCTAssertTrue(catalog.isReadOnly)
    }

    func testDiamondCatalogKeepsCSourceAnchorsConservative() throws {
        let root = try makeRoot(name: "pokediamond", configure: makeDiamondFixture)

        let catalog = try NDSDataCatalogBuilder.build(path: root.path)

        XCTAssertEqual(catalog.profile, .pokediamond)
        XCTAssertEqual(catalog.family, .diamondPearl)
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "arm9/src/pokemon.c" && $0.domain == .species && $0.format == .cSource })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "arm9/src/script.c" && $0.domain == .scripts && $0.format == .cSource })
        XCTAssertTrue(catalog.records.contains { $0.relativePath == "files/fielddata/mapmatrix/matrix.bin" && $0.domain == .maps && $0.format == .binary })
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

    func testBinaryNDSROMReportsDataCatalogDeferred() throws {
        let temp = try NDSDataCatalogTemporaryDirectory()
        temporaryDirectories.append(temp)
        let rom = temp.url.appendingPathComponent("diamond.nds")
        var data = Data(repeating: 0, count: 0x200)
        data.replaceSubrange(0x00..<0x08, with: Data("POKEMON".utf8))
        data.replaceSubrange(0x0C..<0x10, with: Data("ADAE".utf8))
        try data.write(to: rom)

        let catalog = try NDSDataCatalogBuilder.build(path: rom.path)

        XCTAssertEqual(catalog.profile, .ndsROM)
        XCTAssertEqual(catalog.family, .diamondPearl)
        XCTAssertTrue(catalog.records.isEmpty)
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "NDS_DATA_CATALOG_BINARY_DEFERRED" })
        XCTAssertTrue(catalog.isReadOnly)
    }

    func testResourceRegistrySurfacesCatalogRowsForNDSSourceRoots() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)

        let entry = GenIIIResourceRegistry.resourceIndex(path: root.path)
        let assetCatalog = GenIIIAssetCatalogBuilder.build(path: root.path)

        XCTAssertEqual(entry.platform, .ndsSource)
        XCTAssertEqual(entry.writePolicy, .readOnly)
        XCTAssertTrue(entry.items.contains { $0.category == "NDS Data species" && $0.path == "res/pokemon/abra/data.json" })
        XCTAssertTrue(entry.items.contains { $0.category == "NDS Data items" && $0.path == "res/items/items.csv" })
        XCTAssertTrue(assetCatalog.assets.contains { $0.relativePath == "res/pokemon/abra/data.json" && $0.category == .species })
        XCTAssertTrue(assetCatalog.assets.contains { $0.relativePath == "res/items/items.csv" && $0.category == .items })
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
        try write("{\"base_hp\":25}\n", to: root.appendingPathComponent("res/pokemon/abra/data.json"))
        try write("{\"power\":40}\n", to: root.appendingPathComponent("res/battle/moves/tackle.json"))
        try write("id,name\n1,POTION\n", to: root.appendingPathComponent("res/items/items.csv"))
        try write("[{\"id\":1}]\n", to: root.appendingPathComponent("res/trainers/data/youngster.json"))
        try write("[{\"species\":\"BIDOOF\"}]\n", to: root.appendingPathComponent("res/field/encounters/route201.json"))
        try write("{\"message\":\"hello\"}\n", to: root.appendingPathComponent("res/text/story.json"))
        try write("scrcmd_end\n", to: root.appendingPathComponent("res/field/scripts/route201.s"))
        try write("{\"event\":1}\n", to: root.appendingPathComponent("res/field/events/route201.json"))
        try write(Data([0x01, 0x02]), to: root.appendingPathComponent("res/field/maps/route201/map.bin"))
        try write("{\"matrix\":1}\n", to: root.appendingPathComponent("res/field/matrices/route201.json"))
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
        try write(Data([0x4E, 0x41, 0x52, 0x43]), to: root.appendingPathComponent("files/poketool/waza/waza_tbl.narc"))
        try write("id,name\n1,POTION\n", to: root.appendingPathComponent("files/itemtool/itemdata/item_data.csv"))
        try write("[{\"id\":1}]\n", to: root.appendingPathComponent("files/poketool/trainer/trainers.json"))
        try write("[{\"slot\":1}]\n", to: root.appendingPathComponent("files/fielddata/encountdata/gs_enc_data.json"))
        try write("{\"zone\":1}\n", to: root.appendingPathComponent("files/fielddata/eventdata/zone_event/zone_001.json"))
        try write("message\n", to: root.appendingPathComponent("files/msgdata/msg/0001.txt"))
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
        try write("{\"personal\":1}\n", to: root.appendingPathComponent("files/poketool/personal/personal.json"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/fielddata/mapmatrix/matrix.bin"))
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
