import SwiftUI

struct RecordSummaryRow: View {
    let record: WorkbenchRecord

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: record.module.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 5) {
                Text(record.title)
                    .font(.headline)
                Text(record.subtitle)
                    .foregroundStyle(.secondary)
                SourceLocationView(source: record.source)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                DirtyPill(isDirty: record.isDirty)
                StatusPill(state: record.validation)
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}
