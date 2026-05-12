import AppKit
import PokemonHackCore

@MainActor
enum MapEventSpriteRenderer {
    private static var imageCache: [String: NSImage] = [:]

    static func drawEvent(
        _ event: MapEventDescriptor,
        document: MapVisualDocument?,
        tileRect: NSRect,
        tileSize: CGFloat,
        opacity: CGFloat,
        selected: Bool,
        fallbackColor: NSColor,
        badge: String? = nil
    ) {
        if event.kind == .object,
           let sprite = event.sprite,
           let image = image(for: sprite, document: document) {
            drawSprite(sprite, image: image, tileRect: tileRect, tileSize: tileSize, opacity: opacity, selected: selected)
        } else {
            drawMarker(in: tileRect, tileSize: tileSize, opacity: opacity, selected: selected, color: fallbackColor)
        }
        if let badge, !badge.isEmpty, tileSize >= 10 {
            drawBadge(badge, near: tileRect, opacity: opacity)
        }
    }

    static func drawOverviewEvent(
        _ event: MapEventDescriptor,
        in rect: NSRect,
        opacity: CGFloat,
        selected: Bool,
        fallbackColor: NSColor
    ) {
        if event.kind == .object, event.sprite?.imageAssetPath != nil {
            let spriteRect = rect.insetBy(dx: -1.5, dy: -2.5)
            NSColor.black.withAlphaComponent(0.22 * opacity).setFill()
            NSBezierPath(ovalIn: NSRect(x: rect.minX - 1, y: rect.maxY - 2, width: rect.width + 2, height: 3)).fill()
            fallbackColor.withAlphaComponent(0.72 * opacity).setFill()
            NSBezierPath(roundedRect: spriteRect, xRadius: 2, yRadius: 2).fill()
            if selected {
                NSColor.white.withAlphaComponent(opacity).setStroke()
                NSBezierPath(roundedRect: spriteRect.insetBy(dx: -1.5, dy: -1.5), xRadius: 2, yRadius: 2).stroke()
            }
        } else {
            drawMarker(in: rect, tileSize: max(rect.width, rect.height), opacity: opacity, selected: selected, color: fallbackColor)
        }
    }

    private static func drawSprite(
        _ sprite: MapEventSpriteDescriptor,
        image: NSImage,
        tileRect: NSRect,
        tileSize: CGFloat,
        opacity: CGFloat,
        selected: Bool
    ) {
        let destination = spriteDestinationRect(sprite: sprite, tileRect: tileRect, tileSize: tileSize)
        NSColor.black.withAlphaComponent(0.24 * opacity).setFill()
        NSBezierPath(
            ovalIn: NSRect(
                x: tileRect.midX - tileSize * 0.34,
                y: tileRect.maxY - tileSize * 0.22,
                width: tileSize * 0.68,
                height: tileSize * 0.18
            )
        ).fill()

        if let context = NSGraphicsContext.current?.cgContext {
            context.saveGState()
            context.translateBy(x: 0, y: destination.minY + destination.maxY)
            context.scaleBy(x: 1, y: -1)
            image.draw(in: destination, from: sourceRect(sprite: sprite, image: image), operation: .sourceOver, fraction: opacity)
            context.restoreGState()
        } else {
            image.draw(in: destination, from: sourceRect(sprite: sprite, image: image), operation: .sourceOver, fraction: opacity)
        }

        if selected {
            NSColor.white.withAlphaComponent(opacity).setStroke()
            let ring = NSBezierPath(roundedRect: destination.insetBy(dx: -3, dy: -3), xRadius: 4, yRadius: 4)
            ring.lineWidth = 3
            ring.stroke()
        }
    }

    private static func drawMarker(in rect: NSRect, tileSize: CGFloat, opacity: CGFloat, selected: Bool, color: NSColor) {
        color.withAlphaComponent(opacity).setFill()
        let marker = rect.insetBy(dx: tileSize * 0.22, dy: tileSize * 0.22)
        NSBezierPath(ovalIn: marker).fill()

        if selected {
            NSColor.white.withAlphaComponent(opacity).setStroke()
            let ring = NSBezierPath(ovalIn: marker.insetBy(dx: -3, dy: -3))
            ring.lineWidth = 3
            ring.stroke()
        }
    }

    private static func drawBadge(_ label: String, near rect: NSRect, opacity: CGFloat) {
        let fontSize = max(8, min(11, rect.width * 0.28))
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .semibold),
            .foregroundColor: NSColor.white.withAlphaComponent(opacity)
        ]
        let size = label.size(withAttributes: attributes)
        let badge = NSRect(
            x: rect.midX - size.width / 2 - 4,
            y: max(rect.minY - size.height * 0.35, rect.minY + 1),
            width: size.width + 8,
            height: size.height + 4
        )
        NSColor.black.withAlphaComponent(0.58 * opacity).setFill()
        NSBezierPath(roundedRect: badge, xRadius: 4, yRadius: 4).fill()
        label.draw(at: NSPoint(x: badge.minX + 4, y: badge.minY + 2), withAttributes: attributes)
    }

    private static func spriteDestinationRect(sprite: MapEventSpriteDescriptor, tileRect: NSRect, tileSize: CGFloat) -> NSRect {
        let pixelWidth = CGFloat(sprite.frameWidth ?? sprite.width ?? 16)
        let pixelHeight = CGFloat(sprite.frameHeight ?? sprite.height ?? 16)
        let width = max(tileSize * 0.55, pixelWidth / 16 * tileSize)
        let height = max(tileSize * 0.55, pixelHeight / 16 * tileSize)
        return NSRect(
            x: tileRect.midX - width / 2,
            y: tileRect.maxY - height,
            width: width,
            height: height
        )
    }

    private static func sourceRect(sprite: MapEventSpriteDescriptor, image: NSImage) -> NSRect {
        let width = min(CGFloat(sprite.frameWidth ?? sprite.width ?? Int(image.size.width)), image.size.width)
        let height = min(CGFloat(sprite.frameHeight ?? sprite.height ?? Int(image.size.height)), image.size.height)
        return NSRect(x: 0, y: max(image.size.height - height, 0), width: width, height: height)
    }

    private static func image(for sprite: MapEventSpriteDescriptor, document: MapVisualDocument?) -> NSImage? {
        guard let path = sprite.imageAssetPath, path.hasSuffix(".png"), let document else {
            return nil
        }
        let absolutePath = URL(fileURLWithPath: document.rootPath).appendingPathComponent(path).standardizedFileURL.path
        if let cached = imageCache[absolutePath] {
            return cached
        }
        guard let image = NSImage(contentsOfFile: absolutePath), image.isValid else {
            return nil
        }
        imageCache[absolutePath] = image
        return image
    }
}
