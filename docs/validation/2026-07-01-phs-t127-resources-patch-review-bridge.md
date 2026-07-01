# PHS-T127 Resources-To-Patch Review Bridge

## Scope

Build/Patch/Playtest Patch Library rows now append app-only Resources workflow facet context for the selected project. The rows are derived from the existing selected asset catalog and `ResourceAssetWorkflowFacet` classification, adding one summary row plus bounded facet rows with counts and sample resource paths when those facets are present.

Before opening the row, the live board ended at `PHS-T126`, no `PHS-T127` existed, and duplicate Active Board IDs were clean.

## Proof

- `cd PokemonHackStudio && POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath ../DerivedData/PokemonHackStudio-PHS-T127 -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testPatchLibraryRowsIncludeResourcesWorkflowFacetContextWithoutChangingPatchAuthority -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testResourceAssetWorkflowFacetFilteringAndGrouping -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testNDSResourceEditorKeepsHiddenDirtyDraftVisibleAndRedactsEvidence -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testNDSSourceResourceRecordEditsPreviewApplyAndBlockBinaryRows -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testPatchCreationRefreshesPatchLibraryAndSelectsCreatedBPSArtifact test` (passed)
- `make verify` (passed; generated plists/project, built the app, and completed the verify script with existing locked-device, ad-hoc signing, bundle-script, and `allowedFileTypes` warnings only)
- `git diff --check` (passed)

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackStudio/Stores/WorkbenchStore.swift`
- `PokemonHackStudio/Sources/PokemonHackStudio/Views/Editors/BuildWorkbenchView.swift`
- `PokemonHackStudio/Tests/PokemonHackStudioTests/MapEditorStoreTests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/README.md`
- `docs/validation/2026-07-01-phs-t127-resources-patch-review-bridge.md`

Other dirty core/app/test/docs paths were present before or outside this app-only slice and were preserved.

## Posture

This row is app/store/view/test/docs only. It triggers only the existing asset catalog load, keeps Patch Library Re-check, Copy JSON, and Reveal as the only Patch Library actions, and does not change Copy Report JSON shape. It adds no parser behavior, CLI/schema change, source-write path, NDS or Gen V apply, extraction, export, patch apply/export authority, build/playtest execution, ROM write, reference edit, or new mutation authority. NDS Preview, Apply, and Discard remain governed by existing gates.
