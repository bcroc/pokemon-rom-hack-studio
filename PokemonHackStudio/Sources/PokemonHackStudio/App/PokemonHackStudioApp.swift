import AppKit
import SwiftUI

@main
struct PokemonHackStudioApp: App {
    @StateObject private var store = WorkbenchStore()
    @FocusedBinding(\.editorShellShowsSourceInspector) private var showsSourceInspector

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandMenu("Project") {
                Button("Open Project...") {
                    openProjectPanel()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Refresh Project Indexes") {
                    store.refreshProjectIndexes()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])

                Divider()

                Button("Build Target") {
                    selectModule(.build)
                }
                    .keyboardShortcut("b", modifiers: [.command, .shift])

                Button("Run Target") {
                    selectModule(.build)
                }
                .keyboardShortcut("r", modifiers: [.command, .option])

                Button("Validate Sources") {
                    selectModule(.issues)
                }
                    .keyboardShortcut("v", modifiers: [.command, .shift])
            }

            CommandMenu("View") {
                Button((showsSourceInspector ?? true) ? "Hide Source Inspector" : "Show Source Inspector") {
                    showsSourceInspector?.toggle()
                }
                .keyboardShortcut("i", modifiers: [.command, .option])
                .disabled(showsSourceInspector == nil)
            }

            CommandMenu("Navigate") {
                Button("Previous Module") {
                    selectAdjacentModule(offset: -1)
                }
                .keyboardShortcut(.leftArrow, modifiers: [.command, .option])

                Button("Next Module") {
                    selectAdjacentModule(offset: 1)
                }
                .keyboardShortcut(.rightArrow, modifiers: [.command, .option])

                Divider()

                Button("Project") {
                    selectModule(.dashboard)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Maps") {
                    selectModule(.maps)
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Data") {
                    selectModule(.pokemon)
                }
                .keyboardShortcut("3", modifiers: .command)

                Button("Scripts/Text") {
                    selectModule(.scripts)
                }
                .keyboardShortcut("4", modifiers: .command)

                Button("Graphics") {
                    selectModule(.graphics)
                }
                .keyboardShortcut("5", modifiers: .command)

                Button("Build/Patch/Playtest") {
                    selectModule(.build)
                }
                .keyboardShortcut("6", modifiers: .command)

                Button("Diagnostics") {
                    selectModule(.issues)
                }
                .keyboardShortcut("7", modifiers: .command)
            }

            CommandMenu("Map") {
                Button("Select Tool") {
                    dispatchMapCommand(.selectTool(.select))
                }
                .disabled(!canUseMapCommands)

                Button("Pan Tool") {
                    dispatchMapCommand(.selectTool(.hand))
                }
                .disabled(!canUseMapCommands)

                Button("Eyedropper Tool") {
                    dispatchMapCommand(.selectTool(.eyedropper))
                }
                .disabled(!canUseMapCommands)

                Button("Pencil Tool") {
                    dispatchMapCommand(.selectTool(.pencil))
                }
                .disabled(!canUseMapCommands)

                Button("Rectangle Fill Tool") {
                    dispatchMapCommand(.selectTool(.rectangleFill))
                }
                .disabled(!canUseMapCommands)

                Divider()

                Button("Duplicate Selected Event") {
                    dispatchMapCommand(.duplicateSelectedMapEvent)
                }
                .disabled(!canUseMapCommands || store.mapEditorSession.selectedMapEventID == nil)

                Button("Delete Selected Event") {
                    dispatchMapCommand(.deleteSelectedMapEvent)
                }
                .disabled(!canUseMapCommands || store.mapEditorSession.selectedMapEventID == nil)

                Divider()

                Button("Undo Map Edit") {
                    dispatchMapCommand(.undo)
                }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(!canUseMapCommands || !store.mapEditorSession.hasUndo)

                Button("Redo Map Edit") {
                    dispatchMapCommand(.redo)
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(!canUseMapCommands || !store.mapEditorSession.hasRedo)

                Divider()

                Button("Reload Selected Map") {
                    store.loadSelectedMapVisualDocument()
                }
                .disabled(!canUseMapCommands || store.selectedMapID.isEmpty)

                Button("Preview Map Changes") {
                    store.previewSelectedMapMutationPlan()
                }
                .keyboardShortcut("p", modifiers: [.command, .option])
                .disabled(!canUseMapCommands || !store.mapEditorSession.canPreviewSelectedMapMutationPlan)

                Button("Discard Map Changes") {
                    store.discardMapEdits()
                }
                .keyboardShortcut(.delete, modifiers: [.command, .option])
                .disabled(!canUseMapCommands || !store.mapEditorSession.canDiscardMapEdits)
            }
        }
    }
}

private extension PokemonHackStudioApp {
    var orderedModules: [WorkbenchModule] {
        WorkbenchModuleGroup.allCases.flatMap(\.modules)
    }

    var canUseMapCommands: Bool {
        store.selection == .maps
    }

    func selectModule(_ module: WorkbenchModule) {
        store.selection = module
        if module == .maps {
            store.loadSelectedMapCatalogIfNeeded()
            store.loadSelectedMapVisualDocumentIfNeeded()
        }
    }

    func selectAdjacentModule(offset: Int) {
        guard let index = orderedModules.firstIndex(of: store.selection), !orderedModules.isEmpty else {
            return
        }

        let nextIndex = (index + offset + orderedModules.count) % orderedModules.count
        selectModule(orderedModules[nextIndex])
    }

    func dispatchMapCommand(_ command: MapEditorCommand) {
        guard canUseMapCommands else { return }
        _ = store.mapEditorSession.dispatch(command)
    }

    func openProjectPanel() {
        let panel = NSOpenPanel()
        panel.title = "Open Pokemon Project"
        panel.prompt = "Open"
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.resolvesAliases = true

        guard panel.runModal() == .OK, let url = panel.url else { return }
        store.openProject(at: url)
    }
}
