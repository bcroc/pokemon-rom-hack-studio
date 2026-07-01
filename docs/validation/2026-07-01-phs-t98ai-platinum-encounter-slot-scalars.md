# PHS-T98AI Platinum Encounter Slot Scalar Fields

## Scope

`PHS-T98AI` opens the Platinum encounter slot scalar follow-up after the live board assigned `PHS-T98AG` to Platinum text line row operations and `PHS-T98AH` to Diamond/Pearl encounter loader-only readiness.

This row covers eligible local Platinum source-tree encounter JSON rows:

- `res/field/encounters/*.json`

The semantic editor exposes existing top-level scalars, existing scalar-array slots such as `swarms.0`, and existing object-array slot scalar fields such as `land_encounters.0.level` and `land_encounters.0.species`.

## Original Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/NDSDataEditing.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/NDSDataCatalogTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `PokemonHackStudio/Tests/PokemonHackStudioTests/MapEditorStoreTests.swift`
- `docs/nds-extension-plan.md`
- `docs/planning-and-progress.md`

## Write Posture

The path reuses the existing NDS semantic draft, `NDSDataEditPlan`, redacted preview, source hash/size freshness checks, explicit apply, backups, and catalog reload gate. It does not add a new CLI command, public writer family, app-only writer, NARC/container writer, generated/reference mutation, ROM rebuild/export, playtest launch, or binary write path.

Still blocked:

- container keys
- slot object edits
- slot insert/delete/reorder
- nested object reshaping
- nested directories
- non-JSON rows
- HGSS/DP rows
- NARC/container work
- generated/reference writes
- ROM rebuild/export
- binary writes

## Proof

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/pokemonhack-phs-t98ag-focused-build --filter 'NDSDataCatalogTests/testNDSDataSemanticEditorPlansPlatinumEncounterRateJSONScalars|PokemonHackCLITests/testNDSDataSemanticCommandsPlanAndApplyPlatinumEncounterJSONFields'`: passed, 2 selected tests and 0 failures. Covered top-level encounter scalars, scalar-array slots, object-array slot scalar fields, redacted CLI output, semantic apply/backups, and nested-object/missing-slot refusals.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T98AI-PlatinumEncounterSlots -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testPlatinumEncounterSlotSemanticFieldEditsFlowThroughResourceEditor test`: passed. App Resources exposes Platinum encounter slot scalar fields, previews/applies one slot edit, and clears blocked-row drafts; existing `allowedFileTypes`, ad-hoc signing, and build-script warnings only.
- `bash -n script/*.sh`: passed.
- `make validate-nds`: passed, 109 selected NDS/core/CLI tests and 0 failures, including the Platinum encounter semantic core/CLI coverage. Central clean-room reference smokes skipped because `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky` were not present under `/Users/bryan/projects/reference-repos/repos`.
- `git diff --check`: passed after docs/proof reconciliation.

## Known Outside-Slice Failure

`make validate` ran the full SwiftPM suite and failed outside this slice: `PokemonHackCoreTests.PokemonMoveCatalogTests/testRubySapphireContestMoveFactsJoinToBattleMoveRowsWhenPresent` failed at `PokemonMoveCatalogTests.swift:381` because the Ruby/Sapphire contest metadata blocked-actions fact did not contain `combo array editing`; 466 tests executed with 1 failure.
