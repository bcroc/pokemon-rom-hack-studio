import PokemonHackCore
import SwiftUI

struct TrainerEditorView: View {
    let catalog: PokemonHackCore.ProjectTrainerCatalog?
    let trainers: [PokemonHackCore.TrainerDetail]
    @Binding var selectedTrainerID: String
    let selectedTrainer: PokemonHackCore.TrainerDetail?
    let draft: PokemonHackCore.TrainerEditDraft?
    let isDirty: Bool
    let rootPath: String?
    let loadStatus: TrainerCatalogLoadStatus
    let fallbackRecords: [WorkbenchRecord]
    let speciesCatalog: PokemonHackCore.ProjectSpeciesCatalog?
    let onLoadCatalog: () -> Void
    let onSelectTrainer: (String) -> Void
    let onUpdateDraft: (PokemonHackCore.TrainerEditDraft) -> Void
    var onFocusSpecies: ((String) -> Void)? = nil

    @State private var selectedPartySlot = 0
    @State private var showCompactBrowser = false
    @State private var sourceExpanded = false

    var body: some View {
        Group {
            if catalog != nil {
                GeometryReader { proxy in
                    let layoutMode = WorkbenchLayoutMode(contentWidth: proxy.size.width)
                    trainerDetail(layoutMode: layoutMode)
                        .frame(minWidth: 560, maxWidth: .infinity, maxHeight: .infinity)
                }
            } else if !fallbackRecords.isEmpty {
                EditorListShell(title: "Trainers", records: fallbackRecords) { record in
                    EditorSection(title: "Trainer Definition") {
                        FactGrid(facts: record.facts)
                    }

                    SourcePreviewBlock(text: record.preview)
                    NotesList(notes: record.notes)
                }
            } else {
                ContentUnavailableView(
                    "No Trainer Catalog",
                    systemImage: "person.2",
                    description: Text(loadStatus.label)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear(perform: onLoadCatalog)
        .onChange(of: selectedTrainerID) { _, newValue in
            selectedPartySlot = 0
            showCompactBrowser = false
            sourceExpanded = false
            onSelectTrainer(newValue)
        }
    }

    private func compactWorkbench(
        catalog: PokemonHackCore.ProjectTrainerCatalog,
        layoutMode: WorkbenchLayoutMode
    ) -> some View {
        VStack(spacing: 0) {
            compactBrowserBar(catalog: catalog)
            Divider()
            trainerDetail(layoutMode: layoutMode)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func compactBrowserBar(catalog: PokemonHackCore.ProjectTrainerCatalog) -> some View {
        HStack(spacing: 10) {
            Button("Trainers", systemImage: "sidebar.left") {
                showCompactBrowser.toggle()
            }
            .help("Open trainer browser")
            .popover(isPresented: $showCompactBrowser, arrowEdge: .bottom) {
                trainerBrowser(catalog: catalog)
                    .frame(
                        width: WorkbenchLayoutMode.compactPopoverWidth,
                        height: WorkbenchLayoutMode.compactPopoverHeight
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(selectedTrainer?.displayName ?? "No Trainer Selected")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("\(trainers.count) of \(catalog.trainerCount)")
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

    private func trainerBrowser(catalog: PokemonHackCore.ProjectTrainerCatalog) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Trainers")
                        .font(.headline)
                    Text("\(trainers.count) of \(catalog.trainerCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                StatusPill(state: validationState(for: catalog.diagnostics))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            if trainers.isEmpty {
                ContentUnavailableView(
                    "No Trainers",
                    systemImage: "magnifyingglass",
                    description: Text("No trainer rows matched the current search.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedTrainerID) {
                    ForEach(trainers) { trainer in
                        TrainerBrowserRow(trainer: trainer)
                            .tag(trainer.trainerID)
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }

    @ViewBuilder
    private func trainerDetail(layoutMode: WorkbenchLayoutMode) -> some View {
        if let trainer = selectedTrainer {
            if let draft {
                ScrollView {
                    VStack(alignment: .leading, spacing: layoutMode.sectionSpacing) {
                        trainerHeader(trainer: trainer, draft: draft)

                        if layoutMode.isCompact {
                            VStack(alignment: .leading, spacing: layoutMode.sectionSpacing) {
                                battleSettingsSection(draft: draft)
                                trainerItemsSection(draft: draft)
                            }
                        } else {
                            HStack(alignment: .top, spacing: 18) {
                                battleSettingsSection(draft: draft)
                                trainerItemsSection(draft: draft)
                            }
                        }

                        aiFlagsSection(draft: draft)
                        partySection(trainer: trainer, draft: draft, layoutMode: layoutMode)
                        sourceSection(trainer: trainer, layoutMode: layoutMode)
                        diagnosticsSection(trainer: trainer)
                    }
                    .padding(layoutMode.contentPadding)
                }
            } else {
                readOnlyDetail(trainer: trainer, layoutMode: layoutMode)
            }
        } else {
            ContentUnavailableView(
                "No Trainer Selected",
                systemImage: "sidebar.left",
                description: Text("Select a trainer to inspect battle setup and party data.")
            )
        }
    }

    private func trainerHeader(
        trainer: PokemonHackCore.TrainerDetail,
        draft: PokemonHackCore.TrainerEditDraft
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trainer.displayName)
                        .font(.title2.weight(.semibold))
                    Text(trainer.trainerID)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                Spacer()

                if isDirty {
                    DirtyPill(isDirty: true)
                }

                StatusPill(state: validationState(for: trainer.diagnostics))
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 8)], alignment: .leading, spacing: 8) {
                TrainerTag(text: draft.partyShape.macroName)
                TrainerTag(text: "\(draft.party.count) Pokemon")
                TrainerTag(text: draft.doubleBattle ? "Double battle" : "Single battle")
                TrainerTag(text: draft.aiFlags.isEmpty ? "No AI flags" : "\(draft.aiFlags.count) AI flags")
            }
        }
    }

    private func battleSettingsSection(draft: PokemonHackCore.TrainerEditDraft) -> some View {
        EditorSection(title: "Battle Settings") {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Trainer name", text: draftStringBinding(\.trainerName, fallback: draft.trainerName))
                    .textFieldStyle(.roundedBorder)

                SearchableConstantPicker(
                    title: "Class",
                    selection: draftStringBinding(\.trainerClass, fallback: draft.trainerClass),
                    constants: constants(.trainerClasses)
                )

                SearchableConstantPicker(
                    title: "Pic",
                    selection: draftStringBinding(\.trainerPic, fallback: draft.trainerPic),
                    constants: constants(.trainerPics)
                )

                SearchableConstantPicker(
                    title: "Encounter Music",
                    selection: draftStringBinding(\.encounterMusicGender, fallback: draft.encounterMusicGender),
                    constants: constants(.encounterMusic)
                )

                Toggle("Double battle", isOn: draftBoolBinding(\.doubleBattle, fallback: draft.doubleBattle))
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func trainerItemsSection(draft: PokemonHackCore.TrainerEditDraft) -> some View {
        EditorSection(title: "Trainer Items") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Uses bag items", isOn: trainerItemsEnabledBinding)

                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
                    ForEach(0..<4, id: \.self) { index in
                        GridRow {
                            Text("Item \(index + 1)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                            SearchableConstantPicker(
                                title: "Item \(index + 1)",
                                selection: trainerItemBinding(index: index),
                                constants: constants(.items)
                            )
                            .labelsHidden()
                            .disabled(!trainerItemsEnabledBinding.wrappedValue)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func aiFlagsSection(draft: PokemonHackCore.TrainerEditDraft) -> some View {
        EditorSection(title: "AI Flags") {
            let flags = aiFlagSymbols(for: draft)
            if flags.isEmpty {
                Text("No AI flag constants were indexed for this project.")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], alignment: .leading, spacing: 10) {
                    ForEach(flags, id: \.self) { flag in
                        Toggle(displayConstant(flag), isOn: aiFlagBinding(flag))
                            .toggleStyle(.checkbox)
                            .help(flag)
                    }
                }
            }
        }
    }

    private func partySection(
        trainer: PokemonHackCore.TrainerDetail,
        draft: PokemonHackCore.TrainerEditDraft,
        layoutMode: WorkbenchLayoutMode
    ) -> some View {
        EditorSection(title: "Party") {
            VStack(alignment: .leading, spacing: 14) {
                ViewThatFits(in: .horizontal) {
                    partyActionRow(draft: draft)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 18) {
                            Toggle("Held items", isOn: heldItemsEnabledBinding)
                            Toggle("Custom moves", isOn: customMovesEnabledBinding)
                        }
                        HStack(spacing: 10) {
                            partyButtons(draft: draft)
                        }
                    }
                }

                if layoutMode.isCompact {
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(draft.party) { member in
                                TrainerPartyRow(
                                    member: member,
                                    shape: draft.partyShape,
                                    isSelected: member.slot == selectedPartySlot,
                                    species: speciesCatalog?.species.first { $0.speciesID == member.species },
                                    rootPath: rootPath
                                ) {
                                    selectedPartySlot = member.slot
                                }
                                .frame(width: 220)
                            }
                        }
                        .padding(.bottom, 2)
                    }

                    partyDetail(trainer: trainer, draft: draft)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                } else {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 8) {
                            ForEach(draft.party) { member in
                                TrainerPartyRow(
                                    member: member,
                                    shape: draft.partyShape,
                                    isSelected: member.slot == selectedPartySlot,
                                    species: speciesCatalog?.species.first { $0.speciesID == member.species },
                                    rootPath: rootPath
                                ) {
                                    selectedPartySlot = member.slot
                                }
                            }
                        }
                        .frame(width: 250, alignment: .topLeading)

                        Divider()

                        partyDetail(trainer: trainer, draft: draft)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
            }
        }
    }

    private func partyActionRow(draft: PokemonHackCore.TrainerEditDraft) -> some View {
        HStack(spacing: 18) {
            Toggle("Held items", isOn: heldItemsEnabledBinding)
            Toggle("Custom moves", isOn: customMovesEnabledBinding)

            Spacer()

            partyButtons(draft: draft)
        }
    }

    @ViewBuilder
    private func partyButtons(draft: PokemonHackCore.TrainerEditDraft) -> some View {
        Button("Add Pokemon", systemImage: "plus") {
            addPartyPokemon()
        }
        .disabled(draft.party.count >= 6)

        Button("Remove", systemImage: "trash") {
            removeSelectedPartyPokemon()
        }
        .disabled(draft.party.count <= 1)
        .labelStyle(.iconOnly)
        .help("Remove selected Pokemon")
    }

    @ViewBuilder
    private func partyDetail(
        trainer: PokemonHackCore.TrainerDetail,
        draft: PokemonHackCore.TrainerEditDraft
    ) -> some View {
        if let member = draft.party.first(where: { $0.slot == selectedPartySlot }) ?? draft.party.first {
            let sourceMember = trainer.party.first(where: { $0.slot == member.slot })
            let inheritedMoves = defaultMoves(for: member)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Slot \(member.slot + 1)")
                        .font(.headline)
                    Spacer()
                    if let source = trainer.party.first(where: { $0.slot == member.slot })?.sourceSpan {
                        SourceLocationView(source: SourceLocation(path: source.relativePath, symbol: member.species, line: source.startLine))
                    }
                }

                SearchableConstantPicker(
                    title: "Species",
                    selection: partySpeciesBinding(slot: member.slot, fallback: member.species),
                    constants: constants(.species)
                )

                HStack(alignment: .top, spacing: 16) {
                    TrainerIntegerField(
                        title: "Level",
                        value: partyLevelBinding(slot: member.slot, fallback: member.level),
                        range: 1...100
                    )

                    SearchableConstantPicker(
                        title: "Nature",
                        selection: partyStringBinding(slot: member.slot, keyPath: \.nature, fallback: member.nature),
                        constants: constants(.natures)
                    )
                }

                if sourceMember?.supportsNature != true {
                    TrainerDisabledField(title: "Nature Source", detail: "Classic trainer parties do not store nature; changes remain staged diagnostics until the source supports natures.")
                }

                TrainerIVEditor(
                    hp: partyIVBinding(slot: member.slot, keyPath: \.hp, fallback: member.ivs.hp),
                    attack: partyIVBinding(slot: member.slot, keyPath: \.attack, fallback: member.ivs.attack),
                    defense: partyIVBinding(slot: member.slot, keyPath: \.defense, fallback: member.ivs.defense),
                    speed: partyIVBinding(slot: member.slot, keyPath: \.speed, fallback: member.ivs.speed),
                    spAttack: partyIVBinding(slot: member.slot, keyPath: \.spAttack, fallback: member.ivs.spAttack),
                    spDefense: partyIVBinding(slot: member.slot, keyPath: \.spDefense, fallback: member.ivs.spDefense)
                )

                if draft.partyShape.usesHeldItems {
                    SearchableConstantPicker(
                        title: "Held Item",
                        selection: partyStringBinding(slot: member.slot, keyPath: \.heldItem, fallback: member.heldItem),
                        constants: constants(.items)
                    )
                } else {
                    TrainerDisabledField(title: "Held Item", detail: "Enable held items to write heldItem fields.")
                }

                TrainerMoveList(title: "Default Moves", moves: inheritedMoves)

                if draft.partyShape.usesCustomMoves {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Move Overrides")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Reset to Defaults", systemImage: "arrow.counterclockwise") {
                                updatePartyMember(slot: member.slot) { member in
                                    refreshDefaultMoves(for: &member, fillMoveOverrides: true, replaceMoveOverrides: true)
                                }
                            }
                            .buttonStyle(.borderless)
                            .controlSize(.small)
                        }

                        ForEach(0..<4, id: \.self) { index in
                            SearchableConstantPicker(
                                title: "Slot \(index + 1)",
                                selection: partyMoveBinding(slot: member.slot, index: index),
                                constants: constants(.moves)
                            )
                        }
                    }
                } else {
                    TrainerDisabledField(title: "Move Overrides", detail: "Enable custom moves to write four explicit move overrides.")
                }
            }
        } else {
            ContentUnavailableView("No Party Pokemon", systemImage: "sparkles", description: Text("Add a party Pokemon before editing party fields."))
        }
    }

    private func sourceSection(
        trainer: PokemonHackCore.TrainerDetail,
        layoutMode: WorkbenchLayoutMode
    ) -> some View {
        DisclosureGroup(isExpanded: $sourceExpanded) {
            Group {
                if layoutMode.isCompact {
                    VStack(alignment: .leading, spacing: layoutMode.sectionSpacing) {
                        sourcePreviews(trainer: trainer)
                    }
                } else {
                    HStack(alignment: .top, spacing: 18) {
                        sourcePreviews(trainer: trainer)
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            Label("Source Previews", systemImage: "curlybraces.square")
                .font(.headline)
        }
    }

    @ViewBuilder
    private func sourcePreviews(trainer: PokemonHackCore.TrainerDetail) -> some View {
        EditorSection(title: "Trainer Source") {
            SourcePreviewBlock(text: trainer.sourcePreview)
        }

        EditorSection(title: "Party Source") {
            SourcePreviewBlock(text: trainer.partyPreview)
        }
    }

    @ViewBuilder
    private func diagnosticsSection(trainer: PokemonHackCore.TrainerDetail) -> some View {
        if !trainer.diagnostics.isEmpty {
            EditorSection(title: "Diagnostics") {
                VStack(spacing: 8) {
                    ForEach(trainer.diagnostics) { diagnostic in
                        TrainerDiagnosticRow(diagnostic: diagnostic)
                    }
                }
            }
        }
    }

    private func readOnlyDetail(
        trainer: PokemonHackCore.TrainerDetail,
        layoutMode: WorkbenchLayoutMode
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: layoutMode.sectionSpacing) {
                trainerHeader(
                    trainer: trainer,
                    draft: PokemonHackCore.TrainerEditDraft(
                        trainerID: trainer.trainerID,
                        trainerName: trainer.trainerName,
                        trainerClass: trainer.trainerClass,
                        encounterMusicGender: trainer.encounterMusicGender,
                        trainerPic: trainer.trainerPic,
                        trainerItems: trainer.trainerItems,
                        doubleBattle: trainer.doubleBattle,
                        aiFlags: trainer.aiFlags,
                        partyShape: trainer.partyShape ?? .noItemDefaultMoves,
                        partySymbol: trainer.partySymbol ?? "",
                        party: trainer.party.map {
                            PokemonHackCore.TrainerPartyPokemonDraft(
                                slot: $0.slot,
                                species: $0.species,
                                level: $0.level ?? 1,
                                iv: $0.iv ?? 0,
                                ivs: $0.ivs,
                                nature: $0.nature ?? "NATURE_HARDY",
                                heldItem: $0.heldItem ?? "ITEM_NONE",
                                moves: $0.moves.isEmpty ? $0.defaultMoves : $0.moves,
                                defaultMoves: $0.defaultMoves
                            )
                        }
                    )
                )

                DisclosureGroup(isExpanded: $sourceExpanded) {
                    Text("This trainer is visible, but edits are blocked until its source shape and diagnostics are supported.")
                        .foregroundStyle(.secondary)
                    SourcePreviewBlock(text: trainer.sourcePreview)
                    SourcePreviewBlock(text: trainer.partyPreview)
                } label: {
                    Label("Read-Only Source", systemImage: "curlybraces.square")
                        .font(.headline)
                }

                diagnosticsSection(trainer: trainer)
            }
            .padding(layoutMode.contentPadding)
        }
    }

    private func constants(_ group: PokemonHackCore.TrainerConstantGroup) -> [PokemonHackCore.TrainerConstant] {
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

    private func draftStringBinding(
        _ keyPath: WritableKeyPath<PokemonHackCore.TrainerEditDraft, String>,
        fallback: String
    ) -> Binding<String> {
        Binding(
            get: { draft?[keyPath: keyPath] ?? fallback },
            set: { value in
                guard var draft else { return }
                draft[keyPath: keyPath] = value
                onUpdateDraft(draft)
            }
        )
    }

    private func draftBoolBinding(
        _ keyPath: WritableKeyPath<PokemonHackCore.TrainerEditDraft, Bool>,
        fallback: Bool
    ) -> Binding<Bool> {
        Binding(
            get: { draft?[keyPath: keyPath] ?? fallback },
            set: { value in
                guard var draft else { return }
                draft[keyPath: keyPath] = value
                onUpdateDraft(draft)
            }
        )
    }

    private var trainerItemsEnabledBinding: Binding<Bool> {
        Binding(
            get: { draft?.trainerItems.contains { $0 != "ITEM_NONE" } ?? false },
            set: { enabled in
                guard var draft else { return }
                if enabled {
                    if draft.trainerItems.allSatisfy({ $0 == "ITEM_NONE" }) {
                        draft.trainerItems[0] = defaultBattleItem
                    }
                } else {
                    draft.trainerItems = Array(repeating: "ITEM_NONE", count: 4)
                }
                onUpdateDraft(draft)
            }
        )
    }

    private func trainerItemBinding(index: Int) -> Binding<String> {
        Binding(
            get: {
                guard let draft, draft.trainerItems.indices.contains(index) else { return "ITEM_NONE" }
                return draft.trainerItems[index]
            },
            set: { value in
                guard var draft else { return }
                while draft.trainerItems.count < 4 {
                    draft.trainerItems.append("ITEM_NONE")
                }
                draft.trainerItems[index] = value
                onUpdateDraft(draft)
            }
        )
    }

    private func aiFlagBinding(_ flag: String) -> Binding<Bool> {
        Binding(
            get: { draft?.aiFlags.contains(flag) ?? false },
            set: { enabled in
                guard var draft else { return }
                if enabled {
                    if !draft.aiFlags.contains(flag) {
                        draft.aiFlags.append(flag)
                        draft.aiFlags.sort()
                    }
                } else {
                    draft.aiFlags.removeAll { $0 == flag }
                }
                onUpdateDraft(draft)
            }
        )
    }

    private var heldItemsEnabledBinding: Binding<Bool> {
        Binding(
            get: { draft?.partyShape.usesHeldItems ?? false },
            set: { enabled in
                guard var draft else { return }
                draft.partyShape = partyShape(usesHeldItems: enabled, usesCustomMoves: draft.partyShape.usesCustomMoves)
                onUpdateDraft(draft)
            }
        )
    }

    private var customMovesEnabledBinding: Binding<Bool> {
        Binding(
            get: { draft?.partyShape.usesCustomMoves ?? false },
            set: { enabled in
                guard var draft else { return }
                draft.partyShape = partyShape(usesHeldItems: draft.partyShape.usesHeldItems, usesCustomMoves: enabled)
                if enabled {
                    for index in draft.party.indices {
                        refreshDefaultMoves(for: &draft.party[index], fillMoveOverrides: true, replaceMoveOverrides: false)
                    }
                }
                onUpdateDraft(draft)
            }
        )
    }

    private func partySpeciesBinding(slot: Int, fallback: String) -> Binding<String> {
        Binding(
            get: {
                draft?.party.first(where: { $0.slot == slot })?.species ?? fallback
            },
            set: { value in
                updatePartyMember(slot: slot) { member in
                    member.species = value
                    refreshDefaultMoves(
                        for: &member,
                        fillMoveOverrides: true,
                        replaceMoveOverrides: !(draft?.partyShape.usesCustomMoves ?? false)
                    )
                }
            }
        )
    }

    private func partyLevelBinding(slot: Int, fallback: Int) -> Binding<Int> {
        Binding(
            get: {
                draft?.party.first(where: { $0.slot == slot })?.level ?? fallback
            },
            set: { value in
                updatePartyMember(slot: slot) { member in
                    member.level = value
                    refreshDefaultMoves(
                        for: &member,
                        fillMoveOverrides: true,
                        replaceMoveOverrides: !(draft?.partyShape.usesCustomMoves ?? false)
                    )
                }
            }
        )
    }

    private func partyStringBinding(
        slot: Int,
        keyPath: WritableKeyPath<PokemonHackCore.TrainerPartyPokemonDraft, String>,
        fallback: String
    ) -> Binding<String> {
        Binding(
            get: {
                draft?.party.first(where: { $0.slot == slot })?[keyPath: keyPath] ?? fallback
            },
            set: { value in
                updatePartyMember(slot: slot) { member in
                    member[keyPath: keyPath] = value
                }
            }
        )
    }

    private func partyIntBinding(
        slot: Int,
        keyPath: WritableKeyPath<PokemonHackCore.TrainerPartyPokemonDraft, Int>,
        fallback: Int
    ) -> Binding<Int> {
        Binding(
            get: {
                draft?.party.first(where: { $0.slot == slot })?[keyPath: keyPath] ?? fallback
            },
            set: { value in
                updatePartyMember(slot: slot) { member in
                    member[keyPath: keyPath] = value
                }
            }
        )
    }

    private func partyIVBinding(
        slot: Int,
        keyPath: WritableKeyPath<PokemonHackCore.TrainerPokemonIVs, Int>,
        fallback: Int
    ) -> Binding<Int> {
        Binding(
            get: {
                draft?.party.first(where: { $0.slot == slot })?.ivs[keyPath: keyPath] ?? fallback
            },
            set: { value in
                updatePartyMember(slot: slot) { member in
                    member.ivs[keyPath: keyPath] = value
                }
            }
        )
    }

    private func partyMoveBinding(slot: Int, index: Int) -> Binding<String> {
        Binding(
            get: {
                guard
                    let member = draft?.party.first(where: { $0.slot == slot }),
                    member.moves.indices.contains(index)
                else {
                    return "MOVE_NONE"
                }
                return member.moves[index]
            },
            set: { value in
                updatePartyMember(slot: slot) { member in
                    while member.moves.count < 4 {
                        member.moves.append("MOVE_NONE")
                    }
                    member.moves[index] = value
                }
            }
        )
    }

    private func defaultMoves(for member: PokemonHackCore.TrainerPartyPokemonDraft) -> [String] {
        let learnset = catalog?.defaultMoveLearnsets[member.species] ?? []
        guard !learnset.isEmpty else {
            return Array((member.defaultMoves + Array(repeating: "MOVE_NONE", count: 4)).prefix(4))
        }
        let moves = learnset
            .filter { $0.level <= member.level }
            .map(\.move)
            .suffix(4)
        return Array((Array(moves) + Array(repeating: "MOVE_NONE", count: 4)).prefix(4))
    }

    private func refreshDefaultMoves(
        for member: inout PokemonHackCore.TrainerPartyPokemonDraft,
        fillMoveOverrides: Bool,
        replaceMoveOverrides: Bool
    ) {
        let moves = defaultMoves(for: member)
        member.defaultMoves = moves
        guard fillMoveOverrides else { return }
        while member.moves.count < 4 {
            member.moves.append("MOVE_NONE")
        }
        for index in 0..<4 {
            if replaceMoveOverrides || member.moves[index] == "MOVE_NONE" || member.moves[index].isEmpty {
                member.moves[index] = moves[index]
            }
        }
    }

    private func updatePartyMember(
        slot: Int,
        update: (inout PokemonHackCore.TrainerPartyPokemonDraft) -> Void
    ) {
        guard var draft, let index = draft.party.firstIndex(where: { $0.slot == slot }) else { return }
        update(&draft.party[index])
        onUpdateDraft(draft)
    }

    private func addPartyPokemon() {
        guard var draft, draft.party.count < 6 else { return }
        let slot = draft.party.count
        var member = PokemonHackCore.TrainerPartyPokemonDraft(
            slot: slot,
            species: defaultSpecies,
            level: 5,
            iv: 0,
            nature: "NATURE_HARDY",
            heldItem: "ITEM_NONE",
            moves: Array(repeating: "MOVE_NONE", count: 4)
        )
        refreshDefaultMoves(for: &member, fillMoveOverrides: true, replaceMoveOverrides: true)
        draft.party.append(member)
        selectedPartySlot = slot
        onUpdateDraft(draft)
    }

    private func removeSelectedPartyPokemon() {
        guard var draft, draft.party.count > 1 else { return }
        draft.party.removeAll { $0.slot == selectedPartySlot }
        draft.party = draft.party.enumerated().map { index, member in
            var member = member
            member.slot = index
            return member
        }
        selectedPartySlot = min(selectedPartySlot, max(0, draft.party.count - 1))
        onUpdateDraft(draft)
    }

    private func aiFlagSymbols(for draft: PokemonHackCore.TrainerEditDraft) -> [String] {
        let constants = constants(.aiFlags).map(\.symbol)
        return Array(Set(constants + draft.aiFlags)).sorted()
    }

    private var defaultBattleItem: String {
        if constants(.items).contains(where: { $0.symbol == "ITEM_POTION" }) {
            return "ITEM_POTION"
        }
        return constants(.items).first { $0.symbol != "ITEM_NONE" }?.symbol ?? "ITEM_NONE"
    }

    private var defaultSpecies: String {
        if constants(.species).contains(where: { $0.symbol == "SPECIES_POOCHYENA" }) {
            return "SPECIES_POOCHYENA"
        }
        return constants(.species).first { $0.symbol != "SPECIES_NONE" }?.symbol ?? "SPECIES_NONE"
    }

    private func partyShape(
        usesHeldItems: Bool,
        usesCustomMoves: Bool
    ) -> PokemonHackCore.TrainerPartyShape {
        switch (usesHeldItems, usesCustomMoves) {
        case (false, false):
            .noItemDefaultMoves
        case (false, true):
            .noItemCustomMoves
        case (true, false):
            .itemDefaultMoves
        case (true, true):
            .itemCustomMoves
        }
    }
}

private struct TrainerBrowserRow: View {
    let trainer: PokemonHackCore.TrainerDetail

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: trainer.isEditable ? "person.crop.rectangle" : "lock.doc")
                .frame(width: 20)
                .foregroundStyle(trainer.isEditable ? Color.secondary : Color.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(trainer.displayName)
                    .lineLimit(1)

                Text("\(trainer.trainerClass) · \(trainer.party.count) Pokemon")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(trainer.partyShape?.macroName ?? "Read-only")
                    if trainer.doubleBattle {
                        Text("Double")
                    }
                    if !trainer.trainerItems.allSatisfy({ $0 == "ITEM_NONE" }) {
                        Text("Items")
                    }
                }
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
                .lineLimit(1)
            }
        }
        .padding(.vertical, 3)
    }
}

private struct TrainerPartyRow: View {
    let member: PokemonHackCore.TrainerPartyPokemonDraft
    let shape: PokemonHackCore.TrainerPartyShape
    let isSelected: Bool
    let species: PokemonHackCore.SpeciesDetail?
    let rootPath: String?
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                if let species {
                    SpeciesAssetPreview(
                        asset: species.assets.first { $0.kind == .front },
                        rootPath: rootPath,
                        draftData: nil,
                        size: 36
                    )
                } else {
                    Text("\(member.slot + 1)")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .frame(width: 36, height: 36)
                        .background(isSelected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12), in: Circle())
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(displayConstant(member.species))
                        .lineLimit(1)
                    Text("Lv \(member.level) · IVs \(ivSummary(member.ivs))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if shape.usesHeldItems || shape.usesCustomMoves {
                        Text(summary)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var summary: String {
        var parts: [String] = []
        if shape.usesHeldItems {
            parts.append(member.heldItem)
        }
        if shape.usesCustomMoves {
            parts.append(member.moves.filter { $0 != "MOVE_NONE" }.prefix(2).joined(separator: ", "))
        }
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }
}


private struct TrainerIntegerField: View {
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

private struct TrainerIVEditor: View {
    @Binding var hp: Int
    @Binding var attack: Int
    @Binding var defense: Int
    @Binding var speed: Int
    @Binding var spAttack: Int
    @Binding var spDefense: Int

    private let columns = [
        GridItem(.adaptive(minimum: 118), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("IVs")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                TrainerIntegerField(title: "HP", value: $hp, range: 0...31)
                TrainerIntegerField(title: "Attack", value: $attack, range: 0...31)
                TrainerIntegerField(title: "Defense", value: $defense, range: 0...31)
                TrainerIntegerField(title: "Speed", value: $speed, range: 0...31)
                TrainerIntegerField(title: "Sp. Atk", value: $spAttack, range: 0...31)
                TrainerIntegerField(title: "Sp. Def", value: $spDefense, range: 0...31)
            }
        }
    }
}

private struct TrainerMoveList: View {
    let title: String
    let moves: [String]

    private let columns = [
        GridItem(.adaptive(minimum: 136), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    let move = moves.indices.contains(index) ? moves[index] : "MOVE_NONE"
                    HStack(spacing: 6) {
                        Text("\(index + 1)")
                            .font(.caption2.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 18)
                        Text(displayConstant(move))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    .help(move)
                }
            }
        }
    }
}

private struct TrainerDisabledField: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct TrainerDiagnosticRow: View {
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

private struct TrainerTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.monospaced())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.12), in: Capsule())
    }
}


private func ivSummary(_ ivs: PokemonHackCore.TrainerPokemonIVs) -> String {
    if let value = ivs.uniformValue {
        return "\(value)"
    }
    return "\(ivs.hp)/\(ivs.attack)/\(ivs.defense)/\(ivs.speed)/\(ivs.spAttack)/\(ivs.spDefense)"
}
