import Foundation

public struct BinaryROMMutationReplacementRequest: Codable, Equatable {
    public let offset: UInt32
    public let length: UInt32
    public let replacementBytes: [UInt8]

    public init(offset: UInt32, length: UInt32, replacementBytes: [UInt8]) {
        self.offset = offset
        self.length = length
        self.replacementBytes = replacementBytes
    }
}

public struct BinaryROMMutationRepointRequest: Codable, Equatable {
    public let pointerOffset: UInt32
    public let newTargetOffset: UInt32

    public init(pointerOffset: UInt32, newTargetOffset: UInt32) {
        self.pointerOffset = pointerOffset
        self.newTargetOffset = newTargetOffset
    }
}

public struct BinaryROMMutationAllocationRequest: Codable, Equatable {
    public let byteCount: UInt32
    public let alignment: UInt32

    public init(byteCount: UInt32, alignment: UInt32 = 1) {
        self.byteCount = byteCount
        self.alignment = max(alignment, 1)
    }
}

public struct BinaryROMMutationDryRunRequest: Codable, Equatable {
    public let expectedSHA1: String?
    public let workspaceRoot: String?
    public let replacements: [BinaryROMMutationReplacementRequest]
    public let repoints: [BinaryROMMutationRepointRequest]
    public let allocations: [BinaryROMMutationAllocationRequest]

    public init(
        expectedSHA1: String? = nil,
        workspaceRoot: String? = nil,
        replacements: [BinaryROMMutationReplacementRequest] = [],
        repoints: [BinaryROMMutationRepointRequest] = [],
        allocations: [BinaryROMMutationAllocationRequest] = []
    ) {
        self.expectedSHA1 = expectedSHA1
        self.workspaceRoot = workspaceRoot
        self.replacements = replacements
        self.repoints = repoints
        self.allocations = allocations
    }
}

public struct BinaryROMMutationBaseIdentity: Codable, Equatable {
    public let path: String
    public let fileName: String
    public let sizeBytes: UInt64
    public let sha1: String
    public let crc32: String
    public let title: String?
    public let gameCode: String?
    public let makerCode: String?
    public let revision: UInt8?
    public let headerComplementChecksum: UInt8?
    public let expectedHeaderComplementChecksum: UInt8?
    public let isHeaderComplementChecksumValid: Bool?
    public let headerFacts: [BinaryROMGraphFact]

    public init(path: String, data: Data, graph: BinaryROMGraph) {
        let image = graph.image
        self.path = path
        fileName = URL(fileURLWithPath: path).lastPathComponent
        sizeBytes = UInt64(data.count)
        sha1 = pokemonHackSHA1Hex(data)
        crc32 = pokemonHackCRC32Hex(data)
        title = image.title
        gameCode = image.gameCode
        makerCode = image.makerCode
        revision = image.version
        headerComplementChecksum = image.complementChecksum
        expectedHeaderComplementChecksum = image.expectedComplementChecksum
        isHeaderComplementChecksumValid = image.isComplementChecksumValid
        headerFacts = graph.headerFacts
    }
}

public enum BinaryROMMutationSourceTreeStatus: String, Codable, Equatable {
    case binaryOnlyCandidate
    case refusedSourceTreeInput
    case refusedSourceTreeAvailable
    case unsupportedInput
}

public struct BinaryROMMutationSourceCandidate: Codable, Equatable, Identifiable {
    public var id: String { path }

    public let path: String
    public let profile: GameProfile
    public let adapterID: String
    public let adapterName: String

    public init(index: ProjectIndex) {
        path = index.root.path
        profile = index.profile
        adapterID = index.adapterID
        adapterName = index.adapterName
    }
}

public struct BinaryROMMutationSourceTreeState: Codable, Equatable {
    public let status: BinaryROMMutationSourceTreeStatus
    public let canUseBinaryOnlyPlan: Bool
    public let rationale: String
    public let sourceCandidates: [BinaryROMMutationSourceCandidate]

    public init(
        status: BinaryROMMutationSourceTreeStatus,
        canUseBinaryOnlyPlan: Bool,
        rationale: String,
        sourceCandidates: [BinaryROMMutationSourceCandidate] = []
    ) {
        self.status = status
        self.canUseBinaryOnlyPlan = canUseBinaryOnlyPlan
        self.rationale = rationale
        self.sourceCandidates = sourceCandidates
    }
}

public struct BinaryROMMutationIgnoredOutputGuidance: Codable, Equatable {
    public let willWriteFiles: Bool
    public let relativeRoot: String
    public let relativeManifestPath: String
    public let relativeOutputROMPath: String
    public let relativeBackupRoot: String
    public let guidance: [String]

    public init(stem: String) {
        willWriteFiles = false
        relativeRoot = ".pokemonhackstudio/rom-mutations/\(stem)"
        relativeManifestPath = "\(relativeRoot)/manifest.json"
        relativeOutputROMPath = "\(relativeRoot)/\(stem)-patched.gba"
        relativeBackupRoot = "\(relativeRoot)/<timestamp-token>"
        guidance = [
            "Dry-run manifests report ignored future output paths only.",
            "No backup, manifest, patched ROM, export artifact, checksum repair, or byte write is created.",
            "Future binary mutation artifacts must stay under ignored .pokemonhackstudio/rom-mutations/ roots."
        ]
    }
}

public struct BinaryROMMutationApplyReview: Codable, Equatable {
    public let isReviewable: Bool
    public let reviewToken: String?
    public let confirmationArgument: String?
    public let operationCount: Int
    public let operationKinds: [BinaryROMMutationOperationKind]
    public let blockedApplyActions: [String]
    public let rationale: String

    public init(
        isReviewable: Bool,
        reviewToken: String?,
        confirmationArgument: String?,
        operationCount: Int,
        operationKinds: [BinaryROMMutationOperationKind],
        blockedApplyActions: [String],
        rationale: String
    ) {
        self.isReviewable = isReviewable
        self.reviewToken = reviewToken
        self.confirmationArgument = confirmationArgument
        self.operationCount = operationCount
        self.operationKinds = operationKinds
        self.blockedApplyActions = blockedApplyActions
        self.rationale = rationale
    }
}

public enum BinaryROMMutationOperationKind: String, Codable, Equatable {
    case replaceBytes
    case repointPointer
    case allocateFreeSpace
}

public enum BinaryROMMutationOperationStatus: String, Codable, Equatable {
    case previewOnly
    case blocked
}

public struct BinaryROMMutationOperationPreview: Codable, Equatable, Identifiable {
    public let id: String
    public let kind: BinaryROMMutationOperationKind
    public let status: BinaryROMMutationOperationStatus
    public let canApply: Bool
    public let summary: String
    public let offset: UInt32?
    public let length: UInt32?
    public let originalPreviewHex: String?
    public let originalSpanSHA1: String?
    public let replacementPreviewHex: String?
    public let replacementHex: String?
    public let replacementSHA1: String?
    public let pointerSourceOffset: UInt32?
    public let oldTargetOffset: UInt32?
    public let plannedTargetOffset: UInt32?
    public let oldRawValue: UInt32?
    public let plannedRawValue: UInt32?
    public let allocationByteCount: UInt32?
    public let alignment: UInt32?
    public let selectedFreeSpaceOffset: UInt32?
    public let selectedFreeSpaceLength: UInt32?
    public let selectedFreeSpaceFillByte: UInt8?
    public let diagnostics: [Diagnostic]

    public init(
        id: String,
        kind: BinaryROMMutationOperationKind,
        status: BinaryROMMutationOperationStatus,
        summary: String,
        offset: UInt32? = nil,
        length: UInt32? = nil,
        originalPreviewHex: String? = nil,
        originalSpanSHA1: String? = nil,
        replacementPreviewHex: String? = nil,
        replacementHex: String? = nil,
        replacementSHA1: String? = nil,
        pointerSourceOffset: UInt32? = nil,
        oldTargetOffset: UInt32? = nil,
        plannedTargetOffset: UInt32? = nil,
        oldRawValue: UInt32? = nil,
        plannedRawValue: UInt32? = nil,
        allocationByteCount: UInt32? = nil,
        alignment: UInt32? = nil,
        selectedFreeSpaceOffset: UInt32? = nil,
        selectedFreeSpaceLength: UInt32? = nil,
        selectedFreeSpaceFillByte: UInt8? = nil,
        diagnostics: [Diagnostic] = []
    ) {
        self.id = id
        self.kind = kind
        self.status = status
        canApply = false
        self.summary = summary
        self.offset = offset
        self.length = length
        self.originalPreviewHex = originalPreviewHex
        self.originalSpanSHA1 = originalSpanSHA1
        self.replacementPreviewHex = replacementPreviewHex
        self.replacementHex = replacementHex
        self.replacementSHA1 = replacementSHA1
        self.pointerSourceOffset = pointerSourceOffset
        self.oldTargetOffset = oldTargetOffset
        self.plannedTargetOffset = plannedTargetOffset
        self.oldRawValue = oldRawValue
        self.plannedRawValue = plannedRawValue
        self.allocationByteCount = allocationByteCount
        self.alignment = alignment
        self.selectedFreeSpaceOffset = selectedFreeSpaceOffset
        self.selectedFreeSpaceLength = selectedFreeSpaceLength
        self.selectedFreeSpaceFillByte = selectedFreeSpaceFillByte
        self.diagnostics = diagnostics
    }
}

public struct BinaryROMMutationDryRunManifest: Codable, Equatable {
    public let schemaVersion: Int
    public let isDryRun: Bool
    public let canApply: Bool
    public let inputPath: String
    public let profile: GameProfile
    public let baseROM: BinaryROMMutationBaseIdentity?
    public let sourceTreeFirst: BinaryROMMutationSourceTreeState
    public let operationPreviews: [BinaryROMMutationOperationPreview]
    public let ignoredOutputGuidance: BinaryROMMutationIgnoredOutputGuidance
    public let applyReview: BinaryROMMutationApplyReview?
    public let diagnostics: [Diagnostic]

    public init(
        inputPath: String,
        profile: GameProfile,
        baseROM: BinaryROMMutationBaseIdentity?,
        sourceTreeFirst: BinaryROMMutationSourceTreeState,
        operationPreviews: [BinaryROMMutationOperationPreview],
        ignoredOutputGuidance: BinaryROMMutationIgnoredOutputGuidance,
        applyReview: BinaryROMMutationApplyReview? = nil,
        diagnostics: [Diagnostic]
    ) {
        schemaVersion = 1
        isDryRun = true
        canApply = false
        self.inputPath = inputPath
        self.profile = profile
        self.baseROM = baseROM
        self.sourceTreeFirst = sourceTreeFirst
        self.operationPreviews = operationPreviews
        self.ignoredOutputGuidance = ignoredOutputGuidance
        self.applyReview = applyReview
        self.diagnostics = diagnostics
    }
}

public enum BinaryROMMutationApplyStatus: String, Codable, Equatable {
    case applied
    case blocked
}

public struct BinaryROMMutationApplyConfirmation: Codable, Equatable {
    public let method: String
    public let reviewToken: String
    public let dryRunManifestPath: String
    public let dryRunManifestSHA1: String

    public init(method: String, reviewToken: String, dryRunManifestPath: String, dryRunManifestSHA1: String) {
        self.method = method
        self.reviewToken = reviewToken
        self.dryRunManifestPath = dryRunManifestPath
        self.dryRunManifestSHA1 = dryRunManifestSHA1
    }
}

public struct BinaryROMMutationAppliedReplacement: Codable, Equatable, Identifiable {
    public let id: String
    public let offset: UInt32
    public let length: UInt32
    public let originalPreviewHex: String?
    public let originalSpanSHA1: String?
    public let replacementPreviewHex: String?
    public let replacementSHA1: String?

    public init(
        id: String,
        offset: UInt32,
        length: UInt32,
        originalPreviewHex: String?,
        originalSpanSHA1: String?,
        replacementPreviewHex: String?,
        replacementSHA1: String?
    ) {
        self.id = id
        self.offset = offset
        self.length = length
        self.originalPreviewHex = originalPreviewHex
        self.originalSpanSHA1 = originalSpanSHA1
        self.replacementPreviewHex = replacementPreviewHex
        self.replacementSHA1 = replacementSHA1
    }
}

public struct BinaryROMMutationApplyManifest: Codable, Equatable {
    public let schemaVersion: Int
    public let operationKind: String
    public let inputPath: String
    public let backupPath: String
    public let baseBefore: BinaryROMMutationBaseIdentity
    public let baseAfter: BinaryROMMutationBaseIdentity
    public let replacements: [BinaryROMMutationAppliedReplacement]
    public let confirmation: BinaryROMMutationApplyConfirmation
    public let diagnostics: [Diagnostic]

    public init(
        inputPath: String,
        backupPath: String,
        baseBefore: BinaryROMMutationBaseIdentity,
        baseAfter: BinaryROMMutationBaseIdentity,
        replacements: [BinaryROMMutationAppliedReplacement],
        confirmation: BinaryROMMutationApplyConfirmation,
        diagnostics: [Diagnostic]
    ) {
        schemaVersion = 1
        operationKind = "replaceBytesInPlace"
        self.inputPath = inputPath
        self.backupPath = backupPath
        self.baseBefore = baseBefore
        self.baseAfter = baseAfter
        self.replacements = replacements
        self.confirmation = confirmation
        self.diagnostics = diagnostics
    }
}

public struct BinaryROMMutationApplyResult: Codable, Equatable {
    public let schemaVersion: Int
    public let status: BinaryROMMutationApplyStatus
    public let inputPath: String
    public let backupPath: String?
    public let manifestPath: String?
    public let baseBefore: BinaryROMMutationBaseIdentity?
    public let baseAfter: BinaryROMMutationBaseIdentity?
    public let appliedReplacements: [BinaryROMMutationAppliedReplacement]
    public let diagnostics: [Diagnostic]
    public let manifest: BinaryROMMutationApplyManifest?

    public init(
        status: BinaryROMMutationApplyStatus,
        inputPath: String,
        backupPath: String? = nil,
        manifestPath: String? = nil,
        baseBefore: BinaryROMMutationBaseIdentity? = nil,
        baseAfter: BinaryROMMutationBaseIdentity? = nil,
        appliedReplacements: [BinaryROMMutationAppliedReplacement] = [],
        diagnostics: [Diagnostic],
        manifest: BinaryROMMutationApplyManifest? = nil
    ) {
        schemaVersion = 1
        self.status = status
        self.inputPath = inputPath
        self.backupPath = backupPath
        self.manifestPath = manifestPath
        self.baseBefore = baseBefore
        self.baseAfter = baseAfter
        self.appliedReplacements = appliedReplacements
        self.diagnostics = diagnostics
        self.manifest = manifest
    }
}

public enum BinaryROMMutationDryRunManifestBuilder {
    public static func build(
        path: String,
        request: BinaryROMMutationDryRunRequest = BinaryROMMutationDryRunRequest(),
        fileManager: FileManager = .default
    ) -> BinaryROMMutationDryRunManifest {
        let inputURL = URL(fileURLWithPath: path).standardizedFileURL
        let outputGuidance = BinaryROMMutationIgnoredOutputGuidance(stem: sanitizedStem(for: inputURL))
        let index: ProjectIndex
        do {
            index = try GameAdapterRegistry.index(path: inputURL.path, fileManager: fileManager)
        } catch {
            let diagnostics = [
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_INPUT_UNSUPPORTED",
                    message: "Binary ROM mutation dry-run manifests require a supported local .gba binary ROM input; \(inputURL.path) could not be indexed."
                ),
                dryRunDiagnostic()
            ]
            return BinaryROMMutationDryRunManifest(
                inputPath: inputURL.path,
                profile: .unknown,
                baseROM: nil,
                sourceTreeFirst: BinaryROMMutationSourceTreeState(
                    status: .unsupportedInput,
                    canUseBinaryOnlyPlan: false,
                    rationale: "Unsupported inputs cannot produce binary-only operation previews."
                ),
                operationPreviews: [],
                ignoredOutputGuidance: outputGuidance,
                diagnostics: diagnostics
            )
        }

        if index.profile.projectKind == .sourceTree {
            let diagnostics = [
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_SOURCE_TREE_INPUT_REFUSED",
                    message: "Refusing binary ROM mutation planning for source-tree input \(index.root.path); edit the decompilation source tree through source mutation plans instead."
                ),
                dryRunDiagnostic()
            ]
            return BinaryROMMutationDryRunManifest(
                inputPath: inputURL.path,
                profile: index.profile,
                baseROM: nil,
                sourceTreeFirst: BinaryROMMutationSourceTreeState(
                    status: .refusedSourceTreeInput,
                    canUseBinaryOnlyPlan: false,
                    rationale: "A source-tree edit path is the canonical workflow for this input.",
                    sourceCandidates: [BinaryROMMutationSourceCandidate(index: index)]
                ),
                operationPreviews: [],
                ignoredOutputGuidance: outputGuidance,
                diagnostics: diagnostics
            )
        }

        guard index.profile == .binaryROM else {
            let diagnostics = [
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_NON_GBA_INPUT_REFUSED",
                    message: "Binary ROM mutation manifests only support GBA .gba binaryROM inputs; \(index.profile.rawValue) remains outside this dry-run model."
                ),
                dryRunDiagnostic()
            ]
            return BinaryROMMutationDryRunManifest(
                inputPath: inputURL.path,
                profile: index.profile,
                baseROM: nil,
                sourceTreeFirst: BinaryROMMutationSourceTreeState(
                    status: .unsupportedInput,
                    canUseBinaryOnlyPlan: false,
                    rationale: "Only local GBA binary ROM inputs can produce this dry-run manifest."
                ),
                operationPreviews: [],
                ignoredOutputGuidance: outputGuidance,
                diagnostics: diagnostics
            )
        }

        guard let data = try? Data(contentsOf: inputURL) else {
            let diagnostics = [
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_INPUT_UNREADABLE",
                    message: "Could not read base ROM bytes from \(inputURL.path)."
                ),
                dryRunDiagnostic()
            ]
            return BinaryROMMutationDryRunManifest(
                inputPath: inputURL.path,
                profile: index.profile,
                baseROM: nil,
                sourceTreeFirst: BinaryROMMutationSourceTreeState(
                    status: .unsupportedInput,
                    canUseBinaryOnlyPlan: false,
                    rationale: "Unreadable base ROM bytes cannot produce operation previews."
                ),
                operationPreviews: [],
                ignoredOutputGuidance: outputGuidance,
                diagnostics: diagnostics
            )
        }

        let graph = BinaryROMGraphBuilder.build(path: inputURL.path, data: data)
        let base = BinaryROMMutationBaseIdentity(path: inputURL.path, data: data, graph: graph)
        let sourceCandidates = sourceTreeCandidates(
            workspaceRoot: request.workspaceRoot,
            romGameCode: base.gameCode,
            inputURL: inputURL,
            fileManager: fileManager
        )
        var diagnostics = index.diagnostics + graph.diagnostics + [
            Diagnostic(
                severity: .info,
                code: "BINARY_ROM_MUTATION_BASE_IDENTITY",
                message: "Base ROM identity captured: SHA1 \(base.sha1), CRC32 \(base.crc32), \(base.sizeBytes) byte(s)."
            ),
            dryRunDiagnostic(),
            Diagnostic(
                severity: .info,
                code: "BINARY_ROM_MUTATION_IGNORED_OUTPUT_GUIDANCE",
                message: "Future binary mutation manifests and ROM artifacts must stay under \(outputGuidance.relativeRoot); this dry run writes no files."
            )
        ]

        if let expectedSHA1 = request.expectedSHA1?.lowercased(), expectedSHA1 != base.sha1 {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_BASE_SHA1_MISMATCH",
                    message: "Expected base SHA1 \(expectedSHA1), but selected ROM SHA1 is \(base.sha1); future apply must refuse base-hash drift."
                )
            )
        }

        if !sourceCandidates.isEmpty {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_SOURCE_TREE_AVAILABLE_REFUSED",
                    message: "Refusing binary-only operation previews because \(sourceCandidates.count) matching source-tree candidate(s) were found under the requested workspace root."
                )
            )
            return BinaryROMMutationDryRunManifest(
                inputPath: inputURL.path,
                profile: index.profile,
                baseROM: base,
                sourceTreeFirst: BinaryROMMutationSourceTreeState(
                    status: .refusedSourceTreeAvailable,
                    canUseBinaryOnlyPlan: false,
                    rationale: "A decompilation source tree is available; use source-tree mutation plans instead of binary-only ROM mutation.",
                    sourceCandidates: sourceCandidates
                ),
                operationPreviews: [],
                ignoredOutputGuidance: outputGuidance,
                diagnostics: diagnostics
            )
        }

        let operationPreviews = previews(request: request, data: data, graph: graph)
        diagnostics.append(contentsOf: operationPreviews.flatMap(\.diagnostics))
        if operationPreviews.isEmpty {
            diagnostics.append(
                Diagnostic(
                    severity: .info,
                    code: "BINARY_ROM_MUTATION_NO_OPERATIONS",
                    message: "No byte replacement, pointer repoint, or free-space allocation operations were requested."
                )
            )
        }
        let applyReview = applyReview(base: base, operationPreviews: operationPreviews, diagnostics: diagnostics)

        return BinaryROMMutationDryRunManifest(
            inputPath: inputURL.path,
            profile: index.profile,
            baseROM: base,
            sourceTreeFirst: BinaryROMMutationSourceTreeState(
                status: .binaryOnlyCandidate,
                canUseBinaryOnlyPlan: true,
                rationale: "No matching source-tree candidate was supplied or discovered for this dry run; operation previews remain binary-only and non-applyable."
            ),
            operationPreviews: operationPreviews,
            ignoredOutputGuidance: outputGuidance,
            applyReview: applyReview,
            diagnostics: diagnostics
        )
    }

    private static func previews(
        request: BinaryROMMutationDryRunRequest,
        data: Data,
        graph: BinaryROMGraph
    ) -> [BinaryROMMutationOperationPreview] {
        var previews: [BinaryROMMutationOperationPreview] = []
        var replacementRanges: [(index: Int, start: UInt64, end: UInt64)] = []
        for (index, replacement) in request.replacements.enumerated() {
            let start = UInt64(replacement.offset)
            let end = start + UInt64(replacement.length)
            replacementRanges.append((index: index, start: start, end: end))
        }

        for (index, replacement) in request.replacements.enumerated() {
            previews.append(replacementPreview(index: index, request: replacement, data: data, ranges: replacementRanges))
        }
        for (index, repoint) in request.repoints.enumerated() {
            previews.append(repointPreview(index: index, request: repoint, data: data, graph: graph))
        }
        for (index, allocation) in request.allocations.enumerated() {
            previews.append(allocationPreview(index: index, request: allocation, graph: graph))
        }
        return previews
    }

    private static func replacementPreview(
        index: Int,
        request: BinaryROMMutationReplacementRequest,
        data: Data,
        ranges: [(index: Int, start: UInt64, end: UInt64)]
    ) -> BinaryROMMutationOperationPreview {
        var diagnostics: [Diagnostic] = []
        let replacementData = Data(request.replacementBytes)
        let start = UInt64(request.offset)
        let requestedEnd = start + UInt64(request.length)

        if request.length == 0 {
            diagnostics.append(Diagnostic(severity: .error, code: "BINARY_ROM_MUTATION_RANGE_EMPTY", message: "Replacement \(index) has zero length."))
        }
        if request.length != UInt32(request.replacementBytes.count) {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_REPLACEMENT_LENGTH_MISMATCH",
                    message: "Replacement \(index) declares \(request.length) byte(s), but \(request.replacementBytes.count) replacement byte(s) were provided."
                )
            )
        }
        if requestedEnd > UInt64(data.count) {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_RANGE_OUT_OF_BOUNDS",
                    message: String(format: "Replacement %d range 0x%06X...0x%06llX exceeds the %d-byte ROM.", index, request.offset, requestedEnd, data.count)
                )
            )
        }
        if ranges.contains(where: { other in
            other.index != index && start < other.end && requestedEnd > other.start
        }) {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_REPLACEMENT_OVERLAP",
                    message: "Replacement \(index) overlaps another requested replacement range."
                )
            )
        }
        if overlapsHeader(offset: request.offset, length: request.length) {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_HEADER_REGION_BLOCKED",
                    message: "Replacement \(index) overlaps the fixed GBA header/checksum region; header and checksum repair are out of scope."
                )
            )
        }

        let status: BinaryROMMutationOperationStatus = diagnostics.contains { $0.severity == .error } ? .blocked : .previewOnly
        return BinaryROMMutationOperationPreview(
            id: "replace:\(index):\(request.offset)",
            kind: .replaceBytes,
            status: status,
            summary: String(format: "Dry-run byte replacement at 0x%06X for %u byte(s); no bytes will be written.", request.offset, request.length),
            offset: request.offset,
            length: request.length,
            originalPreviewHex: hexPreview(data: data, offset: request.offset, length: request.length),
            originalSpanSHA1: spanSHA1(data: data, offset: request.offset, length: request.length),
            replacementPreviewHex: hexPreview(bytes: request.replacementBytes),
            replacementHex: compactHex(bytes: request.replacementBytes),
            replacementSHA1: pokemonHackSHA1Hex(replacementData),
            diagnostics: diagnostics
        )
    }

    private static func repointPreview(
        index: Int,
        request: BinaryROMMutationRepointRequest,
        data: Data,
        graph: BinaryROMGraph
    ) -> BinaryROMMutationOperationPreview {
        var diagnostics: [Diagnostic] = []
        let matchingCandidates = graph.pointerCandidates.filter { $0.sourceOffset == request.pointerOffset }
        let candidate = matchingCandidates.first
        if candidate == nil {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_POINTER_CANDIDATE_MISSING",
                    message: String(format: "Pointer repoint %d at 0x%06X was not an accepted graph pointer candidate.", index, request.pointerOffset)
                )
            )
        } else if matchingCandidates.count > 1 {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_POINTER_CANDIDATE_AMBIGUOUS",
                    message: String(format: "Pointer repoint %d at 0x%06X matched multiple graph pointer candidates; future apply must refuse ambiguous pointer identity.", index, request.pointerOffset)
                )
            )
        }
        if let candidate, candidate.rawValue != UInt32(0x0800_0000) &+ candidate.targetOffset {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_POINTER_CANDIDATE_STALE",
                    message: String(format: "Pointer repoint %d at 0x%06X has stale graph identity; raw value and target offset no longer agree.", index, request.pointerOffset)
                )
            )
        }
        if UInt64(request.newTargetOffset) >= UInt64(data.count) {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_POINTER_TARGET_OUT_OF_BOUNDS",
                    message: String(format: "Pointer repoint %d target 0x%06X exceeds the %d-byte ROM; ROM expansion is blocked.", index, request.newTargetOffset, data.count)
                )
            )
        }
        if overlapsHeader(offset: request.pointerOffset, length: 4) {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_HEADER_REGION_BLOCKED",
                    message: "Pointer repoint \(index) would rewrite bytes in the fixed GBA header/checksum region."
                )
            )
        }
        let plannedRawValue = UInt32(0x0800_0000) &+ request.newTargetOffset
        let status: BinaryROMMutationOperationStatus = diagnostics.contains { $0.severity == .error } ? .blocked : .previewOnly
        return BinaryROMMutationOperationPreview(
            id: "repoint:\(index):\(request.pointerOffset)",
            kind: .repointPointer,
            status: status,
            summary: String(format: "Dry-run pointer repoint at 0x%06X to target 0x%06X; no pointer bytes will be written.", request.pointerOffset, request.newTargetOffset),
            offset: request.pointerOffset,
            length: 4,
            pointerSourceOffset: request.pointerOffset,
            oldTargetOffset: candidate?.targetOffset,
            plannedTargetOffset: request.newTargetOffset,
            oldRawValue: candidate?.rawValue,
            plannedRawValue: plannedRawValue,
            diagnostics: diagnostics
        )
    }

    private static func allocationPreview(
        index: Int,
        request: BinaryROMMutationAllocationRequest,
        graph: BinaryROMGraph
    ) -> BinaryROMMutationOperationPreview {
        var diagnostics: [Diagnostic] = [
            Diagnostic(
                severity: .info,
                code: "BINARY_ROM_MUTATION_ROM_EXPANSION_BLOCKED",
                message: "Free-space allocation previews never expand the ROM; only detected fill-byte ranges are considered."
            )
        ]
        if request.byteCount == 0 {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_ALLOCATION_SIZE_INVALID",
                    message: "Allocation \(index) requested zero bytes."
                )
            )
        }
        let selected = request.byteCount == 0 ? nil : graph.freeSpaceRanges.first { range in
            let aligned = alignedOffset(range.offset, alignment: request.alignment)
            let alignedEnd = UInt64(aligned) + UInt64(request.byteCount)
            let rangeEnd = UInt64(range.offset) + UInt64(range.length)
            return aligned >= range.offset && alignedEnd <= rangeEnd
        }
        let selectedOffset = selected.map { alignedOffset($0.offset, alignment: request.alignment) }
        if request.byteCount > 0, selected == nil {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_FREE_SPACE_INSUFFICIENT",
                    message: "No detected free-space range can fit allocation \(index) for \(request.byteCount) byte(s) at \(request.alignment)-byte alignment."
                )
            )
        }
        let status: BinaryROMMutationOperationStatus = diagnostics.contains { $0.severity == .error } ? .blocked : .previewOnly
        return BinaryROMMutationOperationPreview(
            id: "allocate:\(index):\(request.byteCount)",
            kind: .allocateFreeSpace,
            status: status,
            summary: "Dry-run free-space allocation for \(request.byteCount) byte(s) at \(request.alignment)-byte alignment; no bytes are reserved or written.",
            offset: selectedOffset,
            length: request.byteCount,
            allocationByteCount: request.byteCount,
            alignment: request.alignment,
            selectedFreeSpaceOffset: selectedOffset,
            selectedFreeSpaceLength: selected?.length,
            selectedFreeSpaceFillByte: selected?.fillByte,
            diagnostics: diagnostics
        )
    }

    private static func sourceTreeCandidates(
        workspaceRoot: String?,
        romGameCode: String?,
        inputURL: URL,
        fileManager: FileManager
    ) -> [BinaryROMMutationSourceCandidate] {
        guard let workspaceRoot, !workspaceRoot.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        let root = URL(fileURLWithPath: workspaceRoot).standardizedFileURL
        var candidates = [root]
        if let contents = try? fileManager.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) {
            candidates.append(contentsOf: contents.filter { url in
                (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            })
        }

        var seen: Set<String> = []
        var results: [BinaryROMMutationSourceCandidate] = []
        for candidate in candidates {
            let standardized = candidate.standardizedFileURL
            guard standardized.path != inputURL.path else { continue }
            guard seen.insert(standardized.path).inserted else { continue }
            guard let index = try? GameAdapterRegistry.index(path: standardized.path, fileManager: fileManager) else { continue }
            guard index.profile.platform == .gba, index.profile.projectKind == .sourceTree else { continue }
            guard matches(profile: index.profile, gameCode: romGameCode) else { continue }
            results.append(BinaryROMMutationSourceCandidate(index: index))
        }
        return results
    }

    private static func matches(profile: GameProfile, gameCode: String?) -> Bool {
        guard let gameCode else { return true }
        switch gameCode.uppercased() {
        case "BPEE", "BPEP":
            return profile == .pokeemerald || profile == .pokeemeraldExpansion
        case "BPRE", "BPRP", "BPGE", "BPGP":
            return profile == .pokefirered
        case "AXVE", "AXVP", "AXPE", "AXPP":
            return profile == .pokeruby
        default:
            return true
        }
    }

    private static func dryRunDiagnostic() -> Diagnostic {
        Diagnostic(
            severity: .info,
            code: "BINARY_ROM_MUTATION_DRY_RUN_ONLY",
            message: "Binary ROM mutation manifests are dry-run only; canApply is always false and no bytes, files, backups, manifests, exports, or patches are written."
        )
    }

    private static func applyReview(
        base: BinaryROMMutationBaseIdentity,
        operationPreviews: [BinaryROMMutationOperationPreview],
        diagnostics: [Diagnostic]
    ) -> BinaryROMMutationApplyReview {
        let replacementPreviews = operationPreviews.filter { $0.kind == .replaceBytes }
        let hasErrors = diagnostics.contains { $0.severity == .error }
            || operationPreviews.flatMap(\.diagnostics).contains { $0.severity == .error }
        let replacementOnly = !operationPreviews.isEmpty && replacementPreviews.count == operationPreviews.count
        let reviewable = replacementOnly
            && !hasErrors
            && operationPreviews.allSatisfy { $0.status == .previewOnly }
            && replacementPreviews.allSatisfy {
                $0.offset != nil
                    && $0.length != nil
                    && $0.originalSpanSHA1 != nil
                    && $0.replacementHex != nil
                    && $0.replacementSHA1 != nil
            }
        let token = reviewable ? binaryROMMutationReviewToken(base: base, replacements: replacementPreviews) : nil
        let rationale: String
        if reviewable {
            rationale = "This dry-run is reviewable for the replace-only CLI apply path; copy the review token into rom-mutation-apply after reviewing base identity and byte spans."
        } else if operationPreviews.isEmpty {
            rationale = "No byte replacement operations are available to review for apply."
        } else if !replacementOnly {
            rationale = "Only explicit byte replacement operations can be applied by this first binary writer row."
        } else {
            rationale = "One or more diagnostics must be resolved before a binary replacement apply can be reviewed."
        }
        return BinaryROMMutationApplyReview(
            isReviewable: reviewable,
            reviewToken: token,
            confirmationArgument: token.map { "--confirm \($0)" },
            operationCount: operationPreviews.count,
            operationKinds: operationPreviews.map(\.kind),
            blockedApplyActions: [
                "pointer repoint apply",
                "free-space allocation apply",
                "checksum repair",
                "emulator launch",
                "app apply UI",
                "source mutation",
                "ROM export",
                "patched-copy output"
            ],
            rationale: rationale
        )
    }

    private static func sanitizedStem(for url: URL) -> String {
        let raw = url.deletingPathExtension().lastPathComponent
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let scalars = raw.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let stem = String(scalars).trimmingCharacters(in: CharacterSet(charactersIn: "-_"))
        return stem.isEmpty ? "binary-rom" : stem
    }

    private static func overlapsHeader(offset: UInt32, length: UInt32) -> Bool {
        guard length > 0 else { return false }
        return offset < 0xC0 && UInt64(offset) + UInt64(length) > 0
    }

    private static func alignedOffset(_ offset: UInt32, alignment: UInt32) -> UInt32 {
        let safeAlignment = max(alignment, 1)
        let remainder = offset % safeAlignment
        return remainder == 0 ? offset : offset &+ (safeAlignment - remainder)
    }

    private static func hexPreview(data: Data, offset: UInt32, length: UInt32) -> String? {
        guard let start = Int(exactly: offset), let requestedLength = Int(exactly: length) else { return nil }
        guard start >= 0, start < data.count, requestedLength > 0 else { return nil }
        let end = min(data.count, start + requestedLength, start + 16)
        return hexPreview(bytes: Array(data[start..<end]))
    }

    private static func hexPreview(bytes: [UInt8]) -> String? {
        guard !bytes.isEmpty else { return nil }
        return bytes.prefix(16).map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    private static func compactHex(bytes: [UInt8]) -> String? {
        guard !bytes.isEmpty else { return nil }
        return bytes.map { String(format: "%02X", $0) }.joined()
    }

    private static func spanSHA1(data: Data, offset: UInt32, length: UInt32) -> String? {
        guard let start = Int(exactly: offset), let requestedLength = Int(exactly: length) else { return nil }
        guard start >= 0, requestedLength > 0, start + requestedLength <= data.count else { return nil }
        return pokemonHackSHA1Hex(data.subdata(in: start..<(start + requestedLength)))
    }
}

public enum BinaryROMMutationApplier {
    public static func apply(
        path: String,
        manifestPath: String?,
        workspaceRoot: String?,
        confirmationToken: String?,
        fileManager: FileManager = .default
    ) -> BinaryROMMutationApplyResult {
        let inputURL = URL(fileURLWithPath: path).standardizedFileURL
        guard let manifestPath, !manifestPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return blocked(
                inputPath: inputURL.path,
                diagnostics: [
                    Diagnostic(
                        severity: .error,
                        code: "BINARY_ROM_MUTATION_APPLY_MANIFEST_REQUIRED",
                        message: "Binary ROM mutation apply requires --manifest <dry-run-json>."
                    )
                ]
            )
        }
        let manifestURL = URL(fileURLWithPath: manifestPath).standardizedFileURL
        let manifestData: Data
        do {
            manifestData = try Data(contentsOf: manifestURL)
        } catch {
            return blocked(
                inputPath: inputURL.path,
                diagnostics: [
                    Diagnostic(
                        severity: .error,
                        code: "BINARY_ROM_MUTATION_APPLY_MANIFEST_UNREADABLE",
                        message: "Could not read dry-run manifest at \(manifestURL.path): \(error.localizedDescription)"
                    )
                ]
            )
        }
        let manifest: BinaryROMMutationDryRunManifest
        do {
            manifest = try JSONDecoder().decode(BinaryROMMutationDryRunManifest.self, from: manifestData)
        } catch {
            return blocked(
                inputPath: inputURL.path,
                diagnostics: [
                    Diagnostic(
                        severity: .error,
                        code: "BINARY_ROM_MUTATION_APPLY_MANIFEST_DECODE_FAILED",
                        message: "Could not decode binary ROM mutation dry-run manifest at \(manifestURL.path): \(error.localizedDescription)"
                    )
                ]
            )
        }

        return apply(
            path: inputURL.path,
            dryRunManifest: manifest,
            dryRunManifestPath: manifestURL.path,
            dryRunManifestData: manifestData,
            workspaceRoot: workspaceRoot,
            confirmationToken: confirmationToken,
            fileManager: fileManager
        )
    }

    public static func apply(
        path: String,
        dryRunManifest manifest: BinaryROMMutationDryRunManifest,
        dryRunManifestPath: String,
        dryRunManifestData: Data,
        workspaceRoot: String?,
        confirmationToken: String?,
        fileManager: FileManager = .default
    ) -> BinaryROMMutationApplyResult {
        let inputURL = URL(fileURLWithPath: path).standardizedFileURL
        var diagnostics: [Diagnostic] = []
        let trimmedWorkspaceRoot = workspaceRoot?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedWorkspaceRoot.isEmpty else {
            return blocked(
                inputPath: inputURL.path,
                diagnostics: [
                    Diagnostic(
                        severity: .error,
                        code: "BINARY_ROM_MUTATION_APPLY_WORKSPACE_ROOT_REQUIRED",
                        message: "Binary ROM mutation apply requires --workspace-root so source-tree-first refusal can be rechecked immediately before writing."
                    )
                ]
            )
        }
        let workspaceURL = URL(fileURLWithPath: trimmedWorkspaceRoot).standardizedFileURL

        guard let baseBeforeReview = manifest.baseROM else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_APPLY_BASE_IDENTITY_MISSING",
                    message: "Dry-run manifest does not contain base ROM identity."
                )
            )
            return blocked(inputPath: inputURL.path, diagnostics: diagnostics)
        }

        let manifestErrors = manifest.diagnostics.filter { $0.severity == .error }
            + manifest.operationPreviews.flatMap(\.diagnostics).filter { $0.severity == .error }
        if !manifestErrors.isEmpty {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_APPLY_MANIFEST_ERRORS",
                    message: "Dry-run manifest still contains error diagnostics; review and regenerate the manifest before applying."
                )
            )
            diagnostics.append(contentsOf: manifestErrors)
        }

        if manifest.inputPath != inputURL.path {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_APPLY_INPUT_PATH_MISMATCH",
                    message: "Dry-run manifest was created for \(manifest.inputPath), not \(inputURL.path)."
                )
            )
        }

        let replacementPreviews = manifest.operationPreviews.filter { $0.kind == .replaceBytes }
        if replacementPreviews.isEmpty {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_APPLY_NO_REPLACEMENTS",
                    message: "Binary ROM mutation apply requires at least one explicit byte replacement."
                )
            )
        }
        if replacementPreviews.count != manifest.operationPreviews.count {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_APPLY_NON_REPLACEMENT_BLOCKED",
                    message: "This CLI apply path only supports replaceBytes operations; pointer repoint and free-space allocation apply remain blocked."
                )
            )
        }
        if replacementPreviews.contains(where: { $0.status != .previewOnly }) {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_APPLY_BLOCKED_PREVIEW",
                    message: "One or more replacement previews are blocked and cannot be applied."
                )
            )
        }
        diagnostics.append(contentsOf: overlapDiagnostics(for: replacementPreviews))

        let replacements = replacementPreviews.compactMap(Self.replacementRequest(from:))
        if replacements.count != replacementPreviews.count {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_APPLY_REPLACEMENT_IDENTITY_MISSING",
                    message: "One or more replacement previews are missing offset, length, or full replacement hex identity."
                )
            )
        }

        guard let review = manifest.applyReview,
              review.isReviewable,
              let manifestReviewToken = review.reviewToken
        else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_APPLY_MANIFEST_NOT_REVIEWABLE",
                    message: "Dry-run manifest does not include a reviewable replace-only apply token."
                )
            )
            return blocked(inputPath: inputURL.path, baseBefore: baseBeforeReview, diagnostics: diagnostics)
        }
        let expectedReviewToken = binaryROMMutationReviewToken(base: baseBeforeReview, replacements: replacementPreviews)
        if manifestReviewToken != expectedReviewToken {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_APPLY_REVIEW_TOKEN_STALE",
                    message: "Dry-run manifest review token no longer matches its base identity and replacement set."
                )
            )
        }
        guard let confirmationToken, confirmationToken == manifestReviewToken else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_APPLY_CONFIRMATION_MISMATCH",
                    message: "Binary ROM mutation apply requires the exact review token from the dry-run manifest."
                )
            )
            return blocked(inputPath: inputURL.path, baseBefore: baseBeforeReview, diagnostics: diagnostics)
        }

        let freshManifest = BinaryROMMutationDryRunManifestBuilder.build(
            path: inputURL.path,
            request: BinaryROMMutationDryRunRequest(
                expectedSHA1: baseBeforeReview.sha1,
                workspaceRoot: workspaceURL.path,
                replacements: replacements
            ),
            fileManager: fileManager
        )
        diagnostics.append(contentsOf: freshManifest.diagnostics)
        guard let freshBase = freshManifest.baseROM else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_APPLY_FRESH_BASE_MISSING",
                    message: "Could not re-read selected base ROM immediately before apply."
                )
            )
            return blocked(inputPath: inputURL.path, baseBefore: baseBeforeReview, diagnostics: diagnostics)
        }
        if !freshManifest.sourceTreeFirst.canUseBinaryOnlyPlan {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_APPLY_SOURCE_TREE_AVAILABLE_REFUSED",
                    message: "Binary-only apply is refused because a source-tree edit path is available or the selected input is not a standalone binary ROM."
                )
            )
        }
        diagnostics.append(contentsOf: baseDriftDiagnostics(expected: baseBeforeReview, actual: freshBase))
        diagnostics.append(contentsOf: originalByteDiagnostics(expected: replacementPreviews, actual: freshManifest.operationPreviews))
        diagnostics.append(contentsOf: freshManifest.operationPreviews.flatMap(\.diagnostics).filter { $0.severity == .error })

        let tokenSuffix = binaryROMMutationTokenSuffix(manifestReviewToken)
        let relativeRoot = ".pokemonhackstudio/rom-mutations/\(binaryROMMutationSanitizedStem(for: inputURL))/\(binaryROMMutationTimestamp())-\(tokenSuffix)"
        let backupRelativePath = "\(relativeRoot)/\(inputURL.deletingPathExtension().lastPathComponent)-original.gba"
        let applyManifestRelativePath = "\(relativeRoot)/apply-manifest.json"
        diagnostics.append(contentsOf: SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
            backupRelativePath,
            root: workspaceURL,
            fileManager: fileManager,
            codePrefix: "BINARY_ROM_MUTATION_APPLY_BACKUP",
            subject: "Binary ROM mutation backup path"
        ))
        diagnostics.append(contentsOf: SourceTreeWriteSafety.diagnosticsForRelativeWritePath(
            applyManifestRelativePath,
            root: workspaceURL,
            fileManager: fileManager,
            codePrefix: "BINARY_ROM_MUTATION_APPLY_MANIFEST",
            subject: "Binary ROM mutation apply manifest path"
        ))

        if diagnostics.contains(where: { $0.severity == .error }) {
            return blocked(inputPath: inputURL.path, baseBefore: freshBase, diagnostics: diagnostics)
        }

        let originalData: Data
        do {
            originalData = try Data(contentsOf: inputURL)
        } catch {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_APPLY_BASE_READ_FAILED",
                    message: "Could not read base ROM before apply: \(error.localizedDescription)"
                )
            )
            return blocked(inputPath: inputURL.path, baseBefore: freshBase, diagnostics: diagnostics)
        }
        var mutatedBytes = Array(originalData)
        for replacement in replacements {
            let start = Int(replacement.offset)
            let end = start + Int(replacement.length)
            mutatedBytes.replaceSubrange(start..<end, with: replacement.replacementBytes)
        }
        let mutatedData = Data(mutatedBytes)
        let afterGraph = BinaryROMGraphBuilder.build(path: inputURL.path, data: mutatedData)
        let baseAfter = BinaryROMMutationBaseIdentity(path: inputURL.path, data: mutatedData, graph: afterGraph)
        let appliedReplacements = replacementPreviews.map { preview in
            BinaryROMMutationAppliedReplacement(
                id: preview.id,
                offset: preview.offset ?? 0,
                length: preview.length ?? 0,
                originalPreviewHex: preview.originalPreviewHex,
                originalSpanSHA1: preview.originalSpanSHA1,
                replacementPreviewHex: preview.replacementPreviewHex,
                replacementSHA1: preview.replacementSHA1
            )
        }
        let backupURL = workspaceURL.appendingPathComponent(backupRelativePath).standardizedFileURL
        let applyManifestURL = workspaceURL.appendingPathComponent(applyManifestRelativePath).standardizedFileURL
        let confirmation = BinaryROMMutationApplyConfirmation(
            method: "dry-run-review-token",
            reviewToken: manifestReviewToken,
            dryRunManifestPath: dryRunManifestPath,
            dryRunManifestSHA1: pokemonHackSHA1Hex(dryRunManifestData)
        )
        let successDiagnostics = diagnostics + [
            Diagnostic(
                severity: .info,
                code: "BINARY_ROM_MUTATION_APPLY_IN_PLACE_COMPLETED",
                message: "Applied \(appliedReplacements.count) explicit byte replacement(s) in place to \(inputURL.path); backup and manifest are under \(relativeRoot)."
            )
        ]
        let applyManifest = BinaryROMMutationApplyManifest(
            inputPath: inputURL.path,
            backupPath: backupURL.path,
            baseBefore: freshBase,
            baseAfter: baseAfter,
            replacements: appliedReplacements,
            confirmation: confirmation,
            diagnostics: successDiagnostics
        )

        do {
            try fileManager.createDirectory(at: backupURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try fileManager.copyItem(at: inputURL, to: backupURL)
            try mutatedData.write(to: inputURL, options: .atomic)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(applyManifest).write(to: applyManifestURL, options: .atomic)
        } catch {
            let failureDiagnostics = diagnostics + [
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_APPLY_WRITE_FAILED",
                    message: "Binary ROM mutation apply failed while writing backup, ROM bytes, or manifest: \(error.localizedDescription)"
                )
            ]
            return blocked(inputPath: inputURL.path, baseBefore: freshBase, diagnostics: failureDiagnostics)
        }

        return BinaryROMMutationApplyResult(
            status: .applied,
            inputPath: inputURL.path,
            backupPath: backupURL.path,
            manifestPath: applyManifestURL.path,
            baseBefore: freshBase,
            baseAfter: baseAfter,
            appliedReplacements: appliedReplacements,
            diagnostics: successDiagnostics,
            manifest: applyManifest
        )
    }

    private static func blocked(
        inputPath: String,
        baseBefore: BinaryROMMutationBaseIdentity? = nil,
        diagnostics: [Diagnostic]
    ) -> BinaryROMMutationApplyResult {
        BinaryROMMutationApplyResult(status: .blocked, inputPath: inputPath, baseBefore: baseBefore, diagnostics: diagnostics)
    }

    private static func replacementRequest(
        from preview: BinaryROMMutationOperationPreview
    ) -> BinaryROMMutationReplacementRequest? {
        guard let offset = preview.offset,
              let length = preview.length,
              let replacementHex = preview.replacementHex,
              let replacementBytes = binaryROMMutationParseHex(replacementHex)
        else {
            return nil
        }
        return BinaryROMMutationReplacementRequest(offset: offset, length: length, replacementBytes: replacementBytes)
    }

    private static func overlapDiagnostics(for previews: [BinaryROMMutationOperationPreview]) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        let ranges = previews.enumerated().compactMap { index, preview -> (index: Int, start: UInt64, end: UInt64)? in
            guard let offset = preview.offset, let length = preview.length else { return nil }
            return (index: index, start: UInt64(offset), end: UInt64(offset) + UInt64(length))
        }
        for range in ranges where ranges.contains(where: { other in
            other.index != range.index && range.start < other.end && range.end > other.start
        }) {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "BINARY_ROM_MUTATION_APPLY_REPLACEMENT_OVERLAP",
                    message: "Replacement \(range.index) overlaps another requested replacement range."
                )
            )
        }
        return diagnostics
    }

    private static func baseDriftDiagnostics(
        expected: BinaryROMMutationBaseIdentity,
        actual: BinaryROMMutationBaseIdentity
    ) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        if expected.sha1 != actual.sha1 {
            diagnostics.append(Diagnostic(severity: .error, code: "BINARY_ROM_MUTATION_APPLY_BASE_SHA1_DRIFT", message: "Base SHA1 drifted from \(expected.sha1) to \(actual.sha1)."))
        }
        if expected.crc32 != actual.crc32 {
            diagnostics.append(Diagnostic(severity: .error, code: "BINARY_ROM_MUTATION_APPLY_BASE_CRC32_DRIFT", message: "Base CRC32 drifted from \(expected.crc32) to \(actual.crc32)."))
        }
        if expected.sizeBytes != actual.sizeBytes {
            diagnostics.append(Diagnostic(severity: .error, code: "BINARY_ROM_MUTATION_APPLY_BASE_SIZE_DRIFT", message: "Base size drifted from \(expected.sizeBytes) to \(actual.sizeBytes) byte(s)."))
        }
        if expected.title != actual.title
            || expected.gameCode != actual.gameCode
            || expected.makerCode != actual.makerCode
            || expected.revision != actual.revision
            || expected.headerComplementChecksum != actual.headerComplementChecksum
            || expected.expectedHeaderComplementChecksum != actual.expectedHeaderComplementChecksum
            || expected.isHeaderComplementChecksumValid != actual.isHeaderComplementChecksumValid
        {
            diagnostics.append(Diagnostic(severity: .error, code: "BINARY_ROM_MUTATION_APPLY_HEADER_DRIFT", message: "Base GBA header facts changed after dry-run review."))
        }
        return diagnostics
    }

    private static func originalByteDiagnostics(
        expected: [BinaryROMMutationOperationPreview],
        actual: [BinaryROMMutationOperationPreview]
    ) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        let actualByID = Dictionary(uniqueKeysWithValues: actual.map { ($0.id, $0) })
        for preview in expected {
            guard let actualPreview = actualByID[preview.id] else {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "BINARY_ROM_MUTATION_APPLY_ORIGINAL_BYTES_MISSING",
                        message: "Replacement \(preview.id) could not be revalidated against the current ROM bytes."
                    )
                )
                continue
            }
            if preview.originalSpanSHA1 != actualPreview.originalSpanSHA1 {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "BINARY_ROM_MUTATION_APPLY_ORIGINAL_BYTES_MISMATCH",
                        message: "Replacement \(preview.id) original bytes no longer match the dry-run review."
                    )
                )
            }
        }
        return diagnostics
    }
}

private func binaryROMMutationReviewToken(
    base: BinaryROMMutationBaseIdentity,
    replacements: [BinaryROMMutationOperationPreview]
) -> String {
    var lines = [
        "binary-rom-replace-apply-v1",
        "base-sha1:\(base.sha1)",
        "base-crc32:\(base.crc32)",
        "base-size:\(base.sizeBytes)",
        "base-title:\(base.title ?? "")",
        "base-game-code:\(base.gameCode ?? "")",
        "base-maker-code:\(base.makerCode ?? "")",
        "base-revision:\(base.revision.map(String.init) ?? "")",
        "base-header-complement:\(base.headerComplementChecksum.map(String.init) ?? "")",
        "base-header-expected:\(base.expectedHeaderComplementChecksum.map(String.init) ?? "")",
        "base-header-valid:\(base.isHeaderComplementChecksumValid.map(String.init) ?? "")"
    ]
    for replacement in replacements {
        lines.append([
            "replace",
            String(replacement.offset ?? 0),
            String(replacement.length ?? 0),
            replacement.originalSpanSHA1 ?? "",
            replacement.replacementSHA1 ?? "",
            replacement.replacementHex ?? ""
        ].joined(separator: ":"))
    }
    return "romreplace-\(pokemonHackSHA1Hex(Data(lines.joined(separator: "\n").utf8)).prefix(24))"
}

private func binaryROMMutationParseHex(_ text: String) -> [UInt8]? {
    let compact = text.filter { character in
        character.isHexDigit
    }
    guard compact.count > 0, compact.count % 2 == 0 else { return nil }
    var bytes: [UInt8] = []
    var index = compact.startIndex
    while index < compact.endIndex {
        let next = compact.index(index, offsetBy: 2)
        guard let byte = UInt8(compact[index..<next], radix: 16) else { return nil }
        bytes.append(byte)
        index = next
    }
    return bytes
}

private func binaryROMMutationSanitizedStem(for url: URL) -> String {
    let raw = url.deletingPathExtension().lastPathComponent
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
    let scalars = raw.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
    let stem = String(scalars).trimmingCharacters(in: CharacterSet(charactersIn: "-_"))
    return stem.isEmpty ? "binary-rom" : stem
}

private func binaryROMMutationTokenSuffix(_ token: String) -> String {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
    let scalars = token.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
    return String(scalars).suffix(12).isEmpty ? "confirmed" : String(String(scalars).suffix(12))
}

private func binaryROMMutationTimestamp() -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
    return "\(formatter.string(from: Date()))-\(UUID().uuidString.prefix(8))"
}
