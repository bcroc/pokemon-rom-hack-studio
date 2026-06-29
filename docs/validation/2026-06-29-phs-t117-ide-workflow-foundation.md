# PHS-T117 IDE Workflow Foundation

## Scope

- Introduce explicit project identity/write-policy labels for editable projects, bundled fallback data, reference roots, ROM inputs, and demo fixtures.
- Promote guided dashboard cards into persistent workflow runs with active target, mutation gate, diagnostics, artifacts, and next-action state.
- Add source-location actions and diagnostic routing hooks.
- Add a reusable `ModuleEditorSession` summary around selection, draft, preview, apply, discard, and diagnostics state.
- Add validation-tier model/Makefile commands plus this validation index.

## Proof

- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T117 -destination 'platform=macOS,arch=arm64' -only-testing:PokemonHackStudioTests/WorkbenchIDEFoundationTests test` (passed; 5 app-hosted IDE foundation tests)
- `git diff --check` (passed)
- `make validate-synthetic` (passed; includes `scripts-check` plus 353 SwiftPM tests)
- `make verify` (passed; regenerated the Xcode project, built/signed the macOS app and CLI, and the asset bundle phase reported `Reused 0 PokemonHackStudio asset project(s)`)

## Changed Paths

- `Makefile`
- `PokemonHackStudio/Sources/PokemonHackStudio/Models/GuidedWorkflowModels.swift`
- `PokemonHackStudio/Sources/PokemonHackStudio/Models/WorkbenchModels.swift`
- `PokemonHackStudio/Sources/PokemonHackStudio/Stores/WorkbenchStore+GuidedWorkflow.swift`
- `PokemonHackStudio/Sources/PokemonHackStudio/Stores/WorkbenchStore.swift`
- `PokemonHackStudio/Sources/PokemonHackStudio/Views/Components/IndexedProjectRows.swift`
- `PokemonHackStudio/Sources/PokemonHackStudio/Views/Components/SourceLocationView.swift`
- `PokemonHackStudio/Sources/PokemonHackStudio/Views/ContentView.swift`
- `PokemonHackStudio/Sources/PokemonHackStudio/Views/DashboardView.swift`
- `PokemonHackStudio/Sources/PokemonHackStudio/Views/Editors/IssuesView.swift`
- `PokemonHackStudio/Sources/PokemonHackStudio/Views/ModuleDetailView.swift`
- `PokemonHackStudio/Sources/PokemonHackStudio/Views/SidebarView.swift`
- `PokemonHackStudio/Tests/PokemonHackStudioTests/WorkbenchIDEFoundationTests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/README.md`
- `docs/validation/2026-06-29-phs-t117-ide-workflow-foundation.md`

## Posture

No source-write, binary ROM write, NDS extraction/rebuild, patch export, build execution, playtest launch, reference mutation, or bundled-fallback write gate was widened.
