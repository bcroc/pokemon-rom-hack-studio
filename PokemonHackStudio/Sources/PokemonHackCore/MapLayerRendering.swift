import Foundation

public enum GameBackgroundLayer: String, Codable, Equatable, CaseIterable, Identifiable, Hashable, Sendable {
    case bottom
    case middle
    case top

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .bottom:
            return "Bottom"
        case .middle:
            return "Middle"
        case .top:
            return "Top"
        }
    }
}

public struct MetatileLayerCell: Codable, Equatable, Identifiable {
    public var id: String { layer.rawValue }

    public let layer: GameBackgroundLayer
    public let tileEntries: [MetatileTileEntry?]

    public var isEmpty: Bool {
        tileEntries.allSatisfy { $0 == nil }
    }

    public init(layer: GameBackgroundLayer, tileEntries: [MetatileTileEntry?]) {
        self.layer = layer
        self.tileEntries = Array(tileEntries.prefix(4)) + Array(repeating: nil, count: max(0, 4 - tileEntries.count))
    }
}

public struct MapBlockAttributes: Codable, Equatable, Sendable {
    public let rawValue: UInt16
    public let metatileID: Int
    public let collision: Int
    public let elevation: Int

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
        metatileID = Int(rawValue & 0x03ff)
        collision = Int((rawValue >> 10) & 0x0003)
        elevation = Int((rawValue >> 12) & 0x000f)
    }
}

public struct PaletteColor: Codable, Equatable, Sendable {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8
    public let alpha: UInt8

    public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8 = 255) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

public enum TilePaletteParser {
    public static func parse(data: Data, path: String? = nil) -> [PaletteColor] {
        if let text = String(data: data, encoding: .utf8),
           text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("JASC-PAL") {
            return parseJASCPalette(text)
        }
        return parseGBAPalette(data)
    }

    private static func parseJASCPalette(_ text: String) -> [PaletteColor] {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard lines.count >= 3, lines[0] == "JASC-PAL" else { return [] }
        let expectedCount = Int(lines[2]) ?? max(lines.count - 3, 0)
        return lines.dropFirst(3).prefix(expectedCount).compactMap { line in
            let parts = line.split(separator: " ").compactMap { UInt8($0) }
            guard parts.count >= 3 else { return nil }
            return PaletteColor(red: parts[0], green: parts[1], blue: parts[2])
        }
    }

    private static func parseGBAPalette(_ data: Data) -> [PaletteColor] {
        let bytes = [UInt8](data)
        return stride(from: 0, to: bytes.count - (bytes.count % 2), by: 2).map { offset in
            let raw = UInt16(bytes[offset]) | (UInt16(bytes[offset + 1]) << 8)
            return PaletteColor(
                red: expandFiveBitColor(UInt8(raw & 0x001f)),
                green: expandFiveBitColor(UInt8((raw >> 5) & 0x001f)),
                blue: expandFiveBitColor(UInt8((raw >> 10) & 0x001f))
            )
        }
    }

    private static func expandFiveBitColor(_ value: UInt8) -> UInt8 {
        (value << 3) | (value >> 2)
    }
}

public extension MetatileDefinition {
    func expandedLayerCells() -> [MetatileLayerCell] {
        if tileEntries.count >= 12 {
            return GameBackgroundLayer.allCases.enumerated().map { layerIndex, layer in
                let start = layerIndex * 4
                let entries = Array(tileEntries[start..<(start + 4)]).map(Optional.some)
                return MetatileLayerCell(layer: layer, tileEntries: entries)
            }
        }

        let firstHalf = Array(tileEntries.prefix(4)).map(Optional.some)
        let secondHalf = Array(tileEntries.dropFirst(4).prefix(4)).map(Optional.some)
        let empty = Array<MetatileTileEntry?>(repeating: nil, count: 4)

        switch attribute?.layerType ?? .normal {
        case .normal:
            return [
                MetatileLayerCell(layer: .bottom, tileEntries: empty),
                MetatileLayerCell(layer: .middle, tileEntries: firstHalf),
                MetatileLayerCell(layer: .top, tileEntries: secondHalf)
            ]
        case .covered:
            return [
                MetatileLayerCell(layer: .bottom, tileEntries: firstHalf),
                MetatileLayerCell(layer: .middle, tileEntries: secondHalf),
                MetatileLayerCell(layer: .top, tileEntries: empty)
            ]
        case .split:
            return [
                MetatileLayerCell(layer: .bottom, tileEntries: firstHalf),
                MetatileLayerCell(layer: .middle, tileEntries: empty),
                MetatileLayerCell(layer: .top, tileEntries: secondHalf)
            ]
        }
    }

    func layerCell(for layer: GameBackgroundLayer) -> MetatileLayerCell {
        expandedLayerCells().first { $0.layer == layer } ?? MetatileLayerCell(
            layer: layer,
            tileEntries: Array(repeating: nil, count: 4)
        )
    }
}
