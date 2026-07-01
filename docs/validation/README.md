# PokemonHackStudio Validation

This directory records validation tiers and closeout proof outside the main planning board.

## Focused Closeout Proof

| Row | Proof | Outcome |
| --- | --- | --- |
| `PHS-T118` | [Guided UI/UX Evidence Closeout](2026-07-01-guided-ui-ux-evidence-closeout.md) | Local screenshot/audit evidence was recorded without adding PNG binaries to Git; archived guided/adoption paths were confirmed as already adopted or local-only evidence. |
| `PHS-T57U` | [Ruby/Sapphire Contest Move Scalar Editing](2026-07-01-phs-t57u-ruby-contest-move-scalars.md) | Focused SwiftPM, app-hosted Moves, `make test`, and `git diff --check` proof passed for existing `gContestMoves` simple scalar editing and blocked combo-array/unsafe adjacent writes. |
| `PHS-T57T` | [Ruby/Sapphire Contest Move Facts](2026-07-01-phs-t57t-ruby-contest-move-facts.md) | Focused move catalog, compatibility, and CLI compatibility JSON proof passed on 2026-07-01; `git diff --check` passed. |
| `PHS-T79C` | [Binary Replace Apply CLI](2026-07-01-phs-t79c-binary-replace-apply-cli.md) | Focused core/CLI proof passed for dry-run review tokens, reviewed in-place byte replacement apply, ignored backup/manifest artifacts, and blocked unsafe/non-replacement/source-tree/drift/confirmation paths. |
| `PHS-T78U` | [Expansion Move Contest Combo Moves](2026-07-01-phs-t78u-expansion-move-contest-combo-moves.md) | Focused move/compatibility/CLI, app-hosted Moves store, `make test`, `make validate`, and `make verify` proof passed for existing simple `MOVE_*` combo-array editing with constants validation and adjacent writes blocked. |
| `PHS-T78T` | [Modern Emerald Reference Compatibility Facts](2026-07-01-phs-t78t-modern-emerald-reference-compatibility.md) | Metadata-only Modern Emerald compatibility rows were added; focused SwiftPM and `make test` proof are blocked by unrelated live-tree compile drift before PHS-T78T assertions run. |
| `PHS-T78R` | [Expansion Move Contest Scalar Editing](2026-07-01-phs-t78r-expansion-move-contest-scalars.md) | Focused core/compatibility and CLI JSON proof passed; broader compatibility and `make validate` runs are blocked by unrelated all-learnables assertions after the PHS-T78R tests pass. |
| `PHS-T112V` | [Gen V Source Data Domain Inventory Facts](2026-07-01-phs-t112v-genv-source-data-domain-inventory-facts.md) | Focused catalog/CLI JSON, app Resources selection, `make validate-nds`, and `git diff --check` passed for preview-only Gen V Pokemon/move/item/trainer source-data domain facts after row-ID collision with existing `PHS-T112U`. |
| `PHS-T112U` | [Gen V Related-Row Readiness](2026-07-01-phs-t112u-genv-related-row-readiness.md) | Focused catalog/CLI proof and `make validate-nds` passed for preview-only Gen V encounter/fielddata/message related-row readiness facts. |
| `PHS-T112T` | [Gen V Message Metadata Facts](2026-07-01-phs-t112t-genv-message-metadata-facts.md) | Focused catalog/CLI proof and `make validate-nds` passed for preview-only Gen V `files/msgdata/**` byte, line-count, numeric-bank-hint, and `noDecodedPreview` facts. |
| `PHS-T98AH` | [DP Encounter C-Anchor Loader-Only Readiness](2026-07-01-phs-t98ah-dp-encounter-c-anchor-loader-only.md) | Focused clean proof and `make validate-nds` passed for Diamond/Pearl `encounters:arm9/src/encounter.c` loader-only blocked readiness facts, CLI/resource-index propagation, and unchanged semantic refusal. |
| `PHS-T98AG` | [Platinum Text Line Row Operations](2026-07-01-phs-t98ag-platinum-text-line-operations.md) | Focused scratch-path core/CLI proof passed for Platinum `.txt` insert/delete/reorder planning/apply, redacted JSON, backups, and blocked unsafe rows; live `make validate-nds` is blocked by unrelated `BuildPatchPlaytestValidationTests.swift` modification during the build. |
| `PHS-T98AF` | [DP Move C-Anchor Simple Scalars](2026-07-01-phs-t98af-dp-move-c-anchor-scalars.md) | Focused core/CLI proof and `make validate-nds` passed for exact `sWazaTbl` simple scalar plan/apply, catalog/resource-index facts, and blocked encounter C-anchor apply attempts. |
| `PHS-T98AE` | [DP Move/Encounter C-Anchor Readiness Facts](2026-07-01-phs-t98ae-dp-move-encounter-c-anchor-readiness.md) | Focused clean proof passed for catalog, CLI JSON, resource-index/Resources propagation, and blocked semantic snapshots; the prior Gen V NitroFS/message-bank expectation drift is resolved, and `make validate-nds` now passes with 103 selected tests and 0 failures. |
| `PHS-T98AD` | [HGSS Map Relationship Readiness](2026-06-30-phs-t98ad-hgss-map-relationship-readiness.md) | Focused MapCatalog/MapWorkflow proof, HGSS NDS/CLI proof, and `make validate-nds` passed on 2026-06-30; optional central reference-root smokes skipped because the local pret clones are absent. |
| `PHS-T98AC` | [HGSS Map Header Integer Scalars](2026-06-29-phs-t98ac-hgss-map-header-integer-scalars.md) | Focused core/CLI proof, app Resources proof, `make validate-nds`, and `git diff --check` passed on 2026-06-29 America/Vancouver. |
| `PHS-T98AB` | [Diamond/Pearl Map Header C Scalars](2026-06-29-phs-t98ab-diamond-pearl-map-header-c-scalars.md) | Focused NDS catalog, CLI semantic plan/apply, and `make validate-nds` proof passed on 2026-06-29 19:35 America/Vancouver; central NDS reference smokes skipped absent local pret clones. |
| `PHS-T78S` | [Expansion All Learnables Coverage Facts](2026-06-30-phs-t78s-expansion-all-learnables-coverage.md) | Focused compatibility, asset catalog, CLI JSON, and `git diff --check` proof passed on 2026-06-30; generated all-learnables and source/write paths remain read-only. |
| `PHS-T78N` | [Expansion All Learnables Readiness Facts](2026-06-30-phs-t78n-expansion-all-learnables-readiness.md) | Focused compatibility/asset/CLI proof passed on 2026-06-29 19:27 America/Vancouver; broader Species and synthetic suites are blocked by unrelated live-tree NDS/Species failures. |
| `PHS-T78Q` | [Expansion ItemInfo Effect/Icon Editing](2026-06-30-phs-t78q-expansion-iteminfo-effect-icon-editing.md) | Focused item and CLI proof passed on 2026-06-30; full compatibility filter is blocked by unrelated all-learnables failures after the item compatibility assertion passes. |
| `PHS-T78P` | [Expansion ItemInfo Effect/Icon Metadata Facts](2026-06-30-phs-t78p-expansion-iteminfo-effect-icon-metadata.md) | Focused SwiftPM passed with 24 selected tests; `make validate-synthetic` builds but remains blocked by unrelated Gen V NitroFS root shallow-count drift after 433 tests. |
| `PHS-T57P` | [Ruby/Sapphire Move Description Text Editing](2026-06-29-phs-t57p-ruby-move-descriptions.md) | Focused SwiftPM rerun passed on 2026-06-29 19:11:06 America/Vancouver; 2 selected tests, 0 failures. |

## Tiers

| Tier | Command | Purpose | Skips And Blockers |
| --- | --- | --- | --- |
| Synthetic | `make validate-synthetic` | Shell checks plus SwiftPM tests over checked-in synthetic fixtures. | None expected. |
| Local GBA Fixtures | `make validate-gba-fixtures` | Full GBA fixture ladder with local Emerald, FireRed, and Ruby source roots required. | Fails when required local fixture roots are unavailable. |
| NDS Synthetic And Optional References | `make validate-nds` | NDS catalog, semantic, and CLI proof over synthetic fixtures plus optional central clean-room reference smokes. | Skips missing central reference roots and reports each skipped root. |
| Central NDS References | `make validate-nds-strict` | NDS catalog, semantic, and CLI proof with required central clean-room references. | Fails when central reference roots are unavailable. |
| App GUI Smoke | `make validate-gui-smoke` | App-hosted smoke via `script/build_and_run.sh test`. | Requires local Xcode/macOS app test environment. |
| Release Candidate | `make validate-release-candidate` | Combined scripts, core, NDS, app-hosted, and app verify ladder before packaging. | Local fixture/reference availability remains tier-specific. |

## Policy

- Synthetic proof is the minimum for source-only or narrow Swift package changes.
- GUI workflow changes should add app/store tests and run at least `make test`; app-hosted smoke is preferred when the changed surface depends on the macOS shell.
- Local fixture and reference tiers must report explicit missing-root reasons instead of silently widening scope.
- Release-candidate proof must also audit that ROMs, saves, generated outputs, references, caches, and local artifacts remain excluded from packaged output.
