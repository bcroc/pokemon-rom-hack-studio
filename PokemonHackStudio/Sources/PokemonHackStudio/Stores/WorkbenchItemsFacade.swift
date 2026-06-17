import PokemonHackCore

struct WorkbenchItemsFacade {
    let catalog: ProjectItemCatalog?
    let viewState: ItemCatalogViewState?
    let selectedItemID: String
    let filter: ItemWorkbenchFilter
    let searchText: String

    var filteredDetails: [ItemDetailViewState] {
        guard let viewState else { return [] }
        let filteredByMode: [ItemDetailViewState]
        switch filter {
        case .all:
            filteredByMode = viewState.items
        case .editable:
            filteredByMode = viewState.items.filter(\.isEditable)
        case .diagnostics:
            filteredByMode = viewState.items.filter { !$0.diagnostics.isEmpty }
        }
        guard !searchText.isEmpty else { return filteredByMode }
        let needle = searchText.lowercased()
        return filteredByMode.filter { $0.searchBlob.contains(needle) }
    }

    var selectedDetail: ItemDetailViewState? {
        guard let viewState else { return nil }
        if let selected = viewState.items.first(where: { $0.itemID == selectedItemID }) {
            return selected
        }
        return filteredDetails.first ?? viewState.items.first
    }

    var selectedCoreDetail: ItemDetail? {
        guard let catalog else { return nil }
        if let itemID = selectedDetail?.itemID,
           let detail = catalog.items.first(where: { $0.itemID == itemID }) {
            return detail
        }
        if let selected = catalog.items.first(where: { $0.itemID == selectedItemID }) {
            return selected
        }
        return catalog.items.first { $0.isEditable } ?? catalog.items.first
    }

    static func refreshedSelection(currentID: String, catalog: ProjectItemCatalog?) -> String {
        guard let catalog else { return "" }
        if catalog.items.contains(where: { $0.itemID == currentID }) {
            return currentID
        }
        return catalog.items.first { $0.isEditable }?.itemID
            ?? catalog.items.first?.itemID
            ?? ""
    }
}
