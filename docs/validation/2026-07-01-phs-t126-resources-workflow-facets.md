# PHS-T126 Resources Workflow Facets

## Scope

Resources Assets mode now filters and groups app-facing rows by workflow state using existing `ResourceAssetRowViewState` facts, readiness diagnostics, current hidden NDS draft keys, and existing `NDSDataMutationPlanner.editabilityDiagnostics`.

The accepted plan named `PHS-T124`, but the live planning board already assigned `PHS-T124` to Patch Creation Verification and `PHS-T125` to the read-only Patch Library. This closeout is recorded as `PHS-T126` to keep Active Board IDs unique.

## Proof

- `cd PokemonHackStudio && POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath ../DerivedData/PokemonHackStudio-PHS-T124 -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testResourceAssetWorkflowFacetFilteringAndGrouping -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testResourceAssetSelectionSurvivesWorkflowFiltersThatHideTheRow -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testNDSResourceEditorKeepsHiddenDirtyDraftVisibleAndRedactsEvidence -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testNDSSourceResourceRecordEditsPreviewApplyAndBlockBinaryRows -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testRelatedResourceWorkflowFacetKeepsRelatedRowNavigation -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testResourceBacklinksForceMatchingResourceMode test` (passed; existing `allowedFileTypes`, ad-hoc signing, bundle-script, and locked-device warnings only)
- `make verify` (passed; generated plists/project, built the app, and completed the verify script)
- `git diff --check` (passed)

## Posture

This row is app/store/view/test/docs only. It adds no parser behavior, source-write paths, NDS or Gen V apply, extraction, export, ROM writes, reference edits, or new mutation authority. NDS Preview, Apply, and Discard remain governed by existing `canPreview`, `canApply`, and `canDiscard` readiness/apply diagnostics.
