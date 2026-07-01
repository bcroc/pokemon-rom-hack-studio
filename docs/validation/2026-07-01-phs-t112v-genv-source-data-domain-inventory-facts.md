# PHS-T112V Gen V Source Data Domain Inventory Facts

## Scope

- Row ID: `PHS-T112V`. The accepted implementation plan named `PHS-T112U`, but the live planning doc already assigned `PHS-T112U` to Gen V related-row readiness, so this work uses the next unused `PHS-T112*` suffix.
- Adds preview-only Gen V inventory facts for optional source-shaped roots: `data/pokemon`, `data/moves`, `data/items`, `data/trainers`, `src/data/pokemon`, `src/data/moves`, `src/data/items`, and `src/data/trainers`.
- Clean-room fact basis is path, filename, extension, member count, byte count, and bounded sample paths only.
- No Gen V proprietary decoding, semantic controls, extraction, NARC packing, build/playtest execution, ROM export, mutation apply, source mutation, or binary writes are added.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests/testPokeBlackCatalogSurfacesGenVSourceDataDomainInventoryFacts|PokemonHackCLITests/testNDSDataCatalogCommandEmitsPokeBlackSourceDataDomainInventoryJSON'`
  - Passed after fixing a test-only duplicate-path lookup and waiting on an unrelated SwiftPM `.build` lock: 2 selected tests, 0 failures.
  - Proves NDS catalog facts, CLI JSON, `resource-index` rows, root and child facts, no migration facts, no text-bank preview facts, and no semantic fact labels.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T112V-App -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testGenVSourceDataDomainInventoryStaysPreviewOnlyInResourcesSelection test`
  - Passed, with only pre-existing deprecation/build-script warnings.
  - Proves Resources asset rows, read-only NDS data editor state, no retained draft, blocked preview/apply controls, and unchanged backing file contents after a draft attempt.
- `make validate-nds`
  - Passed after waiting on an unrelated SwiftPM `.build` lock: 109 selected tests, 0 failures.
- `git diff --check`
  - Passed.

## Reference Roots

- Central-reference roots are not required for the synthetic focused tests.
- `make validate-nds` skipped optional central clean-room reference smokes because these roots were absent under `/Users/bryan/projects/reference-repos/repos`: `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky`.
