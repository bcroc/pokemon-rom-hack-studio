# PHS-T78AC Expansion Item Behavior Missing-Field Insertion

## Scope

`PHS-T78AC` is the Expansion `gItemsInfo` behavior/function missing-field insertion row. The requested row ID was `PHS-T78AB`, but the live planning doc already records `PHS-T78AB` for the all-learnables regeneration-plan row.

- Local `.pokeemeraldExpansion` `src/data/items.h` rows may insert `.fieldUseFunc`, `.battleUsage`, `.battleUseFunc`, and `.secondaryId` only as one complete group.
- The group is allowed only when all four fields are absent, all four draft values are non-empty simple values, and existing `.effect` plus `.iconPic` anchors are present.
- Rendering inserts immediately after `.effect`, uses the `.effect` indentation, and preserves canonical order: `.fieldUseFunc`, `.battleUsage`, `.battleUseFunc`, `.secondaryId`.
- `references/pokeemerald-expansion` remains a broken environment alias only; this row did not repair, clone, or write references.

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/PokemonItemCatalog.swift`
- `PokemonHackStudio/Sources/PokemonHackCore/PokemonDataCompatibility.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonItemCatalogTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonDataCompatibilityTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `PokemonHackStudio/Tests/PokemonHackStudioTests/MapEditorStoreTests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/2026-07-01-phs-t78ac-expansion-item-behavior-missing-field-insertion.md`

Several changed files already contained unrelated dirty edits in the live checkout; those edits were preserved.

## Proof

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t78ab-item-behavior-insertion --jobs 1 --filter 'PokemonItemCatalogTests|PokemonDataCompatibilityTests|PokemonHackCLITests/testItemCatalogCommandEmitsEditableJSON|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsExpansionItemBehaviorScalarsEditableJSON'`
  - Passed; 35 selected tests, 0 failures.
  - Covers full behavior-group insertion, deterministic order/indent, apply/backups/reload/hash drift, missing-anchor blocking, partial insertion blocking, removal blocking, non-simple value blocking, compatibility JSON, and CLI JSON.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHST78AB-ItemBehaviorInsertion -destination 'platform=macOS,arch=arm64' -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testExpansionItemMissingBehaviorScalarsInsertThroughItemsEditor test`
  - Passed; app-hosted Items store staged, previewed, applied, backed up, and reloaded the full missing behavior/function scalar group.
  - Existing `allowedFileTypes`, ad-hoc signing, and bundle-script warnings only.
- `git diff --check`
  - Passed.

## Source-Write Posture

This row keeps local Expansion item writes limited to one complete behavior/function scalar insertion group in an existing `gItemsInfo` row. Source hash/size applyability, ignored backups, explicit apply, reload, source order, comments, and unknown fields are preserved.

Partial insertion, field removal, non-simple values, constants-file edits or creation, row add/remove/reorder, generated outputs, Modern Emerald/reference writes, ROM/build/export paths, binary writes, and broad item schema rewrites remain blocked.
