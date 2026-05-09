import PokemonHackCore
import SwiftUI

struct MapEventsPaneView: View {
    let document: MapVisualDocument
    @ObservedObject var session: MapEditorSession
    @Binding var eventSearchText: String
    @Binding var scriptDraftKey: String
    @Binding var scriptDraftText: String
    let viewportCenter: (x: Int, y: Int)?
    let onCenterEvent: (MapEventDescriptor) -> Void

    @State private var selectedKindFilter: MapEventKind?
    @State private var includeSharedScriptSuggestions = true
    @State private var isAdvancedScriptEditing = false

    var body: some View {
        EditorSection(title: "Events") {
            VStack(alignment: .leading, spacing: 12) {
                eventToolbar
                eventPalette
                kindTabs
                eventBrowser
                selectedEventEditor
            }
        }
    }

    private var eventToolbar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("Search events", text: $eventSearchText)
                    .textFieldStyle(.roundedBorder)

                Menu {
                    ForEach(MapEventTemplateKind.allCases) { template in
                        Button {
                            session.selectEventTemplate(template)
                            let coordinate = insertionCoordinate
                            session.addMapEvent(template: template, atX: coordinate.x, y: coordinate.y)
                        } label: {
                            Label(template.title, systemImage: template.systemImage)
                        }
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .menuStyle(.borderlessButton)
                .help("Add event at the selected map coordinate")
            }

            Picker("New event", selection: $session.selectedEventTemplate) {
                ForEach(MapEventTemplateKind.allCases) { template in
                    Label(template.title, systemImage: template.systemImage)
                        .tag(template)
                }
            }
            .pickerStyle(.menu)
            .help("Choose the event type used by the canvas add-event tool")
        }
    }

    private var eventPalette: some View {
        HStack(spacing: 6) {
            ForEach(MapEventTemplateKind.allCases) { template in
                Menu {
                    Button("At Selected Cell", systemImage: "plus.circle") {
                        add(template: template, at: insertionCoordinate)
                    }
                    .disabled(session.selectedMapCell == nil && session.selectedMapEvent == nil)

                    Button("At Viewport Center", systemImage: "scope") {
                        add(template: template, at: viewportCenter ?? insertionCoordinate)
                    }
                    .disabled(viewportCenter == nil)

                    Button("At Origin", systemImage: "arrow.up.left") {
                        add(template: template, at: (0, 0))
                    }
                } label: {
                    Image(systemName: template.systemImage)
                        .frame(width: 26, height: 24)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .help("Add \(template.title)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Event template palette")
    }

    private var kindTabs: some View {
        HStack(spacing: 6) {
            kindTab(title: "All", count: session.stagedMapEvents.count, kind: nil)
            ForEach(MapEventKind.allCases.filter { $0 != .connection }, id: \.rawValue) { kind in
                kindTab(title: kind.title, count: eventCount(for: kind), kind: kind)
            }
        }
    }

    private func kindTab(title: String, count: Int, kind: MapEventKind?) -> some View {
        Button {
            selectedKindFilter = kind
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .lineLimit(1)
                Text("\(count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .font(.caption.weight(selectedKindFilter == kind ? .semibold : .regular))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(selectedKindFilter == kind ? Color.accentColor.opacity(0.16) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .disabled(count == 0 && kind != nil)
    }

    private var eventBrowser: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("\(filteredEvents.count) shown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Previous", systemImage: "chevron.up") {
                    selectAdjacentEvent(offset: -1)
                }
                .labelStyle(.iconOnly)
                .help("Select previous filtered event")
                .disabled(filteredEvents.isEmpty)
                Button("Next", systemImage: "chevron.down") {
                    selectAdjacentEvent(offset: 1)
                }
                .labelStyle(.iconOnly)
                .help("Select next filtered event")
                .disabled(filteredEvents.isEmpty)
            }

            if filteredEvents.isEmpty {
                Text("No matching events.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                let resolutions = scriptResolutionCache
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(groupedFilteredEvents) { group in
                        VStack(alignment: .leading, spacing: 5) {
                            Text("\(group.kind.title) (\(group.events.count))")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            ForEach(group.events) { event in
                                eventRow(event, resolutions: resolutions)
                            }
                        }
                    }
                }
            }
        }
    }

    private func eventRow(_ event: MapEventDescriptor, resolutions: [String: MapScriptResolution]) -> some View {
        Button {
            session.selectMapEvent(id: event.id)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: event.templateKind?.systemImage ?? event.kind.systemImage)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 2) {
                    Text(eventTitle(event))
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Text(eventSubtitle(event))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                if let state = scriptResolutionSummary(for: event, resolutions: resolutions) {
                    Text(state)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(scriptResolutionColor(for: event, resolutions: resolutions))
                        .lineLimit(1)
                }
                if session.selectedMapEventID == event.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(session.selectedMapEventID == event.id ? Color.accentColor.opacity(0.14) : Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Center on Canvas", systemImage: "scope") {
                onCenterEvent(event)
            }
            Button("Duplicate", systemImage: "plus.square.on.square") {
                session.selectMapEvent(id: event.id)
                session.duplicateSelectedMapEvent()
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                session.selectMapEvent(id: event.id)
                session.deleteSelectedMapEvent()
            }
        }
    }

    @ViewBuilder
    private var selectedEventEditor: some View {
        if let event = selectedEvent {
            let resolutions = scriptResolutionCache
            Divider()
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Label(event.templateKind?.title ?? event.kind.title, systemImage: event.templateKind?.systemImage ?? event.kind.systemImage)
                        .font(.headline)
                    Text("#\(event.index)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    if let state = scriptResolutionSummary(for: event, resolutions: resolutions) {
                        Text(state)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(scriptResolutionColor(for: event, resolutions: resolutions))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(scriptResolutionColor(for: event, resolutions: resolutions).opacity(0.12), in: Capsule())
                    }
                    Spacer()
                    Button("Center", systemImage: "scope") {
                        onCenterEvent(event)
                    }
                    .labelStyle(.iconOnly)
                    .help("Center selected event on canvas")
                    Button("Duplicate", systemImage: "plus.square.on.square") {
                        session.duplicateSelectedMapEvent()
                    }
                    .labelStyle(.iconOnly)
                    .help("Duplicate selected event")
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        session.deleteSelectedMapEvent()
                    }
                    .labelStyle(.iconOnly)
                    .help("Delete selected event")
                }

                typedFields(for: event)
                customFields(for: event)
                scriptEditor(for: event)
            }
        } else {
            Text("Select an event to edit its fields.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func typedFields(for event: MapEventDescriptor) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fields")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            numericField("X", key: "x", range: -512...512)
            numericField("Y", key: "y", range: -512...512)
            numericField("Elevation", key: "elevation", range: 0...15)

            switch event.templateKind ?? .object {
            case .object:
                textField("Graphics", key: "graphics_id")
                textField("Movement", key: "movement_type")
                numericField("Move X", key: "movement_range_x", range: 0...255)
                numericField("Move Y", key: "movement_range_y", range: 0...255)
                textField("Trainer Type", key: "trainer_type")
                textField("Trainer Sight", key: "trainer_sight_or_berry_tree_id")
                textField("Flag", key: "flag")
                textField("Script", key: "script")
            case .warp:
                textField("Destination", key: "dest_map")
                numericField("Warp ID", key: "dest_warp_id", range: 0...255)
            case .coordTrigger:
                textField("Type", key: "type")
                textField("Variable", key: "var")
                textField("Value", key: "var_value")
                textField("Script", key: "script")
            case .bgSign:
                textField("Type", key: "type")
                textField("Facing", key: "player_facing_dir")
                textField("Script", key: "script")
            case .bgHiddenItem:
                textField("Type", key: "type")
                textField("Item", key: "item")
                textField("Flag", key: "flag")
            }
        }
    }

    @ViewBuilder
    private func customFields(for event: MapEventDescriptor) -> some View {
        let keys = Set(primaryKeys(for: event))
        let custom = event.properties.filter { !keys.contains($0.key) }
        if !custom.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Custom")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(custom) { property in
                    textField(property.key, key: property.key)
                }
            }
        }
    }

    @ViewBuilder
    private func scriptEditor(for event: MapEventDescriptor) -> some View {
        if canEditScript(for: event) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Inline Script")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if let scriptLabel = event.scriptLabel,
                   let scriptIndex = document.scriptIndex {
                    if let stagedScript = stagedScriptBody(for: scriptLabel) {
                        stagedScriptBodyEditor(stagedScript)
                    } else {
                        let resolution = scriptIndex.resolution(for: scriptLabel)
                        scriptResolutionView(resolution: resolution, event: event)
                    }
                } else {
                    newScriptButton(for: event, title: "Create Script")
                }
            }
        }
    }

    @ViewBuilder
    private func scriptResolutionView(resolution: MapScriptResolution, event: MapEventDescriptor) -> some View {
        switch resolution.state {
        case .resolved:
            if let span = resolution.span {
                scriptBodyEditor(span: span)
            }
        case .missingLabel:
            VStack(alignment: .leading, spacing: 8) {
                diagnosticRows(resolution.diagnostics)
                newScriptButton(for: event, title: "Create Missing Label")
            }
        case .duplicateLabel, .generatedPath, .externalLabel:
            diagnosticRows(resolution.diagnostics)
        case .noScript:
            newScriptButton(for: event, title: "Create Script")
        }
    }

    private func scriptBodyEditor(span: MapScriptLabelSpan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SourceLocationView(
                source: SourceLocation(path: span.sourcePath, symbol: span.label, line: span.labelLine)
            )

            scriptAuthoringHelpers(span: span)
            
            if span.sourceRole == .shared {
                Label("Shared script source. Edits affect multiple maps.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else if !MapScriptIndex.isEditableScriptPath(span.sourcePath) {
                Label("Read-only or generated source path.", systemImage: "lock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if isAdvancedScriptEditing || !MapScriptIndex.isEditableScriptPath(span.sourcePath) {
                TextEditor(text: $scriptDraftText)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 140)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(nsColor: .separatorColor))
                    )
                    .onAppear {
                        syncScriptDraft(span: span)
                    }
                    .onChange(of: span.id) { _, _ in
                        syncScriptDraft(span: span)
                    }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(span.lines.indices, id: \.self) { index in
                        scriptLineRow(span: span, index: index)
                    }
                }
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: .separatorColor))
                )
            }

            HStack {
                if MapScriptIndex.isEditableScriptPath(span.sourcePath) {
                    Button(isAdvancedScriptEditing ? "Structured View" : "Plain Text", systemImage: isAdvancedScriptEditing ? "list.bullet.indent" : "text.alignleft") {
                        isAdvancedScriptEditing.toggle()
                    }
                    .font(.caption)
                }
                
                Spacer()

                if isAdvancedScriptEditing {
                    Button("Stage Changes", systemImage: "square.and.pencil") {
                        session.updateScriptBody(label: span.label, sourcePath: span.sourcePath, body: scriptDraftText)
                    }
                    .disabled(scriptDraftText == (session.stagedScriptBody(label: span.label, sourcePath: span.sourcePath) ?? span.body))
                }
                
                Text("\(span.lines.count) lines")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func scriptAuthoringHelpers(span: MapScriptLabelSpan) -> some View {
        if span.sourceRole == .mapLocal && MapScriptIndex.isEditableScriptPath(span.sourcePath) {
            let currentBody = session.stagedScriptBody(label: span.label, sourcePath: span.sourcePath) ?? span.body
            let awarenessDiagnostics = ScriptAuthoringHelpers.lineMarkerAndPoryswitchDiagnostics(
                body: currentBody,
                sourcePath: span.sourcePath
            )
            let shouldValidateMapscriptScaffold = span.label.localizedCaseInsensitiveContains("MapScripts")
                || currentBody.contains("map_script")
            let scaffoldDiagnostics = shouldValidateMapscriptScaffold
                ? ScriptAuthoringHelpers.validateMapScriptScaffold(
                    label: span.label,
                    body: currentBody,
                    existingLabels: Set(document.scriptIndex?.labels.map(\.label) ?? []),
                    sourcePath: span.sourcePath
                ).diagnostics
                : []
            let textPreview = ScriptAuthoringHelpers.textWrappingPreview(
                label: "\(span.label)_Text",
                text: selectedEvent.map(eventSubtitle) ?? span.label,
                maxLineLength: 36,
                sourcePath: span.sourcePath
            )

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Button("Movement", systemImage: "figure.walk") {
                        stageHelperBody(
                            ScriptAuthoringHelpers.movementListPlan(
                                label: span.label,
                                movements: ["walk_down"],
                                sourcePath: span.sourcePath
                            ),
                            span: span
                        )
                    }
                    .font(.caption)
                    .help("Stage a movement-list body through the map mutation preview")

                    Button("Mart", systemImage: "cart") {
                        stageHelperBody(
                            ScriptAuthoringHelpers.martItemListPlan(
                                label: span.label,
                                items: ["ITEM_POTION"],
                                sourcePath: span.sourcePath
                            ),
                            span: span
                        )
                    }
                    .font(.caption)
                    .help("Stage a mart item list through the map mutation preview")

                    Button("Mapscript", systemImage: "list.bullet.rectangle") {
                        stageHelperBody(
                            ScriptHelperBodyPlan(
                                label: span.label,
                                body: "\tmap_script MAP_SCRIPT_ON_TRANSITION, \(span.label)_OnTransition\n\t.byte 0",
                                diagnostics: ScriptAuthoringHelpers.validateMapScriptScaffold(
                                    label: span.label,
                                    body: "\tmap_script MAP_SCRIPT_ON_TRANSITION, \(span.label)_OnTransition\n\t.byte 0",
                                    existingLabels: Set(document.scriptIndex?.labels.map(\.label) ?? []),
                                    sourcePath: span.sourcePath
                                ).diagnostics
                            ),
                            span: span
                        )
                    }
                    .font(.caption)
                    .help("Stage a mapscript scaffold through the map mutation preview")

                    Spacer()

                    Text("\(textPreview.lines.count) text lines")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .help(textPreview.bodyPreview)
                }

                let diagnostics = Array((awarenessDiagnostics + scaffoldDiagnostics).prefix(3))
                if !diagnostics.isEmpty {
                    diagnosticRows(diagnostics)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
        }
    }

    private func stageHelperBody(_ plan: ScriptHelperBodyPlan, span: MapScriptLabelSpan) {
        guard !plan.diagnostics.contains(where: { $0.severity == .error }) else { return }
        session.stageMapLocalScriptHelperBody(label: span.label, sourcePath: span.sourcePath, body: plan.body)
    }

    private func scriptLineRow(span: MapScriptLabelSpan, index: Int) -> some View {
        let line = span.lines[index]
        return HStack(spacing: 8) {
            Text("\(line.line)")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)
            
            scriptLineContent(line, span: span, index: index)
                .font(.system(.caption, design: .monospaced))
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 1)
    }

    @ViewBuilder
    private func scriptLineContent(_ line: ScriptLine, span: MapScriptLabelSpan, index: Int) -> some View {
        switch line {
        case .command(let cmd, _):
            HStack(spacing: 4) {
                Text(cmd.name)
                    .foregroundStyle(Color.accentColor)
                ForEach(cmd.arguments.indices, id: \.self) { argIndex in
                    editableArgument(cmd.arguments[argIndex], span: span, lineIndex: index, argIndex: argIndex)
                }
                if let comment = cmd.comment {
                    Text("@ \(comment)")
                        .foregroundStyle(.secondary)
                }
            }
        case .label(let name, _):
            Text("\(name)::")
                .foregroundStyle(.purple)
        case .macro(let name, let args, _):
            HStack(spacing: 4) {
                Text(name)
                    .foregroundStyle(.blue)
                ForEach(args.indices, id: \.self) { argIndex in
                    Text(args[argIndex])
                        .foregroundStyle(.secondary)
                }
            }
        case .directive(let name, let value, _):
            HStack(spacing: 4) {
                Text(name)
                    .foregroundStyle(.secondary)
                Text(value)
            }
        case .comment(let text, _):
            Text("@ \(text)")
                .foregroundStyle(.secondary)
                .italic()
        case .empty:
            Color.clear.frame(height: 1)
        }
    }

    private func editableArgument(_ value: String, span: MapScriptLabelSpan, lineIndex: Int, argIndex: Int) -> some View {
        let binding = Binding {
            value
        } set: { newValue in
            updateScriptArgument(span: span, lineIndex: lineIndex, argIndex: argIndex, newValue: newValue)
        }
        
        return TextField("", text: binding)
            .textFieldStyle(.plain)
            .padding(.horizontal, 4)
            .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 3))
            .fixedSize()
    }

    private func updateScriptArgument(span: MapScriptLabelSpan, lineIndex: Int, argIndex: Int, newValue: String) {
        let currentBody = session.stagedScriptBody(label: span.label, sourcePath: span.sourcePath) ?? span.body
        let bodyLines = currentBody.components(separatedBy: .newlines)
        guard bodyLines.indices.contains(lineIndex) else { return }
        
        let line = bodyLines[lineIndex]
        // This is a bit tricky because we need to rebuild the line string accurately.
        // For now, let's use a simpler approach: if it's a command line, we know its structure.
        let parsed = ScriptParser.parseLine(line, lineNumber: lineIndex + span.bodyStartLine)
        if case .command(let cmd, _) = parsed {
            var newArgs = cmd.arguments
            guard newArgs.indices.contains(argIndex) else { return }
            newArgs[argIndex] = newValue
            
            var newLine = "\t\(cmd.name) \(newArgs.joined(separator: ", "))"
            if let comment = cmd.comment {
                newLine += " @ \(comment)"
            }
            session.updateScriptLine(label: span.label, sourcePath: span.sourcePath, lineIndex: lineIndex, content: newLine)
        }
    }

    private func stagedScriptBodyEditor(_ stagedScript: StagedMapScriptBody) -> some View {
        let role = document.scriptIndex?.source(path: stagedScript.sourcePath)?.role ?? .mapLocal
        let span = MapScriptLabelSpan(
            label: stagedScript.label,
            sourcePath: stagedScript.sourcePath,
            sourceRole: role,
            labelLine: 1,
            bodyStartLine: 2,
            bodyEndLine: 2,
            body: stagedScript.body
        )
        return scriptBodyEditor(span: span)
    }

    private func newScriptButton(for event: MapEventDescriptor, title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let sourcePath = session.editableScriptSourcePath {
                Button(title, systemImage: "plus.rectangle.on.folder") {
                    createAndAssignScript(for: event)
                }
                .help("Create a map script label in \(sourcePath)")
            } else {
                Text("No editable scripts.inc source is loaded for this map.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func diagnosticRows(_ diagnostics: [Diagnostic]) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(diagnostics.prefix(3)) { diagnostic in
                Label(diagnostic.message, systemImage: diagnostic.severity == .error ? "xmark.octagon" : "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(diagnostic.severity == .error ? .red : .orange)
            }
        }
    }

    private func textField(_ title: String, key: String) -> AnyView {
        if key == "script" {
            return AnyView(scriptField(title, key: key))
        }
        let options = document.eventOptions.options(for: key)
        if !options.isEmpty {
            return AnyView(optionField(title, key: key, options: options))
        }
        return AnyView(
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 96, alignment: .leading)
                TextField(key, text: propertyBinding(for: key))
                    .font(.caption)
                    .textFieldStyle(.roundedBorder)
            }
        )
    }

    private func optionField(_ title: String, key: String, options: [String]) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .leading)
            TextField(key, text: propertyBinding(for: key))
                .font(.caption)
                .textFieldStyle(.roundedBorder)
            Menu {
                let suggestions = optionSuggestions(options, key: key)
                if let value = selectedEvent?.propertyValue(key), !value.isEmpty, !options.contains(value) {
                    Text("Custom: \(value)")
                    Divider()
                }
                ForEach(suggestions, id: \.self) { option in
                    Button {
                        session.updateSelectedMapEventProperty(key: key, value: option)
                    } label: {
                        Text(displayConstant(option))
                    }
                }
                if suggestions.isEmpty {
                    Text("No matches")
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
            .menuStyle(.borderlessButton)
            .help("Choose \(title.lowercased())")
        }
    }

    private func scriptField(_ title: String, key: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .leading)
            TextField(key, text: propertyBinding(for: key))
                .font(.caption)
                .textFieldStyle(.roundedBorder)
            Menu {
                Toggle("Include Shared", isOn: $includeSharedScriptSuggestions)
                Divider()
                ForEach(scriptSuggestions) { suggestion in
                    Button {
                        session.updateSelectedMapEventProperty(key: key, value: suggestion.label)
                    } label: {
                        Label(suggestion.label, systemImage: suggestion.sourceRole == .mapLocal ? "curlybraces" : "link")
                    }
                }
                if let event = selectedEvent, session.editableScriptSourcePath != nil {
                    Divider()
                    Button("Create Local Label", systemImage: "plus.rectangle.on.folder") {
                        createAndAssignScript(for: event, key: key)
                    }
                }
                if scriptSuggestions.isEmpty {
                    Text("No labels")
                }
            } label: {
                Image(systemName: "text.magnifyingglass")
            }
            .menuStyle(.borderlessButton)
            .help("Choose a script label from this map")
        }
    }

    private var scriptSuggestions: [MapScriptLabelSpan] {
        guard let scriptIndex = document.scriptIndex else { return [] }
        return scriptIndex.suggestions(
            matching: selectedEvent?.propertyValue("script") ?? "",
            includeShared: includeSharedScriptSuggestions
        )
    }

    private func optionSuggestions(_ options: [String], key: String) -> [String] {
        let query = selectedEvent?.propertyValue(key)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let matches = query.isEmpty
            ? options
            : options.filter { option in
                option.localizedCaseInsensitiveContains(query) || displayConstant(option).localizedCaseInsensitiveContains(query)
            }
        return Array(matches.prefix(80))
    }

    private func numericField(_ title: String, key: String, range: ClosedRange<Int>) -> some View {
        Stepper(value: integerBinding(for: key, range: range), in: range) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 96, alignment: .leading)
                Text("\(integerBinding(for: key, range: range).wrappedValue)")
                    .font(.caption.monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var selectedEvent: MapEventDescriptor? {
        session.selectedMapEvent
    }

    private var filteredEvents: [MapEventDescriptor] {
        let query = eventSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return session.stagedMapEvents.filter { event in
            if let selectedKindFilter, event.kind != selectedKindFilter {
                return false
            }
            guard !query.isEmpty else { return true }
            let haystack = ([event.kind.rawValue, "\(event.index)", event.templateKind?.title ?? ""] + event.properties.flatMap { [$0.key, $0.value] })
                .joined(separator: " ")
            return haystack.localizedCaseInsensitiveContains(query)
        }
    }

    private var groupedFilteredEvents: [MapEventGroup] {
        MapEventKind.allCases.compactMap { kind in
            let events = filteredEvents.filter { $0.kind == kind }
            guard !events.isEmpty else { return nil }
            return MapEventGroup(kind: kind, events: events)
        }
    }

    private var scriptResolutionCache: [String: MapScriptResolution] {
        document.scriptIndex?.resolutions(for: session.stagedMapEvents.compactMap(\.scriptLabel)) ?? [:]
    }

    private func eventCount(for kind: MapEventKind) -> Int {
        session.stagedMapEvents.filter { $0.kind == kind }.count
    }

    private func selectAdjacentEvent(offset: Int) {
        let events = filteredEvents
        guard !events.isEmpty else { return }
        let currentIndex = session.selectedMapEventID.flatMap { id in events.firstIndex { $0.id == id } } ?? (offset > 0 ? -1 : 0)
        let nextIndex = (currentIndex + offset + events.count) % events.count
        session.selectMapEvent(id: events[nextIndex].id)
    }

    private var insertionCoordinate: (x: Int, y: Int) {
        if let selectedMapCell = session.selectedMapCell {
            return (selectedMapCell.x, selectedMapCell.y)
        }
        if let selectedEvent = session.selectedMapEvent, let x = selectedEvent.x, let y = selectedEvent.y {
            return (x, y)
        }
        return (0, 0)
    }

    private func add(template: MapEventTemplateKind, at coordinate: (x: Int, y: Int)) {
        session.selectEventTemplate(template)
        session.addMapEvent(template: template, atX: coordinate.x, y: coordinate.y)
    }

    private func eventTitle(_ event: MapEventDescriptor) -> String {
        "\(event.templateKind?.title ?? event.kind.title) #\(event.index)"
    }

    private func eventSubtitle(_ event: MapEventDescriptor) -> String {
        var parts: [String] = []
        if let x = event.x, let y = event.y {
            parts.append("(\(x), \(y))")
        }
        if let script = event.propertyValue("script") {
            parts.append(script)
        } else if let destination = event.propertyValue("dest_map") {
            parts.append(destination)
        } else if let item = event.propertyValue("item") {
            parts.append(item)
        }
        return parts.isEmpty ? "No core fields" : parts.joined(separator: " ")
    }

    private func propertyBinding(for key: String) -> Binding<String> {
        Binding {
            selectedEvent?.propertyValue(key) ?? ""
        } set: { value in
            session.updateSelectedMapEventProperty(key: key, value: value)
        }
    }

    private func integerBinding(for key: String, range: ClosedRange<Int>) -> Binding<Int> {
        Binding {
            let value = selectedEvent?.propertyValue(key).flatMap(Int.init) ?? 0
            return min(max(value, range.lowerBound), range.upperBound)
        } set: { value in
            session.updateSelectedMapEventProperty(key: key, value: "\(value)")
        }
    }

    private func syncScriptDraft(span: MapScriptLabelSpan) {
        let key = StagedMapScriptBody.key(label: span.label, sourcePath: span.sourcePath)
        guard scriptDraftKey != key else { return }
        scriptDraftKey = key
        scriptDraftText = session.stagedScriptBody(label: span.label, sourcePath: span.sourcePath) ?? span.body
    }

    private func stagedScriptBody(for label: String) -> StagedMapScriptBody? {
        session.stagedMapScriptBodies.values.first { $0.label == label }
    }

    private func createAndAssignScript(for event: MapEventDescriptor, key: String = "script") {
        guard let sourcePath = session.editableScriptSourcePath else { return }
        let label = generatedScriptLabel(for: event)
        let body = "\tend"
        session.createScriptLabel(label: label, sourcePath: sourcePath, body: body)
        session.updateSelectedMapEventProperty(key: key, value: label)
        scriptDraftKey = StagedMapScriptBody.key(label: label, sourcePath: sourcePath)
        scriptDraftText = body
    }

    private func generatedScriptLabel(for event: MapEventDescriptor) -> String {
        let suffix = (event.templateKind?.rawValue ?? event.kind.rawValue)
            .replacingOccurrences(of: #"[^A-Za-z0-9_]"#, with: "_", options: .regularExpression)
        return "\(document.mapName)_EventScript_\(suffix)_\(event.index)"
    }

    private func primaryKeys(for event: MapEventDescriptor) -> [String] {
        switch event.templateKind ?? .object {
        case .object:
            return ["local_id", "type", "graphics_id", "x", "y", "elevation", "movement_type", "movement_range_x", "movement_range_y", "trainer_type", "trainer_sight_or_berry_tree_id", "script", "flag"]
        case .warp:
            return ["x", "y", "elevation", "dest_map", "dest_warp_id"]
        case .coordTrigger:
            return ["type", "x", "y", "elevation", "var", "var_value", "script"]
        case .bgSign:
            return ["type", "x", "y", "elevation", "player_facing_dir", "script"]
        case .bgHiddenItem:
            return ["type", "x", "y", "elevation", "item", "flag"]
        }
    }

    private func canEditScript(for event: MapEventDescriptor) -> Bool {
        if event.propertyValue("script") != nil {
            return true
        }

        switch event.templateKind {
        case .object, .coordTrigger, .bgSign:
            return true
        case .warp, .bgHiddenItem, nil:
            return false
        }
    }

    private func scriptResolutionSummary(for event: MapEventDescriptor, resolutions: [String: MapScriptResolution]) -> String? {
        guard let scriptLabel = event.scriptLabel, let resolution = resolutions[scriptLabel] else { return nil }
        switch resolution.state {
        case .resolved:
            return resolution.span?.sourceRole == .shared ? "shared" : "local"
        case .noScript:
            return nil
        case .missingLabel:
            return "missing"
        case .duplicateLabel:
            return "duplicate"
        case .generatedPath:
            return "generated"
        case .externalLabel:
            return "external"
        }
    }

    private func scriptResolutionColor(for event: MapEventDescriptor, resolutions: [String: MapScriptResolution]) -> Color {
        guard let scriptLabel = event.scriptLabel, let state = resolutions[scriptLabel]?.state else {
            return .secondary
        }
        switch state {
        case .resolved:
            return .secondary
        case .noScript:
            return .secondary
        case .missingLabel, .duplicateLabel, .generatedPath, .externalLabel:
            return .orange
        }
    }
}

private struct MapEventGroup: Identifiable {
    var id: String { kind.rawValue }

    let kind: MapEventKind
    let events: [MapEventDescriptor]
}

private extension MapEventKind {
    var title: String {
        switch self {
        case .object: "Objects"
        case .warp: "Warps"
        case .coord: "Coords"
        case .bg: "BG"
        case .connection: "Connections"
        }
    }

    var systemImage: String {
        switch self {
        case .object: "person.crop.square"
        case .warp: "arrow.triangle.branch"
        case .coord: "scope"
        case .bg: "signpost.right"
        case .connection: "point.3.connected.trianglepath.dotted"
        }
    }
}

private extension MapEventTemplateKind {
    var systemImage: String {
        switch self {
        case .object: "person.crop.square"
        case .warp: "arrow.triangle.branch"
        case .coordTrigger: "scope"
        case .bgSign: "signpost.right"
        case .bgHiddenItem: "shippingbox"
        }
    }
}

private func displayConstant(_ symbol: String) -> String {
    var value = symbol
    for prefix in [
        "OBJ_EVENT_GFX_",
        "MOVEMENT_TYPE_",
        "TRAINER_TYPE_",
        "BG_EVENT_PLAYER_FACING_",
        "ITEM_",
        "VAR_",
        "FLAG_",
        "MAP_"
    ] {
        if value.hasPrefix(prefix) {
            value.removeFirst(prefix.count)
            break
        }
    }
    return value
        .split(separator: "_")
        .map { word in
            word.prefix(1).uppercased() + word.dropFirst().lowercased()
        }
        .joined(separator: " ")
}
