import SwiftUI

struct DashboardView: View {
    @ObservedObject var store: WorkbenchStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let project = store.selectedIndexedProject {
                    indexedDashboard(project)
                } else {
                    fixtureDashboard
                }
            }
            .padding(24)
        }
        .navigationTitle("Project Hub")
    }

    @ViewBuilder
    private func indexedDashboard(_ project: IndexedProjectSummary) -> some View {
        projectHeader(project)
        workspaceSaveSection
        workflowHub
        diagnosticsHub

        if let library = store.resourceLibrary {
            resourceLibrarySection(library)
        }

        EditorSection(title: "Source Shortcuts") {
            VStack(spacing: 10) {
                ForEach(project.sourceSurfaces.prefix(6)) { surface in
                    IndexedSourceSurfaceRow(surface: surface)
                }
            }
        }
    }

    private var workspaceSaveSection: some View {
        EditorSection(title: "Workspace Saves") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    StatusPill(state: store.workspacePersistenceError == nil ? .valid : .error)
                    Text(store.workspacePersistenceError ?? store.workspacePersistenceStatus)
                        .font(.callout)
                        .foregroundStyle(store.workspacePersistenceError == nil ? Color.secondary : Color.red)
                    Spacer()
                    Text(store.workspaceAutosavePending ? "Autosave pending" : store.workspaceLastSavedLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                    MetricCard(title: "Current Drafts", value: "\(store.currentDraftCount)", detail: "Unsourced workspace state")
                    MetricCard(title: "Saved Drafts", value: "\(store.savedDraftCount)", detail: "Ignored local snapshot")
                    MetricCard(title: "Save Location", value: ".pokemonhackstudio", detail: "Project-local")
                }

                HStack(spacing: 8) {
                    Button("Save Project", systemImage: "square.and.arrow.down") {
                        store.saveProjectWorkspace()
                    }
                    .disabled(!store.canSaveProjectWorkspace)

                    Button("Save Drafts", systemImage: "tray.and.arrow.down") {
                        store.saveDraftsNow()
                    }
                    .disabled(!store.canSaveProjectWorkspace)

                    Button("Reload", systemImage: "arrow.counterclockwise") {
                        store.loadSavedWorkspaceForSelectedProject()
                    }
                    .disabled(!store.canSaveProjectWorkspace)

                    Button("Discard Drafts", systemImage: "trash") {
                        store.discardSavedDrafts()
                    }
                    .disabled(!store.canSaveProjectWorkspace || (store.currentDraftCount == 0 && store.savedDraftCount == 0))

                    Spacer()
                }
            }
        }
    }

    private func projectHeader(_ project: IndexedProjectSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(project.title)
                        .font(.largeTitle.weight(.semibold))
                    Text("Guided workbench for maps, Pokemon data, trainer battles, assets, patch readiness, and diagnostics.")
                        .foregroundStyle(.secondary)
                    Text(project.rootPath)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    StatusPill(state: project.status)
                    StatusPill(state: store.projectIndexStatus.validationState)
                    DashboardResourceTag(text: project.originLabel)
                    DashboardResourceTag(text: project.writePolicy)
                }
            }

            let mapMetric = store.dashboardMapMetric
            let diagnosticSummary = store.diagnosticSummary
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
                MetricCard(title: "Sources", value: "\(project.existingSourceDocumentCount)/\(project.sourceDocumentCount)", detail: "Indexed source files")
                MetricCard(title: "Maps", value: mapMetric.value, detail: mapMetric.detail)
                MetricCard(title: "Pokemon", value: "\(store.selectedSpeciesCatalog?.speciesCount ?? 0)", detail: store.speciesCatalogLoadStatus.label)
                MetricCard(title: "Trainers", value: "\(store.selectedTrainerCatalog?.trainerCount ?? 0)", detail: store.trainerCatalogLoadStatus.label)
                MetricCard(title: "Build Targets", value: "\(project.buildTargetCount)", detail: store.selectedBuildReport?.isNDS == true ? "Manual NDS guidance" : "Declared make targets")
                MetricCard(title: "Diagnostics", value: "\(diagnosticSummary.totalCount)", detail: diagnosticSummary.compactLabel)
            }
        }
    }

    private var workflowHub: some View {
        EditorSection(title: "Next Actions") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 12)], spacing: 12) {
                ForEach(store.guidedFlows) { flow in
                    GuidedFlowCard(flow: flow) { action in
                        store.route(to: action)
                    }
                }
            }
        }
    }

    private var diagnosticsHub: some View {
        EditorSection(title: "Project Health") {
            DiagnosticSummaryStrip(summary: store.diagnosticSummary) {
                store.selectWorkbenchModule(.issues)
            }
        }
    }

    private var fixtureDashboard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(store.selectedTarget.name)
                    .font(.largeTitle.weight(.semibold))
                Text("Open a Generation III source project to use guided ROM-hacking workflows.")
                    .foregroundStyle(.secondary)
            }

            workflowHub
            diagnosticsHub

            if let library = store.resourceLibrary {
                resourceLibrarySection(library)
            }

            EditorSection(title: "Available Fixture Surfaces") {
                VStack(spacing: 10) {
                    ForEach(store.records.prefix(5)) { record in
                        RecordSummaryRow(record: record)
                    }
                }
            }
        }
    }

    private func resourceLibrarySection(_ library: ResourceLibraryViewState) -> some View {
        EditorSection(title: "Resource Library") {
            VStack(spacing: 10) {
                ForEach(library.entries) { entry in
                    ResourceLibraryRow(entry: entry)
                }
            }
        }
    }
}

private struct GuidedFlowCard: View {
    let flow: WorkbenchGuidedFlow
    let route: (WorkbenchGuidedAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: flow.systemImage)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 5) {
                    Text(flow.title)
                        .font(.headline)
                    Text(flow.subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
                StatusPill(state: flow.status)
            }

            Text(flow.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            FactGrid(facts: flow.facts)

            HStack(spacing: 8) {
                Button(flow.primaryAction.title, systemImage: flow.primaryAction.systemImage) {
                    route(flow.primaryAction)
                }
                .help(flow.primaryAction.subtitle)

                ForEach(flow.secondaryActions) { action in
                    Button(action.title, systemImage: action.systemImage) {
                        route(action)
                    }
                    .buttonStyle(.borderless)
                    .help(action.subtitle)
                }

                Spacer()
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct DiagnosticSummaryStrip: View {
    let summary: DiagnosticSummary
    let openDiagnostics: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                StatusPill(state: summary.status)
                Text(summary.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Open Diagnostics", systemImage: "list.bullet.rectangle") {
                    openDiagnostics()
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 10)], spacing: 10) {
                ForEach(summary.buckets) { bucket in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: bucket.systemImage)
                                .foregroundStyle(.secondary)
                            Text(bucket.title)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            Spacer()
                            Text("\(bucket.count)")
                                .font(.caption.monospacedDigit().weight(.semibold))
                                .foregroundStyle(bucket.count == 0 ? .secondary : .primary)
                        }
                        Text(bucket.subtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(10)
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

private struct ResourceLibraryRow: View {
    let entry: ResourceLibraryEntryViewState

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(entry.title)
                        .font(.headline)
                    StatusPill(state: entry.status)
                    DashboardResourceTag(text: entry.platform)
                    DashboardResourceTag(text: entry.role)
                    DashboardResourceTag(text: entry.writePolicy)
                }
                Text("\(entry.variantSummary) · \(entry.moduleSummary)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(entry.path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .textSelection(.enabled)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(entry.resourceCount)")
                    .font(.headline)
                Text(entry.parseStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if entry.diagnosticCount > 0 {
                    Text("\(entry.diagnosticCount) diagnostics")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
    }

    private var iconName: String {
        switch entry.platform {
        case "gbaSource":
            "folder"
        case "ndsSource":
            "folder.badge.gearshape"
        case "gbaROM":
            "memorychip"
        case "ndsROM":
            "memorychip"
        case "gameCube":
            "opticaldisc"
        default:
            "questionmark.folder"
        }
    }
}

private struct DashboardResourceTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.secondary.opacity(0.12), in: Capsule())
            .foregroundStyle(.secondary)
    }
}
