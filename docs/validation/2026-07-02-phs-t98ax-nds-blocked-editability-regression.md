# PHS-T98AX NDS Blocked Editability Regression

## Scope

`PHS-T98AX` is a diagnostics-only regression row. It proves unsupported NDS rows still lower to blocked, non-applyable edit plans or blocked semantic snapshots across Gen V source inventory, standalone `.nds` ROM rows, NARC/container rows, generated/reference rows, and PMD-Sky spin-off rows.

No writer family, semantic eligibility, raw-source eligibility, extraction, decompression, NARC/container rebuild, generated/reference write, ROM rebuild/export, mutation apply, or binary write path was added.

## Proof

- `swift test --package-path PokemonHackStudio --filter 'NDSDataCatalogTests/testNDSBlockedEditabilityRegressionKeepsUnsupportedRowsNonApplyable'` passed: 1 selected test, 0 failures.
- `swift test --package-path PokemonHackStudio --filter 'PokemonHackCLITests/testNDSDataEditCommandsKeepUnsupportedRowsBlocked'` passed: 1 selected test, 0 failures.
- `make validate-nds` passed: 129 selected tests, 0 failures.
- `git diff --check` passed.

Optional central reference smokes skipped exactly as reported by `script/validate_nds.sh`:

- `pret__pokeplatinum`; central reference root not found at `/Users/bryan/projects/reference-repos/repos/pret__pokeplatinum`
- `pret__pokediamond`; central reference root not found at `/Users/bryan/projects/reference-repos/repos/pret__pokediamond`
- `pret__pokeheartgold`; central reference root not found at `/Users/bryan/projects/reference-repos/repos/pret__pokeheartgold`
- `pret__pmd-sky`; central reference root not found at `/Users/bryan/projects/reference-repos/repos/pret__pmd-sky`

## Coverage

The core regression asserts empty/non-applyable `NDSDataEditPlan` output for Gen V `data/encounters/route_1.txt`, ROM-backed `resources:sub/child.narc`, source-tree NARC `personal:res/prebuilt/poketool/personal/personal.narc`, generated `resources:generated/species.txt`, temp `references/pokeplatinum`, and PMD-Sky `resources:files/MESSAGE/text_us.str`.

The CLI regression promotes a blocked `nds-data-edit-plan` smoke into `make validate-nds` and checks JSON diagnostics for `NDS_GEN_V_WRITE_BLOCKED`, `NDS_DATA_EDIT_BINARY_ROM_BLOCKED`, `NDS_DATA_EDIT_CONTAINER_BLOCKED`, `NDS_DATA_EDIT_ROLE_BLOCKED`, `NDS_DATA_EDIT_REFERENCE_BLOCKED`, and `NDS_DATA_EDIT_SPINOFF_BLOCKED`; Gen V and PMD-Sky semantic plan JSON also remains blocked by profile diagnostics.
