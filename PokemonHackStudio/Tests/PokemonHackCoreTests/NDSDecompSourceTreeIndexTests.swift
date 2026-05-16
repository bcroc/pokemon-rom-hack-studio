import XCTest
@testable import PokemonHackCore

final class NDSDecompSourceTreeIndexTests: XCTestCase {
    private var temporaryDirectories: [NDSDecompTemporaryDirectory] = []

    override func tearDown() {
        temporaryDirectories.removeAll()
        super.tearDown()
    }

    func testDetectsNDSDecompProfilesAsReadOnlySourceTrees() throws {
        let fixtures: [(String, GameProfile, (URL) throws -> Void)] = [
            ("pokediamond", .pokediamond, makeDiamondFixture),
            ("pokeplatinum", .pokeplatinum, makePlatinumFixture),
            ("pokeheartgold", .pokeheartgold, makeHeartGoldFixture),
            ("pokeblack", .pokeblack, makeBlackFixture),
            ("pmd-sky", .pmdSky, makePMDSkyFixture)
        ]

        for (name, expectedProfile, makeFixture) in fixtures {
            let root = try makeRoot(name: name, configure: makeFixture)

            let profile = try ProjectInspector.detectProfile(at: root)
            let project = try ProjectInspector.inspect(path: root.path)
            let index = try GameAdapterRegistry.index(path: root.path)
            let sourceTree = try NDSDecompSourceTreeIndexBuilder.build(root: root)

            XCTAssertEqual(profile, expectedProfile)
            XCTAssertEqual(project.editorModules, [.rom, .build, .diagnostics])
            XCTAssertEqual(index.profile, expectedProfile)
            XCTAssertEqual(index.platform, .nds)
            XCTAssertEqual(index.projectKind, .sourceTree)
            XCTAssertEqual(index.writePolicy, .readOnly)
            XCTAssertEqual(index.editorModules, [.rom, .build, .diagnostics])
            XCTAssertTrue(index.capabilities.contains(.ndsSourceTreeIndex))
            XCTAssertFalse(index.capabilities.contains(.buildRunner))
            XCTAssertFalse(index.capabilities.contains(.playtestBridge))
            XCTAssertFalse(index.capabilities.contains(.patchPlanning))
            XCTAssertFalse(index.buildTargets.isEmpty)
            XCTAssertNotEqual(sourceTree.buildSystem, .unknown)
            XCTAssertEqual(sourceTree.family, entryFamily(for: expectedProfile))
            XCTAssertTrue(sourceTree.diagnostics.contains(where: { $0.code == "NDS_DECOMP_READ_ONLY" }))
            XCTAssertTrue(sourceTree.paths.contains(where: { $0.role == .nitroFSRoot }))
        }
    }

    func testResourceRegistrySurfacesNDSSourceEntriesWithoutWriteCapabilities() throws {
        let root = try makeRoot(name: "pokeplatinum", configure: makePlatinumFixture)

        let entry = GenIIIResourceRegistry.resourceIndex(path: root.path)

        XCTAssertEqual(entry.platform, .ndsSource)
        XCTAssertEqual(entry.profile, .pokeplatinum)
        XCTAssertEqual(entry.family, .platinum)
        XCTAssertEqual(entry.writePolicy, .readOnly)
        XCTAssertTrue(entry.modules.contains(.rom))
        XCTAssertTrue(entry.items.contains(where: { $0.category == "NDS Variant" && $0.path == "build/pokeplatinum.us.nds" }))
        XCTAssertTrue(entry.items.contains(where: { $0.category == "NDS Build Target" }))
        XCTAssertFalse(entry.modules.contains(.pokemon))
    }

    func testResourceRegistrySurfacesPokeBlackSourceInventory() throws {
        let root = try makeRoot(name: "pokeblack", configure: makeBlackFixture)

        let entry = GenIIIResourceRegistry.resourceIndex(path: root.path)

        XCTAssertEqual(entry.platform, .ndsSource)
        XCTAssertEqual(entry.profile, .pokeblack)
        XCTAssertEqual(entry.family, .blackWhite)
        XCTAssertEqual(entry.writePolicy, .readOnly)
        XCTAssertTrue(entry.variants.contains { $0.title == "Pokemon Black US" && $0.checksumPath == "black.us/rom.sha1" })
        XCTAssertTrue(entry.items.contains { $0.category == "NDS Variant" && $0.path == "pokeblack.nds" })
        XCTAssertTrue(entry.items.contains { $0.category == "NDS Data resources" && $0.path == "files/root.bin" })
        XCTAssertTrue(entry.items.contains { $0.category == "NDS Data audio" && $0.path == "files/wb_sound_data.sdat" })
    }

    func testResourceRegistryLoadIncludesSiblingCentralPokeBlackReference() throws {
        let temp = try NDSDecompTemporaryDirectory()
        temporaryDirectories.append(temp)
        let workspace = temp.url.appendingPathComponent("pokemonhack")
        try makeDirectory(workspace)
        let centralRoot = temp.url
            .appendingPathComponent("reference-repos")
            .appendingPathComponent("repos")
            .appendingPathComponent("pokemodding__pokeblack")
        try makeBlackFixture(root: centralRoot)

        let library = GenIIIResourceRegistry.load(workspaceRoot: workspace.path)

        let entry = try XCTUnwrap(library.entries.first { $0.path == centralRoot.path })
        XCTAssertEqual(entry.profile, .pokeblack)
        XCTAssertEqual(entry.platform, .ndsSource)
        XCTAssertEqual(entry.role, .referenceSource)
        XCTAssertEqual(entry.writePolicy, .readOnly)
    }

    func testGBAProjectAndNDSROMDetectionRemainUnchanged() throws {
        let gbaRoot = try makeRoot(name: "pokeemerald") { root in
            try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
            try write("placeholder\n", to: root.appendingPathComponent("rom.sha1"))
            try makeDirectory(root.appendingPathComponent("src"))
            try makeDirectory(root.appendingPathComponent("include"))
            try makeDirectory(root.appendingPathComponent("graphics/pokenav"))
            try makeDirectory(root.appendingPathComponent("graphics/pokemon"))
            try makeDirectory(root.appendingPathComponent("data/maps"))
            try write("[]\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        }
        XCTAssertEqual(try ProjectInspector.detectProfile(at: gbaRoot), .pokeemerald)

        let temp = try NDSDecompTemporaryDirectory()
        temporaryDirectories.append(temp)
        let rom = temp.url.appendingPathComponent("test.nds")
        var data = Data(repeating: 0, count: 0x200)
        data.replaceSubrange(0x00..<0x08, with: Data("POKEMON".utf8))
        data.replaceSubrange(0x0C..<0x10, with: Data("ADAE".utf8))
        try data.write(to: rom)

        XCTAssertEqual(try ProjectInspector.detectProfile(at: rom), .ndsROM)
        XCTAssertEqual(try GameAdapterRegistry.index(path: rom.path).profile, .ndsROM)
    }

    private func makeRoot(name: String, configure: (URL) throws -> Void) throws -> URL {
        let temp = try NDSDecompTemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent(name)
        try makeDirectory(root)
        try configure(root)
        return root
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
    }

    private func makePlatinumFixture(root: URL) throws {
        try write("rom: build/pokeplatinum.us.nds\n", to: root.appendingPathComponent("Makefile"))
        try write("project('pokeplatinum')\n", to: root.appendingPathComponent("meson.build"))
        try write("option('revision')\n", to: root.appendingPathComponent("meson.options"))
        try write("path,sha1\n", to: root.appendingPathComponent("platinum.us/filesys.csv"))
        try write("bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb  filesys\n", to: root.appendingPathComponent("platinum.us/filesys.sha1"))
        try write("cccccccccccccccccccccccccccccccccccccccc  pokeplatinum.us.nds\n", to: root.appendingPathComponent("platinum.us/rom_rev1.sha1"))
        try makeDirectory(root.appendingPathComponent("src"))
        try makeDirectory(root.appendingPathComponent("asm"))
        try makeDirectory(root.appendingPathComponent("res"))
    }

    private func makeHeartGoldFixture(root: URL) throws {
        try write("GAME_VERSION       ?= HEARTGOLD\nGAME_CODE     := IPK\n", to: root.appendingPathComponent("config.mk"))
        try write("ROM := $(BUILD_DIR)/poke$(buildname).nds\n", to: root.appendingPathComponent("Makefile"))
        try write("HostRoot files/\n", to: root.appendingPathComponent("rom.rsf"))
        try write("filesystem: $(NITROFS_FILES)\n", to: root.appendingPathComponent("filesystem.mk"))
        try write("dddddddddddddddddddddddddddddddddddddddd  pokeheartgold.us.nds\n", to: root.appendingPathComponent("heartgold.us/rom.sha1"))
        try makeDirectory(root.appendingPathComponent("soulsilver.us"))
        try makeDirectory(root.appendingPathComponent("files"))
        try makeDirectory(root.appendingPathComponent("src"))
        try makeDirectory(root.appendingPathComponent("asm"))
    }

    private func makePMDSkyFixture(root: URL) throws {
        try write("GAME_CODE     := C2S\nGAME_LANGUAGE      ?= NORTH_AMERICA\n", to: root.appendingPathComponent("config.mk"))
        try write("ROM := $(BUILD_DIR)/$(buildname).nds\n", to: root.appendingPathComponent("Makefile"))
        try write("HostRoot files/\n", to: root.appendingPathComponent("rom.rsf"))
        try write("NITROFS_FILES_FILE := nitrofs_files.txt\n", to: root.appendingPathComponent("filesystem.mk"))
        try write("files/MESSAGE/text.str\n", to: root.appendingPathComponent("nitrofs_files.txt"))
        try write("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee  pmdsky.us.nds\n", to: root.appendingPathComponent("pmdsky.us/rom.sha1"))
        try makeDirectory(root.appendingPathComponent("files"))
        try makeDirectory(root.appendingPathComponent("src"))
        try makeDirectory(root.appendingPathComponent("asm"))
    }

    private func makeBlackFixture(root: URL) throws {
        try write("GAME_VERSION  ?= BLACK\nSUPPORTED_ROMS   := black.us\n", to: root.appendingPathComponent("config.mk"))
        try write("ROM            := pokeblack.nds\n", to: root.appendingPathComponent("Makefile"))
        try write("NitroROMSpec\n", to: root.appendingPathComponent("main.rsf"))
        try write("main linker script\n", to: root.appendingPathComponent("main.lsf"))
        try write("ffffffffffffffffffffffffffffffffffffffff  pokeblack.nds\n", to: root.appendingPathComponent("black.us/rom.sha1"))
        try write("void Init(void) {}\n", to: root.appendingPathComponent("src/init.c"))
        try write("arm9\n", to: root.appendingPathComponent("asm/arm9_remaining.s"))
        try write("#define BLACK 1\n", to: root.appendingPathComponent("include/globals.h"))
        try write("encounter\n", to: root.appendingPathComponent("data/encounters/route_1.txt"))
        try write(Data([0x00]), to: root.appendingPathComponent("files/root.bin"))
        try write(Data("NARC".utf8), to: root.appendingPathComponent("files/soundstatus.narc"))
        try write(Data("SDAT".utf8), to: root.appendingPathComponent("files/wb_sound_data.sdat"))
        try write("overlay\n", to: root.appendingPathComponent("overlays/overlay_93/source.s"))
        try write("config\n", to: root.appendingPathComponent("ndsdisasm_config/ARM9.cfg"))
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

    private func entryFamily(for profile: GameProfile) -> GenIIIGameFamily {
        switch profile {
        case .pokediamond:
            return .diamondPearl
        case .pokeplatinum:
            return .platinum
        case .pokeheartgold:
            return .heartGoldSoulSilver
        case .pokeblack:
            return .blackWhite
        default:
            return .ndsUnknown
        }
    }
}

private final class NDSDecompTemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackCoreNDSDecompTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
