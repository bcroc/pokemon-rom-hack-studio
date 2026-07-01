# PHS-T112U Gen V Related-Row Readiness

## Summary

- Row ID: `PHS-T112U`. The live board already recorded `PHS-T112T`, so this is the next unique `PHS-T112` follow-up.
- Links `.pokeblack` Gen V `data/encounters/*`, `files/fielddata`, `files/fielddata/mapmatrix`, `files/fielddata/maptable`, `files/fielddata/script`, `files/fielddata/eventdata/zone_event`, `files/msgdata`, and every `files/msgdata/**` candidate through existing catalog `relatedRecords`, `Related Rows`, `Related Domains`, and readiness facts.
- Uses one explicit Gen V context relationship key so encounter/message membership does not come from filename token stems such as `0001`.
- Preserves read-only child posture: message rows keep `messageBankMetadata`, `noDecodedPreview`, byte/line/bank-hint facts; fielddata children keep preview-only roles; mutation planning remains non-applyable with `NDS_GEN_V_WRITE_BLOCKED`.

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/NDSDataCatalog.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/NDSDataCatalogTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `docs/nds-extension-plan.md`
- `docs/planning-and-progress.md`
- `docs/validation/README.md`
- `docs/validation/2026-07-01-phs-t112u-genv-related-row-readiness.md`

## Validation

- `swiftc -parse PokemonHackStudio/Sources/PokemonHackCore/NDSDataCatalog.swift`, `swiftc -parse PokemonHackStudio/Tests/PokemonHackCoreTests/NDSDataCatalogTests.swift`, and `swiftc -parse PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift` passed.
- `swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests/testPokeBlackCatalogLinksGenVEncounterFielddataAndMessageCandidates|PokemonHackCLITests/testNDSDataCatalogCommandLinksPokeBlackEncounterFielddataAndMessageCandidatesJSON'` passed after waiting on the existing SwiftPM build lock: 2 selected tests, 0 failures.
- `make validate-nds` passed after waiting on the existing SwiftPM build lock: 109 selected tests, 0 failures. Central clean-room reference smokes were skipped because `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky` were not present under `/Users/bryan/projects/reference-repos/repos`.
- `git diff --check` passed after docs/proof reconciliation.

## Source-Write Posture

- Preview-only/manual-only related-row metadata only.
- No Gen V script parser, text decoder, decoded preview, source writer, NARC packing, container rebuild, build/playtest execution, ROM export, mutation apply, or binary write path was added.
