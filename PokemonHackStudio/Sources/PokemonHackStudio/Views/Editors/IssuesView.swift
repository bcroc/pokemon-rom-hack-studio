import SwiftUI

struct IssuesView: View {
    let issues: [WorkbenchIssue]
    let indexedProject: IndexedProjectSummary?
    let indexedDiagnostics: [IndexedDiagnosticRow]

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
                Text("Issues")
                    .font(.largeTitle.weight(.semibold))
                Text("\(project.title) index diagnostics")
                    .foregroundStyle(.secondary)
            }

            if indexedDiagnostics.isEmpty {
                ContentUnavailableView(
                    "No Diagnostics",
                    systemImage: "checkmark.seal",
                    description: Text("The selected project index has no findings.")
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(indexedDiagnostics) { diagnostic in
                        IndexedDiagnosticRowView(diagnostic: diagnostic)
                    }
                }
            }
        }
        .padding(24)
    }

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
