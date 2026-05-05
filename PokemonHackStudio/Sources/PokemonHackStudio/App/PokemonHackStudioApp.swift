import SwiftUI

@main
struct PokemonHackStudioApp: App {
    @StateObject private var store = WorkbenchStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandMenu("Workbench") {
                Button("Build Target") {}
                    .keyboardShortcut("b", modifiers: [.command, .shift])
                Button("Run Target") {}
                    .keyboardShortcut("r", modifiers: [.command])
                Button("Validate Sources") {}
                    .keyboardShortcut("v", modifiers: [.command, .shift])
            }

            CommandMenu("Map Editor") {
                Button("Select Tool") {
                    store.mapEditorSession.selectedMapTool = .select
                }
                .keyboardShortcut("v", modifiers: [])

                Button("Pan Tool") {
                    store.mapEditorSession.selectedMapTool = .hand
                }
                .keyboardShortcut("h", modifiers: [])

                Button("Eyedropper Tool") {
                    store.mapEditorSession.selectedMapTool = .eyedropper
                }
                .keyboardShortcut("i", modifiers: [])

                Button("Pencil Tool") {
                    store.mapEditorSession.selectedMapTool = .pencil
                }
                .keyboardShortcut("b", modifiers: [])

                Button("Rectangle Fill Tool") {
                    store.mapEditorSession.selectedMapTool = .rectangleFill
                }
                .keyboardShortcut("f", modifiers: [])

                Divider()

                Button("Undo Map Edit") {
                    store.mapEditorSession.undoLastMapEdit()
                }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(!store.mapEditorSession.hasUndo)

                Button("Redo Map Edit") {
                    store.mapEditorSession.redoMapEdit()
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(!store.mapEditorSession.hasRedo)

                Divider()

                Button("Preview Map Changes") {
                    _ = store.mapEditorSession.previewSelectedMapMutationPlan()
                }
                .keyboardShortcut("p", modifiers: [.command, .option])
                .disabled(!store.mapEditorSession.canPreviewSelectedMapMutationPlan)

                Button("Discard Map Changes") {
                    store.discardMapEdits()
                }
                .keyboardShortcut(.delete, modifiers: [.command, .option])
                .disabled(!store.mapEditorSession.canDiscardMapEdits)
            }
        }
    }
}
