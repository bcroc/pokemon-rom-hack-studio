# PHS-T120 Validation Tier Command Surface

## Scope

- Row ID note: the requested plan named `PHS-T119`, but the live board already uses `PHS-T119` for Patch Creation Preview and NDS Resource Workflow Readiness entries, so this closeout is recorded as `PHS-T120`.
- Add core-backed `ValidationTierCommandRow` state for all five `ValidationTier` commands, including title, exact command, copy value, disabled `Run manually` state, copyability, and repository-root guidance.
- Add `WorkbenchStore.validationTierCommandRows` plus `copyValidationTierCommandToPasteboard(_:)`, copying only the selected command value.
- Add a compact `Validation Commands` section to Build/Patch/Playtest for indexed projects and fixture/no-project state, with selectable monospace commands, icon-only copy, and disabled manual-run affordances.
- Add app-hosted model/store tests for command order, copy-only/manual state, disabled wording, and exact pasteboard copy.

## Proof

- `make test` (initial run hit concurrent dirty NDS test failures outside this row; rerun passed with 387 SwiftPM tests, 0 failures)
- `make validate-synthetic` (passed; `scripts-check`, build-tool availability check, and 387 SwiftPM tests with 0 failures)
- `cd PokemonHackStudio && xcodegen generate` (passed; regenerated `PokemonHackStudio.xcodeproj` before app-hosted proof)
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T119-validation-tier-commands -destination 'platform=macOS,arch=arm64' -only-testing:PokemonHackStudioTests/WorkbenchIDEFoundationTests test` (blocked; Xcode stalled waiting for workers to materialize and was interrupted with `** TEST INTERRUPTED **` after emitting existing `allowedFileTypes` warnings only)
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T119-validation-tier-commands-retry -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:PokemonHackStudioTests/WorkbenchIDEFoundationTests test` (blocked; serial retry hit the same Xcode test-session stall and was interrupted with `** TEST INTERRUPTED **`)
- `swift test --package-path PokemonHackStudio --filter 'BuildPatchPlaytestValidationTests/testValidationTierCommandRowsStayCopyOnlyAndManual'` (passed on 2026-06-29 19:14:27 America/Vancouver; 1 selected SwiftPM core test, 0 failures; covers all validation-tier command rows, exact copy values, copy-only state, and disabled manual-run state)
- `make validate-synthetic` (blocked after `scripts-check` and build-tool availability passed; SwiftPM hit unrelated dirty-lane compile failures in `PokemonHackStudio/Sources/PokemonHackCore/PokemonDataCompatibility.swift:411` for `extra argument 'sourceIndex' in call`, plus `PokemonHackStudio/Sources/PokemonHackCore/NDSDataCatalog.swift` being modified during the build)
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T120-command-surface -destination 'platform=macOS,arch=arm64' build` (blocked before app target proof by unrelated dirty-lane compile failures in `PokemonHackStudio/Sources/PokemonHackCore/NDSDataEditing.swift:889` and `:892`: `parseDiamondPearlMapHeaderFields` not found)
- `git diff --check` (passed)

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/BuildPatchPlaytestValidation.swift`
- `PokemonHackStudio/Sources/PokemonHackStudio/Models/WorkbenchModels.swift`
- `PokemonHackStudio/Sources/PokemonHackStudio/Stores/WorkbenchStore.swift`
- `PokemonHackStudio/Sources/PokemonHackStudio/Views/Editors/BuildWorkbenchView.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/BuildPatchPlaytestValidationTests.swift`
- `PokemonHackStudio/Tests/PokemonHackStudioTests/WorkbenchIDEFoundationTests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/2026-06-29-phs-t120-validation-tier-command-surface.md`

## Posture

No validation command can execute from the UI. The core-backed command row exposes `copyValue` exactly equal to the selected `ValidationTier.command`, the pasteboard helper copies that value, and the disabled `Run manually` affordance has no execution path. `ValidationTier.command`, Makefile targets, CLI behavior, build runner, patch export, playtest launch/capture, mutation plans, source/binary write gates, and artifact-write powers remain unchanged.
