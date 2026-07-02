# PHS-T79G Binary Apply Review Copy Split

Date: 2026-07-02

## Scope

`PHS-T79G` opens the next binary mutation row after the live board's `PHS-T79F`.

Build/Patch/Playtest now splits the loaded binary apply audit into separate copyable audit status, review-token state, current-state drift, ignored backup destination, ignored apply-manifest destination, and irreversible replace-only apply status rows before the typed-token apply gate. The row also adds Copy Audit JSON for the loaded read-only audit while keeping the existing `BinaryROMMutationApplier.apply` replace-only writer as the only app write path.

## Proof

- `swift test --package-path PokemonHackStudio --filter BinaryROMMutationDryRunManifestTests`
  - Passed with 15 selected tests and 0 failures.
- `swift test --package-path PokemonHackStudio --filter PokemonHackCLITests`
  - Passed with 110 selected tests and 0 failures.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T79G-AppReview -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testBinaryROMMutationApplyReviewAppliesSelectedManifestWithToken -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testBinaryROMMutationApplyReviewBlocksWrongTokenWithoutWriting -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testBinaryROMMutationApplyReviewRefusesSourceTreeCandidateAndDrift -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testBinaryROMMutationApplyAuditRowsDisableApplyWhenCurrentStateDrifts -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testBinaryROMMutationApplyAuditRowsSeparateCopyableStateBeforeApplyGate test`
  - Passed with focused app apply-review/audit row ordering, copy payload, drift disablement, token blocking, successful apply artifact status, and no patched-copy output proof.
- `git diff --check`
  - Passed.

## Boundaries

This row adds app-only copy row/action state, Copy Audit JSON, focused tests, and proof docs only. It does not change `PokemonHackCore` audit/apply schemas, CLI commands or JSON, replacement authoring controls, app auto-apply, repoint apply, free-space allocation apply, checksum repair, patched-copy output, emulator launch, source mutation, ROM export, or writes beyond the existing explicitly confirmed replace-only path.

## Unrelated Dirty Work

Concurrent unrelated dirty NDS, patch audit/distribution, IDE, CLI, validation-script, docs-validation, and other app/test work was preserved outside this row.
