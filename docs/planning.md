# PokemonHackStudio Planning

PokemonHackStudio is a Swift-native, Apple Silicon focused workbench for Pokemon GBA and NDS ROM hacking. The product direction remains source-tree-first: decomp projects are the canonical editing surface, while binary ROM workflows support inspection, patching, migration, and compatibility. The active GBA + NDS extension shape is tracked in `docs/nds-extension-plan.md`.

## Current Roadmap

1. **Source Project Foundation**
   - Detect supported Gen III project shapes.
   - Index source documents, generated outputs, diagnostics, and build targets.
   - Auto-load editable roots, pinned reference roots, recent roots, and safe top-level ROM/media inputs into one resource library.
   - Keep source locations visible across app and CLI surfaces.

2. **Map And Layout Workbench**
   - Parse `map_groups.json`, per-map `map.json`, and `layouts.json`.
   - Show maps by group, layout metadata, connections, event counts, source links, and a neutral metatile grid.
   - Render visual map canvases from local tileset assets and support explicit, backup-protected source writes after mutation-plan preview.
   - Harden visual editing around dirty-state prompts, visual metatile selection, desktop-grade tools, undoable map/event operations, and applyability checks before deeper paint or tileset authoring.

3. **Script, Text, And Data Indexing**
   - Add script labels, command outlines, text blocks, and source-span diagnostics.
   - Add table-aware C initializer indexes for species, trainers, items, and moves.
   - Handle FireRed positional item data separately from bracket-designated Emerald tables.

4. **Build, Patch, And Playtest Pipeline**
   - Promote build previews into non-mutating validation reports.
   - Expand patch parsing, checksum workflows, explicit BPS creation from selected base ROM plus existing built output, and read-only Patch Library review for ignored `.pokemonhackstudio/patches/*.bps` artifacts plus sibling manifests; created BPS artifacts must be re-read and verified in memory before schema v2 manifests are written, while patched-ROM export stays separate.
   - Prepare mGBA-compatible interactive and headless playtest handoff.

5. **Cross-Media Resource Library**
   - Treat GBA ROMs as read-only local inputs in the auto-loaded Resources surface; the only opened direct-write lanes are `PHS-T79C` CLI-reviewed and `PHS-T79D` app-reviewed in-place byte replacement paths for explicit local `.gba` inputs, with `PHS-T79E` adding read-only app audit/review diagnostics before apply, `PHS-T79F` exposing the same audit model as read-only CLI JSON, and `PHS-T141` scanning existing ignored ROM mutation apply artifacts as a read-only CLI library.
   - Treat NDS ROMs, containers, and generated/reference rows as read-only preview/catalog inputs; eligible local source-backed Gen IV text/JSON rows may write only through explicit mutation-plan gates opened by dedicated rows.
   - Keep binary-only GBA mutation behind the `PHS-T79` safety policy: source-tree-first refusal, dry-run mutation plans, base-hash drift refusal, ignored backups/artifacts/manifests, and explicit user confirmation remain mandatory for apply. `PHS-T79C` opens CLI replace-byte apply, `PHS-T79D` opens the matching app review/apply surface, `PHS-T79E` surfaces read-only app pre-apply audit/drift status, `PHS-T79F` adds read-only CLI audit JSON, and `PHS-T141` adds read-only CLI artifact-library JSON for existing apply manifests/backups; broader direct ROM writers remain blocked.
   - Keep GameCube `.iso`/`.gcm` media as direct parser inputs for `resource-index`, not auto-loaded Resources rows, until the GBA asset workflow is mature.
   - Parse GameCube headers, FST entries, DOL ranges, FSYS archives, and LZSS members before any future export workflow.
   - Show missing Colosseum, XD, Box, and Channel inputs as diagnostics instead of silently omitting them.

## Operating Guardrails

- Keep reference repos as behavioral guidance unless a license review explicitly approves reuse.
- Do not bundle commercial ROMs, generated ROMs, decomp assets, or unlicensed expansion content.
- Treat generated files as caches unless an adapter marks them as source.
- Treat GameCube disc and archive resources as direct read-only parser inputs until a future mutation/export policy and UI scope are designed.
- Treat NDS build/playtest as manual guidance only until a future row explicitly adds runnable NDS execution.
- Keep all writes preview-first through mutation plans and diffs.
- Back up source files under ignored `.pokemonhackstudio/backups/` before explicit apply operations.
- Keep binary ROM writes disabled except for explicit guarded rows; today that means `PHS-T79C` CLI and `PHS-T79D` app-reviewed replace-byte apply plus `PHS-T79E` app audit, `PHS-T79F` CLI audit read-only status, and `PHS-T141` read-only ROM mutation artifact library scans, while pointer repoint apply, free-space allocation apply, checksum repair, app auto-apply, emulator launch, and ROM export remain blocked.
- Use local `pokeemerald` and `pokefirered` as smoke targets, not hard unit-test dependencies.
