import AppKit
import Compression
import Foundation
import PokemonHackCore

struct IndexedTilesetImage: Equatable {
    let width: Int
    let height: Int
    let indices: [UInt8]

    init(width: Int, height: Int, indices: [UInt8]) {
        self.width = width
        self.height = height
        self.indices = indices
    }

    func paletteIndex(tileIndex: Int, x: Int, y: Int, hFlip: Bool, vFlip: Bool) -> UInt8? {
        let columns = max(width / 8, 1)
        let sourceX = (tileIndex % columns) * 8 + (hFlip ? 7 - x : x)
        let sourceY = (tileIndex / columns) * 8 + (vFlip ? 7 - y : y)
        guard sourceX >= 0, sourceY >= 0, sourceX < width, sourceY < height else { return nil }
        let index = sourceY * width + sourceX
        guard indices.indices.contains(index) else { return nil }
        return indices[index]
    }
}

final class MetatileSwatchRenderer {
    private struct TileEntrySource {
        let asset: TilesetAsset
        let tileImage: IndexedTilesetImage
        let tileIndex: Int
    }

    private var document: MapVisualDocument
    private var images: [Int: NSImage] = [:]
    private var styledImages: [String: NSImage] = [:]
    private var indexedTileImages: [String: IndexedTilesetImage] = [:]
    private var paletteSets: [String: [[PaletteColor]]] = [:]

    init(document: MapVisualDocument) {
        self.document = document
    }

    init(
        document: MapVisualDocument,
        indexedTileImages: [String: IndexedTilesetImage],
        paletteSets: [String: [[PaletteColor]]]
    ) {
        self.document = document
        self.indexedTileImages = indexedTileImages
        self.paletteSets = paletteSets
    }

    func update(document: MapVisualDocument) {
        guard self.document.id != document.id else { return }
        self.document = document
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
        guard let definition = document.metatiles.first(where: { $0.id == metatileID }) else {
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

enum IndexedPNGParser {
    static func parse(url: URL) -> IndexedTilesetImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return parse(data: data)
    }

    static func parse(data: Data) -> IndexedTilesetImage? {
        let bytes = [UInt8](data)
        let signature: [UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
        guard bytes.count > signature.count, Array(bytes.prefix(signature.count)) == signature else { return nil }

        var offset = signature.count
        var width = 0
        var height = 0
        var bitDepth = 0
        var colorType = 0
        var idat = Data()

        while offset + 12 <= bytes.count {
            let length = Int(readUInt32(bytes, offset: offset))
            offset += 4
            guard offset + 4 + length + 4 <= bytes.count else { return nil }
            let type = String(bytes: bytes[offset..<(offset + 4)], encoding: .ascii) ?? ""
            offset += 4
            let payload = bytes[offset..<(offset + length)]
            switch type {
            case "IHDR":
                guard payload.count >= 13 else { return nil }
                let payloadBytes = Array(payload)
                width = Int(readUInt32(payloadBytes, offset: 0))
                height = Int(readUInt32(payloadBytes, offset: 4))
                bitDepth = Int(payloadBytes[8])
                colorType = Int(payloadBytes[9])
            case "IDAT":
                idat.append(contentsOf: payload)
            case "IEND":
                offset = bytes.count
            default:
                break
            }
            offset += length + 4
        }

        guard width > 0, height > 0, colorType == 3, [1, 2, 4, 8].contains(bitDepth), !idat.isEmpty else {
            return nil
        }
        let rowByteCount = (width * bitDepth + 7) / 8
        let expectedInflatedSize = height * (rowByteCount + 1)
        guard let inflated = inflate(idat, expectedSize: expectedInflatedSize), inflated.count == expectedInflatedSize else {
            return nil
        }
        let filteredRows = unfilter(inflated, width: width, height: height, rowByteCount: rowByteCount)
        let indices = unpack(filteredRows, width: width, height: height, bitDepth: bitDepth, rowByteCount: rowByteCount)
        return IndexedTilesetImage(width: width, height: height, indices: indices)
    }

    private static func readUInt32(_ bytes: [UInt8], offset: Int) -> UInt32 {
        (UInt32(bytes[offset]) << 24)
            | (UInt32(bytes[offset + 1]) << 16)
            | (UInt32(bytes[offset + 2]) << 8)
            | UInt32(bytes[offset + 3])
    }

    private static func inflate(_ data: Data, expectedSize: Int) -> [UInt8]? {
        guard expectedSize > 0 else { return [] }
        let source = [UInt8](data)
        if source.count == expectedSize {
            return source
        }

        if let compressedPayload = zlibDeflatePayload(from: source),
           let inflated = decodeCompressedBytes(compressedPayload, expectedSize: expectedSize) {
            return inflated
        }

        return decodeCompressedBytes(source, expectedSize: expectedSize)
    }

    private static func zlibDeflatePayload(from source: [UInt8]) -> [UInt8]? {
        guard source.count > 6 else { return nil }
        let compressionMethod = source[0] & 0x0f
        let compressionInfo = source[0] >> 4
        let header = UInt16(source[0]) << 8 | UInt16(source[1])
        guard compressionMethod == 8,
              compressionInfo <= 7,
              header % 31 == 0,
              source[1] & 0x20 == 0
        else {
            return nil
        }
        return Array(source.dropFirst(2).dropLast(4))
    }

    private static func decodeCompressedBytes(_ source: [UInt8], expectedSize: Int) -> [UInt8]? {
        guard !source.isEmpty else { return nil }
        var destination = [UInt8](repeating: 0, count: expectedSize)
        let decoded = destination.withUnsafeMutableBytes { destinationBuffer in
            source.withUnsafeBufferPointer { sourceBuffer in
                compression_decode_buffer(
                    destinationBuffer.bindMemory(to: UInt8.self).baseAddress!,
                    expectedSize,
                    sourceBuffer.baseAddress!,
                    source.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        guard decoded == expectedSize else { return nil }
        return destination
    }

    private static func unfilter(_ bytes: [UInt8], width: Int, height: Int, rowByteCount: Int) -> [UInt8] {
        var output = [UInt8](repeating: 0, count: height * rowByteCount)
        for row in 0..<height {
            let sourceOffset = row * (rowByteCount + 1)
            let filter = bytes[sourceOffset]
            let rowOffset = row * rowByteCount
            let previousRowOffset = (row - 1) * rowByteCount
            for column in 0..<rowByteCount {
                let raw = bytes[sourceOffset + 1 + column]
                let left = column > 0 ? output[rowOffset + column - 1] : 0
                let up = row > 0 ? output[previousRowOffset + column] : 0
                let upperLeft = row > 0 && column > 0 ? output[previousRowOffset + column - 1] : 0
                output[rowOffset + column] = unfilteredByte(filter: filter, raw: raw, left: left, up: up, upperLeft: upperLeft)
            }
        }
        return output
    }

    private static func unfilteredByte(filter: UInt8, raw: UInt8, left: UInt8, up: UInt8, upperLeft: UInt8) -> UInt8 {
        switch filter {
        case 0:
            return raw
        case 1:
            return raw &+ left
        case 2:
            return raw &+ up
        case 3:
            return raw &+ UInt8((UInt16(left) + UInt16(up)) / 2)
        case 4:
            return raw &+ paeth(left: left, up: up, upperLeft: upperLeft)
        default:
            return raw
        }
    }

    private static func paeth(left: UInt8, up: UInt8, upperLeft: UInt8) -> UInt8 {
        let a = Int(left)
        let b = Int(up)
        let c = Int(upperLeft)
        let p = a + b - c
        let pa = abs(p - a)
        let pb = abs(p - b)
        let pc = abs(p - c)
        if pa <= pb && pa <= pc { return left }
        if pb <= pc { return up }
        return upperLeft
    }

    private static func unpack(_ bytes: [UInt8], width: Int, height: Int, bitDepth: Int, rowByteCount: Int) -> [UInt8] {
        var pixels: [UInt8] = []
        pixels.reserveCapacity(width * height)
        for row in 0..<height {
            let rowOffset = row * rowByteCount
            switch bitDepth {
            case 8:
                pixels.append(contentsOf: bytes[rowOffset..<(rowOffset + width)])
            case 4:
                for column in 0..<width {
                    let byte = bytes[rowOffset + column / 2]
                    pixels.append(column % 2 == 0 ? byte >> 4 : byte & 0x0f)
                }
            case 2:
                for column in 0..<width {
                    let byte = bytes[rowOffset + column / 4]
                    let shift = 6 - (column % 4) * 2
                    pixels.append((byte >> UInt8(shift)) & 0x03)
                }
            case 1:
                for column in 0..<width {
                    let byte = bytes[rowOffset + column / 8]
                    let shift = 7 - column % 8
                    pixels.append((byte >> UInt8(shift)) & 0x01)
                }
            default:
                break
            }
        }
        return pixels
    }
}
