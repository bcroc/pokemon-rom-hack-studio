# PHS-T78AB Expansion All Learnables Regeneration Plan

## Scope

`PHS-T78AB` is a copy/report-only follow-up to the `PHS-T78AA` all-learnables disagreement review surface.

- Compatibility JSON adds optional `learnablesCoverage.regenerationPlan` when generated/source disagreements exist.
- The plan reports source buckets, bucket paths, aggregate generated-only/source-only move IDs, per-species review items, report-only commands, and guidance to use the project's documented generator outside PokemonHackStudio.
- SourceIndex/Resources facts expose the same review posture, source buckets, aggregate move IDs, report commands, and no-run/no-write guidance.
- No generated JSON write, regeneration command execution, learnset row insertion, constants, reference edit, ROM/build/export path, or binary write was added.

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/SourceIndex.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonDataCompatibilityTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/README.md`
- `docs/validation/2026-07-01-phs-t78ab-expansion-all-learnables-regeneration-plan.md`

## Proof

- Current live checkout proof passed with the requested focused SwiftPM filter:
  - `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t78ab-live-proof-20260702 --jobs 1 --filter 'PokemonDataCompatibilityTests/testExpansionAllLearnablesCoverageCountsGeneratedSourceAndMoveMismatches|SourceIndexTests/testExpansionMovedDataShapesIndexWithoutRequiredDescriptorWarnings|GenIIIAssetCatalogTests|PokemonHackCLITests/testPokemonCompatibilityAndAssetIndexCommandsEmitExpansionAllLearnablesFacts'`
  - Passed; 10 selected tests, 0 failures.
- Isolated row-only proof passed in `/tmp/phs-t78ab-clean.lqUwM6`, a clean archive of `HEAD` with only the PHS-T78AB source/test patch applied:
  - `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t78ab-clean-proof-swiftpm --jobs 1 --filter 'PokemonDataCompatibilityTests/testExpansionAllLearnablesCoverageCountsGeneratedSourceAndMoveMismatches|SourceIndexTests/testExpansionMovedDataShapesIndexWithoutRequiredDescriptorWarnings|GenIIIAssetCatalogTests|PokemonHackCLITests/testPokemonCompatibilityAndAssetIndexCommandsEmitExpansionAllLearnablesFacts'`
  - Passed; 10 selected tests, 0 failures.

## Source-Write Posture

Generated `src/data/pokemon/all_learnables.json` remains read-only generated context. This row adds only copy/report guidance and compatibility/resource facts; it does not run regeneration, write generated JSON, insert learnset rows, create constants, edit references, run builds/exports, mutate ROMs, or add binary writes.
