import Foundation

public enum GraphicsEditOperationKind: String, Codable, Equatable {
    case metatileTile
    case metatileAttribute
    case paletteColor
}

public struct GraphicsEditOperation: Codable, Equatable, Identifiable {
    public let id: String
    public let kind: GraphicsEditOperationKind
    public let path: String
    public let summary: String
    public let metatileLocalID: Int?
    public let tileEntryIndex: Int?
    public let rawTileValue: UInt16?
    public let attributeWordSize: Int?
    public let rawAttributeValue: UInt32?
    public let paletteColorIndex: Int?
    public let red: UInt8?
    public let green: UInt8?
    public let blue: UInt8?

    public init(
        id: String = UUID().uuidString,
        kind: GraphicsEditOperationKind,
        path: String,
        summary: String,
        metatileLocalID: Int? = nil,
        tileEntryIndex: Int? = nil,
        rawTileValue: UInt16? = nil,
        attributeWordSize: Int? = nil,
        rawAttributeValue: UInt32? = nil,
        paletteColorIndex: Int? = nil,
        red: UInt8? = nil,
        green: UInt8? = nil,
        blue: UInt8? = nil
    ) {
        self.id = id
        self.kind = kind
        self.path = path
        self.summary = summary
        self.metatileLocalID = metatileLocalID
        self.tileEntryIndex = tileEntryIndex
        self.rawTileValue = rawTileValue
        self.attributeWordSize = attributeWordSize
        self.rawAttributeValue = rawAttributeValue
        self.paletteColorIndex = paletteColorIndex
        self.red = red
        self.green = green
        self.blue = blue
    }

    public static func metatileTile(
        path: String,
        metatileLocalID: Int,
        tileEntryIndex: Int,
        rawTileValue: UInt16
    ) -> GraphicsEditOperation {
        GraphicsEditOperation(
            kind: .metatileTile,
            path: path,
            summary: "Update metatile tile word",
            metatileLocalID: metatileLocalID,
            tileEntryIndex: tileEntryIndex,
            rawTileValue: rawTileValue
        )
    }

    public static func metatileAttribute(
        path: String,
        metatileLocalID: Int,
        rawAttributeValue: UInt32,
        wordSize: Int = 2
    ) -> GraphicsEditOperation {
        GraphicsEditOperation(
            kind: .metatileAttribute,
            path: path,
            summary: "Update metatile attributes",
            metatileLocalID: metatileLocalID,
            attributeWordSize: wordSize,
            rawAttributeValue: rawAttributeValue
        )
    }

    public static func paletteColor(
        path: String,
        colorIndex: Int,
        red: UInt8,
        green: UInt8,
        blue: UInt8
    ) -> GraphicsEditOperation {
        GraphicsEditOperation(
            kind: .paletteColor,
            path: path,
            summary: "Update palette color",
            paletteColorIndex: colorIndex,
            red: red,
            green: green,
            blue: blue
        )
    }
}

public struct GraphicsEditDraft: Codable, Equatable, Identifiable {
    public var id: String { "\(tilesetSymbol)::\(operations.map(\.id).joined(separator: ","))" }

    public let tilesetSymbol: String
    public var operations: [GraphicsEditOperation]

    public init(tilesetSymbol: String, operations: [GraphicsEditOperation] = []) {
        self.tilesetSymbol = tilesetSymbol
        self.operations = operations
    }
}

public struct GraphicsEditFileChange: Codable, Equatable, Identifiable {
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

public struct GraphicsEditPlan: Codable, Equatable, Identifiable {
    public let id: String
    public let rootPath: String
    public let draft: GraphicsEditDraft
    public let changes: [GraphicsEditFileChange]
    public let diagnostics: [Diagnostic]
    public let mutationPlan: MutationPlan
    public let backupRelativeRoot: String

    public init(
        id: String = UUID().uuidString,
        rootPath: String,
        draft: GraphicsEditDraft,
        changes: [GraphicsEditFileChange],
        diagnostics: [Diagnostic],
        mutationPlan: MutationPlan,
        backupRelativeRoot: String
    ) {
        self.id = id
        self.rootPath = rootPath
        self.draft = draft
        self.changes = changes
        self.diagnostics = diagnostics
        self.mutationPlan = mutationPlan
        self.backupRelativeRoot = backupRelativeRoot
    }

    public func validateApplyability(fileManager: FileManager = .default) -> GraphicsEditApplyability {
        GraphicsEditApplySafety.applyability(for: self, fileManager: fileManager)
    }

    public var isApplyable: Bool {
        validateApplyability().isApplyable
    }
}

public struct GraphicsEditApplyability: Codable, Equatable {
    public let isApplyable: Bool
    public let diagnostics: [Diagnostic]

    public init(isApplyable: Bool, diagnostics: [Diagnostic]) {
        self.isApplyable = isApplyable
        self.diagnostics = diagnostics
    }
}

public struct AppliedGraphicsFileChange: Codable, Equatable, Identifiable {
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

public struct GraphicsApplyResult: Codable, Equatable, Identifiable {
    public let id: String
    public let backupRootPath: String
    public let appliedChanges: [AppliedGraphicsFileChange]
    public let diagnostics: [Diagnostic]

    public init(
        id: String = UUID().uuidString,
        backupRootPath: String,
        appliedChanges: [AppliedGraphicsFileChange],
        diagnostics: [Diagnostic] = []
    ) {
        self.id = id
        self.backupRootPath = backupRootPath
        self.appliedChanges = appliedChanges
        self.diagnostics = diagnostics
    }
}

public enum GraphicsMutationPlanner {
    public static func plan(
        rootPath: String,
        draft: GraphicsEditDraft,
        fileManager: FileManager = .default
    ) -> GraphicsEditPlan {
        let root = URL(fileURLWithPath: rootPath).standardizedFileURL
        var diagnostics: [Diagnostic] = []
        var draftsByPath: [String: GraphicsSourceDraft] = [:]

        for operation in draft.operations {
            guard validateSourcePath(operation.path, root: root, fileManager: fileManager, diagnostics: &diagnostics) else {
                continue
            }
            var source = draftsByPath[operation.path]
            if source == nil {
                let url = root.appendingPathComponent(operation.path)
                guard let data = try? Data(contentsOf: url) else {
                    diagnostics.append(pathDiagnostic("GRAPHICS_SOURCE_UNREADABLE", "Graphics source file could not be read before planning: \(operation.path).", path: operation.path))
                    continue
                }
                source = GraphicsSourceDraft(path: operation.path, originalData: data, data: data, summaries: [])
            }
            guard var source else { continue }
            apply(operation, to: &source, diagnostics: &diagnostics)
            draftsByPath[operation.path] = source
        }

        let changes = draftsByPath.values
            .filter { $0.data != $0.originalData }
            .sorted { $0.path < $1.path }
            .map { source in
                GraphicsEditFileChange(
                    path: source.path,
                    summary: source.summaries.sorted().joined(separator: "; "),
                    originalByteCount: source.originalData.count,
                    originalSHA1: pokemonHackSHA1Hex(source.originalData),
                    newByteCount: source.data.count,
                    newData: source.data,
                    textPreview: textPreview(for: source)
                )
            }

        let mutationPlan = MutationPlan(
            title: "Apply graphics edits to \(draft.tilesetSymbol)",
            summary: "\(changes.count) source file change(s) for graphics data.",
            changes: changes.map {
                PlannedChange(path: $0.path, summary: $0.summary, span: SourceSpan(relativePath: $0.path, startLine: 1))
            },
            diagnostics: diagnostics,
            requiresExplicitApply: true
        )
        return GraphicsEditPlan(
            rootPath: rootPath,
            draft: draft,
            changes: changes,
            diagnostics: diagnostics,
            mutationPlan: mutationPlan,
            backupRelativeRoot: ".pokemonhackstudio/backups/\(backupTimestamp())"
        )
    }

    private static func validateSourcePath(_ path: String, root: URL, fileManager: FileManager, diagnostics: inout [Diagnostic]) -> Bool {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            diagnostics.append(Diagnostic(severity: .error, code: "GRAPHICS_SOURCE_PATH_MISSING", message: "Graphics edit path is missing."))
            return false
        }
        guard !trimmed.hasPrefix("/") else {
            diagnostics.append(pathDiagnostic("GRAPHICS_SOURCE_PATH_ABSOLUTE", "Graphics edit paths must be project-relative: \(path).", path: path))
            return false
        }
        let destination = root.appendingPathComponent(trimmed).standardizedFileURL
        let pathDiagnostics = SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
            trimmed,
            root: root,
            fileManager: fileManager,
            codePrefix: "GRAPHICS_SOURCE",
            subject: "Graphics edit path"
        )
        guard pathDiagnostics.isEmpty else {
            diagnostics.append(contentsOf: pathDiagnostics)
            return false
        }
        guard !isBlockedSourcePath(trimmed) else {
            diagnostics.append(pathDiagnostic("GRAPHICS_SOURCE_PATH_BLOCKED", "Graphics authoring cannot write generated, build, cache, backup, ROM, or reference paths: \(path).", path: path))
            return false
        }
        guard fileManager.fileExists(atPath: destination.path) else {
            diagnostics.append(pathDiagnostic("GRAPHICS_SOURCE_MISSING", "Graphics source file does not exist: \(path).", path: path))
            return false
        }
        return true
    }

    private static func apply(
        _ operation: GraphicsEditOperation,
        to source: inout GraphicsSourceDraft,
        diagnostics: inout [Diagnostic]
    ) {
        switch operation.kind {
        case .metatileTile:
            applyMetatileTile(operation, to: &source, diagnostics: &diagnostics)
        case .metatileAttribute:
            applyMetatileAttribute(operation, to: &source, diagnostics: &diagnostics)
        case .paletteColor:
            applyPaletteColor(operation, to: &source, diagnostics: &diagnostics)
        }
    }

    private static func applyMetatileTile(
        _ operation: GraphicsEditOperation,
        to source: inout GraphicsSourceDraft,
        diagnostics: inout [Diagnostic]
    ) {
        guard operation.path.lowercased().hasSuffix("metatiles.bin") else {
            diagnostics.append(pathDiagnostic("GRAPHICS_METATILE_TILE_PATH_UNSUPPORTED", "Metatile tile edits currently write existing metatiles.bin sources only.", path: operation.path))
            return
        }
        guard let metatileLocalID = operation.metatileLocalID, metatileLocalID >= 0,
              let tileEntryIndex = operation.tileEntryIndex, (0..<8).contains(tileEntryIndex),
              let rawValue = operation.rawTileValue
        else {
            diagnostics.append(pathDiagnostic("GRAPHICS_METATILE_TILE_INCOMPLETE", "Metatile tile edit needs a non-negative metatile ID, tile index 0...7, and raw tile value.", path: operation.path))
            return
        }
        let offset = (metatileLocalID * 8 + tileEntryIndex) * 2
        guard offset + 2 <= source.data.count else {
            diagnostics.append(pathDiagnostic("GRAPHICS_METATILE_TILE_OUT_OF_RANGE", "Metatile \(metatileLocalID) tile entry \(tileEntryIndex) is outside \(operation.path).", path: operation.path))
            return
        }
        writeUInt16(rawValue, to: &source.data, offset: offset)
        source.summaries.insert(operation.summary)
    }

    private static func applyMetatileAttribute(
        _ operation: GraphicsEditOperation,
        to source: inout GraphicsSourceDraft,
        diagnostics: inout [Diagnostic]
    ) {
        guard operation.path.lowercased().hasSuffix("metatile_attributes.bin") else {
            diagnostics.append(pathDiagnostic("GRAPHICS_METATILE_ATTRIBUTE_PATH_UNSUPPORTED", "Metatile attribute edits currently write existing metatile_attributes.bin sources only.", path: operation.path))
            return
        }
        guard let metatileLocalID = operation.metatileLocalID, metatileLocalID >= 0,
              let rawValue = operation.rawAttributeValue
        else {
            diagnostics.append(pathDiagnostic("GRAPHICS_METATILE_ATTRIBUTE_INCOMPLETE", "Metatile attribute edit needs a non-negative metatile ID and raw attribute value.", path: operation.path))
            return
        }
        let wordSize = max(operation.attributeWordSize ?? 2, 2)
        guard wordSize == 2 || wordSize == 4 else {
            diagnostics.append(pathDiagnostic("GRAPHICS_METATILE_ATTRIBUTE_WORD_SIZE", "Metatile attribute word size must be 2 or 4 bytes.", path: operation.path))
            return
        }
        let offset = metatileLocalID * wordSize
        guard offset + wordSize <= source.data.count else {
            diagnostics.append(pathDiagnostic("GRAPHICS_METATILE_ATTRIBUTE_OUT_OF_RANGE", "Metatile \(metatileLocalID) attribute is outside \(operation.path).", path: operation.path))
            return
        }
        if wordSize == 4 {
            writeUInt32(rawValue, to: &source.data, offset: offset)
        } else {
            writeUInt16(UInt16(rawValue & 0xffff), to: &source.data, offset: offset)
        }
        source.summaries.insert(operation.summary)
    }

    private static func applyPaletteColor(
        _ operation: GraphicsEditOperation,
        to source: inout GraphicsSourceDraft,
        diagnostics: inout [Diagnostic]
    ) {
        guard let colorIndex = operation.paletteColorIndex, colorIndex >= 0,
              let red = operation.red,
              let green = operation.green,
              let blue = operation.blue
        else {
            diagnostics.append(pathDiagnostic("GRAPHICS_PALETTE_COLOR_INCOMPLETE", "Palette edit needs a non-negative color index and RGB values.", path: operation.path))
            return
        }
        if operation.path.lowercased().hasSuffix(".gbapal") {
            let offset = colorIndex * 2
            guard offset + 2 <= source.data.count else {
                diagnostics.append(pathDiagnostic("GRAPHICS_PALETTE_COLOR_OUT_OF_RANGE", "Palette color \(colorIndex) is outside \(operation.path).", path: operation.path))
                return
            }
            writeUInt16(gbaColor(red: red, green: green, blue: blue), to: &source.data, offset: offset)
            source.summaries.insert(operation.summary)
            return
        }

        if operation.path.lowercased().hasSuffix(".pal") {
            guard
                let text = String(data: source.data, encoding: .utf8),
                let patched = patchJASCPalette(text: text, colorIndex: colorIndex, red: red, green: green, blue: blue, path: operation.path, diagnostics: &diagnostics),
                let data = patched.data(using: .utf8)
            else {
                return
            }
            source.data = data
            source.summaries.insert(operation.summary)
            return
        }

        diagnostics.append(pathDiagnostic("GRAPHICS_PALETTE_FORMAT_UNSUPPORTED", "Palette color edits currently support .gbapal and JASC .pal files only.", path: operation.path))
    }

    private static func patchJASCPalette(
        text: String,
        colorIndex: Int,
        red: UInt8,
        green: UInt8,
        blue: UInt8,
        path: String,
        diagnostics: inout [Diagnostic]
    ) -> String? {
        var lines = text.components(separatedBy: "\n")
        guard lines.count >= 4, lines[0].trimmingCharacters(in: .whitespacesAndNewlines) == "JASC-PAL" else {
            diagnostics.append(pathDiagnostic("GRAPHICS_PALETTE_JASC_UNSUPPORTED", "Palette \(path) is not a supported JASC-PAL file.", path: path))
            return nil
        }
        let entryIndex = colorIndex + 3
        guard lines.indices.contains(entryIndex) else {
            diagnostics.append(pathDiagnostic("GRAPHICS_PALETTE_COLOR_OUT_OF_RANGE", "Palette color \(colorIndex) is outside \(path).", path: path))
            return nil
        }
        lines[entryIndex] = "\(red) \(green) \(blue)"
        return lines.joined(separator: "\n")
    }

    private static func textPreview(for source: GraphicsSourceDraft) -> String? {
        if source.path.lowercased().hasSuffix(".pal"),
           let text = String(data: source.data, encoding: .utf8)
        {
            return text.components(separatedBy: "\n").prefix(24).joined(separator: "\n")
        }
        return "\(source.data.count) byte graphics source update"
    }
}

public enum GraphicsMutationApplier {
    public static func apply(plan: GraphicsEditPlan, fileManager: FileManager = .default) throws -> GraphicsApplyResult {
        let root = URL(fileURLWithPath: plan.rootPath).standardizedFileURL
        let backupRoot = root.appendingPathComponent(plan.backupRelativeRoot)
        let applyability = plan.validateApplyability(fileManager: fileManager)
        guard applyability.isApplyable else {
            return GraphicsApplyResult(backupRootPath: backupRoot.path, appliedChanges: [], diagnostics: applyability.diagnostics)
        }
        guard !plan.changes.isEmpty else {
            return GraphicsApplyResult(backupRootPath: backupRoot.path, appliedChanges: [])
        }
        let backupDiagnostics = SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
            plan.backupRelativeRoot,
            root: root,
            fileManager: fileManager,
            codePrefix: "GRAPHICS_APPLY_BACKUP",
            subject: "Graphics backup path"
        )
        guard backupDiagnostics.isEmpty else {
            return GraphicsApplyResult(backupRootPath: backupRoot.path, appliedChanges: [], diagnostics: backupDiagnostics)
        }

        try fileManager.createDirectory(at: backupRoot, withIntermediateDirectories: true)
        var applied: [AppliedGraphicsFileChange] = []
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
            applied.append(AppliedGraphicsFileChange(path: change.path, backupPath: backup.path, byteCount: change.newData.count))
        }
        return GraphicsApplyResult(backupRootPath: backupRoot.path, appliedChanges: applied)
    }
}

private struct GraphicsSourceDraft {
    let path: String
    let originalData: Data
    var data: Data
    var summaries: Set<String>
}

private enum GraphicsEditApplySafety {
    static func applyability(for plan: GraphicsEditPlan, fileManager: FileManager) -> GraphicsEditApplyability {
        var diagnostics = plan.diagnostics.filter { $0.severity == .error }
        let root = URL(fileURLWithPath: plan.rootPath).standardizedFileURL
        guard !plan.rootPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            diagnostics.append(Diagnostic(severity: .error, code: "GRAPHICS_APPLY_ROOT_MISSING", message: "Graphics apply root path is missing."))
            return GraphicsEditApplyability(isApplyable: false, diagnostics: diagnostics)
        }
        guard fileManager.fileExists(atPath: root.path) else {
            diagnostics.append(Diagnostic(severity: .error, code: "GRAPHICS_APPLY_ROOT_MISSING", message: "Graphics apply root does not exist: \(plan.rootPath)."))
            return GraphicsEditApplyability(isApplyable: false, diagnostics: diagnostics)
        }
        guard !plan.changes.isEmpty else {
            diagnostics.append(Diagnostic(severity: .warning, code: "GRAPHICS_APPLY_NO_CHANGES", message: "No graphics source changes are staged."))
            return GraphicsEditApplyability(isApplyable: false, diagnostics: diagnostics)
        }
        for change in plan.changes {
            diagnostics.append(contentsOf: diagnosticsForChange(change, root: root, fileManager: fileManager))
        }
        return GraphicsEditApplyability(isApplyable: diagnostics.allSatisfy { $0.severity != .error }, diagnostics: diagnostics)
    }

    private static func diagnosticsForChange(_ change: GraphicsEditFileChange, root: URL, fileManager: FileManager) -> [Diagnostic] {
        let destination = root.appendingPathComponent(change.path).standardizedFileURL
        let pathDiagnostics = SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
            change.path,
            root: root,
            fileManager: fileManager,
            codePrefix: "GRAPHICS_APPLY",
            subject: "Graphics apply path"
        )
        guard pathDiagnostics.isEmpty else {
            return pathDiagnostics
        }
        guard fileManager.fileExists(atPath: destination.path) else {
            return [pathDiagnostic("GRAPHICS_APPLY_SOURCE_MISSING", "Graphics source file is missing before apply: \(change.path).", path: change.path)]
        }
        guard let currentData = try? Data(contentsOf: destination) else {
            return [pathDiagnostic("GRAPHICS_APPLY_SOURCE_UNREADABLE", "Graphics source file could not be read before apply: \(change.path).", path: change.path)]
        }
        guard currentData.count == change.originalByteCount else {
            return [pathDiagnostic("GRAPHICS_APPLY_ORIGINAL_SIZE_MISMATCH", "Graphics source file changed size since planning: \(change.path).", path: change.path)]
        }
        if let originalSHA1 = change.originalSHA1, pokemonHackSHA1Hex(currentData) != originalSHA1 {
            return [pathDiagnostic("GRAPHICS_APPLY_ORIGINAL_HASH_MISMATCH", "Graphics source file contents changed since planning: \(change.path).", path: change.path)]
        }
        return []
    }
}

private func isBlockedSourcePath(_ path: String) -> Bool {
    let components = path.split(separator: "/").map(String.init)
    if components.contains(where: { [".git", "build", "builds", "tools", "references", ".pokemonhackstudio", "DerivedData"].contains($0) }) {
        return true
    }
    let lowercased = path.lowercased()
    return [".gba", ".sav", ".sgm", ".elf", ".map", ".o", ".ips", ".bps", ".ups", ".iso", ".gcm"].contains {
        lowercased.hasSuffix($0)
    }
}

private func writeUInt16(_ value: UInt16, to data: inout Data, offset: Int) {
    data[offset] = UInt8(value & 0xff)
    data[offset + 1] = UInt8((value >> 8) & 0xff)
}

private func writeUInt32(_ value: UInt32, to data: inout Data, offset: Int) {
    data[offset] = UInt8(value & 0xff)
    data[offset + 1] = UInt8((value >> 8) & 0xff)
    data[offset + 2] = UInt8((value >> 16) & 0xff)
    data[offset + 3] = UInt8((value >> 24) & 0xff)
}

private func gbaColor(red: UInt8, green: UInt8, blue: UInt8) -> UInt16 {
    let r = UInt16(red >> 3)
    let g = UInt16(green >> 3)
    let b = UInt16(blue >> 3)
    return r | (g << 5) | (b << 10)
}

private func backupTimestamp() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    return "\(formatter.string(from: Date()))-\(UUID().uuidString.prefix(8))"
}

private func pathDiagnostic(_ code: String, _ message: String, path: String) -> Diagnostic {
    Diagnostic(severity: .error, code: code, message: message, span: SourceSpan(relativePath: path, startLine: 1))
}
