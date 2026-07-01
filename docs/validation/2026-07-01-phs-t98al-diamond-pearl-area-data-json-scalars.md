# PHS-T98AL Diamond/Pearl Area Data JSON Semantic Fields

## Scope

`PHS-T98AL` opens the Diamond/Pearl area-data JSON scalar follow-up after the live board recorded `PHS-T98AK` for Diamond/Pearl encounter slot scalars.

This row covers eligible local Diamond/Pearl source-tree area-data JSON rows:

- `files/fielddata/areadata/*.json`

The semantic editor exposes already-present top-level scalar JSON leaves through the existing NDS semantic draft, `NDSDataEditPlan`, explicit apply, backup, and reload path.

## Original Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/NDSDataEditing.swift`
- `PokemonHackStudio/Sources/PokemonHackCore/NDSDataCatalog.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/NDSDataCatalogTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `script/validate_nds.sh`
- `docs/nds-extension-plan.md`
- `docs/planning-and-progress.md`

## Write Posture

The path reuses the existing NDS semantic draft, `NDSDataEditPlan`, redacted preview, source hash/size freshness checks, explicit apply, backups, and catalog reload gate. It does not add a new CLI command, public writer family, app-only writer, NARC/container writer, generated/reference mutation, ROM rebuild/export, playtest launch, or binary write path.

Still blocked:

- the `files/fielddata/areadata` root
- binary members
- nested area-data directories
- `files/fielddata/land_data`
- map matrix/table rows
- missing field creation
- nested objects/arrays
- row add/remove/reorder
- NARC/container work
- generated/reference writes
- ROM rebuild/export/playtest
- binary writes

## Proof

- `swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests/testNDSDataSemanticEditorPlansDiamondPearlAreaDataJSONScalars|PokemonHackCLITests/testNDSDataSemanticCommandsPlanAndApplyDiamondPearlAreaDataJSONFields'`: passed, 2 selected tests and 0 failures. Covered Diamond/Pearl direct-child area-data JSON scalar discovery, catalog readiness/action-state facts, redacted CLI plan/apply, backup creation, invalid scalar blocking, nested edit blocking, nested directory blocking, land-data blocking, and binary area-data blocking.
- `make validate-nds`: passed, 113 selected NDS tests and 0 failures. Central NDS reference smokes skipped because `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky` were not found under `/Users/bryan/projects/reference-repos/repos`.
- `git diff --check`: passed after proof ledger reconciliation.

## Source-Write Posture

Diamond/Pearl area-data semantic edits are limited to already-present top-level scalar JSON leaves in eligible local direct-child `files/fielddata/areadata/*.json` rows and still lower to the existing `NDSDataEditPlan`. The `files/fielddata/areadata` root, binary members, nested area-data directories, `files/fielddata/land_data`, map matrix/table rows, missing field creation, nested objects/arrays, row add/remove/reorder, NARC/container work, generated/reference rows, ROM rebuild/export/playtest, and binary writes remain blocked.
