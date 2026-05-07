import Foundation
import PokemonHackCore

typealias MetatileRenderLayer = GameBackgroundLayer

enum MapLayerPreset: String, CaseIterable, Identifiable {
    case gameComposite
    case bottom
    case middle
    case top
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gameComposite:
            return "Game Composite"
        case .bottom:
            return "Bottom"
        case .middle:
            return "Middle"
        case .top:
            return "Top"
        case .custom:
            return "Custom"
        }
    }

    var systemImage: String {
        switch self {
        case .gameComposite:
            return "square.stack.3d.up"
        case .bottom:
            return "square.stack.3d.down.right"
        case .middle:
            return "square.stack.3d.up"
        case .top:
            return "square.stack.3d.up.fill"
        case .custom:
            return "slider.horizontal.3"
        }
    }

    var renderLayer: MetatileRenderLayer? {
        switch self {
        case .bottom:
            return .bottom
        case .middle:
            return .middle
        case .top:
            return .top
        case .gameComposite, .custom:
            return nil
        }
    }
}

enum MapEditorLayer: String, CaseIterable, Identifiable, Hashable {
    case metatileBottom
    case metatileMiddle
    case metatileTop
    case collision
    case objects
    case warps
    case coordEvents
    case bgEvents
    case connections
    case border
    case playerView
    case grid

    var id: String { rawValue }

    var title: String {
        switch self {
        case .metatileBottom: "Bottom"
        case .metatileMiddle: "Middle"
        case .metatileTop: "Top"
        case .collision: "Collision"
        case .objects: "Objects"
        case .warps: "Warps"
        case .coordEvents: "Coord"
        case .bgEvents: "BG"
        case .connections: "Connections"
        case .border: "Border"
        case .playerView: "Player View"
        case .grid: "Grid"
        }
    }

    var systemImage: String {
        switch self {
        case .metatileBottom: "square.stack.3d.down.right"
        case .metatileMiddle: "square.stack.3d.up"
        case .metatileTop: "square.stack.3d.up.fill"
        case .collision: "figure.walk.diamond"
        case .objects: "person.crop.circle"
        case .warps: "arrow.triangle.swap"
        case .coordEvents: "scope"
        case .bgEvents: "signpost.right"
        case .connections: "point.3.connected.trianglepath.dotted"
        case .border: "square.dashed"
        case .playerView: "rectangle.inset.filled"
        case .grid: "grid"
        }
    }

    var defaultState: MapLayerSettings {
        switch self {
        case .metatileBottom, .metatileMiddle, .metatileTop:
            MapLayerSettings(isVisible: true, opacity: 1)
        case .collision:
            MapLayerSettings(isVisible: false, opacity: 0.55)
        case .connections, .border:
            MapLayerSettings(isVisible: true, opacity: 1)
        case .playerView:
            MapLayerSettings(isVisible: true, opacity: 0.85)
        case .objects, .warps, .coordEvents, .bgEvents:
            MapLayerSettings(isVisible: true, opacity: 1)
        case .grid:
            MapLayerSettings(isVisible: false, opacity: 1)
        }
    }

    var metatileRenderLayer: MetatileRenderLayer? {
        switch self {
        case .metatileBottom: .bottom
        case .metatileMiddle: .middle
        case .metatileTop: .top
        default: nil
        }
    }

    static func layer(for renderLayer: MetatileRenderLayer) -> MapEditorLayer {
        switch renderLayer {
        case .bottom: .metatileBottom
        case .middle: .metatileMiddle
        case .top: .metatileTop
        }
    }
}

struct MapLayerSettings: Equatable {
    var isVisible: Bool
    var opacity: Double
}

struct MapOverlaySettings: Equatable {
    var layerStates: [MapEditorLayer: MapLayerSettings]
    var soloLayer: MapEditorLayer?
    var preset: MapLayerPreset

    init(
        layerStates: [MapEditorLayer: MapLayerSettings]? = nil,
        soloLayer: MapEditorLayer? = nil,
        preset: MapLayerPreset = .gameComposite
    ) {
        self.layerStates = layerStates ?? Dictionary(
            uniqueKeysWithValues: MapEditorLayer.allCases.map { ($0, $0.defaultState) }
        )
        self.soloLayer = soloLayer
        self.preset = preset
    }

    var visibleMetatileLayers: Set<MetatileRenderLayer> {
        Set(
            MetatileRenderLayer.allCases.filter { renderLayer in
                isLayerVisible(MapEditorLayer.layer(for: renderLayer))
            }
        )
    }

    var metatileLayerOpacities: [MetatileRenderLayer: Double] {
        Dictionary(
            uniqueKeysWithValues: MetatileRenderLayer.allCases.map { renderLayer in
                (renderLayer, layerOpacity(MapEditorLayer.layer(for: renderLayer)))
            }
        )
    }

    var hasVisibleMetatileLayer: Bool {
        !visibleMetatileLayers.isEmpty
    }

    var showGrid: Bool {
        get { isLayerVisible(.grid) }
        set { setLayerVisible(.grid, newValue) }
    }

    var showCollision: Bool {
        get { isLayerVisible(.collision) }
        set { setLayerVisible(.collision, newValue) }
    }

    var showObjects: Bool {
        get { isLayerVisible(.objects) }
        set { setLayerVisible(.objects, newValue) }
    }

    var showWarps: Bool {
        get { isLayerVisible(.warps) }
        set { setLayerVisible(.warps, newValue) }
    }

    var showCoordEvents: Bool {
        get { isLayerVisible(.coordEvents) }
        set { setLayerVisible(.coordEvents, newValue) }
    }

    var showBGEvents: Bool {
        get { isLayerVisible(.bgEvents) }
        set { setLayerVisible(.bgEvents, newValue) }
    }

    var showConnections: Bool {
        get { isLayerVisible(.connections) }
        set { setLayerVisible(.connections, newValue) }
    }

    var showBorder: Bool {
        get { isLayerVisible(.border) }
        set { setLayerVisible(.border, newValue) }
    }

    var showPlayerView: Bool {
        get { isLayerVisible(.playerView) }
        set { setLayerVisible(.playerView, newValue) }
    }

    func state(for layer: MapEditorLayer) -> MapLayerSettings {
        layerStates[layer] ?? layer.defaultState
    }

    func isLayerVisible(_ layer: MapEditorLayer) -> Bool {
        guard state(for: layer).isVisible else { return false }
        if let soloLayer {
            return soloLayer == layer
        }
        return true
    }

    func layerOpacity(_ layer: MapEditorLayer) -> Double {
        guard isLayerVisible(layer) else { return 0 }
        return min(max(state(for: layer).opacity, 0), 1)
    }

    func previewingOnly(renderLayer: MetatileRenderLayer) -> MapOverlaySettings {
        var copy = self
        copy.soloLayer = nil
        copy.preset = MapLayerPreset.allCases.first { $0.renderLayer == renderLayer } ?? .custom
        for layer in [MapEditorLayer.metatileBottom, .metatileMiddle, .metatileTop] {
            var next = copy.state(for: layer)
            next.isVisible = layer.metatileRenderLayer == renderLayer
            next.opacity = 1
            copy.layerStates[layer] = next
        }
        for layer in [MapEditorLayer.collision, .objects, .warps, .coordEvents, .bgEvents, .connections, .border, .playerView, .grid] {
            var next = copy.state(for: layer)
            next.isVisible = false
            copy.layerStates[layer] = next
        }
        return copy
    }

    mutating func applyPreset(_ preset: MapLayerPreset) {
        self.preset = preset
        soloLayer = nil
        switch preset {
        case .gameComposite:
            for layer in [MapEditorLayer.metatileBottom, .metatileMiddle, .metatileTop] {
                var next = state(for: layer)
                next.isVisible = true
                next.opacity = 1
                layerStates[layer] = next
            }
        case .bottom, .middle, .top:
            guard let renderLayer = preset.renderLayer else { return }
            for layer in [MapEditorLayer.metatileBottom, .metatileMiddle, .metatileTop] {
                var next = state(for: layer)
                next.isVisible = layer.metatileRenderLayer == renderLayer
                next.opacity = 1
                layerStates[layer] = next
            }
        case .custom:
            break
        }
    }

    mutating func setLayerVisible(_ layer: MapEditorLayer, _ isVisible: Bool) {
        var next = state(for: layer)
        next.isVisible = isVisible
        layerStates[layer] = next
        preset = .custom
        if soloLayer == layer, !isVisible {
            soloLayer = nil
        }
    }

    mutating func setLayerOpacity(_ layer: MapEditorLayer, _ opacity: Double) {
        var next = state(for: layer)
        next.opacity = min(max(opacity, 0), 1)
        layerStates[layer] = next
        preset = .custom
    }

    mutating func toggleSolo(_ layer: MapEditorLayer) {
        preset = .custom
        if soloLayer == layer {
            soloLayer = nil
        } else {
            setLayerVisible(layer, true)
            soloLayer = layer
        }
    }

    mutating func reset() {
        self = MapOverlaySettings()
    }
}
