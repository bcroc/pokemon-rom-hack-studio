import CryptoKit
import Foundation

public enum GenIIIResourcePlatform: String, Codable, Equatable, CaseIterable {
    case gbaSource
    case gbaROM
    case ndsSource
    case ndsROM
    case gameCube
    case unknown
}

public enum GenIIIResourceRole: String, Codable, Equatable, CaseIterable {
    case editableSource
    case referenceSource
    case localInput
    case generatedArtifact
    case missingInput
}

public enum GenIIIParseStatus: String, Codable, Equatable, CaseIterable {
    case parsed
    case partial
    case missing
    case unsupported
    case failed
}

public enum GenIIIGameFamily: String, Codable, Equatable, CaseIterable {
    case rubySapphire
    case emerald
    case fireRedLeafGreen
    case emeraldExpansion
    case colosseum
    case xdGaleOfDarkness
    case pokemonBox
    case pokemonChannel
    case diamondPearl
    case platinum
    case heartGoldSoulSilver
    case blackWhite
    case black2White2
    case ndsUnknown
    case unknown
}

public struct GenIIIResourceVariant: Codable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let outputPath: String?
    public let checksumPath: String?

    public init(id: String, title: String, outputPath: String? = nil, checksumPath: String? = nil) {
        self.id = id
        self.title = title
        self.outputPath = outputPath
        self.checksumPath = checksumPath
    }
}

public struct GenIIIResourceItem: Codable, Equatable, Identifiable {
    public let id: String
    public let path: String
    public let kind: String
    public let category: String
    public let offset: UInt64?
    public let size: UInt64?
    public let uncompressedSize: UInt64?
    public let sha1: String?

    public init(
        id: String,
        path: String,
        kind: String,
        category: String,
        offset: UInt64? = nil,
        size: UInt64? = nil,
        uncompressedSize: UInt64? = nil,
        sha1: String? = nil
    ) {
        self.id = id
        self.path = path
        self.kind = kind
        self.category = category
        self.offset = offset
        self.size = size
        self.uncompressedSize = uncompressedSize
        self.sha1 = sha1
    }
}

public struct GenIIIResourceEntry: Codable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let path: String
    public let platform: GenIIIResourcePlatform
    public let family: GenIIIGameFamily
    public let profile: GameProfile
    public let variants: [GenIIIResourceVariant]
    public let role: GenIIIResourceRole
    public let parseStatus: GenIIIParseStatus
    public let adapterID: String?
    public let writePolicy: WritePolicy
    public let modules: [EditorModule]
    public let resourceCount: Int
    public let items: [GenIIIResourceItem]
    public let diagnostics: [Diagnostic]

    public init(
        id: String,
        title: String,
        path: String,
        platform: GenIIIResourcePlatform,
        family: GenIIIGameFamily,
        profile: GameProfile,
        variants: [GenIIIResourceVariant],
        role: GenIIIResourceRole,
        parseStatus: GenIIIParseStatus,
        adapterID: String? = nil,
        writePolicy: WritePolicy = .mutationPlanOnly,
        modules: [EditorModule] = [],
        resourceCount: Int,
        items: [GenIIIResourceItem] = [],
        diagnostics: [Diagnostic] = []
    ) {
        self.id = id
        self.title = title
        self.path = path
        self.platform = platform
        self.family = family
        self.profile = profile
        self.variants = variants
        self.role = role
        self.parseStatus = parseStatus
        self.adapterID = adapterID
        self.writePolicy = writePolicy
        self.modules = modules
        self.resourceCount = resourceCount
        self.items = items
        self.diagnostics = diagnostics
    }
}

public struct GenIIIResourceLibrary: Codable, Equatable {
    public let workspaceRoot: String
    public let entries: [GenIIIResourceEntry]
    public let diagnostics: [Diagnostic]

    public init(workspaceRoot: String, entries: [GenIIIResourceEntry], diagnostics: [Diagnostic] = []) {
        self.workspaceRoot = workspaceRoot
        self.entries = entries
        self.diagnostics = diagnostics
    }
}

public enum GameCubeResourceKind: String, Codable, Equatable, CaseIterable {
    case filesystem
    case dol
    case archive
    case archiveMember
    case pokemonTable
    case trainerTable
    case itemTable
    case moveTable
    case text
    case model
    case texture
    case audio
    case unknown
}

public struct GameCubeDiscHeader: Codable, Equatable {
    public let gameCode: String
    public let makerCode: String
    public let discID: UInt8
    public let version: UInt8
    public let title: String
    public let dolOffset: UInt64
    public let fstOffset: UInt64
    public let fstSize: UInt64
}

public struct GameCubeResource: Codable, Equatable, Identifiable {
    public let id: String
    public let path: String
    public let kind: GameCubeResourceKind
    public let offset: UInt64
    public let size: UInt64
    public let uncompressedSize: UInt64?
    public let containerPath: String?

    public init(
        id: String,
        path: String,
        kind: GameCubeResourceKind,
        offset: UInt64,
        size: UInt64,
        uncompressedSize: UInt64? = nil,
        containerPath: String? = nil
    ) {
        self.id = id
        self.path = path
        self.kind = kind
        self.offset = offset
        self.size = size
        self.uncompressedSize = uncompressedSize
        self.containerPath = containerPath
    }
}

public struct GameCubeDiscIndex: Codable, Equatable {
    public let path: String
    public let profile: GameProfile
    public let header: GameCubeDiscHeader?
    public let resources: [GameCubeResource]
    public let diagnostics: [Diagnostic]

    public init(
        path: String,
        profile: GameProfile,
        header: GameCubeDiscHeader?,
        resources: [GameCubeResource],
        diagnostics: [Diagnostic]
    ) {
        self.path = path
        self.profile = profile
        self.header = header
        self.resources = resources
        self.diagnostics = diagnostics
    }
}

public enum GenIIIResourceRegistry {
    private struct Candidate: Hashable {
        let path: String
        let role: GenIIIResourceRole
    }

    private static let defaultSourceRoots = [
        "pokeemerald",
        "pokefirered",
        "pokeruby",
        "pokesapphire",
        "pokeemerald-expansion",
        "pokediamond",
        "pokeplatinum",
        "pokeheartgold",
        "pokesoulsilver",
        "pmd-sky"
    ]

    private static let referenceResourceNames: Set<String> = [
        "pokeemerald",
        "pokefirered",
        "pokeruby",
        "pokeemerald-expansion",
        "pokediamond",
        "pokeplatinum",
        "pokeheartgold",
        "pmd-sky"
    ]

    public static func load(
        workspaceRoot: String = FileManager.default.currentDirectoryPath,
        recentRoots: [String] = [],
        fileManager: FileManager = .default
    ) -> GenIIIResourceLibrary {
        let root = URL(fileURLWithPath: workspaceRoot).standardizedFileURL
        var candidates: [Candidate] = []
        var diagnostics: [Diagnostic] = []

        for relativePath in defaultSourceRoots {
            let url = root.appendingPathComponent(relativePath).standardizedFileURL
            if fileManager.fileExists(atPath: url.path) {
                candidates.append(Candidate(path: url.path, role: .editableSource))
            }
        }

        candidates.append(contentsOf: referenceCandidates(workspaceRoot: root, fileManager: fileManager, diagnostics: &diagnostics))
        candidates.append(contentsOf: topLevelMediaCandidates(workspaceRoot: root, fileManager: fileManager))
        candidates.append(contentsOf: recentRoots.map {
            Candidate(path: URL(fileURLWithPath: $0).standardizedFileURL.path, role: .editableSource)
        })

        var entries: [GenIIIResourceEntry] = []
        var seenPaths: Set<String> = []

        for candidate in candidates {
            let standardized = URL(fileURLWithPath: candidate.path).standardizedFileURL.path
            guard seenPaths.insert(standardized).inserted else { continue }
            guard fileManager.fileExists(atPath: standardized) else {
                entries.append(missingEntry(path: standardized, title: URL(fileURLWithPath: standardized).lastPathComponent))
                continue
            }

            entries.append(resourceEntry(path: standardized, role: candidate.role, workspaceRoot: root, fileManager: fileManager))
        }

        return GenIIIResourceLibrary(
            workspaceRoot: root.path,
            entries: entries.sorted { lhs, rhs in
                if lhs.platform.rawValue == rhs.platform.rawValue {
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
                return lhs.platform.rawValue < rhs.platform.rawValue
            },
            diagnostics: diagnostics
        )
    }

    public static func resourceIndex(
        path: String,
        role: GenIIIResourceRole = .localInput,
        fileManager: FileManager = .default
    ) -> GenIIIResourceEntry {
        resourceEntry(
            path: URL(fileURLWithPath: path).standardizedFileURL.path,
            role: role,
            workspaceRoot: URL(fileURLWithPath: fileManager.currentDirectoryPath).standardizedFileURL,
            fileManager: fileManager
        )
    }

    public static func resourceEntry(
        from index: ProjectIndex,
        role: GenIIIResourceRole = .localInput,
        workspaceRoot: String = FileManager.default.currentDirectoryPath,
        fileManager: FileManager = .default
    ) -> GenIIIResourceEntry {
        let workspaceURL = URL(fileURLWithPath: workspaceRoot).standardizedFileURL
        let resolvedRole = roleFor(index: index, requestedRole: role, workspaceRoot: workspaceURL)
        return entry(from: index, role: resolvedRole, fileManager: fileManager)
    }

    private static func referenceCandidates(
        workspaceRoot: URL,
        fileManager: FileManager,
        diagnostics: inout [Diagnostic]
    ) -> [Candidate] {
        guard let manifest = try? ReferenceManifestLoader.load(from: workspaceRoot.path, fileManager: fileManager) else {
            return []
        }

        return manifest.repositories
            .filter { referenceResourceNames.contains($0.name) }
            .map { reference in
                Candidate(
                    path: workspaceRoot.appendingPathComponent(reference.path).standardizedFileURL.path,
                    role: .referenceSource
                )
            }
    }

    private static func topLevelMediaCandidates(workspaceRoot: URL, fileManager: FileManager) -> [Candidate] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: workspaceRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let supportedExtensions: Set<String> = ["gba", "nds"]
        return contents.compactMap { url in
            guard
                (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true,
                supportedExtensions.contains(url.pathExtension.lowercased())
            else {
                return nil
            }
            return Candidate(path: url.standardizedFileURL.path, role: .localInput)
        }
    }

    private static func resourceEntry(
        path: String,
        role: GenIIIResourceRole,
        workspaceRoot: URL,
        fileManager: FileManager
    ) -> GenIIIResourceEntry {
        let url = URL(fileURLWithPath: path).standardizedFileURL

        if GameCubeDiscParser.isSupportedDiscImage(url, fileManager: fileManager) {
            return gameCubeEntry(path: url.path, role: role, fileManager: fileManager)
        }

        do {
            let index = try GameAdapterRegistry.index(path: url.path, fileManager: fileManager)
            let resolvedRole = roleFor(index: index, requestedRole: role, workspaceRoot: workspaceRoot)
            return entry(from: index, role: resolvedRole, fileManager: fileManager)
        } catch {
            return GenIIIResourceEntry(
                id: url.path,
                title: url.lastPathComponent,
                path: url.path,
                platform: .unknown,
                family: .unknown,
                profile: .unknown,
                variants: [],
                role: role,
                parseStatus: .failed,
                resourceCount: 0,
                diagnostics: [
                    Diagnostic(
                        severity: .warning,
                        code: "RESOURCE_INDEX_UNSUPPORTED",
                        message: error.localizedDescription
                    )
                ]
            )
        }
    }

    private static func entry(from index: ProjectIndex, role: GenIIIResourceRole, fileManager: FileManager) -> GenIIIResourceEntry {
        if index.profile == .ndsROM,
           let report = try? NDSROMInspectorReportBuilder.build(index: index, fileManager: fileManager) {
            return report.resourceEntry
        }

        let items = resourceItems(from: index, fileManager: fileManager)
        let diagnostics = index.diagnostics + resourceDiagnostics(from: index, fileManager: fileManager)

        return GenIIIResourceEntry(
            id: index.root.path,
            title: title(for: index, fileManager: fileManager),
            path: index.root.path,
            platform: platform(for: index.profile),
            family: family(for: index.profile, path: index.root.path),
            profile: index.profile,
            variants: variants(for: index, fileManager: fileManager),
            role: role,
            parseStatus: diagnostics.contains { $0.severity == .error } ? .partial : .parsed,
            adapterID: index.adapterID,
            writePolicy: index.writePolicy,
            modules: index.editorModules,
            resourceCount: items.count,
            items: items,
            diagnostics: diagnostics
        )
    }

    private static func gameCubeEntry(path: String, role: GenIIIResourceRole, fileManager: FileManager) -> GenIIIResourceEntry {
        let index = GameCubeDiscParser.parse(path: path, fileManager: fileManager)
        let url = URL(fileURLWithPath: path)
        let title = index.header?.title.isEmpty == false ? index.header?.title ?? url.lastPathComponent : url.lastPathComponent
        let items = index.resources.map { resource in
            GenIIIResourceItem(
                id: resource.id,
                path: resource.path,
                kind: resource.kind.rawValue,
                category: category(for: resource.kind),
                offset: resource.offset,
                size: resource.size,
                uncompressedSize: resource.uncompressedSize
            )
        }

        return GenIIIResourceEntry(
            id: path,
            title: title,
            path: path,
            platform: .gameCube,
            family: family(for: index.profile, path: path),
            profile: index.profile,
            variants: variants(for: index.profile, title: title),
            role: role,
            parseStatus: index.diagnostics.contains { $0.severity == .error } ? .partial : .parsed,
            adapterID: "gen3.gamecube-disc",
            writePolicy: .readOnly,
            modules: [.rom, .graphics, .pokemon, .trainers, .items, .moves, .text, .diagnostics],
            resourceCount: items.count,
            items: items,
            diagnostics: index.diagnostics
        )
    }

    private static func resourceItems(from index: ProjectIndex, fileManager: FileManager) -> [GenIIIResourceItem] {
        if index.profile == .ndsROM,
           let report = try? NDSROMInspectorReportBuilder.build(index: index, fileManager: fileManager) {
            return report.resourceEntry.items
        }

        if isNDSSourceProfile(index.profile),
           let sourceTree = try? NDSDecompSourceTreeIndexBuilder.build(root: URL(fileURLWithPath: index.root.path), fileManager: fileManager) {
            let pathItems = sourceTree.paths.map { path in
                GenIIIResourceItem(
                    id: "nds-source:\(path.role.rawValue):\(path.relativePath)",
                    path: path.relativePath,
                    kind: path.kind.rawValue,
                    category: "NDS \(path.role.rawValue)"
                )
            }
            let variantItems = sourceTree.variants.map { variant in
                GenIIIResourceItem(
                    id: "nds-variant:\(variant.id)",
                    path: variant.outputPath ?? variant.id,
                    kind: variant.title,
                    category: "NDS Variant",
                    sha1: variant.checksumPath
                )
            }
            let buildItems = sourceTree.buildTargets.map { target in
                GenIIIResourceItem(
                    id: "nds-build-target:\(target.id)",
                    path: target.outputPath ?? target.command.joined(separator: " "),
                    kind: target.kind.rawValue,
                    category: "NDS Build Target"
                )
            }
            let catalog = NDSDataCatalogBuilder.build(index: index, fileManager: fileManager)
            let catalogItems = catalog.records.map { record in
                GenIIIResourceItem(
                    id: "nds-data:\(record.id)",
                    path: record.relativePath,
                    kind: record.format.rawValue,
                    category: "NDS Data \(record.domain.rawValue)",
                    size: record.byteCount
                )
            }
            return pathItems + variantItems + buildItems + catalogItems
        }

        if index.profile == .binaryROM {
            let url = URL(fileURLWithPath: index.root.path)
            let sha1 = smallFileSHA1(url: url)
            let attributes = try? fileManager.attributesOfItem(atPath: url.path)
            let size = (attributes?[.size] as? NSNumber)?.uint64Value
            let data = (try? Data(contentsOf: url)) ?? Data()
            let graph = BinaryROMGraphBuilder.build(path: url.path, data: data)
            let headerItems = graph.headerFacts.map {
                GenIIIResourceItem(
                    id: "rom-header:\($0.key)",
                    path: url.lastPathComponent,
                    kind: $0.key,
                    category: "ROM Header",
                    offset: nil,
                    size: nil,
                    sha1: nil
                )
            }
            let pointerItems = graph.pointerCandidates.prefix(16).map {
                GenIIIResourceItem(
                    id: "rom-pointer:\($0.sourceOffset)",
                    path: String(format: "0x%06X -> 0x%06X", $0.sourceOffset, $0.targetOffset),
                    kind: "pointer",
                    category: "GBA Pointer",
                    offset: UInt64($0.sourceOffset),
                    size: 4
                )
            }
            let freeSpaceItems = graph.freeSpaceRanges.prefix(16).map {
                GenIIIResourceItem(
                    id: "rom-free-space:\($0.offset)",
                    path: String(format: "0x%06X", $0.offset),
                    kind: String(format: "fill 0x%02X", $0.fillByte),
                    category: "Free Space",
                    offset: UInt64($0.offset),
                    size: UInt64($0.length)
                )
            }
            let anchorItems = graph.anchors.prefix(16).map {
                GenIIIResourceItem(
                    id: "rom-anchor:\($0.id)",
                    path: String(format: "0x%06X", $0.offset),
                    kind: $0.kind,
                    category: "ROM Anchor",
                    offset: UInt64($0.offset),
                    size: nil
                )
            }
            let runItems = graph.semanticRuns.prefix(24).map {
                GenIIIResourceItem(
                    id: "rom-run:\($0.id)",
                    path: String(format: "0x%06X", $0.offset),
                    kind: $0.kind.rawValue,
                    category: "Semantic ROM Run",
                    offset: UInt64($0.offset),
                    size: UInt64($0.length)
                )
            }
            return [
                GenIIIResourceItem(
                    id: url.path,
                    path: url.lastPathComponent,
                    kind: "rom",
                    category: "GBA ROM",
                    offset: 0,
                    size: size,
                    sha1: sha1
                )
            ] + headerItems + anchorItems + runItems + pointerItems + freeSpaceItems
        }

        let sourceItems = index.documents.map { document in
            GenIIIResourceItem(
                id: "source:\(document.relativePath)",
                path: document.relativePath,
                kind: document.kind.rawValue,
                category: document.role.rawValue
            )
        }
        let generatedItems = index.generatedOutputs.map { document in
            GenIIIResourceItem(
                id: "generated:\(document.relativePath)",
                path: document.relativePath,
                kind: document.kind.rawValue,
                category: document.role.rawValue
            )
        }
        return sourceItems + generatedItems
    }

    private static func variants(for index: ProjectIndex, fileManager: FileManager) -> [GenIIIResourceVariant] {
        switch index.profile {
        case .pokeemerald:
            return [GenIIIResourceVariant(id: "emerald", title: "Pokemon Emerald", outputPath: "pokeemerald.gba", checksumPath: "rom.sha1")]
        case .pokeemeraldExpansion:
            return [GenIIIResourceVariant(id: "emerald-expansion", title: "Pokemon Emerald Expansion", outputPath: "pokeemerald.gba", checksumPath: "rom.sha1")]
        case .pokefirered, .pokeruby:
            return variantsFromBuildTargetsAndSHA1(index: index, fileManager: fileManager)
        case .binaryROM:
            return variantsForGBAImage(path: index.root.path)
        case .ndsROM:
            return variantsForNDSImage(path: index.root.path)
        case .pokediamond, .pokeplatinum, .pokeheartgold, .pmdSky:
            return variantsForNDSSource(index: index, fileManager: fileManager)
        case .pokemonColosseum, .pokemonXD, .pokemonBox, .pokemonChannel, .gameCubeMedia:
            return variants(for: index.profile, title: URL(fileURLWithPath: index.root.path).lastPathComponent)
        case .unknown:
            return []
        }
    }

    private static func variants(for profile: GameProfile, title: String) -> [GenIIIResourceVariant] {
        switch profile {
        case .pokemonColosseum:
            return [GenIIIResourceVariant(id: "pokemon-colosseum", title: "Pokemon Colosseum")]
        case .pokemonXD:
            return [GenIIIResourceVariant(id: "pokemon-xd", title: "Pokemon XD: Gale of Darkness")]
        case .pokemonBox:
            return [GenIIIResourceVariant(id: "pokemon-box", title: "Pokemon Box: Ruby & Sapphire")]
        case .pokemonChannel:
            return [GenIIIResourceVariant(id: "pokemon-channel", title: "Pokemon Channel")]
        default:
            return [GenIIIResourceVariant(id: "gamecube-media", title: title)]
        }
    }

    private static func variantsFromBuildTargetsAndSHA1(index: ProjectIndex, fileManager: FileManager) -> [GenIIIResourceVariant] {
        let root = URL(fileURLWithPath: index.root.path)
        let checksumPaths = Set((try? fileManager.contentsOfDirectory(atPath: root.path))?.filter { $0.hasSuffix(".sha1") } ?? [])
        var variants: [GenIIIResourceVariant] = []
        var seen: Set<String> = []

        for target in index.buildTargets where target.outputPath?.hasSuffix(".gba") == true {
            let output = target.outputPath
            let checksumPath = checksumPath(forOutputPath: output, checksumPaths: checksumPaths)
            let id = output ?? target.id
            guard seen.insert(id).inserted else { continue }
            variants.append(
                GenIIIResourceVariant(
                    id: id,
                    title: target.name.replacingOccurrences(of: "Build ", with: ""),
                    outputPath: output,
                    checksumPath: checksumPath
                )
            )
        }

        return variants
    }

    private static func variantsForGBAImage(path: String) -> [GenIIIResourceVariant] {
        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            data.count >= 0xB2
        else {
            return [GenIIIResourceVariant(id: "gba-rom", title: URL(fileURLWithPath: path).lastPathComponent)]
        }
        let image = ROMImage(path: path, data: data)
        let title = titleForGBACode(image.gameCode) ?? image.title ?? URL(fileURLWithPath: path).lastPathComponent
        return [GenIIIResourceVariant(id: image.gameCode ?? "gba-rom", title: title)]
    }

    private static func variantsForNDSImage(path: String) -> [GenIIIResourceVariant] {
        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let header = NDSROMHeaderParser.parse(path: path, data: data).header
        else {
            return [GenIIIResourceVariant(id: "nds-rom", title: URL(fileURLWithPath: path).lastPathComponent)]
        }
        return [GenIIIResourceVariant(id: header.gameCode.isEmpty ? "nds-rom" : header.gameCode, title: header.displayTitle)]
    }

    private static func variantsForNDSSource(index: ProjectIndex, fileManager: FileManager) -> [GenIIIResourceVariant] {
        guard let sourceTree = try? NDSDecompSourceTreeIndexBuilder.build(
            root: URL(fileURLWithPath: index.root.path),
            fileManager: fileManager
        ) else {
            return []
        }

        return sourceTree.variants.map {
            GenIIIResourceVariant(
                id: $0.id,
                title: $0.title,
                outputPath: $0.outputPath,
                checksumPath: $0.checksumPath
            )
        }
    }

    private static func checksumPath(forOutputPath outputPath: String?, checksumPaths: Set<String>) -> String? {
        guard let outputPath else { return nil }
        let basename = URL(fileURLWithPath: outputPath).deletingPathExtension().lastPathComponent.lowercased()
        let candidates = [
            "\(basename).sha1",
            basename.hasPrefix("poke") ? String(basename.dropFirst(4)) + ".sha1" : nil
        ].compactMap { $0 }
        return candidates.first { checksumPaths.contains($0) }
    }

    private static func resourceDiagnostics(from index: ProjectIndex, fileManager: FileManager) -> [Diagnostic] {
        switch index.profile {
        case .pokemonColosseum, .pokemonXD, .pokemonBox, .pokemonChannel, .gameCubeMedia:
            return []
        default:
            return []
        }
    }

    private static func roleFor(index: ProjectIndex, requestedRole: GenIIIResourceRole, workspaceRoot: URL) -> GenIIIResourceRole {
        if requestedRole == .referenceSource || index.root.path.hasPrefix(workspaceRoot.appendingPathComponent("references").path + "/") {
            return .referenceSource
        }
        if pathIsCentralReferenceRoot(index.root.path) {
            return .referenceSource
        }
        if index.profile == .binaryROM || index.profile == .ndsROM {
            return .localInput
        }
        return requestedRole == .localInput ? .editableSource : requestedRole
    }

    private static func platform(for profile: GameProfile) -> GenIIIResourcePlatform {
        switch profile {
        case .pokeemerald, .pokefirered, .pokeruby, .pokeemeraldExpansion:
            return .gbaSource
        case .pokediamond, .pokeplatinum, .pokeheartgold, .pmdSky:
            return .ndsSource
        case .binaryROM:
            return .gbaROM
        case .ndsROM:
            return .ndsROM
        case .pokemonColosseum, .pokemonXD, .pokemonBox, .pokemonChannel, .gameCubeMedia:
            return .gameCube
        case .unknown:
            return .unknown
        }
    }

    private static func family(for profile: GameProfile, path: String) -> GenIIIGameFamily {
        switch profile {
        case .pokeruby:
            return .rubySapphire
        case .pokeemerald:
            return .emerald
        case .pokefirered:
            return .fireRedLeafGreen
        case .pokeemeraldExpansion:
            return .emeraldExpansion
        case .pokediamond:
            return .diamondPearl
        case .pokeplatinum:
            return .platinum
        case .pokeheartgold:
            return .heartGoldSoulSilver
        case .pmdSky:
            return .ndsUnknown
        case .pokemonColosseum:
            return .colosseum
        case .pokemonXD:
            return .xdGaleOfDarkness
        case .pokemonBox:
            return .pokemonBox
        case .pokemonChannel:
            return .pokemonChannel
        case .binaryROM:
            return familyForGBAROM(path: path)
        case .ndsROM:
            return familyForNDSROM(path: path)
        case .gameCubeMedia, .unknown:
            return .unknown
        }
    }

    private static func familyForGBAROM(path: String) -> GenIIIGameFamily {
        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            data.count >= 0xB0
        else {
            return .unknown
        }
        let image = ROMImage(path: path, data: data)
        switch image.gameCode?.uppercased() {
        case "AXVE", "AXVP":
            return .rubySapphire
        case "AXPE", "AXPP":
            return .rubySapphire
        case "BPEE", "BPEP":
            return .emerald
        case "BPRE", "BPRP", "BPGE", "BPGP":
            return .fireRedLeafGreen
        default:
            return .unknown
        }
    }

    private static func familyForNDSROM(path: String) -> GenIIIGameFamily {
        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let header = NDSROMHeaderParser.parse(path: path, data: data).header
        else {
            return .ndsUnknown
        }
        return NDSResourceEntryFactory.family(for: header.gameCode)
    }

    private static func title(for index: ProjectIndex, fileManager: FileManager) -> String {
        if index.profile == .binaryROM {
            let url = URL(fileURLWithPath: index.root.path)
            if let data = try? Data(contentsOf: url), data.count >= 0xB2 {
                let image = ROMImage(path: url.path, data: data)
                return titleForGBACode(image.gameCode) ?? image.title ?? url.lastPathComponent
            }
            return url.lastPathComponent
        }
        if index.profile == .ndsROM {
            let url = URL(fileURLWithPath: index.root.path)
            if let data = try? Data(contentsOf: url),
               let header = NDSROMHeaderParser.parse(path: url.path, data: data).header {
                return header.displayTitle
            }
            return url.lastPathComponent
        }
        if isNDSSourceProfile(index.profile) {
            return index.adapterName
        }
        return URL(fileURLWithPath: index.root.path).lastPathComponent
    }

    private static func isNDSSourceProfile(_ profile: GameProfile) -> Bool {
        switch profile {
        case .pokediamond, .pokeplatinum, .pokeheartgold, .pmdSky:
            return true
        default:
            return false
        }
    }

    private static func pathIsCentralReferenceRoot(_ path: String) -> Bool {
        let components = URL(fileURLWithPath: path).standardizedFileURL.pathComponents
        guard let projectsIndex = components.firstIndex(of: "projects"),
              components.indices.contains(projectsIndex + 2)
        else {
            return false
        }
        return components[projectsIndex + 1] == "reference-repos"
            && components[projectsIndex + 2] == "repos"
    }

    private static func titleForGBACode(_ code: String?) -> String? {
        switch code?.uppercased() {
        case "AXVE", "AXVP":
            return "Pokemon Ruby"
        case "AXPE", "AXPP":
            return "Pokemon Sapphire"
        case "BPEE", "BPEP":
            return "Pokemon Emerald"
        case "BPRE", "BPRP":
            return "Pokemon FireRed"
        case "BPGE", "BPGP":
            return "Pokemon LeafGreen"
        default:
            return nil
        }
    }

    private static func category(for kind: GameCubeResourceKind) -> String {
        switch kind {
        case .filesystem:
            return "Disc filesystem"
        case .dol:
            return "Executable"
        case .archive:
            return "FSYS archive"
        case .archiveMember:
            return "Archive member"
        case .pokemonTable:
            return "Pokemon table candidate"
        case .trainerTable:
            return "Trainer table candidate"
        case .itemTable:
            return "Item table candidate"
        case .moveTable:
            return "Move table candidate"
        case .text:
            return "Text resource"
        case .model:
            return "Model resource"
        case .texture:
            return "Texture resource"
        case .audio:
            return "Audio resource"
        case .unknown:
            return "Unrecognized resource"
        }
    }

    private static func missingGameCubeMediaEntries(existingEntries: [GenIIIResourceEntry]) -> [GenIIIResourceEntry] {
        let existingFamilies = Set(existingEntries.filter { $0.platform == .gameCube }.map(\.family))
        let expected: [(GenIIIGameFamily, GameProfile, String)] = [
            (.colosseum, .pokemonColosseum, "Pokemon Colosseum"),
            (.xdGaleOfDarkness, .pokemonXD, "Pokemon XD: Gale of Darkness"),
            (.pokemonBox, .pokemonBox, "Pokemon Box: Ruby & Sapphire"),
            (.pokemonChannel, .pokemonChannel, "Pokemon Channel")
        ]

        return expected.compactMap { family, profile, title in
            guard !existingFamilies.contains(family) else { return nil }
            return GenIIIResourceEntry(
                id: "missing:\(family.rawValue)",
                title: title,
                path: "",
                platform: .gameCube,
                family: family,
                profile: profile,
                variants: variants(for: profile, title: title),
                role: .missingInput,
                parseStatus: .missing,
                adapterID: "gen3.gamecube-disc",
                writePolicy: .readOnly,
                modules: [.rom, .diagnostics],
                resourceCount: 0,
                diagnostics: [
                    Diagnostic(
                        severity: .info,
                        code: "GAMECUBE_MEDIA_MISSING",
                        message: "\(title) disc image was not found. Add a local .iso or .gcm to index its read-only resources."
                    )
                ]
            )
        }
    }

    private static func missingEntry(path: String, title: String) -> GenIIIResourceEntry {
        GenIIIResourceEntry(
            id: "missing:\(path)",
            title: title,
            path: path,
            platform: .unknown,
            family: .unknown,
            profile: .unknown,
            variants: [],
            role: .missingInput,
            parseStatus: .missing,
            resourceCount: 0,
            diagnostics: [
                Diagnostic(
                    severity: .warning,
                    code: "RESOURCE_ROOT_MISSING",
                    message: "Resource path is not present: \(path)"
                )
            ]
        )
    }

    private static func smallFileSHA1(url: URL, maxBytes: UInt64 = 64 * 1024 * 1024) -> String? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        guard
            let size = (attributes?[.size] as? NSNumber)?.uint64Value,
            size <= maxBytes,
            let data = try? Data(contentsOf: url)
        else {
            return nil
        }
        let digest = Insecure.SHA1.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

public enum GameCubeDiscParser {
    private static let minimumHeaderSize = 0x430
    private static let maxFSTReadBytes: UInt64 = 32 * 1024 * 1024
    private static let maxArchiveReadBytes: UInt64 = 64 * 1024 * 1024

    public static func isSupportedDiscImage(_ url: URL, fileManager: FileManager = .default) -> Bool {
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
            && !isDirectory.boolValue
            && ["iso", "gcm"].contains(url.pathExtension.lowercased())
    }

    public static func detectProfile(at url: URL, fileManager: FileManager = .default) -> GameProfile {
        parse(path: url.path, fileManager: fileManager, includeFileSystem: false).profile
    }

    public static func parse(
        path: String,
        fileManager: FileManager = .default,
        includeFileSystem: Bool = true
    ) -> GameCubeDiscIndex {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        guard isSupportedDiscImage(url, fileManager: fileManager) else {
            return GameCubeDiscIndex(
                path: url.path,
                profile: .unknown,
                header: nil,
                resources: [],
                diagnostics: [
                    Diagnostic(severity: .warning, code: "GAMECUBE_IMAGE_UNSUPPORTED", message: "Expected a local .iso or .gcm file.")
                ]
            )
        }

        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return GameCubeDiscIndex(
                path: url.path,
                profile: .unknown,
                header: nil,
                resources: [],
                diagnostics: [
                    Diagnostic(severity: .error, code: "GAMECUBE_IMAGE_UNREADABLE", message: "Could not open \(url.path).")
                ]
            )
        }
        defer { try? handle.close() }

        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        let size = (attributes?[.size] as? NSNumber)?.uint64Value ?? 0
        let headerData = read(handle: handle, offset: 0, length: UInt64(min(Int(size), 0x500)))
        guard headerData.count >= minimumHeaderSize else {
            return GameCubeDiscIndex(
                path: url.path,
                profile: .unknown,
                header: nil,
                resources: [],
                diagnostics: [
                    Diagnostic(severity: .error, code: "GAMECUBE_HEADER_TRUNCATED", message: "Disc image is too small to contain a GameCube header.")
                ]
            )
        }

        guard let header = parseHeader(headerData) else {
            return GameCubeDiscIndex(
                path: url.path,
                profile: .unknown,
                header: nil,
                resources: [],
                diagnostics: [
                    Diagnostic(severity: .error, code: "GAMECUBE_HEADER_INVALID", message: "Disc header could not be parsed.")
                ]
            )
        }

        let profile = profileFor(header: header)
        var diagnostics: [Diagnostic] = []
        var resources: [GameCubeResource] = []

        if header.dolOffset > 0, header.dolOffset < size {
            resources.append(
                GameCubeResource(
                    id: "dol:\(header.dolOffset)",
                    path: "main.dol",
                    kind: .dol,
                    offset: header.dolOffset,
                    size: header.fstOffset > header.dolOffset ? header.fstOffset - header.dolOffset : 0
                )
            )
        }

        guard includeFileSystem else {
            return GameCubeDiscIndex(path: url.path, profile: profile, header: header, resources: resources, diagnostics: diagnostics)
        }

        if header.fstOffset == 0 || header.fstSize == 0 || header.fstOffset + header.fstSize > size {
            diagnostics.append(
                Diagnostic(severity: .warning, code: "GAMECUBE_FST_UNAVAILABLE", message: "Disc filesystem table is missing or outside the image bounds.")
            )
            return GameCubeDiscIndex(path: url.path, profile: profile, header: header, resources: resources, diagnostics: diagnostics)
        }

        if header.fstSize > maxFSTReadBytes {
            diagnostics.append(
                Diagnostic(severity: .warning, code: "GAMECUBE_FST_TOO_LARGE", message: "Disc filesystem table is larger than the parser safety cap.")
            )
            return GameCubeDiscIndex(path: url.path, profile: profile, header: header, resources: resources, diagnostics: diagnostics)
        }

        let fstData = read(handle: handle, offset: header.fstOffset, length: header.fstSize)
        let parsedFST = parseFST(data: fstData, fstOffset: header.fstOffset, imageSize: size)
        diagnostics.append(contentsOf: parsedFST.diagnostics)
        resources.append(contentsOf: parsedFST.resources)

        for archive in parsedFST.resources where archive.kind == .archive && archive.size <= maxArchiveReadBytes {
            let archiveData = read(handle: handle, offset: archive.offset, length: archive.size)
            let parsedArchive = FSYSArchiveParser.parse(
                data: archiveData,
                archivePath: archive.path,
                baseOffset: archive.offset
            )
            resources.append(contentsOf: parsedArchive.resources)
            diagnostics.append(contentsOf: parsedArchive.diagnostics)
        }

        return GameCubeDiscIndex(path: url.path, profile: profile, header: header, resources: resources, diagnostics: diagnostics)
    }

    private static func parseHeader(_ data: Data) -> GameCubeDiscHeader? {
        guard data.count >= minimumHeaderSize else { return nil }
        let gameCode = ascii(data, offset: 0x0, length: 4)
        let makerCode = ascii(data, offset: 0x4, length: 2)
        let discID = data[data.index(data.startIndex, offsetBy: 0x6)]
        let version = data[data.index(data.startIndex, offsetBy: 0x7)]
        let title = ascii(data, offset: 0x20, length: 0x3E0)
        let dolOffset = UInt64(be32(data, offset: 0x420))
        let fstOffset = UInt64(be32(data, offset: 0x424))
        let fstSize = UInt64(be32(data, offset: 0x428))

        guard !gameCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return GameCubeDiscHeader(
            gameCode: gameCode,
            makerCode: makerCode,
            discID: discID,
            version: version,
            title: title,
            dolOffset: dolOffset,
            fstOffset: fstOffset,
            fstSize: fstSize
        )
    }

    private static func profileFor(header: GameCubeDiscHeader) -> GameProfile {
        let code = header.gameCode.uppercased()
        let title = header.title.uppercased()

        if code.hasPrefix("GC6") || title.contains("COLOSSEUM") {
            return .pokemonColosseum
        }
        if code.hasPrefix("GXX") || title.contains("GALE OF DARKNESS") || title.contains("POKEMON XD") {
            return .pokemonXD
        }
        if code.hasPrefix("GPX") || title.contains("POKEMON BOX") {
            return .pokemonBox
        }
        if code.hasPrefix("GPA") || title.contains("POKEMON CHANNEL") {
            return .pokemonChannel
        }
        return .gameCubeMedia
    }

    private struct FSTParseResult {
        let resources: [GameCubeResource]
        let diagnostics: [Diagnostic]
    }

    private static func parseFST(data: Data, fstOffset: UInt64, imageSize: UInt64) -> FSTParseResult {
        guard data.count >= 12 else {
            return FSTParseResult(resources: [], diagnostics: [
                Diagnostic(severity: .warning, code: "GAMECUBE_FST_TRUNCATED", message: "Filesystem table is smaller than one entry.")
            ])
        }

        let entryCount = Int(be32(data, offset: 8))
        guard entryCount > 0, entryCount <= data.count / 12 else {
            return FSTParseResult(resources: [], diagnostics: [
                Diagnostic(severity: .warning, code: "GAMECUBE_FST_ENTRY_COUNT_INVALID", message: "Filesystem table entry count is invalid.")
            ])
        }

        let stringTableOffset = entryCount * 12
        var resources: [GameCubeResource] = []
        var diagnostics: [Diagnostic] = []
        var directories: [(path: String, endIndex: Int)] = [("", entryCount)]
        var seenPaths: Set<String> = []

        for index in 1..<entryCount {
            while let last = directories.last, index >= last.endIndex {
                directories.removeLast()
            }

            let entryOffset = index * 12
            let typeAndName = be32(data, offset: entryOffset)
            let entryType = UInt8(typeAndName >> 24)
            let nameOffset = Int(typeAndName & 0x00FF_FFFF)
            let valueA = UInt64(be32(data, offset: entryOffset + 4))
            let valueB = UInt64(be32(data, offset: entryOffset + 8))
            let name = fstString(data: data, stringTableOffset: stringTableOffset, nameOffset: nameOffset)
                ?? "entry-\(index)"
            let parentPath = directories.last?.path ?? ""
            let path = parentPath.isEmpty ? name : "\(parentPath)/\(name)"

            if entryType == 1 {
                let endIndex = Int(valueB)
                if endIndex <= index || endIndex > entryCount {
                    diagnostics.append(
                        Diagnostic(severity: .warning, code: "GAMECUBE_FST_DIRECTORY_INVALID", message: "Directory \(path) has an invalid end index.")
                    )
                } else {
                    directories.append((path, endIndex))
                }
                continue
            }

            let uniquePath = seenPaths.insert(path).inserted ? path : "\(path)#\(index)"
            if valueA + valueB > imageSize {
                diagnostics.append(
                    Diagnostic(severity: .warning, code: "GAMECUBE_FST_FILE_OUT_OF_BOUNDS", message: "\(uniquePath) points outside the disc image.")
                )
            }

            resources.append(
                GameCubeResource(
                    id: "fst:\(index):\(uniquePath)",
                    path: uniquePath,
                    kind: kindForDiscFile(path: uniquePath),
                    offset: valueA,
                    size: valueB
                )
            )
        }

        return FSTParseResult(resources: resources, diagnostics: diagnostics)
    }

    private static func kindForDiscFile(path: String) -> GameCubeResourceKind {
        let lowercased = path.lowercased()
        if lowercased.hasSuffix(".fsys") {
            return .archive
        }
        if lowercased.hasSuffix(".dol") {
            return .dol
        }
        if lowercased.contains("common") || lowercased.contains("pokemon") || lowercased.contains("pocket") {
            return .pokemonTable
        }
        if lowercased.contains("trainer") || lowercased.contains("deck") {
            return .trainerTable
        }
        if lowercased.contains("item") {
            return .itemTable
        }
        if lowercased.contains("move") || lowercased.contains("waza") {
            return .moveTable
        }
        if lowercased.contains("msg") || lowercased.contains("text") || lowercased.hasSuffix(".str") {
            return .text
        }
        if lowercased.hasSuffix(".bmd") || lowercased.hasSuffix(".dat") || lowercased.contains("model") {
            return .model
        }
        if lowercased.hasSuffix(".tpl") || lowercased.contains("tex") {
            return .texture
        }
        if lowercased.hasSuffix(".adp") || lowercased.hasSuffix(".dsp") || lowercased.contains("sound") {
            return .audio
        }
        return .filesystem
    }

    private static func read(handle: FileHandle, offset: UInt64, length: UInt64) -> Data {
        do {
            try handle.seek(toOffset: offset)
            return handle.readData(ofLength: Int(length))
        } catch {
            return Data()
        }
    }

    private static func fstString(data: Data, stringTableOffset: Int, nameOffset: Int) -> String? {
        let offset = stringTableOffset + nameOffset
        guard offset >= 0, offset < data.count else { return nil }
        var end = offset
        while end < data.count, data[data.index(data.startIndex, offsetBy: end)] != 0 {
            end += 1
        }
        guard end > offset else { return nil }
        return ascii(data, offset: offset, length: end - offset)
    }
}

private enum FSYSArchiveParser {
    struct ParseResult {
        let resources: [GameCubeResource]
        let diagnostics: [Diagnostic]
    }

    static func parse(data: Data, archivePath: String, baseOffset: UInt64) -> ParseResult {
        let bytes = Array(data)
        let names = candidateNames(in: bytes)
        let magic = Array("LZSS".utf8)
        var resources: [GameCubeResource] = []
        var diagnostics: [Diagnostic] = []
        var cursor = 0
        var memberIndex = 0

        while cursor + 16 <= bytes.count {
            if Array(bytes[cursor..<(cursor + 4)]) == magic {
                let compressedSize = UInt64(GameCubeDiscParser.be32(bytes, offset: cursor + 4))
                let uncompressedSize = UInt64(GameCubeDiscParser.be32(bytes, offset: cursor + 8))
                let name = memberIndex < names.count ? names[memberIndex] : "member-\(memberIndex).lzss"
                let memberPath = "\(archivePath)#\(name)"
                let size = compressedSize > 0 ? compressedSize + 16 : 16
                resources.append(
                    GameCubeResource(
                        id: "fsys:\(archivePath):\(memberIndex)",
                        path: memberPath,
                        kind: kindForArchiveMember(path: memberPath),
                        offset: baseOffset + UInt64(cursor),
                        size: size,
                        uncompressedSize: uncompressedSize > 0 ? uncompressedSize : nil,
                        containerPath: archivePath
                    )
                )
                memberIndex += 1
                cursor += Int(max(size, 4))
            } else {
                cursor += 1
            }
        }

        if resources.isEmpty {
            diagnostics.append(
                Diagnostic(severity: .warning, code: "FSYS_ARCHIVE_NO_LZSS_MEMBERS", message: "\(archivePath) did not contain recognizable LZSS members.")
            )
        }

        return ParseResult(resources: resources, diagnostics: diagnostics)
    }

    private static func candidateNames(in bytes: [UInt8]) -> [String] {
        var names: [String] = []
        var run: [UInt8] = []

        func flush() {
            defer { run.removeAll(keepingCapacity: true) }
            guard run.count >= 3 else { return }
            let string = String(decoding: run, as: UTF8.self)
            guard string.contains(".") || string.contains("_") else { return }
            guard string.range(of: #"^[A-Za-z0-9_.\-/]+$"#, options: .regularExpression) != nil else { return }
            names.append(string)
        }

        for byte in bytes.prefix(4096) {
            if byte >= 0x20, byte <= 0x7E {
                run.append(byte)
            } else {
                flush()
            }
        }
        flush()

        return Array(NSOrderedSet(array: names).compactMap { $0 as? String }.prefix(128))
    }

    private static func kindForArchiveMember(path: String) -> GameCubeResourceKind {
        let lowercased = (path.split(separator: "#").last.map(String.init) ?? path).lowercased()
        if lowercased.contains("pokemon") || lowercased.contains("pkx") || lowercased.contains("common") {
            return .pokemonTable
        }
        if lowercased.contains("trainer") || lowercased.contains("deck") {
            return .trainerTable
        }
        if lowercased.contains("item") {
            return .itemTable
        }
        if lowercased.contains("move") || lowercased.contains("waza") {
            return .moveTable
        }
        if lowercased.contains("msg") || lowercased.contains("text") || lowercased.contains("str") {
            return .text
        }
        if lowercased.contains("model") || lowercased.hasSuffix(".dat") || lowercased.hasSuffix(".fdat") {
            return .model
        }
        if lowercased.contains("tex") || lowercased.hasSuffix(".tpl") {
            return .texture
        }
        if lowercased.contains("sound") || lowercased.contains("audio") {
            return .audio
        }
        return .archiveMember
    }
}

private func ascii(_ data: Data, offset: Int, length: Int) -> String {
    guard offset >= 0, offset < data.count, length > 0 else { return "" }
    let end = min(data.count, offset + length)
    let bytes = data[offset..<end]
    let string = String(decoding: bytes, as: UTF8.self)
    return string
        .components(separatedBy: "\0")
        .first?
        .trimmingCharacters(in: .controlCharacters.union(.whitespacesAndNewlines)) ?? ""
}

fileprivate extension GameCubeDiscParser {
    static func be32(_ data: Data, offset: Int) -> UInt32 {
        guard offset + 4 <= data.count else { return 0 }
        let bytes = Array(data[offset..<(offset + 4)])
        return (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16) | (UInt32(bytes[2]) << 8) | UInt32(bytes[3])
    }

    static func be32(_ bytes: [UInt8], offset: Int) -> UInt32 {
        guard offset + 4 <= bytes.count else { return 0 }
        return (UInt32(bytes[offset]) << 24) | (UInt32(bytes[offset + 1]) << 16) | (UInt32(bytes[offset + 2]) << 8) | UInt32(bytes[offset + 3])
    }
}
