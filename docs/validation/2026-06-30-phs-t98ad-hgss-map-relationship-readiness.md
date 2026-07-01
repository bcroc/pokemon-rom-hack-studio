# PHS-T98AD HGSS Map Relationship Readiness

## Scope

- Added a HeartGold/SoulSilver root-level relationship key for `files/fielddata/mapmatrix`, `files/fielddata/maptable`, and `src/data/map_headers.h`.
- Extended NDS catalog and CLI assertions so the three root records expose related-row context, ready map readiness, `Related Rows`, and `Related Domains` while preserving existing child map/script/text/zone relationships.
- Tightened semantic blocker wording for HGSS map matrix/table rows; no matrix/table writer, map editor, nested map editing, script editing, extraction, NARC rebuild, ROM rebuild/export, mutation apply, generated/reference write, or binary write path was added.

## Validation

- `swift test --package-path PokemonHackStudio --filter 'MapCatalogTests|MapWorkflowPlanTests'` passed on 2026-06-30 22:25 America/Vancouver with 17 selected tests and 0 failures. This confirms the `MapEventCapacityLimits.unknown` and `MapEventCapacitySummary.unknown` Swift concurrency blocker is resolved while warning-only map event capacity diagnostics remain non-blocking for mutation-plan applyability.
- `swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests|PokemonHackCLITests/testNDSDataCatalogCommandEmitsHeartGoldSoulSilverMapInventoryJSON'` passed on 2026-06-30 22:25 America/Vancouver with 54 selected tests and 0 failures.
- `make validate-nds` passed on 2026-06-30 22:25 America/Vancouver with 103 selected tests and 0 failures. Central clean-room reference smokes were skipped because `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky` were not present under `/Users/bryan/projects/reference-repos/repos`.
- `git diff --check` passed after proof reconciliation.

## Posture

PHS-T98AD is inventory/readiness metadata only. The existing NDS catalog JSON fields carry the new relationship facts; no public writer API or app editor capability changed.
