import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: WorkbenchStore

    var body: some View {
        UniversalIDEView(store: store, onOpenProject: openProjectPanel)
        .searchable(text: $store.searchText, placement: .toolbar, prompt: "Search sources")
        .onChange(of: store.selectedProjectID) { _, _ in
            store.refreshSelectedMapCatalog()
            store.loadSelectedModuleDataIfNeeded()
        }
        .onChange(of: store.openProjectPanelRequestID) { _, requestID in
            guard requestID != nil else { return }
            openProjectPanel()
            store.clearOpenProjectPanelRequest()
        }
        .confirmationDialog(
            store.pendingMapNavigationTitle,
            isPresented: Binding(
                get: { store.pendingMapNavigation != nil },
                set: { isPresented in
                    if !isPresented {
                        store.cancelPendingMapNavigation()
                    }
                }
            ),
            presenting: store.pendingMapNavigation
        ) { _ in
            Button(store.pendingMapNavigationPreviewTitle) {
                store.previewBeforePendingMapNavigation()
            }
            .disabled(!store.canPreviewPendingMapNavigationDraft)

            Button(store.pendingMapNavigationDiscardTitle, role: .destructive) {
                store.discardMapEditsAndContinueNavigation()
            }
            Button("Cancel", role: .cancel) {
                store.cancelPendingMapNavigation()
            }
        } message: { _ in
            Text(store.pendingMapNavigationMessage)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if store.hasIndexedProjects {
                    Picker("Project", selection: projectSelection) {
                        ForEach(store.indexedProjects) { project in
                            Text(project.menuTitle)
                                .tag(project.id)
                                .help(project.menuSubtitle)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minWidth: 150, idealWidth: 200, maxWidth: 240)
                } else {
                    Picker("Target", selection: $store.selectedTargetID) {
                        ForEach(store.targets) { target in
                            Text(target.name).tag(target.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minWidth: 110, idealWidth: 130, maxWidth: 150)
                }

                Divider()

                workspaceMenu
                refreshMenu

                Divider()

                Button("Command Palette", systemImage: "command") {
                    store.showCommandPalette()
                }
                .labelStyle(.iconOnly)
                .keyboardShortcut("k", modifiers: .command)
                .help("Command palette")

                Divider()

                mutationActions
                navigationMenu

                DiagnosticStatusButton(summary: store.diagnosticSummary) {
                    store.selectWorkbenchModule(.issues)
                }
            }
        }
    }

    private var workspaceMenu: some View {
        Menu {
            Button("Open Project...", systemImage: "folder.badge.plus") {
                openProjectPanel()
            }

            Divider()

            Button("Save Project", systemImage: "externaldrive.badge.checkmark") {
                store.saveProjectWorkspace()
            }
            .disabled(!store.canSaveProjectWorkspace)

            Button("Save Drafts", systemImage: "square.and.arrow.down") {
                store.saveDraftsNow()
            }
            .disabled(!store.canSaveProjectWorkspace)

            Button("Reload Saved Drafts", systemImage: "arrow.down.doc") {
                store.loadSavedWorkspaceForSelectedProject()
            }
            .disabled(!store.canSaveProjectWorkspace)

            Button("Discard Saved Drafts", systemImage: "trash") {
                store.discardSavedDrafts()
            }
            .disabled(!store.canSaveProjectWorkspace || (store.savedDraftCount == 0 && store.currentDraftCount == 0))

            Divider()

            Label("\(store.currentDraftCount) current · \(store.savedDraftCount) saved", systemImage: "tray.full")
            Label(store.workspaceLastSavedLabel, systemImage: store.workspaceAutosavePending ? "clock.badge" : "clock")
        } label: {
            Label("Workspace", systemImage: store.workspaceAutosavePending ? "externaldrive.badge.clock" : "externaldrive")
        }
        .labelStyle(.iconOnly)
        .help("Workspace saves and project files")
    }

    private var refreshMenu: some View {
        Menu {
            Button("Refresh \(store.selection.title)", systemImage: "arrow.triangle.2.circlepath") {
                store.refreshSelectedModuleContext()
            }
            .disabled(!store.hasIndexedProjects)

            Button("Refresh Project Indexes", systemImage: "arrow.clockwise") {
                store.refreshProjectIndexes()
            }

            Button("Refresh Health Checks", systemImage: "stethoscope") {
                store.refreshHealthChecks()
            }
            .disabled(!store.hasIndexedProjects)

            Button("Refresh Resource Library", systemImage: "externaldrive.connected.to.line.below") {
                store.refreshResourceLibrary()
            }
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
        .labelStyle(.iconOnly)
        .help("Refresh project and module data")
    }

    private var mutationActions: some View {
        MutationActionBar(
            state: store.mutationActionBarState,
            style: .toolbar,
            onPreview: store.previewToolbarMutationTarget,
            onApply: store.applyToolbarMutationTarget,
            onDiscard: store.discardToolbarMutationTarget
        )
    }

    private var navigationMenu: some View {
        Menu {
            ForEach(WorkbenchModuleGroup.allCases) { group in
                Section(group.rawValue) {
                    ForEach(group.modules) { module in
                        Button {
                            store.selectWorkbenchModule(module)
                        } label: {
                            Label(module.title, systemImage: module.systemImage)
                        }
                    }
                }
            }

            Divider()

            Button("Build Target", systemImage: "hammer") {
                store.showBuildCommandTab()
            }

            Button("Run Target", systemImage: "play.fill") {
                store.showRunCommandTab()
            }

            Button("Show Diagnostics", systemImage: "checkmark.seal") {
                store.selectWorkbenchModule(.issues)
            }
        } label: {
            Label(store.selection.title, systemImage: store.selection.systemImage)
        }
        .labelStyle(.iconOnly)
        .help("Navigate modules and ship surfaces")
    }

    private var projectSelection: Binding<String> {
        Binding {
            store.selectedProjectID
        } set: { projectID in
            store.requestProjectSelection(projectID)
        }
    }

    private func openProjectPanel() {
        let panel = NSOpenPanel()
        panel.title = "Open Pokemon Project"
        panel.prompt = "Open"
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.resolvesAliases = true

        guard panel.runModal() == .OK, let url = panel.url else { return }
        store.openProject(at: url)
    }
}
