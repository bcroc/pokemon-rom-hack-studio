import XCTest
@testable import PokemonHackCore

final class WorkspacePersistenceTests: XCTestCase {
    private var temporaryDirectories: [WorkspacePersistenceTemporaryDirectory] = []

    override func tearDown() {
        temporaryDirectories.removeAll()
        super.tearDown()
    }

    func testProjectWorkspaceRoundTripsWithDraftCounts() throws {
        let temp = try WorkspacePersistenceTemporaryDirectory()
        temporaryDirectories.append(temp)
        let savedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let workspace = SavedHackWorkspace(
            savedAt: savedAt,
            projectRootPath: temp.url.path,
            projectTitle: "pokeemerald",
            profile: .pokeemerald,
            adapterID: "pret.pokeemerald",
            selectedModule: "Moves",
            selectedMapID: "MAP_ROUTE1",
            selectedMoveID: "MOVE_POUND",
            drafts: SavedDraftSnapshot(
                moveDrafts: [
                    MoveEditDraft(
                        moveID: "MOVE_POUND",
                        effect: "EFFECT_HIT",
                        power: 45,
                        type: "TYPE_NORMAL",
                        accuracy: 100,
                        pp: 35,
                        secondaryEffectChance: 0,
                        target: "MOVE_TARGET_SELECTED",
                        priority: 0,
                        flags: ["FLAG_MAKES_CONTACT"]
                    )
                ],
                itemDrafts: [
                    ItemEditDraft(itemID: "ITEM_POTION", name: "POTION", price: "400")
                ],
                mapDrafts: [
                    SavedMapDraftSnapshot(
                        mapID: "MAP_ROUTE1",
                        documentID: "route1-document",
                        operations: [
                            MapEditOperation(action: .paintMetatile, target: .layout, x: 0, y: 1, rawValue: 0x22)
                        ]
                    )
                ],
                graphicsDrafts: [
                    GraphicsEditDraft(
                        tilesetSymbol: "gTileset_General",
                        operations: [
                            .metatileTile(
                                path: "data/tilesets/general/metatiles.bin",
                                metatileLocalID: 0,
                                tileEntryIndex: 0,
                                rawTileValue: 0x22
                            )
                        ]
                    )
                ],
                ndsDataDrafts: [
                    NDSDataEditDraft(recordID: "species:res/pokemon/abra/data.json", editedText: "{\"base_hp\":26}\n")
                ]
            )
        )

        try ProjectWorkspacePersistence.saveProject(workspace, root: temp.url)
        let loaded = try XCTUnwrap(ProjectWorkspacePersistence.loadProject(root: temp.url))

        XCTAssertEqual(loaded, workspace)
        XCTAssertEqual(loaded.drafts.counts.moves, 1)
        XCTAssertEqual(loaded.drafts.counts.items, 1)
        XCTAssertEqual(loaded.drafts.counts.maps, 1)
        XCTAssertEqual(loaded.drafts.counts.graphics, 1)
        XCTAssertEqual(loaded.drafts.counts.ndsData, 1)
        XCTAssertEqual(loaded.drafts.counts.total, 5)
        XCTAssertTrue(FileManager.default.fileExists(atPath: temp.url.appendingPathComponent(".pokemonhackstudio/project.json").path))
    }

    func testMissingWorkspaceFilesReturnNil() throws {
        let temp = try WorkspacePersistenceTemporaryDirectory()
        temporaryDirectories.append(temp)

        XCTAssertNil(try ProjectWorkspacePersistence.loadProject(root: temp.url))
        XCTAssertNil(try ProjectWorkspacePersistence.loadAutosave(root: temp.url))
    }

    func testAutosaveCanBeOverwrittenAndDiscarded() throws {
        let temp = try WorkspacePersistenceTemporaryDirectory()
        temporaryDirectories.append(temp)
        let first = workspace(root: temp.url, selectedItemID: "ITEM_POTION")
        let second = workspace(root: temp.url, selectedItemID: "ITEM_ESCAPE_ROPE")

        try ProjectWorkspacePersistence.saveAutosave(first, root: temp.url)
        try ProjectWorkspacePersistence.saveAutosave(second, root: temp.url)

        XCTAssertEqual(try ProjectWorkspacePersistence.loadAutosave(root: temp.url)?.selectedItemID, "ITEM_ESCAPE_ROPE")

        try ProjectWorkspacePersistence.discardAutosave(root: temp.url)

        XCTAssertNil(try ProjectWorkspacePersistence.loadAutosave(root: temp.url))
    }

    func testWorkspacePersistenceBlocksSymlinkEscapedWorkspaceDirectory() throws {
        let temp = try WorkspacePersistenceTemporaryDirectory()
        temporaryDirectories.append(temp)
        let outsideTemp = try WorkspacePersistenceTemporaryDirectory()
        temporaryDirectories.append(outsideTemp)
        let outside = outsideTemp.url
        try FileManager.default.createSymbolicLink(
            at: temp.url.appendingPathComponent(".pokemonhackstudio"),
            withDestinationURL: outside
        )
        let saved = workspace(root: temp.url, selectedItemID: "ITEM_POTION")

        XCTAssertThrowsError(try ProjectWorkspacePersistence.saveProject(saved, root: temp.url)) { error in
            guard case ProjectWorkspacePersistenceError.unsafeWorkspacePath(let code, _) = error else {
                return XCTFail("Expected unsafe workspace path, got \(error)")
            }
            XCTAssertEqual(code, "WORKSPACE_PATH_SYMLINK_OUTSIDE_ROOT")
        }
        XCTAssertThrowsError(try ProjectWorkspacePersistence.saveAutosave(saved, root: temp.url))
        XCTAssertThrowsError(try ProjectWorkspacePersistence.discardAutosave(root: temp.url))
        XCTAssertFalse(FileManager.default.fileExists(atPath: outside.appendingPathComponent("project.json").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: outside.appendingPathComponent("drafts/autosave.json").path))
    }

    func testUnsupportedSchemaVersionThrows() throws {
        let temp = try WorkspacePersistenceTemporaryDirectory()
        temporaryDirectories.append(temp)
        let unsupported = SavedHackWorkspace(
            schemaVersion: SavedHackWorkspace.currentSchemaVersion + 100,
            savedAt: Date(timeIntervalSince1970: 1_700_000_000),
            projectRootPath: temp.url.path,
            projectTitle: "pokeemerald",
            profile: .pokeemerald,
            adapterID: "pret.pokeemerald"
        )

        try ProjectWorkspacePersistence.saveProject(unsupported, root: temp.url)

        XCTAssertThrowsError(try ProjectWorkspacePersistence.loadProject(root: temp.url)) { error in
            XCTAssertEqual(error as? ProjectWorkspacePersistenceError, .unsupportedSchemaVersion(101))
        }
    }

    private func workspace(root: URL, selectedItemID: String) -> SavedHackWorkspace {
        SavedHackWorkspace(
            savedAt: Date(timeIntervalSince1970: 1_700_000_000),
            projectRootPath: root.path,
            projectTitle: "pokeemerald",
            profile: .pokeemerald,
            adapterID: "pret.pokeemerald",
            selectedItemID: selectedItemID,
            drafts: SavedDraftSnapshot(
                itemDrafts: [ItemEditDraft(itemID: selectedItemID, name: "ITEM", price: "1")]
            )
        )
    }
}

private final class WorkspacePersistenceTemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackWorkspacePersistenceTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
