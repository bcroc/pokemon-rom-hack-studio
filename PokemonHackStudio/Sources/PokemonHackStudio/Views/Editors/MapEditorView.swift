import PokemonHackCore
import SwiftUI

enum MapEditorLayoutMode: Equatable {
    static let compactBreakpoint: CGFloat = 1180

    case wide
    case compact

    init(width: CGFloat) {
        self = width < Self.compactBreakpoint ? .compact : .wide
    }

    var isCompact: Bool {
        self == .compact
    }

    var isWide: Bool {
        self == .wide
    }
}

struct MapEditorView: View {
    @ObservedObject var store: WorkbenchStore
    @ObservedObject private var session: MapEditorSession
    let records: [WorkbenchRecord]
    let catalog: MapCatalogViewState?

    @State private var zoom = 2.0
    @State private var hoverStatus: MapCanvasHoverStatus?
    @State private var fitMapToView = false
    @State private var canvasViewportSize: CGSize = .zero
    @State private var viewportSnapshot = MapCanvasViewport.zero

    init(store: WorkbenchStore, records: [WorkbenchRecord], catalog: MapCatalogViewState?) {
        self.store = store
        _session = ObservedObject(wrappedValue: store.mapEditorSession)
        self.records = records
        self.catalog = catalog
        _zoom = State(initialValue: Self.initialZoom(from: store.userSettings.mapZoomDefault))
        _fitMapToView = State(initialValue: store.userSettings.mapZoomDefault == .fit)
    }

    var body: some View {
        if let catalog {
            GeometryReader { proxy in
                visualEditor(catalog, layoutMode: layoutMode(width: proxy.size.width))
            }
        } else {
            fixtureList
        }
    }

    private static func initialZoom(from defaultZoom: WorkbenchMapZoomDefault) -> Double {
        switch defaultZoom {
        case .fit:
            MapViewportGeometry.defaultZoom
        case .oneHundred:
            1.0
        case .twoHundred:
            2.0
        }
    }

    private func layoutMode(width: CGFloat) -> MapEditorLayoutMode {
        if store.userSettings.preferCompactMapControls, width < 1500 {
            return .compact
        }
        return MapEditorLayoutMode(width: width)
    }

    private var fixtureList: some View {
        EditorListShell(title: "Maps", records: records) { record in
            EditorSection(title: "Map Structure") {
                FactGrid(facts: record.facts)
            }

            EditorSection(title: "Event Preview") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Warps, object events, coord events, and signposts are grouped by source include.", systemImage: "point.3.connected.trianglepath.dotted")
                    Label("Selected map object highlights its script source without editing the include.", systemImage: "scope")
                }
                .foregroundStyle(.secondary)
            }

            NotesList(notes: record.notes)
        }
    }

    private func visualEditor(_ catalog: MapCatalogViewState, layoutMode: MapEditorLayoutMode) -> some View {
        Group {
            switch layoutMode {
            case .wide:
                wideVisualEditor(catalog)
            case .compact:
                compactVisualEditor(catalog)
            }
        }
        .navigationTitle("Maps")
        .onAppear {
            reconcileSelection(in: catalog)
            store.loadSelectedMapVisualDocumentIfNeeded()
        }
        .onChange(of: catalog.id) { _, _ in
            reconcileSelection(in: catalog)
            store.loadSelectedMapVisualDocument()
        }
        .onChange(of: store.selectedMapID) { _, _ in
            store.loadSelectedMapVisualDocument()
        }
    }

    private func wideVisualEditor(_ catalog: MapCatalogViewState) -> some View {
        VStack(spacing: 0) {
            editorTopChrome(layoutMode: .wide, catalog: catalog)

            editorCanvas(layoutMode: .wide)
                .frame(minWidth: 360, idealWidth: 840, maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func compactVisualEditor(_ catalog: MapCatalogViewState) -> some View {
        VStack(spacing: 0) {
            editorTopChrome(layoutMode: .compact, catalog: catalog)

            editorCanvas(layoutMode: .compact)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func editorTopChrome(layoutMode: MapEditorLayoutMode, catalog: MapCatalogViewState) -> some View {
        VStack(spacing: 0) {
            editorToolbar(layoutMode: layoutMode, catalog: catalog)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.bar)
                .accessibilityLabel("Map editor toolbar")

            if session.isDirty {
                MapEditorDirtyBanner(
                    operationCount: session.mapEditOperations.count,
                    onPreview: {
                        _ = session.previewSelectedMapMutationPlan()
                    },
                    onDiscard: store.discardMapEdits
                )
            }

            Divider()
        }
    }

    private func editorCanvas(layoutMode: MapEditorLayoutMode) -> some View {
        VStack(spacing: 0) {
            if let document = session.selectedMapVisualDocument {
                VStack(spacing: 0) {
                    GeometryReader { proxy in
                        ScrollView([.horizontal, .vertical]) {
                            MapVisualCanvas(
                                document: document,
                                rawValues: session.stagedMapBlockdataValues,
                                borderRawValues: session.stagedMapBorderValues,
                                events: session.stagedMapEvents,
                                selectedTool: session.selectedMapTool,
                                eventTemplate: session.selectedEventTemplate,
                                brushRawValue: session.selectedBrushRawValue,
                                overlays: session.mapOverlaySettings,
                                zoom: zoom,
                                selectedCell: session.selectedMapCell,
                                selectedCellTarget: session.selectedMapBlockTarget,
                                selectedEventID: session.selectedMapEventID,
                                viewportRequest: store.mapViewportRequest,
                                onSelectCell: { _, _ in },
                                onPaintCell: { _, _ in },
                                onFillCell: { _, _ in },
                                onEyedropCell: { _, _ in },
                                onSelectEvent: { _ in },
                                onMoveEvent: { _, _ in },
                                onAddEvent: { _, _ in },
                                onDuplicateEvent: {},
                                onDeleteEvent: {},
                                onHoverStatus: { hoverStatus = $0 },
                                onViewportChange: { viewport in
                                    if viewportSnapshot != viewport {
                                        viewportSnapshot = viewport
                                    }
                                },
                                onZoom: { factor in
                                    applyCanvasZoom(factor: factor)
                                },
                                onCommand: { _ = session.dispatch($0) }
                            )
                            .frame(
                                width: CGFloat(document.scene.viewport.width) * 16 * zoom,
                                height: CGFloat(document.scene.viewport.height) * 16 * zoom
                            )
                            .accessibilityLabel("Map canvas")
                        }
                        .background(Color(nsColor: .textBackgroundColor))
                        .overlay(alignment: .bottomLeading) {
                            MapEditorCanvasStatusHUD(
                                session: session,
                                hoverStatus: hoverStatus,
                                zoom: zoom,
                                isReadOnlyZoom: isReadOnlyZoom
                            )
                                .padding(10)
                        }
                        .onAppear {
                            canvasViewportSize = proxy.size
                            applyFitZoomIfNeeded(for: document, viewportSize: proxy.size)
                        }
                        .onChange(of: proxy.size) { _, size in
                            canvasViewportSize = size
                            applyFitZoomIfNeeded(for: document, viewportSize: size)
                        }
                    }

                    if store.mapShowsPalette && !layoutMode.isCompact {
                        Divider()
                        MetatilePaletteView(
                            document: document,
                            selectedRawValue: session.selectedBrushRawValue,
                            filterText: $store.mapMetatileFilter,
                            maxVisibleMetatiles: 512
                        ) { rawValue in
                            session.selectBrush(rawValue: rawValue)
                        }
                    }
                }
                .onChange(of: document.id) { _, _ in
                    viewportSnapshot = .zero
                    applyFitZoomIfNeeded(for: document, viewportSize: canvasViewportSize)
                }
            } else {
                ContentUnavailableView(
                    store.mapVisualStatus.label,
                    systemImage: "map",
                    description: Text("Select a map to load the visual editor.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .accessibilityLabel("Map editor canvas area")
    }

    private func editorToolbar(layoutMode: MapEditorLayoutMode, catalog: MapCatalogViewState) -> some View {
        HStack(spacing: 8) {
            Label(selectedMapName(in: catalog), systemImage: "map")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Divider()

            Button("Undo", systemImage: "arrow.uturn.backward") {
                session.undoLastMapEdit()
            }
            .labelStyle(.iconOnly)
            .help("Undo last staged map edit")
            .disabled(session.mapEditOperations.isEmpty)

            Button("Redo", systemImage: "arrow.uturn.forward") {
                session.redoMapEdit()
            }
            .labelStyle(.iconOnly)
            .help("Redo staged map edit")
            .disabled(session.undoneMapEditOperations.isEmpty)

            Divider()

            Button(store.mapShowsPalette ? "Hide Palette" : "Show Palette", systemImage: "square.grid.3x3") {
                store.mapShowsPalette.toggle()
            }
            .labelStyle(.iconOnly)
            .help(store.mapShowsPalette ? "Hide metatile palette" : "Show metatile palette")

            mapCommandMenu

            zoomControls

            Spacer(minLength: 8)

            if !layoutMode.isCompact {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(hoverStatus?.statusText ?? store.mapVisualStatus.label)
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
        .frame(height: 34)
    }

    private var mapCommandMenu: some View {
        Menu {
            Button("Reload Selected Map", systemImage: "arrow.clockwise") {
                store.loadSelectedMapVisualDocument()
            }
            .disabled(store.selectedMapID.isEmpty)

            Divider()

            Button("Preview Map Changes", systemImage: "doc.text.magnifyingglass") {
                store.previewSelectedMapMutationPlan()
            }
            .disabled(!session.canPreviewSelectedMapMutationPlan)
            .help(session.previewBlockedReason ?? "Preview staged map mutations")

            Button("Apply Previewed Map Changes", systemImage: "checkmark.seal") {
                store.applySelectedMapMutationPlan()
            }
            .disabled(!session.canApplySelectedMapMutationPlan)
            .help(session.applyBlockedReason ?? "Apply previewed map mutations")

            Button("Discard Map Changes", systemImage: "trash") {
                store.discardMapEdits()
            }
            .disabled(!session.canDiscardMapEdits)

            Divider()

            Button("Duplicate Selected Event", systemImage: "plus.square.on.square") {
                _ = session.dispatch(.duplicateSelectedMapEvent)
            }
            .disabled(session.selectedMapEventID == nil)

            Button("Delete Selected Event", systemImage: "trash") {
                _ = session.dispatch(.deleteSelectedMapEvent)
            }
            .disabled(session.selectedMapEventID == nil)
        } label: {
            Label("Map Commands", systemImage: "ellipsis.circle")
        }
        .labelStyle(.iconOnly)
        .help("Map reload, mutation, and selected-event commands")
    }

    private var zoomBinding: Binding<Double> {
        Binding {
            zoom
        } set: { value in
            applyZoom(value)
        }
    }

    private var zoomControls: some View {
        HStack(spacing: 5) {
            Button("Zoom Out", systemImage: "minus.magnifyingglass") {
                zoomOut()
            }
            .labelStyle(.iconOnly)
            .help("Zoom out")

            Button("100%") {
                setZoom(MapViewportGeometry.unitZoom)
            }
            .font(.caption.monospacedDigit())
            .help("Show map at 100%")

            Button("Zoom In", systemImage: "plus.magnifyingglass") {
                zoomIn()
            }
            .labelStyle(.iconOnly)
            .help("Zoom in")

            Button("Fit", systemImage: fitMapToView ? "arrow.up.left.and.down.right.magnifyingglass" : "arrow.up.left.and.down.right") {
                fitSelectedMapToView()
            }
            .labelStyle(.iconOnly)
            .help("Fit the whole map in the viewport")

            Button("Reset View", systemImage: "arrow.counterclockwise") {
                resetView()
            }
            .labelStyle(.iconOnly)
            .help("Reset zoom and pan")

            Slider(value: zoomBinding, in: MapViewportGeometry.minimumManualZoom...MapViewportGeometry.maximumZoom) {
                Text("Zoom")
            }
            .frame(width: 112)

            Text("\(Int((zoom * 100).rounded()))%")
                .font(.caption.monospacedDigit())
                .foregroundStyle(isReadOnlyZoom ? Color.orange : Color.secondary)
                .frame(width: 44, alignment: .trailing)
        }
    }

    private var isReadOnlyZoom: Bool {
        zoom < MapViewportGeometry.minimumEditableZoom
    }

    private func zoomIn() {
        applyZoom(zoom * 1.25)
    }

    private func zoomOut() {
        applyZoom(zoom / 1.25)
    }

    private func setZoom(_ nextZoom: Double) {
        applyZoom(nextZoom)
    }

    private func resetView() {
        fitMapToView = false
        zoom = MapViewportGeometry.defaultZoom
        store.mapViewportRequest = MapCanvasViewportRequest(centerX: 0, centerY: 0)
    }

    private func fitSelectedMapToView() {
        guard let document = session.selectedMapVisualDocument else { return }
        fitMapToView = true
        zoom = MapViewportGeometry.fitZoom(
            mapWidth: document.scene.viewport.width,
            mapHeight: document.scene.viewport.height,
            viewportSize: canvasViewportSize
        )
        store.mapViewportRequest = MapCanvasViewportRequest(
            centerX: CGFloat(document.scene.viewport.minX) + CGFloat(document.scene.viewport.width) / 2,
            centerY: CGFloat(document.scene.viewport.minY) + CGFloat(document.scene.viewport.height) / 2
        )
    }

    private func applyFitZoomIfNeeded(for document: MapVisualDocument, viewportSize: CGSize) {
        guard fitMapToView else { return }
        zoom = MapViewportGeometry.fitZoom(
            mapWidth: document.scene.viewport.width,
            mapHeight: document.scene.viewport.height,
            viewportSize: viewportSize
        )
    }

    private func applyCanvasZoom(factor: CGFloat) {
        applyZoom(zoom * Double(factor))
    }

    private func applyZoom(_ nextZoom: Double) {
        let clamped = clampedZoom(nextZoom)
        guard clamped != zoom else {
            fitMapToView = false
            return
        }

        fitMapToView = false
        let center = currentViewportCenter()
        zoom = clamped
        if let center {
            store.mapViewportRequest = MapCanvasViewportRequest(centerX: center.x, centerY: center.y)
        }
    }

    private func clampedZoom(_ value: Double) -> Double {
        min(max(value, MapViewportGeometry.minimumManualZoom), MapViewportGeometry.maximumZoom)
    }

    private func currentViewportCenter() -> CGPoint? {
        if !viewportSnapshot.isEmpty {
            return CGPoint(
                x: viewportSnapshot.originX + viewportSnapshot.width / 2,
                y: viewportSnapshot.originY + viewportSnapshot.height / 2
            )
        }

        guard let document = session.selectedMapVisualDocument else { return nil }
        return CGPoint(
            x: CGFloat(document.scene.viewport.minX) + CGFloat(document.scene.viewport.width) / 2,
            y: CGFloat(document.scene.viewport.minY) + CGFloat(document.scene.viewport.height) / 2
        )
    }

    private func selectedMapName(in catalog: MapCatalogViewState) -> String {
        catalog.maps.first { $0.id == store.selectedMapID }?.name ?? "Maps"
    }

    private func reconcileSelection(in catalog: MapCatalogViewState) {
        guard let firstID = catalog.maps.first?.id else {
            store.selectedMapID = ""
            return
        }
        if !catalog.maps.contains(where: { $0.id == store.selectedMapID }) {
            store.requestMapSelection(firstID, source: "Maps")
        }
    }
}
