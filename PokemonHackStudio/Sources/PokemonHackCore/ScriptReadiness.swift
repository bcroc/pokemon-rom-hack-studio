import Foundation

public enum ScriptReadinessTargetKind: String, Codable, Equatable, CaseIterable {
    case map
    case script
}

public struct ScriptReadinessTarget: Codable, Equatable, Identifiable {
    public var id: String { "\(kind.rawValue):\(identifier)" }

    public let kind: ScriptReadinessTargetKind
    public let identifier: String

    public init(kind: ScriptReadinessTargetKind, identifier: String) {
        self.kind = kind
        self.identifier = identifier
    }
}

public enum ScriptReadinessCheckCategory: String, Codable, Equatable, CaseIterable {
    case source
    case build
    case playtest
    case workflow
}

public enum ScriptReadinessCheckStatus: String, Codable, Equatable, CaseIterable {
    case passed
    case needsReview
    case blocked
    case info
}

public struct ScriptReadinessCheck: Codable, Equatable, Identifiable {
    public let id: String
    public let category: ScriptReadinessCheckCategory
    public let title: String
    public let detail: String
    public let status: ScriptReadinessCheckStatus
    public let sourceSpan: SourceSpan?
    public let diagnostic: Diagnostic?

    public init(
        id: String,
        category: ScriptReadinessCheckCategory,
        title: String,
        detail: String,
        status: ScriptReadinessCheckStatus,
        sourceSpan: SourceSpan? = nil,
        diagnostic: Diagnostic? = nil
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.detail = detail
        self.status = status
        self.sourceSpan = sourceSpan
        self.diagnostic = diagnostic
    }
}

public struct ScriptReadinessMapContext: Codable, Equatable {
    public let mapID: String
    public let mapName: String
    public let sourcePath: String
    public let layoutID: String?
    public let scriptSourcePaths: [String]
    public let eventScriptLabels: [String]

    public init(
        mapID: String,
        mapName: String,
        sourcePath: String,
        layoutID: String?,
        scriptSourcePaths: [String],
        eventScriptLabels: [String]
    ) {
        self.mapID = mapID
        self.mapName = mapName
        self.sourcePath = sourcePath
        self.layoutID = layoutID
        self.scriptSourcePaths = scriptSourcePaths
        self.eventScriptLabels = eventScriptLabels
    }
}

public struct ScriptReadinessScriptContext: Codable, Equatable {
    public let label: String
    public let kind: ScriptOutlineLabelKind
    public let sourcePath: String
    public let sourceRole: MapScriptSourceRole
    public let sourceSpan: SourceSpan
    public let commandCount: Int
    public let textReferenceCount: Int

    public init(
        label: String,
        kind: ScriptOutlineLabelKind,
        sourcePath: String,
        sourceRole: MapScriptSourceRole,
        sourceSpan: SourceSpan,
        commandCount: Int,
        textReferenceCount: Int
    ) {
        self.label = label
        self.kind = kind
        self.sourcePath = sourcePath
        self.sourceRole = sourceRole
        self.sourceSpan = sourceSpan
        self.commandCount = commandCount
        self.textReferenceCount = textReferenceCount
    }
}

public struct ScriptReadinessReport: Codable, Equatable {
    public let adapterID: String
    public let adapterName: String
    public let profile: GameProfile
    public let rootPath: String
    public let target: ScriptReadinessTarget
    public let mapContext: ScriptReadinessMapContext?
    public let scriptContext: ScriptReadinessScriptContext?
    public let buildReport: BuildValidationReport
    public let playtestReport: PlaytestHandoffReport
    public let checks: [ScriptReadinessCheck]
    public let diagnostics: [Diagnostic]
    public let status: ScriptReadinessCheckStatus
    public let isReady: Bool
    public let isReadOnly: Bool

    public init(
        adapterID: String,
        adapterName: String,
        profile: GameProfile,
        rootPath: String,
        target: ScriptReadinessTarget,
        mapContext: ScriptReadinessMapContext?,
        scriptContext: ScriptReadinessScriptContext?,
        buildReport: BuildValidationReport,
        playtestReport: PlaytestHandoffReport,
        checks: [ScriptReadinessCheck],
        isReadOnly: Bool = true
    ) {
        self.adapterID = adapterID
        self.adapterName = adapterName
        self.profile = profile
        self.rootPath = rootPath
        self.target = target
        self.mapContext = mapContext
        self.scriptContext = scriptContext
        self.buildReport = buildReport
        self.playtestReport = playtestReport
        self.checks = checks
        self.diagnostics = checks.compactMap(\.diagnostic)
        self.status = Self.status(for: checks)
        self.isReady = self.status == .passed
        self.isReadOnly = isReadOnly
    }

    private static func status(for checks: [ScriptReadinessCheck]) -> ScriptReadinessCheckStatus {
        if checks.contains(where: { $0.status == .blocked }) {
            return .blocked
        }
        if checks.contains(where: { $0.status == .needsReview }) {
            return .needsReview
        }
        return .passed
    }
}

public enum ScriptReadinessReportBuilder {
    public static func build(
        index: ProjectIndex,
        target: ScriptReadinessTarget,
        fileManager: FileManager = .default,
        toolResolver: ToolAvailabilityResolver = ToolAvailabilityResolverFactory.pathEnvironment()
    ) -> ScriptReadinessReport {
        let root = URL(fileURLWithPath: index.root.path).standardizedFileURL
        let buildReport = BuildValidationReportBuilder.build(
            index: index,
            fileManager: fileManager,
            toolResolver: toolResolver
        )
        let playtestReport = PlaytestHandoffReportBuilder.build(
            index: index,
            mode: .headless,
            fileManager: fileManager,
            toolResolver: toolResolver
        )

        var checks = baseChecks(index: index, root: root, fileManager: fileManager)
        let targetEvaluation = evaluateTarget(
            target,
            index: index,
            root: root,
            fileManager: fileManager
        )
        checks.append(contentsOf: targetEvaluation.checks)
        checks.append(contentsOf: buildChecks(buildReport: buildReport, playtestReport: playtestReport))
        checks.append(contentsOf: playtestChecks(playtestReport: playtestReport))
        checks.append(
            check(
                id: "workflow:read-only",
                category: .workflow,
                title: "Read-only workflow",
                detail: "This report reads source files, build outputs, PATH, and mGBA availability; it does not write source, build, patch, or emulator state.",
                status: .info
            )
        )

        return ScriptReadinessReport(
            adapterID: index.adapterID,
            adapterName: index.adapterName,
            profile: index.profile,
            rootPath: root.path,
            target: target,
            mapContext: targetEvaluation.mapContext,
            scriptContext: targetEvaluation.scriptContext,
            buildReport: buildReport,
            playtestReport: playtestReport,
            checks: checks
        )
    }

    private struct TargetEvaluation {
        let mapContext: ScriptReadinessMapContext?
        let scriptContext: ScriptReadinessScriptContext?
        let checks: [ScriptReadinessCheck]
    }

    private struct MapScriptReference: Equatable {
        let label: String
        let eventKind: String
        let index: Int
    }

    private struct ScriptReadinessSourceLabel: Equatable {
        let label: String
        let sourcePath: String
        let sourceSpan: SourceSpan
        let scope: String
    }

    private static func baseChecks(
        index: ProjectIndex,
        root: URL,
        fileManager: FileManager
    ) -> [ScriptReadinessCheck] {
        var checks: [ScriptReadinessCheck] = []
        checks.append(
            check(
                id: "source:project-root",
                category: .source,
                title: "Project root",
                detail: fileManager.fileExists(atPath: root.path) ? root.path : "Project root is not available: \(root.path).",
                status: fileManager.fileExists(atPath: root.path) ? .passed : .blocked
            )
        )
        checks.append(
            check(
                id: "source:script-capability",
                category: .source,
                title: "Script outline capability",
                detail: index.capabilities.contains(.scriptOutline)
                    ? "\(index.adapterName) exposes script outline data."
                    : "\(index.adapterName) does not expose script outline data.",
                status: index.capabilities.contains(.scriptOutline) ? .passed : .blocked
            )
        )

        let blockingProjectDiagnostics = index.diagnostics.filter { $0.severity == .error }
        let reviewProjectDiagnostics = index.diagnostics.filter { $0.severity == .warning }
        if !blockingProjectDiagnostics.isEmpty {
            checks.append(
                diagnosticCheck(
                    id: "source:project-diagnostics:error",
                    category: .source,
                    title: "Project diagnostics",
                    detail: "\(blockingProjectDiagnostics.count) project diagnostic(s) block script readiness.",
                    status: .blocked,
                    diagnostic: blockingProjectDiagnostics[0]
                )
            )
        } else if !reviewProjectDiagnostics.isEmpty {
            checks.append(
                diagnosticCheck(
                    id: "source:project-diagnostics:warning",
                    category: .source,
                    title: "Project diagnostics",
                    detail: "\(reviewProjectDiagnostics.count) project diagnostic(s) need review before a live script loop.",
                    status: .needsReview,
                    diagnostic: reviewProjectDiagnostics[0]
                )
            )
        } else {
            checks.append(
                check(
                    id: "source:project-diagnostics:clean",
                    category: .source,
                    title: "Project diagnostics",
                    detail: "The selected project index has no diagnostics.",
                    status: .passed
                )
            )
        }

        return checks
    }

    private static func evaluateTarget(
        _ target: ScriptReadinessTarget,
        index: ProjectIndex,
        root: URL,
        fileManager: FileManager
    ) -> TargetEvaluation {
        switch target.kind {
        case .map:
            return evaluateMapTarget(target.identifier, index: index, root: root, fileManager: fileManager)
        case .script:
            return evaluateScriptTarget(target.identifier, index: index, root: root, fileManager: fileManager)
        }
    }

    private static func evaluateMapTarget(
        _ identifier: String,
        index: ProjectIndex,
        root: URL,
        fileManager: FileManager
    ) -> TargetEvaluation {
        var checks: [ScriptReadinessCheck] = []
        let catalog: ProjectMapCatalog
        do {
            catalog = try ProjectMapCatalogLoader.load(from: index, fileManager: fileManager)
            checks.append(
                check(
                    id: "source:map-catalog",
                    category: .source,
                    title: "Map catalog",
                    detail: "\(catalog.maps.count) map(s) are available for script readiness selection.",
                    status: .passed
                )
            )
        } catch {
            checks.append(
                check(
                    id: "source:map-catalog",
                    category: .source,
                    title: "Map catalog",
                    detail: "Map catalog could not be loaded: \(error.localizedDescription)",
                    status: .blocked
                )
            )
            return TargetEvaluation(mapContext: nil, scriptContext: nil, checks: checks)
        }

        guard let map = map(matching: identifier, in: catalog) else {
            checks.append(
                check(
                    id: "source:map-target",
                    category: .source,
                    title: "Selected map",
                    detail: "No map matched \(identifier).",
                    status: .blocked
                )
            )
            return TargetEvaluation(mapContext: nil, scriptContext: nil, checks: checks)
        }

        checks.append(
            check(
                id: "source:map-target",
                category: .source,
                title: "Selected map",
                detail: "\(map.name) resolves to \(map.id).",
                status: .passed,
                sourceSpan: SourceSpan(relativePath: map.sourcePath, startLine: 1)
            )
        )

        let mapURL = root.appendingPathComponent(map.sourcePath)
        let mapSourceExists = fileManager.fileExists(atPath: mapURL.path)
        checks.append(
            check(
                id: "source:map-json",
                category: .source,
                title: "Map JSON",
                detail: mapSourceExists ? "\(map.sourcePath) is readable for event script references." : "\(map.sourcePath) is missing.",
                status: mapSourceExists ? .passed : .blocked,
                sourceSpan: SourceSpan(relativePath: map.sourcePath, startLine: 1)
            )
        )

        if let layoutID = map.layout {
            let hasLayout = catalog.layoutSlots.contains { $0.layoutID == layoutID }
            checks.append(
                check(
                    id: "source:map-layout",
                    category: .source,
                    title: "Map layout",
                    detail: hasLayout ? "\(layoutID) is present in layouts.json." : "\(layoutID) is referenced but not present in layouts.json.",
                    status: hasLayout ? .passed : .needsReview,
                    sourceSpan: SourceSpan(relativePath: map.sourcePath, startLine: 1)
                )
            )
        }

        let scriptIndex = MapScriptIndexLoader.load(
            root: root,
            mapName: map.name,
            sharedMapName: sharedScriptMapName(for: map, in: catalog),
            fileManager: fileManager
        )
        let projectOutline = try? ProjectScriptOutlineLoader.load(from: index, fileManager: fileManager)
        let projectLabelsByName = Dictionary(
            grouping: projectSourceLabels(
                index: index,
                outline: projectOutline,
                root: root,
                fileManager: fileManager
            ),
            by: \.label
        )
        checks.append(
            check(
                id: "source:project-script-outline",
                category: .source,
                title: "Project script outline",
                detail: projectOutline.map { "\($0.labels.count) outline label(s) plus assembly labels are available for global script references." }
                    ?? "Project-wide script outline could not be loaded for global script references.",
                status: projectOutline == nil ? .needsReview : .passed
            )
        )
        let existingSources = scriptIndex.sources.filter(\.exists)
        checks.append(
            check(
                id: "source:map-script-sources",
                category: .source,
                title: "Map script sources",
                detail: existingSources.isEmpty
                    ? "No editable or shared map script source was found for \(map.name)."
                    : existingSources.map(\.path).joined(separator: ", "),
                status: existingSources.isEmpty ? .needsReview : .passed,
                sourceSpan: SourceSpan(relativePath: "data/maps/\(map.name)/scripts.inc", startLine: 1)
            )
        )
        checks.append(contentsOf: scriptIndex.diagnostics.map { diagnostic in
            diagnosticCheck(
                id: "source:map-script-diagnostic:\(diagnostic.code):\(diagnostic.span?.relativePath ?? "global")",
                category: .source,
                title: diagnostic.code,
                detail: diagnostic.message,
                status: status(for: diagnostic.severity),
                diagnostic: diagnostic
            )
        })

        let references = mapSourceExists ? eventScriptReferences(from: mapURL) : []
        if references.isEmpty {
            checks.append(
                check(
                    id: "source:event-script-references",
                    category: .source,
                    title: "Event script references",
                    detail: "The selected map has no normalized event script references.",
                    status: .info,
                    sourceSpan: SourceSpan(relativePath: map.sourcePath, startLine: 1)
                )
            )
        } else {
            for reference in references {
                let resolution = scriptIndex.resolution(for: reference.label)
                checks.append(
                    eventScriptCheck(
                        reference: reference,
                        mapSourcePath: map.sourcePath,
                        mapResolution: resolution,
                        projectMatches: projectLabelsByName[reference.label] ?? []
                    )
                )
            }
        }

        let context = ScriptReadinessMapContext(
            mapID: map.id,
            mapName: map.name,
            sourcePath: map.sourcePath,
            layoutID: map.layout,
            scriptSourcePaths: scriptIndex.sources.map(\.path),
            eventScriptLabels: Array(Set(references.map(\.label))).sorted()
        )
        return TargetEvaluation(mapContext: context, scriptContext: nil, checks: checks)
    }

    private static func evaluateScriptTarget(
        _ label: String,
        index: ProjectIndex,
        root: URL,
        fileManager: FileManager
    ) -> TargetEvaluation {
        var checks: [ScriptReadinessCheck] = []
        let outline: ProjectScriptOutline
        do {
            outline = try ProjectScriptOutlineLoader.load(from: index, fileManager: fileManager)
            checks.append(
                check(
                    id: "source:script-outline",
                    category: .source,
                    title: "Script outline",
                    detail: "\(outline.labels.count) labels are available for script readiness selection.",
                    status: .passed
                )
            )
        } catch {
            checks.append(
                check(
                    id: "source:script-outline",
                    category: .source,
                    title: "Script outline",
                    detail: "Script outline could not be loaded: \(error.localizedDescription)",
                    status: .blocked
                )
            )
            return TargetEvaluation(mapContext: nil, scriptContext: nil, checks: checks)
        }

        let matches = outline.labels.filter { $0.label == label }
        guard matches.count == 1, let match = matches.first else {
            checks.append(
                check(
                    id: "source:script-target",
                    category: .source,
                    title: "Selected script",
                    detail: matches.isEmpty
                        ? "No script label matched \(label)."
                        : "Script label \(label) appears \(matches.count) times.",
                    status: .blocked
                )
            )
            return TargetEvaluation(mapContext: nil, scriptContext: nil, checks: checks)
        }

        checks.append(
            check(
                id: "source:script-target",
                category: .source,
                title: "Selected script",
                detail: "\(match.label) resolves to \(match.sourcePath):\(match.sourceSpan.startLine).",
                status: .passed,
                sourceSpan: match.sourceSpan
            )
        )

        let sourceURL = root.appendingPathComponent(match.sourcePath)
        let sourceExists = fileManager.fileExists(atPath: sourceURL.path)
        checks.append(
            check(
                id: "source:script-file",
                category: .source,
                title: "Script source file",
                detail: sourceExists ? "\(match.sourcePath) exists." : "\(match.sourcePath) is missing.",
                status: sourceExists ? .passed : .blocked,
                sourceSpan: SourceSpan(relativePath: match.sourcePath, startLine: 1)
            )
        )

        checks.append(
            check(
                id: "source:script-kind",
                category: .source,
                title: "Script label kind",
                detail: "\(match.kind.title) label with \(match.commands.count) command(s) and \(match.textReferences.count) text reference(s).",
                status: match.kind == .script ? .passed : .needsReview,
                sourceSpan: match.sourceSpan
            )
        )
        checks.append(contentsOf: match.diagnostics.map { diagnostic in
            diagnosticCheck(
                id: "source:script-diagnostic:\(diagnostic.code):\(diagnostic.span?.startLine ?? match.sourceSpan.startLine)",
                category: .source,
                title: diagnostic.code,
                detail: diagnostic.message,
                status: status(for: diagnostic.severity),
                diagnostic: diagnostic
            )
        })

        let context = ScriptReadinessScriptContext(
            label: match.label,
            kind: match.kind,
            sourcePath: match.sourcePath,
            sourceRole: match.sourceRole,
            sourceSpan: match.sourceSpan,
            commandCount: match.commands.count,
            textReferenceCount: match.textReferences.count
        )
        return TargetEvaluation(mapContext: nil, scriptContext: context, checks: checks)
    }

    private static func buildChecks(
        buildReport: BuildValidationReport,
        playtestReport: PlaytestHandoffReport
    ) -> [ScriptReadinessCheck] {
        guard !buildReport.targets.isEmpty else {
            return [
                check(
                    id: "build:targets",
                    category: .build,
                    title: "Build targets",
                    detail: "No build target is available before playtest.",
                    status: .blocked
                )
            ]
        }

        let relevantTargets = relevantBuildTargets(buildReport: buildReport, playtestReport: playtestReport)
        var checks: [ScriptReadinessCheck] = [
            check(
                id: "build:targets",
                category: .build,
                title: "Build targets",
                detail: "\(buildReport.targets.count) build target(s) are declared; \(relevantTargets.count) target(s) feed the selected playtest ROM candidate.",
                status: .passed
            )
        ]

        for target in relevantTargets {
            if let tool = target.commandTool {
                checks.append(
                    check(
                        id: "build:tool:\(target.id):\(tool.name)",
                        category: .build,
                        title: tool.name,
                        detail: tool.isAvailable ? "\(tool.name) resolved at \(tool.resolvedPath ?? "PATH")." : "\(tool.name) was not found.",
                        status: tool.isAvailable ? .passed : .blocked
                    )
                )
            }

            if let output = target.output {
                checks.append(
                    check(
                        id: "build:output:\(target.id)",
                        category: .build,
                        title: target.target.name,
                        detail: output.exists
                            ? "\(output.relativePath) exists; checksum \(output.checksumStatus.rawValue); freshness \(output.freshnessStatus.rawValue)."
                            : "\(output.relativePath) is missing.",
                        status: buildOutputStatus(output),
                        sourceSpan: SourceSpan(relativePath: output.relativePath, startLine: 1)
                    )
                )
            }

            checks.append(contentsOf: target.diagnostics.map { diagnostic in
                diagnosticCheck(
                    id: "build:diagnostic:\(target.id):\(diagnostic.code)",
                    category: .build,
                    title: diagnostic.code,
                    detail: diagnostic.message,
                    status: buildDiagnosticStatus(diagnostic),
                    diagnostic: diagnostic
                )
            })
        }

        return checks
    }

    private static func relevantBuildTargets(
        buildReport: BuildValidationReport,
        playtestReport: PlaytestHandoffReport
    ) -> [BuildTargetValidation] {
        if let targetID = playtestReport.romCandidate?.targetID,
           let target = buildReport.targets.first(where: { $0.id == targetID }) {
            return [target]
        }
        return Array(buildReport.targets.prefix(1))
    }

    private static func playtestChecks(
        playtestReport: PlaytestHandoffReport
    ) -> [ScriptReadinessCheck] {
        var checks: [ScriptReadinessCheck] = [
            check(
                id: "playtest:plan-only",
                category: .playtest,
                title: "Playtest plan",
                detail: "Handoff is evaluated in headless mode and does not launch mGBA.",
                status: .info
            )
        ]

        if let candidate = playtestReport.romCandidate {
            checks.append(
                check(
                    id: "playtest:rom-candidate",
                    category: .playtest,
                    title: "ROM candidate",
                    detail: candidate.exists
                        ? "\(candidate.relativePath ?? candidate.absolutePath) is available for mGBA handoff."
                        : "\(candidate.relativePath ?? candidate.absolutePath) is declared but missing.",
                    status: candidate.exists ? .passed : .blocked,
                    sourceSpan: SourceSpan(relativePath: candidate.relativePath ?? candidate.absolutePath, startLine: 1)
                )
            )
        } else {
            checks.append(
                check(
                    id: "playtest:rom-candidate",
                    category: .playtest,
                    title: "ROM candidate",
                    detail: "No .gba output is declared for playtest handoff.",
                    status: .blocked
                )
            )
        }

        checks.append(
            check(
                id: "playtest:emulator",
                category: .playtest,
                title: playtestReport.emulator.name,
                detail: playtestReport.emulator.isAvailable
                    ? "\(playtestReport.emulator.name) resolved at \(playtestReport.emulator.resolvedPath ?? "PATH")."
                    : "mGBA was not found in PATH or common macOS application locations.",
                status: playtestReport.emulator.isAvailable ? .passed : .blocked
            )
        )
        checks.append(
            check(
                id: "playtest:runnable",
                category: .playtest,
                title: "Headless handoff",
                detail: playtestReport.isRunnable ? "ROM output and emulator are available." : "ROM output and emulator prerequisites are incomplete.",
                status: playtestReport.isRunnable ? .passed : .blocked
            )
        )

        return checks
    }

    private static func buildOutputStatus(_ output: BuildOutputValidation) -> ScriptReadinessCheckStatus {
        guard output.exists else { return .blocked }
        switch output.checksumStatus {
        case .mismatched, .unreadable:
            return .blocked
        case .outputMissing:
            return .blocked
        case .matched, .expectationMissing, .notApplicable:
            break
        }

        switch output.freshnessStatus {
        case .stale, .unknown, .noSourceModifiedTimes:
            return .needsReview
        case .outputMissing:
            return .blocked
        case .fresh, .notApplicable:
            return .passed
        }
    }

    private static func buildDiagnosticStatus(_ diagnostic: Diagnostic) -> ScriptReadinessCheckStatus {
        if diagnostic.code == "BUILD_OUTPUT_MISSING" {
            return .blocked
        }
        if diagnostic.code == "BUILD_OUTPUT_STALE" {
            return .needsReview
        }
        return status(for: diagnostic.severity)
    }

    private static func status(for severity: DiagnosticSeverity) -> ScriptReadinessCheckStatus {
        switch severity {
        case .info:
            return .info
        case .warning:
            return .needsReview
        case .error:
            return .blocked
        }
    }

    private static func map(matching identifier: String, in catalog: ProjectMapCatalog) -> MapDescriptor? {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        if let exact = catalog.maps.first(where: { $0.id == trimmed || $0.name == trimmed }) {
            return exact
        }
        return catalog.maps.first {
            $0.id.caseInsensitiveCompare(trimmed) == .orderedSame
                || $0.name.caseInsensitiveCompare(trimmed) == .orderedSame
        }
    }

    private static func sharedScriptMapName(for map: MapDescriptor, in catalog: ProjectMapCatalog) -> String? {
        guard let sharedScriptsMap = map.sharedScriptsMap else { return nil }
        return catalog.maps.first { $0.id == sharedScriptsMap || $0.name == sharedScriptsMap }?.name ?? sharedScriptsMap
    }

    private static func eventScriptReferences(from mapURL: URL) -> [MapScriptReference] {
        guard let data = try? Data(contentsOf: mapURL),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }

        let arrays: [(String, String)] = [
            ("object_events", "object"),
            ("coord_events", "coord"),
            ("bg_events", "bg")
        ]
        var references: [MapScriptReference] = []
        var seen: Set<String> = []

        for (arrayKey, eventKind) in arrays {
            guard let events = object[arrayKey] as? [[String: Any]] else { continue }
            for (index, event) in events.enumerated() {
                guard let raw = event["script"] as? String,
                      let label = MapScriptIndex.normalizedScriptLabel(raw) else {
                    continue
                }
                let key = "\(eventKind):\(index):\(label)"
                guard seen.insert(key).inserted else { continue }
                references.append(MapScriptReference(label: label, eventKind: eventKind, index: index))
            }
        }

        return references
    }

    private static func projectSourceLabels(
        index: ProjectIndex,
        outline: ProjectScriptOutline?,
        root: URL,
        fileManager: FileManager
    ) -> [ScriptReadinessSourceLabel] {
        var labels = (outline?.labels ?? []).map {
            ScriptReadinessSourceLabel(
                label: $0.label,
                sourcePath: $0.sourcePath,
                sourceSpan: $0.sourceSpan,
                scope: "project script outline"
            )
        }
        labels.append(contentsOf: assemblyLabels(index: index, root: root, fileManager: fileManager))
        return labels
    }

    private static func assemblyLabels(
        index: ProjectIndex,
        root: URL,
        fileManager: FileManager
    ) -> [ScriptReadinessSourceLabel] {
        let documentPaths = index.documents
            .filter { $0.kind == .assembly && $0.exists }
            .map(\.relativePath)
        let candidatePaths = Array(Set(documentPaths + ["data/event_scripts.s"])).sorted()

        return candidatePaths.flatMap { path -> [ScriptReadinessSourceLabel] in
            let url = root.appendingPathComponent(path)
            guard fileManager.fileExists(atPath: url.path),
                  let text = try? String(contentsOf: url, encoding: .utf8) else {
                return []
            }
            let source = MapScriptSource(path: path, role: .shared, exists: true, text: text)
            return MapScriptIndexLoader.parseLabels(source: source).map {
                ScriptReadinessSourceLabel(
                    label: $0.label,
                    sourcePath: $0.sourcePath,
                    sourceSpan: SourceSpan(relativePath: $0.sourcePath, startLine: $0.labelLine, endLine: $0.bodyEndLine),
                    scope: "assembly source"
                )
            }
        }
    }

    private static func eventScriptCheck(
        reference: MapScriptReference,
        mapSourcePath: String,
        mapResolution: MapScriptResolution,
        projectMatches: [ScriptReadinessSourceLabel]
    ) -> ScriptReadinessCheck {
        let id = "source:event-script:\(reference.label):\(reference.eventKind):\(reference.index)"
        if mapResolution.state == .resolved, let span = mapResolution.span {
            return check(
                id: id,
                category: .source,
                title: reference.label,
                detail: eventScriptDetail(reference: reference, sourcePath: span.sourcePath, scope: "map script"),
                status: .passed,
                sourceSpan: SourceSpan(relativePath: span.sourcePath, startLine: span.labelLine, endLine: span.bodyEndLine)
            )
        }

        if projectMatches.count == 1, let match = projectMatches.first {
            return check(
                id: id,
                category: .source,
                title: reference.label,
                detail: eventScriptDetail(reference: reference, sourcePath: match.sourcePath, scope: match.scope),
                status: .passed,
                sourceSpan: match.sourceSpan
            )
        }

        if projectMatches.count > 1 {
            return check(
                id: id,
                category: .source,
                title: reference.label,
                detail: "\(reference.eventKind) event \(reference.index) references \(reference.label), but the project-wide label is duplicated.",
                status: .blocked,
                sourceSpan: projectMatches.first?.sourceSpan ?? SourceSpan(relativePath: mapSourcePath, startLine: 1)
            )
        }

        return check(
            id: id,
            category: .source,
            title: reference.label,
            detail: eventScriptDetail(reference: reference, resolution: mapResolution),
            status: .blocked,
            sourceSpan: SourceSpan(relativePath: mapSourcePath, startLine: 1),
            diagnostic: mapResolution.diagnostics.first
        )
    }

    private static func eventScriptDetail(
        reference: MapScriptReference,
        sourcePath: String,
        scope: String
    ) -> String {
        "\(reference.eventKind) event \(reference.index) resolves through \(scope) at \(sourcePath)."
    }

    private static func eventScriptDetail(
        reference: MapScriptReference,
        resolution: MapScriptResolution
    ) -> String {
        switch resolution.state {
        case .resolved:
            return "\(reference.eventKind) event \(reference.index) resolves to \(resolution.span?.sourcePath ?? "script source")."
        case .noScript:
            return "\(reference.eventKind) event \(reference.index) has no normalized script label."
        case .missingLabel:
            return "\(reference.eventKind) event \(reference.index) references \(reference.label), but no label was found."
        case .duplicateLabel:
            return "\(reference.eventKind) event \(reference.index) references \(reference.label), but the label is duplicated."
        case .generatedPath:
            return "\(reference.eventKind) event \(reference.index) resolves to a generated or unsupported source path."
        case .externalLabel:
            return "\(reference.eventKind) event \(reference.index) resolves outside the selected map script sources."
        }
    }

    private static func check(
        id: String,
        category: ScriptReadinessCheckCategory,
        title: String,
        detail: String,
        status: ScriptReadinessCheckStatus,
        sourceSpan: SourceSpan? = nil,
        diagnostic providedDiagnostic: Diagnostic? = nil
    ) -> ScriptReadinessCheck {
        let diagnostic = providedDiagnostic ?? readinessDiagnostic(for: id, title: title, detail: detail, status: status, sourceSpan: sourceSpan)
        return ScriptReadinessCheck(
            id: id,
            category: category,
            title: title,
            detail: detail,
            status: status,
            sourceSpan: sourceSpan,
            diagnostic: diagnostic
        )
    }

    private static func diagnosticCheck(
        id: String,
        category: ScriptReadinessCheckCategory,
        title: String,
        detail: String,
        status: ScriptReadinessCheckStatus,
        diagnostic: Diagnostic
    ) -> ScriptReadinessCheck {
        ScriptReadinessCheck(
            id: id,
            category: category,
            title: title,
            detail: detail,
            status: status,
            sourceSpan: diagnostic.span,
            diagnostic: diagnostic
        )
    }

    private static func readinessDiagnostic(
        for id: String,
        title: String,
        detail: String,
        status: ScriptReadinessCheckStatus,
        sourceSpan: SourceSpan?
    ) -> Diagnostic? {
        let severity: DiagnosticSeverity
        switch status {
        case .passed, .info:
            return nil
        case .needsReview:
            severity = .warning
        case .blocked:
            severity = .error
        }

        return Diagnostic(
            id: "SCRIPT_READINESS:\(id)",
            severity: severity,
            code: "SCRIPT_READINESS_\(status.rawValue.uppercased())",
            message: "\(title): \(detail)",
            span: sourceSpan
        )
    }
}
