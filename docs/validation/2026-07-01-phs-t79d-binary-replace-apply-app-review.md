# PHS-T79D Binary Replace Apply App Review

`PHS-T79D` opens the Build/Patch/Playtest app review surface for the existing `PHS-T79C` replace-only binary ROM apply path.

The app now loads an existing dry-run JSON manifest for a selected local `.gba`, displays base identity, source-tree-first state, replacement identity, review-token, and blocked broader-action rows, requires a typed confirmation token, and invokes `BinaryROMMutationApplier` directly. Successful apply writes only the existing ignored original-ROM backup and apply manifest under `.pokemonhackstudio/rom-mutations/`.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'BinaryROMMutationDryRunManifestTests|PokemonHackCLITests/test(HelpUsesCommandMetadataForTextAndJSON|BlockedApplyExportOutputsMapToNonzeroExecutableExitCode|ROMMutationManifestCommandEmitsDryRunJSONWithoutWritingFiles|ROMMutationApplyCommand)'` passed with 16 selected tests and 0 failures.
- `xcodegen generate` passed before app-hosted proof.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHST79D-AppReview -destination 'platform=macOS,arch=arm64' -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testBinaryROMMutationApplyReviewAppliesSelectedManifestWithToken -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testBinaryROMMutationApplyReviewBlocksWrongTokenWithoutWriting -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testBinaryROMMutationApplyReviewRefusesSourceTreeCandidateAndDrift test` passed after project regeneration.
- `git check-ignore -v .pokemonhackstudio/rom-mutations/phs-t79d/apply-manifest.json .pokemonhackstudio/rom-mutations/phs-t79d/phs-t79d-original.gba` passed; both paths matched the ignored `.pokemonhackstudio/` root.
- `git diff --check` passed.

## Boundaries

Pointer repoint apply, free-space allocation apply, checksum repair, patched-copy output, emulator launch, app auto-apply, replacement authoring controls, source mutation, ROM export, and CLI shape changes remain blocked.
