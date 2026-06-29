import Foundation
import PokemonHackCore

private struct NDSDataEditPlanReport: Codable, Equatable {
    let rootPath: String
    let recordID: String
    let changes: [NDSDataEditFileChangeReport]
    let diagnostics: [Diagnostic]
    let mutationPlan: MutationPlan
    let backupRelativeRoot: String

    init(plan: NDSDataEditPlan) {
        rootPath = plan.rootPath
        recordID = plan.recordID
        changes = plan.changes.map(NDSDataEditFileChangeReport.init(change:))
        diagnostics = plan.diagnostics
        mutationPlan = plan.mutationPlan
        backupRelativeRoot = plan.backupRelativeRoot
    }
}

private struct NDSDataEditFileChangeReport: Codable, Equatable {
    let id: String
    let path: String
    let summary: String
    let originalSHA1: String?
    let originalByteCount: Int
    let newByteCount: Int
    let textPreview: String

    init(change: NDSDataEditFileChange) {
        id = change.id
        path = change.path
        summary = change.summary
        originalSHA1 = change.originalSHA1
        originalByteCount = change.originalByteCount
        newByteCount = change.newByteCount
        textPreview = change.textPreview
    }
}

private struct NDSDataSemanticEditPlanReport: Codable, Equatable {
    let recordID: String
    let requestedFieldKeys: [String]
    let snapshot: NDSDataSemanticSnapshot
    let changes: [NDSDataSemanticFileChangeReport]
    let diagnostics: [Diagnostic]
    let mutationPlan: MutationPlan
    let backupRelativeRoot: String
    let changeCount: Int

    init(plan: NDSDataSemanticEditPlan) {
        recordID = plan.draft.recordID
        requestedFieldKeys = plan.draft.fieldEdits.map(\.key)
        snapshot = plan.snapshot
        changes = plan.editPlan.changes.map(NDSDataSemanticFileChangeReport.init(change:))
        diagnostics = plan.diagnostics
        mutationPlan = plan.editPlan.mutationPlan
        backupRelativeRoot = plan.editPlan.backupRelativeRoot
        changeCount = plan.editPlan.changes.count
    }
}

private struct NDSDataSemanticFileChangeReport: Codable, Equatable {
    let id: String
    let path: String
    let summary: String
    let originalSHA1: String?
    let originalByteCount: Int
    let newByteCount: Int

    init(change: NDSDataEditFileChange) {
        id = change.id
        path = change.path
        summary = change.summary
        originalSHA1 = change.originalSHA1
        originalByteCount = change.originalByteCount
        newByteCount = change.newByteCount
    }
}

private struct CLICommandMetadata: Codable, Equatable {
    let name: String
    let usage: String
    let summary: String
}

private struct CLIHelpReport: Codable, Equatable {
    let executable: String
    let summary: String
    let commands: [CLICommandMetadata]
}

@main
struct PokemonHackCLI {
    static func main() {
        do {
            let arguments = Array(CommandLine.arguments.dropFirst())
            let output = try run(arguments: arguments)
            print(output)
            let code = exitCode(arguments: arguments, output: output)
            if code != 0 {
                Foundation.exit(code)
            }
        } catch {
            FileHandle.standardError.write(Data((render(error: error) + "\n").utf8))
            Foundation.exit(1)
        }
    }

    static func run(arguments: [String]) throws -> String {
        if arguments == ["--help"] || arguments == ["help"] {
            return helpText
        }
        if arguments == ["help", "--json"] || arguments == ["--help", "--json"] {
            return try encode(helpReport)
        }
        guard let command = arguments.first else {
            throw CLIError.usage
        }

        switch command {
        case "inspect":
            return try inspect(arguments: Array(arguments.dropFirst()))
        case "index":
            return try index(arguments: Array(arguments.dropFirst()))
        case "source-index":
            return try sourceIndex(arguments: Array(arguments.dropFirst()))
        case "script-outline":
            return try scriptOutline(arguments: Array(arguments.dropFirst()))
        case "script-readiness":
            return try scriptReadiness(arguments: Array(arguments.dropFirst()))
        case "script-command-edit-plan":
            return try scriptCommandEditPlan(arguments: Array(arguments.dropFirst()))
        case "script-command-edit-apply":
            return try scriptCommandEditApply(arguments: Array(arguments.dropFirst()))
        case "moves-graph":
            return try movesGraph(arguments: Array(arguments.dropFirst()))
        case "move-catalog":
            return try moveCatalog(arguments: Array(arguments.dropFirst()))
        case "item-catalog":
            return try itemCatalog(arguments: Array(arguments.dropFirst()))
        case "pokemon-compatibility":
            return try pokemonCompatibility(arguments: Array(arguments.dropFirst()))
        case "migration-coverage":
            return try migrationCoverage(arguments: Array(arguments.dropFirst()))
        case "rom-asset-migration-plan":
            return try romAssetMigrationPlan(arguments: Array(arguments.dropFirst()))
        case "species-graph":
            return try speciesGraph(arguments: Array(arguments.dropFirst()))
        case "resources":
            return try resources(arguments: Array(arguments.dropFirst()))
        case "resource-index":
            return try resourceIndex(arguments: Array(arguments.dropFirst()))
        case "asset-index":
            return try assetIndex(arguments: Array(arguments.dropFirst()))
        case "pokemon-catalog":
            return try pokemonCatalog(arguments: Array(arguments.dropFirst()))
        case "trainer-catalog":
            return try trainerCatalog(arguments: Array(arguments.dropFirst()))
        case "validate":
            return try validate(arguments: Array(arguments.dropFirst()))
        case "maps":
            return try maps(arguments: Array(arguments.dropFirst()))
        case "map-visual":
            return try mapVisual(arguments: Array(arguments.dropFirst()))
        case "graphics":
            return try graphics(arguments: Array(arguments.dropFirst()))
        case "graphics-import-plan":
            return try graphicsImportPlan(arguments: Array(arguments.dropFirst()))
        case "rom-graph":
            return try romGraph(arguments: Array(arguments.dropFirst()))
        case "rom-inspect":
            return try romInspect(arguments: Array(arguments.dropFirst()))
        case "nds-inspect":
            return try ndsInspect(arguments: Array(arguments.dropFirst()))
        case "nds-files":
            return try ndsFiles(arguments: Array(arguments.dropFirst()))
        case "narc-inspect":
            return try narcInspect(arguments: Array(arguments.dropFirst()))
        case "nds-data-catalog":
            return try ndsDataCatalog(arguments: Array(arguments.dropFirst()))
        case "nds-data-edit-plan":
            return try ndsDataEditPlan(arguments: Array(arguments.dropFirst()))
        case "nds-data-edit-apply":
            return try ndsDataEditApply(arguments: Array(arguments.dropFirst()))
        case "nds-data-semantic-plan":
            return try ndsDataSemanticPlan(arguments: Array(arguments.dropFirst()))
        case "nds-data-semantic-apply":
            return try ndsDataSemanticApply(arguments: Array(arguments.dropFirst()))
        case "toolchain-health":
            return try toolchainHealth(arguments: Array(arguments.dropFirst()))
        case "references":
            return try references(arguments: Array(arguments.dropFirst()))
        case "patch":
            return try patch(arguments: Array(arguments.dropFirst()))
        case "patch-manifest":
            return try patchManifest(arguments: Array(arguments.dropFirst()))
        case "patch-artifact-plan":
            return try patchArtifactPlan(arguments: Array(arguments.dropFirst()))
        case "patch-create-preview":
            return try patchCreatePreview(arguments: Array(arguments.dropFirst()))
        case "patch-apply-export":
            return try patchApplyExport(arguments: Array(arguments.dropFirst()))
        case "rom-diff-preview":
            return try romDiffPreview(arguments: Array(arguments.dropFirst()))
        case "rom-mutation-manifest":
            return try romMutationManifest(arguments: Array(arguments.dropFirst()))
        case "build":
            return try build(arguments: Array(arguments.dropFirst()))
        case "playtest":
            return try playtest(arguments: Array(arguments.dropFirst()))
        case "playtest-debug-plan":
            return try playtestDebugPlan(arguments: Array(arguments.dropFirst()))
        default:
            throw CLIError.unknownCommand(command)
        }
    }

    static func exitCode(arguments: [String], output: String) -> Int32 {
        guard let command = arguments.first else { return 0 }
        switch command {
        case "patch-apply-export":
            guard let object = jsonObject(output) else { return 0 }
            return object["status"] as? String == "blocked" ? 1 : 0
        case "script-command-edit-apply", "nds-data-edit-apply", "nds-data-semantic-apply":
            guard let object = jsonObject(output) else { return 0 }
            if diagnosticsContainError(object["diagnostics"]) {
                return 1
            }
            if let changes = object["appliedChanges"] as? [Any], changes.isEmpty {
                return 1
            }
            return 0
        default:
            return 0
        }
    }

    private static func jsonObject(_ output: String) -> [String: Any]? {
        guard
            let data = output.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }
        return object
    }

    private static func diagnosticsContainError(_ diagnostics: Any?) -> Bool {
        guard let diagnostics = diagnostics as? [[String: Any]] else { return false }
        return diagnostics.contains { diagnostic in
            diagnostic["severity"] as? String == "error"
        }
    }

    private static func inspect(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        return try encode(ProjectInspector.inspect(path: path))
    }

    private static func index(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        return try encode(GameAdapterRegistry.index(path: path))
    }

    private static func sourceIndex(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        let index = try GameAdapterRegistry.index(path: path)
        return try encode(ProjectSourceIndexLoader.load(from: index))
    }

    private static func scriptOutline(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        let index = try GameAdapterRegistry.index(path: path)
        return try encode(ProjectScriptOutlineLoader.load(from: index))
    }

    private static func scriptReadiness(arguments: [String]) throws -> String {
        guard
            arguments.count == 4,
            let path = arguments.first,
            let targetFlag = arguments.dropFirst().first,
            let targetID = arguments.dropFirst(2).first,
            arguments.last == "--json"
        else {
            throw CLIError.usage
        }

        let kind: ScriptReadinessTargetKind
        switch targetFlag {
        case "--map":
            kind = .map
        case "--script":
            kind = .script
        default:
            throw CLIError.usage
        }

        let index = try GameAdapterRegistry.index(path: path)
        let target = ScriptReadinessTarget(kind: kind, identifier: targetID)
        return try encode(ScriptReadinessReportBuilder.build(index: index, target: target))
    }

    private static func scriptCommandEditPlan(arguments: [String]) throws -> String {
        let request = try scriptCommandEditRequest(arguments: arguments)
        return try encode(
            ScriptCommandEditPlanner.plan(
                rootPath: request.projectPath,
                draft: request.draft
            )
        )
    }

    private static func scriptCommandEditApply(arguments: [String]) throws -> String {
        let request = try scriptCommandEditRequest(arguments: arguments)
        let plan = ScriptCommandEditPlanner.plan(
            rootPath: request.projectPath,
            draft: request.draft
        )
        return try encode(try ScriptCommandEditApplier.apply(plan: plan))
    }

    private static func movesGraph(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        let index = try GameAdapterRegistry.index(path: path)
        return try encode(MoveGraphBuilder.build(index: index))
    }

    private static func moveCatalog(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        return try encode(ProjectMoveCatalogBuilder.build(path: path))
    }

    private static func itemCatalog(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        return try encode(ProjectItemCatalogBuilder.build(path: path))
    }

    private static func pokemonCompatibility(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        return try encode(PokemonDataCompatibilityReportBuilder.build(path: path))
    }

    private static func migrationCoverage(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        return try encode(MigrationCoverageReportBuilder.build(path: path))
    }

    private static func romAssetMigrationPlan(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        return try encode(ROMAssetMigrationPlanBuilder.build(path: path))
    }

    private static func speciesGraph(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        let index = try GameAdapterRegistry.index(path: path)
        return try encode(SpeciesGraphBuilder.build(index: index))
    }

    private static func resources(arguments: [String]) throws -> String {
        switch arguments {
        case ["--json"]:
            return try encode(GenIIIResourceRegistry.load())
        case ["--summary", "--json"]:
            return try encode(GenIIIResourceRegistry.load(detailMode: .summary))
        default:
            throw CLIError.usage
        }
    }

    private static func resourceIndex(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        return try encode(GenIIIResourceRegistry.resourceIndex(path: path))
    }

    private static func assetIndex(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        if let cachedJSON = GenIIIAssetCatalogBuilder.cachedCatalogJSONString(path: path) {
            return cachedJSON
        }
        return try encode(GenIIIAssetCatalogBuilder.build(path: path))
    }

    private static func pokemonCatalog(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        return try encode(ProjectSpeciesCatalogBuilder.build(path: path))
    }

    private static func trainerCatalog(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        return try encode(ProjectTrainerCatalogBuilder.build(path: path))
    }

    private static func validate(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        let index = try GameAdapterRegistry.index(path: path)
        let sourceIndex = try ProjectSourceIndexLoader.load(from: index)
        let buildReport = BuildValidationReportBuilder.build(index: index)
        let assetCatalog = GenIIIAssetCatalogBuilder.build(index: index, sourceIndex: sourceIndex, buildReport: buildReport)
        let playtestReport = PlaytestHandoffReportBuilder.build(index: index)
        let toolchainHealthReport = ToolchainHealthMatrixBuilder.build(
            index: index,
            buildReport: buildReport,
            playtestReport: playtestReport
        )
        return try encode(
            ValidationReport(
                index: index,
                sourceIndex: sourceIndex,
                assetCatalog: assetCatalog,
                buildReport: buildReport,
                playtestReport: playtestReport,
                toolchainHealthReport: toolchainHealthReport
            )
        )
    }

    private static func maps(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        let index = try GameAdapterRegistry.index(path: path)
        return try encode(ProjectMapCatalogLoader.load(from: index))
    }

    private static func mapVisual(arguments: [String]) throws -> String {
        guard arguments.count == 3, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        let index = try GameAdapterRegistry.index(path: path)
        return try encode(ProjectMapVisualLoader.load(from: index, mapID: arguments[1]))
    }

    private static func graphics(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        let index = try GameAdapterRegistry.index(path: path)
        return try encode(GraphicsDiagnosticsReportBuilder.build(index: index))
    }

    private static func graphicsImportPlan(arguments: [String]) throws -> String {
        guard arguments.count == 3, let project = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        return try encode(GraphicsImportPackagePlanBuilder.build(projectPath: project, packagePath: arguments[1]))
    }

    private static func romGraph(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try encode(BinaryROMGraphBuilder.build(path: path, data: data))
    }

    private static func romInspect(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        if (try? GameAdapterRegistry.index(path: path).profile) == .ndsROM {
            return try encode(NDSROMInspectorReportBuilder.build(path: path))
        }
        return try encode(BinaryROMInspectorReportBuilder.build(path: path))
    }

    private static func ndsInspect(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        return try encode(NDSROMInspectorReportBuilder.build(path: path))
    }

    private static func ndsFiles(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        return try encode(NDSROMInspectorReportBuilder.files(path: path))
    }

    private static func narcInspect(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try encode(NARCParser.parse(path: path, data: data))
    }

    private static func ndsDataCatalog(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        return try encode(NDSDataCatalogBuilder.build(path: path))
    }

    private static func ndsDataEditPlan(arguments: [String]) throws -> String {
        guard let request = try parseNDSDataEditArguments(arguments) else {
            throw CLIError.usage
        }
        let catalog = try NDSDataCatalogBuilder.build(path: request.projectPath)
        let draft = try ndsDataEditDraft(recordID: request.recordID, draftFilePath: request.draftFilePath)
        return try encode(NDSDataEditPlanReport(plan: NDSDataMutationPlanner.plan(catalog: catalog, draft: draft)))
    }

    private static func ndsDataEditApply(arguments: [String]) throws -> String {
        guard let request = try parseNDSDataEditArguments(arguments) else {
            throw CLIError.usage
        }
        let catalog = try NDSDataCatalogBuilder.build(path: request.projectPath)
        let draft = try ndsDataEditDraft(recordID: request.recordID, draftFilePath: request.draftFilePath)
        let plan = NDSDataMutationPlanner.plan(catalog: catalog, draft: draft)
        return try encode(try NDSDataMutationApplier.apply(plan: plan))
    }

    private static func ndsDataSemanticPlan(arguments: [String]) throws -> String {
        guard let request = parseNDSDataSemanticArguments(arguments) else {
            throw CLIError.usage
        }
        let catalog = try NDSDataCatalogBuilder.build(path: request.projectPath)
        let draft = NDSDataSemanticEditDraft(recordID: request.recordID, fieldEdits: request.fieldEdits)
        return try encode(NDSDataSemanticEditPlanReport(plan: NDSDataSemanticEditor.plan(catalog: catalog, draft: draft)))
    }

    private static func ndsDataSemanticApply(arguments: [String]) throws -> String {
        guard let request = parseNDSDataSemanticArguments(arguments) else {
            throw CLIError.usage
        }
        let catalog = try NDSDataCatalogBuilder.build(path: request.projectPath)
        let draft = NDSDataSemanticEditDraft(recordID: request.recordID, fieldEdits: request.fieldEdits)
        let semanticPlan = NDSDataSemanticEditor.plan(catalog: catalog, draft: draft)
        return try encode(try NDSDataMutationApplier.apply(plan: semanticPlan.editPlan))
    }

    private static func parseNDSDataEditArguments(_ arguments: [String]) throws -> NDSDataEditCLIRequest? {
        guard arguments.count == 5,
              arguments[2] == "--draft-file",
              arguments[4] == "--json"
        else {
            return nil
        }
        return NDSDataEditCLIRequest(projectPath: arguments[0], recordID: arguments[1], draftFilePath: arguments[3])
    }

    private static func parseNDSDataSemanticArguments(_ arguments: [String]) -> NDSDataSemanticCLIRequest? {
        guard arguments.count >= 5,
              arguments.last == "--json"
        else {
            return nil
        }
        let projectPath = arguments[0]
        let recordID = arguments[1]
        var index = 2
        var edits: [NDSDataSemanticFieldEdit] = []
        while index < arguments.count - 1 {
            guard arguments[index] == "--set", index + 1 < arguments.count - 1 else {
                return nil
            }
            let assignment = arguments[index + 1]
            guard let equals = assignment.firstIndex(of: "=") else {
                return nil
            }
            let key = String(assignment[..<equals])
            let value = String(assignment[assignment.index(after: equals)...])
            guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            edits.append(NDSDataSemanticFieldEdit(key: key, value: value))
            index += 2
        }
        guard !edits.isEmpty else { return nil }
        return NDSDataSemanticCLIRequest(projectPath: projectPath, recordID: recordID, fieldEdits: edits)
    }

    private static func ndsDataEditDraft(recordID: String, draftFilePath: String) throws -> NDSDataEditDraft {
        let text = try String(contentsOf: URL(fileURLWithPath: draftFilePath), encoding: .utf8)
        return NDSDataEditDraft(recordID: recordID, editedText: text)
    }

    private static func toolchainHealth(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        let index = try GameAdapterRegistry.index(path: path)
        return try encode(ToolchainHealthMatrixBuilder.build(index: index))
    }

    private static func references(arguments: [String]) throws -> String {
        guard arguments == ["--json"] else {
            throw CLIError.usage
        }
        return try encode(ReferenceManifestLoader.load())
    }

    private static func patch(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        return try encode(PatchValidationReportBuilder.validate(path: path))
    }

    private static func patchManifest(arguments: [String]) throws -> String {
        guard arguments.last == "--json" else {
            throw CLIError.usage
        }

        var positionals: [String] = []
        var baseROMPath: String?
        var index = 0
        let payload = Array(arguments.dropLast())
        while index < payload.count {
            let argument = payload[index]
            if argument == "--base-rom" {
                let nextIndex = index + 1
                guard nextIndex < payload.count else {
                    throw CLIError.usage
                }
                baseROMPath = payload[nextIndex]
                index += 2
            } else {
                positionals.append(argument)
                index += 1
            }
        }

        if positionals.count == 1, let patch = positionals.first {
            return try encode(PatchManifestBuilder.build(patchPath: patch, baseROMPath: baseROMPath))
        }
        guard positionals.count == 2, let project = positionals.first, let patch = positionals.dropFirst().first else {
            throw CLIError.usage
        }
        return try encode(PatchManifestBuilder.build(patchPath: patch, projectPath: project, baseROMPath: baseROMPath))
    }

    private static func patchArtifactPlan(arguments: [String]) throws -> String {
        guard arguments.last == "--json" else {
            throw CLIError.usage
        }

        var positionals: [String] = []
        var baseROMPath: String?
        var index = 0
        let payload = Array(arguments.dropLast())
        while index < payload.count {
            let argument = payload[index]
            if argument == "--base-rom" {
                let nextIndex = index + 1
                guard nextIndex < payload.count else {
                    throw CLIError.usage
                }
                baseROMPath = payload[nextIndex]
                index += 2
            } else {
                positionals.append(argument)
                index += 1
            }
        }

        guard let baseROMPath else {
            throw CLIError.usage
        }
        if positionals.count == 1, let patch = positionals.first {
            let report = try PatchManifestBuilder.build(
                patchPath: patch,
                baseROMPath: baseROMPath
            )
            return try encode(report.artifactPlan)
        }
        guard positionals.count == 2, let project = positionals.first, let patch = positionals.dropFirst().first else {
            throw CLIError.usage
        }
        let report = try PatchManifestBuilder.build(
            patchPath: patch,
            projectPath: project,
            baseROMPath: baseROMPath
        )
        return try encode(report.artifactPlan)
    }

    private static func romDiffPreview(arguments: [String]) throws -> String {
        guard
            arguments.count == 4,
            let patch = arguments.first,
            arguments[1] == "--base-rom",
            arguments.last == "--json"
        else {
            throw CLIError.usage
        }

        return try encode(
            PatchManifestBuilder.binaryDiffPreview(
                patchPath: patch,
                baseROMPath: arguments[2]
            )
        )
    }

    private static func romMutationManifest(arguments: [String]) throws -> String {
        guard arguments.count >= 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }

        let request = try parseROMMutationManifestArguments(Array(arguments.dropFirst().dropLast()))
        return try encode(BinaryROMMutationDryRunManifestBuilder.build(path: path, request: request))
    }

    private static func parseROMMutationManifestArguments(_ arguments: [String]) throws -> BinaryROMMutationDryRunRequest {
        var expectedSHA1: String?
        var workspaceRoot: String?
        var replacements: [BinaryROMMutationReplacementRequest] = []
        var repoints: [BinaryROMMutationRepointRequest] = []
        var allocations: [BinaryROMMutationAllocationRequest] = []

        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "--workspace-root":
                guard index + 1 < arguments.count else { throw CLIError.usage }
                workspaceRoot = arguments[index + 1]
                index += 2
            case "--expect-sha1":
                guard index + 1 < arguments.count else { throw CLIError.usage }
                expectedSHA1 = arguments[index + 1]
                index += 2
            case "--replace":
                guard index + 1 < arguments.count else { throw CLIError.usage }
                replacements.append(try parseReplacement(arguments[index + 1]))
                index += 2
            case "--repoint":
                guard index + 1 < arguments.count else { throw CLIError.usage }
                repoints.append(try parseRepoint(arguments[index + 1]))
                index += 2
            case "--allocate":
                guard index + 1 < arguments.count else { throw CLIError.usage }
                allocations.append(try parseAllocation(arguments[index + 1]))
                index += 2
            default:
                throw CLIError.usage
            }
        }

        return BinaryROMMutationDryRunRequest(
            expectedSHA1: expectedSHA1,
            workspaceRoot: workspaceRoot,
            replacements: replacements,
            repoints: repoints,
            allocations: allocations
        )
    }

    private static func parseReplacement(_ text: String) throws -> BinaryROMMutationReplacementRequest {
        let parts = text.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 3,
              let offset = parseUInt32(parts[0]),
              let length = parseUInt32(parts[1])
        else {
            throw CLIError.usage
        }
        return BinaryROMMutationReplacementRequest(
            offset: offset,
            length: length,
            replacementBytes: try parseHexBytes(parts[2])
        )
    }

    private static func parseRepoint(_ text: String) throws -> BinaryROMMutationRepointRequest {
        let parts = text.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 2,
              let pointerOffset = parseUInt32(parts[0]),
              let newTargetOffset = parseUInt32(parts[1])
        else {
            throw CLIError.usage
        }
        return BinaryROMMutationRepointRequest(pointerOffset: pointerOffset, newTargetOffset: newTargetOffset)
    }

    private static func parseAllocation(_ text: String) throws -> BinaryROMMutationAllocationRequest {
        let parts = text.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 1 || parts.count == 2, let byteCount = parseUInt32(parts[0]) else {
            throw CLIError.usage
        }
        let alignment = parts.count == 2 ? parseUInt32(parts[1]) : 1
        guard let alignment else {
            throw CLIError.usage
        }
        return BinaryROMMutationAllocationRequest(byteCount: byteCount, alignment: alignment)
    }

    private static func parseUInt32(_ text: String) -> UInt32? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("0x") {
            return UInt32(trimmed.dropFirst(2), radix: 16)
        }
        return UInt32(trimmed, radix: 10)
    }

    private static func parseHexBytes(_ text: String) throws -> [UInt8] {
        let compact = text
            .filter { !$0.isWhitespace && $0 != "_" }
            .map(String.init)
            .joined()
        guard !compact.isEmpty, compact.count.isMultiple(of: 2) else {
            throw CLIError.usage
        }

        var bytes: [UInt8] = []
        var index = compact.startIndex
        while index < compact.endIndex {
            let next = compact.index(index, offsetBy: 2)
            guard let byte = UInt8(compact[index..<next], radix: 16) else {
                throw CLIError.usage
            }
            bytes.append(byte)
            index = next
        }
        return bytes
    }

    private static func patchCreatePreview(arguments: [String]) throws -> String {
        guard arguments.last == "--json" else {
            throw CLIError.usage
        }

        var positionals: [String] = []
        var baseROMPath: String?
        var targetID: String?
        var index = 0
        let payload = Array(arguments.dropLast())
        while index < payload.count {
            let argument = payload[index]
            if argument == "--base-rom" {
                let nextIndex = index + 1
                guard nextIndex < payload.count else {
                    throw CLIError.usage
                }
                baseROMPath = payload[nextIndex]
                index += 2
            } else if argument == "--target" {
                let nextIndex = index + 1
                guard nextIndex < payload.count else {
                    throw CLIError.usage
                }
                targetID = payload[nextIndex]
                index += 2
            } else {
                positionals.append(argument)
                index += 1
            }
        }

        guard positionals.count == 1, let project = positionals.first, let baseROMPath else {
            throw CLIError.usage
        }
        return try encode(
            PatchCreationPreviewBuilder.build(
                projectPath: project,
                baseROMPath: baseROMPath,
                targetID: targetID
            )
        )
    }

    private static func patchApplyExport(arguments: [String]) throws -> String {
        guard arguments.last == "--json" else {
            throw CLIError.usage
        }

        var positionals: [String] = []
        var baseROMPath: String?
        var overwrite = false
        var index = 0
        let payload = Array(arguments.dropLast())
        while index < payload.count {
            let argument = payload[index]
            if argument == "--base-rom" {
                let nextIndex = index + 1
                guard nextIndex < payload.count else {
                    throw CLIError.usage
                }
                baseROMPath = payload[nextIndex]
                index += 2
            } else if argument == "--overwrite" {
                overwrite = true
                index += 1
            } else {
                positionals.append(argument)
                index += 1
            }
        }

        guard let baseROMPath else {
            throw CLIError.usage
        }
        if positionals.count == 1, let patch = positionals.first {
            return try encode(
                PatchManifestBuilder.applyExport(
                    patchPath: patch,
                    baseROMPath: baseROMPath,
                    overwrite: overwrite
                )
            )
        }
        guard positionals.count == 2, let project = positionals.first, let patch = positionals.dropFirst().first else {
            throw CLIError.usage
        }
        return try encode(
            PatchManifestBuilder.applyExport(
                patchPath: patch,
                projectPath: project,
                baseROMPath: baseROMPath,
                overwrite: overwrite
            )
        )
    }

    private static func build(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        let index = try GameAdapterRegistry.index(path: path)
        return try encode(BuildValidationReportBuilder.build(index: index))
    }

    private static func playtest(arguments: [String]) throws -> String {
        guard arguments.count == 3, let path = arguments.first, arguments[2] == "--json" else {
            throw CLIError.usage
        }
        let index = try GameAdapterRegistry.index(path: path)
        switch arguments[1] {
        case "--headless":
            return try encode(PlaytestHandoffReportBuilder.build(index: index, mode: .headless))
        case "--launch":
            return try encode(
                PlaytestLauncher.launch(
                    index: index,
                    mode: .interactive,
                    artifactRoot: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                )
            )
        case "--screenshot":
            return try encode(
                PlaytestLauncher.capture(
                    index: index,
                    kind: .screenshot,
                    mode: .interactive,
                    artifactRoot: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                )
            )
        case "--savestate":
            return try encode(
                PlaytestLauncher.capture(
                    index: index,
                    kind: .saveState,
                    mode: .interactive,
                    artifactRoot: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                )
            )
        default:
            throw CLIError.usage
        }
    }

    private static func playtestDebugPlan(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        let index = try GameAdapterRegistry.index(path: path)
        return try encode(PlaytestDebugPlanBuilder.build(index: index))
    }

    private static func scriptCommandEditRequest(arguments: [String]) throws -> ScriptCommandEditCLIRequest {
        guard
            arguments.count == 6,
            let projectPath = arguments.first,
            let sourcePath = arguments.dropFirst().first,
            let lineText = arguments.dropFirst(2).first,
            let argumentIndexText = arguments.dropFirst(3).first,
            let replacementArgument = arguments.dropFirst(4).first,
            arguments.last == "--json",
            let line = Int(lineText),
            let argumentIndex = Int(argumentIndexText)
        else {
            throw CLIError.usage
        }

        return ScriptCommandEditCLIRequest(
            projectPath: projectPath,
            draft: ScriptCommandEditDraft(
                sourcePath: sourcePath,
                line: line,
                argumentIndex: argumentIndex,
                replacementArgument: replacementArgument
            )
        )
    }

    private static func encode<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(value)
        return String(decoding: data, as: UTF8.self)
    }

    static var helpText: String {
        let commandLines = commandMetadata.map { "  \($0.usage)\n      \($0.summary)" }.joined(separator: "\n")
        return """
        Usage: pokemonhack-cli <command> [arguments]

        Commands:
        \(commandLines)

        Run pokemonhack-cli help --json for machine-readable command metadata.
        """
    }

    private static var helpReport: CLIHelpReport {
        CLIHelpReport(
            executable: "pokemonhack-cli",
            summary: "Inspect, validate, preview, and explicitly apply supported PokemonHackStudio project plans.",
            commands: commandMetadata
        )
    }

    private static let commandMetadata: [CLICommandMetadata] = [
        CLICommandMetadata(name: "inspect", usage: "inspect <path> --json", summary: "Inspect a project, ROM, or supported input path."),
        CLICommandMetadata(name: "index", usage: "index <path> --json", summary: "Build the adapter index for a project path."),
        CLICommandMetadata(name: "source-index", usage: "source-index <path> --json", summary: "Emit parsed source index records."),
        CLICommandMetadata(name: "script-outline", usage: "script-outline <path> --json", summary: "Emit script outline records."),
        CLICommandMetadata(name: "script-readiness", usage: "script-readiness <path> --map <map-id> --json | script-readiness <path> --script <label> --json", summary: "Preview script readiness for a map or script label."),
        CLICommandMetadata(name: "script-command-edit-plan", usage: "script-command-edit-plan <project> <source-path> <line> <argument-index> <replacement> --json", summary: "Plan a single native script command argument edit."),
        CLICommandMetadata(name: "script-command-edit-apply", usage: "script-command-edit-apply <project> <source-path> <line> <argument-index> <replacement> --json", summary: "Apply a planned native script command argument edit through backups and safety checks."),
        CLICommandMetadata(name: "moves-graph", usage: "moves-graph <path> --json", summary: "Emit move and learnset graph data."),
        CLICommandMetadata(name: "move-catalog", usage: "move-catalog <path> --json", summary: "Emit editable/read-only move catalog data."),
        CLICommandMetadata(name: "item-catalog", usage: "item-catalog <path> --json", summary: "Emit editable/read-only item catalog data."),
        CLICommandMetadata(name: "pokemon-compatibility", usage: "pokemon-compatibility <path> --json", summary: "Report Pokemon data editor compatibility by surface."),
        CLICommandMetadata(name: "migration-coverage", usage: "migration-coverage <path> --json", summary: "Report source migration coverage."),
        CLICommandMetadata(name: "rom-asset-migration-plan", usage: "rom-asset-migration-plan <rom> --json", summary: "Preview ROM asset migration targets."),
        CLICommandMetadata(name: "species-graph", usage: "species-graph <path> --json", summary: "Emit species graph data."),
        CLICommandMetadata(name: "resources", usage: "resources [--summary] --json", summary: "Emit the built-in resource manifest, optionally as launch-speed summary rows."),
        CLICommandMetadata(name: "resource-index", usage: "resource-index <path> --json", summary: "Emit resource rows for a project path."),
        CLICommandMetadata(name: "asset-index", usage: "asset-index <path> --json", summary: "Emit or reuse the generated asset catalog."),
        CLICommandMetadata(name: "pokemon-catalog", usage: "pokemon-catalog <path> --json", summary: "Emit Pokemon species catalog data."),
        CLICommandMetadata(name: "trainer-catalog", usage: "trainer-catalog <path> --json", summary: "Emit trainer catalog data."),
        CLICommandMetadata(name: "validate", usage: "validate <path> --json", summary: "Emit the composite validation report."),
        CLICommandMetadata(name: "maps", usage: "maps <path> --json", summary: "Emit map catalog data."),
        CLICommandMetadata(name: "map-visual", usage: "map-visual <path> <map-id> --json", summary: "Emit map visual data for one map."),
        CLICommandMetadata(name: "graphics", usage: "graphics <path> --json", summary: "Emit graphics diagnostics."),
        CLICommandMetadata(name: "graphics-import-plan", usage: "graphics-import-plan <project> <package> --json", summary: "Preview graphics import package handling without applying it."),
        CLICommandMetadata(name: "rom-graph", usage: "rom-graph <rom> --json", summary: "Emit semantic GBA ROM graph data."),
        CLICommandMetadata(name: "rom-inspect", usage: "rom-inspect <rom> --json", summary: "Inspect a GBA or NDS ROM."),
        CLICommandMetadata(name: "nds-inspect", usage: "nds-inspect <rom> --json", summary: "Inspect an NDS ROM header and layout."),
        CLICommandMetadata(name: "nds-files", usage: "nds-files <rom> --json", summary: "Emit NDS filesystem rows."),
        CLICommandMetadata(name: "narc-inspect", usage: "narc-inspect <narc> --json", summary: "Inspect a NARC container."),
        CLICommandMetadata(name: "nds-data-catalog", usage: "nds-data-catalog <path> --json", summary: "Emit the NDS data catalog."),
        CLICommandMetadata(name: "nds-data-edit-plan", usage: "nds-data-edit-plan <project> <record-id> --draft-file <path> --json", summary: "Plan a raw source-backed NDS data edit."),
        CLICommandMetadata(name: "nds-data-edit-apply", usage: "nds-data-edit-apply <project> <record-id> --draft-file <path> --json", summary: "Apply a raw source-backed NDS data edit through backups and safety checks."),
        CLICommandMetadata(name: "nds-data-semantic-plan", usage: "nds-data-semantic-plan <project> <record-id> --set <field=value> [--set <field=value>] --json", summary: "Plan redacted field-level NDS semantic edits."),
        CLICommandMetadata(name: "nds-data-semantic-apply", usage: "nds-data-semantic-apply <project> <record-id> --set <field=value> [--set <field=value>] --json", summary: "Apply field-level NDS semantic edits through the existing source mutation gate."),
        CLICommandMetadata(name: "toolchain-health", usage: "toolchain-health <path> --json", summary: "Emit toolchain readiness rows."),
        CLICommandMetadata(name: "references", usage: "references --json", summary: "Emit reference repository metadata."),
        CLICommandMetadata(name: "patch", usage: "patch <patch> --json", summary: "Validate patch metadata."),
        CLICommandMetadata(name: "patch-manifest", usage: "patch-manifest <patch> [--base-rom <path>] --json | patch-manifest <project> <patch> [--base-rom <path>] --json", summary: "Emit patch manifest compatibility data."),
        CLICommandMetadata(name: "patch-artifact-plan", usage: "patch-artifact-plan <patch> --base-rom <path> --json | patch-artifact-plan <project> <patch> --base-rom <path> --json", summary: "Preview patch output artifacts without writing them."),
        CLICommandMetadata(name: "patch-create-preview", usage: "patch-create-preview <project> --base-rom <path> [--target <build-target-id>] --json", summary: "Preview BPS patch creation metadata from a selected base ROM to an existing built output without writing patch files."),
        CLICommandMetadata(name: "patch-apply-export", usage: "patch-apply-export <patch> --base-rom <path> [--overwrite] --json | patch-apply-export <project> <patch> --base-rom <path> [--overwrite] --json", summary: "Explicitly apply a supported patch and export an ignored ROM artifact with checksum and manifest proof."),
        CLICommandMetadata(name: "rom-diff-preview", usage: "rom-diff-preview <patch> --base-rom <rom> --json", summary: "Preview binary patch diff spans."),
        CLICommandMetadata(name: "rom-mutation-manifest", usage: "rom-mutation-manifest <rom-or-source-path> [--workspace-root <path>] [--expect-sha1 <sha1>] [--replace <offset:length:hex>] [--repoint <pointer-offset:new-target-offset>] [--allocate <byte-count[:alignment]>] --json", summary: "Emit a dry-run-only future binary ROM mutation manifest with canApply=false."),
        CLICommandMetadata(name: "build", usage: "build <path> --json", summary: "Emit build validation data without building."),
        CLICommandMetadata(name: "playtest", usage: "playtest <path> --headless --json | playtest <path> --launch --json | playtest <path> --screenshot --json | playtest <path> --savestate --json", summary: "Preview or run supported mGBA handoff actions."),
        CLICommandMetadata(name: "playtest-debug-plan", usage: "playtest-debug-plan <path> --json", summary: "Preview emulator debugging plans."),
        CLICommandMetadata(name: "help", usage: "help [--json] | --help [--json]", summary: "Show human or machine-readable command metadata.")
    ]

    private static func render(error: Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }
        return String(describing: error)
    }
}

enum CLIError: Error, LocalizedError, Equatable {
    case usage
    case unknownCommand(String)

    var errorDescription: String? {
        switch self {
        case .usage:
            return PokemonHackCLI.helpText
        case .unknownCommand(let command):
            return "Unknown command: \(command)"
        }
    }
}

private struct ScriptCommandEditCLIRequest {
    let projectPath: String
    let draft: ScriptCommandEditDraft
}

private struct NDSDataEditCLIRequest {
    let projectPath: String
    let recordID: String
    let draftFilePath: String
}

private struct NDSDataSemanticCLIRequest {
    let projectPath: String
    let recordID: String
    let fieldEdits: [NDSDataSemanticFieldEdit]
}

struct ValidationReport: Encodable {
    let adapterID: String
    let profile: GameProfile
    let issueCount: Int
    let sourceIndexRecordCount: Int
    let assetCount: Int
    let assetCatalog: GenIIIAssetCatalog
    let buildReport: BuildValidationReport
    let playtestReport: PlaytestHandoffReport
    let toolchainHealthReport: ToolchainHealthMatrixReport
    let diagnostics: [Diagnostic]

    init(
        index: ProjectIndex,
        sourceIndex: ProjectSourceIndex,
        assetCatalog: GenIIIAssetCatalog,
        buildReport: BuildValidationReport,
        playtestReport: PlaytestHandoffReport,
        toolchainHealthReport: ToolchainHealthMatrixReport
    ) {
        adapterID = index.adapterID
        profile = index.profile
        sourceIndexRecordCount = sourceIndex.records.count
        assetCount = assetCatalog.assetCount
        self.assetCatalog = assetCatalog
        self.buildReport = buildReport
        self.playtestReport = playtestReport
        self.toolchainHealthReport = toolchainHealthReport
        diagnostics = index.diagnostics
            + sourceIndex.diagnostics
            + assetCatalog.diagnostics
            + buildReport.diagnostics
            + playtestReport.diagnostics
            + toolchainHealthReport.diagnostics
        issueCount = diagnostics.count
    }
}
