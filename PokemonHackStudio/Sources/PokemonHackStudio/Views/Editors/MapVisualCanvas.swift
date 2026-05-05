import AppKit
import PokemonHackCore
import SwiftUI

struct MapVisualCanvas: NSViewRepresentable {
    let document: MapVisualDocument
    let rawValues: [UInt16]
    let borderRawValues: [UInt16]
    let events: [MapEventDescriptor]
    let selectedTool: MapEditorTool
    let eventTemplate: MapEventTemplateKind
    let brushRawValue: UInt16?
    let overlays: MapOverlaySettings
    let zoom: CGFloat
    let selectedCell: MapCellSelection?
    let selectedCellTarget: MapBlockTarget
    let selectedEventID: String?
    let viewportRequest: MapCanvasViewportRequest?
    let onSelectCell: (Int, Int) -> Void
    let onPaintCell: (Int, Int) -> Void
    let onFillCell: (Int, Int) -> Void
    let onEyedropCell: (Int, Int) -> Void
    let onSelectEvent: (String?) -> Void
    let onMoveEvent: (Int, Int) -> Void
    let onAddEvent: (Int, Int) -> Void
    let onDuplicateEvent: () -> Void
    let onDeleteEvent: () -> Void
    let onHoverStatus: (MapCanvasHoverStatus?) -> Void
    let onViewportChange: (MapCanvasViewport) -> Void
    let onZoom: (CGFloat) -> Void
    let onCommand: (MapEditorCommand) -> Void

    func makeNSView(context: Context) -> MapCanvasNSView {
        let view = MapCanvasNSView()
        view.update(from: self)
        return view
    }

    func updateNSView(_ nsView: MapCanvasNSView, context: Context) {
        nsView.update(from: self)
    }
}

private enum DragState {
    case none
    case painting(last: MapCanvasCoordinate, target: MapBlockTarget)
    case rectangle(anchor: MapCanvasCoordinate, current: MapCanvasCoordinate, target: MapBlockTarget)
    case event(eventID: String, origin: MapCanvasCoordinate?, current: MapCanvasCoordinate, didDrag: Bool)
    case panning(lastPoint: NSPoint)
}

private enum KeyCode {
    static let delete: UInt16 = 51
    static let leftArrow: UInt16 = 123
    static let rightArrow: UInt16 = 124
    static let downArrow: UInt16 = 125
    static let upArrow: UInt16 = 126
}

final class MapCanvasNSView: NSView {
    private var document: MapVisualDocument?
    private var rawValues: [UInt16] = []
    private var borderRawValues: [UInt16] = []
    private var events: [MapEventDescriptor] = []
    private var selectedTool: MapEditorTool = .select
    private var eventTemplate: MapEventTemplateKind = .object
    private var brushRawValue: UInt16?
    private var overlays = MapOverlaySettings()
    private var zoom: CGFloat = 2
    private var selectedCell: MapCellSelection?
    private var selectedCellTarget: MapBlockTarget = .layout
    private var selectedEventID: String?
    private var viewportRequest: MapCanvasViewportRequest?
    private var renderer: MetatileSwatchRenderer?
    private var hoveredStatus: MapCanvasHoverStatus?
    private var rectanglePreview: MapCanvasRectanglePreview?
    private var eventDragPreview: MapCanvasEventDragPreview?
    private var dragState = DragState.none
    private var trackingArea: NSTrackingArea?
    private weak var observedClipView: NSClipView?
    private var lastHandledViewportRequestID: String?
    private var lastReportedViewport = MapCanvasViewport.zero
    private var onSelectCell: (Int, Int) -> Void = { _, _ in }
    private var onPaintCell: (Int, Int) -> Void = { _, _ in }
    private var onFillCell: (Int, Int) -> Void = { _, _ in }
    private var onEyedropCell: (Int, Int) -> Void = { _, _ in }
    private var onSelectEvent: (String?) -> Void = { _ in }
    private var onMoveEvent: (Int, Int) -> Void = { _, _ in }
    private var onAddEvent: (Int, Int) -> Void = { _, _ in }
    private var onDuplicateEvent: () -> Void = {}
    private var onDeleteEvent: () -> Void = {}
    private var onHoverStatus: (MapCanvasHoverStatus?) -> Void = { _ in }
    private var onViewportChange: (MapCanvasViewport) -> Void = { _ in }
    private var onZoom: (CGFloat) -> Void = { _ in }
    private var onCommand: (MapEditorCommand) -> Void = { _ in }

    override var isFlipped: Bool { true }
    private var tileSize: CGFloat { max(2, 16 * zoom) }
    private var isReadOnlyZoom: Bool { zoom < MapViewportGeometry.minimumEditableZoom }
    private var canvasSize: MapCanvasSize? {
        document.map {
            MapCanvasSize(
                originX: $0.scene.viewport.minX,
                originY: $0.scene.viewport.minY,
                width: $0.scene.viewport.width,
                height: $0.scene.viewport.height
            )
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func isAccessibilityElement() -> Bool {
        true
    }

    override func accessibilityRole() -> NSAccessibility.Role? {
        .group
    }

    override func accessibilityLabel() -> String? {
        accessibilityCanvasLabel
    }

    override func accessibilityValue() -> Any? {
        accessibilityCanvasValue
    }

    override func accessibilityChildren() -> [Any]? {
        accessibilityCanvasChildren
    }

    func update(from canvas: MapVisualCanvas) {
        let needsRenderer = document?.id != canvas.document.id
        document = canvas.document
        rawValues = canvas.rawValues
        borderRawValues = canvas.borderRawValues
        events = canvas.events
        selectedTool = canvas.selectedTool
        eventTemplate = canvas.eventTemplate
        brushRawValue = canvas.brushRawValue
        overlays = canvas.overlays
        zoom = canvas.zoom
        selectedCell = canvas.selectedCell
        selectedCellTarget = canvas.selectedCellTarget
        selectedEventID = canvas.selectedEventID
        viewportRequest = canvas.viewportRequest
        onSelectCell = canvas.onSelectCell
        onPaintCell = canvas.onPaintCell
        onFillCell = canvas.onFillCell
        onEyedropCell = canvas.onEyedropCell
        onSelectEvent = canvas.onSelectEvent
        onMoveEvent = canvas.onMoveEvent
        onAddEvent = canvas.onAddEvent
        onDuplicateEvent = canvas.onDuplicateEvent
        onDeleteEvent = canvas.onDeleteEvent
        onHoverStatus = canvas.onHoverStatus
        onViewportChange = canvas.onViewportChange
        onZoom = canvas.onZoom
        onCommand = canvas.onCommand
        if needsRenderer {
            renderer = MetatileSwatchRenderer(document: canvas.document)
        } else {
            renderer?.update(document: canvas.document)
        }
        setAccessibilityLabel(accessibilityCanvasLabel)
        setAccessibilityValue(accessibilityCanvasValue)
        setNeedsDisplay(bounds)
        installScrollObserverIfNeeded()
        handleViewportRequestIfNeeded()
        reportViewportIfNeeded()
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let document else { return }
        NSColor.windowBackgroundColor.setFill()
        dirtyRect.fill()

        let viewport = document.scene.viewport
        let visibleColumns = visibleRange(origin: viewport.minX, length: viewport.width, min: dirtyRect.minX, max: dirtyRect.maxX)
        let visibleRows = visibleRange(origin: viewport.minY, length: viewport.height, min: dirtyRect.minY, max: dirtyRect.maxY)

        for sceneY in visibleRows {
            for sceneX in visibleColumns {
                let rect = rect(forSceneX: sceneX, sceneY: sceneY)
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

        if overlays.showGrid {
            drawGrid(viewport: viewport, opacity: overlays.layerOpacity(.grid))
        }

        drawPlayerView()
        drawRectanglePreview()
        drawSelectedCell()
        drawHover()
        drawEvents()
        drawEventDragPreview()
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        let point = convert(event.locationInWindow, from: nil)
        guard let hit = hitTester().hit(at: point) else { return }
        let coordinate = hit.coordinate
        updateHover(with: hit)

        if isReadOnlyZoom, selectedTool != .hand {
            if let eventID = hit.eventID {
                commit(.selectMapEvent(id: eventID))
            } else if let target = hit.target {
                commit(.selectMapEvent(id: nil))
                commit(.selectMapCell(x: coordinate.x, y: coordinate.y, target: target))
            }
            return
        }

        switch selectedTool {
        case .pencil:
            guard let target = hit.target else { return }
            commit(.paintMapCell(x: coordinate.x, y: coordinate.y, target: target))
            dragState = .painting(last: coordinate, target: target)
        case .rectangleFill:
            guard let target = hit.target else { return }
            rectanglePreview = MapCanvasRectanglePreview(anchor: coordinate, focus: coordinate)
            dragState = .rectangle(anchor: coordinate, current: coordinate, target: target)
            commit(.selectMapCell(x: coordinate.x, y: coordinate.y, target: target))
            setNeedsDisplay(bounds)
        case .eyedropper:
            guard let target = hit.target else { return }
            commit(.eyedropMapCell(x: coordinate.x, y: coordinate.y, target: target))
        case .eventMove:
            if let eventID = hit.eventID {
                commit(.selectMapEvent(id: eventID))
                dragState = .event(eventID: eventID, origin: coordinate, current: coordinate, didDrag: false)
            } else if selectedEventID != nil {
                dragState = .event(eventID: selectedEventID ?? "", origin: nil, current: coordinate, didDrag: false)
            } else if let target = hit.target {
                commit(.selectMapCell(x: coordinate.x, y: coordinate.y, target: target))
            }
        case .addEvent:
            guard hit.target == .layout else { return }
            commit(.addMapEvent(template: eventTemplate, x: coordinate.x, y: coordinate.y))
        case .delete:
            if let eventID = hit.eventID {
                commit(.selectMapEvent(id: eventID))
                commit(.deleteSelectedMapEvent)
            }
        case .duplicate:
            if let eventID = hit.eventID {
                commit(.selectMapEvent(id: eventID))
                commit(.duplicateSelectedMapEvent)
            } else if let target = hit.target {
                commit(.selectMapCell(x: coordinate.x, y: coordinate.y, target: target))
            }
        case .select:
            if let eventID = hit.eventID {
                commit(.selectMapEvent(id: eventID))
            } else if let target = hit.target {
                commit(.selectMapEvent(id: nil))
                commit(.selectMapCell(x: coordinate.x, y: coordinate.y, target: target))
            }
        case .hand:
            dragState = .panning(lastPoint: point)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        switch dragState {
        case .painting(let last, let target):
            guard let coordinate = hitTester().coordinate(at: point), coordinate != last else { return }
            commit(.paintMapCell(x: coordinate.x, y: coordinate.y, target: target))
            dragState = .painting(last: coordinate, target: target)
        case .rectangle(let anchor, let current, let target):
            guard let coordinate = hitTester().coordinate(at: point), coordinate != current else { return }
            let preview = MapCanvasRectanglePreview(anchor: anchor, focus: coordinate)
            rectanglePreview = preview
            dragState = .rectangle(anchor: anchor, current: coordinate, target: target)
            setNeedsDisplay(bounds)
        case .event(let eventID, let origin, let current, _):
            guard !eventID.isEmpty,
                  let coordinate = hitTester().coordinate(at: point),
                  coordinate != current
            else { return }
            eventDragPreview = MapCanvasEventDragPreview(eventID: eventID, origin: origin, focus: coordinate)
            dragState = .event(eventID: eventID, origin: origin, current: coordinate, didDrag: true)
            setNeedsDisplay(bounds)
        case .panning(let lastPoint):
            let delta = CGSize(width: point.x - lastPoint.x, height: point.y - lastPoint.y)
            pan(by: delta)
            dragState = .panning(lastPoint: point)
        case .none:
            break
        }
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        defer {
            dragState = .none
            rectanglePreview = nil
            eventDragPreview = nil
            setNeedsDisplay(bounds)
        }

        switch dragState {
        case .rectangle(let anchor, let current, let target):
            let focus = hitTester().coordinate(at: point) ?? current
            let preview = MapCanvasRectanglePreview(anchor: anchor, focus: focus)
            commit(
                .fillMapRectangle(
                    x: preview.minX,
                    y: preview.minY,
                    width: preview.width,
                    height: preview.height,
                    target: target,
                    rawValue: brushRawValue
                )
            )
        case .event(let eventID, let origin, let current, let didDrag):
            guard !eventID.isEmpty else { return }
            let focus = hitTester().coordinate(at: point) ?? current
            if didDrag || origin == nil {
                commit(.moveSelectedMapEvent(x: focus.x, y: focus.y))
            }
        case .panning:
            break
        case .painting, .none:
            break
        }
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if let hit = hitTester().hit(at: point) {
            updateHover(with: hit)
        } else {
            clearHover()
        }
    }

    override func mouseExited(with event: NSEvent) {
        clearHover()
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case KeyCode.delete:
            commit(.deleteSelectedMapEvent)
        case KeyCode.leftArrow:
            scrollViewport(byContentDelta: CGSize(width: -keyboardPanStep(for: event), height: 0))
        case KeyCode.rightArrow:
            scrollViewport(byContentDelta: CGSize(width: keyboardPanStep(for: event), height: 0))
        case KeyCode.upArrow:
            scrollViewport(byContentDelta: CGSize(width: 0, height: -keyboardPanStep(for: event)))
        case KeyCode.downArrow:
            scrollViewport(byContentDelta: CGSize(width: 0, height: keyboardPanStep(for: event)))
        default:
            super.keyDown(with: event)
        }
    }

    override func scrollWheel(with event: NSEvent) {
        let verticalDelta = event.scrollingDeltaY
        guard verticalDelta.isFinite,
              abs(verticalDelta) > 0,
              abs(verticalDelta) >= abs(event.scrollingDeltaX)
        else {
            super.scrollWheel(with: event)
            return
        }

        window?.makeFirstResponder(self)
        let clampedDelta = min(max(verticalDelta, -24), 24)
        requestZoom(by: CGFloat(pow(1.02, Double(clampedDelta))))
    }

    override func magnify(with event: NSEvent) {
        window?.makeFirstResponder(self)
        requestZoom(by: 1 + event.magnification)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.acceptsMouseMovedEvents = true
        installScrollObserverIfNeeded()
        handleViewportRequestIfNeeded()
        reportViewportIfNeeded()
    }

    deinit {
        if let observedClipView {
            NotificationCenter.default.removeObserver(self, name: NSView.boundsDidChangeNotification, object: observedClipView)
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let nextTrackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(nextTrackingArea)
        trackingArea = nextTrackingArea
    }

    private func hitTester() -> MapCanvasHitTester {
        MapCanvasHitTester(
            size: canvasSize ?? MapCanvasSize(width: 0, height: 0),
            tileSize: tileSize,
            document: document ?? MapVisualDocument(
                id: "empty",
                rootPath: "",
                profile: .unknown,
                mapID: "",
                mapName: "",
                mapSourcePath: "",
                layout: LayoutSlot(
                    slotIndex: 0,
                    layoutID: nil,
                    name: nil,
                    width: 0,
                    height: 0,
                    borderWidth: nil,
                    borderHeight: nil,
                    primaryTileset: nil,
                    secondaryTileset: nil,
                    borderFilepath: nil,
                    blockdataFilepath: nil,
                    sourcePath: ""
                ),
                blockdata: EditableLayoutBlockdata(filepath: "", width: 0, height: 0, rawValues: []),
                border: nil,
                primaryTileset: nil,
                secondaryTileset: nil,
                metatiles: [],
                events: [],
                mapJSONText: "{}"
            ),
            rawValues: rawValues,
            borderRawValues: borderRawValues,
            events: events,
            overlays: overlays
        )
    }

    private func installScrollObserverIfNeeded() {
        guard let clipView = enclosingScrollView?.contentView, observedClipView !== clipView else { return }
        if let observedClipView {
            NotificationCenter.default.removeObserver(self, name: NSView.boundsDidChangeNotification, object: observedClipView)
        }
        observedClipView = clipView
        clipView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clipViewBoundsDidChange(_:)),
            name: NSView.boundsDidChangeNotification,
            object: clipView
        )
    }

    @objc private func clipViewBoundsDidChange(_ notification: Notification) {
        reportViewportIfNeeded()
    }

    private func handleViewportRequestIfNeeded() {
        guard let viewportRequest, viewportRequest.id != lastHandledViewportRequestID else { return }
        guard let scrollView = enclosingScrollView, let document else { return }

        let clipView = scrollView.contentView
        let sceneViewport = document.scene.viewport
        var origin = NSPoint(
            x: (viewportRequest.centerX - CGFloat(sceneViewport.minX)) * tileSize - clipView.bounds.width / 2,
            y: (viewportRequest.centerY - CGFloat(sceneViewport.minY)) * tileSize - clipView.bounds.height / 2
        )
        let maxX = max(CGFloat(sceneViewport.width) * tileSize - clipView.bounds.width, 0)
        let maxY = max(CGFloat(sceneViewport.height) * tileSize - clipView.bounds.height, 0)
        origin.x = min(max(origin.x, 0), maxX)
        origin.y = min(max(origin.y, 0), maxY)
        clipView.scroll(to: origin)
        scrollView.reflectScrolledClipView(clipView)
        lastHandledViewportRequestID = viewportRequest.id
        reportViewportIfNeeded()
    }

    private func reportViewportIfNeeded() {
        guard let document, let clipView = enclosingScrollView?.contentView else { return }
        let visible = clipView.bounds
        let sceneViewport = document.scene.viewport
        let viewport = MapCanvasViewport(
            originX: CGFloat(sceneViewport.minX) + visible.minX / tileSize,
            originY: CGFloat(sceneViewport.minY) + visible.minY / tileSize,
            width: min(CGFloat(sceneViewport.width), visible.width / tileSize),
            height: min(CGFloat(sceneViewport.height), visible.height / tileSize),
            mapWidth: CGFloat(sceneViewport.width),
            mapHeight: CGFloat(sceneViewport.height)
        )
        guard viewport != lastReportedViewport else { return }
        lastReportedViewport = viewport
        onViewportChange(viewport)
    }

    private func updateHover(with hit: MapCanvasHitResult) {
        let status = MapCanvasHoverStatus(hit: hit)
        guard hoveredStatus != status else { return }
        hoveredStatus = status
        onHoverStatus(status)
        setAccessibilityValue(accessibilityCanvasValue)
        setNeedsDisplay(bounds)
    }

    private func clearHover() {
        guard hoveredStatus != nil else { return }
        hoveredStatus = nil
        onHoverStatus(nil)
        setAccessibilityValue(accessibilityCanvasValue)
        setNeedsDisplay(bounds)
    }

    private func emit(_ command: MapEditorCommand) {
        onCommand(command)
    }

    private func commit(_ command: MapEditorCommand) {
        emit(command)
        switch command {
        case .selectMapCell(let x, let y, _):
            onSelectCell(x, y)
        case .paintMapCell(let x, let y, _):
            onPaintCell(x, y)
        case .eyedropMapCell(let x, let y, _):
            onEyedropCell(x, y)
        case .fillMapRectangle(let x, let y, let width, let height, _, _):
            onFillCell(x + width - 1, y + height - 1)
        case .fillMapFromSelection(let x, let y, _):
            onFillCell(x, y)
        case .selectMapEvent(let eventID):
            onSelectEvent(eventID)
        case .moveSelectedMapEvent(let x, let y):
            onMoveEvent(x, y)
        case .addObjectEvent(let x, let y), .addMapEvent(_, let x, let y):
            onAddEvent(x, y)
        case .duplicateSelectedMapEvent:
            onDuplicateEvent()
        case .deleteSelectedMapEvent:
            onDeleteEvent()
        default:
            break
        }
    }

    private func pan(by delta: CGSize) {
        scrollViewport(byContentDelta: CGSize(width: -delta.width, height: -delta.height))
    }

    private func scrollViewport(byContentDelta delta: CGSize) {
        guard let scrollView = enclosingScrollView else { return }
        let clipView = scrollView.contentView
        var origin = clipView.bounds.origin
        origin.x += delta.width
        origin.y += delta.height
        let maxX = max(bounds.width - clipView.bounds.width, 0)
        let maxY = max(bounds.height - clipView.bounds.height, 0)
        origin.x = min(max(origin.x, 0), maxX)
        origin.y = min(max(origin.y, 0), maxY)
        clipView.scroll(to: origin)
        scrollView.reflectScrolledClipView(clipView)
        reportViewportIfNeeded()
    }

    private func keyboardPanStep(for event: NSEvent) -> CGFloat {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains(.option) {
            return tileSize * 12
        }
        if flags.contains(.shift) {
            return tileSize * 6
        }
        return tileSize * 3
    }

    private func requestZoom(by factor: CGFloat) {
        let clampedFactor = min(max(factor, 0.25), 4)
        guard clampedFactor.isFinite, abs(clampedFactor - 1) > 0.001 else { return }
        onZoom(clampedFactor)
    }

    private var accessibilityCanvasLabel: String {
        guard let document else { return "Map canvas" }
        return "\(document.mapName) map canvas, \(document.blockdata.width) by \(document.blockdata.height) cells"
    }

    private var accessibilityCanvasValue: String? {
        if let hoveredStatus {
            return hoveredStatus.statusText
        }
        if let selectedCell {
            return "Selected cell \(selectedCell.x), \(selectedCell.y), metatile \(String(format: "%03X", selectedCell.metatileID))"
        }
        if let selectedEventID {
            return "Selected event \(selectedEventID)"
        }
        return nil
    }

    private var accessibilityCanvasChildren: [Any] {
        var children: [NSAccessibilityElement] = []
        if let selectedCell {
            let coordinate = MapCanvasCoordinate(x: selectedCell.x, y: selectedCell.y)
            children.append(
                accessibilityElement(
                    label: "Selected cell \(coordinate.x), \(coordinate.y)",
                    value: "Metatile \(String(format: "%03X", selectedCell.metatileID))",
                    role: .group,
                    rect: rect(for: coordinate)
                )
            )
        }

        for event in events where MapCanvasHitTester.shouldShow(event.kind, overlays: overlays) {
            guard let x = event.x, let y = event.y else { continue }
            let coordinate = MapCanvasCoordinate(x: x, y: y)
            children.append(
                accessibilityElement(
                    label: "\(event.kind.rawValue.capitalized) event \(event.index)",
                    value: event.id == selectedEventID ? "Selected" : nil,
                    role: .button,
                    rect: rect(for: coordinate)
                )
            )
        }
        return children
    }

    private func accessibilityElement(
        label: String,
        value: String?,
        role: NSAccessibility.Role,
        rect: NSRect
    ) -> NSAccessibilityElement {
        let element = NSAccessibilityElement()
        element.setAccessibilityParent(self)
        element.setAccessibilityRole(role)
        element.setAccessibilityLabel(label)
        element.setAccessibilityValue(value)
        if let screenRect = screenRect(for: rect) {
            element.setAccessibilityFrame(screenRect)
        }
        return element
    }

    private func screenRect(for rect: NSRect) -> NSRect? {
        guard let window else { return nil }
        return window.convertToScreen(convert(rect, to: nil))
    }

    private func visibleRange(origin: Int, length: Int, min: CGFloat, max: CGFloat) -> Range<Int> {
        let localStart = Swift.max(0, Int(floor(min / tileSize)) - 1)
        let localEnd = Swift.min(length, Int(ceil(max / tileSize)) + 1)
        let start = origin + localStart
        let end = origin + localEnd
        return start..<Swift.max(start, end)
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
            MetatileSwatchRenderer.fallbackColor(for: metatileID)
                .withAlphaComponent(CGFloat(max(overlays.metatileLayerOpacities.values.max() ?? 1, 0.15)))
                .setFill()
            rect.fill()
            if zoom >= 1.4 {
                drawID(metatileID, in: rect)
            }
        }
    }

    private func drawID(_ metatileID: Int, in rect: NSRect) {
        let label = String(format: "%03X", metatileID)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: max(8, tileSize * 0.22), weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let size = label.size(withAttributes: attributes)
        label.draw(at: NSPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2), withAttributes: attributes)
    }

    private func drawCollision(rawValue: UInt16, in rect: NSRect) {
        let collision = Int((rawValue >> 10) & 0x03)
        guard collision > 0 else { return }
        let opacity = CGFloat(overlays.layerOpacity(.collision))
        NSColor.systemRed.withAlphaComponent(0.18 * CGFloat(collision) * opacity).setFill()
        rect.fill()
    }

    private func drawGrid(viewport: MapSceneViewport, opacity: Double) {
        let path = NSBezierPath()
        for column in viewport.minX...viewport.maxXExclusive {
            let x = CGFloat(column - viewport.minX) * tileSize
            path.move(to: NSPoint(x: x, y: 0))
            path.line(to: NSPoint(x: x, y: CGFloat(viewport.height) * tileSize))
        }
        for row in viewport.minY...viewport.maxYExclusive {
            let y = CGFloat(row - viewport.minY) * tileSize
            path.move(to: NSPoint(x: 0, y: y))
            path.line(to: NSPoint(x: CGFloat(viewport.width) * tileSize, y: y))
        }
        NSColor.separatorColor.withAlphaComponent(CGFloat(0.28 * opacity)).setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }

    private func drawBorderPreview(_ border: EditableLayoutBlockdata, opacity: Double) {
        guard tileSize >= 20 else { return }
        let rect = NSRect(x: 8, y: 8, width: CGFloat(border.width) * 12, height: CGFloat(border.height) * 12)
        NSColor.black.withAlphaComponent(CGFloat(0.42 * opacity)).setFill()
        NSBezierPath(roundedRect: rect.insetBy(dx: -6, dy: -6), xRadius: 6, yRadius: 6).fill()
        for row in 0..<border.height {
            for column in 0..<border.width {
                let index = row * border.width + column
                guard border.rawValues.indices.contains(index) else { continue }
                let id = Int(border.rawValues[index] & 0x03ff)
                let cell = NSRect(x: rect.minX + CGFloat(column) * 12, y: rect.minY + CGFloat(row) * 12, width: 12, height: 12)
                if overlays.hasVisibleMetatileLayer,
                   let image = renderer?.image(for: id, layers: overlays.visibleMetatileLayers, opacities: overlays.metatileLayerOpacities) {
                    image.draw(in: cell, from: .zero, operation: .sourceOver, fraction: CGFloat(opacity))
                } else if overlays.hasVisibleMetatileLayer {
                    MetatileSwatchRenderer.fallbackColor(for: id).withAlphaComponent(CGFloat(opacity)).setFill()
                    cell.fill()
                }
            }
        }
    }

    private func drawPlayerView() {
        guard overlays.showPlayerView else { return }
        let focus: MapCanvasCoordinate
        if let hoveredStatus, hoveredStatus.target == .layout {
            focus = hoveredStatus.coordinate
        } else if let selectedCell, selectedCellTarget == .layout {
            focus = MapCanvasCoordinate(x: selectedCell.x, y: selectedCell.y)
        } else {
            return
        }

        let width = MapVisualScene.gameViewportTileWidth
        let height = MapVisualScene.gameViewportTileHeight
        let minX = focus.x - width / 2
        let minY = focus.y - height / 2
        let rect = NSRect(
            x: CGFloat(minX - (document?.scene.viewport.minX ?? 0)) * tileSize,
            y: CGFloat(minY - (document?.scene.viewport.minY ?? 0)) * tileSize,
            width: CGFloat(width) * tileSize,
            height: CGFloat(height) * tileSize
        )
        let opacity = CGFloat(overlays.layerOpacity(.playerView))
        NSColor.controlAccentColor.withAlphaComponent(0.08 * opacity).setFill()
        rect.fill()
        NSColor.controlAccentColor.withAlphaComponent(0.9 * opacity).setStroke()
        let path = NSBezierPath(rect: rect.insetBy(dx: 1, dy: 1))
        path.lineWidth = 2
        path.stroke()
        if tileSize >= 14 {
            drawBadge("240x160", near: rect)
        }
    }

    private func drawSelectedCell() {
        guard let selectedCell else { return }
        guard selectedCellTarget == .layout else { return }
        let rect = rect(for: MapCanvasCoordinate(x: selectedCell.x, y: selectedCell.y))
        NSColor.controlAccentColor.setStroke()
        let path = NSBezierPath(rect: rect.insetBy(dx: 1, dy: 1))
        path.lineWidth = 3
        path.stroke()
    }

    private func drawHover() {
        guard let hoveredStatus else { return }
        let rect = rect(for: hoveredStatus.sceneCoordinate)
        NSColor.selectedControlColor.withAlphaComponent(0.16).setFill()
        rect.fill()
        NSColor.selectedControlColor.withAlphaComponent(0.72).setStroke()
        let path = NSBezierPath(rect: rect.insetBy(dx: 1.5, dy: 1.5))
        path.lineWidth = 1.5
        path.stroke()
    }

    private func drawRectanglePreview() {
        guard let rectanglePreview else { return }
        let rect = rect(for: rectanglePreview)
        NSColor.controlAccentColor.withAlphaComponent(0.16).setFill()
        rect.fill()
        NSColor.controlAccentColor.setStroke()
        let path = NSBezierPath(rect: rect.insetBy(dx: 1, dy: 1))
        path.lineWidth = 2
        path.stroke()

        if tileSize >= 22 {
            let label = "\(rectanglePreview.width)x\(rectanglePreview.height)"
            drawBadge(label, near: rect)
        }
    }

    private func drawEvents() {
        for event in events where MapCanvasHitTester.shouldShow(event.kind, overlays: overlays) {
            guard let x = event.x, let y = event.y else { continue }
            let rect = rect(for: MapCanvasCoordinate(x: x, y: y))
            let opacity = CGFloat(overlays.layerOpacity(MapCanvasHitTester.layer(for: event.kind)))
            MapEventSpriteRenderer.drawEvent(
                event,
                document: document,
                tileRect: rect,
                tileSize: tileSize,
                opacity: opacity,
                selected: event.id == selectedEventID,
                fallbackColor: eventColor(event.kind)
            )
        }
    }

    private func drawEventDragPreview() {
        guard let eventDragPreview else { return }
        if let origin = eventDragPreview.origin {
            let originRect = rect(for: origin)
            let focusRect = rect(for: eventDragPreview.focus)
            let path = NSBezierPath()
            path.move(to: NSPoint(x: originRect.midX, y: originRect.midY))
            path.line(to: NSPoint(x: focusRect.midX, y: focusRect.midY))
            NSColor.controlAccentColor.withAlphaComponent(0.75).setStroke()
            path.lineWidth = 2
            path.stroke()
        }

        let rect = rect(for: eventDragPreview.focus)
        NSColor.controlAccentColor.withAlphaComponent(0.24).setFill()
        NSBezierPath(ovalIn: rect.insetBy(dx: tileSize * 0.18, dy: tileSize * 0.18)).fill()
        NSColor.controlAccentColor.setStroke()
        let ring = NSBezierPath(ovalIn: rect.insetBy(dx: tileSize * 0.14, dy: tileSize * 0.14))
        ring.lineWidth = 2
        ring.stroke()
    }

    private func drawBadge(_ label: String, near rect: NSRect) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        let size = label.size(withAttributes: attributes)
        let badge = NSRect(
            x: rect.maxX - size.width - 8,
            y: rect.minY + 4,
            width: size.width + 6,
            height: size.height + 4
        )
        NSColor.black.withAlphaComponent(0.54).setFill()
        NSBezierPath(roundedRect: badge, xRadius: 4, yRadius: 4).fill()
        label.draw(at: NSPoint(x: badge.minX + 3, y: badge.minY + 2), withAttributes: attributes)
    }

    private func rect(for coordinate: MapCanvasCoordinate) -> NSRect {
        guard let document else {
            return NSRect(x: CGFloat(coordinate.x) * tileSize, y: CGFloat(coordinate.y) * tileSize, width: tileSize, height: tileSize)
        }
        return rect(forSceneX: coordinate.x, sceneY: coordinate.y, viewport: document.scene.viewport)
    }

    private func rect(forSceneX sceneX: Int, sceneY: Int, viewport: MapSceneViewport? = nil) -> NSRect {
        let resolvedViewport = viewport ?? document?.scene.viewport
        let originX = resolvedViewport?.minX ?? 0
        let originY = resolvedViewport?.minY ?? 0
        return NSRect(
            x: CGFloat(sceneX - originX) * tileSize,
            y: CGFloat(sceneY - originY) * tileSize,
            width: tileSize,
            height: tileSize
        )
    }

    private func rect(for preview: MapCanvasRectanglePreview) -> NSRect {
        let originX = document?.scene.viewport.minX ?? 0
        let originY = document?.scene.viewport.minY ?? 0
        return NSRect(
            x: CGFloat(preview.minX - originX) * tileSize,
            y: CGFloat(preview.minY - originY) * tileSize,
            width: CGFloat(preview.width) * tileSize,
            height: CGFloat(preview.height) * tileSize
        )
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
