import AppKit
import PokemonHackCore
import SwiftUI

struct PokemonSpeciesWorkbenchView: View {
    let catalog: PokemonHackCore.ProjectSpeciesCatalog?
    let species: [PokemonHackCore.SpeciesDetail]
    @Binding var selectedSpeciesID: String
    let selectedSpecies: PokemonHackCore.SpeciesDetail?
    let draft: PokemonHackCore.SpeciesEditDraft?
    let isDirty: Bool
    let rootPath: String?
    let loadStatus: SpeciesCatalogLoadStatus
    let onLoadCatalog: () -> Void
    let onUpdateDraft: (PokemonHackCore.SpeciesEditDraft) -> Void
    let onNavigateToResourceAsset: (String) -> Void

    @State private var sourceExpanded = false
    @State private var showCompactBrowser = false

    var body: some View {
        Group {
            if let catalog {
                GeometryReader { proxy in
                    let layoutMode = WorkbenchLayoutMode(contentWidth: proxy.size.width)

                    if layoutMode.isCompact {
                        compactWorkbench(catalog: catalog, layoutMode: layoutMode)
                    } else {
                        HSplitView {
                            speciesBrowser(catalog: catalog)
                                .frame(minWidth: 230, idealWidth: 290, maxWidth: 380, maxHeight: .infinity)

                            speciesDetail(layoutMode: layoutMode)
                                .frame(minWidth: 560, maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Pokemon Catalog",
                    systemImage: "sparkles",
                    description: Text(loadStatus.label)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: selectedSpeciesID) { _, _ in
            showCompactBrowser = false
        }
        .onAppear {
            guard catalog == nil else { return }
            DispatchQueue.main.async {
                onLoadCatalog()
            }
        }
        .navigationTitle("Pokemon")
    }

    private func compactWorkbench(
        catalog: PokemonHackCore.ProjectSpeciesCatalog,
        layoutMode: WorkbenchLayoutMode
    ) -> some View {
        VStack(spacing: 0) {
            compactBrowserBar(catalog: catalog)
            Divider()
            speciesDetail(layoutMode: layoutMode)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func compactBrowserBar(catalog: PokemonHackCore.ProjectSpeciesCatalog) -> some View {
        HStack(spacing: 10) {
            Button("Pokemon", systemImage: "sidebar.left") {
                showCompactBrowser.toggle()
            }
            .help("Open Pokemon browser")
            .popover(isPresented: $showCompactBrowser, arrowEdge: .bottom) {
                speciesBrowser(catalog: catalog)
                    .frame(
                        width: WorkbenchLayoutMode.compactPopoverWidth,
                        height: WorkbenchLayoutMode.compactPopoverHeight
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(selectedSpecies?.displayName ?? "No Pokemon Selected")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("\(species.count) of \(catalog.speciesCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            StatusPill(state: validationState(for: catalog.diagnostics))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func speciesBrowser(catalog: PokemonHackCore.ProjectSpeciesCatalog) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pokemon")
                        .font(.headline)
                    Text("\(species.count) of \(catalog.speciesCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                StatusPill(state: validationState(for: catalog.diagnostics))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            if species.isEmpty {
                ContentUnavailableView(
                    "No Pokemon",
                    systemImage: "magnifyingglass",
                    description: Text("No rows matched the current search.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedSpeciesID) {
                    ForEach(species) { detail in
                        SpeciesBrowserRow(species: detail, rootPath: rootPath)
                            .tag(detail.speciesID)
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }

    @ViewBuilder
    private func speciesDetail(layoutMode: WorkbenchLayoutMode) -> some View {
        if let selectedSpecies {
            if let draft {
                ScrollView {
                    VStack(alignment: .leading, spacing: layoutMode.sectionSpacing) {
                        SpeciesHero(species: selectedSpecies, draft: draft, isDirty: isDirty, rootPath: rootPath)

                        if layoutMode.isCompact {
                            VStack(alignment: .leading, spacing: layoutMode.sectionSpacing) {
                                statsSection(draft: draft)
                                typingAbilitiesSection(draft: draft)
                            }
                        } else {
                            HStack(alignment: .top, spacing: 18) {
                                statsSection(draft: draft)
                                typingAbilitiesSection(draft: draft)
                            }
                        }

                        if layoutMode.isCompact {
                            VStack(alignment: .leading, spacing: layoutMode.sectionSpacing) {
                                trainingSection(draft: draft)
                                breedingItemsSection(draft: draft)
                            }
                        } else {
                            HStack(alignment: .top, spacing: 18) {
                                trainingSection(draft: draft)
                                breedingItemsSection(draft: draft)
                            }
                        }

                        levelUpSection(draft: draft)
                        tmhmSection(draft: draft)
                        eggMovesSection(draft: draft)
                        relatedDataSection(for: selectedSpecies, layoutMode: layoutMode)
                        sourceSection(for: selectedSpecies)
                        diagnosticsSection(for: selectedSpecies)
                    }
                    .padding(layoutMode.contentPadding)
                }
            } else {
                readOnlyDetail(species: selectedSpecies, layoutMode: layoutMode)
            }
        } else {
            ContentUnavailableView(
                "No Pokemon Selected",
                systemImage: "sidebar.left",
                description: Text("Select a Pokemon to edit its source-backed data.")
            )
        }
    }

    private func statsSection(draft: PokemonHackCore.SpeciesEditDraft) -> some View {
        EditorSection(title: "Stats") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 12)], alignment: .leading, spacing: 12) {
                SpeciesIntegerField(title: "HP", value: statBinding(\.hp), range: 0...255)
                SpeciesIntegerField(title: "Attack", value: statBinding(\.attack), range: 0...255)
                SpeciesIntegerField(title: "Defense", value: statBinding(\.defense), range: 0...255)
                SpeciesIntegerField(title: "Speed", value: statBinding(\.speed), range: 0...255)
                SpeciesIntegerField(title: "Sp. Attack", value: statBinding(\.spAttack), range: 0...255)
                SpeciesIntegerField(title: "Sp. Defense", value: statBinding(\.spDefense), range: 0...255)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func typingAbilitiesSection(draft: PokemonHackCore.SpeciesEditDraft) -> some View {
        EditorSection(title: "Typing And Abilities") {
            VStack(alignment: .leading, spacing: 12) {
                SpeciesConstantPicker(title: "Type 1", selection: fixedListBinding(\.types, index: 0, fallback: "TYPE_NORMAL"), constants: constants(.types))
                SpeciesConstantPicker(title: "Type 2", selection: fixedListBinding(\.types, index: 1, fallback: "TYPE_NORMAL"), constants: constants(.types))
                Divider()
                SpeciesConstantPicker(title: "Ability 1", selection: fixedListBinding(\.abilities, index: 0, fallback: "ABILITY_NONE"), constants: constants(.abilities))
                SpeciesConstantPicker(title: "Ability 2", selection: fixedListBinding(\.abilities, index: 1, fallback: "ABILITY_NONE"), constants: constants(.abilities))
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func trainingSection(draft: PokemonHackCore.SpeciesEditDraft) -> some View {
        EditorSection(title: "Training") {
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 12)], alignment: .leading, spacing: 12) {
                    speciesTextField("Catch Rate", text: draftStringBinding(\.catchRate))
                    speciesTextField("EXP Yield", text: draftStringBinding(\.expYield))
                    speciesTextField("Safari Flee", text: draftStringBinding(\.safariZoneFleeRate))
                    speciesTextField("Gender", text: draftStringBinding(\.genderRatio))
                    speciesTextField("Egg Cycles", text: draftStringBinding(\.eggCycles))
                    speciesTextField("Friendship", text: draftStringBinding(\.friendship))
                }
                SpeciesConstantPicker(title: "Growth Rate", selection: draftStringBinding(\.growthRate), constants: constants(.growthRates))

                Divider()

                Text("EV Yield")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 12)], alignment: .leading, spacing: 12) {
                    SpeciesIntegerField(title: "HP", value: evBinding(\.hp), range: 0...3)
                    SpeciesIntegerField(title: "Attack", value: evBinding(\.attack), range: 0...3)
                    SpeciesIntegerField(title: "Defense", value: evBinding(\.defense), range: 0...3)
                    SpeciesIntegerField(title: "Speed", value: evBinding(\.speed), range: 0...3)
                    SpeciesIntegerField(title: "Sp. Attack", value: evBinding(\.spAttack), range: 0...3)
                    SpeciesIntegerField(title: "Sp. Defense", value: evBinding(\.spDefense), range: 0...3)
                }
                Text("\(draft.evYield.total) total")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(draft.evYield.total > 3 ? Color.orange : Color.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func breedingItemsSection(draft: PokemonHackCore.SpeciesEditDraft) -> some View {
        EditorSection(title: "Breeding And Items") {
            VStack(alignment: .leading, spacing: 12) {
                SpeciesConstantPicker(title: "Egg Group 1", selection: fixedListBinding(\.eggGroups, index: 0, fallback: "EGG_GROUP_NONE"), constants: constants(.eggGroups))
                SpeciesConstantPicker(title: "Egg Group 2", selection: fixedListBinding(\.eggGroups, index: 1, fallback: "EGG_GROUP_NONE"), constants: constants(.eggGroups))
                Divider()
                SpeciesConstantPicker(title: "Common Item", selection: draftStringBinding(\.itemCommon), constants: constants(.items))
                SpeciesConstantPicker(title: "Rare Item", selection: draftStringBinding(\.itemRare), constants: constants(.items))
                Divider()
                SpeciesConstantPicker(title: "Body Color", selection: draftStringBinding(\.bodyColor), constants: constants(.bodyColors))
                Toggle("No sprite flip", isOn: draftBoolBinding(\.noFlip))
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func levelUpSection(draft: PokemonHackCore.SpeciesEditDraft) -> some View {
        EditorSection(title: "Level-Up Moves") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(draft.levelUpMoves.count) moves")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Add Move", systemImage: "plus") {
                        addLevelUpMove()
                    }
                }

                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 8) {
                    GridRow {
                        Text("Level").foregroundStyle(.secondary)
                        Text("Move").foregroundStyle(.secondary)
                        Text("").accessibilityHidden(true)
                    }
                    .font(.caption.weight(.semibold))

                    ForEach(Array(draft.levelUpMoves.enumerated()), id: \.element.id) { index, move in
                        GridRow {
                            SpeciesIntegerField(title: "Level", value: levelUpLevelBinding(id: move.id), range: 1...100)
                                .labelsHidden()
                            SpeciesConstantPicker(title: "Move", selection: levelUpMoveBinding(id: move.id), constants: constants(.moves))
                                .labelsHidden()
                            moveControls(
                                canMoveUp: index > 0,
                                canMoveDown: index < draft.levelUpMoves.count - 1,
                                onMoveUp: { moveLevelUpMove(id: move.id, offset: -1) },
                                onMoveDown: { moveLevelUpMove(id: move.id, offset: 1) },
                                onRemove: { removeLevelUpMove(id: move.id) }
                            )
                        }
                    }
                }
            }
        }
    }

    private func tmhmSection(draft: PokemonHackCore.SpeciesEditDraft) -> some View {
        EditorSection(title: "TM/HM") {
            let moves = constants(.tmhmMoves)
            if moves.isEmpty {
                Text("No TM/HM move constants were indexed for this project.")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 10)], alignment: .leading, spacing: 8) {
                    ForEach(moves) { move in
                        Toggle(displayConstant(move.symbol), isOn: tmhmBinding(move.symbol))
                            .toggleStyle(.checkbox)
                            .help(move.symbol)
                    }
                }
            }
        }
    }

    private func eggMovesSection(draft: PokemonHackCore.SpeciesEditDraft) -> some View {
        EditorSection(title: "Egg Moves") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(draft.eggMoves.count) moves")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Add Move", systemImage: "plus") {
                        addEggMove()
                    }
                }

                if draft.eggMoves.isEmpty {
                    Text("No egg moves indexed.")
                        .foregroundStyle(.secondary)
                } else {
                    Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 8) {
                        ForEach(Array(draft.eggMoves.enumerated()), id: \.offset) { index, move in
                            GridRow {
                                SpeciesConstantPicker(title: "Egg Move \(index + 1)", selection: eggMoveBinding(index: index, fallback: move), constants: constants(.moves))
                                    .labelsHidden()
                                moveControls(
                                    canMoveUp: index > 0,
                                    canMoveDown: index < draft.eggMoves.count - 1,
                                    onMoveUp: { moveEggMove(index: index, offset: -1) },
                                    onMoveDown: { moveEggMove(index: index, offset: 1) },
                                    onRemove: { removeEggMove(index: index) }
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    private func relatedDataSection(
        for species: PokemonHackCore.SpeciesDetail,
        layoutMode: WorkbenchLayoutMode
    ) -> some View {
        Group {
            if layoutMode.isCompact {
                VStack(alignment: .leading, spacing: layoutMode.sectionSpacing) {
                    evolutionSection(for: species)
                    pokedexSection(for: species)
                }
            } else {
                HStack(alignment: .top, spacing: 18) {
                    evolutionSection(for: species)
                    pokedexSection(for: species)
                }
            }
        }
    }

    private func evolutionSection(for species: PokemonHackCore.SpeciesDetail) -> some View {
        EditorSection(title: "Evolution") {
            if species.evolutions.isEmpty {
                Text("No evolution rows indexed.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(species.evolutions) { evolution in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            SpeciesTag(text: displayConstant(evolution.method))
                            Text(evolution.parameter)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            Image(systemName: "arrow.right")
                                .foregroundStyle(.secondary)
                            if canSelectSpecies(evolution.targetSpecies) {
                                Button {
                                    selectedSpeciesID = evolution.targetSpecies
                                } label: {
                                    Text(displayConstant(evolution.targetSpecies))
                                        .fontWeight(.medium)
                                }
                                .buttonStyle(.borderless)
                            } else {
                                Text(displayConstant(evolution.targetSpecies))
                                    .fontWeight(.medium)
                            }
                            Spacer()
                            SourceLocationView(source: sourceLocation(evolution.sourceSpan, symbol: evolution.targetSpecies))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func pokedexSection(for species: PokemonHackCore.SpeciesDetail) -> some View {
        EditorSection(title: "Pokedex") {
            if let pokedex = species.pokedex {
                VStack(alignment: .leading, spacing: 10) {
                    FactGrid(facts: [
                        Fact(label: "Category", value: pokedex.categoryName ?? "Unknown"),
                        Fact(label: "Height", value: pokedex.height ?? "Unknown"),
                        Fact(label: "Weight", value: pokedex.weight ?? "Unknown")
                    ])
                    if let description = pokedex.description {
                        Text(description)
                            .lineLimit(4)
                            .textSelection(.enabled)
                    }
                    SourceLocationView(source: sourceLocation(pokedex.sourceSpan, symbol: species.speciesID))
                }
            } else {
                Text("No Pokedex entry indexed.")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func sourceSection(for species: PokemonHackCore.SpeciesDetail) -> some View {
        DisclosureGroup(isExpanded: $sourceExpanded) {
            VStack(alignment: .leading, spacing: 12) {
                SourceLocationView(source: sourceLocation(species.sourceSpan, symbol: species.speciesID))
                SourcePreviewBlock(text: species.sourcePreview)
                assetsSection(for: species)
            }
            .padding(.top, 8)
        } label: {
            Label("Source And Assets", systemImage: "curlybraces.square")
                .font(.headline)
        }
    }

    private func assetsSection(for species: PokemonHackCore.SpeciesDetail) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], alignment: .leading, spacing: 12) {
            ForEach(species.assets) { asset in
                SpeciesAssetTile(asset: asset, rootPath: rootPath) {
                    onNavigateToResourceAsset(asset.relativePath)
                }
            }
        }
    }

    @ViewBuilder
    private func diagnosticsSection(for species: PokemonHackCore.SpeciesDetail) -> some View {
        if !species.diagnostics.isEmpty {
            EditorSection(title: "Diagnostics") {
                VStack(spacing: 8) {
                    ForEach(species.diagnostics) { diagnostic in
                        SpeciesDiagnosticRow(diagnostic: diagnostic)
                    }
                }
            }
        }
    }

    private func readOnlyDetail(
        species: PokemonHackCore.SpeciesDetail,
        layoutMode: WorkbenchLayoutMode
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: layoutMode.sectionSpacing) {
                SpeciesHero(species: species, draft: nil, isDirty: false, rootPath: rootPath)
                if layoutMode.isCompact {
                    VStack(alignment: .leading, spacing: layoutMode.sectionSpacing) {
                        EditorSection(title: "Stats") {
                            SpeciesStatsGrid(stats: species.baseStats)
                        }
                        EditorSection(title: "EV Yield") {
                            SpeciesEVYieldGrid(evYield: species.evYield)
                        }
                    }
                } else {
                    HStack(alignment: .top, spacing: 18) {
                        EditorSection(title: "Stats") {
                            SpeciesStatsGrid(stats: species.baseStats)
                        }
                        EditorSection(title: "EV Yield") {
                            SpeciesEVYieldGrid(evYield: species.evYield)
                        }
                    }
                }
                relatedDataSection(for: species, layoutMode: layoutMode)
                sourceSection(for: species)
                diagnosticsSection(for: species)
            }
            .padding(layoutMode.contentPadding)
        }
    }

    private func constants(_ group: PokemonHackCore.SpeciesConstantGroup) -> [PokemonHackCore.SpeciesConstant] {
        catalog?.constants[group] ?? []
    }

    private func validationState(for diagnostics: [PokemonHackCore.Diagnostic]) -> ValidationState {
        let states = diagnostics.map { WorkbenchStore.validationState(for: $0.severity) }
        if states.contains(.error) {
            return .error
        }
        if states.contains(.warning) {
            return .warning
        }
        return .valid
    }

    private func canSelectSpecies(_ speciesID: String) -> Bool {
        catalog?.species.contains(where: { $0.speciesID == speciesID }) == true
    }

    private func sourceLocation(_ span: PokemonHackCore.SourceSpan, symbol: String) -> SourceLocation {
        SourceLocation(path: span.relativePath, symbol: symbol, line: span.startLine)
    }

    private func speciesTextField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func moveControls(
        canMoveUp: Bool,
        canMoveDown: Bool,
        onMoveUp: @escaping () -> Void,
        onMoveDown: @escaping () -> Void,
        onRemove: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 6) {
            Button("Move Up", systemImage: "arrow.up") { onMoveUp() }
                .labelStyle(.iconOnly)
                .disabled(!canMoveUp)
            Button("Move Down", systemImage: "arrow.down") { onMoveDown() }
                .labelStyle(.iconOnly)
                .disabled(!canMoveDown)
            Button("Remove", systemImage: "trash") { onRemove() }
                .labelStyle(.iconOnly)
        }
    }

    private func updateDraft(_ update: (inout PokemonHackCore.SpeciesEditDraft) -> Void) {
        guard var draft else { return }
        update(&draft)
        onUpdateDraft(draft)
    }

    private func draftStringBinding(_ keyPath: WritableKeyPath<PokemonHackCore.SpeciesEditDraft, String>) -> Binding<String> {
        Binding(
            get: { draft?[keyPath: keyPath] ?? "" },
            set: { value in
                updateDraft { $0[keyPath: keyPath] = value }
            }
        )
    }

    private func draftBoolBinding(_ keyPath: WritableKeyPath<PokemonHackCore.SpeciesEditDraft, Bool>) -> Binding<Bool> {
        Binding(
            get: { draft?[keyPath: keyPath] ?? false },
            set: { value in
                updateDraft { $0[keyPath: keyPath] = value }
            }
        )
    }

    private func statBinding(_ keyPath: WritableKeyPath<PokemonHackCore.SpeciesBaseStatsDraft, Int>) -> Binding<Int> {
        Binding(
            get: { draft?.baseStats[keyPath: keyPath] ?? 0 },
            set: { value in
                updateDraft { $0.baseStats[keyPath: keyPath] = value }
            }
        )
    }

    private func evBinding(_ keyPath: WritableKeyPath<PokemonHackCore.SpeciesEVYieldDraft, Int>) -> Binding<Int> {
        Binding(
            get: { draft?.evYield[keyPath: keyPath] ?? 0 },
            set: { value in
                updateDraft { $0.evYield[keyPath: keyPath] = value }
            }
        )
    }

    private func fixedListBinding(
        _ keyPath: WritableKeyPath<PokemonHackCore.SpeciesEditDraft, [String]>,
        index: Int,
        fallback: String
    ) -> Binding<String> {
        Binding(
            get: {
                guard let values = draft?[keyPath: keyPath], values.indices.contains(index) else { return fallback }
                return values[index]
            },
            set: { value in
                updateDraft { draft in
                    while draft[keyPath: keyPath].count <= index {
                        draft[keyPath: keyPath].append(fallback)
                    }
                    draft[keyPath: keyPath][index] = value
                }
            }
        )
    }

    private func levelUpLevelBinding(id: String) -> Binding<Int> {
        Binding(
            get: { draft?.levelUpMoves.first(where: { $0.id == id })?.level ?? 1 },
            set: { value in
                updateDraft { draft in
                    guard let index = draft.levelUpMoves.firstIndex(where: { $0.id == id }) else { return }
                    draft.levelUpMoves[index].level = value
                }
            }
        )
    }

    private func levelUpMoveBinding(id: String) -> Binding<String> {
        Binding(
            get: { draft?.levelUpMoves.first(where: { $0.id == id })?.move ?? defaultMove },
            set: { value in
                updateDraft { draft in
                    guard let index = draft.levelUpMoves.firstIndex(where: { $0.id == id }) else { return }
                    draft.levelUpMoves[index].move = value
                }
            }
        )
    }

    private func tmhmBinding(_ move: String) -> Binding<Bool> {
        Binding(
            get: { draft?.tmhmMoves.contains(move) ?? false },
            set: { enabled in
                updateDraft { draft in
                    if enabled {
                        if !draft.tmhmMoves.contains(move) {
                            draft.tmhmMoves.append(move)
                            draft.tmhmMoves.sort()
                        }
                    } else {
                        draft.tmhmMoves.removeAll { $0 == move }
                    }
                }
            }
        )
    }

    private func eggMoveBinding(index: Int, fallback: String) -> Binding<String> {
        Binding(
            get: {
                guard let moves = draft?.eggMoves, moves.indices.contains(index) else { return fallback }
                return moves[index]
            },
            set: { value in
                updateDraft { draft in
                    guard draft.eggMoves.indices.contains(index) else { return }
                    draft.eggMoves[index] = value
                }
            }
        )
    }

    private func addLevelUpMove() {
        updateDraft { draft in
            draft.levelUpMoves.append(PokemonHackCore.SpeciesLevelUpMoveDraft(level: 1, move: defaultMove))
        }
    }

    private func removeLevelUpMove(id: String) {
        updateDraft { draft in
            draft.levelUpMoves.removeAll { $0.id == id }
        }
    }

    private func moveLevelUpMove(id: String, offset: Int) {
        updateDraft { draft in
            guard let index = draft.levelUpMoves.firstIndex(where: { $0.id == id }) else { return }
            let target = index + offset
            guard draft.levelUpMoves.indices.contains(target) else { return }
            draft.levelUpMoves.swapAt(index, target)
        }
    }

    private func addEggMove() {
        updateDraft { draft in
            draft.eggMoves.append(defaultMove)
        }
    }

    private func removeEggMove(index: Int) {
        updateDraft { draft in
            guard draft.eggMoves.indices.contains(index) else { return }
            draft.eggMoves.remove(at: index)
        }
    }

    private func moveEggMove(index: Int, offset: Int) {
        updateDraft { draft in
            let target = index + offset
            guard draft.eggMoves.indices.contains(index), draft.eggMoves.indices.contains(target) else { return }
            draft.eggMoves.swapAt(index, target)
        }
    }

    private var defaultMove: String {
        if constants(.moves).contains(where: { $0.symbol == "MOVE_TACKLE" }) {
            return "MOVE_TACKLE"
        }
        return constants(.moves).first { $0.symbol != "MOVE_NONE" }?.symbol ?? "MOVE_NONE"
    }
}

private struct SpeciesBrowserRow: View {
    let species: PokemonHackCore.SpeciesDetail
    let rootPath: String?

    var body: some View {
        HStack(spacing: 10) {
            SpeciesAssetPreview(
                asset: species.assets.first { $0.kind == .icon },
                rootPath: rootPath,
                size: 28
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(species.displayName)
                        .lineLimit(1)
                    if !species.isEditable {
                        Image(systemName: "lock.doc")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .help("Read-only source shape")
                    }
                }
                .help(species.speciesID)

                HStack(spacing: 4) {
                    ForEach(Array(species.types.prefix(2).enumerated()), id: \.offset) { _, type in
                        SpeciesTag(text: displayConstant(type))
                    }
                }
            }
        }
        .padding(.vertical, 3)
    }
}

private struct SpeciesHero: View {
    let species: PokemonHackCore.SpeciesDetail
    let draft: PokemonHackCore.SpeciesEditDraft?
    let isDirty: Bool
    let rootPath: String?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            horizontalHero
            compactHero
        }
        .padding(.bottom, 4)
    }

    private var horizontalHero: some View {
        HStack(alignment: .top, spacing: 18) {
            frontPreview(size: 112)

            VStack(alignment: .leading, spacing: 10) {
                titleRow(font: .largeTitle.weight(.semibold))
                tagRow
                metricRow
            }

            Spacer()

            secondaryPreviews
        }
    }

    private var compactHero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                frontPreview(size: 72)

                VStack(alignment: .leading, spacing: 8) {
                    titleRow(font: .title2.weight(.semibold))
                    tagRow
                }

                Spacer(minLength: 8)
            }

            metricRow
        }
    }

    private func frontPreview(size: CGFloat) -> some View {
        SpeciesAssetPreview(
            asset: species.assets.first { $0.kind == .front },
            rootPath: rootPath,
            size: size
        )
    }

    private func titleRow(font: Font) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(species.displayName)
                .font(font)
                .lineLimit(1)
            if isDirty {
                DirtyPill(isDirty: true)
            }
            StatusPill(state: validationState)
        }
    }

    private var tagRow: some View {
        HStack(spacing: 6) {
            SpeciesTagCloud(values: (draft?.types ?? species.types).map(displayConstant))
            SpeciesTagCloud(values: (draft?.abilities ?? species.abilities).map(displayConstant))
        }
    }

    private var metricRow: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 82), spacing: 12)], alignment: .leading, spacing: 8) {
            heroMetric(title: "BST", value: "\(baseStatTotal)")
            heroMetric(title: "EVs", value: "\(evTotal)")
            heroMetric(title: "Level Moves", value: "\(draft?.levelUpMoves.count ?? species.learnsets.levelUp.count)")
            heroMetric(title: "TM/HM", value: "\(draft?.tmhmMoves.count ?? species.learnsets.tmhm.count)")
            heroMetric(title: "Egg", value: "\(draft?.eggMoves.count ?? species.learnsets.egg.count)")
        }
    }

    private var secondaryPreviews: some View {
        VStack(spacing: 10) {
            SpeciesAssetPreview(asset: species.assets.first { $0.kind == .back }, rootPath: rootPath, size: 64)
            SpeciesAssetPreview(asset: species.assets.first { $0.kind == .footprint }, rootPath: rootPath, size: 40)
        }
    }

    private var validationState: ValidationState {
        let states = species.diagnostics.map { WorkbenchStore.validationState(for: $0.severity) }
        if states.contains(.error) {
            return .error
        }
        if states.contains(.warning) {
            return .warning
        }
        return species.isEditable ? .valid : .warning
    }

    private var baseStatTotal: Int {
        if let draft {
            return draft.baseStats.hp + draft.baseStats.attack + draft.baseStats.defense + draft.baseStats.speed + draft.baseStats.spAttack + draft.baseStats.spDefense
        }
        return species.baseStats.total ?? 0
    }

    private var evTotal: Int {
        draft?.evYield.total ?? species.evYield.total
    }

    private func heroMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
        }
    }
}

private struct SpeciesStatsGrid: View {
    let stats: PokemonHackCore.SpeciesBaseStats

    var body: some View {
        FactGrid(facts: [
            Fact(label: "HP", value: value(stats.hp)),
            Fact(label: "Attack", value: value(stats.attack)),
            Fact(label: "Defense", value: value(stats.defense)),
            Fact(label: "Speed", value: value(stats.speed)),
            Fact(label: "Sp. Attack", value: value(stats.spAttack)),
            Fact(label: "Sp. Defense", value: value(stats.spDefense)),
            Fact(label: "Total", value: value(stats.total))
        ])
    }

    private func value(_ int: Int?) -> String {
        int.map(String.init) ?? "Unknown"
    }
}

private struct SpeciesEVYieldGrid: View {
    let evYield: PokemonHackCore.SpeciesEVYield

    var body: some View {
        FactGrid(facts: [
            Fact(label: "HP", value: "\(evYield.hp)"),
            Fact(label: "Attack", value: "\(evYield.attack)"),
            Fact(label: "Defense", value: "\(evYield.defense)"),
            Fact(label: "Speed", value: "\(evYield.speed)"),
            Fact(label: "Sp. Attack", value: "\(evYield.spAttack)"),
            Fact(label: "Sp. Defense", value: "\(evYield.spDefense)"),
            Fact(label: "Total", value: "\(evYield.total)")
        ])
    }
}

private struct SpeciesConstantPicker: View {
    let title: String
    @Binding var selection: String
    let constants: [PokemonHackCore.SpeciesConstant]

    var body: some View {
        Picker(title, selection: $selection) {
            if !selection.isEmpty && !constants.contains(where: { $0.symbol == selection }) {
                Text(displayConstant(selection)).tag(selection)
            }
            ForEach(constants) { constant in
                Text(displayConstant(constant.symbol)).tag(constant.symbol)
            }
        }
        .pickerStyle(.menu)
        .help(selection)
    }
}

private struct SpeciesIntegerField: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                TextField(title, value: $value, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 70)
                Stepper(title, value: clampedBinding, in: range)
                    .labelsHidden()
            }
        }
    }

    private var clampedBinding: Binding<Int> {
        Binding(
            get: { min(max(value, range.lowerBound), range.upperBound) },
            set: { value = min(max($0, range.lowerBound), range.upperBound) }
        )
    }
}

private struct SpeciesTagCloud: View {
    let values: [String]

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                SpeciesTag(text: value)
            }
        }
    }
}

private struct SpeciesTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.secondary.opacity(0.12), in: Capsule())
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
    }
}

private struct SpeciesAssetTile: View {
    let asset: PokemonHackCore.SpeciesAsset
    let rootPath: String?
    let onOpenResource: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SpeciesAssetPreview(asset: asset, rootPath: rootPath, size: 64)

            HStack {
                Text(asset.kind.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                StatusPill(state: asset.exists ? .valid : .warning)
            }

            Button("Open Resource", systemImage: "arrow.uturn.left.circle") {
                onOpenResource()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .help("Open this asset in Resources")

            Text(asset.relativePath)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .textSelection(.enabled)
        }
        .padding(12)
        .background(.quaternary.opacity(0.24), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct SpeciesAssetPreview: View {
    let asset: PokemonHackCore.SpeciesAsset?
    let rootPath: String?
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.quaternary, lineWidth: 1)
                )

            if let image {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: size, height: size)
    }

    private var image: NSImage? {
        guard
            let asset,
            asset.exists,
            asset.relativePath.hasSuffix(".png"),
            let rootPath
        else {
            return nil
        }
        let path = URL(fileURLWithPath: rootPath).appendingPathComponent(asset.relativePath).standardizedFileURL.path
        return PokemonSpeciesImageCache.image(at: path)
    }
}

private struct SpeciesDiagnosticRow: View {
    let diagnostic: PokemonHackCore.Diagnostic

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            StatusPill(state: WorkbenchStore.validationState(for: diagnostic.severity))
            VStack(alignment: .leading, spacing: 4) {
                Text(diagnostic.code)
                    .font(.caption.weight(.semibold))
                Text(diagnostic.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let span = diagnostic.span {
                    SourceLocationView(source: SourceLocation(path: span.relativePath, symbol: diagnostic.code, line: span.startLine))
                }
            }
            Spacer()
        }
    }
}

@MainActor
private enum PokemonSpeciesImageCache {
    private static var cache: [String: NSImage] = [:]

    static func image(at path: String) -> NSImage? {
        if let image = cache[path] {
            return image
        }
        guard let image = NSImage(contentsOfFile: path), image.isValid else {
            return nil
        }
        cache[path] = image
        return image
    }
}

private func displayConstant(_ symbol: String) -> String {
    let prefixes = [
        "TRAINER_CLASS_",
        "TRAINER_PIC_",
        "TRAINER_ENCOUNTER_MUSIC_",
        "AI_SCRIPT_",
        "SPECIES_",
        "ABILITY_",
        "TYPE_",
        "EGG_GROUP_",
        "ITEM_",
        "MOVE_",
        "GROWTH_",
        "BODY_COLOR_",
        "EVO_"
    ]
    let trimmed = prefixes.reduce(symbol) { value, prefix in
        value.hasPrefix(prefix) ? String(value.dropFirst(prefix.count)) : value
    }
    let words = trimmed.split(separator: "_").map { part in
        part.lowercased().capitalized
    }
    return words.isEmpty ? symbol : words.joined(separator: " ")
}

private struct FlowLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(for: subviews, maxWidth: proposal.width ?? 600)
        return CGSize(width: proposal.width ?? rows.width, height: rows.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        let maxWidth = max(bounds.width, 1)

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.minX + maxWidth {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }

    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> (width: CGFloat, height: CGFloat) {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                usedWidth = max(usedWidth, x - spacing)
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        usedWidth = max(usedWidth, x - spacing)
        return (usedWidth, y + rowHeight)
    }
}
