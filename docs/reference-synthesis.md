# Reference Synthesis

PokemonHackStudio is intended to become an all-in-one, Apple Silicon native Pokemon GBA + NDS ROM hacking workbench. The reference repos are a product and compatibility map, not a source pool. Default adoption is clean-room Swift implementation unless a future license review explicitly approves copying code, schemas, assets, tests, or UI text.

The May 12, 2026 central reference-corpus refresh made `/Users/bryan/projects/reference-repos` canonical for PokemonHackStudio reference metadata and clones. Use `docs/index.json` and per-repo central profiles there for current HEAD, license posture, reuse class, and tags. The ignored local `references/*` paths are compatibility aliases to central clone roots, while active editable decomp source trees in the PokemonHackStudio working folder remain local project inputs. The later May 12 expansion added central profiles for additional NDS, Gen III binary extraction, CFRU, devkitPro, tilemap, and alternate emulator/debugger references without adding product code. Selected DS/NDS and emulator/tooling entries now also have local `references/*` compatibility aliases, while binary-extraction, CFRU, and devkitPro additions remain central-profile-first. The May 14, 2026 central index snapshot records 129 unique repositories and 59 PokemonHackStudio-tagged profiles; the product-local `references/manifest.json` remains the original 30-entry bench unless a future row explicitly adds compatibility aliases.

## Product Direction

- Source-tree editing is the high-fidelity path. Decomp projects preserve reviewable diffs, build reproducibility, and source locations for every object.
- Binary ROM and GameCube-era media workflows are support workflows for inspection, patching, legacy import/export, migration, and compatibility.
- Writes must be staged as mutation plans with diagnostics and diffs before any apply/export action.
- Commercial ROMs, generated ROMs, decomp game assets, and unlicensed expansion content stay local and user-supplied.

## Repo Findings

| Reference | Best Features | Adoption Decision | Reuse Posture |
| --- | --- | --- | --- |
| Porymap | Decomp project graph, map/layout/event editing, wild encounters, configurable block masks, stable JSON writes, file watchers, paint-style tools | Adapt behavior into Swift map/layout indexer and editor | LGPL-3.0; behavioral reference only by default |
| Poryscript | Structured script language, AST/source spans, text wrapping, diagnostics, line markers, movement/mart/mapscript builders | Adapt concepts for script/text workbench and compatibility import/export; central profile `huderlem__poryscript` tracks current HEAD | MIT; code reuse possible only after attribution review |
| Porytiles | Editable source vs compiled tileset model, metatile layers, palette packing, animation diagnostics, checksum-safe writes | Adapt architecture and diagnostics into graphics/tileset module; central profile `grunt-lucas__porytiles` tracks current HEAD | MIT; clean-room Swift preferred |
| pokeemerald | Canonical Emerald source tree, generated map artifacts, table/header/script paths, build outputs, and SHA1 target expectations | Use central profile `pret__pokeemerald` as the primary Emerald adapter compatibility target | No root license found; read-only interoperability/reference only |
| pokefirered | Canonical FireRed/LeafGreen source tree, revision-specific build targets, generated map artifacts, and FireRed data-shape differences | Use central profile `pret__pokefirered` as the primary FireRed/LeafGreen adapter compatibility target | No root license found; read-only interoperability/reference only |
| agbcc | pret compiler/toolchain shape and setup scripts used by decomp builds | Treat central profile `pret__agbcc` as the external toolchain boundary reference for validation and setup checks | Mixed GCC/newlib notices; external toolchain research only |
| Hex Maniac Advance | Semantic ROM graph over bytes, runs, anchors, pointer graph, metadata sidecar, goto, diff, backup, repointing | Adopt product pattern for binary ROM adapter | MIT; audit before copying metadata/scripts/resources |
| Pokemon Game Editor | Legacy all-in-one binary domains: species, moves, items, trainers, Pokedex, sprites, icons, footprints, cries, INI/PNG/WAV import/export | Observe and modernize workflows; use as migration checklist | Custom restrictive license; observe only |
| RomPatcher.js | IPS/BPS/UPS/APS-GBA workflows, checksum UX, patch packs, archive detection, worker split | Adapt patch model; make BPS preferred output | MIT plus third-party notices; clean-room parser preferred |
| mGBA | Native emulator core, headless runner, debugger, GDB, Lua concepts, savestates, screenshots, access logs, patch loading | Integrate via external tool first, embedded bridge later | MPL-2.0; preserve file-level obligations if distributed |
| pokeemerald-expansion | Modern mechanics, expanded species/moves/items/trainers, config gates, tests, migration scripts, save-aware constraints | Treat as Expansion adapter with schema-rich source graph | No root license found; reference-only unless clarified |
| pokeruby | Ruby/Sapphire decomp layout, target matrix, localization overlays, C data, macro scripts, map JSON differences | Use central profile `pret__pokeruby`; no separate Sapphire clone is needed for the Ruby/Sapphire adapter | No root license found; user-supplied project input only |
| Porylive | Live script editing loop for decomps and emulator-adjacent iteration | Convert into a read-only live-readiness report before any hot reload feature | No root license found; workflow reference only |
| PoryMoves | Focused move and learnset editing workflow | Use to scope moves/learnset source graph and later mutation-plan editors | No root license found; observe only |
| porypal | Sprite/palette conversion workflow, GBA color constraints, and decomp asset-prep affordances | Use central profile `loxed__porypal` as clean-room input for palette diagnostics and preview-only conversion plans | GPL-3.0; behavioral or external-tool reference only |
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
| pret NDS decomps (`pokediamond`, `pokeplatinum`, `pokeheartgold`) | Gen IV source-tree shapes, NitroFS roots, build metadata, expected output names, and version-specific directories | Use for NDS decomp detection and read-only source catalog planning | No code, schemas, tests, or assets copied; reference-only local corpus |
| DSPRE, PokEditor-v2, Pokeweb, SkyTemple | NDS ROM editor workflows, NitroFS/NARC tooling expectations, and external-tool boundary pressure | Use current central profile `ds-pokemon-rom-editor__dspre` for live DSPRE behavior, keep `adastra-ld__ds-pokemon-rom-editor` as lineage/stable-reference context, and use all as UX/toolchain planning inputs only | High-risk/observational; V1 uses clean-room Swift parsers with synthetic fixtures |
| ndspy | NDS ROM, NitroFS, overlay, NARC, compression, BMG, sound, and texture-container behavior | Use central profile `roadrunnerwmc__ndspy` to pressure-test clean-room NDS parser terminology and edge cases | GPL-3.0; reference-only |
| NitroPaint | DS graphics/resource editor coverage for NCLR, NCGR, NSCR, NCER, NANR, NFTR, BMG, NSBMD, NSBTX, and compression | Use central profile `garhoogin__nitropaint` for NDS graphics catalog and preview vocabulary | BSD-2-Clause; adaptation requires attribution review |
| DS Pokemon Rom Editor / Pokemon DS Map Studio / PPRE | Gen IV/V editor UX around extracted directories, NARC pack/unpack, maps, scripts, trainers, personal data, learnsets, and historical generator workflows | Use central profiles `adastra-ld__ds-pokemon-rom-editor`, `trifindo__pokemon-ds-map-studio`, and `projectpokemon__ppre` as observational editor/workflow pressure | No root license detected or high-risk lineage; reference-only |
| pkmn-rom-extract | Modern Rust Gen III binary ROM asset extraction across titles, languages, and revisions | Use central profile `ayashibox__pkmn-rom-extract` to pressure-test standalone binary asset catalog assumptions | MIT OR Apache-2.0; adaptation still needs attribution review |
| Complete Fire Red Upgrade | FireRed binary-expansion ecosystem, config gates, battle hooks, patch/build expectations, and save-expansion pressure | Use central profile `skeli789__complete-fire-red-upgrade` as a high-risk CFRU compatibility reference | No root license detected and game-derived/binary dependencies; reference-only |
| devkitPro libgba/buildscripts | GBA library, hardware headers, setup, package/build scripts, and devkitARM health-check expectations | Use central profiles `devkitpro__libgba` and `devkitpro__buildscripts` for external toolchain diagnostics only | LGPL-style/custom or no root license; reference-only |
| Tilemap Studio, BizHawk, VisualBoyAdvance-M | Tilemap editor UX, emulator automation, alternate debugger/logging, link behavior, savestates, and playtest assumptions | Use central profiles `rangi42__tilemap-studio`, `tasemulators__bizhawk`, and `visualboyadvance-m__visualboyadvance-m` to avoid mGBA/Porytiles-only assumptions | LGPL/GPL/mixed-license; external or behavioral reference-only |
| Gen V candidate references (`pokeblack`, SwissArmyKnife, CTRMap-CE, Pokeweb) | BW/BW2 source-tree pressure, map containers, text/script/zone entities, encounters, hotswap/project workflows, and plugin-style level editing | Queue in central corpus before product adoption; use only to shape future Gen V source/project detection and readiness rows | High-risk or unknown until profiled; reference-only by default |
| DS container/audio/text candidates (TinkeDSi, NitroStudio2, Kuriimu2, EveryFileExplorer, dsdecmp) | NARC/BMG/SDAT/graphics/container browsing, text encodings, compression behavior, and broad Nintendo format vocabulary | Queue as central reference candidates to pressure-test `PHS-T94`, `PHS-T97`, and `PHS-T100` without copying code or schemas | GPL/unknown/mixed until profiled; observational or external-tool only |

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
| NDS resource graph | pret NDS decomps, DSPRE/PokEditor/Pokeweb/SkyTemple workflow posture, ndspy, NitroPaint, DS Pokemon Rom Editor, Pokemon DS Map Studio, PPRE, queued Tinke/Kuriimu/container candidates | `.nds` header, NitroFS FNT/FAT browser, overlay table facts, NARC archive/member inventory, pret-style NDS source-tree index, read-only Gen IV data catalog rows, read-only diagnostics |
| Patch pipeline | RomPatcher.js, HMA, mGBA | IPS/BPS/UPS/APS-GBA parse/apply/export, checksum validation, patch manifests |
| Build and validation | pokeemerald, pokefirered, pokeruby, Expansion, agbcc, devkitPro libgba/buildscripts | Make target previews, toolchain checks, generated freshness, diagnostics, build logs, memory usage |
| Playtest/debug | mGBA, BizHawk, VisualBoyAdvance-M, melonDS/DeSmuME candidates, Expansion tests | Run Hack, headless test plan, screenshots, savestates, symbols, break/watchpoints |
| Migration/import | PGE, Expansion migration scripts, Porytiles, pkmn-rom-extract | INI/PNG/WAV import, migration dry runs, source span preserving rewrites, `migration-coverage <path> --json` source-first/binary-only diagnostics |
| Asset import/provenance | Team Aqua Asset Repo, Porytiles, porypal, PGE | Local asset catalog, credit metadata, conversion boundaries, no bundled third-party assets |

## Reference-Review Candidate Queue

The May 12, 2026 subagent review against the dirty tree did not reopen shipped rows. The later NDS/reference push completed `PHS-T94` through `PHS-T101`, so the current queue should strengthen validation and migration coverage before widening more writers:

- `PHS-T73`: patch apply/export should write only ignored output ROMs plus backup/export manifests after explicit user action; source-tree mutation remains out of scope.
- `PHS-T76`: Poryscript follow-through starts with `.pory` detection, generated `.inc` relationships, poryswitch/line-marker facts, and blocked compiler/apply guidance.
- `PHS-T78`: Expansion work should split into one semantic writer family at a time instead of a broad adapter rewrite.
- `PHS-T79`: binary mutation needs preflight, manifest, backup, hash-drift refusal, and mutation-plan review before any ROM byte write.
- `PHS-T92` and `PHS-T93`: ROM-only work remains migration/extraction planning and source-first coverage diagnostics before export or extraction writers; the first shared diagnostic surface is `migration-coverage <path> --json`.
- `PHS-T94` through `PHS-T101`: completed NDS read-only catalog, preview, and manual workflow rows remain the baseline; future NDS work should expand one semantic domain at a time, starting with Platinum before HGSS/DP.

Preferred next implementation picks are `PHS-T83` for related-record context panels, then narrow compatibility splits from `PHS-T57`, plus bounded `PHS-T75`, `PHS-T84`, `PHS-T76`, and `PHS-T77` authoring rows. Keep `PHS-T93` coverage diagnostics ahead of `PHS-T92` ROM asset migration planning.

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

### 3A. NDS Resource Graph

NDS support extends the resource library and project profile model with read-only `.nds` inputs and read-only pret-style NDS source-tree roots. The first native Swift parser surface covers the NDS header, NitroFS FNT/FAT file listing, ARM9/ARM7 overlay table metadata, and NARC archive/member listings. The source-tree index surface detects Diamond/Pearl, Platinum, HeartGold/SoulSilver, and PMD-Sky roots, then reports markers, variants, checksums, NitroFS manifests, and build-target metadata without enabling editors or rebuilds. The first Gen IV data catalog adds read-only source/path rows for Platinum, HeartGold/SoulSilver, and Diamond/Pearl while keeping PMD-Sky as spin-off inventory only. Source-tree workflows stay the target path for Gen IV editing, while binary-only NDS writes remain disabled until mutation-plan models exist.

Initial adapters/parsers:

- `NDSROMAdapter`
- `NDSDecompAdapter`
- `NDSROMHeaderParser`
- `NitroFSIndexBuilder`
- `NDSOverlayTableIndexBuilder`
- `NARCParser`
- `NDSDecompSourceTreeIndexBuilder`
- `NDSDataCatalogBuilder`

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
10. Read-only NDS ROM resource inspector for `.nds` header facts, NitroFS files, overlay metadata, and NARC archives.
11. Read-only NDS source-tree detector for pret Diamond/Pearl, Platinum, HeartGold/SoulSilver, and PMD-Sky roots.
12. Read-only Gen IV source data catalog for Platinum, HeartGold/SoulSilver, and Diamond/Pearl source/path summaries, with PMD-Sky spin-off inventory diagnostics.

## Reference Follow-Up State

The first broad reference sweep rows are now historical context, and the app baseline has continued well past this snapshot. Keep this section as reference rationale only; use `docs/planning-and-progress.md` as the live workboard before choosing new work.

| ID | State | Reference Signal | Result |
| --- | --- | --- | --- |
| `PHS-T19` | Done | PoryMoves, pret repos, Expansion | Move and learnset graph with source spans, diagnostics, CLI JSON, and Pokemon workbench consumption. |
| `PHS-T20` | Done | Universal-GBA-Pokedex, PokeData, Expansion, PGE | Species/evolution/Pokedex/assets graph plus detailed Data > Pokemon surfaces. |
| `PHS-T21` | Done | Porylive, Poryscript, mGBA | `script-readiness` report for selected map/script build and playtest prerequisites. |
| `PHS-T22` | Done | RomPatcher.js, berry-fix, cfru-generator | Patch/base-ROM manifest model with checksums, compatibility notes, and dry-run plans. |
| `PHS-T23` | Done | agbcc, gba-tools, grit, libtonc, pret repos | External-tool, ROM-header, graphics-conversion, and generated-artifact health matrix. |
| `PHS-T24` | Done | mGBA, Porylive | Playtest handoff artifacts and later `PHS-T40` explicit external mGBA launch. |
| `PHS-T25` | Done | PorySuite, HMA, PGE, PokeData | Cross-linked Resources navigation across maps, scripts, species, trainers, graphics, build rows, text, and items. |

Current follow-up work is tracked on the live board, especially `PHS-T57` compatibility-specific data editors and newer Candidate rows such as `PHS-T68` species asset import validation. Rows `PHS-T17`, `PHS-T41`, `PHS-T42`, `PHS-T43`, and `PHS-T44` are no longer deferred in the live workboard.

## Guardrails

- Preserve unknown JSON fields and stable ordering for source-tree round trips.
- Treat generated files as caches unless an adapter marks them as source.
- Store project-relative paths and source spans in diagnostics and mutation plans.
- Show save/layout/text/capacity warnings before writes.
- Treat GameCube disc images and FSYS/LZSS members as read-only local inputs until a later mutation/export policy exists.
- Treat NDS ROMs, NDS source-tree roots, NitroFS files, overlay tables, and NARC members as read-only local inputs until a later mutation/export policy exists.
- Keep mGBA, GPL tools, LGPL tools, custom-licensed code, and unlicensed game assets behind clear distribution boundaries.
