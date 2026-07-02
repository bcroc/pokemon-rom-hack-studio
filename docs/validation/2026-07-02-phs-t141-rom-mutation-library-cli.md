# PHS-T141 ROM Mutation Library CLI

Date: 2026-07-02

## Scope

`PHS-T141` records the accepted ROM Mutation Library CLI plan under the next free row because the live board already used `PHS-T140` for Resources Detail Packet Copy Affordance.

Core now owns `ROMMutationArtifactLibraryScanner`, which recursively scans only regular `apply-manifest.json` files under `.pokemonhackstudio/rom-mutations`, pairs each readable apply manifest with its recorded backup only when the backup remains in the selected workspace artifact root, reports missing/mismatched/out-of-root backups as diagnostics, and keeps raw review tokens out of the encoded library.

CLI `rom-mutation-library <workspace-root> --json` is a thin adapter and returns successful JSON for empty or warning/error scan reports.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'BinaryROMMutationDryRunManifestTests|BuildPatchPlaytestValidationTests/testROMMutationArtifactLibrary|PokemonHackCLITests/test(HelpUsesCommandMetadataForTextAndJSON|ROMMutationLibraryCommand)'`
  - Passed with 23 selected tests and 0 failures.

## Boundaries

No apply, dry-run creation, replacement authoring, repoint/allocation/checksum repair, patched-copy output, emulator launch, source mutation, ROM export, backup/manifest creation, directory creation, artifact overwrite, app row, or app UI was added.

## Unrelated Dirty Work

The planning ledger records this row alongside concurrent Resources/detail, reference-status, NDS semantic coverage, validation-promotion, patch/library, CLI, and proof-doc work. Those changes are separate from this read-only CLI library closeout.
