# PHS-T57Q Ruby/Sapphire Item Description Text Editing

Date: 2026-06-29

Scope: Ruby/Sapphire local source-backed item description declarations only.

## Changed Paths

- `PokemonHackStudio/Sources/PokemonHackCore/PokemonItemCatalog.swift`
- `PokemonHackStudio/Sources/PokemonHackCore/PokemonDataCompatibility.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonItemCatalogTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCoreTests/PokemonDataCompatibilityTests.swift`
- `PokemonHackStudio/Tests/PokemonHackCLITests/PokemonHackCLITests.swift`
- `docs/planning-and-progress.md`
- `docs/validation/2026-06-29-phs-t57q-ruby-sapphire-item-descriptions.md`

## Proof

- Confirmed Ruby/Sapphire item rows in `src/data/items_en.h` reference description symbols such as `gItemDescription_Potion`.
- Confirmed the Ruby/Sapphire item description declaration file is `src/data/item_descriptions_en.h`, with simple declarations such as `static const u8 gItemDescription_*[] = _(...)`.
- `swift test --package-path PokemonHackStudio --scratch-path /tmp/PokemonHackStudio-PHS-T57P-item-tests --filter PokemonItemCatalogTests` passed with 12 selected tests and 0 failures.
- `swift test --package-path PokemonHackStudio --scratch-path /tmp/PokemonHackStudio-PHS-T57Q-compat-final --filter PokemonDataCompatibilityTests` passed with 10 selected tests and 0 failures.
- `swift test --package-path PokemonHackStudio --scratch-path /tmp/PokemonHackStudio-PHS-T57P-compat-test --filter 'PokemonDataCompatibilityTests/testRubyAndExpansionItemsReportEditableSourceBackedRows'` passed with 1 selected test and 0 failures.
- `swift test --package-path PokemonHackStudio --scratch-path /tmp/PokemonHackStudio-PHS-T57P-cli-test --filter 'PokemonHackCLITests/testItemCatalogCommandEmitsRubySapphireDescriptionJSON'` passed with 1 selected test and 0 failures.
- Direct CLI smoke `swift run --package-path PokemonHackStudio --scratch-path /tmp/PokemonHackStudio-PHS-T57P-cli-run pokemonhack-cli item-catalog "$tmp" --json` against a synthetic Ruby/Sapphire source root reported `pokeruby | 1 | ITEM_POTION | true | true | gItemDescription_Potion | Restores HP.`
- `make validate-synthetic` passed with shell syntax checks, build-tool check, and 413 SwiftPM tests with 0 failures.
- `git diff --check` passed.

## Blockers And Notes

- The requested sub-row was likely `PHS-T57P`, but the live board already assigned `PHS-T57P` to Ruby/Sapphire move descriptions, so this closeout is recorded as `PHS-T57Q`.
- An earlier full `PokemonDataCompatibilityTests` attempt was blocked by unrelated concurrent Expansion species compatibility expectations in `testExpansionSpeciesRowsReportEditableWithBlockedAdjacentSourcesAndJSON`, where other live-checkout changes made the fixture report four indexed/editable Expansion species rows instead of one; the final rerun above passed from the settled tree.

## Source-Write Posture

Ruby/Sapphire item description writes are limited to existing local `src/data/item_descriptions_en.h` `gItemDescription_*` declarations referenced by existing `src/data/items_en.h` `gItems` rows, through explicit Items preview/apply with source hash/size checks and backups. Item identity/constants, row insertion, TM/HM compatibility, references, ROM writes, generated outputs, unsupported/non-simple declarations, and broad row rewrites remain blocked/read-only.
