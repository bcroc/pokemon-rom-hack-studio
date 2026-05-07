import AppKit
import SwiftUI

struct BuildWorkbenchView: View {
    @ObservedObject var store: WorkbenchStore
    @State private var selectedTab: BuildWorkbenchTab = .build

    var body: some View {
        ScrollView {
            if let indexedProject = store.selectedIndexedProject, let report = store.selectedBuildReport {
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
            header(project: project, report: report)
            metrics(report: report)

            Picker("Report", selection: $selectedTab) {
                ForEach(BuildWorkbenchTab.allCases) { tab in
                    Label(tab.title, systemImage: tab.systemImage).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            switch selectedTab {
            case .build:
                buildSections(report: report, rows: store.filteredBuildReportRows)
            case .patch:
                patchSections(report: store.selectedPatchManifestReport, rows: store.filteredPatchManifestRows)
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
                Text("Build")
                    .font(.largeTitle.weight(.semibold))
                Text("\(project.title) readiness report for builds, patches, generated outputs, toolchain health, and playtest handoff.")
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
            MetricCard(title: "Build Targets", value: "\(report.buildTargets.count)", detail: "Preview commands")
            MetricCard(
                title: "Generated",
                value: "\(report.generatedArtifacts.count)",
                detail: "\(report.generatedArtifacts.filter(\.exists).count) present"
            )
            MetricCard(title: "Patch", value: store.patchManifestLoadStatus.validationState.rawValue, detail: store.patchManifestLoadStatus.label)
            MetricCard(
                title: "Health Matrix",
                value: "\(report.healthMatrix.warningCount + report.healthMatrix.errorCount)",
                detail: report.healthMatrix.detail
            )
            MetricCard(title: "Playtest", value: report.playtest.status.rawValue, detail: report.playtest.emulator)
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

            previewActions(includePatchActions: false)
        }
    }

    private func patchSections(
        report: PatchManifestReportViewState?,
        rows: [BuildReportRow]
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            EditorSection(title: "Patch") {
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

                        TextField("Base ROM path", text: $store.selectedBaseROMPath)
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
                        Button("Copy Report JSON", systemImage: "doc.on.doc") {
                            store.copyBuildPatchPlaytestReportJSONToPasteboard()
                        }
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

            previewActions(includePatchActions: true)
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

            previewActions(includePatchActions: false)
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

    private func previewActions(includePatchActions: Bool) -> some View {
        EditorSection(title: "Actions") {
            HStack {
                Button("Build", systemImage: "hammer") {}
                    .disabled(true)
                Button("Run", systemImage: "play.fill") {}
                    .disabled(true)
                Button("Validate", systemImage: "checkmark.seal") {}
                    .disabled(true)
                if includePatchActions {
                    Divider()
                    Button("Apply Patch", systemImage: "wand.and.stars") {}
                        .disabled(true)
                    Button("Export ROM", systemImage: "square.and.arrow.down") {}
                        .disabled(true)
                }
                Spacer()
                Text("Preview only")
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
                Text("Build")
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

private enum BuildWorkbenchTab: String, CaseIterable, Identifiable {
    case build
    case patch
    case playtest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .build: "Build"
        case .patch: "Patch"
        case .playtest: "Playtest"
        }
    }

    var systemImage: String {
        switch self {
        case .build: "hammer"
        case .patch: "doc.badge.gearshape"
        case .playtest: "gamecontroller"
        }
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
