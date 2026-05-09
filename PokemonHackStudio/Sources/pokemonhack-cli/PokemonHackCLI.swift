import Foundation
import PokemonHackCore

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
        case "toolchain-health":
            return try toolchainHealth(arguments: Array(arguments.dropFirst()))
        case "references":
            return try references(arguments: Array(arguments.dropFirst()))
        case "patch":
            return try patch(arguments: Array(arguments.dropFirst()))
        case "patch-manifest":
            return try patchManifest(arguments: Array(arguments.dropFirst()))
        case "build":
            return try build(arguments: Array(arguments.dropFirst()))
        case "playtest":
            return try playtest(arguments: Array(arguments.dropFirst()))
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
        default:
            throw CLIError.usage
        }
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
            return "Usage: pokemonhack-cli inspect <path> --json | index <path> --json | source-index <path> --json | script-outline <path> --json | script-readiness <path> --map <map-id> --json | script-readiness <path> --script <label> --json | moves-graph <path> --json | move-catalog <path> --json | item-catalog <path> --json | species-graph <path> --json | resources --json | resource-index <path> --json | asset-index <path> --json | pokemon-catalog <path> --json | trainer-catalog <path> --json | validate <path> --json | maps <path> --json | map-visual <path> <map-id> --json | graphics <path> --json | graphics-import-plan <project> <package> --json | rom-graph <rom> --json | toolchain-health <path> --json | references --json | patch <patch> --json | patch-manifest <patch> [--base-rom <path>] --json | patch-manifest <project> <patch> [--base-rom <path>] --json | build <path> --json | playtest <path> --headless --json | playtest <path> --launch --json"
        case .unknownCommand(let command):
            return "Unknown command: \(command)"
        }
    }
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
