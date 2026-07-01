# PHS-T112X Gen V Source Data Audit Facts

## Scope

- Row ID: `PHS-T112X`. The live board had no active row and already recorded `PHS-T112W` as complete.
- Adds preview-only relationship/readiness audit facts for Gen V source-data root and member rows.
- Root rows report whether their existing related-row context is present and keep the `PHS-T112W` `relatedRecords`, `Related Rows`, `Related Domains`, and readiness behavior.
- Member rows report `memberRootContextOnly`, readiness status, and their owning root record while staying outside the broad `relatedRecords` cluster.
- No Gen V parser, decode, semantic control, raw-source write, extraction, NARC packing, build/playtest execution, ROM export, mutation apply, or binary write path is added.

## Proof

- `swiftc -parse PokemonHackStudio/Sources/PokemonHackCore/NDSDataCatalog.swift`
  - Passed.
- `swiftc -parse PokemonHackStudio/Tests/PokemonHackCoreTests/NDSDataCatalogTests.swift`
  - Passed.
- `swiftc -parse PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
  - Passed.
- `bash -n script/validate_nds.sh`
  - Passed.
  - Confirms the validation script syntax after adding the source-data inventory and related-row CLI tests to `make validate-nds`.
- `swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests/testPokeBlackCatalogSurfacesGenVSourceDataDomainInventoryFacts|NDSDataCatalogTests/testPokeBlackCatalogLinksGenVSourceDataDomainInventoryRelatedRows|PokemonHackCLITests/testNDSDataCatalogCommandEmitsPokeBlackSourceDataDomainInventoryJSON|PokemonHackCLITests/testNDSDataCatalogCommandLinksPokeBlackSourceDataDomainInventoryRelatedRowsJSON'`
  - Superseded by the current `make validate-nds` rerun below, which includes the selected NDS catalog and CLI assertions.
- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t112x-focused-swiftpm --filter 'NDSDataCatalogTests/testPokeBlackCatalogSurfacesGenVSourceDataDomainInventoryFacts|NDSDataCatalogTests/testPokeBlackCatalogLinksGenVSourceDataDomainInventoryRelatedRows|PokemonHackCLITests/testNDSDataCatalogCommandEmitsPokeBlackSourceDataDomainInventoryJSON|PokemonHackCLITests/testNDSDataCatalogCommandLinksPokeBlackSourceDataDomainInventoryRelatedRowsJSON'`
  - Superseded by the current `make validate-nds` rerun below; the prior compile blocker is stale.
- `make validate-nds`
  - Passed on current rerun with 111 selected tests and 0 failures, including the source-data inventory and related-row CLI assertions added to `script/validate_nds.sh`.
- `git diff --check`
  - Passed.

## Reference Roots

- Current `make validate-nds` skipped optional central-reference smokes because `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky` were absent under `/Users/bryan/projects/reference-repos/repos`.
