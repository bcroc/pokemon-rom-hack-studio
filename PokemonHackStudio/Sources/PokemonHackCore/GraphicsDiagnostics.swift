import CryptoKit
import Foundation

public enum GraphicsArtifactKind: String, Codable, Equatable, CaseIterable {
    case tileImage
    case palette
    case metatiles
    case metatileAttributes
    case animationDirectory
    case sourceDirectory
    case unsupportedSource
}

public enum GraphicsArtifactFreshness: String, Codable, Equatable {
    case sourceOnly
    case generatedMissing
    case generatedFresh
    case generatedStale
    case unknown
}

public struct GraphicsPNGMetadata: Codable, Equatable {
    public let width: Int
    public let height: Int
    public let bitDepth: Int
    public let colorType: Int
    public let paletteColorCount: Int?
    public let hasTransparencyChunk: Bool

    public init(
        width: Int,
        height: Int,
        bitDepth: Int,
        colorType: Int,
        paletteColorCount: Int? = nil,
        hasTransparencyChunk: Bool = false
    ) {
        self.width = width
        self.height = height
        self.bitDepth = bitDepth
        self.colorType = colorType
        self.paletteColorCount = paletteColorCount
        self.hasTransparencyChunk = hasTransparencyChunk
    }
}

public struct GraphicsPaletteMetadata: Codable, Equatable {
    public let format: String
    public let colorCount: Int
    public let gbaPrecisionLossCount: Int
    public let hasSlotZero: Bool

    public init(format: String, colorCount: Int, gbaPrecisionLossCount: Int = 0, hasSlotZero: Bool = false) {
        self.format = format
        self.colorCount = colorCount
        self.gbaPrecisionLossCount = gbaPrecisionLossCount
        self.hasSlotZero = hasSlotZero
    }
}

public struct GraphicsArtifactStatus: Codable, Equatable, Identifiable {
    public var id: String { "\(kind.rawValue):\(relativePath)" }

    public let relativePath: String
    public let kind: GraphicsArtifactKind
    public let exists: Bool
    public let sizeBytes: UInt64?
    public let modifiedAt: Date?
    public let sha1: String?
    public let generatedRelativePath: String?
    public let generatedExists: Bool?
    public let generatedModifiedAt: Date?
    public let freshness: GraphicsArtifactFreshness
    public let png: GraphicsPNGMetadata?
    public let palette: GraphicsPaletteMetadata?

    public init(
        relativePath: String,
        kind: GraphicsArtifactKind,
        exists: Bool,
        sizeBytes: UInt64? = nil,
        modifiedAt: Date? = nil,
        sha1: String? = nil,
        generatedRelativePath: String? = nil,
        generatedExists: Bool? = nil,
        generatedModifiedAt: Date? = nil,
        freshness: GraphicsArtifactFreshness = .sourceOnly,
        png: GraphicsPNGMetadata? = nil,
        palette: GraphicsPaletteMetadata? = nil
    ) {
        self.relativePath = relativePath
        self.kind = kind
        self.exists = exists
        self.sizeBytes = sizeBytes
        self.modifiedAt = modifiedAt
        self.sha1 = sha1
        self.generatedRelativePath = generatedRelativePath
        self.generatedExists = generatedExists
        self.generatedModifiedAt = generatedModifiedAt
        self.freshness = freshness
        self.png = png
        self.palette = palette
    }
}

public struct GraphicsAnimationStatus: Codable, Equatable {
    public let relativePath: String
    public let exists: Bool
    public let fileCount: Int

    public init(relativePath: String, exists: Bool, fileCount: Int = 0) {
        self.relativePath = relativePath
        self.exists = exists
        self.fileCount = fileCount
    }
}

public struct GraphicsLayerModeSummary: Codable, Equatable {
    public let normal: Int
    public let covered: Int
    public let split: Int
    public let unknown: Int
    public let missing: Int

    public init(normal: Int = 0, covered: Int = 0, split: Int = 0, unknown: Int = 0, missing: Int = 0) {
        self.normal = normal
        self.covered = covered
        self.split = split
        self.unknown = unknown
        self.missing = missing
    }
}

public struct GraphicsTilesetDiagnostics: Codable, Equatable, Identifiable {
    public var id: String { symbol }

    public let symbol: String
    public let role: String
    public let tileImage: GraphicsArtifactStatus?
    public let palettes: [GraphicsArtifactStatus]
    public let metatiles: GraphicsArtifactStatus?
    public let metatileAttributes: GraphicsArtifactStatus?
    public let animation: GraphicsAnimationStatus?
    public let metatileCount: Int
    public let layerSummary: GraphicsLayerModeSummary
    public let diagnostics: [Diagnostic]

    public init(
        symbol: String,
        role: String,
        tileImage: GraphicsArtifactStatus?,
        palettes: [GraphicsArtifactStatus],
        metatiles: GraphicsArtifactStatus?,
        metatileAttributes: GraphicsArtifactStatus?,
        animation: GraphicsAnimationStatus?,
        metatileCount: Int,
        layerSummary: GraphicsLayerModeSummary,
        diagnostics: [Diagnostic] = []
    ) {
        self.symbol = symbol
        self.role = role
        self.tileImage = tileImage
        self.palettes = palettes
        self.metatiles = metatiles
        self.metatileAttributes = metatileAttributes
        self.animation = animation
        self.metatileCount = metatileCount
        self.layerSummary = layerSummary
        self.diagnostics = diagnostics
    }
}

public struct GraphicsSourceAssetInventory: Codable, Equatable {
    public let rootRelativePath: String
    public let tileImageCount: Int
    public let paletteFileCount: Int
    public let metatileBinaryCount: Int
    public let attributeBinaryCount: Int
    public let animationDirectoryCount: Int
    public let unsupportedSourceArtifactCount: Int
    public let pathsWithSpacesCount: Int
    public let readmeCount: Int

    public init(
        rootRelativePath: String,
        tileImageCount: Int = 0,
        paletteFileCount: Int = 0,
        metatileBinaryCount: Int = 0,
        attributeBinaryCount: Int = 0,
        animationDirectoryCount: Int = 0,
        unsupportedSourceArtifactCount: Int = 0,
        pathsWithSpacesCount: Int = 0,
        readmeCount: Int = 0
    ) {
        self.rootRelativePath = rootRelativePath
        self.tileImageCount = tileImageCount
        self.paletteFileCount = paletteFileCount
        self.metatileBinaryCount = metatileBinaryCount
        self.attributeBinaryCount = attributeBinaryCount
        self.animationDirectoryCount = animationDirectoryCount
        self.unsupportedSourceArtifactCount = unsupportedSourceArtifactCount
        self.pathsWithSpacesCount = pathsWithSpacesCount
        self.readmeCount = readmeCount
    }
}

public struct GraphicsDiagnosticsReport: Codable, Equatable {
    public let root: SourceLocation
    public let profile: GameProfile
    public let adapterID: String
    public let adapterName: String
    public let generatedAt: Date
    public let isReadOnly: Bool
    public let inventory: GraphicsSourceAssetInventory
    public let tilesets: [GraphicsTilesetDiagnostics]
    public let diagnostics: [Diagnostic]

    public init(
        root: SourceLocation,
        profile: GameProfile,
        adapterID: String,
        adapterName: String,
        generatedAt: Date = Date(),
        isReadOnly: Bool = true,
        inventory: GraphicsSourceAssetInventory,
        tilesets: [GraphicsTilesetDiagnostics],
        diagnostics: [Diagnostic] = []
    ) {
        self.root = root
        self.profile = profile
        self.adapterID = adapterID
        self.adapterName = adapterName
        self.generatedAt = generatedAt
        self.isReadOnly = isReadOnly
        self.inventory = inventory
        self.tilesets = tilesets
        self.diagnostics = diagnostics
    }
}

public enum GraphicsDiagnosticsReportBuilder {
    public static func build(
        index: ProjectIndex,
        fileManager: FileManager = .default
    ) -> GraphicsDiagnosticsReport {
        let root = URL(fileURLWithPath: index.root.path).standardizedFileURL
        let inventory = sourceInventory(root: root, fileManager: fileManager)
        let tilesetIndex: TilesetIndex
        do {
            tilesetIndex = try TilesetIndexLoader.load(from: index, fileManager: fileManager)
        } catch {
            let diagnostic = Diagnostic(
                severity: .warning,
                code: "GRAPHICS_TILESET_INDEX_UNAVAILABLE",
                message: "Could not load tileset index: \(error.localizedDescription)",
                span: SourceSpan(relativePath: "src/data/tilesets/headers.h", startLine: 1)
            )
            return GraphicsDiagnosticsReport(
                root: index.root,
                profile: index.profile,
                adapterID: index.adapterID,
                adapterName: index.adapterName,
                inventory: inventory,
                tilesets: [],
                diagnostics: [diagnostic]
            )
        }

        var diagnostics = tilesetIndex.diagnostics
        let tilesets = tilesetIndex.assets.map { asset in
            let tileset = tilesetDiagnostics(for: asset, root: root, fileManager: fileManager)
            diagnostics.append(contentsOf: tileset.diagnostics)
            return tileset
        }

        if inventory.pathsWithSpacesCount > 0 {
            diagnostics.append(
                Diagnostic(
                    severity: .info,
                    code: "GRAPHICS_PATH_CONTAINS_SPACES",
                    message: "\(inventory.pathsWithSpacesCount) graphics path(s) contain spaces and may need careful quoting in external-tool plans.",
                    span: SourceSpan(relativePath: inventory.rootRelativePath, startLine: 1)
                )
            )
        }

        if inventory.unsupportedSourceArtifactCount > 0 {
            diagnostics.append(
                Diagnostic(
                    severity: .info,
                    code: "GRAPHICS_UNSUPPORTED_SOURCE_ARTIFACT",
                    message: "\(inventory.unsupportedSourceArtifactCount) design/archive artifact(s) are local inputs, not directly writable decomp graphics outputs.",
                    span: SourceSpan(relativePath: inventory.rootRelativePath, startLine: 1)
                )
            )
        }

        return GraphicsDiagnosticsReport(
            root: index.root,
            profile: index.profile,
            adapterID: index.adapterID,
            adapterName: index.adapterName,
            inventory: inventory,
            tilesets: tilesets,
            diagnostics: diagnostics
        )
    }

    private static func tilesetDiagnostics(
        for asset: TilesetAsset,
        root: URL,
        fileManager: FileManager
    ) -> GraphicsTilesetDiagnostics {
        var diagnostics = asset.diagnostics
        let tileImage = asset.tileImagePath.map {
            artifactStatus(root: root, path: $0, kind: .tileImage, fileManager: fileManager)
        }
        if let tileImage, !tileImage.exists {
            diagnostics.append(missingDiagnostic("GRAPHICS_TILE_IMAGE_MISSING", "\(asset.symbol) tile image is missing: \(tileImage.relativePath)", tileImage.relativePath))
        } else if let tileImage, let paletteColorCount = tileImage.png?.paletteColorCount, paletteColorCount > 16 {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "GRAPHICS_IMAGE_TOO_MANY_COLORS_FOR_4BPP",
                    message: "\(tileImage.relativePath) declares \(paletteColorCount) palette color(s); 4bpp tiles should fit within 16 colors before conversion.",
                    span: SourceSpan(relativePath: tileImage.relativePath, startLine: 1)
                )
            )
        }
        if let tileImage {
            diagnostics.append(contentsOf: generatedArtifactDiagnostics(for: tileImage, owner: asset.symbol))
        }

        let palettes = asset.palettePaths.map {
            artifactStatus(root: root, path: $0, kind: .palette, fileManager: fileManager)
        }
        for palette in palettes {
            if !palette.exists {
                diagnostics.append(missingDiagnostic("GRAPHICS_PALETTE_MISSING", "\(asset.symbol) palette is missing: \(palette.relativePath)", palette.relativePath))
            } else if let metadata = palette.palette, metadata.colorCount != 16 {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "GRAPHICS_PALETTE_COLOR_COUNT_UNEXPECTED",
                        message: "\(palette.relativePath) has \(metadata.colorCount) color(s); Gen III tileset palette files are expected to carry 16 colors.",
                        span: SourceSpan(relativePath: palette.relativePath, startLine: 1)
                    )
                )
            }
            if let metadata = palette.palette, metadata.gbaPrecisionLossCount > 0 {
                diagnostics.append(
                    Diagnostic(
                        severity: .info,
                        code: "GRAPHICS_15BIT_PRECISION_LOSS",
                        message: "\(palette.relativePath) has \(metadata.gbaPrecisionLossCount) color(s) that lose precision when represented as GBA 15-bit color.",
                        span: SourceSpan(relativePath: palette.relativePath, startLine: 1)
                    )
                )
            }
            diagnostics.append(contentsOf: generatedArtifactDiagnostics(for: palette, owner: asset.symbol))
        }

        let metatiles = asset.metatilesPath.map {
            artifactStatus(root: root, path: $0, kind: .metatiles, fileManager: fileManager)
        }
        if let metatiles, !metatiles.exists {
            diagnostics.append(missingDiagnostic("GRAPHICS_METATILES_MISSING", "\(asset.symbol) metatile data is missing: \(metatiles.relativePath)", metatiles.relativePath))
        }

        let attributes = asset.metatileAttributesPath.map {
            artifactStatus(root: root, path: $0, kind: .metatileAttributes, fileManager: fileManager)
        }
        if let attributes, !attributes.exists {
            diagnostics.append(missingDiagnostic("GRAPHICS_METATILE_ATTRIBUTES_MISSING", "\(asset.symbol) metatile attributes are missing: \(attributes.relativePath)", attributes.relativePath))
        }

        let layerSummary = layerSummary(asset: asset, root: root, fileManager: fileManager)
        if layerSummary.unknown > 0 {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "GRAPHICS_METATILE_LAYER_UNKNOWN",
                    message: "\(asset.symbol) has \(layerSummary.unknown) metatile attribute(s) with unknown layer-mode values.",
                    span: asset.metatileAttributesPath.map { SourceSpan(relativePath: $0, startLine: 1) }
                )
            )
        }

        let animation = animationStatus(asset: asset, root: root, fileManager: fileManager)

        return GraphicsTilesetDiagnostics(
            symbol: asset.symbol,
            role: asset.isSecondary ? "Secondary" : "Primary",
            tileImage: tileImage,
            palettes: palettes,
            metatiles: metatiles,
            metatileAttributes: attributes,
            animation: animation,
            metatileCount: asset.metatileCount,
            layerSummary: layerSummary,
            diagnostics: diagnostics
        )
    }

    private static func artifactStatus(
        root: URL,
        path: String,
        kind: GraphicsArtifactKind,
        fileManager: FileManager
    ) -> GraphicsArtifactStatus {
        let url = root.appendingPathComponent(path)
        let exists = fileManager.fileExists(atPath: url.path)
        if !exists, let sourceBacked = sourceBackedGeneratedArtifactStatus(
            root: root,
            path: path,
            kind: kind,
            fileManager: fileManager
        ) {
            return sourceBacked
        }
        let generatedRelativePath = generatedArtifactPath(for: path, kind: kind, root: root, fileManager: fileManager)
        let generatedURL = generatedRelativePath.map { root.appendingPathComponent($0) }
        let generatedAttributes = generatedURL.flatMap { try? fileManager.attributesOfItem(atPath: $0.path) }
        let generatedExists = generatedURL.map { fileManager.fileExists(atPath: $0.path) }
        let generatedModifiedAt = generatedAttributes?[.modificationDate] as? Date
        guard exists else {
            return GraphicsArtifactStatus(
                relativePath: path,
                kind: kind,
                exists: false,
                generatedRelativePath: generatedRelativePath,
                generatedExists: generatedExists,
                generatedModifiedAt: generatedModifiedAt,
                freshness: generatedRelativePath == nil ? .sourceOnly : .unknown
            )
        }

        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        let size = attributes?[.size] as? UInt64
        let modifiedAt = attributes?[.modificationDate] as? Date
        let data = try? Data(contentsOf: url)
        let freshness = artifactFreshness(
            generatedRelativePath: generatedRelativePath,
            generatedExists: generatedExists,
            sourceModifiedAt: modifiedAt,
            generatedModifiedAt: generatedModifiedAt
        )
        return GraphicsArtifactStatus(
            relativePath: path,
            kind: kind,
            exists: true,
            sizeBytes: size ?? data.map { UInt64($0.count) },
            modifiedAt: modifiedAt,
            sha1: data.map(sha1Hex),
            generatedRelativePath: generatedRelativePath,
            generatedExists: generatedExists,
            generatedModifiedAt: generatedModifiedAt,
            freshness: freshness,
            png: data.flatMap { path.lowercased().hasSuffix(".png") ? pngMetadata(from: $0) : nil },
            palette: data.flatMap { paletteMetadata(from: $0, path: path) }
        )
    }

    private static func sourceBackedGeneratedArtifactStatus(
        root: URL,
        path: String,
        kind: GraphicsArtifactKind,
        fileManager: FileManager
    ) -> GraphicsArtifactStatus? {
        let lowercased = path.lowercased()
        let sourcePath: String?
        switch kind {
        case .palette where lowercased.hasSuffix(".gbapal"):
            sourcePath = String(path.dropLast(".gbapal".count)) + ".pal"
        case .tileImage where lowercased.hasSuffix(".4bpp.lz"):
            sourcePath = String(path.dropLast(".4bpp.lz".count)) + ".png"
        case .tileImage where lowercased.hasSuffix(".4bpp"):
            sourcePath = String(path.dropLast(".4bpp".count)) + ".png"
        default:
            sourcePath = nil
        }

        guard let sourcePath else { return nil }
        let sourceURL = root.appendingPathComponent(sourcePath)
        guard fileManager.fileExists(atPath: sourceURL.path) else { return nil }

        let attributes = try? fileManager.attributesOfItem(atPath: sourceURL.path)
        let size = attributes?[.size] as? UInt64
        let modifiedAt = attributes?[.modificationDate] as? Date
        let data = try? Data(contentsOf: sourceURL)
        let generatedURL = root.appendingPathComponent(path)
        let generatedAttributes = try? fileManager.attributesOfItem(atPath: generatedURL.path)
        let generatedModifiedAt = generatedAttributes?[.modificationDate] as? Date

        return GraphicsArtifactStatus(
            relativePath: sourcePath,
            kind: kind,
            exists: true,
            sizeBytes: size ?? data.map { UInt64($0.count) },
            modifiedAt: modifiedAt,
            sha1: data.map(sha1Hex),
            generatedRelativePath: path,
            generatedExists: false,
            generatedModifiedAt: generatedModifiedAt,
            freshness: .generatedMissing,
            png: data.flatMap { sourcePath.lowercased().hasSuffix(".png") ? pngMetadata(from: $0) : nil },
            palette: data.flatMap { paletteMetadata(from: $0, path: sourcePath) }
        )
    }

    private static func generatedArtifactPath(
        for path: String,
        kind: GraphicsArtifactKind,
        root: URL,
        fileManager: FileManager
    ) -> String? {
        let lowercased = path.lowercased()
        switch kind {
        case .tileImage where lowercased.hasSuffix(".png"):
            let base = String(path.dropLast(4))
            let compressed = base + ".4bpp.lz"
            if fileManager.fileExists(atPath: root.appendingPathComponent(compressed).path) {
                return compressed
            }
            let uncompressed = base + ".4bpp"
            if fileManager.fileExists(atPath: root.appendingPathComponent(uncompressed).path) {
                return uncompressed
            }
            return compressed
        case .palette where lowercased.hasSuffix(".pal"):
            return String(path.dropLast(4)) + ".gbapal"
        default:
            return nil
        }
    }

    private static func artifactFreshness(
        generatedRelativePath: String?,
        generatedExists: Bool?,
        sourceModifiedAt: Date?,
        generatedModifiedAt: Date?
    ) -> GraphicsArtifactFreshness {
        guard generatedRelativePath != nil else { return .sourceOnly }
        guard generatedExists == true else { return .generatedMissing }
        guard let sourceModifiedAt, let generatedModifiedAt else { return .unknown }
        return generatedModifiedAt >= sourceModifiedAt ? .generatedFresh : .generatedStale
    }

    private static func paletteMetadata(from data: Data, path: String) -> GraphicsPaletteMetadata? {
        let lowercased = path.lowercased()
        if lowercased.hasSuffix(".gbapal") {
            return GraphicsPaletteMetadata(format: "GBA", colorCount: data.count / 2, hasSlotZero: data.count >= 2)
        }

        guard lowercased.hasSuffix(".pal") else { return nil }
        guard let text = String(data: data, encoding: .utf8) else { return nil }
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard lines.first == "JASC-PAL", lines.count >= 3, let declaredCount = Int(lines[2]) else {
            return nil
        }

        let colorLines = lines.dropFirst(3).prefix(declaredCount)
        var precisionLoss = 0
        for line in colorLines {
            let channels = line.split(separator: " ").compactMap { Int($0) }
            if channels.count >= 3, channels.prefix(3).contains(where: { $0 % 8 != 0 }) {
                precisionLoss += 1
            }
        }

        return GraphicsPaletteMetadata(
            format: "JASC-PAL",
            colorCount: min(declaredCount, colorLines.count),
            gbaPrecisionLossCount: precisionLoss,
            hasSlotZero: !colorLines.isEmpty
        )
    }

    private static func pngMetadata(from data: Data) -> GraphicsPNGMetadata? {
        let signature: [UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
        guard data.count >= 33, Array(data.prefix(8)) == signature else { return nil }

        var offset = 8
        var width: Int?
        var height: Int?
        var bitDepth: Int?
        var colorType: Int?
        var paletteCount: Int?
        var hasTransparency = false

        while offset + 8 <= data.count {
            let length = Int(readUInt32BE(data, offset: offset))
            let typeStart = offset + 4
            let dataStart = offset + 8
            let dataEnd = dataStart + length
            let next = dataEnd + 4
            guard dataEnd <= data.count, next <= data.count else { break }
            let type = String(decoding: data[typeStart..<typeStart + 4], as: UTF8.self)

            if type == "IHDR", length >= 13 {
                width = Int(readUInt32BE(data, offset: dataStart))
                height = Int(readUInt32BE(data, offset: dataStart + 4))
                bitDepth = Int(data[dataStart + 8])
                colorType = Int(data[dataStart + 9])
            } else if type == "PLTE" {
                paletteCount = length / 3
            } else if type == "tRNS" {
                hasTransparency = true
            } else if type == "IEND" {
                break
            }

            offset = next
        }

        guard let width, let height, let bitDepth, let colorType else { return nil }
        return GraphicsPNGMetadata(
            width: width,
            height: height,
            bitDepth: bitDepth,
            colorType: colorType,
            paletteColorCount: paletteCount,
            hasTransparencyChunk: hasTransparency
        )
    }

    private static func layerSummary(
        asset: TilesetAsset,
        root: URL,
        fileManager: FileManager
    ) -> GraphicsLayerModeSummary {
        guard let path = asset.metatileAttributesPath,
              fileManager.fileExists(atPath: root.appendingPathComponent(path).path),
              let data = try? Data(contentsOf: root.appendingPathComponent(path))
        else {
            return GraphicsLayerModeSummary(missing: max(asset.metatileCount, 0))
        }

        var normal = 0
        var covered = 0
        var split = 0
        var unknown = 0
        let strideBy = max(asset.metatileAttributeWordSize, 2)
        for offset in stride(from: 0, to: data.count - (data.count % strideBy), by: strideBy) {
            let rawValue: UInt32
            if strideBy == 4 {
                rawValue = readUInt32LE(data, offset: offset)
            } else {
                rawValue = UInt32(readUInt16LE(data, offset: offset))
            }
            switch MetatileLayerType.rawLayerType(from: rawValue, wordSize: strideBy) {
            case MetatileLayerType.normal.rawValue:
                normal += 1
            case MetatileLayerType.covered.rawValue:
                covered += 1
            case MetatileLayerType.split.rawValue:
                split += 1
            default:
                unknown += 1
            }
        }

        let decoded = normal + covered + split + unknown
        return GraphicsLayerModeSummary(
            normal: normal,
            covered: covered,
            split: split,
            unknown: unknown,
            missing: max(asset.metatileCount - decoded, 0)
        )
    }

    private static func animationStatus(
        asset: TilesetAsset,
        root: URL,
        fileManager: FileManager
    ) -> GraphicsAnimationStatus? {
        guard let basePath = asset.metatilesPath ?? asset.tileImagePath else { return nil }
        let directory = (basePath as NSString).deletingLastPathComponent + "/anim"
        let url = root.appendingPathComponent(directory)
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return GraphicsAnimationStatus(relativePath: directory, exists: false)
        }

        let fileCount = (fileManager.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey])?
            .compactMap { $0 as? URL }
            .filter { (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true }
            .count) ?? 0
        return GraphicsAnimationStatus(relativePath: directory, exists: true, fileCount: fileCount)
    }

    private static func sourceInventory(root: URL, fileManager: FileManager) -> GraphicsSourceAssetInventory {
        let relativeRoot = "data/tilesets"
        let url = root.appendingPathComponent(relativeRoot)
        guard fileManager.fileExists(atPath: url.path) else {
            return GraphicsSourceAssetInventory(rootRelativePath: relativeRoot)
        }

        var tileImageCount = 0
        var paletteFileCount = 0
        var metatileBinaryCount = 0
        var attributeBinaryCount = 0
        var animationDirectoryCount = 0
        var unsupportedSourceArtifactCount = 0
        var pathsWithSpacesCount = 0
        var readmeCount = 0

        let unsupportedExtensions = Set(["psd", "afdesign", "zip", "7z", "rar", "gif", "ase", "aseprite"])
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return GraphicsSourceAssetInventory(rootRelativePath: relativeRoot)
        }

        for case let item as URL in enumerator {
            let relativePath = relativePath(from: item, root: root)
            if relativePath.contains(" ") {
                pathsWithSpacesCount += 1
            }

            let values = try? item.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
            if values?.isDirectory == true {
                if item.lastPathComponent == "anim" {
                    animationDirectoryCount += 1
                }
                continue
            }

            guard values?.isRegularFile == true else { continue }
            let filename = item.lastPathComponent.lowercased()
            let ext = item.pathExtension.lowercased()
            if filename == "readme.md" || filename == "readme.txt" || filename == "credits.md" || filename == "credits.txt" {
                readmeCount += 1
            }
            if filename.hasSuffix("tiles.png") || ext == "png" {
                tileImageCount += 1
            } else if ext == "pal" || ext == "gbapal" {
                paletteFileCount += 1
            } else if filename == "metatiles.bin" {
                metatileBinaryCount += 1
            } else if filename == "metatile_attributes.bin" {
                attributeBinaryCount += 1
            } else if unsupportedExtensions.contains(ext) {
                unsupportedSourceArtifactCount += 1
            }
        }

        return GraphicsSourceAssetInventory(
            rootRelativePath: relativeRoot,
            tileImageCount: tileImageCount,
            paletteFileCount: paletteFileCount,
            metatileBinaryCount: metatileBinaryCount,
            attributeBinaryCount: attributeBinaryCount,
            animationDirectoryCount: animationDirectoryCount,
            unsupportedSourceArtifactCount: unsupportedSourceArtifactCount,
            pathsWithSpacesCount: pathsWithSpacesCount,
            readmeCount: readmeCount
        )
    }

    private static func missingDiagnostic(_ code: String, _ message: String, _ path: String) -> Diagnostic {
        Diagnostic(
            severity: .warning,
            code: code,
            message: message,
            span: SourceSpan(relativePath: path, startLine: 1)
        )
    }

    private static func generatedArtifactDiagnostics(for artifact: GraphicsArtifactStatus, owner: String) -> [Diagnostic] {
        guard let generatedPath = artifact.generatedRelativePath else { return [] }
        switch artifact.freshness {
        case .generatedMissing:
            return [
                Diagnostic(
                    severity: .info,
                    code: "GRAPHICS_GENERATED_ARTIFACT_MISSING",
                    message: "\(owner) source artifact \(artifact.relativePath) does not have generated output \(generatedPath). Build or conversion tools may need to regenerate it.",
                    span: SourceSpan(relativePath: artifact.relativePath, startLine: 1)
                )
            ]
        case .generatedStale:
            return [
                Diagnostic(
                    severity: .warning,
                    code: "GRAPHICS_GENERATED_ARTIFACT_STALE",
                    message: "\(owner) generated artifact \(generatedPath) is older than source \(artifact.relativePath).",
                    span: SourceSpan(relativePath: generatedPath, startLine: 1)
                )
            ]
        default:
            return []
        }
    }

    private static func sha1Hex(_ data: Data) -> String {
        Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func readUInt16LE(_ data: Data, offset: Int) -> UInt16 {
        guard offset + 1 < data.count else { return 0 }
        return UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }

    private static func readUInt32LE(_ data: Data, offset: Int) -> UInt32 {
        guard offset + 3 < data.count else { return 0 }
        return UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }

    private static func readUInt32BE(_ data: Data, offset: Int) -> UInt32 {
        guard offset + 3 < data.count else { return 0 }
        return (UInt32(data[offset]) << 24)
            | (UInt32(data[offset + 1]) << 16)
            | (UInt32(data[offset + 2]) << 8)
            | UInt32(data[offset + 3])
    }

    private static func relativePath(from url: URL, root: URL) -> String {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        if path == rootPath { return "" }
        if path.hasPrefix(rootPath + "/") {
            return String(path.dropFirst(rootPath.count + 1))
        }
        return path
    }
}
