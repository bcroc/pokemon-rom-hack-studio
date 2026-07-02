import Foundation

public enum ReferencePathAvailabilityStatus: String, Codable, Equatable, Sendable {
    case available
    case missing
}

public enum ReferenceAliasResolutionStatus: String, Codable, Equatable, Sendable {
    case resolved
    case dangling
    case materialized
}

public enum ReferenceTrackingSource: String, Codable, Equatable, Sendable {
    case git
    case policyFallback
}

public enum ReferenceTrackingStatusValue: String, Codable, Equatable, Sendable {
    case manifestOnly
    case extraTrackedReferences
    case policyOnly
    case policyMissing
}

public struct ReferenceStatusReport: Codable, Equatable, Sendable {
    public let repositories: [ReferenceRepo]
    public let centralReferenceIndex: CentralReferenceIndexStatus
    public let referenceAliases: ReferenceAliasStatusSummary
    public let validationTiersAffected: [ReferenceValidationTierImpact]
    public let tracking: ReferenceTrackingStatus

    public init(
        repositories: [ReferenceRepo],
        centralReferenceIndex: CentralReferenceIndexStatus,
        referenceAliases: ReferenceAliasStatusSummary,
        validationTiersAffected: [ReferenceValidationTierImpact],
        tracking: ReferenceTrackingStatus
    ) {
        self.repositories = repositories
        self.centralReferenceIndex = centralReferenceIndex
        self.referenceAliases = referenceAliases
        self.validationTiersAffected = validationTiersAffected
        self.tracking = tracking
    }
}

public struct CentralReferenceIndexStatus: Codable, Equatable, Sendable {
    public let path: String
    public let exists: Bool
    public let status: ReferencePathAvailabilityStatus

    public init(path: String, exists: Bool) {
        self.path = path
        self.exists = exists
        self.status = exists ? .available : .missing
    }
}

public struct ReferenceAliasStatusSummary: Codable, Equatable, Sendable {
    public let rootPath: String
    public let ignoredByPolicy: Bool
    public let totalCount: Int
    public let resolvedCount: Int
    public let danglingCount: Int
    public let materializedCount: Int
    public let aliases: [ReferenceAliasStatus]

    public init(rootPath: String, ignoredByPolicy: Bool, aliases: [ReferenceAliasStatus]) {
        self.rootPath = rootPath
        self.ignoredByPolicy = ignoredByPolicy
        self.totalCount = aliases.count
        self.resolvedCount = aliases.filter { $0.status == .resolved }.count
        self.danglingCount = aliases.filter { $0.status == .dangling }.count
        self.materializedCount = aliases.filter { $0.status == .materialized }.count
        self.aliases = aliases
    }
}

public struct ReferenceAliasStatus: Codable, Equatable, Sendable {
    public let name: String
    public let path: String
    public let isSymlink: Bool
    public let symlinkTarget: String?
    public let resolvedPath: String
    public let exists: Bool
    public let status: ReferenceAliasResolutionStatus
    public let ignoredByPolicy: Bool

    public init(
        name: String,
        path: String,
        isSymlink: Bool,
        symlinkTarget: String?,
        resolvedPath: String,
        exists: Bool,
        status: ReferenceAliasResolutionStatus,
        ignoredByPolicy: Bool
    ) {
        self.name = name
        self.path = path
        self.isSymlink = isSymlink
        self.symlinkTarget = symlinkTarget
        self.resolvedPath = resolvedPath
        self.exists = exists
        self.status = status
        self.ignoredByPolicy = ignoredByPolicy
    }
}

public struct ReferenceValidationTierImpact: Codable, Equatable, Sendable {
    public let tier: ValidationTier
    public let title: String
    public let command: String
    public let strictnessTitle: String
    public let affectedReferenceCauses: [ReferenceValidationCauseAvailability]

    public init(row: ValidationTierCommandRow, workspaceRoot: URL, fileManager: FileManager) {
        self.tier = row.tier
        self.title = row.title
        self.command = row.command
        self.strictnessTitle = row.strictnessTitle
        self.affectedReferenceCauses = row.skippedReferenceCauses.map {
            ReferenceValidationCauseAvailability(
                cause: $0,
                workspaceRoot: workspaceRoot,
                fileManager: fileManager
            )
        }
    }
}

public struct ReferenceValidationCauseAvailability: Codable, Equatable, Sendable {
    public let id: String
    public let label: String
    public let defaultPath: String
    public let resolvedPath: String
    public let exists: Bool
    public let behavior: ValidationReferenceAvailabilityBehavior
    public let overrideEnvironmentVariables: [String]
    public let detail: String

    public init(
        cause: ValidationSkippedReferenceCause,
        workspaceRoot: URL,
        fileManager: FileManager
    ) {
        let resolvedURL = Self.resolvedURL(for: cause.defaultPath, workspaceRoot: workspaceRoot)
        self.id = cause.id
        self.label = cause.label
        self.defaultPath = cause.defaultPath
        self.resolvedPath = resolvedURL.path
        self.exists = fileManager.fileExists(atPath: resolvedURL.path)
        self.behavior = cause.behavior
        self.overrideEnvironmentVariables = cause.overrideEnvironmentVariables
        self.detail = cause.detail
    }

    private static func resolvedURL(for path: String, workspaceRoot: URL) -> URL {
        if path.hasPrefix("/") {
            return URL(fileURLWithPath: path).standardizedFileURL
        }
        return workspaceRoot.appendingPathComponent(path).standardizedFileURL
    }
}

public struct ReferenceTrackingStatus: Codable, Equatable, Sendable {
    public let ignoredPattern: String
    public let manifestExceptionPattern: String
    public let ignorePolicyPresent: Bool
    public let source: ReferenceTrackingSource
    public let gitTrackedPathsAvailable: Bool
    public let trackedPaths: [String]
    public let onlyReferencesManifestTracked: Bool
    public let status: ReferenceTrackingStatusValue
    public let errorMessage: String?

    public init(
        ignorePolicyPresent: Bool,
        gitProbe: ReferenceGitTrackingProbe
    ) {
        self.ignoredPattern = "/references/*"
        self.manifestExceptionPattern = "!/references/manifest.json"
        self.ignorePolicyPresent = ignorePolicyPresent
        self.gitTrackedPathsAvailable = gitProbe.isAvailable
        self.trackedPaths = gitProbe.trackedPaths.sorted()
        self.errorMessage = gitProbe.errorMessage

        if gitProbe.isAvailable {
            self.source = .git
            self.onlyReferencesManifestTracked = trackedPaths == ["references/manifest.json"]
            self.status = onlyReferencesManifestTracked ? .manifestOnly : .extraTrackedReferences
        } else {
            self.source = .policyFallback
            self.onlyReferencesManifestTracked = ignorePolicyPresent
            self.status = ignorePolicyPresent ? .policyOnly : .policyMissing
        }
    }
}

public struct ReferenceGitTrackingProbe: Codable, Equatable, Sendable {
    public let isAvailable: Bool
    public let trackedPaths: [String]
    public let errorMessage: String?

    public init(isAvailable: Bool, trackedPaths: [String], errorMessage: String? = nil) {
        self.isAvailable = isAvailable
        self.trackedPaths = trackedPaths
        self.errorMessage = errorMessage
    }
}

public enum ReferenceStatusReportBuilder {
    public static let defaultCentralReferenceIndexPath = "/Users/bryan/projects/reference-repos/docs/index.json"

    public static func build(
        from startPath: String = FileManager.default.currentDirectoryPath,
        centralReferenceIndexPath: String = defaultCentralReferenceIndexPath,
        fileManager: FileManager = .default,
        gitProbe: ReferenceGitTrackingProbe? = nil
    ) throws -> ReferenceStatusReport {
        let start = URL(fileURLWithPath: startPath).standardizedFileURL
        let manifestURL = try resolvedManifestURL(startingAt: start, fileManager: fileManager)
        let workspaceRoot = manifestURL.deletingLastPathComponent().deletingLastPathComponent().standardizedFileURL
        let manifest = try ReferenceManifestLoader.load(from: startPath, fileManager: fileManager)
        let ignorePolicyPresent = hasReferenceIgnorePolicy(workspaceRoot: workspaceRoot, fileManager: fileManager)
        let aliases = referenceAliases(
            workspaceRoot: workspaceRoot,
            ignoredByPolicy: ignorePolicyPresent,
            fileManager: fileManager
        )
        let probe = gitProbe ?? gitTrackedReferencePaths(workspaceRoot: workspaceRoot)
        let validationImpacts = ValidationTier.allCases
            .map(ValidationTierCommandRow.init(tier:))
            .filter { !$0.skippedReferenceCauses.isEmpty }
            .map {
                ReferenceValidationTierImpact(
                    row: $0,
                    workspaceRoot: workspaceRoot,
                    fileManager: fileManager
                )
            }

        let centralIndexURL = URL(fileURLWithPath: centralReferenceIndexPath).standardizedFileURL
        return ReferenceStatusReport(
            repositories: manifest.repositories,
            centralReferenceIndex: CentralReferenceIndexStatus(
                path: centralIndexURL.path,
                exists: fileManager.fileExists(atPath: centralIndexURL.path)
            ),
            referenceAliases: ReferenceAliasStatusSummary(
                rootPath: workspaceRoot.appendingPathComponent("references").path,
                ignoredByPolicy: ignorePolicyPresent,
                aliases: aliases
            ),
            validationTiersAffected: validationImpacts,
            tracking: ReferenceTrackingStatus(
                ignorePolicyPresent: ignorePolicyPresent,
                gitProbe: probe
            )
        )
    }

    private static func resolvedManifestURL(startingAt start: URL, fileManager: FileManager) throws -> URL {
        let candidates = ReferenceManifestLoader.manifestCandidates(startingAt: start)
        for candidate in candidates where fileManager.fileExists(atPath: candidate.path) {
            return candidate
        }
        throw PokemonHackCoreError.referenceManifestNotFound(candidates.map(\.path))
    }

    private static func referenceAliases(
        workspaceRoot: URL,
        ignoredByPolicy: Bool,
        fileManager: FileManager
    ) -> [ReferenceAliasStatus] {
        let referencesRoot = workspaceRoot.appendingPathComponent("references").standardizedFileURL
        guard let contents = try? fileManager.contentsOfDirectory(
            at: referencesRoot,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return contents
            .filter { $0.lastPathComponent != "manifest.json" }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            .map { aliasStatus(for: $0, workspaceRoot: workspaceRoot, ignoredByPolicy: ignoredByPolicy, fileManager: fileManager) }
    }

    private static func aliasStatus(
        for url: URL,
        workspaceRoot: URL,
        ignoredByPolicy: Bool,
        fileManager: FileManager
    ) -> ReferenceAliasStatus {
        let relativePath = relativePath(for: url, workspaceRoot: workspaceRoot)
        if let target = try? fileManager.destinationOfSymbolicLink(atPath: url.path) {
            let resolvedURL = resolvedSymlinkTarget(target, from: url)
            let exists = fileManager.fileExists(atPath: resolvedURL.path)
            return ReferenceAliasStatus(
                name: url.lastPathComponent,
                path: relativePath,
                isSymlink: true,
                symlinkTarget: target,
                resolvedPath: resolvedURL.path,
                exists: exists,
                status: exists ? .resolved : .dangling,
                ignoredByPolicy: ignoredByPolicy
            )
        }

        let exists = fileManager.fileExists(atPath: url.path)
        return ReferenceAliasStatus(
            name: url.lastPathComponent,
            path: relativePath,
            isSymlink: false,
            symlinkTarget: nil,
            resolvedPath: url.standardizedFileURL.path,
            exists: exists,
            status: .materialized,
            ignoredByPolicy: ignoredByPolicy
        )
    }

    private static func resolvedSymlinkTarget(_ target: String, from aliasURL: URL) -> URL {
        if target.hasPrefix("/") {
            return URL(fileURLWithPath: target).standardizedFileURL
        }
        return aliasURL
            .deletingLastPathComponent()
            .appendingPathComponent(target)
            .standardizedFileURL
    }

    private static func hasReferenceIgnorePolicy(workspaceRoot: URL, fileManager: FileManager) -> Bool {
        let gitignoreURL = workspaceRoot.appendingPathComponent(".gitignore")
        guard let text = try? String(contentsOf: gitignoreURL, encoding: .utf8) else {
            return false
        }
        let lines = Set(text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) })
        return lines.contains("/references/*") && lines.contains("!/references/manifest.json")
    }

    private static func relativePath(for url: URL, workspaceRoot: URL) -> String {
        let path = url.standardizedFileURL.path
        let rootPath = workspaceRoot.standardizedFileURL.path
        guard path.hasPrefix(rootPath + "/") else {
            return path
        }
        return String(path.dropFirst(rootPath.count + 1))
    }

    private static func gitTrackedReferencePaths(workspaceRoot: URL) -> ReferenceGitTrackingProbe {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git", "-C", workspaceRoot.path, "ls-files", "references"]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ReferenceGitTrackingProbe(
                isAvailable: false,
                trackedPaths: [],
                errorMessage: error.localizedDescription
            )
        }

        let stdoutData = stdout.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderr.fileHandleForReading.readDataToEndOfFile()
        if process.terminationStatus != 0 {
            let message = String(decoding: stderrData, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return ReferenceGitTrackingProbe(
                isAvailable: false,
                trackedPaths: [],
                errorMessage: message.isEmpty ? "git ls-files references failed." : message
            )
        }

        let paths = String(decoding: stdoutData, as: UTF8.self)
            .split(separator: "\n")
            .map(String.init)
            .sorted()
        return ReferenceGitTrackingProbe(isAvailable: true, trackedPaths: paths)
    }
}
