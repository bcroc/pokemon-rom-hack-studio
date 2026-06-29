struct MutationActionBarState: Equatable {
    let target: WorkbenchToolbarMutationTarget
    let title: String
    let systemImage: String
    let canPreview: Bool
    let canApply: Bool
    let canDiscard: Bool
    let previewHelp: String
    let applyHelp: String
    let discardHelp: String

    var hasEditableTarget: Bool {
        target != .none
    }

    var previewTitle: String {
        "Preview"
    }

    var applyTitle: String {
        "Apply"
    }

    var discardTitle: String {
        "Discard"
    }
}

extension MutationActionBarState {
    init(toolbarState state: WorkbenchToolbarMutationState) {
        self.init(
            target: state.target,
            title: state.title,
            systemImage: state.systemImage,
            canPreview: state.canPreview,
            canApply: state.canApply,
            canDiscard: state.canDiscard,
            previewHelp: state.previewHelp,
            applyHelp: state.applyHelp,
            discardHelp: state.discardHelp
        )
    }

    init(context: MutationPlanPanelContext) {
        self.init(
            target: context.target,
            title: context.title,
            systemImage: context.target.systemImage,
            canPreview: context.canPreview,
            canApply: context.canApply,
            canDiscard: context.canDiscard,
            previewHelp: context.previewBlockedReason ?? "Preview staged source mutations",
            applyHelp: context.applyBlockedReason ?? "Apply previewed source mutations",
            discardHelp: "Discard staged source mutations"
        )
    }
}
