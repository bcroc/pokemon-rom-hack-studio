import AppKit
import SwiftUI

struct BuildWorkbenchView: View {
    @ObservedObject var store: WorkbenchStore

    var body: some View {
        ScrollView {
            if let indexedProject = store.selectedIndexedProject, let report = store.selectedBuildReport {
                indexedBuild(project: indexedProject, report: report)
            } else {
                fixtureBuild
            }
        }
        .navigationTitle("Build/Patch/Playtest")
    }

    private func indexedBuild(
        project: IndexedProjectSummary,
        report: BuildPatchPlaytestReportViewState
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            header(project: project, report: report)
            metrics(report: report)

            HStack(spacing: 12) {
                Picker("Report", selection: $store.selectedBuildWorkbenchTab) {
                    ForEach(BuildWorkbenchTab.allCases) { tab in
                        Label(tab.title, systemImage: tab.systemImage).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                Button("Copy Report JSON", systemImage: "doc.on.doc") {
                    store.copyBuildPatchPlaytestReportJSONToPasteboard()
                }
                .help("Copy the current build, patch, and playtest preview report as JSON")
            }

            switch store.selectedBuildWorkbenchTab {
            case .build:
                buildSections(report: report, rows: store.filteredBuildReportRows)
            case .patch:
                patchSections(buildReport: report, report: store.selectedPatchManifestReport, rows: store.filteredPatchManifestRows)
            case .playtest:
                playtestSections(report: report)
            }
        }
        .padding(24)
    }

    private func header(
        project: IndexedProjectSummary,
        report: BuildPatchPlaytestReportViewState
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Ship Preview")
                    .font(.largeTitle.weight(.semibold))
                Text("\(project.title) guided previews for build readiness, patch checks, generated outputs, toolchain health, and playtest handoff.")
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
    }

    private func metrics(report: BuildPatchPlaytestReportViewState) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
            MetricCard(title: "Build Readiness", value: "\(report.buildTargets.count)", detail: "Preview commands")
            MetricCard(
                title: "Generated",
                value: "\(report.generatedArtifacts.count)",
                detail: "\(report.generatedArtifacts.filter(\.exists).count) present"
            )
            MetricCard(title: "Patch Check", value: store.patchManifestLoadStatus.validationState.rawValue, detail: store.patchManifestLoadStatus.label)
            MetricCard(
                title: "Health Matrix",
                value: "\(report.healthMatrix.warningCount + report.healthMatrix.errorCount)",
                detail: report.healthMatrix.detail
            )
            MetricCard(title: "Playtest Handoff", value: report.playtest.status.rawValue, detail: report.playtest.emulator)
        }
    }

    private func buildSections(
        report: BuildPatchPlaytestReportViewState,
        rows: [BuildReportRow]
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(BuildReportSection.allCases.filter { $0 != .diagnostics && $0 != .patchManifest }) { section in
                let sectionRows = rows.filter { $0.section == section }
                EditorSection(title: section.rawValue) {
                    VStack(spacing: 10) {
                        if sectionRows.isEmpty {
                            emptySection(section, rows: rows)
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

            workflowActions(includePatchActions: false)
        }
    }

    private func patchSections(
        buildReport: BuildPatchPlaytestReportViewState,
        report: PatchManifestReportViewState?,
        rows: [BuildReportRow]
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            EditorSection(title: "Patch Check") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        TextField(
                            "Patch file",
                            text: Binding(
                                get: { store.selectedPatchPath },
                                set: { store.requestPatchPath($0) }
                            )
                        )
                        .textFieldStyle(.roundedBorder)

                        Button("Choose", systemImage: "folder") {
                            choosePatch()
                        }
                        Button("Refresh", systemImage: "arrow.clockwise") {
                            store.loadSelectedPatchManifestReport()
                        }
                        .disabled(store.selectedPatchPath.isEmpty)
                    }

                    HStack(spacing: 8) {
                        Picker(
                            "Base ROM",
                            selection: Binding(
                                get: { store.selectedBaseROMPath },
                                set: { store.requestBaseROMPath($0) }
                            )
                        ) {
                            Text("No base ROM").tag("")
                            ForEach(store.baseROMOptions) { option in
                                Text("\(option.title) - \(option.sourceKind)").tag(option.path)
                            }
                        }
                        .frame(minWidth: 260)

                        TextField(
                            "Base ROM path",
                            text: Binding(
                                get: { store.selectedBaseROMPath },
                                set: { store.requestBaseROMPath($0) }
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                        Button("Choose", systemImage: "folder") {
                            chooseBaseROM()
                        }
                    }

                    HStack {
                        StatusPill(state: store.patchManifestLoadStatus.validationState)
                        Text(store.patchManifestLoadStatus.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }

            if !store.baseROMOptions.isEmpty {
                EditorSection(title: "Base ROM Options") {
                    VStack(spacing: 10) {
                        ForEach(store.baseROMOptions) { option in
                            BaseROMOptionRow(option: option) {
                                store.requestBaseROMPath(option.path)
                            }
                        }
                    }
                }
            }

            EditorSection(title: "Manifest") {
                VStack(spacing: 10) {
                    if rows.filter({ $0.section == .patchManifest }).isEmpty {
                        emptyPatchManifest
                    } else {
                        ForEach(rows.filter { $0.section == .patchManifest }) { row in
                            BuildReportRowView(row: row)
                        }
                    }
                }
            }

            if let report, !report.dryRunPlans.isEmpty {
                EditorSection(title: "Dry-Run Plans") {
                    VStack(spacing: 10) {
                        ForEach(report.dryRunPlans) { plan in
                            PatchDryRunPlanView(plan: plan)
                        }
                    }
                }
            }

            if let report, !report.diagnostics.isEmpty {
                EditorSection(title: "Diagnostics") {
                    VStack(spacing: 10) {
                        ForEach(rows.filter { $0.section == .diagnostics }) { row in
                            BuildReportRowView(row: row)
                        }
                    }
                }
            }

            workflowActions(includePatchActions: true)
        }
    }

    private func playtestSections(report: BuildPatchPlaytestReportViewState) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            EditorSection(title: "Playtest Handoff") {
                VStack(spacing: 10) {
                    BuildReportRowView(row: BuildReportRow(playtest: report.playtest))
                    if report.playtest.artifacts.isEmpty {
                        ContentUnavailableView(
                            "No Planned Artifacts",
                            systemImage: "doc.badge.clock",
                            description: Text("The selected adapter did not expose playtest artifacts.")
                        )
                    } else {
                        ForEach(report.playtest.artifacts) { artifact in
                            PlaytestArtifactRow(artifact: artifact)
                        }
                    }
                }
            }

            if let launchResult = store.selectedPlaytestLaunchResult {
                EditorSection(title: "Launch Result") {
                    VStack(spacing: 10) {
                        BuildReportRowView(row: BuildReportRow(launchResult: launchResult))
                        ForEach(launchResult.artifacts) { artifact in
                            PlaytestArtifactRow(artifact: artifact)
                        }
                    }
                }
            }

            workflowActions(includePatchActions: false)
        }
    }

    @ViewBuilder
    private func emptySection(_ section: BuildReportSection, rows: [BuildReportRow]) -> some View {
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
            case .patchManifest:
                emptyPatchManifest
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

    private var emptyPatchManifest: some View {
        ContentUnavailableView(
            "No Patch Manifest",
            systemImage: BuildReportSection.patchManifest.systemImage,
            description: Text("Choose a patch file and refresh the preview report.")
        )
    }

    private func workflowActions(includePatchActions: Bool) -> some View {
        EditorSection(title: "Actions") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ForEach(store.buildWorkflowActions(includePatchActions: includePatchActions)) { action in
                        workflowButton(action)
                        if action.id == "validate-sources", includePatchActions {
                            Divider()
                        }
                    }
                    Spacer()
                }

                Text("Open Playtest launches a runnable report-selected ROM in mGBA. Build, validate, patch apply, export, conversion, and source-write actions remain locked behind preview/report flows.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func workflowButton(_ action: BuildWorkflowActionViewState) -> some View {
        if action.id == "open-playtest" {
            Button(action.title, systemImage: action.systemImage) {
                store.launchSelectedPlaytest()
            }
            .disabled(!action.isEnabled)
        } else {
            Button(action.title, systemImage: action.isPreviewLocked ? "lock" : action.systemImage) {}
                .disabled(!action.isEnabled)
        }
    }

    private var fixtureActions: some View {
        EditorSection(title: "Actions") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ForEach(store.fixtureBuildWorkflowActions) { action in
                        Button(action.title, systemImage: "lock") {}
                            .disabled(true)
                    }
                    Spacer()
                }

                Text("Fixture preview only")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func choosePatch() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["ips", "bps", "ups", "aps"]
        if panel.runModal() == .OK, let url = panel.url {
            store.requestPatchPath(url.path)
            store.loadSelectedPatchManifestReport()
        }
    }

    private func chooseBaseROM() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["gba"]
        if panel.runModal() == .OK, let url = panel.url {
            store.requestBaseROMPath(url.path)
        }
    }

    private var fixtureBuild: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Ship Preview")
                    .font(.largeTitle.weight(.semibold))
                Text("\(store.selectedTarget.name) targets \(store.selectedTarget.romBase)")
                    .foregroundStyle(.secondary)
            }

            EditorSection(title: "Pipeline") {
                VStack(spacing: 10) {
                    ForEach(store.buildSteps) { step in
                        BuildStepRow(step: step)
                    }
                }
            }

            fixtureActions
        }
        .padding(24)
    }
}

private struct BaseROMOptionRow: View {
    let option: BaseROMOptionViewState
    let select: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "opticaldiscdrive")
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 6) {
                Text(option.title)
                    .font(.headline)
                Text("\(option.subtitle) · \(option.sha1Summary)")
                    .foregroundStyle(.secondary)
                Text(option.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text(option.path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }

            Spacer()

            StatusPill(state: option.status)
            Button("Use", action: select)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct PatchDryRunPlanView: View {
    let plan: PatchDryRunPlanViewState

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "list.clipboard")
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 6) {
                Text(plan.title)
                    .font(.headline)
                ForEach(Array(plan.steps.enumerated()), id: \.offset) { _, step in
                    Text(step)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            StatusPill(state: plan.status)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct PlaytestArtifactRow: View {
    let artifact: PlaytestArtifactViewState

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "doc.badge.clock")
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 6) {
                Text(artifact.kind)
                    .font(.headline)
                Text(artifact.detail)
                    .foregroundStyle(.secondary)
                SourceLocationView(source: artifact.source)
            }

            Spacer()
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
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
