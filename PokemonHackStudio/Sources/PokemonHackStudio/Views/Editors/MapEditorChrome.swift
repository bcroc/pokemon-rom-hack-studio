import SwiftUI

struct MapEditorToolbar: View {
    @ObservedObject var session: MapEditorSession
    let layoutMode: MapEditorLayoutMode
    let selectedMapTitle: String
    let visualStatus: String
    let hoverStatus: MapCanvasHoverStatus?
    let zoom: Binding<Double>
    let isReadOnlyZoom: Bool
    let fitMapToView: Bool
    @Binding var showPalette: Bool
    @Binding var showCompactMapBrowser: Bool
    @Binding var showCompactPalette: Bool
    @Binding var showCompactInspector: Bool
    let mapBrowserPopover: AnyView
    let palettePopover: AnyView
    let inspectorPopover: AnyView
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onZoomOut: () -> Void
    let onUnitZoom: () -> Void
    let onZoomIn: () -> Void
    let onFitMap: () -> Void
    let onResetView: () -> Void

    var body: some View {
        HStack(spacing: 9) {
            if layoutMode.isCompact {
                compactMapBrowserButton
                compactToolMenu
            } else {
                MapEditorGroupedToolPicker(session: session)
            }

            Divider()

            editHistoryControls

            Divider()

            surfaceControls

            Divider()

            zoomControls

            Spacer(minLength: 8)

            if !layoutMode.isCompact {
                toolbarStatus
            }
        }
        .frame(height: 34)
    }

    private var compactMapBrowserButton: some View {
        Button {
            showCompactMapBrowser.toggle()
        } label: {
            Label(selectedMapTitle, systemImage: "list.bullet")
                .lineLimit(1)
        }
        .frame(maxWidth: 176)
        .help("Browse maps")
        .popover(isPresented: $showCompactMapBrowser, arrowEdge: .bottom) {
            mapBrowserPopover
        }
    }

    private var compactToolMenu: some View {
        Menu {
            ForEach(MapEditorToolGroup.allCases) { group in
                Section(group.title) {
                    ForEach(MapEditorTool.tools(in: group)) { tool in
                        Button {
                            session.selectedMapTool = tool
                        } label: {
                            Label(tool.title, systemImage: tool.systemImage)
                        }
                    }
                }
            }
        } label: {
            Label(session.selectedMapTool.shortTitle, systemImage: session.selectedMapTool.systemImage)
                .lineLimit(1)
        }
        .frame(maxWidth: 124)
        .help("Select map editor tool")
    }

    private var editHistoryControls: some View {
        HStack(spacing: 4) {
            Button("Undo", systemImage: "arrow.uturn.backward") {
                onUndo()
            }
            .labelStyle(.iconOnly)
            .help("Undo last staged map edit")
            .disabled(session.mapEditOperations.isEmpty)

            Button("Redo", systemImage: "arrow.uturn.forward") {
                onRedo()
            }
            .labelStyle(.iconOnly)
            .help("Redo staged map edit")
            .disabled(session.undoneMapEditOperations.isEmpty)
        }
    }

    private var surfaceControls: some View {
        HStack(spacing: 4) {
            Button(showPalette ? "Hide Palette" : "Show Palette", systemImage: "square.grid.3x3") {
                if layoutMode.isCompact {
                    showCompactPalette.toggle()
                } else {
                    showPalette.toggle()
                }
            }
            .labelStyle(.iconOnly)
            .help(layoutMode.isCompact ? "Open metatile palette" : (showPalette ? "Hide metatile palette" : "Show metatile palette"))
            .popover(isPresented: $showCompactPalette, arrowEdge: .bottom) {
                palettePopover
            }

            if layoutMode.isCompact {
                Button("Inspector", systemImage: "sidebar.right") {
                    showCompactInspector.toggle()
                }
                .labelStyle(.iconOnly)
                .accessibilityLabel("Open map workbench inspector")
                .help("Open map inspector")
                .popover(isPresented: $showCompactInspector, arrowEdge: .bottom) {
                    inspectorPopover
                }
            }
        }
    }

    private var zoomControls: some View {
        HStack(spacing: 5) {
            Button("Zoom Out", systemImage: "minus.magnifyingglass") {
                onZoomOut()
            }
            .labelStyle(.iconOnly)
            .help("Zoom out")

            Button("100%") {
                onUnitZoom()
            }
            .font(.caption.monospacedDigit())
            .help("Show map at 100%")

            Button("Zoom In", systemImage: "plus.magnifyingglass") {
                onZoomIn()
            }
            .labelStyle(.iconOnly)
            .help("Zoom in")

            Button("Fit", systemImage: fitMapToView ? "arrow.up.left.and.down.right.magnifyingglass" : "arrow.up.left.and.down.right") {
                onFitMap()
            }
            .labelStyle(.iconOnly)
            .help("Fit the whole map in the viewport")

            Button("Reset View", systemImage: "arrow.counterclockwise") {
                onResetView()
            }
            .labelStyle(.iconOnly)
            .help("Reset zoom and pan")

            Slider(value: zoom, in: MapViewportGeometry.minimumManualZoom...MapViewportGeometry.maximumZoom) {
                Text("Zoom")
            }
            .frame(width: layoutMode.isCompact ? 76 : 116)

            Text("\(Int((zoom.wrappedValue * 100).rounded()))%")
                .font(.caption.monospacedDigit())
                .foregroundStyle(isReadOnlyZoom ? Color.orange : Color.secondary)
                .frame(width: 44, alignment: .trailing)
        }
    }

    private var toolbarStatus: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(hoverStatus?.statusText ?? visualStatus)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(session.selectedMapTool.title)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: 260, alignment: .trailing)
    }
}

struct MapEditorCanvasStatusHUD: View {
    @ObservedObject var session: MapEditorSession
    let hoverStatus: MapCanvasHoverStatus?
    let zoom: Double
    let isReadOnlyZoom: Bool

    var body: some View {
        HStack(spacing: 8) {
            Label(session.selectedMapTool.shortTitle, systemImage: session.selectedMapTool.systemImage)
                .font(.caption.weight(.semibold))

            Text(hoverStatus?.statusText ?? "Move over the map for coordinates")
                .font(.caption.monospacedDigit())
                .lineLimit(1)

            if let rawValue = session.selectedBrushRawValue {
                Text("Brush \(String(format: "%03X", Int(rawValue & 0x03ff)))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text("\(Int((zoom * 100).rounded()))%")
                .font(.caption.monospacedDigit())
                .foregroundStyle(isReadOnlyZoom ? Color.orange : Color.secondary)

            if isReadOnlyZoom {
                Text("Read-only")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
    }
}

struct MapEditorDirtyBanner: View {
    let operationCount: Int
    let onPreview: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Label("\(operationCount) staged edit\(operationCount == 1 ? "" : "s")", systemImage: "pencil.and.outline")
                .font(.caption.weight(.semibold))
            Text("Preview before applying source writes, or discard to reload from disk.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
            Button("Preview", systemImage: "doc.text.magnifyingglass") {
                onPreview()
            }
            Button("Discard", systemImage: "arrow.counterclockwise") {
                onDiscard()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color(nsColor: .controlAccentColor).opacity(0.12))
    }
}

private struct MapEditorGroupedToolPicker: View {
    @ObservedObject var session: MapEditorSession

    var body: some View {
        HStack(spacing: 8) {
            ForEach(MapEditorToolGroup.allCases) { group in
                HStack(spacing: 4) {
                    Text(group.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 2) {
                        ForEach(MapEditorTool.tools(in: group)) { tool in
                            toolButton(tool)
                        }
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("\(group.title) tools")
            }
        }
    }

    private func toolButton(_ tool: MapEditorTool) -> some View {
        Button {
            session.selectedMapTool = tool
        } label: {
            Image(systemName: tool.systemImage)
                .frame(width: 26, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(session.selectedMapTool == tool ? Color.accentColor : Color.primary)
        .background(
            session.selectedMapTool == tool ? Color.accentColor.opacity(0.16) : Color.clear,
            in: RoundedRectangle(cornerRadius: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(session.selectedMapTool == tool ? Color.accentColor.opacity(0.35) : Color.clear, lineWidth: 1)
        )
        .accessibilityLabel(tool.accessibilityLabel)
        .accessibilityValue(session.selectedMapTool == tool ? "Selected" : "Not selected")
        .help(tool.helpText)
    }
}
