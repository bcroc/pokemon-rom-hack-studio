# NDS Extension Plan

PokemonHackStudio remains one Swift/macOS app with `PokemonHackCore` and `pokemonhack-cli`. NDS support extends the existing source-tree-first workbench instead of becoming a separate editor.

## Clean-Room Posture

- Local `.nds` files are user-supplied inputs and stay ignored.
- Central NDS references under `/Users/bryan/projects/reference-repos` are read-only research unless a future license review approves reuse.
- Small, stable binary containers can be native Swift parsers with synthetic fixtures only: NDS header, FNT/FAT NitroFS index, overlay table metadata, banner facts, and NARC member listing.
- Complex rebuild/conversion systems stay external-tool or planning-only at first: NDS graphics conversion, 3D Nitro formats, audio, script compilation, compression/recompression, overlay rebuilds, and ROM writes.
- Future NDS writes must use mutation-plan previews, backups, source hash checks where source-backed, and ignored `.pokemonhackstudio/` outputs.

## Phased Roadmap

1. **Done - NDS ROM Resource Inspector V1**: platform/profile detection for `.nds`, read-only header facts, NitroFS file/folder listing, overlay counts, NARC member listing, CLI JSON, Resources/Project Hub visibility, synthetic tests.
2. **Done - NDS Decomp Project Detection**: detect Diamond/Pearl, Platinum, HeartGold/SoulSilver, and PMD-Sky-style source trees through `rom.rsf`, `filesystem.mk`, `files/` or `res/`, variant `.sha1`, and game directories such as `platinum.us`, `heartgold.us`, and `soulsilver.us`.
3. **Done - Gen IV Read-Only Data Catalog**: source/decomp-aware personal/species, moves, items, trainers, encounters, text, scripts, and map resource indexes with diagnostics, shallow counts, source spans, CLI JSON, and Resources visibility where available.
4. **NARC-Backed Workbenches**: browse Gen IV data containers from ROMs and source trees, resolving member labels and format-specific summaries without extraction by default.
5. **NDS Toolchain Health**: report user-installed devkitPro/BlocksDS, ndstool, DSPRE/Tinke-style tools, ndspy-compatible tooling, melonDS/DeSmuME, and source-tree build prerequisites as optional external dependencies.
6. **Mutation-Plan Design**: only after read-only coverage is stable, design preview/apply models for source-backed NDS edits and separate binary-only export plans that preserve ordering and unknown bytes.

## V1 Native Parsers

- `NDSROMHeader`: title, game code, maker, unit code, device capacity, ARM9/ARM7 ranges, FNT/FAT ranges, overlay table ranges, banner offset, and checksum fields.
- `NitroFSIndex`: FNT/FAT directory traversal, file IDs, paths, offsets, sizes, category guesses, and malformed range diagnostics.
- `NDSOverlayTableIndex`: ARM9/ARM7 overlay entry counts, file IDs, memory ranges, compression flag facts, and bounds diagnostics.
- `NARCIndex`: `NARC` container with `BTAF`/`BTNF`/`GMIF` blocks, named or unnamed members, offsets, sizes, and malformed block diagnostics.

## V2 Source-Tree Index

- `NDSDecompAdapter`: read-only adapter for pret-style Diamond/Pearl, Platinum, HeartGold/SoulSilver, and PMD-Sky roots.
- `NDSDecompSourceTreeIndex`: reports profile, family, build system, marker files, source roots, NitroFS/file manifest roots, variant outputs, checksum files, generated/build artifact paths, build target metadata, and diagnostics.
- App and CLI visibility is intentionally limited to Resources, Project Hub/project inspection, ROM, Build, and Diagnostics routing. Gen IV editors, source mutation, extraction, rebuild, playtest launch, and binary writes remain disabled.
- Central reference roots under `/Users/bryan/projects/reference-repos/repos` are labeled as reference inputs instead of editable project inputs.

## V3 Data Catalog

- `NDSDataCatalogBuilder`: read-only catalog builder for NDS source-tree profiles. It emits project-relative records for Gen IV data domains, shallow JSON/CSV/text counts, byte counts, source spans, diagnostics, and read-only posture.
- Platinum gets the richest semantic path coverage through `res/pokemon`, `res/battle/moves`, `res/items`, `res/trainers`, `res/field`, `res/text`, and `generated/*.txt`.
- HeartGold/SoulSilver and Diamond/Pearl start with source/path counts, NitroFS-backed paths, C source anchors, and NARC placeholders only. PMD-Sky is intentionally reported as a spin-off resource inventory, not a mainline Gen IV RPG schema.
- `pokemonhack-cli nds-data-catalog <path> --json` exposes the catalog. `resource-index` and Resources add `NDS Data ...` rows, but no Gen IV editor modules, rebuilds, extraction, mutation plans, or ROM writes are enabled.

## Next Useful Pass

Add NARC-backed read-only summaries for source-tree and ROM-backed Gen IV data containers, or add NDS toolchain health for user-installed devkitPro/BlocksDS, ndstool, DSPRE/Tinke-style tools, ndspy-compatible tooling, and DS emulators. Keep both lanes read-only until mutation-plan designs exist.
