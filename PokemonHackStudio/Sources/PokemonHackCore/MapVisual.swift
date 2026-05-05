import Foundation

public struct MapVisualDocument: Codable, Equatable, Identifiable {
    public let id: String
    public let rootPath: String
    public let profile: GameProfile
    public let mapID: String
    public let mapName: String
    public let mapMetadata: MapVisualMapMetadata
    public let mapSourcePath: String
    public let layout: LayoutSlot
    public let blockdata: EditableLayoutBlockdata
    public let border: EditableLayoutBlockdata?
    public let primaryTileset: TilesetAsset?
    public let secondaryTileset: TilesetAsset?
    public let metatiles: [MetatileDefinition]
    public let events: [MapEventDescriptor]
    public let scene: MapVisualScene
    public let diagnostics: [Diagnostic]
    fileprivate let mapJSONText: String

    public init(
        id: String,
        rootPath: String,
        profile: GameProfile,
        mapID: String,
        mapName: String,
        mapMetadata: MapVisualMapMetadata? = nil,
        mapSourcePath: String,
        layout: LayoutSlot,
        blockdata: EditableLayoutBlockdata,
        border: EditableLayoutBlockdata?,
        primaryTileset: TilesetAsset?,
        secondaryTileset: TilesetAsset?,
        metatiles: [MetatileDefinition],
        events: [MapEventDescriptor],
        scene: MapVisualScene? = nil,
        diagnostics: [Diagnostic] = [],
        mapJSONText: String
    ) {
        self.id = id
        self.rootPath = rootPath
        self.profile = profile
        self.mapID = mapID
        self.mapName = mapName
        self.mapMetadata = mapMetadata ?? MapVisualMapMetadata(mapID: mapID, mapName: mapName, sourcePath: mapSourcePath)
        self.mapSourcePath = mapSourcePath
        self.layout = layout
        self.blockdata = blockdata
        self.border = border
        self.primaryTileset = primaryTileset
        self.secondaryTileset = secondaryTileset
        self.metatiles = metatiles
        self.events = events
        self.scene = scene ?? MapVisualScene(layoutWidth: blockdata.width, layoutHeight: blockdata.height)
        self.diagnostics = diagnostics
        self.mapJSONText = mapJSONText
    }
}

public struct MapVisualMapMetadata: Codable, Equatable, Identifiable {
    public var id: String { mapID }

    public let mapID: String
    public let mapName: String
    public let sourcePath: String
    public let music: String?
    public let mapType: String?
    public let weather: String?
    public let regionMapSection: String?
    public let floorNumber: Int?

    public init(
        mapID: String,
        mapName: String,
        sourcePath: String,
        music: String? = nil,
        mapType: String? = nil,
        weather: String? = nil,
        regionMapSection: String? = nil,
        floorNumber: Int? = nil
    ) {
        self.mapID = mapID
        self.mapName = mapName
        self.sourcePath = sourcePath
        self.music = music
        self.mapType = mapType
        self.weather = weather
        self.regionMapSection = regionMapSection
        self.floorNumber = floorNumber
    }
}

public enum MapScenePlacementRole: String, Codable, Equatable {
    case layout
    case connection
}

public enum MapSceneConnectionDirection: String, Codable, Equatable, CaseIterable {
    case up
    case down
    case left
    case right

    public init?(rawConnectionDirection: String?) {
        guard let value = rawConnectionDirection?.lowercased() else { return nil }
        switch value {
        case "up", "north":
            self = .up
        case "down", "south":
            self = .down
        case "left", "west":
            self = .left
        case "right", "east":
            self = .right
        default:
            return nil
        }
    }
}

public struct MapSceneViewport: Codable, Equatable, Identifiable {
    public var id: String { "\(minX),\(minY),\(width),\(height)" }

    public let minX: Int
    public let minY: Int
    public let width: Int
    public let height: Int
    public let layoutOriginX: Int
    public let layoutOriginY: Int
    public let layoutWidth: Int
    public let layoutHeight: Int
    public let marginX: Int
    public let marginY: Int

    public var maxXExclusive: Int { minX + width }
    public var maxYExclusive: Int { minY + height }

    public init(
        minX: Int,
        minY: Int,
        width: Int,
        height: Int,
        layoutOriginX: Int,
        layoutOriginY: Int,
        layoutWidth: Int,
        layoutHeight: Int,
        marginX: Int = MapVisualScene.gameViewportTileWidth,
        marginY: Int = MapVisualScene.gameViewportTileHeight
    ) {
        self.minX = minX
        self.minY = minY
        self.width = max(width, 0)
        self.height = max(height, 0)
        self.layoutOriginX = layoutOriginX
        self.layoutOriginY = layoutOriginY
        self.layoutWidth = max(layoutWidth, 0)
        self.layoutHeight = max(layoutHeight, 0)
        self.marginX = max(marginX, 0)
        self.marginY = max(marginY, 0)
    }

    public func contains(sceneX: Int, sceneY: Int) -> Bool {
        sceneX >= minX
            && sceneY >= minY
            && sceneX < maxXExclusive
            && sceneY < maxYExclusive
    }
}

public struct MapScenePlacement: Codable, Equatable, Identifiable {
    public let id: String
    public let role: MapScenePlacementRole
    public let mapID: String
    public let mapName: String
    public let originX: Int
    public let originY: Int
    public let width: Int
    public let height: Int
    public let rawValues: [UInt16]
    public let sourcePath: String?

    public init(
        id: String,
        role: MapScenePlacementRole,
        mapID: String,
        mapName: String,
        originX: Int,
        originY: Int,
        width: Int,
        height: Int,
        rawValues: [UInt16],
        sourcePath: String? = nil
    ) {
        self.id = id
        self.role = role
        self.mapID = mapID
        self.mapName = mapName
        self.originX = originX
        self.originY = originY
        self.width = max(width, 0)
        self.height = max(height, 0)
        self.rawValues = rawValues
        self.sourcePath = sourcePath
    }

    public var maxXExclusive: Int { originX + width }
    public var maxYExclusive: Int { originY + height }

    public func contains(sceneX: Int, sceneY: Int) -> Bool {
        sceneX >= originX
            && sceneY >= originY
            && sceneX < maxXExclusive
            && sceneY < maxYExclusive
    }

    public func rawValue(sceneX: Int, sceneY: Int) -> UInt16? {
        guard contains(sceneX: sceneX, sceneY: sceneY) else { return nil }
        let localX = sceneX - originX
        let localY = sceneY - originY
        let index = localY * width + localX
        guard rawValues.indices.contains(index) else { return nil }
        return rawValues[index]
    }
}

public struct MapSceneConnection: Codable, Equatable, Identifiable {
    public var id: String { "\(sourceMapID)-\(index)-\(direction?.rawValue ?? "unknown")" }

    public let sourceMapID: String
    public let index: Int
    public let targetMapID: String?
    public let targetMapName: String?
    public let direction: MapSceneConnectionDirection?
    public let offset: Int
    public let placementID: String?
    public let isResolved: Bool
    public let diagnostic: Diagnostic?

    public init(
        sourceMapID: String,
        index: Int,
        targetMapID: String?,
        targetMapName: String?,
        direction: MapSceneConnectionDirection?,
        offset: Int,
        placementID: String?,
        isResolved: Bool,
        diagnostic: Diagnostic? = nil
    ) {
        self.sourceMapID = sourceMapID
        self.index = index
        self.targetMapID = targetMapID
        self.targetMapName = targetMapName
        self.direction = direction
        self.offset = offset
        self.placementID = placementID
        self.isResolved = isResolved
        self.diagnostic = diagnostic
    }
}

public struct MapVisualScene: Codable, Equatable, Identifiable {
    public static let gameViewportTileWidth = 15
    public static let gameViewportTileHeight = 10

    public var id: String { viewport.id }

    public let viewport: MapSceneViewport
    public let placements: [MapScenePlacement]
    public let connections: [MapSceneConnection]
    public let diagnostics: [Diagnostic]

    public init(
        viewport: MapSceneViewport,
        placements: [MapScenePlacement],
        connections: [MapSceneConnection] = [],
        diagnostics: [Diagnostic] = []
    ) {
        self.viewport = viewport
        self.placements = placements
        self.connections = connections
        self.diagnostics = diagnostics
    }

    public init(layoutWidth: Int, layoutHeight: Int) {
        let viewport = MapVisualScene.viewport(layoutWidth: layoutWidth, layoutHeight: layoutHeight, placements: [])
        self.init(
            viewport: viewport,
            placements: [
                MapScenePlacement(
                    id: "layout",
                    role: .layout,
                    mapID: "",
                    mapName: "Layout",
                    originX: 0,
                    originY: 0,
                    width: layoutWidth,
                    height: layoutHeight,
                    rawValues: []
                )
            ]
        )
    }

    public var layoutPlacement: MapScenePlacement? {
        placements.first { $0.role == .layout }
    }

    public func placement(containingSceneX sceneX: Int, sceneY: Int) -> MapScenePlacement? {
        placements.reversed().first { $0.contains(sceneX: sceneX, sceneY: sceneY) }
    }

    public static func viewport(
        layoutWidth: Int,
        layoutHeight: Int,
        placements: [MapScenePlacement],
        marginX: Int = gameViewportTileWidth,
        marginY: Int = gameViewportTileHeight
    ) -> MapSceneViewport {
        var minX = -marginX
        var minY = -marginY
        var maxX = layoutWidth + marginX
        var maxY = layoutHeight + marginY
        for placement in placements {
            minX = Swift.min(minX, placement.originX)
            minY = Swift.min(minY, placement.originY)
            maxX = Swift.max(maxX, placement.maxXExclusive)
            maxY = Swift.max(maxY, placement.maxYExclusive)
        }
        return MapSceneViewport(
            minX: minX,
            minY: minY,
            width: maxX - minX,
            height: maxY - minY,
            layoutOriginX: 0,
            layoutOriginY: 0,
            layoutWidth: layoutWidth,
            layoutHeight: layoutHeight,
            marginX: marginX,
            marginY: marginY
        )
    }
}

public struct EditableLayoutBlockdata: Codable, Equatable, Identifiable {
    public var id: String { filepath }

    public let filepath: String
    public let width: Int
    public let height: Int
    public let rawValues: [UInt16]

    public var metatileIDs: [Int] {
        rawValues.map { Int($0 & 0x03ff) }
    }

    public var expectedByteCount: Int {
        width * height * 2
    }

    public var actualByteCount: Int {
        rawValues.count * 2
    }

    public var isComplete: Bool {
        rawValues.count == width * height
    }

    public init(filepath: String, width: Int, height: Int, rawValues: [UInt16]) {
        self.filepath = filepath
        self.width = width
        self.height = height
        self.rawValues = rawValues
    }
}

public struct TilesetAsset: Codable, Equatable, Identifiable {
    public var id: String { symbol }

    public let symbol: String
    public let isSecondary: Bool
    public let tileImagePath: String?
    public let palettePaths: [String]
    public let metatilesPath: String?
    public let metatileAttributesPath: String?
    public let metatileAttributeWordSize: Int
    public let metatileCount: Int
    public let diagnostics: [Diagnostic]

    public init(
        symbol: String,
        isSecondary: Bool,
        tileImagePath: String?,
        palettePaths: [String] = [],
        metatilesPath: String?,
        metatileAttributesPath: String?,
        metatileAttributeWordSize: Int = 2,
        metatileCount: Int = 0,
        diagnostics: [Diagnostic] = []
    ) {
        self.symbol = symbol
        self.isSecondary = isSecondary
        self.tileImagePath = tileImagePath
        self.palettePaths = palettePaths
        self.metatilesPath = metatilesPath
        self.metatileAttributesPath = metatileAttributesPath
        self.metatileAttributeWordSize = metatileAttributeWordSize
        self.metatileCount = metatileCount
        self.diagnostics = diagnostics
    }
}

public struct MetatileDefinition: Codable, Equatable, Identifiable {
    public let id: Int
    public let localID: Int
    public let tilesetSymbol: String
    public let tileEntries: [MetatileTileEntry]
    public let attribute: MetatileAttribute?

    public init(
        id: Int,
        localID: Int,
        tilesetSymbol: String,
        tileEntries: [MetatileTileEntry],
        attribute: MetatileAttribute?
    ) {
        self.id = id
        self.localID = localID
        self.tilesetSymbol = tilesetSymbol
        self.tileEntries = tileEntries
        self.attribute = attribute
    }
}

public struct MetatileTileEntry: Codable, Equatable, Identifiable {
    public var id: Int { index }

    public let index: Int
    public let rawValue: UInt16
    public let tileIndex: Int
    public let palette: Int
    public let hFlip: Bool
    public let vFlip: Bool

    public init(index: Int, rawValue: UInt16) {
        self.index = index
        self.rawValue = rawValue
        tileIndex = Int(rawValue & 0x03ff)
        hFlip = (rawValue & 0x0400) != 0
        vFlip = (rawValue & 0x0800) != 0
        palette = Int((rawValue >> 12) & 0x000f)
    }
}

public enum MetatileLayerType: Int, Codable, Equatable, CaseIterable {
    case normal = 0
    case covered = 1
    case split = 2

    public var displayName: String {
        switch self {
        case .normal:
            return "Normal"
        case .covered:
            return "Covered"
        case .split:
            return "Split"
        }
    }

    static func rawLayerType(from rawValue: UInt32, wordSize: Int) -> Int {
        if wordSize == 4 {
            return Int((rawValue >> 29) & 0x00000003)
        }
        return Int((rawValue >> 12) & 0x0000000f)
    }
}

public struct MetatileAttribute: Codable, Equatable {
    public let rawValue: UInt32
    public let rawLayerType: Int
    public let layerType: MetatileLayerType

    public var behavior: Int {
        Int(rawValue & 0x01ff)
    }

    public init(rawValue: UInt32, wordSize: Int = 2) {
        self.rawValue = rawValue
        rawLayerType = MetatileLayerType.rawLayerType(from: rawValue, wordSize: wordSize)
        layerType = MetatileLayerType(rawValue: rawLayerType) ?? .normal
    }
}

public enum MapEventKind: String, Codable, Equatable, CaseIterable {
    case object
    case warp
    case coord
    case bg
    case connection
}

public struct MapEventProperty: Codable, Equatable, Identifiable {
    public var id: String { key }

    public let key: String
    public let value: String

    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

public struct MapEventSpriteDescriptor: Codable, Equatable, Identifiable {
    public var id: String { graphicsID }

    public let graphicsID: String
    public let graphicsConstantValue: Int?
    public let graphicsInfoSymbol: String?
    public let imageSymbol: String?
    public let imageAssetPath: String?
    public let frameWidth: Int?
    public let frameHeight: Int?
    public let tileTag: String?
    public let paletteTag: String?
    public let reflectionPaletteTag: String?
    public let size: Int?
    public let width: Int?
    public let height: Int?
    public let paletteSlot: String?
    public let shadowSize: String?
    public let inanimate: Bool?
    public let tracks: String?
    public let oam: String?
    public let subspriteTables: String?
    public let anims: String?
    public let images: String?
    public let sourcePath: String?

    public init(
        graphicsID: String,
        graphicsConstantValue: Int? = nil,
        graphicsInfoSymbol: String? = nil,
        imageSymbol: String? = nil,
        imageAssetPath: String? = nil,
        frameWidth: Int? = nil,
        frameHeight: Int? = nil,
        tileTag: String? = nil,
        paletteTag: String? = nil,
        reflectionPaletteTag: String? = nil,
        size: Int? = nil,
        width: Int? = nil,
        height: Int? = nil,
        paletteSlot: String? = nil,
        shadowSize: String? = nil,
        inanimate: Bool? = nil,
        tracks: String? = nil,
        oam: String? = nil,
        subspriteTables: String? = nil,
        anims: String? = nil,
        images: String? = nil,
        sourcePath: String? = nil
    ) {
        self.graphicsID = graphicsID
        self.graphicsConstantValue = graphicsConstantValue
        self.graphicsInfoSymbol = graphicsInfoSymbol
        self.imageSymbol = imageSymbol
        self.imageAssetPath = imageAssetPath
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight
        self.tileTag = tileTag
        self.paletteTag = paletteTag
        self.reflectionPaletteTag = reflectionPaletteTag
        self.size = size
        self.width = width
        self.height = height
        self.paletteSlot = paletteSlot
        self.shadowSize = shadowSize
        self.inanimate = inanimate
        self.tracks = tracks
        self.oam = oam
        self.subspriteTables = subspriteTables
        self.anims = anims
        self.images = images
        self.sourcePath = sourcePath
    }
}

public struct MapEventDescriptor: Codable, Equatable, Identifiable {
    public var id: String { "\(kind.rawValue)-\(index)" }

    public let kind: MapEventKind
    public let index: Int
    public let x: Int?
    public let y: Int?
    public let elevation: Int?
    public let properties: [MapEventProperty]
    public let sprite: MapEventSpriteDescriptor?

    public init(
        kind: MapEventKind,
        index: Int,
        x: Int?,
        y: Int?,
        elevation: Int?,
        properties: [MapEventProperty],
        sprite: MapEventSpriteDescriptor? = nil
    ) {
        self.kind = kind
        self.index = index
        self.x = x
        self.y = y
        self.elevation = elevation
        self.properties = properties
        self.sprite = sprite
    }
}

private struct ObjectEventSpriteIndex {
    private struct SpritePicTable {
        let imageSymbol: String
        let frameWidth: Int?
        let frameHeight: Int?
    }

    private struct GraphicsInfo {
        let symbol: String
        let tileTag: String?
        let paletteTag: String?
        let reflectionPaletteTag: String?
        let size: Int?
        let width: Int?
        let height: Int?
        let paletteSlot: String?
        let shadowSize: String?
        let inanimate: Bool?
        let tracks: String?
        let oam: String?
        let subspriteTables: String?
        let anims: String?
        let images: String?
    }

    private static let constantsPath = "include/constants/event_objects.h"
    private static let graphicsInfoPath = "src/data/object_events/object_event_graphics_info.h"
    private static let graphicsInfoPointersPath = "src/data/object_events/object_event_graphics_info_pointers.h"
    private static let picTablesPath = "src/data/object_events/object_event_pic_tables.h"
    private static let graphicsPath = "src/data/object_events/object_event_graphics.h"

    let spritesByGraphicsID: [String: MapEventSpriteDescriptor]

    func sprite(for graphicsID: String?) -> MapEventSpriteDescriptor? {
        guard let graphicsID else { return nil }
        return spritesByGraphicsID[graphicsID]
    }

    static func load(root: URL, fileManager: FileManager) -> ObjectEventSpriteIndex {
        let constants = parseConstants(readText(root: root, path: constantsPath))
        let pointerSymbols = parsePointerSymbols(readText(root: root, path: graphicsInfoPointersPath))
        let graphicsInfos = parseGraphicsInfos(readText(root: root, path: graphicsInfoPath))
        let picTables = parsePicTables(readText(root: root, path: picTablesPath))
        let imagePaths = parseImagePaths(
            readText(root: root, path: graphicsPath),
            root: root,
            fileManager: fileManager
        )

        var sprites: [String: MapEventSpriteDescriptor] = [:]
        for (graphicsID, graphicsInfoSymbol) in pointerSymbols {
            guard let info = graphicsInfos[graphicsInfoSymbol] else { continue }
            let picTable = info.images.flatMap { picTables[$0] }
            let imageAssetPath = picTable.flatMap { imagePaths[$0.imageSymbol] }
            sprites[graphicsID] = MapEventSpriteDescriptor(
                graphicsID: graphicsID,
                graphicsConstantValue: constants[graphicsID],
                graphicsInfoSymbol: info.symbol,
                imageSymbol: picTable?.imageSymbol,
                imageAssetPath: imageAssetPath,
                frameWidth: picTable?.frameWidth,
                frameHeight: picTable?.frameHeight,
                tileTag: info.tileTag,
                paletteTag: info.paletteTag,
                reflectionPaletteTag: info.reflectionPaletteTag,
                size: info.size,
                width: info.width,
                height: info.height,
                paletteSlot: info.paletteSlot,
                shadowSize: info.shadowSize,
                inanimate: info.inanimate,
                tracks: info.tracks,
                oam: info.oam,
                subspriteTables: info.subspriteTables,
                anims: info.anims,
                images: info.images,
                sourcePath: graphicsInfoPath
            )
        }
        return ObjectEventSpriteIndex(spritesByGraphicsID: sprites)
    }

    private static func readText(root: URL, path: String) -> String {
        let url = root.appendingPathComponent(path)
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    private static func parseConstants(_ text: String) -> [String: Int] {
        var constants: [String: Int] = [:]
        for match in matches(pattern: #"(?m)^\s*#define\s+(OBJ_EVENT_GFX_[A-Za-z0-9_]+)\s+([0-9]+)"#, in: text) {
            guard match.count > 2, let value = Int(match[2]) else { continue }
            constants[match[1]] = value
        }
        return constants
    }

    private static func parsePointerSymbols(_ text: String) -> [String: String] {
        var symbols: [String: String] = [:]
        for match in matches(pattern: #"\[(OBJ_EVENT_GFX_[A-Za-z0-9_]+)\]\s*=\s*&?(gObjectEventGraphicsInfo_[A-Za-z0-9_]+)"#, in: text) {
            guard match.count > 2 else { continue }
            symbols[match[1]] = match[2]
        }
        return symbols
    }

    private static func parseGraphicsInfos(_ text: String) -> [String: GraphicsInfo] {
        var infos: [String: GraphicsInfo] = [:]
        let pattern = #"const\s+struct\s+ObjectEventGraphicsInfo\s+(gObjectEventGraphicsInfo_[A-Za-z0-9_]+)\s*=\s*\{(.*?)\};"#
        for match in matches(pattern: pattern, in: text, options: .dotMatchesLineSeparators) {
            guard match.count > 2 else { continue }
            let symbol = match[1]
            let body = match[2]
            infos[symbol] = GraphicsInfo(
                symbol: symbol,
                tileTag: symbolField("tileTag", in: body),
                paletteTag: symbolField("paletteTag", in: body),
                reflectionPaletteTag: symbolField("reflectionPaletteTag", in: body),
                size: intField("size", in: body),
                width: intField("width", in: body),
                height: intField("height", in: body),
                paletteSlot: symbolField("paletteSlot", in: body),
                shadowSize: symbolField("shadowSize", in: body),
                inanimate: boolField("inanimate", in: body),
                tracks: symbolField("tracks", in: body),
                oam: symbolField("oam", in: body),
                subspriteTables: symbolField("subspriteTables", in: body),
                anims: symbolField("anims", in: body),
                images: symbolField("images", in: body)
            )
        }
        return infos
    }

    private static func parsePicTables(_ text: String) -> [String: SpritePicTable] {
        var tables: [String: SpritePicTable] = [:]
        let pattern = #"static\s+const\s+struct\s+SpriteFrameImage\s+(sPicTable_[A-Za-z0-9_]+)\[\]\s*=\s*\{(.*?)\};"#
        for match in matches(pattern: pattern, in: text, options: .dotMatchesLineSeparators) {
            guard match.count > 2 else { continue }
            let symbol = match[1]
            let body = match[2]
            guard let frame = matches(pattern: #"overworld_frame\((gObjectEventPic_[A-Za-z0-9_]+),\s*([0-9]+),\s*([0-9]+),"#, in: body).first,
                  frame.count > 3
            else { continue }
            tables[symbol] = SpritePicTable(
                imageSymbol: frame[1],
                frameWidth: Int(frame[2]).map { $0 * 8 },
                frameHeight: Int(frame[3]).map { $0 * 8 }
            )
        }
        return tables
    }

    private static func parseImagePaths(_ text: String, root: URL, fileManager: FileManager) -> [String: String] {
        var paths: [String: String] = [:]
        let pattern = #"const\s+u(?:16|32)\s+(gObjectEventPic_[A-Za-z0-9_]+)\[\]\s*=\s*(?:INCGFX_U(?:16|32)|INCBIN_U(?:16|32))\("([^"]+)""#
        for match in matches(pattern: pattern, in: text) {
            guard match.count > 2 else { continue }
            paths[match[1]] = resolvedRasterPath(match[2], root: root, fileManager: fileManager)
        }
        return paths
    }

    private static func resolvedRasterPath(_ path: String, root: URL, fileManager: FileManager) -> String {
        if path.hasSuffix(".png") {
            return path
        }
        let suffixes = [".4bpp.lz", ".4bpp", ".gbapal.lz", ".gbapal"]
        for suffix in suffixes where path.hasSuffix(suffix) {
            let candidate = String(path.dropLast(suffix.count)) + ".png"
            if fileManager.fileExists(atPath: root.appendingPathComponent(candidate).path) {
                return candidate
            }
        }
        return path
    }

    private static func symbolField(_ key: String, in text: String) -> String? {
        fieldValue(key, in: text).flatMap(normalizedSymbol)
    }

    private static func intField(_ key: String, in text: String) -> Int? {
        fieldValue(key, in: text).flatMap { Int($0) }
    }

    private static func boolField(_ key: String, in text: String) -> Bool? {
        guard let value = fieldValue(key, in: text) else { return nil }
        if value == "TRUE" { return true }
        if value == "FALSE" { return false }
        return nil
    }

    private static func fieldValue(_ key: String, in text: String) -> String? {
        let pattern = #"(?m)\."# + key + #"\s*=\s*([^,\n]+)"#
        guard let match = matches(pattern: pattern, in: text).first, match.count > 1 else { return nil }
        return match[1].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalizedSymbol(_ value: String) -> String? {
        var symbol = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if symbol.hasPrefix("&") {
            symbol.removeFirst()
        }
        guard !symbol.isEmpty, symbol != "NULL" else { return nil }
        return symbol
    }

    private static func matches(
        pattern: String,
        in text: String,
        options: NSRegularExpression.Options = []
    ) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return []
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).map { match in
            (0..<match.numberOfRanges).map { index in
                guard let range = Range(match.range(at: index), in: text) else { return "" }
                return String(text[range])
            }
        }
    }
}

public enum MapBlockTarget: String, Codable, Equatable {
    case layout
    case border
}

public enum MapEditAction: String, Codable, Equatable {
    case paintMetatile
    case fillMetatile
    case moveEvent
    case updateEventField
    case addEvent
    case duplicateEvent
    case deleteEvent
}

public struct MapEditOperation: Codable, Equatable, Identifiable {
    public let id: String
    public let action: MapEditAction
    public let target: MapBlockTarget?
    public let x: Int?
    public let y: Int?
    public let width: Int?
    public let height: Int?
    public let rawValue: UInt16?
    public let eventKind: MapEventKind?
    public let eventIndex: Int?
    public let fieldKey: String?
    public let fieldValue: String?
    public let templateProperties: [MapEventProperty]

    public init(
        id: String = UUID().uuidString,
        action: MapEditAction,
        target: MapBlockTarget? = nil,
        x: Int? = nil,
        y: Int? = nil,
        width: Int? = nil,
        height: Int? = nil,
        rawValue: UInt16? = nil,
        eventKind: MapEventKind? = nil,
        eventIndex: Int? = nil,
        fieldKey: String? = nil,
        fieldValue: String? = nil,
        templateProperties: [MapEventProperty] = []
    ) {
        self.id = id
        self.action = action
        self.target = target
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.rawValue = rawValue
        self.eventKind = eventKind
        self.eventIndex = eventIndex
        self.fieldKey = fieldKey
        self.fieldValue = fieldValue
        self.templateProperties = templateProperties
    }
}

public struct MapEditDraft: Codable, Equatable, Identifiable {
    public var id: String { documentID }

    public let documentID: String
    public let blockdata: EditableLayoutBlockdata
    public let border: EditableLayoutBlockdata?
    public let mapJSONText: String
    public let events: [MapEventDescriptor]
    public let diagnostics: [Diagnostic]

    public init(
        documentID: String,
        blockdata: EditableLayoutBlockdata,
        border: EditableLayoutBlockdata?,
        mapJSONText: String,
        events: [MapEventDescriptor],
        diagnostics: [Diagnostic]
    ) {
        self.documentID = documentID
        self.blockdata = blockdata
        self.border = border
        self.mapJSONText = mapJSONText
        self.events = events
        self.diagnostics = diagnostics
    }
}

public struct MapEditFileChange: Codable, Equatable, Identifiable {
    public var id: String { path }

    public let path: String
    public let summary: String
    public let originalByteCount: Int
    public let newByteCount: Int
    public let newData: Data
    public let textPreview: String?

    public init(
        path: String,
        summary: String,
        originalByteCount: Int,
        newByteCount: Int,
        newData: Data,
        textPreview: String? = nil
    ) {
        self.path = path
        self.summary = summary
        self.originalByteCount = originalByteCount
        self.newByteCount = newByteCount
        self.newData = newData
        self.textPreview = textPreview
    }
}

public struct MapEditPlan: Codable, Equatable, Identifiable {
    public let id: String
    public let rootPath: String
    public let documentID: String
    public let operations: [MapEditOperation]
    public let changes: [MapEditFileChange]
    public let diagnostics: [Diagnostic]
    public let mutationPlan: MutationPlan
    public let backupRelativeRoot: String

    public init(
        id: String = UUID().uuidString,
        rootPath: String,
        documentID: String,
        operations: [MapEditOperation],
        changes: [MapEditFileChange],
        diagnostics: [Diagnostic],
        mutationPlan: MutationPlan,
        backupRelativeRoot: String
    ) {
        self.id = id
        self.rootPath = rootPath
        self.documentID = documentID
        self.operations = operations
        self.changes = changes
        self.diagnostics = diagnostics
        self.mutationPlan = mutationPlan
        self.backupRelativeRoot = backupRelativeRoot
    }
}

public struct MapEditApplyability: Codable, Equatable {
    public let isApplyable: Bool
    public let diagnostics: [Diagnostic]

    public init(isApplyable: Bool, diagnostics: [Diagnostic]) {
        self.isApplyable = isApplyable
        self.diagnostics = diagnostics
    }
}

public extension MapEditPlan {
    var applyability: MapEditApplyability {
        validateApplyability()
    }

    var isApplyable: Bool {
        applyability.isApplyable
    }

    func validateApplyability(fileManager: FileManager = .default) -> MapEditApplyability {
        MapEditApplySafety.applyability(for: self, fileManager: fileManager)
    }
}

public struct AppliedMapFileChange: Codable, Equatable, Identifiable {
    public var id: String { path }

    public let path: String
    public let backupPath: String
    public let byteCount: Int

    public init(path: String, backupPath: String, byteCount: Int) {
        self.path = path
        self.backupPath = backupPath
        self.byteCount = byteCount
    }
}

public struct MapApplyResult: Codable, Equatable, Identifiable {
    public let id: String
    public let backupRootPath: String
    public let appliedChanges: [AppliedMapFileChange]
    public let diagnostics: [Diagnostic]

    public init(
        id: String = UUID().uuidString,
        backupRootPath: String,
        appliedChanges: [AppliedMapFileChange],
        diagnostics: [Diagnostic] = []
    ) {
        self.id = id
        self.backupRootPath = backupRootPath
        self.appliedChanges = appliedChanges
        self.diagnostics = diagnostics
    }
}

public struct TilesetIndex: Codable, Equatable {
    public let rootPath: String
    public let assets: [TilesetAsset]
    public let diagnostics: [Diagnostic]

    public init(rootPath: String, assets: [TilesetAsset], diagnostics: [Diagnostic] = []) {
        self.rootPath = rootPath
        self.assets = assets
        self.diagnostics = diagnostics
    }

    public func asset(symbol: String?) -> TilesetAsset? {
        guard let symbol else { return nil }
        return assets.first { $0.symbol == symbol }
    }
}

public enum TilesetIndexLoader {
    private static let headersPath = "src/data/tilesets/headers.h"
    private static let graphicsPath = "src/data/tilesets/graphics.h"
    private static let metatilesPath = "src/data/tilesets/metatiles.h"

    public static func load(from projectIndex: ProjectIndex, fileManager: FileManager = .default) throws -> TilesetIndex {
        let root = URL(fileURLWithPath: projectIndex.root.path).standardizedFileURL
        let headersText = try readText(root: root, path: headersPath)
        let graphicsText = try readText(root: root, path: graphicsPath) + "\n" + ((try? readText(root: root, path: "src/graphics.c")) ?? "")
        let metatilesText = try readText(root: root, path: metatilesPath)

        let headers = parseHeaders(headersText)
        let graphics = parseGraphics(graphicsText, root: root, fileManager: fileManager)
        let metatileRefs = parseMetatiles(metatilesText)

        var diagnostics: [Diagnostic] = []
        var assets: [TilesetAsset] = []

        for header in headers {
            var assetDiagnostics: [Diagnostic] = []
            let tileImagePath = header.tilesSymbol.flatMap { graphics.tilePaths[$0] }
            let palettePaths = header.palettesSymbol.flatMap { graphics.palettePaths[$0] } ?? []
            let metatilePath = header.metatilesSymbol.flatMap { metatileRefs.metatilePaths[$0] }
            let attributeRef = header.attributesSymbol.flatMap { metatileRefs.attributePaths[$0] }
            let wordSize = header.attributesSymbol.flatMap { metatileRefs.attributeWordSizes[$0] } ?? 2

            if tileImagePath == nil {
                assetDiagnostics.append(missingAssetDiagnostic(symbol: header.symbol, field: "tiles", path: graphicsPath))
            }
            if metatilePath == nil {
                assetDiagnostics.append(missingAssetDiagnostic(symbol: header.symbol, field: "metatiles", path: metatilesPath))
            }

            let count = metatilePath.map { metatileCount(root: root, path: $0, fileManager: fileManager) } ?? 0
            let asset = TilesetAsset(
                symbol: header.symbol,
                isSecondary: header.isSecondary,
                tileImagePath: tileImagePath,
                palettePaths: palettePaths,
                metatilesPath: metatilePath,
                metatileAttributesPath: attributeRef,
                metatileAttributeWordSize: wordSize,
                metatileCount: count,
                diagnostics: assetDiagnostics
            )
            diagnostics.append(contentsOf: assetDiagnostics)
            assets.append(asset)
        }

        return TilesetIndex(rootPath: root.path, assets: assets, diagnostics: diagnostics)
    }

    private static func readText(root: URL, path: String) throws -> String {
        let data = try Data(contentsOf: root.appendingPathComponent(path))
        return String(decoding: data, as: UTF8.self)
    }

    private static func missingAssetDiagnostic(symbol: String, field: String, path: String) -> Diagnostic {
        Diagnostic(
            severity: .warning,
            code: "TILESET_ASSET_MISSING",
            message: "\(symbol) does not resolve a \(field) asset.",
            span: SourceSpan(relativePath: path, startLine: 1)
        )
    }

    private static func metatileCount(root: URL, path: String, fileManager: FileManager) -> Int {
        let url = root.appendingPathComponent(path)
        guard fileManager.fileExists(atPath: url.path), let data = try? Data(contentsOf: url) else {
            return 0
        }
        return data.count / 16
    }

    private static func parseHeaders(_ text: String) -> [TilesetHeader] {
        let matches = regexMatches(
            #"const\s+struct\s+Tileset\s+(gTileset_[A-Za-z0-9_]+)\s*=\s*\{(.*?)\};"#,
            in: text,
            options: [.dotMatchesLineSeparators]
        )
        return matches.compactMap { match in
            guard match.count == 3 else { return nil }
            let body = match[2]
            return TilesetHeader(
                symbol: match[1],
                isSecondary: body.contains(".isSecondary = TRUE"),
                tilesSymbol: fieldSymbol("tiles", in: body),
                palettesSymbol: fieldSymbol("palettes", in: body),
                metatilesSymbol: fieldSymbol("metatiles", in: body),
                attributesSymbol: fieldSymbol("metatileAttributes", in: body)
            )
        }
    }

    private static func parseGraphics(_ text: String, root: URL, fileManager: FileManager) -> GraphicsRefs {
        var tilePaths: [String: String] = [:]
        for match in regexMatches(#"const\s+u\d+\s+(gTilesetTiles_[A-Za-z0-9_]+)\[\]\s*=\s*(?:INCGFX_U32|INCBIN_U32)\("([^"]+)""#, in: text) where match.count == 3 {
            tilePaths[match[1]] = resolveTileImagePath(match[2], root: root, fileManager: fileManager)
        }

        var palettePaths: [String: [String]] = [:]
        let paletteMatches = regexMatches(
            #"const\s+u16\s+(gTilesetPalettes_[A-Za-z0-9_]+)\[\]\[16\]\s*=\s*\{(.*?)\};"#,
            in: text,
            options: [.dotMatchesLineSeparators]
        )
        for match in paletteMatches where match.count == 3 {
            palettePaths[match[1]] = regexMatches(#""([^"]+\.(?:pal|gbapal))""#, in: match[2]).compactMap { $0.count > 1 ? $0[1] : nil }
        }

        return GraphicsRefs(tilePaths: tilePaths, palettePaths: palettePaths)
    }

    private static func parseMetatiles(_ text: String) -> MetatileRefs {
        var metatilePaths: [String: String] = [:]
        var attributePaths: [String: String] = [:]
        var attributeWordSizes: [String: Int] = [:]

        for match in regexMatches(#"const\s+u16\s+(gMetatiles_[A-Za-z0-9_]+)\[\]\s*=\s*INCBIN_U16\("([^"]+)"\);"#, in: text) where match.count == 3 {
            metatilePaths[match[1]] = match[2]
        }

        for match in regexMatches(#"const\s+u(16|32)\s+(gMetatileAttributes_[A-Za-z0-9_]+)\[\]\s*=\s*INCBIN_U(?:16|32)\("([^"]+)"\);"#, in: text) where match.count == 4 {
            attributePaths[match[2]] = match[3]
            attributeWordSizes[match[2]] = match[1] == "32" ? 4 : 2
        }

        return MetatileRefs(
            metatilePaths: metatilePaths,
            attributePaths: attributePaths,
            attributeWordSizes: attributeWordSizes
        )
    }

    private static func fieldSymbol(_ field: String, in body: String) -> String? {
        regexMatches(#"\.\#(field)\s*=\s*([A-Za-z0-9_]+)"#, in: body).first?.last
    }

    private static func resolveTileImagePath(_ path: String, root: URL, fileManager: FileManager) -> String {
        if path.hasSuffix("tiles.4bpp.lz") {
            let pngPath = path.replacingOccurrences(of: "tiles.4bpp.lz", with: "tiles.png")
            if fileManager.fileExists(atPath: root.appendingPathComponent(pngPath).path) {
                return pngPath
            }
        }
        if path.hasSuffix("tiles.4bpp") {
            let pngPath = path.replacingOccurrences(of: "tiles.4bpp", with: "tiles.png")
            if fileManager.fileExists(atPath: root.appendingPathComponent(pngPath).path) {
                return pngPath
            }
        }
        if fileManager.fileExists(atPath: root.appendingPathComponent(path).path) {
            return path
        }
        return path
    }
}

public enum ProjectMapVisualLoader {
    public static func load(from projectIndex: ProjectIndex, mapID: String, fileManager: FileManager = .default) throws -> MapVisualDocument {
        let root = URL(fileURLWithPath: projectIndex.root.path).standardizedFileURL
        let catalog = try ProjectMapCatalogLoader.load(from: projectIndex, fileManager: fileManager)
        let map = try resolveMap(mapID: mapID, in: catalog)
        let layout = try resolveLayout(for: map, in: catalog)
        let tilesets = try TilesetIndexLoader.load(from: projectIndex, fileManager: fileManager)

        var diagnostics = catalog.diagnostics
        let blockdata = readBlockdata(
            root: root,
            path: layout.blockdataFilepath,
            width: layout.width,
            height: layout.height,
            code: "MAP_VISUAL_BLOCKDATA_MISSING",
            diagnostics: &diagnostics
        )
        let border = readBorder(root: root, layout: layout, diagnostics: &diagnostics)
        let primary = tilesets.asset(symbol: layout.primaryTileset)
        let secondary = tilesets.asset(symbol: layout.secondaryTileset)
        diagnostics.append(contentsOf: primary?.diagnostics ?? [])
        diagnostics.append(contentsOf: secondary?.diagnostics ?? [])
        let metatiles = loadMetatileDefinitions(root: root, primary: primary, secondary: secondary, diagnostics: &diagnostics)
        let scene = buildScene(
            root: root,
            map: map,
            layout: layout,
            catalog: catalog,
            fileManager: fileManager
        )
        diagnostics.append(contentsOf: scene.diagnostics)

        let mapJSONData = try Data(contentsOf: root.appendingPathComponent(map.sourcePath))
        let mapJSONText = String(decoding: mapJSONData, as: UTF8.self)
        var eventParser = OrderedJSONParser(text: mapJSONText)
        let objectEventSpriteIndex = ObjectEventSpriteIndex.load(root: root, fileManager: fileManager)
        let events = (try? eventParser.parse()).map {
            extractEvents(
                from: $0,
                spriteIndex: objectEventSpriteIndex,
                sourcePath: map.sourcePath,
                diagnostics: &diagnostics
            )
        } ?? []

        return MapVisualDocument(
            id: "\(projectIndex.root.path):\(map.id)",
            rootPath: projectIndex.root.path,
            profile: projectIndex.profile,
            mapID: map.id,
            mapName: map.name,
            mapMetadata: mapMetadata(from: map),
            mapSourcePath: map.sourcePath,
            layout: layout,
            blockdata: blockdata,
            border: border,
            primaryTileset: primary,
            secondaryTileset: secondary,
            metatiles: metatiles,
            events: events,
            scene: scene,
            diagnostics: diagnostics,
            mapJSONText: mapJSONText
        )
    }

    private static func mapMetadata(from map: MapDescriptor) -> MapVisualMapMetadata {
        MapVisualMapMetadata(
            mapID: map.id,
            mapName: map.name,
            sourcePath: map.sourcePath,
            music: map.music,
            mapType: map.mapType,
            weather: map.weather,
            regionMapSection: map.regionMapSection,
            floorNumber: map.floorNumber
        )
    }

    private static func buildScene(
        root: URL,
        map: MapDescriptor,
        layout: LayoutSlot,
        catalog: ProjectMapCatalog,
        fileManager: FileManager
    ) -> MapVisualScene {
        let layoutWidth = layout.width ?? 0
        let layoutHeight = layout.height ?? 0
        let layoutValues = readUInt16Values(root: root, path: layout.blockdataFilepath ?? "")
        let layoutPlacement = MapScenePlacement(
            id: "layout-\(map.id)",
            role: .layout,
            mapID: map.id,
            mapName: map.name,
            originX: 0,
            originY: 0,
            width: layoutWidth,
            height: layoutHeight,
            rawValues: layoutValues,
            sourcePath: layout.blockdataFilepath
        )

        var placements = [layoutPlacement]
        var connections: [MapSceneConnection] = []
        var diagnostics: [Diagnostic] = []

        for connection in map.connections {
            let direction = MapSceneConnectionDirection(rawConnectionDirection: connection.direction)
            guard let direction else {
                let diagnostic = sceneDiagnostic(
                    code: "MAP_SCENE_CONNECTION_DIRECTION_UNKNOWN",
                    message: "\(map.id) has a connection with unknown direction \(connection.direction ?? "nil").",
                    sourcePath: map.sourcePath
                )
                diagnostics.append(diagnostic)
                connections.append(
                    MapSceneConnection(
                        sourceMapID: map.id,
                        index: connection.index,
                        targetMapID: connection.map,
                        targetMapName: nil,
                        direction: nil,
                        offset: connection.offset ?? 0,
                        placementID: nil,
                        isResolved: false,
                        diagnostic: diagnostic
                    )
                )
                continue
            }

            guard let targetMap = resolveOptionalMap(mapID: connection.map, in: catalog) else {
                let diagnostic = sceneDiagnostic(
                    code: "MAP_SCENE_CONNECTION_MAP_MISSING",
                    message: "\(map.id) connects \(direction.rawValue) to \(connection.map ?? "nil"), but that map is not indexed.",
                    sourcePath: map.sourcePath
                )
                diagnostics.append(diagnostic)
                connections.append(
                    MapSceneConnection(
                        sourceMapID: map.id,
                        index: connection.index,
                        targetMapID: connection.map,
                        targetMapName: nil,
                        direction: direction,
                        offset: connection.offset ?? 0,
                        placementID: nil,
                        isResolved: false,
                        diagnostic: diagnostic
                    )
                )
                continue
            }

            guard let targetLayout = try? resolveLayout(for: targetMap, in: catalog) else {
                let diagnostic = sceneDiagnostic(
                    code: "MAP_SCENE_CONNECTION_LAYOUT_MISSING",
                    message: "\(map.id) connects \(direction.rawValue) to \(targetMap.id), but its layout could not be resolved.",
                    sourcePath: targetMap.sourcePath
                )
                diagnostics.append(diagnostic)
                connections.append(
                    MapSceneConnection(
                        sourceMapID: map.id,
                        index: connection.index,
                        targetMapID: targetMap.id,
                        targetMapName: targetMap.name,
                        direction: direction,
                        offset: connection.offset ?? 0,
                        placementID: nil,
                        isResolved: false,
                        diagnostic: diagnostic
                    )
                )
                continue
            }

            guard targetLayout.primaryTileset == layout.primaryTileset,
                  targetLayout.secondaryTileset == layout.secondaryTileset
            else {
                let diagnostic = sceneDiagnostic(
                    code: "MAP_SCENE_CONNECTION_TILESET_MISMATCH",
                    message: "\(targetMap.id) uses different tilesets; showing border fallback for this connection.",
                    sourcePath: targetLayout.sourcePath
                )
                diagnostics.append(diagnostic)
                connections.append(
                    MapSceneConnection(
                        sourceMapID: map.id,
                        index: connection.index,
                        targetMapID: targetMap.id,
                        targetMapName: targetMap.name,
                        direction: direction,
                        offset: connection.offset ?? 0,
                        placementID: nil,
                        isResolved: false,
                        diagnostic: diagnostic
                    )
                )
                continue
            }

            let targetValues = readUInt16Values(root: root, path: targetLayout.blockdataFilepath ?? "")
            let expectedCount = (targetLayout.width ?? 0) * (targetLayout.height ?? 0)
            guard expectedCount > 0, targetValues.count == expectedCount else {
                let diagnostic = sceneDiagnostic(
                    code: "MAP_SCENE_CONNECTION_BLOCKDATA_MISSING",
                    message: "\(targetMap.id) connection blockdata contains \(targetValues.count) metatiles; expected \(expectedCount).",
                    sourcePath: targetLayout.blockdataFilepath ?? targetLayout.sourcePath
                )
                diagnostics.append(diagnostic)
                connections.append(
                    MapSceneConnection(
                        sourceMapID: map.id,
                        index: connection.index,
                        targetMapID: targetMap.id,
                        targetMapName: targetMap.name,
                        direction: direction,
                        offset: connection.offset ?? 0,
                        placementID: nil,
                        isResolved: false,
                        diagnostic: diagnostic
                    )
                )
                continue
            }

            let placementOrigin = sceneConnectionOrigin(
                direction: direction,
                offset: connection.offset ?? 0,
                layoutWidth: layoutWidth,
                layoutHeight: layoutHeight,
                targetWidth: targetLayout.width ?? 0,
                targetHeight: targetLayout.height ?? 0
            )
            let placementID = "connection-\(map.id)-\(connection.index)-\(targetMap.id)"
            placements.append(
                MapScenePlacement(
                    id: placementID,
                    role: .connection,
                    mapID: targetMap.id,
                    mapName: targetMap.name,
                    originX: placementOrigin.x,
                    originY: placementOrigin.y,
                    width: targetLayout.width ?? 0,
                    height: targetLayout.height ?? 0,
                    rawValues: targetValues,
                    sourcePath: targetLayout.blockdataFilepath
                )
            )
            connections.append(
                MapSceneConnection(
                    sourceMapID: map.id,
                    index: connection.index,
                    targetMapID: targetMap.id,
                    targetMapName: targetMap.name,
                    direction: direction,
                    offset: connection.offset ?? 0,
                    placementID: placementID,
                    isResolved: true
                )
            )
        }

        let viewport = MapVisualScene.viewport(layoutWidth: layoutWidth, layoutHeight: layoutHeight, placements: placements)
        return MapVisualScene(viewport: viewport, placements: placements, connections: connections, diagnostics: diagnostics)
    }

    private static func resolveOptionalMap(mapID: String?, in catalog: ProjectMapCatalog) -> MapDescriptor? {
        guard let mapID else { return nil }
        return catalog.maps.first { $0.id == mapID || $0.name == mapID }
    }

    private static func sceneConnectionOrigin(
        direction: MapSceneConnectionDirection,
        offset: Int,
        layoutWidth: Int,
        layoutHeight: Int,
        targetWidth: Int,
        targetHeight: Int
    ) -> (x: Int, y: Int) {
        switch direction {
        case .up:
            return (offset, -targetHeight)
        case .down:
            return (offset, layoutHeight)
        case .left:
            return (-targetWidth, offset)
        case .right:
            return (layoutWidth, offset)
        }
    }

    private static func sceneDiagnostic(code: String, message: String, sourcePath: String) -> Diagnostic {
        Diagnostic(
            severity: .warning,
            code: code,
            message: message,
            span: SourceSpan(relativePath: sourcePath, startLine: 1)
        )
    }

    private static func resolveMap(mapID: String, in catalog: ProjectMapCatalog) throws -> MapDescriptor {
        if let map = catalog.maps.first(where: { $0.id == mapID || $0.name == mapID }) {
            return map
        }
        throw MapVisualError.mapNotFound(mapID)
    }

    private static func resolveLayout(for map: MapDescriptor, in catalog: ProjectMapCatalog) throws -> LayoutSlot {
        if let slotIndex = map.layoutSlotIndex, let layout = catalog.layoutSlots.first(where: { $0.slotIndex == slotIndex }) {
            return layout
        }
        if let layoutID = map.layout, let layout = catalog.layoutSlots.first(where: { $0.layoutID == layoutID }) {
            return layout
        }
        throw MapVisualError.layoutNotFound(map.layout ?? map.id)
    }

    private static func readBlockdata(
        root: URL,
        path: String?,
        width: Int?,
        height: Int?,
        code: String,
        diagnostics: inout [Diagnostic]
    ) -> EditableLayoutBlockdata {
        let filepath = path ?? "data/layouts/unknown/map.bin"
        let resolvedWidth = max(width ?? 0, 0)
        let resolvedHeight = max(height ?? 0, 0)
        let values = readUInt16Values(root: root, path: filepath)
        if values.count != resolvedWidth * resolvedHeight {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: code,
                    message: "\(filepath) contains \(values.count) metatiles; expected \(resolvedWidth * resolvedHeight).",
                    span: SourceSpan(relativePath: filepath, startLine: 1)
                )
            )
        }
        return EditableLayoutBlockdata(filepath: filepath, width: resolvedWidth, height: resolvedHeight, rawValues: values)
    }

    private static func readBorder(root: URL, layout: LayoutSlot, diagnostics: inout [Diagnostic]) -> EditableLayoutBlockdata? {
        guard let path = layout.borderFilepath else { return nil }
        let values = readUInt16Values(root: root, path: path)
        guard !values.isEmpty else { return nil }
        let width = layout.borderWidth ?? 2
        let height = layout.borderHeight ?? max(1, values.count / max(width, 1))
        if values.count != width * height {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "MAP_VISUAL_BORDER_SIZE_MISMATCH",
                    message: "\(path) contains \(values.count) metatiles; expected \(width * height).",
                    span: SourceSpan(relativePath: path, startLine: 1)
                )
            )
        }
        return EditableLayoutBlockdata(filepath: path, width: width, height: height, rawValues: values)
    }

    private static func readUInt16Values(root: URL, path: String) -> [UInt16] {
        guard let data = try? Data(contentsOf: root.appendingPathComponent(path)) else { return [] }
        let bytes = [UInt8](data)
        return stride(from: 0, to: bytes.count - (bytes.count % 2), by: 2).map { offset in
            UInt16(bytes[offset]) | (UInt16(bytes[offset + 1]) << 8)
        }
    }

    private static func loadMetatileDefinitions(
        root: URL,
        primary: TilesetAsset?,
        secondary: TilesetAsset?,
        diagnostics: inout [Diagnostic]
    ) -> [MetatileDefinition] {
        var definitions: [MetatileDefinition] = []
        if let primary {
            definitions.append(contentsOf: definitionsForTileset(primary, root: root, baseID: 0, diagnostics: &diagnostics))
        }
        if let secondary {
            definitions.append(contentsOf: definitionsForTileset(secondary, root: root, baseID: 0x200, diagnostics: &diagnostics))
        }
        return definitions
    }

    private static func definitionsForTileset(
        _ asset: TilesetAsset,
        root: URL,
        baseID: Int,
        diagnostics: inout [Diagnostic]
    ) -> [MetatileDefinition] {
        guard let path = asset.metatilesPath, let data = try? Data(contentsOf: root.appendingPathComponent(path)) else {
            return []
        }
        let attributeValues = readAttributes(asset: asset, root: root)
        let bytes = [UInt8](data)
        let count = bytes.count / 16
        return (0..<count).map { localID in
            let start = localID * 16
            let entries = (0..<8).map { entryIndex -> MetatileTileEntry in
                let offset = start + entryIndex * 2
                let raw = UInt16(bytes[offset]) | (UInt16(bytes[offset + 1]) << 8)
                return MetatileTileEntry(index: entryIndex, rawValue: raw)
            }
            let attribute = attributeValues.indices.contains(localID)
                ? MetatileAttribute(rawValue: attributeValues[localID], wordSize: asset.metatileAttributeWordSize)
                : nil
            if let attribute, attribute.rawLayerType > MetatileLayerType.split.rawValue {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "METATILE_LAYER_TYPE_UNKNOWN",
                        message: "\(asset.symbol) metatile \(localID) uses unknown layer type \(attribute.rawLayerType); rendering as normal.",
                        span: SourceSpan(relativePath: asset.metatileAttributesPath ?? path, startLine: 1)
                    )
                )
            }
            return MetatileDefinition(
                id: baseID + localID,
                localID: localID,
                tilesetSymbol: asset.symbol,
                tileEntries: entries,
                attribute: attribute
            )
        }
    }

    private static func readAttributes(asset: TilesetAsset, root: URL) -> [UInt32] {
        guard let path = asset.metatileAttributesPath, let data = try? Data(contentsOf: root.appendingPathComponent(path)) else {
            return []
        }
        let bytes = [UInt8](data)
        let strideBy = max(asset.metatileAttributeWordSize, 2)
        return stride(from: 0, to: bytes.count - (bytes.count % strideBy), by: strideBy).map { offset in
            if strideBy == 4 {
                return UInt32(bytes[offset])
                    | (UInt32(bytes[offset + 1]) << 8)
                    | (UInt32(bytes[offset + 2]) << 16)
                    | (UInt32(bytes[offset + 3]) << 24)
            }
            return UInt32(bytes[offset]) | (UInt32(bytes[offset + 1]) << 8)
        }
    }

    private static func extractEvents(
        from root: OrderedJSONValue,
        spriteIndex: ObjectEventSpriteIndex,
        sourcePath: String,
        diagnostics: inout [Diagnostic]
    ) -> [MapEventDescriptor] {
        var events: [MapEventDescriptor] = []
        var reportedSpriteIDs: Set<String> = []
        events += extractEventArray(from: root, key: "object_events", kind: .object, spriteIndex: spriteIndex, sourcePath: sourcePath, diagnostics: &diagnostics, reportedSpriteIDs: &reportedSpriteIDs)
        events += extractEventArray(from: root, key: "warp_events", kind: .warp, spriteIndex: spriteIndex, sourcePath: sourcePath, diagnostics: &diagnostics, reportedSpriteIDs: &reportedSpriteIDs)
        events += extractEventArray(from: root, key: "coord_events", kind: .coord, spriteIndex: spriteIndex, sourcePath: sourcePath, diagnostics: &diagnostics, reportedSpriteIDs: &reportedSpriteIDs)
        events += extractEventArray(from: root, key: "bg_events", kind: .bg, spriteIndex: spriteIndex, sourcePath: sourcePath, diagnostics: &diagnostics, reportedSpriteIDs: &reportedSpriteIDs)
        events += extractEventArray(from: root, key: "connections", kind: .connection, spriteIndex: spriteIndex, sourcePath: sourcePath, diagnostics: &diagnostics, reportedSpriteIDs: &reportedSpriteIDs)
        return events
    }

    private static func extractEventArray(
        from root: OrderedJSONValue,
        key: String,
        kind: MapEventKind,
        spriteIndex: ObjectEventSpriteIndex,
        sourcePath: String,
        diagnostics: inout [Diagnostic],
        reportedSpriteIDs: inout Set<String>
    ) -> [MapEventDescriptor] {
        guard case .object(let pairs) = root, let array = pairs.first(where: { $0.key == key })?.value, case .array(let values) = array else {
            return []
        }
        return values.enumerated().compactMap { index, value in
            guard case .object(let eventPairs) = value else { return nil }
            let properties = eventPairs.map { MapEventProperty(key: $0.key, value: $0.value.displayValue) }
            let graphicsID = kind == .object ? properties.first(where: { $0.key == "graphics_id" })?.value : nil
            let sprite = spriteIndex.sprite(for: graphicsID)
            if let graphicsID, sprite == nil, reportedSpriteIDs.insert(graphicsID).inserted {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "MAP_EVENT_SPRITE_UNRESOLVED",
                        message: "\(graphicsID) could not be resolved from object event graphics tables; using the typed event marker.",
                        span: SourceSpan(relativePath: sourcePath, startLine: 1)
                    )
                )
            }
            return MapEventDescriptor(
                kind: kind,
                index: index,
                x: eventPairs.first(where: { $0.key == "x" })?.value.intValue,
                y: eventPairs.first(where: { $0.key == "y" })?.value.intValue,
                elevation: eventPairs.first(where: { $0.key == "elevation" })?.value.intValue,
                properties: properties,
                sprite: sprite
            )
        }
    }
}

public enum MapEditReducer {
    public static func reduce(document: MapVisualDocument, operations: [MapEditOperation]) -> MapEditDraft {
        MapMutationPlanner.reduceDraft(document: document, operations: operations)
    }
}

public enum MapMutationPlanner {
    fileprivate static func reduceDraft(document: MapVisualDocument, operations: [MapEditOperation]) -> MapEditDraft {
        var diagnostics = document.diagnostics
        var layoutValues = document.blockdata.rawValues
        var borderValues = document.border?.rawValues
        var jsonParser = OrderedJSONParser(text: document.mapJSONText)
        var jsonRoot = try? jsonParser.parse()
        var didChangeJSON = false

        for operation in operations {
            switch operation.action {
            case .paintMetatile:
                applyPaint(operation, document: document, layoutValues: &layoutValues, borderValues: &borderValues, diagnostics: &diagnostics)
            case .fillMetatile:
                applyFill(operation, document: document, layoutValues: &layoutValues, borderValues: &borderValues, diagnostics: &diagnostics)
            case .moveEvent, .updateEventField, .addEvent, .duplicateEvent, .deleteEvent:
                if jsonRoot == nil {
                    diagnostics.append(jsonDiagnostic("MAP_JSON_PARSE_FAILED", document: document))
                } else {
                    didChangeJSON = applyEventOperation(operation, root: &jsonRoot!, diagnostics: &diagnostics, document: document) || didChangeJSON
                }
            }
        }

        let draftJSONText: String
        let draftEvents: [MapEventDescriptor]
        if didChangeJSON, let jsonRoot {
            draftJSONText = jsonRoot.renderPretty() + "\n"
            draftEvents = extractEvents(from: jsonRoot)
        } else {
            draftJSONText = document.mapJSONText
            draftEvents = document.events
        }

        return MapEditDraft(
            documentID: document.id,
            blockdata: EditableLayoutBlockdata(
                filepath: document.blockdata.filepath,
                width: document.blockdata.width,
                height: document.blockdata.height,
                rawValues: layoutValues
            ),
            border: document.border.map {
                EditableLayoutBlockdata(
                    filepath: $0.filepath,
                    width: $0.width,
                    height: $0.height,
                    rawValues: borderValues ?? $0.rawValues
                )
            },
            mapJSONText: draftJSONText,
            events: draftEvents,
            diagnostics: diagnostics
        )
    }

    public static func plan(document: MapVisualDocument, operations: [MapEditOperation]) -> MapEditPlan {
        let draft = reduceDraft(document: document, operations: operations)
        var changes: [MapEditFileChange] = []

        let layoutValues = draft.blockdata.rawValues
        let originalLayoutValues = document.blockdata.rawValues
        let borderValues = draft.border?.rawValues
        let originalBorderValues = document.border?.rawValues

        if layoutValues != originalLayoutValues {
            let data = encodeUInt16Values(layoutValues)
            changes.append(
                MapEditFileChange(
                    path: draft.blockdata.filepath,
                    summary: "Update layout blockdata",
                    originalByteCount: originalLayoutValues.count * 2,
                    newByteCount: data.count,
                    newData: data
                )
            )
        }

        if let originalBorderValues, let borderValues, borderValues != originalBorderValues, let border = draft.border {
            let data = encodeUInt16Values(borderValues)
            changes.append(
                MapEditFileChange(
                    path: border.filepath,
                    summary: "Update border blockdata",
                    originalByteCount: originalBorderValues.count * 2,
                    newByteCount: data.count,
                    newData: data
                )
            )
        }

        if draft.mapJSONText != document.mapJSONText {
            let data = Data(draft.mapJSONText.utf8)
            changes.append(
                MapEditFileChange(
                    path: document.mapSourcePath,
                    summary: "Update map JSON events/header fields",
                    originalByteCount: Data(document.mapJSONText.utf8).count,
                    newByteCount: data.count,
                    newData: data,
                    textPreview: draft.mapJSONText
                )
            )
        }

        let plannedChanges = changes.map {
            PlannedChange(path: $0.path, summary: $0.summary, span: SourceSpan(relativePath: $0.path, startLine: 1))
        }
        let mutationPlan = MutationPlan(
            title: "Apply visual map edits to \(document.mapName)",
            summary: "\(changes.count) source file change(s), \(operations.count) edit operation(s).",
            changes: plannedChanges,
            diagnostics: draft.diagnostics,
            requiresExplicitApply: true
        )
        let backupRoot = ".pokemonhackstudio/backups/\(Self.backupTimestamp())"

        return MapEditPlan(
            rootPath: document.rootPath,
            documentID: document.id,
            operations: operations,
            changes: changes,
            diagnostics: draft.diagnostics,
            mutationPlan: mutationPlan,
            backupRelativeRoot: backupRoot
        )
    }

    private static func applyPaint(
        _ operation: MapEditOperation,
        document: MapVisualDocument,
        layoutValues: inout [UInt16],
        borderValues: inout [UInt16]?,
        diagnostics: inout [Diagnostic]
    ) {
        guard let x = operation.x, let y = operation.y, let rawValue = operation.rawValue else {
            diagnostics.append(operationDiagnostic("MAP_EDIT_INCOMPLETE", "Paint operation is missing x, y, or rawValue."))
            return
        }
        setBlockValue(target: operation.target ?? .layout, x: x, y: y, rawValue: rawValue, document: document, layoutValues: &layoutValues, borderValues: &borderValues, diagnostics: &diagnostics)
    }

    private static func applyFill(
        _ operation: MapEditOperation,
        document: MapVisualDocument,
        layoutValues: inout [UInt16],
        borderValues: inout [UInt16]?,
        diagnostics: inout [Diagnostic]
    ) {
        guard let x = operation.x, let y = operation.y, let width = operation.width, let height = operation.height, let rawValue = operation.rawValue else {
            diagnostics.append(operationDiagnostic("MAP_EDIT_INCOMPLETE", "Fill operation is missing rectangle or rawValue."))
            return
        }
        for fillY in y..<(y + height) {
            for fillX in x..<(x + width) {
                setBlockValue(target: operation.target ?? .layout, x: fillX, y: fillY, rawValue: rawValue, document: document, layoutValues: &layoutValues, borderValues: &borderValues, diagnostics: &diagnostics)
            }
        }
    }

    private static func setBlockValue(
        target: MapBlockTarget,
        x: Int,
        y: Int,
        rawValue: UInt16,
        document: MapVisualDocument,
        layoutValues: inout [UInt16],
        borderValues: inout [UInt16]?,
        diagnostics: inout [Diagnostic]
    ) {
        let width: Int
        let height: Int
        switch target {
        case .layout:
            width = document.blockdata.width
            height = document.blockdata.height
            guard x >= 0, y >= 0, x < width, y < height else {
                diagnostics.append(boundsDiagnostic(target: target, x: x, y: y, width: width, height: height))
                return
            }
            let index = y * width + x
            guard layoutValues.indices.contains(index) else {
                diagnostics.append(boundsDiagnostic(target: target, x: x, y: y, width: width, height: height))
                return
            }
            layoutValues[index] = rawValue
        case .border:
            guard let border = document.border else {
                diagnostics.append(operationDiagnostic("MAP_BORDER_MISSING", "Border paint requested but this layout has no border data."))
                return
            }
            width = border.width
            height = border.height
            guard x >= 0, y >= 0, x < width, y < height else {
                diagnostics.append(boundsDiagnostic(target: target, x: x, y: y, width: width, height: height))
                return
            }
            let index = y * width + x
            guard borderValues?.indices.contains(index) == true else {
                diagnostics.append(boundsDiagnostic(target: target, x: x, y: y, width: width, height: height))
                return
            }
            borderValues?[index] = rawValue
        }
    }

    private static func applyEventOperation(
        _ operation: MapEditOperation,
        root: inout OrderedJSONValue,
        diagnostics: inout [Diagnostic],
        document: MapVisualDocument
    ) -> Bool {
        guard let kind = operation.eventKind, let arrayKey = jsonKey(for: kind) else {
            diagnostics.append(operationDiagnostic("MAP_EVENT_KIND_MISSING", "Event operation is missing a supported event kind."))
            return false
        }

        switch operation.action {
        case .moveEvent:
            guard let index = operation.eventIndex, let x = operation.x, let y = operation.y else {
                diagnostics.append(operationDiagnostic("MAP_EVENT_OPERATION_INCOMPLETE", "Move event operation is missing index, x, or y."))
                return false
            }
            if !updateObject(in: &root, arrayKey: arrayKey, index: index, updates: [("x", .number(String(x))), ("y", .number(String(y)))]) {
                diagnostics.append(eventIndexDiagnostic(kind: kind, index: index, document: document))
                return false
            }
            return true
        case .updateEventField:
            guard let index = operation.eventIndex, let key = operation.fieldKey, let value = operation.fieldValue else {
                diagnostics.append(operationDiagnostic("MAP_EVENT_OPERATION_INCOMPLETE", "Update event field operation is missing index, key, or value."))
                return false
            }
            if !updateObject(in: &root, arrayKey: arrayKey, index: index, updates: [(key, scalarValue(from: value))]) {
                diagnostics.append(eventIndexDiagnostic(kind: kind, index: index, document: document))
                return false
            }
            return true
        case .deleteEvent:
            guard let index = operation.eventIndex else {
                diagnostics.append(operationDiagnostic("MAP_EVENT_OPERATION_INCOMPLETE", "Delete event operation is missing index."))
                return false
            }
            if !deleteObject(in: &root, arrayKey: arrayKey, index: index) {
                diagnostics.append(eventIndexDiagnostic(kind: kind, index: index, document: document))
                return false
            }
            return true
        case .duplicateEvent:
            guard let index = operation.eventIndex else {
                diagnostics.append(operationDiagnostic("MAP_EVENT_OPERATION_INCOMPLETE", "Duplicate event operation is missing index."))
                return false
            }
            if !duplicateObject(in: &root, arrayKey: arrayKey, index: index, operation: operation) {
                diagnostics.append(eventIndexDiagnostic(kind: kind, index: index, document: document))
                return false
            }
            return true
        case .addEvent:
            addObject(in: &root, arrayKey: arrayKey, properties: operation.templateProperties)
            return true
        case .paintMetatile, .fillMetatile:
            return false
        }
    }

    private static func jsonKey(for kind: MapEventKind) -> String? {
        switch kind {
        case .object: "object_events"
        case .warp: "warp_events"
        case .coord: "coord_events"
        case .bg: "bg_events"
        case .connection: "connections"
        }
    }

    private static func updateObject(in root: inout OrderedJSONValue, arrayKey: String, index: Int, updates: [(String, OrderedJSONValue)]) -> Bool {
        mutateObject(in: &root, arrayKey: arrayKey, index: index) { object in
            for update in updates {
                object.set(key: update.0, value: update.1)
            }
        }
    }

    private static func deleteObject(in root: inout OrderedJSONValue, arrayKey: String, index: Int) -> Bool {
        guard case .object(var pairs) = root, let pairIndex = pairs.firstIndex(where: { $0.key == arrayKey }), case .array(var values) = pairs[pairIndex].value, values.indices.contains(index) else {
            return false
        }
        values.remove(at: index)
        pairs[pairIndex].value = .array(values)
        root = .object(pairs)
        return true
    }

    private static func duplicateObject(in root: inout OrderedJSONValue, arrayKey: String, index: Int, operation: MapEditOperation) -> Bool {
        guard case .object(var pairs) = root, let pairIndex = pairs.firstIndex(where: { $0.key == arrayKey }), case .array(var values) = pairs[pairIndex].value, values.indices.contains(index), case .object(var duplicatePairs) = values[index] else {
            return false
        }
        for property in operation.templateProperties {
            duplicatePairs.set(key: property.key, value: scalarValue(from: property.value))
        }
        if let key = operation.fieldKey, let value = operation.fieldValue {
            duplicatePairs.set(key: key, value: scalarValue(from: value))
        }
        if let x = operation.x {
            duplicatePairs.set(key: "x", value: .number(String(x)))
        }
        if let y = operation.y {
            duplicatePairs.set(key: "y", value: .number(String(y)))
        }
        values.insert(.object(duplicatePairs), at: index + 1)
        pairs[pairIndex].value = .array(values)
        root = .object(pairs)
        return true
    }

    private static func addObject(in root: inout OrderedJSONValue, arrayKey: String, properties: [MapEventProperty]) {
        let object = OrderedJSONValue.object(properties.map { OrderedJSONPair(key: $0.key, value: scalarValue(from: $0.value)) })
        guard case .object(var pairs) = root else { return }
        if let pairIndex = pairs.firstIndex(where: { $0.key == arrayKey }), case .array(var values) = pairs[pairIndex].value {
            values.append(object)
            pairs[pairIndex].value = .array(values)
        } else {
            pairs.append(OrderedJSONPair(key: arrayKey, value: .array([object])))
        }
        root = .object(pairs)
    }

    private static func extractEvents(from root: OrderedJSONValue) -> [MapEventDescriptor] {
        var events: [MapEventDescriptor] = []
        events += extractEventArray(from: root, key: "object_events", kind: .object)
        events += extractEventArray(from: root, key: "warp_events", kind: .warp)
        events += extractEventArray(from: root, key: "coord_events", kind: .coord)
        events += extractEventArray(from: root, key: "bg_events", kind: .bg)
        events += extractEventArray(from: root, key: "connections", kind: .connection)
        return events
    }

    private static func extractEventArray(from root: OrderedJSONValue, key: String, kind: MapEventKind) -> [MapEventDescriptor] {
        guard case .object(let pairs) = root, let array = pairs.first(where: { $0.key == key })?.value, case .array(let values) = array else {
            return []
        }
        return values.enumerated().compactMap { index, value in
            guard case .object(let eventPairs) = value else { return nil }
            let properties = eventPairs.map { MapEventProperty(key: $0.key, value: $0.value.displayValue) }
            return MapEventDescriptor(
                kind: kind,
                index: index,
                x: eventPairs.first(where: { $0.key == "x" })?.value.intValue,
                y: eventPairs.first(where: { $0.key == "y" })?.value.intValue,
                elevation: eventPairs.first(where: { $0.key == "elevation" })?.value.intValue,
                properties: properties
            )
        }
    }

    private static func mutateObject(
        in root: inout OrderedJSONValue,
        arrayKey: String,
        index: Int,
        _ mutate: (inout OrderedJSONObject) -> Void
    ) -> Bool {
        guard case .object(var pairs) = root, let pairIndex = pairs.firstIndex(where: { $0.key == arrayKey }), case .array(var values) = pairs[pairIndex].value, values.indices.contains(index), case .object(var eventPairs) = values[index] else {
            return false
        }
        mutate(&eventPairs)
        values[index] = .object(eventPairs)
        pairs[pairIndex].value = .array(values)
        root = .object(pairs)
        return true
    }

    private static func scalarValue(from value: String) -> OrderedJSONValue {
        if value == "true" { return .bool(true) }
        if value == "false" { return .bool(false) }
        if value == "null" { return .null }
        if Int(value) != nil { return .number(value) }
        return .string(value)
    }

    private static func encodeUInt16Values(_ values: [UInt16]) -> Data {
        var data = Data()
        data.reserveCapacity(values.count * 2)
        for value in values {
            data.append(UInt8(value & 0x00ff))
            data.append(UInt8((value >> 8) & 0x00ff))
        }
        return data
    }

    private static func boundsDiagnostic(target: MapBlockTarget, x: Int, y: Int, width: Int, height: Int) -> Diagnostic {
        operationDiagnostic("MAP_EDIT_OUT_OF_BOUNDS", "\(target.rawValue) coordinate \(x),\(y) is outside \(width)x\(height).")
    }

    private static func eventIndexDiagnostic(kind: MapEventKind, index: Int, document: MapVisualDocument) -> Diagnostic {
        Diagnostic(
            severity: .error,
            code: "MAP_EVENT_INDEX_INVALID",
            message: "\(kind.rawValue) event index \(index) does not exist in \(document.mapSourcePath).",
            span: SourceSpan(relativePath: document.mapSourcePath, startLine: 1)
        )
    }

    private static func jsonDiagnostic(_ code: String, document: MapVisualDocument) -> Diagnostic {
        Diagnostic(severity: .error, code: code, message: "Could not parse \(document.mapSourcePath).", span: SourceSpan(relativePath: document.mapSourcePath, startLine: 1))
    }

    private static func operationDiagnostic(_ code: String, _ message: String) -> Diagnostic {
        Diagnostic(severity: .error, code: code, message: message)
    }

    private static func backupTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "\(formatter.string(from: Date()))-\(UUID().uuidString.prefix(8))"
    }
}

public enum MapMutationApplier {
    public static func apply(plan: MapEditPlan, fileManager: FileManager = .default) throws -> MapApplyResult {
        let root = URL(fileURLWithPath: plan.rootPath).standardizedFileURL
        let backupRoot = root.appendingPathComponent(plan.backupRelativeRoot)
        let applyability = plan.validateApplyability(fileManager: fileManager)
        guard applyability.isApplyable else {
            return MapApplyResult(backupRootPath: backupRoot.path, appliedChanges: [], diagnostics: applyability.diagnostics)
        }
        guard !plan.changes.isEmpty else {
            return MapApplyResult(backupRootPath: backupRoot.path, appliedChanges: [])
        }

        try fileManager.createDirectory(at: backupRoot, withIntermediateDirectories: true)

        var applied: [AppliedMapFileChange] = []
        for change in plan.changes {
            let destination = root.appendingPathComponent(change.path)
            let backup = backupRoot.appendingPathComponent(change.path)
            try fileManager.createDirectory(at: backup.deletingLastPathComponent(), withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: destination.path) {
                if fileManager.fileExists(atPath: backup.path) {
                    try fileManager.removeItem(at: backup)
                }
                try fileManager.copyItem(at: destination, to: backup)
            }
            try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            try change.newData.write(to: destination, options: .atomic)
            applied.append(AppliedMapFileChange(path: change.path, backupPath: backup.path, byteCount: change.newData.count))
        }

        return MapApplyResult(backupRootPath: backupRoot.path, appliedChanges: applied)
    }
}

private enum MapEditApplySafety {
    static func applyability(for plan: MapEditPlan, fileManager: FileManager) -> MapEditApplyability {
        var diagnostics = plan.diagnostics.filter { $0.severity == .error }

        guard !(plan.rootPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "MAP_APPLY_ROOT_MISSING",
                    message: "Map edit plan is missing a project root."
                )
            )
            return MapEditApplyability(isApplyable: diagnostics.isEmpty, diagnostics: diagnostics)
        }

        guard (plan.rootPath as NSString).isAbsolutePath else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "MAP_APPLY_ROOT_INVALID",
                    message: "Map edit plan root must be absolute."
                )
            )
            return MapEditApplyability(isApplyable: diagnostics.isEmpty, diagnostics: diagnostics)
        }

        let root = URL(fileURLWithPath: plan.rootPath).standardizedFileURL
        let resolvedRoot = root.resolvingSymlinksInPath().standardizedFileURL
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: root.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "MAP_APPLY_ROOT_MISSING",
                    message: "Map edit plan root does not exist: \(plan.rootPath)."
                )
            )
            return MapEditApplyability(isApplyable: diagnostics.isEmpty, diagnostics: diagnostics)
        }

        diagnostics.append(
            contentsOf: validatePath(
                plan.backupRelativeRoot,
                purpose: .backup,
                root: root,
                resolvedRoot: resolvedRoot,
                fileManager: fileManager
            )
        )

        for change in plan.changes {
            let pathDiagnostics = validatePath(
                change.path,
                purpose: .change,
                root: root,
                resolvedRoot: resolvedRoot,
                fileManager: fileManager
            )
            diagnostics.append(contentsOf: pathDiagnostics)
            if pathDiagnostics.isEmpty {
                diagnostics.append(contentsOf: validateSourcePrecondition(change: change, root: root, fileManager: fileManager))
            }
        }

        return MapEditApplyability(isApplyable: diagnostics.isEmpty, diagnostics: diagnostics)
    }

    private enum PathPurpose {
        case backup
        case change
    }

    private static func validatePath(
        _ path: String,
        purpose: PathPurpose,
        root: URL,
        resolvedRoot: URL,
        fileManager: FileManager
    ) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else {
            return [
                pathDiagnostic(
                    code: "MAP_APPLY_PATH_EMPTY",
                    message: "Map edit plan contains an empty write path.",
                    path: path
                )
            ]
        }

        if (trimmedPath as NSString).isAbsolutePath {
            return [
                pathDiagnostic(
                    code: "MAP_APPLY_PATH_ABSOLUTE",
                    message: "Map edit write path must be project-relative: \(trimmedPath).",
                    path: trimmedPath
                )
            ]
        }

        let pathComponents = trimmedPath
            .replacingOccurrences(of: "\\", with: "/")
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)
        if pathComponents.contains("..") {
            diagnostics.append(
                pathDiagnostic(
                    code: "MAP_APPLY_PATH_ESCAPE",
                    message: "Map edit write path cannot contain '..': \(trimmedPath).",
                    path: trimmedPath
                )
            )
        }

        if purpose == .change {
            diagnostics.append(contentsOf: generatedPathDiagnostics(path: trimmedPath, components: pathComponents))
        }
        diagnostics.append(contentsOf: artifactPathDiagnostics(path: trimmedPath, components: pathComponents, purpose: purpose))

        let destination = root.appendingPathComponent(trimmedPath).standardizedFileURL
        if !isContained(destination, in: root) {
            diagnostics.append(
                pathDiagnostic(
                    code: "MAP_APPLY_PATH_OUTSIDE_ROOT",
                    message: "Map edit write path resolves outside the project root: \(trimmedPath).",
                    path: trimmedPath
                )
            )
        }

        if let ancestor = nearestExistingAncestor(for: destination, root: root, fileManager: fileManager) {
            let resolvedAncestor = ancestor.resolvingSymlinksInPath().standardizedFileURL
            if !isContained(resolvedAncestor, in: resolvedRoot) {
                diagnostics.append(
                    pathDiagnostic(
                        code: "MAP_APPLY_PATH_OUTSIDE_ROOT",
                        message: "Map edit write path crosses a symlink outside the project root: \(trimmedPath).",
                        path: trimmedPath
                    )
                )
            }
        }

        return diagnostics
    }

    private static func generatedPathDiagnostics(path: String, components: [String]) -> [Diagnostic] {
        let pathExtension = (path as NSString).pathExtension.lowercased()
        guard pathExtension == "inc" else { return [] }
        return [
            pathDiagnostic(
                code: "MAP_APPLY_PATH_GENERATED",
                message: "Map edit plans cannot write generated .inc files: \(path).",
                path: path
            )
        ]
    }

    private static func artifactPathDiagnostics(path: String, components: [String], purpose: PathPurpose) -> [Diagnostic] {
        let lowercasedComponents = components.map { $0.lowercased() }
        let blockedComponents: Set<String>
        switch purpose {
        case .backup:
            blockedComponents = ["build", ".build", "deriveddata", ".swiftpm", "artifacts"]
        case .change:
            blockedComponents = ["build", ".build", "deriveddata", ".swiftpm", ".pokemonhackstudio", "artifacts"]
        }
        if lowercasedComponents.contains(where: { blockedComponents.contains($0) }) {
            return [
                pathDiagnostic(
                    code: "MAP_APPLY_PATH_ARTIFACT",
                    message: "Map edit plans cannot write build, cache, backup, or artifact paths: \(path).",
                    path: path
                )
            ]
        }

        let blockedExtensions: Set<String> = ["gba", "gb", "gbc", "sav", "srm", "elf", "map", "ips", "bps", "ups"]
        let pathExtension = (path as NSString).pathExtension.lowercased()
        if blockedExtensions.contains(pathExtension) {
            return [
                pathDiagnostic(
                    code: "MAP_APPLY_PATH_ROM_OR_ARTIFACT",
                    message: "Map edit plans cannot write ROM, patch, or build artifact files: \(path).",
                    path: path
                )
            ]
        }

        return []
    }

    private static func validateSourcePrecondition(change: MapEditFileChange, root: URL, fileManager: FileManager) -> [Diagnostic] {
        let destination = root.appendingPathComponent(change.path).standardizedFileURL
        guard fileManager.fileExists(atPath: destination.path) else {
            if change.originalByteCount == 0 { return [] }
            return [
                pathDiagnostic(
                    code: "MAP_APPLY_SOURCE_MISSING",
                    message: "Map edit source file no longer exists: \(change.path).",
                    path: change.path
                )
            ]
        }

        guard let attributes = try? fileManager.attributesOfItem(atPath: destination.path),
              let fileSize = attributes[.size] as? NSNumber
        else {
            return [
                pathDiagnostic(
                    code: "MAP_APPLY_SOURCE_UNREADABLE",
                    message: "Map edit source file could not be checked before apply: \(change.path).",
                    path: change.path
                )
            ]
        }

        guard fileSize.intValue == change.originalByteCount else {
            return [
                pathDiagnostic(
                    code: "MAP_APPLY_ORIGINAL_SIZE_MISMATCH",
                    message: "Map edit source file changed since planning: \(change.path).",
                    path: change.path
                )
            ]
        }

        return []
    }

    private static func nearestExistingAncestor(for url: URL, root: URL, fileManager: FileManager) -> URL? {
        var current = url
        while isContained(current, in: root) {
            if fileManager.fileExists(atPath: current.path) {
                return current
            }
            let parent = current.deletingLastPathComponent()
            if parent.path == current.path {
                return nil
            }
            current = parent
        }
        return nil
    }

    private static func isContained(_ url: URL, in root: URL) -> Bool {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        if path == rootPath {
            return true
        }
        let prefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
        return path.hasPrefix(prefix)
    }

    private static func pathDiagnostic(code: String, message: String, path: String) -> Diagnostic {
        Diagnostic(
            severity: .error,
            code: code,
            message: message,
            span: SourceSpan(relativePath: path, startLine: 1)
        )
    }
}

public enum MapVisualError: Error, LocalizedError, Equatable {
    case mapNotFound(String)
    case layoutNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .mapNotFound(let mapID):
            "Map not found: \(mapID)"
        case .layoutNotFound(let layoutID):
            "Layout not found: \(layoutID)"
        }
    }
}

private struct TilesetHeader {
    let symbol: String
    let isSecondary: Bool
    let tilesSymbol: String?
    let palettesSymbol: String?
    let metatilesSymbol: String?
    let attributesSymbol: String?
}

private struct GraphicsRefs {
    let tilePaths: [String: String]
    let palettePaths: [String: [String]]
}

private struct MetatileRefs {
    let metatilePaths: [String: String]
    let attributePaths: [String: String]
    let attributeWordSizes: [String: Int]
}

private typealias OrderedJSONObject = [OrderedJSONPair]

private struct OrderedJSONPair: Equatable {
    let key: String
    var value: OrderedJSONValue
}

private enum OrderedJSONValue: Equatable {
    case object([OrderedJSONPair])
    case array([OrderedJSONValue])
    case string(String)
    case number(String)
    case bool(Bool)
    case null

    var intValue: Int? {
        if case .number(let value) = self {
            return Int(value)
        }
        if case .string(let value) = self {
            return Int(value)
        }
        return nil
    }

    var displayValue: String {
        switch self {
        case .object:
            return "{...}"
        case .array:
            return "[...]"
        case .string(let value), .number(let value):
            return value
        case .bool(let value):
            return value ? "true" : "false"
        case .null:
            return "null"
        }
    }

    func renderPretty(indent: Int = 0) -> String {
        let pad = String(repeating: " ", count: indent)
        let childPad = String(repeating: " ", count: indent + 2)
        switch self {
        case .object(let pairs):
            guard !pairs.isEmpty else { return "{}" }
            let body = pairs.map { pair in
                "\(childPad)\"\(escape(pair.key))\": \(pair.value.renderPretty(indent: indent + 2))"
            }.joined(separator: ",\n")
            return "{\n\(body)\n\(pad)}"
        case .array(let values):
            guard !values.isEmpty else { return "[]" }
            if values.allSatisfy(\.isScalar) {
                return "[" + values.map { $0.renderPretty(indent: indent) }.joined(separator: ", ") + "]"
            }
            let body = values.map { "\(childPad)\($0.renderPretty(indent: indent + 2))" }.joined(separator: ",\n")
            return "[\n\(body)\n\(pad)]"
        case .string(let value):
            return "\"\(escape(value))\""
        case .number(let value):
            return value
        case .bool(let value):
            return value ? "true" : "false"
        case .null:
            return "null"
        }
    }

    private var isScalar: Bool {
        switch self {
        case .string, .number, .bool, .null:
            true
        case .object, .array:
            false
        }
    }

    private func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}

private extension OrderedJSONObject {
    mutating func set(key: String, value: OrderedJSONValue) {
        if let index = firstIndex(where: { $0.key == key }) {
            self[index].value = value
        } else {
            append(OrderedJSONPair(key: key, value: value))
        }
    }
}

private struct OrderedJSONParser {
    let scalars: [UnicodeScalar]
    var index: Int = 0

    init(text: String) {
        scalars = Array(text.unicodeScalars)
    }

    mutating func parse() throws -> OrderedJSONValue {
        try parseValue()
    }

    private mutating func parseValue() throws -> OrderedJSONValue {
        skipWhitespace()
        guard let scalar = peek() else { throw ParserError.unexpectedEnd }
        switch scalar {
        case "{":
            return try parseObject()
        case "[":
            return try parseArray()
        case "\"":
            return .string(try parseString())
        case "t", "f":
            return .bool(try parseBool())
        case "n":
            try consume("null")
            return .null
        default:
            return .number(try parseNumber())
        }
    }

    private mutating func parseObject() throws -> OrderedJSONValue {
        try consume("{")
        skipWhitespace()
        var pairs: [OrderedJSONPair] = []
        if try consumeIf("}") {
            return .object([])
        }
        while true {
            skipWhitespace()
            let key = try parseString()
            skipWhitespace()
            try consume(":")
            let value = try parseValue()
            pairs.append(OrderedJSONPair(key: key, value: value))
            skipWhitespace()
            if try consumeIf("}") {
                break
            }
            try consume(",")
        }
        return .object(pairs)
    }

    private mutating func parseArray() throws -> OrderedJSONValue {
        try consume("[")
        skipWhitespace()
        var values: [OrderedJSONValue] = []
        if try consumeIf("]") {
            return .array([])
        }
        while true {
            values.append(try parseValue())
            skipWhitespace()
            if try consumeIf("]") {
                break
            }
            try consume(",")
        }
        return .array(values)
    }

    private mutating func parseString() throws -> String {
        try consume("\"")
        var result = ""
        while let scalar = peek() {
            index += 1
            if scalar == "\"" {
                return result
            }
            if scalar == "\\" {
                guard let escaped = peek() else { throw ParserError.unexpectedEnd }
                index += 1
                switch escaped {
                case "\"", "\\", "/":
                    result.unicodeScalars.append(escaped)
                case "b":
                    result.append("\u{08}")
                case "f":
                    result.append("\u{0c}")
                case "n":
                    result.append("\n")
                case "r":
                    result.append("\r")
                case "t":
                    result.append("\t")
                case "u":
                    let hexScalars = (0..<4).compactMap { _ -> UnicodeScalar? in
                        guard let next = peek() else { return nil }
                        index += 1
                        return next
                    }
                    let hex = String(String.UnicodeScalarView(hexScalars))
                    if let value = UInt32(hex, radix: 16), let unicode = UnicodeScalar(value) {
                        result.unicodeScalars.append(unicode)
                    }
                default:
                    result.unicodeScalars.append(escaped)
                }
            } else {
                result.unicodeScalars.append(scalar)
            }
        }
        throw ParserError.unexpectedEnd
    }

    private mutating func parseBool() throws -> Bool {
        if try consumeIf("true") {
            return true
        }
        try consume("false")
        return false
    }

    private mutating func parseNumber() throws -> String {
        var number = ""
        while let scalar = peek(), "-+0123456789.eE".unicodeScalars.contains(scalar) {
            number.unicodeScalars.append(scalar)
            index += 1
        }
        guard !number.isEmpty else { throw ParserError.invalidToken }
        return number
    }

    private mutating func skipWhitespace() {
        while let scalar = peek(), CharacterSet.whitespacesAndNewlines.contains(scalar) {
            index += 1
        }
    }

    private func peek() -> UnicodeScalar? {
        scalars.indices.contains(index) ? scalars[index] : nil
    }

    private mutating func consume(_ token: String) throws {
        guard try consumeIf(token) else {
            throw ParserError.invalidToken
        }
    }

    private mutating func consumeIf(_ token: String) throws -> Bool {
        let tokenScalars = Array(token.unicodeScalars)
        guard index + tokenScalars.count <= scalars.count else { return false }
        guard Array(scalars[index..<(index + tokenScalars.count)]) == tokenScalars else {
            return false
        }
        index += tokenScalars.count
        return true
    }

    private enum ParserError: Error {
        case unexpectedEnd
        case invalidToken
    }
}

private func regexMatches(
    _ pattern: String,
    in text: String,
    options: NSRegularExpression.Options = []
) -> [[String]] {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
        return []
    }
    let nsText = text as NSString
    return regex.matches(in: text, range: NSRange(location: 0, length: nsText.length)).map { match in
        (0..<match.numberOfRanges).map { index in
            let range = match.range(at: index)
            guard range.location != NSNotFound else { return "" }
            return nsText.substring(with: range)
        }
    }
}
