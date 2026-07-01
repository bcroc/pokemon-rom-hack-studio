# PHS-T79C Binary Replace Apply CLI

## Summary

`PHS-T79C` opens the first real binary ROM mutation writer as a CLI-only, reviewed, in-place byte replacement path for user-supplied local `.gba` `binaryROM` inputs with no available source-tree edit path.

The dry-run manifest now carries replacement apply-review metadata: original-span SHA1, full replacement identity, blocked broader actions, and a deterministic review token tied to the base SHA1/CRC32/file-size/header identity plus the exact replacement set. `rom-mutation-apply` requires the dry-run JSON, `--workspace-root`, and that exact token before writing.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'BinaryROMMutationDryRunManifestTests|PokemonHackCLITests/test(HelpUsesCommandMetadataForTextAndJSON|BlockedApplyExportOutputsMapToNonzeroExecutableExitCode|ROMMutationManifestCommandEmitsDryRunJSONWithoutWritingFiles|ROMMutationApplyCommand)'` passed on rerun with 16 selected tests and 0 failures.
- `git check-ignore -v .pokemonhackstudio/rom-mutations/phs-t79c/apply-manifest.json .pokemonhackstudio/rom-mutations/phs-t79c/base-original.gba .pokemonhackstudio/rom-mutations/phs-t79c/patched-copy.gba` passed; all representative paths matched the ignored `.pokemonhackstudio/` root.
- `git diff --check` passed.
- `make validate-synthetic` reached the full SwiftPM test suite but is currently blocked by unrelated live-tree move-catalog drift: `PokemonMoveCatalogTests/testRubySapphireContestMoveFactsJoinToBattleMoveRowsWhenPresent` fails at `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonMoveCatalogTests.swift:381`. The PHS-T79C core/CLI tests pass before that unrelated failure.

## Covered Scenarios

- Successful reviewed replace apply mutates the selected `.gba` in place, copies the original ROM, writes an apply manifest under ignored `.pokemonhackstudio/rom-mutations/<rom-stem>/<timestamp-token>/`, and does not create a patched-copy output.
- Blocked paths return JSON without writing for missing/wrong confirmation, matching source-tree candidates, base SHA1/CRC32 drift, original-byte drift, header-region edits, out-of-bounds ranges, overlapping replacements, repoint/allocation operations, and symlink-escaped artifact roots.
- CLI help, JSON command metadata, and blocked-result exit-code mapping include `rom-mutation-apply`.

## Still Blocked

Pointer repoint apply, free-space allocation apply, checksum repair, emulator launch, app apply UI, source mutation, ROM export, patched-copy output, arbitrary binary edits, and header/checksum-region writes remain blocked.
