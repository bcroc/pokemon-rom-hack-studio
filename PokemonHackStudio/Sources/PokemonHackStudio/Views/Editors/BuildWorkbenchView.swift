import AppKit
import PokemonHackCore
import SwiftUI
import UniformTypeIdentifiers

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
            if let digest = store.selectedShipPreviewDigest {
                shipPreviewDigestSection(digest)
            }

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

            validationCommandsSection

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
                Text(headerDetail(project: project, report: report))
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

    private func shipPreviewDigestSection(_ digest: ShipPreviewDigestViewState) -> some View {
        EditorSection(title: "Ship Preview Digest") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            StatusPill(state: digest.status)
                            Text(digest.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("Read-only snapshot from loaded app state. It does not re-check, build, patch, playtest, export, or apply binary mutations.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Copy JSON", systemImage: "doc.on.doc") {
                        store.copyShipPreviewDigestJSONToPasteboard()
                    }
                    Button("Copy Markdown", systemImage: "text.page") {
                        store.copyShipPreviewDigestMarkdownToPasteboard()
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 10)], spacing: 10) {
                    ForEach(digest.rows) { row in
                        ShipPreviewDigestRowView(row: row) {
                            store.openShipPreviewDigestRow(row)
                        }
                    }
                }
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
            buildRunnerSection(report: report)

            if report.isNDS {
                ndsToolchainOverview(report: report)
                ndsSemanticCoverageSection(report: store.selectedNDSSemanticCoverageReport, rows: store.filteredNDSSemanticCoverageRows)
                let readinessDigestRows = store.filteredGenVReadinessDigestRows
                if !readinessDigestRows.isEmpty {
                    genVReadinessDigestSection(rows: readinessDigestRows)
                }
                let bridgeRows = store.filteredGenVResourcesToBuildBridgeRows
                if !bridgeRows.isEmpty {
                    genVResourcesToBuildBridgeSection(rows: bridgeRows)
                }
            }

            mapRenderAuditSection(report: store.selectedMapRenderAuditReport, rows: store.filteredMapRenderAuditRows)

            let skippedSections: Set<BuildReportSection> = report.isNDS
                ? [.diagnostics, .mapRenderAudit, .ndsSemanticCoverage, .patchManifest, .healthMatrix]
                : [.diagnostics, .mapRenderAudit, .ndsSemanticCoverage, .patchManifest]
            ForEach(BuildReportSection.allCases.filter { !skippedSections.contains($0) }) { section in
                let sectionRows = rows.filter { $0.section == section }
                EditorSection(title: section.rawValue) {
                    VStack(spacing: 10) {
                        if sectionRows.isEmpty {
                            emptySection(section, rows: rows)
                        } else {
                            ForEach(sectionRows) { row in
                                BuildReportRowView(
                                    row: row,
                                    copyAction: store.copyBuildReportRowActionToPasteboard
                                )
                            }
                        }
                    }
                }
            }

            if !report.diagnostics.isEmpty {
                EditorSection(title: BuildReportSection.diagnostics.rawValue) {
                    VStack(spacing: 10) {
                        ForEach(rows.filter { $0.section == .diagnostics }) { row in
                            BuildReportRowView(
                                row: row,
                                copyAction: store.copyBuildReportRowActionToPasteboard
                            )
                        }
                    }
                }
            }

            workflowActions(includePatchActions: false)
        }
    }

    private func buildRunnerSection(report: BuildPatchPlaytestReportViewState) -> some View {
        EditorSection(title: "Build Runner") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Picker(
                        "Target",
                        selection: Binding(
                            get: { store.selectedEffectiveDecompBuildTargetID },
                            set: { store.selectedDecompBuildTargetID = $0 }
                        )
                    ) {
                        if store.selectedRunnableBuildTargets.isEmpty {
                            Text("No make targets").tag("")
                        } else {
                            ForEach(store.selectedRunnableBuildTargets) { target in
                                Text("\(target.name) - \(target.command)").tag(target.id)
                            }
                        }
                    }
                    .frame(minWidth: 280)

                    if store.runningBuildTargetID == nil {
                        Button("Build", systemImage: "hammer") {
                            store.runSelectedDecompBuild()
                        }
                        .disabled(!store.canRunSelectedDecompBuild)
                        .help(store.buildWorkflowActions(includePatchActions: false).first { $0.id == "build-rom" }?.disabledReason ?? "Run the selected declared make target")
                    } else {
                        Button("Cancel", systemImage: "xmark.circle") {
                            store.cancelSelectedDecompBuild()
                        }
                        .help("Cancel the current build run")
                    }
                    Spacer()
                }

                Text(report.isNDS ? ndsRunnerGuidance : gbaRunnerGuidance)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !store.selectedBuildRunLogLines.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(store.selectedBuildRunLogLines.suffix(12)) { line in
                            HStack(alignment: .top, spacing: 8) {
                                Text(line.stream)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 54, alignment: .leading)
                                Text(line.message)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .padding(10)
                    .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
                }

                if let result = store.selectedBuildRunResult {
                    BuildRunResultView(result: result)
                }
            }
        }
        .onAppear {
            if report.isNDS {
                store.loadSelectedAssetCatalogIfNeeded()
            }
        }
    }

    private func mapRenderAuditSection(
        report: MapRenderAuditReportViewState?,
        rows: [BuildReportRow]
    ) -> some View {
        EditorSection(title: "Map Render Audit") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    StatusPill(state: store.mapRenderAuditLoadStatus.validationState)
                    Text(store.mapRenderAuditLoadStatus.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Re-check", systemImage: "arrow.clockwise") {
                        store.loadSelectedMapRenderAudit()
                    }
                    Button("Copy JSON", systemImage: "doc.on.doc") {
                        store.copyMapRenderAuditJSONToPasteboard()
                    }
                    .disabled(report == nil)
                }

                if let report {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
                        MetricCard(title: "Targets", value: "\(report.targetCount)", detail: "\(report.auditedTargetCount) audited")
                        MetricCard(title: "Maps", value: "\(report.auditedMapCount)", detail: "\(report.mapCount) discovered")
                        MetricCard(title: "Textures", value: "\(report.textureCount)", detail: "Checks")
                        MetricCard(title: "Warnings", value: "\(report.warningBucketCount)", detail: "\(report.warningCount) total")
                        MetricCard(title: "Failures", value: "\(report.failureCount)", detail: report.statusLabel)
                        MetricCard(title: "Skipped", value: "\(report.skippedTargetCount)", detail: "Targets")
                    }

                    if rows.isEmpty {
                        ContentUnavailableView(
                            "No Matching Audit Rows",
                            systemImage: "magnifyingglass",
                            description: Text("No map render audit rows match the current search.")
                        )
                    } else {
                        ForEach(rows) { row in
                            BuildReportRowView(
                                row: row,
                                copyAction: store.copyBuildReportRowActionToPasteboard
                            )
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No Map Render Audit",
                        systemImage: "map",
                        description: Text("Run Re-check to load a read-only selected-project map render audit.")
                    )
                }
            }
        }
    }

    private func ndsSemanticCoverageSection(
        report: NDSSemanticCoverageReportViewState?,
        rows: [BuildReportRow]
    ) -> some View {
        EditorSection(title: "NDS Semantic Coverage") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    StatusPill(state: store.ndsSemanticCoverageLoadStatus.validationState)
                    Text(store.ndsSemanticCoverageLoadStatus.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Refresh", systemImage: "arrow.clockwise") {
                        store.loadSelectedNDSSemanticCoverageReport()
                    }
                    Button("Copy JSON", systemImage: "doc.on.doc") {
                        store.copyNDSSemanticCoverageJSONToPasteboard()
                    }
                    .disabled(report == nil)
                }

                if let report {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
                        MetricCard(title: "Catalog Rows", value: "\(report.catalogRows)", detail: "\(report.scannedRows) scanned")
                        MetricCard(title: "Eligible Rows", value: "\(report.eligibleRows)", detail: "\(report.eligibleFields) fields")
                        MetricCard(title: "Write-Blocked", value: "\(report.blockedRows)", detail: "\(report.bucketCount) buckets")
                        MetricCard(title: "Skipped", value: "\(report.skippedRows)", detail: "\(report.domainCount) domains")
                    }

                    if rows.isEmpty {
                        ContentUnavailableView(
                            "No Matching Coverage Rows",
                            systemImage: "magnifyingglass",
                            description: Text("No NDS semantic coverage rows match the current search.")
                        )
                    } else {
                        ForEach(rows) { row in
                            BuildReportRowView(
                                row: row,
                                copyAction: store.copyBuildReportRowActionToPasteboard
                            )
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No NDS Semantic Coverage",
                        systemImage: "chart.bar.doc.horizontal",
                        description: Text("Refresh to load redacted read-only coverage counts for the selected NDS source root.")
                    )
                }
            }
        }
    }

    private func patchSections(
        buildReport _: BuildPatchPlaytestReportViewState,
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

            patchCreationPreviewSection(
                rows: store.filteredPatchCreationPreviewRows,
                resultRows: store.filteredPatchCreationResultRows
            )
            patchArtifactLibrarySection(rows: store.filteredPatchArtifactLibraryRows)
            patchExportArtifactLibrarySection(rows: store.filteredPatchExportArtifactLibraryRows)
            romMutationArtifactLibrarySection(rows: store.filteredROMMutationArtifactLibraryRows)
            allLearnablesRegenerationReviewSection(rows: store.filteredAllLearnablesRegenerationReviewRows)
            patchDistributionReadinessSection(rows: store.filteredPatchDistributionReadinessRows)
            patchApplyExportAuditSection(rows: store.filteredPatchApplyExportAuditRows)
            binaryROMMutationDryRunSection(
                rows: store.filteredBinaryROMMutationDryRunRows,
                auditRows: store.filteredBinaryROMMutationApplyAuditRows,
                resultRows: store.filteredBinaryROMMutationApplyResultRows
            )

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
                            BuildReportRowView(
                                row: row,
                                copyAction: store.copyBuildReportRowActionToPasteboard
                            )
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
                            BuildReportRowView(
                                row: row,
                                copyAction: store.copyBuildReportRowActionToPasteboard
                            )
                        }
                    }
                }
            }

            workflowActions(includePatchActions: true)
        }
    }

    private func binaryROMMutationDryRunSection(
        rows: [BuildReportRow],
        auditRows: [BuildReportRow],
        resultRows: [BuildReportRow]
    ) -> some View {
        EditorSection(title: "Binary ROM Mutation Review") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    TextField(
                        "GBA ROM path",
                        text: Binding(
                            get: { store.selectedBinaryROMMutationDryRunPath },
                            set: { store.requestBinaryROMMutationDryRunPath($0) }
                        )
                    )
                    .textFieldStyle(.roundedBorder)

                    Button("Choose", systemImage: "folder") {
                        chooseBinaryROMMutationDryRunROM()
                    }
                    Button("Refresh", systemImage: "arrow.clockwise") {
                        store.loadSelectedBinaryROMMutationDryRunManifest()
                    }
                    .disabled(store.selectedBinaryROMMutationDryRunPath.isEmpty)
                    Button("Copy JSON", systemImage: "doc.on.doc") {
                        store.copyBinaryROMMutationDryRunManifestJSONToPasteboard()
                    }
                    .disabled(store.selectedBinaryROMMutationDryRunReport == nil)
                }

                HStack(spacing: 8) {
                    TextField(
                        "Dry-run manifest JSON path",
                        text: Binding(
                            get: { store.selectedBinaryROMMutationDryRunManifestPath },
                            set: { store.requestBinaryROMMutationDryRunManifestPath($0) }
                        )
                    )
                    .textFieldStyle(.roundedBorder)

                    Button("Choose JSON", systemImage: "folder") {
                        chooseBinaryROMMutationDryRunManifestJSON()
                    }
                    Button("Load Review", systemImage: "doc.text.magnifyingglass") {
                        store.loadSelectedBinaryROMMutationDryRunManifestFromJSON()
                    }
                    .disabled(store.selectedBinaryROMMutationDryRunManifestPath.isEmpty)
                    Button("Copy Audit JSON", systemImage: "doc.on.doc") {
                        store.copyBinaryROMMutationApplyAuditJSONToPasteboard()
                    }
                    .disabled(store.selectedBinaryROMMutationApplyAuditReport == nil)
                }

                if !auditRows.isEmpty {
                    Divider()
                    ForEach(auditRows) { row in
                        BuildReportRowView(
                            row: row,
                            copyAction: store.copyBuildReportRowActionToPasteboard
                        )
                    }
                }

                HStack(spacing: 8) {
                    TextField("Review token", text: $store.binaryROMMutationApplyConfirmationToken)
                        .textFieldStyle(.roundedBorder)
                    Button("Apply Reviewed Replacement", systemImage: "checkmark.seal") {
                        store.applySelectedBinaryROMMutationReview()
                    }
                    .disabled(!store.canApplySelectedBinaryROMMutationReview)
                    .help(store.binaryROMMutationApplyDisabledReason ?? "Apply reviewed replace-only byte changes in place")
                }

                HStack(spacing: 8) {
                    StatusPill(state: store.binaryROMMutationDryRunLoadStatus.validationState)
                    Text(store.binaryROMMutationDryRunLoadStatus.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                if rows.isEmpty {
                    ContentUnavailableView(
                        "No Dry-Run Manifest",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("No local .gba is selected.")
                    )
                } else {
                    ForEach(rows.filter { $0.section == .patchManifest }) { row in
                        BuildReportRowView(
                            row: row,
                            copyAction: store.copyBuildReportRowActionToPasteboard
                        )
                    }

                    ForEach(rows.filter { $0.section == .diagnostics }) { row in
                        BuildReportRowView(
                            row: row,
                            copyAction: store.copyBuildReportRowActionToPasteboard
                        )
                    }
                }

                if !resultRows.isEmpty {
                    Divider()
                    ForEach(resultRows) { row in
                        BuildReportRowView(
                            row: row,
                            copyAction: store.copyBuildReportRowActionToPasteboard
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func allLearnablesRegenerationReviewSection(rows: [BuildReportRow]) -> some View {
        if !rows.isEmpty {
            EditorSection(title: "All Learnables Regeneration Review") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Existing compatibility and asset-index facts only; this review surface is copy/report-only.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(rows) { row in
                        BuildReportRowView(
                            row: row,
                            copyAction: store.copyBuildReportRowActionToPasteboard
                        )
                    }
                }
            }
        }
    }

    private func patchArtifactLibrarySection(rows: [BuildReportRow]) -> some View {
        EditorSection(title: "Patch Library") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    StatusPill(state: store.patchArtifactLibraryLoadStatus.validationState)
                    Text(store.patchArtifactLibraryLoadStatus.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Re-check", systemImage: "arrow.clockwise") {
                        store.recheckPatchArtifactLibrary()
                    }
                    Button("Copy JSON", systemImage: "doc.on.doc") {
                        store.copyPatchArtifactLibraryJSONToPasteboard()
                    }
                    .disabled(store.selectedPatchArtifactLibrary == nil)
                    Button("Reveal", systemImage: "folder") {
                        if let item = store.selectedPatchArtifactLibraryItem {
                            store.revealPatchArtifactLibraryItem(item)
                        }
                    }
                    .disabled(store.selectedPatchArtifactLibraryItem?.canReveal != true)
                }

                if let library = store.selectedPatchArtifactLibrary, !library.items.isEmpty {
                    Picker(
                        "Artifact",
                        selection: Binding(
                            get: { store.selectedPatchArtifactLibraryItemID ?? library.items.first?.id ?? "" },
                            set: { store.requestPatchArtifactLibraryItemSelection($0.isEmpty ? nil : $0) }
                        )
                    ) {
                        ForEach(library.items) { item in
                            Text("\(item.title) - \(item.subtitle)").tag(item.id)
                        }
                    }
                    .frame(minWidth: 320)

                    if let selected = store.selectedPatchArtifactLibraryItem {
                        HStack(spacing: 6) {
                            Image(systemName: "checklist")
                            Text(selected.verificationSummary)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                if rows.isEmpty {
                    ContentUnavailableView(
                        "No BPS Patch Artifacts",
                        systemImage: "tray",
                        description: Text("Ignored .pokemonhackstudio/patches/*.bps artifacts will appear here after re-check.")
                    )
                } else {
                    ForEach(rows) { row in
                        BuildReportRowView(
                            row: row,
                            copyAction: store.copyBuildReportRowActionToPasteboard
                        )
                    }
                }
            }
        }
        .onAppear {
            if store.patchArtifactLibraryLoadStatus == .idle {
                store.recheckPatchArtifactLibrary()
            }
            store.loadSelectedAssetCatalogIfNeeded()
        }
    }

    private func patchExportArtifactLibrarySection(rows: [BuildReportRow]) -> some View {
        EditorSection(title: "Patched ROM Export Library") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    StatusPill(state: store.patchExportArtifactLibraryLoadStatus.validationState)
                    Text(store.patchExportArtifactLibraryLoadStatus.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Re-check", systemImage: "arrow.clockwise") {
                        store.recheckPatchExportArtifactLibrary()
                    }
                    Button("Copy JSON", systemImage: "doc.on.doc") {
                        store.copyPatchExportArtifactLibraryJSONToPasteboard()
                    }
                    .disabled(store.selectedPatchExportArtifactLibrary == nil)
                    Button("Reveal", systemImage: "folder") {
                        if let item = store.selectedPatchExportArtifactLibraryItem {
                            store.revealPatchExportArtifactLibraryItem(item)
                        }
                    }
                    .disabled(store.selectedPatchExportArtifactLibraryItem?.canReveal != true)
                }

                if let library = store.selectedPatchExportArtifactLibrary, !library.items.isEmpty {
                    Picker(
                        "Export",
                        selection: Binding(
                            get: { store.selectedPatchExportArtifactLibraryItemID ?? library.items.first?.id ?? "" },
                            set: { store.requestPatchExportArtifactLibraryItemSelection($0.isEmpty ? nil : $0) }
                        )
                    ) {
                        ForEach(library.items) { item in
                            Text("\(item.title) - \(item.subtitle)").tag(item.id)
                        }
                    }
                    .frame(minWidth: 320)

                    if let selected = store.selectedPatchExportArtifactLibraryItem {
                        HStack(spacing: 6) {
                            Image(systemName: "checklist")
                            Text(selected.verificationSummary)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                if rows.isEmpty {
                    ContentUnavailableView(
                        "No Patched ROM Exports",
                        systemImage: "tray",
                        description: Text("Ignored .pokemonhackstudio/patches/*.gba exports will appear here after re-check.")
                    )
                } else {
                    ForEach(rows) { row in
                        BuildReportRowView(
                            row: row,
                            copyAction: store.copyBuildReportRowActionToPasteboard
                        )
                    }
                }
            }
        }
    }

    private func romMutationArtifactLibrarySection(rows: [BuildReportRow]) -> some View {
        EditorSection(title: "ROM Mutation Library") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    StatusPill(state: store.romMutationArtifactLibraryLoadStatus.validationState)
                    Text(store.romMutationArtifactLibraryLoadStatus.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Re-check", systemImage: "arrow.clockwise") {
                        store.recheckROMMutationArtifactLibrary()
                    }
                    Button("Copy JSON", systemImage: "doc.on.doc") {
                        store.copyROMMutationArtifactLibraryJSONToPasteboard()
                    }
                    .disabled(store.selectedROMMutationArtifactLibrary == nil)
                }

                if let library = store.selectedROMMutationArtifactLibrary, !library.items.isEmpty {
                    Picker(
                        "Apply Manifest",
                        selection: Binding(
                            get: { store.selectedROMMutationArtifactLibraryItemID ?? library.items.first?.id ?? "" },
                            set: { store.requestROMMutationArtifactLibraryItemSelection($0.isEmpty ? nil : $0) }
                        )
                    ) {
                        ForEach(library.items) { item in
                            Text("\(item.title) - \(item.subtitle)").tag(item.id)
                        }
                    }
                    .frame(minWidth: 320)

                    if let selected = store.selectedROMMutationArtifactLibraryItem {
                        HStack(spacing: 6) {
                            Image(systemName: "checklist")
                            Text("\(selected.manifestStatus); backup \(selected.backupStatus); \(selected.replacementSummary); \(selected.reviewTokenSummary)")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                if rows.isEmpty {
                    ContentUnavailableView(
                        "No ROM Mutation Apply Manifests",
                        systemImage: "tray",
                        description: Text("Ignored .pokemonhackstudio/rom-mutations/**/apply-manifest.json files will appear here after re-check.")
                    )
                } else {
                    ForEach(rows) { row in
                        BuildReportRowView(
                            row: row,
                            copyAction: store.copyBuildReportRowActionToPasteboard
                        )
                    }
                }
            }
        }
    }

    private func patchDistributionReadinessSection(rows: [BuildReportRow]) -> some View {
        EditorSection(title: "Patch Distribution Readiness") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    StatusPill(state: store.patchDistributionReadinessLoadStatus.validationState)
                    Text(store.patchDistributionReadinessLoadStatus.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Refresh", systemImage: "arrow.clockwise") {
                        store.loadSelectedPatchDistributionReadinessPacket()
                    }
                    .disabled(store.selectedBaseROMPath.isEmpty)
                    Button("Copy JSON", systemImage: "doc.on.doc") {
                        store.copyPatchDistributionReadinessJSONToPasteboard()
                    }
                    .disabled(store.selectedPatchDistributionReadinessReport == nil)
                }

                Picker(
                    "Distribution Patch",
                    selection: Binding(
                        get: { store.selectedPatchDistributionReadinessPatchPath },
                        set: { store.requestPatchDistributionReadinessPatchSelection($0) }
                    )
                ) {
                    Text("No patch selected").tag("")
                    ForEach(store.selectedPatchArtifactLibrary?.items ?? []) { item in
                        Text("\(item.title) - \(item.subtitle)").tag(item.patchPath)
                    }
                }
                .frame(minWidth: 320)

                if rows.isEmpty {
                    ContentUnavailableView(
                        "No Readiness Packet",
                        systemImage: "shippingbox",
                        description: Text("Select a base ROM and explicit BPS artifact, then refresh.")
                    )
                } else {
                    ForEach(rows) { row in
                        BuildReportRowView(
                            row: row,
                            copyAction: store.copyBuildReportRowActionToPasteboard
                        )
                    }
                }
            }
        }
    }

    private func patchApplyExportAuditSection(rows: [BuildReportRow]) -> some View {
        EditorSection(title: "Patch Apply/Export Audit") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    StatusPill(state: store.patchApplyExportAuditLoadStatus.validationState)
                    Text(store.patchApplyExportAuditLoadStatus.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Refresh", systemImage: "arrow.clockwise") {
                        store.loadSelectedPatchApplyExportAudit()
                    }
                    .disabled(store.selectedPatchPath.isEmpty || store.selectedBaseROMPath.isEmpty)
                    Button("Copy JSON", systemImage: "doc.on.doc") {
                        store.copyPatchApplyExportAuditJSONToPasteboard()
                    }
                    .disabled(store.selectedPatchApplyExportAuditReport == nil)
                }

                if rows.isEmpty {
                    ContentUnavailableView(
                        "No Apply/Export Audit",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Select a patch and base ROM, then refresh.")
                    )
                } else {
                    ForEach(rows) { row in
                        BuildReportRowView(
                            row: row,
                            copyAction: store.copyBuildReportRowActionToPasteboard
                        )
                    }
                }
            }
        }
    }

    private func patchCreationPreviewSection(
        rows: [BuildReportRow],
        resultRows: [BuildReportRow]
    ) -> some View {
        EditorSection(title: "Patch Creation Preview") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    StatusPill(state: store.patchCreationPreviewLoadStatus.validationState)
                    Text(store.patchCreationPreviewLoadStatus.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Preview Patch Creation", systemImage: "eye") {
                        store.loadSelectedPatchCreationPreview()
                    }
                    .disabled(store.selectedBaseROMPath.isEmpty)
                    Button("Create BPS Patch", systemImage: "square.and.arrow.down") {
                        store.createSelectedBPSPatch()
                    }
                    .disabled(!store.canCreateSelectedBPSPatch)
                    .help(store.createBPSPatchDisabledReason)
                }

                HStack(spacing: 6) {
                    Image(systemName: "hammer")
                    Text(store.selectedEffectiveDecompBuildTargetID.isEmpty ? "Target: auto" : "Target: \(store.selectedEffectiveDecompBuildTargetID)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if rows.isEmpty {
                    ContentUnavailableView(
                        "No Patch Creation Preview",
                        systemImage: "doc.badge.clock",
                        description: Text("Preview rows will appear here.")
                    )
                } else {
                    ForEach(rows) { row in
                        BuildReportRowView(
                            row: row,
                            copyAction: store.copyBuildReportRowActionToPasteboard
                        )
                    }
                }

                if !resultRows.isEmpty {
                    Divider()
                    ForEach(resultRows) { row in
                        BuildReportRowView(
                            row: row,
                            copyAction: store.copyBuildReportRowActionToPasteboard
                        )
                    }
                }
            }
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
                            description: Text(report.isNDS ? "NDS emulator readiness is manual-only in this slice; the app does not create melonDS or DeSmuME launch artifacts." : "The selected adapter did not expose playtest artifacts.")
                        )
                    } else {
                        ForEach(report.playtest.artifacts) { artifact in
                            PlaytestArtifactRow(artifact: artifact)
                        }
                    }
                }
            }

            EditorSection(title: "Debug And Access-Log Plan") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        StatusPill(state: report.playtestDebug.status)
                        Text(report.playtestDebug.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    if !report.playtestDebug.command.isEmpty {
                        Text(report.playtestDebug.command)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
                    }

                    ForEach(report.playtestDebug.capabilities) { capability in
                        BuildReportRowView(
                            row: BuildReportRow(debugCapability: capability),
                            copyAction: store.copyBuildReportRowActionToPasteboard
                        )
                    }

                    ForEach(report.playtestDebug.artifacts) { artifact in
                        PlaytestArtifactRow(artifact: artifact)
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

            if let captureResult = store.selectedPlaytestCaptureResult {
                EditorSection(title: "Capture Result") {
                    VStack(spacing: 10) {
                        BuildReportRowView(row: BuildReportRow(captureResult: captureResult))
                        if let artifact = captureResult.primaryArtifact {
                            LatestPlaytestCaptureCard(
                                artifact: artifact,
                                open: { store.openPlaytestArtifact(artifact) },
                                reveal: { store.revealPlaytestArtifact(artifact) }
                            )
                        }
                        ForEach(captureResult.artifacts) { artifact in
                            PlaytestArtifactRow(
                                artifact: artifact,
                                open: { store.openPlaytestArtifact(artifact) },
                                reveal: { store.revealPlaytestArtifact(artifact) }
                            )
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
            case .mapRenderAudit:
                ContentUnavailableView(
                    "No Map Render Audit Rows",
                    systemImage: section.systemImage,
                    description: Text("Run Re-check to load the selected-project audit.")
                )
            case .ndsSemanticCoverage:
                ContentUnavailableView(
                    "No NDS Semantic Coverage Rows",
                    systemImage: section.systemImage,
                    description: Text("Refresh NDS semantic coverage to load redacted counts.")
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

                Text(selectedWorkflowGuidance)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func headerDetail(project: IndexedProjectSummary, report: BuildPatchPlaytestReportViewState) -> String {
        if report.isNDS {
            return "\(project.title) NDS toolchain readiness, manual setup guidance, header facts, and declared-output checks. Build, extraction, emulator launch, and ROM writes stay disabled."
        }
        return "\(project.title) guided previews for build readiness, patch checks, generated outputs, toolchain health, and playtest handoff."
    }

    private var selectedWorkflowGuidance: String {
        if store.selectedBuildReport?.isNDS == true {
            return "NDS actions are manual setup and rerun guidance only. PokemonHackStudio does not install tools, run Docker, build NDS ROMs, launch melonDS/DeSmuME, extract assets, apply mutation plans, export ROMs, or write binary/source outputs from this surface."
        }
        return "Build runs only the selected declared make target. Open Playtest and capture actions use mGBA handoffs. Patched-ROM artifact actions write ignored ROM artifacts only after a compatible patch and manifest-matched base ROM are selected; conversion and source-write actions stay locked."
    }

    private var gbaRunnerGuidance: String {
        "Runs only the selected declared decomp make target. Source edits, conversion, and repair actions remain outside this runner."
    }

    private var ndsRunnerGuidance: String {
        "NDS builds are preview-only here. Use the toolchain rows for detected paths, copyable manual commands, and rerun guidance; PokemonHackStudio will not run make, Meson, Ninja, Docker, extraction, or rebuild steps for NDS projects."
    }

    private func ndsToolchainOverview(report: BuildPatchPlaytestReportViewState) -> some View {
        EditorSection(title: "NDS Toolchain Health") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    StatusPill(state: report.healthMatrix.status)
                    Text("\(report.healthMatrix.readyCount) ready")
                        .font(.caption.weight(.semibold))
                    Text("\(report.healthMatrix.warningCount) warnings")
                        .font(.caption.weight(.semibold))
                    Text("\(report.healthMatrix.notApplicableCount) not applicable")
                        .font(.caption.weight(.semibold))
                    Spacer()
                }

                Text("Preview-only NDS readiness: detected paths and copyable manual setup/rerun guidance only. No installs, builds, Docker runs, extraction, emulator launch, mutation apply, ROM export, or binary/source writes are performed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(report.healthMatrix.ndsGroups) { group in
                    NDSToolchainHealthGroupView(
                        group: group,
                        copyAction: store.copyBuildReportRowActionToPasteboard
                    )
                }
            }
        }
    }

    private func genVResourcesToBuildBridgeSection(rows: [BuildReportRow]) -> some View {
        EditorSection(title: "Gen V Resources-To-Build Bridge") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Button("Selected Resource", systemImage: "arrow.right.circle") {
                        store.focusSelectedGenVResourcesToBuildBridgeAsset()
                    }
                    Button("Freshness Packet", systemImage: "doc.text.magnifyingglass") {
                        store.focusGenVGeneratedOutputFreshnessPacketForBridge()
                    }
                    Button("Build Readiness", systemImage: "hammer") {
                        store.focusGenVManualBuildReadinessForBridge()
                    }
                    Spacer()
                }

                ForEach(rows) { row in
                    BuildReportRowView(
                        row: row,
                        copyAction: store.copyBuildReportRowActionToPasteboard
                    )
                }
            }
        }
    }

    private func genVReadinessDigestSection(rows: [BuildReportRow]) -> some View {
        EditorSection(title: "Gen V Readiness Digest") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(rows) { row in
                    BuildReportRowView(
                        row: row,
                        copyAction: store.copyBuildReportRowActionToPasteboard
                    )
                }
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
            .help(action.disabledReason ?? "Launch the runnable playtest handoff")
        } else if action.id == "build-rom" {
            Button(action.title, systemImage: action.systemImage) {
                store.runSelectedDecompBuild()
            }
            .disabled(!action.isEnabled)
            .help(action.disabledReason ?? "Run the selected declared make target")
        } else if action.id == "cancel-build" {
            Button(action.title, systemImage: action.systemImage) {
                store.cancelSelectedDecompBuild()
            }
            .disabled(!action.isEnabled)
            .help(action.disabledReason ?? "Cancel the current build run")
        } else if action.id == "capture-screenshot" {
            Button(action.title, systemImage: action.systemImage) {
                store.captureSelectedPlaytest(kind: .screenshot)
            }
            .disabled(!action.isEnabled)
            .help(action.disabledReason ?? "Capture the current playtest screenshot artifact")
        } else if action.id == "capture-savestate" {
            Button(action.title, systemImage: action.systemImage) {
                store.captureSelectedPlaytest(kind: .saveState)
            }
            .disabled(!action.isEnabled)
            .help(action.disabledReason ?? "Capture the current playtest savestate artifact")
        } else if action.id == "apply-patch" || action.id == "export-rom" {
            Button(action.title, systemImage: action.systemImage) {
                store.applyExportSelectedPatchROM()
            }
            .disabled(!action.isEnabled)
            .help(action.disabledReason ?? "Write the selected patched ROM artifact")
        } else {
            Button(action.title, systemImage: action.isPreviewLocked ? "lock" : action.systemImage) {}
                .disabled(!action.isEnabled)
                .help(action.disabledReason ?? "Action unavailable")
        }
    }

    private var fixtureActions: some View {
        EditorSection(title: "Actions") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ForEach(store.fixtureBuildWorkflowActions) { action in
                        Button(action.title, systemImage: "lock") {}
                            .disabled(true)
                            .help(action.disabledReason ?? "Read-only fixture preview")
                    }
                    Spacer()
                }

                Text("Read-only fixture preview")
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
        panel.allowedContentTypes = Self.contentTypes(for: ["ips", "bps", "ups", "aps"])
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
        panel.allowedContentTypes = Self.contentTypes(for: ["gba"])
        if panel.runModal() == .OK, let url = panel.url {
            store.requestBaseROMPath(url.path)
        }
    }

    private func chooseBinaryROMMutationDryRunROM() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = Self.contentTypes(for: ["gba"])
        if panel.runModal() == .OK, let url = panel.url {
            store.requestBinaryROMMutationDryRunPath(url.path)
            store.loadSelectedBinaryROMMutationDryRunManifest()
        }
    }

    private func chooseBinaryROMMutationDryRunManifestJSON() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = Self.contentTypes(for: ["json"])
        if panel.runModal() == .OK, let url = panel.url {
            store.requestBinaryROMMutationDryRunManifestPath(url.path)
            store.loadSelectedBinaryROMMutationDryRunManifestFromJSON()
        }
    }

    private static func contentTypes(for filenameExtensions: [String]) -> [UTType] {
        filenameExtensions.compactMap { UTType(filenameExtension: $0) }
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

            validationCommandsSection
            fixtureActions
        }
        .padding(24)
    }

    private var validationCommandsSection: some View {
        EditorSection(title: "Validation Commands") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 10)], spacing: 10) {
                ForEach(store.validationTierCommandRows) { row in
                    ValidationTierCommandRowView(
                        row: row,
                        copy: { store.copyValidationTierCommandToPasteboard(row) }
                    )
                }
            }
        }
    }
}

private struct ShipPreviewDigestRowView: View {
    let row: ShipPreviewDigestRow
    let open: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: row.area.systemImage)
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

            VStack(alignment: .trailing, spacing: 8) {
                StatusPill(state: row.status)
                Button("Open", systemImage: "arrow.right.circle") {
                    open()
                }
                .help("Open \(row.area.title) in \(row.targetTab.title)")
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
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
    var open: (() -> Void)? = nil
    var reveal: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: artifact.isPrimaryCaptureArtifact ? "photo.on.rectangle" : "doc.badge.clock")
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

            if artifact.canOpenOrReveal {
                HStack(spacing: 6) {
                    Button("Open", systemImage: "arrow.up.right.square") {
                        open?()
                    }
                    .labelStyle(.iconOnly)
                    .help("Open artifact")

                    Button("Reveal", systemImage: "folder") {
                        reveal?()
                    }
                    .labelStyle(.iconOnly)
                    .help("Reveal in Finder")
                }
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct LatestPlaytestCaptureCard: View {
    let artifact: PlaytestArtifactViewState
    let open: () -> Void
    let reveal: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: artifact.kind == "screenshot" ? "photo" : "square.and.arrow.down")
                .foregroundStyle(.blue)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 6) {
                Text("Latest Capture")
                    .font(.headline)
                Text(artifact.path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                Text(artifact.detail)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 6) {
                Button("Open", systemImage: "arrow.up.right.square", action: open)
                    .labelStyle(.iconOnly)
                    .disabled(!artifact.canOpenOrReveal)
                    .help("Open latest capture")

                Button("Reveal", systemImage: "folder", action: reveal)
                    .labelStyle(.iconOnly)
                    .disabled(!artifact.canOpenOrReveal)
                    .help("Reveal latest capture in Finder")
            }
        }
        .padding(12)
        .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.blue.opacity(0.25), lineWidth: 1)
        )
    }
}

private struct BuildRunResultView: View {
    let result: BuildRunResultViewState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StatusPill(state: result.status)
                Text(result.title)
                    .font(.headline)
                Text(result.processID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(result.exitCode)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(result.outputDetail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            ForEach(result.artifacts) { artifact in
                HStack(spacing: 8) {
                    Image(systemName: artifact.exists ? "doc.text" : "doc.badge.clock")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(artifact.path)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                        Text(artifact.detail)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }

            if !result.diagnostics.isEmpty {
                ForEach(result.diagnostics) { diagnostic in
                    HStack(alignment: .top, spacing: 8) {
                        StatusPill(state: diagnostic.severity)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(diagnostic.title)
                                .font(.caption.weight(.semibold))
                            Text(diagnostic.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct BuildReportRowView: View {
    let row: BuildReportRow
    var copyAction: (BuildReportRowAction) -> Void = { _ in }

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
                if !row.actions.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(row.actions) { action in
                            BuildReportActionRow(
                                action: action,
                                copy: { copyAction(action) }
                            )
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()

            StatusPill(state: row.status)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct NDSToolchainHealthGroupView: View {
    let group: NDSToolchainHealthGroupViewState
    let copyAction: (BuildReportRowAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                StatusPill(state: group.status)
                Text(group.title)
                    .font(.headline)
                Text("\(group.readyCount) ready · \(group.warningCount) warnings · \(group.notApplicableCount) not applicable")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(group.detail)
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(group.rows) { row in
                BuildReportRowView(row: row, copyAction: copyAction)
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct BuildReportActionRow: View {
    let action: BuildReportRowAction
    let copy: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(action.kind.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text(action.title)
                    .font(.caption.weight(.semibold))
                Text(action.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let value = action.copyValue {
                    Text(value)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            Spacer(minLength: 8)
            if action.copyValue != nil {
                Button("Copy", systemImage: "doc.on.doc") {
                    copy()
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .help("Copy \(action.kind.rawValue.lowercased())")
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ValidationTierCommandRowView: View {
    let row: ValidationTierCommandRow
    let copy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(row.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Button(row.runStateTitle, systemImage: "terminal") {}
                    .disabled(!row.canRunInApp)
                    .help(row.disabledReason)
            }

            HStack(spacing: 8) {
                Text(row.command)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)

                Spacer(minLength: 8)

                Button("Copy", systemImage: "doc.on.doc") {
                    copy()
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .disabled(!row.canCopyCommand)
                .help("Copy validation command")
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(row.strictnessTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(row.strictnessDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text(row.skippedReferenceCauseSummary)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(3)
            }
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
