import AppKit
import PokemonHackCore
import SwiftUI

struct MetatilePaletteView: View {
    let document: MapVisualDocument
    let selectedRawValue: UInt16?
    @Binding var filterText: String
    let maxVisibleMetatiles: Int
    let onSelectMetatile: (UInt16) -> Void

    @State private var renderer: MetatileSwatchRenderer

    init(
        document: MapVisualDocument,
        selectedRawValue: UInt16?,
        filterText: Binding<String>,
        maxVisibleMetatiles: Int = 160,
        onSelectMetatile: @escaping (UInt16) -> Void
    ) {
        self.document = document
        self.selectedRawValue = selectedRawValue
        _filterText = filterText
        self.maxVisibleMetatiles = maxVisibleMetatiles
        self.onSelectMetatile = onSelectMetatile
        _renderer = State(initialValue: MetatileSwatchRenderer(document: document))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(paletteGroups) { group in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(group.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            LazyHGrid(rows: rows, spacing: 6) {
                                ForEach(group.visibleMetatiles) { metatile in
                                    Button {
                                        onSelectMetatile(UInt16(metatile.id & 0x03ff))
                                    } label: {
                                        MetatileSwatchView(
                                            metatileID: metatile.id,
                                            image: renderer.image(for: metatile),
                                            fallbackColor: MetatileSwatchRenderer.fallbackColor(for: metatile.id),
                                            isSelected: selectedMetatileID == (metatile.id & 0x03ff)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .help("\(metatile.tilesetSymbol) \(String(format: "%03X", metatile.id))")
                                    .accessibilityLabel("Metatile \(String(format: "%03X", metatile.id))")
                                    .accessibilityValue(selectedMetatileID == (metatile.id & 0x03ff) ? "Selected" : "Not selected")
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 6)
            }
        }
        .padding(12)
        .frame(maxHeight: 124)
        .background(.regularMaterial)
        .onChange(of: document.id) { _, _ in
            renderer.update(document: document)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("Metatiles")
                .font(.headline)
            Text(brushLabel)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
            TextField("Filter", text: $filterText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 160)
            Spacer()
            Text("\(visibleMetatiles.count) shown of \(filteredMetatiles.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var rows: [GridItem] {
        [
            GridItem(.fixed(40), spacing: 6),
            GridItem(.fixed(40), spacing: 6)
        ]
    }

    private var selectedMetatileID: Int? {
        selectedRawValue.map { Int($0 & 0x03ff) }
    }

    private var visibleMetatiles: [MetatileDefinition] {
        Array(filteredMetatiles.prefix(maxVisibleMetatiles))
    }

    private var paletteGroups: [MetatilePaletteGroup] {
        let orderedSymbols = [
            document.primaryTileset?.symbol,
            document.secondaryTileset?.symbol
        ].compactMap { $0 }
        var seen = Set(orderedSymbols)
        let extraSymbols = filteredMetatiles.map(\.tilesetSymbol).filter { seen.insert($0).inserted }
        return (orderedSymbols + extraSymbols).compactMap { symbol in
            let metatiles = filteredMetatiles.filter { $0.tilesetSymbol == symbol }
            guard !metatiles.isEmpty else { return nil }
            let title: String
            if symbol == document.primaryTileset?.symbol {
                title = "Primary"
            } else if symbol == document.secondaryTileset?.symbol {
                title = "Secondary"
            } else {
                title = symbol
            }
            return MetatilePaletteGroup(
                id: symbol,
                title: title,
                visibleMetatiles: Array(metatiles.prefix(maxVisibleMetatiles))
            )
        }
    }

    private var filteredMetatiles: [MetatileDefinition] {
        let query = filterText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return document.metatiles }
        return document.metatiles.filter { metatile in
            String(format: "%03X", metatile.id).localizedCaseInsensitiveContains(query)
                || "\(metatile.id)".contains(query)
                || metatile.tilesetSymbol.localizedCaseInsensitiveContains(query)
        }
    }

    private var brushLabel: String {
        guard let selectedRawValue else { return "No brush" }
        return "Brush \(String(format: "%03X", Int(selectedRawValue & 0x03ff)))"
    }
}

private struct MetatilePaletteGroup: Identifiable {
    let id: String
    let title: String
    let visibleMetatiles: [MetatileDefinition]
}

struct MetatileSwatchView: View {
    let metatileID: Int
    let image: NSImage?
    let fallbackColor: NSColor
    let isSelected: Bool

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
            } else {
                Rectangle()
                    .fill(Color(nsColor: fallbackColor))
                Text(String(format: "%03X", metatileID))
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .padding(.horizontal, 2)
            }

            RoundedRectangle(cornerRadius: 5)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.35), lineWidth: isSelected ? 3 : 1)
        }
        .frame(width: 40, height: 40)
        .background(isSelected ? Color.accentColor.opacity(0.14) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}
