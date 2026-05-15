import Foundation

public enum PoryscriptRelationshipKind: String, Codable, Equatable, CaseIterable {
    case lineMarker
    case poryswitch
    case conditional
}

public struct PoryscriptSourceFile: Codable, Equatable, Identifiable {
    public var id: String { relativePath }

    public let relativePath: String
    public let lineCount: Int

    public init(relativePath: String, lineCount: Int) {
        self.relativePath = relativePath
        self.lineCount = lineCount
    }
}

public struct PoryscriptGeneratedRelationship: Codable, Equatable, Identifiable {
    public var id: String { "\(incPath):\(line):\(kind.rawValue)" }

    public let incPath: String
    public let poryPath: String?
    public let line: Int
    public let kind: PoryscriptRelationshipKind
    public let preview: String

    public init(incPath: String, poryPath: String?, line: Int, kind: PoryscriptRelationshipKind, preview: String) {
        self.incPath = incPath
        self.poryPath = poryPath
        self.line = line
        self.kind = kind
        self.preview = preview
    }
}

public struct PoryscriptCompatibilityReport: Codable, Equatable {
    public let rootPath: String
    public let porySources: [PoryscriptSourceFile]
    public let generatedRelationships: [PoryscriptGeneratedRelationship]
    public let diagnostics: [Diagnostic]

    public init(
        rootPath: String,
        porySources: [PoryscriptSourceFile],
        generatedRelationships: [PoryscriptGeneratedRelationship],
        diagnostics: [Diagnostic] = []
    ) {
        self.rootPath = rootPath
        self.porySources = porySources
        self.generatedRelationships = generatedRelationships
        self.diagnostics = diagnostics
    }

    public func blockingDiagnostics(for relativePath: String) -> [Diagnostic] {
        let matches = generatedRelationships.filter { $0.incPath == relativePath }
        return matches.map { relationship in
            let code: String
            let message: String
            switch relationship.kind {
            case .lineMarker:
                code = "SCRIPT_COMMAND_EDIT_PORYSCRIPT_GENERATED_BLOCKED"
                message = "Native .inc command edits are blocked because \(relativePath) carries #line provenance from \(relationship.poryPath ?? "a .pory file")."
            case .poryswitch:
                code = "SCRIPT_COMMAND_EDIT_PORYSWITCH_BLOCKED"
                message = "Native .inc command edits are blocked because \(relativePath) contains poryswitch conditional generation facts."
            case .conditional:
                code = "SCRIPT_COMMAND_EDIT_CONDITIONAL_BLOCKED"
                message = "Native .inc command edits are blocked because \(relativePath) contains preprocessor conditional facts."
            }
            return Diagnostic(
                severity: .error,
                code: code,
                message: message,
                span: SourceSpan(relativePath: relativePath, startLine: relationship.line)
            )
        }
    }
}

public enum PoryscriptCompatibilityScanner {
    public static func scan(rootPath: String, fileManager: FileManager = .default) -> PoryscriptCompatibilityReport {
        let root = URL(fileURLWithPath: rootPath).standardizedFileURL
        var porySources: [PoryscriptSourceFile] = []
        var relationships: [PoryscriptGeneratedRelationship] = []

        for path in sourceFiles(root: root, extensions: ["pory"], fileManager: fileManager) {
            let url = root.appendingPathComponent(path)
            let lineCount = (try? String(contentsOf: url, encoding: .utf8).components(separatedBy: .newlines).count) ?? 0
            porySources.append(PoryscriptSourceFile(relativePath: path, lineCount: lineCount))
        }

        for path in sourceFiles(root: root, extensions: ["inc"], fileManager: fileManager) {
            let url = root.appendingPathComponent(path)
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            relationships.append(contentsOf: relationshipsInInc(text: text, path: path))
        }

        var diagnostics: [Diagnostic] = []
        if !porySources.isEmpty {
            diagnostics.append(
                Diagnostic(
                    severity: .info,
                    code: "PORYSCRIPT_SOURCES_DISCOVERED",
                    message: "Discovered \(porySources.count) .pory source file(s); native .inc writes remain blocked for generated outputs."
                )
            )
        }
        if !relationships.isEmpty {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "PORYSCRIPT_GENERATED_INC_FACTS",
                    message: "Discovered \(relationships.count) generated or conditional .inc fact(s); command apply is blocked for affected files."
                )
            )
        }
        diagnostics.append(
            Diagnostic(
                severity: .info,
                code: "PORYSCRIPT_COMPILER_NOT_INVOKED",
                message: "Poryscript compatibility scanning is read-only and does not invoke a compiler."
            )
        )

        return PoryscriptCompatibilityReport(
            rootPath: root.path,
            porySources: porySources.sorted { $0.relativePath < $1.relativePath },
            generatedRelationships: relationships.sorted {
                if $0.incPath == $1.incPath { return $0.line < $1.line }
                return $0.incPath < $1.incPath
            },
            diagnostics: diagnostics
        )
    }

    private static func relationshipsInInc(text: String, path: String) -> [PoryscriptGeneratedRelationship] {
        text.components(separatedBy: .newlines).enumerated().compactMap { index, line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#line"), trimmed.contains(".pory") {
                return PoryscriptGeneratedRelationship(
                    incPath: path,
                    poryPath: quotedPath(in: trimmed),
                    line: index + 1,
                    kind: .lineMarker,
                    preview: trimmed
                )
            }
            if trimmed.localizedCaseInsensitiveContains("poryswitch") {
                return PoryscriptGeneratedRelationship(
                    incPath: path,
                    poryPath: nil,
                    line: index + 1,
                    kind: .poryswitch,
                    preview: trimmed
                )
            }
            if isConditionalLine(trimmed) {
                return PoryscriptGeneratedRelationship(
                    incPath: path,
                    poryPath: nil,
                    line: index + 1,
                    kind: .conditional,
                    preview: trimmed
                )
            }
            return nil
        }
    }

    private static func quotedPath(in line: String) -> String? {
        guard let first = line.firstIndex(of: "\"") else { return nil }
        let remainder = line[line.index(after: first)...]
        guard let last = remainder.firstIndex(of: "\"") else { return nil }
        return String(remainder[..<last])
    }

    private static func isConditionalLine(_ line: String) -> Bool {
        line.hasPrefix("#if")
            || line.hasPrefix("#ifdef")
            || line.hasPrefix("#ifndef")
            || line.hasPrefix("#elif")
            || line.hasPrefix("#else")
            || line.hasPrefix("#endif")
    }

    private static func sourceFiles(root: URL, extensions: Set<String>, fileManager: FileManager) -> [String] {
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var paths: [String] = []
        for case let url as URL in enumerator {
            if (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
                let name = url.lastPathComponent
                if ["build", "DerivedData", ".pokemonhackstudio", "references", ".git"].contains(name) {
                    enumerator.skipDescendants()
                }
                continue
            }
            guard extensions.contains(url.pathExtension.lowercased()) else { continue }
            let rootPath = root.path
            let path = url.standardizedFileURL.path
            guard path.hasPrefix(rootPath + "/") else { continue }
            paths.append(String(path.dropFirst(rootPath.count + 1)))
        }
        return paths.sorted()
    }
}
