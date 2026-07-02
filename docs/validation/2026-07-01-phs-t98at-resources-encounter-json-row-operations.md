# PHS-T98AT Resources Encounter JSON Row Operations

Date: 2026-07-01

## Scope

`PHS-T98AT` implements the Resources app controls for Platinum encounter JSON row operations. The requested plan named `PHS-T98AS`, but the live validation ledger and planning summary already use `PHS-T98AS` for HeartGold/SoulSilver encounter JSON row operations, so this app-controls follow-up uses the next suffix.

Eligible Resources rows are local Platinum source-tree `.encounters` records at `res/field/encounters/*.json` with existing object-array semantic fields such as `land_encounters.0.level`. The app derives non-persisted array targets from those existing semantic field keys, stages insert/delete/reorder operations in app memory, and previews/applies through the existing `NDSDataEncounterJSONRowOperationPlanner` and `NDSDataMutationApplier.apply` path.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests/testNDSDataEncounterJSONRowOperationPlanner|PokemonHackCLITests/testNDSDataEncounterJSONRowOperationCommands'`
  - Passed: 4 selected tests, 0 failures. The selector also matched the existing HeartGold/SoulSilver encounter JSON row-operation planner and CLI tests.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T98AS-ResourcesEncounterRows -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testPlatinumEncounterJSONRowOperationsFlowThroughResourceEditor test`
  - Passed with existing `allowedFileTypes`, ad-hoc signing, and bundle-script warnings only.

## Guardrails

The Resources controls are app-only. They do not add a core writer, parser, CLI command, persisted workspace schema, NARC/container path, generated/reference write, ROM rebuild/export/playtest path, or binary write.

Scalar arrays such as `swarms`, rows without object-array semantic targets, nested encounter directories, non-JSON rows, generated/reference/container rows, broad schema reshaping, and binary writes remain blocked by the existing eligibility and planner/apply gates.
