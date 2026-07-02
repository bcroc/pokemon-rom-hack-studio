# PHS-T98AS HGSS Encounter JSON Row Operations

Date: 2026-07-01

## Scope

`PHS-T98AS` implements the HeartGold/SoulSilver encounter JSON row-operation follow-up after the live board's `PHS-T98AR` Platinum encounter JSON row-operation row.

Eligible HGSS rows are local source-tree `.encounters` JSON records under `files/fielddata/encountdata/**/*.json`. The planner operates on one existing top-level object array at a time. Insert/delete/reorder operations are zero-based and sequential; reorder destinations are interpreted after removing the source row.

No Resources app row-operation controls, NARC work, ROM rebuild/export/playtest path, broad schema reshaping, or binary writes were added.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests/testNDSDataEncounterJSONRowOperationPlanner|NDSDataCatalogTests/testNDSDataEncounterJSONRowOperationPlannerHeartGoldSoulSilver'`
  - Passed: 2 selected tests, 0 failures.
- `swift test --package-path PokemonHackStudio --filter 'PokemonHackCLITests/testNDSDataEncounterJSONRowOperationCommands|PokemonHackCLITests/testNDSDataEncounterJSONRowOperationCommandsHeartGoldSoulSilver'`
  - Passed: 2 selected tests, 0 failures.
- `make validate-nds`
  - Passed: 125 selected tests, 0 failures.
  - Optional central reference smokes skipped because `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky` were absent under `/Users/bryan/projects/reference-repos/repos`.
- `git diff --check`
  - Passed.

## Guardrails

Safe drafts lower to the existing `NDSDataEditPlan` and `NDSDataMutationApplier` path, preserving source hash/size freshness checks, explicit apply, atomic writes, and backup creation. CLI plan JSON stays redacted: it reports operation kinds/indexes and inserted field counts only, with no inserted JSON row text, replacement bytes, `textPreview`, or full edited source.

Scalar arrays such as `swarms`, missing or empty arrays, object rows with mismatched or duplicate keys, nested row values, nested array-key paths such as `metadata.slots`, C anchors, non-JSON rows, Diamond/Pearl rows, generated/reference/container rows, ROM rebuild/export/playtest, nested schema reshaping, broad schemas, and binary writes remain blocked.

## Notes

- A compile-only correction in the already-dirty Gen V readiness packet call chain moved `index` and `fileManager` back onto `enrichGenVReadiness`, restoring SwiftPM compilation before row validation.
