import PokemonHackCore
import SwiftUI

struct MapLayerInspectorView: View {
    let document: MapVisualDocument
    @ObservedObject var session: MapEditorSession
    let viewport: MapCanvasViewport
    let onSelectViewportCenter: (CGFloat, CGFloat) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            overview
            layerViewPresets
            layerStackControls
        }
    }

    private var overview: some View {
        EditorSection(title: "Overview") {
            MapOverviewView(
                document: document,
                rawValues: session.stagedMapBlockdataValues,
                borderRawValues: session.stagedMapBorderValues,
                events: session.stagedMapEvents,
                overlays: session.mapOverlaySettings,
                viewport: viewport,
                onSelectViewportCenter: onSelectViewportCenter
            )
            .frame(height: 156)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .help("Click to pan the main canvas")
        }
    }

    private var layerViewPresets: some View {
        EditorSection(title: "Layer Views") {
            VStack(alignment: .leading, spacing: 10) {
                Picker("Layer View", selection: presetBinding) {
                    ForEach(MapLayerPreset.allCases) { preset in
                        Label(preset.title, systemImage: preset.systemImage)
                            .tag(preset)
                    }
                }
                .pickerStyle(.segmented)
                .help("Switch between the game composite and individual background layers")

                MapBackgroundLayerPreviewStrip(
                    document: document,
                    rawValues: session.stagedMapBlockdataValues,
                    borderRawValues: session.stagedMapBorderValues,
                    events: session.stagedMapEvents,
                    overlays: session.mapOverlaySettings,
                    viewport: viewport
                ) { layer in
                    session.toggleLayerSolo(MapEditorLayer.layer(for: layer))
                }
            }
        }
    }

    private var layerStackControls: some View {
        EditorSection(title: "Layers") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(layerGroups) { group in
                    VStack(alignment: .leading, spacing: 7) {
                        Text(group.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(group.layers) { layer in
                            MapLayerControlRow(
                                layer: layer,
                                settings: session.mapOverlaySettings.state(for: layer),
                                isEffectivelyVisible: session.mapOverlaySettings.isLayerVisible(layer),
                                isSolo: session.mapOverlaySettings.soloLayer == layer,
                                onVisibilityChanged: { isVisible in
                                    session.setLayerVisible(layer, isVisible: isVisible)
                                },
                                onOpacityChanged: { opacity in
                                    session.setLayerOpacity(layer, opacity: opacity)
                                },
                                onSolo: {
                                    session.toggleLayerSolo(layer)
                                }
                            )
                        }
                    }
                }

                HStack {
                    Button("Reset Layers", systemImage: "arrow.counterclockwise") {
                        session.resetLayerSettings()
                    }
                    Spacer()
                    if let soloLayer = session.mapOverlaySettings.soloLayer {
                        Text("Solo: \(soloLayer.title)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var presetBinding: Binding<MapLayerPreset> {
        Binding {
            session.mapOverlaySettings.preset
        } set: { preset in
            session.applyLayerPreset(preset)
        }
    }

    private var layerGroups: [MapLayerControlGroup] {
        [
            MapLayerControlGroup(title: "Game Art", layers: [.metatileBottom, .metatileMiddle, .metatileTop]),
            MapLayerControlGroup(title: "Scene Context", layers: [.connections, .border, .playerView]),
            MapLayerControlGroup(title: "Events", layers: [.objects, .warps, .coordEvents, .bgEvents]),
            MapLayerControlGroup(title: "Diagnostics", layers: [.collision, .grid])
        ]
    }
}

private struct MapLayerControlGroup: Identifiable {
    var id: String { title }

    let title: String
    let layers: [MapEditorLayer]
}

struct MapBackgroundLayerPreviewStrip: View {
    let document: MapVisualDocument
    let rawValues: [UInt16]
    let borderRawValues: [UInt16]
    let events: [MapEventDescriptor]
    let overlays: MapOverlaySettings
    let viewport: MapCanvasViewport
    let onSelectLayer: (MetatileRenderLayer) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(MetatileRenderLayer.allCases) { layer in
                Button {
                    onSelectLayer(layer)
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(layer.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                        MapOverviewView(
                            document: document,
                            rawValues: rawValues,
                            borderRawValues: borderRawValues,
                            events: events,
                            overlays: overlays.previewingOnly(renderLayer: layer),
                            viewport: viewport,
                            onSelectViewportCenter: { _, _ in }
                        )
                        .frame(height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                }
                .buttonStyle(.plain)
                .help("Solo \(layer.displayName) background layer")
            }
        }
    }
}

struct MapSelectionLayerDetails: View {
    let document: MapVisualDocument
    let rawValue: UInt16

    private var attributes: MapBlockAttributes {
        MapBlockAttributes(rawValue: rawValue)
    }

    private var metatile: MetatileDefinition? {
        document.metatiles.first { $0.id == attributes.metatileID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FactGrid(
                facts: [
                    Fact(label: "Raw", value: String(format: "0x%04X", rawValue)),
                    Fact(label: "Metatile", value: String(format: "%03X", attributes.metatileID)),
                    Fact(label: "Collision", value: "\(attributes.collision)"),
                    Fact(label: "Elevation", value: "\(attributes.elevation)"),
                    Fact(label: "Layer Type", value: metatile?.attribute?.layerType.displayName ?? "Unknown")
                ]
            )

            if let metatile {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(metatile.expandedLayerCells()) { cell in
                        HStack(alignment: .top, spacing: 8) {
                            Text(cell.layer.displayName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 54, alignment: .leading)
                            Text(layerEntrySummary(cell))
                                .font(.caption.monospaced())
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }

    private func layerEntrySummary(_ cell: MetatileLayerCell) -> String {
        let entries = cell.tileEntries.enumerated().map { offset, entry -> String in
            guard let entry else { return "\(offset): --" }
            return "\(offset): t\(entry.tileIndex)/p\(entry.palette)"
        }
        return entries.joined(separator: "  ")
    }
}

private struct MapLayerControlRow: View {
    let layer: MapEditorLayer
    let settings: MapLayerSettings
    let isEffectivelyVisible: Bool
    let isSolo: Bool
    let onVisibilityChanged: (Bool) -> Void
    let onOpacityChanged: (Double) -> Void
    let onSolo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Toggle(isOn: visibilityBinding) {
                    Label(layer.title, systemImage: layer.systemImage)
                        .lineLimit(1)
                }
                .toggleStyle(.checkbox)

                Spacer()

                Button("Solo") {
                    onSolo()
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundStyle(isSolo ? Color.accentColor : Color.primary)
                .help("Show only \(layer.title)")
            }

            HStack(spacing: 8) {
                Slider(value: opacityBinding, in: 0...1)
                    .disabled(!settings.isVisible)
                Text("\(Int((settings.opacity * 100).rounded()))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(isEffectivelyVisible ? Color.secondary : Color.secondary.opacity(0.55))
                    .frame(width: 42, alignment: .trailing)
            }
        }
        .opacity(isEffectivelyVisible || isSolo ? 1 : 0.58)
    }

    private var visibilityBinding: Binding<Bool> {
        Binding {
            settings.isVisible
        } set: { value in
            onVisibilityChanged(value)
        }
    }

    private var opacityBinding: Binding<Double> {
        Binding {
            settings.opacity
        } set: { value in
            onOpacityChanged(value)
        }
    }
}
