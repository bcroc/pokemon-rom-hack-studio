# PHS-T98AZ NDS Semantic Coverage CLI Report

Date: 2026-07-02

## Scope

`PHS-T98AZ` adds `nds-data-semantic-coverage <path> --json` over `NDSDataSemanticCoverageReportBuilder`.

The report counts eligible fields, kinds, domains, and blocked/skipped reason buckets while skipping Gen V, standalone ROM, PMD-Sky, container/NARC, generated, metadata-only, and reference-root rows without semantic snapshot reads.

The live board already contained `PHS-T98AY`; no `PHS-T98AZ` or `PHS-T98BA` row was present before this read-only semantic coverage report row.

## Proof

- First focused selector attempt was blocked before tests by a transient SwiftPM modified-during-build race in `PokemonHackStudio/Tests/PokemonHackCoreTests/BuildPatchPlaytestValidationTests.swift`; rerunning the same selector passed.
- `swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests/testNDSDataSemanticCoverageReportSummarizesEligibleCountsAndBlockedBuckets|PokemonHackCLITests/testHelpUsesCommandMetadataForTextAndJSON|PokemonHackCLITests/testNDSDataSemanticCoverageCommandEmitsRedactedJSON'`
  - Passed with 3 selected tests and 0 failures.
- `make validate-nds`
  - Passed with 134 selected tests and 0 failures.
  - Optional central reference smokes skipped because `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky` were absent under `/Users/bryan/projects/reference-repos/repos`.
- `git diff --check`
  - Passed.

## Boundaries

This row is report-only. It reuses existing semantic snapshots only for normal non-reference, non-generated, non-container, non-ROM, non-Gen V rows; it emits no source values, text previews, source bytes, binary bytes, mutation plans, or snapshot payloads; and it adds no semantic eligibility, parser/domain support, writer family, apply/export path, source write, Gen V/container/generated/reference snapshot read, ROM rebuild/export, or binary write.

## Unrelated Dirty Work

Existing dirty app/IDE/patch/validation/docs work was preserved outside this row.
