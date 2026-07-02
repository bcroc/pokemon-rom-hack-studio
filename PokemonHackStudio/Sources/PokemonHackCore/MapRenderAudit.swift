import Foundation

public enum MapRenderAuditStatus: String, Codable, Equatable {
    case passed
    case failed
    case skipped
}

public struct MapRenderAuditReport: Codable, Equatable {
    public let schemaVersion: Int
    public let workspaceRoot: String?
    public let path: String?
    public let status: MapRenderAuditStatus
    public let summary: MapRenderAuditSummary
    public let targets: [MapRenderAuditTargetReport]
    public let skippedTargets: [MapRenderAuditSkippedTarget]
    public let warningBuckets: [MapRenderAuditWarningBucket]
    public let failures: [MapRenderAuditIssue]
    public let diagnostics: [Diagnostic]

    public init(
        schemaVersion: Int = 1,
        workspaceRoot: String?,
        path: String?,
        targets: [MapRenderAuditTargetReport],
        diagnostics: [Diagnostic] = []
    ) {
        self.schemaVersion = schemaVersion
        self.workspaceRoot = workspaceRoot
        self.path = path
        self.targets = targets
        skippedTargets = targets.compactMap(\.skippedTarget)
        warningBuckets = Self.warningBuckets(from: targets.flatMap(\.warnings))
        failures = targets.flatMap(\.failures)
        summary = MapRenderAuditSummary(targets: targets)
        status = failures.isEmpty ? .passed : .failed
        self.diagnostics = diagnostics
    }

    private static func warningBuckets(from warnings: [MapRenderAuditIssue]) -> [MapRenderAuditWarningBucket] {
        Dictionary(grouping: warnings, by: \.code)
            .map { code, issues in MapRenderAuditWarningBucket(code: code, count: issues.count) }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.code < rhs.code
                }
                return lhs.count > rhs.count
            }
    }
}

public struct MapRenderAuditSummary: Codable, Equatable {
    public let targetCount: Int
    public let auditedTargetCount: Int
    public let skippedTargetCount: Int
    public let mapCount: Int
    public let auditedMapCount: Int
    public let textureCount: Int
    public let warningCount: Int
    public let failureCount: Int

    public init(
        targetCount: Int,
        auditedTargetCount: Int,
        skippedTargetCount: Int,
        mapCount: Int,
        auditedMapCount: Int,
        textureCount: Int,
        warningCount: Int,
        failureCount: Int
    ) {
        self.targetCount = targetCount
        self.auditedTargetCount = auditedTargetCount
        self.skippedTargetCount = skippedTargetCount
        self.mapCount = mapCount
        self.auditedMapCount = auditedMapCount
        self.textureCount = textureCount
        self.warningCount = warningCount
        self.failureCount = failureCount
    }

    public init(targets: [MapRenderAuditTargetReport]) {
        self.init(
            targetCount: targets.count,
            auditedTargetCount: targets.filter { $0.skippedTarget == nil }.count,
            skippedTargetCount: targets.filter { $0.skippedTarget != nil }.count,
            mapCount: targets.reduce(0) { $0 + $1.mapCount },
            auditedMapCount: targets.reduce(0) { $0 + $1.auditedMapCount },
            textureCount: targets.reduce(0) { $0 + $1.textureCount },
            warningCount: targets.reduce(0) { $0 + $1.warningCount },
            failureCount: targets.reduce(0) { $0 + $1.failureCount }
        )
    }
}

public struct MapRenderAuditTargetReport: Codable, Equatable, Identifiable {
    public var id: String { targetID }

    public let targetID: String
    public let title: String
    public let path: String
    public let platform: GenIIIResourcePlatform
    public let profile: GameProfile
    public let role: GenIIIResourceRole
    public let parseStatus: GenIIIParseStatus
    public let modules: [EditorModule]
    public let status: MapRenderAuditStatus
    public let mapCount: Int
    public let auditedMapCount: Int
    public let textureCount: Int
    public let warningCount: Int
    public let failureCount: Int
    public let maps: [MapRenderAuditMapReport]
    public let skippedTarget: MapRenderAuditSkippedTarget?
    public let warningBuckets: [MapRenderAuditWarningBucket]
    public let warnings: [MapRenderAuditIssue]
    public let failures: [MapRenderAuditIssue]

    public init(
        targetID: String,
        title: String,
        path: String,
        platform: GenIIIResourcePlatform,
        profile: GameProfile,
        role: GenIIIResourceRole,
        parseStatus: GenIIIParseStatus,
        modules: [EditorModule],
        maps: [MapRenderAuditMapReport],
        skippedTarget: MapRenderAuditSkippedTarget? = nil,
        warnings: [MapRenderAuditIssue] = [],
        failures: [MapRenderAuditIssue] = []
    ) {
        self.targetID = targetID
        self.title = title
        self.path = path
        self.platform = platform
        self.profile = profile
        self.role = role
        self.parseStatus = parseStatus
        self.modules = modules
        self.maps = maps
        self.skippedTarget = skippedTarget
        self.warnings = warnings + maps.flatMap(\.warnings)
        self.failures = failures + maps.flatMap(\.failures)
        status = skippedTarget != nil ? .skipped : (self.failures.isEmpty ? .passed : .failed)
        mapCount = skippedTarget == nil ? maps.count : 0
        auditedMapCount = maps.filter { $0.status != .skipped }.count
        textureCount = maps.reduce(0) { $0 + $1.textureChecks.count }
        warningCount = self.warnings.count
        failureCount = self.failures.count
        warningBuckets = MapRenderAuditWarningBucket.buckets(from: self.warnings)
    }
}

public struct MapRenderAuditMapReport: Codable, Equatable, Identifiable {
    public var id: String { mapID }

    public let mapID: String
    public let mapName: String
    public let sourcePath: String
    public let status: MapRenderAuditStatus
    public let width: Int
    public let height: Int
    public let usedMetatileCount: Int
    public let textureChecks: [MapRenderAuditTextureReport]
    public let warningBuckets: [MapRenderAuditWarningBucket]
    public let warnings: [MapRenderAuditIssue]
    public let failures: [MapRenderAuditIssue]

    public init(
        mapID: String,
        mapName: String,
        sourcePath: String,
        width: Int,
        height: Int,
        usedMetatileCount: Int,
        textureChecks: [MapRenderAuditTextureReport],
        warnings: [MapRenderAuditIssue] = [],
        failures: [MapRenderAuditIssue] = []
    ) {
        self.mapID = mapID
        self.mapName = mapName
        self.sourcePath = sourcePath
        self.width = width
        self.height = height
        self.usedMetatileCount = usedMetatileCount
        self.textureChecks = textureChecks
        self.warnings = warnings + textureChecks.flatMap(\.warnings)
        self.failures = failures + textureChecks.flatMap(\.failures)
        status = self.failures.isEmpty ? .passed : .failed
        warningBuckets = MapRenderAuditWarningBucket.buckets(from: self.warnings)
    }
}

public struct MapRenderAuditTextureReport: Codable, Equatable, Identifiable {
    public var id: String { "\(kind.rawValue):\(role):\(path ?? symbol ?? "unknown")" }

    public let kind: MapRenderAuditTextureKind
    public let role: String
    public let symbol: String?
    public let path: String?
    public let status: MapRenderAuditStatus
    public let width: Int?
    public let height: Int?
    public let tileCount: Int?
    public let paletteCount: Int?
    public let colorCount: Int?
    public let warnings: [MapRenderAuditIssue]
    public let failures: [MapRenderAuditIssue]

    public init(
        kind: MapRenderAuditTextureKind,
        role: String,
        symbol: String?,
        path: String?,
        width: Int? = nil,
        height: Int? = nil,
        tileCount: Int? = nil,
        paletteCount: Int? = nil,
        colorCount: Int? = nil,
        warnings: [MapRenderAuditIssue] = [],
        failures: [MapRenderAuditIssue] = []
    ) {
        self.kind = kind
        self.role = role
        self.symbol = symbol
        self.path = path
        self.width = width
        self.height = height
        self.tileCount = tileCount
        self.paletteCount = paletteCount
        self.colorCount = colorCount
        self.warnings = warnings
        self.failures = failures
        status = failures.isEmpty ? .passed : .failed
    }
}

public enum MapRenderAuditTextureKind: String, Codable, Equatable {
    case tileImage
    case palette
    case eventSprite
}

public struct MapRenderAuditSkippedTarget: Codable, Equatable, Identifiable {
    public var id: String { targetID }

    public let targetID: String
    public let title: String
    public let path: String
    public let platform: GenIIIResourcePlatform
    public let profile: GameProfile
    public let role: GenIIIResourceRole
    public let parseStatus: GenIIIParseStatus
    public let reasonCode: String
    public let reason: String

    public init(
        targetID: String,
        title: String,
        path: String,
        platform: GenIIIResourcePlatform,
        profile: GameProfile,
        role: GenIIIResourceRole,
        parseStatus: GenIIIParseStatus,
        reasonCode: String,
        reason: String
    ) {
        self.targetID = targetID
        self.title = title
        self.path = path
        self.platform = platform
        self.profile = profile
        self.role = role
        self.parseStatus = parseStatus
        self.reasonCode = reasonCode
        self.reason = reason
    }
}

public struct MapRenderAuditWarningBucket: Codable, Equatable {
    public let code: String
    public let count: Int

    public init(code: String, count: Int) {
        self.code = code
        self.count = count
    }

    static func buckets(from warnings: [MapRenderAuditIssue]) -> [MapRenderAuditWarningBucket] {
        Dictionary(grouping: warnings, by: \.code)
            .map { code, issues in MapRenderAuditWarningBucket(code: code, count: issues.count) }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.code < rhs.code
                }
                return lhs.count > rhs.count
            }
    }
}

public struct MapRenderAuditIssue: Codable, Equatable, Identifiable {
    public var id: String {
        [
            severity.rawValue,
            code,
            targetID ?? "",
            mapID ?? "",
            path ?? "",
            message
        ].joined(separator: ":")
    }

    public let severity: DiagnosticSeverity
    public let code: String
    public let message: String
    public let targetID: String?
    public let mapID: String?
    public let path: String?

    public init(
        severity: DiagnosticSeverity,
        code: String,
        message: String,
        targetID: String? = nil,
        mapID: String? = nil,
        path: String? = nil
    ) {
        self.severity = severity
        self.code = code
        self.message = message
        self.targetID = targetID
        self.mapID = mapID
        self.path = path
    }

    init(diagnostic: Diagnostic, targetID: String, mapID: String? = nil) {
        self.init(
            severity: diagnostic.severity,
            code: diagnostic.code,
            message: diagnostic.message,
            targetID: targetID,
            mapID: mapID,
            path: diagnostic.span?.relativePath
        )
    }
}

public enum MapRenderAuditBuilder {
    public static func build(path: String, fileManager: FileManager = .default) -> MapRenderAuditReport {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        let target: MapRenderAuditTargetReport

        guard fileManager.fileExists(atPath: url.path) else {
            target = skippedTargetReport(
                targetID: url.path,
                title: url.lastPathComponent,
                path: url.path,
                platform: .unknown,
                profile: .unknown,
                role: .missingInput,
                parseStatus: .missing,
                reasonCode: "MAP_RENDER_AUDIT_TARGET_MISSING",
                reason: "The requested target path does not exist."
            )
            return MapRenderAuditReport(workspaceRoot: nil, path: url.path, targets: [target])
        }

        let entry: GenIIIResourceEntry
        do {
            let index = try GameAdapterRegistry.index(path: url.path, fileManager: fileManager)
            entry = GenIIIResourceRegistry.resourceEntry(
                from: index,
                role: .localInput,
                workspaceRoot: url.deletingLastPathComponent().path,
                fileManager: fileManager,
                detailMode: .summary
            )
        } catch {
            target = skippedTargetReport(
                targetID: url.path,
                title: url.lastPathComponent,
                path: url.path,
                platform: .unknown,
                profile: .unknown,
                role: .localInput,
                parseStatus: .unsupported,
                reasonCode: "MAP_RENDER_AUDIT_TARGET_UNSUPPORTED",
                reason: error.localizedDescription
            )
            return MapRenderAuditReport(workspaceRoot: nil, path: url.path, targets: [target])
        }

        return MapRenderAuditReport(
            workspaceRoot: nil,
            path: url.path,
            targets: [targetReport(from: entry, fileManager: fileManager)]
        )
    }

    public static func buildAll(
        workspaceRoot: String = FileManager.default.currentDirectoryPath,
        fileManager: FileManager = .default
    ) -> MapRenderAuditReport {
        let root = URL(fileURLWithPath: workspaceRoot).standardizedFileURL
        let library = GenIIIResourceRegistry.load(
            workspaceRoot: root.path,
            fileManager: fileManager,
            detailMode: .summary
        )
        let targets = library.entries.map { targetReport(from: $0, fileManager: fileManager) }
        return MapRenderAuditReport(
            workspaceRoot: library.workspaceRoot,
            path: nil,
            targets: targets,
            diagnostics: library.diagnostics
        )
    }

    private static func targetReport(from entry: GenIIIResourceEntry, fileManager: FileManager) -> MapRenderAuditTargetReport {
        guard entry.platform == .gbaSource,
              entry.modules.contains(.maps),
              entry.parseStatus == .parsed || entry.parseStatus == .partial
        else {
            return skippedTargetReport(
                targetID: entry.id,
                title: entry.title,
                path: entry.path,
                platform: entry.platform,
                profile: entry.profile,
                role: entry.role,
                parseStatus: entry.parseStatus,
                reasonCode: skipReasonCode(for: entry),
                reason: skipReason(for: entry)
            )
        }

        let targetID = entry.id
        do {
            let index = try GameAdapterRegistry.index(path: entry.path, fileManager: fileManager)
            let sharedCache = try ProjectMapVisualSharedCache.load(from: index, fileManager: fileManager)
            let warnings = entry.diagnostics
                .filter { $0.severity != .error }
                .map { MapRenderAuditIssue(diagnostic: $0, targetID: targetID) }
            var failures = entry.diagnostics
                .filter { $0.severity == .error }
                .map { MapRenderAuditIssue(diagnostic: $0, targetID: targetID) }
            if sharedCache.catalog.maps.isEmpty {
                failures.append(
                    issue(
                        .error,
                        "MAP_RENDER_AUDIT_NO_MAPS",
                        "No maps were discovered for a GBA source-tree target with map support.",
                        targetID: targetID
                    )
                )
            }
            let textureCache = MapRenderAuditTextureCache(rootPath: sharedCache.rootPath, fileManager: fileManager)
            let maps = sharedCache.catalog.maps.map { descriptor in
                mapReport(
                    targetID: targetID,
                    descriptor: descriptor,
                    sharedCache: sharedCache,
                    textureCache: textureCache,
                    fileManager: fileManager
                )
            }
            return MapRenderAuditTargetReport(
                targetID: targetID,
                title: entry.title,
                path: entry.path,
                platform: entry.platform,
                profile: entry.profile,
                role: entry.role,
                parseStatus: entry.parseStatus,
                modules: entry.modules,
                maps: maps,
                warnings: warnings,
                failures: failures
            )
        } catch {
            return MapRenderAuditTargetReport(
                targetID: targetID,
                title: entry.title,
                path: entry.path,
                platform: entry.platform,
                profile: entry.profile,
                role: entry.role,
                parseStatus: entry.parseStatus,
                modules: entry.modules,
                maps: [],
                failures: [
                    issue(
                        .error,
                        "MAP_RENDER_AUDIT_CATALOG_LOAD_FAILED",
                        "Map visual catalog load failed: \(error.localizedDescription)",
                        targetID: targetID,
                        path: entry.path
                    )
                ]
            )
        }
    }

    private static func mapReport(
        targetID: String,
        descriptor: MapDescriptor,
        sharedCache: ProjectMapVisualSharedCache,
        textureCache: MapRenderAuditTextureCache,
        fileManager: FileManager
    ) -> MapRenderAuditMapReport {
        do {
            let document = try ProjectMapVisualLoader.load(from: sharedCache, mapID: descriptor.id, fileManager: fileManager)
            return validate(document: document, targetID: targetID, textureCache: textureCache)
        } catch {
            return MapRenderAuditMapReport(
                mapID: descriptor.id,
                mapName: descriptor.name,
                sourcePath: descriptor.sourcePath,
                width: 0,
                height: 0,
                usedMetatileCount: 0,
                textureChecks: [],
                failures: [
                    issue(
                        .error,
                        "MAP_RENDER_AUDIT_MAP_LOAD_FAILED",
                        "Map visual load failed: \(error.localizedDescription)",
                        targetID: targetID,
                        mapID: descriptor.id,
                        path: descriptor.sourcePath
                    )
                ]
            )
        }
    }

    private static func validate(
        document: MapVisualDocument,
        targetID: String,
        textureCache: MapRenderAuditTextureCache
    ) -> MapRenderAuditMapReport {
        var warnings: [MapRenderAuditIssue] = []
        var failures: [MapRenderAuditIssue] = []
        var textureChecks: [MapRenderAuditTextureReport] = []

        for diagnostic in document.diagnostics {
            let issue = MapRenderAuditIssue(diagnostic: diagnostic, targetID: targetID, mapID: document.mapID)
            if diagnostic.severity == .error {
                failures.append(issue)
            } else {
                warnings.append(issue)
            }
        }

        validateBlockdata(
            document.blockdata,
            role: "layout",
            targetID: targetID,
            mapID: document.mapID,
            failures: &failures
        )
        if let border = document.border {
            validateBlockdata(
                border,
                role: "border",
                targetID: targetID,
                mapID: document.mapID,
                failures: &failures
            )
        }
        for placement in document.scene.placements {
            if placement.rawValues.count != placement.width * placement.height {
                failures.append(
                    issue(
                        .error,
                        "MAP_RENDER_AUDIT_SCENE_PLACEMENT_INCOMPLETE",
                        "\(placement.id) has \(placement.rawValues.count) cells; expected \(placement.width * placement.height).",
                        targetID: targetID,
                        mapID: document.mapID,
                        path: placement.sourcePath
                    )
                )
            }
        }

        let usedMetatileIDs = usedMetatiles(in: document)
        let definitionsByID = Dictionary(document.metatiles.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let missingDefinitions = usedMetatileIDs.filter { definitionsByID[$0] == nil }.sorted()
        for id in missingDefinitions {
            failures.append(
                issue(
                    .error,
                    "MAP_RENDER_AUDIT_METATILE_DEFINITION_MISSING",
                    "Metatile \(id) is used by map data but has no loaded definition.",
                    targetID: targetID,
                    mapID: document.mapID,
                    path: document.layout.sourcePath
                )
            )
        }

        let assets = [document.primaryTileset, document.secondaryTileset].compactMap { $0 }
        let assetChecks = assets.map { textureCache.assetTextureReport(asset: $0, targetID: targetID, mapID: document.mapID) }
        textureChecks.append(contentsOf: assetChecks.flatMap(\.textureReports))
        failures.append(contentsOf: assetChecks.flatMap(\.failures))
        warnings.append(contentsOf: assetChecks.flatMap(\.warnings))
        textureChecks.append(contentsOf: eventSpriteChecks(document: document, targetID: targetID, textureCache: textureCache))

        for definition in usedMetatileIDs.compactMap({ definitionsByID[$0] }) {
            validate(
                definition: definition,
                document: document,
                targetID: targetID,
                images: textureCache.images,
                palettes: textureCache.palettes,
                warnings: &warnings,
                failures: &failures
            )
        }

        if !usedMetatileIDs.isEmpty,
           !usedMetatileIDs.compactMap({ definitionsByID[$0] }).contains(where: { definitionHasVisiblePixel($0, document: document, images: textureCache.images, palettes: textureCache.palettes) }) {
            failures.append(
                issue(
                    .error,
                    "MAP_RENDER_AUDIT_ALL_BLANK_RENDER",
                    "All used metatiles resolve to blank or transparent pixels.",
                    targetID: targetID,
                    mapID: document.mapID,
                    path: document.layout.sourcePath
                )
            )
        }

        return MapRenderAuditMapReport(
            mapID: document.mapID,
            mapName: document.mapName,
            sourcePath: document.mapSourcePath,
            width: document.blockdata.width,
            height: document.blockdata.height,
            usedMetatileCount: usedMetatileIDs.count,
            textureChecks: textureChecks,
            warnings: warnings,
            failures: failures
        )
    }

    private static func validateBlockdata(
        _ blockdata: EditableLayoutBlockdata,
        role: String,
        targetID: String,
        mapID: String,
        failures: inout [MapRenderAuditIssue]
    ) {
        guard blockdata.isComplete else {
            failures.append(
                issue(
                    .error,
                    "MAP_RENDER_AUDIT_BLOCKDATA_INCOMPLETE",
                    "\(role) blockdata has \(blockdata.actualByteCount) bytes; expected \(blockdata.expectedByteCount).",
                    targetID: targetID,
                    mapID: mapID,
                    path: blockdata.filepath
                )
            )
            return
        }
    }

    private static func eventSpriteChecks(
        document: MapVisualDocument,
        targetID: String,
        textureCache: MapRenderAuditTextureCache
    ) -> [MapRenderAuditTextureReport] {
        var seen: Set<String> = []
        return document.events.compactMap { event -> MapRenderAuditTextureReport? in
            guard let sprite = event.sprite,
                  let path = sprite.imageAssetPath,
                  seen.insert(path).inserted
            else {
                return nil
            }
            return textureCache.eventSpriteReport(path: path, symbol: sprite.graphicsID, targetID: targetID, mapID: document.mapID)
        }
    }

    private static func validate(
        definition: MetatileDefinition,
        document: MapVisualDocument,
        targetID: String,
        images: [String: IndexedTilesetImage],
        palettes: [String: [[PaletteColor]]],
        warnings: inout [MapRenderAuditIssue],
        failures: inout [MapRenderAuditIssue]
    ) {
        for entry in definition.tileEntries {
            if entry.tileIndex >= document.tileLimits.total {
                failures.append(
                    issue(
                        .error,
                        "MAP_RENDER_AUDIT_TILE_INDEX_OUT_OF_RANGE",
                        "Metatile \(definition.id) tile entry \(entry.index) references tile \(entry.tileIndex), outside the map tile limit \(document.tileLimits.total).",
                        targetID: targetID,
                        mapID: document.mapID,
                        path: document.layout.sourcePath
                    )
                )
                continue
            }
            guard let asset = asset(for: entry, document: document) else {
                failures.append(
                    issue(
                        .error,
                        "MAP_RENDER_AUDIT_TILESET_MISSING",
                        "Metatile \(definition.id) tile entry \(entry.index) references tile \(entry.tileIndex), but the matching tileset is missing.",
                        targetID: targetID,
                        mapID: document.mapID,
                        path: document.layout.sourcePath
                    )
                )
                continue
            }
            let localTileIndex = entry.tileIndex < document.tileLimits.primary
                ? entry.tileIndex
                : entry.tileIndex - document.tileLimits.primary
            guard let path = asset.tileImagePath,
                  let image = images[path]
            else {
                continue
            }
            if localTileIndex < 0 || localTileIndex >= image.tileCount {
                warnings.append(
                    issue(
                        .warning,
                        "MAP_RENDER_AUDIT_TILE_IMAGE_INDEX_OUT_OF_RANGE",
                        "Metatile \(definition.id) tile entry \(entry.index) references tile \(entry.tileIndex), outside \(asset.symbol)'s \(image.tileCount) decoded image tiles; the renderer treats the slot as blank.",
                        targetID: targetID,
                        mapID: document.mapID,
                        path: path
                    )
                )
            }
            let paletteSets = palettes[asset.symbol] ?? []
            if entry.palette < 0 || entry.palette >= paletteSets.count {
                failures.append(
                    issue(
                        .error,
                        "MAP_RENDER_AUDIT_PALETTE_INDEX_OUT_OF_RANGE",
                        "Metatile \(definition.id) tile entry \(entry.index) references palette \(entry.palette), outside \(asset.symbol)'s \(paletteSets.count) loaded palettes.",
                        targetID: targetID,
                        mapID: document.mapID,
                        path: asset.palettePaths.first
                    )
                )
            }
        }
    }

    private static func definitionHasVisiblePixel(
        _ definition: MetatileDefinition,
        document: MapVisualDocument,
        images: [String: IndexedTilesetImage],
        palettes: [String: [[PaletteColor]]]
    ) -> Bool {
        for entry in definition.tileEntries {
            guard let asset = asset(for: entry, document: document),
                  let path = asset.tileImagePath,
                  let image = images[path]
            else {
                continue
            }
            let localTileIndex = entry.tileIndex < document.tileLimits.primary
                ? entry.tileIndex
                : entry.tileIndex - document.tileLimits.primary
            guard localTileIndex >= 0, localTileIndex < image.tileCount else { continue }
            let palette = palettes[asset.symbol]?[safe: entry.palette] ?? []
            for y in 0..<8 {
                for x in 0..<8 {
                    guard let paletteIndex = image.paletteIndex(tileIndex: localTileIndex, x: x, y: y, hFlip: entry.hFlip, vFlip: entry.vFlip),
                          paletteIndex > 0
                    else {
                        continue
                    }
                    if let color = palette[safe: Int(paletteIndex)] {
                        if color.alpha > 0 {
                            return true
                        }
                    } else {
                        return true
                    }
                }
            }
        }
        return false
    }

    private static func asset(for entry: MetatileTileEntry, document: MapVisualDocument) -> TilesetAsset? {
        if entry.tileIndex < document.tileLimits.primary {
            return document.primaryTileset
        }
        guard entry.tileIndex < document.tileLimits.total else {
            return nil
        }
        return document.secondaryTileset
    }

    private static func usedMetatiles(in document: MapVisualDocument) -> Set<Int> {
        var ids = Set(document.blockdata.metatileIDs)
        if let border = document.border {
            ids.formUnion(border.metatileIDs)
        }
        for placement in document.scene.placements {
            ids.formUnion(placement.rawValues.map { Int($0 & 0x03ff) })
        }
        return ids
    }

    private static func skippedTargetReport(
        targetID: String,
        title: String,
        path: String,
        platform: GenIIIResourcePlatform,
        profile: GameProfile,
        role: GenIIIResourceRole,
        parseStatus: GenIIIParseStatus,
        reasonCode: String,
        reason: String
    ) -> MapRenderAuditTargetReport {
        let skipped = MapRenderAuditSkippedTarget(
            targetID: targetID,
            title: title,
            path: path,
            platform: platform,
            profile: profile,
            role: role,
            parseStatus: parseStatus,
            reasonCode: reasonCode,
            reason: reason
        )
        return MapRenderAuditTargetReport(
            targetID: targetID,
            title: title,
            path: path,
            platform: platform,
            profile: profile,
            role: role,
            parseStatus: parseStatus,
            modules: [],
            maps: [],
            skippedTarget: skipped
        )
    }

    private static func skipReasonCode(for entry: GenIIIResourceEntry) -> String {
        if entry.parseStatus == .missing { return "MAP_RENDER_AUDIT_TARGET_MISSING" }
        if entry.parseStatus == .failed { return "MAP_RENDER_AUDIT_TARGET_FAILED_DISCOVERY" }
        if entry.parseStatus == .unsupported { return "MAP_RENDER_AUDIT_TARGET_UNSUPPORTED" }
        switch entry.platform {
        case .gbaROM:
            return "MAP_RENDER_AUDIT_BINARY_ROM_SKIPPED"
        case .ndsROM:
            return "MAP_RENDER_AUDIT_NDS_ROM_SKIPPED"
        case .ndsSource:
            return "MAP_RENDER_AUDIT_NDS_SOURCE_SKIPPED"
        case .gameCube:
            return "MAP_RENDER_AUDIT_GAMECUBE_SKIPPED"
        case .gbaSource where !entry.modules.contains(.maps):
            return "MAP_RENDER_AUDIT_GBA_SOURCE_WITHOUT_MAPS_SKIPPED"
        case .unknown:
            return "MAP_RENDER_AUDIT_TARGET_UNSUPPORTED"
        case .gbaSource:
            return "MAP_RENDER_AUDIT_TARGET_SKIPPED"
        }
    }

    private static func skipReason(for entry: GenIIIResourceEntry) -> String {
        switch skipReasonCode(for: entry) {
        case "MAP_RENDER_AUDIT_BINARY_ROM_SKIPPED":
            return "Binary GBA ROM targets do not expose source-tree map render inputs."
        case "MAP_RENDER_AUDIT_NDS_ROM_SKIPPED":
            return "NDS ROM targets do not use the Gen III source-tree map renderer."
        case "MAP_RENDER_AUDIT_NDS_SOURCE_SKIPPED":
            return "NDS source-tree targets do not use the Gen III source-tree map renderer."
        case "MAP_RENDER_AUDIT_GAMECUBE_SKIPPED":
            return "GameCube media targets do not use the Gen III source-tree map renderer."
        case "MAP_RENDER_AUDIT_GBA_SOURCE_WITHOUT_MAPS_SKIPPED":
            return "This GBA source-tree target does not expose the maps editor module."
        case "MAP_RENDER_AUDIT_TARGET_MISSING":
            return "The discovered target path is missing."
        case "MAP_RENDER_AUDIT_TARGET_FAILED_DISCOVERY":
            return "The discovered target could not be parsed by resource discovery."
        default:
            return "The discovered target is not supported by the Gen III map render audit."
        }
    }

    private static func issue(
        _ severity: DiagnosticSeverity,
        _ code: String,
        _ message: String,
        targetID: String,
        mapID: String? = nil,
        path: String? = nil
    ) -> MapRenderAuditIssue {
        MapRenderAuditIssue(
            severity: severity,
            code: code,
            message: message,
            targetID: targetID,
            mapID: mapID,
            path: path
        )
    }
}

private struct MapRenderAuditAssetCheck {
    let textureReports: [MapRenderAuditTextureReport]
    let warnings: [MapRenderAuditIssue]
    let failures: [MapRenderAuditIssue]
}

private final class MapRenderAuditTextureCache {
    let root: URL
    let fileManager: FileManager
    private(set) var images: [String: IndexedTilesetImage] = [:]
    private(set) var palettes: [String: [[PaletteColor]]] = [:]

    init(rootPath: String, fileManager: FileManager) {
        root = URL(fileURLWithPath: rootPath).standardizedFileURL
        self.fileManager = fileManager
    }

    func assetTextureReport(asset: TilesetAsset, targetID: String, mapID: String) -> MapRenderAuditAssetCheck {
        var reports: [MapRenderAuditTextureReport] = []
        let warnings: [MapRenderAuditIssue] = []
        var failures: [MapRenderAuditIssue] = []
        let role = asset.isSecondary ? "secondary" : "primary"

        if let tilePath = asset.tileImagePath {
            let url = root.appendingPathComponent(tilePath)
            if !fileManager.fileExists(atPath: url.path) {
                let issue = makeIssue(
                    .error,
                    code: "MAP_RENDER_AUDIT_TILE_IMAGE_MISSING",
                    message: "\(asset.symbol) tile image is missing.",
                    targetID: targetID,
                    mapID: mapID,
                    path: tilePath
                )
                failures.append(issue)
                reports.append(
                    MapRenderAuditTextureReport(kind: .tileImage, role: role, symbol: asset.symbol, path: tilePath, failures: [issue])
                )
            } else if let image = IndexedPNGParser.parse(url: url) {
                images[tilePath] = image
                reports.append(
                    MapRenderAuditTextureReport(
                        kind: .tileImage,
                        role: role,
                        symbol: asset.symbol,
                        path: tilePath,
                        width: image.width,
                        height: image.height,
                        tileCount: image.tileCount
                    )
                )
            } else {
                let issue = makeIssue(
                    .error,
                    code: "MAP_RENDER_AUDIT_TILE_IMAGE_UNPARSEABLE",
                    message: "\(asset.symbol) tile image is not a supported indexed PNG.",
                    targetID: targetID,
                    mapID: mapID,
                    path: tilePath
                )
                failures.append(issue)
                reports.append(
                    MapRenderAuditTextureReport(kind: .tileImage, role: role, symbol: asset.symbol, path: tilePath, failures: [issue])
                )
            }
        } else {
            let issue = makeIssue(
                .error,
                code: "MAP_RENDER_AUDIT_TILE_IMAGE_UNRESOLVED",
                message: "\(asset.symbol) does not resolve a tile image path.",
                targetID: targetID,
                mapID: mapID
            )
            failures.append(issue)
            reports.append(
                MapRenderAuditTextureReport(kind: .tileImage, role: role, symbol: asset.symbol, path: nil, failures: [issue])
            )
        }

        var paletteSets: [[PaletteColor]] = []
        for palettePath in asset.palettePaths {
            let url = root.appendingPathComponent(palettePath)
            if !fileManager.fileExists(atPath: url.path) {
                let issue = makeIssue(
                    .error,
                    code: "MAP_RENDER_AUDIT_PALETTE_MISSING",
                    message: "\(asset.symbol) palette is missing.",
                    targetID: targetID,
                    mapID: mapID,
                    path: palettePath
                )
                failures.append(issue)
                reports.append(
                    MapRenderAuditTextureReport(kind: .palette, role: role, symbol: asset.symbol, path: palettePath, failures: [issue])
                )
                continue
            }
            guard let data = try? Data(contentsOf: url) else {
                let issue = makeIssue(
                    .error,
                    code: "MAP_RENDER_AUDIT_PALETTE_UNREADABLE",
                    message: "\(asset.symbol) palette could not be read.",
                    targetID: targetID,
                    mapID: mapID,
                    path: palettePath
                )
                failures.append(issue)
                reports.append(
                    MapRenderAuditTextureReport(kind: .palette, role: role, symbol: asset.symbol, path: palettePath, failures: [issue])
                )
                continue
            }
            let colors = TilePaletteParser.parse(data: data, path: palettePath)
            if colors.isEmpty {
                let issue = makeIssue(
                    .error,
                    code: "MAP_RENDER_AUDIT_PALETTE_UNPARSEABLE",
                    message: "\(asset.symbol) palette did not produce any colors.",
                    targetID: targetID,
                    mapID: mapID,
                    path: palettePath
                )
                failures.append(issue)
                reports.append(
                    MapRenderAuditTextureReport(kind: .palette, role: role, symbol: asset.symbol, path: palettePath, failures: [issue])
                )
                continue
            }
            paletteSets.append(colors)
            reports.append(
                MapRenderAuditTextureReport(
                    kind: .palette,
                    role: role,
                    symbol: asset.symbol,
                    path: palettePath,
                    paletteCount: 1,
                    colorCount: colors.count
                )
            )
        }
        if asset.palettePaths.isEmpty {
            let issue = makeIssue(
                .error,
                code: "MAP_RENDER_AUDIT_PALETTE_UNRESOLVED",
                message: "\(asset.symbol) does not resolve any palette paths.",
                targetID: targetID,
                mapID: mapID
            )
            failures.append(issue)
            reports.append(
                MapRenderAuditTextureReport(kind: .palette, role: role, symbol: asset.symbol, path: nil, failures: [issue])
            )
        }
        palettes[asset.symbol] = paletteSets

        return MapRenderAuditAssetCheck(textureReports: reports, warnings: warnings, failures: failures)
    }

    func eventSpriteReport(path: String, symbol: String, targetID: String, mapID: String) -> MapRenderAuditTextureReport {
        let url = root.appendingPathComponent(path)
        guard fileManager.fileExists(atPath: url.path) else {
            let issue = makeIssue(
                .error,
                code: "MAP_RENDER_AUDIT_EVENT_SPRITE_MISSING",
                message: "\(symbol) resolves to a missing object event sprite image.",
                targetID: targetID,
                mapID: mapID,
                path: path
            )
            return MapRenderAuditTextureReport(kind: .eventSprite, role: "object", symbol: symbol, path: path, failures: [issue])
        }
        guard let data = try? Data(contentsOf: url),
              let png = GraphicsMetadataParser.pngMetadata(from: data)
        else {
            let issue = makeIssue(
                .error,
                code: "MAP_RENDER_AUDIT_EVENT_SPRITE_UNREADABLE",
                message: "\(symbol) object event sprite image could not be read as PNG metadata.",
                targetID: targetID,
                mapID: mapID,
                path: path
            )
            return MapRenderAuditTextureReport(kind: .eventSprite, role: "object", symbol: symbol, path: path, failures: [issue])
        }
        return MapRenderAuditTextureReport(
            kind: .eventSprite,
            role: "object",
            symbol: symbol,
            path: path,
            width: png.width,
            height: png.height,
            paletteCount: png.paletteColorCount
        )
    }

    private func makeIssue(
        _ severity: DiagnosticSeverity,
        code: String,
        message: String,
        targetID: String,
        mapID: String,
        path: String? = nil
    ) -> MapRenderAuditIssue {
        MapRenderAuditIssue(
            severity: severity,
            code: code,
            message: message,
            targetID: targetID,
            mapID: mapID,
            path: path
        )
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
