# PHS-T134 Map Render Audit App Panel

## Scope

`PHS-T134` adds a read-only selected-project Map Render Audit panel to Build/Patch/Playtest. The panel calls the existing `MapRenderAuditBuilder.build(path:)` only after an explicit Re-check, caches the raw `MapRenderAuditReport`, projects app-only rows for target/map/texture/warning/failure/skipped counts, warning buckets, failures, skipped targets, and diagnostics, and supports a dedicated Copy JSON action.

The accepted plan named `PHS-T133`, but the live board already used `PHS-T133` for Patch Library CLI JSON. This closeout is recorded as `PHS-T134` to preserve row IDs.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'MapRenderAuditTests|PokemonHackCLITests/testMapRenderAudit'`  
  Passed with 15 selected tests and 0 failures.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T134-App -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -skip-testing:PokemonHackCLITests -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testMapRenderAuditLoadsIntoBuildWorkbenchAndCopiesJSONReadOnly test`  
  Passed the focused app-hosted store/view-state test.
- `make verify`  
  Passed; regenerated the ignored Xcode project and built the macOS app with existing local signing/AppIntents/script-phase warnings only.
- `./script/check_validation_docs.sh`  
  Passed.
- `git diff --check`  
  Passed.

## Read-Only Boundary

The app panel does not auto-run on project open, does not call `buildAll(workspaceRoot:)`, and does not create screenshots, generated images, source-tree writes, ROM writes, `.pokemonhackstudio` artifacts, preview exports, build/playtest executions, or renderer behavior changes. Copy Report JSON includes the loaded audit only after Re-check; dedicated Copy JSON emits only the raw audit.

The focused app-hosted test asserts that the selected-project load path is used, count rows and warning/failure/skipped rows are represented, both JSON copy paths include audit JSON, and no `.pokemonhackstudio`, screenshot, export, ROM, patch/playtest/build, or source-file artifacts are created by the audit flow.
