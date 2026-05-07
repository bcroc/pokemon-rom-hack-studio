import SwiftUI

struct CatalogEditorView: View {
    let title: String
    let records: [WorkbenchRecord]

    var body: some View {
        EditorListShell(title: title, records: records) { record in
            EditorSection(title: "Table Row") {
                FactGrid(facts: record.facts)
            }

            SourcePreviewBlock(text: record.preview)
            NotesList(notes: record.notes)
        }
    }
}
