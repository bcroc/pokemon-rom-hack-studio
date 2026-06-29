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
        relativeBackupRoot = ".pokemonhackstudio/backups"
        guidance = [
            "Dry-run manifests report ignored future output paths only.",
            "No backup, manifest, patched ROM, export artifact, checksum repair, or byte write is created.",
            "Future binary mutation artifacts must stay under ignored .pokemonhackstudio/rom-mutations/ roots."
        ]
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
    public let replacementPreviewHex: String?
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
        replacementPreviewHex: String? = nil,
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
        self.replacementPreviewHex = replacementPreviewHex
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
    public let diagnostics: [Diagnostic]

    public init(
        inputPath: String,
        profile: GameProfile,
        baseROM: BinaryROMMutationBaseIdentity?,
        sourceTreeFirst: BinaryROMMutationSourceTreeState,
        operationPreviews: [BinaryROMMutationOperationPreview],
        ignoredOutputGuidance: BinaryROMMutationIgnoredOutputGuidance,
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
        self.diagnostics = diagnostics
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
            replacementPreviewHex: hexPreview(bytes: request.replacementBytes),
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
}
