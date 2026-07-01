# PHS-T112T Gen V Message Metadata Facts

## Summary

- Row ID: `PHS-T112T`. The accepted implementation plan named `PHS-T112R`, but the live dirty board already used `PHS-T112R` for Gen V overlay/disassembly aggregate facts and `PHS-T112S` for Gen V fielddata related rows.
- Extends Gen V `files/msgdata/**` child rows with bounded metadata-only facts: byte count, UTF-8 text-like non-empty line count for `.txt`, `.gmm`, and `.str`, numeric bank hints for `.bin`, `.dat`, and `.msg`, and `Gen V Message Decoded Preview = noDecodedPreview`.
- Preserves the existing `files/msgdata` `messageBankInventory` root and child `messageBankMetadata` roles, candidate count/extensions/kind/basis/posture facts, and the absence of text-bank previews and migration facts.

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/NDSDataCatalog.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/NDSDataCatalogTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `docs/nds-extension-plan.md`
- `docs/planning-and-progress.md`
- `docs/validation/README.md`
- `docs/validation/2026-07-01-phs-t112t-genv-message-metadata-facts.md`

## Validation

- `swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests/testPokeBlackCatalogSurfacesGenVMessageBankInventoryFacts|PokemonHackCLITests/testNDSDataCatalogCommandEmitsPokeBlackMessageBankInventoryJSON'` passed after waiting on the existing SwiftPM build lock: 2 selected tests, 0 failures.
- `make validate-nds` passed: 103 selected tests, 0 failures. Central clean-room reference smokes were skipped because `pret__pokeplatinum`, `pret__pokediamond`, `pret__pokeheartgold`, and `pret__pmd-sky` were not present under `/Users/bryan/projects/reference-repos/repos`.
- `git diff --check` passed after docs/proof reconciliation.

## Source-Write Posture

- Preview-only/manual-only message metadata row.
- No Gen V text parser, decoded preview, semantic control, migration candidate, NARC packing, raw-source write, build/playtest execution, ROM export, mutation apply, or binary write path was added.
