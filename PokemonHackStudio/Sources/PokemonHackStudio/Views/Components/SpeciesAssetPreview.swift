import SwiftUI
import AppKit
import PokemonHackCore

struct SpeciesAssetPreview: View {
    let asset: PokemonHackCore.SpeciesAsset?
    let rootPath: String?
    let draftData: Data?
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.quaternary, lineWidth: 1)
                )

            if let image {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: size, height: size)
    }

    private var image: NSImage? {
        if let draftData {
            return NSImage(data: draftData)
        }
        guard
            let asset,
            asset.exists,
            asset.relativePath.hasSuffix(".png"),
            let rootPath
        else {
            return nil
        }
        let path = URL(fileURLWithPath: rootPath).appendingPathComponent(asset.relativePath).standardizedFileURL.path
        return PokemonSpeciesImageCache.image(at: path)
    }
}

@MainActor
enum PokemonSpeciesImageCache {
    private static var cache: [String: NSImage] = [:]

    static func image(at path: String) -> NSImage? {
        if let cached = cache[path] {
            return cached
        }
        guard let image = NSImage(contentsOfFile: path) else {
            return nil
        }
        cache[path] = image
        return image
    }
}
