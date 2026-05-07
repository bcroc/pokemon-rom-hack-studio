import Foundation

public enum PatchManifestCompatibilityStatus: String, Codable, Equatable {
    case compatible
    case needsBaseROM
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

public struct PatchManifestReport: Codable, Equatable {
    public let patch: PatchValidationReport
    public let projectRoot: String?
    public let baseROMCandidates: [PatchBaseROMCandidate]
    public let compatibilityStatus: PatchManifestCompatibilityStatus
    public let dryRunPlans: [PatchManifestDryRunPlan]
    public let diagnostics: [Diagnostic]

    public init(
        patch: PatchValidationReport,
        projectRoot: String?,
        baseROMCandidates: [PatchBaseROMCandidate],
        compatibilityStatus: PatchManifestCompatibilityStatus,
        dryRunPlans: [PatchManifestDryRunPlan],
        diagnostics: [Diagnostic]
    ) {
        self.patch = patch
        self.projectRoot = projectRoot
        self.baseROMCandidates = baseROMCandidates
        self.compatibilityStatus = compatibilityStatus
        self.dryRunPlans = dryRunPlans
        self.diagnostics = diagnostics
    }
}

public enum PatchManifestBuilder {
    public static func build(
        patchPath: String,
        projectPath: String? = nil,
        fileManager: FileManager = .default
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

        let compatibility = compatibilityStatus(patch: patch, candidates: candidates)
        let dryRuns = dryRunPlans(patch: patch, candidates: candidates, compatibility: compatibility)
        diagnostics.append(
            Diagnostic(
                severity: .info,
                code: "PATCH_MANIFEST_PLAN_ONLY",
                message: "Patch manifests model base ROM compatibility and dry-run steps without applying or creating patches."
            )
        )

        return PatchManifestReport(
            patch: patch,
            projectRoot: projectRoot,
            baseROMCandidates: candidates,
            compatibilityStatus: compatibility,
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
        candidates: [PatchBaseROMCandidate]
    ) -> PatchManifestCompatibilityStatus {
        guard patch.isValid else { return .invalidPatch }
        if patch.summary?.hasEmbeddedChecksums == true {
            return candidates.isEmpty ? .unknown : .compatible
        }
        return candidates.isEmpty ? .needsBaseROM : .unknown
    }

    private static func dryRunPlans(
        patch: PatchValidationReport,
        candidates: [PatchBaseROMCandidate],
        compatibility: PatchManifestCompatibilityStatus
    ) -> [PatchManifestDryRunPlan] {
        [
            PatchManifestDryRunPlan(
                id: "verify",
                title: "Verify patch metadata",
                steps: [
                    "Read patch header and format.",
                    "Report embedded checksum availability.",
                    "Compare against known base ROM checksum candidates when supplied."
                ],
                diagnostics: patch.diagnostics
            ),
            PatchManifestDryRunPlan(
                id: "apply",
                title: "Plan patch apply",
                steps: [
                    "Select a user-provided base ROM.",
                    "Check base ROM SHA1 against \(candidates.count) candidate(s).",
                    "Write patched output only after an explicit export action."
                ],
                diagnostics: compatibility == .invalidPatch ? patch.diagnostics : []
            )
        ]
    }
}
