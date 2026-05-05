import SwiftUI

struct SourceInspectorContext {
    let title: String
    let subtitle: String
    let systemImage: String
    let status: ValidationState?
    let facts: [SourceInspectorFact]
    let sources: [SourceInspectorSource]
    let diagnostics: [SourceInspectorDiagnostic]
}

struct SourceInspectorFact: Identifiable {
    let id: String
    let label: String
    let value: String

    init(label: String, value: String) {
        id = label
        self.label = label
        self.value = value
    }
}

struct SourceInspectorSource: Identifiable {
    let id: String
    let title: String
    let source: SourceLocation
    let status: ValidationState?

    init(title: String, source: SourceLocation, status: ValidationState? = nil) {
        id = "\(title):\(source.label):\(source.symbol)"
        self.title = title
        self.source = source
        self.status = status
    }
}

struct SourceInspectorDiagnostic: Identifiable {
    let id: String
    let title: String
    let message: String
    let status: ValidationState
    let source: SourceLocation?

    init(id: String, title: String, message: String, status: ValidationState, source: SourceLocation? = nil) {
        self.id = id
        self.title = title
        self.message = message
        self.status = status
        self.source = source
    }
}

struct SourceInspector: View {
    let context: SourceInspectorContext

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                if !context.facts.isEmpty {
                    inspectorSection("Facts") {
                        VStack(spacing: 8) {
                            ForEach(context.facts) { fact in
                                HStack(alignment: .firstTextBaseline) {
                                    Text(fact.label)
                                        .foregroundStyle(.secondary)
                                    Spacer(minLength: 12)
                                    Text(fact.value)
                                        .fontWeight(.medium)
                                        .multilineTextAlignment(.trailing)
                                        .textSelection(.enabled)
                                }
                                .font(.caption)
                            }
                        }
                    }
                }

                inspectorSection("Sources") {
                    if context.sources.isEmpty {
                        Text("No source selection")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(context.sources) { source in
                                sourceRow(source)
                            }
                        }
                    }
                }

                if !context.diagnostics.isEmpty {
                    inspectorSection("Diagnostics") {
                        VStack(spacing: 10) {
                            ForEach(context.diagnostics) { diagnostic in
                                diagnosticRow(diagnostic)
                            }
                        }
                    }
                }
            }
            .padding(14)
        }
        .background(.background)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: context.systemImage)
                    .foregroundStyle(.secondary)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 3) {
                    Text(context.title)
                        .font(.headline)
                        .lineLimit(2)

                    Text(context.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                Spacer(minLength: 8)
            }

            if let status = context.status {
                StatusPill(state: status)
            }
        }
    }

    private func inspectorSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func sourceRow(_ source: SourceInspectorSource) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(source.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                Spacer(minLength: 8)

                if let status = source.status {
                    StatusPill(state: status)
                }
            }

            SourceLocationView(source: source.source)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func diagnosticRow(_ diagnostic: SourceInspectorDiagnostic) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(diagnostic.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                Spacer(minLength: 8)

                StatusPill(state: diagnostic.status)
            }

            Text(diagnostic.message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            if let source = diagnostic.source {
                SourceLocationView(source: source)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
