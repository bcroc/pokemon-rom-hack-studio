import SwiftUI

struct MapEditorView: View {
    let records: [WorkbenchRecord]
    let catalog: MapCatalogViewState?
    @Binding var selectedMapID: String

    init(
        records: [WorkbenchRecord],
        catalog: MapCatalogViewState? = nil,
        selectedMapID: Binding<String> = .constant("")
    ) {
        self.records = records
        self.catalog = catalog
        _selectedMapID = selectedMapID
    }

    var body: some View {
        if let catalog {
            MapCatalogView(catalog: catalog, selectedMapID: $selectedMapID)
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
}

private struct MapCatalogView: View {
    let catalog: MapCatalogViewState
    @Binding var selectedMapID: String

    private var selectedMap: MapSummaryViewState? {
        catalog.maps.first { $0.id == selectedMapID } ?? catalog.maps.first
    }

    var body: some View {
        HSplitView {
            List(selection: $selectedMapID) {
                ForEach(catalog.groups) { group in
                    Section(group.name) {
                        ForEach(maps(in: group)) { map in
                            MapSidebarRow(map: map)
                                .tag(map.id)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 240, idealWidth: 280, maxWidth: 360)

            MapDetailView(map: selectedMap, catalog: catalog)
                .frame(minWidth: 520, maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Maps")
        .onAppear(perform: reconcileSelection)
        .onChange(of: catalog.id) { _ in
            reconcileSelection()
        }
    }

    private func maps(in group: MapGroupViewState) -> [MapSummaryViewState] {
        let byID = Dictionary(uniqueKeysWithValues: catalog.maps.map { ($0.id, $0) })
        return group.mapIDs.compactMap { byID[$0] }
    }

    private func reconcileSelection() {
        guard let firstID = catalog.maps.first?.id else {
            selectedMapID = ""
            return
        }

        if !catalog.maps.contains(where: { $0.id == selectedMapID }) {
            selectedMapID = firstID
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

private struct MapDetailView: View {
    let map: MapSummaryViewState?
    let catalog: MapCatalogViewState

    var body: some View {
        if let map {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header(for: map)
                    metrics(for: map)
                    structure(for: map)
                    sources(for: map)
                    connections(for: map)
                    metatileGrid(for: map)

                    if !map.notes.isEmpty {
                        NotesList(notes: map.notes)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            ContentUnavailableView(
                "No Map Selected",
                systemImage: "map",
                description: Text("The selected project has no map catalog entries.")
            )
        }
    }

    private func header(for map: MapSummaryViewState) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(map.name)
                .font(.title.weight(.semibold))
            HStack(spacing: 10) {
                Label(map.mapID, systemImage: "number")
                Label(map.groupName, systemImage: "folder")
                if let layout = map.layout {
                    Label("\(layout.width)x\(layout.height)", systemImage: "square.grid.3x3")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
        }
    }

    private func metrics(for map: MapSummaryViewState) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 126), spacing: 12)], spacing: 12) {
            MetricCard(title: "Objects", value: "\(map.eventCounts.objectEvents)", detail: "object events")
            MetricCard(title: "Warps", value: "\(map.eventCounts.warpEvents)", detail: "warp events")
            MetricCard(title: "Coord", value: "\(map.eventCounts.coordEvents)", detail: "coord events")
            MetricCard(title: "BG", value: "\(map.eventCounts.bgEvents)", detail: "bg events")
        }
    }

    private func structure(for map: MapSummaryViewState) -> some View {
        EditorSection(title: "Map Structure") {
            FactGrid(
                facts: [
                    Fact(label: "Map ID", value: map.mapID),
                    Fact(label: "Layout", value: map.layout?.name ?? "Missing"),
                    Fact(label: "Music", value: map.music ?? "None"),
                    Fact(label: "Map Type", value: map.mapType ?? "None"),
                    Fact(label: "Weather", value: map.weather ?? "None"),
                    Fact(label: "Region", value: map.regionMapSection ?? "None"),
                    Fact(label: "Primary Tileset", value: map.layout?.primaryTileset ?? "Unknown"),
                    Fact(label: "Secondary Tileset", value: map.layout?.secondaryTileset ?? "Unknown")
                ]
            )
        }
    }

    private func sources(for map: MapSummaryViewState) -> some View {
        EditorSection(title: "Source Links") {
            VStack(alignment: .leading, spacing: 10) {
                SourceLocationView(source: map.source)

                if let layout = map.layout {
                    SourceLocationView(
                        source: SourceLocation(
                            path: layout.blockdataFilepath ?? "data/layouts/layouts.json",
                            symbol: layout.id,
                            line: 1
                        )
                    )
                }
            }
        }
    }

    private func connections(for map: MapSummaryViewState) -> some View {
        EditorSection(title: "Connections") {
            if map.connections.isEmpty {
                Label("No map connections are declared.", systemImage: "minus.circle")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(map.connections) { connection in
                        HStack {
                            Label(connection.direction, systemImage: systemImage(for: connection.direction))
                                .foregroundStyle(.secondary)
                                .frame(width: 110, alignment: .leading)
                            Text(connection.map)
                                .fontWeight(.medium)
                                .textSelection(.enabled)
                            Spacer()
                            Text("offset \(connection.offset)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func metatileGrid(for map: MapSummaryViewState) -> some View {
        EditorSection(title: "Metatile IDs") {
            if let preview = map.layout?.blockPreview, !preview.metatileIDs.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ScrollView([.horizontal, .vertical]) {
                        Grid(horizontalSpacing: 2, verticalSpacing: 2) {
                            ForEach(0..<preview.visibleHeight, id: \.self) { row in
                                GridRow {
                                    ForEach(0..<preview.visibleWidth, id: \.self) { column in
                                        let index = row * preview.width + column
                                        let label = preview.metatileIDs.indices.contains(index)
                                            ? String(format: "%03X", preview.metatileIDs[index])
                                            : "--"
                                        Text(label)
                                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                                            .frame(width: 34, height: 24)
                                            .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                                    }
                                }
                            }
                        }
                        .padding(10)
                    }
                    .frame(minHeight: 220, maxHeight: 360)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))

                    Text(previewCaption(preview))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Label("No metatile preview is available.", systemImage: "minus.circle")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func previewCaption(_ preview: LayoutBlockPreviewViewState) -> String {
        var caption = "Showing \(preview.visibleWidth)x\(preview.visibleHeight) of \(preview.width)x\(preview.height) metatile IDs"
        if let diagnostic = preview.diagnostic {
            caption += " · \(diagnostic)"
        }
        return caption
    }

    private func systemImage(for direction: String) -> String {
        switch direction.lowercased() {
        case "up", "north":
            "arrow.up"
        case "down", "south":
            "arrow.down"
        case "left", "west":
            "arrow.left"
        case "right", "east":
            "arrow.right"
        default:
            "arrow.left.and.right"
        }
    }
}
