import CryptoKit
import Foundation

public enum GraphicsImportSourceKind: String, Codable, Equatable, CaseIterable {
    case tileImage
    case palette
    case layeredTileImage
    case attributes
    case animation
    case creditMetadata
    case designSource
    case unsupported
}

public enum GraphicsImportReadiness: String, Codable, Equatable {
    case ready
    case blocked
}

public struct GraphicsImportSourceFile: Codable, Equatable, Identifiable {
    public var id: String { relativePath }

    public let relativePath: String
    public let kind: GraphicsImportSourceKind
    public let sizeBytes: UInt64
    public let sha1: String
    public let png: GraphicsPNGMetadata?
    public let palette: GraphicsPaletteMetadata?

    public init(
        relativePath: String,
        kind: GraphicsImportSourceKind,
        sizeBytes: UInt64,
        sha1: String,
        png: GraphicsPNGMetadata? = nil,
        palette: GraphicsPaletteMetadata? = nil
    ) {
        self.relativePath = relativePath
        self.kind = kind
        self.sizeBytes = sizeBytes
        self.sha1 = sha1
        self.png = png
        self.palette = palette
    }
}

public struct GraphicsImportCopyPlan: Codable, Equatable, Identifiable {
    public var id: String { "\(sourceRelativePath)->\(destinationRelativePath)" }

    public let sourceRelativePath: String
    public let destinationRelativePath: String
    public let willOverwriteExistingSource: Bool

    public init(sourceRelativePath: String, destinationRelativePath: String, willOverwriteExistingSource: Bool) {
        self.sourceRelativePath = sourceRelativePath
        self.destinationRelativePath = destinationRelativePath
        self.willOverwriteExistingSource = willOverwriteExistingSource
    }
}

public struct GraphicsLayeredTilesetDryRun: Codable, Equatable {
    public let detectedLayerPaths: [String]
    public let missingLayerNames: [String]
    public let attributesPath: String?
    public let animationFileCount: Int
    public let expectedGeneratedOutputs: [String]
    public let externalToolPlan: String

    public init(
        detectedLayerPaths: [String],
        missingLayerNames: [String],
        attributesPath: String?,
        animationFileCount: Int,
        expectedGeneratedOutputs: [String],
        externalToolPlan: String
    ) {
        self.detectedLayerPaths = detectedLayerPaths
        self.missingLayerNames = missingLayerNames
        self.attributesPath = attributesPath
        self.animationFileCount = animationFileCount
        self.expectedGeneratedOutputs = expectedGeneratedOutputs
        self.externalToolPlan = externalToolPlan
    }
}

public struct GraphicsPaletteFitPreview: Codable, Equatable, Identifiable {
    public var id: String { sourceRelativePath }

    public let sourceRelativePath: String
    public let colorSummary: String
    public let transparencySummary: String
    public let precisionSummary: String
    public let nearestPaletteSummary: String
    public let isReadyFor4bpp: Bool
    public let diagnostics: [Diagnostic]

    public init(
        sourceRelativePath: String,
        colorSummary: String,
        transparencySummary: String,
        precisionSummary: String,
        nearestPaletteSummary: String,
        isReadyFor4bpp: Bool,
        diagnostics: [Diagnostic] = []
    ) {
        self.sourceRelativePath = sourceRelativePath
        self.colorSummary = colorSummary
        self.transparencySummary = transparencySummary
        self.precisionSummary = precisionSummary
        self.nearestPaletteSummary = nearestPaletteSummary
        self.isReadyFor4bpp = isReadyFor4bpp
        self.diagnostics = diagnostics
    }
}

public struct GraphicsImportPackagePlan: Codable, Equatable {
    public let projectRoot: SourceLocation
    public let packageRoot: SourceLocation
    public let packageTitle: String
    public let readiness: GraphicsImportReadiness
    public let isPreviewOnly: Bool
    public let sourceFiles: [GraphicsImportSourceFile]
    public let copyPlan: [GraphicsImportCopyPlan]
    public let creditMetadataPaths: [String]
    public let layeredTilesetDryRun: GraphicsLayeredTilesetDryRun
    public let paletteFitPreviews: [GraphicsPaletteFitPreview]
    public let diagnostics: [Diagnostic]

    public init(
        projectRoot: SourceLocation,
        packageRoot: SourceLocation,
        packageTitle: String,
        readiness: GraphicsImportReadiness,
        isPreviewOnly: Bool = true,
        sourceFiles: [GraphicsImportSourceFile],
        copyPlan: [GraphicsImportCopyPlan],
        creditMetadataPaths: [String],
        layeredTilesetDryRun: GraphicsLayeredTilesetDryRun,
        paletteFitPreviews: [GraphicsPaletteFitPreview],
        diagnostics: [Diagnostic]
    ) {
        self.projectRoot = projectRoot
        self.packageRoot = packageRoot
        self.packageTitle = packageTitle
        self.readiness = readiness
        self.isPreviewOnly = isPreviewOnly
        self.sourceFiles = sourceFiles
        self.copyPlan = copyPlan
        self.creditMetadataPaths = creditMetadataPaths
        self.layeredTilesetDryRun = layeredTilesetDryRun
        self.paletteFitPreviews = paletteFitPreviews
        self.diagnostics = diagnostics
    }
}

public enum GraphicsImportPackagePlanBuilder {
    public static func build(
        projectPath: String,
        packagePath: String,
        fileManager: FileManager = .default
    ) throws -> GraphicsImportPackagePlan {
        let index = try GameAdapterRegistry.index(path: projectPath, fileManager: fileManager)
        let projectRoot = URL(fileURLWithPath: index.root.path).standardizedFileURL
        let packageRoot = URL(fileURLWithPath: packagePath).standardizedFileURL
        let packageTitle = packageRoot.lastPathComponent.isEmpty ? "graphics-import" : packageRoot.lastPathComponent
        var diagnostics: [Diagnostic] = []
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: packageRoot.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "GRAPHICS_IMPORT_PACKAGE_MISSING",
                    message: "Graphics import package does not exist or is not a directory.",
                    span: SourceSpan(relativePath: packagePath, startLine: 1)
                )
            )
            return GraphicsImportPackagePlan(
                projectRoot: index.root,
                packageRoot: SourceLocation(path: packageRoot.path, exists: false),
                packageTitle: packageTitle,
                readiness: .blocked,
                sourceFiles: [],
                copyPlan: [],
                creditMetadataPaths: [],
                layeredTilesetDryRun: emptyLayeredDryRun(),
                paletteFitPreviews: [],
                diagnostics: diagnostics
            )
        }

        let sourceFiles = scanPackage(root: packageRoot, fileManager: fileManager)
        let creditPaths = sourceFiles
            .filter { $0.kind == .creditMetadata }
            .map(\.relativePath)
            .sorted()
        let importRoot = "data/tilesets/imports/\(slug(packageTitle))"
        let copyPlan = sourceFiles
            .filter { shouldCopy($0.kind) }
            .map { file in
                let destination = importRoot + "/" + file.relativePath
                return GraphicsImportCopyPlan(
                    sourceRelativePath: file.relativePath,
                    destinationRelativePath: destination,
                    willOverwriteExistingSource: fileManager.fileExists(atPath: projectRoot.appendingPathComponent(destination).path)
                )
            }
            .sorted { $0.destinationRelativePath < $1.destinationRelativePath }
        let layeredDryRun = layeredTilesetDryRun(files: sourceFiles, importRoot: importRoot)
        let palettePreviews = paletteFitPreviews(files: sourceFiles)
        let graphicsFileCount = sourceFiles.filter {
            [.tileImage, .palette, .layeredTileImage].contains($0.kind)
        }.count

        if creditPaths.isEmpty {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "GRAPHICS_IMPORT_PROVENANCE_MISSING",
                    message: "Import packages must include README or credits metadata before they can be marked ready.",
                    span: SourceSpan(relativePath: packageRoot.path, startLine: 1)
                )
            )
        }
        if graphicsFileCount == 0 {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "GRAPHICS_IMPORT_NO_GRAPHICS",
                    message: "No PNG or palette source files were found in the selected import package.",
                    span: SourceSpan(relativePath: packageRoot.path, startLine: 1)
                )
            )
        }
        if !sourceFiles.contains(where: { $0.kind == .attributes }) {
            diagnostics.append(
                Diagnostic(
                    severity: .info,
                    code: "GRAPHICS_IMPORT_ATTRIBUTES_NOT_FOUND",
                    message: "No attributes CSV was found; metatile behavior and layer metadata would need manual review.",
                    span: SourceSpan(relativePath: packageRoot.path, startLine: 1)
                )
            )
        }
        if copyPlan.contains(where: \.willOverwriteExistingSource) {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "GRAPHICS_IMPORT_DESTINATION_EXISTS",
                    message: "One or more planned copied source paths already exist in the project import area.",
                    span: SourceSpan(relativePath: importRoot, startLine: 1)
                )
            )
        }

        diagnostics.append(contentsOf: palettePreviews.flatMap(\.diagnostics))
        let readiness: GraphicsImportReadiness = diagnostics.contains { $0.severity == .error } ? .blocked : .ready
        return GraphicsImportPackagePlan(
            projectRoot: index.root,
            packageRoot: SourceLocation(path: packageRoot.path, exists: true),
            packageTitle: packageTitle,
            readiness: readiness,
            sourceFiles: sourceFiles,
            copyPlan: copyPlan,
            creditMetadataPaths: creditPaths,
            layeredTilesetDryRun: layeredDryRun,
            paletteFitPreviews: palettePreviews,
            diagnostics: diagnostics
        )
    }

    private static func scanPackage(root: URL, fileManager: FileManager) -> [GraphicsImportSourceFile] {
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        var files: [GraphicsImportSourceFile] = []
        for case let url as URL in enumerator {
            guard (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true,
                  let data = try? Data(contentsOf: url)
            else { continue }
            let relativePath = relativePath(from: url, root: root)
            let kind = kind(for: relativePath)
            files.append(
                GraphicsImportSourceFile(
                    relativePath: relativePath,
                    kind: kind,
                    sizeBytes: UInt64(data.count),
                    sha1: sha1Hex(data),
                    png: relativePath.lowercased().hasSuffix(".png") ? pngMetadata(from: data) : nil,
                    palette: paletteMetadata(from: data, path: relativePath)
                )
            )
        }
        return files.sorted { $0.relativePath < $1.relativePath }
    }

    private static func kind(for relativePath: String) -> GraphicsImportSourceKind {
        let lowercased = relativePath.lowercased()
        let fileName = URL(fileURLWithPath: lowercased).lastPathComponent
        if ["readme.md", "readme.txt", "credits.md", "credits.txt"].contains(fileName) {
            return .creditMetadata
        }
        if lowercased.hasSuffix(".png") {
            let stem = URL(fileURLWithPath: lowercased).deletingPathExtension().lastPathComponent
            return ["top", "middle", "bottom", "layer_top", "layer_middle", "layer_bottom"].contains(stem)
                ? .layeredTileImage
                : .tileImage
        }
        if lowercased.hasSuffix(".pal") || lowercased.hasSuffix(".gbapal") {
            return .palette
        }
        if fileName == "attributes.csv" || fileName == "metatile_attributes.csv" {
            return .attributes
        }
        if lowercased.contains("/anim/") || lowercased.hasPrefix("anim/") {
            return .animation
        }
        if ["psd", "afdesign", "ase", "aseprite"].contains(URL(fileURLWithPath: lowercased).pathExtension) {
            return .designSource
        }
        return .unsupported
    }

    private static func shouldCopy(_ kind: GraphicsImportSourceKind) -> Bool {
        switch kind {
        case .tileImage, .palette, .layeredTileImage, .attributes, .animation, .creditMetadata, .designSource:
            return true
        case .unsupported:
            return false
        }
    }

    private static func layeredTilesetDryRun(files: [GraphicsImportSourceFile], importRoot: String) -> GraphicsLayeredTilesetDryRun {
        let layerNames = ["top", "middle", "bottom"]
        let detected = files
            .filter { $0.kind == .layeredTileImage }
            .map(\.relativePath)
            .sorted()
        let detectedNames = Set(detected.map {
            URL(fileURLWithPath: $0).deletingPathExtension().lastPathComponent
                .lowercased()
                .replacingOccurrences(of: "layer_", with: "")
        })
        let missing = layerNames.filter { !detectedNames.contains($0) }
        let attributes = files.first { $0.kind == .attributes }?.relativePath
        let animationCount = files.filter { $0.kind == .animation }.count
        let outputs = [
            "\(importRoot)/tiles.4bpp.lz",
            "\(importRoot)/metatiles.bin",
            "\(importRoot)/metatile_attributes.bin",
            "\(importRoot)/palettes/*.gbapal"
        ]
        return GraphicsLayeredTilesetDryRun(
            detectedLayerPaths: detected,
            missingLayerNames: missing,
            attributesPath: attributes,
            animationFileCount: animationCount,
            expectedGeneratedOutputs: outputs,
            externalToolPlan: "Preview only: validate layered PNGs, attributes, animation sources, and provenance before invoking any user-installed conversion tool."
        )
    }

    private static func paletteFitPreviews(files: [GraphicsImportSourceFile]) -> [GraphicsPaletteFitPreview] {
        let paletteCandidates = files.filter { $0.palette?.colorCount ?? 0 <= 16 && $0.kind == .palette }
        return files.compactMap { file -> GraphicsPaletteFitPreview? in
            if let png = file.png {
                var diagnostics: [Diagnostic] = []
                let colorCount = png.paletteColorCount
                let colorSummary = colorCount.map {
                    "\($0) indexed color(s)"
                } ?? "PNG is not indexed or has no PLTE chunk"
                if let colorCount, colorCount > 16 {
                    diagnostics.append(
                        Diagnostic(
                            severity: .warning,
                            code: "GRAPHICS_IMPORT_PALETTE_TOO_LARGE",
                            message: "\(file.relativePath) declares \(colorCount) indexed colors; reduce to 16 before 4bpp conversion.",
                            span: SourceSpan(relativePath: file.relativePath, startLine: 1)
                        )
                    )
                }
                if !png.hasTransparencyChunk {
                    diagnostics.append(
                        Diagnostic(
                            severity: .info,
                            code: "GRAPHICS_IMPORT_TRANSPARENCY_UNDECLARED",
                            message: "\(file.relativePath) has no PNG transparency chunk; slot 0 should be reviewed before conversion.",
                            span: SourceSpan(relativePath: file.relativePath, startLine: 1)
                        )
                    )
                }
                let nearest = paletteCandidates.isEmpty
                    ? "No package palette candidates under 16 colors."
                    : "\(paletteCandidates.count) package palette candidate(s) fit the 16-color limit."
                let ready = (colorCount ?? 17) <= 16
                return GraphicsPaletteFitPreview(
                    sourceRelativePath: file.relativePath,
                    colorSummary: colorSummary,
                    transparencySummary: png.hasTransparencyChunk ? "Transparency chunk present." : "Transparency slot requires review.",
                    precisionSummary: "PNG channel precision will be reviewed when a palette is selected.",
                    nearestPaletteSummary: nearest,
                    isReadyFor4bpp: ready,
                    diagnostics: diagnostics
                )
            }
            if let palette = file.palette {
                let ready = palette.colorCount <= 16
                let precision = palette.gbaPrecisionLossCount == 0
                    ? "No 15-bit precision loss detected."
                    : "\(palette.gbaPrecisionLossCount) color(s) lose precision in 15-bit GBA color."
                var diagnostics: [Diagnostic] = []
                if !ready {
                    diagnostics.append(
                        Diagnostic(
                            severity: .warning,
                            code: "GRAPHICS_IMPORT_PALETTE_TOO_LARGE",
                            message: "\(file.relativePath) contains \(palette.colorCount) colors; Gen III palettes should fit 16 colors.",
                            span: SourceSpan(relativePath: file.relativePath, startLine: 1)
                        )
                    )
                }
                return GraphicsPaletteFitPreview(
                    sourceRelativePath: file.relativePath,
                    colorSummary: "\(palette.colorCount) palette color(s)",
                    transparencySummary: palette.hasSlotZero ? "Palette slot 0 exists." : "Palette slot 0 is missing.",
                    precisionSummary: precision,
                    nearestPaletteSummary: "Source palette can be used as a package candidate.",
                    isReadyFor4bpp: ready,
                    diagnostics: diagnostics
                )
            }
            return nil
        }
    }

    private static func emptyLayeredDryRun() -> GraphicsLayeredTilesetDryRun {
        GraphicsLayeredTilesetDryRun(
            detectedLayerPaths: [],
            missingLayerNames: ["top", "middle", "bottom"],
            attributesPath: nil,
            animationFileCount: 0,
            expectedGeneratedOutputs: [],
            externalToolPlan: "Preview only."
        )
    }

    private static func relativePath(from url: URL, root: URL) -> String {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        guard path.hasPrefix(rootPath + "/") else { return url.lastPathComponent }
        return String(path.dropFirst(rootPath.count + 1))
    }

    private static func slug(_ value: String) -> String {
        let scalars = value.lowercased().unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : "-"
        }
        let collapsed = String(scalars).split(separator: "-").joined(separator: "-")
        return collapsed.isEmpty ? "graphics-import" : collapsed
    }

    private static func sha1Hex(_ data: Data) -> String {
        Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func paletteMetadata(from data: Data, path: String) -> GraphicsPaletteMetadata? {
        let lowercased = path.lowercased()
        if lowercased.hasSuffix(".gbapal") {
            return GraphicsPaletteMetadata(format: "GBA", colorCount: data.count / 2, hasSlotZero: data.count >= 2)
        }

        guard lowercased.hasSuffix(".pal"), let text = String(data: data, encoding: .utf8) else { return nil }
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard lines.first == "JASC-PAL", lines.count >= 3, let declaredCount = Int(lines[2]) else {
            return nil
        }
        let colorLines = lines.dropFirst(3).prefix(declaredCount)
        let precisionLoss = colorLines.reduce(0) { count, line in
            let channels = line.split(separator: " ").compactMap { Int($0) }
            return count + (channels.count >= 3 && channels.prefix(3).contains(where: { $0 % 8 != 0 }) ? 1 : 0)
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

    private static func readUInt32BE(_ data: Data, offset: Int) -> UInt32 {
        (UInt32(data[offset]) << 24)
            | (UInt32(data[offset + 1]) << 16)
            | (UInt32(data[offset + 2]) << 8)
            | UInt32(data[offset + 3])
    }
}
