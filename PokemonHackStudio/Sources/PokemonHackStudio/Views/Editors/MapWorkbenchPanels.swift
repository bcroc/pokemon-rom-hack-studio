import PokemonHackCore
import SwiftUI

struct MapWorkbenchPanels: View {
    let document: MapVisualDocument
    let catalog: ProjectMapCatalog?
    @ObservedObject var session: MapEditorSession
    let layoutMode: MapEditorLayoutMode
    let viewport: MapCanvasViewport
    @Binding var selectedTab: MapWorkbenchTab
    @Binding var eventSearchText: String
    @Binding var scriptDraftKey: String
    @Binding var scriptDraftText: String
    let onSelectViewportCenter: (CGFloat, CGFloat) -> Void
    let onCenterEvent: (MapEventDescriptor) -> Void
    @State private var metatileTileIndex = 0
    @State private var metatileTileRawValue = ""
    @State private var metatileAttributeKey = "behavior"
    @State private var metatileAttributeValue = ""
    @State private var duplicateMapID = ""
    @State private var duplicateMapName = ""
    @State private var prefabName = "Prefab"
    @State private var prefabWidth = "2"
    @State private var prefabHeight = "2"
    @State private var prefabRawValues = "1, 1, 1, 1"
    @State private var prefabX = "0"
    @State private var prefabY = "0"
    @State private var exportFileStem = ""

    init(
        document: MapVisualDocument,
        catalog: ProjectMapCatalog? = nil,
        session: MapEditorSession,
        layoutMode: MapEditorLayoutMode,
        viewport: MapCanvasViewport,
        selectedTab: Binding<MapWorkbenchTab>,
        eventSearchText: Binding<String>,
        scriptDraftKey: Binding<String>,
        scriptDraftText: Binding<String>,
        onSelectViewportCenter: @escaping (CGFloat, CGFloat) -> Void,
        onCenterEvent: @escaping (MapEventDescriptor) -> Void
    ) {
        self.document = document
        self.catalog = catalog
        self.session = session
        self.layoutMode = layoutMode
        self.viewport = viewport
        _selectedTab = selectedTab
        _eventSearchText = eventSearchText
        _scriptDraftKey = scriptDraftKey
        _scriptDraftText = scriptDraftText
        self.onSelectViewportCenter = onSelectViewportCenter
        self.onCenterEvent = onCenterEvent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            tabSelector
            selectedPanel
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Map workbench inspector")
    }

    @ViewBuilder
    private var tabSelector: some View {
        if layoutMode.isCompact {
            Picker("Panel", selection: $selectedTab) {
                ForEach(MapWorkbenchTab.allCases) { tab in
                    Label(tab.title, systemImage: tab.systemImage)
                        .tag(tab)
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel("Map workbench panel selector")
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(MapWorkbenchTab.allCases) { tab in
                        MapWorkbenchTabButton(
                            tab: tab,
                            isSelected: selectedTab == tab
                        ) {
                            selectedTab = tab
                        }
                    }
                }
                .padding(.bottom, 1)
            }
            .accessibilityLabel("Map workbench tab bar")
        }
    }

    @ViewBuilder
    private var selectedPanel: some View {
        switch selectedTab {
        case .overviewLayers:
            overviewLayersPanel
        case .paintCollision:
            paintCollisionPanel
        case .eventsScripts:
            eventsScriptsPanel
        case .mapData:
            mapDataPanel
        case .workflow:
            workflowPanel
        }
    }

    private var overviewLayersPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            MapLayerInspectorView(
                document: document,
                session: session,
                layoutMode: layoutMode,
                viewport: viewport,
                onSelectViewportCenter: onSelectViewportCenter
            )
            .accessibilityLabel("Map overview, layer views, and overlays")

            mapSummary
            selectionSummary
            sceneDiagnostics
        }
    }

    private var paintCollisionPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            mapAuthoring
            collisionPanel
            tilesetsPanel
        }
    }

    private var eventsScriptsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            eventsPanel
            scriptsPanel
        }
    }

    private var mapDataPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerPanel
            connectionsPanel
            wildPanel
        }
    }

    private var workflowPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            EditorSection(title: "Duplicate Map Plan") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        TextField("New map id", text: $duplicateMapID)
                            .textFieldStyle(.roundedBorder)
                        TextField("New map folder", text: $duplicateMapName)
                            .textFieldStyle(.roundedBorder)
                    }
                    if let duplicationPlan {
                        workflowPlanSummary(
                            title: duplicationPlan.mutationPlan.title,
                            summary: duplicationPlan.mutationPlan.summary,
                            diagnostics: duplicationPlan.diagnostics,
                            reasons: duplicationPlan.executionState.reasons
                        )
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Source Event Capacity")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            FactGrid(facts: MapEventCapacityFactBuilder.facts(from: duplicationPlan.sourceEventCapacity))
                        }
                        workflowPathList(duplicationPlan.plannedFiles.map { $0.destinationPath ?? $0.sourcePath })
                    } else {
                        Text("Load the map catalog before planning duplication.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            EditorSection(title: "Reload Snapshot") {
                VStack(alignment: .leading, spacing: 10) {
                    if reloadDiagnostics.isEmpty {
                        Label("Tracked map sources match the current workflow snapshot.", systemImage: "checkmark.seal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(reloadDiagnostics) { diagnostic in
                            workflowDiagnosticRow(diagnostic)
                        }
                    }
                    workflowPathList(workflowSnapshots.map(\.relativePath))
                }
            }

            EditorSection(title: "Prefab Paste") {
                VStack(alignment: .leading, spacing: 10) {
                    TextField("Prefab name", text: $prefabName)
                        .textFieldStyle(.roundedBorder)
                    HStack(spacing: 8) {
                        TextField("Width", text: $prefabWidth)
                            .textFieldStyle(.roundedBorder)
                        TextField("Height", text: $prefabHeight)
                            .textFieldStyle(.roundedBorder)
                        TextField("X", text: $prefabX)
                            .textFieldStyle(.roundedBorder)
                        TextField("Y", text: $prefabY)
                            .textFieldStyle(.roundedBorder)
                    }
                    TextField("Raw metatiles", text: $prefabRawValues)
                        .textFieldStyle(.roundedBorder)
                    if let prefabPastePlan {
                        workflowPlanSummary(
                            title: prefabPastePlan.mutationPlan.title,
                            summary: prefabPastePlan.mutationPlan.summary,
                            diagnostics: prefabPastePlan.diagnostics,
                            reasons: prefabPastePlan.executionState.reasons
                        )
                    }
                    Button("Stage Prefab Paste", systemImage: "plus") {
                        stagePrefabPaste()
                    }
                    .disabled(prefabPastePlan?.executionState.canApply != true)
                }
            }

            EditorSection(title: "Region and Export Plans") {
                VStack(alignment: .leading, spacing: 10) {
                    workflowPlanSummary(
                        title: regionPreview.displayName,
                        summary: regionPreview.usesFallback ? "Region preview falls back to the map name." : "Region preview uses \(regionPreview.regionMapSection ?? "source metadata").",
                        diagnostics: regionPreview.diagnostics,
                        reasons: []
                    )
                    TextField("Export file stem", text: $exportFileStem)
                        .textFieldStyle(.roundedBorder)
                    workflowPlanSummary(
                        title: visualExportPlan.mutationPlan.title,
                        summary: visualExportPlan.mutationPlan.summary,
                        diagnostics: visualExportPlan.diagnostics,
                        reasons: visualExportPlan.executionState.reasons
                    )
                    workflowPathList(visualExportPlan.artifacts.map(\.relativePath))
                }
            }
        }
    }

    private var collisionPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            EditorSection(title: "Collision View") {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(isOn: visibilityBinding(for: .collision)) {
                        Label("Collision", systemImage: MapEditorLayer.collision.systemImage)
                    }
                    .toggleStyle(.checkbox)
                    .accessibilityLabel("Show collision overlay")

                    Toggle(isOn: visibilityBinding(for: .grid)) {
                        Label("Grid", systemImage: MapEditorLayer.grid.systemImage)
                    }
                    .toggleStyle(.checkbox)
                    .accessibilityLabel("Show grid overlay")

                    HStack(spacing: 8) {
                        Slider(value: opacityBinding(for: .collision), in: 0...1)
                            .accessibilityLabel("Collision opacity")
                        Text("\(Int((session.mapOverlaySettings.state(for: .collision).opacity * 100).rounded()))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 42, alignment: .trailing)
                    }

                    HStack {
                        Button("Solo Collision", systemImage: "scope") {
                            session.toggleLayerSolo(.collision)
                        }
                        .accessibilityLabel("Solo collision layer")

                        Button("Reset Layers", systemImage: "arrow.counterclockwise") {
                            session.resetLayerSettings()
                        }
                        .accessibilityLabel("Reset map layers")
                    }
                }
            }

            selectedCollisionTile

            EditorSection(title: "Collision Authoring") {
                if session.selectedMapCell == nil {
                    Text("Select a map tile before staging collision or elevation changes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Stepper("Collision \(selectedBehaviorText)", value: collisionBinding, in: 0...3)
                        Stepper("Elevation \(selectedElevationText)", value: elevationBinding, in: 0...15)
                        Label("Collision and elevation edits are staged as map block attribute operations.", systemImage: "doc.text.magnifyingglass")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var eventsPanel: some View {
        MapEventsPaneView(
            document: document,
            session: session,
            eventSearchText: $eventSearchText,
            scriptDraftKey: $scriptDraftKey,
            scriptDraftText: $scriptDraftText,
            viewportCenter: viewportCenterCoordinate,
            onCenterEvent: onCenterEvent
        )
        .accessibilityLabel("Map events editor")
    }

    private var headerPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            EditorSection(title: "Header") {
                VStack(alignment: .leading, spacing: 10) {
                    FactGrid(facts: headerFacts)
                    SourceLocationView(
                        source: SourceLocation(path: document.mapSourcePath, symbol: document.mapID, line: 1)
                    )
                }
            }

            EditorSection(title: "Header Authoring") {
                VStack(alignment: .leading, spacing: 10) {
                    HeaderFieldDraftRow(title: "Music", key: "music", value: document.mapMetadata.music ?? "") { key, value in
                        session.updateMapHeaderField(key: key, value: value)
                    }
                    HeaderFieldDraftRow(title: "Location", key: "region_map_section", value: document.mapMetadata.regionMapSection ?? "") { key, value in
                        session.updateMapHeaderField(key: key, value: value)
                    }
                    HeaderFieldDraftRow(title: "Weather", key: "weather", value: document.mapMetadata.weather ?? "") { key, value in
                        session.updateMapHeaderField(key: key, value: value)
                    }
                    HeaderFieldDraftRow(title: "Map Type", key: "map_type", value: document.mapMetadata.mapType ?? "") { key, value in
                        session.updateMapHeaderField(key: key, value: value)
                    }
                    HeaderFieldDraftRow(title: "Battle Scene", key: "battle_scene", value: "") { key, value in
                        session.updateMapHeaderField(key: key, value: value)
                    }
                    HeaderFieldDraftRow(title: "Floor", key: "floor_number", value: document.mapMetadata.floorNumber.map(String.init) ?? "") { key, value in
                        session.updateMapHeaderField(key: key, value: value)
                    }
                }
            }
        }
    }

    private var connectionsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            EditorSection(title: "Connections") {
                if document.scene.connections.isEmpty {
                    Text("No connections are indexed for this map.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(document.scene.connections) { connection in
                            connectionRow(connection)
                        }
                    }
                }
            }

            sceneDiagnostics

            EditorSection(title: "Connection Authoring") {
                VStack(alignment: .leading, spacing: 10) {
                    Button("Add North Connection", systemImage: "plus") {
                        session.addConnection(properties: [
                            MapEventProperty(key: "direction", value: "up"),
                            MapEventProperty(key: "offset", value: "0"),
                            MapEventProperty(key: "map", value: document.mapID)
                        ])
                    }
                    .help("Stage a source-backed connection template that can be edited in the mutation preview.")

                    Label("Use each row to adjust offsets, duplicate/mirror, or delete existing connection JSON entries.", systemImage: "ruler")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var wildPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            EditorSection(title: "Wild Encounters") {
                if let wild = document.wildEncounters {
                    VStack(alignment: .leading, spacing: 10) {
                        FactGrid(
                            facts: [
                                Fact(label: "Map", value: document.mapID),
                                Fact(label: "Groups", value: "\(wild.groups.count)"),
                                Fact(label: "Entries", value: "\(wild.groups.flatMap(\.encounters).count)"),
                                Fact(label: "Source", value: wild.sourcePath)
                            ]
                        )

                        if wild.groups.isEmpty {
                            Text("No encounter rows are indexed for this map.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(wild.groups) { group in
                                wildGroupRow(group, sourcePath: wild.sourcePath, speciesIDs: document.eventOptions.speciesIDs)
                            }
                        }

                        Label("Encounter edits are staged as source-backed mutation plans with preview, backups, and explicit apply.", systemImage: "checklist.checked")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("No wild encounter index is loaded.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var scriptsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            EditorSection(title: "Scripts") {
                if let scriptIndex = document.scriptIndex {
                    VStack(alignment: .leading, spacing: 10) {
                        FactGrid(
                            facts: [
                                Fact(label: "Sources", value: "\(scriptIndex.sources.count)"),
                                Fact(label: "Labels", value: "\(scriptIndex.labels.count)"),
                                Fact(label: "Diagnostics", value: "\(scriptIndex.diagnostics.count)")
                            ]
                        )

                        scriptSourceList(scriptIndex)
                    }
                } else {
                    Text("No map script index is loaded.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            selectedScriptResolution
            stagedScripts
            scriptDiagnostics
        }
    }

    private var tilesetsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            EditorSection(title: "Tilesets") {
                VStack(alignment: .leading, spacing: 12) {
                    tilesetFacts(title: "Primary", tileset: document.primaryTileset)
                    tilesetFacts(title: "Secondary", tileset: document.secondaryTileset)
                    FactGrid(
                        facts: [
                            Fact(label: "Metatiles", value: "\(document.metatiles.count)"),
                            Fact(label: "Brush", value: selectedBrushText)
                        ]
                    )
                }
            }

            selectedTilesetTile

            EditorSection(title: "Tileset Authoring") {
                if let selectedMetatileID {
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Attribute", selection: $metatileAttributeKey) {
                            Text("Behavior").tag("behavior")
                            Text("Layer Type").tag("layer_type")
                            Text("Raw Value").tag("raw_value")
                        }
                        .pickerStyle(.segmented)
                        TextField("Attribute value", text: $metatileAttributeValue)
                            .textFieldStyle(.roundedBorder)
                        Button("Stage Attribute", systemImage: "slider.horizontal.3") {
                            session.updateMetatileAttribute(
                                metatileID: selectedMetatileID,
                                tilesetSymbol: selectedMetatileTilesetSymbol,
                                key: metatileAttributeKey,
                                value: metatileAttributeValue
                            )
                        }
                        .disabled(metatileAttributeValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Divider()

                        Stepper("Tile Entry \(metatileTileIndex)", value: $metatileTileIndex, in: 0...7)
                        TextField("Raw tile word", text: $metatileTileRawValue)
                            .textFieldStyle(.roundedBorder)
                        Button("Stage Tile Word", systemImage: "square.grid.3x3") {
                            if let rawValue = UInt16(metatileTileRawValue.trimmingCharacters(in: .whitespacesAndNewlines)) {
                                session.updateMetatileTile(
                                    metatileID: selectedMetatileID,
                                    tilesetSymbol: selectedMetatileTilesetSymbol,
                                    tileEntryIndex: metatileTileIndex,
                                    rawValue: rawValue
                                )
                            }
                        }
                        .disabled(UInt16(metatileTileRawValue.trimmingCharacters(in: .whitespacesAndNewlines)) == nil)
                    }
                } else {
                    Text("Select a metatile on the canvas before staging tileset edits.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var mapAuthoring: some View {
        EditorSection(title: "Canvas Authoring") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Button("Shift Left", systemImage: "arrow.left") {
                        session.shiftMap(deltaX: -1, deltaY: 0, fillRawValue: session.selectedBrushRawValue ?? 0)
                    }
                    Button("Shift Right", systemImage: "arrow.right") {
                        session.shiftMap(deltaX: 1, deltaY: 0, fillRawValue: session.selectedBrushRawValue ?? 0)
                    }
                }
                HStack {
                    Button("Shift Up", systemImage: "arrow.up") {
                        session.shiftMap(deltaX: 0, deltaY: -1, fillRawValue: session.selectedBrushRawValue ?? 0)
                    }
                    Button("Shift Down", systemImage: "arrow.down") {
                        session.shiftMap(deltaX: 0, deltaY: 1, fillRawValue: session.selectedBrushRawValue ?? 0)
                    }
                }

                if let selectedMapCell = session.selectedMapCell {
                    Button("Copy 2x2 From Selection", systemImage: "square.on.square") {
                        stageTwoByTwoPrefab(from: selectedMapCell)
                    }
                    .disabled(!canCopyTwoByTwo(from: selectedMapCell))
                }

                Label("Shift and prefab operations stay preview-first and flow through the mutation panel.", systemImage: "doc.text.magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var mapSummary: some View {
        EditorSection(title: document.mapName) {
            FactGrid(
                facts: [
                    Fact(label: "Map ID", value: document.mapID),
                    Fact(label: "Layout", value: document.layout.name ?? "Unknown"),
                    Fact(label: "Size", value: "\(document.blockdata.width)x\(document.blockdata.height)"),
                    Fact(label: "Primary", value: document.primaryTileset?.symbol ?? "Missing"),
                    Fact(label: "Secondary", value: document.secondaryTileset?.symbol ?? "Missing"),
                    Fact(label: "Events", value: "\(document.events.count)"),
                    Fact(label: "Objects", value: capacityFact(for: .object)),
                    Fact(label: "Warps", value: capacityFact(for: .warp)),
                    Fact(label: "Coords", value: capacityFact(for: .coord)),
                    Fact(label: "BG", value: capacityFact(for: .bg)),
                    Fact(label: "Scene", value: "\(document.scene.viewport.width)x\(document.scene.viewport.height)"),
                    Fact(label: "Connections", value: "\(document.scene.connections.filter(\.isResolved).count)/\(document.scene.connections.count)")
                ]
            )
        }
    }

    private var sceneDiagnostics: some View {
        EditorSection(title: "Scene Diagnostics") {
            VStack(alignment: .leading, spacing: 8) {
                if document.diagnostics.isEmpty && document.scene.diagnostics.isEmpty {
                    Label("No scene diagnostics.", systemImage: "checkmark.seal")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach((document.diagnostics + document.scene.diagnostics).prefix(6)) { diagnostic in
                        VStack(alignment: .leading, spacing: 3) {
                            Label(diagnostic.code, systemImage: diagnostic.severity == .error ? "xmark.octagon" : "exclamationmark.triangle")
                                .font(.caption.weight(.semibold))
                            Text(diagnostic.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private var selectionSummary: some View {
        EditorSection(title: "Selection") {
            if let cell = session.selectedMapCell {
                VStack(alignment: .leading, spacing: 8) {
                    FactGrid(facts: [Fact(label: "Cell", value: "\(cell.x), \(cell.y)")])
                    MapSelectionLayerDetails(document: document, rawValue: cell.rawValue)
                }
            } else if let event = session.selectedMapEvent {
                FactGrid(
                    facts: [
                        Fact(label: "Event", value: "\(event.kind.rawValue) #\(event.index)"),
                        Fact(label: "Position", value: eventPositionText(event))
                    ]
                )
            } else {
                Text("No map cell or event is selected.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            SourceLocationView(
                source: SourceLocation(path: document.blockdata.filepath, symbol: document.layout.id, line: 1)
            )
        }
    }

    private var selectedCollisionTile: some View {
        EditorSection(title: "Selected Tile") {
            if let cell = session.selectedMapCell {
                VStack(alignment: .leading, spacing: 8) {
                    FactGrid(
                        facts: [
                            Fact(label: "Cell", value: "\(cell.x), \(cell.y)"),
                            Fact(label: "Target", value: session.selectedMapBlockTarget.rawValue.capitalized)
                        ]
                    )
                    MapSelectionLayerDetails(document: document, rawValue: cell.rawValue)
                }
            } else {
                Text("No tile is selected.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var selectedTilesetTile: some View {
        EditorSection(title: "Selected Metatile") {
            if let cell = session.selectedMapCell {
                MapSelectionLayerDetails(document: document, rawValue: cell.rawValue)
            } else {
                Text("No metatile is selected.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var selectedScriptResolution: some View {
        EditorSection(title: "Selected Script") {
            if let event = session.selectedMapEvent {
                VStack(alignment: .leading, spacing: 10) {
                    FactGrid(
                        facts: [
                            Fact(label: "Event", value: "\(event.kind.rawValue) #\(event.index)"),
                            Fact(label: "Script", value: event.propertyValue("script") ?? "None")
                        ]
                    )

                    if let scriptIndex = document.scriptIndex {
                        scriptResolutionRows(scriptIndex.resolution(for: event.scriptLabel))
                    }

                    Button("Edit In Events", systemImage: MapWorkbenchTab.eventsScripts.systemImage) {
                        selectedTab = .eventsScripts
                    }
                    .accessibilityLabel("Edit selected event script in Events and Scripts group")
                }
            } else {
                Text("No event script is selected.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var stagedScripts: some View {
        if !session.stagedMapScriptBodies.isEmpty {
            EditorSection(title: "Staged Scripts") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(session.stagedMapScriptBodies.values).sorted(by: { $0.id < $1.id })) { script in
                        VStack(alignment: .leading, spacing: 3) {
                            Label(script.label, systemImage: script.isNew ? "plus.rectangle.on.folder" : "square.and.pencil")
                                .font(.caption.weight(.semibold))
                            Text(script.sourcePath)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var scriptDiagnostics: some View {
        if let scriptIndex = document.scriptIndex, !scriptIndex.diagnostics.isEmpty {
            EditorSection(title: "Script Diagnostics") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(scriptIndex.diagnostics.prefix(5)) { diagnostic in
                        Label(diagnostic.message, systemImage: diagnostic.severity == .error ? "xmark.octagon" : "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(diagnostic.severity == .error ? .red : .orange)
                    }
                }
            }
        }
    }

    private var headerFacts: [Fact] {
        let metadata = document.mapMetadata
        return [
            Fact(label: "Map ID", value: metadata.mapID),
            Fact(label: "Name", value: metadata.mapName),
            Fact(label: "Music", value: metadata.music ?? "Unspecified"),
            Fact(label: "Type", value: metadata.mapType ?? "Unspecified"),
            Fact(label: "Weather", value: metadata.weather ?? "Unspecified"),
            Fact(label: "Region", value: metadata.regionMapSection ?? "Unspecified"),
            Fact(label: "Floor", value: metadata.floorNumber.map(String.init) ?? "Unspecified")
        ]
    }

    private var metadataPresentationSummary: String {
        let parts = [
            document.mapMetadata.music,
            document.mapMetadata.weather,
            document.mapMetadata.regionMapSection
        ]
        .compactMap { $0 }
        return parts.isEmpty ? "Unspecified" : parts.joined(separator: " / ")
    }

    private var viewportCenterCoordinate: (x: Int, y: Int)? {
        guard !viewport.isEmpty else { return nil }
        return (
            x: min(max(Int((viewport.originX + viewport.width / 2).rounded()), 0), max(document.blockdata.width - 1, 0)),
            y: min(max(Int((viewport.originY + viewport.height / 2).rounded()), 0), max(document.blockdata.height - 1, 0))
        )
    }

    private var connectionDirectionSummary: String {
        let directions = Set(document.scene.connections.compactMap { $0.direction?.rawValue }).sorted()
        return directions.isEmpty ? "No resolved directions" : directions.joined(separator: ", ")
    }

    private var selectedBrushText: String {
        guard let rawValue = session.selectedBrushRawValue else { return "None" }
        return String(format: "0x%04X", rawValue)
    }

    private var selectedBehaviorText: String {
        guard let cell = session.selectedMapCell else { return "No tile selected" }
        let attributes = MapBlockAttributes(rawValue: cell.rawValue)
        return "\(attributes.collision)"
    }

    private var selectedElevationText: String {
        guard let cell = session.selectedMapCell else { return "No tile selected" }
        let attributes = MapBlockAttributes(rawValue: cell.rawValue)
        return "\(attributes.elevation)"
    }

    private var selectedMetatileText: String {
        guard let cell = session.selectedMapCell else { return "No metatile selected" }
        return String(format: "%03X", cell.metatileID)
    }

    private var selectedMetatileID: Int? {
        session.selectedMapCell?.metatileID
    }

    private var selectedMetatileTilesetSymbol: String? {
        guard let selectedMetatileID else { return nil }
        return document.metatiles.first { $0.id == selectedMetatileID }?.tilesetSymbol
    }

    private var selectedAttributeText: String {
        guard let cell = session.selectedMapCell else { return "No metatile selected" }
        let attributes = MapBlockAttributes(rawValue: cell.rawValue)
        return "collision \(attributes.collision), elevation \(attributes.elevation)"
    }

    private var collisionBinding: Binding<Int> {
        Binding {
            guard let cell = session.selectedMapCell else { return 0 }
            return MapBlockAttributes(rawValue: cell.rawValue).collision
        } set: { value in
            session.updateSelectedBlockCollision(value)
        }
    }

    private var elevationBinding: Binding<Int> {
        Binding {
            guard let cell = session.selectedMapCell else { return 0 }
            return MapBlockAttributes(rawValue: cell.rawValue).elevation
        } set: { value in
            session.updateSelectedBlockElevation(value)
        }
    }

    private func visibilityBinding(for layer: MapEditorLayer) -> Binding<Bool> {
        Binding {
            session.mapOverlaySettings.state(for: layer).isVisible
        } set: { isVisible in
            session.setLayerVisible(layer, isVisible: isVisible)
        }
    }

    private func opacityBinding(for layer: MapEditorLayer) -> Binding<Double> {
        Binding {
            session.mapOverlaySettings.state(for: layer).opacity
        } set: { opacity in
            session.setLayerOpacity(layer, opacity: opacity)
        }
    }

    private func connectionRow(_ connection: MapSceneConnection) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: connection.isResolved ? "arrow.triangle.branch" : "exclamationmark.triangle")
                .foregroundStyle(connection.isResolved ? Color.secondary : Color.orange)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 3) {
                Text(connectionTitle(connection))
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text(connectionSubtitle(connection))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if let diagnostic = connection.diagnostic {
                    Text(diagnostic.message)
                        .font(.caption2)
                        .foregroundStyle(diagnostic.severity == .error ? .red : .orange)
                        .lineLimit(2)
                }
                ForEach(connection.diagnostics.filter { $0.id != connection.diagnostic?.id }.prefix(3)) { diagnostic in
                    Text(diagnostic.message)
                        .font(.caption2)
                        .foregroundStyle(diagnostic.severity == .error ? .red : .orange)
                        .lineLimit(2)
                }
            }

            Spacer()

            Button("Center", systemImage: "scope") {
                centerConnection(connection)
            }
            .labelStyle(.iconOnly)
            .accessibilityLabel("Center connection \(connection.index)")
            .disabled(connection.placementID == nil)

            Button("Offset -1", systemImage: "minus") {
                session.updateConnectionField(index: connection.index, key: "offset", value: "\(connection.offset - 1)")
            }
            .labelStyle(.iconOnly)
            .accessibilityLabel("Decrease connection offset \(connection.index)")

            Button("Offset +1", systemImage: "plus") {
                session.updateConnectionField(index: connection.index, key: "offset", value: "\(connection.offset + 1)")
            }
            .labelStyle(.iconOnly)
            .accessibilityLabel("Increase connection offset \(connection.index)")

            Button("Duplicate", systemImage: "plus.square.on.square") {
                session.duplicateConnection(index: connection.index)
            }
            .labelStyle(.iconOnly)
            .accessibilityLabel("Duplicate connection \(connection.index)")

            Button("Delete", systemImage: "trash", role: .destructive) {
                session.deleteConnection(index: connection.index)
            }
            .labelStyle(.iconOnly)
            .accessibilityLabel("Delete connection \(connection.index)")
        }
        .padding(.vertical, 2)
    }

    private func wildGroupRow(_ group: MapWildEncounterGroup, sourcePath: String, speciesIDs: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(group.label, systemImage: "leaf")
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("\(group.encounters.count) table\(group.encounters.count == 1 ? "" : "s")")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ForEach(group.encounters) { encounter in
                WildEncounterEditorRow(
                    encounter: encounter,
                    sourcePath: sourcePath,
                    session: session,
                    speciesIDs: speciesIDs
                )
            }
        }
        .padding(10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private func scriptSourceList(_ scriptIndex: MapScriptIndex) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(scriptIndex.sources) { source in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: source.exists ? "doc.text" : "doc.badge.exclamationmark")
                        .foregroundStyle(source.exists ? Color.secondary : Color.orange)
                        .frame(width: 16)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(source.path)
                            .font(.caption.weight(.semibold))
                            .lineLimit(2)
                            .textSelection(.enabled)
                        Text(source.role.title)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func scriptResolutionRows(_ resolution: MapScriptResolution) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            FactGrid(
                facts: [
                    Fact(label: "State", value: resolution.state.rawValue),
                    Fact(label: "Label", value: resolution.label.isEmpty ? "None" : resolution.label)
                ]
            )

            if let span = resolution.span {
                SourceLocationView(
                    source: SourceLocation(path: span.sourcePath, symbol: span.label, line: span.labelLine)
                )
            }

            ForEach(resolution.diagnostics.prefix(3)) { diagnostic in
                Label(diagnostic.message, systemImage: diagnostic.severity == .error ? "xmark.octagon" : "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(diagnostic.severity == .error ? .red : .orange)
            }
        }
    }

    @ViewBuilder
    private func tilesetFacts(title: String, tileset: TilesetAsset?) -> some View {
        if let tileset {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                FactGrid(
                    facts: [
                        Fact(label: "Symbol", value: tileset.symbol),
                        Fact(label: "Metatiles", value: "\(tileset.metatileCount)"),
                        Fact(label: "Image", value: tileset.tileImagePath ?? "Missing"),
                        Fact(label: "Attributes", value: tileset.metatileAttributesPath ?? "Missing")
                    ]
                )
            }
        } else {
            FactGrid(facts: [Fact(label: title, value: "Missing")])
        }
    }

    private func connectionTitle(_ connection: MapSceneConnection) -> String {
        let direction = connection.direction?.rawValue.capitalized ?? "Unknown"
        return "\(direction) #\(connection.index)"
    }

    private func connectionSubtitle(_ connection: MapSceneConnection) -> String {
        let target = connection.targetMapName ?? connection.targetMapID ?? "Unresolved"
        return "\(target), offset \(connection.offset)"
    }

    private func eventPositionText(_ event: MapEventDescriptor) -> String {
        guard let x = event.x, let y = event.y else { return "No position" }
        return "\(x), \(y)"
    }

    private func capacityFact(for kind: MapEventKind) -> String {
        guard let usage = document.eventCapacity.usages.first(where: { $0.kind == kind }) else {
            return "Unknown"
        }
        guard let limit = usage.limit else {
            return "\(usage.count)/?"
        }
        return usage.isOverLimit ? "\(usage.count)/\(limit) over" : "\(usage.count)/\(limit)"
    }

    private func centerConnection(_ connection: MapSceneConnection) {
        guard let placementID = connection.placementID,
              let placement = document.scene.placements.first(where: { $0.id == placementID })
        else {
            return
        }
        let centerX = CGFloat(placement.originX) + CGFloat(placement.width) / 2
        let centerY = CGFloat(placement.originY) + CGFloat(placement.height) / 2
        onSelectViewportCenter(centerX, centerY)
    }

    private var duplicationPlan: MapDuplicationPlan? {
        guard let catalog else { return nil }
        return MapWorkflowPlanner.planDuplication(
            catalog: catalog,
            sourceMapID: document.mapID,
            proposedMapID: normalizedDuplicateMapID,
            proposedMapName: normalizedDuplicateMapName
        )
    }

    private var workflowSnapshots: [MapWorkflowSourceSnapshot] {
        MapWorkflowPlanner.captureSourceSnapshots(
            rootPath: document.rootPath,
            paths: [document.mapSourcePath, document.blockdata.filepath] + [document.border?.filepath].compactMap(\.self)
        )
    }

    private var reloadDiagnostics: [Diagnostic] {
        MapWorkflowPlanner.externalChangeDiagnostics(rootPath: document.rootPath, snapshots: workflowSnapshots)
    }

    private var regionPreview: MapRegionPreviewMetadata {
        MapWorkflowPlanner.regionPreviewMetadata(
            for: MapDescriptor(
                id: document.mapID,
                name: document.mapName,
                sourcePath: document.mapSourcePath,
                groupID: nil,
                groupIndex: nil,
                mapIndexInGroup: nil,
                layout: document.layout.layoutID,
                layoutSlotIndex: document.layout.slotIndex,
                music: document.mapMetadata.music,
                mapType: document.mapMetadata.mapType,
                weather: document.mapMetadata.weather,
                regionMapSection: document.mapMetadata.regionMapSection,
                floorNumber: document.mapMetadata.floorNumber,
                sharedEventsMap: nil,
                sharedScriptsMap: nil
            )
        )
    }

    private var visualExportPlan: MapVisualExportPlan {
        MapWorkflowPlanner.planVisualExport(
            document: document,
            format: .png,
            fileStem: exportFileStem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : exportFileStem
        )
    }

    private var prefabPastePlan: MapPrefabPastePlan? {
        guard
            let prefabWidth = parsedInt(prefabWidth),
            let prefabHeight = parsedInt(prefabHeight),
            let x = parsedInt(prefabX),
            let y = parsedInt(prefabY)
        else { return nil }
        let prefab = MapBlockPrefab(
            name: prefabName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Prefab" : prefabName,
            width: prefabWidth,
            height: prefabHeight,
            rawValues: parsedUInt16List(prefabRawValues)
        )
        return MapWorkflowPlanner.planPrefabPaste(document: document, prefab: prefab, x: x, y: y)
    }

    private var normalizedDuplicateMapID: String {
        let trimmed = duplicateMapID.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "\(document.mapID)_COPY" : trimmed
    }

    private var normalizedDuplicateMapName: String {
        let trimmed = duplicateMapName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "\(document.mapName)_Copy" : trimmed
    }

    @ViewBuilder
    private func workflowPlanSummary(
        title: String,
        summary: String,
        diagnostics: [Diagnostic],
        reasons: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Text(summary)
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(diagnostics.prefix(3)) { diagnostic in
                workflowDiagnosticRow(diagnostic)
            }
            ForEach(Array(reasons.prefix(2).enumerated()), id: \.offset) { _, reason in
                Text(reason)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func workflowPathList(_ paths: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(paths.prefix(5).enumerated()), id: \.offset) { _, path in
                Text(path)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    private func workflowDiagnosticRow(_ diagnostic: Diagnostic) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: diagnostic.severity == .error ? "exclamationmark.triangle" : "info.circle")
            VStack(alignment: .leading, spacing: 2) {
                Text(diagnostic.code)
                    .font(.caption2.weight(.semibold))
                Text(diagnostic.message)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    private func stagePrefabPaste() {
        guard
            let plan = prefabPastePlan,
            plan.executionState.canApply,
            let operation = plan.operation,
            let x = operation.x,
            let y = operation.y,
            let width = operation.width,
            let height = operation.height,
            let rawValues = operation.rawValues
        else { return }
        session.pasteBlockPattern(x: x, y: y, width: width, height: height, target: operation.target ?? .layout, rawValues: rawValues)
    }

    private func parsedInt(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("0x") {
            return Int(trimmed.dropFirst(2), radix: 16)
        }
        return Int(trimmed)
    }

    private func parsedUInt16List(_ text: String) -> [UInt16] {
        text
            .split { $0 == "," || $0 == " " || $0 == "\n" || $0 == "\t" }
            .compactMap { token in
                let raw = String(token)
                guard let value = parsedInt(raw), (0...Int(UInt16.max)).contains(value) else {
                    return nil
                }
                return UInt16(value)
            }
    }

    private func canCopyTwoByTwo(from cell: MapCellSelection) -> Bool {
        cell.x + 1 < document.blockdata.width && cell.y + 1 < document.blockdata.height
    }

    private func stageTwoByTwoPrefab(from cell: MapCellSelection) {
        guard canCopyTwoByTwo(from: cell) else { return }
        let width = document.blockdata.width
        let values = [
            session.stagedMapBlockdataValues[cell.y * width + cell.x],
            session.stagedMapBlockdataValues[cell.y * width + cell.x + 1],
            session.stagedMapBlockdataValues[(cell.y + 1) * width + cell.x],
            session.stagedMapBlockdataValues[(cell.y + 1) * width + cell.x + 1]
        ]
        session.pasteBlockPattern(
            x: max(0, min(cell.x + 2, document.blockdata.width - 2)),
            y: cell.y,
            width: 2,
            height: 2,
            rawValues: values
        )
    }
}

private struct MapWorkbenchTabButton: View {
    let tab: MapWorkbenchTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: tab.systemImage)
                Text(tab.title)
                    .lineLimit(1)
            }
            .font(.caption.weight(isSelected ? .semibold : .regular))
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color.accentColor.opacity(0.16) : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.accessibilityLabel)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

private struct PlannedArea: Identifiable {
    var id: String { title }

    let title: String
    let detail: String
    let systemImage: String
}

private struct PlannedAreaList: View {
    let items: [PlannedArea]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: item.systemImage)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.caption.weight(.semibold))
                        Text(item.detail)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
    }
}

private struct HeaderFieldDraftRow: View {
    let title: String
    let key: String
    let onStage: (String, String) -> Void
    @State private var value: String

    init(title: String, key: String, value: String, onStage: @escaping (String, String) -> Void) {
        self.title = title
        self.key = key
        self.onStage = onStage
        _value = State(initialValue: value)
    }

    var body: some View {
        LabeledContent(title) {
            HStack {
                TextField(title, text: $value)
                    .textFieldStyle(.roundedBorder)
                Button("Stage", systemImage: "plus.rectangle.on.folder") {
                    onStage(key, value)
                }
                .labelStyle(.iconOnly)
                .help("Stage \(title) in the map header mutation plan")
            }
        }
    }
}

private struct WildEncounterEditorRow: View {
    let encounter: MapWildEncounterEntry
    let sourcePath: String
    @ObservedObject var session: MapEditorSession
    let speciesIDs: [String]

    @State private var encounterRate: String

    init(encounter: MapWildEncounterEntry, sourcePath: String, session: MapEditorSession, speciesIDs: [String]) {
        self.encounter = encounter
        self.sourcePath = sourcePath
        self.session = session
        self.speciesIDs = speciesIDs
        _encounterRate = State(initialValue: encounter.encounterRate.map(String.init) ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(encounter.encounterType)
                        .font(.caption.weight(.semibold))
                    if let baseLabel = encounter.baseLabel {
                        Text(baseLabel)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }

                if let diagnostic = slotCountDiagnostic {
                    Label(diagnostic.message, systemImage: "exclamationmark.triangle")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 4)
                }

                Spacer()

                TextField("Rate", text: $encounterRate)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 72)
                    .onSubmit { stageEncounterRate() }

                Button("Stage rate", systemImage: "checkmark.circle") {
                    stageEncounterRate()
                }
                .labelStyle(.iconOnly)
                .help("Stage the encounter rate in the mutation preview")
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("Slot").frame(width: 42, alignment: .leading)
                    Text("Species").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Min").frame(width: 58, alignment: .leading)
                    Text("Max").frame(width: 58, alignment: .leading)
                    Text("%").frame(width: 48, alignment: .trailing)
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

                ForEach(encounter.slots) { slot in
                    WildEncounterSlotEditorRow(slot: slot, sourcePath: sourcePath, session: session, speciesIDs: speciesIDs)
                }
            }

            Text(encounter.jsonPath.joined(separator: "."))
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .padding(.vertical, 6)
    }

    private func stageEncounterRate() {
        session.updateWildEncounterField(
            sourcePath: sourcePath,
            jsonPath: encounter.rateJSONPath,
            key: "encounter_rate",
            value: encounterRate
        )
    }

    private var slotCountDiagnostic: Diagnostic? {
        guard let expected = encounter.expectedSlotCount, encounter.slots.count != expected else { return nil }
        return Diagnostic(
            severity: .warning,
            code: "WILD_ENCOUNTER_SLOT_COUNT_MISMATCH",
            message: "Expected \(expected) slots, found \(encounter.slots.count).",
            span: SourceSpan(relativePath: sourcePath, startLine: 1)
        )
    }
}

private struct WildEncounterSlotEditorRow: View {
    let slot: MapWildEncounterSlot
    let sourcePath: String
    @ObservedObject var session: MapEditorSession
    let speciesIDs: [String]

    @State private var species: String
    @State private var minLevel: String
    @State private var maxLevel: String

    init(slot: MapWildEncounterSlot, sourcePath: String, session: MapEditorSession, speciesIDs: [String]) {
        self.slot = slot
        self.sourcePath = sourcePath
        self.session = session
        self.speciesIDs = speciesIDs
        _species = State(initialValue: slot.species)
        _minLevel = State(initialValue: slot.minLevel.map(String.init) ?? "")
        _maxLevel = State(initialValue: slot.maxLevel.map(String.init) ?? "")
    }

    var body: some View {
        HStack(spacing: 6) {
            Text("#\(slot.index + 1)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 42, alignment: .leading)

            Picker("Species", selection: $species) {
                if !speciesIDs.contains(species) {
                    Text(species).tag(species)
                }
                ForEach(speciesIDs, id: \.self) { id in
                    Text(id).tag(id)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .onChange(of: species) { _, newValue in
                stage(key: "species", value: newValue)
            }

            TextField("Min", text: $minLevel)
                .textFieldStyle(.roundedBorder)
                .foregroundStyle(isLevelRangeValid ? Color.primary : Color.red)
                .frame(width: 58)
                .onSubmit { if isLevelRangeValid { stage(key: "min_level", value: minLevel) } }

            TextField("Max", text: $maxLevel)
                .textFieldStyle(.roundedBorder)
                .foregroundStyle(isLevelRangeValid ? Color.primary : Color.red)
                .frame(width: 58)
                .onSubmit { if isLevelRangeValid { stage(key: "max_level", value: maxLevel) } }

            Text(slot.rate.map { "\($0)" } ?? "-")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .trailing)
            Button("Stage slot", systemImage: isLevelRangeValid ? "checkmark.circle" : "exclamationmark.triangle") {
                stage(key: "species", value: species)
                if isLevelRangeValid {
                    stage(key: "min_level", value: minLevel)
                    stage(key: "max_level", value: maxLevel)
                }
            }
            .labelStyle(.iconOnly)
            .foregroundStyle(isLevelRangeValid ? Color.accentColor : Color.red)
            .help(isLevelRangeValid ? "Stage this wild encounter slot in the mutation preview" : "Min level must be less than or equal to max level")
        }
    }

    private var isLevelRangeValid: Bool {
        let min = Int(minLevel.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let max = Int(maxLevel.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 255
        return min <= max
    }

    private func stage(key: String, value: String) {
        session.updateWildEncounterField(
            sourcePath: sourcePath,
            jsonPath: slot.jsonPath,
            key: key,
            value: value
        )
    }
}
