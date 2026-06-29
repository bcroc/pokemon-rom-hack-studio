import AppKit
import SwiftUI

struct SourceLocationView: View {
    let source: SourceLocation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Label(source.label, systemImage: "doc.text.magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                    .help(source.label)

                Spacer(minLength: 4)

                ForEach(SourceLocationAction.allCases) { action in
                    Button {
                        perform(action)
                    } label: {
                        Image(systemName: action.systemImage)
                            .frame(width: 14, height: 14)
                    }
                    .buttonStyle(.borderless)
                    .disabled(!isEnabled(action))
                    .help(helpText(for: action))
                }
            }

            Text(source.symbol)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
                .help(source.symbol)
        }
    }

    private var isAbsolutePath: Bool {
        source.path.hasPrefix("/")
    }

    private var fileURL: URL {
        URL(fileURLWithPath: source.path)
    }

    private func isEnabled(_ action: SourceLocationAction) -> Bool {
        switch action {
        case .copyPath:
            !source.path.isEmpty
        case .revealInFinder, .openExternally:
            isAbsolutePath
        }
    }

    private func helpText(for action: SourceLocationAction) -> String {
        switch action {
        case .copyPath:
            "Copy \(source.label)"
        case .revealInFinder:
            isAbsolutePath ? "Reveal source in Finder" : "Reveal needs an absolute source path"
        case .openExternally:
            isAbsolutePath ? "Open source in the default editor" : "Open externally needs an absolute source path"
        }
    }

    private func perform(_ action: SourceLocationAction) {
        switch action {
        case .copyPath:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(source.label, forType: .string)
        case .revealInFinder:
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        case .openExternally:
            NSWorkspace.shared.open(fileURL)
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
