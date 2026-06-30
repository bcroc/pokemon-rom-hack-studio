import Foundation

public struct ProjectMapCatalog: Codable, Equatable, Identifiable {
    public let id: String
    public let rootPath: String
    public let profile: GameProfile
    public let mapGroups: [MapGroupSummary]
    public let maps: [MapDescriptor]
    public let layoutSlots: [LayoutSlot]
    public let connectionsIncludeOrder: [String]
    public let diagnostics: [Diagnostic]

    public init(
        id: String,
        rootPath: String,
        profile: GameProfile,
        mapGroups: [MapGroupSummary],
        maps: [MapDescriptor],
        layoutSlots: [LayoutSlot],
        connectionsIncludeOrder: [String] = [],
        diagnostics: [Diagnostic] = []
    ) {
        self.id = id
        self.rootPath = rootPath
        self.profile = profile
        self.mapGroups = mapGroups
        self.maps = maps
        self.layoutSlots = layoutSlots
        self.connectionsIncludeOrder = connectionsIncludeOrder
        self.diagnostics = diagnostics
    }
}

public struct MapGroupSummary: Codable, Equatable, Identifiable {
    public let id: String
    public let orderIndex: Int
    public let mapNames: [String]
    public let maps: [MapDescriptor]

    public init(id: String, orderIndex: Int, mapNames: [String], maps: [MapDescriptor]) {
        self.id = id
        self.orderIndex = orderIndex
        self.mapNames = mapNames
        self.maps = maps
    }
}

public struct MapDescriptor: Codable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let sourcePath: String
    public let groupID: String?
    public let groupIndex: Int?
    public let mapIndexInGroup: Int?
    public let layout: String?
    public let layoutSlotIndex: Int?
    public let music: String?
    public let mapType: String?
    public let weather: String?
    public let regionMapSection: String?
    public let floorNumber: Int?
    public let sharedEventsMap: String?
    public let sharedScriptsMap: String?
    public let connectionsNoInclude: Bool
    public let connections: [MapConnection]
    public let eventCounts: MapEventCounts
    public let eventCapacity: MapEventCapacitySummary

    public init(
        id: String,
        name: String,
        sourcePath: String,
        groupID: String?,
        groupIndex: Int?,
        mapIndexInGroup: Int?,
        layout: String?,
        layoutSlotIndex: Int?,
        music: String?,
        mapType: String?,
        weather: String?,
        regionMapSection: String?,
        floorNumber: Int?,
        sharedEventsMap: String?,
        sharedScriptsMap: String?,
        connectionsNoInclude: Bool = false,
        connections: [MapConnection] = [],
        eventCounts: MapEventCounts = MapEventCounts(),
        eventCapacity: MapEventCapacitySummary? = nil
    ) {
        self.id = id
        self.name = name
        self.sourcePath = sourcePath
        self.groupID = groupID
        self.groupIndex = groupIndex
        self.mapIndexInGroup = mapIndexInGroup
        self.layout = layout
        self.layoutSlotIndex = layoutSlotIndex
        self.music = music
        self.mapType = mapType
        self.weather = weather
        self.regionMapSection = regionMapSection
        self.floorNumber = floorNumber
        self.sharedEventsMap = sharedEventsMap
        self.sharedScriptsMap = sharedScriptsMap
        self.connectionsNoInclude = connectionsNoInclude
        self.connections = connections
        self.eventCounts = eventCounts
        self.eventCapacity = eventCapacity ?? MapEventCapacitySummary(
            counts: eventCounts,
            limits: .unknown,
            mapSourcePath: sourcePath
        )
    }
}

public struct MapEventCounts: Codable, Equatable, Identifiable, Sendable {
    public var id: String { "map-event-counts" }

    public let objectEvents: Int
    public let warpEvents: Int
    public let coordEvents: Int
    public let bgEvents: Int

    public var total: Int {
        objectEvents + warpEvents + coordEvents + bgEvents
    }

    public init(objectEvents: Int = 0, warpEvents: Int = 0, coordEvents: Int = 0, bgEvents: Int = 0) {
        self.objectEvents = objectEvents
        self.warpEvents = warpEvents
        self.coordEvents = coordEvents
        self.bgEvents = bgEvents
    }

    public init(events: [MapEventDescriptor]) {
        self.init(
            objectEvents: events.filter { $0.kind == .object }.count,
            warpEvents: events.filter { $0.kind == .warp }.count,
            coordEvents: events.filter { $0.kind == .coord }.count,
            bgEvents: events.filter { $0.kind == .bg }.count
        )
    }

    public func count(for kind: MapEventKind) -> Int {
        switch kind {
        case .object:
            objectEvents
        case .warp:
            warpEvents
        case .coord:
            coordEvents
        case .bg:
            bgEvents
        case .connection:
            0
        }
    }
}

public struct MapEventCapacityLimits: Codable, Equatable, Sendable {
    public struct Source: Codable, Equatable, Identifiable, Sendable {
        public var id: String { "\(kind.rawValue):\(symbol):\(path)" }

        public let kind: MapEventKind
        public let path: String
        public let symbol: String
        public let detail: String

        public init(kind: MapEventKind, path: String, symbol: String, detail: String) {
            self.kind = kind
            self.path = path
            self.symbol = symbol
            self.detail = detail
        }
    }

    public static let unknown = MapEventCapacityLimits()
    public static let storedCountFieldLimit = 255

    public let objectEvents: Int?
    public let warpEvents: Int?
    public let coordEvents: Int?
    public let bgEvents: Int?
    public let objectRuntimeSlots: Int?
    public let sources: [Source]

    public init(
        objectEvents: Int? = nil,
        warpEvents: Int? = nil,
        coordEvents: Int? = nil,
        bgEvents: Int? = nil,
        objectRuntimeSlots: Int? = nil,
        sources: [Source] = []
    ) {
        self.objectEvents = objectEvents
        self.warpEvents = warpEvents
        self.coordEvents = coordEvents
        self.bgEvents = bgEvents
        self.objectRuntimeSlots = objectRuntimeSlots
        self.sources = sources
    }

    public func limit(for kind: MapEventKind) -> Int? {
        switch kind {
        case .object:
            objectEvents
        case .warp:
            warpEvents
        case .coord:
            coordEvents
        case .bg:
            bgEvents
        case .connection:
            nil
        }
    }

    public func source(for kind: MapEventKind) -> Source? {
        sources.first { $0.kind == kind }
    }
}

public struct MapEventCapacityUsage: Codable, Equatable, Identifiable, Sendable {
    public var id: String { kind.rawValue }

    public let kind: MapEventKind
    public let count: Int
    public let limit: Int?
    public let source: MapEventCapacityLimits.Source?

    public init(
        kind: MapEventKind,
        count: Int,
        limit: Int?,
        source: MapEventCapacityLimits.Source?
    ) {
        self.kind = kind
        self.count = count
        self.limit = limit
        self.source = source
    }

    public var remaining: Int? {
        limit.map { $0 - count }
    }

    public var isOverLimit: Bool {
        guard let limit else { return false }
        return count > limit
    }
}

public struct MapEventCapacitySummary: Codable, Equatable, Sendable {
    public static let unknown = MapEventCapacitySummary()
    public static let eventKinds: [MapEventKind] = [.object, .warp, .coord, .bg]

    public let counts: MapEventCounts
    public let limits: MapEventCapacityLimits
    public let mapSourcePath: String?

    public init(
        counts: MapEventCounts = MapEventCounts(),
        limits: MapEventCapacityLimits = .unknown,
        mapSourcePath: String? = nil
    ) {
        self.counts = counts
        self.limits = limits
        self.mapSourcePath = mapSourcePath
    }

    public var usages: [MapEventCapacityUsage] {
        Self.eventKinds.map { kind in
            MapEventCapacityUsage(
                kind: kind,
                count: counts.count(for: kind),
                limit: limits.limit(for: kind),
                source: limits.source(for: kind)
            )
        }
    }

    public var diagnostics: [Diagnostic] {
        usages.compactMap { usage in
            guard usage.isOverLimit, let limit = usage.limit else { return nil }
            let source = usage.source
            let sourceText = source.map { " from \($0.symbol) in \($0.path)" } ?? ""
            return Diagnostic(
                severity: .warning,
                code: "MAP_EVENT_CAPACITY_OVER_LIMIT",
                message: "\(usage.kind.rawValue) events use \(usage.count) entries, exceeding the source-backed limit of \(limit)\(sourceText).",
                span: mapSourcePath.map { SourceSpan(relativePath: $0, startLine: 1) }
            )
        }
    }
}

public struct MapConnection: Codable, Equatable, Identifiable {
    public var id: String { "\(sourceMapID)-connection-\(index)" }

    public let sourceMapID: String
    public let index: Int
    public let map: String?
    public let offset: Int?
    public let direction: String?

    public init(sourceMapID: String, index: Int, map: String?, offset: Int?, direction: String?) {
        self.sourceMapID = sourceMapID
        self.index = index
        self.map = map
        self.offset = offset
        self.direction = direction
    }
}

public struct LayoutSlot: Codable, Equatable, Identifiable {
    public var id: String { layoutID ?? "layout-slot-\(slotIndex)" }

    public let slotIndex: Int
    public let layoutID: String?
    public let name: String?
    public let width: Int?
    public let height: Int?
    public let borderWidth: Int?
    public let borderHeight: Int?
    public let primaryTileset: String?
    public let secondaryTileset: String?
    public let borderFilepath: String?
    public let blockdataFilepath: String?
    public let sourcePath: String
    public let blockdataPreview: LayoutBlockdataPreview?

    public var isEmpty: Bool {
        layoutID == nil
    }

    public init(
        slotIndex: Int,
        layoutID: String?,
        name: String?,
        width: Int?,
        height: Int?,
        borderWidth: Int?,
        borderHeight: Int?,
        primaryTileset: String?,
        secondaryTileset: String?,
        borderFilepath: String?,
        blockdataFilepath: String?,
        sourcePath: String,
        blockdataPreview: LayoutBlockdataPreview? = nil
    ) {
        self.slotIndex = slotIndex
        self.layoutID = layoutID
        self.name = name
        self.width = width
        self.height = height
        self.borderWidth = borderWidth
        self.borderHeight = borderHeight
        self.primaryTileset = primaryTileset
        self.secondaryTileset = secondaryTileset
        self.borderFilepath = borderFilepath
        self.blockdataFilepath = blockdataFilepath
        self.sourcePath = sourcePath
        self.blockdataPreview = blockdataPreview
    }
}

public struct LayoutBlockdataPreview: Codable, Equatable, Identifiable {
    public var id: String { blockdataFilepath }

    public let blockdataFilepath: String
    public let width: Int
    public let height: Int
    public let expectedByteCount: Int
    public let actualByteCount: Int
    public let maxMetatileCount: Int
    public let metatileIDs: [UInt16]
    public let isCapped: Bool
    public let isByteCountValid: Bool

    public init(
        blockdataFilepath: String,
        width: Int,
        height: Int,
        expectedByteCount: Int,
        actualByteCount: Int,
        maxMetatileCount: Int,
        metatileIDs: [UInt16],
        isCapped: Bool,
        isByteCountValid: Bool
    ) {
        self.blockdataFilepath = blockdataFilepath
        self.width = width
        self.height = height
        self.expectedByteCount = expectedByteCount
        self.actualByteCount = actualByteCount
        self.maxMetatileCount = maxMetatileCount
        self.metatileIDs = metatileIDs
        self.isCapped = isCapped
        self.isByteCountValid = isByteCountValid
    }
}

public enum ProjectMapCatalogLoader {
    private static let maxPreviewMetatiles = 256
    private static let mapGroupsPath = "data/maps/map_groups.json"
    private static let layoutsPath = "data/layouts/layouts.json"
    private static let globalConstantsPath = "include/constants/global.h"
    private static let globalFieldmapPath = "include/global.fieldmap.h"

    public static func load(from projectIndex: ProjectIndex, fileManager: FileManager = .default) throws -> ProjectMapCatalog {
        let root = URL(fileURLWithPath: projectIndex.root.path).standardizedFileURL
        let mapGroupIndex = try SourceParsers.decodeMapGroups(Data(contentsOf: root.appendingPathComponent(mapGroupsPath)))
        let layoutIndex = try SourceParsers.decodeLayouts(Data(contentsOf: root.appendingPathComponent(layoutsPath)))
        let referencedLayoutIDs = collectReferencedLayoutIDs(mapGroupIndex: mapGroupIndex, root: root, fileManager: fileManager)
        let eventCapacityLimits = loadEventCapacityLimits(root: root, fileManager: fileManager)

        var diagnostics: [Diagnostic] = []
        let layoutSlots = layoutIndex.layoutSlots.enumerated().map { index, descriptor in
            makeLayoutSlot(
                slotIndex: index,
                descriptor: descriptor,
                root: root,
                fileManager: fileManager,
                shouldEmitBlockdataDiagnostics: descriptor.map { referencedLayoutIDs.contains($0.id) } ?? false,
                diagnostics: &diagnostics
            )
        }

        var layoutSlotsByID: [String: LayoutSlot] = [:]
        for slot in layoutSlots {
            guard let layoutID = slot.layoutID else {
                continue
            }
            layoutSlotsByID[layoutID] = slot
        }

        var maps: [MapDescriptor] = []
        var mapGroups: [MapGroupSummary] = []
        let orderedGroupIDs = mapGroupIndex.groupOrder
            + mapGroupIndex.groups.keys.filter { !mapGroupIndex.groupOrder.contains($0) }.sorted()

        for (groupIndex, groupID) in orderedGroupIDs.enumerated() {
            let mapNames = mapGroupIndex.groups[groupID] ?? []
            var groupMaps: [MapDescriptor] = []

            for (mapIndex, mapName) in mapNames.enumerated() {
                guard let descriptor = loadMap(
                    named: mapName,
                    groupID: groupID,
                    groupIndex: groupIndex,
                    mapIndexInGroup: mapIndex,
                    root: root,
                    layoutSlotsByID: layoutSlotsByID,
                    eventCapacityLimits: eventCapacityLimits,
                    fileManager: fileManager,
                    diagnostics: &diagnostics
                ) else {
                    continue
                }
                groupMaps.append(descriptor)
                maps.append(descriptor)
            }

            mapGroups.append(
                MapGroupSummary(
                    id: groupID,
                    orderIndex: groupIndex,
                    mapNames: mapNames,
                    maps: groupMaps
                )
            )
        }

        return ProjectMapCatalog(
            id: root.path,
            rootPath: root.path,
            profile: projectIndex.profile,
            mapGroups: mapGroups,
            maps: maps,
            layoutSlots: layoutSlots,
            connectionsIncludeOrder: mapGroupIndex.connectionsIncludeOrder,
            diagnostics: diagnostics
        )
    }

    private static func makeLayoutSlot(
        slotIndex: Int,
        descriptor: LayoutDescriptor?,
        root: URL,
        fileManager: FileManager,
        shouldEmitBlockdataDiagnostics: Bool,
        diagnostics: inout [Diagnostic]
    ) -> LayoutSlot {
        guard let descriptor else {
            return LayoutSlot(
                slotIndex: slotIndex,
                layoutID: nil,
                name: nil,
                width: nil,
                height: nil,
                borderWidth: nil,
                borderHeight: nil,
                primaryTileset: nil,
                secondaryTileset: nil,
                borderFilepath: nil,
                blockdataFilepath: nil,
                sourcePath: layoutsPath
            )
        }

        let preview = makeBlockdataPreview(
            descriptor: descriptor,
            root: root,
            fileManager: fileManager,
            shouldEmitDiagnostics: shouldEmitBlockdataDiagnostics,
            diagnostics: &diagnostics
        )

        return LayoutSlot(
            slotIndex: slotIndex,
            layoutID: descriptor.id,
            name: descriptor.name,
            width: descriptor.width,
            height: descriptor.height,
            borderWidth: descriptor.borderWidth,
            borderHeight: descriptor.borderHeight,
            primaryTileset: descriptor.primaryTileset,
            secondaryTileset: descriptor.secondaryTileset,
            borderFilepath: descriptor.borderFilepath,
            blockdataFilepath: descriptor.blockdataFilepath,
            sourcePath: layoutsPath,
            blockdataPreview: preview
        )
    }

    private static func makeBlockdataPreview(
        descriptor: LayoutDescriptor,
        root: URL,
        fileManager: FileManager,
        shouldEmitDiagnostics: Bool,
        diagnostics: inout [Diagnostic]
    ) -> LayoutBlockdataPreview? {
        guard descriptor.width > 0, descriptor.height > 0 else {
            return nil
        }

        let blockdataURL = root.appendingPathComponent(descriptor.blockdataFilepath)
        guard fileManager.fileExists(atPath: blockdataURL.path) else {
            return nil
        }

        let data: Data
        do {
            data = try Data(contentsOf: blockdataURL)
        } catch {
            if shouldEmitDiagnostics {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "LAYOUT_BLOCKDATA_READ_FAILED",
                        message: "Could not read blockdata for \(descriptor.id): \(error.localizedDescription)",
                        span: SourceSpan(relativePath: descriptor.blockdataFilepath, startLine: 1)
                    )
                )
            }
            return nil
        }

        let expectedByteCount = descriptor.width * descriptor.height * 2
        let metatileIDs = readMetatileIDs(data: data, maxCount: maxPreviewMetatiles)
        let isByteCountValid = data.count == expectedByteCount

        if shouldEmitDiagnostics, !isByteCountValid {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "LAYOUT_BLOCKDATA_SIZE_MISMATCH",
                    message: "Blockdata for \(descriptor.id) is \(data.count) bytes; expected \(expectedByteCount).",
                    span: SourceSpan(relativePath: descriptor.blockdataFilepath, startLine: 1)
                )
            )
        }

        return LayoutBlockdataPreview(
            blockdataFilepath: descriptor.blockdataFilepath,
            width: descriptor.width,
            height: descriptor.height,
            expectedByteCount: expectedByteCount,
            actualByteCount: data.count,
            maxMetatileCount: maxPreviewMetatiles,
            metatileIDs: metatileIDs,
            isCapped: data.count / 2 > maxPreviewMetatiles,
            isByteCountValid: isByteCountValid
        )
    }

    private static func readMetatileIDs(data: Data, maxCount: Int) -> [UInt16] {
        let bytes = [UInt8](data)
        let count = min(bytes.count / 2, maxCount)
        guard count > 0 else {
            return []
        }

        return (0..<count).map { index in
            let offset = index * 2
            return UInt16(bytes[offset]) | (UInt16(bytes[offset + 1]) << 8)
        }
    }

    private static func loadMap(
        named mapName: String,
        groupID: String,
        groupIndex: Int,
        mapIndexInGroup: Int,
        root: URL,
        layoutSlotsByID: [String: LayoutSlot],
        eventCapacityLimits: MapEventCapacityLimits,
        fileManager: FileManager,
        diagnostics: inout [Diagnostic]
    ) -> MapDescriptor? {
        let sourcePath = "data/maps/\(mapName)/map.json"
        let mapURL = root.appendingPathComponent(sourcePath)
        guard fileManager.fileExists(atPath: mapURL.path) else {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "MAP_JSON_MISSING",
                    message: "Map group \(groupID) references \(mapName), but \(sourcePath) is missing.",
                    span: SourceSpan(relativePath: sourcePath, startLine: 1)
                )
            )
            return nil
        }

        let rawMap: RawMapJSON
        do {
            rawMap = try JSONDecoder().decode(RawMapJSON.self, from: Data(contentsOf: mapURL))
        } catch {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "MAP_JSON_DECODE_FAILED",
                    message: "Could not decode \(sourcePath): \(error.localizedDescription)",
                    span: SourceSpan(relativePath: sourcePath, startLine: 1)
                )
            )
            return nil
        }

        let mapID = rawMap.id ?? mapName
        let layoutSlotIndex = rawMap.layout.flatMap { layoutSlotsByID[$0]?.slotIndex }
        if let layout = rawMap.layout, layoutSlotsByID[layout] == nil {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "MAP_LAYOUT_MISSING",
                    message: "\(mapID) references layout \(layout), but that layout is not present in \(layoutsPath).",
                    span: SourceSpan(relativePath: sourcePath, startLine: 1)
                )
            )
        }

        let connections = rawMap.connections.enumerated().map { index, connection in
            MapConnection(
                sourceMapID: mapID,
                index: index,
                map: connection.map,
                offset: connection.offset,
                direction: connection.direction
            )
        }
        let eventCapacity = MapEventCapacitySummary(
            counts: rawMap.eventCounts,
            limits: eventCapacityLimits,
            mapSourcePath: sourcePath
        )
        diagnostics.append(contentsOf: eventCapacity.diagnostics)

        return MapDescriptor(
            id: mapID,
            name: rawMap.name ?? mapName,
            sourcePath: sourcePath,
            groupID: groupID,
            groupIndex: groupIndex,
            mapIndexInGroup: mapIndexInGroup,
            layout: rawMap.layout,
            layoutSlotIndex: layoutSlotIndex,
            music: rawMap.music,
            mapType: rawMap.mapType,
            weather: rawMap.weather,
            regionMapSection: rawMap.regionMapSection,
            floorNumber: rawMap.floorNumber,
            sharedEventsMap: rawMap.sharedEventsMap,
            sharedScriptsMap: rawMap.sharedScriptsMap,
            connectionsNoInclude: rawMap.connectionsNoInclude,
            connections: connections,
            eventCounts: rawMap.eventCounts,
            eventCapacity: eventCapacity
        )
    }

    private static func loadEventCapacityLimits(root: URL, fileManager: FileManager) -> MapEventCapacityLimits {
        let globalConstantsText = readText(root: root, path: globalConstantsPath, fileManager: fileManager)
        let fieldmapText = readText(root: root, path: globalFieldmapPath, fileManager: fileManager)
        let objectTemplateLimit = parseDefine("OBJECT_EVENT_TEMPLATES_COUNT", in: globalConstantsText)
        let objectRuntimeSlots = parseDefine("OBJECT_EVENTS_COUNT", in: globalConstantsText)
        let storedCountFields = parseMapEventsStoredCountFields(fieldmapText)

        var sources: [MapEventCapacityLimits.Source] = []
        if objectTemplateLimit != nil {
            sources.append(
                MapEventCapacityLimits.Source(
                    kind: .object,
                    path: globalConstantsPath,
                    symbol: "OBJECT_EVENT_TEMPLATES_COUNT",
                    detail: "Object map template capacity."
                )
            )
        } else if storedCountFields.contains("objectEventCount") {
            sources.append(
                MapEventCapacityLimits.Source(
                    kind: .object,
                    path: globalFieldmapPath,
                    symbol: "u8 objectEventCount",
                    detail: "Stored object event count field width."
                )
            )
        }

        let countFieldSources: [(field: String, kind: MapEventKind, detail: String)] = [
            ("warpCount", .warp, "Stored warp event count field width."),
            ("coordEventCount", .coord, "Stored coord event count field width."),
            ("bgEventCount", .bg, "Stored BG event count field width.")
        ]
        for source in countFieldSources where storedCountFields.contains(source.field) {
            sources.append(
                MapEventCapacityLimits.Source(
                    kind: source.kind,
                    path: globalFieldmapPath,
                    symbol: "u8 \(source.field)",
                    detail: source.detail
                )
            )
        }

        let storedLimit = MapEventCapacityLimits.storedCountFieldLimit
        return MapEventCapacityLimits(
            objectEvents: objectTemplateLimit ?? (storedCountFields.contains("objectEventCount") ? storedLimit : nil),
            warpEvents: storedCountFields.contains("warpCount") ? storedLimit : nil,
            coordEvents: storedCountFields.contains("coordEventCount") ? storedLimit : nil,
            bgEvents: storedCountFields.contains("bgEventCount") ? storedLimit : nil,
            objectRuntimeSlots: objectRuntimeSlots,
            sources: sources
        )
    }

    private static func readText(root: URL, path: String, fileManager: FileManager) -> String {
        let url = root.appendingPathComponent(path)
        guard fileManager.fileExists(atPath: url.path) else { return "" }
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    private static func parseDefine(_ symbol: String, in text: String) -> Int? {
        let pattern = #"(?m)^\s*#define\s+\#(symbol)\s+([0-9A-Fa-fx]+)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text)),
              let valueRange = Range(match.range(at: 1), in: text)
        else {
            return nil
        }
        let value = String(text[valueRange])
        if value.lowercased().hasPrefix("0x") {
            return Int(value.dropFirst(2), radix: 16)
        }
        return Int(value)
    }

    private static func parseMapEventsStoredCountFields(_ text: String) -> Set<String> {
        guard let structRange = text.range(of: #"struct\s+MapEvents\s*\{([^}]*)\}"#, options: .regularExpression) else {
            return []
        }
        let body = String(text[structRange])
        let pattern = #"(?m)^\s*u8\s+(objectEventCount|warpCount|coordEventCount|bgEventCount)\s*;"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(body.startIndex..<body.endIndex, in: body)
        return Set(regex.matches(in: body, range: range).compactMap { match in
            guard let fieldRange = Range(match.range(at: 1), in: body) else { return nil }
            return String(body[fieldRange])
        })
    }

    private static func collectReferencedLayoutIDs(
        mapGroupIndex: MapGroupIndex,
        root: URL,
        fileManager: FileManager
    ) -> Set<String> {
        let orderedGroupIDs = mapGroupIndex.groupOrder
            + mapGroupIndex.groups.keys.filter { !mapGroupIndex.groupOrder.contains($0) }.sorted()
        var layoutIDs: Set<String> = []

        for groupID in orderedGroupIDs {
            for mapName in mapGroupIndex.groups[groupID] ?? [] {
                let mapURL = root.appendingPathComponent("data/maps/\(mapName)/map.json")
                guard fileManager.fileExists(atPath: mapURL.path) else { continue }
                guard
                    let data = try? Data(contentsOf: mapURL),
                    let rawMap = try? JSONDecoder().decode(RawMapJSON.self, from: data),
                    let layout = rawMap.layout
                else {
                    continue
                }
                layoutIDs.insert(layout)
            }
        }

        return layoutIDs
    }
}

private struct RawMapJSON: Decodable {
    let id: String?
    let name: String?
    let layout: String?
    let music: String?
    let mapType: String?
    let weather: String?
    let regionMapSection: String?
    let floorNumber: Int?
    let sharedEventsMap: String?
    let sharedScriptsMap: String?
    let connectionsNoInclude: Bool
    let connections: [RawMapConnection]
    let eventCounts: MapEventCounts

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case layout
        case music
        case mapType = "map_type"
        case weather
        case regionMapSection = "region_map_section"
        case floorNumber = "floor_number"
        case sharedEventsMap = "shared_events_map"
        case sharedScriptsMap = "shared_scripts_map"
        case connectionsNoInclude = "connections_no_include"
        case connections
        case objectEvents = "object_events"
        case warpEvents = "warp_events"
        case coordEvents = "coord_events"
        case bgEvents = "bg_events"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        layout = try container.decodeIfPresent(String.self, forKey: .layout)
        music = try container.decodeIfPresent(String.self, forKey: .music)
        mapType = try container.decodeIfPresent(String.self, forKey: .mapType)
        weather = try container.decodeIfPresent(String.self, forKey: .weather)
        regionMapSection = try container.decodeIfPresent(String.self, forKey: .regionMapSection)
        floorNumber = try container.decodeIfPresent(Int.self, forKey: .floorNumber)
        sharedEventsMap = try container.decodeIfPresent(String.self, forKey: .sharedEventsMap)
        sharedScriptsMap = try container.decodeIfPresent(String.self, forKey: .sharedScriptsMap)
        connectionsNoInclude = try container.decodeIfPresent(Bool.self, forKey: .connectionsNoInclude) ?? false
        connections = try container.decodeIfPresent([RawMapConnection].self, forKey: .connections) ?? []

        eventCounts = MapEventCounts(
            objectEvents: (try container.decodeIfPresent([IgnoredJSONValue].self, forKey: .objectEvents))?.count ?? 0,
            warpEvents: (try container.decodeIfPresent([IgnoredJSONValue].self, forKey: .warpEvents))?.count ?? 0,
            coordEvents: (try container.decodeIfPresent([IgnoredJSONValue].self, forKey: .coordEvents))?.count ?? 0,
            bgEvents: (try container.decodeIfPresent([IgnoredJSONValue].self, forKey: .bgEvents))?.count ?? 0
        )
    }
}

private struct RawMapConnection: Decodable {
    let map: String?
    let offset: Int?
    let direction: String?

    private enum CodingKeys: String, CodingKey {
        case map
        case offset
        case direction
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        map = try container.decodeIfPresent(String.self, forKey: .map)
        offset = try container.decodeFlexibleIntIfPresent(forKey: .offset)
        direction = try container.decodeIfPresent(String.self, forKey: .direction)
    }
}

private struct IgnoredJSONValue: Decodable {}

private extension KeyedDecodingContainer {
    func decodeFlexibleIntIfPresent(forKey key: Key) throws -> Int? {
        if let value = try decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let value = try decodeIfPresent(String.self, forKey: key) {
            return Int(value)
        }
        return nil
    }
}
