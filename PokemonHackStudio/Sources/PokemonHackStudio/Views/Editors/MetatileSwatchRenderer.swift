import AppKit
import Foundation
import PokemonHackCore

final class MetatileSwatchRenderer {
    private struct TileEntrySource {
        let asset: TilesetAsset
        let tileImage: IndexedTilesetImage
        let tileIndex: Int
    }

    private var document: MapVisualDocument
    private var definitionsByID: [Int: MetatileDefinition]
    private var images: [Int: NSImage] = [:]
    private var styledImages: [String: NSImage] = [:]
    private var indexedTileImages: [String: IndexedTilesetImage] = [:]
    private var paletteSets: [String: [[PaletteColor]]] = [:]

    init(document: MapVisualDocument) {
        self.document = document
        definitionsByID = Self.definitionsByID(for: document)
    }

    init(
        document: MapVisualDocument,
        indexedTileImages: [String: IndexedTilesetImage],
        paletteSets: [String: [[PaletteColor]]]
    ) {
        self.document = document
        definitionsByID = Self.definitionsByID(for: document)
        self.indexedTileImages = indexedTileImages
        self.paletteSets = paletteSets
    }

    func update(document: MapVisualDocument) {
        guard self.document.id != document.id else { return }
        self.document = document
        definitionsByID = Self.definitionsByID(for: document)
        images = [:]
        styledImages = [:]
        indexedTileImages = [:]
        paletteSets = [:]
    }

    func image(for metatileID: Int) -> NSImage? {
        image(for: metatileID, layers: Set(MetatileRenderLayer.allCases), opacities: [:])
    }

    func image(
        for metatileID: Int,
        layers: Set<MetatileRenderLayer>,
        opacities: [MetatileRenderLayer: Double]
    ) -> NSImage? {
        if let image = images[metatileID] {
            if layers == Set(MetatileRenderLayer.allCases), opacities.isEmpty {
                return image
            }
        }
        let cacheKey = self.cacheKey(for: metatileID, layers: layers, opacities: opacities)
        if let image = styledImages[cacheKey] {
            return image
        }
        guard let definition = definitionsByID[metatileID] else {
            return nil
        }
        return image(for: definition, layers: layers, opacities: opacities)
    }

    func image(for definition: MetatileDefinition) -> NSImage? {
        image(for: definition, layers: Set(MetatileRenderLayer.allCases), opacities: [:])
    }

    func image(
        for definition: MetatileDefinition,
        layers: Set<MetatileRenderLayer>,
        opacities: [MetatileRenderLayer: Double]
    ) -> NSImage? {
        let cacheKey = self.cacheKey(for: definition.id, layers: layers, opacities: opacities)
        if layers == Set(MetatileRenderLayer.allCases), opacities.isEmpty, let image = images[definition.id] {
            return image
        }
        if let image = styledImages[cacheKey] {
            return image
        }
        guard asset(symbol: definition.tilesetSymbol) != nil else {
            return nil
        }

        let image = render(definition: definition, layers: layers, opacities: opacities)
        if layers == Set(MetatileRenderLayer.allCases), opacities.isEmpty {
            images[definition.id] = image
        } else {
            styledImages[cacheKey] = image
        }
        return image
    }

    static func fallbackColor(for metatileID: Int) -> NSColor {
        let hue = CGFloat((metatileID * 37) % 360) / 360
        return NSColor(calibratedHue: hue, saturation: 0.38, brightness: 0.76, alpha: 1)
    }

    private static func definitionsByID(for document: MapVisualDocument) -> [Int: MetatileDefinition] {
        Dictionary(document.metatiles.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private func render(
        definition: MetatileDefinition,
        layers: Set<MetatileRenderLayer>,
        opacities: [MetatileRenderLayer: Double]
    ) -> NSImage {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 16,
            pixelsHigh: 16,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 16 * 4,
            bitsPerPixel: 32
        )!
        guard let bitmapData = rep.bitmapData else {
            return NSImage(size: NSSize(width: 16, height: 16))
        }
        bitmapData.initialize(repeating: 0, count: 16 * 16 * 4)

        let layerCells = Dictionary(uniqueKeysWithValues: definition.expandedLayerCells().map { ($0.layer, $0) })
        for layer in MetatileRenderLayer.allCases where layers.contains(layer) {
            guard let cell = layerCells[layer] else { continue }
            let opacity = min(max(opacities[layer] ?? 1, 0), 1)
            guard opacity > 0 else { continue }
            for (entryIndex, entry) in cell.tileEntries.enumerated() {
                guard let entry else { continue }
                draw(entry: entry, entryIndex: entryIndex, opacity: opacity, into: bitmapData)
            }
        }

        let image = NSImage(size: NSSize(width: 16, height: 16))
        image.addRepresentation(rep)
        return image
    }

    private func draw(
        entry: MetatileTileEntry,
        entryIndex: Int,
        opacity: Double,
        into bitmapData: UnsafeMutablePointer<UInt8>
    ) {
        guard let source = tileEntrySource(for: entry) else { return }
        let destinationX = entryIndex % 2 == 0 ? 0 : 8
        let destinationY = entryIndex < 2 ? 0 : 8
        let palette = paletteSet(for: source.asset, paletteID: entry.palette)
        for y in 0..<8 {
            for x in 0..<8 {
                guard let paletteIndex = source.tileImage.paletteIndex(
                    tileIndex: source.tileIndex,
                    x: x,
                    y: y,
                    hFlip: entry.hFlip,
                    vFlip: entry.vFlip
                ),
                    paletteIndex > 0
                else {
                    continue
                }
                let color = palette.indices.contains(Int(paletteIndex))
                    ? palette[Int(paletteIndex)]
                    : PaletteColor(red: 255, green: 0, blue: 255)
                blend(
                    color: color,
                    opacity: opacity,
                    x: destinationX + x,
                    y: destinationY + y,
                    into: bitmapData
                )
            }
        }
    }

    private func tileEntrySource(for entry: MetatileTileEntry) -> TileEntrySource? {
        if entry.tileIndex < document.tileLimits.primary {
            guard let asset = document.primaryTileset,
                  let tileImage = indexedTileImage(for: asset)
            else {
                return nil
            }
            return TileEntrySource(asset: asset, tileImage: tileImage, tileIndex: entry.tileIndex)
        }

        guard entry.tileIndex < document.tileLimits.total else {
            return nil
        }
        guard let asset = document.secondaryTileset,
              let tileImage = indexedTileImage(for: asset)
        else {
            return nil
        }
        return TileEntrySource(
            asset: asset,
            tileImage: tileImage,
            tileIndex: entry.tileIndex - document.tileLimits.primary
        )
    }

    private func blend(color: PaletteColor, opacity: Double, x: Int, y: Int, into bitmapData: UnsafeMutablePointer<UInt8>) {
        let offset = (y * 16 + x) * 4
        let sourceAlpha = Double(color.alpha) / 255 * opacity
        guard sourceAlpha > 0 else { return }
        let destinationAlpha = Double(bitmapData[offset + 3]) / 255
        let outputAlpha = sourceAlpha + destinationAlpha * (1 - sourceAlpha)
        guard outputAlpha > 0 else { return }

        let channels = [color.red, color.green, color.blue]
        for channel in 0..<3 {
            let source = Double(channels[channel])
            let destination = Double(bitmapData[offset + channel])
            let blended = (source * sourceAlpha + destination * destinationAlpha * (1 - sourceAlpha)) / outputAlpha
            bitmapData[offset + channel] = UInt8(min(max(Int(blended.rounded()), 0), 255))
        }
        bitmapData[offset + 3] = UInt8(min(max(Int((outputAlpha * 255).rounded()), 0), 255))
    }

    private func asset(symbol: String) -> TilesetAsset? {
        if document.primaryTileset?.symbol == symbol {
            return document.primaryTileset
        }
        if document.secondaryTileset?.symbol == symbol {
            return document.secondaryTileset
        }
        return nil
    }

    private func indexedTileImage(for asset: TilesetAsset) -> IndexedTilesetImage? {
        guard let path = asset.tileImagePath else { return nil }
        if let image = indexedTileImages[path] {
            return image
        }
        let url = URL(fileURLWithPath: document.rootPath).appendingPathComponent(path)
        guard let image = IndexedPNGParser.parse(url: url) else { return nil }
        indexedTileImages[path] = image
        return image
    }

    private func paletteSet(for asset: TilesetAsset, paletteID: Int) -> [PaletteColor] {
        let palettes = paletteSetsBySymbol(for: asset)
        if palettes.indices.contains(paletteID) {
            return palettes[paletteID]
        }
        return Self.defaultPalette
    }

    private func paletteSetsBySymbol(for asset: TilesetAsset) -> [[PaletteColor]] {
        if let palettes = paletteSets[asset.symbol] {
            return palettes
        }
        let palettes = asset.palettePaths.compactMap { path -> [PaletteColor]? in
            let url = URL(fileURLWithPath: document.rootPath).appendingPathComponent(path)
            guard let data = try? Data(contentsOf: url) else { return nil }
            let parsed = TilePaletteParser.parse(data: data, path: path)
            return parsed.isEmpty ? nil : parsed
        }
        paletteSets[asset.symbol] = palettes
        return palettes
    }

    private static let defaultPalette: [PaletteColor] = [
        PaletteColor(red: 0, green: 0, blue: 0, alpha: 0),
        PaletteColor(red: 255, green: 255, blue: 255),
        PaletteColor(red: 200, green: 200, blue: 200),
        PaletteColor(red: 120, green: 120, blue: 120)
    ]

    private func cacheKey(
        for metatileID: Int,
        layers: Set<MetatileRenderLayer>,
        opacities: [MetatileRenderLayer: Double]
    ) -> String {
        let layerKey = MetatileRenderLayer.allCases
            .filter { layers.contains($0) }
            .map(\.rawValue)
            .joined(separator: "-")
        let opacityKey = MetatileRenderLayer.allCases
            .map { layer in String(format: "%.2f", opacities[layer] ?? 1) }
            .joined(separator: "-")
        return "\(metatileID)|\(layerKey)|\(opacityKey)"
    }
}
