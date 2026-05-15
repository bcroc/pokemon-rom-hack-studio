import Foundation

@MainActor
extension WorkbenchStore {
    var diagnosticSummary: DiagnosticSummary {
        let diagnostics = selectedIndexedProject == nil ? fixtureDiagnosticRows : selectedDiagnosticRows
        return DiagnosticSummary(diagnostics: diagnostics)
    }

    var guidedFlows: [WorkbenchGuidedFlow] {
        [
            mapsGuidedFlow,
            pokemonGuidedFlow,
            trainersGuidedFlow,
            resourcesGuidedFlow,
            shipGuidedFlow,
            diagnosticsGuidedFlow
        ]
    }

    var dashboardMapMetric: (value: String, detail: String) {
        if let catalog = selectedMapCatalog {
            return ("\(catalog.mapCount)", mapCatalogStatus.label)
        }

        let sourceMapCount = records(for: .maps).count
        if sourceMapCount > 0 {
            switch mapCatalogStatus {
            case .loading:
                return ("\(sourceMapCount)", "Source index, loading catalog")
            case .failed:
                return ("\(sourceMapCount)", mapCatalogStatus.label)
            case .idle, .loaded:
                return ("\(sourceMapCount)", "Source index, open Maps for layouts")
            }
        }

        return ("0", mapCatalogStatus.label)
    }

    func route(to action: WorkbenchGuidedAction) {
        if let resourceAssetPath = action.resourceAssetPath {
            navigateToResourceAsset(path: resourceAssetPath)
            return
        }

        selectWorkbenchModule(
            action.targetModule,
            search: action.searchText.map(WorkbenchSearchBehavior.replace) ?? .restoreModule
        )
        if let buildTab = action.buildTab {
            selectedBuildWorkbenchTab = buildTab
        }

        switch action.targetModule {
        case .maps:
            loadSelectedMapCatalogIfNeeded()
            loadSelectedMapVisualDocumentIfNeeded()
        case .pokemon:
            loadSelectedSpeciesCatalogIfNeeded()
        case .trainers:
            loadSelectedTrainerCatalogIfNeeded()
        case .moves:
            loadSelectedMoveCatalogIfNeeded()
        case .resources:
            resourceAssetCategory = action.resourceAssetCategory ?? Self.allResourceAssetCategories
            loadSelectedAssetCatalogIfNeeded()
        case .scripts:
            if !searchText.isEmpty {
                scriptReadinessTargetMode = .script
                refreshSelectedScriptReadinessReport()
            }
        case .issues:
            selectedDiagnosticBucket = .blockingErrors
        case .build, .graphics, .items, .encounters, .text, .dashboard:
            break
        }
    }

    private var mapsGuidedFlow: WorkbenchGuidedFlow {
        let mapCount = selectedMapCatalog?.mapCount ?? records(for: .maps).count
        let layoutCount = selectedMapCatalog?.layoutCount ?? 0
        return WorkbenchGuidedFlow(
            id: "maps-events",
            title: "Edit Maps & Events",
            subtitle: "Start from layouts, events, scripts, and blockdata previews.",
            detail: "Map edits stay staged until a mutation plan is previewed and explicitly applied.",
            systemImage: WorkbenchModule.maps.systemImage,
            status: moduleStatus(for: .maps),
            facts: [
                Fact(label: "Maps", value: "\(mapCount)"),
                Fact(label: "Layouts", value: layoutCount == 0 ? "Load catalog" : "\(layoutCount)")
            ],
            primaryAction: WorkbenchGuidedAction(
                id: "open-maps",
                title: "Open Maps",
                subtitle: "Browse maps and stage source-first edits.",
                systemImage: WorkbenchModule.maps.systemImage,
                targetModule: .maps
            ),
            secondaryActions: [
                WorkbenchGuidedAction(
                    id: "open-map-assets",
                    title: "Map Assets",
                    subtitle: "Find layouts, tilesets, and related files.",
                    systemImage: WorkbenchModule.resources.systemImage,
                    targetModule: .resources,
                    searchText: "layout",
                    resourceAssetCategory: "layouts"
                )
            ]
        )
    }

    private var pokemonGuidedFlow: WorkbenchGuidedFlow {
        WorkbenchGuidedFlow(
            id: "pokemon-data",
            title: "Tune Pokemon Data",
            subtitle: "Adjust stats, learnsets, evolutions, and linked graphics.",
            detail: "Pokemon edits use preview/apply/discard mutation plans with source path visibility.",
            systemImage: WorkbenchModule.pokemon.systemImage,
            status: moduleStatus(for: .pokemon),
            facts: [
                Fact(label: "Species", value: "\(selectedSpeciesCatalog?.speciesCount ?? records(for: .pokemon).count)"),
                Fact(label: "Selected", value: selectedSpeciesDetail?.displayName ?? "First editable")
            ],
            primaryAction: WorkbenchGuidedAction(
                id: "open-pokemon",
                title: "Open Pokemon",
                subtitle: "Edit the first real species or search the full catalog.",
                systemImage: WorkbenchModule.pokemon.systemImage,
                targetModule: .pokemon
            ),
            secondaryActions: [
                WorkbenchGuidedAction(
                    id: "pokemon-assets",
                    title: "Pokemon Assets",
                    subtitle: "Jump to sprites, icons, palettes, and related resources.",
                    systemImage: "photo.on.rectangle",
                    targetModule: .resources,
                    searchText: "pokemon",
                    resourceAssetCategory: "graphics"
                )
            ]
        )
    }

    private var trainersGuidedFlow: WorkbenchGuidedFlow {
        WorkbenchGuidedFlow(
            id: "trainer-battles",
            title: "Build Trainer Battles",
            subtitle: "Review parties, items, AI flags, and battle shape.",
            detail: "Trainer edits share the same mutation-plan review rhythm as Pokemon.",
            systemImage: WorkbenchModule.trainers.systemImage,
            status: moduleStatus(for: .trainers),
            facts: [
                Fact(label: "Trainers", value: "\(selectedTrainerCatalog?.trainerCount ?? records(for: .trainers).count)"),
                Fact(label: "Selected", value: selectedTrainerDetail?.trainerName ?? "First editable")
            ],
            primaryAction: WorkbenchGuidedAction(
                id: "open-trainers",
                title: "Open Trainers",
                subtitle: "Edit battle data with source previews visible.",
                systemImage: WorkbenchModule.trainers.systemImage,
                targetModule: .trainers
            ),
            secondaryActions: [
                WorkbenchGuidedAction(
                    id: "trainer-assets",
                    title: "Trainer Assets",
                    subtitle: "Find trainer graphics and related source files.",
                    systemImage: "person.crop.square",
                    targetModule: .resources,
                    searchText: "trainer",
                    resourceAssetCategory: "graphics"
                )
            ]
        )
    }

    private var resourcesGuidedFlow: WorkbenchGuidedFlow {
        let firstResourcePath = selectedAssetCatalog?.rows.first?.path ?? resourceLibrary?.entries.first?.path
        let secondaryAction: WorkbenchGuidedAction
        if let firstResourcePath {
            secondaryAction = WorkbenchGuidedAction(
                id: "focus-first-resource",
                title: "Inspect First Asset",
                subtitle: "Open the resource browser with a concrete source path selected.",
                systemImage: "scope",
                targetModule: .resources,
                resourceAssetPath: firstResourcePath
            )
        } else {
            secondaryAction = WorkbenchGuidedAction(
                id: "open-graphics",
                title: "Graphics Report",
                subtitle: "Review tilesets, palettes, and generated asset findings.",
                systemImage: WorkbenchModule.graphics.systemImage,
                targetModule: .graphics
            )
        }

        return WorkbenchGuidedFlow(
            id: "resources-assets",
            title: "Inspect Assets & Graphics",
            subtitle: "Connect ROM resources, source files, graphics, and module backlinks.",
            detail: "Resource rows can route into maps, Pokemon, trainers, graphics, scripts, and build reports.",
            systemImage: WorkbenchModule.resources.systemImage,
            status: moduleStatus(for: .resources),
            facts: [
                Fact(label: "Resources", value: "\(resourceLibrary?.entryCount ?? 0)"),
                Fact(label: "Assets", value: "\(selectedAssetCatalog?.assetCount ?? 0)")
            ],
            primaryAction: WorkbenchGuidedAction(
                id: "open-resources",
                title: "Open Resources",
                subtitle: "Search assets and follow backlinks into editor modules.",
                systemImage: WorkbenchModule.resources.systemImage,
                targetModule: .resources
            ),
            secondaryActions: [secondaryAction]
        )
    }

    private var shipGuidedFlow: WorkbenchGuidedFlow {
        WorkbenchGuidedFlow(
            id: "ship-preview",
            title: "Prepare Patch & Playtest",
            subtitle: "Check build readiness, patch inputs, and playtest handoff reports.",
            detail: selectedBuildReport?.isNDS == true
                ? "NDS build and emulator actions remain manual guidance only; no tools, Docker, extraction, rebuilds, or ROM writes are run."
                : "GBA projects can run declared make targets and external mGBA handoffs; patch apply/export and source writes remain locked behind preview/report flows.",
            systemImage: WorkbenchModule.build.systemImage,
            status: moduleStatus(for: .build),
            facts: [
                Fact(label: "Build Rows", value: "\(selectedBuildReport?.rows.count ?? filteredBuildReportRows.count)"),
                Fact(label: "Patch", value: patchManifestLoadStatus.validationState.rawValue)
            ],
            primaryAction: WorkbenchGuidedAction(
                id: "open-ship",
                title: "Open Build Readiness",
                subtitle: selectedBuildReport?.isNDS == true
                    ? "Review manual NDS setup, header, and declared-output guidance."
                    : "Review build, patch, and playtest actions for the selected project.",
                systemImage: WorkbenchModule.build.systemImage,
                targetModule: .build,
                buildTab: .build
            ),
            secondaryActions: [
                WorkbenchGuidedAction(
                    id: "patch-check",
                    title: "Patch Check",
                    subtitle: "Start at patch manifest and base ROM inputs.",
                    systemImage: "doc.badge.gearshape",
                    targetModule: .build,
                    buildTab: .patch
                )
            ]
        )
    }

    private var diagnosticsGuidedFlow: WorkbenchGuidedFlow {
        let summary = diagnosticSummary
        return WorkbenchGuidedFlow(
            id: "diagnostics-triage",
            title: "Triage Diagnostics",
            subtitle: "Group blocking errors, source warnings, health, generated files, and optional assets.",
            detail: "Use diagnostics as the project health queue before editing or shipping.",
            systemImage: WorkbenchModule.issues.systemImage,
            status: summary.status,
            facts: [
                Fact(label: "Blocking", value: "\(summary.blockingErrorCount)"),
                Fact(label: "Warnings", value: "\(summary.warningCount)")
            ],
            primaryAction: WorkbenchGuidedAction(
                id: "open-diagnostics",
                title: "Open Diagnostics",
                subtitle: "Review findings by source and severity.",
                systemImage: WorkbenchModule.issues.systemImage,
                targetModule: .issues
            ),
            secondaryActions: [
                WorkbenchGuidedAction(
                    id: "build-health",
                    title: "Health Report",
                    subtitle: "Inspect readiness and generated-output checks.",
                    systemImage: "wrench.and.screwdriver",
                    targetModule: .build,
                    buildTab: .build
                )
            ]
        )
    }

    private var fixtureDiagnosticRows: [IndexedDiagnosticRow] {
        issues.map { issue in
            IndexedDiagnosticRow(
                id: issue.id.uuidString,
                title: issue.title,
                message: issue.message,
                severity: issue.severity,
                source: issue.source
            )
        }
    }
}
