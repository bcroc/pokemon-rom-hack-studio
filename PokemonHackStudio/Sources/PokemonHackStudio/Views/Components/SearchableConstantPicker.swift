import SwiftUI
import PokemonHackCore

public protocol PickerConstant: Identifiable {
    var symbol: String { get }
}

extension TrainerConstant: PickerConstant {
    public var id: String { symbol }
}

extension SpeciesConstant: PickerConstant {}

struct SearchableConstantPicker<T: PickerConstant>: View {
    let title: String
    @Binding var selection: String
    let constants: [T]
    
    @State private var isShowingPicker = false
    @State private var searchText = ""
    
    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button {
                isShowingPicker = true
            } label: {
                HStack {
                    Text(displayConstant(selection))
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: 200)
            .popover(isPresented: $isShowingPicker, arrowEdge: .trailing) {
                pickerContent
            }
        }
    }
    
    private var pickerContent: some View {
        VStack(spacing: 0) {
            TextField("Search...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(8)
                .background(.ultraThinMaterial)
            
            Divider()
            
            List {
                let filtered = constants.filter {
                    searchText.isEmpty || 
                    $0.symbol.localizedCaseInsensitiveContains(searchText) ||
                    displayConstant($0.symbol).localizedCaseInsensitiveContains(searchText)
                }
                
                ForEach(Array(filtered.enumerated()), id: \.offset) { _, constant in
                    Button {
                        selection = constant.symbol
                        isShowingPicker = false
                    } label: {
                        HStack {
                            Text(displayConstant(constant.symbol))
                            Spacer()
                            if selection == constant.symbol {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .frame(width: 250, height: 300)
        }
    }
    
    private func displayConstant(_ symbol: String) -> String {
        symbol.replacingOccurrences(of: "MOVE_", with: "")
              .replacingOccurrences(of: "ITEM_", with: "")
              .replacingOccurrences(of: "TYPE_", with: "")
              .replacingOccurrences(of: "ABILITY_", with: "")
              .replacingOccurrences(of: "SPECIES_", with: "")
              .replacingOccurrences(of: "EVO_", with: "")
              .replacingOccurrences(of: "MAP_GROUP_", with: "")
              .replacingOccurrences(of: "MAP_", with: "")
              .replacingOccurrences(of: "_", with: " ")
              .capitalized
    }
}
