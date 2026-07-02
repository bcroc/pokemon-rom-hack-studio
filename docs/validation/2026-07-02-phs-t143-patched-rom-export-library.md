# PHS-T143 Read-Only Patched ROM Export Library

Date: 2026-07-02

## Scope

`PHS-T143` records the accepted Patched ROM Export Library plan under the next free row because the live dirty board already contained `PHS-T140` for Resources Detail Packet Copy Affordance, `PHS-T141` for ROM Mutation Library CLI, and `PHS-T142` for Reference Status Visibility.

`PatchExportArtifactLibraryScanner` scans only regular direct-child `.gba` exports under `.pokemonhackstudio/patches`, reads only the sibling `.gba.manifest.json` as `PatchApplyExportManifest`, compares manifest-backed base/output SHA1 and CRC32 plus patch CRC32, computes patch SHA1 for review identity only, and refuses to hash manifest-declared base, patch, or backup paths that leave the selected project root after standardization and symlink resolution.

CLI `patch-export-library <project> --json` is a thin read-only adapter and returns successful JSON for empty, warning, and error scan reports.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'BuildPatchPlaytestValidationTests|PokemonHackCLITests/testPatchExportLibrary'`
  - Passed with 67 selected tests and 0 failures.
  - Covers valid export artifact scans, missing/unreadable/mismatched manifests, output checksum drift, base/patch path containment, backup posture, direct-child-only filtering, missing-root no-create behavior, CLI help metadata, and CLI JSON without file-tree mutation.
- `git diff --check`
  - Passed.

## Boundaries

This row adds a Core read-only scanner, CLI JSON adapter, focused Core/CLI tests, and proof docs only. The scanner reads direct-child ignored `.gba` exports and sibling `.gba.manifest.json` manifests; it reads manifest-declared base, patch, and backup paths only when contained in the selected project root after standardization and symlink resolution; and it does not call `patch-apply-export`, export ROMs, overwrite artifacts, create backups, mutate selected Pokemon source, widen patch formats, run builds/playtests, or rewrite headers.

## Unrelated Dirty Work

Concurrent unrelated dirty NDS semantic coverage, Resources/app command routing, reference status visibility, ROM mutation library, validation-promotion, validation-doc, and planning-doc work was preserved outside this row.
