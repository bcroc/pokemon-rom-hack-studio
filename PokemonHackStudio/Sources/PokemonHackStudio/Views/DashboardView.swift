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
        .navigationTitle("Dashboard")
    }

    @ViewBuilder
    private func indexedDashboard(_ project: IndexedProjectSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(project.title)
                        .font(.largeTitle.weight(.semibold))
                    Text(project.subtitle)
                        .foregroundStyle(.secondary)
                    Text(project.rootPath)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .textSelection(.enabled)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    StatusPill(state: project.status)
                    StatusPill(state: store.projectIndexStatus.validationState)
                    Text(store.projectIndexStatus.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
            if let library = store.resourceLibrary {
                MetricCard(
                    title: "Gen III Resources",
                    value: "\(library.entryCount)",
                    detail: "\(library.parsedCount) parsed"
                )
            }
            MetricCard(
                title: "Source Documents",
                value: "\(project.sourceDocumentCount)",
                detail: "\(project.existingSourceDocumentCount) present"
            )
            MetricCard(
                title: "Missing Sources",
                value: "\(project.missingSourceDocumentCount)",
                detail: "Adapter expectations"
            )
            MetricCard(
                title: "Diagnostics",
                value: "\(store.issueCount)",
                detail: "Read-only index"
            )
            MetricCard(
                title: "Build Targets",
                value: "\(project.buildTargetCount)",
                detail: "Preview commands"
            )
            MetricCard(
                title: "Generated Outputs",
                value: "\(project.generatedOutputCount)",
                detail: "\(project.artifactCount) artifacts"
            )
            MetricCard(
                title: "Write Policy",
                value: project.writePolicy,
                detail: "No direct source writes"
            )
        }

        if let library = store.resourceLibrary {
            resourceLibrarySection(library)
        }

        EditorSection(title: "Indexed Source Surfaces") {
            VStack(spacing: 10) {
                ForEach(project.sourceSurfaces.prefix(8)) { surface in
                    IndexedSourceSurfaceRow(surface: surface)
                }
            }
        }

        EditorSection(title: "Generated Outputs") {
            VStack(spacing: 10) {
                ForEach(project.generatedOutputs.prefix(6)) { surface in
                    IndexedSourceSurfaceRow(surface: surface)
                }
            }
        }

        if !store.selectedDiagnosticRows.isEmpty {
            EditorSection(title: "Index Diagnostics") {
                VStack(spacing: 10) {
                    ForEach(store.selectedDiagnosticRows.prefix(5)) { diagnostic in
                        IndexedDiagnosticRowView(diagnostic: diagnostic)
                    }
                }
            }
        }
    }

    private var fixtureDashboard: some View {
        Group {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.selectedTarget.name)
                        .font(.largeTitle.weight(.semibold))
                    Text("Source-tree-first workbench for \(store.selectedTarget.romBase)")
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
                    if let library = store.resourceLibrary {
                        MetricCard(title: "Gen III Resources", value: "\(library.entryCount)", detail: "\(library.missingCount) missing")
                    }
                    MetricCard(title: "Modules", value: "\(WorkbenchModule.allCases.count)", detail: "Editor surfaces")
                    MetricCard(title: "Dirty Fixtures", value: "\(store.records.filter(\.isDirty).count)", detail: "Unsaved mock edits")
                    MetricCard(title: "Issues", value: "\(store.issueCount)", detail: "Validation queue")
                    MetricCard(title: "Targets", value: "\(store.targets.count)", detail: "Build profiles")
                }

                if let library = store.resourceLibrary {
                    resourceLibrarySection(library)
                }

                EditorSection(title: "Recent Source Surfaces") {
                    VStack(spacing: 10) {
                        ForEach(store.records.prefix(5)) { record in
                            RecordSummaryRow(record: record)
                        }
                    }
                }

                EditorSection(title: "Workbench Contract") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Every editor names the source file, symbol, and line it represents.", systemImage: "location")
                        Label("Dirty and validation badges are fixture-backed UI affordances.", systemImage: "checkmark.seal")
                        Label("Build, run, and validate controls are mock actions with no source-writing behavior.", systemImage: "lock.doc")
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func resourceLibrarySection(_ library: ResourceLibraryViewState) -> some View {
        EditorSection(title: "Generation III Resource Library") {
            VStack(spacing: 10) {
                ForEach(library.entries) { entry in
                    ResourceLibraryRow(entry: entry)
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
