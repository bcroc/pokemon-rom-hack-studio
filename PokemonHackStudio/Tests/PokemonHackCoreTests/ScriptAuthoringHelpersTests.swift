import XCTest
@testable import PokemonHackCore

final class ScriptAuthoringHelpersTests: XCTestCase {
    func testTextWrappingPreviewBuildsCleanRoomStringBody() {
        let preview = ScriptAuthoringHelpers.textWrappingPreview(
            label: "Route1_Text_Helper",
            text: "Hello there trainer this line should wrap before it becomes too wide.",
            maxLineLength: 18,
            sourcePath: "data/maps/Route1/scripts.inc"
        )

        XCTAssertEqual(preview.label, "Route1_Text_Helper")
        XCTAssertEqual(preview.maxLineLength, 18)
        XCTAssertEqual(preview.lines, ["Hello there", "trainer this line", "should wrap before", "it becomes too", "wide."])
        XCTAssertEqual(
            preview.bodyPreview,
            """
            Route1_Text_Helper::
            \t.string "Hello there\\ntrainer this line\\nshould wrap before\\nit becomes too\\nwide.$"
            """
        )
        XCTAssertTrue(preview.diagnostics.isEmpty, "\(preview.diagnostics.map(\.code))")
    }

    func testMovementListPlanAppendsStepEnd() {
        let plan = ScriptAuthoringHelpers.movementListPlan(
            label: "Route1_Movement_Helper",
            movements: ["walk_down", "walk_left"],
            sourcePath: "data/maps/Route1/scripts.inc"
        )

        XCTAssertEqual(plan.body, "\twalk_down\n\twalk_left\n\tstep_end")
        XCTAssertTrue(plan.diagnostics.isEmpty, "\(plan.diagnostics.map(\.code))")
    }

    func testMartItemListPlanUsesItemNoneSentinel() {
        let plan = ScriptAuthoringHelpers.martItemListPlan(
            label: "Route1_Mart_Items",
            items: ["ITEM_POTION", "ITEM_ANTIDOTE", "ITEM_NONE"],
            sourcePath: "data/maps/Route1/scripts.inc"
        )

        XCTAssertEqual(plan.body, "\t.2byte ITEM_POTION\n\t.2byte ITEM_ANTIDOTE\n\t.2byte ITEM_NONE")
        XCTAssertTrue(plan.diagnostics.isEmpty, "\(plan.diagnostics.map(\.code))")
    }

    func testMapScriptScaffoldValidationChecksArityTargetsTerminatorAndMarkers() {
        let validation = ScriptAuthoringHelpers.validateMapScriptScaffold(
            label: "Route1_MapScripts",
            body: """
            #line 10 "Route1.pory"
            map_script MAP_SCRIPT_ON_TRANSITION
            map_script MAP_SCRIPT_ON_FRAME_TABLE, Route1_EventScript_Missing
            """,
            existingLabels: ["Route1_MapScripts"],
            sourcePath: "data/maps/Route1/scripts.inc"
        )

        XCTAssertEqual(validation.referencedLabels, ["Route1_EventScript_Missing"])
        XCTAssertTrue(validation.diagnostics.contains { $0.code == "SCRIPT_LINE_MARKER_PRESENT" })
        XCTAssertTrue(validation.diagnostics.contains { $0.code == "SCRIPT_MAPSCRIPT_ARITY" })
        XCTAssertTrue(validation.diagnostics.contains { $0.code == "SCRIPT_MAPSCRIPT_TARGET_MISSING" })
        XCTAssertTrue(validation.diagnostics.contains { $0.code == "SCRIPT_MAPSCRIPT_TERMINATOR_MISSING" })
    }

    func testLineMarkerAndPoryswitchDiagnosticsAreAwarenessOnly() {
        let diagnostics = ScriptAuthoringHelpers.lineMarkerAndPoryswitchDiagnostics(
            body: """
            #ifdef REVISION
            poryswitch(VERSION) {
            }
            #endif
            """,
            sourcePath: "data/maps/Route1/scripts.inc"
        )

        XCTAssertTrue(diagnostics.contains { $0.code == "SCRIPT_CONDITIONAL_MARKER_PRESENT" })
        XCTAssertTrue(diagnostics.contains { $0.code == "SCRIPT_PORYSWITCH_PRESENT" })
        XCTAssertFalse(diagnostics.contains { $0.severity == .error })
    }

    func testHelperStagingValidationBlocksSharedGeneratedAndMissingSources() {
        let shared = ScriptAuthoringHelpers.validateMapLocalHelperStaging(
            label: "Route1_EventScript_Helper",
            sourcePath: "data/maps/Shared/scripts.inc",
            sourceRole: .shared,
            sourceExists: true
        )
        XCTAssertTrue(shared.contains { $0.code == "SCRIPT_HELPER_SOURCE_SHARED" && $0.severity == .error })

        let generated = ScriptAuthoringHelpers.validateMapLocalHelperStaging(
            label: "Route1_EventScript_Helper",
            sourcePath: "data/maps/Route1/events.inc",
            sourceRole: .mapLocal,
            sourceExists: true
        )
        XCTAssertTrue(generated.contains { $0.code == "SCRIPT_HELPER_SOURCE_UNSUPPORTED" && $0.severity == .error })

        let missing = ScriptAuthoringHelpers.validateMapLocalHelperStaging(
            label: "Route1_EventScript_Helper",
            sourcePath: "data/maps/Route1/scripts.inc",
            sourceRole: .mapLocal,
            sourceExists: false
        )
        XCTAssertTrue(missing.contains { $0.code == "SCRIPT_HELPER_SOURCE_MISSING" && $0.severity == .error })
    }
}
