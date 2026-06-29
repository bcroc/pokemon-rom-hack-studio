# PokemonHackStudio Validation

This directory records validation tiers and closeout proof outside the main planning board.

## Tiers

| Tier | Command | Purpose | Skips And Blockers |
| --- | --- | --- | --- |
| Synthetic | `make validate-synthetic` | Shell checks plus SwiftPM tests over checked-in synthetic fixtures. | None expected. |
| Local GBA Fixtures | `make validate-gba-fixtures` | Full GBA fixture ladder with local Emerald, FireRed, and Ruby source roots required. | Fails when required local fixture roots are unavailable. |
| Central NDS References | `make validate-nds-strict` | NDS catalog, semantic, and CLI proof against central clean-room references. | Fails when central reference roots are unavailable. |
| App GUI Smoke | `make validate-gui-smoke` | App-hosted smoke via `script/build_and_run.sh test`. | Requires local Xcode/macOS app test environment. |
| Release Candidate | `make validate-release-candidate` | Combined scripts, core, NDS, app-hosted, and app verify ladder before packaging. | Local fixture/reference availability remains tier-specific. |

## Policy

- Synthetic proof is the minimum for source-only or narrow Swift package changes.
- GUI workflow changes should add app/store tests and run at least `make test`; app-hosted smoke is preferred when the changed surface depends on the macOS shell.
- Local fixture and reference tiers must report explicit missing-root reasons instead of silently widening scope.
- Release-candidate proof must also audit that ROMs, saves, generated outputs, references, caches, and local artifacts remain excluded from packaged output.
