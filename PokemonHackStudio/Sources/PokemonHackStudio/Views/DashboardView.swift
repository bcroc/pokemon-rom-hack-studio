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
                    Text(project.writePolicy)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            let mapMetric = store.dashboardMapMetric
            let diagnosticSummary = store.diagnosticSummary
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
                MetricCard(title: "Sources", value: "\(project.existingSourceDocumentCount)/\(project.sourceDocumentCount)", detail: "Indexed source files")
                MetricCard(title: "Maps", value: mapMetric.value, detail: mapMetric.detail)
                MetricCard(title: "Pokemon", value: "\(store.selectedSpeciesCatalog?.speciesCount ?? 0)", detail: store.speciesCatalogLoadStatus.label)
                MetricCard(title: "Trainers", value: "\(store.selectedTrainerCatalog?.trainerCount ?? 0)", detail: store.trainerCatalogLoadStatus.label)
                MetricCard(title: "Build Targets", value: "\(project.buildTargetCount)", detail: "Preview only")
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
                store.selection = .issues
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
                    Text(entry.platform)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
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
        case "gbaROM":
            "memorychip"
        case "gameCube":
            "opticaldisc"
        default:
            "questionmark.folder"
        }
    }
}
