# PHS-T112AA Gen V Source Root Inventory Facts

## Scope

The live board had already assigned `PHS-T112Z` to Gen V source-data variant coverage during this closeout, so this source-root inventory slice is recorded as the next unused `PHS-T112*` row, `PHS-T112AA`.

This row adds bounded preview-only inventory facts for exact Gen V `src`, `asm`, and `include` root rows through the existing `genVDirectoryInventory` seam:

- `src`: `Gen V Source Root Members`, `Gen V Source Root Bytes`, `Gen V Source Root Sample Paths`
- `asm`: `Gen V Assembly Root Members`, `Gen V Assembly Root Bytes`, `Gen V Assembly Root Sample Paths`
- `include`: `Gen V Header Root Members`, `Gen V Header Root Bytes`, `Gen V Header Root Sample Paths`

Existing source role, blocked action, action state, readiness, no-migration, and no-text-preview posture is unchanged.

## Proof

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/PokemonHackStudio-PHS-T112Z-live-retry-swiftpm --jobs 1 --filter 'NDSDataCatalogTests/testPokeBlackCatalogSurfacesGenVReadinessFacts|PokemonHackCLITests/testNDSDataCatalogCommandEmitsPokeBlackReadinessJSON'` passed: 2 selected tests, 0 failures. The first live-checkout attempt without a scratch path was blocked before tests because unrelated `PokemonHackStudio/Sources/PokemonHackCore/SourceIndex.swift` changed during compilation.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T112Z-App -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testGenVManualOnlySourceRootsStayPreviewOnlyInResourcesSelection test` passed with existing macOS/Xcode warnings only.
- `make validate-nds` first blocked before tests because unrelated `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonMoveCatalogTests.swift` changed during compilation. A rerun executed 118 selected tests and failed only unrelated `NDSDataCatalogTests/testNDSDataItemCSVRowOperationPlanner` assertions for missing `NDS_DATA_ITEM_CSV_ROWS_PATH_BLOCKED` and `NDS_DATA_EDIT_ROLE_BLOCKED` diagnostics from another dirty item-CSV row-operation lane. The `PHS-T112AA` catalog and CLI readiness assertions passed inside that run.
- `git diff --check` passed.

## Write Posture

No C/ASM/header parser, semantic editor, raw source write, generated-output write, child expansion, extraction/decompression, NARC packing, build/playtest execution, ROM export, mutation apply, or binary write path was added.
