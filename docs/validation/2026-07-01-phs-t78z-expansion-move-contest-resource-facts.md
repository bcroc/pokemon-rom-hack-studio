# PHS-T78Z Expansion Move Contest Resource Facts

## Scope

`PHS-T78Z` is a preview-only SourceIndex/Resources facts row for existing local Expansion `src/data/moves_info.h` `gMovesInfo` contest metadata.

- SourceIndex move fact selection is descriptor-aware for `src/data/moves_info.h` / `gMovesInfo`.
- Existing parsed `contestAppeal`, `contestJam`, `contestComboStarterId`, and `contestComboMoves` fields now surface as SourceIndex facts and reach CLI/app Resources through `asset-index`.
- Rows with contest metadata also expose a compact `Expansion Contest Resource Facts` fact recording preview-only posture and blocked adjacent actions.
- No move draft, mutation planner, compatibility writer, app mutation gate, item/species catalog, source writer, constants, generated output, reference, ROM/build/export, row creation/removal/reorder, or binary write behavior changed.

## Proof

- `swift test --package-path PokemonHackStudio --scratch-path /tmp/phs-t78z-resource-facts --jobs 1 --filter 'SourceIndexTests|PokemonHackCLITests/testMoveCatalogCommandEmitsExpansionContestScalarJSON|PokemonHackCLITests/testAssetIndexCommandEmitsExpansionMoveContestResourceFacts'` passed with 14 selected tests and 0 failures.
- The SourceIndex slice extends `SourceIndexTests.testExpansionMovedDataShapesIndexWithoutRequiredDescriptorWarnings` to assert Expansion `gMovesInfo` `contestAppeal`, `contestJam`, `contestComboStarterId`, `contestComboMoves`, and preview-only blocker/readiness facts.
- The CLI Resources slice adds `PokemonHackCLITests.testAssetIndexCommandEmitsExpansionMoveContestResourceFacts`, which runs `asset-index <root> --json` against the existing Expansion move fixture and asserts the contest metadata and blocker/readiness facts reach Resources.
- `git diff --check` passed.

## Live Checkout Notes

The row started with unrelated/parallel dirty work already present in NDS, compatibility, SourceIndex, compatibility tests, and validation docs. Additional unrelated/parallel dirty files appeared by final status in CLI, NDS tests, move tests, app tests, NDS docs, validation scripts, and a `PHS-T112Z` validation note. This closeout preserved those edits and layered only the PHS-T78Z fact/test/docs changes needed for this row.

## Source-Write Posture

This row is preview-only. Generated `all_learnables.json`, references, ROM/build/export paths, constants, source writers, data row creation/removal/reorder, item/species catalogs, move drafts, mutation planners, app mutation gates, compatibility writer status, and binary writes remain blocked/unchanged.
