import SwiftUI

struct SidebarView: View {
    @Binding var selection: WorkbenchModule
    let issueCount: Int

    var body: some View {
        List(selection: $selection) {
            ForEach(WorkbenchModuleGroup.allCases) { group in
                Section(group.rawValue) {
                    ForEach(group.modules) { module in
                        SidebarModuleRow(module: module, issueCount: issueCount)
                            .tag(module)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("PokemonHack")
    }
}

private struct SidebarModuleRow: View {
    let module: WorkbenchModule
    let issueCount: Int

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: module.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(module.title)
                    .lineLimit(1)

                Text(module == .issues ? "\(issueCount) open" : module.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
