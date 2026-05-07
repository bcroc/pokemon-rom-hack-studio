import SwiftUI

struct MapBrowserView: View {
    let catalog: MapCatalogViewState
    let selectedMapID: String
    @Binding var searchText: String
    let onSelectMap: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            browserHeader
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

            Divider()

            if filteredGroups.isEmpty {
                ContentUnavailableView(
                    "No Maps",
                    systemImage: "magnifyingglass",
                    description: Text("No maps match the current search.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: mapSelection) {
                    ForEach(filteredGroups) { group in
                        Section(group.name) {
                            ForEach(group.maps) { map in
                                MapSidebarRow(map: map)
                                    .tag(map.id)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .accessibilityLabel("Map browser")
    }

    private var browserHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search maps", text: $searchText)
                .textFieldStyle(.roundedBorder)

            if !searchText.isEmpty {
                Button("Clear", systemImage: "xmark.circle.fill") {
                    searchText = ""
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Clear map search")
            }
        }
    }

    private var mapSelection: Binding<String> {
        Binding {
            selectedMapID
        } set: { mapID in
            onSelectMap(mapID)
        }
    }

    private var filteredGroups: [MapBrowserGroup] {
        let byID = Dictionary(uniqueKeysWithValues: catalog.maps.map { ($0.id, $0) })
        return catalog.groups.compactMap { group in
            let maps = group.mapIDs
                .compactMap { byID[$0] }
                .filter { matches($0, in: group) }
            guard !maps.isEmpty else { return nil }
            return MapBrowserGroup(id: group.id, name: group.name, maps: maps)
        }
    }

    private func matches(_ map: MapSummaryViewState, in group: MapGroupViewState) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        let haystack = [
            map.name,
            map.mapID,
            group.name,
            map.groupName,
            map.layout?.name,
            map.mapType,
            map.weather,
            map.regionMapSection
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        return haystack.localizedCaseInsensitiveContains(query)
    }
}

private struct MapBrowserGroup: Identifiable {
    let id: String
    let name: String
    let maps: [MapSummaryViewState]
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
