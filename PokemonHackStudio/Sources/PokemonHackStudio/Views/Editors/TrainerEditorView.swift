import SwiftUI

struct TrainerEditorView: View {
    let records: [WorkbenchRecord]

    var body: some View {
        EditorListShell(title: "Trainers", records: records) { record in
            EditorSection(title: "Trainer Definition") {
                FactGrid(facts: record.facts)
            }

            EditorSection(title: "Party Variants") {
                VStack(alignment: .leading, spacing: 8) {
                    PartyRow(slot: "1", species: "Wailmer", level: "18", item: "None")
                    PartyRow(slot: "2", species: "Shroomish", level: "18", item: "Oran Berry")
                    PartyRow(slot: "3", species: "Starter branch", level: "20", item: "None")
                }
            }

            NotesList(notes: record.notes)
        }
    }
}

private struct PartyRow: View {
    let slot: String
    let species: String
    let level: String
    let item: String

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16) {
            GridRow {
                Text(slot)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                Text(species)
                Text("Lv \(level)")
                    .foregroundStyle(.secondary)
                Text(item)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
