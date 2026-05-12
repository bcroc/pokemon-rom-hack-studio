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

@main
struct PokemonHackCLI {
    static func main() {
        do {
            let output = try run(arguments: Array(CommandLine.arguments.dropFirst()))
            print(output)
        } catch {
            FileHandle.standardError.write(Data((render(error: error) + "\n").utf8))
            Foundation.exit(1)
        }
    }

    static func run(arguments: [String]) throws -> String {
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
        case "moves-graph":
            return try movesGraph(arguments: Array(arguments.dropFirst()))
        case "move-catalog":
            return try moveCatalog(arguments: Array(arguments.dropFirst()))
        case "item-catalog":
            return try itemCatalog(arguments: Array(arguments.dropFirst()))
        case "pokemon-compatibility":
            return try pokemonCompatibility(arguments: Array(arguments.dropFirst()))
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
        case "rom-diff-preview":
            return try romDiffPreview(arguments: Array(arguments.dropFirst()))
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

    private static func speciesGraph(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        let index = try GameAdapterRegistry.index(path: path)
        return try encode(SpeciesGraphBuilder.build(index: index))
    }

    private static func resources(arguments: [String]) throws -> String {
        guard arguments == ["--json"] else {
            throw CLIError.usage
        }
        return try encode(GenIIIResourceRegistry.load())
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
        return try encode(NDSDataSemanticEditor.plan(catalog: catalog, draft: draft))
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

    private static func encode<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(value)
        return String(decoding: data, as: UTF8.self)
    }

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
            return "Usage: pokemonhack-cli inspect <path> --json | index <path> --json | source-index <path> --json | script-outline <path> --json | script-readiness <path> --map <map-id> --json | script-readiness <path> --script <label> --json | moves-graph <path> --json | move-catalog <path> --json | item-catalog <path> --json | pokemon-compatibility <path> --json | species-graph <path> --json | resources --json | resource-index <path> --json | asset-index <path> --json | pokemon-catalog <path> --json | trainer-catalog <path> --json | validate <path> --json | maps <path> --json | map-visual <path> <map-id> --json | graphics <path> --json | graphics-import-plan <project> <package> --json | rom-graph <rom> --json | rom-inspect <rom> --json | nds-inspect <rom> --json | nds-files <rom> --json | narc-inspect <narc> --json | nds-data-catalog <path> --json | nds-data-edit-plan <project> <record-id> --draft-file <path> --json | nds-data-edit-apply <project> <record-id> --draft-file <path> --json | nds-data-semantic-plan <project> <record-id> --set <field=value> [--set <field=value>] --json | nds-data-semantic-apply <project> <record-id> --set <field=value> [--set <field=value>] --json | toolchain-health <path> --json | references --json | patch <patch> --json | patch-manifest <patch> [--base-rom <path>] --json | patch-manifest <project> <patch> [--base-rom <path>] --json | patch-artifact-plan <patch> --base-rom <path> --json | patch-artifact-plan <project> <patch> --base-rom <path> --json | rom-diff-preview <patch> --base-rom <rom> --json | build <path> --json | playtest <path> --headless --json | playtest <path> --launch --json | playtest <path> --screenshot --json | playtest <path> --savestate --json | playtest-debug-plan <path> --json"
        case .unknownCommand(let command):
            return "Unknown command: \(command)"
        }
    }
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
