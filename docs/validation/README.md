# PokemonHackStudio Validation

This directory records validation tiers and closeout proof outside the main planning board.

## Focused Closeout Proof

| Row | Proof | Outcome |
| --- | --- | --- |
| `PHS-T98AD` | [HGSS Map Relationship Readiness](2026-06-30-phs-t98ad-hgss-map-relationship-readiness.md) | Implementation and focused assertions were added on 2026-06-30; requested SwiftPM and `make validate-nds` proof is blocked by unrelated dirty `MapCatalog.swift` concurrency errors before selected tests run. |
| `PHS-T98AC` | [HGSS Map Header Integer Scalars](2026-06-29-phs-t98ac-hgss-map-header-integer-scalars.md) | Focused core/CLI proof, app Resources proof, `make validate-nds`, and `git diff --check` passed on 2026-06-29 America/Vancouver. |
| `PHS-T98AB` | [Diamond/Pearl Map Header C Scalars](2026-06-29-phs-t98ab-diamond-pearl-map-header-c-scalars.md) | Focused NDS catalog, CLI semantic plan/apply, and `make validate-nds` proof passed on 2026-06-29 19:35 America/Vancouver; central NDS reference smokes skipped absent local pret clones. |
| `PHS-T78N` | [Expansion All Learnables Readiness Facts](2026-06-30-phs-t78n-expansion-all-learnables-readiness.md) | Focused compatibility/asset/CLI proof passed on 2026-06-29 19:27 America/Vancouver; broader Species and synthetic suites are blocked by unrelated live-tree NDS/Species failures. |
| `PHS-T78P` | [Expansion ItemInfo Effect/Icon Metadata Facts](2026-06-30-phs-t78p-expansion-iteminfo-effect-icon-metadata.md) | Focused SwiftPM and synthetic proof were blocked on 2026-06-29 22:12 America/Vancouver by unrelated `MapCatalog.swift` Swift concurrency diagnostics before PHS-T78P tests executed; `git diff --check` passed. |
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
