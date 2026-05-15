import SwiftUI

struct EditorRecordSwitcherItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let detail: String?
    let systemImage: String
    let status: ValidationState?
    let searchText: String
}

struct EditorRecordSwitcher: View {
    let title: String
    let selectedTitle: String
    let selectedSubtitle: String?
    let systemImage: String
    let items: [EditorRecordSwitcherItem]
    let selectedID: String
    let emptyTitle: String
    let emptyDescription: String
    let onSelect: (String) -> Void

    @State private var isPresented = false
    @State private var searchText = ""

    var body: some View {
        Button {
            if !isPresented {
                searchText = ""
            }
            isPresented.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text(selectedTitle)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    if let selectedSubtitle, !selectedSubtitle.isEmpty {
                        Text(selectedSubtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(title)
        .accessibilityLabel(title)
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            switcherPopover
                .frame(width: 380, height: 480)
        }
    }

    private var switcherPopover: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                TextField("Search", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(12)

            Divider()

            if filteredItems.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: "magnifyingglass",
                    description: Text(emptyDescription)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(filteredItems) { item in
                            Button {
                                onSelect(item.id)
                                isPresented = false
                            } label: {
                                switcherRow(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                }
            }
        }
    }

    private func switcherRow(_ item: EditorRecordSwitcherItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let detail = item.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 5) {
                if item.id == selectedID {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                }
                if let status = item.status {
                    StatusPill(state: status)
                }
            }
        }
        .padding(10)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(item.id == selectedID ? Color.accentColor.opacity(0.16) : Color.clear)
        )
    }

    private var filteredItems: [EditorRecordSwitcherItem] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return items }
        let needle = trimmed.lowercased()
        return items.filter { item in
            item.searchText.localizedCaseInsensitiveContains(needle)
        }
    }
}
