import Foundation

public struct ScriptTextWrapPreview: Codable, Equatable {
    public let label: String?
    public let maxLineLength: Int
    public let lines: [String]
    public let bodyPreview: String
    public let diagnostics: [Diagnostic]

    public init(
        label: String?,
        maxLineLength: Int,
        lines: [String],
        bodyPreview: String,
        diagnostics: [Diagnostic] = []
    ) {
        self.label = label
        self.maxLineLength = maxLineLength
        self.lines = lines
        self.bodyPreview = bodyPreview
        self.diagnostics = diagnostics
    }
}

public struct ScriptHelperBodyPlan: Codable, Equatable {
    public let label: String
    public let body: String
    public let diagnostics: [Diagnostic]

    public init(label: String, body: String, diagnostics: [Diagnostic] = []) {
        self.label = label
        self.body = body
        self.diagnostics = diagnostics
    }
}

public struct MapScriptScaffoldValidation: Codable, Equatable {
    public let label: String
    public let body: String
    public let referencedLabels: [String]
    public let diagnostics: [Diagnostic]

    public init(label: String, body: String, referencedLabels: [String], diagnostics: [Diagnostic] = []) {
        self.label = label
        self.body = body
        self.referencedLabels = referencedLabels
        self.diagnostics = diagnostics
    }
}

public enum ScriptAuthoringHelpers {
    public static func textWrappingPreview(
        label: String? = nil,
        text: String,
        maxLineLength: Int = 36,
        sourcePath: String? = nil
    ) -> ScriptTextWrapPreview {
        let clampedLimit = max(8, maxLineLength)
        let normalizedText = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        var diagnostics: [Diagnostic] = []

        if let label, MapScriptIndex.normalizedScriptLabel(label) == nil {
            diagnostics.append(helperDiagnostic(
                severity: .error,
                code: "SCRIPT_TEXT_LABEL_INVALID",
                message: "Text label \(label) is not a valid source label.",
                sourcePath: sourcePath
            ))
        }

        var wrappedLines: [String] = []
        for paragraph in normalizedText.components(separatedBy: "\n") {
            wrappedLines.append(contentsOf: wrapParagraph(paragraph, maxLineLength: clampedLimit))
        }
        if wrappedLines.isEmpty {
            wrappedLines = [""]
            diagnostics.append(helperDiagnostic(
                severity: .warning,
                code: "SCRIPT_TEXT_EMPTY",
                message: "Text preview is empty.",
                sourcePath: sourcePath
            ))
        }

        for (index, line) in wrappedLines.enumerated() where visibleCharacterCount(line) > clampedLimit {
            diagnostics.append(helperDiagnostic(
                severity: .warning,
                code: "SCRIPT_TEXT_WORD_TOO_LONG",
                message: "Wrapped text line \(index + 1) still exceeds \(clampedLimit) visible characters.",
                sourcePath: sourcePath,
                line: index + 1,
                column: clampedLimit + 1
            ))
        }

        let body = wrappedTextBody(label: label, lines: wrappedLines)
        return ScriptTextWrapPreview(
            label: label,
            maxLineLength: clampedLimit,
            lines: wrappedLines,
            bodyPreview: body,
            diagnostics: diagnostics
        )
    }

    public static func movementListPlan(
        label: String,
        movements: [String],
        sourcePath: String? = nil
    ) -> ScriptHelperBodyPlan {
        var diagnostics = validateLabel(label, sourcePath: sourcePath)
        let normalizedMovements = movements.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if normalizedMovements.isEmpty {
            diagnostics.append(helperDiagnostic(
                severity: .error,
                code: "SCRIPT_MOVEMENT_LIST_EMPTY",
                message: "Movement list \(label) needs at least one movement command before step_end.",
                sourcePath: sourcePath
            ))
        }

        for movement in normalizedMovements where !isSymbolOrMacroToken(movement) {
            diagnostics.append(helperDiagnostic(
                severity: .warning,
                code: "SCRIPT_MOVEMENT_COMMAND_UNUSUAL",
                message: "Movement command \(movement) is not a simple macro token.",
                sourcePath: sourcePath
            ))
        }

        var bodyLines = normalizedMovements.map { "\t\($0)" }
        if bodyLines.last?.trimmingCharacters(in: .whitespacesAndNewlines) != "step_end" {
            bodyLines.append("\tstep_end")
        }
        return ScriptHelperBodyPlan(label: label, body: bodyLines.joined(separator: "\n"), diagnostics: diagnostics)
    }

    public static func martItemListPlan(
        label: String,
        items: [String],
        sourcePath: String? = nil
    ) -> ScriptHelperBodyPlan {
        var diagnostics = validateLabel(label, sourcePath: sourcePath)
        let normalizedItems = items.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0 != "ITEM_NONE" }

        if normalizedItems.isEmpty {
            diagnostics.append(helperDiagnostic(
                severity: .error,
                code: "SCRIPT_MART_LIST_EMPTY",
                message: "Mart list \(label) needs at least one item before ITEM_NONE.",
                sourcePath: sourcePath
            ))
        }

        for item in normalizedItems where !item.hasPrefix("ITEM_") {
            diagnostics.append(helperDiagnostic(
                severity: .warning,
                code: "SCRIPT_MART_ITEM_UNUSUAL",
                message: "Mart item \(item) does not use the ITEM_ constant style.",
                sourcePath: sourcePath
            ))
        }

        let bodyLines = normalizedItems.map { "\t.2byte \($0)" } + ["\t.2byte ITEM_NONE"]
        return ScriptHelperBodyPlan(label: label, body: bodyLines.joined(separator: "\n"), diagnostics: diagnostics)
    }

    public static func validateMapScriptScaffold(
        label: String,
        body: String,
        existingLabels: Set<String> = [],
        sourcePath: String? = nil
    ) -> MapScriptScaffoldValidation {
        var diagnostics = validateLabel(label, sourcePath: sourcePath)
        var referencedLabels: [String] = []
        let parsedLines = ScriptParser.parse(body: body, startLine: 1)
        let commandLines = parsedLines.compactMap { line -> ScriptCommand? in
            if case .command(let command, _) = line {
                return command
            }
            return nil
        }

        let mapScriptCommands = commandLines.filter { $0.name == "map_script" || $0.name == "map_script_2" }
        if mapScriptCommands.isEmpty {
            diagnostics.append(helperDiagnostic(
                severity: .warning,
                code: "SCRIPT_MAPSCRIPT_SCAFFOLD_EMPTY",
                message: "Mapscript scaffold \(label) does not include a map_script command.",
                sourcePath: sourcePath
            ))
        }

        for command in mapScriptCommands {
            let requiredArgumentCount = command.name == "map_script_2" ? 4 : 2
            if command.arguments.count < requiredArgumentCount {
                diagnostics.append(helperDiagnostic(
                    severity: .error,
                    code: "SCRIPT_MAPSCRIPT_ARITY",
                    message: "\(command.name) needs at least \(requiredArgumentCount) arguments.",
                    sourcePath: sourcePath
                ))
                continue
            }
            if let referencedLabel = command.arguments.last,
               MapScriptIndex.normalizedScriptLabel(referencedLabel) != nil {
                referencedLabels.append(referencedLabel)
                if !existingLabels.isEmpty && !existingLabels.contains(referencedLabel) && referencedLabel != label {
                    diagnostics.append(helperDiagnostic(
                        severity: .warning,
                        code: "SCRIPT_MAPSCRIPT_TARGET_MISSING",
                        message: "Mapscript target \(referencedLabel) is not present in the indexed labels.",
                        sourcePath: sourcePath
                    ))
                }
            }
        }

        if !body.components(separatedBy: .newlines).contains(where: isByteZeroTerminator) {
            diagnostics.append(helperDiagnostic(
                severity: .warning,
                code: "SCRIPT_MAPSCRIPT_TERMINATOR_MISSING",
                message: "Mapscript scaffold \(label) should end with .byte 0.",
                sourcePath: sourcePath
            ))
        }

        diagnostics.append(contentsOf: lineMarkerAndPoryswitchDiagnostics(body: body, sourcePath: sourcePath))
        return MapScriptScaffoldValidation(
            label: label,
            body: body,
            referencedLabels: referencedLabels,
            diagnostics: diagnostics
        )
    }

    public static func lineMarkerAndPoryswitchDiagnostics(
        body: String,
        sourcePath: String? = nil
    ) -> [Diagnostic] {
        body.components(separatedBy: .newlines).enumerated().flatMap { index, line -> [Diagnostic] in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            var diagnostics: [Diagnostic] = []
            if trimmed.hasPrefix("#line") {
                diagnostics.append(helperDiagnostic(
                    severity: .warning,
                    code: "SCRIPT_LINE_MARKER_PRESENT",
                    message: "Line marker detected; keep helper edits preview-only until the owning generated/source mapping is understood.",
                    sourcePath: sourcePath,
                    line: index + 1
                ))
            }
            if trimmed.hasPrefix("#if") || trimmed.hasPrefix("#elif") || trimmed.hasPrefix("#else") || trimmed.hasPrefix("#endif") {
                diagnostics.append(helperDiagnostic(
                    severity: .warning,
                    code: "SCRIPT_CONDITIONAL_MARKER_PRESENT",
                    message: "Conditional source marker detected; helper output may not preserve every build variant.",
                    sourcePath: sourcePath,
                    line: index + 1
                ))
            }
            if trimmed.localizedCaseInsensitiveContains("poryswitch") || trimmed.localizedCaseInsensitiveContains("pory_switch") {
                diagnostics.append(helperDiagnostic(
                    severity: .warning,
                    code: "SCRIPT_PORYSWITCH_PRESENT",
                    message: "Poryswitch marker detected; this helper does not invoke or interpret Poryscript.",
                    sourcePath: sourcePath,
                    line: index + 1
                ))
            }
            return diagnostics
        }
    }

    public static func validateMapLocalHelperStaging(
        label: String,
        sourcePath: String,
        sourceRole: MapScriptSourceRole?,
        sourceExists: Bool
    ) -> [Diagnostic] {
        var diagnostics = validateLabel(label, sourcePath: sourcePath)
        if !sourceExists {
            diagnostics.append(helperDiagnostic(
                severity: .error,
                code: "SCRIPT_HELPER_SOURCE_MISSING",
                message: "Helper output cannot stage because \(sourcePath) is not loaded.",
                sourcePath: sourcePath
            ))
        }
        if sourceRole != .mapLocal {
            diagnostics.append(helperDiagnostic(
                severity: .error,
                code: "SCRIPT_HELPER_SOURCE_SHARED",
                message: "Helper output can only stage to map-local scripts.inc sources.",
                sourcePath: sourcePath
            ))
        }
        if !MapScriptIndex.isEditableScriptPath(sourcePath) {
            diagnostics.append(helperDiagnostic(
                severity: .error,
                code: "SCRIPT_HELPER_SOURCE_UNSUPPORTED",
                message: "Helper output can only stage to data/maps/*/scripts.inc sources.",
                sourcePath: sourcePath
            ))
        }
        return diagnostics
    }

    private static func validateLabel(_ label: String, sourcePath: String?) -> [Diagnostic] {
        guard MapScriptIndex.normalizedScriptLabel(label) == nil else { return [] }
        return [
            helperDiagnostic(
                severity: .error,
                code: "SCRIPT_HELPER_LABEL_INVALID",
                message: "Script label \(label) is not a valid source label.",
                sourcePath: sourcePath
            )
        ]
    }

    private static func wrapParagraph(_ paragraph: String, maxLineLength: Int) -> [String] {
        let words = paragraph.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard !words.isEmpty else { return [""] }

        var lines: [String] = []
        var current = ""
        for word in words {
            if current.isEmpty {
                current = word
            } else if visibleCharacterCount(current) + 1 + visibleCharacterCount(word) <= maxLineLength {
                current += " \(word)"
            } else {
                lines.append(current)
                current = word
            }
        }
        if !current.isEmpty {
            lines.append(current)
        }
        return lines
    }

    private static func wrappedTextBody(label: String?, lines: [String]) -> String {
        let escapedLines = lines.map(escapeStringLiteral)
        let joined = escapedLines.enumerated().map { index, line in
            let suffix = index == escapedLines.count - 1 ? "$" : "\\n"
            return line + suffix
        }.joined()
        let stringLine = "\t.string \"\(joined)\""
        guard let label, !label.isEmpty else { return stringLine }
        return "\(label)::\n\(stringLine)"
    }

    private static func escapeStringLiteral(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private static func visibleCharacterCount(_ value: String) -> Int {
        var count = 0
        var isEscaped = false
        for character in value {
            if isEscaped {
                count += 1
                isEscaped = false
            } else if character == "\\" {
                isEscaped = true
            } else {
                count += 1
            }
        }
        return count
    }

    private static func isSymbolOrMacroToken(_ value: String) -> Bool {
        value.range(of: #"^[A-Za-z_][A-Za-z0-9_]*$"#, options: .regularExpression) != nil
    }

    private static func isByteZeroTerminator(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed == ".byte 0" || trimmed == "\t.byte 0"
    }

    private static func helperDiagnostic(
        severity: DiagnosticSeverity,
        code: String,
        message: String,
        sourcePath: String?,
        line: Int = 1,
        column: Int = 1
    ) -> Diagnostic {
        Diagnostic(
            severity: severity,
            code: code,
            message: message,
            span: sourcePath.map { SourceSpan(relativePath: $0, startLine: line, startColumn: column) }
        )
    }
}
