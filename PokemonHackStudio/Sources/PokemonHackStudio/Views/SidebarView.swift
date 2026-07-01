import PokemonHackCore
import SwiftUI

struct WorkbenchSidebarPanel: View {
    @ObservedObject var store: WorkbenchStore

    @State private var mapEventSearchText = ""
    @State private var scriptDraftKey = ""
    @State private var scriptDraftText = ""

    private static let recentLimit = 5
    private static let mapRowLimit = 260
    private static let speciesRowLimit = 220
    private static let moveRowLimit = 260

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                projectSummary
                currentEditorSessionSection
                moduleNavigation
                currentTargetNavigation
                sidebarModePicker
                sidebarModeContent
            }
            .padding(12)
        }
        .navigationTitle("PokemonHack")
        .background(.bar)
    }

    private var projectSummary: some View {
        let identity = store.selectedProjectIdentity
        return sidebarSection("Workspace", systemImage: "folder") {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: identity.systemImage)
                        .foregroundStyle(.secondary)
                        .frame(width: 18)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(identity.title)
                            .font(.headline)
                            .lineLimit(1)
                        Text(identity.rootDisplay)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .truncationMode(.middle)
                    }

                    Spacer(minLength: 6)
                    StatusPill(state: store.selectedIndexedProject?.status ?? store.projectIndexStatus.validationState)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(identity.writePolicy.title)
                        .font(.caption.weight(.semibold))
                    Text(identity.writePolicy.detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    sidebarMetric("Projects", "\(store.indexedProjects.count)")
                    sidebarMetric("Issues", "\(store.issueCount)")
                    sidebarMetric("Dirty", store.hasStagedEdits ? "Yes" : "No")
                    sidebarMetric("Drafts", "\(store.currentDraftCount)/\(store.savedDraftCount)")
                }

                HStack(spacing: 6) {
                    Image(systemName: store.workspaceAutosavePending ? "clock.arrow.circlepath" : "tray.and.arrow.down")
                        .foregroundStyle(.secondary)
                    Text(store.workspacePersistenceError ?? "\(store.workspacePersistenceStatus) · \(store.workspaceLastSavedLabel)")
                        .font(.caption2)
                        .foregroundStyle(store.workspacePersistenceError == nil ? Color.secondary : Color.red)
                        .lineLimit(1)
                }
            }
        }
    }

    private var currentEditorSessionSection: some View {
        let session = store.currentModuleEditorSession
        return sidebarSection("Editor Session", systemImage: "slider.horizontal.3") {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    StatusPill(state: session.stage.validationState)
                    Text(session.stage.rawValue)
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Text(session.module.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(session.selectedObjectTitle)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(session.nextActionTitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    sidebarMetric("Preview", session.canPreview ? "Yes" : "No")
                    sidebarMetric("Apply", session.canApply ? "Yes" : "No")
                    sidebarMetric("Diagnostics", "\(session.diagnosticsCount)")
                }
            }
        }
    }

    private var sidebarModePicker: some View {
        Picker("Sidebar Mode", selection: $store.sidebarMode) {
            ForEach(WorkbenchSidebarMode.allCases) { mode in
                Label(mode.rawValue, systemImage: mode.systemImage)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .help("Choose sidebar content")
    }

    @ViewBuilder
    private var sidebarModeContent: some View {
        switch store.sidebarMode {
        case .browse:
            recentModuleNavigation
            sidebarSearch
            objectNavigation
        case .tools:
            sidebarSearch
            contextualTools
        case .properties:
            selectionProperties
        }
    }

    private var moduleNavigation: some View {
        sidebarSection("Navigation", systemImage: "sidebar.left") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(WorkbenchModuleGroup.allCases) { group in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(group.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(group.modules) { module in
                            moduleRow(module)
                        }
                    }
                }
            }
        }
    }

    private var recentModuleNavigation: some View {
        let modules = store.recentModules.isEmpty ? [store.selection] : store.recentModules
        return sidebarSection("Recent Modules", systemImage: "clock.arrow.circlepath") {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(modules.prefix(Self.recentLimit)) { module in
                    moduleRow(module, compact: true)
                }
            }
        }
    }

    private var sidebarSearch: some View {
        sidebarSection("Find", systemImage: "magnifyingglass") {
            TextField("Search current module", text: $store.searchText)
                .textFieldStyle(.roundedBorder)
        }
    }

    @ViewBuilder
    private var currentTargetNavigation: some View {
        switch store.selection {
        case .maps:
            currentAndRecentMapsNavigation
        case .pokemon:
            currentAndRecentPokemonNavigation
        case .moves:
            currentAndRecentMovesNavigation
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var objectNavigation: some View {
        switch store.selection {
        case .dashboard:
            dashboardNavigation
        case .resources:
            resourcesNavigation
        case .maps:
            mapsNavigation
        case .pokemon:
            pokemonNavigation
        case .trainers:
            trainersNavigation
        case .moves:
            movesNavigation
        case .scripts:
            scriptsNavigation
        case .items:
            itemsNavigation
        case .text, .encounters:
            genericRecordNavigation(module: store.selection)
        case .graphics:
            graphicsNavigation
        case .build:
            buildNavigation
        case .issues:
            diagnosticsNavigation
        }
    }

    @ViewBuilder
    private var contextualTools: some View {
        switch store.selection {
        case .maps:
            mapTools
        case .resources:
            resourceTools
        case .build:
            buildTools
        case .graphics:
            VStack(alignment: .leading, spacing: 12) {
                mutationTools(
                    title: "Graphics Mutation",
                    state: store.mutationActionBarState
                )
                previewOnlyTools(title: "Graphics Package Tools", actions: ["Import", "Convert", "Apply Package"])
            }
        case .pokemon:
            mutationTools(
                title: "Pokemon Mutation",
                state: store.mutationActionBarState
            )
        case .trainers:
            mutationTools(
                title: "Trainer Mutation",
                state: store.mutationActionBarState
            )
        case .moves:
            mutationTools(
                title: store.mutationActionBarState.target == .pokemonBatch ? "Pokemon Batch Mutation" : "Move Mutation",
                state: store.mutationActionBarState
            )
        case .items:
            mutationTools(
                title: "Item Mutation",
                state: store.mutationActionBarState
            )
        default:
            sidebarSection("Tools", systemImage: "wrench.and.screwdriver") {
                Text("Context tools appear here when the selected module exposes preview or edit controls.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var selectionProperties: some View {
        switch store.selection {
        case .dashboard:
            dashboardProperties
        case .resources:
            resourceProperties
        case .maps:
            mapProperties
        case .pokemon:
            speciesProperties
        case .trainers:
            trainerProperties
        case .moves:
            movesProperties
        case .scripts:
            scriptProperties
        case .items:
            itemsProperties
        case .text, .encounters:
            genericRecordProperties(module: store.selection)
        case .graphics:
            graphicsProperties
        case .build:
            buildProperties
        case .issues:
            diagnosticProperties
        }
    }

    private func moduleRow(_ module: WorkbenchModule, compact: Bool = false) -> some View {
        let isSelected = store.selection == module
        let dirtyCount = dirtyCount(for: module)
        return Button {
            selectModule(module)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: module.systemImage)
                    .foregroundStyle(.secondary)
                    .frame(width: 17)
                VStack(alignment: .leading, spacing: 1) {
                    Text(module.title)
                        .lineLimit(1)
                    Text(module == .issues ? store.diagnosticSummary.compactLabel : module.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                if let dirtyCount {
                    dirtyCountBadge(dirtyCount)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, compact ? 5 : 6)
            .contentShape(Rectangle())
            .background(selectionBackground(isSelected))
        }
        .buttonStyle(.plain)
        .help(module.subtitle)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(module.title)
        .accessibilityValue(moduleAccessibilityValue(isSelected: isSelected, dirtyCount: dirtyCount))
    }

    private var dashboardNavigation: some View {
        sidebarSection("Project Hub", systemImage: "square.grid.2x2") {
            sidebarRows(store.guidedFlows, limit: 12) { flow in
                sidebarButton(
                    id: flow.id,
                    title: flow.title,
                    subtitle: flow.subtitle,
                    systemImage: flow.systemImage,
                    isSelected: store.selectedGuidedFlowID == flow.id
                ) {
                    store.requestGuidedFlowSelection(flow.id)
                }
            }
        }
    }

    private var currentAndRecentMapsNavigation: some View {
        sidebarSection("Current Map", systemImage: WorkbenchModule.maps.systemImage) {
            VStack(alignment: .leading, spacing: 8) {
                if let map = currentMap {
                    sidebarButton(
                        id: "current-map-\(map.id)",
                        title: map.name,
                        subtitle: map.mapID,
                        systemImage: "scope",
                        isSelected: store.selectedMapID == map.id,
                        badgeText: store.hasStagedMapEdits ? "Dirty" : nil
                    ) {
                        selectMap(map.id)
                    }

                    if currentMapIsHidden(map) {
                        hiddenTargetControls(
                            detail: "Current map is hidden by the list filter or row limit.",
                            canClear: !store.searchText.isEmpty,
                            reveal: { revealMap(map) },
                            clear: { store.clearCurrentModuleSearch() }
                        )
                    }
                } else {
                    emptySidebarText(store.mapCatalogStatus.label)
                }

                let recents = recentMaps(excluding: currentMap?.id)
                if !recents.isEmpty {
                    sidebarSubheading("Recent")
                    ForEach(recents.prefix(Self.recentLimit)) { map in
                        sidebarButton(
                            id: "recent-map-\(map.id)",
                            title: map.name,
                            subtitle: "\(map.groupName) · \(map.mapID)",
                            systemImage: "map",
                            isSelected: store.selectedMapID == map.id,
                            badgeText: store.hasStagedMapEdits && store.selectedMapID == map.id ? "Dirty" : nil
                        ) {
                            selectMap(map.id)
                        }
                    }
                }
            }
        }
    }

    private var currentAndRecentPokemonNavigation: some View {
        sidebarSection("Current Pokemon", systemImage: WorkbenchModule.pokemon.systemImage) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    sidebarMetric("Visible", "\(store.filteredSpeciesDetails.count)")
                    sidebarMetric("Dirty", "\(store.dirtySpeciesDraftCount)")
                }

                if let species = currentSpecies {
                    sidebarButton(
                        id: "current-species-\(species.speciesID)",
                        title: species.displayName,
                        subtitle: species.speciesID,
                        systemImage: species.isEditable ? "pencil" : "lock",
                        isSelected: selectedSpeciesID == species.speciesID,
                        badgeText: dirtyBadgeText(forSpeciesID: species.speciesID)
                    ) {
                        selectSpecies(species.speciesID)
                    }

                    if currentSpeciesIsHidden(species) {
                        hiddenTargetControls(
                            detail: "Current Pokemon is hidden by search or the row limit.",
                            canClear: !store.searchText.isEmpty,
                            reveal: { revealSpecies(species) },
                            clear: { store.clearCurrentModuleSearch() }
                        )
                    }
                } else {
                    emptySidebarText(store.speciesCatalogLoadStatus.label)
                }

                let recents = recentSpecies(excluding: currentSpecies?.speciesID)
                if !recents.isEmpty {
                    sidebarSubheading("Recent")
                    ForEach(recents.prefix(Self.recentLimit), id: \.speciesID) { species in
                        sidebarButton(
                            id: "recent-species-\(species.speciesID)",
                            title: species.displayName,
                            subtitle: species.speciesID,
                            systemImage: species.isEditable ? "pencil" : "lock",
                            isSelected: selectedSpeciesID == species.speciesID,
                            badgeText: dirtyBadgeText(forSpeciesID: species.speciesID)
                        ) {
                            selectSpecies(species.speciesID)
                        }
                    }
                }
            }
        }
    }

    private var currentAndRecentMovesNavigation: some View {
        sidebarSection("Current Move", systemImage: WorkbenchModule.moves.systemImage) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    sidebarMetric("Visible", "\(store.filteredMoveDetails.count)")
                    sidebarMetric("Dirty", "\(store.dirtyMoveDraftCount)")
                }

                if let move = currentMove {
                    sidebarButton(
                        id: "current-move-\(move.moveID)",
                        title: move.displayName,
                        subtitle: move.moveID,
                        systemImage: move.isEditable ? "pencil" : "lock",
                        isSelected: selectedMoveID == move.moveID,
                        badgeText: dirtyBadgeText(forMoveID: move.moveID)
                    ) {
                        selectMove(move.moveID)
                    }

                    if currentMoveIsHidden(move) {
                        hiddenTargetControls(
                            detail: "Current move is hidden by search, filter, or the row limit.",
                            canClear: !store.searchText.isEmpty || store.selectedMoveWorkbenchFilter != .all,
                            reveal: { revealMove(move) },
                            clear: {
                                store.revealSelectedMoveInSidebar()
                            }
                        )
                    }
                } else {
                    emptySidebarText(store.moveCatalogLoadStatus.label)
                }

                let recents = recentMoves(excluding: currentMove?.moveID)
                if !recents.isEmpty {
                    sidebarSubheading("Recent")
                    ForEach(recents.prefix(Self.recentLimit)) { move in
                        sidebarButton(
                            id: "recent-move-\(move.moveID)",
                            title: move.displayName,
                            subtitle: "\(move.moveID) · \(move.learnerCount) learners",
                            systemImage: move.isEditable ? "pencil" : "lock",
                            isSelected: selectedMoveID == move.moveID,
                            badgeText: dirtyBadgeText(forMoveID: move.moveID)
                        ) {
                            selectMove(move.moveID)
                        }
                    }
                }
            }
        }
    }

    private var resourcesNavigation: some View {
        sidebarSection("Resources", systemImage: WorkbenchModule.resources.systemImage) {
            VStack(alignment: .leading, spacing: 10) {
                Picker("Resource Mode", selection: $store.selectedResourceLibraryMode) {
                    ForEach(ResourceLibraryMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.systemImage).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                switch store.selectedResourceLibraryMode {
                case .assets:
                    sidebarRows(store.filteredResourceAssetRows, limit: 220) { asset in
                        sidebarButton(
                            id: asset.id,
                            title: asset.title,
                            subtitle: "\(asset.category) · \(asset.availabilitySummary)",
                            systemImage: iconName(forResourceCategory: asset.category),
                            isSelected: store.selectedResourceAsset?.id == asset.id
                        ) {
                            store.requestResourceAssetSelection(asset.id)
                        }
                    }
                case .entries:
                    sidebarRows(store.filteredResourceLibraryEntries, limit: 140) { entry in
                        sidebarButton(
                            id: entry.id,
                            title: entry.title,
                            subtitle: "\(entry.family) · \(entry.parseStatus)",
                            systemImage: "externaldrive.connected.to.line.below",
                            isSelected: store.selectedResourceLibraryEntry?.id == entry.id
                        ) {
                            store.requestResourceLibraryEntrySelection(entry.id)
                        }
                    }
                }
            }
        }
    }

    private var mapsNavigation: some View {
        sidebarSection("Maps", systemImage: WorkbenchModule.maps.systemImage) {
            if let catalog = store.selectedMapCatalog {
                sidebarRows(filteredMaps(in: catalog), limit: Self.mapRowLimit) { map in
                    sidebarButton(
                        id: map.id,
                        title: map.name,
                        subtitle: "\(map.groupName) · \(map.layout?.name ?? "No layout")",
                        systemImage: "map",
                        isSelected: store.selectedMapID == map.id,
                        badgeText: store.hasStagedMapEdits && store.selectedMapID == map.id ? "Dirty" : nil
                    ) {
                        selectMap(map.id)
                    }
                }
            } else {
                emptySidebarText(store.mapCatalogStatus.label)
            }
        }
    }

    private var pokemonNavigation: some View {
        sidebarSection("Pokemon", systemImage: WorkbenchModule.pokemon.systemImage) {
            sidebarRows(store.filteredSpeciesDetails, limit: Self.speciesRowLimit) { species in
                sidebarButton(
                    id: species.speciesID,
                    title: species.displayName,
                    subtitle: species.speciesID,
                    systemImage: species.isEditable ? "pencil" : "lock",
                    isSelected: selectedSpeciesID == species.speciesID,
                    badgeText: dirtyBadgeText(forSpeciesID: species.speciesID)
                ) {
                    selectSpecies(species.speciesID)
                }
            }
        }
    }

    private var trainersNavigation: some View {
        sidebarSection("Trainers", systemImage: WorkbenchModule.trainers.systemImage) {
            sidebarRows(store.filteredTrainerDetails, limit: 220) { trainer in
                sidebarButton(
                    id: trainer.trainerID,
                    title: trainer.displayName,
                    subtitle: trainer.trainerID,
                    systemImage: trainer.isEditable ? "person.crop.circle.badge.checkmark" : "lock",
                    isSelected: store.selectedTrainerDetail?.trainerID == trainer.trainerID
                ) {
                    store.requestTrainerSelection(trainer.trainerID)
                }
            }
        }
    }

    private var movesNavigation: some View {
        sidebarSection("Moves", systemImage: WorkbenchModule.moves.systemImage) {
            sidebarRows(store.filteredMoveDetails, limit: Self.moveRowLimit) { move in
                sidebarButton(
                    id: move.moveID,
                    title: move.displayName,
                    subtitle: "\(move.moveID) · \(move.learnerCount) learners",
                    systemImage: WorkbenchModule.moves.systemImage,
                    isSelected: selectedMoveID == move.moveID,
                    badgeText: dirtyBadgeText(forMoveID: move.moveID)
                ) {
                    selectMove(move.moveID)
                }
            }

            if store.selectedMoveCatalog == nil {
                emptySidebarText(store.moveCatalogLoadStatus.label)
            }
        }
    }

    private var itemsNavigation: some View {
        sidebarSection("Items", systemImage: WorkbenchModule.items.systemImage) {
            sidebarRows(store.filteredItemDetails, limit: 260) { item in
                sidebarButton(
                    id: item.itemID,
                    title: item.displayName,
                    subtitle: item.itemID,
                    systemImage: item.isEditable ? "pencil" : "lock",
                    isSelected: store.selectedItemDetail?.itemID == item.itemID
                ) {
                    store.requestItemSelection(item.itemID)
                }
            }

            if store.selectedItemCatalog == nil {
                emptySidebarText(store.itemCatalogLoadStatus.label)
            }
        }
    }

    private var scriptsNavigation: some View {
        sidebarSection("Scripts", systemImage: WorkbenchModule.scripts.systemImage) {
            VStack(alignment: .leading, spacing: 12) {
                if !store.filteredScriptOutlineLabels.isEmpty {
                    sidebarSubheading("Labels")
                    sidebarRows(store.filteredScriptOutlineLabels, limit: 120) { label in
                        sidebarButton(
                            id: label.id,
                            title: label.label,
                            subtitle: "\(label.kind.rawValue) · \(label.sourcePath)",
                            systemImage: "curlybraces",
                            isSelected: store.selectedScriptLabel?.id == label.id
                        ) {
                            store.requestScriptLabelSelection(label.id)
                        }
                    }
                }

                if !store.filteredScriptOutlineSources.isEmpty {
                    sidebarSubheading("Sources")
                    sidebarRows(store.filteredScriptOutlineSources, limit: 80) { source in
                        sidebarButton(
                            id: source.id,
                            title: source.path,
                            subtitle: "\(source.module.rawValue) · \(source.role.rawValue)",
                            systemImage: "doc.text",
                            isSelected: store.selectedScriptSource?.id == source.id
                        ) {
                            store.requestScriptSourceSelection(source.id)
                        }
                    }
                }

                if !store.filteredScriptTextBlocks.isEmpty {
                    sidebarSubheading("Text Blocks")
                    sidebarRows(store.filteredScriptTextBlocks, limit: 80) { block in
                        sidebarButton(
                            id: block.id,
                            title: block.label,
                            subtitle: block.sourcePath,
                            systemImage: "text.quote",
                            isSelected: store.selectedScriptTextBlock?.id == block.id
                        ) {
                            store.requestScriptTextBlockSelection(block.id)
                        }
                    }
                }

                if store.selectedScriptOutline == nil {
                    emptySidebarText("No script outline loaded.")
                }
            }
        }
    }

    private func genericRecordNavigation(module: WorkbenchModule) -> some View {
        sidebarSection(module.title, systemImage: module.systemImage) {
            let rows = store.records(for: module)
            if rows.isEmpty {
                emptySidebarText("No records match the current search.")
            } else {
                sidebarRows(rows, limit: 180) { record in
                    sidebarButton(
                        id: record.id.uuidString,
                        title: record.title,
                        subtitle: record.source.path,
                        systemImage: module.systemImage,
                        isSelected: store.selectedRecord(for: module)?.id == record.id
                    ) {
                        store.requestRecordSelection(record.id, module: module)
                    }
                }
            }
        }
    }

    private var graphicsNavigation: some View {
        sidebarSection("Graphics Rows", systemImage: WorkbenchModule.graphics.systemImage) {
            sidebarRows(store.filteredGraphicsReportRows, limit: 180) { row in
                sidebarButton(
                    id: row.id,
                    title: row.title,
                    subtitle: "\(row.section.rawValue) · \(row.source.path)",
                    systemImage: row.section.systemImage,
                    isSelected: store.selectedGraphicsReportRow?.id == row.id
                ) {
                    store.requestGraphicsReportRowSelection(row.id)
                }
            }
        }
    }

    private var buildNavigation: some View {
        sidebarSection("Ship Rows", systemImage: WorkbenchModule.build.systemImage) {
            VStack(alignment: .leading, spacing: 10) {
                Picker("Report", selection: $store.selectedBuildWorkbenchTab) {
                    ForEach(BuildWorkbenchTab.allCases) { tab in
                        Label(tab.title, systemImage: tab.systemImage).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                sidebarRows(store.filteredBuildRowsForSelectedTab, limit: 160) { row in
                    sidebarButton(
                        id: row.id,
                        title: row.title,
                        subtitle: "\(row.section.rawValue) · \(row.status.rawValue)",
                        systemImage: row.section.systemImage,
                        isSelected: store.selectedBuildReportRow?.id == row.id
                    ) {
                        store.requestBuildReportRowSelection(row.id)
                    }
                }
            }
        }
    }

    private var diagnosticsNavigation: some View {
        sidebarSection("Diagnostics", systemImage: WorkbenchModule.issues.systemImage) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(DiagnosticSummaryBucket.allCases) { bucket in
                    let summary = store.diagnosticSummary.bucket(bucket)
                    sidebarButton(
                        id: bucket.id,
                        title: summary.title,
                        subtitle: "\(summary.count) · \(summary.status.rawValue)",
                        systemImage: summary.systemImage,
                        isSelected: store.selectedDiagnosticBucket == bucket
                    ) {
                        store.requestDiagnosticBucketSelection(bucket)
                    }
                }

                if !store.selectedDiagnosticBucketSummary.diagnostics.isEmpty {
                    sidebarSubheading("Findings")
                    sidebarRows(store.selectedDiagnosticBucketSummary.diagnostics, limit: 160) { diagnostic in
                        sidebarButton(
                            id: diagnostic.id,
                            title: diagnostic.title,
                            subtitle: diagnostic.source.path,
                            systemImage: "exclamationmark.triangle",
                            isSelected: store.selectedDiagnosticRow?.id == diagnostic.id
                        ) {
                            store.requestDiagnosticRowSelection(diagnostic.id)
                        }
                    }
                }
            }
        }
    }

    private var mapTools: some View {
        sidebarSection("Map Tools", systemImage: "paintbrush.pointed") {
            VStack(alignment: .leading, spacing: 12) {
                mutationToolContent(state: store.mutationActionBarState)

                MapEditorGroupedToolPicker(session: store.mapEditorSession)

                Picker("Panel", selection: $store.selectedMapWorkbenchTab) {
                    ForEach(MapWorkbenchTab.allCases) { tab in
                        Label(tab.title, systemImage: tab.systemImage).tag(tab)
                    }
                }
                .pickerStyle(.menu)

                Toggle("Metatile Palette", isOn: $store.mapShowsPalette)
                    .toggleStyle(.checkbox)

                if store.mapShowsPalette {
                    TextField("Filter metatiles", text: $store.mapMetatileFilter)
                        .textFieldStyle(.roundedBorder)
                }

                mapLayerToggles

                HStack(spacing: 8) {
                    Button("Undo", systemImage: "arrow.uturn.backward") {
                        store.undoLastMapEdit()
                    }
                    .disabled(store.mapEditOperations.isEmpty)

                    Button("Redo", systemImage: "arrow.uturn.forward") {
                        store.redoMapEdit()
                    }
                    .disabled(store.undoneMapEditOperations.isEmpty)
                }

                if let document = store.selectedMapVisualDocument {
                    Divider()
                    MapWorkbenchPanels(
                        document: document,
                        catalog: store.selectedCoreMapCatalog,
                        session: store.mapEditorSession,
                        layoutMode: .compact,
                        viewport: .zero,
                        selectedTab: $store.selectedMapWorkbenchTab,
                        eventSearchText: $mapEventSearchText,
                        scriptDraftKey: $scriptDraftKey,
                        scriptDraftText: $scriptDraftText,
                        onSelectViewportCenter: { centerX, centerY in
                            store.mapViewportRequest = MapCanvasViewportRequest(centerX: centerX, centerY: centerY)
                        },
                        onCenterEvent: { event in
                            store.mapEditorSession.selectMapEvent(id: event.id)
                            if let x = event.x, let y = event.y {
                                store.mapViewportRequest = MapCanvasViewportRequest(centerX: CGFloat(x), centerY: CGFloat(y))
                            }
                        }
                    )
                }
            }
        }
    }

    private var resourceTools: some View {
        sidebarSection("Resource Tools", systemImage: "line.3.horizontal.decrease.circle") {
            VStack(alignment: .leading, spacing: 10) {
                if store.mutationActionBarState.target == .ndsData {
                    mutationToolContent(state: store.mutationActionBarState)
                    Divider()
                }

                Picker("Mode", selection: $store.selectedResourceLibraryMode) {
                    ForEach(ResourceLibraryMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.systemImage).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                if store.selectedResourceLibraryMode == .assets {
                    Picker("Category", selection: $store.resourceAssetCategory) {
                        ForEach(resourceCategoryOptions, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }

                    Picker("Workflow", selection: $store.resourceAssetWorkflowFacet) {
                        ForEach(ResourceAssetWorkflowFacet.allCases) { facet in
                            Label(facet.title, systemImage: facet.systemImage).tag(facet)
                        }
                    }

                    Picker("Group", selection: $store.resourceAssetGroupingMode) {
                        ForEach(ResourceAssetGroupingMode.allCases) { groupingMode in
                            Text(groupingMode.title).tag(groupingMode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Sort", selection: $store.resourceAssetSortMode) {
                        ForEach(ResourceAssetSortMode.allCases) { sort in
                            Text(sort.title).tag(sort)
                        }
                    }
                }
            }
        }
    }

    private var movesTools: some View {
        sidebarSection("Moves", systemImage: WorkbenchModule.moves.systemImage) {
            VStack(alignment: .leading, spacing: 10) {
                Picker("Filter", selection: $store.selectedMoveWorkbenchFilter) {
                    ForEach(MoveWorkbenchFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    sidebarMetric("Moves", "\(store.selectedMoveCatalog?.moveCount ?? 0)")
                    sidebarMetric("Visible", "\(store.filteredMoveDetails.count)")
                    sidebarMetric("Issues", "\(store.selectedMoveCatalog?.diagnostics.count ?? 0)")
                }

                Text("Read-only source graph")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var buildTools: some View {
        sidebarSection("Ship Tools", systemImage: "hammer") {
            VStack(alignment: .leading, spacing: 10) {
                Button("Copy Report JSON", systemImage: "doc.on.doc") {
                    store.copyBuildPatchPlaytestReportJSONToPasteboard()
                }
                .disabled(store.selectedBuildReport == nil)

                ForEach(store.buildWorkflowActions(includePatchActions: true)) { action in
                    if action.id == "open-playtest" {
                        Button(action.title, systemImage: action.systemImage) {
                            store.launchSelectedPlaytest()
                        }
                        .disabled(!action.isEnabled)
                    } else if action.id == "build-rom" {
                        Button(action.title, systemImage: action.systemImage) {
                            store.runSelectedDecompBuild()
                        }
                        .disabled(!action.isEnabled)
                    } else if action.id == "cancel-build" {
                        Button(action.title, systemImage: action.systemImage) {
                            store.cancelSelectedDecompBuild()
                        }
                        .disabled(!action.isEnabled)
                    } else if action.id == "capture-screenshot" {
                        Button(action.title, systemImage: action.systemImage) {
                            store.captureSelectedPlaytest(kind: .screenshot)
                        }
                        .disabled(!action.isEnabled)
                    } else if action.id == "capture-savestate" {
                        Button(action.title, systemImage: action.systemImage) {
                            store.captureSelectedPlaytest(kind: .saveState)
                        }
                        .disabled(!action.isEnabled)
                    } else {
                        Button(action.title, systemImage: "lock") {}
                            .disabled(true)
                    }
                }

                if store.selectedBuildReport?.isNDS == true && !store.selectedNDSHealthActionRows.isEmpty {
                    Divider()
                    sidebarSubheading("NDS Setup")
                    ForEach(store.selectedNDSHealthActionRows.prefix(4)) { row in
                        if let action = row.actions.first {
                            Button(action.title, systemImage: action.kind == .copyPath ? "doc.on.clipboard" : "terminal") {
                                store.copyBuildReportRowActionToPasteboard(action)
                            }
                            .help(action.detail)
                        }
                    }
                }

                Text(store.selectedBuildReport?.isNDS == true ? "NDS health actions copy manual setup or rerun guidance only. Builds, Docker, extraction, emulator launch, and ROM writes stay disabled." : "Build runs only selected declared make targets. Validate, patched-ROM artifact export, conversion, and source writes stay locked.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var mapLayerToggles: some View {
        VStack(alignment: .leading, spacing: 8) {
            sidebarSubheading("Layers")
            ForEach([MapEditorLayer.collision, .objects, .warps, .coordEvents, .bgEvents, .connections, .playerView, .grid], id: \.self) { layer in
                Toggle(isOn: Binding(
                    get: { store.mapEditorSession.mapOverlaySettings.state(for: layer).isVisible },
                    set: { store.mapEditorSession.setLayerVisible(layer, isVisible: $0) }
                )) {
                    Label(layer.title, systemImage: layer.systemImage)
                }
                .toggleStyle(.checkbox)
            }

            HStack(spacing: 8) {
                Button("Solo Collision", systemImage: "scope") {
                    store.mapEditorSession.toggleLayerSolo(.collision)
                }
                Button("Reset", systemImage: "arrow.counterclockwise") {
                    store.mapEditorSession.resetLayerSettings()
                }
            }
        }
    }

    private func mutationTools(
        title: String,
        state: MutationActionBarState
    ) -> some View {
        sidebarSection(title, systemImage: "doc.text.magnifyingglass") {
            mutationToolContent(state: state)
        }
    }

    private func mutationToolContent(state: MutationActionBarState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                DirtyPill(isDirty: isMutationToolDirty(state.target))
                Spacer()
            }

            MutationActionBar(
                state: state,
                style: .sidebar,
                onPreview: store.previewToolbarMutationTarget,
                onApply: store.applyToolbarMutationTarget,
                onDiscard: store.discardToolbarMutationTarget
            )
        }
    }

    private func previewOnlyTools(title: String, actions: [String]) -> some View {
        sidebarSection(title, systemImage: "lock") {
            previewOnlyActions(actions)
        }
    }

    private func previewOnlyActions(_ actions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(actions, id: \.self) { action in
                Button(action, systemImage: "lock") {}
                    .disabled(true)
            }
            Text("Read-only preview")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var dashboardProperties: some View {
        let flow = store.guidedFlows.first { $0.id == store.selectedGuidedFlowID } ?? store.guidedFlows.first
        return sidebarSection("Properties", systemImage: "info.circle") {
            if let flow {
                let run = flow.run
                propertyHeader(flow.title, subtitle: flow.detail, systemImage: flow.systemImage, status: flow.status)
                propertyFacts(flow.facts + [
                    Fact(label: "Step", value: run.currentStep),
                    Fact(label: "Target", value: run.activeObject),
                    Fact(label: "Gate", value: run.mutationGate),
                    Fact(label: "Next", value: run.nextAction),
                    Fact(label: "Diagnostics", value: "\(run.diagnosticsCount)")
                ])
            } else {
                emptySidebarText("No guided project action selected.")
            }
        }
    }

    private var resourceProperties: some View {
        sidebarSection("Properties", systemImage: "info.circle") {
            switch store.selectedResourceLibraryMode {
            case .assets:
                if let asset = store.selectedResourceAsset {
                    propertyHeader(asset.title, subtitle: asset.path, systemImage: iconName(forResourceCategory: asset.category), status: asset.status)
                    propertyFacts(asset.facts + [
                        Fact(label: "Category", value: asset.category),
                        Fact(label: "Availability", value: asset.availabilitySummary),
                        Fact(label: "Checksum", value: asset.checksumSummary),
                    ])
                    SourceLocationView(source: asset.source)
                    if let targetModule = asset.targetModule {
                        Button("Open \(targetModule.title)", systemImage: targetModule.systemImage) {
                            store.navigateToAsset(asset)
                        }
                    }
                } else {
                    emptySidebarText("No resource asset selected.")
                }
            case .entries:
                if let entry = store.selectedResourceLibraryEntry {
                    propertyHeader(entry.title, subtitle: entry.path, systemImage: "externaldrive.connected.to.line.below", status: entry.status)
                    propertyFacts([
                        Fact(label: "Family", value: entry.family),
                        Fact(label: "Profile", value: entry.profile),
                        Fact(label: "Items", value: "\(entry.items.count)"),
                        Fact(label: "Diagnostics", value: "\(entry.diagnosticCount)"),
                    ])
                    SourceLocationView(source: entry.source)
                } else {
                    emptySidebarText("No resource entry selected.")
                }
            }
        }
    }

    private var mapProperties: some View {
        sidebarSection("Properties", systemImage: "info.circle") {
            if let map = selectedMap {
                propertyHeader(map.name, subtitle: map.mapID, systemImage: "map", status: store.moduleStatus(for: .maps))
                propertyFacts([
                    Fact(label: "Group", value: map.groupName),
                    Fact(label: "Layout", value: map.layout?.name ?? "None"),
                    Fact(label: "Size", value: map.layout.map { "\($0.width)x\($0.height)" } ?? "Unknown"),
                    Fact(label: "Events", value: "\(map.eventCounts.total)"),
                    Fact(label: "Objects", value: mapCapacityFact(map, for: .object)),
                    Fact(label: "Warps", value: mapCapacityFact(map, for: .warp)),
                    Fact(label: "Coords", value: mapCapacityFact(map, for: .coord)),
                    Fact(label: "BG", value: mapCapacityFact(map, for: .bg)),
                    Fact(label: "Connections", value: "\(map.connections.count)"),
                    Fact(label: "Tool", value: store.selectedMapTool.title),
                    Fact(label: "Panel", value: store.selectedMapWorkbenchTab.title),
                ])
                SourceLocationView(source: map.source)
            } else {
                emptySidebarText(store.mapCatalogStatus.label)
            }
        }
    }

    private var speciesProperties: some View {
        sidebarSection("Properties", systemImage: "info.circle") {
            if let species = store.selectedSpeciesDetail {
                propertyHeader(species.displayName, subtitle: species.speciesID, systemImage: "sparkles", status: species.diagnostics.isEmpty ? .valid : .warning)
                propertyFacts([
                    Fact(label: "Types", value: species.types.joined(separator: " / ")),
                    Fact(label: "Abilities", value: species.abilities.joined(separator: ", ")),
                    Fact(label: "Stats", value: statSummary(species.baseStats)),
                    Fact(label: "Editable", value: species.isEditable ? "Yes" : "No"),
                    Fact(label: "Dirty", value: store.selectedSpeciesIsDirty ? "Yes" : "No"),
                    Fact(label: "Write Policy", value: species.isEditable ? (store.selectedIndexedProject?.writePolicy ?? "Editable") : "Read-only"),
                    Fact(label: "Preview", value: mutationPreviewFact(store.mutationActionBarState)),
                    Fact(label: "Apply", value: mutationApplyFact(store.mutationActionBarState)),
                ])
                SourceLocationView(source: SourceLocation(path: species.sourceSpan.relativePath, symbol: species.speciesID, line: species.sourceSpan.startLine))
            } else {
                emptySidebarText(store.speciesCatalogLoadStatus.label)
            }
        }
    }

    private var trainerProperties: some View {
        sidebarSection("Properties", systemImage: "info.circle") {
            if let trainer = store.selectedTrainerDetail {
                propertyHeader(trainer.displayName, subtitle: trainer.trainerID, systemImage: "person.2", status: trainer.diagnostics.isEmpty ? .valid : .warning)
                propertyFacts([
                    Fact(label: "Class", value: trainer.trainerClass),
                    Fact(label: "Party", value: "\(trainer.party.count) Pokemon"),
                    Fact(label: "Battle", value: trainer.doubleBattle ? "Double" : "Single"),
                    Fact(label: "Items", value: "\(trainer.trainerItems.filter { $0 != "ITEM_NONE" }.count)"),
                    Fact(label: "Editable", value: trainer.isEditable ? "Yes" : "No"),
                    Fact(label: "Dirty", value: store.selectedTrainerIsDirty ? "Yes" : "No"),
                ])
                SourceLocationView(source: SourceLocation(path: trainer.sourceSpan.relativePath, symbol: trainer.trainerID, line: trainer.sourceSpan.startLine))
            } else {
                emptySidebarText(store.trainerCatalogLoadStatus.label)
            }
        }
    }

    private var movesProperties: some View {
        sidebarSection("Properties", systemImage: "info.circle") {
            if let move = store.selectedMoveDetail {
                propertyHeader(move.displayName, subtitle: move.moveID, systemImage: WorkbenchModule.moves.systemImage, status: move.status)
                propertyFacts([
                    Fact(label: "TM/HM", value: "\(move.tmhmLearners.count)"),
                    Fact(label: "Tutor", value: "\(move.tutorLearners.count)"),
                    Fact(label: "Learned By", value: "\(move.learnedBy.count)"),
                    Fact(label: "Editable", value: move.isEditable ? "Yes" : "No"),
                    Fact(label: "Dirty", value: store.selectedMoveIsDirty || !store.dirtySpeciesBatchDrafts.isEmpty ? "Yes" : "No"),
                    Fact(label: "Diagnostics", value: "\(move.diagnostics.count)"),
                    Fact(label: "Write Policy", value: move.isEditable ? (store.selectedIndexedProject?.writePolicy ?? "Editable") : "Read-only"),
                    Fact(label: "Compatibility Drafts", value: "\(store.dirtySpeciesBatchDrafts.count)"),
                    Fact(label: "Preview", value: mutationPreviewFact(store.mutationActionBarState)),
                    Fact(label: "Apply", value: mutationApplyFact(store.mutationActionBarState)),
                ])
                SourceLocationView(source: move.source)
            } else {
                emptySidebarText(store.moveCatalogLoadStatus.label)
            }
        }
    }

    private var itemsProperties: some View {
        sidebarSection("Properties", systemImage: "info.circle") {
            if let item = store.selectedItemDetail {
                propertyHeader(item.displayName, subtitle: item.itemID, systemImage: WorkbenchModule.items.systemImage, status: item.status)
                propertyFacts([
                    Fact(label: "Editable", value: item.isEditable ? "Yes" : "No"),
                    Fact(label: "Dirty", value: store.selectedItemIsDirty ? "Yes" : "No"),
                    Fact(label: "Diagnostics", value: "\(item.diagnostics.count)"),
                ] + item.facts.prefix(4))
                SourceLocationView(source: item.source)
            } else {
                emptySidebarText(store.itemCatalogLoadStatus.label)
            }
        }
    }

    private var scriptProperties: some View {
        sidebarSection("Properties", systemImage: "info.circle") {
            if let label = store.selectedScriptLabel {
                propertyHeader(label.label, subtitle: label.sourcePath, systemImage: "curlybraces", status: .valid)
                propertyFacts([
                    Fact(label: "Kind", value: label.kind.rawValue),
                    Fact(label: "Commands", value: "\(label.commands.count)"),
                    Fact(label: "Text Refs", value: "\(label.textReferences.count)"),
                ])
                SourceLocationView(source: SourceLocation(path: label.sourcePath, symbol: label.label, line: label.sourceSpan.startLine))
            } else if let source = store.selectedScriptSource {
                propertyHeader(source.path, subtitle: "\(source.module.rawValue) · \(source.role.rawValue)", systemImage: "doc.text", status: .valid)
                propertyFacts([
                    Fact(label: "Labels", value: "\(source.labelCount)"),
                    Fact(label: "Text Blocks", value: "\(source.textBlockCount)"),
                    Fact(label: "Diagnostics", value: "\(source.diagnosticCount)"),
                ])
            } else if let block = store.selectedScriptTextBlock {
                propertyHeader(block.label, subtitle: block.sourcePath, systemImage: "text.quote", status: .valid)
                propertyFacts([
                    Fact(label: "Preview", value: block.preview),
                    Fact(label: "Line", value: "\(block.sourceSpan.startLine)"),
                ])
            } else {
                emptySidebarText("No script row selected.")
            }
        }
    }

    private func genericRecordProperties(module: WorkbenchModule) -> some View {
        sidebarSection("Properties", systemImage: "info.circle") {
            if let record = store.selectedRecord(for: module) {
                propertyHeader(record.title, subtitle: record.subtitle, systemImage: module.systemImage, status: record.validation)
                propertyFacts(record.facts)
                SourceLocationView(source: record.source)
            } else {
                emptySidebarText("No \(module.title.lowercased()) row selected.")
            }
        }
    }

    private var graphicsProperties: some View {
        sidebarSection("Properties", systemImage: "info.circle") {
            if let row = store.selectedGraphicsReportRow {
                propertyHeader(row.title, subtitle: row.detail, systemImage: row.section.systemImage, status: row.status)
                propertyFacts([
                    Fact(label: "Section", value: row.section.rawValue),
                    Fact(label: "Kind", value: row.subtitle),
                ])
                SourceLocationView(source: row.source)
            } else {
                emptySidebarText("No graphics row selected.")
            }
        }
    }

    private var buildProperties: some View {
        sidebarSection("Properties", systemImage: "info.circle") {
            if let row = store.selectedBuildReportRow {
                propertyHeader(row.title, subtitle: row.detail, systemImage: row.section.systemImage, status: row.status)
                propertyFacts([
                    Fact(label: "Section", value: row.section.rawValue),
                    Fact(label: "Status", value: row.status.rawValue),
                    Fact(label: "Tab", value: store.selectedBuildWorkbenchTab.title),
                ])
                SourceLocationView(source: row.source)
            } else {
                emptySidebarText("No ship row selected.")
            }
        }
    }

    private var diagnosticProperties: some View {
        sidebarSection("Properties", systemImage: "info.circle") {
            if let row = store.selectedDiagnosticRow {
                propertyHeader(row.title, subtitle: row.message, systemImage: "exclamationmark.triangle", status: row.severity)
                propertyFacts([
                    Fact(label: "Bucket", value: store.selectedDiagnosticBucket.title),
                    Fact(label: "Severity", value: row.severity.rawValue),
                ])
                SourceLocationView(source: row.source)
            } else {
                emptySidebarText("No diagnostic selected.")
            }
        }
    }

    private var selectedMap: MapSummaryViewState? {
        guard let catalog = store.selectedMapCatalog else { return nil }
        return catalog.maps.first { $0.id == store.selectedMapID } ?? catalog.maps.first
    }

    private var currentMap: MapSummaryViewState? {
        guard let catalog = store.selectedMapCatalog else { return nil }
        if let selected = catalog.maps.first(where: { $0.id == store.selectedMapID }) {
            return selected
        }
        return catalog.maps.first
    }

    private var currentSpecies: PokemonHackCore.SpeciesDetail? {
        guard let catalog = store.selectedSpeciesCatalog else { return nil }
        if let selected = catalog.species.first(where: { $0.speciesID == selectedSpeciesID }) {
            return selected
        }
        return catalog.species.first
    }

    private var currentMove: MoveDetailViewState? {
        guard let catalog = store.selectedMoveCatalog else { return nil }
        if let selected = catalog.moves.first(where: { $0.moveID == selectedMoveID }) {
            return selected
        }
        return catalog.moves.first
    }

    private var selectedSpeciesID: String {
        if !store.selectedSpeciesID.isEmpty {
            return store.selectedSpeciesID
        }
        return store.selectedSpeciesDetail?.speciesID ?? ""
    }

    private var selectedMoveID: String {
        if !store.selectedMoveID.isEmpty {
            return store.selectedMoveID
        }
        return store.selectedMoveDetail?.moveID ?? ""
    }

    private var resourceCategoryOptions: [String] {
        [WorkbenchStore.allResourceAssetCategories] + (store.selectedAssetCatalog?.categoryTitles ?? [])
    }

    private func filteredMaps(in catalog: MapCatalogViewState) -> [MapSummaryViewState] {
        guard !store.searchText.isEmpty else { return catalog.maps }
        return catalog.maps.filter { map in
            map.name.localizedCaseInsensitiveContains(store.searchText)
                || map.mapID.localizedCaseInsensitiveContains(store.searchText)
                || map.groupName.localizedCaseInsensitiveContains(store.searchText)
                || (map.layout?.name.localizedCaseInsensitiveContains(store.searchText) == true)
                || map.source.path.localizedCaseInsensitiveContains(store.searchText)
        }
    }

    private func currentMapIsHidden(_ map: MapSummaryViewState) -> Bool {
        guard let catalog = store.selectedMapCatalog else { return false }
        return !filteredMaps(in: catalog).prefix(Self.mapRowLimit).contains { $0.id == map.id }
    }

    private func mapCapacityFact(_ map: MapSummaryViewState, for kind: PokemonHackCore.MapEventKind) -> String {
        guard let usage = map.eventCapacity.usages.first(where: { $0.kind == kind }) else {
            return "Unknown"
        }
        guard let limit = usage.limit else {
            return "\(usage.count)/?"
        }
        return usage.isOverLimit ? "\(usage.count)/\(limit) over" : "\(usage.count)/\(limit)"
    }

    private func currentSpeciesIsHidden(_ species: PokemonHackCore.SpeciesDetail) -> Bool {
        !store.filteredSpeciesDetails.prefix(Self.speciesRowLimit).contains { $0.speciesID == species.speciesID }
    }

    private func currentMoveIsHidden(_ move: MoveDetailViewState) -> Bool {
        !store.filteredMoveDetails.prefix(Self.moveRowLimit).contains { $0.moveID == move.moveID }
    }

    private func recentMaps(excluding currentID: String?) -> [MapSummaryViewState] {
        guard let catalog = store.selectedMapCatalog else { return [] }
        return store.recentMapTargets.compactMap { recent in
            let id = recent.target.rawIdentifier
            guard id != currentID else { return nil }
            return catalog.maps.first { $0.id == id }
        }
    }

    private func recentSpecies(excluding currentID: String?) -> [PokemonHackCore.SpeciesDetail] {
        guard let catalog = store.selectedSpeciesCatalog else { return [] }
        return store.recentSpeciesTargets.compactMap { recent in
            let id = recent.target.rawIdentifier
            guard id != currentID else { return nil }
            return catalog.species.first { $0.speciesID == id }
        }
    }

    private func recentMoves(excluding currentID: String?) -> [MoveDetailViewState] {
        guard let catalog = store.selectedMoveCatalog else { return [] }
        return store.recentMoveTargets.compactMap { recent in
            let id = recent.target.rawIdentifier
            guard id != currentID else { return nil }
            return catalog.moves.first { $0.moveID == id }
        }
    }

    private func selectModule(_ module: WorkbenchModule) {
        store.selectWorkbenchModule(module)
    }

    private func selectMap(_ mapID: String) {
        store.focusWorkbenchTarget(.map(mapID), search: .preserve)
    }

    private func selectSpecies(_ speciesID: String) {
        store.focusWorkbenchTarget(.species(speciesID), search: .preserve)
    }

    private func selectMove(_ moveID: String) {
        store.focusWorkbenchTarget(.move(moveID), search: .preserve)
    }

    private func revealMap(_ map: MapSummaryViewState) {
        store.focusWorkbenchTarget(.map(map.id), search: .replace(map.mapID))
    }

    private func revealSpecies(_ species: PokemonHackCore.SpeciesDetail) {
        store.focusWorkbenchTarget(.species(species.speciesID), search: .replace(species.speciesID))
    }

    private func revealMove(_ move: MoveDetailViewState) {
        store.selectedMoveWorkbenchFilter = .all
        store.focusWorkbenchTarget(.move(move.moveID), search: .replace(move.moveID))
    }

    private func dirtyCount(for module: WorkbenchModule) -> Int? {
        let count: Int
        switch module {
        case .pokemon:
            count = store.dirtySpeciesDraftCount
        case .moves:
            count = store.dirtyMoveDraftCount
        default:
            return nil
        }
        return count > 0 ? count : nil
    }

    private func dirtyBadgeText(forSpeciesID speciesID: String) -> String? {
        store.isSpeciesDirty(speciesID) ? "Dirty" : nil
    }

    private func dirtyBadgeText(forMoveID moveID: String) -> String? {
        store.isMoveDirty(moveID) ? "Dirty" : nil
    }

    private func mutationPreviewFact(_ state: MutationActionBarState) -> String {
        state.canPreview ? "Ready" : state.previewHelp
    }

    private func mutationApplyFact(_ state: MutationActionBarState) -> String {
        state.canApply ? "Ready" : state.applyHelp
    }

    private func isMutationToolDirty(_ target: WorkbenchToolbarMutationTarget) -> Bool {
        switch target {
        case .none:
            false
        case .map:
            store.hasStagedMapEdits
        case .pokemon:
            store.selectedSpeciesIsDirty
        case .pokemonBatch:
            !store.dirtySpeciesBatchDrafts.isEmpty
        case .trainer:
            store.selectedTrainerIsDirty
        case .move:
            store.selectedMoveIsDirty
        case .item:
            store.selectedItemIsDirty
        case .graphics:
            store.selectedGraphicsIsDirty
        case .ndsData:
            store.selectedNDSDataIsDirty
        }
    }

    private func hiddenTargetControls(
        detail: String,
        canClear: Bool,
        reveal: @escaping () -> Void,
        clear: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Button("Reveal", systemImage: "scope", action: reveal)
                Button("Clear", systemImage: "xmark.circle", action: clear)
                    .disabled(!canClear)
            }
            .font(.caption)
        }
        .padding(8)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
    }

    private func sidebarSection<Content: View>(
        _ title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func sidebarRows<Data: RandomAccessCollection, Row: View>(
        _ rows: Data,
        limit: Int,
        @ViewBuilder rowView: @escaping (Data.Element) -> Row
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if rows.isEmpty {
                emptySidebarText("No rows match the current search.")
            } else {
                ForEach(Array(rows.prefix(limit).enumerated()), id: \.offset) { _, row in
                    rowView(row)
                }

                if rows.count > limit {
                    Text("\(rows.count - limit) more rows hidden. Narrow the search to reveal them.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
        }
    }

    private func sidebarButton(
        id: String,
        title: String,
        subtitle: String,
        systemImage: String,
        isSelected: Bool,
        badgeText: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
                    .frame(width: 17)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.callout)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 4)
                if let badgeText {
                    compactBadge(badgeText)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(selectionBackground(isSelected))
        }
        .id(id)
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)")
        .accessibilityValue(rowAccessibilityValue(isSelected: isSelected, badgeText: badgeText))
    }

    private func selectionBackground(_ isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
    }

    private func compactBadge(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.14), in: Capsule())
            .foregroundStyle(Color.blue)
            .accessibilityLabel(text)
    }

    private func dirtyCountBadge(_ count: Int) -> some View {
        Label("\(count)", systemImage: "circle.fill")
            .labelStyle(.titleAndIcon)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.14), in: Capsule())
            .foregroundStyle(Color.blue)
            .help(count == 1 ? "1 dirty draft" : "\(count) dirty drafts")
            .accessibilityLabel(count == 1 ? "1 dirty draft" : "\(count) dirty drafts")
    }

    private func rowAccessibilityValue(isSelected: Bool, badgeText: String?) -> String {
        [isSelected ? "Selected" : nil, badgeText].compactMap { $0 }.joined(separator: ", ")
    }

    private func moduleAccessibilityValue(isSelected: Bool, dirtyCount: Int?) -> String {
        let dirtyText = dirtyCount.map { $0 == 1 ? "1 dirty draft" : "\($0) dirty drafts" }
        return [isSelected ? "Selected" : nil, dirtyText].compactMap { $0 }.joined(separator: ", ")
    }

    private func sidebarMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.caption.weight(.semibold))
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sidebarSubheading(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.top, 4)
    }

    private func propertyHeader(
        _ title: String,
        subtitle: String,
        systemImage: String,
        status: ValidationState?
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                Spacer(minLength: 6)
            }

            if let status {
                StatusPill(state: status)
            }
        }
    }

    private func propertyFacts(_ facts: [Fact]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(facts.prefix(10)) { fact in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(fact.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 6)
                    Text(fact.value)
                        .font(.caption.weight(.medium))
                        .multilineTextAlignment(.trailing)
                        .lineLimit(3)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private func emptySidebarText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func iconName(forResourceCategory category: String) -> String {
        switch category {
        case "maps":
            "map"
        case "layouts":
            "square.grid.3x3"
        case "scripts":
            "curlybraces"
        case "text":
            "text.quote"
        case "moves":
            "bolt"
        case "species", "learnsets", "evolutions", "pokedex":
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

    private func statSummary(_ stats: SpeciesBaseStats) -> String {
        [
            stats.hp,
            stats.attack,
            stats.defense,
            stats.speed,
            stats.spAttack,
            stats.spDefense,
        ]
        .map { value in
            value.map(String.init) ?? "?"
        }
        .joined(separator: "/")
    }
}
