# PHS-T79F ROM Mutation Audit CLI

`PHS-T79F` adds `rom-mutation-audit <rom> --manifest <dry-run-json> --workspace-root <path> --json` as a read-only CLI wrapper around the existing `BinaryROMMutationApplier.audit` report model.

The command reads the selected ROM and dry-run manifest, recomputes source-tree-first, base identity, original-byte, review-token, replacement-shape, and artifact-containment diagnostics, and emits the existing `BinaryROMMutationApplyAuditReport` JSON. Missing `--manifest` or `--workspace-root` inputs return blocked audit JSON. `--confirm` is not accepted by the audit command.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'BinaryROMMutationDryRunManifestTests'` passed with 15 selected tests and 0 failures.
- `swift test --package-path PokemonHackStudio --filter 'PokemonHackCLITests/test(HelpUsesCommandMetadataForTextAndJSON|BlockedApplyExportOutputsMapToNonzeroExecutableExitCode|ROMMutationManifestCommandEmitsDryRunJSONWithoutWritingFiles|ROMMutationAuditCommand)'` passed with 6 selected tests and 0 failures.
- A temp-file CLI smoke generated a dry-run manifest for a synthetic local `.gba`, then ran `rom-mutation-audit <rom> --manifest <dry-run-json> --workspace-root <tmp> --json`; the audit reported `status=ready`, two pending artifact reviews, and no `.pokemonhackstudio` directory creation.

## Boundaries

This row does not call `BinaryROMMutationApplier.apply`, require or accept confirmation tokens, apply bytes, write backups, write apply manifests, create artifacts, create patched-copy outputs, mutate source, export ROMs, repair checksums, launch emulators, author replacements, apply repoints, allocate free space, or change app auto-apply behavior.
