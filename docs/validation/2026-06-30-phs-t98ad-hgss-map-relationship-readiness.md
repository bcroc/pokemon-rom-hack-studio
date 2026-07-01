# PHS-T98AD HGSS Map Relationship Readiness

## Scope

- Added a HeartGold/SoulSilver root-level relationship key for `files/fielddata/mapmatrix`, `files/fielddata/maptable`, and `src/data/map_headers.h`.
- Extended NDS catalog and CLI assertions so the three root records expose related-row context, ready map readiness, `Related Rows`, and `Related Domains` while preserving existing child map/script/text/zone relationships.
- Tightened semantic blocker wording for HGSS map matrix/table rows; no matrix/table writer, map editor, nested map editing, script editing, extraction, NARC rebuild, ROM rebuild/export, mutation apply, generated/reference write, or binary write path was added.

## Validation

- `swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests|PokemonHackCLITests/testNDSDataCatalogCommandEmitsHeartGoldSoulSilverMapInventoryJSON'` was rerun on 2026-06-30 17:34 America/Vancouver. SwiftPM built and ran 54 selected tests; `PokemonHackCLITests/testNDSDataCatalogCommandEmitsHeartGoldSoulSilverMapInventoryJSON` passed, but the selected run failed in unrelated `NDSDataCatalogTests/testPokeBlackCatalogSurfacesGenVNitroFSRootInventoryFacts` assertions expecting shallow count `10` and observing `13`, with the matching resource-index/fact assertion failing.
- `make validate-nds` was rerun on 2026-06-30 17:34 America/Vancouver. SwiftPM built and ran 103 selected tests; the routed HGSS map inventory and semantic CLI tests passed, but the tier failed on the same unrelated Gen V NitroFS root shallow-count drift with 3 failures.
- `git diff --check` passed. Post-validation `git status --short --branch` showed `## main...origin/main [ahead 1]`.

## Posture

PHS-T98AD is inventory/readiness metadata only. The existing NDS catalog JSON fields carry the new relationship facts; no public writer API or app editor capability changed.
