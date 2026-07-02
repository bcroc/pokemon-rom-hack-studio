import Foundation

public struct NDSDataEditDraft: Codable, Equatable {
    public let recordID: String
    public var editedText: String

    public init(recordID: String, editedText: String) {
        self.recordID = recordID
        self.editedText = editedText
    }
}

public enum NDSDataSemanticFieldValueKind: String, Codable, Equatable {
    case string
    case number
    case bool
    case null
}

public struct NDSDataSemanticField: Codable, Equatable, Identifiable {
    public var id: String { key }

    public let key: String
    public let label: String
    public let value: String
    public let valueKind: NDSDataSemanticFieldValueKind
    public let sourceSpan: SourceSpan?

    public init(
        key: String,
        label: String,
        value: String,
        valueKind: NDSDataSemanticFieldValueKind,
        sourceSpan: SourceSpan? = nil
    ) {
        self.key = key
        self.label = label
        self.value = value
        self.valueKind = valueKind
        self.sourceSpan = sourceSpan
    }
}

public struct NDSDataSemanticSnapshot: Codable, Equatable {
    public let recordID: String
    public let domain: NDSDataDomain
    public let title: String
    public let fields: [NDSDataSemanticField]
    public let diagnostics: [Diagnostic]
    public let canEdit: Bool

    public init(
        recordID: String,
        domain: NDSDataDomain,
        title: String,
        fields: [NDSDataSemanticField],
        diagnostics: [Diagnostic],
        canEdit: Bool
    ) {
        self.recordID = recordID
        self.domain = domain
        self.title = title
        self.fields = fields
        self.diagnostics = diagnostics
        self.canEdit = canEdit
    }
}

public struct NDSDataSemanticFieldEdit: Codable, Equatable {
    public let key: String
    public let value: String

    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

public struct NDSDataSemanticEditDraft: Codable, Equatable {
    public let recordID: String
    public let fieldEdits: [NDSDataSemanticFieldEdit]

    public init(recordID: String, fieldEdits: [NDSDataSemanticFieldEdit]) {
        self.recordID = recordID
        self.fieldEdits = fieldEdits
    }
}

public struct NDSDataSemanticEditPlan: Codable, Equatable {
    public let snapshot: NDSDataSemanticSnapshot
    public let draft: NDSDataSemanticEditDraft
    public let textDraft: NDSDataEditDraft
    public let editPlan: NDSDataEditPlan
    public let diagnostics: [Diagnostic]

    public init(
        snapshot: NDSDataSemanticSnapshot,
        draft: NDSDataSemanticEditDraft,
        textDraft: NDSDataEditDraft,
        editPlan: NDSDataEditPlan,
        diagnostics: [Diagnostic]
    ) {
        self.snapshot = snapshot
        self.draft = draft
        self.textDraft = textDraft
        self.editPlan = editPlan
        self.diagnostics = diagnostics
    }
}

public enum NDSDataTextLineOperationKind: String, Codable, Equatable {
    case insert
    case delete
    case reorder
}

public struct NDSDataTextLineOperation: Codable, Equatable {
    public let kind: NDSDataTextLineOperationKind
    public let index: Int?
    public let text: String?
    public let fromIndex: Int?
    public let toIndex: Int?

    public init(kind: NDSDataTextLineOperationKind, index: Int? = nil, text: String? = nil, fromIndex: Int? = nil, toIndex: Int? = nil) {
        self.kind = kind
        self.index = index
        self.text = text
        self.fromIndex = fromIndex
        self.toIndex = toIndex
    }

    public static func insert(index: Int, text: String) -> NDSDataTextLineOperation {
        NDSDataTextLineOperation(kind: .insert, index: index, text: text)
    }

    public static func delete(index: Int) -> NDSDataTextLineOperation {
        NDSDataTextLineOperation(kind: .delete, index: index)
    }

    public static func reorder(fromIndex: Int, toIndex: Int) -> NDSDataTextLineOperation {
        NDSDataTextLineOperation(kind: .reorder, fromIndex: fromIndex, toIndex: toIndex)
    }
}

public struct NDSDataTextLineOperationDraft: Codable, Equatable {
    public let recordID: String
    public let operations: [NDSDataTextLineOperation]

    public init(recordID: String, operations: [NDSDataTextLineOperation]) {
        self.recordID = recordID
        self.operations = operations
    }
}

public struct NDSDataTextLineOperationPlan: Codable, Equatable {
    public let draft: NDSDataTextLineOperationDraft
    public let beforeLineCount: Int
    public let afterLineCount: Int
    public let diagnostics: [Diagnostic]
    public let editPlan: NDSDataEditPlan

    public init(
        draft: NDSDataTextLineOperationDraft,
        beforeLineCount: Int,
        afterLineCount: Int,
        diagnostics: [Diagnostic],
        editPlan: NDSDataEditPlan
    ) {
        self.draft = draft
        self.beforeLineCount = beforeLineCount
        self.afterLineCount = afterLineCount
        self.diagnostics = diagnostics
        self.editPlan = editPlan
    }
}

public enum NDSDataItemCSVRowOperationKind: String, Codable, Equatable {
    case insert
    case delete
    case reorder
}

public struct NDSDataItemCSVRowOperation: Codable, Equatable {
    public let kind: NDSDataItemCSVRowOperationKind
    public let index: Int?
    public let rowText: String?
    public let fromIndex: Int?
    public let toIndex: Int?

    public init(kind: NDSDataItemCSVRowOperationKind, index: Int? = nil, rowText: String? = nil, fromIndex: Int? = nil, toIndex: Int? = nil) {
        self.kind = kind
        self.index = index
        self.rowText = rowText
        self.fromIndex = fromIndex
        self.toIndex = toIndex
    }

    public static func insert(index: Int, rowText: String) -> NDSDataItemCSVRowOperation {
        NDSDataItemCSVRowOperation(kind: .insert, index: index, rowText: rowText)
    }

    public static func delete(index: Int) -> NDSDataItemCSVRowOperation {
        NDSDataItemCSVRowOperation(kind: .delete, index: index)
    }

    public static func reorder(fromIndex: Int, toIndex: Int) -> NDSDataItemCSVRowOperation {
        NDSDataItemCSVRowOperation(kind: .reorder, fromIndex: fromIndex, toIndex: toIndex)
    }
}

public struct NDSDataItemCSVRowOperationDraft: Codable, Equatable {
    public let recordID: String
    public let operations: [NDSDataItemCSVRowOperation]

    public init(recordID: String, operations: [NDSDataItemCSVRowOperation]) {
        self.recordID = recordID
        self.operations = operations
    }
}

public struct NDSDataItemCSVRowOperationPlan: Codable, Equatable {
    public let draft: NDSDataItemCSVRowOperationDraft
    public let beforeRowCount: Int
    public let afterRowCount: Int
    public let diagnostics: [Diagnostic]
    public let editPlan: NDSDataEditPlan

    public init(
        draft: NDSDataItemCSVRowOperationDraft,
        beforeRowCount: Int,
        afterRowCount: Int,
        diagnostics: [Diagnostic],
        editPlan: NDSDataEditPlan
    ) {
        self.draft = draft
        self.beforeRowCount = beforeRowCount
        self.afterRowCount = afterRowCount
        self.diagnostics = diagnostics
        self.editPlan = editPlan
    }
}

public enum NDSDataEncounterJSONRowOperationKind: String, Codable, Equatable {
    case insert
    case delete
    case reorder
}

public struct NDSDataEncounterJSONRowOperation: Codable, Equatable {
    public let kind: NDSDataEncounterJSONRowOperationKind
    public let index: Int?
    public let rowText: String?
    public let fromIndex: Int?
    public let toIndex: Int?

    public init(kind: NDSDataEncounterJSONRowOperationKind, index: Int? = nil, rowText: String? = nil, fromIndex: Int? = nil, toIndex: Int? = nil) {
        self.kind = kind
        self.index = index
        self.rowText = rowText
        self.fromIndex = fromIndex
        self.toIndex = toIndex
    }

    public static func insert(index: Int, rowText: String) -> NDSDataEncounterJSONRowOperation {
        NDSDataEncounterJSONRowOperation(kind: .insert, index: index, rowText: rowText)
    }

    public static func delete(index: Int) -> NDSDataEncounterJSONRowOperation {
        NDSDataEncounterJSONRowOperation(kind: .delete, index: index)
    }

    public static func reorder(fromIndex: Int, toIndex: Int) -> NDSDataEncounterJSONRowOperation {
        NDSDataEncounterJSONRowOperation(kind: .reorder, fromIndex: fromIndex, toIndex: toIndex)
    }
}

public struct NDSDataEncounterJSONRowOperationDraft: Codable, Equatable {
    public let recordID: String
    public let arrayKey: String
    public let operations: [NDSDataEncounterJSONRowOperation]

    public init(recordID: String, arrayKey: String, operations: [NDSDataEncounterJSONRowOperation]) {
        self.recordID = recordID
        self.arrayKey = arrayKey
        self.operations = operations
    }
}

public struct NDSDataEncounterJSONRowOperationPlan: Codable, Equatable {
    public let draft: NDSDataEncounterJSONRowOperationDraft
    public let beforeRowCount: Int
    public let afterRowCount: Int
    public let diagnostics: [Diagnostic]
    public let editPlan: NDSDataEditPlan

    public init(
        draft: NDSDataEncounterJSONRowOperationDraft,
        beforeRowCount: Int,
        afterRowCount: Int,
        diagnostics: [Diagnostic],
        editPlan: NDSDataEditPlan
    ) {
        self.draft = draft
        self.beforeRowCount = beforeRowCount
        self.afterRowCount = afterRowCount
        self.diagnostics = diagnostics
        self.editPlan = editPlan
    }
}

public struct NDSDataEditFileChange: Codable, Equatable, Identifiable {
    public let id: String
    public let path: String
    public let summary: String
    public let originalSHA1: String?
    public let originalByteCount: Int
    public let newByteCount: Int
    public let textPreview: String
    public let newData: Data

    public init(
        id: String = UUID().uuidString,
        path: String,
        summary: String,
        originalSHA1: String?,
        originalByteCount: Int,
        newByteCount: Int,
        textPreview: String,
        newData: Data
    ) {
        self.id = id
        self.path = path
        self.summary = summary
        self.originalSHA1 = originalSHA1
        self.originalByteCount = originalByteCount
        self.newByteCount = newByteCount
        self.textPreview = textPreview
        self.newData = newData
    }
}

public struct NDSDataEditApplyability: Codable, Equatable {
    public let isApplyable: Bool
    public let diagnostics: [Diagnostic]

    public init(isApplyable: Bool, diagnostics: [Diagnostic]) {
        self.isApplyable = isApplyable
        self.diagnostics = diagnostics
    }
}

public struct NDSDataEditPlan: Codable, Equatable {
    public let rootPath: String
    public let recordID: String
    public let draft: NDSDataEditDraft
    public let changes: [NDSDataEditFileChange]
    public let diagnostics: [Diagnostic]
    public let mutationPlan: MutationPlan
    public let backupRelativeRoot: String

    public init(
        rootPath: String,
        recordID: String,
        draft: NDSDataEditDraft,
        changes: [NDSDataEditFileChange],
        diagnostics: [Diagnostic],
        mutationPlan: MutationPlan,
        backupRelativeRoot: String
    ) {
        self.rootPath = rootPath
        self.recordID = recordID
        self.draft = draft
        self.changes = changes
        self.diagnostics = diagnostics
        self.mutationPlan = mutationPlan
        self.backupRelativeRoot = backupRelativeRoot
    }

    public func validateApplyability(fileManager: FileManager = .default) -> NDSDataEditApplyability {
        NDSDataEditApplySafety.applyability(for: self, fileManager: fileManager)
    }
}

public struct AppliedNDSDataFileChange: Codable, Equatable, Identifiable {
    public let id: String
    public let path: String
    public let backupPath: String
    public let byteCount: Int

    public init(id: String = UUID().uuidString, path: String, backupPath: String, byteCount: Int) {
        self.id = id
        self.path = path
        self.backupPath = backupPath
        self.byteCount = byteCount
    }
}

public struct NDSDataApplyResult: Codable, Equatable, Identifiable {
    public let id: String
    public let backupRootPath: String
    public let appliedChanges: [AppliedNDSDataFileChange]
    public let diagnostics: [Diagnostic]

    public init(
        id: String = UUID().uuidString,
        backupRootPath: String,
        appliedChanges: [AppliedNDSDataFileChange],
        diagnostics: [Diagnostic] = []
    ) {
        self.id = id
        self.backupRootPath = backupRootPath
        self.appliedChanges = appliedChanges
        self.diagnostics = diagnostics
    }
}

public enum NDSDataSemanticEditor {
    private static let diamondPearlMoveCAnchorPath = "arm9/src/waza.c"
    private static let diamondPearlMoveTableSymbol = "sWazaTbl"
    private static let diamondPearlItemCAnchorPath = "arm9/src/itemtool.c"
    private static let diamondPearlItemMappingTableSymbol = "sItemIndexMappings"
    private static let diamondPearlTrainerCAnchorPath = "arm9/src/trainer_data.c"
    private static let diamondPearlTrainerClassGenderTableSymbol = "sTrainerClassGenderCountTbl"
    private static let diamondPearlMapHeaderCAnchorPath = "arm9/src/map_header.c"
    private static let diamondPearlMapHeaderTableSymbol = "sMapHeaders"
    private static let heartGoldSoulSilverMapHeaderCAnchorPath = "src/data/map_headers.h"
    private static let heartGoldSoulSilverMapHeaderTableSymbol = "sMapHeaders"

    private enum DiamondPearlMoveField: String, CaseIterable {
        case effect
        case moveClass = "class"
        case power
        case type
        case accuracy
        case pp
        case effectChance
        case unk8
        case priority
        case unkB
        case unkC
        case contestType

        var key: String {
            rawValue
        }

        var label: String {
            switch self {
            case .effect: return "Effect"
            case .moveClass: return "Class"
            case .power: return "Power"
            case .type: return "Type"
            case .accuracy: return "Accuracy"
            case .pp: return "PP"
            case .effectChance: return "Effect Chance"
            case .unk8: return "Unknown 8"
            case .priority: return "Priority"
            case .unkB: return "Unknown B"
            case .unkC: return "Unknown C"
            case .contestType: return "Contest Type"
            }
        }
    }

    private enum DiamondPearlItemMappingField: Int, CaseIterable {
        case itemDataIndex
        case iconIndex
        case paletteIndex
        case gen3Index

        var key: String {
            switch self {
            case .itemDataIndex: return "itemDataIndex"
            case .iconIndex: return "iconIndex"
            case .paletteIndex: return "paletteIndex"
            case .gen3Index: return "gen3Index"
            }
        }

        var label: String {
            switch self {
            case .itemDataIndex: return "Item Data Index"
            case .iconIndex: return "Icon Index"
            case .paletteIndex: return "Palette Index"
            case .gen3Index: return "Gen III Index"
            }
        }
    }

    private enum DiamondPearlMapHeaderField: Int, CaseIterable {
        case areaDataBank
        case moveModelBank
        case matrixId
        case scriptsBank
        case levelScriptsBank
        case msgBank
        case dayMusicId
        case nightMusicId
        case wildEncounterBank
        case eventsBank
        case mapSection
        case weatherType
        case cameraType
        case mapType
        case battleBg
        case isBikeAllowed
        case isRunningAllowed
        case isEscapeRopeAllowed
        case isFlyAllowed

        var key: String {
            switch self {
            case .areaDataBank: return "areaDataBank"
            case .moveModelBank: return "moveModelBank"
            case .matrixId: return "matrixId"
            case .scriptsBank: return "scriptsBank"
            case .levelScriptsBank: return "levelScriptsBank"
            case .msgBank: return "msgBank"
            case .dayMusicId: return "dayMusicId"
            case .nightMusicId: return "nightMusicId"
            case .wildEncounterBank: return "wildEncounterBank"
            case .eventsBank: return "eventsBank"
            case .mapSection: return "mapSection"
            case .weatherType: return "weatherType"
            case .cameraType: return "cameraType"
            case .mapType: return "mapType"
            case .battleBg: return "battleBg"
            case .isBikeAllowed: return "isBikeAllowed"
            case .isRunningAllowed: return "isRunningAllowed"
            case .isEscapeRopeAllowed: return "isEscapeRopeAllowed"
            case .isFlyAllowed: return "isFlyAllowed"
            }
        }

        var label: String {
            switch self {
            case .areaDataBank: return "Area Data Bank"
            case .moveModelBank: return "Move Model Bank"
            case .matrixId: return "Matrix ID"
            case .scriptsBank: return "Scripts Bank"
            case .levelScriptsBank: return "Level Scripts Bank"
            case .msgBank: return "Message Bank"
            case .dayMusicId: return "Day Music ID"
            case .nightMusicId: return "Night Music ID"
            case .wildEncounterBank: return "Wild Encounter Bank"
            case .eventsBank: return "Events Bank"
            case .mapSection: return "Map Section"
            case .weatherType: return "Weather Type"
            case .cameraType: return "Camera Type"
            case .mapType: return "Map Type"
            case .battleBg: return "Battle Background"
            case .isBikeAllowed: return "Bike Allowed"
            case .isRunningAllowed: return "Running Allowed"
            case .isEscapeRopeAllowed: return "Escape Rope Allowed"
            case .isFlyAllowed: return "Fly Allowed"
            }
        }
    }

    private enum SemanticFieldSyntax {
        case json
        case cScalar
        case cSimpleScalar
        case csvCell
        case textLine
        case textJSONString
    }

    public static func snapshot(
        catalog: ProjectNDSDataCatalog,
        recordID: String,
        fileManager: FileManager = .default
    ) -> NDSDataSemanticSnapshot {
        guard let record = catalog.records.first(where: { $0.id == recordID }) else {
            let diagnostics = [
                Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_RECORD_MISSING", message: "NDS data record \(recordID) is not in the current catalog.")
            ]
            return NDSDataSemanticSnapshot(recordID: recordID, domain: .resources, title: recordID, fields: [], diagnostics: diagnostics, canEdit: false)
        }

        var diagnostics = semanticEligibilityDiagnostics(catalog: catalog, record: record, fileManager: fileManager)
        var fields: [NDSDataSemanticField] = []
        if diagnostics.allSatisfy({ $0.severity != .error }),
           let sourceText = NDSDataMutationPlanner.sourceText(catalog: catalog, recordID: recordID, fileManager: fileManager) {
            let parsed = parseSemanticFields(sourceText: sourceText, record: record, profile: catalog.profile)
            fields = parsed.fields.map(\.semanticField)
            diagnostics.append(contentsOf: parsed.diagnostics)
            if fields.isEmpty, parsed.diagnostics.allSatisfy({ $0.severity != .error }) {
                diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_NO_FIELDS", message: "No scalar fields are available for semantic editing: \(record.relativePath).", span: record.sourceSpan))
            }
        }

        return NDSDataSemanticSnapshot(
            recordID: recordID,
            domain: record.domain,
            title: record.title,
            fields: fields,
            diagnostics: diagnostics,
            canEdit: diagnostics.allSatisfy { $0.severity != .error } && !fields.isEmpty
        )
    }

    public static func plan(
        catalog: ProjectNDSDataCatalog,
        draft: NDSDataSemanticEditDraft,
        fileManager: FileManager = .default
    ) -> NDSDataSemanticEditPlan {
        let snapshot = snapshot(catalog: catalog, recordID: draft.recordID, fileManager: fileManager)
        let sourceText = NDSDataMutationPlanner.sourceText(catalog: catalog, recordID: draft.recordID, fileManager: fileManager) ?? ""
        let record = catalog.records.first(where: { $0.id == draft.recordID })
        let editResult = snapshot.canEdit
            ? updateSourceText(sourceText, fieldEdits: draft.fieldEdits, recordID: draft.recordID, record: record, profile: catalog.profile)
            : (text: sourceText, diagnostics: [])
        let textDraft = NDSDataEditDraft(recordID: draft.recordID, editedText: editResult.text)
        let semanticDiagnostics = snapshot.diagnostics + editResult.diagnostics
        let editPlan: NDSDataEditPlan
        if semanticDiagnostics.contains(where: { $0.severity == .error }) {
            editPlan = blockedEditPlan(catalog: catalog, draft: textDraft, diagnostics: semanticDiagnostics)
        } else {
            editPlan = NDSDataMutationPlanner.plan(catalog: catalog, draft: textDraft, fileManager: fileManager)
        }
        let diagnostics = semanticDiagnostics + editPlan.diagnostics
        return NDSDataSemanticEditPlan(snapshot: snapshot, draft: draft, textDraft: textDraft, editPlan: editPlan, diagnostics: diagnostics)
    }

    public static func updateSourceText(
        _ sourceText: String,
        fieldEdit: NDSDataSemanticFieldEdit,
        recordID: String
    ) -> (text: String, diagnostics: [Diagnostic]) {
        updateSourceText(sourceText, fieldEdits: [fieldEdit], recordID: recordID)
    }

    public static func updateSourceText(
        _ sourceText: String,
        fieldEdit: NDSDataSemanticFieldEdit,
        recordID: String,
        record: NDSDataCatalogRecord
    ) -> (text: String, diagnostics: [Diagnostic]) {
        updateSourceText(sourceText, fieldEdits: [fieldEdit], recordID: recordID, record: record)
    }

    public static func fields(sourceText: String, recordID: String) -> [NDSDataSemanticField] {
        parseSemanticFields(sourceText: sourceText, record: nil, recordID: recordID).fields.map(\.semanticField)
    }

    public static func fields(sourceText: String, recordID: String, record: NDSDataCatalogRecord) -> [NDSDataSemanticField] {
        parseSemanticFields(sourceText: sourceText, record: record, recordID: recordID).fields.map(\.semanticField)
    }

    public static func updateSourceText(
        _ sourceText: String,
        fieldEdits: [NDSDataSemanticFieldEdit],
        recordID: String
    ) -> (text: String, diagnostics: [Diagnostic]) {
        updateSourceText(sourceText, fieldEdits: fieldEdits, recordID: recordID, record: nil)
    }

    public static func updateSourceText(
        _ sourceText: String,
        fieldEdits: [NDSDataSemanticFieldEdit],
        recordID: String,
        record: NDSDataCatalogRecord
    ) -> (text: String, diagnostics: [Diagnostic]) {
        updateSourceText(sourceText, fieldEdits: fieldEdits, recordID: recordID, record: Optional(record))
    }

    private static func updateSourceText(
        _ sourceText: String,
        fieldEdits: [NDSDataSemanticFieldEdit],
        recordID: String,
        record: NDSDataCatalogRecord?,
        profile: GameProfile? = nil
    ) -> (text: String, diagnostics: [Diagnostic]) {
        let parsed = parseSemanticFields(sourceText: sourceText, record: record, recordID: recordID, profile: profile)
        var diagnostics = parsed.diagnostics
        var text = sourceText
        var fieldsByKey: [String: ParsedSemanticField] = [:]
        for field in parsed.fields where fieldsByKey[field.semanticField.key] == nil {
            fieldsByKey[field.semanticField.key] = field
        }
        var seenKeys = Set<String>()
        var duplicateKeys = Set<String>()
        for edit in fieldEdits {
            if !seenKeys.insert(edit.key).inserted {
                duplicateKeys.insert(edit.key)
            }
        }
        for key in duplicateKeys.sorted() {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_SEMANTIC_FIELD_DUPLICATE",
                    message: "Semantic NDS field \(key) was edited more than once in the same plan; submit one value per field."
                )
            )
        }
        guard duplicateKeys.isEmpty else {
            return (sourceText, diagnostics)
        }

        var replacements: [(range: Range<String.Index>, value: String)] = []
        for edit in fieldEdits {
            guard let field = fieldsByKey[edit.key] else {
                let rootKey = edit.key.split(separator: ".").first.map(String.init) ?? edit.key
                if parsed.unsupportedNestedKeys.contains(rootKey) {
                    diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED", message: "Semantic NDS field \(edit.key) targets nested JSON that remains raw-source only on \(recordID)."))
                } else {
                    diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_FIELD_MISSING", message: "Semantic NDS field \(edit.key) is not available on \(recordID)."))
                    if rootKey == "slots", edit.key.contains(".") {
                        diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_NESTED_EDIT_UNSUPPORTED", message: "Semantic NDS field \(edit.key) targets an unavailable encounter slot path on \(recordID)."))
                    }
                }
                continue
            }
            guard let rendered = renderedValue(edit.value, for: field) else {
                diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_VALUE_INVALID", message: "Semantic NDS field \(edit.key) received a value that cannot be rendered as \(field.semanticField.valueKind.rawValue)."))
                continue
            }
            replacements.append((field.valueRange, rendered))
        }

        for replacement in replacements.sorted(by: { $0.range.lowerBound > $1.range.lowerBound }) {
            text.replaceSubrange(replacement.range, with: replacement.value)
        }
        return (text, diagnostics)
    }

    private static func semanticEligibilityDiagnostics(
        catalog: ProjectNDSDataCatalog,
        record: NDSDataCatalogRecord,
        fileManager: FileManager
    ) -> [Diagnostic] {
        var diagnostics = NDSDataMutationPlanner.editabilityDiagnostics(catalog: catalog, recordID: record.id, fileManager: fileManager)
        if !isSemanticProfileSupported(catalog.profile, record: record) {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_PROFILE_BLOCKED", message: "Semantic Gen IV field editing is limited to Platinum source-tree Pokemon/move/item/trainer/trainer-class/encounter/field-event/map-matrix/area-data JSON records, existing text lines under res/text/**/*.txt, existing text JSON string leaves under res/text/**/*.json, HeartGold/SoulSilver personal/trainer/item JSON rows, direct item CSV rows, encounter JSON rows, zone-event JSON rows, and map header integer scalars, Diamond/Pearl personal/trainer/item/encounter/field-event/land-data/area-data JSON rows, the Diamond/Pearl move C anchor, the Diamond/Pearl item mapping C anchor, the Diamond/Pearl trainer class gender C anchor, and the Diamond/Pearl map header C anchor in this slice; \(catalog.profile.rawValue) stays on raw source editing for now.", span: record.sourceSpan))
        }
        if ![NDSDataDomain.species, .personal, .moves, .items, .trainers, .encounters, .maps, .scripts, .text].contains(record.domain) {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_DOMAIN_BLOCKED", message: "Semantic Gen IV field editing is limited to source-backed Pokemon, personal, move, item, trainer, encounter, field-event map, HGSS zone-event script, and Platinum text line or text JSON records in this slice.", span: record.sourceSpan))
        }
        if catalog.profile == .pokeheartgold, !isHeartGoldSoulSilverSemanticDataPath(record) {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_HGSS_PATH_BLOCKED", message: "Semantic HeartGold/SoulSilver editing is limited to source-backed personal JSON rows under files/poketool/personal, trainer JSON rows under files/poketool/trainer, item JSON rows and direct item CSV rows under files/itemtool/itemdata, encounter JSON rows under files/fielddata/encountdata, direct zone-event JSON rows under files/fielddata/eventdata/zone_event, and map header integer scalars in src/data/map_headers.h; NARC, generated, script binary, inventory-only map matrix/map table relationship rows, nested map directories, nested item CSV rows, binary item rows, and nested event rows remain raw-source or read-only.", span: record.sourceSpan))
        }
        if catalog.profile == .pokediamond, !isDiamondPearlSemanticDataPath(record) {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_DP_PATH_BLOCKED", message: "Semantic Diamond/Pearl editing is limited to source-backed personal JSON rows under files/poketool/personal or files/poketool/personal_pearl, trainer JSON rows under files/poketool/trainer, item JSON rows under files/itemtool/itemdata, encounter JSON rows under files/fielddata/encountdata, direct field-event JSON rows under files/fielddata/eventdata, direct land-data JSON rows under files/fielddata/land_data, direct area-data JSON rows under files/fielddata/areadata, move scalars in arm9/src/waza.c, item mapping scalars in arm9/src/itemtool.c, trainer class gender scalars in arm9/src/trainer_data.c, and map header integer scalars in arm9/src/map_header.c; NARC, container, generated, binary, reference, and ROM rows remain raw-source or read-only.", span: record.sourceSpan))
        }
        if record.domain == .moves, !isSemanticMoveDataPath(catalog.profile, record.relativePath) {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_MOVE_PATH_BLOCKED", message: "Semantic move editing is limited to Platinum source-backed JSON rows directly under res/battle/moves and Diamond/Pearl move scalars in arm9/src/waza.c; nested move tables, HeartGold/SoulSilver move containers, generated/reference rows, ROM/export/rebuild paths, row insert/remove/reorder, and binary writes remain raw-source or read-only.", span: record.sourceSpan))
        }
        if record.domain == .items, !isSemanticItemDataPath(catalog.profile, record.relativePath) {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_ITEM_PATH_BLOCKED", message: "Semantic item editing is limited to Platinum item JSON rows under res/items, HeartGold/SoulSilver item JSON rows and direct item CSV rows under files/itemtool/itemdata, Diamond/Pearl item JSON rows under files/itemtool/itemdata, and Diamond/Pearl item mapping scalars in arm9/src/itemtool.c; non-HGSS CSV, generated, binary, container, and other item data remain on raw source editing or read-only surfaces.", span: record.sourceSpan))
        }
        if record.domain == .trainers, !isSemanticTrainerDataPath(catalog.profile, record.relativePath) {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_TRAINER_PATH_BLOCKED", message: "Semantic trainer editing is limited to Platinum trainer data JSON rows under res/trainers/data, direct Platinum trainer class JSON rows under res/trainers/classes, HeartGold/SoulSilver trainer JSON rows under files/poketool/trainer, Diamond/Pearl trainer JSON rows under files/poketool/trainer, and Diamond/Pearl trainer class gender scalars in arm9/src/trainer_data.c; nested trainer class rows, trainer resources, other C anchors, and other trainer assets remain on raw source editing or read-only surfaces.", span: record.sourceSpan))
        }
        if record.domain == .encounters, !isSemanticEncounterDataPath(catalog.profile, record.relativePath) {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_ENCOUNTER_PATH_BLOCKED", message: "Semantic encounter editing is limited to Platinum source-backed JSON rows directly under res/field/encounters, HeartGold/SoulSilver source-backed JSON rows under files/fielddata/encountdata, and Diamond/Pearl source-backed JSON rows under files/fielddata/encountdata; slot insert/delete/reorder, nested object reshaping, C anchors, containers, generated/reference rows, ROM/export/rebuild paths, and binary writes remain raw-source or read-only.", span: record.sourceSpan))
        }
        if record.domain == .maps, !isSemanticMapDataPath(catalog.profile, record.relativePath) {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_MAP_PATH_BLOCKED", message: "Semantic map/event editing is limited to Platinum source-backed JSON rows directly under res/field/events, res/field/matrices, or res/field/area_data, HeartGold/SoulSilver integer map-header scalars in src/data/map_headers.h, Diamond/Pearl direct JSON rows under files/fielddata/eventdata, files/fielddata/land_data, or files/fielddata/areadata, and Diamond/Pearl integer map-header scalars in arm9/src/map_header.c; nested event, matrix, land-data, or area-data directories, res/field/maps/**, map binaries, inventory-only map matrix/map table/root rows, scripts, other C anchors, generated/reference rows, ROM/export/rebuild/playtest paths, and binary writes remain raw-source or read-only.", span: record.sourceSpan))
        }
        if record.domain == .scripts, !isSemanticScriptDataPath(catalog.profile, record.relativePath) {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_SCRIPT_PATH_BLOCKED", message: "Semantic script/event editing is limited to HeartGold/SoulSilver direct source-backed JSON rows under files/fielddata/eventdata/zone_event; nested zone-event directories, binary script rows, map matrices, NARC/container rows, generated/reference rows, ROM/export/rebuild paths, and binary writes remain raw-source or read-only.", span: record.sourceSpan))
        }
        if record.domain == .text, !isSemanticTextDataPath(catalog.profile, record) {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_TEXT_PATH_BLOCKED", message: "Semantic text editing is limited to existing line contents in Platinum source-tree .txt rows under res/text/**/*.txt and existing string leaves in Platinum source-tree JSON rows under res/text/**/*.json; BMG/message-bank binary rows, JSON message-bank writers, containers, generated/reference rows, ROM-backed rows, multiline edits, insert/delete/reorder edits, extraction/rebuild/export paths, and binary writes remain raw-source or read-only.", span: record.sourceSpan))
        }
        if !isSemanticFormatSupported(catalog.profile, record) {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_FORMAT_BLOCKED", message: "Semantic Gen IV field editing requires source-backed JSON, an eligible Platinum source text .txt row, an eligible HeartGold/SoulSilver item CSV or map header row, or an explicitly supported Diamond/Pearl C anchor; \(record.format.rawValue) rows use the raw text editor or stay read-only.", span: record.sourceSpan))
        }
        return diagnostics
    }

    private static func isPlatinumTrainerDataPath(_ relativePath: String) -> Bool {
        relativePath.hasPrefix("res/trainers/data/") && relativePath.lowercased().hasSuffix(".json")
    }

    private static func isPlatinumTrainerClassDataPath(_ relativePath: String) -> Bool {
        let prefix = "res/trainers/classes/"
        let lower = relativePath.lowercased()
        guard lower.hasPrefix(prefix), lower.hasSuffix(".json") else { return false }
        let remainder = lower.dropFirst(prefix.count)
        return !remainder.isEmpty && !remainder.contains("/")
    }

    private static func isSemanticTrainerDataPath(_ profile: GameProfile, _ relativePath: String) -> Bool {
        switch profile {
        case .pokeplatinum:
            return isPlatinumTrainerDataPath(relativePath) || isPlatinumTrainerClassDataPath(relativePath)
        case .pokeheartgold:
            return isHeartGoldSoulSilverTrainerDataPath(relativePath)
        case .pokediamond:
            return isDiamondPearlTrainerDataPath(relativePath) || relativePath == diamondPearlTrainerCAnchorPath
        default:
            return false
        }
    }

    private static func isPlatinumMoveDataPath(_ relativePath: String) -> Bool {
        let prefix = "res/battle/moves/"
        let lower = relativePath.lowercased()
        guard lower.hasPrefix(prefix), lower.hasSuffix(".json") else { return false }
        let remainder = lower.dropFirst(prefix.count)
        return !remainder.isEmpty && !remainder.contains("/")
    }

    private static func isSemanticMoveDataPath(_ profile: GameProfile, _ relativePath: String) -> Bool {
        switch profile {
        case .pokeplatinum:
            return isPlatinumMoveDataPath(relativePath)
        case .pokediamond:
            return relativePath == diamondPearlMoveCAnchorPath
        default:
            return false
        }
    }

    private static func isPlatinumItemDataPath(_ relativePath: String) -> Bool {
        relativePath.hasPrefix("res/items/") && relativePath.lowercased().hasSuffix(".json")
    }

    private static func isSemanticItemDataPath(_ profile: GameProfile, _ relativePath: String) -> Bool {
        switch profile {
        case .pokeplatinum:
            return isPlatinumItemDataPath(relativePath)
        case .pokeheartgold:
            return isHeartGoldSoulSilverItemDataPath(relativePath)
        case .pokediamond:
            return isDiamondPearlItemDataPath(relativePath) || relativePath == diamondPearlItemCAnchorPath
        default:
            return false
        }
    }

    private static func isPlatinumEncounterDataPath(_ relativePath: String) -> Bool {
        let prefix = "res/field/encounters/"
        let lower = relativePath.lowercased()
        guard lower.hasPrefix(prefix), lower.hasSuffix(".json") else { return false }
        let remainder = lower.dropFirst(prefix.count)
        return !remainder.isEmpty && !remainder.contains("/")
    }

    private static func isPlatinumEncounterRecord(_ record: NDSDataCatalogRecord) -> Bool {
        record.domain == .encounters
            && record.format == .json
            && isPlatinumEncounterDataPath(record.relativePath)
    }

    private static func isPlatinumEncounterRecordID(_ recordID: String?) -> Bool {
        guard let recordID,
              recordID.hasPrefix("encounters:")
        else {
            return false
        }
        let relativePath = String(recordID.dropFirst("encounters:".count))
        return isPlatinumEncounterDataPath(relativePath)
    }

    private static func isSemanticEncounterDataPath(_ profile: GameProfile, _ relativePath: String) -> Bool {
        switch profile {
        case .pokeplatinum:
            return isPlatinumEncounterDataPath(relativePath)
        case .pokeheartgold:
            return isHeartGoldSoulSilverEncounterDataPath(relativePath)
        case .pokediamond:
            return isDiamondPearlEncounterDataPath(relativePath)
        default:
            return false
        }
    }

    private static func isPlatinumFieldEventDataPath(_ relativePath: String) -> Bool {
        let prefix = "res/field/events/"
        let lower = relativePath.lowercased()
        guard lower.hasPrefix(prefix), lower.hasSuffix(".json") else { return false }
        let remainder = lower.dropFirst(prefix.count)
        return !remainder.isEmpty && !remainder.contains("/")
    }

    private static func isPlatinumMapMatrixDataPath(_ relativePath: String) -> Bool {
        let prefix = "res/field/matrices/"
        let lower = relativePath.lowercased()
        guard lower.hasPrefix(prefix), lower.hasSuffix(".json") else { return false }
        let remainder = lower.dropFirst(prefix.count)
        return !remainder.isEmpty && !remainder.contains("/")
    }

    private static func isPlatinumAreaDataPath(_ relativePath: String) -> Bool {
        let prefix = "res/field/area_data/"
        let lower = relativePath.lowercased()
        guard lower.hasPrefix(prefix), lower.hasSuffix(".json") else { return false }
        let remainder = lower.dropFirst(prefix.count)
        return !remainder.isEmpty && !remainder.contains("/")
    }

    private static func isSemanticMapDataPath(_ profile: GameProfile, _ relativePath: String) -> Bool {
        switch profile {
        case .pokeplatinum:
            return isPlatinumFieldEventDataPath(relativePath)
                || isPlatinumMapMatrixDataPath(relativePath)
                || isPlatinumAreaDataPath(relativePath)
        case .pokeheartgold:
            return relativePath == heartGoldSoulSilverMapHeaderCAnchorPath
        case .pokediamond:
            return isDiamondPearlFieldEventDataPath(relativePath)
                || isDiamondPearlLandDataPath(relativePath)
                || isDiamondPearlAreaDataPath(relativePath)
                || relativePath == diamondPearlMapHeaderCAnchorPath
        default:
            return false
        }
    }

    private static func isDiamondPearlFieldEventDataPath(_ relativePath: String) -> Bool {
        let prefix = "files/fielddata/eventdata/"
        let lower = relativePath.lowercased()
        guard lower.hasPrefix(prefix), lower.hasSuffix(".json") else { return false }
        let remainder = lower.dropFirst(prefix.count)
        return !remainder.isEmpty && !remainder.contains("/")
    }

    private static func isDiamondPearlAreaDataPath(_ relativePath: String) -> Bool {
        let prefix = "files/fielddata/areadata/"
        let lower = relativePath.lowercased()
        guard lower.hasPrefix(prefix), lower.hasSuffix(".json") else { return false }
        let remainder = lower.dropFirst(prefix.count)
        return !remainder.isEmpty && !remainder.contains("/")
    }

    private static func isDiamondPearlLandDataPath(_ relativePath: String) -> Bool {
        let prefix = "files/fielddata/land_data/"
        let lower = relativePath.lowercased()
        guard lower.hasPrefix(prefix), lower.hasSuffix(".json") else { return false }
        let remainder = lower.dropFirst(prefix.count)
        return !remainder.isEmpty && !remainder.contains("/")
    }

    private static func isHeartGoldSoulSilverZoneEventDataPath(_ relativePath: String) -> Bool {
        let prefix = "files/fielddata/eventdata/zone_event/"
        let lower = relativePath.lowercased()
        guard lower.hasPrefix(prefix), lower.hasSuffix(".json") else { return false }
        let remainder = lower.dropFirst(prefix.count)
        return !remainder.isEmpty && !remainder.contains("/")
    }

    private static func isSemanticScriptDataPath(_ profile: GameProfile, _ relativePath: String) -> Bool {
        switch profile {
        case .pokeheartgold:
            return isHeartGoldSoulSilverZoneEventDataPath(relativePath)
        default:
            return false
        }
    }

    private static func isPlatinumSourceTextLineDataPath(_ relativePath: String) -> Bool {
        let prefix = "res/text/"
        let lower = relativePath.lowercased()
        guard lower.hasPrefix(prefix), lower.hasSuffix(".txt") else { return false }
        return !lower.dropFirst(prefix.count).isEmpty
    }

    private static func isPlatinumSourceTextLineRecord(_ record: NDSDataCatalogRecord) -> Bool {
        record.domain == .text
            && record.role == .sourceTree
            && record.format == .text
            && isPlatinumSourceTextLineDataPath(record.relativePath)
    }

    private static func isPlatinumSourceTextJSONDataPath(_ relativePath: String) -> Bool {
        let prefix = "res/text/"
        let lower = relativePath.lowercased()
        guard lower.hasPrefix(prefix), lower.hasSuffix(".json") else { return false }
        return !lower.dropFirst(prefix.count).isEmpty
    }

    private static func isPlatinumSourceTextJSONRecord(_ record: NDSDataCatalogRecord) -> Bool {
        record.domain == .text
            && record.role == .sourceTree
            && record.format == .json
            && isPlatinumSourceTextJSONDataPath(record.relativePath)
    }

    private static func isSemanticTextDataPath(_ profile: GameProfile, _ record: NDSDataCatalogRecord) -> Bool {
        switch profile {
        case .pokeplatinum:
            return isPlatinumSourceTextLineRecord(record) || isPlatinumSourceTextJSONRecord(record)
        default:
            return false
        }
    }

    private static func isSemanticProfileSupported(_ profile: GameProfile, record: NDSDataCatalogRecord) -> Bool {
        switch profile {
        case .pokeplatinum:
            return true
        case .pokeheartgold:
            return isHeartGoldSoulSilverSemanticDataPath(record)
        case .pokediamond:
            return isDiamondPearlSemanticDataPath(record)
        default:
            return false
        }
    }

    private static func isDiamondPearlSemanticDataPath(_ record: NDSDataCatalogRecord) -> Bool {
        switch record.domain {
        case .personal:
            return isDiamondPearlPersonalDataPath(record.relativePath) && record.format == .json
        case .trainers:
            return (isDiamondPearlTrainerDataPath(record.relativePath) && record.format == .json)
                || isDiamondPearlTrainerClassGenderCAnchorRecord(record)
        case .moves:
            return isDiamondPearlMoveCAnchorRecord(record)
        case .items:
            return (isDiamondPearlItemDataPath(record.relativePath) && record.format == .json)
                || isDiamondPearlItemCAnchorRecord(record)
        case .encounters:
            return isDiamondPearlEncounterDataPath(record.relativePath) && record.format == .json
        case .maps:
            return (isDiamondPearlFieldEventDataPath(record.relativePath) && record.format == .json)
                || (isDiamondPearlLandDataPath(record.relativePath) && record.format == .json)
                || (isDiamondPearlAreaDataPath(record.relativePath) && record.format == .json)
                || isDiamondPearlMapHeaderCAnchorRecord(record)
        default:
            return false
        }
    }

    private static func isDiamondPearlMoveCAnchorRecord(_ record: NDSDataCatalogRecord) -> Bool {
        record.domain == .moves
            && record.relativePath == diamondPearlMoveCAnchorPath
            && record.format == .cSource
    }

    private static func isDiamondPearlItemCAnchorRecord(_ record: NDSDataCatalogRecord) -> Bool {
        record.domain == .items
            && record.relativePath == diamondPearlItemCAnchorPath
            && record.format == .cSource
    }

    private static func isDiamondPearlTrainerClassGenderCAnchorRecord(_ record: NDSDataCatalogRecord) -> Bool {
        record.domain == .trainers
            && record.relativePath == diamondPearlTrainerCAnchorPath
            && record.format == .cSource
    }

    private static func isDiamondPearlMapHeaderCAnchorRecord(_ record: NDSDataCatalogRecord) -> Bool {
        record.domain == .maps
            && record.relativePath == diamondPearlMapHeaderCAnchorPath
            && record.format == .cSource
    }

    private static func isHeartGoldSoulSilverMapHeaderCAnchorRecord(_ record: NDSDataCatalogRecord) -> Bool {
        record.domain == .maps
            && record.relativePath == heartGoldSoulSilverMapHeaderCAnchorPath
            && record.format == .cHeader
    }

    private static func isSemanticFormatSupported(_ profile: GameProfile, _ record: NDSDataCatalogRecord) -> Bool {
        if record.format == .json {
            return true
        }
        if profile == .pokeheartgold, isHeartGoldSoulSilverItemCSVRecord(record) {
            return true
        }
        if profile == .pokeheartgold, isHeartGoldSoulSilverMapHeaderCAnchorRecord(record) {
            return true
        }
        if profile == .pokeplatinum, isPlatinumSourceTextLineRecord(record) {
            return true
        }
        return profile == .pokediamond && isDiamondPearlSemanticDataPath(record)
    }

    private static func isHeartGoldSoulSilverSemanticDataPath(_ record: NDSDataCatalogRecord) -> Bool {
        switch record.domain {
        case .personal:
            return isHeartGoldSoulSilverPersonalDataPath(record.relativePath)
        case .items:
            return isHeartGoldSoulSilverItemDataPath(record.relativePath)
        case .trainers:
            return isHeartGoldSoulSilverTrainerDataPath(record.relativePath)
        case .encounters:
            return isHeartGoldSoulSilverEncounterDataPath(record.relativePath)
        case .scripts:
            return isHeartGoldSoulSilverZoneEventDataPath(record.relativePath)
        case .maps:
            return isHeartGoldSoulSilverMapHeaderCAnchorRecord(record)
        default:
            return false
        }
    }

    private static func isHeartGoldSoulSilverPersonalDataPath(_ relativePath: String) -> Bool {
        relativePath.hasPrefix("files/poketool/personal/") && relativePath.lowercased().hasSuffix(".json")
    }

    private static func isDiamondPearlPersonalDataPath(_ relativePath: String) -> Bool {
        let lower = relativePath.lowercased()
        return (lower.hasPrefix("files/poketool/personal/") || lower.hasPrefix("files/poketool/personal_pearl/"))
            && lower.hasSuffix(".json")
    }

    private static func isDiamondPearlTrainerDataPath(_ relativePath: String) -> Bool {
        let lower = relativePath.lowercased()
        return lower.hasPrefix("files/poketool/trainer/")
            && lower.hasSuffix(".json")
    }

    private static func isDiamondPearlItemDataPath(_ relativePath: String) -> Bool {
        let lower = relativePath.lowercased()
        return lower.hasPrefix("files/itemtool/itemdata/")
            && lower.hasSuffix(".json")
    }

    private static func isDiamondPearlEncounterDataPath(_ relativePath: String) -> Bool {
        let lower = relativePath.lowercased()
        return lower.hasPrefix("files/fielddata/encountdata/")
            && lower.hasSuffix(".json")
    }

    private static func isDiamondPearlEncounterRecord(_ record: NDSDataCatalogRecord, profile: GameProfile?) -> Bool {
        profile == .pokediamond
            && record.domain == .encounters
            && record.format == .json
            && isDiamondPearlEncounterDataPath(record.relativePath)
    }

    private static func isHeartGoldSoulSilverTrainerDataPath(_ relativePath: String) -> Bool {
        relativePath.hasPrefix("files/poketool/trainer/") && relativePath.lowercased().hasSuffix(".json")
    }

    private static func isHeartGoldSoulSilverItemDataPath(_ relativePath: String) -> Bool {
        isHeartGoldSoulSilverItemJSONDataPath(relativePath) || isHeartGoldSoulSilverItemCSVDataPath(relativePath)
    }

    private static func isHeartGoldSoulSilverItemJSONDataPath(_ relativePath: String) -> Bool {
        relativePath.hasPrefix("files/itemtool/itemdata/") && relativePath.lowercased().hasSuffix(".json")
    }

    private static func isHeartGoldSoulSilverItemCSVDataPath(_ relativePath: String) -> Bool {
        let prefix = "files/itemtool/itemdata/"
        let lower = relativePath.lowercased()
        guard lower.hasPrefix(prefix), lower.hasSuffix(".csv") else { return false }
        let remainder = lower.dropFirst(prefix.count)
        return !remainder.isEmpty && !remainder.contains("/")
    }

    private static func isHeartGoldSoulSilverItemCSVRecord(_ record: NDSDataCatalogRecord) -> Bool {
        record.domain == .items
            && record.format == .csv
            && isHeartGoldSoulSilverItemCSVDataPath(record.relativePath)
    }

    private static func isHeartGoldSoulSilverEncounterDataPath(_ relativePath: String) -> Bool {
        relativePath.hasPrefix("files/fielddata/encountdata/") && relativePath.lowercased().hasSuffix(".json")
    }

    private static func isHeartGoldSoulSilverEncounterRecord(_ record: NDSDataCatalogRecord, profile: GameProfile?) -> Bool {
        profile == .pokeheartgold
            && record.domain == .encounters
            && record.format == .json
            && isHeartGoldSoulSilverEncounterDataPath(record.relativePath)
    }

    private struct ParsedSemanticField {
        let semanticField: NDSDataSemanticField
        let valueRange: Range<String.Index>
        let syntax: SemanticFieldSyntax

        init(semanticField: NDSDataSemanticField, valueRange: Range<String.Index>, syntax: SemanticFieldSyntax = .json) {
            self.semanticField = semanticField
            self.valueRange = valueRange
            self.syntax = syntax
        }
    }

    private struct ParsedSemanticFields {
        let fields: [ParsedSemanticField]
        let diagnostics: [Diagnostic]
        let unsupportedNestedKeys: Set<String>
    }

    private struct ParsedCSVCell {
        let value: String
        let valueRange: Range<String.Index>
    }

    private static func parseSemanticFields(
        sourceText: String,
        record: NDSDataCatalogRecord?,
        recordID: String? = nil,
        profile: GameProfile? = nil
    ) -> ParsedSemanticFields {
        if let record, isDiamondPearlMoveCAnchorRecord(record) {
            return parseDiamondPearlMoveCAnchorFields(sourceText: sourceText, record: record)
        }
        if record == nil, recordID == "moves:\(diamondPearlMoveCAnchorPath)" {
            return parseDiamondPearlMoveCAnchorFields(sourceText: sourceText, record: nil)
        }
        if let record, isDiamondPearlItemCAnchorRecord(record) {
            return parseDiamondPearlItemCAnchorFields(sourceText: sourceText, record: record)
        }
        if record == nil, recordID == "items:\(diamondPearlItemCAnchorPath)" {
            return parseDiamondPearlItemCAnchorFields(sourceText: sourceText, record: nil)
        }
        if let record, isDiamondPearlTrainerClassGenderCAnchorRecord(record) {
            return parseDiamondPearlTrainerClassGenderFields(sourceText: sourceText, record: record)
        }
        if record == nil, recordID == "trainers:\(diamondPearlTrainerCAnchorPath)" {
            return parseDiamondPearlTrainerClassGenderFields(sourceText: sourceText, record: nil)
        }
        if let record, isDiamondPearlMapHeaderCAnchorRecord(record) {
            return parseDiamondPearlMapHeaderFields(sourceText: sourceText, record: record)
        }
        if record == nil, recordID == "maps:\(diamondPearlMapHeaderCAnchorPath)" {
            return parseDiamondPearlMapHeaderFields(sourceText: sourceText, record: nil)
        }
        if let record, isHeartGoldSoulSilverMapHeaderCAnchorRecord(record) {
            return parseHeartGoldSoulSilverMapHeaderFields(sourceText: sourceText, record: record)
        }
        if record == nil, recordID == "maps:\(heartGoldSoulSilverMapHeaderCAnchorPath)" {
            return parseHeartGoldSoulSilverMapHeaderFields(sourceText: sourceText, record: nil)
        }
        if let record, isHeartGoldSoulSilverItemCSVRecord(record) {
            return parseHeartGoldSoulSilverItemCSVFields(sourceText: sourceText, record: record)
        }
        if let record, isPlatinumEncounterRecord(record) {
            return parseEncounterSlotJSONFields(sourceText: sourceText, record: record, gameLabel: "Platinum")
        }
        if record == nil, isPlatinumEncounterRecordID(recordID) {
            return parseEncounterSlotJSONFields(sourceText: sourceText, record: nil, gameLabel: "Platinum")
        }
        if let record, isHeartGoldSoulSilverEncounterRecord(record, profile: profile) {
            return parseEncounterSlotJSONFields(sourceText: sourceText, record: record, gameLabel: "HeartGold/SoulSilver")
        }
        if let record, isDiamondPearlEncounterRecord(record, profile: profile) {
            return parseEncounterSlotJSONFields(sourceText: sourceText, record: record, gameLabel: "Diamond/Pearl")
        }
        if let record, isPlatinumSourceTextLineRecord(record) {
            return parsePlatinumSourceTextLineFields(sourceText: sourceText, record: record)
        }
        if let record, isPlatinumSourceTextJSONRecord(record) {
            return parsePlatinumTextJSONStringLeafFields(sourceText: sourceText, record: record)
        }
        return parseTopLevelScalarJSONFields(sourceText: sourceText, record: record)
    }

    private static func parsePlatinumSourceTextLineFields(
        sourceText: String,
        record: NDSDataCatalogRecord
    ) -> ParsedSemanticFields {
        var fields: [ParsedSemanticField] = []
        for (lineIndex, lineRange) in csvLineRanges(sourceText).enumerated() {
            fields.append(
                ParsedSemanticField(
                    semanticField: NDSDataSemanticField(
                        key: "lines.\(lineIndex).text",
                        label: "Line \(lineIndex + 1)",
                        value: String(sourceText[lineRange]),
                        valueKind: .string,
                        sourceSpan: SourceSpan(relativePath: record.relativePath, startLine: lineNumber(in: sourceText, before: lineRange.lowerBound))
                    ),
                    valueRange: lineRange,
                    syntax: .textLine
                )
            )
        }

        var diagnostics: [Diagnostic] = []
        if fields.isEmpty {
            diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_NO_TEXT_LINES", message: "No existing text lines were found for Platinum source text semantic editing.", span: record.sourceSpan))
        }
        return ParsedSemanticFields(fields: fields, diagnostics: diagnostics, unsupportedNestedKeys: [])
    }

    private static func parsePlatinumTextJSONStringLeafFields(
        sourceText: String,
        record: NDSDataCatalogRecord
    ) -> ParsedSemanticFields {
        var diagnostics: [Diagnostic] = []
        guard let data = sourceText.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) != nil
        else {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_JSON_MALFORMED", message: "Platinum text JSON semantic editing requires parseable JSON before string leaves are planned.", span: record.sourceSpan))
            return ParsedSemanticFields(fields: [], diagnostics: diagnostics, unsupportedNestedKeys: [])
        }

        var fields: [ParsedSemanticField] = []
        var index = sourceText.startIndex
        parseTextJSONStringLeaves(
            sourceText,
            index: &index,
            pathComponents: [],
            record: record,
            fields: &fields,
            diagnostics: &diagnostics
        )

        let duplicateKeys = duplicateSemanticFieldKeys(fields)
        for key in duplicateKeys {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_SEMANTIC_JSON_KEY_DUPLICATE",
                    message: "Platinum text JSON string leaf \(key) appears more than once; ambiguous source keys must be resolved before field-level edits are planned.",
                    span: record.sourceSpan
                )
            )
        }

        if fields.isEmpty, diagnostics.allSatisfy({ $0.severity != .error }) {
            diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_NO_TEXT_JSON_STRINGS", message: "No existing string leaves were found for Platinum text JSON semantic editing.", span: record.sourceSpan))
        }
        return ParsedSemanticFields(fields: fields, diagnostics: diagnostics, unsupportedNestedKeys: [])
    }

    private static func parseTextJSONStringLeaves(
        _ text: String,
        index: inout String.Index,
        pathComponents: [String],
        record: NDSDataCatalogRecord,
        fields: inout [ParsedSemanticField],
        diagnostics: inout [Diagnostic]
    ) {
        skipWhitespace(text, index: &index)
        guard index < text.endIndex else { return }
        switch text[index] {
        case "{":
            parseTextJSONObjectStringLeaves(text, index: &index, pathComponents: pathComponents, record: record, fields: &fields, diagnostics: &diagnostics)
        case "[":
            parseTextJSONArrayStringLeaves(text, index: &index, pathComponents: pathComponents, record: record, fields: &fields, diagnostics: &diagnostics)
        case "\"":
            let valueStart = index
            guard let token = parseJSONStringToken(text, start: index) else {
                skipJSONValueOrToken(text, index: &index)
                return
            }
            let key = pathComponents.isEmpty ? "value" : pathComponents.joined(separator: ".")
            fields.append(
                ParsedSemanticField(
                    semanticField: NDSDataSemanticField(
                        key: key,
                        label: semanticTextJSONLabel(for: pathComponents),
                        value: token.value,
                        valueKind: .string,
                        sourceSpan: SourceSpan(relativePath: record.relativePath, startLine: lineNumber(in: text, before: valueStart))
                    ),
                    valueRange: valueStart..<token.end,
                    syntax: .textJSONString
                )
            )
            index = token.end
        default:
            skipJSONValueOrToken(text, index: &index)
        }
    }

    private static func parseTextJSONObjectStringLeaves(
        _ text: String,
        index: inout String.Index,
        pathComponents: [String],
        record: NDSDataCatalogRecord,
        fields: inout [ParsedSemanticField],
        diagnostics: inout [Diagnostic]
    ) {
        guard index < text.endIndex, text[index] == "{" else { return }
        index = text.index(after: index)
        var seenKeys = Set<String>()
        var duplicateKeys = Set<String>()
        while index < text.endIndex {
            skipWhitespaceAndCommas(text, index: &index)
            guard index < text.endIndex else { return }
            if text[index] == "}" {
                index = text.index(after: index)
                break
            }
            guard text[index] == "\"", let keyToken = parseJSONStringToken(text, start: index) else {
                skipJSONValueOrToken(text, index: &index)
                continue
            }
            index = keyToken.end
            if !seenKeys.insert(keyToken.value).inserted {
                duplicateKeys.insert((pathComponents + [keyToken.value]).joined(separator: "."))
            }
            skipWhitespace(text, index: &index)
            guard index < text.endIndex, text[index] == ":" else { continue }
            index = text.index(after: index)
            parseTextJSONStringLeaves(
                text,
                index: &index,
                pathComponents: pathComponents + [keyToken.value],
                record: record,
                fields: &fields,
                diagnostics: &diagnostics
            )
        }
        for key in duplicateKeys.sorted() {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_SEMANTIC_JSON_KEY_DUPLICATE",
                    message: "Platinum text JSON object key \(key) appears more than once; duplicate source keys must be resolved before field-level edits are planned.",
                    span: record.sourceSpan
                )
            )
        }
    }

    private static func parseTextJSONArrayStringLeaves(
        _ text: String,
        index: inout String.Index,
        pathComponents: [String],
        record: NDSDataCatalogRecord,
        fields: inout [ParsedSemanticField],
        diagnostics: inout [Diagnostic]
    ) {
        guard index < text.endIndex, text[index] == "[" else { return }
        index = text.index(after: index)
        var elementIndex = 0
        while index < text.endIndex {
            skipWhitespace(text, index: &index)
            guard index < text.endIndex else { return }
            if text[index] == "]" {
                index = text.index(after: index)
                break
            }
            parseTextJSONStringLeaves(
                text,
                index: &index,
                pathComponents: pathComponents + ["\(elementIndex)"],
                record: record,
                fields: &fields,
                diagnostics: &diagnostics
            )
            skipWhitespace(text, index: &index)
            if index < text.endIndex, text[index] == "," {
                index = text.index(after: index)
                elementIndex += 1
            }
        }
    }

    private static func duplicateSemanticFieldKeys(_ fields: [ParsedSemanticField]) -> [String] {
        var seen = Set<String>()
        var duplicates = Set<String>()
        for field in fields {
            if !seen.insert(field.semanticField.key).inserted {
                duplicates.insert(field.semanticField.key)
            }
        }
        return duplicates.sorted()
    }

    private static func parseHeartGoldSoulSilverItemCSVFields(
        sourceText: String,
        record: NDSDataCatalogRecord
    ) -> ParsedSemanticFields {
        var diagnostics: [Diagnostic] = []
        var lineRanges = csvLineRanges(sourceText)
        while let last = lineRanges.last, String(sourceText[last]).isEmpty {
            lineRanges.removeLast()
        }
        guard let headerRange = lineRanges.first else {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_CSV_HEADER_REQUIRED", message: "HeartGold/SoulSilver item CSV semantic editing requires a nonempty header row.", span: record.sourceSpan))
            return ParsedSemanticFields(fields: [], diagnostics: diagnostics, unsupportedNestedKeys: [])
        }

        let header = parseCSVRow(sourceText, lineRange: headerRange, record: record, rowDescription: "header")
        diagnostics.append(contentsOf: header.diagnostics)
        var headers: [String] = []
        var seenHeaders = Set<String>()
        var duplicateHeaders = Set<String>()
        for cell in header.cells {
            let name = cell.value.trimmingCharacters(in: .whitespacesAndNewlines)
            if name.isEmpty {
                diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_CSV_HEADER_EMPTY", message: "HeartGold/SoulSilver item CSV semantic editing requires nonempty header names.", span: SourceSpan(relativePath: record.relativePath, startLine: lineNumber(in: sourceText, before: cell.valueRange.lowerBound))))
            } else if !seenHeaders.insert(name).inserted {
                duplicateHeaders.insert(name)
            }
            headers.append(name)
        }
        for headerName in duplicateHeaders.sorted() {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_CSV_HEADER_DUPLICATE", message: "HeartGold/SoulSilver item CSV header \(headerName) appears more than once; duplicate headers must be resolved before field-level edits are planned.", span: record.sourceSpan))
        }
        guard diagnostics.allSatisfy({ $0.severity != .error }) else {
            return ParsedSemanticFields(fields: [], diagnostics: diagnostics, unsupportedNestedKeys: [])
        }
        guard !headers.isEmpty else {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_CSV_HEADER_REQUIRED", message: "HeartGold/SoulSilver item CSV semantic editing requires at least one header column.", span: record.sourceSpan))
            return ParsedSemanticFields(fields: [], diagnostics: diagnostics, unsupportedNestedKeys: [])
        }
        guard lineRanges.count > 1 else {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_CSV_ROW_REQUIRED", message: "HeartGold/SoulSilver item CSV semantic editing requires at least one existing data row.", span: record.sourceSpan))
            return ParsedSemanticFields(fields: [], diagnostics: diagnostics, unsupportedNestedKeys: [])
        }

        var fields: [ParsedSemanticField] = []
        for (dataRowIndex, lineRange) in lineRanges.dropFirst().enumerated() {
            let row = parseCSVRow(sourceText, lineRange: lineRange, record: record, rowDescription: "row \(dataRowIndex + 1)")
            diagnostics.append(contentsOf: row.diagnostics)
            guard row.cells.count == headers.count else {
                diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_CSV_ROW_BAD_SHAPE", message: "HeartGold/SoulSilver item CSV row \(dataRowIndex + 1) has \(row.cells.count) cell(s), but the header has \(headers.count); this row remains raw-source only.", span: SourceSpan(relativePath: record.relativePath, startLine: lineNumber(in: sourceText, before: lineRange.lowerBound))))
                continue
            }
            for (columnIndex, cell) in row.cells.enumerated() {
                let headerName = headers[columnIndex]
                fields.append(
                    ParsedSemanticField(
                        semanticField: NDSDataSemanticField(
                            key: "rows.\(dataRowIndex).\(headerName)",
                            label: "Row \(dataRowIndex + 1) \(semanticLabel(for: headerName))",
                            value: cell.value,
                            valueKind: .string,
                            sourceSpan: SourceSpan(relativePath: record.relativePath, startLine: lineNumber(in: sourceText, before: cell.valueRange.lowerBound))
                        ),
                        valueRange: cell.valueRange,
                        syntax: .csvCell
                    )
                )
            }
        }

        if fields.isEmpty, diagnostics.allSatisfy({ $0.severity != .error }) {
            diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_NO_CSV_CELLS", message: "No editable CSV cells were found for HeartGold/SoulSilver item semantic editing.", span: record.sourceSpan))
        }
        return ParsedSemanticFields(fields: fields, diagnostics: diagnostics, unsupportedNestedKeys: [])
    }

    private static func csvLineRanges(_ text: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var lineStart = text.startIndex
        var index = text.startIndex
        while index < text.endIndex {
            if text[index] == "\n" {
                var lineEnd = index
                if lineStart < lineEnd {
                    let beforeEnd = text.index(before: lineEnd)
                    if text[beforeEnd] == "\r" {
                        lineEnd = beforeEnd
                    }
                }
                ranges.append(lineStart..<lineEnd)
                lineStart = text.index(after: index)
            }
            index = text.index(after: index)
        }
        if lineStart < text.endIndex {
            var lineEnd = text.endIndex
            let beforeEnd = text.index(before: lineEnd)
            if text[beforeEnd] == "\r" {
                lineEnd = beforeEnd
            }
            ranges.append(lineStart..<lineEnd)
        }
        return ranges
    }

    private static func parseCSVRow(
        _ text: String,
        lineRange: Range<String.Index>,
        record: NDSDataCatalogRecord,
        rowDescription: String
    ) -> (cells: [ParsedCSVCell], diagnostics: [Diagnostic]) {
        var cells: [ParsedCSVCell] = []
        var diagnostics: [Diagnostic] = []
        var index = lineRange.lowerBound
        while true {
            let cellStart = index
            if index < lineRange.upperBound, text[index] == "\"" {
                let quoted = parseQuotedCSVCell(text, start: index, end: lineRange.upperBound, record: record, rowDescription: rowDescription)
                diagnostics.append(contentsOf: quoted.diagnostics)
                if let cell = quoted.cell {
                    cells.append(cell)
                }
                index = quoted.end
            } else {
                var cellEnd = index
                while cellEnd < lineRange.upperBound, text[cellEnd] != "," {
                    cellEnd = text.index(after: cellEnd)
                }
                cells.append(ParsedCSVCell(value: String(text[cellStart..<cellEnd]), valueRange: cellStart..<cellEnd))
                index = cellEnd
            }

            if index < lineRange.upperBound, text[index] == "," {
                index = text.index(after: index)
                continue
            }
            break
        }
        return (cells, diagnostics)
    }

    private static func parseQuotedCSVCell(
        _ text: String,
        start: String.Index,
        end: String.Index,
        record: NDSDataCatalogRecord,
        rowDescription: String
    ) -> (cell: ParsedCSVCell?, end: String.Index, diagnostics: [Diagnostic]) {
        var diagnostics: [Diagnostic] = []
        var value = ""
        var index = text.index(after: start)
        while index < end {
            if text[index] == "\"" {
                let next = text.index(after: index)
                if next < end, text[next] == "\"" {
                    value.append("\"")
                    index = text.index(after: next)
                    continue
                }

                var cellEnd = next
                while cellEnd < end, text[cellEnd] != "," {
                    if !text[cellEnd].isWhitespace {
                        diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_CSV_QUOTED_TRAILING_TEXT", message: "HeartGold/SoulSilver item CSV \(rowDescription) has non-whitespace text after a quoted cell; this row remains raw-source only.", span: SourceSpan(relativePath: record.relativePath, startLine: lineNumber(in: text, before: cellEnd))))
                    }
                    cellEnd = text.index(after: cellEnd)
                }
                return (ParsedCSVCell(value: value, valueRange: start..<cellEnd), cellEnd, diagnostics)
            }
            value.append(text[index])
            index = text.index(after: index)
        }

        diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_CSV_QUOTE_UNCLOSED", message: "HeartGold/SoulSilver item CSV \(rowDescription) has an unterminated quoted cell; multiline CSV cells remain raw-source only.", span: SourceSpan(relativePath: record.relativePath, startLine: lineNumber(in: text, before: start))))
        return (nil, end, diagnostics)
    }

    private static func parseDiamondPearlMoveCAnchorFields(
        sourceText: String,
        record: NDSDataCatalogRecord?
    ) -> ParsedSemanticFields {
        var diagnostics: [Diagnostic] = []
        guard let tableRange = cExactStaticConstStructTableBraceRange(
            sourceText,
            structName: "WazaTbl",
            symbol: diamondPearlMoveTableSymbol
        ) else {
            diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_C_TABLE_MISSING", message: "Diamond/Pearl move table static const struct WazaTbl \(diamondPearlMoveTableSymbol)[] was not found; move C anchors remain raw-source only.", span: record?.sourceSpan))
            return ParsedSemanticFields(fields: [], diagnostics: diagnostics, unsupportedNestedKeys: [])
        }

        var fields: [ParsedSemanticField] = []
        var cursor = sourceText.index(after: tableRange.openBrace)
        let tableClose = sourceText.index(before: tableRange.closeBraceEnd)
        while cursor < tableClose {
            skipCWhitespaceCommentsAndCommas(sourceText, index: &cursor, end: tableClose)
            guard cursor < tableClose else { break }
            let rowStart = cursor
            guard sourceText[cursor] == "[",
                  let bracketEnd = matchingBracketEnd(sourceText, start: cursor),
                  bracketEnd <= tableClose,
                  let moveKeyRange = trimmedRange(sourceText.index(after: cursor)..<sourceText.index(before: bracketEnd), in: sourceText)
            else {
                diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_C_ROW_BAD_SHAPE", message: "Diamond/Pearl move table row is not a direct designated \(diamondPearlMoveTableSymbol) entry and remains raw-source only.", span: SourceSpan(relativePath: record?.relativePath ?? diamondPearlMoveCAnchorPath, startLine: lineNumber(in: sourceText, before: rowStart))))
                skipCInitializerEntry(sourceText, cursor: &cursor, end: tableClose)
                continue
            }

            let moveKey = String(sourceText[moveKeyRange])
            guard isCIdentifier(moveKey) else {
                diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_C_ROW_BAD_SHAPE", message: "Diamond/Pearl move table row \(moveKey) does not use a simple move constant and remains raw-source only.", span: SourceSpan(relativePath: record?.relativePath ?? diamondPearlMoveCAnchorPath, startLine: lineNumber(in: sourceText, before: moveKeyRange.lowerBound))))
                cursor = bracketEnd
                skipCInitializerEntry(sourceText, cursor: &cursor, end: tableClose)
                continue
            }

            cursor = bracketEnd
            skipCWhitespaceCommentsAndCommas(sourceText, index: &cursor, end: tableClose)
            guard cursor < tableClose, sourceText[cursor] == "=" else {
                diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_C_ROW_BAD_SHAPE", message: "Diamond/Pearl move table row \(moveKey) is not a direct designated initializer and remains raw-source only.", span: SourceSpan(relativePath: record?.relativePath ?? diamondPearlMoveCAnchorPath, startLine: lineNumber(in: sourceText, before: moveKeyRange.lowerBound))))
                skipCInitializerEntry(sourceText, cursor: &cursor, end: tableClose)
                continue
            }
            cursor = sourceText.index(after: cursor)
            skipCWhitespaceCommentsAndCommas(sourceText, index: &cursor, end: tableClose)
            guard cursor < tableClose, sourceText[cursor] == "{",
                  let entryEnd = matchingCBraceEnd(sourceText, start: cursor),
                  entryEnd <= tableRange.closeBraceEnd
            else {
                diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_C_ROW_BAD_SHAPE", message: "Diamond/Pearl move table row \(moveKey) is not a direct brace initializer and remains raw-source only.", span: SourceSpan(relativePath: record?.relativePath ?? diamondPearlMoveCAnchorPath, startLine: lineNumber(in: sourceText, before: moveKeyRange.lowerBound))))
                if cursor < tableClose {
                    cursor = sourceText.index(after: cursor)
                }
                continue
            }

            parseDiamondPearlMoveEntryFields(
                sourceText: sourceText,
                moveKey: moveKey,
                start: sourceText.index(after: cursor),
                end: sourceText.index(before: entryEnd),
                record: record,
                fields: &fields,
                diagnostics: &diagnostics
            )
            cursor = entryEnd
        }

        let duplicateKeys = duplicateSemanticFieldKeys(fields)
        for key in duplicateKeys {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_C_FIELD_DUPLICATE", message: "Diamond/Pearl move scalar \(key) appears more than once; duplicate source fields must be resolved before field-level edits are planned.", span: record?.sourceSpan))
        }
        if fields.isEmpty, diagnostics.allSatisfy({ $0.severity != .error }) {
            diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_NO_C_SCALARS", message: "No simple scalar fields were found in Diamond/Pearl \(diamondPearlMoveTableSymbol); move C anchors remain raw-source only.", span: record?.sourceSpan))
        }
        return ParsedSemanticFields(fields: fields, diagnostics: diagnostics, unsupportedNestedKeys: [])
    }

    private static func parseDiamondPearlMoveEntryFields(
        sourceText: String,
        moveKey: String,
        start: String.Index,
        end: String.Index,
        record: NDSDataCatalogRecord?,
        fields: inout [ParsedSemanticField],
        diagnostics: inout [Diagnostic]
    ) {
        var cursor = start
        while cursor < end {
            skipCWhitespaceCommentsAndCommas(sourceText, index: &cursor, end: end)
            guard cursor < end else { break }
            guard sourceText[cursor] == "." else {
                diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_C_FIELD_BAD_SHAPE", message: "Diamond/Pearl move table row \(moveKey) contains a non-designated field and remains raw-source only for that field.", span: SourceSpan(relativePath: record?.relativePath ?? diamondPearlMoveCAnchorPath, startLine: lineNumber(in: sourceText, before: cursor))))
                let valueEnd = cTopLevelValueEnd(sourceText, start: cursor, end: end)
                cursor = valueEnd
                if cursor < end, sourceText[cursor] == "," {
                    cursor = sourceText.index(after: cursor)
                }
                continue
            }

            let fieldStart = sourceText.index(after: cursor)
            guard fieldStart < end, isCIdentifierStart(sourceText[fieldStart]) else {
                cursor = fieldStart
                continue
            }
            var fieldEnd = sourceText.index(after: fieldStart)
            while fieldEnd < end, isCIdentifierContinuation(sourceText[fieldEnd]) {
                fieldEnd = sourceText.index(after: fieldEnd)
            }
            let fieldName = String(sourceText[fieldStart..<fieldEnd])
            cursor = fieldEnd
            skipCWhitespaceCommentsAndCommas(sourceText, index: &cursor, end: end)
            guard cursor < end, sourceText[cursor] == "=" else {
                diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_C_FIELD_BAD_SHAPE", message: "Diamond/Pearl move table field \(moveKey).\(fieldName) is not a direct assignment and remains raw-source only.", span: SourceSpan(relativePath: record?.relativePath ?? diamondPearlMoveCAnchorPath, startLine: lineNumber(in: sourceText, before: fieldStart))))
                if cursor < end {
                    cursor = sourceText.index(after: cursor)
                }
                continue
            }
            cursor = sourceText.index(after: cursor)
            skipCWhitespaceCommentsAndCommas(sourceText, index: &cursor, end: end)

            let valueStart = cursor
            let valueEnd = cTopLevelValueEnd(sourceText, start: valueStart, end: end)
            defer {
                cursor = valueEnd
                if cursor < end, sourceText[cursor] == "," {
                    cursor = sourceText.index(after: cursor)
                }
            }

            guard fieldName != "padding",
                  let moveField = DiamondPearlMoveField(rawValue: fieldName),
                  let scalarRange = trimmedRange(valueStart..<valueEnd, in: sourceText)
            else {
                continue
            }

            let trimmed = String(sourceText[scalarRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard isCSimpleScalar(trimmed) else {
                diagnostics.append(Diagnostic(severity: .info, code: "NDS_DATA_SEMANTIC_C_SCALAR_UNSUPPORTED", message: "Diamond/Pearl move table field \(moveKey).\(fieldName) is not a simple C integer literal or identifier and remains raw-source only.", span: SourceSpan(relativePath: record?.relativePath ?? diamondPearlMoveCAnchorPath, startLine: lineNumber(in: sourceText, before: scalarRange.lowerBound))))
                continue
            }
            fields.append(
                ParsedSemanticField(
                    semanticField: NDSDataSemanticField(
                        key: "waza.\(moveKey).\(moveField.key)",
                        label: "\(moveKey) \(moveField.label)",
                        value: trimmed,
                        valueKind: isCIntegerLiteral(trimmed) ? .number : .string,
                        sourceSpan: SourceSpan(relativePath: record?.relativePath ?? diamondPearlMoveCAnchorPath, startLine: lineNumber(in: sourceText, before: scalarRange.lowerBound))
                    ),
                    valueRange: scalarRange,
                    syntax: .cSimpleScalar
                )
            )
        }
    }

    private static func parseDiamondPearlItemCAnchorFields(
        sourceText: String,
        record: NDSDataCatalogRecord?
    ) -> ParsedSemanticFields {
        var diagnostics: [Diagnostic] = []
        guard let tableRange = cInitializerTableBraceRange(sourceText, symbol: diamondPearlItemMappingTableSymbol)
        else {
            diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_C_TABLE_MISSING", message: "Diamond/Pearl item mapping table \(diamondPearlItemMappingTableSymbol) was not found; item C anchors remain raw-source only.", span: record?.sourceSpan))
            return ParsedSemanticFields(fields: [], diagnostics: diagnostics, unsupportedNestedKeys: [])
        }

        var fields: [ParsedSemanticField] = []
        var rowIndex = 0
        var cursor = sourceText.index(after: tableRange.openBrace)
        let tableClose = sourceText.index(before: tableRange.closeBraceEnd)
        while cursor < tableClose {
            skipCWhitespaceCommentsAndCommas(sourceText, index: &cursor, end: tableClose)
            guard cursor < tableClose else { break }
            guard sourceText[cursor] == "{",
                  let entryEnd = matchingCBraceEnd(sourceText, start: cursor),
                  entryEnd <= tableRange.closeBraceEnd
            else {
                cursor = sourceText.index(after: cursor)
                continue
            }

            let entryClose = sourceText.index(before: entryEnd)
            let scalars = cTopLevelScalars(in: sourceText, start: sourceText.index(after: cursor), end: entryClose)
            guard scalars.count == DiamondPearlItemMappingField.allCases.count else {
                diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_C_ROW_BAD_SHAPE", message: "Diamond/Pearl item mapping row \(rowIndex) is not a four-scalar row and remains raw-source only.", span: SourceSpan(relativePath: record?.relativePath ?? diamondPearlItemCAnchorPath, startLine: lineNumber(in: sourceText, before: cursor))))
                rowIndex += 1
                cursor = entryEnd
                continue
            }
            for (offset, scalarRange) in scalars.prefix(DiamondPearlItemMappingField.allCases.count).enumerated() {
                guard let mappingField = DiamondPearlItemMappingField(rawValue: offset) else { continue }
                let trimmed = String(sourceText[scalarRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                guard isCIntegerLiteral(trimmed) else {
                    diagnostics.append(Diagnostic(severity: .info, code: "NDS_DATA_SEMANTIC_C_SCALAR_UNSUPPORTED", message: "Diamond/Pearl item mapping field \(mappingField.key) is not an integer literal and remains raw-source only.", span: SourceSpan(relativePath: record?.relativePath ?? diamondPearlItemCAnchorPath, startLine: lineNumber(in: sourceText, before: scalarRange.lowerBound))))
                    continue
                }
                fields.append(
                    ParsedSemanticField(
                        semanticField: NDSDataSemanticField(
                            key: "itemIndexMappings.\(rowIndex).\(mappingField.key)",
                            label: "Item Mapping \(rowIndex) \(mappingField.label)",
                            value: trimmed,
                            valueKind: .number,
                            sourceSpan: SourceSpan(relativePath: record?.relativePath ?? diamondPearlItemCAnchorPath, startLine: lineNumber(in: sourceText, before: scalarRange.lowerBound))
                        ),
                        valueRange: scalarRange,
                        syntax: .cScalar
                    )
                )
            }
            rowIndex += 1
            cursor = entryEnd
        }

        if fields.isEmpty, diagnostics.allSatisfy({ $0.severity != .error }) {
            diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_NO_C_SCALARS", message: "No integer scalar fields were found in Diamond/Pearl \(diamondPearlItemMappingTableSymbol); item C anchors remain raw-source only.", span: record?.sourceSpan))
        }
        return ParsedSemanticFields(fields: fields, diagnostics: diagnostics, unsupportedNestedKeys: [])
    }

    private static func parseDiamondPearlTrainerClassGenderFields(
        sourceText: String,
        record: NDSDataCatalogRecord?
    ) -> ParsedSemanticFields {
        var diagnostics: [Diagnostic] = []
        guard let tableRange = cInitializerTableBraceRange(sourceText, symbol: diamondPearlTrainerClassGenderTableSymbol)
        else {
            diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_C_TABLE_MISSING", message: "Diamond/Pearl trainer class gender table \(diamondPearlTrainerClassGenderTableSymbol) was not found; trainer C anchors remain raw-source only.", span: record?.sourceSpan))
            return ParsedSemanticFields(fields: [], diagnostics: diagnostics, unsupportedNestedKeys: [])
        }

        var fields: [ParsedSemanticField] = []
        var rowIndex = 0
        var cursor = sourceText.index(after: tableRange.openBrace)
        let tableClose = sourceText.index(before: tableRange.closeBraceEnd)
        while cursor < tableClose {
            skipCWhitespaceCommentsAndCommas(sourceText, index: &cursor, end: tableClose)
            guard cursor < tableClose else { break }

            let scalarStart = cursor
            var scalarEnd = cursor
            var depth = 0
            while scalarEnd < tableClose {
                if skipCCommentOrQuotedLiteral(sourceText, index: &scalarEnd, end: tableClose) {
                    continue
                }
                let character = sourceText[scalarEnd]
                if character == "(" || character == "[" || character == "{" {
                    depth += 1
                } else if character == ")" || character == "]" || character == "}" {
                    depth = max(0, depth - 1)
                } else if character == "," && depth == 0 {
                    break
                }
                scalarEnd = sourceText.index(after: scalarEnd)
            }

            if let scalarRange = trimmedRange(scalarStart..<scalarEnd, in: sourceText) {
                let trimmed = String(sourceText[scalarRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                if isCIntegerLiteral(trimmed) {
                    fields.append(
                        ParsedSemanticField(
                            semanticField: NDSDataSemanticField(
                                key: "trainerClassGenderCounts.\(rowIndex).genderCount",
                                label: "Trainer Class \(rowIndex) Gender Count",
                                value: trimmed,
                                valueKind: .number,
                                sourceSpan: SourceSpan(relativePath: record?.relativePath ?? diamondPearlTrainerCAnchorPath, startLine: lineNumber(in: sourceText, before: scalarRange.lowerBound))
                            ),
                            valueRange: scalarRange,
                            syntax: .cScalar
                        )
                    )
                } else {
                    diagnostics.append(Diagnostic(severity: .info, code: "NDS_DATA_SEMANTIC_C_SCALAR_UNSUPPORTED", message: "Diamond/Pearl trainer class gender row \(rowIndex) is not an integer literal and remains raw-source only.", span: SourceSpan(relativePath: record?.relativePath ?? diamondPearlTrainerCAnchorPath, startLine: lineNumber(in: sourceText, before: scalarRange.lowerBound))))
                }
                rowIndex += 1
            }

            cursor = scalarEnd
            if cursor < tableClose, sourceText[cursor] == "," {
                cursor = sourceText.index(after: cursor)
            }
        }

        if fields.isEmpty, diagnostics.allSatisfy({ $0.severity != .error }) {
            diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_NO_C_SCALARS", message: "No integer scalar fields were found in Diamond/Pearl \(diamondPearlTrainerClassGenderTableSymbol); trainer C anchors remain raw-source only.", span: record?.sourceSpan))
        }
        return ParsedSemanticFields(fields: fields, diagnostics: diagnostics, unsupportedNestedKeys: [])
    }

    private static func parseDiamondPearlMapHeaderFields(
        sourceText: String,
        record: NDSDataCatalogRecord?
    ) -> ParsedSemanticFields {
        var diagnostics: [Diagnostic] = []
        guard let tableRange = cInitializerTableBraceRange(sourceText, symbol: diamondPearlMapHeaderTableSymbol)
        else {
            diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_C_TABLE_MISSING", message: "Diamond/Pearl map header table \(diamondPearlMapHeaderTableSymbol) was not found; map header C anchors remain raw-source only.", span: record?.sourceSpan))
            return ParsedSemanticFields(fields: [], diagnostics: diagnostics, unsupportedNestedKeys: [])
        }

        var fields: [ParsedSemanticField] = []
        var rowIndex = 0
        var cursor = sourceText.index(after: tableRange.openBrace)
        let tableClose = sourceText.index(before: tableRange.closeBraceEnd)
        while cursor < tableClose {
            skipCWhitespaceCommentsAndCommas(sourceText, index: &cursor, end: tableClose)
            guard cursor < tableClose else { break }
            guard sourceText[cursor] == "{",
                  let entryEnd = matchingCBraceEnd(sourceText, start: cursor),
                  entryEnd <= tableRange.closeBraceEnd
            else {
                cursor = sourceText.index(after: cursor)
                continue
            }

            let entryClose = sourceText.index(before: entryEnd)
            let scalars = cTopLevelScalars(in: sourceText, start: sourceText.index(after: cursor), end: entryClose)
            guard scalars.count == DiamondPearlMapHeaderField.allCases.count else {
                diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_C_ROW_BAD_SHAPE", message: "Diamond/Pearl map header row \(rowIndex) is not a 19-scalar row and remains raw-source only.", span: SourceSpan(relativePath: record?.relativePath ?? diamondPearlMapHeaderCAnchorPath, startLine: lineNumber(in: sourceText, before: cursor))))
                rowIndex += 1
                cursor = entryEnd
                continue
            }
            for (offset, scalarRange) in scalars.prefix(DiamondPearlMapHeaderField.allCases.count).enumerated() {
                guard let mapField = DiamondPearlMapHeaderField(rawValue: offset) else { continue }
                let trimmed = String(sourceText[scalarRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                guard isCIntegerLiteral(trimmed) else {
                    diagnostics.append(Diagnostic(severity: .info, code: "NDS_DATA_SEMANTIC_C_SCALAR_UNSUPPORTED", message: "Diamond/Pearl map header field \(mapField.key) is not an integer literal and remains raw-source only.", span: SourceSpan(relativePath: record?.relativePath ?? diamondPearlMapHeaderCAnchorPath, startLine: lineNumber(in: sourceText, before: scalarRange.lowerBound))))
                    continue
                }
                fields.append(
                    ParsedSemanticField(
                        semanticField: NDSDataSemanticField(
                            key: "mapHeaders.\(rowIndex).\(mapField.key)",
                            label: "Map Header \(rowIndex) \(mapField.label)",
                            value: trimmed,
                            valueKind: .number,
                            sourceSpan: SourceSpan(relativePath: record?.relativePath ?? diamondPearlMapHeaderCAnchorPath, startLine: lineNumber(in: sourceText, before: scalarRange.lowerBound))
                        ),
                        valueRange: scalarRange,
                        syntax: .cScalar
                    )
                )
            }
            rowIndex += 1
            cursor = entryEnd
        }

        if fields.isEmpty, diagnostics.allSatisfy({ $0.severity != .error }) {
            diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_NO_C_SCALARS", message: "No integer scalar fields were found in Diamond/Pearl \(diamondPearlMapHeaderTableSymbol); map header C anchors remain raw-source only.", span: record?.sourceSpan))
        }
        return ParsedSemanticFields(fields: fields, diagnostics: diagnostics, unsupportedNestedKeys: [])
    }

    private static func parseHeartGoldSoulSilverMapHeaderFields(
        sourceText: String,
        record: NDSDataCatalogRecord?
    ) -> ParsedSemanticFields {
        var diagnostics: [Diagnostic] = []
        guard let tableRange = cInitializerTableBraceRange(sourceText, symbol: heartGoldSoulSilverMapHeaderTableSymbol)
        else {
            diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_C_TABLE_MISSING", message: "HeartGold/SoulSilver map header table \(heartGoldSoulSilverMapHeaderTableSymbol) was not found; map header C anchors remain raw-source only.", span: record?.sourceSpan))
            return ParsedSemanticFields(fields: [], diagnostics: diagnostics, unsupportedNestedKeys: [])
        }

        var fields: [ParsedSemanticField] = []
        var cursor = sourceText.index(after: tableRange.openBrace)
        let tableClose = sourceText.index(before: tableRange.closeBraceEnd)
        while cursor < tableClose {
            skipCWhitespaceCommentsAndCommas(sourceText, index: &cursor, end: tableClose)
            guard cursor < tableClose else { break }
            guard sourceText[cursor] == "[",
                  let bracketEnd = matchingBracketEnd(sourceText, start: cursor),
                  bracketEnd <= tableClose,
                  let mapKeyRange = trimmedRange(sourceText.index(after: cursor)..<sourceText.index(before: bracketEnd), in: sourceText)
            else {
                cursor = sourceText.index(after: cursor)
                continue
            }

            let mapKey = String(sourceText[mapKeyRange])
            guard isCIdentifier(mapKey) else {
                diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_C_ROW_BAD_SHAPE", message: "HeartGold/SoulSilver map header row \(mapKey) does not use a simple map constant and remains raw-source only.", span: SourceSpan(relativePath: record?.relativePath ?? heartGoldSoulSilverMapHeaderCAnchorPath, startLine: lineNumber(in: sourceText, before: cursor))))
                cursor = bracketEnd
                continue
            }

            cursor = bracketEnd
            skipCWhitespaceCommentsAndCommas(sourceText, index: &cursor, end: tableClose)
            guard cursor < tableClose, sourceText[cursor] == "=" else {
                diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_C_ROW_BAD_SHAPE", message: "HeartGold/SoulSilver map header row \(mapKey) is not a direct designated initializer and remains raw-source only.", span: SourceSpan(relativePath: record?.relativePath ?? heartGoldSoulSilverMapHeaderCAnchorPath, startLine: lineNumber(in: sourceText, before: mapKeyRange.lowerBound))))
                if cursor < tableClose {
                    cursor = sourceText.index(after: cursor)
                }
                continue
            }
            cursor = sourceText.index(after: cursor)
            skipCWhitespaceCommentsAndCommas(sourceText, index: &cursor, end: tableClose)
            guard cursor < tableClose, sourceText[cursor] == "{",
                  let entryEnd = matchingCBraceEnd(sourceText, start: cursor),
                  entryEnd <= tableRange.closeBraceEnd
            else {
                diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_C_ROW_BAD_SHAPE", message: "HeartGold/SoulSilver map header row \(mapKey) is not a direct brace initializer and remains raw-source only.", span: SourceSpan(relativePath: record?.relativePath ?? heartGoldSoulSilverMapHeaderCAnchorPath, startLine: lineNumber(in: sourceText, before: mapKeyRange.lowerBound))))
                if cursor < tableClose {
                    cursor = sourceText.index(after: cursor)
                }
                continue
            }

            parseHeartGoldSoulSilverMapHeaderEntryFields(
                sourceText: sourceText,
                mapKey: mapKey,
                start: sourceText.index(after: cursor),
                end: sourceText.index(before: entryEnd),
                record: record,
                fields: &fields,
                diagnostics: &diagnostics
            )
            cursor = entryEnd
        }

        let duplicateKeys = duplicateSemanticFieldKeys(fields)
        for key in duplicateKeys {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_C_FIELD_DUPLICATE", message: "HeartGold/SoulSilver map header scalar \(key) appears more than once; duplicate source fields must be resolved before field-level edits are planned.", span: record?.sourceSpan))
        }
        if fields.isEmpty, diagnostics.allSatisfy({ $0.severity != .error }) {
            diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_NO_C_SCALARS", message: "No integer scalar fields were found in HeartGold/SoulSilver \(heartGoldSoulSilverMapHeaderTableSymbol); map header C anchors remain raw-source only.", span: record?.sourceSpan))
        }
        return ParsedSemanticFields(fields: fields, diagnostics: diagnostics, unsupportedNestedKeys: [])
    }

    private static func parseHeartGoldSoulSilverMapHeaderEntryFields(
        sourceText: String,
        mapKey: String,
        start: String.Index,
        end: String.Index,
        record: NDSDataCatalogRecord?,
        fields: inout [ParsedSemanticField],
        diagnostics: inout [Diagnostic]
    ) {
        var cursor = start
        while cursor < end {
            skipCWhitespaceCommentsAndCommas(sourceText, index: &cursor, end: end)
            guard cursor < end else { break }
            guard sourceText[cursor] == "." else {
                cursor = sourceText.index(after: cursor)
                continue
            }

            let fieldStart = sourceText.index(after: cursor)
            guard fieldStart < end, isCIdentifierStart(sourceText[fieldStart]) else {
                cursor = fieldStart
                continue
            }
            var fieldEnd = sourceText.index(after: fieldStart)
            while fieldEnd < end, isCIdentifierContinuation(sourceText[fieldEnd]) {
                fieldEnd = sourceText.index(after: fieldEnd)
            }
            let fieldName = String(sourceText[fieldStart..<fieldEnd])
            cursor = fieldEnd
            skipCWhitespaceCommentsAndCommas(sourceText, index: &cursor, end: end)
            guard cursor < end, sourceText[cursor] == "=" else {
                diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_C_FIELD_BAD_SHAPE", message: "HeartGold/SoulSilver map header field \(mapKey).\(fieldName) is not a direct assignment and remains raw-source only.", span: SourceSpan(relativePath: record?.relativePath ?? heartGoldSoulSilverMapHeaderCAnchorPath, startLine: lineNumber(in: sourceText, before: fieldStart))))
                if cursor < end {
                    cursor = sourceText.index(after: cursor)
                }
                continue
            }
            cursor = sourceText.index(after: cursor)
            skipCWhitespaceCommentsAndCommas(sourceText, index: &cursor, end: end)

            let valueStart = cursor
            var valueEnd = cursor
            var depth = 0
            while valueEnd < end {
                if skipCCommentOrQuotedLiteral(sourceText, index: &valueEnd, end: end) {
                    continue
                }
                let character = sourceText[valueEnd]
                if character == "(" || character == "[" || character == "{" {
                    depth += 1
                } else if character == ")" || character == "]" || character == "}" {
                    depth = max(0, depth - 1)
                } else if character == "," && depth == 0 {
                    break
                }
                valueEnd = sourceText.index(after: valueEnd)
            }

            if let scalarRange = trimmedRange(valueStart..<valueEnd, in: sourceText) {
                let trimmed = String(sourceText[scalarRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                if isCIntegerLiteral(trimmed) {
                    fields.append(
                        ParsedSemanticField(
                            semanticField: NDSDataSemanticField(
                                key: "mapHeaders.\(mapKey).\(fieldName)",
                                label: "\(mapKey) \(semanticLabel(for: fieldName))",
                                value: trimmed,
                                valueKind: .number,
                                sourceSpan: SourceSpan(relativePath: record?.relativePath ?? heartGoldSoulSilverMapHeaderCAnchorPath, startLine: lineNumber(in: sourceText, before: scalarRange.lowerBound))
                            ),
                            valueRange: scalarRange,
                            syntax: .cScalar
                        )
                    )
                } else {
                    diagnostics.append(Diagnostic(severity: .info, code: "NDS_DATA_SEMANTIC_C_SCALAR_UNSUPPORTED", message: "HeartGold/SoulSilver map header field \(mapKey).\(fieldName) is not an integer literal and remains raw-source only.", span: SourceSpan(relativePath: record?.relativePath ?? heartGoldSoulSilverMapHeaderCAnchorPath, startLine: lineNumber(in: sourceText, before: scalarRange.lowerBound))))
                }
            }

            cursor = valueEnd
            if cursor < end, sourceText[cursor] == "," {
                cursor = sourceText.index(after: cursor)
            }
        }
    }

    private static func parseEncounterSlotJSONFields(
        sourceText: String,
        record: NDSDataCatalogRecord?,
        gameLabel: String
    ) -> ParsedSemanticFields {
        var diagnostics: [Diagnostic] = []
        let trimmed = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{") else {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_JSON_OBJECT_REQUIRED", message: "\(gameLabel) encounter semantic editing requires a top-level JSON object.", span: record?.sourceSpan))
            return ParsedSemanticFields(fields: [], diagnostics: diagnostics, unsupportedNestedKeys: [])
        }
        if let data = sourceText.data(using: .utf8),
           (try? JSONSerialization.jsonObject(with: data)) == nil {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_JSON_MALFORMED", message: "\(gameLabel) encounter semantic editing requires parseable JSON before slot field edits are planned.", span: record?.sourceSpan))
            return ParsedSemanticFields(fields: [], diagnostics: diagnostics, unsupportedNestedKeys: [])
        }

        var fields: [ParsedSemanticField] = []
        var seenTopLevelKeys: Set<String> = []
        var duplicateTopLevelKeys: Set<String> = []
        var unsupportedNestedKeys: Set<String> = []
        var index = sourceText.startIndex
        guard let objectStart = sourceText[index...].firstIndex(of: "{") else {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_JSON_OBJECT_REQUIRED", message: "\(gameLabel) encounter semantic editing requires a top-level JSON object.", span: record?.sourceSpan))
            return ParsedSemanticFields(fields: [], diagnostics: diagnostics, unsupportedNestedKeys: [])
        }
        index = sourceText.index(after: objectStart)

        while index < sourceText.endIndex {
            skipWhitespaceAndCommas(sourceText, index: &index)
            guard index < sourceText.endIndex, sourceText[index] != "}" else { break }
            guard sourceText[index] == "\"", let keyToken = parseJSONStringToken(sourceText, start: index) else {
                skipJSONValueOrToken(sourceText, index: &index)
                continue
            }
            index = keyToken.end
            if !seenTopLevelKeys.insert(keyToken.value).inserted {
                duplicateTopLevelKeys.insert(keyToken.value)
            }
            skipWhitespace(sourceText, index: &index)
            guard index < sourceText.endIndex, sourceText[index] == ":" else { continue }
            index = sourceText.index(after: index)
            skipWhitespace(sourceText, index: &index)
            let valueStart = index
            if let value = parseJSONScalarValue(sourceText, start: valueStart) {
                index = value.end
                fields.append(encounterSlotField(key: keyToken.value, label: semanticLabel(for: keyToken.value), value: value, sourceText: sourceText, record: record, valueStart: valueStart))
            } else if valueStart < sourceText.endIndex, sourceText[valueStart] == "[" {
                parseEncounterSlotArrayFields(
                    sourceText: sourceText,
                    arrayKey: keyToken.value,
                    start: valueStart,
                    record: record,
                    fields: &fields,
                    diagnostics: &diagnostics
                )
                skipJSONValueOrToken(sourceText, index: &index)
            } else {
                if valueStart < sourceText.endIndex, sourceText[valueStart] == "{" {
                    unsupportedNestedKeys.insert(keyToken.value)
                    diagnostics.append(
                        Diagnostic(
                            severity: .info,
                            code: "NDS_DATA_SEMANTIC_NESTED_VALUE_UNSUPPORTED",
                            message: "\(gameLabel) encounter field \(keyToken.value) is nested and remains raw-source only in this slice.",
                            span: SourceSpan(relativePath: record?.relativePath ?? "", startLine: lineNumber(in: sourceText, before: valueStart))
                        )
                    )
                } else {
                    diagnostics.append(
                        Diagnostic(
                            severity: .error,
                            code: "NDS_DATA_SEMANTIC_SCALAR_INVALID",
                            message: "\(gameLabel) encounter field \(keyToken.value) has an invalid scalar JSON value.",
                            span: SourceSpan(relativePath: record?.relativePath ?? "", startLine: lineNumber(in: sourceText, before: valueStart))
                        )
                    )
                }
                skipJSONValueOrToken(sourceText, index: &index)
            }
        }
        for key in duplicateTopLevelKeys.sorted() {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_SEMANTIC_JSON_KEY_DUPLICATE",
                    message: "\(gameLabel) encounter JSON field \(key) appears more than once; duplicate source keys must be resolved before field-level edits are planned.",
                    span: record?.sourceSpan
                )
            )
        }
        for key in duplicateSemanticFieldKeys(fields) {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_SEMANTIC_JSON_KEY_DUPLICATE",
                    message: "\(gameLabel) encounter slot field \(key) appears more than once; duplicate source keys must be resolved before field-level edits are planned.",
                    span: record?.sourceSpan
                )
            )
        }
        if fields.isEmpty, diagnostics.allSatisfy({ $0.severity != .error }) {
            diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_NO_SCALAR_FIELDS", message: "No top-level or slot scalar JSON fields were found for \(gameLabel) encounter semantic editing.", span: record?.sourceSpan))
        }
        return ParsedSemanticFields(fields: fields, diagnostics: diagnostics, unsupportedNestedKeys: unsupportedNestedKeys)
    }

    private static func parseEncounterSlotArrayFields(
        sourceText: String,
        arrayKey: String,
        start: String.Index,
        record: NDSDataCatalogRecord?,
        fields: inout [ParsedSemanticField],
        diagnostics: inout [Diagnostic]
    ) {
        guard start < sourceText.endIndex,
              sourceText[start] == "[",
              let arrayEnd = matchingBracketEnd(sourceText, start: start)
        else {
            return
        }
        var cursor = sourceText.index(after: start)
        let close = sourceText.index(before: arrayEnd)
        var elementIndex = 0
        while cursor < close {
            skipWhitespace(sourceText, index: &cursor)
            guard cursor < close else { break }
            if sourceText[cursor] == "," {
                cursor = sourceText.index(after: cursor)
                continue
            }
            if sourceText[cursor] == "]" {
                break
            }
            if let value = parseJSONScalarValue(sourceText, start: cursor) {
                fields.append(
                    encounterSlotField(
                        key: "\(arrayKey).\(elementIndex)",
                        label: "\(semanticLabel(for: arrayKey)) #\(elementIndex + 1)",
                        value: value,
                        sourceText: sourceText,
                        record: record,
                        valueStart: cursor
                    )
                )
                cursor = value.end
            } else if sourceText[cursor] == "{" {
                cursor = parseEncounterSlotObjectFields(
                    sourceText: sourceText,
                    arrayKey: arrayKey,
                    slotIndex: elementIndex,
                    start: cursor,
                    record: record,
                    fields: &fields,
                    diagnostics: &diagnostics
                )
            } else {
                skipJSONValueOrToken(sourceText, index: &cursor)
            }
            elementIndex += 1
            skipWhitespace(sourceText, index: &cursor)
            if cursor < close, sourceText[cursor] == "," {
                cursor = sourceText.index(after: cursor)
            }
        }
    }

    private static func parseEncounterSlotObjectFields(
        sourceText: String,
        arrayKey: String,
        slotIndex: Int,
        start: String.Index,
        record: NDSDataCatalogRecord?,
        fields: inout [ParsedSemanticField],
        diagnostics: inout [Diagnostic]
    ) -> String.Index {
        guard start < sourceText.endIndex,
              sourceText[start] == "{",
              let objectEnd = matchingCBraceEnd(sourceText, start: start)
        else {
            var cursor = start
            skipJSONValueOrToken(sourceText, index: &cursor)
            return cursor
        }
        var cursor = sourceText.index(after: start)
        let close = sourceText.index(before: objectEnd)
        while cursor < close {
            skipWhitespaceAndCommas(sourceText, index: &cursor)
            guard cursor < close else { break }
            guard sourceText[cursor] == "\"", let keyToken = parseJSONStringToken(sourceText, start: cursor) else {
                skipJSONValueOrToken(sourceText, index: &cursor)
                continue
            }
            cursor = keyToken.end
            skipWhitespace(sourceText, index: &cursor)
            guard cursor < close, sourceText[cursor] == ":" else { continue }
            cursor = sourceText.index(after: cursor)
            skipWhitespace(sourceText, index: &cursor)
            let valueStart = cursor
            if let value = parseJSONScalarValue(sourceText, start: valueStart) {
                fields.append(
                    encounterSlotField(
                        key: "\(arrayKey).\(slotIndex).\(keyToken.value)",
                        label: "\(semanticLabel(for: arrayKey)) #\(slotIndex + 1) \(semanticLabel(for: keyToken.value))",
                        value: value,
                        sourceText: sourceText,
                        record: record,
                        valueStart: valueStart
                    )
                )
                cursor = value.end
            } else {
                skipJSONValueOrToken(sourceText, index: &cursor)
            }
        }
        return objectEnd
    }

    private static func encounterSlotField(
        key: String,
        label: String,
        value: (displayValue: String, kind: NDSDataSemanticFieldValueKind, end: String.Index),
        sourceText: String,
        record: NDSDataCatalogRecord?,
        valueStart: String.Index
    ) -> ParsedSemanticField {
        ParsedSemanticField(
            semanticField: NDSDataSemanticField(
                key: key,
                label: label,
                value: value.displayValue,
                valueKind: value.kind,
                sourceSpan: SourceSpan(relativePath: record?.relativePath ?? "", startLine: lineNumber(in: sourceText, before: valueStart))
            ),
            valueRange: valueStart..<value.end
        )
    }

    private static func parseTopLevelScalarJSONFields(
        sourceText: String,
        record: NDSDataCatalogRecord?
    ) -> ParsedSemanticFields {
        var diagnostics: [Diagnostic] = []
        let trimmed = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{") else {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_JSON_OBJECT_REQUIRED", message: "Semantic NDS editing requires a top-level JSON object.", span: record?.sourceSpan))
            return ParsedSemanticFields(fields: [], diagnostics: diagnostics, unsupportedNestedKeys: [])
        }
        if let data = sourceText.data(using: .utf8),
           (try? JSONSerialization.jsonObject(with: data)) == nil {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_JSON_MALFORMED", message: "Semantic NDS editing requires parseable JSON before field-level edits are planned.", span: record?.sourceSpan))
            return ParsedSemanticFields(fields: [], diagnostics: diagnostics, unsupportedNestedKeys: [])
        }

        var fields: [ParsedSemanticField] = []
        var seenTopLevelKeys: Set<String> = []
        var duplicateTopLevelKeys: Set<String> = []
        var unsupportedNestedKeys: Set<String> = []
        var index = sourceText.startIndex
        guard let objectStart = sourceText[index...].firstIndex(of: "{") else {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_JSON_OBJECT_REQUIRED", message: "Semantic NDS editing requires a top-level JSON object.", span: record?.sourceSpan))
            return ParsedSemanticFields(fields: [], diagnostics: diagnostics, unsupportedNestedKeys: [])
        }
        index = sourceText.index(after: objectStart)

        while index < sourceText.endIndex {
            skipWhitespaceAndCommas(sourceText, index: &index)
            guard index < sourceText.endIndex, sourceText[index] != "}" else { break }
            guard sourceText[index] == "\"", let keyToken = parseJSONStringToken(sourceText, start: index) else {
                skipJSONValueOrToken(sourceText, index: &index)
                continue
            }
            index = keyToken.end
            if !seenTopLevelKeys.insert(keyToken.value).inserted {
                duplicateTopLevelKeys.insert(keyToken.value)
            }
            skipWhitespace(sourceText, index: &index)
            guard index < sourceText.endIndex, sourceText[index] == ":" else { continue }
            index = sourceText.index(after: index)
            skipWhitespace(sourceText, index: &index)
            let valueStart = index
            guard let value = parseJSONScalarValue(sourceText, start: valueStart) else {
                if valueStart < sourceText.endIndex, sourceText[valueStart] == "{" || sourceText[valueStart] == "[" {
                    unsupportedNestedKeys.insert(keyToken.value)
                    diagnostics.append(
                        Diagnostic(
                            severity: .info,
                            code: "NDS_DATA_SEMANTIC_NESTED_VALUE_UNSUPPORTED",
                            message: "Semantic NDS field \(keyToken.value) is nested and remains raw-source only in this slice.",
                            span: SourceSpan(relativePath: record?.relativePath ?? "", startLine: lineNumber(in: sourceText, before: valueStart))
                        )
                    )
                } else {
                    diagnostics.append(
                        Diagnostic(
                            severity: .error,
                            code: "NDS_DATA_SEMANTIC_SCALAR_INVALID",
                            message: "Semantic NDS field \(keyToken.value) has an invalid scalar JSON value.",
                            span: SourceSpan(relativePath: record?.relativePath ?? "", startLine: lineNumber(in: sourceText, before: valueStart))
                        )
                    )
                }
                skipJSONValueOrToken(sourceText, index: &index)
                continue
            }
            index = value.end
            let field = NDSDataSemanticField(
                key: keyToken.value,
                label: semanticLabel(for: keyToken.value),
                value: value.displayValue,
                valueKind: value.kind,
                sourceSpan: SourceSpan(relativePath: record?.relativePath ?? "", startLine: lineNumber(in: sourceText, before: valueStart))
            )
            fields.append(ParsedSemanticField(semanticField: field, valueRange: valueStart..<value.end))
        }
        for key in duplicateTopLevelKeys.sorted() {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_SEMANTIC_JSON_KEY_DUPLICATE",
                    message: "Semantic NDS JSON field \(key) appears more than once; duplicate source keys must be resolved before field-level edits are planned.",
                    span: record?.sourceSpan
                )
            )
        }

        let evolutionFields = parseEvolutionTupleJSONFields(sourceText: sourceText, record: record)
        fields.append(contentsOf: evolutionFields.fields)
        diagnostics.append(contentsOf: evolutionFields.diagnostics)

        if fields.isEmpty, diagnostics.allSatisfy({ $0.severity != .error }) {
            diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_NO_SCALAR_FIELDS", message: "No top-level scalar JSON fields were found for semantic NDS editing.", span: record?.sourceSpan))
        }
        return ParsedSemanticFields(fields: fields, diagnostics: diagnostics, unsupportedNestedKeys: unsupportedNestedKeys)
    }

    private static func parseEvolutionTupleJSONFields(
        sourceText: String,
        record: NDSDataCatalogRecord?
    ) -> (fields: [ParsedSemanticField], diagnostics: [Diagnostic]) {
        guard record?.domain == .species || record == nil,
              let valueRange = topLevelJSONValueRange(sourceText, key: "evolutions"),
              valueRange.lowerBound < sourceText.endIndex,
              sourceText[valueRange.lowerBound] == "["
        else {
            return ([], [])
        }

        var fields: [ParsedSemanticField] = []
        var diagnostics: [Diagnostic] = []
        var tupleIndex = 0
        var index = sourceText.index(after: valueRange.lowerBound)
        while index < valueRange.upperBound {
            skipWhitespaceAndCommas(sourceText, index: &index)
            guard index < valueRange.upperBound, sourceText[index] != "]" else { break }
            guard sourceText[index] == "[",
                  let tupleEnd = matchingBracketEnd(sourceText, start: index)
            else {
                skipJSONValueOrToken(sourceText, index: &index)
                continue
            }

            var tupleCursor = sourceText.index(after: index)
            let method = parseTupleScalarField(sourceText, cursor: &tupleCursor, tupleEnd: tupleEnd, tupleIndex: tupleIndex, key: "method", record: record)
            if let method {
                fields.append(method)
            }
            let parameter = parseTupleScalarField(sourceText, cursor: &tupleCursor, tupleEnd: tupleEnd, tupleIndex: tupleIndex, key: "parameter", record: record)
            if let parameter {
                fields.append(parameter)
            }
            let target = parseTupleScalarField(sourceText, cursor: &tupleCursor, tupleEnd: tupleEnd, tupleIndex: tupleIndex, key: "target", record: record)
            if let target {
                fields.append(target)
            }
            skipWhitespaceAndCommas(sourceText, index: &tupleCursor)
            let contentEnd = sourceText.index(before: tupleEnd)
            if method == nil || parameter == nil || target == nil || tupleCursor < contentEnd {
                diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_EVOLUTION_TUPLE_BAD_SHAPE", message: "Evolution tuple \(tupleIndex + 1) is not a three-scalar method/parameter/target row and remains raw-source only.", span: record?.sourceSpan))
            }

            index = tupleEnd
            tupleIndex += 1
        }
        return (fields, diagnostics)
    }

    private static func parseTupleScalarField(
        _ sourceText: String,
        cursor: inout String.Index,
        tupleEnd: String.Index,
        tupleIndex: Int,
        key: String,
        record: NDSDataCatalogRecord?
    ) -> ParsedSemanticField? {
        skipWhitespaceAndCommas(sourceText, index: &cursor)
        guard cursor < tupleEnd, let value = parseJSONScalarValue(sourceText, start: cursor) else { return nil }
        let valueStart = cursor
        cursor = value.end
        let semanticKey = "evolutions.\(tupleIndex).\(key)"
        return ParsedSemanticField(
            semanticField: NDSDataSemanticField(
                key: semanticKey,
                label: "Evolution \(tupleIndex + 1) \(semanticLabel(for: key))",
                value: value.displayValue,
                valueKind: value.kind,
                sourceSpan: SourceSpan(relativePath: record?.relativePath ?? "", startLine: lineNumber(in: sourceText, before: valueStart))
            ),
            valueRange: valueStart..<value.end
        )
    }

    private static func topLevelJSONValueRange(_ sourceText: String, key: String) -> Range<String.Index>? {
        var index = sourceText.startIndex
        guard let objectStart = sourceText[index...].firstIndex(of: "{") else { return nil }
        index = sourceText.index(after: objectStart)

        while index < sourceText.endIndex {
            skipWhitespaceAndCommas(sourceText, index: &index)
            guard index < sourceText.endIndex, sourceText[index] != "}" else { break }
            guard sourceText[index] == "\"", let keyToken = parseJSONStringToken(sourceText, start: index) else {
                skipJSONValueOrToken(sourceText, index: &index)
                continue
            }
            index = keyToken.end
            skipWhitespace(sourceText, index: &index)
            guard index < sourceText.endIndex, sourceText[index] == ":" else { continue }
            index = sourceText.index(after: index)
            skipWhitespace(sourceText, index: &index)
            let valueStart = index
            skipJSONValueOrToken(sourceText, index: &index)
            if keyToken.value == key {
                return valueStart..<index
            }
        }
        return nil
    }

    private static func cExactStaticConstStructTableBraceRange(
        _ text: String,
        structName: String,
        symbol: String
    ) -> (openBrace: String.Index, closeBraceEnd: String.Index)? {
        var index = text.startIndex
        while index < text.endIndex {
            if skipCCommentOrQuotedLiteral(text, index: &index, end: text.endIndex) {
                continue
            }
            guard isCIdentifierStart(text[index]) else {
                index = text.index(after: index)
                continue
            }
            let identifierStart = index
            index = text.index(after: index)
            while index < text.endIndex, isCIdentifierContinuation(text[index]) {
                index = text.index(after: index)
            }
            guard String(text[identifierStart..<index]) == symbol,
                  isExactStaticConstStructDeclarator(
                    text,
                    structName: structName,
                    symbolStart: identifierStart,
                    symbolEnd: index
                  )
            else {
                continue
            }
            var cursor = index
            guard let openBrace = nextCInitializerOpenBrace(text, from: &cursor),
                  let closeBraceEnd = matchingCBraceEnd(text, start: openBrace)
            else {
                continue
            }
            return (openBrace, closeBraceEnd)
        }
        return nil
    }

    private static func isExactStaticConstStructDeclarator(
        _ text: String,
        structName: String,
        symbolStart: String.Index,
        symbolEnd: String.Index
    ) -> Bool {
        let lineStart = text[..<symbolStart].lastIndex(of: "\n").map { text.index(after: $0) } ?? text.startIndex
        let prefix = String(text[lineStart..<symbolStart])
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
        guard prefix == "static const struct \(structName)" else {
            return false
        }

        var cursor = symbolEnd
        skipCWhitespaceAndComments(text, index: &cursor, end: text.endIndex)
        guard cursor < text.endIndex, text[cursor] == "[" else { return false }
        cursor = text.index(after: cursor)
        skipCWhitespaceAndComments(text, index: &cursor, end: text.endIndex)
        guard cursor < text.endIndex, text[cursor] == "]" else { return false }
        cursor = text.index(after: cursor)
        skipCWhitespaceAndComments(text, index: &cursor, end: text.endIndex)
        return cursor < text.endIndex && text[cursor] == "="
    }

    private static func cInitializerTableBraceRange(
        _ text: String,
        symbol: String
    ) -> (openBrace: String.Index, closeBraceEnd: String.Index)? {
        var index = text.startIndex
        while index < text.endIndex {
            if skipCCommentOrQuotedLiteral(text, index: &index, end: text.endIndex) {
                continue
            }
            guard isCIdentifierStart(text[index]) else {
                index = text.index(after: index)
                continue
            }
            let identifierStart = index
            index = text.index(after: index)
            while index < text.endIndex, isCIdentifierContinuation(text[index]) {
                index = text.index(after: index)
            }
            guard String(text[identifierStart..<index]) == symbol,
                  let openBrace = nextCInitializerOpenBrace(text, from: index),
                  let closeBraceEnd = matchingCBraceEnd(text, start: openBrace)
            else {
                continue
            }
            return (openBrace, closeBraceEnd)
        }
        return nil
    }

    private static func nextCInitializerOpenBrace(_ text: String, from start: String.Index) -> String.Index? {
        var index = start
        return nextCInitializerOpenBrace(text, from: &index)
    }

    private static func nextCInitializerOpenBrace(_ text: String, from start: inout String.Index) -> String.Index? {
        var index = start
        while index < text.endIndex {
            if skipCCommentOrQuotedLiteral(text, index: &index, end: text.endIndex) {
                continue
            }
            if text[index] == ";" {
                return nil
            }
            if text[index] == "{" {
                return index
            }
            index = text.index(after: index)
        }
        start = index
        return nil
    }

    private static func matchingBracketEnd(_ text: String, start: String.Index) -> String.Index? {
        guard start < text.endIndex, text[start] == "[" else { return nil }
        var index = start
        var depth = 0
        var inString = false
        var escaped = false
        while index < text.endIndex {
            let character = text[index]
            if inString {
                if escaped {
                    escaped = false
                } else if character == "\\" {
                    escaped = true
                } else if character == "\"" {
                    inString = false
                }
            } else if character == "\"" {
                inString = true
            } else if character == "[" {
                depth += 1
            } else if character == "]" {
                depth -= 1
                if depth == 0 {
                    return text.index(after: index)
                }
            }
            index = text.index(after: index)
        }
        return nil
    }

    private static func matchingCBraceEnd(_ text: String, start: String.Index) -> String.Index? {
        guard start < text.endIndex, text[start] == "{" else { return nil }
        var index = start
        var depth = 0
        while index < text.endIndex {
            if skipCCommentOrQuotedLiteral(text, index: &index, end: text.endIndex) {
                continue
            }
            if text[index] == "{" {
                depth += 1
            } else if text[index] == "}" {
                depth -= 1
                if depth == 0 {
                    return text.index(after: index)
                }
            }
            index = text.index(after: index)
        }
        return nil
    }

    private static func cTopLevelScalars(in text: String, start: String.Index, end: String.Index) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var scalarStart = start
        var index = start
        var depth = 0
        while index < end {
            if skipCCommentOrQuotedLiteral(text, index: &index, end: end) {
                continue
            }
            let character = text[index]
            if character == "(" || character == "[" || character == "{" {
                depth += 1
            } else if character == ")" || character == "]" || character == "}" {
                depth = max(0, depth - 1)
            } else if character == "," && depth == 0 {
                if let range = trimmedRange(scalarStart..<index, in: text) {
                    ranges.append(range)
                }
                scalarStart = text.index(after: index)
            }
            index = text.index(after: index)
        }
        if let range = trimmedRange(scalarStart..<end, in: text) {
            ranges.append(range)
        }
        return ranges
    }

    private static func cTopLevelValueEnd(_ text: String, start: String.Index, end: String.Index) -> String.Index {
        var index = start
        var depth = 0
        while index < end {
            if skipCCommentOrQuotedLiteral(text, index: &index, end: end) {
                continue
            }
            let character = text[index]
            if character == "(" || character == "[" || character == "{" {
                depth += 1
            } else if character == ")" || character == "]" || character == "}" {
                depth = max(0, depth - 1)
            } else if character == "," && depth == 0 {
                break
            }
            index = text.index(after: index)
        }
        return index
    }

    private static func skipCInitializerEntry(_ text: String, cursor: inout String.Index, end: String.Index) {
        while cursor < end {
            if skipCCommentOrQuotedLiteral(text, index: &cursor, end: end) {
                continue
            }
            if text[cursor] == "{",
               let entryEnd = matchingCBraceEnd(text, start: cursor),
               entryEnd <= end {
                cursor = entryEnd
                if cursor < end, text[cursor] == "," {
                    cursor = text.index(after: cursor)
                }
                return
            }
            if text[cursor] == "," {
                cursor = text.index(after: cursor)
                return
            }
            cursor = text.index(after: cursor)
        }
    }

    private static func skipCWhitespaceCommentsAndCommas(_ text: String, index: inout String.Index, end: String.Index) {
        while index < end {
            if text[index].isWhitespace || text[index] == "," {
                index = text.index(after: index)
            } else if skipCCommentOrQuotedLiteral(text, index: &index, end: end) {
                continue
            } else {
                break
            }
        }
    }

    private static func skipCWhitespaceAndComments(_ text: String, index: inout String.Index, end: String.Index) {
        while index < end {
            if text[index].isWhitespace {
                index = text.index(after: index)
            } else if skipCCommentOrQuotedLiteral(text, index: &index, end: end) {
                continue
            } else {
                break
            }
        }
    }

    private static func skipCCommentOrQuotedLiteral(_ text: String, index: inout String.Index, end: String.Index) -> Bool {
        guard index < end else { return false }
        if text[index] == "\"" || text[index] == "'" {
            let quote = text[index]
            index = text.index(after: index)
            var escaped = false
            while index < end {
                let character = text[index]
                if escaped {
                    escaped = false
                } else if character == "\\" {
                    escaped = true
                } else if character == quote {
                    index = text.index(after: index)
                    return true
                }
                index = text.index(after: index)
            }
            return true
        }

        guard text[index] == "/" else { return false }
        let next = text.index(after: index)
        guard next < end else { return false }
        if text[next] == "/" {
            index = text.index(after: next)
            while index < end, text[index] != "\n" {
                index = text.index(after: index)
            }
            return true
        }
        if text[next] == "*" {
            index = text.index(after: next)
            while index < end {
                let after = text.index(after: index)
                if text[index] == "*", after < end, text[after] == "/" {
                    index = text.index(after: after)
                    return true
                }
                index = after
            }
            return true
        }
        return false
    }

    private static func isCIdentifierStart(_ character: Character) -> Bool {
        character == "_" || character.isLetter
    }

    private static func isCIdentifierContinuation(_ character: Character) -> Bool {
        isCIdentifierStart(character) || character.isNumber
    }

    private static func isCIdentifier(_ value: String) -> Bool {
        guard let first = value.first, isCIdentifierStart(first) else { return false }
        return value.dropFirst().allSatisfy(isCIdentifierContinuation)
    }

    private static func trimmedRange(_ range: Range<String.Index>, in text: String) -> Range<String.Index>? {
        var lower = range.lowerBound
        var upper = range.upperBound
        while lower < upper, text[lower].isWhitespace {
            lower = text.index(after: lower)
        }
        while lower < upper {
            let beforeUpper = text.index(before: upper)
            guard text[beforeUpper].isWhitespace else { break }
            upper = beforeUpper
        }
        return lower < upper ? lower..<upper : nil
    }

    private static func isCIntegerLiteral(_ value: String) -> Bool {
        value.trimmingCharacters(in: .whitespacesAndNewlines).range(
            of: #"^[+-]?(?:0[xX][0-9A-Fa-f]+|0[bB][01]+|[0-9]+)(?:[uUlL]+)?$"#,
            options: .regularExpression
        ) != nil
    }

    private static func isCSimpleScalar(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return isCIntegerLiteral(trimmed) || isCIdentifier(trimmed)
    }

    private static func parseJSONStringToken(_ text: String, start: String.Index) -> (value: String, end: String.Index)? {
        guard start < text.endIndex, text[start] == "\"" else { return nil }
        var index = text.index(after: start)
        var escaped = false
        while index < text.endIndex {
            let character = text[index]
            if escaped {
                escaped = false
            } else if character == "\\" {
                escaped = true
            } else if character == "\"" {
                let end = text.index(after: index)
                let literal = String(text[start..<end])
                guard
                    let data = literal.data(using: .utf8),
                    let value = try? JSONDecoder().decode(String.self, from: data)
                else {
                    return nil
                }
                return (value, end)
            }
            index = text.index(after: index)
        }
        return nil
    }

    private static func parseJSONScalarValue(
        _ text: String,
        start: String.Index
    ) -> (displayValue: String, kind: NDSDataSemanticFieldValueKind, end: String.Index)? {
        guard start < text.endIndex else { return nil }
        if text[start] == "\"" {
            guard let token = parseJSONStringToken(text, start: start) else { return nil }
            return (token.value, .string, token.end)
        }

        var index = start
        while index < text.endIndex, ![",", "}", "\n", "\r"].contains(text[index]) {
            index = text.index(after: index)
        }
        let raw = text[start..<index].trimmingCharacters(in: .whitespacesAndNewlines)
        if raw == "true" || raw == "false" {
            return (raw, .bool, index)
        }
        if raw == "null" {
            return (raw, .null, index)
        }
        if Double(raw) != nil {
            return (raw, .number, index)
        }
        return nil
    }

    private static func renderedJSONValue(_ value: String, as kind: NDSDataSemanticFieldValueKind) -> String? {
        switch kind {
        case .string:
            return jsonStringLiteral(value)
        case .number:
            return Double(value.trimmingCharacters(in: .whitespacesAndNewlines)) == nil ? nil : value.trimmingCharacters(in: .whitespacesAndNewlines)
        case .bool:
            let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return (normalized == "true" || normalized == "false") ? normalized : nil
        case .null:
            return value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "null" ? "null" : nil
        }
    }

    private static func renderedCScalarValue(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return isCIntegerLiteral(trimmed) ? trimmed : nil
    }

    private static func renderedCSimpleScalarValue(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return isCSimpleScalar(trimmed) ? trimmed : nil
    }

    private static func renderedCSVCellValue(_ value: String) -> String? {
        guard !value.contains(where: { $0 == "\n" || $0 == "\r" }) else { return nil }
        let needsQuoting = value.contains(",")
            || value.contains("\"")
            || value.first?.isWhitespace == true
            || value.last?.isWhitespace == true
        guard needsQuoting else { return value }

        var rendered = "\""
        for character in value {
            if character == "\"" {
                rendered += "\"\""
            } else {
                rendered.append(character)
            }
        }
        rendered += "\""
        return rendered
    }

    private static func renderedTextLineValue(_ value: String) -> String? {
        value.contains(where: { $0 == "\n" || $0 == "\r" }) ? nil : value
    }

    private static func renderedTextJSONStringValue(_ value: String) -> String? {
        guard !value.contains(where: { $0 == "\n" || $0 == "\r" }) else { return nil }
        return jsonStringLiteral(value)
    }

    private static func renderedValue(_ value: String, for field: ParsedSemanticField) -> String? {
        switch field.syntax {
        case .json:
            return renderedJSONValue(value, as: field.semanticField.valueKind)
        case .cScalar:
            return renderedCScalarValue(value)
        case .cSimpleScalar:
            return renderedCSimpleScalarValue(value)
        case .csvCell:
            return renderedCSVCellValue(value)
        case .textLine:
            return renderedTextLineValue(value)
        case .textJSONString:
            return renderedTextJSONStringValue(value)
        }
    }

    private static func jsonStringLiteral(_ value: String) -> String {
        var escaped = "\""
        for character in value {
            switch character {
            case "\\":
                escaped += "\\\\"
            case "\"":
                escaped += "\\\""
            case "\n":
                escaped += "\\n"
            case "\r":
                escaped += "\\r"
            case "\t":
                escaped += "\\t"
            default:
                escaped.append(character)
            }
        }
        escaped += "\""
        return escaped
    }

    private static func semanticLabel(for key: String) -> String {
        key
            .split(separator: "_")
            .map { word in word.prefix(1).uppercased() + String(word.dropFirst()) }
            .joined(separator: " ")
    }

    private static func semanticTextJSONLabel(for components: [String]) -> String {
        guard !components.isEmpty else { return "Value" }
        return components.map { component in
            if let index = Int(component) {
                return "#\(index + 1)"
            }
            return semanticLabel(for: component)
        }
        .joined(separator: " ")
    }

    private static func blockedEditPlan(
        catalog: ProjectNDSDataCatalog,
        draft: NDSDataEditDraft,
        diagnostics: [Diagnostic]
    ) -> NDSDataEditPlan {
        let mutationPlan = MutationPlan(
            title: "NDS semantic data edits blocked",
            summary: "No NDS source files are applyable until semantic edit diagnostics are resolved.",
            diagnostics: diagnostics,
            requiresExplicitApply: true
        )
        return NDSDataEditPlan(
            rootPath: catalog.root.path,
            recordID: draft.recordID,
            draft: draft,
            changes: [],
            diagnostics: diagnostics,
            mutationPlan: mutationPlan,
            backupRelativeRoot: ".pokemonhackstudio/backups/semantic-blocked"
        )
    }

    private static func skipWhitespace(_ text: String, index: inout String.Index) {
        while index < text.endIndex, text[index].isWhitespace {
            index = text.index(after: index)
        }
    }

    private static func skipWhitespaceAndCommas(_ text: String, index: inout String.Index) {
        while index < text.endIndex, text[index].isWhitespace || text[index] == "," {
            index = text.index(after: index)
        }
    }

    private static func skipJSONValueOrToken(_ text: String, index: inout String.Index) {
        guard index < text.endIndex else { return }
        var depth = 0
        var inString = false
        var escaped = false
        while index < text.endIndex {
            let character = text[index]
            if inString {
                if escaped {
                    escaped = false
                } else if character == "\\" {
                    escaped = true
                } else if character == "\"" {
                    inString = false
                }
            } else if character == "\"" {
                inString = true
            } else if character == "{" || character == "[" {
                depth += 1
            } else if character == "}" || character == "]" {
                if depth == 0 { return }
                depth -= 1
            } else if character == "," && depth == 0 {
                return
            }
            index = text.index(after: index)
        }
    }

    private static func lineNumber(in text: String, before index: String.Index) -> Int {
        text[..<index].reduce(1) { count, character in character == "\n" ? count + 1 : count }
    }
}

public enum NDSDataTextLineOperationPlanner {
    public static func plan(
        catalog: ProjectNDSDataCatalog,
        draft: NDSDataTextLineOperationDraft,
        fileManager: FileManager = .default
    ) -> NDSDataTextLineOperationPlan {
        let record = catalog.records.first(where: { $0.id == draft.recordID })
        let sourceText = NDSDataMutationPlanner.sourceText(
            catalog: catalog,
            recordID: draft.recordID,
            fileManager: fileManager
        ) ?? ""
        var diagnostics = NDSDataMutationPlanner.editabilityDiagnostics(
            catalog: catalog,
            recordID: draft.recordID,
            fileManager: fileManager
        )

        if let record, !isEligiblePlatinumTextLineRecord(record, profile: catalog.profile) {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_TEXT_LINES_PATH_BLOCKED",
                    message: "Only local Platinum source-tree res/text/**/*.txt rows support text line operations; BMG/message-bank files, JSON text rows, NARC/container rows, generated/reference rows, ROM rebuild/export, build/playtest execution, and binary paths remain blocked.",
                    span: record.sourceSpan
                )
            )
        }

        let beforeLines = splitTextLines(sourceText)
        let beforeLineCount = beforeLines.lines.count

        guard !draft.operations.isEmpty else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_TEXT_LINES_OPERATION_REQUIRED",
                    message: "At least one text line insert, delete, or reorder operation is required."
                )
            )
            let editDraft = NDSDataEditDraft(recordID: draft.recordID, editedText: sourceText)
            let editPlan = blockedEditPlan(catalog: catalog, draft: editDraft, diagnostics: diagnostics)
            return NDSDataTextLineOperationPlan(
                draft: draft,
                beforeLineCount: beforeLineCount,
                afterLineCount: beforeLineCount,
                diagnostics: editPlan.diagnostics,
                editPlan: editPlan
            )
        }

        var editedLines = beforeLines.lines
        if diagnostics.allSatisfy({ $0.severity != .error }) {
            diagnostics.append(contentsOf: applyOperations(draft.operations, to: &editedLines))
        }

        let operationErrors = diagnostics.filter { $0.severity == .error }
        let editedText = operationErrors.isEmpty
            ? renderTextLines(editedLines, hadTrailingNewline: beforeLines.hadTrailingNewline)
            : sourceText
        let editDraft = NDSDataEditDraft(recordID: draft.recordID, editedText: editedText)
        let editPlan = operationErrors.isEmpty
            ? NDSDataMutationPlanner.plan(catalog: catalog, draft: editDraft, fileManager: fileManager)
            : blockedEditPlan(catalog: catalog, draft: editDraft, diagnostics: diagnostics)
        let allDiagnostics = diagnostics + editPlan.diagnostics.filter { editDiagnostic in
            !diagnostics.contains(editDiagnostic)
        }

        return NDSDataTextLineOperationPlan(
            draft: draft,
            beforeLineCount: beforeLineCount,
            afterLineCount: operationErrors.isEmpty ? editedLines.count : beforeLineCount,
            diagnostics: allDiagnostics,
            editPlan: editPlan
        )
    }

    private static func isEligiblePlatinumTextLineRecord(_ record: NDSDataCatalogRecord, profile: GameProfile) -> Bool {
        guard profile == .pokeplatinum,
              record.domain == .text,
              record.role == .sourceTree,
              record.format == .text
        else {
            return false
        }
        let lower = record.relativePath.lowercased()
        return lower.hasPrefix("res/text/")
            && lower.hasSuffix(".txt")
            && !lower.dropFirst("res/text/".count).isEmpty
    }

    private static func applyOperations(
        _ operations: [NDSDataTextLineOperation],
        to lines: inout [String]
    ) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        for (operationIndex, operation) in operations.enumerated() {
            switch operation.kind {
            case .insert:
                guard let index = operation.index, let text = operation.text else {
                    diagnostics.append(invalidOperationDiagnostic(operationIndex: operationIndex, detail: "insert requires an index and text value."))
                    return diagnostics
                }
                guard !text.contains(where: { $0 == "\n" || $0 == "\r" }) else {
                    diagnostics.append(
                        Diagnostic(
                            severity: .error,
                            code: "NDS_DATA_TEXT_LINES_NEWLINE_BLOCKED",
                            message: "Text line insert operation \(operationIndex + 1) contains a newline; multiline text row operations remain blocked."
                        )
                    )
                    return diagnostics
                }
                guard (0...lines.count).contains(index) else {
                    diagnostics.append(rangeDiagnostic(operationIndex: operationIndex, indexDescription: "insert index \(index)", lineCount: lines.count, allowsEnd: true))
                    return diagnostics
                }
                lines.insert(text, at: index)

            case .delete:
                guard let index = operation.index else {
                    diagnostics.append(invalidOperationDiagnostic(operationIndex: operationIndex, detail: "delete requires an index."))
                    return diagnostics
                }
                guard lines.indices.contains(index) else {
                    diagnostics.append(rangeDiagnostic(operationIndex: operationIndex, indexDescription: "delete index \(index)", lineCount: lines.count, allowsEnd: false))
                    return diagnostics
                }
                lines.remove(at: index)

            case .reorder:
                guard let fromIndex = operation.fromIndex, let toIndex = operation.toIndex else {
                    diagnostics.append(invalidOperationDiagnostic(operationIndex: operationIndex, detail: "reorder requires from-index and to-index values."))
                    return diagnostics
                }
                guard lines.indices.contains(fromIndex) else {
                    diagnostics.append(rangeDiagnostic(operationIndex: operationIndex, indexDescription: "reorder source index \(fromIndex)", lineCount: lines.count, allowsEnd: false))
                    return diagnostics
                }
                let line = lines.remove(at: fromIndex)
                guard (0...lines.count).contains(toIndex) else {
                    diagnostics.append(rangeDiagnostic(operationIndex: operationIndex, indexDescription: "reorder destination index \(toIndex)", lineCount: lines.count, allowsEnd: true))
                    return diagnostics
                }
                lines.insert(line, at: toIndex)
            }
        }
        return diagnostics
    }

    private static func splitTextLines(_ text: String) -> (lines: [String], hadTrailingNewline: Bool) {
        let normalized = normalizeLineEndings(text)
        let hadTrailingNewline = normalized.hasSuffix("\n")
        var lines = normalized.components(separatedBy: "\n")
        if hadTrailingNewline {
            lines.removeLast()
        }
        if lines.count == 1, lines[0].isEmpty, normalized.isEmpty {
            lines.removeAll()
        }
        return (lines, hadTrailingNewline)
    }

    private static func renderTextLines(_ lines: [String], hadTrailingNewline: Bool) -> String {
        guard !lines.isEmpty else { return "" }
        let rendered = lines.joined(separator: "\n")
        return hadTrailingNewline ? rendered + "\n" : rendered
    }

    private static func invalidOperationDiagnostic(operationIndex: Int, detail: String) -> Diagnostic {
        Diagnostic(
            severity: .error,
            code: "NDS_DATA_TEXT_LINES_OPERATION_INVALID",
            message: "Text line operation \(operationIndex + 1) is invalid: \(detail)"
        )
    }

    private static func rangeDiagnostic(
        operationIndex: Int,
        indexDescription: String,
        lineCount: Int,
        allowsEnd: Bool
    ) -> Diagnostic {
        let validRange = allowsEnd ? "0...\(lineCount)" : "0..<\(lineCount)"
        return Diagnostic(
            severity: .error,
            code: "NDS_DATA_TEXT_LINES_INDEX_OUT_OF_RANGE",
            message: "Text line operation \(operationIndex + 1) has \(indexDescription), but the valid range at that step is \(validRange)."
        )
    }

    private static func blockedEditPlan(
        catalog: ProjectNDSDataCatalog,
        draft: NDSDataEditDraft,
        diagnostics: [Diagnostic]
    ) -> NDSDataEditPlan {
        let mutationPlan = MutationPlan(
            title: "NDS text line operations blocked",
            summary: "No NDS text line source files are applyable until operation diagnostics are resolved.",
            diagnostics: diagnostics,
            requiresExplicitApply: true
        )
        return NDSDataEditPlan(
            rootPath: catalog.root.path,
            recordID: draft.recordID,
            draft: draft,
            changes: [],
            diagnostics: diagnostics,
            mutationPlan: mutationPlan,
            backupRelativeRoot: ".pokemonhackstudio/backups/text-line-operations-blocked"
        )
    }

    private static func normalizeLineEndings(_ text: String) -> String {
        text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
    }
}

public enum NDSDataItemCSVRowOperationPlanner {
    private struct ParsedCSVTable {
        let headerLine: String
        let rowLines: [String]
        let headerColumnCount: Int
        let hadTrailingNewline: Bool
        let diagnostics: [Diagnostic]
    }

    private struct ParsedCSVLine {
        let cells: [String]
        let diagnostics: [Diagnostic]
    }

    public static func plan(
        catalog: ProjectNDSDataCatalog,
        draft: NDSDataItemCSVRowOperationDraft,
        fileManager: FileManager = .default
    ) -> NDSDataItemCSVRowOperationPlan {
        let record = catalog.records.first(where: { $0.id == draft.recordID })
        let sourceText = NDSDataMutationPlanner.sourceText(
            catalog: catalog,
            recordID: draft.recordID,
            fileManager: fileManager
        ) ?? ""
        var diagnostics = NDSDataMutationPlanner.editabilityDiagnostics(
            catalog: catalog,
            recordID: draft.recordID,
            fileManager: fileManager
        )

        if let record, !isEligibleHeartGoldSoulSilverItemCSVRecord(record, profile: catalog.profile) {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_ITEM_CSV_ROWS_PATH_BLOCKED",
                    message: "Only local HeartGold/SoulSilver source-tree files/itemtool/itemdata/*.csv item rows support CSV row operations; nested CSV, JSON item rows, binary rows, containers, generated/reference rows, BMG/message banks, ROM rebuild/export, build/playtest execution, and binary paths remain blocked.",
                    span: record.sourceSpan
                )
            )
        }

        let parsed = parseCSVTable(sourceText: sourceText, record: record)
        diagnostics.append(contentsOf: parsed.diagnostics)
        let beforeRowCount = parsed.rowLines.count

        guard !draft.operations.isEmpty else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_ITEM_CSV_ROWS_OPERATION_REQUIRED",
                    message: "At least one item CSV row insert, delete, or reorder operation is required."
                )
            )
            let editDraft = NDSDataEditDraft(recordID: draft.recordID, editedText: sourceText)
            let editPlan = blockedEditPlan(catalog: catalog, draft: editDraft, diagnostics: diagnostics)
            return NDSDataItemCSVRowOperationPlan(
                draft: draft,
                beforeRowCount: beforeRowCount,
                afterRowCount: beforeRowCount,
                diagnostics: editPlan.diagnostics,
                editPlan: editPlan
            )
        }

        var editedRows = parsed.rowLines
        if diagnostics.allSatisfy({ $0.severity != .error }) {
            diagnostics.append(
                contentsOf: applyOperations(
                    draft.operations,
                    to: &editedRows,
                    headerColumnCount: parsed.headerColumnCount,
                    record: record
                )
            )
        }

        let hasErrors = diagnostics.contains { $0.severity == .error }
        let editedText = hasErrors
            ? sourceText
            : renderCSVTable(headerLine: parsed.headerLine, rowLines: editedRows, hadTrailingNewline: parsed.hadTrailingNewline)
        let editDraft = NDSDataEditDraft(recordID: draft.recordID, editedText: editedText)
        let editPlan = hasErrors
            ? blockedEditPlan(catalog: catalog, draft: editDraft, diagnostics: diagnostics)
            : NDSDataMutationPlanner.plan(catalog: catalog, draft: editDraft, fileManager: fileManager)
        let allDiagnostics = diagnostics + editPlan.diagnostics.filter { editDiagnostic in
            !diagnostics.contains(editDiagnostic)
        }

        return NDSDataItemCSVRowOperationPlan(
            draft: draft,
            beforeRowCount: beforeRowCount,
            afterRowCount: hasErrors ? beforeRowCount : editedRows.count,
            diagnostics: allDiagnostics,
            editPlan: editPlan
        )
    }

    private static func isEligibleHeartGoldSoulSilverItemCSVRecord(_ record: NDSDataCatalogRecord, profile: GameProfile) -> Bool {
        guard profile == .pokeheartgold,
              record.domain == .items,
              record.role == .sourceTree,
              record.format == .csv
        else {
            return false
        }
        let prefix = "files/itemtool/itemdata/"
        let lower = record.relativePath.lowercased()
        guard lower.hasPrefix(prefix), lower.hasSuffix(".csv") else { return false }
        let remainder = lower.dropFirst(prefix.count)
        return !remainder.isEmpty && !remainder.contains("/")
    }

    private static func parseCSVTable(
        sourceText: String,
        record: NDSDataCatalogRecord?
    ) -> ParsedCSVTable {
        let normalized = normalizeLineEndings(sourceText)
        let hadTrailingNewline = normalized.hasSuffix("\n")
        var lines = normalized.components(separatedBy: "\n")
        if hadTrailingNewline {
            lines.removeLast()
        }

        var diagnostics: [Diagnostic] = []
        guard let headerLine = lines.first else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_ITEM_CSV_ROWS_HEADER_REQUIRED",
                    message: "HeartGold/SoulSilver item CSV row operations require a nonempty header row.",
                    span: record?.sourceSpan
                )
            )
            return ParsedCSVTable(headerLine: "", rowLines: [], headerColumnCount: 0, hadTrailingNewline: hadTrailingNewline, diagnostics: diagnostics)
        }

        let header = parseCSVLine(headerLine, record: record, rowDescription: "header", lineNumber: 1)
        diagnostics.append(contentsOf: header.diagnostics)
        var seenHeaders = Set<String>()
        var duplicateHeaders = Set<String>()
        for cell in header.cells {
            let name = cell.trimmingCharacters(in: .whitespacesAndNewlines)
            if name.isEmpty {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "NDS_DATA_ITEM_CSV_ROWS_HEADER_EMPTY",
                        message: "HeartGold/SoulSilver item CSV row operations require nonempty header names.",
                        span: span(record: record, line: 1)
                    )
                )
            } else if !seenHeaders.insert(name).inserted {
                duplicateHeaders.insert(name)
            }
        }
        for headerName in duplicateHeaders.sorted() {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_ITEM_CSV_ROWS_HEADER_DUPLICATE",
                    message: "HeartGold/SoulSilver item CSV header \(headerName) appears more than once; duplicate headers must be resolved before row operations are planned.",
                    span: record?.sourceSpan
                )
            )
        }
        guard !header.cells.isEmpty else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_ITEM_CSV_ROWS_HEADER_REQUIRED",
                    message: "HeartGold/SoulSilver item CSV row operations require at least one header column.",
                    span: record?.sourceSpan
                )
            )
            return ParsedCSVTable(headerLine: headerLine, rowLines: Array(lines.dropFirst()), headerColumnCount: 0, hadTrailingNewline: hadTrailingNewline, diagnostics: diagnostics)
        }

        let rowLines = Array(lines.dropFirst())
        for (rowIndex, rowLine) in rowLines.enumerated() {
            let parsed = parseCSVLine(rowLine, record: record, rowDescription: "row \(rowIndex + 1)", lineNumber: rowIndex + 2)
            diagnostics.append(contentsOf: parsed.diagnostics)
            if parsed.cells.count != header.cells.count {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "NDS_DATA_ITEM_CSV_ROWS_ROW_BAD_SHAPE",
                        message: "HeartGold/SoulSilver item CSV row \(rowIndex + 1) has \(parsed.cells.count) cell(s), but the header has \(header.cells.count); fix the table before row operations are planned.",
                        span: span(record: record, line: rowIndex + 2)
                    )
                )
            }
        }

        return ParsedCSVTable(
            headerLine: headerLine,
            rowLines: rowLines,
            headerColumnCount: header.cells.count,
            hadTrailingNewline: hadTrailingNewline,
            diagnostics: diagnostics
        )
    }

    private static func applyOperations(
        _ operations: [NDSDataItemCSVRowOperation],
        to rows: inout [String],
        headerColumnCount: Int,
        record: NDSDataCatalogRecord?
    ) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        for (operationIndex, operation) in operations.enumerated() {
            switch operation.kind {
            case .insert:
                guard let index = operation.index, let rowText = operation.rowText else {
                    diagnostics.append(invalidOperationDiagnostic(operationIndex: operationIndex, detail: "insert requires an index and CSV row text."))
                    return diagnostics
                }
                guard !rowText.contains(where: { $0 == "\n" || $0 == "\r" }) else {
                    diagnostics.append(
                        Diagnostic(
                            severity: .error,
                            code: "NDS_DATA_ITEM_CSV_ROWS_NEWLINE_BLOCKED",
                            message: "Item CSV row insert operation \(operationIndex + 1) contains a newline; multiline CSV row operations remain blocked."
                        )
                    )
                    return diagnostics
                }
                guard (0...rows.count).contains(index) else {
                    diagnostics.append(rangeDiagnostic(operationIndex: operationIndex, indexDescription: "insert index \(index)", rowCount: rows.count, allowsEnd: true))
                    return diagnostics
                }
                let parsed = parseCSVLine(rowText, record: record, rowDescription: "insert row", lineNumber: nil)
                diagnostics.append(contentsOf: parsed.diagnostics)
                guard parsed.diagnostics.allSatisfy({ $0.severity != .error }) else {
                    return diagnostics
                }
                guard parsed.cells.count == headerColumnCount else {
                    diagnostics.append(
                        Diagnostic(
                            severity: .error,
                            code: "NDS_DATA_ITEM_CSV_ROWS_INSERT_ROW_BAD_SHAPE",
                            message: "Item CSV row insert operation \(operationIndex + 1) has \(parsed.cells.count) cell(s), but the header has \(headerColumnCount)."
                        )
                    )
                    return diagnostics
                }
                rows.insert(rowText, at: index)

            case .delete:
                guard let index = operation.index else {
                    diagnostics.append(invalidOperationDiagnostic(operationIndex: operationIndex, detail: "delete requires an index."))
                    return diagnostics
                }
                guard rows.indices.contains(index) else {
                    diagnostics.append(rangeDiagnostic(operationIndex: operationIndex, indexDescription: "delete index \(index)", rowCount: rows.count, allowsEnd: false))
                    return diagnostics
                }
                rows.remove(at: index)

            case .reorder:
                guard let fromIndex = operation.fromIndex, let toIndex = operation.toIndex else {
                    diagnostics.append(invalidOperationDiagnostic(operationIndex: operationIndex, detail: "reorder requires from-index and to-index values."))
                    return diagnostics
                }
                guard rows.indices.contains(fromIndex) else {
                    diagnostics.append(rangeDiagnostic(operationIndex: operationIndex, indexDescription: "reorder source index \(fromIndex)", rowCount: rows.count, allowsEnd: false))
                    return diagnostics
                }
                let row = rows.remove(at: fromIndex)
                guard (0...rows.count).contains(toIndex) else {
                    diagnostics.append(rangeDiagnostic(operationIndex: operationIndex, indexDescription: "reorder destination index \(toIndex)", rowCount: rows.count, allowsEnd: true))
                    return diagnostics
                }
                rows.insert(row, at: toIndex)
            }
        }
        return diagnostics
    }

    private static func parseCSVLine(
        _ line: String,
        record: NDSDataCatalogRecord?,
        rowDescription: String,
        lineNumber: Int?
    ) -> ParsedCSVLine {
        var cells: [String] = []
        var diagnostics: [Diagnostic] = []
        var index = line.startIndex
        while true {
            if index < line.endIndex, line[index] == "\"" {
                let quoted = parseQuotedCSVCell(line, start: index, record: record, rowDescription: rowDescription, lineNumber: lineNumber)
                diagnostics.append(contentsOf: quoted.diagnostics)
                if let cell = quoted.cell {
                    cells.append(cell)
                }
                index = quoted.end
            } else {
                let cellStart = index
                while index < line.endIndex, line[index] != "," {
                    index = line.index(after: index)
                }
                cells.append(String(line[cellStart..<index]))
            }

            if index < line.endIndex, line[index] == "," {
                index = line.index(after: index)
                continue
            }
            break
        }
        return ParsedCSVLine(cells: cells, diagnostics: diagnostics)
    }

    private static func parseQuotedCSVCell(
        _ line: String,
        start: String.Index,
        record: NDSDataCatalogRecord?,
        rowDescription: String,
        lineNumber: Int?
    ) -> (cell: String?, end: String.Index, diagnostics: [Diagnostic]) {
        var diagnostics: [Diagnostic] = []
        var value = ""
        var index = line.index(after: start)
        while index < line.endIndex {
            if line[index] == "\"" {
                let next = line.index(after: index)
                if next < line.endIndex, line[next] == "\"" {
                    value.append("\"")
                    index = line.index(after: next)
                    continue
                }

                var cellEnd = next
                while cellEnd < line.endIndex, line[cellEnd] != "," {
                    if !line[cellEnd].isWhitespace {
                        diagnostics.append(
                            Diagnostic(
                                severity: .error,
                                code: "NDS_DATA_ITEM_CSV_ROWS_QUOTED_TRAILING_TEXT",
                                message: "HeartGold/SoulSilver item CSV \(rowDescription) has non-whitespace text after a quoted cell; this row remains blocked.",
                                span: span(record: record, line: lineNumber)
                            )
                        )
                    }
                    cellEnd = line.index(after: cellEnd)
                }
                return (value, cellEnd, diagnostics)
            }
            value.append(line[index])
            index = line.index(after: index)
        }

        diagnostics.append(
            Diagnostic(
                severity: .error,
                code: "NDS_DATA_ITEM_CSV_ROWS_QUOTE_UNCLOSED",
                message: "HeartGold/SoulSilver item CSV \(rowDescription) has an unterminated quoted cell; multiline CSV cells remain blocked.",
                span: span(record: record, line: lineNumber)
            )
        )
        return (nil, line.endIndex, diagnostics)
    }

    private static func renderCSVTable(
        headerLine: String,
        rowLines: [String],
        hadTrailingNewline: Bool
    ) -> String {
        let rendered = ([headerLine] + rowLines).joined(separator: "\n")
        return hadTrailingNewline ? rendered + "\n" : rendered
    }

    private static func invalidOperationDiagnostic(operationIndex: Int, detail: String) -> Diagnostic {
        Diagnostic(
            severity: .error,
            code: "NDS_DATA_ITEM_CSV_ROWS_OPERATION_INVALID",
            message: "Item CSV row operation \(operationIndex + 1) is invalid: \(detail)"
        )
    }

    private static func rangeDiagnostic(
        operationIndex: Int,
        indexDescription: String,
        rowCount: Int,
        allowsEnd: Bool
    ) -> Diagnostic {
        let validRange = allowsEnd ? "0...\(rowCount)" : "0..<\(rowCount)"
        return Diagnostic(
            severity: .error,
            code: "NDS_DATA_ITEM_CSV_ROWS_INDEX_OUT_OF_RANGE",
            message: "Item CSV row operation \(operationIndex + 1) has \(indexDescription), but the valid data-row range at that step is \(validRange)."
        )
    }

    private static func blockedEditPlan(
        catalog: ProjectNDSDataCatalog,
        draft: NDSDataEditDraft,
        diagnostics: [Diagnostic]
    ) -> NDSDataEditPlan {
        let mutationPlan = MutationPlan(
            title: "NDS item CSV row operations blocked",
            summary: "No NDS item CSV source files are applyable until operation diagnostics are resolved.",
            diagnostics: diagnostics,
            requiresExplicitApply: true
        )
        return NDSDataEditPlan(
            rootPath: catalog.root.path,
            recordID: draft.recordID,
            draft: draft,
            changes: [],
            diagnostics: diagnostics,
            mutationPlan: mutationPlan,
            backupRelativeRoot: ".pokemonhackstudio/backups/item-csv-row-operations-blocked"
        )
    }

    private static func span(record: NDSDataCatalogRecord?, line: Int?) -> SourceSpan? {
        guard let record else { return nil }
        guard let line else { return record.sourceSpan }
        return SourceSpan(relativePath: record.relativePath, startLine: line)
    }

    private static func normalizeLineEndings(_ text: String) -> String {
        text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
    }
}

public enum NDSDataEncounterJSONRowOperationPlanner {
    private struct JSONStringToken {
        let value: String
        let end: String.Index
    }

    private struct ParsedObjectRow {
        let text: String
        let keySet: Set<String>
        let diagnostics: [Diagnostic]
    }

    private struct ParsedEncounterArray {
        let valueRange: Range<String.Index>?
        let rowTexts: [String]
        let rowKeySet: Set<String>
        let diagnostics: [Diagnostic]
    }

    public static func plan(
        catalog: ProjectNDSDataCatalog,
        draft: NDSDataEncounterJSONRowOperationDraft,
        fileManager: FileManager = .default
    ) -> NDSDataEncounterJSONRowOperationPlan {
        let record = catalog.records.first(where: { $0.id == draft.recordID })
        let sourceText = NDSDataMutationPlanner.sourceText(
            catalog: catalog,
            recordID: draft.recordID,
            fileManager: fileManager
        ) ?? ""
        var diagnostics = NDSDataMutationPlanner.editabilityDiagnostics(
            catalog: catalog,
            recordID: draft.recordID,
            fileManager: fileManager
        )
        let arrayKey = draft.arrayKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if arrayKey.isEmpty {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_ENCOUNTER_JSON_ROWS_ARRAY_REQUIRED",
                    message: "Platinum encounter JSON row operations require a top-level array key."
                )
            )
        }

        if let record, !isEligiblePlatinumEncounterJSONRecord(record, profile: catalog.profile) {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_ENCOUNTER_JSON_ROWS_PATH_BLOCKED",
                    message: "Only local Platinum source-tree encounters:res/field/encounters/*.json object-array rows support encounter JSON row operations; scalar arrays, nested directories, non-JSON rows, HGSS/DP rows, containers, generated/reference rows, ROM rebuild/export/playtest, nested schema reshaping, broad schemas, and binary writes remain blocked.",
                    span: record.sourceSpan
                )
            )
        }

        let parsed = diagnostics.contains { $0.severity == .error }
            ? ParsedEncounterArray(valueRange: nil, rowTexts: [], rowKeySet: [], diagnostics: [])
            : parseEncounterArray(sourceText: sourceText, arrayKey: arrayKey, record: record)
        diagnostics.append(contentsOf: parsed.diagnostics)
        let beforeRowCount = parsed.rowTexts.count

        guard !draft.operations.isEmpty else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_ENCOUNTER_JSON_ROWS_OPERATION_REQUIRED",
                    message: "At least one encounter JSON row insert, delete, or reorder operation is required."
                )
            )
            let editDraft = NDSDataEditDraft(recordID: draft.recordID, editedText: sourceText)
            let editPlan = blockedEditPlan(catalog: catalog, draft: editDraft, diagnostics: diagnostics)
            return NDSDataEncounterJSONRowOperationPlan(
                draft: draft,
                beforeRowCount: beforeRowCount,
                afterRowCount: beforeRowCount,
                diagnostics: editPlan.diagnostics,
                editPlan: editPlan
            )
        }

        var editedRows = parsed.rowTexts
        if diagnostics.allSatisfy({ $0.severity != .error }) {
            diagnostics.append(
                contentsOf: applyOperations(
                    draft.operations,
                    to: &editedRows,
                    rowKeySet: parsed.rowKeySet,
                    record: record
                )
            )
            if editedRows.isEmpty {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "NDS_DATA_ENCOUNTER_JSON_ROWS_EMPTY_BLOCKED",
                        message: "Encounter JSON row operations must preserve at least one existing object row so the row shape remains source-backed.",
                        span: record?.sourceSpan
                    )
                )
            }
        }

        let hasErrors = diagnostics.contains { $0.severity == .error }
        let editedText: String
        if hasErrors {
            editedText = sourceText
        } else if let valueRange = parsed.valueRange {
            editedText = renderSourceReplacingArray(sourceText, arrayRange: valueRange, rowTexts: editedRows)
        } else {
            editedText = sourceText
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_ENCOUNTER_JSON_ROWS_ARRAY_MISSING",
                    message: "Encounter JSON array \(arrayKey) could not be located for row operations.",
                    span: record?.sourceSpan
                )
            )
        }

        let editDraft = NDSDataEditDraft(recordID: draft.recordID, editedText: editedText)
        let finalHasErrors = diagnostics.contains { $0.severity == .error }
        let editPlan = finalHasErrors
            ? blockedEditPlan(catalog: catalog, draft: editDraft, diagnostics: diagnostics)
            : NDSDataMutationPlanner.plan(catalog: catalog, draft: editDraft, fileManager: fileManager)
        let allDiagnostics = diagnostics + editPlan.diagnostics.filter { editDiagnostic in
            !diagnostics.contains(editDiagnostic)
        }

        return NDSDataEncounterJSONRowOperationPlan(
            draft: draft,
            beforeRowCount: beforeRowCount,
            afterRowCount: finalHasErrors ? beforeRowCount : editedRows.count,
            diagnostics: allDiagnostics,
            editPlan: editPlan
        )
    }

    private static func isEligiblePlatinumEncounterJSONRecord(_ record: NDSDataCatalogRecord, profile: GameProfile) -> Bool {
        guard profile == .pokeplatinum,
              record.domain == .encounters,
              record.role == .sourceTree,
              record.format == .json
        else {
            return false
        }
        let prefix = "res/field/encounters/"
        let lower = record.relativePath.lowercased()
        guard lower.hasPrefix(prefix), lower.hasSuffix(".json") else { return false }
        let remainder = lower.dropFirst(prefix.count)
        return !remainder.isEmpty && !remainder.contains("/")
    }

    private static func parseEncounterArray(
        sourceText: String,
        arrayKey: String,
        record: NDSDataCatalogRecord?
    ) -> ParsedEncounterArray {
        var diagnostics: [Diagnostic] = []
        let trimmed = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{") else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_ENCOUNTER_JSON_ROWS_OBJECT_REQUIRED",
                    message: "Platinum encounter JSON row operations require a top-level JSON object.",
                    span: record?.sourceSpan
                )
            )
            return ParsedEncounterArray(valueRange: nil, rowTexts: [], rowKeySet: [], diagnostics: diagnostics)
        }
        if let data = sourceText.data(using: .utf8),
           (try? JSONSerialization.jsonObject(with: data)) == nil {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_ENCOUNTER_JSON_ROWS_JSON_MALFORMED",
                    message: "Platinum encounter JSON must parse before row operations are planned.",
                    span: record?.sourceSpan
                )
            )
            return ParsedEncounterArray(valueRange: nil, rowTexts: [], rowKeySet: [], diagnostics: diagnostics)
        }

        guard let valueRange = topLevelJSONValueRange(sourceText, key: arrayKey, record: record, diagnostics: &diagnostics) else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_ENCOUNTER_JSON_ROWS_ARRAY_MISSING",
                    message: "Platinum encounter JSON row operations require an existing top-level array named \(arrayKey).",
                    span: record?.sourceSpan
                )
            )
            return ParsedEncounterArray(valueRange: nil, rowTexts: [], rowKeySet: [], diagnostics: diagnostics)
        }
        guard sourceText[valueRange.lowerBound] == "[",
              let arrayEnd = matchingEnd(sourceText, start: valueRange.lowerBound, open: "[", close: "]")
        else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_ENCOUNTER_JSON_ROWS_ARRAY_REQUIRED",
                    message: "Platinum encounter JSON field \(arrayKey) is not an array; nested schema reshaping remains blocked.",
                    span: span(record: record, line: lineNumber(in: sourceText, before: valueRange.lowerBound))
                )
            )
            return ParsedEncounterArray(valueRange: valueRange, rowTexts: [], rowKeySet: [], diagnostics: diagnostics)
        }

        var rowTexts: [String] = []
        var rowKeySet: Set<String>?
        var cursor = sourceText.index(after: valueRange.lowerBound)
        let close = sourceText.index(before: arrayEnd)
        while cursor < close {
            skipWhitespace(sourceText, index: &cursor)
            guard cursor < close else { break }
            if sourceText[cursor] == "," {
                cursor = sourceText.index(after: cursor)
                continue
            }
            if sourceText[cursor] == "]" {
                break
            }
            guard sourceText[cursor] == "{",
                  let rowEnd = matchingEnd(sourceText, start: cursor, open: "{", close: "}")
            else {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "NDS_DATA_ENCOUNTER_JSON_ROWS_OBJECT_ROWS_REQUIRED",
                        message: "Encounter JSON array \(arrayKey) contains scalar or non-object rows; scalar arrays and nested row shapes remain blocked.",
                        span: span(record: record, line: lineNumber(in: sourceText, before: cursor))
                    )
                )
                skipJSONValue(sourceText, index: &cursor)
                continue
            }

            let rowText = String(sourceText[cursor..<rowEnd])
            let parsedRow = parseObjectRow(rowText, record: record, rowDescription: "\(arrayKey) row \(rowTexts.count + 1)", line: lineNumber(in: sourceText, before: cursor))
            diagnostics.append(contentsOf: parsedRow.diagnostics)
            if let existingKeySet = rowKeySet {
                if parsedRow.keySet != existingKeySet {
                    diagnostics.append(
                        Diagnostic(
                            severity: .error,
                            code: "NDS_DATA_ENCOUNTER_JSON_ROWS_ROW_SHAPE_MISMATCH",
                            message: "Encounter JSON array \(arrayKey) has object rows with different scalar key sets; row operations require a stable existing row shape.",
                            span: span(record: record, line: lineNumber(in: sourceText, before: cursor))
                        )
                    )
                }
            } else {
                rowKeySet = parsedRow.keySet
            }
            rowTexts.append(rowText)
            cursor = rowEnd
            skipWhitespace(sourceText, index: &cursor)
            if cursor < close, sourceText[cursor] == "," {
                cursor = sourceText.index(after: cursor)
            }
        }

        if rowTexts.isEmpty, diagnostics.allSatisfy({ $0.severity != .error }) {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_ENCOUNTER_JSON_ROWS_EMPTY_BLOCKED",
                    message: "Encounter JSON array \(arrayKey) has no object rows to use as a source-backed row template.",
                    span: record?.sourceSpan
                )
            )
        }
        if rowKeySet?.isEmpty == true {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_ENCOUNTER_JSON_ROWS_EMPTY_OBJECT_BLOCKED",
                    message: "Encounter JSON array \(arrayKey) uses empty object rows; template-less row operations remain blocked.",
                    span: record?.sourceSpan
                )
            )
        }

        return ParsedEncounterArray(
            valueRange: valueRange,
            rowTexts: rowTexts,
            rowKeySet: rowKeySet ?? [],
            diagnostics: diagnostics
        )
    }

    private static func applyOperations(
        _ operations: [NDSDataEncounterJSONRowOperation],
        to rows: inout [String],
        rowKeySet: Set<String>,
        record: NDSDataCatalogRecord?
    ) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        for (operationIndex, operation) in operations.enumerated() {
            switch operation.kind {
            case .insert:
                guard let index = operation.index, let rowText = operation.rowText else {
                    diagnostics.append(invalidOperationDiagnostic(operationIndex: operationIndex, detail: "insert requires an index and JSON row text."))
                    return diagnostics
                }
                guard !rowText.contains(where: { $0 == "\n" || $0 == "\r" }) else {
                    diagnostics.append(
                        Diagnostic(
                            severity: .error,
                            code: "NDS_DATA_ENCOUNTER_JSON_ROWS_NEWLINE_BLOCKED",
                            message: "Encounter JSON row insert operation \(operationIndex + 1) contains a newline; multiline row inserts remain blocked."
                        )
                    )
                    return diagnostics
                }
                guard (0...rows.count).contains(index) else {
                    diagnostics.append(rangeDiagnostic(operationIndex: operationIndex, indexDescription: "insert index \(index)", rowCount: rows.count, allowsEnd: true))
                    return diagnostics
                }
                let parsedRow = parseObjectRow(rowText, record: record, rowDescription: "insert row", line: nil)
                diagnostics.append(contentsOf: parsedRow.diagnostics)
                guard parsedRow.diagnostics.allSatisfy({ $0.severity != .error }) else {
                    return diagnostics
                }
                guard parsedRow.keySet == rowKeySet else {
                    diagnostics.append(
                        Diagnostic(
                            severity: .error,
                            code: "NDS_DATA_ENCOUNTER_JSON_ROWS_INSERT_ROW_BAD_SHAPE",
                            message: "Encounter JSON row insert operation \(operationIndex + 1) must use the same scalar key set as the existing rows."
                        )
                    )
                    return diagnostics
                }
                rows.insert(rowText.trimmingCharacters(in: .whitespacesAndNewlines), at: index)

            case .delete:
                guard let index = operation.index else {
                    diagnostics.append(invalidOperationDiagnostic(operationIndex: operationIndex, detail: "delete requires an index."))
                    return diagnostics
                }
                guard rows.indices.contains(index) else {
                    diagnostics.append(rangeDiagnostic(operationIndex: operationIndex, indexDescription: "delete index \(index)", rowCount: rows.count, allowsEnd: false))
                    return diagnostics
                }
                rows.remove(at: index)

            case .reorder:
                guard let fromIndex = operation.fromIndex, let toIndex = operation.toIndex else {
                    diagnostics.append(invalidOperationDiagnostic(operationIndex: operationIndex, detail: "reorder requires from-index and to-index values."))
                    return diagnostics
                }
                guard rows.indices.contains(fromIndex) else {
                    diagnostics.append(rangeDiagnostic(operationIndex: operationIndex, indexDescription: "reorder source index \(fromIndex)", rowCount: rows.count, allowsEnd: false))
                    return diagnostics
                }
                let row = rows.remove(at: fromIndex)
                guard (0...rows.count).contains(toIndex) else {
                    diagnostics.append(rangeDiagnostic(operationIndex: operationIndex, indexDescription: "reorder destination index \(toIndex)", rowCount: rows.count, allowsEnd: true))
                    return diagnostics
                }
                rows.insert(row, at: toIndex)
            }
        }
        return diagnostics
    }

    private static func parseObjectRow(
        _ rowText: String,
        record: NDSDataCatalogRecord?,
        rowDescription: String,
        line: Int?
    ) -> ParsedObjectRow {
        var diagnostics: [Diagnostic] = []
        let trimmed = rowText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{"),
              trimmed.hasSuffix("}")
        else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_ENCOUNTER_JSON_ROWS_ROW_OBJECT_REQUIRED",
                    message: "Encounter JSON \(rowDescription) must be a JSON object.",
                    span: span(record: record, line: line)
                )
            )
            return ParsedObjectRow(text: trimmed, keySet: [], diagnostics: diagnostics)
        }
        guard let data = trimmed.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) is [String: Any]
        else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_ENCOUNTER_JSON_ROWS_ROW_MALFORMED",
                    message: "Encounter JSON \(rowDescription) must be parseable before row operations are planned.",
                    span: span(record: record, line: line)
                )
            )
            return ParsedObjectRow(text: trimmed, keySet: [], diagnostics: diagnostics)
        }

        var keys: [String] = []
        var seenKeys = Set<String>()
        var duplicateKeys = Set<String>()
        var cursor = trimmed.startIndex
        guard let objectEnd = matchingEnd(trimmed, start: cursor, open: "{", close: "}") else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_ENCOUNTER_JSON_ROWS_ROW_MALFORMED",
                    message: "Encounter JSON \(rowDescription) must be a complete JSON object.",
                    span: span(record: record, line: line)
                )
            )
            return ParsedObjectRow(text: trimmed, keySet: [], diagnostics: diagnostics)
        }
        cursor = trimmed.index(after: cursor)
        let close = trimmed.index(before: objectEnd)
        while cursor < close {
            skipWhitespaceAndCommas(trimmed, index: &cursor)
            guard cursor < close else { break }
            guard trimmed[cursor] == "\"", let keyToken = parseJSONStringToken(trimmed, start: cursor) else {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "NDS_DATA_ENCOUNTER_JSON_ROWS_ROW_MALFORMED",
                        message: "Encounter JSON \(rowDescription) has an invalid object key.",
                        span: span(record: record, line: line)
                    )
                )
                return ParsedObjectRow(text: trimmed, keySet: Set(keys), diagnostics: diagnostics)
            }
            cursor = keyToken.end
            if !seenKeys.insert(keyToken.value).inserted {
                duplicateKeys.insert(keyToken.value)
            }
            keys.append(keyToken.value)
            skipWhitespace(trimmed, index: &cursor)
            guard cursor < close, trimmed[cursor] == ":" else {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "NDS_DATA_ENCOUNTER_JSON_ROWS_ROW_MALFORMED",
                        message: "Encounter JSON \(rowDescription) has an invalid object separator.",
                        span: span(record: record, line: line)
                    )
                )
                return ParsedObjectRow(text: trimmed, keySet: Set(keys), diagnostics: diagnostics)
            }
            cursor = trimmed.index(after: cursor)
            skipWhitespace(trimmed, index: &cursor)
            guard cursor < close else {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "NDS_DATA_ENCOUNTER_JSON_ROWS_ROW_MALFORMED",
                        message: "Encounter JSON \(rowDescription) has a missing scalar value.",
                        span: span(record: record, line: line)
                    )
                )
                return ParsedObjectRow(text: trimmed, keySet: Set(keys), diagnostics: diagnostics)
            }
            if trimmed[cursor] == "{" || trimmed[cursor] == "[" {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "NDS_DATA_ENCOUNTER_JSON_ROWS_NESTED_VALUE_BLOCKED",
                        message: "Encounter JSON \(rowDescription) contains nested value \(keyToken.value); nested schema reshaping remains blocked.",
                        span: span(record: record, line: line)
                    )
                )
                skipJSONValue(trimmed, index: &cursor)
            } else if let scalarEnd = jsonScalarEnd(trimmed, start: cursor) {
                cursor = scalarEnd
            } else {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "NDS_DATA_ENCOUNTER_JSON_ROWS_ROW_VALUE_INVALID",
                        message: "Encounter JSON \(rowDescription) contains an invalid scalar value for \(keyToken.value).",
                        span: span(record: record, line: line)
                    )
                )
                return ParsedObjectRow(text: trimmed, keySet: Set(keys), diagnostics: diagnostics)
            }
        }
        for key in duplicateKeys.sorted() {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_ENCOUNTER_JSON_ROWS_KEY_DUPLICATE",
                    message: "Encounter JSON \(rowDescription) contains duplicate key \(key); duplicate keys must be resolved before row operations are planned.",
                    span: span(record: record, line: line)
                )
            )
        }
        return ParsedObjectRow(text: trimmed, keySet: Set(keys), diagnostics: diagnostics)
    }

    private static func topLevelJSONValueRange(
        _ sourceText: String,
        key targetKey: String,
        record: NDSDataCatalogRecord?,
        diagnostics: inout [Diagnostic]
    ) -> Range<String.Index>? {
        var index = sourceText.startIndex
        guard let objectStart = sourceText[index...].firstIndex(of: "{") else { return nil }
        guard let objectEnd = matchingEnd(sourceText, start: objectStart, open: "{", close: "}") else { return nil }
        index = sourceText.index(after: objectStart)
        let close = sourceText.index(before: objectEnd)
        var seenKeys = Set<String>()
        var duplicateKeys = Set<String>()
        var targetRange: Range<String.Index>?

        while index < close {
            skipWhitespaceAndCommas(sourceText, index: &index)
            guard index < close else { break }
            guard sourceText[index] == "\"", let keyToken = parseJSONStringToken(sourceText, start: index) else {
                skipJSONValue(sourceText, index: &index)
                continue
            }
            index = keyToken.end
            if !seenKeys.insert(keyToken.value).inserted {
                duplicateKeys.insert(keyToken.value)
            }
            skipWhitespace(sourceText, index: &index)
            guard index < close, sourceText[index] == ":" else { continue }
            index = sourceText.index(after: index)
            skipWhitespace(sourceText, index: &index)
            let valueStart = index
            skipJSONValue(sourceText, index: &index)
            let valueEnd = trimTrailingWhitespace(sourceText, start: valueStart, end: index)
            if keyToken.value == targetKey, targetRange == nil {
                targetRange = valueStart..<valueEnd
            }
        }

        for key in duplicateKeys.sorted() {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "NDS_DATA_ENCOUNTER_JSON_ROWS_JSON_KEY_DUPLICATE",
                    message: "Platinum encounter JSON field \(key) appears more than once; duplicate source keys must be resolved before row operations are planned.",
                    span: record?.sourceSpan
                )
            )
        }
        return targetRange
    }

    private static func renderSourceReplacingArray(
        _ sourceText: String,
        arrayRange: Range<String.Index>,
        rowTexts: [String]
    ) -> String {
        var editedText = sourceText
        editedText.replaceSubrange(arrayRange, with: "[\(rowTexts.joined(separator: ","))]")
        return editedText
    }

    private static func invalidOperationDiagnostic(operationIndex: Int, detail: String) -> Diagnostic {
        Diagnostic(
            severity: .error,
            code: "NDS_DATA_ENCOUNTER_JSON_ROWS_OPERATION_INVALID",
            message: "Encounter JSON row operation \(operationIndex + 1) is invalid: \(detail)"
        )
    }

    private static func rangeDiagnostic(
        operationIndex: Int,
        indexDescription: String,
        rowCount: Int,
        allowsEnd: Bool
    ) -> Diagnostic {
        let validRange = allowsEnd ? "0...\(rowCount)" : "0..<\(rowCount)"
        return Diagnostic(
            severity: .error,
            code: "NDS_DATA_ENCOUNTER_JSON_ROWS_INDEX_OUT_OF_RANGE",
            message: "Encounter JSON row operation \(operationIndex + 1) has \(indexDescription), but the valid row range at that step is \(validRange)."
        )
    }

    private static func blockedEditPlan(
        catalog: ProjectNDSDataCatalog,
        draft: NDSDataEditDraft,
        diagnostics: [Diagnostic]
    ) -> NDSDataEditPlan {
        let mutationPlan = MutationPlan(
            title: "NDS encounter JSON row operations blocked",
            summary: "No NDS encounter JSON source files are applyable until operation diagnostics are resolved.",
            diagnostics: diagnostics,
            requiresExplicitApply: true
        )
        return NDSDataEditPlan(
            rootPath: catalog.root.path,
            recordID: draft.recordID,
            draft: draft,
            changes: [],
            diagnostics: diagnostics,
            mutationPlan: mutationPlan,
            backupRelativeRoot: ".pokemonhackstudio/backups/encounter-json-row-operations-blocked"
        )
    }

    private static func span(record: NDSDataCatalogRecord?, line: Int?) -> SourceSpan? {
        guard let record else { return nil }
        guard let line else { return record.sourceSpan }
        return SourceSpan(relativePath: record.relativePath, startLine: line)
    }

    private static func skipWhitespace(_ text: String, index: inout String.Index) {
        while index < text.endIndex, text[index].isWhitespace {
            index = text.index(after: index)
        }
    }

    private static func skipWhitespaceAndCommas(_ text: String, index: inout String.Index) {
        while index < text.endIndex, text[index].isWhitespace || text[index] == "," {
            index = text.index(after: index)
        }
    }

    private static func skipJSONValue(_ text: String, index: inout String.Index) {
        guard index < text.endIndex else { return }
        if text[index] == "\"", let token = parseJSONStringToken(text, start: index) {
            index = token.end
            return
        }
        if text[index] == "{", let end = matchingEnd(text, start: index, open: "{", close: "}") {
            index = end
            return
        }
        if text[index] == "[", let end = matchingEnd(text, start: index, open: "[", close: "]") {
            index = end
            return
        }
        while index < text.endIndex, text[index] != "," && text[index] != "}" && text[index] != "]" {
            index = text.index(after: index)
        }
    }

    private static func jsonScalarEnd(_ text: String, start: String.Index) -> String.Index? {
        if text[start] == "\"" {
            return parseJSONStringToken(text, start: start)?.end
        }
        var end = start
        while end < text.endIndex, text[end] != "," && text[end] != "}" && text[end] != "]" {
            end = text.index(after: end)
        }
        let scalarEnd = trimTrailingWhitespace(text, start: start, end: end)
        guard scalarEnd > start else { return nil }
        let token = String(text[start..<scalarEnd])
        guard let data = "[\(token)]".data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) != nil
        else {
            return nil
        }
        return scalarEnd
    }

    private static func parseJSONStringToken(_ text: String, start: String.Index) -> JSONStringToken? {
        guard start < text.endIndex, text[start] == "\"" else { return nil }
        var index = text.index(after: start)
        var value = ""
        var escaped = false
        while index < text.endIndex {
            let character = text[index]
            if escaped {
                value.append(character)
                escaped = false
            } else if character == "\\" {
                escaped = true
            } else if character == "\"" {
                return JSONStringToken(value: value, end: text.index(after: index))
            } else {
                value.append(character)
            }
            index = text.index(after: index)
        }
        return nil
    }

    private static func matchingEnd(
        _ text: String,
        start: String.Index,
        open: Character,
        close: Character
    ) -> String.Index? {
        guard start < text.endIndex, text[start] == open else { return nil }
        var depth = 0
        var index = start
        var inString = false
        var escaped = false
        while index < text.endIndex {
            let character = text[index]
            if inString {
                if escaped {
                    escaped = false
                } else if character == "\\" {
                    escaped = true
                } else if character == "\"" {
                    inString = false
                }
            } else if character == "\"" {
                inString = true
            } else if character == open {
                depth += 1
            } else if character == close {
                depth -= 1
                if depth == 0 {
                    return text.index(after: index)
                }
            }
            index = text.index(after: index)
        }
        return nil
    }

    private static func trimTrailingWhitespace(
        _ text: String,
        start: String.Index,
        end: String.Index
    ) -> String.Index {
        var valueEnd = end
        while valueEnd > start {
            let previous = text.index(before: valueEnd)
            if !text[previous].isWhitespace {
                break
            }
            valueEnd = previous
        }
        return valueEnd
    }

    private static func lineNumber(in text: String, before index: String.Index) -> Int {
        text[..<index].reduce(1) { count, character in character == "\n" ? count + 1 : count }
    }
}

public enum NDSDataMutationPlanner {
    public static func plan(
        catalog: ProjectNDSDataCatalog,
        draft: NDSDataEditDraft,
        fileManager: FileManager = .default
    ) -> NDSDataEditPlan {
        let root = URL(fileURLWithPath: catalog.root.path).standardizedFileURL
        guard let record = catalog.records.first(where: { $0.id == draft.recordID }) else {
            return blockedPlan(
                catalog: catalog,
                draft: draft,
                diagnostics: [
                    Diagnostic(severity: .error, code: "NDS_DATA_EDIT_RECORD_MISSING", message: "NDS data record \(draft.recordID) is not in the current catalog.")
                ]
            )
        }

        var diagnostics = editabilityDiagnostics(catalog: catalog, record: record, fileManager: fileManager)
        var changes: [NDSDataEditFileChange] = []

        if diagnostics.allSatisfy({ $0.severity != .error }) {
            let sourceURL = root.appendingPathComponent(record.relativePath).standardizedFileURL
            if let originalData = try? Data(contentsOf: sourceURL),
               let originalText = String(data: originalData, encoding: .utf8) {
                let normalizedDraft = normalizeLineEndings(draft.editedText)
                let normalizedOriginal = normalizeLineEndings(originalText)
                if normalizedDraft == normalizedOriginal {
                    diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_EDIT_NO_CHANGES", message: "No NDS source text changes are staged.", span: record.sourceSpan))
                } else if let newData = normalizedDraft.data(using: .utf8) {
                    diagnostics.append(contentsOf: draftValidationDiagnostics(draftText: normalizedDraft, record: record))
                    if diagnostics.allSatisfy({ $0.severity != .error }) {
                        changes.append(
                            NDSDataEditFileChange(
                                path: record.relativePath,
                                summary: "Rewrite NDS data record \(record.title)",
                                originalSHA1: pokemonHackSHA1Hex(originalData),
                                originalByteCount: originalData.count,
                                newByteCount: newData.count,
                                textPreview: preview(normalizedDraft),
                                newData: newData
                            )
                        )
                        diagnostics.append(
                            Diagnostic(
                                severity: .warning,
                                code: "NDS_DATA_EDIT_GENERATED_OUTPUTS_STALE",
                                message: "NDS source edits may leave generated outputs and rebuild artifacts stale until the project is rebuilt externally.",
                                span: record.sourceSpan
                            )
                        )
                    }
                }
            } else {
                diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_EDIT_SOURCE_UNREADABLE", message: "NDS source record could not be read as UTF-8: \(record.relativePath).", span: record.sourceSpan))
            }
        }

        let plannedChanges = changes.map {
            PlannedChange(path: $0.path, summary: $0.summary, span: SourceSpan(relativePath: $0.path, startLine: 1))
        }
        let mutationPlan = MutationPlan(
            title: changes.isEmpty ? "NDS data edits blocked" : "Apply NDS data edits",
            summary: "\(changes.count) source file change(s) for NDS data record \(draft.recordID).",
            changes: plannedChanges,
            diagnostics: diagnostics,
            requiresExplicitApply: true
        )
        return NDSDataEditPlan(
            rootPath: catalog.root.path,
            recordID: draft.recordID,
            draft: draft,
            changes: changes,
            diagnostics: diagnostics,
            mutationPlan: mutationPlan,
            backupRelativeRoot: ".pokemonhackstudio/backups/\(backupTimestamp())"
        )
    }

    public static func editabilityDiagnostics(
        catalog: ProjectNDSDataCatalog,
        recordID: String,
        fileManager: FileManager = .default
    ) -> [Diagnostic] {
        guard let record = catalog.records.first(where: { $0.id == recordID }) else {
            return [Diagnostic(severity: .error, code: "NDS_DATA_EDIT_RECORD_MISSING", message: "NDS data record \(recordID) is not in the current catalog.")]
        }
        return editabilityDiagnostics(catalog: catalog, record: record, fileManager: fileManager)
    }

    public static func sourceText(
        catalog: ProjectNDSDataCatalog,
        recordID: String,
        fileManager: FileManager = .default
    ) -> String? {
        guard let record = catalog.records.first(where: { $0.id == recordID }) else { return nil }
        let diagnostics = editabilityDiagnostics(catalog: catalog, record: record, fileManager: fileManager)
        guard diagnostics.allSatisfy({ $0.severity != .error }) else { return nil }
        let url = URL(fileURLWithPath: catalog.root.path).appendingPathComponent(record.relativePath)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func editabilityDiagnostics(
        catalog: ProjectNDSDataCatalog,
        record: NDSDataCatalogRecord,
        fileManager: FileManager
    ) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        if catalog.profile == .ndsROM {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_EDIT_BINARY_ROM_BLOCKED", message: "NDS ROM inputs are inspect-only; binary data writes and ROM exports remain disabled.", span: record.sourceSpan))
        }
        if catalog.profile == .pmdSky {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_EDIT_SPINOFF_BLOCKED", message: "PMD-Sky is indexed as spin-off inventory only and is not editable in this source-backed Gen IV slice.", span: record.sourceSpan))
        }
        if catalog.profile == .pokeblack {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_GEN_V_WRITE_BLOCKED", message: "Pokemon Black/White source rows are read-only Gen V readiness metadata in this slice; semantic editing, raw source writes, rebuilds, playtest launch, ROM export, and binary writes remain disabled.", span: record.sourceSpan))
        }
        let root = URL(fileURLWithPath: catalog.root.path).standardizedFileURL
        let sourceURL = root.appendingPathComponent(record.relativePath).standardizedFileURL
        if isReferenceResearchRoot(catalog.root.path, sourceURL: sourceURL, fileManager: fileManager) {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_EDIT_REFERENCE_BLOCKED", message: "Reference NDS projects are read-only research inputs and cannot be edited.", span: record.sourceSpan))
        }
        if record.role != .sourceTree {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_EDIT_ROLE_BLOCKED", message: "Only source-tree NDS data records are editable; \(record.role.rawValue) rows stay read-only.", span: record.sourceSpan))
        }
        if !safeEditableFormats.contains(record.format) {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_EDIT_FORMAT_BLOCKED", message: "NDS \(record.format.rawValue) rows are read-only in this source-backed editor slice.", span: record.sourceSpan))
        }
        if record.containerSummary != nil {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_EDIT_CONTAINER_BLOCKED", message: "NDS containers are summarized only; extraction, rebuilds, and container writes remain disabled.", span: record.sourceSpan))
        }
        if !record.exists {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_EDIT_SOURCE_MISSING", message: "NDS source record is missing: \(record.relativePath).", span: record.sourceSpan))
        }
        let pathDiagnostics = SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
            record.relativePath,
            root: root,
            fileManager: fileManager,
            codePrefix: "NDS_DATA_EDIT",
            subject: "NDS source path",
            spanLine: record.sourceSpan?.startLine ?? 1
        )
        if !pathDiagnostics.isEmpty {
            diagnostics.append(contentsOf: pathDiagnostics)
        } else if record.exists {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
                diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_EDIT_SOURCE_NOT_FILE", message: "NDS source record is not an editable file: \(record.relativePath).", span: record.sourceSpan))
                return diagnostics
            }
            guard let data = try? Data(contentsOf: sourceURL), String(data: data, encoding: .utf8) != nil else {
                diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_EDIT_SOURCE_NOT_UTF8", message: "NDS source record must be UTF-8 text before editing: \(record.relativePath).", span: record.sourceSpan))
                return diagnostics
            }
        }
        return diagnostics
    }

    private static func isReferenceResearchRoot(_ path: String, sourceURL: URL, fileManager: FileManager) -> Bool {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        var candidates = [
            url,
            url.resolvingSymlinksInPath().standardizedFileURL,
            sourceURL,
            sourceURL.resolvingSymlinksInPath().standardizedFileURL
        ]
        if let destination = try? fileManager.destinationOfSymbolicLink(atPath: url.path) {
            let destinationURL = URL(
                fileURLWithPath: destination,
                relativeTo: url.deletingLastPathComponent()
            ).standardizedFileURL
            candidates.append(destinationURL)
            candidates.append(destinationURL.resolvingSymlinksInPath().standardizedFileURL)
        }
        return candidates.contains { candidate in
            let components = candidate.pathComponents
            return components.contains("references") || components.contains("reference-repos")
        }
    }

    private static func draftValidationDiagnostics(draftText: String, record: NDSDataCatalogRecord) -> [Diagnostic] {
        guard record.format == .json else { return [] }
        guard let data = draftText.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) != nil
        else {
            return [
                Diagnostic(severity: .error, code: "NDS_DATA_EDIT_JSON_INVALID", message: "Edited NDS JSON must parse before apply: \(record.relativePath).", span: record.sourceSpan)
            ]
        }
        return []
    }

    private static func blockedPlan(catalog: ProjectNDSDataCatalog, draft: NDSDataEditDraft, diagnostics: [Diagnostic]) -> NDSDataEditPlan {
        let mutationPlan = MutationPlan(
            title: "NDS data edits blocked",
            summary: "No NDS source files are applyable until diagnostics are resolved.",
            diagnostics: diagnostics,
            requiresExplicitApply: true
        )
        return NDSDataEditPlan(
            rootPath: catalog.root.path,
            recordID: draft.recordID,
            draft: draft,
            changes: [],
            diagnostics: diagnostics,
            mutationPlan: mutationPlan,
            backupRelativeRoot: ".pokemonhackstudio/backups/\(backupTimestamp())"
        )
    }

    private static func normalizeLineEndings(_ text: String) -> String {
        text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
    }

    private static func preview(_ text: String) -> String {
        String(text.prefix(400))
    }

    private static func backupTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return "\(formatter.string(from: Date()))-\(UUID().uuidString.prefix(8))"
    }

    private static let safeEditableFormats: Set<NDSDataSourceFormat> = [.json, .csv, .text, .cSource, .cHeader]
}

public enum NDSDataMutationApplier {
    public static func apply(plan: NDSDataEditPlan, fileManager: FileManager = .default) throws -> NDSDataApplyResult {
        let root = URL(fileURLWithPath: plan.rootPath).standardizedFileURL
        let backupRoot = root.appendingPathComponent(plan.backupRelativeRoot)
        let applyability = plan.validateApplyability(fileManager: fileManager)
        guard applyability.isApplyable else {
            return NDSDataApplyResult(backupRootPath: backupRoot.path, appliedChanges: [], diagnostics: applyability.diagnostics)
        }
        guard !plan.changes.isEmpty else {
            return NDSDataApplyResult(backupRootPath: backupRoot.path, appliedChanges: [])
        }
        let backupDiagnostics = SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
            plan.backupRelativeRoot,
            root: root,
            fileManager: fileManager,
            codePrefix: "NDS_DATA_APPLY_BACKUP",
            subject: "NDS data backup path"
        )
        guard backupDiagnostics.isEmpty else {
            return NDSDataApplyResult(backupRootPath: backupRoot.path, appliedChanges: [], diagnostics: backupDiagnostics)
        }

        try fileManager.createDirectory(at: backupRoot, withIntermediateDirectories: true)
        var applied: [AppliedNDSDataFileChange] = []
        for change in plan.changes {
            let destination = root.appendingPathComponent(change.path).standardizedFileURL
            let backup = backupRoot.appendingPathComponent(change.path)
            try fileManager.createDirectory(at: backup.deletingLastPathComponent(), withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: destination.path) {
                if fileManager.fileExists(atPath: backup.path) {
                    try fileManager.removeItem(at: backup)
                }
                try fileManager.copyItem(at: destination, to: backup)
            }
            try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            try change.newData.write(to: destination, options: .atomic)
            applied.append(AppliedNDSDataFileChange(path: change.path, backupPath: backup.path, byteCount: change.newData.count))
        }
        return NDSDataApplyResult(backupRootPath: backupRoot.path, appliedChanges: applied)
    }
}

private enum NDSDataEditApplySafety {
    static func applyability(for plan: NDSDataEditPlan, fileManager: FileManager) -> NDSDataEditApplyability {
        var diagnostics = plan.diagnostics.filter { $0.severity == .error }
        let root = URL(fileURLWithPath: plan.rootPath).standardizedFileURL
        guard !plan.rootPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_APPLY_ROOT_MISSING", message: "NDS data apply root path is missing."))
            return NDSDataEditApplyability(isApplyable: false, diagnostics: diagnostics)
        }
        guard fileManager.fileExists(atPath: root.path) else {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_APPLY_ROOT_MISSING", message: "NDS data apply root does not exist: \(plan.rootPath)."))
            return NDSDataEditApplyability(isApplyable: false, diagnostics: diagnostics)
        }
        guard !plan.changes.isEmpty else {
            diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_APPLY_NO_CHANGES", message: "No NDS data source changes are staged."))
            return NDSDataEditApplyability(isApplyable: false, diagnostics: diagnostics)
        }
        for change in plan.changes {
            diagnostics.append(contentsOf: diagnosticsForChange(change, root: root, fileManager: fileManager))
        }
        return NDSDataEditApplyability(isApplyable: diagnostics.allSatisfy { $0.severity != .error }, diagnostics: diagnostics)
    }

    private static func diagnosticsForChange(_ change: NDSDataEditFileChange, root: URL, fileManager: FileManager) -> [Diagnostic] {
        let destination = root.appendingPathComponent(change.path).standardizedFileURL
        let pathDiagnostics = SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
            change.path,
            root: root,
            fileManager: fileManager,
            codePrefix: "NDS_DATA_APPLY",
            subject: "NDS data apply path"
        )
        guard pathDiagnostics.isEmpty else {
            return pathDiagnostics
        }
        guard fileManager.fileExists(atPath: destination.path) else {
            return [pathDiagnostic("NDS_DATA_APPLY_SOURCE_MISSING", "NDS data source file is missing before apply: \(change.path).", path: change.path)]
        }
        guard let currentData = try? Data(contentsOf: destination) else {
            return [pathDiagnostic("NDS_DATA_APPLY_SOURCE_UNREADABLE", "NDS data source file could not be read before apply: \(change.path).", path: change.path)]
        }
        guard currentData.count == change.originalByteCount else {
            return [pathDiagnostic("NDS_DATA_APPLY_SOURCE_SIZE_CHANGED", "NDS data source changed size before apply: \(change.path).", path: change.path)]
        }
        if let originalSHA1 = change.originalSHA1, pokemonHackSHA1Hex(currentData) != originalSHA1 {
            return [pathDiagnostic("NDS_DATA_APPLY_SOURCE_HASH_CHANGED", "NDS data source changed hash before apply: \(change.path).", path: change.path)]
        }
        return []
    }

    private static func pathDiagnostic(_ code: String, _ message: String, path: String) -> Diagnostic {
        Diagnostic(severity: .error, code: code, message: message, span: SourceSpan(relativePath: path, startLine: 1))
    }

}
