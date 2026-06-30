# PHS-T78M Modern Emerald Compatibility Metadata

## Scope

- Add metadata-only Modern Emerald compatibility source-table rows for Expansion species, moves, and items.
- Report `references/modern-emerald` species, move, TM/HM, tutor, item, item-constant, and item-graphics paths as blocked `referenceOnly` rows with `PHS-T78` future-row guidance.
- Add unsupported diagnostics for Modern Emerald species, moves, and items.
- Keep Modern Emerald adapters/profiles, writers, generated outputs, reference edits, ROM/build/export paths, binary writes, and broad schema rewrites disabled.

## Proof

- Baseline before implementation: `git status --short --branch` (clean on `main...origin/main`).
- Baseline before implementation: `swift test --package-path PokemonHackStudio --filter PokemonDataCompatibilityTests` (passed; 10 selected tests, 0 failures).
- Baseline before implementation: `swift test --package-path PokemonHackStudio --filter PokemonHackCLITests/testPokemonCompatibilityCommandEmitsPreviewJSON` (passed; 1 selected CLI JSON test, 0 failures).
- Baseline before implementation: `git diff --check` (passed).
- Initial post-edit proof attempts were interrupted by concurrent live-tree edits: `swift test --package-path PokemonHackStudio --filter PokemonDataCompatibilityTests` first saw `PokemonHackStudio/Sources/PokemonHackCore/NDSDataEditing.swift` missing `parseDiamondPearlMapHeaderFields`, and a parallel CLI filter hit SwiftPM `input file ... was modified during the build` noise.
- Serial retry after that helper appeared: `swift test --package-path PokemonHackStudio --filter PokemonDataCompatibilityTests` (blocked before PHS-T78M tests could execute by unrelated live-tree compile drift in `PokemonHackStudio/Sources/PokemonHackCore/NDSDataCatalog.swift`: `missing return in static method expected to return '[Diagnostic]'` at line 1742).
- Serial CLI retry: `swift test --package-path PokemonHackStudio --filter 'PokemonHackCLITests/testPokemonCompatibilityCommandEmitsModernEmeraldMetadataJSON|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsPreviewJSON'` (blocked by the same unrelated `NDSDataCatalog.swift` compile error before CLI assertions could execute).
- `git diff --check` (passed after PHS-T78M code/test/docs edits; unrelated local dirty files remain present in the checkout).

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/PokemonDataCompatibility.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonDataCompatibilityTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/2026-06-29-phs-t78m-modern-emerald-compatibility-metadata.md`

## Posture

Modern Emerald remains reference-only schema pressure under the existing Expansion compatibility report. No new `GameProfile`, adapter, source-index scanner, mutation planner, writer, generated-output path, reference edit, ROM/build/export path, binary write, or broad schema rewrite was added.
