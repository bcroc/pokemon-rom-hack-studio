# PHS-T57W Ruby/Sapphire Move Identity Facts

## Summary

- Opens `PHS-T57W` after `PHS-T57V` as a facts-only Ruby/Sapphire compatibility/readiness row.
- Adds read-only `include/constants/moves.h` identity guidance to Ruby/Sapphire move catalog facts: matched/missing constant readiness plus existing constant value/source when present.
- Changes Ruby/Sapphire `pokemon-compatibility` move source-table JSON so `include/constants/moves.h` reports read-only `MOVE_*` count/readiness when present and blocked missing/unreadable readiness when absent.
- Reuses the existing move constants parser that already gates contest combo validation; no row writer, constant writer, source apply path, app UI, ROM write, binary write, generated output, or reference write was added.

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/PokemonMoveCatalog.swift`
- `PokemonHackStudio/Sources/PokemonHackCore/PokemonDataCompatibility.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonMoveCatalogTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonDataCompatibilityTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/README.md`
- `docs/validation/2026-07-01-phs-t57w-ruby-move-identity-facts.md`

## Validation

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t57w-catalog-compat-tests --jobs 1 --filter 'PokemonMoveCatalogTests/testRubySapphireContestMoveFactsJoinToBattleMoveRowsWhenPresent|PokemonDataCompatibilityTests'` (passed on rerun; 13 selected tests, 0 failures; covers matched/missing move identity facts, read-only/missing constants readiness, and unchanged compatibility surfaces)
- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t57w-cli-json-tests --jobs 1 --filter 'PokemonHackCLITests/testMoveCatalogCommandEmitsRubySapphireEditableJSON|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsRubySapphireMovesEditableJSON'` (passed; 2 selected tests, 0 failures; covers Ruby/Sapphire `move-catalog` and `pokemon-compatibility` JSON)

## Superseded Attempts

- The first fresh-scratch catalog/compatibility run was invalidated by SwiftPM's input-file modified guard on `PokemonDataCompatibility.swift`; the same command later passed from the same scratch path.
- An intermediate rerun exposed unrelated live dirty-tree churn in `PokemonItemCatalogTests.swift` before the selected PHS-T57W tests could run; no PHS-T57W source or writer behavior depended on that file.

## Source-Write Posture

- This row is metadata/readiness only. It indexes local Ruby/Sapphire move constants for identity facts and blocked guidance.
- Constant creation, constant rename, row insertion/removal/reorder, generated writes, reference writes, ROM writes, binary writes, table-family writer changes, and broader Ruby/Sapphire move schema rewrites remain blocked/read-only.
