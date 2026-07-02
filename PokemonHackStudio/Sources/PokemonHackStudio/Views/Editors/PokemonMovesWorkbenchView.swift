import PokemonHackCore
import SwiftUI

struct PokemonMovesWorkbenchView: View {
    let catalog: MoveCatalogViewState?
    let moves: [MoveDetailViewState]
    @Binding var selectedMoveID: String
    let selectedMove: MoveDetailViewState?
    let draft: MoveEditDraft?
    let isDirty: Bool
    let speciesCatalog: ProjectSpeciesCatalog?
    let loadStatus: MoveCatalogLoadStatus
    @Binding var filter: MoveWorkbenchFilter
    let fallbackRecords: [WorkbenchRecord]
    let onLoadCatalog: () -> Void
    let onUpdateDraft: (MoveEditDraft) -> Void
    let onRevealMoveInSidebar: (String) -> Void
    let onFocusSpecies: (String) -> Void
    let isSpeciesCompatibleWithMove: (String, String, LearnsetBucket) -> Bool
    let onSetSpeciesCompatibility: (String, String, LearnsetBucket, Bool) -> Void
    let onNavigateToResourceAsset: (String) -> Void

    var body: some View {
        Group {
            if let catalog {
                indexedMoves(catalog)
            } else if !fallbackRecords.isEmpty {
                fallbackMoves
            } else {
                noCatalogView
            }
        }
        .navigationTitle("Moves")
        .onAppear(perform: onLoadCatalog)
    }

    private func indexedMoves(_ catalog: MoveCatalogViewState) -> some View {
        GeometryReader { proxy in
            let layoutMode = WorkbenchLayoutMode(contentWidth: proxy.size.width)
            ScrollView {
                VStack(alignment: .leading, spacing: layoutMode.sectionSpacing) {
                    header(catalog, layoutMode: layoutMode)

                    if let selectedMove {
                        selectedMoveFilterNotice(selectedMove)
                        moveDetail(selectedMove, layoutMode: layoutMode)
                    } else {
                        ContentUnavailableView(
                            "No Move Selected",
                            systemImage: WorkbenchModule.moves.systemImage,
                            description: Text("Select a move to inspect its battle facts and learnability.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 360)
                    }
                }
                .padding(layoutMode.contentPadding)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    @ViewBuilder
    private func header(_ catalog: MoveCatalogViewState, layoutMode: WorkbenchLayoutMode) -> some View {
        let metricMinimum: CGFloat = layoutMode.isCompact ? 120 : 150

        VStack(alignment: .leading, spacing: layoutMode.sectionSpacing) {
            if layoutMode.isCompact {
                VStack(alignment: .leading, spacing: 10) {
                    moveSwitcher(catalog)
                    titleBlock(catalog)
                    StatusPill(state: catalog.status)
                    filterControls(catalog)
                }
            } else {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        moveSwitcher(catalog)
                        titleBlock(catalog)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 8) {
                        StatusPill(state: catalog.status)
                        Text(catalog.profile)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        filterControls(catalog)
                    }
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: metricMinimum), spacing: 12)], spacing: 12) {
                MetricCard(title: "Moves", value: "\(catalog.moveCount)", detail: "\(moves.count) visible")
                MetricCard(title: "TM/HM", value: "\(catalog.tmhmMoveCount)", detail: "Moves with machine learners")
                MetricCard(title: "Tutor", value: "\(catalog.tutorMoveCount)", detail: "Moves with tutor learners")
                MetricCard(title: "Learnsets", value: "\(catalog.learnsetEntryCount)", detail: "Read-only graph entries")
                MetricCard(title: "Diagnostics", value: "\(catalog.diagnostics.count)", detail: loadStatus.label)
            }
        }
    }

    private func titleBlock(_ catalog: MoveCatalogViewState) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Moves")
                .font(.largeTitle.weight(.semibold))
            Text("\(catalog.projectTitle) editable battle move definitions, compatibility, and learnability.")
                .foregroundStyle(.secondary)
            Text(catalog.rootPath)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
    }

    private func moveSwitcher(_ catalog: MoveCatalogViewState) -> some View {
        EditorRecordSwitcher(
            title: "Switch Move",
            selectedTitle: selectedMove?.displayName ?? "No Move Selected",
            selectedSubtitle: selectedMove?.moveID,
            systemImage: WorkbenchModule.moves.systemImage,
            items: catalog.moves.map(moveSwitcherItem),
            selectedID: selectedMoveID,
            emptyTitle: "No Moves",
            emptyDescription: "No moves matched the current search.",
            onSelect: { selectedMoveID = $0 }
        )
    }

    private func moveSwitcherItem(_ move: MoveDetailViewState) -> EditorRecordSwitcherItem {
        EditorRecordSwitcherItem(
            id: move.moveID,
            title: move.displayName,
            subtitle: move.moveID,
            detail: "\(move.learnerCount) linked learners",
            systemImage: WorkbenchModule.moves.systemImage,
            status: move.status,
            searchText: move.searchBlob
        )
    }

    private func filterControls(_ catalog: MoveCatalogViewState) -> some View {
        HStack(spacing: 8) {
            Picker("Filter", selection: $filter) {
                ForEach(MoveWorkbenchFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.menu)

            Text("\(moves.count) of \(catalog.moveCount)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func selectedMoveFilterNotice(_ move: MoveDetailViewState) -> some View {
        if !isMoveVisible(move) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Selected Move Hidden")
                        .font(.subheadline.weight(.semibold))
                    Text("\(move.displayName) is selected but is outside the current search or filter.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Button("Reveal", systemImage: "scope") {
                    onRevealMoveInSidebar(move.moveID)
                }
                .buttonStyle(.bordered)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func isMoveVisible(_ move: MoveDetailViewState) -> Bool {
        moves.contains { $0.moveID == move.moveID }
    }

    private func moveDetail(_ move: MoveDetailViewState, layoutMode: WorkbenchLayoutMode) -> some View {
        VStack(alignment: .leading, spacing: layoutMode.sectionSpacing) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(move.displayName)
                        .font(.title.weight(.semibold))
                    Text(move.moveID)
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                Spacer()
                StatusPill(state: move.status)
            }

            if layoutMode.isCompact {
                battleFactsSection(move)
                moveEditingSection
            } else {
                HStack(alignment: .top, spacing: 18) {
                    battleFactsSection(move)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    moveEditingSection
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }

            learnerSection(title: "TM/HM", rows: move.tmhmLearners, layoutMode: layoutMode)
            learnerSection(title: "Tutor", rows: move.tutorLearners, layoutMode: layoutMode)
            compatibilityBatchSection(move: move, layoutMode: layoutMode)
            learnerSection(title: "Learned By", rows: move.learnedBy, layoutMode: layoutMode)

            EditorSection(title: "Source") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        SourceLocationView(source: move.source)
                        Spacer(minLength: 8)
                        Button("Resources", systemImage: "doc.text.magnifyingglass") {
                            onNavigateToResourceAsset(move.source.path)
                        }
                        .disabled(move.source.path.isEmpty)
                    }
                    sourcePreviewText(move.sourcePreview)
                }
            }

            EditorSection(title: "Diagnostics") {
                if move.diagnostics.isEmpty {
                    Text("No diagnostics for this move.")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 10) {
                        ForEach(move.diagnostics) { diagnostic in
                            diagnosticRow(diagnostic)
                        }
                    }
                }
            }
        }
    }

    private func battleFactsSection(_ move: MoveDetailViewState) -> some View {
        EditorSection(title: "Battle Facts") {
            FactGrid(facts: move.battleFacts.isEmpty ? move.facts : move.battleFacts)
        }
    }

    @ViewBuilder
    private var moveEditingSection: some View {
        if let draft {
            editSection(draft)
        } else {
            EditorSection(title: "Editing") {
                Text("This move source shape is read-only.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func editSection(_ draft: MoveEditDraft) -> some View {
        EditorSection(title: isDirty ? "Battle Data Edited" : "Battle Data") {
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], alignment: .leading, spacing: 12) {
                    moveTextField("Effect", text: draftStringBinding(\.effect))
                    moveIntegerField("Power", value: draftIntBinding(\.power), range: 0...255)
                    moveTextField("Type", text: draftStringBinding(\.type))
                    moveIntegerField("Accuracy", value: draftIntBinding(\.accuracy), range: 0...100)
                    moveIntegerField("PP", value: draftIntBinding(\.pp), range: 0...255)
                    moveIntegerField("Secondary %", value: draftIntBinding(\.secondaryEffectChance), range: 0...100)
                    moveTextField("Target", text: draftStringBinding(\.target))
                    moveIntegerField("Priority", value: draftIntBinding(\.priority), range: -128...127)
                }

                Divider()

                TextField("Flags", text: flagsBinding)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))

                if draft.descriptionText != nil {
                    Divider()
                    descriptionEditor(text: descriptionBinding)
                }

                if hasContestScalarFields(draft) {
                    Divider()
                    contestScalarEditor(draft)
                }

                if draft.contestComboMoves != nil {
                    Divider()
                    contestComboMovesEditor(text: contestComboMovesBinding)
                }
            }
        }
    }

    private func hasContestScalarFields(_ draft: MoveEditDraft) -> Bool {
        draft.contestEffect != nil
            || draft.contestMoveEffect != nil
            || draft.contestCategory != nil
            || draft.contestAppeal != nil
            || draft.contestJam != nil
            || draft.contestComboStarterId != nil
    }

    private func contestScalarEditor(_ draft: MoveEditDraft) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], alignment: .leading, spacing: 12) {
            if draft.contestEffect != nil {
                moveTextField("Battle Contest Effect", text: draftOptionalStringBinding(\.contestEffect))
            }
            if draft.contestMoveEffect != nil {
                moveTextField("Contest Move Effect", text: draftOptionalStringBinding(\.contestMoveEffect))
            }
            if draft.contestCategory != nil {
                moveTextField("Contest Category", text: draftOptionalStringBinding(\.contestCategory))
            }
            if draft.contestAppeal != nil {
                moveIntegerField("Contest Appeal", value: draftOptionalIntBinding(\.contestAppeal), range: 0...255)
            }
            if draft.contestJam != nil {
                moveIntegerField("Contest Jam", value: draftOptionalIntBinding(\.contestJam), range: 0...255)
            }
            if draft.contestComboStarterId != nil {
                moveTextField("Combo Starter", text: draftOptionalStringBinding(\.contestComboStarterId))
            }
        }
    }

    private func moveTextField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
        }
    }

    private func moveIntegerField(_ title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Stepper(value: value, in: range) {
                Text("\(value.wrappedValue)")
                    .font(.system(.body, design: .monospaced))
            }
        }
    }

    private func draftStringBinding(_ keyPath: WritableKeyPath<MoveEditDraft, String>) -> Binding<String> {
        Binding(
            get: { draft?[keyPath: keyPath] ?? "" },
            set: { value in
                guard var draft else { return }
                draft[keyPath: keyPath] = value.trimmingCharacters(in: .whitespacesAndNewlines)
                onUpdateDraft(draft)
            }
        )
    }

    private func draftIntBinding(_ keyPath: WritableKeyPath<MoveEditDraft, Int>) -> Binding<Int> {
        Binding(
            get: { draft?[keyPath: keyPath] ?? 0 },
            set: { value in
                guard var draft else { return }
                draft[keyPath: keyPath] = value
                onUpdateDraft(draft)
            }
        )
    }

    private func draftOptionalStringBinding(_ keyPath: WritableKeyPath<MoveEditDraft, String?>) -> Binding<String> {
        Binding(
            get: { draft?[keyPath: keyPath] ?? "" },
            set: { value in
                guard var draft else { return }
                draft[keyPath: keyPath] = value.trimmingCharacters(in: .whitespacesAndNewlines)
                onUpdateDraft(draft)
            }
        )
    }

    private func draftOptionalIntBinding(_ keyPath: WritableKeyPath<MoveEditDraft, Int?>) -> Binding<Int> {
        Binding(
            get: { draft?[keyPath: keyPath] ?? 0 },
            set: { value in
                guard var draft else { return }
                draft[keyPath: keyPath] = value
                onUpdateDraft(draft)
            }
        )
    }

    private var flagsBinding: Binding<String> {
        Binding(
            get: { draft?.flags.joined(separator: " | ") ?? "" },
            set: { value in
                guard var draft else { return }
                draft.flags = value
                    .split(separator: "|")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                onUpdateDraft(draft)
            }
        )
    }

    private var descriptionBinding: Binding<String> {
        Binding(
            get: { draft?.descriptionText ?? "" },
            set: { value in
                guard var draft else { return }
                draft.descriptionText = value
                onUpdateDraft(draft)
            }
        )
    }

    private var contestComboMovesBinding: Binding<String> {
        Binding(
            get: { draft?.contestComboMoves?.joined(separator: ", ") ?? "" },
            set: { value in
                guard var draft else { return }
                draft.contestComboMoves = value
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                onUpdateDraft(draft)
            }
        )
    }

    private func descriptionEditor(text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Description Text")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextEditor(text: text)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 92)
                .scrollContentBackground(.hidden)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.22))
                )
        }
    }

    private func contestComboMovesEditor(text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Contest Combo Moves")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("Contest Combo Moves", text: text)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
        }
    }

    private func learnerSection(
        title: String,
        rows: [MoveLearnerRowViewState],
        layoutMode: WorkbenchLayoutMode
    ) -> some View {
        EditorSection(title: title) {
            if rows.isEmpty {
                Text("No \(title.lowercased()) learners indexed.")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: layoutMode.isCompact ? 170 : 210), spacing: 10)],
                    spacing: 10
                ) {
                    ForEach(rows.prefix(120)) { row in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: row.bucket == .tmhm ? "disc" : "sparkle.magnifyingglass")
                                .foregroundStyle(.secondary)
                                .frame(width: 18)

                            VStack(alignment: .leading, spacing: 4) {
                                Button {
                                    onFocusSpecies(row.speciesID)
                                } label: {
                                    Text(row.speciesID)
                                        .font(.callout.weight(.medium))
                                        .lineLimit(1)
                                }
                                .buttonStyle(.borderless)
                                Text(row.bucketTitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(row.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                SourceLocationView(source: row.source)
                                if !row.source.path.isEmpty {
                                    Button("Source", systemImage: "doc.text.magnifyingglass") {
                                        onNavigateToResourceAsset(row.source.path)
                                    }
                                    .font(.caption)
                                    .buttonStyle(.borderless)
                                }
                            }

                            Spacer(minLength: 4)
                        }
                        .padding(.vertical, 6)
                    }
                }

                if rows.count > 120 {
                    Text("\(rows.count - 120) more rows hidden. Narrow the search to focus the list.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func compatibilityBatchSection(move: MoveDetailViewState, layoutMode: WorkbenchLayoutMode) -> some View {
        EditorSection(title: "Compatibility Batch") {
            if let speciesCatalog {
                let supportsTMHM = speciesCatalog.constants[.tmhmMoves]?.contains { $0.symbol == move.moveID } == true
                let supportsTutor = speciesCatalog.constants[.tutorMoves]?.contains { $0.symbol == move.moveID } == true
                let supportsEgg = speciesCatalog.constants[.moves]?.contains { $0.symbol == move.moveID } == true

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("\(speciesCatalog.species.count) species")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text([
                            supportsTMHM ? "TM/HM editable" : "TM/HM unavailable",
                            supportsTutor ? "Tutor editable" : "Tutor unavailable",
                            supportsEgg ? "Egg editable" : "Egg unavailable"
                        ].joined(separator: " / "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: layoutMode.isCompact ? 210 : 260), spacing: 10)],
                        alignment: .leading,
                        spacing: 8
                    ) {
                        ForEach(speciesCatalog.species) { species in
                            VStack(alignment: .leading, spacing: 8) {
                                Button {
                                    onFocusSpecies(species.speciesID)
                                } label: {
                                    Text(displayConstant(species.speciesID))
                                        .font(.callout.weight(.medium))
                                        .lineLimit(1)
                                }
                                .buttonStyle(.borderless)
                                .help(species.speciesID)

                                HStack(spacing: 12) {
                                    Toggle("TM/HM", isOn: compatibilityBinding(speciesID: species.speciesID, moveID: move.moveID, bucket: .tmhm))
                                        .toggleStyle(.checkbox)
                                        .disabled(!supportsTMHM)
                                    Toggle("Tutor", isOn: compatibilityBinding(speciesID: species.speciesID, moveID: move.moveID, bucket: .tutor))
                                        .toggleStyle(.checkbox)
                                        .disabled(!supportsTutor)
                                    Toggle("Egg", isOn: compatibilityBinding(speciesID: species.speciesID, moveID: move.moveID, bucket: .egg))
                                        .toggleStyle(.checkbox)
                                        .disabled(!supportsEgg)
                                }
                                .font(.caption)
                            }
                            .padding(10)
                            .background(.background, in: RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.quaternary, lineWidth: 1)
                            )
                        }
                    }
                }
            } else {
                Text("Open a supported Pokemon data project to batch-stage move compatibility.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func compatibilityBinding(
        speciesID: String,
        moveID: String,
        bucket: LearnsetBucket
    ) -> Binding<Bool> {
        Binding(
            get: { isSpeciesCompatibleWithMove(speciesID, moveID, bucket) },
            set: { isEnabled in
                onSetSpeciesCompatibility(speciesID, moveID, bucket, isEnabled)
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

    private var fallbackMoves: some View {
        EditorListShell(title: "Moves", records: fallbackRecords) { record in
            EditorSection(title: "Battle Facts") {
                FactGrid(facts: record.facts)
            }

            SourcePreviewBlock(text: record.preview)
            NotesList(notes: record.notes)
        }
    }

    private var noCatalogView: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Moves")
                    .font(.largeTitle.weight(.semibold))
                Text("Open a supported project to inspect move definitions, TM/HM compatibility, tutor learnsets, and source diagnostics.")
                    .foregroundStyle(.secondary)
            }

            EditorSection(title: "Catalog") {
                ContentUnavailableView(
                    loadStatus.label,
                    systemImage: WorkbenchModule.moves.systemImage,
                    description: Text("Open a supported project to load the move catalog, editable classic move rows, compatibility checklists, and source diagnostics.")
                )
            }
        }
        .padding(24)
    }
}
