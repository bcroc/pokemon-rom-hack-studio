import SwiftUI

struct SourceLocationView: View {
    let source: SourceLocation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(source.label, systemImage: "doc.text.magnifyingglass")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
                .help(source.label)

            Text(source.symbol)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
                .help(source.symbol)
        }
    }
}

struct SourceHeader: View {
    let record: WorkbenchRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.title)
                        .font(.title2.weight(.semibold))
                    Text(record.subtitle)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    DirtyPill(isDirty: record.isDirty)
                    StatusPill(state: record.validation)
                }
            }

            SourceLocationView(source: record.source)

            HStack {
                ForEach(record.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: Capsule())
                }
            }
        }
    }
}
