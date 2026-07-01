# PHS-T78U Expansion Move Contest Combo Moves

## Summary

`PHS-T78U` implements a narrow editor for existing local Expansion `src/data/moves_info.h` `gMovesInfo` `.contestComboMoves` fields when the existing source value is a simple brace-delimited `MOVE_*` list. The row was requested as `PHS-T78T`, but the live planning board already records `PHS-T78T` for Modern Emerald reference compatibility facts, so this implementation is documented as the next free `PHS-T78*` row.

The implementation preserves ordered combo entries in `MoveEditDraft.contestComboMoves`, validates submitted tokens against `include/constants/moves.h`, renders only the existing field value, and keeps preview/apply/backups/reload on `MoveMutationPlanner`. The Moves workbench exposes a narrow comma-separated field only for editable existing combo arrays.

## Proof

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t78t-swiftpm --filter 'PokemonMoveCatalogTests|PokemonDataCompatibilityTests|PokemonHackCLITests'` passed with 109 selected tests and 0 failures.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T78U-Combo -destination 'platform=macOS,arch=arm64' -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testExpansionMoveContestComboMovesDraftPreviewApplyAndReloadsThroughMovesEditor test` passed.
- `make test` passed with 466 tests and 0 failures.
- `make validate` passed; the optional pokeruby reference CLI smoke was skipped because `references/pokeruby` is absent.
- `make verify` passed; existing macOS `allowedFileTypes` deprecation, ad-hoc signing, and run-script notes only.
- `git diff --check` passed.

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/PokemonMoveCatalog.swift`
- `PokemonHackStudio/Sources/PokemonHackCore/PokemonDataCompatibility.swift`
- `PokemonHackStudio/Sources/PokemonHackStudio/Views/Editors/PokemonMovesWorkbenchView.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonMoveCatalogTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonDataCompatibilityTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `PokemonHackStudio/Tests/PokemonHackStudioTests/MapEditorStoreTests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/README.md`
- `docs/validation/2026-07-01-phs-t78u-expansion-move-contest-combo-moves.md`

## Boundaries

No generated output writes, reference writes, ROM/build/export paths, binary writes, row insertion/removal/reorder, missing-field insertion, or constant creation were added. Non-simple combo arrays, invalid tokens, unknown move constants, unreadable/missing constants, and non-Expansion sources remain blocked.
