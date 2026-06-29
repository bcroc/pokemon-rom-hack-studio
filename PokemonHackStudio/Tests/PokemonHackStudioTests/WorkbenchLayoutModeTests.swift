import CoreGraphics
import XCTest

final class WorkbenchLayoutModeTests: XCTestCase {
    func testContentWidthThresholdKeepsSmallSidebarWindowsCompact() {
        XCTAssertEqual(WorkbenchLayoutMode(contentWidth: 1029), .compact)
        XCTAssertEqual(WorkbenchLayoutMode(contentWidth: 1059), .compact)
        XCTAssertEqual(WorkbenchLayoutMode(contentWidth: 1060), .wide)
        XCTAssertEqual(WorkbenchLayoutMode(contentWidth: 1320), .wide)
    }

    func testCompactModeUsesTighterLayoutMetrics() {
        XCTAssertLessThan(WorkbenchLayoutMode.compact.contentPadding, WorkbenchLayoutMode.wide.contentPadding)
        XCTAssertLessThan(WorkbenchLayoutMode.compact.sectionSpacing, WorkbenchLayoutMode.wide.sectionSpacing)
        XCTAssertEqual(WorkbenchLayoutMode.compactPopoverWidth, 360)
        XCTAssertEqual(WorkbenchLayoutMode.compactPopoverHeight, 620)
    }

    func testMapEditorCompactBreakpointMatchesPalettePopoverPath() {
        XCTAssertEqual(MapEditorLayoutMode(width: 1179), .compact)
        XCTAssertEqual(MapEditorLayoutMode(width: 1180), .wide)
    }

    func testSidebarModesUseGuidedDisclosureOrder() {
        XCTAssertEqual(WorkbenchSidebarMode.allCases, [.browse, .tools, .properties])
        XCTAssertEqual(WorkbenchSidebarMode.browse.systemImage, "list.bullet")
        XCTAssertEqual(WorkbenchSidebarMode.tools.systemImage, "wrench.and.screwdriver")
        XCTAssertEqual(WorkbenchSidebarMode.properties.systemImage, "info.circle")
    }

    func testWorkbenchModuleGroupsUseCreatorIntentOrder() {
        XCTAssertEqual(
            WorkbenchModuleGroup.allCases.map(\.rawValue),
            ["Workspace", "Create", "Data & Assets", "Ship"]
        )
        XCTAssertEqual(WorkbenchModuleGroup.workspace.modules, [.dashboard])
        XCTAssertEqual(WorkbenchModuleGroup.create.modules, [.maps, .pokemon, .trainers, .scripts])
        XCTAssertEqual(WorkbenchModuleGroup.dataAssets.modules, [.resources, .graphics, .moves, .items, .encounters, .text])
        XCTAssertEqual(WorkbenchModuleGroup.ship.modules, [.build, .issues])
    }
}
