import Foundation
import PokemonHackCore

@MainActor
final class WorkbenchStore: ObservableObject {
    @Published var selection: WorkbenchModule = .dashboard
    @Published var selectedTargetID: BuildTarget.ID = "emerald-dev"
    @Published var selectedProjectID: IndexedProjectSummary.ID = ""
    @Published var selectedMapID: String = ""
    @Published var searchText = ""
    @Published private(set) var indexedProjects: [IndexedProjectSummary] = []
    @Published private(set) var projectIndexStatus: ProjectIndexLoadStatus = .idle
    @Published private(set) var selectedMapCatalog: MapCatalogViewState?
    @Published private(set) var mapCatalogStatus: MapCatalogLoadStatus = .idle
    @Published private(set) var recentProjectRoots: [String]

    let targets: [BuildTarget]
    let records: [WorkbenchRecord]
    let issues: [WorkbenchIssue]
    let buildSteps: [BuildStep]

    private let userDefaults: UserDefaults
    private let fileManager: FileManager
    private let workspaceRoot: URL
    private var projectIndexesByID: [String: PokemonHackCore.ProjectIndex] = [:]

    private static let recentRootsKey = "PokemonHackStudio.recentProjectRoots"

    init(
        userDefaults: UserDefaults = .standard,
        fileManager: FileManager = .default,
        autoLoadProjects: Bool = true
    ) {
        self.userDefaults = userDefaults
        self.fileManager = fileManager
        workspaceRoot = Self.inferredWorkspaceRoot()
        recentProjectRoots = userDefaults.stringArray(forKey: Self.recentRootsKey) ?? []

        targets = FixtureData.targets
        records = FixtureData.records
        issues = FixtureData.issues
        buildSteps = FixtureData.buildSteps

        if autoLoadProjects {
            refreshProjectIndexes()
        }
    }

    var selectedTarget: BuildTarget {
        targets.first { $0.id == selectedTargetID } ?? targets[0]
    }

    var selectedIndexedProject: IndexedProjectSummary? {
        indexedProjects.first { $0.id == selectedProjectID } ?? indexedProjects.first
    }

    var hasIndexedProjects: Bool {
        !indexedProjects.isEmpty
    }

    var issueCount: Int {
        selectedIndexedProject?.diagnosticCount ?? issues.count
    }

    func records(for module: WorkbenchModule) -> [WorkbenchRecord] {
        let moduleRecords = records.filter { $0.module == module }
        guard !searchText.isEmpty else { return moduleRecords }

        return moduleRecords.filter { record in
            record.title.localizedCaseInsensitiveContains(searchText)
                || record.subtitle.localizedCaseInsensitiveContains(searchText)
                || record.source.path.localizedCaseInsensitiveContains(searchText)
        }
    }

    func refreshProjectIndexes() {
        projectIndexStatus = .loading

        let roots = Self.uniquePaths(defaultProjectRoots() + recentProjectRoots)
        var summaries: [IndexedProjectSummary] = []
        var indexes: [String: PokemonHackCore.ProjectIndex] = [:]

        for root in roots {
            guard fileManager.fileExists(atPath: root) else { continue }

            do {
                let index = try GameAdapterRegistry.index(path: root, fileManager: fileManager)
                let summary = Self.summary(from: index)
                summaries.append(summary)
                indexes[summary.id] = index
            } catch {
                continue
            }
        }

        indexedProjects = summaries
        projectIndexesByID = indexes
        if !summaries.contains(where: { $0.id == selectedProjectID }) {
            selectedProjectID = summaries.first?.id ?? ""
        }
        refreshSelectedMapCatalog()
        projectIndexStatus = .loaded(summaries.count)
    }

    func openProject(at url: URL) {
        openProject(path: url.standardizedFileURL.path)
    }

    func openProject(path: String) {
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path

        do {
            let index = try GameAdapterRegistry.index(path: standardizedPath, fileManager: fileManager)
            let summary = Self.summary(from: index)
            projectIndexesByID[summary.id] = index
            upsert(summary)
            rememberRecentRoot(standardizedPath)
            selectedProjectID = summary.id
            refreshSelectedMapCatalog()
            projectIndexStatus = .loaded(indexedProjects.count)
        } catch {
            projectIndexStatus = .failed(error.localizedDescription)
        }
    }

    private func upsert(_ summary: IndexedProjectSummary) {
        if let index = indexedProjects.firstIndex(where: { $0.id == summary.id }) {
            indexedProjects[index] = summary
        } else {
            indexedProjects.insert(summary, at: 0)
        }
    }

    private func rememberRecentRoot(_ path: String) {
        let roots = Array(Self.uniquePaths([path] + recentProjectRoots).prefix(8))
        recentProjectRoots = roots
        userDefaults.set(roots, forKey: Self.recentRootsKey)
    }

    func refreshSelectedMapCatalog() {
        selectedMapCatalog = nil
        selectedMapID = ""
        mapCatalogStatus = selectedIndexedProject == nil ? .idle : .loading
    }

    func loadSelectedMapCatalogIfNeeded() {
        guard selectedMapCatalog == nil else { return }
        loadSelectedMapCatalog()
    }

    func loadSelectedMapCatalog() {
        guard let selectedIndexedProject else {
            selectedMapCatalog = nil
            selectedMapID = ""
            mapCatalogStatus = .idle
            return
        }

        mapCatalogStatus = .loading

        do {
            let index: PokemonHackCore.ProjectIndex
            if let retainedIndex = projectIndexesByID[selectedIndexedProject.id] {
                index = retainedIndex
            } else {
                index = try GameAdapterRegistry.index(path: selectedIndexedProject.rootPath, fileManager: fileManager)
                projectIndexesByID[selectedIndexedProject.id] = index
            }

            let catalog = try ProjectMapCatalogLoader.load(from: index, fileManager: fileManager)
            let viewState = Self.mapCatalogViewState(from: catalog, project: selectedIndexedProject)
            selectedMapCatalog = viewState
            if !viewState.maps.contains(where: { $0.id == selectedMapID }) {
                selectedMapID = viewState.maps.first?.id ?? ""
            }
            mapCatalogStatus = .loaded(viewState.mapCount)
        } catch {
            selectedMapCatalog = nil
            selectedMapID = ""
            mapCatalogStatus = .failed(error.localizedDescription)
        }
    }

    private func defaultProjectRoots() -> [String] {
        #if DEBUG
        ["pokeemerald", "pokefirered"]
            .map { workspaceRoot.appendingPathComponent($0).path }
            .filter { fileManager.fileExists(atPath: $0) }
        #else
        []
        #endif
    }

    private static func inferredWorkspaceRoot() -> URL {
        #if DEBUG
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 {
            root.deleteLastPathComponent()
        }
        return root.standardizedFileURL
        #else
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath).standardizedFileURL
        #endif
    }

    private static func uniquePaths(_ paths: [String]) -> [String] {
        var seen: Set<String> = []
        var unique: [String] = []

        for path in paths {
            let standardized = URL(fileURLWithPath: path).standardizedFileURL.path
            guard seen.insert(standardized).inserted else { continue }
            unique.append(standardized)
        }

        return unique
    }

    private static func summary(from index: PokemonHackCore.ProjectIndex) -> IndexedProjectSummary {
        let rootURL = URL(fileURLWithPath: index.root.path)
        let sourceSurfaces = index.documents.map { surface(from: $0) }
        let generatedOutputs = index.generatedOutputs.map { surface(from: $0) }
        let diagnostics = index.diagnostics.map { diagnostic(from: $0, rootPath: index.root.path) }
        let buildTargets = index.buildTargets.map { target in
            IndexedBuildTargetPreview(
                id: target.id,
                name: target.name,
                kind: target.kind.rawValue,
                command: target.command.joined(separator: " "),
                outputPath: target.outputPath
            )
        }
        let missingSourceDocuments = index.documents.filter { !$0.exists && $0.role == .source }.count
        let existingSourceDocuments = index.documents.filter(\.exists).count

        return IndexedProjectSummary(
            id: index.root.path,
            title: rootURL.lastPathComponent,
            subtitle: "\(index.adapterName) · \(index.profile.rawValue)",
            rootPath: index.root.path,
            profile: index.profile.rawValue,
            adapterName: index.adapterName,
            writePolicy: index.writePolicy.rawValue,
            status: status(for: diagnostics, missingSourceDocuments: missingSourceDocuments),
            sourceDocumentCount: index.documents.count,
            existingSourceDocumentCount: existingSourceDocuments,
            missingSourceDocumentCount: missingSourceDocuments,
            generatedOutputCount: index.generatedOutputs.count,
            artifactCount: index.generatedOutputs.filter { $0.role == .artifact }.count,
            diagnosticCount: diagnostics.count,
            buildTargetCount: buildTargets.count,
            sourceSurfaces: sourceSurfaces,
            generatedOutputs: generatedOutputs,
            diagnostics: diagnostics,
            buildTargets: buildTargets
        )
    }

    private static func surface(from document: SourceDocument) -> IndexedSourceSurface {
        let title = URL(fileURLWithPath: document.relativePath).lastPathComponent
        let displayTitle = title.isEmpty ? document.relativePath : title
        let role = document.role.rawValue
        let kind = document.kind.rawValue

        return IndexedSourceSurface(
            id: "\(role):\(document.relativePath)",
            title: displayTitle,
            subtitle: "\(kind) · \(role)",
            kind: kind,
            role: role,
            exists: document.exists,
            preservesUnknownFields: document.preservesUnknownFields,
            validation: document.exists || document.role != .source ? .valid : .warning,
            source: SourceLocation(path: document.relativePath, symbol: kind, line: 1)
        )
    }

    private static func diagnostic(
        from diagnostic: PokemonHackCore.Diagnostic,
        rootPath: String
    ) -> IndexedDiagnosticRow {
        let span = diagnostic.span
        let path = span?.relativePath ?? rootPath

        return IndexedDiagnosticRow(
            id: diagnostic.id,
            title: diagnostic.code,
            message: diagnostic.message,
            severity: validationState(for: diagnostic.severity),
            source: SourceLocation(path: path, symbol: diagnostic.code, line: span?.startLine ?? 1)
        )
    }

    private static func validationState(for severity: DiagnosticSeverity) -> ValidationState {
        switch severity {
        case .info:
            .valid
        case .warning:
            .warning
        case .error:
            .error
        }
    }

    private static func status(
        for diagnostics: [IndexedDiagnosticRow],
        missingSourceDocuments: Int
    ) -> ValidationState {
        if diagnostics.contains(where: { $0.severity == .error }) {
            return .error
        }

        if missingSourceDocuments > 0 || diagnostics.contains(where: { $0.severity == .warning }) {
            return .warning
        }

        return .valid
    }

    private static func mapCatalogViewState(
        from catalog: PokemonHackCore.ProjectMapCatalog,
        project: IndexedProjectSummary
    ) -> MapCatalogViewState {
        let layoutSlotsByIndex = Dictionary(uniqueKeysWithValues: catalog.layoutSlots.map { ($0.slotIndex, $0) })
        let maps = catalog.maps.map { map in
            mapSummary(from: map, layoutSlot: map.layoutSlotIndex.flatMap { layoutSlotsByIndex[$0] })
        }
        let mapsByID = Dictionary(uniqueKeysWithValues: maps.map { ($0.name, $0.id) })
        let groups = catalog.mapGroups.map { group in
            MapGroupViewState(
                id: group.id,
                name: group.id,
                mapCount: group.mapNames.count,
                mapIDs: group.mapNames.compactMap { mapsByID[$0] }
            )
        }

        return MapCatalogViewState(
            id: catalog.id,
            projectTitle: project.title,
            rootPath: catalog.rootPath,
            groupCount: catalog.mapGroups.count,
            mapCount: catalog.maps.count,
            layoutCount: catalog.layoutSlots.filter { !$0.isEmpty }.count,
            diagnostics: catalog.diagnostics.map { diagnostic(from: $0, rootPath: catalog.rootPath) },
            groups: groups,
            maps: maps
        )
    }

    private static func mapSummary(
        from map: PokemonHackCore.MapDescriptor,
        layoutSlot: PokemonHackCore.LayoutSlot?
    ) -> MapSummaryViewState {
        MapSummaryViewState(
            id: map.id,
            mapID: map.id,
            name: map.name,
            groupName: map.groupID ?? "Ungrouped",
            source: SourceLocation(path: map.sourcePath, symbol: map.id, line: 1),
            layout: layoutSlot.map(layout(from:)),
            music: map.music,
            mapType: map.mapType,
            weather: map.weather,
            regionMapSection: map.regionMapSection,
            eventCounts: MapEventCountViewState(
                objectEvents: map.eventCounts.objectEvents,
                warpEvents: map.eventCounts.warpEvents,
                coordEvents: map.eventCounts.coordEvents,
                bgEvents: map.eventCounts.bgEvents
            ),
            connections: map.connections.map { connection in
                MapConnectionViewState(
                    id: connection.id,
                    direction: connection.direction ?? "connection",
                    map: connection.map ?? "Unknown map",
                    offset: connection.offset ?? 0
                )
            },
            notes: mapNotes(from: map)
        )
    }

    private static func layout(from slot: PokemonHackCore.LayoutSlot) -> MapLayoutViewState {
        MapLayoutViewState(
            id: slot.layoutID ?? slot.id,
            name: slot.name ?? "Empty layout slot \(slot.slotIndex)",
            width: slot.width ?? 0,
            height: slot.height ?? 0,
            primaryTileset: slot.primaryTileset,
            secondaryTileset: slot.secondaryTileset,
            borderFilepath: slot.borderFilepath,
            blockdataFilepath: slot.blockdataFilepath,
            blockPreview: slot.blockdataPreview.map(blockPreview(from:))
        )
    }

    private static func blockPreview(
        from preview: PokemonHackCore.LayoutBlockdataPreview
    ) -> LayoutBlockPreviewViewState {
        let visibleWidth = min(preview.width, 24)
        let rowsAvailable = Int(ceil(Double(preview.metatileIDs.count) / Double(max(preview.width, 1))))
        let visibleHeight = min(preview.height, max(1, rowsAvailable), 18)

        return LayoutBlockPreviewViewState(
            width: preview.width,
            height: preview.height,
            visibleWidth: visibleWidth,
            visibleHeight: visibleHeight,
            metatileIDs: preview.metatileIDs.map(Int.init),
            isComplete: !preview.isCapped && preview.isByteCountValid,
            diagnostic: blockPreviewDiagnostic(preview)
        )
    }

    private static func blockPreviewDiagnostic(
        _ preview: PokemonHackCore.LayoutBlockdataPreview
    ) -> String? {
        if !preview.isByteCountValid {
            return "\(preview.actualByteCount) bytes, expected \(preview.expectedByteCount)"
        }
        if preview.isCapped {
            return "preview capped at \(preview.maxMetatileCount) metatiles"
        }
        return nil
    }

    private static func mapNotes(from map: PokemonHackCore.MapDescriptor) -> [String] {
        var notes: [String] = []
        if map.connectionsNoInclude {
            notes.append("Connections are declared without a generated include.")
        }
        if let sharedEventsMap = map.sharedEventsMap {
            notes.append("Shares events with \(sharedEventsMap).")
        }
        if let sharedScriptsMap = map.sharedScriptsMap {
            notes.append("Shares scripts with \(sharedScriptsMap).")
        }
        return notes
    }
}

private enum FixtureData {
    static let targets = [
        BuildTarget(id: "emerald-dev", name: "Emerald Dev", romBase: "Pokemon Emerald"),
        BuildTarget(id: "firered-lab", name: "FireRed Lab", romBase: "Pokemon FireRed"),
        BuildTarget(id: "emerald-release", name: "Emerald Release", romBase: "Pokemon Emerald")
    ]

    static let records = [
        WorkbenchRecord(
            title: "Littleroot Town",
            subtitle: "Outdoor layout with 4 warps, 7 objects, 2 signposts",
            module: .maps,
            source: SourceLocation(path: "data/maps/LittlerootTown/map.json", symbol: "MAP_LITTLEROOT_TOWN", line: 1),
            validation: .warning,
            isDirty: true,
            tags: ["layout", "events", "warps"],
            facts: [
                Fact(label: "Layout", value: "LittlerootTown"),
                Fact(label: "Tileset", value: "General / Petalburg"),
                Fact(label: "Connections", value: "Route 101 north")
            ],
            notes: ["Object 5 has a pending script pointer review.", "Preview is fixture-only and does not write map JSON."]
        ),
        WorkbenchRecord(
            title: "Route 110 Rival",
            subtitle: "May/Brendan trainer battle variants",
            module: .trainers,
            source: SourceLocation(path: "src/data/trainers.h", symbol: "TRAINER_MAY_ROUTE110", line: 1847),
            validation: .valid,
            isDirty: false,
            tags: ["party", "ai", "battle"],
            facts: [
                Fact(label: "Class", value: "Pokemon Trainer"),
                Fact(label: "AI", value: "Check bad move / Try status"),
                Fact(label: "Party", value: "3 mons, starter branch")
            ],
            notes: ["Party preview groups source variants side by side."]
        ),
        WorkbenchRecord(
            title: "Mach Bike",
            subtitle: "Key item with overworld use callback",
            module: .items,
            source: SourceLocation(path: "src/data/items.h", symbol: "ITEM_MACH_BIKE", line: 732),
            validation: .warning,
            isDirty: true,
            tags: ["key item", "field use"],
            facts: [
                Fact(label: "Price", value: "0"),
                Fact(label: "Pocket", value: "Key Items"),
                Fact(label: "Use", value: "ItemUseOutOfBattle_MachBike")
            ],
            notes: ["Dirty badge represents staged mock edits only."]
        ),
        WorkbenchRecord(
            title: "Treecko",
            subtitle: "Species base stats and evolution table links",
            module: .pokemon,
            source: SourceLocation(path: "src/data/pokemon/species_info.h", symbol: "SPECIES_TREECKO", line: 2771),
            validation: .valid,
            isDirty: false,
            tags: ["base stats", "abilities", "evolution"],
            facts: [
                Fact(label: "BST", value: "310"),
                Fact(label: "Abilities", value: "Overgrow / Unburden"),
                Fact(label: "Growth", value: "Medium Slow")
            ],
            notes: ["Source links show the table row the editor would jump to."]
        ),
        WorkbenchRecord(
            title: "Route 102 Grass",
            subtitle: "Morning grass slots and level bands",
            module: .encounters,
            source: SourceLocation(path: "src/data/wild_encounters.json", symbol: "Route102_LandMons", line: 418),
            validation: .error,
            isDirty: true,
            tags: ["land", "levels", "rates"],
            facts: [
                Fact(label: "Encounter Rate", value: "20%"),
                Fact(label: "Slots", value: "12"),
                Fact(label: "Level Range", value: "3-5")
            ],
            notes: ["Slot 8 references a species not enabled for this target."]
        ),
        WorkbenchRecord(
            title: "Professor Birch Intro",
            subtitle: "Initial scene script and text branches",
            module: .scripts,
            source: SourceLocation(path: "data/scripts/new_game.inc", symbol: "NewGame_BirchSpeech", line: 42),
            validation: .warning,
            isDirty: false,
            tags: ["script", "movement", "text"],
            facts: [
                Fact(label: "Commands", value: "31"),
                Fact(label: "Text refs", value: "6"),
                Fact(label: "Labels", value: "4")
            ],
            notes: ["Command list is displayed as a read-only source outline."]
        ),
        WorkbenchRecord(
            title: "Birch Bag Prompt",
            subtitle: "Localized string for starter bag interaction",
            module: .text,
            source: SourceLocation(path: "data/text/birch.inc", symbol: "gText_BirchBagPrompt", line: 118),
            validation: .valid,
            isDirty: true,
            tags: ["string", "event text"],
            facts: [
                Fact(label: "Length", value: "82 chars"),
                Fact(label: "References", value: "2 scripts"),
                Fact(label: "Control Codes", value: "PLAYER, PAUSE")
            ],
            notes: ["Text editor shows control-code awareness without changing source files."]
        )
    ]

    static let issues = [
        WorkbenchIssue(
            title: "Encounter species gated from target",
            severity: .error,
            source: SourceLocation(path: "src/data/wild_encounters.json", symbol: "Route102_LandMons[8]", line: 447),
            message: "Selected species is not available in Emerald Dev target flags."
        ),
        WorkbenchIssue(
            title: "Object script pointer needs review",
            severity: .warning,
            source: SourceLocation(path: "data/maps/LittlerootTown/events.inc", symbol: "LittlerootTown_EventScript_Object5", line: 93),
            message: "Map event points to a script label outside the current source folder."
        ),
        WorkbenchIssue(
            title: "Item field use callback has no mock preview",
            severity: .warning,
            source: SourceLocation(path: "src/data/items.h", symbol: "ITEM_MACH_BIKE", line: 746),
            message: "Workbench can display the callback symbol but not its field behavior yet."
        )
    ]

    static let buildSteps = [
        BuildStep(
            name: "Scan source tree",
            status: .valid,
            detail: "pokeemerald headers, data tables, scripts, and map JSON discovered.",
            source: SourceLocation(path: "Makefile", symbol: "all", line: 1)
        ),
        BuildStep(
            name: "Validate fixtures",
            status: .warning,
            detail: "3 warnings and 1 error are shown in the Issues module.",
            source: SourceLocation(path: "tools/studio/mock_validation.json", symbol: "FixtureValidation", line: 1)
        ),
        BuildStep(
            name: "Build ROM",
            status: .valid,
            detail: "Mock target output: build/emerald-dev/pokeemerald.gba",
            source: SourceLocation(path: "Makefile", symbol: "pokeemerald.gba", line: 191)
        )
    ]
}
