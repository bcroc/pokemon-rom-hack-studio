import XCTest
@testable import PokemonHackCore

final class ProjectInspectorTests: XCTestCase {
    private var temporaryDirectories: [TemporaryDirectory] = []

    override func tearDown() {
        temporaryDirectories.removeAll()
        super.tearDown()
    }

    func testDetectsPokeemeraldFixture() throws {
        let root = try makeFixture(name: "pokeemerald") { root in
            try write("TITLE := POKEMON EMER\nGAME_CODE := BPEE\n", to: root.appendingPathComponent("Makefile"))
            try write("placeholder\n", to: root.appendingPathComponent("rom.sha1"))
            try makeDirectory(root.appendingPathComponent("graphics/pokenav"))
        }

        let project = try ProjectInspector.inspect(path: root.path)

        XCTAssertEqual(project.profile, .pokeemerald)
        XCTAssertTrue(project.editorModules.contains(.maps))
        XCTAssertTrue(project.editorModules.contains(.graphics))
        XCTAssertTrue(project.issues.isEmpty)
    }

    func testDetectsPokefireredFixture() throws {
        let root = try makeFixture(name: "pokefirered") { root in
            try write("ROM := poke$(BUILD_NAME).gba\n", to: root.appendingPathComponent("Makefile"))
            try write("placeholder\n", to: root.appendingPathComponent("firered.sha1"))
            try makeDirectory(root.appendingPathComponent("graphics/quest_log"))
        }

        let project = try ProjectInspector.inspect(path: root.path)

        XCTAssertEqual(project.profile, .pokefirered)
        XCTAssertTrue(project.editorModules.contains(.maps))
        XCTAssertTrue(project.editorModules.contains(.pokemon))
        XCTAssertTrue(project.issues.isEmpty)
    }

    func testReferenceManifestLoadsFromSiblingReferencesDirectory() throws {
        let temp = try TemporaryDirectory()
        let studio = temp.url.appendingPathComponent("PokemonHackStudio")
        let references = temp.url.appendingPathComponent("references")
        try makeDirectory(studio)
        try makeDirectory(references)
        try write(
            """
            {
              "repositories": [
                {
                  "name": "porymap",
                  "path": "references/porymap",
                  "url": "https://github.com/huderlem/porymap",
                  "description": "Map editor",
                  "modules": ["maps", "scripts"]
                }
              ]
            }
            """,
            to: references.appendingPathComponent("manifest.json")
        )

        let manifest = try ReferenceManifestLoader.load(from: studio.path)

        XCTAssertEqual(manifest.repositories.count, 1)
        XCTAssertEqual(manifest.repositories[0].name, "porymap")
        XCTAssertEqual(manifest.repositories[0].modules, [.maps, .scripts])
    }

    func testReferenceManifestLoadsFromProjectRootReferencesDirectory() throws {
        let temp = try TemporaryDirectory()
        let references = temp.url.appendingPathComponent("references")
        try makeDirectory(references)
        try write(
            """
            {
              "repositories": [
                {
                  "name": "mgba",
                  "path": "references/mgba",
                  "modules": ["unknown"]
                }
              ]
            }
            """,
            to: references.appendingPathComponent("manifest.json")
        )

        let manifest = try ReferenceManifestLoader.load(from: temp.url.path)

        XCTAssertEqual(manifest.repositories, [
            ReferenceRepo(name: "mgba", path: "references/mgba", modules: [.unknown])
        ])
    }

    func testReferenceManifestLoadsPinnedReferenceCatalogShape() throws {
        let temp = try TemporaryDirectory()
        let references = temp.url.appendingPathComponent("references")
        try makeDirectory(references)
        try write(
            """
            {
              "schemaVersion": 1,
              "references": [
                {
                  "name": "porytiles",
                  "repoUrl": "https://github.com/grunt-lucas/porytiles.git",
                  "folder": "references/porytiles",
                  "branch": "develop",
                  "head": "abc123",
                  "license": {
                    "spdx": "MIT",
                    "notes": "Local license file is MIT."
                  },
                  "usage": "Tileset compiler reference.",
                  "risk": "Pin this repo before comparing behavior."
                }
              ]
            }
            """,
            to: references.appendingPathComponent("manifest.json")
        )

        let manifest = try ReferenceManifestLoader.load(from: temp.url.path)
        let repo = try XCTUnwrap(manifest.repositories.first)

        XCTAssertEqual(repo.name, "porytiles")
        XCTAssertEqual(repo.path, "references/porytiles")
        XCTAssertEqual(repo.url, "https://github.com/grunt-lucas/porytiles.git")
        XCTAssertEqual(repo.description, "Tileset compiler reference.")
        XCTAssertEqual(repo.modules, [.graphics])
        XCTAssertEqual(repo.branch, "develop")
        XCTAssertEqual(repo.head, "abc123")
        XCTAssertEqual(repo.license, "MIT")
        XCTAssertEqual(repo.risk, "Pin this repo before comparing behavior.")
    }

    func testReferenceManifestAllowsMissingModules() throws {
        let temp = try TemporaryDirectory()
        let references = temp.url.appendingPathComponent("references")
        try makeDirectory(references)
        try write(
            """
            {
              "repositories": [
                {
                  "name": "neutral-reference",
                  "path": "references/neutral-reference"
                }
              ]
            }
            """,
            to: references.appendingPathComponent("manifest.json")
        )

        let manifest = try ReferenceManifestLoader.load(from: temp.url.path)

        XCTAssertEqual(manifest.repositories[0].modules, [])
    }

    private func makeFixture(
        name: String,
        configure: (URL) throws -> Void
    ) throws -> URL {
        let temp = try TemporaryDirectory()
        temporaryDirectories.append(temp)
        let root = temp.url.appendingPathComponent(name)
        try makeDirectory(root)
        try makeDirectory(root.appendingPathComponent("src"))
        try makeDirectory(root.appendingPathComponent("include"))
        try makeDirectory(root.appendingPathComponent("graphics/pokemon"))
        try makeDirectory(root.appendingPathComponent("graphics/trainers"))
        try makeDirectory(root.appendingPathComponent("graphics/items"))
        try makeDirectory(root.appendingPathComponent("data/scripts"))
        try makeDirectory(root.appendingPathComponent("data/maps"))
        try write("[]\n", to: root.appendingPathComponent("data/maps/map_groups.json"))
        try configure(root)
        return root
    }

    private func makeDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private func write(_ text: String, to url: URL) throws {
        try makeDirectory(url.deletingLastPathComponent())
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
}

private final class TemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackCoreTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
