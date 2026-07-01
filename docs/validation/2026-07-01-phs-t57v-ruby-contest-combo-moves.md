# PHS-T57V Ruby/Sapphire Contest Combo Moves

## Summary

- Opens `PHS-T57V` after the existing `PHS-T57U` Ruby/Sapphire contest scalar row.
- Edits existing local Ruby/Sapphire `src/data/contest_moves.h` `gContestMoves` `.comboMoves` fields only when the current field is a simple brace-delimited `COMBO_STARTER_*` list.
- Preserves ordered combo entries in `MoveEditDraft.contestComboMoves`, validates each edited token against local `include/constants/moves.h` by resolving it to a `MOVE_*` constant, and renders only the existing `.comboMoves` field value through `MoveMutationPlanner`.
- Keeps `PHS-T57U` `.effect`, `.contestCategory`, and `.comboStarterId` scalar behavior unchanged.

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/PokemonMoveCatalog.swift`
- `PokemonHackStudio/Sources/PokemonHackCore/PokemonDataCompatibility.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonMoveCatalogTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonDataCompatibilityTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `PokemonHackStudio/Tests/PokemonHackStudioTests/MapEditorStoreTests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/README.md`
- `docs/validation/2026-07-01-phs-t57v-ruby-contest-combo-moves.md`

## Validation

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t57v-move-tests-2 --jobs 1 --filter 'PokemonMoveCatalogTests/testRubySapphireContestMoveFactsJoinToBattleMoveRowsWhenPresent|PokemonMoveCatalogTests/testRubySapphireContestMoveScalarsAndComboMovesPlanApplyBackupReload'` (passed; 2 selected tests, 0 failures; covers draft initialization, ordered combo replacement, scalar preservation, blockers, source-drift refusal, backup, and reload)
- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t57v-compat-cli-tests-2 --jobs 1 --filter 'PokemonDataCompatibilityTests|PokemonHackCLITests/testMoveCatalogCommandEmitsRubySapphireEditableJSON|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsRubySapphireMovesEditableJSON'` (passed; 14 selected tests, 0 failures; covers compatibility/readiness JSON and Ruby/Sapphire move-catalog JSON)
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T57V-App-2 -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testRubySapphireContestMoveScalarsAndComboMovesDraftPreviewApplyAndReloadsThroughStore test` (passed; app-hosted Moves store stages, previews, applies, backs up, reloads, and preserves selected move for a Ruby/Sapphire contest scalar plus combo-array edit; existing passcode-protected device, `allowedFileTypes`, ad-hoc signing, and bundle-script warnings only)
- `make test` (passed; 472 SwiftPM tests, 0 failures)
- `git diff --check` (passed)
- Optional live-reference smoke skipped because local `references/pokeruby` is absent; tracked synthetic Ruby/Sapphire fixtures provide the proof without writing ignored reference roots.

## Superseded Attempts

- Early fresh-scratch SwiftPM attempts were blocked before row assertions when unrelated live-tree files were modified during the build (`NDSDataCatalogTests.swift`, then `NDSDataEditing.swift`).
- The first app-hosted rerun exposed a missing `MOVE_GROWL` definition in the shared Ruby app-test fixture; the fixture was corrected and the same selected app test passed from `/tmp/PokemonHackStudio-PHS-T57V-App-2`.

## Source-Write Posture

- Writable scope is limited to replacing an existing simple `.comboMoves` value in an existing local Ruby/Sapphire `src/data/contest_moves.h` `gContestMoves` row.
- Apply still runs through the existing Moves mutation-plan path with source hash/size checks, explicit apply, backup, and reload.
- Missing `contest_moves.h`, missing move rows, missing `.comboMoves`, non-simple arrays/macros, invalid `COMBO_STARTER_*` tokens, unknown `MOVE_*` constants, and missing/unreadable constants emit blocking diagnostics.
- Missing field insertion, constant creation, row insertion/removal/reorder, generated/reference writes, ROM writes, binary writes, and broad Ruby/Sapphire contest schema rewrites remain blocked/read-only.
