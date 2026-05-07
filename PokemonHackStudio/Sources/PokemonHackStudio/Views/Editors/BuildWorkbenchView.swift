import SwiftUI

struct BuildWorkbenchView: View {
    let target: BuildTarget
    let steps: [BuildStep]
    let indexedProject: IndexedProjectSummary?
    let report: BuildPatchPlaytestReportViewState?
    let rows: [BuildReportRow]

    var body: some View {
        ScrollView {
            if let indexedProject, let report {
                indexedBuild(project: indexedProject, report: report)
            } else {
                fixtureBuild
            }
        }
        .navigationTitle("Build")
    }

    private func indexedBuild(
        project: IndexedProjectSummary,
        report: BuildPatchPlaytestReportViewState
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Build")
                        .font(.largeTitle.weight(.semibold))
                    Text("\(project.title) readiness report for builds, generated outputs, toolchain health, and playtest handoff.")
                        .foregroundStyle(.secondary)
                    Text(report.rootPath)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    StatusPill(state: report.status)
                    Text(report.profile)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
                MetricCard(title: "Build Targets", value: "\(report.buildTargets.count)", detail: "Preview commands")
                MetricCard(
                    title: "Generated",
                    value: "\(report.generatedArtifacts.count)",
                    detail: "\(report.generatedArtifacts.filter(\.exists).count) present"
                )
                MetricCard(title: "Toolchain", value: report.toolchain.status.rawValue, detail: report.toolchain.detail)
                MetricCard(
                    title: "Health Matrix",
                    value: "\(report.healthMatrix.warningCount + report.healthMatrix.errorCount)",
                    detail: report.healthMatrix.detail
                )
                MetricCard(title: "Playtest", value: report.playtest.status.rawValue, detail: report.playtest.emulator)
            }

            ForEach(BuildReportSection.allCases.filter { $0 != .diagnostics }) { section in
                let sectionRows = rows.filter { $0.section == section }
                EditorSection(title: section.rawValue) {
                    VStack(spacing: 10) {
                        if sectionRows.isEmpty {
                            emptySection(section)
                        } else {
                            ForEach(sectionRows) { row in
                                BuildReportRowView(row: row)
                            }
                        }
                    }
                }
            }

            if !report.diagnostics.isEmpty {
                EditorSection(title: BuildReportSection.diagnostics.rawValue) {
                    VStack(spacing: 10) {
                        ForEach(rows.filter { $0.section == .diagnostics }) { row in
                            BuildReportRowView(row: row)
                        }
                    }
                }
            }

            EditorSection(title: "Actions") {
                HStack {
                    Button("Build", systemImage: "hammer") {}
                        .disabled(true)
                    Button("Run", systemImage: "play.fill") {}
                        .disabled(true)
                    Button("Validate", systemImage: "checkmark.seal") {}
                        .disabled(true)
                    Spacer()
                    Text("Preview only")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
    }

    @ViewBuilder
    private func emptySection(_ section: BuildReportSection) -> some View {
        if rows.isEmpty {
            ContentUnavailableView(
                "No Matching Rows",
                systemImage: "magnifyingglass",
                description: Text("No build report rows match the current search.")
            )
        } else {
            switch section {
            case .buildTargets:
                ContentUnavailableView(
                    "No Build Targets",
                    systemImage: section.systemImage,
                    description: Text("The selected adapter did not expose build commands.")
                )
            case .generatedArtifacts:
                ContentUnavailableView(
                    "No Generated Artifacts",
                    systemImage: section.systemImage,
                    description: Text("The selected adapter did not expose generated outputs.")
                )
            case .toolchain:
                ContentUnavailableView(
                    "No Toolchain Checks",
                    systemImage: section.systemImage,
                    description: Text("No readiness checks are available.")
                )
            case .healthMatrix:
                ContentUnavailableView(
                    "No Health Matrix Rows",
                    systemImage: section.systemImage,
                    description: Text("No toolchain health rows are available.")
                )
            case .playtest:
                ContentUnavailableView(
                    "No Playtest Plan",
                    systemImage: section.systemImage,
                    description: Text("No emulator handoff is available.")
                )
            case .diagnostics:
                ContentUnavailableView(
                    "No Diagnostics",
                    systemImage: "checkmark.seal",
                    description: Text("The build report has no diagnostics.")
                )
            }
        }
    }

    private var fixtureBuild: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Build")
                    .font(.largeTitle.weight(.semibold))
                Text("\(target.name) targets \(target.romBase)")
                    .foregroundStyle(.secondary)
            }

            EditorSection(title: "Pipeline") {
                VStack(spacing: 10) {
                    ForEach(steps) { step in
                        BuildStepRow(step: step)
                    }
                }
            }

            EditorSection(title: "Actions") {
                HStack {
                    Button("Build", systemImage: "hammer") {}
                    Button("Run", systemImage: "play.fill") {}
                    Button("Validate", systemImage: "checkmark.seal") {}
                    Spacer()
                    Text("Mock controls only")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
    }
}

private struct BuildReportRowView: View {
    let row: BuildReportRow

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: row.section.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 6) {
                Text(row.title)
                    .font(.headline)
                Text(row.subtitle)
                    .foregroundStyle(.secondary)
                Text(row.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                SourceLocationView(source: row.source)
            }

            Spacer()

            StatusPill(state: row.status)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct BuildStepRow: View {
    let step: BuildStep

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            StatusPill(state: step.status)

            VStack(alignment: .leading, spacing: 5) {
                Text(step.name)
                    .font(.headline)
                Text(step.detail)
                    .foregroundStyle(.secondary)
                SourceLocationView(source: step.source)
            }

            Spacer()
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}
