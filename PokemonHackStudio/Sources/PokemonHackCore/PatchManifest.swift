import Foundation

public enum PatchManifestCompatibilityStatus: String, Codable, Equatable {
    case compatible
    case needsBaseROM
    case baseROMMismatch
    case unknown
    case invalidPatch
}

public struct PatchBaseROMCandidate: Codable, Equatable, Identifiable {
    public var id: String { relativePath }

    public let relativePath: String
    public let expectedSHA1: String?
    public let builtOutputPath: String?
    public let builtOutputSHA1: String?
    public let exists: Bool

    public init(
        relativePath: String,
        expectedSHA1: String?,
        builtOutputPath: String? = nil,
        builtOutputSHA1: String? = nil,
        exists: Bool = false
    ) {
        self.relativePath = relativePath
        self.expectedSHA1 = expectedSHA1
        self.builtOutputPath = builtOutputPath
        self.builtOutputSHA1 = builtOutputSHA1
        self.exists = exists
    }
}

public struct PatchManifestDryRunPlan: Codable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let steps: [String]
    public let diagnostics: [Diagnostic]

    public init(id: String, title: String, steps: [String], diagnostics: [Diagnostic] = []) {
        self.id = id
        self.title = title
        self.steps = steps
        self.diagnostics = diagnostics
    }
}

public struct PatchSelectedBaseROM: Codable, Equatable {
    public let path: String
    public let absolutePath: String
    public let exists: Bool
    public let sizeBytes: UInt64?
    public let sha1: String?
    public let matchedCandidateRelativePath: String?
    public let matchedCandidateBuiltOutputPath: String?

    public init(
        path: String,
        absolutePath: String,
        exists: Bool,
        sizeBytes: UInt64? = nil,
        sha1: String? = nil,
        matchedCandidateRelativePath: String? = nil,
        matchedCandidateBuiltOutputPath: String? = nil
    ) {
        self.path = path
        self.absolutePath = absolutePath
        self.exists = exists
        self.sizeBytes = sizeBytes
        self.sha1 = sha1
        self.matchedCandidateRelativePath = matchedCandidateRelativePath
        self.matchedCandidateBuiltOutputPath = matchedCandidateBuiltOutputPath
    }
}

public struct PatchArtifactChecksumExpectations: Codable, Equatable {
    public let baseROMSHA1: String?
    public let expectedBaseROMSHA1: String?
    public let matchedCandidateRelativePath: String?
    public let patchHasEmbeddedChecksums: Bool
    public let expectedPatchedROMSHA1: String?
    public let targetSizeBytes: UInt64?
    public let policy: String

    public init(
        baseROMSHA1: String?,
        expectedBaseROMSHA1: String?,
        matchedCandidateRelativePath: String?,
        patchHasEmbeddedChecksums: Bool,
        expectedPatchedROMSHA1: String? = nil,
        targetSizeBytes: UInt64?,
        policy: String
    ) {
        self.baseROMSHA1 = baseROMSHA1
        self.expectedBaseROMSHA1 = expectedBaseROMSHA1
        self.matchedCandidateRelativePath = matchedCandidateRelativePath
        self.patchHasEmbeddedChecksums = patchHasEmbeddedChecksums
        self.expectedPatchedROMSHA1 = expectedPatchedROMSHA1
        self.targetSizeBytes = targetSizeBytes
        self.policy = policy
    }
}

public struct PatchArtifactHeaderPolicy: Codable, Equatable {
    public let mode: String
    public let detail: String
    public let shouldRewriteHeader: Bool

    public init(mode: String, detail: String, shouldRewriteHeader: Bool) {
        self.mode = mode
        self.detail = detail
        self.shouldRewriteHeader = shouldRewriteHeader
    }
}

public struct PatchArtifactLaunchPreview: Codable, Equatable {
    public let emulatorName: String
    public let emulatorPath: String?
    public let outputROMPath: String
    public let command: [String]
    public let isLaunchEnabled: Bool
    public let disabledReason: String?

    public init(
        emulatorName: String,
        emulatorPath: String?,
        outputROMPath: String,
        command: [String],
        isLaunchEnabled: Bool,
        disabledReason: String?
    ) {
        self.emulatorName = emulatorName
        self.emulatorPath = emulatorPath
        self.outputROMPath = outputROMPath
        self.command = command
        self.isLaunchEnabled = isLaunchEnabled
        self.disabledReason = disabledReason
    }
}

public struct PatchArtifactPlan: Codable, Equatable, Identifiable {
    public var id: String { absoluteOutputPath }

    public let isPreviewOnly: Bool
    public let selectedBaseROMPath: String?
    public let patchFormat: PatchFormatID
    public let outputPath: String
    public let absoluteOutputPath: String
    public let checksumExpectations: PatchArtifactChecksumExpectations
    public let headerPolicy: PatchArtifactHeaderPolicy
    public let expectedPatchedROMName: String
    public let mgbaLaunchPreview: PatchArtifactLaunchPreview
    public let diagnostics: [Diagnostic]

    public init(
        isPreviewOnly: Bool,
        selectedBaseROMPath: String?,
        patchFormat: PatchFormatID,
        outputPath: String,
        absoluteOutputPath: String,
        checksumExpectations: PatchArtifactChecksumExpectations,
        headerPolicy: PatchArtifactHeaderPolicy,
        expectedPatchedROMName: String,
        mgbaLaunchPreview: PatchArtifactLaunchPreview,
        diagnostics: [Diagnostic] = []
    ) {
        self.isPreviewOnly = isPreviewOnly
        self.selectedBaseROMPath = selectedBaseROMPath
        self.patchFormat = patchFormat
        self.outputPath = outputPath
        self.absoluteOutputPath = absoluteOutputPath
        self.checksumExpectations = checksumExpectations
        self.headerPolicy = headerPolicy
        self.expectedPatchedROMName = expectedPatchedROMName
        self.mgbaLaunchPreview = mgbaLaunchPreview
        self.diagnostics = diagnostics
    }
}

public struct PatchManifestReport: Codable, Equatable {
    public let patch: PatchValidationReport
    public let projectRoot: String?
    public let baseROMCandidates: [PatchBaseROMCandidate]
    public let selectedBaseROM: PatchSelectedBaseROM?
    public let compatibilityStatus: PatchManifestCompatibilityStatus
    public let artifactPlan: PatchArtifactPlan
    public let dryRunPlans: [PatchManifestDryRunPlan]
    public let diagnostics: [Diagnostic]

    public init(
        patch: PatchValidationReport,
        projectRoot: String?,
        baseROMCandidates: [PatchBaseROMCandidate],
        selectedBaseROM: PatchSelectedBaseROM? = nil,
        compatibilityStatus: PatchManifestCompatibilityStatus,
        artifactPlan: PatchArtifactPlan,
        dryRunPlans: [PatchManifestDryRunPlan],
        diagnostics: [Diagnostic]
    ) {
        self.patch = patch
        self.projectRoot = projectRoot
        self.baseROMCandidates = baseROMCandidates
        self.selectedBaseROM = selectedBaseROM
        self.compatibilityStatus = compatibilityStatus
        self.artifactPlan = artifactPlan
        self.dryRunPlans = dryRunPlans
        self.diagnostics = diagnostics
    }
}

public enum PatchManifestBuilder {
    public static func build(
        patchPath: String,
        projectPath: String? = nil,
        baseROMPath: String? = nil,
        fileManager: FileManager = .default,
        toolResolver: ToolAvailabilityResolver = ToolAvailabilityResolverFactory.pathEnvironment()
    ) throws -> PatchManifestReport {
        let patch = PatchValidationReportBuilder.validate(path: patchPath, fileManager: fileManager)
        var candidates: [PatchBaseROMCandidate] = []
        var diagnostics = patch.diagnostics
        var projectRoot: String?

        if let projectPath {
            let index = try GameAdapterRegistry.index(path: projectPath)
            let buildReport = BuildValidationReportBuilder.build(index: index, fileManager: fileManager)
            projectRoot = index.root.path
            candidates = candidatesFrom(buildReport: buildReport)
            diagnostics.append(contentsOf: buildReport.diagnostics.filter { $0.severity == .error })
        }

        let selectedBaseROM = selectedBaseROMReport(
            from: baseROMPath,
            projectRoot: projectRoot,
            candidates: candidates,
            fileManager: fileManager
        )
        diagnostics.append(contentsOf: selectedBaseROMDiagnostics(selectedBaseROM, candidates: candidates))

        let compatibility = compatibilityStatus(patch: patch, selectedBaseROM: selectedBaseROM, candidates: candidates)
        let artifactPlan = artifactPlan(
            patch: patch,
            selectedBaseROM: selectedBaseROM,
            candidates: candidates,
            projectRoot: projectRoot,
            fileManager: fileManager,
            toolResolver: toolResolver
        )
        let dryRuns = dryRunPlans(
            patch: patch,
            selectedBaseROM: selectedBaseROM,
            candidates: candidates,
            compatibility: compatibility,
            artifactPlan: artifactPlan
        )
        diagnostics.append(contentsOf: artifactPlan.diagnostics)
        diagnostics.append(
            Diagnostic(
                severity: .info,
                code: "PATCH_MANIFEST_PLAN_ONLY",
                message: "Patch manifests model base ROM compatibility, output artifact plans, and dry-run steps without applying or creating patches."
            )
        )

        return PatchManifestReport(
            patch: patch,
            projectRoot: projectRoot,
            baseROMCandidates: candidates,
            selectedBaseROM: selectedBaseROM,
            compatibilityStatus: compatibility,
            artifactPlan: artifactPlan,
            dryRunPlans: dryRuns,
            diagnostics: diagnostics
        )
    }

    private static func candidatesFrom(buildReport: BuildValidationReport) -> [PatchBaseROMCandidate] {
        var outputsByExpectation: [String: BuildOutputValidation] = [:]
        for target in buildReport.targets {
            guard let output = target.output, let expectation = output.expectation else { continue }
            let key = expectation.relativePath
            if let existing = outputsByExpectation[key], existing.exists {
                continue
            }
            outputsByExpectation[key] = output
        }

        return buildReport.sha1Expectations.map { expectation in
            let output = outputsByExpectation[expectation.relativePath]
            return PatchBaseROMCandidate(
                relativePath: expectation.relativePath,
                expectedSHA1: expectation.expectedSHA1,
                builtOutputPath: output?.relativePath,
                builtOutputSHA1: output?.sha1,
                exists: output?.exists ?? false
            )
        }
    }

    private static func compatibilityStatus(
        patch: PatchValidationReport,
        selectedBaseROM: PatchSelectedBaseROM?,
        candidates: [PatchBaseROMCandidate]
    ) -> PatchManifestCompatibilityStatus {
        guard patch.isValid else { return .invalidPatch }
        guard let selectedBaseROM else {
            return patch.summary?.hasEmbeddedChecksums == true ? .unknown : .needsBaseROM
        }
        guard selectedBaseROM.exists else { return .needsBaseROM }
        guard selectedBaseROM.sha1 != nil else { return .unknown }
        if selectedBaseROM.matchedCandidateRelativePath != nil {
            return .compatible
        }
        return candidates.isEmpty ? .unknown : .baseROMMismatch
    }

    private static func dryRunPlans(
        patch: PatchValidationReport,
        selectedBaseROM: PatchSelectedBaseROM?,
        candidates: [PatchBaseROMCandidate],
        compatibility: PatchManifestCompatibilityStatus,
        artifactPlan: PatchArtifactPlan
    ) -> [PatchManifestDryRunPlan] {
        let baseROMStep = selectedBaseROM.map { selected in
            selected.exists
                ? "Selected base ROM: \(selected.absolutePath); SHA1 \(selected.sha1 ?? "unavailable")."
                : "Selected base ROM is missing at \(selected.absolutePath)."
        } ?? "No base ROM selected; keep apply/export disabled."

        return [
            PatchManifestDryRunPlan(
                id: "verify",
                title: "Verify patch metadata",
                steps: [
                    "Read patch header and format.",
                    "Report embedded checksum availability.",
                    baseROMStep,
                    "Compare selected base ROM SHA1 against \(candidates.count) known candidate(s) when available."
                ],
                diagnostics: patch.diagnostics
            ),
            PatchManifestDryRunPlan(
                id: "apply",
                title: "Plan patch apply",
                steps: [
                    "Select a user-provided base ROM.",
                    "Check base ROM SHA1 against \(candidates.count) candidate(s).",
                    "Plan output artifact \(artifactPlan.outputPath) as \(artifactPlan.patchFormat.rawValue.uppercased()).",
                    "Keep ROM header policy at \(artifactPlan.headerPolicy.mode).",
                    "Keep apply/export disabled in this preview-only pass."
                ],
                diagnostics: compatibility == .invalidPatch
                    ? patch.diagnostics
                    : selectedBaseROMDiagnostics(selectedBaseROM, candidates: candidates)
            )
        ]
    }

    private static func selectedBaseROMReport(
        from baseROMPath: String?,
        projectRoot: String?,
        candidates: [PatchBaseROMCandidate],
        fileManager: FileManager
    ) -> PatchSelectedBaseROM? {
        guard
            let baseROMPath,
            !baseROMPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        let trimmedPath = baseROMPath.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = resolvedURL(for: trimmedPath, projectRoot: projectRoot, fileManager: fileManager)
        let exists = fileManager.fileExists(atPath: url.path)
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        let size = (attributes?[.size] as? NSNumber)?.uint64Value
        let sha1 = exists ? (try? Data(contentsOf: url)).map(pokemonHackSHA1Hex) : nil
        let matchedCandidate = sha1.flatMap { matchingCandidate(for: $0, candidates: candidates) }

        return PatchSelectedBaseROM(
            path: trimmedPath,
            absolutePath: url.path,
            exists: exists,
            sizeBytes: size,
            sha1: sha1,
            matchedCandidateRelativePath: matchedCandidate?.relativePath,
            matchedCandidateBuiltOutputPath: matchedCandidate?.builtOutputPath
        )
    }

    private static func artifactPlan(
        patch: PatchValidationReport,
        selectedBaseROM: PatchSelectedBaseROM?,
        candidates: [PatchBaseROMCandidate],
        projectRoot: String?,
        fileManager: FileManager,
        toolResolver: ToolAvailabilityResolver
    ) -> PatchArtifactPlan {
        let patchURL = URL(fileURLWithPath: patch.path ?? "patch").standardizedFileURL
        let patchStem = sanitizedArtifactComponent(patchURL.deletingPathExtension().lastPathComponent, fallback: "patch")
        let baseStem = selectedBaseROM
            .map { sanitizedArtifactComponent(URL(fileURLWithPath: $0.absolutePath).deletingPathExtension().lastPathComponent, fallback: "base") }
            ?? "selected-base"
        let expectedPatchedROMName = "\(baseStem)-\(patchStem).gba"
        let outputPath = ".pokemonhackstudio/patches/\(expectedPatchedROMName)"
        let outputRoot = projectRoot.map { URL(fileURLWithPath: $0) }
            ?? patchURL.deletingLastPathComponent()
        let absoluteOutputPath = outputRoot.appendingPathComponent(outputPath).standardizedFileURL.path
        let matchedCandidate = selectedBaseROM?.matchedCandidateRelativePath.flatMap { matchedPath in
            candidates.first { $0.relativePath == matchedPath }
        }
        let expectedBaseSHA1 = matchedCandidate?.expectedSHA1 ?? matchedCandidate?.builtOutputSHA1
        let patchSummary = patch.summary
        var diagnostics: [Diagnostic] = [
            Diagnostic(
                severity: .info,
                code: "PATCH_ARTIFACT_PLAN_ONLY",
                message: "Patch artifact output is planned at \(absoluteOutputPath); no patched ROM is written."
            )
        ]
        if fileManager.fileExists(atPath: absoluteOutputPath) {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "PATCH_ARTIFACT_OUTPUT_EXISTS",
                    message: "Planned patched ROM output already exists at \(absoluteOutputPath); preview will not overwrite it."
                )
            )
        }

        let checksumExpectations = PatchArtifactChecksumExpectations(
            baseROMSHA1: selectedBaseROM?.sha1,
            expectedBaseROMSHA1: expectedBaseSHA1,
            matchedCandidateRelativePath: selectedBaseROM?.matchedCandidateRelativePath,
            patchHasEmbeddedChecksums: patchSummary?.hasEmbeddedChecksums == true,
            expectedPatchedROMSHA1: nil,
            targetSizeBytes: patchSummary?.targetSize,
            policy: "Verify the selected base ROM SHA1 before apply; compute patched ROM SHA1 only after an explicit future export."
        )
        let headerPolicy = PatchArtifactHeaderPolicy(
            mode: "preserve-selected-base-rom-header",
            detail: "The planned apply/export flow preserves base ROM header bytes and does not rewrite title, game code, maker code, or header checksum.",
            shouldRewriteHeader: false
        )
        let emulator = toolResolver("mgba")
        let launchTool = emulator.resolvedPath ?? emulator.name
        let launchPreview = PatchArtifactLaunchPreview(
            emulatorName: emulator.name,
            emulatorPath: emulator.resolvedPath,
            outputROMPath: absoluteOutputPath,
            command: [launchTool, absoluteOutputPath],
            isLaunchEnabled: false,
            disabledReason: "Patched ROM export is disabled; mGBA launch remains a preview until the artifact exists."
        )

        return PatchArtifactPlan(
            isPreviewOnly: true,
            selectedBaseROMPath: selectedBaseROM?.absolutePath,
            patchFormat: patchSummary?.format ?? .unknown,
            outputPath: outputPath,
            absoluteOutputPath: absoluteOutputPath,
            checksumExpectations: checksumExpectations,
            headerPolicy: headerPolicy,
            expectedPatchedROMName: expectedPatchedROMName,
            mgbaLaunchPreview: launchPreview,
            diagnostics: diagnostics
        )
    }

    private static func selectedBaseROMDiagnostics(
        _ selectedBaseROM: PatchSelectedBaseROM?,
        candidates: [PatchBaseROMCandidate]
    ) -> [Diagnostic] {
        guard let selectedBaseROM else { return [] }
        guard selectedBaseROM.exists else {
            return [
                Diagnostic(
                    severity: .warning,
                    code: "PATCH_BASE_ROM_MISSING",
                    message: "Selected base ROM does not exist at \(selectedBaseROM.absolutePath)."
                )
            ]
        }
        guard let sha1 = selectedBaseROM.sha1 else {
            return [
                Diagnostic(
                    severity: .warning,
                    code: "PATCH_BASE_ROM_UNREADABLE",
                    message: "Selected base ROM exists but its SHA1 could not be read at \(selectedBaseROM.absolutePath)."
                )
            ]
        }
        if let matched = selectedBaseROM.matchedCandidateRelativePath {
            return [
                Diagnostic(
                    severity: .info,
                    code: "PATCH_BASE_ROM_MATCHED",
                    message: "Selected base ROM SHA1 matches candidate \(matched)."
                )
            ]
        }
        guard !candidates.isEmpty else { return [] }
        let expected = candidates
            .compactMap { $0.expectedSHA1 ?? $0.builtOutputSHA1 }
            .map { String($0.prefix(8)) }
            .joined(separator: ", ")
        return [
            Diagnostic(
                severity: .warning,
                code: "PATCH_BASE_ROM_MISMATCH",
                message: "Selected base ROM SHA1 \(String(sha1.prefix(8))) does not match known candidate checksum(s)\(expected.isEmpty ? "." : ": \(expected).")"
            )
        ]
    }

    private static func matchingCandidate(
        for sha1: String,
        candidates: [PatchBaseROMCandidate]
    ) -> PatchBaseROMCandidate? {
        let normalized = sha1.lowercased()
        return candidates.first { candidate in
            candidate.expectedSHA1?.lowercased() == normalized
                || candidate.builtOutputSHA1?.lowercased() == normalized
        }
    }

    private static func resolvedURL(for path: String, projectRoot: String?, fileManager: FileManager) -> URL {
        let url: URL
        if path.hasPrefix("/") {
            url = URL(fileURLWithPath: path)
        } else {
            let direct = URL(fileURLWithPath: path).standardizedFileURL
            if fileManager.fileExists(atPath: direct.path) {
                url = direct
            } else if let projectRoot {
                url = URL(fileURLWithPath: projectRoot).appendingPathComponent(path)
            } else {
                url = direct
            }
        }
        return url.standardizedFileURL
    }

    private static func sanitizedArtifactComponent(_ value: String, fallback: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let scalars = value.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar) : "-"
        }
        let sanitized = String(scalars).trimmingCharacters(in: CharacterSet(charactersIn: "-_"))
        return sanitized.isEmpty ? fallback : sanitized
    }
}
