import SwiftUI

struct ModuleDetailView: View {
    @ObservedObject var store: WorkbenchStore

    var body: some View {
        EditorShell(
            module: store.selection,
            projectTitle: store.selectedIndexedProject?.title,
            status: moduleStatus,
            inspectorContext: shellInspectorContext,
            mutationPlanContext: nil,
            onPreviewMutationPlan: {
                store.previewSelectedMapMutationPlan()
            },
            onApplyMutationPlan: {
                store.applySelectedMapMutationPlan()
            },
            onDiscardMutationPlan: {
                store.discardMapEdits()
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
            TrainerEditorView(records: store.records(for: .trainers))
        case .items:
            CatalogEditorView(title: "Items", records: store.records(for: .items))
        case .pokemon:
            CatalogEditorView(title: "Pokemon", records: store.records(for: .pokemon))
        case .encounters:
            EncounterEditorView(records: store.records(for: .encounters))
        case .scripts:
            ScriptEditorView(records: store.records(for: .scripts))
        case .text:
            TextEditorWorkbenchView(records: store.records(for: .text))
        case .graphics:
            graphicsWorkbenchView
        case .build:
            BuildWorkbenchView(
                target: store.selectedTarget,
                steps: store.buildSteps,
                indexedProject: store.selectedIndexedProject
            )
        case .issues:
            IssuesView(issues: store.issues, indexedProject: store.selectedIndexedProject)
        }
    }

    private var graphicsWorkbenchView: some View {
        ContentUnavailableView(
            "Graphics",
            systemImage: WorkbenchModule.graphics.systemImage,
            description: Text("Indexed tilesets, palettes, and generated graphics artifacts will appear here.")
        )
        .navigationTitle(WorkbenchModule.graphics.title)
    }

    private var moduleStatus: ValidationState? {
        switch store.selection {
        case .dashboard:
            store.selectedIndexedProject?.status ?? store.projectIndexStatus.validationState
        case .maps:
            mapStatus
        case .build:
            status(for: store.buildSteps.map(\.status))
        case .issues:
            store.issueCount == 0 ? .valid : .warning
        case .graphics:
            graphicsStatus
        default:
            status(for: store.records(for: store.selection).map(\.validation))
        }
    }

    private var mapStatus: ValidationState {
        if case .failed = store.mapCatalogStatus {
            return .error
        }

        if let catalog = store.selectedMapCatalog, !catalog.diagnostics.isEmpty {
            return status(for: catalog.diagnostics.map(\.severity))
        }

        return .valid
    }

    private var graphicsStatus: ValidationState {
        guard let project = store.selectedIndexedProject else { return .valid }
        let graphicsSurfaces = project.sourceSurfaces.filter { surface in
            surface.kind == "graphics" || surface.kind == "palette"
        }
        return status(for: graphicsSurfaces.map(\.validation))
    }

    private var sourceInspectorContext: SourceInspectorContext? {
        switch store.selection {
        case .dashboard:
            projectInspectorContext
        case .maps:
            mapInspectorContext
        case .build:
            buildInspectorContext
        case .issues:
            diagnosticsInspectorContext
        case .graphics:
            graphicsInspectorContext
        default:
            recordsInspectorContext(module: store.selection)
        }
    }

    private var shellInspectorContext: SourceInspectorContext? {
        store.selection == .maps ? nil : sourceInspectorContext
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
                status: mapStatus,
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
            status: mapStatus,
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
                    SourceInspectorFact(label: "Artifacts", value: "\(project.artifactCount)")
                ],
                sources: project.generatedOutputs.prefix(8).map {
                    SourceInspectorSource(title: $0.title, source: $0.source, status: $0.validation)
                },
                diagnostics: project.diagnostics.prefix(6).map { SourceInspectorDiagnostic(diagnostic: $0) }
            )
        }

        return recordsInspectorContext(module: .build)
    }

    private var diagnosticsInspectorContext: SourceInspectorContext {
        if let project = store.selectedIndexedProject {
            return SourceInspectorContext(
                title: WorkbenchModule.issues.title,
                subtitle: "\(project.diagnosticCount) indexed diagnostics",
                systemImage: WorkbenchModule.issues.systemImage,
                status: moduleStatus,
                facts: [
                    SourceInspectorFact(label: "Project", value: project.title),
                    SourceInspectorFact(label: "Missing Sources", value: "\(project.missingSourceDocumentCount)")
                ],
                sources: [],
                diagnostics: project.diagnostics.prefix(10).map { SourceInspectorDiagnostic(diagnostic: $0) }
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

        let graphicsSurfaces = project.sourceSurfaces.filter { surface in
            surface.kind == "graphics" || surface.kind == "palette"
        }

        return SourceInspectorContext(
            title: WorkbenchModule.graphics.title,
            subtitle: project.title,
            systemImage: WorkbenchModule.graphics.systemImage,
            status: graphicsStatus,
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
