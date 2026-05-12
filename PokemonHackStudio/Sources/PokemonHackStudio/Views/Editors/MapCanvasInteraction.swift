import AppKit
import PokemonHackCore

struct MapCanvasCoordinate: Equatable, Hashable, Identifiable, CustomStringConvertible {
    let x: Int
    let y: Int

    var id: String { "\(x),\(y)" }
    var description: String { "\(x), \(y)" }
}

struct MapCanvasSize: Equatable {
    let originX: Int
    let originY: Int
    let width: Int
    let height: Int

    init(originX: Int = 0, originY: Int = 0, width: Int, height: Int) {
        self.originX = originX
        self.originY = originY
        self.width = width
        self.height = height
    }

    func contains(_ coordinate: MapCanvasCoordinate) -> Bool {
        coordinate.x >= originX
            && coordinate.y >= originY
            && coordinate.x < originX + width
            && coordinate.y < originY + height
    }
}

struct MapCanvasViewport: Equatable {
    let originX: CGFloat
    let originY: CGFloat
    let width: CGFloat
    let height: CGFloat
    let mapWidth: CGFloat
    let mapHeight: CGFloat

    static let zero = MapCanvasViewport(originX: 0, originY: 0, width: 0, height: 0, mapWidth: 0, mapHeight: 0)

    var maxX: CGFloat { originX + width }
    var maxY: CGFloat { originY + height }
    var isEmpty: Bool { width <= 0 || height <= 0 || mapWidth <= 0 || mapHeight <= 0 }
}

enum MapViewportGeometry {
    static let defaultZoom = 2.0
    static let unitZoom = 1.0
    static let minimumManualZoom = 0.15
    static let minimumEditableZoom = 0.75
    static let maximumZoom = 4.0

    static func fitZoom(
        mapWidth: Int,
        mapHeight: Int,
        viewportSize: CGSize,
        padding: CGFloat = 28,
        minZoom: Double = minimumManualZoom,
        maxZoom: Double = maximumZoom
    ) -> Double {
        guard mapWidth > 0, mapHeight > 0, viewportSize.width > 0, viewportSize.height > 0 else {
            return unitZoom
        }
        let availableWidth = max(viewportSize.width - padding * 2, 1)
        let availableHeight = max(viewportSize.height - padding * 2, 1)
        let widthZoom = Double(availableWidth / (CGFloat(mapWidth) * 16))
        let heightZoom = Double(availableHeight / (CGFloat(mapHeight) * 16))
        return min(max(min(widthZoom, heightZoom), minZoom), maxZoom)
    }
}

struct MapCanvasRectanglePreview: Equatable, Identifiable {
    let anchor: MapCanvasCoordinate
    let focus: MapCanvasCoordinate

    var id: String { "\(minX),\(minY),\(width),\(height)" }
    var minX: Int { min(anchor.x, focus.x) }
    var maxX: Int { max(anchor.x, focus.x) }
    var minY: Int { min(anchor.y, focus.y) }
    var maxY: Int { max(anchor.y, focus.y) }
    var width: Int { maxX - minX + 1 }
    var height: Int { maxY - minY + 1 }
    var cellCount: Int { width * height }

    func contains(_ coordinate: MapCanvasCoordinate) -> Bool {
        coordinate.x >= minX
            && coordinate.x <= maxX
            && coordinate.y >= minY
            && coordinate.y <= maxY
    }
}

struct MapCanvasEventDragPreview: Equatable {
    let eventID: String
    let origin: MapCanvasCoordinate?
    let focus: MapCanvasCoordinate
}

struct MapCanvasHitResult: Equatable {
    let sceneCoordinate: MapCanvasCoordinate
    let coordinate: MapCanvasCoordinate
    let target: MapBlockTarget?
    let rawValue: UInt16?
    let event: MapEventDescriptor?
    let events: [MapEventDescriptor]
    let placement: MapScenePlacement?

    var eventID: String? { event?.id }
    var isEditable: Bool { target != nil }
}

struct MapCanvasHoverStatus: Equatable, Identifiable {
    let sceneCoordinate: MapCanvasCoordinate
    let coordinate: MapCanvasCoordinate
    let target: MapBlockTarget?
    let rawValue: UInt16?
    let metatileID: Int?
    let eventID: String?
    let eventKind: MapEventKind?
    let eventStackCount: Int
    let placementRole: MapScenePlacementRole?

    var id: String { sceneCoordinate.id }

    var statusText: String {
        var parts = ["Cell \(coordinate.x), \(coordinate.y)"]
        if sceneCoordinate != coordinate {
            parts.append("Scene \(sceneCoordinate.x), \(sceneCoordinate.y)")
        }
        if target == .border {
            parts.append("Border")
        } else if placementRole == .connection {
            parts.append("Connection")
        }
        if let metatileID {
            parts.append("Metatile \(String(format: "%03X", metatileID))")
        }
        if let eventKind {
            parts.append("\(eventKind.rawValue.capitalized) event")
        }
        if eventStackCount > 1 {
            parts.append("\(eventStackCount) events")
        }
        return parts.joined(separator: " | ")
    }

    init(hit: MapCanvasHitResult) {
        sceneCoordinate = hit.sceneCoordinate
        coordinate = hit.coordinate
        target = hit.target
        rawValue = hit.rawValue
        metatileID = hit.rawValue.map { Int($0 & 0x03ff) }
        eventID = hit.event?.id
        eventKind = hit.event?.kind
        eventStackCount = hit.events.count
        placementRole = hit.placement?.role
    }
}

struct MapCanvasEventRenderIndex: Equatable {
    static let empty = MapCanvasEventRenderIndex(events: [], overlays: MapOverlaySettings(), document: nil, selectedEventID: nil)

    let visibleEvents: [MapEventDescriptor]

    private let eventsByCoordinate: [MapCanvasCoordinate: [MapEventDescriptor]]
    private let eventsByID: [String: MapEventDescriptor]
    private let stackCountsByCoordinate: [MapCanvasCoordinate: Int]
    private let badgesByEventID: [String: String]

    init(
        events: [MapEventDescriptor],
        overlays: MapOverlaySettings,
        document: MapVisualDocument?,
        selectedEventID: String?
    ) {
        let visibleEvents = events.filter { MapCanvasHitTester.shouldShow($0.kind, overlays: overlays) }
        let eventsByCoordinate = Dictionary(grouping: visibleEvents.compactMap { event -> (MapCanvasCoordinate, MapEventDescriptor)? in
            guard let x = event.x, let y = event.y else { return nil }
            return (MapCanvasCoordinate(x: x, y: y), event)
        }) { $0.0 }
            .mapValues { pairs in pairs.map(\.1) }
        let stackCountsByCoordinate = eventsByCoordinate.mapValues(\.count)

        self.visibleEvents = visibleEvents
        self.eventsByCoordinate = eventsByCoordinate
        eventsByID = Dictionary(visibleEvents.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
        self.stackCountsByCoordinate = stackCountsByCoordinate
        badgesByEventID = Dictionary(
            visibleEvents.compactMap { event in
                guard let badge = Self.badge(for: event, document: document, selectedEventID: selectedEventID, stackCount: Self.stackCount(for: event, in: stackCountsByCoordinate)) else {
                    return nil
                }
                return (event.id, badge)
            },
            uniquingKeysWith: { _, last in last }
        )
    }

    func events(at coordinate: MapCanvasCoordinate, target: MapBlockTarget?) -> [MapEventDescriptor] {
        guard target == .layout else { return [] }
        return eventsByCoordinate[coordinate] ?? []
    }

    func event(id: String?) -> MapEventDescriptor? {
        guard let id else { return nil }
        return eventsByID[id]
    }

    func stackCount(for event: MapEventDescriptor) -> Int {
        Self.stackCount(for: event, in: stackCountsByCoordinate)
    }

    func badge(for event: MapEventDescriptor) -> String? {
        badgesByEventID[event.id]
    }

    private static func stackCount(for event: MapEventDescriptor, in counts: [MapCanvasCoordinate: Int]) -> Int {
        guard let x = event.x, let y = event.y else { return 1 }
        return counts[MapCanvasCoordinate(x: x, y: y)] ?? 1
    }

    private static func badge(
        for event: MapEventDescriptor,
        document: MapVisualDocument?,
        selectedEventID: String?,
        stackCount: Int
    ) -> String? {
        var parts: [String] = []
        if event.id == selectedEventID, let scriptState = scriptResolutionBadge(for: event, document: document) {
            parts.append(scriptState)
        }
        if stackCount > 1 {
            parts.append("x\(stackCount)")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    private static func scriptResolutionBadge(for event: MapEventDescriptor, document: MapVisualDocument?) -> String? {
        guard let scriptLabel = event.scriptLabel, let resolution = document?.scriptIndex?.resolution(for: scriptLabel) else { return nil }
        switch resolution.state {
        case .resolved:
            return resolution.span?.sourceRole == .shared ? "shared" : "local"
        case .noScript:
            return nil
        case .missingLabel:
            return "missing"
        case .duplicateLabel:
            return "dup"
        case .generatedPath:
            return "gen"
        case .externalLabel:
            return "ext"
        }
    }
}

struct MapCanvasHitTester {
    let size: MapCanvasSize
    let tileSize: CGFloat
    let document: MapVisualDocument
    let rawValues: [UInt16]
    let borderRawValues: [UInt16]
    let overlays: MapOverlaySettings
    let eventIndex: MapCanvasEventRenderIndex

    init(
        size: MapCanvasSize,
        tileSize: CGFloat,
        document: MapVisualDocument,
        rawValues: [UInt16],
        borderRawValues: [UInt16],
        events: [MapEventDescriptor],
        overlays: MapOverlaySettings
    ) {
        self.init(
            size: size,
            tileSize: tileSize,
            document: document,
            rawValues: rawValues,
            borderRawValues: borderRawValues,
            overlays: overlays,
            eventIndex: MapCanvasEventRenderIndex(
                events: events,
                overlays: overlays,
                document: document,
                selectedEventID: nil
            )
        )
    }

    init(
        size: MapCanvasSize,
        tileSize: CGFloat,
        document: MapVisualDocument,
        rawValues: [UInt16],
        borderRawValues: [UInt16],
        overlays: MapOverlaySettings,
        eventIndex: MapCanvasEventRenderIndex
    ) {
        self.size = size
        self.tileSize = tileSize
        self.document = document
        self.rawValues = rawValues
        self.borderRawValues = borderRawValues
        self.overlays = overlays
        self.eventIndex = eventIndex
    }

    func hit(at point: NSPoint) -> MapCanvasHitResult? {
        guard let sceneCoordinate = sceneCoordinate(at: point),
              let resolved = resolvedCoordinate(sceneCoordinate)
        else { return nil }
        let events = events(at: resolved.coordinate, target: resolved.target)
        return MapCanvasHitResult(
            sceneCoordinate: sceneCoordinate,
            coordinate: resolved.coordinate,
            target: resolved.target,
            rawValue: resolved.rawValue,
            event: events.last,
            events: events,
            placement: resolved.placement
        )
    }

    func coordinate(at point: NSPoint) -> MapCanvasCoordinate? {
        guard let hit = hit(at: point), hit.isEditable else { return nil }
        return hit.coordinate
    }

    func sceneCoordinate(at point: NSPoint) -> MapCanvasCoordinate? {
        let coordinate = MapCanvasCoordinate(
            x: Int(floor(point.x / tileSize)) + size.originX,
            y: Int(floor(point.y / tileSize)) + size.originY
        )
        return size.contains(coordinate) ? coordinate : nil
    }

    func rawValue(at coordinate: MapCanvasCoordinate) -> UInt16? {
        let index = coordinate.y * size.width + coordinate.x
        guard rawValues.indices.contains(index) else { return nil }
        return rawValues[index]
    }

    func event(at coordinate: MapCanvasCoordinate, target: MapBlockTarget?) -> MapEventDescriptor? {
        events(at: coordinate, target: target).last
    }

    func events(at coordinate: MapCanvasCoordinate, target: MapBlockTarget?) -> [MapEventDescriptor] {
        eventIndex.events(at: coordinate, target: target)
    }

    private func resolvedCoordinate(
        _ sceneCoordinate: MapCanvasCoordinate
    ) -> (coordinate: MapCanvasCoordinate, target: MapBlockTarget?, rawValue: UInt16?, placement: MapScenePlacement?)? {
        if sceneCoordinate.x >= 0,
           sceneCoordinate.y >= 0,
           sceneCoordinate.x < document.blockdata.width,
           sceneCoordinate.y < document.blockdata.height {
            return (
                coordinate: sceneCoordinate,
                target: .layout,
                rawValue: rawValue(at: sceneCoordinate),
                placement: document.scene.layoutPlacement
            )
        }

        if overlays.showConnections,
           let connection = document.scene.placement(containingSceneX: sceneCoordinate.x, sceneY: sceneCoordinate.y),
           connection.role == .connection {
            let local = MapCanvasCoordinate(
                x: sceneCoordinate.x - connection.originX,
                y: sceneCoordinate.y - connection.originY
            )
            return (
                coordinate: local,
                target: nil,
                rawValue: connection.rawValue(sceneX: sceneCoordinate.x, sceneY: sceneCoordinate.y),
                placement: connection
            )
        }

        guard overlays.showBorder,
              let border = document.border,
              border.width > 0,
              border.height > 0,
              !borderRawValues.isEmpty
        else {
            return nil
        }
        let borderX = positiveModulo(sceneCoordinate.x, border.width)
        let borderY = positiveModulo(sceneCoordinate.y, border.height)
        let local = MapCanvasCoordinate(x: borderX, y: borderY)
        let index = borderY * border.width + borderX
        return (
            coordinate: local,
            target: .border,
            rawValue: borderRawValues.indices.contains(index) ? borderRawValues[index] : nil,
            placement: nil
        )
    }

    private func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
        guard divisor > 0 else { return 0 }
        let remainder = value % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }

    static func shouldShow(_ kind: MapEventKind, overlays: MapOverlaySettings) -> Bool {
        overlays.isLayerVisible(layer(for: kind))
    }

    static func layer(for kind: MapEventKind) -> MapEditorLayer {
        switch kind {
        case .object:
            .objects
        case .warp:
            .warps
        case .coord:
            .coordEvents
        case .bg:
            .bgEvents
        case .connection:
            .connections
        }
    }
}
