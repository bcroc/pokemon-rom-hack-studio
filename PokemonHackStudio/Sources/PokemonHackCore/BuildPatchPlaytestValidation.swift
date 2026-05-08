import Foundation

public struct ToolAvailability: Codable, Equatable {
    public let name: String
    public let isAvailable: Bool
    public let resolvedPath: String?

    public init(name: String, isAvailable: Bool, resolvedPath: String? = nil) {
        self.name = name
        self.isAvailable = isAvailable
        self.resolvedPath = resolvedPath
    }
}

public typealias ToolAvailabilityResolver = (String) -> ToolAvailability

public enum ToolAvailabilityResolverFactory {
    public static func pathEnvironment(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) -> ToolAvailabilityResolver {
        { tool in
            if tool.lowercased() == "mgba" {
                if let appPath = firstExistingPath(
                    [
                        "/Applications/mGBA.app",
                        FileManager.default.homeDirectoryForCurrentUser
                            .appendingPathComponent("Applications/mGBA.app")
                            .path
                    ],
                    fileManager: fileManager
                ) {
                    return ToolAvailability(name: tool, isAvailable: true, resolvedPath: appPath)
                }
            }

            guard let path = environment["PATH"] else {
                return ToolAvailability(name: tool, isAvailable: false)
            }

            for directory in path.split(separator: ":").map(String.init) {
                let candidate = URL(fileURLWithPath: directory).appendingPathComponent(tool).path
                if fileManager.fileExists(atPath: candidate), fileManager.isExecutableFile(atPath: candidate) {
                    return ToolAvailability(name: tool, isAvailable: true, resolvedPath: candidate)
                }
            }

            return ToolAvailability(name: tool, isAvailable: false)
        }
    }

    private static func firstExistingPath(_ paths: [String], fileManager: FileManager) -> String? {
        paths.first { fileManager.fileExists(atPath: $0) }
    }
}

public struct SHA1Expectation: Codable, Equatable, Identifiable {
    public var id: String { relativePath }

    public let relativePath: String
    public let expectedSHA1: String?
    public let isParseable: Bool

    public init(relativePath: String, expectedSHA1: String?, isParseable: Bool) {
        self.relativePath = relativePath
        self.expectedSHA1 = expectedSHA1
        self.isParseable = isParseable
    }
}

public enum BuildOutputChecksumStatus: String, Codable, Equatable {
    case notApplicable
    case outputMissing
    case expectationMissing
    case matched
    case mismatched
    case unreadable
}

public enum BuildOutputFreshnessStatus: String, Codable, Equatable {
    case notApplicable
    case outputMissing
    case noSourceModifiedTimes
    case fresh
    case stale
    case unknown
}

public struct BuildOutputValidation: Codable, Equatable {
    public let relativePath: String
    public let absolutePath: String
    public let exists: Bool
    public let sizeBytes: UInt64?
    public let modifiedAt: Date?
    public let sha1: String?
    public let expectation: SHA1Expectation?
    public let checksumStatus: BuildOutputChecksumStatus
    public let freshnessStatus: BuildOutputFreshnessStatus
    public let newestSourcePath: String?
    public let newestSourceModifiedAt: Date?

    public init(
        relativePath: String,
        absolutePath: String,
        exists: Bool,
        sizeBytes: UInt64? = nil,
        modifiedAt: Date? = nil,
        sha1: String? = nil,
        expectation: SHA1Expectation? = nil,
        checksumStatus: BuildOutputChecksumStatus,
        freshnessStatus: BuildOutputFreshnessStatus,
        newestSourcePath: String? = nil,
        newestSourceModifiedAt: Date? = nil
    ) {
        self.relativePath = relativePath
        self.absolutePath = absolutePath
        self.exists = exists
        self.sizeBytes = sizeBytes
        self.modifiedAt = modifiedAt
        self.sha1 = sha1
        self.expectation = expectation
        self.checksumStatus = checksumStatus
        self.freshnessStatus = freshnessStatus
        self.newestSourcePath = newestSourcePath
        self.newestSourceModifiedAt = newestSourceModifiedAt
    }
}

public struct BuildTargetValidation: Codable, Equatable, Identifiable {
    public var id: String { target.id }

    public let target: BuildTarget
    public let commandTool: ToolAvailability?
    public let output: BuildOutputValidation?
    public let diagnostics: [Diagnostic]

    public init(
        target: BuildTarget,
        commandTool: ToolAvailability? = nil,
        output: BuildOutputValidation? = nil,
        diagnostics: [Diagnostic] = []
    ) {
        self.target = target
        self.commandTool = commandTool
        self.output = output
        self.diagnostics = diagnostics
    }
}

public struct GeneratedArtifactInventoryItem: Codable, Equatable, Identifiable {
    public var id: String { relativePath }

    public let relativePath: String
    public let kind: SourceKind
    public let role: SourceRole
    public let exists: Bool
    public let matchedPaths: [String]
    public let matchCount: Int

    public init(
        relativePath: String,
        kind: SourceKind,
        role: SourceRole,
        exists: Bool,
        matchedPaths: [String] = []
    ) {
        self.relativePath = relativePath
        self.kind = kind
        self.role = role
        self.exists = exists
        self.matchedPaths = matchedPaths
        self.matchCount = matchedPaths.count
    }
}

public struct BuildValidationReport: Codable, Equatable {
    public let adapterID: String
    public let profile: GameProfile
    public let rootPath: String
    public let targets: [BuildTargetValidation]
    public let sha1Expectations: [SHA1Expectation]
    public let generatedArtifacts: [GeneratedArtifactInventoryItem]
    public let diagnostics: [Diagnostic]
    public let isReady: Bool

    public init(
        adapterID: String,
        profile: GameProfile,
        rootPath: String,
        targets: [BuildTargetValidation],
        sha1Expectations: [SHA1Expectation],
        generatedArtifacts: [GeneratedArtifactInventoryItem],
        diagnostics: [Diagnostic]
    ) {
        self.adapterID = adapterID
        self.profile = profile
        self.rootPath = rootPath
        self.targets = targets
        self.sha1Expectations = sha1Expectations
        self.generatedArtifacts = generatedArtifacts
        self.diagnostics = diagnostics
        self.isReady = !diagnostics.contains { $0.severity == .error }
    }
}

public enum BuildValidationReportBuilder {
    public static func build(
        index: ProjectIndex,
        fileManager: FileManager = .default,
        toolResolver: ToolAvailabilityResolver = ToolAvailabilityResolverFactory.pathEnvironment()
    ) -> BuildValidationReport {
        let root = URL(fileURLWithPath: index.root.path).standardizedFileURL
        let sha1Expectations = loadSHA1Expectations(root: root, fileManager: fileManager)
        let generatedArtifacts = index.generatedOutputs.map {
            generatedArtifactStatus(for: $0, root: root, fileManager: fileManager)
        }
        let newestSource = newestSourceModification(in: index, root: root, fileManager: fileManager)

        var diagnostics = malformedSHA1Diagnostics(sha1Expectations)
        let targets = index.buildTargets.map { target in
            let targetReport = validate(
                target: target,
                index: index,
                root: root,
                sha1Expectations: sha1Expectations,
                newestSource: newestSource,
                fileManager: fileManager,
                toolResolver: toolResolver
            )
            diagnostics.append(contentsOf: targetReport.diagnostics)
            return targetReport
        }

        if index.buildTargets.isEmpty {
            diagnostics.append(
                diagnostic(
                    severity: .info,
                    code: "BUILD_TARGETS_EMPTY",
                    message: "No build targets are declared for this project."
                )
            )
        }

        return BuildValidationReport(
            adapterID: index.adapterID,
            profile: index.profile,
            rootPath: root.path,
            targets: targets,
            sha1Expectations: sha1Expectations,
            generatedArtifacts: generatedArtifacts,
            diagnostics: diagnostics
        )
    }

    private static func validate(
        target: BuildTarget,
        index: ProjectIndex,
        root: URL,
        sha1Expectations: [SHA1Expectation],
        newestSource: SourceModification?,
        fileManager: FileManager,
        toolResolver: ToolAvailabilityResolver
    ) -> BuildTargetValidation {
        var diagnostics: [Diagnostic] = []
        let tool = resolveCommandTool(target.command.first, root: root, fileManager: fileManager, toolResolver: toolResolver)

        if target.command.isEmpty {
            diagnostics.append(
                diagnostic(
                    severity: .error,
                    code: "BUILD_COMMAND_MISSING",
                    message: "Build target \(target.id) does not declare a command."
                )
            )
        } else if let tool, !tool.isAvailable {
            diagnostics.append(
                diagnostic(
                    severity: .error,
                    code: "BUILD_TOOL_MISSING",
                    message: "Build target \(target.id) requires \(tool.name), but it was not found."
                )
            )
        }

        guard let outputPath = target.outputPath else {
            diagnostics.append(
                diagnostic(
                    severity: .info,
                    code: "BUILD_OUTPUT_NOT_DECLARED",
                    message: "Build target \(target.id) does not declare an output artifact."
                )
            )
            return BuildTargetValidation(target: target, commandTool: tool, diagnostics: diagnostics)
        }

        let output = validateOutput(
            relativePath: outputPath,
            target: target,
            index: index,
            root: root,
            sha1Expectations: sha1Expectations,
            newestSource: newestSource,
            fileManager: fileManager,
            diagnostics: &diagnostics
        )

        return BuildTargetValidation(target: target, commandTool: tool, output: output, diagnostics: diagnostics)
    }

    private static func validateOutput(
        relativePath: String,
        target: BuildTarget,
        index: ProjectIndex,
        root: URL,
        sha1Expectations: [SHA1Expectation],
        newestSource: SourceModification?,
        fileManager: FileManager,
        diagnostics: inout [Diagnostic]
    ) -> BuildOutputValidation {
        let outputURL = root.appendingPathComponent(relativePath)
        let exists = fileManager.fileExists(atPath: outputURL.path)
        let attributes = try? fileManager.attributesOfItem(atPath: outputURL.path)
        let size = fileSize(from: attributes)
        let modifiedAt = attributes?[.modificationDate] as? Date
        let expectation = matchingSHA1Expectation(
            for: relativePath,
            target: target,
            profile: index.profile,
            expectations: sha1Expectations
        )

        guard exists else {
            diagnostics.append(
                diagnostic(
                    severity: .warning,
                    code: "BUILD_OUTPUT_MISSING",
                    message: "Build target \(target.id) has no output at \(relativePath).",
                    span: SourceSpan(relativePath: relativePath, startLine: 1)
                )
            )
            return BuildOutputValidation(
                relativePath: relativePath,
                absolutePath: outputURL.path,
                exists: false,
                expectation: expectation,
                checksumStatus: .outputMissing,
                freshnessStatus: .outputMissing,
                newestSourcePath: newestSource?.relativePath,
                newestSourceModifiedAt: newestSource?.modifiedAt
            )
        }

        let sha1: String?
        let checksumStatus: BuildOutputChecksumStatus
        if let data = try? Data(contentsOf: outputURL) {
            sha1 = pokemonHackSHA1Hex(data)
            if let expected = expectation?.expectedSHA1 {
                checksumStatus = sha1 == expected ? .matched : .mismatched
                if checksumStatus == .mismatched {
                    diagnostics.append(
                        diagnostic(
                            severity: .error,
                            code: "BUILD_OUTPUT_CHECKSUM_MISMATCH",
                            message: "Build target \(target.id) output checksum does not match \(expectation?.relativePath ?? ".sha1") expectation.",
                            span: SourceSpan(relativePath: relativePath, startLine: 1)
                        )
                    )
                }
            } else {
                checksumStatus = expectation == nil ? .expectationMissing : .unreadable
            }
        } else {
            sha1 = nil
            checksumStatus = .unreadable
            diagnostics.append(
                diagnostic(
                    severity: .error,
                    code: "BUILD_OUTPUT_UNREADABLE",
                    message: "Build target \(target.id) output exists but could not be read: \(relativePath).",
                    span: SourceSpan(relativePath: relativePath, startLine: 1)
                )
            )
        }

        let freshnessStatus: BuildOutputFreshnessStatus
        if let modifiedAt, let newestSource {
            freshnessStatus = newestSource.modifiedAt > modifiedAt ? .stale : .fresh
            if freshnessStatus == .stale {
                diagnostics.append(
                    diagnostic(
                        severity: .warning,
                        code: "BUILD_OUTPUT_STALE",
                        message: "Build target \(target.id) output is older than \(newestSource.relativePath).",
                        span: SourceSpan(relativePath: relativePath, startLine: 1)
                    )
                )
            }
        } else if newestSource == nil {
            freshnessStatus = .noSourceModifiedTimes
        } else {
            freshnessStatus = .unknown
        }

        return BuildOutputValidation(
            relativePath: relativePath,
            absolutePath: outputURL.path,
            exists: true,
            sizeBytes: size,
            modifiedAt: modifiedAt,
            sha1: sha1,
            expectation: expectation,
            checksumStatus: checksumStatus,
            freshnessStatus: freshnessStatus,
            newestSourcePath: newestSource?.relativePath,
            newestSourceModifiedAt: newestSource?.modifiedAt
        )
    }

    private static func resolveCommandTool(
        _ command: String?,
        root: URL,
        fileManager: FileManager,
        toolResolver: ToolAvailabilityResolver
    ) -> ToolAvailability? {
        guard let command, !command.isEmpty else {
            return nil
        }

        guard command.contains("/") else {
            return toolResolver(command)
        }

        let candidate = command.hasPrefix("/")
            ? URL(fileURLWithPath: command)
            : root.appendingPathComponent(command)
        let exists = fileManager.fileExists(atPath: candidate.path)
        return ToolAvailability(
            name: command,
            isAvailable: exists && fileManager.isExecutableFile(atPath: candidate.path),
            resolvedPath: exists ? candidate.path : nil
        )
    }

    private static func loadSHA1Expectations(root: URL, fileManager: FileManager) -> [SHA1Expectation] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        return contents
            .filter { $0.lastPathComponent.lowercased().hasSuffix(".sha1") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { url in
                let text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
                let hash = firstSHA1(in: text)
                return SHA1Expectation(
                    relativePath: url.lastPathComponent,
                    expectedSHA1: hash,
                    isParseable: hash != nil
                )
            }
    }

    private static func firstSHA1(in text: String) -> String? {
        guard let range = text.range(of: #"[A-Fa-f0-9]{40}"#, options: .regularExpression) else {
            return nil
        }
        return String(text[range]).lowercased()
    }

    private static func malformedSHA1Diagnostics(_ expectations: [SHA1Expectation]) -> [Diagnostic] {
        expectations.compactMap { expectation in
            guard !expectation.isParseable else {
                return nil
            }
            return diagnostic(
                severity: .warning,
                code: "SHA1_EXPECTATION_MALFORMED",
                message: "Could not read a SHA1 checksum from \(expectation.relativePath).",
                span: SourceSpan(relativePath: expectation.relativePath, startLine: 1)
            )
        }
    }

    private static func matchingSHA1Expectation(
        for outputPath: String,
        target: BuildTarget,
        profile: GameProfile,
        expectations: [SHA1Expectation]
    ) -> SHA1Expectation? {
        let expectationByPath = Dictionary(uniqueKeysWithValues: expectations.map { ($0.relativePath.lowercased(), $0) })
        let filename = URL(fileURLWithPath: outputPath).lastPathComponent
        let basename = URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent
        var candidates = [
            "\(filename).sha1",
            "\(basename).sha1"
        ]

        if basename.hasPrefix("poke") {
            candidates.append(String(basename.dropFirst(4)) + ".sha1")
        }

        switch profile {
        case .pokeemerald, .pokeemeraldExpansion:
            candidates.append("rom.sha1")
        case .pokefirered:
            candidates.append(contentsOf: ["firered.sha1", "leafgreen.sha1", "rom.sha1"])
        case .pokeruby:
            if basename.lowercased().contains("sapphire") {
                candidates.append("sapphire.sha1")
            } else if basename.lowercased().contains("ruby") {
                candidates.append("ruby.sha1")
            }
        case .binaryROM, .pokemonColosseum, .pokemonXD, .pokemonBox, .pokemonChannel, .gameCubeMedia, .unknown:
            break
        }

        return candidates.lazy.compactMap { expectationByPath[$0.lowercased()] }.first
    }

    private static func generatedArtifactStatus(
        for document: SourceDocument,
        root: URL,
        fileManager: FileManager
    ) -> GeneratedArtifactInventoryItem {
        if document.relativePath.contains("*") {
            let matches = matchingGeneratedPaths(pattern: document.relativePath, root: root, fileManager: fileManager)
            return GeneratedArtifactInventoryItem(
                relativePath: document.relativePath,
                kind: document.kind,
                role: document.role,
                exists: !matches.isEmpty,
                matchedPaths: matches
            )
        }

        let exists = fileManager.fileExists(atPath: root.appendingPathComponent(document.relativePath).path)
        return GeneratedArtifactInventoryItem(
            relativePath: document.relativePath,
            kind: document.kind,
            role: document.role,
            exists: exists,
            matchedPaths: exists ? [document.relativePath] : []
        )
    }

    private static func matchingGeneratedPaths(
        pattern: String,
        root: URL,
        fileManager: FileManager
    ) -> [String] {
        let components = pattern.split(separator: "/").map(String.init)
        guard !components.isEmpty else {
            return []
        }

        func walk(directory: URL, componentIndex: Int, prefix: String) -> [String] {
            guard componentIndex < components.count else {
                return [prefix]
            }

            let component = components[componentIndex]
            if component.contains("*") {
                guard let children = try? fileManager.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: nil
                ) else {
                    return []
                }
                return children.flatMap { child -> [String] in
                    guard wildcard(component, matches: child.lastPathComponent) else {
                        return []
                    }
                    let childPrefix = prefix.isEmpty ? child.lastPathComponent : "\(prefix)/\(child.lastPathComponent)"
                    return walk(directory: child, componentIndex: componentIndex + 1, prefix: childPrefix)
                }
            }

            let next = directory.appendingPathComponent(component)
            guard fileManager.fileExists(atPath: next.path) else {
                return []
            }
            let nextPrefix = prefix.isEmpty ? component : "\(prefix)/\(component)"
            return walk(directory: next, componentIndex: componentIndex + 1, prefix: nextPrefix)
        }

        return walk(directory: root, componentIndex: 0, prefix: "").sorted()
    }

    private static func wildcard(_ pattern: String, matches value: String) -> Bool {
        let escaped = NSRegularExpression.escapedPattern(for: pattern)
            .replacingOccurrences(of: "\\*", with: ".*")
        return value.range(of: "^\(escaped)$", options: .regularExpression) != nil
    }

    private static func newestSourceModification(
        in index: ProjectIndex,
        root: URL,
        fileManager: FileManager
    ) -> SourceModification? {
        index.documents
            .filter { $0.role == .source && $0.exists }
            .compactMap { document in
                newestModification(
                    at: root.appendingPathComponent(document.relativePath),
                    relativePath: document.relativePath,
                    root: root,
                    fileManager: fileManager
                )
            }
            .max { $0.modifiedAt < $1.modifiedAt }
    }

    private static func newestModification(
        at url: URL,
        relativePath: String,
        root: URL,
        fileManager: FileManager
    ) -> SourceModification? {
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        var newest = modification(at: url, relativePath: relativePath, fileManager: fileManager)
        guard isDirectory(url, fileManager: fileManager) else {
            return newest
        }

        let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )

        while let child = enumerator?.nextObject() as? URL {
            guard let values = try? child.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey]),
                  values.isRegularFile == true,
                  let modifiedAt = values.contentModificationDate else {
                continue
            }
            let childRelativePath = relativePathFromRoot(child, root: root)
            let candidate = SourceModification(relativePath: childRelativePath, modifiedAt: modifiedAt)
            if newest == nil || candidate.modifiedAt > newest!.modifiedAt {
                newest = candidate
            }
        }

        return newest
    }

    private static func modification(at url: URL, relativePath: String, fileManager: FileManager) -> SourceModification? {
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let modifiedAt = attributes[.modificationDate] as? Date else {
            return nil
        }
        return SourceModification(relativePath: relativePath, modifiedAt: modifiedAt)
    }
}

public struct PatchValidationReport: Codable, Equatable {
    public let path: String?
    public let exists: Bool
    public let sizeBytes: UInt64?
    public let summary: PatchSummary?
    public let diagnostics: [Diagnostic]
    public let isValid: Bool

    public init(
        path: String?,
        exists: Bool,
        sizeBytes: UInt64? = nil,
        summary: PatchSummary? = nil,
        diagnostics: [Diagnostic]
    ) {
        self.path = path
        self.exists = exists
        self.sizeBytes = sizeBytes
        self.summary = summary
        self.diagnostics = diagnostics
        self.isValid = exists && !diagnostics.contains { $0.severity == .error }
    }
}

public enum PatchValidationReportBuilder {
    public static func validate(
        path: String,
        fileManager: FileManager = .default
    ) -> PatchValidationReport {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        guard fileManager.fileExists(atPath: url.path) else {
            return PatchValidationReport(
                path: url.path,
                exists: false,
                diagnostics: [
                    diagnostic(
                        severity: .error,
                        code: "PATCH_NOT_FOUND",
                        message: "Patch file does not exist: \(url.path)."
                    )
                ]
            )
        }

        do {
            let data = try Data(contentsOf: url)
            let attributes = try? fileManager.attributesOfItem(atPath: url.path)
            let size = fileSize(from: attributes) ?? UInt64(data.count)
            return validate(data: data, path: url.path, sizeBytes: size)
        } catch {
            return PatchValidationReport(
                path: url.path,
                exists: true,
                diagnostics: [
                    diagnostic(
                        severity: .error,
                        code: "PATCH_READ_FAILED",
                        message: "Patch file could not be read: \(error.localizedDescription)"
                    )
                ]
            )
        }
    }

    public static func validate(
        data: Data,
        path: String? = nil,
        sizeBytes: UInt64? = nil
    ) -> PatchValidationReport {
        do {
            let summary = try PatchParser.parseSummary(data: data)
            if summary.format == .unknown {
                return PatchValidationReport(
                    path: path,
                    exists: true,
                    sizeBytes: sizeBytes ?? UInt64(data.count),
                    summary: summary,
                    diagnostics: [
                        diagnostic(
                            severity: .error,
                            code: "PATCH_FORMAT_UNKNOWN",
                            message: "Patch format could not be identified."
                        )
                    ]
                )
            }

            return PatchValidationReport(
                path: path,
                exists: true,
                sizeBytes: sizeBytes ?? UInt64(data.count),
                summary: summary,
                diagnostics: []
            )
        } catch {
            let format = PatchParser.sniff(data: data)
            return PatchValidationReport(
                path: path,
                exists: true,
                sizeBytes: sizeBytes ?? UInt64(data.count),
                summary: PatchSummary(
                    format: format,
                    hasEmbeddedChecksums: hasEmbeddedChecksums(format)
                ),
                diagnostics: [
                    diagnostic(
                        severity: .error,
                        code: "PATCH_MALFORMED",
                        message: "Patch metadata could not be parsed: \(error.localizedDescription)"
                    )
                ]
            )
        }
    }

    private static func hasEmbeddedChecksums(_ format: PatchFormatID) -> Bool {
        switch format {
        case .bps, .ups, .apsGBA:
            true
        case .ips, .unknown:
            false
        }
    }
}

public struct ROMCandidateStatus: Codable, Equatable {
    public let targetID: String?
    public let relativePath: String?
    public let absolutePath: String
    public let exists: Bool
    public let sha1: String?

    public init(
        targetID: String?,
        relativePath: String?,
        absolutePath: String,
        exists: Bool,
        sha1: String? = nil
    ) {
        self.targetID = targetID
        self.relativePath = relativePath
        self.absolutePath = absolutePath
        self.exists = exists
        self.sha1 = sha1
    }
}

public struct PlaytestHandoffReport: Codable, Equatable {
    public let adapterID: String
    public let profile: GameProfile
    public let mode: PlaytestMode
    public let emulator: ToolAvailability
    public let romCandidate: ROMCandidateStatus?
    public let session: PlaytestSession
    public let diagnostics: [Diagnostic]
    public let isRunnable: Bool

    public init(
        adapterID: String,
        profile: GameProfile,
        mode: PlaytestMode,
        emulator: ToolAvailability,
        romCandidate: ROMCandidateStatus?,
        diagnostics: [Diagnostic]
    ) {
        let isRunnable = romCandidate?.exists == true && emulator.isAvailable
        self.adapterID = adapterID
        self.profile = profile
        self.mode = mode
        self.emulator = emulator
        self.romCandidate = romCandidate
        self.diagnostics = diagnostics
        self.isRunnable = isRunnable
        self.session = PlaytestSession(
            mode: mode,
            emulator: emulator.name,
            romPath: romCandidate?.absolutePath,
            arguments: mode == .headless ? ["--headless"] : [],
            artifacts: Self.plannedArtifacts(mode: mode, romCandidate: romCandidate),
            isRunnable: isRunnable,
            diagnostics: diagnostics
        )
    }

    private static func plannedArtifacts(mode: PlaytestMode, romCandidate: ROMCandidateStatus?) -> [PlaytestSessionArtifact] {
        let stem = romCandidate?.relativePath.map { URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent } ?? "playtest"
        let root = ".pokemonhackstudio/playtests/\(stem)"
        var artifacts = [
            PlaytestSessionArtifact(kind: .runLog, relativePath: "\(root)/run.log", detail: "External emulator launch log."),
            PlaytestSessionArtifact(kind: .stdout, relativePath: "\(root)/stdout.log", detail: "Captured emulator standard output."),
            PlaytestSessionArtifact(kind: .stderr, relativePath: "\(root)/stderr.log", detail: "Captured emulator standard error."),
            PlaytestSessionArtifact(kind: .screenshot, relativePath: "\(root)/screenshot.png", detail: "Optional screenshot captured by the playtest bridge.")
        ]
        if mode == .headless {
            artifacts.append(
                PlaytestSessionArtifact(kind: .saveState, relativePath: "\(root)/headless.ss0", detail: "Optional headless smoke savestate capture.")
            )
        }
        return artifacts
    }
}

public enum PlaytestLaunchStatus: String, Codable, Equatable {
    case launched
    case blocked
    case failed
}

public struct PlaytestProcessRequest: Equatable {
    public let executableURL: URL
    public let arguments: [String]
    public let workingDirectoryURL: URL
    public let standardOutputURL: URL
    public let standardErrorURL: URL

    public init(
        executableURL: URL,
        arguments: [String],
        workingDirectoryURL: URL,
        standardOutputURL: URL,
        standardErrorURL: URL
    ) {
        self.executableURL = executableURL
        self.arguments = arguments
        self.workingDirectoryURL = workingDirectoryURL
        self.standardOutputURL = standardOutputURL
        self.standardErrorURL = standardErrorURL
    }
}

public typealias PlaytestProcessRunner = (PlaytestProcessRequest) throws -> Int32

public struct PlaytestLaunchResult: Codable, Equatable {
    public let status: PlaytestLaunchStatus
    public let mode: PlaytestMode
    public let projectRootPath: String
    public let emulatorPath: String?
    public let romPath: String?
    public let command: [String]
    public let processID: Int32?
    public let artifacts: [PlaytestSessionArtifact]
    public let diagnostics: [Diagnostic]
    public let launchedAt: Date?

    public init(
        status: PlaytestLaunchStatus,
        mode: PlaytestMode,
        projectRootPath: String,
        emulatorPath: String?,
        romPath: String?,
        command: [String],
        processID: Int32? = nil,
        artifacts: [PlaytestSessionArtifact],
        diagnostics: [Diagnostic],
        launchedAt: Date? = nil
    ) {
        self.status = status
        self.mode = mode
        self.projectRootPath = projectRootPath
        self.emulatorPath = emulatorPath
        self.romPath = romPath
        self.command = command
        self.processID = processID
        self.artifacts = artifacts
        self.diagnostics = diagnostics
        self.launchedAt = launchedAt
    }
}

public enum PlaytestHandoffReportBuilder {
    public static func build(
        index: ProjectIndex,
        mode: PlaytestMode = .headless,
        fileManager: FileManager = .default,
        toolResolver: ToolAvailabilityResolver = ToolAvailabilityResolverFactory.pathEnvironment()
    ) -> PlaytestHandoffReport {
        let root = URL(fileURLWithPath: index.root.path).standardizedFileURL
        let emulator = toolResolver("mgba")
        let romCandidate = findROMCandidate(index: index, root: root, fileManager: fileManager)
        var diagnostics: [Diagnostic] = [
            diagnostic(
                severity: .info,
                code: "PLAYTEST_PLAN_ONLY",
                message: "Playtest handoff is validated only; this report never launches an emulator."
            )
        ]

        if romCandidate == nil {
            diagnostics.append(
                diagnostic(
                    severity: .error,
                    code: "PLAYTEST_ROM_CANDIDATE_MISSING",
                    message: "No .gba ROM candidate is declared for playtest handoff."
                )
            )
        } else if romCandidate?.exists == false {
            diagnostics.append(
                diagnostic(
                    severity: .warning,
                    code: "PLAYTEST_ROM_NOT_BUILT",
                    message: "ROM candidate is declared but does not exist: \(romCandidate?.absolutePath ?? "")."
                )
            )
        }

        if !emulator.isAvailable {
            diagnostics.append(
                diagnostic(
                    severity: .warning,
                    code: "PLAYTEST_EMULATOR_MISSING",
                    message: "mGBA was not found in PATH or common macOS application locations."
                )
            )
        }

        return PlaytestHandoffReport(
            adapterID: index.adapterID,
            profile: index.profile,
            mode: mode,
            emulator: emulator,
            romCandidate: romCandidate,
            diagnostics: diagnostics
        )
    }

    private static func findROMCandidate(
        index: ProjectIndex,
        root: URL,
        fileManager: FileManager
    ) -> ROMCandidateStatus? {
        if index.profile == .binaryROM {
            return romCandidate(targetID: nil, relativePath: nil, url: root, fileManager: fileManager)
        }

        let buildOutputCandidates = index.buildTargets
            .compactMap { target -> (BuildTarget, String)? in
                guard let outputPath = target.outputPath,
                      outputPath.lowercased().hasSuffix(".gba") else {
                    return nil
                }
                return (target, outputPath)
            }

        let firstExisting = buildOutputCandidates.first {
            fileManager.fileExists(atPath: root.appendingPathComponent($0.1).path)
        }
        let selected = firstExisting ?? buildOutputCandidates.first
        guard let selected else {
            return nil
        }

        return romCandidate(
            targetID: selected.0.id,
            relativePath: selected.1,
            url: root.appendingPathComponent(selected.1),
            fileManager: fileManager
        )
    }

    private static func romCandidate(
        targetID: String?,
        relativePath: String?,
        url: URL,
        fileManager: FileManager
    ) -> ROMCandidateStatus {
        let exists = fileManager.fileExists(atPath: url.path)
        let sha1 = exists ? (try? Data(contentsOf: url)).map(pokemonHackSHA1Hex) : nil
        return ROMCandidateStatus(
            targetID: targetID,
            relativePath: relativePath,
            absolutePath: url.path,
            exists: exists,
            sha1: sha1
        )
    }
}

public enum PlaytestLauncher {
    public static func launch(
        index: ProjectIndex,
        mode: PlaytestMode = .interactive,
        artifactRoot: URL? = nil,
        fileManager: FileManager = .default,
        toolResolver: ToolAvailabilityResolver = ToolAvailabilityResolverFactory.pathEnvironment(),
        processRunner: PlaytestProcessRunner = PlaytestLauncher.defaultProcessRunner,
        now: () -> Date = Date.init
    ) -> PlaytestLaunchResult {
        let report = PlaytestHandoffReportBuilder.build(
            index: index,
            mode: mode,
            fileManager: fileManager,
            toolResolver: toolResolver
        )
        return launch(
            report: report,
            projectRoot: URL(fileURLWithPath: index.root.path),
            artifactRoot: artifactRoot,
            fileManager: fileManager,
            processRunner: processRunner,
            now: now
        )
    }

    public static func launch(
        report: PlaytestHandoffReport,
        projectRoot: URL,
        artifactRoot: URL? = nil,
        fileManager: FileManager = .default,
        processRunner: PlaytestProcessRunner = PlaytestLauncher.defaultProcessRunner,
        now: () -> Date = Date.init
    ) -> PlaytestLaunchResult {
        let root = projectRoot.standardizedFileURL
        let artifactRoot = (artifactRoot ?? root).standardizedFileURL
        let artifacts = launchArtifacts(from: report, root: artifactRoot, fileManager: fileManager)
        let romPath = report.romCandidate?.absolutePath
        let executablePath = executablePath(for: report.emulator, fileManager: fileManager)
        let command = executablePath.map { [$0] + report.session.arguments + [romPath].compactMap { $0 } } ?? []

        guard report.isRunnable else {
            return PlaytestLaunchResult(
                status: .blocked,
                mode: report.mode,
                projectRootPath: root.path,
                emulatorPath: executablePath,
                romPath: romPath,
                command: command,
                artifacts: artifacts,
                diagnostics: report.diagnostics + [
                    diagnostic(
                        severity: .warning,
                        code: "PLAYTEST_LAUNCH_BLOCKED",
                        message: "Playtest launch was blocked because the handoff report is not runnable."
                    )
                ]
            )
        }

        guard let executablePath else {
            return PlaytestLaunchResult(
                status: .blocked,
                mode: report.mode,
                projectRootPath: root.path,
                emulatorPath: report.emulator.resolvedPath,
                romPath: romPath,
                command: command,
                artifacts: artifacts,
                diagnostics: report.diagnostics + [
                    diagnostic(
                        severity: .error,
                        code: "PLAYTEST_EMULATOR_EXECUTABLE_MISSING",
                        message: "mGBA was discovered, but no executable could be resolved for launch."
                    )
                ]
            )
        }

        guard let romPath else {
            return PlaytestLaunchResult(
                status: .blocked,
                mode: report.mode,
                projectRootPath: root.path,
                emulatorPath: executablePath,
                romPath: nil,
                command: command,
                artifacts: artifacts,
                diagnostics: report.diagnostics + [
                    diagnostic(
                        severity: .error,
                        code: "PLAYTEST_ROM_CANDIDATE_MISSING",
                        message: "No ROM path is available for mGBA launch."
                    )
                ]
            )
        }

        guard
            let stdoutURL = artifactURL(kind: .stdout, artifacts: artifacts, root: artifactRoot),
            let stderrURL = artifactURL(kind: .stderr, artifacts: artifacts, root: artifactRoot),
            let runLogURL = artifactURL(kind: .runLog, artifacts: artifacts, root: artifactRoot)
        else {
            return PlaytestLaunchResult(
                status: .failed,
                mode: report.mode,
                projectRootPath: root.path,
                emulatorPath: executablePath,
                romPath: romPath,
                command: command,
                artifacts: artifacts,
                diagnostics: report.diagnostics + [
                    diagnostic(
                        severity: .error,
                        code: "PLAYTEST_ARTIFACT_PLAN_MISSING",
                        message: "Playtest launch artifacts are incomplete."
                    )
                ]
            )
        }

        do {
            try fileManager.createDirectory(at: runLogURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data().write(to: stdoutURL)
            try Data().write(to: stderrURL)

            let request = PlaytestProcessRequest(
                executableURL: URL(fileURLWithPath: executablePath),
                arguments: report.session.arguments + [romPath],
                workingDirectoryURL: root,
                standardOutputURL: stdoutURL,
                standardErrorURL: stderrURL
            )
            let processID = try processRunner(request)
            let launchDate = now()
            try runLog(
                report: report,
                executablePath: executablePath,
                romPath: romPath,
                rootPath: root.path,
                processID: processID,
                launchedAt: launchDate
            ).write(to: runLogURL, atomically: true, encoding: .utf8)

            return PlaytestLaunchResult(
                status: .launched,
                mode: report.mode,
                projectRootPath: root.path,
                emulatorPath: executablePath,
                romPath: romPath,
                command: command,
                processID: processID,
                artifacts: launchArtifacts(from: report, root: artifactRoot, fileManager: fileManager),
                diagnostics: report.diagnostics,
                launchedAt: launchDate
            )
        } catch {
            return PlaytestLaunchResult(
                status: .failed,
                mode: report.mode,
                projectRootPath: root.path,
                emulatorPath: executablePath,
                romPath: romPath,
                command: command,
                artifacts: launchArtifacts(from: report, root: artifactRoot, fileManager: fileManager),
                diagnostics: report.diagnostics + [
                    diagnostic(
                        severity: .error,
                        code: "PLAYTEST_LAUNCH_FAILED",
                        message: "mGBA launch failed: \(error.localizedDescription)"
                    )
                ]
            )
        }
    }

    public static func executablePath(
        for emulator: ToolAvailability,
        fileManager: FileManager = .default
    ) -> String? {
        guard let resolvedPath = emulator.resolvedPath else {
            return nil
        }

        let resolvedURL = URL(fileURLWithPath: resolvedPath)
        if resolvedURL.pathExtension == "app" {
            let executableURL = resolvedURL.appendingPathComponent("Contents/MacOS/mGBA")
            guard fileManager.fileExists(atPath: executableURL.path),
                  fileManager.isExecutableFile(atPath: executableURL.path) else {
                return nil
            }
            return executableURL.path
        }

        guard fileManager.fileExists(atPath: resolvedURL.path),
              fileManager.isExecutableFile(atPath: resolvedURL.path) else {
            return nil
        }
        return resolvedURL.path
    }

    public static func defaultProcessRunner(_ request: PlaytestProcessRequest) throws -> Int32 {
        let process = Process()
        process.executableURL = request.executableURL
        process.arguments = request.arguments
        process.currentDirectoryURL = request.workingDirectoryURL

        let stdoutHandle = try FileHandle(forWritingTo: request.standardOutputURL)
        let stderrHandle = try FileHandle(forWritingTo: request.standardErrorURL)
        defer {
            try? stdoutHandle.close()
            try? stderrHandle.close()
        }

        process.standardOutput = stdoutHandle
        process.standardError = stderrHandle
        try process.run()
        return process.processIdentifier
    }

    private static func launchArtifacts(
        from report: PlaytestHandoffReport,
        root: URL,
        fileManager: FileManager
    ) -> [PlaytestSessionArtifact] {
        report.session.artifacts.map { artifact in
            let url = root.appendingPathComponent(artifact.relativePath)
            return PlaytestSessionArtifact(
                kind: artifact.kind,
                relativePath: artifact.relativePath,
                isExpected: artifact.isExpected,
                exists: fileManager.fileExists(atPath: url.path),
                detail: artifact.detail
            )
        }
    }

    private static func artifactURL(
        kind: PlaytestSessionArtifactKind,
        artifacts: [PlaytestSessionArtifact],
        root: URL
    ) -> URL? {
        artifacts.first { $0.kind == kind }.map { root.appendingPathComponent($0.relativePath) }
    }

    private static func runLog(
        report: PlaytestHandoffReport,
        executablePath: String,
        romPath: String,
        rootPath: String,
        processID: Int32,
        launchedAt: Date
    ) -> String {
        [
            "launchedAt: \(ISO8601DateFormatter().string(from: launchedAt))",
            "projectRoot: \(rootPath)",
            "mode: \(report.mode.rawValue)",
            "emulator: \(executablePath)",
            "rom: \(romPath)",
            "romSHA1: \(report.romCandidate?.sha1 ?? "unknown")",
            "targetID: \(report.romCandidate?.targetID ?? "unknown")",
            "processID: \(processID)",
            "command: \(([executablePath] + report.session.arguments + [romPath]).joined(separator: " "))",
            ""
        ].joined(separator: "\n")
    }
}

private struct SourceModification: Equatable {
    let relativePath: String
    let modifiedAt: Date
}

private func isDirectory(_ url: URL, fileManager: FileManager) -> Bool {
    var isDirectory: ObjCBool = false
    return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
}

private func relativePathFromRoot(_ url: URL, root: URL) -> String {
    let rootPath = root.standardizedFileURL.path
    let path = url.standardizedFileURL.path
    guard path.hasPrefix(rootPath + "/") else {
        return url.lastPathComponent
    }
    return String(path.dropFirst(rootPath.count + 1))
}

private func fileSize(from attributes: [FileAttributeKey: Any]?) -> UInt64? {
    guard let value = attributes?[.size] else {
        return nil
    }
    if let size = value as? UInt64 {
        return size
    }
    if let size = value as? Int {
        return UInt64(size)
    }
    if let size = value as? NSNumber {
        return size.uint64Value
    }
    return nil
}

private func diagnostic(
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
