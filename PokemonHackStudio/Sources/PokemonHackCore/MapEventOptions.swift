import Foundation

public enum MapEventOptionGroup: String, Codable, Equatable, CaseIterable, Sendable {
    case maps
    case scripts
    case objectGraphics
    case items
    case variables
    case movementTypes
    case trainerTypes
    case facingDirections
    case flags
}

public struct MapEventOptionsCatalog: Codable, Equatable, Sendable {
    public static let empty = MapEventOptionsCatalog()

    public let mapIDs: [String]
    public let mapWarpCounts: [String: Int]
    public let scriptLabels: [String]
    public let objectGraphicsIDs: [String]
    public let objectSprites: [MapEventSpriteDescriptor]
    public let itemIDs: [String]
    public let variableIDs: [String]
    public let movementTypes: [String]
    public let trainerTypes: [String]
    public let facingDirections: [String]
    public let flags: [String]
    public let speciesIDs: [String]

    private let mapIDSet: Set<String>
    private let scriptLabelSet: Set<String>
    private let objectGraphicsIDSet: Set<String>
    private let itemIDSet: Set<String>
    private let variableIDSet: Set<String>
    private let movementTypeSet: Set<String>
    private let trainerTypeSet: Set<String>
    private let facingDirectionSet: Set<String>
    private let flagSet: Set<String>
    private let objectSpritesByGraphicsID: [String: MapEventSpriteDescriptor]

    private enum CodingKeys: String, CodingKey {
        case mapIDs
        case mapWarpCounts
        case scriptLabels
        case objectGraphicsIDs
        case objectSprites
        case itemIDs
        case variableIDs
        case movementTypes
        case trainerTypes
        case facingDirections
        case flags
        case speciesIDs
    }

    public init(
        mapIDs: [String] = [],
        mapWarpCounts: [String: Int] = [:],
        scriptLabels: [String] = [],
        objectGraphicsIDs: [String] = [],
        objectSprites: [MapEventSpriteDescriptor] = [],
        itemIDs: [String] = [],
        variableIDs: [String] = [],
        movementTypes: [String] = [],
        trainerTypes: [String] = [],
        facingDirections: [String] = [],
        flags: [String] = [],
        speciesIDs: [String] = []
    ) {
        self.mapIDs = Self.uniqueSorted(mapIDs)
        self.mapWarpCounts = mapWarpCounts
        self.scriptLabels = Self.uniqueSorted(scriptLabels)
        self.objectGraphicsIDs = Self.uniqueSorted(objectGraphicsIDs)
        self.objectSprites = Self.uniqueSprites(objectSprites)
        self.itemIDs = Self.uniqueSorted(itemIDs)
        self.variableIDs = Self.uniqueSorted(variableIDs)
        self.movementTypes = Self.uniqueSorted(movementTypes)
        self.trainerTypes = Self.uniqueSorted(trainerTypes)
        self.facingDirections = Self.uniqueSorted(facingDirections)
        self.flags = Self.uniqueSorted(flags)
        self.speciesIDs = Self.uniqueSorted(speciesIDs)
        mapIDSet = Set(self.mapIDs)
        scriptLabelSet = Set(self.scriptLabels)
        objectGraphicsIDSet = Set(self.objectGraphicsIDs)
        itemIDSet = Set(self.itemIDs)
        variableIDSet = Set(self.variableIDs)
        movementTypeSet = Set(self.movementTypes)
        trainerTypeSet = Set(self.trainerTypes)
        facingDirectionSet = Set(self.facingDirections)
        flagSet = Set(self.flags)
        objectSpritesByGraphicsID = Dictionary(uniqueKeysWithValues: self.objectSprites.map { ($0.graphicsID, $0) })
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            mapIDs: try container.decodeIfPresent([String].self, forKey: .mapIDs) ?? [],
            mapWarpCounts: try container.decodeIfPresent([String: Int].self, forKey: .mapWarpCounts) ?? [:],
            scriptLabels: try container.decodeIfPresent([String].self, forKey: .scriptLabels) ?? [],
            objectGraphicsIDs: try container.decodeIfPresent([String].self, forKey: .objectGraphicsIDs) ?? [],
            objectSprites: try container.decodeIfPresent([MapEventSpriteDescriptor].self, forKey: .objectSprites) ?? [],
            itemIDs: try container.decodeIfPresent([String].self, forKey: .itemIDs) ?? [],
            variableIDs: try container.decodeIfPresent([String].self, forKey: .variableIDs) ?? [],
            movementTypes: try container.decodeIfPresent([String].self, forKey: .movementTypes) ?? [],
            trainerTypes: try container.decodeIfPresent([String].self, forKey: .trainerTypes) ?? [],
            facingDirections: try container.decodeIfPresent([String].self, forKey: .facingDirections) ?? [],
            flags: try container.decodeIfPresent([String].self, forKey: .flags) ?? [],
            speciesIDs: try container.decodeIfPresent([String].self, forKey: .speciesIDs) ?? []
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mapIDs, forKey: .mapIDs)
        try container.encode(mapWarpCounts, forKey: .mapWarpCounts)
        try container.encode(scriptLabels, forKey: .scriptLabels)
        try container.encode(objectGraphicsIDs, forKey: .objectGraphicsIDs)
        try container.encode(objectSprites, forKey: .objectSprites)
        try container.encode(itemIDs, forKey: .itemIDs)
        try container.encode(variableIDs, forKey: .variableIDs)
        try container.encode(movementTypes, forKey: .movementTypes)
        try container.encode(trainerTypes, forKey: .trainerTypes)
        try container.encode(facingDirections, forKey: .facingDirections)
        try container.encode(flags, forKey: .flags)
        try container.encode(speciesIDs, forKey: .speciesIDs)
    }

    public static func load(
        root: URL,
        catalog: ProjectMapCatalog,
        scriptIndex: MapScriptIndex,
        objectSprites: [MapEventSpriteDescriptor],
        fileManager: FileManager = .default
    ) -> MapEventOptionsCatalog {
        let mapIDs = catalog.maps.map { $0.id }
        let mapWarpCounts = Dictionary(uniqueKeysWithValues: catalog.maps.map { ($0.id, $0.eventCounts.warpEvents) })
        let spriteIDs = objectSprites.map { $0.graphicsID }
        let staticOptions = MapEventOptionsStaticCatalog.load(root: root, fileManager: fileManager)

        return MapEventOptionsCatalog(
            mapIDs: mapIDs,
            mapWarpCounts: mapWarpCounts,
            scriptLabels: scriptIndex.labels.map { $0.label },
            objectGraphicsIDs: spriteIDs,
            objectSprites: objectSprites,
            itemIDs: staticOptions.itemIDs,
            variableIDs: staticOptions.variableIDs,
            movementTypes: staticOptions.movementTypes,
            trainerTypes: staticOptions.trainerTypes,
            facingDirections: staticOptions.facingDirections,
            flags: staticOptions.flags,
            speciesIDs: staticOptions.speciesIDs
        )
    }

    public func options(for key: String) -> [String] {
        switch key {
        case "dest_map", "map":
            return mapIDs
        case "script":
            return scriptLabels
        case "graphics_id":
            return objectGraphicsIDs
        case "item":
            return itemIDs
        case "var":
            return variableIDs
        case "movement_type":
            return movementTypes
        case "trainer_type":
            return trainerTypes
        case "player_facing_dir":
            return facingDirections
        case "flag":
            return flags
        default:
            return []
        }
    }

    public func contains(_ value: String, in group: MapEventOptionGroup) -> Bool {
        guard !value.isEmpty else { return true }
        switch group {
        case .maps:
            return mapIDSet.contains(value)
        case .scripts:
            return scriptLabelSet.contains(value)
        case .objectGraphics:
            return objectGraphicsIDSet.contains(value)
        case .items:
            return itemIDSet.contains(value)
        case .variables:
            return variableIDSet.contains(value)
        case .movementTypes:
            return movementTypeSet.contains(value)
        case .trainerTypes:
            return trainerTypeSet.contains(value)
        case .facingDirections:
            return facingDirectionSet.contains(value)
        case .flags:
            return flagSet.contains(value)
        }
    }

    public func sprite(for graphicsID: String?) -> MapEventSpriteDescriptor? {
        guard let graphicsID else { return nil }
        return objectSpritesByGraphicsID[graphicsID]
    }

    public func warpCount(for mapID: String?) -> Int? {
        guard let mapID else { return nil }
        return mapWarpCounts[mapID]
    }

    private static func uniqueSorted(_ values: [String]) -> [String] {
        Array(Set(values.filter { !$0.isEmpty })).sorted()
    }

    private static func uniqueSprites(_ sprites: [MapEventSpriteDescriptor]) -> [MapEventSpriteDescriptor] {
        var seen: Set<String> = []
        return sprites
            .sorted { $0.graphicsID < $1.graphicsID }
            .filter { sprite in
                seen.insert(sprite.graphicsID).inserted
            }
    }
}

public struct MapEventOptionsStaticCatalog: Codable, Equatable, Sendable {
    public static let empty = MapEventOptionsStaticCatalog()

    public let itemIDs: [String]
    public let variableIDs: [String]
    public let movementTypes: [String]
    public let trainerTypes: [String]
    public let facingDirections: [String]
    public let flags: [String]
    public let speciesIDs: [String]

    public init(
        itemIDs: [String] = [],
        variableIDs: [String] = [],
        movementTypes: [String] = [],
        trainerTypes: [String] = [],
        facingDirections: [String] = [],
        flags: [String] = [],
        speciesIDs: [String] = []
    ) {
        self.itemIDs = Self.uniqueSorted(itemIDs)
        self.variableIDs = Self.uniqueSorted(variableIDs)
        self.movementTypes = Self.uniqueSorted(movementTypes)
        self.trainerTypes = Self.uniqueSorted(trainerTypes)
        self.facingDirections = Self.uniqueSorted(facingDirections)
        self.flags = Self.uniqueSorted(flags)
        self.speciesIDs = Self.uniqueSorted(speciesIDs)
    }

    public static func load(root: URL, fileManager: FileManager = .default) -> MapEventOptionsStaticCatalog {
        MapEventOptionsStaticCatalog(
            itemIDs: constants(root: root, path: "include/constants/items.h", prefixes: ["ITEM_"], fileManager: fileManager),
            variableIDs: constants(root: root, path: "include/constants/vars.h", prefixes: ["VAR_"], fileManager: fileManager),
            movementTypes: constants(root: root, path: "include/constants/event_object_movement.h", prefixes: ["MOVEMENT_TYPE_"], fileManager: fileManager),
            trainerTypes: constants(root: root, path: "include/constants/trainer_types.h", prefixes: ["TRAINER_TYPE_"], fileManager: fileManager),
            facingDirections: constants(root: root, path: "include/constants/event_bg.h", prefixes: ["BG_EVENT_PLAYER_FACING_"], fileManager: fileManager),
            flags: constants(root: root, path: "include/constants/flags.h", prefixes: ["FLAG_"], exactSymbols: ["FLAG_NONE"], fileManager: fileManager),
            speciesIDs: constants(root: root, path: "include/constants/species.h", prefixes: ["SPECIES_"], fileManager: fileManager)
        )
    }

    public func makeOptions(
        catalog: ProjectMapCatalog,
        scriptIndex: MapScriptIndex,
        objectSprites: [MapEventSpriteDescriptor]
    ) -> MapEventOptionsCatalog {
        MapEventOptionsCatalog(
            mapIDs: catalog.maps.map { $0.id },
            mapWarpCounts: Dictionary(uniqueKeysWithValues: catalog.maps.map { ($0.id, $0.eventCounts.warpEvents) }),
            scriptLabels: scriptIndex.labels.map { $0.label },
            objectGraphicsIDs: objectSprites.map { $0.graphicsID },
            objectSprites: objectSprites,
            itemIDs: itemIDs,
            variableIDs: variableIDs,
            movementTypes: movementTypes,
            trainerTypes: trainerTypes,
            facingDirections: facingDirections,
            flags: flags,
            speciesIDs: speciesIDs
        )
    }

    private static func constants(
        root: URL,
        path: String,
        prefixes: [String],
        exactSymbols: [String] = [],
        fileManager: FileManager
    ) -> [String] {
        let url = root.appendingPathComponent(path)
        guard fileManager.fileExists(atPath: url.path),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else {
            return exactSymbols
        }

        var symbols = exactSymbols
        let pattern = #"(?m)^\s*#define\s+([A-Za-z0-9_]+)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return uniqueSorted(symbols)
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        for match in regex.matches(in: text, range: range) {
            guard let symbolRange = Range(match.range(at: 1), in: text) else { continue }
            let symbol = String(text[symbolRange])
            if prefixes.contains(where: { symbol.hasPrefix($0) }) || exactSymbols.contains(symbol) {
                symbols.append(symbol)
            }
        }
        return uniqueSorted(symbols)
    }

    private static func uniqueSorted(_ values: [String]) -> [String] {
        Array(Set(values.filter { !$0.isEmpty })).sorted()
    }
}
