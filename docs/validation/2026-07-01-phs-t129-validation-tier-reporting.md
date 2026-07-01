# PHS-T129 Validation Tier Reporting

## Scope

- Add the missing optional NDS validation tier, `make validate-nds`, between strict GBA fixture validation and strict central NDS reference validation.
- Extend the shared Core `ValidationTierCommandRow` model so CLI JSON and Build/Patch/Playtest rows use the same exact command, copy value, strictness, disabled manual-run state, and skip-versus-fail reference cause metadata.
- Add CLI `validation-tiers --json` as a metadata-only report. It does not run Make, shell scripts, SwiftPM, Xcode, or validation commands.
- Show strictness and skipped-reference cause summaries in the app's copy-only validation rows while keeping `Run manually` disabled.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'BuildPatchPlaytestValidationTests/testValidationTierCommandRowsReportStrictnessSkippedCausesAndExactCommands|PokemonHackCLITests/testValidationTiersCommandUsesSharedCopyOnlyModelJSON|PokemonHackCLITests/testHelpUsesCommandMetadataForTextAndJSON'` passed after waiting on an existing SwiftPM `.build` lock: 3 selected tests, 0 failures.
- `cd PokemonHackStudio && xcodegen generate` passed.
- `cd PokemonHackStudio && POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath ../DerivedData/PokemonHackStudio-PHS-T129-validation-tier-reporting -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:PokemonHackStudioTests/WorkbenchIDEFoundationTests/testValidationTierCommandRowsReportStrictnessSkippedCausesAndExactCommands -only-testing:PokemonHackStudioTests/WorkbenchIDEFoundationTests/testValidationTierCommandCopyWritesExactCommand test` passed with existing `allowedFileTypes`, ad-hoc signing, and bundle-script warnings only.
- `make verify` passed: the app project/plists regenerated, the app built and signed, the bundle-assets phase ran, LaunchServices registration completed, and the verify script finished after `BUILD SUCCEEDED`.
- `git diff --check` passed.

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/BuildPatchPlaytestValidation.swift`
- `PokemonHackStudio/Sources/pokemonhack-cli/PokemonHackCLI.swift`
- `PokemonHackStudio/Sources/PokemonHackStudio/Views/Editors/BuildWorkbenchView.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/BuildPatchPlaytestValidationTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `PokemonHackStudio/Tests/PokemonHackStudioTests/WorkbenchIDEFoundationTests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/README.md`
- `docs/validation/2026-07-01-phs-t129-validation-tier-reporting.md`

## Posture

No validation command can execute from the UI. The app copy helper still writes only `ValidationTierCommandRow.copyValue`, and that value exactly matches the displayed command. CLI `validation-tiers --json` emits static shared metadata only. Makefile targets, validation scripts, build/playtest execution, patch/export authority, source-write paths, ROM writes, binary writes, and mutation gates are unchanged.
