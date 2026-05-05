import SwiftUI

struct SidebarView: View {
    @Binding var selection: WorkbenchModule
    let issueCount: Int

    var body: some View {
        List(selection: $selection) {
            ForEach(WorkbenchModule.allCases) { module in
                HStack(spacing: 10) {
                    Image(systemName: module.systemImage)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(module.rawValue)
                            .lineLimit(1)

                        Text(module == .issues ? "\(issueCount) open" : module.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .tag(module)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("PokemonHack")
    }
}
