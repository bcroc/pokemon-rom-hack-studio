# PHS-T78AE Expansion All Learnables App Review Visibility

Date: 2026-07-02

## Scope

`PHS-T78AE` is the app-only all-learnables review visibility follow-up after `PHS-T78AD`.

Resources now gives generated `src/data/pokemon/all_learnables.json` rows a focused All Learnables Regeneration Review detail section from existing coverage/regeneration facts, and Build/Patch/Playtest adds a copy-only review row derived from the loaded asset catalog. The row copies generated path, report commands, and a review summary only.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'PokemonDataCompatibilityTests/testExpansionAllLearnablesCoverageCountsGeneratedSourceAndMoveMismatches|PokemonHackCLITests/testPokemonCompatibilityAndAssetIndexCommandsEmitExpansionAllLearnablesFacts'`
  - Passed with 2 selected tests and 0 failures.
  - Rechecked compatibility coverage and CLI asset-index JSON facts without schema changes.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T78AE-AllLearnablesReview -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testAllLearnablesRegenerationReviewRowsSurfaceCopyOnlyPlan test`
  - Passed with app-hosted store proof for Resources selection, Build/Patch copy-only review row, copy actions, and unchanged generated JSON bytes; existing `allowedFileTypes`, ad-hoc signing, and build-script warnings only.
- `git diff --check`
  - Passed.

## Boundaries

App visibility only. Generated `src/data/pokemon/all_learnables.json` is parsed/reported from existing Resources and compatibility facts only; no regeneration command execution, generated JSON write, learnset row insertion, constants edit, reference edit, ROM/build/export artifact, binary write, Core writer API, CLI command, or JSON schema change was added.

## Unrelated Dirty Work

Pre-edit `git status --short --branch` was clean for this row, but unrelated dirty NDS, validation, script, app, and docs files appeared during implementation/validation and were preserved outside it. Several changed files also contained unrelated dirty edits, preserved.
