import SwiftUI

struct IndexedSourceSurfaceRow: View {
    let surface: IndexedSourceSurface

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: surface.exists ? "doc.text" : "doc.badge.clock")
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 5) {
                Text(surface.title)
                    .font(.headline)
                Text(surface.subtitle)
                    .foregroundStyle(.secondary)
                SourceLocationView(source: surface.source)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                if surface.preservesUnknownFields {
                    Label("Stable JSON", systemImage: "curlybraces")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.12), in: Capsule())
                        .foregroundStyle(.blue)
                }

                StatusPill(state: surface.validation)
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct IndexedDiagnosticRowView: View {
    let diagnostic: IndexedDiagnosticRow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(diagnostic.title)
                        .font(.headline)
                    Text(diagnostic.message)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                StatusPill(state: diagnostic.severity)
            }

            SourceLocationView(source: diagnostic.source)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct IndexedBuildTargetPreviewRow: View {
    let target: IndexedBuildTargetPreview

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: imageName)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 5) {
                Text(target.name)
                    .font(.headline)
                Text(target.kind)
                    .foregroundStyle(.secondary)
                Text(target.command)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .textSelection(.enabled)

                if let outputPath = target.outputPath {
                    Label(outputPath, systemImage: "archivebox")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var imageName: String {
        switch target.kind {
        case "test":
            "checkmark.seal"
        case "debug":
            "ladybug"
        case "release":
            "shippingbox"
        case "generated":
            "arrow.triangle.2.circlepath"
        default:
            "hammer"
        }
    }
}
