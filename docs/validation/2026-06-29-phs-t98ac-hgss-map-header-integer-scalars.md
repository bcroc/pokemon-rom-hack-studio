# PHS-T98AC HGSS Map Header Integer Scalars

Date: 2026-06-29

## Scope

- Added HeartGold/SoulSilver semantic editing for `maps:src/data/map_headers.h` only when the catalog row is `.pokeheartgold`, `.maps`, `.cHeader`, and the source contains `static const MapHeader sMapHeaders[]`.
- Exposes existing C integer literal assignments in direct designated rows as `mapHeaders.<MAP_CONSTANT>.<fieldName>`.
- Keeps `files/fielddata/mapmatrix` and `files/fielddata/maptable` inventory-only and preserves blocked neighbors.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests/testNDSDataSemanticEditorPlansHeartGoldSoulSilverMapHeaderCIntegerScalars|PokemonHackCLITests/testNDSDataSemanticCommandsPlanAndApplyHeartGoldSoulSilverMapHeaderCIntegerScalars'` passed with 2 selected tests and 0 failures.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T98AA-HGSSMapHeader -destination 'platform=macOS,arch=arm64' -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testHeartGoldSoulSilverMapHeaderSemanticFieldEditsFlowThroughResourceEditor test` passed; existing `allowedFileTypes`, ad-hoc signing, and build-script warnings only.
- `make validate-nds` passed with 103 selected tests and 0 failures. Central reference smokes skipped absent `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky` roots under `/Users/bryan/projects/reference-repos/repos`.
- `git diff --check` passed after docs/proof reconciliation.

## Write Posture

This row only replaces existing C integer literal tokens through the existing NDS mutation-plan preview/apply path with backups. Identifiers/macros/booleans such as `TRUE` and `MAP_TYPE_ROUTE`, complex expressions, missing fields, duplicate edits, non-designated rows, row insertion/removal/reorder, nested map directories, scripts, generated/reference rows, NARC/container rebuilds, ROM rebuild/export, binary writes, and local ROM/reference/generated/DerivedData asset writes remain blocked.
