# Editable Surfaces Remediation Plan

This document outlines the phased implementation strategy to promote currently read-only or preview-only surfaces into full editable workspaces.

## Phase 1: High-Value Data Editors (Target: PHS-T64 - PHS-T67)
Focus on the most frequently edited pokemon data that is currently read-only.

| ID | Title | Scope |
| --- | --- | --- |
| PHS-T64 | **Evolution Editor** | Done: parser/planner/apply for existing `evolution.h` rows, method/target/parameter edits, removals, trade-item parameters, zero-parameter validation, and safe blocking when insertion would be required. |
| PHS-T65 | **Pokedex Workbench** | Done: category, height/weight, description text, and scale/offset editing for `pokedex_entries.h` / Pokedex text. |
| PHS-T66 | **Move Compatibility Editor** | Done: species-side TM/HM and Tutor assignment edits plus a move-centric species checklist in Moves that stages compatibility drafts. |
| PHS-T67 | **Trainer Hardening** | Done for classic profiles: searchable constants, party previews, reset-to-default moves, and party add/remove mutation proof. Expansion-only per-stat IV/nature write support remains a future adapter-specific row. |

## Phase 2: Workflow Activation (Target: PHS-T72 - PHS-T74)
Promote preview-only workflows into actionable source-write operations.

| ID | Title | Scope |
| --- | --- | --- |
| PHS-T72 | **Graphics Import Execution** | Enable "Import" and "Convert" actions for graphics packages, invoking external tools (gtools/porytiles) through the core library. |
| PHS-T73 | **Patch Apply & ROM Export** | Activate the patch apply gate to produce patched `.gba` files from planned manifests. |
| PHS-T74 | **Integrated Build Runner** | Support triggering `make` build commands directly from the app with real-time log capture and artifact verification. |

## Phase 3: Advanced Assets & Scripting (Target: PHS-T75 - PHS-T77)
Address complex binary and high-level authoring surfaces.

| ID | Title | Scope |
| --- | --- | --- |
| PHS-T75 | **Sprite & Palette Authoring** | Implement PNG import and automated palette-fitting for Pokemon and Trainer sprites. |
| PHS-T76 | **Poryscript Integration** | Support Poryscript (.pory) authoring with automated compilation into shared script includes. |
| PHS-T77 | **Map Duplication & Export** | Move map duplication and visual image export from "Plan-only" to "Execute". |

## Phase 4: Expansion & Binary Support (Target: PHS-T78+)
Extend support to modern project shapes and binary-only workflows.

| ID | Title | Scope |
| --- | --- | --- |
| PHS-T78 | **Modern Expansion Adapters** | Complete editable coverage for Expansion-specific tables like `ItemInfo` and `FormChange`. |
| PHS-T79 | **Binary Mutation Workbench** | Implement direct ROM byte editing, repointing, and free-space management for binary-only hacks. |

## Implementation Guidelines
1. **Mutation-Plan First**: All new editors must follow the established Draft -> Preview -> Apply pattern with source hash checks and backups.
2. **Profile Parity**: Ensure editors handle both Emerald and FireRed differences (e.g., positional vs. bracketed tables).
3. **Diagnostic Integrity**: Provide clear feedback when a field is read-only due to profile limitations (e.g., classic IVs).
