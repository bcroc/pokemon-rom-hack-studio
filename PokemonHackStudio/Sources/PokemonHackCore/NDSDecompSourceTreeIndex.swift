import Foundation

public struct NDSDecompSourceVariant: Codable, Equatable, Sendable {
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

public enum NDSDecompBuildSystem: String, Codable, Equatable, CaseIterable, Sendable {
    case make
    case meson
    case makeAndCMake
    case unknown
}

public enum NDSDecompSourcePathRole: String, Codable, Equatable, CaseIterable, Sendable {
    case marker
    case source
    case nitroFSRoot
    case generated
    case buildOutput
}

public struct NDSDecompSourcePath: Codable, Equatable {
    public let relativePath: String
    public let kind: SourceKind
    public let role: NDSDecompSourcePathRole
    public let exists: Bool

    public init(relativePath: String, kind: SourceKind, role: NDSDecompSourcePathRole, exists: Bool) {
        self.relativePath = relativePath
        self.kind = kind
        self.role = role
        self.exists = exists
    }
}

public struct NDSDecompSourceTreeIndex: Codable, Equatable {
    public let root: SourceLocation
    public let profile: GameProfile
    public let family: GenIIIGameFamily
    public let displayName: String
    public let buildSystem: NDSDecompBuildSystem
    public let markerDocuments: [SourceDocument]
    public let sourceDocuments: [SourceDocument]
    public let generatedOutputs: [SourceDocument]
    public let variants: [NDSDecompSourceVariant]
    public let buildTargets: [BuildTarget]
    public let diagnostics: [Diagnostic]
    public let writePolicy: WritePolicy

    public var documents: [SourceDocument] {
        markerDocuments + sourceDocuments
    }

    public var paths: [NDSDecompSourcePath] {
        markerDocuments.map { path(from: $0, role: .marker) }
            + sourceDocuments.map { path(from: $0, role: nitroFSRoots.contains($0.relativePath) ? .nitroFSRoot : .source) }
            + generatedOutputs.map { path(from: $0, role: $0.role == .artifact ? .buildOutput : .generated) }
    }

    private var nitroFSRoots: Set<String> {
        ["files", "res"]
    }

    private func path(from document: SourceDocument, role: NDSDecompSourcePathRole) -> NDSDecompSourcePath {
        NDSDecompSourcePath(
            relativePath: document.relativePath,
            kind: document.kind,
            role: role,
            exists: document.exists
        )
    }

    public init(
        root: SourceLocation,
        profile: GameProfile,
        family: GenIIIGameFamily,
        displayName: String,
        buildSystem: NDSDecompBuildSystem,
        markerDocuments: [SourceDocument],
        sourceDocuments: [SourceDocument],
        generatedOutputs: [SourceDocument],
        variants: [NDSDecompSourceVariant],
        buildTargets: [BuildTarget],
        diagnostics: [Diagnostic] = [],
        writePolicy: WritePolicy = .readOnly
    ) {
        self.root = root
        self.profile = profile
        self.family = family
        self.displayName = displayName
        self.buildSystem = buildSystem
        self.markerDocuments = markerDocuments
        self.sourceDocuments = sourceDocuments
        self.generatedOutputs = generatedOutputs
        self.variants = variants
        self.buildTargets = buildTargets
        self.diagnostics = diagnostics
        self.writePolicy = writePolicy
    }
}

public enum NDSDecompSourceTreeIndexBuilder {
    public static func detectProfile(at root: URL, fileManager: FileManager = .default) -> GameProfile? {
        spec(for: root, fileManager: fileManager)?.profile
    }

    public static func build(root: URL, fileManager: FileManager = .default) throws -> NDSDecompSourceTreeIndex {
        let standardizedRoot = root.standardizedFileURL
        guard directoryExists(standardizedRoot, fileManager: fileManager) else {
            throw PokemonHackCoreError.unsupportedProject(standardizedRoot.path)
        }
        guard let spec = spec(for: standardizedRoot, fileManager: fileManager) else {
            throw PokemonHackCoreError.unsupportedProject(standardizedRoot.path)
        }

        let markerDocuments = spec.markerDocuments(root: standardizedRoot, fileManager: fileManager)
        let sourceDocuments = spec.sourceDocuments(root: standardizedRoot, fileManager: fileManager)
        let generatedOutputs = spec.generatedOutputs(root: standardizedRoot, fileManager: fileManager)
        let diagnostics = [
            Diagnostic(
                severity: .info,
                code: "NDS_DECOMP_READ_ONLY",
                message: "Nintendo DS decomp workflows remain preview-first; only eligible source-backed data records can be edited through explicit mutation plans."
            )
        ] + missingDiagnostics(sourceDocuments)

        return NDSDecompSourceTreeIndex(
            root: SourceLocation(path: standardizedRoot.path, exists: true),
            profile: spec.profile,
            family: spec.family,
            displayName: spec.displayName,
            buildSystem: spec.buildSystem,
            markerDocuments: markerDocuments,
            sourceDocuments: sourceDocuments,
            generatedOutputs: generatedOutputs,
            variants: spec.variants,
            buildTargets: spec.buildTargets,
            diagnostics: diagnostics
        )
    }

    private static func spec(for root: URL, fileManager: FileManager) -> NDSDecompProfileSpec? {
        guard directoryExists(root, fileManager: fileManager) else { return nil }
        return specs.first { $0.matches(root: root, fileManager: fileManager) }
    }

    private static func missingDiagnostics(_ documents: [SourceDocument]) -> [Diagnostic] {
        documents.compactMap { document in
            guard !document.exists else { return nil }
            return Diagnostic(
                severity: .warning,
                code: "NDS_SOURCE_PATH_MISSING",
                message: "Expected NDS source path is not present: \(document.relativePath)",
                span: SourceSpan(relativePath: document.relativePath, startLine: 1)
            )
        }
    }

    private static let specs: [NDSDecompProfileSpec] = [
        NDSDecompProfileSpec(
            profile: .pokeplatinum,
            displayName: "pokeplatinum",
            family: .platinum,
            buildSystem: .meson,
            requiredMarkers: [
                ("Makefile", .makefile),
                ("meson.build", .configuration),
                ("platinum.us", .configuration),
                ("platinum.us/filesys.csv", .configuration)
            ],
            anyMarkerGroups: [
                [("platinum.us/rom_rev0.sha1", .configuration), ("platinum.us/rom_rev1.sha1", .configuration)]
            ],
            sourceDocumentPaths: [
                ("src", .cSource),
                ("asm", .assembly),
                ("include", .cHeader),
                ("res", .binary),
                ("generated", .generated)
            ],
            generatedOutputPaths: [
                ("build", .artifact),
                ("build/pokeplatinum.us.nds", .artifact),
                ("build/debug.nef", .artifact),
                ("build/overlay.map", .artifact)
            ],
            variants: [
                NDSDecompSourceVariant(id: "platinum.us.rev0", title: "Pokemon Platinum US Rev 0", outputPath: "build/pokeplatinum.us.nds", checksumPath: "platinum.us/rom_rev0.sha1"),
                NDSDecompSourceVariant(id: "platinum.us.rev1", title: "Pokemon Platinum US Rev 1", outputPath: "build/pokeplatinum.us.nds", checksumPath: "platinum.us/rom_rev1.sha1")
            ],
            buildTargets: [
                BuildTarget(id: "platinum-rom", name: "Build Platinum ROM", kind: .build, command: ["make", "rom"], outputPath: "build/pokeplatinum.us.nds"),
                BuildTarget(id: "platinum-test", name: "Run Platinum Tests", kind: .test, command: ["make", "test"])
            ]
        ),
        NDSDecompProfileSpec(
            profile: .pokeheartgold,
            displayName: "pokeheartgold / pokesoulsilver",
            family: .heartGoldSoulSilver,
            buildSystem: .makeAndCMake,
            requiredMarkers: [
                ("Makefile", .makefile),
                ("config.mk", .configuration),
                ("rom.rsf", .configuration),
                ("filesystem.mk", .configuration),
                ("files", .binary)
            ],
            optionalMarkers: [
                ("main.lsf", .configuration)
            ],
            anyMarkerGroups: [
                [("heartgold.us", .configuration), ("soulsilver.us", .configuration)],
                [("heartgold.us/rom.sha1", .configuration), ("soulsilver.us/rom.sha1", .configuration)]
            ],
            sourceDocumentPaths: [
                ("src", .cSource),
                ("asm", .assembly),
                ("include", .cHeader),
                ("files", .binary),
                ("scripts", .script),
                ("sub", .assembly),
                ("charmap.txt", .text)
            ],
            generatedOutputPaths: [
                ("build", .artifact),
                ("build/heartgold.us/pokeheartgold.us.nds", .artifact),
                ("build/soulsilver.us/pokesoulsilver.us.nds", .artifact)
            ],
            variants: [
                NDSDecompSourceVariant(id: "heartgold.us", title: "Pokemon HeartGold US", outputPath: "build/heartgold.us/pokeheartgold.us.nds", checksumPath: "heartgold.us/rom.sha1"),
                NDSDecompSourceVariant(id: "soulsilver.us", title: "Pokemon SoulSilver US", outputPath: "build/soulsilver.us/pokesoulsilver.us.nds", checksumPath: "soulsilver.us/rom.sha1")
            ],
            buildTargets: [
                BuildTarget(id: "heartgold-rom", name: "Build HeartGold ROM", kind: .build, command: ["make", "heartgold"], outputPath: "build/heartgold.us/pokeheartgold.us.nds"),
                BuildTarget(id: "soulsilver-rom", name: "Build SoulSilver ROM", kind: .build, command: ["make", "soulsilver"], outputPath: "build/soulsilver.us/pokesoulsilver.us.nds")
            ]
        ),
        NDSDecompProfileSpec(
            profile: .pmdSky,
            displayName: "pmd-sky",
            family: .ndsUnknown,
            buildSystem: .make,
            requiredMarkers: [
                ("Makefile", .makefile),
                ("config.mk", .configuration),
                ("rom.rsf", .configuration),
                ("filesystem.mk", .configuration),
                ("files", .binary)
            ],
            optionalMarkers: [
                ("main.lsf", .configuration)
            ],
            anyMarkerGroups: [
                [("pmdsky.us", .configuration), ("pmdsky.eu", .configuration), ("pmdsky.jp", .configuration)],
                [("pmdsky.us/rom.sha1", .configuration), ("pmdsky.eu/rom.sha1", .configuration), ("pmdsky.jp/rom.sha1", .configuration)],
                [("nitrofs_files.txt", .configuration), ("nitrofs_files_eu.txt", .configuration), ("nitrofs_files_jp.txt", .configuration)]
            ],
            sourceDocumentPaths: [
                ("src", .cSource),
                ("asm", .assembly),
                ("include", .cHeader),
                ("files", .binary),
                ("sub", .assembly),
                ("charmap.txt", .text)
            ],
            generatedOutputPaths: [
                ("build", .artifact),
                ("build/pmdsky.us/pmdsky.us.nds", .artifact),
                ("build/pmdsky.eu/pmdsky.eu.nds", .artifact),
                ("build/pmdsky.jp/pmdsky.jp.nds", .artifact)
            ],
            variants: [
                NDSDecompSourceVariant(id: "pmdsky.us", title: "PMD Sky US", outputPath: "build/pmdsky.us/pmdsky.us.nds", checksumPath: "pmdsky.us/rom.sha1"),
                NDSDecompSourceVariant(id: "pmdsky.eu", title: "PMD Sky EU", outputPath: "build/pmdsky.eu/pmdsky.eu.nds", checksumPath: "pmdsky.eu/rom.sha1"),
                NDSDecompSourceVariant(id: "pmdsky.jp", title: "PMD Sky JP", outputPath: "build/pmdsky.jp/pmdsky.jp.nds", checksumPath: "pmdsky.jp/rom.sha1")
            ],
            buildTargets: [
                BuildTarget(id: "pmd-sky-us-rom", name: "Build PMD Sky US ROM", kind: .build, command: ["make", "us"], outputPath: "build/pmdsky.us/pmdsky.us.nds"),
                BuildTarget(id: "pmd-sky-eu-rom", name: "Build PMD Sky EU ROM", kind: .build, command: ["make", "eu"], outputPath: "build/pmdsky.eu/pmdsky.eu.nds"),
                BuildTarget(id: "pmd-sky-jp-rom", name: "Build PMD Sky JP ROM", kind: .build, command: ["make", "jp"], outputPath: "build/pmdsky.jp/pmdsky.jp.nds")
            ]
        ),
        NDSDecompProfileSpec(
            profile: .pokediamond,
            displayName: "pokediamond / pokepearl",
            family: .diamondPearl,
            buildSystem: .makeAndCMake,
            requiredMarkers: [
                ("Makefile", .makefile),
                ("config.mk", .configuration),
                ("rom.rsf", .configuration),
                ("filesystem.mk", .configuration),
                ("arm9", .assembly),
                ("arm7", .assembly),
                ("files", .binary)
            ],
            anyMarkerGroups: [
                [
                    ("pokediamond.us.sha1", .configuration),
                    ("pokepearl.us.sha1", .configuration),
                    ("arm9/pokediamond.us.sha1", .configuration),
                    ("arm9/pokepearl.us.sha1", .configuration)
                ]
            ],
            sourceDocumentPaths: [
                ("arm9/src", .cSource),
                ("arm9/asm", .assembly),
                ("arm7/asm", .assembly),
                ("include", .cHeader),
                ("include-mw", .cHeader),
                ("files", .binary),
                ("graphics", .graphics),
                ("charmap.txt", .text)
            ],
            generatedOutputPaths: [
                ("build", .artifact),
                ("build/diamond.us/pokediamond.us.nds", .artifact),
                ("build/pearl.us/pokepearl.us.nds", .artifact)
            ],
            variants: [
                NDSDecompSourceVariant(id: "pokediamond.us", title: "Pokemon Diamond US", outputPath: "build/diamond.us/pokediamond.us.nds", checksumPath: "pokediamond.us.sha1"),
                NDSDecompSourceVariant(id: "pokepearl.us", title: "Pokemon Pearl US", outputPath: "build/pearl.us/pokepearl.us.nds", checksumPath: "pokepearl.us.sha1")
            ],
            buildTargets: [
                BuildTarget(id: "diamond-rom", name: "Build Diamond ROM", kind: .build, command: ["make", "diamond"], outputPath: "build/diamond.us/pokediamond.us.nds"),
                BuildTarget(id: "pearl-rom", name: "Build Pearl ROM", kind: .build, command: ["make", "pearl"], outputPath: "build/pearl.us/pokepearl.us.nds")
            ]
        )
    ]

    private static func directoryExists(_ url: URL, fileManager: FileManager) -> Bool {
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}

private struct NDSDecompProfileSpec: @unchecked Sendable {
    let profile: GameProfile
    let displayName: String
    let family: GenIIIGameFamily
    let buildSystem: NDSDecompBuildSystem
    let requiredMarkers: [(String, SourceKind)]
    var optionalMarkers: [(String, SourceKind)] = []
    let anyMarkerGroups: [[(String, SourceKind)]]
    let sourceDocumentPaths: [(String, SourceKind)]
    let generatedOutputPaths: [(String, SourceRole)]
    let variants: [NDSDecompSourceVariant]
    let buildTargets: [BuildTarget]

    func matches(root: URL, fileManager: FileManager) -> Bool {
        requiredMarkers.allSatisfy { exists($0.0, root: root, fileManager: fileManager) }
            && anyMarkerGroups.allSatisfy { group in
                group.contains { exists($0.0, root: root, fileManager: fileManager) }
            }
    }

    func markerDocuments(root: URL, fileManager: FileManager) -> [SourceDocument] {
        let markerPaths = requiredMarkers + optionalMarkers + anyMarkerGroups.flatMap { $0 }
        return unique(markerPaths).map { path, kind in
            document(path: path, kind: kind, role: .marker, root: root, fileManager: fileManager)
        }
    }

    func sourceDocuments(root: URL, fileManager: FileManager) -> [SourceDocument] {
        unique(sourceDocumentPaths).map { path, kind in
            document(path: path, kind: kind, role: .source, root: root, fileManager: fileManager)
        }
    }

    func generatedOutputs(root: URL, fileManager: FileManager) -> [SourceDocument] {
        unique(generatedOutputPaths).map { path, role in
            document(path: path, kind: .generated, role: role, root: root, fileManager: fileManager)
        }
    }

    private func unique<T>(_ entries: [(String, T)]) -> [(String, T)] {
        var seen: Set<String> = []
        var uniqueEntries: [(String, T)] = []
        for entry in entries where seen.insert(entry.0).inserted {
            uniqueEntries.append(entry)
        }
        return uniqueEntries
    }

    private func exists(_ path: String, root: URL, fileManager: FileManager) -> Bool {
        fileManager.fileExists(atPath: root.appendingPathComponent(path).path)
    }

    private func document(
        path: String,
        kind: SourceKind,
        role: SourceRole,
        root: URL,
        fileManager: FileManager
    ) -> SourceDocument {
        SourceDocument(
            relativePath: path,
            kind: kind,
            role: role,
            exists: exists(path, root: root, fileManager: fileManager),
            preservesUnknownFields: kind == .json
        )
    }
}
