import PokemonHackCore
import SwiftUI

struct ResourceLibraryWorkbenchView: View {
    let library: ResourceLibraryViewState?
    let entries: [ResourceLibraryEntryViewState]
    let assetCatalog: ResourceAssetCatalogViewState?
    let romInspector: BinaryROMInspectorReport?
    let gameCubeEntry: ResourceLibraryEntryViewState?
    let gameCubeLoadStatus: GameCubeResourceLoadStatus
    let loadingResourceEntryID: ResourceLibraryEntryViewState.ID?
    let assets: [ResourceAssetRowViewState]
    let selectedAsset: ResourceAssetRowViewState?
    let assetGroups: [ResourceAssetWorkflowGroup]
    let assetLoadStatus: ResourceAssetCatalogLoadStatus
    @Binding var gameCubeResourcePath: String
    @Binding var selectedAssetID: ResourceAssetRowViewState.ID?
    @Binding var mode: ResourceLibraryMode
    @Binding var selectedCategory: String
    @Binding var workflowFacet: ResourceAssetWorkflowFacet
    @Binding var groupingMode: ResourceAssetGroupingMode
    @Binding var sortMode: ResourceAssetSortMode
    @Binding var searchText: String
    let onChooseGameCubeResource: () -> Void
    let onLoadGameCubeResource: () -> Void
    let onLoadAssetCatalog: () -> Void
    let onLoadResourceEntryDetails: (ResourceLibraryEntryViewState) -> Void
    let onNavigateToAsset: (ResourceAssetRowViewState) -> Void
    let resourceReadinessPacketCopyDisabledReason: String?
    let onCopyResourceReadinessPacketJSON: () -> Void
    let ndsDataEditor: NDSDataResourceEditorViewState?
    let onUpdateNDSDataDraft: (String) -> Void
    let onUpdateNDSDataSemanticField: (String, String) -> Void
    let onStageNDSDataRowOperation: (NDSDataResourceRowOperationKind, String?, Int?, String, Int?, Int?) -> Void
    let onRemoveLastNDSDataRowOperation: () -> Void
    let onClearNDSDataRowOperations: () -> Void
    let onPreviewNDSDataMutationPlan: () -> Void
    let onApplyNDSDataMutationPlan: () -> Void
    let onDiscardNDSDataEdits: () -> Void
    let onFocusNDSMapReviewTarget: (NDSDataMapReviewBridgeTargetViewState) -> Void
    let onCopyNDSMapReviewPacketJSON: () -> Void
    let onCopyNDSMapReviewPacketMarkdown: () -> Void

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
            Fact(label: "Playtest", value: report.playtestReport.isRunnable ? "Runnable" : "Read-only preview"),
            Fact(label: "Diagnostics", value: "\(report.diagnostics.count)"),
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
                            ResourceLibraryDetailRow(
                                entry: entry,
                                isLoadingDetails: loadingResourceEntryID == entry.id,
                                onLoadDetails: {
                                    onLoadResourceEntryDetails(entry)
                                }
                            )
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
                if let ndsDataEditor, ndsDataEditor.isHiddenByFilters {
                    ScrollView {
                        hiddenNDSDraftPanel(editor: ndsDataEditor)
                            .padding(layoutMode.isCompact ? 14 : 24)
                    }
                } else {
                    ContentUnavailableView {
                        Label(emptyAssetTitle, systemImage: emptyAssetSystemImage)
                    } description: {
                        Text(emptyAssetDescription)
                    } actions: {
                        Button(assetLoadStatusActionTitle, systemImage: assetLoadStatusActionSystemImage) {
                            handleEmptyAssetAction()
                        }
                        .disabled(assetLoadStatus == .loading)
                    }
                    .frame(maxWidth: .infinity, minHeight: 260)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if let ndsDataEditor, ndsDataEditor.isHiddenByFilters {
                            hiddenNDSDraftPanel(editor: ndsDataEditor)
                        }

                        ResourceAssetDetailPane(
                            asset: selectedAsset,
                            onNavigate: onNavigateToAsset,
                            resourceReadinessPacketCopyDisabledReason: resourceReadinessPacketCopyDisabledReason,
                            onCopyResourceReadinessPacketJSON: onCopyResourceReadinessPacketJSON,
                            ndsDataEditor: ndsDataEditor?.isHiddenByFilters == true ? nil : ndsDataEditor,
                            onUpdateNDSDataDraft: onUpdateNDSDataDraft,
                            onUpdateNDSDataSemanticField: onUpdateNDSDataSemanticField,
                            onStageNDSDataRowOperation: onStageNDSDataRowOperation,
                            onRemoveLastNDSDataRowOperation: onRemoveLastNDSDataRowOperation,
                            onClearNDSDataRowOperations: onClearNDSDataRowOperations,
                            onPreviewNDSDataMutationPlan: onPreviewNDSDataMutationPlan,
                            onApplyNDSDataMutationPlan: onApplyNDSDataMutationPlan,
                            onDiscardNDSDataEdits: onDiscardNDSDataEdits,
                            onFocusNDSMapReviewTarget: onFocusNDSMapReviewTarget,
                            onCopyNDSMapReviewPacketJSON: onCopyNDSMapReviewPacketJSON,
                            onCopyNDSMapReviewPacketMarkdown: onCopyNDSMapReviewPacketMarkdown
                        )

                        assetRowsView
                    }
                    .padding(layoutMode.isCompact ? 14 : 24)
                }
            }
        }
    }

    private func hiddenNDSDraftPanel(editor: NDSDataResourceEditorViewState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label("Hidden NDS Draft", systemImage: "line.3.horizontal.decrease.circle")
                    .font(.headline)
                ResourceTag(text: editor.recordID)
                Spacer()
                Button("Show Draft", systemImage: "eye") {
                    mode = .assets
                    selectedCategory = Self.allCategories
                    workflowFacet = .all
                    selectedAssetID = editor.assetID
                }
                .help("Select the draft and reset the category filter. Clear the search field if it is still hidden.")
                Button("Discard", systemImage: "trash") {
                    onDiscardNDSDataEdits()
                }
                .disabled(!editor.canDiscard)
                .help("Discard the hidden NDS draft")
            }

            Text(editor.hiddenDraftSummary ?? "The selected NDS draft is outside the current Resources results.")
                .font(.caption)
                .foregroundStyle(.secondary)

            NDSDataRecordEditor(
                editor: editor,
                onUpdateDraft: onUpdateNDSDataDraft,
                onUpdateSemanticField: onUpdateNDSDataSemanticField,
                onStageRowOperation: onStageNDSDataRowOperation,
                onRemoveLastRowOperation: onRemoveLastNDSDataRowOperation,
                onClearRowOperations: onClearNDSDataRowOperations,
                onPreview: onPreviewNDSDataMutationPlan,
                onApply: onApplyNDSDataMutationPlan,
                onDiscard: onDiscardNDSDataEdits,
                onFocusMapReviewTarget: onFocusNDSMapReviewTarget,
                onCopyMapReviewJSON: onCopyNDSMapReviewPacketJSON,
                onCopyMapReviewMarkdown: onCopyNDSMapReviewPacketMarkdown
            )
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var assetRowsView: some View {
        if groupingMode == .workflow {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(assetGroups) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Label(group.title, systemImage: group.facet.systemImage)
                                .font(.subheadline.weight(.semibold))
                            ResourceTag(text: "\(group.rows.count)")
                            Spacer()
                        }

                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(group.rows) { asset in
                                selectableAssetRow(asset)
                            }
                        }
                    }
                }
            }
        } else {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(assets) { asset in
                    selectableAssetRow(asset)
                }
            }
        }
    }

    private func selectableAssetRow(_ asset: ResourceAssetRowViewState) -> some View {
        ResourceAssetRow(asset: asset, onNavigate: onNavigateToAsset)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedAssetID = asset.id
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
                                resourceReadinessPacketCopyDisabledReason: resourceReadinessPacketCopyDisabledReason,
                                onCopyResourceReadinessPacketJSON: onCopyResourceReadinessPacketJSON,
                                ndsDataEditor: selectedAssetID == asset.id ? ndsDataEditor : nil,
                                onUpdateNDSDataDraft: onUpdateNDSDataDraft,
                                onUpdateNDSDataSemanticField: onUpdateNDSDataSemanticField,
                                onStageNDSDataRowOperation: onStageNDSDataRowOperation,
                                onRemoveLastNDSDataRowOperation: onRemoveLastNDSDataRowOperation,
                                onClearNDSDataRowOperations: onClearNDSDataRowOperations,
                                onPreviewNDSDataMutationPlan: onPreviewNDSDataMutationPlan,
                                onApplyNDSDataMutationPlan: onApplyNDSDataMutationPlan,
                                onDiscardNDSDataEdits: onDiscardNDSDataEdits,
                                onFocusNDSMapReviewTarget: onFocusNDSMapReviewTarget,
                                onCopyNDSMapReviewPacketJSON: onCopyNDSMapReviewPacketJSON,
                                onCopyNDSMapReviewPacketMarkdown: onCopyNDSMapReviewPacketMarkdown
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
            hasActiveAssetFilters
                ? "No catalog assets match the current filters."
                : "The selected project's asset catalog has no source-backed rows yet."
        case let .failed(message):
            "\(message) Reload the asset catalog after fixing the source input."
        }
    }

    private var emptyAssetTitle: String {
        switch assetLoadStatus {
        case .idle:
            "Asset Catalog Unavailable"
        case .loading:
            "Loading Asset Catalog"
        case .loaded:
            "No Assets"
        case .failed:
            "Asset Catalog Error"
        }
    }

    private var emptyAssetSystemImage: String {
        switch assetLoadStatus {
        case .failed:
            "exclamationmark.triangle"
        case .idle:
            "tray"
        case .loading:
            "hourglass"
        case .loaded:
            "line.3.horizontal.decrease.circle"
        }
    }

    private var assetLoadStatusActionTitle: String {
        switch assetLoadStatus {
        case .idle:
            "Load Asset Catalog"
        case .failed:
            "Retry Asset Catalog"
        case .loading:
            "Loading"
        case .loaded:
            hasActiveAssetFilters ? "Clear Asset Filters" : "Reload Asset Catalog"
        }
    }

    private var assetLoadStatusActionSystemImage: String {
        if case .loaded = assetLoadStatus, hasActiveAssetFilters {
            return "line.3.horizontal.decrease.circle"
        }
        return "arrow.clockwise"
    }

    private var hasActiveAssetFilters: Bool {
        selectedCategory != Self.allCategories
            || workflowFacet != .all
            || !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func handleEmptyAssetAction() {
        if case .loaded = assetLoadStatus, hasActiveAssetFilters {
            selectedCategory = Self.allCategories
            workflowFacet = .all
            searchText = ""
            selectedAssetID = nil
            return
        }
        onLoadAssetCatalog()
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
    let isLoadingDetails: Bool
    let onLoadDetails: () -> Void
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 14) {
                FactGrid(facts: entryFacts)

                if entry.detailMode == "summary" {
                    HStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.small)
                            .opacity(isLoadingDetails ? 1 : 0)
                        Text(isLoadingDetails ? "Loading details..." : "Summary loaded")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Load Details", systemImage: "list.bullet.rectangle") {
                            onLoadDetails()
                        }
                        .disabled(isLoadingDetails)
                    }
                    .padding(10)
                    .background(.quaternary.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
                }

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
        .onChange(of: isExpanded) { _, expanded in
            if expanded, entry.detailMode == "summary" {
                onLoadDetails()
            }
        }
    }

    private var entryFacts: [Fact] {
        [
            Fact(label: "Family", value: entry.family),
            Fact(label: "Profile", value: entry.profile),
            Fact(label: "Role", value: entry.role),
            Fact(label: "Write Policy", value: entry.writePolicy),
            Fact(label: "Details", value: entry.detailMode),
            Fact(label: "Items", value: "\(entry.items.count)"),
            Fact(label: "Diagnostics", value: "\(entry.diagnosticCount)"),
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
    let resourceReadinessPacketCopyDisabledReason: String?
    let onCopyResourceReadinessPacketJSON: () -> Void
    let ndsDataEditor: NDSDataResourceEditorViewState?
    let onUpdateNDSDataDraft: (String) -> Void
    let onUpdateNDSDataSemanticField: (String, String) -> Void
    let onStageNDSDataRowOperation: (NDSDataResourceRowOperationKind, String?, Int?, String, Int?, Int?) -> Void
    let onRemoveLastNDSDataRowOperation: () -> Void
    let onClearNDSDataRowOperations: () -> Void
    let onPreviewNDSDataMutationPlan: () -> Void
    let onApplyNDSDataMutationPlan: () -> Void
    let onDiscardNDSDataEdits: () -> Void
    let onFocusNDSMapReviewTarget: (NDSDataMapReviewBridgeTargetViewState) -> Void
    let onCopyNDSMapReviewPacketJSON: () -> Void
    let onCopyNDSMapReviewPacketMarkdown: () -> Void

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
                            if resourceReadinessPacketCopyDisabledReason == nil {
                                Button("Copy Packet JSON", systemImage: "doc.on.doc") {
                                    onCopyResourceReadinessPacketJSON()
                                }
                                .help("Copy the selected Resources packet JSON")
                            }
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

                    if let review = allLearnablesRegenerationReview(for: asset) {
                        EditorSection(title: "All Learnables Regeneration Review") {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 8) {
                                    ResourceTag(text: review.posture)
                                    ResourceTag(text: "\(review.coverageMismatches) mismatches")
                                    ResourceTag(text: "\(review.staleSourceFiles) stale")
                                }

                                Text(review.guidance)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                FactGrid(facts: review.facts)
                            }
                        }
                    }

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
                            onStageRowOperation: onStageNDSDataRowOperation,
                            onRemoveLastRowOperation: onRemoveLastNDSDataRowOperation,
                            onClearRowOperations: onClearNDSDataRowOperations,
                            onPreview: onPreviewNDSDataMutationPlan,
                            onApply: onApplyNDSDataMutationPlan,
                            onDiscard: onDiscardNDSDataEdits,
                            onFocusMapReviewTarget: onFocusNDSMapReviewTarget,
                            onCopyMapReviewJSON: onCopyNDSMapReviewPacketJSON,
                            onCopyMapReviewMarkdown: onCopyNDSMapReviewPacketMarkdown
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
            Fact(label: "Source Line", value: "\(asset.source.line)"),
        ]
    }

    private func allLearnablesRegenerationReview(
        for asset: ResourceAssetRowViewState
    ) -> AllLearnablesRegenerationReview? {
        guard asset.path == "src/data/pokemon/all_learnables.json",
              let posture = factValue("Regeneration Posture", in: asset.facts)
        else {
            return nil
        }

        let focusedLabels = [
            "Coverage Status",
            "Coverage Mismatches",
            "Move-set Mismatches",
            "Generated-only Species",
            "Source-only Species",
            "Stale Source Files",
            "Newest Stale Source",
            "Regeneration Source Buckets",
            "Regeneration Source Paths",
            "Regeneration Source-only Move IDs",
            "Regeneration Generated-only Move IDs",
            "Regeneration Report Commands",
        ]
        let facts = focusedLabels.compactMap { label -> Fact? in
            factValue(label, in: asset.facts).map { Fact(label: label, value: $0) }
        }
        let guidance = factValue("Regeneration Guidance", in: asset.facts)
            ?? "Review compatibility and asset-index JSON; PokemonHackStudio will not run regeneration or write generated JSON."
        return AllLearnablesRegenerationReview(
            posture: posture,
            coverageMismatches: factValue("Coverage Mismatches", in: asset.facts) ?? "0",
            staleSourceFiles: factValue("Stale Source Files", in: asset.facts) ?? "0",
            guidance: guidance,
            facts: facts
        )
    }

    private func factValue(_ label: String, in facts: [Fact]) -> String? {
        facts.first { $0.label == label }?.value
    }
}

private struct AllLearnablesRegenerationReview {
    let posture: String
    let coverageMismatches: String
    let staleSourceFiles: String
    let guidance: String
    let facts: [Fact]
}

private struct NDSDataRecordEditor: View {
    let editor: NDSDataResourceEditorViewState?
    let onUpdateDraft: (String) -> Void
    let onUpdateSemanticField: (String, String) -> Void
    let onStageRowOperation: (NDSDataResourceRowOperationKind, String?, Int?, String, Int?, Int?) -> Void
    let onRemoveLastRowOperation: () -> Void
    let onClearRowOperations: () -> Void
    let onPreview: () -> Void
    let onApply: () -> Void
    let onDiscard: () -> Void
    let onFocusMapReviewTarget: (NDSDataMapReviewBridgeTargetViewState) -> Void
    let onCopyMapReviewJSON: () -> Void
    let onCopyMapReviewMarkdown: () -> Void

    @State private var rowOperationKind: NDSDataResourceRowOperationKind = .insert
    @State private var rowOperationIndex = ""
    @State private var rowOperationFromIndex = ""
    @State private var rowOperationToIndex = ""
    @State private var rowOperationInsertValue = ""
    @State private var rowOperationTargetKey = ""

    var body: some View {
        EditorSection(title: "NDS Editing Lens") {
            if let editor {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        ResourceTag(text: editor.recordID)
                        if editor.isDirty {
                            ResourceTag(text: "draft")
                        }
                        if editor.isHiddenByFilters {
                            ResourceTag(text: "hidden by filters")
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
                        .help(editor.canDiscard ? "Discard staged NDS data edits" : "No NDS data edits are staged")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(editor.lensSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 8) {
                            ResourceTag(text: "\(editor.sourceByteCount) source bytes")
                            ResourceTag(text: "\(editor.draftByteCount) draft bytes")
                            ResourceTag(text: editor.canEdit ? "source-backed" : "read-only")
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        FactGrid(facts: editor.readiness.facts)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 10)], alignment: .leading, spacing: 8) {
                            readinessFacet(editor.readiness.rawSource)
                            readinessFacet(editor.readiness.semanticSource)
                            readinessFacet(editor.readiness.draft)
                            readinessFacet(editor.readiness.mutationPlan)
                        }

                        if !editor.readiness.blockers.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Blockers")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                ForEach(editor.readiness.blockers) { blocker in
                                    VStack(alignment: .leading, spacing: 5) {
                                        HStack(spacing: 6) {
                                            StatusPill(state: blocker.status)
                                            Text(blocker.title)
                                                .font(.caption.weight(.semibold))
                                            ResourceTag(text: blocker.code)
                                        }
                                        Text(blocker.message)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(8)
                                    .background(.quaternary.opacity(0.24), in: RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }

                    if let mapReviewBridge = editor.mapReviewBridge {
                        mapReviewBridgeControls(mapReviewBridge)
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

                    if let rowOperations = editor.rowOperations {
                        rowOperationControls(rowOperations)
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

    private func mapReviewBridgeControls(_ bridge: NDSDataMapReviewBridgeViewState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Gen IV Map Review")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ResourceTag(text: bridge.component)
                ResourceTag(text: bridge.posture)
                ResourceTag(text: bridge.readinessStatus)
                Spacer(minLength: 8)
                Button("Copy JSON", systemImage: "doc.on.doc") {
                    onCopyMapReviewJSON()
                }
                .help("Copy the selected map review packet as JSON")
                Button("Copy Markdown", systemImage: "text.quote") {
                    onCopyMapReviewMarkdown()
                }
                .help("Copy the selected map review handoff as Markdown")
            }

            FactGrid(facts: bridge.packetFacts + bridge.catalogSummary.facts)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], alignment: .leading, spacing: 8) {
                ForEach(bridge.rows) { row in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(row.label)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        Text(row.value)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        if let detail = row.detail, !detail.isEmpty {
                            Text(detail)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                }
            }

            if !bridge.targets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Related Rows")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(bridge.targets) { target in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: target.canJump ? "arrow.right.circle" : "nosign")
                                .foregroundStyle(target.canJump ? Color.accentColor : Color.secondary)
                                .frame(width: 16)
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(target.label)
                                        .font(.caption.weight(.semibold))
                                    ResourceTag(text: target.domain)
                                    ResourceTag(text: target.readinessStatus)
                                }
                                Text(target.recordID)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Text(target.relativePath)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            Spacer(minLength: 8)
                            Button("Jump", systemImage: "arrow.turn.down.right") {
                                onFocusMapReviewTarget(target)
                            }
                            .disabled(!target.canJump)
                            .help(target.canJump ? "Jump to this Resources row" : "No matching Resources row is loaded for this packet record")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(.quaternary.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            if !bridge.blockedActions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Blocked Actions")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(bridge.blockedActions, id: \.self) { action in
                        Label(action, systemImage: "lock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.16), in: RoundedRectangle(cornerRadius: 8))
    }

    private func rowOperationControls(_ rowOperations: NDSDataResourceRowOperationEditorViewState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(rowOperations.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ResourceTag(text: rowOperations.countSummary)
                if rowOperations.stagedCount > 0 {
                    ResourceTag(text: "\(rowOperations.stagedCount) staged")
                }
                if let targetKey = selectedRowOperationTargetKey(rowOperations) {
                    ResourceTag(text: targetKey)
                }
            }

            if !rowOperations.targetOptions.isEmpty {
                Picker("Array", selection: rowOperationTargetSelectionBinding(rowOperations)) {
                    ForEach(rowOperations.targetOptions) { option in
                        Text("\(option.title) (\(option.detail))").tag(option.key)
                    }
                }
                .pickerStyle(.menu)
                .disabled(!rowOperations.canChangeTarget)
                .help(rowOperations.canChangeTarget ? "Choose the encounter array for staged row operations" : "Clear staged operations before changing the encounter array")
            }

            Picker("Operation", selection: $rowOperationKind) {
                ForEach(NDSDataResourceRowOperationKind.allCases) { kind in
                    Label(kind.title, systemImage: kind.systemImage).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], alignment: .leading, spacing: 8) {
                if rowOperationKind == .reorder {
                    rowOperationNumberField("From", text: $rowOperationFromIndex)
                    rowOperationNumberField("To", text: $rowOperationToIndex)
                } else {
                    rowOperationNumberField("Index", text: $rowOperationIndex)
                }

                if rowOperationKind == .insert {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(rowOperations.family.insertValueTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField(rowOperations.family.insertValuePlaceholder, text: $rowOperationInsertValue)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }

            HStack(spacing: 8) {
                Button("Stage", systemImage: rowOperationKind.systemImage) {
                    onStageRowOperation(
                        rowOperationKind,
                        selectedRowOperationTargetKey(rowOperations),
                        parsedRowOperationIndex,
                        rowOperationInsertValue,
                        parsedRowOperationFromIndex,
                        parsedRowOperationToIndex
                    )
                    if rowOperationKind == .insert {
                        rowOperationInsertValue = ""
                    }
                }
                .disabled(stageRowOperationDisabled(rowOperations))
                .help("Stage \(rowOperationKind.title.lowercased()) \(rowOperations.title.lowercased())")

                Button("Remove", systemImage: "arrow.uturn.backward") {
                    onRemoveLastRowOperation()
                }
                .disabled(!rowOperations.canRemoveLast)
                .help("Remove the latest staged row operation")

                Button("Clear", systemImage: "trash") {
                    onClearRowOperations()
                }
                .disabled(!rowOperations.canClear)
                .help("Clear staged row operations")
            }

            if !rowOperations.stagedOperations.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(rowOperations.stagedOperations) { operation in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: operation.kind.systemImage)
                                .foregroundStyle(.secondary)
                                .frame(width: 16)
                            Text(operation.summary)
                                .font(.caption.weight(.semibold))
                            if let detail = operation.detail, !detail.isEmpty {
                                Text(detail)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(7)
                        .background(.quaternary.opacity(0.22), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    private func rowOperationNumberField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("0", text: text)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
        }
    }

    private var parsedRowOperationIndex: Int? {
        Int(rowOperationIndex.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var parsedRowOperationFromIndex: Int? {
        Int(rowOperationFromIndex.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var parsedRowOperationToIndex: Int? {
        Int(rowOperationToIndex.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func rowOperationTargetSelectionBinding(_ rowOperations: NDSDataResourceRowOperationEditorViewState) -> Binding<String> {
        Binding(
            get: {
                selectedRowOperationTargetKey(rowOperations) ?? ""
            },
            set: { newValue in
                rowOperationTargetKey = newValue
            }
        )
    }

    private func selectedRowOperationTargetKey(_ rowOperations: NDSDataResourceRowOperationEditorViewState) -> String? {
        if !rowOperationTargetKey.isEmpty,
           rowOperations.targetOptions.contains(where: { $0.key == rowOperationTargetKey })
        {
            return rowOperationTargetKey
        }
        return rowOperations.selectedTargetKey ?? rowOperations.targetOptions.first?.key
    }

    private func stageRowOperationDisabled(_ rowOperations: NDSDataResourceRowOperationEditorViewState) -> Bool {
        guard rowOperations.canStage else { return true }
        if !rowOperations.targetOptions.isEmpty, selectedRowOperationTargetKey(rowOperations) == nil {
            return true
        }
        switch rowOperationKind {
        case .insert, .delete:
            return parsedRowOperationIndex == nil
        case .reorder:
            return parsedRowOperationFromIndex == nil || parsedRowOperationToIndex == nil
        }
    }

    private func readinessFacet(_ facet: NDSDataResourceReadinessFacetViewState) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                StatusPill(state: facet.status)
                Text(facet.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            Text(facet.value)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text(facet.detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
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
