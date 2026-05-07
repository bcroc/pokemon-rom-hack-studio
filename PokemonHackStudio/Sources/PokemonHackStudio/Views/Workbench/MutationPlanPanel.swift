import PokemonHackCore
import SwiftUI

struct MutationPlanPanelContext {
    let title: String
    let summary: String
    let status: ValidationState
    let operationCount: Int
    let changes: [MutationPlanChangeRow]
    let appliedChanges: [MutationPlanAppliedChangeRow]
    let diagnostics: [MutationPlanDiagnosticRow]
    let canPreview: Bool
    let canApply: Bool
    let canDiscard: Bool
    let previewBlockedReason: String?
    let applyBlockedReason: String?
}

struct MutationPlanChangeRow: Identifiable {
    let id: String
    let path: String
    let summary: String
    let detail: String?
}

struct MutationPlanAppliedChangeRow: Identifiable {
    let id: String
    let path: String
    let backupPath: String
    let byteCount: Int
}

struct MutationPlanDiagnosticRow: Identifiable {
    let id: String
    let code: String
    let message: String
    let status: ValidationState
}

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

extension MutationPlanPanelContext {
    @MainActor
    static func map(session: MapEditorSession) -> MutationPlanPanelContext? {
        guard session.isDirty
            || session.latestMapEditPlan != nil
            || session.latestMapApplyResult != nil
            || session.needsDocumentReloadAfterApply
        else {
            return nil
        }

        let plan = session.latestMapEditPlan
        let result = session.latestMapApplyResult
        let planDiagnostics = plan?.diagnostics ?? []
        let applyDiagnostics = result?.diagnostics ?? []
        let diagnostics = (planDiagnostics + applyDiagnostics).map { MutationPlanDiagnosticRow(diagnostic: $0) }
        let status = Self.status(
            diagnostics: diagnostics,
            isApplyReady: session.canApplySelectedMapMutationPlan,
            hasAppliedChanges: !(result?.appliedChanges.isEmpty ?? true)
        )

        return MutationPlanPanelContext(
            title: plan?.mutationPlan.title ?? "Map Mutation Plan",
            summary: Self.summary(plan: plan, result: result, session: session),
            status: status,
            operationCount: session.mapEditOperations.count,
            changes: (plan?.changes ?? []).map { MutationPlanChangeRow(change: $0) },
            appliedChanges: (result?.appliedChanges ?? []).map { MutationPlanAppliedChangeRow(change: $0) },
            diagnostics: diagnostics,
            canPreview: session.canPreviewSelectedMapMutationPlan,
            canApply: session.canApplySelectedMapMutationPlan,
            canDiscard: session.canDiscardMapEdits,
            previewBlockedReason: session.previewBlockedReason,
            applyBlockedReason: session.applyBlockedReason
        )
    }

    @MainActor
    static func trainer(
        plan: TrainerEditPlan?,
        result: TrainerApplyResult?,
        isDirty: Bool,
        canPreview: Bool,
        canApply: Bool,
        canDiscard: Bool,
        previewBlockedReason: String?,
        applyBlockedReason: String?
    ) -> MutationPlanPanelContext? {
        guard isDirty || plan != nil || result != nil else {
            return nil
        }

        let planDiagnostics = plan?.diagnostics ?? []
        let applyDiagnostics = result?.diagnostics ?? []
        let diagnostics = (planDiagnostics + applyDiagnostics).map { MutationPlanDiagnosticRow(diagnostic: $0) }
        let status = Self.status(
            diagnostics: diagnostics,
            isApplyReady: canApply,
            hasAppliedChanges: !(result?.appliedChanges.isEmpty ?? true)
        )

        return MutationPlanPanelContext(
            title: plan?.mutationPlan.title ?? "Trainer Mutation Plan",
            summary: Self.trainerSummary(plan: plan, result: result, isDirty: isDirty),
            status: status,
            operationCount: isDirty ? 1 : 0,
            changes: (plan?.changes ?? []).map { MutationPlanChangeRow(change: $0) },
            appliedChanges: (result?.appliedChanges ?? []).map { MutationPlanAppliedChangeRow(change: $0) },
            diagnostics: diagnostics,
            canPreview: canPreview,
            canApply: canApply,
            canDiscard: canDiscard,
            previewBlockedReason: previewBlockedReason,
            applyBlockedReason: applyBlockedReason
        )
    }

    @MainActor
    static func species(
        plan: SpeciesEditPlan?,
        result: SpeciesApplyResult?,
        isDirty: Bool,
        canPreview: Bool,
        canApply: Bool,
        canDiscard: Bool,
        previewBlockedReason: String?,
        applyBlockedReason: String?
    ) -> MutationPlanPanelContext? {
        guard isDirty || plan != nil || result != nil else {
            return nil
        }

        let planDiagnostics = plan?.diagnostics ?? []
        let applyDiagnostics = result?.diagnostics ?? []
        let diagnostics = (planDiagnostics + applyDiagnostics).map { MutationPlanDiagnosticRow(diagnostic: $0) }
        let status = Self.status(
            diagnostics: diagnostics,
            isApplyReady: canApply,
            hasAppliedChanges: !(result?.appliedChanges.isEmpty ?? true)
        )

        return MutationPlanPanelContext(
            title: plan?.mutationPlan.title ?? "Pokemon Mutation Plan",
            summary: Self.speciesSummary(plan: plan, result: result, isDirty: isDirty),
            status: status,
            operationCount: isDirty ? 1 : 0,
            changes: (plan?.changes ?? []).map { MutationPlanChangeRow(change: $0) },
            appliedChanges: (result?.appliedChanges ?? []).map { MutationPlanAppliedChangeRow(change: $0) },
            diagnostics: diagnostics,
            canPreview: canPreview,
            canApply: canApply,
            canDiscard: canDiscard,
            previewBlockedReason: previewBlockedReason,
            applyBlockedReason: applyBlockedReason
        )
    }

    private static func status(
        diagnostics: [MutationPlanDiagnosticRow],
        isApplyReady: Bool,
        hasAppliedChanges: Bool
    ) -> ValidationState {
        if diagnostics.contains(where: { $0.status == .error }) {
            return .error
        }

        if isApplyReady || hasAppliedChanges {
            return .valid
        }

        return .warning
    }

    @MainActor
    private static func summary(
        plan: MapEditPlan?,
        result: MapApplyResult?,
        session: MapEditorSession
    ) -> String {
        if let result, !result.appliedChanges.isEmpty {
            return "Applied \(result.appliedChanges.count) source file change(s); backups are recorded for review."
        }

        if let plan {
            return plan.mutationPlan.summary
        }

        if session.needsDocumentReloadAfterApply {
            return "Reload the map before staging additional source edits."
        }

        return "\(session.mapEditOperations.count) staged map edit(s) waiting for preview."
    }

    private static func trainerSummary(
        plan: TrainerEditPlan?,
        result: TrainerApplyResult?,
        isDirty: Bool
    ) -> String {
        if let result, !result.appliedChanges.isEmpty {
            return "Applied \(result.appliedChanges.count) trainer source file change(s); backups are recorded for review."
        }

        if let result, !result.diagnostics.isEmpty {
            return "Trainer apply is blocked until the reported diagnostics are resolved."
        }

        if let plan {
            return plan.mutationPlan.summary
        }

        if isDirty {
            return "Trainer edits are staged locally and waiting for source mutation preview."
        }

        return "No trainer edits are staged."
    }

    private static func speciesSummary(
        plan: SpeciesEditPlan?,
        result: SpeciesApplyResult?,
        isDirty: Bool
    ) -> String {
        if let result, !result.appliedChanges.isEmpty {
            return "Applied \(result.appliedChanges.count) Pokemon source file change(s); backups are recorded for review."
        }

        if let result, !result.diagnostics.isEmpty {
            return "Pokemon apply is blocked until the reported diagnostics are resolved."
        }

        if let plan {
            return plan.mutationPlan.summary
        }

        if isDirty {
            return "Pokemon edits are staged locally and waiting for source mutation preview."
        }

        return "No Pokemon edits are staged."
    }
}

private extension MutationPlanChangeRow {
    init(change: MapEditFileChange) {
        id = change.id
        path = change.path
        summary = change.summary
        detail = "\(change.originalByteCount) -> \(change.newByteCount) bytes"
    }

    init(change: TrainerEditFileChange) {
        id = change.id
        path = change.path
        summary = change.summary
        detail = "\(change.originalByteCount) -> \(change.newByteCount) bytes"
    }

    init(change: SpeciesEditFileChange) {
        id = change.id
        path = change.path
        summary = change.summary
        detail = "\(change.originalByteCount) -> \(change.newByteCount) bytes"
    }
}

private extension MutationPlanAppliedChangeRow {
    init(change: AppliedMapFileChange) {
        id = change.id
        path = change.path
        backupPath = change.backupPath
        byteCount = change.byteCount
    }

    init(change: AppliedTrainerFileChange) {
        id = change.id
        path = change.path
        backupPath = change.backupPath
        byteCount = change.byteCount
    }

    init(change: AppliedSpeciesFileChange) {
        id = change.id
        path = change.path
        backupPath = change.backupPath
        byteCount = change.byteCount
    }
}

private extension MutationPlanDiagnosticRow {
    init(diagnostic: Diagnostic) {
        id = diagnostic.id
        code = diagnostic.code
        message = diagnostic.message
        status = ValidationState(severity: diagnostic.severity)
    }
}

private extension ValidationState {
    init(severity: DiagnosticSeverity) {
        switch severity {
        case .info:
            self = .valid
        case .warning:
            self = .warning
        case .error:
            self = .error
        }
    }
}
