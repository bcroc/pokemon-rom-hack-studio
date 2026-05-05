# Mockup Screen Descriptions

These mockups describe the first usable PokemonHackStudio app surfaces. They are product notes, not final visual specs.

## 1. Project Picker

Purpose: open a decomp source tree or inspect a local ROM.

Layout:

- Sidebar with recent projects and detected project type badges.
- Main panel with two primary actions: open source tree and inspect ROM.
- Project summary after selection: game family, root path, build target, base ROM status, toolchain status, last validation result.
- Footer status strip for warnings such as missing `agbcc`, unknown base ROM hash, dirty source tree, or generated artifacts out of date.

Default path should guide users toward `pokeemerald/` and `pokefirered/` source trees. ROM inspection should be clearly labeled as a fallback or comparison workflow.

## 2. Project Dashboard

Purpose: give a fast, source-aware overview of the active hack.

Layout:

- Left navigation for Maps, Scripts, Pokemon, Trainers, Items, Moves, Graphics, Builds, Patches, and Diagnostics.
- Header showing project name, game family, branch or dirty state when available, and last successful build.
- Central dashboard with validation cards for source index, build readiness, base ROM match, generated artifact freshness, and patch readiness.
- Activity panel listing recent edits, generated outputs, builds, and emulator launches.

Every dashboard item should link to either a source file, a generated artifact, or a diagnostic detail screen.

## 3. Source-Aware Editor

Purpose: edit structured game data while keeping the backing source visible.

Layout:

- Object browser on the left with search, filters, and source-file grouping.
- Editor pane in the center with form controls tailored to the selected object.
- Inspector on the right showing backing files, related constants, validation errors, references, and pending mutation plan.
- Bottom diff drawer that previews exact source-tree changes before writing.

Examples:

- Pokemon species editor: stats, typing, abilities, learnsets, evolution links, icon/sprite references, and source paths.
- Trainer editor: party, AI flags, payout, encounter context, and linked scripts.
- Item editor: name, price, effect hooks, pocket, icon, and description text.

Writes should be explicit. A user should be able to preview, apply, revert, and then build without losing track of which source files changed.

## 4. Map And Script Workspace

Purpose: connect map layout, events, warps, and scripts without forcing constant file navigation.

Layout:

- Map canvas with layers for collision, events, warps, connections, and NPCs.
- Tool rail for select, paint, event placement, warp linking, and connection edits.
- Script panel that opens the script attached to the selected object.
- Inspector for selected tile, event, warp, or connection.
- Source panel showing map data paths and script file paths.

The first version can be read-heavy: visualize source data, expose relationships, and generate safe edit plans for narrow changes before becoming a full map editor.

## 5. Build, Patch, And Playtest

Purpose: turn source changes into a built output, patch artifact, and emulator smoke test.

Layout:

- Build lane with target selection, command preview, progress logs, and parsed errors.
- Patch lane with original ROM selection, checksum display, output patch format, and generated artifact path.
- Playtest lane with emulator launch action, recent ROM builds, save-state notes, and smoke-test checklist.
- Artifact table listing build outputs, patches, logs, indexes, and their source metadata.

Generated outputs should be marked as generated and should never look like hand-authored project files.

## 6. Diagnostics

Purpose: make failures actionable without requiring users to read raw build logs first.

Layout:

- Issue list grouped by source parse errors, missing tools, base ROM mismatch, build failures, patch failures, and licensing/content warnings.
- Detail pane with command, file path, line or object reference when known, explanation, and suggested next action.
- Raw log drawer for full output.
- Export button for a compact diagnostic report.

Diagnostics should favor project-relative paths and should distinguish source problems from generated-artifact staleness.
