import SwiftUI

struct IssuesView: View {
    let issues: [WorkbenchIssue]
    let indexedProject: IndexedProjectSummary?
    let indexedDiagnostics: [IndexedDiagnosticRow]
    let diagnosticSummary: DiagnosticSummary
    let onRouteDiagnostic: (IndexedDiagnosticRow) -> Void

    @State private var expandedBuckets: Set<DiagnosticSummaryBucket> = [.blockingErrors]
    @State private var visibleRowLimits: [DiagnosticSummaryBucket: Int] = [:]

    var body: some View {
        ScrollView {
            if let indexedProject {
                indexedIssues(project: indexedProject)
            } else {
                fixtureIssues
            }
        }
        .navigationTitle("Issues")
    }

    @ViewBuilder
    private func indexedIssues(project: IndexedProjectSummary) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Diagnostics")
                    .font(.largeTitle.weight(.semibold))
                Text("\(project.title) grouped triage for source, health, generated-output, and optional resource findings.")
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
                MetricCard(title: "Blocking", value: "\(diagnosticSummary.blockingErrorCount)", detail: "Errors to fix first")
                MetricCard(title: "Source", value: "\(diagnosticSummary.sourceWarningCount)", detail: "Source/data warnings")
                MetricCard(title: "Health", value: "\(diagnosticSummary.healthCount)", detail: "Tools and ROM headers")
                MetricCard(title: "Generated", value: "\(diagnosticSummary.generatedArtifactCount)", detail: "Outputs and artifacts")
                MetricCard(title: "Optional Assets", value: "\(diagnosticSummary.optionalAssetCount)", detail: "Resources and graphics")
            }

            if indexedDiagnostics.isEmpty {
                ContentUnavailableView(
                    "No Diagnostics",
                    systemImage: "checkmark.seal",
                    description: Text("The selected project index has no findings.")
                )
            } else {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(diagnosticSummary.buckets) { bucket in
                        if !bucket.diagnostics.isEmpty {
                            diagnosticBucket(bucket)
                        }
                    }
                }
            }
        }
        .padding(24)
    }

    private func diagnosticBucket(_ bucket: DiagnosticBucketSummary) -> some View {
        EditorSection(title: bucket.title) {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    toggleBucket(bucket.bucket)
                } label: {
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: expandedBuckets.contains(bucket.bucket) ? "chevron.down" : "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 12)
                        Image(systemName: bucket.systemImage)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bucket.subtitle)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Text(summaryLine(for: bucket))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        StatusPill(state: bucket.status)
                        Text("\(bucket.count)")
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                if expandedBuckets.contains(bucket.bucket) {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(visibleDiagnostics(for: bucket)) { diagnostic in
                            IndexedDiagnosticRowView(diagnostic: diagnostic) {
                                onRouteDiagnostic(diagnostic)
                            }
                        }

                        if remainingCount(for: bucket) > 0 {
                            HStack {
                                Text("\(remainingCount(for: bucket)) more finding\(remainingCount(for: bucket) == 1 ? "" : "s") hidden")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button("Show More", systemImage: "chevron.down.circle") {
                                    showMoreRows(in: bucket.bucket)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
        }
    }

    private func toggleBucket(_ bucket: DiagnosticSummaryBucket) {
        if expandedBuckets.contains(bucket) {
            expandedBuckets.remove(bucket)
        } else {
            expandedBuckets.insert(bucket)
        }
    }

    private func visibleDiagnostics(for bucket: DiagnosticBucketSummary) -> [IndexedDiagnosticRow] {
        Array(bucket.diagnostics.prefix(visibleRowLimit(for: bucket.bucket)))
    }

    private func visibleRowLimit(for bucket: DiagnosticSummaryBucket) -> Int {
        visibleRowLimits[bucket] ?? Self.initialVisibleRowLimit
    }

    private func remainingCount(for bucket: DiagnosticBucketSummary) -> Int {
        max(0, bucket.count - visibleRowLimit(for: bucket.bucket))
    }

    private func showMoreRows(in bucket: DiagnosticSummaryBucket) {
        visibleRowLimits[bucket] = visibleRowLimit(for: bucket) + Self.visibleRowPageSize
    }

    private func summaryLine(for bucket: DiagnosticBucketSummary) -> String {
        if expandedBuckets.contains(bucket.bucket) {
            let visibleCount = min(visibleRowLimit(for: bucket.bucket), bucket.count)
            return "Showing \(visibleCount) of \(bucket.count)"
        }
        return "Collapsed"
    }

    private static let initialVisibleRowLimit = 50
    private static let visibleRowPageSize = 100

    private var fixtureIssues: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Issues")
                    .font(.largeTitle.weight(.semibold))
                Text("Validation findings mapped back to source files and symbols.")
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(issues) { issue in
                    IssueRow(issue: issue)
                }
            }
        }
        .padding(24)
    }
}

private struct IssueRow: View {
    let issue: WorkbenchIssue

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(issue.title)
                        .font(.headline)
                    Text(issue.message)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusPill(state: issue.severity)
            }

            SourceLocationView(source: issue.source)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
