import PokemonHackCore

struct WorkbenchMovesFacade {
    let viewState: MoveCatalogViewState?
    let catalog: ProjectMoveCatalog?
    let selectedProjectID: String?
    let selectedMoveID: String
    let filter: MoveWorkbenchFilter
    let searchText: String
    let draftsByKey: [String: MoveEditDraft]

    var filteredDetails: [MoveDetailViewState] {
        guard let viewState else { return [] }
        let filteredByMode: [MoveDetailViewState]
        switch filter {
        case .all:
            filteredByMode = viewState.moves
        case .tmhm:
            filteredByMode = viewState.moves.filter { !$0.tmhmLearners.isEmpty }
        case .tutor:
            filteredByMode = viewState.moves.filter { !$0.tutorLearners.isEmpty }
        case .learnedBy:
            filteredByMode = viewState.moves.filter { $0.learnerCount > 0 }
        case .diagnostics:
            filteredByMode = viewState.moves.filter { !$0.diagnostics.isEmpty }
        }
        guard !searchText.isEmpty else { return filteredByMode }
        let needle = searchText.lowercased()
        return filteredByMode.filter { $0.searchBlob.contains(needle) }
    }

    var selectedDetail: MoveDetailViewState? {
        guard let viewState else { return nil }
        if let selected = viewState.moves.first(where: { $0.moveID == selectedMoveID }) {
            return selected
        }
        return viewState.moves.first { $0.isEditable } ?? viewState.moves.first
    }

    var selectedCoreDetail: MoveDetail? {
        guard let catalog else { return nil }
        if let selected = catalog.moves.first(where: { $0.moveID == selectedMoveID }) {
            return selected
        }
        return catalog.moves.first { $0.isEditable } ?? catalog.moves.first
    }

    var selectedIsHiddenByCurrentFilter: Bool {
        guard !selectedMoveID.isEmpty, viewState != nil else { return false }
        return !filteredDetails.contains { $0.moveID == selectedMoveID }
    }

    var selectedDraft: MoveEditDraft? {
        guard let detail = selectedCoreDetail else { return nil }
        if let selectedProjectID {
            let key = Self.draftKey(projectID: selectedProjectID, moveID: detail.moveID)
            if let draft = draftsByKey[key] {
                return draft
            }
        }
        return MoveEditDraft(detail: detail)
    }

    var selectedIsDirty: Bool {
        guard let selectedProjectID, let detail = selectedCoreDetail else { return false }
        return isDirty(detail.moveID, projectID: selectedProjectID)
    }

    var dirtyDraftCount: Int {
        guard let selectedProjectID, let catalog else { return 0 }
        return catalog.moves.filter { isDirty($0.moveID, projectID: selectedProjectID) }.count
    }

    func isDirty(_ moveID: String, projectID: String? = nil) -> Bool {
        let effectiveProjectID = projectID ?? selectedProjectID
        guard
            let effectiveProjectID,
            let detail = catalog?.moves.first(where: { $0.moveID == moveID })
        else {
            return false
        }
        let baseDraft = MoveEditDraft(detail: detail)
        let key = Self.draftKey(projectID: effectiveProjectID, moveID: moveID)
        guard let draft = draftsByKey[key] else { return false }
        return draft != baseDraft
    }

    static func refreshedSelection(currentID: String, catalog: MoveCatalogViewState?) -> String {
        guard let catalog else { return "" }
        if catalog.moves.contains(where: { $0.moveID == currentID }) {
            return currentID
        }
        return catalog.moves.first { $0.isEditable }?.moveID
            ?? catalog.moves.first?.moveID
            ?? ""
    }

    static func draftKey(projectID: String, moveID: String) -> String {
        "\(projectID)::move::\(moveID)"
    }
}
