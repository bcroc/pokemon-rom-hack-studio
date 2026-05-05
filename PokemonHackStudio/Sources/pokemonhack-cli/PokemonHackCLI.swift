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
        case "validate":
            return try validate(arguments: Array(arguments.dropFirst()))
        case "maps":
            return try maps(arguments: Array(arguments.dropFirst()))
        case "references":
            return try references(arguments: Array(arguments.dropFirst()))
        case "patch":
            return try patch(arguments: Array(arguments.dropFirst()))
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

    private static func validate(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        let index = try GameAdapterRegistry.index(path: path)
        return try encode(ValidationReport(index: index))
    }

    private static func maps(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        let index = try GameAdapterRegistry.index(path: path)
        return try encode(ProjectMapCatalogLoader.load(from: index))
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
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try encode(PatchParser.parseSummary(data: data))
    }

    private static func build(arguments: [String]) throws -> String {
        guard arguments.count == 2, let path = arguments.first, arguments.last == "--json" else {
            throw CLIError.usage
        }
        let index = try GameAdapterRegistry.index(path: path)
        return try encode(BuildPlanSummary(index: index))
    }

    private static func playtest(arguments: [String]) throws -> String {
        guard arguments.count == 3, let path = arguments.first, arguments[1] == "--headless", arguments[2] == "--json" else {
            throw CLIError.usage
        }
        let index = try GameAdapterRegistry.index(path: path)
        let session = PlaytestSession(
            mode: .headless,
            romPath: index.buildTargets.first(where: { $0.outputPath?.hasSuffix(".gba") == true })?.outputPath,
            arguments: ["--headless"],
            isRunnable: false,
            diagnostics: [
                Diagnostic(
                    severity: .info,
                    code: "PLAYTEST_PLAN_ONLY",
                    message: "Headless playtest is planned but external emulator execution is not invoked by this command."
                )
            ]
        )
        return try encode(session)
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
            return "Usage: pokemonhack-cli inspect <path> --json | index <path> --json | validate <path> --json | maps <path> --json | references --json | patch <patch> --json | build <path> --json | playtest <path> --headless --json"
        case .unknownCommand(let command):
            return "Unknown command: \(command)"
        }
    }
}

struct ValidationReport: Encodable {
    let adapterID: String
    let profile: GameProfile
    let issueCount: Int
    let diagnostics: [Diagnostic]

    init(index: ProjectIndex) {
        adapterID = index.adapterID
        profile = index.profile
        issueCount = index.diagnostics.count
        diagnostics = index.diagnostics
    }
}

struct BuildPlanSummary: Encodable {
    let adapterID: String
    let profile: GameProfile
    let targets: [BuildTarget]

    init(index: ProjectIndex) {
        adapterID = index.adapterID
        profile = index.profile
        targets = index.buildTargets
    }
}
