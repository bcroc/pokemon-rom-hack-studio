# PHS-T112W Gen V Source Data Related-Row Readiness

## Scope

- Row ID: `PHS-T112W`. This was the next unused `PHS-T112*` row after the live `PHS-T112V` closeout.
- Links only the eight Gen V source data-domain root inventory rows into the existing Gen V preview context: `data/pokemon`, `data/moves`, `data/items`, `data/trainers`, `src/data/pokemon`, `src/data/moves`, `src/data/items`, and `src/data/trainers`.
- The eight root rows now propagate existing `relatedRecords`, `Related Rows`, `Related Domains`, and readiness facts through NDS catalog JSON, `resource-index`, and app Resources selection.
- Child source-data member rows remain present, read-only, and outside the root relationship cluster while preserving their existing `*DataMember` source-role and source-data facts.
- No Gen V parsers, decoded previews, semantic controls, raw-source writes, extraction, NARC packing, build/playtest execution, ROM export, mutation apply, or binary writes are added.

## Proof

- `swiftc -parse PokemonHackStudio/Sources/PokemonHackCore/NDSDataCatalog.swift`
  - Passed.
- `swiftc -parse PokemonHackStudio/Tests/PokemonHackCoreTests/NDSDataCatalogTests.swift`
  - Passed.
- `swiftc -parse PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
  - Passed.
- `swiftc -parse PokemonHackStudio/Tests/PokemonHackStudioTests/MapEditorStoreTests.swift`
  - Passed.
- `swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests/testPokeBlackCatalogLinksGenVSourceDataDomainInventoryRelatedRows|PokemonHackCLITests/testNDSDataCatalogCommandLinksPokeBlackSourceDataDomainInventoryRelatedRowsJSON'`
  - Passed: 2 selected tests, 0 failures.
  - Proves the expanded 21-record Gen V context, `Related Rows = 20`, all related domains, readiness propagation, CLI JSON, `resource-index` facts, and representative child source-data rows staying outside the root cluster.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T112W-App -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testGenVSourceDataDomainInventoryStaysPreviewOnlyInResourcesSelection test`
  - Passed after aligning the app fixture with the catalog/CLI Gen V message-candidate context, with only existing deprecation/build-script warnings and local passcode-protected device noise.
  - Proves representative root related-row/readiness facts, read-only NDS editor selection, refused draft retention, and unchanged backing files.
- `make validate-nds`
  - Current rerun on 2026-07-01 passed with 111 selected tests and 0 failures.
  - The stale Diamond/Pearl encounter semantic-test blocker is resolved; Diamond/Pearl encounter slot scalar proof is recorded separately under `PHS-T98AK`.
- `git diff --check`
  - Passed after docs/proof reconciliation.

## Reference Roots

- Central-reference roots are not required for the synthetic focused tests.
- The current `make validate-nds` rerun skipped optional central clean-room reference smokes because these roots were absent under `/Users/bryan/projects/reference-repos/repos`: `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky`.
