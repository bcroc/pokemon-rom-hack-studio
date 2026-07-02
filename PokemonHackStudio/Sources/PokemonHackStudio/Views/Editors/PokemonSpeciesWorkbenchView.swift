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
    let onFocusSpecies: (String) -> Void
    let onImportAsset: (PokemonHackCore.SpeciesAssetKind, URL) -> Void
    let assetImportBlockedReason: (PokemonHackCore.SpeciesAssetKind) -> String?
    let cryAudioSources: [PokemonHackCore.GBACryAudioSourceFile]
    let onImportCryAudioSource: (PokemonHackCore.GBACryAudioSourceFile, URL) -> Void
    let cryAudioImportBlockedReason: (PokemonHackCore.GBACryAudioSourceFile) -> String?
    let onNavigateToResourceAsset: (String) -> Void

    @State private var sourceExpanded = false

    var body: some View {
        Group {
            if catalog != nil {
                GeometryReader { proxy in
                    let layoutMode = WorkbenchLayoutMode(contentWidth: proxy.size.width)
                    speciesDetail(layoutMode: layoutMode)
                        .frame(minWidth: 560, maxWidth: .infinity, maxHeight: .infinity)
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
        .onAppear {
            guard catalog == nil else { return }
            DispatchQueue.main.async {
                onLoadCatalog()
            }
        }
        .navigationTitle("Pokemon")
    }

    @ViewBuilder
    private func speciesDetail(layoutMode: WorkbenchLayoutMode) -> some View {
        if let selectedSpecies {
            if let draft {
                ScrollView {
                    VStack(alignment: .leading, spacing: layoutMode.sectionSpacing) {
                        speciesSwitcher(selectedSpecies)
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

                        if supportsLevelUpEditing(for: selectedSpecies) {
                            levelUpSection(draft: draft)
                        }
                        if supportsEvolutionEditing(for: selectedSpecies) {
                            evolutionSection(draft: draft)
                        }
                        if supportsFormsEditing(for: selectedSpecies) {
                            formsSection(draft: draft)
                        }
                        if supportsTMHMEditing(for: selectedSpecies) {
                            tmhmSection(draft: draft)
                        }
                        if supportsTutorEditing(for: selectedSpecies) {
                            tutorSection(draft: draft)
                        }
                        if supportsClassicSpeciesMutationEditing {
                            eggMovesSection(draft: draft)
                        }
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
                    SpeciesPresetPicker(title: "Gender", selection: draftStringBinding(\.genderRatio), options: genderRatioOptions)
                    speciesTextField("Egg Cycles", text: draftStringBinding(\.eggCycles))
                    SpeciesPresetPicker(title: "Friendship", selection: draftStringBinding(\.friendship), options: friendshipOptions)
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

    private func formsSection(draft: PokemonHackCore.SpeciesEditDraft) -> some View {
        EditorSection(title: "Forms") {
            VStack(alignment: .leading, spacing: 14) {
                if !draft.formSpecies.isEmpty {
                    Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 8) {
                        GridRow {
                            Text("Slot").foregroundStyle(.secondary)
                            Text("Species").foregroundStyle(.secondary)
                        }
                        .font(.caption.weight(.semibold))

                        ForEach(draft.formSpecies) { row in
                            GridRow {
                                Text("\(row.slot + 1)")
                                    .foregroundStyle(.secondary)
                                SpeciesConstantPicker(title: "Form Species", selection: formSpeciesBinding(slot: row.slot), constants: constants(.species))
                                    .labelsHidden()
                            }
                        }
                    }
                }

                if !draft.formChanges.isEmpty {
                    Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 8) {
                        GridRow {
                            Text("Change").foregroundStyle(.secondary)
                            Text("Target").foregroundStyle(.secondary)
                        }
                        .font(.caption.weight(.semibold))

                        ForEach(draft.formChanges) { row in
                            GridRow {
                                SpeciesConstantPicker(title: "Change", selection: formChangeMethodBinding(index: row.index), constants: constants(.formChangeMethods))
                                    .labelsHidden()
                                SpeciesConstantPicker(title: "Target", selection: formChangeTargetBinding(index: row.index), constants: constants(.species))
                                    .labelsHidden()
                            }
                        }
                    }
                }
            }
        }
    }

    private func tutorSection(draft: PokemonHackCore.SpeciesEditDraft) -> some View {
        EditorSection(title: "Tutor Moves") {
            let moves = constants(.tutorMoves)
            if moves.isEmpty {
                Text("No tutor move constants were indexed for this project.")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 10)], alignment: .leading, spacing: 8) {
                    ForEach(moves) { move in
                        Toggle(displayConstant(move.symbol), isOn: tutorBinding(move.symbol))
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
                    pokedexSection(for: species)
                    sourceSection(for: species)
                }
            }
        }
    }

    private func evolutionSection(draft: PokemonHackCore.SpeciesEditDraft) -> some View {
        EditorSection(title: "Evolutions") {
            VStack(alignment: .leading, spacing: 12) {
                let canEditRows = supportsEvolutionRowStructureEditing
                HStack {
                    Text("\(draft.evolutions.count) rows")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if canEditRows {
                        Button("Add Evolution", systemImage: "plus") {
                            addEvolution()
                        }
                    }
                }

                if draft.evolutions.isEmpty {
                    Text("No evolutions defined.")
                        .foregroundStyle(.secondary)
                } else {
                    Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 8) {
                        GridRow {
                            Text("Method").foregroundStyle(.secondary)
                            Text("Parameter").foregroundStyle(.secondary)
                            Text("Target").foregroundStyle(.secondary)
                            Text("").accessibilityHidden(true)
                        }
                        .font(.caption.weight(.semibold))

                        ForEach(Array(draft.evolutions.enumerated()), id: \.element.id) { index, evolution in
                            GridRow {
                                SpeciesConstantPicker(title: "Method", selection: evolutionMethodBinding(id: evolution.id), constants: constants(.evolutionMethods))
                                    .labelsHidden()

                                evolutionParameterField(evolution: evolution)

                                SearchableConstantPicker(title: "Target", selection: evolutionTargetBinding(id: evolution.id), constants: catalogSpeciesConstants)
                                    .labelsHidden()

                                if canEditRows {
                                    moveControls(
                                        canMoveUp: index > 0,
                                        canMoveDown: index < draft.evolutions.count - 1,
                                        onMoveUp: { moveEvolution(id: evolution.id, offset: -1) },
                                        onMoveDown: { moveEvolution(id: evolution.id, offset: 1) },
                                        onRemove: { removeEvolution(id: evolution.id) }
                                    )
                                } else {
                                    Text("")
                                        .frame(width: 72)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func evolutionParameterField(evolution: PokemonHackCore.SpeciesEvolutionDraft) -> some View {
        if itemParameterEvolutionMethods.contains(evolution.method) {
            SearchableConstantPicker(title: "Item", selection: evolutionParameterBinding(id: evolution.id), constants: constants(.items))
                .labelsHidden()
        } else if zeroParameterEvolutionMethods.contains(evolution.method) {
            Text("0")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .frame(minWidth: 40)
        } else {
            SpeciesIntegerField(title: "Param", value: evolutionParameterIntBinding(id: evolution.id), range: 0...65535)
                .labelsHidden()
                .frame(width: 60)
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
                                    onFocusSpecies(evolution.targetSpecies)
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
            if supportsPokedexEditing(for: species), let draft = draft, draft.pokedex != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                        GridRow {
                            Text("Category")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("WOOD GECKO", text: pokedexCategoryBinding)
                                .textFieldStyle(.roundedBorder)
                        }
                        GridRow {
                            Text("Height")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("5", text: pokedexHeightBinding)
                                .textFieldStyle(.roundedBorder)
                        }
                        GridRow {
                            Text("Weight")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("50", text: pokedexWeightBinding)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: pokedexDescriptionBinding)
                            .frame(minHeight: 100)
                            .padding(4)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.2)))
                            .font(.system(.body, design: .monospaced))
                    }

                    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                        GridRow {
                            Text("Pokemon Scale")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("256", text: pokedexPokemonScaleBinding)
                                .textFieldStyle(.roundedBorder)
                            Text("Offset")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("0", text: pokedexPokemonOffsetBinding)
                                .textFieldStyle(.roundedBorder)
                        }
                        GridRow {
                            Text("Trainer Scale")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("256", text: pokedexTrainerScaleBinding)
                                .textFieldStyle(.roundedBorder)
                            Text("Offset")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("0", text: pokedexTrainerOffsetBinding)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    if let pokedex = species.pokedex {
                        SourceLocationView(source: sourceLocation(pokedex.sourceSpan, symbol: species.speciesID))
                    }
                }
            } else if let pokedex = species.pokedex {
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
        VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], alignment: .leading, spacing: 12) {
                ForEach(species.assets) { asset in
                    SpeciesAssetTile(
                        asset: asset,
                        rootPath: rootPath,
                        draftData: draft?.assetData[asset.kind],
                        importProvenance: draft?.assetImports[asset.kind],
                        importBlockedReason: assetImportBlockedReason(asset.kind),
                        onOpenResource: {
                            onNavigateToResourceAsset(asset.relativePath)
                        },
                        onImport: {
                            importAsset(kind: asset.kind)
                        }
                    )
                }
            }

            if !cryAudioSources.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cry Audio Sources")
                        .font(.subheadline.weight(.semibold))
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], alignment: .leading, spacing: 12) {
                        ForEach(cryAudioSources, id: \.path) { source in
                            SpeciesCryAudioSourceTile(
                                source: source,
                                replacement: draft?.cryAudioReplacements?[source.path],
                                importBlockedReason: cryAudioImportBlockedReason(source),
                                onImport: {
                                    importCryAudioSource(source)
                                }
                            )
                        }
                    }
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
                speciesSwitcher(species)
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

    private var genderRatioOptions: [SpeciesPresetOption] {
        [
            SpeciesPresetOption(label: "Male Only", value: "MON_MALE"),
            SpeciesPresetOption(label: "12.5% Female", value: "PERCENT_FEMALE(12.5)"),
            SpeciesPresetOption(label: "25% Female", value: "PERCENT_FEMALE(25)"),
            SpeciesPresetOption(label: "50% Female", value: "PERCENT_FEMALE(50)"),
            SpeciesPresetOption(label: "75% Female", value: "PERCENT_FEMALE(75)"),
            SpeciesPresetOption(label: "Female Only", value: "MON_FEMALE"),
            SpeciesPresetOption(label: "Genderless", value: "MON_GENDERLESS")
        ]
    }

    private var friendshipOptions: [SpeciesPresetOption] {
        var options = [
            SpeciesPresetOption(label: "0", value: "0"),
            SpeciesPresetOption(label: "35", value: "35"),
            SpeciesPresetOption(label: "70", value: "70"),
            SpeciesPresetOption(label: "90", value: "90"),
            SpeciesPresetOption(label: "100", value: "100"),
            SpeciesPresetOption(label: "140", value: "140")
        ]
        if usesStandardFriendshipPreset {
            options.insert(SpeciesPresetOption(label: "Standard (70)", value: "STANDARD_FRIENDSHIP"), at: 0)
        }
        return options
    }

    private var usesStandardFriendshipPreset: Bool {
        switch catalog?.profile {
        case .pokeemerald, .pokeemeraldExpansion:
            return true
        default:
            return false
        }
    }

    private var supportsClassicSpeciesMutationEditing: Bool {
        switch catalog?.profile {
        case .pokeemerald, .pokefirered:
            return true
        default:
            return false
        }
    }

    private func supportsPokedexEditing(for species: PokemonHackCore.SpeciesDetail) -> Bool {
        switch catalog?.profile {
        case .pokeemerald, .pokefirered, .pokeruby:
            return true
        case .pokeemeraldExpansion:
            return species.pokedex?.sourceSpan.relativePath == "src/data/pokemon/pokedex_entries.h"
                && species.pokedex?.descriptionSpan?.relativePath == "src/data/pokemon/pokedex_text.h"
        default:
            return false
        }
    }

    private func supportsTMHMEditing(for species: PokemonHackCore.SpeciesDetail) -> Bool {
        switch catalog?.profile {
        case .pokeemerald, .pokefirered:
            return true
        case .pokeruby:
            return species.learnsets.tmhmSourceSpan?.relativePath == "src/data/pokemon/tmhm_learnsets.h"
        case .pokeemeraldExpansion:
            return species.learnsets.tmhmSourceSpan?.relativePath == "src/data/pokemon/tmhm_learnsets.h"
        default:
            return false
        }
    }

    private func supportsEvolutionEditing(for species: PokemonHackCore.SpeciesDetail) -> Bool {
        switch catalog?.profile {
        case .pokeemerald, .pokefirered:
            return true
        case .pokeruby:
            return species.evolutions.contains { $0.sourceSpan.relativePath == "src/data/pokemon/evolution.h" }
        case .pokeemeraldExpansion:
            return species.evolutions.contains { $0.sourceSpan.relativePath == "src/data/pokemon/evolution.h" }
        default:
            return false
        }
    }

    private var supportsEvolutionRowStructureEditing: Bool {
        switch catalog?.profile {
        case .pokeemerald, .pokefirered, .pokeruby:
            return true
        default:
            return false
        }
    }

    private func supportsFormsEditing(for species: PokemonHackCore.SpeciesDetail) -> Bool {
        catalog?.profile == .pokeemeraldExpansion && species.forms.hasEditableRows
    }

    private func supportsLevelUpEditing(for species: PokemonHackCore.SpeciesDetail) -> Bool {
        switch catalog?.profile {
        case .pokeemerald, .pokefirered:
            return true
        case .pokeruby:
            return species.learnsets.levelUpSourceSpan?.relativePath == "src/data/pokemon/level_up_learnsets.h"
        case .pokeemeraldExpansion:
            guard let path = species.learnsets.levelUpSourceSpan?.relativePath else { return false }
            return path == "src/data/pokemon/level_up_learnsets.h"
                || path.hasPrefix("src/data/pokemon/level_up_learnsets/")
        default:
            return false
        }
    }

    private func supportsTutorEditing(for species: PokemonHackCore.SpeciesDetail) -> Bool {
        switch catalog?.profile {
        case .pokeemerald, .pokefirered:
            return true
        case .pokeruby:
            return species.learnsets.tutorSourceSpan?.relativePath == "src/data/pokemon/tutor_learnsets.h"
        case .pokeemeraldExpansion:
            return species.learnsets.tutorSourceSpan?.relativePath == "src/data/pokemon/tutor_learnsets.h"
        default:
            return false
        }
    }

    private func speciesSwitcher(_ selected: PokemonHackCore.SpeciesDetail) -> some View {
        EditorRecordSwitcher(
            title: "Switch Pokemon",
            selectedTitle: selected.displayName,
            selectedSubtitle: selected.speciesID,
            systemImage: WorkbenchModule.pokemon.systemImage,
            items: (catalog?.species ?? species).map(speciesSwitcherItem),
            selectedID: selectedSpeciesID,
            emptyTitle: "No Pokemon",
            emptyDescription: "No Pokemon matched the current search.",
            onSelect: { selectedSpeciesID = $0 }
        )
    }

    private func speciesSwitcherItem(_ species: PokemonHackCore.SpeciesDetail) -> EditorRecordSwitcherItem {
        EditorRecordSwitcherItem(
            id: species.speciesID,
            title: species.displayName,
            subtitle: species.speciesID,
            detail: species.types.map(displayConstant).joined(separator: " / "),
            systemImage: WorkbenchModule.pokemon.systemImage,
            status: validationState(for: species.diagnostics),
            searchText: [
                species.displayName,
                species.speciesID,
                species.sourceSpan.relativePath,
                species.types.joined(separator: " "),
                species.abilities.joined(separator: " "),
                species.pokedex?.categoryName ?? ""
            ].joined(separator: " ")
        )
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

    private func formSpeciesBinding(slot: Int) -> Binding<String> {
        Binding(
            get: { draft?.formSpecies.first(where: { $0.slot == slot })?.speciesID ?? "SPECIES_NONE" },
            set: { value in
                updateDraft { draft in
                    guard let index = draft.formSpecies.firstIndex(where: { $0.slot == slot }) else { return }
                    draft.formSpecies[index].speciesID = value
                }
            }
        )
    }

    private func formChangeMethodBinding(index: Int) -> Binding<String> {
        Binding(
            get: { draft?.formChanges.first(where: { $0.index == index })?.method ?? "FORM_CHANGE_BATTLE_MEGA_EVOLUTION" },
            set: { value in
                updateDraft { draft in
                    guard let rowIndex = draft.formChanges.firstIndex(where: { $0.index == index }) else { return }
                    draft.formChanges[rowIndex].method = value
                }
            }
        )
    }

    private func formChangeTargetBinding(index: Int) -> Binding<String> {
        Binding(
            get: { draft?.formChanges.first(where: { $0.index == index })?.targetSpecies ?? "SPECIES_NONE" },
            set: { value in
                updateDraft { draft in
                    guard let rowIndex = draft.formChanges.firstIndex(where: { $0.index == index }) else { return }
                    draft.formChanges[rowIndex].targetSpecies = value
                }
            }
        )
    }

    private func tmhmBinding(_ move: String) -> Binding<Bool> {
        Binding(
            get: { draft?.tmhmMoves.contains(move) ?? false },
            set: { isOn in
                updateDraft { draft in
                    if isOn {
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

    private func tutorBinding(_ move: String) -> Binding<Bool> {
        Binding(
            get: { draft?.tutorMoves.contains(move) ?? false },
            set: { isOn in
                updateDraft { draft in
                    if isOn {
                        if !draft.tutorMoves.contains(move) {
                            draft.tutorMoves.append(move)
                            draft.tutorMoves.sort()
                        }
                    } else {
                        draft.tutorMoves.removeAll { $0 == move }
                    }
                }
            }
        )
    }

    private var pokedexCategoryBinding: Binding<String> {
        Binding(
            get: { draft?.pokedex?.categoryName ?? "" },
            set: { value in updateDraft { $0.pokedex?.categoryName = value } }
        )
    }

    private var pokedexHeightBinding: Binding<String> {
        Binding(
            get: { draft?.pokedex?.height ?? "0" },
            set: { value in updateDraft { $0.pokedex?.height = value } }
        )
    }

    private var pokedexWeightBinding: Binding<String> {
        Binding(
            get: { draft?.pokedex?.weight ?? "0" },
            set: { value in updateDraft { $0.pokedex?.weight = value } }
        )
    }

    private var pokedexDescriptionBinding: Binding<String> {
        Binding(
            get: { draft?.pokedex?.description ?? "" },
            set: { value in updateDraft { $0.pokedex?.description = value } }
        )
    }

    private var pokedexPokemonScaleBinding: Binding<String> {
        Binding(
            get: { draft?.pokedex?.pokemonScale ?? "256" },
            set: { value in updateDraft { $0.pokedex?.pokemonScale = value } }
        )
    }

    private var pokedexPokemonOffsetBinding: Binding<String> {
        Binding(
            get: { draft?.pokedex?.pokemonOffset ?? "0" },
            set: { value in updateDraft { $0.pokedex?.pokemonOffset = value } }
        )
    }

    private var pokedexTrainerScaleBinding: Binding<String> {
        Binding(
            get: { draft?.pokedex?.trainerScale ?? "256" },
            set: { value in updateDraft { $0.pokedex?.trainerScale = value } }
        )
    }

    private var pokedexTrainerOffsetBinding: Binding<String> {
        Binding(
            get: { draft?.pokedex?.trainerOffset ?? "0" },
            set: { value in updateDraft { $0.pokedex?.trainerOffset = value } }
        )
    }

    private func importAsset(kind: PokemonHackCore.SpeciesAssetKind) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedFileTypes = kind.isSpriteAsset ? ["png"] : ["pal", "gbapal"]
        panel.message = kind.isSpriteAsset
            ? "Select a replacement \(kind.title) sprite PNG"
            : "Select a replacement \(kind.title) palette"

        if panel.runModal() == .OK, let url = panel.url {
            onImportAsset(kind, url)
        }
    }

    private func importCryAudioSource(_ source: PokemonHackCore.GBACryAudioSourceFile) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        let targetExtension = URL(fileURLWithPath: source.path).pathExtension
        if !targetExtension.isEmpty {
            panel.allowedFileTypes = [targetExtension]
        }
        panel.message = "Select a one-for-one replacement for \(source.path)"

        if panel.runModal() == .OK, let url = panel.url {
            onImportCryAudioSource(source, url)
        }
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

    private func evolutionMethodBinding(id: String) -> Binding<String> {
        Binding(
            get: { draft?.evolutions.first(where: { $0.id == id })?.method ?? "EVO_LEVEL" },
            set: { value in
                updateDraft { draft in
                    guard let index = draft.evolutions.firstIndex(where: { $0.id == id }) else { return }
                    draft.evolutions[index].method = value
                    if zeroParameterEvolutionMethods.contains(value) {
                        draft.evolutions[index].parameter = "0"
                    } else if itemParameterEvolutionMethods.contains(value), !draft.evolutions[index].parameter.hasPrefix("ITEM_") {
                        draft.evolutions[index].parameter = constants(.items).first?.symbol ?? "ITEM_NONE"
                    }
                }
            }
        )
    }

    private func evolutionParameterBinding(id: String) -> Binding<String> {
        Binding(
            get: { draft?.evolutions.first(where: { $0.id == id })?.parameter ?? "0" },
            set: { value in
                updateDraft { draft in
                    guard let index = draft.evolutions.firstIndex(where: { $0.id == id }) else { return }
                    draft.evolutions[index].parameter = value
                }
            }
        )
    }

    private func evolutionParameterIntBinding(id: String) -> Binding<Int> {
        Binding(
            get: { Int(draft?.evolutions.first(where: { $0.id == id })?.parameter ?? "0") ?? 0 },
            set: { value in
                updateDraft { draft in
                    guard let index = draft.evolutions.firstIndex(where: { $0.id == id }) else { return }
                    draft.evolutions[index].parameter = "\(value)"
                }
            }
        )
    }

    private func evolutionTargetBinding(id: String) -> Binding<String> {
        Binding(
            get: { draft?.evolutions.first(where: { $0.id == id })?.targetSpecies ?? "SPECIES_NONE" },
            set: { value in
                updateDraft { draft in
                    guard let index = draft.evolutions.firstIndex(where: { $0.id == id }) else { return }
                    draft.evolutions[index].targetSpecies = value
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

    private func addEvolution() {
        updateDraft { draft in
            guard draft.evolutions.count < 5 else { return }
            draft.evolutions.append(PokemonHackCore.SpeciesEvolutionDraft(method: "EVO_LEVEL", parameter: "1", targetSpecies: "SPECIES_NONE"))
        }
    }

    private func removeEvolution(id: String) {
        updateDraft { draft in
            draft.evolutions.removeAll { $0.id == id }
        }
    }

    private func moveEvolution(id: String, offset: Int) {
        updateDraft { draft in
            guard let index = draft.evolutions.firstIndex(where: { $0.id == id }) else { return }
            let target = index + offset
            guard draft.evolutions.indices.contains(target) else { return }
            draft.evolutions.swapAt(index, target)
        }
    }

    private var defaultMove: String {
        if constants(.moves).contains(where: { $0.symbol == "MOVE_TACKLE" }) {
            return "MOVE_TACKLE"
        }
        return constants(.moves).first { $0.symbol != "MOVE_NONE" }?.symbol ?? "MOVE_NONE"
    }

    private var catalogSpeciesConstants: [PokemonHackCore.SpeciesConstant] {
        catalog?.species.map { detail in
            PokemonHackCore.SpeciesConstant(
                group: .moves, // Reusing move constant type as a shim for species in the picker
                symbol: detail.speciesID,
                value: "0",
                sourceSpan: detail.sourceSpan
            )
        } ?? []
    }

    private var itemParameterEvolutionMethods: Set<String> {
        ["EVO_ITEM", "EVO_TRADE_ITEM"]
    }

    private var zeroParameterEvolutionMethods: Set<String> {
        ["EVO_FRIENDSHIP", "EVO_FRIENDSHIP_DAY", "EVO_FRIENDSHIP_NIGHT", "EVO_TRADE"]
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
            draftData: draft?.assetData[.front],
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
            heroMetric(title: "Tutor", value: "\(draft?.tutorMoves.count ?? species.learnsets.tutor.count)")
            heroMetric(title: "Egg", value: "\(draft?.eggMoves.count ?? species.learnsets.egg.count)")
        }
    }

    private var secondaryPreviews: some View {
        VStack(spacing: 10) {
            SpeciesAssetPreview(
                asset: species.assets.first { $0.kind == .back },
                rootPath: rootPath,
                draftData: draft?.assetData[.back],
                size: 64
            )
            SpeciesAssetPreview(
                asset: species.assets.first { $0.kind == .footprint },
                rootPath: rootPath,
                draftData: draft?.assetData[.footprint],
                size: 40
            )
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

private struct SpeciesPresetOption: Identifiable {
    var id: String { value }

    let label: String
    let value: String
}

private struct SpeciesPresetPicker: View {
    let title: String
    @Binding var selection: String
    let options: [SpeciesPresetOption]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Picker(title, selection: $selection) {
                if !selection.isEmpty && !options.contains(where: { $0.value == selection }) {
                    Text(displayConstant(selection)).tag(selection)
                }
                ForEach(options) { option in
                    Text(option.label).tag(option.value)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .help(selection)
        }
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
    let draftData: Data?
    let importProvenance: PokemonHackCore.SpeciesAssetImportProvenance?
    let importBlockedReason: String?
    let onOpenResource: () -> Void
    let onImport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SpeciesAssetPreview(asset: asset, rootPath: rootPath, draftData: draftData, size: 64)

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

            Button("Import...", systemImage: "square.and.arrow.down") {
                onImport()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(importBlockedReason != nil)
            .help(importBlockedReason ?? "Import stages draft bytes only; preview the mutation plan before apply.")

            if let importBlockedReason {
                Text(importBlockedReason)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let draftData {
                Text("Draft staged: \(draftData.count) bytes. Preview mutations to validate asset policy.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let importProvenance {
                SpeciesAssetImportProvenanceView(provenance: importProvenance)
            }

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

private struct SpeciesCryAudioSourceTile: View {
    let source: PokemonHackCore.GBACryAudioSourceFile
    let replacement: PokemonHackCore.GBACryAudioReplacementDraft?
    let importBlockedReason: String?
    let onImport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(source.kind)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                StatusPill(state: replacement == nil ? .warning : replacementState)
            }

            Button("Import...", systemImage: "square.and.arrow.down") {
                onImport()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(importBlockedReason != nil)
            .help(importBlockedReason ?? "Import stages a one-for-one cry/audio replacement for mutation review.")

            if let importBlockedReason {
                Text(importBlockedReason)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("\(source.sizeBytes) bytes · SHA1 \(source.sha1)")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)

            if let replacement {
                Text("Draft staged: \(replacement.replacementSizeBytes) bytes · SHA1 \(replacement.replacementSHA1)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                Text("Validation \(replacement.status.rawValue).")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(source.path)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .textSelection(.enabled)
        }
        .padding(12)
        .background(.quaternary.opacity(0.24), in: RoundedRectangle(cornerRadius: 8))
    }

    private var replacementState: ValidationState {
        switch replacement?.status {
        case .ready:
            return .valid
        case .blocked:
            return .error
        case nil:
            return .warning
        }
    }
}

private struct SpeciesAssetImportProvenanceView: View {
    let provenance: PokemonHackCore.SpeciesAssetImportProvenance

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                StatusPill(state: validationState)
                Text("\(provenance.sourceFileName) · \(provenance.byteCount) bytes")
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            }
            Text("SHA1 \(provenance.sha1)")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
            Text("Detected \(provenance.detectedKind.rawValue); validation \(provenance.status.rawValue).")
                .font(.caption2)
                .foregroundStyle(.secondary)
            if let png = provenance.pngMetadata {
                Text("PNG \(png.width)x\(png.height); palette \(png.paletteColorCount.map(String.init) ?? "unverified").")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if let palette = provenance.paletteMetadata {
                Text("Palette \(palette.format), \(palette.colorCount) colors.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            ForEach(provenance.diagnostics.prefix(2)) { diagnostic in
                Text(diagnostic.message)
                    .font(.caption2)
                    .foregroundStyle(diagnostic.severity == .error ? .red : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var validationState: ValidationState {
        switch provenance.status {
        case .ready:
            return .valid
        case .warning:
            return .warning
        case .blocked:
            return .error
        }
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
