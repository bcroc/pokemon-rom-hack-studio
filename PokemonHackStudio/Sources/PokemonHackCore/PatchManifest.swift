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

public enum PatchBinaryDiffChangeKind: String, Codable, Equatable {
    case bytes
    case runLength
    case metadataOnly
}

public struct PatchBinaryDiffChange: Codable, Equatable, Identifiable {
    public var id: String { "\(kind.rawValue):\(offset):\(length)" }

    public let offset: UInt32
    public let length: UInt32
    public let kind: PatchBinaryDiffChangeKind
    public let originalPreviewHex: String?
    public let patchedPreviewHex: String?
    public let detail: String

    public init(
        offset: UInt32,
        length: UInt32,
        kind: PatchBinaryDiffChangeKind,
        originalPreviewHex: String?,
        patchedPreviewHex: String?,
        detail: String
    ) {
        self.offset = offset
        self.length = length
        self.kind = kind
        self.originalPreviewHex = originalPreviewHex
        self.patchedPreviewHex = patchedPreviewHex
        self.detail = detail
    }
}

public struct PatchFreeSpaceSuitability: Codable, Equatable, Identifiable {
    public var id: String { "\(freeSpaceOffset):\(requiredBytes)" }

    public let freeSpaceOffset: UInt32
    public let freeSpaceLength: UInt32
    public let requiredBytes: UInt32
    public let isSuitable: Bool
    public let detail: String

    public init(
        freeSpaceOffset: UInt32,
        freeSpaceLength: UInt32,
        requiredBytes: UInt32,
        isSuitable: Bool,
        detail: String
    ) {
        self.freeSpaceOffset = freeSpaceOffset
        self.freeSpaceLength = freeSpaceLength
        self.requiredBytes = requiredBytes
        self.isSuitable = isSuitable
        self.detail = detail
    }
}

public struct PatchPointerRepointPlan: Codable, Equatable, Identifiable {
    public var id: String { "\(pointerSourceOffset):\(oldTargetOffset):\(plannedTargetOffset)" }

    public let pointerSourceOffset: UInt32
    public let oldTargetOffset: UInt32
    public let plannedTargetOffset: UInt32
    public let oldRawValue: UInt32
    public let plannedRawValue: UInt32
    public let detail: String

    public init(
        pointerSourceOffset: UInt32,
        oldTargetOffset: UInt32,
        plannedTargetOffset: UInt32,
        oldRawValue: UInt32,
        plannedRawValue: UInt32,
        detail: String
    ) {
        self.pointerSourceOffset = pointerSourceOffset
        self.oldTargetOffset = oldTargetOffset
        self.plannedTargetOffset = plannedTargetOffset
        self.oldRawValue = oldRawValue
        self.plannedRawValue = plannedRawValue
        self.detail = detail
    }
}

public struct PatchBackupExportManifest: Codable, Equatable {
    public let backupPath: String?
    public let outputPath: String
    public let manifestPath: String
    public let baseROMSHA1: String?
    public let patchedROMSHA1: String?
    public let detail: String

    public init(
        backupPath: String?,
        outputPath: String,
        manifestPath: String,
        baseROMSHA1: String?,
        patchedROMSHA1: String?,
        detail: String
    ) {
        self.backupPath = backupPath
        self.outputPath = outputPath
        self.manifestPath = manifestPath
        self.baseROMSHA1 = baseROMSHA1
        self.patchedROMSHA1 = patchedROMSHA1
        self.detail = detail
    }
}

public struct PatchApplyExportState: Codable, Equatable {
    public let canApply: Bool
    public let canExport: Bool
    public let reasons: [String]

    public init(canApply: Bool, canExport: Bool, reasons: [String]) {
        self.canApply = canApply
        self.canExport = canExport
        self.reasons = reasons
    }
}

public struct PatchBinaryDiffPreview: Codable, Equatable {
    public let isPreviewOnly: Bool
    public let patchFormat: PatchFormatID
    public let baseROMPath: String?
    public let baseROMSizeBytes: UInt64?
    public let previewedChangeCount: Int
    public let changedByteCount: UInt64
    public let changes: [PatchBinaryDiffChange]
    public let freeSpaceSuitability: [PatchFreeSpaceSuitability]
    public let pointerRepointPlans: [PatchPointerRepointPlan]
    public let backupExportManifest: PatchBackupExportManifest
    public let applyExportState: PatchApplyExportState
    public let diagnostics: [Diagnostic]

    public init(
        isPreviewOnly: Bool,
        patchFormat: PatchFormatID,
        baseROMPath: String?,
        baseROMSizeBytes: UInt64?,
        previewedChangeCount: Int,
        changedByteCount: UInt64,
        changes: [PatchBinaryDiffChange],
        freeSpaceSuitability: [PatchFreeSpaceSuitability],
        pointerRepointPlans: [PatchPointerRepointPlan],
        backupExportManifest: PatchBackupExportManifest,
        applyExportState: PatchApplyExportState,
        diagnostics: [Diagnostic]
    ) {
        self.isPreviewOnly = isPreviewOnly
        self.patchFormat = patchFormat
        self.baseROMPath = baseROMPath
        self.baseROMSizeBytes = baseROMSizeBytes
        self.previewedChangeCount = previewedChangeCount
        self.changedByteCount = changedByteCount
        self.changes = changes
        self.freeSpaceSuitability = freeSpaceSuitability
        self.pointerRepointPlans = pointerRepointPlans
        self.backupExportManifest = backupExportManifest
        self.applyExportState = applyExportState
        self.diagnostics = diagnostics
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
    public let binaryDiffPreview: PatchBinaryDiffPreview?
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
        binaryDiffPreview: PatchBinaryDiffPreview? = nil,
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
        self.binaryDiffPreview = binaryDiffPreview
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
        let diffPreview = binaryDiffPreview(
            patch: patch,
            selectedBaseROM: selectedBaseROM,
            outputPath: absoluteOutputPath,
            fileManager: fileManager
        )
        diagnostics.append(contentsOf: diffPreview.diagnostics)

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
            binaryDiffPreview: diffPreview,
            diagnostics: diagnostics
        )
    }

    public static func binaryDiffPreview(
        patchPath: String,
        baseROMPath: String,
        outputPath: String? = nil,
        fileManager: FileManager = .default
    ) -> PatchBinaryDiffPreview {
        let patch = PatchValidationReportBuilder.validate(path: patchPath, fileManager: fileManager)
        let selectedBaseROM = selectedBaseROMReport(
            from: baseROMPath,
            projectRoot: nil,
            candidates: [],
            fileManager: fileManager
        )
        let patchURL = URL(fileURLWithPath: patch.path ?? patchPath).standardizedFileURL
        let fallbackOutputPath = patchURL
            .deletingLastPathComponent()
            .appendingPathComponent(".pokemonhackstudio/patches/\(patchURL.deletingPathExtension().lastPathComponent)-preview.gba")
            .standardizedFileURL
            .path
        return binaryDiffPreview(
            patch: patch,
            selectedBaseROM: selectedBaseROM,
            outputPath: outputPath ?? fallbackOutputPath,
            fileManager: fileManager
        )
    }

    private static func binaryDiffPreview(
        patch: PatchValidationReport,
        selectedBaseROM: PatchSelectedBaseROM?,
        outputPath: String,
        fileManager: FileManager
    ) -> PatchBinaryDiffPreview {
        let format = patch.summary?.format ?? .unknown
        let manifest = PatchBackupExportManifest(
            backupPath: selectedBaseROM?.absolutePath.appending(".bak"),
            outputPath: outputPath,
            manifestPath: outputPath.appending(".manifest.json"),
            baseROMSHA1: selectedBaseROM?.sha1,
            patchedROMSHA1: nil,
            detail: "Backup, patched ROM, and manifest paths are planned only; no files are written."
        )
        let blockedState = PatchApplyExportState(
            canApply: false,
            canExport: false,
            reasons: [
                "Binary patch apply/export is intentionally disabled in this preview.",
                "Pointer rewrites and free-space use are mutation plans only.",
                "Patched ROM checksums are unavailable until a future explicit export flow."
            ]
        )
        var diagnostics = patch.diagnostics
        guard patch.isValid else {
            diagnostics.append(Diagnostic(severity: .warning, code: "PATCH_BINARY_DIFF_BLOCKED_INVALID_PATCH", message: "Binary diff preview is blocked because the patch metadata is invalid."))
            return PatchBinaryDiffPreview(
                isPreviewOnly: true,
                patchFormat: format,
                baseROMPath: selectedBaseROM?.absolutePath,
                baseROMSizeBytes: selectedBaseROM?.sizeBytes,
                previewedChangeCount: 0,
                changedByteCount: 0,
                changes: [],
                freeSpaceSuitability: [],
                pointerRepointPlans: [],
                backupExportManifest: manifest,
                applyExportState: blockedState,
                diagnostics: diagnostics
            )
        }
        guard let selectedBaseROM, selectedBaseROM.exists, let baseData = try? Data(contentsOf: URL(fileURLWithPath: selectedBaseROM.absolutePath)) else {
            diagnostics.append(Diagnostic(severity: .warning, code: "PATCH_BINARY_DIFF_BASE_ROM_REQUIRED", message: "Select a readable base ROM to preview byte diffs, free-space suitability, and pointer repoint plans."))
            return PatchBinaryDiffPreview(
                isPreviewOnly: true,
                patchFormat: format,
                baseROMPath: selectedBaseROM?.absolutePath,
                baseROMSizeBytes: selectedBaseROM?.sizeBytes,
                previewedChangeCount: 0,
                changedByteCount: 0,
                changes: [],
                freeSpaceSuitability: [],
                pointerRepointPlans: [],
                backupExportManifest: manifest,
                applyExportState: blockedState,
                diagnostics: diagnostics
            )
        }

        let records: [IPSDiffRecord]
        if format == .ips, let patchPath = patch.path, let patchData = try? Data(contentsOf: URL(fileURLWithPath: patchPath)) {
            do {
                records = try parseIPSDiffRecords(data: patchData)
            } catch {
                diagnostics.append(Diagnostic(severity: .warning, code: "PATCH_BINARY_DIFF_PARSE_FAILED", message: "IPS byte diff preview could not be parsed: \(error.localizedDescription)"))
                records = []
            }
        } else {
            records = []
            diagnostics.append(Diagnostic(severity: .info, code: "PATCH_BINARY_DIFF_METADATA_ONLY", message: "\(format.rawValue.uppercased()) patches currently expose metadata-only binary diff previews; apply/export remains blocked."))
        }

        let graph = BinaryROMGraphBuilder.build(path: selectedBaseROM.absolutePath, data: baseData)
        let changes = records.prefix(64).map { record in
            PatchBinaryDiffChange(
                offset: record.offset,
                length: record.length,
                kind: record.isRunLength ? .runLength : .bytes,
                originalPreviewHex: hexPreview(data: baseData, offset: Int(record.offset), length: Int(record.length)),
                patchedPreviewHex: hexPreview(bytes: record.previewBytes),
                detail: String(format: "Would replace 0x%06X...0x%06X; preview only.", record.offset, record.offset + max(record.length, 1) - 1)
            )
        }
        let changedBytes = records.reduce(UInt64(0)) { $0 + UInt64($1.length) }
        let requiredBytes = records.map(\.length).max() ?? UInt32(patch.summary?.targetSize ?? 0)
        let suitability = graph.freeSpaceRanges.prefix(16).map { range in
            PatchFreeSpaceSuitability(
                freeSpaceOffset: range.offset,
                freeSpaceLength: range.length,
                requiredBytes: requiredBytes,
                isSuitable: requiredBytes > 0 && range.length >= requiredBytes,
                detail: requiredBytes == 0
                    ? "No concrete byte-span requirement is available for this patch format."
                    : String(format: "Free space 0x%06X has %u byte(s); largest previewed change requires %u byte(s).", range.offset, range.length, requiredBytes)
            )
        }
        let repoints = pointerRepointPlans(
            changes: changes,
            freeSpace: graph.freeSpaceRanges,
            pointers: graph.pointerCandidates
        )

        diagnostics.append(Diagnostic(severity: .info, code: "PATCH_BINARY_DIFF_PREVIEW_ONLY", message: "Binary diff, free-space, pointer-repoint, backup, and export outputs are previews only; no ROM bytes are changed."))
        if records.count > changes.count {
            diagnostics.append(Diagnostic(severity: .info, code: "PATCH_BINARY_DIFF_PREVIEW_TRUNCATED", message: "Showing \(changes.count) of \(records.count) parsed byte change(s)."))
        }
        if requiredBytes > 0, !suitability.contains(where: \.isSuitable) {
            diagnostics.append(Diagnostic(severity: .warning, code: "PATCH_FREE_SPACE_NO_SUITABLE_RANGE", message: "No previewed free-space range can fit the largest planned byte span."))
        }

        return PatchBinaryDiffPreview(
            isPreviewOnly: true,
            patchFormat: format,
            baseROMPath: selectedBaseROM.absolutePath,
            baseROMSizeBytes: selectedBaseROM.sizeBytes ?? UInt64(baseData.count),
            previewedChangeCount: changes.count,
            changedByteCount: changedBytes,
            changes: changes,
            freeSpaceSuitability: suitability,
            pointerRepointPlans: repoints,
            backupExportManifest: manifest,
            applyExportState: blockedState,
            diagnostics: diagnostics
        )
    }

    private struct IPSDiffRecord {
        let offset: UInt32
        let length: UInt32
        let previewBytes: [UInt8]
        let isRunLength: Bool
    }

    private static func parseIPSDiffRecords(data: Data) throws -> [IPSDiffRecord] {
        var cursor = ByteCursor(data: data)
        _ = try cursor.readBytes(count: 5)
        var records: [IPSDiffRecord] = []

        while !cursor.isAtEnd {
            let offset = try cursor.readUInt24BE()
            if offset == 0x454F46 { break }
            let size = try cursor.readUInt16BE()
            if size == 0 {
                let runLength = try cursor.readUInt16BE()
                let byte = try cursor.readUInt8()
                records.append(
                    IPSDiffRecord(
                        offset: offset,
                        length: UInt32(runLength),
                        previewBytes: Array(repeating: byte, count: min(Int(runLength), 16)),
                        isRunLength: true
                    )
                )
            } else {
                let bytes = try cursor.readBytes(count: Int(size))
                records.append(
                    IPSDiffRecord(
                        offset: offset,
                        length: UInt32(size),
                        previewBytes: Array(bytes.prefix(16)),
                        isRunLength: false
                    )
                )
            }
        }

        return records
    }

    private static func pointerRepointPlans(
        changes: [PatchBinaryDiffChange],
        freeSpace: [BinaryROMRange],
        pointers: [BinaryROMPointerCandidate]
    ) -> [PatchPointerRepointPlan] {
        var plans: [PatchPointerRepointPlan] = []
        for change in changes {
            guard let targetRange = freeSpace.first(where: { $0.length >= change.length }) else { continue }
            let end = change.offset + change.length
            for pointer in pointers where pointer.targetOffset >= change.offset && pointer.targetOffset < end {
                let delta = pointer.targetOffset - change.offset
                let plannedTarget = targetRange.offset + delta
                let plannedRaw = 0x0800_0000 + plannedTarget
                plans.append(
                    PatchPointerRepointPlan(
                        pointerSourceOffset: pointer.sourceOffset,
                        oldTargetOffset: pointer.targetOffset,
                        plannedTargetOffset: plannedTarget,
                        oldRawValue: pointer.rawValue,
                        plannedRawValue: plannedRaw,
                        detail: String(format: "Would repoint 0x%06X from 0x%06X to free-space target 0x%06X.", pointer.sourceOffset, pointer.targetOffset, plannedTarget)
                    )
                )
            }
        }
        return Array(plans.prefix(64))
    }

    private static func hexPreview(data: Data, offset: Int, length: Int) -> String? {
        guard offset >= 0, offset < data.count, length > 0 else { return nil }
        let end = min(data.count, offset + length, offset + 16)
        return hexPreview(bytes: Array(data[offset..<end]))
    }

    private static func hexPreview(bytes: [UInt8]) -> String? {
        guard !bytes.isEmpty else { return nil }
        return bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
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
