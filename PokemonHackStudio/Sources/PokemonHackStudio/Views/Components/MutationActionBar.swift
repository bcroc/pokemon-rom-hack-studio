import SwiftUI

enum MutationActionBarStyle {
    case toolbar
    case sidebar
    case panel
}

struct MutationActionBar: View {
    let state: MutationActionBarState
    let style: MutationActionBarStyle
    let onPreview: () -> Void
    let onApply: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        switch style {
        case .toolbar:
            toolbarBar
        case .sidebar:
            sidebarBar
        case .panel:
            panelBar
        }
    }

    private var toolbarBar: some View {
        HStack(spacing: 4) {
            mutationMenu

            commandButton(
                state.previewTitle,
                systemImage: "doc.text.magnifyingglass",
                isEnabled: state.canPreview,
                help: state.previewHelp,
                action: onPreview
            )

            commandButton(
                state.applyTitle,
                systemImage: "checkmark.seal",
                isEnabled: state.canApply,
                help: state.applyHelp,
                action: onApply
            )

            commandButton(
                state.discardTitle,
                systemImage: "trash",
                isEnabled: state.canDiscard,
                help: state.discardHelp,
                action: onDiscard
            )
        }
    }

    private var sidebarBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(state.hasEditableTarget ? state.title : state.previewHelp)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                commandButton(
                    state.previewTitle,
                    systemImage: "doc.text.magnifyingglass",
                    isEnabled: state.canPreview,
                    help: state.previewHelp,
                    action: onPreview
                )

                commandButton(
                    state.applyTitle,
                    systemImage: "checkmark.seal",
                    isEnabled: state.canApply,
                    help: state.applyHelp,
                    action: onApply
                )

                commandButton(
                    state.discardTitle,
                    systemImage: "trash",
                    isEnabled: state.canDiscard,
                    help: state.discardHelp,
                    action: onDiscard
                )
            }
        }
    }

    private var panelBar: some View {
        HStack(spacing: 8) {
            commandButton(
                state.previewTitle,
                systemImage: "doc.text.magnifyingglass",
                isEnabled: state.canPreview,
                help: state.previewHelp,
                action: onPreview
            )

            commandButton(
                state.applyTitle,
                systemImage: "checkmark.seal",
                isEnabled: state.canApply,
                help: state.applyHelp,
                action: onApply
            )

            commandButton(
                state.discardTitle,
                systemImage: "trash",
                isEnabled: state.canDiscard,
                help: state.discardHelp,
                action: onDiscard
            )
        }
    }

    private var mutationMenu: some View {
        Menu {
            Button("Preview \(state.title)", systemImage: "doc.text.magnifyingglass") {
                onPreview()
            }
            .disabled(!state.canPreview)
            .help(state.previewHelp)

            Button("Apply \(state.title)", systemImage: "checkmark.seal") {
                onApply()
            }
            .disabled(!state.canApply)
            .help(state.applyHelp)

            Button("Discard \(state.title)", systemImage: "trash") {
                onDiscard()
            }
            .disabled(!state.canDiscard)
            .help(state.discardHelp)
        } label: {
            Label("Mutations", systemImage: state.systemImage)
        }
        .labelStyle(.iconOnly)
        .help(state.hasEditableTarget ? state.title : state.previewHelp)
        .disabled(!state.hasEditableTarget)
    }

    @ViewBuilder
    private func commandButton(
        _ title: String,
        systemImage: String,
        isEnabled: Bool,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        if style == .toolbar {
            Button(title, systemImage: systemImage, action: action)
                .labelStyle(.iconOnly)
                .help(help)
                .accessibilityLabel(title)
                .accessibilityHint(help)
                .disabled(!isEnabled)
        } else {
            Button(title, systemImage: systemImage, action: action)
                .help(help)
                .accessibilityLabel(title)
                .accessibilityHint(help)
                .disabled(!isEnabled)
        }
    }
}
