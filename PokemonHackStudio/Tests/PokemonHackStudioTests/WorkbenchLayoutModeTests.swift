import CoreGraphics
import XCTest

final class WorkbenchLayoutModeTests: XCTestCase {
    func testContentWidthThresholdKeepsSmallSidebarWindowsCompact() {
        XCTAssertEqual(WorkbenchLayoutMode(contentWidth: 1_029), .compact)
        XCTAssertEqual(WorkbenchLayoutMode(contentWidth: 1_059), .compact)
        XCTAssertEqual(WorkbenchLayoutMode(contentWidth: 1_060), .wide)
        XCTAssertEqual(WorkbenchLayoutMode(contentWidth: 1_320), .wide)
    }

    func testCompactModeUsesTighterLayoutMetrics() {
        XCTAssertLessThan(WorkbenchLayoutMode.compact.contentPadding, WorkbenchLayoutMode.wide.contentPadding)
        XCTAssertLessThan(WorkbenchLayoutMode.compact.sectionSpacing, WorkbenchLayoutMode.wide.sectionSpacing)
        XCTAssertEqual(WorkbenchLayoutMode.compactPopoverWidth, 360)
        XCTAssertEqual(WorkbenchLayoutMode.compactPopoverHeight, 620)
    }

    func testWorkbenchModuleGroupsUseCreatorIntentOrder() {
        XCTAssertEqual(
            WorkbenchModuleGroup.allCases.map(\.rawValue),
            ["Workspace", "Create", "Data & Assets", "Ship"]
        )
        XCTAssertEqual(WorkbenchModuleGroup.workspace.modules, [.dashboard])
        XCTAssertEqual(WorkbenchModuleGroup.create.modules, [.maps, .pokemon, .trainers, .scripts])
        XCTAssertEqual(WorkbenchModuleGroup.dataAssets.modules, [.resources, .graphics, .items, .encounters, .text])
        XCTAssertEqual(WorkbenchModuleGroup.ship.modules, [.build, .issues])
    }
}
