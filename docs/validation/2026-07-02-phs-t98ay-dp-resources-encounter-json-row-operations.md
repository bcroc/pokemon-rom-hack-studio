# PHS-T98AY DP Resources Encounter JSON Row Operations

## Summary

`PHS-T98AY` wires the existing Diamond/Pearl encounter JSON row-operation planner path into the Resources NDS editor for eligible local `files/fielddata/encountdata/**/*.json` source-tree object arrays.

The accepted implementation plan named `PHS-T98AX`, but the live validation ledger already assigns `PHS-T98AX` to NDS blocked editability regression proof. This closeout therefore uses the next unused live-board suffix, `PHS-T98AY`.

## Scope

- Reused the existing app-memory staging, preview, apply, discard, and hidden-draft gates.
- Reused the existing `NDSDataEncounterJSONRowOperationPlanner` and `NDSDataMutationApplier.apply` path.
- Derived selectable targets from profile-aware semantic snapshot field keys such as `slots.0.rate`.
- Kept scalar arrays such as `swarms`, rows without object-array targets, C anchors, non-JSON rows, generated/reference/container rows, CLI/schema changes, NARC/container work, ROM rebuild/export/playtest, persisted workspace schema changes, generated/reference writes, and binary writes blocked.

## Proof

```sh
swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests/testNDSDataEncounterJSONRowOperationPlannerHeartGoldSoulSilver|PokemonHackCLITests/testNDSDataEncounterJSONRowOperationCommandsHeartGoldSoulSilver'
```

First attempt stopped before tests executed with a transient SwiftPM `NDSDataCatalog.swift` "modified during the build" race. Rerun passed: 2 selected tests, 0 failures.

```sh
POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T98AY-DPEncounterRows -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testDiamondPearlEncounterJSONRowOperationsFlowThroughResourceEditor test
```

Passed. Existing `allowedFileTypes`, ad-hoc signing, and bundle-script warnings only.

```sh
make validate-nds
```

Passed: 129 selected tests, 0 failures. Central NDS reference smokes skipped because `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky` were not present under `/Users/bryan/projects/reference-repos/repos`.

```sh
git diff --check
```

Passed.
