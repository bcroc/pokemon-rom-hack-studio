# PHS-T78T Modern Emerald Reference Compatibility Facts

## Scope

- Expand Modern Emerald compatibility metadata under the existing Expansion report.
- Report additional `references/modern-emerald` species, move, item, learnset, constants, aggregate config, Pokemon graphics/icon, and item icon/palette paths as blocked `referenceOnly` source-table rows with `PHS-T78` future-row guidance.
- Reuse the existing compatibility JSON shape and `references/modern-emerald` routing.
- Keep Modern Emerald adapters/profiles, writers, source mutations, generated outputs, reference edits, ROM/build/export paths, binary writes, and broad schema rewrites disabled.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'PokemonDataCompatibilityTests|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsModernEmeraldMetadataJSON|PokemonHackCLITests/testPokemonCompatibilityCommandEmitsPreviewJSON'` was attempted, but blocked before the PHS-T78T assertions could run by unrelated live-tree compile drift in `PokemonHackStudio/Sources/PokemonHackCore/PokemonMoveCatalog.swift`, `PokemonHackStudio/Sources/PokemonHackCore/BinaryROMMutationDryRunManifest.swift`, and the dirty `PokemonHackStudio/Sources/PokemonHackCore/NDSDataEditing.swift`. Missing helper symbols included `simpleContestComboMoves`, `rubyContestScalarFieldState`, `isMoveConstantSymbol`, `renderContestComboMoves`, `binaryROMMutationReviewToken`, and `parsePlatinumEncounterJSONFields`.
- `make test` was attempted, but blocked by unrelated live-tree compile drift before tests ran. Missing helper symbols included `binaryROMMutationReviewToken`, `rubyContestScalarFieldState`, `rubyContestScalarEdits`, and an inaccessible `normalizedMoveID`; SwiftPM also reported `PokemonMoveCatalog.swift` was modified during the build.
- `git diff --check` passed.
- Live reference smoke was not run because the central reference clone target behind `references/modern-emerald` is absent in this checkout, and this row does not require reading or editing reference files.

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/PokemonDataCompatibility.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonDataCompatibilityTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/README.md`
- `docs/validation/2026-07-01-phs-t78t-modern-emerald-reference-compatibility.md`

## Posture

This row is metadata-only. Compatibility JSON adds blocked `referenceOnly` Modern Emerald rows with `recommendedFutureRow: PHS-T78` for species, moves, items, level-up/TMHM/tutor/egg learnsets, constants, aggregate `include/config.h`, Pokemon graphics/icon paths, and item icon/palette paths. No Modern Emerald adapter/profile, writer, source mutation, generated output, reference edit, ROM/build/export path, binary write, or broad schema rewrite was added.
