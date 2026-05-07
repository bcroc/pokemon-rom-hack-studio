import Combine
import Foundation
import PokemonHackCore

enum MapEditorOverlay: String, CaseIterable, Identifiable {
    case grid
    case collision
    case objects
    case warps
    case coordEvents
    case bgEvents
    case connections
    case border
    case playerView

    var id: String { rawValue }

    var layer: MapEditorLayer {
        switch self {
        case .grid: .grid
        case .collision: .collision
        case .objects: .objects
        case .warps: .warps
        case .coordEvents: .coordEvents
        case .bgEvents: .bgEvents
        case .connections: .connections
        case .border: .border
        case .playerView: .playerView
        }
    }
}

enum MapEditorCommand: Equatable {
    case selectTool(MapEditorTool)
    case setOverlay(MapEditorOverlay, Bool)
    case toggleOverlay(MapEditorOverlay)
    case setLayerVisibility(MapEditorLayer, Bool)
    case setLayerOpacity(MapEditorLayer, Double)
    case toggleLayerSolo(MapEditorLayer)
    case applyLayerPreset(MapLayerPreset)
    case resetLayerSettings
    case setOverlaySettings(MapOverlaySettings)
    case selectBrush(rawValue: UInt16)
    case selectMapCell(x: Int, y: Int, target: MapBlockTarget)
    case eyedropMapCell(x: Int, y: Int, target: MapBlockTarget)
    case paintMapCell(x: Int, y: Int, target: MapBlockTarget)
    case fillMapFromSelection(toX: Int, y: Int, target: MapBlockTarget)
    case fillMapRectangle(x: Int, y: Int, width: Int, height: Int, target: MapBlockTarget, rawValue: UInt16?)
    case updateSelectedBlockCollision(Int)
    case updateSelectedBlockElevation(Int)
    case shiftMap(deltaX: Int, deltaY: Int, fillRawValue: UInt16)
    case pasteBlockPattern(x: Int, y: Int, width: Int, height: Int, target: MapBlockTarget, rawValues: [UInt16])
    case selectMapEvent(id: String?)
    case moveSelectedMapEvent(x: Int, y: Int)
    case updateSelectedMapEventProperty(key: String, value: String)
    case addObjectEvent(x: Int, y: Int)
    case selectEventTemplate(MapEventTemplateKind)
    case addMapEvent(template: MapEventTemplateKind, x: Int, y: Int)
    case duplicateSelectedMapEvent
    case deleteSelectedMapEvent
    case updateMapHeaderField(key: String, value: String)
    case updateConnectionField(index: Int, key: String, value: String)
    case addConnection(properties: [MapEventProperty])
    case duplicateConnection(index: Int)
    case deleteConnection(index: Int)
    case updateWildEncounterField(sourcePath: String, jsonPath: [String], key: String, value: String)
    case updateMetatileAttribute(metatileID: Int, tilesetSymbol: String?, key: String, value: String)
    case updateMetatileTile(metatileID: Int, tilesetSymbol: String?, tileEntryIndex: Int, rawValue: UInt16)
    case updateScriptBody(label: String, sourcePath: String, body: String)
    case createMapScriptLabel(label: String, sourcePath: String, body: String)
    case undo
    case redo
    case discardChanges
    case reset
    case clearSelection
    case previewMutationPlan
}

struct MapEditorHistoryEntry: Equatable, Identifiable {
    let id: String
    let command: MapEditorCommand
    let operations: [MapEditOperation]

    init(id: String = UUID().uuidString, command: MapEditorCommand, operations: [MapEditOperation]) {
        self.id = id
        self.command = command
        self.operations = operations
    }
}

struct StagedMapScriptBody: Equatable, Identifiable {
    var id: String { Self.key(label: label, sourcePath: sourcePath) }

    let label: String
    let sourcePath: String
    let body: String
    let isNew: Bool

    static func key(label: String, sourcePath: String) -> String {
        "\(sourcePath):\(label)"
    }
}

@MainActor
final class MapEditorSession: ObservableObject {
    @Published var selectedMapTool: MapEditorTool = .select
    @Published var selectedEventTemplate: MapEventTemplateKind = .object
    @Published var mapOverlaySettings = MapOverlaySettings()
    @Published private(set) var selectedMapVisualDocument: MapVisualDocument?
    @Published private(set) var selectedBrushRawValue: UInt16?
    @Published private(set) var selectedMapCell: MapCellSelection?
    @Published private(set) var selectedMapBlockTarget: MapBlockTarget = .layout
    @Published private(set) var selectedMapEventID: String?
    @Published private(set) var stagedMapBlockdataValues: [UInt16] = []
    @Published private(set) var stagedMapBorderValues: [UInt16] = []
    @Published private(set) var stagedMapEvents: [MapEventDescriptor] = []
    @Published private(set) var stagedMapScriptBodies: [String: StagedMapScriptBody] = [:]
    @Published private(set) var undoStack: [MapEditorHistoryEntry] = []
    @Published private(set) var redoStack: [MapEditorHistoryEntry] = []
    @Published private(set) var latestMapEditPlan: MapEditPlan?
    @Published private(set) var latestMapApplyResult: MapApplyResult?
    @Published private(set) var needsDocumentReloadAfterApply = false

    init(document: MapVisualDocument? = nil) {
        if let document {
            load(document: document, preserveSelection: false)
        }
    }

    var isDirty: Bool {
        !undoStack.isEmpty
    }

    var hasUndo: Bool {
        !undoStack.isEmpty
    }

    var hasRedo: Bool {
        !redoStack.isEmpty
    }

    var canDiscardMapEdits: Bool {
        isDirty || latestMapEditPlan != nil || latestMapApplyResult != nil || needsDocumentReloadAfterApply
    }

    var mapEditOperations: [MapEditOperation] {
        undoStack.flatMap(\.operations)
    }

    var undoneMapEditOperations: [MapEditOperation] {
        redoStack.flatMap(\.operations)
    }

    var selectedMapEvent: MapEventDescriptor? {
        guard let selectedMapEventID else { return nil }
        return stagedMapEvents.first { $0.id == selectedMapEventID }
    }

    var isLatestMapEditPlanCurrent: Bool {
        guard let document = selectedMapVisualDocument, let latestMapEditPlan else { return false }
        return latestMapEditPlan.documentID == document.id
            && latestMapEditPlan.operations == mapEditOperations
    }

    var canPreviewSelectedMapMutationPlan: Bool {
        selectedMapVisualDocument != nil
            && isDirty
            && !needsDocumentReloadAfterApply
            && !isLatestMapEditPlanCurrent
    }

    var canApplySelectedMapMutationPlan: Bool {
        guard let latestMapEditPlan,
              isDirty,
              isLatestMapEditPlanCurrent,
              !latestMapEditPlan.changes.isEmpty,
              latestMapEditPlan.mutationPlan.requiresExplicitApply,
              !needsDocumentReloadAfterApply
        else {
            return false
        }
        return !latestMapEditPlan.diagnostics.contains { $0.severity == .error }
    }

    var previewBlockedReason: String? {
        if selectedMapVisualDocument == nil { return "No map document is loaded." }
        if needsDocumentReloadAfterApply { return "Reload the map after apply before previewing more edits." }
        if !isDirty { return "No staged edits to preview." }
        if isLatestMapEditPlanCurrent { return "The current edits already have a preview." }
        return nil
    }

    var applyBlockedReason: String? {
        guard let latestMapEditPlan else { return "Preview the staged edits before applying." }
        if needsDocumentReloadAfterApply { return "Reload the map after apply before applying more edits." }
        if !isDirty { return "No staged edits to apply." }
        if !isLatestMapEditPlanCurrent { return "Preview is stale." }
        if latestMapEditPlan.changes.isEmpty { return "Preview produced no file changes." }
        if latestMapEditPlan.diagnostics.contains(where: { $0.severity == .error }) { return "Preview has blocking diagnostics." }
        if !latestMapEditPlan.mutationPlan.requiresExplicitApply { return "Preview is not marked for explicit apply." }
        return nil
    }

    func load(document: MapVisualDocument, preserveSelection: Bool = true) {
        let shouldPreserveSelection = preserveSelection && selectedMapVisualDocument?.id == document.id
        let previousCell = selectedMapCell
        let previousCellTarget = selectedMapBlockTarget
        let previousEventID = selectedMapEventID
        let shouldResetBrush = selectedMapVisualDocument?.id != document.id || selectedBrushRawValue == nil

        selectedMapVisualDocument = document
        stagedMapBlockdataValues = document.blockdata.rawValues
        stagedMapBorderValues = document.border?.rawValues ?? []
        stagedMapEvents = Self.normalizedEvents(document.events)
        stagedMapScriptBodies = [:]
        undoStack = []
        redoStack = []
        latestMapEditPlan = nil
        latestMapApplyResult = nil
        needsDocumentReloadAfterApply = false

        if shouldResetBrush {
            selectedBrushRawValue = document.blockdata.rawValues.first
        }

        if shouldPreserveSelection {
            restoreSelection(cell: previousCell, target: previousCellTarget, eventID: previousEventID)
        } else {
            selectedMapCell = nil
            selectedMapBlockTarget = .layout
            selectedMapEventID = nil
        }
    }

    func reset() {
        selectedMapTool = .select
        mapOverlaySettings = MapOverlaySettings()
        selectedMapVisualDocument = nil
        selectedBrushRawValue = nil
        selectedMapCell = nil
        selectedMapBlockTarget = .layout
        selectedMapEventID = nil
        stagedMapScriptBodies = [:]
        stagedMapBlockdataValues = []
        stagedMapBorderValues = []
        stagedMapEvents = []
        undoStack = []
        redoStack = []
        latestMapEditPlan = nil
        latestMapApplyResult = nil
        needsDocumentReloadAfterApply = false
    }

    func discardChanges(preserveSelection: Bool = true) {
        guard let document = selectedMapVisualDocument else {
            reset()
            return
        }

        let previousCell = selectedMapCell
        let previousCellTarget = selectedMapBlockTarget
        let previousEventID = selectedMapEventID
        stagedMapBlockdataValues = document.blockdata.rawValues
        stagedMapBorderValues = document.border?.rawValues ?? []
        stagedMapEvents = Self.normalizedEvents(document.events)
        stagedMapScriptBodies = [:]
        undoStack = []
        redoStack = []
        latestMapEditPlan = nil
        latestMapApplyResult = nil
        needsDocumentReloadAfterApply = false

        if preserveSelection {
            restoreSelection(cell: previousCell, target: previousCellTarget, eventID: previousEventID)
        } else {
            selectedMapCell = nil
            selectedMapBlockTarget = .layout
            selectedMapEventID = nil
        }
    }

    func clearSelection() {
        selectedMapCell = nil
        selectedMapBlockTarget = .layout
        selectedMapEventID = nil
    }

    func setOverlay(_ overlay: MapEditorOverlay, isVisible: Bool) {
        setLayerVisible(overlay.layer, isVisible: isVisible)
    }

    func isOverlayVisible(_ overlay: MapEditorOverlay) -> Bool {
        mapOverlaySettings.isLayerVisible(overlay.layer)
    }

    func toggleOverlay(_ overlay: MapEditorOverlay) {
        setOverlay(overlay, isVisible: !isOverlayVisible(overlay))
    }

    func setLayerVisible(_ layer: MapEditorLayer, isVisible: Bool) {
        mapOverlaySettings.setLayerVisible(layer, isVisible)
    }

    func setLayerOpacity(_ layer: MapEditorLayer, opacity: Double) {
        mapOverlaySettings.setLayerOpacity(layer, opacity)
    }

    func toggleLayerSolo(_ layer: MapEditorLayer) {
        mapOverlaySettings.toggleSolo(layer)
    }

    func applyLayerPreset(_ preset: MapLayerPreset) {
        mapOverlaySettings.applyPreset(preset)
    }

    func resetLayerSettings() {
        mapOverlaySettings.reset()
    }

    func selectMapCell(x: Int, y: Int, target: MapBlockTarget = .layout) {
        guard let rawValue = blockValue(x: x, y: y, target: target) else { return }
        selectedMapCell = MapCellSelection(x: x, y: y, rawValue: rawValue)
        selectedMapBlockTarget = target
    }

    func selectBrush(rawValue: UInt16) {
        selectedBrushRawValue = rawValue
        selectedMapTool = .pencil
    }

    func eyedropMapCell(x: Int, y: Int, target: MapBlockTarget = .layout) {
        guard let rawValue = blockValue(x: x, y: y, target: target) else { return }
        selectedBrushRawValue = rawValue
        selectedMapCell = MapCellSelection(x: x, y: y, rawValue: rawValue)
        selectedMapBlockTarget = target
    }

    @discardableResult
    func paintMapCell(x: Int, y: Int, target: MapBlockTarget = .layout) -> Bool {
        guard let rawValue = selectedBrushRawValue else { return false }
        return paintMapCell(x: x, y: y, target: target, rawValue: rawValue)
    }

    @discardableResult
    func fillMapFromSelection(toX x: Int, y: Int, target: MapBlockTarget? = nil) -> Bool {
        guard let selectedMapCell else {
            return paintMapCell(x: x, y: y, target: target ?? selectedMapBlockTarget)
        }
        let resolvedTarget = target ?? selectedMapBlockTarget
        let minX = min(selectedMapCell.x, x)
        let maxX = max(selectedMapCell.x, x)
        let minY = min(selectedMapCell.y, y)
        let maxY = max(selectedMapCell.y, y)
        return fillMapRectangle(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1,
            target: resolvedTarget,
            rawValue: selectedBrushRawValue
        )
    }

    @discardableResult
    func fillMapRectangle(
        x: Int,
        y: Int,
        width: Int,
        height: Int,
        target: MapBlockTarget = .layout,
        rawValue: UInt16? = nil
    ) -> Bool {
        guard width > 0, height > 0, let rawValue = rawValue ?? selectedBrushRawValue else { return false }

        var didChange = false
        for fillY in y..<(y + height) {
            for fillX in x..<(x + width) {
                didChange = setBlockValue(rawValue, x: fillX, y: fillY, target: target) || didChange
            }
        }
        guard didChange else { return false }

        selectedMapCell = MapCellSelection(x: x + width - 1, y: y + height - 1, rawValue: rawValue)
        selectedMapBlockTarget = target
        appendHistory(
            command: .fillMapRectangle(x: x, y: y, width: width, height: height, target: target, rawValue: rawValue),
            operations: [
                MapEditOperation(
                    action: .fillMetatile,
                    target: target,
                    x: x,
                    y: y,
                    width: width,
                    height: height,
                    rawValue: rawValue
                )
            ]
        )
        return true
    }

    @discardableResult
    func updateSelectedBlockCollision(_ collision: Int) -> Bool {
        guard let selectedMapCell else { return false }
        guard updateBlockAttributes(x: selectedMapCell.x, y: selectedMapCell.y, target: selectedMapBlockTarget, collision: collision, elevation: nil) else {
            return false
        }
        appendHistory(
            command: .updateSelectedBlockCollision(collision),
            operations: [
                MapEditOperation(
                    action: .updateBlockCollision,
                    target: selectedMapBlockTarget,
                    x: selectedMapCell.x,
                    y: selectedMapCell.y,
                    collision: collision
                )
            ]
        )
        return true
    }

    @discardableResult
    func updateSelectedBlockElevation(_ elevation: Int) -> Bool {
        guard let selectedMapCell else { return false }
        guard updateBlockAttributes(x: selectedMapCell.x, y: selectedMapCell.y, target: selectedMapBlockTarget, collision: nil, elevation: elevation) else {
            return false
        }
        appendHistory(
            command: .updateSelectedBlockElevation(elevation),
            operations: [
                MapEditOperation(
                    action: .updateBlockElevation,
                    target: selectedMapBlockTarget,
                    x: selectedMapCell.x,
                    y: selectedMapCell.y,
                    elevation: elevation
                )
            ]
        )
        return true
    }

    @discardableResult
    func shiftMap(deltaX: Int, deltaY: Int, fillRawValue: UInt16 = 0) -> Bool {
        guard shiftStagedLayout(deltaX: deltaX, deltaY: deltaY, fillRawValue: fillRawValue) else { return false }
        appendHistory(
            command: .shiftMap(deltaX: deltaX, deltaY: deltaY, fillRawValue: fillRawValue),
            operations: [MapEditOperation(action: .shiftMap, defaultRawValue: fillRawValue, deltaX: deltaX, deltaY: deltaY)]
        )
        return true
    }

    @discardableResult
    func pasteBlockPattern(
        x: Int,
        y: Int,
        width: Int,
        height: Int,
        target: MapBlockTarget = .layout,
        rawValues: [UInt16]
    ) -> Bool {
        guard pasteStagedBlockPattern(x: x, y: y, width: width, height: height, target: target, rawValues: rawValues) else {
            return false
        }
        appendHistory(
            command: .pasteBlockPattern(x: x, y: y, width: width, height: height, target: target, rawValues: rawValues),
            operations: [
                MapEditOperation(
                    action: .pasteBlockPattern,
                    target: target,
                    x: x,
                    y: y,
                    width: width,
                    height: height,
                    rawValues: rawValues
                )
            ]
        )
        return true
    }

    @discardableResult
    func updateMapHeaderField(key: String, value: String) -> Bool {
        stageSourceOnlyOperation(
            command: .updateMapHeaderField(key: key, value: value),
            operation: MapEditOperation(action: .updateMapHeaderField, fieldKey: key, fieldValue: value)
        )
    }

    @discardableResult
    func updateConnectionField(index: Int, key: String, value: String) -> Bool {
        stageSourceOnlyOperation(
            command: .updateConnectionField(index: index, key: key, value: value),
            operation: MapEditOperation(action: .updateConnectionField, eventIndex: index, fieldKey: key, fieldValue: value)
        )
    }

    @discardableResult
    func addConnection(properties: [MapEventProperty]) -> Bool {
        stageSourceOnlyOperation(
            command: .addConnection(properties: properties),
            operation: MapEditOperation(action: .addConnection, templateProperties: properties)
        )
    }

    @discardableResult
    func duplicateConnection(index: Int) -> Bool {
        stageSourceOnlyOperation(
            command: .duplicateConnection(index: index),
            operation: MapEditOperation(action: .duplicateConnection, eventIndex: index)
        )
    }

    @discardableResult
    func deleteConnection(index: Int) -> Bool {
        stageSourceOnlyOperation(
            command: .deleteConnection(index: index),
            operation: MapEditOperation(action: .deleteConnection, eventIndex: index)
        )
    }

    @discardableResult
    func updateWildEncounterField(sourcePath: String, jsonPath: [String], key: String, value: String) -> Bool {
        stageSourceOnlyOperation(
            command: .updateWildEncounterField(sourcePath: sourcePath, jsonPath: jsonPath, key: key, value: value),
            operation: MapEditOperation(
                action: .updateWildEncounterField,
                fieldKey: key,
                fieldValue: value,
                sourcePath: sourcePath,
                jsonPath: jsonPath
            )
        )
    }

    @discardableResult
    func updateMetatileAttribute(metatileID: Int, tilesetSymbol: String? = nil, key: String, value: String) -> Bool {
        stageSourceOnlyOperation(
            command: .updateMetatileAttribute(metatileID: metatileID, tilesetSymbol: tilesetSymbol, key: key, value: value),
            operation: MapEditOperation(
                action: .updateMetatileAttribute,
                fieldKey: key,
                fieldValue: value,
                tilesetSymbol: tilesetSymbol,
                metatileID: metatileID
            )
        )
    }

    @discardableResult
    func updateMetatileTile(metatileID: Int, tilesetSymbol: String? = nil, tileEntryIndex: Int, rawValue: UInt16) -> Bool {
        stageSourceOnlyOperation(
            command: .updateMetatileTile(metatileID: metatileID, tilesetSymbol: tilesetSymbol, tileEntryIndex: tileEntryIndex, rawValue: rawValue),
            operation: MapEditOperation(
                action: .updateMetatileTile,
                rawValue: rawValue,
                tilesetSymbol: tilesetSymbol,
                metatileID: metatileID,
                tileEntryIndex: tileEntryIndex
            )
        )
    }

    func selectMapEvent(id: String?) {
        guard let id else {
            selectedMapEventID = nil
            return
        }
        guard stagedMapEvents.contains(where: { $0.id == id }) else { return }
        selectedMapEventID = id
    }

    @discardableResult
    func moveSelectedMapEvent(toX x: Int, y: Int) -> Bool {
        guard let selectedMapEventID,
              let event = stagedMapEvents.first(where: { $0.id == selectedMapEventID }),
              event.x != x || event.y != y
        else {
            return false
        }

        stagedMapEvents = stagedMapEvents.map { current in
            guard current.id == selectedMapEventID else { return current }
            return moved(current, x: x, y: y)
        }
        self.selectedMapEventID = selectedMapEventID
        appendHistory(
            command: .moveSelectedMapEvent(x: x, y: y),
            operations: [MapEditOperation(action: .moveEvent, x: x, y: y, eventKind: event.kind, eventIndex: event.index)]
        )
        return true
    }

    @discardableResult
    func updateSelectedMapEventProperty(key: String, value: String) -> Bool {
        guard let selectedMapEventID,
              let event = stagedMapEvents.first(where: { $0.id == selectedMapEventID })
        else {
            return false
        }
        let updated = updated(event, key: key, value: value)
        guard updated != event else { return false }

        stagedMapEvents = stagedMapEvents.map { $0.id == selectedMapEventID ? updated : $0 }
        self.selectedMapEventID = updated.id
        appendHistory(
            command: .updateSelectedMapEventProperty(key: key, value: value),
            operations: [
                MapEditOperation(
                    action: .updateEventField,
                    eventKind: event.kind,
                    eventIndex: event.index,
                    fieldKey: key,
                    fieldValue: value
                )
            ]
        )
        return true
    }

    func selectEventTemplate(_ template: MapEventTemplateKind) {
        selectedEventTemplate = template
    }

    @discardableResult
    func addObjectEvent(atX x: Int, y: Int) -> Bool {
        addMapEvent(template: .object, atX: x, y: y)
    }

    @discardableResult
    func addMapEvent(template: MapEventTemplateKind, atX x: Int, y: Int) -> Bool {
        addMapEvent(
            template: template,
            kind: template.eventKind,
            atX: x,
            y: y,
            templateProperties: template.templateProperties(x: x, y: y, mapID: selectedMapVisualDocument?.mapID)
        )
    }

    @discardableResult
    private func addMapEvent(
        template: MapEventTemplateKind,
        kind: MapEventKind,
        atX x: Int,
        y: Int,
        templateProperties: [MapEventProperty]
    ) -> Bool {
        let index = stagedMapEvents.filter { $0.kind == kind }.count
        let event = Self.event(kind: kind, index: index, x: x, y: y, properties: templateProperties)
        stagedMapEvents.append(event)
        stagedMapEvents = Self.normalizedEvents(stagedMapEvents)
        selectedMapEventID = event.id
        appendHistory(
            command: .addMapEvent(template: template, x: x, y: y),
            operations: [
                MapEditOperation(
                    action: .addEvent,
                    x: x,
                    y: y,
                    eventKind: kind,
                    templateProperties: event.properties
                )
            ]
        )
        return true
    }

    func stagedScriptBody(label: String, sourcePath: String) -> String? {
        stagedMapScriptBodies[StagedMapScriptBody.key(label: label, sourcePath: sourcePath)]?.body
    }

    var editableScriptSourcePath: String? {
        selectedMapVisualDocument?.scriptIndex?.sources.first { $0.exists && $0.role == .mapLocal }?.path
            ?? selectedMapVisualDocument?.scriptIndex?.sources.first { $0.exists && $0.role == .shared }?.path
    }

    @discardableResult
    func updateScriptBody(label: String, sourcePath: String, body: String) -> Bool {
        guard MapScriptIndex.normalizedScriptLabel(label) != nil else { return false }
        let key = StagedMapScriptBody.key(label: label, sourcePath: sourcePath)
        guard stagedMapScriptBodies[key]?.body != body else { return false }
        stageScriptBody(label: label, sourcePath: sourcePath, body: body, isNew: stagedMapScriptBodies[key]?.isNew ?? false)
        appendHistory(
            command: .updateScriptBody(label: label, sourcePath: sourcePath, body: body),
            operations: [
                MapEditOperation(
                    action: .updateScriptBody,
                    scriptLabel: label,
                    scriptBody: body,
                    scriptSourcePath: sourcePath
                )
            ]
        )
        return true
    }

    @discardableResult
    func createScriptLabel(label: String, sourcePath: String, body: String) -> Bool {
        guard MapScriptIndex.normalizedScriptLabel(label) != nil else { return false }
        let key = StagedMapScriptBody.key(label: label, sourcePath: sourcePath)
        guard stagedMapScriptBodies[key] == nil else { return false }
        stageScriptBody(label: label, sourcePath: sourcePath, body: body, isNew: true)
        appendHistory(
            command: .createMapScriptLabel(label: label, sourcePath: sourcePath, body: body),
            operations: [
                MapEditOperation(
                    action: .createMapScriptLabel,
                    scriptLabel: label,
                    scriptBody: body,
                    scriptSourcePath: sourcePath
                )
            ]
        )
        return true
    }

    @discardableResult
    func duplicateSelectedMapEvent() -> Bool {
        guard let selectedMapEventID,
              let event = stagedMapEvents.first(where: { $0.id == selectedMapEventID })
        else {
            return false
        }

        guard let sourceIndex = stagedMapEvents.firstIndex(where: { $0.id == event.id }) else { return false }
        stagedMapEvents.insert(Self.duplicate(event, in: stagedMapEvents), at: stagedMapEvents.index(after: sourceIndex))
        stagedMapEvents = Self.normalizedEvents(stagedMapEvents)
        let duplicatePosition = stagedMapEvents.index(after: sourceIndex)
        let duplicate = stagedMapEvents[duplicatePosition]
        self.selectedMapEventID = duplicate.id

        var operations = [
            MapEditOperation(action: .duplicateEvent, eventKind: event.kind, eventIndex: event.index)
        ]
        if let duplicateX = duplicate.x, let duplicateY = duplicate.y {
            operations.append(
                MapEditOperation(
                    action: .moveEvent,
                    x: duplicateX,
                    y: duplicateY,
                    eventKind: duplicate.kind,
                    eventIndex: duplicate.index
                )
            )
        }
        appendHistory(command: .duplicateSelectedMapEvent, operations: operations)
        return true
    }

    @discardableResult
    func deleteSelectedMapEvent() -> Bool {
        guard let selectedMapEventID,
              let event = stagedMapEvents.first(where: { $0.id == selectedMapEventID })
        else {
            return false
        }

        stagedMapEvents.removeAll { $0.id == selectedMapEventID }
        stagedMapEvents = Self.normalizedEvents(stagedMapEvents)
        self.selectedMapEventID = nil
        appendHistory(
            command: .deleteSelectedMapEvent,
            operations: [MapEditOperation(action: .deleteEvent, eventKind: event.kind, eventIndex: event.index)]
        )
        return true
    }

    func undoLastMapEdit() {
        guard let entry = undoStack.popLast() else { return }
        redoStack.append(entry)
        rebuildStagedMapStateFromHistory()
    }

    func redoMapEdit() {
        guard let entry = redoStack.popLast() else { return }
        undoStack.append(entry)
        rebuildStagedMapStateFromHistory()
    }

    @discardableResult
    func previewSelectedMapMutationPlan() -> MapEditPlan? {
        guard canPreviewSelectedMapMutationPlan, let document = selectedMapVisualDocument else {
            if !isDirty {
                latestMapEditPlan = nil
            }
            return latestMapEditPlan
        }
        let plan = MapMutationPlanner.plan(document: document, operations: mapEditOperations)
        latestMapEditPlan = plan
        return plan
    }

    @discardableResult
    func applySelectedMapMutationPlan(fileManager: FileManager = .default) throws -> MapApplyResult? {
        guard canApplySelectedMapMutationPlan, let latestMapEditPlan else { return nil }
        let result = try MapMutationApplier.apply(plan: latestMapEditPlan, fileManager: fileManager)
        latestMapApplyResult = result
        self.latestMapEditPlan = nil
        undoStack = []
        redoStack = []
        needsDocumentReloadAfterApply = true
        return result
    }

    func recordApplyFailure(_ error: Error) {
        guard let plan = latestMapEditPlan else { return }
        latestMapEditPlan = MapEditPlan(
            rootPath: plan.rootPath,
            documentID: plan.documentID,
            operations: plan.operations,
            changes: plan.changes,
            diagnostics: plan.diagnostics + [
                Diagnostic(severity: .error, code: "MAP_APPLY_FAILED", message: error.localizedDescription)
            ],
            mutationPlan: plan.mutationPlan,
            backupRelativeRoot: plan.backupRelativeRoot
        )
    }

    @discardableResult
    func dispatch(_ command: MapEditorCommand) -> Bool {
        switch command {
        case .selectTool(let tool):
            selectedMapTool = tool
            return true
        case .setOverlay(let overlay, let isVisible):
            setOverlay(overlay, isVisible: isVisible)
            return true
        case .toggleOverlay(let overlay):
            toggleOverlay(overlay)
            return true
        case .setLayerVisibility(let layer, let isVisible):
            setLayerVisible(layer, isVisible: isVisible)
            return true
        case .setLayerOpacity(let layer, let opacity):
            setLayerOpacity(layer, opacity: opacity)
            return true
        case .toggleLayerSolo(let layer):
            toggleLayerSolo(layer)
            return true
        case .applyLayerPreset(let preset):
            applyLayerPreset(preset)
            return true
        case .resetLayerSettings:
            resetLayerSettings()
            return true
        case .setOverlaySettings(let settings):
            mapOverlaySettings = settings
            return true
        case .selectBrush(let rawValue):
            selectBrush(rawValue: rawValue)
            return true
        case .selectMapCell(let x, let y, let target):
            let previous = selectedMapCell
            selectMapCell(x: x, y: y, target: target)
            return selectedMapCell != previous
        case .eyedropMapCell(let x, let y, let target):
            let previousBrush = selectedBrushRawValue
            let previousCell = selectedMapCell
            eyedropMapCell(x: x, y: y, target: target)
            return selectedBrushRawValue != previousBrush || selectedMapCell != previousCell
        case .paintMapCell(let x, let y, let target):
            return paintMapCell(x: x, y: y, target: target)
        case .fillMapFromSelection(let x, let y, let target):
            return fillMapFromSelection(toX: x, y: y, target: target)
        case .fillMapRectangle(let x, let y, let width, let height, let target, let rawValue):
            return fillMapRectangle(x: x, y: y, width: width, height: height, target: target, rawValue: rawValue)
        case .updateSelectedBlockCollision(let collision):
            return updateSelectedBlockCollision(collision)
        case .updateSelectedBlockElevation(let elevation):
            return updateSelectedBlockElevation(elevation)
        case .shiftMap(let deltaX, let deltaY, let fillRawValue):
            return shiftMap(deltaX: deltaX, deltaY: deltaY, fillRawValue: fillRawValue)
        case .pasteBlockPattern(let x, let y, let width, let height, let target, let rawValues):
            return pasteBlockPattern(x: x, y: y, width: width, height: height, target: target, rawValues: rawValues)
        case .selectMapEvent(let id):
            let previous = selectedMapEventID
            selectMapEvent(id: id)
            return selectedMapEventID != previous
        case .moveSelectedMapEvent(let x, let y):
            return moveSelectedMapEvent(toX: x, y: y)
        case .updateSelectedMapEventProperty(let key, let value):
            return updateSelectedMapEventProperty(key: key, value: value)
        case .addObjectEvent(let x, let y):
            return addObjectEvent(atX: x, y: y)
        case .selectEventTemplate(let template):
            selectEventTemplate(template)
            return true
        case .addMapEvent(let template, let x, let y):
            return addMapEvent(template: template, atX: x, y: y)
        case .duplicateSelectedMapEvent:
            return duplicateSelectedMapEvent()
        case .deleteSelectedMapEvent:
            return deleteSelectedMapEvent()
        case .updateMapHeaderField(let key, let value):
            return updateMapHeaderField(key: key, value: value)
        case .updateConnectionField(let index, let key, let value):
            return updateConnectionField(index: index, key: key, value: value)
        case .addConnection(let properties):
            return addConnection(properties: properties)
        case .duplicateConnection(let index):
            return duplicateConnection(index: index)
        case .deleteConnection(let index):
            return deleteConnection(index: index)
        case .updateWildEncounterField(let sourcePath, let jsonPath, let key, let value):
            return updateWildEncounterField(sourcePath: sourcePath, jsonPath: jsonPath, key: key, value: value)
        case .updateMetatileAttribute(let metatileID, let tilesetSymbol, let key, let value):
            return updateMetatileAttribute(metatileID: metatileID, tilesetSymbol: tilesetSymbol, key: key, value: value)
        case .updateMetatileTile(let metatileID, let tilesetSymbol, let tileEntryIndex, let rawValue):
            return updateMetatileTile(metatileID: metatileID, tilesetSymbol: tilesetSymbol, tileEntryIndex: tileEntryIndex, rawValue: rawValue)
        case .updateScriptBody(let label, let sourcePath, let body):
            return updateScriptBody(label: label, sourcePath: sourcePath, body: body)
        case .createMapScriptLabel(let label, let sourcePath, let body):
            return createScriptLabel(label: label, sourcePath: sourcePath, body: body)
        case .undo:
            guard hasUndo else { return false }
            undoLastMapEdit()
            return true
        case .redo:
            guard hasRedo else { return false }
            redoMapEdit()
            return true
        case .discardChanges:
            guard canDiscardMapEdits else { return false }
            discardChanges()
            return true
        case .reset:
            reset()
            return true
        case .clearSelection:
            clearSelection()
            return true
        case .previewMutationPlan:
            return previewSelectedMapMutationPlan() != nil
        }
    }

    private func paintMapCell(x: Int, y: Int, target: MapBlockTarget, rawValue: UInt16) -> Bool {
        guard setBlockValue(rawValue, x: x, y: y, target: target) else { return false }
        selectedMapCell = MapCellSelection(x: x, y: y, rawValue: rawValue)
        selectedMapBlockTarget = target
        appendHistory(
            command: .paintMapCell(x: x, y: y, target: target),
            operations: [MapEditOperation(action: .paintMetatile, target: target, x: x, y: y, rawValue: rawValue)]
        )
        return true
    }

    private func stageSourceOnlyOperation(command: MapEditorCommand, operation: MapEditOperation) -> Bool {
        appendHistory(command: command, operations: [operation])
        return true
    }

    private func updateBlockAttributes(
        x: Int,
        y: Int,
        target: MapBlockTarget,
        collision: Int?,
        elevation: Int?
    ) -> Bool {
        guard let rawValue = blockValue(x: x, y: y, target: target) else { return false }
        guard collision != nil || elevation != nil else { return false }
        if let collision, !(0...3).contains(collision) { return false }
        if let elevation, !(0...15).contains(elevation) { return false }

        var nextValue = rawValue
        if let collision {
            nextValue = (nextValue & 0xf3ff) | (UInt16(collision) << 10)
        }
        if let elevation {
            nextValue = (nextValue & 0x0fff) | (UInt16(elevation) << 12)
        }
        guard nextValue != rawValue else { return false }
        guard setBlockValue(nextValue, x: x, y: y, target: target) else { return false }
        selectedMapCell = MapCellSelection(x: x, y: y, rawValue: nextValue)
        selectedMapBlockTarget = target
        return true
    }

    private func shiftStagedLayout(deltaX: Int, deltaY: Int, fillRawValue: UInt16) -> Bool {
        guard let document = selectedMapVisualDocument else { return false }
        let width = document.blockdata.width
        let height = document.blockdata.height
        guard width > 0, height > 0, stagedMapBlockdataValues.count == width * height else { return false }

        let original = stagedMapBlockdataValues
        var shifted = Array(repeating: fillRawValue, count: original.count)
        for y in 0..<height {
            for x in 0..<width {
                let sourceX = x - deltaX
                let sourceY = y - deltaY
                guard sourceX >= 0, sourceY >= 0, sourceX < width, sourceY < height else { continue }
                shifted[y * width + x] = original[sourceY * width + sourceX]
            }
        }
        guard shifted != original else { return false }
        stagedMapBlockdataValues = shifted
        restoreSelection(cell: selectedMapCell, target: selectedMapBlockTarget, eventID: selectedMapEventID)
        return true
    }

    private func pasteStagedBlockPattern(
        x: Int,
        y: Int,
        width: Int,
        height: Int,
        target: MapBlockTarget,
        rawValues: [UInt16]
    ) -> Bool {
        guard width > 0, height > 0, rawValues.count >= width * height else { return false }
        var didChange = false
        for row in 0..<height {
            for column in 0..<width {
                let value = rawValues[row * width + column]
                didChange = setBlockValue(value, x: x + column, y: y + row, target: target) || didChange
            }
        }
        guard didChange else { return false }
        if let rawValue = blockValue(x: x, y: y, target: target) {
            selectedMapCell = MapCellSelection(x: x, y: y, rawValue: rawValue)
            selectedMapBlockTarget = target
        }
        return true
    }

    private func blockValue(x: Int, y: Int, target: MapBlockTarget) -> UInt16? {
        guard let index = blockIndex(x: x, y: y, target: target) else { return nil }
        switch target {
        case .layout:
            guard stagedMapBlockdataValues.indices.contains(index) else { return nil }
            return stagedMapBlockdataValues[index]
        case .border:
            guard stagedMapBorderValues.indices.contains(index) else { return nil }
            return stagedMapBorderValues[index]
        }
    }

    private func setBlockValue(_ rawValue: UInt16, x: Int, y: Int, target: MapBlockTarget) -> Bool {
        guard let index = blockIndex(x: x, y: y, target: target) else { return false }
        switch target {
        case .layout:
            guard stagedMapBlockdataValues.indices.contains(index), stagedMapBlockdataValues[index] != rawValue else {
                return false
            }
            stagedMapBlockdataValues[index] = rawValue
            return true
        case .border:
            guard stagedMapBorderValues.indices.contains(index), stagedMapBorderValues[index] != rawValue else {
                return false
            }
            stagedMapBorderValues[index] = rawValue
            return true
        }
    }

    private func blockIndex(x: Int, y: Int, target: MapBlockTarget) -> Int? {
        guard x >= 0, y >= 0 else { return nil }
        switch target {
        case .layout:
            guard let document = selectedMapVisualDocument,
                  x < document.blockdata.width,
                  y < document.blockdata.height
            else {
                return nil
            }
            return y * document.blockdata.width + x
        case .border:
            guard let border = selectedMapVisualDocument?.border,
                  x < border.width,
                  y < border.height
            else {
                return nil
            }
            return y * border.width + x
        }
    }

    private func appendHistory(command: MapEditorCommand, operations: [MapEditOperation]) {
        guard !operations.isEmpty else { return }
        undoStack.append(MapEditorHistoryEntry(command: command, operations: operations))
        redoStack = []
        latestMapEditPlan = nil
        latestMapApplyResult = nil
        needsDocumentReloadAfterApply = false
    }

    private func rebuildStagedMapStateFromHistory() {
        guard let document = selectedMapVisualDocument else { return }
        let previousCell = selectedMapCell
        let previousCellTarget = selectedMapBlockTarget
        let previousEventID = selectedMapEventID

        stagedMapBlockdataValues = document.blockdata.rawValues
        stagedMapBorderValues = document.border?.rawValues ?? []
        stagedMapEvents = Self.normalizedEvents(document.events)
        stagedMapScriptBodies = [:]
        selectedMapCell = nil
        selectedMapBlockTarget = .layout
        selectedMapEventID = nil

        for operation in mapEditOperations {
            apply(operation)
        }

        restoreSelection(cell: previousCell, target: previousCellTarget, eventID: previousEventID)
        latestMapEditPlan = nil
        latestMapApplyResult = nil
        needsDocumentReloadAfterApply = false
    }

    private func apply(_ operation: MapEditOperation) {
        switch operation.action {
        case .paintMetatile:
            if let x = operation.x, let y = operation.y, let rawValue = operation.rawValue {
                _ = setBlockValue(rawValue, x: x, y: y, target: operation.target ?? .layout)
                selectedMapCell = MapCellSelection(x: x, y: y, rawValue: rawValue)
                selectedMapBlockTarget = operation.target ?? .layout
            }
        case .fillMetatile:
            if let x = operation.x,
               let y = operation.y,
               let width = operation.width,
               let height = operation.height,
               let rawValue = operation.rawValue {
                for fillY in y..<(y + height) {
                    for fillX in x..<(x + width) {
                        _ = setBlockValue(rawValue, x: fillX, y: fillY, target: operation.target ?? .layout)
                    }
                }
                selectedMapCell = MapCellSelection(x: x + width - 1, y: y + height - 1, rawValue: rawValue)
                selectedMapBlockTarget = operation.target ?? .layout
            }
        case .updateBlockCollision:
            if let x = operation.x, let y = operation.y {
                _ = updateBlockAttributes(
                    x: x,
                    y: y,
                    target: operation.target ?? .layout,
                    collision: operation.collision ?? operation.rawValue.map(Int.init),
                    elevation: nil
                )
            }
        case .updateBlockElevation:
            if let x = operation.x, let y = operation.y {
                _ = updateBlockAttributes(
                    x: x,
                    y: y,
                    target: operation.target ?? .layout,
                    collision: nil,
                    elevation: operation.elevation ?? operation.rawValue.map(Int.init)
                )
            }
        case .updateBlockAttributes:
            if let x = operation.x, let y = operation.y {
                _ = updateBlockAttributes(
                    x: x,
                    y: y,
                    target: operation.target ?? .layout,
                    collision: operation.collision,
                    elevation: operation.elevation
                )
            }
        case .shiftMap:
            _ = shiftStagedLayout(
                deltaX: operation.deltaX ?? 0,
                deltaY: operation.deltaY ?? 0,
                fillRawValue: operation.defaultRawValue ?? 0
            )
        case .resizeMap:
            if let newWidth = operation.newWidth ?? operation.width,
               let newHeight = operation.newHeight ?? operation.height,
               let document = selectedMapVisualDocument,
               newWidth > 0,
               newHeight > 0,
               stagedMapBlockdataValues.count == document.blockdata.width * document.blockdata.height {
                let original = stagedMapBlockdataValues
                var resized = Array(repeating: operation.defaultRawValue ?? 0, count: newWidth * newHeight)
                let copyWidth = min(document.blockdata.width, newWidth)
                let copyHeight = min(document.blockdata.height, newHeight)
                for row in 0..<copyHeight {
                    for column in 0..<copyWidth {
                        resized[row * newWidth + column] = original[row * document.blockdata.width + column]
                    }
                }
                stagedMapBlockdataValues = resized
                selectedMapCell = nil
                selectedMapBlockTarget = .layout
            }
        case .pasteBlockPattern:
            if let x = operation.x, let y = operation.y, let width = operation.width, let height = operation.height, let rawValues = operation.rawValues {
                _ = pasteStagedBlockPattern(
                    x: x,
                    y: y,
                    width: width,
                    height: height,
                    target: operation.target ?? .layout,
                    rawValues: rawValues
                )
            }
        case .moveEvent:
            if let x = operation.x,
               let y = operation.y,
               let eventIndex = stagedMapEvents.firstIndex(where: { $0.kind == operation.eventKind && $0.index == operation.eventIndex }) {
                stagedMapEvents[eventIndex] = moved(stagedMapEvents[eventIndex], x: x, y: y)
                selectedMapEventID = stagedMapEvents[eventIndex].id
            }
        case .updateEventField:
            guard let kind = operation.eventKind,
                  let index = operation.eventIndex,
                  let key = operation.fieldKey,
                  let value = operation.fieldValue,
                  let eventIndex = stagedMapEvents.firstIndex(where: { $0.kind == kind && $0.index == index })
            else {
                break
            }
                stagedMapEvents[eventIndex] = updated(stagedMapEvents[eventIndex], key: key, value: value)
            selectedMapEventID = stagedMapEvents[eventIndex].id
        case .addEvent:
            guard let kind = operation.eventKind, let x = operation.x, let y = operation.y else { break }
            let index = stagedMapEvents.filter { $0.kind == kind }.count
            let event = Self.event(kind: kind, index: index, x: x, y: y, properties: operation.templateProperties)
            stagedMapEvents.append(event)
            stagedMapEvents = Self.normalizedEvents(stagedMapEvents)
            selectedMapEventID = event.id
        case .duplicateEvent:
            guard let source = stagedMapEvents.first(where: { $0.kind == operation.eventKind && $0.index == operation.eventIndex }),
                  let sourceIndex = stagedMapEvents.firstIndex(where: { $0.id == source.id })
            else {
                break
            }
            stagedMapEvents.insert(Self.duplicate(source, in: stagedMapEvents), at: stagedMapEvents.index(after: sourceIndex))
            stagedMapEvents = Self.normalizedEvents(stagedMapEvents)
            let duplicate = stagedMapEvents[stagedMapEvents.index(after: sourceIndex)]
            selectedMapEventID = duplicate.id
        case .deleteEvent:
            guard let kind = operation.eventKind, let index = operation.eventIndex else { break }
            stagedMapEvents.removeAll { $0.kind == kind && $0.index == index }
            stagedMapEvents = Self.normalizedEvents(stagedMapEvents)
            selectedMapEventID = nil
        case .updateScriptBody:
            guard let label = operation.scriptLabel,
                  let sourcePath = operation.scriptSourcePath,
                  let body = operation.scriptBody
            else {
                break
            }
            stageScriptBody(
                label: label,
                sourcePath: sourcePath,
                body: body,
                isNew: stagedMapScriptBodies[StagedMapScriptBody.key(label: label, sourcePath: sourcePath)]?.isNew ?? false
            )
        case .createMapScriptLabel:
            guard let label = operation.scriptLabel,
                  let sourcePath = operation.scriptSourcePath,
                  let body = operation.scriptBody
            else {
                break
            }
            stageScriptBody(label: label, sourcePath: sourcePath, body: body, isNew: true)
        case .updateMapHeaderField,
             .updateConnectionField,
             .addConnection,
             .duplicateConnection,
             .deleteConnection,
             .updateWildEncounterField,
             .updateMetatileTile,
             .updateMetatileAttribute:
            break
        }
    }

    private func restoreSelection(cell: MapCellSelection?, target: MapBlockTarget, eventID: String?) {
        if let cell, let rawValue = blockValue(x: cell.x, y: cell.y, target: target) {
            selectedMapCell = MapCellSelection(x: cell.x, y: cell.y, rawValue: rawValue)
            selectedMapBlockTarget = target
        } else if selectedMapCell == nil {
            selectedMapBlockTarget = .layout
        }

        if let eventID, stagedMapEvents.contains(where: { $0.id == eventID }) {
            selectedMapEventID = eventID
        }
    }

    private static func objectEventTemplate(x: Int, y: Int) -> [MapEventProperty] {
        [
            MapEventProperty(key: "local_id", value: "0"),
            MapEventProperty(key: "type", value: "object"),
            MapEventProperty(key: "graphics_id", value: "OBJ_EVENT_GFX_BOY_1"),
            MapEventProperty(key: "x", value: "\(x)"),
            MapEventProperty(key: "y", value: "\(y)"),
            MapEventProperty(key: "elevation", value: "3"),
            MapEventProperty(key: "movement_type", value: "MOVEMENT_TYPE_FACE_DOWN"),
            MapEventProperty(key: "movement_range_x", value: "0"),
            MapEventProperty(key: "movement_range_y", value: "0"),
            MapEventProperty(key: "trainer_type", value: "TRAINER_TYPE_NONE"),
            MapEventProperty(key: "trainer_sight_or_berry_tree_id", value: "0"),
            MapEventProperty(key: "script", value: "0x0"),
            MapEventProperty(key: "flag", value: "0")
        ]
    }

    private func stageScriptBody(label: String, sourcePath: String, body: String, isNew: Bool) {
        stagedMapScriptBodies[StagedMapScriptBody.key(label: label, sourcePath: sourcePath)] = StagedMapScriptBody(
            label: label,
            sourcePath: sourcePath,
            body: body,
            isNew: isNew
        )
    }

    private static func duplicate(_ event: MapEventDescriptor, in events: [MapEventDescriptor]) -> MapEventDescriptor {
        let index = events.filter { $0.kind == event.kind }.count
        let x = event.x.map { $0 + 1 }
        let y = event.y
        let properties = event.properties.map { property -> MapEventProperty in
            if property.key == "x", let x { return MapEventProperty(key: property.key, value: "\(x)") }
            if property.key == "y", let y { return MapEventProperty(key: property.key, value: "\(y)") }
            return property
        }
        return Self.event(kind: event.kind, index: index, x: x, y: y, properties: properties, sprite: event.sprite)
    }

    private func moved(_ event: MapEventDescriptor, x: Int, y: Int) -> MapEventDescriptor {
        updated(updated(event, key: "x", value: "\(x)"), key: "y", value: "\(y)")
    }

    private func updated(_ event: MapEventDescriptor, key: String, value: String) -> MapEventDescriptor {
        var didUpdate = false
        var properties = event.properties.map { property -> MapEventProperty in
            guard property.key == key else { return property }
            didUpdate = true
            return MapEventProperty(key: key, value: value)
        }
        if !didUpdate {
            properties.append(MapEventProperty(key: key, value: value))
        }

        let x = key == "x" ? Int(value) : event.x
        let y = key == "y" ? Int(value) : event.y
        let elevation = key == "elevation" ? Int(value) : event.elevation
        return MapEventDescriptor(
            kind: event.kind,
            index: event.index,
            x: x,
            y: y,
            elevation: elevation,
            properties: properties,
            sprite: key == "graphics_id" ? selectedMapVisualDocument?.eventOptions.sprite(for: value) : event.sprite
        )
    }

    private static func event(
        kind: MapEventKind,
        index: Int,
        x: Int?,
        y: Int?,
        properties: [MapEventProperty],
        sprite: MapEventSpriteDescriptor? = nil
    ) -> MapEventDescriptor {
        var keys = Set(properties.map(\.key))
        var normalized = properties.map { property -> MapEventProperty in
            if property.key == "x", let x { return MapEventProperty(key: property.key, value: "\(x)") }
            if property.key == "y", let y { return MapEventProperty(key: property.key, value: "\(y)") }
            return property
        }
        if !keys.contains("x"), let x {
            normalized.append(MapEventProperty(key: "x", value: "\(x)"))
            keys.insert("x")
        }
        if !keys.contains("y"), let y {
            normalized.append(MapEventProperty(key: "y", value: "\(y)"))
            keys.insert("y")
        }
        let elevation = normalized.first(where: { $0.key == "elevation" }).flatMap { Int($0.value) }
        return MapEventDescriptor(kind: kind, index: index, x: x, y: y, elevation: elevation, properties: normalized, sprite: sprite)
    }

    private static func normalizedEvents(_ events: [MapEventDescriptor]) -> [MapEventDescriptor] {
        var nextIndexByKind: [MapEventKind: Int] = [:]
        return events.map { event in
            let index = nextIndexByKind[event.kind, default: 0]
            nextIndexByKind[event.kind] = index + 1
            guard event.index != index else { return event }
            return MapEventDescriptor(
                kind: event.kind,
                index: index,
                x: event.x,
                y: event.y,
                elevation: event.elevation,
                properties: event.properties,
                sprite: event.sprite
            )
        }
    }
}
