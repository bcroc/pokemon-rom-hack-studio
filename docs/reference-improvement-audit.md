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
| 1 | Moves/learnsets | PoryMoves, pret repos, Expansion, PokeData | Core/CLI `PHS-T19` move and learnset graphs now exist; app/editor surfaces still need to consume them. | Use the graph in Pokemon/Resources UX and future mutation-plan editors. |
| 2 | Species/Pokedex graph | Universal-GBA-Pokedex, PokeData, Expansion, PGE | Core/CLI `PHS-T20` species, evolution, Pokedex, asset, and related-data graph now exists; cries/forms and app browsing are still future work. | Surface the graph through app backlinks before form edits. |
| 3 | Live script loop | Porylive, Poryscript, mGBA | Script outlines exist, but live-readiness and emulator handoff checks are not script-aware. | Add `PHS-T21` live script readiness report; keep hot reload out of scope until the report is trustworthy. |
| 4 | Patch manifests | RomPatcher.js, berry-fix, cfru-generator | `PHS-T22` patch-manifest models and CLI now report base-ROM candidates, compatibility, and dry-run steps; app export/share polish remains shallow. | Build the app workbench around the plan-only report before patch apply/export. |
| 5 | Toolchain and ROM headers | agbcc, gba-tools, grit, libtonc, pret repos | Build/playtest reports check broad readiness, but not detailed ROM header/toolchain/conversion health. | Add `PHS-T23` toolchain health matrix, including external-tool boundaries and generated-artifact explanations. |
| 6 | Playtest bridge | mGBA, Porylive | `PHS-T24` playtest sessions now describe expected logs, stdout/stderr, screenshots, and headless savestates; actual launch/capture hooks remain future work. | Add external artifact capture only after the handoff plan is stable. |
| 7 | All-in-one related UX | PorySuite, HMA, PGE, PokeData | Core related-data nodes/edges now exist for species/moves/learnsets/Pokedex/assets, but app-visible cross-links remain thin. | Add `PHS-T25` related-data navigation and workspace context. |
| 8 | Asset import/provenance | Team Aqua Asset Repo, porypal, Porytiles, grit | Graphics diagnostics are read-only and do not model credit/provenance for local asset imports yet. | Later, add asset import plans with credit metadata and conversion previews before any write path. |
| 9 | Binary ROM graph | HMA, PGE, Frame, Dynamic Pokemon Expansion | Binary ROM adapter is still a fallback lane. | Keep `PHS-T17` as a later semantic ROM graph baseline with runs, anchors, pointers, and repoint planning. |

## Candidate Workboard Rows

| ID | Title | Intent | Minimal proof |
| --- | --- | --- | --- |
| PHS-T15 | Graphics And Tileset Diagnostics | Read-only graphics report with artifact inventory, checksums/freshness, palette/metatile/layer diagnostics, animation presence, and generated-output warnings. | Focused Swift tests, CLI JSON for `pokeemerald` and `pokefirered`, app Graphics smoke, `make validate`, and `make verify`. |
| PHS-T19 | Moves And Learnset Source Graph | Done: move and learnset data is promoted from generic source records into a cross-linked read-only graph. | `PokemonDataGraphTests`, `moves-graph` CLI JSON, `make test`, `make validate`. |
| PHS-T20 | Species Data Graph | Done: species/evolution/Pokedex/assets/learnsets now form a closed read-only related-data graph for later safe editors. | `PokemonDataGraphTests`, `species-graph` CLI JSON, `make test`, `make validate`. |
| PHS-T21 | Live Script Readiness | Report map/script/playtest prerequisites for future live script iteration. | CLI/app readiness report for selected map scripts without invoking emulator mutation. |
| PHS-T22 | Patch Manifest Models And CLI | Done: model base ROM candidates, patch metadata, compatibility status, and dry-run plans without patch apply/export. | `BuildPatchPlaytestValidationTests`, synthetic/project-backed `patch-manifest` CLI smokes, `make validate`. |
| PHS-T23 | Toolchain Health Matrix | Make external tool, ROM header, graphics conversion, and generated-artifact health visible. | Tool discovery fixtures and local decomp report smokes. |
| PHS-T24 | mGBA Playtest Artifact Plans | Done: strengthen external emulator handoff with planned run logs, stdout/stderr, screenshot, and headless savestate artifacts. | `BuildPatchPlaytestValidationTests`, `make test`, `make validate`. |
| PHS-T25 | All-In-One Related Data UX | Still candidate: app-visible related-data navigation between current module records. | App smoke showing cross-links without widening write policy. |

## Adoption Notes

- `PHS-T15` is the first adopted broad-sweep idea and stays read-only: it borrows diagnostics vocabulary and workflow pressure from Porytiles, porypal, libtonc, grit, and Team Aqua Asset Repo without invoking or copying them.
- `PHS-T19`, `PHS-T20`, `PHS-T22`, and `PHS-T24` are implemented as independent Swift models and CLI/report surfaces; they do not copy reference schemas, UI text, assets, tests, or generated data.
- `PHS-T16` adopts map workflow pressure clean-room through autocomplete, read-only wild encounter indexing, source snapshot checks, and connection diagnostics; order-preserving row edits remain future work before any wild encounter mutation path.
- GPL/LGPL/MPL/custom/no-license references are behavioral references unless a future legal/reuse review creates a compatible boundary.
- MIT/Apache references can still remain conceptual. The default for PokemonHackStudio is independent Swift models that preserve source paths, unknown fields, and mutation-plan boundaries.
- Asset repositories are provenance and credit references only. No third-party art should be bundled, copied, or exported from PokemonHackStudio without asset-by-asset permission and attribution review.
