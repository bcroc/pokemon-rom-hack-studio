import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: WorkbenchStore

    var body: some View {
        NavigationSplitView {
            WorkbenchSidebarPanel(store: store)
                .navigationSplitViewColumnWidth(min: 320, ideal: 380, max: 460)
        } detail: {
            ModuleDetailView(store: store)
        }
        .searchable(text: $store.searchText, placement: .toolbar, prompt: "Search sources")
        .onChange(of: store.selectedProjectID) { _, _ in
            store.refreshSelectedMapCatalog()
            if store.selection == .maps {
                store.loadSelectedMapCatalogIfNeeded()
            }
        }
        .confirmationDialog(
            store.pendingMapNavigation?.title ?? "Staged map edits",
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
            Button("Preview Changes") {
                store.previewBeforePendingMapNavigation()
            }
            Button("Discard and Continue", role: .destructive) {
                store.discardMapEditsAndContinueNavigation()
            }
            Button("Cancel", role: .cancel) {
                store.cancelPendingMapNavigation()
            }
        } message: { pending in
            Text(pending.message)
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

                Button("Open Project", systemImage: "folder.badge.plus") {
                    openProjectPanel()
                }
                .labelStyle(.iconOnly)
                .help("Open project")
                Button("Refresh", systemImage: "arrow.clockwise") {
                    store.refreshProjectIndexes()
                }
                .labelStyle(.iconOnly)
                .help("Refresh project indexes")
                Button("Build", systemImage: "hammer") {
                    store.selection = .build
                }
                .labelStyle(.iconOnly)
                .help("Show build workbench")
                Button("Run", systemImage: "play.fill") {
                    store.selection = .build
                }
                .labelStyle(.iconOnly)
                .help("Show run and playtest workbench")
                Button("Validate", systemImage: "checkmark.seal") {
                    store.selection = .issues
                }
                .labelStyle(.iconOnly)
                .help("Show diagnostics")

                DiagnosticStatusButton(summary: store.diagnosticSummary) {
                    store.selection = .issues
                }
            }
        }
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
