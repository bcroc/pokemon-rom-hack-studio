import Foundation

public enum SourceAssetImportExpectedContent: String, Codable, Equatable, CaseIterable {
    case png
    case sourcePalette
}

public enum SourceAssetImportDetectedKind: String, Codable, Equatable, CaseIterable {
    case png
    case palette
    case unsupported
}

public enum SourceAssetImportValidationStatus: String, Codable, Equatable {
    case ready
    case warning
    case blocked
}

public struct SourceAssetImportProvenance: Codable, Equatable {
    public let sourcePath: String
    public let sourceFileName: String
    public let byteCount: Int
    public let sha1: String
    public let expectedContent: SourceAssetImportExpectedContent
    public let detectedKind: SourceAssetImportDetectedKind
    public let targetPath: String?
    public let pngMetadata: GraphicsPNGMetadata?
    public let paletteMetadata: GraphicsPaletteMetadata?
    public let status: SourceAssetImportValidationStatus
    public let diagnostics: [Diagnostic]

    public init(
        sourcePath: String,
        sourceFileName: String,
        byteCount: Int,
        sha1: String,
        expectedContent: SourceAssetImportExpectedContent,
        detectedKind: SourceAssetImportDetectedKind,
        targetPath: String? = nil,
        pngMetadata: GraphicsPNGMetadata? = nil,
        paletteMetadata: GraphicsPaletteMetadata? = nil,
        status: SourceAssetImportValidationStatus,
        diagnostics: [Diagnostic]
    ) {
        self.sourcePath = sourcePath
        self.sourceFileName = sourceFileName
        self.byteCount = byteCount
        self.sha1 = sha1
        self.expectedContent = expectedContent
        self.detectedKind = detectedKind
        self.targetPath = targetPath
        self.pngMetadata = pngMetadata
        self.paletteMetadata = paletteMetadata
        self.status = status
        self.diagnostics = diagnostics
    }
}

public enum SourceAssetImportValidator {
    public static func provenance(
        sourcePath: String,
        expectedContent: SourceAssetImportExpectedContent,
        targetPath: String? = nil,
        data: Data
    ) -> SourceAssetImportProvenance {
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let pngMetadata = GraphicsMetadataParser.pngMetadata(from: data)
        let lowercasedSourcePath = sourcePath.lowercased()
        let sourcePaletteMetadata = lowercasedSourcePath.hasSuffix(".pal")
            ? GraphicsMetadataParser.paletteMetadata(from: data, path: sourcePath)
            : nil
        let binaryPaletteMetadata = GraphicsMetadataParser.gbaPaletteMetadata(from: data)
        let paletteMetadata = sourcePaletteMetadata ?? binaryPaletteMetadata
        let detectedKind: SourceAssetImportDetectedKind
        if pngMetadata != nil {
            detectedKind = .png
        } else if paletteMetadata != nil {
            detectedKind = .palette
        } else {
            detectedKind = .unsupported
        }
        let diagnostics = diagnostics(
            sourcePath: sourcePath,
            expectedContent: expectedContent,
            targetPath: targetPath,
            data: data,
            pngMetadata: pngMetadata,
            sourcePaletteMetadata: sourcePaletteMetadata,
            binaryPaletteMetadata: binaryPaletteMetadata,
            detectedKind: detectedKind
        )
        let status: SourceAssetImportValidationStatus
        if diagnostics.contains(where: { $0.severity == .error }) {
            status = .blocked
        } else if diagnostics.contains(where: { $0.severity == .warning }) {
            status = .warning
        } else {
            status = .ready
        }

        return SourceAssetImportProvenance(
            sourcePath: sourceURL.standardizedFileURL.path,
            sourceFileName: sourceURL.lastPathComponent,
            byteCount: data.count,
            sha1: pokemonHackSHA1Hex(data),
            expectedContent: expectedContent,
            detectedKind: detectedKind,
            targetPath: targetPath,
            pngMetadata: pngMetadata,
            paletteMetadata: paletteMetadata,
            status: status,
            diagnostics: diagnostics
        )
    }

    private static func diagnostics(
        sourcePath: String,
        expectedContent: SourceAssetImportExpectedContent,
        targetPath: String?,
        data: Data,
        pngMetadata: GraphicsPNGMetadata?,
        sourcePaletteMetadata: GraphicsPaletteMetadata?,
        binaryPaletteMetadata: GraphicsPaletteMetadata?,
        detectedKind: SourceAssetImportDetectedKind
    ) -> [Diagnostic] {
        let span = SourceSpan(relativePath: targetPath ?? sourcePath, startLine: 1)
        guard !data.isEmpty else {
            return [
                Diagnostic(
                    severity: .error,
                    code: "ASSET_IMPORT_EMPTY",
                    message: "Imported asset data is empty.",
                    span: span
                )
            ]
        }

        switch expectedContent {
        case .png:
            guard detectedKind == .png, let pngMetadata, pngMetadata.width > 0, pngMetadata.height > 0 else {
                return [
                    Diagnostic(
                        severity: .error,
                        code: "ASSET_IMPORT_PNG_INVALID",
                        message: "Sprite imports must be readable PNG source assets.",
                        span: span
                    )
                ]
            }
            var diagnostics: [Diagnostic] = []
            if let paletteColorCount = pngMetadata.paletteColorCount, paletteColorCount > 16 {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "ASSET_IMPORT_PNG_PALETTE_OVER_LIMIT",
                        message: "PNG declares \(paletteColorCount) palette colors; Gen III sprite sources must fit 16 colors.",
                        span: span
                    )
                )
            }
            if pngMetadata.paletteColorCount == nil {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "ASSET_IMPORT_PNG_PALETTE_UNVERIFIED",
                        message: "PNG has no PLTE chunk; palette fit must be reviewed before conversion.",
                        span: span
                    )
                )
            }
            return diagnostics

        case .sourcePalette:
            guard detectedKind == .palette, let palette = sourcePaletteMetadata ?? binaryPaletteMetadata else {
                return [
                    Diagnostic(
                        severity: .error,
                        code: "ASSET_IMPORT_PALETTE_INVALID",
                        message: "Palette imports must be readable JASC .pal source files.",
                        span: span
                    )
                ]
            }
            var diagnostics: [Diagnostic] = []
            if sourcePaletteMetadata == nil, binaryPaletteMetadata != nil {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "ASSET_IMPORT_BINARY_PALETTE_BLOCKED",
                        message: "Binary .gbapal palette bytes cannot replace source .pal files until a conversion workflow is available.",
                        span: span
                    )
                )
            }
            if !palette.hasSlotZero {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "ASSET_IMPORT_PALETTE_SLOT_ZERO_MISSING",
                        message: "Palette imports must include slot 0.",
                        span: span
                    )
                )
            }
            if palette.colorCount > 16 {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "ASSET_IMPORT_PALETTE_OVER_LIMIT",
                        message: "Palette has \(palette.colorCount) colors; Gen III palettes must fit 16 colors.",
                        span: span
                    )
                )
            }
            if palette.colorCount < 16 {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "ASSET_IMPORT_PALETTE_UNDER_LIMIT",
                        message: "Palette has \(palette.colorCount) colors; Gen III palettes normally carry 16 colors.",
                        span: span
                    )
                )
            }
            if palette.gbaPrecisionLossCount > 0 {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "ASSET_IMPORT_PALETTE_PRECISION_LOSS",
                        message: "Palette has \(palette.gbaPrecisionLossCount) color(s) that lose precision in GBA 15-bit color.",
                        span: span
                    )
                )
            }
            return diagnostics
        }
    }
}
