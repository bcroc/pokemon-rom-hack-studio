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

public struct PatchCreationROMMetadata: Codable, Equatable {
    public let path: String
    public let absolutePath: String
    public let exists: Bool
    public let sizeBytes: UInt64?
    public let sha1: String?

    public init(
        path: String,
        absolutePath: String,
        exists: Bool,
        sizeBytes: UInt64? = nil,
        sha1: String? = nil
    ) {
        self.path = path
        self.absolutePath = absolutePath
        self.exists = exists
        self.sizeBytes = sizeBytes
        self.sha1 = sha1
    }
}

public struct PatchCreationBuiltOutputMetadata: Codable, Equatable {
    public let targetID: String
    public let targetName: String
    public let relativePath: String
    public let absolutePath: String
    public let exists: Bool
    public let sizeBytes: UInt64?
    public let sha1: String?
    public let checksumStatus: BuildOutputChecksumStatus
    public let freshnessStatus: BuildOutputFreshnessStatus

    public init(
        targetID: String,
        targetName: String,
        relativePath: String,
        absolutePath: String,
        exists: Bool,
        sizeBytes: UInt64? = nil,
        sha1: String? = nil,
        checksumStatus: BuildOutputChecksumStatus,
        freshnessStatus: BuildOutputFreshnessStatus
    ) {
        self.targetID = targetID
        self.targetName = targetName
        self.relativePath = relativePath
        self.absolutePath = absolutePath
        self.exists = exists
        self.sizeBytes = sizeBytes
        self.sha1 = sha1
        self.checksumStatus = checksumStatus
        self.freshnessStatus = freshnessStatus
    }
}

public struct PatchCreationPreviewReport: Codable, Equatable {
    public let isPreviewOnly: Bool
    public let isReady: Bool
    public let candidateFormat: PatchFormatID
    public let baseROM: PatchCreationROMMetadata
    public let builtOutput: PatchCreationBuiltOutputMetadata?
    public let sizeDeltaBytes: Int64?
    public let hashesMatch: Bool?
    public let plannedPatchPath: String
    public let absolutePlannedPatchPath: String
    public let headerPolicy: PatchArtifactHeaderPolicy
    public let blockedActions: [String]
    public let diagnostics: [Diagnostic]

    public init(
        isPreviewOnly: Bool,
        isReady: Bool,
        candidateFormat: PatchFormatID,
        baseROM: PatchCreationROMMetadata,
        builtOutput: PatchCreationBuiltOutputMetadata?,
        sizeDeltaBytes: Int64?,
        hashesMatch: Bool?,
        plannedPatchPath: String,
        absolutePlannedPatchPath: String,
        headerPolicy: PatchArtifactHeaderPolicy,
        blockedActions: [String],
        diagnostics: [Diagnostic]
    ) {
        self.isPreviewOnly = isPreviewOnly
        self.isReady = isReady
        self.candidateFormat = candidateFormat
        self.baseROM = baseROM
        self.builtOutput = builtOutput
        self.sizeDeltaBytes = sizeDeltaBytes
        self.hashesMatch = hashesMatch
        self.plannedPatchPath = plannedPatchPath
        self.absolutePlannedPatchPath = absolutePlannedPatchPath
        self.headerPolicy = headerPolicy
        self.blockedActions = blockedActions
        self.diagnostics = diagnostics
    }
}

public enum PatchCreationStatus: String, Codable, Equatable {
    case created
    case blocked
}

public enum PatchCreationVerificationStatus: String, Codable, Equatable {
    case passed
    case failed
}

public struct PatchCreationVerification: Codable, Equatable {
    public let status: PatchCreationVerificationStatus
    public let appliedOutputSHA1: String?
    public let appliedOutputCRC32: String?
    public let appliedOutputSizeBytes: UInt64?
    public let expectedBuiltOutputSHA1: String
    public let expectedBuiltOutputCRC32: String
    public let expectedBuiltOutputSizeBytes: UInt64
    public let sha1Matches: Bool
    public let crc32Matches: Bool
    public let sizeMatches: Bool
    public let headerPolicyMatches: Bool
    public let headerPolicy: PatchArtifactHeaderPolicy

    public init(
        status: PatchCreationVerificationStatus,
        appliedOutputSHA1: String?,
        appliedOutputCRC32: String?,
        appliedOutputSizeBytes: UInt64?,
        expectedBuiltOutputSHA1: String,
        expectedBuiltOutputCRC32: String,
        expectedBuiltOutputSizeBytes: UInt64,
        sha1Matches: Bool,
        crc32Matches: Bool,
        sizeMatches: Bool,
        headerPolicyMatches: Bool,
        headerPolicy: PatchArtifactHeaderPolicy
    ) {
        self.status = status
        self.appliedOutputSHA1 = appliedOutputSHA1
        self.appliedOutputCRC32 = appliedOutputCRC32
        self.appliedOutputSizeBytes = appliedOutputSizeBytes
        self.expectedBuiltOutputSHA1 = expectedBuiltOutputSHA1
        self.expectedBuiltOutputCRC32 = expectedBuiltOutputCRC32
        self.expectedBuiltOutputSizeBytes = expectedBuiltOutputSizeBytes
        self.sha1Matches = sha1Matches
        self.crc32Matches = crc32Matches
        self.sizeMatches = sizeMatches
        self.headerPolicyMatches = headerPolicyMatches
        self.headerPolicy = headerPolicy
    }
}

public struct PatchCreationArtifactManifest: Codable, Equatable {
    public let schemaVersion: Int
    public let action: String
    public let projectRoot: String
    public let baseROMPath: String
    public let baseROMSHA1: String
    public let baseROMCRC32: String
    public let baseROMSizeBytes: UInt64
    public let matchedBaseROMCandidate: String
    public let builtOutputPath: String
    public let builtOutputRelativePath: String
    public let builtOutputTargetID: String
    public let builtOutputSHA1: String
    public let builtOutputCRC32: String
    public let builtOutputSizeBytes: UInt64
    public let patchPath: String
    public let patchSHA1: String
    public let patchCRC32: String
    public let patchSizeBytes: UInt64
    public let patchFormat: PatchFormatID
    public let headerPolicy: PatchArtifactHeaderPolicy
    public let verification: PatchCreationVerification?
    public let diagnostics: [Diagnostic]

    public init(
        schemaVersion: Int,
        action: String,
        projectRoot: String,
        baseROMPath: String,
        baseROMSHA1: String,
        baseROMCRC32: String,
        baseROMSizeBytes: UInt64,
        matchedBaseROMCandidate: String,
        builtOutputPath: String,
        builtOutputRelativePath: String,
        builtOutputTargetID: String,
        builtOutputSHA1: String,
        builtOutputCRC32: String,
        builtOutputSizeBytes: UInt64,
        patchPath: String,
        patchSHA1: String,
        patchCRC32: String,
        patchSizeBytes: UInt64,
        patchFormat: PatchFormatID,
        headerPolicy: PatchArtifactHeaderPolicy,
        verification: PatchCreationVerification? = nil,
        diagnostics: [Diagnostic]
    ) {
        self.schemaVersion = schemaVersion
        self.action = action
        self.projectRoot = projectRoot
        self.baseROMPath = baseROMPath
        self.baseROMSHA1 = baseROMSHA1
        self.baseROMCRC32 = baseROMCRC32
        self.baseROMSizeBytes = baseROMSizeBytes
        self.matchedBaseROMCandidate = matchedBaseROMCandidate
        self.builtOutputPath = builtOutputPath
        self.builtOutputRelativePath = builtOutputRelativePath
        self.builtOutputTargetID = builtOutputTargetID
        self.builtOutputSHA1 = builtOutputSHA1
        self.builtOutputCRC32 = builtOutputCRC32
        self.builtOutputSizeBytes = builtOutputSizeBytes
        self.patchPath = patchPath
        self.patchSHA1 = patchSHA1
        self.patchCRC32 = patchCRC32
        self.patchSizeBytes = patchSizeBytes
        self.patchFormat = patchFormat
        self.headerPolicy = headerPolicy
        self.verification = verification
        self.diagnostics = diagnostics
    }
}

public struct PatchCreationResult: Codable, Equatable {
    public let status: PatchCreationStatus
    public let patchPath: String?
    public let manifestPath: String?
    public let patchSHA1: String?
    public let diagnostics: [Diagnostic]
    public let verification: PatchCreationVerification?
    public let manifest: PatchCreationArtifactManifest?

    public init(
        status: PatchCreationStatus,
        patchPath: String?,
        manifestPath: String?,
        patchSHA1: String?,
        diagnostics: [Diagnostic],
        verification: PatchCreationVerification? = nil,
        manifest: PatchCreationArtifactManifest?
    ) {
        self.status = status
        self.patchPath = patchPath
        self.manifestPath = manifestPath
        self.patchSHA1 = patchSHA1
        self.diagnostics = diagnostics
        self.verification = verification
        self.manifest = manifest
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

public enum PatchCreationPreviewBuilder {
    public static func build(
        projectPath: String,
        baseROMPath: String,
        targetID: String? = nil,
        fileManager: FileManager = .default
    ) throws -> PatchCreationPreviewReport {
        let index = try GameAdapterRegistry.index(path: projectPath)
        let root = URL(fileURLWithPath: index.root.path).standardizedFileURL
        let buildReport = BuildValidationReportBuilder.build(
            index: index,
            fileManager: fileManager,
            toolResolver: { ToolAvailability(name: $0, isAvailable: true) }
        )
        let target = selectedTarget(from: buildReport.targets, targetID: targetID)
        let baseROM = romMetadata(path: baseROMPath, root: root, fileManager: fileManager)
        let builtOutput = target.flatMap(builtOutputMetadata)
        let plannedPatchPath = plannedPatchRelativePath(baseROM: baseROM, builtOutput: builtOutput, targetID: targetID)
        let absolutePlannedPatchPath = root.appendingPathComponent(plannedPatchPath).standardizedFileURL.path
        var diagnostics = diagnosticsForTargetSelection(
            targets: buildReport.targets,
            selectedTarget: target,
            requestedTargetID: targetID
        )
        diagnostics.append(contentsOf: diagnosticsForBaseROM(baseROM))
        diagnostics.append(contentsOf: diagnosticsForBuiltOutput(builtOutput))
        if let builtOutput, builtOutput.checksumStatus == .mismatched {
            diagnostics.append(
                Diagnostic(
                    severity: .info,
                    code: "PATCH_CREATION_BUILD_OUTPUT_CHECKSUM_FACT",
                    message: "Built output SHA1 differs from its declared expectation; patch creation preview reports this as target metadata and does not block comparison."
                )
            )
        }
        if fileManager.fileExists(atPath: absolutePlannedPatchPath) {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "PATCH_CREATION_PLANNED_PATCH_EXISTS",
                    message: "A file already exists at the planned patch path \(absolutePlannedPatchPath); this preview will not overwrite it."
                )
            )
        }
        diagnostics.append(
            Diagnostic(
                severity: .info,
                code: "PATCH_CREATION_PREVIEW_ONLY",
                message: "Patch creation is a metadata preview only; no .ips/.bps files, ROMs, manifests, builds, playtests, header rewrites, source mutations, or binary writes are performed."
            )
        )

        let sizeDelta = signedDelta(from: baseROM.sizeBytes, to: builtOutput?.sizeBytes)
        let hashesMatch = hashesMatch(baseROM.sha1, builtOutput?.sha1)
        if hashesMatch == true {
            diagnostics.append(
                Diagnostic(
                    severity: .info,
                    code: "PATCH_CREATION_HASHES_MATCH",
                    message: "Selected base ROM and built output have the same SHA1; a future patch writer would have no changed output bytes to encode."
                )
            )
        }

        let isReady = baseROM.exists
            && baseROM.sha1 != nil
            && builtOutput?.exists == true
            && builtOutput?.sha1 != nil
        let headerPolicy = PatchArtifactHeaderPolicy(
            mode: "no-header-rewrite",
            detail: "Patch creation preview compares the selected base ROM and built output as-is and will not rewrite title, game code, maker code, or header checksum.",
            shouldRewriteHeader: false
        )
        return PatchCreationPreviewReport(
            isPreviewOnly: true,
            isReady: isReady,
            candidateFormat: .bps,
            baseROM: baseROM,
            builtOutput: builtOutput,
            sizeDeltaBytes: sizeDelta,
            hashesMatch: hashesMatch,
            plannedPatchPath: plannedPatchPath,
            absolutePlannedPatchPath: absolutePlannedPatchPath,
            headerPolicy: headerPolicy,
            blockedActions: [
                "BPS/IPS patch file writes",
                "source mutation",
                "build execution",
                "playtest launch",
                "header rewrite",
                "ROM export",
                "binary writes"
            ],
            diagnostics: diagnostics
        )
    }

    private static func selectedTarget(
        from targets: [BuildTargetValidation],
        targetID: String?
    ) -> BuildTargetValidation? {
        if let targetID {
            return targets.first { $0.target.id == targetID }
        }
        return targets.first { $0.target.outputPath != nil }
    }

    private static func romMetadata(path: String, root: URL, fileManager: FileManager) -> PatchCreationROMMetadata {
        let absoluteURL = resolvedURL(path: path, root: root, fileManager: fileManager)
        let exists = fileManager.fileExists(atPath: absoluteURL.path)
        let attributes = try? fileManager.attributesOfItem(atPath: absoluteURL.path)
        let size = (attributes?[.size] as? NSNumber)?.uint64Value
        let sha1 = exists ? (try? Data(contentsOf: absoluteURL)).map(pokemonHackSHA1Hex) : nil
        return PatchCreationROMMetadata(
            path: path,
            absolutePath: absoluteURL.path,
            exists: exists,
            sizeBytes: size,
            sha1: sha1
        )
    }

    private static func builtOutputMetadata(
        from target: BuildTargetValidation
    ) -> PatchCreationBuiltOutputMetadata? {
        guard let output = target.output else {
            return nil
        }
        return PatchCreationBuiltOutputMetadata(
            targetID: target.target.id,
            targetName: target.target.name,
            relativePath: output.relativePath,
            absolutePath: output.absolutePath,
            exists: output.exists,
            sizeBytes: output.sizeBytes,
            sha1: output.sha1,
            checksumStatus: output.checksumStatus,
            freshnessStatus: output.freshnessStatus
        )
    }

    private static func diagnosticsForTargetSelection(
        targets: [BuildTargetValidation],
        selectedTarget: BuildTargetValidation?,
        requestedTargetID: String?
    ) -> [Diagnostic] {
        if let requestedTargetID, selectedTarget == nil {
            return [
                Diagnostic(
                    severity: .error,
                    code: "PATCH_CREATION_BUILD_TARGET_NOT_FOUND",
                    message: "Build target \(requestedTargetID) was not found for patch creation preview."
                )
            ]
        }
        guard !targets.isEmpty else {
            return [
                Diagnostic(
                    severity: .error,
                    code: "PATCH_CREATION_BUILD_TARGET_MISSING",
                    message: "No build targets are declared for patch creation preview."
                )
            ]
        }
        if selectedTarget?.target.outputPath == nil {
            return [
                Diagnostic(
                    severity: .error,
                    code: "PATCH_CREATION_BUILD_OUTPUT_NOT_DECLARED",
                    message: "Selected build target does not declare an output path for patch creation preview."
                )
            ]
        }
        return []
    }

    private static func diagnosticsForBaseROM(_ baseROM: PatchCreationROMMetadata) -> [Diagnostic] {
        guard baseROM.exists else {
            return [
                Diagnostic(
                    severity: .error,
                    code: "PATCH_CREATION_BASE_ROM_MISSING",
                    message: "Selected base ROM does not exist at \(baseROM.absolutePath)."
                )
            ]
        }
        guard baseROM.sha1 != nil else {
            return [
                Diagnostic(
                    severity: .error,
                    code: "PATCH_CREATION_BASE_ROM_UNREADABLE",
                    message: "Selected base ROM exists but could not be read for SHA1 at \(baseROM.absolutePath)."
                )
            ]
        }
        return []
    }

    private static func diagnosticsForBuiltOutput(_ builtOutput: PatchCreationBuiltOutputMetadata?) -> [Diagnostic] {
        guard let builtOutput else {
            return []
        }
        guard builtOutput.exists else {
            return [
                Diagnostic(
                    severity: .error,
                    code: "PATCH_CREATION_BUILD_OUTPUT_MISSING",
                    message: "Built output does not exist at \(builtOutput.absolutePath)."
                )
            ]
        }
        guard builtOutput.sha1 != nil else {
            return [
                Diagnostic(
                    severity: .error,
                    code: "PATCH_CREATION_BUILD_OUTPUT_UNREADABLE",
                    message: "Built output exists but could not be read for SHA1 at \(builtOutput.absolutePath)."
                )
            ]
        }
        return []
    }

    private static func plannedPatchRelativePath(
        baseROM: PatchCreationROMMetadata,
        builtOutput: PatchCreationBuiltOutputMetadata?,
        targetID: String?
    ) -> String {
        let baseStem = sanitizedArtifactComponent(
            URL(fileURLWithPath: baseROM.absolutePath).deletingPathExtension().lastPathComponent,
            fallback: "base"
        )
        let outputSource = builtOutput?.relativePath
            ?? targetID
            ?? "built-output"
        let outputStem = sanitizedArtifactComponent(
            URL(fileURLWithPath: outputSource).deletingPathExtension().lastPathComponent,
            fallback: "built-output"
        )
        return ".pokemonhackstudio/patches/\(baseStem)-to-\(outputStem).bps"
    }

    private static func signedDelta(from baseSize: UInt64?, to outputSize: UInt64?) -> Int64? {
        guard let baseSize, let outputSize,
              baseSize <= UInt64(Int64.max),
              outputSize <= UInt64(Int64.max)
        else {
            return nil
        }
        return Int64(outputSize) - Int64(baseSize)
    }

    private static func hashesMatch(_ lhs: String?, _ rhs: String?) -> Bool? {
        guard let lhs, let rhs else {
            return nil
        }
        return lhs.lowercased() == rhs.lowercased()
    }

    private static func resolvedURL(path: String, root: URL, fileManager: FileManager) -> URL {
        if path.hasPrefix("/") {
            return URL(fileURLWithPath: path).standardizedFileURL
        }
        let direct = URL(fileURLWithPath: path).standardizedFileURL
        if fileManager.fileExists(atPath: direct.path) {
            return direct
        }
        return root.appendingPathComponent(path).standardizedFileURL
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

public enum BPSPatchCodecError: Error, LocalizedError, Equatable {
    case malformed(String)
    case checksumMismatch(String)

    public var errorDescription: String? {
        switch self {
        case .malformed(let message), .checksumMismatch(let message):
            return message
        }
    }
}

public enum BPSPatchCodec {
    public static func encode(source: Data, target: Data) -> Data {
        var body = Data("BPS1".utf8)
        body.append(contentsOf: encodeVariableLength(UInt64(source.count)))
        body.append(contentsOf: encodeVariableLength(UInt64(target.count)))
        body.append(contentsOf: encodeVariableLength(0))

        let sourceBytes = Array(source)
        let targetBytes = Array(target)
        var prefixLength = 0
        while prefixLength < min(sourceBytes.count, targetBytes.count),
              sourceBytes[prefixLength] == targetBytes[prefixLength]
        {
            prefixLength += 1
        }

        if prefixLength > 0 {
            body.append(contentsOf: encodeCommand(length: prefixLength, command: 0))
        }
        if prefixLength < targetBytes.count {
            let length = targetBytes.count - prefixLength
            body.append(contentsOf: encodeCommand(length: length, command: 1))
            body.append(contentsOf: targetBytes[prefixLength...])
        }

        appendUInt32LE(pokemonHackCRC32(source), to: &body)
        appendUInt32LE(pokemonHackCRC32(target), to: &body)
        appendUInt32LE(pokemonHackCRC32(body), to: &body)
        return body
    }

    public static func apply(patchData: Data, baseData: Data) throws -> Data {
        let bytes = Array(patchData)
        guard bytes.count >= 4, Data(bytes[0..<4]) == Data("BPS1".utf8) else {
            throw BPSPatchCodecError.malformed("BPS patch header is missing.")
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
            throw BPSPatchCodecError.checksumMismatch("BPS source size \(sourceSize) does not match selected base ROM size \(baseData.count).")
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
                    throw BPSPatchCodecError.malformed("BPS SourceRead exceeds source ROM size.")
                }
                output.append(contentsOf: source[offset..<(offset + length)])
            case 1:
                output.append(contentsOf: try cursor.readBytes(count: length))
            case 2:
                sourceRelativeOffset += try readSignedOffset(cursor: &cursor)
                guard sourceRelativeOffset >= 0, sourceRelativeOffset + length <= source.count else {
                    throw BPSPatchCodecError.malformed("BPS SourceCopy exceeds source ROM size.")
                }
                output.append(contentsOf: source[sourceRelativeOffset..<(sourceRelativeOffset + length)])
                sourceRelativeOffset += length
            case 3:
                targetRelativeOffset += try readSignedOffset(cursor: &cursor)
                guard targetRelativeOffset >= 0 else {
                    throw BPSPatchCodecError.malformed("BPS TargetCopy has a negative target offset.")
                }
                for index in 0..<length {
                    let sourceIndex = targetRelativeOffset + index
                    guard sourceIndex < output.count else {
                        throw BPSPatchCodecError.malformed("BPS TargetCopy references bytes that have not been written.")
                    }
                    output.append(output[sourceIndex])
                }
                targetRelativeOffset += length
            default:
                throw BPSPatchCodecError.malformed("BPS command is invalid.")
            }
        }

        guard output.count == Int(targetSize) else {
            throw BPSPatchCodecError.malformed("BPS output size \(output.count) does not match target size \(targetSize).")
        }
        let outputData = Data(output)
        if hasChecksumTrailer {
            let expectedSourceCRC = readUInt32LE(bytes, offset: bytes.count - 12)
            let expectedTargetCRC = readUInt32LE(bytes, offset: bytes.count - 8)
            let expectedPatchCRC = readUInt32LE(bytes, offset: bytes.count - 4)
            guard pokemonHackCRC32(baseData) == expectedSourceCRC else {
                throw BPSPatchCodecError.checksumMismatch("BPS embedded source CRC32 does not match the selected base ROM.")
            }
            guard pokemonHackCRC32(outputData) == expectedTargetCRC else {
                throw BPSPatchCodecError.checksumMismatch("BPS embedded target CRC32 does not match the exported ROM.")
            }
            guard pokemonHackCRC32(Data(bytes[0..<(bytes.count - 4)])) == expectedPatchCRC else {
                throw BPSPatchCodecError.checksumMismatch("BPS embedded patch CRC32 does not match the patch file.")
            }
        }
        return outputData
    }

    private static func encodeCommand(length: Int, command: UInt64) -> [UInt8] {
        encodeVariableLength(UInt64((length - 1) << 2) | command)
    }

    private static func encodeVariableLength(_ value: UInt64) -> [UInt8] {
        var data = value
        var bytes: [UInt8] = []
        while true {
            let byte = UInt8(data & 0x7F)
            data >>= 7
            if data == 0 {
                bytes.append(byte | 0x80)
                break
            }
            bytes.append(byte)
            data -= 1
        }
        return bytes
    }

    private static func appendUInt32LE(_ value: UInt32, to data: inout Data) {
        data.append(UInt8(value & 0xFF))
        data.append(UInt8((value >> 8) & 0xFF))
        data.append(UInt8((value >> 16) & 0xFF))
        data.append(UInt8((value >> 24) & 0xFF))
    }

    private static func readSignedOffset(cursor: inout ByteCursor) throws -> Int {
        let value = try cursor.readVariableLengthQuantity()
        let magnitude = Int(value >> 1)
        return value & 1 == 0 ? magnitude : -magnitude
    }

    private static func readUInt32LE(_ bytes: [UInt8], offset: Int) -> UInt32 {
        UInt32(bytes[offset])
            | (UInt32(bytes[offset + 1]) << 8)
            | (UInt32(bytes[offset + 2]) << 16)
            | (UInt32(bytes[offset + 3]) << 24)
    }
}

public enum PatchCreationBuilder {
    public static func create(
        projectPath: String,
        baseROMPath: String,
        targetID: String? = nil,
        fileManager: FileManager = .default
    ) throws -> PatchCreationResult {
        let index = try GameAdapterRegistry.index(path: projectPath)
        let root = URL(fileURLWithPath: index.root.path).standardizedFileURL
        let buildReport = BuildValidationReportBuilder.build(
            index: index,
            fileManager: fileManager,
            toolResolver: { ToolAvailability(name: $0, isAvailable: true) }
        )
        let preview = try PatchCreationPreviewBuilder.build(
            projectPath: projectPath,
            baseROMPath: baseROMPath,
            targetID: targetID,
            fileManager: fileManager
        )
        let manifestRelativePath = preview.plannedPatchPath.appending(".manifest.json")
        let patchURL = root.appendingPathComponent(preview.plannedPatchPath).standardizedFileURL
        let manifestURL = root.appendingPathComponent(manifestRelativePath).standardizedFileURL
        var diagnostics = preview.diagnostics.filter { $0.code != "PATCH_CREATION_PREVIEW_ONLY" }

        diagnostics.append(contentsOf: creationSafetyDiagnostics(
            root: root,
            patchRelativePath: preview.plannedPatchPath,
            manifestRelativePath: manifestRelativePath,
            fileManager: fileManager
        ))

        guard preview.candidateFormat == .bps else {
            diagnostics.append(Diagnostic(severity: .error, code: "PATCH_CREATION_FORMAT_UNSUPPORTED", message: "Patch creation currently writes BPS artifacts only."))
            return blockedResult(patchURL: patchURL, manifestURL: manifestURL, diagnostics: diagnostics)
        }
        guard !preview.headerPolicy.shouldRewriteHeader else {
            diagnostics.append(Diagnostic(severity: .error, code: "PATCH_CREATION_HEADER_REWRITE_BLOCKED", message: "Patch creation will not rewrite title, game code, maker code, or header checksum."))
            return blockedResult(patchURL: patchURL, manifestURL: manifestURL, diagnostics: diagnostics)
        }
        if fileManager.fileExists(atPath: patchURL.path) {
            diagnostics.append(Diagnostic(severity: .error, code: "PATCH_CREATION_PATCH_EXISTS", message: "BPS patch output already exists at \(patchURL.path); creation does not overwrite or back up existing patch artifacts."))
        }
        if fileManager.fileExists(atPath: manifestURL.path) {
            diagnostics.append(Diagnostic(severity: .error, code: "PATCH_CREATION_MANIFEST_EXISTS", message: "BPS patch manifest already exists at \(manifestURL.path); creation does not overwrite or back up existing manifests."))
        }

        guard preview.isReady else {
            diagnostics.append(Diagnostic(severity: .error, code: "PATCH_CREATION_NOT_READY", message: "Patch creation requires a readable selected base ROM and an existing readable built output."))
            return blockedResult(patchURL: patchURL, manifestURL: manifestURL, diagnostics: diagnostics)
        }
        guard diagnostics.contains(where: { $0.severity == .error }) == false else {
            return blockedResult(patchURL: patchURL, manifestURL: manifestURL, diagnostics: diagnostics)
        }
        guard let baseSHA1 = preview.baseROM.sha1,
              let builtOutput = preview.builtOutput,
              let builtOutputSHA1 = builtOutput.sha1 else {
            diagnostics.append(Diagnostic(severity: .error, code: "PATCH_CREATION_INPUT_HASH_UNAVAILABLE", message: "Patch creation requires SHA1 metadata for both selected base ROM and built output."))
            return blockedResult(patchURL: patchURL, manifestURL: manifestURL, diagnostics: diagnostics)
        }
        guard let matchedCandidate = matchingBaseCandidate(sha1: baseSHA1, expectations: buildReport.sha1Expectations) else {
            diagnostics.append(Diagnostic(severity: .error, code: "PATCH_CREATION_BASE_ROM_NOT_COMPATIBLE", message: "Patch creation requires the selected base ROM SHA1 to match a declared project SHA1 candidate."))
            return blockedResult(patchURL: patchURL, manifestURL: manifestURL, diagnostics: diagnostics)
        }

        guard let baseData = try? Data(contentsOf: URL(fileURLWithPath: preview.baseROM.absolutePath)) else {
            diagnostics.append(Diagnostic(severity: .error, code: "PATCH_CREATION_BASE_ROM_UNREADABLE", message: "Selected base ROM could not be read immediately before patch creation at \(preview.baseROM.absolutePath)."))
            return blockedResult(patchURL: patchURL, manifestURL: manifestURL, diagnostics: diagnostics)
        }
        guard let builtData = try? Data(contentsOf: URL(fileURLWithPath: builtOutput.absolutePath)) else {
            diagnostics.append(Diagnostic(severity: .error, code: "PATCH_CREATION_BUILD_OUTPUT_UNREADABLE", message: "Built output could not be read immediately before patch creation at \(builtOutput.absolutePath)."))
            return blockedResult(patchURL: patchURL, manifestURL: manifestURL, diagnostics: diagnostics)
        }
        let currentBaseSHA1 = pokemonHackSHA1Hex(baseData)
        let currentBuiltSHA1 = pokemonHackSHA1Hex(builtData)
        guard currentBaseSHA1.caseInsensitiveCompare(baseSHA1) == .orderedSame,
              currentBaseSHA1.caseInsensitiveCompare(matchedCandidate.expectedSHA1 ?? "") == .orderedSame else {
            diagnostics.append(Diagnostic(severity: .error, code: "PATCH_CREATION_BASE_ROM_HASH_CHANGED", message: "Selected base ROM SHA1 changed or no longer matches the declared project candidate."))
            return blockedResult(patchURL: patchURL, manifestURL: manifestURL, diagnostics: diagnostics)
        }
        guard currentBuiltSHA1.caseInsensitiveCompare(builtOutputSHA1) == .orderedSame else {
            diagnostics.append(Diagnostic(severity: .error, code: "PATCH_CREATION_BUILD_OUTPUT_HASH_CHANGED", message: "Built output SHA1 changed after readiness was computed; refresh the preview before creating a patch."))
            return blockedResult(patchURL: patchURL, manifestURL: manifestURL, diagnostics: diagnostics)
        }

        let patchData = BPSPatchCodec.encode(source: baseData, target: builtData)
        if let writeFailure = writePatchArtifact(
            patchData: patchData,
            patchURL: patchURL,
            fileManager: fileManager
        ) {
            return blockedResult(
                patchURL: patchURL,
                manifestURL: manifestURL,
                diagnostics: diagnostics + [writeFailure]
            )
        }

        let writtenPatchData = try? Data(contentsOf: patchURL)
        let patchIdentityData = writtenPatchData ?? patchData
        let patchSHA1 = pokemonHackSHA1Hex(patchIdentityData)
        let verification = writtenPatchData.map {
            verifyCreatedPatch(
                patchData: $0,
                baseData: baseData,
                expectedBuiltData: builtData,
                headerPolicy: preview.headerPolicy
            )
        } ?? unreadablePatchVerification(
            expectedBuiltData: builtData,
            headerPolicy: preview.headerPolicy
        )
        let verificationDiagnostic = diagnostic(for: verification, patchURL: patchURL)
        let writtenDiagnostic = Diagnostic(
            severity: .info,
            code: "PATCH_CREATION_WRITTEN",
            message: "BPS patch was written to \(patchURL.path); manifest written to \(manifestURL.path)."
        )
        let resultDiagnostics = diagnostics + [verificationDiagnostic, writtenDiagnostic]
        let manifest = PatchCreationArtifactManifest(
            schemaVersion: 2,
            action: "patch-create",
            projectRoot: root.path,
            baseROMPath: preview.baseROM.absolutePath,
            baseROMSHA1: currentBaseSHA1,
            baseROMCRC32: pokemonHackCRC32Hex(baseData),
            baseROMSizeBytes: UInt64(baseData.count),
            matchedBaseROMCandidate: matchedCandidate.relativePath,
            builtOutputPath: builtOutput.absolutePath,
            builtOutputRelativePath: builtOutput.relativePath,
            builtOutputTargetID: builtOutput.targetID,
            builtOutputSHA1: currentBuiltSHA1,
            builtOutputCRC32: pokemonHackCRC32Hex(builtData),
            builtOutputSizeBytes: UInt64(builtData.count),
            patchPath: patchURL.path,
            patchSHA1: patchSHA1,
            patchCRC32: pokemonHackCRC32Hex(patchIdentityData),
            patchSizeBytes: UInt64(patchIdentityData.count),
            patchFormat: .bps,
            headerPolicy: preview.headerPolicy,
            verification: verification,
            diagnostics: resultDiagnostics
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let manifestData = try encoder.encode(manifest)
        if let writeFailure = writeManifestArtifact(
            manifestData: manifestData,
            patchURL: patchURL,
            manifestURL: manifestURL,
            fileManager: fileManager
        ) {
            return blockedResult(
                patchURL: patchURL,
                manifestURL: manifestURL,
                diagnostics: diagnostics + [writeFailure]
            )
        }

        return PatchCreationResult(
            status: .created,
            patchPath: patchURL.path,
            manifestPath: manifestURL.path,
            patchSHA1: patchSHA1,
            diagnostics: resultDiagnostics,
            verification: verification,
            manifest: manifest
        )
    }

    static func verifyCreatedPatch(
        patchData: Data,
        baseData: Data,
        expectedBuiltData: Data,
        headerPolicy: PatchArtifactHeaderPolicy
    ) -> PatchCreationVerification {
        let expectedSHA1 = pokemonHackSHA1Hex(expectedBuiltData)
        let expectedCRC32 = pokemonHackCRC32Hex(expectedBuiltData)
        let expectedSize = UInt64(expectedBuiltData.count)
        let headerPolicyMatches = headerPolicy.mode == "no-header-rewrite" && !headerPolicy.shouldRewriteHeader

        guard let appliedData = try? BPSPatchCodec.apply(patchData: patchData, baseData: baseData) else {
            return PatchCreationVerification(
                status: .failed,
                appliedOutputSHA1: nil,
                appliedOutputCRC32: nil,
                appliedOutputSizeBytes: nil,
                expectedBuiltOutputSHA1: expectedSHA1,
                expectedBuiltOutputCRC32: expectedCRC32,
                expectedBuiltOutputSizeBytes: expectedSize,
                sha1Matches: false,
                crc32Matches: false,
                sizeMatches: false,
                headerPolicyMatches: headerPolicyMatches,
                headerPolicy: headerPolicy
            )
        }

        let appliedSHA1 = pokemonHackSHA1Hex(appliedData)
        let appliedCRC32 = pokemonHackCRC32Hex(appliedData)
        let appliedSize = UInt64(appliedData.count)
        let sha1Matches = appliedSHA1.caseInsensitiveCompare(expectedSHA1) == .orderedSame
        let crc32Matches = appliedCRC32.caseInsensitiveCompare(expectedCRC32) == .orderedSame
        let sizeMatches = appliedSize == expectedSize
        let status: PatchCreationVerificationStatus = sha1Matches && crc32Matches && sizeMatches && headerPolicyMatches
            ? .passed
            : .failed

        return PatchCreationVerification(
            status: status,
            appliedOutputSHA1: appliedSHA1,
            appliedOutputCRC32: appliedCRC32,
            appliedOutputSizeBytes: appliedSize,
            expectedBuiltOutputSHA1: expectedSHA1,
            expectedBuiltOutputCRC32: expectedCRC32,
            expectedBuiltOutputSizeBytes: expectedSize,
            sha1Matches: sha1Matches,
            crc32Matches: crc32Matches,
            sizeMatches: sizeMatches,
            headerPolicyMatches: headerPolicyMatches,
            headerPolicy: headerPolicy
        )
    }

    private static func unreadablePatchVerification(
        expectedBuiltData: Data,
        headerPolicy: PatchArtifactHeaderPolicy
    ) -> PatchCreationVerification {
        PatchCreationVerification(
            status: .failed,
            appliedOutputSHA1: nil,
            appliedOutputCRC32: nil,
            appliedOutputSizeBytes: nil,
            expectedBuiltOutputSHA1: pokemonHackSHA1Hex(expectedBuiltData),
            expectedBuiltOutputCRC32: pokemonHackCRC32Hex(expectedBuiltData),
            expectedBuiltOutputSizeBytes: UInt64(expectedBuiltData.count),
            sha1Matches: false,
            crc32Matches: false,
            sizeMatches: false,
            headerPolicyMatches: headerPolicy.mode == "no-header-rewrite" && !headerPolicy.shouldRewriteHeader,
            headerPolicy: headerPolicy
        )
    }

    private static func diagnostic(
        for verification: PatchCreationVerification,
        patchURL: URL
    ) -> Diagnostic {
        switch verification.status {
        case .passed:
            return Diagnostic(
                severity: .info,
                code: "PATCH_CREATION_VERIFICATION_PASSED",
                message: "Re-read BPS patch \(patchURL.path), applied it in memory to the selected base ROM, and verified SHA1, CRC32, size, and no-header-rewrite policy against the built output."
            )
        case .failed:
            return Diagnostic(
                severity: .error,
                code: "PATCH_CREATION_VERIFICATION_FAILED",
                message: "Re-read BPS patch \(patchURL.path), but in-memory verification did not match the built output SHA1, CRC32, size, or no-header-rewrite policy."
            )
        }
    }

    private static func matchingBaseCandidate(
        sha1: String,
        expectations: [SHA1Expectation]
    ) -> SHA1Expectation? {
        expectations.first { expectation in
            guard let expectedSHA1 = expectation.expectedSHA1 else { return false }
            return expectedSHA1.caseInsensitiveCompare(sha1) == .orderedSame
        }
    }

    private static func creationSafetyDiagnostics(
        root: URL,
        patchRelativePath: String,
        manifestRelativePath: String,
        fileManager: FileManager
    ) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        if !patchRelativePath.hasPrefix(".pokemonhackstudio/patches/") || !patchRelativePath.hasSuffix(".bps") {
            diagnostics.append(Diagnostic(severity: .error, code: "PATCH_CREATION_PATCH_PATH_UNSAFE", message: "BPS patch creation must write only ignored .pokemonhackstudio/patches/*.bps artifacts."))
        }
        if !manifestRelativePath.hasPrefix(".pokemonhackstudio/patches/") || !manifestRelativePath.hasSuffix(".bps.manifest.json") {
            diagnostics.append(Diagnostic(severity: .error, code: "PATCH_CREATION_MANIFEST_PATH_UNSAFE", message: "BPS patch creation must write only ignored .pokemonhackstudio/patches/*.bps.manifest.json manifests."))
        }
        diagnostics.append(contentsOf: SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
            patchRelativePath,
            root: root,
            fileManager: fileManager,
            codePrefix: "PATCH_CREATION_PATCH",
            subject: "Patch creation output path"
        ))
        diagnostics.append(contentsOf: SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
            manifestRelativePath,
            root: root,
            fileManager: fileManager,
            codePrefix: "PATCH_CREATION_MANIFEST",
            subject: "Patch creation manifest path"
        ))
        return diagnostics
    }

    private static func writePatchArtifact(
        patchData: Data,
        patchURL: URL,
        fileManager: FileManager
    ) -> Diagnostic? {
        let directory = patchURL.deletingLastPathComponent()
        let patchTempURL = directory.appendingPathComponent(".\(patchURL.lastPathComponent).\(UUID().uuidString).tmp")
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try patchData.write(to: patchTempURL, options: .atomic)
            try fileManager.moveItem(at: patchTempURL, to: patchURL)
            return nil
        } catch {
            try? fileManager.removeItem(at: patchTempURL)
            return Diagnostic(severity: .error, code: "PATCH_CREATION_WRITE_FAILED", message: "BPS patch creation failed while writing ignored artifacts: \(error.localizedDescription)")
        }
    }

    private static func writeManifestArtifact(
        manifestData: Data,
        patchURL: URL,
        manifestURL: URL,
        fileManager: FileManager
    ) -> Diagnostic? {
        let directory = manifestURL.deletingLastPathComponent()
        let manifestTempURL = directory.appendingPathComponent(".\(manifestURL.lastPathComponent).\(UUID().uuidString).tmp")
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try manifestData.write(to: manifestTempURL, options: .atomic)
            try fileManager.moveItem(at: manifestTempURL, to: manifestURL)
            return nil
        } catch {
            try? fileManager.removeItem(at: manifestTempURL)
            try? fileManager.removeItem(at: patchURL)
            return Diagnostic(severity: .error, code: "PATCH_CREATION_WRITE_FAILED", message: "BPS patch creation failed while writing ignored artifacts: \(error.localizedDescription)")
        }
    }

    private static func blockedResult(
        patchURL: URL,
        manifestURL: URL,
        diagnostics: [Diagnostic]
    ) -> PatchCreationResult {
        PatchCreationResult(
            status: .blocked,
            patchPath: patchURL.path,
            manifestPath: manifestURL.path,
            patchSHA1: nil,
            diagnostics: diagnostics,
            manifest: nil
        )
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

        var backupPath: String?
        let artifactRoot = patchArtifactRoot(projectRoot: report.projectRoot, patchPath: patchPath)
        let manifestRelativePath = report.artifactPlan.outputPath.appending(".manifest.json")
        let backupRelativePath = fileManager.fileExists(atPath: outputURL.path)
            ? uniqueBackupRelativePathForExistingOutput(outputFileName: outputURL.lastPathComponent, root: artifactRoot, fileManager: fileManager)
            : nil
        let safetyDiagnostics = patchApplyExportSafetyDiagnostics(
            root: artifactRoot,
            outputRelativePath: report.artifactPlan.outputPath,
            manifestRelativePath: manifestRelativePath,
            backupRelativePath: backupRelativePath,
            fileManager: fileManager
        )
        if !safetyDiagnostics.isEmpty {
            diagnostics.append(contentsOf: safetyDiagnostics)
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

        if fileManager.fileExists(atPath: outputURL.path) {
            let backupRelativePath = backupRelativePath ?? uniqueBackupRelativePathForExistingOutput(
                outputFileName: outputURL.lastPathComponent,
                root: artifactRoot,
                fileManager: fileManager
            )
            let backupURL = artifactRoot.appendingPathComponent(backupRelativePath).standardizedFileURL
            try fileManager.createDirectory(at: backupURL.deletingLastPathComponent(), withIntermediateDirectories: true)
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
        let manifestURL = artifactRoot.appendingPathComponent(manifestRelativePath).standardizedFileURL
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
        try BPSPatchCodec.apply(patchData: patchData, baseData: baseData)
    }

    private static func patchArtifactRoot(projectRoot: String?, patchPath: String) -> URL {
        if let projectRoot {
            return URL(fileURLWithPath: projectRoot).standardizedFileURL
        }
        return URL(fileURLWithPath: patchPath).standardizedFileURL.deletingLastPathComponent()
    }

    private static func patchApplyExportSafetyDiagnostics(
        root: URL,
        outputRelativePath: String,
        manifestRelativePath: String,
        backupRelativePath: String?,
        fileManager: FileManager
    ) -> [Diagnostic] {
        var diagnostics = SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
            outputRelativePath,
            root: root,
            fileManager: fileManager,
            codePrefix: "PATCH_EXPORT_OUTPUT",
            subject: "Patch export output path"
        )
        diagnostics.append(contentsOf: SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
            manifestRelativePath,
            root: root,
            fileManager: fileManager,
            codePrefix: "PATCH_EXPORT_MANIFEST",
            subject: "Patch export manifest path"
        ))
        if let backupRelativePath {
            diagnostics.append(contentsOf: SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
                backupRelativePath,
                root: root,
                fileManager: fileManager,
                codePrefix: "PATCH_EXPORT_BACKUP",
                subject: "Patch export backup path"
            ))
        }
        return diagnostics
    }

    private static func uniqueBackupRelativePathForExistingOutput(
        outputFileName: String,
        root: URL,
        fileManager: FileManager
    ) -> String {
        for _ in 0..<10 {
            let relativePath = ".pokemonhackstudio/backups/\(backupTimestamp())/patches/\(outputFileName)"
            let url = root.appendingPathComponent(relativePath).standardizedFileURL
            if !fileManager.fileExists(atPath: url.path) {
                return relativePath
            }
        }
        return ".pokemonhackstudio/backups/\(backupTimestamp())/patches/\(UUID().uuidString)-\(outputFileName)"
    }

    private static func backupTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        return "\(formatter.string(from: Date()))-\(UUID().uuidString.prefix(8))"
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
        pokemonHackCRC32Hex(data)
    }

    private static func crc32(_ data: Data) -> UInt32 {
        pokemonHackCRC32(data)
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
