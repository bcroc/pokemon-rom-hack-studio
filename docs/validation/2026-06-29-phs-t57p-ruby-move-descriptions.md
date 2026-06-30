# PHS-T57P Ruby/Sapphire Move Description Text Editing

## Scope

- Ruby/Sapphire local `src/data/battle_moves.c` `gMoveDescription_*` declarations referenced by existing `gBattleMoves` rows now flow through the existing Moves draft, mutation preview, explicit apply, backup, and reload path.
- Move constants/identity changes, contest data, TM/HM/tutor compatibility, generated/reference rows, ROM writes, binary writes, and broad schema rewrites remain blocked/read-only.

## Proof

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/PokemonHackStudio-PHS-T57P-move-tests-final --jobs 1 --filter 'PokemonMoveCatalogTests/testRubySapphireMoveRowsPlanApplyBackupReloadAndKeepAdjacentScopesBlocked|PokemonMoveCatalogTests/testRubySapphireMoveDescriptionTextBlocksMissingDeclaration'` (passed on 2026-06-29 19:11:06 America/Vancouver after a complete debug build; 2 selected tests, 0 failures; covers Ruby/Sapphire move row apply/backup/reload with adjacent scope blockers and missing description declaration blocking)
- `git diff --check` (passed with no output after docs/proof-ledger reconciliation)
