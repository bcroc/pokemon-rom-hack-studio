# PHS-T98AG Platinum Text Line Row Operations

## Scope

- Adds source-backed Platinum `res/text/**/*.txt` insert/delete/reorder line operation planning through `NDSDataTextLineOperationPlanner`.
- Adds redacted CLI plan/apply commands: `nds-data-text-lines-plan` and `nds-data-text-lines-apply`.
- Keeps BMG/message-bank files, JSON text rows, NARC/container rows, generated/reference rows, ROM rebuild/export, build/playtest execution, newline-containing inserts, invalid ranges, and binary paths blocked/read-only.

## Validation

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/PokemonHackStudio-PHS-T98AG-swiftpm --filter 'NDSDataCatalogTests/testNDSDataTextLineOperationPlanner|PokemonHackCLITests/testNDSDataTextLineOperationCommands'`
  - Passed.
  - 2 selected tests, 0 failures.
  - Covers safe insert/delete/reorder planning/apply/backups, redacted CLI plan output, ordered operation application, BMG/JSON/container/generated/reference blocks, newline insert refusal, and invalid range refusal.
  - Only unrelated `PatchManifest.swift` warnings appeared during compilation.
- `make validate-nds`
  - Current rerun on 2026-07-01 passed with 111 selected tests and 0 failures.
- `git diff --check`
  - Passed.

## Source-Write Posture

Safe line operations lower to the existing NDS source mutation plan with source hash/size checks, explicit apply, atomic writes, and backups under `.pokemonhackstudio/backups/`. Blocked plans contain no source changes and no applyable file changes.
