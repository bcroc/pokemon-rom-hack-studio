import PokemonHackCore
import SwiftUI

struct ResourceLibraryWorkbenchView: View {
    let library: ResourceLibraryViewState?
    let entries: [ResourceLibraryEntryViewState]
    let assetCatalog: ResourceAssetCatalogViewState?
    let romInspector: BinaryROMInspectorReport?
    let gameCubeEntry: ResourceLibraryEntryViewState?
    let gameCubeLoadStatus: GameCubeResourceLoadStatus
    let assets: [ResourceAssetRowViewState]
    let assetLoadStatus: ResourceAssetCatalogLoadStatus
    @Binding var gameCubeResourcePath: String
    @Binding var selectedAssetID: ResourceAssetRowViewState.ID?
    @Binding var mode: ResourceLibraryMode
    @Binding var selectedCategory: String
    @Binding var sortMode: ResourceAssetSortMode
    let onChooseGameCubeResource: () -> Void
    let onLoadGameCubeResource: () -> Void
    let onLoadAssetCatalog: () -> Void
    let onNavigateToAsset: (ResourceAssetRowViewState) -> Void
    let ndsDataEditor: NDSDataResourceEditorViewState?
    let onUpdateNDSDataDraft: (String) -> Void
    let onUpdateNDSDataSemanticField: (String, String) -> Void
    let onPreviewNDSDataMutationPlan: () -> Void
    let onApplyNDSDataMutationPlan: () -> Void
    let onDiscardNDSDataEdits: () -> Void

    @ViewBuilder
    var body: some View {
        if library != nil || assetCatalog != nil || gameCubeEntry != nil {
            GeometryReader { proxy in
                let layoutMode = WorkbenchLayoutMode(contentWidth: proxy.size.width)

                VStack(alignment: .leading, spacing: 0) {
                    resourceMetrics(layoutMode: layoutMode)
                    gameCubeResourceControls(layoutMode: layoutMode)
                    if let romInspector {
                        romInspectorSummary(romInspector, layoutMode: layoutMode)
                    }

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
            GeometryReader { proxy in
                let layoutMode = WorkbenchLayoutMode(contentWidth: proxy.size.width)

                VStack(alignment: .leading, spacing: 0) {
                    gameCubeResourceControls(layoutMode: layoutMode)
                    EmptyModuleView(title: "Resources")
                }
            }
        }
    }

    private func resourceMetrics(layoutMode: WorkbenchLayoutMode) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: layoutMode.isCompact ? 145 : 170), spacing: 12)], spacing: 12) {
                MetricCard(title: "Entries", value: "\(library?.entryCount ?? 0)", detail: "\(library?.parsedCount ?? 0) parsed")
                MetricCard(title: "Assets", value: "\(assetCatalog?.assetCount ?? 0)", detail: assetCatalog?.profile ?? "No project")
                MetricCard(title: "GameCube", value: "\(gameCubeEntry?.resourceCount ?? 0)", detail: gameCubeLoadStatus.label)
                MetricCard(title: "Source Roots", value: "\(sourceRootCount)", detail: "GBA/NDS sources")
                MetricCard(title: "ROM Inputs", value: "\(romInputCount)", detail: "Top-level GBA/NDS")
                MetricCard(title: "Availability", value: "\(availabilityProblemCount)", detail: assetLoadStatus.label)
                MetricCard(title: "Diagnostics", value: "\(diagnosticCount)", detail: "Library and assets")
            }
        }
        .padding(layoutMode.isCompact ? 14 : 24)
        .background(.regularMaterial)
    }

    private func gameCubeResourceControls(layoutMode: WorkbenchLayoutMode) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                TextField("GameCube .iso or .gcm path", text: $gameCubeResourcePath)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onSubmit {
                        onLoadGameCubeResource()
                    }

                Button {
                    onChooseGameCubeResource()
                } label: {
                    Label("Choose", systemImage: "folder")
                }

                Button {
                    onLoadGameCubeResource()
                } label: {
                    Label("Load", systemImage: "opticaldisc")
                }
                .disabled(gameCubeResourcePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            HStack(spacing: 8) {
                StatusPill(state: gameCubeLoadStatus.validationState)
                Text(gameCubeLoadStatus.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, layoutMode.isCompact ? 14 : 24)
        .padding(.vertical, 12)
        .background(.thinMaterial)
    }

    private func romInspectorSummary(_ report: BinaryROMInspectorReport, layoutMode: WorkbenchLayoutMode) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "memorychip")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(report.graph.image.title ?? report.resourceEntry.title)
                            .font(.headline)
                            .lineLimit(1)
                        StatusPill(state: report.diagnostics.contains { $0.severity == .error } ? .error : .valid)
                        ResourceTag(text: report.isReadOnly ? "read-only" : report.projectIndex.writePolicy.rawValue)
                    }

                    Text("Standalone GBA ROM inspector")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(report.projectIndex.root.path)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }

                Spacer(minLength: 12)
            }

            FactGrid(facts: romInspectorFacts(report))
        }
        .padding(layoutMode.isCompact ? 14 : 18)
        .background(.thinMaterial)
    }

    private func romInspectorFacts(_ report: BinaryROMInspectorReport) -> [Fact] {
        [
            Fact(label: "Game Code", value: report.graph.image.gameCode ?? "Unavailable"),
            Fact(label: "Size", value: "\(report.graph.image.size) bytes"),
            Fact(label: "Pointers", value: "\(report.graph.pointerCandidates.count) accepted"),
            Fact(label: "Rejected", value: "\(report.graph.rejectedPointerCandidates.count)"),
            Fact(label: "Free Space", value: "\(report.graph.freeSpaceRanges.count) range(s)"),
            Fact(label: "Assets", value: "\(report.assetCatalog.assetCount)"),
            Fact(label: "Playtest", value: report.playtestReport.isRunnable ? "Runnable" : "Preview only"),
            Fact(label: "Diagnostics", value: "\(report.diagnostics.count)")
        ]
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
                    ResourceAssetDetailPane(
                        asset: selectedAsset,
                        onNavigate: onNavigateToAsset,
                        ndsDataEditor: ndsDataEditor,
                        onUpdateNDSDataDraft: onUpdateNDSDataDraft,
                        onUpdateNDSDataSemanticField: onUpdateNDSDataSemanticField,
                        onPreviewNDSDataMutationPlan: onPreviewNDSDataMutationPlan,
                        onApplyNDSDataMutationPlan: onApplyNDSDataMutationPlan,
                        onDiscardNDSDataEdits: onDiscardNDSDataEdits
                    )
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
                            ResourceAssetDetailPane(
                                asset: asset,
                                onNavigate: onNavigateToAsset,
                                ndsDataEditor: selectedAssetID == asset.id ? ndsDataEditor : nil,
                                onUpdateNDSDataDraft: onUpdateNDSDataDraft,
                                onUpdateNDSDataSemanticField: onUpdateNDSDataSemanticField,
                                onPreviewNDSDataMutationPlan: onPreviewNDSDataMutationPlan,
                                onApplyNDSDataMutationPlan: onApplyNDSDataMutationPlan,
                                onDiscardNDSDataEdits: onDiscardNDSDataEdits
                            )
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
        (library?.allDiagnostics.count ?? 0)
            + (gameCubeEntry?.diagnostics.count ?? 0)
            + (assetCatalog?.diagnostics.count ?? 0)
    }

    private var romInputCount: Int {
        library?.entries.filter { $0.platform == "gbaROM" || $0.platform == "ndsROM" }.count ?? 0
    }

    private var sourceRootCount: Int {
        library?.entries.filter { $0.platform == "gbaSource" || $0.platform == "ndsSource" }.count ?? 0
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
                        ResourceTag(text: entry.role)
                        ResourceTag(text: entry.writePolicy)
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
        case "ndsSource":
            "folder.badge.gearshape"
        case "gbaROM":
            "memorychip"
        case "ndsROM":
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
        case "GBA ROM", "NDS ROM":
            "memorychip"
        case "NDS Header":
            "info.circle"
        case "NitroFS Folder":
            "folder"
        case "NitroFS File", "NARC Archive", "NARC Member":
            "shippingbox"
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
    let ndsDataEditor: NDSDataResourceEditorViewState?
    let onUpdateNDSDataDraft: (String) -> Void
    let onUpdateNDSDataSemanticField: (String, String) -> Void
    let onPreviewNDSDataMutationPlan: () -> Void
    let onApplyNDSDataMutationPlan: () -> Void
    let onDiscardNDSDataEdits: () -> Void

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

                    if asset.id.contains(":nds-data:") {
                        NDSDataRecordEditor(
                            editor: ndsDataEditor,
                            onUpdateDraft: onUpdateNDSDataDraft,
                            onUpdateSemanticField: onUpdateNDSDataSemanticField,
                            onPreview: onPreviewNDSDataMutationPlan,
                            onApply: onApplyNDSDataMutationPlan,
                            onDiscard: onDiscardNDSDataEdits
                        )
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

private struct NDSDataRecordEditor: View {
    let editor: NDSDataResourceEditorViewState?
    let onUpdateDraft: (String) -> Void
    let onUpdateSemanticField: (String, String) -> Void
    let onPreview: () -> Void
    let onApply: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        EditorSection(title: "NDS Data Record") {
            if let editor {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        ResourceTag(text: editor.recordID)
                        if editor.isDirty {
                            ResourceTag(text: "draft")
                        }
                        Spacer()
                        Button("Preview", systemImage: "doc.text.magnifyingglass") {
                            onPreview()
                        }
                        .disabled(!editor.canPreview)
                        .help(editor.blockedReason ?? "Preview NDS data source mutation")

                        Button("Apply", systemImage: "checkmark.seal") {
                            onApply()
                        }
                        .disabled(!editor.canApply)
                        .help(editor.applyBlockedReason ?? "Apply previewed NDS data source mutation")

                        Button("Discard", systemImage: "trash") {
                            onDiscard()
                        }
                        .disabled(!editor.canDiscard)
                    }

                    if !editor.semanticFields.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Semantic Fields")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], alignment: .leading, spacing: 8) {
                                ForEach(editor.semanticFields) { field in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(field.label)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                        TextField(field.valueKind, text: Binding(
                                            get: { field.value },
                                            set: { onUpdateSemanticField(field.key, $0) }
                                        ))
                                        .textFieldStyle(.roundedBorder)
                                        .disabled(!editor.canEdit)
                                    }
                                }
                            }
                        }
                    }

                    TextEditor(text: Binding(
                        get: { editor.text },
                        set: { onUpdateDraft($0) }
                    ))
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 220)
                    .scrollContentBackground(.hidden)
                    .background(.quaternary.opacity(0.22), in: RoundedRectangle(cornerRadius: 8))
                    .disabled(!editor.canEdit)
                    .opacity(editor.canEdit ? 1 : 0.72)

                    if let blockedReason = editor.blockedReason, !editor.canPreview {
                        Label(blockedReason, systemImage: "lock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Label("This NDS data row is read-only in the current source-backed editor slice.", systemImage: "lock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
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
