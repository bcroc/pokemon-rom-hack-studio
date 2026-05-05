# PokemonHackStudio Planning And Progress

## Current Focus

`PHS-T8` is complete: the maps editor now defaults to a full-scene, game-authentic preview while preserving editor-first painting and mutation-plan workflows.

## Active Board

| ID | Status | Title | Notes |
| --- | --- | --- | --- |
| PHS-T1 | Done | Map/Layout Viewer | Read-only core map catalog, CLI `maps`, SwiftUI Maps surface, and fixture fallback are implemented and verified. |
| PHS-T2 | Ready | Script/Text And C Table Indexing | Add script/text outlines and table-aware species/trainers/items/moves indexes after PHS-T1 core catalog lands. |
| PHS-T3 | Ready | Build/Patch/Playtest Validation Polish | Tighten CLI/app validation flows, patch summaries, generated-output checks, and playtest planning. |
| PHS-T4 | Done | Visual Map Editor | Real map art, staged layout/event edits, mutation previews, explicit apply, and backups are implemented with the SwiftPM baseline rechecked. |
| PHS-T5 | Done | Map Editor UX Hardening And Refactor | Dirty-state guards, rendered metatile palette, improved canvas tools, session-based state, stronger apply gating, and focused regression coverage are implemented and verified. |
| PHS-T6 | Done | Map Editor Full-Map And Layer Visibility | Fit/zoom controls, full-map overview panning, layer stack visibility/opacity/solo controls, metatile layer-type decoding, and focused proof are implemented. |
| PHS-T7 | Done | Game-Faithful Map Layer Rendering And Maps Refactor | Shared palette-aware BG layer rendering, game-composite/layer presets, per-layer previews, selected-cell layer details, and focused proof are implemented. |
| PHS-T8 | Done | Full-Scene Maps Editor Overhaul | Game-authentic full-scene previews with borders, connections, player-view framing, editor-first layer controls, and focused scene/rendering proof are implemented. |

## Recent Progress

- `PHS-T1` delivered a live `ProjectIndex`-backed Maps view for `pokeemerald` and `pokefirered`, including group/map navigation, layout metadata, event counts, connections, source links, diagnostics, and capped blockdata previews.
- `PHS-T4` delivered the first visual map editor: real tileset-backed rendering, layout painting, event staging, mutation-plan preview, and backup-protected explicit source apply.
- `PHS-T5` hardened the visual editor around recoverable dirty-state navigation, session-owned tools/selection/undo state, rendered metatile picking, richer mutation previews, safer apply gating, and clearer desktop interactions.
- `PHS-T6` made the map easier to inspect at whole-map scale with fit/zoom/reset controls, a full-map overview that can pan the main canvas, layer stack visibility/opacity/solo controls, and source-backed metatile layer-type decoding.
- `PHS-T7` refactored map rendering around core BG layer expansion, palette-aware indexed tileset drawing, game-composite and individual BG layer presets, inspector layer previews, and selected-cell collision/elevation/layer details.
- `PHS-T8` overhauled the map editor around full-scene game previews: central layouts keep edit coordinates, connected maps and repeated borders render around them, the player-view frame is available as an overlay, resolvable object events use source sprite PNGs, and editor controls are grouped around game art, scene context, events, and diagnostics.
- ProjectIndex-backed dashboard slice is complete and verified.
- Reference synthesis and product architecture docs are in place.
- Generated `.inc` files remain generated artifacts and are not edited by map workflows.

## Validation Ledger

For each completed row, record the focused commands that proved the slice. Generated ROMs, local indexes, and build products remain untracked artifacts.

- `PHS-T1`:
  - `swift test --package-path PokemonHackStudio`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli maps pokeemerald --json`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli maps pokefirered --json`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli validate pokeemerald --json`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli validate pokefirered --json`
  - `cd PokemonHackStudio && xcodegen generate`
  - `xcodebuild -project PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath ../DerivedData/PokemonHackStudio build`
  - `./script/build_and_run.sh --verify`
  - Manual app smoke: opened Maps with repo-local `pokeemerald`, selected `MauvilleCity`, and verified live layout facts, event counts, connections, source links, and metatile-ID preview.
- `PHS-T4`:
  - `swift test --package-path PokemonHackStudio`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli map-visual pokeemerald MAP_MAUVILLE_CITY --json`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli map-visual pokefirered MAP_PALLET_TOWN --json`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli validate pokeemerald --json`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli validate pokefirered --json`
  - `cd PokemonHackStudio && xcodegen generate`
  - `xcodebuild -project PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath ../DerivedData/PokemonHackStudio test`
  - `./script/build_and_run.sh --verify`
  - Baseline recheck before `PHS-T5`: `swift test --package-path PokemonHackStudio`
- `PHS-T5`:
  - `swift test --package-path PokemonHackStudio`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli map-visual pokeemerald MAP_MAUVILLE_CITY --json`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli map-visual pokefirered MAP_PALLET_TOWN --json`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli validate pokeemerald --json`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli validate pokefirered --json`
  - `cd PokemonHackStudio && xcodegen generate`
  - `xcodebuild -project PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath ../DerivedData/PokemonHackStudio test`
  - `./script/build_and_run.sh --verify`
- `PHS-T6`:
  - `swift test --package-path PokemonHackStudio`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli map-visual pokeemerald MAP_MAUVILLE_CITY --json`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli map-visual pokefirered MAP_PALLET_TOWN --json`
  - `cd PokemonHackStudio && xcodegen generate`
  - `xcodebuild -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath DerivedData/PokemonHackStudio test`
  - `./script/build_and_run.sh --verify`
- `PHS-T7`:
  - `swift test --package-path PokemonHackStudio`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli map-visual pokeemerald MAP_MAUVILLE_CITY --json`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli map-visual pokefirered MAP_PALLET_TOWN --json`
  - `cd PokemonHackStudio && xcodegen generate`
  - `xcodebuild -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath DerivedData/PokemonHackStudio test`
  - `./script/build_and_run.sh --verify`
  - `git diff --check`
- `PHS-T8`:
  - `make test`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli map-visual pokeemerald MAP_MAUVILLE_CITY --json`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli map-visual pokefirered MAP_PALLET_TOWN --json`
  - `cd PokemonHackStudio && xcodegen generate`
  - `xcodebuild -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath DerivedData/PokemonHackStudio test`
  - `make verify`
  - `git diff --check`
