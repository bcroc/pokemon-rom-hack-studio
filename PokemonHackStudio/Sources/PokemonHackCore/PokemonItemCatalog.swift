import Foundation

public struct ProjectItemCatalog: Codable, Equatable {
    public let root: SourceLocation
    public let profile: GameProfile
    public let adapterID: String
    public let adapterName: String
    public let itemCount: Int
    public let items: [ItemDetail]
    public let diagnostics: [Diagnostic]

    public init(
        root: SourceLocation,
        profile: GameProfile,
        adapterID: String,
        adapterName: String,
        items: [ItemDetail],
        diagnostics: [Diagnostic] = []
    ) {
        self.root = root
        self.profile = profile
        self.adapterID = adapterID
        self.adapterName = adapterName
        self.itemCount = items.count
        self.items = items
        self.diagnostics = diagnostics
    }
}

public struct ItemDetail: Codable, Equatable, Identifiable {
    public var id: String { itemID }

    public let itemID: String
    public let displayName: String
    public let sourceSpan: SourceSpan
    public let sourcePreview: String?
    public let name: String?
    public let price: String?
    public let holdEffect: String?
    public let holdEffectParam: String?
    public let pocket: String?
    public let type: String?
    public let battleUsage: String?
    public let secondaryId: String?
    public let fieldUseFunc: String?
    public let battleUseFunc: String?
    public let descriptionSymbol: String?
    public let descriptionText: String?
    public let isDescriptionEditable: Bool
    public let diagnostics: [Diagnostic]
    public let isEditable: Bool

    public init(
        itemID: String,
        displayName: String,
        sourceSpan: SourceSpan,
        sourcePreview: String? = nil,
        name: String? = nil,
        price: String? = nil,
        holdEffect: String? = nil,
        holdEffectParam: String? = nil,
        pocket: String? = nil,
        type: String? = nil,
        battleUsage: String? = nil,
        secondaryId: String? = nil,
        fieldUseFunc: String? = nil,
        battleUseFunc: String? = nil,
        descriptionSymbol: String? = nil,
        descriptionText: String? = nil,
        isDescriptionEditable: Bool = false,
        diagnostics: [Diagnostic] = [],
        isEditable: Bool = false
    ) {
        self.itemID = itemID
        self.displayName = displayName
        self.sourceSpan = sourceSpan
        self.sourcePreview = sourcePreview
        self.name = name
        self.price = price
        self.holdEffect = holdEffect
        self.holdEffectParam = holdEffectParam
        self.pocket = pocket
        self.type = type
        self.battleUsage = battleUsage
        self.secondaryId = secondaryId
        self.fieldUseFunc = fieldUseFunc
        self.battleUseFunc = battleUseFunc
        self.descriptionSymbol = descriptionSymbol
        self.descriptionText = descriptionText
        self.isDescriptionEditable = isDescriptionEditable
        self.diagnostics = diagnostics
        self.isEditable = isEditable
    }
}

public struct ItemEditDraft: Codable, Equatable {
    public var itemID: String
    public var name: String?
    public var price: String?
    public var holdEffect: String?
    public var holdEffectParam: String?
    public var pocket: String?
    public var type: String?
    public var battleUsage: String?
    public var secondaryId: String?
    public var fieldUseFunc: String?
    public var battleUseFunc: String?
    public var descriptionText: String?

    public init(
        itemID: String,
        name: String? = nil,
        price: String? = nil,
        holdEffect: String? = nil,
        holdEffectParam: String? = nil,
        pocket: String? = nil,
        type: String? = nil,
        battleUsage: String? = nil,
        secondaryId: String? = nil,
        fieldUseFunc: String? = nil,
        battleUseFunc: String? = nil,
        descriptionText: String? = nil
    ) {
        self.itemID = itemID
        self.name = name
        self.price = price
        self.holdEffect = holdEffect
        self.holdEffectParam = holdEffectParam
        self.pocket = pocket
        self.type = type
        self.battleUsage = battleUsage
        self.secondaryId = secondaryId
        self.fieldUseFunc = fieldUseFunc
        self.battleUseFunc = battleUseFunc
        self.descriptionText = descriptionText
    }

    public init?(detail: ItemDetail) {
        guard detail.isEditable || detail.isDescriptionEditable else { return nil }
        self.init(
            itemID: detail.itemID,
            name: detail.isEditable ? detail.name : nil,
            price: detail.isEditable ? detail.price : nil,
            holdEffect: detail.isEditable ? detail.holdEffect : nil,
            holdEffectParam: detail.isEditable ? detail.holdEffectParam : nil,
            pocket: detail.isEditable ? detail.pocket : nil,
            type: detail.isEditable ? detail.type : nil,
            battleUsage: detail.isEditable ? detail.battleUsage : nil,
            secondaryId: detail.isEditable ? detail.secondaryId : nil,
            fieldUseFunc: detail.isEditable ? detail.fieldUseFunc : nil,
            battleUseFunc: detail.isEditable ? detail.battleUseFunc : nil,
            descriptionText: detail.descriptionText
        )
    }
}

public struct ItemEditFileChange: Codable, Equatable, Identifiable {
    public var id: String { path }

    public let path: String
    public let summary: String
    public let originalByteCount: Int
    public let originalSHA1: String?
    public let newByteCount: Int
    public let newData: Data
    public let textPreview: String?

    public init(
        path: String,
        summary: String,
        originalByteCount: Int,
        originalSHA1: String? = nil,
        newByteCount: Int,
        newData: Data,
        textPreview: String? = nil
    ) {
        self.path = path
        self.summary = summary
        self.originalByteCount = originalByteCount
        self.originalSHA1 = originalSHA1
        self.newByteCount = newByteCount
        self.newData = newData
        self.textPreview = textPreview
    }
}

public struct ItemEditPlan: Codable, Equatable, Identifiable {
    public let id: String
    public let rootPath: String
    public let itemID: String
    public let draft: ItemEditDraft
    public let changes: [ItemEditFileChange]
    public let diagnostics: [Diagnostic]
    public let mutationPlan: MutationPlan
    public let backupRelativeRoot: String

    public init(
        id: String = UUID().uuidString,
        rootPath: String,
        itemID: String,
        draft: ItemEditDraft,
        changes: [ItemEditFileChange],
        diagnostics: [Diagnostic],
        mutationPlan: MutationPlan,
        backupRelativeRoot: String
    ) {
        self.id = id
        self.rootPath = rootPath
        self.itemID = itemID
        self.draft = draft
        self.changes = changes
        self.diagnostics = diagnostics
        self.mutationPlan = mutationPlan
        self.backupRelativeRoot = backupRelativeRoot
    }
}

public struct ItemEditApplyability: Codable, Equatable {
    public let isApplyable: Bool
    public let diagnostics: [Diagnostic]

    public init(isApplyable: Bool, diagnostics: [Diagnostic]) {
        self.isApplyable = isApplyable
        self.diagnostics = diagnostics
    }
}

public extension ItemEditPlan {
    var applyability: ItemEditApplyability {
        validateApplyability()
    }

    var isApplyable: Bool {
        applyability.isApplyable
    }

    func validateApplyability(fileManager: FileManager = .default) -> ItemEditApplyability {
        ItemEditApplySafety.applyability(for: self, fileManager: fileManager)
    }
}

public struct AppliedItemFileChange: Codable, Equatable, Identifiable {
    public var id: String { path }

    public let path: String
    public let backupPath: String
    public let byteCount: Int

    public init(path: String, backupPath: String, byteCount: Int) {
        self.path = path
        self.backupPath = backupPath
        self.byteCount = byteCount
    }
}

public struct ItemApplyResult: Codable, Equatable, Identifiable {
    public let id: String
    public let backupRootPath: String
    public let appliedChanges: [AppliedItemFileChange]
    public let diagnostics: [Diagnostic]

    public init(id: String = UUID().uuidString, backupRootPath: String, appliedChanges: [AppliedItemFileChange], diagnostics: [Diagnostic] = []) {
        self.id = id
        self.backupRootPath = backupRootPath
        self.appliedChanges = appliedChanges
        self.diagnostics = diagnostics
    }
}

public enum ProjectItemCatalogBuilder {
    public static func build(path: String, fileManager: FileManager = .default) throws -> ProjectItemCatalog {
        try build(index: GameAdapterRegistry.index(path: path, fileManager: fileManager), fileManager: fileManager)
    }

    public static func build(
        index: ProjectIndex,
        sourceIndex: ProjectSourceIndex? = nil,
        fileManager: FileManager = .default
    ) throws -> ProjectItemCatalog {
        let root = URL(fileURLWithPath: index.root.path)
        guard let descriptor = ItemCatalogDescriptor.descriptor(for: index.profile) else {
            let diagnostic = readOnlyDiagnostic(profile: index.profile, span: SourceSpan(relativePath: index.root.path, startLine: 1))
            return ProjectItemCatalog(
                root: index.root,
                profile: index.profile,
                adapterID: index.adapterID,
                adapterName: index.adapterName,
                items: [],
                diagnostics: [diagnostic]
            )
        }

        if descriptor.supportsItemCatalogParsing {
            return try sourceBackedCatalog(index: index, descriptor: descriptor, root: root, fileManager: fileManager)
        }

        return readOnlyCatalog(index: index, descriptor: descriptor, sourceIndex: sourceIndex, fileManager: fileManager)
    }

    private static func sourceBackedCatalog(
        index: ProjectIndex,
        descriptor: ItemCatalogDescriptor,
        root: URL,
        fileManager: FileManager
    ) throws -> ProjectItemCatalog {
        var diagnostics: [Diagnostic] = []
        let path = root.appendingPathComponent(descriptor.itemPath)
        guard fileManager.fileExists(atPath: path.path) else {
            diagnostics.append(missingSourceDiagnostic(path: descriptor.itemPath))
            return ProjectItemCatalog(root: index.root, profile: index.profile, adapterID: index.adapterID, adapterName: index.adapterName, items: [], diagnostics: diagnostics)
        }

        let text = try readText(path)
        let descriptions = readDescriptionTexts(descriptor: descriptor, root: root, fileManager: fileManager)
        let parsed = CInitializerParser.tableEntries(
            in: text,
            descriptor: CInitializerTableDescriptor(
                module: .items,
                relativePath: descriptor.itemPath,
                tableSymbol: descriptor.tableSymbol,
                entryStyle: descriptor.entryStyle,
                idField: descriptor.idField,
                knownFields: itemFields,
                warnsOnUnknownFields: true
            )
        )
        diagnostics.append(contentsOf: parsed.diagnostics)
        let items = parsed.entries.compactMap { entry -> ItemDetail? in
            guard entry.symbol.hasPrefix("ITEM_") else { return nil }
            return detail(from: entry, descriptor: descriptor, descriptions: descriptions)
        }
        diagnostics.append(contentsOf: items.flatMap(\.diagnostics))
        return ProjectItemCatalog(
            root: index.root,
            profile: index.profile,
            adapterID: index.adapterID,
            adapterName: index.adapterName,
            items: items.sorted { $0.sourceSpan.startLine < $1.sourceSpan.startLine },
            diagnostics: diagnostics
        )
    }

    private static func readOnlyCatalog(
        index: ProjectIndex,
        descriptor: ItemCatalogDescriptor,
        sourceIndex: ProjectSourceIndex?,
        fileManager: FileManager
    ) -> ProjectItemCatalog {
        let readOnly = readOnlyDiagnostic(profile: index.profile, span: SourceSpan(relativePath: descriptor.itemPath, startLine: 1))
        let loadedSourceIndex = sourceIndex ?? (try? ProjectSourceIndexLoader.load(from: index, fileManager: fileManager))
        let records = loadedSourceIndex?.records.filter { $0.module == .items } ?? []
        let items = records.map { record in
            ItemDetail(
                itemID: record.title,
                displayName: displayName(for: record.title),
                sourceSpan: record.sourceSpan,
                sourcePreview: record.preview,
                name: fact("name", in: record.facts).flatMap(unwrappedTextMacro),
                price: fact("price", in: record.facts),
                holdEffect: fact("holdEffect", in: record.facts),
                holdEffectParam: fact("holdEffectParam", in: record.facts),
                pocket: fact("pocket", in: record.facts),
                type: fact("type", in: record.facts),
                battleUsage: fact("battleUsage", in: record.facts),
                secondaryId: fact("secondaryId", in: record.facts),
                fieldUseFunc: fact("fieldUseFunc", in: record.facts),
                battleUseFunc: fact("battleUseFunc", in: record.facts),
                descriptionSymbol: fact("description", in: record.facts),
                descriptionText: nil,
                isDescriptionEditable: false,
                diagnostics: record.diagnostics + [readOnly],
                isEditable: false
            )
        }
        return ProjectItemCatalog(
            root: index.root,
            profile: index.profile,
            adapterID: index.adapterID,
            adapterName: index.adapterName,
            items: items,
            diagnostics: (loadedSourceIndex?.diagnostics ?? []) + [readOnly]
        )
    }

    private static func detail(
        from entry: CInitializerEntry,
        descriptor: ItemCatalogDescriptor,
        descriptions: [String: ItemDescriptionText]
    ) -> ItemDetail {
        let fields = entry.fields
        let name = unwrappedTextMacro(compact(fields["name"]))
        let descriptionSymbol = compact(fields["description"])
        let diagnostics = editabilityDiagnostics(entry: entry, descriptor: descriptor)
        return ItemDetail(
            itemID: entry.symbol,
            displayName: name ?? displayName(for: entry.symbol),
            sourceSpan: entry.span,
            sourcePreview: preview(entry.body),
            name: name,
            price: compact(fields["price"]),
            holdEffect: compact(fields["holdEffect"]),
            holdEffectParam: compact(fields["holdEffectParam"]),
            pocket: compact(fields["pocket"]),
            type: compact(fields["type"]),
            battleUsage: compact(fields["battleUsage"]),
            secondaryId: compact(fields["secondaryId"]),
            fieldUseFunc: compact(fields["fieldUseFunc"]),
            battleUseFunc: compact(fields["battleUseFunc"]),
            descriptionSymbol: descriptionSymbol,
            descriptionText: descriptionSymbol.flatMap { descriptions[$0]?.text },
            isDescriptionEditable: descriptor.supportsDescriptionEditing && descriptionSymbol.flatMap { descriptions[$0] } != nil,
            diagnostics: diagnostics,
            isEditable: descriptor.supportsRowEditing && diagnostics.allSatisfy { $0.severity != .error }
        )
    }

    private static func editabilityDiagnostics(entry: CInitializerEntry, descriptor: ItemCatalogDescriptor) -> [Diagnostic] {
        guard descriptor.supportsRowEditing || descriptor.supportsDescriptionEditing else {
            return [readOnlyDiagnostic(profile: descriptor.profile, span: entry.span)]
        }
        guard !entry.fields.isEmpty else {
            return [
                Diagnostic(
                    severity: .error,
                    code: "ITEM_ENTRY_UNSUPPORTED_SHAPE",
                    message: "\(entry.symbol) uses a macro or initializer shape that cannot be safely rewritten yet.",
                    span: entry.span
                )
            ]
        }
        if let itemId = compact(entry.fields["itemId"]), itemId != entry.symbol {
            return [
                Diagnostic(
                    severity: .error,
                    code: "ITEM_ENTRY_ID_MISMATCH",
                    message: "\(entry.symbol) has read-only itemId \(itemId). The bracket key and itemId must match before editing.",
                    span: entry.span
                )
            ]
        }
        return []
    }

    private static func readDescriptionTexts(
        descriptor: ItemCatalogDescriptor,
        root: URL,
        fileManager: FileManager
    ) -> [String: ItemDescriptionText] {
        guard let path = descriptor.descriptionPath else { return [:] }
        let url = root.appendingPathComponent(path)
        guard fileManager.fileExists(atPath: url.path), let text = try? readText(url) else { return [:] }
        return ItemDescriptionScanner.descriptions(in: text, relativePath: path)
    }

    private static func fact(_ label: String, in facts: [SourceIndexFact]) -> String? {
        facts.first { $0.label == label }?.value
    }

    private static func missingSourceDiagnostic(path: String) -> Diagnostic {
        Diagnostic(
            severity: .warning,
            code: "ITEM_CATALOG_SOURCE_MISSING",
            message: "Item catalog source is not present: \(path)",
            span: SourceSpan(relativePath: path, startLine: 1)
        )
    }
}

public enum ItemMutationPlanner {
    public static func plan(
        catalog: ProjectItemCatalog,
        draft: ItemEditDraft,
        fileManager: FileManager = .default
    ) -> ItemEditPlan {
        let root = URL(fileURLWithPath: catalog.root.path).standardizedFileURL
        guard let descriptor = ItemCatalogDescriptor.descriptor(for: catalog.profile),
              descriptor.supportsRowEditing || descriptor.supportsDescriptionEditing
        else {
            return blockedPlan(
                catalog: catalog,
                draft: draft,
                diagnostics: [
                    Diagnostic(severity: .error, code: "ITEM_PLAN_READ_ONLY_PROFILE", message: "Item apply is currently available only for classic Emerald item rows and supported Emerald/FireRed item descriptions.")
                ]
            )
        }
        guard let item = catalog.items.first(where: { $0.itemID == draft.itemID }) else {
            return blockedPlan(
                catalog: catalog,
                draft: draft,
                diagnostics: [
                    Diagnostic(severity: .error, code: "ITEM_PLAN_TARGET_MISSING", message: "Item \(draft.itemID) is not in the current catalog.")
                ]
            )
        }

        var diagnostics = plannerDiagnostics(item: item, draft: draft)
        var changes: [ItemEditFileChange] = []

        if diagnostics.allSatisfy({ $0.severity != .error }) {
            if descriptor.supportsRowEditing,
               let change = rewriteChange(root: root, descriptor: descriptor, item: item, draft: draft, diagnostics: &diagnostics)
            {
                changes.append(change)
            }
            if let change = rewriteDescriptionChange(root: root, descriptor: descriptor, item: item, draft: draft, diagnostics: &diagnostics) {
                changes.append(change)
            }
        }

        let plannedChanges = changes.map {
            PlannedChange(path: $0.path, summary: $0.summary, span: SourceSpan(relativePath: $0.path, startLine: 1))
        }
        let mutationPlan = MutationPlan(
            title: "Apply item edits to \(draft.itemID)",
            summary: "\(changes.count) source file change(s) for item data.",
            changes: plannedChanges,
            diagnostics: diagnostics,
            requiresExplicitApply: true
        )
        return ItemEditPlan(
            rootPath: catalog.root.path,
            itemID: draft.itemID,
            draft: draft,
            changes: changes,
            diagnostics: diagnostics,
            mutationPlan: mutationPlan,
            backupRelativeRoot: ".pokemonhackstudio/backups/\(backupTimestamp())"
        )
    }

    private static func blockedPlan(catalog: ProjectItemCatalog, draft: ItemEditDraft, diagnostics: [Diagnostic]) -> ItemEditPlan {
        let mutationPlan = MutationPlan(
            title: "Item edits blocked for \(draft.itemID)",
            summary: "No source files are applyable until diagnostics are resolved.",
            diagnostics: diagnostics,
            requiresExplicitApply: true
        )
        return ItemEditPlan(
            rootPath: catalog.root.path,
            itemID: draft.itemID,
            draft: draft,
            changes: [],
            diagnostics: diagnostics,
            mutationPlan: mutationPlan,
            backupRelativeRoot: ".pokemonhackstudio/backups/\(backupTimestamp())"
        )
    }

    private static func plannerDiagnostics(item: ItemDetail, draft: ItemEditDraft) -> [Diagnostic] {
        var diagnostics = item.diagnostics.filter { $0.severity == .error }
        guard item.isEditable || item.isDescriptionEditable else {
            diagnostics.append(Diagnostic(severity: .error, code: "ITEM_NOT_EDITABLE", message: "\(item.itemID) is read-only until its source diagnostics are resolved.", span: item.sourceSpan))
            return diagnostics
        }
        if draft.itemID != item.itemID {
            diagnostics.append(Diagnostic(severity: .error, code: "ITEM_DRAFT_ID_MISMATCH", message: "Item IDs are read-only. Draft \(draft.itemID) does not match catalog item \(item.itemID).", span: item.sourceSpan))
        }
        return diagnostics
    }

    private static func rewriteChange(
        root: URL,
        descriptor: ItemCatalogDescriptor,
        item: ItemDetail,
        draft: ItemEditDraft,
        diagnostics: inout [Diagnostic]
    ) -> ItemEditFileChange? {
        let path = descriptor.itemPath
        let url = root.appendingPathComponent(path)
        guard let originalText = try? readText(url), let originalData = originalText.data(using: .utf8) else {
            diagnostics.append(Diagnostic(severity: .error, code: "ITEM_PLAN_SOURCE_UNREADABLE", message: "Item source file could not be read before planning: \(path).", span: SourceSpan(relativePath: path, startLine: 1)))
            return nil
        }
        let parsed = CInitializerParser.tableEntries(
            in: originalText,
            descriptor: CInitializerTableDescriptor(module: .items, relativePath: path, tableSymbol: descriptor.tableSymbol, entryStyle: descriptor.entryStyle, idField: descriptor.idField)
        )
        guard let entry = parsed.entries.first(where: { $0.symbol == item.itemID }) else {
            diagnostics.append(Diagnostic(severity: .error, code: "ITEM_PLAN_TARGET_MISSING", message: "Item \(item.itemID) is not present in \(path).", span: SourceSpan(relativePath: path, startLine: 1)))
            return nil
        }

        let changes = changedFields(item: item, draft: draft)
        guard !changes.isEmpty else { return nil }
        guard let patchedBody = ItemFieldPatcher.patch(entryBody: entry.body, changes: changes, diagnostics: &diagnostics, span: entry.span) else {
            return nil
        }

        let replacement = patchedBody.hasSuffix(",") ? patchedBody : "\(patchedBody),"
        let newText = replaceLines(in: originalText, span: entry.span, replacement: replacement)
        guard newText != originalText, let newData = newText.data(using: .utf8) else { return nil }
        return ItemEditFileChange(
            path: path,
            summary: "Update item source block",
            originalByteCount: originalData.count,
            originalSHA1: pokemonHackSHA1Hex(originalData),
            newByteCount: newData.count,
            newData: newData,
            textPreview: replacement
        )
    }

    private static func rewriteDescriptionChange(
        root: URL,
        descriptor: ItemCatalogDescriptor,
        item: ItemDetail,
        draft: ItemEditDraft,
        diagnostics: inout [Diagnostic]
    ) -> ItemEditFileChange? {
        guard let draftText = draft.descriptionText, draftText != item.descriptionText else { return nil }
        guard let path = descriptor.descriptionPath, let symbol = item.descriptionSymbol else {
            diagnostics.append(Diagnostic(severity: .error, code: "ITEM_DESCRIPTION_SOURCE_MISSING", message: "Item \(item.itemID) does not have a description symbol that can be rewritten.", span: item.sourceSpan))
            return nil
        }
        let url = root.appendingPathComponent(path)
        guard let originalText = try? readText(url), let originalData = originalText.data(using: .utf8) else {
            diagnostics.append(Diagnostic(severity: .error, code: "ITEM_DESCRIPTION_SOURCE_UNREADABLE", message: "Item description source file could not be read before planning: \(path).", span: SourceSpan(relativePath: path, startLine: 1)))
            return nil
        }
        guard let description = ItemDescriptionScanner.descriptions(in: originalText, relativePath: path)[symbol] else {
            diagnostics.append(Diagnostic(severity: .error, code: "ITEM_DESCRIPTION_SYMBOL_MISSING", message: "Description symbol \(symbol) was not found in \(path).", span: SourceSpan(relativePath: path, startLine: 1)))
            return nil
        }
        let replacement = renderDescriptionDeclaration(symbol: symbol, text: draftText, usesStatic: description.usesStatic)
        let mutableText = NSMutableString(string: originalText)
        mutableText.replaceCharacters(
            in: NSRange(location: description.startOffset, length: description.endOffset - description.startOffset),
            with: replacement
        )
        let newText = mutableText as String
        guard newText != originalText, let newData = newText.data(using: .utf8) else { return nil }
        return ItemEditFileChange(
            path: path,
            summary: "Update item description text",
            originalByteCount: originalData.count,
            originalSHA1: pokemonHackSHA1Hex(originalData),
            newByteCount: newData.count,
            newData: newData,
            textPreview: replacement
        )
    }

    private static func changedFields(item: ItemDetail, draft: ItemEditDraft) -> [ItemFieldChange] {
        [
            fieldChange(key: "name", current: item.name, draft: draft.name, render: renderName),
            fieldChange(key: "price", current: item.price, draft: draft.price),
            fieldChange(key: "holdEffect", current: item.holdEffect, draft: draft.holdEffect),
            fieldChange(key: "holdEffectParam", current: item.holdEffectParam, draft: draft.holdEffectParam),
            fieldChange(key: "pocket", current: item.pocket, draft: draft.pocket),
            fieldChange(key: "type", current: item.type, draft: draft.type),
            fieldChange(key: "battleUsage", current: item.battleUsage, draft: draft.battleUsage),
            fieldChange(key: "secondaryId", current: item.secondaryId, draft: draft.secondaryId),
            fieldChange(key: "fieldUseFunc", current: item.fieldUseFunc, draft: draft.fieldUseFunc),
            fieldChange(key: "battleUseFunc", current: item.battleUseFunc, draft: draft.battleUseFunc)
        ].compactMap { $0 }
    }

    private static func fieldChange(
        key: String,
        current: String?,
        draft: String?,
        render: (String) -> String = { $0 }
    ) -> ItemFieldChange? {
        guard current != draft else { return nil }
        guard let draft else {
            return ItemFieldChange(key: key, replacement: "")
        }
        return ItemFieldChange(key: key, replacement: render(draft))
    }

    private static func renderName(_ name: String) -> String {
        "_(\"\(escapeCString(name))\")"
    }

    private static func backupTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "\(formatter.string(from: Date()))-\(UUID().uuidString.prefix(8))"
    }
}

public enum ItemMutationApplier {
    public static func apply(plan: ItemEditPlan, fileManager: FileManager = .default) throws -> ItemApplyResult {
        let root = URL(fileURLWithPath: plan.rootPath).standardizedFileURL
        let backupRoot = root.appendingPathComponent(plan.backupRelativeRoot)
        let applyability = plan.validateApplyability(fileManager: fileManager)
        guard applyability.isApplyable else {
            return ItemApplyResult(backupRootPath: backupRoot.path, appliedChanges: [], diagnostics: applyability.diagnostics)
        }
        guard !plan.changes.isEmpty else {
            return ItemApplyResult(backupRootPath: backupRoot.path, appliedChanges: [])
        }

        try fileManager.createDirectory(at: backupRoot, withIntermediateDirectories: true)
        var applied: [AppliedItemFileChange] = []
        for change in plan.changes {
            let destination = root.appendingPathComponent(change.path)
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
            applied.append(AppliedItemFileChange(path: change.path, backupPath: backup.path, byteCount: change.newData.count))
        }
        return ItemApplyResult(backupRootPath: backupRoot.path, appliedChanges: applied)
    }
}

private enum ItemEditApplySafety {
    static func applyability(for plan: ItemEditPlan, fileManager: FileManager) -> ItemEditApplyability {
        var diagnostics = plan.diagnostics.filter { $0.severity == .error }
        let root = URL(fileURLWithPath: plan.rootPath).standardizedFileURL
        guard !plan.rootPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            diagnostics.append(Diagnostic(severity: .error, code: "ITEM_APPLY_ROOT_MISSING", message: "Item apply root path is missing."))
            return ItemEditApplyability(isApplyable: false, diagnostics: diagnostics)
        }
        guard fileManager.fileExists(atPath: root.path) else {
            diagnostics.append(Diagnostic(severity: .error, code: "ITEM_APPLY_ROOT_MISSING", message: "Item apply root does not exist: \(plan.rootPath)."))
            return ItemEditApplyability(isApplyable: false, diagnostics: diagnostics)
        }
        guard !plan.changes.isEmpty else {
            diagnostics.append(Diagnostic(severity: .warning, code: "ITEM_APPLY_NO_CHANGES", message: "No item source changes are staged."))
            return ItemEditApplyability(isApplyable: false, diagnostics: diagnostics)
        }
        for change in plan.changes {
            diagnostics.append(contentsOf: diagnosticsForChange(change, root: root, fileManager: fileManager))
        }
        return ItemEditApplyability(isApplyable: diagnostics.allSatisfy { $0.severity != .error }, diagnostics: diagnostics)
    }

    private static func diagnosticsForChange(_ change: ItemEditFileChange, root: URL, fileManager: FileManager) -> [Diagnostic] {
        let destination = root.appendingPathComponent(change.path).standardizedFileURL
        guard isContained(destination, in: root) else {
            return [pathDiagnostic("ITEM_APPLY_PATH_OUTSIDE_ROOT", "Item apply path is outside the project root: \(change.path).", path: change.path)]
        }
        guard fileManager.fileExists(atPath: destination.path) else {
            return [pathDiagnostic("ITEM_APPLY_SOURCE_MISSING", "Item source file is missing before apply: \(change.path).", path: change.path)]
        }
        guard let currentData = try? Data(contentsOf: destination) else {
            return [pathDiagnostic("ITEM_APPLY_SOURCE_UNREADABLE", "Item source file could not be read before apply: \(change.path).", path: change.path)]
        }
        guard currentData.count == change.originalByteCount else {
            return [pathDiagnostic("ITEM_APPLY_ORIGINAL_SIZE_MISMATCH", "Item source file changed size since planning: \(change.path).", path: change.path)]
        }
        if let originalSHA1 = change.originalSHA1, pokemonHackSHA1Hex(currentData) != originalSHA1 {
            return [pathDiagnostic("ITEM_APPLY_ORIGINAL_HASH_MISMATCH", "Item source file contents changed since planning: \(change.path).", path: change.path)]
        }
        return []
    }

    private static func isContained(_ url: URL, in root: URL) -> Bool {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        return path == rootPath || path.hasPrefix(rootPath + "/")
    }

    private static func pathDiagnostic(_ code: String, _ message: String, path: String) -> Diagnostic {
        Diagnostic(severity: .error, code: code, message: message, span: SourceSpan(relativePath: path, startLine: 1))
    }
}

private struct ItemCatalogDescriptor {
    let profile: GameProfile
    let itemPath: String
    let descriptionPath: String?
    let tableSymbol: String
    let entryStyle: CInitializerEntryStyle
    let idField: String?
    let supportsRowEditing: Bool
    let supportsDescriptionEditing: Bool

    var supportsItemCatalogParsing: Bool {
        supportsRowEditing || supportsDescriptionEditing
    }

    static func descriptor(for profile: GameProfile) -> ItemCatalogDescriptor? {
        switch profile {
        case .pokeemerald:
            ItemCatalogDescriptor(profile: profile, itemPath: "src/data/items.h", descriptionPath: "src/data/text/item_descriptions.h", tableSymbol: "gItems", entryStyle: .bracketed, idField: nil, supportsRowEditing: true, supportsDescriptionEditing: true)
        case .pokefirered:
            ItemCatalogDescriptor(profile: profile, itemPath: "src/data/items.h", descriptionPath: "src/data/items.h", tableSymbol: "gItems", entryStyle: .positional, idField: "itemId", supportsRowEditing: false, supportsDescriptionEditing: true)
        case .pokeruby:
            ItemCatalogDescriptor(profile: profile, itemPath: "src/data/items_en.h", descriptionPath: nil, tableSymbol: "gItems", entryStyle: .positional, idField: "itemId", supportsRowEditing: false, supportsDescriptionEditing: false)
        case .pokeemeraldExpansion:
            ItemCatalogDescriptor(profile: profile, itemPath: "src/data/items.h", descriptionPath: nil, tableSymbol: "gItemsInfo", entryStyle: .bracketed, idField: nil, supportsRowEditing: false, supportsDescriptionEditing: false)
        default:
            nil
        }
    }
}

private struct ItemDescriptionText {
    let symbol: String
    let text: String
    let span: SourceSpan
    let startOffset: Int
    let endOffset: Int
    let usesStatic: Bool
}

private struct ItemFieldChange {
    let key: String
    let replacement: String
}

private struct ItemFieldRange {
    let key: String
    let start: Int
    let end: Int
}

private enum ItemFieldPatcher {
    static func patch(
        entryBody: String,
        changes: [ItemFieldChange],
        diagnostics: inout [Diagnostic],
        span: SourceSpan
    ) -> String? {
        let ranges = Dictionary(uniqueKeysWithValues: fieldRanges(in: entryBody).map { ($0.key, $0) })
        var characters = Array(entryBody)
        var replacements: [(range: ItemFieldRange, value: String)] = []
        for change in changes {
            guard let range = ranges[change.key] else {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "ITEM_FIELD_MISSING",
                        message: "Cannot edit \(change.key) because the existing item entry does not contain that top-level field.",
                        span: span
                    )
                )
                continue
            }
            guard !change.replacement.isEmpty else {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "ITEM_FIELD_REMOVAL_UNSUPPORTED",
                        message: "Removing item field values is not supported by the item planner.",
                        span: span
                    )
                )
                continue
            }
            replacements.append((range, change.replacement))
        }
        guard diagnostics.allSatisfy({ $0.severity != .error }) else { return nil }
        for replacement in replacements.sorted(by: { $0.range.start > $1.range.start }) {
            characters.replaceSubrange(replacement.range.start..<replacement.range.end, with: Array(replacement.value))
        }
        return String(characters)
    }

    private static func fieldRanges(in text: String) -> [ItemFieldRange] {
        let characters = Array(text)
        guard
            let equals = firstCharacter("=", in: characters, after: 0),
            let open = firstCharacter("{", in: characters, after: equals + 1),
            let close = matchingCloseBrace(in: characters, from: open)
        else {
            return []
        }

        var ranges: [ItemFieldRange] = []
        var index = open + 1
        var depth = 0
        var state = ItemScannerState.normal
        while index < close {
            let character = characters[index]
            let next = index + 1 < characters.count ? characters[index + 1] : nil
            updateState(&state, character: character, next: next, index: &index)

            if state == .normal {
                if character == "{" || character == "(" || character == "[" {
                    depth += 1
                    index += 1
                    continue
                } else if character == "}" || character == ")" || character == "]" {
                    depth = max(0, depth - 1)
                    index += 1
                    continue
                }
            }

            guard state == .normal, depth == 0, character == "." else {
                index += 1
                continue
            }

            let nameStart = index + 1
            var nameEnd = nameStart
            while nameEnd < close, isIdentifier(characters[nameEnd]) {
                nameEnd += 1
            }
            guard nameEnd > nameStart else {
                index += 1
                continue
            }
            var cursor = nameEnd
            while cursor < close, characters[cursor].isWhitespace {
                cursor += 1
            }
            guard cursor < close, characters[cursor] == "=" else {
                index += 1
                continue
            }
            cursor += 1
            while cursor < close, characters[cursor].isWhitespace {
                cursor += 1
            }

            let valueStart = cursor
            var valueEnd = cursor
            var valueDepth = 0
            var valueState = ItemScannerState.normal
            while valueEnd < close {
                let valueCharacter = characters[valueEnd]
                let valueNext = valueEnd + 1 < characters.count ? characters[valueEnd + 1] : nil
                updateState(&valueState, character: valueCharacter, next: valueNext, index: &valueEnd)

                if valueState == .normal {
                    if valueCharacter == "{" || valueCharacter == "(" || valueCharacter == "[" {
                        valueDepth += 1
                    } else if valueCharacter == "}" || valueCharacter == ")" || valueCharacter == "]" {
                        if valueDepth == 0 { break }
                        valueDepth -= 1
                    } else if valueCharacter == "," && valueDepth == 0 {
                        break
                    }
                }
                valueEnd += 1
            }

            var trimmedEnd = valueEnd
            while trimmedEnd > valueStart, characters[trimmedEnd - 1].isWhitespace {
                trimmedEnd -= 1
            }
            let key = String(characters[nameStart..<nameEnd])
            ranges.append(ItemFieldRange(key: key, start: valueStart, end: trimmedEnd))
            index = max(valueEnd, index + 1)
        }
        return ranges
    }
}

private enum ItemDescriptionScanner {
    static func descriptions(in text: String, relativePath: String) -> [String: ItemDescriptionText] {
        let pattern = #"(static\s+)?const\s+u8\s+([A-Za-z_][A-Za-z0-9_]*)\[\]\s*=\s*_\(\s*((?:"(?:\\.|[^"])*"\s*)+)\);"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return [:]
        }
        let nsText = text as NSString
        var result: [String: ItemDescriptionText] = [:]
        for match in regex.matches(in: text, range: NSRange(location: 0, length: nsText.length)) {
            guard match.numberOfRanges >= 4 else { continue }
            let symbol = nsText.substring(with: match.range(at: 2))
            let literalBlock = nsText.substring(with: match.range(at: 3))
            let description = quotedStrings(in: literalBlock)
                .map(unescapeCString)
                .joined(separator: "\n")
            let fullRange = match.range(at: 0)
            result[symbol] = ItemDescriptionText(
                symbol: symbol,
                text: description,
                span: SourceSpan(
                    relativePath: relativePath,
                    startLine: lineNumber(forUTF16Offset: fullRange.location, in: text),
                    endLine: lineNumber(forUTF16Offset: fullRange.location + fullRange.length, in: text)
                ),
                startOffset: fullRange.location,
                endOffset: fullRange.location + fullRange.length,
                usesStatic: match.range(at: 1).location != NSNotFound
            )
        }
        return result
    }

    private static func quotedStrings(in text: String) -> [String] {
        let characters = Array(text)
        var strings: [String] = []
        var index = 0
        while index < characters.count {
            guard characters[index] == "\"" else {
                index += 1
                continue
            }
            index += 1
            var value = ""
            while index < characters.count {
                let character = characters[index]
                if character == "\\" {
                    value.append(character)
                    index += 1
                    if index < characters.count {
                        value.append(characters[index])
                    }
                } else if character == "\"" {
                    break
                } else {
                    value.append(character)
                }
                index += 1
            }
            strings.append(value.trimmingCharacters(in: .whitespacesAndNewlines))
            index += 1
        }
        return strings
    }
}

private enum ItemScannerState: Equatable {
    case normal
    case lineComment
    case blockComment
    case string
    case character
}

private let itemFields = [
    "itemId", "name", "price", "holdEffect", "holdEffectParam",
    "description", "descriptionPage1", "descriptionPage2",
    "importance", "registrability", "pocket", "type",
    "fieldUseFunc", "battleUsage", "battleUseFunc", "secondaryId", "exitsBagOnUse"
]

private func readOnlyDiagnostic(profile: GameProfile, span: SourceSpan?) -> Diagnostic {
    Diagnostic(
        severity: .warning,
        code: "ITEM_CATALOG_READ_ONLY_PROFILE",
        message: "Item row editing is currently read-only for \(profile.rawValue); this slice only supports classic Emerald rows plus Emerald/FireRed item description text.",
        span: span
    )
}

private func compact(_ value: String?) -> String? {
    guard let value else { return nil }
    let compacted = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return compacted.isEmpty ? nil : compacted
}

private func unwrappedTextMacro(_ value: String?) -> String? {
    guard let value = compact(value) else { return nil }
    let pattern = #"^_\(\s*"((?:\\.|[^"])*)"\s*\)$"#
    if let match = regexMatches(pattern, in: value).first, match.count >= 2 {
        return unescapeCString(match[1])
    }
    let quoted = #"^"((?:\\.|[^"])*)"$"#
    if let match = regexMatches(quoted, in: value).first, match.count >= 2 {
        return unescapeCString(match[1])
    }
    return value
}

private func displayName(for itemID: String) -> String {
    let stripped = itemID.replacingOccurrences(of: "ITEM_", with: "")
    return stripped
        .split(separator: "_")
        .map { part in
            part.prefix(1).uppercased() + part.dropFirst().lowercased()
        }
        .joined(separator: " ")
}

private func preview(_ text: String) -> String {
    text.components(separatedBy: .newlines).prefix(12).joined(separator: "\n")
}

private func readText(_ url: URL) throws -> String {
    if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
        return utf8
    }
    return try String(contentsOf: url, encoding: .isoLatin1)
}

private func replaceLines(in text: String, span: SourceSpan, replacement: String) -> String {
    var lines = text.components(separatedBy: "\n")
    let hadTrailingNewline = lines.last == ""
    let start = max(0, span.startLine - 1)
    let end = min(max(start, span.endLine - 1), max(0, lines.count - 1))
    let replacementLines = replacement.components(separatedBy: "\n")
    if start <= end, start < lines.count {
        lines.replaceSubrange(start...end, with: replacementLines)
    }
    var joined = lines.joined(separator: "\n")
    if hadTrailingNewline, !joined.hasSuffix("\n") {
        joined.append("\n")
    }
    return joined
}

private func escapeCString(_ value: String) -> String {
    value
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: "\\n")
}

private func unescapeCString(_ value: String) -> String {
    var result = ""
    var iterator = value.makeIterator()
    while let character = iterator.next() {
        if character == "\\", let escaped = iterator.next() {
            switch escaped {
            case "n": result.append("\n")
            case "t": result.append("\t")
            case "\"": result.append("\"")
            case "\\": result.append("\\")
            default:
                result.append(escaped)
            }
        } else {
            result.append(character)
        }
    }
    return result
}

private func regexMatches(_ pattern: String, in text: String) -> [[String]] {
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
        return []
    }
    let nsText = text as NSString
    return regex.matches(in: text, range: NSRange(location: 0, length: nsText.length)).map { match in
        (0..<match.numberOfRanges).map { index in
            let range = match.range(at: index)
            guard range.location != NSNotFound else { return "" }
            return nsText.substring(with: range)
        }
    }
}

private func renderDescriptionDeclaration(symbol: String, text: String, usesStatic: Bool) -> String {
    let prefix = usesStatic ? "static const u8" : "const u8"
    let lines = text.components(separatedBy: "\n")
    if lines.count <= 1 {
        return "\(prefix) \(symbol)[] = _(\"" + escapeCString(text) + "\");"
    }
    let body = lines
        .map { "    \"\(escapeCString($0))\"" }
        .joined(separator: "\n")
    return "\(prefix) \(symbol)[] = _(\n\(body));"
}

private func lineNumber(forUTF16Offset offset: Int, in text: String) -> Int {
    let clamped = max(0, min(offset, (text as NSString).length))
    let prefix = (text as NSString).substring(to: clamped)
    return prefix.reduce(1) { count, character in
        character == "\n" ? count + 1 : count
    }
}

private func firstCharacter(_ needle: Character, in characters: [Character], after start: Int) -> Int? {
    var index = start
    var state = ItemScannerState.normal
    while index < characters.count {
        let character = characters[index]
        let next = index + 1 < characters.count ? characters[index + 1] : nil
        updateState(&state, character: character, next: next, index: &index)
        if state == .normal, character == needle {
            return index
        }
        index += 1
    }
    return nil
}

private func matchingCloseBrace(in characters: [Character], from openOffset: Int) -> Int? {
    var index = openOffset
    var depth = 0
    var state = ItemScannerState.normal
    while index < characters.count {
        let character = characters[index]
        let next = index + 1 < characters.count ? characters[index + 1] : nil
        updateState(&state, character: character, next: next, index: &index)
        if state == .normal {
            if character == "{" {
                depth += 1
            } else if character == "}" {
                depth -= 1
                if depth == 0 { return index }
            }
        }
        index += 1
    }
    return nil
}

private func updateState(_ state: inout ItemScannerState, character: Character, next: Character?, index: inout Int) {
    switch state {
    case .normal:
        if character == "/", next == "/" {
            state = .lineComment
            index += 1
        } else if character == "/", next == "*" {
            state = .blockComment
            index += 1
        } else if character == "\"" {
            state = .string
        } else if character == "'" {
            state = .character
        }
    case .lineComment:
        if character == "\n" {
            state = .normal
        }
    case .blockComment:
        if character == "*", next == "/" {
            state = .normal
            index += 1
        }
    case .string:
        if character == "\\" {
            index += 1
        } else if character == "\"" {
            state = .normal
        }
    case .character:
        if character == "\\" {
            index += 1
        } else if character == "'" {
            state = .normal
        }
    }
}

private func isIdentifier(_ character: Character) -> Bool {
    character == "_" || character.isLetter || character.isNumber
}
