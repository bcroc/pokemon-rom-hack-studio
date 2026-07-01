# PHS-T112Y Gen V Source Data Blocked-Action Facts

## Scope

`PHS-T112Y` adds preview-only blocked-action facts to existing Gen V source-data root/member rows for `data/pokemon`, `data/moves`, `data/items`, `data/trainers`, and matching `src/data/...` roots.

The new facts are:

- `Gen V Source Data Blocked Actions = parser, decoded preview, semantic controls, source writes, extraction, NARC packing, build/playtest, ROM export, mutation apply, binary writes`
- `Gen V Source Data Blocked Reason = domainInventoryPreviewOnly` on root rows
- `Gen V Source Data Blocked Reason = memberMetadataPreviewOnly` on member rows

Member rows remain outside broad `relatedRecords` clusters and still expose no `Related Rows` fact.

## Proof

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/PokemonHackStudio-PHS-T112Y-proof-swiftpm --jobs 1 --filter 'NDSDataCatalogTests/testPokeBlackCatalogSurfacesGenVSourceDataDomainInventoryFacts|NDSDataCatalogTests/testPokeBlackCatalogLinksGenVSourceDataDomainInventoryRelatedRows|PokemonHackCLITests/testNDSDataCatalogCommandEmitsPokeBlackSourceDataDomainInventoryJSON|PokemonHackCLITests/testNDSDataCatalogCommandLinksPokeBlackSourceDataDomainInventoryRelatedRowsJSON'` in `/tmp/pokemonhack-phs-t112y-proof` passed: 4 selected tests, 0 failures.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T112Y-App -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testGenVSourceDataDomainInventoryStaysPreviewOnlyInResourcesSelection test` in `/tmp/pokemonhack-phs-t112y-proof` passed, with only existing macOS/Xcode warnings.
- `make validate-nds` in `/tmp/pokemonhack-phs-t112y-proof` passed: 113 selected tests, 0 failures. Optional central reference smokes skipped because `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky` were absent under `/Users/bryan/projects/reference-repos/repos`.
- `git diff --check` passed in `/Users/bryan/projects/pokemonhack`.

Live-checkout focused SwiftPM attempts were blocked by unrelated dirty file churn during compilation: first `PokemonDataCompatibility.swift`, then `PokemonItemCatalog.swift`. The stable proof snapshot was used to avoid moving inputs during SwiftPM builds.

## Write Posture

No Gen V parser, decoded preview, semantic control, source write, extraction, NARC packing, build/playtest execution, ROM export, mutation apply, or binary write path was added.
