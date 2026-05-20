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
4. **Done - NARC-Backed Read-Only Summaries**: source-tree and ROM-backed NARC containers now appear in NDS data catalogs with member counts, sample member paths, diagnostics, and Resources metadata; Diamond/Pearl unpacked archive directories are summarized without reconstruction.
5. **Done - NDS Toolchain Health**: report user-installed devkitPro/BlocksDS, ndstool, grit, mmutil, devkitARM, ndspy-compatible tooling, melonDS/DeSmuME, reference-only DSPRE/Tinke posture, NDS header facts, and source-tree build prerequisites as optional external dependencies.
6. **Done - Source-Backed Record Editing**: local source-tree NDS data records in safe UTF-8 formats now draft, preview, apply, discard, back up, and reload through the mutation-plan contract in CLI and Resources.
7. **Done - Semantic Editor Design V1**: eligible Platinum source-backed JSON species, move, item, trainer, direct encounter JSON, and existing species evolution tuple records, HeartGold/SoulSilver personal/trainer/item JSON plus nested encounter JSON records, Diamond/Pearl personal/trainer JSON records, and Diamond/Pearl `arm9/src/itemtool.c` `sItemIndexMappings` integer initializer rows expose scalar semantic fields in Resources and CLI plan/apply commands while still lowering to the source-backed NDS mutation plan. Separate binary-only export plans remain later rows.
8. **Done - Map/Script/Text Readiness**: NDS data catalog rows now carry read-only relationship and readiness metadata for map, matrix, script, text, filesystem manifest, and container review in CLI JSON and Resources facts. External editors, compilers, extraction, rebuilds, NARC packing, mutation apply, and ROM/container writes stay blocked.
9. **Done - Container Member Fingerprints**: NARC and unpacked archive directory summaries now include bounded read-only member path/index, size, extension, leading magic, format/compression hint, confidence, diagnostics, CLI JSON, and Resources facts for future graphics, text, map, and migration routing.
10. **Done - Graphics Preview Metadata**: sampled NDS container members now expose read-only preview metadata for known Nitro graphics-adjacent formats, while compressed, unsupported, too-short, and unreadable members stay blocked and metadata-only.
11. **Done - Text Bank Preview Metadata**: safe source text, JSON message banks, and BMG-like Gen IV text rows now expose read-only decoded string counts, decoded sample strings, blocked writer/export actions, CLI JSON, and Resources facts without adding semantic mutation eligibility or any extraction/rebuild/export path.
12. **Done - Extracted Directory Migration Plan**: binary container and NitroFS manifest rows now report read-only source-tree and extracted-directory candidate paths, unsupported preservation/rebuild steps, blocked actions, CLI JSON, and source/ROM Resources facts without materializing extracted files or enabling repack/rebuild/export behavior.
13. **Done - Shared Migration Coverage Diagnostics**: `migration-coverage <path> --json` reports NDS source, ROM, and source-backed Gen IV semantic domains against shared source-first/read-only/migration-plan/binary-only/blocked statuses so PHS-T93 can guide PHS-T92 and future PHS-T98 slices without enabling NDS build/playtest execution or ROM/container writes.
14. **Done - Diamond/Pearl Item Mapping Semantic Fields**: the semantic editor now parses only the existing `sItemIndexMappings` table in Diamond/Pearl `items:arm9/src/itemtool.c`, exposes `itemIndexMappings.<index>.itemDataIndex`, `.iconIndex`, `.paletteIndex`, and `.gen3Index` integer scalar fields, and replaces only initializer values through the existing NDS mutation plan. Other C anchors, non-integer expressions, row add/remove/reorder, binary item rows, NARC/container rows, generated/reference rows, ROM/export/rebuild paths, and binary writes remain blocked/read-only.
15. **Done - Diamond/Pearl Personal JSON Semantic Fields**: Diamond/Pearl source-backed personal JSON records under `files/poketool/personal` and `files/poketool/personal_pearl` now expose existing top-level scalar JSON fields through the same semantic editor and NDS mutation-plan gate. Nested personal arrays/objects, binary personal rows, other Diamond/Pearl C anchors, NARC/container rows, generated/reference rows, ROM/export/rebuild paths, and binary writes remain blocked/read-only.
16. **Done - Diamond/Pearl Trainer JSON Semantic Fields**: Diamond/Pearl source-backed trainer JSON records under `files/poketool/trainer` now expose existing top-level scalar JSON fields through the same semantic editor and NDS mutation-plan gate. Nested trainer arrays/objects, party rows, binary trainer rows, other Diamond/Pearl C anchors, NARC/container rows, generated/reference rows, ROM/export/rebuild paths, and binary writes remain blocked/read-only.

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

## V4 Container Summaries

- `NDSDataContainerSummary` enriches catalog records with NARC or unpacked-archive-directory member counts, named/unnamed counts, byte counts, sample member paths, read-only posture, and parser diagnostics.
- Platinum `res/prebuilt/**/*.narc`, HeartGold/SoulSilver `files/**/*.narc`, Diamond/Pearl unpacked `narc_*` archive directories, and ROM-backed NitroFS NARCs all flow through the existing `nds-data-catalog` and `resource-index` surfaces.
- PMD-Sky remains spin-off inventory only. Complex formats, decompression, extraction, rebuilds, data decoding, editor routing, and binary writes remain deferred.

## V5 Toolchain Health

- `ToolchainHealthMatrixBuilder` now adds NDS-specific preview rows for devkitPro/DEVKITARM roots, devkitARM tools, `ndstool`, `grit`, `mmutil`, Python/`ndspy`, BlocksDS Docker, melonDS, DeSmuME, and reference-only DSPRE/Tinke roots.
- NDS source trees and `.nds` ROM inputs reuse `pokemonhack-cli toolchain-health <path> --json` and the existing Build/Patch/Playtest health surface. Missing NDS tools are warnings, not write blockers, because NDS rebuilds and playtest launches remain disabled.
- Build/Patch/Playtest groups NDS health rows into build SDKs, packaging/inspection, Python/ndspy-compatible tooling, manual emulators, reference tools, headers, and declared outputs; sidebar setup actions copy manual commands or paths without adding new settings.
- PokemonHackStudio only detects local tool paths, app bundles, common install roots, and reference-checkout availability. It does not install packages, inspect/pull/run Docker images, run builds, launch emulators, extract assets, or write ROM outputs.

## V6 Source-Backed Record Editing

- `NDSDataMutationPlanner` and `NDSDataMutationApplier` draft catalog rows through the shared mutation-plan contract, with source path, SHA1 and byte-count freshness checks, diagnostics, explicit apply, atomic writes, and backups under `.pokemonhackstudio/backups/`.
- Editable rows are limited to local source-tree JSON, CSV, plain text, C source, and C header files that parse as UTF-8. JSON drafts must parse before a plan is applyable.
- `pokemonhack-cli nds-data-edit-plan <project> <record-id> --draft-file <path> --json` exposes a redacted report that preserves path, preview, hash, byte-count, diagnostic, mutation-plan, and backup metadata without emitting raw replacement bytes. `nds-data-edit-apply <project> <record-id> --draft-file <path> --json` remains a thin adapter over the same guarded core applier.
- NDS raw source drafts persist through the shared project workspace save/autosave system, and selected app catalogs are cached per source fingerprint so large Platinum/HGSS catalogs are not rebuilt by repeated Resources/store state reads.
- Source-backed NDS edit plans warn that generated outputs and rebuild artifacts may be stale after source edits until an external rebuild refreshes them.
- Resources shows a raw NDS Data Record editor only for eligible selected rows, with Preview, Apply, Discard, mutation-plan panel integration, and blocked-state messages for ineligible NDS rows.
- ROM-backed rows, `.nds` files, NARC containers, unpacked archive directories, generated/reference rows, PMD-Sky spin-off inventory, extraction, rebuilds, emulator launch, ROM export, and binary writes remain blocked/read-only.

## V7 Semantic Field Editing

- `NDSDataSemanticEditor` adds the first semantic layer above raw source text by detecting top-level scalar fields in eligible Platinum source-backed JSON records for species/personal/move-style data, item data under `res/items/**/*.json`, trainer data under `res/trainers/data/**/*.json`, direct encounter JSON rows under `res/field/encounters/*.json`, existing species evolution tuple method/parameter/target values under `res/pokemon/<species>/data.json`, HeartGold/SoulSilver personal/trainer/item JSON rows under `files/poketool/personal/**/*.json`, `files/poketool/trainer/**/*.json`, and `files/itemtool/itemdata/**/*.json`, nested HeartGold/SoulSilver encounter JSON rows under `files/fielddata/encountdata/**/*.json`, Diamond/Pearl personal JSON rows under `files/poketool/personal/**/*.json` and `files/poketool/personal_pearl/**/*.json`, Diamond/Pearl trainer JSON rows under `files/poketool/trainer/**/*.json`, plus Diamond/Pearl `arm9/src/itemtool.c` `sItemIndexMappings` integer initializer scalars.
- Semantic edits preserve the source file shape by replacing only the selected scalar value, then flow through `NDSDataMutationPlanner`/`NDSDataMutationApplier` for preview, source hash/size checks, explicit apply, and backups.
- Semantic eligibility diagnostics are carried into the lowered mutation plan so direct CLI/app apply paths cannot bypass the row-specific semantic path policy.
- `pokemonhack-cli nds-data-semantic-plan <project> <record-id> --set <field=value> --json` and `nds-data-semantic-apply ...` expose field-level planning/apply without introducing a separate write path.
- Resources renders semantic field controls above the raw text editor when a selected NDS data row is eligible; ineligible records keep the existing raw editor or read-only blocked state.
- Evolution add/remove/reorder, trainer class/resource JSON, nested trainer/item/personal/encounter arrays or objects outside the explicitly exposed scalar tuple values, Diamond/Pearl party and encounter rows, HeartGold/SoulSilver CSV item rows and non-JSON encounter rows, other Diamond/Pearl C anchors, Diamond/Pearl non-integer item mapping expressions, binary item/personal/trainer data, ROM-backed rows, NARC/container rows, generated/reference rows, PMD-Sky, extraction, rebuilds, binary writes, and ROM exports remain blocked/read-only.

## V8 Map/Script/Text Readiness

- `NDSDataCatalogRecord` now includes `relatedRecords` and a read-only `readiness` summary so existing `nds-data-catalog`, `resource-index`, and Resources rows can show Gen IV context without a new editor module.
- Relationship keys connect same-name map, matrix, script, and text rows where source-tree paths make that safe; unmatched rows remain partial and explain that no same-key context was found.
- Filesystem manifests and binary/container rows report manual-only or blocked readiness with explicit blocked actions for extraction, decompression, compilers, NARC rebuild, ROM rebuild, and ROM export.
- Resources surfaces this metadata as facts and searchable row context. Navigation still routes through existing Resources behavior; no editor, compiler, extraction, rebuild, mutation apply, NARC packing, ROM export, or binary/container write path is added by this pass.

## V9 Container Member Fingerprints

- `NDSDataContainerSummary` now carries `NDSDataContainerMemberFingerprint` rows for sampled NARC and unpacked archive members.
- Fingerprints report path/index, byte count, extension, leading magic bytes/ASCII when safe, conservative Nitro/text/container/compression hints, confidence, and diagnostics.
- Fingerprinting reads only bounded leading byte windows and caps samples with the existing container sample limit. It does not extract, decompress, rewrite, rebuild, apply mutation plans, export ROMs, or materialize member files.
- `nds-data-catalog`, `resource-index`, and Resources facts expose member hints and compression hints while keeping ROM-backed, source-backed container, generated/reference, PMD-Sky, and binary rows read-only or blocked.

## V10 Graphics Preview Metadata

- `NDSDataContainerMemberFingerprint` now carries optional read-only preview metadata for Nitro palette, character graphics, screen map, cell, animation, font, model, and texture candidates detected from extension or leading magic.
- Preview metadata is descriptive only: it reports ready/blocked status, format, summary, blocked actions, and diagnostics. It does not decode pixels, parse dimensions, extract members, decompress data, convert formats, rebuild containers, apply mutation plans, export ROMs, or materialize preview files.
- Compressed candidates, unsupported formats, too-short members, and unreadable member bytes are explicitly blocked so future graphics, text, map, and migration rows can route the member safely without implying write or conversion support.
- `nds-data-catalog`, `resource-index`, and Resources facts surface preview hints and blocked preview counts consistently for source-tree and ROM-backed container rows.

## V11 Text Bank Preview Metadata

- `NDSDataCatalogRecord` carries optional `NDSDataTextBankPreview` metadata for Gen IV text rows.
- Safe source-backed text, JSON, CSV, C source, and C header rows report decoded string counts and capped sample strings as read-only facts; JSON message-bank rows sample decoded string leaves rather than JSON syntax.
- BMG-like binary text rows use bounded printable-string sampling and explicit blocked diagnostics instead of extraction, conversion, write, rebuild, or export behavior.
- CLI `nds-data-catalog`, CLI `resource-index`, and Resources facts surface the same preview status, decoded string counts, sample strings, and blocked actions; the local Platinum source-tree smoke proves these facts through Resources rows.
- Text bank preview does not add semantic mutation eligibility. Existing NDS source edits remain governed by the raw source mutation gate, and ROM/NARC/container/generated/reference rows remain blocked/read-only.

## V12 Extracted Directory Migration Plan

- `NDSDataCatalogRecord` carries optional `NDSDataMigrationPlan` metadata for binary container and NitroFS manifest rows.
- Migration plans report source-tree candidate paths, extracted-directory candidate paths, unsupported preservation/rebuild steps, blocked actions, and read-only diagnostics.
- Candidate routing uses conservative path/domain heuristics from existing NDS catalog classification; it does not copy reference schemas, inspect external tools, or infer write eligibility.
- CLI `nds-data-catalog`, CLI `resource-index`, and Resources facts surface the same migration status, candidate paths, unsupported steps, and blocked actions for source-tree and ROM rows.
- Migration plans do not extract ROM files, unpack NARCs, materialize member files, repack containers, rebuild ROMs, export ROMs, or apply mutation plans.

## Next Useful Pass

Expand semantic Gen IV coverage one dedicated source-backed domain at a time, continuing from the completed Platinum rows, HGSS personal/trainer/item JSON slices, Diamond/Pearl personal/trainer JSON slices, and the first Diamond/Pearl item mapping C-anchor slice toward other HGSS or Diamond/Pearl source-backed schemas only when they fit the existing mutation-plan architecture. Keep container/ROM writes disabled until dedicated parser, preservation, and rebuild rows exist, and keep NDS build/playtest as manual guidance until a future implementation row opens runnable execution.
