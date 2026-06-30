# PHS-T57P Ruby/Sapphire Move Description Text Editing

## Scope

- Ruby/Sapphire local `src/data/battle_moves.c` `gMoveDescription_*` declarations referenced by existing `gBattleMoves` rows now flow through the existing Moves draft, mutation preview, explicit apply, backup, and reload path.
- Move constants/identity changes, contest data, TM/HM/tutor compatibility, generated/reference rows, ROM writes, binary writes, and broad schema rewrites remain blocked/read-only.

## Proof

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/PokemonHackStudio-PHS-T57P-core-tests --filter 'PokemonMoveCatalogTests|PokemonDataCompatibilityTests'` (blocked before tests ran because concurrent checkout edits modified `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonSpeciesCatalogTests.swift` during the SwiftPM build)
- `swift test --package-path PokemonHackStudio --scratch-path /tmp/PokemonHackStudio-PHS-T57P-move-tests --jobs 1 --filter 'PokemonMoveCatalogTests/testRubySapphireMoveRowsPlanApplyBackupReloadAndKeepAdjacentScopesBlocked|PokemonMoveCatalogTests/testRubySapphireMoveDescriptionTextBlocksMissingDeclaration'` (blocked before tests ran because concurrent checkout edits modified `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift` during the SwiftPM build; changed PHS-T57P core files had compiled before the blocker)
- `swift build --package-path PokemonHackStudio --scratch-path /tmp/PokemonHackStudio-PHS-T57P-core-build --jobs 1 --target PokemonHackCore` (interrupted after several minutes of active `swift-frontend` compilation because unrelated concurrent SwiftPM jobs were still running and the build was not completing promptly)
