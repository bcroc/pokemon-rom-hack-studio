# PHS-T124 Patch Creation Verification

## Scope

`PHS-T124` verifies created BPS artifacts by re-reading the final patch, applying it in memory to the selected base ROM, and recording schema v2 verification facts in the creation manifest and app/CLI reports.

## Review Remediation Addendum

- BPS apply now uses checked integer conversion and checked offset arithmetic for metadata size, target size, command length, source-copy offsets, target-copy offsets, and signed offsets.
- Patch export now computes patched bytes and manifest data before replacing an existing output, then commits through temporary files with rollback on late output/manifest write failures.
- App patch export now uses the core default `overwrite: false`, so repeat export blocks with `PATCH_EXPORT_OUTPUT_EXISTS` instead of silently replacing an existing patched ROM.

## Proof

- `BuildPatchPlaytestValidationTests/testPatchApplyExportDoesNotReplaceExistingOutputWhenPatchBodyFails` passed in SwiftPM and targeted Xcode proof.
- `BuildPatchPlaytestValidationTests/testPatchApplyExportRestoresExistingOutputWhenManifestCommitFails` passed in SwiftPM and targeted Xcode proof.
- `BuildPatchPlaytestValidationTests/testPatchApplyExportRestoresExistingOutputWhenOutputMoveFailsAfterRemoval` passed in SwiftPM and targeted Xcode proof for the remove-old-output, fail-temp-move rollback interleaving.
- `MapEditorStoreTests/testPatchApplyExportStoreWritesPatchedROMAndManifest` passed in targeted Xcode proof and now asserts repeat app export is blocked without backup creation.
- `make validate` passed after the remediation.

## Boundary

Verification remains in-memory except for the explicit ignored creation manifest. Existing export output is no longer overwritten by the app until a future explicit overwrite-review UI exists.
