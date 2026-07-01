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
    public let sourceEventCapacity: MapEventCapacitySummary
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
        sourceEventCapacity: MapEventCapacitySummary = .unknown,
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
        self.sourceEventCapacity = sourceEventCapacity
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

public struct MapVisualExportResult: Codable, Equatable, Identifiable {
    public var id: String { relativePath }

    public let relativePath: String
    public let absolutePath: String
    public let byteCount: Int
    public let sha1: String
    public let diagnostics: [Diagnostic]

    public init(relativePath: String, absolutePath: String, byteCount: Int, sha1: String, diagnostics: [Diagnostic] = []) {
        self.relativePath = relativePath
        self.absolutePath = absolutePath
        self.byteCount = byteCount
        self.sha1 = sha1
        self.diagnostics = diagnostics
    }
}

public struct AppliedMapDuplicationFile: Codable, Equatable, Identifiable {
    public var id: String { path }

    public let path: String
    public let action: MapDuplicationPlannedFileAction
    public let backupPath: String?
    public let byteCount: Int

    public init(path: String, action: MapDuplicationPlannedFileAction, backupPath: String? = nil, byteCount: Int) {
        self.path = path
        self.action = action
        self.backupPath = backupPath
        self.byteCount = byteCount
    }
}

public struct MapDuplicationApplyResult: Codable, Equatable {
    public let backupRootPath: String
    public let selectedMapID: String?
    public let appliedFiles: [AppliedMapDuplicationFile]
    public let diagnostics: [Diagnostic]

    public init(
        backupRootPath: String,
        selectedMapID: String?,
        appliedFiles: [AppliedMapDuplicationFile],
        diagnostics: [Diagnostic] = []
    ) {
        self.backupRootPath = backupRootPath
        self.selectedMapID = selectedMapID
        self.appliedFiles = appliedFiles
        self.diagnostics = diagnostics
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
                sourceEventCapacity: .unknown,
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
            sourceEventCapacity: sourceMap.eventCapacity,
            sourceSnapshots: snapshots,
            plannedFiles: plannedFiles,
            diagnostics: diagnostics + sourceMap.eventCapacity.diagnostics
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
            code: "MAP_VISUAL_EXPORT_IGNORED_ARTIFACT_READY",
            message: "Visual export is scoped to ignored .pokemonhackstudio/exports artifacts."
        )
        let change = PlannedChange(
            path: relativePath,
            summary: "Write \(format.rawValue.uppercased()) map visual export for \(document.mapID).",
            span: SourceSpan(relativePath: relativePath, startLine: 1)
        )
        let mutationPlan = MutationPlan(
            title: "Export visual artifact for \(document.mapName)",
            summary: "1 ignored workspace artifact planned under .pokemonhackstudio/exports/maps.",
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
                canExport: artifact.isIgnoredWorkspaceArtifact,
                reasons: artifact.isIgnoredWorkspaceArtifact ? [] : ["Visual export path must stay under ignored .pokemonhackstudio artifacts."]
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
        sourceEventCapacity: MapEventCapacitySummary,
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
        let canApply = diagnostics.allSatisfy { $0.severity != .error } && sourceSnapshots.allSatisfy(\.exists)
        let mutationPlan = MutationPlan(
            title: "Preview map duplication for \(proposedMapID)",
            summary: "\(plannedFiles.count) source-tree file operation(s) planned with snapshot-gated apply.",
            changes: plannedChanges,
            diagnostics: diagnostics,
            requiresExplicitApply: true
        )
        var reasons: [String] = []
        if diagnostics.contains(where: { $0.severity == .error }) {
            reasons.append("Resolve blocking diagnostics before source-tree apply.")
        }
        if sourceSnapshots.contains(where: { !$0.exists }) {
            reasons.append("All source and index files must exist before duplication apply.")
        }

        return MapDuplicationPlan(
            rootPath: rootPath,
            sourceMapID: sourceMapID,
            proposedMapID: proposedMapID,
            proposedMapName: proposedMapName,
            proposedLayoutID: proposedLayoutID,
            proposedLayoutName: proposedLayoutName,
            duplicateLayout: duplicateLayout,
            sourceEventCapacity: sourceEventCapacity,
            sourceSnapshots: sourceSnapshots,
            plannedFiles: plannedFiles,
            mutationPlan: mutationPlan,
            diagnostics: diagnostics,
            executionState: MapWorkflowExecutionState(canApply: canApply, canExport: false, reasons: reasons)
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

public enum MapVisualExportWriter {
    public static func export(
        plan: MapVisualExportPlan,
        renderedData: Data? = nil,
        fileManager: FileManager = .default
    ) throws -> MapVisualExportResult {
        guard let artifact = plan.artifacts.first else {
            return MapVisualExportResult(relativePath: "", absolutePath: "", byteCount: 0, sha1: "", diagnostics: [
                Diagnostic(severity: .error, code: "MAP_VISUAL_EXPORT_ARTIFACT_MISSING", message: "No visual export artifact path was planned.")
            ])
        }
        var diagnostics = plan.diagnostics.filter { $0.severity == .error }
        if !plan.executionState.canExport {
            diagnostics.append(Diagnostic(severity: .error, code: "MAP_VISUAL_EXPORT_NOT_APPLYABLE", message: "Visual export plan is not exportable.", span: SourceSpan(relativePath: artifact.relativePath, startLine: 1)))
        }
        if !artifact.relativePath.hasPrefix(".pokemonhackstudio/exports/maps/") || isUnsafeMapWorkflowPath(artifact.relativePath) {
            diagnostics.append(Diagnostic(severity: .error, code: "MAP_VISUAL_EXPORT_PATH_UNSAFE", message: "Visual export must stay under .pokemonhackstudio/exports/maps.", span: SourceSpan(relativePath: artifact.relativePath, startLine: 1)))
        }

        let data: Data
        switch plan.format {
        case .json:
            data = try JSONEncoder().encode(
                MapVisualExportMetadata(
                    documentID: plan.documentID,
                    mapID: plan.mapID,
                    mapName: plan.mapName,
                    artifactPath: artifact.relativePath
                )
            )
        case .png:
            guard let renderedData, !renderedData.isEmpty else {
                diagnostics.append(Diagnostic(severity: .error, code: "MAP_VISUAL_EXPORT_RENDERED_DATA_MISSING", message: "PNG visual export requires rendered image bytes.", span: SourceSpan(relativePath: artifact.relativePath, startLine: 1)))
                return MapVisualExportResult(relativePath: artifact.relativePath, absolutePath: artifact.absolutePath, byteCount: 0, sha1: "", diagnostics: diagnostics)
            }
            data = renderedData
        }

        guard diagnostics.allSatisfy({ $0.severity != .error }) else {
            return MapVisualExportResult(relativePath: artifact.relativePath, absolutePath: artifact.absolutePath, byteCount: 0, sha1: "", diagnostics: diagnostics)
        }

        let destination = URL(fileURLWithPath: artifact.absolutePath).standardizedFileURL
        try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: destination, options: .atomic)
        return MapVisualExportResult(
            relativePath: artifact.relativePath,
            absolutePath: destination.path,
            byteCount: data.count,
            sha1: pokemonHackSHA1Hex(data)
        )
    }
}

public enum MapWorkflowApplier {
    public static func applyDuplication(
        plan: MapDuplicationPlan,
        fileManager: FileManager = .default
    ) throws -> MapDuplicationApplyResult {
        let root = URL(fileURLWithPath: plan.rootPath).standardizedFileURL
        let backupRoot = root.appendingPathComponent(".pokemonhackstudio/backups/\(mapWorkflowBackupTimestamp())")
        let diagnostics = duplicationPreflightDiagnostics(plan: plan, root: root, fileManager: fileManager)
        guard diagnostics.allSatisfy({ $0.severity != .error }) else {
            return MapDuplicationApplyResult(
                backupRootPath: backupRoot.path,
                selectedMapID: nil,
                appliedFiles: [],
                diagnostics: diagnostics
            )
        }

        try fileManager.createDirectory(at: backupRoot, withIntermediateDirectories: true)
        var applied: [AppliedMapDuplicationFile] = []
        for file in plan.plannedFiles {
            switch file.action {
            case .copy:
                guard let destinationPath = file.destinationPath else { continue }
                let data = try Data(contentsOf: root.appendingPathComponent(file.sourcePath))
                try writeMapWorkflowData(data, to: root.appendingPathComponent(destinationPath), fileManager: fileManager)
                applied.append(AppliedMapDuplicationFile(path: destinationPath, action: file.action, byteCount: data.count))

            case .copyAndRewrite:
                guard let destinationPath = file.destinationPath else { continue }
                let sourceURL = root.appendingPathComponent(file.sourcePath)
                let text = try readMapWorkflowText(sourceURL)
                let rewritten = rewriteMapJSON(text, sourcePath: file.sourcePath, plan: plan)
                let data = Data(rewritten.utf8)
                try writeMapWorkflowData(data, to: root.appendingPathComponent(destinationPath), fileManager: fileManager)
                applied.append(AppliedMapDuplicationFile(path: destinationPath, action: file.action, byteCount: data.count))

            case .updateIndex:
                let sourceURL = root.appendingPathComponent(file.sourcePath)
                let originalData = try Data(contentsOf: sourceURL)
                let originalText: String
                if let utf8 = String(data: originalData, encoding: .utf8) {
                    originalText = utf8
                } else {
                    originalText = try readMapWorkflowText(sourceURL)
                }
                let updatedText: String
                if file.sourcePath == "data/maps/map_groups.json" {
                    updatedText = try updateMapGroupsJSON(originalText, plan: plan)
                } else {
                    updatedText = try updateLayoutsJSON(originalText, plan: plan)
                }
                let backup = backupRoot.appendingPathComponent(file.sourcePath)
                try fileManager.createDirectory(at: backup.deletingLastPathComponent(), withIntermediateDirectories: true)
                try fileManager.copyItem(at: sourceURL, to: backup)
                let data = Data(updatedText.utf8)
                try writeMapWorkflowData(data, to: sourceURL, fileManager: fileManager)
                applied.append(AppliedMapDuplicationFile(path: file.sourcePath, action: file.action, backupPath: backup.path, byteCount: data.count))
            }
        }

        return MapDuplicationApplyResult(
            backupRootPath: backupRoot.path,
            selectedMapID: plan.proposedMapID,
            appliedFiles: applied
        )
    }

    private static func duplicationPreflightDiagnostics(plan: MapDuplicationPlan, root: URL, fileManager: FileManager) -> [Diagnostic] {
        var diagnostics = plan.diagnostics.filter { $0.severity == .error }
        if !plan.executionState.canApply {
            diagnostics.append(Diagnostic(severity: .error, code: "MAP_DUPLICATION_APPLY_NOT_READY", message: "Map duplication plan is not applyable."))
        }
        diagnostics.append(contentsOf: MapWorkflowPlanner.externalChangeDiagnostics(rootPath: plan.rootPath, snapshots: plan.sourceSnapshots, fileManager: fileManager).filter { $0.severity == .error })
        for file in plan.plannedFiles {
            if isUnsafeMapWorkflowPath(file.sourcePath) {
                diagnostics.append(Diagnostic(severity: .error, code: "MAP_DUPLICATION_SOURCE_PATH_UNSAFE", message: "Map duplication source path is unsafe: \(file.sourcePath).", span: SourceSpan(relativePath: file.sourcePath, startLine: 1)))
            }
            if let destinationPath = file.destinationPath {
                if isUnsafeMapWorkflowPath(destinationPath) {
                    diagnostics.append(Diagnostic(severity: .error, code: "MAP_DUPLICATION_DESTINATION_PATH_UNSAFE", message: "Map duplication destination path is unsafe: \(destinationPath).", span: SourceSpan(relativePath: destinationPath, startLine: 1)))
                }
                if fileManager.fileExists(atPath: root.appendingPathComponent(destinationPath).path) {
                    diagnostics.append(Diagnostic(severity: .error, code: "MAP_DUPLICATION_DESTINATION_CONFLICT", message: "Map duplication destination already exists: \(destinationPath).", span: SourceSpan(relativePath: destinationPath, startLine: 1)))
                }
            }
        }
        return diagnostics
    }
}

private struct MapVisualExportMetadata: Codable, Equatable {
    let documentID: String
    let mapID: String
    let mapName: String
    let artifactPath: String
}

private func rewriteMapJSON(_ text: String, sourcePath: String, plan: MapDuplicationPlan) -> String {
    let sourceMapName = mapWorkflowMapName(fromSourcePath: sourcePath)
    var updated = text
        .replacingOccurrences(of: plan.sourceMapID, with: plan.proposedMapID)
        .replacingOccurrences(of: sourceMapName, with: plan.proposedMapName)
    if let proposedLayoutID = plan.proposedLayoutID {
        updated = replaceJSONStringValue(in: updated, key: "layout", value: proposedLayoutID)
        updated = replaceJSONStringValue(in: updated, key: "layout_id", value: proposedLayoutID)
    }
    return updated
}

private func updateMapGroupsJSON(_ text: String, plan: MapDuplicationPlan) throws -> String {
    if text.contains("\"\(plan.proposedMapName)\"") {
        return text
    }
    if text.trimmingCharacters(in: .whitespacesAndNewlines) == "[]" {
        return "[\"\(plan.proposedMapName)\"]"
    }
    let sourceName = plan.plannedFiles.first { $0.action == .copyAndRewrite }.map { mapWorkflowMapName(fromSourcePath: $0.sourcePath) } ?? plan.sourceMapID
    guard let sourceRange = text.range(of: "\"\(sourceName)\"") else {
        throw MapWorkflowApplyError.indexUpdateFailed("Could not find \(sourceName) in data/maps/map_groups.json.")
    }
    return text.replacingCharacters(in: sourceRange, with: "\"\(sourceName)\", \"\(plan.proposedMapName)\"")
}

private func updateLayoutsJSON(_ text: String, plan: MapDuplicationPlan) throws -> String {
    guard let layoutID = plan.proposedLayoutID else {
        throw MapWorkflowApplyError.indexUpdateFailed("No proposed layout id is available for layout index update.")
    }
    if text.contains("\"\(layoutID)\"") {
        return text
    }
    guard let insertionIndex = text.lastIndex(of: "]") else {
        throw MapWorkflowApplyError.indexUpdateFailed("Could not find layouts array in data/layouts/layouts.json.")
    }
    let blockdataPath = plan.plannedFiles.first { $0.action == .copy && ($0.destinationPath?.hasSuffix("map.bin") == true || $0.destinationPath?.contains("block") == true) }?.destinationPath
    let borderPath = plan.plannedFiles.first { $0.action == .copy && ($0.destinationPath?.hasSuffix("border.bin") == true || $0.destinationPath?.contains("border") == true) }?.destinationPath
    var object = """
    {
      "id": "\(layoutID)",
      "name": "\(plan.proposedLayoutName ?? layoutID)"
    """
    if let blockdataPath {
        object += ",\n  \"blockdata_filepath\": \"\(blockdataPath)\""
    }
    if let borderPath {
        object += ",\n  \"border_filepath\": \"\(borderPath)\""
    }
    object += "\n}"
    let prefix = text[..<insertionIndex]
    let needsComma = prefix.contains("{") && !prefix.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("[")
    let insertion = (needsComma ? ",\n" : "\n") + object + "\n"
    return String(prefix) + insertion + String(text[insertionIndex...])
}

private func replaceJSONStringValue(in text: String, key: String, value: String) -> String {
    let pattern = #""\#(key)"\s*:\s*"[^"]*""#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return regex.stringByReplacingMatches(in: text, range: range, withTemplate: #""\#(key)": "\#(value)""#)
}

private func writeMapWorkflowData(_ data: Data, to url: URL, fileManager: FileManager) throws {
    try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url, options: .atomic)
}

private func readMapWorkflowText(_ url: URL) throws -> String {
    if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
        return utf8
    }
    return try String(contentsOf: url, encoding: .isoLatin1)
}

private func mapWorkflowMapName(fromSourcePath sourcePath: String) -> String {
    URL(fileURLWithPath: sourcePath).deletingLastPathComponent().lastPathComponent
}

private func isUnsafeMapWorkflowPath(_ path: String) -> Bool {
    path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || (path as NSString).isAbsolutePath
        || path.split(separator: "/").contains("..")
}

private func mapWorkflowBackupTimestamp() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    return "\(formatter.string(from: Date()))-\(UUID().uuidString.prefix(8))"
}

private enum MapWorkflowApplyError: LocalizedError {
    case indexUpdateFailed(String)

    var errorDescription: String? {
        switch self {
        case .indexUpdateFailed(let message):
            return message
        }
    }
}
