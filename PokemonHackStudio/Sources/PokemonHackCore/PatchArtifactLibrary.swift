import Foundation

public enum PatchArtifactLibraryItemStatus: String, Codable, Equatable {
    case valid
    case warning
    case error
}

public enum PatchArtifactLibraryCheckStatus: String, Codable, Equatable {
    case matched
    case mismatched
    case missing
    case unreadable
    case unavailable
}

public enum PatchArtifactLibraryManifestStatus: String, Codable, Equatable {
    case matched
    case missing
    case unreadable
    case mismatched
}

public struct PatchArtifactLibraryFileIdentity: Codable, Equatable {
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

public struct PatchArtifactLibraryItem: Codable, Equatable, Identifiable {
    public let id: String
    public let fileName: String
    public let relativePatchPath: String
    public let patchPath: String
    public let relativeManifestPath: String
    public let manifestPath: String
    public let patchIdentity: PatchArtifactLibraryFileIdentity
    public let manifest: PatchCreationArtifactManifest?
    public let manifestStatus: PatchArtifactLibraryManifestStatus
    public let patchChecksumStatus: PatchArtifactLibraryCheckStatus
    public let baseROMStatus: PatchArtifactLibraryCheckStatus
    public let builtOutputStatus: PatchArtifactLibraryCheckStatus
    public let baseROMIdentity: PatchArtifactLibraryFileIdentity?
    public let builtOutputIdentity: PatchArtifactLibraryFileIdentity?
    public let patchSummary: PatchSummary?
    public let verificationSummary: String
    public let status: PatchArtifactLibraryItemStatus
    public let diagnostics: [Diagnostic]

    public init(
        id: String,
        fileName: String,
        relativePatchPath: String,
        patchPath: String,
        relativeManifestPath: String,
        manifestPath: String,
        patchIdentity: PatchArtifactLibraryFileIdentity,
        manifest: PatchCreationArtifactManifest?,
        manifestStatus: PatchArtifactLibraryManifestStatus,
        patchChecksumStatus: PatchArtifactLibraryCheckStatus,
        baseROMStatus: PatchArtifactLibraryCheckStatus,
        builtOutputStatus: PatchArtifactLibraryCheckStatus,
        baseROMIdentity: PatchArtifactLibraryFileIdentity?,
        builtOutputIdentity: PatchArtifactLibraryFileIdentity?,
        patchSummary: PatchSummary?,
        verificationSummary: String,
        status: PatchArtifactLibraryItemStatus,
        diagnostics: [Diagnostic]
    ) {
        self.id = id
        self.fileName = fileName
        self.relativePatchPath = relativePatchPath
        self.patchPath = patchPath
        self.relativeManifestPath = relativeManifestPath
        self.manifestPath = manifestPath
        self.patchIdentity = patchIdentity
        self.manifest = manifest
        self.manifestStatus = manifestStatus
        self.patchChecksumStatus = patchChecksumStatus
        self.baseROMStatus = baseROMStatus
        self.builtOutputStatus = builtOutputStatus
        self.baseROMIdentity = baseROMIdentity
        self.builtOutputIdentity = builtOutputIdentity
        self.patchSummary = patchSummary
        self.verificationSummary = verificationSummary
        self.status = status
        self.diagnostics = diagnostics
    }
}

public struct PatchArtifactLibrary: Codable, Equatable {
    public let projectRoot: String
    public let artifactRoot: String
    public let relativeArtifactRoot: String
    public let items: [PatchArtifactLibraryItem]
    public let diagnostics: [Diagnostic]
    public let isReadOnly: Bool

    public init(
        projectRoot: String,
        artifactRoot: String,
        relativeArtifactRoot: String,
        items: [PatchArtifactLibraryItem],
        diagnostics: [Diagnostic],
        isReadOnly: Bool
    ) {
        self.projectRoot = projectRoot
        self.artifactRoot = artifactRoot
        self.relativeArtifactRoot = relativeArtifactRoot
        self.items = items
        self.diagnostics = diagnostics
        self.isReadOnly = isReadOnly
    }
}

public enum PatchArtifactLibraryScanner {
    public static func scan(
        projectPath: String,
        fileManager: FileManager = .default
    ) -> PatchArtifactLibrary {
        let projectRoot = URL(fileURLWithPath: projectPath).standardizedFileURL
        let relativeArtifactRoot = ".pokemonhackstudio/patches"
        let artifactRoot = projectRoot.appendingPathComponent(relativeArtifactRoot).standardizedFileURL
        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: artifactRoot.path, isDirectory: &isDirectory) else {
            return PatchArtifactLibrary(
                projectRoot: projectRoot.path,
                artifactRoot: artifactRoot.path,
                relativeArtifactRoot: relativeArtifactRoot,
                items: [],
                diagnostics: [
                    diagnostic(
                        .info,
                        "PATCH_ARTIFACT_LIBRARY_EMPTY",
                        "No ignored BPS patch artifacts were found under \(relativeArtifactRoot).",
                        relativeArtifactRoot
                    ),
                    readOnlyDiagnostic(relativeArtifactRoot)
                ],
                isReadOnly: true
            )
        }

        guard isDirectory.boolValue else {
            return PatchArtifactLibrary(
                projectRoot: projectRoot.path,
                artifactRoot: artifactRoot.path,
                relativeArtifactRoot: relativeArtifactRoot,
                items: [],
                diagnostics: [
                    diagnostic(
                        .error,
                        "PATCH_ARTIFACT_LIBRARY_ROOT_NOT_DIRECTORY",
                        "Patch artifact library root exists but is not a directory: \(artifactRoot.path).",
                        relativeArtifactRoot
                    ),
                    readOnlyDiagnostic(relativeArtifactRoot)
                ],
                isReadOnly: true
            )
        }

        let patchURLs: [URL]
        do {
            patchURLs = try fileManager.contentsOfDirectory(
                at: artifactRoot,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            )
            .filter { $0.pathExtension.lowercased() == "bps" }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        } catch {
            return PatchArtifactLibrary(
                projectRoot: projectRoot.path,
                artifactRoot: artifactRoot.path,
                relativeArtifactRoot: relativeArtifactRoot,
                items: [],
                diagnostics: [
                    diagnostic(
                        .error,
                        "PATCH_ARTIFACT_LIBRARY_READ_FAILED",
                        "Patch artifact library could not be read: \(error.localizedDescription)",
                        relativeArtifactRoot
                    ),
                    readOnlyDiagnostic(relativeArtifactRoot)
                ],
                isReadOnly: true
            )
        }

        let items = patchURLs.map {
            item(for: $0, projectRoot: projectRoot, artifactRoot: artifactRoot, fileManager: fileManager)
        }
        let libraryDiagnostics = [
            diagnostic(
                .info,
                "PATCH_ARTIFACT_LIBRARY_READ_ONLY",
                "Patch artifact library scans ignored .bps artifacts and manifests only; it does not apply patches, export ROMs, run builds, launch playtests, overwrite artifacts, mutate source, or rewrite headers.",
                relativeArtifactRoot
            )
        ]

        return PatchArtifactLibrary(
            projectRoot: projectRoot.path,
            artifactRoot: artifactRoot.path,
            relativeArtifactRoot: relativeArtifactRoot,
            items: items,
            diagnostics: libraryDiagnostics,
            isReadOnly: true
        )
    }

    private static func item(
        for patchURL: URL,
        projectRoot: URL,
        artifactRoot: URL,
        fileManager: FileManager
    ) -> PatchArtifactLibraryItem {
        let patchURL = patchURL.standardizedFileURL
        let manifestURL = URL(fileURLWithPath: patchURL.path + ".manifest.json").standardizedFileURL
        let relativePatchPath = relativePath(for: patchURL, root: projectRoot)
        let relativeManifestPath = relativePath(for: manifestURL, root: projectRoot)
        var diagnostics: [Diagnostic] = []

        let patchIdentity = fileIdentity(path: patchURL.path, fileManager: fileManager)
        let validation = PatchValidationReportBuilder.validate(path: patchURL.path, fileManager: fileManager)
        diagnostics.append(contentsOf: validation.diagnostics)
        if validation.summary?.format != .bps {
            diagnostics.append(
                diagnostic(
                    .error,
                    "PATCH_ARTIFACT_LIBRARY_NON_BPS",
                    "Patch library includes only BPS artifacts; \(patchURL.lastPathComponent) parsed as \(validation.summary?.format.rawValue ?? "unknown").",
                    relativePatchPath
                )
            )
        }

        let manifestRead = readManifest(at: manifestURL, relativePath: relativeManifestPath, patchURL: patchURL, fileManager: fileManager)
        diagnostics.append(contentsOf: manifestRead.diagnostics)

        let patchChecksumStatus = checkStatus(
            actual: patchIdentity,
            expectedSHA1: manifestRead.manifest?.patchSHA1,
            expectedCRC32: manifestRead.manifest?.patchCRC32,
            expectedSizeBytes: manifestRead.manifest?.patchSizeBytes
        )
        if patchChecksumStatus == .mismatched {
            diagnostics.append(
                diagnostic(
                    .warning,
                    "PATCH_ARTIFACT_LIBRARY_PATCH_HASH_MISMATCH",
                    "Patch artifact hash, CRC32, or size no longer matches its creation manifest.",
                    relativePatchPath
                )
            )
        }

        let baseIdentity: PatchArtifactLibraryFileIdentity?
        let baseStatus: PatchArtifactLibraryCheckStatus
        if let manifest = manifestRead.manifest {
            baseIdentity = fileIdentity(path: manifest.baseROMPath, fileManager: fileManager)
            baseStatus = checkStatus(
                actual: baseIdentity,
                expectedSHA1: manifest.baseROMSHA1,
                expectedCRC32: manifest.baseROMCRC32,
                expectedSizeBytes: manifest.baseROMSizeBytes
            )
            appendInputDiagnostics(
                status: baseStatus,
                codePrefix: "PATCH_ARTIFACT_LIBRARY_BASE_ROM",
                label: "Base ROM",
                path: manifest.baseROMPath,
                relativePatchPath: relativePatchPath,
                diagnostics: &diagnostics
            )
        } else {
            baseIdentity = nil
            baseStatus = .unavailable
        }

        let builtOutputIdentity: PatchArtifactLibraryFileIdentity?
        let builtOutputStatus: PatchArtifactLibraryCheckStatus
        if let manifest = manifestRead.manifest {
            builtOutputIdentity = fileIdentity(path: manifest.builtOutputPath, fileManager: fileManager)
            builtOutputStatus = checkStatus(
                actual: builtOutputIdentity,
                expectedSHA1: manifest.builtOutputSHA1,
                expectedCRC32: manifest.builtOutputCRC32,
                expectedSizeBytes: manifest.builtOutputSizeBytes
            )
            appendInputDiagnostics(
                status: builtOutputStatus,
                codePrefix: "PATCH_ARTIFACT_LIBRARY_BUILT_OUTPUT",
                label: "Built output",
                path: manifest.builtOutputPath,
                relativePatchPath: relativePatchPath,
                diagnostics: &diagnostics
            )
        } else {
            builtOutputIdentity = nil
            builtOutputStatus = .unavailable
        }

        let status = itemStatus(
            diagnostics: diagnostics,
            manifestStatus: manifestRead.status,
            patchChecksumStatus: patchChecksumStatus,
            baseROMStatus: baseStatus,
            builtOutputStatus: builtOutputStatus
        )
        let summary = verificationSummary(
            status: status,
            manifestStatus: manifestRead.status,
            patchChecksumStatus: patchChecksumStatus,
            baseROMStatus: baseStatus,
            builtOutputStatus: builtOutputStatus,
            patchSummary: validation.summary
        )

        _ = artifactRoot
        return PatchArtifactLibraryItem(
            id: patchURL.path,
            fileName: patchURL.lastPathComponent,
            relativePatchPath: relativePatchPath,
            patchPath: patchURL.path,
            relativeManifestPath: relativeManifestPath,
            manifestPath: manifestURL.path,
            patchIdentity: patchIdentity,
            manifest: manifestRead.manifest,
            manifestStatus: manifestRead.status,
            patchChecksumStatus: patchChecksumStatus,
            baseROMStatus: baseStatus,
            builtOutputStatus: builtOutputStatus,
            baseROMIdentity: baseIdentity,
            builtOutputIdentity: builtOutputIdentity,
            patchSummary: validation.summary,
            verificationSummary: summary,
            status: status,
            diagnostics: diagnostics
        )
    }

    private struct ManifestReadResult {
        let manifest: PatchCreationArtifactManifest?
        let status: PatchArtifactLibraryManifestStatus
        let diagnostics: [Diagnostic]
    }

    private static func readManifest(
        at manifestURL: URL,
        relativePath: String,
        patchURL: URL,
        fileManager: FileManager
    ) -> ManifestReadResult {
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            return ManifestReadResult(
                manifest: nil,
                status: .missing,
                diagnostics: [
                    diagnostic(
                        .warning,
                        "PATCH_ARTIFACT_LIBRARY_MANIFEST_MISSING",
                        "No sibling creation manifest exists for \(patchURL.lastPathComponent).",
                        relativePath
                    )
                ]
            )
        }

        do {
            let data = try Data(contentsOf: manifestURL)
            let manifest = try JSONDecoder().decode(PatchCreationArtifactManifest.self, from: data)
            var diagnostics: [Diagnostic] = []
            var status: PatchArtifactLibraryManifestStatus = .matched

            if manifest.action != "patch-create" {
                diagnostics.append(
                    diagnostic(
                        .warning,
                        "PATCH_ARTIFACT_LIBRARY_MANIFEST_ACTION_MISMATCH",
                        "Creation manifest action is \(manifest.action), not patch-create.",
                        relativePath
                    )
                )
                status = .mismatched
            }
            if manifest.patchFormat != .bps {
                diagnostics.append(
                    diagnostic(
                        .warning,
                        "PATCH_ARTIFACT_LIBRARY_MANIFEST_FORMAT_MISMATCH",
                        "Creation manifest format is \(manifest.patchFormat.rawValue), not bps.",
                        relativePath
                    )
                )
                status = .mismatched
            }
            let manifestPatchPath = URL(fileURLWithPath: manifest.patchPath).standardizedFileURL.path
            if manifestPatchPath != patchURL.path {
                diagnostics.append(
                    diagnostic(
                        .warning,
                        "PATCH_ARTIFACT_LIBRARY_MANIFEST_PATCH_PATH_MISMATCH",
                        "Creation manifest points at \(manifest.patchPath), not \(patchURL.path).",
                        relativePath
                    )
                )
                status = .mismatched
            }

            return ManifestReadResult(manifest: manifest, status: status, diagnostics: diagnostics)
        } catch {
            return ManifestReadResult(
                manifest: nil,
                status: .unreadable,
                diagnostics: [
                    diagnostic(
                        .warning,
                        "PATCH_ARTIFACT_LIBRARY_MANIFEST_UNREADABLE",
                        "Creation manifest could not be decoded: \(error.localizedDescription)",
                        relativePath
                    )
                ]
            )
        }
    }

    private static func fileIdentity(
        path: String,
        fileManager: FileManager
    ) -> PatchArtifactLibraryFileIdentity {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        guard fileManager.fileExists(atPath: url.path) else {
            return PatchArtifactLibraryFileIdentity(path: url.path, exists: false)
        }
        guard let data = try? Data(contentsOf: url) else {
            return PatchArtifactLibraryFileIdentity(path: url.path, exists: true)
        }
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        return PatchArtifactLibraryFileIdentity(
            path: url.path,
            exists: true,
            sizeBytes: fileSize(from: attributes) ?? UInt64(data.count),
            sha1: pokemonHackSHA1Hex(data),
            crc32: pokemonHackCRC32Hex(data)
        )
    }

    private static func checkStatus(
        actual: PatchArtifactLibraryFileIdentity?,
        expectedSHA1: String?,
        expectedCRC32: String?,
        expectedSizeBytes: UInt64?
    ) -> PatchArtifactLibraryCheckStatus {
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

    private static func appendInputDiagnostics(
        status: PatchArtifactLibraryCheckStatus,
        codePrefix: String,
        label: String,
        path: String,
        relativePatchPath: String,
        diagnostics: inout [Diagnostic]
    ) {
        switch status {
        case .matched, .unavailable:
            return
        case .missing:
            diagnostics.append(
                diagnostic(
                    .warning,
                    "\(codePrefix)_MISSING",
                    "\(label) recorded in the creation manifest is missing at \(path).",
                    relativePatchPath
                )
            )
        case .unreadable:
            diagnostics.append(
                diagnostic(
                    .warning,
                    "\(codePrefix)_UNREADABLE",
                    "\(label) recorded in the creation manifest could not be read at \(path).",
                    relativePatchPath
                )
            )
        case .mismatched:
            diagnostics.append(
                diagnostic(
                    .warning,
                    "\(codePrefix)_HASH_MISMATCH",
                    "\(label) hash, CRC32, or size no longer matches the creation manifest.",
                    relativePatchPath
                )
            )
        }
    }

    private static func itemStatus(
        diagnostics: [Diagnostic],
        manifestStatus: PatchArtifactLibraryManifestStatus,
        patchChecksumStatus: PatchArtifactLibraryCheckStatus,
        baseROMStatus: PatchArtifactLibraryCheckStatus,
        builtOutputStatus: PatchArtifactLibraryCheckStatus
    ) -> PatchArtifactLibraryItemStatus {
        if diagnostics.contains(where: { $0.severity == .error }) {
            return .error
        }
        if manifestStatus != .matched
            || patchChecksumStatus != .matched
            || baseROMStatus != .matched
            || builtOutputStatus != .matched
            || diagnostics.contains(where: { $0.severity == .warning }) {
            return .warning
        }
        return .valid
    }

    private static func verificationSummary(
        status: PatchArtifactLibraryItemStatus,
        manifestStatus: PatchArtifactLibraryManifestStatus,
        patchChecksumStatus: PatchArtifactLibraryCheckStatus,
        baseROMStatus: PatchArtifactLibraryCheckStatus,
        builtOutputStatus: PatchArtifactLibraryCheckStatus,
        patchSummary: PatchSummary?
    ) -> String {
        if patchSummary?.format != .bps {
            return "Patch metadata is not a valid BPS artifact; no apply/export was attempted."
        }
        if manifestStatus == .missing {
            return "Patch parsed as BPS, but no sibling creation manifest is available; no apply/export was attempted."
        }
        if manifestStatus == .unreadable {
            return "Patch parsed as BPS, but the sibling creation manifest is unreadable; no apply/export was attempted."
        }
        if status == .valid {
            return "Patch, manifest, base ROM, and built output hashes match current files; no apply/export was attempted."
        }

        let reviewCount = [patchChecksumStatus, baseROMStatus, builtOutputStatus]
            .filter { $0 != .matched }
            .count + (manifestStatus == .matched ? 0 : 1)
        return "Patch library found \(reviewCount) metadata issue\(reviewCount == 1 ? "" : "s"); no apply/export was attempted."
    }

    private static func relativePath(for url: URL, root: URL) -> String {
        let path = url.standardizedFileURL.path
        let rootPath = root.standardizedFileURL.path
        guard path.hasPrefix(rootPath + "/") else {
            return path
        }
        return String(path.dropFirst(rootPath.count + 1))
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

    private static func readOnlyDiagnostic(_ relativePath: String) -> Diagnostic {
        diagnostic(
            .info,
            "PATCH_ARTIFACT_LIBRARY_READ_ONLY",
            "Patch artifact library scans ignored .bps artifacts and manifests only; it does not apply patches, export ROMs, run builds, launch playtests, overwrite artifacts, mutate source, or rewrite headers.",
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
}
