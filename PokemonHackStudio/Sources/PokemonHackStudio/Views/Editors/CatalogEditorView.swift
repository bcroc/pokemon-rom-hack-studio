import SwiftUI

struct CatalogEditorView: View {
    let title: String
    let records: [WorkbenchRecord]

    var body: some View {
        EditorListShell(title: title, records: records) { record in
            EditorSection(title: "Table Row") {
                FactGrid(facts: record.facts)
            }

            EditorSection(title: "Linked Source Tables") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Primary definition, constants, icon, and text labels are surfaced as source references.", systemImage: "link")
                    Label("Mock controls show intended edit points but do not mutate headers or data files.", systemImage: "lock.doc")
                }
                .foregroundStyle(.secondary)
            }

            NotesList(notes: record.notes)
        }
    }
}
