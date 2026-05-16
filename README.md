# PokemonHackStudio

PokemonHackStudio is a local-first macOS workbench for Pokemon Generation III ROM hacking. The project is source-tree-first: decompilation projects are the canonical editing surface, while ROM inspection, patching, and playtest workflows support validation and migration.

The completed baseline is tracked in `docs/planning-and-progress.md`; read that live workboard before choosing implementation work. New implementation work should start from the Active Board candidate rows.

## Repository Layout

| Path | Purpose |
| --- | --- |
| `PokemonHackStudio/` | Swift package, SwiftUI app, shared `PokemonHackCore` library, CLI, and tests. |
| `docs/` | Product architecture, reference synthesis, planning, and live progress tracking. |
| `script/` | Root-level automation for local development and app launch. |
| `references/manifest.json` | Tracked catalog of read-only reference repositories and license/risk notes. |
| `.codex/` | Local Codex environment metadata for this workspace. |

Local fixtures and generated outputs stay out of Git:

- `pokeemerald/`, `pokefirered/`, and `agbcc/` are local decomp/toolchain fixtures.
- `references/*` clones are read-only research material; only `references/manifest.json` is tracked.
- `*.gba`, saves, patched ROMs, build output, `DerivedData/`, and SwiftPM/Xcode caches are ignored.

## Quick Start

```sh
make validate
```

Common commands:

```sh
make test       # Swift package tests
make build      # Swift package build
make validate   # Tests plus CLI smoke checks
make scripts-check  # Shell syntax and app-build tool preflight
make test-app   # Generate the Xcode project and run app-hosted tests
make run        # Generate the Xcode project, build the app, and launch it
make verify     # Build and verify the app process launches
```

The app launch helpers require `xcodegen` and Xcode command line tools. The SwiftPM validation path only requires the Swift toolchain.

## CLI Smoke Checks

The validation script runs:

```sh
swift test --package-path PokemonHackStudio
swift build --package-path PokemonHackStudio --product pokemonhack-cli
PokemonHackStudio/.build/debug/pokemonhack-cli references --json
PokemonHackStudio/.build/debug/pokemonhack-cli inspect pokeemerald --json
PokemonHackStudio/.build/debug/pokemonhack-cli maps pokeemerald --json
PokemonHackStudio/.build/debug/pokemonhack-cli map-visual pokeemerald MAP_MAUVILLE_CITY --json
PokemonHackStudio/.build/debug/pokemonhack-cli playtest pokeemerald --headless --json
```

The `pokeemerald`, `pokefirered`, and `references/pokeruby` checks are skipped when the local fixture is not present. Set `GBA_FIXTURE_ROOT`, or the narrower `POKEEMERALD_FIXTURE_ROOT`, `POKEFIRERED_FIXTURE_ROOT`, and `POKERUBY_REFERENCE_FIXTURE_ROOT`, to point validation at alternate fixtures. Set `REQUIRE_GBA_FIXTURES=1` to fail when those fixtures are missing.

## Operating Boundaries

- Do not commit commercial ROMs, generated ROMs, saves, patches, decomp build products, local indexes, or build caches.
- Do not copy code, schemas, tests, UI text, or assets from reference repositories without a license review and attribution plan.
- Keep product writes preview-first through mutation plans and diagnostics before applying source changes.
- Prefer project-relative paths in docs, diagnostics, manifests, and generated reports.
- Treat generated files as reproducible artifacts unless a future adapter explicitly marks one as source.
