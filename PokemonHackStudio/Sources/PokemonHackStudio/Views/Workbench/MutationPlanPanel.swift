import SwiftUI

struct MutationPlanPanel: View {
    let context: MutationPlanPanelContext
    let layoutMode: WorkbenchLayoutMode
    let onPreview: () -> Void
    let onApply: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            summaryCounters

            if !context.changes.isEmpty || !context.appliedChanges.isEmpty || !context.diagnostics.isEmpty {
                detailColumns
            }
        }
        .padding(layoutMode.isCompact ? 12 : 14)
        .background(.regularMaterial)
    }

    @ViewBuilder
    private var header: some View {
        if layoutMode.isCompact {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    titleBlock
                    Spacer(minLength: 8)
                    StatusPill(state: context.status)
                }

                actionButtons
            }
        } else {
            HStack(alignment: .top, spacing: 12) {
                titleBlock

                Spacer()

                StatusPill(state: context.status)
                actionButtons
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(context.title)
                .font(.headline)
                .lineLimit(1)
            Text(context.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button("Preview", systemImage: "doc.text.magnifyingglass") {
                onPreview()
            }
            .disabled(!context.canPreview)
            .help(context.previewBlockedReason ?? "Preview staged source mutations")

            Button("Apply", systemImage: "checkmark.seal") {
                onApply()
            }
            .disabled(!context.canApply)
            .help(context.applyBlockedReason ?? "Apply previewed source mutations")

            Button("Discard", systemImage: "trash") {
                onDiscard()
            }
            .disabled(!context.canDiscard)
            .help("Discard staged source mutations")
        }
    }

    private var summaryCounters: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], alignment: .leading, spacing: 6) {
            Text("\(context.operationCount) staged")
            Text("\(context.changes.count) planned")
            Text("\(context.appliedChanges.count) applied")
            Text("\(context.diagnostics.count) diagnostics")
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var detailColumns: some View {
        if layoutMode.isCompact {
            VStack(alignment: .leading, spacing: 10) {
                panelColumns
            }
        } else {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    panelColumns
                }
                .padding(.bottom, 2)
            }
        }
    }

    @ViewBuilder
    private var panelColumns: some View {
        if !context.changes.isEmpty {
            panelColumn("Planned Changes") {
                VStack(spacing: 8) {
                    ForEach(context.changes.prefix(4)) { change in
                        planChangeRow(change)
                    }
                }
            }
            .frame(width: panelColumnWidth)
        }

        if !context.appliedChanges.isEmpty {
            panelColumn("Applied") {
                VStack(spacing: 8) {
                    ForEach(context.appliedChanges.prefix(4)) { change in
                        appliedChangeRow(change)
                    }
                }
            }
            .frame(width: panelColumnWidth)
        }

        if !context.diagnostics.isEmpty {
            panelColumn("Diagnostics") {
                VStack(spacing: 8) {
                    ForEach(context.diagnostics.prefix(4)) { diagnostic in
                        diagnosticRow(diagnostic)
                    }
                }
            }
            .frame(width: panelColumnWidth)
        }
    }

    private var panelColumnWidth: CGFloat? {
        layoutMode.isCompact ? nil : 300
    }

    private func panelColumn<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func planChangeRow(_ change: MutationPlanChangeRow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(change.path)
                .font(.caption.monospaced())
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)

            Text(change.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if let detail = change.detail {
                Text(detail)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func appliedChangeRow(_ change: MutationPlanAppliedChangeRow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(change.path)
                .font(.caption.monospaced())
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)

            Text("\(change.byteCount) bytes")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)

            Text(change.backupPath)
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func diagnosticRow(_ diagnostic: MutationPlanDiagnosticRow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(diagnostic.code)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                Spacer(minLength: 8)

                StatusPill(state: diagnostic.status)
            }

            Text(diagnostic.message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
