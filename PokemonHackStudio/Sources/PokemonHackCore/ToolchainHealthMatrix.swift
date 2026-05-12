import Foundation

public enum ToolchainHealthCategory: String, Codable, Equatable, CaseIterable {
    case externalTools
    case romHeaders
    case graphicsConversion
    case generatedArtifacts
}

public enum ToolchainHealthStatus: String, Codable, Equatable, CaseIterable {
    case ready
    case warning
    case error
    case notApplicable
}

public enum ToolchainHealthActionKind: String, Codable, Equatable, CaseIterable {
    case copyCommand
    case copyPath
    case rerunGuidance
}

public struct ToolchainHealthAction: Codable, Equatable, Identifiable {
    public let id: String
    public let kind: ToolchainHealthActionKind
    public let title: String
    public let detail: String
    public let command: String?
    public let payload: String?
    public let isPreviewOnly: Bool

    public init(
        id: String,
        kind: ToolchainHealthActionKind,
        title: String,
        detail: String,
        command: String? = nil,
        payload: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detail = detail
        self.command = command
        self.payload = payload
        self.isPreviewOnly = true
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case title
        case detail
        case command
        case payload
        case isPreviewOnly
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        kind = try container.decode(ToolchainHealthActionKind.self, forKey: .kind)
        title = try container.decode(String.self, forKey: .title)
        detail = try container.decode(String.self, forKey: .detail)
        command = try container.decodeIfPresent(String.self, forKey: .command)
        payload = try container.decodeIfPresent(String.self, forKey: .payload)
        isPreviewOnly = true
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(kind, forKey: .kind)
        try container.encode(title, forKey: .title)
        try container.encode(detail, forKey: .detail)
        try container.encodeIfPresent(command, forKey: .command)
        try container.encodeIfPresent(payload, forKey: .payload)
        try container.encode(true, forKey: .isPreviewOnly)
    }
}

public struct ToolchainHealthMatrixRow: Codable, Equatable, Identifiable {
    public let id: String
    public let category: ToolchainHealthCategory
    public let title: String
    public let subject: String
    public let status: ToolchainHealthStatus
    public let detail: String
    public let source: SourceSpan?
    public let resolvedPath: String?
    public let diagnostics: [Diagnostic]
    public let actions: [ToolchainHealthAction]

    public init(
        id: String,
        category: ToolchainHealthCategory,
        title: String,
        subject: String,
        status: ToolchainHealthStatus,
        detail: String,
        source: SourceSpan? = nil,
        resolvedPath: String? = nil,
        diagnostics: [Diagnostic] = [],
        actions: [ToolchainHealthAction] = []
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.subject = subject
        self.status = status
        self.detail = detail
        self.source = source
        self.resolvedPath = resolvedPath
        self.diagnostics = diagnostics
        self.actions = actions
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case category
        case title
        case subject
        case status
        case detail
        case source
        case resolvedPath
        case diagnostics
        case actions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        category = try container.decode(ToolchainHealthCategory.self, forKey: .category)
        title = try container.decode(String.self, forKey: .title)
        subject = try container.decode(String.self, forKey: .subject)
        status = try container.decode(ToolchainHealthStatus.self, forKey: .status)
        detail = try container.decode(String.self, forKey: .detail)
        source = try container.decodeIfPresent(SourceSpan.self, forKey: .source)
        resolvedPath = try container.decodeIfPresent(String.self, forKey: .resolvedPath)
        diagnostics = try container.decodeIfPresent([Diagnostic].self, forKey: .diagnostics) ?? []
        actions = try container.decodeIfPresent([ToolchainHealthAction].self, forKey: .actions) ?? []
    }
}

public struct ToolchainHealthCounts: Codable, Equatable {
    public let ready: Int
    public let warnings: Int
    public let errors: Int
    public let notApplicable: Int

    public init(rows: [ToolchainHealthMatrixRow]) {
        ready = rows.filter { $0.status == .ready }.count
        warnings = rows.filter { $0.status == .warning }.count
        errors = rows.filter { $0.status == .error }.count
        notApplicable = rows.filter { $0.status == .notApplicable }.count
    }
}

public struct ToolchainHealthSummary: Codable, Equatable {
    public let all: ToolchainHealthCounts
    public let externalTools: ToolchainHealthCounts
    public let romHeaders: ToolchainHealthCounts
    public let graphicsConversion: ToolchainHealthCounts
    public let generatedArtifacts: ToolchainHealthCounts

    public init(rows: [ToolchainHealthMatrixRow]) {
        all = ToolchainHealthCounts(rows: rows)
        externalTools = ToolchainHealthCounts(rows: rows.filter { $0.category == .externalTools })
        romHeaders = ToolchainHealthCounts(rows: rows.filter { $0.category == .romHeaders })
        graphicsConversion = ToolchainHealthCounts(rows: rows.filter { $0.category == .graphicsConversion })
        generatedArtifacts = ToolchainHealthCounts(rows: rows.filter { $0.category == .generatedArtifacts })
    }
}

public struct ToolchainHealthMatrixReport: Codable, Equatable {
    public let adapterID: String
    public let adapterName: String
    public let profile: GameProfile
    public let rootPath: String
    public let generatedAt: Date
    public let isPreviewOnly: Bool
    public let rows: [ToolchainHealthMatrixRow]
    public let diagnostics: [Diagnostic]
    public let summary: ToolchainHealthSummary
    public let isHealthy: Bool

    public init(
        adapterID: String,
        adapterName: String,
        profile: GameProfile,
        rootPath: String,
        generatedAt: Date = Date(),
        isPreviewOnly: Bool = true,
        rows: [ToolchainHealthMatrixRow],
        diagnostics: [Diagnostic] = []
    ) {
        self.adapterID = adapterID
        self.adapterName = adapterName
        self.profile = profile
        self.rootPath = rootPath
        self.generatedAt = generatedAt
        self.isPreviewOnly = isPreviewOnly
        self.rows = rows
        self.diagnostics = diagnostics
        self.summary = ToolchainHealthSummary(rows: rows)
        isHealthy = !rows.contains { $0.status == .error }
    }
}

public enum ToolchainHealthMatrixBuilder {
    public static func build(
        index: ProjectIndex,
        fileManager: FileManager = .default,
        toolResolver: ToolAvailabilityResolver = ToolAvailabilityResolverFactory.pathEnvironment()
    ) -> ToolchainHealthMatrixReport {
        let buildReport = BuildValidationReportBuilder.build(
            index: index,
            fileManager: fileManager,
            toolResolver: toolResolver
        )
        let playtestReport = PlaytestHandoffReportBuilder.build(
            index: index,
            fileManager: fileManager,
            toolResolver: toolResolver
        )
        let graphicsReport = shouldInspectGraphics(index)
            ? GraphicsDiagnosticsReportBuilder.build(index: index, fileManager: fileManager)
            : nil
        return build(
            index: index,
            fileManager: fileManager,
            toolResolver: toolResolver,
            buildReport: buildReport,
            playtestReport: playtestReport,
            graphicsReport: graphicsReport
        )
    }

    public static func build(
        index: ProjectIndex,
        fileManager: FileManager = .default,
        toolResolver: ToolAvailabilityResolver = ToolAvailabilityResolverFactory.pathEnvironment(),
        buildReport: BuildValidationReport,
        playtestReport: PlaytestHandoffReport,
        graphicsReport: GraphicsDiagnosticsReport? = nil
    ) -> ToolchainHealthMatrixReport {
        let root = URL(fileURLWithPath: index.root.path).standardizedFileURL
        var rows: [ToolchainHealthMatrixRow] = []
        rows.append(contentsOf: externalToolRows(index: index, root: root, buildReport: buildReport, playtestReport: playtestReport, fileManager: fileManager, toolResolver: toolResolver))
        rows.append(contentsOf: romHeaderRows(index: index, root: root, buildReport: buildReport, fileManager: fileManager))
        rows.append(contentsOf: graphicsConversionRows(index: index, root: root, graphicsReport: graphicsReport, fileManager: fileManager))
        rows.append(contentsOf: generatedArtifactRows(index: index, buildReport: buildReport, graphicsReport: graphicsReport))

        let diagnostics = [
            healthDiagnostic(
                severity: .info,
                code: "TOOLCHAIN_HEALTH_PREVIEW_ONLY",
                message: "Toolchain health is inspected without invoking build tools, graphics converters, patch writers, or emulators."
            )
        ] + rows.flatMap(\.diagnostics)

        return ToolchainHealthMatrixReport(
            adapterID: index.adapterID,
            adapterName: index.adapterName,
            profile: index.profile,
            rootPath: root.path,
            rows: rows,
            diagnostics: diagnostics
        )
    }

    private static func shouldInspectGraphics(_ index: ProjectIndex) -> Bool {
        index.editorModules.contains(.graphics)
            && isDecompProfile(index.profile)
    }

    private static func externalToolRows(
        index: ProjectIndex,
        root: URL,
        buildReport: BuildValidationReport,
        playtestReport: PlaytestHandoffReport,
        fileManager: FileManager,
        toolResolver: ToolAvailabilityResolver
    ) -> [ToolchainHealthMatrixRow] {
        var rows: [ToolchainHealthMatrixRow] = []
        var seen: Set<String> = []

        for target in buildReport.targets {
            guard let tool = target.commandTool else { continue }
            if let row = toolRow(tool, requiredBy: target.target.name, sourcePath: "Makefile", seen: &seen) {
                rows.append(row)
            }
        }

        let makefile = makefileInspection(root: root, fileManager: fileManager)
        for toolName in externalCompilerTools(from: makefile) {
            if let row = toolRow(toolResolver(toolName), requiredBy: "GBA build toolchain", sourcePath: "Makefile", seen: &seen) {
                rows.append(row)
            }
        }

        for localTool in localToolRequirements(index: index, makefile: makefile) {
            if let row = localToolRow(localTool, root: root, fileManager: fileManager, seen: &seen) {
                rows.append(row)
            }
        }

        if let row = toolRow(
                playtestReport.emulator,
                requiredBy: "Playtest handoff",
                sourcePath: root.path,
                missingSeverity: .warning,
                seen: &seen
        ) {
            rows.append(row)
        }

        if rows.isEmpty {
            rows.append(
                ToolchainHealthMatrixRow(
                    id: "external:none",
                    category: .externalTools,
                    title: "External tools",
                    subject: index.adapterName,
                    status: .notApplicable,
                    detail: "No external build, conversion, or playtest tools are declared for this adapter.",
                    source: SourceSpan(relativePath: root.path, startLine: 1)
                )
            )
        }

        return rows
    }

    private static func toolRow(
        _ tool: ToolAvailability,
        requiredBy: String,
        sourcePath: String,
        missingSeverity: DiagnosticSeverity = .error,
        seen: inout Set<String>
    ) -> ToolchainHealthMatrixRow? {
        let key = "tool:\(tool.name)"
        guard seen.insert(key).inserted else {
            return nil
        }

        let status: ToolchainHealthStatus = tool.isAvailable ? .ready : (missingSeverity == .error ? .error : .warning)
        let diagnostic = tool.isAvailable ? nil : healthDiagnostic(
            severity: missingSeverity,
            code: "TOOLCHAIN_TOOL_MISSING",
            message: "\(tool.name) is required by \(requiredBy), but no executable was found.",
            span: SourceSpan(relativePath: sourcePath, startLine: 1)
        )
        return ToolchainHealthMatrixRow(
            id: "external:\(tool.name)",
            category: .externalTools,
            title: tool.name,
            subject: requiredBy,
            status: status,
            detail: tool.resolvedPath ?? "No executable discovered for \(requiredBy).",
            source: SourceSpan(relativePath: sourcePath, startLine: 1),
            resolvedPath: tool.resolvedPath,
            diagnostics: diagnostic.map { [$0] } ?? [],
            actions: toolActions(tool: tool, requiredBy: requiredBy, sourcePath: sourcePath)
        )
    }

    private static func toolActions(
        tool: ToolAvailability,
        requiredBy: String,
        sourcePath: String
    ) -> [ToolchainHealthAction] {
        if let resolvedPath = tool.resolvedPath {
            return [
                copyPathAction(
                    id: "copy-tool-path-\(tool.name)",
                    title: "Copy tool path",
                    path: resolvedPath,
                    detail: "Copies the discovered \(tool.name) path for manual inspection."
                )
            ]
        }

        var actions = [
            rerunGuidanceAction(
                id: "rerun-after-\(tool.name)-setup",
                title: "Set up \(tool.name)",
                detail: "Install or expose \(tool.name) on PATH outside PokemonHackStudio, then rerun health for \(requiredBy)."
            )
        ]

        if sourcePath == "Makefile" {
            actions.append(
                copyPathAction(
                    id: "copy-tool-source-\(tool.name)",
                    title: "Copy declaring file",
                    path: sourcePath,
                    detail: "Copies the file that declared the \(tool.name) requirement."
                )
            )
        }

        return actions
    }

    private static func localToolRow(
        _ tool: LocalToolRequirement,
        root: URL,
        fileManager: FileManager,
        seen: inout Set<String>
    ) -> ToolchainHealthMatrixRow? {
        let key = "local:\(tool.path)"
        guard seen.insert(key).inserted else {
            return nil
        }

        let url = root.appendingPathComponent(tool.path)
        let exists = fileManager.fileExists(atPath: url.path)
        let executable = exists && fileManager.isExecutableFile(atPath: url.path)
        let status: ToolchainHealthStatus = executable ? .ready : .warning
        let detail: String
        if executable {
            detail = "Project-local executable is present at \(tool.path)."
        } else if exists {
            detail = "Project-local tool source or file exists at \(tool.path), but it is not executable yet."
        } else {
            detail = "Project-local tool is expected at \(tool.path), but it is not present."
        }

        let diagnostic = executable ? nil : healthDiagnostic(
            severity: .warning,
            code: "TOOLCHAIN_LOCAL_TOOL_MISSING",
            message: "\(tool.name) is expected for \(tool.requiredBy), but \(tool.path) is not executable.",
            span: SourceSpan(relativePath: tool.path, startLine: 1)
        )

        return ToolchainHealthMatrixRow(
            id: "external:local:\(tool.path)",
            category: .externalTools,
            title: tool.name,
            subject: tool.requiredBy,
            status: status,
            detail: detail,
            source: SourceSpan(relativePath: tool.path, startLine: 1),
            resolvedPath: exists ? url.path : nil,
            diagnostics: diagnostic.map { [$0] } ?? [],
            actions: localToolActions(tool: tool, exists: exists, executable: executable)
        )
    }

    private static func localToolActions(
        tool: LocalToolRequirement,
        exists: Bool,
        executable: Bool
    ) -> [ToolchainHealthAction] {
        if executable {
            return [
                copyPathAction(
                    id: "copy-local-tool-path-\(tool.name)",
                    title: "Copy tool path",
                    path: tool.path,
                    detail: "Copies the project-local \(tool.name) path for manual inspection."
                )
            ]
        }

        let detail = exists
            ? "\(tool.path) exists but is not executable; fix permissions or rebuild the local tool outside PokemonHackStudio, then rerun health."
            : "\(tool.path) is missing; build or restore the local tool outside PokemonHackStudio, then rerun health."
        var actions = [
            rerunGuidanceAction(
                id: "rerun-local-tool-\(tool.name)",
                title: "Prepare \(tool.name)",
                detail: detail
            )
        ]

        if !exists {
            actions.append(
                copyCommandAction(
                    id: "copy-tools-build-command-\(tool.name)",
                    title: "Copy tool build command",
                    command: "make tools",
                    detail: "Copies the common decomp tool-build command for manual terminal use; PokemonHackStudio will not run it."
                )
            )
        }

        return actions
    }

    private static func romHeaderRows(
        index: ProjectIndex,
        root: URL,
        buildReport: BuildValidationReport,
        fileManager: FileManager
    ) -> [ToolchainHealthMatrixRow] {
        guard isDecompProfile(index.profile) else {
            return [
                ToolchainHealthMatrixRow(
                    id: "rom-header:not-applicable",
                    category: .romHeaders,
                    title: "ROM header",
                    subject: index.adapterName,
                    status: .notApplicable,
                    detail: "ROM-header validation is only modeled for supported GBA decomp projects.",
                    source: SourceSpan(relativePath: root.path, startLine: 1)
                )
            ]
        }

        let config = headerConfigurationInspection(index: index, root: root, fileManager: fileManager)
        var rows = [
            ToolchainHealthMatrixRow(
                id: "rom-header:configuration",
                category: .romHeaders,
                title: "Header configuration",
                subject: index.profile.rawValue,
                status: config.status,
                detail: config.detail,
                source: SourceSpan(relativePath: config.sourcePath, startLine: 1),
                diagnostics: config.diagnostics
            )
        ]

        let targets = buildReport.targets.filter { $0.target.outputPath?.lowercased().hasSuffix(".gba") == true }
        if targets.isEmpty {
            rows.append(
                ToolchainHealthMatrixRow(
                    id: "rom-header:no-rom-targets",
                    category: .romHeaders,
                    title: "Built ROM header",
                    subject: "No .gba outputs",
                    status: .notApplicable,
                    detail: "No build target declares a .gba output for header inspection.",
                    source: SourceSpan(relativePath: "Makefile", startLine: 1)
                )
            )
            return rows
        }

        rows.append(contentsOf: targets.map { target in
            romHeaderRow(target: target, index: index, root: root, fileManager: fileManager)
        })
        return rows
    }

    private static func romHeaderRow(
        target: BuildTargetValidation,
        index: ProjectIndex,
        root: URL,
        fileManager: FileManager
    ) -> ToolchainHealthMatrixRow {
        guard let outputPath = target.target.outputPath else {
            return ToolchainHealthMatrixRow(
                id: "rom-header:\(target.target.id):missing-output-path",
                category: .romHeaders,
                title: "Built ROM header",
                subject: target.target.name,
                status: .notApplicable,
                detail: "This target does not declare a ROM output path.",
                source: SourceSpan(relativePath: "Makefile", startLine: 1)
            )
        }

        let expectation = headerExpectation(for: target.target, profile: index.profile)
        let url = root.appendingPathComponent(outputPath)
        guard fileManager.fileExists(atPath: url.path) else {
            let commandActions = target.target.command.isEmpty ? [] : [
                copyCommandAction(
                    id: "copy-build-command-\(target.target.id)",
                    title: "Copy build command",
                    command: target.target.command.joined(separator: " "),
                    detail: "Copies the declared project build command for manual terminal use; PokemonHackStudio will not run it."
                )
            ]
            return ToolchainHealthMatrixRow(
                id: "rom-header:\(target.target.id)",
                category: .romHeaders,
                title: "Built ROM header",
                subject: target.target.name,
                status: .warning,
                detail: "ROM output is missing, so header bytes were not inspected. Expected \(expectation.summary).",
                source: SourceSpan(relativePath: outputPath, startLine: 1),
                diagnostics: [
                    healthDiagnostic(
                        severity: .warning,
                        code: "ROM_HEADER_OUTPUT_MISSING",
                        message: "Cannot inspect ROM header because \(outputPath) does not exist.",
                        span: SourceSpan(relativePath: outputPath, startLine: 1)
                    )
                ],
                actions: [
                    rerunGuidanceAction(
                        id: "rerun-build-\(target.target.id)",
                        title: "Refresh build output",
                        detail: "Build the ROM outside PokemonHackStudio, then rerun this health check to inspect \(outputPath)."
                    )
                ] + commandActions
            )
        }

        guard let data = try? Data(contentsOf: url), let header = GBAHeader(data: data) else {
            return ToolchainHealthMatrixRow(
                id: "rom-header:\(target.target.id)",
                category: .romHeaders,
                title: "Built ROM header",
                subject: target.target.name,
                status: .warning,
                detail: "ROM output exists, but the GBA header could not be read.",
                source: SourceSpan(relativePath: outputPath, startLine: 1),
                diagnostics: [
                    healthDiagnostic(
                        severity: .warning,
                        code: "ROM_HEADER_UNREADABLE",
                        message: "Could not read GBA header bytes from \(outputPath).",
                        span: SourceSpan(relativePath: outputPath, startLine: 1)
                    )
                ],
                actions: [
                    copyPathAction(
                        id: "copy-unreadable-rom-path-\(target.target.id)",
                        title: "Copy ROM path",
                        path: outputPath,
                        detail: "Copies the unreadable ROM output path for manual inspection."
                    ),
                    rerunGuidanceAction(
                        id: "rerun-unreadable-rom-\(target.target.id)",
                        title: "Rebuild and rerun",
                        detail: "Rebuild the ROM outside PokemonHackStudio, then rerun health to inspect the header bytes."
                    )
                ]
            )
        }

        let mismatches = expectation.mismatches(in: header)
        let status: ToolchainHealthStatus = mismatches.isEmpty ? .ready : .warning
        let diagnostic = mismatches.isEmpty ? nil : healthDiagnostic(
            severity: .warning,
            code: "ROM_HEADER_MISMATCH",
            message: "\(outputPath) header differs from expected \(expectation.summary): \(mismatches.joined(separator: "; ")).",
            span: SourceSpan(relativePath: outputPath, startLine: 1)
        )

        return ToolchainHealthMatrixRow(
            id: "rom-header:\(target.target.id)",
            category: .romHeaders,
            title: "Built ROM header",
            subject: target.target.name,
            status: status,
            detail: "Found title \(header.title), code \(header.gameCode), maker \(header.makerCode), revision \(header.revision). Expected \(expectation.summary).",
            source: SourceSpan(relativePath: outputPath, startLine: 1),
            diagnostics: diagnostic.map { [$0] } ?? [],
            actions: mismatches.isEmpty ? [
                copyPathAction(
                    id: "copy-rom-path-\(target.target.id)",
                    title: "Copy ROM path",
                    path: outputPath,
                    detail: "Copies the inspected ROM output path for manual review."
                )
            ] : [
                rerunGuidanceAction(
                    id: "rerun-header-\(target.target.id)",
                    title: "Rebuild and recheck header",
                    detail: "Review Makefile/header constants, rebuild outside PokemonHackStudio, then rerun health to confirm \(expectation.summary)."
                )
            ]
        )
    }

    private static func graphicsConversionRows(
        index: ProjectIndex,
        root: URL,
        graphicsReport: GraphicsDiagnosticsReport?,
        fileManager: FileManager
    ) -> [ToolchainHealthMatrixRow] {
        guard isDecompProfile(index.profile) else {
            return [
                ToolchainHealthMatrixRow(
                    id: "graphics-conversion:not-applicable",
                    category: .graphicsConversion,
                    title: "Graphics conversion",
                    subject: index.adapterName,
                    status: .notApplicable,
                    detail: "Graphics conversion prerequisites are only modeled for supported GBA decomp projects.",
                    source: SourceSpan(relativePath: root.path, startLine: 1)
                )
            ]
        }

        guard let graphicsReport else {
            return [
                ToolchainHealthMatrixRow(
                    id: "graphics-conversion:no-report",
                    category: .graphicsConversion,
                    title: "Graphics diagnostics",
                    subject: index.adapterName,
                    status: .notApplicable,
                    detail: "No graphics diagnostics report was built for this adapter.",
                    source: SourceSpan(relativePath: root.path, startLine: 1)
                )
            ]
        }

        let inventory = graphicsReport.inventory
        let sourceCount = inventory.tileImageCount + inventory.paletteFileCount
        let gbagfx = localToolRequirement(name: "gbagfx", path: "tools/gbagfx/gbagfx", requiredBy: "graphics conversion")
        let gbagfxURL = root.appendingPathComponent(gbagfx.path)
        let hasGBAGFX = fileManager.fileExists(atPath: gbagfxURL.path) && fileManager.isExecutableFile(atPath: gbagfxURL.path)
        let conversionStatus: ToolchainHealthStatus = sourceCount == 0 ? .notApplicable : (hasGBAGFX ? .ready : .warning)
        let conversionDiagnostic = sourceCount > 0 && !hasGBAGFX ? healthDiagnostic(
            severity: .warning,
            code: "GRAPHICS_CONVERSION_TOOL_MISSING",
            message: "\(sourceCount) graphics source artifact(s) were found, but tools/gbagfx/gbagfx is not executable.",
            span: SourceSpan(relativePath: gbagfx.path, startLine: 1)
        ) : nil

        let missingGenerated = graphicsReport.tilesets
            .flatMap(graphicsArtifacts)
            .filter { $0.freshness == .generatedMissing }
            .count
        let staleGenerated = graphicsReport.tilesets
            .flatMap(graphicsArtifacts)
            .filter { $0.freshness == .generatedStale }
            .count
        let paletteWarnings = graphicsReport.diagnostics.filter {
            $0.code == "GRAPHICS_PALETTE_COLOR_COUNT_UNEXPECTED"
                || $0.code == "GRAPHICS_IMAGE_TOO_MANY_COLORS_FOR_4BPP"
                || $0.code == "GRAPHICS_15BIT_PRECISION_LOSS"
        }

        return [
            ToolchainHealthMatrixRow(
                id: "graphics-conversion:gbagfx",
                category: .graphicsConversion,
                title: "gbagfx conversion",
                subject: "\(sourceCount) PNG/palette source artifact(s)",
                status: conversionStatus,
                detail: sourceCount == 0
                    ? "No PNG or palette source artifacts were found under \(inventory.rootRelativePath)."
                    : "Conversion inputs are previewed only; \(hasGBAGFX ? "gbagfx is executable" : "gbagfx is not executable") at \(gbagfx.path).",
                source: SourceSpan(relativePath: gbagfx.path, startLine: 1),
                resolvedPath: fileManager.fileExists(atPath: gbagfxURL.path) ? gbagfxURL.path : nil,
                diagnostics: conversionDiagnostic.map { [$0] } ?? [],
                actions: hasGBAGFX
                    ? [
                        copyPathAction(
                            id: "copy-gbagfx-path",
                            title: "Copy gbagfx path",
                            path: gbagfx.path,
                            detail: "Copies the detected project-local converter path for manual inspection."
                        )
                    ]
                    : [
                        rerunGuidanceAction(
                            id: "rerun-gbagfx-setup",
                            title: "Set up gbagfx then rerun",
                            detail: "Build or install the project-local gbagfx tool outside PokemonHackStudio, then rerun health."
                        )
                    ]
            ),
            ToolchainHealthMatrixRow(
                id: "graphics-conversion:generated-freshness",
                category: .graphicsConversion,
                title: "Conversion freshness",
                subject: "\(graphicsReport.tilesets.count) tileset(s)",
                status: missingGenerated == 0 && staleGenerated == 0 ? .ready : .warning,
                detail: "\(missingGenerated) generated conversion artifact(s) missing; \(staleGenerated) stale.",
                source: SourceSpan(relativePath: inventory.rootRelativePath, startLine: 1),
                diagnostics: graphicsReport.diagnostics.filter {
                    $0.code == "GRAPHICS_GENERATED_ARTIFACT_MISSING"
                        || $0.code == "GRAPHICS_GENERATED_ARTIFACT_STALE"
                },
                actions: missingGenerated == 0 && staleGenerated == 0 ? [] : [
                    rerunGuidanceAction(
                        id: "rerun-graphics-conversion-check",
                        title: "Refresh generated graphics",
                        detail: "Run the project's graphics conversion/build workflow outside PokemonHackStudio, then rerun diagnostics."
                    )
                ]
            ),
            ToolchainHealthMatrixRow(
                id: "graphics-conversion:palette-prerequisites",
                category: .graphicsConversion,
                title: "Palette and 4bpp prerequisites",
                subject: "\(inventory.paletteFileCount) palette file(s)",
                status: paletteWarnings.isEmpty ? .ready : .warning,
                detail: paletteWarnings.isEmpty
                    ? "Palette and indexed-image prerequisites are within the current read-only checks."
                    : "\(paletteWarnings.count) palette or 4bpp prerequisite warning(s) need review.",
                source: SourceSpan(relativePath: inventory.rootRelativePath, startLine: 1),
                diagnostics: paletteWarnings,
                actions: paletteWarnings.isEmpty ? [] : [
                    rerunGuidanceAction(
                        id: "review-palette-prerequisites",
                        title: "Review source graphics",
                        detail: "Fix palette or indexed-image prerequisites in the source project, then rerun graphics diagnostics."
                    )
                ]
            )
        ]
    }

    private static func generatedArtifactRows(
        index: ProjectIndex,
        buildReport: BuildValidationReport,
        graphicsReport: GraphicsDiagnosticsReport?
    ) -> [ToolchainHealthMatrixRow] {
        let generatedGroups = buildReport.generatedArtifacts
        let generatedPresent = generatedGroups.filter(\.exists).count
        let generatedMissing = generatedGroups.count - generatedPresent
        var rows = [
            ToolchainHealthMatrixRow(
                id: "generated:adapter-outputs",
                category: .generatedArtifacts,
                title: "Adapter generated outputs",
                subject: index.adapterName,
                status: generatedMissing == 0 ? .ready : .warning,
                detail: "\(generatedPresent)/\(generatedGroups.count) generated-output pattern(s) currently match; generated files remain cache/artifact surfaces.",
                source: SourceSpan(relativePath: index.root.path, startLine: 1),
                diagnostics: generatedGroups.filter { !$0.exists }.map {
                    healthDiagnostic(
                        severity: .warning,
                        code: "GENERATED_ARTIFACT_PATTERN_MISSING",
                        message: "No generated files matched \($0.relativePath).",
                        span: SourceSpan(relativePath: $0.relativePath, startLine: 1)
                    )
                },
                actions: generatedMissing == 0 ? [] : [
                    rerunGuidanceAction(
                        id: "rerun-generated-output-check",
                        title: "Refresh generated outputs",
                        detail: "Regenerate project outputs outside PokemonHackStudio, then rerun health to refresh these pattern checks."
                    )
                ]
            )
        ]

        if let graphicsReport {
            let artifacts = graphicsReport.tilesets.flatMap(graphicsArtifacts)
            let tracked = artifacts.filter { $0.generatedRelativePath != nil }
            let fresh = tracked.filter { $0.freshness == .generatedFresh }.count
            let missing = tracked.filter { $0.freshness == .generatedMissing }.count
            let stale = tracked.filter { $0.freshness == .generatedStale }.count
            rows.append(
                ToolchainHealthMatrixRow(
                    id: "generated:graphics-conversions",
                    category: .generatedArtifacts,
                    title: "Graphics generated outputs",
                    subject: "\(tracked.count) tracked conversion artifact(s)",
                    status: missing == 0 && stale == 0 ? .ready : .warning,
                    detail: "\(fresh) fresh, \(missing) missing, \(stale) stale generated graphics artifact(s).",
                    source: SourceSpan(relativePath: graphicsReport.inventory.rootRelativePath, startLine: 1),
                    diagnostics: graphicsReport.diagnostics.filter {
                        $0.code == "GRAPHICS_GENERATED_ARTIFACT_MISSING"
                            || $0.code == "GRAPHICS_GENERATED_ARTIFACT_STALE"
                    },
                    actions: missing == 0 && stale == 0 ? [] : [
                        rerunGuidanceAction(
                            id: "rerun-generated-graphics-check",
                            title: "Refresh graphics outputs",
                            detail: "Regenerate graphics outputs outside PokemonHackStudio, then rerun health to confirm freshness."
                        )
                    ]
                )
            )
        }

        return rows
    }

    private static func graphicsArtifacts(_ tileset: GraphicsTilesetDiagnostics) -> [GraphicsArtifactStatus] {
        [tileset.tileImage, tileset.metatiles, tileset.metatileAttributes].compactMap { $0 } + tileset.palettes
    }

    private static func makefileInspection(root: URL, fileManager: FileManager) -> MakefileInspection {
        let makefile = root.appendingPathComponent("Makefile")
        let config = root.appendingPathComponent("config.mk")
        return MakefileInspection(
            makefile: (try? String(contentsOf: makefile, encoding: .utf8)) ?? "",
            config: (try? String(contentsOf: config, encoding: .utf8)) ?? ""
        )
    }

    private static func externalCompilerTools(from makefile: MakefileInspection) -> [String] {
        guard makefile.combined.contains("arm-none-eabi-") else { return [] }
        return [
            "arm-none-eabi-as",
            "arm-none-eabi-ld",
            "arm-none-eabi-objcopy",
            "arm-none-eabi-objdump",
            "arm-none-eabi-cpp",
            "arm-none-eabi-gcc",
            "perl"
        ]
    }

    private static func localToolRequirements(index: ProjectIndex, makefile: MakefileInspection) -> [LocalToolRequirement] {
        guard isDecompProfile(index.profile) else { return [] }
        var tools: [LocalToolRequirement] = [
            localToolRequirement(name: "agbcc", path: "tools/agbcc/bin/agbcc", requiredBy: "legacy C compilation"),
            localToolRequirement(name: "old_agbcc", path: "tools/agbcc/bin/old_agbcc", requiredBy: "legacy library objects"),
            localToolRequirement(name: "agbcc_arm", path: "tools/agbcc/bin/agbcc_arm", requiredBy: "ARM-mode library objects"),
            localToolRequirement(name: "gbagfx", path: "tools/gbagfx/gbagfx", requiredBy: "graphics conversion"),
            localToolRequirement(name: "gbafix", path: "tools/gbafix/gbafix", requiredBy: "ROM header finalization"),
            localToolRequirement(name: "scaninc", path: "tools/scaninc/scaninc", requiredBy: "dependency scanning"),
            localToolRequirement(name: "preproc", path: "tools/preproc/preproc", requiredBy: "text/script preprocessing"),
            localToolRequirement(name: "mapjson", path: "tools/mapjson/mapjson", requiredBy: "map generated output refresh"),
            localToolRequirement(name: "jsonproc", path: "tools/jsonproc/jsonproc", requiredBy: "JSON generated output refresh"),
            localToolRequirement(name: "rsfont", path: "tools/rsfont/rsfont", requiredBy: "font graphics conversion"),
            localToolRequirement(name: "mid2agb", path: "tools/mid2agb/mid2agb", requiredBy: "music conversion")
        ]

        if makefile.combined.contains("WAV2AGB") {
            tools.append(localToolRequirement(name: "wav2agb", path: "tools/wav2agb/wav2agb", requiredBy: "sound conversion"))
        }
        if makefile.combined.contains("RAMSCRGEN") || index.profile != .pokeemeraldExpansion {
            tools.append(localToolRequirement(name: "ramscrgen", path: "tools/ramscrgen/ramscrgen", requiredBy: "RAM script generation"))
        }

        return tools
    }

    private static func localToolRequirement(name: String, path: String, requiredBy: String) -> LocalToolRequirement {
        LocalToolRequirement(name: name, path: path, requiredBy: requiredBy)
    }

    private static func headerConfigurationInspection(
        index: ProjectIndex,
        root: URL,
        fileManager: FileManager
    ) -> HeaderConfigurationInspection {
        let makefile = makefileInspection(root: root, fileManager: fileManager)
        let sourcePath = makefile.config.isEmpty ? "Makefile" : "config.mk"
        let text = makefile.combined
        let expectation = profileHeaderExpectation(index.profile)
        let missingTokens = expectation.requiredConfigTokens.filter { !text.contains($0) }
        let hasFinalizer = text.contains("-t\"$(TITLE)\"") && text.contains("-c$(GAME_CODE)") && text.contains("-m$(MAKER_CODE)")
        let hasHeaderSource = expectedHeaderSources(for: index.profile).contains {
            fileManager.fileExists(atPath: root.appendingPathComponent($0).path)
        }

        var diagnostics: [Diagnostic] = []
        if !missingTokens.isEmpty {
            diagnostics.append(
                healthDiagnostic(
                    severity: .warning,
                    code: "ROM_HEADER_CONFIG_TOKEN_MISSING",
                    message: "Header configuration is missing expected token(s): \(missingTokens.joined(separator: ", ")).",
                    span: SourceSpan(relativePath: sourcePath, startLine: 1)
                )
            )
        }
        if !hasFinalizer {
            diagnostics.append(
                healthDiagnostic(
                    severity: .warning,
                    code: "ROM_HEADER_FINALIZER_MISSING",
                    message: "Makefile does not expose the expected gbafix title/code/maker finalizer flags.",
                    span: SourceSpan(relativePath: "Makefile", startLine: 1)
                )
            )
        }
        if !hasHeaderSource {
            diagnostics.append(
                healthDiagnostic(
                    severity: .warning,
                    code: "ROM_HEADER_SOURCE_MISSING",
                    message: "No expected ROM header source file was found for \(index.profile.rawValue).",
                    span: SourceSpan(relativePath: "src", startLine: 1)
                )
            )
        }

        let detail = "Expected \(expectation.summary); \(hasFinalizer ? "gbafix finalizer flags found" : "gbafix finalizer flags missing"); \(hasHeaderSource ? "header source found" : "header source missing")."
        return HeaderConfigurationInspection(
            status: diagnostics.isEmpty ? .ready : .warning,
            detail: detail,
            sourcePath: sourcePath,
            diagnostics: diagnostics
        )
    }

    private static func headerExpectation(for target: BuildTarget, profile: GameProfile) -> ROMHeaderExpectation {
        let id = target.id.lowercased()
        let output = (target.outputPath ?? "").lowercased()

        switch profile {
        case .pokeemerald, .pokeemeraldExpansion:
            return ROMHeaderExpectation(title: "POKEMON EMER", gameCode: "BPEE", makerCode: "01", revision: 0)
        case .pokefirered:
            let isLeafGreen = id.contains("leafgreen") || output.contains("leafgreen")
            let revision: UInt8 = id.contains("switch") || output.contains("switch") ? 10 : (id.contains("rev1") || output.contains("rev1") ? 1 : 0)
            return ROMHeaderExpectation(
                title: isLeafGreen ? "POKEMON LEAF" : "POKEMON FIRE",
                gameCode: isLeafGreen ? "BPGE" : "BPRE",
                makerCode: "01",
                revision: revision
            )
        case .pokeruby:
            let isSapphire = id.contains("sapphire") || output.contains("sapphire")
            let isGerman = id.contains("-de") || output.contains("_de")
            let revision: UInt8 = id.contains("rev2") || output.contains("rev2") ? 2 : (id.contains("rev1") || output.contains("rev1") ? 1 : 0)
            let language = isGerman ? "D" : "E"
            return ROMHeaderExpectation(
                title: isSapphire ? "POKEMON SAPP" : "POKEMON RUBY",
                gameCode: (isSapphire ? "AXP" : "AXV") + language,
                makerCode: "01",
                revision: revision
            )
        default:
            return ROMHeaderExpectation(title: "", gameCode: "", makerCode: "", revision: 0)
        }
    }

    private static func profileHeaderExpectation(_ profile: GameProfile) -> ProfileHeaderExpectation {
        switch profile {
        case .pokeemerald, .pokeemeraldExpansion:
            return ProfileHeaderExpectation(
                summary: "POKEMON EMER / BPEE / maker 01 / revision 0",
                requiredConfigTokens: ["TITLE", "POKEMON EMER", "GAME_CODE", "BPEE", "MAKER_CODE", "01"]
            )
        case .pokefirered:
            return ProfileHeaderExpectation(
                summary: "FireRed BPRE and LeafGreen BPGE variants with maker 01",
                requiredConfigTokens: ["GAME_VERSION", "FIRERED", "LEAFGREEN", "POKEMON FIRE", "POKEMON LEAF", "MAKER_CODE", "01"]
            )
        case .pokeruby:
            return ProfileHeaderExpectation(
                summary: "Ruby AXVE/AXVD and Sapphire AXPE/AXPD variants with maker 01",
                requiredConfigTokens: ["GAME_VERSION", "RUBY", "SAPPHIRE", "POKEMON RUBY", "POKEMON SAPP", "MAKER_CODE", "01"]
            )
        default:
            return ProfileHeaderExpectation(summary: "No decomp header expectation", requiredConfigTokens: [])
        }
    }

    private static func expectedHeaderSources(for profile: GameProfile) -> [String] {
        switch profile {
        case .pokeemerald:
            ["src/rom_header_gf.c", "src/rom_header.s"]
        case .pokeemeraldExpansion:
            ["src/rom_header_rhh.c", "src/rom_header_gf.c", "src/rom_header.s"]
        case .pokefirered:
            ["src/rom_header_gf.c", "src/rom_header.s"]
        case .pokeruby:
            ["src/crt0.s", "src/rom_header.s"]
        default:
            []
        }
    }

    private static func isDecompProfile(_ profile: GameProfile) -> Bool {
        switch profile {
        case .pokeemerald, .pokefirered, .pokeruby, .pokeemeraldExpansion:
            true
        case .binaryROM, .ndsROM, .pokediamond, .pokeplatinum, .pokeheartgold, .pmdSky,
             .pokemonColosseum, .pokemonXD, .pokemonBox, .pokemonChannel, .gameCubeMedia, .unknown:
            false
        }
    }

    private static func copyCommandAction(
        id: String,
        title: String,
        command: String,
        detail: String
    ) -> ToolchainHealthAction {
        ToolchainHealthAction(
            id: id,
            kind: .copyCommand,
            title: title,
            detail: detail,
            command: command
        )
    }

    private static func copyPathAction(
        id: String,
        title: String,
        path: String,
        detail: String
    ) -> ToolchainHealthAction {
        ToolchainHealthAction(
            id: id,
            kind: .copyPath,
            title: title,
            detail: detail,
            payload: path
        )
    }

    private static func rerunGuidanceAction(
        id: String,
        title: String,
        detail: String
    ) -> ToolchainHealthAction {
        ToolchainHealthAction(
            id: id,
            kind: .rerunGuidance,
            title: title,
            detail: detail
        )
    }
}

private struct LocalToolRequirement {
    let name: String
    let path: String
    let requiredBy: String
}

private struct MakefileInspection {
    let makefile: String
    let config: String

    var combined: String {
        makefile + "\n" + config
    }
}

private struct HeaderConfigurationInspection {
    let status: ToolchainHealthStatus
    let detail: String
    let sourcePath: String
    let diagnostics: [Diagnostic]
}

private struct ProfileHeaderExpectation {
    let summary: String
    let requiredConfigTokens: [String]
}

private struct ROMHeaderExpectation {
    let title: String
    let gameCode: String
    let makerCode: String
    let revision: UInt8

    var summary: String {
        "\(title) / \(gameCode) / maker \(makerCode) / revision \(revision)"
    }

    func mismatches(in header: GBAHeader) -> [String] {
        var mismatches: [String] = []
        if !title.isEmpty, header.title != title {
            mismatches.append("title \(header.title)")
        }
        if !gameCode.isEmpty, header.gameCode != gameCode {
            mismatches.append("game code \(header.gameCode)")
        }
        if !makerCode.isEmpty, header.makerCode != makerCode {
            mismatches.append("maker \(header.makerCode)")
        }
        if header.revision != revision {
            mismatches.append("revision \(header.revision)")
        }
        return mismatches
    }
}

private struct GBAHeader {
    let title: String
    let gameCode: String
    let makerCode: String
    let revision: UInt8

    init?(data: Data) {
        guard data.count > 0xBC else { return nil }
        title = Self.ascii(data[0xA0..<0xAC])
        gameCode = Self.ascii(data[0xAC..<0xB0])
        makerCode = Self.ascii(data[0xB0..<0xB2])
        revision = data[0xBC]
    }

    private static func ascii(_ slice: Data.SubSequence) -> String {
        let bytes = slice.prefix { $0 != 0 }
        return String(decoding: bytes, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private func healthDiagnostic(
    severity: DiagnosticSeverity,
    code: String,
    message: String,
    span: SourceSpan? = nil
) -> Diagnostic {
    Diagnostic(
        id: code + ":" + (span?.relativePath ?? "global") + ":" + message,
        severity: severity,
        code: code,
        message: message,
        span: span
    )
}
