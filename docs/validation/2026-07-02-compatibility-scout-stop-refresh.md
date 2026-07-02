# Compatibility Scout Stop Refresh

## Scope

This is a docs-only refresh of the 2026-07-02 compatibility scout stop line. It does not open a new implementation row, change public APIs, repair reference aliases, or widen any source-write gate.

## Scout Evidence

- Initial scout status recorded `git status --short --branch` as `## main...origin/main`. The implementation turn later saw unrelated dirty Swift/app/script/doc work and preserved it outside this note.
- `swift run --package-path PokemonHackStudio pokemonhack-cli pokemon-compatibility references/pokeruby --json`, `references/pokeemerald-expansion`, and `references/modern-emerald` each returned `CLI_ERROR` with a path-missing message.
- `swift run --package-path PokemonHackStudio pokemonhack-cli asset-index references/pokeruby --json`, `references/pokeemerald-expansion`, and `references/modern-emerald` each returned `profile: unknown`, `assetCount: 0`, and `RESOURCE_INDEX_UNSUPPORTED` plus `ASSET_CATALOG_UNSUPPORTED_INPUT` diagnostics.
- Local Ruby and Sapphire ROM compatibility returned `profile: binaryROM`, 12 entries, 11 blocked entries, and 1 read-only assets entry. Their blocked form metadata rows had `indexedCount: 0` and no editable source data, so they do not satisfy the source-backed seam requirement.
- Local Ruby and Sapphire ROM asset-index returned `profile: binaryROM`, 80 assets, a single `rom` category, and `ROM_READ_ONLY`.

## Stop Result

No named local table, source-backed asset, or missing-field gate has both indexed source data and an existing draft-to-mutation-plan seam. Reference repair, generated `all_learnables.json`, constants or identity rows, source row insertion/removal/reorder, broad adapters, ROM/export/build artifacts, binary files, and write gates remain untouched and out of scope.

## Validation

- `./script/check_validation_docs.sh` passed.
- `make scripts-check` passed.
- `git diff --check` passed.
