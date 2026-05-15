# Product Architecture

PokemonHackStudio is a local-first macOS tool for editing Pokemon GBA hacks from decompilation source trees first, while growing read-only NDS source/ROM intelligence. ROM patching, binary inspection, and NDS container catalogs are support workflows until mutation-plan backed writers exist. The app should help creators make deliberate changes, preview likely outcomes, and produce reproducible build artifacts without hiding the underlying project structure.

## Workspace Model

- `PokemonHackStudio/` is the product surface: SwiftUI app, shared core library, CLI, configuration, and tests.
- `pokeemerald/` and `pokefirered/` are editable source-tree workspaces. They are the preferred targets for content, data, script, map, and build-system changes.
- Root `.gba` files are local base ROM inputs for comparison, extraction, or patch generation. They should not become the canonical editing surface.
- `references/` is read-only research material unless a task explicitly says otherwise; `/Users/bryan/projects/reference-repos` is the canonical reference metadata and clone corpus.
- `agbcc/` is toolchain support for the decompilation builds.
- `script/` is reserved for repo-level automation that does not belong in the app package.

## Package Shape

The intended Swift package layout is:

- `PokemonHackStudio/Sources/PokemonHackStudio`: SwiftUI macOS app shell, navigation, document windows, inspectors, editors, previews, and user-facing state.
- `PokemonHackStudio/Sources/PokemonHackCore`: reusable domain logic for project discovery, source-tree parsing, asset indexing, patch planning, validation, diagnostics, and build orchestration.
- `PokemonHackStudio/Sources/pokemonhack-cli`: command-line entrypoint for automation, smoke checks, batch imports, validation, export, and future CI-friendly workflows.
- `PokemonHackStudio/Tests/PokemonHackCoreTests`: focused tests for parsers, path handling, mutation plans, patch manifests, and validation rules.
- `PokemonHackStudio/Config`: app defaults, schema descriptors, editor registries, and non-secret local configuration templates.

Keep UI state and platform integration in the app target. Keep file formats, data models, source mutations, patch generation, and validation in `PokemonHackCore`. The CLI should call the same core APIs as the app rather than reimplementing workflows.

## Reference-Driven Core Lanes

Reference review is captured in `docs/reference-synthesis.md`. The implementation should grow through four cooperating lanes:

- Decomp project graph: source-tree adapters index maps, layouts, scripts, constants, C initializer tables, trainer data, graphics, generated files, and build targets.
- NDS resource graph: read-only NDS ROM/source adapters index NitroFS, overlays, NARC/member rows, Gen IV data catalogs, source markers, and manual build/playtest readiness without enabling writes.
- Binary ROM graph: ROM adapters index local `.gba` inputs as semantic byte ranges, pointers, anchors, checksums, metadata, diffs, and patch plans.
- Build and patch pipeline: build targets, generated-data checks, patch parsing, checksum validation, patch manifests, and export plans stay in `PokemonHackCore`.
- Emulator and playtest bridge: interactive run and headless validation use mGBA-compatible boundaries, with Swift owning the product state and any emulator bridge kept isolated.

Adapters declare supported files, generated outputs, write policy, modules, capabilities, and validators. They should be read-heavy first; write paths must go through mutation plans.

## Source-Tree-First Editing

Default behavior should preserve a clear edit path back to decompilation files:

- Prefer modifying C, assembly, data, constants, graphics, maps, scripts, and build inputs in `pokeemerald/` or `pokefirered/`.
- Model every write as a previewable mutation plan before applying it.
- Use stable project-relative paths in manifests and diagnostics.
- Keep source edits small enough that they remain reviewable in Git.
- Use ROM-level binary edits only when no source-tree path is available, and mark them as binary-only in the UI and generated manifests.

The app should make the source location visible for each editable object. For example, a Pokemon species editor should show the backing constants/data files; a map editor should expose map data paths and related scripts.

## Generated Artifacts

Generated outputs should be reproducible, clearly labeled, and kept out of hand-authored source areas.

- Build products, patched ROMs, extracted assets, generated previews, indexes, logs, and temporary manifests are artifacts, not source.
- Prefer an explicit generated-output directory under the active workspace when workflows need persisted outputs.
- Never treat generated indexes as authoritative when the source tree can be parsed again.
- Generated files should include enough metadata to identify source project, base ROM hash when relevant, tool version, command or workflow, and timestamp.
- Do not commit generated ROMs, caches, build products, or local indexes unless a future policy explicitly marks a specific artifact as review material.

Durable source changes should be represented as source-tree diffs, patch manifests, or documented commands that can reproduce the artifact.

## Core Services

`PokemonHackCore` should grow around narrow services:

- Project discovery: identify Emerald, FireRed, Ruby/Sapphire, Expansion, GBA binary ROM, NDS binary ROM, pret-style NDS source trees, and future Gen 3/Gen 4 project shapes.
- Adapter registry: select the appropriate `GameAdapter` and expose a `ProjectIndex`.
- Source index: map domain objects to source files, source spans, generated build products, and adapter capabilities.
- Parser layer: read structured source data without ad hoc text replacement where a safer parser or table model exists.
- Mutation planner: produce reviewable edits and diagnostics before writing files.
- Build runner: invoke project build commands and capture logs without embedding build assumptions in SwiftUI views.
- Patch runner: create and verify distributable patches from known base ROMs and built outputs.
- Emulator bridge: launch or hand off built ROMs to an emulator for smoke testing.

Each service should be testable without launching the SwiftUI app.

## CLI Responsibilities

The CLI is the automation companion for the app:

- `inspect`: summarize detected project type, paths, build targets, and known assets.
- `index`: emit or refresh the adapter-selected source graph, generated-output policy, and cacheable index data.
- `validate`: run non-mutating checks for path integrity, source parseability, and artifact freshness.
- `build`: report selected decomp build targets, output existence, checksums, freshness, and tool readiness before any future build execution.
- `patch`: parse and verify patch metadata, base-ROM compatibility, and dry-run manifests before any future patch apply/export.
- `playtest`: prepare headless mGBA-compatible run plans and explicitly launch runnable interactive handoffs through the external emulator boundary.
- `migration-coverage`: report source-first, read-only, migration-plan-only, binary-only, and blocked domains across GBA/NDS inputs so CLI and app-facing diagnostics share one fact model before ROM asset migration planning.

Repo-level validation should keep `make validate` as the canonical local proof, with `make validate-nds` as the opt-in central NDS reference smoke. App-hosted Xcode tests should use a unique DerivedData path for each focused ladder to avoid shared build database locks.

CLI output should be script-friendly by default, with JSON output available for workflows that feed back into the app or tests.

## Licensing And Content Boundaries

This repository contains or references projects with different licenses and content rules. Keep boundaries explicit:

- Do not copy reference implementation code into the app without checking the referenced license and documenting attribution.
- Do not redistribute commercial ROM content or generated ROMs.
- Prefer patch distribution, source diffs, and reproducible build instructions.
- Keep proprietary game assets and user-provided ROMs local unless a future release process defines a lawful alternative.
- Treat reference repositories as learning material and compatibility targets, not as a pool of code to paste from.

When borrowing behavior from a reference project, record the idea and link to the source. When borrowing code, perform a license review first.
