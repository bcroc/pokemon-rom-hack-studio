# PHS-T98AK Diamond/Pearl Encounter Slot Scalar Fields

## Scope

PHS-T98AK records the Diamond/Pearl encounter slot scalar repair after the live board assigned `PHS-T98AJ` to HeartGold/SoulSilver encounter slot scalar fields.

This row covers only eligible local Diamond/Pearl source-tree encounter JSON rows:

- `encounters:files/fielddata/encountdata/**/*.json`

The semantic editor exposes already-present scalar values at the top level, already-present scalar-array entries such as `swarms.0`, and already-present object-array scalar fields such as `slots.0.rate` and `slots.0.species`.

`arm9/src/encounter.c` remains loader-only/non-editable under `PHS-T98AH`.

## Write Posture

The path reuses the existing NDS semantic draft, `NDSDataEditPlan`, redacted preview, source hash/size freshness checks, explicit apply, backups, and catalog reload gate. It does not add a new CLI command, public writer family, app-only writer, C-anchor encounter writer, NARC/container writer, generated/reference mutation, ROM rebuild/export, playtest launch, or binary write path.

Still blocked:

- slot insert/delete/reorder
- missing field or missing slot creation
- nested object reshaping such as `metadata.map` or `slots.0.metadata.time`
- C anchors
- non-JSON rows
- NARC/container rows
- generated/reference rows
- ROM rebuild/export/playtest
- binary writes

## Proof

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/PokemonHackStudio-PHS-T98AK-plan-check --filter 'NDSDataCatalogTests/testNDSDataSemanticEditorPlansDiamondPearlEncounterJSONScalars|PokemonHackCLITests/testNDSDataSemanticCommandsPlanAndApplyDiamondPearlEncounterJSONFields'`: passed, 2 selected tests and 0 failures. Covered Diamond/Pearl encounter top-level scalars, scalar-array slots, object-array slot scalar fields, redacted CLI plan/apply, missing-slot blocking, nested-object blocking, non-JSON blockers, and the `arm9/src/encounter.c` loader-only blocker.
- `make validate-nds`: passed, 109 selected tests and 0 failures. Central clean-room reference smokes skipped because `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky` were not present under `/Users/bryan/projects/reference-repos/repos`.
- `git diff --check`: passed after docs/proof reconciliation.
