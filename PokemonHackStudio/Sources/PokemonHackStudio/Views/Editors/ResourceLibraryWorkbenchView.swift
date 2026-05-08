import SwiftUI

struct ResourceLibraryWorkbenchView: View {
    let library: ResourceLibraryViewState?
    let entries: [ResourceLibraryEntryViewState]
    let assetCatalog: ResourceAssetCatalogViewState?
    let assets: [ResourceAssetRowViewState]
    let assetLoadStatus: ResourceAssetCatalogLoadStatus
    @Binding var selectedAssetID: ResourceAssetRowViewState.ID?
    @Binding var mode: ResourceLibraryMode
    @Binding var selectedCategory: String
    @Binding var sortMode: ResourceAssetSortMode
    let onLoadAssetCatalog: () -> Void
    let onNavigateToAsset: (ResourceAssetRowViewState) -> Void

    @ViewBuilder
    var body: some View {
        if library != nil || assetCatalog != nil {
            GeometryReader { proxy in
                let layoutMode = WorkbenchLayoutMode(contentWidth: proxy.size.width)

                VStack(alignment: .leading, spacing: 0) {
                    resourceMetrics(layoutMode: layoutMode)

                    switch mode {
                    case .assets:
                        assetList(layoutMode: layoutMode)
                    case .entries:
                        entryList(layoutMode: layoutMode)
                    }
                }
            }
            .navigationTitle("Resources")
            .onAppear {
                if mode == .assets {
                    onLoadAssetCatalog()
                }
            }
            .onChange(of: mode) { _, newMode in
                if newMode == .assets {
                    onLoadAssetCatalog()
                }
            }
        } else {
            EmptyModuleView(title: "Resources")
        }
    }

    private func resourceMetrics(layoutMode: WorkbenchLayoutMode) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: layoutMode.isCompact ? 145 : 170), spacing: 12)], spacing: 12) {
                MetricCard(title: "Entries", value: "\(library?.entryCount ?? 0)", detail: "\(library?.parsedCount ?? 0) parsed")
                MetricCard(title: "Assets", value: "\(assetCatalog?.assetCount ?? 0)", detail: assetCatalog?.profile ?? "No project")
                MetricCard(title: "GBA ROMs", value: "\(gbaROMCount)", detail: "Top-level inputs")
                MetricCard(title: "Availability", value: "\(availabilityProblemCount)", detail: assetLoadStatus.label)
                MetricCard(title: "Diagnostics", value: "\(diagnosticCount)", detail: "Library and assets")
            }
        }
        .padding(layoutMode.isCompact ? 14 : 24)
        .background(.regularMaterial)
    }

    private func entryList(layoutMode: WorkbenchLayoutMode) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No Resources",
                        systemImage: "externaldrive.badge.questionmark",
                        description: Text("No resources match the current search.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 240)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(entries) { entry in
                            ResourceLibraryDetailRow(entry: entry)
                        }
                    }
                }
            }
            .padding(layoutMode.isCompact ? 14 : 24)
        }
    }

    private func assetList(layoutMode: WorkbenchLayoutMode) -> some View {
        VStack(spacing: 0) {
            if case .loading = assetLoadStatus {
                ProgressView("Loading asset catalog...")
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(.quaternary.opacity(0.18))
            }

            if assets.isEmpty {
                ContentUnavailableView(
                    "No Assets",
                    systemImage: "tray",
                    description: Text(emptyAssetDescription)
                )
                .frame(maxWidth: .infinity, minHeight: 260)
            } else {
                ScrollView {
                    ResourceAssetDetailPane(asset: selectedAsset, onNavigate: onNavigateToAsset)
                        .padding(layoutMode.isCompact ? 14 : 24)
                }
            }
        }
    }

    private var compactAssetList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(assets) { asset in
                    VStack(alignment: .leading, spacing: 0) {
                        ResourceAssetRow(asset: asset, onNavigate: onNavigateToAsset)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedAssetID = selectedAssetID == asset.id ? nil : asset.id
                            }

                        if selectedAssetID == asset.id {
                            ResourceAssetDetailPane(asset: asset, onNavigate: onNavigateToAsset)
                                .frame(maxWidth: .infinity, minHeight: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(.top, 8)
                        }
                    }
                }
            }
            .padding(14)
        }
    }

    private var selectedAsset: ResourceAssetRowViewState? {
        if let selectedAssetID, let asset = assets.first(where: { $0.id == selectedAssetID }) {
            return asset
        }
        return assets.first
    }

    private var categoryOptions: [String] {
        [Self.allCategories] + (assetCatalog?.categoryTitles ?? [])
    }

    private var diagnosticCount: Int {
        (library?.allDiagnostics.count ?? 0) + (assetCatalog?.diagnostics.count ?? 0)
    }

    private var gbaROMCount: Int {
        library?.entries.filter { $0.platform == "gbaROM" }.count ?? 0
    }

    private var availabilityProblemCount: Int {
        assetCatalog?.rows.filter(\.affectsResourceAvailability).count ?? 0
    }

    private var emptyAssetDescription: String {
        switch assetLoadStatus {
        case .idle:
            "The selected project's asset catalog has not loaded yet."
        case .loading:
            "The selected project's asset catalog is still loading."
        case .loaded:
            "No catalog assets match the current filters."
        case .failed(let message):
            message
        }
    }

    private func iconName(for category: String) -> String {
        switch category {
        case "maps":
            "map"
        case "layouts":
            "square.grid.3x3"
        case "scripts":
            "curlybraces"
        case "text":
            "text.quote"
        case "species", "moves", "learnsets", "evolutions", "pokedex":
            "sparkles"
        case "trainers":
            "person.2"
        case "items":
            "shippingbox"
        case "graphics", "palettes", "tilesets":
            "photo"
        case "audio":
            "waveform"
        case "rom", "media":
            "memorychip"
        case "generated":
            "hammer"
        default:
            "doc"
        }
    }

    private static let allCategories = WorkbenchStore.allResourceAssetCategories
}

private struct ResourceLibraryDetailRow: View {
    let entry: ResourceLibraryEntryViewState
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 14) {
                FactGrid(facts: entryFacts)

                if !entry.items.isEmpty {
                    EditorSection(title: "Resource Items") {
                        VStack(spacing: 8) {
                            ForEach(entry.items) { item in
                                ResourceLibraryItemRow(item: item)
                            }
                        }
                    }
                }

                if !entry.diagnostics.isEmpty {
                    EditorSection(title: "Diagnostics") {
                        VStack(spacing: 8) {
                            ForEach(entry.diagnostics) { diagnostic in
                                IndexedDiagnosticRowView(diagnostic: diagnostic)
                            }
                        }
                    }
                }
            }
            .padding(.top, 12)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(entry.title)
                            .font(.headline)
                            .lineLimit(1)
                        StatusPill(state: entry.status)
                        ResourceTag(text: entry.platform)
                    }

                    Text("\(entry.variantSummary) · \(entry.moduleSummary)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Text(entry.path)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .textSelection(.enabled)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(entry.resourceCount)")
                        .font(.headline)
                    Text(entry.parseStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if entry.diagnosticCount > 0 {
                        Text("\(entry.diagnosticCount) diagnostics")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var entryFacts: [Fact] {
        [
            Fact(label: "Family", value: entry.family),
            Fact(label: "Profile", value: entry.profile),
            Fact(label: "Role", value: entry.role),
            Fact(label: "Write Policy", value: entry.writePolicy),
            Fact(label: "Items", value: "\(entry.items.count)"),
            Fact(label: "Diagnostics", value: "\(entry.diagnosticCount)")
        ]
    }

    private var iconName: String {
        switch entry.platform {
        case "gbaSource":
            "folder"
        case "gbaROM":
            "memorychip"
        case "gameCube":
            "opticaldisc"
        default:
            "questionmark.folder"
        }
    }
}

private struct ResourceLibraryItemRow: View {
    let item: ResourceLibraryItemViewState

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName)
                .foregroundStyle(.secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    ResourceTag(text: item.kind)
                    ResourceTag(text: item.category)
                }

                Text(item.path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .textSelection(.enabled)

                Text("\(item.locationSummary) · \(item.sizeSummary) · \(item.checksumSummary)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)
        }
        .padding(10)
        .background(.quaternary.opacity(0.28), in: RoundedRectangle(cornerRadius: 8))
    }

    private var iconName: String {
        switch item.category {
        case "GBA ROM":
            "memorychip"
        case "Pokemon Data", "pokemonTable":
            "sparkles"
        case "Text", "text":
            "text.quote"
        case "Graphics", "texture", "model":
            "photo"
        case "Audio", "audio":
            "waveform"
        default:
            "doc"
        }
    }
}

private struct ResourceAssetDetailPane: View {
    let asset: ResourceAssetRowViewState?
    let onNavigate: (ResourceAssetRowViewState) -> Void

    var body: some View {
        ScrollView {
            if let asset {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(asset.title)
                                .font(.headline)
                                .lineLimit(2)
                            Spacer(minLength: 8)
                            StatusPill(state: asset.status)
                        }

                        Text(asset.path)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .textSelection(.enabled)

                        Text(asset.availabilitySummary)
                            .font(.caption)
                            .foregroundStyle(asset.affectsResourceAvailability ? .orange : .secondary)
                    }

                    FactGrid(facts: detailFacts(for: asset))

                    if !asset.facts.isEmpty {
                        EditorSection(title: "Facts") {
                            FactGrid(facts: asset.facts)
                        }
                    }

                    if !asset.diagnostics.isEmpty {
                        EditorSection(title: "Diagnostics") {
                            VStack(spacing: 8) {
                                ForEach(asset.diagnostics) { diagnostic in
                                    IndexedDiagnosticRowView(diagnostic: diagnostic)
                                }
                            }
                        }
                    }

                    if let targetModule = asset.targetModule {
                        Button {
                            onNavigate(asset)
                        } label: {
                            Label("Open in \(targetModule.title)", systemImage: "arrow.right.circle")
                        }
                    }
                }
                .padding(18)
            } else {
                ContentUnavailableView(
                    "No Asset Selected",
                    systemImage: "sidebar.right",
                    description: Text("Select an asset to inspect its source span, diagnostics, and navigation target.")
                )
                .frame(maxWidth: .infinity, minHeight: 260)
                .padding(18)
            }
        }
        .background(.regularMaterial)
    }

    private func detailFacts(for asset: ResourceAssetRowViewState) -> [Fact] {
        [
            Fact(label: "Category", value: asset.category),
            Fact(label: "Kind", value: asset.kind),
            Fact(label: "Role", value: asset.role),
            Fact(label: "Availability", value: asset.availability),
            Fact(label: "Size", value: asset.sizeSummary),
            Fact(label: "Checksum", value: asset.checksumSummary),
            Fact(label: "Source Line", value: "\(asset.source.line)")
        ]
    }
}

private struct ResourceAssetRow: View {
    let asset: ResourceAssetRowViewState
    let onNavigate: (ResourceAssetRowViewState) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text(asset.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    StatusPill(state: asset.status)
                    ResourceTag(text: asset.category)
                    ResourceTag(text: asset.kind)
                }

                Text(asset.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(asset.path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .textSelection(.enabled)

                HStack(spacing: 8) {
                    Text("\(asset.role) · \(asset.sizeSummary) · \(asset.checksumSummary)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)

                    if let targetModule = asset.targetModule {
                        Text("Target: \(targetModule.title)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                if !asset.facts.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(asset.facts.prefix(4)) { fact in
                            ResourceTag(text: "\(fact.label): \(fact.value)")
                        }
                    }
                }
            }

            Spacer(minLength: 8)

            if asset.targetModule != nil {
                Button {
                    onNavigate(asset)
                } label: {
                    Image(systemName: "arrow.right.circle")
                }
                .buttonStyle(.borderless)
                .help("Open related editor module")
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.24), in: RoundedRectangle(cornerRadius: 8))
    }

    private var iconName: String {
        switch asset.category {
        case "maps":
            "map"
        case "layouts":
            "square.grid.3x3"
        case "scripts":
            "curlybraces"
        case "text":
            "text.quote"
        case "species", "moves", "learnsets", "evolutions", "pokedex":
            "sparkles"
        case "trainers":
            "person.2"
        case "items":
            "shippingbox"
        case "graphics", "palettes", "tilesets":
            "photo"
        case "audio":
            "waveform"
        case "rom", "media":
            "memorychip"
        case "generated":
            "hammer"
        default:
            "doc"
        }
    }
}

private struct ResourceTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.secondary.opacity(0.12), in: Capsule())
            .foregroundStyle(.secondary)
    }
}
