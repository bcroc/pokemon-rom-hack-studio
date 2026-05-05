import SwiftUI

struct ScriptEditorView: View {
    let records: [WorkbenchRecord]

    var body: some View {
        EditorListShell(title: "Scripts", records: records) { record in
            EditorSection(title: "Script Outline") {
                VStack(alignment: .leading, spacing: 8) {
                    ScriptCommandRow(command: "lock", detail: "Acquire player control")
                    ScriptCommandRow(command: "msgbox", detail: "Show linked text symbol")
                    ScriptCommandRow(command: "applymovement", detail: "Reference movement include")
                    ScriptCommandRow(command: "release", detail: "Return player control")
                }
            }

            EditorSection(title: "Source Links") {
                FactGrid(facts: record.facts)
            }

            NotesList(notes: record.notes)
        }
    }
}

private struct ScriptCommandRow: View {
    let command: String
    let detail: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(command)
                .font(.system(.body, design: .monospaced))
                .frame(width: 130, alignment: .leading)
            Text(detail)
                .foregroundStyle(.secondary)
        }
    }
}
