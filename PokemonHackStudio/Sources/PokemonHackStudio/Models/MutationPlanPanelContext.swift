import PokemonHackCore

struct MutationPlanPanelContext {
    let target: WorkbenchToolbarMutationTarget
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
    let evidenceDetail: String?
    let evidenceIsTruncated: Bool
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
            target: .map,
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
            target: .trainer,
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
            target: .pokemon,
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

    @MainActor
    static func speciesBatch(
        plans: [SpeciesEditPlan],
        result: SpeciesApplyResult?,
        dirtyDraftCount: Int,
        canPreview: Bool,
        canApply: Bool,
        canDiscard: Bool,
        previewBlockedReason: String?,
        applyBlockedReason: String?
    ) -> MutationPlanPanelContext? {
        guard dirtyDraftCount > 0 || !plans.isEmpty || result != nil else {
            return nil
        }

        let planDiagnostics = plans.flatMap(\.diagnostics)
        let applyDiagnostics = result?.diagnostics ?? []
        let diagnostics = (planDiagnostics + applyDiagnostics).map { MutationPlanDiagnosticRow(diagnostic: $0) }
        let status = Self.status(
            diagnostics: diagnostics,
            isApplyReady: canApply,
            hasAppliedChanges: !(result?.appliedChanges.isEmpty ?? true)
        )
        let changes = plans.flatMap { plan in
            plan.changes.map { change in
                MutationPlanChangeRow(
                    id: "\(plan.speciesID)::\(change.id)",
                    path: change.path,
                    summary: "\(plan.speciesID): \(change.summary)",
                    detail: "\(change.originalByteCount) -> \(change.newByteCount) bytes",
                    evidenceDetail: nil,
                    evidenceIsTruncated: false
                )
            }
        }

        return MutationPlanPanelContext(
            target: .pokemonBatch,
            title: "Pokemon Compatibility Batch",
            summary: Self.speciesBatchSummary(plans: plans, result: result, dirtyDraftCount: dirtyDraftCount),
            status: status,
            operationCount: dirtyDraftCount,
            changes: changes,
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
    static func move(
        plan: MoveEditPlan?,
        result: MoveApplyResult?,
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
            target: .move,
            title: plan?.mutationPlan.title ?? "Move Mutation Plan",
            summary: Self.editSummary(kind: "Move", planSummary: plan?.mutationPlan.summary, appliedCount: result?.appliedChanges.count, hasApplyDiagnostics: !(result?.diagnostics.isEmpty ?? true), isDirty: isDirty),
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
    static func item(
        plan: ItemEditPlan?,
        result: ItemApplyResult?,
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
            target: .item,
            title: plan?.mutationPlan.title ?? "Item Mutation Plan",
            summary: Self.editSummary(kind: "Item", planSummary: plan?.mutationPlan.summary, appliedCount: result?.appliedChanges.count, hasApplyDiagnostics: !(result?.diagnostics.isEmpty ?? true), isDirty: isDirty),
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
    static func graphics(
        plan: GraphicsEditPlan?,
        result: GraphicsApplyResult?,
        draft: GraphicsEditDraft?,
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
            target: .graphics,
            title: plan?.mutationPlan.title ?? "Graphics Mutation Plan",
            summary: Self.graphicsSummary(plan: plan, result: result, isDirty: isDirty),
            status: status,
            operationCount: draft?.operations.count ?? 0,
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
    static func ndsData(
        plan: NDSDataEditPlan?,
        result: NDSDataApplyResult?,
        editor: NDSDataResourceEditorViewState?
    ) -> MutationPlanPanelContext? {
        guard let editor, editor.isDirty || plan != nil || result != nil else {
            return nil
        }

        let planDiagnostics = plan?.diagnostics ?? []
        let applyDiagnostics = result?.diagnostics ?? []
        let diagnostics = (planDiagnostics + applyDiagnostics).map { MutationPlanDiagnosticRow(diagnostic: $0) }
        let status = Self.status(
            diagnostics: diagnostics,
            isApplyReady: editor.canApply,
            hasAppliedChanges: !(result?.appliedChanges.isEmpty ?? true)
        )

        return MutationPlanPanelContext(
            target: .ndsData,
            title: plan?.mutationPlan.title ?? "NDS Data Mutation Plan",
            summary: Self.editSummary(
                kind: "NDS data",
                planSummary: plan?.mutationPlan.summary,
                appliedCount: result?.appliedChanges.count,
                hasApplyDiagnostics: !(result?.diagnostics.isEmpty ?? true),
                isDirty: editor.isDirty
            ),
            status: status,
            operationCount: editor.isDirty ? 1 : 0,
            changes: (plan?.changes ?? []).map { MutationPlanChangeRow(change: $0) },
            appliedChanges: (result?.appliedChanges ?? []).map { MutationPlanAppliedChangeRow(change: $0) },
            diagnostics: diagnostics,
            canPreview: editor.canPreview,
            canApply: editor.canApply,
            canDiscard: editor.canDiscard,
            previewBlockedReason: editor.blockedReason,
            applyBlockedReason: editor.applyBlockedReason
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

    private static func speciesBatchSummary(
        plans: [SpeciesEditPlan],
        result: SpeciesApplyResult?,
        dirtyDraftCount: Int
    ) -> String {
        if let result, !result.appliedChanges.isEmpty {
            return "Applied \(result.appliedChanges.count) Pokemon compatibility source file change(s); backups are recorded for review."
        }

        if let result, !result.diagnostics.isEmpty {
            return "Pokemon compatibility apply is blocked until the reported diagnostics are resolved."
        }

        if !plans.isEmpty {
            let changeCount = plans.reduce(0) { $0 + $1.changes.count }
            return "\(plans.count) Pokemon draft(s) preview \(changeCount) source file change(s)."
        }

        if dirtyDraftCount > 0 {
            return "\(dirtyDraftCount) Pokemon compatibility draft(s) are staged locally and waiting for source mutation preview."
        }

        return "No Pokemon compatibility edits are staged."
    }

    private static func editSummary(
        kind: String,
        planSummary: String?,
        appliedCount: Int?,
        hasApplyDiagnostics: Bool,
        isDirty: Bool
    ) -> String {
        if let appliedCount, appliedCount > 0 {
            return "Applied \(appliedCount) \(kind.lowercased()) source file change(s); backups are recorded for review."
        }

        if hasApplyDiagnostics {
            return "\(kind) apply is blocked until the reported diagnostics are resolved."
        }

        if let planSummary {
            return planSummary
        }

        if isDirty {
            return "\(kind) edits are staged locally and waiting for source mutation preview."
        }

        return "No \(kind.lowercased()) edits are staged."
    }

    private static func graphicsSummary(
        plan: GraphicsEditPlan?,
        result: GraphicsApplyResult?,
        isDirty: Bool
    ) -> String {
        if let result, !result.appliedChanges.isEmpty {
            return "Applied \(result.appliedChanges.count) graphics source file change(s); backups are recorded for review."
        }

        if let result, !result.diagnostics.isEmpty {
            return "Graphics apply is blocked until the reported diagnostics are resolved."
        }

        if let plan {
            return plan.mutationPlan.summary
        }

        if isDirty {
            return "Graphics edits are staged locally and waiting for source mutation preview."
        }

        return "No graphics edits are staged."
    }
}

private extension MutationPlanChangeRow {
    init(change: MapEditFileChange) {
        id = change.id
        path = change.path
        summary = change.summary
        detail = "\(change.originalByteCount) -> \(change.newByteCount) bytes"
        evidenceDetail = nil
        evidenceIsTruncated = false
    }

    init(change: TrainerEditFileChange) {
        id = change.id
        path = change.path
        summary = change.summary
        detail = "\(change.originalByteCount) -> \(change.newByteCount) bytes"
        evidenceDetail = nil
        evidenceIsTruncated = false
    }

    init(change: SpeciesEditFileChange) {
        id = change.id
        path = change.path
        summary = change.summary
        detail = "\(change.originalByteCount) -> \(change.newByteCount) bytes"
        evidenceDetail = nil
        evidenceIsTruncated = false
    }

    init(change: MoveEditFileChange) {
        id = change.id
        path = change.path
        summary = change.summary
        detail = "\(change.originalByteCount) -> \(change.newByteCount) bytes"
        evidenceDetail = nil
        evidenceIsTruncated = false
    }

    init(change: ItemEditFileChange) {
        id = change.id
        path = change.path
        summary = change.summary
        detail = "\(change.originalByteCount) -> \(change.newByteCount) bytes"
        evidenceDetail = nil
        evidenceIsTruncated = false
    }

    init(change: GraphicsEditFileChange) {
        id = change.id
        path = change.path
        summary = change.summary
        detail = "\(change.originalByteCount) -> \(change.newByteCount) bytes"
        evidenceDetail = nil
        evidenceIsTruncated = false
    }

    init(change: NDSDataEditFileChange) {
        id = change.id
        path = change.path
        summary = change.summary
        let previewLimit = 400
        let previewCount = change.textPreview.count
        evidenceIsTruncated = change.newData.count > previewLimit || previewCount >= previewLimit
        let truncation = evidenceIsTruncated ? "; preview evidence is truncated" : ""
        let shaSummary = change.originalSHA1.map { "; source sha1 \($0.prefix(8))" } ?? ""
        detail = "\(change.originalByteCount) -> \(change.newByteCount) bytes\(shaSummary)"
        evidenceDetail = "Replacement content is redacted; \(previewCount) preview character(s) tracked for review\(truncation)."
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

    init(change: AppliedMoveFileChange) {
        id = change.id
        path = change.path
        backupPath = change.backupPath
        byteCount = change.byteCount
    }

    init(change: AppliedItemFileChange) {
        id = change.id
        path = change.path
        backupPath = change.backupPath
        byteCount = change.byteCount
    }

    init(change: AppliedGraphicsFileChange) {
        id = change.id
        path = change.path
        backupPath = change.backupPath
        byteCount = change.byteCount
    }

    init(change: AppliedNDSDataFileChange) {
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
