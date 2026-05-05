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
        }
    }
}
