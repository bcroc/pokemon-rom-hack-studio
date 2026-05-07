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
    @State private var showPalette = true
    @State private var showApplyConfirmation = false
    @State private var showCompactMapBrowser = false
    @State private var showCompactInspector = false
    @State private var showCompactPalette = false
    @State private var mapFilter = ""
    @State private var metatileFilter = ""
    @State private var hoverStatus: MapCanvasHoverStatus?
    @State private var fitMapToView = false
    @State private var canvasViewportSize: CGSize = .zero
    @State private var viewportSnapshot = MapCanvasViewport.zero
    @State private var viewportRequest: MapCanvasViewportRequest?
    @State private var eventSearchText = ""
    @State private var scriptDraftKey = ""
    @State private var scriptDraftText = ""
    @State private var selectedWorkbenchTab: MapWorkbenchTab = .overviewLayers

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
        .confirmationDialog("Apply map edits?", isPresented: $showApplyConfirmation) {
            Button("Apply Source Writes", role: .destructive) {
                store.applySelectedMapMutationPlan()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("PokemonHackStudio will write source files and create backups under .pokemonhackstudio/backups.")
        }
    }

    private func wideVisualEditor(_ catalog: MapCatalogViewState) -> some View {
        VStack(spacing: 0) {
            editorTopChrome(layoutMode: .wide, catalog: catalog)

            HSplitView {
                MapBrowserView(
                    catalog: catalog,
                    selectedMapID: store.selectedMapID,
                    searchText: $mapFilter,
                    onSelectMap: store.requestMapSelection
                )
                    .frame(minWidth: 170, idealWidth: 240, maxWidth: 320)

                editorCanvas(layoutMode: .wide)
                    .frame(minWidth: 360, idealWidth: 840, maxWidth: .infinity, maxHeight: .infinity)

                inspector(layoutMode: .wide)
                    .frame(minWidth: 260, idealWidth: 340, maxWidth: 430)
            }
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
                                viewportRequest: viewportRequest,
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

                    if showPalette && !layoutMode.isCompact {
                        Divider()
                        MetatilePaletteView(
                            document: document,
                            selectedRawValue: session.selectedBrushRawValue,
                            filterText: $metatileFilter,
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
        MapEditorToolbar(
            session: session,
            layoutMode: layoutMode,
            selectedMapTitle: selectedMapName(in: catalog),
            visualStatus: store.mapVisualStatus.label,
            hoverStatus: hoverStatus,
            zoom: zoomBinding,
            isReadOnlyZoom: isReadOnlyZoom,
            fitMapToView: fitMapToView,
            showPalette: $showPalette,
            showCompactMapBrowser: $showCompactMapBrowser,
            showCompactPalette: $showCompactPalette,
            showCompactInspector: $showCompactInspector,
            mapBrowserPopover: AnyView(
                MapBrowserView(
                    catalog: catalog,
                    selectedMapID: store.selectedMapID,
                    searchText: $mapFilter,
                    onSelectMap: store.requestMapSelection
                )
                .frame(width: 340, height: 620)
                .onChange(of: store.selectedMapID) { _, _ in
                    showCompactMapBrowser = false
                }
            ),
            palettePopover: AnyView(compactPalettePopover),
            inspectorPopover: AnyView(
                inspector(layoutMode: .compact)
                    .frame(width: 430, height: 680)
            ),
            onUndo: session.undoLastMapEdit,
            onRedo: session.redoMapEdit,
            onZoomOut: zoomOut,
            onUnitZoom: {
                setZoom(MapViewportGeometry.unitZoom)
            },
            onZoomIn: zoomIn,
            onFitMap: fitSelectedMapToView,
            onResetView: resetView
        )
    }

    private var compactPalettePopover: some View {
        Group {
            if let document = session.selectedMapVisualDocument {
                MetatilePaletteView(
                    document: document,
                    selectedRawValue: session.selectedBrushRawValue,
                    filterText: $metatileFilter,
                    maxVisibleMetatiles: 512
                ) { rawValue in
                    session.selectBrush(rawValue: rawValue)
                }
                .frame(width: 760)
            } else {
                ContentUnavailableView("No Palette", systemImage: "square.grid.3x3", description: Text(store.mapVisualStatus.label))
                    .frame(width: 360, height: 180)
            }
        }
    }

    private var zoomBinding: Binding<Double> {
        Binding {
            zoom
        } set: { value in
            applyZoom(value)
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
        viewportRequest = MapCanvasViewportRequest(centerX: 0, centerY: 0)
    }

    private func fitSelectedMapToView() {
        guard let document = session.selectedMapVisualDocument else { return }
        fitMapToView = true
        zoom = MapViewportGeometry.fitZoom(
            mapWidth: document.scene.viewport.width,
            mapHeight: document.scene.viewport.height,
            viewportSize: canvasViewportSize
        )
        viewportRequest = MapCanvasViewportRequest(
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
            viewportRequest = MapCanvasViewportRequest(centerX: center.x, centerY: center.y)
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

    private func inspector(layoutMode: MapEditorLayoutMode) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let document = session.selectedMapVisualDocument {
                    MapWorkbenchPanels(
                        document: document,
                        session: session,
                        layoutMode: layoutMode,
                        viewport: viewportSnapshot,
                        selectedTab: $selectedWorkbenchTab,
                        eventSearchText: $eventSearchText,
                        scriptDraftKey: $scriptDraftKey,
                        scriptDraftText: $scriptDraftText,
                        onSelectViewportCenter: { centerX, centerY in
                            viewportRequest = MapCanvasViewportRequest(centerX: centerX, centerY: centerY)
                        },
                        onCenterEvent: { event in
                            centerOnEvent(event)
                        }
                    ) {
                        mutationInspector
                    }
                } else {
                    ContentUnavailableView("No Map", systemImage: "sidebar.right", description: Text(store.mapVisualStatus.label))
                }
            }
            .padding(16)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .accessibilityLabel("Map workbench inspector")
    }

    private var mutationInspector: some View {
        MutationPlanPanel(
            context: MutationPlanPanelContext.map(session: session) ?? emptyMutationContext,
            layoutMode: .compact,
            onPreview: {
                _ = session.previewSelectedMapMutationPlan()
            },
            onApply: {
                if !session.isLatestMapEditPlanCurrent {
                    _ = session.previewSelectedMapMutationPlan()
                }
                showApplyConfirmation = true
            },
            onDiscard: {
                store.discardMapEdits()
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel("Map mutation review")
    }

    private var emptyMutationContext: MutationPlanPanelContext {
        MutationPlanPanelContext(
            title: "Map Mutation Plan",
            summary: "No staged map edits.",
            status: .valid,
            operationCount: session.mapEditOperations.count,
            changes: [],
            appliedChanges: [],
            diagnostics: [],
            canPreview: session.canPreviewSelectedMapMutationPlan,
            canApply: session.canApplySelectedMapMutationPlan,
            canDiscard: session.canDiscardMapEdits,
            previewBlockedReason: session.previewBlockedReason,
            applyBlockedReason: session.applyBlockedReason
        )
    }

    private func centerOnEvent(_ event: MapEventDescriptor) {
        session.selectMapEvent(id: event.id)
        guard let x = event.x, let y = event.y else { return }
        viewportRequest = MapCanvasViewportRequest(centerX: CGFloat(x), centerY: CGFloat(y))
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
            store.selectedMapID = firstID
        }
    }
}
