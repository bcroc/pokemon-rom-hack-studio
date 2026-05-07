import Foundation

public enum ScriptOutlineLabelKind: String, Codable, Equatable, CaseIterable {
    case script
    case text
    case data

    public var title: String {
        switch self {
        case .script:
            "Script"
        case .text:
            "Text"
        case .data:
            "Data"
        }
    }
}

public struct ScriptOutlineSource: Codable, Equatable, Identifiable {
    public var id: String { path }

    public let path: String
    public let module: SourceIndexModule
    public let role: MapScriptSourceRole
    public let labelCount: Int
    public let commandCount: Int
    public let textBlockCount: Int
    public let diagnosticCount: Int

    public init(
        path: String,
        module: SourceIndexModule,
        role: MapScriptSourceRole,
        labelCount: Int,
        commandCount: Int,
        textBlockCount: Int,
        diagnosticCount: Int
    ) {
        self.path = path
        self.module = module
        self.role = role
        self.labelCount = labelCount
        self.commandCount = commandCount
        self.textBlockCount = textBlockCount
        self.diagnosticCount = diagnosticCount
    }
}

public struct ScriptOutlineCommand: Codable, Equatable, Identifiable {
    public var id: String { "\(sourceSpan.relativePath):\(sourceSpan.startLine):\(name):\(rawLine)" }

    public let name: String
    public let arguments: String
    public let rawLine: String
    public let sourceSpan: SourceSpan

    public init(name: String, arguments: String, rawLine: String, sourceSpan: SourceSpan) {
        self.name = name
        self.arguments = arguments
        self.rawLine = rawLine
        self.sourceSpan = sourceSpan
    }
}

public struct ScriptTextBlock: Codable, Equatable, Identifiable {
    public var id: String { "\(sourceSpan.relativePath):\(sourceSpan.startLine):\(label)" }

    public let label: String
    public let sourcePath: String
    public let sourceSpan: SourceSpan
    public let stringLineCount: Int
    public let characterCount: Int
    public let preview: String
    public let diagnostics: [Diagnostic]

    public init(
        label: String,
        sourcePath: String,
        sourceSpan: SourceSpan,
        stringLineCount: Int,
        characterCount: Int,
        preview: String,
        diagnostics: [Diagnostic] = []
    ) {
        self.label = label
        self.sourcePath = sourcePath
        self.sourceSpan = sourceSpan
        self.stringLineCount = stringLineCount
        self.characterCount = characterCount
        self.preview = preview
        self.diagnostics = diagnostics
    }
}

public struct ScriptOutlineLabel: Codable, Equatable, Identifiable {
    public var id: String { "\(sourceSpan.relativePath):\(sourceSpan.startLine):\(label)" }

    public let label: String
    public let kind: ScriptOutlineLabelKind
    public let sourcePath: String
    public let sourceRole: MapScriptSourceRole
    public let sourceSpan: SourceSpan
    public let bodySpan: SourceSpan
    public let bodyPreview: String
    public let commands: [ScriptOutlineCommand]
    public let textReferences: [String]
    public let diagnostics: [Diagnostic]

    public init(
        label: String,
        kind: ScriptOutlineLabelKind,
        sourcePath: String,
        sourceRole: MapScriptSourceRole,
        sourceSpan: SourceSpan,
        bodySpan: SourceSpan,
        bodyPreview: String,
        commands: [ScriptOutlineCommand],
        textReferences: [String],
        diagnostics: [Diagnostic] = []
    ) {
        self.label = label
        self.kind = kind
        self.sourcePath = sourcePath
        self.sourceRole = sourceRole
        self.sourceSpan = sourceSpan
        self.bodySpan = bodySpan
        self.bodyPreview = bodyPreview
        self.commands = commands
        self.textReferences = textReferences
        self.diagnostics = diagnostics
    }
}

public struct ProjectScriptOutline: Codable, Equatable {
    public let root: SourceLocation
    public let profile: GameProfile
    public let adapterID: String
    public let adapterName: String
    public let sources: [ScriptOutlineSource]
    public let labels: [ScriptOutlineLabel]
    public let textBlocks: [ScriptTextBlock]
    public let diagnostics: [Diagnostic]

    public init(
        root: SourceLocation,
        profile: GameProfile,
        adapterID: String,
        adapterName: String,
        sources: [ScriptOutlineSource],
        labels: [ScriptOutlineLabel],
        textBlocks: [ScriptTextBlock],
        diagnostics: [Diagnostic] = []
    ) {
        self.root = root
        self.profile = profile
        self.adapterID = adapterID
        self.adapterName = adapterName
        self.sources = sources
        self.labels = labels
        self.textBlocks = textBlocks
        self.diagnostics = diagnostics
    }
}

public enum ProjectScriptOutlineLoader {
    public static func load(
        from index: ProjectIndex,
        fileManager: FileManager = .default
    ) throws -> ProjectScriptOutline {
        let root = URL(fileURLWithPath: index.root.path).standardizedFileURL
        let descriptors = SourceIndexDescriptorSet.descriptors(for: index.profile)
        let sourceDescriptors = indexedSourceDescriptors(
            root: root,
            descriptors: descriptors,
            fileManager: fileManager
        )

        var sources: [ScriptOutlineSource] = []
        var labels: [ScriptOutlineLabel] = []
        var textBlocks: [ScriptTextBlock] = []
        var diagnostics: [Diagnostic] = []

        for descriptor in sourceDescriptors {
            let url = root.appendingPathComponent(descriptor.path)
            let text: String
            do {
                text = try String(contentsOf: url, encoding: .utf8)
            } catch {
                let diagnostic = Diagnostic(
                    severity: .error,
                    code: "SCRIPT_SOURCE_UNREADABLE",
                    message: "Could not read script source \(descriptor.path): \(error.localizedDescription)",
                    span: SourceSpan(relativePath: descriptor.path, startLine: 1)
                )
                diagnostics.append(diagnostic)
                sources.append(
                    ScriptOutlineSource(
                        path: descriptor.path,
                        module: descriptor.module,
                        role: role(for: descriptor.path),
                        labelCount: 0,
                        commandCount: 0,
                        textBlockCount: 0,
                        diagnosticCount: 1
                    )
                )
                continue
            }

            let role = role(for: descriptor.path)
            let source = MapScriptSource(path: descriptor.path, role: role, exists: true, text: text)
            let spans = MapScriptIndexLoader.parseLabels(source: source)
            let sourceLabels = spans.map { label(from: $0) }
            let sourceTextBlocks = spans.compactMap(textBlock(from:))
            let sourceDiagnostics = sourceLabels.flatMap(\.diagnostics)

            labels.append(contentsOf: sourceLabels)
            textBlocks.append(contentsOf: sourceTextBlocks)
            diagnostics.append(contentsOf: sourceDiagnostics)
            sources.append(
                ScriptOutlineSource(
                    path: descriptor.path,
                    module: descriptor.module,
                    role: role,
                    labelCount: sourceLabels.count,
                    commandCount: sourceLabels.reduce(0) { $0 + $1.commands.count },
                    textBlockCount: sourceTextBlocks.count,
                    diagnosticCount: sourceDiagnostics.count
                )
            )
        }

        let duplicateDiagnostics = duplicateLabelDiagnostics(labels: labels)
        diagnostics.append(contentsOf: duplicateDiagnostics)

        let sourceDiagnosticsByPath = Dictionary(grouping: duplicateDiagnostics.compactMap { diagnostic -> (String, Diagnostic)? in
            guard let path = diagnostic.span?.relativePath else { return nil }
            return (path, diagnostic)
        }, by: \.0)

        if !sourceDiagnosticsByPath.isEmpty {
            sources = sources.map { source in
                let extraCount = sourceDiagnosticsByPath[source.path]?.count ?? 0
                guard extraCount > 0 else { return source }
                return ScriptOutlineSource(
                    path: source.path,
                    module: source.module,
                    role: source.role,
                    labelCount: source.labelCount,
                    commandCount: source.commandCount,
                    textBlockCount: source.textBlockCount,
                    diagnosticCount: source.diagnosticCount + extraCount
                )
            }
        }

        return ProjectScriptOutline(
            root: index.root,
            profile: index.profile,
            adapterID: index.adapterID,
            adapterName: index.adapterName,
            sources: sources.sorted { $0.path < $1.path },
            labels: labels.sorted(by: sourceOrder),
            textBlocks: textBlocks.sorted { lhs, rhs in
                if lhs.sourcePath == rhs.sourcePath {
                    return lhs.sourceSpan.startLine < rhs.sourceSpan.startLine
                }
                return lhs.sourcePath < rhs.sourcePath
            },
            diagnostics: diagnostics
        )
    }

    private struct ScriptSourceDescriptor {
        let path: String
        let module: SourceIndexModule
    }

    private static func indexedSourceDescriptors(
        root: URL,
        descriptors: SourceIndexDescriptorSet,
        fileManager: FileManager
    ) -> [ScriptSourceDescriptor] {
        var modulesByPath: [String: SourceIndexModule] = [:]

        for path in sourceFiles(root: root, roots: descriptors.scriptRoots, extensions: ["inc"], fileManager: fileManager)
            where isIndexedScriptSource(path) {
            modulesByPath[path] = .scripts
        }

        for path in sourceFiles(root: root, roots: descriptors.textRoots, extensions: ["inc", "h", "c"], fileManager: fileManager)
            where modulesByPath[path] == nil {
            modulesByPath[path] = .text
        }

        return modulesByPath
            .map { ScriptSourceDescriptor(path: $0.key, module: $0.value) }
            .sorted { $0.path < $1.path }
    }

    private static func isIndexedScriptSource(_ path: String) -> Bool {
        if path.hasPrefix("data/maps/") {
            return MapScriptIndex.isEditableScriptPath(path)
        }
        return true
    }

    private static func role(for path: String) -> MapScriptSourceRole {
        MapScriptIndex.isEditableScriptPath(path) ? .mapLocal : .shared
    }

    private static func sourceFiles(
        root: URL,
        roots: [String],
        extensions: Set<String>,
        fileManager: FileManager
    ) -> [String] {
        var paths: [String] = []

        for relativeRoot in roots {
            let url = root.appendingPathComponent(relativeRoot)
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else { continue }

            if isDirectory.boolValue {
                guard let enumerator = fileManager.enumerator(
                    at: url,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                ) else {
                    continue
                }

                for case let fileURL as URL in enumerator {
                    guard
                        (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true,
                        extensions.contains(fileURL.pathExtension.lowercased())
                    else {
                        continue
                    }
                    paths.append(relativePath(for: fileURL, root: root))
                }
            } else if extensions.contains(url.pathExtension.lowercased()) {
                paths.append(relativeRoot)
            }
        }

        return Array(Set(paths)).sorted()
    }

    private static func relativePath(for url: URL, root: URL) -> String {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        if path.hasPrefix(rootPath + "/") {
            return String(path.dropFirst(rootPath.count + 1))
        }
        return path
    }

    private static func label(from span: MapScriptLabelSpan) -> ScriptOutlineLabel {
        let commands = commandOutlines(in: span)
        let stringLines = scriptStringLines(in: span.body).map(\.line)
        let kind = labelKind(commands: commands, stringLines: stringLines)
        let diagnostics = kind == .text ? textDiagnostics(for: span, stringLines: stringLines) : []
        let textReferences = Array(Set(symbolTokens(in: span.body).filter { token in
            token.hasPrefix("gText_") || token.hasPrefix("Text_")
        })).sorted()

        return ScriptOutlineLabel(
            label: span.label,
            kind: kind,
            sourcePath: span.sourcePath,
            sourceRole: span.sourceRole,
            sourceSpan: SourceSpan(
                relativePath: span.sourcePath,
                startLine: span.labelLine,
                endLine: span.bodyEndLine
            ),
            bodySpan: SourceSpan(
                relativePath: span.sourcePath,
                startLine: span.bodyStartLine,
                endLine: span.bodyEndLine
            ),
            bodyPreview: preview(span.body),
            commands: commands,
            textReferences: textReferences,
            diagnostics: diagnostics
        )
    }

    private static func textBlock(from span: MapScriptLabelSpan) -> ScriptTextBlock? {
        let stringLines = scriptStringLines(in: span.body).map(\.line)
        guard !stringLines.isEmpty else { return nil }
        let diagnostics = textDiagnostics(for: span, stringLines: stringLines)

        return ScriptTextBlock(
            label: span.label,
            sourcePath: span.sourcePath,
            sourceSpan: SourceSpan(
                relativePath: span.sourcePath,
                startLine: span.labelLine,
                endLine: span.bodyEndLine
            ),
            stringLineCount: stringLines.count,
            characterCount: stringLines.joined().count,
            preview: stringLines.prefix(8).joined(separator: "\n"),
            diagnostics: diagnostics
        )
    }

    private static func labelKind(
        commands: [ScriptOutlineCommand],
        stringLines: [String]
    ) -> ScriptOutlineLabelKind {
        if !stringLines.isEmpty, commands.isEmpty {
            return .text
        }
        if !commands.isEmpty {
            return .script
        }
        return .data
    }

    private static func commandOutlines(in span: MapScriptLabelSpan) -> [ScriptOutlineCommand] {
        span.body.components(separatedBy: .newlines).enumerated().compactMap { offset, line in
            let rawLine = line.trimmingCharacters(in: .whitespaces)
            let trimmed = trimmedCommandLine(rawLine)
            guard !trimmed.isEmpty, !trimmed.hasPrefix(".") else { return nil }

            let parts = trimmed.split(maxSplits: 1, whereSeparator: { $0.isWhitespace })
            guard let name = parts.first else { return nil }
            let arguments = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : ""
            return ScriptOutlineCommand(
                name: String(name),
                arguments: arguments,
                rawLine: rawLine,
                sourceSpan: SourceSpan(relativePath: span.sourcePath, startLine: span.bodyStartLine + offset)
            )
        }
    }

    private static func trimmedCommandLine(_ line: String) -> String {
        let commentTrimmed = line.split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? line
        return commentTrimmed.trimmingCharacters(in: .whitespaces)
    }

    private static func scriptStringLines(in body: String) -> [(offset: Int, line: String)] {
        body.components(separatedBy: .newlines).enumerated().compactMap { offset, line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix(".string") else { return nil }
            return (offset, trimmed)
        }
    }

    private static func textDiagnostics(
        for span: MapScriptLabelSpan,
        stringLines: [String],
        maxLineLength: Int = 68
    ) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        let lines = span.body.components(separatedBy: .newlines)

        for (offset, line) in lines.enumerated() where line.count > maxLineLength {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "TEXT_LINE_LONG",
                    message: "Line exceeds \(maxLineLength) characters.",
                    span: SourceSpan(
                        relativePath: span.sourcePath,
                        startLine: span.bodyStartLine + offset,
                        startColumn: maxLineLength + 1
                    )
                )
            )
        }

        if !stringLines.contains(where: { $0.contains("$") }) {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "TEXT_TERMINATOR_MISSING",
                    message: "Text block has no $ terminator.",
                    span: SourceSpan(relativePath: span.sourcePath, startLine: span.labelLine, endLine: span.bodyEndLine)
                )
            )
        }

        return diagnostics
    }

    private static func duplicateLabelDiagnostics(labels: [ScriptOutlineLabel]) -> [Diagnostic] {
        Dictionary(grouping: labels, by: \.label).compactMap { label, matches in
            guard matches.count > 1 else { return nil }
            let first = matches[0]
            return Diagnostic(
                severity: .warning,
                code: "SCRIPT_LABEL_DUPLICATE",
                message: "Script outline label \(label) appears \(matches.count) times across indexed script/text sources.",
                span: first.sourceSpan
            )
        }
    }

    private static func sourceOrder(_ lhs: ScriptOutlineLabel, _ rhs: ScriptOutlineLabel) -> Bool {
        if lhs.sourcePath == rhs.sourcePath {
            return lhs.sourceSpan.startLine < rhs.sourceSpan.startLine
        }
        return lhs.sourcePath < rhs.sourcePath
    }

    private static func symbolTokens(in text: String) -> [String] {
        text.split { character in
            !(character == "_" || character.isLetter || character.isNumber)
        }.map(String.init)
    }

    private static func preview(_ body: String, maxLines: Int = 12) -> String {
        body.components(separatedBy: .newlines)
            .prefix(maxLines)
            .joined(separator: "\n")
    }
}
