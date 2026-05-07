# Reference Synthesis

PokemonHackStudio is intended to become an all-in-one, Apple Silicon native Pokemon Generation III ROM hacking workbench. The reference repos are a product and compatibility map, not a source pool. Default adoption is clean-room Swift implementation unless a future license review explicitly approves copying code, schemas, assets, tests, or UI text.

## Product Direction

- Source-tree editing is the high-fidelity path. Decomp projects preserve reviewable diffs, build reproducibility, and source locations for every object.
- Binary ROM and GameCube-era media workflows are support workflows for inspection, patching, legacy import/export, migration, and compatibility.
- Writes must be staged as mutation plans with diagnostics and diffs before any apply/export action.
- Commercial ROMs, generated ROMs, decomp game assets, and unlicensed expansion content stay local and user-supplied.

## Repo Findings

| Reference | Best Features | Adoption Decision | Reuse Posture |
| --- | --- | --- | --- |
| Porymap | Decomp project graph, map/layout/event editing, wild encounters, configurable block masks, stable JSON writes, file watchers, paint-style tools | Adapt behavior into Swift map/layout indexer and editor | LGPL-3.0; behavioral reference only by default |
| Poryscript | Structured script language, AST/source spans, text wrapping, diagnostics, line markers, movement/mart/mapscript builders | Adapt concepts for script/text workbench and compatibility import/export | MIT; code reuse possible only after attribution review |
| Porytiles | Editable source vs compiled tileset model, metatile layers, palette packing, animation diagnostics, checksum-safe writes | Adapt architecture and diagnostics into graphics/tileset module | MIT; clean-room Swift preferred |
| pokeemerald | Canonical Emerald source tree, generated map artifacts, table/header/script paths, build outputs, and SHA1 target expectations | Use as the primary Emerald adapter compatibility target | No root license found; read-only interoperability/reference only |
| pokefirered | Canonical FireRed/LeafGreen source tree, revision-specific build targets, generated map artifacts, and FireRed data-shape differences | Use as the primary FireRed adapter compatibility target | No root license found; read-only interoperability/reference only |
| agbcc | pret compiler/toolchain shape and setup scripts used by decomp builds | Treat as external toolchain boundary for validation and setup checks | Mixed GCC/newlib notices; external toolchain research only |
| Hex Maniac Advance | Semantic ROM graph over bytes, runs, anchors, pointer graph, metadata sidecar, goto, diff, backup, repointing | Adopt product pattern for binary ROM adapter | MIT; audit before copying metadata/scripts/resources |
| Pokemon Game Editor | Legacy all-in-one binary domains: species, moves, items, trainers, Pokedex, sprites, icons, footprints, cries, INI/PNG/WAV import/export | Observe and modernize workflows; use as migration checklist | Custom restrictive license; observe only |
| RomPatcher.js | IPS/BPS/UPS/APS-GBA workflows, checksum UX, patch packs, archive detection, worker split | Adapt patch model; make BPS preferred output | MIT plus third-party notices; clean-room parser preferred |
| mGBA | Native emulator core, headless runner, debugger, GDB, Lua concepts, savestates, screenshots, access logs, patch loading | Integrate via external tool first, embedded bridge later | MPL-2.0; preserve file-level obligations if distributed |
| pokeemerald-expansion | Modern mechanics, expanded species/moves/items/trainers, config gates, tests, migration scripts, save-aware constraints | Treat as Expansion adapter with schema-rich source graph | No root license found; reference-only unless clarified |
| pokeruby | Ruby/Sapphire decomp layout, target matrix, localization overlays, C data, macro scripts, map JSON differences | Add separate Ruby/Sapphire adapter | No root license found; user-supplied project input only |
| Porylive | Live script editing loop for decomps and emulator-adjacent iteration | Convert into a read-only live-readiness report before any hot reload feature | No root license found; workflow reference only |
| PoryMoves | Focused move and learnset editing workflow | Use to scope moves/learnset source graph and later mutation-plan editors | No root license found; observe only |
| porypal | Palette workflow, GBA color constraints, and conversion affordances | Use as clean-room input for palette diagnostics and preview-only conversion plans | GPL-3.0; behavioral reference only |
| PorySuite | All-in-one source editor grouping and project navigation | Use to pressure-test PokemonHackStudio's module grouping and cross-linked data surfaces | No root license found; UX/product reference only |
| Team Aqua Asset Repo | Asset organization, credits, and community provenance | Add asset import/credit metadata planning before any import/export writes | No root license found; assets stay local/reference-only |
| libtonc | GBA tile, palette, VRAM, and ROM-header fundamentals | Use for diagnostics language and hardware constraints | MIT; cite/review before copying prose or code |
| gba-tools | ROM header and toolchain utilities | Add ROM header/toolchain diagnostics as external-tool checks | GPL-3.0; external/reference-only |
| grit | Graphics conversion boundaries, tilemap reduction, palette conversion, compression outputs | Model external conversion plans and generated-artifact freshness without invoking grit | GPL-2.0; external/reference-only |
| pokeemerald-jp | Localization and source-layout variation | Keep adapters tolerant of localized project differences | No root license found; compatibility reference only |
| berry-fix | Patch/update distribution and validation flow | Use for patch manifest and base-ROM compatibility thinking | No root license found; reference-only |
| Modern Emerald | Feature-fork source-shape pressure | Use to avoid hardcoding pret-only table and config assumptions | No root license found; reference-only |
| Dynamic Pokemon Expansion | Expanded data and binary/decomp bridge pressure | Use for future expansion compatibility matrix | License requires review; reference-only |
| cfru-generator | Expansion patch/config generation | Use to scope patch manifest and compatibility checks | Apache-2.0; clean-room preferred |
| PokeMapExport | Map export expectations | Later visual export planning, not current source mutation | GPL-3.0; behavioral reference only |
| Universal-GBA-Pokedex | Pokedex/species browsing and cross-game data presentation | Use for Pokedex/species explorer ergonomics | MIT; data provenance review needed |
| Frame | ROM data model and editor architecture | Use as binary graph architecture pressure | MIT; architecture-level reference for now |
| porydelete | Safe cleanup/deletion affordances | Use for source-tree safety checks and mutation-plan deletes | GPL-3.0; behavioral reference only |
| PokeData | Cross-linked Pokemon data/export surfaces | Use for source graph cross-links and import/export provenance checks | MIT; provenance review needed |
| PkmGCTools / public FSYS notes | GameCube disc resource inventory, Colosseum/XD FSYS and compressed-member behavior | Use as conceptual compatibility research for clean-room Swift parsers | Not cloned; no code, schemas, or assets copied |

## Feature Matrix

| Capability | Primary References | PokemonHackStudio Surface |
| --- | --- | --- |
| Project detection and indexing | Porymap, pokeemerald, pokefirered, pokeruby, Expansion | `GameAdapter`, `ProjectIndex`, source documents, generated outputs |
| Map/layout editing | Porymap, pokeruby, pokeemerald-expansion | Map canvas, event overlays, connections, warps, wild encounters, layout block masks |
| Script/text editing | Poryscript, pokeemerald, pokefirered, pokeruby, HMA | Script outline, text diagnostics, generated `.inc` preview, movement/mart builders |
| Tilesets/graphics | Porytiles, Porymap, PGE, HMA | Metatile layers, palette workbench, animation timeline, PNG/PAL/BIN import/export |
| Graphics diagnostics | Porytiles, porypal, libtonc, grit, Team Aqua Asset Repo | Artifact inventory, checksums/freshness, palette/metatile diagnostics, generated-output warnings, asset provenance |
| Species/trainers/items/moves | pokeemerald, pokefirered, Expansion, PGE, HMA, pokeruby | Source-aware form editors with C initializer/trainer-party parsers |
| Moves/learnsets/Pokedex | PoryMoves, Universal-GBA-Pokedex, PokeData, Expansion | Moves and learnset source graph, Pokedex explorer, cross-linked species/move/evolution views |
| Binary ROM graph | HMA, PGE | ROM image inspector, runs, anchors, pointers, free-space and repoint planning |
| GameCube resource graph | PkmGCTools, public FSYS notes, HMA/PGE workflow posture | Disc header, FST, DOL, FSYS archive, LZSS member, and unsupported-resource inventory |
| Patch pipeline | RomPatcher.js, HMA, mGBA | IPS/BPS/UPS/APS-GBA parse/apply/export, checksum validation, patch manifests |
| Build and validation | pokeemerald, pokefirered, pokeruby, Expansion, agbcc | Make target previews, toolchain checks, generated freshness, diagnostics, build logs, memory usage |
| Playtest/debug | mGBA, Expansion tests | Run Hack, headless test plan, screenshots, savestates, symbols, break/watchpoints |
| Migration/import | PGE, Expansion migration scripts, Porytiles | INI/PNG/WAV import, migration dry runs, source span preserving rewrites |
| Asset import/provenance | Team Aqua Asset Repo, Porytiles, porypal, PGE | Local asset catalog, credit metadata, conversion boundaries, no bundled third-party assets |

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

### 3. Generation III Resource Library

The resource library unifies local Gen III inputs without changing write policy. It auto-loads editable GBA source roots, reference manifest roots, recent roots, and safe top-level `.gba` files. GameCube `.iso`/`.gcm` parsing remains available through direct `resource-index` inputs and parser tests, but those rows are not shown in auto-loaded Resources while the product is focused on GBA assets.

Initial adapters/parsers:

- `GenIIIResourceRegistry`
- `GameCubeDiscAdapter`
- `GameCubeDiscParser`
- `FSYSArchiveParser`

### 4. Build And Patch Pipeline

The build lane previews and later executes project-local make targets. The patch lane parses and validates patch files, then creates patch manifests and export plans. BPS should be the preferred shareable patch format because it carries source and target checksums.

### 5. Emulator And Playtest Bridge

The playtest lane starts as an external mGBA handoff and can later become an embedded ARM64 bridge. Interactive and headless modes should stay separate: play is user-facing, while headless tests are automation-facing.

## First Vertical Slices

1. Project dashboard backed by `ProjectIndex`.
2. Map/layout viewer for `map_groups.json` and `layouts.json`.
3. Script/text outline and diagnostics.
4. Trainer/species/item/move C initializer indexing.
5. Base ROM inspector and patch summary parser.
6. Build target preview and non-mutating validation report.
7. Headless playtest plan that can later call mGBA.
8. Unified Gen III resource library with GameCube disc/archive parser path.
9. Source-first GBA asset catalog with fast cached Resources navigation across maps, layouts, scripts, text, species, trainers, items, moves, learnsets, evolutions, Pokedex, graphics, palettes, audio, generated outputs, and ROM metadata.

## Broad Sweep Candidate Rows

After `PHS-T15`, the broad reference sweep maps cleanly into these candidate lanes. `PHS-T18` is already occupied by the completed Generation III resource-library lane, so new broad-sweep candidates start at `PHS-T19`.

| ID | Candidate | Reference Signal | Clean-Room First Step |
| --- | --- | --- | --- |
| `PHS-T19` | Moves And Learnset Source Graph | PoryMoves, pret repos, Expansion | Read-only move/learnset index with source spans, diagnostics, and cross-links to species. |
| `PHS-T20` | Species Data Graph | Universal-GBA-Pokedex, PokeData, Expansion, PGE | Read-only species/evolution/Pokedex graph before form edits. |
| `PHS-T21` | Live Script Readiness | Porylive, Poryscript, mGBA | Report whether a selected script/map/project is ready for a future live playtest loop. |
| `PHS-T22` | Patch Manifest Workbench | RomPatcher.js, berry-fix, cfru-generator | Patch/base-ROM manifest model with checksums, compatibility notes, and no mutation by default. |
| `PHS-T23` | Toolchain Health Matrix | agbcc, gba-tools, grit, libtonc, pret repos | External-tool/version/header diagnostics and generated-artifact explanations. |
| `PHS-T24` | mGBA Playtest Bridge V2 | mGBA, Porylive | Stronger external emulator handoff, run logs, screenshots, and later headless smoke hooks. |
| `PHS-T25` | All-In-One Related Data UX | PorySuite, HMA, PGE, PokeData | Cross-linked module navigation so species, moves, trainers, maps, scripts, and graphics feel like one workspace. |

## Guardrails

- Preserve unknown JSON fields and stable ordering for source-tree round trips.
- Treat generated files as caches unless an adapter marks them as source.
- Store project-relative paths and source spans in diagnostics and mutation plans.
- Show save/layout/text/capacity warnings before writes.
- Treat GameCube disc images and FSYS/LZSS members as read-only local inputs until a later mutation/export policy exists.
- Keep mGBA, GPL tools, LGPL tools, custom-licensed code, and unlicensed game assets behind clear distribution boundaries.
