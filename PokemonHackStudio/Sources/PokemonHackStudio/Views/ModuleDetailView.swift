import SwiftUI

struct ModuleDetailView: View {
    @ObservedObject var store: WorkbenchStore

    var body: some View {
        switch store.selection {
        case .dashboard:
            DashboardView(store: store)
        case .maps:
            MapEditorView(
                records: store.records(for: .maps),
                catalog: store.selectedMapCatalog,
                selectedMapID: $store.selectedMapID
            )
            .onAppear {
                store.loadSelectedMapCatalogIfNeeded()
            }
        case .trainers:
            TrainerEditorView(records: store.records(for: .trainers))
        case .items:
            CatalogEditorView(title: "Items", records: store.records(for: .items))
        case .pokemon:
            CatalogEditorView(title: "Pokemon", records: store.records(for: .pokemon))
        case .encounters:
            EncounterEditorView(records: store.records(for: .encounters))
        case .scripts:
            ScriptEditorView(records: store.records(for: .scripts))
        case .text:
            TextEditorWorkbenchView(records: store.records(for: .text))
        case .build:
            BuildWorkbenchView(
                target: store.selectedTarget,
                steps: store.buildSteps,
                indexedProject: store.selectedIndexedProject
            )
        case .issues:
            IssuesView(issues: store.issues, indexedProject: store.selectedIndexedProject)
        }
    }
}
