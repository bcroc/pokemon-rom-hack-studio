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

public struct PatchManifestReport: Codable, Equatable {
    public let patch: PatchValidationReport
    public let projectRoot: String?
    public let baseROMCandidates: [PatchBaseROMCandidate]
    public let selectedBaseROM: PatchSelectedBaseROM?
    public let compatibilityStatus: PatchManifestCompatibilityStatus
    public let dryRunPlans: [PatchManifestDryRunPlan]
    public let diagnostics: [Diagnostic]

    public init(
        patch: PatchValidationReport,
        projectRoot: String?,
        baseROMCandidates: [PatchBaseROMCandidate],
        selectedBaseROM: PatchSelectedBaseROM? = nil,
        compatibilityStatus: PatchManifestCompatibilityStatus,
        dryRunPlans: [PatchManifestDryRunPlan],
        diagnostics: [Diagnostic]
    ) {
        self.patch = patch
        self.projectRoot = projectRoot
        self.baseROMCandidates = baseROMCandidates
        self.selectedBaseROM = selectedBaseROM
        self.compatibilityStatus = compatibilityStatus
        self.dryRunPlans = dryRunPlans
        self.diagnostics = diagnostics
    }
}

public enum PatchManifestBuilder {
    public static func build(
        patchPath: String,
        projectPath: String? = nil,
        baseROMPath: String? = nil,
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

        let selectedBaseROM = selectedBaseROMReport(
            from: baseROMPath,
            projectRoot: projectRoot,
            candidates: candidates,
            fileManager: fileManager
        )
        diagnostics.append(contentsOf: selectedBaseROMDiagnostics(selectedBaseROM, candidates: candidates))

        let compatibility = compatibilityStatus(patch: patch, selectedBaseROM: selectedBaseROM, candidates: candidates)
        let dryRuns = dryRunPlans(
            patch: patch,
            selectedBaseROM: selectedBaseROM,
            candidates: candidates,
            compatibility: compatibility
        )
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
            selectedBaseROM: selectedBaseROM,
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
        compatibility: PatchManifestCompatibilityStatus
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
}
