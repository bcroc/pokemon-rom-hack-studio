# Reference Synthesis

PokemonHackStudio is intended to become an all-in-one, Apple Silicon native Pokemon Generation III ROM hacking workbench. The reference repos are a product and compatibility map, not a source pool. Default adoption is clean-room Swift implementation unless a future license review explicitly approves copying code, schemas, assets, tests, or UI text.

## Product Direction

- Source-tree editing is the high-fidelity path. Decomp projects preserve reviewable diffs, build reproducibility, and source locations for every object.
- Binary ROM workflows are support workflows for inspection, patching, legacy import/export, migration, and compatibility.
- Writes must be staged as mutation plans with diagnostics and diffs before any apply/export action.
- Commercial ROMs, generated ROMs, decomp game assets, and unlicensed expansion content stay local and user-supplied.

## Repo Findings

| Reference | Best Features | Adoption Decision | Reuse Posture |
| --- | --- | --- | --- |
| Porymap | Decomp project graph, map/layout/event editing, wild encounters, configurable block masks, stable JSON writes, file watchers, paint-style tools | Adapt behavior into Swift map/layout indexer and editor | LGPL-3.0; behavioral reference only by default |
| Poryscript | Structured script language, AST/source spans, text wrapping, diagnostics, line markers, movement/mart/mapscript builders | Adapt concepts for script/text workbench and compatibility import/export | MIT; code reuse possible only after attribution review |
| Porytiles | Editable source vs compiled tileset model, metatile layers, palette packing, animation diagnostics, checksum-safe writes | Adapt architecture and diagnostics into graphics/tileset module | MIT; clean-room Swift preferred |
| Hex Maniac Advance | Semantic ROM graph over bytes, runs, anchors, pointer graph, metadata sidecar, goto, diff, backup, repointing | Adopt product pattern for binary ROM adapter | MIT; audit before copying metadata/scripts/resources |
| Pokemon Game Editor | Legacy all-in-one binary domains: species, moves, items, trainers, Pokedex, sprites, icons, footprints, cries, INI/PNG/WAV import/export | Observe and modernize workflows; use as migration checklist | Custom restrictive license; observe only |
| RomPatcher.js | IPS/BPS/UPS/APS-GBA workflows, checksum UX, patch packs, archive detection, worker split | Adapt patch model; make BPS preferred output | MIT plus third-party notices; clean-room parser preferred |
| mGBA | Native emulator core, headless runner, debugger, GDB, Lua concepts, savestates, screenshots, access logs, patch loading | Integrate via external tool first, embedded bridge later | MPL-2.0; preserve file-level obligations if distributed |
| pokeemerald-expansion | Modern mechanics, expanded species/moves/items/trainers, config gates, tests, migration scripts, save-aware constraints | Treat as Expansion adapter with schema-rich source graph | No root license found; reference-only unless clarified |
| pokeruby | Ruby/Sapphire decomp layout, target matrix, localization overlays, C data, macro scripts, map JSON differences | Add separate Ruby/Sapphire adapter | No root license found; user-supplied project input only |

## Feature Matrix

| Capability | Primary References | PokemonHackStudio Surface |
| --- | --- | --- |
| Project detection and indexing | Porymap, pret repos, Expansion | `GameAdapter`, `ProjectIndex`, source documents, generated outputs |
| Map/layout editing | Porymap, pokeruby, pokeemerald-expansion | Map canvas, event overlays, connections, warps, wild encounters, layout block masks |
| Script/text editing | Poryscript, pret repos, HMA | Script outline, text diagnostics, generated `.inc` preview, movement/mart builders |
| Tilesets/graphics | Porytiles, Porymap, PGE, HMA | Metatile layers, palette workbench, animation timeline, PNG/PAL/BIN import/export |
| Species/trainers/items/moves | Expansion, PGE, HMA, pokeruby | Source-aware form editors with C initializer/trainer-party parsers |
| Binary ROM graph | HMA, PGE | ROM image inspector, runs, anchors, pointers, free-space and repoint planning |
| Patch pipeline | RomPatcher.js, HMA, mGBA | IPS/BPS/UPS/APS-GBA parse/apply/export, checksum validation, patch manifests |
| Build and validation | pret repos, Expansion | Make target previews, generated freshness, diagnostics, build logs, memory usage |
| Playtest/debug | mGBA, Expansion tests | Run Hack, headless test plan, screenshots, savestates, symbols, break/watchpoints |
| Migration/import | PGE, Expansion migration scripts, Porytiles | INI/PNG/WAV import, migration dry runs, source span preserving rewrites |

## Implementation Lanes

### 1. Decomp Project Graph

The decomp graph indexes project-relative source documents, generated outputs, maps, layouts, scripts, constants, C initializer tables, graphics, trainer data, and build targets. Adapters own profile-specific paths and generated-file policy.

Initial adapters:

- `EmeraldAdapter`
- `FireRedAdapter`
- `RubySapphireAdapter`
- `ExpansionAdapter`

### 2. Binary ROM Graph

The ROM graph treats a `.gba` as a local input and exposes staged inspection and patch planning. It should grow around byte-range runs, GBA pointers, anchors, checksums, metadata, and diff/export workflows. Binary edits stay plan-only until explicit export.

Initial adapter:

- `BinaryROMAdapter`

### 3. Build And Patch Pipeline

The build lane previews and later executes project-local make targets. The patch lane parses and validates patch files, then creates patch manifests and export plans. BPS should be the preferred shareable patch format because it carries source and target checksums.

### 4. Emulator And Playtest Bridge

The playtest lane starts as an external mGBA handoff and can later become an embedded ARM64 bridge. Interactive and headless modes should stay separate: play is user-facing, while headless tests are automation-facing.

## First Vertical Slices

1. Project dashboard backed by `ProjectIndex`.
2. Map/layout viewer for `map_groups.json` and `layouts.json`.
3. Script/text outline and diagnostics.
4. Trainer/species/item/move C initializer indexing.
5. Base ROM inspector and patch summary parser.
6. Build target preview and non-mutating validation report.
7. Headless playtest plan that can later call mGBA.

## Guardrails

- Preserve unknown JSON fields and stable ordering for source-tree round trips.
- Treat generated files as caches unless an adapter marks them as source.
- Store project-relative paths and source spans in diagnostics and mutation plans.
- Show save/layout/text/capacity warnings before writes.
- Keep mGBA, GPL tools, LGPL tools, custom-licensed code, and unlicensed game assets behind clear distribution boundaries.
