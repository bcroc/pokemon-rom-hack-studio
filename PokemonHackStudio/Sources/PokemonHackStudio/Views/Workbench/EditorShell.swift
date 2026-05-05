import SwiftUI

struct EditorShell<Content: View>: View {
    let module: WorkbenchModule
    let projectTitle: String?
    let status: ValidationState?
    let inspectorContext: SourceInspectorContext?
    let mutationPlanContext: MutationPlanPanelContext?
    let onPreviewMutationPlan: () -> Void
    let onApplyMutationPlan: () -> Void
    let onDiscardMutationPlan: () -> Void
    private let content: Content

    @State private var showsSourceInspector = true

    init(
        module: WorkbenchModule,
        projectTitle: String?,
        status: ValidationState? = nil,
        inspectorContext: SourceInspectorContext? = nil,
        mutationPlanContext: MutationPlanPanelContext? = nil,
        onPreviewMutationPlan: @escaping () -> Void = {},
        onApplyMutationPlan: @escaping () -> Void = {},
        onDiscardMutationPlan: @escaping () -> Void = {},
        @ViewBuilder content: () -> Content
    ) {
        self.module = module
        self.projectTitle = projectTitle
        self.status = status
        self.inspectorContext = inspectorContext
        self.mutationPlanContext = mutationPlanContext
        self.onPreviewMutationPlan = onPreviewMutationPlan
        self.onApplyMutationPlan = onApplyMutationPlan
        self.onDiscardMutationPlan = onDiscardMutationPlan
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.bar)

            Divider()

            detailArea

            if let mutationPlanContext {
                Divider()
                MutationPlanPanel(
                    context: mutationPlanContext,
                    onPreview: onPreviewMutationPlan,
                    onApply: onApplyMutationPlan,
                    onDiscard: onDiscardMutationPlan
                )
            }
        }
        .navigationTitle(module.title)
        .focusedSceneValue(\.editorShellShowsSourceInspector, $showsSourceInspector)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Label(module.title, systemImage: module.systemImage)
                .font(.headline)

            Text(module.group.rawValue)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(module.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 12)

            if let projectTitle {
                Text(projectTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let status {
                StatusPill(state: status)
            }

            if inspectorContext != nil {
                Button("Source Inspector", systemImage: "sidebar.right") {
                    showsSourceInspector.toggle()
                }
                .labelStyle(.iconOnly)
                .help(showsSourceInspector ? "Hide source inspector" : "Show source inspector")
            }
        }
    }

    @ViewBuilder
    private var detailArea: some View {
        if showsSourceInspector, let inspectorContext {
            HSplitView {
                content
                    .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)

                SourceInspector(context: inspectorContext)
                    .frame(minWidth: 240, idealWidth: 280, maxWidth: 360, maxHeight: .infinity)
            }
        } else {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct EditorShellShowsSourceInspectorKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var editorShellShowsSourceInspector: Binding<Bool>? {
        get { self[EditorShellShowsSourceInspectorKey.self] }
        set { self[EditorShellShowsSourceInspectorKey.self] = newValue }
    }
}
