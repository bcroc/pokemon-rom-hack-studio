import SwiftUI

struct UniversalIDEView: View {
    @ObservedObject var store: WorkbenchStore
    let onOpenProject: () -> Void

    private let navigatorWidth: CGFloat = 286
    private let inspectorWidth: CGFloat = 310

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                IDEProjectNavigator(store: store, onOpenProject: onOpenProject)
                    .frame(width: navigatorWidth)

                Divider()

                VStack(spacing: 0) {
                    IDEEditorTabsBar(store: store)

                    Divider()

                    ModuleDetailView(store: store)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                IDEInspectorPanel(store: store)
                    .frame(width: inspectorWidth)
            }

            Divider()

            IDEActivityConsole(store: store)
                .frame(height: store.bottomPanelHeight)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: commandPaletteBinding) {
            IDECommandPalette(store: store)
                .frame(minWidth: 640, idealWidth: 700, maxWidth: 760, minHeight: 520)
        }
    }

    private var commandPaletteBinding: Binding<Bool> {
        Binding {
            store.commandPaletteState.isPresented
        } set: { isPresented in
            if isPresented {
                store.showCommandPalette()
            } else {
                store.hideCommandPalette()
            }
        }
    }
}

private struct IDEProjectNavigator: View {
    @ObservedObject var store: WorkbenchStore
    let onOpenProject: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(store.workbenchNavigatorNodes) { node in
                        navigatorNode(node, depth: 0)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            }
        }
        .background(Color(nsColor: .underPageBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: store.selectedProjectIdentity.systemImage)
                    .foregroundStyle(.secondary)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 2) {
                    Text(store.selectedProjectIdentity.title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)

                    Text(store.selectedProjectIdentity.writePolicy.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Button("Open Project", systemImage: "folder.badge.plus", action: onOpenProject)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help("Open project")
            }

            HStack(spacing: 6) {
                Text(store.selectedProjectIdentity.writePolicy.isWritable ? "Writable" : "Guarded")
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.quaternary, in: Capsule())

                Text(store.workspaceAutosavePending ? "Autosave pending" : store.workspaceLastSavedLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(10)
    }

    private func navigatorNode(_ node: WorkbenchNavigatorNode, depth: Int) -> AnyView {
        let isGroup = !node.children.isEmpty
        return AnyView(VStack(alignment: .leading, spacing: 3) {
            Button {
                if isGroup {
                    store.toggleNavigatorExpansion(node.id)
                } else {
                    store.selectNavigatorNode(node)
                }
            } label: {
                HStack(spacing: 7) {
                    if isGroup {
                        Image(systemName: store.expandedNavigatorNodeIDs.contains(node.id) ? "chevron.down" : "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .frame(width: 10)
                            .foregroundStyle(.secondary)
                    } else {
                        Spacer()
                            .frame(width: 10)
                    }

                    Image(systemName: node.systemImage)
                        .frame(width: 17)
                        .foregroundStyle(iconTint(for: node.status))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(node.title)
                            .font(depth == 0 ? .caption.weight(.semibold) : .caption)
                            .lineLimit(1)

                        if depth > 0 {
                            Text(node.subtitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 8)

                    if let badge = node.badge {
                        Text(badge)
                            .font(.caption2.weight(.medium))
                            .monospacedDigit()
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.leading, CGFloat(depth * 12))
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .background(selectionBackground(for: node), in: RoundedRectangle(cornerRadius: 6))
            .help(node.subtitle)

            if isGroup, store.expandedNavigatorNodeIDs.contains(node.id) {
                ForEach(node.children) { child in
                    navigatorNode(child, depth: depth + 1)
                }
            }
        })
    }

    private func selectionBackground(for node: WorkbenchNavigatorNode) -> Color {
        store.navigatorSelectionID == node.id ? Color.accentColor.opacity(0.16) : Color.clear
    }

    private func iconTint(for status: ValidationState?) -> Color {
        switch status {
        case .valid:
            .green
        case .warning:
            .orange
        case .error:
            .red
        case nil:
            .secondary
        }
    }
}

private struct IDEEditorTabsBar: View {
    @ObservedObject var store: WorkbenchStore

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(store.editorTabs) { tab in
                        tabButton(tab)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }

            Divider()

            Button("Command Palette", systemImage: "command") {
                store.showCommandPalette()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .help("Command palette")
            .padding(.horizontal, 10)
        }
        .frame(height: 42)
        .background(.bar)
    }

    private func tabButton(_ tab: WorkbenchEditorTab) -> some View {
        HStack(spacing: 6) {
            Button {
                store.activateEditorTab(tab)
            } label: {
                Label(tab.title, systemImage: tab.systemImage)
                    .font(.caption.weight(store.activeEditorTabID == tab.id ? .semibold : .regular))
                    .lineLimit(1)
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.plain)
            .help(tab.subtitle)

            Button("Close", systemImage: "xmark") {
                store.closeEditorTab(tab)
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .disabled(store.editorTabs.count == 1)
            .help("Close tab")
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .frame(minWidth: 92, maxWidth: 190)
        .background(
            store.activeEditorTabID == tab.id ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor),
            in: RoundedRectangle(cornerRadius: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(store.activeEditorTabID == tab.id ? Color.accentColor.opacity(0.45) : Color.secondary.opacity(0.12))
        )
    }
}

private struct IDEInspectorPanel: View {
    @ObservedObject var store: WorkbenchStore

    var body: some View {
        VStack(spacing: 0) {
            Picker("Inspector", selection: $store.inspectorMode) {
                ForEach(WorkbenchInspectorMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.systemImage)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(10)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    switch store.inspectorMode {
                    case .source:
                        sourceInspector
                    case .selection:
                        selectionInspector
                    case .diagnostics:
                        diagnosticsInspector
                    case .mutation:
                        mutationInspector
                    case .artifacts:
                        artifactInspector
                    }
                }
                .padding(12)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var sourceInspector: some View {
        VStack(alignment: .leading, spacing: 12) {
            inspectorHeader(
                title: store.selection.title,
                subtitle: store.selectedIndexedProject?.rootPath ?? store.selectedProjectIdentity.rootDisplay,
                systemImage: store.selection.systemImage,
                status: store.moduleStatus(for: store.selection)
            )

            keyValueSection("Project") {
                inspectorFact("Profile", store.selectedIndexedProject?.profile ?? store.selectedTarget.name)
                inspectorFact("Write Policy", store.selectedIndexedProject?.writePolicy ?? store.selectedProjectIdentity.writePolicy.title)
                inspectorFact("Sources", "\(store.selectedIndexedProject?.existingSourceDocumentCount ?? 0)/\(store.selectedIndexedProject?.sourceDocumentCount ?? 0)")
                inspectorFact("References", "\(store.workbenchNavigatorNodes.first { $0.id == WorkbenchNavigatorGroup.references.id }?.children.count ?? 0)")
            }

            if let row = store.selectedDiagnosticRow {
                keyValueSection("Focused Source") {
                    inspectorFact("Symbol", row.source.symbol.isEmpty ? "Unknown" : row.source.symbol)
                    inspectorFact("Path", row.source.path)
                    inspectorFact("Line", String(row.source.line))
                }
            }
        }
    }

    private var selectionInspector: some View {
        VStack(alignment: .leading, spacing: 12) {
            inspectorHeader(
                title: store.activeEditorTab?.title ?? store.selection.title,
                subtitle: store.activeEditorTab?.subtitle ?? store.selection.subtitle,
                systemImage: store.activeEditorTab?.systemImage ?? store.selection.systemImage,
                status: store.moduleStatus(for: store.selection)
            )

            keyValueSection("Selection") {
                inspectorFact("Navigator", store.navigatorSelectionID)
                inspectorFact("Open Tabs", "\(store.editorTabs.count)")
                inspectorFact("Search", store.searchText.isEmpty ? "None" : store.searchText)
                inspectorFact("Recent Commands", "\(store.recentCommandIDs.count)")
            }

            if store.selection == .maps {
                keyValueSection("Map Workspace") {
                    inspectorFact("Maps", "\(store.selectedMapCatalog?.mapCount ?? 0)")
                    inspectorFact("Layouts", "\(store.selectedMapCatalog?.layoutCount ?? 0)")
                    inspectorFact("Draft", store.currentModuleEditorSession.isDirty ? "Dirty" : "Clean")
                }
            }

            if store.selection == .resources {
                keyValueSection("Resources") {
                    inspectorFact("Assets", "\(store.selectedAssetCatalog?.assetCount ?? 0)")
                    inspectorFact("Library Entries", "\(store.resourceLibrary?.entryCount ?? 0)")
                    inspectorFact("Mode", store.selectedResourceLibraryMode.title)
                }
            }
        }
    }

    private var diagnosticsInspector: some View {
        VStack(alignment: .leading, spacing: 12) {
            inspectorHeader(
                title: store.diagnosticSummary.compactLabel,
                subtitle: store.diagnosticSummary.detail,
                systemImage: WorkbenchInspectorMode.diagnostics.systemImage,
                status: store.diagnosticSummary.status
            )

            VStack(alignment: .leading, spacing: 10) {
                ForEach(store.selectedDiagnosticRows.prefix(8)) { diagnostic in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(diagnostic.title)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            StatusPill(state: diagnostic.severity)
                        }

                        Text(diagnostic.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(10)
                    .background(.background, in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    private var mutationInspector: some View {
        let state = store.mutationActionBarState
        return VStack(alignment: .leading, spacing: 12) {
            inspectorHeader(
                title: state.title,
                subtitle: state.previewHelp,
                systemImage: state.systemImage,
                status: store.currentModuleEditorSession.stage.validationState
            )

            MutationActionBar(
                state: state,
                style: .sidebar,
                onPreview: store.previewToolbarMutationTarget,
                onApply: store.applyToolbarMutationTarget,
                onDiscard: store.discardToolbarMutationTarget
            )

            keyValueSection("Execution Gates") {
                inspectorFact("Preview", state.canPreview ? "Available" : state.previewHelp)
                inspectorFact("Apply", state.canApply ? "Available" : state.applyHelp)
                inspectorFact("Discard", state.canDiscard ? "Available" : state.discardHelp)
            }
        }
    }

    private var artifactInspector: some View {
        VStack(alignment: .leading, spacing: 12) {
            inspectorHeader(
                title: "Artifacts",
                subtitle: "Build, patch, resource, capture, and mutation outputs.",
                systemImage: WorkbenchInspectorMode.artifacts.systemImage,
                status: store.visibleIDEActivityEvents.first?.status
            )

            keyValueSection("Ship Surface") {
                inspectorFact("Build Rows", "\(store.filteredBuildReportRows.count)")
                inspectorFact("Build Logs", "\(store.selectedBuildRunLogLines.count)")
                inspectorFact("Activity Events", "\(store.currentIDEActivityEvents.count)")
                inspectorFact("Patch Artifacts", "\(store.selectedPatchArtifactLibrary?.items.count ?? 0)")
            }

            ForEach(store.currentIDEActivityEvents.prefix(6)) { event in
                activityEventRow(event)
            }
        }
    }

    private func inspectorHeader(
        title: String,
        subtitle: String,
        systemImage: String,
        status: ValidationState?
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: systemImage)
                    .frame(width: 18)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                Spacer(minLength: 8)
            }

            if let status {
                StatusPill(state: status)
            }
        }
    }

    private func keyValueSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private func inspectorFact(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
                .lineLimit(3)
                .textSelection(.enabled)
        }
        .font(.caption)
    }

    private func activityEventRow(_ event: WorkbenchActivityEvent) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: event.category.systemImage)
                .frame(width: 16)
                .foregroundStyle(iconTint(for: event.status))

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                Text(event.detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 6))
    }

    private func iconTint(for status: ValidationState) -> Color {
        switch status {
        case .valid:
            .green
        case .warning:
            .orange
        case .error:
            .red
        }
    }
}

private struct IDEActivityConsole: View {
    @ObservedObject var store: WorkbenchStore

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Picker("Activity Mode", selection: $store.bottomPanelMode) {
                    ForEach(WorkbenchBottomPanelMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.systemImage)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 420)

                Picker("Filter", selection: activityFilterBinding) {
                    Text("All").tag("all")
                    ForEach(WorkbenchActivityCategory.allCases) { category in
                        Text(category.rawValue).tag(category.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 130)
                .help("Activity filter")

                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: "rectangle.compress.vertical")
                    Slider(value: $store.bottomPanelHeight, in: 150...340)
                        .frame(width: 120)
                }
                .foregroundStyle(.secondary)
                .help("Bottom panel height")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.bar)

            Divider()

            if store.visibleIDEActivityEvents.isEmpty {
                ContentUnavailableView(
                    "No activity",
                    systemImage: "waveform.path.ecg",
                    description: Text("Build, patch, playtest, mutation, resource, and diagnostic activity appears here.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(store.visibleIDEActivityEvents) { event in
                            consoleRow(event)
                        }
                    }
                    .padding(10)
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var activityFilterBinding: Binding<String> {
        Binding {
            store.activityCategoryFilter?.rawValue ?? "all"
        } set: { value in
            store.activityCategoryFilter = WorkbenchActivityCategory(rawValue: value)
        }
    }

    private func consoleRow(_ event: WorkbenchActivityEvent) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Label(event.category.rawValue, systemImage: event.category.systemImage)
                .font(.caption.weight(.semibold))
                .frame(width: 112, alignment: .leading)

            Text(event.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .frame(width: 170, alignment: .leading)

            Text(event.detail)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .textSelection(.enabled)

            Spacer(minLength: 8)

            StatusPill(state: event.status)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct IDECommandPalette: View {
    @ObservedObject var store: WorkbenchStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "command")
                    .foregroundStyle(.secondary)

                TextField("Search commands", text: $store.commandPaletteState.searchText)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .onSubmit(executeSelectedCommand)

                Button("Close", systemImage: "xmark") {
                    store.hideCommandPalette()
                    dismiss()
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .help("Close command palette")
            }
            .padding(14)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(store.filteredWorkbenchCommands) { command in
                            commandRow(command)
                                .id(command.id)
                        }
                    }
                    .padding(10)
                }
                .onChange(of: store.commandPaletteState.selectedCommandID) { _, commandID in
                    guard let commandID else { return }
                    proxy.scrollTo(commandID, anchor: .center)
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            store.commandPaletteState.selectedCommandID = store.filteredWorkbenchCommands.first?.id
        }
    }

    private func commandRow(_ command: WorkbenchCommand) -> some View {
        Button {
            store.executeCommand(command)
            dismiss()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: command.systemImage)
                    .frame(width: 20)
                    .foregroundStyle(command.availability.isEnabled ? Color.accentColor : Color.secondary)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(command.title)
                            .font(.headline)
                            .lineLimit(1)

                        Text(command.scope)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                    }

                    Text(command.availability.disabledReason ?? command.subtitle)
                        .font(.caption)
                        .foregroundStyle(command.availability.isEnabled ? Color(nsColor: .secondaryLabelColor) : Color.orange)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                if let keyboardHint = command.keyboardHint {
                    Text(keyboardHint)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }

                if command.availability.isGuarded {
                    Image(systemName: command.availability.isEnabled ? "lock.open" : "lock")
                        .foregroundStyle(command.availability.isEnabled ? .green : .orange)
                }
            }
            .contentShape(Rectangle())
            .padding(11)
            .background(commandBackground(for: command), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(!command.availability.isEnabled)
        .help(command.availability.disabledReason ?? command.subtitle)
        .simultaneousGesture(TapGesture().onEnded {
            store.commandPaletteState.selectedCommandID = command.id
        })
    }

    private func commandBackground(for command: WorkbenchCommand) -> Color {
        if store.commandPaletteState.selectedCommandID == command.id {
            return Color.accentColor.opacity(0.16)
        }
        return command.availability.isEnabled ? Color(nsColor: .controlBackgroundColor) : Color.orange.opacity(0.08)
    }

    private func executeSelectedCommand() {
        guard
            let commandID = store.commandPaletteState.selectedCommandID,
            let command = store.filteredWorkbenchCommands.first(where: { $0.id == commandID })
        else { return }
        store.executeCommand(command)
        dismiss()
    }
}
