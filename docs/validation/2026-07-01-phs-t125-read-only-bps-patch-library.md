# PHS-T125 Read-Only BPS Patch Library

## Scope

`PHS-T125` scans direct-child ignored `.pokemonhackstudio/patches/*.bps` files and sibling `.bps.manifest.json` creation manifests into a read-only Patch Library with patch/base/output identity status and safe app actions.

## Review Remediation Addendum

- Manifest-declared `baseROMPath` and `builtOutputPath` are now standardized and required to remain under the selected project root after symlink resolution before the scanner hashes them.
- Out-of-root or symlink-escaped manifest paths are not read. The scanner reports `.unavailable` status and warning diagnostics instead of hashing external files.
- Re-check, Copy JSON, Reveal, and created-artifact selection remain read-only review actions; they do not apply/export patches or create directories.

## Proof

- `BuildPatchPlaytestValidationTests/testPatchArtifactLibraryDoesNotHashManifestInputsOutsideProjectRoot` passed in SwiftPM and targeted Xcode proof.
- `MapEditorStoreTests/testPatchCreationRefreshesPatchLibraryAndSelectsCreatedBPSArtifact` and existing Patch Library rows remain covered by the SwiftPM/app proof ladder.
- Existing Patch Library app coverage continues to exercise explicit-create selection plus Re-check, Copy JSON, and Reveal as review actions without patch apply/export authority.
- `make validate-nds` passed with optional central-reference skips for missing local pret clones: `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky`.
- `make validate` passed; optional `references/pokeruby` smoke skipped because the local fixture is absent.

## Boundary

Patch Library remains a read-only scanner. It does not read manifest-declared files outside the selected project, write patched ROMs, auto-apply/export patches, overwrite artifacts, run builds/playtests, mutate source, or rewrite headers.
