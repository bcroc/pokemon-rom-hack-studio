import XCTest
@testable import PokemonHackCore

final class GenIIIResourceTests: XCTestCase {
    private var temporaryDirectories: [ResourceTemporaryDirectory] = []

    override func tearDown() {
        temporaryDirectories.removeAll()
        super.tearDown()
    }

    func testRubySapphireDetectionWinsEvenWhenMakefileMentionsEmeraldCodes() throws {
        let root = try makeDecompFixture(name: "pokeruby") { root in
            try write(
                """
                # Compatibility table mentions BPEE but this is still pokeruby.
                GAME_VERSION  ?= RUBY
                ruby: ; @$(MAKE) GAME_VERSION=RUBY
                sapphire: ; @$(MAKE) GAME_VERSION=SAPPHIRE
                """,
                to: root.appendingPathComponent("Makefile")
            )
            try write("GAME_VERSION  ?= RUBY\n", to: root.appendingPathComponent("config.mk"))
            try write("f28b6ffc97847e94a6c21a63cacf633ee5c8df1e  pokeruby.gba\n", to: root.appendingPathComponent("ruby.sha1"))
            try write("3ccbbd45f8553c36463f13b938e833f652b793e4  pokesapphire.gba\n", to: root.appendingPathComponent("sapphire.sha1"))
        }

        let profile = try ProjectInspector.detectProfile(at: root)
        let index = try GameAdapterRegistry.index(path: root.path)
        let resource = GenIIIResourceRegistry.resourceIndex(path: root.path)

        XCTAssertEqual(profile, .pokeruby)
        XCTAssertEqual(index.adapterID, "pret.pokeruby")
        XCTAssertEqual(resource.family, .rubySapphire)
        XCTAssertTrue(resource.variants.contains { $0.title == "Ruby" })
        XCTAssertTrue(resource.variants.contains { $0.title == "Sapphire" })
    }

    func testFireRedAdapterExposesLeafGreenVariants() throws {
        let root = try makeDecompFixture(name: "pokefirered") { root in
            try write(
                """
                ROM := poke$(BUILD_NAME).gba
                leafgreen: ; @$(MAKE) GAME_VERSION=LEAFGREEN
                leafgreen_rev1: ; @$(MAKE) GAME_VERSION=LEAFGREEN GAME_REVISION=1
                """,
                to: root.appendingPathComponent("Makefile")
            )
            try write("GAME_VERSION  ?= FIRERED\n", to: root.appendingPathComponent("config.mk"))
            try write("41cb23d8dccc8ebd7c649cd8fbb58eeace6e2fdc  pokefirered.gba\n", to: root.appendingPathComponent("firered.sha1"))
            try write("574fa542ffebb14be69902d1d36f1ec0a4afd71e  pokeleafgreen.gba\n", to: root.appendingPathComponent("leafgreen.sha1"))
            try makeDirectory(root.appendingPathComponent("graphics/quest_log"))
        }

        let index = try GameAdapterRegistry.index(path: root.path)
        let resource = GenIIIResourceRegistry.resourceIndex(path: root.path)

        XCTAssertEqual(index.profile, .pokefirered)
        XCTAssertTrue(index.buildTargets.contains { $0.id == "leafgreen-build" })
        XCTAssertTrue(index.buildTargets.contains { $0.outputPath == "pokeleafgreen.gba" })
        XCTAssertTrue(resource.variants.contains { $0.title == "LeafGreen" && $0.checksumPath == "leafgreen.sha1" })
    }

    func testResourceRegistryAutoDiscoversOnlyGBASourcesReferencesAndROMs() throws {
        let temp = try ResourceTemporaryDirectory()
        temporaryDirectories.append(temp)
        let workspace = temp.url

        _ = try makeDecompFixture(name: "pokeemerald", under: workspace) { root in
            try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
            try write("f3ae088181bf583e55daf962a92bb46f4f1d07b7  pokeemerald.gba\n", to: root.appendingPathComponent("rom.sha1"))
        }

        let referenceRoot = try makeDecompFixture(name: "pokeruby", under: workspace.appendingPathComponent("references")) { root in
            try write("GAME_VERSION  ?= RUBY\n", to: root.appendingPathComponent("config.mk"))
            try write("ruby: ; @$(MAKE) GAME_VERSION=RUBY\nsapphire: ; @$(MAKE) GAME_VERSION=SAPPHIRE\n", to: root.appendingPathComponent("Makefile"))
            try write("f28b6ffc97847e94a6c21a63cacf633ee5c8df1e  pokeruby.gba\n", to: root.appendingPathComponent("ruby.sha1"))
            try write("3ccbbd45f8553c36463f13b938e833f652b793e4  pokesapphire.gba\n", to: root.appendingPathComponent("sapphire.sha1"))
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: referenceRoot.path))
        try write(
            """
            {
              "references": [
                { "name": "pokeruby", "folder": "references/pokeruby" }
              ]
            }
            """,
            to: workspace.appendingPathComponent("references/manifest.json")
        )

        try writeGBA(
            title: "POKEMON EMER",
            gameCode: "BPEE",
            to: workspace.appendingPathComponent("Pokemon Emerald.gba")
        )
        try writeSyntheticGameCubeDisc(to: workspace.appendingPathComponent("Pokemon Colosseum.iso"))

        let library = GenIIIResourceRegistry.load(workspaceRoot: workspace.path)

        XCTAssertTrue(library.entries.contains { $0.family == .emerald && $0.role == .editableSource })
        XCTAssertTrue(library.entries.contains { $0.family == .rubySapphire && $0.role == .referenceSource })
        XCTAssertTrue(library.entries.contains { $0.platform == .gbaROM && $0.family == .emerald })
        XCTAssertFalse(library.entries.contains { $0.platform == .gameCube })
    }

    func testGameCubeDiscAndFSYSParserIndexesSyntheticArchiveMembers() throws {
        let temp = try ResourceTemporaryDirectory()
        temporaryDirectories.append(temp)
        let image = temp.url.appendingPathComponent("Pokemon Colosseum.iso")
        try writeSyntheticGameCubeDisc(to: image)

        let disc = GameCubeDiscParser.parse(path: image.path)
        let resource = GenIIIResourceRegistry.resourceIndex(path: image.path)

        XCTAssertEqual(disc.profile, .pokemonColosseum)
        XCTAssertEqual(disc.header?.gameCode, "GC6E")
        XCTAssertTrue(disc.resources.contains { $0.path == "files/common.fsys" && $0.kind == .archive })
        XCTAssertTrue(disc.resources.contains { $0.path.contains("common_rel.fdat") && $0.kind == .pokemonTable })
        XCTAssertTrue(disc.resources.contains { $0.path.contains("msg_shop.bin") && $0.kind == .text })
        XCTAssertEqual(resource.platform, .gameCube)
        XCTAssertEqual(resource.family, .colosseum)
        XCTAssertEqual(resource.parseStatus, .parsed)
    }

    private func makeDecompFixture(
        name: String,
        under parent: URL? = nil,
        configure: (URL) throws -> Void
    ) throws -> URL {
        let root: URL
        if let parent {
            root = parent.appendingPathComponent(name)
        } else {
            let temp = try ResourceTemporaryDirectory()
            temporaryDirectories.append(temp)
            root = temp.url.appendingPathComponent(name)
        }

        try makeDirectory(root)
        try makeDirectory(root.appendingPathComponent("src"))
        try makeDirectory(root.appendingPathComponent("include"))
        try makeDirectory(root.appendingPathComponent("graphics/pokemon"))
        try makeDirectory(root.appendingPathComponent("graphics/trainers"))
        try makeDirectory(root.appendingPathComponent("graphics/items"))
        try makeDirectory(root.appendingPathComponent("data/scripts"))
        try makeDirectory(root.appendingPathComponent("data/text"))
        try makeDirectory(root.appendingPathComponent("data/maps"))
        try makeDirectory(root.appendingPathComponent("data/layouts"))
        try write("{\"group_order\":[]}\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write("{\"layouts_table_label\":\"gMapLayouts\",\"layouts\":[]}\n", to: root.appendingPathComponent("data/layouts/layouts.json"))
        try configure(root)
        return root
    }

    private func writeSyntheticGameCubeDisc(to url: URL) throws {
        var bytes = [UInt8](repeating: 0, count: 0x2400)
        replaceASCII("GC6E", at: 0x0, in: &bytes)
        replaceASCII("01", at: 0x4, in: &bytes)
        bytes[0x6] = 0
        bytes[0x7] = 0
        replaceASCII("POKEMON COLOSSEUM", at: 0x20, in: &bytes)
        writeBE32(0x1000, at: 0x420, in: &bytes)
        writeBE32(0x1800, at: 0x424, in: &bytes)

        let fsys = syntheticFSYSArchive()
        let fsysOffset = 0x2000
        bytes.replaceSubrange(fsysOffset..<(fsysOffset + fsys.count), with: fsys)

        let names = Array("\0files\0common.fsys\0".utf8)
        let entryCount = 3
        let fstSize = entryCount * 12 + names.count
        writeBE32(UInt32(fstSize), at: 0x428, in: &bytes)

        var fst = [UInt8](repeating: 0, count: fstSize)
        writeBE32(0x01000000, at: 0, in: &fst)
        writeBE32(0, at: 4, in: &fst)
        writeBE32(UInt32(entryCount), at: 8, in: &fst)
        writeBE32(0x01000001, at: 12, in: &fst)
        writeBE32(0, at: 16, in: &fst)
        writeBE32(UInt32(entryCount), at: 20, in: &fst)
        writeBE32(0x00000007, at: 24, in: &fst)
        writeBE32(UInt32(fsysOffset), at: 28, in: &fst)
        writeBE32(UInt32(fsys.count), at: 32, in: &fst)
        fst.replaceSubrange((entryCount * 12)..<fstSize, with: names)
        bytes.replaceSubrange(0x1800..<(0x1800 + fst.count), with: fst)

        try Data(bytes).write(to: url)
    }

    private func syntheticFSYSArchive() -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: 0x180)
        replaceASCII("common_rel.fdat", at: 0x10, in: &bytes)
        replaceASCII("msg_shop.bin", at: 0x30, in: &bytes)
        replaceASCII("LZSS", at: 0x80, in: &bytes)
        writeBE32(8, at: 0x84, in: &bytes)
        writeBE32(24, at: 0x88, in: &bytes)
        replaceASCII("POKEMON1", at: 0x90, in: &bytes)
        replaceASCII("LZSS", at: 0xB0, in: &bytes)
        writeBE32(8, at: 0xB4, in: &bytes)
        writeBE32(32, at: 0xB8, in: &bytes)
        replaceASCII("TEXTDATA", at: 0xC0, in: &bytes)
        return bytes
    }

    private func writeGBA(title: String, gameCode: String, to url: URL) throws {
        var bytes = [UInt8](repeating: 0, count: 0xC0)
        replaceASCII(title, at: 0xA0, in: &bytes, maxLength: 12)
        replaceASCII(gameCode, at: 0xAC, in: &bytes, maxLength: 4)
        replaceASCII("01", at: 0xB0, in: &bytes, maxLength: 2)
        try Data(bytes).write(to: url)
    }

    private func replaceASCII(_ string: String, at offset: Int, in bytes: inout [UInt8], maxLength: Int? = nil) {
        let replacement = Array(string.utf8).prefix(maxLength ?? string.utf8.count)
        bytes.replaceSubrange(offset..<(offset + replacement.count), with: replacement)
    }

    private func writeBE32(_ value: UInt32, at offset: Int, in bytes: inout [UInt8]) {
        bytes[offset] = UInt8((value >> 24) & 0xFF)
        bytes[offset + 1] = UInt8((value >> 16) & 0xFF)
        bytes[offset + 2] = UInt8((value >> 8) & 0xFF)
        bytes[offset + 3] = UInt8(value & 0xFF)
    }

    private func makeDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private func write(_ text: String, to url: URL) throws {
        try makeDirectory(url.deletingLastPathComponent())
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
}

private final class ResourceTemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackResourceTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
