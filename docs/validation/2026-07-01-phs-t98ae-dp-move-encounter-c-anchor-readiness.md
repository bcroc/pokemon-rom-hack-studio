# PHS-T98AE DP Move/Encounter C-Anchor Readiness Facts

## Scope

PHS-T98AE adds read-only Diamond/Pearl readiness facts for exactly two catalog rows:

- `moves:arm9/src/waza.c`
- `encounters:arm9/src/encounter.c`

Each row now reports exact `Gen IV Source Role`, `Gen IV Source Provenance`, `futureRowBlocked` readiness, `Gen IV Future Row = PHS-T98`, explicit blocked actions, blocked readiness summaries, and warning diagnostics. The facts propagate through `nds-data-catalog`, `resource-index`, and Resources asset rows.

## Write Posture

This slice does not add semantic fields, parsers, planner lowering, write behavior, C-anchor writers, NDS edit-plan paths, UI editor controls, NARC/container work, generated/reference writes, ROM rebuild/export, or binary writes. The rows remain conservative raw C-source records with semantic snapshots blocked.

## Proof

- Earlier live-checkout focused attempt, `swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests/testDiamondCatalogKeepsCSourceAnchorsConservative|PokemonHackCLITests/testNDSDataCatalogCommandEmitsDiamondPearlMapInventoryJSON'`: blocked before selected tests ran by unrelated dirty `PokemonHackStudio/Sources/PokemonHackCore/PokemonItemCatalog.swift:717` guard fallthrough; SwiftPM also reported `PokemonHackStudio/Sources/PokemonHackCore/PokemonMoveCatalog.swift` was modified during the build.
- `swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests/testDiamondCatalogKeepsCSourceAnchorsConservative|PokemonHackCLITests/testNDSDataCatalogCommandEmitsDiamondPearlMapInventoryJSON'` in clean proof worktree `/tmp/pokemonhack-phs-t98ae-proof` with the NDS/CLI patch applied: passed, 2 selected tests and 0 failures.
- The earlier adjacent Gen V directory/message-bank fixture expectation drift is resolved in the live checkout. `make validate-nds` passed with 103 selected tests and 0 failures; central clean-room reference smokes were skipped because `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky` were not present under `/Users/bryan/projects/reference-repos/repos`.
- `git diff --check`: passed after docs/proof reconciliation.
