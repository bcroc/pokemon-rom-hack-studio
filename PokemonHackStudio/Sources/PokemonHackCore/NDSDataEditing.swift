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
            let parsed = parseTopLevelScalarJSONFields(sourceText: sourceText, record: record)
            fields = parsed.fields.map(\.semanticField)
            diagnostics.append(contentsOf: parsed.diagnostics)
            if fields.isEmpty, parsed.diagnostics.allSatisfy({ $0.severity != .error }) {
                diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_NO_FIELDS", message: "No top-level scalar JSON fields are available for semantic editing: \(record.relativePath).", span: record.sourceSpan))
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
        let editResult = snapshot.canEdit
            ? updateSourceText(sourceText, fieldEdits: draft.fieldEdits, recordID: draft.recordID)
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

    public static func fields(sourceText: String, recordID: String) -> [NDSDataSemanticField] {
        parseTopLevelScalarJSONFields(sourceText: sourceText, record: nil).fields.map(\.semanticField)
    }

    public static func updateSourceText(
        _ sourceText: String,
        fieldEdits: [NDSDataSemanticFieldEdit],
        recordID: String
    ) -> (text: String, diagnostics: [Diagnostic]) {
        let parsed = parseTopLevelScalarJSONFields(sourceText: sourceText, record: nil)
        var diagnostics = parsed.diagnostics
        var text = sourceText
        let fieldsByKey = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.semanticField.key, $0) })

        var replacements: [(range: Range<String.Index>, value: String)] = []
        for edit in fieldEdits {
            guard let field = fieldsByKey[edit.key] else {
                diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_FIELD_MISSING", message: "Semantic NDS field \(edit.key) is not available on \(recordID)."))
                continue
            }
            guard let rendered = renderedJSONValue(edit.value, as: field.semanticField.valueKind) else {
                diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_VALUE_INVALID", message: "Semantic NDS field \(edit.key) cannot use value \(edit.value) as \(field.semanticField.valueKind.rawValue)."))
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
        if catalog.profile != .pokeplatinum {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_PROFILE_BLOCKED", message: "Semantic Gen IV field editing starts with Platinum source-tree JSON records; \(catalog.profile.rawValue) stays on raw source editing for now.", span: record.sourceSpan))
        }
        if ![NDSDataDomain.species, .personal, .moves, .items, .trainers].contains(record.domain) {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_DOMAIN_BLOCKED", message: "Semantic Gen IV field editing is limited to Platinum Pokemon, move, item, and trainer JSON records in this slice.", span: record.sourceSpan))
        }
        if record.domain == .items, !isPlatinumItemDataPath(record.relativePath) {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_ITEM_PATH_BLOCKED", message: "Semantic item editing is limited to Platinum item JSON rows under res/items; CSV, generated, binary, and non-Platinum item data remain on raw source editing or read-only surfaces.", span: record.sourceSpan))
        }
        if record.domain == .trainers, !isPlatinumTrainerDataPath(record.relativePath) {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_TRAINER_PATH_BLOCKED", message: "Semantic trainer editing is limited to Platinum trainer data JSON rows under res/trainers/data; trainer classes, animation resources, and other trainer assets remain on raw source editing or read-only surfaces.", span: record.sourceSpan))
        }
        if record.format != .json {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_FORMAT_BLOCKED", message: "Semantic Gen IV field editing requires source-backed JSON; \(record.format.rawValue) rows use the raw text editor or stay read-only.", span: record.sourceSpan))
        }
        return diagnostics
    }

    private static func isPlatinumTrainerDataPath(_ relativePath: String) -> Bool {
        relativePath.hasPrefix("res/trainers/data/") && relativePath.lowercased().hasSuffix(".json")
    }

    private static func isPlatinumItemDataPath(_ relativePath: String) -> Bool {
        relativePath.hasPrefix("res/items/") && relativePath.lowercased().hasSuffix(".json")
    }

    private struct ParsedSemanticField {
        let semanticField: NDSDataSemanticField
        let valueRange: Range<String.Index>
    }

    private static func parseTopLevelScalarJSONFields(
        sourceText: String,
        record: NDSDataCatalogRecord?
    ) -> (fields: [ParsedSemanticField], diagnostics: [Diagnostic]) {
        var diagnostics: [Diagnostic] = []
        let trimmed = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{") else {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_JSON_OBJECT_REQUIRED", message: "Semantic NDS editing requires a top-level JSON object.", span: record?.sourceSpan))
            return ([], diagnostics)
        }

        var fields: [ParsedSemanticField] = []
        var index = sourceText.startIndex
        guard let objectStart = sourceText[index...].firstIndex(of: "{") else {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_SEMANTIC_JSON_OBJECT_REQUIRED", message: "Semantic NDS editing requires a top-level JSON object.", span: record?.sourceSpan))
            return ([], diagnostics)
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
            skipWhitespace(sourceText, index: &index)
            guard index < sourceText.endIndex, sourceText[index] == ":" else { continue }
            index = sourceText.index(after: index)
            skipWhitespace(sourceText, index: &index)
            let valueStart = index
            guard let value = parseJSONScalarValue(sourceText, start: valueStart) else {
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

        if fields.isEmpty {
            diagnostics.append(Diagnostic(severity: .warning, code: "NDS_DATA_SEMANTIC_NO_SCALAR_FIELDS", message: "No top-level scalar JSON fields were found for semantic NDS editing.", span: record?.sourceSpan))
        }
        return (fields, diagnostics)
    }

    private static func parseJSONStringToken(_ text: String, start: String.Index) -> (value: String, end: String.Index)? {
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
                return (value, text.index(after: index))
            } else {
                value.append(character)
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
        if catalog.root.path.contains("/reference-repos/") || catalog.root.path.contains("/references/") {
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
        let root = URL(fileURLWithPath: catalog.root.path).standardizedFileURL
        let sourceURL = root.appendingPathComponent(record.relativePath).standardizedFileURL
        if !isContained(sourceURL, in: root) {
            diagnostics.append(Diagnostic(severity: .error, code: "NDS_DATA_EDIT_PATH_OUTSIDE_ROOT", message: "NDS source path is outside the project root: \(record.relativePath).", span: record.sourceSpan))
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
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: Date())
    }

    private static func isContained(_ url: URL, in root: URL) -> Bool {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        return path == rootPath || path.hasPrefix(rootPath + "/")
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
        guard isContained(destination, in: root) else {
            return [pathDiagnostic("NDS_DATA_APPLY_PATH_OUTSIDE_ROOT", "NDS data apply path is outside the project root: \(change.path).", path: change.path)]
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

    private static func isContained(_ url: URL, in root: URL) -> Bool {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        return path == rootPath || path.hasPrefix(rootPath + "/")
    }
}
