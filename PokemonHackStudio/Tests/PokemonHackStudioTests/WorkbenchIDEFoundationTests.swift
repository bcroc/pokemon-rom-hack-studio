import Foundation
import XCTest

final class WorkbenchIDEFoundationTests: XCTestCase {
    func testProjectWritePolicyClassifiesEditableReferenceROMAndFixtureProjects() {
        let editable = ProjectWritePolicy.policy(originLabel: "Editable", rawWritePolicy: "editable")
        XCTAssertEqual(editable.kind, .editableSource)
        XCTAssertTrue(editable.isWritable)
        XCTAssertEqual(editable.title, "Editable source")

        let reference = ProjectWritePolicy.policy(originLabel: "Reference", rawWritePolicy: "readOnly")
        XCTAssertEqual(reference.kind, .reference)
        XCTAssertFalse(reference.isWritable)

        let romInput = ProjectWritePolicy.policy(originLabel: "Local Input", rawWritePolicy: "readOnly")
        XCTAssertEqual(romInput.kind, .romInput)
        XCTAssertEqual(romInput.title, "Read-only ROM input")

        let fixture = ProjectIdentity.fixture(title: "Emerald Dev")
        XCTAssertEqual(fixture.kind, .fixtureDev)
        XCTAssertEqual(fixture.writePolicy.title, "Read-only fixture")
        XCTAssertFalse(fixture.isWritable)
    }

    func testValidationTiersExposeRepeatableCommands() {
        XCTAssertEqual(
            ValidationTier.allCases.map(\.command),
            [
                "make validate-synthetic",
                "make validate-gba-fixtures",
                "make validate-nds-strict",
                "make validate-gui-smoke",
                "make validate-release-candidate"
            ]
        )
    }

    @MainActor
    func testFixtureStoreExposesNoProjectIdentityAndOpenProjectRequest() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "WorkbenchIDEFoundationTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        XCTAssertEqual(store.selectedProjectIdentity.kind, .fixtureDev)
        XCTAssertEqual(store.selectedProjectIdentity.writePolicy.title, "Read-only fixture")
        XCTAssertNil(store.openProjectPanelRequestID)

        store.requestOpenProjectPanel()
        XCTAssertNotNil(store.openProjectPanelRequestID)

        store.clearOpenProjectPanelRequest()
        XCTAssertNil(store.openProjectPanelRequestID)
    }

    @MainActor
    func testCurrentEditorSessionMirrorsToolbarMutationState() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "WorkbenchIDEFoundationTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.selectWorkbenchModule(.dashboard)
        XCTAssertEqual(store.currentModuleEditorSession.module, .dashboard)
        XCTAssertEqual(store.currentModuleEditorSession.stage, .browse)
        XCTAssertEqual(store.currentModuleEditorSession.selectedObjectTitle, store.selectedTarget.name)

        store.selectWorkbenchModule(.pokemon)
        XCTAssertEqual(store.currentModuleEditorSession.module, .pokemon)
        XCTAssertFalse(store.currentModuleEditorSession.canPreview)
        XCTAssertFalse(store.currentModuleEditorSession.canApply)
        XCTAssertFalse(store.currentModuleEditorSession.nextActionTitle.isEmpty)
    }

    func testDiagnosticBucketsStayAvailableForRouting() {
        let generated = IndexedDiagnosticRow(
            id: "generated",
            title: "GENERATED_ARTIFACT_MISSING",
            message: "Build output is missing",
            severity: .warning,
            source: SourceLocation(path: "build/pokeemerald.gba", symbol: "Generated", line: 1)
        )
        XCTAssertEqual(DiagnosticSummary.bucket(for: generated), .generatedArtifacts)

        let toolchain = IndexedDiagnosticRow(
            id: "toolchain",
            title: "TOOLCHAIN_MISSING",
            message: "Compiler missing",
            severity: .warning,
            source: SourceLocation(path: "Makefile", symbol: "Toolchain", line: 1)
        )
        XCTAssertEqual(DiagnosticSummary.bucket(for: toolchain), .healthToolchain)

        let blocking = IndexedDiagnosticRow(
            id: "blocking",
            title: "SOURCE_ERROR",
            message: "Unsupported source shape",
            severity: .error,
            source: SourceLocation(path: "src/data/example.c", symbol: "Example", line: 12)
        )
        XCTAssertEqual(DiagnosticSummary.bucket(for: blocking), .blockingErrors)
    }
}
