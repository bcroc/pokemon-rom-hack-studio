import SwiftUI

struct GraphicsWorkbenchView: View {
    let indexedProject: IndexedProjectSummary?
    let report: GraphicsDiagnosticsReportViewState?
    let rows: [GraphicsReportRow]

    var body: some View {
        ScrollView {
            if let indexedProject, let report {
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

            ForEach(GraphicsReportSection.allCases.filter { $0 != .diagnostics }) { section in
                let sectionRows = rows.filter { $0.section == section }
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
                        ForEach(rows.filter { $0.section == .diagnostics }) { row in
                            GraphicsReportRowView(row: row)
                        }
                    }
                }
            }

            EditorSection(title: "Actions") {
                HStack {
                    Button("Import", systemImage: "square.and.arrow.down") {}
                        .disabled(true)
                    Button("Convert", systemImage: "wand.and.stars") {}
                        .disabled(true)
                    Button("Apply", systemImage: "checkmark.seal") {}
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
    private func emptySection(_ section: GraphicsReportSection) -> some View {
        if rows.isEmpty {
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
