# PokemonHackStudio Planning

PokemonHackStudio is a Swift-native, Apple Silicon focused workbench for Pokemon Generation III ROM hacking. The product direction is source-tree-first: decomp projects are the canonical editing surface, while binary ROM workflows support inspection, patching, migration, and compatibility.

## Current Roadmap

1. **Source Project Foundation**
   - Detect supported Gen III project shapes.
   - Index source documents, generated outputs, diagnostics, and build targets.
   - Keep source locations visible across app and CLI surfaces.

2. **Map And Layout Workbench**
   - Parse `map_groups.json`, per-map `map.json`, and `layouts.json`.
   - Show maps by group, layout metadata, connections, event counts, source links, and a neutral metatile grid.
   - Keep this read-only until mutation plans and stable JSON round trips are proven.

3. **Script, Text, And Data Indexing**
   - Add script labels, command outlines, text blocks, and source-span diagnostics.
   - Add table-aware C initializer indexes for species, trainers, items, and moves.
   - Handle FireRed positional item data separately from bracket-designated Emerald tables.

4. **Build, Patch, And Playtest Pipeline**
   - Promote build previews into non-mutating validation reports.
   - Expand patch parsing toward manifests and checksum workflows.
   - Prepare mGBA-compatible interactive and headless playtest handoff.

## Operating Guardrails

- Keep reference repos as behavioral guidance unless a license review explicitly approves reuse.
- Do not bundle commercial ROMs, generated ROMs, decomp assets, or unlicensed expansion content.
- Treat generated files as caches unless an adapter marks them as source.
- Keep all writes preview-first through mutation plans and diffs.
- Use local `pokeemerald` and `pokefirered` as smoke targets, not hard unit-test dependencies.
