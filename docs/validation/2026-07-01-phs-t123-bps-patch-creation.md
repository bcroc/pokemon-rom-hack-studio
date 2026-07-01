# PHS-T123 BPS Patch Creation

## Scope

`PHS-T123` is the explicit BPS patch creation row. The row writes ignored `.pokemonhackstudio/patches/*.bps` artifacts and sibling creation manifests only after an explicit create action and readiness checks pass.

## Review Remediation Addendum

- Hardened shared BPS/UPS variable-length parsing so overlong values return `PATCH_MALFORMED` diagnostics instead of trapping.
- Guarded BPS metadata, target-size, command-length, and signed-offset conversions used by patch validation/apply paths.
- Kept patch creation source-compatible: no source mutation, build/playtest execution, patched-ROM export, overwrite policy widening, or header rewriting was added.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'BuildPatchPlaytestValidationTests|BinaryROMMutationDryRunManifestTests|PokemonHackCLITests|NDSDataCatalogTests/testNDSDataMutationPlanAppliesSourceBackedJSONRecordWithBackup'` passed after remediation; final run executed 148 selected tests with 0 failures.
- Targeted Xcode proof passed for BPS/UPS malformed diagnostics and related patch apply/export regressions under `POKEMONHACKSTUDIO_SKIP_BUNDLE_ASSETS=1`.
- `make validate` passed: 495 SwiftPM tests, CLI smokes, and local fixture checks completed with 0 failures; optional `references/pokeruby` smoke skipped because the local fixture is absent.

## Boundary

Patch creation remains explicit and ignored-artifact-only. No ROM export, auto-apply, source write, build, playtest, header rewrite, or overwrite review UI was added.
