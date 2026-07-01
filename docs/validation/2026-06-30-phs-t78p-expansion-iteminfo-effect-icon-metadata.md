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

- `swift test --package-path PokemonHackStudio --filter 'PokemonItemCatalogTests|PokemonDataCompatibilityTests|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsPreviewJSON'` passed on 2026-06-30 17:34 America/Vancouver with 24 selected tests and 0 failures.
- `make validate-synthetic` was rerun on 2026-06-30 17:35 America/Vancouver. `bash -n script/*.sh` and `./script/build_and_run.sh --check-tools` passed, SwiftPM built, then the full suite executed 433 tests with 6 unrelated Gen V NitroFS root failures: 3 in `NDSDataCatalogTests/testPokeBlackCatalogSurfacesGenVNitroFSRootInventoryFacts` and 3 in `PokemonHackCLITests/testNDSDataCatalogCommandEmitsPokeBlackNitroFSRootInventoryJSON`, expecting shallow count `10` and observing `13` plus matching fact assertion failures.
- `git diff --check` passed. Post-validation `git status --short --branch` showed `## main...origin/main [ahead 1]`.

## Source-Write Posture

- Metadata-only row. Expansion `gItemsInfo` `.effect`, `.iconPic`, and `.iconPalette` are exposed as catalog/source-index/compatibility facts only.
- `ItemEditDraft`, item mutation planning, apply/export/build/ROM paths, generated writes, Modern Emerald writes, and identity edits remain unchanged or blocked.
