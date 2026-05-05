import AppKit
import PokemonHackCore
import SwiftUI

struct MapOverviewView: NSViewRepresentable {
    let document: MapVisualDocument
    let rawValues: [UInt16]
    let borderRawValues: [UInt16]
    let events: [MapEventDescriptor]
    let overlays: MapOverlaySettings
    let viewport: MapCanvasViewport
    let onSelectViewportCenter: (CGFloat, CGFloat) -> Void

    func makeNSView(context: Context) -> MapOverviewNSView {
        let view = MapOverviewNSView()
        view.update(from: self)
        return view
    }

    func updateNSView(_ nsView: MapOverviewNSView, context: Context) {
        nsView.update(from: self)
    }
}

final class MapOverviewNSView: NSView {
    private var document: MapVisualDocument?
    private var rawValues: [UInt16] = []
    private var borderRawValues: [UInt16] = []
    private var events: [MapEventDescriptor] = []
    private var overlays = MapOverlaySettings()
    private var viewport = MapCanvasViewport.zero
    private var renderer: MetatileSwatchRenderer?
    private var onSelectViewportCenter: (CGFloat, CGFloat) -> Void = { _, _ in }

    override var isFlipped: Bool { true }

    override func isAccessibilityElement() -> Bool {
        true
    }

    override func accessibilityRole() -> NSAccessibility.Role? {
        .image
    }

    override func accessibilityLabel() -> String? {
        guard let document else { return "Map overview" }
        return "\(document.mapName) full map overview"
    }

    func update(from overview: MapOverviewView) {
        let needsRenderer = document?.id != overview.document.id
        document = overview.document
        rawValues = overview.rawValues
        borderRawValues = overview.borderRawValues
        events = overview.events
        overlays = overview.overlays
        viewport = overview.viewport
        onSelectViewportCenter = overview.onSelectViewportCenter
        if needsRenderer {
            renderer = MetatileSwatchRenderer(document: overview.document)
        } else {
            renderer?.update(document: overview.document)
        }
        setNeedsDisplay(bounds)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let document else { return }
        NSColor.textBackgroundColor.setFill()
        dirtyRect.fill()

        let mapRect = overviewMapRect(for: document)
        NSColor.windowBackgroundColor.setFill()
        NSBezierPath(roundedRect: mapRect.insetBy(dx: -4, dy: -4), xRadius: 5, yRadius: 5).fill()

        let scene = document.scene.viewport
        let cellWidth = mapRect.width / max(CGFloat(scene.width), 1)
        let cellHeight = mapRect.height / max(CGFloat(scene.height), 1)

        for sceneY in scene.minY..<scene.maxYExclusive {
            for sceneX in scene.minX..<scene.maxXExclusive {
                let rect = NSRect(
                    x: mapRect.minX + CGFloat(sceneX - scene.minX) * cellWidth,
                    y: mapRect.minY + CGFloat(sceneY - scene.minY) * cellHeight,
                    width: cellWidth,
                    height: cellHeight
                )

                var collisionRawValue: UInt16?
                if overlays.showBorder, let rawValue = borderRawValue(sceneX: sceneX, sceneY: sceneY) {
                    drawMetatile(rawValue: rawValue, in: rect)
                    collisionRawValue = rawValue
                }
                if overlays.showConnections,
                   let placement = document.scene.placement(containingSceneX: sceneX, sceneY: sceneY),
                   placement.role == .connection,
                   let rawValue = placement.rawValue(sceneX: sceneX, sceneY: sceneY) {
                    drawMetatile(rawValue: rawValue, in: rect)
                    collisionRawValue = rawValue
                }
                if let rawValue = layoutRawValue(sceneX: sceneX, sceneY: sceneY) {
                    drawMetatile(rawValue: rawValue, in: rect)
                    collisionRawValue = rawValue
                }

                if overlays.showCollision, let collisionRawValue {
                    drawCollision(rawValue: collisionRawValue, in: rect)
                }
            }
        }

        drawEvents(in: mapRect, cellWidth: cellWidth, cellHeight: cellHeight)
        if overlays.showGrid, cellWidth >= 4, cellHeight >= 4 {
            drawGrid(in: mapRect, viewport: scene)
        }
        drawViewport(in: mapRect, cellWidth: cellWidth, cellHeight: cellHeight)
    }

    override func mouseDown(with event: NSEvent) {
        guard let document else { return }
        let point = convert(event.locationInWindow, from: nil)
        let mapRect = overviewMapRect(for: document)
        guard mapRect.contains(point) else { return }
        let scene = document.scene.viewport
        let centerX = CGFloat(scene.minX) + (point.x - mapRect.minX) / max(mapRect.width, 1) * CGFloat(scene.width)
        let centerY = CGFloat(scene.minY) + (point.y - mapRect.minY) / max(mapRect.height, 1) * CGFloat(scene.height)
        onSelectViewportCenter(centerX, centerY)
    }

    private func overviewMapRect(for document: MapVisualDocument) -> NSRect {
        let scene = document.scene.viewport
        let mapAspect = max(CGFloat(scene.width), 1) / max(CGFloat(scene.height), 1)
        let available = bounds.insetBy(dx: 8, dy: 8)
        let widthFromHeight = available.height * mapAspect
        if widthFromHeight <= available.width {
            return NSRect(
                x: available.midX - widthFromHeight / 2,
                y: available.minY,
                width: widthFromHeight,
                height: available.height
            )
        }
        let heightFromWidth = available.width / mapAspect
        return NSRect(
            x: available.minX,
            y: available.midY - heightFromWidth / 2,
            width: available.width,
            height: heightFromWidth
        )
    }

    private func drawCollision(rawValue: UInt16, in rect: NSRect) {
        let collision = Int((rawValue >> 10) & 0x03)
        guard collision > 0 else { return }
        let opacity = CGFloat(overlays.layerOpacity(.collision))
        NSColor.systemRed.withAlphaComponent(0.18 * CGFloat(collision) * opacity).setFill()
        rect.fill()
    }

    private func layoutRawValue(sceneX: Int, sceneY: Int) -> UInt16? {
        guard let document,
              sceneX >= 0,
              sceneY >= 0,
              sceneX < document.blockdata.width,
              sceneY < document.blockdata.height
        else { return nil }
        let index = sceneY * document.blockdata.width + sceneX
        guard rawValues.indices.contains(index) else { return nil }
        return rawValues[index]
    }

    private func borderRawValue(sceneX: Int, sceneY: Int) -> UInt16? {
        guard let border = document?.border,
              border.width > 0,
              border.height > 0,
              !borderRawValues.isEmpty
        else { return nil }
        let x = positiveModulo(sceneX, border.width)
        let y = positiveModulo(sceneY, border.height)
        let index = y * border.width + x
        guard borderRawValues.indices.contains(index) else { return nil }
        return borderRawValues[index]
    }

    private func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
        guard divisor > 0 else { return 0 }
        let remainder = value % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }

    private func drawMetatile(rawValue: UInt16, in rect: NSRect) {
        let metatileID = Int(rawValue & 0x03ff)
        if overlays.hasVisibleMetatileLayer,
           let image = renderer?.image(
            for: metatileID,
            layers: overlays.visibleMetatileLayers,
            opacities: overlays.metatileLayerOpacities
           ) {
            image.draw(in: rect)
        } else if overlays.hasVisibleMetatileLayer {
            MetatileSwatchRenderer.fallbackColor(for: metatileID).setFill()
            rect.fill()
        }
    }

    private func drawEvents(in mapRect: NSRect, cellWidth: CGFloat, cellHeight: CGFloat) {
        for event in events where MapCanvasHitTester.shouldShow(event.kind, overlays: overlays) {
            guard let x = event.x, let y = event.y else { continue }
            let opacity = CGFloat(overlays.layerOpacity(MapCanvasHitTester.layer(for: event.kind)))
            let scene = document?.scene.viewport
            let rect = NSRect(
                x: mapRect.minX + CGFloat(x - (scene?.minX ?? 0)) * cellWidth,
                y: mapRect.minY + CGFloat(y - (scene?.minY ?? 0)) * cellHeight,
                width: max(cellWidth, 3),
                height: max(cellHeight, 3)
            ).insetBy(dx: -1, dy: -1)
            MapEventSpriteRenderer.drawOverviewEvent(
                event,
                in: rect,
                opacity: opacity,
                selected: false,
                fallbackColor: eventColor(event.kind)
            )
        }
    }

    private func drawGrid(in mapRect: NSRect, viewport: MapSceneViewport) {
        let path = NSBezierPath()
        for column in 0...viewport.width {
            let x = mapRect.minX + CGFloat(column) * mapRect.width / max(CGFloat(viewport.width), 1)
            path.move(to: NSPoint(x: x, y: mapRect.minY))
            path.line(to: NSPoint(x: x, y: mapRect.maxY))
        }
        for row in 0...viewport.height {
            let y = mapRect.minY + CGFloat(row) * mapRect.height / max(CGFloat(viewport.height), 1)
            path.move(to: NSPoint(x: mapRect.minX, y: y))
            path.line(to: NSPoint(x: mapRect.maxX, y: y))
        }
        NSColor.separatorColor.withAlphaComponent(CGFloat(0.18 * overlays.layerOpacity(.grid))).setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }

    private func drawViewport(in mapRect: NSRect, cellWidth: CGFloat, cellHeight: CGFloat) {
        guard !viewport.isEmpty else { return }
        let scene = document?.scene.viewport
        let rect = NSRect(
            x: mapRect.minX + (viewport.originX - CGFloat(scene?.minX ?? 0)) * cellWidth,
            y: mapRect.minY + (viewport.originY - CGFloat(scene?.minY ?? 0)) * cellHeight,
            width: min(viewport.width, viewport.mapWidth) * cellWidth,
            height: min(viewport.height, viewport.mapHeight) * cellHeight
        )
        NSColor.controlAccentColor.withAlphaComponent(0.16).setFill()
        rect.fill()
        NSColor.controlAccentColor.setStroke()
        let path = NSBezierPath(rect: rect.insetBy(dx: 0.5, dy: 0.5))
        path.lineWidth = 2
        path.stroke()
    }

    private func eventColor(_ kind: MapEventKind) -> NSColor {
        switch kind {
        case .object: .systemBlue
        case .warp: .systemPurple
        case .coord: .systemOrange
        case .bg: .systemGreen
        case .connection: .systemPink
        }
    }
}
