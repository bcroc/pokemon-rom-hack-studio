import AppKit
import PokemonHackCore
import SwiftUI

struct GraphicsWorkbenchView: View {
    @ObservedObject var store: WorkbenchStore
    @State private var authoringPath = ""
    @State private var metatileID = "0"
    @State private var tileEntryIndex = "0"
    @State private var rawTileValue = "0x0000"
    @State private var attributeWordSize = "2"
    @State private var rawAttributeValue = "0x0000"
    @State private var paletteColorIndex = "0"
    @State private var paletteRed = "0"
    @State private var paletteGreen = "0"
    @State private var paletteBlue = "0"

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
                    Text("\(project.title) source-backed tileset, palette, metatile, and animation workspace.")
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

            sourceAuthoringSection(project: project)

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
                        .help("Bulk graphics package imports remain plan-only until a dedicated package executor has preview/apply safeguards.")
                    Button("Convert Plan", systemImage: "wand.and.stars") {}
                        .disabled(true)
                        .help("Bulk conversion remains a dry-run report and does not invoke external tools.")
                    Spacer()
                    Text("Bulk package import and conversion stay preview-only")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
    }

    private func sourceAuthoringSection(project: IndexedProjectSummary) -> some View {
        EditorSection(title: "Source Authoring") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Selected source")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextField("data/tilesets/.../metatiles.bin or palette", text: $authoringPath)
                            .textFieldStyle(.roundedBorder)
                        HStack(spacing: 8) {
                            Button("Use Selected Row", systemImage: "scope") {
                                authoringPath = store.selectedGraphicsReportRow?.source.path ?? ""
                            }
                            .disabled(store.selectedGraphicsReportRow == nil)
                            Text(store.selectedGraphicsReportRow?.source.symbol ?? project.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(minWidth: 260)

                    draftSummary
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], alignment: .leading, spacing: 12) {
                    authoringCard("Metatile Tile Word", systemImage: "square.grid.3x3") {
                        numberField("Metatile", text: $metatileID)
                        numberField("Tile slot 0...7", text: $tileEntryIndex)
                        numberField("Raw word", text: $rawTileValue)
                        Button("Stage Tile Word", systemImage: "plus") {
                            stageMetatileTile()
                        }
                        .disabled(!canStageMetatileTile)
                    }

                    authoringCard("Metatile Attributes", systemImage: "tablecells") {
                        numberField("Metatile", text: $metatileID)
                        numberField("Word size", text: $attributeWordSize)
                        numberField("Raw value", text: $rawAttributeValue)
                        Button("Stage Attributes", systemImage: "plus") {
                            stageMetatileAttribute()
                        }
                        .disabled(!canStageMetatileAttribute)
                    }

                    authoringCard("Palette Color", systemImage: "paintpalette") {
                        numberField("Color index", text: $paletteColorIndex)
                        HStack(spacing: 8) {
                            numberField("R", text: $paletteRed)
                            numberField("G", text: $paletteGreen)
                            numberField("B", text: $paletteBlue)
                        }
                        Button("Stage Palette Color", systemImage: "plus") {
                            stagePaletteColor()
                        }
                        .disabled(!canStagePaletteColor)
                    }
                }

                if let draft = store.selectedGraphicsDraft, !draft.operations.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Staged Operations")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(draft.operations) { operation in
                            HStack(spacing: 10) {
                                Image(systemName: operationIcon(operation.kind))
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(operation.summary)
                                        .font(.caption.weight(.semibold))
                                    Text(operation.path)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                Spacer()
                                Button("Remove", systemImage: "xmark") {
                                    store.removeSelectedGraphicsOperation(id: operation.id)
                                }
                                .labelStyle(.iconOnly)
                                .help("Remove staged graphics edit")
                            }
                            .padding(8)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                    }
                }
            }
        }
    }

    private var draftSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Draft")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(store.selectedGraphicsDraft?.tilesetSymbol ?? "No graphics row selected")
                .font(.callout.weight(.semibold))
                .lineLimit(1)
            Text("\(store.selectedGraphicsDraft?.operations.count ?? 0) staged operation(s)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            Text("Writes are limited to metatiles.bin, metatile_attributes.bin, .pal, and .gbapal source files.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 320, alignment: .leading)
    }

    private func authoringCard<Content: View>(
        _ title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            content()
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func numberField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .textFieldStyle(.roundedBorder)
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

    private var stagedPath: String {
        let trimmed = authoringPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        return store.selectedGraphicsReportRow?.source.path ?? ""
    }

    private var canStageMetatileTile: Bool {
        !stagedPath.isEmpty
            && parsedInt(metatileID) != nil
            && parsedInt(tileEntryIndex) != nil
            && parsedUInt16(rawTileValue) != nil
    }

    private var canStageMetatileAttribute: Bool {
        !stagedPath.isEmpty
            && parsedInt(metatileID) != nil
            && parsedInt(attributeWordSize) != nil
            && parsedUInt32(rawAttributeValue) != nil
    }

    private var canStagePaletteColor: Bool {
        !stagedPath.isEmpty
            && parsedInt(paletteColorIndex) != nil
            && parsedUInt8(paletteRed) != nil
            && parsedUInt8(paletteGreen) != nil
            && parsedUInt8(paletteBlue) != nil
    }

    private func stageMetatileTile() {
        guard
            let metatileLocalID = parsedInt(metatileID),
            let tileEntryIndex = parsedInt(tileEntryIndex),
            let rawTileValue = parsedUInt16(rawTileValue)
        else { return }
        store.stageSelectedGraphicsOperation(
            .metatileTile(
                path: stagedPath,
                metatileLocalID: metatileLocalID,
                tileEntryIndex: tileEntryIndex,
                rawTileValue: rawTileValue
            )
        )
    }

    private func stageMetatileAttribute() {
        guard
            let metatileLocalID = parsedInt(metatileID),
            let wordSize = parsedInt(attributeWordSize),
            let rawAttributeValue = parsedUInt32(rawAttributeValue)
        else { return }
        store.stageSelectedGraphicsOperation(
            .metatileAttribute(
                path: stagedPath,
                metatileLocalID: metatileLocalID,
                rawAttributeValue: rawAttributeValue,
                wordSize: wordSize
            )
        )
    }

    private func stagePaletteColor() {
        guard
            let colorIndex = parsedInt(paletteColorIndex),
            let red = parsedUInt8(paletteRed),
            let green = parsedUInt8(paletteGreen),
            let blue = parsedUInt8(paletteBlue)
        else { return }
        store.stageSelectedGraphicsOperation(
            .paletteColor(
                path: stagedPath,
                colorIndex: colorIndex,
                red: red,
                green: green,
                blue: blue
            )
        )
    }

    private func parsedInt(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("0x") {
            return Int(trimmed.dropFirst(2), radix: 16)
        }
        return Int(trimmed)
    }

    private func parsedUInt16(_ text: String) -> UInt16? {
        guard let value = parsedInt(text), (0...Int(UInt16.max)).contains(value) else { return nil }
        return UInt16(value)
    }

    private func parsedUInt32(_ text: String) -> UInt32? {
        guard let value = parsedInt(text), value >= 0, value <= Int(UInt32.max) else { return nil }
        return UInt32(value)
    }

    private func parsedUInt8(_ text: String) -> UInt8? {
        guard let value = parsedInt(text), (0...Int(UInt8.max)).contains(value) else { return nil }
        return UInt8(value)
    }

    private func operationIcon(_ kind: GraphicsEditOperationKind) -> String {
        switch kind {
        case .metatileTile:
            "square.grid.3x3"
        case .metatileAttribute:
            "tablecells"
        case .paletteColor:
            "paintpalette"
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
