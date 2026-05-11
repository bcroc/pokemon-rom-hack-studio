# Audit: Progress Against Remediation Plan

**Audit Date**: 2026-05-10
**Status**: Phase 1 Complete; Phase 2 Backlog

## Executive Summary
Recent remediation work completed the Phase 1 goals. Evolutions, Pokedex data, and TM/HM/Tutor compatibility now stage through the existing draft and mutation-plan gates, while the Moves workbench provides a move-centric species checklist for batch staging. Trainer editor hardening also landed for the classic trainer surface.

---

## Phase 1: High-Value Data Editors
| Task ID | Component | Status | Progress Audit |
| :--- | :--- | :--- | :--- |
| **PHS-T64** | **Evolution Editor** | **[x] Completed** | Parser/draft/planner/apply support now covers row edits, removals, multi-evolution rows, `EVO_TRADE_ITEM` item parameters, zero-parameter method validation, and safe blocking for insertion into species without an existing source span. |
| **PHS-T65** | **Pokedex Workbench** | **[x] Completed** | Category, height, weight, description text, `.pokemonScale`, `.pokemonOffset`, `.trainerScale`, and `.trainerOffset` are editable through the Species mutation-plan gate. |
| **PHS-T66** | **Move Compatibility** | **[x] Completed** | Species-side TM/HM and bitwise Tutor edits are implemented, and Moves now has a move-centric compatibility checklist that stages TM/HM/Tutor species drafts without bypassing source-write gates. |
| **PHS-T67** | **Trainer Hardening** | **[x] Completed** | Searchable trainer constants, party species previews, reset-to-default moves, and party add/remove mutation proof are implemented for classic trainer profiles. |

## Phase 2: Workflow Activation
| Task ID | Component | Status | Progress Audit |
| :--- | :--- | :--- | :--- |
| **PHS-T68** | **Graphics Import** | **[ ] Backlog** | Infrastructure exists (AssetLinks), but execution triggers are not yet active. |
| **PHS-T69** | **Patch & Export** | **[ ] Backlog** | No changes. |
| **PHS-T70** | **Build Runner** | **[ ] Backlog** | No changes. |

---

## Technical Debt & Infrastructure Improvements
- **Generalised Pickers**: The transition of `SearchableConstantPicker` to a protocol-based system (`PickerConstant`) allows for rapid implementation of editors for any constant-backed field (Items, Types, etc.).
- **Tutor Macro Logic**: Successfully implemented bitwise macro rendering (`TUTOR(MOVE)`) which was a blocker for Emerald/FireRed compatibility.
- **Test Coverage**: Added focused apply/reload coverage in `PokemonSpeciesCatalogTests` and `TrainerCatalogTests`, plus app-target build proof for the SwiftUI remediation surfaces.

## Next Steps
1. **PHS-T68 (Graphics Import Execution)**: Keep source-write execution behind explicit tool readiness, mutation plans, and backups.
2. **PHS-T69 (Patch & Export)**: Promote patch apply/export only after checksum/header/backups are fully planned.
3. **PHS-T70 (Integrated Build Runner)**: Prototype `make` build execution with log capture and artifact verification.
