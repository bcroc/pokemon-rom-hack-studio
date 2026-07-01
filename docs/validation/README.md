# PokemonHackStudio Validation

This directory records validation tiers and closeout proof outside the main planning board.

## Focused Closeout Proof

| Row | Proof | Outcome |
| --- | --- | --- |
| `PHS-T118` | [Guided UI/UX Evidence Closeout](2026-07-01-guided-ui-ux-evidence-closeout.md) | Local screenshot/audit evidence was recorded without adding PNG binaries to Git; archived guided/adoption paths were confirmed as already adopted or local-only evidence. |
| `PHS-T57T` | [Ruby/Sapphire Contest Move Facts](2026-07-01-phs-t57t-ruby-contest-move-facts.md) | Focused move catalog, compatibility, and CLI compatibility JSON proof passed on 2026-07-01; `git diff --check` passed. |
| `PHS-T78R` | [Expansion Move Contest Scalar Editing](2026-07-01-phs-t78r-expansion-move-contest-scalars.md) | Focused core/compatibility and CLI JSON proof passed; broader compatibility and `make validate` runs are blocked by unrelated all-learnables assertions after the PHS-T78R tests pass. |
| `PHS-T112T` | [Gen V Message Metadata Facts](2026-07-01-phs-t112t-genv-message-metadata-facts.md) | Focused catalog/CLI proof and `make validate-nds` passed for preview-only Gen V `files/msgdata/**` byte, line-count, numeric-bank-hint, and `noDecodedPreview` facts. |
| `PHS-T98AE` | [DP Move/Encounter C-Anchor Readiness Facts](2026-07-01-phs-t98ae-dp-move-encounter-c-anchor-readiness.md) | Focused clean proof passed for catalog, CLI JSON, resource-index/Resources propagation, and blocked semantic snapshots; live-root proof is blocked by unrelated dirty item/move compile state, and broader `make validate-nds` is blocked by adjacent Gen V fixture drift after PHS-T98AE assertions pass. |
| `PHS-T98AD` | [HGSS Map Relationship Readiness](2026-06-30-phs-t98ad-hgss-map-relationship-readiness.md) | Focused SwiftPM now builds and runs; the HGSS CLI assertion passed, but the selected run and `make validate-nds` remain blocked by unrelated Gen V NitroFS root shallow-count drift (`10` expected, `13` observed). |
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
