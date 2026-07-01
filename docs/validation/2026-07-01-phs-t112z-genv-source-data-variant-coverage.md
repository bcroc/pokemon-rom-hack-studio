# PHS-T112Z Gen V Source Data Variant Coverage Rollups

## Scope

Preview-only Gen V source-data root rows now report fixed-marker variant coverage for `black.us`, `white.us`, `black2.us`, and `white2.us`. The facts use source marker presence plus root presence only; they do not parse source-data content, decode previews, add semantic controls, or enable source/container/build/export/apply/binary writes.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests/testPokeBlackCatalogSurfacesGenVSourceDataVariantCoverageRollups|PokemonHackCLITests/testNDSDataCatalogCommandEmitsPokeBlackSourceDataVariantCoverageJSON'` passed: 2 selected tests, 0 failures.
- `bash -n script/validate_nds.sh` passed.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T112Z-App -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testGenVSourceDataVariantCoverageStaysPreviewOnlyInResourcesSelection test` passed after clearing a stale `/tmp/PokemonHackStudio-PHS-T112Z-App` build database lock; only existing `allowedFileTypes`, ad-hoc signing, and bundle-script warnings were emitted.
- `make validate-nds` passed: 117 selected tests, 0 failures. Optional central reference smokes skipped because `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky` were not found under `/Users/bryan/projects/reference-repos/repos`.

## Notes

The live checkout already contained unrelated dirty work in adjacent code/docs, and more adjacent NDS/source edits appeared during validation. This closeout preserves those hunks and records only the `PHS-T112Z` source-data coverage slice.
