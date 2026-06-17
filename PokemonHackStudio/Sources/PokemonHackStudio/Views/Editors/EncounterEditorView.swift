import SwiftUI

struct EncounterEditorView: View {
    let records: [WorkbenchRecord]

    var body: some View {
        EditorListShell(title: "Encounters", records: records) { record in
            EditorSection(title: "Encounter Table") {
                FactGrid(facts: record.facts)
            }

            NotesList(notes: record.notes)
        }
    }
}
