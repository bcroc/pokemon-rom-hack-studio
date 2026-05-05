import SwiftUI

struct EncounterEditorView: View {
    let records: [WorkbenchRecord]

    var body: some View {
        EditorListShell(title: "Encounters", records: records) { record in
            EditorSection(title: "Encounter Table") {
                FactGrid(facts: record.facts)
            }

            EditorSection(title: "Slot Preview") {
                VStack(alignment: .leading, spacing: 8) {
                    EncounterSlot(percent: "20%", species: "Poochyena", level: "3")
                    EncounterSlot(percent: "20%", species: "Zigzagoon", level: "3")
                    EncounterSlot(percent: "10%", species: "Target-gated species", level: "5")
                }
            }

            NotesList(notes: record.notes)
        }
    }
}

private struct EncounterSlot: View {
    let percent: String
    let species: String
    let level: String

    var body: some View {
        HStack {
            Text(percent)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .leading)
            Text(species)
            Spacer()
            Text("Lv \(level)")
                .foregroundStyle(.secondary)
        }
    }
}
