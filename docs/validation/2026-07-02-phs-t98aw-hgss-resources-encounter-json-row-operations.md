# PHS-T98AW HGSS Resources Encounter JSON Row Operations

## Summary

`PHS-T98AW` wires the existing HeartGold/SoulSilver encounter JSON row-operation planner path into the Resources NDS editor for eligible local `files/fielddata/encountdata/**/*.json` source-tree object arrays.

The accepted implementation plan named `PHS-T98AU`, but the live planning board already assigns `PHS-T98AU` to Diamond/Pearl encounter JSON row operations and `PHS-T98AV` to the Gen IV map review Resources bridge. This closeout therefore uses the next unused live-board suffix, `PHS-T98AW`.

## Scope

- Reused the existing app-memory staging, preview, apply, discard, and hidden-draft gates.
- Reused the existing `NDSDataEncounterJSONRowOperationPlanner` and `NDSDataMutationApplier.apply` path.
- Derived selectable targets from profile-aware semantic snapshot field keys such as `slots.0.rate`.
- Kept scalar arrays such as `swarms`, rows without object-array targets, non-JSON/C rows, generated/reference/container rows, CLI/schema changes, NARC/container work, ROM rebuild/export/playtest, persisted workspace schema changes, generated/reference writes, and binary writes blocked.

## Proof

```sh
swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests/testNDSDataEncounterJSONRowOperationPlannerHeartGoldSoulSilver|PokemonHackCLITests/testNDSDataEncounterJSONRowOperationCommandsHeartGoldSoulSilver'
```

Passed: 2 selected tests, 0 failures.

```sh
POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T98AW-HGSSEncounterRows -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testHeartGoldSoulSilverEncounterJSONRowOperationsFlowThroughResourceEditor test
```

Passed. Existing `allowedFileTypes`, ad-hoc signing, and bundle-script warnings only.

`make validate-nds` was not run because this row changed only the app Resources eligibility and target-derivation seam, and the focused HGSS Core/CLI regression passed.

```sh
git diff --check
```

Passed.
