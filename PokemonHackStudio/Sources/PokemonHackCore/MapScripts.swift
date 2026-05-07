import Foundation

public enum MapScriptSourceRole: String, Codable, Equatable, CaseIterable {
    case mapLocal
    case shared

    public var title: String {
        switch self {
        case .mapLocal: "Map Local"
        case .shared: "Shared"
        }
    }
}

public enum MapScriptResolutionState: String, Codable, Equatable {
    case resolved
    case noScript
    case missingLabel
    case duplicateLabel
    case generatedPath
    case externalLabel
}

public struct MapScriptSource: Codable, Equatable, Identifiable {
    public var id: String { path }

    public let path: String
    public let role: MapScriptSourceRole
    public let exists: Bool
    public let text: String

    public init(path: String, role: MapScriptSourceRole, exists: Bool, text: String) {
        self.path = path
        self.role = role
        self.exists = exists
        self.text = text
    }
}

public struct MapScriptLabelSpan: Codable, Equatable, Identifiable {
    public var id: String { "\(sourcePath):\(labelLine):\(label)" }

    public let label: String
    public let sourcePath: String
    public let sourceRole: MapScriptSourceRole
    public let labelLine: Int
    public let bodyStartLine: Int
    public let bodyEndLine: Int
    public let body: String

    public init(
        label: String,
        sourcePath: String,
        sourceRole: MapScriptSourceRole,
        labelLine: Int,
        bodyStartLine: Int,
        bodyEndLine: Int,
        body: String
    ) {
        self.label = label
        self.sourcePath = sourcePath
        self.sourceRole = sourceRole
        self.labelLine = labelLine
        self.bodyStartLine = bodyStartLine
        self.bodyEndLine = bodyEndLine
        self.body = body
    }
}

public struct MapScriptResolution: Codable, Equatable, Identifiable {
    public var id: String { label }

    public let label: String
    public let state: MapScriptResolutionState
    public let span: MapScriptLabelSpan?
    public let diagnostics: [Diagnostic]

    public init(
        label: String,
        state: MapScriptResolutionState,
        span: MapScriptLabelSpan? = nil,
        diagnostics: [Diagnostic] = []
    ) {
        self.label = label
        self.state = state
        self.span = span
        self.diagnostics = diagnostics
    }
}

public struct MapScriptIndex: Codable, Equatable, Identifiable {
    public var id: String { rootPath + ":" + mapName }

    public let rootPath: String
    public let mapName: String
    public let sources: [MapScriptSource]
    public let labels: [MapScriptLabelSpan]
    public let diagnostics: [Diagnostic]

    public init(
        rootPath: String,
        mapName: String,
        sources: [MapScriptSource],
        labels: [MapScriptLabelSpan],
        diagnostics: [Diagnostic] = []
    ) {
        self.rootPath = rootPath
        self.mapName = mapName
        self.sources = sources
        self.labels = labels
        self.diagnostics = diagnostics
    }

    public func source(path: String) -> MapScriptSource? {
        sources.first { $0.path == path }
    }

    public func resolution(for label: String?) -> MapScriptResolution {
        guard let label = Self.normalizedScriptLabel(label) else {
            return MapScriptResolution(label: label ?? "", state: .noScript)
        }

        return resolution(forNormalizedLabel: label, matches: labels.filter { $0.label == label })
    }

    public func resolutions(for labels: [String]) -> [String: MapScriptResolution] {
        let normalizedLabels = Set(labels.compactMap(Self.normalizedScriptLabel))
        guard !normalizedLabels.isEmpty else { return [:] }

        let matchesByLabel = Dictionary(grouping: self.labels.filter { normalizedLabels.contains($0.label) }) { $0.label }
        return Dictionary(uniqueKeysWithValues: normalizedLabels.map { label in
            (label, resolution(forNormalizedLabel: label, matches: matchesByLabel[label] ?? []))
        })
    }

    private func resolution(forNormalizedLabel label: String, matches: [MapScriptLabelSpan]) -> MapScriptResolution {
        if matches.count == 1 {
            let span = matches[0]
            guard Self.isEditableScriptPath(span.sourcePath) else {
                return MapScriptResolution(
                    label: label,
                    state: .generatedPath,
                    diagnostics: [
                        Diagnostic(
                            severity: .error,
                            code: "MAP_SCRIPT_SOURCE_GENERATED",
                            message: "Script label \(label) resolves to a generated or unsupported source path: \(span.sourcePath).",
                            span: SourceSpan(relativePath: span.sourcePath, startLine: span.labelLine)
                        )
                    ]
                )
            }
            return MapScriptResolution(label: label, state: .resolved, span: span)
        }

        if matches.count > 1 {
            return MapScriptResolution(
                label: label,
                state: .duplicateLabel,
                diagnostics: [
                    Diagnostic(
                        severity: .error,
                        code: "MAP_SCRIPT_LABEL_DUPLICATE",
                        message: "Script label \(label) appears \(matches.count) times in editable map script sources."
                    )
                ]
            )
        }

        return MapScriptResolution(
            label: label,
            state: .missingLabel,
            diagnostics: [
                Diagnostic(
                    severity: .warning,
                    code: "MAP_SCRIPT_LABEL_MISSING",
                    message: "Script label \(label) is not defined in this map's editable script sources."
                )
            ]
        )
    }

    public func suggestions(
        matching query: String,
        includeShared: Bool = true,
        limit: Int = 12
    ) -> [MapScriptLabelSpan] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidates = labels
            .filter { includeShared || $0.sourceRole == .mapLocal }
            .filter { $0.label != "NULL" }

        let filtered: [MapScriptLabelSpan]
        if trimmed.isEmpty || trimmed == "0x0" {
            filtered = candidates
        } else {
            filtered = candidates.filter {
                $0.label.localizedCaseInsensitiveContains(trimmed)
                    || $0.sourcePath.localizedCaseInsensitiveContains(trimmed)
            }
        }

        return Array(
            filtered
                .sorted { lhs, rhs in
                    if lhs.sourceRole == rhs.sourceRole {
                        return lhs.label < rhs.label
                    }
                    return lhs.sourceRole == .mapLocal
                }
                .prefix(max(limit, 0))
        )
    }

    public static func normalizedScriptLabel(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "0x0", trimmed != "NULL" else { return nil }
        guard trimmed.range(of: #"^[A-Za-z_][A-Za-z0-9_]*$"#, options: .regularExpression) != nil else {
            return nil
        }
        return trimmed
    }

    public static func isEditableScriptPath(_ path: String) -> Bool {
        path.range(of: #"^data/maps/[^/]+/scripts\.inc$"#, options: .regularExpression) != nil
    }
}

public enum MapScriptIndexLoader {
    public static func load(
        root: URL,
        mapName: String,
        sharedMapName: String? = nil,
        fileManager: FileManager = .default
    ) -> MapScriptIndex {
        let root = root.standardizedFileURL
        var sources: [MapScriptSource] = []
        var labels: [MapScriptLabelSpan] = []
        var diagnostics: [Diagnostic] = []

        appendSource(
            mapName: mapName,
            role: .mapLocal,
            root: root,
            fileManager: fileManager,
            sources: &sources,
            labels: &labels,
            diagnostics: &diagnostics
        )

        if let sharedMapName, sharedMapName != mapName {
            appendSource(
                mapName: sharedMapName,
                role: .shared,
                root: root,
                fileManager: fileManager,
                sources: &sources,
                labels: &labels,
                diagnostics: &diagnostics
            )
        }

        diagnostics.append(contentsOf: duplicateDiagnostics(labels: labels))
        return MapScriptIndex(rootPath: root.path, mapName: mapName, sources: sources, labels: labels, diagnostics: diagnostics)
    }

    public static func parseLabels(source: MapScriptSource) -> [MapScriptLabelSpan] {
        let lines = source.text.components(separatedBy: "\n")
        var labelStarts: [(label: String, lineIndex: Int)] = []

        for (index, line) in lines.enumerated() {
            guard let label = label(in: line) else { continue }
            labelStarts.append((label: label, lineIndex: index))
        }

        return labelStarts.enumerated().map { offset, start in
            let nextLineIndex = offset + 1 < labelStarts.count ? labelStarts[offset + 1].lineIndex : lines.count
            let bodyStartIndex = min(start.lineIndex + 1, lines.count)
            let bodyEndExclusive = max(bodyStartIndex, nextLineIndex)
            let body = lines[bodyStartIndex..<bodyEndExclusive].joined(separator: "\n")
            return MapScriptLabelSpan(
                label: start.label,
                sourcePath: source.path,
                sourceRole: source.role,
                labelLine: start.lineIndex + 1,
                bodyStartLine: bodyStartIndex + 1,
                bodyEndLine: bodyEndExclusive,
                body: body
            )
        }
    }

    private static func appendSource(
        mapName: String,
        role: MapScriptSourceRole,
        root: URL,
        fileManager: FileManager,
        sources: inout [MapScriptSource],
        labels: inout [MapScriptLabelSpan],
        diagnostics: inout [Diagnostic]
    ) {
        let path = "data/maps/\(mapName)/scripts.inc"
        let url = root.appendingPathComponent(path)
        guard fileManager.fileExists(atPath: url.path) else {
            sources.append(MapScriptSource(path: path, role: role, exists: false, text: ""))
            diagnostics.append(
                Diagnostic(
                    severity: .info,
                    code: "MAP_SCRIPT_SOURCE_MISSING",
                    message: "\(path) does not exist; inline script editing is unavailable for this source.",
                    span: SourceSpan(relativePath: path, startLine: 1)
                )
            )
            return
        }

        let text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        let source = MapScriptSource(path: path, role: role, exists: true, text: text)
        sources.append(source)
        labels.append(contentsOf: parseLabels(source: source))
    }

    private static func label(in line: String) -> String? {
        let pattern = #"^([A-Za-z_][A-Za-z0-9_]*)(::?)\s*(?:@.*)?$"#
        guard let match = line.range(of: pattern, options: .regularExpression) else { return nil }
        let matched = String(line[match])
        guard let separator = matched.firstIndex(of: ":") else { return nil }
        return String(matched[..<separator])
    }

    private static func duplicateDiagnostics(labels: [MapScriptLabelSpan]) -> [Diagnostic] {
        let grouped = Dictionary(grouping: labels, by: \.label)
        return grouped.compactMap { label, spans in
            guard spans.count > 1 else { return nil }
            let first = spans[0]
            return Diagnostic(
                severity: .error,
                code: "MAP_SCRIPT_LABEL_DUPLICATE",
                message: "Script label \(label) appears \(spans.count) times in editable map script sources.",
                span: SourceSpan(relativePath: first.sourcePath, startLine: first.labelLine)
            )
        }
    }
}
