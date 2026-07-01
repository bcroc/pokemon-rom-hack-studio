# PHS-T57T Ruby/Sapphire Contest Move Facts

## Summary

- Adds optional read-only indexing for local Ruby/Sapphire `src/data/contest_moves.h` `gContestMoves` rows.
- Joins raw contest effect/category/combo starter/combo move metadata back to existing `gBattleMoves` move IDs in move catalog facts/JSON and compatibility source-table JSON.
- Does not add contest writers, combo array editing, constants, row insertion/removal/reorder, generated/reference writes, ROM writes, binary writes, or broad contest rewrites.

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/SourceIndex.swift`
- `PokemonHackStudio/Sources/PokemonHackCore/PokemonMoveCatalog.swift`
- `PokemonHackStudio/Sources/PokemonHackCore/PokemonDataCompatibility.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonMoveCatalogTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonDataCompatibilityTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/README.md`
- `docs/validation/2026-07-01-phs-t57t-ruby-contest-move-facts.md`

## Validation

- `swift test --package-path PokemonHackStudio --filter 'PokemonMoveCatalogTests|PokemonDataCompatibilityTests|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsRubySapphireMovesEditableJSON'` (passed; 27 selected tests, 0 failures)
- `git diff --check` (passed)

## Notes

- The first exact SwiftPM attempt found an active `.build` lock and was stopped before compiling.
- An isolated scratch-path retry was blocked by SwiftPM's source timestamp guard while adjacent work modified `PokemonDataCompatibilityTests.swift`.
- The exact requested command was rerun after file mtimes stabilized and passed.
