# PHS-T78R Expansion Move Contest Scalar Editing

## Summary

- Row ID: `PHS-T78R`. The requested plan named `PHS-T78Q`, but the live board already records `PHS-T78Q` as the Expansion `gItemsInfo` effect/icon writer row, so this move contest scalar slice uses the next unused `PHS-T78R` ID.
- Existing simple Expansion `src/data/moves_info.h` `gMovesInfo` `contestCategory`, `contestAppeal`, `contestJam`, and `contestComboStarterId` fields now flow through `MoveEditDraft`, `MoveMutationPlanner`, preview, explicit apply, backup, and reload.
- This supersedes the `PHS-T78O` facts-only posture only for those four existing simple scalar fields. `contestComboMoves` arrays, generated outputs, references, constants, row insertion/removal/reorder, ROM/build/export paths, binary writes, and broad Expansion move schema rewrites remain blocked.

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/PokemonMoveCatalog.swift`
- `PokemonHackStudio/Sources/PokemonHackCore/PokemonDataCompatibility.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonMoveCatalogTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonDataCompatibilityTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/README.md`
- `docs/validation/2026-07-01-phs-t78r-expansion-move-contest-scalars.md`

## Validation

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t78q-swiftpm --filter 'PokemonMoveCatalogTests/testExpansionMovesInfoRowsPlanApplyAndReloadThroughDescriptor|PokemonMoveCatalogTests/testExpansionMoveContestScalarPlanningBlocksUnsupportedCases|PokemonDataCompatibilityTests/testExpansionMovesInfoRowsReportEditableWithBlockedAdjacentSourcesAndJSON'` (passed; 3 selected tests, 0 failures.)
- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t78q-swiftpm --filter 'PokemonHackCLITests/testMoveCatalogCommandEmitsExpansionContestScalarJSON|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsExpansionContestScalarsEditableJSON'` (passed; 2 selected CLI JSON tests, 0 failures.)
- Historical run: `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t78q-swiftpm --filter 'PokemonMoveCatalogTests|PokemonDataCompatibilityTests'` (blocked by unrelated all-learnables compatibility assertions after the PHS-T78R move catalog and compatibility tests passed; failures remained in `testExpansionAllLearnablesCoverageCountsGeneratedSourceAndMoveMismatches` and `testExpansionLearnsetCompatibilityWarnsWhenAllLearnablesIsStale`; superseded by the current reconciliation proof below.)
- Historical run: `make validate` (blocked by the same unrelated all-learnables compatibility assertions after the SwiftPM suite ran; PHS-T78R core, compatibility, and CLI JSON tests passed inside the run; not rerun for this docs-only reconciliation.)
- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-reconcile-all-learnables-swiftpm --filter 'PokemonDataCompatibilityTests|GenIIIAssetCatalogTests|PokemonHackCLITests/testPokemonCompatibility'` (passed on 2026-07-01; 28 selected tests, 0 failures; confirms the current compatibility/catalog/CLI all-learnables proof passes.)
- `git diff --check` (passed.)

## Source-Write Posture

- Expansion move contest scalar edits are limited to existing local `src/data/moves_info.h` `gMovesInfo` fields named `contestCategory`, `contestAppeal`, `contestJam`, and `contestComboStarterId`.
- Symbol-like scalar fields accept simple C symbols or integer literals where already present; `contestAppeal` and `contestJam` are bounded to `0...255`.
- `contestComboMoves` arrays, generated outputs, references, constants, row insertion/removal/reorder, ROM/build/export paths, binary writes, and broad Expansion move schema rewrites remain blocked.
