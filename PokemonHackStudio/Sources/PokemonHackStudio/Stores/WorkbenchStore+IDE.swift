import AppKit
import Foundation

@MainActor
extension WorkbenchStore {
    var workbenchNavigatorNodes: [WorkbenchNavigatorNode] {
        [
            navigatorGroup(.workspace, children: [
                moduleNavigatorNode(.dashboard, badge: selectedProjectIdentity.isWritable ? "Edit" : "Read"),
            ] + indexedProjects.prefix(6).map(projectNavigatorNode)),
            navigatorGroup(.visual, children: [
                moduleNavigatorNode(.maps, badge: selectedMapCatalog.map { "\($0.mapCount)" }),
                moduleNavigatorNode(.graphics, badge: selectedGraphicsReport.map { "\($0.rows.count)" }),
            ]),
            navigatorGroup(.data, children: [
                moduleNavigatorNode(.pokemon, badge: selectedSpeciesCatalog.map { "\($0.speciesCount)" }),
                moduleNavigatorNode(.trainers, badge: selectedTrainerCatalog.map { "\($0.trainerCount)" }),
                moduleNavigatorNode(.moves, badge: selectedMoveCatalog.map { "\($0.moveCount)" }),
                moduleNavigatorNode(.items, badge: selectedItemCatalogView.map { "\($0.itemCount)" }),
                moduleNavigatorNode(.encounters),
                moduleNavigatorNode(.scripts, badge: selectedScriptOutline.map { "\($0.labels.count)" }),
                moduleNavigatorNode(.text),
            ]),
            navigatorGroup(.assets, children: [
                moduleNavigatorNode(.resources, badge: selectedAssetCatalog.map { "\($0.assetCount)" }),
                moduleNavigatorNode(.build, title: "Artifacts", subtitle: "Build outputs, patches, captures", badge: artifactNavigatorBadge),
            ]),
            navigatorGroup(.ship, children: [
                moduleNavigatorNode(.build, badge: selectedBuildReport.map { "\($0.buildTargets.count)" }),
            ]),
            navigatorGroup(.diagnostics, children: [
                moduleNavigatorNode(.issues, badge: "\(diagnosticSummary.totalCount)", status: diagnosticSummary.status),
            ]),
            navigatorGroup(.romInputs, children: romInputNavigatorNodes),
            navigatorGroup(.references, children: referenceNavigatorNodes),
        ]
    }

    var filteredWorkbenchCommands: [WorkbenchCommand] {
        let query = commandPaletteState.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return workbenchCommands }
        return workbenchCommands.filter { $0.searchBlob.contains(query) }
    }

    var workbenchCommands: [WorkbenchCommand] {
        let moduleCommands = WorkbenchModule.allCases.map { module in
            WorkbenchCommand(
                id: "module:\(module.id)",
                title: "Open \(module.title)",
                subtitle: module.subtitle,
                systemImage: module.systemImage,
                scope: module.group.rawValue,
                keyboardHint: keyboardHint(for: module),
                action: .selectModule(module),
                availability: .enabled
            )
        }

        let mutationState = mutationActionBarState
        let workflowActions = buildWorkflowActions(includePatchActions: selectedBuildWorkbenchTab == .patch)
        let buildAction = workflowActions.first { $0.id == "build-rom" }
        let cancelBuildAction = workflowActions.first { $0.id == "cancel-build" }
        let playtestAction = workflowActions.first { $0.id == "open-playtest" }
        let screenshotAction = workflowActions.first { $0.id == "capture-screenshot" }
        let savestateAction = workflowActions.first { $0.id == "capture-savestate" }

        var commands: [WorkbenchCommand] = moduleCommands + [
            WorkbenchCommand(
                id: "palette:open",
                title: "Show Command Palette",
                subtitle: "Search navigation, guarded actions, and copy commands.",
                systemImage: "command",
                scope: "IDE",
                keyboardHint: "Cmd-K",
                action: .openCommandPalette,
                availability: .enabled
            ),
            WorkbenchCommand(
                id: "refresh:current",
                title: "Refresh Current Editor",
                subtitle: "Reload the selected module context.",
                systemImage: "arrow.triangle.2.circlepath",
                scope: "Refresh",
                keyboardHint: nil,
                action: .refreshCurrent,
                availability: hasIndexedProjects ? .enabled : .disabled("Open or index a project before refreshing the current editor.")
            ),
            WorkbenchCommand(
                id: "refresh:projects",
                title: "Refresh Project Indexes",
                subtitle: "Re-scan editable roots, references, ROM inputs, and bundled fallbacks.",
                systemImage: "arrow.clockwise",
                scope: "Refresh",
                keyboardHint: "Shift-Cmd-R",
                action: .refreshProjects,
                availability: .enabled
            ),
            WorkbenchCommand(
                id: "refresh:resources",
                title: "Refresh Resource Library",
                subtitle: "Reload resources without changing write policy.",
                systemImage: "externaldrive.connected.to.line.below",
                scope: "Refresh",
                keyboardHint: "Shift-Cmd-L",
                action: .refreshResources,
                availability: .enabled
            ),
            WorkbenchCommand(
                id: "refresh:health",
                title: "Refresh Health Checks",
                subtitle: "Reload toolchain, generated output, and readiness facts.",
                systemImage: "stethoscope",
                scope: "Refresh",
                keyboardHint: "Shift-Cmd-H",
                action: .refreshHealth,
                availability: hasIndexedProjects ? .enabled : .disabled("Open or index a project before refreshing health checks.")
            ),
            WorkbenchCommand(
                id: "mutation:preview",
                title: "Preview \(mutationState.title)",
                subtitle: mutationState.previewHelp,
                systemImage: "doc.text.magnifyingglass",
                scope: "Mutation",
                keyboardHint: nil,
                action: .previewMutation,
                availability: .guarded(mutationState.canPreview, disabledReason: mutationState.canPreview ? nil : mutationState.previewHelp)
            ),
            WorkbenchCommand(
                id: "mutation:apply",
                title: "Apply \(mutationState.title)",
                subtitle: mutationState.applyHelp,
                systemImage: "checkmark.seal",
                scope: "Mutation",
                keyboardHint: nil,
                action: .applyMutation,
                availability: .guarded(mutationState.canApply, disabledReason: mutationState.canApply ? nil : mutationState.applyHelp)
            ),
            WorkbenchCommand(
                id: "mutation:discard",
                title: "Discard \(mutationState.title)",
                subtitle: mutationState.discardHelp,
                systemImage: "trash",
                scope: "Mutation",
                keyboardHint: nil,
                action: .discardMutation,
                availability: .guarded(mutationState.canDiscard, disabledReason: mutationState.canDiscard ? nil : mutationState.discardHelp)
            ),
            WorkbenchCommand(
                id: "build:run",
                title: buildAction?.title ?? "Build ROM",
                subtitle: buildAction?.disabledReason ?? "Run the selected declared make target.",
                systemImage: buildAction?.systemImage ?? "hammer",
                scope: "Ship",
                keyboardHint: nil,
                action: .runBuild,
                availability: .guarded(buildAction?.isEnabled == true, disabledReason: buildAction?.isEnabled == true ? nil : buildAction?.disabledReason)
            ),
            WorkbenchCommand(
                id: "build:cancel",
                title: cancelBuildAction?.title ?? "Cancel Build",
                subtitle: cancelBuildAction?.disabledReason ?? "Cancel the current build run.",
                systemImage: cancelBuildAction?.systemImage ?? "xmark.circle",
                scope: "Ship",
                keyboardHint: nil,
                action: .cancelBuild,
                availability: .guarded(cancelBuildAction?.isEnabled == true, disabledReason: cancelBuildAction?.isEnabled == true ? nil : cancelBuildAction?.disabledReason)
            ),
            WorkbenchCommand(
                id: "playtest:open",
                title: playtestAction?.title ?? "Open Playtest",
                subtitle: playtestAction?.disabledReason ?? "Launch the runnable external emulator handoff.",
                systemImage: playtestAction?.systemImage ?? "play.fill",
                scope: "Ship",
                keyboardHint: nil,
                action: .openPlaytest,
                availability: .guarded(playtestAction?.isEnabled == true, disabledReason: playtestAction?.isEnabled == true ? nil : playtestAction?.disabledReason)
            ),
            WorkbenchCommand(
                id: "playtest:capture-screenshot",
                title: screenshotAction?.title ?? "Capture Screenshot",
                subtitle: screenshotAction?.disabledReason ?? "Capture the current playtest screenshot artifact.",
                systemImage: screenshotAction?.systemImage ?? "camera",
                scope: "Ship",
                keyboardHint: nil,
                action: .captureScreenshot,
                availability: .guarded(screenshotAction?.isEnabled == true, disabledReason: screenshotAction?.isEnabled == true ? nil : screenshotAction?.disabledReason)
            ),
            WorkbenchCommand(
                id: "playtest:capture-savestate",
                title: savestateAction?.title ?? "Capture Savestate",
                subtitle: savestateAction?.disabledReason ?? "Capture the current playtest savestate artifact.",
                systemImage: savestateAction?.systemImage ?? "memories",
                scope: "Ship",
                keyboardHint: nil,
                action: .captureSavestate,
                availability: .guarded(savestateAction?.isEnabled == true, disabledReason: savestateAction?.isEnabled == true ? nil : savestateAction?.disabledReason)
            ),
            WorkbenchCommand(
                id: "copy:report-json",
                title: "Copy Build/Patch/Playtest JSON",
                subtitle: "Copy the current ship report without running validation.",
                systemImage: "doc.on.doc",
                scope: "Copy",
                keyboardHint: nil,
                action: .copyReportJSON,
                availability: selectedBuildReport == nil ? .disabled("Load a build report before copying JSON.") : .enabled
            ),
            WorkbenchCommand(
                id: "copy:ship-preview-digest-json",
                title: "Copy Ship Preview Digest JSON",
                subtitle: "Copy the current read-only ship digest snapshot.",
                systemImage: "doc.on.doc",
                scope: "Copy",
                keyboardHint: nil,
                action: .copyShipPreviewDigestJSON,
                availability: selectedShipPreviewDigest == nil ? .disabled("Open or index a project before copying Ship Preview Digest JSON.") : .enabled
            ),
            WorkbenchCommand(
                id: "copy:ship-preview-digest-markdown",
                title: "Copy Ship Preview Digest Markdown",
                subtitle: "Copy the current read-only ship digest handoff.",
                systemImage: "text.page",
                scope: "Copy",
                keyboardHint: nil,
                action: .copyShipPreviewDigestMarkdown,
                availability: selectedShipPreviewDigest == nil ? .disabled("Open or index a project before copying Ship Preview Digest Markdown.") : .enabled
            ),
            WorkbenchCommand(
                id: "copy:map-render-audit-json",
                title: "Copy Map Render Audit JSON",
                subtitle: "Copy the loaded read-only map render audit.",
                systemImage: "doc.on.doc",
                scope: "Copy",
                keyboardHint: nil,
                action: .copyMapRenderAuditJSON,
                availability: selectedMapRenderAuditReport == nil ? .disabled("Run Map Render Audit Re-check before copying JSON.") : .enabled
            ),
            WorkbenchCommand(
                id: "copy:nds-semantic-coverage-json",
                title: "Copy NDS Semantic Coverage JSON",
                subtitle: "Copy the loaded redacted NDS semantic coverage report.",
                systemImage: "doc.on.doc",
                scope: "Copy",
                keyboardHint: nil,
                action: .copyNDSSemanticCoverageJSON,
                availability: canCopyNDSSemanticCoverageJSON ? .enabled : .disabled("Refresh NDS semantic coverage before copying JSON.")
            ),
            WorkbenchCommand(
                id: "copy:patch-distribution-readiness-json",
                title: "Copy Patch Distribution Readiness JSON",
                subtitle: "Copy the loaded copy-only patch distribution packet.",
                systemImage: "doc.on.doc",
                scope: "Copy",
                keyboardHint: nil,
                action: .copyPatchDistributionReadinessJSON,
                availability: canCopyPatchDistributionReadinessJSON ? .enabled : .disabled("Refresh patch distribution readiness before copying JSON.")
            ),
            WorkbenchCommand(
                id: "copy:patch-apply-export-audit-json",
                title: "Copy Patch Apply/Export Audit JSON",
                subtitle: "Copy the loaded read-only patch apply/export audit.",
                systemImage: "doc.on.doc",
                scope: "Copy",
                keyboardHint: nil,
                action: .copyPatchApplyExportAuditJSON,
                availability: canCopyPatchApplyExportAuditJSON ? .enabled : .disabled("Refresh Patch Apply/Export Audit before copying JSON.")
            ),
            WorkbenchCommand(
                id: "copy:binary-rom-mutation-apply-audit-json",
                title: "Copy Binary ROM Apply Audit JSON",
                subtitle: "Copy the loaded read-only binary apply audit.",
                systemImage: "doc.on.doc",
                scope: "Copy",
                keyboardHint: nil,
                action: .copyBinaryROMMutationApplyAuditJSON,
                availability: canCopyBinaryROMMutationApplyAuditJSON ? .enabled : .disabled("Load a binary mutation review before copying audit JSON.")
            ),
            WorkbenchCommand(
                id: "copy:rom-mutation-library-json",
                title: "Copy ROM Mutation Library JSON",
                subtitle: "Copy the loaded read-only ROM mutation artifact library.",
                systemImage: "doc.on.doc",
                scope: "Copy",
                keyboardHint: nil,
                action: .copyROMMutationArtifactLibraryJSON,
                availability: canCopyROMMutationArtifactLibraryJSON ? .enabled : .disabled("Re-check ROM Mutation Library before copying JSON.")
            ),
            WorkbenchCommand(
                id: "copy:gen-iv-map-review-json",
                title: "Copy Gen IV Map Review JSON",
                subtitle: "Copy the selected Gen IV map review packet.",
                systemImage: "doc.on.doc",
                scope: "Copy",
                keyboardHint: nil,
                action: .copySelectedNDSMapReviewPacketJSON,
                availability: selectedNDSMapReviewPacketCopyDisabledReason.map { .disabled($0) } ?? .enabled
            ),
            WorkbenchCommand(
                id: "copy:resource-readiness-packet-json",
                title: "Copy Resource Readiness Packet JSON",
                subtitle: "Copy the selected Resources packet or NDS readiness row.",
                systemImage: "doc.on.doc",
                scope: "Copy",
                keyboardHint: nil,
                action: .copySelectedResourceReadinessPacketJSON,
                availability: selectedResourceReadinessPacketCopyDisabledReason.map { .disabled($0) } ?? .enabled
            ),
        ]

        commands.append(contentsOf: validationTierCommandRows.map { row in
            WorkbenchCommand(
                id: "validation:\(row.id)",
                title: "Copy \(row.title)",
                subtitle: "\(row.command) · \(row.strictnessTitle)",
                systemImage: "terminal",
                scope: "Validation",
                keyboardHint: nil,
                action: .copyValidationCommand(row.command),
                availability: row.canCopyCommand
                    ? .enabled
                    : .disabled(row.disabledReason, guarded: true)
            )
        })

        return commands
    }

    var currentIDEActivityEvents: [WorkbenchActivityEvent] {
        var events: [WorkbenchActivityEvent] = []

        if let report = selectedBuildReport {
            let generatedPresent = report.generatedArtifacts.filter(\.exists).count
            events.append(
                WorkbenchActivityEvent(
                    id: "build-report:\(report.id)",
                    category: .build,
                    title: "Build report loaded",
                    detail: "\(report.buildTargets.count) target(s); \(generatedPresent)/\(report.generatedArtifacts.count) generated output(s) present",
                    status: report.status,
                    source: report.rows.first?.source
                )
            )
        }

        if let result = selectedBuildRunResult {
            events.append(
                WorkbenchActivityEvent(
                    id: "build-result:\(result.id)",
                    category: .build,
                    title: result.title,
                    detail: result.outputDetail,
                    status: result.status,
                    source: nil
                )
            )
        }

        events.append(contentsOf: selectedBuildRunLogLines.suffix(8).map { line in
            WorkbenchActivityEvent(
                id: "build-log:\(line.id)",
                category: .build,
                title: "\(line.stream) log",
                detail: line.message,
                status: .valid,
                source: nil
            )
        })

        if let launch = selectedPlaytestLaunchResult {
            events.append(
                WorkbenchActivityEvent(
                    id: "playtest-launch:\(launch.id)",
                    category: .playtest,
                    title: launch.statusLabel,
                    detail: launch.detail,
                    status: launch.status,
                    source: launch.source
                )
            )
        }

        if let capture = selectedPlaytestCaptureResult {
            events.append(
                WorkbenchActivityEvent(
                    id: "playtest-capture:\(capture.id)",
                    category: .playtest,
                    title: capture.title,
                    detail: capture.detail,
                    status: capture.status,
                    source: capture.source
                )
            )
        }

        if let catalog = selectedAssetCatalog {
            events.append(
                WorkbenchActivityEvent(
                    id: "resource-catalog:\(catalog.id)",
                    category: .resources,
                    title: "Resources catalog loaded",
                    detail: "\(catalog.assetCount) asset(s); \(catalog.diagnostics.count) diagnostic(s)",
                    status: status(for: catalog.rows.map(\.status)) ?? .valid,
                    source: catalog.rows.first?.source
                )
            )
        }

        if selectedResourceReadinessPacketCopyDisabledReason == nil,
           let asset = selectedResourceAsset {
            events.append(
                WorkbenchActivityEvent(
                    id: "resource-readiness:\(asset.id)",
                    category: .resources,
                    title: "Resource readiness packet",
                    detail: "\(asset.path) · \(asset.availabilitySummary)",
                    status: asset.status,
                    source: asset.source
                )
            )
        }

        if let preview = selectedPatchCreationPreviewReport {
            events.append(
                WorkbenchActivityEvent(
                    id: "patch-creation-preview:\(preview.id)",
                    category: .patch,
                    title: "Patch creation preview \(preview.isReady ? "ready" : "blocked")",
                    detail: preview.absolutePlannedPatchPath,
                    status: preview.status,
                    source: preview.rows.first?.source
                )
            )
        }

        if let result = selectedPatchCreationResultReport {
            events.append(
                WorkbenchActivityEvent(
                    id: "patch-creation-result:\(result.id)",
                    category: .patch,
                    title: "Patch creation \(result.statusLabel)",
                    detail: result.patchPath ?? result.manifestPath ?? "No patch artifact path",
                    status: result.status,
                    source: result.rows.first?.source
                )
            )
        }

        if let library = selectedPatchArtifactLibrary {
            events.append(
                WorkbenchActivityEvent(
                    id: "patch-library:\(library.id)",
                    category: .patch,
                    title: library.title,
                    detail: "\(library.items.count) artifact(s) in \(library.artifactRoot)",
                    status: library.status,
                    source: library.rows.first?.source
                )
            )
        }

        if let report = selectedPatchDistributionReadinessReport {
            events.append(
                WorkbenchActivityEvent(
                    id: "patch-distribution:\(report.id)",
                    category: .patch,
                    title: report.title,
                    detail: report.detail,
                    status: report.status,
                    source: report.rows.first?.source
                )
            )
        }

        if let report = selectedPatchApplyExportAuditReport {
            events.append(
                WorkbenchActivityEvent(
                    id: "patch-apply-export-audit:\(report.id)",
                    category: .patch,
                    title: "Patch apply/export audit \(report.statusLabel)",
                    detail: report.plannedOutputPath,
                    status: report.status,
                    source: report.rows.first?.source
                )
            )
        }

        if let report = selectedMapRenderAuditReport {
            events.append(
                WorkbenchActivityEvent(
                    id: "map-render-audit:\(report.id)",
                    category: .diagnostics,
                    title: "Map render audit \(report.statusLabel)",
                    detail: "\(report.auditedMapCount)/\(report.mapCount) maps; \(report.warningCount) warning(s); \(report.failureCount) failure(s)",
                    status: report.status,
                    source: report.rows.first?.source
                )
            )
        }

        if let report = selectedNDSSemanticCoverageReport {
            events.append(
                WorkbenchActivityEvent(
                    id: "nds-semantic-coverage:\(report.id)",
                    category: .diagnostics,
                    title: "NDS semantic coverage \(report.statusLabel)",
                    detail: "\(report.eligibleFields) field(s); \(report.blockedRows) write-blocked; \(report.skippedRows) skipped",
                    status: report.status,
                    source: report.rows.first?.source
                )
            )
        }

        if let digest = selectedShipPreviewDigest {
            events.append(
                WorkbenchActivityEvent(
                    id: "ship-preview-digest:\(digest.id)",
                    category: .diagnostics,
                    title: digest.title,
                    detail: digest.subtitle,
                    status: digest.status,
                    source: nil
                )
            )
        }

        if let binaryDryRun = selectedBinaryROMMutationDryRunReport {
            events.append(
                WorkbenchActivityEvent(
                    id: "binary-dry-run:\(binaryDryRun.id)",
                    category: .mutation,
                    title: binaryDryRun.title,
                    detail: binaryDryRun.inputPath,
                    status: binaryDryRun.status,
                    source: binaryDryRun.rows.first?.source
                )
            )
        }

        if let binaryAudit = selectedBinaryROMMutationApplyAuditReport {
            events.append(
                WorkbenchActivityEvent(
                    id: "binary-apply-audit:\(binaryAudit.id)",
                    category: .mutation,
                    title: "Binary apply audit \(binaryAudit.statusLabel)",
                    detail: binaryAudit.manifestPath ?? binaryAudit.inputPath,
                    status: binaryAudit.status,
                    source: binaryAudit.rows.first?.source
                )
            )
        }

        if let binaryResult = selectedBinaryROMMutationApplyResultReport {
            events.append(
                WorkbenchActivityEvent(
                    id: "binary-apply-result:\(binaryResult.id)",
                    category: .mutation,
                    title: "Binary apply \(binaryResult.statusLabel)",
                    detail: binaryResult.manifestPath ?? binaryResult.inputPath,
                    status: binaryResult.status,
                    source: binaryResult.rows.first?.source
                )
            )
        }

        if currentModuleEditorSession.isDirty || currentModuleEditorSession.canApply {
            events.append(
                WorkbenchActivityEvent(
                    id: "mutation-session:\(currentModuleEditorSession.id)",
                    category: .mutation,
                    title: currentModuleEditorSession.stage.rawValue,
                    detail: currentModuleEditorSession.nextActionTitle,
                    status: currentModuleEditorSession.stage.validationState,
                    source: nil
                )
            )
        }

        if diagnosticSummary.totalCount > 0 {
            events.append(
                WorkbenchActivityEvent(
                    id: "diagnostics:\(diagnosticSummary.totalCount)",
                    category: .diagnostics,
                    title: diagnosticSummary.compactLabel,
                    detail: diagnosticSummary.detail,
                    status: diagnosticSummary.status,
                    source: selectedDiagnosticRow?.source
                )
            )
        }

        if let filter = activityCategoryFilter {
            return events.filter { $0.category == filter }
        }
        return events
    }

    var visibleIDEActivityEvents: [WorkbenchActivityEvent] {
        switch bottomPanelMode {
        case .activity:
            currentIDEActivityEvents
        case .buildLogs:
            currentIDEActivityEvents.filter { $0.category == .build }
        case .playtest:
            currentIDEActivityEvents.filter { $0.category == .playtest }
        case .artifacts:
            currentIDEActivityEvents.filter { $0.category == .patch || $0.category == .resources }
        }
    }

    var activeEditorTab: WorkbenchEditorTab? {
        editorTabs.first { $0.id == activeEditorTabID }
    }

    func activateEditorTab(_ tab: WorkbenchEditorTab) {
        openEditorTab(for: tab.module, targetID: tab.targetID, activate: true)
        selectWorkbenchModule(tab.module, search: .restoreModule)
    }

    func closeEditorTab(_ tab: WorkbenchEditorTab) {
        guard editorTabs.count > 1 else { return }
        guard let index = editorTabs.firstIndex(where: { $0.id == tab.id }) else { return }
        editorTabs.remove(at: index)
        if activeEditorTabID == tab.id {
            let replacement = editorTabs[min(index, editorTabs.count - 1)]
            activeEditorTabID = replacement.id
            selectWorkbenchModule(replacement.module, search: .restoreModule)
        }
    }

    func selectNavigatorNode(_ node: WorkbenchNavigatorNode) {
        navigatorSelectionID = node.id
        if let target = node.target {
            focusWorkbenchTarget(target)
            openEditorTab(for: target.module, targetID: target.rawIdentifier, activate: true)
        } else if let module = node.module {
            selectWorkbenchModule(module)
        }
    }

    func toggleNavigatorExpansion(_ nodeID: WorkbenchNavigatorNode.ID) {
        if expandedNavigatorNodeIDs.contains(nodeID) {
            expandedNavigatorNodeIDs.remove(nodeID)
        } else {
            expandedNavigatorNodeIDs.insert(nodeID)
        }
    }

    func showCommandPalette() {
        commandPaletteState.isPresented = true
        commandPaletteState.searchText = ""
        commandPaletteState.selectedCommandID = filteredWorkbenchCommands.first?.id
    }

    func hideCommandPalette() {
        commandPaletteState.isPresented = false
        commandPaletteState.searchText = ""
        commandPaletteState.selectedCommandID = nil
    }

    func executeCommand(_ command: WorkbenchCommand) {
        guard command.availability.isEnabled else { return }
        recordRecentCommand(command.id)
        switch command.action {
        case let .selectModule(module):
            selectWorkbenchModule(module)
        case .openCommandPalette:
            showCommandPalette()
        case .refreshCurrent:
            refreshSelectedModuleContext()
        case .refreshProjects:
            refreshProjectIndexes()
        case .refreshResources:
            refreshResourceLibrary()
        case .refreshHealth:
            refreshHealthChecks()
        case .previewMutation:
            previewToolbarMutationTarget()
        case .applyMutation:
            applyToolbarMutationTarget()
        case .discardMutation:
            discardToolbarMutationTarget()
        case .runBuild:
            runSelectedDecompBuild()
        case .cancelBuild:
            cancelSelectedDecompBuild()
        case .openPlaytest:
            launchSelectedPlaytest()
        case .captureScreenshot:
            captureSelectedPlaytest(kind: .screenshot)
        case .captureSavestate:
            captureSelectedPlaytest(kind: .saveState)
        case let .copyValidationCommand(commandText):
            if let row = validationTierCommandRows.first(where: { $0.command == commandText }) {
                copyValidationTierCommandToPasteboard(row)
            } else {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(commandText, forType: .string)
            }
        case .copyReportJSON:
            copyBuildPatchPlaytestReportJSONToPasteboard()
        case .copyShipPreviewDigestJSON:
            copyShipPreviewDigestJSONToPasteboard()
        case .copyShipPreviewDigestMarkdown:
            copyShipPreviewDigestMarkdownToPasteboard()
        case .copyMapRenderAuditJSON:
            copyMapRenderAuditJSONToPasteboard()
        case .copyNDSSemanticCoverageJSON:
            copyNDSSemanticCoverageJSONToPasteboard()
        case .copyPatchDistributionReadinessJSON:
            copyPatchDistributionReadinessJSONToPasteboard()
        case .copyPatchApplyExportAuditJSON:
            copyPatchApplyExportAuditJSONToPasteboard()
        case .copyBinaryROMMutationApplyAuditJSON:
            copyBinaryROMMutationApplyAuditJSONToPasteboard()
        case .copyROMMutationArtifactLibraryJSON:
            copyROMMutationArtifactLibraryJSONToPasteboard()
        case .copySelectedNDSMapReviewPacketJSON:
            copySelectedNDSMapReviewPacketJSONToPasteboard()
        case .copySelectedResourceReadinessPacketJSON:
            copySelectedResourceReadinessPacketJSONToPasteboard()
        }
        if command.action != .openCommandPalette {
            hideCommandPalette()
        }
    }

    static func defaultIDEInspectorMode(for module: WorkbenchModule) -> WorkbenchInspectorMode {
        switch module {
        case .issues:
            .diagnostics
        case .build, .resources, .graphics:
            .artifacts
        case .dashboard:
            .source
        case .maps, .pokemon, .trainers, .moves, .items, .encounters, .scripts, .text:
            .selection
        }
    }

    private var artifactNavigatorBadge: String? {
        let count = (selectedPatchArtifactLibrary?.items.count ?? 0)
            + (selectedPlaytestCaptureResult?.artifacts.count ?? 0)
            + (selectedBuildRunResult?.artifacts.count ?? 0)
        return count == 0 ? nil : "\(count)"
    }

    private var romInputNavigatorNodes: [WorkbenchNavigatorNode] {
        let entries = (resourceLibrary?.entries ?? []).filter { entry in
            let haystack = [entry.platform, entry.family, entry.profile, entry.role, entry.title, entry.path]
                .joined(separator: " ")
                .lowercased()
            return haystack.contains("rom") || haystack.contains(".gba") || haystack.contains(".nds")
        }
        guard !entries.isEmpty else {
            return [
                WorkbenchNavigatorNode(
                    id: "rom-inputs:empty",
                    title: "No ROM inputs",
                    subtitle: "Open local ROMs through Resources.",
                    systemImage: "opticaldiscdrive",
                    status: .warning,
                    module: .resources
                ),
            ]
        }
        return entries.prefix(8).map { entry in
            WorkbenchNavigatorNode(
                id: "rom-input:\(entry.id)",
                title: entry.title,
                subtitle: entry.path,
                systemImage: "opticaldiscdrive",
                status: entry.status,
                module: .resources,
                target: .resourceEntry(entry.id)
            )
        }
    }

    private var referenceNavigatorNodes: [WorkbenchNavigatorNode] {
        let references = indexedProjects.filter { $0.originLabel == "Reference" || $0.writePolicy.localizedCaseInsensitiveContains("read") }
        guard !references.isEmpty else {
            return [
                WorkbenchNavigatorNode(
                    id: "references:empty",
                    title: "Reference Bench",
                    subtitle: "Reference roots stay read-only and behavioral.",
                    systemImage: "books.vertical",
                    status: .valid,
                    module: .resources
                ),
            ]
        }
        return references.prefix(8).map(projectNavigatorNode)
    }

    private func navigatorGroup(
        _ group: WorkbenchNavigatorGroup,
        children: [WorkbenchNavigatorNode]
    ) -> WorkbenchNavigatorNode {
        WorkbenchNavigatorNode(
            id: group.id,
            title: group.rawValue,
            subtitle: "\(children.count) item\(children.count == 1 ? "" : "s")",
            systemImage: group.systemImage,
            status: status(for: children.compactMap(\.status)),
            badge: "\(children.count)",
            children: children
        )
    }

    private func moduleNavigatorNode(
        _ module: WorkbenchModule,
        title: String? = nil,
        subtitle: String? = nil,
        badge: String? = nil,
        status: ValidationState? = nil
    ) -> WorkbenchNavigatorNode {
        WorkbenchNavigatorNode(
            id: module.id,
            title: title ?? module.title,
            subtitle: subtitle ?? module.subtitle,
            systemImage: module.systemImage,
            status: status ?? moduleStatus(for: module),
            badge: badge,
            module: module
        )
    }

    private func projectNavigatorNode(_ project: IndexedProjectSummary) -> WorkbenchNavigatorNode {
        WorkbenchNavigatorNode(
            id: "project:\(project.id)",
            title: project.title,
            subtitle: "\(project.originLabel) · \(project.profile)",
            systemImage: project.identity.systemImage,
            status: project.status,
            badge: project.originLabel,
            module: .dashboard
        )
    }

    private func recordRecentCommand(_ commandID: WorkbenchCommand.ID) {
        recentCommandIDs.removeAll { $0 == commandID }
        recentCommandIDs.insert(commandID, at: 0)
        recentCommandIDs = Array(recentCommandIDs.prefix(10))
    }

    private func keyboardHint(for module: WorkbenchModule) -> String? {
        switch module {
        case .dashboard: "Cmd-1"
        case .maps: "Cmd-2"
        case .pokemon, .trainers, .moves, .items, .encounters: "Cmd-3"
        case .scripts, .text: "Cmd-4"
        case .graphics, .resources: "Cmd-5"
        case .build: "Cmd-6"
        case .issues: "Cmd-7"
        }
    }

    private func status(for states: [ValidationState]) -> ValidationState? {
        guard !states.isEmpty else { return nil }
        if states.contains(.error) { return .error }
        if states.contains(.warning) { return .warning }
        return .valid
    }
}
