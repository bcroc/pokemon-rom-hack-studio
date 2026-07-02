import AppKit
import Foundation
import PokemonHackCore
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
                "make validate-nds",
                "make validate-nds-strict",
                "make validate-gui-smoke",
                "make validate-release-candidate"
            ]
        )
    }

    @MainActor
    func testValidationTierCommandRowsReportStrictnessSkippedCausesAndExactCommands() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "WorkbenchIDEFoundationTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)
        let rows = store.validationTierCommandRows

        XCTAssertEqual(rows.map(\.command), ValidationTier.allCases.map(\.command))
        XCTAssertEqual(rows.map(\.title), ValidationTier.allCases.map(\.title))
        XCTAssertEqual(rows.map(\.copyValue), ValidationTier.allCases.map(\.command))
        XCTAssertTrue(rows.allSatisfy(\.canCopyCommand))
        XCTAssertTrue(rows.allSatisfy { !$0.canRunInApp })
        XCTAssertTrue(rows.allSatisfy { $0.runStateTitle == "Run manually" })
        XCTAssertTrue(rows.allSatisfy { $0.disabledReason.contains("copy-only") })
        XCTAssertTrue(rows.allSatisfy { $0.disabledReason.contains("repository root") })
        XCTAssertTrue(rows.allSatisfy { !$0.strictnessTitle.isEmpty })
        XCTAssertTrue(rows.allSatisfy { !$0.strictnessDetail.isEmpty })

        let optionalNDS = try XCTUnwrap(rows.first { $0.tier == .ndsSyntheticAndOptionalReferences })
        XCTAssertEqual(optionalNDS.command, "make validate-nds")
        XCTAssertEqual(optionalNDS.copyValue, "make validate-nds")
        XCTAssertEqual(optionalNDS.strictnessTitle, "Optional central NDS references")
        XCTAssertEqual(optionalNDS.skippedReferenceCauses.count, 4)
        XCTAssertTrue(optionalNDS.skippedReferenceCauses.allSatisfy { $0.behavior == .skippedWhenMissing })
        XCTAssertTrue(optionalNDS.skippedReferenceCauseSummary.contains("pret__pokeplatinum"))

        let strictGBA = try XCTUnwrap(rows.first { $0.tier == .localGBAFixtures })
        XCTAssertTrue(strictGBA.skippedReferenceCauses.allSatisfy { $0.behavior == .failsWhenMissing })
        XCTAssertTrue(strictGBA.skippedReferenceCauses.contains { $0.overrideEnvironmentVariables.contains("GBA_FIXTURE_ROOT") })
    }

    @MainActor
    func testValidationTierCommandCopyWritesExactCommand() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "WorkbenchIDEFoundationTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)
        let synthetic = try XCTUnwrap(store.validationTierCommandRows.first { $0.tier == .synthetic })

        NSPasteboard.general.clearContents()
        store.copyValidationTierCommandToPasteboard(synthetic)

        XCTAssertEqual(NSPasteboard.general.string(forType: .string), "make validate-synthetic")
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

    @MainActor
    func testUniversalIDENavigatorGroupsCoreSurfaces() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "WorkbenchIDEFoundationTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)
        let nodes = store.workbenchNavigatorNodes

        XCTAssertEqual(nodes.map(\.title), WorkbenchNavigatorGroup.allCases.map(\.rawValue))

        let visual = try XCTUnwrap(nodes.first { $0.id == WorkbenchNavigatorGroup.visual.id })
        XCTAssertEqual(visual.children.map(\.module), [.maps, .graphics])

        let data = try XCTUnwrap(nodes.first { $0.id == WorkbenchNavigatorGroup.data.id })
        XCTAssertTrue(data.children.contains { $0.module == .pokemon })
        XCTAssertTrue(data.children.contains { $0.module == .trainers })
        XCTAssertTrue(data.children.contains { $0.module == .moves })
        XCTAssertTrue(data.children.contains { $0.module == .items })
        XCTAssertTrue(data.children.contains { $0.module == .encounters })
        XCTAssertTrue(data.children.contains { $0.module == .scripts })
        XCTAssertTrue(data.children.contains { $0.module == .text })

        let assets = try XCTUnwrap(nodes.first { $0.id == WorkbenchNavigatorGroup.assets.id })
        XCTAssertTrue(assets.children.contains { $0.module == .resources })
        XCTAssertTrue(assets.children.contains { $0.title == "Artifacts" && $0.module == .build })

        let ship = try XCTUnwrap(nodes.first { $0.id == WorkbenchNavigatorGroup.ship.id })
        XCTAssertEqual(ship.children.first?.module, .build)

        let romInputs = try XCTUnwrap(nodes.first { $0.id == WorkbenchNavigatorGroup.romInputs.id })
        XCTAssertEqual(romInputs.children.first?.module, .resources)
        XCTAssertEqual(romInputs.children.first?.title, "No ROM inputs")

        let references = try XCTUnwrap(nodes.first { $0.id == WorkbenchNavigatorGroup.references.id })
        XCTAssertEqual(references.children.first?.module, .resources)
    }

    @MainActor
    func testUniversalIDETabsAndPanelsPersistBackwardCompatibly() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "WorkbenchIDEFoundationTests.\(UUID().uuidString)"))
        var store: WorkbenchStore? = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store?.selectWorkbenchModule(.build)
        store?.openEditorTab(for: .resources, targetID: "rom-input.gba", activate: true)
        store?.navigatorSelectionID = "rom-input:demo"
        store?.expandedNavigatorNodeIDs = [WorkbenchNavigatorGroup.visual.id, WorkbenchNavigatorGroup.romInputs.id]
        store?.inspectorMode = .artifacts
        store?.bottomPanelMode = .playtest
        store?.bottomPanelHeight = 286
        store?.recentCommandIDs = ["module:maps", "validation:synthetic"]
        store?.activityCategoryFilter = .playtest

        store = nil

        let restored = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)
        let resourceROMTabID = "\(WorkbenchModule.resources.id)::rom-input.gba"
        XCTAssertTrue(restored.editorTabs.contains { $0.id == resourceROMTabID })
        XCTAssertEqual(restored.activeEditorTabID, resourceROMTabID)
        XCTAssertEqual(restored.selection, .resources)
        XCTAssertEqual(restored.navigatorSelectionID, "rom-input:demo")
        XCTAssertEqual(restored.expandedNavigatorNodeIDs, [WorkbenchNavigatorGroup.visual.id, WorkbenchNavigatorGroup.romInputs.id])
        XCTAssertEqual(restored.inspectorMode, .artifacts)
        XCTAssertEqual(restored.bottomPanelMode, .playtest)
        XCTAssertEqual(restored.bottomPanelHeight, 286)
        XCTAssertEqual(restored.recentCommandIDs, ["module:maps", "validation:synthetic"])
        XCTAssertEqual(restored.activityCategoryFilter, .playtest)
    }

    @MainActor
    func testUniversalIDEInspectorModeFollowsActiveEditorCategory() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "WorkbenchIDEFoundationTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        XCTAssertEqual(store.selection, .maps)
        XCTAssertEqual(store.inspectorMode, .selection)

        store.selectWorkbenchModule(.build)
        XCTAssertEqual(store.inspectorMode, .artifacts)

        store.selectWorkbenchModule(.issues)
        XCTAssertEqual(store.inspectorMode, .diagnostics)

        store.selectWorkbenchModule(.dashboard)
        XCTAssertEqual(store.inspectorMode, .source)

        store.selectWorkbenchModule(.pokemon)
        XCTAssertEqual(store.inspectorMode, .selection)
    }

    @MainActor
    func testUniversalIDECommandPaletteAvailabilityAndRoutingStayGuarded() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "WorkbenchIDEFoundationTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        let commands = store.workbenchCommands
        let maps = try XCTUnwrap(commands.first { $0.id == "module:\(WorkbenchModule.maps.id)" })
        XCTAssertTrue(maps.availability.isEnabled)

        store.executeCommand(maps)
        XCTAssertEqual(store.selection, .maps)
        XCTAssertEqual(store.activeEditorTabID, WorkbenchModule.maps.id)
        XCTAssertEqual(store.recentCommandIDs.first, maps.id)

        let validation = try XCTUnwrap(store.workbenchCommands.first { $0.id == "validation:\(ValidationTier.synthetic.id)" })
        XCTAssertTrue(validation.availability.isEnabled)
        XCTAssertEqual(validation.scope, "Validation")
        XCTAssertEqual(validation.action, .copyValidationCommand("make validate-synthetic"))

        NSPasteboard.general.clearContents()
        store.executeCommand(validation)
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), "make validate-synthetic")

        let ndsValidation = try XCTUnwrap(store.workbenchCommands.first { $0.id == "validation:\(ValidationTier.ndsSyntheticAndOptionalReferences.id)" })
        XCTAssertEqual(ndsValidation.action, .copyValidationCommand("make validate-nds"))
        XCTAssertTrue(ndsValidation.availability.isEnabled)
        XCTAssertTrue(store.validationTierCommandRows.first { $0.tier == .ndsSyntheticAndOptionalReferences }?.canRunInApp == false)

        let mutationApply = try XCTUnwrap(store.workbenchCommands.first { $0.id == "mutation:apply" })
        XCTAssertFalse(mutationApply.availability.isEnabled)
        XCTAssertTrue(mutationApply.availability.isGuarded)
        XCTAssertEqual(mutationApply.availability.disabledReason, "Preview the staged edits before applying.")

        let buildRun = try XCTUnwrap(store.workbenchCommands.first { $0.id == "build:run" })
        XCTAssertTrue(buildRun.availability.isGuarded)

        let patchDistribution = try XCTUnwrap(store.workbenchCommands.first { $0.id == "copy:patch-distribution-readiness-json" })
        XCTAssertEqual(patchDistribution.scope, "Copy")
        XCTAssertEqual(patchDistribution.action, .copyPatchDistributionReadinessJSON)
        XCTAssertFalse(patchDistribution.availability.isEnabled)
        XCTAssertEqual(patchDistribution.availability.disabledReason, "Refresh patch distribution readiness before copying JSON.")

        let binaryAudit = try XCTUnwrap(store.workbenchCommands.first { $0.id == "copy:binary-rom-mutation-apply-audit-json" })
        XCTAssertEqual(binaryAudit.scope, "Copy")
        XCTAssertEqual(binaryAudit.action, .copyBinaryROMMutationApplyAuditJSON)
        XCTAssertFalse(binaryAudit.availability.isEnabled)
        XCTAssertEqual(binaryAudit.availability.disabledReason, "Load a binary mutation review before copying audit JSON.")

        let resourceReadiness = try XCTUnwrap(store.workbenchCommands.first { $0.id == "copy:resource-readiness-packet-json" })
        XCTAssertEqual(resourceReadiness.scope, "Copy")
        XCTAssertEqual(resourceReadiness.action, .copySelectedResourceReadinessPacketJSON)
        XCTAssertFalse(resourceReadiness.availability.isEnabled)
        XCTAssertEqual(resourceReadiness.availability.disabledReason, "Load the Resources asset catalog before copying readiness packet JSON.")

        NSPasteboard.general.clearContents()
        let recentCommands = store.recentCommandIDs
        store.executeCommand(patchDistribution)
        XCTAssertNil(NSPasteboard.general.string(forType: .string))
        XCTAssertEqual(store.recentCommandIDs, recentCommands)
    }

    @MainActor
    func testUniversalIDECommandPaletteSearchAndPresentationState() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "WorkbenchIDEFoundationTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        store.showCommandPalette()
        XCTAssertTrue(store.commandPaletteState.isPresented)
        XCTAssertNotNil(store.commandPaletteState.selectedCommandID)

        store.commandPaletteState.searchText = "playtest"
        XCTAssertTrue(store.filteredWorkbenchCommands.allSatisfy { $0.searchBlob.contains("playtest") })
        XCTAssertTrue(store.filteredWorkbenchCommands.contains { $0.id == "playtest:open" })

        store.hideCommandPalette()
        XCTAssertFalse(store.commandPaletteState.isPresented)
        XCTAssertEqual(store.commandPaletteState.searchText, "")
        XCTAssertNil(store.commandPaletteState.selectedCommandID)
    }

    @MainActor
    func testUniversalIDEActivityConsoleAggregatesAndFiltersStoreEvents() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "WorkbenchIDEFoundationTests.\(UUID().uuidString)"))
        let store = WorkbenchStore(userDefaults: defaults, autoLoadProjects: false)

        XCTAssertTrue(store.currentIDEActivityEvents.contains { $0.category == .diagnostics })

        store.activityCategoryFilter = .diagnostics
        XCTAssertFalse(store.currentIDEActivityEvents.isEmpty)
        XCTAssertTrue(store.currentIDEActivityEvents.allSatisfy { $0.category == .diagnostics })

        store.bottomPanelMode = .buildLogs
        XCTAssertTrue(store.visibleIDEActivityEvents.allSatisfy { $0.category == .build })

        store.bottomPanelMode = .artifacts
        XCTAssertTrue(store.visibleIDEActivityEvents.allSatisfy { $0.category == .patch || $0.category == .resources })
    }
}
