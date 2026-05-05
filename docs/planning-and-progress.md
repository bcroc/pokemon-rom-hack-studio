# PokemonHackStudio Planning And Progress

## Current Focus

`PHS-T1` is complete. The next ready lane is `PHS-T2`: script/text and C table indexing, with FireRed positional item data handled as a separate design.

## Active Board

| ID | Status | Title | Notes |
| --- | --- | --- | --- |
| PHS-T1 | Done | Map/Layout Viewer | Read-only core map catalog, CLI `maps`, SwiftUI Maps surface, and fixture fallback are implemented and verified. |
| PHS-T2 | Ready | Script/Text And C Table Indexing | Add script/text outlines and table-aware species/trainers/items/moves indexes after PHS-T1 core catalog lands. |
| PHS-T3 | Ready | Build/Patch/Playtest Validation Polish | Tighten CLI/app validation flows, patch summaries, generated-output checks, and playtest planning. |

## Recent Progress

- `PHS-T1` delivered a live `ProjectIndex`-backed Maps view for `pokeemerald` and `pokefirered`, including group/map navigation, layout metadata, event counts, connections, source links, diagnostics, and capped blockdata previews.
- ProjectIndex-backed dashboard slice is complete and verified.
- Reference synthesis and product architecture docs are in place.
- Current implementation remains read-only and mutation-plan-only.

## Validation Ledger

For each completed row, record the focused commands that proved the slice. Generated ROMs, local indexes, and build products remain untracked artifacts.

- `PHS-T1`:
  - `swift test --package-path PokemonHackStudio`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli maps pokeemerald --json`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli maps pokefirered --json`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli validate pokeemerald --json`
  - `swift run --package-path PokemonHackStudio pokemonhack-cli validate pokefirered --json`
  - `cd PokemonHackStudio && xcodegen generate`
  - `xcodebuild -project PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath ../DerivedData/PokemonHackStudio build`
  - `./script/build_and_run.sh --verify`
  - Manual app smoke: opened Maps with repo-local `pokeemerald`, selected `MauvilleCity`, and verified live layout facts, event counts, connections, source links, and metatile-ID preview.
