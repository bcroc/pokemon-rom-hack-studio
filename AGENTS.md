# Agent Guide

This repo is a local development workspace for PokemonHackStudio. Keep the first move grounded in the live files, then make narrow, verifiable changes.

## Start Here

- Read `docs/planning-and-progress.md` before choosing implementation work.
- Use `docs/planning.md` and `docs/product-architecture.md` for product direction.
- Use `docs/reference-repos.md` and `docs/reference-synthesis.md` before adopting behavior from reference projects.
- Prefer root tooling: `make validate`, `make test`, `make build`, `make run`, and `make verify`.

## Boundaries

- Keep `pokeemerald/`, `pokefirered/`, `agbcc/`, local ROMs, saves, generated ROMs, `DerivedData/`, SwiftPM caches, and Xcode output untracked.
- Keep `references/*` ignored; track only `references/manifest.json` unless a task explicitly changes the reference policy.
- Treat reference repositories as read-only research material. Do not copy code or assets without a license review.
- Keep source-tree edits reviewable and preserve unknown fields/order when parsing source formats.
- Model product writes as mutation plans before any apply/export workflow.

## Validation

- Run `make validate` for bootstrap and core changes.
- For narrow Swift package changes, `make test` is the minimum proof.
- For app shell changes, use `make verify` or `make run` after SwiftPM checks.
- Record completed work and proof in `docs/planning-and-progress.md` when closing a tracked row.

## Current Focus

No implementation row is currently active. Treat `docs/planning-and-progress.md` as the live baseline and source of truth before choosing work; choose new work from the Active Board candidate rows and update the board/proof ledger when closing a row.
