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
    @State private var showsCompactSourceInspector = false

    init(
        module: WorkbenchModule,
        projectTitle: String?,
        status: ValidationState? = nil,
        inspectorContext: SourceInspectorContext? = nil,
        mutationPlanContext: MutationPlanPanelContext? = nil,
        showsSourceInspectorByDefault: Bool = true,
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
        _showsSourceInspector = State(initialValue: showsSourceInspectorByDefault)
    }

    var body: some View {
        GeometryReader { proxy in
            let layoutMode = WorkbenchLayoutMode(contentWidth: proxy.size.width)

            VStack(spacing: 0) {
                header(layoutMode: layoutMode)
                    .padding(.horizontal, layoutMode.isCompact ? 12 : 16)
                    .padding(.vertical, layoutMode.isCompact ? 8 : 10)
                    .background(.bar)

                Divider()

                detailArea(layoutMode: layoutMode)

                if let mutationPlanContext {
                    Divider()
                    MutationPlanPanel(
                        context: mutationPlanContext,
                        layoutMode: layoutMode,
                        onPreview: onPreviewMutationPlan,
                        onApply: onApplyMutationPlan,
                        onDiscard: onDiscardMutationPlan
                    )
                }
            }
        }
        .navigationTitle(module.title)
        .focusedSceneValue(\.editorShellShowsSourceInspector, $showsSourceInspector)
    }

    private func header(layoutMode: WorkbenchLayoutMode) -> some View {
        Group {
            if layoutMode.isCompact {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        moduleTitle
                        Spacer(minLength: 8)
                        if let status {
                            StatusPill(state: status)
                        }
                        sourceInspectorButton(layoutMode: layoutMode)
                    }

                    HStack(spacing: 8) {
                        Text(module.group.rawValue)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)

                        Text(module.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        if let projectTitle {
                            Text(projectTitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    moduleTitle

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
                            .truncationMode(.middle)
                    }

                    if let status {
                        StatusPill(state: status)
                    }

                    sourceInspectorButton(layoutMode: layoutMode)
                }
            }
        }
    }

    private var moduleTitle: some View {
        Label(module.title, systemImage: module.systemImage)
            .font(.headline)
            .lineLimit(1)
    }

    @ViewBuilder
    private func sourceInspectorButton(layoutMode: WorkbenchLayoutMode) -> some View {
        if let inspectorContext {
            Button("Source Inspector", systemImage: "sidebar.right") {
                if layoutMode.isCompact {
                    showsCompactSourceInspector.toggle()
                } else {
                    showsSourceInspector.toggle()
                }
            }
            .labelStyle(.iconOnly)
            .help(layoutMode.isCompact ? "Open source inspector" : (showsSourceInspector ? "Hide source inspector" : "Show source inspector"))
            .popover(isPresented: $showsCompactSourceInspector, arrowEdge: .bottom) {
                SourceInspector(context: inspectorContext)
                    .frame(
                        width: WorkbenchLayoutMode.compactPopoverWidth,
                        height: WorkbenchLayoutMode.compactPopoverHeight
                    )
            }
        }
    }

    @ViewBuilder
    private func detailArea(layoutMode: WorkbenchLayoutMode) -> some View {
        if showsSourceInspector, layoutMode.isWide, let inspectorContext {
            HSplitView {
                content
                    .frame(minWidth: 360, maxWidth: .infinity, maxHeight: .infinity)

                SourceInspector(context: inspectorContext)
                    .frame(minWidth: 220, idealWidth: 270, maxWidth: 340, maxHeight: .infinity)
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
