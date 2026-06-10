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

public enum PatchApplyExportStatus: String, Codable, Equatable {
    case exported
    case blocked
}

public struct PatchApplyExportManifest: Codable, Equatable {
    public let schemaVersion: Int
    public let action: String
    public let patchPath: String
    public let baseROMPath: String
    public let outputPath: String
    public let backupPath: String?
    public let patchFormat: PatchFormatID
    public let baseROMSHA1: String?
    public let outputROMSHA1: String?
    public let baseROMCRC32: String?
    public let outputROMCRC32: String?
    public let patchCRC32: String?
    public let checksumPolicy: String
    public let headerPolicy: PatchArtifactHeaderPolicy
    public let diagnostics: [Diagnostic]

    public init(
        schemaVersion: Int,
        action: String,
        patchPath: String,
        baseROMPath: String,
        outputPath: String,
        backupPath: String?,
        patchFormat: PatchFormatID,
        baseROMSHA1: String?,
        outputROMSHA1: String?,
        baseROMCRC32: String?,
        outputROMCRC32: String?,
        patchCRC32: String?,
        checksumPolicy: String,
        headerPolicy: PatchArtifactHeaderPolicy,
        diagnostics: [Diagnostic]
    ) {
        self.schemaVersion = schemaVersion
        self.action = action
        self.patchPath = patchPath
        self.baseROMPath = baseROMPath
        self.outputPath = outputPath
        self.backupPath = backupPath
        self.patchFormat = patchFormat
        self.baseROMSHA1 = baseROMSHA1
        self.outputROMSHA1 = outputROMSHA1
        self.baseROMCRC32 = baseROMCRC32
        self.outputROMCRC32 = outputROMCRC32
        self.patchCRC32 = patchCRC32
        self.checksumPolicy = checksumPolicy
        self.headerPolicy = headerPolicy
        self.diagnostics = diagnostics
    }
}

public struct PatchApplyExportResult: Codable, Equatable {
    public let status: PatchApplyExportStatus
    public let outputPath: String?
    public let manifestPath: String?
    public let backupPath: String?
    public let outputROMSHA1: String?
    public let diagnostics: [Diagnostic]
    public let manifest: PatchApplyExportManifest?

    public init(
        status: PatchApplyExportStatus,
        outputPath: String?,
        manifestPath: String?,
        backupPath: String?,
        outputROMSHA1: String?,
        diagnostics: [Diagnostic],
        manifest: PatchApplyExportManifest?
    ) {
        self.status = status
        self.outputPath = outputPath
        self.manifestPath = manifestPath
        self.backupPath = backupPath
        self.outputROMSHA1 = outputROMSHA1
        self.diagnostics = diagnostics
        self.manifest = manifest
    }
}

private enum PatchApplyError: Error, LocalizedError {
    case unsupported(String)
    case malformed(String)
    case checksumMismatch(String)

    var errorDescription: String? {
        switch self {
        case .unsupported(let message), .malformed(let message), .checksumMismatch(let message):
            message
        }
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
                message: "Patch manifests model base ROM compatibility, output artifact plans, and dry-run steps; ROM bytes are written only by an explicit patch apply/export action."
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
                    "Require an explicit apply/export action before writing the ignored patched ROM and manifest."
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

    public static func applyExport(
        patchPath: String,
        projectPath: String? = nil,
        baseROMPath: String,
        overwrite: Bool = false,
        fileManager: FileManager = .default,
        toolResolver: ToolAvailabilityResolver = ToolAvailabilityResolverFactory.pathEnvironment()
    ) throws -> PatchApplyExportResult {
        let report = try build(
            patchPath: patchPath,
            projectPath: projectPath,
            baseROMPath: baseROMPath,
            fileManager: fileManager,
            toolResolver: toolResolver
        )
        let blocked = applyExportBlockers(report)
        guard blocked.isEmpty,
              let selectedBaseROM = report.selectedBaseROM,
              let patchPath = report.patch.path else {
            return PatchApplyExportResult(
                status: .blocked,
                outputPath: report.artifactPlan.absoluteOutputPath,
                manifestPath: report.artifactPlan.binaryDiffPreview?.backupExportManifest.manifestPath,
                backupPath: nil,
                outputROMSHA1: nil,
                diagnostics: blocked,
                manifest: nil
            )
        }

        let outputURL = URL(fileURLWithPath: report.artifactPlan.absoluteOutputPath).standardizedFileURL
        var diagnostics = report.diagnostics
        if fileManager.fileExists(atPath: outputURL.path), !overwrite {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "PATCH_EXPORT_OUTPUT_EXISTS",
                    message: "Patched ROM output already exists at \(outputURL.path); export was blocked because overwrite was not requested."
                )
            )
            return PatchApplyExportResult(
                status: .blocked,
                outputPath: outputURL.path,
                manifestPath: report.artifactPlan.binaryDiffPreview?.backupExportManifest.manifestPath,
                backupPath: nil,
                outputROMSHA1: nil,
                diagnostics: diagnostics,
                manifest: nil
            )
        }

        try fileManager.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        var backupPath: String?
        if fileManager.fileExists(atPath: outputURL.path) {
            let backupURL = backupURLForExistingOutput(outputURL: outputURL, projectRoot: report.projectRoot, fileManager: fileManager)
            try fileManager.createDirectory(at: backupURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: backupURL.path) {
                try fileManager.removeItem(at: backupURL)
            }
            try fileManager.copyItem(at: outputURL, to: backupURL)
            backupPath = backupURL.path
            try fileManager.removeItem(at: outputURL)
        }

        let baseData = try Data(contentsOf: URL(fileURLWithPath: selectedBaseROM.absolutePath))
        let patchData = try Data(contentsOf: URL(fileURLWithPath: patchPath))
        let patchedData: Data
        do {
            patchedData = try applyPatch(
                format: report.artifactPlan.patchFormat,
                patchData: patchData,
                baseData: baseData
            )
        } catch {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "PATCH_EXPORT_APPLY_FAILED",
                    message: "Patch apply/export failed: \(error.localizedDescription)"
                )
            )
            return PatchApplyExportResult(
                status: .blocked,
                outputPath: outputURL.path,
                manifestPath: report.artifactPlan.binaryDiffPreview?.backupExportManifest.manifestPath,
                backupPath: backupPath,
                outputROMSHA1: nil,
                diagnostics: diagnostics,
                manifest: nil
            )
        }

        try patchedData.write(to: outputURL, options: .atomic)
        let outputSHA1 = pokemonHackSHA1Hex(patchedData)
        let outputCRC = crc32Hex(patchedData)
        let manifestURL = URL(fileURLWithPath: report.artifactPlan.binaryDiffPreview?.backupExportManifest.manifestPath ?? outputURL.path.appending(".manifest.json"))
        let manifest = PatchApplyExportManifest(
            schemaVersion: 1,
            action: "patch-apply-export",
            patchPath: patchPath,
            baseROMPath: selectedBaseROM.absolutePath,
            outputPath: outputURL.path,
            backupPath: backupPath,
            patchFormat: report.artifactPlan.patchFormat,
            baseROMSHA1: selectedBaseROM.sha1,
            outputROMSHA1: outputSHA1,
            baseROMCRC32: crc32Hex(baseData),
            outputROMCRC32: outputCRC,
            patchCRC32: crc32Hex(patchData),
            checksumPolicy: checksumPolicy(for: report.artifactPlan.patchFormat),
            headerPolicy: report.artifactPlan.headerPolicy,
            diagnostics: diagnostics
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(manifest).write(to: manifestURL, options: .atomic)

        diagnostics.append(
            Diagnostic(
                severity: .info,
                code: "PATCH_EXPORT_WRITTEN",
                message: "Patched ROM was exported to \(outputURL.path); manifest written to \(manifestURL.path)."
            )
        )
        return PatchApplyExportResult(
            status: .exported,
            outputPath: outputURL.path,
            manifestPath: manifestURL.path,
            backupPath: backupPath,
            outputROMSHA1: outputSHA1,
            diagnostics: diagnostics,
            manifest: manifest
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

    private static func applyExportBlockers(_ report: PatchManifestReport) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        if report.compatibilityStatus != .compatible {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "PATCH_EXPORT_BASE_ROM_NOT_COMPATIBLE",
                    message: "Patch apply/export requires a selected base ROM whose SHA1 matches an existing manifest candidate."
                )
            )
        }
        switch report.artifactPlan.patchFormat {
        case .bps, .ips:
            break
        case .ups, .apsGBA, .unknown:
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "PATCH_EXPORT_FORMAT_UNSUPPORTED",
                    message: "Patch apply/export currently supports BPS and IPS patches only; \(report.artifactPlan.patchFormat.rawValue.uppercased()) remains manifest-only."
                )
            )
        }
        if report.patch.diagnostics.contains(where: { $0.severity == .error }) {
            diagnostics.append(contentsOf: report.patch.diagnostics.filter { $0.severity == .error })
        }
        if report.artifactPlan.headerPolicy.shouldRewriteHeader {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "PATCH_EXPORT_HEADER_REWRITE_BLOCKED",
                    message: "Patch apply/export preserves base ROM header bytes and will not rewrite title, game code, maker code, or header checksum."
                )
            )
        }
        return diagnostics
    }

    private static func applyPatch(
        format: PatchFormatID,
        patchData: Data,
        baseData: Data
    ) throws -> Data {
        switch format {
        case .bps:
            return try applyBPSPatch(patchData: patchData, baseData: baseData)
        case .ips:
            return try applyIPSPatch(patchData: patchData, baseData: baseData)
        case .ups, .apsGBA, .unknown:
            throw PatchApplyError.unsupported("Unsupported patch format \(format.rawValue).")
        }
    }

    private static func applyIPSPatch(patchData: Data, baseData: Data) throws -> Data {
        var output = Array(baseData)
        let records = try parseIPSDiffRecords(data: patchData)
        for record in records {
            let offset = Int(record.offset)
            let length = Int(record.length)
            guard length >= 0 else {
                throw PatchApplyError.malformed("IPS record length is invalid.")
            }
            if output.count < offset + length {
                output.append(contentsOf: Array(repeating: 0, count: offset + length - output.count))
            }
            let bytes: [UInt8]
            if record.isRunLength {
                guard let byte = record.previewBytes.first else {
                    throw PatchApplyError.malformed("IPS RLE record is missing a byte value.")
                }
                bytes = Array(repeating: byte, count: length)
            } else {
                bytes = record.previewBytes.count == length
                    ? record.previewBytes
                    : try fullIPSRecordBytes(patchData: patchData, matching: record)
            }
            output.replaceSubrange(offset..<(offset + length), with: bytes)
        }
        return Data(output)
    }

    private static func fullIPSRecordBytes(patchData: Data, matching target: IPSDiffRecord) throws -> [UInt8] {
        var cursor = ByteCursor(data: patchData)
        _ = try cursor.readBytes(count: 5)
        while !cursor.isAtEnd {
            let offset = try cursor.readUInt24BE()
            if offset == 0x454F46 { break }
            let size = try cursor.readUInt16BE()
            if size == 0 {
                let runLength = try cursor.readUInt16BE()
                let byte = try cursor.readUInt8()
                if offset == target.offset, UInt32(runLength) == target.length {
                    return Array(repeating: byte, count: Int(runLength))
                }
            } else {
                let bytes = try cursor.readBytes(count: Int(size))
                if offset == target.offset, UInt32(size) == target.length {
                    return bytes
                }
            }
        }
        throw PatchApplyError.malformed("IPS record bytes could not be recovered for export.")
    }

    private static func applyBPSPatch(patchData: Data, baseData: Data) throws -> Data {
        let bytes = Array(patchData)
        guard bytes.count >= 4, Data(bytes[0..<4]) == Data("BPS1".utf8) else {
            throw PatchApplyError.malformed("BPS patch header is missing.")
        }
        let hasChecksumTrailer = bytes.count >= 16
        let patchBodyEnd = hasChecksumTrailer ? bytes.count - 12 : bytes.count
        var cursor = ByteCursor(data: Data(bytes[0..<patchBodyEnd]))
        _ = try cursor.readBytes(count: 4)
        let sourceSize = try cursor.readVariableLengthQuantity()
        let targetSize = try cursor.readVariableLengthQuantity()
        let metadataSize = try cursor.readVariableLengthQuantity()
        if metadataSize > 0 {
            _ = try cursor.readBytes(count: Int(metadataSize))
        }
        guard sourceSize == UInt64(baseData.count) else {
            throw PatchApplyError.checksumMismatch("BPS source size \(sourceSize) does not match selected base ROM size \(baseData.count).")
        }

        var output: [UInt8] = []
        output.reserveCapacity(Int(targetSize))
        let source = Array(baseData)
        var sourceRelativeOffset = 0
        var targetRelativeOffset = 0

        while output.count < Int(targetSize), !cursor.isAtEnd {
            let data = try cursor.readVariableLengthQuantity()
            let command = Int(data & 0x03)
            let length = Int((data >> 2) + 1)
            switch command {
            case 0:
                let offset = output.count
                guard offset + length <= source.count else {
                    throw PatchApplyError.malformed("BPS SourceRead exceeds source ROM size.")
                }
                output.append(contentsOf: source[offset..<(offset + length)])
            case 1:
                output.append(contentsOf: try cursor.readBytes(count: length))
            case 2:
                sourceRelativeOffset += try readBPSSignedOffset(cursor: &cursor)
                guard sourceRelativeOffset >= 0, sourceRelativeOffset + length <= source.count else {
                    throw PatchApplyError.malformed("BPS SourceCopy exceeds source ROM size.")
                }
                output.append(contentsOf: source[sourceRelativeOffset..<(sourceRelativeOffset + length)])
                sourceRelativeOffset += length
            case 3:
                targetRelativeOffset += try readBPSSignedOffset(cursor: &cursor)
                guard targetRelativeOffset >= 0 else {
                    throw PatchApplyError.malformed("BPS TargetCopy has a negative target offset.")
                }
                for index in 0..<length {
                    let sourceIndex = targetRelativeOffset + index
                    guard sourceIndex < output.count else {
                        throw PatchApplyError.malformed("BPS TargetCopy references bytes that have not been written.")
                    }
                    output.append(output[sourceIndex])
                }
                targetRelativeOffset += length
            default:
                throw PatchApplyError.malformed("BPS command is invalid.")
            }
        }

        guard output.count == Int(targetSize) else {
            throw PatchApplyError.malformed("BPS output size \(output.count) does not match target size \(targetSize).")
        }
        let outputData = Data(output)
        if hasChecksumTrailer {
            let expectedSourceCRC = readUInt32LE(bytes, offset: bytes.count - 12)
            let expectedTargetCRC = readUInt32LE(bytes, offset: bytes.count - 8)
            let expectedPatchCRC = readUInt32LE(bytes, offset: bytes.count - 4)
            guard crc32(baseData) == expectedSourceCRC else {
                throw PatchApplyError.checksumMismatch("BPS embedded source CRC32 does not match the selected base ROM.")
            }
            guard crc32(outputData) == expectedTargetCRC else {
                throw PatchApplyError.checksumMismatch("BPS embedded target CRC32 does not match the exported ROM.")
            }
            guard crc32(Data(bytes[0..<(bytes.count - 4)])) == expectedPatchCRC else {
                throw PatchApplyError.checksumMismatch("BPS embedded patch CRC32 does not match the patch file.")
            }
        }
        return outputData
    }

    private static func readBPSSignedOffset(cursor: inout ByteCursor) throws -> Int {
        let value = try cursor.readVariableLengthQuantity()
        let magnitude = Int(value >> 1)
        return value & 1 == 0 ? magnitude : -magnitude
    }

    private static func backupURLForExistingOutput(outputURL: URL, projectRoot: String?, fileManager: FileManager) -> URL {
        let root = projectRoot.map { URL(fileURLWithPath: $0) } ?? outputURL.deletingLastPathComponent().deletingLastPathComponent()
        return root
            .appendingPathComponent(".pokemonhackstudio/backups/\(backupTimestamp())/patches")
            .appendingPathComponent(outputURL.lastPathComponent)
            .standardizedFileURL
    }

    private static func backupTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }

    private static func checksumPolicy(for format: PatchFormatID) -> String {
        switch format {
        case .bps:
            return "BPS-first policy: require selected base ROM manifest SHA1 compatibility before export, verify embedded BPS CRC32 checksums when present, compute exported ROM SHA1/CRC32, and preserve the base ROM header bytes."
        case .ips:
            return "IPS compatibility policy: require selected base ROM manifest SHA1 compatibility before export, compute exported ROM SHA1/CRC32, and preserve the base ROM header bytes because IPS has no embedded checksums."
        case .ups, .apsGBA, .unknown:
            return "Unsupported export format; manifest validation only."
        }
    }

    private static func crc32Hex(_ data: Data) -> String {
        String(format: "%08x", crc32(data))
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                let mask = 0 &- (crc & 1)
                crc = (crc >> 1) ^ (0xEDB8_8320 & mask)
            }
        }
        return ~crc
    }

    private static func readUInt32LE(_ bytes: [UInt8], offset: Int) -> UInt32 {
        UInt32(bytes[offset])
            | (UInt32(bytes[offset + 1]) << 8)
            | (UInt32(bytes[offset + 2]) << 16)
            | (UInt32(bytes[offset + 3]) << 24)
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
