import PokemonHackCore
import SwiftUI

struct MapEditorView: View {
    @ObservedObject var store: WorkbenchStore
    @ObservedObject private var session: MapEditorSession
    let records: [WorkbenchRecord]
    let catalog: MapCatalogViewState?

    @State private var zoom = 2.0
    @State private var showPalette = true
    @State private var showApplyConfirmation = false
    @State private var metatileFilter = ""
    @State private var hoverStatus: MapCanvasHoverStatus?
    @State private var fitMapToView = false
    @State private var canvasViewportSize: CGSize = .zero
    @State private var viewportSnapshot = MapCanvasViewport.zero
    @State private var viewportRequest: MapCanvasViewportRequest?

    init(store: WorkbenchStore, records: [WorkbenchRecord], catalog: MapCatalogViewState?) {
        self.store = store
        _session = ObservedObject(wrappedValue: store.mapEditorSession)
        self.records = records
        self.catalog = catalog
    }

    var body: some View {
        if let catalog {
            visualEditor(catalog)
        } else {
            fixtureList
        }
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

    private func visualEditor(_ catalog: MapCatalogViewState) -> some View {
        HSplitView {
            mapList(catalog)
                .frame(minWidth: 240, idealWidth: 280, maxWidth: 360)

            editorCanvas
                .frame(minWidth: 620, idealWidth: 900, maxWidth: .infinity, maxHeight: .infinity)

            inspector
                .frame(minWidth: 280, idealWidth: 320, maxWidth: 420)
        }
        .navigationTitle("Maps")
        .onAppear {
            reconcileSelection(in: catalog)
            store.loadSelectedMapVisualDocumentIfNeeded()
        }
        .onChange(of: catalog.id) { _ in
            reconcileSelection(in: catalog)
            store.loadSelectedMapVisualDocument()
        }
        .onChange(of: store.selectedMapID) { _ in
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

    private func mapList(_ catalog: MapCatalogViewState) -> some View {
        List(selection: mapSelection) {
            ForEach(catalog.groups) { group in
                Section(group.name) {
                    ForEach(maps(in: group, catalog: catalog)) { map in
                        MapSidebarRow(map: map)
                            .tag(map.id)
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    private var mapSelection: Binding<String> {
        Binding {
            store.selectedMapID
        } set: { mapID in
            store.requestMapSelection(mapID)
        }
    }

    private var editorCanvas: some View {
        VStack(spacing: 0) {
            editorToolbar
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.bar)

            if session.isDirty {
                dirtyBanner
            }

            Divider()

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
                                onCommand: { _ = session.dispatch($0) }
                            )
                            .frame(
                                width: CGFloat(document.scene.viewport.width) * 16 * zoom,
                                height: CGFloat(document.scene.viewport.height) * 16 * zoom
                            )
                        }
                        .background(Color(nsColor: .textBackgroundColor))
                        .overlay(alignment: .bottomLeading) {
                            canvasStatusHUD
                                .padding(10)
                        }
                        .onAppear {
                            canvasViewportSize = proxy.size
                            applyFitZoomIfNeeded(for: document, viewportSize: proxy.size)
                        }
                        .onChange(of: proxy.size) { size in
                            canvasViewportSize = size
                            applyFitZoomIfNeeded(for: document, viewportSize: size)
                        }
                    }

                    if showPalette {
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
                .onChange(of: document.id) { _ in
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
    }

    private var editorToolbar: some View {
        HStack(spacing: 8) {
            Picker("Tool", selection: $session.selectedMapTool) {
                ForEach(MapEditorTool.allCases) { tool in
                    Label(tool.title, systemImage: tool.systemImage)
                        .tag(tool)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 520)

            Divider()

            Button("Undo", systemImage: "arrow.uturn.backward") {
                session.undoLastMapEdit()
            }
            .help("Undo last staged map edit")
            .disabled(session.mapEditOperations.isEmpty)

            Button("Redo", systemImage: "arrow.uturn.forward") {
                session.redoMapEdit()
            }
            .help("Redo staged map edit")
            .disabled(session.undoneMapEditOperations.isEmpty)

            Divider()

            Button(showPalette ? "Hide Palette" : "Show Palette", systemImage: "square.grid.3x3") {
                showPalette.toggle()
            }

            Divider()

            Button("Zoom Out", systemImage: "minus.magnifyingglass") {
                zoomOut()
            }
            .labelStyle(.iconOnly)
            .help("Zoom out")

            Button("100%") {
                setZoom(MapViewportGeometry.unitZoom)
            }
            .help("Show map at 100%")

            Button("Zoom In", systemImage: "plus.magnifyingglass") {
                zoomIn()
            }
            .labelStyle(.iconOnly)
            .help("Zoom in")

            Button("Fit", systemImage: fitMapToView ? "arrow.up.left.and.down.right.magnifyingglass" : "arrow.up.left.and.down.right") {
                fitSelectedMapToView()
            }
            .help("Fit the whole map in the viewport")

            Button("Reset View", systemImage: "arrow.counterclockwise") {
                resetView()
            }
            .labelStyle(.iconOnly)
            .help("Reset zoom and pan")

            Slider(value: zoomBinding, in: MapViewportGeometry.minimumManualZoom...MapViewportGeometry.maximumZoom) {
                Text("Zoom")
            }
            .frame(width: 110)

            Text("\(Int((zoom * 100).rounded()))%")
                .font(.caption.monospacedDigit())
                .foregroundStyle(isReadOnlyZoom ? Color.orange : Color.secondary)
                .frame(width: 44, alignment: .trailing)

            Spacer()

            if let hoverStatus {
                Text(hoverStatus.statusText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(store.mapVisualStatus.label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var zoomBinding: Binding<Double> {
        Binding {
            zoom
        } set: { value in
            fitMapToView = false
            zoom = clampedZoom(value)
        }
    }

    private var isReadOnlyZoom: Bool {
        zoom < MapViewportGeometry.minimumEditableZoom
    }

    private func zoomIn() {
        setZoom(zoom * 1.25)
    }

    private func zoomOut() {
        setZoom(zoom / 1.25)
    }

    private func setZoom(_ nextZoom: Double) {
        fitMapToView = false
        zoom = clampedZoom(nextZoom)
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

    private func clampedZoom(_ value: Double) -> Double {
        min(max(value, MapViewportGeometry.minimumManualZoom), MapViewportGeometry.maximumZoom)
    }

    private var canvasStatusHUD: some View {
        HStack(spacing: 8) {
            Image(systemName: session.selectedMapTool.systemImage)
                .foregroundStyle(.secondary)
            Text(hoverStatus?.statusText ?? "Move over the map for coordinates")
                .font(.caption.monospacedDigit())
                .lineLimit(1)
            if let rawValue = session.selectedBrushRawValue {
                Text("Brush \(String(format: "%03X", Int(rawValue & 0x03ff)))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            if isReadOnlyZoom {
                Text("Read-only fit zoom")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
    }

    private var dirtyBanner: some View {
        HStack(spacing: 10) {
            Label("\(session.mapEditOperations.count) staged edit\(session.mapEditOperations.count == 1 ? "" : "s")", systemImage: "pencil.and.outline")
                .font(.caption.weight(.semibold))
            Text("Preview before applying source writes, or discard to reload from disk.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
            Button("Preview", systemImage: "doc.text.magnifyingglass") {
                _ = session.previewSelectedMapMutationPlan()
            }
            Button("Discard", systemImage: "arrow.counterclockwise") {
                store.discardMapEdits()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color(nsColor: .controlAccentColor).opacity(0.12))
    }

    private func metatilePalette(_ document: MapVisualDocument) -> some View {
        let metatiles = filteredMetatiles(in: document)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Metatiles")
                    .font(.headline)
                Text(brushLabel)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                TextField("Filter", text: $metatileFilter)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 160)
                Spacer()
                Text("\(metatiles.count) shown of \(document.metatiles.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal) {
                LazyHGrid(rows: [GridItem(.fixed(34)), GridItem(.fixed(34))], spacing: 6) {
                    ForEach(metatiles.prefix(160)) { metatile in
                        Button {
                            session.selectBrush(rawValue: UInt16(metatile.id & 0x03ff))
                        } label: {
                            Text(String(format: "%03X", metatile.id))
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .frame(width: 46, height: 28)
                        }
                        .buttonStyle(.bordered)
                        .help(metatile.tilesetSymbol)
                    }
                }
                .padding(.bottom, 6)
            }
        }
        .padding(12)
        .frame(maxHeight: 116)
        .background(.regularMaterial)
    }

    private func filteredMetatiles(in document: MapVisualDocument) -> [MetatileDefinition] {
        let query = metatileFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return document.metatiles }
        return document.metatiles.filter { metatile in
            String(format: "%03X", metatile.id).localizedCaseInsensitiveContains(query)
                || "\(metatile.id)".contains(query)
                || metatile.tilesetSymbol.localizedCaseInsensitiveContains(query)
        }
    }

    private var brushLabel: String {
        guard let rawValue = session.selectedBrushRawValue else {
            return "No brush"
        }
        return "Brush \(String(format: "%03X", Int(rawValue & 0x03ff)))"
    }

    private var inspector: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let document = session.selectedMapVisualDocument {
                    MapLayerInspectorView(
                        document: document,
                        session: session,
                        viewport: viewportSnapshot
                    ) { centerX, centerY in
                        viewportRequest = MapCanvasViewportRequest(centerX: centerX, centerY: centerY)
                    }
                    mapSummary(document)
                    sceneDiagnostics(document)
                    selectionInspector(document)
                    eventInspector
                    mutationInspector
                } else {
                    ContentUnavailableView("No Map", systemImage: "sidebar.right", description: Text(store.mapVisualStatus.label))
                }
            }
            .padding(16)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func mapSummary(_ document: MapVisualDocument) -> some View {
        EditorSection(title: document.mapName) {
            FactGrid(
                facts: [
                    Fact(label: "Map ID", value: document.mapID),
                    Fact(label: "Layout", value: document.layout.name ?? "Unknown"),
                    Fact(label: "Size", value: "\(document.blockdata.width)x\(document.blockdata.height)"),
                    Fact(label: "Primary", value: document.primaryTileset?.symbol ?? "Missing"),
                    Fact(label: "Secondary", value: document.secondaryTileset?.symbol ?? "Missing"),
                    Fact(label: "Events", value: "\(document.events.count)"),
                    Fact(label: "Scene", value: "\(document.scene.viewport.width)x\(document.scene.viewport.height)"),
                    Fact(label: "Connections", value: "\(document.scene.connections.filter(\.isResolved).count)/\(document.scene.connections.count)")
                ]
            )
        }
    }

    private func sceneDiagnostics(_ document: MapVisualDocument) -> some View {
        EditorSection(title: "Scene Diagnostics") {
            VStack(alignment: .leading, spacing: 8) {
                if document.diagnostics.isEmpty {
                    Label("Textures, palettes, borders, and connections resolved cleanly.", systemImage: "checkmark.seal")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(document.diagnostics.prefix(6)) { diagnostic in
                        VStack(alignment: .leading, spacing: 3) {
                            Label(diagnostic.code, systemImage: diagnostic.severity == .error ? "xmark.octagon" : "exclamationmark.triangle")
                                .font(.caption.weight(.semibold))
                            Text(diagnostic.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if document.diagnostics.count > 6 {
                        Text("\(document.diagnostics.count - 6) more diagnostics")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func selectionInspector(_ document: MapVisualDocument) -> some View {
        EditorSection(title: "Selection") {
            if let cell = session.selectedMapCell {
                VStack(alignment: .leading, spacing: 8) {
                    FactGrid(facts: [Fact(label: "Cell", value: "\(cell.x), \(cell.y)")])
                    MapSelectionLayerDetails(document: document, rawValue: cell.rawValue)
                }
            } else {
                Text("Select a cell or event on the canvas.")
                    .foregroundStyle(.secondary)
            }

            SourceLocationView(
                source: SourceLocation(path: document.blockdata.filepath, symbol: document.layout.id, line: 1)
            )
        }
    }

    private var eventInspector: some View {
        EditorSection(title: "Event Inspector") {
            if let event = selectedEvent {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label(event.kind.rawValue.capitalized, systemImage: "point.3.connected.trianglepath.dotted")
                            .font(.headline)
                        Spacer()
                        Text("#\(event.index)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    ForEach(event.properties) { property in
                        HStack(alignment: .top) {
                            Text(property.key)
                                .foregroundStyle(.secondary)
                                .frame(width: 112, alignment: .leading)
                            TextField(property.key, text: eventPropertyBinding(for: property))
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .font(.caption)
                    }
                    HStack {
                        Button("Duplicate", systemImage: "plus.square.on.square") {
                            session.duplicateSelectedMapEvent()
                        }
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            session.deleteSelectedMapEvent()
                        }
                    }
                }
            } else {
                Text("Use Select or Move Event to inspect map events.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var mutationInspector: some View {
        EditorSection(title: "Mutation Plan") {
            VStack(alignment: .leading, spacing: 10) {
                FactGrid(
                    facts: [
                        Fact(label: "Staged Ops", value: "\(session.mapEditOperations.count)"),
                        Fact(label: "Plan Changes", value: "\(session.latestMapEditPlan?.changes.count ?? 0)")
                    ]
                )

                HStack {
                    Button("Preview", systemImage: "doc.text.magnifyingglass") {
                        _ = session.previewSelectedMapMutationPlan()
                    }
                    .disabled(!session.canPreviewSelectedMapMutationPlan)
                    .help(session.previewBlockedReason ?? "Preview staged source changes")

                    Button("Apply", systemImage: "square.and.arrow.down") {
                        if !session.isLatestMapEditPlanCurrent {
                            _ = session.previewSelectedMapMutationPlan()
                        }
                        showApplyConfirmation = true
                    }
                    .disabled(!session.canApplySelectedMapMutationPlan)
                    .help(session.applyBlockedReason ?? "Apply staged source changes with backups")
                }

                if let plan = session.latestMapEditPlan {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(plan.changes) { change in
                            VStack(alignment: .leading, spacing: 2) {
                                Label(change.path, systemImage: "doc")
                                    .font(.caption.weight(.semibold))
                                    .textSelection(.enabled)
                                Text("\(change.summary) · \(change.originalByteCount) → \(change.newByteCount) bytes")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        ForEach(plan.diagnostics.prefix(5)) { diagnostic in
                            Label(diagnostic.message, systemImage: diagnostic.severity == .error ? "xmark.octagon" : "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(diagnostic.severity == .error ? .red : .orange)
                        }
                        if !plan.isApplyable {
                            Label("Apply is blocked until diagnostics are resolved.", systemImage: "lock.trianglebadge.exclamationmark")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                if let result = session.latestMapApplyResult {
                    Label("Backed up to \(result.backupRootPath)", systemImage: "checkmark.seal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var selectedEvent: MapEventDescriptor? {
        guard let id = session.selectedMapEventID else { return nil }
        return session.stagedMapEvents.first { $0.id == id }
    }

    private func eventPropertyBinding(for property: MapEventProperty) -> Binding<String> {
        Binding {
            selectedEvent?.properties.first { $0.key == property.key }?.value ?? property.value
        } set: { value in
            session.updateSelectedMapEventProperty(key: property.key, value: value)
        }
    }

    private func maps(in group: MapGroupViewState, catalog: MapCatalogViewState) -> [MapSummaryViewState] {
        let byID = Dictionary(uniqueKeysWithValues: catalog.maps.map { ($0.id, $0) })
        return group.mapIDs.compactMap { byID[$0] }
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

private struct MapSidebarRow: View {
    let map: MapSummaryViewState

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "map")
                .foregroundStyle(.secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(map.name)
                    .lineLimit(1)
                Text(map.layout?.name ?? map.mapID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
