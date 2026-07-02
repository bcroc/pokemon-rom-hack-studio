import Foundation

public enum ROMMutationArtifactLibraryItemStatus: String, Codable, Equatable {
    case valid
    case warning
    case error
}

public enum ROMMutationArtifactLibraryManifestStatus: String, Codable, Equatable {
    case matched
    case unreadable
    case mismatched
}

public enum ROMMutationArtifactLibraryCheckStatus: String, Codable, Equatable {
    case matched
    case mismatched
    case missing
    case unreadable
    case unavailable
}

public struct ROMMutationArtifactLibraryFileIdentity: Codable, Equatable {
    public let path: String
    public let exists: Bool
    public let sizeBytes: UInt64?
    public let sha1: String?
    public let crc32: String?

    public init(
        path: String,
        exists: Bool,
        sizeBytes: UInt64? = nil,
        sha1: String? = nil,
        crc32: String? = nil
    ) {
        self.path = path
        self.exists = exists
        self.sizeBytes = sizeBytes
        self.sha1 = sha1
        self.crc32 = crc32
    }
}

public struct ROMMutationArtifactLibraryConfirmationSummary: Codable, Equatable {
    public let method: String
    public let dryRunManifestPath: String
    public let dryRunManifestSHA1: String
    public let hasReviewToken: Bool
    public let reviewTokenSuffix: String?

    public init(
        method: String,
        dryRunManifestPath: String,
        dryRunManifestSHA1: String,
        hasReviewToken: Bool,
        reviewTokenSuffix: String?
    ) {
        self.method = method
        self.dryRunManifestPath = dryRunManifestPath
        self.dryRunManifestSHA1 = dryRunManifestSHA1
        self.hasReviewToken = hasReviewToken
        self.reviewTokenSuffix = reviewTokenSuffix
    }
}

public struct ROMMutationArtifactLibraryItem: Codable, Equatable, Identifiable {
    public let id: String
    public let relativeApplyManifestPath: String
    public let applyManifestPath: String
    public let manifestIdentity: ROMMutationArtifactLibraryFileIdentity
    public let manifestStatus: ROMMutationArtifactLibraryManifestStatus
    public let operationKind: String?
    public let recordedInputPath: String?
    public let recordedBackupPath: String?
    public let relativeBackupPath: String?
    public let backupIdentity: ROMMutationArtifactLibraryFileIdentity?
    public let backupStatus: ROMMutationArtifactLibraryCheckStatus
    public let baseBefore: BinaryROMMutationBaseIdentity?
    public let baseAfter: BinaryROMMutationBaseIdentity?
    public let replacementCount: Int
    public let confirmation: ROMMutationArtifactLibraryConfirmationSummary?
    public let verificationSummary: String
    public let status: ROMMutationArtifactLibraryItemStatus
    public let diagnostics: [Diagnostic]

    public init(
        id: String,
        relativeApplyManifestPath: String,
        applyManifestPath: String,
        manifestIdentity: ROMMutationArtifactLibraryFileIdentity,
        manifestStatus: ROMMutationArtifactLibraryManifestStatus,
        operationKind: String?,
        recordedInputPath: String?,
        recordedBackupPath: String?,
        relativeBackupPath: String?,
        backupIdentity: ROMMutationArtifactLibraryFileIdentity?,
        backupStatus: ROMMutationArtifactLibraryCheckStatus,
        baseBefore: BinaryROMMutationBaseIdentity?,
        baseAfter: BinaryROMMutationBaseIdentity?,
        replacementCount: Int,
        confirmation: ROMMutationArtifactLibraryConfirmationSummary?,
        verificationSummary: String,
        status: ROMMutationArtifactLibraryItemStatus,
        diagnostics: [Diagnostic]
    ) {
        self.id = id
        self.relativeApplyManifestPath = relativeApplyManifestPath
        self.applyManifestPath = applyManifestPath
        self.manifestIdentity = manifestIdentity
        self.manifestStatus = manifestStatus
        self.operationKind = operationKind
        self.recordedInputPath = recordedInputPath
        self.recordedBackupPath = recordedBackupPath
        self.relativeBackupPath = relativeBackupPath
        self.backupIdentity = backupIdentity
        self.backupStatus = backupStatus
        self.baseBefore = baseBefore
        self.baseAfter = baseAfter
        self.replacementCount = replacementCount
        self.confirmation = confirmation
        self.verificationSummary = verificationSummary
        self.status = status
        self.diagnostics = diagnostics
    }
}

public struct ROMMutationArtifactLibrary: Codable, Equatable {
    public let schemaVersion: Int
    public let workspaceRoot: String
    public let artifactRoot: String
    public let relativeArtifactRoot: String
    public let items: [ROMMutationArtifactLibraryItem]
    public let blockedActions: [String]
    public let diagnostics: [Diagnostic]
    public let isReadOnly: Bool

    public init(
        workspaceRoot: String,
        artifactRoot: String,
        relativeArtifactRoot: String,
        items: [ROMMutationArtifactLibraryItem],
        blockedActions: [String],
        diagnostics: [Diagnostic],
        isReadOnly: Bool
    ) {
        schemaVersion = 1
        self.workspaceRoot = workspaceRoot
        self.artifactRoot = artifactRoot
        self.relativeArtifactRoot = relativeArtifactRoot
        self.items = items
        self.blockedActions = blockedActions
        self.diagnostics = diagnostics
        self.isReadOnly = isReadOnly
    }
}

public enum ROMMutationArtifactLibraryScanner {
    public static func scan(
        workspaceRoot: String,
        fileManager: FileManager = .default
    ) -> ROMMutationArtifactLibrary {
        let workspaceURL = URL(fileURLWithPath: workspaceRoot).standardizedFileURL
        let relativeArtifactRoot = ".pokemonhackstudio/rom-mutations"
        let artifactRoot = workspaceURL.appendingPathComponent(relativeArtifactRoot).standardizedFileURL
        let resolvedWorkspace = workspaceURL.resolvingSymlinksInPath().standardizedFileURL
        let resolvedArtifactRoot = artifactRoot.resolvingSymlinksInPath().standardizedFileURL
        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: artifactRoot.path, isDirectory: &isDirectory) else {
            return library(
                workspaceRoot: workspaceURL,
                artifactRoot: artifactRoot,
                relativeArtifactRoot: relativeArtifactRoot,
                items: [],
                diagnostics: [
                    diagnostic(
                        .info,
                        "ROM_MUTATION_ARTIFACT_LIBRARY_EMPTY",
                        "No ignored ROM mutation apply manifests were found under \(relativeArtifactRoot).",
                        relativeArtifactRoot
                    ),
                    readOnlyDiagnostic(relativeArtifactRoot)
                ]
            )
        }

        guard isDirectory.boolValue else {
            return library(
                workspaceRoot: workspaceURL,
                artifactRoot: artifactRoot,
                relativeArtifactRoot: relativeArtifactRoot,
                items: [],
                diagnostics: [
                    diagnostic(
                        .error,
                        "ROM_MUTATION_ARTIFACT_LIBRARY_ROOT_NOT_DIRECTORY",
                        "ROM mutation artifact library root exists but is not a directory: \(artifactRoot.path).",
                        relativeArtifactRoot
                    ),
                    readOnlyDiagnostic(relativeArtifactRoot)
                ]
            )
        }

        guard isContained(resolvedArtifactRoot, in: resolvedWorkspace) else {
            return library(
                workspaceRoot: workspaceURL,
                artifactRoot: artifactRoot,
                relativeArtifactRoot: relativeArtifactRoot,
                items: [],
                diagnostics: [
                    diagnostic(
                        .error,
                        "ROM_MUTATION_ARTIFACT_LIBRARY_ROOT_SYMLINK_OUTSIDE_WORKSPACE",
                        "ROM mutation artifact library root resolves outside the selected workspace; no manifests or backups were read.",
                        relativeArtifactRoot
                    ),
                    readOnlyDiagnostic(relativeArtifactRoot)
                ]
            )
        }

        let scanResult = applyManifestURLs(
            under: artifactRoot,
            resolvedArtifactRoot: resolvedArtifactRoot,
            workspaceRoot: workspaceURL,
            resolvedWorkspace: resolvedWorkspace,
            fileManager: fileManager
        )
        let items = scanResult.urls.map {
            item(
                for: $0,
                workspaceRoot: workspaceURL,
                artifactRoot: artifactRoot,
                resolvedWorkspace: resolvedWorkspace,
                resolvedArtifactRoot: resolvedArtifactRoot,
                fileManager: fileManager
            )
        }
        var diagnostics = scanResult.diagnostics + [readOnlyDiagnostic(relativeArtifactRoot)]
        if items.isEmpty {
            diagnostics.append(
                diagnostic(
                    .info,
                    "ROM_MUTATION_ARTIFACT_LIBRARY_EMPTY",
                    "No ignored ROM mutation apply manifests were found under \(relativeArtifactRoot).",
                    relativeArtifactRoot
                )
            )
        }

        return library(
            workspaceRoot: workspaceURL,
            artifactRoot: artifactRoot,
            relativeArtifactRoot: relativeArtifactRoot,
            items: items,
            diagnostics: diagnostics
        )
    }

    private static func library(
        workspaceRoot: URL,
        artifactRoot: URL,
        relativeArtifactRoot: String,
        items: [ROMMutationArtifactLibraryItem],
        diagnostics: [Diagnostic]
    ) -> ROMMutationArtifactLibrary {
        ROMMutationArtifactLibrary(
            workspaceRoot: workspaceRoot.path,
            artifactRoot: artifactRoot.path,
            relativeArtifactRoot: relativeArtifactRoot,
            items: items,
            blockedActions: blockedActions,
            diagnostics: diagnostics,
            isReadOnly: true
        )
    }

    private struct ManifestURLScanResult {
        let urls: [URL]
        let diagnostics: [Diagnostic]
    }

    private static func applyManifestURLs(
        under artifactRoot: URL,
        resolvedArtifactRoot: URL,
        workspaceRoot: URL,
        resolvedWorkspace: URL,
        fileManager: FileManager
    ) -> ManifestURLScanResult {
        guard let enumerator = fileManager.enumerator(
            at: artifactRoot,
            includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        ) else {
            return ManifestURLScanResult(
                urls: [],
                diagnostics: [
                    diagnostic(
                        .error,
                        "ROM_MUTATION_ARTIFACT_LIBRARY_READ_FAILED",
                        "ROM mutation artifact library could not be enumerated.",
                        relativePath(for: artifactRoot, root: workspaceRoot)
                    )
                ]
            )
        }

        var urls: [URL] = []
        var diagnostics: [Diagnostic] = []
        for case let url as URL in enumerator {
            guard url.lastPathComponent == "apply-manifest.json" else {
                continue
            }
            let standardizedURL = url.standardizedFileURL
            let relativePath = relativePath(for: standardizedURL, root: workspaceRoot)

            guard let values = try? standardizedURL.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey]) else {
                diagnostics.append(
                    diagnostic(
                        .warning,
                        "ROM_MUTATION_ARTIFACT_LIBRARY_MANIFEST_RESOURCE_UNREADABLE",
                        "Apply manifest resource values could not be read; the manifest was skipped.",
                        relativePath
                    )
                )
                continue
            }
            guard values.isRegularFile == true, values.isSymbolicLink != true else {
                diagnostics.append(
                    diagnostic(
                        .warning,
                        "ROM_MUTATION_ARTIFACT_LIBRARY_MANIFEST_NOT_REGULAR_FILE",
                        "Apply manifest path is not a regular file or is a symlink; the manifest was skipped.",
                        relativePath
                    )
                )
                continue
            }

            let resolvedURL = standardizedURL.resolvingSymlinksInPath().standardizedFileURL
            guard isContained(standardizedURL, in: artifactRoot),
                  isContained(resolvedURL, in: resolvedArtifactRoot),
                  isContained(resolvedURL, in: resolvedWorkspace)
            else {
                diagnostics.append(
                    diagnostic(
                        .warning,
                        "ROM_MUTATION_ARTIFACT_LIBRARY_MANIFEST_PATH_OUTSIDE_WORKSPACE",
                        "Apply manifest resolves outside the selected workspace or ROM mutation artifact root; the manifest was skipped.",
                        relativePath
                    )
                )
                continue
            }
            urls.append(standardizedURL)
        }

        return ManifestURLScanResult(
            urls: urls.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending },
            diagnostics: diagnostics
        )
    }

    private static func item(
        for manifestURL: URL,
        workspaceRoot: URL,
        artifactRoot: URL,
        resolvedWorkspace: URL,
        resolvedArtifactRoot: URL,
        fileManager: FileManager
    ) -> ROMMutationArtifactLibraryItem {
        let relativeManifestPath = relativePath(for: manifestURL, root: workspaceRoot)
        let manifestIdentity = fileIdentity(path: manifestURL.path, fileManager: fileManager)
        var diagnostics: [Diagnostic] = []

        let manifest: BinaryROMMutationApplyManifest?
        var manifestStatus: ROMMutationArtifactLibraryManifestStatus = .matched
        do {
            let data = try Data(contentsOf: manifestURL)
            manifest = try JSONDecoder().decode(BinaryROMMutationApplyManifest.self, from: data)
        } catch {
            manifest = nil
            manifestStatus = .unreadable
            diagnostics.append(
                diagnostic(
                    .warning,
                    "ROM_MUTATION_ARTIFACT_LIBRARY_MANIFEST_UNREADABLE",
                    "Apply manifest could not be decoded: \(error.localizedDescription)",
                    relativeManifestPath
                )
            )
        }

        if let manifest, manifest.operationKind != "replaceBytesInPlace" {
            manifestStatus = .mismatched
            diagnostics.append(
                diagnostic(
                    .warning,
                    "ROM_MUTATION_ARTIFACT_LIBRARY_OPERATION_KIND_MISMATCH",
                    "Apply manifest operation kind is \(manifest.operationKind), not replaceBytesInPlace.",
                    relativeManifestPath
                )
            )
        }

        let backupReview = manifest.map {
            backupIdentity(
                for: $0,
                relativeManifestPath: relativeManifestPath,
                workspaceRoot: workspaceRoot,
                artifactRoot: artifactRoot,
                resolvedWorkspace: resolvedWorkspace,
                resolvedArtifactRoot: resolvedArtifactRoot,
                fileManager: fileManager
            )
        }
        if let backupDiagnostics = backupReview?.diagnostics {
            diagnostics.append(contentsOf: backupDiagnostics)
        }

        let backupStatus = backupReview?.status ?? .unavailable
        let status = itemStatus(
            diagnostics: diagnostics,
            manifestStatus: manifestStatus,
            backupStatus: backupStatus
        )

        return ROMMutationArtifactLibraryItem(
            id: manifestURL.path,
            relativeApplyManifestPath: relativeManifestPath,
            applyManifestPath: manifestURL.path,
            manifestIdentity: manifestIdentity,
            manifestStatus: manifestStatus,
            operationKind: manifest?.operationKind,
            recordedInputPath: manifest?.inputPath,
            recordedBackupPath: manifest?.backupPath,
            relativeBackupPath: backupReview?.relativePath,
            backupIdentity: backupReview?.identity,
            backupStatus: backupStatus,
            baseBefore: manifest?.baseBefore,
            baseAfter: manifest?.baseAfter,
            replacementCount: manifest?.replacements.count ?? 0,
            confirmation: manifest.map(confirmationSummary(from:)),
            verificationSummary: verificationSummary(
                status: status,
                manifestStatus: manifestStatus,
                backupStatus: backupStatus,
                replacementCount: manifest?.replacements.count ?? 0
            ),
            status: status,
            diagnostics: diagnostics
        )
    }

    private struct BackupIdentityResult {
        let identity: ROMMutationArtifactLibraryFileIdentity?
        let relativePath: String?
        let status: ROMMutationArtifactLibraryCheckStatus
        let diagnostics: [Diagnostic]
    }

    private static func backupIdentity(
        for manifest: BinaryROMMutationApplyManifest,
        relativeManifestPath: String,
        workspaceRoot: URL,
        artifactRoot: URL,
        resolvedWorkspace: URL,
        resolvedArtifactRoot: URL,
        fileManager: FileManager
    ) -> BackupIdentityResult {
        let backupURL = URL(fileURLWithPath: manifest.backupPath).standardizedFileURL
        let relativeBackupPath = relativePath(for: backupURL, root: workspaceRoot)
        let resolvedBackupURL = backupURL.resolvingSymlinksInPath().standardizedFileURL
        guard isContained(backupURL, in: workspaceRoot),
              isContained(backupURL, in: artifactRoot),
              isContained(resolvedBackupURL, in: resolvedWorkspace),
              isContained(resolvedBackupURL, in: resolvedArtifactRoot)
        else {
            return BackupIdentityResult(
                identity: ROMMutationArtifactLibraryFileIdentity(path: backupURL.path, exists: false),
                relativePath: relativeBackupPath,
                status: .unavailable,
                diagnostics: [
                    diagnostic(
                        .warning,
                        "ROM_MUTATION_ARTIFACT_LIBRARY_BACKUP_PATH_OUTSIDE_ARTIFACT_ROOT",
                        "Backup recorded in the apply manifest is outside the selected workspace ROM mutation artifact root or resolves through a symlink outside it; the library did not read \(backupURL.path).",
                        relativeManifestPath
                    )
                ]
            )
        }

        guard fileManager.fileExists(atPath: backupURL.path) else {
            return BackupIdentityResult(
                identity: ROMMutationArtifactLibraryFileIdentity(path: backupURL.path, exists: false),
                relativePath: relativeBackupPath,
                status: .missing,
                diagnostics: [
                    diagnostic(
                        .warning,
                        "ROM_MUTATION_ARTIFACT_LIBRARY_BACKUP_MISSING",
                        "Backup recorded in the apply manifest is missing at \(backupURL.path).",
                        relativeManifestPath
                    )
                ]
            )
        }

        guard (try? backupURL.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])).map({
            $0.isRegularFile == true && $0.isSymbolicLink != true
        }) == true else {
            return BackupIdentityResult(
                identity: ROMMutationArtifactLibraryFileIdentity(path: backupURL.path, exists: true),
                relativePath: relativeBackupPath,
                status: .unreadable,
                diagnostics: [
                    diagnostic(
                        .warning,
                        "ROM_MUTATION_ARTIFACT_LIBRARY_BACKUP_NOT_REGULAR_FILE",
                        "Backup recorded in the apply manifest is not a regular file or is a symlink; the library did not hash it.",
                        relativeManifestPath
                    )
                ]
            )
        }

        let identity = fileIdentity(path: backupURL.path, fileManager: fileManager)
        let status = checkStatus(
            actual: identity,
            expectedSHA1: manifest.baseBefore.sha1,
            expectedCRC32: manifest.baseBefore.crc32,
            expectedSizeBytes: manifest.baseBefore.sizeBytes
        )
        let diagnostics: [Diagnostic]
        switch status {
        case .matched, .unavailable:
            diagnostics = []
        case .missing:
            diagnostics = [
                diagnostic(
                    .warning,
                    "ROM_MUTATION_ARTIFACT_LIBRARY_BACKUP_MISSING",
                    "Backup recorded in the apply manifest is missing at \(backupURL.path).",
                    relativeManifestPath
                )
            ]
        case .unreadable:
            diagnostics = [
                diagnostic(
                    .warning,
                    "ROM_MUTATION_ARTIFACT_LIBRARY_BACKUP_UNREADABLE",
                    "Backup recorded in the apply manifest could not be read at \(backupURL.path).",
                    relativeManifestPath
                )
            ]
        case .mismatched:
            diagnostics = [
                diagnostic(
                    .warning,
                    "ROM_MUTATION_ARTIFACT_LIBRARY_BACKUP_HASH_MISMATCH",
                    "Backup hash, CRC32, or size no longer matches the apply manifest base-before identity.",
                    relativeManifestPath
                )
            ]
        }

        return BackupIdentityResult(
            identity: identity,
            relativePath: relativeBackupPath,
            status: status,
            diagnostics: diagnostics
        )
    }

    private static func confirmationSummary(
        from manifest: BinaryROMMutationApplyManifest
    ) -> ROMMutationArtifactLibraryConfirmationSummary {
        ROMMutationArtifactLibraryConfirmationSummary(
            method: manifest.confirmation.method,
            dryRunManifestPath: manifest.confirmation.dryRunManifestPath,
            dryRunManifestSHA1: manifest.confirmation.dryRunManifestSHA1,
            hasReviewToken: !manifest.confirmation.reviewToken.isEmpty,
            reviewTokenSuffix: manifest.confirmation.reviewToken.isEmpty
                ? nil
                : String(manifest.confirmation.reviewToken.suffix(8))
        )
    }

    private static func itemStatus(
        diagnostics: [Diagnostic],
        manifestStatus: ROMMutationArtifactLibraryManifestStatus,
        backupStatus: ROMMutationArtifactLibraryCheckStatus
    ) -> ROMMutationArtifactLibraryItemStatus {
        if diagnostics.contains(where: { $0.severity == .error }) {
            return .error
        }
        if manifestStatus != .matched
            || backupStatus != .matched
            || diagnostics.contains(where: { $0.severity == .warning }) {
            return .warning
        }
        return .valid
    }

    private static func verificationSummary(
        status: ROMMutationArtifactLibraryItemStatus,
        manifestStatus: ROMMutationArtifactLibraryManifestStatus,
        backupStatus: ROMMutationArtifactLibraryCheckStatus,
        replacementCount: Int
    ) -> String {
        if manifestStatus == .unreadable {
            return "Apply manifest is unreadable; no ROM, backup, dry-run manifest, source, export, or apply action was attempted."
        }
        if status == .valid {
            return "Apply manifest and original-ROM backup match recorded identity for \(replacementCount) replacement(s); no ROM, backup, dry-run manifest, source, export, or apply action was attempted."
        }
        if backupStatus == .missing {
            return "Apply manifest is readable, but the recorded backup is missing; no ROM, backup, dry-run manifest, source, export, or apply action was attempted."
        }
        if backupStatus == .mismatched {
            return "Apply manifest is readable, but the recorded backup identity has drifted; no ROM, backup, dry-run manifest, source, export, or apply action was attempted."
        }
        return "ROM mutation library found metadata issues; no ROM, backup, dry-run manifest, source, export, or apply action was attempted."
    }

    private static func fileIdentity(
        path: String,
        fileManager: FileManager
    ) -> ROMMutationArtifactLibraryFileIdentity {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        guard fileManager.fileExists(atPath: url.path) else {
            return ROMMutationArtifactLibraryFileIdentity(path: url.path, exists: false)
        }
        guard let data = try? Data(contentsOf: url) else {
            return ROMMutationArtifactLibraryFileIdentity(path: url.path, exists: true)
        }
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        return ROMMutationArtifactLibraryFileIdentity(
            path: url.path,
            exists: true,
            sizeBytes: fileSize(from: attributes) ?? UInt64(data.count),
            sha1: pokemonHackSHA1Hex(data),
            crc32: pokemonHackCRC32Hex(data)
        )
    }

    private static func checkStatus(
        actual: ROMMutationArtifactLibraryFileIdentity?,
        expectedSHA1: String?,
        expectedCRC32: String?,
        expectedSizeBytes: UInt64?
    ) -> ROMMutationArtifactLibraryCheckStatus {
        guard let actual else { return .unavailable }
        guard actual.exists else { return .missing }
        guard let sha1 = actual.sha1, let crc32 = actual.crc32, let size = actual.sizeBytes else {
            return .unreadable
        }
        guard let expectedSHA1, let expectedCRC32, let expectedSizeBytes else {
            return .unavailable
        }
        let shaMatches = sha1.caseInsensitiveCompare(expectedSHA1) == .orderedSame
        let crcMatches = crc32.caseInsensitiveCompare(expectedCRC32) == .orderedSame
        return shaMatches && crcMatches && size == expectedSizeBytes ? .matched : .mismatched
    }

    private static let blockedActions = [
        "Apply binary ROM mutations from library scan",
        "Create dry-run mutation manifests from library scan",
        "Author replacements from library scan",
        "Apply pointer repoints from library scan",
        "Allocate free space from library scan",
        "Repair checksums from library scan",
        "Write patched-copy output from library scan",
        "Launch emulators from library scan",
        "Mutate source from library scan",
        "Export ROMs from library scan",
        "Create backups or manifests from library scan",
        "Overwrite artifacts from library scan",
        "Hash files outside the selected workspace ROM mutation artifact root"
    ]

    private static func readOnlyDiagnostic(_ relativePath: String) -> Diagnostic {
        diagnostic(
            .info,
            "ROM_MUTATION_ARTIFACT_LIBRARY_READ_ONLY",
            "ROM mutation artifact library scans ignored apply manifests and backups only; this library scan does not apply bytes, create dry-run manifests, author replacements, apply repoints, allocate free space, repair checksums, write patched-copy output, launch emulators, mutate source, export ROMs, create backups or manifests, overwrite artifacts, or hash files outside the selected workspace ROM mutation artifact root.",
            relativePath
        )
    }

    private static func diagnostic(
        _ severity: DiagnosticSeverity,
        _ code: String,
        _ message: String,
        _ relativePath: String
    ) -> Diagnostic {
        Diagnostic(
            id: "\(code):\(relativePath):\(message)",
            severity: severity,
            code: code,
            message: message,
            span: SourceSpan(relativePath: relativePath, startLine: 1)
        )
    }

    private static func relativePath(for url: URL, root: URL) -> String {
        let path = url.standardizedFileURL.path
        let rootPath = root.standardizedFileURL.path
        guard path.hasPrefix(rootPath + "/") else {
            return path
        }
        return String(path.dropFirst(rootPath.count + 1))
    }

    private static func isContained(_ url: URL, in root: URL) -> Bool {
        let path = url.standardizedFileURL.path
        let rootPath = root.standardizedFileURL.path
        return path == rootPath || path.hasPrefix(rootPath + "/")
    }

    private static func fileSize(from attributes: [FileAttributeKey: Any]?) -> UInt64? {
        guard let value = attributes?[.size] else { return nil }
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
}
