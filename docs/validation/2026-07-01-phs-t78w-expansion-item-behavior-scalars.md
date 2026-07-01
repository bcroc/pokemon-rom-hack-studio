# PHS-T78W Expansion Item Behavior Scalars

## Scope

`PHS-T78W` opens one narrow Expansion `gItemsInfo` descriptor family: existing local `src/data/items.h` `.fieldUseFunc`, `.battleUsage`, `.battleUseFunc`, and `.secondaryId` fields.

- Function fields accept a single C identifier or `NULL`.
- Battle usage and secondary ID fields accept a single C identifier or integer literal.
- The existing item draft, mutation preview, source hash/size applyability, backup, apply, and reload path is reused.

## Proof

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t78w-item-behavior --filter 'PokemonItemCatalogTests|PokemonDataCompatibilityTests'` passed with 27 selected tests and 0 failures.
- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t78w-cli --filter 'PokemonHackCLITests/testItemCatalogCommandEmitsEditableJSON|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsExpansionItemBehaviorScalarsEditableJSON'` passed with 2 selected tests and 0 failures.
- App-hosted proof was not run because no SwiftUI, app store, or Xcode project files changed.
- `git diff --check` passed.

## Source-Write Posture

Behavior scalar edits are limited to existing local Expansion `src/data/items.h` `gItemsInfo` fields. Missing-field insertion, removal, non-simple expressions, constants-file edits or creation, row insertion/removal/reorder, generated outputs, reference rows, ROM/build/export paths, binary writes, and broad item schema rewrites remain blocked.
