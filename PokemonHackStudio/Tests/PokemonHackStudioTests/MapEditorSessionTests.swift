import AppKit
import CoreGraphics
import PokemonHackCore
import XCTest

final class MapEditorSessionTests: XCTestCase {
    @MainActor
    func testDirtyStateDiscardAndReset() throws {
        let session = MapEditorSession(document: makeDocument())

        XCTAssertFalse(session.isDirty)
        XCTAssertFalse(session.canPreviewSelectedMapMutationPlan)
        XCTAssertEqual(session.previewBlockedReason, "No staged edits to preview.")

        XCTAssertTrue(session.dispatch(.setOverlay(.grid, false)))
        XCTAssertFalse(session.isOverlayVisible(.grid))
        XCTAssertTrue(session.dispatch(.toggleOverlay(.grid)))
        XCTAssertTrue(session.isOverlayVisible(.grid))

        session.selectMapCell(x: 0, y: 0)
        session.selectBrush(rawValue: 0x0022)
        XCTAssertTrue(session.paintMapCell(x: 1, y: 0))

        XCTAssertTrue(session.isDirty)
        XCTAssertTrue(session.canPreviewSelectedMapMutationPlan)
        XCTAssertEqual(session.stagedMapBlockdataValues, [1, 0x0022, 3, 4])
        XCTAssertNil(session.latestMapEditPlan)

        let plan = try XCTUnwrap(session.previewSelectedMapMutationPlan())
        XCTAssertEqual(plan.changes.map(\.path), ["data/layouts/Route1/map.bin"])
        XCTAssertTrue(session.canApplySelectedMapMutationPlan)

        session.discardChanges()
        XCTAssertFalse(session.isDirty)
        XCTAssertEqual(session.stagedMapBlockdataValues, [1, 2, 3, 4])
        XCTAssertNil(session.latestMapEditPlan)
        XCTAssertEqual(session.selectedMapCell?.x, 1)
        XCTAssertEqual(session.selectedMapCell?.y, 0)
        XCTAssertEqual(session.selectedMapCell?.rawValue, 2)

        session.reset()
        XCTAssertNil(session.selectedMapVisualDocument)
        XCTAssertTrue(session.stagedMapBlockdataValues.isEmpty)
        XCTAssertTrue(session.stagedMapEvents.isEmpty)
        XCTAssertEqual(session.selectedMapTool, .select)
        XCTAssertFalse(session.isDirty)
    }

    @MainActor
    func testMixedBlockAndEventUndoRedoStacks() throws {
        let session = MapEditorSession(document: makeDocument())

        session.selectBrush(rawValue: 0x0010)
        XCTAssertTrue(session.paintMapCell(x: 0, y: 0))
        session.selectMapEvent(id: "object-0")
        XCTAssertTrue(session.moveSelectedMapEvent(toX: 4, y: 5))

        XCTAssertEqual(session.mapEditOperations.map(\.action), [.paintMetatile, .moveEvent])
        XCTAssertEqual(session.stagedMapBlockdataValues[0], 0x0010)
        XCTAssertEqual(session.selectedMapEvent?.x, 4)
        XCTAssertEqual(session.selectedMapEvent?.y, 5)

        session.undoLastMapEdit()
        XCTAssertEqual(session.mapEditOperations.map(\.action), [.paintMetatile])
        XCTAssertEqual(session.undoneMapEditOperations.map(\.action), [.moveEvent])
        XCTAssertEqual(session.stagedMapBlockdataValues[0], 0x0010)
        XCTAssertEqual(session.selectedMapEvent?.x, 1)
        XCTAssertEqual(session.selectedMapEvent?.y, 1)

        session.undoLastMapEdit()
        XCTAssertFalse(session.isDirty)
        XCTAssertEqual(session.stagedMapBlockdataValues, [1, 2, 3, 4])
        XCTAssertEqual(session.undoneMapEditOperations.map(\.action), [.moveEvent, .paintMetatile])

        session.redoMapEdit()
        session.redoMapEdit()
        XCTAssertTrue(session.isDirty)
        XCTAssertEqual(session.stagedMapBlockdataValues[0], 0x0010)
        XCTAssertEqual(session.selectedMapEvent?.x, 4)
        XCTAssertEqual(session.selectedMapEvent?.y, 5)
    }

    @MainActor
    func testFillAndEyedropperFlows() throws {
        let session = MapEditorSession(document: makeDocument())

        session.eyedropMapCell(x: 1, y: 1)
        XCTAssertFalse(session.isDirty)
        XCTAssertEqual(session.selectedBrushRawValue, 4)
        XCTAssertEqual(session.selectedMapCell?.metatileID, 4)

        session.selectMapCell(x: 0, y: 0)
        XCTAssertTrue(session.fillMapFromSelection(toX: 1, y: 1))

        XCTAssertTrue(session.isDirty)
        XCTAssertEqual(session.stagedMapBlockdataValues, [4, 4, 4, 4])
        XCTAssertEqual(session.mapEditOperations.count, 1)
        XCTAssertEqual(session.mapEditOperations.first?.action, .fillMetatile)
        XCTAssertEqual(session.mapEditOperations.first?.width, 2)
        XCTAssertEqual(session.mapEditOperations.first?.height, 2)
    }

    @MainActor
    func testMoveAddDuplicateAndDeleteEventFlows() throws {
        let session = MapEditorSession(document: makeDocument())

        session.selectMapEvent(id: "object-0")
        XCTAssertTrue(session.moveSelectedMapEvent(toX: 5, y: 6))
        XCTAssertEqual(session.selectedMapEvent?.x, 5)
        XCTAssertEqual(session.selectedMapEvent?.y, 6)
        XCTAssertEqual(session.selectedMapEvent?.properties.first { $0.key == "x" }?.value, "5")
        XCTAssertEqual(session.selectedMapEvent?.properties.first { $0.key == "y" }?.value, "6")

        XCTAssertTrue(session.addObjectEvent(atX: 2, y: 2))
        XCTAssertEqual(session.stagedMapEvents.count, 2)
        XCTAssertEqual(session.selectedMapEventID, "object-1")

        XCTAssertTrue(session.duplicateSelectedMapEvent())
        XCTAssertEqual(session.stagedMapEvents.count, 3)
        XCTAssertEqual(session.selectedMapEventID, "object-2")
        XCTAssertEqual(session.selectedMapEvent?.x, 3)
        XCTAssertEqual(session.selectedMapEvent?.y, 2)
        XCTAssertEqual(session.mapEditOperations.map(\.action), [.moveEvent, .addEvent, .duplicateEvent, .moveEvent])

        XCTAssertTrue(session.deleteSelectedMapEvent())
        XCTAssertEqual(session.stagedMapEvents.count, 2)
        XCTAssertNil(session.selectedMapEventID)
        XCTAssertEqual(session.mapEditOperations.last?.action, .deleteEvent)

        session.undoLastMapEdit()
        XCTAssertEqual(session.stagedMapEvents.count, 3)
        XCTAssertEqual(session.selectedMapEventID, "object-2")
    }

    @MainActor
    func testAddEventTemplatesUseSubtypeDefaults() throws {
        let session = MapEditorSession(document: makeDocument())

        XCTAssertTrue(session.addMapEvent(template: .warp, atX: 0, y: 1))
        XCTAssertTrue(session.addMapEvent(template: .coordTrigger, atX: 1, y: 0))
        XCTAssertTrue(session.addMapEvent(template: .bgSign, atX: 0, y: 0))
        XCTAssertTrue(session.addMapEvent(template: .bgHiddenItem, atX: 1, y: 1))

        let warp = try XCTUnwrap(session.stagedMapEvents.first { $0.kind == .warp })
        let coord = try XCTUnwrap(session.stagedMapEvents.first { $0.kind == .coord })
        let signs = session.stagedMapEvents.filter { $0.kind == .bg }
        let sign = try XCTUnwrap(signs.first { $0.propertyValue("type") == "sign" })
        let hiddenItem = try XCTUnwrap(signs.first { $0.propertyValue("type") == "hidden_item" })

        XCTAssertEqual(warp.propertyValue("dest_map"), "MAP_ROUTE1")
        XCTAssertEqual(warp.propertyValue("dest_warp_id"), "0")
        XCTAssertEqual(coord.propertyValue("var"), "VAR_TEMP_1")
        XCTAssertEqual(coord.propertyValue("script"), "0x0")
        XCTAssertEqual(sign.propertyValue("player_facing_dir"), "BG_EVENT_PLAYER_FACING_ANY")
        XCTAssertEqual(hiddenItem.propertyValue("item"), "ITEM_POTION")
        XCTAssertEqual(hiddenItem.propertyValue("flag"), "FLAG_NONE")
        XCTAssertEqual(session.mapEditOperations.suffix(4).map(\.action), [.addEvent, .addEvent, .addEvent, .addEvent])
    }

    @MainActor
    func testEventCapacityWarningsTrackStagedEventsWithoutBlockingInsertion() throws {
        let capacity = MapEventCapacitySummary(
            counts: MapEventCounts(objectEvents: 1),
            limits: MapEventCapacityLimits(
                objectEvents: 1,
                sources: [
                    MapEventCapacityLimits.Source(
                        kind: .object,
                        path: "include/constants/global.h",
                        symbol: "OBJECT_EVENT_TEMPLATES_COUNT",
                        detail: "Object map template capacity."
                    )
                ]
            ),
            mapSourcePath: "data/maps/Route1/map.json"
        )
        let session = MapEditorSession(document: makeDocument(eventCapacity: capacity))

        XCTAssertEqual(session.stagedMapEventCapacity.usages.first { $0.kind == .object }?.count, 1)
        XCTAssertTrue(session.addObjectEvent(atX: 0, y: 0))
        XCTAssertTrue(session.duplicateSelectedMapEvent())

        let usage = try XCTUnwrap(session.stagedMapEventCapacity.usages.first { $0.kind == .object })
        XCTAssertEqual(usage.count, 3)
        XCTAssertEqual(usage.limit, 1)
        XCTAssertTrue(usage.isOverLimit)

        let plan = try XCTUnwrap(session.previewSelectedMapMutationPlan())
        let diagnostic = try XCTUnwrap(plan.diagnostics.first { $0.code == "MAP_EVENT_CAPACITY_OVER_LIMIT" })
        XCTAssertEqual(diagnostic.severity, .warning)
        XCTAssertEqual(diagnostic.span?.relativePath, "data/maps/Route1/map.json")
        XCTAssertTrue(session.canApplySelectedMapMutationPlan)
    }

    @MainActor
    func testGraphicsIDFieldRefreshesStagedSpritePreview() throws {
        let replacementSprite = MapEventSpriteDescriptor(
            graphicsID: "OBJ_EVENT_GFX_GIRL_1",
            imageAssetPath: "graphics/object_events/pics/people/girl_1.png",
            frameWidth: 16,
            frameHeight: 32
        )
        let options = MapEventOptionsCatalog(
            objectGraphicsIDs: ["OBJ_EVENT_GFX_BOY_1", "OBJ_EVENT_GFX_GIRL_1"],
            objectSprites: [replacementSprite]
        )
        let session = MapEditorSession(document: makeDocument(eventOptions: options))

        session.selectMapEvent(id: "object-0")
        XCTAssertNil(session.selectedMapEvent?.sprite)
        XCTAssertTrue(session.updateSelectedMapEventProperty(key: "graphics_id", value: "OBJ_EVENT_GFX_GIRL_1"))

        XCTAssertEqual(session.selectedMapEvent?.propertyValue("graphics_id"), "OBJ_EVENT_GFX_GIRL_1")
        XCTAssertEqual(session.selectedMapEvent?.sprite?.graphicsID, "OBJ_EVENT_GFX_GIRL_1")
        XCTAssertEqual(session.selectedMapEvent?.sprite?.imageAssetPath, "graphics/object_events/pics/people/girl_1.png")
    }

    @MainActor
    func testHitTesterReturnsVisibleSameTileEventStack() throws {
        let document = makeDocument()
        let session = MapEditorSession(document: document)

        XCTAssertTrue(session.addMapEvent(template: .warp, atX: 1, y: 1))

        let hitTester = MapCanvasHitTester(
            size: MapCanvasSize(width: 2, height: 2),
            tileSize: 16,
            document: document,
            rawValues: session.stagedMapBlockdataValues,
            borderRawValues: document.border?.rawValues ?? [],
            events: session.stagedMapEvents,
            overlays: session.mapOverlaySettings
        )
        let hit = try XCTUnwrap(hitTester.hit(at: NSPoint(x: 17, y: 17)))

        XCTAssertEqual(hit.events.map(\.id), ["object-0", "warp-0"])
        XCTAssertEqual(hit.eventID, "warp-0")
        XCTAssertEqual(MapCanvasHoverStatus(hit: hit).eventStackCount, 2)

        session.setLayerVisible(.warps, isVisible: false)
        let filteredHitTester = MapCanvasHitTester(
            size: MapCanvasSize(width: 2, height: 2),
            tileSize: 16,
            document: document,
            rawValues: session.stagedMapBlockdataValues,
            borderRawValues: document.border?.rawValues ?? [],
            events: session.stagedMapEvents,
            overlays: session.mapOverlaySettings
        )
        let filteredHit = try XCTUnwrap(filteredHitTester.hit(at: NSPoint(x: 17, y: 17)))
        XCTAssertEqual(filteredHit.events.map(\.id), ["object-0"])
        XCTAssertEqual(MapCanvasHoverStatus(hit: filteredHit).eventStackCount, 1)
    }

    @MainActor
    func testEventRenderIndexCachesVisibleStacksAndSelectedScriptBadges() throws {
        let source = MapScriptSource(
            path: "data/maps/Route1/scripts.inc",
            role: .mapLocal,
            exists: true,
            text: "Route1_EventScript_NPC::\n\tend\n"
        )
        let scriptIndex = MapScriptIndex(
            rootPath: "/tmp/PokemonHackStudioTests",
            mapName: "Route1",
            sources: [source],
            labels: MapScriptIndexLoader.parseLabels(source: source)
        )
        let document = makeDocument(scriptIndex: scriptIndex)
        let session = MapEditorSession(document: document)

        XCTAssertTrue(session.addMapEvent(template: .warp, atX: 1, y: 1))

        let coordinate = MapCanvasCoordinate(x: 1, y: 1)
        let eventIndex = MapCanvasEventRenderIndex(
            events: session.stagedMapEvents,
            overlays: session.mapOverlaySettings,
            document: document,
            selectedEventID: "object-0"
        )
        let object = try XCTUnwrap(eventIndex.event(id: "object-0"))

        XCTAssertEqual(eventIndex.visibleEvents.map(\.id), ["object-0", "warp-0"])
        XCTAssertEqual(eventIndex.events(at: coordinate, target: .layout).map(\.id), ["object-0", "warp-0"])
        XCTAssertEqual(eventIndex.events(at: coordinate, target: .border), [])
        XCTAssertEqual(eventIndex.stackCount(for: object), 2)
        XCTAssertEqual(eventIndex.badge(for: object), "local x2")

        session.setLayerVisible(.warps, isVisible: false)
        let filteredIndex = MapCanvasEventRenderIndex(
            events: session.stagedMapEvents,
            overlays: session.mapOverlaySettings,
            document: document,
            selectedEventID: "object-0"
        )
        let filteredObject = try XCTUnwrap(filteredIndex.event(id: "object-0"))

        XCTAssertEqual(filteredIndex.visibleEvents.map(\.id), ["object-0"])
        XCTAssertEqual(filteredIndex.events(at: coordinate, target: .layout).map(\.id), ["object-0"])
        XCTAssertNil(filteredIndex.event(id: "warp-0"))
        XCTAssertEqual(filteredIndex.stackCount(for: filteredObject), 1)
        XCTAssertEqual(filteredIndex.badge(for: filteredObject), "local")
    }

    @MainActor
    func testCreateAndAssignScriptLabelPreviewUsesStagedLabelResolution() throws {
        let source = MapScriptSource(
            path: "data/maps/Route1/scripts.inc",
            role: .mapLocal,
            exists: true,
            text: ""
        )
        let scriptIndex = MapScriptIndex(
            rootPath: "/tmp/PokemonHackStudioTests",
            mapName: "Route1",
            sources: [source],
            labels: []
        )
        let session = MapEditorSession(document: makeDocument(scriptIndex: scriptIndex))

        session.selectMapEvent(id: "object-0")
        XCTAssertTrue(session.createScriptLabel(
            label: "Route1_EventScript_New",
            sourcePath: "data/maps/Route1/scripts.inc",
            body: "\tend"
        ))
        XCTAssertTrue(session.updateSelectedMapEventProperty(key: "script", value: "Route1_EventScript_New"))

        let plan = try XCTUnwrap(session.previewSelectedMapMutationPlan())
        XCTAssertTrue(plan.changes.first { $0.path == "data/maps/Route1/scripts.inc" }?.textPreview?.contains("Route1_EventScript_New::\n\tend") ?? false)
        XCTAssertTrue(plan.changes.first { $0.path == "data/maps/Route1/map.json" }?.textPreview?.contains(#""script": "Route1_EventScript_New""#) ?? false)
        XCTAssertFalse(plan.diagnostics.contains { $0.code == "MAP_EVENT_SCRIPT_UNRESOLVED" }, "\(plan.diagnostics.map(\.code))")
        XCTAssertTrue(session.canApplySelectedMapMutationPlan)
    }

    @MainActor
    func testScriptBodyEditsParticipateInUndoRedoAndPreview() throws {
        let source = MapScriptSource(
            path: "data/maps/Route1/scripts.inc",
            role: .mapLocal,
            exists: true,
            text: "Route1_EventScript_NPC::\n\tend\n"
        )
        let scriptIndex = MapScriptIndex(
            rootPath: "/tmp/PokemonHackStudioTests",
            mapName: "Route1",
            sources: [source],
            labels: MapScriptIndexLoader.parseLabels(source: source)
        )
        let session = MapEditorSession(document: makeDocument(scriptIndex: scriptIndex))

        XCTAssertTrue(session.updateScriptBody(
            label: "Route1_EventScript_NPC",
            sourcePath: "data/maps/Route1/scripts.inc",
            body: "\tmsgbox Route1_Text\n\tend"
        ))
        XCTAssertEqual(session.stagedScriptBody(label: "Route1_EventScript_NPC", sourcePath: "data/maps/Route1/scripts.inc"), "\tmsgbox Route1_Text\n\tend")
        XCTAssertEqual(session.mapEditOperations.map(\.action), [.updateScriptBody])

        session.undoLastMapEdit()
        XCTAssertNil(session.stagedScriptBody(label: "Route1_EventScript_NPC", sourcePath: "data/maps/Route1/scripts.inc"))
        XCTAssertFalse(session.isDirty)

        session.redoMapEdit()
        XCTAssertEqual(session.stagedScriptBody(label: "Route1_EventScript_NPC", sourcePath: "data/maps/Route1/scripts.inc"), "\tmsgbox Route1_Text\n\tend")
        let plan = try XCTUnwrap(session.previewSelectedMapMutationPlan())
        XCTAssertEqual(plan.changes.map(\.path), ["data/maps/Route1/scripts.inc"])
    }

    @MainActor
    func testNewScriptLabelBodyCanBeRestagedBeforePreview() throws {
        let source = MapScriptSource(
            path: "data/maps/Route1/scripts.inc",
            role: .mapLocal,
            exists: true,
            text: "Route1_EventScript_NPC::\n\tend\n"
        )
        let scriptIndex = MapScriptIndex(
            rootPath: "/tmp/PokemonHackStudioTests",
            mapName: "Route1",
            sources: [source],
            labels: []
        )
        let session = MapEditorSession(document: makeDocument(scriptIndex: scriptIndex))

        XCTAssertTrue(session.createScriptLabel(
            label: "Route1_EventScript_New",
            sourcePath: "data/maps/Route1/scripts.inc",
            body: "\tend"
        ))
        XCTAssertTrue(session.updateScriptBody(
            label: "Route1_EventScript_New",
            sourcePath: "data/maps/Route1/scripts.inc",
            body: "\tmsgbox Route1_Text\n\tend"
        ))

        let plan = try XCTUnwrap(session.previewSelectedMapMutationPlan())
        let script = try XCTUnwrap(plan.changes.first { $0.path == "data/maps/Route1/scripts.inc" }?.textPreview)
        XCTAssertTrue(script.contains("Route1_EventScript_New::\n\tmsgbox Route1_Text\n\tend"))
        XCTAssertEqual(script.components(separatedBy: "Route1_EventScript_New::").count, 2)
        XCTAssertTrue(plan.diagnostics.isEmpty, "\(plan.diagnostics.map(\.code))")
    }

    @MainActor
    func testScriptAuthoringHelperOutputStagesOnlyToMapLocalScriptBodies() throws {
        let localSource = MapScriptSource(
            path: "data/maps/Route1/scripts.inc",
            role: .mapLocal,
            exists: true,
            text: "Route1_EventScript_NPC::\n\tend\n"
        )
        let sharedSource = MapScriptSource(
            path: "data/maps/Shared/scripts.inc",
            role: .shared,
            exists: true,
            text: "Route1_EventScript_Shared::\n\tend\n"
        )
        let scriptIndex = MapScriptIndex(
            rootPath: "/tmp/PokemonHackStudioTests",
            mapName: "Route1",
            sources: [localSource, sharedSource],
            labels: MapScriptIndexLoader.parseLabels(source: localSource) + MapScriptIndexLoader.parseLabels(source: sharedSource)
        )
        let session = MapEditorSession(document: makeDocument(scriptIndex: scriptIndex))
        let helperPlan = ScriptAuthoringHelpers.movementListPlan(
            label: "Route1_EventScript_NPC",
            movements: ["walk_down"],
            sourcePath: "data/maps/Route1/scripts.inc"
        )

        XCTAssertTrue(session.stageMapLocalScriptHelperBody(
            label: helperPlan.label,
            sourcePath: "data/maps/Route1/scripts.inc",
            body: helperPlan.body
        ))
        XCTAssertEqual(session.stagedScriptBody(label: "Route1_EventScript_NPC", sourcePath: "data/maps/Route1/scripts.inc"), "\twalk_down\n\tstep_end")

        XCTAssertFalse(session.stageMapLocalScriptHelperBody(
            label: "Route1_EventScript_Shared",
            sourcePath: "data/maps/Shared/scripts.inc",
            body: "\twalk_left\n\tstep_end"
        ))

        let plan = try XCTUnwrap(session.previewSelectedMapMutationPlan())
        XCTAssertEqual(plan.changes.map(\.path), ["data/maps/Route1/scripts.inc"])
        XCTAssertTrue(plan.diagnostics.isEmpty, "\(plan.diagnostics.map(\.code))")
        XCTAssertTrue(session.canApplySelectedMapMutationPlan)
    }

    @MainActor
    func testPreviewGatingHelpers() throws {
        let session = MapEditorSession(document: makeDocument())

        XCTAssertNil(session.previewSelectedMapMutationPlan())
        XCTAssertFalse(session.canApplySelectedMapMutationPlan)
        XCTAssertEqual(session.applyBlockedReason, "Preview the staged edits before applying.")

        session.selectBrush(rawValue: 0x0099)
        XCTAssertTrue(session.paintMapCell(x: 0, y: 0))
        XCTAssertTrue(session.canPreviewSelectedMapMutationPlan)
        XCTAssertFalse(session.canApplySelectedMapMutationPlan)

        let plan = try XCTUnwrap(session.previewSelectedMapMutationPlan())
        XCTAssertFalse(session.canPreviewSelectedMapMutationPlan)
        XCTAssertEqual(session.previewBlockedReason, "The current edits already have a preview.")
        XCTAssertTrue(session.isLatestMapEditPlanCurrent)
        XCTAssertTrue(session.canApplySelectedMapMutationPlan)
        XCTAssertEqual(plan.mutationPlan.requiresExplicitApply, true)

        XCTAssertTrue(session.paintMapCell(x: 1, y: 1))
        XCTAssertNil(session.latestMapEditPlan)
        XCTAssertTrue(session.canPreviewSelectedMapMutationPlan)
        XCTAssertFalse(session.canApplySelectedMapMutationPlan)
        XCTAssertEqual(session.applyBlockedReason, "Preview the staged edits before applying.")
    }

    @MainActor
    func testLayerSettingsSoloOpacityAndReset() throws {
        let session = MapEditorSession(document: makeDocument())

        XCTAssertEqual(session.mapOverlaySettings.preset, .gameComposite)
        XCTAssertTrue(session.mapOverlaySettings.isLayerVisible(.metatileBottom))
        XCTAssertTrue(session.mapOverlaySettings.isLayerVisible(.metatileMiddle))
        XCTAssertTrue(session.mapOverlaySettings.isLayerVisible(.metatileTop))
        XCTAssertFalse(session.mapOverlaySettings.showCollision)
        XCTAssertTrue(session.mapOverlaySettings.showObjects)
        XCTAssertTrue(session.mapOverlaySettings.showWarps)
        XCTAssertTrue(session.mapOverlaySettings.showCoordEvents)
        XCTAssertTrue(session.mapOverlaySettings.showBGEvents)
        XCTAssertTrue(session.mapOverlaySettings.showBorder)
        XCTAssertTrue(session.mapOverlaySettings.showConnections)
        XCTAssertTrue(session.mapOverlaySettings.showPlayerView)

        session.setLayerVisible(.collision, isVisible: true)
        session.setLayerOpacity(.collision, opacity: 0.32)

        XCTAssertEqual(session.mapOverlaySettings.preset, .custom)
        XCTAssertTrue(session.mapOverlaySettings.showCollision)
        XCTAssertEqual(session.mapOverlaySettings.layerOpacity(.collision), 0.32, accuracy: 0.0001)

        session.toggleLayerSolo(.collision)

        XCTAssertEqual(session.mapOverlaySettings.soloLayer, .collision)
        XCTAssertTrue(session.mapOverlaySettings.showCollision)
        XCTAssertFalse(session.mapOverlaySettings.showObjects)
        XCTAssertFalse(session.mapOverlaySettings.hasVisibleMetatileLayer)

        session.resetLayerSettings()

        XCTAssertNil(session.mapOverlaySettings.soloLayer)
        XCTAssertEqual(session.mapOverlaySettings.preset, .gameComposite)
        XCTAssertTrue(session.mapOverlaySettings.showObjects)
        XCTAssertTrue(session.mapOverlaySettings.showWarps)
        XCTAssertTrue(session.mapOverlaySettings.showCoordEvents)
        XCTAssertTrue(session.mapOverlaySettings.showBGEvents)
        XCTAssertTrue(session.mapOverlaySettings.showBorder)
        XCTAssertTrue(session.mapOverlaySettings.showConnections)
        XCTAssertTrue(session.mapOverlaySettings.showPlayerView)
        XCTAssertFalse(session.mapOverlaySettings.showCollision)
        XCTAssertTrue(session.mapOverlaySettings.hasVisibleMetatileLayer)
    }

    @MainActor
    func testLayerPresetTransitionsAndCustomFallback() throws {
        let session = MapEditorSession(document: makeDocument())

        session.applyLayerPreset(.bottom)

        XCTAssertEqual(session.mapOverlaySettings.preset, .bottom)
        XCTAssertTrue(session.mapOverlaySettings.isLayerVisible(.metatileBottom))
        XCTAssertFalse(session.mapOverlaySettings.isLayerVisible(.metatileMiddle))
        XCTAssertFalse(session.mapOverlaySettings.isLayerVisible(.metatileTop))

        session.setLayerVisible(.metatileTop, isVisible: true)

        XCTAssertEqual(session.mapOverlaySettings.preset, .custom)
        XCTAssertTrue(session.mapOverlaySettings.isLayerVisible(.metatileTop))

        session.applyLayerPreset(.gameComposite)

        XCTAssertEqual(session.mapOverlaySettings.preset, .gameComposite)
        XCTAssertTrue(session.mapOverlaySettings.isLayerVisible(.metatileBottom))
        XCTAssertTrue(session.mapOverlaySettings.isLayerVisible(.metatileMiddle))
        XCTAssertTrue(session.mapOverlaySettings.isLayerVisible(.metatileTop))
    }

    func testPaletteAwareRendererHandlesTransparencyAndFilteredLayers() throws {
        let document = makeRenderDocument()
        let tileImage = IndexedTilesetImage(
            width: 16,
            height: 8,
            indices: syntheticTileIndices()
        )
        let renderer = MetatileSwatchRenderer(
            document: document,
            indexedTileImages: ["tiles.png": tileImage],
            paletteSets: [
                "gTileset_Test": [[
                    PaletteColor(red: 0, green: 0, blue: 0, alpha: 0),
                    PaletteColor(red: 255, green: 0, blue: 0),
                    PaletteColor(red: 0, green: 0, blue: 255)
                ]]
            ]
        )

        let middle = try XCTUnwrap(renderer.image(for: 0, layers: [.middle], opacities: [:]))
        XCTAssertEqual(pixel(in: middle, x: 0, y: 0), [0, 0, 0, 0])
        XCTAssertEqual(pixel(in: middle, x: 1, y: 0), [255, 0, 0, 255])

        let top = try XCTUnwrap(renderer.image(for: 0, layers: [.top], opacities: [:]))
        XCTAssertEqual(pixel(in: top, x: 0, y: 0), [0, 0, 255, 255])

        let bottom = try XCTUnwrap(renderer.image(for: 0, layers: [.bottom], opacities: [:]))
        XCTAssertEqual(pixel(in: bottom, x: 1, y: 0), [0, 0, 0, 0])
    }

    func testRendererResolvesMixedTileEntriesAcrossPrimaryAndSecondaryTilesets() throws {
        let document = makeMixedTilesetRenderDocument()
        let renderer = MetatileSwatchRenderer(
            document: document,
            indexedTileImages: [
                "primary.png": IndexedTilesetImage(width: 8, height: 8, indices: solidTileIndices(1)),
                "secondary.png": IndexedTilesetImage(width: 8, height: 8, indices: solidTileIndices(1))
            ],
            paletteSets: [
                "gTileset_Primary": [
                    [
                        PaletteColor(red: 0, green: 0, blue: 0, alpha: 0),
                        PaletteColor(red: 255, green: 0, blue: 0)
                    ]
                ],
                "gTileset_Secondary": [
                    [
                        PaletteColor(red: 0, green: 0, blue: 0, alpha: 0),
                        PaletteColor(red: 0, green: 0, blue: 255)
                    ]
                ]
            ]
        )

        let image = try XCTUnwrap(renderer.image(for: 2, layers: [.middle], opacities: [:]))
        XCTAssertEqual(pixel(in: image, x: 0, y: 0), [255, 0, 0, 255])
        XCTAssertEqual(pixel(in: image, x: 8, y: 0), [0, 0, 255, 255])
        XCTAssertEqual(pixel(in: image, x: 0, y: 8), [0, 0, 0, 0])
    }

    @MainActor
    func testEventSpriteRendererKeepsObjectSpritesUprightInFlippedCanvas() throws {
        let root = URL(fileURLWithPath: "/tmp/PokemonHackStudioTests")
        let relativeSpritePath = "graphics/object_events/pics/people/test-\(UUID().uuidString).png"
        let spritePath = root.appendingPathComponent(relativeSpritePath)
        try FileManager.default.createDirectory(at: spritePath.deletingLastPathComponent(), withIntermediateDirectories: true)
        try twoToneSpritePNGData().write(to: spritePath)
        defer {
            try? FileManager.default.removeItem(at: spritePath)
        }
        XCTAssertTrue(NSImage(contentsOfFile: spritePath.path)?.isValid == true)

        let sprite = MapEventSpriteDescriptor(
            graphicsID: "OBJ_EVENT_GFX_BOY_1",
            imageAssetPath: relativeSpritePath,
            frameWidth: 16,
            frameHeight: 16,
            width: 16,
            height: 16
        )
        let document = makeDocument(eventOptions: MapEventOptionsCatalog(objectSprites: [sprite]))
        let event: MapEventDescriptor = try XCTUnwrap(document.events.first)
        let image = try XCTUnwrap(NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 80,
            pixelsHigh: 80,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ))
        image.size = NSSize(width: 80, height: 80)
        let context = try XCTUnwrap(NSGraphicsContext(bitmapImageRep: image))

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.cgContext.clear(CGRect(x: 0, y: 0, width: 80, height: 80))
        context.cgContext.translateBy(x: 0, y: 80)
        context.cgContext.scaleBy(x: 1, y: -1)
        MapEventSpriteRenderer.drawEvent(
            event,
            document: document,
            tileRect: NSRect(x: 24, y: 24, width: 32, height: 32),
            tileSize: 32,
            opacity: 1,
            selected: false,
            fallbackColor: .systemBlue
        )
        NSGraphicsContext.restoreGraphicsState()

        let colorRows = spriteColorRows(in: image)

        XCTAssertFalse(colorRows.red.isEmpty)
        XCTAssertFalse(colorRows.blue.isEmpty)
        XCTAssertLessThan(colorRows.red.min() ?? .max, colorRows.blue.min() ?? .min)
    }

    func testIndexedPNGParserInflatesZlibWrappedIndexedRows() throws {
        let image = try XCTUnwrap(IndexedPNGParser.parse(data: Data(zlibWrappedIndexedPNGFixture())))

        XCTAssertEqual(image.width, 2)
        XCTAssertEqual(image.height, 2)
        XCTAssertEqual(image.indices, [1, 2, 3, 0])
    }

    func testFitZoomGeometryAllowsFullMapScale() throws {
        let fitted = MapViewportGeometry.fitZoom(
            mapWidth: 100,
            mapHeight: 80,
            viewportSize: CGSize(width: 400, height: 300)
        )

        XCTAssertEqual(fitted, 0.190625, accuracy: 0.0001)
        XCTAssertLessThan(fitted, MapViewportGeometry.minimumEditableZoom)
        XCTAssertEqual(
            MapViewportGeometry.fitZoom(mapWidth: 4, mapHeight: 4, viewportSize: CGSize(width: 2000, height: 2000)),
            MapViewportGeometry.maximumZoom,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            MapViewportGeometry.fitZoom(mapWidth: 0, mapHeight: 4, viewportSize: CGSize(width: 2000, height: 2000)),
            MapViewportGeometry.unitZoom,
            accuracy: 0.0001
        )
    }

    @MainActor
    func testSelectionPersistenceAcrossDiscardAndReload() throws {
        let document = makeDocument()
        let session = MapEditorSession(document: document)

        session.selectMapCell(x: 1, y: 1)
        session.selectMapEvent(id: "object-0")
        XCTAssertTrue(session.updateSelectedMapEventProperty(key: "script", value: "Route1_EventScript_New"))

        session.discardChanges()
        XCTAssertFalse(session.isDirty)
        XCTAssertEqual(session.selectedMapCell?.x, 1)
        XCTAssertEqual(session.selectedMapCell?.y, 1)
        XCTAssertEqual(session.selectedMapCell?.rawValue, 4)
        XCTAssertEqual(session.selectedMapEventID, "object-0")

        session.load(document: document)
        XCTAssertEqual(session.selectedMapCell?.x, 1)
        XCTAssertEqual(session.selectedMapCell?.y, 1)
        XCTAssertEqual(session.selectedMapEventID, "object-0")

        session.load(document: makeDocument(mapID: "MAP_ROUTE2", mapName: "Route2", blockdata: [5, 6, 7, 8]))
        XCTAssertNil(session.selectedMapCell)
        XCTAssertNil(session.selectedMapEventID)
        XCTAssertEqual(session.stagedMapBlockdataValues, [5, 6, 7, 8])
    }

    private func makeDocument(
        mapID: String = "MAP_ROUTE1",
        mapName: String = "Route1",
        blockdata: [UInt16] = [1, 2, 3, 4],
        scriptIndex: MapScriptIndex? = nil,
        eventOptions: MapEventOptionsCatalog = .empty,
        eventCapacity: MapEventCapacitySummary? = nil
    ) -> MapVisualDocument {
        let layout = LayoutSlot(
            slotIndex: 0,
            layoutID: "LAYOUT_\(mapName.uppercased())",
            name: "\(mapName)_Layout",
            width: 2,
            height: 2,
            borderWidth: 2,
            borderHeight: 2,
            primaryTileset: "gTileset_General",
            secondaryTileset: "gTileset_Route",
            borderFilepath: "data/layouts/\(mapName)/border.bin",
            blockdataFilepath: "data/layouts/\(mapName)/map.bin",
            sourcePath: "data/layouts/layouts.json"
        )
        let event = MapEventDescriptor(
            kind: .object,
            index: 0,
            x: 1,
            y: 1,
            elevation: 3,
            properties: [
                MapEventProperty(key: "local_id", value: "LOCALID_ROUTE_NPC"),
                MapEventProperty(key: "type", value: "object"),
                MapEventProperty(key: "graphics_id", value: "OBJ_EVENT_GFX_BOY_1"),
                MapEventProperty(key: "x", value: "1"),
                MapEventProperty(key: "y", value: "1"),
                MapEventProperty(key: "elevation", value: "3"),
                MapEventProperty(key: "script", value: "\(mapName)_EventScript_NPC")
            ],
            sprite: eventOptions.sprite(for: "OBJ_EVENT_GFX_BOY_1")
        )

        return MapVisualDocument(
            id: "/tmp/PokemonHackStudioTests:\(mapID)",
            rootPath: "/tmp/PokemonHackStudioTests",
            profile: .pokeemerald,
            mapID: mapID,
            mapName: mapName,
            mapSourcePath: "data/maps/\(mapName)/map.json",
            layout: layout,
            blockdata: EditableLayoutBlockdata(
                filepath: "data/layouts/\(mapName)/map.bin",
                width: 2,
                height: 2,
                rawValues: blockdata
            ),
            border: EditableLayoutBlockdata(
                filepath: "data/layouts/\(mapName)/border.bin",
                width: 2,
                height: 2,
                rawValues: [9, 10, 11, 12]
            ),
            primaryTileset: nil,
            secondaryTileset: nil,
            metatiles: [],
            events: [event],
            eventCapacity: eventCapacity,
            eventOptions: eventOptions,
            scriptIndex: scriptIndex,
            mapJSONText: mapJSONText(mapID: mapID, mapName: mapName)
        )
    }

    private func makeRenderDocument() -> MapVisualDocument {
        let layout = LayoutSlot(
            slotIndex: 0,
            layoutID: "LAYOUT_RENDER",
            name: "Render_Layout",
            width: 1,
            height: 1,
            borderWidth: 1,
            borderHeight: 1,
            primaryTileset: "gTileset_Test",
            secondaryTileset: nil,
            borderFilepath: nil,
            blockdataFilepath: "data/layouts/Render/map.bin",
            sourcePath: "data/layouts/layouts.json"
        )
        let asset = TilesetAsset(
            symbol: "gTileset_Test",
            isSecondary: false,
            tileImagePath: "tiles.png",
            palettePaths: [],
            metatilesPath: nil,
            metatileAttributesPath: nil,
            metatileCount: 1
        )
        let entries = (0..<8).map { index in
            MetatileTileEntry(index: index, rawValue: UInt16(index < 4 ? 0 : 1))
        }
        let metatile = MetatileDefinition(
            id: 0,
            localID: 0,
            tilesetSymbol: "gTileset_Test",
            tileEntries: entries,
            attribute: MetatileAttribute(rawValue: 0, wordSize: 2)
        )
        return MapVisualDocument(
            id: "/tmp/PokemonHackStudioTests:MAP_RENDER",
            rootPath: "/tmp/PokemonHackStudioTests",
            profile: .pokeemerald,
            mapID: "MAP_RENDER",
            mapName: "Render",
            mapSourcePath: "data/maps/Render/map.json",
            layout: layout,
            blockdata: EditableLayoutBlockdata(filepath: "data/layouts/Render/map.bin", width: 1, height: 1, rawValues: [0]),
            border: nil,
            primaryTileset: asset,
            secondaryTileset: nil,
            metatiles: [metatile],
            events: [],
            mapJSONText: "{}"
        )
    }

    private func makeMixedTilesetRenderDocument() -> MapVisualDocument {
        let layout = LayoutSlot(
            slotIndex: 0,
            layoutID: "LAYOUT_MIXED_RENDER",
            name: "MixedRender_Layout",
            width: 1,
            height: 1,
            borderWidth: 1,
            borderHeight: 1,
            primaryTileset: "gTileset_Primary",
            secondaryTileset: "gTileset_Secondary",
            borderFilepath: nil,
            blockdataFilepath: "data/layouts/MixedRender/map.bin",
            sourcePath: "data/layouts/layouts.json"
        )
        let primaryAsset = TilesetAsset(
            symbol: "gTileset_Primary",
            isSecondary: false,
            tileImagePath: "primary.png",
            palettePaths: [],
            metatilesPath: nil,
            metatileAttributesPath: nil,
            metatileCount: 1
        )
        let secondaryAsset = TilesetAsset(
            symbol: "gTileset_Secondary",
            isSecondary: true,
            tileImagePath: "secondary.png",
            palettePaths: [],
            metatilesPath: nil,
            metatileAttributesPath: nil,
            metatileCount: 1
        )
        let entries = [0, 2, 4, 2, 0, 0, 0, 0].enumerated().map { index, rawValue in
            MetatileTileEntry(index: index, rawValue: UInt16(rawValue))
        }
        let metatile = MetatileDefinition(
            id: 2,
            localID: 0,
            tilesetSymbol: "gTileset_Secondary",
            tileEntries: entries,
            attribute: MetatileAttribute(rawValue: 0, wordSize: 2)
        )
        return MapVisualDocument(
            id: "/tmp/PokemonHackStudioTests:MAP_MIXED_RENDER",
            rootPath: "/tmp/PokemonHackStudioTests",
            profile: .pokefirered,
            mapID: "MAP_MIXED_RENDER",
            mapName: "MixedRender",
            mapSourcePath: "data/maps/MixedRender/map.json",
            layout: layout,
            blockdata: EditableLayoutBlockdata(filepath: "data/layouts/MixedRender/map.bin", width: 1, height: 1, rawValues: [2]),
            border: nil,
            primaryTileset: primaryAsset,
            secondaryTileset: secondaryAsset,
            metatileLimits: MapMetatileLimits(primary: 2, total: 4),
            tileLimits: MapTileLimits(primary: 2, total: 4),
            metatiles: [metatile],
            events: [],
            mapJSONText: "{}"
        )
    }

    private func syntheticTileIndices() -> [UInt8] {
        var indices = [UInt8](repeating: 1, count: 16 * 8)
        indices[0] = 0
        for y in 0..<8 {
            for x in 8..<16 {
                indices[y * 16 + x] = 2
            }
        }
        return indices
    }

    private func solidTileIndices(_ paletteIndex: UInt8) -> [UInt8] {
        [UInt8](repeating: paletteIndex, count: 8 * 8)
    }

    private func twoToneSpritePNGData() throws -> Data {
        try XCTUnwrap(Data(base64Encoded: """
        iVBORw0KGgoAAAANSUhEUgAAABAAAAAQAgMAAABinRfyAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAAJUExURf8AAAAA/////xSXxWgAAAABYktHRAJmC3xkAAAAB3RJTUUH6gUMAhQA1BehtwAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNi0wNS0xMlQwMjoyMDowMCswMDowMHjRU2IAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjYtMDUtMTJUMDI6MjA6MDArMDA6MDAJjOveAAAAKHRFWHRkYXRlOnRpbWVzdGFtcAAyMDI2LTA1LTEyVDAyOjIwOjAwKzAwOjAwXpnKAQAAABBjYU52AAAAEAAAAAgAAAAAAAAAAFzpI24AAAAQSURBVAjXY2AgEoQCAREEANTQCqEa0kzlAAAAAElFTkSuQmCC
        """))
    }

    private func pixel(in image: NSImage, x: Int, y: Int) -> [Int] {
        guard let data = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: data)
        else {
            return []
        }
        var pixel = [Int](repeating: 0, count: 4)
        rep.getPixel(&pixel, atX: x, y: y)
        return Array(pixel.prefix(4))
    }

    private func spriteColorRows(in rep: NSBitmapImageRep) -> (red: [Int], blue: [Int]) {
        var red: Set<Int> = []
        var blue: Set<Int> = []
        var pixel = [Int](repeating: 0, count: 4)
        for y in 0..<rep.pixelsHigh {
            for x in 0..<rep.pixelsWide {
                rep.getPixel(&pixel, atX: x, y: y)
                if pixel[0] > 220, pixel[1] < 40, pixel[2] < 40, pixel[3] > 220 {
                    red.insert(y)
                } else if pixel[0] < 40, pixel[1] < 40, pixel[2] > 220, pixel[3] > 220 {
                    blue.insert(y)
                }
            }
        }
        return (red.sorted(), blue.sorted())
    }

    private func zlibWrappedIndexedPNGFixture() -> [UInt8] {
        [
            0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
            0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
            0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x02,
            0x04, 0x03, 0x00, 0x00, 0x00, 0x80, 0x98, 0x10,
            0x17, 0x00, 0x00, 0x00, 0x0c, 0x50, 0x4c, 0x54,
            0x45, 0x00, 0x00, 0x00, 0xff, 0x00, 0x00, 0x00,
            0xff, 0x00, 0x00, 0x00, 0xff, 0x9b, 0xc0, 0x13,
            0xdc, 0x00, 0x00, 0x00, 0x0c, 0x49, 0x44, 0x41,
            0x54, 0x78, 0x9c, 0x63, 0x10, 0x62, 0x30, 0x00,
            0x00, 0x00, 0x6a, 0x00, 0x43, 0xbd, 0xdf, 0xd3,
            0xdc, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e,
            0x44, 0xae, 0x42, 0x60, 0x82
        ]
    }

    private func mapJSONText(mapID: String, mapName: String) -> String {
        """
        {
          "id": "\(mapID)",
          "name": "\(mapName)",
          "layout": "LAYOUT_\(mapName.uppercased())",
          "music": "MUS_ROUTE",
          "region_map_section": "MAPSEC_ROUTE",
          "weather": "WEATHER_SUNNY",
          "map_type": "MAP_TYPE_ROUTE",
          "object_events": [
            {
              "local_id": "LOCALID_ROUTE_NPC",
              "type": "object",
              "graphics_id": "OBJ_EVENT_GFX_BOY_1",
              "x": 1,
              "y": 1,
              "elevation": 3,
              "script": "\(mapName)_EventScript_NPC"
            }
          ],
          "warp_events": [],
          "coord_events": [],
          "bg_events": [],
          "connections": []
        }
        """
    }
}
