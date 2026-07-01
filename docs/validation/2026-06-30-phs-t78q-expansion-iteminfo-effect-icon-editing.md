# PHS-T78Q Expansion ItemInfo Effect/Icon Editing

## Summary

- Row ID: `PHS-T78Q`. The live board already records `PHS-T78P` as the metadata-only `gItemsInfo` effect/icon facts row, so this writer slice uses the next unused `PHS-T78Q` ID.
- Adds local source-backed editing for existing Expansion `src/data/items.h` `gItemsInfo` `.effect`, `.iconPic`, and `.iconPalette` fields.
- Values must be simple C symbols. Expressions, calls, removals, row insertion/removal/reorder, item identity/constants, generated outputs, Modern Emerald writes, icon asset rewrites, ROM/build/export paths, binary writes, and broad item schema rewrites stay blocked.

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/PokemonItemCatalog.swift`
- `PokemonHackStudio/Sources/PokemonHackCore/PokemonDataCompatibility.swift`
- `PokemonHackStudio/Sources/PokemonHackStudio/Views/Editors/PokemonItemsWorkbenchView.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonItemCatalogTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonDataCompatibilityTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/README.md`
- `docs/validation/2026-06-30-phs-t78q-expansion-iteminfo-effect-icon-editing.md`

## Validation

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t78q-cli-scratch --filter PokemonItemCatalogTests` (passed; 13 selected tests, 0 failures.)
- Historical run: `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t78q-cli-scratch --filter PokemonDataCompatibilityTests` (blocked by unrelated all-learnables compatibility failures after the PHS-T78Q item compatibility assertion passed; 12 selected tests ran, 5 failures in `testExpansionAllLearnablesCoverageCountsGeneratedSourceAndMoveMismatches` and `testExpansionLearnsetCompatibilityWarnsWhenAllLearnablesIsStale`; superseded by the current reconciliation proof below.)
- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t78q-cli-scratch --filter 'PokemonHackCLITests/testPokemonCompatibilityCommandEmitsModernEmeraldMetadataJSON|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsExpansionItemEffectIconEditableJSON'` (passed; 2 selected tests, 0 failures.)
- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-reconcile-all-learnables-swiftpm --filter 'PokemonDataCompatibilityTests|GenIIIAssetCatalogTests|PokemonHackCLITests/testPokemonCompatibility'` (passed on 2026-07-01; 28 selected tests, 0 failures; confirms the current compatibility/catalog/CLI all-learnables proof passes.)
- `git diff --check` (passed.)

## Source-Write Posture

- Expansion effect/icon edits are limited to existing local fields in `src/data/items.h` `gItemsInfo` rows and still require explicit item mutation preview/apply with source hash/size checks and backups.
- No identity edits, constant creation, row insertion/removal/reorder, generated output write, Modern Emerald write, icon asset rewrite, ROM/build/export path, binary write, or broad item schema rewrite was added.
