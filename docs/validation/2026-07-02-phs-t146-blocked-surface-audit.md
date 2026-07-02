# PHS-T146 Blocked Surface Audit

Date: 2026-07-02

## Scope

`PHS-T146` audits user-facing blocked/readiness labels across Core and app report surfaces after `PHS-T145`.

The row narrows stale broad wording where a supported explicit action already exists elsewhere behind its own gate:

- Patch creation preview now says patch/manifest writes are blocked from preview, not globally blocked.
- Patch distribution readiness now says creation/apply/export/writes are blocked from the readiness packet.
- Patch apply/export audit now says writes are blocked from the audit report.
- ROM Mutation Library now says binary apply/dry-run/replacement actions are blocked from the library scan.
- Build/Patch/Playtest NDS semantic coverage and activity rows use write-blocked report wording.
- Gen IV map-review packet facts say blocked actions rather than a generic blocked count.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'BuildPatchPlaytestValidationTests/test(PatchCreationPreviewComparesBaseROMAndBuiltOutputWithoutWritingPatch|ROMMutationArtifactLibraryScansApplyManifestBackupReadOnly|PatchDistributionReadinessComposesSelectedPatchLibraryAndManualPlaytestReadinessWithoutWriting|PatchApplyExportAuditReportsReadyForCompatibleBPSAndIPSWithoutWritingArtifacts)|NDSDataCatalogTests/test(HeartGoldCatalogIncludesNARCPlaceholderAndSourceAnchors|DiamondCatalogKeepsCSourceAnchorsConservative|PokeBlackCatalogSurfacesGenVSourceDataDomainInventoryFacts|PokeBlackCatalogSurfacesGenVBlockedActionAuditPacket)|PokemonDataCompatibilityTests/testRubyAndExpansionItemsReportEditableSourceBackedRows'`
  - Passed with 9 selected tests and 0 failures.
- `swift test --package-path PokemonHackStudio --filter 'PokemonHackCLITests/test(PatchCreatePreviewCommandEmitsReadonlyJSON|PatchDistributionReadinessCommandMatchesExplicitRelativePatchPath|PatchApplyExportAuditCommandEmitsReadOnlyJSONWithoutWritingArtifacts)'`
  - Passed with 3 selected tests and 0 failures.
- `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1 xcodebuild -quiet -project PokemonHackStudio/PokemonHackStudio.xcodeproj -scheme PokemonHackStudio -configuration Debug -derivedDataPath /tmp/PokemonHackStudio-PHS-T146-BlockedSurfaceAudit -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testNDSSemanticCoverageLoadsIntoBuildWorkbenchAndCopiesJSONReadOnly -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testPatchCreationPreviewLoadsReadonlyMetadataWithoutWritingPatchArtifacts -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testPatchDistributionReadinessRowsCopyJSONAndRequireExplicitPatchSelection -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testROMMutationArtifactLibraryRowsCopyRedactedJSONWithoutWritingArtifacts -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testPatchApplyExportAuditRowsCopyJSONWithoutWritingArtifacts -only-testing:PokemonHackStudioTests/MapEditorStoreTests/testShipPreviewDigestSummarizesLoadedNDSSemanticCoverageWithoutWriting test`
  - Passed.
- `make validate`
  - Passed with 582 SwiftPM tests plus CLI smokes and local `pokeemerald`/`pokefirered`; skipped absent `references/pokeruby`.
- `make validate-nds`
  - Passed with 137 selected tests and 0 failures; skipped absent optional central reference roots for `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky`.
- `make verify`
  - Passed after `xcodegen`; existing AppIntents metadata, ad-hoc signing, bundle-script, and macOS `allowedFileTypes` warnings only.
- `make scripts-check`
  - Passed.
- `git diff --check`
  - Passed.

## Boundaries

This row changes wording/readiness values and focused regression coverage only. It does not add public CLI commands, Core write APIs, app commands, persisted workspace schema, writers, export authority, emulator launch, source mutations, ROM mutations, reference edits, NARC/container rebuilds, checksum repair, pointer repoint apply, free-space allocation apply, or app auto-apply.

Generated/reference writes, unsupported binary edits, source writes without mutation plans, broad ROM export, and manual-only/copy-only report posture remain blocked.

## Unrelated Dirty Work

The checkout was already dirty with in-flight NDS, reference-status, patch/export, ROM-mutation, app-panel, validation-script, and planning/doc work. This row preserved that baseline and changed only the blocked-surface wording/tests/docs listed in the planning ledger.
