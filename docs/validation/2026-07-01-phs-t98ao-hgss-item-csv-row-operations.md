# PHS-T98AO HGSS Item CSV Row Operations

Date: 2026-07-01

## Scope

`PHS-T98AO` implements the HeartGold/SoulSilver item CSV row-operation follow-up. The requested plan named `PHS-T98AM`, but the live board already records `PHS-T98AM` for Diamond/Pearl script loader-only metadata and `PHS-T98AN` for Diamond/Pearl land-data JSON semantic fields, so this closeout uses the next free suffix.

Eligible rows are local source-tree, HeartGold/SoulSilver, `.items`, direct-child `files/itemtool/itemdata/*.csv` records. Insert/delete/reorder operations are zero-based data-row operations; the CSV header is preserved and never targeted.

## Proof

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/PokemonHackStudio-PHS-T98AM-hgss-item-csv-rows --filter 'NDSDataCatalogTests/testNDSDataItemCSVRowOperationPlanner|PokemonHackCLITests/testNDSDataItemCSVRowOperationCommands'`
  - Passed: 2 selected tests, 0 failures.
- `make validate-nds`
  - Passed on rerun after transient dirty-tree compile drift: 119 selected tests, 0 failures.
  - Optional central reference smokes skipped because `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky` were absent under `/Users/bryan/projects/reference-repos/repos`.
- `git diff --check`
  - Passed.

## Guardrails

Safe drafts lower to the existing `NDSDataEditPlan` and `NDSDataMutationApplier` path, preserving source hash/size freshness checks, explicit apply, atomic writes, and backup creation. CLI plan JSON stays redacted: it reports operation kinds/indexes and inserted column counts only, with no inserted CSV row text and no mutation `textPreview`.

Nested CSV, JSON item rows, binary item rows, containers/NARCs, generated/reference rows, BMG/message banks, non-HGSS profiles, ROM rebuild/export/playtest, nested schema reshaping, multiline CSV cells, invalid ranges, and binary writes remain blocked.
