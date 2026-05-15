import Foundation

public enum ROMAssetMigrationFamily: String, Codable, Equatable, CaseIterable {
    case pokemonSprites
    case trainerSprites
    case icons
    case footprints
    case tilesets
    case palettes
    case tilemaps
}

public struct ROMAssetMigrationPreviewSample: Codable, Equatable, Identifiable {
    public var id: String { "\(kind):\(offset)" }

    public let kind: String
    public let offset: UInt32
    public let length: UInt32
    public let confidence: String
    public let detail: String

    public init(kind: String, offset: UInt32, length: UInt32, confidence: String, detail: String) {
        self.kind = kind
        self.offset = offset
        self.length = length
        self.confidence = confidence
        self.detail = detail
    }
}

public struct ROMAssetMigrationPreviewMetadata: Codable, Equatable {
    public let tileCandidateCount: Int
    public let paletteCandidateCount: Int
    public let tilemapCandidateCount: Int
    public let pointerCandidateCount: Int
    public let freeSpaceRangeCount: Int
    public let samples: [ROMAssetMigrationPreviewSample]

    public init(
        tileCandidateCount: Int,
        paletteCandidateCount: Int,
        tilemapCandidateCount: Int,
        pointerCandidateCount: Int,
        freeSpaceRangeCount: Int,
        samples: [ROMAssetMigrationPreviewSample]
    ) {
        self.tileCandidateCount = tileCandidateCount
        self.paletteCandidateCount = paletteCandidateCount
        self.tilemapCandidateCount = tilemapCandidateCount
        self.pointerCandidateCount = pointerCandidateCount
        self.freeSpaceRangeCount = freeSpaceRangeCount
        self.samples = samples
    }
}

public struct ROMAssetMigrationBlockedTarget: Codable, Equatable, Identifiable {
    public var id: String { "\(family.rawValue):\(targetPath)" }

    public let family: ROMAssetMigrationFamily
    public let targetPath: String
    public let reason: String
    public let requiredFutureRow: String

    public init(
        family: ROMAssetMigrationFamily,
        targetPath: String,
        reason: String,
        requiredFutureRow: String = "future ignored-export row"
    ) {
        self.family = family
        self.targetPath = targetPath
        self.reason = reason
        self.requiredFutureRow = requiredFutureRow
    }
}

public struct ROMAssetMigrationFamilyPlan: Codable, Equatable, Identifiable {
    public var id: String { family.rawValue }

    public let family: ROMAssetMigrationFamily
    public let title: String
    public let status: MigrationCoverageStatus
    public let confidence: String
    public let currentSurface: String
    public let sourceMigrationTarget: String
    public let supportedActions: [String]
    public let blockedActions: [String]
    public let blockedTargets: [ROMAssetMigrationBlockedTarget]
    public let previewMetadata: ROMAssetMigrationPreviewMetadata
    public let diagnostics: [Diagnostic]

    public init(
        family: ROMAssetMigrationFamily,
        title: String,
        status: MigrationCoverageStatus,
        confidence: String,
        currentSurface: String,
        sourceMigrationTarget: String,
        supportedActions: [String],
        blockedActions: [String],
        blockedTargets: [ROMAssetMigrationBlockedTarget],
        previewMetadata: ROMAssetMigrationPreviewMetadata,
        diagnostics: [Diagnostic] = []
    ) {
        self.family = family
        self.title = title
        self.status = status
        self.confidence = confidence
        self.currentSurface = currentSurface
        self.sourceMigrationTarget = sourceMigrationTarget
        self.supportedActions = supportedActions
        self.blockedActions = blockedActions
        self.blockedTargets = blockedTargets
        self.previewMetadata = previewMetadata
        self.diagnostics = diagnostics
    }
}

public struct ROMAssetMigrationPlanSummary: Codable, Equatable {
    public let familyPlanCount: Int
    public let highConfidenceFamilyCount: Int
    public let blockedTargetCount: Int
    public let tileCandidateCount: Int
    public let paletteCandidateCount: Int
    public let tilemapCandidateCount: Int

    public init(familyPlans: [ROMAssetMigrationFamilyPlan]) {
        familyPlanCount = familyPlans.count
        highConfidenceFamilyCount = familyPlans.filter { $0.confidence == "high" }.count
        blockedTargetCount = familyPlans.flatMap(\.blockedTargets).count
        tileCandidateCount = familyPlans.map(\.previewMetadata.tileCandidateCount).max() ?? 0
        paletteCandidateCount = familyPlans.map(\.previewMetadata.paletteCandidateCount).max() ?? 0
        tilemapCandidateCount = familyPlans.map(\.previewMetadata.tilemapCandidateCount).max() ?? 0
    }
}

public struct ROMAssetMigrationPlanReport: Codable, Equatable {
    public let root: SourceLocation
    public let profile: GameProfile
    public let platform: GamePlatform
    public let projectKind: ProjectKind
    public let gameCode: String?
    public let gameFamily: GenIIIGameFamily
    public let familyConfidence: String
    public let revision: UInt8?
    public let revisionConfidence: String
    public let coverageEntry: MigrationCoverageEntry?
    public let summary: ROMAssetMigrationPlanSummary
    public let familyPlans: [ROMAssetMigrationFamilyPlan]
    public let diagnostics: [Diagnostic]
    public let isReadOnly: Bool
    public let extractionEnabled: Bool
    public let exportEnabled: Bool

    public init(
        root: SourceLocation,
        profile: GameProfile,
        platform: GamePlatform,
        projectKind: ProjectKind,
        gameCode: String?,
        gameFamily: GenIIIGameFamily,
        familyConfidence: String,
        revision: UInt8?,
        revisionConfidence: String,
        coverageEntry: MigrationCoverageEntry?,
        familyPlans: [ROMAssetMigrationFamilyPlan],
        diagnostics: [Diagnostic],
        isReadOnly: Bool = true,
        extractionEnabled: Bool = false,
        exportEnabled: Bool = false
    ) {
        self.root = root
        self.profile = profile
        self.platform = platform
        self.projectKind = projectKind
        self.gameCode = gameCode
        self.gameFamily = gameFamily
        self.familyConfidence = familyConfidence
        self.revision = revision
        self.revisionConfidence = revisionConfidence
        self.coverageEntry = coverageEntry
        self.summary = ROMAssetMigrationPlanSummary(familyPlans: familyPlans)
        self.familyPlans = familyPlans
        self.diagnostics = diagnostics
        self.isReadOnly = isReadOnly
        self.extractionEnabled = extractionEnabled
        self.exportEnabled = exportEnabled
    }
}

public enum ROMAssetMigrationPlanBuilder {
    public static func build(path: String, fileManager: FileManager = .default) throws -> ROMAssetMigrationPlanReport {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        let index = try GameAdapterRegistry.index(path: url.path, fileManager: fileManager)
        guard index.profile == .binaryROM else {
            throw PokemonHackCoreError.unsupportedProject(url.path)
        }

        let data = try Data(contentsOf: url)
        let graph = BinaryROMGraphBuilder.build(path: url.path, data: data)
        let coverage = MigrationCoverageReportBuilder.build(index: index, fileManager: fileManager)
        let coverageEntry = coverage.entries.first { $0.domain == .graphics && $0.recommendedFutureRow == "PHS-T92" }
        let metadata = previewMetadata(data: data, graph: graph)
        let gameFamily = family(for: graph.image.gameCode)
        let familyConfidence = gameFamily == .unknown ? "low" : "high"
        let revisionConfidence = graph.image.version == nil ? "low" : "high"
        let familyPlans = plans(
            metadata: metadata,
            gameFamily: gameFamily,
            familyConfidence: familyConfidence,
            coverageEntry: coverageEntry
        )
        let diagnostics = coverage.diagnostics + graph.diagnostics + diagnostics(
            image: graph.image,
            gameFamily: gameFamily,
            metadata: metadata,
            coverageEntry: coverageEntry
        )

        return ROMAssetMigrationPlanReport(
            root: index.root,
            profile: index.profile,
            platform: index.platform,
            projectKind: index.projectKind,
            gameCode: graph.image.gameCode,
            gameFamily: gameFamily,
            familyConfidence: familyConfidence,
            revision: graph.image.version,
            revisionConfidence: revisionConfidence,
            coverageEntry: coverageEntry,
            familyPlans: familyPlans,
            diagnostics: diagnostics
        )
    }

    private static func plans(
        metadata: ROMAssetMigrationPreviewMetadata,
        gameFamily: GenIIIGameFamily,
        familyConfidence: String,
        coverageEntry: MigrationCoverageEntry?
    ) -> [ROMAssetMigrationFamilyPlan] {
        let sourcePrefix = sourceTargetPrefix(for: gameFamily)
        let surface = coverageEntry?.currentSurface ?? "migration-coverage, rom-inspect"
        let supported = ["read ROM header", "sample graphics-shaped byte ranges", "preview source migration targets"]
        let blocked = ["asset extraction", "decompression", "format conversion", "source write", "ignored export write", "ROM write"]

        return [
            plan(
                family: .pokemonSprites,
                title: "Pokemon Sprite Sheets",
                confidence: familyConfidence,
                surface: surface,
                target: "\(sourcePrefix)/graphics/pokemon/<species>/front.png and palette files",
                supported: supported,
                blocked: blocked,
                blockedTargets: [
                    blockedTarget(.pokemonSprites, "\(sourcePrefix)/graphics/pokemon/<species>/front.png"),
                    blockedTarget(.pokemonSprites, "\(sourcePrefix)/graphics/pokemon/<species>/back.png"),
                    blockedTarget(.pokemonSprites, "\(sourcePrefix)/graphics/pokemon/<species>/normal.pal")
                ],
                metadata: metadata
            ),
            plan(
                family: .trainerSprites,
                title: "Trainer Sprite Sheets",
                confidence: familyConfidence,
                surface: surface,
                target: "\(sourcePrefix)/graphics/trainers/<trainer>.png and palette files",
                supported: supported,
                blocked: blocked,
                blockedTargets: [
                    blockedTarget(.trainerSprites, "\(sourcePrefix)/graphics/trainers/<trainer>.png"),
                    blockedTarget(.trainerSprites, "\(sourcePrefix)/graphics/trainers/palettes/<trainer>.pal")
                ],
                metadata: metadata
            ),
            plan(
                family: .icons,
                title: "Pokemon Icons",
                confidence: familyConfidence,
                surface: surface,
                target: "\(sourcePrefix)/graphics/pokemon/<species>/icon.png",
                supported: supported,
                blocked: blocked,
                blockedTargets: [
                    blockedTarget(.icons, "\(sourcePrefix)/graphics/pokemon/<species>/icon.png")
                ],
                metadata: metadata
            ),
            plan(
                family: .footprints,
                title: "Pokemon Footprints",
                confidence: familyConfidence,
                surface: surface,
                target: "\(sourcePrefix)/graphics/pokemon/<species>/footprint.png",
                supported: supported,
                blocked: blocked,
                blockedTargets: [
                    blockedTarget(.footprints, "\(sourcePrefix)/graphics/pokemon/<species>/footprint.png")
                ],
                metadata: metadata
            ),
            plan(
                family: .tilesets,
                title: "Tilesets And Metatiles",
                confidence: familyConfidence,
                surface: surface,
                target: "\(sourcePrefix)/data/tilesets/** source graphics, metatiles, and attributes",
                supported: supported,
                blocked: blocked,
                blockedTargets: [
                    blockedTarget(.tilesets, "\(sourcePrefix)/data/tilesets/<name>/tiles.png"),
                    blockedTarget(.tilesets, "\(sourcePrefix)/data/tilesets/<name>/metatiles.bin"),
                    blockedTarget(.tilesets, "\(sourcePrefix)/data/tilesets/<name>/metatile_attributes.bin")
                ],
                metadata: metadata
            ),
            plan(
                family: .palettes,
                title: "Palettes",
                confidence: metadata.paletteCandidateCount > 0 ? "medium" : "low",
                surface: surface,
                target: "\(sourcePrefix)/graphics/**.pal",
                supported: supported,
                blocked: blocked,
                blockedTargets: [
                    blockedTarget(.palettes, "\(sourcePrefix)/graphics/**/<asset>.pal")
                ],
                metadata: metadata
            ),
            plan(
                family: .tilemaps,
                title: "Tilemaps",
                confidence: metadata.tilemapCandidateCount > 0 ? "medium" : "low",
                surface: surface,
                target: "\(sourcePrefix)/graphics/**.tilemap or source layout data",
                supported: supported,
                blocked: blocked,
                blockedTargets: [
                    blockedTarget(.tilemaps, "\(sourcePrefix)/graphics/**/<asset>.tilemap")
                ],
                metadata: metadata
            )
        ]
    }

    private static func plan(
        family: ROMAssetMigrationFamily,
        title: String,
        confidence: String,
        surface: String,
        target: String,
        supported: [String],
        blocked: [String],
        blockedTargets: [ROMAssetMigrationBlockedTarget],
        metadata: ROMAssetMigrationPreviewMetadata
    ) -> ROMAssetMigrationFamilyPlan {
        ROMAssetMigrationFamilyPlan(
            family: family,
            title: title,
            status: .migrationPlanOnly,
            confidence: confidence,
            currentSurface: surface,
            sourceMigrationTarget: target,
            supportedActions: supported,
            blockedActions: blocked,
            blockedTargets: blockedTargets,
            previewMetadata: metadata
        )
    }

    private static func blockedTarget(_ family: ROMAssetMigrationFamily, _ path: String) -> ROMAssetMigrationBlockedTarget {
        ROMAssetMigrationBlockedTarget(
            family: family,
            targetPath: path,
            reason: "Read-only PHS-T92 planning does not extract, convert, export, or write source assets."
        )
    }

    private static func previewMetadata(data: Data, graph: BinaryROMGraph) -> ROMAssetMigrationPreviewMetadata {
        let tileSamples = graphicsTileSamples(data: data)
        let paletteSamples = paletteSamples(data: data)
        let tilemapSamples = tilemapSamples(data: data)
        let samples = Array((tileSamples + paletteSamples + tilemapSamples).sorted { lhs, rhs in
            lhs.offset == rhs.offset ? lhs.kind < rhs.kind : lhs.offset < rhs.offset
        }.prefix(16))

        return ROMAssetMigrationPreviewMetadata(
            tileCandidateCount: tileSamples.count,
            paletteCandidateCount: paletteSamples.count,
            tilemapCandidateCount: tilemapSamples.count,
            pointerCandidateCount: graph.pointerCandidates.count,
            freeSpaceRangeCount: graph.freeSpaceRanges.count,
            samples: samples
        )
    }

    private static func graphicsTileSamples(data: Data) -> [ROMAssetMigrationPreviewSample] {
        guard data.count >= 32 else { return [] }
        var samples: [ROMAssetMigrationPreviewSample] = []
        for offset in stride(from: 0xC0, to: data.count - 31, by: 32) {
            let chunk = data[offset..<(offset + 32)]
            let unique = Set(chunk)
            let nonFill = chunk.filter { $0 != 0x00 && $0 != 0xff }.count
            guard unique.count >= 4, nonFill >= 8 else { continue }
            samples.append(
                ROMAssetMigrationPreviewSample(
                    kind: "4bppTileCandidate",
                    offset: UInt32(offset),
                    length: 32,
                    confidence: "low",
                    detail: "Aligned 32-byte range has varied non-fill bytes; classification is preview metadata only."
                )
            )
            if samples.count >= 32 { break }
        }
        return samples
    }

    private static func paletteSamples(data: Data) -> [ROMAssetMigrationPreviewSample] {
        guard data.count >= 32 else { return [] }
        var samples: [ROMAssetMigrationPreviewSample] = []
        for offset in stride(from: 0xC0, to: data.count - 31, by: 2) where offset.isMultiple(of: 32) {
            var plausibleColors = 0
            for colorOffset in stride(from: offset, to: offset + 32, by: 2) {
                let color = readUInt16LE(data, offset: colorOffset)
                if color <= 0x7fff {
                    plausibleColors += 1
                }
            }
            guard plausibleColors >= 12 else { continue }
            samples.append(
                ROMAssetMigrationPreviewSample(
                    kind: "paletteCandidate",
                    offset: UInt32(offset),
                    length: 32,
                    confidence: "low",
                    detail: "Aligned 16-color BGR555-shaped range; no palette is extracted."
                )
            )
            if samples.count >= 16 { break }
        }
        return samples
    }

    private static func tilemapSamples(data: Data) -> [ROMAssetMigrationPreviewSample] {
        guard data.count >= 64 else { return [] }
        var samples: [ROMAssetMigrationPreviewSample] = []
        for offset in stride(from: 0xC0, to: data.count - 63, by: 32) {
            var plausibleEntries = 0
            for entryOffset in stride(from: offset, to: offset + 64, by: 2) {
                let value = readUInt16LE(data, offset: entryOffset)
                let tile = value & 0x03ff
                if tile < 0x0400 {
                    plausibleEntries += 1
                }
            }
            guard plausibleEntries >= 24 else { continue }
            samples.append(
                ROMAssetMigrationPreviewSample(
                    kind: "tilemapCandidate",
                    offset: UInt32(offset),
                    length: 64,
                    confidence: "low",
                    detail: "Aligned tilemap-shaped halfwords; no tilemap is materialized."
                )
            )
            if samples.count >= 16 { break }
        }
        return samples
    }

    private static func diagnostics(
        image: ROMImage,
        gameFamily: GenIIIGameFamily,
        metadata: ROMAssetMigrationPreviewMetadata,
        coverageEntry: MigrationCoverageEntry?
    ) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = [
            Diagnostic(
                severity: .info,
                code: "ROM_ASSET_MIGRATION_PLAN_ONLY",
                message: "ROM asset migration planning is read-only; extraction, conversion, export, source writes, and ROM writes are disabled."
            )
        ]
        if coverageEntry == nil {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "ROM_ASSET_MIGRATION_COVERAGE_ENTRY_MISSING",
                    message: "The migration-coverage graphics entry for PHS-T92 was not found; plan output is limited to ROM inspection metadata."
                )
            )
        }
        if gameFamily == .unknown {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "ROM_ASSET_FAMILY_LOW_CONFIDENCE",
                    message: "The ROM game code \(image.gameCode ?? "unavailable") is not a recognized Gen III family, so source migration targets are generic."
                )
            )
        }
        if metadata.tileCandidateCount == 0, metadata.paletteCandidateCount == 0, metadata.tilemapCandidateCount == 0 {
            diagnostics.append(
                Diagnostic(
                    severity: .info,
                    code: "ROM_ASSET_PREVIEW_CANDIDATES_EMPTY",
                    message: "No graphics-shaped preview candidates were found in the bounded scan."
                )
            )
        }
        return diagnostics
    }

    private static func sourceTargetPrefix(for family: GenIIIGameFamily) -> String {
        switch family {
        case .emerald:
            return "pokeemerald"
        case .fireRedLeafGreen:
            return "pokefirered"
        case .rubySapphire:
            return "pokeruby"
        default:
            return "supported Gen III source tree"
        }
    }

    private static func family(for gameCode: String?) -> GenIIIGameFamily {
        switch gameCode?.uppercased() {
        case "AXVE", "AXVP", "AXPE", "AXPP":
            return .rubySapphire
        case "BPEE", "BPEP":
            return .emerald
        case "BPRE", "BPRP", "BPGE", "BPGP":
            return .fireRedLeafGreen
        default:
            return .unknown
        }
    }

    private static func readUInt16LE(_ data: Data, offset: Int) -> UInt16 {
        UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }
}
