# PHS-T132 Map Render Audit

## Scope

`PHS-T132` records the map-render audit under the next free row ID because the live board already uses `PHS-T131` for Project File Save Menu Refactor. The audit is read-only: it loads discovered source-tree maps and texture inputs, reports unsupported or missing targets as skipped, and does not write source trees, generated images, ROMs, screenshots, exports, or `.pokemonhackstudio` artifacts.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'MapRenderAuditTests|PokemonHackCLITests/testMapRenderAudit'`
  - Passed: 15 selected tests, 0 failures.
- `swift run --package-path PokemonHackStudio pokemonhack-cli map-render-audit pokeemerald --json`
  - Passed: JSON captured at `/tmp/phs-t132-pokeemerald-audit.json`.
  - Summary: 518 audited maps, 18,994 texture checks, 0 failures.
- `swift run --package-path PokemonHackStudio pokemonhack-cli map-render-audit pokefirered --json`
  - Passed: JSON captured at `/tmp/phs-t132-pokefirered-audit.json`.
  - Summary: 425 audited maps, 15,475 texture checks, 0 failures.
- `swift run --package-path PokemonHackStudio pokemonhack-cli map-render-audit --all --json`
  - Passed: JSON captured at `/tmp/phs-t132-all-audit.json`.
  - Summary: 943 audited maps, 34,469 texture checks, 18 skipped non-renderable/missing targets, 0 failures.
- `make test`
  - Passed: 530 SwiftPM tests, 0 failures.
- `make validate`
  - Passed: SwiftPM suite plus CLI smoke ladder completed.
  - Existing absent `references/pokeruby` smoke was skipped.
- `make verify`
  - Passed: regenerated ignored Xcode project and built the macOS app.
  - Existing local signing, AppIntents metadata, and script-phase warnings only.
- `./script/check_validation_docs.sh`
  - Passed after adding the pre-existing `PHS-T78AC` validation file to `docs/validation/README.md`.
- `git diff --check`
  - Passed.

## Warning Buckets

- Emerald warning buckets: `MAP_EVENT_SPRITE_UNRESOLVED` 457, `MAP_SCRIPT_SOURCE_MISSING` 74, `MAP_SCENE_CONNECTION_TILESET_MISMATCH` 38, `MAP_RENDER_AUDIT_TILE_IMAGE_INDEX_OUT_OF_RANGE` 16, `MAP_SCENE_CONNECTION_DIRECTION_UNKNOWN` 14.
- FireRed warning buckets: `MAP_EVENT_SPRITE_UNRESOLVED` 54, `MAP_SCENE_CONNECTION_TILESET_MISMATCH` 34, `MAP_RENDER_AUDIT_TILE_IMAGE_INDEX_OUT_OF_RANGE` 8.
- `--all` skipped-target buckets: binary GBA ROM skipped 5, NDS ROM skipped 9, missing target skipped 4.

## Posture

The audit keeps stock blank secondary-tile image slots warning-only when the tile reference is inside the game's total tile limit because the app renderer already treats those decoded-image misses as blank. Game tile-limit violations, missing assets, unparseable indexed PNGs/palettes, missing metatile definitions, palette-index violations, all-blank suspicious renders, and unreadable resolved event sprites remain blocker failures.
