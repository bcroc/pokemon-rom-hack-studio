# PHS-T98AD HGSS Map Relationship Readiness

## Scope

- Added a HeartGold/SoulSilver root-level relationship key for `files/fielddata/mapmatrix`, `files/fielddata/maptable`, and `src/data/map_headers.h`.
- Extended NDS catalog and CLI assertions so the three root records expose related-row context, ready map readiness, `Related Rows`, and `Related Domains` while preserving existing child map/script/text/zone relationships.
- Tightened semantic blocker wording for HGSS map matrix/table rows; no matrix/table writer, map editor, nested map editing, script editing, extraction, NARC rebuild, ROM rebuild/export, mutation apply, generated/reference write, or binary write path was added.

## Validation

- `swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests|PokemonHackCLITests/testNDSDataCatalogCommandEmitsHeartGoldSoulSilverMapInventoryJSON'` was attempted. The first run aborted before selected tests ran because unrelated `PokemonMoveCatalogTests.swift` changed during the build. Reruns failed before selected tests ran while compiling unrelated dirty `PokemonHackStudio/Sources/PokemonHackCore/MapCatalog.swift`: `MapEventCapacityLimits.unknown` and `MapEventCapacitySummary.unknown` are non-`Sendable` static properties rejected by Swift concurrency checks.
- `make validate-nds` was attempted and failed before NDS tests ran with the same unrelated `MapCatalog.swift` concurrency errors.
- `git diff --check` passed.

## Posture

PHS-T98AD is inventory/readiness metadata only. The existing NDS catalog JSON fields carry the new relationship facts; no public writer API or app editor capability changed.
