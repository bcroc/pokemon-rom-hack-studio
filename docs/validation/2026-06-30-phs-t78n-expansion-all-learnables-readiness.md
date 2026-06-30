# PHS-T78N Expansion All Learnables Readiness Facts

## Scope

- Row ID reconciliation: the requested plan named `PHS-T78M`, but the live worktree already contains `PHS-T78M` for Modern Emerald compatibility metadata, so this all-learnables readiness slice uses the next unused `PHS-T78N`.
- Treat `src/data/pokemon/all_learnables.json` as generated, read-only Expansion context that aggregates level-up, TM/HM, tutor, and egg learnset sources.
- Surface source-role, generated-from, readiness, and blocked-action facts through SourceIndex/app Resources, compatibility JSON, and `pokemon-compatibility` CLI JSON.
- Keep learnset row insertion, generated output writes, reference writes, ROM/build/export writes, binary writes, constants, and wider Species mutation paths disabled.

## Proof

- Baseline command requested by the user: `git status --short --branch` began clean on `main...origin/main`; concurrent live-tree edits appeared while this row was in progress and were preserved.
- `swift test --package-path PokemonHackStudio --filter 'PokemonDataCompatibilityTests|GenIIIAssetCatalogTests|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsPreviewJSON|PokemonHackCLITests/testPokemonCompatibilityAndAssetIndexCommandsEmitExpansionAllLearnablesFacts'` (passed; 20 selected tests, 0 failures).
- `swift test --package-path PokemonHackStudio --filter 'PokemonDataCompatibilityTests|PokemonSpeciesCatalogTests|GenIIIAssetCatalogTests|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsPreviewJSON|PokemonHackCLITests/testPokemonCompatibilityAndAssetIndexCommandsEmitExpansionAllLearnablesFacts'` (blocked by unrelated live-tree `PokemonSpeciesCatalogTests` failures in the dirty checkout after the compatibility, asset catalog, and CLI all-learnables tests passed).
- `make validate-synthetic` (blocked; scripts and build-tool checks passed and SwiftPM built, then unrelated live-tree NDS/Species tests failed, including HGSS zone-event semantic assertions, Gen V NitroFS root inventory count assertions, and Species mutation/tutor expectations).
- `git diff --check` (passed).

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/SourceIndex.swift`
- `PokemonHackStudio/Sources/PokemonHackCore/PokemonDataCompatibility.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonDataCompatibilityTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/README.md`
- `docs/validation/2026-06-30-phs-t78n-expansion-all-learnables-readiness.md`

## Posture

`src/data/pokemon/all_learnables.json` remains generated, read-only context. It now reports `generatedAllLearnablesIndex`, `level-up, TM/HM, tutor, egg learnsets`, `read-only generated context`, and blocked actions for apply, generated output writes, reference writes, and ROM/binary writes. No learnset rows, generated files, references, ROMs, binaries, constants, or broader Species mutation paths were added or written.
