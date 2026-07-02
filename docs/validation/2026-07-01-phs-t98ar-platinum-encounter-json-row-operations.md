# PHS-T98AR Platinum Encounter JSON Row Operations

Date: 2026-07-01

## Scope

`PHS-T98AR` implements the Platinum encounter JSON row-operation follow-up. The requested plan named `PHS-T98AP`, but the live board now records `PHS-T98AP` for Gen IV map review packets and `PHS-T98AQ` for Resources row-operation controls, so this closeout uses the next free suffix.

Eligible rows are local source-tree, Platinum, `.encounters`, direct-child `res/field/encounters/*.json` records. The planner operates on one existing top-level object array at a time. Insert/delete/reorder operations are zero-based and sequential; reorder destinations are interpreted after removing the source row.

## Proof

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/PokemonHackStudio-PHS-T98AP-encounter-json-rows --filter 'NDSDataCatalogTests/testNDSDataEncounterJSONRowOperationPlanner|PokemonHackCLITests/testNDSDataEncounterJSONRowOperationCommands'`
  - Passed on rerun: 2 selected tests, 0 failures.
- `swift test --package-path PokemonHackStudio --scratch-path /tmp/PokemonHackStudio-PHS-T98AP-semantic --filter 'PokemonHackCLITests/testNDSDataSemanticCommandsPlanAndApplyPlatinumEncounterJSONFields'`
  - Passed on rerun after a transient dirty-tree SwiftPM race reported `PokemonDataCompatibility.swift` was modified during the first build: 1 selected test, 0 failures.
- `make validate-nds`
  - Passed: 122 selected tests, 0 failures.
  - Optional central reference smokes skipped because `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky` were absent under `/Users/bryan/projects/reference-repos/repos`.
- `git diff --check`
  - Passed.

## Guardrails

Safe drafts lower to the existing `NDSDataEditPlan` and `NDSDataMutationApplier` path, preserving source hash/size freshness checks, explicit apply, atomic writes, and backup creation. CLI plan JSON stays redacted: it reports operation kinds/indexes and inserted field counts only, with no inserted JSON row text, replacement bytes, `textPreview`, or full edited source.

Scalar arrays such as `swarms`, missing or empty arrays, object rows with mismatched or duplicate keys, nested row values, nested encounter directories, non-JSON rows, HGSS/DP rows, generated/reference/container rows, ROM rebuild/export/playtest, nested schema reshaping, broad schemas, and binary writes remain blocked.
