import SwiftUI
import PokemonHackCore

struct ScriptEditorView: View {
    @ObservedObject var store: WorkbenchStore
    let records: [WorkbenchRecord]
    let outline: ProjectScriptOutline?
    let sources: [ScriptOutlineSource]
    let labels: [ScriptOutlineLabel]
    let textBlocks: [ScriptTextBlock]

    var body: some View {
        if let outline {
            scriptOutline(outline)
        } else {
            EditorListShell(title: "Scripts", records: records) { record in
                EditorSection(title: "Outline") {
                    FactGrid(facts: record.facts)
                }

                SourcePreviewBlock(text: record.preview)
                NotesList(notes: record.notes)
            }
        }
    }

    private func scriptOutline(_ outline: ProjectScriptOutline) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                header(outline)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
                    MetricCard(title: "Sources", value: "\(outline.sources.count)", detail: "\(sources.count) visible")
                    MetricCard(title: "Labels", value: "\(outline.labels.count)", detail: "\(labels.count) visible")
                    MetricCard(title: "Commands", value: "\(outline.labels.reduce(0) { $0 + $1.commands.count })", detail: "Read-only bodies")
                    MetricCard(title: "Text Blocks", value: "\(outline.textBlocks.count)", detail: "\(textBlocks.count) visible")
                }

                readinessSection

                EditorSection(title: "Script Sources") {
                    LazyVStack(spacing: 10) {
                        if sources.isEmpty {
                            emptyRows("No Sources", image: "magnifyingglass")
                        } else {
                            ForEach(sources) { source in
                                ScriptOutlineSourceRow(source: source)
                            }
                        }
                    }
                }

                EditorSection(title: "Label Outline") {
                    LazyVStack(spacing: 10) {
                        if labels.isEmpty {
                            emptyRows("No Labels", image: "magnifyingglass")
                        } else {
                            ForEach(labels) { label in
                                ScriptOutlineLabelRow(label: label)
                            }
                        }
                    }
                }

                EditorSection(title: "Text Blocks") {
                    LazyVStack(spacing: 10) {
                        if textBlocks.isEmpty {
                            emptyRows("No Text Blocks", image: "text.quote")
                        } else {
                            ForEach(textBlocks) { block in
                                ScriptTextBlockRow(block: block)
                            }
                        }
                    }
                }

                if !outline.diagnostics.isEmpty {
                    EditorSection(title: "Diagnostics") {
                        LazyVStack(spacing: 10) {
                            ForEach(outline.diagnostics.prefix(12)) { diagnostic in
                                ScriptOutlineDiagnosticRow(diagnostic: diagnostic)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Scripts")
        .onAppear {
            store.loadSelectedMapCatalogIfNeeded()
            store.refreshSelectedScriptReadinessReport()
        }
    }

    private func header(_ outline: ProjectScriptOutline) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Scripts")
                    .font(.largeTitle.weight(.semibold))
                Text("\(outline.adapterName) · \(outline.profile.rawValue)")
                    .foregroundStyle(.secondary)
                Text(outline.root.path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }

            Spacer()

            StatusPill(state: outline.diagnostics.contains { $0.severity == .error } ? .error : outline.diagnostics.isEmpty ? .valid : .warning)
        }
    }

    private var readinessSection: some View {
        EditorSection(title: "Live Script Readiness") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    Picker("Target", selection: Binding {
                        store.scriptReadinessTargetMode
                    } set: { mode in
                        store.requestScriptReadinessMode(mode)
                    }) {
                        ForEach(ScriptReadinessTargetMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 220)

                    readinessTargetControl

                    Spacer()

                    Button("Refresh", systemImage: "arrow.clockwise") {
                        store.refreshSelectedScriptReadinessReport()
                    }
                }

                if let report = store.selectedScriptReadinessReport {
                    readinessSummary(report)
                    readinessRows(report)
                } else {
                    ContentUnavailableView(
                        "No Readiness Report",
                        systemImage: "curlybraces",
                        description: Text("Select an indexed map or script label.")
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var readinessTargetControl: some View {
        switch store.scriptReadinessTargetMode {
        case .map:
            if let catalog = store.selectedMapCatalog, !catalog.maps.isEmpty {
                Picker("Map", selection: Binding {
                    store.selectedMapID
                } set: { mapID in
                    store.requestScriptReadinessMapSelection(mapID)
                }) {
                    ForEach(catalog.maps) { map in
                        Text(map.name).tag(map.id)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 220)
            } else {
                Text("No maps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .script:
            TextField(
                "Script label",
                text: Binding {
                    store.selectedScriptReadinessLabel
                } set: { label in
                    store.requestScriptReadinessLabel(label)
                }
            )
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: 280)
        }
    }

    private func readinessSummary(_ report: ScriptReadinessReportViewState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(report.targetTitle)
                        .font(.headline)
                    Text("\(report.targetMode.rawValue) · \(report.profile)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                StatusPill(state: report.status)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 8) {
                compactFact("Source", "\(store.filteredScriptReadinessRows.filter { $0.section == .source }.count)")
                compactFact("Build", "\(store.filteredScriptReadinessRows.filter { $0.section == .build }.count)")
                compactFact("Playtest", "\(store.filteredScriptReadinessRows.filter { $0.section == .playtest }.count)")
                compactFact("Ready", report.isReady ? "Yes" : "No")
            }

            if let map = report.mapContext {
                FactGrid(facts: [
                    Fact(label: "Map", value: map.mapName),
                    Fact(label: "Scripts", value: "\(map.eventScriptCount) event labels"),
                    Fact(label: "Sources", value: "\(map.scriptSourceCount) files"),
                    Fact(label: "Layout", value: map.layoutID ?? "None")
                ])
            } else if let script = report.scriptContext {
                FactGrid(facts: [
                    Fact(label: "Label", value: script.label),
                    Fact(label: "Kind", value: script.kind),
                    Fact(label: "Commands", value: "\(script.commandCount)"),
                    Fact(label: "Text Refs", value: "\(script.textReferenceCount)")
                ])
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private func readinessRows(_ report: ScriptReadinessReportViewState) -> some View {
        LazyVStack(spacing: 10) {
            if store.filteredScriptReadinessRows.isEmpty {
                emptyRows("No Readiness Rows", image: "magnifyingglass")
            } else {
                ForEach(ScriptReadinessReportSection.allCases) { section in
                    let rows = store.filteredScriptReadinessRows.filter { $0.section == section }
                    if !rows.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(section.rawValue, systemImage: section.systemImage)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            ForEach(rows) { row in
                                ScriptReadinessRowView(row: row)
                            }
                        }
                    }
                }
            }
        }
    }

    private func emptyRows(_ title: String, image: String) -> some View {
        ContentUnavailableView(
            title,
            systemImage: image,
            description: Text("No script outline rows match the current search.")
        )
    }
}

private struct ScriptReadinessRowView: View {
    let row: ScriptReadinessReportRow

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: row.section.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 6) {
                Text(row.title)
                    .font(.headline)
                Text(row.detail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                SourceLocationView(source: row.source)
            }

            Spacer()

            StatusPill(state: row.status)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct ScriptOutlineSourceRow: View {
    let source: ScriptOutlineSource

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: source.module == .text ? "text.quote" : "curlybraces")
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 8) {
                Text(source.path)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)

                SourceLocationView(source: SourceLocation(path: source.path, symbol: source.module.rawValue, line: 1))

                HStack(spacing: 8) {
                    outlineTag(source.role.title)
                    outlineTag("\(source.labelCount) labels")
                    outlineTag("\(source.commandCount) commands")
                    outlineTag("\(source.textBlockCount) text")
                }
            }

            Spacer()

            StatusPill(state: source.diagnosticCount > 0 ? .warning : .valid)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct ScriptOutlineLabelRow: View {
    let label: ScriptOutlineLabel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(label.label)
                        .font(.headline)
                        .textSelection(.enabled)
                    Text("\(label.kind.title) · \(label.sourceRole.title)")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                StatusPill(state: validationState)
            }

            SourceLocationView(
                source: SourceLocation(
                    path: label.sourcePath,
                    symbol: label.label,
                    line: label.sourceSpan.startLine
                )
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 8) {
                compactFact("Commands", "\(label.commands.count)")
                compactFact("Text Refs", "\(label.textReferences.count)")
                compactFact("Lines", "\(label.sourceSpan.startLine)-\(label.sourceSpan.endLine)")
                compactFact("Body", "\(max(0, label.bodySpan.endLine - label.bodySpan.startLine + 1)) lines")
            }

            if !label.commands.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Commands")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(label.commands.prefix(8)) { command in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(command.name)
                                .font(.system(.caption, design: .monospaced).weight(.semibold))
                            Text(command.arguments.isEmpty ? "line \(command.sourceSpan.startLine)" : command.arguments)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer(minLength: 8)
                        }
                    }
                }
            }

            if !label.textReferences.isEmpty {
                HStack {
                    ForEach(label.textReferences.prefix(6), id: \.self) { reference in
                        outlineTag(reference)
                    }
                }
            }

            if !label.bodyPreview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ScrollView(.horizontal) {
                    Text(label.bodyPreview)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var validationState: ValidationState {
        if label.diagnostics.contains(where: { $0.severity == .error }) {
            return .error
        }
        return label.diagnostics.isEmpty ? .valid : .warning
    }
}

private struct ScriptTextBlockRow: View {
    let block: ScriptTextBlock

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "text.quote")
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 8) {
                Text(block.label)
                    .font(.headline)
                    .textSelection(.enabled)
                SourceLocationView(source: SourceLocation(path: block.sourcePath, symbol: block.label, line: block.sourceSpan.startLine))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 8) {
                    compactFact("String Lines", "\(block.stringLineCount)")
                    compactFact("Characters", "\(block.characterCount)")
                    compactFact("Lines", "\(block.sourceSpan.startLine)-\(block.sourceSpan.endLine)")
                }

                ScrollView(.horizontal) {
                    Text(block.preview)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }

            Spacer()

            StatusPill(state: block.diagnostics.isEmpty ? .valid : .warning)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct ScriptOutlineDiagnosticRow: View {
    let diagnostic: Diagnostic

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(diagnostic.code)
                        .font(.headline)
                    Text(diagnostic.message)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusPill(state: validationState)
            }

            if let span = diagnostic.span {
                SourceLocationView(source: SourceLocation(path: span.relativePath, symbol: diagnostic.code, line: span.startLine))
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var validationState: ValidationState {
        switch diagnostic.severity {
        case .error:
            .error
        case .warning:
            .warning
        case .info:
            .valid
        }
    }
}

private func outlineTag(_ text: String) -> some View {
    Text(text)
        .font(.caption)
        .lineLimit(1)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.quaternary, in: Capsule())
}

private func compactFact(_ label: String, _ value: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
        Text(label)
            .font(.caption)
            .foregroundStyle(.secondary)
        Text(value)
            .font(.caption.weight(.medium))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
