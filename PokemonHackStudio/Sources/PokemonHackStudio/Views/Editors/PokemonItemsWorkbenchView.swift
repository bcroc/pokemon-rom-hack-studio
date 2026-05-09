import PokemonHackCore
import SwiftUI

struct PokemonItemsWorkbenchView: View {
    let catalog: ItemCatalogViewState?
    let items: [ItemDetailViewState]
    @Binding var selectedItemID: String
    let selectedItem: ItemDetailViewState?
    let draft: ItemEditDraft?
    let isDirty: Bool
    let loadStatus: ItemCatalogLoadStatus
    @Binding var filter: ItemWorkbenchFilter
    let fallbackRecords: [WorkbenchRecord]
    let onLoadCatalog: () -> Void
    let onUpdateDraft: (ItemEditDraft) -> Void

    var body: some View {
        Group {
            if let catalog {
                itemWorkbench(catalog)
            } else if !fallbackRecords.isEmpty {
                EditorListShell(title: "Items", records: fallbackRecords) { record in
                    EditorSection(title: "Facts") {
                        FactGrid(facts: record.facts)
                    }
                    SourcePreviewBlock(text: record.preview)
                    NotesList(notes: record.notes)
                }
            } else {
                noCatalogView
            }
        }
        .navigationTitle("Items")
        .onAppear(perform: onLoadCatalog)
    }

    private func itemWorkbench(_ catalog: ItemCatalogViewState) -> some View {
        VStack(spacing: 0) {
            header(catalog)
                .padding(.horizontal, 24)
                .padding(.vertical, 18)

            Divider()

            HStack(spacing: 0) {
                itemList
                    .frame(minWidth: 240, idealWidth: 300, maxWidth: 360)

                Divider()

                ScrollView {
                    if let selectedItem {
                        itemDetail(selectedItem)
                    } else {
                        ContentUnavailableView(
                            "No Item Selected",
                            systemImage: WorkbenchModule.items.systemImage,
                            description: Text("Select an item to inspect or edit its source-backed data.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 360)
                    }
                }
            }
        }
    }

    private func header(_ catalog: ItemCatalogViewState) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Items")
                        .font(.largeTitle.weight(.semibold))
                    Text("\(catalog.projectTitle) source-backed item catalog and Emerald row editor.")
                        .foregroundStyle(.secondary)
                    Text(catalog.rootPath)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    StatusPill(state: catalog.status)
                    Text(catalog.profile)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                MetricCard(title: "Items", value: "\(catalog.itemCount)", detail: "\(items.count) visible")
                MetricCard(title: "Editable", value: "\(catalog.editableCount)", detail: "Emerald gItems rows")
                MetricCard(title: "Diagnostics", value: "\(catalog.diagnostics.count)", detail: loadStatus.label)
            }
        }
    }

    private var itemList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Filter", selection: $filter) {
                ForEach(ItemWorkbenchFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.menu)

            if items.isEmpty {
                ContentUnavailableView("No Matching Items", systemImage: "magnifyingglass")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(items) { item in
                            itemListRow(item)
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
        }
        .padding(16)
        .background(.background)
    }

    private func itemListRow(_ item: ItemDetailViewState) -> some View {
        Button {
            selectedItemID = item.itemID
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: WorkbenchModule.items.systemImage)
                    .foregroundStyle(.secondary)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    Text(item.itemID)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(item.isEditable ? "Editable" : "Read-only")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 6)
                StatusPill(state: item.status)
            }
            .padding(10)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedItemID == item.itemID ? Color.accentColor.opacity(0.16) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func itemDetail(_ item: ItemDetailViewState) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.displayName)
                        .font(.title.weight(.semibold))
                    Text(item.itemID)
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                Spacer()
                StatusPill(state: item.status)
            }

            EditorSection(title: "Item Facts") {
                FactGrid(facts: item.facts)
            }

            if let draft {
                editSection(draft)
            } else {
                EditorSection(title: "Editing") {
                    Text("This item source shape is read-only.")
                        .foregroundStyle(.secondary)
                }
            }

            EditorSection(title: "Source") {
                VStack(alignment: .leading, spacing: 10) {
                    SourceLocationView(source: item.source)
                    sourcePreviewText(item.sourcePreview)
                }
            }

            EditorSection(title: "Diagnostics") {
                if item.diagnostics.isEmpty {
                    Text("No diagnostics for this item.")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 10) {
                        ForEach(item.diagnostics) { diagnostic in
                            diagnosticRow(diagnostic)
                        }
                    }
                }
            }
        }
        .padding(24)
    }

    private func editSection(_ draft: ItemEditDraft) -> some View {
        EditorSection(title: isDirty ? "Item Data Edited" : "Item Data") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], alignment: .leading, spacing: 12) {
                itemTextField("Name", text: draftOptionalStringBinding(\.name))
                itemTextField("Price", text: draftOptionalStringBinding(\.price))
                itemTextField("Hold Effect", text: draftOptionalStringBinding(\.holdEffect))
                itemTextField("Hold Param", text: draftOptionalStringBinding(\.holdEffectParam))
                itemTextField("Pocket", text: draftOptionalStringBinding(\.pocket))
                itemTextField("Type", text: draftOptionalStringBinding(\.type))
                itemTextField("Battle Use", text: draftOptionalStringBinding(\.battleUsage))
                itemTextField("Secondary", text: draftOptionalStringBinding(\.secondaryId))
                itemTextField("Field Func", text: draftOptionalStringBinding(\.fieldUseFunc))
                itemTextField("Battle Func", text: draftOptionalStringBinding(\.battleUseFunc))
            }
        }
    }

    private func itemTextField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
        }
    }

    private func draftOptionalStringBinding(_ keyPath: WritableKeyPath<ItemEditDraft, String?>) -> Binding<String> {
        Binding(
            get: { draft?[keyPath: keyPath] ?? "" },
            set: { value in
                guard var draft else { return }
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                draft[keyPath: keyPath] = trimmed.isEmpty ? nil : trimmed
                onUpdateDraft(draft)
            }
        )
    }

    private func diagnosticRow(_ diagnostic: IndexedDiagnosticRow) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 5) {
                Text(diagnostic.title)
                    .font(.headline)
                Text(diagnostic.message)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                SourceLocationView(source: diagnostic.source)
            }

            Spacer()
            StatusPill(state: diagnostic.severity)
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func sourcePreviewText(_ text: String?) -> some View {
        if let text, !text.isEmpty {
            ScrollView(.horizontal) {
                Text(text)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            Text("No preview available.")
                .foregroundStyle(.secondary)
        }
    }

    private var noCatalogView: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Items")
                    .font(.largeTitle.weight(.semibold))
                Text("Open a supported project to inspect items and edit Emerald item rows.")
                    .foregroundStyle(.secondary)
            }

            EditorSection(title: "Catalog") {
                ContentUnavailableView(
                    loadStatus.label,
                    systemImage: WorkbenchModule.items.systemImage
                )
            }
        }
        .padding(24)
    }
}
