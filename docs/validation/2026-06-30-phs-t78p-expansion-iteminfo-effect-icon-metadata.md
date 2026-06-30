# PHS-T78P Expansion ItemInfo Effect/Icon Metadata Facts

## Summary

- Row ID: `PHS-T78P`. The requested plan expected `PHS-T78O`, but the live board already uses `PHS-T78O` for Expansion `gMovesInfo` contest metadata facts.
- Adds metadata-only facts for Expansion `src/data/items.h` `gItemsInfo` `.effect`, `.iconPic`, and `.iconPalette`.
- No effect/icon writers, generated output writes, Modern Emerald writes, ROM/build/export paths, item identity edits, or broad item schema rewrites were added.

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/PokemonItemCatalog.swift`
- `PokemonHackStudio/Sources/PokemonHackCore/SourceIndex.swift`
- `PokemonHackStudio/Sources/PokemonHackCore/PokemonDataCompatibility.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonItemCatalogTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonDataCompatibilityTests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/README.md`
- `docs/validation/2026-06-30-phs-t78p-expansion-iteminfo-effect-icon-metadata.md`

## Validation

- `swift test --package-path PokemonHackStudio --filter 'PokemonItemCatalogTests|PokemonDataCompatibilityTests|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsPreviewJSON'` (blocked before selected tests executed by unrelated compile drift in `PokemonHackStudio/Sources/PokemonHackCore/MapCatalog.swift`: `MapEventCapacityLimits.unknown` and `MapEventCapacitySummary.unknown` are rejected as non-`Sendable` static properties under Swift concurrency checks.)
- `make validate-synthetic` (blocked at the same unrelated `MapCatalog.swift` concurrency diagnostics after `bash -n script/*.sh` and `./script/build_and_run.sh --check-tools` passed.)
- `git diff --check` (passed.)

## Source-Write Posture

- Metadata-only row. Expansion `gItemsInfo` `.effect`, `.iconPic`, and `.iconPalette` are exposed as catalog/source-index/compatibility facts only.
- `ItemEditDraft`, item mutation planning, apply/export/build/ROM paths, generated writes, Modern Emerald writes, and identity edits remain unchanged or blocked.
