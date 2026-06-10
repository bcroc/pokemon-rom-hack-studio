import Foundation

public struct ScriptCommandEditDraft: Codable, Equatable {
    public let sourcePath: String
    public let line: Int
    public let commandName: String?
    public let argumentIndex: Int
    public let replacementArgument: String

    public init(
        sourcePath: String,
        line: Int,
        commandName: String? = nil,
        argumentIndex: Int,
        replacementArgument: String
    ) {
        self.sourcePath = sourcePath
        self.line = line
        self.commandName = commandName
        self.argumentIndex = argumentIndex
        self.replacementArgument = replacementArgument
    }
}

public struct ScriptCommandEditFileChange: Codable, Equatable, Identifiable {
    public var id: String { path }

    public let path: String
    public let summary: String
    public let originalByteCount: Int
    public let originalSHA1: String?
    public let newByteCount: Int
    public let newData: Data
    public let textPreview: String

    public init(
        path: String,
        summary: String,
        originalByteCount: Int,
        originalSHA1: String?,
        newByteCount: Int,
        newData: Data,
        textPreview: String
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

public struct ScriptCommandEditPlan: Codable, Equatable, Identifiable {
    public let id: String
    public let rootPath: String
    public let draft: ScriptCommandEditDraft
    public let changes: [ScriptCommandEditFileChange]
    public let poryscriptReport: PoryscriptCompatibilityReport
    public let diagnostics: [Diagnostic]
    public let mutationPlan: MutationPlan
    public let backupRelativeRoot: String

    public init(
        id: String = UUID().uuidString,
        rootPath: String,
        draft: ScriptCommandEditDraft,
        changes: [ScriptCommandEditFileChange],
        poryscriptReport: PoryscriptCompatibilityReport,
        diagnostics: [Diagnostic],
        mutationPlan: MutationPlan,
        backupRelativeRoot: String
    ) {
        self.id = id
        self.rootPath = rootPath
        self.draft = draft
        self.changes = changes
        self.poryscriptReport = poryscriptReport
        self.diagnostics = diagnostics
        self.mutationPlan = mutationPlan
        self.backupRelativeRoot = backupRelativeRoot
    }

    public var isApplyable: Bool {
        validateApplyability().isApplyable
    }

    public func validateApplyability(fileManager: FileManager = .default) -> ScriptCommandEditApplyability {
        ScriptCommandEditApplySafety.applyability(for: self, fileManager: fileManager)
    }
}

public struct ScriptCommandEditApplyability: Codable, Equatable {
    public let isApplyable: Bool
    public let diagnostics: [Diagnostic]

    public init(isApplyable: Bool, diagnostics: [Diagnostic]) {
        self.isApplyable = isApplyable
        self.diagnostics = diagnostics
    }
}

public struct AppliedScriptCommandEditChange: Codable, Equatable, Identifiable {
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

public struct ScriptCommandEditApplyResult: Codable, Equatable {
    public let backupRootPath: String
    public let appliedChanges: [AppliedScriptCommandEditChange]
    public let diagnostics: [Diagnostic]

    public init(backupRootPath: String, appliedChanges: [AppliedScriptCommandEditChange], diagnostics: [Diagnostic] = []) {
        self.backupRootPath = backupRootPath
        self.appliedChanges = appliedChanges
        self.diagnostics = diagnostics
    }
}

public enum ScriptCommandEditPlanner {
    public static func plan(
        rootPath: String,
        draft: ScriptCommandEditDraft,
        fileManager: FileManager = .default
    ) -> ScriptCommandEditPlan {
        let root = URL(fileURLWithPath: rootPath).standardizedFileURL
        let poryscriptReport = PoryscriptCompatibilityScanner.scan(rootPath: root.path, fileManager: fileManager)
        var diagnostics = validateDraft(draft)
        diagnostics.append(contentsOf: poryscriptReport.blockingDiagnostics(for: draft.sourcePath))

        let sourceURL = root.appendingPathComponent(draft.sourcePath).standardizedFileURL
        var changes: [ScriptCommandEditFileChange] = []
        if diagnostics.allSatisfy({ $0.severity != .error }) {
            let pathDiagnostics = SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
                draft.sourcePath,
                root: root,
                fileManager: fileManager,
                codePrefix: "SCRIPT_COMMAND_EDIT",
                subject: "Script command edit path",
                spanLine: draft.line
            )
            if !pathDiagnostics.isEmpty {
                diagnostics.append(contentsOf: pathDiagnostics)
            } else if !fileManager.fileExists(atPath: sourceURL.path) {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "SCRIPT_COMMAND_EDIT_SOURCE_MISSING",
                        message: "Script source is missing: \(draft.sourcePath).",
                        span: SourceSpan(relativePath: draft.sourcePath, startLine: draft.line)
                    )
                )
            } else if let text = try? readText(sourceURL), let originalData = text.data(using: .utf8) {
                let plannedLine = plannedLineEdit(text: text, draft: draft)
                diagnostics.append(contentsOf: plannedLine.diagnostics)
                if diagnostics.allSatisfy({ $0.severity != .error }),
                   let replacementLine = plannedLine.replacementLine
                {
                    let newText = replaceLine(in: text, lineNumber: draft.line, replacement: replacementLine)
                    if newText != text, let newData = newText.data(using: .utf8) {
                        changes.append(
                            ScriptCommandEditFileChange(
                                path: draft.sourcePath,
                                summary: "Edit argument \(draft.argumentIndex) of \(plannedLine.commandName ?? "script command") on line \(draft.line).",
                                originalByteCount: originalData.count,
                                originalSHA1: pokemonHackSHA1Hex(originalData),
                                newByteCount: newData.count,
                                newData: newData,
                                textPreview: replacementLine
                            )
                        )
                    }
                }
            } else {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "SCRIPT_COMMAND_EDIT_SOURCE_UNREADABLE",
                        message: "Script source could not be read as text: \(draft.sourcePath).",
                        span: SourceSpan(relativePath: draft.sourcePath, startLine: draft.line)
                    )
                )
            }
        }

        if changes.isEmpty, diagnostics.allSatisfy({ $0.severity != .error }) {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "SCRIPT_COMMAND_EDIT_NO_CHANGE",
                    message: "The command argument already matches the requested value.",
                    span: SourceSpan(relativePath: draft.sourcePath, startLine: draft.line)
                )
            )
        }

        let mutationPlan = MutationPlan(
            title: "Edit script command argument",
            summary: "\(changes.count) source file change(s) for one native .inc command argument.",
            changes: changes.map {
                PlannedChange(path: $0.path, summary: $0.summary, span: SourceSpan(relativePath: $0.path, startLine: draft.line))
            },
            diagnostics: diagnostics,
            requiresExplicitApply: true
        )

        return ScriptCommandEditPlan(
            rootPath: root.path,
            draft: draft,
            changes: changes,
            poryscriptReport: poryscriptReport,
            diagnostics: diagnostics,
            mutationPlan: mutationPlan,
            backupRelativeRoot: ".pokemonhackstudio/backups/\(backupTimestamp())"
        )
    }

    private static func validateDraft(_ draft: ScriptCommandEditDraft) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        let span = SourceSpan(relativePath: draft.sourcePath, startLine: max(1, draft.line))
        if draft.sourcePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || draft.sourcePath.hasPrefix("/")
            || draft.sourcePath.split(separator: "/").contains("..")
        {
            diagnostics.append(Diagnostic(severity: .error, code: "SCRIPT_COMMAND_EDIT_PATH_UNSAFE", message: "Script command edit path must stay inside the project root.", span: span))
        }
        if !draft.sourcePath.lowercased().hasSuffix(".inc") {
            diagnostics.append(Diagnostic(severity: .error, code: "SCRIPT_COMMAND_EDIT_SOURCE_NOT_INC", message: "Script command editing is limited to native .inc source files.", span: span))
        } else if !MapScriptIndex.isEditableScriptPath(draft.sourcePath) {
            diagnostics.append(blockedSourceDiagnostic(for: draft.sourcePath, span: span))
        }
        if draft.line < 1 {
            diagnostics.append(Diagnostic(severity: .error, code: "SCRIPT_COMMAND_EDIT_LINE_INVALID", message: "Script command edit line must be 1 or greater.", span: span))
        }
        if draft.argumentIndex < 0 {
            diagnostics.append(Diagnostic(severity: .error, code: "SCRIPT_COMMAND_EDIT_ARGUMENT_INDEX_INVALID", message: "Script command edit argument index must be zero or greater.", span: span))
        }
        if draft.replacementArgument.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draft.replacementArgument.contains("\n") || draft.replacementArgument.contains("\r") {
            diagnostics.append(Diagnostic(severity: .error, code: "SCRIPT_COMMAND_EDIT_ARGUMENT_INVALID", message: "Replacement argument must be one non-empty line.", span: span))
        }
        return diagnostics
    }

    private static func blockedSourceDiagnostic(for path: String, span: SourceSpan) -> Diagnostic {
        if path.hasPrefix("data/scripts/") || path.localizedCaseInsensitiveContains("shared") {
            return Diagnostic(
                severity: .error,
                code: "SCRIPT_COMMAND_EDIT_SHARED_SOURCE_BLOCKED",
                message: "Native command edits are blocked for shared script files; this planner only edits existing arguments in data/maps/*/scripts.inc.",
                span: span
            )
        }
        return Diagnostic(
            severity: .error,
            code: "SCRIPT_COMMAND_EDIT_GENERATED_SOURCE_BLOCKED",
            message: "Native command edits are blocked for generated or unsupported .inc paths; this planner only edits existing arguments in data/maps/*/scripts.inc.",
            span: span
        )
    }

    private static func plannedLineEdit(text: String, draft: ScriptCommandEditDraft) -> (replacementLine: String?, commandName: String?, diagnostics: [Diagnostic]) {
        let lines = text.components(separatedBy: "\n")
        guard draft.line <= lines.count else {
            return (
                nil,
                nil,
                [
                    Diagnostic(
                        severity: .error,
                        code: "SCRIPT_COMMAND_EDIT_LINE_MISSING",
                        message: "\(draft.sourcePath) has no line \(draft.line).",
                        span: SourceSpan(relativePath: draft.sourcePath, startLine: draft.line)
                    )
                ]
            )
        }

        let originalLine = lines[draft.line - 1]
        let parsed = ParsedScriptCommandLine(line: originalLine, sourcePath: draft.sourcePath, lineNumber: draft.line)
        var diagnostics = parsed.diagnostics
        if let commandName = draft.commandName, parsed.commandName != nil, parsed.commandName != commandName {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "SCRIPT_COMMAND_EDIT_COMMAND_MISMATCH",
                    message: "Expected command \(commandName), but line \(draft.line) contains \(parsed.commandName ?? "none").",
                    span: SourceSpan(relativePath: draft.sourcePath, startLine: draft.line)
                )
            )
        }
        guard diagnostics.allSatisfy({ $0.severity != .error }), let commandName = parsed.commandName else {
            return (nil, parsed.commandName, diagnostics)
        }
        guard parsed.arguments.indices.contains(draft.argumentIndex) else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "SCRIPT_COMMAND_EDIT_ARGUMENT_MISSING",
                    message: "\(commandName) has \(parsed.arguments.count) argument(s); index \(draft.argumentIndex) cannot be edited without inserting a new argument.",
                    span: SourceSpan(relativePath: draft.sourcePath, startLine: draft.line)
                )
            )
            return (nil, commandName, diagnostics)
        }

        var arguments = parsed.arguments
        arguments[draft.argumentIndex] = draft.replacementArgument.trimmingCharacters(in: .whitespaces)
        return (parsed.render(arguments: arguments), commandName, diagnostics)
    }
}

public enum ScriptCommandEditApplier {
    public static func apply(plan: ScriptCommandEditPlan, fileManager: FileManager = .default) throws -> ScriptCommandEditApplyResult {
        let root = URL(fileURLWithPath: plan.rootPath).standardizedFileURL
        let backupRoot = root.appendingPathComponent(plan.backupRelativeRoot)
        let applyability = plan.validateApplyability(fileManager: fileManager)
        guard applyability.isApplyable else {
            return ScriptCommandEditApplyResult(backupRootPath: backupRoot.path, appliedChanges: [], diagnostics: applyability.diagnostics)
        }
        let backupDiagnostics = SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
            plan.backupRelativeRoot,
            root: root,
            fileManager: fileManager,
            codePrefix: "SCRIPT_COMMAND_EDIT_APPLY_BACKUP",
            subject: "Script backup path",
            spanLine: plan.draft.line
        )
        guard backupDiagnostics.isEmpty else {
            return ScriptCommandEditApplyResult(backupRootPath: backupRoot.path, appliedChanges: [], diagnostics: backupDiagnostics)
        }

        try fileManager.createDirectory(at: backupRoot, withIntermediateDirectories: true)
        var applied: [AppliedScriptCommandEditChange] = []
        for change in plan.changes {
            let destination = root.appendingPathComponent(change.path)
            let backup = backupRoot.appendingPathComponent(change.path)
            try fileManager.createDirectory(at: backup.deletingLastPathComponent(), withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: backup.path) {
                try fileManager.removeItem(at: backup)
            }
            try fileManager.copyItem(at: destination, to: backup)
            try change.newData.write(to: destination, options: .atomic)
            applied.append(AppliedScriptCommandEditChange(path: change.path, backupPath: backup.path, byteCount: change.newData.count))
        }
        return ScriptCommandEditApplyResult(backupRootPath: backupRoot.path, appliedChanges: applied)
    }
}

private struct ParsedScriptCommandLine {
    let originalLine: String
    let leadingWhitespace: String
    let commandName: String?
    let arguments: [String]
    let inlineComment: String?
    let diagnostics: [Diagnostic]

    init(line: String, sourcePath: String, lineNumber: Int) {
        originalLine = line
        let split = Self.splitInlineComment(line)
        let codePart = split.code
        inlineComment = split.comment
        leadingWhitespace = String(codePart.prefix { $0.isWhitespace })
        let trimmedCode = codePart.trimmingCharacters(in: .whitespaces)
        if trimmedCode.isEmpty || trimmedCode.hasPrefix("@") {
            commandName = nil
            arguments = []
            diagnostics = [
                Diagnostic(severity: .error, code: "SCRIPT_COMMAND_EDIT_NO_COMMAND", message: "Line \(lineNumber) does not contain a native .inc command.", span: SourceSpan(relativePath: sourcePath, startLine: lineNumber))
            ]
            return
        }
        if trimmedCode.hasPrefix("#") || trimmedCode.hasPrefix(".") || trimmedCode.hasSuffix(":") {
            commandName = nil
            arguments = []
            diagnostics = [
                Diagnostic(severity: .error, code: "SCRIPT_COMMAND_EDIT_UNSUPPORTED_LINE", message: "Line \(lineNumber) is not an editable command line.", span: SourceSpan(relativePath: sourcePath, startLine: lineNumber))
            ]
            return
        }

        let parts = trimmedCode.split(maxSplits: 1, whereSeparator: { $0.isWhitespace })
        guard let commandPart = parts.first else {
            commandName = nil
            arguments = []
            diagnostics = [
                Diagnostic(severity: .error, code: "SCRIPT_COMMAND_EDIT_NO_COMMAND", message: "Line \(lineNumber) does not contain a native .inc command.", span: SourceSpan(relativePath: sourcePath, startLine: lineNumber))
            ]
            return
        }
        commandName = String(commandPart)
        arguments = parts.count > 1 ? Self.splitArguments(String(parts[1])) : []
        diagnostics = []
    }

    func render(arguments: [String]) -> String {
        var line = leadingWhitespace + (commandName ?? "")
        if !arguments.isEmpty {
            line += " " + arguments.joined(separator: ", ")
        }
        if let inlineComment {
            line += " " + inlineComment
        }
        return line
    }

    private static func splitInlineComment(_ line: String) -> (code: String, comment: String?) {
        guard let commentStart = line.firstIndex(of: "@") else {
            return (line, nil)
        }
        let code = String(line[..<commentStart]).trimmingCharacters(in: .whitespaces)
        let leading = String(line[..<commentStart].prefix { $0.isWhitespace })
        return (leading + code, String(line[commentStart...]))
    }

    private static func splitArguments(_ args: String) -> [String] {
        guard !args.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var parenDepth = 0
        for character in args {
            if character == "\"" {
                inQuotes.toggle()
                current.append(character)
                continue
            }
            if !inQuotes {
                if character == "(" {
                    parenDepth += 1
                } else if character == ")" {
                    parenDepth = max(0, parenDepth - 1)
                } else if character == "," && parenDepth == 0 {
                    result.append(current.trimmingCharacters(in: .whitespaces))
                    current = ""
                    continue
                }
            }
            current.append(character)
        }
        let trimmed = current.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            result.append(trimmed)
        }
        return result
    }
}

private enum ScriptCommandEditApplySafety {
    static func applyability(for plan: ScriptCommandEditPlan, fileManager: FileManager) -> ScriptCommandEditApplyability {
        var diagnostics = plan.diagnostics.filter { $0.severity == .error }
        let root = URL(fileURLWithPath: plan.rootPath).standardizedFileURL
        guard fileManager.fileExists(atPath: root.path) else {
            diagnostics.append(Diagnostic(severity: .error, code: "SCRIPT_COMMAND_EDIT_ROOT_MISSING", message: "Script edit root does not exist: \(plan.rootPath)."))
            return ScriptCommandEditApplyability(isApplyable: false, diagnostics: diagnostics)
        }
        guard !plan.changes.isEmpty else {
            diagnostics.append(Diagnostic(severity: .warning, code: "SCRIPT_COMMAND_EDIT_NO_CHANGES", message: "No script command edits are staged."))
            return ScriptCommandEditApplyability(isApplyable: false, diagnostics: diagnostics)
        }
        for change in plan.changes {
            let destination = root.appendingPathComponent(change.path).standardizedFileURL
            let pathDiagnostics = SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
                change.path,
                root: root,
                fileManager: fileManager,
                codePrefix: "SCRIPT_COMMAND_EDIT_APPLY",
                subject: "Script edit path",
                spanLine: plan.draft.line
            )
            if !pathDiagnostics.isEmpty {
                diagnostics.append(contentsOf: pathDiagnostics)
                continue
            }
            guard fileManager.fileExists(atPath: destination.path), let currentData = try? Data(contentsOf: destination) else {
                diagnostics.append(Diagnostic(severity: .error, code: "SCRIPT_COMMAND_EDIT_APPLY_SOURCE_MISSING", message: "Script source is missing before apply: \(change.path).", span: SourceSpan(relativePath: change.path, startLine: plan.draft.line)))
                continue
            }
            if currentData.count != change.originalByteCount {
                diagnostics.append(Diagnostic(severity: .error, code: "SCRIPT_COMMAND_EDIT_APPLY_SIZE_MISMATCH", message: "\(change.path) changed size since planning.", span: SourceSpan(relativePath: change.path, startLine: plan.draft.line)))
            }
            if let originalSHA1 = change.originalSHA1, pokemonHackSHA1Hex(currentData) != originalSHA1 {
                diagnostics.append(Diagnostic(severity: .error, code: "SCRIPT_COMMAND_EDIT_APPLY_HASH_MISMATCH", message: "\(change.path) changed SHA1 since planning.", span: SourceSpan(relativePath: change.path, startLine: plan.draft.line)))
            }
        }
        return ScriptCommandEditApplyability(isApplyable: diagnostics.allSatisfy { $0.severity != .error }, diagnostics: diagnostics)
    }
}

private func replaceLine(in text: String, lineNumber: Int, replacement: String) -> String {
    var lines = text.components(separatedBy: "\n")
    let hadTrailingNewline = lines.last == ""
    let index = max(0, lineNumber - 1)
    guard lines.indices.contains(index) else { return text }
    lines[index] = replacement
    var joined = lines.joined(separator: "\n")
    if hadTrailingNewline, !joined.hasSuffix("\n") {
        joined.append("\n")
    }
    return joined
}

private func readText(_ url: URL) throws -> String {
    if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
        return utf8
    }
    return try String(contentsOf: url, encoding: .isoLatin1)
}

private func backupTimestamp() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    return "\(formatter.string(from: Date()))-\(UUID().uuidString.prefix(8))"
}
