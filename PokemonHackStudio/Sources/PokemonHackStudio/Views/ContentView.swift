import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: WorkbenchStore

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $store.selection, issueCount: store.issueCount)
                .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
        } detail: {
            ModuleDetailView(store: store)
        }
        .searchable(text: $store.searchText, placement: .toolbar, prompt: "Search sources")
        .onChange(of: store.selectedProjectID) { _ in
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
                            Text(project.title).tag(project.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)
                } else {
                    Picker("Target", selection: $store.selectedTargetID) {
                        ForEach(store.targets) { target in
                            Text(target.name).tag(target.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }

                Divider()

                Button("Open Project", systemImage: "folder.badge.plus") {
                    openProjectPanel()
                }
                Button("Refresh", systemImage: "arrow.clockwise") {
                    store.refreshProjectIndexes()
                }
                Button("Build", systemImage: "hammer") {}
                Button("Run", systemImage: "play.fill") {}
                Button("Validate", systemImage: "checkmark.seal") {}

                IssueCountBadge(count: store.issueCount)
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
