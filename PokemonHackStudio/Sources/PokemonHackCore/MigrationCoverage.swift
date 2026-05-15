import Foundation

public enum MigrationCoverageDomain: String, Codable, Equatable, CaseIterable, Sendable {
    case species
    case moves
    case items
    case trainers
    case maps
    case scripts
    case text
    case encounters
    case sprites
    case icons
    case footprints
    case cries
    case forms
    case pokedex
    case evolutions
    case graphics
    case palettes
    case audio
    case patches
    case build
    case binaryBlocks
    case ndsContainers
    case ndsTextBanks
    case gameCubeResources
    case expansionData
}

public enum MigrationCoverageStatus: String, Codable, Equatable, CaseIterable, Sendable {
    case sourceFirstEditable
    case sourceFirstReadOnly
    case previewOnly
    case migrationPlanOnly
    case binaryOnlyBlocked
    case blocked
    case externalToolOnly
}

public struct MigrationCoverageEntry: Codable, Equatable, Identifiable {
    public var id: String { domain.rawValue }

    public let domain: MigrationCoverageDomain
    public let title: String
    public let status: MigrationCoverageStatus
    public let currentSurface: String
    public let sourcePath: String?
    public let migrationTarget: String?
    public let recommendedFutureRow: String?
    public let supportedActions: [String]
    public let blockedActions: [String]
    public let referenceDrivers: [String]
    public let diagnostics: [Diagnostic]

    public init(
        domain: MigrationCoverageDomain,
        title: String,
        status: MigrationCoverageStatus,
        currentSurface: String,
        sourcePath: String? = nil,
        migrationTarget: String? = nil,
        recommendedFutureRow: String? = nil,
        supportedActions: [String],
        blockedActions: [String],
        referenceDrivers: [String],
        diagnostics: [Diagnostic] = []
    ) {
        self.domain = domain
        self.title = title
        self.status = status
        self.currentSurface = currentSurface
        self.sourcePath = sourcePath
        self.migrationTarget = migrationTarget
        self.recommendedFutureRow = recommendedFutureRow
        self.supportedActions = supportedActions
        self.blockedActions = blockedActions
        self.referenceDrivers = referenceDrivers
        self.diagnostics = diagnostics
    }
}

public struct MigrationCoverageSummary: Codable, Equatable {
    public let entryCount: Int
    public let sourceFirstEditableCount: Int
    public let sourceFirstReadOnlyCount: Int
    public let previewOnlyCount: Int
    public let migrationPlanOnlyCount: Int
    public let binaryOnlyBlockedCount: Int
    public let blockedCount: Int
    public let externalToolOnlyCount: Int

    public init(entries: [MigrationCoverageEntry]) {
        entryCount = entries.count
        sourceFirstEditableCount = entries.filter { $0.status == .sourceFirstEditable }.count
        sourceFirstReadOnlyCount = entries.filter { $0.status == .sourceFirstReadOnly }.count
        previewOnlyCount = entries.filter { $0.status == .previewOnly }.count
        migrationPlanOnlyCount = entries.filter { $0.status == .migrationPlanOnly }.count
        binaryOnlyBlockedCount = entries.filter { $0.status == .binaryOnlyBlocked }.count
        blockedCount = entries.filter { $0.status == .blocked }.count
        externalToolOnlyCount = entries.filter { $0.status == .externalToolOnly }.count
    }
}

public struct MigrationCoverageReport: Codable, Equatable {
    public let root: SourceLocation
    public let profile: GameProfile
    public let platform: GamePlatform
    public let projectKind: ProjectKind
    public let summary: MigrationCoverageSummary
    public let entries: [MigrationCoverageEntry]
    public let diagnostics: [Diagnostic]
    public let referenceDrivers: [String]
    public let isReadOnly: Bool

    public init(
        root: SourceLocation,
        profile: GameProfile,
        platform: GamePlatform,
        projectKind: ProjectKind,
        entries: [MigrationCoverageEntry],
        diagnostics: [Diagnostic],
        referenceDrivers: [String],
        isReadOnly: Bool = true
    ) {
        self.root = root
        self.profile = profile
        self.platform = platform
        self.projectKind = projectKind
        self.summary = MigrationCoverageSummary(entries: entries)
        self.entries = entries
        self.diagnostics = diagnostics
        self.referenceDrivers = referenceDrivers
        self.isReadOnly = isReadOnly
    }
}

public enum MigrationCoverageReportBuilder {
    public static func build(path: String, fileManager: FileManager = .default) throws -> MigrationCoverageReport {
        try build(index: GameAdapterRegistry.index(path: path, fileManager: fileManager), fileManager: fileManager)
    }

    public static func build(index: ProjectIndex, fileManager: FileManager = .default) -> MigrationCoverageReport {
        let entries: [MigrationCoverageEntry]
        let extraDiagnostics: [Diagnostic]

        switch index.profile.platform {
        case .gba:
            let result = gbaEntries(index: index, fileManager: fileManager)
            entries = result.entries
            extraDiagnostics = result.diagnostics
        case .nds:
            let result = ndsEntries(index: index, fileManager: fileManager)
            entries = result.entries
            extraDiagnostics = result.diagnostics
        case .gameCube:
            entries = gameCubeEntries(index: index)
            extraDiagnostics = []
        case .unknown:
            entries = unknownEntries(index: index)
            extraDiagnostics = [
                Diagnostic(
                    severity: .warning,
                    code: "MIGRATION_COVERAGE_UNKNOWN_PROFILE",
                    message: "Migration coverage is limited because PokemonHackStudio could not identify this input profile."
                )
            ]
        }

        let diagnostics = index.diagnostics + extraDiagnostics + entries.flatMap(\.diagnostics)
        return MigrationCoverageReport(
            root: index.root,
            profile: index.profile,
            platform: index.platform,
            projectKind: index.projectKind,
            entries: entries.sorted { $0.domain.rawValue < $1.domain.rawValue },
            diagnostics: diagnostics,
            referenceDrivers: referenceDrivers(for: index.profile)
        )
    }

    private static func gbaEntries(
        index: ProjectIndex,
        fileManager: FileManager
    ) -> (entries: [MigrationCoverageEntry], diagnostics: [Diagnostic]) {
        switch index.profile {
        case .binaryROM:
            return (binaryGBAEntries(index: index), [])
        case .pokeemerald, .pokefirered, .pokeruby, .pokeemeraldExpansion:
            var diagnostics: [Diagnostic] = []
            var entries = sourceFirstGBAEntries(index: index)
            if let compatibility = try? PokemonDataCompatibilityReportBuilder.build(index: index, fileManager: fileManager) {
                entries.append(contentsOf: compatibilityEntries(from: compatibility))
                diagnostics.append(contentsOf: compatibility.diagnostics)
            } else {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "MIGRATION_COVERAGE_COMPATIBILITY_UNAVAILABLE",
                        message: "Pokemon data compatibility could not be loaded; source-first migration coverage falls back to project-level surfaces."
                    )
                )
                entries.append(contentsOf: fallbackPokemonEntries(index: index))
            }
            return (deduplicate(entries: entries), diagnostics)
        default:
            return (unknownEntries(index: index), [])
        }
    }

    private static func sourceFirstGBAEntries(index: ProjectIndex) -> [MigrationCoverageEntry] {
        [
            entry(
                .maps,
                "Maps, Layouts, Events, And Encounters",
                .sourceFirstEditable,
                surface: "maps, map-visual, map mutation plans",
                sourcePath: "data/maps, data/layouts",
                target: "source-tree map JSON, layouts, blockdata, and event sources",
                row: "PHS-T77",
                supported: ["read catalog", "preview mutations", "apply supported map edits"],
                blocked: ["new map duplication apply", "visual export writer"],
                refs: ["pret__pokeemerald", "pret__pokefirered", "pret__pokeruby", "huderlem__porymap"]
            ),
            entry(
                .scripts,
                "Native Scripts And Text",
                .sourceFirstReadOnly,
                surface: "script-outline, script-readiness, map-local script mutation plans",
                sourcePath: "data/maps/**/scripts.inc",
                target: "native script source with shared-script planning",
                row: "PHS-T84",
                supported: ["outline labels", "stage map-local script helper output"],
                blocked: ["project-wide shared script command apply", "generated .inc rewrites"],
                refs: ["pret__pokeemerald", "huderlem__poryscript", "porylive__porylive"]
            ),
            entry(
                .graphics,
                "Tilesets, Metatiles, Palettes, And Package Imports",
                .sourceFirstEditable,
                surface: "graphics, graphics-import-plan, graphics mutation plans",
                sourcePath: "graphics/**",
                target: "source-backed palettes/metatile files and later sprite package imports",
                row: "PHS-T75",
                supported: ["diagnose graphics", "preview packages", "apply supported palette/metatile edits"],
                blocked: ["bulk package copy", "conversion execution", "trainer sprite import"],
                refs: ["grunt-lucas__porytiles", "loxed__porypal", "gbadev-org__libtonc", "blocksds__grit"]
            ),
            entry(
                .patches,
                "Patch Apply And ROM Export",
                .previewOnly,
                surface: "patch-manifest, patch-artifact-plan, rom-diff-preview",
                target: "ignored .pokemonhackstudio/patches outputs",
                row: "PHS-T73",
                supported: ["parse patches", "preview checksum/header policy", "preview binary diffs"],
                blocked: ["patch apply", "ROM export", "header repair"],
                refs: ["marcrobledo__rompatcher.js", "pret__berry-fix", "mgba-emu__mgba"]
            ),
            entry(
                .binaryBlocks,
                "Binary-Only Blocks And Repointing",
                .previewOnly,
                surface: "rom-graph, rom-inspect, rom-diff-preview",
                target: "binary-only hacks when no source-tree path exists",
                row: "PHS-T79",
                supported: ["inspect runs", "preview pointers", "preview free space"],
                blocked: ["byte writes", "repoint apply", "free-space allocation"],
                refs: ["haven1433__hexmaniacadvance", "gamer2020__pokemongameeditor", "merilec__frame"]
            ),
            entry(
                .build,
                "Build And Playtest",
                index.buildTargets.isEmpty ? .previewOnly : .sourceFirstEditable,
                surface: "build, toolchain-health, playtest",
                target: "declared decomp make targets and external mGBA handoff",
                supported: index.buildTargets.isEmpty ? ["readiness report"] : ["run selected make target", "launch runnable mGBA handoff", "capture screenshot/savestate"],
                blocked: ["arbitrary commands", "patch export", "conversion execution"],
                refs: ["pret__agbcc", "mgba-emu__mgba", "visualboyadvance-m__visualboyadvance-m", "tasemulators__bizhawk"]
            )
        ]
    }

    private static func compatibilityEntries(from report: PokemonDataCompatibilityReport) -> [MigrationCoverageEntry] {
        report.entries.map { compatibility in
            let domain = migrationDomain(for: compatibility.surface)
            return entry(
                domain,
                title(for: compatibility.surface),
                migrationStatus(for: compatibility.status),
                surface: "pokemon-compatibility",
                sourcePath: compatibility.sourcePath,
                target: migrationTarget(for: compatibility.surface, profile: compatibility.profile),
                row: compatibility.recommendedFutureRow,
                supported: supportedActions(for: compatibility),
                blocked: blockedActions(for: compatibility),
                refs: referenceDrivers(for: compatibility.profile) + legacyReferenceDrivers(for: compatibility.surface),
                diagnostics: compatibility.diagnostics
            )
        }
    }

    private static func binaryGBAEntries(index: ProjectIndex) -> [MigrationCoverageEntry] {
        let blockedDomains: [MigrationCoverageDomain] = [.species, .moves, .items, .trainers, .pokedex, .evolutions, .cries, .forms]
        var entries = blockedDomains.map {
            entry(
                $0,
                title(for: $0),
                .binaryOnlyBlocked,
                surface: "rom-inspect",
                target: "source-tree migration before editing",
                row: "PHS-T93",
                supported: ["read-only ROM inspection"],
                blocked: ["source writes", "binary table edits", "asset export"],
                refs: ["haven1433__hexmaniacadvance", "gamer2020__pokemongameeditor", "ayashibox__pkmn-rom-extract"]
            )
        }
        entries.append(
            entry(
                .graphics,
                "ROM Graphics And Asset Families",
                .migrationPlanOnly,
                surface: "rom-inspect",
                target: "source-tree graphics package migration plan",
                row: "PHS-T92",
                supported: ["read-only ROM graph", "asset-family planning"],
                blocked: ["asset extraction", "conversion", "source write"],
                refs: ["ayashibox__pkmn-rom-extract", "loxed__porypal", "blocksds__grit"]
            )
        )
        entries.append(
            entry(
                .binaryBlocks,
                "Binary-Only Blocks And Repointing",
                .previewOnly,
                surface: "rom-graph, rom-diff-preview",
                target: "manifested binary mutation plan",
                row: "PHS-T79",
                supported: ["inspect byte ranges", "preview pointer candidates", "preview free space"],
                blocked: ["byte writes", "repoint apply", "ROM export"],
                refs: ["haven1433__hexmaniacadvance", "merilec__frame"]
            )
        )
        return entries
    }

    private static func ndsEntries(
        index: ProjectIndex,
        fileManager: FileManager
    ) -> (entries: [MigrationCoverageEntry], diagnostics: [Diagnostic]) {
        var diagnostics: [Diagnostic] = []
        var entries = sourceFirstNDSBaseline(index: index)
        if let catalog = try? NDSDataCatalogBuilder.build(path: index.root.path, fileManager: fileManager) {
            entries.append(contentsOf: ndsCatalogEntries(catalog))
            diagnostics.append(contentsOf: catalog.diagnostics)
        } else {
            diagnostics.append(
                Diagnostic(
                    severity: .warning,
                    code: "MIGRATION_COVERAGE_NDS_CATALOG_UNAVAILABLE",
                    message: "NDS data catalog could not be loaded; migration coverage falls back to project-level NDS surfaces."
                )
            )
        }
        return (deduplicate(entries: entries), diagnostics)
    }

    private static func sourceFirstNDSBaseline(index: ProjectIndex) -> [MigrationCoverageEntry] {
        [
            entry(
                .ndsContainers,
                "NDS Containers And NitroFS",
                .migrationPlanOnly,
                surface: "nds-inspect, nds-data-catalog",
                target: "source-tree or extracted-directory migration plan",
                row: "PHS-T92",
                supported: ["header facts", "NitroFS listing", "NARC/member fingerprints", "migration candidates"],
                blocked: ["extraction", "decompression", "NARC rebuild", "ROM export"],
                refs: ["roadrunnerwmc__ndspy", "ds-pokemon-rom-editor__dspre", "r-yatian__tinkedsi"]
            ),
            entry(
                .build,
                "NDS Build And Playtest",
                .externalToolOnly,
                surface: "toolchain-health",
                target: "manual external build/emulator workflow",
                supported: ["manual setup guidance", "declared output checks"],
                blocked: ["run make", "run Docker", "launch melonDS/DeSmuME", "ROM export"],
                refs: ["devkitpro__buildscripts", "devkitpro__libgba", "melonds-emu__melonds", "tasemulators__desmume"]
            )
        ]
    }

    private static func ndsCatalogEntries(_ catalog: ProjectNDSDataCatalog) -> [MigrationCoverageEntry] {
        catalog.summary.domainCounts.compactMap { count in
            guard count.count > 0 else { return nil }
            let domain = migrationDomain(for: count.domain)
            let hasMigrationPlan = catalog.records.contains { $0.domain == count.domain && $0.migrationPlan != nil }
            let editableCount = catalog.records.filter { record in
                record.domain == count.domain && record.role == .sourceTree && [.json, .csv, .text, .cSource, .cHeader].contains(record.format)
            }.count
            let status: MigrationCoverageStatus
            if hasMigrationPlan {
                status = .migrationPlanOnly
            } else if editableCount > 0 && catalog.profile == .pokeplatinum {
                status = .sourceFirstEditable
            } else if count.domain == .resources {
                status = .previewOnly
            } else {
                status = .sourceFirstReadOnly
            }
            return entry(
                domain,
                "NDS \(title(for: domain))",
                status,
                surface: "nds-data-catalog",
                target: "source-backed Gen IV data catalog",
                row: status == .sourceFirstEditable ? "PHS-T98" : "PHS-T93",
                supported: ["catalog \(count.count) records", "show readiness", "show related rows"],
                blocked: ["ROM writes", "NARC rebuild", "generated/reference row edits"],
                refs: referenceDrivers(for: catalog.profile) + ["roadrunnerwmc__ndspy", "garhoogin__nitropaint"]
            )
        }
    }

    private static func gameCubeEntries(index: ProjectIndex) -> [MigrationCoverageEntry] {
        [
            entry(
                .gameCubeResources,
                "GameCube Disc And FSYS Resources",
                .previewOnly,
                surface: "resource-index",
                target: "read-only disc/archive inventory",
                supported: ["disc header", "FST rows", "FSYS/LZSS inventory"],
                blocked: ["extraction", "conversion", "disc export"],
                refs: ["PkmGCTools", "public FSYS notes"]
            )
        ]
    }

    private static func unknownEntries(index: ProjectIndex) -> [MigrationCoverageEntry] {
        [
            entry(
                .binaryBlocks,
                "Unknown Input",
                .blocked,
                surface: "inspect",
                target: "supported source tree or local ROM input",
                supported: ["profile detection diagnostics"],
                blocked: ["migration planning", "source writes", "binary writes"],
                refs: []
            )
        ]
    }

    private static func fallbackPokemonEntries(index: ProjectIndex) -> [MigrationCoverageEntry] {
        [.species, .moves, .items, .trainers, .pokedex, .evolutions].map {
            entry(
                $0,
                title(for: $0),
                .sourceFirstReadOnly,
                surface: "source-index",
                target: "source-backed Pokemon data editor",
                row: "PHS-T57",
                supported: ["source index when descriptors are available"],
                blocked: ["migration coverage details unavailable"],
                refs: referenceDrivers(for: index.profile)
            )
        }
    }

    private static func deduplicate(entries: [MigrationCoverageEntry]) -> [MigrationCoverageEntry] {
        var byDomain: [MigrationCoverageDomain: MigrationCoverageEntry] = [:]
        for entry in entries {
            if let existing = byDomain[entry.domain] {
                byDomain[entry.domain] = preferred(entry, over: existing)
            } else {
                byDomain[entry.domain] = entry
            }
        }
        return Array(byDomain.values)
    }

    private static func preferred(_ candidate: MigrationCoverageEntry, over existing: MigrationCoverageEntry) -> MigrationCoverageEntry {
        score(candidate.status) >= score(existing.status) ? candidate : existing
    }

    private static func score(_ status: MigrationCoverageStatus) -> Int {
        switch status {
        case .sourceFirstEditable: 6
        case .sourceFirstReadOnly: 5
        case .migrationPlanOnly: 4
        case .previewOnly: 3
        case .externalToolOnly: 2
        case .binaryOnlyBlocked: 1
        case .blocked: 0
        }
    }

    private static func entry(
        _ domain: MigrationCoverageDomain,
        _ title: String,
        _ status: MigrationCoverageStatus,
        surface: String,
        sourcePath: String? = nil,
        target: String?,
        row: String? = nil,
        supported: [String],
        blocked: [String],
        refs: [String],
        diagnostics: [Diagnostic] = []
    ) -> MigrationCoverageEntry {
        MigrationCoverageEntry(
            domain: domain,
            title: title,
            status: status,
            currentSurface: surface,
            sourcePath: sourcePath,
            migrationTarget: target,
            recommendedFutureRow: row,
            supportedActions: supported,
            blockedActions: blocked,
            referenceDrivers: Array(Set(refs)).sorted(),
            diagnostics: diagnostics
        )
    }

    private static func migrationStatus(for status: PokemonDataCompatibilityStatus) -> MigrationCoverageStatus {
        switch status {
        case .editable:
            return .sourceFirstEditable
        case .indexed, .readOnly:
            return .sourceFirstReadOnly
        case .blocked:
            return .blocked
        }
    }

    private static func migrationDomain(for surface: PokemonDataCompatibilitySurface) -> MigrationCoverageDomain {
        switch surface {
        case .species: .species
        case .moves: .moves
        case .items: .items
        case .levelUpLearnsets, .tmhmLearnsets, .eggMoves, .tutorLearnsets: .moves
        case .evolutions: .evolutions
        case .pokedex: .pokedex
        case .assets: .sprites
        case .cries: .cries
        case .forms: .forms
        }
    }

    private static func migrationDomain(for domain: NDSDataDomain) -> MigrationCoverageDomain {
        switch domain {
        case .species, .personal: .species
        case .moves: .moves
        case .items: .items
        case .trainers: .trainers
        case .encounters: .encounters
        case .text: .ndsTextBanks
        case .scripts: .scripts
        case .maps: .maps
        case .resources: .ndsContainers
        }
    }

    private static func title(for surface: PokemonDataCompatibilitySurface) -> String {
        switch surface {
        case .species: "Pokemon Species"
        case .moves: "Moves"
        case .items: "Items"
        case .levelUpLearnsets: "Level-Up Learnsets"
        case .tmhmLearnsets: "TM/HM Learnsets"
        case .eggMoves: "Egg Moves"
        case .tutorLearnsets: "Tutor Learnsets"
        case .evolutions: "Evolutions"
        case .pokedex: "Pokedex"
        case .assets: "Pokemon Assets"
        case .cries: "Cries"
        case .forms: "Forms"
        }
    }

    private static func title(for domain: MigrationCoverageDomain) -> String {
        switch domain {
        case .species: "Pokemon Species"
        case .moves: "Moves And Learnsets"
        case .items: "Items"
        case .trainers: "Trainers"
        case .maps: "Maps"
        case .scripts: "Scripts"
        case .text: "Text"
        case .encounters: "Encounters"
        case .sprites: "Sprites"
        case .icons: "Icons"
        case .footprints: "Footprints"
        case .cries: "Cries"
        case .forms: "Forms"
        case .pokedex: "Pokedex"
        case .evolutions: "Evolutions"
        case .graphics: "Graphics"
        case .palettes: "Palettes"
        case .audio: "Audio"
        case .patches: "Patches"
        case .build: "Build And Playtest"
        case .binaryBlocks: "Binary Blocks"
        case .ndsContainers: "NDS Containers"
        case .ndsTextBanks: "NDS Text Banks"
        case .gameCubeResources: "GameCube Resources"
        case .expansionData: "Expansion Data"
        }
    }

    private static func migrationTarget(for surface: PokemonDataCompatibilitySurface, profile: GameProfile) -> String {
        switch surface {
        case .assets:
            return "source-backed graphics/pokemon assets"
        case .cries:
            return "source-backed audio/cry asset workflow"
        case .forms:
            return profile == .pokeemeraldExpansion ? "Expansion form data writer" : "source-backed form data support"
        default:
            return "source-backed \(title(for: surface).lowercased()) editor"
        }
    }

    private static func supportedActions(for entry: PokemonDataCompatibilityEntry) -> [String] {
        switch entry.status {
        case .editable:
            return ["catalog", "draft", "preview mutation plan", "explicit apply"]
        case .indexed:
            return ["catalog", "source spans", "read-only diagnostics"]
        case .readOnly:
            return ["catalog", "source spans", "compatibility diagnostics"]
        case .blocked:
            return ["blocked-state diagnostics"]
        }
    }

    private static func blockedActions(for entry: PokemonDataCompatibilityEntry) -> [String] {
        var blocked = entry.unsupportedFields
        if let reason = entry.blockedReason {
            blocked.append(reason)
        }
        if blocked.isEmpty, entry.status != .editable {
            blocked.append("source write")
        }
        return blocked
    }

    private static func referenceDrivers(for profile: GameProfile) -> [String] {
        switch profile {
        case .pokeemerald:
            return ["pret__pokeemerald", "huderlem__porymap", "huderlem__poryscript"]
        case .pokefirered:
            return ["pret__pokefirered", "skeli789__complete-fire-red-upgrade"]
        case .pokeruby:
            return ["pret__pokeruby"]
        case .pokeemeraldExpansion:
            return ["rh-hideout__pokeemerald-expansion", "resetes12__pokeemerald"]
        case .binaryROM:
            return ["haven1433__hexmaniacadvance", "gamer2020__pokemongameeditor", "ayashibox__pkmn-rom-extract"]
        case .ndsROM:
            return ["roadrunnerwmc__ndspy", "ds-pokemon-rom-editor__dspre"]
        case .pokediamond:
            return ["pret__pokediamond", "projectpokemon__ppre"]
        case .pokeplatinum:
            return ["pret__pokeplatinum", "ds-pokemon-rom-editor__dspre", "roadrunnerwmc__ndspy"]
        case .pokeheartgold:
            return ["pret__pokeheartgold", "ds-pokemon-rom-editor__dspre"]
        case .pmdSky:
            return ["pret__pmd-sky", "skytemple__skytemple"]
        case .pokemonColosseum, .pokemonXD, .pokemonBox, .pokemonChannel, .gameCubeMedia:
            return ["PkmGCTools", "public FSYS notes"]
        case .unknown:
            return []
        }
    }

    private static func legacyReferenceDrivers(for surface: PokemonDataCompatibilitySurface) -> [String] {
        switch surface {
        case .species, .pokedex, .evolutions:
            return ["thejazz123__universal-gba-pokedex", "tarnatlon__pokedata"]
        case .moves, .levelUpLearnsets, .tmhmLearnsets, .eggMoves, .tutorLearnsets:
            return ["asparaguseduardo__porymoves"]
        case .items:
            return ["gamer2020__pokemongameeditor"]
        case .assets:
            return ["teamaquashideout__team-aquas-asset-repo", "loxed__porypal"]
        case .cries:
            return ["gamer2020__pokemongameeditor"]
        case .forms:
            return ["rh-hideout__pokeemerald-expansion"]
        }
    }
}
