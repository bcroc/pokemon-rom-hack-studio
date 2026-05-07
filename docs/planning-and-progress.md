# PokemonHackStudio Planning And Progress

## Current Focus

No active implementation row. The May 6 build-time asset bundling pass is complete as `PHS-T34`: the generated macOS app bundle now receives safe local source asset trees during Xcode builds while keeping ROMs, saves, generated outputs, build products, toolchains, and reference clones excluded. The completed `PHS-T33` compact UX refactor, `PHS-T32` Pokemon species editor, `PHS-T31` Trainers workbench, `PHS-T27`/`PHS-T28` Resources baseline, `PHS-T29` Maps polish, `PHS-T30` Settings/menu extension, `PHS-T18` resource library, `PHS-T15` Graphics diagnostics, `PHS-T21` script readiness, and `PHS-T23` toolchain matrix remain the active product baseline. `PHS-T25` remains the broader UX bridge for app-visible backlinks across Resources, Pokemon, Maps, Scripts, Graphics, and Build/Patch/Playtest.

## Active Board

| ID | Status | Title | Notes |
| --- | --- | --- | --- |
| PHS-T1 | Done | Map/Layout Viewer | Read-only core map catalog, CLI `maps`, SwiftUI Maps surface, and fixture fallback are implemented and verified. |
| PHS-T2 | Done | Script/Text And C Table Indexing | Live read-only Scripts/Text/Pokemon/Trainer/Item source indexes now replace fixture-backed surfaces when a supported project is loaded, with source spans, facts, previews, diagnostics, adapter-owned descriptors, CLI JSON, validate diagnostics, fixture fallback for no-project mode, and a `MapScriptIndex`-backed script outline browser for labels, commands, and text blocks. |
| PHS-T3 | Done | Build/Patch/Playtest Validation Polish | Non-mutating core/CLI/app reports now cover build output existence, SHA1 expectations, checksum/freshness, generated-artifact inventory, toolchain readiness, patch metadata diagnostics, and mGBA handoff plans while keeping Build/Run/Validate actions preview-only. |
| PHS-T4 | Done | Visual Map Editor | Real map art, staged layout/event edits, mutation previews, explicit apply, and backups are implemented with the SwiftPM baseline rechecked. |
| PHS-T5 | Done | Map Editor UX Hardening And Refactor | Dirty-state guards, rendered metatile palette, improved canvas tools, session-based state, stronger apply gating, and focused regression coverage are implemented and verified. |
| PHS-T6 | Done | Map Editor Full-Map And Layer Visibility | Fit/zoom controls, full-map overview panning, layer stack visibility/opacity/solo controls, metatile layer-type decoding, and focused proof are implemented. |
| PHS-T7 | Done | Game-Faithful Map Layer Rendering And Maps Refactor | Shared palette-aware BG layer rendering, game-composite/layer presets, per-layer previews, selected-cell layer details, and focused proof are implemented. |
| PHS-T8 | Done | Full-Scene Maps Editor Overhaul | Game-authentic full-scene previews with borders, connections, player-view framing, editor-first layer controls, and focused scene/rendering proof are implemented. |
| PHS-T9 | Done | Small-Screen Map Editor UX Refactor | Canvas-first compact mode, map browser/tool/palette/inspector popovers, relaxed pane minimums, compact inspector controls, and 1280 x 800 smoke proof are implemented. |
| PHS-T10 | Done | Map Canvas Input Navigation | Scroll-wheel/touchpad zoom, pinch magnification, center-preserving zoom updates, and arrow-key viewport panning are implemented for the maps canvas. |
| PHS-T11 | Done | Maps Event Pane And Inline Scripts | First-class map event browsing, subtype templates, typed editing, canvas/session sync, undo/redo script staging, map-local script indexing, and preview-first inline script mutation plans are implemented and verified. |
| PHS-T12 | Done | All-In Source Workbench Overhaul | Source workbench shell, tabbed Maps authoring, reusable mutation review, source inspectors, session-owned map edit state, and Porymap/Poryscript/Porytiles-inspired source mutation planners are implemented and verified. |
| PHS-T13 | Candidate | Table Parser Hardening | Follow-up hardening beyond the `PHS-T2` read-only index: expand descriptor coverage, unknown-field reporting, source-shape edge cases, and mutation-plan readiness for later table workflows. |
| PHS-T14 | Candidate | Build/Patch/Playtest Report Follow-ups | Follow-up beyond `PHS-T3`: patch manifests, user-selectable base ROM catalogs, report export/persistence, richer run-plan UI, and fuller patch/base-ROM workflows. |
| PHS-T15 | Done | Graphics And Tileset Diagnostics | Live read-only Graphics diagnostics now cover tileset artifact inventory, checksums, generated-output freshness, palette/metatile diagnostics, layer-mode summaries, animation folders, source-asset warnings, CLI JSON, and the SwiftUI Graphics module. |
| PHS-T16 | Done | Map Workflow Polish From Reference Audit | Current-map script autocomplete, read-only wild encounter index, SHA1 source snapshot checks before apply, and reverse/offset connection diagnostics are implemented; event-limit warnings and row-based wild edits remain later follow-ups. |
| PHS-T17 | Candidate | Binary ROM Graph Baseline | Later binary-only fallback lane for semantic ROM runs, anchors, pointers, goto, free-space/repoint planning, diffs, backups, and mutation-plan posture. |
| PHS-T18 | Done | Generation III Resource Library And Parsers | Auto-loaded resource library, Ruby/Sapphire detection fix, FireRed/LeafGreen variant targets, top-level GBA ROM indexing, GameCube disc/FST plus FSYS/LZSS parser path, resource CLI, dashboard section, and focused proof are implemented. |
| PHS-T19 | Done | Moves And Learnset Source Graph | Core/CLI `MoveGraph` and `LearnsetGraphEntry` models now expose level-up, TM/HM, tutor, egg, and Expansion all-learnables buckets with source spans and unresolved-move diagnostics; Data > Pokemon surfaces level-up, TM/HM, and egg learnsets per species. |
| PHS-T20 | Done | Species Data Graph | Core/CLI species graph now composes species, evolution, Pokedex, asset, learnset, and related-data nodes/edges; `ProjectSpeciesCatalog` and the Data > Pokemon workbench expose detailed species stats, EV/training/breeding fields, Pokedex/evolution data, source links, and local Pokemon asset previews. |
| PHS-T21 | Done | Live Script Readiness | Non-mutating core, CLI, validate-script, and Scripts app report now evaluate selected map or script source resolution, build output/tool readiness, and mGBA playtest prerequisites. |
| PHS-T22 | Done | Patch Manifest Models And CLI | `patch-manifest` now reports patch metadata, base ROM checksum candidates, compatibility state, and dry-run plans without applying or exporting patches; app workbench polish remains a follow-up. |
| PHS-T23 | Done | Toolchain Health Matrix | Preview-only core/CLI/app matrix reports external and project-local tool discovery, ROM-header config/output expectations, graphics conversion prerequisites, and generated-artifact health across Emerald, FireRed/LeafGreen, and Ruby/Sapphire decomp projects. |
| PHS-T24 | Done | mGBA Playtest Artifact Plans | Playtest handoff sessions now include planned run-log, stdout/stderr, screenshot, and headless savestate artifacts while keeping emulator launch/capture out of scope. |
| PHS-T25 | Candidate | All-In-One Related Data UX | Core related-data nodes/edges exist for species, moves, learnsets, Pokedex entries, and assets; app-visible backlinks across Resources, Pokemon, Maps, Scripts, Graphics, and Build/Patch/Playtest remain next. |
| PHS-T26 | Done | Resource Library Editor Surface | Resources is now a first-class editor module with library metrics, search-filtered entries, item drill-down for source paths and byte ranges, resource diagnostics, source inspector support, and open-project resource refresh. |
| PHS-T27 | Done | Gen III GBA Asset Catalog And Fast Navigation | A cached read-only GBA asset catalog now composes project, source-index, map, script, graphics, build, and resource data; CLI `asset-index` emits JSON; Resources defaults to fast asset rows and filters; auto-loaded Resources exclude GameCube rows for now. |
| PHS-T28 | Done | GBA Asset Availability And Fast Resources Navigation | Resources now reports source-first availability, keeps optional generated/build outputs out of warning state, hardens FireRed and Expansion parser paths, loads selected asset catalogs lazily off the main UI path, and filters/sorts cached asset rows through the table-based Resources view. |
| PHS-T29 | Done | Maps Editor UI/UX Polish | Refactored Maps into a top-chrome, canvas-first Mac editor surface with searchable map browsing, grouped icon tools, visible brush/zoom/status chrome, compact popovers, and regrouped inspector panels while keeping mutation-plan write gates unchanged. |
| PHS-T30 | Done | Settings And Menu Extension | Native macOS Settings now owns project, editor, health-check, resource, and advanced preferences; menus expose Project/Tools/View actions; health filtering is applied in the app store before Build/Patch/Playtest and Diagnostics consume reports. |
| PHS-T31 | Done | Trainer/Battle Editor Workbench | Core trainer catalog, preview/apply mutation planner, trainer CLI smoke, app-store dirty state, and searchable split Trainers workbench are implemented for classic Emerald/FireRed trainer and party editing; inherited default moves, custom move overrides, uniform IV writes, visible per-stat IV/nature controls, and source-shape diagnostics are covered. |
| PHS-T32 | Done | Editable Pokemon Species Workbench | Core species drafts/plans/apply, constant-backed pickers, Emerald/FireRed source rewrites, app dirty-state wiring, and a cleaned-up Data > Pokemon editor are implemented for species info, stats, level-up moves, TM/HM moves, and egg moves; evolutions, Pokedex, and assets remain read-only. |
| PHS-T33 | Done | App-Wide Compact UX Refactor | Shared shell geometry, compact source-inspector affordance, wrapped Resources controls, compact Pokemon/Trainers browser access, collapsed source preview defaults, stacked mutation review details, and resizable Settings are implemented and verified. |
| PHS-T34 | Done | Build-Time App Asset Bundling | Xcode builds now copy safe local Emerald/FireRed source asset trees into the app bundle under `PokemonHackStudioAssets`, write a bundle manifest, exclude ROM/generated/build/toolchain/reference payloads, and expose bundled entries as read-only Resources fallback data. |

## Recent Progress

- `PHS-T1` delivered a live `ProjectIndex`-backed Maps view for `pokeemerald` and `pokefirered`, including group/map navigation, layout metadata, event counts, connections, source links, diagnostics, and capped blockdata previews.
- `PHS-T2` delivered live read-only source indexes for Scripts, Text, Pokemon, Trainers, and Items; the CLI exposes `source-index`, validate includes source-index diagnostics, app modules prefer live records over fixtures, and fixture fallback remains for no-project mode.
- `PHS-T2` follow-on script outline browser now reuses `MapScriptIndex` label/body parsing across Emerald/FireRed script sources, skips generated map includes, exposes project-wide labels, command rows, text references, text blocks, spans, and diagnostics through CLI JSON and the SwiftUI Scripts surface.
- `PHS-T3` delivered read-only build, patch, and playtest validation reports: CLI JSON now reports build output/checksum/freshness/toolchain readiness, patch metadata and malformed-input diagnostics, validate includes source-index plus build/playtest diagnostics, and the Build/Patch/Playtest app surface renders live report rows with disabled actions.
- `PHS-T4` delivered the first visual map editor: real tileset-backed rendering, layout painting, event staging, mutation-plan preview, and backup-protected explicit source apply.
- `PHS-T5` hardened the visual editor around recoverable dirty-state navigation, session-owned tools/selection/undo state, rendered metatile picking, richer mutation previews, safer apply gating, and clearer desktop interactions.
- `PHS-T6` made the map easier to inspect at whole-map scale with fit/zoom/reset controls, a full-map overview that can pan the main canvas, layer stack visibility/opacity/solo controls, and source-backed metatile layer-type decoding.
- `PHS-T7` refactored map rendering around core BG layer expansion, palette-aware indexed tileset drawing, game-composite and individual BG layer presets, inspector layer previews, and selected-cell collision/elevation/layer details.
- `PHS-T8` overhauled the map editor around full-scene game previews: central layouts keep edit coordinates, connected maps and repeated borders render around them, the player-view frame is available as an overlay, resolvable object events use source sprite PNGs, and editor controls are grouped around game art, scene context, events, and diagnostics.
- `PHS-T9` made the maps editor usable at 1280 x 800 with the app sidebar visible: compact mode keeps the canvas primary, moves map selection/tools/palette/inspector into on-demand controls, preserves dirty-state preview/apply/discard gating, and keeps the regular three-pane layout for wider windows.
- `PHS-T10` made the maps canvas more natural to navigate: vertical scroll and touchpad magnification request zoom through the existing editor zoom state, toolbar/slider/gesture zoom preserve the current viewport center, and arrow keys pan the visible map while leaving staged map data untouched.
- `PHS-T11` upgraded map events from a simple inspector to a first-class Maps pane with grouped browsing, subtype-aware creation, typed core fields, custom property preservation, canvas/session selection sync, and raw map-local script body staging through the existing mutation-plan gates.
- `PHS-T12` delivered the all-in source workbench overhaul: the app now groups source modules by ROM-hacking workflow, Maps is a reusable tabbed editor pattern, `MapEditorSession` owns maps edit state, and new source mutation planners cover map blocks, collision/elevation, headers, connections, wild encounters, scripts, and tilesets.
- `PHS-T18` delivered the Generation III resource library: `GenIIIResourceRegistry` discovers editable roots, reference roots, recent roots, and safe top-level GBA media; `references/pokeruby` now indexes as Ruby/Sapphire instead of Emerald; FireRed/LeafGreen and Ruby/Sapphire variants surface through build/checksum rows; `.gba` files index as read-only ROM resources; and direct GameCube `.iso`/`.gcm` `resource-index` inputs have clean-room disc, FST, FSYS, and LZSS member parsing.
- Broad reference sweep cloned 18 additional Gen III ROM-hacking/tooling references into the ignored `references/` bench, expanded `references/manifest.json` to 30 pinned entries, and refreshed the reference docs with clean-room adoption posture plus `PHS-T19` through `PHS-T25` candidate lanes.
- `PHS-T15` delivered the first broad-sweep product extension: Graphics now renders live read-only diagnostics from `TilesetIndexLoader`, with artifact checksums/freshness, generated-output warnings, palette/metatile/layer summaries, animation folders, CLI JSON, and fixture fallback only when no project is loaded.
- `PHS-T21` delivered live script readiness: `ScriptReadinessReportBuilder` evaluates selected map or script labels against map-local/shared/global source labels, current build output/tool readiness, and headless mGBA handoff prerequisites; CLI exposes `script-readiness --map/--script`; validate now smokes both modes; and the Scripts app surface renders a read-only target selector plus readiness rows.
- `PHS-T23` delivered a preview-only toolchain health matrix: CLI `toolchain-health`, validate JSON, and the Build/Patch/Playtest UI now combine external/project-local tool discovery, ROM-header config/output checks, graphics conversion prerequisites, and generated-artifact health without invoking build, conversion, patch, emulator, or source-write actions.
- `PHS-T26` promoted the Generation III resource library into a first-class Resources editor module: sidebar navigation now exposes indexed GBA source roots and top-level GBA ROMs; expandable entries show source items, byte ranges, size/checksum facts, and diagnostics; search filters across entry metadata and nested items; and opening a project refreshes the library immediately.
- `PHS-T27` added the source-first GBA asset catalog: `GenIIIAssetCatalogBuilder` composes project, source-index, map, script, graphics, build, and resource loaders; source-index descriptors now include moves, learnsets, evolutions, and Pokedex tables; safe inventory scans common source asset roots without generated ROM/build products; CLI `asset-index` emits JSON; Resources defaults to cached asset rows with category filters/sorts and related-module navigation; and auto-loaded Resources stay GBA-only for now.
- `PHS-T28` made Resources source-first and fast: asset rows now carry availability counts, missing generated ROM/build/graphics outputs are optional facts instead of warnings, FireRed JSON item and Expansion moved-data parser paths are covered, selected catalogs load lazily in the app, and cached search/category/sort state feeds the compact table/detail Resources surface.
- `PHS-T29` polished Maps into a Mac-native canvas-first editor: the map browser is searchable, editor tools are grouped with SF Symbol icon controls, compact mode uses top-page map/tool/palette/inspector popovers, the canvas keeps brush/hover/zoom state visible, and inspector tabs are regrouped into Overview/Layers, Paint/Collision, Events/Scripts, and Map Data without changing mutation-plan apply gates.
- `PHS-T30` added native macOS Settings plus broader Project/Tools/View menus: persisted preferences cover startup/recent projects, editor defaults, health-check categories and noise, diagnostics inclusion, resource indexing, reset, and export/copy flows while keeping build, patch, emulator, graphics conversion, and source writes preview-only.
- Reference-informed follow-through completed `PHS-T16`, `PHS-T19`, `PHS-T20`, `PHS-T22`, and `PHS-T24`: Maps now has script autocomplete, read-only wild encounters, source snapshot conflict checks, and connection diagnostics; core/CLI graph commands expose moves/learnsets and species-related backlinks; patch manifests are plan-only; and playtest sessions describe expected external artifacts.
- `PHS-T19`/`PHS-T20` Data > Pokemon workbench follow-through replaced the generic Pokemon table with a searchable species browser, detail header with local front/back/icon/footprint previews, compact stat/EV/training/breeding sections, level-up/TM-HM/egg learnset tables, evolution and Pokedex panels, asset diagnostics, and source inspector links. CLI `pokemon-catalog --json` now emits the same read-only catalog for app and smoke use.
- `PHS-T31` replaced the flat Trainers list with a searchable split workbench: trainer browsing, source diagnostics, editable identity/battle settings, trainer bag items, AI flags, double-battle mode, party shape, inherited default moves, custom move overrides, six visible IV fields, and nature controls now route through `WorkbenchStore` dirty state and the existing mutation-plan footer. Core catalog/planner coverage joins `trainers.h` to `trainer_parties.h`, supports all four classic party shapes, rewrites only affected C initializer blocks, applies uniform IV edits through the classic source byte, blocks unsupported per-stat IV/nature writes with diagnostics, and creates backups on apply.
- `PHS-T32` makes Data > Pokemon editable for the first species pass: the workbench now shows readable labels instead of raw `MOVE_*`/`ABILITY_*`/`TYPE_*` text, keeps source previews collapsed by default, edits stats/training/breeding/held-item fields plus level-up/TM-HM/egg moves, and routes preview/apply/discard through the existing mutation-plan panel with source hash checks and backups.
- `PHS-T33` refactored the app-wide macOS layout for smaller screens: `EditorShell` is geometry-aware, compact mode moves the source inspector behind a toolbar popover, Resources wraps its controls and uses compact asset rows, Pokemon and Trainers use compact browser popovers, Trainer/Pokemon source previews default collapsed, mutation review details stack in compact mode, Settings is resizable, and wide windows still restore split layouts.
- `PHS-T34` added build-time asset bundling for the macOS app: XcodeGen now runs `script/bundle_app_assets.sh`, the script copies safe `constants`, `data`, `graphics`, `include`, `sound`, `songs`, and `src/data` trees plus small root metadata for local source projects, and the app Resources library treats bundled source roots as read-only fallback entries when local editable roots are not available.
- Reference refresh added pinned source-first refs for `pokeemerald`, `pokefirered`, and `agbcc`; `docs/reference-improvement-audit.md` now captures the comparison against current code and the prioritized follow-up rows.
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
- `PHS-T2`:
  - `swift test --package-path PokemonHackStudio` (47 tests)
  - `make test` (47 tests)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli source-index pokeemerald --json > /tmp/pokemonhack-pokeemerald-source-index.json` (11,573 records; 122 diagnostics)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli source-index pokefirered --json > /tmp/pokemonhack-pokefirered-source-index.json` (11,500 records; 4 diagnostics)
  - `make validate`
  - `cd PokemonHackStudio && xcodegen generate`
  - `xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath DerivedData/PokemonHackStudio -destination platform=macOS test`
  - `make verify`
  - Manual app smoke: opened repo-local `pokeemerald` and `pokefirered`, visited Scripts, Text, Pokemon, Trainers, and Items, confirmed live source paths/spans/facts/previews render, search filters live records, dirty counts stay at 0, and the nested source repos stayed clean.
  - `git diff --check`
  - Script-outline continuation proof: `swift test --package-path PokemonHackStudio --filter SourceIndexTests` (5 tests)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli script-outline pokeemerald --json > /tmp/pokemonhack-pokeemerald-script-outline.json` (571 sources; 17,265 labels; 48,623 command rows; 7,928 text blocks; 69 diagnostics)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli script-outline pokefirered --json > /tmp/pokemonhack-pokefirered-script-outline.json` (498 sources; 6,637 labels; 23,374 command rows; 1,435 text blocks; 184 diagnostics)
  - `make test` (55 tests)
  - `make validate`
  - `cd PokemonHackStudio && xcodegen generate`
  - `xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath DerivedData/PokemonHackStudio -destination platform=macOS test`
  - `make verify`
  - `git diff --check`
- `PHS-T3`:
  - `swift test --package-path PokemonHackStudio` (54 tests)
  - `make test` (54 tests)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli build pokeemerald --json > /tmp/pokemonhack-pokeemerald-build-report.json` (2 targets; `BUILD_OUTPUT_MISSING` for absent `pokeemerald.gba`; 8 generated-output descriptors)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli build pokefirered --json > /tmp/pokemonhack-pokefirered-build-report.json` (1 target; `pokefirered.gba` exists; SHA1 matched; freshness fresh; 8 generated-output descriptors)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli playtest pokeemerald --headless --json > /tmp/pokemonhack-pokeemerald-playtest-report.json` (`isRunnable: false`; mGBA discovered at `/Applications/mGBA.app`; ROM candidate missing)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli playtest pokefirered --headless --json > /tmp/pokemonhack-pokefirered-playtest-report.json` (`isRunnable: true`; mGBA discovered; ROM candidate present)
  - Synthetic patch CLI smokes under `/tmp/pokemonhack-patch-smokes`: valid IPS/BPS/UPS returned structured metadata; unknown input returned `PATCH_FORMAT_UNKNOWN`; truncated BPS returned `PATCH_MALFORMED`.
  - `swift run --package-path PokemonHackStudio pokemonhack-cli validate pokeemerald --json > /tmp/pokemonhack-pokeemerald-validate-report.json` (`sourceIndexRecordCount: 11573`; build/playtest diagnostics included; 126 total diagnostics)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli validate pokefirered --json > /tmp/pokemonhack-pokefirered-validate-report.json` (`sourceIndexRecordCount: 11500`; playtest plan diagnostic included; 5 total diagnostics)
  - `make validate`
  - `cd PokemonHackStudio && xcodegen generate`
  - `xcodebuild -quiet -project PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath ../DerivedData/PokemonHackStudio -destination platform=macOS test`
  - `make verify`
  - Manual app smoke: opened Build/Patch/Playtest for repo-local `pokeemerald` and `pokefirered`, confirmed live readiness sections render build targets, generated artifacts, toolchain, playtest handoff, and diagnostics; search filtered report rows by `mgba`; in-view Build/Run/Validate actions stayed disabled; no build, patch, emulator, or source-apply action was invoked.
  - `git -C pokeemerald status --short` and `git -C pokefirered status --short` stayed clean.
  - `git diff --check`
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
  - Continuation recheck in the current checkout: `swift test --package-path PokemonHackStudio --filter MapVisualTests` (21 tests); `xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath DerivedData/PokemonHackStudio -destination platform=macOS test -only-testing:PokemonHackStudioTests/MapEditorSessionTests`; `DerivedData/PokemonHackStudio/Build/Products/Debug/pokemonhack-cli map-visual pokeemerald MAP_MAUVILLE_CITY --json > /tmp/pokemonhack-pokeemerald-phs-t11-recheck.json` (`2,048,994` bytes); `DerivedData/PokemonHackStudio/Build/Products/Debug/pokemonhack-cli map-visual pokefirered MAP_PALLET_TOWN --json > /tmp/pokemonhack-pokefirered-phs-t11-recheck.json` (`1,330,028` bytes); `git diff --check`.
  - Remaining limits: inline script editing is raw source-body editing only; structured script command editing remains later work. New labels require an editable existing `data/maps/*/scripts.inc`; shared map script files are warning-gated, and inline writes stay disabled for `0x0`, unresolved, duplicate, external, unsupported, or generated-include sources.
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
- `PHS-T18`:
  - `swift test --package-path PokemonHackStudio --filter GenIIIResourceTests` (4 tests)
  - `swift test --package-path PokemonHackStudio --filter GraphicsDiagnosticsTests` (4 tests; rechecked the existing graphics diagnostics helper after Xcode verification surfaced it)
  - `swift test --package-path PokemonHackStudio` (63 tests)
  - `make test` (63 tests)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli resources --json > /tmp/pokemonhack-resources.json` (15 entries: 6 GBA source roots, 5 top-level GBA ROMs, and 4 missing GameCube media diagnostics; 9 parsed)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli index references/pokeruby --json` (`profile: pokeruby`; `adapterID: pret.pokeruby`; 13 documents; 0 diagnostics)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli source-index references/pokeruby --json > /tmp/pokemonhack-reference-pokeruby-source-index.json` (14,000 records; 1,995 diagnostics; 349 items, 412 pokemon, 6,333 scripts, 6,212 text, 694 trainers)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli resource-index /tmp/pokemonhack-synthetic-colosseum.iso --json > /tmp/pokemonhack-synthetic-colosseum-resource-index.json` (`pokemonColosseum`; parsed; 4 resources; pokemon/text FSYS members recognized)
  - `make validate`
  - `make verify`
  - Manual app smoke: launched the built macOS app through `make verify`, opened the Dashboard resource library, confirmed the 15-resource metric, visible missing-media diagnostics for Colosseum, XD, Box, and Channel, top-level GBA ROM rows, and all six GBA source/reference roots including `references/pokeruby`.
  - Real Colosseum/XD/Box/Channel media smoke remains blocked until local `.iso`/`.gcm` images are supplied; the library intentionally shows missing-input diagnostics for those profiles.
- `PHS-T15`:
  - Baseline before implementation: `make test` (55 tests), `make validate`, and targeted CLI smokes for `source-index`, `script-outline`, `build`, `playtest`, and `validate` on `pokeemerald`/`pokefirered`.
  - `swift test --package-path PokemonHackStudio --filter GraphicsDiagnosticsTests` (4 tests)
  - `make test` (63 tests)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli graphics pokeemerald --json > /tmp/pokemonhack-pokeemerald-graphics.json` (75 tilesets; 226 tile images; 1,200 palettes; 19 animation folders; 2,007 diagnostics: generated graphics outputs missing and palette precision warnings)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli graphics pokefirered --json > /tmp/pokemonhack-pokefirered-graphics.json` (68 tilesets; 106 tile images; 2,144 palettes; 6 animation folders; 0 diagnostics)
  - Reference proof: `references/manifest.json` has 30 entries, all recorded HEADs matched local clones, `references/*` remained ignored, and only `references/manifest.json` was tracked under `references/`.
  - `make validate`
  - `make verify`
  - Manual app smoke: launched the built macOS app, opened the live Graphics module for repo-local `pokeemerald`, confirmed live summary cards, tileset rows, warning rows for missing generated graphics artifacts, and read-only diagnostics with no graphics tool invocation.
  - `git -C pokeemerald status --short` and `git -C pokefirered status --short` stayed clean.
  - `git diff --check`
- `PHS-T21`:
  - `swift test --package-path PokemonHackStudio --filter ScriptReadinessTests` (2 tests)
  - `make test` (68 tests)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli script-readiness pokeemerald --map MAP_MAUVILLE_CITY --json > /tmp/pokemonhack-pokeemerald-script-readiness-map.json` (`status: blocked` only because `pokeemerald.gba` is not built locally; map-local, global include, and assembly common-script labels resolved)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli script-readiness pokefirered --script PalletTown_EventScript_TryReadySignLady --json > /tmp/pokemonhack-pokefirered-script-readiness-script.json` (`status: passed`; selected label resolved to `data/maps/PalletTown/scripts.inc`; ROM/emulator handoff prerequisites present)
  - `make validate`
  - `make verify` (regenerated Xcode project, built, launched, and verified the macOS app; added `GameProfile: Sendable` to satisfy the existing Swift 6 app-build concurrency check)
- `PHS-T23`:
  - `swift test --package-path PokemonHackStudio --filter ToolchainHealthMatrixTests` (3 tests)
  - `swift test --package-path PokemonHackStudio` (68 tests)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli toolchain-health pokeemerald --json > /tmp/pokemonhack-pokeemerald-toolchain-health.json` (30 rows; 10 ready, 20 warnings, 0 errors; preview-only local tool and generated-artifact health surfaced)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli toolchain-health pokefirered --json > /tmp/pokemonhack-pokefirered-toolchain-health.json` (34 rows; 29 ready, 5 warnings, 0 errors; variant ROM-header output expectations surfaced)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli toolchain-health references/pokeruby --json > /tmp/pokemonhack-pokeruby-toolchain-health.json` (37 rows; 13 ready, 24 warnings, 0 errors; preview-only local tool and generated-artifact health surfaced)
  - `make validate`
  - `make verify`
  - App build/launch smoke: `make verify` rebuilt and launched the macOS app; Build/Patch/Playtest health rows compile into the preview-only surface, and no build, conversion, patch, emulator, or source-write action was invoked.
  - `git diff --check`
- `PHS-T26`:
  - `make test` (68 tests)
  - `make validate`
  - `xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath DerivedData/PokemonHackStudio -destination platform=macOS test -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testResourceLibraryRefreshesWhenOpeningProjectAndFiltersEntries`
  - `make verify`
  - Manual app smoke: launched the built macOS app, selected the new Resources sidebar module, confirmed 15 entries and 133 resource items, expanded the Pokemon Emerald GBA ROM row, and verified byte range, size, SHA1, read-only diagnostics, and the source inspector summary render.
- `PHS-T27`:
  - `swift test --package-path PokemonHackStudio --filter GenIIIAssetCatalogTests` (4 tests)
  - `swift test --package-path PokemonHackStudio --filter GenIIIResourceTests` (4 tests; auto-loaded Resources now exclude GameCube rows while direct synthetic GameCube `resource-index` parsing remains covered)
  - `swift test --package-path PokemonHackStudio` (72 tests)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli asset-index pokeemerald --json > /tmp/pokemonhack-pokeemerald-asset-index.json` (`pokeemerald`; 31,874 assets; 0 catalog diagnostics)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli asset-index pokefirered --json > /tmp/pokemonhack-pokefirered-asset-index.json` (`pokefirered`; 31,423 assets; 0 catalog diagnostics)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli asset-index references/pokeruby --json > /tmp/pokemonhack-pokeruby-asset-index.json` (`pokeruby`; 24,785 assets; 0 catalog diagnostics)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli resources --json > /tmp/pokemonhack-resources.json` (11 entries: 6 GBA source roots, 5 top-level GBA ROMs, 0 GameCube rows; 133 resource items)
  - `xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath DerivedData/PokemonHackStudio -destination platform=macOS test -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testResourceLibraryRefreshesWhenOpeningProjectAndFiltersEntries`
  - `make test` (72 tests)
  - `make validate`
  - `make verify`
- `PHS-T28`:
  - `swift test --package-path PokemonHackStudio --filter GenIIIAssetCatalogTests` (5 tests)
  - `swift test --package-path PokemonHackStudio --filter SourceIndexTests` (7 tests)
  - `swift test --package-path PokemonHackStudio --filter GraphicsDiagnosticsTests` (5 tests)
  - `xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath DerivedData/PokemonHackStudio -destination platform=macOS test -only-testing:PokemonHackStudioTests/MapEditorStoreTests`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli resources --json` (11 entries: 6 GBA source roots, 5 top-level GBA ROMs, 0 GameCube rows; 0 top-level diagnostics; 0 warning/error entry diagnostics)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli asset-index pokeemerald --json` (`pokeemerald`; 31,874 assets; 0 catalog diagnostics; 0 required-source availability blockers)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli asset-index pokefirered --json` (`pokefirered`; 31,423 assets; 0 catalog diagnostics; 0 required-source availability blockers)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli asset-index references/pokeruby --json` (`pokeruby`; 24,785 assets; 0 catalog diagnostics; 0 required-source availability blockers)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli asset-index references/pokefirered --json` (`pokefirered`; 19,389 assets; 0 catalog diagnostics; 0 required-source availability blockers)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli asset-index references/pokeemerald-expansion --json` (`pokeemeraldExpansion`; 70,680 assets; 0 catalog diagnostics; 0 required-source availability blockers)
  - `make test` (80 tests)
  - `make validate`
  - `make verify`
  - Manual app smoke: launched the built macOS app, opened Resources from the sidebar, and confirmed the app stayed responsive with the GBA-only Resources library available.
  - `git diff --check`
- `PHS-T29`:
  - `swift test --package-path PokemonHackStudio --filter MapEditorSessionTests` (build succeeded, but SwiftPM reported `No matching test cases were run`; session tests remain app-target-only rather than package-discovered)
  - `xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath DerivedData/PokemonHackStudio -destination platform=macOS build`
  - `make test` (77 tests)
  - `make verify`
  - Manual app smoke: launched the built macOS app, opened Maps on `pokeemerald`, verified the tools now live in the top Maps chrome at 1280 x 800 and 1700 x 900, selected `Route101`, selected Paint, opened the compact map browser popover, and confirmed the canvas keeps only the live brush/hover/zoom HUD over the map.
  - `git -C pokeemerald status --short` stayed clean.
  - `git diff --check`
- `PHS-T30`:
  - Baseline unblock: renamed the older lightweight `PatchManifest` scaffolding type so the newer core `PatchManifest` model can compile.
  - `swift test --package-path PokemonHackStudio --filter ToolchainHealthMatrixTests` (3 tests)
  - `make test` (86 tests)
  - `xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath DerivedData/PokemonHackStudio -destination platform=macOS test`
  - `make validate`
  - `make verify`
  - App smoke: `make verify` regenerated the Xcode project, built, signed, launched, and verified the macOS app; manual Settings smoke opened `Cmd-,`, confirmed the Health tab, and confirmed Project/Tools/View appear as single native menus.
- `PHS-T31`:
  - `swift test --package-path PokemonHackStudio --filter TrainerCatalogTests` (6 tests)
  - `swift test --package-path PokemonHackStudio --filter PokemonSpeciesCatalogTests` (4 tests; stale compile check)
  - `make test` (95 tests)
  - `xcodebuild -quiet -project PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath ../DerivedData/PokemonHackStudio -destination 'platform=macOS,arch=arm64' -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testTrainerCatalogLoadsSelectionAndFilteringIntoStore -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testTrainerDraftPreviewContextApplyAndDiscardFlow test` (2 app-store tests)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli trainer-catalog pokeemerald --json > /tmp/pokemonhack-pokeemerald-trainer-catalog.json` (`855` trainers; `854` editable; `1` read-only `TRAINER_NONE`; `437` default learnsets; `4,156,190` bytes)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli trainer-catalog pokefirered --json > /tmp/pokemonhack-pokefirered-trainer-catalog.json` (`743` trainers; `639` editable; `104` read-only legacy RS placeholder macro parties plus `TRAINER_NONE`; `437` default learnsets; `4,338,585` bytes)
  - `make validate`
  - `make verify`
  - Manual app smoke: opened Trainers on repo-local `pokeemerald`, selected `TRAINER_SAWYER_1`, confirmed the workbench shows inherited default moves, editable move-overrides toggle, six IV fields, nature picker with classic-source diagnostics, and selected-trainer-only inspector diagnostics.
  - `git -C pokeemerald status --short` and `git -C pokefirered status --short` stayed clean.
  - `git diff --check`
- `PHS-T32`:
  - `swift test --package-path PokemonHackStudio --filter PokemonSpeciesCatalogTests` (4 tests)
  - `xcodebuild test -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -destination 'platform=macOS' -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testSpeciesDraftPreviewContextApplyAndDiscardFlow`
  - `make test` (95 tests)
  - `make validate`
  - `make verify`
  - `git diff --check`
- `PHS-T33`:
  - `make test` (95 tests)
  - `cd PokemonHackStudio && xcodegen generate`
  - `xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath DerivedData/PokemonHackStudio -destination platform=macOS test`
  - `make verify`
  - `git diff --check`
  - Manual app smoke at 1280 x 800 with the app sidebar visible: opened Dashboard, Resources, Pokemon, Trainers, Maps, Scripts, Build/Patch/Playtest, and Settings; confirmed wrapped Resources controls, compact Pokemon/Trainers browser buttons, Trainer source previews collapsed by default, primary toolbar actions visible, and no obvious clipping or overlap.
  - Manual app smoke at approximately 1700 x 900: confirmed the wide Resources shell restores the split layout with the source inspector available.
  - Mutation/source-write smoke: no apply/source-write action was invoked; preview/discard gates remain routed through the existing mutation-plan panel and app-store tests.
- `PHS-T34`:
  - `bash -n script/bundle_app_assets.sh`
  - Temporary fixture smoke for `script/bundle_app_assets.sh`: copied safe `graphics`, `data`, and `src/data` inputs, wrote `PokemonHackStudioAssets/manifest.json`, and verified nested `.gba` plus build-output `.o` files were excluded.
  - `make verify` (regenerated the Xcode project, built, signed, launched, and verified the macOS app; the Xcode build phase bundled 2 local source projects into `Contents/Resources/PokemonHackStudioAssets`)
  - Bundle artifact proof: `Contents/Resources/PokemonHackStudioAssets/Projects` contained 32,505 files / 164M from local `pokeemerald` and `pokefirered`; `data/maps/map_groups.json` and `graphics/` existed for both projects; `.gba` and `.o` files were absent; `jq empty` validated the generated manifest JSON.
  - `make test` (95 tests)
- `PHS-T16` / `PHS-T19` / `PHS-T20` / `PHS-T22` / `PHS-T24` reference-informed follow-through:
  - `swift test --package-path PokemonHackStudio --filter PokemonDataGraphTests` (2 tests)
  - `swift test --package-path PokemonHackStudio --filter BuildPatchPlaytestValidationTests` (8 tests)
  - `swift test --package-path PokemonHackStudio --filter MapVisualTests` (24 tests)
  - `swift test --package-path PokemonHackStudio --filter PokemonSpeciesCatalogTests` (1 test; rechecked source-order learnset preservation)
  - `make test` (86 tests)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli pokemon-catalog pokeemerald --json | jq '{speciesCount, treecko:(.species[]|select(.speciesID=="SPECIES_TREECKO")|{displayName, evYield:.evYield, growthRate:.training.growthRate, levelMoves:(.learnsets.levelUp|length), tmhm:(.learnsets.tmhm|length), egg:(.learnsets.egg|length), assets:(.assets|map(select(.exists == true))|length)})}'` (`speciesCount: 412`; Treecko speed EV 1; growth `GROWTH_MEDIUM_SLOW`; 11 level-up moves; 25 TM/HM moves; 6 egg moves; 7 local assets)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli pokemon-catalog pokefirered --json | jq '{speciesCount, bulbasaur:(.species[]|select(.speciesID=="SPECIES_BULBASAUR")|{displayName, evYield:.evYield, growthRate:.training.growthRate, levelMoves:(.learnsets.levelUp|length), tmhm:(.learnsets.tmhm|length), egg:(.learnsets.egg|length), assets:(.assets|map(select(.exists == true))|length)})}'` (`speciesCount: 412`; Bulbasaur Sp. Attack EV 1; growth `GROWTH_MEDIUM_SLOW`; 11 level-up moves; 19 TM/HM moves; 8 egg moves; 6 local assets)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli moves-graph pokeemerald --json > /tmp/phs-moves.json` (`674,422` bytes)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli species-graph pokeemerald --json > /tmp/phs-species.json` (`3,406,342` bytes)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli map-visual pokeemerald MAP_MAUVILLE_CITY --json > /tmp/phs-map-visual.json` (`2,049,379` bytes)
  - `swift run --package-path PokemonHackStudio pokemonhack-cli patch-manifest pokeemerald <synthetic APS patch> --json > /tmp/phs-patch-manifest.json` (`1,539` bytes)
  - `make validate` (includes `moves-graph`, `species-graph`, and synthetic/project-backed `patch-manifest` smokes)
  - `make verify` (regenerated the Xcode project, built, signed, and launched the macOS app target with the Data > Pokemon workbench compiled in)
  - Manual app smoke: opened Data > Pokemon on repo-local `pokeemerald`, confirmed the dedicated species browser and workbench render, selected Bulbasaur and Chimecho, and verified local front/back/icon/footprint/animation asset previews, stats, EV yields, training/breeding data, level-up learnsets, TM/HM and egg counts, Pokedex/source links, and asset availability rows.
