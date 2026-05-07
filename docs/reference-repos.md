# Reference Repositories

The `references/` directory is a research bench for Pokemon GBA hacking tools, emulation, patching, and decompilation workflows. Reference repos should inform architecture and compatibility, but they are not owned product code.

## Strategy

- Keep reference repos read-only during product work unless a task explicitly asks to update or inspect them.
- Use references to understand file formats, editor ergonomics, patch formats, build expectations, and user workflows.
- Summarize learned patterns in docs or issues before adopting them.
- Prefer clean-room implementation in `PokemonHackCore` when the needed behavior is small or domain-specific.
- Require license review before copying code, assets, schemas, tests, or UI text.

The project should learn from existing tools while keeping PokemonHackStudio's implementation and distribution story clean.

Detailed feature synthesis, adoption decisions, and the current implementation lanes are tracked in `docs/reference-synthesis.md`.

## Current References

The May 6, 2026 broad sweep expanded the ignored `references/` bench to 30 pinned shallow clones. Only `references/manifest.json` is tracked; all clone directories remain local read-only research material.

| Path | Primary Use | Notes |
| --- | --- | --- |
| `references/agbcc` | pret toolchain setup and compiler/build boundary reference | Mixed GCC/newlib notices; treat as external toolchain research only. |
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
| `references/pokeemerald` | Canonical Emerald source layout, build outputs, generated data, and table/script formats | No root license detected; use as read-only compatibility truth, not a code source. |
| `references/pokeemerald-expansion` | Expanded decomp content and compatibility pressure | Check upstream terms before borrowing; use as a target for schema flexibility. |
| `references/pokeemerald-jp` | Emerald localization/source-layout variation | No root license detected; read-only interoperability reference. |
| `references/pokefirered` | Canonical FireRed/LeafGreen source layout, build target variants, generated data, and adapter differences | No root license detected; use as read-only compatibility truth, especially for FireRed-specific positional data. |
| `references/pokemapexport` | Visual map export workflow reference | GPL-3.0; behavioral reference only. |
| `references/pokemon-game-editor` | Legacy binary editor behavior | Custom restrictive license; treat as observational only unless reviewed. |
| `references/pokeruby` | Additional pret decomp project shape | Use to avoid overfitting core models to only Emerald and FireRed. |
| `references/porydelete` | Safe source-tree cleanup/deletion workflow reference | GPL-3.0; adopt safety checks conceptually only. |
| `references/porylive` | Live script editing and playtest-loop workflow reference | No root license detected; use behaviorally for future live-readiness planning. |
| `references/porymap` | Source-tree map editing UX for Gen 3 decomp projects | LGPL 3.0; study project loading, map relationships, and editor workflows carefully before borrowing implementation details. |
| `references/porymoves` | Moves and learnset workflow reference | No root license detected; observational reference for editor coverage. |
| `references/porypal` | Palette editing and GBA color conversion reference | GPL-3.0; clean-room diagnostics and UX reference only. |
| `references/poryscript` | Script language conventions for decomp-based event scripting | MIT; useful for script workflow compatibility and CLI ergonomics. |
| `references/porysuite` | All-in-one decomp editor workflow reference | No root license detected; observational UX/product reference only. |
| `references/porytiles` | Tileset and tile workflow reference | MIT; useful for asset pipeline terminology and validation ideas. |
| `references/rompatcher-js` | Patch format support and user-facing patching flow | MIT with third-party components noted by upstream; useful for supported patch formats and verification UX. |
| `references/team-aquas-asset-repo` | Community asset organization, credits, and import metadata | No root license detected; assets are local reference only until asset-by-asset review. |
| `references/universal-gba-pokedex` | Pokedex/species presentation and cross-game data navigation | MIT; validate data provenance and game-derived assumptions before reuse. |

## Researched But Not Cloned

| Repository | Decision | Rationale |
| --- | --- | --- |
| `Rangi42/tilemap-studio` | Skip for this pass | Useful tilemap editor ergonomics, but LGPL-3.0 makes it behavioral-only and less direct than Porytiles for the current source-first lane. |
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
- Use `agbcc` only to understand toolchain/build boundaries; PokemonHackStudio should invoke or validate external tools rather than embedding compiler internals.

Any durable decision learned from references should move into `docs/product-architecture.md`, a future design note, or a tracked implementation issue.
