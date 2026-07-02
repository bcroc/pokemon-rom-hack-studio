# PHS-T78AD Expansion Item Usage Missing-Field Insertion

## Scope

`PHS-T78AD` is the Expansion `gItemsInfo` usage/classification missing-field insertion row after `PHS-T78AC`.

- Local `.pokeemeraldExpansion` `src/data/items.h` rows may insert `.holdEffect`, `.holdEffectParam`, `.pocket`, and `.type` only as one complete group.
- The group is allowed only when all four fields are absent, all four draft values are non-empty simple values, and split anchors `.price`, `.description`, and `.sortType` are present.
- Rendering inserts `.holdEffect` and `.holdEffectParam` after `.price`, `.pocket` after `.description`, and `.type` after `.sortType` to preserve surrounding field order.
- Partial insertion, removal, non-simple values, constants edits or creation, row add/remove/reorder, generated outputs, Modern Emerald/reference writes, ROM/build/export paths, binary writes, and broad item schema rewrites remain blocked.

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/PokemonItemCatalog.swift`
- `PokemonHackStudio/Sources/PokemonHackCore/PokemonDataCompatibility.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonItemCatalogTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonDataCompatibilityTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `PokemonHackStudio/Tests/PokemonHackStudioTests/MapEditorStoreTests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/README.md`
- `docs/validation/2026-07-02-phs-t78ad-expansion-item-usage-missing-field-insertion.md`

The live checkout already had unrelated dirty work before this row, and additional unrelated NDS, patch distribution, ROM mutation, app, and docs edits appeared during validation. Those edits were preserved.

## Proof

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t78ad-item-usage-insertion --jobs 1 --filter 'PokemonItemCatalogTests|PokemonDataCompatibilityTests|PokemonHackCLITests/testItemCatalogCommandEmitsEditableJSON|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsExpansionItemUsageScalarsEditableJSON'`
  - Passed; 36 selected tests, 0 failures.
  - Covers existing usage scalar editing, full split-anchor missing-group insertion, apply/backups/reload/hash drift, missing-anchor blocking, partial insertion blocking, removal blocking, non-simple current/draft blocking, compatibility JSON, and CLI JSON.
- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t78ad-core-compat --jobs 1 --filter 'PokemonItemCatalogTests|PokemonDataCompatibilityTests'`
  - Passed; 34 selected tests, 0 failures.
  - This rerun followed an initial fixture assertion fix and covers the core/catalog plus compatibility surfaces without the dirty CLI target.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHST78AD-ItemUsageInsertion -destination 'platform=macOS,arch=arm64' -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testExpansionItemMissingUsageScalarsInsertThroughItemsEditor test`
  - Blocked before the selected test by unrelated active app dirty work: `PokemonHackStudio/Sources/PokemonHackStudio/Stores/WorkbenchStore.swift:4533:61` reported `type 'Self' has no member 'patchDistributionReadinessReportViewState'`.
  - Existing `allowedFileTypes` deprecation warnings were also emitted before the compile failure.
- `git diff --check`
  - Passed.
- `./script/check_validation_docs.sh`
  - Passed.

## Source-Write Posture

This row keeps local Expansion item writes limited to one complete usage/classification scalar insertion group in an existing `gItemsInfo` row. Source hash/size applyability, ignored backups, explicit apply, reload, source order, comments, and unknown fields are preserved.

Partial insertion, field removal, non-simple values, constants-file edits or creation, row add/remove/reorder, generated outputs, Modern Emerald/reference writes, ROM/build/export paths, binary writes, and broad item schema rewrites remain blocked.
