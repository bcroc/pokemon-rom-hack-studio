import PokemonHackCore
import SwiftUI

struct ModuleDetailView: View {
    @ObservedObject var store: WorkbenchStore

    var body: some View {
        EditorShell(
            module: store.selection,
            projectTitle: store.selectedIndexedProject?.title,
            status: moduleStatus,
            inspectorContext: shellInspectorContext,
            mutationPlanContext: mutationPlanContext,
            showsSourceInspectorByDefault: store.userSettings.showSourceInspectorByDefault,
            onPreviewMutationPlan: {
                previewMutationPlan()
            },
            onApplyMutationPlan: {
                applyMutationPlan()
            },
            onDiscardMutationPlan: {
                discardMutationPlan()
            }
        ) {
            selectedModuleContent
        }
    }

    @ViewBuilder
    private var selectedModuleContent: some View {
        switch store.selection {
        case .dashboard:
            DashboardView(store: store)
        case .resources:
            ResourceLibraryWorkbenchView(
                library: store.resourceLibrary,
                entries: store.filteredResourceLibraryEntries,
                assetCatalog: store.selectedAssetCatalog,
                assets: store.filteredResourceAssetRows,
                assetLoadStatus: store.assetCatalogLoadStatus,
                selectedAssetID: Binding(
                    get: { store.selectedResourceAssetID },
                    set: { store.requestResourceAssetSelection($0) }
                ),
                selectedCategory: Binding(
                    get: { store.resourceAssetCategory },
                    set: { store.resourceAssetCategory = $0 }
                ),
                sortMode: Binding(
                    get: { store.resourceAssetSortMode },
                    set: { store.resourceAssetSortMode = $0 }
                ),
                onLoadAssetCatalog: {
                    store.loadSelectedAssetCatalogIfNeeded()
                },
                onNavigateToAsset: store.navigateToAsset
            )
        case .maps:
            MapEditorView(
                store: store,
                records: store.records(for: .maps),
                catalog: store.selectedMapCatalog
            )
            .onAppear {
                store.loadSelectedMapCatalogIfNeeded()
                store.loadSelectedMapVisualDocumentIfNeeded()
            }
        case .trainers:
            TrainerEditorView(
                catalog: store.selectedTrainerCatalog,
                trainers: store.filteredTrainerDetails,
                selectedTrainerID: Binding(
                    get: { store.selectedTrainerID },
                    set: { store.requestTrainerSelection($0) }
                ),
                selectedTrainer: store.selectedTrainerDetail,
                draft: store.selectedTrainerDraft,
                isDirty: store.selectedTrainerIsDirty,
                rootPath: store.selectedIndexedProject?.rootPath,
                loadStatus: store.trainerCatalogLoadStatus,
                fallbackRecords: store.records(for: .trainers),
                onLoadCatalog: {
                    store.loadSelectedTrainerCatalogIfNeeded()
                },
                onSelectTrainer: store.requestTrainerSelection,
                onUpdateDraft: store.updateSelectedTrainerDraft
            )
        case .items:
            CatalogEditorView(title: "Items", records: store.records(for: .items))
        case .pokemon:
            PokemonSpeciesWorkbenchView(
                catalog: store.selectedSpeciesCatalog,
                species: store.filteredSpeciesDetails,
                selectedSpeciesID: Binding(
                    get: { store.selectedSpeciesID },
                    set: { store.requestSpeciesSelection($0) }
                ),
                selectedSpecies: store.selectedSpeciesDetail,
                draft: store.selectedSpeciesDraft,
                isDirty: store.selectedSpeciesIsDirty,
                rootPath: store.selectedIndexedProject?.rootPath,
                loadStatus: store.speciesCatalogLoadStatus,
                onLoadCatalog: {
                    store.loadSelectedSpeciesCatalogIfNeeded()
                },
                onUpdateDraft: store.updateSelectedSpeciesDraft,
                onNavigateToResourceAsset: store.navigateToResourceAsset
            )
        case .encounters:
            EncounterEditorView(records: store.records(for: .encounters))
        case .scripts:
            ScriptEditorView(
                store: store,
                records: store.records(for: .scripts),
                outline: store.selectedScriptOutline,
                sources: store.filteredScriptOutlineSources,
                labels: store.filteredScriptOutlineLabels,
                textBlocks: store.filteredScriptTextBlocks
            )
        case .text:
            TextEditorWorkbenchView(records: store.records(for: .text))
        case .graphics:
            graphicsWorkbenchView
        case .build:
            BuildWorkbenchView(store: store)
        case .issues:
            IssuesView(
                issues: store.issues,
                indexedProject: store.selectedIndexedProject,
                indexedDiagnostics: store.selectedDiagnosticRows
            )
        }
    }

    private var graphicsWorkbenchView: some View {
        GraphicsWorkbenchView(
            indexedProject: store.selectedIndexedProject,
            report: store.selectedGraphicsReport,
            rows: store.filteredGraphicsReportRows
        )
    }

    private var moduleStatus: ValidationState? {
        store.moduleStatus(for: store.selection)
    }

    private var sourceInspectorContext: SourceInspectorContext? {
        switch store.selection {
        case .dashboard:
            projectInspectorContext
        case .resources:
            resourceInspectorContext
        case .maps:
            mapInspectorContext
        case .build:
            buildInspectorContext
        case .issues:
            diagnosticsInspectorContext
        case .scripts:
            scriptInspectorContext
        case .graphics:
            graphicsInspectorContext
        case .pokemon:
            speciesInspectorContext
        case .trainers:
            trainerInspectorContext
        default:
            recordsInspectorContext(module: store.selection)
        }
    }

    private var shellInspectorContext: SourceInspectorContext? {
        store.selection == .maps ? nil : sourceInspectorContext
    }

    private var mutationPlanContext: MutationPlanPanelContext? {
        switch store.selection {
        case .pokemon:
            MutationPlanPanelContext.species(
                plan: store.latestSpeciesEditPlan,
                result: store.latestSpeciesApplyResult,
                isDirty: store.selectedSpeciesIsDirty,
                canPreview: store.canPreviewSelectedSpeciesMutationPlan,
                canApply: store.canApplySelectedSpeciesMutationPlan,
                canDiscard: store.canDiscardSpeciesEdits,
                previewBlockedReason: store.speciesPreviewBlockedReason,
                applyBlockedReason: store.speciesApplyBlockedReason
            )
        case .trainers:
            MutationPlanPanelContext.trainer(
                plan: store.latestTrainerEditPlan,
                result: store.latestTrainerApplyResult,
                isDirty: store.selectedTrainerIsDirty,
                canPreview: store.canPreviewSelectedTrainerMutationPlan,
                canApply: store.canApplySelectedTrainerMutationPlan,
                canDiscard: store.canDiscardTrainerEdits,
                previewBlockedReason: store.trainerPreviewBlockedReason,
                applyBlockedReason: store.trainerApplyBlockedReason
            )
        default:
            nil
        }
    }

    private func previewMutationPlan() {
        switch store.selection {
        case .pokemon:
            store.previewSelectedSpeciesMutationPlan()
        case .trainers:
            store.previewSelectedTrainerMutationPlan()
        default:
            store.previewSelectedMapMutationPlan()
        }
    }

    private func applyMutationPlan() {
        switch store.selection {
        case .pokemon:
            store.applySelectedSpeciesMutationPlan()
        case .trainers:
            store.applySelectedTrainerMutationPlan()
        default:
            store.applySelectedMapMutationPlan()
        }
    }

    private func discardMutationPlan() {
        switch store.selection {
        case .pokemon:
            store.discardSpeciesEdits()
        case .trainers:
            store.discardTrainerEdits()
        default:
            store.discardMapEdits()
        }
    }

    private var projectInspectorContext: SourceInspectorContext {
        guard let project = store.selectedIndexedProject else {
            return SourceInspectorContext(
                title: "Project Index",
                subtitle: store.projectIndexStatus.label,
                systemImage: WorkbenchModule.dashboard.systemImage,
                status: store.projectIndexStatus.validationState,
                facts: [
                    SourceInspectorFact(label: "Projects", value: "\(store.indexedProjects.count)"),
                    SourceInspectorFact(label: "Issues", value: "\(store.issueCount)")
                ],
                sources: [],
                diagnostics: []
            )
        }

        return SourceInspectorContext(
            title: project.title,
            subtitle: project.subtitle,
            systemImage: WorkbenchModule.dashboard.systemImage,
            status: project.status,
            facts: [
                SourceInspectorFact(label: "Profile", value: project.profile),
                SourceInspectorFact(label: "Write Policy", value: project.writePolicy),
                SourceInspectorFact(label: "Sources", value: "\(project.existingSourceDocumentCount)/\(project.sourceDocumentCount)"),
                SourceInspectorFact(label: "Build Targets", value: "\(project.buildTargetCount)")
            ],
            sources: project.sourceSurfaces.prefix(8).map {
                SourceInspectorSource(title: $0.title, source: $0.source, status: $0.validation)
            },
            diagnostics: project.diagnostics.prefix(6).map { SourceInspectorDiagnostic(diagnostic: $0) }
        )
    }

    private var resourceInspectorContext: SourceInspectorContext {
        guard let library = store.resourceLibrary else {
            return SourceInspectorContext(
                title: WorkbenchModule.resources.title,
                subtitle: "No resource library loaded",
                systemImage: WorkbenchModule.resources.systemImage,
                status: .valid,
                facts: [],
                sources: [],
                diagnostics: []
            )
        }

        return SourceInspectorContext(
            title: WorkbenchModule.resources.title,
            subtitle: library.workspaceRoot,
            systemImage: WorkbenchModule.resources.systemImage,
            status: store.moduleStatus(for: .resources),
            facts: [
                SourceInspectorFact(label: "Entries", value: "\(library.entryCount)"),
                SourceInspectorFact(label: "Parsed", value: "\(library.parsedCount)"),
                SourceInspectorFact(label: "Missing", value: "\(library.missingCount)"),
                SourceInspectorFact(label: "Items", value: "\(library.itemCount)"),
                SourceInspectorFact(label: "Assets", value: "\(store.selectedAssetCatalog?.assetCount ?? 0)")
            ],
            sources: resourceInspectorSources(library: library),
            diagnostics: (library.allDiagnostics + (store.selectedAssetCatalog?.diagnostics ?? []))
                .prefix(10)
                .map { SourceInspectorDiagnostic(diagnostic: $0) }
        )
    }

    private func resourceInspectorSources(library: ResourceLibraryViewState) -> [SourceInspectorSource] {
        let entrySources = library.entries.prefix(5).map {
            SourceInspectorSource(title: $0.title, source: $0.source, status: $0.status)
        }
        let assetSources = store.selectedAssetCatalog?.rows.prefix(5).map {
            SourceInspectorSource(title: $0.title, source: $0.source, status: $0.status)
        } ?? []
        return entrySources + assetSources
    }

    private var mapInspectorContext: SourceInspectorContext {
        guard let catalog = store.selectedMapCatalog else {
            return recordsInspectorContext(module: .maps)
        }

        let selectedMap = catalog.maps.first { $0.id == store.selectedMapID } ?? catalog.maps.first
        guard let selectedMap else {
            return SourceInspectorContext(
                title: catalog.projectTitle,
                subtitle: store.mapCatalogStatus.label,
                systemImage: WorkbenchModule.maps.systemImage,
                status: store.moduleStatus(for: .maps),
                facts: [
                    SourceInspectorFact(label: "Groups", value: "\(catalog.groupCount)"),
                    SourceInspectorFact(label: "Maps", value: "\(catalog.mapCount)"),
                    SourceInspectorFact(label: "Layouts", value: "\(catalog.layoutCount)")
                ],
                sources: [],
                diagnostics: catalog.diagnostics.prefix(6).map { SourceInspectorDiagnostic(diagnostic: $0) }
            )
        }

        return SourceInspectorContext(
            title: selectedMap.name,
            subtitle: "\(selectedMap.groupName) in \(catalog.projectTitle)",
            systemImage: WorkbenchModule.maps.systemImage,
            status: store.moduleStatus(for: .maps),
            facts: mapFacts(selectedMap),
            sources: mapSources(selectedMap),
            diagnostics: catalog.diagnostics.prefix(6).map { SourceInspectorDiagnostic(diagnostic: $0) }
        )
    }

    private var buildInspectorContext: SourceInspectorContext {
        if let project = store.selectedIndexedProject {
            return SourceInspectorContext(
                title: WorkbenchModule.build.title,
                subtitle: project.title,
                systemImage: WorkbenchModule.build.systemImage,
                status: moduleStatus,
                facts: [
                    SourceInspectorFact(label: "Targets", value: "\(project.buildTargetCount)"),
                    SourceInspectorFact(label: "Generated", value: "\(project.generatedOutputCount)"),
                    SourceInspectorFact(label: "Artifacts", value: "\(project.artifactCount)"),
                    SourceInspectorFact(label: "Health Rows", value: "\(store.selectedBuildReport?.healthMatrix.rows.count ?? 0)"),
                    SourceInspectorFact(label: "Report Rows", value: "\(store.filteredBuildReportRows.count)")
                ],
                sources: (store.selectedBuildReport?.generatedArtifacts.prefix(8).map {
                    SourceInspectorSource(title: $0.title, source: $0.source, status: $0.status)
                } ?? project.generatedOutputs.prefix(8).map {
                    SourceInspectorSource(title: $0.title, source: $0.source, status: $0.validation)
                }),
                diagnostics: (store.selectedBuildReport?.diagnostics.prefix(6).map {
                    SourceInspectorDiagnostic(diagnostic: $0)
                } ?? project.diagnostics.prefix(6).map {
                    SourceInspectorDiagnostic(diagnostic: $0)
                })
            )
        }

        return recordsInspectorContext(module: .build)
    }

    private var diagnosticsInspectorContext: SourceInspectorContext {
        if let project = store.selectedIndexedProject {
            return SourceInspectorContext(
                title: WorkbenchModule.issues.title,
                subtitle: "\(store.issueCount) indexed diagnostics",
                systemImage: WorkbenchModule.issues.systemImage,
                status: moduleStatus,
                facts: [
                    SourceInspectorFact(label: "Project", value: project.title),
                    SourceInspectorFact(label: "Missing Sources", value: "\(project.missingSourceDocumentCount)")
                ],
                sources: [],
                diagnostics: store.selectedDiagnosticRows.prefix(10).map { SourceInspectorDiagnostic(diagnostic: $0) }
            )
        }

        return SourceInspectorContext(
            title: WorkbenchModule.issues.title,
            subtitle: "\(store.issueCount) fixture diagnostics",
            systemImage: WorkbenchModule.issues.systemImage,
            status: moduleStatus,
            facts: [SourceInspectorFact(label: "Open", value: "\(store.issueCount)")],
            sources: store.issues.prefix(6).map {
                SourceInspectorSource(title: $0.title, source: $0.source, status: $0.severity)
            },
            diagnostics: store.issues.prefix(6).map {
                SourceInspectorDiagnostic(
                    id: $0.id.uuidString,
                    title: $0.title,
                    message: $0.message,
                    status: $0.severity,
                    source: $0.source
                )
            }
        )
    }

    private var scriptInspectorContext: SourceInspectorContext {
        guard let outline = store.selectedScriptOutline else {
            return recordsInspectorContext(module: .scripts)
        }

        return SourceInspectorContext(
            title: WorkbenchModule.scripts.title,
            subtitle: "\(outline.adapterName) · \(outline.profile.rawValue)",
            systemImage: WorkbenchModule.scripts.systemImage,
            status: store.moduleStatus(for: .scripts),
            facts: [
                SourceInspectorFact(label: "Sources", value: "\(outline.sources.count)"),
                SourceInspectorFact(label: "Labels", value: "\(outline.labels.count)"),
                SourceInspectorFact(label: "Commands", value: "\(outline.labels.reduce(0) { $0 + $1.commands.count })"),
                SourceInspectorFact(label: "Text Blocks", value: "\(outline.textBlocks.count)")
            ],
            sources: outline.sources.prefix(10).map {
                SourceInspectorSource(
                    title: $0.path,
                    source: SourceLocation(path: $0.path, symbol: $0.module.rawValue, line: 1),
                    status: $0.diagnosticCount > 0 ? .warning : .valid
                )
            },
            diagnostics: outline.diagnostics.prefix(8).map { diagnostic in
                SourceInspectorDiagnostic(
                    id: diagnostic.id,
                    title: diagnostic.code,
                    message: diagnostic.message,
                    status: WorkbenchStore.validationState(for: diagnostic.severity),
                    source: diagnostic.span.map { span in
                        SourceLocation(path: span.relativePath, symbol: diagnostic.code, line: span.startLine)
                    }
                )
            }
        )
    }

    private var graphicsInspectorContext: SourceInspectorContext {
        guard let project = store.selectedIndexedProject else {
            return SourceInspectorContext(
                title: WorkbenchModule.graphics.title,
                subtitle: WorkbenchModule.graphics.subtitle,
                systemImage: WorkbenchModule.graphics.systemImage,
                status: .valid,
                facts: [],
                sources: [],
                diagnostics: []
            )
        }

        if let report = store.selectedGraphicsReport {
            return SourceInspectorContext(
                title: WorkbenchModule.graphics.title,
                subtitle: project.title,
                systemImage: WorkbenchModule.graphics.systemImage,
                status: report.status,
                facts: [
                    SourceInspectorFact(label: "Tilesets", value: "\(report.tilesetCount)"),
                    SourceInspectorFact(label: "Tile Images", value: "\(report.tileImageCount)"),
                    SourceInspectorFact(label: "Palettes", value: "\(report.paletteFileCount)"),
                    SourceInspectorFact(label: "Animations", value: "\(report.animationDirectoryCount)")
                ],
                sources: report.rows.prefix(8).map {
                    SourceInspectorSource(title: $0.title, source: $0.source, status: $0.status)
                },
                diagnostics: report.diagnostics.prefix(6).map { SourceInspectorDiagnostic(diagnostic: $0) }
            )
        }

        let graphicsSurfaces = project.sourceSurfaces.filter { surface in
            surface.kind == "graphics" || surface.kind == "palette"
        }
        return SourceInspectorContext(
            title: WorkbenchModule.graphics.title,
            subtitle: project.title,
            systemImage: WorkbenchModule.graphics.systemImage,
            status: store.moduleStatus(for: .graphics),
            facts: [
                SourceInspectorFact(label: "Graphics Sources", value: "\(graphicsSurfaces.count)"),
                SourceInspectorFact(label: "Generated Outputs", value: "\(project.generatedOutputCount)")
            ],
            sources: graphicsSurfaces.prefix(10).map {
                SourceInspectorSource(title: $0.title, source: $0.source, status: $0.validation)
            },
            diagnostics: project.diagnostics.prefix(6).map { SourceInspectorDiagnostic(diagnostic: $0) }
        )
    }

    private var speciesInspectorContext: SourceInspectorContext {
        guard let catalog = store.selectedSpeciesCatalog else {
            return SourceInspectorContext(
                title: WorkbenchModule.pokemon.title,
                subtitle: store.speciesCatalogLoadStatus.label,
                systemImage: WorkbenchModule.pokemon.systemImage,
                status: store.speciesCatalogLoadStatus.validationState,
                facts: [],
                sources: [],
                diagnostics: []
            )
        }

        guard let species = store.selectedSpeciesDetail else {
            return SourceInspectorContext(
                title: WorkbenchModule.pokemon.title,
                subtitle: "\(catalog.speciesCount) species",
                systemImage: WorkbenchModule.pokemon.systemImage,
                status: store.moduleStatus(for: .pokemon),
                facts: [SourceInspectorFact(label: "Species", value: "\(catalog.speciesCount)")],
                sources: [],
                diagnostics: catalog.diagnostics.prefix(8).map(sourceInspectorDiagnostic(from:))
            )
        }

        return SourceInspectorContext(
            title: species.displayName,
            subtitle: species.speciesID,
            systemImage: WorkbenchModule.pokemon.systemImage,
            status: store.moduleStatus(for: .pokemon),
            facts: [
                SourceInspectorFact(label: "Base Stat Total", value: species.baseStats.total.map(String.init) ?? "Unknown"),
                SourceInspectorFact(label: "Level Moves", value: "\(species.learnsets.levelUp.count)"),
                SourceInspectorFact(label: "TM/HM", value: "\(species.learnsets.tmhm.count)"),
                SourceInspectorFact(label: "Egg Moves", value: "\(species.learnsets.egg.count)"),
                SourceInspectorFact(label: "Assets", value: "\(species.assets.filter(\.exists).count)/\(species.assets.count)")
            ],
            sources: speciesSources(species),
            diagnostics: (catalog.diagnostics + species.diagnostics).prefix(10).map(sourceInspectorDiagnostic(from:))
        )
    }

    private var trainerInspectorContext: SourceInspectorContext {
        guard let catalog = store.selectedTrainerCatalog else {
            return SourceInspectorContext(
                title: WorkbenchModule.trainers.title,
                subtitle: store.trainerCatalogLoadStatus.label,
                systemImage: WorkbenchModule.trainers.systemImage,
                status: store.trainerCatalogLoadStatus.validationState,
                facts: [],
                sources: [],
                diagnostics: []
            )
        }

        guard let trainer = store.selectedTrainerDetail else {
            return SourceInspectorContext(
                title: WorkbenchModule.trainers.title,
                subtitle: "\(catalog.trainerCount) trainers",
                systemImage: WorkbenchModule.trainers.systemImage,
                status: store.moduleStatus(for: .trainers),
                facts: [SourceInspectorFact(label: "Trainers", value: "\(catalog.trainerCount)")],
                sources: [],
                diagnostics: catalog.diagnostics.prefix(8).map(sourceInspectorDiagnostic(from:))
            )
        }

        let trainerStatus = status(
            for: trainer.diagnostics.map { WorkbenchStore.validationState(for: $0.severity) }
        )

        return SourceInspectorContext(
            title: trainer.displayName,
            subtitle: trainer.trainerID,
            systemImage: WorkbenchModule.trainers.systemImage,
            status: trainerStatus,
            facts: [
                SourceInspectorFact(label: "Class", value: trainer.trainerClass),
                SourceInspectorFact(label: "Party", value: "\(trainer.party.count) Pokemon"),
                SourceInspectorFact(label: "AI Flags", value: "\(trainer.aiFlags.count)"),
                SourceInspectorFact(label: "Editable", value: trainer.isEditable ? "Yes" : "No")
            ],
            sources: trainerSources(trainer),
            diagnostics: trainer.diagnostics.prefix(10).map(sourceInspectorDiagnostic(from:))
        )
    }

    private func recordsInspectorContext(module: WorkbenchModule) -> SourceInspectorContext {
        let records = store.records(for: module)
        return SourceInspectorContext(
            title: module.title,
            subtitle: module.subtitle,
            systemImage: module.systemImage,
            status: status(for: records.map(\.validation)),
            facts: [
                SourceInspectorFact(label: "Records", value: "\(records.count)"),
                SourceInspectorFact(label: "Dirty", value: "\(records.filter(\.isDirty).count)")
            ],
            sources: records.prefix(8).map {
                SourceInspectorSource(title: $0.title, source: $0.source, status: $0.validation)
            },
            diagnostics: []
        )
    }

    private func speciesSources(_ species: PokemonHackCore.SpeciesDetail) -> [SourceInspectorSource] {
        var sources = [
            SourceInspectorSource(
                title: "Species Info",
                source: SourceLocation(
                    path: species.sourceSpan.relativePath,
                    symbol: species.speciesID,
                    line: species.sourceSpan.startLine
                ),
                status: .valid
            )
        ]
        if let pokedex = species.pokedex {
            sources.append(
                SourceInspectorSource(
                    title: "Pokedex",
                    source: SourceLocation(path: pokedex.sourceSpan.relativePath, symbol: species.speciesID, line: pokedex.sourceSpan.startLine),
                    status: .valid
                )
            )
        }
        sources.append(contentsOf: species.assets.prefix(5).map {
            SourceInspectorSource(
                title: $0.kind.title,
                source: SourceLocation(path: $0.sourceSpan.relativePath, symbol: species.speciesID, line: $0.sourceSpan.startLine),
                status: $0.exists ? .valid : .warning
            )
        })
        return sources
    }

    private func trainerSources(_ trainer: PokemonHackCore.TrainerDetail) -> [SourceInspectorSource] {
        var sources = [
            SourceInspectorSource(
                title: "Trainer Table",
                source: SourceLocation(
                    path: trainer.sourceSpan.relativePath,
                    symbol: trainer.trainerID,
                    line: trainer.sourceSpan.startLine
                ),
                status: trainer.isEditable ? .valid : .warning
            )
        ]
        if let partySpan = trainer.partySourceSpan, let partySymbol = trainer.partySymbol {
            sources.append(
                SourceInspectorSource(
                    title: "Trainer Party",
                    source: SourceLocation(path: partySpan.relativePath, symbol: partySymbol, line: partySpan.startLine),
                    status: trainer.isEditable ? .valid : .warning
                )
            )
        }
        return sources
    }

    private func sourceInspectorDiagnostic(from diagnostic: PokemonHackCore.Diagnostic) -> SourceInspectorDiagnostic {
        SourceInspectorDiagnostic(
            id: diagnostic.id,
            title: diagnostic.code,
            message: diagnostic.message,
            status: WorkbenchStore.validationState(for: diagnostic.severity),
            source: diagnostic.span.map { span in
                SourceLocation(path: span.relativePath, symbol: diagnostic.code, line: span.startLine)
            }
        )
    }

    private func mapFacts(_ map: MapSummaryViewState) -> [SourceInspectorFact] {
        var facts = [
            SourceInspectorFact(label: "Group", value: map.groupName),
            SourceInspectorFact(label: "Events", value: "\(map.eventCounts.total)"),
            SourceInspectorFact(label: "Connections", value: "\(map.connections.count)")
        ]

        if let layout = map.layout {
            facts.append(SourceInspectorFact(label: "Layout", value: layout.name))
            facts.append(SourceInspectorFact(label: "Size", value: "\(layout.width)x\(layout.height)"))
        }

        return facts
    }

    private func mapSources(_ map: MapSummaryViewState) -> [SourceInspectorSource] {
        var sources = [
            SourceInspectorSource(title: "Map JSON", source: map.source, status: .valid)
        ]

        if let layout = map.layout {
            if let blockdataFilepath = layout.blockdataFilepath {
                sources.append(
                    SourceInspectorSource(
                        title: "Blockdata",
                        source: SourceLocation(path: blockdataFilepath, symbol: layout.name, line: 1),
                        status: .valid
                    )
                )
            }

            if let borderFilepath = layout.borderFilepath {
                sources.append(
                    SourceInspectorSource(
                        title: "Border",
                        source: SourceLocation(path: borderFilepath, symbol: layout.name, line: 1),
                        status: .valid
                    )
                )
            }
        }

        return sources
    }

    private func status(for states: [ValidationState]) -> ValidationState {
        if states.contains(.error) {
            return .error
        }

        if states.contains(.warning) {
            return .warning
        }

        return .valid
    }
}

private extension SourceInspectorDiagnostic {
    init(diagnostic: IndexedDiagnosticRow) {
        self.init(
            id: diagnostic.id,
            title: diagnostic.title,
            message: diagnostic.message,
            status: diagnostic.severity,
            source: diagnostic.source
        )
    }
}
