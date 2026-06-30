# PHS-T98Y Diamond/Pearl Map Inventory Metadata

Date: 2026-06-29

## Scope

Metadata-only Diamond/Pearl map inventory coverage was added for:

- `arm9/src/map_header.c`
- `files/fielddata/mapmatrix`
- `files/fielddata/maptable`
- `files/fielddata/land_data`
- `files/fielddata/areadata`

The rows surface inventory-only source-role, provenance, readiness, action-state, blocked-action, and diagnostic facts through the NDS catalog, CLI JSON, `resource-index`, and Resources. This pass does not add semantic editing, raw C-anchor writes, map editor workflows, rebuilds, exports, generated/reference writes, ROM writes, NARC/container writes, or binary writes.

## Proof

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t98y-build --filter 'NDSDataCatalogTests|PokemonHackCLITests/testNDSDataCatalogCommandEmitsDiamondPearlMapInventoryJSON'`
  - Passed on rerun after a stale `.build` lock and concurrent file-modification race.
  - 51 selected tests, 0 failures.
  - Covered Diamond/Pearl map inventory facts, diagnostics, blocked actions, no migration status on summary roots, continued map/C/binary semantic blocking, and `resource-index` JSON propagation.
- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t98y-build --filter 'MapEditorStoreTests/testNDSSourceProjectStaysReadOnlyInProjectAndResourceSummaries'`
  - Completed, but SwiftPM discovered 0 matching app-hosted tests.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T98Y-DPMapInventory -destination 'platform=macOS,arch=arm64' -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testNDSSourceProjectStaysReadOnlyInProjectAndResourceSummaries test`
  - Blocked before test execution by unrelated concurrent compile error in `PokemonHackStudio/Sources/PokemonHackStudio/Views/Editors/PokemonSpeciesWorkbenchView.swift:681`: optional chaining on non-optional `SourceSpan`.
- `make validate-nds`
  - Passed.
  - 96 selected NDS tests, 0 failures, including `PokemonHackCLITests/testNDSDataCatalogCommandEmitsDiamondPearlMapInventoryJSON`.
  - Central NDS reference smokes skipped because `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky` were not found under `/Users/bryan/projects/reference-repos/repos`.

## Write Posture

Diamond/Pearl map header, map matrix, map table, land data, and area data rows remain metadata-only inventory records. Semantic editing, raw C-anchor writes, map editors, compilers, generated/reference writes, NARC/container rebuilds, ROM rebuild/export/write paths, and binary writes remain blocked/read-only.
