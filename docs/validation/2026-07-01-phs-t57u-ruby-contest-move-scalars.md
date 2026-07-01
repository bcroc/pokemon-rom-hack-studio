# PHS-T57U Ruby/Sapphire Contest Move Scalar Editing

## Summary

- Opens `PHS-T57U` after the existing `PHS-T57T` read-only contest move facts row.
- Edits existing local Ruby/Sapphire `src/data/contest_moves.h` `gContestMoves` simple scalar fields `.effect`, `.contestCategory`, and `.comboStarterId` through the existing Moves draft, preview, explicit apply, backup, and reload path.
- Keeps `gContestMoves` `.effect` separate from `gBattleMoves` `.contestEffect` by using `MoveEditDraft.contestMoveEffect`.
- Keeps `.comboMoves` arrays facts-only/read-only and blocks constants, row insertion/removal/reorder, generated/reference writes, ROM writes, binary writes, and broad contest schema rewrites.

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
- `docs/validation/2026-07-01-phs-t57u-ruby-contest-move-scalars.md`

## Validation

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t57u-swiftpm --filter 'PokemonMoveCatalogTests/testRubySapphireContestMoveScalarsPlanApplyBackupReloadAndKeepComboArraysBlocked|PokemonDataCompatibilityTests|PokemonHackCLITests/testMoveCatalogCommandEmitsRubySapphireEditableJSON|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsRubySapphireMovesEditableJSON'` (passed; 15 selected tests, 0 failures)
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T57U-App -destination 'platform=macOS,arch=arm64' -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testRubySapphireContestMoveScalarsDraftPreviewApplyAndReloadsThroughStore test` (passed; existing `allowedFileTypes`, ad-hoc signing, bundle-script, and adjacent `PatchManifest.swift` warnings only)
- `make test` (passed; 466 SwiftPM tests, 0 failures)
- `git diff --check` (passed)

## Source-Write Posture

- Writable scope is limited to replacing existing simple scalar values for `.effect`, `.contestCategory`, and `.comboStarterId` in existing local Ruby/Sapphire `src/data/contest_moves.h` `gContestMoves` rows.
- Apply still runs through the existing Moves mutation-plan path with source hash/size checks, explicit apply, backup, and reload.
- Missing `contest_moves.h`, missing move rows, missing scalar fields, and non-simple scalar expressions emit blocking diagnostics instead of inserting or widening the schema.
- `.comboMoves` arrays, constants, row insertion/removal/reorder, generated/reference writes, ROM writes, binary writes, and broad Ruby/Sapphire contest schema rewrites remain blocked/read-only.
