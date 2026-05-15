import XCTest
@testable import PokemonHackCore

final class ScriptCommandEditingTests: XCTestCase {
    func testCommandEditPlansAndAppliesOneArgumentWithBackup() throws {
        let root = try makeTemporaryProjectRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let path = "data/maps/Route1/scripts.inc"
        try write(
            """
            Route1_EventScript_Test::
                msgbox Route1_Text_Hello, MSGBOX_DEFAULT @ keep this comment
                end
            """,
            to: root.appendingPathComponent(path)
        )

        let draft = ScriptCommandEditDraft(
            sourcePath: path,
            line: 2,
            commandName: "msgbox",
            argumentIndex: 1,
            replacementArgument: "MSGBOX_YESNO"
        )
        let plan = ScriptCommandEditPlanner.plan(rootPath: root.path, draft: draft)

        XCTAssertTrue(plan.isApplyable, "\(plan.diagnostics.map(\.code))")
        XCTAssertEqual(plan.changes.count, 1)
        XCTAssertEqual(plan.changes.first?.textPreview, "    msgbox Route1_Text_Hello, MSGBOX_YESNO @ keep this comment")
        XCTAssertFalse(plan.diagnostics.contains { $0.severity == .error })

        let result = try ScriptCommandEditApplier.apply(plan: plan)
        XCTAssertEqual(result.appliedChanges.map(\.path), [path])
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedChanges[0].backupPath))
        let edited = try String(contentsOf: root.appendingPathComponent(path), encoding: .utf8)
        XCTAssertTrue(edited.contains("msgbox Route1_Text_Hello, MSGBOX_YESNO @ keep this comment"))
    }

    func testCommandEditBlocksInsertDeleteAndWholeBodyReplacement() throws {
        let root = try makeTemporaryProjectRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let path = "data/maps/Route1/scripts.inc"
        try write(
            """
            Route1_EventScript_Test::
                lock
                end
            """,
            to: root.appendingPathComponent(path)
        )

        let missingArgumentPlan = ScriptCommandEditPlanner.plan(
            rootPath: root.path,
            draft: ScriptCommandEditDraft(
                sourcePath: path,
                line: 2,
                commandName: "lock",
                argumentIndex: 0,
                replacementArgument: "EVENT_FLAG"
            )
        )
        XCTAssertFalse(missingArgumentPlan.isApplyable)
        XCTAssertTrue(missingArgumentPlan.diagnostics.contains { $0.code == "SCRIPT_COMMAND_EDIT_ARGUMENT_MISSING" })

        let bodyReplacementPlan = ScriptCommandEditPlanner.plan(
            rootPath: root.path,
            draft: ScriptCommandEditDraft(
                sourcePath: path,
                line: 1,
                argumentIndex: 0,
                replacementArgument: "Different_Label::"
            )
        )
        XCTAssertFalse(bodyReplacementPlan.isApplyable)
        XCTAssertTrue(bodyReplacementPlan.diagnostics.contains { $0.code == "SCRIPT_COMMAND_EDIT_UNSUPPORTED_LINE" })
    }

    func testCommandEditBlocksSharedAndGeneratedIncPaths() throws {
        let root = try makeTemporaryProjectRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let sharedPath = "data/scripts/shared.inc"
        let generatedPath = "data/maps/Route1/header.inc"
        try write("    msgbox Shared_Text, MSGBOX_DEFAULT\n", to: root.appendingPathComponent(sharedPath))
        try write("    msgbox Route1_Text, MSGBOX_DEFAULT\n", to: root.appendingPathComponent(generatedPath))

        let sharedPlan = ScriptCommandEditPlanner.plan(
            rootPath: root.path,
            draft: ScriptCommandEditDraft(
                sourcePath: sharedPath,
                line: 1,
                commandName: "msgbox",
                argumentIndex: 1,
                replacementArgument: "MSGBOX_YESNO"
            )
        )
        XCTAssertFalse(sharedPlan.isApplyable)
        XCTAssertTrue(sharedPlan.changes.isEmpty)
        XCTAssertTrue(sharedPlan.diagnostics.contains { $0.code == "SCRIPT_COMMAND_EDIT_SHARED_SOURCE_BLOCKED" })

        let generatedPlan = ScriptCommandEditPlanner.plan(
            rootPath: root.path,
            draft: ScriptCommandEditDraft(
                sourcePath: generatedPath,
                line: 1,
                commandName: "msgbox",
                argumentIndex: 1,
                replacementArgument: "MSGBOX_YESNO"
            )
        )
        XCTAssertFalse(generatedPlan.isApplyable)
        XCTAssertTrue(generatedPlan.changes.isEmpty)
        XCTAssertTrue(generatedPlan.diagnostics.contains { $0.code == "SCRIPT_COMMAND_EDIT_GENERATED_SOURCE_BLOCKED" })
    }

    func testCommandEditBlocksPoryscriptGeneratedInc() throws {
        let root = try makeTemporaryProjectRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let path = "data/maps/Route1/scripts.inc"
        try write(
            """
            #line 8 "data/maps/Route1/scripts.pory"
                msgbox Route1_Text_Hello, MSGBOX_DEFAULT
            """,
            to: root.appendingPathComponent(path)
        )
        try write("script Route1 {}\n", to: root.appendingPathComponent("data/maps/Route1/scripts.pory"))

        let plan = ScriptCommandEditPlanner.plan(
            rootPath: root.path,
            draft: ScriptCommandEditDraft(
                sourcePath: path,
                line: 2,
                commandName: "msgbox",
                argumentIndex: 1,
                replacementArgument: "MSGBOX_YESNO"
            )
        )

        XCTAssertFalse(plan.isApplyable)
        XCTAssertTrue(plan.poryscriptReport.porySources.contains { $0.relativePath == "data/maps/Route1/scripts.pory" })
        XCTAssertTrue(plan.diagnostics.contains { $0.code == "SCRIPT_COMMAND_EDIT_PORYSCRIPT_GENERATED_BLOCKED" })
    }

    private func makeTemporaryProjectRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("pokemonhack-script-edit-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
}
