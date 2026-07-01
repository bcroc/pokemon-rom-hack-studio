# PHS-T79E Binary Apply Audit Review

`PHS-T79E` adds a read-only Build/Patch/Playtest audit surface for the existing `PHS-T79C`/`PHS-T79D` replace-only binary ROM apply path.

The audit loads an existing dry-run JSON manifest for a selected local `.gba`, recomputes current source-tree-first, base identity, original-byte, review-token, replacement-shape, and artifact containment checks, and surfaces ignored original-ROM backup plus apply-manifest status before apply. It writes no files and disables app apply when the audit is blocked; the existing apply path still performs its own full recheck before writing.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'BinaryROMMutationDryRunManifestTests|PokemonHackCLITests/test(HelpUsesCommandMetadataForTextAndJSON|BlockedApplyExportOutputsMapToNonzeroExecutableExitCode|ROMMutationManifestCommandEmitsDryRunJSONWithoutWritingFiles|ROMMutationApplyCommand)'` passed with 20 selected tests and 0 failures.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHST79E-AppAudit -destination 'platform=macOS,arch=arm64' -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testBinaryROMMutationApplyReviewAppliesSelectedManifestWithToken -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testBinaryROMMutationApplyReviewBlocksWrongTokenWithoutWriting -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testBinaryROMMutationApplyReviewRefusesSourceTreeCandidateAndDrift -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testBinaryROMMutationApplyAuditRowsDisableApplyWhenCurrentStateDrifts test` passed with existing `allowedFileTypes` warnings and local passcode-protected-device notification-proxy warnings.
- `git check-ignore -v .pokemonhackstudio/rom-mutations/phs-t79e/apply-manifest.json .pokemonhackstudio/rom-mutations/phs-t79e/phs-t79e-original.gba .pokemonhackstudio/rom-mutations/phs-t79e/phs-t79e-patched.gba` passed; all paths matched the ignored `.pokemonhackstudio/` root.
- `git diff --check` passed.

## Boundaries

The audit is read-only and does not add repoint apply, free-space allocation apply, checksum repair, patched-copy output, emulator launch, app auto-apply, replacement authoring controls, source mutation, ROM export, or CLI shape changes.
