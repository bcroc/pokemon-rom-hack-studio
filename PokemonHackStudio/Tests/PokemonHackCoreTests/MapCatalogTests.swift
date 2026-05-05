import XCTest
@testable import PokemonHackCore

final class MapCatalogTests: XCTestCase {
    private var temporaryDirectories: [MapCatalogTemporaryDirectory] = []

    override func tearDown() {
        temporaryDirectories.removeAll()
        super.tearDown()
    }

    func testConnectionsIncludeOrderIsCatalogMetadataNotMapGroup() throws {
        let root = try makeProjectRoot(
            mapGroups:
            """
            {
              "group_order": ["gMapGroup_Towns"],
              "gMapGroup_Towns": ["PalletTown"],
              "connections_include_order": ["PalletTown", "Route1"]
            }
            """,
            layouts:
            """
            {
              "layouts_table_label": "gMapLayouts",
              "layouts": [
                {
                  "id": "LAYOUT_PALLET_TOWN",
                  "name": "PalletTown_Layout",
                  "width": 1,
                  "height": 1,
                  "primary_tileset": "gTileset_General",
                  "secondary_tileset": "gTileset_Pallet",
                  "border_filepath": "data/layouts/PalletTown/border.bin",
                  "blockdata_filepath": "data/layouts/PalletTown/map.bin"
                }
              ]
            }
            """
        )
        try writeMap(
            named: "PalletTown",
            root: root,
            json: minimalMapJSON(id: "MAP_PALLET_TOWN", name: "PalletTown", layout: "LAYOUT_PALLET_TOWN")
        )
        try writeBlockdata([7], to: "data/layouts/PalletTown/map.bin", root: root)

        let decoded = try SourceParsers.decodeMapGroups(
            Data(contentsOf: root.appendingPathComponent("data/maps/map_groups.json"))
        )
        let catalog = try ProjectMapCatalogLoader.load(from: projectIndex(root: root))

        XCTAssertEqual(decoded.connectionsIncludeOrder, ["PalletTown", "Route1"])
        XCTAssertNil(decoded.groups["connections_include_order"])
        XCTAssertEqual(catalog.connectionsIncludeOrder, ["PalletTown", "Route1"])
        XCTAssertEqual(catalog.mapGroups.map(\.id), ["gMapGroup_Towns"])
    }

    func testFireRedLayoutSlotsPreserveEmptySlotsAndBorderDimensions() throws {
        let layouts = try SourceParsers.decodeLayouts(
            Data(
                """
                {
                  "layouts_table_label": "gMapLayouts",
                  "layouts": [
                    {},
                    {
                      "id": "LAYOUT_ROUTE1",
                      "name": "Route1_Layout",
                      "width": 2,
                      "height": 2,
                      "border_width": 2,
                      "border_height": 3,
                      "primary_tileset": "gTileset_General",
                      "secondary_tileset": "gTileset_Route",
                      "border_filepath": "data/layouts/Route1/border.bin",
                      "blockdata_filepath": "data/layouts/Route1/map.bin"
                    }
                  ]
                }
                """.utf8
            )
        )

        XCTAssertEqual(layouts.layoutSlots.count, 2)
        XCTAssertNil(layouts.layoutSlots[0])
        XCTAssertEqual(layouts.layouts.count, 1)
        XCTAssertEqual(layouts.layouts[0].slotIndex, 1)
        XCTAssertEqual(layouts.layouts[0].borderWidth, 2)
        XCTAssertEqual(layouts.layouts[0].borderHeight, 3)
    }

    func testCatalogLinksMapsToLayoutSlotsAndPreviewsBlockdata() throws {
        let root = try makeProjectRoot(
            mapGroups:
            """
            {
              "group_order": ["gMapGroup_Routes"],
              "gMapGroup_Routes": ["Route1"]
            }
            """,
            layouts:
            """
            {
              "layouts_table_label": "gMapLayouts",
              "layouts": [
                {},
                {
                  "id": "LAYOUT_ROUTE1",
                  "name": "Route1_Layout",
                  "width": 2,
                  "height": 2,
                  "border_width": 2,
                  "border_height": 2,
                  "primary_tileset": "gTileset_General",
                  "secondary_tileset": "gTileset_Route",
                  "border_filepath": "data/layouts/Route1/border.bin",
                  "blockdata_filepath": "data/layouts/Route1/map.bin"
                }
              ]
            }
            """
        )
        try writeMap(
            named: "Route1",
            root: root,
            json:
            """
            {
              "id": "MAP_ROUTE1",
              "name": "Route1",
              "layout": "LAYOUT_ROUTE1",
              "music": "MUS_ROUTE1",
              "region_map_section": "MAPSEC_ROUTE1",
              "weather": "WEATHER_SUNNY",
              "map_type": "MAP_TYPE_ROUTE",
              "floor_number": 0,
              "connections": [
                { "map": "MAP_PALLET_TOWN", "offset": 0, "direction": "down" }
              ],
              "object_events": [],
              "warp_events": [],
              "coord_events": [],
              "bg_events": []
            }
            """
        )
        try writeBlockdata([1, 2, 0x1234, 0xffff], to: "data/layouts/Route1/map.bin", root: root)

        let catalog = try ProjectMapCatalogLoader.load(from: projectIndex(root: root))
        let map = try XCTUnwrap(catalog.maps.first)
        let layout = try XCTUnwrap(catalog.layoutSlots.first { $0.layoutID == "LAYOUT_ROUTE1" })
        let preview = try XCTUnwrap(layout.blockdataPreview)

        XCTAssertEqual(map.layoutSlotIndex, 1)
        XCTAssertEqual(map.connections.first?.map, "MAP_PALLET_TOWN")
        XCTAssertEqual(map.connections.first?.direction, "down")
        XCTAssertEqual(preview.expectedByteCount, 8)
        XCTAssertEqual(preview.actualByteCount, 8)
        XCTAssertTrue(preview.isByteCountValid)
        XCTAssertEqual(preview.metatileIDs, [1, 2, 0x1234, 0xffff])
    }

    func testMissingLayoutAddsDiagnostic() throws {
        let root = try makeProjectRoot(
            mapGroups:
            """
            {
              "group_order": ["gMapGroup_Routes"],
              "gMapGroup_Routes": ["Route1"]
            }
            """,
            layouts:
            """
            {
              "layouts_table_label": "gMapLayouts",
              "layouts": []
            }
            """
        )
        try writeMap(
            named: "Route1",
            root: root,
            json: minimalMapJSON(id: "MAP_ROUTE1", name: "Route1", layout: "LAYOUT_ROUTE1")
        )

        let catalog = try ProjectMapCatalogLoader.load(from: projectIndex(root: root))

        XCTAssertEqual(catalog.maps.first?.layoutSlotIndex, nil)
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "MAP_LAYOUT_MISSING" })
    }

    func testMapDescriptorCapturesEventsAndFireRedFields() throws {
        let root = try makeProjectRoot(
            mapGroups:
            """
            {
              "group_order": ["gMapGroup_Dungeons"],
              "gMapGroup_Dungeons": ["RocketHideout_B3F"]
            }
            """,
            layouts:
            """
            {
              "layouts_table_label": "gMapLayouts",
              "layouts": [
                {
                  "id": "LAYOUT_ROCKET_HIDEOUT_B3F",
                  "name": "RocketHideout_B3F_Layout",
                  "width": 1,
                  "height": 1,
                  "border_width": 0,
                  "border_height": 0,
                  "primary_tileset": "gTileset_Cave",
                  "secondary_tileset": "gTileset_Rocket",
                  "border_filepath": "data/layouts/RocketHideout_B3F/border.bin",
                  "blockdata_filepath": "data/layouts/RocketHideout_B3F/map.bin"
                }
              ]
            }
            """
        )
        try writeMap(
            named: "RocketHideout_B3F",
            root: root,
            json:
            """
            {
              "id": "MAP_ROCKET_HIDEOUT_B3F",
              "name": "RocketHideout_B3F",
              "layout": "LAYOUT_ROCKET_HIDEOUT_B3F",
              "music": "MUS_ROCKET_HIDEOUT",
              "region_map_section": "MAPSEC_ROCKET_HIDEOUT",
              "weather": "WEATHER_NONE",
              "map_type": "MAP_TYPE_UNDERGROUND",
              "floor_number": -3,
              "shared_events_map": "RocketHideout",
              "shared_scripts_map": "RocketHideout",
              "connections": null,
              "connections_no_include": true,
              "object_events": [{}, {}],
              "warp_events": [{}],
              "coord_events": [{}],
              "bg_events": [{}, {}]
            }
            """
        )
        try writeBlockdata([0], to: "data/layouts/RocketHideout_B3F/map.bin", root: root)

        let map = try XCTUnwrap(try ProjectMapCatalogLoader.load(from: projectIndex(root: root)).maps.first)

        XCTAssertEqual(map.music, "MUS_ROCKET_HIDEOUT")
        XCTAssertEqual(map.mapType, "MAP_TYPE_UNDERGROUND")
        XCTAssertEqual(map.weather, "WEATHER_NONE")
        XCTAssertEqual(map.regionMapSection, "MAPSEC_ROCKET_HIDEOUT")
        XCTAssertEqual(map.floorNumber, -3)
        XCTAssertEqual(map.sharedEventsMap, "RocketHideout")
        XCTAssertEqual(map.sharedScriptsMap, "RocketHideout")
        XCTAssertTrue(map.connectionsNoInclude)
        XCTAssertEqual(map.connections.count, 0)
        XCTAssertEqual(map.eventCounts.objectEvents, 2)
        XCTAssertEqual(map.eventCounts.warpEvents, 1)
        XCTAssertEqual(map.eventCounts.coordEvents, 1)
        XCTAssertEqual(map.eventCounts.bgEvents, 2)
    }

    func testBlockdataSizeMismatchIsReported() throws {
        let root = try makeProjectRoot(
            mapGroups:
            """
            {
              "group_order": ["gMapGroup_Test"],
              "gMapGroup_Test": ["Short"]
            }
            """,
            layouts:
            """
            {
              "layouts_table_label": "gMapLayouts",
              "layouts": [
                {
                  "id": "LAYOUT_SHORT",
                  "name": "Short_Layout",
                  "width": 2,
                  "height": 2,
                  "primary_tileset": "gTileset_General",
                  "secondary_tileset": "gTileset_Route",
                  "border_filepath": "data/layouts/Short/border.bin",
                  "blockdata_filepath": "data/layouts/Short/map.bin"
                }
              ]
            }
            """
        )
        try writeMap(
            named: "Short",
            root: root,
            json: minimalMapJSON(id: "MAP_SHORT", name: "Short", layout: "LAYOUT_SHORT")
        )
        try write(Data([0x01, 0x00, 0x02, 0x00, 0x03, 0x00]), to: root.appendingPathComponent("data/layouts/Short/map.bin"))

        let catalog = try ProjectMapCatalogLoader.load(from: projectIndex(root: root))
        let preview = try XCTUnwrap(catalog.layoutSlots.first?.blockdataPreview)

        XCTAssertEqual(preview.expectedByteCount, 8)
        XCTAssertEqual(preview.actualByteCount, 6)
        XCTAssertFalse(preview.isByteCountValid)
        XCTAssertEqual(preview.metatileIDs, [1, 2, 3])
        XCTAssertTrue(catalog.diagnostics.contains { $0.code == "LAYOUT_BLOCKDATA_SIZE_MISMATCH" })
    }

    func testUnreferencedLayoutBlockdataMismatchIsNotDiagnostic() throws {
        let root = try makeProjectRoot(
            mapGroups:
            """
            {
              "group_order": []
            }
            """,
            layouts:
            """
            {
              "layouts_table_label": "gMapLayouts",
              "layouts": [
                {
                  "id": "LAYOUT_UNUSED",
                  "name": "Unused_Layout",
                  "width": 2,
                  "height": 2,
                  "primary_tileset": "gTileset_General",
                  "secondary_tileset": "gTileset_Route",
                  "border_filepath": "data/layouts/Unused/border.bin",
                  "blockdata_filepath": "data/layouts/Unused/map.bin"
                }
              ]
            }
            """
        )
        try write(Data([0x01, 0x00]), to: root.appendingPathComponent("data/layouts/Unused/map.bin"))

        let catalog = try ProjectMapCatalogLoader.load(from: projectIndex(root: root))

        XCTAssertFalse(catalog.layoutSlots.first?.blockdataPreview?.isByteCountValid ?? true)
        XCTAssertFalse(catalog.diagnostics.contains { $0.code == "LAYOUT_BLOCKDATA_SIZE_MISMATCH" })
    }

    private func makeProjectRoot(mapGroups: String, layouts: String) throws -> URL {
        let temp = try MapCatalogTemporaryDirectory()
        temporaryDirectories.append(temp)

        let root = temp.url
        try makeDirectory(root.appendingPathComponent("data/maps"))
        try makeDirectory(root.appendingPathComponent("data/layouts"))
        try write(mapGroups, to: root.appendingPathComponent("data/maps/map_groups.json"))
        try write(layouts, to: root.appendingPathComponent("data/layouts/layouts.json"))
        return root
    }

    private func projectIndex(root: URL) -> ProjectIndex {
        ProjectIndex(
            root: SourceLocation(path: root.path, exists: true),
            profile: .pokefirered,
            adapterID: "test.fixture",
            adapterName: "Fixture",
            editorModules: [.maps],
            capabilities: [.mapIndex, .layoutIndex],
            writePolicy: .mutationPlanOnly,
            documents: []
        )
    }

    private func minimalMapJSON(id: String, name: String, layout: String) -> String {
        """
        {
          "id": "\(id)",
          "name": "\(name)",
          "layout": "\(layout)",
          "music": "MUS_NONE",
          "region_map_section": "MAPSEC_NONE",
          "weather": "WEATHER_NONE",
          "map_type": "MAP_TYPE_NONE",
          "connections": [],
          "object_events": [],
          "warp_events": [],
          "coord_events": [],
          "bg_events": []
        }
        """
    }

    private func writeMap(named name: String, root: URL, json: String) throws {
        try write(json, to: root.appendingPathComponent("data/maps/\(name)/map.json"))
    }

    private func writeBlockdata(_ words: [UInt16], to relativePath: String, root: URL) throws {
        var data = Data()
        for word in words {
            data.append(UInt8(word & 0x00ff))
            data.append(UInt8((word & 0xff00) >> 8))
        }
        try write(data, to: root.appendingPathComponent(relativePath))
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

private final class MapCatalogTemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PokemonHackMapCatalogTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
