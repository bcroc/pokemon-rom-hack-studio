# PHS-T78Y Expansion Item Usage Scalars

## Scope

`PHS-T78Y` opens one narrow Expansion `gItemsInfo` descriptor family: existing local `src/data/items.h` `.holdEffect`, `.holdEffectParam`, `.pocket`, and `.type` fields.

- `.holdEffect`, `.pocket`, and `.type` accept a single C identifier.
- `.holdEffectParam` accepts a single C identifier or integer literal.
- The existing item draft, mutation preview, source hash/size applyability, backup, apply, and reload path is reused.
- The row is recorded as `PHS-T78Y` because the live board already uses `PHS-T78X` for the adjacent Expansion item bag/classification scalar row.

## Proof

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t78x-recheck --jobs 1 --filter 'PokemonItemCatalogTests/testExpansionItemInfoBagClassificationScalarsPlanApplyBackUpReloadAndBlockDrift|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsRubySapphireMovesEditableJSON|PokemonItemCatalogTests/testExpansionItemInfoUsageScalarsPlanApplyBackUpAndReload|PokemonItemCatalogTests/testExpansionItemInfoUsageScalarsRejectNonSimpleValuesRemovalAndMissingFields|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsExpansionItemUsageScalarsEditableJSON'` passed with 5 selected tests and 0 failures.
- `swift test --package-path PokemonHackStudio --filter 'PokemonItemCatalogTests|PokemonDataCompatibilityTests|PokemonHackCLITests'` passed with 117 selected tests and 0 failures.
- App-hosted proof was not run because no SwiftUI, app store, or Xcode project files changed.
- `git diff --check` passed.

## Notes

Two earlier SwiftPM attempts were invalidated before row assertions by the package input-file modified guard on `PokemonHackStudio/Sources/PokemonHackCore/PokemonDataCompatibility.swift` while unrelated dirty-lane edits were landing. Final proof passed after the checkout settled.

## Source-Write Posture

Usage/classification scalar edits are limited to existing local Expansion `src/data/items.h` `gItemsInfo` fields. Missing-field insertion, removal, non-simple expressions, constants-file edits or creation, row insertion/removal/reorder, generated outputs, reference rows, ROM/build/export paths, binary writes, and broad item schema rewrites remain blocked.
