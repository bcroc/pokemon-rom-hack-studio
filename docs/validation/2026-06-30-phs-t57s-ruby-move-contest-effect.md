# PHS-T57S Ruby/Sapphire Move Contest Effect Editing

## Scope

- Ruby/Sapphire local `src/data/battle_moves.c` existing `gBattleMoves` `.contestEffect` fields now parse simple C symbols, appear in move catalog JSON, flow through `MoveEditDraft`, preview, explicit apply, backup, and reload.
- Row ID note: the requested plan named `PHS-T57R`, but the live worktree now records `PHS-T57R` for Ruby/Sapphire tutor learnset editing, so this contest-effect row is recorded as `PHS-T57S` to keep row IDs unique.
- Move constants, descriptions beyond existing support, TM/HM/tutor compatibility, generated/reference rows, ROM writes, binary writes, field insertion, row insertion/removal/reorder, other contest data, non-simple contest expressions, and broad move rewrites remain blocked/read-only.

## Proof

- Clean proof worktree: `/Users/bryan/projects/pokemonhack-phs-t57r-clean` from `HEAD`, used to isolate this patch from unrelated dirty main-checkout NDS, Species, Modern Emerald, all-learnables, validation-command, and tutor-learnset edits.
- `swift test --package-path PokemonHackStudio --filter 'PokemonMoveCatalogTests|PokemonDataCompatibilityTests'` (passed on 2026-06-29 19:41:37 America/Vancouver; 22 selected tests, 0 failures)
- `swift test --package-path PokemonHackStudio --filter 'PokemonHackCLITests/testMoveCatalogCommandEmitsRubySapphireEditableJSON|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsRubySapphireMovesEditableJSON'` (passed on 2026-06-29 19:41:43 America/Vancouver; 2 selected CLI JSON tests, 0 failures)
- `git diff --check` (passed in the clean proof worktree)
- Main checkout rerun: `swift test --package-path PokemonHackStudio --filter 'PokemonMoveCatalogTests|PokemonDataCompatibilityTests'` (passed on 2026-06-29 19:44:44 America/Vancouver; 23 selected tests, 0 failures)
- Main checkout rerun: `swift test --package-path PokemonHackStudio --filter 'PokemonHackCLITests/testMoveCatalogCommandEmitsRubySapphireEditableJSON|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsRubySapphireMovesEditableJSON'` (passed on 2026-06-29 19:44:55 America/Vancouver; 2 selected CLI JSON tests, 0 failures)
- Main checkout rerun: `git diff --check` (passed)
