import SwiftUI

struct BuildWorkbenchView: View {
    let target: BuildTarget
    let steps: [BuildStep]
    let indexedProject: IndexedProjectSummary?

    var body: some View {
        ScrollView {
            if let indexedProject {
                indexedBuild(project: indexedProject)
            } else {
                fixtureBuild
            }
        }
        .navigationTitle("Build")
    }

    @ViewBuilder
    private func indexedBuild(project: IndexedProjectSummary) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Build")
                    .font(.largeTitle.weight(.semibold))
                Text("\(project.title) exposes \(project.buildTargetCount) build target previews.")
                    .foregroundStyle(.secondary)
            }

            EditorSection(title: "Targets") {
                VStack(spacing: 10) {
                    if project.buildTargets.isEmpty {
                        ContentUnavailableView(
                            "No Build Targets",
                            systemImage: "hammer",
                            description: Text("The selected adapter did not expose build commands.")
                        )
                    } else {
                        ForEach(project.buildTargets) { target in
                            IndexedBuildTargetPreviewRow(target: target)
                        }
                    }
                }
            }

            EditorSection(title: "Actions") {
                HStack {
                    Button("Build", systemImage: "hammer") {}
                        .disabled(true)
                    Button("Run", systemImage: "play.fill") {}
                        .disabled(true)
                    Button("Validate", systemImage: "checkmark.seal") {}
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

    private var fixtureBuild: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Build")
                    .font(.largeTitle.weight(.semibold))
                Text("\(target.name) targets \(target.romBase)")
                    .foregroundStyle(.secondary)
            }

            EditorSection(title: "Pipeline") {
                VStack(spacing: 10) {
                    ForEach(steps) { step in
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
