# PHS-T78S Expansion All Learnables Coverage Facts

Date: 2026-06-30 America/Vancouver

## Scope

`PHS-T78S` is the metadata-only Expansion all-learnables coverage slice. The requested plan named `PHS-T78Q`, but the live board already records `PHS-T78Q` for Expansion item effect/icon editing and `PHS-T78R` for Expansion move contest scalar editing, so this row is recorded as the next unused `PHS-T78S`.

Generated `src/data/pokemon/all_learnables.json` is parsed only for comparison against parsed level-up, TM/HM, tutor, and egg learnset source moves. The row adds no generated JSON regeneration/write, learnset row insertion, constants, generated output write, reference write, ROM/build/export path, binary write, or broader Species mutation path.

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/SourceIndex.swift`
- `PokemonHackStudio/Sources/PokemonHackCore/PokemonDataCompatibility.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonDataCompatibilityTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/README.md`
- `docs/validation/2026-06-30-phs-t78s-expansion-all-learnables-coverage.md`

## Proof

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t78s-coverage-swiftpm --filter 'PokemonDataCompatibilityTests/testExpansionAllLearnablesCoverageCountsGeneratedSourceAndMoveMismatches|PokemonHackCLITests/testPokemonCompatibilityAndAssetIndexCommandsEmitExpansionAllLearnablesFacts'`
  - Passed; 2 selected tests, 0 failures.
  - Covers synthetic matching, generated-only, source-only, move-mismatch, stale-source counts, and CLI asset-index/resource facts.
- `swift test --package-path PokemonHackStudio --filter 'PokemonDataCompatibilityTests|GenIIIAssetCatalogTests|PokemonHackCLITests/testPokemonCompatibility'`
  - Passed; 27 selected tests, 0 failures.
  - Covers `learnablesCoverage` on all four Expansion learnset compatibility entries, SourceIndex to asset catalog/Resources propagation, and CLI JSON.
- `git diff --check`
  - Passed.

## Source-Write Posture

This row remains metadata-only. Generated `src/data/pokemon/all_learnables.json`, parsed learnset sources, generated outputs, references, ROM/build/export outputs, and binary files remain read-only for this slice.
