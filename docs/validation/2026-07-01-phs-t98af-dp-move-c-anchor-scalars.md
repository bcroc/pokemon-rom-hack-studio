# PHS-T98AF DP Move C-Anchor Simple Scalars

## Scope

PHS-T98AF opens the next unused `PHS-T98*` row after `PHS-T98AE` for a narrow Diamond/Pearl semantic writer on exactly one row:

- `moves:arm9/src/waza.c`

The writer recognizes only exact `static const struct WazaTbl sWazaTbl[]` direct designated entries and exposes existing `.effect`, `.class`, `.power`, `.type`, `.accuracy`, `.pp`, `.effectChance`, `.unk8`, `.priority`, `.unkB`, `.unkC`, and `.contestType` assignments as `waza.<MOVE_CONSTANT>.<fieldName>`. Values must be simple C integer literals or simple C identifiers.

## Write Posture

The path reuses the existing NDS semantic draft, `NDSDataEditPlan`, explicit apply, and backup flow. It does not add a new CLI command, app-only writer, NARC/container writer, generated/reference mutation, ROM rebuild/export, row insert/remove/reorder, or binary write path.

Still blocked:

- `encounters:arm9/src/encounter.c`
- `padding`
- calls, casts, arithmetic, braces, strings, and other non-simple C expressions
- missing fields
- positional or non-designated rows
- duplicate field edits
- NARC/container work
- generated/reference rows
- ROM rebuild/export
- binary writes

## Proof

- `swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests/testNDSDataSemanticEditorPlansDiamondPearlMoveCAnchorScalars|NDSDataCatalogTests/testDiamondCatalogKeepsCSourceAnchorsConservative|PokemonHackCLITests/testNDSDataSemanticCommandsPlanAndApplyDiamondPearlMoveCAnchorScalars|PokemonHackCLITests/testNDSDataCatalogCommandEmitsDiamondPearlMapInventoryJSON'`: passed, 4 selected tests and 0 failures. Covered exact `sWazaTbl` scalar snapshot, plan/apply through one NDS source-file change, backup creation, source preservation, invalid value/missing field/duplicate edit refusal, catalog and `resource-index` facts, and blocked `encounters:arm9/src/encounter.c` apply attempts.
- `make validate-nds`: passed, 105 selected tests and 0 failures. Central clean-room reference smokes skipped because `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky` were not present under `/Users/bryan/projects/reference-repos/repos`.
- `git diff --check`: passed after docs/proof reconciliation.
