# PHS-T78X Expansion Item Bag Classification Scalars

## Scope

`PHS-T78X` opens the next Expansion `gItemsInfo` item scalar row after `PHS-T78W` item behavior scalar editing.

This row covers existing local Expansion item fields in `src/data/items.h`:

- `.importance`
- `.registrability`
- `.sortType`
- `.exitsBagOnUse`

The fields surface through item catalog/API JSON, item facts/search, and the Items workbench edit grid. Values validate as simple C identifiers or integer literals before preview/apply through the existing item mutation-plan gate.

## Original Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/PokemonItemCatalog.swift`
- `PokemonHackStudio/Sources/PokemonHackCore/PokemonDataCompatibility.swift`
- `PokemonHackStudio/Sources/PokemonHackCore/SourceIndex.swift`
- `PokemonHackStudio/Sources/PokemonHackStudio/Stores/WorkbenchStore.swift`
- `PokemonHackStudio/Sources/PokemonHackStudio/Views/Editors/PokemonItemsWorkbenchView.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonItemCatalogTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonDataCompatibilityTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `PokemonHackStudio/Tests/PokemonHackStudioTests/MapEditorStoreTests.swift`
- `docs/planning-and-progress.md`

## Proof

- `swift test --package-path PokemonHackStudio --filter 'PokemonItemCatalogTests|PokemonDataCompatibilityTests|PokemonHackCLITests'`: passed, 117 selected tests and 0 failures. Covered item parse, draft, preview, apply, backup, reload, source-drift blocking, non-simple value rejection, missing-field insertion blocking, removal blocking, compatibility source-table JSON, CLI JSON, and unchanged blocker rows.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHST78X-ItemBagMetadata -destination 'platform=macOS,arch=arm64' -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testExpansionItemBagClassificationEditsFlowThroughItemsEditor test`: passed. The app-hosted Items editor staged, previewed, applied, backed up, and reloaded an existing Expansion bag/classification scalar edit; existing `allowedFileTypes`, ad-hoc signing, and build-script warnings only.
- `git diff --check`: passed.

## Source-Write Posture

Bag/classification scalar edits are limited to existing local Expansion `src/data/items.h` `gItemsInfo` `.importance`, `.registrability`, `.sortType`, and `.exitsBagOnUse` fields. Values must be single C identifiers or integer literals and still require explicit item mutation preview/apply with source hash/size checks, backups, and reload. Missing-field insertion, removal, non-simple expressions, constants-file edits/creation, row insertion/removal/reorder, generated outputs, reference rows, Modern Emerald writes, ROM/build/export paths, binary writes, and broad item schema rewrites remain blocked.
