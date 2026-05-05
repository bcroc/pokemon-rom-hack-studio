import SwiftUI

struct EditorListShell<Content: View>: View {
    let title: String
    let records: [WorkbenchRecord]
    @ViewBuilder let content: (WorkbenchRecord) -> Content

    var body: some View {
        if records.isEmpty {
            EmptyModuleView(title: title)
                .navigationTitle(title)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(records) { record in
                        VStack(alignment: .leading, spacing: 14) {
                            SourceHeader(record: record)
                            content(record)
                        }
                        .padding(16)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(24)
            }
            .navigationTitle(title)
        }
    }
}

struct FactGrid: View {
    let facts: [Fact]

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 8) {
            ForEach(facts) { fact in
                GridRow {
                    Text(fact.label)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(fact.value)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }
}

struct NotesList: View {
    let notes: [String]

    var body: some View {
        EditorSection(title: "Notes") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(notes, id: \.self) { note in
                    Label(note, systemImage: "note.text")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
