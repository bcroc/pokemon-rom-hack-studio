import SwiftUI

struct PokemonMovesWorkbenchView: View {
    let catalog: MoveCatalogViewState?
    let moves: [MoveDetailViewState]
    @Binding var selectedMoveID: String
    let selectedMove: MoveDetailViewState?
    let loadStatus: MoveCatalogLoadStatus
    @Binding var filter: MoveWorkbenchFilter
    let fallbackRecords: [WorkbenchRecord]
    let onLoadCatalog: () -> Void

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
        VStack(spacing: 0) {
            header(catalog)
                .padding(.horizontal, 24)
                .padding(.vertical, 18)

            Divider()

            HStack(spacing: 0) {
                moveList
                    .frame(minWidth: 240, idealWidth: 300, maxWidth: 360)

                Divider()

                ScrollView {
                    if let selectedMove {
                        moveDetail(selectedMove)
                    } else {
                        ContentUnavailableView(
                            "No Move Selected",
                            systemImage: WorkbenchModule.moves.systemImage,
                            description: Text("Select a move to inspect its battle facts and learnability.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 360)
                    }
                }
            }
        }
    }

    private func header(_ catalog: MoveCatalogViewState) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Moves")
                        .font(.largeTitle.weight(.semibold))
                    Text("\(catalog.projectTitle) read-only battle move definitions and learnability.")
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
                MetricCard(title: "Moves", value: "\(catalog.moveCount)", detail: "\(moves.count) visible")
                MetricCard(title: "TM/HM", value: "\(catalog.tmhmMoveCount)", detail: "Moves with machine learners")
                MetricCard(title: "Tutor", value: "\(catalog.tutorMoveCount)", detail: "Moves with tutor learners")
                MetricCard(title: "Learnsets", value: "\(catalog.learnsetEntryCount)", detail: "Read-only graph entries")
                MetricCard(title: "Diagnostics", value: "\(catalog.diagnostics.count)", detail: loadStatus.label)
            }
        }
    }

    private var moveList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Filter", selection: $filter) {
                ForEach(MoveWorkbenchFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.menu)

            if moves.isEmpty {
                ContentUnavailableView(
                    "No Matching Moves",
                    systemImage: "magnifyingglass",
                    description: Text("No move rows match the current search and filter.")
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(moves) { move in
                            moveListRow(move)
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
        }
        .padding(16)
        .background(.background)
    }

    private func moveListRow(_ move: MoveDetailViewState) -> some View {
        Button {
            selectedMoveID = move.moveID
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: WorkbenchModule.moves.systemImage)
                    .foregroundStyle(.secondary)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 3) {
                    Text(move.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    Text(move.moveID)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text("\(move.tmhmLearners.count) TM/HM · \(move.tutorLearners.count) tutor · \(move.learnedBy.count) learned")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)
                StatusPill(state: move.status)
            }
            .padding(10)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedMoveID == move.moveID ? Color.accentColor.opacity(0.16) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func moveDetail(_ move: MoveDetailViewState) -> some View {
        VStack(alignment: .leading, spacing: 18) {
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

            EditorSection(title: "Battle Facts") {
                FactGrid(facts: move.battleFacts.isEmpty ? move.facts : move.battleFacts)
            }

            learnerSection(title: "TM/HM", rows: move.tmhmLearners)
            learnerSection(title: "Tutor", rows: move.tutorLearners)
            learnerSection(title: "Learned By", rows: move.learnedBy)

            EditorSection(title: "Source") {
                VStack(alignment: .leading, spacing: 10) {
                    SourceLocationView(source: move.source)
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
        .padding(24)
    }

    private func learnerSection(title: String, rows: [MoveLearnerRowViewState]) -> some View {
        EditorSection(title: title) {
            if rows.isEmpty {
                Text("No \(title.lowercased()) learners indexed.")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 10)], spacing: 10) {
                    ForEach(rows.prefix(120)) { row in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: row.bucket == .tmhm ? "disc" : "sparkle.magnifyingglass")
                                .foregroundStyle(.secondary)
                                .frame(width: 18)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.speciesID)
                                    .font(.callout.weight(.medium))
                                    .lineLimit(1)
                                Text(row.bucketTitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(row.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                SourceLocationView(source: row.source)
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
                    description: Text("The current app surface uses the existing read-only move graph until a core ProjectMoveCatalog is added.")
                )
            }
        }
        .padding(24)
    }
}
