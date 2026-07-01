# PHS-T78V Expansion Move Flags Editing

## Summary

`PHS-T78V` opens the narrow Expansion `gMovesInfo` flags editor after the live board's `PHS-T78U` combo-array row. Existing local `src/data/moves_info.h` `.flags` fields now edit through `MoveEditDraft` and `MoveMutationPlanner` when the current value and draft are simple `FLAG_*` token lists.

Missing `.flags` fields are inserted only for existing local Expansion rows, directly after `.priority`, when the submitted draft is non-empty and every token is a known local `FLAG_*` constant. Empty missing-field drafts remain unchanged.

## Proof

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t78v-move-flags-core --filter 'PokemonMoveCatalogTests|PokemonDataCompatibilityTests'` passed with 29 selected tests and 0 failures.
- The earlier broad `PokemonHackCLITests` blocker is superseded by current focused reconciliation proof: `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-july1-reconcile-swiftpm-current --jobs 1 --filter 'BuildPatchPlaytestValidationTests|NDSDataCatalogTests/testPokeBlackCatalogLinksGenVSourceDataDomainInventoryRelatedRows|PokemonHackCLITests/testNDSDataCatalogCommandLinksPokeBlackSourceDataDomainInventoryRelatedRowsJSON|PokemonHackCLITests/testMoveCatalogCommandEmitsExpansionContestScalarJSON|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsExpansionContestScalarsEditableJSON|PokemonHackCLITests/testPatchCreateCommandWritesIgnoredBPSAndManifest|PokemonHackCLITests/testPatchCreateCommandBlocksMismatchedBaseROMWithNonzeroExit|NDSDataCatalogTests/testNDSDataSemanticEditorPlansDiamondPearlEncounterJSONScalars|PokemonHackCLITests/testNDSDataSemanticCommandsPlanAndApplyDiamondPearlEncounterJSONFields'` passed with 49 selected tests and 0 failures.
- That focused proof covers the PHS-T78V CLI assertions and the formerly blocking Diamond/Pearl semantic assertions; it is not a full CLI-suite rerun.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T78V-Flags -destination 'platform=macOS,arch=arm64' -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testExpansionMoveMissingFlagsDraftPreviewApplyAndReloadsThroughMovesEditor test` passed in the original row proof and was not rerun during this docs reconciliation.
- `git diff --check` passed.

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/PokemonMoveCatalog.swift`
- `PokemonHackStudio/Sources/PokemonHackCore/PokemonDataCompatibility.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonMoveCatalogTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonDataCompatibilityTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `PokemonHackStudio/Tests/PokemonHackStudioTests/MapEditorStoreTests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/README.md`
- `docs/validation/2026-07-01-phs-t78v-expansion-move-flags.md`

## Boundaries

No new constants, non-simple expression round trips, row insertion/removal/reorder, generated output writes, reference writes, ROM/build/export paths, binary writes, or broad move schema rewrites were added. Missing constants headers, unreadable constants, invalid or unknown flag tokens, unsupported profiles/sources, missing rows, and missing `.priority` insertion anchors remain blocking diagnostics.
