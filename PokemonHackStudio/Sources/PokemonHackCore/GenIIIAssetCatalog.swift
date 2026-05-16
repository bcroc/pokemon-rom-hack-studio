import Foundation

public enum GenIIIAssetCategory: String, Codable, Equatable, CaseIterable {
    case maps
    case layouts
    case scripts
    case text
    case species
    case trainers
    case items
    case moves
    case learnsets
    case evolutions
    case pokedex
    case encounters
    case graphics
    case palettes
    case tilesets
    case audio
    case generated
    case rom
    case media
    case source
    case unknown
}

public enum GenIIIAssetStatus: String, Codable, Equatable, CaseIterable {
    case valid
    case warning
    case error
    case missing
    case unsupported
}

public enum GenIIIAssetAvailability: String, Codable, Equatable, CaseIterable {
    case availableSource
    case availableGenerated
    case availableLocalInput
    case optionalGeneratedMissing
    case generatedStale
    case missingRequiredSource
    case parserWarning
    case parserError
    case unsupported
}

public struct GenIIIAssetAvailabilityCount: Codable, Equatable, Identifiable {
    public var id: String { availability.rawValue }

    public let availability: GenIIIAssetAvailability
    public let count: Int

    public init(availability: GenIIIAssetAvailability, count: Int) {
        self.availability = availability
        self.count = count
    }
}

public struct GenIIIAssetNavigationTarget: Codable, Equatable {
    public let module: EditorModule
    public let identifier: String?

    public init(module: EditorModule, identifier: String? = nil) {
        self.module = module
        self.identifier = identifier
    }
}

public struct GenIIIAsset: Codable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let relativePath: String
    public let category: GenIIIAssetCategory
    public let kind: String
    public let role: SourceRole
    public let status: GenIIIAssetStatus
    public let availability: GenIIIAssetAvailability
    public let sourceSpan: SourceSpan?
    public let sizeBytes: UInt64?
    public let sha1: String?
    public let tags: [String]
    public let facts: [SourceIndexFact]
    public let diagnostics: [Diagnostic]
    public let navigationTarget: GenIIIAssetNavigationTarget?

    public init(
        id: String,
        title: String,
        subtitle: String,
        relativePath: String,
        category: GenIIIAssetCategory,
        kind: String,
        role: SourceRole,
        status: GenIIIAssetStatus = .valid,
        availability: GenIIIAssetAvailability? = nil,
        sourceSpan: SourceSpan? = nil,
        sizeBytes: UInt64? = nil,
        sha1: String? = nil,
        tags: [String] = [],
        facts: [SourceIndexFact] = [],
        diagnostics: [Diagnostic] = [],
        navigationTarget: GenIIIAssetNavigationTarget? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.relativePath = relativePath
        self.category = category
        self.kind = kind
        self.role = role
        self.status = status
        self.availability = availability ?? GenIIIAssetAvailability.inferred(
            category: category,
            kind: kind,
            role: role,
            status: status,
            diagnostics: diagnostics
        )
        self.sourceSpan = sourceSpan
        self.sizeBytes = sizeBytes
        self.sha1 = sha1
        self.tags = tags
        self.facts = facts
        self.diagnostics = diagnostics
        self.navigationTarget = navigationTarget
    }
}

public struct GenIIIAssetCatalog: Codable, Equatable {
    public let root: SourceLocation
    public let profile: GameProfile
    public let adapterID: String
    public let adapterName: String
    public let generatedAt: Date
    public let assets: [GenIIIAsset]
    public let availabilityCounts: [GenIIIAssetAvailabilityCount]
    public let diagnostics: [Diagnostic]

    public var assetCount: Int { assets.count }

    public init(
        root: SourceLocation,
        profile: GameProfile,
        adapterID: String,
        adapterName: String,
        generatedAt: Date = Date(),
        assets: [GenIIIAsset],
        availabilityCounts: [GenIIIAssetAvailabilityCount]? = nil,
        diagnostics: [Diagnostic] = []
    ) {
        self.root = root
        self.profile = profile
        self.adapterID = adapterID
        self.adapterName = adapterName
        self.generatedAt = generatedAt
        self.assets = assets
        self.availabilityCounts = availabilityCounts ?? Self.counts(for: assets)
        self.diagnostics = diagnostics
    }

    private static func counts(for assets: [GenIIIAsset]) -> [GenIIIAssetAvailabilityCount] {
        var counts: [GenIIIAssetAvailability: Int] = [:]
        for asset in assets {
            counts[asset.availability, default: 0] += 1
        }
        return GenIIIAssetAvailability.allCases.compactMap { availability in
            counts[availability].map { GenIIIAssetAvailabilityCount(availability: availability, count: $0) }
        }
    }
}

public extension GenIIIAssetAvailability {
    var affectsResourceAvailability: Bool {
        switch self {
        case .missingRequiredSource, .parserWarning, .parserError, .unsupported:
            true
        case .availableSource, .availableGenerated, .availableLocalInput, .optionalGeneratedMissing, .generatedStale:
            false
        }
    }

    static func inferred(
        category: GenIIIAssetCategory,
        kind: String,
        role: SourceRole,
        status: GenIIIAssetStatus,
        diagnostics: [Diagnostic]
    ) -> GenIIIAssetAvailability {
        if diagnostics.contains(where: { $0.severity == .error }) || status == .error {
            return .parserError
        }

        if status == .unsupported {
            return .unsupported
        }

        if role == .localInput {
            return status == .missing ? .missingRequiredSource : .availableLocalInput
        }

        if category == .generated || role == .artifact || role == .generated {
            if diagnostics.contains(where: { $0.code == "GRAPHICS_GENERATED_ARTIFACT_STALE" }) {
                return .generatedStale
            }
            return status == .missing ? .optionalGeneratedMissing : .availableGenerated
        }

        if kind == "animationDirectory", status == .missing {
            return .optionalGeneratedMissing
        }

        if diagnostics.contains(where: { $0.code == "GRAPHICS_GENERATED_ARTIFACT_STALE" }) {
            return .generatedStale
        }

        if status == .missing {
            return isGeneratedLikePath(kind: kind) ? .optionalGeneratedMissing : .missingRequiredSource
        }

        let blockingDiagnostics = diagnostics.filter { diagnostic in
            diagnostic.severity == .warning && !nonBlockingDiagnosticCodes.contains(diagnostic.code)
        }
        if status == .warning, !blockingDiagnostics.isEmpty {
            return .parserWarning
        }

        return role == .artifact || role == .generated ? .availableGenerated : .availableSource
    }

    private static let nonBlockingDiagnosticCodes: Set<String> = [
        "GRAPHICS_15BIT_PRECISION_LOSS",
        "GRAPHICS_GENERATED_ARTIFACT_MISSING",
        "GRAPHICS_METATILE_LAYER_UNKNOWN",
        "GRAPHICS_PATH_CONTAINS_SPACES",
        "GRAPHICS_UNSUPPORTED_SOURCE_ARTIFACT",
        "TEXT_LINE_LONG",
        "TEXT_TERMINATOR_MISSING"
    ]

    private static func isGeneratedLikePath(kind: String) -> Bool {
        kind == "generated" || kind == "buildOutput"
    }
}

public enum GenIIIAssetCatalogBuilder {
    private static let cacheSchemaVersion = 3
    private static let cacheRelativePath = ".pokemonhackstudio/indexes/asset-catalog-v1.json"
    private static let cacheMetadataRelativePath = ".pokemonhackstudio/indexes/asset-catalog-v1-metadata.json"
    private static let cacheOutputRelativePath = ".pokemonhackstudio/indexes/asset-catalog-v1-output.json"
    private static let inventoryRoots = ["data", "graphics", "sound", "songs", "src/data", "include", "constants"]
    private static let recursiveFingerprintRoots = ["data/maps", "data/layouts", "data/scripts", "data/text", "src/data", "include", "constants"]
    private static let excludedDirectoryNames: Set<String> = [
        ".build",
        ".git",
        ".pokemonhackstudio",
        ".swiftpm",
        "DerivedData",
        "build",
        "builds",
        "node_modules",
        "xcuserdata"
    ]
    private static let excludedExtensions: Set<String> = [
        "3ds",
        "bsp",
        "gba",
        "gbc",
        "gcm",
        "ips",
        "iso",
        "nds",
        "o",
        "sav",
        "sgm",
        "ups",
        "xcodeproj",
        "xcworkspace"
    ]

    public static func build(
        path: String,
        fileManager: FileManager = .default
    ) -> GenIIIAssetCatalog {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        do {
            let index = try GameAdapterRegistry.index(path: url.path, fileManager: fileManager)
            if index.profile == .binaryROM || index.profile == .ndsROM || index.profile.platform == .nds {
                return build(resourceEntry: GenIIIResourceRegistry.resourceIndex(path: url.path, fileManager: fileManager))
            }
            let identity = CacheProjectIdentity(index: index)
            let fingerprint = sourceFingerprint(for: index, fileManager: fileManager)
            if let cached = cachedCatalog(
                root: url,
                identity: identity,
                fingerprint: fingerprint,
                fileManager: fileManager
            ) {
                return cached
            }
            let buildReport = BuildValidationReportBuilder.build(index: index, fileManager: fileManager)
            let catalog = build(index: index, buildReport: buildReport, fileManager: fileManager)
            writeCache(
                catalog: catalog,
                root: url,
                identity: identity,
                fingerprint: fingerprint,
                fileManager: fileManager
            )
            return catalog
        } catch {
            let resource = GenIIIResourceRegistry.resourceIndex(path: url.path, fileManager: fileManager)
            var catalog = build(resourceEntry: resource)
            let diagnostic = Diagnostic(
                severity: .warning,
                code: "ASSET_CATALOG_UNSUPPORTED_INPUT",
                message: error.localizedDescription,
                span: SourceSpan(relativePath: url.lastPathComponent, startLine: 1)
            )
            catalog = GenIIIAssetCatalog(
                root: catalog.root,
                profile: catalog.profile,
                adapterID: catalog.adapterID,
                adapterName: catalog.adapterName,
                assets: catalog.assets,
                diagnostics: catalog.diagnostics + [diagnostic]
            )
            return catalog
        }
    }

    public static func cachedCatalogJSONString(
        path: String,
        fileManager: FileManager = .default
    ) -> String? {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        guard
            let index = try? GameAdapterRegistry.index(path: url.path, fileManager: fileManager),
            index.profile != .binaryROM,
            index.profile != .ndsROM,
            index.profile.platform != .nds
        else {
            return nil
        }
        let identity = CacheProjectIdentity(index: index)
        let fingerprint = sourceFingerprint(for: index, fileManager: fileManager)
        guard cacheMetadataMatches(root: url, identity: identity, fingerprint: fingerprint, fileManager: fileManager) else {
            if let payload = cachedPayload(root: url, identity: identity, fingerprint: fingerprint, fileManager: fileManager) {
                writeCache(
                    catalog: payload.catalog,
                    root: url,
                    identity: identity,
                    fingerprint: fingerprint,
                    fileManager: fileManager
                )
                let outputURL = cacheOutputURL(for: url)
                guard let data = try? Data(contentsOf: outputURL) else { return nil }
                return String(decoding: data, as: UTF8.self)
            }
            return nil
        }
        let outputURL = cacheOutputURL(for: url)
        guard fileManager.fileExists(atPath: outputURL.path),
              let data = try? Data(contentsOf: outputURL)
        else {
            return nil
        }
        return String(decoding: data, as: UTF8.self)
    }

    public static func build(
        index: ProjectIndex,
        sourceIndex: ProjectSourceIndex? = nil,
        scriptOutline: ProjectScriptOutline? = nil,
        mapCatalog: ProjectMapCatalog? = nil,
        graphicsReport: GraphicsDiagnosticsReport? = nil,
        buildReport: BuildValidationReport? = nil,
        resourceEntry: GenIIIResourceEntry? = nil,
        fileManager: FileManager = .default
    ) -> GenIIIAssetCatalog {
        let root = URL(fileURLWithPath: index.root.path).standardizedFileURL
        var diagnostics: [Diagnostic] = []
        var assets: [GenIIIAsset] = []
        var seenIDs = Set<String>()
        var specificallyIndexedPaths = Set<String>()

        let loadedScriptOutline = scriptOutline ?? (try? ProjectScriptOutlineLoader.load(from: index, fileManager: fileManager))
        let loadedSourceIndex: ProjectSourceIndex?
        if let sourceIndex {
            loadedSourceIndex = sourceIndex
        } else if let loadedScriptOutline {
            loadedSourceIndex = try? ProjectSourceIndexLoader.load(from: index, scriptOutline: loadedScriptOutline, fileManager: fileManager)
        } else {
            loadedSourceIndex = try? ProjectSourceIndexLoader.load(from: index, fileManager: fileManager)
        }
        let loadedMapCatalog = mapCatalog ?? (try? ProjectMapCatalogLoader.load(from: index, fileManager: fileManager))
        let loadedGraphicsReport = graphicsReport ?? (index.editorModules.contains(.graphics) ? GraphicsDiagnosticsReportBuilder.build(index: index, fileManager: fileManager) : nil)
        let loadedBuildReport = buildReport
        let loadedResourceEntry = resourceEntry ?? GenIIIResourceRegistry.resourceEntry(from: index, fileManager: fileManager)

        if let loadedSourceIndex {
            diagnostics.append(contentsOf: catalogDiagnostics(from: loadedSourceIndex.diagnostics))
            for record in loadedSourceIndex.records {
                insert(
                    sourceIndexAsset(record),
                    into: &assets,
                    seenIDs: &seenIDs,
                    indexedPaths: &specificallyIndexedPaths
                )
            }
        }

        if let loadedScriptOutline {
            for source in loadedScriptOutline.sources {
                insert(
                    GenIIIAsset(
                        id: "script-source:\(source.path)",
                        title: URL(fileURLWithPath: source.path).lastPathComponent,
                        subtitle: "\(source.labelCount) labels, \(source.textBlockCount) text blocks",
                        relativePath: source.path,
                        category: source.module == .text ? .text : .scripts,
                        kind: "scriptSource",
                        role: .source,
                        status: source.diagnosticCount > 0 ? .warning : .valid,
                        sourceSpan: SourceSpan(relativePath: source.path, startLine: 1),
                        tags: ["script", "source", source.module.rawValue, source.role.rawValue],
                        facts: [
                            SourceIndexFact(label: "Labels", value: "\(source.labelCount)"),
                            SourceIndexFact(label: "Commands", value: "\(source.commandCount)"),
                            SourceIndexFact(label: "Text Blocks", value: "\(source.textBlockCount)")
                        ],
                        navigationTarget: GenIIIAssetNavigationTarget(module: source.module == .text ? .text : .scripts, identifier: source.path)
                    ),
                    into: &assets,
                    seenIDs: &seenIDs,
                    indexedPaths: &specificallyIndexedPaths
                )
            }
        }

        if let loadedMapCatalog {
            for map in loadedMapCatalog.maps {
                insert(mapAsset(map), into: &assets, seenIDs: &seenIDs, indexedPaths: &specificallyIndexedPaths)
            }
            for layout in loadedMapCatalog.layoutSlots where !layout.isEmpty {
                insert(layoutAsset(layout), into: &assets, seenIDs: &seenIDs, indexedPaths: &specificallyIndexedPaths)
            }
        }

        if let loadedGraphicsReport {
            for tileset in loadedGraphicsReport.tilesets {
                insert(tilesetAsset(tileset), into: &assets, seenIDs: &seenIDs, indexedPaths: &specificallyIndexedPaths)
                for artifact in [tileset.tileImage, tileset.metatiles, tileset.metatileAttributes].compactMap({ $0 }) {
                    insert(graphicsArtifactAsset(artifact, tileset: tileset.symbol), into: &assets, seenIDs: &seenIDs, indexedPaths: &specificallyIndexedPaths)
                }
                for palette in tileset.palettes {
                    insert(graphicsArtifactAsset(palette, tileset: tileset.symbol), into: &assets, seenIDs: &seenIDs, indexedPaths: &specificallyIndexedPaths)
                }
                if let animation = tileset.animation {
                    insert(animationAsset(animation, tileset: tileset.symbol), into: &assets, seenIDs: &seenIDs, indexedPaths: &specificallyIndexedPaths)
                }
            }
        }

        for document in index.documents {
            insert(sourceDocumentAsset(document, root: root, fileManager: fileManager), into: &assets, seenIDs: &seenIDs, indexedPaths: &specificallyIndexedPaths)
        }

        for output in index.generatedOutputs {
            insert(sourceDocumentAsset(output, root: root, fileManager: fileManager), into: &assets, seenIDs: &seenIDs, indexedPaths: &specificallyIndexedPaths)
        }

        for artifact in loadedBuildReport?.generatedArtifacts ?? [] {
            insert(generatedArtifactAsset(artifact), into: &assets, seenIDs: &seenIDs, indexedPaths: &specificallyIndexedPaths)
        }

        for target in loadedBuildReport?.targets ?? [] {
            if let output = target.output {
                insert(buildOutputAsset(output, target: target.target), into: &assets, seenIDs: &seenIDs, indexedPaths: &specificallyIndexedPaths)
            }
        }

        for item in loadedResourceEntry.items where loadedResourceEntry.platform != .gbaSource {
            insert(resourceItemAsset(item, entry: loadedResourceEntry), into: &assets, seenIDs: &seenIDs, indexedPaths: &specificallyIndexedPaths)
        }
        if loadedResourceEntry.parseStatus == .failed || loadedResourceEntry.parseStatus == .unsupported {
            diagnostics.append(contentsOf: loadedResourceEntry.diagnostics)
        }

        for asset in safeSourceInventory(root: root, excluding: specificallyIndexedPaths, fileManager: fileManager) {
            insert(asset, into: &assets, seenIDs: &seenIDs, indexedPaths: &specificallyIndexedPaths)
        }

        return GenIIIAssetCatalog(
            root: index.root,
            profile: index.profile,
            adapterID: index.adapterID,
            adapterName: index.adapterName,
            assets: assets.sorted(by: assetSort),
            diagnostics: diagnostics
        )
    }

    private static func build(resourceEntry entry: GenIIIResourceEntry) -> GenIIIAssetCatalog {
        let root = SourceLocation(path: entry.path, exists: !entry.path.isEmpty)
        let assets = entry.items.map { resourceItemAsset($0, entry: entry) }
        return GenIIIAssetCatalog(
            root: root,
            profile: entry.profile,
            adapterID: entry.adapterID ?? "gen3.asset-resource",
            adapterName: entry.title,
            assets: assets.sorted(by: assetSort),
            diagnostics: entry.diagnostics
        )
    }

    private static func cachedCatalog(
        root: URL,
        identity: CacheProjectIdentity,
        fingerprint: String,
        fileManager: FileManager
    ) -> GenIIIAssetCatalog? {
        cachedPayload(root: root, identity: identity, fingerprint: fingerprint, fileManager: fileManager)?.catalog
    }

    private static func cachedPayload(
        root: URL,
        identity: CacheProjectIdentity,
        fingerprint: String,
        fileManager: FileManager
    ) -> AssetCatalogCachePayload? {
        let url = cacheURL(for: root)
        guard
            fileManager.fileExists(atPath: url.path),
            let data = try? Data(contentsOf: url),
            let payload = try? JSONDecoder.pokemonHackAssetCatalogCache.decode(AssetCatalogCachePayload.self, from: data),
            payload.schemaVersion == cacheSchemaVersion,
            payload.project == identity,
            payload.sourceFingerprint == fingerprint
        else {
            return nil
        }
        return payload
    }

    private static func cacheMetadataMatches(
        root: URL,
        identity: CacheProjectIdentity,
        fingerprint: String,
        fileManager: FileManager
    ) -> Bool {
        let url = cacheMetadataURL(for: root)
        guard
            fileManager.fileExists(atPath: url.path),
            let data = try? Data(contentsOf: url),
            let payload = try? JSONDecoder.pokemonHackAssetCatalogCache.decode(AssetCatalogCacheMetadata.self, from: data)
        else {
            return false
        }
        return payload.schemaVersion == cacheSchemaVersion
            && payload.project == identity
            && payload.sourceFingerprint == fingerprint
    }

    private static func writeCache(
        catalog: GenIIIAssetCatalog,
        root: URL,
        identity: CacheProjectIdentity,
        fingerprint: String,
        fileManager: FileManager
    ) {
        let url = cacheURL(for: root)
        let payload = AssetCatalogCachePayload(
            schemaVersion: cacheSchemaVersion,
            generatedAt: Date(),
            project: identity,
            sourceFingerprint: fingerprint,
            catalog: catalog
        )
        do {
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder.pokemonHackAssetCatalogCache.encode(payload)
            try data.write(to: url, options: .atomic)
            let metadata = AssetCatalogCacheMetadata(
                schemaVersion: payload.schemaVersion,
                generatedAt: payload.generatedAt,
                project: payload.project,
                sourceFingerprint: payload.sourceFingerprint
            )
            let metadataData = try JSONEncoder.pokemonHackAssetCatalogCache.encode(metadata)
            try metadataData.write(to: cacheMetadataURL(for: root), options: .atomic)
            let outputData = try JSONEncoder.pokemonHackPublicAssetCatalog.encode(catalog)
            try outputData.write(to: cacheOutputURL(for: root), options: .atomic)
        } catch {
            // Persistent indexes are an optimization; source builds remain authoritative.
        }
    }

    private static func cacheURL(for root: URL) -> URL {
        root.appendingPathComponent(cacheRelativePath)
    }

    private static func cacheMetadataURL(for root: URL) -> URL {
        root.appendingPathComponent(cacheMetadataRelativePath)
    }

    private static func cacheOutputURL(for root: URL) -> URL {
        root.appendingPathComponent(cacheOutputRelativePath)
    }

    private struct AssetCatalogCachePayload: Codable, Equatable {
        let schemaVersion: Int
        let generatedAt: Date
        let project: CacheProjectIdentity
        let sourceFingerprint: String
        let catalog: GenIIIAssetCatalog
    }

    private struct AssetCatalogCacheMetadata: Codable, Equatable {
        let schemaVersion: Int
        let generatedAt: Date
        let project: CacheProjectIdentity
        let sourceFingerprint: String
    }

    private struct CacheProjectIdentity: Codable, Equatable {
        let rootPath: String
        let profile: GameProfile
        let adapterID: String

        init(index: ProjectIndex) {
            rootPath = URL(fileURLWithPath: index.root.path).standardizedFileURL.path
            profile = index.profile
            adapterID = index.adapterID
        }
    }

    private struct SourceFingerprintEntry: Codable, Equatable {
        let relativePath: String
        let kind: String
        let size: UInt64?
        let modificationTime: TimeInterval?
    }

    private struct SourceFingerprintPayload: Codable, Equatable {
        let project: CacheProjectIdentity
        let index: SourceFingerprintIndex
        let files: [SourceFingerprintEntry]
    }

    private struct SourceFingerprintIndex: Codable, Equatable {
        let editorModules: [EditorModule]
        let capabilities: [CoreCapability]
        let writePolicy: WritePolicy
        let documents: [SourceFingerprintDocument]
        let generatedOutputs: [SourceFingerprintDocument]
        let buildTargets: [BuildTarget]

        init(index: ProjectIndex) {
            editorModules = index.editorModules
            capabilities = index.capabilities
            writePolicy = index.writePolicy
            documents = index.documents.map(SourceFingerprintDocument.init)
            generatedOutputs = index.generatedOutputs.map(SourceFingerprintDocument.init)
            buildTargets = index.buildTargets
        }
    }

    private struct SourceFingerprintDocument: Codable, Equatable {
        let relativePath: String
        let kind: SourceKind
        let role: SourceRole
        let exists: Bool
        let preservesUnknownFields: Bool

        init(document: SourceDocument) {
            relativePath = document.relativePath
            kind = document.kind
            role = document.role
            exists = document.exists
            preservesUnknownFields = document.preservesUnknownFields
        }
    }

    private static func sourceFingerprint(for index: ProjectIndex, fileManager: FileManager) -> String {
        let root = URL(fileURLWithPath: index.root.path).standardizedFileURL
        let payload = SourceFingerprintPayload(
            project: CacheProjectIdentity(index: index),
            index: SourceFingerprintIndex(index: index),
            files: fingerprintEntries(root: root, index: index, fileManager: fileManager)
        )
        guard let data = try? JSONEncoder.pokemonHackAssetCatalogCache.encode(payload) else {
            return "\(index.root.path)|\(index.profile.rawValue)|\(index.adapterID)"
        }
        return pokemonHackSHA1Hex(data)
    }

    private static func fingerprintEntries(root: URL, index: ProjectIndex, fileManager: FileManager) -> [SourceFingerprintEntry] {
        var entries = topLevelFingerprintEntries(root: root, fileManager: fileManager)
        for relativeRoot in inventoryRoots {
            let url = root.appendingPathComponent(relativeRoot)
            if let entry = fingerprintEntry(relativePath: relativeRoot, root: root, fileManager: fileManager), fileManager.fileExists(atPath: url.path) {
                entries.append(entry)
            }
        }
        for relativeRoot in recursiveFingerprintRoots {
            entries.append(contentsOf: recursiveFingerprintEntries(relativeRoot: relativeRoot, root: root, fileManager: fileManager))
        }
        let documentPaths = (index.documents + index.generatedOutputs).map(\.relativePath)
        let buildPaths = index.buildTargets.compactMap(\.outputPath)
        for relativePath in Set(documentPaths + buildPaths).sorted() {
            if let entry = fingerprintEntry(relativePath: relativePath, root: root, fileManager: fileManager) {
                entries.append(entry)
            }
        }
        return entries.sorted { lhs, rhs in lhs.relativePath < rhs.relativePath }
    }

    private static func recursiveFingerprintEntries(relativeRoot: String, root: URL, fileManager: FileManager) -> [SourceFingerprintEntry] {
        let url = root.appendingPathComponent(relativeRoot)
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        var entries: [SourceFingerprintEntry] = []
        while let fileURL = enumerator?.nextObject() as? URL {
            let relativePath = relativePath(for: fileURL, root: root)
            let name = fileURL.lastPathComponent
            let values = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
            if values?.isDirectory == true {
                if excludedDirectoryNames.contains(name) {
                    enumerator?.skipDescendants()
                }
                continue
            }
            guard shouldIndexInventoryPath(relativePath, indexedPaths: [], url: fileURL) else {
                continue
            }
            entries.append(
                SourceFingerprintEntry(
                    relativePath: relativePath,
                    kind: kind(forInventoryPath: relativePath),
                    size: values?.fileSize.map(UInt64.init),
                    modificationTime: values?.contentModificationDate?.timeIntervalSince1970
                )
            )
        }
        return entries
    }

    private static func fingerprintEntry(relativePath: String, root: URL, fileManager: FileManager) -> SourceFingerprintEntry? {
        let url = root.appendingPathComponent(relativePath)
        guard fileManager.fileExists(atPath: url.path) else {
            return SourceFingerprintEntry(relativePath: relativePath, kind: kind(forInventoryPath: relativePath), size: nil, modificationTime: nil)
        }
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
        let kind = values?.isDirectory == true ? "directory" : kind(forInventoryPath: relativePath)
        return SourceFingerprintEntry(
            relativePath: relativePath,
            kind: kind,
            size: values?.fileSize.map(UInt64.init),
            modificationTime: values?.contentModificationDate?.timeIntervalSince1970
        )
    }

    private static func topLevelFingerprintEntries(root: URL, fileManager: FileManager) -> [SourceFingerprintEntry] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return contents.compactMap { url in
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
            guard values?.isDirectory != true else { return nil }
            let relativePath = relativePath(for: url, root: root)
            guard shouldIndexInventoryPath(relativePath, indexedPaths: [], url: url) else { return nil }
            return SourceFingerprintEntry(
                relativePath: relativePath,
                kind: kind(forInventoryPath: relativePath),
                size: values?.fileSize.map(UInt64.init),
                modificationTime: values?.contentModificationDate?.timeIntervalSince1970
            )
        }
    }

    private static func sourceIndexAsset(_ record: SourceIndexRecord) -> GenIIIAsset {
        let category = category(for: record.module)
        return GenIIIAsset(
            id: "source-index:\(record.id)",
            title: record.title,
            subtitle: record.subtitle,
            relativePath: record.sourceSpan.relativePath,
            category: category,
            kind: "\(record.module.rawValue)Record",
            role: .source,
            status: status(for: record.diagnostics, exists: true),
            sourceSpan: record.sourceSpan,
            tags: [record.module.rawValue, category.rawValue] + record.tags,
            facts: record.facts,
            diagnostics: record.diagnostics,
            navigationTarget: navigationTarget(for: record)
        )
    }

    private static func mapAsset(_ map: MapDescriptor) -> GenIIIAsset {
        GenIIIAsset(
            id: "map:\(map.id)",
            title: map.name,
            subtitle: map.groupID ?? "Ungrouped map",
            relativePath: map.sourcePath,
            category: .maps,
            kind: "map",
            role: .source,
            sourceSpan: SourceSpan(relativePath: map.sourcePath, startLine: 1),
            tags: ["map", map.id, map.name, map.groupID ?? "", map.layout ?? ""],
            facts: [
                SourceIndexFact(label: "Layout", value: map.layout ?? "Unknown"),
                SourceIndexFact(label: "Events", value: "\(map.eventCounts.total)"),
                SourceIndexFact(label: "Connections", value: "\(map.connections.count)")
            ],
            navigationTarget: GenIIIAssetNavigationTarget(module: .maps, identifier: map.id)
        )
    }

    private static func layoutAsset(_ layout: LayoutSlot) -> GenIIIAsset {
        let title = layout.name ?? layout.layoutID ?? "Layout \(layout.slotIndex)"
        let path = layout.blockdataFilepath ?? layout.sourcePath
        return GenIIIAsset(
            id: "layout:\(layout.id)",
            title: title,
            subtitle: layout.layoutID ?? "Layout slot \(layout.slotIndex)",
            relativePath: path,
            category: .layouts,
            kind: "layout",
            role: .source,
            status: layout.blockdataPreview?.isByteCountValid == false ? .warning : .valid,
            sourceSpan: SourceSpan(relativePath: layout.sourcePath, startLine: 1),
            sizeBytes: layout.blockdataPreview.map { UInt64($0.actualByteCount) },
            tags: ["layout", layout.layoutID ?? "", layout.primaryTileset ?? "", layout.secondaryTileset ?? ""],
            facts: [
                SourceIndexFact(label: "Dimensions", value: dimensions(width: layout.width, height: layout.height)),
                SourceIndexFact(label: "Primary Tileset", value: layout.primaryTileset ?? "Unknown"),
                SourceIndexFact(label: "Secondary Tileset", value: layout.secondaryTileset ?? "Unknown")
            ],
            navigationTarget: GenIIIAssetNavigationTarget(module: .maps, identifier: layout.layoutID)
        )
    }

    private static func tilesetAsset(_ tileset: GraphicsTilesetDiagnostics) -> GenIIIAsset {
        let path = tileset.metatiles?.relativePath ?? tileset.tileImage?.relativePath ?? "src/data/tilesets/headers.h"
        return GenIIIAsset(
            id: "tileset:\(tileset.symbol)",
            title: tileset.symbol,
            subtitle: tileset.role,
            relativePath: path,
            category: .tilesets,
            kind: "tileset",
            role: .source,
            status: status(for: tileset.diagnostics, exists: true),
            sourceSpan: SourceSpan(relativePath: path, startLine: 1),
            tags: ["tileset", tileset.symbol, tileset.role],
            facts: [
                SourceIndexFact(label: "Metatiles", value: "\(tileset.metatileCount)"),
                SourceIndexFact(label: "Palettes", value: "\(tileset.palettes.count)"),
                SourceIndexFact(label: "Layer Modes", value: "normal \(tileset.layerSummary.normal), covered \(tileset.layerSummary.covered), split \(tileset.layerSummary.split)")
            ],
            diagnostics: tileset.diagnostics,
            navigationTarget: GenIIIAssetNavigationTarget(module: .graphics, identifier: tileset.symbol)
        )
    }

    private static func graphicsArtifactAsset(_ artifact: GraphicsArtifactStatus, tileset: String) -> GenIIIAsset {
        let category: GenIIIAssetCategory = artifact.kind == .palette ? .palettes : .graphics
        return GenIIIAsset(
            id: "graphics:\(artifact.kind.rawValue):\(artifact.relativePath)",
            title: URL(fileURLWithPath: artifact.relativePath).lastPathComponent,
            subtitle: tileset,
            relativePath: artifact.relativePath,
            category: category,
            kind: artifact.kind.rawValue,
            role: .source,
            status: artifact.exists ? .valid : .missing,
            sourceSpan: SourceSpan(relativePath: artifact.relativePath, startLine: 1),
            sizeBytes: artifact.sizeBytes,
            sha1: artifact.sha1,
            tags: ["graphics", artifact.kind.rawValue, tileset, artifact.freshness.rawValue],
            facts: graphicsFacts(for: artifact),
            navigationTarget: GenIIIAssetNavigationTarget(module: .graphics, identifier: tileset)
        )
    }

    private static func animationAsset(_ animation: GraphicsAnimationStatus, tileset: String) -> GenIIIAsset {
        GenIIIAsset(
            id: "graphics:animation:\(animation.relativePath)",
            title: URL(fileURLWithPath: animation.relativePath).lastPathComponent,
            subtitle: tileset,
            relativePath: animation.relativePath,
            category: .graphics,
            kind: "animationDirectory",
            role: .source,
            status: animation.exists ? .valid : .missing,
            sourceSpan: SourceSpan(relativePath: animation.relativePath, startLine: 1),
            tags: ["graphics", "animation", tileset],
            facts: [SourceIndexFact(label: "Files", value: "\(animation.fileCount)")],
            navigationTarget: GenIIIAssetNavigationTarget(module: .graphics, identifier: tileset)
        )
    }

    private static func sourceDocumentAsset(_ document: SourceDocument, root: URL, fileManager: FileManager) -> GenIIIAsset {
        let resolvedPath = resolvedDocumentPath(for: document, root: root, fileManager: fileManager)
        let exists = fileManager.fileExists(atPath: root.appendingPathComponent(resolvedPath).path)
        return GenIIIAsset(
            id: "\(document.role.rawValue):\(resolvedPath)",
            title: URL(fileURLWithPath: resolvedPath).lastPathComponent,
            subtitle: document.role.rawValue,
            relativePath: resolvedPath,
            category: category(for: document),
            kind: URL(fileURLWithPath: resolvedPath).pathExtension.isEmpty ? document.kind.rawValue : URL(fileURLWithPath: resolvedPath).pathExtension,
            role: document.role,
            status: exists ? .valid : .missing,
            sourceSpan: SourceSpan(relativePath: resolvedPath, startLine: 1),
            tags: [document.role.rawValue, document.kind.rawValue, document.relativePath],
            facts: [
                SourceIndexFact(label: "Kind", value: document.kind.rawValue),
                SourceIndexFact(label: "Preserves Unknown Fields", value: document.preservesUnknownFields ? "yes" : "no")
            ],
            navigationTarget: navigationTarget(for: document)
        )
    }

    private static func resolvedDocumentPath(for document: SourceDocument, root: URL, fileManager: FileManager) -> String {
        if document.exists {
            return document.relativePath
        }
        if document.relativePath == "src/data/items.h" {
            let jsonPath = "src/data/items.json"
            if fileManager.fileExists(atPath: root.appendingPathComponent(jsonPath).path) {
                return jsonPath
            }
        }
        if document.relativePath == "src/data/trainers.h" {
            let partyPath = "src/data/trainers.party"
            if fileManager.fileExists(atPath: root.appendingPathComponent(partyPath).path) {
                return partyPath
            }
        }
        return document.relativePath
    }

    private static func generatedArtifactAsset(_ artifact: GeneratedArtifactInventoryItem) -> GenIIIAsset {
        GenIIIAsset(
            id: "generated-artifact:\(artifact.relativePath)",
            title: URL(fileURLWithPath: artifact.relativePath).lastPathComponent,
            subtitle: artifact.exists ? "\(artifact.matchCount) match(es)" : "Missing generated artifact",
            relativePath: artifact.relativePath,
            category: .generated,
            kind: artifact.kind.rawValue,
            role: artifact.role,
            status: artifact.exists ? .valid : .missing,
            sourceSpan: SourceSpan(relativePath: artifact.relativePath, startLine: 1),
            tags: ["generated", artifact.kind.rawValue, artifact.relativePath],
            facts: [
                SourceIndexFact(label: "Matches", value: "\(artifact.matchCount)")
            ],
            navigationTarget: GenIIIAssetNavigationTarget(module: .build, identifier: artifact.relativePath)
        )
    }

    private static func buildOutputAsset(_ output: BuildOutputValidation, target: BuildTarget) -> GenIIIAsset {
        let status: GenIIIAssetStatus = output.exists ? .valid : .missing
        return GenIIIAsset(
            id: "build-output:\(target.id):\(output.relativePath)",
            title: URL(fileURLWithPath: output.relativePath).lastPathComponent,
            subtitle: target.name,
            relativePath: output.relativePath,
            category: .generated,
            kind: "buildOutput",
            role: .artifact,
            status: status,
            sourceSpan: SourceSpan(relativePath: output.relativePath, startLine: 1),
            sizeBytes: output.sizeBytes,
            sha1: output.sha1,
            tags: ["generated", "build", target.kind.rawValue, output.checksumStatus.rawValue, output.freshnessStatus.rawValue],
            facts: [
                SourceIndexFact(label: "Target", value: target.name),
                SourceIndexFact(label: "Checksum", value: output.checksumStatus.rawValue),
                SourceIndexFact(label: "Freshness", value: output.freshnessStatus.rawValue)
            ],
            navigationTarget: GenIIIAssetNavigationTarget(module: .build, identifier: output.relativePath)
        )
    }

    private static func resourceItemAsset(_ item: GenIIIResourceItem, entry: GenIIIResourceEntry) -> GenIIIAsset {
        let category = resourceItemCategory(item, entry: entry)
        return GenIIIAsset(
            id: "resource:\(entry.id):\(item.id)",
            title: URL(fileURLWithPath: item.path).lastPathComponent.isEmpty ? item.kind : URL(fileURLWithPath: item.path).lastPathComponent,
            subtitle: entry.title,
            relativePath: item.path,
            category: category,
            kind: item.kind,
            role: entry.role == .localInput ? .localInput : .reference,
            status: entry.parseStatus == .failed ? .unsupported : .valid,
            sourceSpan: SourceSpan(relativePath: item.path.isEmpty ? entry.path : item.path, startLine: 1),
            sizeBytes: item.size,
            sha1: item.sha1,
            tags: [entry.platform.rawValue, entry.family.rawValue, item.kind, item.category],
            facts: [
                SourceIndexFact(label: "Category", value: item.category),
                SourceIndexFact(label: "Offset", value: item.offset.map { "0x\(String($0, radix: 16, uppercase: true))" } ?? "source path")
            ] + item.facts,
            diagnostics: entry.diagnostics,
            navigationTarget: GenIIIAssetNavigationTarget(module: .rom, identifier: entry.id)
        )
    }

    private static func resourceItemCategory(_ item: GenIIIResourceItem, entry: GenIIIResourceEntry) -> GenIIIAssetCategory {
        if entry.platform == .gbaROM || entry.platform == .ndsROM {
            return .rom
        }
        if entry.platform == .ndsSource {
            if item.category.hasPrefix("NDS Data ") {
                return category(forNDSDataDomain: String(item.category.dropFirst("NDS Data ".count)))
            }
            if item.category == "NDS Build Target" || item.category == "NDS Variant" {
                return .generated
            }
            return .source
        }
        return .media
    }

    private static func category(forNDSDataDomain domain: String) -> GenIIIAssetCategory {
        switch domain {
        case NDSDataDomain.species.rawValue, NDSDataDomain.personal.rawValue:
            return .species
        case NDSDataDomain.moves.rawValue:
            return .moves
        case NDSDataDomain.items.rawValue:
            return .items
        case NDSDataDomain.trainers.rawValue:
            return .trainers
        case NDSDataDomain.encounters.rawValue:
            return .encounters
        case NDSDataDomain.text.rawValue:
            return .text
        case NDSDataDomain.scripts.rawValue:
            return .scripts
        case NDSDataDomain.maps.rawValue:
            return .maps
        case NDSDataDomain.audio.rawValue:
            return .audio
        case NDSDataDomain.resources.rawValue:
            return .source
        default:
            return .source
        }
    }

    private static func safeSourceInventory(
        root: URL,
        excluding indexedPaths: Set<String>,
        fileManager: FileManager
    ) -> [GenIIIAsset] {
        var assets: [GenIIIAsset] = []
        for relativeRoot in inventoryRoots {
            let url = root.appendingPathComponent(relativeRoot)
            guard fileManager.fileExists(atPath: url.path) else { continue }
            let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )

            while let fileURL = enumerator?.nextObject() as? URL {
                let relativePath = relativePath(for: fileURL, root: root)
                let name = fileURL.lastPathComponent
                let values = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
                if values?.isDirectory == true {
                    if excludedDirectoryNames.contains(name) {
                        enumerator?.skipDescendants()
                    }
                    continue
                }

                guard shouldIndexInventoryPath(relativePath, indexedPaths: indexedPaths, url: fileURL) else {
                    continue
                }

                let category = inferredInventoryCategory(relativePath)
                assets.append(
                    GenIIIAsset(
                        id: "inventory:\(relativePath)",
                        title: fileURL.lastPathComponent,
                        subtitle: category.rawValue,
                        relativePath: relativePath,
                        category: category,
                        kind: kind(forInventoryPath: relativePath),
                        role: .source,
                        sourceSpan: SourceSpan(relativePath: relativePath, startLine: 1),
                        sizeBytes: values?.fileSize.map(UInt64.init),
                        tags: ["inventory", category.rawValue, relativePath],
                        navigationTarget: navigationTarget(forCategory: category, identifier: relativePath)
                    )
                )
            }
        }
        return assets
    }

    private static func insert(
        _ asset: GenIIIAsset,
        into assets: inout [GenIIIAsset],
        seenIDs: inout Set<String>,
        indexedPaths: inout Set<String>
    ) {
        guard !seenIDs.contains(asset.id) else { return }
        seenIDs.insert(asset.id)
        assets.append(asset)
        if !asset.relativePath.isEmpty {
            indexedPaths.insert(asset.relativePath)
        }
        if let span = asset.sourceSpan {
            indexedPaths.insert(span.relativePath)
        }
    }

    private static func catalogDiagnostics(from diagnostics: [Diagnostic]) -> [Diagnostic] {
        diagnostics.filter { diagnostic in
            diagnostic.code == "SOURCE_INDEX_DESCRIPTOR_MISSING"
                || diagnostic.code == "TABLE_NOT_FOUND"
        }
    }

    private static func sourceIndexModule(for category: GenIIIAssetCategory) -> SourceIndexModule? {
        switch category {
        case .scripts:
            .scripts
        case .text:
            .text
        case .species:
            .pokemon
        case .trainers:
            .trainers
        case .items:
            .items
        case .moves:
            .moves
        case .learnsets:
            .learnsets
        case .evolutions:
            .evolutions
        case .pokedex:
            .pokedex
        case .encounters:
            .encounters
        default:
            nil
        }
    }

    private static func category(for module: SourceIndexModule) -> GenIIIAssetCategory {
        switch module {
        case .scripts:
            .scripts
        case .text:
            .text
        case .pokemon:
            .species
        case .trainers:
            .trainers
        case .items:
            .items
        case .moves:
            .moves
        case .learnsets:
            .learnsets
        case .evolutions:
            .evolutions
        case .pokedex:
            .pokedex
        case .encounters:
            .encounters
        }
    }

    private static func category(for document: SourceDocument) -> GenIIIAssetCategory {
        if document.role == .generated || document.role == .artifact {
            return .generated
        }
        switch document.kind {
        case .mapJson:
            return .maps
        case .layoutJson:
            return .layouts
        case .script:
            return .scripts
        case .text:
            return .text
        case .graphics:
            return .graphics
        case .palette:
            return .palettes
        case .rom:
            return .rom
        default:
            return inferredInventoryCategory(document.relativePath)
        }
    }

    private static func inferredInventoryCategory(_ relativePath: String) -> GenIIIAssetCategory {
        let lower = relativePath.lowercased()
        if lower.hasPrefix("data/maps/") { return .maps }
        if lower.contains("wild_encounters") { return .encounters }
        if lower.hasPrefix("data/layouts/") { return .layouts }
        if lower.hasPrefix("data/scripts/") || lower.hasSuffix(".inc") { return .scripts }
        if lower.hasPrefix("data/text/") || lower.contains("/text/") { return .text }
        if lower.contains("species") || lower.contains("base_stats") { return .species }
        if lower.contains("trainer") { return .trainers }
        if lower.contains("item") { return .items }
        if lower.contains("battle_moves") || lower.contains("move_names") || lower.contains("move_descriptions") { return .moves }
        if lower.contains("learnset") || lower.contains("egg_moves") || lower.contains("tmhm") || lower.contains("tutor") { return .learnsets }
        if lower.contains("evolution") { return .evolutions }
        if lower.contains("pokedex") { return .pokedex }
        if lower.hasPrefix("graphics/") || lower.contains("/graphics/") {
            if lower.hasSuffix(".pal") || lower.hasSuffix(".gbapal") {
                return .palettes
            }
            return .graphics
        }
        if lower.hasPrefix("sound/") || lower.hasPrefix("songs/") || lower.contains("/songs/") {
            return .audio
        }
        return .source
    }

    private static func kind(forInventoryPath relativePath: String) -> String {
        let ext = URL(fileURLWithPath: relativePath).pathExtension
        return ext.isEmpty ? "source" : ext
    }

    private static func status(for diagnostics: [Diagnostic], exists: Bool) -> GenIIIAssetStatus {
        guard exists else { return .missing }
        if diagnostics.contains(where: { $0.severity == .error }) {
            return .error
        }
        if diagnostics.contains(where: { $0.severity == .warning }) {
            return .warning
        }
        return .valid
    }

    private static func navigationTarget(for record: SourceIndexRecord) -> GenIIIAssetNavigationTarget? {
        switch record.module {
        case .scripts:
            return GenIIIAssetNavigationTarget(module: .scripts, identifier: record.title)
        case .text:
            return GenIIIAssetNavigationTarget(module: .text, identifier: record.title)
        case .pokemon, .moves, .learnsets, .evolutions, .pokedex:
            return GenIIIAssetNavigationTarget(module: .pokemon, identifier: record.title)
        case .trainers:
            return GenIIIAssetNavigationTarget(module: .trainers, identifier: record.title)
        case .items:
            return GenIIIAssetNavigationTarget(module: .items, identifier: record.title)
        case .encounters:
            return GenIIIAssetNavigationTarget(module: .encounters, identifier: record.title)
        }
    }

    private static func navigationTarget(for document: SourceDocument) -> GenIIIAssetNavigationTarget? {
        navigationTarget(forCategory: category(for: document), identifier: document.relativePath)
    }

    private static func navigationTarget(forCategory category: GenIIIAssetCategory, identifier: String?) -> GenIIIAssetNavigationTarget? {
        switch category {
        case .maps, .layouts:
            return GenIIIAssetNavigationTarget(module: .maps, identifier: identifier)
        case .scripts:
            return GenIIIAssetNavigationTarget(module: .scripts, identifier: identifier)
        case .text:
            return GenIIIAssetNavigationTarget(module: .text, identifier: identifier)
        case .species, .moves, .learnsets, .evolutions, .pokedex:
            return GenIIIAssetNavigationTarget(module: .pokemon, identifier: identifier)
        case .trainers:
            return GenIIIAssetNavigationTarget(module: .trainers, identifier: identifier)
        case .items:
            return GenIIIAssetNavigationTarget(module: .items, identifier: identifier)
        case .encounters:
            return GenIIIAssetNavigationTarget(module: .encounters, identifier: identifier)
        case .graphics, .palettes, .tilesets:
            return GenIIIAssetNavigationTarget(module: .graphics, identifier: identifier)
        case .generated:
            return GenIIIAssetNavigationTarget(module: .build, identifier: identifier)
        case .rom, .media, .source, .audio, .unknown:
            return GenIIIAssetNavigationTarget(module: .rom, identifier: identifier)
        }
    }

    private static func shouldIndexInventoryPath(_ relativePath: String, indexedPaths: Set<String>, url: URL) -> Bool {
        guard !indexedPaths.contains(relativePath) else { return false }
        let pathComponents = relativePath.split(separator: "/").map(String.init)
        guard !pathComponents.contains(where: { excludedDirectoryNames.contains($0) }) else { return false }
        let ext = url.pathExtension.lowercased()
        guard !excludedExtensions.contains(ext) else { return false }
        guard !relativePath.contains(".xcodeproj/"), !relativePath.contains(".xcworkspace/") else { return false }
        return true
    }

    private static func graphicsFacts(for artifact: GraphicsArtifactStatus) -> [SourceIndexFact] {
        var facts = [
            SourceIndexFact(label: "Freshness", value: artifact.freshness.rawValue)
        ]
        if let png = artifact.png {
            facts.append(SourceIndexFact(label: "PNG", value: "\(png.width)x\(png.height), \(png.bitDepth)-bit"))
            if let colors = png.paletteColorCount {
                facts.append(SourceIndexFact(label: "Palette Colors", value: "\(colors)"))
            }
        }
        if let palette = artifact.palette {
            facts.append(SourceIndexFact(label: "Palette", value: "\(palette.colorCount) colors"))
        }
        return facts
    }

    private static func dimensions(width: Int?, height: Int?) -> String {
        guard let width, let height else { return "Unknown" }
        return "\(width)x\(height)"
    }

    private static func relativePath(for url: URL, root: URL) -> String {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        if path.hasPrefix(rootPath + "/") {
            return String(path.dropFirst(rootPath.count + 1))
        }
        return path
    }

    private static func assetSort(_ lhs: GenIIIAsset, _ rhs: GenIIIAsset) -> Bool {
        if lhs.category.rawValue == rhs.category.rawValue {
            if lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedSame {
                return lhs.relativePath < rhs.relativePath
            }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
        return lhs.category.rawValue < rhs.category.rawValue
    }
}

private extension JSONEncoder {
    static var pokemonHackPublicAssetCatalog: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    static var pokemonHackAssetCatalogCache: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var pokemonHackAssetCatalogCache: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
