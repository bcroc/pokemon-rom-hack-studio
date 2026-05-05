# PokemonHackStudio Planning And Progress

## Current Focus

No active implementation row. `PHS-T2` is the next ready source-indexing lane, and the completed `PHS-T12` workbench overhaul is the new UI/editor baseline.

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
| PHS-T9 | Done | Small-Screen Map Editor UX Refactor | Canvas-first compact mode, map browser/tool/palette/inspector popovers, relaxed pane minimums, compact inspector controls, and 1280 x 800 smoke proof are implemented. |
| PHS-T10 | Done | Map Canvas Input Navigation | Scroll-wheel/touchpad zoom, pinch magnification, center-preserving zoom updates, and arrow-key viewport panning are implemented for the maps canvas. |
| PHS-T11 | Done | Maps Event Pane And Inline Scripts | First-class map event browsing, subtype templates, typed editing, canvas/session sync, undo/redo script staging, map-local script indexing, and preview-first inline script mutation plans are implemented and verified. |
| PHS-T12 | Done | All-In Source Workbench Overhaul | Source workbench shell, tabbed Maps authoring, reusable mutation review, source inspectors, session-owned map edit state, and Porymap/Poryscript/Porytiles-inspired source mutation planners are implemented and verified. |

## Recent Progress

- `PHS-T1` delivered a live `ProjectIndex`-backed Maps view for `pokeemerald` and `pokefirered`, including group/map navigation, layout metadata, event counts, connections, source links, diagnostics, and capped blockdata previews.
- `PHS-T4` delivered the first visual map editor: real tileset-backed rendering, layout painting, event staging, mutation-plan preview, and backup-protected explicit source apply.
- `PHS-T5` hardened the visual editor around recoverable dirty-state navigation, session-owned tools/selection/undo state, rendered metatile picking, richer mutation previews, safer apply gating, and clearer desktop interactions.
- `PHS-T6` made the map easier to inspect at whole-map scale with fit/zoom/reset controls, a full-map overview that can pan the main canvas, layer stack visibility/opacity/solo controls, and source-backed metatile layer-type decoding.
- `PHS-T7` refactored map rendering around core BG layer expansion, palette-aware indexed tileset drawing, game-composite and individual BG layer presets, inspector layer previews, and selected-cell collision/elevation/layer details.
- `PHS-T8` overhauled the map editor around full-scene game previews: central layouts keep edit coordinates, connected maps and repeated borders render around them, the player-view frame is available as an overlay, resolvable object events use source sprite PNGs, and editor controls are grouped around game art, scene context, events, and diagnostics.
- `PHS-T9` made the maps editor usable at 1280 x 800 with the app sidebar visible: compact mode keeps the canvas primary, moves map selection/tools/palette/inspector into on-demand controls, preserves dirty-state preview/apply/discard gating, and keeps the regular three-pane layout for wider windows.
- `PHS-T10` made the maps canvas more natural to navigate: vertical scroll and touchpad magnification request zoom through the existing editor zoom state, toolbar/slider/gesture zoom preserve the current viewport center, and arrow keys pan the visible map while leaving staged map data untouched.
- `PHS-T11` upgraded map events from a simple inspector to a first-class Maps pane with grouped browsing, subtype-aware creation, typed core fields, custom property preservation, canvas/session selection sync, and raw map-local script body staging through the existing mutation-plan gates.
- `PHS-T12` delivered the all-in source workbench overhaul: the app now groups source modules by ROM-hacking workflow, Maps is a reusable tabbed editor pattern, `MapEditorSession` owns maps edit state, and new source mutation planners cover map blocks, collision/elevation, headers, connections, wild encounters, scripts, and tilesets.
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
- `PHS-T9`:
  - `make test`
  - `make verify`
  - Manual app smoke at 1280 x 800 with the app sidebar visible: opened Maps, switched from `PetalburgCity` to `MauvilleCity`, confirmed the canvas stayed primary, opened and closed the map browser, palette, and inspector popovers, used the tool menu plus fit and 100% zoom controls, and verified dirty-state preview/discard gating without applying source writes.
  - Manual app smoke at 1700 x 900: confirmed the wider three-pane map list/canvas/inspector layout returns.
  - `git diff --check`
- `PHS-T10`:
  - `make test`
  - `make verify`
  - Manual app smoke at 1280 x 800 with the app sidebar visible: opened Maps, confirmed compact canvas chrome remained usable, used scroll over the canvas to zoom from 200% to 124%, clicked the canvas to focus it, and used Right/Down arrow keys to pan the visible map viewport.
  - Manual app smoke in the wider three-pane layout: clicked the canvas and confirmed Left/Up arrow keys moved the map viewport scrollbars without staging edits.
  - `git diff --check`
- `PHS-T11`:
  - `make test`
  - `xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath DerivedData/PokemonHackStudio -destination platform=macOS test`
  - `make verify`
  - `DerivedData/PokemonHackStudio/Build/Products/Debug/pokemonhack-cli map-visual pokeemerald MAP_MAUVILLE_CITY --json > /tmp/pokemonhack-pokeemerald-map-visual.json` (`2,048,926` bytes)
  - `DerivedData/PokemonHackStudio/Build/Products/Debug/pokemonhack-cli map-visual pokefirered MAP_PALLET_TOWN --json > /tmp/pokemonhack-pokefirered-map-visual.json` (`1,329,960` bytes)
  - `make validate`
  - Manual app smoke: opened Maps on `PetalburgCity`, used the inspector Events pane, selected an object event from the grouped browser, verified typed fields, created a staged map-local script label for a `0x0` script event, saw the inline script editor resolve to `data/maps/PetalburgCity/scripts.inc`, and discarded the dirty state without applying source writes.
  - `git diff --check`
- `PHS-T12`:
  - `swift test --package-path PokemonHackStudio` (43 tests)
  - `make test` (43 tests)
  - `make validate`
  - `cd PokemonHackStudio && xcodegen generate`
  - `xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath DerivedData/PokemonHackStudio -destination platform=macOS test`
  - `make verify`
  - `DerivedData/PokemonHackStudio/Build/Products/Debug/pokemonhack-cli map-visual pokeemerald MAP_MAUVILLE_CITY --json > /tmp/pokemonhack-pokeemerald-map-visual.json` (`2,048,994` bytes)
  - `DerivedData/PokemonHackStudio/Build/Products/Debug/pokemonhack-cli map-visual pokefirered MAP_PALLET_TOWN --json > /tmp/pokemonhack-pokefirered-map-visual.json` (`1,330,028` bytes)
  - `pokeruby` and `pokeemerald-expansion` map-visual smokes skipped because local fixture directories were not present in this workspace.
  - Manual app smoke: opened the project on `pokeemerald`, confirmed grouped source-workbench navigation and zero diagnostics, opened Maps in compact mode, verified the inspector popover exposes Map, Collision, Events, Header, Connections, Wild, Scripts, and Tilesets tabs, switched to Tilesets, then hid the sidebar for the wider browser/canvas/inspector layout.
  - Manual mutation smoke: staged a preview-first map shift, verified the mutation panel showed one staged edit, previewed source diagnostics for `data/layouts/PetalburgCity/map.bin`, confirmed apply remained explicit, and discarded back to no staged edits without writing source files.
  - `git diff --check`
