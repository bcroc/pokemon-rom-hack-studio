# Reference Improvement Audit

Generated from the May 6, 2026 broad Pokemon GBA ROM-hacking reference sweep. This audit compares the pinned reference bench against the current PokemonHackStudio codebase and identifies implementation improvements without copying reference code, schemas, tests, UI text, or assets.

## Scope And Guardrails

- New broad-sweep clones: `porylive`, `porymoves`, `porypal`, `porysuite`, `team-aquas-asset-repo`, `libtonc`, `gba-tools`, `grit`, `pokeemerald-jp`, `berry-fix`, `modern-emerald`, `dynamic-pokemon-expansion`, `cfru-generator`, `pokemapexport`, `universal-gba-pokedex`, `frame`, `porydelete`, and `pokedata`.
- Existing reference bench retained: `porymap`, `poryscript`, `porytiles`, `pokeemerald`, `pokefirered`, `agbcc`, `pokeemerald-expansion`, `hex-maniac-advance`, `rompatcher-js`, `mgba`, `pokeruby`, and `pokemon-game-editor`.
- `references/manifest.json` is the tracked catalog. Clone directories remain ignored and read-only.
- Reuse posture remains clean-room: references can inform behavior, compatibility, diagnostics, and product shape, but copied code/assets require a separate license decision.
- `PHS-T18` is already the completed Generation III resource-library row, so new broad-sweep candidate rows begin at `PHS-T19`.

## Current Codebase State

- `PHS-T1` through `PHS-T12` established the source-first workbench baseline: project indexing, live map/layout viewing, visual map editing, source mutation planning, script outlines, table/source indexes, build/patch/playtest reports, and the all-in source workbench shell.
- `PHS-T15` now starts the Graphics module as read-only diagnostics. It inventories tileset graphics under `data/tilesets`, reports tile image/palette/metatile/attribute artifacts, SHA1s, generated-output freshness, layer modes, animation folders, source-asset warnings, and graphics diagnostics through core models, CLI JSON, and the SwiftUI Graphics module.
- Source-tree writes remain mutation-plan-first. Graphics diagnostics do not invoke Porytiles, grit, agbcc, mGBA, or any other external tool, and do not mutate ROMs or decomp files.
- The remaining broad gap is app-visible related-data UX. Core/CLI graph depth, patch-manifest planning, and playtest artifact planning now exist as clean-room Swift models, while live emulator capture and mutation editors remain future work.

## High-Value Improvements

| Priority | Area | Reference signal | Current gap | Recommended next work |
| --- | --- | --- | --- | --- |
| 1 | Moves/learnsets | PoryMoves, pret repos, Expansion, PokeData | Done in `PHS-T19`: core/CLI graph plus Pokemon workbench consumption. | Future work is mutation-plan editing, not graph discovery. |
| 2 | Species/Pokedex graph | Universal-GBA-Pokedex, PokeData, Expansion, PGE | Done in `PHS-T20`: species, evolution, Pokedex, asset, and related-data graph plus app detail surfaces. | Cries/forms remain future detail work. |
| 3 | Live script loop | Porylive, Poryscript, mGBA | Done in `PHS-T21`: `script-readiness` evaluates selected map/script source, build, and playtest prerequisites. | Hot reload remains out of scope until structured script editing is trustworthy. |
| 4 | Patch manifests | RomPatcher.js, berry-fix, cfru-generator | Done in `PHS-T22`/`PHS-T14`: patch metadata, base-ROM candidates, compatibility, dry-run steps, and app report surface. | Patch apply/export remains locked behind future explicit scope. |
| 5 | Toolchain and ROM headers | agbcc, gba-tools, grit, libtonc, pret repos | Done in `PHS-T23`: external-tool, ROM-header, graphics-conversion, and generated-artifact health matrix. | Future work can promote selected checks into guided setup actions. |
| 6 | Playtest bridge | mGBA, Porylive | Done in `PHS-T24` and `PHS-T40`: playtest artifacts plus explicit external mGBA launch for runnable handoffs. | Screenshot/savestate capture remains future work. |
| 7 | All-in-one related UX | PorySuite, HMA, PGE, PokeData | Done in `PHS-T25`: Resources rows navigate across maps, layouts, scripts, Pokemon, trainers, graphics, build rows, text, and items. | Future work can deepen record-specific context panels. |
| 8 | Asset import/provenance | Team Aqua Asset Repo, porypal, Porytiles, grit | Graphics diagnostics are read-only and do not model credit/provenance for local asset imports yet. | Later, add asset import plans with credit metadata and conversion previews before any write path. |
| 9 | Binary ROM graph | HMA, PGE, Frame, Dynamic Pokemon Expansion | Binary ROM adapter is still a fallback lane. | Keep `PHS-T17` as a later semantic ROM graph baseline with runs, anchors, pointers, and repoint planning. |

## Candidate Workboard Rows

| ID | Title | Intent | Minimal proof |
| --- | --- | --- | --- |
| PHS-T15 | Graphics And Tileset Diagnostics | Read-only graphics report with artifact inventory, checksums/freshness, palette/metatile/layer diagnostics, animation presence, and generated-output warnings. | Focused Swift tests, CLI JSON for `pokeemerald` and `pokefirered`, app Graphics smoke, `make validate`, and `make verify`. |
| PHS-T19 | Moves And Learnset Source Graph | Done: move and learnset data is promoted from generic source records into a cross-linked read-only graph. | `PokemonDataGraphTests`, `moves-graph` CLI JSON, `make test`, `make validate`. |
| PHS-T20 | Species Data Graph | Done: species/evolution/Pokedex/assets/learnsets now form a closed read-only related-data graph for later safe editors. | `PokemonDataGraphTests`, `species-graph` CLI JSON, `make test`, `make validate`. |
| PHS-T21 | Live Script Readiness | Done: report map/script/playtest prerequisites for future live script iteration. | CLI/app `script-readiness` report for selected map scripts without invoking emulator mutation. |
| PHS-T22 | Patch Manifest Models And CLI | Done: model base ROM candidates, patch metadata, compatibility status, and dry-run plans without patch apply/export. | `BuildPatchPlaytestValidationTests`, synthetic/project-backed `patch-manifest` CLI smokes, `make validate`. |
| PHS-T23 | Toolchain Health Matrix | Done: make external tool, ROM header, graphics conversion, and generated-artifact health visible. | Tool discovery fixtures and local decomp report smokes. |
| PHS-T24 | mGBA Playtest Artifact Plans | Done: strengthen external emulator handoff with planned run logs, stdout/stderr, screenshot, and headless savestate artifacts. | `BuildPatchPlaytestValidationTests`, `make test`, `make validate`. |
| PHS-T25 | All-In-One Related Data UX | Done: app-visible related-data navigation between current module records. | App smoke showing cross-links without widening write policy. |
| PHS-T41 | Live Encounters Module | Candidate: replace fixture Encounters with live read-only wild encounter rows. | Store/app smoke showing live rows and source links. |
| PHS-T42 | Structured Script Command Editing | Candidate: move beyond raw script body editing into structured mutation plans. | Parser/planner tests plus Maps app smoke with no generated/shared writes. |
| PHS-T43 | Wild Encounter Row Editing | Candidate: preview/apply wild encounter row edits with order preservation and backups. | Planner/apply tests plus Maps smoke. |
| PHS-T44 | Graphics Import And Conversion Plans | Candidate: model import provenance, credit, and conversion plans before writes. | Plan-only diagnostics and disabled-write app smoke. |

## Adoption Notes

- `PHS-T15` is the first adopted broad-sweep idea and stays read-only: it borrows diagnostics vocabulary and workflow pressure from Porytiles, porypal, libtonc, grit, and Team Aqua Asset Repo without invoking or copying them.
- `PHS-T19`, `PHS-T20`, `PHS-T22`, and `PHS-T24` are implemented as independent Swift models and CLI/report surfaces; they do not copy reference schemas, UI text, assets, tests, or generated data.
- `PHS-T16` adopts map workflow pressure clean-room through autocomplete, read-only wild encounter indexing, source snapshot checks, and connection diagnostics; order-preserving row edits remain future work before any wild encounter mutation path.
- GPL/LGPL/MPL/custom/no-license references are behavioral references unless a future legal/reuse review creates a compatible boundary.
- MIT/Apache references can still remain conceptual. The default for PokemonHackStudio is independent Swift models that preserve source paths, unknown fields, and mutation-plan boundaries.
- Asset repositories are provenance and credit references only. No third-party art should be bundled, copied, or exported from PokemonHackStudio without asset-by-asset permission and attribution review.
