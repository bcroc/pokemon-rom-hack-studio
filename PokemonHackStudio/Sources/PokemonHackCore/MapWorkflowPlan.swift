import Foundation

public struct MapWorkflowExecutionState: Codable, Equatable {
    public let canApply: Bool
    public let canExport: Bool
    public let reasons: [String]

    public init(canApply: Bool = false, canExport: Bool = false, reasons: [String] = []) {
        self.canApply = canApply
        self.canExport = canExport
        self.reasons = reasons
    }
}

public struct MapWorkflowSourceSnapshot: Codable, Equatable, Identifiable {
    public var id: String { relativePath }

    public let relativePath: String
    public let exists: Bool
    public let byteCount: Int?
    public let sha1: String?

    public init(relativePath: String, exists: Bool, byteCount: Int? = nil, sha1: String? = nil) {
        self.relativePath = relativePath
        self.exists = exists
        self.byteCount = byteCount
        self.sha1 = sha1
    }
}

public enum MapDuplicationPlannedFileAction: String, Codable, Equatable, CaseIterable {
    case copy
    case copyAndRewrite
    case updateIndex
}

public struct MapDuplicationPlannedFile: Codable, Equatable, Identifiable {
    public var id: String { "\(action.rawValue):\(destinationPath ?? sourcePath)" }

    public let action: MapDuplicationPlannedFileAction
    public let sourcePath: String
    public let destinationPath: String?
    public let summary: String

    public init(
        action: MapDuplicationPlannedFileAction,
        sourcePath: String,
        destinationPath: String? = nil,
        summary: String
    ) {
        self.action = action
        self.sourcePath = sourcePath
        self.destinationPath = destinationPath
        self.summary = summary
    }
}

public struct MapDuplicationPlan: Codable, Equatable, Identifiable {
    public let id: String
    public let rootPath: String
    public let sourceMapID: String
    public let proposedMapID: String
    public let proposedMapName: String
    public let proposedLayoutID: String?
    public let proposedLayoutName: String?
    public let duplicateLayout: Bool
    public let sourceSnapshots: [MapWorkflowSourceSnapshot]
    public let plannedFiles: [MapDuplicationPlannedFile]
    public let mutationPlan: MutationPlan
    public let diagnostics: [Diagnostic]
    public let executionState: MapWorkflowExecutionState

    public init(
        id: String = UUID().uuidString,
        rootPath: String,
        sourceMapID: String,
        proposedMapID: String,
        proposedMapName: String,
        proposedLayoutID: String?,
        proposedLayoutName: String?,
        duplicateLayout: Bool,
        sourceSnapshots: [MapWorkflowSourceSnapshot],
        plannedFiles: [MapDuplicationPlannedFile],
        mutationPlan: MutationPlan,
        diagnostics: [Diagnostic],
        executionState: MapWorkflowExecutionState
    ) {
        self.id = id
        self.rootPath = rootPath
        self.sourceMapID = sourceMapID
        self.proposedMapID = proposedMapID
        self.proposedMapName = proposedMapName
        self.proposedLayoutID = proposedLayoutID
        self.proposedLayoutName = proposedLayoutName
        self.duplicateLayout = duplicateLayout
        self.sourceSnapshots = sourceSnapshots
        self.plannedFiles = plannedFiles
        self.mutationPlan = mutationPlan
        self.diagnostics = diagnostics
        self.executionState = executionState
    }
}

public struct MapRegionPreviewMetadata: Codable, Equatable, Identifiable {
    public var id: String { mapID }

    public let mapID: String
    public let mapName: String
    public let sourcePath: String
    public let regionMapSection: String?
    public let displayName: String
    public let floorNumber: Int?
    public let usesFallback: Bool
    public let diagnostics: [Diagnostic]

    public init(
        mapID: String,
        mapName: String,
        sourcePath: String,
        regionMapSection: String?,
        displayName: String,
        floorNumber: Int?,
        usesFallback: Bool,
        diagnostics: [Diagnostic] = []
    ) {
        self.mapID = mapID
        self.mapName = mapName
        self.sourcePath = sourcePath
        self.regionMapSection = regionMapSection
        self.displayName = displayName
        self.floorNumber = floorNumber
        self.usesFallback = usesFallback
        self.diagnostics = diagnostics
    }
}

public struct MapBlockPrefab: Codable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let width: Int
    public let height: Int
    public let rawValues: [UInt16]

    public init(id: String = UUID().uuidString, name: String, width: Int, height: Int, rawValues: [UInt16]) {
        self.id = id
        self.name = name
        self.width = width
        self.height = height
        self.rawValues = rawValues
    }
}

public struct MapPrefabPastePlan: Codable, Equatable, Identifiable {
    public let id: String
    public let documentID: String
    public let target: MapBlockTarget
    public let x: Int
    public let y: Int
    public let prefab: MapBlockPrefab
    public let operation: MapEditOperation?
    public let mapEditPlan: MapEditPlan?
    public let mutationPlan: MutationPlan
    public let diagnostics: [Diagnostic]
    public let executionState: MapWorkflowExecutionState

    public init(
        id: String = UUID().uuidString,
        documentID: String,
        target: MapBlockTarget,
        x: Int,
        y: Int,
        prefab: MapBlockPrefab,
        operation: MapEditOperation?,
        mapEditPlan: MapEditPlan?,
        mutationPlan: MutationPlan,
        diagnostics: [Diagnostic],
        executionState: MapWorkflowExecutionState
    ) {
        self.id = id
        self.documentID = documentID
        self.target = target
        self.x = x
        self.y = y
        self.prefab = prefab
        self.operation = operation
        self.mapEditPlan = mapEditPlan
        self.mutationPlan = mutationPlan
        self.diagnostics = diagnostics
        self.executionState = executionState
    }
}

public enum MapVisualExportFormat: String, Codable, Equatable, CaseIterable {
    case png
    case json

    public var fileExtension: String {
        switch self {
        case .png:
            return "png"
        case .json:
            return "json"
        }
    }
}

public struct MapVisualExportArtifact: Codable, Equatable, Identifiable {
    public var id: String { relativePath }

    public let relativePath: String
    public let absolutePath: String
    public let role: SourceRole
    public let isIgnoredWorkspaceArtifact: Bool
    public let exists: Bool

    public init(
        relativePath: String,
        absolutePath: String,
        role: SourceRole = .artifact,
        isIgnoredWorkspaceArtifact: Bool,
        exists: Bool = false
    ) {
        self.relativePath = relativePath
        self.absolutePath = absolutePath
        self.role = role
        self.isIgnoredWorkspaceArtifact = isIgnoredWorkspaceArtifact
        self.exists = exists
    }
}

public struct MapVisualExportPlan: Codable, Equatable, Identifiable {
    public let id: String
    public let documentID: String
    public let mapID: String
    public let mapName: String
    public let format: MapVisualExportFormat
    public let artifacts: [MapVisualExportArtifact]
    public let mutationPlan: MutationPlan
    public let diagnostics: [Diagnostic]
    public let executionState: MapWorkflowExecutionState

    public init(
        id: String = UUID().uuidString,
        documentID: String,
        mapID: String,
        mapName: String,
        format: MapVisualExportFormat,
        artifacts: [MapVisualExportArtifact],
        mutationPlan: MutationPlan,
        diagnostics: [Diagnostic],
        executionState: MapWorkflowExecutionState
    ) {
        self.id = id
        self.documentID = documentID
        self.mapID = mapID
        self.mapName = mapName
        self.format = format
        self.artifacts = artifacts
        self.mutationPlan = mutationPlan
        self.diagnostics = diagnostics
        self.executionState = executionState
    }
}

public enum MapWorkflowPlanner {
    public static func planDuplication(
        catalog: ProjectMapCatalog,
        sourceMapID: String,
        proposedMapID: String,
        proposedMapName: String? = nil,
        proposedLayoutID: String? = nil,
        proposedLayoutName: String? = nil,
        duplicateLayout: Bool = true,
        fileManager: FileManager = .default
    ) -> MapDuplicationPlan {
        let rootPath = URL(fileURLWithPath: catalog.rootPath).standardizedFileURL.path
        let resolvedMapName = sanitizedPathComponent(proposedMapName ?? mapName(fromMapID: proposedMapID), fallback: proposedMapID)
        var resolvedLayoutID = proposedLayoutID
        var resolvedLayoutName = proposedLayoutName
        var diagnostics: [Diagnostic] = []
        var plannedFiles: [MapDuplicationPlannedFile] = []
        var snapshotPaths = Set<String>()

        guard let sourceMap = resolveMap(sourceMapID, in: catalog) else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "MAP_DUPLICATION_SOURCE_MISSING",
                    message: "Cannot plan map duplication because \(sourceMapID) is not indexed."
                )
            )
            return duplicationPlan(
                rootPath: rootPath,
                sourceMapID: sourceMapID,
                proposedMapID: proposedMapID,
                proposedMapName: resolvedMapName,
                proposedLayoutID: resolvedLayoutID,
                proposedLayoutName: resolvedLayoutName,
                duplicateLayout: duplicateLayout,
                sourceSnapshots: [],
                plannedFiles: [],
                diagnostics: diagnostics
            )
        }

        snapshotPaths.insert(sourceMap.sourcePath)
        if catalog.maps.contains(where: { $0.id == proposedMapID }) {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "MAP_DUPLICATION_MAP_ID_CONFLICT",
                    message: "A map with id \(proposedMapID) already exists.",
                    span: SourceSpan(relativePath: sourceMap.sourcePath, startLine: 1)
                )
            )
        }
        if catalog.maps.contains(where: { $0.name == resolvedMapName }) {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "MAP_DUPLICATION_MAP_NAME_CONFLICT",
                    message: "A map folder/name \(resolvedMapName) already exists.",
                    span: SourceSpan(relativePath: sourceMap.sourcePath, startLine: 1)
                )
            )
        }

        let newMapPath = "data/maps/\(resolvedMapName)/map.json"
        if pathAlreadyExists(newMapPath, rootPath: rootPath, catalogMapPaths: catalog.maps.map(\.sourcePath), fileManager: fileManager) {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "MAP_DUPLICATION_MAP_PATH_CONFLICT",
                    message: "The planned map source path already exists: \(newMapPath).",
                    span: SourceSpan(relativePath: newMapPath, startLine: 1)
                )
            )
        }

        plannedFiles.append(
            MapDuplicationPlannedFile(
                action: .copyAndRewrite,
                sourcePath: sourceMap.sourcePath,
                destinationPath: newMapPath,
                summary: "Copy map JSON and rewrite id/name/layout references for \(proposedMapID)."
            )
        )
        plannedFiles.append(
            MapDuplicationPlannedFile(
                action: .updateIndex,
                sourcePath: "data/maps/map_groups.json",
                summary: "Add \(resolvedMapName) to the source map group near \(sourceMap.name)."
            )
        )
        snapshotPaths.insert("data/maps/map_groups.json")

        if duplicateLayout {
            if let sourceLayout = resolveLayout(for: sourceMap, in: catalog) {
                snapshotPaths.insert(sourceLayout.sourcePath)
                if let blockdataPath = sourceLayout.blockdataFilepath {
                    snapshotPaths.insert(blockdataPath)
                }
                if let borderPath = sourceLayout.borderFilepath {
                    snapshotPaths.insert(borderPath)
                }

                resolvedLayoutID = resolvedLayoutID ?? defaultLayoutID(for: sourceLayout, proposedMapID: proposedMapID)
                resolvedLayoutName = resolvedLayoutName ?? defaultLayoutName(for: sourceLayout, proposedMapName: resolvedMapName)

                if let resolvedLayoutID, catalog.layoutSlots.contains(where: { $0.layoutID == resolvedLayoutID }) {
                    diagnostics.append(
                        Diagnostic(
                            severity: .error,
                            code: "MAP_DUPLICATION_LAYOUT_ID_CONFLICT",
                            message: "A layout with id \(resolvedLayoutID) already exists.",
                            span: SourceSpan(relativePath: sourceLayout.sourcePath, startLine: 1)
                        )
                    )
                }
                if let resolvedLayoutName, catalog.layoutSlots.contains(where: { $0.name == resolvedLayoutName }) {
                    diagnostics.append(
                        Diagnostic(
                            severity: .error,
                            code: "MAP_DUPLICATION_LAYOUT_NAME_CONFLICT",
                            message: "A layout named \(resolvedLayoutName) already exists.",
                            span: SourceSpan(relativePath: sourceLayout.sourcePath, startLine: 1)
                        )
                    )
                }

                let layoutFolder = sanitizedPathComponent(resolvedLayoutName ?? resolvedMapName, fallback: resolvedMapName)
                plannedFiles.append(
                    MapDuplicationPlannedFile(
                        action: .updateIndex,
                        sourcePath: sourceLayout.sourcePath,
                        summary: "Add a layout slot for \(resolvedLayoutID ?? proposedMapID) while preserving layout order."
                    )
                )
                appendLayoutCopy(
                    sourcePath: sourceLayout.blockdataFilepath,
                    basenameFallback: "map.bin",
                    layoutFolder: layoutFolder,
                    rootPath: rootPath,
                    fileManager: fileManager,
                    plannedFiles: &plannedFiles,
                    diagnostics: &diagnostics
                )
                appendLayoutCopy(
                    sourcePath: sourceLayout.borderFilepath,
                    basenameFallback: "border.bin",
                    layoutFolder: layoutFolder,
                    rootPath: rootPath,
                    fileManager: fileManager,
                    plannedFiles: &plannedFiles,
                    diagnostics: &diagnostics
                )
            } else {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "MAP_DUPLICATION_SOURCE_LAYOUT_MISSING",
                        message: "Cannot duplicate \(sourceMap.id) because its layout could not be resolved.",
                        span: SourceSpan(relativePath: sourceMap.sourcePath, startLine: 1)
                    )
                )
            }
        }

        let snapshots = captureSourceSnapshots(rootPath: rootPath, paths: Array(snapshotPaths).sorted(), fileManager: fileManager)
        return duplicationPlan(
            rootPath: rootPath,
            sourceMapID: sourceMap.id,
            proposedMapID: proposedMapID,
            proposedMapName: resolvedMapName,
            proposedLayoutID: resolvedLayoutID,
            proposedLayoutName: resolvedLayoutName,
            duplicateLayout: duplicateLayout,
            sourceSnapshots: snapshots,
            plannedFiles: plannedFiles,
            diagnostics: diagnostics
        )
    }

    public static func captureSourceSnapshots(
        rootPath: String,
        paths: [String],
        fileManager: FileManager = .default
    ) -> [MapWorkflowSourceSnapshot] {
        let root = URL(fileURLWithPath: rootPath).standardizedFileURL
        return paths.map { path in
            guard !isUnsafeRelativePath(path) else {
                return MapWorkflowSourceSnapshot(relativePath: path, exists: false)
            }
            let url = root.appendingPathComponent(path)
            guard fileManager.fileExists(atPath: url.path), let data = try? Data(contentsOf: url) else {
                return MapWorkflowSourceSnapshot(relativePath: path, exists: false)
            }
            return MapWorkflowSourceSnapshot(
                relativePath: path,
                exists: true,
                byteCount: data.count,
                sha1: pokemonHackSHA1Hex(data)
            )
        }
    }

    public static func externalChangeDiagnostics(
        rootPath: String,
        snapshots: [MapWorkflowSourceSnapshot],
        fileManager: FileManager = .default
    ) -> [Diagnostic] {
        let root = URL(fileURLWithPath: rootPath).standardizedFileURL
        var diagnostics: [Diagnostic] = []

        for snapshot in snapshots {
            if isUnsafeRelativePath(snapshot.relativePath) {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "MAP_WORKFLOW_SOURCE_PATH_UNSAFE",
                        message: "Snapshot path must stay inside the project root: \(snapshot.relativePath)."
                    )
                )
                continue
            }

            let url = root.appendingPathComponent(snapshot.relativePath)
            let currentData = (fileManager.fileExists(atPath: url.path) ? try? Data(contentsOf: url) : nil)
            if snapshot.exists, currentData == nil {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "MAP_WORKFLOW_SOURCE_MISSING",
                        message: "Source file changed externally and is now missing: \(snapshot.relativePath).",
                        span: SourceSpan(relativePath: snapshot.relativePath, startLine: 1)
                    )
                )
                continue
            }
            if !snapshot.exists, currentData != nil {
                diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        code: "MAP_WORKFLOW_SOURCE_CREATED",
                        message: "Source file appeared after the workflow snapshot: \(snapshot.relativePath).",
                        span: SourceSpan(relativePath: snapshot.relativePath, startLine: 1)
                    )
                )
                continue
            }
            guard let currentData else { continue }
            if let byteCount = snapshot.byteCount, currentData.count != byteCount {
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: "MAP_WORKFLOW_SOURCE_SIZE_MISMATCH",
                        message: "\(snapshot.relativePath) changed size from \(byteCount) to \(currentData.count) bytes.",
                        span: SourceSpan(relativePath: snapshot.relativePath, startLine: 1)
                    )
                )
            }
            if let sha1 = snapshot.sha1 {
                let currentSHA1 = pokemonHackSHA1Hex(currentData)
                if currentSHA1 != sha1 {
                    diagnostics.append(
                        Diagnostic(
                            severity: .error,
                            code: "MAP_WORKFLOW_SOURCE_HASH_MISMATCH",
                            message: "\(snapshot.relativePath) changed SHA1 from \(sha1) to \(currentSHA1).",
                            span: SourceSpan(relativePath: snapshot.relativePath, startLine: 1)
                        )
                    )
                }
            }
        }

        return diagnostics
    }

    public static func regionPreviewMetadata(for map: MapDescriptor) -> MapRegionPreviewMetadata {
        let normalizedSection = map.regionMapSection?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasRegionSection = normalizedSection.map { !$0.isEmpty && $0 != "MAPSEC_NONE" } ?? false
        if hasRegionSection, let normalizedSection {
            return MapRegionPreviewMetadata(
                mapID: map.id,
                mapName: map.name,
                sourcePath: map.sourcePath,
                regionMapSection: normalizedSection,
                displayName: displayName(fromRegionSection: normalizedSection),
                floorNumber: map.floorNumber,
                usesFallback: false
            )
        }

        let diagnostic = Diagnostic(
            severity: .info,
            code: "MAP_REGION_PREVIEW_FALLBACK",
            message: "\(map.id) has no concrete region map section; preview metadata falls back to the map name.",
            span: SourceSpan(relativePath: map.sourcePath, startLine: 1)
        )
        return MapRegionPreviewMetadata(
            mapID: map.id,
            mapName: map.name,
            sourcePath: map.sourcePath,
            regionMapSection: normalizedSection,
            displayName: displayName(fromMapName: map.name),
            floorNumber: map.floorNumber,
            usesFallback: true,
            diagnostics: [diagnostic]
        )
    }

    public static func planPrefabPaste(
        document: MapVisualDocument,
        prefab: MapBlockPrefab,
        target: MapBlockTarget = .layout,
        x: Int,
        y: Int
    ) -> MapPrefabPastePlan {
        var diagnostics = prefabDiagnostics(prefab: prefab)
        guard let targetBlockdata = blockdata(target: target, document: document) else {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "MAP_PREFAB_PASTE_TARGET_MISSING",
                    message: "Cannot paste prefab into missing \(target.rawValue) blockdata."
                )
            )
            return blockedPrefabPlan(document: document, prefab: prefab, target: target, x: x, y: y, diagnostics: diagnostics)
        }

        diagnostics.append(contentsOf: boundsDiagnostics(prefab: prefab, target: targetBlockdata, targetKind: target, x: x, y: y))
        guard diagnostics.filter({ $0.severity == .error }).isEmpty else {
            return blockedPrefabPlan(document: document, prefab: prefab, target: target, x: x, y: y, diagnostics: diagnostics)
        }

        let operation = MapEditOperation(
            action: .pasteBlockPattern,
            target: target,
            x: x,
            y: y,
            width: prefab.width,
            height: prefab.height,
            rawValues: prefab.rawValues
        )
        let mapEditPlan = MapMutationPlanner.plan(document: document, operations: [operation])
        let applyability = mapEditPlan.validateApplyability()
        let reasons = applyability.isApplyable ? [] : applyability.diagnostics.map(\.message)
        return MapPrefabPastePlan(
            documentID: document.id,
            target: target,
            x: x,
            y: y,
            prefab: prefab,
            operation: operation,
            mapEditPlan: mapEditPlan,
            mutationPlan: mapEditPlan.mutationPlan,
            diagnostics: mapEditPlan.diagnostics + applyability.diagnostics,
            executionState: MapWorkflowExecutionState(canApply: applyability.isApplyable, canExport: false, reasons: reasons)
        )
    }

    public static func planVisualExport(
        document: MapVisualDocument,
        format: MapVisualExportFormat = .png,
        fileStem: String? = nil,
        fileManager: FileManager = .default
    ) -> MapVisualExportPlan {
        let root = URL(fileURLWithPath: document.rootPath).standardizedFileURL
        let stem = sanitizedPathComponent(fileStem ?? document.mapID.lowercased(), fallback: "map-visual")
        let relativePath = ".pokemonhackstudio/exports/maps/\(stem).\(format.fileExtension)"
        let absolutePath = root.appendingPathComponent(relativePath).path
        let exists = fileManager.fileExists(atPath: absolutePath)
        let artifact = MapVisualExportArtifact(
            relativePath: relativePath,
            absolutePath: absolutePath,
            isIgnoredWorkspaceArtifact: relativePath.hasPrefix(".pokemonhackstudio/"),
            exists: exists
        )
        let diagnostic = Diagnostic(
            severity: .info,
            code: "MAP_VISUAL_EXPORT_PREVIEW_ONLY",
            message: "Visual export is planned under .pokemonhackstudio/exports, but core export writes are disabled in this preview slice."
        )
        let change = PlannedChange(
            path: relativePath,
            summary: "Would write \(format.rawValue.uppercased()) map visual export for \(document.mapID).",
            span: SourceSpan(relativePath: relativePath, startLine: 1)
        )
        let mutationPlan = MutationPlan(
            title: "Preview visual export for \(document.mapName)",
            summary: "1 ignored workspace artifact planned; export is disabled.",
            changes: [change],
            diagnostics: [diagnostic],
            requiresExplicitApply: false
        )

        return MapVisualExportPlan(
            documentID: document.id,
            mapID: document.mapID,
            mapName: document.mapName,
            format: format,
            artifacts: [artifact],
            mutationPlan: mutationPlan,
            diagnostics: [diagnostic],
            executionState: MapWorkflowExecutionState(
                canApply: false,
                canExport: false,
                reasons: ["Visual export is preview-only and writes no files until an explicit exporter is implemented."]
            )
        )
    }

    private static func duplicationPlan(
        rootPath: String,
        sourceMapID: String,
        proposedMapID: String,
        proposedMapName: String,
        proposedLayoutID: String?,
        proposedLayoutName: String?,
        duplicateLayout: Bool,
        sourceSnapshots: [MapWorkflowSourceSnapshot],
        plannedFiles: [MapDuplicationPlannedFile],
        diagnostics: [Diagnostic]
    ) -> MapDuplicationPlan {
        let plannedChanges = plannedFiles.map {
            PlannedChange(
                path: $0.destinationPath ?? $0.sourcePath,
                summary: $0.summary,
                span: SourceSpan(relativePath: $0.destinationPath ?? $0.sourcePath, startLine: 1)
            )
        }
        let mutationPlan = MutationPlan(
            title: "Preview map duplication for \(proposedMapID)",
            summary: "\(plannedFiles.count) source-tree file operation(s) planned; apply is disabled for this workflow slice.",
            changes: plannedChanges,
            diagnostics: diagnostics,
            requiresExplicitApply: true
        )
        var reasons = ["Map/layout duplication apply is disabled until the workflow can be connected to a dedicated source-tree applier."]
        if diagnostics.contains(where: { $0.severity == .error }) {
            reasons.append("Resolve blocking diagnostics before any future source-tree apply.")
        }

        return MapDuplicationPlan(
            rootPath: rootPath,
            sourceMapID: sourceMapID,
            proposedMapID: proposedMapID,
            proposedMapName: proposedMapName,
            proposedLayoutID: proposedLayoutID,
            proposedLayoutName: proposedLayoutName,
            duplicateLayout: duplicateLayout,
            sourceSnapshots: sourceSnapshots,
            plannedFiles: plannedFiles,
            mutationPlan: mutationPlan,
            diagnostics: diagnostics,
            executionState: MapWorkflowExecutionState(canApply: false, canExport: false, reasons: reasons)
        )
    }

    private static func resolveMap(_ idOrName: String, in catalog: ProjectMapCatalog) -> MapDescriptor? {
        catalog.maps.first { $0.id == idOrName || $0.name == idOrName }
    }

    private static func resolveLayout(for map: MapDescriptor, in catalog: ProjectMapCatalog) -> LayoutSlot? {
        if let slotIndex = map.layoutSlotIndex {
            return catalog.layoutSlots.first { $0.slotIndex == slotIndex }
        }
        if let layoutID = map.layout {
            return catalog.layoutSlots.first { $0.layoutID == layoutID }
        }
        return nil
    }

    private static func appendLayoutCopy(
        sourcePath: String?,
        basenameFallback: String,
        layoutFolder: String,
        rootPath: String,
        fileManager: FileManager,
        plannedFiles: inout [MapDuplicationPlannedFile],
        diagnostics: inout [Diagnostic]
    ) {
        guard let sourcePath else { return }
        let basename = URL(fileURLWithPath: sourcePath).lastPathComponent.isEmpty
            ? basenameFallback
            : URL(fileURLWithPath: sourcePath).lastPathComponent
        let destinationPath = "data/layouts/\(layoutFolder)/\(basename)"
        if fileManager.fileExists(atPath: URL(fileURLWithPath: rootPath).appendingPathComponent(destinationPath).path) {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "MAP_DUPLICATION_LAYOUT_PATH_CONFLICT",
                    message: "The planned layout artifact path already exists: \(destinationPath).",
                    span: SourceSpan(relativePath: destinationPath, startLine: 1)
                )
            )
        }
        plannedFiles.append(
            MapDuplicationPlannedFile(
                action: .copy,
                sourcePath: sourcePath,
                destinationPath: destinationPath,
                summary: "Copy layout artifact \(sourcePath) to \(destinationPath)."
            )
        )
    }

    private static func pathAlreadyExists(
        _ path: String,
        rootPath: String,
        catalogMapPaths: [String],
        fileManager: FileManager
    ) -> Bool {
        catalogMapPaths.contains(path)
            || fileManager.fileExists(atPath: URL(fileURLWithPath: rootPath).appendingPathComponent(path).path)
    }

    private static func defaultLayoutID(for layout: LayoutSlot, proposedMapID: String) -> String {
        if let layoutID = layout.layoutID, !layoutID.isEmpty {
            return "\(layoutID)_COPY"
        }
        return "LAYOUT_\(proposedMapID.replacingOccurrences(of: "MAP_", with: ""))"
    }

    private static func defaultLayoutName(for layout: LayoutSlot, proposedMapName: String) -> String {
        if let name = layout.name, !name.isEmpty {
            return "\(name)_Copy"
        }
        return "\(proposedMapName)_Layout"
    }

    private static func mapName(fromMapID mapID: String) -> String {
        let trimmed = mapID.hasPrefix("MAP_") ? String(mapID.dropFirst(4)) : mapID
        return trimmed
            .split(separator: "_")
            .map { token in
                token.prefix(1).uppercased() + token.dropFirst().lowercased()
            }
            .joined()
    }

    private static func prefabDiagnostics(prefab: MapBlockPrefab) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        if prefab.width <= 0 || prefab.height <= 0 {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "MAP_PREFAB_DIMENSIONS_INVALID",
                    message: "Prefab \(prefab.name) must have positive width and height."
                )
            )
        }
        let expectedCount = max(prefab.width, 0) * max(prefab.height, 0)
        if prefab.rawValues.count != expectedCount {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    code: "MAP_PREFAB_RAW_VALUE_COUNT_MISMATCH",
                    message: "Prefab \(prefab.name) contains \(prefab.rawValues.count) metatiles; expected \(expectedCount)."
                )
            )
        }
        return diagnostics
    }

    private static func blockdata(target: MapBlockTarget, document: MapVisualDocument) -> EditableLayoutBlockdata? {
        switch target {
        case .layout:
            return document.blockdata
        case .border:
            return document.border
        }
    }

    private static func boundsDiagnostics(
        prefab: MapBlockPrefab,
        target: EditableLayoutBlockdata,
        targetKind: MapBlockTarget,
        x: Int,
        y: Int
    ) -> [Diagnostic] {
        guard x >= 0, y >= 0, prefab.width > 0, prefab.height > 0,
              x + prefab.width <= target.width,
              y + prefab.height <= target.height
        else {
            return [
                Diagnostic(
                    severity: .error,
                    code: "MAP_PREFAB_PASTE_OUT_OF_BOUNDS",
                    message: "Prefab \(prefab.name) at \(x),\(y) with size \(prefab.width)x\(prefab.height) does not fit inside \(targetKind.rawValue) \(target.width)x\(target.height).",
                    span: SourceSpan(relativePath: target.filepath, startLine: 1)
                )
            ]
        }
        return []
    }

    private static func blockedPrefabPlan(
        document: MapVisualDocument,
        prefab: MapBlockPrefab,
        target: MapBlockTarget,
        x: Int,
        y: Int,
        diagnostics: [Diagnostic]
    ) -> MapPrefabPastePlan {
        let mutationPlan = MutationPlan(
            title: "Preview prefab paste for \(document.mapName)",
            summary: "Prefab paste cannot be staged until blocking diagnostics are resolved.",
            changes: [],
            diagnostics: diagnostics,
            requiresExplicitApply: true
        )
        return MapPrefabPastePlan(
            documentID: document.id,
            target: target,
            x: x,
            y: y,
            prefab: prefab,
            operation: nil,
            mapEditPlan: nil,
            mutationPlan: mutationPlan,
            diagnostics: diagnostics,
            executionState: MapWorkflowExecutionState(canApply: false, canExport: false, reasons: diagnostics.map(\.message))
        )
    }

    private static func displayName(fromRegionSection section: String) -> String {
        let stripped = section.hasPrefix("MAPSEC_") ? String(section.dropFirst(7)) : section
        return stripped
            .split(separator: "_")
            .map { token in
                token.prefix(1).uppercased() + token.dropFirst().lowercased()
            }
            .joined(separator: " ")
    }

    private static func displayName(fromMapName name: String) -> String {
        let tokens = name
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
        guard !tokens.isEmpty else { return name }
        return tokens
            .map { token in
                token.prefix(1).uppercased() + token.dropFirst()
            }
            .joined(separator: " ")
    }

    private static func sanitizedPathComponent(_ value: String, fallback: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        let scalars = value.unicodeScalars.map { scalar -> Character in
            if allowed.contains(scalar) {
                return Character(scalar)
            }
            return "_"
        }
        let sanitized = String(scalars)
            .split(separator: "_")
            .joined(separator: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        if sanitized.isEmpty {
            return fallback.isEmpty ? "map" : fallback
        }
        return sanitized
    }

    private static func isUnsafeRelativePath(_ path: String) -> Bool {
        path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || (path as NSString).isAbsolutePath
            || path.split(separator: "/").contains("..")
    }
}
