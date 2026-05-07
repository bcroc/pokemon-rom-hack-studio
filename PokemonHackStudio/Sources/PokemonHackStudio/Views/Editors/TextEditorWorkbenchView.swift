import SwiftUI

struct TextEditorWorkbenchView: View {
    let records: [WorkbenchRecord]

    var body: some View {
        EditorListShell(title: "Text", records: records) { record in
            EditorSection(title: "String Facts") {
                FactGrid(facts: record.facts)
            }

            SourcePreviewBlock(text: record.preview)
            NotesList(notes: record.notes)
        }
    }
}
