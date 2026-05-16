# Reference Repositories

The central `/Users/bryan/projects/reference-repos` corpus is the canonical research bench for Pokemon hacking tools, emulation, patching, decompilation workflows, and related DS/Gen III compatibility references. The local `references/` entries in this repo are ignored compatibility aliases to those central clone roots. Reference repos should inform architecture and compatibility, but they are not owned product code.

## Strategy

- Keep reference repos read-only during product work unless a task explicitly asks to update or inspect them.
- Use `/Users/bryan/projects/reference-repos/docs/index.json` and the central markdown profiles as the source of truth for current HEAD, license posture, reuse class, and Finder `ref.*` tags.
- Keep active editable decomp source trees in the PokemonHackStudio working folder when they are project inputs; the central corpus stores a reference copy/clone and metadata, not the live working tree.
- Use references to understand file formats, editor ergonomics, patch formats, build expectations, and user workflows.
- Summarize learned patterns in docs or issues before adopting them.
- Prefer clean-room implementation in `PokemonHackCore` when the needed behavior is small or domain-specific.
- Require license review before copying code, assets, schemas, tests, or UI text.

The project should learn from existing tools while keeping PokemonHackStudio's implementation and distribution story clean.

Detailed feature synthesis, adoption decisions, and the current implementation lanes are tracked in `docs/reference-synthesis.md`.

## Current References

The May 6, 2026 broad sweep created a 30-repo local reference bench. The May 12, 2026 centralization moved that bench into `/Users/bryan/projects/reference-repos`: central clone roots now live under `repos/<owner>__<repo>`, central profiles live under `docs/<owner>__<repo>.md`, and the central index tags every PokemonHackStudio-relevant resource with `ref.family.pokemonhackstudio` plus domain/reuse/license-risk tags. As of the May 14, 2026 central index snapshot (`docs/index.json` generated at `2026-05-14T08:45:07.156Z`), the corpus records 129 unique repositories and 59 PokemonHackStudio-tagged profiles.

Only `references/manifest.json` is tracked in this repo. The ignored `references/*` paths are compatibility symlinks to central clone roots, and each manifest entry records its central profile and current central HEAD under `centralReference`. That manifest intentionally remains the original 30-entry product bench unless a later task explicitly adds local compatibility aliases; do not expand it to all 59 central PokemonHackStudio profiles by default. For aliases that exist locally but are not in the tracked manifest, use this document plus `/Users/bryan/projects/reference-repos/docs/index.json` as the routing truth.

The May 12, 2026 reference-corpus expansion added a focused batch for current NDS, toolchain, binary-extraction, graphics, and emulator/debugger coverage. Selected DS/NDS and emulator/tooling profiles now have local `references/*` compatibility aliases for quick PokemonHackStudio routing: `references/dspre`, `references/ds-pokemon-rom-editor`, `references/ndspy`, `references/nitropaint`, `references/pokemon-ds-map-studio`, `references/ppre`, `references/pokeditor-v2`, `references/skytemple`, `references/bizhawk`, `references/visualboyadvance-m`, and `references/tilemap-studio`. The remaining expansion entries stay central-profile-first, including `ayashibox__pkmn-rom-extract`, `skeli789__complete-fire-red-upgrade`, `bivurnum__decomps-resources`, `devkitpro__libgba`, and `devkitpro__buildscripts`. The originally researched `pkmn-rom-extract` crate is indexed under the canonical repository owner `ayashibox` rather than the crates.io owner handle.

The May 12 reference-review follow-up also confirmed that current DSPRE development moved to `DS-Pokemon-Rom-Editor/DSPRE`; keep `AdAstra-LD/DS-Pokemon-Rom-Editor` as a stable historical/lineage reference and use the newer central DSPRE profile for current Gen IV editor behavior. Current lane drivers are: pret decomps for source truth; Porymap, Poryscript, Porytiles, and porypal for GBA workflow pressure; HMA, PGE, pkmn-rom-extract, and RomPatcher.js for binary, migration, and patch behavior; and DSPRE, ndspy, NitroPaint, TinkeDSi, PPRE, and Pokemon DS Map Studio for NDS pressure.

| Path | Primary Use | Notes |
| --- | --- | --- |
| `references/agbcc` | pret toolchain setup and compiler/build boundary reference | Central profile: `pret__agbcc`; mixed GCC/newlib notices; treat as external toolchain research only. |
| `references/berry-fix` | Patch/update workflow reference | No root license detected; reference-only until root and bundled-tool notices are reviewed. |
| `references/cfru-generator` | Patch/config generation and expansion workflow | Apache-2.0; clean-room preferred unless a future reuse decision is documented. |
| `references/dynamic-pokemon-expansion` | Expanded Pokemon data and binary/decomp bridge pressure | License does not map cleanly from the local scan; reference-only until reviewed. |
| `references/frame` | ROM data model and editor architecture reference | MIT; useful for architecture ideas after compatibility validation. |
| `references/gba-tools` | GBA ROM header/toolchain utility reference | GPL-3.0; keep behind external-tool and clean-room boundaries. |
| `references/grit` | Graphics conversion, tilemap, palette, and compression-boundary reference | GPL-2.0 plus bundled notices; model external-tool plans, do not embed code. |
| `references/hex-maniac-advance` | Binary ROM inspection and all-in-one editor UX | MIT; useful for safety affordances, data navigation, and binary-only fallback workflows. |
| `references/libtonc` | GBA hardware, tile, palette, and memory-layout documentation | MIT; useful for graphics and ROM-header diagnostics. |
| `references/mgba` | Emulator behavior, launch/debug workflows, patch loading expectations | MPL 2.0; useful for integration boundaries and smoke-test behavior. |
| `references/modern-emerald` | Modern Emerald feature fork and schema pressure | No root license detected; use for compatibility observations only. |
| `references/pokedata` | Pokemon data aggregation/export reference | MIT; data provenance still needs separate review. |
| `references/pokeemerald` | Canonical Emerald source layout, build outputs, generated data, and table/script formats | Central profile: `pret__pokeemerald`; no root license detected; use as read-only compatibility truth, not a code source. |
| `references/pokeemerald-expansion` | Expanded decomp content and compatibility pressure | Check upstream terms before borrowing; use as a target for schema flexibility. |
| `references/pokeemerald-jp` | Emerald localization/source-layout variation | No root license detected; read-only interoperability reference. |
| `references/pokefirered` | Canonical FireRed/LeafGreen source layout, build target variants, generated data, and adapter differences | Central profile: `pret__pokefirered`; no separate LeafGreen clone is needed; use as read-only compatibility truth. |
| `references/pokemapexport` | Visual map export workflow reference | GPL-3.0; behavioral reference only. |
| `references/pokemon-game-editor` | Legacy binary editor behavior | Custom restrictive license; treat as observational only unless reviewed. |
| `references/pokeruby` | Ruby/Sapphire pret decomp project shape | Central profile: `pret__pokeruby`; no separate Sapphire clone is needed; use to avoid overfitting core models to only Emerald and FireRed. |
| `references/porydelete` | Safe source-tree cleanup/deletion workflow reference | GPL-3.0; adopt safety checks conceptually only. |
| `references/porylive` | Live script editing and playtest-loop workflow reference | No root license detected; use behaviorally for future live-readiness planning. |
| `references/porymap` | Source-tree map editing UX for Gen 3 decomp projects | Central profile: `huderlem__porymap`; LGPL 3.0; study workflows behaviorally before borrowing implementation details. |
| `references/porymoves` | Moves and learnset workflow reference | No root license detected; observational reference for editor coverage. |
| `references/porypal` | Sprite/palette conversion and GBA color workflow reference | Central profile: `loxed__porypal`; GPL-3.0; clean-room diagnostics, UX, or external-tool reference only. |
| `references/poryscript` | Script language conventions for decomp-based event scripting | Central profile: `huderlem__poryscript`; MIT; useful for script workflow compatibility and CLI ergonomics after attribution review. |
| `references/porysuite` | All-in-one decomp editor workflow reference | No root license detected; observational UX/product reference only. |
| `references/porytiles` | Tileset and tile workflow reference | Central profile: `grunt-lucas__porytiles`; MIT; useful for asset pipeline terminology and validation ideas after attribution review. |
| `references/rompatcher-js` | Patch format support and user-facing patching flow | MIT with third-party components noted by upstream; useful for supported patch formats and verification UX. |
| `references/team-aquas-asset-repo` | Community asset organization, credits, and import metadata | No root license detected; assets are local reference only until asset-by-asset review. |
| `references/universal-gba-pokedex` | Pokedex/species presentation and cross-game data navigation | MIT; validate data provenance and game-derived assumptions before reuse. |

## NDS References Observed Locally

The May 12, 2026 NDS planning sweep found these central references under `/Users/bryan/projects/reference-repos`. They are orientation material only; current NDS support uses clean-room Swift parsers and synthetic tests for ROM containers plus read-only source-tree detection for pret-style DS decomps.

| Central Path | Primary Use | Notes |
| --- | --- | --- |
| `/Users/bryan/projects/reference-repos/repos/pret__pokediamond` | Diamond/Pearl source-tree shape and NitroFS/build layout | `Makefile`, `CMakeLists.txt`, `config.mk`, `filesystem.mk`, `rom.rsf`, `arm9/`, `arm7/`, `files/`, `graphics/`, `include/`, and `build/diamond.us` / `build/pearl.us` outputs. Detects as read-only `pokediamond`; reference-only. |
| `/Users/bryan/projects/reference-repos/repos/pret__pokeplatinum` | Platinum source-tree shape and Meson/Make build expectations | `Makefile`, `meson.build`, `src/`, `asm/`, `res/`, `generated/`, `include/`, and `platinum.us/`. Detects as read-only `pokeplatinum`; reference-only. |
| `/Users/bryan/projects/reference-repos/repos/pret__pokeheartgold` | HeartGold/SoulSilver source-tree shape and filesystem metadata | `Makefile`, `CMakeLists.txt`, `config.mk`, `filesystem.mk`, `rom.rsf`, `main.lsf`, `src/`, `asm/`, `files/`, `include/`, `heartgold.us/`, and `soulsilver.us/`. Detects as read-only `pokeheartgold`; reference-only. |
| `/Users/bryan/projects/reference-repos/repos/pret__pmd-sky` | DS-era decomp source-tree pressure outside mainline Pokemon RPGs | Detects as read-only `pmdSky`; spin-off reference only; do not use as Gen IV RPG schema truth. |
| `/Users/bryan/projects/reference-repos/repos/ds-pokemon-rom-editor__dspre` | DS Pokemon ROM editor UX/tool boundary reference | Treat as observational and external-tool oriented; do not copy code or UI text. |
| `/Users/bryan/projects/reference-repos/repos/adastra-ld__ds-pokemon-rom-editor` | Modern DSPRE-descended Gen IV ROM editor workflows | High-risk/read-only reference for extracted-directory loading, NARC pack/unpack, scripts, maps, trainers, personal data, learnsets, and ROM toolbox behavior. |
| `/Users/bryan/projects/reference-repos/repos/roadrunnerwmc__ndspy` | General NDS container and format library reference | GPL-3.0; use only for clean-room format behavior around NitroFS, overlays, NARC, compression, BMG, sound, and texture-related containers. |
| `/Users/bryan/projects/reference-repos/repos/garhoogin__nitropaint` | DS graphics/resource editor reference | BSD-2-Clause; useful for NCLR, NCGR, NSCR, NCER, NANR, NFTR, BMG, NSBMD, NSBTX, compression, and preview workflow terminology after attribution review. |
| `/Users/bryan/projects/reference-repos/repos/trifindo__pokemon-ds-map-studio` | Gen IV/V 3D map authoring workflow reference | No root license detected; observational only for map-authoring UX and project-shape pressure. |
| `/Users/bryan/projects/reference-repos/repos/turtleisaac__pokeditor-v2` | DS editor lineage and binary data workflow reference | Treat as high-risk/read-only reference. |
| `/Users/bryan/projects/reference-repos/repos/projectpokemon__ppre` | Historical Gen IV editor/data workflow reference | No root license detected; use for compatibility history around NDS/NARC, text, move, species, evolution, trainer, and generator-style workflows. |
| `/Users/bryan/projects/reference-repos/repos/hzla__pokeweb` | Web/editor workflow reference for DS-era data | Observational only. |
| `/Users/bryan/projects/reference-repos/repos/skytemple__skytemple` | NDS/PMD resource tooling and plugin workflow reference | Spin-off resource tooling reference; keep behind clean-room/external-tool boundaries. |

The central index now includes `pokemodding__pokeblack`, `r-yatian__tinkedsi`, `ds-pokemon-hacking__ctrmap-ce`, `melonds-emu__melonds`, `fantranslatorsinternational__kuriimu2`, `gota7__nitrostudio2`, and `tasemulators__desmume`. They stay central-profile-first until a product test, doc, or CLI path needs a stable local alias. Standalone `ndspy` coverage is present through `roadrunnerwmc__ndspy`, current DSPRE coverage is present through `ds-pokemon-rom-editor__dspre`, and BlocksDS/nitromods remain research candidates rather than local product aliases.

## Central Reference-Only Watchlist

These are metadata-only or central-profile-first references for `/Users/bryan/projects/reference-repos`. Do not clone or vendor them inside PokemonHackStudio, and treat all entries as read-only until the central profile records current license and reuse posture.

| Repository | Decision | Coverage Added |
| --- | --- | --- |
| `pokemodding/pokeblack` | Indexed centrally, reference-only | Gen V source-tree detection and future BW/BW2 source catalog/edit posture. |
| `PlatinumMaster/SwissArmyKnife` | Indexed centrally, reference-only | Gen V map containers, text, scripts, zone entities, encounters, and project/hotswap workflow. |
| `ds-pokemon-hacking/CTRMap-CE` | Indexed centrally, reference-only | Gen V plugin-based level editor and project workflow pressure; keep GPL code outside the product. |
| `melonDS-emu/melonDS` | Indexed centrally, external-tool reference | DS emulator launch/debug/runtime assumptions for future NDS playtest planning. |
| `R-YaTian/TinkeDSi` | Indexed centrally, reference-only | Active Tinke-descended DS/DSi file viewer/editor coverage for NARC, BMG, SDAT, and graphics inventory. |
| `Gota7/NitroStudio2` | Indexed centrally, research-only | Dedicated SDAT/audio workflow coverage for future NDS audio/cries/music diagnostics. |
| `FanTranslatorsInternational/Kuriimu2` | Indexed centrally, reference-only | Broad archive/text/image toolkit coverage for encodings, message resources, and plugin-style format handling. |
| `TASEmulators/desmume` | Indexed centrally, external-tool reference | Alternate DS emulator/debugger behavior for capability reporting. |
| `Gericom/EveryFileExplorer` | Research-only | Cross-check for broad Nintendo container/resource vocabulary. |
| `Barubary/dsdecmp` | Research-only | Focused DS compression/decompression behavior for compressed NARC/member planning. |
| `jmacd/xdelta` | Research-only | xdelta patch-format compatibility for DS hack distribution planning. |
| `XorTroll/NitroEdit` | Research-only | Compact DS resource checklist and on-console editor perspective. |

## Researched But Not Cloned

| Repository | Decision | Rationale |
| --- | --- | --- |
| `Alcaro/Flips` | Skip for this pass | Strong BPS/IPS reference, but archived and GPL-3.0; keep patch-format work clean-room against existing RomPatcher.js and public format behavior first. |
| `Ajarmar/universal-pokemon-randomizer-zx` | Skip for this pass | GPL-3.0 randomizer workflows are less direct than decomp source indexing and build/playtest validation. |
| `TuxSH/PkmGCTools` | Research only | Useful GameCube-era Colosseum/XD resource context; not cloned into this workspace and not a source for copied implementation. |
| Project Pokemon FSYS notes | Research only | Useful public notes for FSYS/LZSS compatibility; treat as format orientation only, with clean-room parser tests in PokemonHackStudio. |

## Licensing Boundaries

Reference code is not automatically available to the product. Use this rule of thumb:

- MIT references can be candidates for direct borrowing only after attribution and dependency/reuse review.
- MPL and LGPL references require stronger care around file boundaries, modifications, linking, and distribution.
- Custom or restrictive licenses are observational references unless legal review says otherwise.
- Commercial ROM content, original game assets, and generated ROM files are out of scope for redistribution.

If a feature depends on a reference implementation, document whether the adoption is:

- Conceptual: behavior or UX pattern reimplemented independently.
- Compatible: file format or workflow support implemented from public behavior.
- Vendored: code copied or included with license and attribution review.
- External tool: invoked as a separate user-installed dependency.

## Working Notes

- Start with source-tree tools such as Porymap and Poryscript when designing editable decomp workflows.
- Use Hex Maniac Advance to understand binary fallbacks, safety messaging, and data discovery for ROM-only scenarios.
- Use Rom Patcher JS as a reference for patch UX, checksum display, and patch-format vocabulary.
- Use mGBA as the emulator integration reference, especially around launch, debug, and patch-loading expectations.
- Use pret decomp repos as the truth for source layout, build outputs, generated artifact policy, table shapes, and project detection.
- Use GameCube resource references only for interoperability vocabulary and high-level format expectations; local `.iso`/`.gcm` inputs remain user-supplied and read-only.
- Use local NDS decomp/tool references only for source-tree shapes, build conventions, and format orientation; local `.nds` inputs remain user-supplied and read-only.
- Use `agbcc` only to understand toolchain/build boundaries; PokemonHackStudio should invoke or validate external tools rather than embedding compiler internals.

Any durable decision learned from references should move into `docs/product-architecture.md`, a future design note, or a tracked implementation issue.
