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
                romInspector: store.selectedROMInspectorReport,
                gameCubeEntry: store.explicitGameCubeResourceEntry,
                gameCubeLoadStatus: store.gameCubeResourceLoadStatus,
                assets: store.filteredResourceAssetRows,
                assetLoadStatus: store.assetCatalogLoadStatus,
                gameCubeResourcePath: Binding(
                    get: { store.selectedGameCubeResourcePath },
                    set: { store.selectedGameCubeResourcePath = $0 }
                ),
                selectedAssetID: Binding(
                    get: { store.selectedResourceAssetID },
                    set: { store.requestResourceAssetSelection($0) }
                ),
                mode: Binding(
                    get: { store.selectedResourceLibraryMode },
                    set: { store.selectedResourceLibraryMode = $0 }
                ),
                selectedCategory: Binding(
                    get: { store.resourceAssetCategory },
                    set: { store.resourceAssetCategory = $0 }
                ),
                sortMode: Binding(
                    get: { store.resourceAssetSortMode },
                    set: { store.resourceAssetSortMode = $0 }
                ),
                onChooseGameCubeResource: {
                    store.chooseGameCubeResourceImage()
                },
                onLoadGameCubeResource: {
                    store.loadSelectedGameCubeResourcePath()
                },
                onLoadAssetCatalog: {
                    store.loadSelectedAssetCatalogIfNeeded()
                },
                onNavigateToAsset: store.navigateToAsset,
                ndsDataEditor: store.selectedNDSDataEditor,
                onUpdateNDSDataDraft: store.updateSelectedNDSDataDraftText,
                onUpdateNDSDataSemanticField: store.updateSelectedNDSDataSemanticField,
                onPreviewNDSDataMutationPlan: store.previewSelectedNDSDataMutationPlan,
                onApplyNDSDataMutationPlan: store.applySelectedNDSDataMutationPlan,
                onDiscardNDSDataEdits: store.discardNDSDataEdits
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
                speciesCatalog: store.selectedSpeciesCatalog,
                onLoadCatalog: {
                    store.loadSelectedTrainerCatalogIfNeeded()
                },
                onSelectTrainer: store.requestTrainerSelection,
                onUpdateDraft: store.updateSelectedTrainerDraft,
                onFocusSpecies: { speciesID in
                    store.focusSpecies(speciesID)
                }
            )
        case .items:
            PokemonItemsWorkbenchView(
                catalog: store.selectedItemCatalogView,
                items: store.filteredItemDetails,
                selectedItemID: Binding(
                    get: { store.selectedItemID },
                    set: { store.requestItemSelection($0) }
                ),
                selectedItem: store.selectedItemDetail,
                draft: store.selectedItemDraft,
                isDirty: store.selectedItemIsDirty,
                loadStatus: store.itemCatalogLoadStatus,
                filter: Binding(
                    get: { store.selectedItemWorkbenchFilter },
                    set: { store.selectedItemWorkbenchFilter = $0 }
                ),
                fallbackRecords: store.records(for: .items),
                onLoadCatalog: {
                    store.loadSelectedItemCatalogIfNeeded()
                },
                onUpdateDraft: store.updateSelectedItemDraft
            )
        case .moves:
            PokemonMovesWorkbenchView(
                catalog: store.selectedMoveCatalog,
                moves: store.filteredMoveDetails,
                selectedMoveID: Binding(
                    get: { store.selectedMoveID },
                    set: { store.requestMoveSelection($0) }
                ),
                selectedMove: store.selectedMoveDetail,
                draft: store.selectedMoveDraft,
                isDirty: store.selectedMoveIsDirty,
                speciesCatalog: store.selectedSpeciesCatalog,
                loadStatus: store.moveCatalogLoadStatus,
                filter: Binding(
                    get: { store.selectedMoveWorkbenchFilter },
                    set: { store.selectedMoveWorkbenchFilter = $0 }
                ),
                fallbackRecords: store.records(for: .moves),
                onLoadCatalog: {
                    store.loadSelectedMoveCatalogIfNeeded()
                },
                onUpdateDraft: store.updateSelectedMoveDraft,
                onRevealMoveInSidebar: { moveID in
                    store.selectedMoveWorkbenchFilter = .all
                    store.focusWorkbenchTarget(.move(moveID), search: .replace(moveID))
                },
                onFocusSpecies: { speciesID in
                    store.focusSpecies(speciesID)
                },
                isSpeciesCompatibleWithMove: { speciesID, moveID, bucket in
                    store.speciesCompatibilityValue(speciesID: speciesID, moveID: moveID, bucket: bucket)
                },
                onSetSpeciesCompatibility: { speciesID, moveID, bucket, isEnabled in
                    store.setSpeciesCompatibility(speciesID: speciesID, moveID: moveID, bucket: bucket, isEnabled: isEnabled)
                },
                onNavigateToResourceAsset: store.navigateToResourceAsset
            )
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
                onFocusSpecies: { speciesID in
                    store.focusSpecies(speciesID)
                },
                onImportAsset: { kind, url in
                    store.importSelectedSpeciesAsset(kind: kind, from: url)
                },
                assetImportBlockedReason: { kind in
                    store.selectedSpeciesAssetImportBlockedReason(kind: kind)
                },
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
            .onAppear {
                store.loadSelectedSourceGraphIfNeeded()
            }
        case .text:
            TextEditorWorkbenchView(records: store.records(for: .text))
                .onAppear {
                    store.loadSelectedSourceGraphIfNeeded()
                }
        case .graphics:
            graphicsWorkbenchView
        case .build:
            BuildWorkbenchView(store: store)
        case .issues:
            IssuesView(
                issues: store.issues,
                indexedProject: store.selectedIndexedProject,
                indexedDiagnostics: store.selectedDiagnosticRows,
                diagnosticSummary: store.diagnosticSummary
            )
        }
    }

    private var graphicsWorkbenchView: some View {
        GraphicsWorkbenchView(store: store)
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
        case .moves:
            moveInspectorContext
        default:
            recordsInspectorContext(module: store.selection)
        }
    }

    private var shellInspectorContext: SourceInspectorContext? {
        sourceInspectorContext
    }

    private var mutationPlanContext: MutationPlanPanelContext? {
        switch store.selection {
        case .maps:
            MutationPlanPanelContext.map(session: store.mapEditorSession)
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
        case .moves:
            if let context = MutationPlanPanelContext.speciesBatch(
                plans: store.latestSpeciesBatchEditPlans,
                result: store.latestSpeciesBatchApplyResult,
                dirtyDraftCount: store.dirtySpeciesBatchDrafts.count,
                canPreview: store.canPreviewSpeciesBatchMutationPlan,
                canApply: store.canApplySpeciesBatchMutationPlan,
                canDiscard: store.canDiscardSpeciesBatchEdits,
                previewBlockedReason: store.speciesBatchPreviewBlockedReason,
                applyBlockedReason: store.speciesBatchApplyBlockedReason
            ) {
                context
            } else {
                MutationPlanPanelContext.move(
                plan: store.latestMoveEditPlan,
                result: store.latestMoveApplyResult,
                isDirty: store.selectedMoveIsDirty,
                canPreview: store.canPreviewSelectedMoveMutationPlan,
                canApply: store.canApplySelectedMoveMutationPlan,
                canDiscard: store.canDiscardMoveEdits,
                previewBlockedReason: store.movePreviewBlockedReason,
                applyBlockedReason: store.moveApplyBlockedReason
                )
            }
        case .items:
            MutationPlanPanelContext.item(
                plan: store.latestItemEditPlan,
                result: store.latestItemApplyResult,
                isDirty: store.selectedItemIsDirty,
                canPreview: store.canPreviewSelectedItemMutationPlan,
                canApply: store.canApplySelectedItemMutationPlan,
                canDiscard: store.canDiscardItemEdits,
                previewBlockedReason: store.itemPreviewBlockedReason,
                applyBlockedReason: store.itemApplyBlockedReason
            )
        case .graphics:
            MutationPlanPanelContext.graphics(
                plan: store.latestGraphicsEditPlan,
                result: store.latestGraphicsApplyResult,
                draft: store.selectedGraphicsDraft,
                isDirty: store.selectedGraphicsIsDirty,
                canPreview: store.canPreviewSelectedGraphicsMutationPlan,
                canApply: store.canApplySelectedGraphicsMutationPlan,
                canDiscard: store.canDiscardGraphicsEdits,
                previewBlockedReason: store.graphicsPreviewBlockedReason,
                applyBlockedReason: store.graphicsApplyBlockedReason
            )
        case .resources:
            MutationPlanPanelContext.ndsData(
                plan: store.latestNDSDataEditPlan,
                result: store.latestNDSDataApplyResult,
                editor: store.selectedNDSDataEditor
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
        case .moves:
            if store.canDiscardSpeciesBatchEdits {
                store.previewSpeciesBatchMutationPlan()
            } else {
                store.previewSelectedMoveMutationPlan()
            }
        case .items:
            store.previewSelectedItemMutationPlan()
        case .graphics:
            store.previewSelectedGraphicsMutationPlan()
        case .resources:
            store.previewSelectedNDSDataMutationPlan()
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
        case .moves:
            if store.canDiscardSpeciesBatchEdits {
                store.applySpeciesBatchMutationPlan()
            } else {
                store.applySelectedMoveMutationPlan()
            }
        case .items:
            store.applySelectedItemMutationPlan()
        case .graphics:
            store.applySelectedGraphicsMutationPlan()
        case .resources:
            store.applySelectedNDSDataMutationPlan()
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
        case .moves:
            if store.canDiscardSpeciesBatchEdits {
                store.discardSpeciesBatchEdits()
            } else {
                store.discardMoveEdits()
            }
        case .items:
            store.discardItemEdits()
        case .graphics:
            store.discardGraphicsEdits()
        case .resources:
            store.discardNDSDataEdits()
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

    private var moveInspectorContext: SourceInspectorContext {
        guard let catalog = store.selectedMoveCatalog else {
            return SourceInspectorContext(
                title: WorkbenchModule.moves.title,
                subtitle: store.moveCatalogLoadStatus.label,
                systemImage: WorkbenchModule.moves.systemImage,
                status: store.moveCatalogLoadStatus.validationState,
                facts: [],
                sources: [],
                diagnostics: []
            )
        }

        guard let move = store.selectedMoveDetail else {
            return SourceInspectorContext(
                title: WorkbenchModule.moves.title,
                subtitle: "\(catalog.moveCount) moves",
                systemImage: WorkbenchModule.moves.systemImage,
                status: store.moduleStatus(for: .moves),
                facts: [
                    SourceInspectorFact(label: "Moves", value: "\(catalog.moveCount)"),
                    SourceInspectorFact(label: "Learnsets", value: "\(catalog.learnsetEntryCount)")
                ],
                sources: [],
                diagnostics: catalog.diagnostics.prefix(8).map { SourceInspectorDiagnostic(diagnostic: $0) }
            )
        }

        return SourceInspectorContext(
            title: move.displayName,
            subtitle: move.moveID,
            systemImage: WorkbenchModule.moves.systemImage,
            status: move.status,
            facts: [
                SourceInspectorFact(label: "TM/HM", value: "\(move.tmhmLearners.count)"),
                SourceInspectorFact(label: "Tutor", value: "\(move.tutorLearners.count)"),
                SourceInspectorFact(label: "Learned By", value: "\(move.learnedBy.count)"),
                SourceInspectorFact(label: "Diagnostics", value: "\(move.diagnostics.count)")
            ],
            sources: [
                SourceInspectorSource(title: "Move Definition", source: move.source, status: move.status)
            ],
            diagnostics: move.diagnostics.prefix(8).map { SourceInspectorDiagnostic(diagnostic: $0) }
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
