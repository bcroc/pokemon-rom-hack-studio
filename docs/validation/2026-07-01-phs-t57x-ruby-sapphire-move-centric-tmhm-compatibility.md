# PHS-T57X Ruby/Sapphire Move-Centric TM/HM Compatibility

## Scope

`PHS-T57X` opens the next Ruby/Sapphire compatibility follow-up after `PHS-T57W` move identity facts.

This row covers existing local Ruby/Sapphire TM/HM learnset rows:

- `src/data/pokemon/tmhm_learnsets.h`
- `gTMHMLearnsets`

Those rows now report editable under the `moves` compatibility source tables and can be toggled from the Moves workbench. Edits continue to draft, preview, apply, back up, and reload only through the existing Species batch mutation-plan gate.

## Original Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/PokemonDataCompatibility.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonDataCompatibilityTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `PokemonHackStudio/Tests/PokemonHackStudioTests/MapEditorStoreTests.swift`
- `docs/planning-and-progress.md`

## Proof

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t57x-core-4 --jobs 1 --filter 'PokemonDataCompatibilityTests|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsRubySapphireMovesEditableJSON'`: passed, 13 selected tests and 0 failures. Covered Ruby/Sapphire `moves` compatibility source tables, editable existing `gTMHMLearnsets`, read-only move constants, and blocked tutor/generated/reference/ROM/binary rows.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T57X-RubyTMHM -destination 'platform=macOS,arch=arm64' -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testRubySapphireMoveCompatibilityTMHMBatchPreviewApplyAndReloadsThroughMovesStore test`: passed. The app-hosted Moves store stages, previews, applies, backs up, and reloads a Ruby/Sapphire `gTMHMLearnsets` compatibility toggle through the existing Species batch mutation-plan gate; existing build warnings only.
- `git diff --check`: passed.

## Superseded Attempts

Two earlier fresh-scratch SwiftPM attempts were blocked before tests by unrelated live-tree timestamp churn on `PokemonItemCatalog.swift`, then `MapVisual.swift`. A later fresh-scratch rerun passed after those unrelated edits settled. The first app-hosted rerun exposed the test fixture's missing Ruby/Sapphire TM/HM row before the corrected targeted rerun passed.

## Source-Write Posture

This row changes compatibility reporting and app proof only for existing local Ruby/Sapphire `src/data/pokemon/tmhm_learnsets.h` `gTMHMLearnsets` rows. Edits still flow through explicit Species batch preview/apply with source hash/size checks, backups, and reload. Tutor compatibility, TM/HM item mapping edits, machine constant creation, missing TM/HM row insertion, move identity/constants, row insertion/removal/reorder, generated/reference writes, ROM writes, and binary writes remain blocked/read-only.
