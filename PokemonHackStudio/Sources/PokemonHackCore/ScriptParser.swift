import Foundation

public enum ScriptParser {
    public static func parse(body: String, startLine: Int) -> [ScriptLine] {
        let lines = body.components(separatedBy: .newlines)
        return lines.enumerated().map { index, line in
            parseLine(line, lineNumber: startLine + index)
        }
    }

    public static func parseLine(_ line: String, lineNumber: Int) -> ScriptLine {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return .empty(line: lineNumber)
        }

        // Check for comment-only line
        if trimmed.hasPrefix("@") {
            return .comment(String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces), line: lineNumber)
        }
        if trimmed.hasPrefix("/*") && trimmed.hasSuffix("*/") {
            let content = trimmed.dropFirst(2).dropLast(2).trimmingCharacters(in: .whitespaces)
            return .comment(content, line: lineNumber)
        }

        // Split by @ for inline comments
        let parts = line.split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
        let codePart = String(parts[0]).trimmingCharacters(in: .whitespaces)
        let commentPart = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : nil

        if codePart.isEmpty {
            return .comment(commentPart ?? "", line: lineNumber)
        }

        // Check for label
        if codePart.hasSuffix("::") {
            return .label(String(codePart.dropLast(2)), line: lineNumber)
        }
        if codePart.hasSuffix(":") {
            return .label(String(codePart.dropLast()), line: lineNumber)
        }

        // Check for directives
        if codePart.hasPrefix(".") {
            let dirParts = codePart.split(maxSplits: 1, omittingEmptySubsequences: true, whereSeparator: { $0.isWhitespace })
            let name = String(dirParts[0])
            let value = dirParts.count > 1 ? String(dirParts[1]) : ""
            return .directive(name: name, value: value, line: lineNumber)
        }

        // Command or Macro
        let commandParts = codePart.split(maxSplits: 1, omittingEmptySubsequences: true, whereSeparator: { $0.isWhitespace })
        let name = String(commandParts[0])
        let argsString = commandParts.count > 1 ? String(commandParts[1]) : ""
        let args = parseArguments(argsString)

        // Simple heuristic: if it's all caps or starts with map_script, treat as macro?
        // Actually, we can just treat them all as commands for now, or use a list of known macros.
        if name.lowercased() == name || name.contains("_") {
            return .command(ScriptCommand(name: name, arguments: args, comment: commentPart), line: lineNumber)
        } else {
            return .macro(name: name, arguments: args, line: lineNumber)
        }
    }

    private static func parseArguments(_ argsString: String) -> [String] {
        guard !argsString.isEmpty else { return [] }
        
        var args: [String] = []
        var currentArg = ""
        var inQuotes = false
        var parenDepth = 0
        
        for char in argsString {
            if char == "\"" {
                inQuotes.toggle()
                currentArg.append(char)
            } else if !inQuotes {
                if char == "(" {
                    parenDepth += 1
                    currentArg.append(char)
                } else if char == ")" {
                    parenDepth -= 1
                    currentArg.append(char)
                } else if char == "," && parenDepth == 0 {
                    args.append(currentArg.trimmingCharacters(in: .whitespaces))
                    currentArg = ""
                } else {
                    currentArg.append(char)
                }
            } else {
                currentArg.append(char)
            }
        }
        
        if !currentArg.trimmingCharacters(in: .whitespaces).isEmpty {
            args.append(currentArg.trimmingCharacters(in: .whitespaces))
        }
        
        return args
    }
}
