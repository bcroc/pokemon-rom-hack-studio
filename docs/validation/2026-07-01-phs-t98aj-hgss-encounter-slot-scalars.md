# PHS-T98AJ HGSS Encounter Slot Scalar Fields

## Scope

PHS-T98AJ opens the next unused `PHS-T98*` row after the live board's `PHS-T98AI` Platinum encounter slot scalar row.

This row extends HeartGold/SoulSilver source-tree encounter JSON semantic editing for:

- `encounters:files/fielddata/encountdata/**/*.json`

The semantic editor now exposes existing scalar values at the top level, existing scalar-array entries such as `swarms.1`, and existing object-array slot scalar fields such as `slots.0.rate` and `slots.0.species`.

The historical companion Diamond/Pearl regression check from this row is superseded by `PHS-T98AK`, which now covers Diamond/Pearl encounter slot scalar editing separately.

## Write Posture

The path reuses the existing NDS semantic draft, `NDSDataEditPlan`, redacted preview, source hash/size freshness checks, explicit apply, backups, and catalog reload gate. It does not add a new CLI command, public writer family, app-only writer, NARC/container writer, generated/reference mutation, ROM rebuild/export, playtest launch, or binary write path.

Still blocked:

- slot insert/delete/reorder
- missing slot creation
- nested object reshaping such as `metadata.map`
- C anchors
- non-JSON rows
- NARC/container rows
- generated/reference rows
- ROM rebuild/export/playtest
- binary writes

## Proof

- `swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests/testNDSDataSemanticEditorPlansHeartGoldSoulSilverEncounterJSONScalars|PokemonHackCLITests/testNDSDataSemanticCommandsPlanAndApplyHeartGoldSoulSilverEncounterJSONFields'`: passed, 2 selected tests and 0 failures. Covered HGSS slot field discovery, semantic plan/apply, redacted CLI plan output, backup creation, source preservation, nested-object refusal, missing-slot refusal, and text/C-anchor blocking.
- `swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests/testNDSDataSemanticEditorPlansHeartGoldSoulSilverEncounterJSONScalars|PokemonHackCLITests/testNDSDataSemanticCommandsPlanAndApplyHeartGoldSoulSilverEncounterJSONFields|NDSDataCatalogTests/testNDSDataSemanticEditorPlansDiamondPearlEncounterJSONScalars|PokemonHackCLITests/testNDSDataSemanticCommandsPlanAndApplyDiamondPearlEncounterJSONFields'`: passed, 4 selected tests and 0 failures. This was the historical Diamond/Pearl regression before `PHS-T98AK` widened DP encounter JSON slot scalars.
- `make validate-nds`: passed, 109 selected tests and 0 failures. Central clean-room reference smokes skipped because `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky` were not present under `/Users/bryan/projects/reference-repos/repos`.
- `git diff --check`: passed after docs/proof reconciliation.
