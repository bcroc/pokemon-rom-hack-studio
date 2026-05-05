import SwiftUI

struct TextEditorWorkbenchView: View {
    let records: [WorkbenchRecord]

    var body: some View {
        EditorListShell(title: "Text", records: records) { record in
            EditorSection(title: "String Preview") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PROF. BIRCH: Hey! Don't go out!\\p")
                        .font(.system(.body, design: .monospaced))
                    Text("Control codes are tokenized and displayed read-only in this mockup.")
                        .foregroundStyle(.secondary)
                }
            }

            EditorSection(title: "References") {
                FactGrid(facts: record.facts)
            }

            NotesList(notes: record.notes)
        }
    }
}
