import AppKit
import SwiftUI

struct GraphicsWorkbenchView: View {
    @ObservedObject var store: WorkbenchStore

    var body: some View {
        ScrollView {
            if let indexedProject = store.selectedIndexedProject, let report = store.selectedGraphicsReport {
                indexedGraphics(project: indexedProject, report: report)
            } else {
                fixtureGraphics
            }
        }
        .navigationTitle("Graphics")
    }

    private func indexedGraphics(
        project: IndexedProjectSummary,
        report: GraphicsDiagnosticsReportViewState
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Graphics")
                        .font(.largeTitle.weight(.semibold))
                    Text("\(project.title) read-only tileset, palette, metatile, and animation diagnostics.")
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
                MetricCard(title: "Tilesets", value: "\(report.tilesetCount)", detail: report.readOnlyDetail)
                MetricCard(title: "Tile Images", value: "\(report.tileImageCount)", detail: "Inventory under data/tilesets")
                MetricCard(title: "Palettes", value: "\(report.paletteFileCount)", detail: "JASC and GBA palette files")
                MetricCard(title: "Animations", value: "\(report.animationDirectoryCount)", detail: "Animation source folders")
                MetricCard(title: "Local Assets", value: "\(report.unsupportedSourceArtifactCount)", detail: "Design/archive files")
            }

            packagePlanControls(project: project)

            if let plan = store.selectedGraphicsImportPackagePlan {
                packagePlanSections(plan: plan)
            }

            ForEach(GraphicsReportSection.allCases.filter { $0 != .diagnostics }) { section in
                let sectionRows = store.filteredGraphicsReportRows.filter { $0.section == section }
                EditorSection(title: section.rawValue) {
                    VStack(spacing: 10) {
                        if sectionRows.isEmpty {
                            emptySection(section)
                        } else {
                            ForEach(sectionRows) { row in
                                GraphicsReportRowView(row: row)
                            }
                        }
                    }
                }
            }

            if !report.diagnostics.isEmpty {
                EditorSection(title: GraphicsReportSection.diagnostics.rawValue) {
                    VStack(spacing: 10) {
                        ForEach(store.filteredGraphicsReportRows.filter { $0.section == .diagnostics }) { row in
                            GraphicsReportRowView(row: row)
                        }
                    }
                }
            }

            EditorSection(title: "Actions") {
                HStack {
                    Button("Import Plan", systemImage: "square.and.arrow.down") {}
                        .disabled(true)
                        .help("Graphics import packages are preview-only and require provenance before any future write path.")
                    Button("Convert Plan", systemImage: "wand.and.stars") {}
                        .disabled(true)
                        .help("Conversion remains a dry-run report and does not invoke external tools.")
                    Button("Apply", systemImage: "checkmark.seal") {}
                        .disabled(true)
                        .help("Graphics writes are disabled until an explicit mutation-plan apply path is implemented.")
                    Spacer()
                    Text("Preview only")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
    }

    private func packagePlanControls(project: IndexedProjectSummary) -> some View {
        EditorSection(title: "Import Package Preview") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    TextField(
                        "Graphics package folder",
                        text: Binding(
                            get: { store.selectedGraphicsImportPackagePath },
                            set: { store.requestGraphicsImportPackagePath($0) }
                        )
                    )
                    .textFieldStyle(.roundedBorder)

                    Button("Choose", systemImage: "folder") {
                        choosePackage()
                    }

                    Button("Refresh", systemImage: "arrow.clockwise") {
                        store.loadSelectedGraphicsImportPackagePlan()
                    }
                    .disabled(store.selectedGraphicsImportPackagePath.isEmpty)

                    Button("Copy Plan JSON", systemImage: "doc.on.doc") {
                        store.copyGraphicsImportPackagePlanJSONToPasteboard()
                    }
                    .disabled(store.selectedGraphicsImportPackagePlan == nil)
                }

                HStack(spacing: 8) {
                    StatusPill(state: store.graphicsImportPackagePlanStatus.validationState)
                    Text(store.graphicsImportPackagePlanStatus.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(project.rootPath)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
    }

    private func packagePlanSections(plan: GraphicsImportPackagePlanViewState) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
                MetricCard(title: "Package", value: plan.packageTitle, detail: plan.packageRootPath)
                MetricCard(title: "Readiness", value: plan.readiness.capitalized, detail: plan.isPreviewOnly ? "Preview-only plan" : "Review write policy")
                MetricCard(title: "Inventory", value: "\(plan.inventoryRows.count)", detail: "\(plan.creditMetadataRows.count) credit metadata file(s)")
                MetricCard(title: "Copy Targets", value: "\(plan.copyTargets.count)", detail: "\(plan.copyTargets.filter(\.willOverwriteExistingSource).count) overwrite flag(s)")
                MetricCard(title: "Palette Fit", value: "\(plan.paletteFitPreviews.count)", detail: "4bpp readiness previews")
                MetricCard(title: "Expected Outputs", value: "\(plan.expectedOutputs.count)", detail: "Dry-run generated artifacts")
            }

            EditorSection(title: "Package Inventory") {
                planList(rows: plan.inventoryRows) { row in
                    GraphicsImportInventoryRowView(row: row)
                }
            }

            EditorSection(title: "Credit Metadata") {
                planList(rows: plan.creditMetadataRows) { row in
                    GraphicsImportInventoryRowView(row: row)
                }
            }

            EditorSection(title: "Copy Targets") {
                planList(rows: plan.copyTargets) { target in
                    GraphicsImportCopyTargetRowView(target: target)
                }
            }

            EditorSection(title: "Layered Dry Run") {
                GraphicsImportLayeredDryRunView(dryRun: plan.layeredDryRun)
            }

            EditorSection(title: "Palette Fit Previews") {
                planList(rows: plan.paletteFitPreviews) { preview in
                    GraphicsImportPaletteFitRowView(preview: preview)
                }
            }

            EditorSection(title: "Expected Outputs") {
                if plan.expectedOutputs.isEmpty {
                    ContentUnavailableView(
                        "No Expected Outputs",
                        systemImage: "shippingbox",
                        description: Text("The loaded package did not infer generated graphics artifacts.")
                    )
                } else {
                    VStack(spacing: 8) {
                        ForEach(plan.expectedOutputs, id: \.self) { output in
                            GraphicsPlanPathRow(systemImage: "shippingbox", title: output, detail: "Generated output preview")
                        }
                    }
                }
            }

            if !plan.diagnostics.isEmpty {
                EditorSection(title: "Import Package Diagnostics") {
                    VStack(spacing: 10) {
                        ForEach(plan.diagnostics) { diagnostic in
                            GraphicsPlanDiagnosticRowView(diagnostic: diagnostic)
                        }
                    }
                }
            }
        }
    }

    private func planList<Rows: RandomAccessCollection, Content: View>(
        rows: Rows,
        @ViewBuilder content: @escaping (Rows.Element) -> Content
    ) -> some View where Rows.Element: Identifiable {
        VStack(spacing: 10) {
            if rows.isEmpty {
                ContentUnavailableView(
                    "No Rows",
                    systemImage: "tray",
                    description: Text("The current package plan does not expose rows for this section.")
                )
            } else {
                ForEach(rows) { row in
                    content(row)
                }
            }
        }
    }

    @ViewBuilder
    private func emptySection(_ section: GraphicsReportSection) -> some View {
        if store.filteredGraphicsReportRows.isEmpty {
            ContentUnavailableView(
                "No Matching Rows",
                systemImage: "magnifyingglass",
                description: Text("No graphics diagnostics match the current search.")
            )
        } else {
            ContentUnavailableView(
                "No \(section.rawValue)",
                systemImage: section.systemImage,
                description: Text("The selected project did not expose rows for this section.")
            )
        }
    }

    private func choosePackage() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            store.requestGraphicsImportPackagePath(url.path)
            store.loadSelectedGraphicsImportPackagePlan()
        }
    }

    private var fixtureGraphics: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Graphics")
                    .font(.largeTitle.weight(.semibold))
                Text("Open a supported project to inspect tilesets, palettes, metatiles, and animation sources.")
                    .foregroundStyle(.secondary)
            }

            EditorSection(title: "Diagnostics") {
                ContentUnavailableView(
                    "No Project Loaded",
                    systemImage: WorkbenchModule.graphics.systemImage,
                    description: Text("Graphics diagnostics are read-only and appear after a supported source tree is selected.")
                )
            }
        }
        .padding(24)
    }
}

private struct GraphicsImportInventoryRowView: View {
    let row: GraphicsImportInventoryRowViewState

    var body: some View {
        GraphicsPlanRow(
            systemImage: "doc",
            title: row.title,
            subtitle: row.subtitle,
            detail: row.detail,
            status: row.status,
            source: row.source
        )
    }
}

private struct GraphicsImportCopyTargetRowView: View {
    let target: GraphicsImportCopyTargetViewState

    var body: some View {
        GraphicsPlanRow(
            systemImage: target.willOverwriteExistingSource ? "exclamationmark.arrow.triangle.2.circlepath" : "arrow.right.doc.on.clipboard",
            title: target.title,
            subtitle: target.subtitle,
            detail: target.detail,
            status: target.status,
            source: target.source
        )
    }
}

private struct GraphicsImportLayeredDryRunView: View {
    let dryRun: GraphicsImportLayeredDryRunViewState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GraphicsPlanRow(
                systemImage: "square.stack.3d.up",
                title: dryRun.title,
                subtitle: dryRun.status.rawValue,
                detail: "\(dryRun.detail) \(dryRun.externalToolPlan)",
                status: dryRun.status,
                source: nil
            )

            if !dryRun.detectedLayerPaths.isEmpty {
                pathGroup(title: "Detected Layers", paths: dryRun.detectedLayerPaths, systemImage: "photo")
            }

            if !dryRun.missingLayerNames.isEmpty {
                pathGroup(title: "Missing Layers", paths: dryRun.missingLayerNames, systemImage: "exclamationmark.triangle")
            }

            if let attributesPath = dryRun.attributesPath {
                GraphicsPlanPathRow(systemImage: "tablecells", title: attributesPath, detail: "Attributes source")
            }

            if !dryRun.expectedGeneratedOutputs.isEmpty {
                pathGroup(title: "Dry-Run Outputs", paths: dryRun.expectedGeneratedOutputs, systemImage: "shippingbox")
            }
        }
    }

    private func pathGroup(title: String, paths: [String], systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(paths, id: \.self) { path in
                GraphicsPlanPathRow(systemImage: systemImage, title: path, detail: title)
            }
        }
    }
}

private struct GraphicsImportPaletteFitRowView: View {
    let preview: GraphicsImportPaletteFitPreviewViewState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GraphicsPlanRow(
                systemImage: "paintpalette",
                title: preview.title,
                subtitle: preview.status.rawValue,
                detail: preview.detail,
                status: preview.status,
                source: preview.source
            )

            ForEach(preview.diagnostics) { diagnostic in
                GraphicsPlanDiagnosticRowView(diagnostic: diagnostic)
            }
        }
    }
}

private struct GraphicsPlanPathRow: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.callout, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct GraphicsPlanDiagnosticRowView: View {
    let diagnostic: IndexedDiagnosticRow

    var body: some View {
        GraphicsPlanRow(
            systemImage: "exclamationmark.triangle",
            title: diagnostic.title,
            subtitle: diagnostic.source.path,
            detail: diagnostic.message,
            status: diagnostic.severity,
            source: diagnostic.source
        )
    }
}

private struct GraphicsPlanRow: View {
    let systemImage: String
    let title: String
    let subtitle: String
    let detail: String
    let status: ValidationState
    let source: SourceLocation?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .textSelection(.enabled)
                Text(subtitle)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let source {
                    SourceLocationView(source: source)
                }
            }

            Spacer()

            StatusPill(state: status)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct GraphicsReportRowView: View {
    let row: GraphicsReportRow

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
