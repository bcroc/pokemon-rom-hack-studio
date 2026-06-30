# PHS-T98AB Diamond/Pearl Map Header C Scalars

Date: 2026-06-29

## Scope

- Row ID reconciliation: the requested plan named `PHS-T98AA`, but the live worktree already contains `PHS-T98AA` for Platinum map inventory metadata, so this Diamond/Pearl map-header scalar slice uses the next unused suffix, `PHS-T98AB`.
- Expose only Diamond/Pearl `maps:arm9/src/map_header.c` `sMapHeaders[]` existing integer-literal `struct MapHeader` positions through `NDSDataSemanticEditor` as `mapHeaders.<rowIndex>.<fieldName>`.
- Use the existing C scalar token-replacement path and source-backed NDS mutation-plan/apply gate shared by the prior Diamond/Pearl item mapping and trainer class gender rows.
- Update Diamond/Pearl map-header catalog facts so `arm9/src/map_header.c` reports semantic integer scalar readiness while map matrix/table/land/area rows remain inventory-only.
- Add CLI validation coverage to `script/validate_nds.sh`.

## Proof

- `swift test --package-path PokemonHackStudio --filter NDSDataCatalogTests` passed on 2026-06-29 19:34 America/Vancouver with 53 selected tests and 0 failures.
- `swift test --package-path PokemonHackStudio --filter PokemonHackCLITests/testNDSDataSemanticCommandsPlanAndApplyDiamondPearlMapHeaderCScalars` passed on 2026-06-29 19:34 America/Vancouver with 1 selected test and 0 failures.
- `make validate-nds` passed on 2026-06-29 19:35 America/Vancouver with 103 selected tests and 0 failures. Central reference smokes skipped absent `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky` roots under `/Users/bryan/projects/reference-repos/repos`.
- `git diff --check` passed after docs/proof reconciliation.

## Live Checkout Notes

- Unrelated dirty Swift/app/docs edits were present while this row was in flight and were preserved.
- Early focused CLI proof hit SwiftPM source-timestamp churn on `PokemonHackStudio/Sources/PokemonHackCore/NDSDataEditing.swift`.
- A later build surfaced an unrelated missing `return` in the current shared `NDSDataCatalog.swift`; after fixing that compile blocker and waiting for the source timestamps to settle, the requested focused and NDS validation commands passed.

## Write Posture

This row only replaces existing integer-literal tokens in Diamond/Pearl `sMapHeaders[]`. Constants, macros, `TRUE`/`FALSE`, `ENCDATA(...)`, nested/compound expressions, bad-shape rows, row add/remove/reorder, map table/matrix/land/area rows, scripts, compilers, generated/reference rows, ROM/export/rebuild paths, and binary writes remain blocked/read-only.
