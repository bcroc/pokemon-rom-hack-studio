import Foundation

public struct BinaryROMInspectorReport: Codable, Equatable {
    public let projectIndex: ProjectIndex
    public let graph: BinaryROMGraph
    public let resourceEntry: GenIIIResourceEntry
    public let assetCatalog: GenIIIAssetCatalog
    public let playtestReport: PlaytestHandoffReport
    public let diagnostics: [Diagnostic]
    public let isReadOnly: Bool

    public init(
        projectIndex: ProjectIndex,
        graph: BinaryROMGraph,
        resourceEntry: GenIIIResourceEntry,
        assetCatalog: GenIIIAssetCatalog,
        playtestReport: PlaytestHandoffReport,
        diagnostics: [Diagnostic],
        isReadOnly: Bool = true
    ) {
        self.projectIndex = projectIndex
        self.graph = graph
        self.resourceEntry = resourceEntry
        self.assetCatalog = assetCatalog
        self.playtestReport = playtestReport
        self.diagnostics = diagnostics
        self.isReadOnly = isReadOnly
    }
}

public enum BinaryROMInspectorReportBuilder {
    public static func build(
        path: String,
        fileManager: FileManager = .default,
        toolResolver: ToolAvailabilityResolver = ToolAvailabilityResolverFactory.pathEnvironment()
    ) throws -> BinaryROMInspectorReport {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        let index = try GameAdapterRegistry.index(path: url.path, fileManager: fileManager)
        guard index.profile == .binaryROM else {
            throw PokemonHackCoreError.unsupportedProject(url.path)
        }

        let data = try Data(contentsOf: url)
        let graph = BinaryROMGraphBuilder.build(path: url.path, data: data)
        let resourceEntry = GenIIIResourceRegistry.resourceIndex(path: url.path, fileManager: fileManager)
        let assetCatalog = GenIIIAssetCatalogBuilder.build(
            index: index,
            resourceEntry: resourceEntry,
            fileManager: fileManager
        )
        let playtestReport = PlaytestHandoffReportBuilder.build(
            index: index,
            mode: .headless,
            fileManager: fileManager,
            toolResolver: toolResolver
        )
        let diagnostics = index.diagnostics
            + graph.diagnostics
            + resourceEntry.diagnostics
            + assetCatalog.diagnostics
            + playtestReport.diagnostics

        return BinaryROMInspectorReport(
            projectIndex: index,
            graph: graph,
            resourceEntry: resourceEntry,
            assetCatalog: assetCatalog,
            playtestReport: playtestReport,
            diagnostics: diagnostics
        )
    }
}
